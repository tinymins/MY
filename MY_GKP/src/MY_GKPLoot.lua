--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录 拾取界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local PATH_ROOT = LIB.GetAddonInfo().szRoot .. 'MY_GKP/'
local _L = LIB.LoadLangPack(PATH_ROOT .. 'lang/')

local DEBUG_LOOT = true -- 测试拾取分配 强制进入分配模式并最终不调用分配接口
local GKP_LOOT_ANCHOR  = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
local GKP_LOOT_INIFILE = PATH_ROOT .. 'ui/MY_GKP_Loot.ini'
local MY_GKP_LOOT_BOSS -- 散件老板

local GKP_LOOT_HUANGBABA = { -- 玄晶
	[LIB.GetItemName(72592)]  = true,
	[LIB.GetItemName(68363)]  = true,
	[LIB.GetItemName(66190)]  = true,
	[LIB.GetItemName(153897)] = true,
	[LIB.GetItemName(160306)] = true,
}
local GKP_LOOT_ZIBABA = { -- 小铁
	[LIB.GetItemName(66189)]  = true,
	[LIB.GetItemName(68362)]  = true,
	[LIB.GetItemName(153896)] = true,
	[LIB.GetItemName(160305)] = true,
}
local GKP_LOOT_RECENT = {} -- 记录上次物品或物品组分配给了谁
local GKP_ITEM_QUALITIES = {
	{ nQuality = -1, szTitle = g_tStrings.STR_ADDON_BLOCK },
	{ nQuality = 1, szTitle = g_tStrings.STR_WHITE },
	{ nQuality = 2, szTitle = g_tStrings.STR_ROLLQUALITY_GREEN },
	{ nQuality = 3, szTitle = g_tStrings.STR_ROLLQUALITY_BLUE },
	{ nQuality = 4, szTitle = g_tStrings.STR_ROLLQUALITY_PURPLE },
	{ nQuality = 5, szTitle = g_tStrings.STR_ROLLQUALITY_NACARAT },
}

local Loot = {}
MY_GKP_Loot = {
	bVertical = true,
	bSetColor = true,
	nConfirmQuality = 3,
}
LIB.RegisterCustomData('MY_GKP_Loot')

MY_GKP_Loot.tConfirm = {
	Huangbaba  = true,
	Book       = true,
	Pendant    = true,
	Outlook    = true,
	Pet        = true,
	Horse      = true,
	HorseEquip = true,
}
LIB.RegisterCustomData('MY_GKP_Loot.tConfirm')

MY_GKP_Loot.tItemConfig = {
	nQualityFilter = -1,
	bFilterBookRead = false,
	nAutoPickupQuality = -1,
}
LIB.RegisterCustomData('MY_GKP_Loot.tItemConfig')

do
local function onLoadingEnd()
	MY_GKP_Loot.tItemConfig.nQualityFilter = -1
	-- MY_GKP_Loot.tItemConfig.nAutoPickupQuality = -1
end
LIB.RegisterEvent('LOADING_END.MY_GKP_Loot', onLoadingEnd)
end

function MY_GKP_Loot.CanDialog(tar, doodad)
	return doodad.CanDialog(tar)
end

function MY_GKP_Loot.IsItemDisplay(itemData, config)
	if config.nQualityFilter ~= -1 and itemData.nQuality < config.nQualityFilter then
		return false
	end
	if config.bFilterBookRead and itemData.nGenre == ITEM_GENRE.BOOK then
		local me = GetClientPlayer()
		local nBookID, nSegmentID = GlobelRecipeID2BookID(itemData.nBookID)
		if me and me.IsBookMemorized(nBookID, nSegmentID) then
			return false
		end
	end
	return true
end

function MY_GKP_Loot.IsItemAutoPickup(itemData, config, doodad, bCanDialog)
	return bCanDialog and config.nAutoPickupQuality ~= -1 and itemData.nQuality >= config.nAutoPickupQuality
end

function MY_GKP_Loot.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('PARTY_LOOT_MODE_CHANGED')
	this:RegisterEvent('PARTY_DISBAND')
	this:RegisterEvent('PARTY_DELETE_MEMBER')
	this:RegisterEvent('DOODAD_LEAVE_SCENE')
	this:RegisterEvent('MY_GKP_LOOT_RELOAD')
	this:RegisterEvent('MY_GKP_LOOT_BOSS')
	local a = GKP_LOOT_ANCHOR
	this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	this:Lookup('WndContainer_DoodadList'):Clear()
	Loot.AdjustFrame(this)
end

function MY_GKP_Loot.OnFrameBreathe()
	local me = GetClientPlayer()
	local wnd = this:Lookup('WndContainer_DoodadList'):LookupContent(0)
	while wnd do
		local doodad = GetDoodad(wnd.dwDoodadID)
		-- 拾取判定
		local bCanDialog = MY_GKP_Loot.CanDialog(me, doodad)
		if not LIB.IsShieldedVersion() then
			local hList, hItem = wnd:Lookup('', 'Handle_ItemList')
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if MY_GKP_Loot.IsItemAutoPickup(hItem.itemData, wnd.tItemConfig, doodad, bCanDialog)
				and not hItem.itemData.bDist and not hItem.itemData.bBidding then
					LIB.ExecuteWithThis(hItem, MY_GKP_Loot.OnItemLButtonClick)
				end
			end
		end
		wnd:Lookup('', 'Image_DoodadTitleBg'):SetFrame(bCanDialog and 0 or 3)
		-- 目标距离
		local nDistance = 0
		if me and doodad then
			nDistance = floor(sqrt(pow(me.nX - doodad.nX, 2) + pow(me.nY - doodad.nY, 2)) * 10 / 64) / 10
		end
		wnd:Lookup('', 'Handle_Compass/Compass_Distance'):SetText(nDistance < 4 and '' or nDistance .. '"')
		-- 自身面向
		if me then
			wnd:Lookup('', 'Handle_Compass/Image_Player'):Show()
			wnd:Lookup('', 'Handle_Compass/Image_Player'):SetRotate( - me.nFaceDirection / 128 * pi)
		end
		-- 物品位置
		local nRotate, nRadius = 0, 10.125
		if me and doodad and nDistance > 0 then
			-- 特判角度
			if me.nX == doodad.nX then
				if me.nY > doodad.nY then
					nRotate = pi / 2
				else
					nRotate = - pi / 2
				end
			else
				nRotate = atan((me.nY - doodad.nY) / (me.nX - doodad.nX))
			end
			if nRotate < 0 then
				nRotate = nRotate + pi
			end
			if doodad.nY < me.nY then
				nRotate = pi + nRotate
			end
		end
		local nX = nRadius + nRadius * cos(nRotate) + 2
		local nY = nRadius - 3 - nRadius * sin(nRotate)
		wnd:Lookup('', 'Handle_Compass/Image_PointGreen'):SetRelPos(nX, nY)
		wnd:Lookup('', 'Handle_Compass'):FormatAllItemPos()
		wnd = wnd:GetNext()
	end
