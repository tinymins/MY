--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Doodad 物品采集拾取助手
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
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKPDoodad'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local O = {
	bOpenLoot = false, -- 自动打开掉落
	bOpenLootEvenFight = false, -- 战斗中也打开
	bShowName = false, -- 显示物品名称
	tNameColor = { 196, 64, 255 }, -- 头顶名称颜色
	bMiniFlag = false, -- 显示小地图标记
	bInteract = false, -- 自动采集
	bInteractEvenFight = false, -- 战斗中也采集
	tCraft = {}, -- 草药、矿石列表
	bQuestDoodad = false, -- 任务物品
	bAllDoodad = false, -- 其它全部
	bCustom = true, -- 启用自定义
	szCustom = '', -- 自定义列表
	bRecent = true, -- 启用自动最近5分钟采集
}
RegisterCustomData('MY_GKPDoodad.bOpenLoot')
RegisterCustomData('MY_GKPDoodad.bOpenLootEvenFight')
RegisterCustomData('MY_GKPDoodad.bShowName')
RegisterCustomData('MY_GKPDoodad.tNameColor')
RegisterCustomData('MY_GKPDoodad.bMiniFlag')
RegisterCustomData('MY_GKPDoodad.bInteract')
RegisterCustomData('MY_GKPDoodad.bInteractEvenFight')
RegisterCustomData('MY_GKPDoodad.tCraft')
RegisterCustomData('MY_GKPDoodad.bQuestDoodad')
RegisterCustomData('MY_GKPDoodad.bAllDoodad')
RegisterCustomData('MY_GKPDoodad.bCustom')
RegisterCustomData('MY_GKPDoodad.szCustom')
RegisterCustomData('MY_GKPDoodad.bRecent')

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local INI_SHADOW = PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini'

local function GetDoodadTemplateName(dwID)
	return GetDoodadTemplate(dwID).szName
end

local function IsShielded()
	return LIB.IsInShieldedMap() and LIB.IsShieldedVersion('TARGET')
end

local function IsAutoInteract()
	return O.bInteract and not IsShiftKeyDown() and not Station.Lookup('Normal/MY_GKP_Loot') and not LIB.IsShieldedVersion('MY_GKPDoodad')
end

local D = {
	-- 草药、矿石列表
	tCraft = {
		1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009,
		1010, 1011, 1012, 1015, 1016, 1017, 1018, 1019, 2641,
		2642, 2643, 3321, 3358, 3359, 3360, 3361, 4227, 4228,
		5659, 5660,
		0, -- switch
		1020, 1021, 1022, 1023, 1024, 1025, 1027, 2644, 2645,
		4229, 4230, 5661, 5662,
	},
	tCustom = {}, -- 自定义列表
	tRecent = {}, -- 最近采集的东西、自动继续采集
	tDoodad = {}, -- 待处理的 doodad 列表
	nToLoot = 0,  -- 待拾取处理数量（用于修复判断）
}

function D.IsCustomDoodad(doodad)
	if O.bCustom and D.tCustom[doodad.szName] then
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			return GetDoodadTemplate(doodad.dwTemplateID).dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING
		end
		return true
	end
	return false
end

function D.IsRecentDoodad(doodad)
	if O.bRecent and D.tRecent[doodad.dwTemplateID] then
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			return GetDoodadTemplate(doodad.dwTemplateID).dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING
		end
		return true
	end
	return false
end

