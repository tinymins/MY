--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Target')
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
-- 附近列表
--------------------------------------------------------------------------------

do
local NEARBY_NPC = {}      -- 附近的NPC
local NEARBY_PET = {}      -- 附近的PET
local NEARBY_BOSS = {}     -- 附近的首领
local NEARBY_PLAYER = {}   -- 附近的玩家
local NEARBY_DOODAD = {}   -- 附近的物品
local NEARBY_FIGHT = {}    -- 附近玩家和NPC战斗状态缓存

-- 获取指定对象
-- (KObject, info, bIsInfo) X.GetObject([number dwType, ]number dwID)
-- (KObject, info, bIsInfo) X.GetObject([number dwType, ]string szName)
-- dwType: [可选]对象类型枚举 TARGET.*
-- dwID  : 对象ID
-- return: 根据 dwType 类型和 dwID 取得操作对象
--         不存在时返回nil, nil
function X.GetObject(arg0, arg1, arg2)
	local dwType, dwID, szName
	if X.IsNumber(arg0) then
		if X.IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		elseif X.IsString(arg1) then
			dwType, szName = arg0, arg1
		elseif X.IsNil(arg1) then
			dwID = arg0
		end
	elseif X.IsString(arg0) then
		szName = arg0
	end
	if not dwID and not szName then
		return
	end

	if dwID and not dwType then
		if NEARBY_PLAYER[dwID] then
			dwType = TARGET.PLAYER
		elseif NEARBY_DOODAD[dwID] then
			dwType = TARGET.DOODAD
		elseif NEARBY_NPC[dwID] then
			dwType = TARGET.NPC
		end
	elseif not dwID and szName then
		local tSearch = {}
		if dwType == TARGET.PLAYER then
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
		elseif dwType == TARGET.NPC then
			tSearch[TARGET.NPC] = NEARBY_NPC
		elseif dwType == TARGET.DOODAD then
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		else
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
			tSearch[TARGET.NPC] = NEARBY_NPC
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		end
		for dwObjectType, NEARBY_OBJECT in pairs(tSearch) do
			for dwObjectID, KObject in pairs(NEARBY_OBJECT) do
				if X.GetObjectName(KObject) == szName then
					dwType, dwID = dwObjectType, dwObjectID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return
	end

	local p, info, b
	if dwType == TARGET.PLAYER then
		local me = X.GetClientPlayer()
		if me and dwID == me.dwID then
			p, info, b = me, me, false
		elseif not X.ENVIRONMENT.RUNTIME_OPTIMIZE and me and me.IsPlayerInMyParty(dwID) then
			p, info, b = X.GetPlayer(dwID), GetClientTeam().GetMemberInfo(dwID), true
		else
			p, info, b = X.GetPlayer(dwID), X.GetPlayer(dwID), false
		end
	elseif dwType == TARGET.NPC then
		p, info, b = X.GetNpc(dwID), X.GetNpc(dwID), false
	elseif dwType == TARGET.DOODAD then
		p, info, b = X.GetDoodad(dwID), X.GetDoodad(dwID), false
	elseif dwType == TARGET.ITEM then
		p, info, b = GetItem(dwID), GetItem(dwID), GetItem(dwID)
	end
	return p, info, b
end

-- 获取目标血量和最大血量
function X.GetObjectLife(obj)
	if not obj then
		return
	end
	return X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and obj.fCurrentLife64 or obj.nCurrentLife,
		X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and obj.fMaxLife64 or obj.nMaxLife
end

-- 获取目标内力和最大内力
function X.GetObjectMana(obj)
	if not obj then
		return
	end
	return obj.nCurrentMana, obj.nMaxMana
end

do
local CACHE = {}
local function GetObjectSceneIndex(dwID)
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if not X.IsMonsterMap(me.GetMapID()) then
		return
	end
	local scene = me.GetScene()
	if not scene then
		return
	end
	local nType = X.IsPlayer(dwID) and 0 or 1
	local nIndex = CACHE[dwID]
	if not nIndex or scene.GetTempCustomUnsigned4(1, nIndex * 20 + 1) ~= dwID then
		for i = 0, 9 do
			local nOffset = i * 20 + 1
			if scene.GetTempCustomUnsigned4(nType, nOffset) == dwID then
				CACHE[dwID] = i
				nIndex = i
				break
			end
		end
	end
	return scene, nType, nIndex
end

-- 获取目标精力和最大精力
---@param obj userdata | string @目标对象或目标ID
---@return number @目标精力，最大精力
function X.GetObjectSpirit(obj)
	local scene, nType, nIndex = GetObjectSceneIndex(X.IsUserdata(obj) and obj.dwID or obj)
	if scene and nType and nIndex then
		return scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 4),
			scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 8)
	end
end

-- 获取目标耐力和最大耐力
---@param obj userdata | string @目标对象或目标ID
---@return number @目标耐力，最大耐力
function X.GetObjectEndurance(obj)
	local scene, nType, nIndex = GetObjectSceneIndex(X.IsUserdata(obj) and obj.dwID or obj)
	if scene and nType and nIndex then
		return scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 12),
			scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 16)
	end
end
end

-- 根据模板ID获取NPC真实名称
local NPC_NAME_CACHE, DOODAD_NAME_CACHE = {}, {}
function X.GetTemplateName(dwType, dwTemplateID)
	local CACHE = dwType == TARGET.NPC and NPC_NAME_CACHE or DOODAD_NAME_CACHE
	local szName
	if CACHE[dwTemplateID] then
		szName = CACHE[dwTemplateID]
	end
	if not szName then
		if dwType == TARGET.NPC then
			szName = X.CONSTANT.NPC_NAME[dwTemplateID]
				and X.RenderTemplateString(X.CONSTANT.NPC_NAME[dwTemplateID])
				or Table_GetNpcTemplateName(dwTemplateID)
		else
			szName = X.CONSTANT.DOODAD_NAME[dwTemplateID]
				and X.RenderTemplateString(X.CONSTANT.DOODAD_NAME[dwTemplateID])
				or Table_GetDoodadTemplateName(dwTemplateID)
		end
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		CACHE[dwTemplateID] = szName or ''
	end
	if X.IsEmpty(szName) then
		szName = nil
	end
	return szName
end

