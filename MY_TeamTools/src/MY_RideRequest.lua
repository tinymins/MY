--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Ë«ÆïÖúÊÖ
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
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_RideRequest.ini'
local D = {}
local O = {
	bEnable = false,
	bRefuseOthers  = false,
	bRefuseUnknown = false,
	bAcceptTong    = false,
	bAcceptFriend  = false,
	bAcceptAll     = false,
	bAcceptCustom  = false,
	tAcceptCustom  = {},
}
RegisterCustomData('MY_RideRequest.bEnable')
RegisterCustomData('MY_RideRequest.bRefuseOthers')
RegisterCustomData('MY_RideRequest.bRefuseUnknown')
RegisterCustomData('MY_RideRequest.bAcceptTong')
RegisterCustomData('MY_RideRequest.bAcceptFriend')
RegisterCustomData('MY_RideRequest.bAcceptAll')
RegisterCustomData('MY_RideRequest.bAcceptCustom')
RegisterCustomData('MY_RideRequest.tAcceptCustom')

local RIDE_MSG = {}
local RIDE_LIST = {}

for k, v in pairs({
	['RIDE_CONTROLLER'     ] = {FOLLOW_TYPE.RIDE     , INVITE_FOLLOW_TYPE.BE_CONTROLLER},
	['RIDE_FOLLOWER'       ] = {FOLLOW_TYPE.RIDE     , INVITE_FOLLOW_TYPE.BE_FOLLOWER  },
	['HOLDHORSE_CONTROLLER'] = {FOLLOW_TYPE.HOLDHORSE, INVITE_FOLLOW_TYPE.BE_CONTROLLER},
	['HOLDHORSE_FOLLOWER'  ] = {FOLLOW_TYPE.HOLDHORSE, INVITE_FOLLOW_TYPE.BE_FOLLOWER  },
	['HOLDHANDS_CONTROLLER'] = {FOLLOW_TYPE.HOLDHANDS, INVITE_FOLLOW_TYPE.BE_CONTROLLER},
	['HOLDHANDS_FOLLOWER'  ] = {FOLLOW_TYPE.HOLDHANDS, INVITE_FOLLOW_TYPE.BE_FOLLOWER  },
	['CARRY_CONTROLLER'    ] = {FOLLOW_TYPE.CARRY    , INVITE_FOLLOW_TYPE.BE_CONTROLLER},
	['CARRY_FOLLOWER'      ] = {FOLLOW_TYPE.CARRY    , INVITE_FOLLOW_TYPE.BE_FOLLOWER  },
}) do
	if v[1] and v[2] and g_tStrings.tInviteType[v[1]] and g_tStrings.tInviteType[v[1]][v[2]] then
		RIDE_MSG[k] = g_tStrings.tInviteType[v[1]][v[2]]:gsub('<D0>', '^(.-)')
	end
end

