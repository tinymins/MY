--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Npc')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local S2L_CACHE = setmetatable({}, { __mode = 'k' })
local L2S_CACHE = setmetatable({}, { __mode = 'k' })
function X.ConvertNpcID(dwID, eType)
	if X.IsPlayer(dwID) then
		if not S2L_CACHE[dwID] then
			S2L_CACHE[dwID] = { dwID + 0x40000000 }
		end
		return eType == 'short' and dwID or S2L_CACHE[dwID][1]
	else
		if not L2S_CACHE[dwID] then
			L2S_CACHE[dwID] = { dwID - 0x40000000 }
		end
		return eType == 'long' and dwID or L2S_CACHE[dwID][1]
	end
end
end

--------------------------------------------------------------------------------
-- 地图首领、重要 NPC
--------------------------------------------------------------------------------

-- 地图首领列表
do local BOSS_LIST, BOSS_LIST_CUSTOM
local CACHE_PATH = {'temporary/bosslist.jx3dat', X.PATH_TYPE.GLOBAL}
local CUSTOM_PATH = {'config/bosslist.jx3dat', X.PATH_TYPE.GLOBAL}
local function LoadCustomList()
	if not BOSS_LIST_CUSTOM then
		BOSS_LIST_CUSTOM = X.LoadLUAData(CUSTOM_PATH) or {}
	end
