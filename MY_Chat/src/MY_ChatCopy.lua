--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌì¸¨Öú
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatCopy'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
	return
end
--------------------------------------------------------------------------
local O = LIB.CreateUserSettingsModule('MY_ChatCopy', _L['Chat'], {
	bChatCopy = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bChatTime = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	eChatTime = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.String,
		xDefaultValue = 'HOUR_MIN_SEC',
	},
	bChatCopyAlwaysShowMask = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bChatCopyAlwaysWhite = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bChatCopyNoCopySysmsg = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bChatNamelinkEx = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

local function onNewChatLine(h, i, szMsg, szChannel, dwTime, nR, nG, nB)
	if szMsg and i and D.bReady and h:GetItemCount() > i and (O.bChatTime or O.bChatCopy) then
		-- chat time
		-- check if timestrap can insert
		if O.bChatCopyNoCopySysmsg and szChannel == 'SYS_MSG' then
			return
		end
		-- create timestrap text
		local szTime = ''
		for ii = i, h:GetItemCount() - 1 do
			local el = h:Lookup(i)
			if el:GetType() == 'Text' and not el:GetName():find('^namelink_%d+$') and el:GetText() ~= '' then
				nR, nG, nB = el:GetFontColor()
				break
			end
		end
		if O.bChatCopy and (O.bChatCopyAlwaysShowMask or not O.bChatTime) then
			local _r, _g, _b = nR, nG, nB
			if O.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = LIB.GetChatCopyXML(_L[' * '], { r = _r, g = _g, b = _b, richtext = szMsg })
		elseif O.bChatCopyAlwaysWhite then
			nR, nG, nB = 255, 255, 255
		end
		if O.bChatTime then
			if O.eChatTime == 'HOUR_MIN_SEC' then
				szTime = szTime .. LIB.GetChatTimeXML(dwTime, {
					r = nR, g = nG, b = nB, f = 10,
					s = '[%hh:%mm:%ss]', richtext = szMsg,
				})
			else
				szTime = szTime .. LIB.GetChatTimeXML(dwTime, {
					r = nR, g = nG, b = nB, f = 10,
					s = '[%hh:%mm]', richtext = szMsg,
				})
			end
		end
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end
LIB.HookChatPanel('AFTER', 'MY_ChatCopy', onNewChatLine)

function D.OnChatPanelNamelinkLButtonDown(...)
	LIB.ChatLinkEventHandlers.OnNameLClick(...)
end

function D.CheckNamelinkHook(h, nIndex, nEnd)
	local bEnable = D.bReady and O.bChatNamelinkEx
	if not nEnd then
		nEnd = h:GetItemCount() - 1
	end
	for i = nIndex, nEnd do
		local hItem = h:Lookup(i)
		if hItem:GetName():find('^namelink_%d+$') then
			UnhookTableFunc(hItem, 'OnItemLButtonDown', D.OnChatPanelNamelinkLButtonDown)
			if bEnable then
				HookTableFunc(hItem, 'OnItemLButtonDown', D.OnChatPanelNamelinkLButtonDown, { bAfterOrigin = true })
			end
		end
	end
end

LIB.HookChatPanel('AFTER', 'MY_ChatCopy__Namelink', function(h, nIndex)
	D.CheckNamelinkHook(h, nIndex)
end)

function D.CheckNamelinkEnable()
	for i = 1, 10 do
		local h = Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
			or Station.Lookup('Normal1/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
		if h then
			D.CheckNamelinkHook(h, 0)
		end
	end
end

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatCopy', function()
	D.bReady = true
	D.CheckNamelinkEnable()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = X
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['chat copy'],
		checked = O.bChatCopy,
		oncheck = function(bChecked)
			O.bChatCopy = bChecked
		end,
	})
	y = y + deltaY

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['chat time'],
		checked = O.bChatTime,
		oncheck = function(bChecked)
			if bChecked and _G.HM_ToolBox then
				_G.HM_ToolBox.bChatTime = false
			end
			O.bChatTime = bChecked
		end,
	}):AutoWidth():Width()

	ui:Append('WndComboBox', {
		x = x, y = y, w = 150,
		text = _L['chat time format'],
		menu = function()
			return {{
				szOption = _L['hh:mm'],
				bMCheck = true,
				bChecked = O.eChatTime == 'HOUR_MIN',
				fnAction = function()
					O.eChatTime = 'HOUR_MIN'
				end,
				fnDisable = function()
					return not O.bChatTime
				end,
			},{
				szOption = _L['hh:mm:ss'],
				bMCheck = true,
				bChecked = O.eChatTime == 'HOUR_MIN_SEC',
				fnAction = function()
					O.eChatTime = 'HOUR_MIN_SEC'
				end,
				fnDisable = function()
					return not O.bChatTime
				end,
			}}
		end,
	})
	y = y + deltaY

	x = X + 25
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['always show *'],
		checked = O.bChatCopyAlwaysShowMask,
		oncheck = function(bChecked)
			O.bChatCopyAlwaysShowMask = bChecked
		end,
		isdisable = function()
			return not O.bChatCopy
		end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['always be white'],
		checked = O.bChatCopyAlwaysWhite,
		oncheck = function(bChecked)
			O.bChatCopyAlwaysWhite = bChecked
		end,
		isdisable = function()
			return not O.bChatCopy
		end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['hide system msg copy'],
		checked = O.bChatCopyNoCopySysmsg,
		oncheck = function(bChecked)
			O.bChatCopyNoCopySysmsg = bChecked
		end,
		isdisable = function()
			return not O.bChatCopy
		end,
	})
	y = y + deltaY

	x = X
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['Chat panel namelink ext function'],
		checked = O.bChatNamelinkEx,
		oncheck = function(bChecked)
			O.bChatNamelinkEx = bChecked
			D.CheckNamelinkEnable()
		end,
		tip = _L['Alt show equip, shift select.'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	})
	y = y + deltaY

	return x, y
end

-- Global exports
do
local settings = {
	name = 'MY_ChatCopy',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_ChatCopy = LIB.CreateModule(settings)
end
