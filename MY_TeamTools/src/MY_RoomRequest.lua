--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 房间助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_RoomRequest'
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
local D = {}
local PR_INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_RoomRequest.ini'
local PR_ROOM_REQUEST = {}

local O = X.CreateUserSettingsModule('MY_RoomRequest', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptTeam = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept team member'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptTong = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept tong member'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptCamp = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept same camp'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptFriend = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept friend'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptAll = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept all'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptCustom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept specific names'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAcceptCustom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_RoomRequest'],
			_L['Auto accept specific names list'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})

function D.GetMenu()
	local menu = {
		szOption = _L['MY_RoomRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = O.bEnable,
			fnAction = function()
				O.bEnable = not O.bEnable
			end,
		},
		X.CONSTANT.MENU_DIVIDER,
		{
			szOption = _L['Auto accept friend'],
			bCheck = true, bChecked = O.bAcceptFriend,
			fnAction = function()
				O.bAcceptFriend = not O.bAcceptFriend
			end,
			fnDisable = function() return not O.bEnable end,
		},
		{
			szOption = _L['Auto accept team member'],
			bCheck = true, bChecked = O.bAcceptTeam,
			fnAction = function()
				O.bAcceptTeam = not O.bAcceptTeam
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
			szOption = _L['Auto accept same camp'],
			bCheck = true, bChecked = O.bAcceptCamp,
			fnAction = function()
				O.bAcceptCamp = not O.bAcceptCamp
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
	for szGlobalName, bEnable in pairs(O.tAcceptCustom) do
		table.insert(t, {
			szOption = szGlobalName,
			bCheck = true, bChecked = bEnable,
			fnAction = function()
				O.tAcceptCustom[szGlobalName] = not O.tAcceptCustom[szGlobalName]
				O.tAcceptCustom = O.tAcceptCustom
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				O.tAcceptCustom[szGlobalName] = nil
				O.tAcceptCustom = O.tAcceptCustom
				X.UI.ClosePopupMenu()
			end,
			fnDisable = function() return not O.bEnable or not O.bAcceptCustom end,
		})
	end
	if #t ~= 0 then
		table.insert(t, X.CONSTANT.MENU_DIVIDER)
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
	return menu
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Accept' then
		D.AcceptRequest(this:GetParent().info)
	elseif name == 'Btn_Refuse' then
		D.RefuseRequest(this:GetParent().info)
	elseif name == 'Btn_Lookup' then
		local info = this:GetParent().info
		if not info.bDetail and IsCtrlKeyDown() then
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			X.SendBgMsg(info.szGlobalName, 'RL', {'ASK'})
			this:Enable(false)
			this:Lookup('', 'Text_Default'):SetText(_L['loading...'])
			X.OutputSystemMessage(_L['If it is always loading, the target may not install plugin or refuse.'])
		elseif info.szGlobalID then
			X.ViewOtherPlayerByGlobalID(info.dwServerID, info.szGlobalID)
		end
	elseif this.info then
		local info = this.info
		if IsCtrlKeyDown() then
			X.EditBox_AppendLinkPlayer(info.szGlobalName)
		elseif IsAltKeyDown() then
			X.ViewOtherPlayerByGlobalID(info.dwServerID, info.szGlobalID)
		end
	end
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'Btn_Lookup' then
		local info = this:GetParent().info
		if not info.bDetail then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szTip = GetFormatText(_L['Press ctrl and click to ask detail.'])
			OutputTip(szTip, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
		end
	elseif this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = MY_Farbnamen and MY_Farbnamen.GetTip(this.info.szGlobalID)
		if szTip then
			OutputTip(szTip, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
		end
	end
end

function D.OnMouseLeave()
	if this.info then
		HideTip()
	end
end

function D.GetFrame()
	return Station.Lookup('Normal2/MY_RoomRequest')
end

function D.OpenPanel()
	if D.GetFrame() then
		return
	end
	X.UI.OpenFrame(PR_INI_PATH, 'MY_RoomRequest')
end

-- 判断是否需要更新界面
function D.CheckRequestUpdate(info)
	if not info.szGlobalName or not info.fnAccept or (info.dwDelayTime and info.dwDelayTime > GetTime()) then
		X.UI.RemoveRequest('MY_RoomRequest', info.szGlobalID)
	else
		X.UI.ReplaceRequest('MY_RoomRequest', info.szGlobalID, info)
	end
end

function D.OnPeekPlayer(szGlobalID, eState, kPlayer)
	if kPlayer and eState == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
		local me = X.GetClientPlayer()
		local dwType, dwID = me.GetTarget()
		X.SetClientPlayerTarget(TARGET.PLAYER, kPlayer.dwID)
		X.SetClientPlayerTarget(dwType, dwID)
		local mnt = kPlayer.GetKungfuMount()
		local data = { nil, kPlayer.dwID, mnt and mnt.dwSkillID or nil, false }
		D.Feedback(kPlayer.szName, data, false)
	end
end

function D.PeekPlayer(szGlobalID, dwServerID)
	X.PeekOtherPlayerByGlobalID(dwServerID, szGlobalID, D.OnPeekPlayer)
end

function D.AcceptRequest(info)
	PR_ROOM_REQUEST[info.szGlobalID] = nil
	X.UI.RemoveRequest('MY_RoomRequest', info.szGlobalID)
	info.fnAccept()
end

function D.RefuseRequest(info)
	PR_ROOM_REQUEST[info.szGlobalID] = nil
	X.UI.RemoveRequest('MY_RoomRequest', info.szGlobalID)
	info.fnRefuse()
end

function D.GetRequestStatus(info)
	local szStatus, szMsg = 'normal'
	if O.bAcceptAll then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s(%s %d%s) room request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szGlobalName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif O.bAcceptCustom and O.tAcceptCustom[info.szGlobalName] then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s(%s %d%s) custom room request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szGlobalName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bFriend and O.bAcceptFriend then
		szStatus = 'accept'
		szMsg = _L('Auto accept friend %s(%s %d%s) room request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szGlobalName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bTeamMember and O.bAcceptTeam then
		szStatus = 'accept'
		szMsg = _L('Auto tong member friend %s(%s %d%s) room request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szGlobalName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bTongMember and O.bAcceptTong then
		szStatus = 'accept'
		szMsg = _L('Auto tong member friend %s(%s %d%s) room request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szGlobalName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bSameCamp and O.bAcceptCamp then
		szStatus = 'accept'
		szMsg = _L('Auto camp %s(%s %d%s) room request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szGlobalName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	end
	return szStatus, szMsg
end

function D.DoAutoAction(info)
	local bAction, szStatus, szMsg = false
	if info.szGlobalName and info.fnAccept then
		szStatus, szMsg = D.GetRequestStatus(info)
		if szStatus == 'refuse' then
			bAction = true
			D.RefuseRequest(info)
		elseif szStatus == 'accept' then
			bAction = true
			D.AcceptRequest(info)
		end
		if szMsg then
			X.OutputSystemMessage(szMsg)
		end
	end
	return bAction, szStatus, szMsg
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	local szPrefix, szGlobalID = unpack(X.SplitString(szMsgName, '_', true, 2))
	if not O.bEnable or not frame or not frame:IsValid() or (szPrefix ~= 'RMIV' and szPrefix ~= 'RMAP') then
		return
	end
	local fnAccept = X.GetMessageBoxButtonAction(frame, 1)
	local fnRefuse = X.GetMessageBoxButtonAction(frame, 2)
	if fnAccept and fnRefuse then
		-- 获取组队方法
		local info = PR_ROOM_REQUEST[szGlobalID]
		if not info then
			info = {}
			PR_ROOM_REQUEST[szGlobalID] = info
		end
		info.fnAccept = function()
			PR_ROOM_REQUEST[szGlobalID] = nil
			X.Call(fnAccept)
		end
		info.fnRefuse = function()
			PR_ROOM_REQUEST[szGlobalID] = nil
			X.Call(fnRefuse)
		end
		D.DoAutoAction(info)
		-- 关闭对话框
		frame.fnAutoClose = nil
		frame.fnCancelAction = nil
		frame.szCloseSound = nil
		X.UI.CloseFrame(frame)
	end
end

function D.OnApplyRequest(event)
	if not O.bEnable then
		return
	end
	local eType = arg0
	local szName = arg1
	local szGlobalID = arg2
	local dwServerID = arg4
	local tPlayer = MY_Farbnamen and MY_Farbnamen.Get and MY_Farbnamen.Get(szGlobalID)
	local info = PR_ROOM_REQUEST[szGlobalID]
	if not info then
		info = {}
		PR_ROOM_REQUEST[szGlobalID] = info
	end
	local me = X.GetClientPlayerInfo()
	local szServerName = X.GetServerNameByID(dwServerID)
	-- 判断对方是否已在进组列表中
	local bTeamMember = false
	for _, dwID in ipairs(X.GetTeamMemberList()) do
		local tMember = X.GetTeamMemberInfo(dwID)
		if tMember and tMember.szGlobalID == szGlobalID then
			bTeamMember = true
			break
		end
	end
	info.szType       = eType == GLOBAL_ROOM_JOIN_TYPE.INVITE and 'invite' or 'request'
	info.szGlobalID   = szGlobalID
	info.dwServerID   = dwServerID
	info.szName       = szName
	info.szGlobalName = X.AssemblePlayerGlobalName(szName, szServerName)
	info.nCamp        = tPlayer and tPlayer.nCamp or -1
	info.dwForce      = tPlayer and tPlayer.dwForceID or -1
	info.nLevel       = tPlayer and tPlayer.nLevel or -1
	info.bFriend      = X.IsFellowship(info.szGlobalName)
	info.bTeamMember  = bTeamMember
	info.bTongMember  = szServerName == X.GetServerOriginName() and X.IsTongMember(szName)
	info.bSameCamp    = info.nCamp == me.nCamp
	info.dwDelayTime  = nil
	-- 自动拒绝 没拒绝的自动申请装备
	local bAction, szStatus = D.DoAutoAction(info)
	if szStatus == 'suspicious' then
		info.dwDelayTime = GetTime() + 2000
		D.DelayInterval()
	end
	if not bAction then
		D.PeekPlayer(info.szGlobalID, info.dwServerID)
		D.CheckRequestUpdate(info)
	end
end

function D.DelayInterval()
	local dwTime, dwDelayTime = GetTime(), nil
	for _, info in pairs(PR_ROOM_REQUEST) do
		if info.dwDelayTime and info.dwDelayTime > dwTime then
			dwDelayTime = math.min(dwDelayTime or math.huge, info.dwDelayTime + 75)
		end
		D.CheckRequestUpdate(info)
	end
	if dwDelayTime then
		X.DelayCall('MY_RoomRequest', dwDelayTime - dwTime, D.DelayInterval)
	end
end

function D.Feedback(szName, data, bDetail)
	local tPlayer = MY_Farbnamen and MY_Farbnamen.Get and MY_Farbnamen.Get(szName)
	local info = tPlayer and tPlayer.szGlobalID and PR_ROOM_REQUEST[tPlayer.szGlobalID]
	if info then
		info.bDetail    = bDetail
		info.dwID       = data[2]
		info.dwKungfuID = data[3]
		info.nGongZhan  = data[4]
		info.bEx        = data[5]
		D.DoAutoAction(info)
	end
	D.DelayInterval()
end

X.RegisterEvent('PEEK_OTHER_PLAYER', 'MY_RoomRequest'   , D.OnPeekPlayer  )
X.RegisterEvent('GLOBAL_ROOM_JOIN_REQUEST', 'MY_RoomRequest', D.OnApplyRequest)
X.RegisterEvent('ON_MESSAGE_BOX_OPEN', 'MY_RoomRequest' , D.OnMessageBoxOpen)

X.RegisterInit('MY_RoomRequest', function()
	for _, k in ipairs({'tAcceptCustom'}) do
		if D[k] then
			X.SafeCall(X.Set, O, k, D[k])
			D[k] = nil
		end
	end
end)

X.RegisterBgMsg('RL', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not bIsSelf then
		if data[1] == 'Feedback' then
			D.Feedback(szName, data, true)
		end
	end
end)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 120,
		text = _L['MY_RoomRequest'],
		menu = D.GetMenu,
	}):Width() + 5
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoomRequest',
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
MY_RoomRequest = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 注册邀请
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'ui\\Image\\button\\SystemButton.UITex',
	nIconFrame = 20,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(PR_INI_PATH, 'Wnd_RoomRequest')
	wnd.info = info
	wnd.OnMouseEnter = D.OnMouseEnter
	wnd.OnMouseLeave = D.OnMouseLeave
	wnd.OnLButtonClick = D.OnLButtonClick
	wnd.OnRButtonClick = D.OnRButtonClick

	local hItem = wnd:Lookup('', '')
	if info.dwKungfuID then
		hItem:Lookup('Image_Icon'):FromIconID(Table_GetSkillIconID(info.dwKungfuID, 1))
	else
		hItem:Lookup('Image_Icon'):FromUITex(GetForceImage(info.dwForce))
	end
	hItem:Lookup('Handle_Status/Handle_Gongzhan'):SetVisible(info.nGongZhan == 1)

	local szCampImg, nCampFrame = X.GetCampImage(info.nCamp)
	if szCampImg then
		hItem:Lookup('Handle_Status/Handle_Camp/Image_Camp'):FromUITex(szCampImg, nCampFrame)
	end
	hItem:Lookup('Handle_Status/Handle_Camp'):SetVisible(not not szCampImg)

	hItem:Lookup('Handle_Status'):FormatAllItemPos()

	if info.bDetail and info.bEx == 'Author' then
		hItem:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	end
	hItem:Lookup('Text_Name'):SetText(info.szGlobalName)
	hItem:Lookup('Text_Level'):SetText(info.nLevel)

	local ui = X.UI(wnd)
	ui:Append('WndButton', {
		name = 'Btn_Accept',
		x = 240, y = 9, w = 60, h = 34,
		buttonStyle = 'FLAT',
		text = g_tStrings.STR_ACCEPT,
		onClick = D.OnLButtonClick,
	})
	ui:Append('WndButton', {
		name = 'Btn_Refuse',
		x = 305, y = 9, w = 60, h = 34,
		buttonStyle = 'FLAT',
		text = g_tStrings.STR_REFUSE,
		onClick = D.OnLButtonClick,
	})
	ui:Append('WndButton', {
		name = 'Btn_Lookup',
		x = 370, y = 9, w = 82, h = 34,
		buttonStyle = 'FLAT',
		text = g_tStrings.STR_LOOKUP,
		onHover = function(bIn)
			if bIn then
				D.OnMouseEnter()
			else
				D.OnMouseLeave()
			end
		end,
		onClick = D.OnLButtonClick,
	})

	return wnd
end

function R.GetTip(info)
	if info.szType == 'invite' then
		return GetFormatText(_L['Room invite request.'])
	end
	return GetFormatText(_L['Room apply request.'])
end

function R.GetMenu()
	return D.GetMenu()
end

function R.OnClear()
	PR_ROOM_REQUEST = {}
end

X.UI.RegisterRequest('MY_RoomRequest', R)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
