--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Map')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local MAP_LIST
local function GenerateMapInfo()
	if not MAP_LIST then
		MAP_LIST = {}
		for _, dwMapID in ipairs(GetMapList()) do
			local map = {
				dwID     = dwMapID,
				dwMapID  = dwMapID,
				szName   = X.CONSTANT.MAP_NAME[dwMapID]
					and X.RenderTemplateString(X.CONSTANT.MAP_NAME[dwMapID])
					or Table_GetMapName(dwMapID),
				bDungeon = false,
			}
			local DungeonInfo = X.GetGameTable('DungeonInfo', true)
			if DungeonInfo then
				local tDungeonInfo = DungeonInfo:Search(dwMapID)
				if tDungeonInfo and tDungeonInfo.dwClassID == 3 then
					map.bDungeon = true
				end
			end
			MAP_LIST[map.dwID] = map
			MAP_LIST[map.szName] = map
		end
		MAP_LIST = X.RecursiveFreezeTable(MAP_LIST)
	end
	return MAP_LIST
end

---获取一个地图的信息
---(table) X.GetMapInfo(dwMapID)
---(table) X.GetMapInfo(szMapName)
---@param arg0 number | string @地图ID或地图名称
---@return table @地图信息
function X.GetMapInfo(arg0)
	if not MAP_LIST then
		GenerateMapInfo()
	end
	if arg0 and X.CONSTANT.MAP_MERGE[arg0] then
		arg0 = X.CONSTANT.MAP_MERGE[arg0]
	end
	return MAP_LIST[arg0]
end
end

---获取一个地图的名字
---@param dwMapID number @地图ID
---@return string @地图名字
function X.GetMapName(dwMapID)
	return Table_GetMapName(dwMapID)
end

function X.GetMapNameList()
	local aList, tMap = {}, {}
	for k, v in X.ipairs_r(GetMapList()) do
		local szName = Table_GetMapName(v)
		if not tMap[szName] then
			tMap[szName] = true
			table.insert(aList, szName)
		end
	end
	return aList
end

---获取主角当前所在地图
---@param bFix boolean @是否做修正
---@return number @所在地图ID
function X.GetMapID(bFix)
	local dwMapID = X.GetClientPlayer().GetMapID()
	return bFix and X.CONSTANT.MAP_MERGE[dwMapID] or dwMapID
end

do
local ARENA_MAP
---判断一个地图是不是名剑大会地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是名剑大会地图
function X.IsArenaMap(dwMapID)
	if not ARENA_MAP then
		ARENA_MAP = {}
		local tTitle = {
			{f = 'i', t = 'dwMapID'},
			{f = 'i', t = 'nEnableGroup0'},
			{f = 'i', t = 'nEnableGroup1'},
			{f = 'i', t = 'nEnableGroup2'},
			{f = 'i', t = 'nEnableGroup3'},
			{f = 'i', t = 'dwPQTemplateID'},
			{f = 'i', t = 'nVisitorCount'},
			{f = 'i', t = 'nGMVisitorCount'},
			{f = 's', t = 'szScript'},
			{f = 'i', t = 'nCritical'},
			X.IS_CLASSIC and {f = 'i', t = 'nIs1V1'} or false,
		}
		for i, v in X.ipairs_r(tTitle) do
			if not v then
				table.remove(tTitle, i)
			end
		end
		local tab = KG_Table.Load('settings\\ArenaMap.tab', tTitle, FILE_OPEN_MODE.NORMAL)
		local nRow = tab:GetRowCount()
		for i = 1, nRow do
			local tLine = tab:GetRow(i)
			ARENA_MAP[tLine.dwMapID] = true
		end
	end
	return ARENA_MAP[dwMapID]
end
end

---判断当前地图是不是名剑大会地图
---@return boolean @当前地图是否是名剑大会地图
function X.IsInArenaMap()
	local me = X.GetClientPlayer()
	return me and X.IsArenaMap(me.GetMapID())
end

