--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Near')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 附近列表
--------------------------------------------------------------------------------

do
local NEARBY_NPC = {}      -- 附近的NPC
local NEARBY_PET = {}      -- 附近的PET
local NEARBY_BOSS = {}     -- 附近的首领
local NEARBY_PLAYER = {}   -- 附近的玩家
local NEARBY_PLAYER_SYNCING = {} -- 刚进入同步范围还在同步数据的玩家
local NEARBY_DOODAD = {}   -- 附近的物品
local NEARBY_FIGHT = {}    -- 附近玩家和NPC战斗状态缓存

-- 获取附近NPC列表
-- (table) X.GetNearNpc(void)
function X.GetNearNpc(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_NPC) do
		local npc = X.GetNpc(k)
		if not npc then
			NEARBY_NPC[k] = nil
		else
			table.insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

function X.GetNearNpcID(nLimit)
	local aNpcID = {}
	for k, _ in pairs(NEARBY_NPC) do
		table.insert(aNpcID, k)
		if nLimit and #aNpcID == nLimit then
			break
		end
	end
	return aNpcID
end

if IsDebugClient() then
function X.GetNearNpcTable()
	return NEARBY_NPC
end
end

-- 通过名字搜索附近 NPC ID，有多个返回第一个
---@param szName string @名字
---@return number | nil @搜索到的 NPC ID，没搜到返回 nil
function X.SearchNearNpcID(szName)
	for _, p in pairs(NEARBY_NPC) do
		if p.szName == szName or p.dwID == szName then
			return p.dwID
		end
	end
end

-- 获取附近PET列表
-- (table) X.GetNearPet(void)
function X.GetNearPet(nLimit)
	local aPet = {}
	for k, _ in pairs(NEARBY_PET) do
		local npc = X.GetNpc(k)
		if not npc then
			NEARBY_PET[k] = nil
		else
			table.insert(aPet, npc)
			if nLimit and #aPet == nLimit then
				break
			end
		end
	end
	return aPet
end

function X.GetNearPetID(nLimit)
	local aPetID = {}
	for k, _ in pairs(NEARBY_PET) do
		table.insert(aPetID, k)
		if nLimit and #aPetID == nLimit then
			break
		end
	end
	return aPetID
end

if IsDebugClient() then
function X.GetNearPetTable()
	return NEARBY_PET
end
end

-- 获取附近的首领
-- (table) X.GetNearBoss(void)
function X.GetNearBoss(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_BOSS) do
		local npc = X.GetNpc(k)
		if not npc then
			NEARBY_BOSS[k] = nil
		else
			table.insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

function X.GetNearBossID(nLimit)
	local aNpcID = {}
	for k, _ in pairs(NEARBY_BOSS) do
		table.insert(aNpcID, k)
		if nLimit and #aNpcID == nLimit then
			break
		end
	end
	return aNpcID
end

if IsDebugClient() then
function X.GetNearBossTable()
	return NEARBY_BOSS
end
end

X.RegisterEvent(X.NSFormatString('{$NS}_SET_BOSS'), 'LIB#GetNearBoss', function()
	local dwMapID, tBoss = X.GetMapID(), {}
	for _, npc in ipairs(X.GetNearNpc()) do
		if X.IsBoss(dwMapID, npc.dwTemplateID) then
			NEARBY_BOSS[npc.dwID] = npc
		end
	end
	NEARBY_BOSS = tBoss
end)

-- 获取附近玩家列表
-- (table) X.GetNearPlayer(void)
function X.GetNearPlayer(nLimit)
	local aPlayer = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		local p = X.GetPlayer(k)
		if not p then
			NEARBY_PLAYER[k] = nil
		else
			table.insert(aPlayer, p)
			if nLimit and #aPlayer == nLimit then
				break
			end
		end
	end
	return aPlayer
end

function X.GetNearPlayerID(nLimit)
	local aPlayerID = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		table.insert(aPlayerID, k)
		if nLimit and #aPlayerID == nLimit then
			break
		end
	end
	return aPlayerID
end