end

function MY_GKP_Loot.OnEvent(szEvent)
	if szEvent == 'DOODAD_LEAVE_SCENE' then
		Loot.RemoveLootList(arg0)
	elseif szEvent == 'PARTY_LOOT_MODE_CHANGED' then
		if arg1 ~= PARTY_LOOT_MODE.DISTRIBUTE then
			-- Wnd.CloseWindow(this)
		end
	elseif szEvent == 'PARTY_DISBAND' or szEvent == 'PARTY_DELETE_MEMBER' then
		if szEvent == 'PARTY_DELETE_MEMBER' and arg1 ~= UI_GetClientPlayerID() then
			return
		end
		Loot.CloseFrame()
	elseif szEvent == 'UI_SCALED' then
		local a = this.anchor or GKP_LOOT_ANCHOR
		this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	elseif szEvent == 'MY_GKP_LOOT_RELOAD' or szEvent == 'MY_GKP_LOOT_BOSS' then
		local wnd = this:Lookup('WndContainer_DoodadList'):LookupContent(0)
		local aDoodadID = {}
		while wnd do
			table.insert(aDoodadID, wnd.dwDoodadID)
			wnd = wnd:GetNext()
		end
		for _, dwDoodadID in ipairs(aDoodadID) do
			Loot.DrawLootList(dwDoodadID)
		end
	end
end

function MY_GKP_Loot.OnFrameDragEnd()
	this:CorrectPos()
	local anchor    = GetFrameAnchor(this, 'LEFTTOP')
	GKP_LOOT_ANCHOR = anchor
	this.anchor     = anchor
end

function MY_GKP_Loot.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Mini' then
		Loot.AdjustWnd(this:GetParent())
		Loot.AdjustFrame(this:GetRoot())
	end
end

function MY_GKP_Loot.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Mini' then
		Loot.AdjustWnd(this:GetParent())
		Loot.AdjustFrame(this:GetRoot())
	end
end

function MY_GKP_Loot.OnMouseEnter()
	local name = this:GetName()
	if name == 'Btn_Boss' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = ''
		local dwDoodadID = this:GetParent().dwDoodadID
		local aPartyMember = Loot.GetaPartyMember(dwDoodadID)
		local p = MY_GKP_LOOT_BOSS and aPartyMember(MY_GKP_LOOT_BOSS)
		if p then
			local r, g, b = LIB.GetForceColor(p.dwForceID)
			szXml = szXml .. GetFormatText(_L['LClick to distrubute all equipment to '], 136)
			szXml = szXml .. GetFormatText('['.. p.szName ..']', 162, r, g, b)
			szXml = szXml .. GetFormatText(_L['.'] .. '\n' .. _L['Ctrl + LClick to distrubute all lootable items to '], 136)
			szXml = szXml .. GetFormatText('['.. p.szName ..']', 162, r, g, b)
			szXml = szXml .. GetFormatText(_L['.'] .. '\n' .. _L['RClick to reselect Equipment Boss.'], 136)
		elseif MY_GKP_LOOT_BOSS then
			szXml = szXml .. GetFormatText(_L['LClick to distrubute all equipment to Equipment Boss.'] .. '\n', 136)
			szXml = szXml .. GetFormatText(_L['Ctrl + LClick to distrubute all lootable items to Equipment Boss.'] .. '\n', 136)
			szXml = szXml .. GetFormatText(_L['RClick to reselect Equipment Boss.'], 136)
		else
			szXml = szXml .. GetFormatText(_L['Click to select Equipment Boss.'], 136)
		end
		OutputTip(szXml, 450, {x, y, w, h}, ALW.TOP_BOTTOM)
	end
end

function MY_GKP_Loot.OnMouseLeave()
	local name = this:GetName()
	if name == 'Btn_Boss' then
		HideTip()
	end
end

function MY_GKP_Loot.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Close' then
		Loot.RemoveLootList(this:GetParent().dwDoodadID)
	elseif szName == 'Btn_Style' then
		local wnd = this:GetParent()
		local dwDoodadID = wnd.dwDoodadID
		local menu = {
			{
				szOption = _L['Set Force Color'],
				bCheck = true, bChecked = MY_GKP_Loot.bSetColor,
				fnAction = function()
					MY_GKP_Loot.bSetColor = not MY_GKP_Loot.bSetColor
					FireUIEvent('MY_GKP_LOOT_RELOAD')
				end,
			},
			{ bDevide = true },
			{
				szOption = _L['Link All Item'],
				fnAction = function()
					local szName, aItemData, bSpecial = Loot.GetDoodad(dwDoodadID)
					local t = {}
					for k, v in ipairs(aItemData) do
						table.insert(t, MY_GKP.GetFormatLink(v.item))
					end
					LIB.Talk(PLAYER_TALK_CHANNEL.RAID, t)
				end,
			},
			{ bDevide = true },
			{
				szOption = _L['switch styles'],
				fnAction = function()
					MY_GKP_Loot.bVertical = not MY_GKP_Loot.bVertical
					FireUIEvent('MY_GKP_LOOT_RELOAD')
				end,
			},
			{ bDevide = true },
			{
				szOption = _L['About'],
				fnAction = function()
					LIB.Alert(_L['GKP_TIPS'])
				end,
			},
		}
		if IsCtrlKeyDown() then
			insert(menu, 1, { szOption = dwDoodadID, bDisable = true })
		end
		if not LIB.IsShieldedVersion() then
			table.insert(menu, MENU_DIVIDER)
			table.insert(menu, Loot.GetFilterMenu())
			table.insert(menu, Loot.GetAutoPickupAllMenu())

			local t = { szOption = _L['Auto pickup this'] }
			for i, p in ipairs(GKP_ITEM_QUALITIES) do
				table.insert(t, {
					szOption = p.nQuality > 0 and _L('Quality reach %s', p.szTitle) or p.szTitle,
					rgb = p.nQuality == -1 and {255, 255, 255} or { GetItemFontColorByQuality(p.nQuality) },
					bCheck = true, bMCheck = true, bChecked = wnd.tItemConfig.nAutoPickupQuality == p.nQuality,
					fnAction = function()
						wnd.tItemConfig.nAutoPickupQuality = p.nQuality
					end,
				})
			end
			table.insert(menu, t)
		end
		PopupMenu(menu)
	elseif szName == 'Btn_Boss' then
		Loot.GetBossAction(this:GetParent().dwDoodadID, type(MY_GKP_LOOT_BOSS) == 'nil')
	end