---判断一个地图是不是战场地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是战场地图
function X.IsBattlefieldMap(dwMapID)
	return select(2, GetMapParams(dwMapID)) == MAP_TYPE.BATTLE_FIELD and not X.IsArenaMap(dwMapID)
end

---判断当前地图是不是战场地图
---@return boolean @当前地图是否是战场地图
function X.IsInBattlefieldMap()
	local me = X.GetClientPlayer()
	return me and X.IsBattlefieldMap(me.GetMapID())
end

---判断一个地图是不是秘境地图
---@param dwMapID number | string @要判断的地图ID或地图名称
---@param bRaid boolean @是否强制要求团队秘境或小队秘境
---@return boolean @是否是秘境地图
function X.IsDungeonMap(dwMapID, bRaid)
	local map = X.GetMapInfo(dwMapID)
	if map then
		dwMapID = map.dwMapID
	end
	if bRaid == true then -- 严格判断25人本
		return map and map.bDungeon
	elseif bRaid == false then -- 严格判断5人本
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON and not (map and map.bDungeon)
	else -- 只判断地图的类型
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
	end
end

---判断当前地图是不是秘境地图
---@param bRaid boolean @是否强制要求团队秘境或小队秘境
---@return boolean @当前地图是否是秘境地图
function X.IsInDungeonMap(bRaid)
	local me = X.GetClientPlayer()
	return me and X.IsDungeonMap(me.GetMapID(), bRaid)
end

---判断一个地图是不是个人CD秘境地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是个人CD秘境地图
function X.IsCDProgressMap(dwMapID)
	return (select(8, GetMapParams(dwMapID)))
end

---判断当前地图是不是个人CD秘境地图
---@return boolean @当前地图是否是个人CD秘境地图
function X.IsInCDProgressMap()
	local me = X.GetClientPlayer()
	return me and X.IsCDProgressMap(me.GetMapID())
end

---判断一个地图是不是主城地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是主城地图
function X.IsCityMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.CITY and true or false
end

---判断当前地图是不是主城地图
---@return boolean @当前地图是否是主城地图
function X.IsInCityMap()
	local me = X.GetClientPlayer()
	return me and X.IsCityMap(me.GetMapID())
end

---判断一个地图是不是野外地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是野外地图
function X.IsVillageMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.VILLAGE and true or false
end

---判断当前地图是不是野外地图
---@return boolean @当前地图是否是野外地图
function X.IsInVillageMap()
	local me = X.GetClientPlayer()
	return me and X.IsVillageMap(me.GetMapID())
end

---判断一个地图是不是阵营地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是阵营地图
function X.IsCampMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.CAMP and true or false
end

---判断当前地图是不是阵营地图
---@return boolean @当前地图是否是阵营地图
function X.IsInCampMap()
	local me = X.GetClientPlayer()
	return me and X.IsCampMap(me.GetMapID())
end

do
local PUBG_MAP = {}
---判断地图是不是绝境战场地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是绝境战场地图
function X.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = X.Table.IsTreasureBattleFieldMap(dwMapID) or false
	end
	return PUBG_MAP[dwMapID]
end
end

---判断当前地图是不是绝境战场地图
---@return boolean @当前地图是否是绝境战场地图
function X.IsInPubgMap()
	local me = X.GetClientPlayer()
	return me and X.IsPubgMap(me.GetMapID())
end

do
local ZOMBIE_MAP = {}
---判断地图是不是李渡鬼域地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是李渡鬼域地图
function X.IsZombieMap(dwMapID)
	if ZOMBIE_MAP[dwMapID] == nil then
		ZOMBIE_MAP[dwMapID] = Table_IsZombieBattleFieldMap
			and Table_IsZombieBattleFieldMap(dwMapID) or false
	end
	return ZOMBIE_MAP[dwMapID]
end
end

---判断当前地图是不是李渡鬼域地图
---@return boolean @当前地图是否是李渡鬼域地图
function X.IsInZombieMap()
	local me = X.GetClientPlayer()
	return me and X.IsZombieMap(me.GetMapID())
end