end
local function SaveCustomList()
	X.SaveLUAData(CUSTOM_PATH, BOSS_LIST_CUSTOM, {
		encoder = IsDebugClient() and 'luatext' or nil,
		indent = IsDebugClient() and '\t' or nil,
	})
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if BOSS_LIST and not bForceRefresh then
		return
	end
	X.CreateDataRoot(X.PATH_TYPE.GLOBAL)
	BOSS_LIST = X.LoadLUAData(CACHE_PATH)
	if bForceRefresh or not BOSS_LIST then
		BOSS_LIST = {}
		local DungeonBoss = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('DungeonBoss', true)
		if DungeonBoss then
			local nCount = DungeonBoss:GetRowCount()
			for i = 2, nCount do
				local tLine = DungeonBoss:GetRow(i)
				local dwMapID = tLine.dwMapID
				local szNpcList = tLine.szNpcList
				for szNpcIndex in string.gmatch(szNpcList, '(%d+)') do
					local DungeonNpc = X.GetGameTable('DungeonNpc', true)
					if DungeonNpc then
						local p = DungeonNpc:Search(tonumber(szNpcIndex))
						if p then
							if not BOSS_LIST[dwMapID] then
								BOSS_LIST[dwMapID] = {}
							end
							BOSS_LIST[dwMapID][p.dwNpcID] = p.szName
						end
					end
				end
			end
		end
		if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
			X.SaveLUAData(CACHE_PATH, BOSS_LIST)
		end
	end

	for dwMapID, tInfo in pairs(X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/bosslist/{$edition}.jx3dat') or {}) do
		if not BOSS_LIST[dwMapID] then
			BOSS_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or X.CONSTANT.EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or X.CONSTANT.EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- 获取指定地图指定模板ID的NPC是不是首领
-- (boolean) X.IsBoss(dwMapID, dwTem)
function X.IsBoss(dwMapID, dwTemplateID)
	GenerateList()
	return (
		(
			BOSS_LIST[dwMapID] and BOSS_LIST[dwMapID][dwTemplateID]
			and not (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or false
end

X.RegisterTargetAddonMenu(X.NSFormatString('{$NS}#Game#Bosslist'), function()
	local me = X.GetClientPlayer()
	local dwType, dwID = X.GetCharacterTarget(me)
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local kNpc = X.GetNpc(dwID)
		local szName = X.GetNpcName(kNpc.dwID)
		local dwMapID = X.GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = kNpc.dwTemplateID
		if X.IsBoss(dwMapID, dwTemplateID) then
			return {
				szOption = _L['Remove from BOSS list'],
				fnAction = function()
					GenerateList(true)
					if not BOSS_LIST_CUSTOM[dwMapID] then
						BOSS_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					if BOSS_LIST[dwMapID] and BOSS_LIST[dwMapID][dwTemplateID] then
						BOSS_LIST_CUSTOM[dwMapID].DEL[dwTemplateID] = szName
					end
					BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = nil
					SaveCustomList()
					FireUIEvent(X.NSFormatString('{$NS}_SET_BOSS'), dwMapID, dwTemplateID, false)
					FireUIEvent(X.NSFormatString('{$NS}_SET_IMPORTANT_NPC'), dwMapID, dwTemplateID, X.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		else
			return {
				szOption = _L['Add to BOSS list'],
				fnAction = function()
					GenerateList(true)
					if not BOSS_LIST_CUSTOM[dwMapID] then
						BOSS_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = szName
					SaveCustomList()
					FireUIEvent(X.NSFormatString('{$NS}_SET_BOSS'), dwMapID, dwTemplateID, true)
					FireUIEvent(X.NSFormatString('{$NS}_SET_IMPORTANT_NPC'), dwMapID, dwTemplateID, X.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		end
	end
end)
end

-- 地图重要NPC列表
do local INPC_LIST, INPC_LIST_CUSTOM
local CACHE_PATH = {'temporary/inpclist.jx3dat', X.PATH_TYPE.GLOBAL}
local function LoadCustomList()
	if not INPC_LIST_CUSTOM then
		INPC_LIST_CUSTOM = X.LoadLUAData({'config/inpclist.jx3dat', X.PATH_TYPE.GLOBAL}) or {}
	end
end
local function SaveCustomList()
	X.SaveLUAData({'config/inpclist.jx3dat', X.PATH_TYPE.GLOBAL}, INPC_LIST_CUSTOM, {
		encoder = IsDebugClient() and 'luatext' or nil,
		indent = IsDebugClient() and '\t' or nil,
	})
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if INPC_LIST and not bForceRefresh then
		return
	end
	INPC_LIST = X.LoadLUAData(CACHE_PATH)
	if bForceRefresh or not INPC_LIST then
		INPC_LIST = {}
		if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
			X.SaveLUAData(CACHE_PATH, INPC_LIST)
		end
	end
	for dwMapID, tInfo in pairs(X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/inpclist/{$edition}.jx3dat') or {}) do
		if not INPC_LIST[dwMapID] then
			INPC_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or X.CONSTANT.EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or X.CONSTANT.EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- 获取指定地图指定模板ID的NPC是不是重要NPC
-- (boolean) X.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
function X.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
	GenerateList()
	return (
		(
			INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID]
			and not (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or (not bNoBoss and X.IsBoss(dwMapID, dwTemplateID) or false)
end

-- 获取指定模板ID的NPC是不是被屏蔽的NPC
-- (boolean) X.IsShieldedNpc(dwTemplateID, szType)
function X.IsShieldedNpc(dwTemplateID, szType)
	if not Table_IsShieldedNpc then
		return false
	end
	local bShieldFocus, bShieldSpeak = Table_IsShieldedNpc(dwTemplateID)
	if szType == 'FOCUS' then
		return bShieldFocus
	end
	if szType == 'TALK' then
		return bShieldSpeak
	end
	return bShieldFocus or bShieldSpeak
end

local PARTNER_NPC = {}
X.RegisterEvent('NPC_ENTER_SCENE', 'LIB.PARTNER_NPC', function()
	local npc = X.GetNpc(arg0)
	if npc and npc.nSpecies == X.CONSTANT.NPC_SPECIES_TYPE.NPC_ASSISTED then
		PARTNER_NPC[npc.dwTemplateID] = true
	end
end)
---获取一个NPC模板ID是否是侠客
---@param dwTemplateID number @模板ID
---@return boolean @是否是侠客
function X.IsPartnerNpc(dwTemplateID)
	return PARTNER_NPC[dwTemplateID] or false
end

X.RegisterTargetAddonMenu(X.NSFormatString('{$NS}#Game#ImportantNpclist'), function()
	local me = X.GetClientPlayer()
	local dwType, dwID = X.GetCharacterTarget(me)
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = X.GetNpc(dwID)
		local szName = X.GetNpcName(p.dwID)
		local dwMapID = X.GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if X.IsImportantNpc(dwMapID, dwTemplateID, true) then
			return {
				szOption = _L['Remove from Important-NPC list'],
				fnAction = function()
					GenerateList(true)
					if not INPC_LIST_CUSTOM[dwMapID] then
						INPC_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					if INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID] then
						INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID] = szName
					end
					INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = nil
					SaveCustomList()
					FireUIEvent(X.NSFormatString('{$NS}_SET_IMPORTANT_NPC'), dwMapID, dwTemplateID, false)
				end,
			}
		else
			return {
				szOption = _L['Add to Important-NPC list'],
				fnAction = function()
					GenerateList(true)
					if not INPC_LIST_CUSTOM[dwMapID] then
						INPC_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = szName
					SaveCustomList()
					FireUIEvent(X.NSFormatString('{$NS}_SET_IMPORTANT_NPC'), dwMapID, dwTemplateID, true)
				end,
			}
		end
	end
end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
