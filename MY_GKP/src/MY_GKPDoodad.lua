--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : Doodad 物品采集拾取助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKPDoodad'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKPDoodad'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_GKPDoodad.HeadName', { ['*'] = false })
X.RegisterRestriction('MY_GKPDoodad.AutoInteract', { ['*'] = true, intl = false })
X.RegisterRestriction('MY_GKPDoodad.MapRestriction', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_GKPDoodad', _L['General'], {
	bOpenLoot = { -- 自动打开掉落
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Enable auto pickup'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOpenLootEvenFight = { -- 战斗中也打开
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Pickup in fight'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowName = { -- 显示物品名称
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Show the head name'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tNameColor = { -- 头顶名称颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Head name color'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 196, 64, 255 },
	},
	nNameFont = { -- 头顶名称字体
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Head name font'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 40,
	},
	fNameScale = { -- 头顶名称缩放
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Head name font scale'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	bMiniFlag = { -- 显示小地图标记
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Display minimap flag'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bInteract = { -- 自动采集
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto craft'],
		}),
		szRestriction = 'MY_GKPDoodad.MapRestriction',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bInteractEvenFight = { -- 战斗中也采集
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Interact in fight'],
		}),
		szRestriction = 'MY_GKPDoodad.MapRestriction',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tCraft = { -- 草药、矿石列表
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Craft list'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Boolean),
		xDefaultValue = {},
	},
	bMiningDoodad = { -- 采金物品
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Mining doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bHerbalismDoodad = { -- 神农物品
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Herbalism doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSkinningDoodad = { -- 庖丁物品
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Skinning doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bQuestDoodad = { -- 任务物品
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Quest doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bReadInscriptionDoodad = { -- 已读碑铭
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Read inscription doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bUnreadInscriptionDoodad = { -- 未读碑铭
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Unread inscription doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOtherDoodad = { -- 其它物品
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Other doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAllDoodad = { -- 全部
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['All doodad'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bCustom = { -- 启用自定义
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Customs (split by | )'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	szCustom = { -- 自定义列表
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Custom list'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	bRecent = { -- 启用自动最近5分钟采集
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Recent doodad'],
		}),
		xSchema = X.Schema.Boolean,
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
local INI_SHADOW = X.PACKET_INFO.UI_COMPONENT_ROOT .. 'Shadow.ini'
local DOODAD_TYPE_VISIBLE = {
	[X.CONSTANT.DOODAD_KIND.INVALID     ] = false,
	[X.CONSTANT.DOODAD_KIND.NORMAL      ] = false, -- 普通的Doodad,有Tip,不能操作
	[X.CONSTANT.DOODAD_KIND.CORPSE      ] = true , -- 尸体
	[X.CONSTANT.DOODAD_KIND.QUEST       ] = true , -- 任务相关的Doodad
	[X.CONSTANT.DOODAD_KIND.READ        ] = true , -- 可以看的Doodad
	[X.CONSTANT.DOODAD_KIND.DIALOG      ] = true , -- 可以对话的Doodad
	[X.CONSTANT.DOODAD_KIND.ACCEPT_QUEST] = true , -- 可以接任务的Doodad,本质上上面3个类型是一样的,只是图标不同而已
	[X.CONSTANT.DOODAD_KIND.TREASURE    ] = true , -- 宝箱
	[X.CONSTANT.DOODAD_KIND.ORNAMENT    ] = false, -- 装饰物,不能操作
	[X.CONSTANT.DOODAD_KIND.CRAFT_TARGET] = true , -- 生活技能的采集物
	[X.CONSTANT.DOODAD_KIND.CLIENT_ONLY ] = false, -- 客户端用
	[X.CONSTANT.DOODAD_KIND.CHAIR       ] = true , -- 可以坐的Doodad
	[X.CONSTANT.DOODAD_KIND.GUIDE       ] = false, -- 路标
	[X.CONSTANT.DOODAD_KIND.DOOR        ] = false, -- 门之类有动态障碍的Doodad
	[X.CONSTANT.DOODAD_KIND.NPCDROP     ] = false, -- 使用NPC掉落模式的doodad
	[X.CONSTANT.DOODAD_KIND.SPRINT      ] = false, -- 轻功落脚点
}

local function GetDoodadTemplateName(dwID)
	local doodad = GetDoodadTemplate(dwID)
	if not doodad then
		return
	end
	return doodad.szName
end

local function IsShowNameDisabled()
	if X.IsRestricted('MY_GKPDoodad.HeadName') then
		return true
	end
	if X.IsInShieldedMap() and X.IsRestricted('MY_GKPDoodad.MapRestriction') then
		return true
	end
	return false
end

local function IsAutoInteractDisabled()
	return not O.bInteract or IsShiftKeyDown() or Station.Lookup('Normal/MY_GKPLoot') or X.IsRestricted('MY_GKPDoodad.AutoInteract')
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
	tLooted = {}, -- 已经拾取过的 doodad id 不再二次拾取
	dwUpdateMiniFlagTime = 0, -- 下次更新小地图位置时间戳
	dwAutoInteractDoodadTime = 0, -- 下次自动交互物件时间戳
}
for _, v in ipairs(D.aCraft) do
	D.tCraft[v] = true
end

function D.IsCustomDoodad(doodad)
	if O.bCustom and D.tCustom[doodad.szName] then
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			local tpl = GetDoodadTemplate(doodad.dwTemplateID)
			return tpl and tpl.dwCraftID == X.CONSTANT.CRAFT_TYPE.SKINNING
		end
		return true
	end
	return false
end

function D.IsRecentDoodad(doodad)
	if O.bRecent and D.tRecent[doodad.dwTemplateID] then
		if doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP then
			local tpl = GetDoodadTemplate(doodad.dwTemplateID)
			return tpl and tpl.dwCraftID == X.CONSTANT.CRAFT_TYPE.SKINNING
		end
		return true
	end
	return false
end

function D.GetDoodadInfo(dwID)
	local doodad = X.GetDoodad(dwID)
	if not doodad then
		return
	end
	local me = X.GetClientPlayer()
	local tpl = GetDoodadTemplate(doodad.dwTemplateID)
	local info = {}
	if tpl then
		info.dwCraftID = tpl.dwCraftID
	end
	local eOverwriteAction = (D.tLooted[doodad.dwID] == false or doodad.CanLoot(me.dwID)) and 'loot' or nil
	-- 跳过非拾取类尸体之类交互物件
	if tpl and DOODAD_TYPE_VISIBLE[tpl.nKind] == false and eOverwriteAction ~= 'loot' then
		return
	end
	-- 神农、采金
	if D.tCraft[doodad.dwTemplateID] then
		info.eDoodadType = 'craft'
		info.eActionType = eOverwriteAction or 'craft'
		return info
	end
	-- 战场任务
	if doodad.dwTemplateID == 3713 -- 遗体
	or doodad.dwTemplateID == 3714 -- 遗体
	or doodad.dwTemplateID == 4733 -- 恶人谷菌箱
	or doodad.dwTemplateID == 4734 -- 浩气盟菌箱
	then
		info.eDoodadType = 'quest'
		info.eActionType = eOverwriteAction or 'craft'
		return info
	end
	-- 通用任务
	if doodad.HaveQuest(me.dwID) then
		info.eDoodadType = 'quest'
		info.eActionType = 'quest'
		return info
	end
	-- 采金
	if info.dwCraftID == X.CONSTANT.CRAFT_TYPE.MINING then
		info.eDoodadType = 'mining'
		info.eActionType = eOverwriteAction or 'craft'
		return info
	end
	-- 神农
	if info.dwCraftID == X.CONSTANT.CRAFT_TYPE.HERBALISM then
		info.eDoodadType = 'herbalism'
		info.eActionType = eOverwriteAction or 'craft'
		return info
	end
	-- 庖丁
	if info.dwCraftID == X.CONSTANT.CRAFT_TYPE.SKINNING then
		info.eDoodadType = 'skinning'
		info.eActionType = eOverwriteAction or 'craft'
		return info
	end
	-- 碑铭
	local dwRecipeID = X.GetDoodadBookRecipeID(doodad.dwTemplateID), false
	if dwRecipeID then
		local dwBookID, dwSegmentID = X.RecipeToSegmentID(dwRecipeID)
		if dwBookID and dwSegmentID then
			info.eDoodadType = 'inscription'
			info.eActionType = 'other'
			info.bMemorized = me.IsBookMemorized(dwBookID, dwSegmentID)
			return info
		end
	end
	-- 尸体
	if (doodad.nKind == DOODAD_KIND.CORPSE or doodad.nKind == DOODAD_KIND.NPCDROP) and (not doodad.CanDialog(me) or doodad.CanLoot(me.dwID)) then
		if eOverwriteAction == 'loot' then
			info.eDoodadType = 'loot'
			info.eActionType = 'loot'
			return info
		end
		return
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
		return X.DelayCall('MY_GKPDoodad__DelayTryAdd' .. dwID, 500, function() D.TryAdd(dwID) end)
	end
	local info = D.GetDoodadInfo(dwID)
	if info then
		local doodad = X.GetDoodad(dwID)
		info.bCustom = D.IsCustomDoodad(doodad)
		info.bRecent = D.IsRecentDoodad(doodad)
		if info.eDoodadType == 'craft' and O.tCraft[doodad.dwTemplateID] then
			info.eRuleType = 'craft'
		elseif info.eDoodadType == 'quest' and O.bQuestDoodad then
			info.eRuleType = 'quest'
		elseif info.eDoodadType == 'mining' and O.bMiningDoodad then
			info.eRuleType = 'mining'
		elseif info.eDoodadType == 'herbalism' and O.bHerbalismDoodad then
			info.eRuleType = 'herbalism'
		elseif info.eDoodadType == 'skinning' and O.bSkinningDoodad then
			info.eRuleType = 'skinning'
		elseif info.eActionType == 'loot' and O.bOpenLoot and not D.tLooted[doodad.dwID] then
			info.eRuleType = 'loot'
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
		elseif info.bCustom then
			info.eRuleType = 'custom'
		elseif info.bRecent then
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
function D.RescanNearby(dwTemplateID)
	if dwTemplateID then
		for _, d in ipairs(X.GetNearDoodad()) do
			if d.dwTemplateID == dwTemplateID then
				D.Remove(d.dwID)
				D.TryAdd(d.dwID)
				D.bUpdateLabel = true
			end
		end
	else
		D.tDoodad = {}
		for _, k in ipairs(X.GetNearDoodadID()) do
			D.TryAdd(k)
		end
		D.bUpdateLabel = true
	end
end

function D.ReloadCustom()
	local t = {}
	local szText = StringReplaceW(O.szCustom, _L['|'], '|')
	for _, v in ipairs(X.SplitString(szText, '|')) do
		v = X.TrimString(v)
		if v ~= '' then
			t[v] = true
		end
	end
	D.tCustom = t
	D.tRecent = {}
	D.RescanNearby()
end

-- 开始采集时调用，用于预判断最近采集列表
function D.OnPickPrepare(doodad, nFinishLFC)
	if nFinishLFC - GetLogicFrameCount() <= 0 then
		return
	end
	local t = GetDoodadTemplate(doodad.dwTemplateID)
	if t.dwCraftID == X.CONSTANT.CRAFT_TYPE.MINING
	or t.dwCraftID == X.CONSTANT.CRAFT_TYPE.HERBALISM
	or t.dwCraftID == X.CONSTANT.CRAFT_TYPE.SKINNING then
		D.nPickPrepareFinishLFC = nFinishLFC
		D.dwPickPrepareDoodadID = doodad.dwID
		D.dwPickPrepareDoodadTemplateID = doodad.dwTemplateID
		D.tRecent[doodad.dwTemplateID] = true
		D.RescanNearby(doodad.dwTemplateID)
	end
end

-- 结束采集时调用，如果符合最后一次采集物品信息，加入最近采集列表
function D.OnPickPrepareStop(doodad)
	local dwTemplateID = D.dwPickPrepareDoodadTemplateID
	if dwTemplateID then
		local bSuccess = doodad
			and doodad.dwID == D.dwPickPrepareDoodadID
			and math.abs(GetLogicFrameCount() - D.nPickPrepareFinishLFC) < X.ENVIRONMENT.GAME_FPS / 2
		D.nPickPrepareFinishLFC = nil
		D.dwPickPrepareDoodadID = nil
		D.dwPickPrepareDoodadTemplateID = nil
		D.tRecent[dwTemplateID] = bSuccess and true or nil
		D.RescanNearby(dwTemplateID)
	end
end

X.RegisterInit('MY_GKPDoodad', function()
	for _, k in ipairs({'tNameColor', 'tCraft', 'szCustom'}) do
		if O2[k] then
			X.SafeCall(X.Set, O, k, O2[k])
			O2[k] = nil
		end
	end
	-- 粮草堆，散落的镖银，阵营首领战利品、押运奖赏
	if X.IsEmpty(O.szCustom) then
		local t = {}
		for _, v in ipairs({ 3874, 4255, 4315, 5622, 5732 }) do
			local szName = GetDoodadTemplateName(v)
			if szName then
				table.insert(t, szName)
			end
		end
		O.szCustom = table.concat(t, '|')
		D.ReloadCustom()
	end
end)

-- switch name
function D.CheckShowName()
	local hName = X.UI.GetShadowHandle('MY_GKPDoodad')
	local bShowName = O.bShowName and not IsShowNameDisabled()
	if bShowName and not D.pLabel then
		D.pLabel = hName:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Name')
		X.BreatheCall('MY_GKPDoodad__HeadName', function()
			if D.bUpdateLabel then
				D.bUpdateLabel = false
				D.UpdateHeadName()
			end
		end)
		D.bUpdateLabel = true
	elseif not bShowName and D.pLabel then
		hName:Clear()
		D.pLabel = nil
		X.BreatheCall('MY_GKPDoodad__HeadName', false)
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
		local tar = X.GetDoodad(dwID)
		local bShow = info.eRuleType ~= 'loot' or info.bCustom or info.bRecent
		if bShow or D.bDebug then
			local szName = X.GetDoodadName(dwID, { eShowID = 'never' }) or ''
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
			--[[#DEBUG BEGIN]]
			if D.bDebug then
				szName = szName .. '|D' .. info.eDoodadType .. '|R' .. info.eRuleType .. '|A' .. info.eActionType .. '|' .. dwID .. '|' .. (bShow and 'Y' or 'N')
			end
			--[[#DEBUG END]]
			sha:AppendDoodadID(tar.dwID, nR, nG, nB, nA, fYDelta, O.nNameFont, szName, 0, O.fNameScale)
		end
	end
	sha:Show()
end

-- auto interact
function D.AutoInteractDoodad()
	local me = X.GetClientPlayer()
	-- auto interact
	if not me or X.GetCharacterOTActionState(me) ~= X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_IDLE
		or (me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_FLOAT)
		-- or IsDialoguePanelOpened()
	then
		return
	end
	local bAllowAutoIntr = (not me.bFightState or O.bInteractEvenFight) and not me.bOnHorse and not IsAutoInteractDisabled()
	for dwID, info in pairs(D.tDoodad) do
		local doodad, bIntr, bOpen = X.GetDoodad(dwID), false, false
		if doodad and doodad.CanDialog(me) then -- 若存在却不能对话只简单保留
			local bAllowAutoOpen = not D.tLooted[doodad.dwID]
			if info.bCustom then
				if info.eActionType == 'loot' then
					bOpen = bAllowAutoOpen
				else
					bIntr = bAllowAutoIntr
				end
			elseif info.bRecent then
				bIntr = bAllowAutoIntr
			elseif info.eActionType == 'loot' and O.bOpenLoot then -- 掉落是否可以打开
				bOpen = bAllowAutoOpen and (not me.bFightState or O.bOpenLootEvenFight) and doodad.CanLoot(me.dwID)
			elseif (info.eRuleType == 'craft' and info.eActionType == 'craft')
				or (info.eRuleType == 'mining' and info.eActionType == 'craft')
				or (info.eRuleType == 'herbalism' and info.eActionType == 'craft')
				or (info.eRuleType == 'skinning' and info.eActionType == 'craft')
			then
				bIntr = bAllowAutoIntr
			elseif (info.eRuleType == 'quest' and info.eActionType == 'quest')
				or (info.eRuleType ~= 'other' and info.eRuleType ~= 'all' and info.eActionType == 'craft')
			then -- 任务和普通道具尝试 5 次
				bIntr = bAllowAutoIntr
				-- 宴席只能吃队友的
				if doodad.dwOwnerID ~= 0 and X.IsPlayer(doodad.dwOwnerID) and not X.IsTeammate(doodad.dwOwnerID) then
					bIntr = false
				end
				if bIntr then
					if info.nActionCount and info.nActionCount >= 5 then
						info.eActionType = 'other'
						bIntr = false
						D.bUpdateLabel = true
					else
						info.nActionCount = (info.nActionCount or 0) + 1
					end
				end
			end
		end
		if bOpen and doodad.CanLoot(me.dwID) then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_GKPDoodad'], 'Auto open [' .. doodad.szName .. '].', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			D.dwOpenDoodadID = dwID
			D.bUpdateLabel = true
			D.dwAutoInteractDoodadTime = GetTime() + 500
			-- 掉落只摸一次
			D.tLooted[doodad.dwID] = true
			return X.OpenDoodad(me, doodad)
		end
		if bIntr and not doodad.CanLoot(me.dwID) then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_GKPDoodad'], 'Auto interact [' .. doodad.szName .. '].', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			D.dwAutoInteractDoodadTime = GetTime() + 500
			return X.InteractDoodad(dwID)
		end
	end
end

function D.CloseLootWindow()
	local me = X.GetClientPlayer()
	if me and X.GetCharacterOTActionState(me) == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_PICKING then
		me.OnCloseLootWindow()
	end
end

-- open doodad (loot)
function D.OnOpenDoodad(dwID)
	local doodad = X.GetDoodad(dwID)
	local info = D.tDoodad[dwID]
	if info then
		-- 摸掉落且开了插件拾取框 可以安全的起身
		if info.eActionType == 'loot' and MY_GKPLoot.IsEnabled() then
			X.DelayCall('MY_GKPDoodad__OnOpenDoodad_1',  150, D.CloseLootWindow)
			X.DelayCall('MY_GKPDoodad__OnOpenDoodad_2',  300, D.CloseLootWindow)
			X.DelayCall('MY_GKPDoodad__OnOpenDoodad_3', 1000, D.CloseLootWindow)
		end
		-- 从列表删除
		D.Remove(dwID)
	end
	-- 如果来源非自动打开掉落、或者是自定义物品、或最近采集物品，需要继续加入该物品
	if doodad and (info.eRuleType ~= 'loot' or D.IsCustomDoodad(doodad) or D.IsRecentDoodad(doodad)) then
		D.TryAdd(dwID)
	end
	X.OutputDebugMessage(_L['MY_GKPDoodad'], 'OnOpenDoodad [' .. X.GetDoodadName(dwID, { eShowID = 'always' }) .. ']', X.DEBUG_LEVEL.LOG)
end

-- save manual doodad
function D.OnLootDoodad()
	if not O.bRecent then
		return
	end
	local doodad = X.GetDoodad(arg0)
	if not doodad then
		return
	end
	D.OnPickPrepareStop(doodad)
end

-- mini flag
function D.UpdateMiniFlag()
	if not D.bReady or not O.bMiniFlag or IsShowNameDisabled() then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	for dwID, info in pairs(D.tDoodad) do
		if info.eRuleType ~= 'loot' and info.eActionType ~= 'loot' then
		-- if info.eRuleType == 'quest'
		-- 	or info.eRuleType == 'craft' or info.eRuleType == 'mining'
		-- 	or info.eRuleType == 'herbalism' or info.eRuleType == 'skinning'
		-- then
			local doodad = X.GetDoodad(dwID)
			local dwType, nF1, nF2 = 5, 169, 48
			if info.eRuleType == 'quest' then
				nF1 = 114
			elseif info.dwCraftID == X.CONSTANT.CRAFT_TYPE.MINING then -- 采金类
				nF1, nF2 = 16, 47
			elseif info.dwCraftID == X.CONSTANT.CRAFT_TYPE.HERBALISM then -- 神农类
				nF1 = 2
			end
			X.UpdateMinimapArrowPoint(dwType, doodad, nF1, nF2)
		end
	end
end

function D.OnBreatheCall()
	local me = X.GetClientPlayer()
	if not me or not D.bReady then
		return
	end
	for dwID, info in pairs(D.tDoodad) do
		local doodad = X.GetDoodad(dwID)
		if not doodad
			or (info.eRuleType == 'quest' and info.eActionType == 'quest' and not doodad.HaveQuest(me.dwID))
			or (info.eActionType == 'loot' and not doodad.CanLoot(me.dwID))
		then
			D.Remove(dwID)
			D.TryAdd(dwID)
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

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
MY_GKPDoodad = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------
X.RegisterEvent('LOADING_ENDING', function()
	D.tLooted = {}
	D.CheckShowName()
end)
X.RegisterEvent('DOODAD_ENTER_SCENE', function()
	if not D.bReady then
		return
	end
	D.TryAdd(arg0, true)
end)
X.RegisterEvent('DOODAD_LEAVE_SCENE', function()
	if not D.bReady then
		return
	end
	D.Remove(arg0)
end)
X.RegisterEvent('OPEN_DOODAD', D.OnLootDoodad)
X.RegisterEvent('HELP_EVENT', function()
	if arg0 == 'OnOpenpanel' and arg1 == 'LOOT' and O.bOpenLoot then
		local dwOpenDoodadID =  D.dwOpenDoodadID
		if dwOpenDoodadID then
			D.dwOpenDoodadID = nil
			D.OnOpenDoodad(dwOpenDoodadID)
		end
	end
end)
X.RegisterEvent('QUEST_ACCEPTED', function()
	if D.bReady and O.bQuestDoodad then
		D.RescanNearby()
	end
end)
X.RegisterEvent('SYS_MSG', function()
	if arg0 == 'UI_OME_CRAFT_RESPOND' and arg1 == CRAFT_RESULT_CODE.SUCCESS
	and D.bReady and (O.bReadInscriptionDoodad or O.bUnreadInscriptionDoodad) then
		D.RescanNearby()
	end
end)
X.RegisterEvent('DO_PICK_PREPARE_PROGRESS', function()
    local nTotalFrame, dwDoodadID = arg0, arg1
	if nTotalFrame == 0 then
		return
	end
	local doodad = X.GetDoodad(dwDoodadID)
	if doodad then
		D.OnPickPrepare(doodad, GetLogicFrameCount() + nTotalFrame)
	end
end)
X.RegisterEvent('OT_ACTION_PROGRESS_BREAK', function()
    local dwID = arg0
	if dwID == X.GetClientPlayerID() then
		D.OnPickPrepareStop(false)
	end
end)
X.RegisterEvent('SYNC_LOOT_LIST', function()
	D.tLooted[arg0] = false
	D.TryAdd(arg0)
end)
X.RegisterInit('MY_GKPDoodad__BC', function()
	X.BreatheCall('MY_GKPDoodad', D.OnBreatheCall)
end)
X.RegisterExit('MY_GKPDoodad__BC', function()
	X.BreatheCall('MY_GKPDoodad', false)
end)
X.RegisterEvent('MY_RESTRICTION', function()
	D.CheckShowName()
end)
X.RegisterUserSettingsInit('MY_GKPDoodad', function()
	for _, dwID in ipairs(D.aCraft) do
		if dwID ~= 0 then
			if not X.IsBoolean(O.tCraft[dwID]) then
				O.tCraft[dwID] = true
			end
		end
	end
	D.RescanNearby()
	D.bReady = true
end)
X.RegisterUserSettingsRelease('MY_GKPDoodad', function()
	D.bReady = false
end)

--------------------------------------------------------------------------------
-- 界面注册
--------------------------------------------------------------------------------
local PS = { nPriority = 2.1 }

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nW, nH = ui:Size()
	local nPaddingX, nPaddingY = 40, 10
	local nX, nY, nLFY = nPaddingX, nPaddingY, nPaddingY
	local nLineHeightS, nLineHeightM, nLineHeightL = 22, 28, 32

	-- loot
	ui:Append('Text', { text = _L['Pickup helper'], x = nX, y = nY, font = 27 })

	nX, nY = nPaddingX + 10, nPaddingY + nLineHeightM
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable auto pickup'],
		checked = O.bOpenLoot,
		onCheck = function(bChecked)
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
		onCheck = function(bChecked)
			O.bOpenLootEvenFight = bChecked
			D.RescanNearby()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10

	nX, nY = nPaddingX + 10, nY + nLineHeightM
	nLFY = nY

	nX, nY, nLFY = MY_GKPLoot.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLineHeightM, nX, nY, nLFY)

	-- doodad
	if not X.IsRestricted('MY_GKPDoodad.HeadName') then
		nX, nY = nPaddingX, nY + nLineHeightL
		ui:Append('Text', { text = _L['Craft assit'], x = nX, y = nY, font = 27 })

		nX, nY = nPaddingX + 10, nY + nLineHeightM
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Show the head name'],
			checked = O.bShowName,
			onCheck = function()
				O.bShowName = not O.bShowName
				D.CheckShowName()
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5

		nX = ui:Append('Shadow', {
			name = 'Shadow_Color', x = nX + 2, y = nY + 4, w = 18, h = 18,
			color = O.tNameColor,
			onClick = function()
				X.UI.OpenColorPicker(function(r, g, b)
					ui:Fetch('Shadow_Color'):Color(r, g, b)
					O.tNameColor = { r, g, b }
					D.RescanNearby()
				end)
			end,
			autoEnable = function() return O.bShowName end,
		}):Pos('BOTTOMRIGHT') + 5

		nX = nX + ui:Append('WndButton', {
			x = nX, y = nY, w = 65, h = 24,
			buttonStyle = 'FLAT',
			text = _L['Font'],
			onClick = function()
				X.UI.OpenFontPicker(function(nFont)
					O.nNameFont = nFont
					D.bUpdateLabel = true
				end)
			end,
			autoEnable = function() return O.bShowName end,
		}):Width() + 5

		nX = nX + ui:Append('WndSlider', {
			x = nX, y = nY, w = 150,
			textFormatter = function(val) return _L('Font scale is %d%%.', val) end,
			range = {10, 500},
			sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
			value = O.fNameScale * 100,
			onChange = function(val)
				O.fNameScale = val / 100
				D.bUpdateLabel = true
			end,
			autoEnable = function() return O.bShowName end,
		}):Width() + 5

		nX, nY = nPaddingX + 10, nY + nLineHeightM
		nX = ui:Append('WndCheckBox', {
			text = _L['Display minimap flag'],
			x = nX, y = nY,
			checked = O.bMiniFlag,
			onCheck = function(bChecked)
				O.bMiniFlag = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		if not X.IsRestricted('MY_GKPDoodad.AutoInteract') then
			nX = ui:Append('WndCheckBox', {
				x = nX, y = nY,
				text = _L['Auto craft'],
				checked = O.bInteract,
				onCheck = function(bChecked)
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
				onCheck = function(bChecked)
					O.bInteractEvenFight = bChecked
					D.RescanNearby()
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 10
		end

		--[[#DEBUG BEGIN]]
		if X.IsDebugClient() then
			nX = ui:Append('WndCheckBox', {
				x = nX, y = nY,
				text = _L['Debug'],
				checked = D.bDebug,
				onCheck = function(bChecked)
					D.bDebug = bChecked
					D.bUpdateLabel = true
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 10
		end
		--[[#DEBUG END]]

		-- craft
		nX, nY = nPaddingX + 10, nY + nLineHeightM
		for _, v in ipairs(D.aCraft) do
			if v == 0 then
				nY = nY + 8
				if nX ~= 10 then
					nY = nY + nLineHeightS
					nX = nPaddingX + 10
				end
			else
				local szName = GetDoodadTemplateName(v)
				if szName then
					if nX + 90 > nW - (nPaddingX + 10) then
						nX = nPaddingX + 10
						nY = nY + nLineHeightS
					end
					ui:Append('WndCheckBox', {
						x = nX, y = nY,
						text = szName,
						checked = O.tCraft[v],
						onCheck = function(bChecked)
							if bChecked then
								O.tCraft[v] = true
							else
								O.tCraft[v] = false
							end
							O.tCraft = O.tCraft
							D.RescanNearby()
						end,
						autoEnable = function() return O.bShowName or O.bInteract end,
					})
					nX = nX + 90
				end
			end
		end
		nX = nPaddingX
		nY = nY + nLineHeightM

		nX = nPaddingX + 10
		nY = nY + 3
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Mining doodad'],
			checked = O.bMiningDoodad,
			onCheck = function(bChecked)
				O.bMiningDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Herbalism doodad'],
			checked = O.bHerbalismDoodad,
			onCheck = function(bChecked)
				O.bHerbalismDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Skinning doodad'],
			checked = O.bSkinningDoodad,
			onCheck = function(bChecked)
				O.bSkinningDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Quest doodad'],
			checked = O.bQuestDoodad,
			onCheck = function(bChecked)
				O.bQuestDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Read inscription doodad'],
			checked = O.bReadInscriptionDoodad,
			onCheck = function(bChecked)
				O.bReadInscriptionDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Unread inscription doodad'],
			checked = O.bUnreadInscriptionDoodad,
			onCheck = function(bChecked)
				O.bUnreadInscriptionDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Other doodad'],
			checked = O.bOtherDoodad,
			onCheck = function(bChecked)
				O.bOtherDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 7

		-- recent / all
		nX, nY = nPaddingX + 10, nY + nLineHeightM
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Recent doodad'],
			checked = O.bRecent,
			onCheck = function(bChecked)
				O.bRecent = bChecked
				D.RescanNearby()
			end,
			tip = {
				render = _L['Recent crafted doodads during current game'],
				position = X.UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['All doodad'],
			checked = O.bAllDoodad,
			onCheck = function(bChecked)
				O.bAllDoodad = bChecked
				D.RescanNearby()
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10

		-- custom
		nX, nY = nPaddingX + 10, nY + nLineHeightM
		nX = ui:Append('WndCheckBox', {
			text = _L['Customs (split by | )'],
			x = nX, y = nY,
			checked = O.bCustom,
			onCheck = function(bChecked)
				O.bCustom = bChecked
				D.RescanNearby()
				ui:Fetch('Edit_Custom'):Enable(bChecked)
			end,
			autoEnable = function() return O.bShowName or O.bInteract end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5

		ui:Append('WndEditBox', {
			name = 'Edit_Custom',
			x = nX, y = nY, w = 360, h = 27,
			limit = 1024, text = O.szCustom,
			enable = O.bCustom,
			onChange = function(szText)
				O.szCustom = szText
				D.ReloadCustom()
			end,
			tip = {
				render = function()
					if X.IsRestricted('MY_GKPDoodad.AutoInteract') then
						return
					end
					return _L['Tip: Enter the name of dead animals can be automatically Paoding!']
				end,
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			autoEnable = function() return (O.bShowName or O.bInteract) and O.bCustom end,
		})
	end
end
X.Panel.Register(_L['General'], 'MY_GKPDoodad', _L['MY_GKPLoot'], 90, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
