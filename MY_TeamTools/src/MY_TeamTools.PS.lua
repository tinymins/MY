--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')
if not LIB.AssertVersion('MY_TeamTools', _L['MY_TeamTools'], 0x2011800) then
	return
end
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 30
	local x, y = X, Y

	y = y + ui:append('Text', { x = x, y = y, text = _L['MY_TeamTools'], font = 27 }, true):height() + 5
	x = X + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_TeamNotice.bEnable,
		text = _L['Team Message'],
		oncheck = function(bChecked)
			MY_TeamNotice.bEnable = bChecked
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_CharInfo.bEnable,
		text = _L['Allow view charinfo'],
		oncheck = function(bChecked)
			MY_CharInfo.bEnable = bChecked
		end,
	}, true):autoWidth():width() + 5

	if not LIB.IsShieldedVersion() then
		x = x + ui:append('WndCheckBox', {
			x = x, y = y,
			checked = MY_WorldMark.bEnable,
			text = _L['World mark enhance'],
			oncheck = function(bChecked)
				MY_WorldMark.bEnable = bChecked
				MY_WorldMark.CheckEnable()
			end,
		}, true):autoWidth():width() + 5
	end
	y = y + 20

	x = X
	y = y + 20
	y = y + ui:append('Text', { x = x, y = y, text = _L['Party Request'], font = 27 }, true):height() + 5
	x = X + 10
	ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bEnable,
		text = _L['Party Request'],
		oncheck = function(bChecked)
			MY_PartyRequest.bEnable = bChecked
		end,
	}, true):autoWidth()
	x = x + 10
	y = y + 25
	ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bRefuseLowLv,
		text = _L['Auto refuse low level player'],
		oncheck = function(bChecked)
			MY_PartyRequest.bRefuseLowLv = bChecked
		end,
		autoenable = function() return MY_PartyRequest.bEnable end,
	}, true):autoWidth()
	y = y + 25
	ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bRefuseRobot,
		text = _L['Auto refuse robot player'],
		tip = _L['Full level and equip score less than 2/3 of yours'],
		tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		oncheck = function(bChecked)
			MY_PartyRequest.bRefuseRobot = bChecked
		end,
		autoenable = function() return MY_PartyRequest.bEnable end,
	}, true):autoWidth()
	y = y + 25
	ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bAcceptFriend,
		text = _L['Auto accept friend'],
		oncheck = function(bChecked)
			MY_PartyRequest.bAcceptFriend = bChecked
		end,
		autoenable = function() return MY_PartyRequest.bEnable end,
	}, true):autoWidth()
	y = y + 25
	ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bAcceptTong,
		text = _L['Auto accept tong member'],
		oncheck = function(bChecked)
			MY_PartyRequest.bAcceptTong = bChecked
		end,
		autoenable = function() return MY_PartyRequest.bEnable end,
	}, true):autoWidth()
	y = y + 25
	ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bAcceptAll,
		text = _L['Auto accept all'],
		oncheck = function(bChecked)
			MY_PartyRequest.bAcceptAll = bChecked
		end,
		autoenable = function() return MY_PartyRequest.bEnable end,
	}, true):autoWidth()
	y = y + 25
end
LIB.RegisterPanel('MY_TeamTools', _L['MY_TeamTools'], _L['Raid'], 5962, PS)