end

function MY_GKP_Loot.OnRButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Boss' then
		Loot.GetBossAction(this:GetParent().dwDoodadID, true)
	end
end

function MY_GKP_Loot.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == 'Handle_Item' then
		this = this:Lookup('Box_Item')
		this.OnItemLButtonDown()
	end
end

function MY_GKP_Loot.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == 'Handle_Item' then
		this = this:Lookup('Box_Item')
		this.OnItemLButtonUp()
	end
end

function MY_GKP_Loot.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == 'Handle_Item' or szName == 'Box_Item' then
		local hItem = szName == 'Handle_Item' and this or this:GetParent()
		local box   = hItem:Lookup('Box_Item')
		if IsAltKeyDown() and not IsCtrlKeyDown() and not IsShiftKeyDown() then
			LIB.OutputTip(this, var2str(hItem.itemData, '  ') .. '\n' .. var2str({
				nUiId = hItem.itemData.item.nUiId,
				dwID = hItem.itemData.item.dwID,
				nGenre = hItem.itemData.item.nGenre,
				nSub = hItem.itemData.item.nSub,
				nDetail = hItem.itemData.item.nDetail,
				nLevel = hItem.itemData.item.nLevel,
				nPrice = hItem.itemData.item.nPrice,
				dwScriptID = hItem.itemData.item.dwScriptID,
				nMaxDurability = hItem.itemData.item.nMaxDurability,
				nMaxExistAmount = hItem.itemData.item.nMaxExistAmount,
				nMaxExistTime = hItem.itemData.item.nMaxExistTime,
				bCanTrade = hItem.itemData.item.bCanTrade,
				bCanDestory = hItem.itemData.item.bCanDestory,
				szName = hItem.itemData.item.szName,
			}, '  '))
		elseif szName == 'Handle_Item' then
			LIB.ExecuteWithThis(box, box.OnItemMouseEnter)
		end
		-- local item = hItem.itemData.item
		-- if itme and item.nGenre == ITEM_GENRE.EQUIPMENT then
		-- 	if itme.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		-- 		this:SetOverText(3, g_tStrings.WeapenDetail[item.nDetail])
		-- 	else
		-- 		this:SetOverText(3, g_tStrings.tEquipTypeNameTable[item.nSub])
		-- 	end
		-- end
	elseif szName == 'Image_GroupDistrib' then
		local hItem = this:GetParent()
		local hList = hItem:GetParent()
		for i = 0, hList:GetItemCount() - 1 do
			local h = hList:Lookup(i)
			h:Lookup('Shadow_Highlight'):SetVisible(h.itemData.szType == hItem.itemData.szType)
		end
		LIB.OutputTip(hItem, GetFormatText(_L['Onekey distrib this group'], 136), true)
	end
end

function MY_GKP_Loot.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'Handle_Item' or szName == 'Box_Item' then
		if szName == 'Handle_Item' then
			local box = this:Lookup('Box_Item')
			if box and box.OnItemMouseLeave then
				LIB.ExecuteWithThis(box, box.OnItemMouseLeave)
			end
		end
		-- if this and this:IsValid() and this.SetOverText then
		-- 	this:SetOverText(3, '')
		-- end
	elseif szName == 'Image_GroupDistrib' then
		local hItem = this:GetParent()
		local hList = hItem:GetParent()
		for i = 0, hList:GetItemCount() - 1 do
			hList:Lookup(i):Lookup('Shadow_Highlight'):Hide()
		end
		HideTip()
	end
end

-- 分配菜单
function MY_GKP_Loot.OnItemLButtonClick()
	local szName = this:GetName()
	if IsCtrlKeyDown() or IsAltKeyDown() then
		return
	end
	if szName == 'Handle_Item' or szName == 'Box_Item' then
		local hItem      = szName == 'Handle_Item' and this or this:GetParent()
		local box        = hItem:Lookup('Box_Item')
		local data       = hItem.itemData
		local me, team   = GetClientPlayer(), GetClientTeam()
		local dwDoodadID = data.dwDoodadID
		local doodad     = GetDoodad(dwDoodadID)
		-- if data.bDist or MY_GKP.bDebug then
		if not data.bDist and not data.bBidding then
			if doodad.CanDialog(me) then
				OpenDoodad(me, doodad)
			else
				LIB.Topmsg(g_tStrings.TIP_TOO_FAR)
			end
		end
		if data.bDist then
			if not doodad then
				LIB.Debug({'Doodad does not exist!'}, 'MY_GKP_Loot:OnItemLButtonClick', DEBUG_LEVEL.WARNING)
				return Loot.RemoveLootList(dwDoodadID)
			end
			if not Loot.AuthCheck(dwDoodadID) then
				return
			end
			return PopupMenu(Loot.GetDistributeMenu(data, data.item.nUiId))
		elseif data.bBidding then
			if team.nLootMode ~= PARTY_LOOT_MODE.BIDDING then
				return OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.GOLD_CHANGE_BID_LOOT)
			end
			LIB.Sysmsg({_L['GKP does not support bidding, please re open loot list.']})
		elseif data.bNeedRoll then
			LIB.Topmsg(g_tStrings.ERROR_LOOT_ROLL)
		else -- 左键摸走
			LootItem(dwDoodadID, data.dwID)
		end
	elseif szName == 'Image_GroupDistrib' then
		local hItem     = this:GetParent()
		local hList     = hItem:GetParent()
		local aItemData = {}
		for i = 0, hList:GetItemCount() - 1 do
			local h = hList:Lookup(i)
			if h.itemData.szType == hItem.itemData.szType then
				insert(aItemData, h.itemData)
			end
		end
		for _, data in ipairs(aItemData) do
			local dwDoodadID = data.dwDoodadID
			local doodad     = GetDoodad(dwDoodadID)
			if not doodad then
				LIB.Debug({'Doodad does not exist!'}, 'MY_GKP_Loot:OnItemLButtonClick', DEBUG_LEVEL.WARNING)
				return Loot.RemoveLootList(dwDoodadID)
			end
			if not Loot.AuthCheck(dwDoodadID) then
				return
			end
		end
		return PopupMenu(Loot.GetDistributeMenu(aItemData, hItem.itemData.szType))
	end
