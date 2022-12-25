--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具 - 团队概况
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamTools_Summary'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_Summary'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^14.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {
	tAnchor = {},
	tDamage = {},
	tDeath  = {},
}
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_Summary.ini'
local MY_IsParty, MY_GetSkillName, MY_GetBuffName = X.IsParty, X.GetSkillName, X.GetBuffName

local RT_EQUIP_TOTAL = {
	'MELEE_WEAPON', -- 轻剑 藏剑取 BIG_SWORD 重剑
	'RANGE_WEAPON', -- 远程武器
	'CHEST',        -- 衣服
	'HELM',         -- 帽子
	'AMULET',       -- 项链
	'LEFT_RING',    -- 戒指
	'RIGHT_RING',   -- 戒指
	'WAIST',        -- 腰带
	'PENDANT',      -- 腰坠
	'PANTS',        -- 裤子
	'BOOTS',        -- 鞋子
	'BANGLE',       -- 护腕
}

local RT_SKILL_TYPE = {
	[0]  = 'PHYSICS_DAMAGE',
	[1]  = 'SOLAR_MAGIC_DAMAGE',
	[2]  = 'NEUTRAL_MAGIC_DAMAGE',
	[3]  = 'LUNAR_MAGIC_DAMAGE',
	[4]  = 'POISON_DAMAGE',
	[5]  = 'REFLECTIED_DAMAGE',
	[6]  = 'THERAPY',
	[7]  = 'STEAL_LIFE',
	[8]  = 'ABSORB_THERAPY',
	[9]  = 'ABSORB_DAMAGE',
	[10] = 'SHIELD_DAMAGE',
	[11] = 'PARRY_DAMAGE',
	[12] = 'INSIGHT_DAMAGE',
	[13] = 'EFFECTIVE_DAMAGE',
	[14] = 'EFFECTIVE_THERAPY',
	[15] = 'TRANSFER_LIFE',
	[16] = 'TRANSFER_MANA',
}
-- 秘境评分 晚点在做吧
-- local RT_DUNGEON_TOTAL = {}
local RT_SCORE = {
	Equip   = _L['Equip score'],
	Buff    = _L['Buff score'],
	Food    = _L['Food score'],
	Enchant = _L['Enchant score'],
	Special = _L['Special equip score'],
}

local RT_EQUIP_SPECIAL = {
	MELEE_WEAPON = true,
	BIG_SWORD    = true,
	AMULET       = true,
	PENDANT      = true
}

local RT_FOOD_TYPE = {
	[24] = true,
	[17] = true,
	[18] = true,
	[19] = true,
	[20] = true
}
-- 需要监控的BUFF
local RT_BUFF_ID = {
	-- 常规职业BUFF
	[362]  = true,
	[673]  = true,
	[112]  = true,
	[382]  = true,
	[2837] = true,
	-- 红篮球
	[6329] = true,
	[6330] = true,
	-- 帮会菜盘
	[2564] = true,
	[2563] = true,
	-- 七秀扇子
	[3098] = true,
	-- 缝针 / 凤凰谷
	[2313] = true,
	[5970] = true,
}
local RT_GONGZHAN_ID = 3219
-- default sort
local RT_SORT_MODE    = 'DESC'
local RT_SORT_FIELD   = 'nEquipScore'
local RT_MAPID = 0
local RT_PLAYER_MAP_COPYID = {}
local RT_SELECT_PAGE  = 0
local RT_SELECT_KUNGFU
local RT_SELECT_DEATH
--
local RT_SCORE_FULL = 30000

function D.UpdateDungeonInfo(hDungeon)
	local me = X.GetClientPlayer()
	local szText = Table_GetMapName(RT_MAPID)
	if me.GetMapID() == RT_MAPID and X.IsDungeonMap(RT_MAPID) then
		szText = szText .. '\n' .. 'ID:(' .. me.GetScene().nCopyIndex  ..')'
	else
		local tCD = X.GetMapSaveCopy()
		if tCD and tCD[RT_MAPID] then
			szText = szText .. '\n' .. 'ID:(' .. tCD[RT_MAPID][1]  ..')'
		end
	end
	hDungeon:Lookup('Text_Dungeon'):SetText(szText)
end

function D.GetPlayerView()
	return Station.Lookup('Normal/PlayerView')
end

function D.ViewInviteToPlayer(page, dwID)
	local me = X.GetClientPlayer()
	if dwID ~= me.dwID then
		page.tViewInvite[dwID] = true
		ViewInviteToPlayer(dwID)
	end
end
-- 分数计算
function D.CountScore(tab, tScore)
	tScore.Food = tScore.Food + #tab.tFood * 100
	tScore.Buff = tScore.Buff + #tab.tBuff * 20
	if tab.nEquipScore then
		tScore.Equip = tScore.Equip + tab.nEquipScore
	end
	if tab.tTemporaryEnchant then
		tScore.Enchant = tScore.Enchant + #tab.tTemporaryEnchant * 300
	end
	if tab.tPermanentEnchant then
		tScore.Enchant = tScore.Enchant + #tab.tPermanentEnchant * 100
	end
	if tab.tEquip then
		for k, v in ipairs(tab.tEquip) do
			tScore.Special = tScore.Special + v.nLevel * 0.15 *  v.nQuality
		end
	end