-- try to add
function D.TryAdd(dwID, bDelay)
	if bDelay then
		return LIB.DelayCall('MY_GKPDoodad__DelayTryAdd' .. dwID, 500, function() D.TryAdd(dwID) end)
	end
	local doodad = GetDoodad(dwID)
	if doodad then
		local data, me = nil, GetClientPlayer()
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			if O.bOpenLoot and doodad.CanLoot(me.dwID) then
				data = { loot = true }
			elseif D.IsCustomDoodad(doodad) then
				data = { craft = true }
			elseif D.IsRecentDoodad(doodad) then
				data = { recent = true }
			end
		elseif O.bQuestDoodad and (doodad.dwTemplateID == 3713 or doodad.dwTemplateID == 3714) then
			data = { craft = true }
		elseif O.tCraft[doodad.dwTemplateID] then
			data = { craft = true }
		elseif D.IsCustomDoodad(doodad) then
			data = { craft = true }
		elseif D.IsRecentDoodad(doodad) then
			data = { recent = true }
		elseif doodad.HaveQuest(me.dwID) then
			if O.bQuestDoodad then
				data = { quest = true }
			end
		elseif doodad.dwTemplateID == 4733 or doodad.dwTemplateID == 4734 and O.bQuestDoodad then
			data = { craft = true }
		elseif O.bAllDoodad and CanSelectDoodad(doodad.dwID) then
			data = { other = true }
		end
		if data then
			D.tDoodad[dwID] = data
			D.bUpdateLabel = true
		end
	end
end

-- remove doodad
function D.Remove(dwID)
	local data = D.tDoodad[dwID]
	if data then
		D.tDoodad[dwID] = nil
		D.bUpdateLabel = true
	end
end

-- reload doodad
function D.RescanNearby()
	D.tDoodad = {}
	for _, k in ipairs(LIB.GetNearDoodadID()) do
		D.TryAdd(k)
	end
	D.bUpdateLabel = true
end

function D.ReloadCustom()
	local t = {}
	local szText = StringReplaceW(O.szCustom, _L['|'], '|')
	for _, v in ipairs(LIB.SplitString(szText, '|')) do
		v = LIB.TrimString(v)
		if v ~= '' then
			t[v] = true
		end
	end
	D.tCustom = t
	D.tRecent = {}
	D.RescanNearby()
end

LIB.RegisterInit('MY_GKPDoodad', function()
	-- 粮草堆，散落的镖银，阵营首领战利品、押运奖赏
	if IsEmpty(O.szCustom) then
		local t = {}
		for _, v in ipairs({ 3874, 4255, 4315, 5622, 5732 }) do
			insert(t, GetDoodadTemplateName(v))
		end
		O.szCustom = concat(t, '|')
		D.ReloadCustom()
	end
end)

-- switch name
function D.CheckShowName()
	local hName = UI.GetShadowHandle('MY_GKPDoodad')
	local bShowName = O.bShowName and not IsShielded()
	if bShowName and not D.pLabel then
		D.pLabel = hName:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Name')
		LIB.BreatheCall('MY_GKPDoodad#HeadName', function()
			if D.bUpdateLabel then
				D.bUpdateLabel = false
				D.OnUpdateHeadName()
			end
		end)
		D.bUpdateLabel = true
	elseif not bShowName and D.pLabel then
		hName:Clear()
		D.pLabel = nil
		LIB.BreatheCall('MY_GKPDoodad#HeadName', false)
	end
end

-- find & get opened dooad ID
function D.GetOpenDoodadID()
	local dwID = D.dwOpenID
	if dwID then
		D.dwOpenID = nil
	end
	return dwID
end

-------------------------------------
-- 事件处理
-------------------------------------
-- head name
function D.OnUpdateHeadName()
	local sha = D.pLabel
	if not sha then
		return
	end
	local r, g, b = unpack(O.tNameColor)
	sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	sha:ClearTriangleFanPoint()
	for k, v in pairs(D.tDoodad) do
		if not v.loot then
			local tar = GetDoodad(k)
			if not tar or (v.quest and not tar.HaveQuest(GetClientPlayer().dwID)) then
				D.Remove(k)
			else
				local szName = tar.szName
				if tar.dwTemplateID == 3713 or tar.dwTemplateID == 3714 then
					szName = Table_GetNpcTemplateName(1622)
				end
				local nR, nG, nB = r, g, b
				if v.other then
					nR = nR * 0.85
					nG = nG * 0.85
					nB = nB * 0.85
				end
				sha:AppendDoodadID(tar.dwID, nR, nG, nB, 255, 128, 40, szName, 0, 1)
			end
		end
	end
	sha:Show()
