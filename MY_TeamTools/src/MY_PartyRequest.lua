--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 组队助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_PartyRequest'
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
local PR_INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_PartyRequest.ini'
local PR_PARTY_REQUEST = {}

local O = X.CreateUserSettingsModule('MY_PartyRequest', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bRefuseLowLv = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto refuse low level player'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bRefuseRobot = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto refuse robot player'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptTong = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto accept tong member'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptCamp = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto accept same camp'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptFriend = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto accept friend'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptAll = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto accept all'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAcceptCustom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto accept specific names'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAcceptCustom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_PartyRequest'],
			_L['Auto accept specific names'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})
RegisterCustomData('MY_PartyRequest.tAcceptCustom')

function D.GetMenu()
	local menu = {
		szOption = _L['MY_PartyRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = O.bEnable,
			fnAction = function()
				O.bEnable = not O.bEnable
			end,
		},
		X.CONSTANT.MENU_DIVIDER,
		{
			szOption = _L['Auto refuse low level player'],
			bCheck = true, bChecked = O.bRefuseLowLv,
			fnAction = function()
				O.bRefuseLowLv = not O.bRefuseLowLv
			end,
			fnDisable = function() return not O.bEnable end,
		},
		{
			szOption = _L['Auto refuse robot player'],
			bCheck = true, bChecked = O.bRefuseRobot,
			fnAction = function()
				O.bRefuseRobot = not O.bRefuseRobot
			end,
			fnMouseEnter = function()
				local szXml = GetFormatText(_L['Full level and equip score less than 2/3 of yours'], nil, 255, 255, 0)
				OutputTip(szXml, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
			fnMouseLeave = function()
				HideTip()
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
		if not info.dwID or (not info.bDetail and IsCtrlKeyDown()) then
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			X.SendBgMsg(info.szName, 'RL', {'ASK'})
			this:Enable(false)
			this:Lookup('', 'Text_Default'):SetText(_L['loading...'])
			X.OutputSystemMessage(_L['If it is always loading, the target may not install plugin or refuse.'])
		elseif info.dwID then
			X.ViewOtherPlayerByID(info.dwID)
		end
	elseif this.info then
		if IsCtrlKeyDown() then
			X.EditBox_AppendLinkPlayer(this.info.szName)
		elseif IsAltKeyDown() and this.info.dwID then
			X.ViewOtherPlayerByID(this.info.dwID)
		end
	end
end

function D.OnRButtonClick()
	if this.info then
		PopupMenu(X.InsertPlayerContextMenu({}, this.info.szName, this.info.dwID))
	end
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'Btn_Lookup' then
		local info = this:GetParent().info
		if info.dwID and not info.bDetail then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szTip = GetFormatText(_L['Press ctrl and click to ask detail.'])
			OutputTip(szTip, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
		end
	elseif this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = MY_Farbnamen and MY_Farbnamen.GetTip(this.info.szName)
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
	return Station.Lookup('Normal2/MY_PartyRequest')
end

function D.OpenPanel()
	if D.GetFrame() then
		return
	end
	X.UI.OpenFrame(PR_INI_PATH, 'MY_PartyRequest')
end

-- 判断是否需要更新界面
function D.CheckRequestUpdate(info)
	if not info.szName or not info.fnAccept or (info.dwDelayTime and info.dwDelayTime > GetTime()) then
		X.UI.RemoveRequest('MY_PartyRequest', info.szName)
	else
		X.UI.ReplaceRequest('MY_PartyRequest', info.szName, info)
	end
end

function D.OnPeekPlayer(dwID, eState, kPlayer)
	if eState == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
		local me = X.GetClientPlayer()
		local dwTarType, dwTarID = me.GetTarget()
		X.SetClientPlayerTarget(TARGET.PLAYER, dwID)
		X.SetClientPlayerTarget(dwTarType, dwTarID)
		local p = X.GetPlayer(dwID)
		if p then
			local mnt = p.GetKungfuMount()
			local data = { nil, dwID, mnt and mnt.dwSkillID or nil, false }
			D.Feedback(p.szName, data, false)
		end
	end
end

function D.PeekPlayer(dwID)
	X.PeekOtherPlayerByID(dwID, D.OnPeekPlayer)
end

function D.AcceptRequest(info)
	PR_PARTY_REQUEST[info.szName] = nil
	X.UI.RemoveRequest('MY_PartyRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	PR_PARTY_REQUEST[info.szName] = nil
	X.UI.RemoveRequest('MY_PartyRequest', info.szName)
	info.fnRefuse()
end

function D.GetRequestStatus(info)
	local szStatus, szMsg = 'normal'
	if O.bAcceptAll then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif O.bAcceptCustom and O.tAcceptCustom[info.szName] then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s(%s %d%s) custom party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bFriend and O.bAcceptFriend then
		szStatus = 'accept'
		szMsg = _L('Auto accept friend %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bTongMember and O.bAcceptTong then
		szStatus = 'accept'
		szMsg = _L('Auto tong member friend %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bSameCamp and O.bAcceptCamp then
		szStatus = 'accept'
		szMsg = _L('Auto camp %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	end
	if szStatus == 'normal' and not info.bFriend and not info.bTongMember then
		if O.bRefuseRobot and info.dwID and info.nLevel == X.CONSTANT.MAX_PLAYER_LEVEL then
			local me = X.GetClientPlayer()
			local tar = X.GetPlayer(info.dwID)
			if tar then
				local nScore = tar.GetTotalEquipScore()
				if nScore == 0 then
					szStatus = 'suspicious'
				elseif tar.GetTotalEquipScore() < me.GetTotalEquipScore() * 2 / 3 then
					szStatus = 'refuse'
					szMsg = _L('Auto refuse %s(%s %d%s) party request, equip score: %d, go to MY/raid/teamtools panel if you want to turn off this feature.',
						info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL, nScore)
				end
			end
		end
		if O.bRefuseLowLv and info.nLevel < X.CONSTANT.MAX_PLAYER_LEVEL then
			szStatus = 'refuse'
			szMsg = _L('Auto refuse %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
				info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
		end
	end
	return szStatus, szMsg
end

function D.DoAutoAction(info)
	local bAction, szStatus, szMsg = false
	if info.szName and info.fnAccept then
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
	local szPrefix, szName = unpack(X.SplitString(szMsgName, '_', true, 2))
	if not O.bEnable or not frame or not frame:IsValid() or (szPrefix ~= 'ATMP' and szPrefix ~= 'IMTP') then
		return
	end
	local fnAccept = X.GetMessageBoxButtonAction(frame, g_tStrings.STR_ACCEPT)
	local fnRefuse = X.GetMessageBoxButtonAction(frame, g_tStrings.STR_REFUSE)
	if fnAccept and fnRefuse then
		-- 获取组队方法
		local info = PR_PARTY_REQUEST[szName]
		if not info then
			info = {}
			PR_PARTY_REQUEST[szName] = info
		end
		info.fnAccept = function()
			PR_PARTY_REQUEST[szName] = nil
			X.Call(fnAccept)
		end
		info.fnRefuse = function()
			PR_PARTY_REQUEST[szName] = nil
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
	local szName, nCamp, dwForce, nLevel, nType, nClientVersionType = arg0, arg1, arg2, arg3, arg4, arg10
	local info = PR_PARTY_REQUEST[szName]
	if not info then
		info = {}
		PR_PARTY_REQUEST[szName] = info
	end
	local me = X.GetClientPlayerInfo()
	-- 判断对方是否已在进组列表中
	info.szType      = event == 'PARTY_INVITE_REQUEST' and 'invite' or 'request'
	info.szName      = szName
	info.nCamp       = nCamp
	info.dwForce     = dwForce
	info.nLevel      = nLevel
	info.bFriend     = X.IsFellowship(szName)
	info.bTongMember = X.IsTongMember(szName)
	info.bSameCamp   = info.nCamp == me.nCamp
	info.nClientVersionType = nClientVersionType
	info.dwDelayTime = nil
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
	-- 自动拒绝 没拒绝的自动申请装备
	local bAction, szStatus = D.DoAutoAction(info)
	if szStatus == 'suspicious' then
		info.dwDelayTime = GetTime() + 2000
		D.DelayInterval()
	end
	if not bAction then
		if info.dwID then
			D.PeekPlayer(info.dwID)
		end
		D.CheckRequestUpdate(info)
	end
end

function D.DelayInterval()
	local dwTime, dwDelayTime = GetTime(), nil
	for _, info in pairs(PR_PARTY_REQUEST) do
		if info.dwDelayTime and info.dwDelayTime > dwTime then
			dwDelayTime = math.min(dwDelayTime or math.huge, info.dwDelayTime + 75)
		end
		D.CheckRequestUpdate(info)
	end
	if dwDelayTime then
		X.DelayCall('MY_PartyRequest', dwDelayTime - dwTime, D.DelayInterval)
	end
end

function D.Feedback(szName, data, bDetail)
	local info = PR_PARTY_REQUEST[szName]
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

X.RegisterEvent('PEEK_OTHER_PLAYER', 'MY_PartyRequest'   , D.OnPeekPlayer  )
X.RegisterEvent('PARTY_INVITE_REQUEST', 'MY_PartyRequest', D.OnApplyRequest)
X.RegisterEvent('PARTY_APPLY_REQUEST', 'MY_PartyRequest' , D.OnApplyRequest)
X.RegisterEvent('ON_MESSAGE_BOX_OPEN', 'MY_PartyRequest' , D.OnMessageBoxOpen)

X.RegisterInit('MY_PartyRequest', function()
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
		text = _L['MY_PartyRequest'],
		menu = D.GetMenu,
	}):Width() + 5
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_PartyRequest',
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
MY_PartyRequest = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 注册邀请
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'ui\\Image\\button\\SystemButton.UITex',
	nIconFrame = 8,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(PR_INI_PATH, 'Wnd_PartyRequest')
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

	hItem:Lookup('Handle_Status/Handle_Mobile'):SetVisible(X.IsMobileClient(info.nClientVersionType))

	hItem:Lookup('Handle_Status'):FormatAllItemPos()

	if info.bDetail and info.bEx == 'Author' then
		hItem:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	end
	hItem:Lookup('Text_Name'):SetText(info.szName)
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
		text = info.dwID and g_tStrings.STR_LOOKUP or _L['Ask details'],
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
		return GetFormatText(_L['Party invite request.'])
	end
	return GetFormatText(_L['Party apply request.'])
end

function R.GetMenu()
	return D.GetMenu()
end

function R.OnClear()
	PR_PARTY_REQUEST = {}
end

X.UI.RegisterRequest('MY_PartyRequest', R)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