end
-- 排序计算
function D.CalculateSort(tInfo)
	local nCount = -2
	if RT_SORT_FIELD == 'tBossKill' then
		if X.IsDungeonRoleProgressMap(RT_MAPID) then
			nCount = 0
			for _, p in ipairs(tInfo[RT_SORT_FIELD]) do
				if p then
					nCount = nCount + 100
				else
					nCount = nCount + 1
				end
			end
		else
			nCount = tInfo.nCopyID or math.huge
		end
	elseif tInfo[RT_SORT_FIELD] then
		if type(tInfo[RT_SORT_FIELD]) == 'table' then
			nCount = #tInfo[RT_SORT_FIELD]
		else
			nCount = tInfo[RT_SORT_FIELD]
		end
	end
	if nCount == 0 and not tInfo.bIsOnLine then
		nCount = -2
	end
	return nCount
end
function D.Sorter(a, b)
	local nCountA = D.CalculateSort(a)
	local nCountB = D.CalculateSort(b)

	if RT_SORT_MODE == 'ASC' then -- 升序
		return nCountA < nCountB
	else
		return nCountA > nCountB
	end
end
-- 更新UI 没什么特殊情况 不要clear
function D.UpdateList(page)
	local me = X.GetClientPlayer()
	if not me then return end
	local aTeam, tKungfu = D.GetTeam(page), {}
	local tScore = {
		Equip   = 0,
		Buff    = 0,
		Food    = 0,
		Enchant = 0,
		Special = 0,
	}
	table.sort(aTeam, D.Sorter)

	for k, v in ipairs(aTeam) do
		-- 心法统计
		tKungfu[v.dwMountKungfuID] = tKungfu[v.dwMountKungfuID] or {}
		table.insert(tKungfu[v.dwMountKungfuID], v)
		D.CountScore(v, tScore)
		if not RT_SELECT_KUNGFU or (RT_SELECT_KUNGFU and v.dwMountKungfuID == RT_SELECT_KUNGFU) then
			local szName = 'P' .. v.dwID
			local h = page.hList:Lookup(szName)
			if not h then
				h = page.hList:AppendItemFromData(page.hPlayer)
			end
			h:SetUserData(k)
			h:SetName(szName)
			h.dwID   = v.dwID
			h.szName = v.szName
			-- 心法名字
			if v.dwMountKungfuID and v.dwMountKungfuID ~= 0 then
				local nIcon = select(2, MY_GetSkillName(v.dwMountKungfuID, 1))
				h:Lookup('Image_Icon'):FromIconID(nIcon)
			else
				h:Lookup('Image_Icon'):FromUITex(GetForceImage(v.dwForceID))
			end
			h:Lookup('Text_Name'):SetText(v.szName)
			h:Lookup('Text_Name'):SetFontColor(X.GetForceColor(v.dwForceID))
			-- 药品和BUFF
			if not h['hHandle_Food'] then
				h['hHandle_Food'] = {
					self = h:Lookup('Handle_Food'),
					Pool = X.UI.HandlePool(h:Lookup('Handle_Food'), '<box>w=29 h=29 eventid=784</box>')
				}
			end
			if not h['hHandle_Equip'] then
				h['hHandle_Equip'] = {
					self = h:Lookup('Handle_Equip'),
					Pool = X.UI.HandlePool(h:Lookup('Handle_Equip'), '<box>w=29 h=29 eventid=784</box>')
				}
			end
			local hBuff = h:Lookup('Box_Buff')
			local hBox = h:Lookup('Box_Grandpa')
			if not v.bIsOnLine then
				h.hHandle_Equip.Pool:Clear()
				h:Lookup('Text_Toofar1'):Show()
				h:Lookup('Text_Toofar1'):SetText(g_tStrings.STR_GUILD_OFFLINE)
			end
			if not v.KPlayer then
				h.hHandle_Food.Pool:Clear()
				h:Lookup('Text_Toofar1'):Show()
				if v.bIsOnLine then
					h:Lookup('Text_Toofar1'):SetText(_L['Too far'])
				end
				hBuff:Hide()
				hBox:Hide()
			else
				hBuff:Show()
				hBox:Show()
				h:Lookup('Text_Toofar1'):Hide()
				-- 小药UI处理
				local handle_food = h.hHandle_Food.self
				for kk, vv in ipairs(v.tFood) do
					local szName = vv.dwID .. '_' .. vv.nLevel
					local nIcon = select(2, MY_GetBuffName(vv.dwID, vv.nLevel))
					local box = handle_food:Lookup(szName)
					if not box then
						box = h.hHandle_Food.Pool:New()
					end
					box:SetName(szName)
					box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, vv.dwID, vv.nLevel, vv.nEndFrame)
					box:SetObjectIcon(nIcon)
					box.OnItemRefreshTip = function()
						local dwID, nLevel, nEndFrame = select(2, this:GetObject())
						local nTime = (nEndFrame - GetLogicFrameCount()) / 16
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						X.OutputBuffTip({ x, y, w, h }, dwID, nLevel, nTime)
					end
					local nTime = (vv.nEndFrame - GetLogicFrameCount()) / 16
					if nTime < 480 then
						box:SetAlpha(80)
					else
						box:SetAlpha(255)
					end
					box:Show()
				end
				for i = 0, handle_food:GetItemCount() - 1, 1 do
					local item = handle_food:Lookup(i)
					if item and not item.bFree then
						local dwID, nLevel, nEndFrame = select(2, item:GetObject())
						if dwID and nLevel then
							if not X.GetBuff(v.KPlayer, dwID, nLevel) then
								h.hHandle_Food.Pool:Remove(item)
							end
						end
					end
				end
				handle_food:FormatAllItemPos()
				-- BUFF UI处理
				if v.tBuff and #v.tBuff > 0 then
					hBuff:EnableObject(true)
					hBuff:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
					hBuff:SetOverTextFontScheme(1, 197)
					hBuff:SetOverText(1, #v.tBuff)
					hBuff.OnItemMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local xml = {}
						for k, v in ipairs(v.tBuff) do
							local nIcon = select(2, MY_GetBuffName(v.dwID, v.nLevel))
							local nTime = (v.nEndFrame - GetLogicFrameCount()) / 16
							local nAlpha = nTime < 600 and 80 or 255
							table.insert(xml, '<image> path="fromiconid" frame=' .. nIcon ..' alpha=' .. nAlpha ..  ' w=30 h=30 </image>')
						end
						OutputTip(table.concat(xml), 250, { x, y, w, h })
					end
				else
					hBuff:SetOverText(1, '')
					hBuff:EnableObject(false)
				end
				if v.bGrandpa then
					hBox:EnableObject(true)
					hBox.OnItemMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local kBuff = X.GetBuff(v.KPlayer, RT_GONGZHAN_ID)
						if kBuff then
							X.OutputBuffTip({ x, y, w, h }, kBuff.dwID, kBuff.nLevel)
						end
					end
				end
				hBox:EnableObject(v.bGrandpa)
			end
			-- 药品：大附魔
			if v.tTemporaryEnchant and #v.tTemporaryEnchant > 0 then
				local vv = v.tTemporaryEnchant[1]
				local box = h:Lookup('Box_Enchant')
				box:Show()
				if vv.CommonEnchant then
					box:SetObjectIcon(6216)
				else
					box:SetObjectIcon(7577)
				end
				box.OnItemRefreshTip = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local desc = ''
					if vv.CommonEnchant then
						desc = X.Table_GetCommonEnchantDesc(vv.dwTemporaryEnchantID)
					else
						-- ... 官方搞的太麻烦了
						local tEnchant = GetItemEnchantAttrib(vv.dwTemporaryEnchantID)
						if tEnchant then
							for kkk, vvv in pairs(tEnchant) do
								if vvv.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then -- ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER
									local SkillEvent = X.GetGameTable('SkillEvent', true)
									local skillEvent = SkillEvent and SkillEvent:Search(vvv.nValue1)
									if skillEvent then
										desc = desc .. FormatString(skillEvent.szDesc, vvv.nValue1, vvv.nValue2)
									else
										desc = desc .. '<text>text="unknown skill event id:'.. vvv.nValue1..'"</text>'
									end
								elseif vvv.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then -- ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE
									local EquipmentRecipe = X.GetGameTable('EquipmentRecipe', true)
									if EquipmentRecipe then
										local tRecipeSkillAtrri = EquipmentRecipe:Search(vvv.nValue1, vvv.nValue2)
										if tRecipeSkillAtrri then
											desc = desc .. tRecipeSkillAtrri.szDesc
										end
									end
								else
									if Table_GetMagicAttributeInfo then
										desc = desc .. FormatString(Table_GetMagicAttributeInfo(vvv.nID, true), vvv.nValue1, vvv.nValue2, 0, 0)
									else
										desc = GetFormatText('Enchant Attrib value ' .. vvv.nValue1 .. ' ', 113)
									end
								end

							end
						end
					end
					if desc and #desc > 0 then
						OutputTip(desc:gsub('font=%d+', 'font=113') .. GetFormatText(FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME ..'\n', GetTimeText(vv.nTemporaryEnchantLeftSeconds)), 102), 400, { x, y, w, h })
					end
				end
				if vv.nTemporaryEnchantLeftSeconds < 480 then
					box:SetAlpha(80)
				else
					box:SetAlpha(255)
				end
			else
				h:Lookup('Box_Enchant'):Hide()
			end
			-- 装备
			if v.tEquip and #v.tEquip > 0 then
				local handle_equip = h.hHandle_Equip.self
				for kk, vv in ipairs(v.tEquip) do

					local szName = tostring(vv.nUiId)
					local box = handle_equip:Lookup(szName)
					if not box then
						box = h.hHandle_Equip.Pool:New()
						X.UpdateItemBoxExtend(box, vv.nQuality)
					end
					box:SetName(szName)
					box:SetObject(UI_OBJECT_OTER_PLAYER_ITEM, vv.nUiId, vv.dwBox, vv.dwX, v.dwID)
					box:SetObjectIcon(vv.nIcon)
					local item = GetItem(vv.dwID)
					if item then
						UpdataItemBoxObject(box, vv.dwBox, vv.dwX, item, nil, nil, v.dwID)
					end
					box.OnItemRefreshTip = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						if not GetItem(vv.dwID) then
							D.GetTotalEquipScore(page, v.dwID)
							OutputItemTip(UI_OBJECT_ITEM_INFO, X.ENVIRONMENT.CURRENT_ITEM_VERSION, vv.dwTabType, vv.dwIndex, {x, y, w, h})
						else
							OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, vv.dwID, nil, nil, { x, y, w, h })
						end
					end
					box:Show()
				end
				for i = 0, handle_equip:GetItemCount() - 1, 1 do
					local item = handle_equip:Lookup(i)
					if item and not item.bFree then
						local nUiId, bDelete = item:GetName(), true
						for kk ,vv in ipairs(v.tEquip) do
							if tostring(vv.nUiId) == nUiId then
								bDelete = false
								break
							end
						end
						if bDelete then
							h.hHandle_Equip.Pool:Remove(item)
						end
					end
				end
				handle_equip:FormatAllItemPos()
			end
			-- 装备分
			local hScore = h:Lookup('Text_Score')
			if v.nEquipScore then
				hScore:SetText(v.nEquipScore)
			else
				if v.bIsOnLine then
					hScore:SetText(_L['Loading'])
				else
					hScore:SetText(g_tStrings.STR_GUILD_OFFLINE)
				end
			end
			-- 秘境CD
			if not h.hHandle_BossKills then
				h.hHandle_BossKills = {
					self = h:Lookup('Handle_BossKills'),
					Pool = X.UI.HandlePool(h:Lookup('Handle_BossKills'), '<handle>postype=8 eventid=784 w=16 h=14 <image>name="Image_BossKilled" w=14 h=14 path="ui/Image/UITga/FBcdPanel01.UITex" frame=20</image><image>name="Image_BossAlive" w=14 h=14 path="ui/Image/UITga/FBcdPanel01.UITex" frame=21</image></handle>')
				}
			end
			local hCopyID = h:Lookup('Text_CopyID')
			local hBossKills = h:Lookup('Handle_BossKills')
			if X.IsDungeonRoleProgressMap(RT_MAPID) then
				for nIndex, bKill in ipairs(v.tBossKill) do
					local szName = tostring(nIndex)
					local hBossKill = hBossKills:Lookup(szName)
					if not hBossKill then
						hBossKill = h.hHandle_BossKills.Pool:New()
						hBossKill:SetName(szName)
					end
					hBossKill:Lookup('Image_BossAlive'):SetVisible(not bKill)
					hBossKill:Lookup('Image_BossKilled'):SetVisible(bKill)
					hBossKill.OnItemRefreshTip = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local texts = {}
						for i, boss in ipairs(Table_GetCDProcessBoss(RT_MAPID)) do
							table.insert(texts, boss.szName .. '\t' .. _L[v.tBossKill[i] and 'x' or 'r'])
						end
						OutputTip(GetFormatText(table.concat(texts, '\n')), 400, { x, y, w, h })
					end
					hBossKill:Show()
				end
				for i = 0, hBossKills:GetItemCount() - 1, 1 do
					local item = hBossKills:Lookup(i)
					if item and not item.bFree then
						if tonumber(item:GetName()) > #v.tBossKill then
							h.hHandle_BossKills.Pool:Remove(item)
						end
					end
				end
				hBossKills:FormatAllItemPos()
				hCopyID:Hide()
				hBossKills:Show()
			else
				hCopyID:SetText(v.nCopyID == -1 and _L['None'] or v.nCopyID or _L['Unknown'])
				hCopyID:Show()
				hBossKills:Hide()
			end
			-- 战斗状态
			if v.nFightState == 1 then
				h:Lookup('Image_Fight'):Show()
			else
				h:Lookup('Image_Fight'):Hide()
			end
		end
	end
	page.hList:FormatAllItemPos()
	for i = 0, page.hList:GetItemCount() - 1, 1 do
		local item = page.hList:Lookup(i)
		if item and item:IsValid() then
			if not MY_IsParty(item.dwID) and item.dwID ~= me.dwID then
				page.hList:RemoveItem(item)
				page.hList:FormatAllItemPos()
			end
		end
	end
	-- 分数
	page.tScore = tScore
	local nScore = 0
	for k, v in pairs(tScore) do
		nScore = nScore + v
	end
	page.hTotalScore:SetText(math.floor(nScore))
	local nNum      = #D.GetTeamMemberList(true)
	local nAvgScore = nScore / nNum
	page.hProgress:Lookup('Image_Progress'):SetPercentage(nAvgScore / RT_SCORE_FULL)
	page.hProgress:Lookup('Text_Progress'):SetText(_L('Team strength(%d/%d)', math.floor(nAvgScore), RT_SCORE_FULL))
	-- 心法统计
	for k, dwKungfuID in pairs(X.GetKungfuIDS()) do
		local h = page.hKungfuList:Lookup(k - 1)
		local img = h:Lookup('Image_Force')
		local nCount = 0
		if tKungfu[dwKungfuID] then
			nCount = #tKungfu[dwKungfuID]
		end
		local szName, nIcon = MY_GetSkillName(dwKungfuID)
		img:FromIconID(nIcon)
		h:Lookup('Text_Num'):SetText(nCount)
		if not tKungfu[dwKungfuID] then
			h:SetAlpha(60)
			h.OnItemMouseEnter = nil
		else
			h:SetAlpha(255)
			h.OnItemMouseEnter = function()
				this:Lookup('Text_Num'):SetFontScheme(101)
				local xml = {}
				table.insert(xml, GetFormatText(szName .. g_tStrings.STR_COLON .. nCount .. g_tStrings.STR_PERSON ..'\n', 157))
				table.sort(tKungfu[dwKungfuID], function(a, b)
					local nCountA = a.nEquipScore or -1
					local nCountB = b.nEquipScore or -1
					return nCountA > nCountB
				end)
				for k, v in ipairs(tKungfu[dwKungfuID]) do
					if v.nEquipScore then
						table.insert(xml, GetFormatText(v.szName .. g_tStrings.STR_COLON ..  v.nEquipScore  ..'\n', 106))
					else
						table.insert(xml, GetFormatText(v.szName ..'\n', 106))
					end
				end
				local x, y = img:GetAbsPos()
				local w, h = img:GetSize()
				OutputTip(table.concat(xml), 400, { x, y, w, h })
			end
		end
	end
