--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.PeekPlayer')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local function PeekPlayer(dwID)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'EquipScore Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	if PeekOtherPlayerEquipSimpleInfo then
		X.SafeCall(PeekOtherPlayerEquipSimpleInfo, dwID)
	else
		X.SafeCall(ViewInviteToPlayer, dwID, true)
	end
end
local EVENT_KEY = nil
local PEEK_PLAYER_EQUIP_SCORE_STATE = {}
local PEEK_PLAYER_EQUIP_SCORE_RESULT = {}
local PEEK_PLAYER_EQUIP_SCORE_CALLBACK = {}
local function OnGetPlayerEquipScorePeekPlayer(dwID)
	if not PEEK_PLAYER_EQUIP_SCORE_CALLBACK[dwID] then
		return
	end
	local nScore = PEEK_PLAYER_EQUIP_SCORE_RESULT[dwID]
	for _, fnAction in ipairs(PEEK_PLAYER_EQUIP_SCORE_CALLBACK[dwID]) do
		X.SafeCall(fnAction, nScore, dwID)
	end
	PEEK_PLAYER_EQUIP_SCORE_CALLBACK[dwID] = nil
end
X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	PEEK_PLAYER_EQUIP_SCORE_STATE[arg0] = nil
end)

-- 获取玩家装备分数
-- X.GetPlayerEquipScore(dwID, fnAction)
-- X.GetPlayerEquipScore(dwID, bForcePeek, fnAction)
-- @param dwID 玩家ID
-- @param bForcePeek 是否强制拉取
-- @param fnAction 回调函数
function X.GetPlayerEquipScore(dwID, bForcePeek, fnAction)
	-- 函数重载
	if X.IsFunction(bForcePeek) then
		fnAction, bForcePeek = bForcePeek, nil
	end
	-- 加入回调
	if not PEEK_PLAYER_EQUIP_SCORE_CALLBACK[dwID] then
		PEEK_PLAYER_EQUIP_SCORE_CALLBACK[dwID] = {}
	end
	table.insert(PEEK_PLAYER_EQUIP_SCORE_CALLBACK[dwID], fnAction)
	-- 自身判定
	if dwID == X.GetClientPlayerID() then
		PEEK_PLAYER_EQUIP_SCORE_RESULT[dwID] = X.GetClientPlayer().GetTotalEquipScore()
		OnGetPlayerEquipScorePeekPlayer(dwID)
		return
	end
	-- 缓存判定
	if PEEK_PLAYER_EQUIP_SCORE_STATE[dwID] == 'SUCCESS' and not bForcePeek then
		OnGetPlayerEquipScorePeekPlayer(dwID)
		return
	end
	-- 防抖限制
	if PEEK_PLAYER_EQUIP_SCORE_STATE[dwID] == 'PENDING' and not bForcePeek then
		return
	end
	-- 发送请求
	PEEK_PLAYER_EQUIP_SCORE_STATE[dwID] = 'PENDING'
	if not EVENT_KEY then
		if PeekOtherPlayerEquipSimpleInfo then
			EVENT_KEY = X.RegisterEvent('ON_SYNC_OTHER_PLAYER_EQUIP_SIMPLE_INFO', X.NSFormatString('{$NS}#GetPlayerEquipScore'), function()
				local dwID, nEquipScore = arg0, arg1
				PEEK_PLAYER_EQUIP_SCORE_STATE[dwID] = 'SUCCESS'
				PEEK_PLAYER_EQUIP_SCORE_RESULT[dwID] = nEquipScore
				OnGetPlayerEquipScorePeekPlayer(dwID)
			end)
		else
			EVENT_KEY = X.RegisterEvent('PEEK_OTHER_PLAYER', X.NSFormatString('{$NS}#GetPlayerEquipScore'), function()
				local nResult, dwID = arg0, arg1
				local player = X.GetPlayer(dwID)
				if nResult == PEEK_OTHER_PLAYER_RESPOND.SUCCESS and player then
					PEEK_PLAYER_EQUIP_SCORE_STATE[dwID] = 'SUCCESS'
					PEEK_PLAYER_EQUIP_SCORE_RESULT[dwID] = player.GetTotalEquipScore()
					OnGetPlayerEquipScorePeekPlayer(dwID)
				end
			end)
		end
	end
	PeekPlayer(dwID)
end
end

do
local function PeekPlayer(dwID)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'EquipInfo Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	if PeekOtherPlayer then
		X.SafeCall(PeekOtherPlayer, dwID)
	else
		X.SafeCall(ViewInviteToPlayer, dwID, true)
	end