do
local MONSTER_MAP = {}
---判断地图是不是百战地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是百战地图
function X.IsMonsterMap(dwMapID)
	if MONSTER_MAP[dwMapID] == nil then
		if GDAPI_SpiritEndurance_IsSEMap then
			MONSTER_MAP[dwMapID] = GDAPI_SpiritEndurance_IsSEMap(dwMapID) or false
		else
			MONSTER_MAP[dwMapID] = X.CONSTANT.MONSTER_MAP[dwMapID] or false
		end
	end
	return MONSTER_MAP[dwMapID]
end
end

---判断当前地图是不是百战地图
---@return boolean @当前地图是否是百战地图
function X.IsInMonsterMap()
	local me = X.GetClientPlayer()
	return me and X.IsMonsterMap(me.GetMapID())
end

---判断地图是不是列星虚境地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是列星虚境地图
-- (bool) X.IsMobaMap(dwMapID)
function X.IsMobaMap(dwMapID)
	return X.CONSTANT.MOBA_MAP[dwMapID] or false
end

---判断当前地图是不是列星虚境地图
---@return boolean @当前地图是否是列星虚境地图
function X.IsInMobaMap()
	local me = X.GetClientPlayer()
	return me and X.IsMobaMap(me.GetMapID())
end

---判断地图是不是浪客行地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是浪客行地图
function X.IsStarveMap(dwMapID)
	return X.CONSTANT.STARVE_MAP[dwMapID] or false
end

---判断当前地图是不是浪客行地图
---@return boolean @当前地图是否是浪客行地图
function X.IsInStarveMap()
	local me = X.GetClientPlayer()
	return me and X.IsStarveMap(me.GetMapID())
end

---判断地图是不是家园地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是家园地图
function X.IsHomelandMap(dwMapID)
	return select(2, GetMapParams(dwMapID)) == MAP_TYPE.HOMELAND
end

---判断当前地图是不是家园地图
---@return boolean @当前地图是否是家园地图
function X.IsInHomelandMap()
	local me = X.GetClientPlayer()
	return me and X.IsHomelandMap(me.GetMapID())
end

---判断地图是不是帮会地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是帮会地图
function X.IsGuildTerritoryMap(dwMapID)
	return dwMapID == 74
end

---判断当前地图是不是帮会地图
---@return boolean @当前地图是否是帮会地图
function X.IsInGuildTerritoryMap()
	local me = X.GetClientPlayer()
	return me and X.IsGuildTerritoryMap(me.GetMapID())
end

do
local ROGUELIKE_MAP = {}
---判断地图是不是八荒衡鉴地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是八荒衡地图
function X.IsRoguelikeMap(dwMapID)
	if ROGUELIKE_MAP[dwMapID] == nil then
		if Table_IsRougeLikeMap then
			ROGUELIKE_MAP[dwMapID] = Table_IsRougeLikeMap(dwMapID) or false
		else
			ROGUELIKE_MAP[dwMapID] = X.CONSTANT.ROGUELIKE_MAP[dwMapID] or false
		end
	end
	return ROGUELIKE_MAP[dwMapID]
end
end

---判断当前地图是不是八荒衡鉴地图
---@return boolean @当前地图是否是八荒衡鉴地图
function X.IsInRoguelikeMap()
	local me = X.GetClientPlayer()
	return me and X.IsRoguelikeMap(me.GetMapID())
end

---判断地图是不是新背包地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是新背包地图
function X.IsInventoryPackageLimitedMap(dwMapID)
	return X.IsPubgMap(dwMapID) or X.IsMobaMap(dwMapID) or X.IsStarveMap(dwMapID)
end

---判断当前地图是不是新背包地图
---@return boolean @当前地图是否是新背包地图
function X.IsInInventoryPackageLimitedMap()
	local me = X.GetClientPlayer()
	return me and X.IsInventoryPackageLimitedMap(me.GetMapID())
end

---判断一个地图是不是比赛地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是比赛地图
function X.IsCompetitionMap(dwMapID)
	return X.IsArenaMap(dwMapID) or X.IsBattlefieldMap(dwMapID)
		or X.IsPubgMap(dwMapID) or X.IsZombieMap(dwMapID)
		or X.IsMobaMap(dwMapID)
		or dwMapID == 173 -- 齐物阁
		or dwMapID == 181 -- 狼影殿