end

local function CreateItemTable(item, dwBox, dwX)
	return {
		nIcon     = X.GetItemIconByUIID(item.nUiId),
		dwID      = item.dwID,
		nLevel    = item.nLevel,
		szName    = X.GetItemNameByUIID(item.nUiId),
		nUiId     = item.nUiId,
		nVersion  = item.nVersion,
		dwTabType = item.dwTabType,
		dwIndex   = item.dwIndex,
		nQuality  = item.nQuality,
		dwBox     = dwBox,
		dwX       = dwX
	}
end

function D.GetEquipCache(page, KPlayer)
	if not KPlayer then
		return
	end
	local me = X.GetClientPlayer()
	local aInfo = {
		tEquip            = {},
		tPermanentEnchant = {},
		tTemporaryEnchant = {}
	}
	-- 装备 Output(X.GetClientPlayer().GetItem(0,0).GetMagicAttrib())
	for _, equip in ipairs(RT_EQUIP_TOTAL) do
		-- if #aInfo.tEquip >= 3 then break end
		-- 藏剑只看重剑
		if KPlayer.dwForceID == 8 and X.CONSTANT.EQUIPMENT_INVENTORY[equip] == X.CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON then
			equip = 'BIG_SWORD'
		end
		local dwBox, dwX = INVENTORY_INDEX.EQUIP, X.CONSTANT.EQUIPMENT_INVENTORY[equip]
		local item = KPlayer.GetItem(dwBox, dwX)
		if item then
			if RT_EQUIP_SPECIAL[equip] then
				if item.dwSkillID ~= 0 then
					table.insert(aInfo.tEquip, CreateItemTable(item, dwBox, dwX))
				elseif equip == 'PENDANT' then
					local desc = Table_GetItemDesc(item.nUiId)
					if desc and (desc:find(_L['Use:']) or desc:find(_L['Use: ']) or desc:find('15 seconds')) then
						table.insert(aInfo.tEquip, CreateItemTable(item, dwBox, dwX))
					end
				-- elseif item.nQuality == 5 then -- 橙色装备
				-- 	table.insert(aInfo.tEquip, CreateItemTable(item))
				else
					-- 黄字装备
					local aMagicAttrib = item.GetMagicAttrib()
					for _, tAttrib in ipairs(aMagicAttrib) do
						if tAttrib.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
							table.insert(aInfo.tEquip, CreateItemTable(item, dwBox, dwX))
							break
						end
					end
				end
			end
			-- 永久的附魔 用于评分
			if item.dwPermanentEnchantID and item.dwPermanentEnchantID ~= 0 then
				table.insert(aInfo.tPermanentEnchant, {
					dwPermanentEnchantID = item.dwPermanentEnchantID,
				})
			end
			-- 大附魔 / 临时附魔 用于评分
			if item.dwTemporaryEnchantID and item.dwTemporaryEnchantID ~= 0 then
				local dat = {
					dwTemporaryEnchantID         = item.dwTemporaryEnchantID,
					nTemporaryEnchantLeftSeconds = item.GetTemporaryEnchantLeftSeconds()
				}
				if X.Table_GetCommonEnchantDesc(item.dwTemporaryEnchantID) then
					dat.CommonEnchant = true
				end
				table.insert(aInfo.tTemporaryEnchant, dat)
			end
		end
	end
	-- 这些都是一次性的缓存数据
	page.tDataCache[KPlayer.dwID] = {
		tEquip            = aInfo.tEquip,
		tPermanentEnchant = aInfo.tPermanentEnchant,
		tTemporaryEnchant = aInfo.tTemporaryEnchant,
		nEquipScore       = KPlayer.GetTotalEquipScore()
	}
	page.tViewInvite[KPlayer.dwID] = nil
	if X.IsEmpty(page.tViewInvite) then
		if KPlayer.dwID ~= me.dwID then
			FireUIEvent('MY_RAIDTOOLS_SUCCESS') -- 装备请求完毕
		end
	else
		ViewInviteToPlayer(next(page.tViewInvite), true)
	end
