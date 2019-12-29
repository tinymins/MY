--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �����������
-- @author   : ���� @˫���� @׷����Ӱ
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

local _L = LIB.LoadLangPack()
local D = {}
local O = {
	bEnable = false,
	nSize = 30,
	anchor = { x = -362, y = -78, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
	bHoverMenu = false,
}
RegisterCustomData('MY_HoverEntry.bEnable')
RegisterCustomData('MY_HoverEntry.nSize')
RegisterCustomData('MY_HoverEntry.anchor')
RegisterCustomData('MY_HoverEntry.bHoverMenu')

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
	PopupMenu(menu)
end

function D.CheckEnable()
	Wnd.CloseWindow('MY_HoverEntry')
	if O.bEnable then
		local frame = UI.CreateFrame('MY_HoverEntry', {
			empty = true,
			w = O.nSize, h = O.nSize,
			anchor = O.anchor,
		})
		UI(frame):Append('Image', {
			w = O.nSize, h = O.nSize,
			image = PACKET_INFO.UITEX_ICON,
			imageframe = PACKET_INFO.MAINICON_FRAME,
			onhover = function(bIn)
				if bIn and O.bHoverMenu then
					D.Popup()
				end
			end,
			onclick = D.Popup,
		})
	end
end
LIB.RegisterInit('MY_HoverEntry', D.CheckEnable)

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		UI(this):Anchor(O.anchor)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['MY_HoverEntry'])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		O.anchor = GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L['MY_HoverEntry'])
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
MY_HoverEntry = LIB.GeneGlobalNS(settings)
end