end

---判断当前地图是不是比赛地图
---@return boolean @当前地图是否是比赛地图
function X.IsInCompetitionMap()
	local me = X.GetClientPlayer()
	return me and X.IsCompetitionMap(me.GetMapID())
end

---判断地图是不是功能屏蔽地图
---@param dwMapID number @要判断的地图ID
---@return boolean @是否是功能屏蔽地图
function X.IsShieldedMap(dwMapID)
	if X.IsPubgMap(dwMapID) or X.IsZombieMap(dwMapID) then
		return true
	end
	if IsAddonBanMap and IsAddonBanMap(dwMapID) then
		return true
	end
	return false
end

---判断当前地图是不是功能屏蔽地图
---@return boolean @当前地图是否是功能屏蔽地图
function X.IsInShieldedMap()
	local me = X.GetClientPlayer()
	return me and X.IsShieldedMap(me.GetMapID())
end

---@class GetDungeonMenuOptions @获取秘境菜单参数
---@field tChecked table<number, boolean> @默认选中的秘境
---@field fnAction fun(tMapNameID: table<string, string | number>) @点击时回调函数
---@field bPartyMap boolean @是否包含小队地图
---@field bRaidMap boolean @是否包含团队地图
---@field bHomelandMap boolean @是否包含家园地图
---@field bMonsterMap boolean @是否包含百战地图
---@field bZombieMap boolean @是否包含僵尸地图
---@field bStarveMap boolean @是否包含浪客行地图
do
local function RecruitItemToDungeonMenu(p, tOptions)
	if p.bParent then
		local t = { szOption = p.TypeName or p.SubTypeName }
		for _, pp in ipairs(p) do
			table.insert(t, RecruitItemToDungeonMenu(pp, tOptions))
		end
		if #t > 0 then
			return t
		end
	else
		-- 不限阵营 有地图ID 7点开始 持续24小时 基本就是秘境了
		if p.nCamp == 7
		and p.nStartTime == 7 and p.nLastTime == 24
		and p.dwMapID and X.IsDungeonMap(p.dwMapID)
		and not (tOptions.bPartyMap == false and X.IsDungeonMap(p.dwMapID, false))
		and not (tOptions.bRaidMap == false and X.IsDungeonMap(p.dwMapID, true))
		and not (tOptions.bHomelandMap == false and X.IsHomelandMap(p.dwMapID))
		and not (tOptions.bMonsterMap == false and X.IsMonsterMap(p.dwMapID))
		and not (tOptions.bZombieMap == false and X.IsZombieMap(p.dwMapID))
		and not (tOptions.bStarveMap == false and X.IsStarveMap(p.dwMapID)) then
			return {
				szOption = p.szName,
				bCheck = tOptions.tChecked and true or false,
				bChecked = tOptions.tChecked and tOptions.tChecked[p.dwMapID] or false,
				bDisable = false,
				UserData = {
					dwID = p.dwMapID,
					szName = p.szName,
				},
				fnAction = tOptions.fnAction,
			}
		end
	end
	return nil
end

-- 获取秘境选择菜单
---@param tOptions GetDungeonMenuOptions @额外参数
---@return table @选择菜单数据
function X.GetDungeonMenu(tOptions)
	local t = {}
	for _, p in ipairs(X.Table.GetTeamRecruit() or {}) do
		table.insert(t, RecruitItemToDungeonMenu(p, tOptions or {}))
	end
	return t
end
end

