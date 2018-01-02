-- @Author: Webster
-- @Date:   2016-01-20 09:31:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2016-12-13 01:08:57

local PATH_ROOT = MY.GetAddonInfo().szRoot .. "MY_GKP/"
local _L = MY.LoadLangPack(PATH_ROOT .. "lang/")

local GKP_LOOT_ANCHOR  = { s = "CENTER", r = "CENTER", x = 0, y = 0 }
local GKP_LOOT_INIFILE = PATH_ROOT .. "ui/MY_GKP_Loot.ini"
local GKP_LOOT_BOSS -- 散件老板

local GKP_LOOT_HUANGBABA = {
	[MY.GetItemName(72592)]  = true,
	[MY.GetItemName(68363)]  = true,
	[MY.GetItemName(66190)]  = true,
	[MY.GetItemName(153897)] = true,
}
local GKP_LOOT_AUTO = {}
local GKP_LOOT_AUTO_LIST = { -- 记录分配上次的物品
	-- 材料
	[153532] = true,
	[153533] = true,
	[153534] = true,
	[153535] = true,
	-- 五行石
	[153190] = true,
	-- 五彩石
	[150241] = true,
	[150242] = true,
	[150243] = true,
	-- 90
	[72591]  = true,
	[68362]  = true,
	[66189]  = true,
	[4097]   = true,
	[73214]  = true,
	[74368]  = true,
	[153896] = true,
}
-- setmetatable(GKP_LOOT_AUTO_LIST, { __index = function() return true end })
MY_GKP_Loot_Base = class()
MY_GKP_Loot = {
	bVertical = true,
	bSetColor = true,
}
MY.RegisterCustomData("MY_GKP_Loot")
local Loot = {}

function MY_GKP_Loot_Base.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PARTY_LOOT_MODE_CHANGED")
	this:RegisterEvent("PARTY_DISBAND")
	this:RegisterEvent("PARTY_DELETE_MEMBER")
	this:RegisterEvent("DOODAD_LEAVE_SCENE")
	this:RegisterEvent("GKP_LOOT_RELOAD")
	this:RegisterEvent("GKP_LOOT_BOSS")
	this.dwDoodadID = arg0
	local a = GKP_LOOT_ANCHOR
	this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
end

function MY_GKP_Loot_Base.OnEvent(szEvent)
	if szEvent == "DOODAD_LEAVE_SCENE" then
		if arg0 == this.dwDoodadID then
			Wnd.CloseWindow(this) -- 不加动画 是系统关闭而不是手动
			PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
		end
	elseif szEvent == "PARTY_LOOT_MODE_CHANGED" then
		if arg1 ~= PARTY_LOOT_MODE.DISTRIBUTE then
			-- Wnd.CloseWindow(this)
		end
	elseif szEvent == "PARTY_DISBAND" or szEvent == "PARTY_DELETE_MEMBER" then
		if szEvent == "PARTY_DELETE_MEMBER" and arg1 ~= UI_GetClientPlayerID() then
			return
		end
		Wnd.CloseWindow(this)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	elseif szEvent == "UI_SCALED" then
		local a = this.anchor or GKP_LOOT_ANCHOR
		this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	elseif szEvent == "GKP_LOOT_RELOAD" or szEvent == "GKP_LOOT_BOSS" then
		Loot.DrawLootList(this.dwDoodadID)
	end
end

function MY_GKP_Loot_Base.OnFrameDragEnd()
	this:CorrectPos()
	local anchor    = GetFrameAnchor(this, "LEFTTOP")
	GKP_LOOT_ANCHOR = anchor
	this.anchor     = anchor
end

