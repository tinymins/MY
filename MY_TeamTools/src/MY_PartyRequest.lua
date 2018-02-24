-- @Author: Webster
-- @Date:   2016-01-04 12:57:33
-- @Last Modified by:   Administrator
-- @Last Modified time: 2016-12-29 11:13:26
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

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_TeamTools/lang/")
local PR = {}
local PR_MAX_LEVEL = 95
local PR_INI_PATH = MY.GetAddonInfo().szRoot .. "MY_TeamTools/ui/MY_PartyRequest.ini"
local PR_EQUIP_REQUEST = {}
local PR_MT = { __call = function(me, szName)
	for k, v in ipairs(me) do
		if v.szName == szName then
			return true
		end
	end
end }
local PR_PARTY_REQUEST  = setmetatable({}, PR_MT)

MY_PartyRequest = {
	bEnable     = true,
	bAutoCancel = false,
}
MY.RegisterCustomData("MY_PartyRequest")

function MY_PartyRequest.OnFrameCreate()
	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	this:Lookup("", "Text_Title"):SetText(g_tStrings.STR_ARENA_INVITE)
	MY.RegisterEsc("MY_PartyRequest", PR.GetFrame, PR.ClosePanel)
end

function MY_PartyRequest.OnLButtonClick()
	local name = this:GetName()
	if name == "Btn_Setting" then
		local menu = {}
		table.insert(menu, {
			szOption = _L["Auto Refuse No full level Player"],
			bCheck = true, bChecked = MY_PartyRequest.bAutoCancel,
			fnAction = function()
				MY_PartyRequest.bAutoCancel = not MY_PartyRequest.bAutoCancel
			end,
		})
		PopupMenu(menu)
	elseif name == "Btn_Close" then
		PR.ClosePanel()
	elseif name == "Btn_Accept" then
		local info = this:GetParent().info
		info.fnAction()
		for i, v in ipairs_r(PR_PARTY_REQUEST) do
			if v == info then
				remove(PR_PARTY_REQUEST, i)
			end
		end
		PR.UpdateFrame()
	elseif name == "Btn_Refuse" then
		local info = this:GetParent().info
		info.fnCancelAction()
		for i, v in ipairs_r(PR_PARTY_REQUEST) do
			if v == info then
				remove(PR_PARTY_REQUEST, i)
			end
		end
		PR.UpdateFrame()
	elseif name == "Btn_Lookup" then
		local info = this:GetParent().info
		if info.bDetail or (info.dwID and IsAltKeyDown()) then
			ViewInviteToPlayer(info.dwID)
		else
			MY.BgTalk(info.szName, "RL", "ASK")
			this:Enable(false)
			this:Lookup("", "Text_Lookup"):SetText(_L["loading..."])
			MY.Sysmsg({_L["If it is always loading, the target may not install plugin or refuse."]})
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
		local menu = {}
		InsertPlayerCommonMenu(menu, 0, this.info.szName)
		menu[4] = nil
		if this.info.dwID then
			table.insert(menu, {
				szOption = g_tStrings.STR_LOOKUP,
				fnAction = function()
					ViewInviteToPlayer(this.info.dwID)
				end,
			})
		end
		PopupMenu(menu)
	end
end

