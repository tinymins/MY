--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 组队助手
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
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local D = {}
local PR_INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_PartyRequest.ini'
local PR_EQUIP_REQUEST = {}
local PR_PARTY_REQUEST = {}

local O = {
	bEnable       = true,
	bRefuseLowLv  = false,
	bRefuseRobot  = false,
	bAcceptTong   = false,
	bAcceptFriend = false,
	bAcceptAll    = false,
	bAcceptCustom = false,
	tAcceptCustom = {},
}
RegisterCustomData('MY_PartyRequest.bEnable')
RegisterCustomData('MY_PartyRequest.bRefuseLowLv')
RegisterCustomData('MY_PartyRequest.bRefuseRobot')
RegisterCustomData('MY_PartyRequest.bAcceptTong')
RegisterCustomData('MY_PartyRequest.bAcceptFriend')
RegisterCustomData('MY_PartyRequest.bAcceptAll')
RegisterCustomData('MY_PartyRequest.bAcceptCustom')
RegisterCustomData('MY_PartyRequest.tAcceptCustom')

function D.GetMenu()
	local menu = {
		szOption = _L['MY_PartyRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = MY_PartyRequest.bEnable,
			fnAction = function()
				MY_PartyRequest.bEnable = not MY_PartyRequest.bEnable
			end,
		},
		CONSTANT.MENU_DIVIDER,
		{
			szOption = _L['Auto refuse low level player'],
			bCheck = true, bChecked = MY_PartyRequest.bRefuseLowLv,
			fnAction = function()
				MY_PartyRequest.bRefuseLowLv = not MY_PartyRequest.bRefuseLowLv
			end,
			fnDisable = function() return not MY_PartyRequest.bEnable end,
		},
		{
			szOption = _L['Auto refuse robot player'],
			bCheck = true, bChecked = MY_PartyRequest.bRefuseRobot,
			fnAction = function()
				MY_PartyRequest.bRefuseRobot = not MY_PartyRequest.bRefuseRobot
			end,
			fnMouseEnter = function()
				local szXml = GetFormatText(_L['Full level and equip score less than 2/3 of yours'], nil, 255, 255, 0)
				OutputTip(szXml, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
			fnDisable = function() return not MY_PartyRequest.bEnable end,
		},
		{
			szOption = _L['Auto accept friend'],
			bCheck = true, bChecked = MY_PartyRequest.bAcceptFriend,
			fnAction = function()
				MY_PartyRequest.bAcceptFriend = not MY_PartyRequest.bAcceptFriend
			end,
			fnDisable = function() return not MY_PartyRequest.bEnable end,
		},
		{
			szOption = _L['Auto accept tong member'],
			bCheck = true, bChecked = MY_PartyRequest.bAcceptTong,
			fnAction = function()
				MY_PartyRequest.bAcceptTong = not MY_PartyRequest.bAcceptTong
			end,
			fnDisable = function() return not MY_PartyRequest.bEnable end,
		},
		{
			szOption = _L['Auto accept all'],
			bCheck = true, bChecked = MY_PartyRequest.bAcceptAll,
			fnAction = function()
				MY_PartyRequest.bAcceptAll = not MY_PartyRequest.bAcceptAll
			end,
			fnDisable = function() return not MY_PartyRequest.bEnable end,
		},
	}
	local t = {
		szOption = _L['Auto accept specific names'],
		bCheck = true, bChecked = MY_PartyRequest.bAcceptCustom,
		fnAction = function()
			MY_PartyRequest.bAcceptCustom = not MY_PartyRequest.bAcceptCustom
		end,
		fnDisable = function() return not MY_PartyRequest.bEnable end,
	}
	for szName, bEnable in pairs(MY_PartyRequest.tAcceptCustom) do
		insert(t, {
			szOption = szName,
			bCheck = true, bChecked = bEnable,
			fnAction = function()
				MY_PartyRequest.tAcceptCustom[szName] = not MY_PartyRequest.tAcceptCustom[szName]
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				MY_PartyRequest.tAcceptCustom[szName] = nil
				UI.ClosePopupMenu()
			end,
			fnDisable = function() return not MY_PartyRequest.bEnable or not MY_PartyRequest.bAcceptCustom end,
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
					MY_PartyRequest.tAcceptCustom[v] = true
				end
			end)
		end,
		fnDisable = function() return not MY_PartyRequest.bEnable or not MY_PartyRequest.bAcceptCustom end,
	})
	insert(menu, t)
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
			if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return LIB.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			LIB.SendBgMsg(info.szName, 'RL', {'ASK'})
			this:Enable(false)
			this:Lookup('', 'Text_Lookup'):SetText(_L['loading...'])
			LIB.Sysmsg(_L['If it is always loading, the target may not install plugin or refuse.'])
		elseif info.dwID then
			ViewInviteToPlayer(info.dwID)
		end
	elseif this.info then
		if IsCtrlKeyDown() then
			LIB.EditBox_AppendLinkPlayer(this.info.szName)
		elseif IsAltKeyDown() and this.info.dwID then
			ViewInviteToPlayer(this.info.dwID)
		end
	end
