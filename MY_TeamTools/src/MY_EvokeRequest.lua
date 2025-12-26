--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 召请助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_EvokeRequest'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_EvokeRequest.ini'
local O = X.CreateUserSettingsModule('MY_EvokeRequest', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_EvokeRequest'],
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

local EVOKE_MSG = {
	['A2M'] = g_tStrings.MENTOR_APPRENTICE_EVOKE_MSG,
	['M2A'] = g_tStrings.MENTOR_MENTOR_EVOKE_MSG,
	['FRIEND'] = g_tStrings.MENTOR_FRIEND_EVOKE_MSG,
	['TONG'] = g_tStrings.MENTOR_TONG_EVOKE_MSG,
	['TONGALL'] = g_tStrings.MENTOR_TONGALL_EVOKE_MSG,
	['TONGALLS'] = g_tStrings.MENTOR_TONGALLS_EVOKE_MSG,
	['ZUIYUAN'] = g_tStrings.MENTOR_QINGMINGJIE_ZUIYUAN_EVOKE_MSG_MSG,
	['PARTY'] = g_tStrings.MENTOR_PARTY_EVOKE_MSG,
}
local EVOKE_LIST = {}

function D.GetMenu()
	local menu = {
		szOption = _L['MY_EvokeRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = MY_EvokeRequest.bEnable,
			fnAction = function()
				MY_EvokeRequest.bEnable = not MY_EvokeRequest.bEnable
			end,
		},
	}
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
		PopupMenu(X.InsertPlayerContextMenu({}, this.info.szName, this.info.dwID))
	end
end

function D.OnMouseEnter()
	if this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = GetFormatText(this.info.szDesc)
		OutputTip(szTip, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
	end
end

function D.OnMouseLeave()
	if this.info then
		HideTip()
	end
end

function D.AcceptRequest(info)
	EVOKE_LIST[info.szName] = nil
	X.UI.RemoveRequest('MY_EvokeRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	EVOKE_LIST[info.szName] = nil
	X.UI.RemoveRequest('MY_EvokeRequest', info.szName)
	info.fnRefuse()
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	if not O.bEnable or not frame or not frame:IsValid() then
		return
	end
	if szMsgName:find('^A_E_M_') then
		local szName = szMsgName:sub(7)
		local hContent = X.GetMessageBoxContentHandle(frame)
		local txt = hContent and hContent:Lookup(0)
		local szMsg, szType = txt and txt:GetType() == 'Text' and txt:GetText()
		for k, szMsgTpl in pairs(EVOKE_MSG) do
			if FormatString(szMsgTpl, szName) == szMsg then
				szType = k
				break
			end
		end
		if szType then
			local fnAccept = X.GetMessageBoxButtonAction(frame, 1)
			local fnRefuse = X.GetMessageBoxButtonAction(frame, 2)
			if fnAccept and fnRefuse then
				local info = EVOKE_LIST[szName]
				if not info then
					info = {}
					EVOKE_LIST[szName] = info
				end
				info.szType = szType
				info.szName = szName
				info.szDesc = szMsg
				info.fnAccept = function()
					EVOKE_LIST[szName] = nil
					X.Call(fnAccept)
				end
				info.fnRefuse = function()
					EVOKE_LIST[szName] = nil
					X.Call(fnRefuse)
				end
				-- 获取dwID
				local tar = X.GetTargetHandle(TARGET.PLAYER, szName)
				if not info.dwID and tar then
					info.dwID = tar.dwID
				end
				if not info.dwID and MY_Farbnamen and MY_Farbnamen.Get then
					local data = MY_Farbnamen.Get(szName)
					if data then
						info.dwID = data.dwID
					end
				end
				X.UI.ReplaceRequest('MY_EvokeRequest', info.szName, info)
				-- 关闭对话框
				frame.fnAutoClose = nil
				frame.fnCancelAction = nil
				frame.szCloseSound = nil
				X.UI.CloseFrame(frame)
			end
		end
	end
end

X.RegisterEvent('ON_MESSAGE_BOX_OPEN', 'MY_EvokeRequest' , D.OnMessageBoxOpen)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 120,
		text = _L['MY_EvokeRequest'],
		menu = D.GetMenu,
	}):Width() + 5
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_EvokeRequest',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_EvokeRequest = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 注册邀请
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'ui\\Image\\button\\SystemButton.UITex',
	nIconFrame = 55,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_EvokeRequest')
	wnd.info = info
	wnd.OnMouseEnter = D.OnMouseEnter
	wnd.OnMouseLeave = D.OnMouseLeave
	wnd:Lookup('', 'Text_Name'):SetText(info.szName)

	local ui = X.UI(wnd)
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

function R.GetIcon(info, szImage, nFrame)
	if info.szType == 'A2M' or info.szType == 'M2A' then
		local tFellowship = X.GetFellowshipInfo(info.szName)
		local tFei = tFellowship and X.GetFellowshipEntryInfo(tFellowship.xID)
		if tFei then
			local szAvatarFile, nAvatarFrame, bAnimate = X.GetPlayerAvatar(tFei.dwForceID, tFei.nRoleType, tFei.dwMiniAvatarID)
			if szAvatarFile and not bAnimate then
				szImage, nFrame = szAvatarFile, nAvatarFrame
			end
		end
	elseif info.szType == 'FRIEND' then
		szImage, nFrame = 'FromIconID', 307
	elseif info.szType == 'TONG' then
		szImage, nFrame = 'FromIconID', 305
	elseif info.szType == 'TONGALL' then
		szImage, nFrame = 'FromIconID', 592
	elseif info.szType == 'TONGALLS' then
		szImage, nFrame = 'FromIconID', 591
	end
	return szImage, nFrame
end

function R.GetMenu()
	return D.GetMenu()
end

function R.OnClear()
	EVOKE_LIST = {}
end

X.UI.RegisterRequest('MY_EvokeRequest', R)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
