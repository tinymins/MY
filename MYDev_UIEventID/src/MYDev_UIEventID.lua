--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : UI事件ID计算
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local EMPTY_TABLE, MENU_DIVIDER, XML_LINE_BREAKER = LIB.EMPTY_TABLE, LIB.MENU_DIVIDER, LIB.XML_LINE_BREAKER
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MYDev_UIEventID/lang/')
if not LIB.AssertVersion('MYDev_UIEventID', _L['MYDev_UIEventID'], 0x2011800) then
	return
end
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
		if ui:children('#Event_' .. event.bit):check() then
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
		ui:children('#Event_' .. event.bit):check(t[event.bit] == 1)
	end
end

LIB.RegisterPanel(
'Dev_UIEventID', _L['UIEventID'], _L['Development'],
'ui/Image/UICommon/BattleFiled.UITex|7', {
OnPanelActive = function(wnd)
	local ui = UI(wnd)
	local x, y = 10, 30

	ui:append('WndEditBox', {
		name = 'WndEdit',
		text = _C.nEventID, x = x, y = y, w = 150, h = 25, font = 201, color = { 255, 255, 255 }
	}):children('#WndEdit'):change(function(text)
	  	local nEventID = tonumber(text)
	  	if nEventID and nEventID ~= _C.nEventID then
	  		_C.SetEventID(ui, nEventID)
	  	end
	  end)

	x, y = 5, y + 35
	for k, event in ipairs(_C.tEventIndex) do
		ui:append('WndCheckBox', {
			name = 'Event_' .. event.bit,
			text = event.text, x = x, y = y, w = 120
		}):children('#Event_' .. event.bit)
		  :check(function(bCheck)
		  	if bCheck then
		  		ui:children('#Event_' .. event.bit):color(255, 128, 0  )
		  	else
		  		ui:children('#Event_' .. event.bit):color(255, 255, 255)
		  	end
		  	_C.nEventID = _C.GetEventID(ui)
		  	ui:children('#WndEdit'):text(_C.nEventID)
		  end)
		x = x + 90

		if(k - 1) % 5 == 1 or k == 2 then
			x, y = 5, y + 25
		end
	end

	_C.SetEventID(ui, _C.nEventID)
end})
