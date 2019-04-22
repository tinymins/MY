--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 组队助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')
local D = {}
local PR_INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_TeamTools/ui/MY_PartyRequest.ini'
local PR_EQUIP_REQUEST = {}
local PR_PARTY_REQUEST = {}

MY_PartyRequest = {
	bEnable       = true,
	bRefuseLowLv  = false,
	bRefuseRobot  = false,
	bAcceptTong   = false,
	bAcceptFriend = false,
	bAcceptAll    = false,
}
MY.RegisterCustomData('MY_PartyRequest')

function MY_PartyRequest.OnFrameCreate()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(g_tStrings.STR_ARENA_INVITE)
	MY.RegisterEsc('MY_PartyRequest', D.GetFrame, D.ClosePanel)
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
			MY.SendBgMsg(info.szName, 'RL', 'ASK')
			this:Enable(false)
			this:Lookup('', 'Text_Lookup'):SetText(_L['loading...'])
			MY.Sysmsg({_L['If it is always loading, the target may not install plugin or refuse.']})
		elseif info.dwID then
			ViewInviteToPlayer(info.dwID)
		end
	elseif this.info then
		if IsCtrlKeyDown() then
			EditBox_AppendLinkPlayer(this.info.szName)
		elseif IsAltKeyDown() and this.info.dwID then
			ViewInviteToPlayer(this.info.dwID)
		end
	end
end

function MY_PartyRequest.OnRButtonClick()
	if this.info then
		PopupMenu(MY.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
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
			OutputTip(szTip, 450, {x, y, w, h}, MY_TIP_POSTYPE.TOP_BOTTOM)
		end
	elseif this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = MY_Farbnamen and MY_Farbnamen.GetTip(this.info.szName)
		if szTip then
			OutputTip(szTip, 450, {x, y, w, h}, MY_TIP_POSTYPE.TOP_BOTTOM)
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
		PR_PARTY_REQUEST = {}
	end
	if bCompulsory then
		fnAction()
	else
		MY.Confirm(_L['Clear list and close?'], fnAction)
	end
end

function D.OnPeekPlayer()
	if PR_EQUIP_REQUEST[arg1] then
		if arg0 == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
			local me = GetClientPlayer()
			local dwType, dwID = me.GetTarget()
			MY.SetTarget(TARGET.PLAYER, arg1)
			MY.SetTarget(dwType, dwID)
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
	info.fnAction()
end

function D.RefuseRequest(info)
	for i, v in ipairs_r(PR_PARTY_REQUEST) do
		if v == info then
			remove(PR_PARTY_REQUEST, i)
		end
	end
	info.fnCancelAction()
end

function D.GetRequestStatus(info)
	local szStatus, szMsg = 'normal'
	if not info.bFriend and not info.bTongMember then
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
		if MY_PartyRequest.bRefuseLowLv and info.nLevel < MY.GetAddonInfo().dwMaxPlayerLevel then
			szStatus = 'refuse'
			szMsg = _L('Auto refuse %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
				info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)
		end
	end
	if szStatus == 'normal' then
		if info.bAcceptAll then
			szStatus = 'accept'
			szMsg = _L('Auto accept %s(%s %d%s) party request, go to MY/raid/teamtools panel if you want to turn off this feature.',
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
		MY.Sysmsg(szMsg)
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

function D.OnApplyRequest()
	if not MY_PartyRequest.bEnable then
		return
	end
	local hMsgBox = Station.Lookup('Topmost/MB_ATMP_' .. arg0) or Station.Lookup('Topmost/MB_IMTP_' .. arg0)
	if hMsgBox then
		local btn  = hMsgBox:Lookup('Wnd_All/Btn_Option1')
		local btn2 = hMsgBox:Lookup('Wnd_All/Btn_Option2')
		if btn and btn:IsEnabled() then
			-- 判断对方是否已在进组列表中
			local info = D.GetRequestInfo(arg0)
			if not info then
				info = {
					szName      = arg0,
					nCamp       = arg1,
					dwForce     = arg2,
					nLevel      = arg3,
					bFriend     = MY.IsFriend(arg0),
					bTongMember = MY.IsTongMember(arg0),
					fnAction = function()
						pcall(btn.fnAction)
					end,
					fnCancelAction = function()
						pcall(btn2.fnAction)
					end,
				}
				insert(PR_PARTY_REQUEST, info)
			end
			-- 获取dwID
			local me = GetClientPlayer()
			local tar = MY.GetObject(TARGET.PLAYER, arg0)
			if not info.dwID and tar then
				info.dwID = tar.dwID
			end
			if not info.dwID and MY_Farbnamen and MY_Farbnamen.Get then
				local data = MY_Farbnamen.Get(arg0)
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
			-- 关闭对话框 更新界面
			hMsgBox.fnAutoClose = nil
			hMsgBox.fnCancelAction = nil
			hMsgBox.szCloseSound = nil
			Wnd.CloseWindow(hMsgBox)
			D.UpdateFrame()
		end
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
	local container, nH = frame:Lookup('WndContainer_Request'), 0
	container:Clear()
	for _, info in ipairs(PR_PARTY_REQUEST) do
		if info.dwDelayTime and info.dwDelayTime > dwTime then
			dwDelayTime = min(dwDelayTime or huge, info.dwDelayTime)
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

			local nCampFrame = GetCampImageFrame(info.nCamp)
			if nCampFrame then
				hItem:Lookup('Handle_Status/Handle_Camp/Image_Camp'):SetFrame(nCampFrame)
			end
			hItem:Lookup('Handle_Status/Handle_Camp'):SetVisible(not not nCampFrame)

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
		end
	end
	if dwDelayTime then
		MY.DelayCall('MY_PartyRequest', dwDelayTime - dwTime, D.UpdateFrame)
	end
	container:SetH(nH)
	container:FormatAllContentPos()
	frame:Lookup('', 'Image_Bg'):SetH(nH)
	frame:SetH(nH + 30)
	frame:SetDragArea(0, 0, frame:GetW(), frame:GetH())
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

MY.RegisterEvent('PEEK_OTHER_PLAYER.MY_PartyRequest'   , D.OnPeekPlayer  )
MY.RegisterEvent('PARTY_INVITE_REQUEST.MY_PartyRequest', D.OnApplyRequest)
MY.RegisterEvent('PARTY_APPLY_REQUEST.MY_PartyRequest' , D.OnApplyRequest)

MY.RegisterBgMsg('RL', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf then
		if data[1] == 'Feedback' then
			D.Feedback(szName, data, true)
		end
	end
end)