end
-- 右键拍卖
function MY_GKP_Loot.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_Item' or szName == 'Box_Item' then
		local hItem = szName == 'Handle_Item' and this or this:GetParent()
		local box   = hItem:Lookup('Box_Item')
		local data = hItem.itemData
		if not data.bDist then
			return
		end
		local me, team   = GetClientPlayer(), GetClientTeam()
		local dwDoodadID = data.dwDoodadID
		if not Loot.AuthCheck(dwDoodadID) then
			return
		end
		local menu = {}
		table.insert(menu, { szOption = data.szName , bDisable = true })
		table.insert(menu, { bDevide = true })
		table.insert(menu, {
			szOption = 'Roll',
			fnAction = function()
				if MY_RollMonitor then
					if MY_RollMonitor.OpenPanel and MY_RollMonitor.Clear then
						MY_RollMonitor.OpenPanel()
						MY_RollMonitor.Clear({echo=false})
					end
				end
				LIB.Talk(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L['Roll the dice if you wang']) })
			end
		})
		table.insert(menu, { bDevide = true })
		for k, v in ipairs(MY_GKP.GetConfig().Scheme) do
			if v[2] then
				table.insert(menu, {
					szOption = v[1],
					fnAction = function()
						MY_GKP_Chat.OpenFrame(data.item, Loot.GetDistributeMenu(data, data.nUiId), {
							dwDoodadID = dwDoodadID,
							data = data,
						})
						LIB.Talk(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L(' %d Gold Start Bidding, off a price if you want.', v[1])) })
					end
				})
			end
		end
		PopupMenu(menu)
	end
end

function Loot.GetFilterMenu()
	local t = {
		szOption = _L['Loot item filter'],
		{
			szOption = _L['Filter book read'],
			bCheck = true,
			bChecked = MY_GKP_Loot.tItemConfig.bFilterBookRead,
			fnAction = function()
				MY_GKP_Loot.tItemConfig.bFilterBookRead = not MY_GKP_Loot.tItemConfig.bFilterBookRead
			end,
		},
	}
	local t1 = {
		szOption = _L['Quality filter'],
		{
			szOption = _L['Will be reset when loading'],
			bDisable = true,
		},
		MENU_DIVIDER,
	}
	for i, p in ipairs(GKP_ITEM_QUALITIES) do
		table.insert(t1, {
			szOption = p.nQuality > 0 and _L('Quality below %s', p.szTitle) or p.szTitle,
			rgb = p.nQuality == -1 and {255, 255, 255} or { GetItemFontColorByQuality(p.nQuality) },
			bCheck = true, bMCheck = true, bChecked = MY_GKP_Loot.tItemConfig.nQualityFilter == p.nQuality,
			fnAction = function()
				MY_GKP_Loot.tItemConfig.nQualityFilter = p.nQuality
			end,
		})
	end
	insert(t, t1)
	return t
end

function Loot.GetAutoPickupAllMenu()
	local t = { szOption = _L['Auto pickup all'] }
	for i, p in ipairs(GKP_ITEM_QUALITIES) do
		table.insert(t, {
			szOption = p.nQuality > 0 and _L('Quality reach %s', p.szTitle) or p.szTitle,
			rgb = p.nQuality == -1 and {255, 255, 255} or { GetItemFontColorByQuality(p.nQuality) },
			bCheck = true, bMCheck = true, bChecked = MY_GKP_Loot.tItemConfig.nAutoPickupQuality == p.nQuality,
			fnAction = function()
				MY_GKP_Loot.tItemConfig.nAutoPickupQuality = p.nQuality
			end,
		})
	end
	return t
end

function Loot.GetBossAction(dwDoodadID, bMenu)
	if not Loot.AuthCheck(dwDoodadID) then
		return
	end
	local szName, aItemData = Loot.GetDoodad(dwDoodadID)
	local fnAction = function()
		local aEquipmentItemData = {}
		for k, v in ipairs(aItemData) do
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
				table.insert(aEquipmentItemData, v)
			end
		end
		if #aEquipmentItemData == 0 then
			return LIB.Alert(_L['No Equiptment left for Equiptment Boss'])
		end
		local aPartyMember = Loot.GetaPartyMember(dwDoodadID)
		local p = aPartyMember(MY_GKP_LOOT_BOSS)
		if p and p.bOnlineFlag then  -- 这个人存在团队的情况下
			local szXml = GetFormatText(_L['Are you sure you want the following item\n'], 162, 255, 255, 255)
			local r, g, b = LIB.GetForceColor(p.dwForceID)
			for k, v in ipairs(aEquipmentItemData) do
				local r, g, b = GetItemFontColorByQuality(v.item.nQuality)
				szXml = szXml .. GetFormatText('['.. GetItemNameByItem(v.item) ..']\n', 166, r, g, b)
			end
			szXml = szXml .. GetFormatText(_L['All distrubute to'], 162, 255, 255, 255)
			szXml = szXml .. GetFormatText('['.. p.szName ..']', 162, r, g, b)
			local msg = {
				szMessage = szXml,
				szName = 'GKP_Distribute',
				szAlignment = 'CENTER',
				bRichText = true,
				{
					szOption = g_tStrings.STR_HOTKEY_SURE,
					fnAction = function()
						Loot.DistributeItem(MY_GKP_LOOT_BOSS, aEquipmentItemData)
					end
				},
				{
					szOption = g_tStrings.STR_HOTKEY_CANCEL
				},
			}
			MessageBox(msg)
		else
			return LIB.Alert(_L['Cannot distrubute items to Equipment Boss, may due to Equipment Boss is too far away or got dropline when looting.'])
		end
	end
	if bMenu then
		local menu = MY_GKP.GetTeamMemberMenu(function(v)
			MY_GKP_LOOT_BOSS = v.dwID
			fnAction()
		end, false, true)
		table.insert(menu, 1, { bDevide = true })
		table.insert(menu, 1, { szOption = _L['select equip boss'], bDisable = true })
		PopupMenu(menu)
	else
		fnAction()
	end