-- 获取推荐的秘境地图列表
---@param bRaid boolean @是否为团队秘境
---@return table @推荐的秘境地图列表
function X.GetRecommendDungeonMapList(bRaid)
	local aMap, tMap = {}, {}
	local me = X.GetClientPlayer()
	if me and Table_GetNewDungeonList then
		local tTeamDungeonList, tRaidDungeonList, tDivideList, tEnterMapList = Table_GetNewDungeonList(me.nLevel)
		-- 小队秘境
		if bRaid == nil or bRaid == false then
			for _, tDungeon in ipairs(tTeamDungeonList) do
				for szTypeName, tInfo in pairs(tDungeon) do
					if X.IsTable(tInfo) then
						if tInfo.bIsRecommend and not tMap[tInfo.dwMapID] then
							table.insert(aMap, {
								dwID = tInfo.dwMapID,
								szName = X.GetMapName(tInfo.dwMapID),
							})
							tMap[tInfo.dwMapID] = true
						end
					end
				end
			end
		end
		-- 团队秘境
		if bRaid == nil or bRaid == true then
			for _, tDungeon in ipairs(tRaidDungeonList) do
				for szTypeName, tInfo in pairs(tDungeon) do
					if X.IsTable(tInfo) then
						if tInfo.bIsRecommend and not tMap[tInfo.dwMapID] then
							table.insert(aMap, {
								dwID = tInfo.dwMapID,
								szName = X.GetMapName(tInfo.dwMapID),
							})
							tMap[tInfo.dwMapID] = true
						end
					end
				end
			end
		end
	end
	table.sort(aMap, function(a, b)
		return a.dwID < b.dwID
	end)
	return aMap
end

function X.GetTypeGroupMap()
	-- 计算地图分组
	local tGroupMap, tMapExist = {}, {}
	local function GroupMapIterator(dwMapID, szGroup, szMapName)
		if szGroup then
			if X.CONSTANT.MAP_MERGE[dwMapID] then
				dwMapID = X.CONSTANT.MAP_MERGE[dwMapID]
			end
			if tMapExist[dwMapID] then
				return
			end
			if not tGroupMap[szGroup] then
				tGroupMap[szGroup] = {}
			end
			table.insert(tGroupMap[szGroup], { dwID = dwMapID, szName = X.IsEmpty(szMapName) and ('#' .. dwMapID) or szMapName })
		end
		tMapExist[dwMapID] = szGroup or 'IGNORE'
	end
	-- 类型排序权重
	local tWeight = {} -- { ['风起稻香'] = 20, ['风起稻香 - 小队秘境'] = 21 }
	local DLCInfo = X.GetGameTable('DLCInfo', true)
	if DLCInfo then
		for i = 2, DLCInfo:GetRowCount() do
			local tLine = DLCInfo:GetRow(i)
			local szVersionName = X.TrimString(tLine.szDLCName)
			tWeight[szVersionName] = 2000 + i * 10
		end
	end
	for i, szVersionName in ipairs(_L.GAME_VERSION_NAME) do
		tWeight[szVersionName] = 1000 + i * 10
	end
	tWeight[_L.MAP_GROUP['Birth / School']] = 100
	tWeight[_L.MAP_GROUP['City / Old city']] = 99
	tWeight[_L.MAP_GROUP['Village / Camp']] = 98
	tWeight[_L.MAP_GROUP['Battle field / Arena']] = 97
	tWeight[_L.MAP_GROUP['Other dungeon']] = 96
	tWeight[_L.MAP_GROUP['Other']] = 95
	-- 获取秘境类型
	local DungeonInfo = X.GetGameTable('DungeonInfo', true)
	if DungeonInfo then
		for i = 2, DungeonInfo:GetRowCount() do
			local tLine = DungeonInfo:GetRow(i)
			local szVersionName = X.TrimString(tLine.szVersionName)
			local szGroup = szVersionName
			if tLine.dwClassID == 1 or tLine.dwClassID == 2 then
				szGroup = szGroup .. ' - ' .. _L['Team dungeon']
				tWeight[szGroup] = (tWeight[szVersionName] or 0) + 2
			elseif tLine.dwClassID == 3 then
				szGroup = szGroup .. ' - ' .. _L['Raid dungeon']
				tWeight[szGroup] = (tWeight[szVersionName] or 0) + 3
			elseif tLine.dwClassID == 4 then
				szGroup = szGroup .. ' - ' .. _L['Duo dungeon']
				tWeight[szGroup] = (tWeight[szVersionName] or 0) + 1
			end
			GroupMapIterator(tLine.dwMapID, szGroup, tLine.szLayer3Name .. tLine.szOtherName)
		end
	end
	-- 非秘境
	local MapList = X.GetGameTable('MapList', true)
	if MapList then
		for i = 2, MapList:GetRowCount() do
			local tLine, szGroup = MapList:GetRow(i), nil
			if tLine.szType == 'BIRTH' or tLine.szType == 'SCHOOL' then
				szGroup = _L.MAP_GROUP['Birth / School']
			elseif tLine.szType == 'CITY' or tLine.szType == 'OLD_CITY' then
				szGroup = _L.MAP_GROUP['City / Old city']
			elseif tLine.szType == 'VILLAGE' or tLine.szType == 'OLD_VILLAGE' then
				szGroup = _L.MAP_GROUP['Village / Camp']
			elseif tLine.szType == 'BATTLE_FIELD' or tLine.szType == 'ARENA' then
				szGroup = _L.MAP_GROUP['Battle field / Arena']
			elseif tLine.szType == 'DUNGEON' or tLine.szType == 'RAID' then
				szGroup = _L.MAP_GROUP['Other dungeon']
			elseif tLine.szType ~= 'TEST' then -- tLine.szType == 'OTHER'
				szGroup = _L.MAP_GROUP['Other']
			end
			GroupMapIterator(tLine.nID, szGroup, tLine.szName)
		end
	end
	-- 逻辑导出表
	for _, dwMapID in ipairs(GetMapList()) do
		GroupMapIterator(
			dwMapID,
			select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
				and _L.MAP_GROUP['Other dungeon']
				or _L.MAP_GROUP['Other'],
			Table_GetMapName(dwMapID))
	end
	-- 哈希转数组
	local aGroup = {}
	for szGroup, aMapInfo in pairs(tGroupMap) do
		table.insert(aGroup, { szGroup = szGroup, aMapInfo = aMapInfo })
	end
	-- 排序
	table.sort(aGroup, function(a, b)
		if not tWeight[a.szGroup] then
			return false
		elseif not tWeight[b.szGroup] then
			return true
		else
			return tWeight[a.szGroup] > tWeight[b.szGroup]
		end
	end)
	return aGroup