-- 获取指定对象的名字
-- X.GetObjectName(obj, eRetID)
-- X.GetObjectName(dwType, dwID, eRetID)
-- (KObject) obj    要获取名字的对象
-- (string)  eRetID 是否返回对象ID信息
--    'auto'   名字为空时返回 -- 默认值
--    'always' 总是返回
--    'never'  总是不返回
local OBJECT_NAME = {
	['PLAYER'   ] = X.CreateCache('LIB#GetObjectName#PLAYER.v'   ),
	['NPC'      ] = X.CreateCache('LIB#GetObjectName#NPC.v'      ),
	['DOODAD'   ] = X.CreateCache('LIB#GetObjectName#DOODAD.v'   ),
	['ITEM'     ] = X.CreateCache('LIB#GetObjectName#ITEM.v'     ),
	['ITEM_INFO'] = X.CreateCache('LIB#GetObjectName#ITEM_INFO.v'),
	['UNKNOWN'  ] = X.CreateCache('LIB#GetObjectName#UNKNOWN.v'  ),
}
function X.GetObjectName(arg0, arg1, arg2, arg3, arg4)
	local KObject, szType, dwID, nExtraID, eRetID
	if X.IsNumber(arg0) then
		local dwType = arg0
		dwID, eRetID = arg1, arg2
		KObject = X.GetObject(dwType, dwID)
		if dwType == TARGET.PLAYER then
			szType = 'PLAYER'
		elseif dwType == TARGET.NPC then
			szType = 'NPC'
		elseif dwType == TARGET.DOODAD then
			szType = 'DOODAD'
		else
			szType = 'UNKNOWN'
		end
	elseif X.IsString(arg0) then
		if arg0 == 'PLAYER' or arg0 == 'NPC' or arg0 == 'DOODAD' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			else
				local dwType = TARGET[arg0]
				dwID, eRetID = arg1, arg2
				KObject = X.GetObject(dwType, dwID)
				szType = arg0
			end
		elseif arg0 == 'ITEM' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif X.IsNumber(arg3) then
				local p = X.GetPlayer(arg1)
				if p then
					KObject = p.GetItem(arg2, arg3)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg4
				end
			elseif X.IsNumber(arg2) then
				local p = X.GetClientPlayer()
				if p then
					KObject = p.GetItem(arg1, arg2)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg3
				end
			else
				dwID, eRetID = arg1, arg2
				KObject = GetItem(dwID)
			end
			szType = 'ITEM'
		elseif arg0 == 'ITEM_INFO' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif X.IsNumber(arg3) then
				dwID = arg1 .. ':' .. arg2 .. ':' .. arg3
				nExtraID = arg3
				eRetID = arg4
			else
				dwID = arg1 .. ':' .. arg2
				eRetID = arg3
			end
			KObject = GetItemInfo(arg1, arg2)
			szType = 'ITEM_INFO'
		else
			szType = 'UNKNOWN'
		end
	else
		KObject, eRetID = arg0, arg1
		if KObject then
			szType = X.GetObjectType(KObject)
			if szType == 'ITEM_INFO' then
				dwID = KObject.nGenre .. ':' .. KObject.dwID
			else
				dwID = KObject.dwID
			end
		end
	end
	if not dwID then
		return
	end
	if not eRetID then
		eRetID = 'auto'
	end
	local cache = OBJECT_NAME[szType][dwID]
	if not cache or (KObject and not cache.bFull) then -- 计算获取名称缓存
		local szDispType, szDispID, szName = '?', '', ''
		if KObject then
			szName = KObject.szName
		end
		if not cache then
			cache = { bFull = false }
		end
		if szType == 'PLAYER' then
			szDispType = 'P'
			cache.bFull = not X.IsEmpty(szName)
		elseif szType == 'NPC' then
			szDispType = 'N'
			if KObject then
				if X.IsEmpty(szName) then
					szName = X.GetTemplateName(TARGET.NPC, KObject.dwTemplateID)
				end
				if KObject.dwEmployer and KObject.dwEmployer ~= 0 then
					if X.Table.IsSimplePlayer(KObject.dwTemplateID) then -- 长歌影子
						szName = X.GetObjectName(X.GetPlayer(KObject.dwEmployer), eRetID)
					elseif not X.IsEmpty(szName) then
						local szEmpName = X.GetObjectName(
							(X.IsPlayer(KObject.dwEmployer) and X.GetPlayer(KObject.dwEmployer)) or X.GetNpc(KObject.dwEmployer),
							'never'
						)
						if szEmpName then
							cache.bFull = true
						else
							szEmpName = g_tStrings.STR_SOME_BODY
						end
						szName =  szEmpName .. g_tStrings.STR_PET_SKILL_LOG .. szName
					end
				else
					cache.bFull = true
				end
			end
		elseif szType == 'DOODAD' then
			szDispType = 'D'
			if KObject and X.IsEmpty(szName) then
				szName = X.Table.GetDoodadTemplateName(KObject.dwTemplateID)
				if szName then
					szName = szName:gsub('^%s*(.-)%s*$', '%1')
				end
			end
			cache.bFull = true
		elseif szType == 'ITEM' then
			szDispType = 'I'
			if KObject then
				szName = X.GetItemNameByItem(KObject)
			end
			cache.bFull = true
		elseif szType == 'ITEM_INFO' then
			szDispType = 'II'
			if KObject then
				szName = X.GetItemNameByItemInfo(KObject, nExtraID)
			end
			cache.bFull = true
		else
			szDispType = '?'
			cache.bFull = false
		end
		if szType == 'NPC' then
			szDispID = X.ConvertNpcID(dwID)
			if KObject then
				szDispID = szDispID .. '@' .. KObject.dwTemplateID
			end
		else
			szDispID = dwID
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		cache['never'] = szName
		if szName then
			cache['auto'] = szName
			cache['always'] = szName .. '(' .. szDispType .. szDispID .. ')'
		else
			cache['auto'] = szDispType .. szDispID
			cache['always'] = szDispType .. szDispID
		end
		OBJECT_NAME[szType][dwID] = cache
	end
	return cache and cache[eRetID] or nil
end

