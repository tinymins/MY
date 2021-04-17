--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 二进制资源
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local PLUGIN_NAME = NSFormatString('{$NS}_Resource')
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = NSFormatString('{$NS}_Resource')
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.0') then
	return
end
--------------------------------------------------------------------------

local C, D = {}, {}

C.aSound = {
	-- {
	-- 	type = _L['Wuer'],
	-- 	{ id = 2, file = 'WE/voice-52001.ogg' },
	-- 	{ id = 3, file = 'WE/voice-52002.ogg' },
	-- },
}

do
local root = PLUGIN_ROOT .. '/audio/'
local function GetSoundList(tSound)
	local t = {}
	if tSound.type then
		t.szType = tSound.type
	elseif tSound.id then
		t.dwID = tSound.id
		t.szName = _L[tSound.file]
		t.szPath = root .. tSound.file
	end
	for _, v in ipairs(tSound) do
		local t1 = GetSoundList(v)
		if t1 then
			insert(t, t1)
		end
	end
	return t
end

function D.GetSoundList()
	return GetSoundList(C.aSound)
end
end

do
local BUTTON_STYLE_CONFIG = {
	FLAT = LIB.SetmetaReadonly({
		nWidth = 100,
		nHeight = 25,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 8,
		nMouseOverGroup = 9,
		nMouseDownGroup = 10,
		nDisableGroup = 11,
	}),
	FLAT_LACE_BORDER = LIB.SetmetaReadonly({
		nWidth = 148,
		nHeight = 33,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 0,
		nMouseOverGroup = 1,
		nMouseDownGroup = 2,
		nDisableGroup = 3,
	}),
	SKEUOMORPHISM = LIB.SetmetaReadonly({
		nWidth = 148,
		nHeight = 33,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 4,
		nMouseOverGroup = 5,
		nMouseDownGroup = 6,
		nDisableGroup = 7,
	}),
	SKEUOMORPHISM_LACE_BORDER = LIB.SetmetaReadonly({
		nWidth = 224,
		nHeight = 64,
		nPaddingTop = 2,
		nPaddingRight = 9,
		nPaddingBottom = 10,
		nPaddingLeft = 6,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 12,
		nMouseOverGroup = 13,
		nMouseDownGroup = 14,
		nDisableGroup = 15,
	}),
	QUESTION = LIB.SetmetaReadonly({
		nWidth = 20,
		nHeight = 20,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 16,
		nMouseOverGroup = 17,
		nMouseDownGroup = 18,
		nDisableGroup = 19,
	}),
}
function D.GetWndButtonStyleName(szImage, nNormalGroup)
	szImage = wlower(LIB.NormalizePath(szImage))
	for e, p in pairs(BUTTON_STYLE_CONFIG) do
		if wlower(LIB.NormalizePath(p.szImage)) == szImage and p.nNormalGroup == nNormalGroup then
			return e
		end
	end
end
function D.GetWndButtonStyleConfig(eStyle)
	return BUTTON_STYLE_CONFIG[eStyle]
end
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				GetSoundList = D.GetSoundList,
				GetWndButtonStyleName = D.GetWndButtonStyleName,
				GetWndButtonStyleConfig = D.GetWndButtonStyleConfig,
			},
		},
	},
}
_G[MODULE_NAME] = LIB.GeneGlobalNS(settings)
end
