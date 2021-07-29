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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_Domesticate', _L['General'], {
	bAlert = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nAlertNum = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Number,
		xDefaultValue = 100,
	},
	dwAutoFeedCubTabType = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Optional(Schema.Number),
		xDefaultValue = nil,
	},
	dwAutoFeedCubTabIndex = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Optional(Schema.Number),
		xDefaultValue = nil,
	},
	dwAutoFeedFoodTabType = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Optional(Schema.Number),
		xDefaultValue = nil,
	},
	dwAutoFeedFoodTabIndex = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Optional(Schema.Number),
		xDefaultValue = nil,
	},
	nAutoFeedFoodMeasure = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Optional(Schema.Number),
		xDefaultValue = nil,
	},
})
local D = {}

function D.SetAutoFeed(dwAutoFeedCubTabType, dwAutoFeedCubTabIndex, dwAutoFeedFoodTabType, dwAutoFeedFoodTabIndex)
	local bValid
	if dwAutoFeedFoodTabType and dwAutoFeedFoodTabIndex then
		local food = GetItemInfo(dwAutoFeedFoodTabType, dwAutoFeedFoodTabIndex)
		if food then
			local szText = MY.GetPureText(GetItemInfoTip(GLOBAL.CURRENT_ITEM_VERSION, dwAutoFeedFoodTabType, dwAutoFeedFoodTabIndex), 'LUA') or ''
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
							D.SetAutoFeed()
							LIB.Systopmsg(_L['Auto feed domesticate cancelled.'])
						else
							local domesticate = GetClientPlayer().GetDomesticate()
							local dwCubTabType, dwCubTabIndex = domesticate.dwCubTabType, domesticate.dwCubTabIndex
							local dwFoodTabType, dwFoodTabIndex = select(5, box:GetObjectData())
							if not domesticate then
								return
							end
							D.SetAutoFeed(dwCubTabType, dwCubTabIndex, dwFoodTabType, dwFoodTabIndex)

							local szFoodName = LIB.GetObjectName('ITEM_INFO', dwFoodTabType, dwFoodTabIndex)
							local szDomesticateName = LIB.GetObjectName('ITEM_INFO', dwCubTabType, dwCubTabIndex)
							if D.IsAutoFeedValid(me) then
								LIB.Systopmsg(_L('Set domesticate auto feed %s to %s succeed, will auto feed when hunger point reach %d.',
									szFoodName,
									szDomesticateName,
									O.nAutoFeedFoodMeasure))
							else
								LIB.Systopmsg(_L('Set domesticate auto feed %s to %s failed.', szFoodName, szDomesticateName))
							end
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
	if D.bReady and D.IsAutoFeedValid(GetClientPlayer()) then
		LIB.BreatheCall('MY_Domesticate__AutoFeed', 30000, function()
			local me = GetClientPlayer()
			if not me then
				return
			end
			if me.bFightState then
				return
			end
			if not D.IsAutoFeedValid(me) then
				return 0
			end
			local domesticate = me.GetDomesticate()
			if not domesticate or domesticate.dwCubTabType == 0 then
				return
			end
			if domesticate.nGrowthLevel >= domesticate.nMaxGrowthLevel then
				local szDomesticate = LIB.GetObjectName('ITEM_INFO', domesticate.dwCubTabType, domesticate.dwCubTabIndex)
				LIB.Systopmsg(_L('Your domesticate %s is growth up!', szDomesticate))
				return
			end
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
	if D.bReady and O.bAlert then
		LIB.BreatheCall('MY_Domesticate__Alert', 60000, function()
			local me = GetClientPlayer()
			if not me then
				return
			end
			if me.bFightState then
				return
			end
			local domesticate = me.GetDomesticate()
			if not domesticate or domesticate.dwCubTabType == 0 then
				return
			end
			if domesticate.nGrowthLevel >= domesticate.nMaxGrowthLevel then
				local szDomesticate = LIB.GetObjectName('ITEM_INFO', domesticate.dwCubTabType, domesticate.dwCubTabIndex)
				OutputWarningMessage('MSG_WARNING_YELLOW', _L('Your domesticate %s is growth up!', szDomesticate))
				PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
				return
			end
			if O.nAlertNum == 0 then
				if domesticate.nFullMeasure == 0 and domesticate.nGrowthLevel < domesticate.nMaxGrowthLevel then
					local szDomesticate = LIB.GetObjectName('ITEM_INFO', domesticate.dwCubTabType, domesticate.dwCubTabIndex)
					OutputWarningMessage('MSG_WARNING_YELLOW', _L('Your domesticate %s is hungery!', szDomesticate))
					PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
				end
			else
				local nMeasure = domesticate.nMaxFullMeasure - domesticate.nFullMeasure
				if nMeasure >= O.nAlertNum and domesticate.nGrowthLevel < domesticate.nMaxGrowthLevel then
					local szDomesticate = LIB.GetObjectName('ITEM_INFO', domesticate.dwCubTabType, domesticate.dwCubTabIndex)
					OutputWarningMessage('MSG_WARNING_YELLOW', _L('Your domesticate %s available measure is %d point!', szDomesticate, nMeasure))
					PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
				end
			end
		end)
	else
		LIB.BreatheCall('MY_Domesticate__Alert', false)
	end
end

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_Domesticate', function()
	D.bReady = true
	D.CheckAutoFeedEnable()
	D.CheckAlertEnable()
end)
LIB.RegisterFrameCreate('DomesticatePanel', 'MY_Domesticate', D.HookDomesticatePanel)
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
		range = {0, 1000},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(val)
			if val == 0 then
				return _L['Alert when measure is empty']
			end
			return _L('Alert when measure larger than %d', val)
		end,
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
	name = 'MY_Domesticate',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bAlert',
				'nAlertNum',
				'dwAutoFeedCubTabType',
				'dwAutoFeedCubTabIndex',
				'dwAutoFeedFoodTabType',
				'dwAutoFeedFoodTabIndex',
				'nAutoFeedFoodMeasure',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bAlert',
				'nAlertNum',
				'dwAutoFeedCubTabType',
				'dwAutoFeedCubTabIndex',
				'dwAutoFeedFoodTabType',
				'dwAutoFeedFoodTabIndex',
				'nAutoFeedFoodMeasure',
			},
			triggers = {
				bAlert = D.CheckAlertEnable,
			},
			root = O,
		},
	},
}
MY_Domesticate = LIB.CreateModule(settings)
end
