--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 组队助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
-----------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')
local PR = {}
local PR_MAX_LEVEL = 95
local PR_INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_TeamTools/ui/MY_PartyRequest.ini'
local PR_EQUIP_REQUEST = {}
local PR_PARTY_REQUEST = {}

MY_PartyRequest = {
	bEnable     = true,
	bAutoCancel = false,
	bRefuseRobot = false,
}
MY.RegisterCustomData('MY_PartyRequest')

function MY_PartyRequest.OnFrameCreate()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(g_tStrings.STR_ARENA_INVITE)
	MY.RegisterEsc('MY_PartyRequest', PR.GetFrame, PR.ClosePanel)
end

function MY_PartyRequest.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		local menu = {}
		table.insert(menu, {
			szOption = _L['Auto refuse low level player'],
			bCheck = true, bChecked = MY_PartyRequest.bAutoCancel,
			fnAction = function()
				MY_PartyRequest.bAutoCancel = not MY_PartyRequest.bAutoCancel
			end,
		})
		table.insert(menu, {
			szOption = _L['Auto refuse robot player'],
			bCheck = true, bChecked = MY_PartyRequest.bRefuseRobot,
			fnAction = function()
				MY_PartyRequest.bRefuseRobot = not MY_PartyRequest.bRefuseRobot
			end,
			fnMouseEnter = function()
				local szXml = GetFormatText(_L['Full level and equip score less than 2/3 of yours'], nil, 255, 255, 0)
				OutputTip(szXml, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
		})
		PopupMenu(menu)
	elseif name == 'Btn_Close' then
		PR.ClosePanel()
	elseif name == 'Btn_Accept' then
		PR.AcceptRequest(this:GetParent().info)
		PR.UpdateFrame()
	elseif name == 'Btn_Refuse' then
		PR.RefuseRequest(this:GetParent().info)
		PR.UpdateFrame()
	elseif name == 'Btn_Lookup' then
		local info = this:GetParent().info
		if not info.dwID or (not info.bDetail and IsCtrlKeyDown()) then
			MY.BgTalk(info.szName, 'RL', 'ASK')
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

function PR.GetFrame()
	return Station.Lookup('Normal2/MY_PartyRequest')
end

function PR.OpenPanel()
	if PR.GetFrame() then
		return
	end
	Wnd.OpenWindow(PR_INI_PATH, 'MY_PartyRequest')
end

function PR.ClosePanel(bCompulsory)
	local fnAction = function()
		Wnd.CloseWindow(PR.GetFrame())
		PR_PARTY_REQUEST = {}
	end
	if bCompulsory then
		fnAction()
	else
		MY.Confirm(_L['Clear list and close?'], fnAction)
	end
end

function PR.OnPeekPlayer()
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
				PR.Feedback(p.szName, data, false)
			end
			local info = PR.GetRequestInfo(arg1)
			if info and PR.CheckAutoRefuse(info) then
				PR.UpdateFrame()
			end
		end
		PR_EQUIP_REQUEST[arg1] = nil
	end
end

function PR.PeekPlayer(dwID)
	PR_EQUIP_REQUEST[dwID] = true
	ViewInviteToPlayer(dwID, true)
end

function PR.AcceptRequest(info)
	for i, v in ipairs_r(PR_PARTY_REQUEST) do
		if v == info then
			remove(PR_PARTY_REQUEST, i)
		end
	end
	info.fnAction()
end

function PR.RefuseRequest(info)
	for i, v in ipairs_r(PR_PARTY_REQUEST) do
		if v == info then
			remove(PR_PARTY_REQUEST, i)
		end
	end
	info.fnCancelAction()
end

function PR.CheckAutoRefuse(info)
	if not info.bFriend then
		if MY_PartyRequest.bRefuseRobot and info.dwID then
			local me = GetClientPlayer()
			local tar = GetPlayer(info.dwID)
			if tar and tar.GetTotalEquipScore() > 0 and tar.GetTotalEquipScore() < me.GetTotalEquipScore() * 2 / 3 then
				PR.RefuseRequest(info)
				MY.Sysmsg({_L('Auto refuse %s(%s %d%s) party request, equip score: %d', info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL, tar.GetTotalEquipScore())})
				return true
			end
		end
		if MY_PartyRequest.bAutoCancel and info.nLevel < PR_MAX_LEVEL then
			PR.RefuseRequest(info)
			MY.Sysmsg({_L('Auto refuse %s(%s %d%s) party request', info.szName, g_tStrings.tForceTitle[info.dwForce], info.nLevel, g_tStrings.STR_LEVEL)})
			return true
		end
	end
	return false
end

function PR.GetRequestInfo(key)
	for k, v in ipairs(PR_PARTY_REQUEST) do
		if v.szName == key or v.dwID == key then
			return v
		end
	end
end

function PR.OnApplyRequest()
	if not MY_PartyRequest.bEnable then
		return
	end
	local hMsgBox = Station.Lookup('Topmost/MB_ATMP_' .. arg0) or Station.Lookup('Topmost/MB_IMTP_' .. arg0)
	if hMsgBox then
		local btn  = hMsgBox:Lookup('Wnd_All/Btn_Option1')
		local btn2 = hMsgBox:Lookup('Wnd_All/Btn_Option2')
		if btn and btn:IsEnabled() then
			-- 判断对方是否已在进组列表中
			local info = PR.GetRequestInfo(arg0)
			if not info then
				info = {
					szName  = arg0,
					nCamp   = arg1,
					dwForce = arg2,
					nLevel  = arg3,
					bFriend = MY.IsFriend(arg0),
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
			if info.dwID and not PR.CheckAutoRefuse(info) then
				PR.PeekPlayer(info.dwID)
			end
			-- 关闭对话框 更新界面
			hMsgBox.fnAutoClose = nil
			hMsgBox.fnCancelAction = nil
			hMsgBox.szCloseSound = nil
			Wnd.CloseWindow(hMsgBox)
			PR.UpdateFrame()
		end
	end
end

function PR.UpdateFrame()
	if not PR.GetFrame() then
		PR.OpenPanel()
	end
	local frame = PR.GetFrame()
	-- update
	if #PR_PARTY_REQUEST == 0 then
		return PR.ClosePanel(true)
	end
	local container, nH = frame:Lookup('WndContainer_Request'), 0
	container:Clear()
	for k, v in ipairs(PR_PARTY_REQUEST) do
		local wnd = container:AppendContentFromIni(PR_INI_PATH, 'WndWindow_Item', k)
		local hItem = wnd:Lookup('', '')
		hItem:Lookup('Image_Hover'):SetFrame(2)

		if v.dwKungfuID then
			hItem:Lookup('Image_Icon'):FromIconID(Table_GetSkillIconID(v.dwKungfuID, 1))
		else
			hItem:Lookup('Image_Icon'):FromUITex(GetForceImage(v.dwForce))
		end
		hItem:Lookup('Handle_Status/Handle_Gongzhan'):SetVisible(v.nGongZhan == 1)

		local nCampFrame = GetCampImageFrame(v.nCamp)
		if nCampFrame then
			hItem:Lookup('Handle_Status/Handle_Camp/Image_Camp'):SetFrame(nCampFrame)
		end
		hItem:Lookup('Handle_Status/Handle_Camp'):SetVisible(not not nCampFrame)

		if v.bDetail and v.bEx == 'Author' then
			hItem:Lookup('Text_Name'):SetFontColor(255, 255, 0)
		end
		hItem:Lookup('Text_Name'):SetText(v.szName)
		hItem:Lookup('Text_Level'):SetText(v.nLevel)

		wnd:Lookup('Btn_Accept', 'Text_Accept'):SetText(g_tStrings.STR_ACCEPT)
		wnd:Lookup('Btn_Refuse', 'Text_Refuse'):SetText(g_tStrings.STR_REFUSE)
		wnd:Lookup('Btn_Lookup', 'Text_Lookup'):SetText(v.dwID and g_tStrings.STR_LOOKUP or _L['Ask details'])
		wnd.info = v
		nH = nH + wnd:GetH()
	end
	container:SetH(nH)
	container:FormatAllContentPos()
	frame:Lookup('', 'Image_Bg'):SetH(nH)
	frame:SetH(nH + 30)
	frame:SetDragArea(0, 0, frame:GetW(), frame:GetH())
end

function PR.Feedback(szName, data, bDetail)
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
	PR.UpdateFrame()
end

MY.RegisterEvent('PEEK_OTHER_PLAYER.MY_PartyRequest'   , PR.OnPeekPlayer  )
MY.RegisterEvent('PARTY_INVITE_REQUEST.MY_PartyRequest', PR.OnApplyRequest)
MY.RegisterEvent('PARTY_APPLY_REQUEST.MY_PartyRequest' , PR.OnApplyRequest)

MY.RegisterBgMsg('RL', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf then
		if data[1] == 'Feedback' then
			PR.Feedback(szName, data, true)
		end
	end
end)