do
local CACHE = X.CreateCache('LIB#GetObjectType.v')
function X.GetObjectType(obj)
	if not CACHE[obj] then
		if NEARBY_PLAYER[obj.dwID] == obj then
			CACHE[obj] = 'PLAYER'
		elseif NEARBY_NPC[obj.dwID] == obj then
			CACHE[obj] = 'NPC'
		elseif NEARBY_DOODAD[obj.dwID] == obj then
			CACHE[obj] = 'DOODAD'
		else
			local szStr = tostring(obj)
			if szStr:find('^KGItem:%w+$') then
				CACHE[obj] = 'ITEM'
			elseif szStr:find('^KGLuaItemInfo:%w+$') then
				CACHE[obj] = 'ITEM_INFO'
			elseif szStr:find('^KDoodad:%w+$') then
				CACHE[obj] = 'DOODAD'
			elseif szStr:find('^KNpc:%w+$') then
				CACHE[obj] = 'NPC'
			elseif szStr:find('^KPlayer:%w+$') then
				CACHE[obj] = 'PLAYER'
			else
				CACHE[obj] = 'UNKNOWN'
			end
		end
	end
	return CACHE[obj]
end
end

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
	NEARBY_FIGHT[arg0] = nil
end)
X.RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = X.GetDoodad(arg0) end)
X.RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
end

--------------------------------------------------------------------------------
-- 交互物件
--------------------------------------------------------------------------------

