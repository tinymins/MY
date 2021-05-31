--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ´ó×ÖÌáÐÑ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @ref      : William Chan (Webster)
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
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
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
		if LIB.IsShieldedVersion('MY_TargetMon', 2) then
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
	if LIB.IsShieldedVersion('MY_TargetMon', 2) then
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

local PS = { bShielded = true, nShielded = 2 }
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
	nX = ui:Append('WndButton', {
		x = X + 10, y = nY + 5,
		text = g_tStrings.FONT,
		buttonstyle = 'FLAT',
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				O.dwFontScheme = nFont
				ui:Children('#Text_Preview'):Font(O.dwFontScheme):scale(O.fScale)
			end)
		end,
	}):Pos('BOTTOMRIGHT')
	ui:Append('WndButton', {
		x = nX + 10, y = nY + 5,
		text = _L['Preview'],
		buttonstyle = 'FLAT',
		onclick = function()
			D.UpdateText(_L['PVE everyday, Xuanjing everyday!'])
		end,
	})
	ui:Append('Text', { name = 'Text_Preview', x = 20, y = nY + 50, txt = _L['JX3'], font = O.dwFontScheme, scale = O.fScale})
end
LIB.RegisterPanel(_L['Raid'], 'MY_TeamMon_LT', _L['MY_TeamMon_LT'], 'ui/Image/TargetPanel/Target.uitex|59', PS)

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
