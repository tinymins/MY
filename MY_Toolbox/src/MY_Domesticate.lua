--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Ñ±Ñø¼¢¶ö±¨¾¯
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
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
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bAlert = false,
	nAlertNum = 100,
	dwAutoFeedCubTabType = nil,
	dwAutoFeedCubTabIndex = nil,
	dwAutoFeedFoodTabType = nil,
	dwAutoFeedFoodTabIndex = nil,
	nAutoFeedFoodMeasure = nil,
}
RegisterCustomData('MY_Domesticate.bAlert')
RegisterCustomData('MY_Domesticate.nAlertNum')
RegisterCustomData('MY_Domesticate.dwAutoFeedCubTabType')
RegisterCustomData('MY_Domesticate.dwAutoFeedCubTabIndex')
RegisterCustomData('MY_Domesticate.dwAutoFeedFoodTabType')
RegisterCustomData('MY_Domesticate.dwAutoFeedFoodTabIndex')
RegisterCustomData('MY_Domesticate.nAutoFeedFoodMeasure')

function D.SetAutoFeed(dwAutoFeedCubTabType, dwAutoFeedCubTabIndex, dwAutoFeedFoodTabType, dwAutoFeedFoodTabIndex)
	local bValid
	if dwAutoFeedFoodTabType and dwAutoFeedFoodTabIndex then
		local food = GetItemInfo(dwAutoFeedFoodTabType, dwAutoFeedFoodTabIndex)
		if food then
			local szText = MY.GetPureText(GetItemInfoTip(GLOBAL.CURRENT_ITEM_VERSION, 5, 23779))
			local szVal = szText:match(_L['measure (%d+) point'])
			local nAutoFeedFoodMeasure = szVal and tonumber(szVal)
			if nAutoFeedFoodMeasure then
				O.dwAutoFeedCubTabType = dwAutoFeedCubTabType
				O.dwAutoFeedCubTabIndex = dwAutoFeedCubTabIndex
				O.dwAutoFeedFoodTabType = dwAutoFeedFoodTabType
				O.dwAutoFeedFoodTabIndex = dwAutoFeedFoodTabIndex
				O.nAutoFeedFoodMeasure = nAutoFeedFoodMeasure
				bValid = true
			end
		end
	end
	if not bValid then
		O.dwAutoFeedCubTabType = nil
		O.dwAutoFeedCubTabIndex = nil
		O.dwAutoFeedFoodTabType = nil
		O.dwAutoFeedFoodTabIndex = nil
		O.nAutoFeedFoodMeasure = nil
	end
	D.CheckAutoFeedEnable()
end

function D.IsAutoFeedValid(me)
	if not O.dwAutoFeedCubTabType or not O.dwAutoFeedCubTabIndex
	or not O.dwAutoFeedFoodTabType or not O.dwAutoFeedFoodTabIndex
	or not O.nAutoFeedFoodMeasure then
		return false
	end
	local domesticate = me.GetDomesticate()
	if not domesticate
	or domesticate.dwCubTabType ~= O.dwAutoFeedCubTabType
	or domesticate.dwCubTabIndex ~= O.dwAutoFeedCubTabIndex
	or domesticate.nGrowthLevel == domesticate.nMaxGrowthLevel then
		return false
	end
	return true
end

function D.HookDomesticatePanel()
	local btn = Station.Lookup('Normal/DomesticatePanel/Wnd_Satiation/Btn_Feed')
	local box = Station.Lookup('Normal/DomesticatePanel/Wnd_Satiation', 'Box_Feed')
	if btn and box then
		btn.OnRButtonClick = function()
			local me = GetClientPlayer()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local menu = {
				x = x,
				y = y + h,
				nMinWidth = w,
				{
					szOption = _L['Auto feed'],
					bCheck = true, bChecked = D.IsAutoFeedValid(me),
					fnAction = function()
						if D.IsAutoFeedValid(me) then
							LIB.Systopmsg(_L['Auto feed domesticate cancelled.'])
							D.SetAutoFeed()
						else
							local domesticate = GetClientPlayer().GetDomesticate()
							local dwCubTabType, dwCubTabIndex = domesticate.dwCubTabType, domesticate.dwCubTabIndex
							local dwFoodTabType, dwFoodTabIndex = select(5, box:GetObjectData())
							if not domesticate then
								return
							end
							LIB.Systopmsg(_L('Set domesticate auto feed %s to %s succeed.',
								LIB.GetObjectName('ITEM_INFO', dwFoodTabType, dwFoodTabIndex),
								LIB.GetObjectName('ITEM_INFO', dwCubTabType, dwCubTabIndex)))
							D.SetAutoFeed(dwCubTabType, dwCubTabIndex, dwFoodTabType, dwFoodTabIndex)
						end
					end,
				},
			}
			UI.PopupMenu(menu)
		end
	end
