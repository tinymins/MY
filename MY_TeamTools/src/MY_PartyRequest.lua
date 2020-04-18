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
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
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
local PR_PARTY_REACT = {}
local PR_PARTY_REQUEST = {}

MY_PartyRequest = {
	bEnable       = true,
	bRefuseLowLv  = false,
	bRefuseRobot  = false,
	bAcceptTong   = false,
	bAcceptFriend = false,
	bAcceptAll    = false,
	bAcceptCustom = false,
	tAcceptCustom = {},
}
LIB.RegisterCustomData('MY_PartyRequest')

function MY_PartyRequest.GetCustomNameMenu()
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
	})
	return t
end

function MY_PartyRequest.OnFrameCreate()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(g_tStrings.STR_ARENA_INVITE)
	LIB.RegisterEsc('MY_PartyRequest', D.GetFrame, D.ClosePanel)
end

function MY_PartyRequest.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		local menu = {
			{
				szOption = _L['Auto refuse low level player'],
				bCheck = true, bChecked = MY_PartyRequest.bRefuseLowLv,
				fnAction = function()
					MY_PartyRequest.bRefuseLowLv = not MY_PartyRequest.bRefuseLowLv
				end,
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
			},
			{
				szOption = _L['Auto accept friend'],
				bCheck = true, bChecked = MY_PartyRequest.bAcceptFriend,
				fnAction = function()
					MY_PartyRequest.bAcceptFriend = not MY_PartyRequest.bAcceptFriend
				end,
			},
			{
				szOption = _L['Auto accept tong member'],
				bCheck = true, bChecked = MY_PartyRequest.bAcceptTong,
				fnAction = function()
					MY_PartyRequest.bAcceptTong = not MY_PartyRequest.bAcceptTong
				end,
			},
			{
				szOption = _L['Auto accept all'],
				bCheck = true, bChecked = MY_PartyRequest.bAcceptAll,
				fnAction = function()
					MY_PartyRequest.bAcceptAll = not MY_PartyRequest.bAcceptAll
				end,
			},
		}
		insert(menu, MY_PartyRequest.GetCustomNameMenu())
		PopupMenu(menu)
	elseif name == 'Btn_Close' then
		D.ClosePanel()
	elseif name == 'Btn_Accept' then
		D.AcceptRequest(this:GetParent().info)
		D.UpdateFrame()
	elseif name == 'Btn_Refuse' then
		D.RefuseRequest(this:GetParent().info)
		D.UpdateFrame()
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