end

function Loot.AuthCheck(dwID)
	local me, team       = GetClientPlayer(), GetClientTeam()
	local doodad         = GetDoodad(dwID)
	if not doodad then
		return LIB.Debug({'Doodad does not exist!'}, 'MY_GKP_Loot:AuthCheck', DEBUG_LEVEL.WARNING)
	end
	local nLootMode      = team.nLootMode
	local dwBelongTeamID = doodad.GetBelongTeamID()
	if nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not MY_GKP.bDebug then -- 需要分配者模式
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
		return false
	end
	if not LIB.IsDistributer() and not MY_GKP.bDebug then -- 需要自己是分配者
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	if dwBelongTeamID ~= team.dwTeamID then
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	return true
end
-- 拾取对象
function Loot.GetaPartyMember(aDoodadID)
	if not IsTable(aDoodadID) then
		aDoodadID = {aDoodadID}
	end
	local team = GetClientTeam()
	local tDoodadID = {}
	local tPartyMember = {}
	local aPartyMember = {}
	for _, dwDoodadID in ipairs(aDoodadID) do
		if not tDoodadID[dwDoodadID] then
			local doodad = GetDoodad(dwDoodadID)
			if doodad then
				local aLooterList = doodad.GetLooterList()
				if not aLooterList then
					LIB.Sysmsg({_L['Pick up time limit exceeded, please try again.']})
				end
				for _, p in ipairs(aLooterList) do
					if not tPartyMember[p.dwID] then
						insert(aPartyMember, p)
						tPartyMember[p.dwID] = true
					end
				end
			end
			tDoodadID[dwDoodadID] = true
		end
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
function Loot.DistributeItem(dwID, info, szAutoDistType)
	if IsArray(info) then
		for _, p in ipairs(info) do
			Loot.DistributeItem(dwID, p, szAutoDistType)
		end
		return
	end
	local doodad = GetDoodad(info.dwDoodadID)
	if not Loot.AuthCheck(info.dwDoodadID) then
		return
	end
	local me = GetClientPlayer()
	local item = GetItem(info.dwID)
	if not item then
		LIB.Debug({'Item does not exist, check!!'}, 'MY_GKP_Loot', DEBUG_LEVEL.WARNING)
		local szName, aItemData = Loot.GetDoodad(info.dwDoodadID)
		for k, v in ipairs(aItemData) do
			if v.nQuality == info.nQuality and GetItemNameByItem(v.item) == info.szName then
				info.dwID = v.item.dwID
				LIB.Debug({'Item matching, ' .. GetItemNameByItem(v.item)}, 'MY_GKP_Loot', DEBUG_LEVEL.LOG)
				break
			end
		end
	end
	local item         = GetItem(info.dwID)
	local team         = GetClientTeam()
	local player       = team.GetMemberInfo(dwID)
	local aPartyMember = Loot.GetaPartyMember(info.dwDoodadID)
	if item then
		if not player or (player and not player.bIsOnLine) then -- 不在线
			return LIB.Alert(_L['No Pick up Object, may due to Network off - line'])
		end
		if not aPartyMember(dwID) then -- 给不了
			return LIB.Alert(_L['No Pick up Object, may due to Network off - line'])
		end
		if player.dwMapID ~= me.GetMapID() then -- 不在同一地图
			return LIB.Alert(_L['No Pick up Object, Please confirm that in the Dungeon.'])
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
			MY_GKP.Record(tab, item)
		else -- 关闭的情况所有东西全部绕过
			tab.nMoney = 0
			MY_GKP('GKP_Record', tab)
		end
		if szAutoDistType then
			GKP_LOOT_RECENT[szAutoDistType] = dwID
		end
		if DEBUG_LOOT then
			return LIB.Sysmsg('LOOT: ' .. info.dwID .. '->' .. dwID) -- !!! Debug
		end
		doodad.DistributeItem(info.dwID, dwID)
	else
		LIB.Sysmsg({_L['Userdata is overdue, distribut failed, please try again.']})
	end
end

