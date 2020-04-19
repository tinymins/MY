--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan = math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2016100) then
	return
end
--------------------------------------------------------------------------

local D = {}

---------------------------------------------------------------------->
-- 获取补贴方案菜单
----------------------------------------------------------------------<
function D.GetSubsidiesMenu()
	local menu = { szOption = _L['Edit Allowance Protocols'], rgb = { 255, 0, 0 } }
	insert(menu, {
		szOption = _L['Add New Protocols'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			GetUserInput(_L['New Protocol  Format: Protocol\'s Name, Money'], function(txt)
				local t = LIB.SplitString(txt, ',')
				local aSubsidies = MY_GKP.aSubsidies
				insert(aSubsidies, { t[1], tonumber(t[2]) or '', true })
				MY_GKP.aSubsidies = aSubsidies
			end)
		end,
	})
	insert(menu, { bDevide = true})
	for k, v in ipairs(MY_GKP.aSubsidies) do
		insert(menu, {
			szOption = v[1],
			bCheck = true,
			bChecked = v[3],
			fnAction = function()
				v[3] = not v[3]
				MY_GKP.aSubsidies = MY_GKP.aSubsidies
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				local aSubsidies = MY_GKP.aSubsidies
				for ii, vv in ipairs(aSubsidies) do
					if v == vv then
						remove(aSubsidies, ii)
					end
				end
				MY_GKP.aSubsidies = aSubsidies
				UI.ClosePopupMenu()
			end,
		})
	end
	return menu
end
---------------------------------------------------------------------->
-- 获取拍卖方案菜单
----------------------------------------------------------------------<
function D.GetSchemeMenu()
	local menu = { szOption = _L['Edit Auction Protocols'], rgb = { 255, 0, 0 } }
	insert(menu,{
		szOption = _L['Edit All Protocols'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			local a = {}
			if IsTable(MY_GKP.aScheme) then
				for k, v in ipairs(MY_GKP.aScheme) do
					if IsTable(v) and IsNumber(v[1]) then
						insert(a, tostring(v[1]))
					end
				end
			end
			GetUserInput(_L['New Protocol Format: Money, Money, Money'], function(txt)
				local t = LIB.SplitString(txt, ',')
				local aScheme = {}
				for k, v in ipairs(t) do
					insert(aScheme, { tonumber(v) or 0, true })
				end
				MY_GKP.aScheme = aScheme
			end, nil, nil, nil, concat(a, ','))
		end
	})
	insert(menu, { bDevide = true })
	for k, v in ipairs(MY_GKP.aScheme) do
		insert(menu,{
			szOption = v[1],
			bCheck = true,
			bChecked = v[2],
			fnAction = function()
				v[2] = not v[2]
				MY_GKP.aScheme = MY_GKP.aScheme
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				local aScheme = MY_GKP.aScheme
				for ii, vv in ipairs(aScheme) do
					if v == vv then
						remove(aScheme, ii)
					end
				end
				MY_GKP.aScheme = aScheme
				UI.ClosePopupMenu()
			end,
		})
	end

	return menu
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 10, 10
	local x, y = X, Y
	local w, h = ui:Size()

	ui:Append('Text', { x = x, y = y, text = _L['Preference Setting'], font = 27 })
	ui:Append('WndButton', {
		x = w - 150, y = y, w = 150, h = 38,
		text = _L['Open Panel'],
		buttonstyle = 3,
		onclick = MY_GKP_MI.OpenPanel,
	})
	y = y + 28

	x = x + 10
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Popup Record for Distributor'], checked = MY_GKP.bOn,
		oncheck = function(bChecked)
			MY_GKP.bOn = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Clause with 0 Gold as Record'], checked = MY_GKP.bDisplayEmptyRecords,
		oncheck = function(bChecked)
			MY_GKP.bDisplayEmptyRecords = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		color = { 255, 128, 0 } , text = _L['Show Gold Brick'], checked = MY_GKP.bShowGoldBrick,
		oncheck = function(bChecked)
			MY_GKP.bShowGoldBrick = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Remind Wipe Data When Enter Dungeon'], checked = MY_GKP.bAlertMessage,
		oncheck = function(bChecked)
			MY_GKP.bAlertMessage = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['Automatic Reception with Record From Distributor'], checked = MY_GKP.bAutoSync,
		oncheck = function(bChecked)
			MY_GKP.bAutoSync = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['Sync system reception'], checked = MY_GKP.bSyncSystem,
		oncheck = function(bChecked)
			MY_GKP.bSyncSystem = bChecked
		end,
	})
	y = y + 28

	y = y + 5
	ui:Append('WndComboBox', { x = x, y = y, w = 150, text = _L['Edit Allowance Protocols'], menu = D.GetSubsidiesMenu })
	ui:Append('WndComboBox', { x = x + 160, y = y, text = _L['Edit Auction Protocols'], menu = D.GetSchemeMenu })
	y = y + 28

	x = X
	ui:Append('Text', { x = x, y = y, text = _L['Money Record'], font = 27 })
	y = y + 28

	x = x + 10
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 150, checked = MY_GKP.bMoneySystem, text = _L['Track Money Trend in the System'],
		oncheck = function(bChecked)
			MY_GKP.bMoneySystem = bChecked
		end,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 150, text = _L['Enable Money Trend'], checked = MY_GKP.bMoneyTalk,
		oncheck = function(bChecked)
			MY_GKP.bMoneyTalk = bChecked
		end,
	})
	y = y + 28
end
LIB.RegisterPanel('MY_GKP', _L['GKP Golden Team Record'], _L['General'], 2490, PS)
