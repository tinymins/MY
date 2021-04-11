--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �����������
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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

local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/hoverentry/')
local D = {}
local O = {
	bEnable = false,
	nSize = 30,
	anchor = { x = -362, y = -78, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
	bHoverMenu = false,
}
local FRAME_NAME = NSFormatString('{$NS}_HoverEntry')
RegisterCustomData(FRAME_NAME .. '.bEnable')
RegisterCustomData(FRAME_NAME .. '.nSize')
RegisterCustomData(FRAME_NAME .. '.anchor')
RegisterCustomData(FRAME_NAME .. '.bHoverMenu')

function D.Popup()
	local addonmenu = LIB.GetTraceButtonAddonMenu()[1]
	local menu = {
		bDisableSound = true,
		{
			szOption = addonmenu.szOption,
			rgb = addonmenu.rgb,
		},
		CONSTANT.MENU_DIVIDER,
	}
	for i, v in ipairs(addonmenu) do
		insert(menu, v)
	end
	UI.PopupMenu(menu)
end

function D.CheckEnable()
	Wnd.CloseWindow(FRAME_NAME)
	if O.bEnable then
		local frame = UI.CreateFrame(FRAME_NAME, {
			empty = true,
			w = O.nSize, h = O.nSize,
			anchor = O.anchor,
		})
		UI(frame):Append('Image', {
			w = O.nSize, h = O.nSize,
			image = PACKET_INFO.LOGO_UITEX,
			imageframe = PACKET_INFO.LOGO_MAIN_FRAME,
			onhover = function(bIn)
				if bIn and O.bHoverMenu then
					D.Popup()
				end
			end,
			onclick = D.Popup,
		})
	end
end
LIB.RegisterInit('HoverEntry', D.CheckEnable)

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		UI(this):Anchor(O.anchor)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['HoverEntry'])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		O.anchor = GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L['HoverEntry'])
	end
end

function D.OnFrameDragEnd()
	O.anchor = GetFrameAnchor(this)
end

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
				bEnable = true,
				nSize = true,
				anchor = true,
				bHoverMenu = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				nSize = true,
				anchor = true,
				bHoverMenu = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
				nSize = D.CheckEnable,
				anchor = D.CheckEnable,
			},
			root = O,
		},
	},
}
_G[FRAME_NAME] = LIB.GeneGlobalNS(settings)
end