end

function D.OnRButtonClick()
	if this.info then
		PopupMenu(LIB.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
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
			OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
		end
	elseif this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = MY_Farbnamen and MY_Farbnamen.GetTip(this.info.szName)
		if szTip then
			OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
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
	Wnd.OpenWindow(PR_INI_PATH, 'MY_PartyRequest')
end

-- 判断是否需要更新界面
function D.CheckRequestUpdate(info)
	if info.dwDelayTime and info.dwDelayTime > GetTime() then
		MY_Request.Remove('MY_PartyRequest', info.szName)
	else
		MY_Request.Replace('MY_PartyRequest', info.szName, info)
	end
end

function D.OnPeekPlayer()
	if PR_EQUIP_REQUEST[arg1] then
		if arg0 == CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
			local me = GetClientPlayer()
			local dwType, dwID = me.GetTarget()
			LIB.SetTarget(TARGET.PLAYER, arg1)
			LIB.SetTarget(dwType, dwID)
			local p = GetPlayer(arg1)
			if p then
				local mnt = p.GetKungfuMount()
				local data = { nil, arg1, mnt and mnt.dwSkillID or nil, false }
				D.Feedback(p.szName, data, false)
				local info = PR_PARTY_REQUEST[p.szName]
				if info then
					D.DoAutoAction(info)
				end
			end
		end
		PR_EQUIP_REQUEST[arg1] = nil
	end
end

function D.PeekPlayer(dwID)
	PR_EQUIP_REQUEST[dwID] = true
	ViewInviteToPlayer(dwID, true)
end

function D.AcceptRequest(info)
	PR_PARTY_REQUEST[info.szName] = nil
	MY_Request.Remove('MY_PartyRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	PR_PARTY_REQUEST[info.szName] = nil
	MY_Request.Remove('MY_PartyRequest', info.szName)
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
		szMsg = _L('Auto accept %s(%s %d%s) custom request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bFriend and O.bAcceptFriend then
		szStatus = 'accept'
		szMsg = _L('Auto accept friend %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bTongMember and O.bAcceptTong then
		szStatus = 'accept'
		szMsg = _L('Auto tong member friend %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	end
	if szStatus == 'normal' and not info.bFriend and not info.bTongMember then
		if O.bRefuseRobot and info.dwID and info.nLevel == PACKET_INFO.MAX_PLAYER_LEVEL then
			local me = GetClientPlayer()
			local tar = GetPlayer(info.dwID)
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
		if O.bRefuseLowLv and info.nLevel < PACKET_INFO.MAX_PLAYER_LEVEL then
			szStatus = 'refuse'
			szMsg = _L('Auto refuse %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
				info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
		end
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
	local szPrefix, szName = unpack(LIB.SplitString(szMsgName, '_', true, 2))
	if not O.bEnable or not frame or not frame:IsValid() or (szPrefix ~= 'ATMP' and szPrefix ~= 'IMTP') then
		return
	end
	local fnAccept = Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
	local fnRefuse = Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
	if fnAccept and fnRefuse then
		-- 获取组队方法
		local info = PR_PARTY_REQUEST[szName]
		if not info then
			info = {}
			PR_PARTY_REQUEST[szName] = info
		end
		info.fnAccept = function()
			PR_PARTY_REQUEST[szName] = nil
			Call(fnAccept)
		end
		info.fnRefuse = function()
			PR_PARTY_REQUEST[szName] = nil
			Call(fnRefuse)
		end
		-- 关闭对话框
		frame.fnAutoClose = nil
		frame.fnCancelAction = nil
		frame.szCloseSound = nil
		Wnd.CloseWindow(frame)
	end
end

function D.OnApplyRequest(event)
	if not O.bEnable then
		return
	end
	local szName, nCamp, dwForce, nLevel, nType = arg0, arg1, arg2, arg3, arg4
	local info = PR_PARTY_REQUEST[szName]
	if not info then
		info = {}
		PR_PARTY_REQUEST[szName] = info
	end
	-- 判断对方是否已在进组列表中
	info.szType      = event == 'PARTY_INVITE_REQUEST' and 'invite' or 'request'
	info.szName      = szName
	info.nCamp       = nCamp
	info.dwForce     = dwForce
	info.nLevel      = nLevel
	info.bFriend     = LIB.IsFriend(szName)
	info.bTongMember = LIB.IsTongMember(szName)
	info.fnAccept    = info.fnAccept
	info.fnRefuse    = info.fnRefuse
	info.dwDelayTime = nil
	-- 获取dwID
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
			dwDelayTime = min(dwDelayTime or HUGE, info.dwDelayTime)
		end
	end
	if dwDelayTime then
		LIB.DelayCall('MY_PartyRequest', dwDelayTime - dwTime, D.DelayInterval)
	end
end

function D.Feedback(szName, data, bDetail)
	local v = PR_PARTY_REQUEST[szName]
	if v then
		v.bDetail    = bDetail
		v.dwID       = data[2]
		v.dwKungfuID = data[3]
		v.nGongZhan  = data[4]
		v.bEx        = data[5]
	end
	D.DelayInterval()
end

LIB.RegisterEvent('PEEK_OTHER_PLAYER.MY_PartyRequest'   , D.OnPeekPlayer  )
LIB.RegisterEvent('PARTY_INVITE_REQUEST.MY_PartyRequest', D.OnApplyRequest)
LIB.RegisterEvent('PARTY_APPLY_REQUEST.MY_PartyRequest' , D.OnApplyRequest)
LIB.RegisterEvent('ON_MESSAGE_BOX_OPEN.MY_PartyRequest' , D.OnMessageBoxOpen)

LIB.RegisterBgMsg('RL', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not bIsSelf then
		if data[1] == 'Feedback' then
			D.Feedback(szName, data, true)
		end
	end
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndComboBox', {
		x = x, y = y, w = 120,
		text = _L['MY_PartyRequest'],
		menu = D.GetMenu,
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
				bEnable       = true,
				bRefuseLowLv  = true,
				bRefuseRobot  = true,
				bAcceptTong   = true,
				bAcceptFriend = true,
				bAcceptAll    = true,
				bAcceptCustom = true,
				tAcceptCustom = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable       = true,
				bRefuseLowLv  = true,
				bRefuseRobot  = true,
				bAcceptTong   = true,
				bAcceptFriend = true,
				bAcceptAll    = true,
				bAcceptCustom = true,
				tAcceptCustom = true,
			},
			root = O,
		},
	},
}
MY_PartyRequest = LIB.GeneGlobalNS(settings)
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

	local szCampImg, nCampFrame = LIB.GetCampImage(info.nCamp)
	if szCampImg then
		hItem:Lookup('Handle_Status/Handle_Camp/Image_Camp'):FromUITex(szCampImg, nCampFrame)
	end
	hItem:Lookup('Handle_Status/Handle_Camp'):SetVisible(not not szCampImg)

	if info.bDetail and info.bEx == 'Author' then
		hItem:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	end
	hItem:Lookup('Text_Name'):SetText(info.szName)
	hItem:Lookup('Text_Level'):SetText(info.nLevel)

	wnd:Lookup('Btn_Accept').OnLButtonClick = D.OnLButtonClick
	wnd:Lookup('Btn_Accept', 'Text_Accept'):SetText(g_tStrings.STR_ACCEPT)
	wnd:Lookup('Btn_Refuse').OnLButtonClick = D.OnLButtonClick
	wnd:Lookup('Btn_Refuse', 'Text_Refuse'):SetText(g_tStrings.STR_REFUSE)
	wnd:Lookup('Btn_Lookup').OnMouseEnter = D.OnMouseEnter
	wnd:Lookup('Btn_Lookup').OnMouseLeave = D.OnMouseLeave
	wnd:Lookup('Btn_Lookup').OnLButtonClick = D.OnLButtonClick
	wnd:Lookup('Btn_Lookup', 'Text_Lookup'):SetText(info.dwID and g_tStrings.STR_LOOKUP or _L['Ask details'])

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

MY_Request.Register('MY_PartyRequest', R)