function MY_GKP_Loot_Base.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		Loot.CloseFrame(this:GetRoot().dwDoodadID)
	elseif szName == "Btn_Style" then
		local ui = this:GetRoot()
		local menu = {
			{ szOption = _L["Set Force Color"], bCheck = true, bChecked = MY_GKP_Loot.bSetColor, fnAction = function()
				MY_GKP_Loot.bSetColor = not MY_GKP_Loot.bSetColor
				FireUIEvent("GKP_LOOT_RELOAD")
			end },
			{ bDevide = true },
			{ szOption = _L["Link All Item"], fnAction = function()
				local szName, data, bSpecial = Loot.GetDoodad(ui.dwDoodadID)
				local t = {}
				for k, v in ipairs(data) do
					table.insert(t, MY_GKP.GetFormatLink(v.item))
				end
				MY.Talk(PLAYER_TALK_CHANNEL.RAID, t)
			end },
			{ bDevide = true },
			{ szOption = _L["switch styles"], fnAction = function()
				MY_GKP_Loot.bVertical = not MY_GKP_Loot.bVertical
				FireUIEvent("GKP_LOOT_RELOAD")
			end },
			{ bDevide = true },
			{ szOption = _L["About"], fnAction = function()
				MY.Alert(_L["GKP_TIPS"])
			end }
		}
		PopupMenu(menu)
	elseif szName == "Btn_Boss" then
		Loot.GetBossAction(this:GetRoot().dwDoodadID, type(GKP_LOOT_BOSS) == "nil")
	end
end

function MY_GKP_Loot_Base.OnRButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Boss" then
		Loot.GetBossAction(this:GetRoot().dwDoodadID, true)
	end
end

function MY_GKP_Loot_Base.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == "Handle_Item" then
		this = this:Lookup("Box_Item")
		this.OnItemLButtonDown()
	end
end

function MY_GKP_Loot_Base.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == "Handle_Item" then
		this = this:Lookup("Box_Item")
		this.OnItemLButtonUp()
	end
end

function MY_GKP_Loot_Base.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Handle_Item" or szName == "Box_Item" then
		if szName == "Handle_Item" then
			this:Lookup("Image_Copper"):Show()
			this = this:Lookup("Box_Item")
			this.OnItemMouseEnter()
		elseif szName == "Box_Item" then
			local hParent = this:GetParent()
			if hParent then
				local szParent = hParent:GetName()
				if szParent == "Handle_Item" then
					hParent:Lookup("Image_Copper"):Show()
				end
			end
		end
		-- local item = this.data.item
		-- if itme and item.nGenre == ITEM_GENRE.EQUIPMENT then
		-- 	if itme.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		-- 		this:SetOverText(3, g_tStrings.WeapenDetail[item.nDetail])
		-- 	else
		-- 		this:SetOverText(3, g_tStrings.tEquipTypeNameTable[item.nSub])
		-- 	end
		-- end
	end
end

function MY_GKP_Loot_Base.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Handle_Item" or szName == "Box_Item" then
		if szName == "Handle_Item" then
			if this:Lookup("Image_Copper") and this:Lookup("Image_Copper"):IsValid() then
				this:Lookup("Image_Copper"):Hide()
				this = this:Lookup("Box_Item")
				this.OnItemMouseLeave()
			end
		elseif szName == "Box_Item" then
			local hParent = this:GetParent()
			if hParent then
				local szParent = hParent:GetName()
				if szParent == "Handle_Item" then
					if hParent:Lookup("Image_Copper") and hParent:Lookup("Image_Copper"):IsValid() then
						hParent:Lookup("Image_Copper"):Hide()
					end
				end
			end
		end
		-- if this and this:IsValid() and this.SetOverText then
		-- 	this:SetOverText(3, "")
		-- end
	end
end