end

function X.GetRegionGroupMap()
	local tMapRegion = {}
	local MapList = X.GetGameTable('MapList', true)
	if MapList then
		local nCount = MapList:GetRowCount()
		for i = 2, nCount do
			local tLine = MapList:GetRow(i)
			if tLine.dwRegionID > 0 then
				local dwRegionID = tLine.dwRegionID
				if not tMapRegion[dwRegionID] then
					tMapRegion[dwRegionID] = {}
				end
				local tRegion = tMapRegion[dwRegionID]
				if tLine.nGroup == 4 then -- GROUP_TYPE_COPY
					if tLine.szType == 'RAID' then
						if not tRegion.aRaid then
							tRegion.aRaid = {}
						end
						table.insert(tRegion.aRaid, { dwID = tLine.nID, szName = tLine.szMiddleMap })
					else
						if not tRegion.aDungeon then
							tRegion.aDungeon = {}
						end
						table.insert(tRegion.aDungeon, { dwID = tLine.nID, szName = tLine.szMiddleMap })
					end
				else
					if not tRegion.aMap then
						tRegion.aMap = {}
					end
					table.insert(tRegion.aMap, { dwID = tLine.nID, szName = tLine.szMiddleMap })
				end
			end
		end
	end
	local aRegion = {}
	local RegionMap = X.GetGameTable('RegionMap', true)
	if RegionMap then
		local nCount = RegionMap:GetRowCount()
		for i = 2, nCount do
			local tLine = RegionMap:GetRow(i)
			local info = tMapRegion[tLine.dwRegionID]
			if info then
				table.insert(aRegion, {
					dwID = tLine.dwRegionID,
					szName = tLine.szRegionName,
					aMapInfo = info.aMap,
					aRaidInfo = info.aRaid,
					aDungeonInfo = info.aDungeon,
				})
			end
		end
	end
	return aRegion
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
