--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ËæÉí±ã¼ã
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------
local ROLE_MEMO = {
	bEnable = false,
	nWidth = 200,
	nHeight = 200,
	szContent = '',
	nFont = 0,
	anchor = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -310, y = 135 },
}
local GLOBAL_MEMO = {
	bEnable = false,
	nWidth = 200,
	nHeight = 200,
	szContent = '',
	nFont = 0,
	anchor = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -310, y = 335 },
}
local D = {}

function D.Reload(bGlobal)
	local CFG_O = bGlobal and GLOBAL_MEMO or ROLE_MEMO
	local CFG = setmetatable({}, {
		__index = CFG_O,
		__newindex = function(t, k, v)
			CFG_O[k] = v
			LIB.DelayCall('MY_Memo_SaveConfig', D.SaveConfig)
		end,
	})
	local NAME = bGlobal and 'MY_MemoGlobal' or 'MY_MemoRole'
	local TITLE = bGlobal and _L['MY Memo (Global)'] or _L['MY Memo (Role)']
	UI('Normal/' .. NAME):Remove()
	if CFG.bEnable then
		UI.CreateFrame(NAME, {
			simple = true, alpha = 140,
			maximize = true, minimize = true, dragresize = true,
			minwidth = 180, minheight = 100,
			onmaximize = function(wnd)
				local ui = UI(wnd)
				ui:Children('#WndEditBox_Memo'):Size(ui:Size())
			end,
			onrestore = function(wnd)
				local ui = UI(wnd)
				ui:Children('#WndEditBox_Memo'):Size(ui:Size())
			end,
			ondragresize = function(wnd)
				local ui = UI(wnd:GetRoot())
				CFG.nWidth  = ui:Width()
				CFG.anchor  = ui:Anchor()
				CFG.nHeight = ui:Height()
				local ui = UI(wnd)
				ui:Children('#WndEditBox_Memo'):Size(ui:Size())
			end,
			w = CFG.nWidth, h = CFG.nHeight, text = TITLE,
			dragable = true, dragarea = {0, 0, CFG.nWidth, 30},
			anchor = CFG.anchor,
			events = {{ 'UI_SCALED', function() UI(this):Anchor(CFG.anchor) end }},
			uievents = {{ 'OnFrameDragEnd', function() CFG.anchor = UI('Normal/' .. NAME):Anchor() end }},
		}):Append('WndEditBox', {
			name = 'WndEditBox_Memo',
			x = 0, y = 0, w = CFG.nWidth, h = CFG.nHeight - 30,
			text = CFG.szContent, multiline = true,
			font = CFG.nFont,
			onchange = function(text) CFG.szContent = text end,
		})
	end
end

function D.LoadConfig()
	local CFG = LIB.LoadLUAData({'config/memo.jx3dat', PATH_TYPE.GLOBAL})
	if CFG then
		for k, v in pairs(CFG) do
			GLOBAL_MEMO[k] = v
		end
	end

	local CFG = LIB.LoadLUAData({'config/memo.jx3dat', PATH_TYPE.ROLE})
	if CFG then
		for k, v in pairs(CFG) do
			ROLE_MEMO[k] = v
		end
		ROLE_MEMO.bEnableGlobal = nil
		GLOBAL_MEMO.bEnable = CFG.bEnableGlobal
	end
end

function D.SaveConfig()
	local CFG = {}
	for k, v in pairs(ROLE_MEMO) do
		CFG[k] = v
	end
	CFG.bEnableGlobal = GLOBAL_MEMO.bEnable
	LIB.SaveLUAData({'config/memo.jx3dat', PATH_TYPE.ROLE}, CFG)

	local CFG = {}
	for k, v in pairs(GLOBAL_MEMO) do
		CFG[k] = v
	end
	CFG.bEnable = nil
	LIB.SaveLUAData({'config/memo.jx3dat', PATH_TYPE.GLOBAL}, CFG)
end

function D.IsEnable(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.bEnable
	end
	return ROLE_MEMO.bEnable
end

function D.Toggle(bGlobal, bEnable)
	(bGlobal and GLOBAL_MEMO or ROLE_MEMO).bEnable = bEnable
	D.SaveConfig()
	D.Reload(bGlobal)
end

function D.GetFont(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.nFont
	end
	return ROLE_MEMO.nFont
end

function D.SetFont(bGlobal, nFont)
	(bGlobal and GLOBAL_MEMO or ROLE_MEMO).nFont = nFont
	D.SaveConfig()
	D.Reload(bGlobal)
end

do
local function onInit()
	D.LoadConfig()
	D.Reload(true)
	D.Reload(false)
end
LIB.RegisterInit('MY_ANMERKUNGEN_PLAYERNOTE', onInit)
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Memo (Role)'],
		checked = D.IsEnable(false),
		oncheck = function(bChecked)
			D.Toggle(false, bChecked)
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndButton', {
		x = x, y = y,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				D.SetFont(false, nFont)
			end)
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Memo (Global)'],
		checked = D.IsEnable(true),
		oncheck = function(bChecked)
			D.Toggle(true, bChecked)
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndButton', {
		x = x, y = y,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				D.SetFont(true, nFont)
			end)
		end,
	}):AutoWidth():Width() + 5
	y = y + deltaY
	x = X
	return x, y
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_Memo',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_Memo = LIB.CreateModule(settings)
end