end

function D.GetTotalEquipScore(page, dwID)
	if not page.tViewInvite[dwID] then
		page.tViewInvite[dwID] = true
		ViewInviteToPlayer(dwID, true)
	end
end

function D.UpdateSelfData()
	local dwMapID = RT_MAPID
	local dwID = X.GetClientPlayerID()
	local function fnAction(tMapID)
		local aCopyID = tMapID[dwMapID]
		if not RT_PLAYER_MAP_COPYID[dwID] then
			RT_PLAYER_MAP_COPYID[dwID] = {}
		end
		RT_PLAYER_MAP_COPYID[dwID][dwMapID] = X.IsTable(aCopyID) and aCopyID[1] or -1
		FireUIEvent('MY_TEAMTOOLS_SUMMARY')
	end
	X.GetMapSaveCopy(fnAction)
end

function D.RequestTeamData()
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local aRequestID, aRefreshID = {}, {}
	local bDungeonMap = X.IsDungeonMap(RT_MAPID)
	local bIsDungeonRoleProgressMap = X.IsDungeonRoleProgressMap(RT_MAPID)
	--[[#DEBUG BEGIN]]
	if bIsDungeonRoleProgressMap then
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'Update team map progress.', X.DEBUG_LEVEL.LOG)
	end
	--[[#DEBUG END]]
	local aTeamMemberList = D.GetTeamMemberList(true)
	for _, dwID in ipairs(aTeamMemberList) do
		if bIsDungeonRoleProgressMap then -- 秘境进度
			ApplyDungeonRoleProgress(RT_MAPID, dwID) -- 成功回调 UPDATE_DUNGEON_ROLE_PROGRESS(dwMapID, dwPlayerID)
		elseif bDungeonMap then -- 秘境CDID
			if not RT_PLAYER_MAP_COPYID[dwID] then
				RT_PLAYER_MAP_COPYID[dwID] = {}
			end
			if RT_PLAYER_MAP_COPYID[dwID][RT_MAPID] then
				table.insert(aRefreshID, dwID)
			else
				table.insert(aRequestID, dwID)
			end
		end
	end
	if not X.IsEmpty(aRequestID) or not X.IsEmpty(aRefreshID) then
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'Request team map copy id.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		if #aRequestID == #aTeamMemberList then
			aRequestID = nil
		end
		if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			X.Systopmsg(_L['Fetch teammate\'s data failed, please unlock talk and reopen.'])
		else
			X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_MAP_COPY_ID_REQUEST', {RT_MAPID, aRequestID, nil})
		end
	end
	-- 刷新自己的
	D.UpdateSelfData()
end

-- 获取团队大部分情况 非缓存
function D.GetTeam(page)
	local me    = X.GetClientPlayer()
	local team  = GetClientTeam()
	local aList = {}
	local bIsInParty = X.IsInParty()
	local bIsDungeonRoleProgressMap = X.IsDungeonRoleProgressMap(RT_MAPID)
	local aProgressMapBoss = bIsDungeonRoleProgressMap and Table_GetCDProcessBoss(RT_MAPID)
	local aRequestMapCopyID = {}
	local aTeamMemberList = D.GetTeamMemberList()
	for _, dwID in ipairs(aTeamMemberList) do
		local KPlayer = X.GetPlayer(dwID)
		local info = bIsInParty and team.GetMemberInfo(dwID) or {}
		local aInfo = {
			KPlayer           = KPlayer,
			szName            = KPlayer and KPlayer.szName or info.szName or _L['Loading...'],
			dwID              = dwID,  -- ID
			dwForceID         = KPlayer and KPlayer.dwForceID or info.dwForceID, -- 门派ID
			dwMountKungfuID   = info and info.dwMountKungfuID or UI_GetPlayerMountKungfuID(), -- 内功
			-- tPermanentEnchant = {}, -- 附魔
			-- tTemporaryEnchant = {}, -- 临时附魔
			-- tEquip            = {}, -- 特效装备
			tBuff             = {}, -- 增益BUFF
			tFood             = {}, -- 小吃和附魔
			-- nEquipScore       = -1,  -- 装备分
			nCopyID           = RT_PLAYER_MAP_COPYID[dwID] and RT_PLAYER_MAP_COPYID[dwID][RT_MAPID], -- 秘境ID
			tBossKill         = {}, -- 秘境进度
			nFightState       = KPlayer and KPlayer.bFightState and 1 or 0, -- 战斗状态
			bIsOnLine         = true,
			bGrandpa          = false, -- 大爷
		}
		if info and info.bIsOnLine ~= nil then
			aInfo.bIsOnLine = info.bIsOnLine
		end
		if KPlayer then
			-- 小吃和buff
			local nType
			for _, buff in X.ipairs_c(X.GetBuffList(KPlayer)) do
				nType = GetBuffInfo(buff.dwID, buff.nLevel, {}).nDetachType or 0
				if RT_FOOD_TYPE[nType] then
					table.insert(aInfo.tFood, buff)
				end
				if RT_BUFF_ID[buff.dwID] then
					table.insert(aInfo.tBuff, buff)
				end
				if buff.dwID == RT_GONGZHAN_ID then -- grandpa
					aInfo.bGrandpa = true
				end
			end
			if me.dwID == KPlayer.dwID then
				D.GetEquipCache(page, me)
			end
		end
		-- 秘境进度
		if aInfo.bIsOnLine and bIsDungeonRoleProgressMap then
			for i, boss in ipairs(aProgressMapBoss) do
				aInfo.tBossKill[i] = GetDungeonRoleProgress(RT_MAPID, dwID, boss.dwProgressID)
			end
		end
		setmetatable(aInfo, { __index = page.tDataCache[dwID] })
		table.insert(aList, aInfo)
	end
	return aList
end

function D.GetEquip(page)
	local hView = D.GetPlayerView()
	if hView and hView:IsVisible() then -- 查看装备的时候停止请求
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local team = GetClientTeam()
	for k, v in ipairs(D.GetTeamMemberList()) do
		if v ~= me.dwID then
			local info = team.GetMemberInfo(v)
			if info.bIsOnLine then
				D.GetTotalEquipScore(page, v)
			end
		end
	end
end

-- 获取团队成员列表
function D.GetTeamMemberList(bIsOnLine)
	local me   = X.GetClientPlayer()
	local team = GetClientTeam()
	if me.IsInParty() then
		if bIsOnLine then
			local tTeam = {}
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = team.GetMemberInfo(v)
				if info and info.bIsOnLine then
					table.insert(tTeam, v)
				end
			end
			return tTeam
		else
			return team.GetTeamMemberList()
		end
	else
		return { me.dwID }
	end
end

function D.SetMapID(dwMapID)
	if RT_MAPID == dwMapID then
		return
	end
	RT_MAPID = dwMapID
	FireUIEvent('MY_RAIDTOOLS_MAPID_CHANGE')
end

X.RegisterEvent('LOADING_END', function()
	D.SetMapID(X.GetClientPlayer().GetMapID())
end)

X.RegisterBgMsg('MY_MAP_COPY_ID', function(_, data, nChannel, dwID, szName, bIsSelf)
	local dwMapID, aCopyID = data[1], data[2]
	if not RT_PLAYER_MAP_COPYID[dwID] then
		RT_PLAYER_MAP_COPYID[dwID] = {}
	end
	RT_PLAYER_MAP_COPYID[dwID][dwMapID] = X.IsTable(aCopyID) and aCopyID[1] or -1
	FireUIEvent('MY_TEAMTOOLS_SUMMARY')
end)

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_TeamTools_Summary')
	local wnd = frameTemp:Lookup('Wnd_Summary')
	wnd:ChangeRelation(this, true, true)
	Wnd.CloseWindow(frameTemp)

	local page = this
	local frame = page:GetRoot()
	frame:RegisterEvent('PEEK_OTHER_PLAYER')
	frame:RegisterEvent('PARTY_ADD_MEMBER')
	frame:RegisterEvent('PARTY_DISBAND')
	frame:RegisterEvent('PARTY_DELETE_MEMBER')
	frame:RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG')
	frame:RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND')
	frame:RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS')
	frame:RegisterEvent('LOADING_END')
	-- 团长变更 重新请求标签
	frame:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	-- 自定义事件
	frame:RegisterEvent('MY_TEAMTOOLS_SUMMARY')
	frame:RegisterEvent('MY_RAIDTOOLS_SUCCESS')
	frame:RegisterEvent('MY_RAIDTOOLS_DEATH')
	frame:RegisterEvent('MY_RAIDTOOLS_ENTER_MAP')
	frame:RegisterEvent('MY_RAIDTOOLS_MAPID_CHANGE')
	-- 重置心法选择
	RT_SELECT_KUNGFU = nil
	page.hPlayer = frame:CreateItemData(SZ_INI, 'Handle_Item_Player')
	page.hList = page:Lookup('Wnd_Summary/Scroll_Player', '')

	this.tScore = {}
	-- 排序
	local hTitle = page:Lookup('Wnd_Summary', 'Handle_Player_BG')
	for k, v in ipairs({'dwForceID', 'tFood', 'tBuff', 'tEquip', 'nEquipScore', 'tBossKill', 'nFightState'}) do
		local txt = hTitle:Lookup('Text_Title_' .. k)
		txt.nFont = txt:GetFontScheme()
		txt.OnItemMouseEnter = function()
			this:SetFontScheme(101)
		end
		txt.OnItemMouseLeave = function()
			this:SetFontScheme(this.nFont)
		end
		txt.OnItemLButtonClick = function()
			if v == RT_SORT_FIELD then
				RT_SORT_MODE = RT_SORT_MODE == 'ASC' and 'DESC' or 'ASC'
			else
				RT_SORT_MODE = 'DESC'
			end
			RT_SORT_FIELD = v
			D.UpdateList(page) -- set userdata
			page.hList:Sort()
			page.hList:FormatAllItemPos()
		end
	end
	-- 装备分
	this.hTotalScore = page:Lookup('Wnd_Summary', 'Handle_Score/Text_TotalScore')
	this.hProgress   = page:Lookup('Wnd_Summary', 'Handle_Progress')
	-- 秘境信息
	local hDungeon = page:Lookup('Wnd_Summary', 'Handle_Dungeon')
	D.UpdateDungeonInfo(hDungeon)
	this.hKungfuList = page:Lookup('Wnd_Summary', 'Handle_Kungfu/Handle_Kungfu_List')
	this.hKungfu     = frame:CreateItemData(SZ_INI, 'Handle_Kungfu_Item')
	this.hKungfuList:Clear()
	for k, dwKungfuID in pairs(X.GetKungfuIDS()) do
		local h = this.hKungfuList:AppendItemFromData(this.hKungfu, dwKungfuID)
		local img = h:Lookup('Image_Force')
		img:FromIconID(select(2, MY_GetSkillName(dwKungfuID)))
		h:Lookup('Text_Num'):SetText(0)
		h.nFont = h:Lookup('Text_Num'):GetFontScheme()
		h.OnItemMouseLeave = function()
			HideTip()
			if RT_SELECT_KUNGFU == tonumber(this:GetName()) then
				this:Lookup('Text_Num'):SetFontScheme(101)
			else
				this:Lookup('Text_Num'):SetFontScheme(h.nFont)
			end
		end
		h.OnItemLButtonClick = function()
			if this:GetAlpha() ~= 255 then
				return
			end
			page.hList:Clear()
			if RT_SELECT_KUNGFU then
				if RT_SELECT_KUNGFU == tonumber(this:GetName()) then
					RT_SELECT_KUNGFU = nil
					h:Lookup('Text_Num'):SetFontScheme(101)
					return D.UpdateList(page)
				else
					local h = this:GetParent():Lookup(tostring(RT_SELECT_KUNGFU))
					h:Lookup('Text_Num'):SetFontScheme(h.nFont)
				end
			end
			RT_SELECT_KUNGFU = tonumber(this:GetName())
			this:Lookup('Text_Num'):SetFontScheme(101)
			D.UpdateList(page)
		end
	end
	this.hKungfuList:FormatAllItemPos()
	-- ui 临时变量
	this.tViewInvite = {} -- 请求装备队列
	this.tDataCache  = {} -- 临时数据
	-- lang
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_3'):SetText(_L['BUFF'])
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_4'):SetText(_L['Equip'])
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_6'):SetText(_L['Dungeon CD'])
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_7'):SetText(_L['Fight'])
end

function D.OnActivePage()
	local hView = D.GetPlayerView()
	if hView and hView:IsVisible() then
		hView:Hide()
	end
	X.BreatheCall('MY_RaidTools_Draw', 1000, D.UpdateList, this)
	X.BreatheCall('MY_RaidTools_GetEquip', 3000, D.GetEquip, this)
	X.BreatheCall('MY_RaidTools_RequestTeamData', 30000, D.RequestTeamData, this)
end

function D.OnDeactivePage()
	X.BreatheCall('MY_RaidTools_Draw', false)
	X.BreatheCall('MY_RaidTools_GetEquip', false)
	X.BreatheCall('MY_RaidTools_RequestTeamData', false)
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TEAMTOOLS_SUMMARY' then
		D.UpdateList(this)
	elseif szEvent == 'UPDATE_DUNGEON_ROLE_PROGRESS' then
		D.UpdateList(this)
	elseif szEvent == 'PEEK_OTHER_PLAYER' then
		if arg0 == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
			if this.tViewInvite[arg1] then
				D.GetEquipCache(this, X.GetPlayer(arg1)) -- 抓取所有数据
			end
		else
			this.tViewInvite[arg1] = nil
		end
	elseif szEvent == 'PARTY_SET_MEMBER_ONLINE_FLAG' then
		if arg2 == 0 then
			this.tDataCache[arg1] = nil
		end
	elseif szEvent == 'PARTY_DELETE_MEMBER' then
		local me = X.GetClientPlayer()
		if me.dwID == arg1 then
			this.tDataCache = {}
			this.hList:Clear()
		else
			this.tDataCache[arg1] = nil
		end
	elseif szEvent == 'LOADING_END' or szEvent == 'PARTY_DISBAND' then
		this.tDataCache = {}
		this.hList:Clear()
		-- 秘境信息
		local hDungeon = this:Lookup('Wnd_Summary', 'Handle_Dungeon')
		D.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'MY_RAIDTOOLS_MAPID_CHANGE' then
		D.RequestTeamData() -- 地图变化刷新
		local hDungeon = this:Lookup('Wnd_Summary', 'Handle_Dungeon')
		D.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'ON_APPLY_PLAYER_SAVED_COPY_RESPOND' then
		local hDungeon = this:Lookup('Wnd_Summary', 'Handle_Dungeon')
		D.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'MY_RAIDTOOLS_SUCCESS' then
		if RT_SORT_FIELD == 'nEquipScore' then
			D.UpdateList(this)
			this.hList:Sort()
			this.hList:FormatAllItemPos()
		end
	end
end

function D.OnLButtonClick()
end

function D.OnItemMouseEnter()
	local szName = this:GetName()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(true)
	elseif szName == 'Handle_Score' then
		local img = this:Lookup('Image_Score')
		img:SetFrame(23)
		local nScore = this:Lookup('Text_TotalScore'):GetText()
		local xml = {}
		table.insert(xml, GetFormatText(g_tStrings.STR_SCORE .. g_tStrings.STR_COLON .. nScore ..'\n', 65))
		for k, v in pairs(this:GetParent():GetParent():GetParent().tScore) do
			table.insert(xml, GetFormatText(RT_SCORE[k] .. g_tStrings.STR_COLON, 67))
			table.insert(xml, GetFormatText(v ..'\n', 44))
		end
		local x, y = img:GetAbsPos()
		local w, h = img:GetSize()
		OutputTip(table.concat(xml), 400, { x, y, w, h })
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(false)
	elseif szName == 'Handle_Score' then
		this:Lookup('Image_Score'):SetFrame(22)
	end
	HideTip()
end

function D.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_Dungeon' then
		local menu = X.GetDungeonMenu(function(p) D.SetMapID(p.dwID) end)
		menu.x, menu.y = Cursor.GetPos(true)
		PopupMenu(menu)
	elseif tonumber(szName:find('P(%d+)')) then
		local dwID = tonumber(szName:match('P(%d+)'))
		if IsCtrlKeyDown() then
			X.EditBox_AppendLinkPlayer(this.szName)
		else
			D.ViewInviteToPlayer(this:GetParent():GetParent():GetParent():GetParent(), dwID)
		end
	end
end

function D.OnItemRButtonClick()
	local szName = this:GetName()
	local dwID = tonumber(szName:match('P(%d+)'))
	local me = X.GetClientPlayer()
	if dwID and dwID ~= me.dwID then
		local page = this:GetParent():GetParent():GetParent():GetParent()
		local menu = {
			{ szOption = this.szName, bDisable = true },
			{ bDevide = true }
		}
		InsertPlayerCommonMenu(menu, dwID, this.szName)
		menu[#menu] = {
			szOption = g_tStrings.STR_LOOKUP, fnAction = function()
				D.ViewInviteToPlayer(page, dwID)
			end
		}
		local t = {}
		InsertTargetMenu(t, dwID)
		for _, v in ipairs(t) do
			if v.szOption == g_tStrings.LOOKUP_INFO then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then
						table.insert(menu, vv)
						break
					end
				end
				break
			end
		end
		if MY_CharInfo and MY_CharInfo.ViewCharInfoToPlayer then
			menu[#menu + 1] = {
				szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR, fnAction = function()
					MY_CharInfo.ViewCharInfoToPlayer(dwID)
				end
			}
		end
		PopupMenu(menu)
	end
end

-- Module exports
do
local settings = {
	name = 'MY_TeamTools_Summary_Module',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnDeactivePage',
			},
			root = D,
		},
	},
}
MY_TeamTools.RegisterModule('Summary', _L['MY_TeamTools_Summary'], X.CreateModule(settings))
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