-- 分配菜单
function MY_GKP_Loot_Base.OnItemLButtonClick()
	local szName = this:GetName()
	if IsCtrlKeyDown() or IsAltKeyDown() then
		return
	end
	if szName == "Handle_Item" or szName == "Box_Item" then
		local box        = szName == "Handle_Item" and this:Lookup("Box_Item") or this
		local data       = box.data
		local me, team   = GetClientPlayer(), GetClientTeam()
		local frame      = this:GetRoot()
		local dwDoodadID = frame.dwDoodadID
		local doodad     = GetDoodad(dwDoodadID)
		-- if data.bDist or MY_GKP.bDebug then
		if not data.bDist and not data.bBidding then
			if doodad.CanDialog(me) then
				OpenDoodad(me, doodad)
			else
				MY.Topmsg(g_tStrings.TIP_TOO_FAR)
			end
		end
		if data.bDist then
			if not doodad then
				MY.Debug({"Doodad does not exist!"}, "MY_GKP_Loot:OnItemLButtonClick", MY_DEBUG.WARNING)
				return Wnd.CloseWindow(frame)
			end
			if not Loot.AuthCheck(dwDoodadID) then
				return
			end
			if IsShiftKeyDown() and GKP_LOOT_AUTO[data.item.nUiId] then
				return Loot.DistributeItem(GKP_LOOT_AUTO[data.item.nUiId], dwDoodadID, data.dwID, data, true)
			else
				return PopupMenu(Loot.GetDistributeMenu(dwDoodadID, data))
			end
		elseif data.bBidding then
			if team.nLootMode ~= PARTY_LOOT_MODE.BIDDING then
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_BID_LOOT)
			end
			MY.Sysmsg({_L["GKP does not support bidding, please re open loot list."]})
		elseif data.bNeedRoll then
			MY.Topmsg(g_tStrings.ERROR_LOOT_ROLL)
		else -- 左键摸走
			LootItem(frame.dwDoodadID, data.dwID)
		end
	end
end
-- 右键拍卖
function MY_GKP_Loot_Base.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Handle_Item" or szName == "Box_Item" then
		local box       = szName == "Handle_Item" and this:Lookup("Box_Item") or this
		local data      = box.data
		if not data.bDist then
			return
		end
		local me, team   = GetClientPlayer(), GetClientTeam()
		local frame      = this:GetRoot()
		local dwDoodadID = frame.dwDoodadID
		if not Loot.AuthCheck(dwDoodadID) then
			return
		end
		local menu = {}
		table.insert(menu, { szOption = data.szName , bDisable = true })
		table.insert(menu, { bDevide = true })
		table.insert(menu, {
			szOption = "Roll",
			fnAction = function()
				if MY_RollMonitor then
					if MY_RollMonitor.OpenPanel and MY_RollMonitor.Clear then
						MY_RollMonitor.OpenPanel()
						MY_RollMonitor.Clear({echo=false})
					end
				end
				MY.Talk(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L["Roll the dice if you wang"]) })
			end
		})
		table.insert(menu, { bDevide = true })
		for k, v in ipairs(MY_GKP.GetConfig().Scheme) do
			if v[2] then
				table.insert(menu, {
					szOption = v[1],
					fnAction = function()
						GKP_Chat.OpenFrame(data.item, Loot.GetDistributeMenu(dwDoodadID, data), {
							dwDoodadID = dwDoodadID,
							data = data,
						})
						MY.Talk(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L(" %d Gold Start Bidding, off a price if you want.", v[1])) })
					end
				})
			end
		end
		PopupMenu(menu)
	end
end

function Loot.GetBossAction(dwDoodadID, bMenu)
	if not Loot.AuthCheck(dwDoodadID) then
		return
	end
	local szName, data = Loot.GetDoodad(dwDoodadID)
	local fnAction = function()
		local tEquipment = {}
		for k, v in ipairs(data) do
			if (v.item.nGenre == ITEM_GENRE.EQUIPMENT or IsCtrlKeyDown())
				and v.item.nSub ~= EQUIPMENT_SUB.WAIST_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.BACK_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.HORSE
				and v.item.nSub ~= EQUIPMENT_SUB.PACKAGE
				and v.item.nSub ~= EQUIPMENT_SUB.FACE_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.L_SHOULDER_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.R_SHOULDER_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.BACK_CLOAK_EXTEND
				and v.bDist
			then -- 按住Ctrl的情况下 无视分类 否则只给装备
				table.insert(tEquipment, v.item)
			end
		end
		if #tEquipment == 0 then
			return MY.Alert(_L["No Equiptment left for Equiptment Boss"])
		end
		local aPartyMember = Loot.GetaPartyMember(GetDoodad(dwDoodadID))
		local p = aPartyMember(GKP_LOOT_BOSS)
		if p and p.bOnlineFlag then  -- 这个人存在团队的情况下
			local szXml = GetFormatText(_L["Are you sure you want the following item\n"], 162, 255, 255, 255)
			local r, g, b = MY.GetForceColor(p.dwForceID)
			for k, v in ipairs(tEquipment) do
				local r, g, b = GetItemFontColorByQuality(v.nQuality)
				szXml = szXml .. GetFormatText("[".. GetItemNameByItem(v) .."]\n", 166, r, g, b)
			end
			szXml = szXml .. GetFormatText(_L["All distrubute to"], 162, 255, 255, 255)
			szXml = szXml .. GetFormatText("[".. p.szName .."]", 162, r, g, b)
			local msg = {
				szMessage = szXml,
				szName = "GKP_Distribute",
				szAlignment = "CENTER",
				bRichText = true,
				{
					szOption = g_tStrings.STR_HOTKEY_SURE,
					fnAction = function()
						for k, v in ipairs(tEquipment) do
							Loot.DistributeItem(GKP_LOOT_BOSS, dwDoodadID, v.dwID, {}, true)
						end
					end
				},
				{
					szOption = g_tStrings.STR_HOTKEY_CANCEL
				},
			}
			MessageBox(msg)
		else
			return MY.Alert(_L["No Pick up Object, may due to Network off - line"])
		end
	end
	if bMenu then
		local menu = MY_GKP.GetTeamMemberMenu(function(v)
			GKP_LOOT_BOSS = v.dwID
			fnAction()
		end, false, true)
		table.insert(menu, 1, { bDevide = true })
		table.insert(menu, 1, { szOption = _L["select equip boss"], bDisable = true })
		PopupMenu(menu)
	else
		fnAction()
	end