end
local EVENT_KEY = nil
local PEEK_PLAYER_EQUIP_STATE = {}
local PEEK_PLAYER_EQUIP_CALLBACK = {}
local function OnGetPlayerEquipInfoPeekPlayer(player)
	if not PEEK_PLAYER_EQUIP_CALLBACK[player.dwID] then
		return
	end
	local tEquipInfo = {}
	for nItemIndex = 0, EQUIPMENT_INVENTORY.TOTAL - 1 do
		local item = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nItemIndex)
		if item then
			-- 五行石
			local aSlotItem = {}
			for i = 1, item.GetSlotCount() do
				local nEnchantID = X.GetItemMountDiamondEnchantID(item, i - 1, player)
				if nEnchantID and nEnchantID > 0 then
					local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(nEnchantID)
					if dwTabType and dwTabIndex then
						aSlotItem[i] = {dwTabType, dwTabIndex}
					end
				end
			end
			-- 五彩石
			local nEnchantID = X.GetItemMountFEAEnchantID(item)
			if nEnchantID and nEnchantID ~= 0 then
				local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
				if dwTabType and dwTabIndex then
					aSlotItem[0] = {dwTabType, dwTabIndex}
				end
			end
			-- 插入结果集
			tEquipInfo[nItemIndex] = {
				dwTabType = item.dwTabType,
				dwTabIndex = item.dwIndex,
				nStrengthLevel = X.GetItemStrengthLevel(item, player),
				aSlotItem = aSlotItem,
				dwPermanentEnchantID = item.dwPermanentEnchantID,
				dwTemporaryEnchantID = item.dwTemporaryEnchantID,
				dwTemporaryEnchantLeftSeconds = item.GetTemporaryEnchantLeftSeconds(),
			}
		end
	end
	if X.IsEmpty(tEquipInfo) and PEEK_PLAYER_EQUIP_STATE[player.dwID] ~= 'SUCCESS' then
		PeekPlayer(player.dwID)
		return
	end
	for _, fnAction in ipairs(PEEK_PLAYER_EQUIP_CALLBACK[player.dwID]) do
		X.SafeCall(fnAction, tEquipInfo, player.dwID)
	end
	PEEK_PLAYER_EQUIP_CALLBACK[player.dwID] = nil
end
X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	PEEK_PLAYER_EQUIP_STATE[arg0] = nil
end)

-- 获取玩家装备信息
-- X.GetPlayerEquipInfo(dwID, fnAction)
-- X.GetPlayerEquipInfo(dwID, bForcePeek, fnAction)
-- @param dwID 玩家ID
-- @param bForcePeek 是否强制拉取
-- @param fnAction 回调函数
function X.GetPlayerEquipInfo(dwID, bForcePeek, fnAction)
	-- 函数重载
	if X.IsFunction(bForcePeek) then
		fnAction, bForcePeek = bForcePeek, nil
	end
	-- 加入回调
	if not PEEK_PLAYER_EQUIP_CALLBACK[dwID] then
		PEEK_PLAYER_EQUIP_CALLBACK[dwID] = {}
	end
	table.insert(PEEK_PLAYER_EQUIP_CALLBACK[dwID], fnAction)
	-- 自身判定
	if dwID == X.GetClientPlayerID() then
		OnGetPlayerEquipInfoPeekPlayer(X.GetClientPlayer())
		return
	end
	-- 缓存判定
	local player = X.GetPlayer(dwID)
	if player and PEEK_PLAYER_EQUIP_STATE[dwID] == 'SUCCESS' and not bForcePeek then
		OnGetPlayerEquipInfoPeekPlayer(player)
		return
	end
	-- 防抖限制
	if PEEK_PLAYER_EQUIP_STATE[dwID] == 'PENDING' and not bForcePeek then
		return
	end
	-- 发送请求
	PEEK_PLAYER_EQUIP_STATE[dwID] = 'PENDING'
	if not EVENT_KEY then
		EVENT_KEY = X.RegisterEvent('PEEK_OTHER_PLAYER', X.NSFormatString('{$NS}#GetPlayerEquipInfo'), function()
			local nResult, dwID = arg0, arg1
			local player = X.GetPlayer(dwID)
			if nResult == PEEK_OTHER_PLAYER_RESPOND.SUCCESS and player then
				PEEK_PLAYER_EQUIP_STATE[dwID] = 'SUCCESS'
				OnGetPlayerEquipInfoPeekPlayer(player)
			else
				PEEK_PLAYER_EQUIP_STATE[dwID] = 'FAILURE'
			end
		end)
	end
	PeekPlayer(dwID)
end
end