function D.GetMenu()
	local menu = {
		szOption = _L['MY_RideRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = MY_RideRequest.bEnable,
			fnAction = function()
				MY_RideRequest.bEnable = not MY_RideRequest.bEnable
			end,
		},
		CONSTANT.MENU_DIVIDER,
		{
			szOption = _L['Auto accept friend'],
			bCheck = true, bChecked = MY_RideRequest.bAcceptFriend,
			fnAction = function()
				MY_RideRequest.bAcceptFriend = not MY_RideRequest.bAcceptFriend
			end,
			fnDisable = function() return not MY_RideRequest.bEnable end,
		},
		{
			szOption = _L['Auto accept tong member'],
			bCheck = true, bChecked = MY_RideRequest.bAcceptTong,
			fnAction = function()
				MY_RideRequest.bAcceptTong = not MY_RideRequest.bAcceptTong
			end,
			fnDisable = function() return not MY_RideRequest.bEnable end,
		},
		{
			szOption = _L['Auto accept all'],
			bCheck = true, bChecked = MY_RideRequest.bAcceptAll,
			fnAction = function()
				MY_RideRequest.bAcceptAll = not MY_RideRequest.bAcceptAll
			end,
			fnDisable = function() return not MY_RideRequest.bEnable end,
		},
	}
	local t = {
		szOption = _L['Auto accept specific names'],
		bCheck = true, bChecked = MY_RideRequest.bAcceptCustom,
		fnAction = function()
			MY_RideRequest.bAcceptCustom = not MY_RideRequest.bAcceptCustom
		end,
		fnDisable = function() return not MY_RideRequest.bEnable end,
	}
	for szName, bEnable in pairs(MY_RideRequest.tAcceptCustom) do
		insert(t, {
			szOption = szName,
			bCheck = true, bChecked = bEnable,
			fnAction = function()
				MY_RideRequest.tAcceptCustom[szName] = not MY_RideRequest.tAcceptCustom[szName]
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				MY_RideRequest.tAcceptCustom[szName] = nil
				UI.ClosePopupMenu()
			end,
			fnDisable = function() return not MY_RideRequest.bEnable or not MY_RideRequest.bAcceptCustom end,
		})
	end
	if #t ~= 0 then
		insert(t, CONSTANT.MENU_DIVIDER)
	end
	insert(t, {
		szOption = _L['Add'],
		fnAction = function()
			GetUserInput(_L['Please input custom name, multiple split with ",[]":'], function(val)
				for _, v in ipairs(LIB.SplitString(val, {',', '[', ']'}, true)) do
					MY_RideRequest.tAcceptCustom[v] = true
				end
			end)
		end,
		fnDisable = function() return not MY_RideRequest.bEnable or not MY_RideRequest.bAcceptCustom end,
	})
	insert(menu, t)
	insert(menu, {
		szOption = _L['Auto refuse others'],
		bCheck = true, bChecked = MY_RideRequest.bRefuseOthers,
		fnAction = function()
			MY_RideRequest.bRefuseOthers = not MY_RideRequest.bRefuseOthers
		end,
		fnDisable = function() return not MY_RideRequest.bEnable end,
	})
	insert(menu, {
		szOption = _L['Auto refuse unknown'],
		bCheck = true, bChecked = MY_RideRequest.bRefuseUnknown,
		fnAction = function()
			MY_RideRequest.bRefuseUnknown = not MY_RideRequest.bRefuseUnknown
		end,
		fnDisable = function() return not MY_RideRequest.bEnable end,
	})
	return menu
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Accept' then
		D.AcceptRequest(this:GetParent().info)
	elseif name == 'Btn_Refuse' then
		D.RefuseRequest(this:GetParent().info)
	end
end