function MY_PartyRequest.OnMouseEnter()
	local name = this:GetName()
	if name == "Btn_Lookup" then
		local info = this:GetParent().info
		if not info.bDetail and info.dwID then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szTip = GetFormatText(_L["Press alt and click to view equipment."])
			OutputTip(szTip, 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
		end
	elseif this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = MY_Farbnamen.GetTip(this.info.szName)
		if szTip then
			OutputTip(szTip, 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
		end
	end
end

function MY_PartyRequest.OnMouseLeave()
	if this.info then
		HideTip()
	end
end

function PR.GetFrame()
	return Station.Lookup("Normal2/MY_PartyRequest")
end

function PR.OpenPanel()
	if PR.GetFrame() then
		return
	end
	Wnd.OpenWindow(PR_INI_PATH, "MY_PartyRequest")
end

function PR.ClosePanel(bCompulsory)
	local fnAction = function()
		Wnd.CloseWindow(PR.GetFrame())
		PR_PARTY_REQUEST  = setmetatable({}, PR_MT)
	end
	if bCompulsory then
		fnAction()
	else
		MY.Confirm(_L["Clear list and close?"], fnAction)
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
		end
		PR_EQUIP_REQUEST[arg1] = nil
	end
end

function PR.OnApplyRequest()
	if not MY_PartyRequest.bEnable then
		return
	end
	local hMsgBox = Station.Lookup("Topmost/MB_ATMP_" .. arg0) or Station.Lookup("Topmost/MB_IMTP_" .. arg0)
	if hMsgBox then
		local btn  = hMsgBox:Lookup("Wnd_All/Btn_Option1")
		local btn2 = hMsgBox:Lookup("Wnd_All/Btn_Option2")
		if btn and btn:IsEnabled() then
			if not PR_PARTY_REQUEST(arg0) then
				local tab = {
					szName  = arg0,
					nCamp   = arg1,
					dwForce = arg2,
					nLevel  = arg3,
					fnAction = function()
						pcall(btn.fnAction)
					end,
					fnCancelAction = function()
						pcall(btn2.fnAction)
					end
				}
				if not MY_PartyRequest.bAutoCancel or MY_PartyRequest.bAutoCancel and arg3 == PR_MAX_LEVEL then
					table.insert(PR_PARTY_REQUEST, tab)
				else
					MY.Sysmsg({_L("Auto Refuse %s(%s %d%s) Party request", arg0, g_tStrings.tForceTitle[arg2], arg3, g_tStrings.STR_LEVEL)})
					pcall(btn2.fnAction)
				end
			end
			local data
			local fnGetEqueip = function(dwID)
				PR_EQUIP_REQUEST[dwID] = true
				ViewInviteToPlayer(dwID, true)
			end
			if MY_Farbnamen and MY_Farbnamen.Get then
				data = MY_Farbnamen.Get(arg0)
				if data then
					fnGetEqueip(data.dwID)
				end
			end
			if not data then
				for k, v in pairs(MY.GetNearPlayer()) do
					if v.szName == arg0 then
						fnGetEqueip(v.dwID)
						break
					end
				end
			end
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
	local container, nH = frame:Lookup("WndContainer_Request"), 0
	container:Clear()
	for k, v in ipairs(PR_PARTY_REQUEST) do
		local wnd = container:AppendContentFromIni(PR_INI_PATH, "WndWindow_Item", k)
		local hItem = wnd:Lookup("", "")
		hItem:Lookup("Image_Hover"):SetFrame(2)

		if v.dwKungfuID then
			hItem:Lookup("Image_Icon"):FromIconID(Table_GetSkillIconID(v.dwKungfuID, 1))
		else
			hItem:Lookup("Image_Icon"):FromUITex(GetForceImage(v.dwForce))
		end
		hItem:Lookup("Handle_Status/Handle_Gongzhan"):SetVisible(v.nGongZhan == 1)

		local nCampFrame = GetCampImageFrame(v.nCamp)
		if nCampFrame then
			hItem:Lookup("Handle_Status/Handle_Camp/Image_Camp"):SetFrame(nCampFrame)
		end
		hItem:Lookup("Handle_Status/Handle_Camp"):SetVisible(not not nCampFrame)

		if v.bDetail and v.bEx == "Author" then
			hItem:Lookup("Text_Name"):SetFontColor(255, 255, 0)
		end
		hItem:Lookup("Text_Name"):SetText(v.szName)
		hItem:Lookup("Text_Level"):SetText(v.nLevel)

		wnd:Lookup("Btn_Accept", "Text_Accept"):SetText(g_tStrings.STR_ACCEPT)
		wnd:Lookup("Btn_Refuse", "Text_Refuse"):SetText(g_tStrings.STR_REFUSE)
		wnd:Lookup("Btn_Lookup", "Text_Lookup"):SetText(v.bDetail and g_tStrings.STR_LOOKUP or _L["Details"])
		wnd.info = v
		nH = nH + wnd:GetH()
	end
	container:SetH(nH)
	container:FormatAllContentPos()
	frame:Lookup("", "Image_Bg"):SetH(nH)
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

MY.RegisterEvent("PEEK_OTHER_PLAYER.MY_PartyRequest"   , PR.OnPeekPlayer  )
MY.RegisterEvent("PARTY_INVITE_REQUEST.MY_PartyRequest", PR.OnApplyRequest)
MY.RegisterEvent("PARTY_APPLY_REQUEST.MY_PartyRequest" , PR.OnApplyRequest)

MY.RegisterBgMsg("RL", function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf then
		if data[1] == "Feedback" then
			PR.Feedback(szName, data, true)
		end
	end
end)