end

function D.UnHookDomesticatePanel()
	local btn = Station.Lookup('Normal/DomesticatePanel/Wnd_Satiation/Btn_Feed')
	if btn then
		btn.OnRButtonClick = nil
	end
end

function D.CheckAutoFeedEnable()
	if D.IsAutoFeedValid(GetClientPlayer()) then
		LIB.BreatheCall('MY_Domesticate__AutoFeed', 30000, function()
			local me = GetClientPlayer()
			if not me then
				return
			end
			if not D.IsAutoFeedValid(me) then
				return 0
			end
			local domesticate = me.GetDomesticate()
			local nMeasure = domesticate.nMaxFullMeasure - domesticate.nFullMeasure
			local nRound = floor(nMeasure / O.nAutoFeedFoodMeasure)
			local bFeed = false
			for _ = 1, nRound do
				LIB.WalkBagItem(function(item, dwBox, dwX)
					if item.dwTabType == O.dwAutoFeedFoodTabType and item.dwIndex == O.dwAutoFeedFoodTabIndex then
						domesticate.Feed(dwBox, dwX)
						bFeed = true
						return 0
					end
				end)
			end
			if nRound > 0 and not bFeed then
				local szFood = LIB.GetObjectName('ITEM_INFO', O.dwAutoFeedFoodTabType, O.dwAutoFeedFoodTabIndex)
				local szDomesticate = LIB.GetObjectName('ITEM_INFO', O.dwAutoFeedCubTabType, O.dwAutoFeedCubTabIndex)
				LIB.Systopmsg(_L('No enough %s to feed %s!', szFood, szDomesticate))
			end
		end)
	else
		LIB.BreatheCall('MY_Domesticate__AutoFeed', false)
	end
end

function D.CheckAlertEnable()
	if O.bAlert then
		LIB.BreatheCall('MY_Domesticate__Alert', 60000, function()
			local me = GetClientPlayer()
			if not me then
				return
			end
			local domesticate = me.GetDomesticate()
			if not domesticate then
				return
			end
			local nMeasure = domesticate.nMaxFullMeasure - domesticate.nFullMeasure
			if nMeasure >= O.nAlertNum and domesticate.nGrowthLevel < domesticate.nMaxGrowthLevel then
				local szDomesticate = LIB.GetObjectName('ITEM_INFO', domesticate.dwCubTabType, domesticate.dwCubTabIndex)
				OutputWarningMessage('MSG_WARNING_YELLOW', _L('Your domesticate %s available measure is %d point!', szDomesticate, nMeasure))
				PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			end
		end)
	else
		LIB.BreatheCall('MY_Domesticate__Alert', false)
	end
end

LIB.RegisterInit('MY_Domesticate__AutoFeed', D.CheckAutoFeedEnable)
LIB.RegisterInit('MY_Domesticate__Alert', D.CheckAlertEnable)
LIB.RegisterFrameCreate('DomesticatePanel.MY_Domesticate', D.HookDomesticatePanel)
LIB.RegisterReload('MY_Domesticate', D.UnHookDomesticatePanel)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Domesticate feed alert'],
		checked = O.bAlert,
		oncheck = function(bChecked)
			MY_Domesticate.bAlert = bChecked
		end,
	}):Width() + 5
	ui:Append('WndTrackbar', {
		x = x, y = y, w = 130,
		value = O.nAlertNum,
		range = {1, 200},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(val) return _L('Alert when measure larger than %d', val) end,
		onchange = function(val)
			O.nAlertNum = val
		end,
		autoenable = function() return MY_Domesticate.bAlert end,
	})
	x = X
	y = y + deltaY
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bAlert = true,
				nAlertNum = true,
				dwAutoFeedCubTabType = true,
				dwAutoFeedCubTabIndex = true,
				dwAutoFeedFoodTabType = true,
				dwAutoFeedFoodTabIndex = true,
				nAutoFeedFoodMeasure = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bAlert = true,
				nAlertNum = true,
				dwAutoFeedCubTabType = true,
				dwAutoFeedCubTabIndex = true,
				dwAutoFeedFoodTabType = true,
				dwAutoFeedFoodTabIndex = true,
				nAutoFeedFoodMeasure = true,
			},
			triggers = {
				bAlert = D.CheckAlertEnable,
			},
			root = O,
		},
	},
}
MY_Domesticate = LIB.GeneGlobalNS(settings)
end