function MY_PartyRequest.OnRButtonClick()
	if this.info then
		PopupMenu(LIB.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
	end
end

function MY_PartyRequest.OnMouseEnter()
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

function MY_PartyRequest.OnMouseLeave()
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

function D.ClosePanel(bCompulsory)
	local fnAction = function()
		Wnd.CloseWindow(D.GetFrame())
		PR_PARTY_REACT = {}
		PR_PARTY_REQUEST = {}
	end
	if bCompulsory then
		fnAction()
	else
		LIB.Confirm(_L['Clear list and close?'], fnAction)
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
			end
			local info = D.GetRequestInfo(arg1)
			if info and D.DoAutoAction(info) then
				D.UpdateFrame()
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
	for i, v in ipairs_r(PR_PARTY_REQUEST) do
		if v == info then
			remove(PR_PARTY_REQUEST, i)
		end
	end
	info.fnAccept()
end

function D.RefuseRequest(info)
	for i, v in ipairs_r(PR_PARTY_REQUEST) do
		if v == info then
			remove(PR_PARTY_REQUEST, i)
		end
	end
	info.fnRefuse()
end

function D.GetRequestStatus(info)
	local szStatus, szMsg = 'normal'
	if MY_PartyRequest.bAcceptAll then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif MY_PartyRequest.bAcceptCustom and MY_PartyRequest.tAcceptCustom[info.szName] then
		szStatus = 'accept'
		szMsg = _L('Auto accept %s(%s %d%s) custom request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bFriend and MY_PartyRequest.bAcceptFriend then
		szStatus = 'accept'
		szMsg = _L('Auto accept friend %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	elseif info.bTongMember and MY_PartyRequest.bAcceptTong then
		szStatus = 'accept'
		szMsg = _L('Auto tong member friend %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
			info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
	end
	if szStatus == 'normal' and not info.bFriend and not info.bTongMember then
		if MY_PartyRequest.bRefuseRobot and info.dwID then
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
		if MY_PartyRequest.bRefuseLowLv and info.nLevel < PACKET_INFO.MAX_PLAYER_LEVEL then
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

function D.GetRequestInfo(key)
	for k, v in ipairs(PR_PARTY_REQUEST) do
		if v.szName == key or v.dwID == key then
			return v
		end
	end
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	local szPrefix, szName = unpack(LIB.SplitString(szMsgName, '_', true, 2))
	if not MY_PartyRequest.bEnable or not frame or not frame:IsValid()
	or (szMsgName:sub(1, 5) ~= 'ATMP_' and szMsgName:sub(1, 5) ~= 'IMTP_') then
		return
	end
	local fnAccept = Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
	local fnRefuse = Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
	if fnAccept and fnRefuse then
		-- 获取组队方法
		PR_PARTY_REACT[szName] = {
			fnAccept = function()
				Call(fnAccept)
				PR_PARTY_REACT[szName] = nil
			end,
			fnRefuse = function()
				Call(fnRefuse)
				PR_PARTY_REACT[szName] = nil
			end,
		}
		-- 关闭对话框
		frame.fnAutoClose = nil
		frame.fnCancelAction = nil
		frame.szCloseSound = nil
		Wnd.CloseWindow(frame)
	end
end

function D.OnApplyRequest()
	if not MY_PartyRequest.bEnable then
		return
	end
	local szName, nCamp, dwForce, nLevel, nType = arg0, arg1, arg2, arg3, arg4
	local tReact = PR_PARTY_REACT[szName]
	if tReact then
		-- 判断对方是否已在进组列表中
		local info = D.GetRequestInfo(szName)
		if not info then
			info = {
				szName      = szName,
				nCamp       = nCamp,
				dwForce     = dwForce,
				nLevel      = nLevel,
				bFriend     = LIB.IsFriend(szName),
				bTongMember = LIB.IsTongMember(szName),
				fnAccept    = tReact.fnAccept,
				fnRefuse    = tReact.fnRefuse,
			}
			insert(PR_PARTY_REQUEST, info)
		end
		-- 获取dwID
		local me = GetClientPlayer()
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
		end
		if not bAction and info.dwID then
			D.PeekPlayer(info.dwID)
		end
		-- 更新界面
		D.UpdateFrame()
	end
end

function D.UpdateFrame()
	if not D.GetFrame() then
		D.OpenPanel()
	end
	local frame = D.GetFrame()
	-- update
	if #PR_PARTY_REQUEST == 0 then
		return D.ClosePanel(true)
	end
	local dwTime, dwDelayTime = GetTime(), nil
	local container, nH, bEmpty = frame:Lookup('WndContainer_Request'), 0, true
	container:Clear()
	for _, info in ipairs(PR_PARTY_REQUEST) do
		if info.dwDelayTime and info.dwDelayTime > dwTime then
			dwDelayTime = min(dwDelayTime or HUGE, info.dwDelayTime)
		else
			local wnd = container:AppendContentFromIni(PR_INI_PATH, 'WndWindow_Item')
			local hItem = wnd:Lookup('', '')
			hItem:Lookup('Image_Hover'):SetFrame(2)

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

			wnd:Lookup('Btn_Accept', 'Text_Accept'):SetText(g_tStrings.STR_ACCEPT)
			wnd:Lookup('Btn_Refuse', 'Text_Refuse'):SetText(g_tStrings.STR_REFUSE)
			wnd:Lookup('Btn_Lookup', 'Text_Lookup'):SetText(info.dwID and g_tStrings.STR_LOOKUP or _L['Ask details'])
			wnd.info = info
			nH = nH + wnd:GetH()
			bEmpty = false
		end
	end
	if dwDelayTime then
		LIB.DelayCall('MY_PartyRequest', dwDelayTime - dwTime, D.UpdateFrame)
	end
	container:SetH(nH)
	container:FormatAllContentPos()
	frame:Lookup('', 'Image_Bg'):SetH(nH)
	frame:SetH(nH + 30)
	frame:SetDragArea(0, 0, frame:GetW(), frame:GetH())
	frame:SetVisible(not bEmpty)
end

function D.Feedback(szName, data, bDetail)
	for k, v in ipairs(PR_PARTY_REQUEST) do
		if v.szName == szName then
			v.bDetail    = bDetail
			v.dwID       = data[2]
			v.dwKungfuID = data[3]
			v.nGongZhan  = data[4]
			v.bEx        = data[5]
			break
		end
	end
	D.UpdateFrame()
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