end

function Loot.AuthCheck(dwID)
	local me, team       = GetClientPlayer(), GetClientTeam()
	local doodad         = GetDoodad(dwID)
	if not doodad then
		return MY.Debug({"Doodad does not exist!"}, "MY_GKP_Loot:AuthCheck", MY_DEBUG.WARNING)
	end
	local nLootMode      = team.nLootMode
	local dwBelongTeamID = doodad.GetBelongTeamID()
	if nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not MY_GKP.bDebug then -- 需要分配者模式
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
		return false
	end
	if not MY.IsDistributer() and not MY_GKP.bDebug then -- 需要自己是分配者
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	if dwBelongTeamID ~= team.dwTeamID then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	return true
end
-- 拾取对象
function Loot.GetaPartyMember(doodad)
	local team = GetClientTeam()
	local aPartyMember = doodad.GetLooterList()
	if not aPartyMember then
		return MY.Sysmsg({_L["Pick up time limit exceeded, please try again."]})
	end
	for k, v in ipairs(aPartyMember) do
		local player = team.GetMemberInfo(v.dwID)
		aPartyMember[k].dwForceID = player.dwForceID
		aPartyMember[k].dwMapID   = player.dwMapID
	end
	setmetatable(aPartyMember, { __call = function(me, dwID)
		for k, v in ipairs(me) do
			if v.dwID == dwID or v.szName == dwID then
				return v
			end
		end
	end })
	return aPartyMember
