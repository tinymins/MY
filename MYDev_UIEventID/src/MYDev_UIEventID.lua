--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : UI事件ID计算
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MYDev_UIEventID'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_UIEventID'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local _C = {}
_C.tEventIndex = {
	{ text = _L['OnKeyDown'        ], bit = 13 },
	{ text = _L['OnKeyUp'          ], bit = 14 },

	{ text = _L['OnLButtonDown'    ], bit = 1  },
	{ text = _L['OnLButtonUp'      ], bit = 3  },
	{ text = _L['OnLButtonClick'   ], bit = 5  },
	{ text = _L['OnLButtonDbClick' ], bit = 7  },
	{ text = _L['OnLButtonDrag'    ], bit = 20 },

	{ text = _L['OnRButtonDown'    ], bit = 2  },
	{ text = _L['OnRButtonUp'      ], bit = 4  },
	{ text = _L['OnRButtonClick'   ], bit = 6  },
	{ text = _L['OnRButtonDbClick' ], bit = 8  },
	{ text = _L['OnRButtonDrag'    ], bit = 19 },

	{ text = _L['OnMButtonDown'    ], bit = 15 },
	{ text = _L['OnMButtonUp'      ], bit = 16 },
	{ text = _L['OnMButtonClick'   ], bit = 17 },
	{ text = _L['OnMButtonDbClick' ], bit = 18 },
	{ text = _L['OnMButtonDrag'    ], bit = 21 },

	{ text = _L['OnMouseEnterLeave'], bit = 9  },
	{ text = _L['OnMouseArea'      ], bit = 10 },
	{ text = _L['OnMouseMove'      ], bit = 11 },
	{ text = _L['OnMouseHover'     ], bit = 22 },
	{ text = _L['OnScroll'         ], bit = 12 },
}
_C.nEventID = 0

_C.GetEventID = function(ui)
	local t = {}
	for i, event in ipairs(_C.tEventIndex) do
		if ui:Children('#Event_' .. event.bit):Check() then
			t[event.bit] = 1
		else
			t[event.bit] = 0
		end
	end
	return LIB.Bitmap2Number(t)
end

_C.SetEventID = function(ui, nEventID)
	local t = LIB.Number2Bitmap(nEventID)
	for i, event in ipairs(_C.tEventIndex) do
		ui:Children('#Event_' .. event.bit):Check(t[event.bit] == 1)
	end
end

LIB.RegisterPanel(_L['Development'], 'Dev_UIEventID', _L['UIEventID'], 'ui/Image/UICommon/BattleFiled.UITex|7', {
OnPanelActive = function(wnd)
	local ui = UI(wnd)
	local x, y = 10, 30

	ui:Append('WndEditBox', {
		x = x, y = y, w = 150, h = 25,
		name = 'WndEdit',
		text = _C.nEventID,
		font = 201, color = { 255, 255, 255 },
		onchange = function(text)
			local nEventID = tonumber(text)
			if nEventID and nEventID ~= _C.nEventID then
				_C.SetEventID(ui, nEventID)
			end
		end,
	})

	x, y = 5, y + 35
	for k, event in ipairs(_C.tEventIndex) do
		ui:Append('WndCheckBox', {
			name = 'Event_' .. event.bit,
			text = event.text, x = x, y = y, w = 120,
			oncheck = function(bCheck)
				if bCheck then
					ui:Children('#Event_' .. event.bit):Color(255, 128, 0  )
				else
					ui:Children('#Event_' .. event.bit):Color(255, 255, 255)
				end
				_C.nEventID = _C.GetEventID(ui)
				ui:Children('#WndEdit'):Text(_C.nEventID)
			end,
		})
		x = x + 90

		if(k - 1) % 5 == 1 or k == 2 then
			x, y = 5, y + 25
		end
	end

	_C.SetEventID(ui, _C.nEventID)
end})