do
local function PeekPlayer(dwID)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'TalentInfo Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	if X.IS_CLASSIC then
		X.SafeCall(PeekOtherPlayerTalent, dwID)
	else
		X.SafeCall(PeekOtherPlayerTalent, dwID, 0xffffffff)
	end
end
local EVENT_KEY = nil
local PEEK_PLAYER_TALENT_STATE = {}
local PEEK_PLAYER_TALENT_TIME = {}
local PEEK_PLAYER_TALENT_CALLBACK = {}
local function OnGetPlayerTalentInfoPeekPlayer(player)
	if not PEEK_PLAYER_TALENT_CALLBACK[player.dwID] then
		return
	end
	local aInfo = player.GetTalentInfo()
	if not aInfo then
		PEEK_PLAYER_TALENT_STATE[player.dwID] = nil
		return
	end
	local aTalent = {}
	for i, info in ipairs(aInfo) do
		local skill = info.SkillArray[info.nSelectIndex]
		if skill then
			aTalent[i] = {
				nIndex = info.nSelectIndex,
				dwSkillID = skill.dwSkillID,
				dwSkillLevel = skill.dwSkillLevel,
			}
		else
			aTalent[i] = {
				nIndex = info.nSelectIndex,
				dwSkillID = 0,
				dwSkillLevel = 0,
			}
		end
	end
	if X.IsEmpty(aTalent) and (not PEEK_PLAYER_TALENT_TIME[player.dwID] or GetTime() - PEEK_PLAYER_TALENT_TIME[player.dwID] > 60000) then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Talent Peek player: ' .. player.dwID, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		PeekPlayer(player.dwID)
		return
	end
	for _, fnAction in ipairs(PEEK_PLAYER_TALENT_CALLBACK[player.dwID]) do
		X.SafeCall(fnAction, aTalent, player.dwID)
	end
	PEEK_PLAYER_TALENT_CALLBACK[player.dwID] = nil
end
X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	PEEK_PLAYER_TALENT_STATE[arg0] = nil
	PEEK_PLAYER_TALENT_TIME[arg0] = nil
end)

-- 获取玩家奇穴信息
-- X.GetPlayerTalentInfo(dwID, fnAction)
-- X.GetPlayerTalentInfo(dwID, bForcePeek, fnAction)
-- @param dwID 玩家ID
-- @param bForcePeek 是否强制拉取
-- @param fnAction 回调函数
function X.GetPlayerTalentInfo(dwID, bForcePeek, fnAction)
	-- 函数重载
	if X.IsFunction(bForcePeek) then
		fnAction, bForcePeek = bForcePeek, nil
	end
	-- 加入回调
	if not PEEK_PLAYER_TALENT_CALLBACK[dwID] then
		PEEK_PLAYER_TALENT_CALLBACK[dwID] = {}
	end
	table.insert(PEEK_PLAYER_TALENT_CALLBACK[dwID], fnAction)
	-- 自身判定
	if dwID == X.GetClientPlayerID() then
		OnGetPlayerTalentInfoPeekPlayer(X.GetClientPlayer())
		return
	end
	-- 缓存判定
	local player = X.GetPlayer(dwID)
	if player and PEEK_PLAYER_TALENT_STATE[dwID] == 'SUCCESS' and not bForcePeek then
		OnGetPlayerTalentInfoPeekPlayer(player)
		return
	end
	-- 防抖限制
	if PEEK_PLAYER_TALENT_STATE[dwID] == 'PENDING' and not bForcePeek then
		return
	end
	-- 发送请求
	PEEK_PLAYER_TALENT_STATE[dwID] = 'PENDING'
	if not EVENT_KEY then
		EVENT_KEY = X.RegisterEvent('ON_UPDATE_TALENT', X.NSFormatString('{$NS}#GetPlayerTalentInfo'), function()
			local dwID = arg0
			local player = X.GetPlayer(dwID)
			if player then
				PEEK_PLAYER_TALENT_STATE[dwID] = 'SUCCESS'
				PEEK_PLAYER_TALENT_TIME[dwID] = GetTime()
				OnGetPlayerTalentInfoPeekPlayer(player)
			end
		end)
	end
	PeekPlayer(dwID)
end
end

do
local function PeekPlayer(dwID)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'ZhenPaiInfo Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	X.SafeCall(ViewOtherZhenPaiSkill, dwID, true)
	X.SafeCall(X.UI.CloseFrame, 'ZhenPaiSkill')
