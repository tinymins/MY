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
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_RideRequest.ini'
local O = X.CreateUserSettingsModule('MY_RideRequest', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bRefuseOthers = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bRefuseUnknown = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptTong = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptParty = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptFriend = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptAll = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptCustom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAcceptCustom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})
local D = {}
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
			bCheck = true, bChecked = O.bEnable,
			fnAction = function()
				O.bEnable = not O.bEnable
			end,
		},
		CONSTANT.MENU_DIVIDER,
		{
			szOption = _L['Auto accept party'],
			bCheck = true, bChecked = O.bAcceptParty,
			fnAction = function()
				O.bAcceptParty = not O.bAcceptParty
			end,
			fnDisable = function() return not O.bEnable end,
		},
		{
			szOption = _L['Auto accept friend'],
			bCheck = true, bChecked = O.bAcceptFriend,
			fnAction = function()
				O.bAcceptFriend = not O.bAcceptFriend
			end,
			fnDisable = function() return not O.bEnable end,
		},
		{
			szOption = _L['Auto accept tong member'],
			bCheck = true, bChecked = O.bAcceptTong,
			fnAction = function()
				O.bAcceptTong = not O.bAcceptTong
			end,
			fnDisable = function() return not O.bEnable end,
		},
		{
			szOption = _L['Auto accept all'],
			bCheck = true, bChecked = O.bAcceptAll,
			fnAction = function()
				O.bAcceptAll = not O.bAcceptAll
			end,
			fnDisable = function() return not O.bEnable end,
		},
	}
	local t = {
		szOption = _L['Auto accept specific names'],
		bCheck = true, bChecked = O.bAcceptCustom,
		fnAction = function()
			O.bAcceptCustom = not O.bAcceptCustom
		end,
		fnDisable = function() return not O.bEnable end,
	}
	for szName, bEnable in pairs(O.tAcceptCustom) do
		table.insert(t, {
			szOption = szName,
			bCheck = true, bChecked = bEnable,
			fnAction = function()
				O.tAcceptCustom[szName] = not O.tAcceptCustom[szName]
				O.tAcceptCustom = O.tAcceptCustom
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				O.tAcceptCustom[szName] = nil
				O.tAcceptCustom = O.tAcceptCustom
				UI.ClosePopupMenu()
			end,
			fnDisable = function() return not O.bEnable or not O.bAcceptCustom end,
		})
	end
	if #t ~= 0 then
		table.insert(t, CONSTANT.MENU_DIVIDER)
	end
	table.insert(t, {
		szOption = _L['Add'],
		fnAction = function()
			GetUserInput(_L['Please input custom name, multiple split with ",[]":'], function(val)
				for _, v in ipairs(X.SplitString(val, {',', '[', ']'}, true)) do
					O.tAcceptCustom[v] = true
					O.tAcceptCustom = O.tAcceptCustom
				end
			end)
		end,
		fnDisable = function() return not O.bEnable or not O.bAcceptCustom end,
	})
	table.insert(menu, t)
	table.insert(menu, {
		szOption = _L['Auto refuse others'],
		bCheck = true, bChecked = O.bRefuseOthers,
		fnAction = function()
			O.bRefuseOthers = not O.bRefuseOthers
		end,
		fnDisable = function() return not O.bEnable end,
	})
	table.insert(menu, {
		szOption = _L['Auto refuse unknown'],
		bCheck = true, bChecked = O.bRefuseUnknown,
		fnAction = function()
			O.bRefuseUnknown = not O.bRefuseUnknown
		end,
		fnDisable = function() return not O.bEnable end,
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
		PopupMenu(X.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
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
	elseif info.bParty and O.bAcceptParty then
		szStatus = 'accept'
		szMsg = _L('Auto accept party %s ride request, go to MY/raid/teamtools panel if you want to turn off this feature.', info.szName)
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
		X.Sysmsg(szMsg)
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
			local fnAccept = X.Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
			local fnRefuse = X.Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
			if fnAccept and fnRefuse then
				local info = RIDE_LIST[szName]
				if not info then
					info = {}
					RIDE_LIST[szName] = info
				end
				info.szName = szName
				info.szDesc = szMsg
				info.bParty      = X.IsParty(szName)
				info.bFriend     = X.IsFriend(szName)
				info.bTongMember = X.IsTongMember(szName)
				info.fnAccept = function()
					RIDE_LIST[szName] = nil
					X.Call(fnAccept)
				end
				info.fnRefuse = function()
					RIDE_LIST[szName] = nil
					X.Call(fnRefuse)
				end
				-- »ñÈ¡dwID
				local tar = X.GetObject(TARGET.PLAYER, szName)
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

X.RegisterEvent('ON_MESSAGE_BOX_OPEN', 'MY_RideRequest' , D.OnMessageBoxOpen)

X.RegisterInit('MY_RideRequest', function()
	for _, k in ipairs({'tAcceptCustom'}) do
		if D[k] then
			X.SafeCall(X.Set, O, k, D[k])
			D[k] = nil
		end
	end
end)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 120,
		text = _L['MY_RideRequest'],
		menu = D.GetMenu,
		tip = {
			render = _L['Optimize ride and emotion request'],
			position = UI.TIP_POSITION.TOP_BOTTOM,
		},
	}):Width() + 5
	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_RideRequest',
	exports = {
		{
			fields = {
				'tAcceptCustom',
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'tAcceptCustom',
			},
			root = D,
		},
	},
}
MY_RideRequest = X.CreateModule(settings)
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
		buttonStyle = 'FLAT',
		text = g_tStrings.STR_ACCEPT,
		onClick = D.OnLButtonClick,
	})
	ui:Append('WndButton', {
		name = 'Btn_Refuse',
		x = 393, y = 9, w = 60, h = 34,
		buttonStyle = 'FLAT',
		text = g_tStrings.STR_REFUSE,
		onClick = D.OnLButtonClick,
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