if IsDebugClient() then
function X.GetNearPlayerTable()
	return NEARBY_PLAYER
end
end

-- 通过名字搜索附近玩家 ID，有多个返回第一个
---@param szName string @名字
---@return number | nil @搜索到的玩家 ID，没搜到返回 nil
function X.SearchNearPlayerID(szName)
	for _, p in pairs(NEARBY_PLAYER) do
		if p.szName == szName or p.dwID == szName then
			return p.dwID
		end
	end
end

-- 获取附近物品列表
-- (table) X.GetNearPlayer(void)
function X.GetNearDoodad(nLimit)
	local aDoodad = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		local doodad = X.GetDoodad(dwID)
		if not doodad then
			NEARBY_DOODAD[dwID] = nil
		else
			table.insert(aDoodad, doodad)
			if nLimit and #aDoodad == nLimit then
				break
			end
		end
	end
	return aDoodad
end

function X.GetNearDoodadID(nLimit)
	local aDoodadID = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		table.insert(aDoodadID, dwID)
		if nLimit and #aDoodadID == nLimit then
			break
		end
	end
	return aDoodadID
end

if IsDebugClient() then
function X.GetNearDoodadTable()
	return NEARBY_DOODAD
end
end

X.BreatheCall(X.NSFormatString('{$NS}#FIGHT_HINT_TRIGGER'), function()
	for dwID, tar in pairs(NEARBY_NPC) do
		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
			NEARBY_FIGHT[dwID] = tar.bFightState
			FireUIEvent(X.NSFormatString('{$NS}_NPC_FIGHT_HINT'), dwID, tar.bFightState)
		end
	end
	for dwID, tar in pairs(NEARBY_PLAYER) do
		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
			NEARBY_FIGHT[dwID] = tar.bFightState
			FireUIEvent(X.NSFormatString('{$NS}_PLAYER_FIGHT_HINT'), dwID, tar.bFightState)
		end
	end
end)
X.RegisterEvent('NPC_ENTER_SCENE', function()
	local npc = X.GetNpc(arg0)
	if npc and npc.dwEmployer ~= 0 then
		NEARBY_PET[arg0] = npc
	end
	if npc and X.IsBoss(X.GetMapID(), npc.dwTemplateID) then
		NEARBY_BOSS[arg0] = npc
	end
	NEARBY_NPC[arg0] = npc
	NEARBY_FIGHT[arg0] = npc and npc.bFightState or false
end)
X.RegisterEvent('NPC_LEAVE_SCENE', function()
	NEARBY_PET[arg0] = nil
	NEARBY_BOSS[arg0] = nil
	NEARBY_NPC[arg0] = nil
	NEARBY_FIGHT[arg0] = nil
end)
X.RegisterEvent('PLAYER_ENTER_SCENE', function()
	local player = X.GetPlayer(arg0)
	NEARBY_PLAYER[arg0] = player
	NEARBY_PLAYER_SYNCING[arg0] = player
	NEARBY_FIGHT[arg0] = player and player.bFightState or false
	if X.GetClientPlayerID() == arg0 then
		FireUIEvent(X.NSFormatString('{$NS}_CLIENT_PLAYER_ENTER_SCENE'))
	end
end)
X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	if X.GetClientPlayerID() == arg0 then
		FireUIEvent(X.NSFormatString('{$NS}_CLIENT_PLAYER_LEAVE_SCENE'))
	end
	NEARBY_PLAYER[arg0] = nil
	NEARBY_PLAYER_SYNCING[arg0] = nil
	NEARBY_FIGHT[arg0] = nil
end)
X.FrameCall('LIB#NEARBY_PLAYER_SYNCING', function()
	for dwID, kTarget in pairs(NEARBY_PLAYER_SYNCING) do
		if kTarget.szName ~= '' then
			NEARBY_PLAYER_SYNCING[dwID] = nil
			FireUIEvent(X.NSFormatString('{$NS}_PLAYER_ENTER_SCENE'), dwID)
		end
	end
end)
X.RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = X.GetDoodad(arg0) end)
X.RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