end
-- 严格判断
function Loot.DistributeItem(dwID, dwDoodadID, dwItemID, info, bShift)
	local doodad = GetDoodad(dwDoodadID)
	if not Loot.AuthCheck(dwDoodadID) then
		return
	end
	local me = GetClientPlayer()
	local item = GetItem(dwItemID)
	if not item then
		MY.Debug({"Item does not exist, check!!"}, "MY_GKP_Loot", MY_DEBUG.WARNING)
		local szName, data = Loot.GetDoodad(dwDoodadID)
		for k, v in ipairs(data) do
			if v.item.nQuality == info.nQuality and GetItemNameByItem(v.item) == info.szName then
				dwItemID = v.item.dwID
				MY.Debug({"Item matching, " .. GetItemNameByItem(v.item)}, "MY_GKP_Loot", MY_DEBUG.LOG)
				break
			end
		end
	end
	local item         = GetItem(dwItemID)
	local team         = GetClientTeam()
	local player       = team.GetMemberInfo(dwID)
	local aPartyMember = Loot.GetaPartyMember(doodad)
	if item then
		if not player or (player and not player.bIsOnLine) then -- 不在线
			return MY.Alert(_L["No Pick up Object, may due to Network off - line"])
		end
		if not aPartyMember(dwID) then -- 给不了
			return MY.Alert(_L["No Pick up Object, may due to Network off - line"])
		end
		if player.dwMapID ~= me.GetMapID() then -- 不在同一地图
			return MY.Alert(_L["No Pick up Object, Please confirm that in the Dungeon."])
		end
		local tab = {
			szPlayer   = player.szName,
			nUiId      = item.nUiId,
			szNpcName  = doodad.szName,
			dwDoodadID = doodad.dwID,
			dwTabType  = item.dwTabType,
			dwIndex    = item.dwIndex,
			nVersion   = item.nVersion,
			nTime      = GetCurrentTime(),
			nQuality   = item.nQuality,
			dwForceID  = player.dwForceID,
			szName     = GetItemNameByItem(item),
			nGenre     = item.nGenre,
		}
		if item.bCanStack and item.nStackNum > 1 then
			tab.nStackNum = item.nStackNum
		end
		if item.nGenre == ITEM_GENRE.BOOK then
			tab.nBookID = item.nBookID
		end
		if MY_GKP.bOn then
			MY_GKP.Record(tab, item, IsShiftKeyDown() or bShift)
		else -- 关闭的情况所有东西全部绕过
			tab.nMoney = 0
			MY_GKP("GKP_Record", tab)
		end
		if GKP_LOOT_AUTO_LIST[item.nUiId] then
			GKP_LOOT_AUTO[item.nUiId] = dwID
		end
		doodad.DistributeItem(dwItemID, dwID)
	else
		MY.Sysmsg({_L["Userdata is overdue, distribut failed, please try again."]})
	end
end

