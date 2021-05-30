--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 悬浮功能入口
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
local LIB = Boilerplate
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
local O = {}
local FRAME_NAME = NSFormatString('{$NS}_HoverEntry')

local KEY_ENABLE = NSFormatString('{$NS}_HoverEntry.bEnable')
local KEY_SIZE = NSFormatString('{$NS}_HoverEntry.nSize')
local KEY_ANCHOR = NSFormatString('{$NS}_HoverEntry.anchor')
local KEY_HOVER_MENU = NSFormatString('{$NS}_HoverEntry.bHoverMenu')

LIB.RegisterUserSettings(KEY_ENABLE    , PATH_TYPE.ROLE, _L['HoverEntry'], _L['Enable status'])
LIB.RegisterUserSettings(KEY_SIZE      , PATH_TYPE.ROLE, _L['HoverEntry'], _L['Size'         ])
LIB.RegisterUserSettings(KEY_ANCHOR    , PATH_TYPE.ROLE, _L['HoverEntry'], _L['Anchor'       ])
LIB.RegisterUserSettings(KEY_HOVER_MENU, PATH_TYPE.ROLE, _L['HoverEntry'], _L['Hover popup'  ])

function D.LoadSettings()
	O.bEnable    = LIB.GetUserSettings(KEY_ENABLE    , false)
	O.nSize      = LIB.GetUserSettings(KEY_SIZE      , 30)
	O.anchor     = LIB.GetUserSettings(KEY_ANCHOR    , { x = -362, y = -78, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' })
	O.bHoverMenu = LIB.GetUserSettings(KEY_HOVER_MENU, false)
	D.CheckEnable()
end
LIB.RegisterInit('HoverEntry', D.LoadSettings)

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
	LIB.SetUserSettings(KEY_ANCHOR, O.anchor)
end

function D.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	nX = X
	nY = nLFY
	ui:Append('Text', {
		x = X - 10, y = nY,
		text = _L['Hover entry'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Enable'],
		checked = O.bEnable,
		oncheck = function(bChecked)
			O.bEnable = bChecked
			D.CheckEnable()
			LIB.SetUserSettings(KEY_ENABLE, O.bEnable)
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Hover popup'],
		checked = O.bHoverMenu,
		oncheck = function(bChecked)
			O.bHoverMenu = bChecked
			D.CheckEnable()
			LIB.SetUserSettings(KEY_HOVER_MENU, O.bHoverMenu)
		end,
		autoenable = function() return O.bEnable end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, w = 100, h = 25,
		value = O.nSize,
		range = {1, 300},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(v) return _L('Size: %d', v) end,
		onchange = function(val)
			O.nSize = val
			D.CheckEnable()
			LIB.SetUserSettings(KEY_SIZE, O.nSize)
		end,
		autoenable = function() return O.bEnable end,
	}):AutoWidth():Width() + 5
	nX, nY = X, nY + 30

	nLFY = nY + LH
	return nX, nY, nLFY
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
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
_G[FRAME_NAME] = LIB.GeneGlobalNS(settings)
end