function D.OnRButtonClick()
	if this.info then
		PopupMenu(LIB.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
	end
end

function D.OnMouseEnter()
	if this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = GetFormatText(this.info.szDesc)
		OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	end
end

function D.OnMouseLeave()
	if this.info then
		HideTip()
	end
end

function D.AcceptRequest(info)
	RIDE_LIST[info.szName] = nil
	UI.RemoveRequest('MY_RideRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	RIDE_LIST[info.szName] = nil
	UI.RemoveRequest('MY_RideRequest', info.szName)
	info.fnRefuse()
end

function D.GetRequestStatus(info)
	local szStatus, szMsg = 'normal'
	if O.bAcceptAll then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
	elseif O.bAcceptCustom and O.tAcceptCustom[info.szName] then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s custom ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
	elseif info.bFriend and O.bAcceptFriend then
		szStatus = 'accept'
		szMsg = _L('Auto accept friend %s ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
	elseif info.bTongMember and O.bAcceptTong then
		szStatus = 'accept'
		szMsg = _L('Auto tong member friend %s ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
	elseif O.bRefuseOthers then
		szStatus = 'refuse'
		szMsg = _L('Auto refuse %s ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
	elseif O.bRefuseUnknown and not info.bFriend and not info.bTongMember then
		szStatus = 'refuse'
		szMsg = _L('Auto refuse %s ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
	end
	return szStatus, szMsg
end

function D.DoAutoAction(info)
	local bAction = false
	local szStatus, szMsg = D.GetRequestStatus(info)
	if szStatus == 'refuse' then
		bAction = true
		D.RefuseRequest(info)
	elseif szStatus == 'accept' then
		bAction = true
		D.AcceptRequest(info)
	end
	if szMsg then
		LIB.Sysmsg(szMsg)
	end
	return bAction, szStatus, szMsg
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	if not O.bEnable or not frame or not frame:IsValid() then
		return
	end
	if szMsgName == 'OnInviteFollow' then
		local hContent = frame:Lookup('Wnd_All', 'Handle_Message')
		local txt = hContent and hContent:Lookup(0)
		local szMsg, szType, szName = txt and txt:GetType() == 'Text' and txt:GetText()
		for k, szMsgTpl in pairs(RIDE_MSG) do
			szName = szMsg:match(szMsgTpl)
			if szName then
				szType = k
				break
			end
		end
		if szType then
			local fnAccept = Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
			local fnRefuse = Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
			if fnAccept and fnRefuse then
				local info = RIDE_LIST[szName]
				if not info then
					info = {}
					RIDE_LIST[szName] = info
				end
				info.szName = szName
				info.szDesc = szMsg
				info.bFriend     = LIB.IsFriend(szName)
				info.bTongMember = LIB.IsTongMember(szName)
				info.fnAccept = function()
					RIDE_LIST[szName] = nil
					Call(fnAccept)
				end
				info.fnRefuse = function()
					RIDE_LIST[szName] = nil
					Call(fnRefuse)
				end
				-- »ñÈ¡dwID
				local tar = LIB.GetObject(TARGET.PLAYER, szName)
				if not info.dwID and tar then
					info.dwID = tar.dwID
				end
				if not info.dwID and MY_Farbnamen and MY_Farbnamen.Get then
					local data = MY_Farbnamen.Get(szName)
					if data then
						info.dwID = data.dwID
					end
				end
				if not D.DoAutoAction(info) then
					UI.ReplaceRequest('MY_RideRequest', info.szName, info)
				end
				-- ¹Ø±Õ¶Ô»°¿ò
				frame.fnAutoClose = nil
				frame.fnCancelAction = nil
				frame.szCloseSound = nil
				Wnd.CloseWindow(frame)
			end
		end
	end
end

LIB.RegisterEvent('ON_MESSAGE_BOX_OPEN.MY_RideRequest' , D.OnMessageBoxOpen)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndComboBox', {
		x = x, y = y, w = 120,
		text = _L['MY_RideRequest'],
		menu = D.GetMenu,
		tip = _L['Optimize ride and emotion request'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	}):Width() + 5
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
				bEnable = true,
				bRefuseOthers = true,
				bRefuseUnknown = true,
				bAcceptTong = true,
				bAcceptFriend = true,
				bAcceptAll = true,
				bAcceptCustom = true,
				tAcceptCustom = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				bRefuseOthers = true,
				bRefuseUnknown = true,
				bAcceptTong = true,
				bAcceptFriend = true,
				bAcceptAll = true,
				bAcceptCustom = true,
				tAcceptCustom = true,
			},
			root = O,
		},
	},
}
MY_RideRequest = LIB.GeneGlobalNS(settings)
end

--------------------------------------------------------------------------------
-- ×¢²áÑûÇë
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'FromIconID',
	nIconFrame = 3554,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_RideRequest')
	wnd.info = info
	wnd.OnMouseEnter = D.OnMouseEnter
	wnd.OnMouseLeave = D.OnMouseLeave
	wnd:Lookup('', 'Text_Name'):SetText(info.szName)

	local ui = UI(wnd)
	ui:Append('WndButton', {
		name = 'Btn_Accept',
		x = 326, y = 9, w = 60, h = 34,
		buttonstyle = 'FLAT',
		text = g_tStrings.STR_ACCEPT,
		onclick = D.OnLButtonClick,
	})
	ui:Append('WndButton', {
		name = 'Btn_Refuse',
		x = 393, y = 9, w = 60, h = 34,
		buttonstyle = 'FLAT',
		text = g_tStrings.STR_REFUSE,
		onclick = D.OnLButtonClick,
	})

	return wnd
end

function R.GetTip(info)
	return GetFormatText(info.szDesc)
end

function R.GetMenu()
	return D.GetMenu()
end

function R.OnClear()
	RIDE_LIST = {}
end

UI.RegisterRequest('MY_RideRequest', R)