function Loot.GetMessageBox(dwID, dwDoodadID, dwItemID, data, bShift)
	local team = GetClientTeam()
	local info = team.GetMemberInfo(dwID)
	local fr, fg, fb = MY.GetForceColor(info.dwForceID)
	local ir, ig, ib = GetItemFontColorByQuality(data.nQuality)
	local msg = {
		szMessage = FormatLinkString(
			g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
			"font=162",
			GetFormatText("[".. data.szName .. "]", 166, ir, ig, ib),
			GetFormatText("[".. info.szName .. "]", 162, fr, fg, fb)
		),
		szName = "GKP_Distribute",
		bRichText = true,
		{
			szOption = g_tStrings.STR_HOTKEY_SURE,
			fnAction = function()
				Loot.DistributeItem(dwID, dwDoodadID, dwItemID, data, bShift)
			end
		},
		{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
	}
	MessageBox(msg)
end

function Loot.GetDistributeMenu(dwDoodadID, data)
	local me, team     = GetClientPlayer(), GetClientTeam()
	local dwMapID      = me.GetMapID()
	local doodad       = GetDoodad(dwDoodadID)
	local aPartyMember = Loot.GetaPartyMember(doodad)
	table.sort(aPartyMember, function(a, b)
		return a.dwForceID < b.dwForceID
	end)
	local menu = {
		{ szOption = data.szName, bDisable = true },
		{ bDevide = true }
	}
	local fnGetMenu = function(v, szName)
		local szIcon, nFrame = GetForceImage(v.dwForceID)
		return {
			szOption = v.szName .. (szName and " - " .. szName or ""),
			bDisable = not v.bOnlineFlag,
			rgb = { MY.GetForceColor(v.dwForceID) },
			szIcon = szIcon, nFrame = nFrame,
			fnAutoClose = function()
				return not frame or false
			end,
			szLayer = "ICON_RIGHTMOST",
			fnAction = function()
				if data.nQuality >= 3 then
					Loot.GetMessageBox(v.dwID, dwDoodadID, data.dwID, data, szName and true)
				else
					Loot.DistributeItem(v.dwID, dwDoodadID, data.dwID, data, szName and true)
				end
			end
		}
	end
	if GKP_LOOT_AUTO[data.item.nUiId] then
		local member = aPartyMember(GKP_LOOT_AUTO[data.item.nUiId])
		if member then
			table.insert(menu, fnGetMenu(member, data.szName))
			table.insert(menu, { bDevide = true })
		end
	end
	for k, v in ipairs(aPartyMember) do
		table.insert(menu, fnGetMenu(v))
	end
	return menu
end

function Loot.DrawLootList(dwID)
	local frame = Loot.GetFrame(dwID)
	local szName, data, bSpecial = Loot.GetDoodad(dwID)
	local nCount = #data
	MY.Debug({(string.format("Doodad %d, items %d.", dwID, nCount))}, "MY_GKP_Loot", MY_DEBUG.LOG)
	if not frame or not szName or nCount == 0 then
		if frame then
			return Wnd.CloseWindow(frame)
		end
		return MY.Debug({"Doodad does not exist!"}, "MY_GKP_Loot:DrawLootList", MY_DEBUG.WARNING)
	end
	-- 修改UI大小
	local handle = frame:Lookup("", "Handle_Box")
	handle:Clear()
	if MY_GKP_Loot.bVertical then
		frame:Lookup("", "Image_Bg"):SetSize(280, nCount * 56 + 35)
		frame:Lookup("", "Image_Title"):SetSize(280, 30)
		frame:Lookup("Btn_Close"):SetRelPos(250, 4)
		frame:Lookup("Btn_Boss"):SetRelPos(210, 3)
		frame:SetSize(280, nCount * 56 + 35)
		handle:SetHandleStyle(3)
	else
		if nCount <= 6 then
			frame:Lookup("", "Image_Bg"):SetSize(6 * 72, 110)
			frame:Lookup("", "Image_Title"):SetSize(6 * 72, 30)
			frame:SetSize(6 * 72, 110)
		else
			frame:Lookup("", "Image_Bg"):SetSize(6 * 72, 30 + math.ceil(nCount / 6) * 75)
			frame:Lookup("", "Image_Title"):SetSize(6 * 72, 30)
			frame:SetSize(6 * 72, 8 + 30 + math.ceil(nCount / 6) * 75)
		end
		local w, h = frame:GetSize()
		frame:Lookup("Btn_Close"):SetRelPos(w - 30, 4)
		frame:Lookup("Btn_Boss"):SetRelPos(w - 70, 3)
		handle:SetHandleStyle(0)
	end
	if bSpecial then
		frame:Lookup("", "Image_Bg"):FromUITex("ui/Image/OperationActivity/RedEnvelope2.uitex", 14)
		frame:Lookup("", "Image_Title"):FromUITex("ui/Image/OperationActivity/RedEnvelope2.uitex", 14)
		frame:Lookup("", "Text_Title"):SetAlpha(255)
		frame:Lookup("", "SFX"):Show()
		handle:SetRelPos(5, 30)
		handle:GetParent():FormatAllItemPos()
	end
	for k, v in ipairs(data) do
		local item = v.item
		local szName = GetItemNameByItem(item)
		local box
		if MY_GKP_Loot.bVertical then
			local h = handle:AppendItemFromIni(GKP_LOOT_INIFILE, "Handle_Item")
			box = h:Lookup("Box_Item")
			local txt = h:Lookup("Text_Item")
			txt:SetText(szName)
			txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
			if MY_GKP_Loot.bSetColor and item.nGenre == ITEM_GENRE.MATERIAL then
				for k, v in pairs(g_tStrings.tForceTitle) do
					if szName:find(v) then
						txt:SetFontColor(MY.GetForceColor(k))
						break
					end
				end
			end
		else
			handle:AppendItemFromString("<Box>name=\"Box_Item\" w=64 h=64 </Box>")
			box = handle:Lookup(k - 1)
			-- append box
			local x, y = (k - 1) % 6, math.ceil(k / 6) - 1
			box:SetRelPos(x * 70 + 5, y * 70 + 5)
		end
		UpdateBoxObject(box, UI_OBJECT_ITEM_ONLY_ID, item.dwID)
		-- box:SetOverText(3, "")
		-- box:SetOverTextFontScheme(3, 15)
		-- box:SetOverTextPosition(3, ITEM_POSITION.LEFT_TOP)
		box.data = {
			dwID      = item.dwID,
			nQuality  = item.nQuality,
			szName    = szName,
			bNeedRoll = v.bNeedRoll,
			bDist     = v.bDist,
			bBidding  = v.bBidding,
			item      = v.item,
		}
		if GKP_LOOT_AUTO[item.nUiId] then
			box:SetObjectStaring(true)
		end
	end
	handle:FormatAllItemPos()
	-- frame:Lookup("", "Text_Title"):SetText(g_tStrings.STR_LOOT_SHOW_LIST .. " - " .. szName)
	frame:Lookup("", "Text_Title"):SetText(szName)
end

function Loot.GetFrame(dwID)
	return Station.Lookup("Normal/MY_GKP_Loot_" .. dwID)
end

function Loot.OpenFrame(dwID)
	local frame = Wnd.OpenWindow(GKP_LOOT_INIFILE, "MY_GKP_Loot_" .. dwID)
	Loot.DrawLootList(dwID)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

-- 手动关闭 不适用自定关闭
function Loot.CloseFrame(dwID)
	local frame = Loot.GetFrame(dwID)
	if frame then
		Wnd.CloseWindow(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

-- 检查物品
function Loot.GetDoodad(dwID)
	local me   = GetClientPlayer()
	local d    = GetDoodad(dwID)
	local data = {}
	local szName
	local bSpecial = false
	if me and d then
		szName = d.szName
		local nLootItemCount = d.GetItemListCount()
		for i = 0, nLootItemCount - 1 do
			local item, bNeedRoll, bDist, bBidding = d.GetLootItem(i, me)
			if item and item.nQuality > 0 then
				local szItemName = GetItemNameByItem(item)
				if GKP_LOOT_HUANGBABA[szItemName] then
					bSpecial = true
				end
				-- bSpecial = true -- debug
				table.insert(data, { item = item, bNeedRoll = bNeedRoll, bDist = bDist, bBidding = bBidding })
			end
		end
	end
	return szName, data, bSpecial
end

-- 摸箱子
MY.RegisterEvent("OPEN_DOODAD", function()
	if arg1 == UI_GetClientPlayerID() then
		local team = GetClientTeam()
		if not team or team
			and team.nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE
			-- and not (MY_GKP.bDebug2 and MY_GKP.bDebug)
		then
			return
		end
		local doodad = GetDoodad(arg0)
		local nM = doodad.GetLootMoney() or 0
		if nM > 0 then
			LootMoney(arg0)
			PlaySound(SOUND.UI_SOUND, g_sound.PickupMoney)
		end
		local szName, data = Loot.GetDoodad(arg0)
		local frame = Loot.GetFrame(arg0)
		if #data == 0 then
			if frame then
				Wnd.CloseWindow(frame)
			end
			return
		elseif not frame then
			Loot.OpenFrame(arg0)
		else
			Loot.DrawLootList(arg0)
		end
		MY.Debug({"Open Doodad: " .. arg0}, "MY_GKP_Loot", MY_DEBUG.LOG)
		local hLoot = Station.Lookup("Normal/LootList")
		if hLoot then
			hLoot:SetAbsPos(4096, 4096)
		end
		-- Wnd.CloseWindow("LootList")
	end
end)

-- 刷新箱子
MY.RegisterEvent("SYNC_LOOT_LIST", function()
	local frame = Loot.GetFrame(arg0)
	if (MY_GKP.bDebug2 and MY_GKP.bDebug) or frame then
		if not frame then
			local szName, data = Loot.GetDoodad(arg0)
			if #data > 0 then
				Loot.OpenFrame(arg0)
			end
		end
		if Loot.GetFrame(arg0) then
			if frame then
				Loot.DrawLootList(arg0)
			end
		end
	end
end)
Loot_OpenFrame = Loot.OpenFrame

MY.RegisterEvent("GKP_LOOT_BOSS", function()
	if not arg0 then
		GKP_LOOT_BOSS = nil
		GKP_LOOT_AUTO = {}
	else
		local team = GetClientTeam()
		if team then
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = GetClientTeam().GetMemberInfo(v)
				if info.szName == arg0 then
					GKP_LOOT_BOSS = v
					break
				end
			end
		end
	end
end)

local ui = {
	GetMessageBox   = Loot.GetMessageBox,
	GetaPartyMember = Loot.GetaPartyMember
}
setmetatable(MY_GKP_Loot, { __index = ui, __newindex = function() end, __metatable = true })
