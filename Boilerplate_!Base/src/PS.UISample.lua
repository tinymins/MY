--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面组件库示例
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local COMPONENT_H = 25
local COMPONENT_SAMPLE = {
	{'Shadow', 'Shadow', { w = COMPONENT_H, h = COMPONENT_H, color = { 255, 255, 255 } }},
	{'Text', 'Text', { w = 'auto', h = COMPONENT_H, font = 162, text = 'Text' }},
	{'CheckBox', 'CheckBox', { w = 'auto', h = COMPONENT_H, text = 'CheckBox' }},
	{'ColorBox', 'ColorBox', { w = 'auto', h = COMPONENT_H, text = 'ColorBox', color = {255, 255, 0} }},
	{'ColorBox Sized', 'ColorBox', { w = 'auto', h = COMPONENT_H, rw = 50, rh = 18, text = 'ColorBox', color = {255, 255, 0} }},
	{'Handle', 'Handle', { w = COMPONENT_H, h = COMPONENT_H }},
	{'Box', 'Box', { w = COMPONENT_H, h = COMPONENT_H, frame = 233 }},
	{'Image', 'Image', { w = COMPONENT_H, h = COMPONENT_H, image = PACKET_INFO.POSTER_UITEX, imageframe = GetTime() % PACKET_INFO.POSTER_FRAME_COUNT }},
	{'WndAutoComplete', 'WndAutoComplete', { w = 200, h = COMPONENT_H, font = 162, text = 'WndAutoComplete' }},
	{'WndButtonBox', 'WndButtonBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndButtonBox' }},
	{'WndButtonBox Themed', 'WndButtonBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndButtonBox', buttonstyle = 'FLAT' }},
	{'WndButtonBox Option', 'WndButtonBox', { w = COMPONENT_H, h = COMPONENT_H, font = 162, buttonstyle = 'OPTION' }},
	{'WndButton', 'WndButton', { w = 100, h = COMPONENT_H, font = 162, text = 'WndButton' }},
	{'WndCheckBox', 'WndCheckBox', { w = 100, h = COMPONENT_H, font = 162, text = 'WndCheckBox' }},
	{'WndComboBox', 'WndComboBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndComboBox' }},
	{'WndEditBox', 'WndEditBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditBox' }},
	{'WndEditComboBox', 'WndEditComboBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditComboBox' }},
	-- WndListBox
	{'WndRadioBox', 'WndRadioBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndRadioBox' }},
	-- WndScrollBox
	{'WndTrackbar', 'WndTrackbar', { w = 200, h = COMPONENT_H, font = 162, text = 'WndTrackbar' }},
	{'WndTrackbar Sized', 'WndTrackbar', { w = 600, h = COMPONENT_H, rw = 400, font = 162, text = 'WndTrackbar' }},
	-- WndWebCef
	-- WndWebPage
	-- WndWindow
}

local PS = {
	IsShielded = function() return not LIB.IsDebugClient('Dev_UISample') end,
}

-- PS.OnPanelActive(wnd)
-- PS.OnPanelResize(wnd)
-- PS.OnPanelScroll(wnd, scrollX, scrollY)
-- PS.OnPanelBreathe(wnd)
-- PS.OnPanelDeactive(wnd)

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local W, H = ui:Size()
	local X, Y, LH = 20, 20, 30
	local nX, nY = X, Y

	for _, v in ipairs(COMPONENT_SAMPLE) do
		ui:Append('Shadow', { x = nX, y = nY + 22, w = W - X * 2, h = 1, color = { 255, 255, 255 }, alpha = 100 })
		nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', h = COMPONENT_H, font = 162, text = v[1] .. ': ' }):Width() + 5
		nX = nX + ui:Append(v[2], v[3]):Pos(nX, nY):Width() + 5
		nX = X
		nY = nY + LH
	end
end

LIB.RegisterPanel(_L['Development'], 'UISample', _L['UI SAMPLE'], '', PS)