function Loot.GetMessageBox(dwID, aItemData, szAutoDistType)
	if not IsArray(aItemData) then
		aItemData = {aItemData}
	end
	local team = GetClientTeam()
	local info = team.GetMemberInfo(dwID)
	local fr, fg, fb = LIB.GetForceColor(info.dwForceID)
	local aItemName = {}
	for _, data in ipairs(aItemData) do
		local ir, ig, ib = GetItemFontColorByQuality(data.nQuality)
		insert(aItemName, GetFormatText('['.. data.szName .. ']', 166, ir, ig, ib))
	end
	local msg = {
		szMessage = FormatLinkString(
			g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
			'font=162',
			concat(aItemName, GetFormatText(g_tStrings.STR_PAUSE)),
			GetFormatText('['.. info.szName .. ']', 162, fr, fg, fb)
		),
		szName = 'GKP_Distribute',
		bRichText = true,
		{
			szOption = g_tStrings.STR_HOTKEY_SURE,
			fnAction = function()
				Loot.DistributeItem(dwID, aItemData, szAutoDistType)
			end
		},
		{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
	}
	MessageBox(msg)
end

do
local function IsItemRequireConfirm(data)
	if data.nQuality >= MY_GKP_Loot.nConfirmQuality
	or (MY_GKP_Loot.tConfirm.Huangbaba and GKP_LOOT_HUANGBABA[GetItemNameByItem(data.item)]) -- 玄晶
	or (MY_GKP_Loot.tConfirm.Book and data.item.nGenre == ITEM_GENRE.BOOK) -- 书籍
	or (MY_GKP_Loot.tConfirm.Pendant and data.item.nGenre == ITEM_GENRE.EQUIPMENT and ( -- 挂件
		data.item.nSub == WAIST_EXTEND
		or data.item.nSub == BACK_EXTEND
		or data.item.nSub == FACE_EXTEND
	))
	or (MY_GKP_Loot.tConfirm.Outlook and data.item.nGenre == ITEM_GENRE.EQUIPMENT and ( -- 肩饰披风
		data.item.nSub == EQUIPMENT_SUB.BACK_CLOAK_EXTEND
		or data.item.nSub == EQUIPMENT_SUB.L_SHOULDER_EXTEND
		or data.item.nSub == EQUIPMENT_SUB.R_SHOULDER_EXTEND
	))
	or (MY_GKP_Loot.tConfirm.Pet and ( -- 跟宠
		data.item.nGenre == ITEM_GENRE.CUB
		or (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == EQUIPMENT_SUB.PET)
	))
	or (MY_GKP_Loot.tConfirm.Horse and ( -- 坐骑
		data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == EQUIPMENT_SUB.HORSE
	))
	or (MY_GKP_Loot.tConfirm.HorseEquip and ( -- 马具
		data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == EQUIPMENT_SUB.HORSE_EQUIP
	))
	then
		return true
	end
	return false
end
local function GetMemberMenu(member, aItemData, szAutoDistType)
	local frame = Loot.GetFrame()
	local wnd = Loot.GetDoodadWnd(frame, dwDoodadID)
	local szIcon, nFrame = GetForceImage(member.dwForceID)
	local szOption = member.szName
	return {
		szOption = szOption,
		bDisable = not member.bOnlineFlag,
		rgb = { LIB.GetForceColor(member.dwForceID) },
		szIcon = szIcon, nFrame = nFrame,
		fnAutoClose = function()
			return not wnd or not wnd:IsValid()
		end,
		szLayer = 'ICON_RIGHTMOST',
		fnAction = function()
			local bConfirm = false
			for _, data in ipairs(aItemData) do
				if IsItemRequireConfirm(data) then
					bConfirm = true
					break
				end
			end
			if bConfirm then
				Loot.GetMessageBox(member.dwID, aItemData, szAutoDistType)
			else
				Loot.DistributeItem(member.dwID, aItemData, szAutoDistType)
			end
		end
	}
end
function Loot.GetDistributeMenu(aItemData, szAutoDistType)
	if not IsArray(aItemData) then
		aItemData = {aItemData}
	end
	local aDoodadID = {}
	for _, p in ipairs(aItemData) do
		insert(aDoodadID, p.dwDoodadID)
	end
	local me, team     = GetClientPlayer(), GetClientTeam()
	local dwMapID      = me.GetMapID()
	local aPartyMember = Loot.GetaPartyMember(aDoodadID)
	table.sort(aPartyMember, function(a, b)
		return a.dwForceID < b.dwForceID
	end)
	local aItemName = {}
	for _, p in ipairs(aItemData) do
		insert(aItemName, p.szName)
	end
	local menu = {
		{ szOption = concat(aItemName, g_tStrings.STR_PAUSE), bDisable = true },
		{ bDevide = true }
	}
	local dwAutoDistID
	if szAutoDistType then
		dwAutoDistID = GKP_LOOT_RECENT[szAutoDistType]
		if dwAutoDistID then
			local member = aPartyMember(dwAutoDistID)
			if member then
				table.insert(menu, GetMemberMenu(member, aItemData, szAutoDistType))
				table.insert(menu, { bDevide = true })
			end
		end
	end
	for _, member in ipairs(aPartyMember) do
		table.insert(menu, GetMemberMenu(member, aItemData, szAutoDistType))
	end
	return menu
end
end

function Loot.AdjustFrame(frame)
	local container = frame:Lookup('WndContainer_DoodadList')
	local nW, nH = frame:GetW(), 0
	local wnd = container:LookupContent(0)
	while wnd do
		nW = wnd:GetW()
		nH = nH + wnd:GetH()
		wnd = wnd:GetNext()
	end
	container:FormatAllContentPos()
	container:SetSize(nW, nH)
	frame:SetSize(nW, nH)
end

function Loot.AdjustWnd(wnd)
	local nInnerW = MY_GKP_Loot.bVertical and 270 or (52 * 8)
	local nOuterW = MY_GKP_Loot.bVertical and nInnerW or (nInnerW + 10)
	local hDoodad = wnd:Lookup('', '')
	local hList = hDoodad:Lookup('Handle_ItemList')
	local bMini = wnd:Lookup('CheckBox_Mini'):IsCheckBoxChecked()
	hList:SetW(nInnerW)
	hList:SetRelX((nOuterW - nInnerW) / 2)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	hList:SetVisible(not bMini)
	hDoodad:SetSize(nOuterW, (bMini and 0 or hList:GetH()) + 30)
	hDoodad:Lookup('Handle_Compass'):SetRelX(nOuterW - 107)
	hDoodad:Lookup('Image_DoodadTitleBg'):SetW(nOuterW)
	hDoodad:Lookup('Image_DoodadBg'):SetSize(nOuterW, hDoodad:GetH() - 20)
	hDoodad:FormatAllItemPos()
	wnd:SetSize(nOuterW, hDoodad:GetH())
	wnd:Lookup('Btn_Boss'):SetRelX(nOuterW - 80)
	wnd:Lookup('CheckBox_Mini'):SetRelX(nOuterW - 50)
	wnd:Lookup('Btn_Close'):SetRelX(nOuterW - 28)
end

function Loot.GetDoodadWnd(frame, dwID, bCreate)
	if not frame then
		return
	end
	local container = frame:Lookup('WndContainer_DoodadList')
	local wnd = container:LookupContent(0)
	while wnd and wnd.dwDoodadID ~= dwID do
		wnd = wnd:GetNext()
	end
	if not wnd and bCreate then
		wnd = container:AppendContentFromIni(GKP_LOOT_INIFILE, 'Wnd_Doodad')
		wnd.dwDoodadID = dwID
		wnd.tItemConfig = setmetatable({}, { __index = MY_GKP_Loot.tItemConfig })
	end
	return wnd
end

local function IsItemDataSuitable(data)
	local me = GetClientPlayer()
	if not me then
		return false, false
	end
	if data.szType == 'BOOK' then
		local nBookID, nSegmentID = GlobelRecipeID2BookID(data.item.nBookID)
		if me.IsBookMemorized(nBookID, nSegmentID) then
			return false, false
		else
			return true, false
		end
	else
		local bSuit = LIB.DoesEquipmentSuit(data.item, true)
		if bSuit then
			if data.szType == 'EQUIPMENT' or data.szType == 'WEAPON' then
				bSuit = LIB.IsItemFitKungfu(data.item)
			elseif data.szType == 'EQUIPMENT_SIGN' then
				bSuit = wfind(data.item.szName, g_tStrings.tForceTitle[me.dwForceID])
			end
		end
		if bSuit then
			return true, LIB.IsBetterEquipment(data.item)
		end
		return false, false
	end
end

function Loot.DrawLootList(dwID)
	local frame = Loot.GetFrame()
	local wnd = Loot.GetDoodadWnd(frame, dwID)
	local config = wnd and wnd.tItemConfig or MY_GKP_Loot.tItemConfig

	-- 计算掉落
	local szName, aItemData, bSpecial = Loot.GetDoodad(dwID)
	local nCount = #aItemData
	if config.nQualityFilter ~= -1 or config.bFilterBookRead then
		nCount = 0
		for i, v in ipairs(aItemData) do
			if MY_GKP_Loot.IsItemDisplay(v, config) then
				nCount = nCount + 1
			end
		end
	end
	LIB.Debug({(string.format('Doodad %d, items %d.', dwID, nCount))}, 'MY_GKP_Loot', DEBUG_LEVEL.LOG)

	if not szName or nCount == 0 then
		if frame then
			Loot.RemoveLootList(dwID)
		end
		return LIB.Debug({'Doodad does not exist!'}, 'MY_GKP_Loot:DrawLootList', DEBUG_LEVEL.LOG)
	end

	-- 获取/创建UI元素
	if not frame then
		frame = Loot.OpenFrame()
	end
	if not wnd then
		wnd = Loot.GetDoodadWnd(frame, dwID, true)
	end
	config = wnd.tItemConfig

	-- 修改UI元素
	local hDoodad = wnd:Lookup('', '')
	local hList = hDoodad:Lookup('Handle_ItemList')
	hList:Clear()
	for i, itemData in ipairs(aItemData) do
		local item = itemData.item
		if MY_GKP_Loot.IsItemDisplay(itemData, config) then
			local szName = GetItemNameByItem(item)
			local h = hList:AppendItemFromIni(GKP_LOOT_INIFILE, 'Handle_Item')
			local box = h:Lookup('Box_Item')
			local txt = h:Lookup('Text_Item')
			txt:SetText(szName)
			txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
			if MY_GKP_Loot.bSetColor and item.nGenre == ITEM_GENRE.MATERIAL then
				for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
					if szName:find(szForceTitle) then
						txt:SetFontColor(LIB.GetForceColor(dwForceID))
						break
					end
				end
			end
			if MY_GKP_Loot.bVertical then
				local bSuit, bBetter = IsItemDataSuitable(itemData)
			h:Lookup('Image_GroupDistrib'):SetVisible(itemData.bDist
					and (i == 1 or aItemData[i - 1].szType ~= itemData.szType or not aItemData[i - 1].bDist))
				h:Lookup('Image_Suitable'):SetVisible(bSuit and not bBetter)
				h:Lookup('Image_Better'):SetVisible(bBetter)
				h:Lookup('Image_Spliter'):SetVisible(i ~= #aItemData)
			else
				txt:Hide()
				box:SetSize(48, 48)
				box:SetRelPos(2, 2)
				h:SetSize(52, 52)
				h:FormatAllItemPos()
				h:Lookup('Image_GroupDistrib'):Hide()
				h:Lookup('Image_Spliter'):Hide()
				h:Lookup('Image_Hover'):SetSize(0, 0)
			end
			UpdateBoxObject(box, UI_OBJECT_ITEM_ONLY_ID, item.dwID)
			-- box:SetOverText(3, '')
			-- box:SetOverTextFontScheme(3, 15)
			-- box:SetOverTextPosition(3, ITEM_POSITION.LEFT_TOP)
			if GKP_LOOT_RECENT[item.nUiId] then
				box:SetObjectStaring(true)
			end
			h.itemData = itemData
		end
	end
	if bSpecial then
		hDoodad:Lookup('Image_DoodadBg'):FromUITex('ui/Image/OperationActivity/RedEnvelope2.uitex', 14)
		hDoodad:Lookup('Image_DoodadTitleBg'):FromUITex('ui/Image/OperationActivity/RedEnvelope2.uitex', 14)
		hDoodad:Lookup('Text_Title'):SetAlpha(255)
		hDoodad:Lookup('SFX'):Show()
	end
	hDoodad:Lookup('Text_Title'):SetText(szName .. ' (' .. #aItemData ..  ')')

	-- 修改UI大小
	Loot.AdjustWnd(wnd)
	Loot.AdjustFrame(frame)
end

function Loot.RemoveLootList(dwID)
	local frame = Loot.GetFrame()
	if not frame then
		return
	end
	local container = frame:Lookup('WndContainer_DoodadList')
	local wnd = container:LookupContent(0)
	while wnd and wnd.dwDoodadID ~= dwID do
		wnd = wnd:GetNext()
	end
	if wnd then
		wnd:Destroy()
		Loot.AdjustFrame(frame)
	end
	if container:GetAllContentCount() == 0 then
		return Loot.CloseFrame()
	end
end

function Loot.GetFrame()
	return Station.Lookup('Normal/MY_GKP_Loot')
end

function Loot.OpenFrame()
	local frame = Loot.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(GKP_LOOT_INIFILE, 'MY_GKP_Loot')
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end

-- 手动关闭 不适用自定关闭
function Loot.CloseFrame(dwID)
	local frame = Loot.GetFrame(dwID)
	if frame then
		Wnd.CloseWindow(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

local ITEM_DATA_WEIGHT = {
	COIN_SHOP      = 1,	-- 外观 披风 礼盒
	OUTLOOK        = 1,	-- 外观 披风 礼盒
	PENDANT        = 2,	-- 挂件
	PET            = 3,	-- 宠物
	HORSE          = 4,	-- 坐骑 马
	HORSE_EQUIP    = 5,	-- 马具
	BOOK           = 6,	-- 书籍
	WEAPON         = 7,	-- 武器
	EQUIPMENT_SIGN = 8,	-- 装备兑换牌
	EQUIPMENT      = 9,	-- 散件装备
	MATERIAL       = 10, -- 材料
	ZIBABA         = 11, -- 小铁
	ENCHANT_ITEM   = 12, -- 附魔
	TASK_ITEM      = 13, -- 任务道具
	OTHER          = 14,
}
local function GetItemDataType(data)
	-- 外观 披风 礼盒
	if data.item.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
		return 'COIN_SHOP'
	end
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT and (
		data.item.nSub == EQUIPMENT_SUB.L_SHOULDER_EXTEND
		or data.item.nSub == EQUIPMENT_SUB.R_SHOULDER_EXTEND
		or data.item.nSub == EQUIPMENT_SUB.BACK_CLOAK_EXTEND
	) then
		return 'OUTLOOK'
	end
	-- 挂件
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT and (
		data.item.nSub == EQUIPMENT_SUB.WAIST_EXTEND
		or data.item.nSub == EQUIPMENT_SUB.BACK_EXTEND
		or data.item.nSub == EQUIPMENT_SUB.FACE_EXTEND
	) then
		return 'PENDANT'
	end
	-- 宠物
	if (data.item.nGenre == ITEM_GENRE.CUB)
	or (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == EQUIPMENT_SUB.PET) then
		return 'PET'
	end
	-- 坐骑 马
	if (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == EQUIPMENT_SUB.HORSE) then
		return 'HORSE'
	end
	-- 马具
	if (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == EQUIPMENT_SUB.HORSE_EQUIP) then
		return 'HORSE_EQUIP'
	end
	-- 书籍
	if (data.item.nGenre == ITEM_GENRE.BOOK) then
		return 'BOOK'
	end
	-- 武器
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT
	and (data.item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or data.item.nSub == EQUIPMENT_SUB.RANGE_WEAPON) then
		return 'WEAPON'
	end
	-- 装备兑换牌
	if (data.item.nGenre == ITEM_GENRE.MATERIAL and data.item.nSub == 6) then -- TODO: 枚举？
		return 'EQUIPMENT_SIGN'
	end
	-- 散件装备
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT then -- TODO: 枚举？
		return 'EQUIPMENT'
	end
	-- 材料
	if data.item.nGenre == ITEM_GENRE.MATERIAL then
		-- 小铁
		if GKP_LOOT_ZIBABA[data.item.szName] then
			return 'ZIBABA'
		end
		-- 材料
		return 'MATERIAL'
	end
	-- 附魔
	if data.item.nGenre == ITEM_GENRE.ENCHANT_ITEM then
		return 'ENCHANT_ITEM'
	end
	-- 任务道具
	if data.item.nGenre == ITEM_GENRE.TASK_ITEM then
		return 'TASK_ITEM'
	end
	return 'OTHER'
end

local function LootItemSorter(data1, data2)
	return data1.nWeight < data2.nWeight
end

-- 检查物品
function Loot.GetDoodad(dwID)
	local me   = GetClientPlayer()
	local d    = GetDoodad(dwID)
	local aItemData = {}
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
				local data = {
					dwDoodadID   = dwID         ,
					szDoodadName = szName       ,
					item         = item         ,
					szName       = szItemName   ,
					dwID         = item.dwID    ,
					nGenre       = item.nGenre  ,
					nSub         = item.nSub    ,
					nQuality     = item.nQuality,
					bNeedRoll    = bNeedRoll    ,
					bDist        = bDist        ,
					bBidding     = bBidding     ,
				}
				if DEBUG_LOOT then
					data.bDist = true -- !!! Debug
				end
				if item.nGenre == ITEM_GENRE.BOOK then
					data.nBookID = item.nBookID
				end
				data.szType = GetItemDataType(data)
				data.nWeight = ITEM_DATA_WEIGHT[data.szType]
				table.insert(aItemData, data)
			end
		end
	end
	sort(aItemData, LootItemSorter)
	return szName, aItemData, bSpecial
end

-- 摸箱子
LIB.RegisterEvent('OPEN_DOODAD', function()
	if not MY_GKP.bOn then
		return
	end
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
		if #data == 0 then
			return Loot.RemoveLootList(arg0)
		end
		Loot.DrawLootList(arg0)
		LIB.Debug({'Open Doodad: ' .. arg0}, 'MY_GKP_Loot', DEBUG_LEVEL.LOG)
		local hLoot = Station.Lookup('Normal/LootList')
		if hLoot then
			hLoot:SetAbsPos(4096, 4096)
		end
		-- Wnd.CloseWindow('LootList')
	end
end)

-- 刷新箱子
LIB.RegisterEvent('SYNC_LOOT_LIST', function()
	if not MY_GKP.bOn then
		return
	end
	local frame = Loot.GetFrame()
	local wnd = Loot.GetDoodadWnd(frame, arg0)
	if not wnd and not (MY_GKP.bDebug and MY_GKP.bDebug2) then
		local bDungeonTreasure = false
		local szName, aItemData = Loot.GetDoodad(arg0)
		for k, v in ipairs(aItemData) do
			if wstring.find(v.szName, _L['Dungeon treasure']) == 1 then
				bDungeonTreasure = true
				break
			end
		end
		if not bDungeonTreasure then
			return
		end
	end
	Loot.DrawLootList(arg0)
end)

LIB.RegisterEvent('MY_GKP_LOOT_BOSS', function()
	if not arg0 then
		MY_GKP_LOOT_BOSS = nil
		GKP_LOOT_RECENT = {}
	else
		local team = GetClientTeam()
		if team then
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = GetClientTeam().GetMemberInfo(v)
				if info.szName == arg0 then
					MY_GKP_LOOT_BOSS = v
					break
				end
			end
		end
	end
end)

local ui = {
	GetMessageBox        = Loot.GetMessageBox,
	GetaPartyMember      = Loot.GetaPartyMember,
	GetFilterMenu        = Loot.GetFilterMenu,
	GetAutoPickupAllMenu = Loot.GetAutoPickupAllMenu,
}
setmetatable(MY_GKP_Loot, { __index = ui, __newindex = function() end, __metatable = true })