end

-- auto interact
function D.OnAutoDoodad()
	local me = GetClientPlayer()
	-- auto interact
	if not me or me.GetOTActionState() ~= 0
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
		-- or IsDialoguePanelOpened()
	then
		return
	end
	for k, v in pairs(D.tDoodad) do
		local doodad, bIntr, bOpen = GetDoodad(k), false, false
		if not doodad then
			D.Remove(k)
		elseif doodad.CanDialog(me) then -- 若存在却不能对话只简单保留
			if v.loot then -- 尸体只摸一次
				bOpen = (not me.bFightState or O.bOpenLootEvenFight) and doodad.CanLoot(me.dwID)
				if bOpen then
					D.dwOpenID = k
				end
			elseif v.craft or doodad.HaveQuest(me.dwID) then -- 任务和普通道具尝试 5 次
				bIntr = (not me.bFightState or O.bInteractEvenFight) and not me.bOnHorse and IsAutoInteract()
				-- 宴席只能吃队友的
				if doodad.dwOwnerID ~= 0 and IsPlayer(doodad.dwOwnerID) and not LIB.IsParty(doodad.dwOwnerID) then
					bIntr = false
				end
			elseif v.recent then -- 最近采集的
				bIntr = true
				-- 从最近采集移除、意味着如果玩家打断这次采集就不会自动继续采集
				D.tRecent[doodad.dwTemplateID] = nil
				for dwID, _ in pairs(D.tDoodad) do
					local d = GetDoodad(dwID)
					if d and d.dwTemplateID == doodad.dwTemplateID then
						D.TryAdd(dwID, true)
						D.tDoodad[dwID] = nil
					end
				end
				D.bUpdateLabel = true
			end
		end
		if bOpen then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto open [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			LIB.BreatheCall('AutoDoodad', 500)
			return LIB.OpenDoodad(me, doodad)
		end
		if bIntr then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto interact [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			LIB.BreatheCall('AutoDoodad', 500)
			return LIB.InteractDoodad(k)
		end
	end
end

function D.CloseLootWindow()
	local me = GetClientPlayer()
	if me and me.GetSkillOTActionState() == CHARACTER_OTACTION_TYPE.ACTION_PICKING then
		me.OnCloseLootWindow()
	end
end

-- open doodad (loot)
function D.OnOpenDoodad(dwID)
	-- 摸尸体且开了插件拾取框 可以安全的起身
	if D.tDoodad[dwID] and D.tDoodad[dwID].loot and MY_GKP_Loot.IsEnabled() then
		LIB.DelayCall('MY_GKPDoodad__OnOpenDoodad', 150, D.CloseLootWindow)
	end
	D.Remove(dwID) -- 从列表删除
	local doodad = GetDoodad(dwID)
	if doodad then
		if D.IsCustomDoodad(doodad) then --庖丁
			D.tDoodad[dwID] = { craft = true }
			D.bUpdateLabel = true
		elseif D.IsRecentDoodad(doodad) then
			D.tDoodad[dwID] = { recent = true }
			D.bUpdateLabel = true
		end
	end
	LIB.Debug(_L['MY_GKPDoodad'], 'OnOpenDoodad [' .. (doodad and doodad.szName or dwID) .. ']', DEBUG_LEVEL.LOG)
end

-- save manual doodad
function D.OnLootDoodad()
	if not O.bRecent then
		return
	end
	local doodad = GetDoodad(arg0)
	if not doodad then
		return
	end
	local t = GetDoodadTemplate(doodad.dwTemplateID)
	if t.dwCraftID == CONSTANT.CRAFT_TYPE.MINING
	or t.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM
	or t.dwCraftID == CONSTANT.CRAFT_TYPE.SKINNING then
		D.tRecent[doodad.dwTemplateID] = true -- 加入最近采集列表
		for _, d in ipairs(LIB.GetNearDoodad()) do
			if d.dwTemplateID == doodad.dwTemplateID then
				D.TryAdd(d.dwID)
			end
		end
		D.bUpdateLabel = true
	end
end

-- mini flag
function D.OnUpdateMiniFlag()
	if not O.bMiniFlag or IsShielded() then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	for k, v in pairs(D.tDoodad) do
		if not v.loot then
			local tar = GetDoodad(k)
			if not tar or (v.quest and not tar.HaveQuest(me.dwID)) then
				D.Remove(k)
			else
				local dwType, nF1, nF2 = 5, 169, 48
				local tpl = GetDoodadTemplate(tar.dwTemplateID)
				if v.quest then
					nF1 = 114
				elseif tpl.dwCraftID == CONSTANT.CRAFT_TYPE.MINING then	-- 采金类
					nF1, nF2 = 16, 47
				elseif tpl.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM then	-- 神农类
					nF1 = 2
				end
				LIB.UpdateMiniFlag(dwType, tar, nF1, nF2)
			end
		end
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
LIB.RegisterEvent('LOADING_ENDING', D.CheckShowName)
LIB.RegisterEvent('DOODAD_ENTER_SCENE', function() D.TryAdd(arg0, true) end)
LIB.RegisterEvent('DOODAD_LEAVE_SCENE', function() D.Remove(arg0) end)
LIB.RegisterEvent('OPEN_DOODAD', D.OnLootDoodad)
LIB.RegisterEvent('HELP_EVENT', function()
	if arg0 == 'OnOpenpanel' and arg1 == 'LOOT' and O.bOpenLoot then
		local dwOpenID =  D.GetOpenDoodadID()
		if dwOpenID then
			D.OnOpenDoodad(dwOpenID)
		end
	end
end)
LIB.RegisterEvent('QUEST_ACCEPTED', function()
	if O.bQuestDoodad then
		D.RescanNearby()
	end
end)
LIB.BreatheCall('AutoDoodad', D.OnAutoDoodad)
LIB.BreatheCall('UpdateMiniFlag', D.OnUpdateMiniFlag, 500)


-------------------------------------
-- 设置界面
-------------------------------------
local PS = {}

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 10, 10
	local nX, nY = X, Y
	local nLineHeightS, nLineHeightM, nLineHeightL = 22, 28, 32

	-- loot
	ui:Append('Text', { text = _L['Pickup helper'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, Y + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable MY_GKP_Loot'],
		checked = MY_GKP_Loot.bOn,
		oncheck = function(bChecked)
			MY_GKP_Loot.bOn = bChecked
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Team dungeon'],
		checked = MY_GKP_Loot.bOnlyInTeamDungeon,
		oncheck = function(bChecked)
			MY_GKP_Loot.bOnlyInTeamDungeon = bChecked
		end,
		tip = _L['Only enable in checked map (uncheck all for all map)'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Raid dungeon'],
		checked = MY_GKP_Loot.bOnlyInRaidDungeon,
		oncheck = function(bChecked)
			MY_GKP_Loot.bOnlyInRaidDungeon = bChecked
		end,
		tip = _L['Only enable in checked map (uncheck all for all map)'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Battlefield'],
		checked = MY_GKP_Loot.bOnlyInBattlefield,
		oncheck = function(bChecked)
			MY_GKP_Loot.bOnlyInBattlefield = bChecked
		end,
		tip = _L['Only enable in checked map (uncheck all for all map)'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable auto pickup'],
		checked = MY_GKPDoodad.bOpenLoot,
		oncheck = function(bChecked)
			MY_GKPDoodad.bOpenLoot = bChecked
			ui:Fetch('Check_Fight'):Enable(bChecked)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		name = 'Check_Fight', x = nX, y = nY,
		text = _L['Pickup in fight'],
		checked = MY_GKPDoodad.bOpenLootEvenFight,
		enable = MY_GKPDoodad.bOpenLoot,
		oncheck = function(bChecked)
			MY_GKPDoodad.bOpenLootEvenFight = bChecked
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show 2nd kungfu fit icon'],
		checked = MY_GKP.bShow2ndKungfuLoot,
		oncheck = function()
			MY_GKP.bShow2ndKungfuLoot = not MY_GKP.bShow2ndKungfuLoot
			FireUIEvent('MY_GKP_LOOT_RELOAD')
		end,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Width() + 10

	nX, nY = X + 10, nY + nLineHeightM
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Confirm when distribute'],
		lmenu = function()
			local t = {}
			insert(t, { szOption = _L['Category'], bDisable = true })
			for _, szKey in ipairs({
				'Huangbaba',
				'Book',
				'Pendant',
				'Outlook',
				'Pet',
				'Horse',
				'HorseEquip',
			}) do
				insert(t, {
					szOption = _L[szKey],
					bCheck = true,
					bChecked = MY_GKP_Loot.tConfirm[szKey],
					fnAction = function()
						MY_GKP_Loot.tConfirm[szKey] = not MY_GKP_Loot.tConfirm[szKey]
					end,
				})
			end
			insert(t, CONSTANT.MENU_DIVIDER)
			insert(t, { szOption = _L['Quality'], bDisable = true })
			for i, s in ipairs({
				[1] = g_tStrings.STR_WHITE,
				[2] = g_tStrings.STR_ROLLQUALITY_GREEN,
				[3] = g_tStrings.STR_ROLLQUALITY_BLUE,
				[4] = g_tStrings.STR_ROLLQUALITY_PURPLE,
				[5] = g_tStrings.STR_ROLLQUALITY_NACARAT,
			}) do
				insert(t, {
					szOption = _L('Reach %s', s),
					rgb = i == -1 and {255, 255, 255} or { GetItemFontColorByQuality(i) },
					bCheck = true, bMCheck = true,
					bChecked = i == MY_GKP_Loot.nConfirmQuality,
					fnAction = function()
						MY_GKP_Loot.nConfirmQuality = i
					end,
				})
			end
			return t
		end,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Loot item filter'],
		menu = MY_GKP_Loot.GetFilterMenu,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Auto pickup'],
		menu = MY_GKP_Loot.GetAutoPickupMenu,
		autoenable = function() return MY_GKP_Loot.bOn end,
	}):AutoWidth():Width() + 5

	-- doodad
	nX, nY = X, nY + nLineHeightL
	ui:Append('Text', { text = _L['Craft assit'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show the head name'],
		checked = MY_GKPDoodad.bShowName,
		oncheck = function()
			MY_GKPDoodad.bShowName = not MY_GKPDoodad.bShowName
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')

	nX = ui:Append('Shadow', {
		name = 'Shadow_Color', x = nX + 2, y = nY + 4, w = 18, h = 18,
		color = MY_GKPDoodad.tNameColor,
		onclick = function()
			UI.OpenColorPicker(function(r, g, b)
				ui:Fetch('Shadow_Color'):Color(r, g, b)
				MY_GKPDoodad.tNameColor = { r, g, b }
			end)
		end,
		autoenable = function() return MY_GKPDoodad.bShowName end,
	}):Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		text = _L['Display minimap flag'],
		x = nX, y = nY,
		checked = MY_GKPDoodad.bMiniFlag,
		oncheck = function(bChecked)
			MY_GKPDoodad.bMiniFlag = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	if not LIB.IsShieldedVersion('MY_GKPDoodad') then
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Auto craft'],
			checked = MY_GKPDoodad.bInteract,
			oncheck = function(bChecked)
				MY_GKPDoodad.bInteract = bChecked
				ui:Fetch('Check_Interact_Fight'):Enable(bChecked)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		nX = ui:Append('WndCheckBox', {
			name = 'Check_Interact_Fight', x = nX, y = nY,
			text = _L['Interact in fight'],
			checked = MY_GKPDoodad.bInteractEvenFight,
			enable = MY_GKPDoodad.bInteract,
			oncheck = function(bChecked)
				MY_GKPDoodad.bInteractEvenFight = bChecked
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	end

	-- craft
	nX, nY = X + 10, nY + nLineHeightM
	for _, v in ipairs(D.tCraft) do
		if v == 0 then
			nY = nY + 8
			if nX ~= 10 then
				nY = nY + nLineHeightS
				nX = X + 10
			end
		else
			ui:Append('WndCheckBox', {
				x = nX, y = nY,
				text = GetDoodadTemplateName(v),
				checked = MY_GKPDoodad.tCraft[v],
				oncheck = function(bChecked)
					if bChecked then
						MY_GKPDoodad.tCraft[v] = true
					else
						MY_GKPDoodad.tCraft[v] = nil
					end
					D.RescanNearby()
				end,
				autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
			})
			nX = nX + 90
			if nX > 500 then
				nX = X + 10
				nY = nY + nLineHeightS
			end
		end
	end
	if nX == X + 10 then
		nY = nY - nLineHeightS + nLineHeightM
	else
		nY = nY + nLineHeightM
	end

	nX = X + 10
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Quest items'],
		checked = MY_GKPDoodad.bQuestDoodad,
		oncheck = function(bChecked)
			MY_GKPDoodad.bQuestDoodad = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Recent items'],
		checked = MY_GKPDoodad.bRecent,
		oncheck = function(bChecked)
			MY_GKPDoodad.bRecent = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['All other'],
		checked = MY_GKPDoodad.bAllDoodad,
		oncheck = function(bChecked)
			MY_GKPDoodad.bAllDoodad = bChecked
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	-- custom
	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		text = _L['Customs (split by | )'],
		x = nX, y = nY,
		checked = MY_GKPDoodad.bCustom,
		oncheck = function(bChecked)
			MY_GKPDoodad.bCustom = bChecked
			ui:Fetch('Edit_Custom'):Enable(bChecked)
		end,
		autoenable = function() return MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5

	ui:Append('WndEditBox', {
		name = 'Edit_Custom',
		x = nX, y = nY, w = 360, h = 27,
		limit = 1024, text = MY_GKPDoodad.szCustom,
		enable = MY_GKPDoodad.bCustom,
		onchange = function(szText)
			MY_GKPDoodad.szCustom = szText
		end,
		tip = function()
			if LIB.IsShieldedVersion('MY_GKPDoodad') then
				return
			end
			return _L['Tip: Enter the name of dead animals can be automatically Paoding!']
		end,
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return (MY_GKPDoodad.bShowName or MY_GKPDoodad.bInteract) and MY_GKPDoodad.bCustom end,
	})
end
LIB.RegisterPanel('MY_GKPDoodad', _L['GKP Doodad helper'], _L['General'], 90, PS)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent',
		},
		{
			fields = {
				bOpenLoot = true,
				bOpenLootEvenFight = true,
				bShowName = true,
				tNameColor = true,
				bMiniFlag = true,
				bInteract = true,
				bInteractEvenFight = true,
				tCraft = true,
				bQuestDoodad = true,
				bAllDoodad = true,
				bCustom = true,
				szCustom = true,
				bRecent = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bOpenLoot = true,
				bOpenLootEvenFight = true,
				bShowName = true,
				tNameColor = true,
				bMiniFlag = true,
				bInteract = true,
				bInteractEvenFight = true,
				tCraft = true,
				bQuestDoodad = true,
				bAllDoodad = true,
				bCustom = true,
				szCustom = true,
				bRecent = true,
			},
			triggers = {
				bOpenLoot = D.RescanNearby,
				bOpenLootEvenFight = D.RescanNearby,
				bShowName = D.CheckShowName,
				tNameColor = D.RescanNearby,
				bMiniFlag = D.RescanNearby,
				bInteract = D.RescanNearby,
				bInteractEvenFight = D.RescanNearby,
				tCraft = D.RescanNearby,
				bQuestDoodad = D.RescanNearby,
				bAllDoodad = D.RescanNearby,
				bCustom = D.RescanNearby,
				szCustom = D.ReloadCustom,
				bRecent = D.RescanNearby,
			},
			root = O,
		},
	},
}
MY_GKPDoodad = LIB.GeneGlobalNS(settings)
end
