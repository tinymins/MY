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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKPDoodad'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_GKPDoodad', _L['General'], {
	bOpenLoot = { -- 自动打开掉落
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bOpenLootEvenFight = { -- 战斗中也打开
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowName = { -- 显示物品名称
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tNameColor = { -- 头顶名称颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 196, 64, 255 },
	},
	nNameFont = { -- 头顶名称字体
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Number,
		xDefaultValue = 40,
	},
	fNameScale = { -- 头顶名称缩放
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	bMiniFlag = { -- 显示小地图标记
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bInteract = { -- 自动采集
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bInteractEvenFight = { -- 战斗中也采集
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tCraft = { -- 草药、矿石列表
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Map(Schema.Number, Schema.Boolean),
		xDefaultValue = {},
	},
	bQuestDoodad = { -- 任务物品
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bCorpseDoodad = { -- 掉落物品
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bReadInscriptionDoodad = { -- 已读碑铭
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bUnreadInscriptionDoodad = { -- 未读碑铭
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bOtherDoodad = { -- 其它物品
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAllDoodad = { -- 全部
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bCustom = { -- 启用自定义
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	szCustom = { -- 自定义列表
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.String,
		xDefaultValue = '',
	},
	bRecent = { -- 启用自动最近5分钟采集
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
})
local O2 = {}
RegisterCustomData('MY_GKPDoodad.tNameColor')
RegisterCustomData('MY_GKPDoodad.tCraft')
RegisterCustomData('MY_GKPDoodad.szCustom')

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local INI_SHADOW = PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini'

local function GetDoodadTemplateName(dwID)
	local doodad = GetDoodadTemplate(dwID)
	if not doodad then
		return
	end
	return doodad.szName
end

local function IsShowNameDisabled()
	return LIB.IsInShieldedMap() and LIB.IsShieldedVersion('TARGET')
end

local function IsAutoInteractDisabled()
	return not O.bInteract or IsShiftKeyDown() or Station.Lookup('Normal/MY_GKPLoot') or LIB.IsShieldedVersion('MY_GKPDoodad')
end

local D = {
	-- 草药、矿石列表
	aCraft = {
		1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009,
		1010, 1011, 1012, 1015, 1016, 1017, 1018, 1019, 2641,
		2642, 2643, 3321, 3358, 3359, 3360, 3361, 4227, 4228,
		5659, 5660,
		0, -- switch
		1020, 1021, 1022, 1023, 1024, 1025, 1027, 2644, 2645,
		4229, 4230, 5661, 5662,
	},
	tCraft = {},
	tCustom = {}, -- 自定义列表
	tRecent = {}, -- 最近采集的东西、自动继续采集
	tDoodad = {}, -- 待处理的 doodad 列表
	nToLoot = 0,  -- 待拾取处理数量（用于修复判断）
	dwUpdateMiniFlagTime = 0, -- 下次更新小地图位置时间戳
	dwAutoInteractDoodadTime = 0, -- 下次自动交互物件时间戳
}
for _, v in ipairs(D.aCraft) do
	D.tCraft[v] = true
end

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

function D.GetDoodadInfo(dwID)
	local doodad = GetDoodad(dwID)
	if not doodad then
		return
	end
	local me = GetClientPlayer()
	local tpl = GetDoodadTemplate(doodad.dwTemplateID)
	local info = {
		dwCraftID = tpl.dwCraftID,
	}
	-- 神农、采金
	if D.tCraft[doodad.dwTemplateID] then
		info.eDoodadType = 'craft'
		info.eActionType = 'craft'
		return info
	end
	-- 战场任务
	if doodad.dwTemplateID == 3713 -- 遗体
	or doodad.dwTemplateID == 3714 -- 遗体
	or doodad.dwTemplateID == 4733 -- 恶人谷菌箱
	or doodad.dwTemplateID == 4734 -- 浩气盟菌箱
	then
		info.eDoodadType = 'quest'
		info.eActionType = 'craft'
		return info
	end
	-- 通用任务
	if doodad.HaveQuest(me.dwID) then
		info.eDoodadType = 'quest'
		info.eActionType = 'quest'
		return info
	end
	-- 掉落
	if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
		info.eDoodadType = 'corpse'
		if doodad.CanLoot(me.dwID) then
			info.eActionType = 'loot'
		else
			info.eActionType = 'craft'
		end
		return info
	end
	-- 碑铭
	local dwRecipeID = LIB.GetDoodadBookRecipeID(doodad.dwTemplateID), false
	if dwRecipeID then
		local dwBookID, dwSegmentID = LIB.RecipeToSegmentID(dwRecipeID)
		if dwBookID and dwSegmentID then
			info.eDoodadType = 'inscription'
			info.eActionType = 'other'
			info.bMemorized = me.IsBookMemorized(dwBookID, dwSegmentID)
			return info
		end
	end
	-- 其他
	if CanSelectDoodad(doodad.dwID) then
		info.eDoodadType = 'other'
		info.eActionType = 'other'
		return info
	end
end

-- try to add
function D.TryAdd(dwID, bDelay)
	if bDelay then
		return LIB.DelayCall('MY_GKPDoodad__DelayTryAdd' .. dwID, 500, function() D.TryAdd(dwID) end)
	end
	local info = D.GetDoodadInfo(dwID)
	if info then
		local doodad = GetDoodad(dwID)
		if info.eDoodadType == 'craft' and O.tCraft[doodad.dwTemplateID] then
			info.eRuleType = 'craft'
		elseif info.eDoodadType == 'quest' and O.bQuestDoodad then
			info.eRuleType = 'quest'
		elseif info.eDoodadType == 'corpse' and info.eActionType == 'loot' and O.bOpenLoot then
			info.eRuleType = 'loot'
		elseif info.eDoodadType == 'corpse' and O.bCorpseDoodad then
			info.eRuleType = 'corpse'
		elseif info.eDoodadType == 'inscription' and info.bMemorized and O.bReadInscriptionDoodad then
			if O.bUnreadInscriptionDoodad then
				info.bMemorizedLabel = true
			end
			info.eRuleType = 'inscription'
		elseif info.eDoodadType == 'inscription' and not info.bMemorized and O.bUnreadInscriptionDoodad then
			if O.bReadInscriptionDoodad then
				info.bMemorizedLabel = true
			end
			info.eRuleType = 'inscription'
		elseif info.eDoodadType == 'other' and O.bOtherDoodad then
			info.eRuleType = 'other'
		elseif D.IsCustomDoodad(doodad) then
			info.eRuleType = 'custom'
		elseif D.IsRecentDoodad(doodad) then
			info.eRuleType = 'recent'
		elseif O.bAllDoodad then
			info.eRuleType = 'all'
		else
			info = nil
		end
		if info then
			D.tDoodad[dwID] = info
			D.bUpdateLabel = true
		end
	end
end

-- remove doodad
function D.Remove(dwID)
	local info = D.tDoodad[dwID]
	if info then
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
	for _, k in ipairs({'tNameColor', 'tCraft', 'szCustom'}) do
		if O2[k] then
			SafeCall(Set, O, k, O2[k])
			O2[k] = nil
		end
	end
	-- 粮草堆，散落的镖银，阵营首领战利品、押运奖赏
	if IsEmpty(O.szCustom) then
		local t = {}
		for _, v in ipairs({ 3874, 4255, 4315, 5622, 5732 }) do
			local szName = GetDoodadTemplateName(v)
			if szName then
				insert(t, szName)
			end
		end
		O.szCustom = concat(t, '|')
		D.ReloadCustom()
	end
end)

-- switch name
function D.CheckShowName()
	local hName = UI.GetShadowHandle('MY_GKPDoodad')
	local bShowName = O.bShowName and not IsShowNameDisabled()
	if bShowName and not D.pLabel then
		D.pLabel = hName:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Name')
		LIB.BreatheCall('MY_GKPDoodad__HeadName', function()
			if D.bUpdateLabel then
				D.bUpdateLabel = false
				D.UpdateHeadName()
			end
		end)
		D.bUpdateLabel = true
	elseif not bShowName and D.pLabel then
		hName:Clear()
		D.pLabel = nil
		LIB.BreatheCall('MY_GKPDoodad__HeadName', false)
	end
end

-------------------------------------
-- 事件处理
-------------------------------------
-- head name
function D.UpdateHeadName()
	local sha = D.pLabel
	if not sha then
		return
	end
	local r, g, b = unpack(O.tNameColor)
	sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	sha:ClearTriangleFanPoint()
	for dwID, info in pairs(D.tDoodad) do
		local tar = GetDoodad(dwID)
		if info.eActionType ~= 'loot' then
			local szName = LIB.GetObjectName(TARGET.DOODAD, dwID, 'never') or ''
			local fYDelta = 128
			local nR, nG, nB, nA, bDarken = r, g, b, 255, false
			-- 将不可自动交互的颜色变暗
			if info.eActionType == 'other' then
				bDarken = true
			end
			if info.eDoodadType == 'inscription' then
				if info.bMemorized then
					if info.bMemorizedLabel then
						szName = szName .. _L['(Read)']
					end
					bDarken = true
				else
					if info.bMemorizedLabel then
						szName = szName .. _L['(Not read)']
					end
					bDarken = false
				end
				fYDelta = 300
			end
			if bDarken then
				nR = nR * 0.85
				nG = nG * 0.85
				nB = nB * 0.85
			end
			sha:AppendDoodadID(tar.dwID, nR, nG, nB, nA, fYDelta, O.nNameFont, szName, 0, O.fNameScale)
		end
	end
	sha:Show()
end

-- auto interact
function D.AutoInteractDoodad()
	local me = GetClientPlayer()
	-- auto interact
	if not me or LIB.GetOTActionState(me) ~= CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_IDLE
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
		-- or IsDialoguePanelOpened()
	then
		return
	end
	local bAllowAutoIntr = not IsAutoInteractDisabled()
	for dwID, info in pairs(D.tDoodad) do
		local doodad, bIntr, bOpen = GetDoodad(dwID), false, false
		if doodad and doodad.CanDialog(me) then -- 若存在却不能对话只简单保留
			if info.eActionType == 'loot' then -- 掉落是否可以打开
				bOpen = (not me.bFightState or O.bOpenLootEvenFight) and doodad.CanLoot(me.dwID)
			elseif info.eRuleType == 'custom' then
				if info.eActionType == 'loot' then
					bOpen = true
				else
					bIntr = bAllowAutoIntr
				end
			elseif (info.eRuleType == 'quest' and info.eActionType == 'quest')
				or (info.eRuleType ~= 'other' and info.eRuleType ~= 'all' and info.eActionType == 'craft')
			then -- 任务和普通道具尝试 5 次
				bIntr = (not me.bFightState or O.bInteractEvenFight) and not me.bOnHorse and bAllowAutoIntr
				-- 宴席只能吃队友的
				if doodad.dwOwnerID ~= 0 and IsPlayer(doodad.dwOwnerID) and not LIB.IsParty(doodad.dwOwnerID) then
					bIntr = false
				end
				if bIntr then
					if info.nActionCount >= 5 then
						info.eActionType = 'other'
						bIntr = false
						D.bUpdateLabel = true
					else
						info.nActionCount = (info.nActionCount or 0) + 1
					end
				end
			elseif info.eRuleType == 'recent' then -- 最近采集的
				bIntr = bAllowAutoIntr
				-- 如果自动采集，就先从最近采集移除，意味着如果玩家打断这次采集就不会自动继续采集
				if bIntr then
					D.tRecent[doodad.dwTemplateID] = nil
					for k, _ in pairs(D.tDoodad) do
						local d = GetDoodad(k)
						if d and d.dwTemplateID == doodad.dwTemplateID then
							D.TryAdd(k, true)
							D.tDoodad[k] = nil
						end
					end
					D.bUpdateLabel = true
				end
			end
		end
		if bOpen then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto open [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- 掉落只摸一次
			info.eActionType = 'other'
			D.dwOpenDoodadID = dwID
			D.bUpdateLabel = true
			D.dwAutoInteractDoodadTime = GetTime() + 500
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto open [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return LIB.OpenDoodad(me, doodad)
		end
		if bIntr then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_GKPDoodad'], 'Auto interact [' .. doodad.szName .. '].', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			D.dwAutoInteractDoodadTime = GetTime() + 500
			return LIB.InteractDoodad(dwID)
		end
	end
end

function D.CloseLootWindow()
	local me = GetClientPlayer()
	if me and LIB.GetOTActionState(me) == CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_PICKING then
		me.OnCloseLootWindow()
	end
end

-- open doodad (loot)
function D.OnOpenDoodad(dwID)
	local doodad = GetDoodad(dwID)
	local info = D.tDoodad[dwID]
	if info then
		-- 摸掉落且开了插件拾取框 可以安全的起身
		if info.eActionType == 'loot' and MY_GKPLoot.IsEnabled() then
			LIB.DelayCall('MY_GKPDoodad__OnOpenDoodad', 150, D.CloseLootWindow)
		end
		-- 从列表删除
		D.Remove(dwID)
	end
	-- 如果是自定义物品、或最近采集物品，需要继续加入该物品
	if doodad and (D.IsCustomDoodad(doodad) or D.IsRecentDoodad(doodad)) then
		D.TryAdd(dwID)
	end
	LIB.Debug(_L['MY_GKPDoodad'], 'OnOpenDoodad [' .. LIB.GetObjectName(TARGET.DOODAD, dwID, 'always') .. ']', DEBUG_LEVEL.LOG)
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
function D.UpdateMiniFlag()
	if not D.bReady or not O.bMiniFlag or IsShowNameDisabled() then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	for dwID, info in pairs(D.tDoodad) do
		if info.eActionType ~= 'loot' then
			local doodad = GetDoodad(dwID)
			local dwType, nF1, nF2 = 5, 169, 48
			if info.eRuleType == 'quest' then
				nF1 = 114
			elseif info.dwCraftID == CONSTANT.CRAFT_TYPE.MINING then -- 采金类
				nF1, nF2 = 16, 47
			elseif info.dwCraftID == CONSTANT.CRAFT_TYPE.HERBALISM then -- 神农类
				nF1 = 2
			end
			LIB.UpdateMiniFlag(dwType, doodad, nF1, nF2)
		end
	end
end

function D.OnBreatheCall()
	local me = GetClientPlayer()
	if not me then
		return
	end
	for dwID, info in pairs(D.tDoodad) do
		local doodad = GetDoodad(dwID)
		if not doodad
			or (info.eRuleType == 'quest' and info.eActionType == 'quest' and not doodad.HaveQuest(me.dwID))
		then
			D.Remove(dwID)
		end
	end
	local dwTime = GetTime()
	if dwTime >= D.dwAutoInteractDoodadTime then
		D.AutoInteractDoodad()
	end
	if dwTime >= D.dwUpdateMiniFlagTime then
		D.UpdateMiniFlag()
		D.dwUpdateMiniFlagTime = dwTime + 500
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
		local dwOpenDoodadID =  D.dwOpenDoodadID
		if dwOpenDoodadID then
			D.dwOpenDoodadID = nil
			D.OnOpenDoodad(dwOpenDoodadID)
		end
	end
end)
LIB.RegisterEvent('QUEST_ACCEPTED', function()
	if D.bReady and O.bQuestDoodad then
		D.RescanNearby()
	end
end)
LIB.RegisterEvent('SYS_MSG', function()
	if arg0 == 'UI_OME_CRAFT_RESPOND' and arg1 == CRAFT_RESULT_CODE.SUCCESS
	and D.bReady and (O.bReadInscriptionDoodad or O.bUnreadInscriptionDoodad) then
		D.RescanNearby()
	end
end)
LIB.RegisterInit('MY_GKPDoodad__BC', function()
	LIB.BreatheCall('MY_GKPDoodad', D.OnBreatheCall)
end)
LIB.RegisterExit('MY_GKPDoodad__BC', function()
	LIB.BreatheCall('MY_GKPDoodad', false)
end)
LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_GKPDoodad', function()
	D.bReady = true
end)
LIB.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_GKPDoodad', function()
	D.bReady = false
end)


-------------------------------------
-- 设置界面
-------------------------------------
local PS = { nPriority = 2.1 }

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local W, H = ui:Size()
	local X, Y = 40, 10
	local nX, nY, nLFY = X, Y, Y
	local nLineHeightS, nLineHeightM, nLineHeightL = 22, 28, 32

	-- loot
	ui:Append('Text', { text = _L['Pickup helper'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, Y + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable auto pickup'],
		checked = O.bOpenLoot,
		oncheck = function(bChecked)
			O.bOpenLoot = bChecked
			D.RescanNearby()
			ui:Fetch('Check_Fight'):Enable(bChecked)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		name = 'Check_Fight', x = nX, y = nY,
		text = _L['Pickup in fight'],
		checked = O.bOpenLootEvenFight,
		enable = O.bOpenLoot,
		oncheck = function(bChecked)
			O.bOpenLootEvenFight = bChecked
			D.RescanNearby()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX, nY = X + 10, nY + nLineHeightM
	nLFY = nY

	nX, nY, nLFY = MY_GKPLoot.OnPanelActivePartial(ui, X, Y, W, H, nLineHeightM, nX, nY, nLFY)

	-- doodad
	nX, nY = X, nY + nLineHeightL
	ui:Append('Text', { text = _L['Craft assit'], x = nX, y = nY, font = 27 })

	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show the head name'],
		checked = O.bShowName,
		oncheck = function()
			O.bShowName = not O.bShowName
			D.CheckShowName()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5

	nX = ui:Append('Shadow', {
		name = 'Shadow_Color', x = nX + 2, y = nY + 4, w = 18, h = 18,
		color = O.tNameColor,
		onclick = function()
			UI.OpenColorPicker(function(r, g, b)
				ui:Fetch('Shadow_Color'):Color(r, g, b)
				O.tNameColor = { r, g, b }
				D.RescanNearby()
			end)
		end,
		autoenable = function() return O.bShowName end,
	}):Pos('BOTTOMRIGHT') + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 65,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				O.nNameFont = nFont
				D.bUpdateLabel = true
			end)
		end,
		autoenable = function() return O.bShowName end,
	}):Width() + 5

	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, w = 150,
		textfmt = function(val) return _L('Font scale is %d%%.', val) end,
		range = {10, 500},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.fNameScale * 100,
		onchange = function(val)
			O.fNameScale = val / 100
			D.bUpdateLabel = true
		end,
		autoenable = function() return O.bShowName end,
	}):Width() + 5

	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		text = _L['Display minimap flag'],
		x = nX, y = nY,
		checked = O.bMiniFlag,
		oncheck = function(bChecked)
			O.bMiniFlag = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	if not LIB.IsShieldedVersion('MY_GKPDoodad') then
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Auto craft'],
			checked = O.bInteract,
			oncheck = function(bChecked)
				O.bInteract = bChecked
				D.RescanNearby()
				ui:Fetch('Check_Interact_Fight'):Enable(bChecked)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		nX = ui:Append('WndCheckBox', {
			name = 'Check_Interact_Fight', x = nX, y = nY,
			text = _L['Interact in fight'],
			checked = O.bInteractEvenFight,
			enable = O.bInteract,
			oncheck = function(bChecked)
				O.bInteractEvenFight = bChecked
				D.RescanNearby()
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	end

	-- craft
	nX, nY = X + 10, nY + nLineHeightM
	for _, v in ipairs(D.aCraft) do
		if v == 0 then
			nY = nY + 8
			if nX ~= 10 then
				nY = nY + nLineHeightS
				nX = X + 10
			end
		else
			local szName = GetDoodadTemplateName(v)
			if szName then
				if nX + 90 > W - (X + 10) then
					nX = X + 10
					nY = nY + nLineHeightS
				end
				ui:Append('WndCheckBox', {
					x = nX, y = nY,
					text = szName,
					checked = O.tCraft[v],
					oncheck = function(bChecked)
						if bChecked then
							O.tCraft[v] = true
						else
							O.tCraft[v] = nil
						end
						O.tCraft = O.tCraft
						D.RescanNearby()
					end,
					autoenable = function() return O.bShowName or O.bInteract end,
				})
				nX = nX + 90
			end
		end
	end
	nX = X
	nY = nY + nLineHeightM

	nX = X + 10
	nY = nY + 3
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Quest doodad'],
		checked = O.bQuestDoodad,
		oncheck = function(bChecked)
			O.bQuestDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Corpse doodad'],
		checked = O.bCorpseDoodad,
		oncheck = function(bChecked)
			O.bCorpseDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Read inscription doodad'],
		checked = O.bReadInscriptionDoodad,
		oncheck = function(bChecked)
			O.bReadInscriptionDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Unread inscription doodad'],
		checked = O.bUnreadInscriptionDoodad,
		oncheck = function(bChecked)
			O.bUnreadInscriptionDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Other doodad'],
		checked = O.bOtherDoodad,
		oncheck = function(bChecked)
			O.bOtherDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	-- recent / all
	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Recent doodad'],
		checked = O.bRecent,
		oncheck = function(bChecked)
			O.bRecent = bChecked
			D.RescanNearby()
		end,
		tip = _L['Recent crafted doodads during current game'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['All doodad'],
		checked = O.bAllDoodad,
		oncheck = function(bChecked)
			O.bAllDoodad = bChecked
			D.RescanNearby()
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	-- custom
	nX, nY = X + 10, nY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		text = _L['Customs (split by | )'],
		x = nX, y = nY,
		checked = O.bCustom,
		oncheck = function(bChecked)
			O.bCustom = bChecked
			D.RescanNearby()
			ui:Fetch('Edit_Custom'):Enable(bChecked)
		end,
		autoenable = function() return O.bShowName or O.bInteract end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5

	ui:Append('WndEditBox', {
		name = 'Edit_Custom',
		x = nX, y = nY, w = 360, h = 27,
		limit = 1024, text = O.szCustom,
		enable = O.bCustom,
		onchange = function(szText)
			O.szCustom = szText
			D.ReloadCustom()
		end,
		tip = function()
			if LIB.IsShieldedVersion('MY_GKPDoodad') then
				return
			end
			return _L['Tip: Enter the name of dead animals can be automatically Paoding!']
		end,
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		autoenable = function() return (O.bShowName or O.bInteract) and O.bCustom end,
	})
end
LIB.RegisterPanel(_L['General'], 'MY_GKPDoodad', _L['MY_GKPLoot'], 90, PS)

-- Global exports
do
local settings = {
	name = 'MY_GKPDoodad',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'tNameColor',
				'tCraft',
				'szCustom',
			},
			root = O2,
		},
	},
}
MY_GKPDoodad = LIB.CreateModule(settings)
end
