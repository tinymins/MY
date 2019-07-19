--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ËæÉí±ã¼ã
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_Toolbox/lang/')
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
MY_Memo = {}
RegisterCustomData('MY_Anmerkungen.szNotePanelContent')

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
	UI('Normal/' .. NAME):remove()
	if CFG.bEnable then
		if not bGlobal and CFG.szContent == ''
		and MY_Anmerkungen and MY_Anmerkungen.szNotePanelContent then
			CFG.szContent = MY_Anmerkungen.szNotePanelContent
			D.SaveConfig()
			MY_Anmerkungen.szNotePanelContent = nil
		end
		UI.CreateFrame(NAME, {
			simple = true, alpha = 140,
			maximize = true, minimize = true, dragresize = true,
			minwidth = 180, minheight = 100,
			onmaximize = function(wnd)
				local ui = UI(wnd)
				ui:children('#WndEditBox_Memo'):size(ui:size())
			end,
			onrestore = function(wnd)
				local ui = UI(wnd)
				ui:children('#WndEditBox_Memo'):size(ui:size())
			end,
			ondragresize = function(wnd)
				local ui = UI(wnd:GetRoot())
				CFG.nWidth  = ui:width()
				CFG.anchor  = ui:anchor()
				CFG.nHeight = ui:height()
				local ui = UI(wnd)
				ui:children('#WndEditBox_Memo'):size(ui:size())
			end,
			w = CFG.nWidth, h = CFG.nHeight, text = TITLE,
			dragable = true, dragarea = {0, 0, CFG.nWidth, 30},
			anchor = CFG.anchor,
			events = {{ 'UI_SCALED', function() UI(this):anchor(CFG.anchor) end }},
			uievents = {{ 'OnFrameDragEnd', function() CFG.anchor = UI('Normal/' .. NAME):anchor() end }},
		}):append('WndEditBox', {
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

function MY_Memo.IsEnable(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.bEnable
	end
	return ROLE_MEMO.bEnable
end

function MY_Memo.Toggle(bGlobal, bEnable)
	(bGlobal and GLOBAL_MEMO or ROLE_MEMO).bEnable = bEnable
	D.SaveConfig()
	D.Reload(bGlobal)
end

function MY_Memo.GetFont(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.nFont
	end
	return ROLE_MEMO.nFont
end

function MY_Memo.SetFont(bGlobal, nFont)
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