end
local EVENT_KEY = nil
local PEEK_PLAYER_ZHEN_PAI_STATE = {}
local PEEK_PLAYER_ZHEN_PAI_CALLBACK = {}
local PEEK_PLAYER_ZHEN_PAI_CACHE = {}
local function OnGetPlayerZhenPaiInfoPeekPlayer(player)
	if not PEEK_PLAYER_ZHEN_PAI_CALLBACK[player.dwID] then
		return
	end
	local tZhenPaiInfo = X.Clone(PEEK_PLAYER_ZHEN_PAI_CACHE[player.dwID])
	if not tZhenPaiInfo then
		PeekPlayer(player.dwID)
		return
	end
	for _, fnAction in ipairs(PEEK_PLAYER_ZHEN_PAI_CALLBACK[player.dwID]) do
		X.SafeCall(fnAction, tZhenPaiInfo, player.dwID)
	end
	PEEK_PLAYER_ZHEN_PAI_CALLBACK[player.dwID] = nil
end
X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	PEEK_PLAYER_ZHEN_PAI_STATE[arg0] = nil
end)

-- 获取玩家镇派信息
-- X.GetPlayerZhenPaiInfo(dwID, fnAction)
-- X.GetPlayerZhenPaiInfo(dwID, bForcePeek, fnAction)
-- @param dwID 玩家ID
-- @param bForcePeek 是否强制拉取
-- @param fnAction 回调函数
function X.GetPlayerZhenPaiInfo(dwID, bForcePeek, fnAction)
	-- 函数重载
	if X.IsFunction(bForcePeek) then
		fnAction, bForcePeek = bForcePeek, nil
	end
	-- 支持性兼容
	if not X.CONSTANT.ZHEN_PAI then
		fnAction({})
		return
	end
	-- 加入回调
	if not PEEK_PLAYER_ZHEN_PAI_CALLBACK[dwID] then
		PEEK_PLAYER_ZHEN_PAI_CALLBACK[dwID] = {}
	end
	table.insert(PEEK_PLAYER_ZHEN_PAI_CALLBACK[dwID], fnAction)
	-- 自身判定
	if dwID == X.GetClientPlayerID() then
		local tTalentSkillLevel = {}
		local tar = X.GetPlayer(dwID)
		if tar then
			local aKungfuTalent = X.CONSTANT.ZHEN_PAI[tar.dwForceID]
			local nTalentSetID = tar.GetTalentSetID()
			if aKungfuTalent and nTalentSetID then
				for nKungfuIndex, aKungfuSubTalent in ipairs(aKungfuTalent) do
					for nKungfuSubIndex, aTalentSkillID in ipairs(aKungfuSubTalent) do
						for nSkillIndex, dwTalentSkillID in ipairs(aTalentSkillID) do
							if dwTalentSkillID ~= 0 then
								tTalentSkillLevel[dwTalentSkillID] = tar.GetTalentSkillLevel(nTalentSetID, dwTalentSkillID)
							end
						end
					end
				end
			end
		end
		PEEK_PLAYER_ZHEN_PAI_CACHE[dwID] = tTalentSkillLevel
		OnGetPlayerZhenPaiInfoPeekPlayer(X.GetClientPlayer())
		return
	end
	-- 缓存判定
	local player = X.GetPlayer(dwID)
	if player and PEEK_PLAYER_ZHEN_PAI_STATE[dwID] == 'SUCCESS' and not bForcePeek then
		OnGetPlayerZhenPaiInfoPeekPlayer(player)
		return
	end
	-- 防抖限制
	if PEEK_PLAYER_ZHEN_PAI_STATE[dwID] == 'PENDING' and not bForcePeek then
		return
	end
	-- 大侠判定
	if player.dwForceID == 0 or not player.GetKungfuMount() then
		PEEK_PLAYER_ZHEN_PAI_STATE[dwID] = 'SUCCESS'
		PEEK_PLAYER_ZHEN_PAI_CACHE[dwID] = {}
		OnGetPlayerZhenPaiInfoPeekPlayer(player)
		return
	end
	-- 发送请求
	PEEK_PLAYER_ZHEN_PAI_STATE[dwID] = 'PENDING'
	if not EVENT_KEY then
		EVENT_KEY = X.RegisterEvent('ON_GET_SKILL_LEVEL_RESULT', X.NSFormatString('{$NS}#GetPlayerZhenPaiInfo'), function()
			local dwID = arg0
			local t = arg1 or {}
			local tSkillLevel = {}
			for k, v in pairs(t) do
				tSkillLevel[k] = v
			end
			PEEK_PLAYER_ZHEN_PAI_STATE[dwID] = 'SUCCESS'
			PEEK_PLAYER_ZHEN_PAI_CACHE[dwID] = tSkillLevel
			OnGetPlayerZhenPaiInfoPeekPlayer(player)
		end)
	end
	PeekPlayer(dwID)
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