-- 打开一个拾取交互物件（当前帧重复调用仅打开一次防止庖丁）
function X.OpenDoodad(me, doodad)
	X.Throttle(X.NSFormatString('{$NS}#OpenDoodad') .. doodad.dwID, 375, function()
		--[[#DEBUG BEGIN]]
		X.Debug('Open Doodad ' .. doodad.dwID .. ' [' .. doodad.szName .. '] at ' .. GetLogicFrameCount() .. '.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		OpenDoodad(me, doodad)
	end)
end

-- 交互一个拾取交互物件（当前帧重复调用仅交互一次防止庖丁）
function X.InteractDoodad(dwID)
	X.Throttle(X.NSFormatString('{$NS}#InteractDoodad') .. dwID, 375, function()
		--[[#DEBUG BEGIN]]
		X.Debug('Open Doodad ' .. dwID .. ' at ' .. GetLogicFrameCount() .. '.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		InteractDoodad(dwID)
	end)
end

-- 获取掉落拾取金钱数量
---@param dwDoodadID number @掉落拾取ID
---@return number @掉落拾取金钱数量
function X.GetDoodadLootMoney(dwDoodadID)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		return scene and scene.GetLootMoney(dwDoodadID)
	else
		local doodad = X.GetDoodad(dwDoodadID)
		return doodad and doodad.GetLootMoney()
	end
end

-- 获取掉落拾取物品数量
---@param dwDoodadID number @掉落拾取ID
---@return number @掉落拾取物品数量
function X.GetDoodadLootItemCount(dwDoodadID)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		local tLoot = scene and scene.GetLootList(dwDoodadID)
		return tLoot and tLoot.nItemCount or nil
	else
		local doodad = X.GetDoodad(dwDoodadID)
		return doodad and doodad.GetItemListCount()
	end
end

-- 获取掉落拾取物品
---@param dwDoodadID number @掉落拾取ID
---@return KItem,boolean,boolean,boolean @掉落拾取物品,是否需要Roll点,是否需要分配,是否需要拍卖
function X.GetDoodadLootItem(dwDoodadID, nIndex)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		local tLoot = scene and scene.GetLootList(dwDoodadID)
		local it = tLoot and tLoot[nIndex - 1]
		if it then
			local bNeedRoll = it.LootType == X.CONSTANT.LOOT_ITEM_TYPE.NEED_ROLL
			local bDist = it.LootType == X.CONSTANT.LOOT_ITEM_TYPE.NEED_DISTRIBUTE
			local bBidding = it.LootType == X.CONSTANT.LOOT_ITEM_TYPE.NEED_BIDDING
			return it.Item, bNeedRoll, bDist, bBidding
		end
	else
		local me = X.GetClientPlayer()
		local doodad = X.GetDoodad(dwDoodadID)
		if doodad then
			return doodad.GetLootItem(nIndex - 1, me)
		end
	end
end

-- 分配掉落拾取物品
---@param dwDoodadID number @掉落拾取ID
---@param dwItemID number @掉落物品ID
---@param dwTargetPlayerID number @被分配者ID
function X.DistributeDoodadItem(dwDoodadID, dwItemID, dwTargetPlayerID)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		if scene then
			scene.DistributeItem(dwDoodadID, dwItemID, dwTargetPlayerID)
		end
	else
		local doodad = X.GetDoodad(dwDoodadID)
		if doodad then
			doodad.DistributeItem(dwItemID, dwTargetPlayerID)
		end
	end
end

-- 获取掉落可拾取玩家列表
---@param dwDoodadID number @掉落拾取ID
---@return number[] @可拾取玩家列表
function X.GetDoodadLooterList(dwDoodadID)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		if scene then
			return scene.GetLooterList(dwDoodadID)
		end
	else
		local doodad = X.GetDoodad(dwDoodadID)
		if doodad then
			return doodad.GetLooterList()
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
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = X.GetObject(dwType, dwID)
		local szName = X.GetObjectName(p)
		local dwMapID = X.GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
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

X.RegisterTargetAddonMenu(X.NSFormatString('{$NS}#Game#ImportantNpclist'), function()
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = X.GetObject(dwType, dwID)
		local szName = X.GetObjectName(p)
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

do
local O = X.CreateUserSettingsModule('LIB', _L['System'], {
	tForceForegroundColor = {
		ePathType = X.PATH_TYPE.ROLE,
		bDataSet = true,
		szLabel = _L['Global color'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = X.CONSTANT.FORCE_COLOR_FG_DEFAULT['*'],
		tDataSetDefaultValue = X.CONSTANT.FORCE_COLOR_FG_DEFAULT,
	},
	tForceBackgroundColor = {
		ePathType = X.PATH_TYPE.ROLE,
		bDataSet = true,
		szLabel = _L['Global color'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = X.CONSTANT.FORCE_COLOR_BG_DEFAULT['*'],
		tDataSetDefaultValue = X.CONSTANT.FORCE_COLOR_BG_DEFAULT,
	},
	tCampForegroundColor = {
		ePathType = X.PATH_TYPE.ROLE,
		bDataSet = true,
		szLabel = _L['Global color'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = X.CONSTANT.CAMP_COLOR_FG_DEFAULT['*'],
		tDataSetDefaultValue = X.CONSTANT.CAMP_COLOR_FG_DEFAULT,
	},
	tCampBackgroundColor = {
		ePathType = X.PATH_TYPE.ROLE,
		bDataSet = true,
		szLabel = _L['Global color'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = X.CONSTANT.CAMP_COLOR_BG_DEFAULT['*'],
		tDataSetDefaultValue = X.CONSTANT.CAMP_COLOR_BG_DEFAULT,
	},
})

local function initForceCustom()
	FireUIEvent(X.NSFormatString('{$NS}_FORCE_COLOR_UPDATE'))
end
X.RegisterUserSettingsInit(X.NSFormatString('{$NS}#ForceColor'), initForceCustom)

function X.GetForceColor(dwForce, szType)
	if szType == 'background' then
		return X.Unpack(O.tForceBackgroundColor[dwForce])
	end
	return X.Unpack(O.tForceForegroundColor[dwForce])
end

function X.SetForceColor(dwForce, szType, tCol)
	if dwForce == 'reset' then
		O('reset', { 'tForceForegroundColor', 'tForceBackgroundColor' })
	elseif szType == 'background' then
		O.tForceBackgroundColor[dwForce] = tCol
	else
		O.tForceForegroundColor[dwForce] = tCol
	end
	FireUIEvent(X.NSFormatString('{$NS}_FORCE_COLOR_UPDATE'))
end

local function initCampCustom()
	FireUIEvent(X.NSFormatString('{$NS}_FORCE_COLOR_UPDATE'))
end
X.RegisterUserSettingsInit(X.NSFormatString('{$NS}#CampColor'), initCampCustom)

function X.GetCampColor(nCamp, szType)
	if szType == 'background' then
		return X.Unpack(O.tCampBackgroundColor[nCamp])
	end
	return X.Unpack(O.tCampForegroundColor[nCamp])
end

function X.SetCampColor(nCamp, szType, tCol)
	if nCamp == 'reset' then
		O('reset', { 'tCampForegroundColor', 'tCampBackgroundColor' })
	elseif szType == 'background' then
		O.tCampBackgroundColor[nCamp] = tCol
	else
		O.tCampForegroundColor[nCamp] = tCol
	end
	FireUIEvent(X.NSFormatString('{$NS}_CAMP_COLOR_UPDATE'))
end
end

--------------------------------------------------------------------------------
-- 角色信息相关接口
--------------------------------------------------------------------------------

-- 获取玩家自身信息（缓存）
do
local CLIENT_PLAYER_INFO
local function GeneClientPlayerInfo(bForce)
	if not bForce and CLIENT_PLAYER_INFO and CLIENT_PLAYER_INFO.dwID then
		return
	end
	local me = X.GetClientPlayer()
	if me then -- 确保获取到玩家
		if not CLIENT_PLAYER_INFO then
			CLIENT_PLAYER_INFO = {}
		end
		if not IsRemotePlayer(me.dwID) then -- 确保不在战场
			CLIENT_PLAYER_INFO.dwID   = me.dwID
			CLIENT_PLAYER_INFO.szName = me.szName
		end
		CLIENT_PLAYER_INFO.nX                = me.nX
		CLIENT_PLAYER_INFO.nY                = me.nY
		CLIENT_PLAYER_INFO.nZ                = me.nZ
		CLIENT_PLAYER_INFO.nFaceDirection    = me.nFaceDirection
		CLIENT_PLAYER_INFO.szTitle           = me.szTitle
		CLIENT_PLAYER_INFO.dwForceID         = me.dwForceID
		CLIENT_PLAYER_INFO.nLevel            = me.nLevel
		CLIENT_PLAYER_INFO.nExperience       = me.nExperience
		CLIENT_PLAYER_INFO.nCurrentStamina   = me.nCurrentStamina
		CLIENT_PLAYER_INFO.nCurrentThew      = me.nCurrentThew
		CLIENT_PLAYER_INFO.nMaxStamina       = me.nMaxStamina
		CLIENT_PLAYER_INFO.nMaxThew          = me.nMaxThew
		CLIENT_PLAYER_INFO.nBattleFieldSide  = me.nBattleFieldSide
		CLIENT_PLAYER_INFO.dwSchoolID        = me.dwSchoolID
		CLIENT_PLAYER_INFO.nCurrentTrainValue= me.nCurrentTrainValue
		CLIENT_PLAYER_INFO.nMaxTrainValue    = me.nMaxTrainValue
		CLIENT_PLAYER_INFO.nUsedTrainValue   = me.nUsedTrainValue
		CLIENT_PLAYER_INFO.nDirectionXY      = me.nDirectionXY
		CLIENT_PLAYER_INFO.nCurrentLife      = me.nCurrentLife
		CLIENT_PLAYER_INFO.nMaxLife          = me.nMaxLife
		CLIENT_PLAYER_INFO.fCurrentLife64,
		CLIENT_PLAYER_INFO.fMaxLife64        = X.GetObjectLife(me)
		CLIENT_PLAYER_INFO.nMaxLifeBase      = me.nMaxLifeBase
		CLIENT_PLAYER_INFO.nCurrentMana      = me.nCurrentMana
		CLIENT_PLAYER_INFO.nMaxMana          = me.nMaxMana
		CLIENT_PLAYER_INFO.nMaxManaBase      = me.nMaxManaBase
		CLIENT_PLAYER_INFO.nCurrentEnergy    = me.nCurrentEnergy
		CLIENT_PLAYER_INFO.nMaxEnergy        = me.nMaxEnergy
		CLIENT_PLAYER_INFO.nEnergyReplenish  = me.nEnergyReplenish
		CLIENT_PLAYER_INFO.bCanUseBigSword   = me.bCanUseBigSword
		CLIENT_PLAYER_INFO.nAccumulateValue  = me.nAccumulateValue
		CLIENT_PLAYER_INFO.nCamp             = me.nCamp
		CLIENT_PLAYER_INFO.bCampFlag         = me.bCampFlag
		CLIENT_PLAYER_INFO.bOnHorse          = me.bOnHorse
		CLIENT_PLAYER_INFO.nMoveState        = me.nMoveState
		CLIENT_PLAYER_INFO.dwTongID          = me.dwTongID
		CLIENT_PLAYER_INFO.nGender           = me.nGender
		CLIENT_PLAYER_INFO.nCurrentRage      = me.nCurrentRage
		CLIENT_PLAYER_INFO.nMaxRage          = me.nMaxRage
		CLIENT_PLAYER_INFO.nCurrentPrestige  = me.nCurrentPrestige
		CLIENT_PLAYER_INFO.bFightState       = me.bFightState
		CLIENT_PLAYER_INFO.nRunSpeed         = me.nRunSpeed
		CLIENT_PLAYER_INFO.nRunSpeedBase     = me.nRunSpeedBase
		CLIENT_PLAYER_INFO.dwTeamID          = me.dwTeamID
		CLIENT_PLAYER_INFO.nRoleType         = me.nRoleType
		CLIENT_PLAYER_INFO.nContribution     = me.nContribution
		CLIENT_PLAYER_INFO.nCoin             = me.nCoin
		CLIENT_PLAYER_INFO.nJustice          = me.nJustice
		CLIENT_PLAYER_INFO.nExamPrint        = me.nExamPrint
		CLIENT_PLAYER_INFO.nArenaAward       = me.nArenaAward
		CLIENT_PLAYER_INFO.nActivityAward    = me.nActivityAward
		CLIENT_PLAYER_INFO.bHideHat          = me.bHideHat
		CLIENT_PLAYER_INFO.bRedName          = me.bRedName
		CLIENT_PLAYER_INFO.dwKillCount       = me.dwKillCount
		CLIENT_PLAYER_INFO.nRankPoint        = me.nRankPoint
		CLIENT_PLAYER_INFO.nTitle            = me.nTitle
		CLIENT_PLAYER_INFO.nTitlePoint       = me.nTitlePoint
		CLIENT_PLAYER_INFO.dwPetID           = me.dwPetID
		CLIENT_PLAYER_INFO.dwMapID           = me.GetMapID()
		CLIENT_PLAYER_INFO.szMapName         = Table_GetMapName(me.GetMapID())
	end
end
X.RegisterEvent('LOADING_ENDING', function()
	GeneClientPlayerInfo(true)
end)
---获取玩家自身信息（缓存）
---@param bForce boolean @是否强制刷新缓存
---@return unknown @玩家的自身信息，或自身信息子字段数据
function X.GetClientPlayerInfo(bForce)
	GeneClientPlayerInfo(bForce)
	if not CLIENT_PLAYER_INFO then
		return X.CONSTANT.EMPTY_TABLE
	end
	return CLIENT_PLAYER_INFO
end
end

do
local PLAYER_NAME
---获取玩家自身角色名
---@return string @玩家的自身角色名
function X.GetClientPlayerName()
	if X.IsFunction(GetUserRoleName) then
		return GetUserRoleName()
	end
	local me = X.GetClientPlayer()
	if me and not IsRemotePlayer(me.dwID) then
		PLAYER_NAME = me.szName
	end
	return PLAYER_NAME
end
end

---获取玩家自身角色属性
function X.GetClientPlayerCharInfo()
	local me = X.GetClientPlayer()
	local kungfu = X.GetClientPlayer().GetKungfuMount()
	local data = {
		dwID = me.dwID,
		szName = me.szName,
		dwForceID = me.dwForceID,
		nEquipScore = me.GetTotalEquipScore() or 0,
		dwMountKungfuID = kungfu and kungfu.dwSkillID or 0,
	}
	if CharInfoMore_GetShowValue then
		local aCategory, aContent, tTip = CharInfoMore_GetShowValue()
		local nCategoryIndex, nSubLen, nSubIndex = 0, -1, 0
		for _, content in ipairs(aContent) do
			if nSubIndex > nSubLen then
				nCategoryIndex = nCategoryIndex + 1
				local category = aCategory[nCategoryIndex]
				if category then
					table.insert(data, {
						category = true,
						label = category[1],
					})
					nSubLen, nSubIndex = category[2], 1
				end
			end
			table.insert(data, {
				label = content[1],
				value = content[2],
				tip = tTip[content[3]],
			})
			nSubIndex = nSubIndex + 1
		end
	else
		local frame = Station.Lookup('Normal/CharInfo')
		if not frame or not frame:IsVisible() then
			if frame then
				X.UI.CloseFrame('CharInfo') -- 强制kill
			end
			X.UI.OpenFrame('CharInfo'):Hide()
		end
		local hCharInfo = Station.Lookup('Normal/CharInfo')
		local handle = hCharInfo:Lookup('WndScroll_Property', '')
		for i = 0, handle:GetVisibleItemCount() -1 do
			local h = handle:Lookup(i)
			table.insert(data, {
				szTip = h.szTip,
				label = h:Lookup(0):GetText(),
				value = h:Lookup(1):GetText(),
			})
		end
	end
	return data
end

do
local REQUEST_TIME = {}
local PLAYER_GUID = {}
local function RequestTeammateGUID()
	local me = X.GetClientPlayer()
	local team = GetClientTeam()
	if not me or IsRemotePlayer(me.dwID) or not team or not me.IsInParty() then
		return
	end
	local nTime = GetTime()
	local aRequestGUID = {}
	for _, dwTarID in ipairs(team.GetTeamMemberList()) do
		local info = team.GetMemberInfo(dwTarID)
		if not PLAYER_GUID[dwTarID]
		and (info and info.bIsOnLine)
		and (not REQUEST_TIME[dwTarID] or nTime - REQUEST_TIME[dwTarID] > 2000) then
			table.insert(aRequestGUID, dwTarID)
			REQUEST_TIME[dwTarID] = nTime
		end
	end
	if not X.IsEmpty(aRequestGUID) then
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, X.NSFormatString('{$NS}_GLOBAL_ID_REQUEST'), {aRequestGUID}, true)
	end
end
X.RegisterEvent('LOADING_END', RequestTeammateGUID)
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', RequestTeammateGUID)
X.RegisterEvent('PARTY_LEVEL_UP_RAID', RequestTeammateGUID)
X.RegisterEvent('PARTY_ADD_MEMBER', RequestTeammateGUID)
X.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', RequestTeammateGUID)
X.RegisterBgMsg(X.NSFormatString('{$NS}_GLOBAL_ID'), function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	PLAYER_GUID[dwTalkerID] = data
end)
-- 获取唯一标识符
function X.GetPlayerGlobalID(dwID)
	if dwID == X.GetClientPlayerID() then
		return X.GetClientPlayerGlobalID()
	end
	return PLAYER_GUID[dwID]
end
end

---获取玩家基本信息
---@param xPlayerID number @要获取的玩家唯一ID（缘起为 dwID）
---@return table @玩家的基本信息
function X.GetPlayerEntryInfo(xPlayerID)
	local me = X.GetClientPlayer()
	local smc = X.GetSocialManagerClient()
	if smc then
		local tPei = smc.GetRoleEntryInfo(xPlayerID)
		if tPei then
			tPei = {
				dwID = tPei.dwPlayerID,
				szName = tPei.szName,
				nLevel = tPei.nLevel,
				nRoleType = tPei.nRoleType,
				dwForceID = tPei.nForceID,
				nCamp = tPei.nCamp,
				szSignature = tPei.szSignature,
				bOnline = tPei.bOnline,
				dwMiniAvatarID = tPei.dwMiniAvatarID,
				nSkinID = tPei.nSkinID,
				dwServerID = tPei.dwCenterID,
			}
			local szServerName = X.GetServerNameByID(tPei.dwServerID)
			if szServerName and (szServerName ~= X.GetServerOriginName() or IsRemotePlayer(me.dwID)) then
				tPei.szName = tPei.szName .. g_tStrings.STR_CONNECT .. szServerName
			end
		end
		return tPei
	end
	local info = X.GetFellowshipInfo(xPlayerID)
	local fcc = X.GetFellowshipCardClient()
	local card = info and fcc and fcc.GetFellowshipCardInfo(info.id)
	if card then
		return {
			dwID = info.id,
			szName = card.szName,
			nLevel = card.nLevel,
			nRoleType = card.nRoleType,
			dwForceID = card.dwForceID,
			nCamp = card.nCamp,
			szSignature = card.szSignature,
			bOnline = info.isonline,
			dwMiniAvatarID = card.dwMiniAvatarID,
			nSkinID = card.dwSkinID,
			dwServerID = 0,
		}
	end
end

---获取玩家是否在线
---@param xPlayerID number @要获取的玩家唯一ID（缘起为 dwID）
---@return boolean @玩家是否在线
function X.IsPlayerOnline(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.IsRoleOnline(xPlayerID)
	end
	local tPei = X.GetPlayerEntryInfo(xPlayerID)
	if tPei then
		return tPei.bOnline
	end
end

--------------------------------------------------------------------------------
-- 帮会成员相关接口
--------------------------------------------------------------------------------

-- 获取帮会成员列表
---@param bShowOffLine boolean @是否显示离线成员
---@param szSorter string @排序字段
---@param bAsc boolean @是否升序排序
---@return table @帮会成员列表
function X.GetTongMemberInfoList(bShowOffLine, szSorter, bAsc)
	if bShowOffLine == nil then bShowOffLine = false  end
	if szSorter     == nil then szSorter     = 'name' end
	if bAsc         == nil then bAsc         = true   end
	local aSorter = {
		['name'  ] = 'name'                    ,
		['level' ] = 'group'                   ,
		['school'] = 'development_contribution',
		['score' ] = 'score'                   ,
		['map'   ] = 'join_time'               ,
		['remark'] = 'last_offline_time'       ,
	}
	szSorter = aSorter[szSorter]
	-- GetMemberList(bShowOffLine, szSorter, bAsc, nGroupFilter, -1) -- 后面两个参数不知道什么鬼
	return GetTongClient().GetMemberList(bShowOffLine, szSorter or 'name', bAsc, -1, -1)
end

-- 获取帮会名称
---@param dwTongID number @帮会ID
---@return string @帮会名称
function X.GetTongName(dwTongID)
	local szTongName
	if not dwTongID then
		dwTongID = (X.GetClientPlayer() or X.CONSTANT.EMPTY_TABLE).dwTongID
	end
	if dwTongID and dwTongID ~= 0 then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, 253)
	else
		szTongName = ''
	end
	return szTongName
end

-- 获取帮会成员
---@param arg0 string | number @帮会成员ID或名称
---@return table @帮会成员信息
function X.GetTongMemberInfo(arg0)
	if not arg0 then
		return
	end
	return GetTongClient().GetMemberInfo(arg0)
end

-- 判断是否是帮会成员
---@param arg0 string | number @帮会成员ID或名称
---@return boolean @是否是帮会成员
function X.IsTongMember(arg0)
	return X.GetTongMemberInfo(arg0) and true or false
end

--------------------------------------------------------------------------------
-- 角色关系相关接口
--------------------------------------------------------------------------------

-- 判断是不是队友
---@param dwID number @角色ID
---@return boolean @该角色是不是队友
function X.IsParty(dwID)
	if X.IsString(dwID) then
		if dwID == X.GetClientPlayerName() then
			return true
		end
		local team = GetClientTeam()
		for _, dwTarID in ipairs(team.GetTeamMemberList()) do
			if dwID == team.GetClientTeamMemberName(dwTarID) then
				return true
			end
		end
		return false
	end
	if dwID == X.GetClientPlayerID() then
		return true
	end
	local me = X.GetClientPlayer()
	return me and me.IsPlayerInMyParty(dwID)
end

-- 判断关系
---@param dwSelfID number @来源角色ID
---@param dwPeerID number @目标角色ID
---@return "'Self'"|"'Party'"|"'Neutrality'"|"'Foe'"|"'Enemy'"|"'Ally'" @目标角色相对来源角色的关系
function X.GetRelation(dwSelfID, dwPeerID)
	if not dwPeerID then
		dwPeerID = dwSelfID
		dwSelfID = X.GetControlPlayerID()
	end
	if not X.IsPlayer(dwPeerID) then
		local npc = X.GetNpc(dwPeerID)
		if npc and npc.dwEmployer ~= 0 and X.GetPlayer(npc.dwEmployer) then
			dwPeerID = npc.dwEmployer
		end
	end
	if X.IsSelf(dwSelfID, dwPeerID) then
		return 'Self'
	end
	local dwSrcID, dwTarID = dwSelfID, dwPeerID
	if not X.IsPlayer(dwTarID) then
		dwSrcID, dwTarID = dwTarID, dwSrcID
	end
	if IsParty(dwSrcID, dwTarID) then
		return 'Party'
	elseif IsNeutrality(dwSrcID, dwTarID) then
		return 'Neutrality'
	elseif IsEnemy(dwSrcID, dwTarID) then -- 敌对关系
		if X.GetFoeInfo(dwPeerID) then
			return 'Foe'
		else
			return 'Enemy'
		end
	elseif IsAlly(dwSrcID, dwTarID) then -- 相同阵营
		return 'Ally'
	else
		return 'Enemy' -- 'Other'
	end
end

-- 判断是不是红名
---@param dwSelfID number @来源角色ID
---@param dwPeerID number @目标角色ID
---@return boolean @目标角色相对来源角色是不是红名
function X.IsEnemy(dwSelfID, dwPeerID)
	return X.GetRelation(dwSelfID, dwPeerID) == 'Enemy'
end

function X.IsSelf(dwSrcID, dwTarID)
	if X.IsFunction(IsSelf) then
		return IsSelf(dwSrcID, dwTarID)
	end
	return dwSrcID ~= 0 and dwSrcID == dwTarID and X.IsPlayer(dwSrcID) and X.IsPlayer(dwTarID)
end

--------------------------------------------------------------------------------
-- 目标获取相关接口
--------------------------------------------------------------------------------

-- 取得目标类型和ID
-- (dwType, dwID) X.GetTarget()       -- 取得自己当前的目标类型和ID
-- (dwType, dwID) X.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
function X.GetTarget(...)
	local object = ...
	if select('#', ...) == 0 then
		object = X.GetClientPlayer()
	end
	if object and object.GetTarget then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end

-- 取得目标的目标类型和ID
-- (dwType, dwID) X.GetTargetTarget()       -- 取得自己当前的目标的目标类型和ID
-- (dwType, dwID) X.GetTargetTarget(object) -- 取得指定操作对象当前的目标的目标类型和ID
function X.GetTargetTarget(object)
	local nTarType, dwTarID = X.GetTarget(object)
	local KTar = X.GetObject(nTarType, dwTarID)
	if not KTar then
		return
	end
	return X.GetTarget(KTar)
end

-- 获取指定名字的右键菜单
function X.GetTargetContextMenu(dwType, szName, dwID)
	local t = {}
	if dwType == TARGET.PLAYER then
		-- 复制
		table.insert(t, {
			szOption = _L['Copy'],
			fnAction = function()
				X.SendChat(X.GetClientPlayer().szName, '[' .. szName .. ']')
			end,
		})
		-- 密聊 好友 邀请入帮 跟随
		X.Call(InsertPlayerCommonMenu, t, dwID, szName)
		-- insert invite team
		if szName and InsertInviteTeamMenu then
			InsertInviteTeamMenu(t, szName)
		end
		-- get dwID
		if not dwID and _G.MY_Farbnamen and _G.MY_Farbnamen.GetAusName then
			local tInfo = _G.MY_Farbnamen.GetAusName(szName)
			if tInfo then
				dwID = tonumber(tInfo.dwID)
			end
		end
		-- insert view equip
		if dwID and X.GetClientPlayerID() ~= dwID then
			table.insert(t, {
				szOption = _L['View equipment'],
				fnAction = function()
					ViewInviteToPlayer(dwID)
				end,
			})
		end
		-- insert view arena
		table.insert(t, {
			szOption = g_tStrings.LOOKUP_CORPS,
			-- fnDisable = function() return not X.GetPlayer(dwID) end,
			fnAction = function()
				X.UI.CloseFrame('ArenaCorpsPanel')
				OpenArenaCorpsPanel(true, dwID)
			end,
		})
	end
	-- view qixue -- mark target
	if dwID and InsertTargetMenu then
		local tx = {}
		InsertTargetMenu(tx, dwType, dwID, szName)
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.LOOKUP_INFO or v.szOption == g_tStrings.STR_LOOKUP_MORE then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then -- 查看奇穴
						table.insert(t, vv)
						break
					end
				end
				break
			end
		end
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.STR_ARENA_INVITE_TARGET -- 邀请入名剑队
			or v.szOption == g_tStrings.LOOKUP_INFO             -- 查看更多信息
			or v.szOption == g_tStrings.STR_LOOKUP_MORE         -- 查看更多
			or v.szOption == g_tStrings.CHANNEL_MENTOR          -- 师徒
			or v.szOption == g_tStrings.STR_ADD_SHANG           -- 发布悬赏
			or v.szOption == g_tStrings.STR_MARK_TARGET         -- 标记目标
			or v.szOption == g_tStrings.STR_MAKE_TRADDING       -- 交易
			or v.szOption == g_tStrings.REPORT_RABOT            -- 举报外挂
			then
				table.insert(t, v)
			end
		end
	end

	return t
end

X.RegisterRestriction('X.SET_TARGET', { ['*'] = true, intl = false })

-- 根据 dwType 类型和 dwID 设置目标
-- (void) X.SetTarget([number dwType, ]number dwID)
-- (void) X.SetTarget([number dwType, ]string szName)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID
function X.SetTarget(arg0, arg1)
	local dwType, dwID, szNames
	if X.IsUserdata(arg0) then
		dwType, dwID = TARGET[X.GetObjectType(arg0)], arg0.dwID
	elseif X.IsString(arg0) then
		szNames = arg0
	elseif X.IsNumber(arg0) then
		if X.IsNil(arg1) then
			dwID = arg0
		elseif X.IsString(arg1) then
			dwType, szNames = arg0, arg1
		elseif X.IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		end
	end
	if not dwID and not szNames then
		return
	end
	if dwID and not dwType then
		dwType = X.IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC
	end
	if szNames then
		local tTarget = {}
		for _, szName in pairs(X.SplitString(szNames:gsub('[%[%]]', ''), '|')) do
			tTarget[szName] = true
		end
		if not dwID and (not dwType or dwType == TARGET.NPC) then
			for _, p in ipairs(X.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and (not dwType or dwType == TARGET.PLAYER) then
			for _, p in ipairs(X.GetNearPlayer()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.PLAYER, p.dwID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return false
	end
	if dwType == TARGET.PLAYER then
		if X.IsInShieldedMap() and not X.IsParty(dwID) and X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.Debug('SetTarget', 'Set target to player is forbiden in current map.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.NPC then
		local npc = X.GetNpc(dwID)
		if npc and not npc.IsSelectable() and X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.Debug('SetTarget', 'Set target to unselectable npc.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.DOODAD then
		if X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.Debug('SetTarget', 'Set target to doodad.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	end
	SetTarget(dwType, dwID)
	return true
end

-- 设置/取消 临时目标
-- X.SetTempTarget(dwType, dwID)
-- X.ResumeTarget()
do
local TEMP_TARGET = { TARGET.NO_TARGET, 0 }
function X.SetTempTarget(dwType, dwID)
	TargetPanel_SetOpenState(true)
	TEMP_TARGET = X.Pack(X.GetClientPlayer().GetTarget())
	X.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end

function X.ResumeTarget()
	TargetPanel_SetOpenState(true)
	-- 当之前的目标不存在时，切到空目标
	if TEMP_TARGET[1] ~= TARGET.NO_TARGET and not X.GetObject(X.Unpack(TEMP_TARGET)) then
		TEMP_TARGET = X.Pack(TARGET.NO_TARGET, 0)
	end
	X.SetTarget(X.Unpack(TEMP_TARGET))
	TEMP_TARGET = X.Pack(TARGET.NO_TARGET, 0)
	TargetPanel_SetOpenState(false)
end
end

-- 临时设置目标为指定目标并执行函数
-- (void) X.WithTarget(dwType, dwID, callback)
do
local WITH_TARGET_LIST = {}
local LOCK_WITH_TARGET = false
local function WithTargetHandle()
	if LOCK_WITH_TARGET or
	#WITH_TARGET_LIST == 0 then
		return
	end

	LOCK_WITH_TARGET = true
	local r = table.remove(WITH_TARGET_LIST, 1)

	X.SetTempTarget(r.dwType, r.dwID)
	local res, err, trace = X.XpCall(r.callback)
	if not res then
		X.ErrorLog(err, X.NSFormatString('{$NS}#WithTarget'), trace)
	end
	X.ResumeTarget()

	LOCK_WITH_TARGET = false
	WithTargetHandle()
end
function X.WithTarget(dwType, dwID, callback)
	-- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
	table.insert(WITH_TARGET_LIST, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	WithTargetHandle()
end
end

do
local CALLBACK_LIST
-- 获取到当前角色并执行函数
-- @param {function} callback 回调函数
function X.WithClientPlayer(callback)
	local me = X.GetClientPlayer()
	if me then
		X.SafeCall(callback, me)
	elseif CALLBACK_LIST then
		table.insert(CALLBACK_LIST, callback)
	else
		CALLBACK_LIST = {callback}
		X.BreatheCall(X.NSFormatString('{$NS}.WithClientPlayer'), function()
			local me = X.GetClientPlayer()
			if me then
				for _, callback in ipairs(CALLBACK_LIST) do
					X.SafeCall(callback, me)
				end
				CALLBACK_LIST = nil
				X.BreatheCall(X.NSFormatString('{$NS}.WithClientPlayer'), false)
			end
		end)
	end
end
end

-- 求N2在N1的面向角  --  重载+2
-- (number) X.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) X.GetFaceAngel(oN1, oN2, bAbs)
-- @param nX    N1的X坐标
-- @param nY    N1的Y坐标
-- @param nFace N1的面向[0, 255]
-- @param nTX   N2的X坐标
-- @param nTY   N2的Y坐标
-- @param bAbs  返回角度是否只允许正数
-- @param oN1   N1对象
-- @param oN2   N2对象
-- @return nil    参数错误
-- @return number 面向角(-180, 180]
function X.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
	if type(nY) == 'userdata' and type(nX) == 'userdata' then
		nX, nY, nFace, nTX, nTY, bAbs = nX.nX, nX.nY, nX.nFaceDirection, nY.nX, nY.nY, nFace
	end
	if type(nX) == 'number' and type(nY) == 'number' and type(nFace) == 'number'
	and type(nTX) == 'number' and type(nTY) == 'number' then
		local nFace = (nFace * 2 * math.pi / 255) - math.pi
		local nSight = (nX == nTX and ((nY > nTY and math.pi / 2) or - math.pi / 2)) or math.atan((nTY - nY) / (nTX - nX))
		local nAngel = ((nSight - nFace) % (math.pi * 2) - math.pi) / math.pi * 180
		if bAbs then
			nAngel = math.abs(nAngel)
		end
		return nAngel
	end
end

--------------------------------------------------------------------------------
-- 角色状态
--------------------------------------------------------------------------------

-- 获取对象是否无敌
-- (mixed) X.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function X.IsInvincible(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return nil
	elseif X.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end

-- 获取对象是否被隔离
-- (mixed) X.IsIsolated([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object isolated state
function X.IsIsolated(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return false
	end
	if X.ENVIRONMENT.GAME_BRANCH == 'classic' then
		return false
	end
	return KObject.bIsolated
end

do
local CURRENT_NPC_SHOW_ALL = true
local CURRENT_PLAYER_SHOW_ALL = true
local CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = false
X.RegisterEvent('ON_REPRESENT_CMD', 'LIB#PLAYER_DISPLAY_MODE', function()
	if arg0 == 'show npc' then
		CURRENT_NPC_SHOW_ALL = true
	elseif arg0 == 'hide npc' then
		CURRENT_NPC_SHOW_ALL = false
	elseif arg0 == 'show player' then
		CURRENT_PLAYER_SHOW_ALL = true
	elseif arg0 == 'hide player' then
		CURRENT_PLAYER_SHOW_ALL = false
	elseif arg0 == 'show or hide party player 1' then
		CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = true
	elseif arg0 == 'show or hide party player 0' then
		CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = false
	end
end)

--------------------------------------------------------------------------------
-- 角色模型屏蔽状态
--------------------------------------------------------------------------------

--- 获取 NPC 显示状态
---@return boolean @NPC 是否显示
function X.GetNpcVisibility()
	return CURRENT_NPC_SHOW_ALL
end

--- 设置 NPC 显示状态
---@param bShow boolean @NPC 是否显示
function X.SetNpcVisibility(bShow)
	if bShow then
		rlcmd('show npc')
	else
		rlcmd('hide npc')
	end
end

--- 获取玩家显示状态
---@return boolean, boolean @玩家是否显示 @队友是否强制显示
function X.GetPlayerVisibility()
	if UIGetPlayerDisplayMode and PLAYER_DISPLAY_MODE then
		local eMode = UIGetPlayerDisplayMode()
		if eMode == PLAYER_DISPLAY_MODE.ALL then
			return true, true
		end
		if eMode == PLAYER_DISPLAY_MODE.ONLY_PARTY then
			return false, true
		end
		if eMode == PLAYER_DISPLAY_MODE.ONLY_SELF then
			return false, false
		end
		return true, false
	end
	return CURRENT_PLAYER_SHOW_ALL, CURRENT_PLAYER_SHOW_PARTY_OVERRIDE
end

--- 设置玩家显示状态
---@param bShowAll boolean @玩家是否显示
---@param bShowPartyOverride boolean @队友是否强制显示
function X.SetPlayerVisibility(bShowAll, bShowPartyOverride)
	if UISetPlayerDisplayMode and PLAYER_DISPLAY_MODE then
		if bShowAll then
			return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ALL)
		end
		if bShowPartyOverride then
			return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ONLY_PARTY)
		end
		return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ONLY_SELF)
	end
	if bShowAll then
		rlcmd('show player')
	else
		rlcmd('hide player')
	end
	if bShowPartyOverride then
		rlcmd('show or hide party player 1')
	else
		rlcmd('show or hide party player 0')
	end
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
