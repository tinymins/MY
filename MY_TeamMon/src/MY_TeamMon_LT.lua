--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ´ó×ÖÌáÐÑ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	tAnchor      = {},
	fScale       = 1.5,
	fPause       = 1,
	fFadeOut     = 0.3,
	dwFontScheme = 23,
}
RegisterCustomData('MY_TeamMon_LT.tAnchor')
RegisterCustomData('MY_TeamMon_LT.fScale')
RegisterCustomData('MY_TeamMon_LT.fPause')
RegisterCustomData('MY_TeamMon_LT.fFadeOut')
RegisterCustomData('MY_TeamMon_LT.dwFontScheme')

local INIFILE = PACKET_INFO.ROOT ..  'MY_TeamMon/ui/MY_TeamMon_LT.ini'

function D.OnFrameCreate()
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('MY_TM_LARGE_TEXT')
	D.UpdateAnchor(this)
	O.frame = this
	O.txt = this:Lookup('', 'Text_Total')
end

function D.OnEvent(szEvent)
	if szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		if LIB.IsShieldedVersion(2) then
			return
		end
		if szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
			O.frame:Hide()
		else
			O.frame:FadeIn(0)
			O.frame:SetAlpha(255)
			O.frame:Show()
		end
		UpdateCustomModeWindow(this, _L['MY_TeamMon_LT'], true)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'MY_TM_LARGE_TEXT' then
		D.UpdateText(arg0, arg1)
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this)
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	end
end

function D.Init()
	return O.frame or Wnd.OpenWindow(INIFILE, 'MY_TeamMon_LT')
end

function D.UpdateText(txt, col)
	if LIB.IsShieldedVersion(2) then
		return
	end
	if not col then
		col = { 255, 128, 0 }
	end
	O.txt:SetText(txt)
	O.txt:SetFontScheme(O.dwFontScheme)
	O.txt:SetFontScale(O.fScale)
	O.txt:SetFontColor(unpack(col))
	O.frame:FadeIn(0)
	O.frame:SetAlpha(255)
	O.frame:Show()
	O.nTime = GetTime()
	LIB.BreatheCall('MY_TeamMon_LT', D.OnBreathe)
end

function D.OnBreathe()
	local nTime = GetTime()
	if O.nTime and (nTime - O.nTime) / 1000 > O.fPause then
		O.nTime = nil
		O.frame:FadeOut(O.fFadeOut * 10)
		LIB.BreatheCall('MY_TeamMon_LT', false)
	end
end

LIB.RegisterInit('MY_TeamMon_LT', D.Init)

local PS = { bShielded = true }
function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local nX, nY = X, Y

	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['MY_TeamMon_LT'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = ui:Append('Text', { text = _L['Font scale'], x = X + 10, y = nY + 10 }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nX + 10, y = nY + 13, text = '',
		range = {1, 2, 10}, value = O.fScale,
		onchange = function(nVal)
			O.fScale = nVal
			ui:Children('#Text_Preview'):Font(O.dwFontScheme):scale(O.fScale)
		end,
	}):Pos('BOTTOMRIGHT')

	nX = ui:Append('Text', { text = _L['Pause time'], x = X + 10, y = nY }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nX + 10, y = nY + 3, text = _L['s'],
		range = {0.5, 3, 25}, value = O.fPause,
		onchange = function(nVal)
			O.fPause = nVal
		end,
	}):Pos('BOTTOMRIGHT')

	nX = ui:Append('Text', { text = _L['FadeOut time'], x = X + 10, y = nY }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nX + 10, y = nY + 3, text = _L['s'],
		range = {0, 3, 30}, value = O.fFadeOut,
		onchange = function(nVal)
			O.fFadeOut = nVal
		end,
	}):Pos('BOTTOMRIGHT')

	nY = nY + 10
	nX = ui:Append('WndButton2', { x = X + 10, y = nY + 5, text = g_tStrings.FONT,
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				O.dwFontScheme = nFont
				ui:Children('#Text_Preview'):Font(O.dwFontScheme):scale(O.fScale)
			end)
		end,
	}):Pos('BOTTOMRIGHT')
	ui:Append('WndButton2', {
		text = _L['Preview'], x = nX + 10, y = nY + 5,
		onclick = function()
			D.UpdateText(_L['PVE everyday, Xuanjing everyday!'])
		end,
	})
	ui:Append('Text', { name = 'Text_Preview', x = 20, y = nY + 50, txt = _L['JX3'], font = O.dwFontScheme, scale = O.fScale})
end
LIB.RegisterPanel('MY_TeamMon_LT', _L['MY_TeamMon_LT'], _L['Raid'], 'ui/Image/TargetPanel/Target.uitex|59', PS)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				tAnchor      = true,
				fScale       = true,
				fPause       = true,
				fFadeOut     = true,
				dwFontScheme = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				tAnchor      = true,
				fScale       = true,
				fPause       = true,
				fFadeOut     = true,
				dwFontScheme = true,
			},
			root = O,
		},
	},
}
MY_TeamMon_LT = LIB.GeneGlobalNS(settings)
end
