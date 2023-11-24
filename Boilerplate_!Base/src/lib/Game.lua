--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- #######################################################################################################
--                                 #                   # # # #   # # # #
--     # # # #   # # # # #       # # # # # # #         #     #   #     #
--     #     #   #       #     #   #       #           # # # #   # # # #
--     #     #   #       #           # # #                     #     #
--     # # # #   #   # #         # #       # #                 #       #
--     #     #   #           # #     #         # #   # # # # # # # # # # #
--     #     #   # # # # #           #                       #   #
--     # # # #   #   #   #     # # # # # # # #           # #       # #
--     #     #   #   #   #         #         #       # #               # #
--     #     #   #     #           #         #         # # # #   # # # #
--     #     #   #   #   #       #           #         #     #   #     #
--   #     # #   # #     #     #         # #           # # # #   # # # #
-- #######################################################################################################

do
local HL_INFO_CACHE = {}
local HL_INFO_CALLBACK = {}
local function FindHLInfo(aList, tQuery)
	for _, info in ipairs(aList) do
		if tQuery.dwMapID and tQuery.nCopyIndex
		and tQuery.dwMapID == info.dwMapID and tQuery.nCopyIndex == info.nCopyIndex then
			return info
		end
		if tQuery.dwCenterID and tQuery.dwMapID and tQuery.nLineIndex
		and tQuery.dwCenterID == info.dwCenterID and tQuery.dwMapID == info.dwMapID and tQuery.nLineIndex == info.nLineIndex then
			return info
		end
	end
end

local GetRelationCenter = _G.GetRelationCenter or _G.HomeLand_GetRelationCenter
X.RegisterEvent('HOME_LAND_RESULT_CODE_INT', 'LIB#HL', function()
	local nResultType = arg0
	if nResultType == X.CONSTANT.HOMELAND_RESULT_CODE.APPLY_COMMUNITY_INFO then -- 申请分线详情
		local dwMapID, nCopyIndex, dwCenterID, nLineIndex = arg1, arg2, arg3, arg4
		local szCenterName
		for _, info in ipairs(X.IsFunction(GetRelationCenter) and GetRelationCenter(dwCenterID) or X.CONSTANT.EMPTY_TABLE) do
			if info.dwCenterID == dwCenterID then
				szCenterName = info.szCenterName
			end
		end
		table.insert(HL_INFO_CACHE, X.SetmetaReadonly({
			dwMapID = dwMapID,
			nCopyIndex = nCopyIndex,
			dwCenterID = dwCenterID,
			szCenterName = szCenterName,
			nLineIndex = nLineIndex,
		}))
		for i, v in X.ipairs_r(HL_INFO_CALLBACK) do
			local info = FindHLInfo(HL_INFO_CACHE, v.tQuery)
			if info then
				X.SafeCall(v.fnCallback, info)
				table.remove(HL_INFO_CALLBACK, i)
			end
		end
	end
end)

local ApplyCommunityInfo = _G.HomeLand_ApplyCommunityInfo
function X.GetHLLineInfo(tQuery, fnCallback)
	local info = FindHLInfo(HL_INFO_CACHE, tQuery)
	if info then
		X.SafeCall(fnCallback, info)
		return info
	end
	if X.IsFunction(ApplyCommunityInfo) and tQuery.dwMapID and tQuery.nCopyIndex then
		table.insert(HL_INFO_CALLBACK, {
			tQuery = tQuery,
			fnCallback = fnCallback,
		})
		if tQuery.nLineIndex then
			ApplyCommunityInfo(tQuery.dwMapID, tQuery.nCopyIndex, tQuery.nLineIndex)
		else
			ApplyCommunityInfo(tQuery.dwMapID, tQuery.nCopyIndex)
		end
	end
end
end

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

do
local O = X.CreateUserSettingsModule('LIB', _L['System'], {
	szDistanceType = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.OneOf('gwwean', 'euclidean','plane'),
		xDefaultValue = 'gwwean',
	},
})
function X.GetGlobalDistanceType()
	return O.szDistanceType
end

function X.SetGlobalDistanceType(szType)
	O.szDistanceType = szType
end

function X.GetDistanceTypeList(bGlobal)
	local t = {
		{ szType = 'gwwean', szText = _L.DISTANCE_TYPE['gwwean'] },
		{ szType = 'euclidean', szText = _L.DISTANCE_TYPE['euclidean'] },
		{ szType = 'plane', szText = _L.DISTANCE_TYPE['plane'] },
	}
	if (bGlobal) then
		table.insert(t, { szType = 'global', szText = _L.DISTANCE_TYPE['global'] })
	end
	return t
end

function X.GetDistanceTypeMenu(bGlobal, eValue, fnAction)
	local t = {}
	for _, p in ipairs(X.GetDistanceTypeList(true)) do
		local t1 = {
			szOption = p.szText,
			bCheck = true, bMCheck = true,
			bChecked = p.szType == eValue,
			UserData = p,
			fnAction = fnAction,
		}
		if p.szType == 'global' then
			t1.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
			t1.nFrame = 105
			t1.nMouseOverFrame = 106
			t1.szLayer = 'ICON_RIGHTMOST'
			t1.fnClickIcon = function()
				X.ShowPanel()
				X.SwitchTab('GlobalConfig')
				X.UI.ClosePopupMenu()
			end
		end
		table.insert(t, t1)
	end
	return t
end
end

-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- X.GetDistance(OObject[, szType])
-- X.GetDistance(nX, nY)
-- X.GetDistance(nX, nY, nZ[, szType])
-- X.GetDistance(OObject1, OObject2[, szType])
-- X.GetDistance(OObject1, nX2, nY2)
-- X.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- X.GetDistance(nX1, nY1, nX2, nY2)
-- X.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': 欧氏距离 (default)
--         'plane'    : 平面距离
--         'gwwean'   : 郭氏距离
--         'global'   : 使用全局配置
function X.GetDistance(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	local szType
	local nX1, nY1, nZ1 = 0, 0, 0
	local nX2, nY2, nZ2 = 0, 0, 0
	if X.IsTable(arg0) then
		arg0 = X.GetObject(X.Unpack(arg0))
		if not arg0 then
			return
		end
	end
	if X.IsTable(arg1) then
		arg1 = X.GetObject(X.Unpack(arg1))
		if not arg1 then
			return
		end
	end
	if X.IsUserdata(arg0) then -- OObject -
		nX1, nY1, nZ1 = arg0.nX, arg0.nY, arg0.nZ
		if X.IsUserdata(arg1) then -- OObject1, OObject2
			nX2, nY2, nZ2, szType = arg1.nX, arg1.nY, arg1.nZ, arg2
		elseif X.IsNumber(arg1) and X.IsNumber(arg2) then -- OObject1, nX2, nY2
			if X.IsNumber(arg3) then -- OObject1, nX2, nY2, nZ2[, szType]
				nX2, nY2, nZ2, szType = arg1, arg2, arg3, arg4
			else -- OObject1, nX2, nY2[, szType]
				nX2, nY2, szType = arg1, arg2, arg3
			end
		else -- OObject[, szType]
			local me = X.GetClientPlayer()
			nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg1
		end
	elseif X.IsNumber(arg0) and X.IsNumber(arg1) then -- nX1, nY1 -
		if X.IsNumber(arg2) then
			if X.IsNumber(arg3) then
				if X.IsNumber(arg4) and X.IsNumber(arg5) then -- nX1, nY1, nZ1, nX2, nY2, nZ2[, szType]
					nX1, nY1, nZ1, nX2, nY2, nZ2, szType = arg0, arg1, arg2, arg3, arg4, arg5, arg6
				else -- nX1, nY1, nX2, nY2[, szType]
					nX1, nY1, nX2, nY2, szType = arg0, arg1, arg2, arg3, arg4
				end
			else -- nX1, nY1, nZ1[, szType]
				local me = X.GetClientPlayer()
				nX1, nY1, nZ1, nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg0, arg1, arg2, arg3
			end
		else -- nX1, nY1
			local me = X.GetClientPlayer()
			nX1, nY1, nX2, nY2 = me.nX, me.nY, arg0, arg1
		end
	end
	if not szType or szType == 'global' then
		szType = X.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return math.max(math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, math.floor(math.abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

do local BUFF_CACHE = {}
function X.GetBuffName(dwBuffID, dwLevel)
	local xKey = dwBuffID
	if dwLevel then
		xKey = dwBuffID .. '_' .. dwLevel
	end
	if not BUFF_CACHE[xKey] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			BUFF_CACHE[xKey] = X.Pack(tLine.szName, tLine.dwIconID)
		else
			local szName = 'BUFF#' .. dwBuffID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			BUFF_CACHE[xKey] = X.Pack(szName, 1436)
		end
	end
	return X.Unpack(BUFF_CACHE[xKey])
end
end

function X.GetBuffIconID(dwBuffID, dwLevel)
	local nIconID = Table_GetBuffIconID(dwBuffID, dwLevel)
	if nIconID ~= -1 then
		return nIconID
	end
end

-- 通过BUFF名称获取BUFF信息
-- (table) X.GetBuffByName(szName)
do local CACHE
function X.GetBuffByName(szName)
	if not CACHE then
		local aCache, tLine, tExist = {}, nil, nil
		local Buff = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Buff', true)
		if Buff then
			for i = 1, Buff:GetRowCount() do
				tLine = Buff:GetRow(i)
				if tLine and tLine.szName then
					tExist = aCache[tLine.szName]
					if not tExist or (tLine.bShow == 1 and tExist.bShow == 0) then
						aCache[tLine.szName] = tLine
					end
				end
			end
		end
		CACHE = aCache
	end
	return CACHE[szName]
end
end

function X.GetEndTime(nEndFrame, bAllowNegative)
	if bAllowNegative then
		return (nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
	end
	return math.max(0, nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
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
				Wnd.CloseWindow('ArenaCorpsPanel')
				OpenArenaCorpsPanel(true, dwID)
			end,
		})
	end
	-- view qixue -- mark target
	if dwID and InsertTargetMenu then
		local tx = {}
		InsertTargetMenu(tx, dwType, dwID, szName)
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.LOOKUP_INFO then
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
	for _, p in ipairs(X.Table_GetTeamRecruit() or {}) do
		table.insert(t, RecruitItemToDungeonMenu(p, tOptions or {}))
	end
	return t
end
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

-- {{武林通鉴 szType 枚举}}
-- WEEK_TEAM_DUNGEON 武林通鉴·秘境
-- WEEK_RAID_DUNGEON 武林通鉴·团队秘境
-- WEEK_PUBLIC_QUEST 武林通鉴·公共任务

-- 获取指定活动任务列表
-- szType枚举值见 @{{武林通鉴 szType 枚举}}
function X.GetActivityQuest(szType)
	local aQuestID = {}
	local me = X.GetClientPlayer()
	local date = TimeToDate(GetCurrentTime())
	local aActive = Table_GetActivityOfDay(date.year, date.month, date.day, ACTIVITY_UI.CALENDER)
	for _, p in ipairs(aActive) do
		if (szType == 'WEEK_TEAM_DUNGEON' and p.szName == _L.ACTIVITY_WEEK_TEAM_DUNGEON)
		or (szType == 'WEEK_RAID_DUNGEON' and p.szName == _L.ACTIVITY_WEEK_RAID_DUNGEON)
		or (szType == 'WEEK_PUBLIC_QUEST' and p.szName == _L.ACTIVITY_WEEK_PUBLIC_QUEST) then
			for _, szQuestID in ipairs(X.SplitString(p.szQuestID, ';')) do
				local tLine = Table_GetCalenderActivityQuest(szQuestID)
				if tLine and tLine.nNpcTemplateID ~= -1 then
					local nQuestID = select(2, me.RandomByDailyQuest(szQuestID, tLine.nNpcTemplateID))
					if nQuestID then
						table.insert(aQuestID, {nQuestID, tLine.nNpcTemplateID})
					end
				end
			end
		end
	end
	return aQuestID
end

-- 获取指定活动地图列表
-- szType枚举值见 @{{武林通鉴 szType 枚举}}
function X.GetActivityMap(szType)
	local aMap = {}
	local aQuestInfo = X.GetActivityQuest(szType)
	for _, p in ipairs(aQuestInfo) do
		local tInfo = p[1] and Table_GetQuestStringInfo(p[1])
		local dwMapID = tInfo and tInfo.dwDungeonID
		local map = dwMapID and X.GetMapInfo(dwMapID)
		if map then
			table.insert(aMap, map)
		end
	end
	return aMap
end

-- 获取秘境CD列表（异步）
-- (table) X.GetMapSaveCopy(fnAction)
-- (number|nil) X.GetMapSaveCopy(dwMapID, fnAction)
do
local QUEUE = {}
local SAVED_COPY_CACHE, REQUEST_FRAME
function X.GetMapSaveCopy(arg0, arg1)
	local dwMapID, fnAction
	if X.IsFunction(arg0) then
		fnAction = arg0
	elseif X.IsNumber(arg0) then
		if X.IsFunction(arg1) then
			fnAction = arg1
		end
		dwMapID = arg0
	end
	if SAVED_COPY_CACHE then
		if dwMapID then
			if fnAction then
				fnAction(SAVED_COPY_CACHE[dwMapID])
			end
			return SAVED_COPY_CACHE[dwMapID]
		else
			if fnAction then
				fnAction(SAVED_COPY_CACHE)
			end
			return SAVED_COPY_CACHE
		end
	else
		if fnAction then
			table.insert(QUEUE, { dwMapID = dwMapID, fnAction = fnAction })
		end
		if REQUEST_FRAME ~= GetLogicFrameCount() then
			ApplyMapSaveCopy()
			REQUEST_FRAME = GetLogicFrameCount()
		end
	end
end

function X.IsDungeonResetable(dwMapID)
	if not SAVED_COPY_CACHE then
		return
	end
	if not X.IsDungeonMap(dwMapID, false) then
		return false
	end
	return SAVED_COPY_CACHE[dwMapID]
end

local function onApplyPlayerSavedCopyRespond()
	SAVED_COPY_CACHE = arg0
	for _, v in ipairs(QUEUE) do
		if v.dwMapID then
			v.fnAction(SAVED_COPY_CACHE[v.dwMapID])
		else
			v.fnAction(SAVED_COPY_CACHE)
		end
	end
	QUEUE = {}
end
X.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', onApplyPlayerSavedCopyRespond)

local function onCopyUpdated()
	SAVED_COPY_CACHE = nil
end
X.RegisterEvent('ON_RESET_MAP_RESPOND', onCopyUpdated)
X.RegisterEvent('ON_MAP_COPY_PROGRESS_UPDATE', onCopyUpdated)
end

-- 获取日常周常下次刷新时间和刷新周期
-- (dwTime, dwCircle) X.GetRefreshTime(szType)
-- @param szType {string} 刷新类型 daily weekly half-weekly
-- @return dwTime {number} 下次刷新时间
-- @return dwCircle {number} 刷新周期
function X.GetRefreshTime(szType)
	local nNextTime, nCircle = 0, 0
	local nTime = GetCurrentTime()
	local date = TimeToDate(nTime)
	if szType == 'daily' then -- 每天7点
		if date.hour < 7 then
			nNextTime = nTime + (7 - date.hour) * 3600 + (0 - date.minute) * 60 + (0 - date.second)
		else
			nNextTime = nTime + (7 + 24 - date.hour) * 3600 + (0 - date.minute) * 60 + (0 - date.second)
		end
		nCircle = 86400
	elseif szType == 'half-weekly' then -- 周一7点 周五7点
		if ((date.weekday == 1 and date.hour >= 7) or date.weekday >= 2)
		and ((date.weekday == 5 and date.hour < 7) or date.weekday <= 4) then -- 周一7点 - 周五7点
			nNextTime = nTime + (5 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
			nCircle = 345600
		else
			if date.weekday == 0 or date.weekday == 1 then -- 周日0点 - 周一7点
				nNextTime = nTime + (1 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
			else -- 周五7点 - 周六24点
				nNextTime = nTime + (8 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
			end
			nCircle = 259200
		end
	else -- if szType == 'weekly' then -- 周一7点
		if date.weekday == 0 or (date.weekday == 1 and date.hour < 7) then -- 周日0点 - 周一7点
			nNextTime = nTime + (1 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
		else -- 周一7点 - 周六24点
			nNextTime = nTime + (8 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
		end
		nCircle = 604800
	end
	return nNextTime, nCircle
end

function X.IsInSameRefreshTime(szType, dwTime)
	local nNextTime, nCircle = X.GetRefreshTime(szType)
	return nNextTime > dwTime and nNextTime - dwTime <= nCircle
end

-- 获取秘境地图刷新时间
-- (number nNextTime, number nCircle) X.GetDungeonRefreshTime(dwMapID)
function X.GetDungeonRefreshTime(dwMapID)
	local _, nMapType, nMaxPlayerCount = GetMapParams(dwMapID)
	if nMapType == MAP_TYPE.DUNGEON then
		if nMaxPlayerCount <= 5 then -- 5人本
			return X.GetRefreshTime('daily')
		end
		if nMaxPlayerCount <= 10 then -- 10人本
			return X.GetRefreshTime('half-weekly')
		end
		if nMaxPlayerCount <= 25 then -- 25人本
			return X.GetRefreshTime('weekly')
		end
	end
	return 0, 0
end

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
	X.SaveLUAData(CUSTOM_PATH, BOSS_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
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
	X.SaveLUAData({'config/inpclist.jx3dat', X.PATH_TYPE.GLOBAL}, INPC_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
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

do
local KUNGFU_NAME_CACHE = {}
local KUNGFU_SHORT_NAME_CACHE = {}
function X.GetKungfuName(dwKungfuID, szType)
	if not KUNGFU_NAME_CACHE[dwKungfuID] then
		KUNGFU_NAME_CACHE[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1) or ''
		KUNGFU_SHORT_NAME_CACHE[dwKungfuID] = X.StringSubW(KUNGFU_NAME_CACHE[dwKungfuID], 1, 2)
	end
	if szType == 'short' then
		return KUNGFU_SHORT_NAME_CACHE[dwKungfuID]
	else
		return KUNGFU_NAME_CACHE[dwKungfuID]
	end
end
end

-------------------------------------------------------------------------------------------------------
--               #     #       #             # #                         #             #             --
--   # # # #     #     #         #     # # #         # # # # # #         #             #             --
--   #     #   #       #               #                 #         #     #     # # # # # # # # #     --
--   #     #   #   # # # #             #                 #         #     #             #             --
--   #   #   # #       #     # # #     # # # # # #       # # # #   #     #       # # # # # # #       --
--   #   #     #       #         #     #     #         #       #   #     #             #             --
--   #     #   #   #   #         #     #     #       #   #     #   #     #   # # # # # # # # # # #   --
--   #     #   #     # #         #     #     #             #   #   #     #           #   #           --
--   #     #   #       #         #     #     #               #     #     #         #     #       #   --
--   # # #     #       #         #   #       #             #             #       # #       #   #     --
--   #         #       #       #   #                     #               #   # #   #   #     #       --
--   #         #     # #     #       # # # # # # #     #             # # #         # #         # #   --
-------------------------------------------------------------------------------------------------------
do
local NEARBY_NPC = {}      -- 附近的NPC
local NEARBY_PET = {}      -- 附近的PET
local NEARBY_BOSS = {}     -- 附近的首领
local NEARBY_PLAYER = {}   -- 附近的物品
local NEARBY_DOODAD = {}   -- 附近的玩家
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
					if X.Table_IsSimplePlayer(KObject.dwTemplateID) then -- 长歌影子
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
				szName = X.Table_GetDoodadTemplateName(KObject.dwTemplateID)
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

do local CACHE = {}
function X.GetFurnitureInfo(szKey, oVal)
	if szKey == 'nRepresentID' then
		szKey = 'dwModelID'
	end
	if not CACHE[szKey] then
		CACHE[szKey] = {}
		local HomelandFurnitureInfo = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('HomelandFurnitureInfo', true)
		if HomelandFurnitureInfo then
			for i = 2, HomelandFurnitureInfo:GetRowCount() do
				local tLine = HomelandFurnitureInfo:GetRow(i)
				if tLine and tLine[szKey] then
					CACHE[szKey][tLine[szKey]] = X.SetmetaReadonly(tLine)
				end
			end
		end
	end
	return CACHE[szKey][oVal]
end
end

do
local GetNearbyFurnitureInfoList = _G.GetNearbyFurnitureInfoList
local HomeLand_GetFurniture2GameID = _G.HomeLand_GetFurniture2GameID
function X.GetNearFurniture(nDis)
	if not nDis then
		nDis = 256
	end
	local nPlaneDis = nDis / 32
	local aFurniture, tID = {}, {}
	if X.IsFunction(GetNearbyFurnitureInfoList) and X.IsFunction(HomeLand_GetFurniture2GameID) then
		for _, p in ipairs(GetNearbyFurnitureInfoList('ui get objects info v_0', nDis)) do
			if X.GetDistance(p.nX, p.nY, p.nZ, 'plane') <= nPlaneDis then
				local dwID = X.NumberBitShl(p.BaseId, 32, 64) + p.InstID
				local info = not tID[dwID] and X.GetFurnitureInfo('nRepresentID', p.RepresentID)
				if info then
					info = setmetatable(p, { __index = info })
					info.dwID = dwID
					info.nInstID = p.InstID
					info.nBaseID = p.BaseId
					info.nGameID = HomeLand_GetFurniture2GameID(p.RepresentID)
					table.insert(aFurniture, info)
					tID[dwID] = true
				end
			end
		end
	end
	return aFurniture
end
end

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

-- 获取玩家自身信息（缓存）
do local m_ClientInfo
function X.GetClientInfo(arg0)
	if arg0 == true or not (m_ClientInfo and m_ClientInfo.dwID) then
		local me = X.GetClientPlayer()
		if me then -- 确保获取到玩家
			if not m_ClientInfo then
				m_ClientInfo = {}
			end
			if not IsRemotePlayer(me.dwID) then -- 确保不在战场
				m_ClientInfo.dwID   = me.dwID
				m_ClientInfo.szName = me.szName
			end
			m_ClientInfo.nX                = me.nX
			m_ClientInfo.nY                = me.nY
			m_ClientInfo.nZ                = me.nZ
			m_ClientInfo.nFaceDirection    = me.nFaceDirection
			m_ClientInfo.szTitle           = me.szTitle
			m_ClientInfo.dwForceID         = me.dwForceID
			m_ClientInfo.nLevel            = me.nLevel
			m_ClientInfo.nExperience       = me.nExperience
			m_ClientInfo.nCurrentStamina   = me.nCurrentStamina
			m_ClientInfo.nCurrentThew      = me.nCurrentThew
			m_ClientInfo.nMaxStamina       = me.nMaxStamina
			m_ClientInfo.nMaxThew          = me.nMaxThew
			m_ClientInfo.nBattleFieldSide  = me.nBattleFieldSide
			m_ClientInfo.dwSchoolID        = me.dwSchoolID
			m_ClientInfo.nCurrentTrainValue= me.nCurrentTrainValue
			m_ClientInfo.nMaxTrainValue    = me.nMaxTrainValue
			m_ClientInfo.nUsedTrainValue   = me.nUsedTrainValue
			m_ClientInfo.nDirectionXY      = me.nDirectionXY
			m_ClientInfo.nCurrentLife      = me.nCurrentLife
			m_ClientInfo.nMaxLife          = me.nMaxLife
			m_ClientInfo.fCurrentLife64,
			m_ClientInfo.fMaxLife64        = X.GetObjectLife(me)
			m_ClientInfo.nMaxLifeBase      = me.nMaxLifeBase
			m_ClientInfo.nCurrentMana      = me.nCurrentMana
			m_ClientInfo.nMaxMana          = me.nMaxMana
			m_ClientInfo.nMaxManaBase      = me.nMaxManaBase
			m_ClientInfo.nCurrentEnergy    = me.nCurrentEnergy
			m_ClientInfo.nMaxEnergy        = me.nMaxEnergy
			m_ClientInfo.nEnergyReplenish  = me.nEnergyReplenish
			m_ClientInfo.bCanUseBigSword   = me.bCanUseBigSword
			m_ClientInfo.nAccumulateValue  = me.nAccumulateValue
			m_ClientInfo.nCamp             = me.nCamp
			m_ClientInfo.bCampFlag         = me.bCampFlag
			m_ClientInfo.bOnHorse          = me.bOnHorse
			m_ClientInfo.nMoveState        = me.nMoveState
			m_ClientInfo.dwTongID          = me.dwTongID
			m_ClientInfo.nGender           = me.nGender
			m_ClientInfo.nCurrentRage      = me.nCurrentRage
			m_ClientInfo.nMaxRage          = me.nMaxRage
			m_ClientInfo.nCurrentPrestige  = me.nCurrentPrestige
			m_ClientInfo.bFightState       = me.bFightState
			m_ClientInfo.nRunSpeed         = me.nRunSpeed
			m_ClientInfo.nRunSpeedBase     = me.nRunSpeedBase
			m_ClientInfo.dwTeamID          = me.dwTeamID
			m_ClientInfo.nRoleType         = me.nRoleType
			m_ClientInfo.nContribution     = me.nContribution
			m_ClientInfo.nCoin             = me.nCoin
			m_ClientInfo.nJustice          = me.nJustice
			m_ClientInfo.nExamPrint        = me.nExamPrint
			m_ClientInfo.nArenaAward       = me.nArenaAward
			m_ClientInfo.nActivityAward    = me.nActivityAward
			m_ClientInfo.bHideHat          = me.bHideHat
			m_ClientInfo.bRedName          = me.bRedName
			m_ClientInfo.dwKillCount       = me.dwKillCount
			m_ClientInfo.nRankPoint        = me.nRankPoint
			m_ClientInfo.nTitle            = me.nTitle
			m_ClientInfo.nTitlePoint       = me.nTitlePoint
			m_ClientInfo.dwPetID           = me.dwPetID
			m_ClientInfo.dwMapID           = me.GetMapID()
			m_ClientInfo.szMapName         = Table_GetMapName(me.GetMapID())
		end
	end
	if not m_ClientInfo then
		return {}
	end
	if X.IsString(arg0) then
		return m_ClientInfo[arg0]
	end
	return m_ClientInfo
end

local function onLoadingEnding()
	X.GetClientInfo(true)
end
X.RegisterEvent('LOADING_ENDING', onLoadingEnding)
end

do
local FRIEND_LIST_BY_ID, FRIEND_LIST_BY_NAME, FRIEND_LIST_BY_GROUP
local function GeneFriendListCache()
	if not FRIEND_LIST_BY_GROUP then
		local me = X.GetClientPlayer()
		if me then
			local infos = me.GetFellowshipGroupInfo()
			if infos then
				FRIEND_LIST_BY_ID = {}
				FRIEND_LIST_BY_NAME = {}
				FRIEND_LIST_BY_GROUP = {{ id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND or '' }} -- 默认分组
				for _, group in ipairs(infos) do
					table.insert(FRIEND_LIST_BY_GROUP, group)
				end
				for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
					for _, p in ipairs(me.GetFellowshipInfo(group.id) or {}) do
						table.insert(group, p)
						FRIEND_LIST_BY_ID[p.id] = p
						FRIEND_LIST_BY_NAME[p.name] = p
					end
				end
				return true
			end
		end
		return false
	end
	return true
end
local function OnFriendListChange()
	FRIEND_LIST_BY_ID = nil
	FRIEND_LIST_BY_NAME = nil
	FRIEND_LIST_BY_GROUP = nil
end
X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , OnFriendListChange)
X.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , OnFriendListChange)
X.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , OnFriendListChange)
X.RegisterEvent('PLAYER_FOE_UPDATE'            , OnFriendListChange)
X.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , OnFriendListChange)
X.RegisterEvent('DELETE_FELLOWSHIP'            , OnFriendListChange)
X.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', OnFriendListChange)
-- 获取好友列表
-- X.GetFriendList()         获取所有好友列表
-- X.GetFriendList(1)        获取第一个分组好友列表
-- X.GetFriendList('挽月堂') 获取分组名称为挽月堂的好友列表
function X.GetFriendList(arg0)
	local t = {}
	local n = 0
	local tGroup = {}
	if GeneFriendListCache() then
		if type(arg0) == 'number' then
			table.insert(tGroup, FRIEND_LIST_BY_GROUP[arg0])
		elseif type(arg0) == 'string' then
			for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
				if group.name == arg0 then
					table.insert(tGroup, X.Clone(group))
				end
			end
		else
			tGroup = FRIEND_LIST_BY_GROUP
		end
		for _, group in ipairs(tGroup) do
			for _, p in ipairs(group) do
				t[p.id], n = X.Clone(p), n + 1
			end
		end
	end
	return t, n
end

-- 获取好友
function X.GetFriend(arg0)
	if arg0 and GeneFriendListCache() then
		if type(arg0) == 'number' then
			return X.Clone(FRIEND_LIST_BY_ID[arg0])
		elseif type(arg0) == 'string' then
			return X.Clone(FRIEND_LIST_BY_NAME[arg0])
		end
	end
end

function X.IsFriend(arg0)
	return X.GetFriend(arg0) and true or false
end
end

do
local FOE_LIST, FOE_LIST_BY_ID, FOE_LIST_BY_NAME
local function GeneFoeListCache()
	if not FOE_LIST then
		local me = X.GetClientPlayer()
		if me then
			FOE_LIST = {}
			FOE_LIST_BY_ID = {}
			FOE_LIST_BY_NAME = {}
			if me.GetFoeInfo then
				local infos = me.GetFoeInfo()
				if infos then
					for i, p in ipairs(infos) do
						FOE_LIST_BY_ID[p.id] = p
						FOE_LIST_BY_NAME[p.name] = p
						table.insert(FOE_LIST, p)
					end
					return true
				end
			end
		end
		return false
	end
	return true
end
local function OnFoeListChange()
	FOE_LIST = nil
	FOE_LIST_BY_ID = nil
	FOE_LIST_BY_NAME = nil
end
X.RegisterEvent('PLAYER_FOE_UPDATE', OnFoeListChange)
-- 获取仇人列表
function X.GetFoeList()
	if GeneFoeListCache() then
		return X.Clone(FOE_LIST)
	end
end
-- 获取仇人
function X.GetFoe(arg0)
	if arg0 and GeneFoeListCache() then
		if type(arg0) == 'number' then
			return FOE_LIST_BY_ID[arg0]
		elseif type(arg0) == 'string' then
			return FOE_LIST_BY_NAME[arg0]
		end
	end
end
end

-- 获取好友列表
function X.GetTongMemberList(bShowOffLine, szSorter, bAsc)
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
function X.GetTongMember(arg0)
	if not arg0 then
		return
	end

	return GetTongClient().GetMemberInfo(arg0)
end

function X.IsTongMember(arg0)
	return X.GetTongMember(arg0) and true or false
end

-- 判断是不是队友
function X.IsParty(dwID)
	if X.IsString(dwID) then
		if dwID == X.GetUserRoleName() then
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
		if X.GetFoe(dwPeerID) then
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
function X.IsEnemy(dwSelfID, dwPeerID)
	return X.GetRelation(dwSelfID, dwPeerID) == 'Enemy'
end

-------------------------------------------------------------------------------------------------------
--       #         #   #                   #             #         #                   #             --
--       #         #     #         #       #             #         #   #               #             --
--       # # #     #                 #     #         #   #         #     #   # # # # # # # # # # #   --
--       #         # # # #             #   #           # #         #                 #   #           --
--       #     # # #           #           #             #   # # # # # # #         #       #         --
--   # # # # #     #   #         #         #             #         #             #     #     #       --
--   #       #     #   #           #       #             #       #   #       # #         #     # #   --
--   #       #     #   #                   # # # #     # #       #   #                 #             --
--   #       #       #       # # # # # # # #         #   #       #   #         #   #     #     #     --
--   # # # # #     # #   #                 #             #     #       #       #   #     #       #   --
--   #           #     # #                 #             #     #       #     #     #         #   #   --
--             #         #                 #             #   #           #           # # # # #       --
-------------------------------------------------------------------------------------------------------
do
local LAST_FIGHT_UUID  = nil
local FIGHT_UUID       = nil
local FIGHT_BEGIN_TICK = -1
local FIGHT_END_TICK   = -1
local FIGHTING         = false
local function ListenFightStateChange()
	-- 判定战斗边界
	if X.IsFighting() then
		-- 进入战斗判断
		if not FIGHTING then
			FIGHTING = true
			-- 5秒脱战判定缓冲 防止明教隐身错误判定
			if not FIGHT_UUID
			or GetTickCount() - FIGHT_END_TICK > 5000 then
				-- 新的一轮战斗开始
				FIGHT_BEGIN_TICK = GetTickCount()
				-- 生成战斗全服唯一标示
				local me = X.GetClientPlayer()
				local team = GetClientTeam()
				local szEdition = X.ENVIRONMENT.GAME_EDITION
				local szServer = X.GetRegionOriginName() .. '_' .. X.GetServerOriginName()
				local dwTime = GetCurrentTime()
				local dwTeamID, nTeamMember, dwTeamXorID = 0, 0, 0
				if team then
					dwTeamID = team.dwTeamID
				end
				if me and team and me.IsInParty() then
					for _, dwTarID in ipairs(team.GetTeamMemberList()) do
						nTeamMember = nTeamMember + 1
						dwTeamXorID = X.NumberBitXor(dwTeamXorID, dwTarID)
					end
				elseif me then
					nTeamMember = 1
					dwTeamXorID = me.dwID
				end
				FIGHT_UUID = szEdition .. '::' .. szServer .. '::' .. dwTime .. '::'
					.. dwTeamID .. '::' .. dwTeamXorID .. '/' .. nTeamMember
					.. '::U' .. me.GetGlobalID() .. '/' .. me.dwID
				FireUIEvent(X.NSFormatString('{$NS}_FIGHT_HINT'), true, FIGHT_UUID, 0)
			end
		end
	else
		-- 退出战斗判定
		if FIGHTING then
			FIGHT_END_TICK, FIGHTING = GetTickCount(), false
		elseif FIGHT_UUID and GetTickCount() - FIGHT_END_TICK > 5000 then
			LAST_FIGHT_UUID, FIGHT_UUID = FIGHT_UUID, nil
			FireUIEvent(X.NSFormatString('{$NS}_FIGHT_HINT'), false, LAST_FIGHT_UUID, FIGHT_END_TICK - FIGHT_BEGIN_TICK)
		end
	end
end
X.BreatheCall(X.NSFormatString('{$NS}#ListenFightStateChange'), ListenFightStateChange)

-- 获取当前战斗时间
function X.GetFightTime(szFormat)
	local nTick = 0
	if FIGHTING then -- 战斗状态
		nTick = GetTickCount() - FIGHT_BEGIN_TICK
	else  -- 脱战状态
		nTick = FIGHT_END_TICK - FIGHT_BEGIN_TICK
	end

	if szFormat then
		local nSeconds = math.floor(nTick / 1000)
		local nMinutes = math.floor(nSeconds / 60)
		local nHours   = math.floor(nMinutes / 60)
		local nMinute  = nMinutes % 60
		local nSecond  = nSeconds % 60
		szFormat = szFormat:gsub('f', math.floor(nTick / 1000 * X.ENVIRONMENT.GAME_FPS))
		szFormat = szFormat:gsub('H', nHours)
		szFormat = szFormat:gsub('M', nMinutes)
		szFormat = szFormat:gsub('S', nSeconds)
		szFormat = szFormat:gsub('hh', string.format('%02d', nHours ))
		szFormat = szFormat:gsub('mm', string.format('%02d', nMinute))
		szFormat = szFormat:gsub('ss', string.format('%02d', nSecond))
		szFormat = szFormat:gsub('h', nHours)
		szFormat = szFormat:gsub('m', nMinute)
		szFormat = szFormat:gsub('s', nSecond)

		if szFormat:sub(1, 1) ~= '0' and tonumber(szFormat) then
			szFormat = tonumber(szFormat)
		end
	else
		szFormat = nTick
	end
	return szFormat
end

-- 获取当前战斗唯一标示符
function X.GetFightUUID()
	return FIGHT_UUID
end

-- 获取上次战斗唯一标示符
function X.GetLastFightUUID()
	return LAST_FIGHT_UUID
end
end

-- 获取自身是否处于逻辑战斗状态
-- (bool) X.IsFighting()
do local ARENA_START = false
function X.IsFighting()
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and X.IsInArenaMap() and ARENA_START then
		bFightState = true
	elseif not bFightState and X.IsInDungeonMap() then
		-- 在秘境且附近队友进战且附近敌对NPC进战则判断处于战斗状态
		local bPlayerFighting, bNpcFighting
		for _, p in ipairs(X.GetNearPlayer()) do
			if me.IsPlayerInMyParty(p.dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for _, p in ipairs(X.GetNearNpc()) do
				if IsEnemy(p.dwID, me.dwID) and p.bFightState then
					bNpcFighting = true
					break
				end
			end
		end
		bFightState = bPlayerFighting and bNpcFighting
	end
	return bFightState
end
X.RegisterEvent('LOADING_ENDING', 'LIB#PLAYER', function() ARENA_START = nil end)
X.RegisterEvent('ARENA_START', 'LIB#PLAYER', function() ARENA_START = true end)
end

-------------------------------------------------------------------------------------------------------------------
--                                   #                                                       #                   --
--   # # # # # # # # # # #         #                               # # # # # # # # #         #     # # # # #     --
--             #             # # # # # # # # # # #       #         #               #         #                   --
--           #               #                   #     #   #       #               #     # # # #                 --
--     # # # # # # # # # #   #                   #     #   #       # # # # # # # # #         #   # # # # # # #   --
--     #     #     #     #   #     # # # # #     #     # # # #     #               #       # #         #         --
--     #     # # # #     #   #     #       #     #   #   #   #     #               #       # # #       #         --
--     #     #     #     #   #     #       #     #   #   #   #     # # # # # # # # #     #   #     #   #   #     --
--     #     # # # #     #   #     #       #     #   #     #       #               #         #     #   #     #   --
--     #     #     #     #   #     # # # # #     #     # #   # #   #               #         #   #     #     #   --
--     # # # # # # # # # #   #                   #                 # # # # # # # # #         #         #         --
--     #                 #   #               # # #                 #               #         #       # #         --
-------------------------------------------------------------------------------------------------------------------
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

function X.GetBagPackageIndex()
	return X.IsInExtraBagMap()
		and INVENTORY_INDEX.LIMITED_PACKAGE
		or INVENTORY_INDEX.PACKAGE
end

function X.GetBagPackageCount()
	if _G.Bag_GetPacketCount then
		return _G.Bag_GetPacketCount()
	end
	return X.IsInExtraBagMap()
		and #X.CONSTANT.INVENTORY_LIMITED_PACKAGE_LIST
		or #X.CONSTANT.INVENTORY_PACKAGE_LIST
end

function X.GetBankPackageCount()
	local me = X.GetClientPlayer()
	return me.GetBankPackageCount() + 1 -- 逻辑写挫了 返回的比真实的少一个
end

-- 获取背包空位总数
-- (number) X.GetFreeBagBoxNum()
function X.GetFreeBagBoxNum()
	local me, nFree = X.GetClientPlayer(), 0
	local nIndex = X.GetBagPackageIndex()
	for i = nIndex, nIndex + X.GetBagPackageCount() do
		nFree = nFree + me.GetBoxFreeRoomSize(i)
	end
	return nFree
end

-- 获取第一个背包空位
-- (number, number) X.GetFreeBagBox()
function X.GetFreeBagBox()
	local me = X.GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	for i = nIndex, nIndex + X.GetBagPackageCount() do
		if me.GetBoxFreeRoomSize(i) > 0 then
			for j = 0, me.GetBoxSize(i) - 1 do
				if not me.GetItem(i, j) then
					return i, j
				end
			end
		end
	end
end

-- 遍历背包物品
-- (number dwBox, number dwX) X.WalkBagItem(fnWalker)
function X.WalkBagItem(fnWalker)
	local me = X.GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local it = me.GetItem(dwBox, dwX)
			if it and fnWalker(it, dwBox, dwX) == 0 then
				return
			end
		end
	end
end

-- 获取一样东西在背包的数量
function X.GetItemAmount(dwTabType, dwIndex, nBookID)
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if nBookID then
		local nBookID, nSegmentID = X.RecipeToSegmentID(nBookID)
		return me.GetItemAmount(dwTabType, dwIndex, nBookID, nSegmentID)
	end
	return me.GetItemAmount(dwTabType, dwIndex)
end

do local CACHE = {}
-- X.GetItemKey(dwTabType, dwIndex, nBookID)
-- X.GetItemKey(KItem)
-- X.GetItemKey(KItemInfo, nBookID)
function X.GetItemKey(dwTabType, dwIndex, nBookID)
	local it, nGenre
	if X.IsUserdata(dwTabType) then
		it, nBookID = dwTabType, dwIndex
		nGenre = it.nGenre
		if not nBookID and nGenre == ITEM_GENRE.BOOK then
			nBookID = it.nBookID or -1
		end
		dwTabType, dwIndex = it.dwTabType, it.dwIndex
	else
		local KItemInfo = GetItemInfo(dwTabType, dwIndex)
		nGenre = KItemInfo and KItemInfo.nGenre
	end
	if not CACHE[dwTabType] then
		CACHE[dwTabType] = {}
	end
	if nGenre == ITEM_GENRE.BOOK then
		if not CACHE[dwTabType][dwIndex] then
			CACHE[dwTabType][dwIndex] = {}
		end
		if not CACHE[dwTabType][dwIndex][nBookID] then
			CACHE[dwTabType][dwIndex][nBookID] = dwTabType .. ',' .. dwIndex .. ',' .. nBookID
		end
		return CACHE[dwTabType][dwIndex][nBookID]
	else
		if not CACHE[dwTabType][dwIndex] then
			CACHE[dwTabType][dwIndex] = dwTabType .. ',' .. dwIndex
		end
		return CACHE[dwTabType][dwIndex]
	end
end
end

do local CACHE, NO_LIMITED_CACHE
local function InsertItem(cache, it)
	if it then
		local szKey = X.GetItemKey(it)
		cache[szKey] = (cache[szKey] or 0) + (it.bCanStack and it.nStackNum or 1)
	end
end
-- 获取一样东西在背包、装备、仓库的数量
-- dwTabType   物品表类型
-- dwIndex     物品在表内地址
-- nBookID     书籍ID
-- bNoLimited  无视地图限制（部分地图内限制使用临时背包）
function X.GetItemAmountInAllPackages(dwTabType, dwIndex, nBookID, bNoLimited)
	if X.IsBoolean(nBookID) then
		nBookID, bNoLimited = nil, nBookID
	end
	if X.IsNil(bNoLimited) then
		bNoLimited = not X.IsInExtraBagMap()
	end
	local cache = CACHE
	if bNoLimited then
		cache = NO_LIMITED_CACHE
	end
	if not cache then
		cache = {}
		local me = X.GetClientPlayer()
		if not me then
			return
		end
		for _, dwBox in ipairs(bNoLimited and X.CONSTANT.INVENTORY_PACKAGE_LIST or X.CONSTANT.INVENTORY_LIMITED_PACKAGE_LIST)  do
			for dwX = 0, me.GetBoxSize(dwBox) - 1 do
				InsertItem(cache, me.GetItem(dwBox, dwX))
			end
		end
		for _, dwBox in ipairs(X.CONSTANT.INVENTORY_BANK_LIST) do
			for dwX = 0,  me.GetBoxSize(dwBox) - 1 do
				InsertItem(cache, GetPlayerItem(me, dwBox, dwX))
			end
		end
		for _, dwBox in ipairs(X.CONSTANT.INVENTORY_EQUIP_LIST) do
			for dwX = 0, EQUIPMENT_INVENTORY.TOTAL - 1 do
				InsertItem(cache, GetPlayerItem(me, dwBox, dwX))
			end
		end
		if bNoLimited then
			NO_LIMITED_CACHE = cache
		else
			CACHE = cache
		end
	end
	return cache[X.GetItemKey(dwTabType, dwIndex, nBookID)] or 0
end
X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE', 'LOADING_ENDING'}, 'LIB#GetItemAmountInAllPackages', function() CACHE, NO_LIMITED_CACHE = nil, nil end)
end

-- 装备指定名字的装备
-- (void) X.Equip(szName)
-- szName  装备名称
function X.Equip(szName)
	X.WalkBagItem(function(it, dwBox, dwX)
		if X.GetItemNameByUIID(it.nUiId) == szName then
			if szName == g_tStrings.tBulletDetail[BULLET_DETAIL.SNARE]
			or szName == g_tStrings.tBulletDetail[BULLET_DETAIL.BOLT] then
				local me = X.GetClientPlayer()
				for nIndex = 0, 15 do
					if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, nIndex) == nil then
						OnExchangeItem(dwBox, dwX, INVENTORY_INDEX.BULLET_PACKAGE, nIndex)
						break
					end
				end
			else
				local nEquipPos = select(2, X.GetClientPlayer().GetEquipPos(dwBox, dwX))
				OnExchangeItem(dwBox, dwX, INVENTORY_INDEX.EQUIP, nEquipPos)
			end
			return 0
		end
	end)
end

-- 使用物品
-- (bool) X.UseItem(szName)
-- (bool) X.UseItem(dwTabType, dwIndex, nBookID)
function X.UseItem(dwTabType, dwIndex, nBookID)
	local bUse = false
	if X.IsString(dwTabType) then
		X.WalkBagItem(function(item, dwBox, dwX)
			if X.GetObjectName('ITEM', item) == dwTabType then
				bUse = true
				OnUseItem(dwBox, dwX)
				return 0
			end
		end)
	else
		X.WalkBagItem(function(item, dwBox, dwX)
			if item.dwTabType == dwTabType and item.dwIndex == dwIndex then
				if item.nGenre == ITEM_GENRE.BOOK and item.nBookID ~= nBookID then
					return
				end
				bUse = true
				OnUseItem(dwBox, dwX)
				return 0
			end
		end)
	end
	return bUse
end

do
-- “气劲下标” 到 “气劲” 的映射缓存
local BUFF_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_PROXY = setmetatable({}, { __mode = 'v' })
-- “目标对象” 到 “气劲列表” 的映射缓存
local BUFF_LIST_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_LIST_PROXY = setmetatable({}, { __mode = 'v' })
-- 缓存保护
local function Reject()
	assert(false, X.NSFormatString('Modify buff list from {$NS}.GetBuffList is forbidden!'))
end
-- 缓存刷新
local function GeneObjectBuffCache(KObject, nTarIndex)
	-- 气劲列表原数据与代理表创建
	local aList, pList = BUFF_LIST_CACHE[KObject], BUFF_LIST_PROXY[KObject]
	if not aList or not pList then
		aList = {}
		pList = setmetatable({}, {
			__index = aList,
			__newindex = Reject,
			__metatable = { const_table = aList },
		})
		BUFF_LIST_CACHE[KObject] = aList
		BUFF_LIST_PROXY[KObject] = pList
	end
	-- 刷新气劲列表缓存
	local nCount, tBuff, pBuff = 0, nil, nil
	for i = 1, KObject.GetBuffCount() or 0 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = KObject.GetBuff(i - 1)
		if dwID then
			tBuff, pBuff = BUFF_CACHE[nIndex], BUFF_PROXY[nIndex]
			if not tBuff or not pBuff then
				tBuff = {}
				pBuff = setmetatable({}, {
					__index = tBuff,
					__newindex = Reject,
					__metatable = { const_table = tBuff },
				})
				BUFF_CACHE[nIndex] = tBuff
				BUFF_PROXY[nIndex] = pBuff
			end
			nCount = nCount + 1
			tBuff.szKey        = dwSkillSrcID .. ':' .. dwID .. ',' .. nLevel
			tBuff.dwID         = dwID
			tBuff.nLevel       = nLevel
			tBuff.bCanCancel   = bCanCancel
			tBuff.nEndFrame    = nEndFrame
			tBuff.nIndex       = nIndex
			tBuff.nStackNum    = nStackNum
			tBuff.dwSkillSrcID = dwSkillSrcID
			tBuff.bValid       = bValid
			tBuff.szName, tBuff.nIcon = X.GetBuffName(dwID, nLevel)
			aList[nCount] = BUFF_PROXY[nIndex]
		end
	end
	-- 删除对象过期气劲缓存
	for i = nCount + 1, aList.nCount or 0 do
		aList[i] = nil
	end
	aList.nCount = nCount
	-- 如果有目标气劲下标，直接返回指定气劲
	if nTarIndex then
		return BUFF_PROXY[nTarIndex]
	end
	return pList, nCount
end

-- 获取对象的buff列表和数量
-- (table, number) X.GetBuffList(KObject)
-- 注意：返回表每帧会重复利用，如有缓存需求请调用X.CloneBuff接口固化数据
function X.GetBuffList(KObject)
	if KObject then
		return GeneObjectBuffCache(KObject)
	end
	return X.CONSTANT.EMPTY_TABLE, 0
end

-- 获取对象的buff
-- tBuff: {[dwID1] = nLevel1, [dwID2] = nLevel2}
-- (table) X.GetBuff(dwID[, nLevel[, dwSkillSrcID]])
-- (table) X.GetBuff(KObject, dwID[, nLevel[, dwSkillSrcID]])
-- (table) X.GetBuff(tBuff[, dwSkillSrcID])
-- (table) X.GetBuff(KObject, tBuff[, dwSkillSrcID])
function X.GetBuff(KObject, dwID, nLevel, dwSkillSrcID)
	local tBuff = {}
	if type(dwID) == 'table' then
		tBuff, dwSkillSrcID = dwID, nLevel
	elseif type(dwID) == 'number' then
		if type(nLevel) == 'number' then
			tBuff[dwID] = nLevel
		else
			tBuff[dwID] = 0
		end
	end
	if X.IsNumber(dwSkillSrcID) and dwSkillSrcID > 0 then
		if KObject.GetBuffByOwner then
			for k, v in pairs(tBuff) do
				local KBuffNode = KObject.GetBuffByOwner(k, v, dwSkillSrcID)
				if KBuffNode then
					return GeneObjectBuffCache(KObject, KBuffNode.nIndex)
				end
			end
		else
			for _, buff in X.ipairs_c(X.GetBuffList(KObject)) do
				if (tBuff[buff.dwID] == buff.nLevel or tBuff[buff.dwID] == 0) and buff.dwSkillSrcID == dwSkillSrcID then
					return buff
				end
			end
		end
	else
		for k, v in pairs(tBuff) do
			local KBuffNode = KObject.GetBuff(k, v)
			if KBuffNode then
				return GeneObjectBuffCache(KObject, KBuffNode.nIndex)
			end
		end
	end
end
end

-- 点掉自己的buff
-- (table) X.CancelBuff(KObject, dwID[, nLevel = 0])
function X.CancelBuff(KObject, dwID, nLevel)
	local KBuffNode = KObject.GetBuff(dwID, nLevel or 0)
	if KBuffNode then
		KObject.CancelBuff(KBuffNode.nIndex)
	end
end

function X.CloneBuff(buff, dst)
	if not dst then
		dst = {}
	end
	dst.szKey = buff.szKey
	dst.dwID = buff.dwID
	dst.nLevel = buff.nLevel
	dst.szName = buff.szName
	dst.nIcon = buff.nIcon
	dst.bCanCancel = buff.bCanCancel
	dst.nEndFrame = buff.nEndFrame
	dst.nIndex = buff.nIndex
	dst.nStackNum = buff.nStackNum
	dst.dwSkillSrcID = buff.dwSkillSrcID
	dst.bValid = buff.bValid
	dst.szName = buff.szName
	dst.nIcon = buff.nIcon
	return dst
end

do
local BUFF_CACHE
function X.IsBossFocusBuff(dwID, nLevel, nStackNum)
	if not BUFF_CACHE then
		BUFF_CACHE = {}
		local BossFocusBuff = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('BossFocusBuff', true)
		if BossFocusBuff then
			if BossFocusBuff then
				for i = 2, BossFocusBuff:GetRowCount() do
					local tLine = BossFocusBuff:GetRow(i)
					if tLine then
						if not BUFF_CACHE[tLine.nBuffID] then
							BUFF_CACHE[tLine.nBuffID] = {}
						end
						BUFF_CACHE[tLine.nBuffID][tLine.nBuffLevel] = tLine.nBuffStack
					end
				end
			end
		end
	end
	return BUFF_CACHE[dwID] and BUFF_CACHE[dwID][nLevel] and nStackNum >= BUFF_CACHE[dwID][nLevel]
end
end

function X.IsVisibleBuff(dwID, nLevel)
	if Table_BuffIsVisible(dwID, nLevel) then
		return true
	end
	if X.IsBossFocusBuff(dwID, nLevel, 0xffff) then
		return true
	end
	return false
end

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

-- 获取对象运功状态
do local bNewAPI
function X.GetOTActionState(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return
	end
	local nType, dwSkillID, dwSkillLevel, fCastPercent
	if X.IsNil(bNewAPI) then
		local eType = X.GetObjectType(KObject)
		if eType == 'PLAYER' or eType == 'NPC' then
			bNewAPI = pcall(function()
				if not KObject.GetSkillOTActionState then
					assert(false)
				end
			end)
		end
	end
	if bNewAPI then
		nType, dwSkillID, dwSkillLevel, fCastPercent = KObject.GetSkillOTActionState()
	else
		nType, dwSkillID, dwSkillLevel, fCastPercent = KObject.GetSkillPrepareState()
		nType = KObject.GetOTActionState()
	end
	return nType, dwSkillID, dwSkillLevel, fCastPercent
end
end

-- 获取对象当前是否可读条
-- (bool) X.CanOTAction([object KObject])
function X.CanOTAction(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return
	end
	return KObject.nMoveState == MOVE_STATE.ON_STAND or KObject.nMoveState == MOVE_STATE.ON_FLOAT
end

-- 通过技能名称获取技能信息
-- (table) X.GetSkillByName(szName)
do local CACHE
function X.GetSkillByName(szName)
	if not CACHE then
		local aCache, tLine, tExist = {}, nil, nil
		local Skill = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Skill', true)
		if Skill then
			for i = 1, Skill:GetRowCount() do
				tLine = Skill:GetRow(i)
				if tLine and tLine.dwIconID and tLine.fSortOrder and tLine.szName then
					tExist = aCache[tLine.szName]
					if not tExist or tLine.fSortOrder > tExist.fSortOrder then
						aCache[tLine.szName] = tLine
					end
				end
			end
		end
		CACHE = aCache
	end
	return CACHE[szName]
end
end

-- 判断技能名称是否有效
-- (bool) X.IsValidSkill(szName)
function X.IsValidSkill(szName)
	if X.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) X.CanUseSkill(number dwSkillID[, dwLevel])
do
local box
function X.CanUseSkill(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == 'string' then
		if not X.IsValidSkill(dwSkillID) then
			return false
		end
		dwSkillID = X.GetSkillByName(dwSkillID).dwSkillID
	end
	if not box or not box:IsValid() then
		box = X.UI.GetTempElement('Box', X.NSFormatString('{$NS}Lib__Skill'))
	end
	local me = X.GetClientPlayer()
	if me and box then
		if not dwLevel then
			if dwSkillID ~= 9007 then
				dwLevel = me.GetSkillLevel(dwSkillID)
			else
				dwLevel = 1
			end
		end
		if dwLevel > 0 then
			box:EnableObject(false)
			box:SetObjectCoolDown(1)
			box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
			UpdataSkillCDProgress(me, box)
			return box:IsObjectEnable() and not box:IsObjectCoolDown()
		end
	end
	return false
end
end

-- 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）
-- (string, number) X.GetSkillName(number dwSkillID[, number dwLevel])
do local SKILL_CACHE = {} -- 技能列表缓存 技能ID查技能名称图标
function X.GetSkillName(dwSkillID, dwLevel)
	local uLevelKey = dwLevel or '*'
	if not SKILL_CACHE[dwSkillID] then
		SKILL_CACHE[dwSkillID] = {}
	end
	if not SKILL_CACHE[dwSkillID][uLevelKey] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (X.StringFindW(tLine.szDesc, '_') == nil  or X.StringFindW(tLine.szDesc, '<') ~= nil)
		then
			SKILL_CACHE[dwSkillID][uLevelKey] = X.Pack(tLine.szName, tLine.dwIconID)
		else
			local szName = 'SKILL#' .. dwSkillID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			SKILL_CACHE[dwSkillID][uLevelKey] = X.Pack(szName, 13)
		end
	end
	return X.Unpack(SKILL_CACHE[dwSkillID][uLevelKey])
end
end

function X.GetSkillIconID(dwSkillID, dwLevel)
	local nIconID = Table_GetSkillIconID(dwSkillID, dwLevel)
	if nIconID ~= -1 then
		return nIconID
	end
end

do
local CACHE = {}
local REPLACE = {}
local function OnSkillReplace()
	for _, aList in pairs(CACHE) do
		for _, group in ipairs(aList) do
			for i, v in ipairs(group) do
				if v == arg0 then
					group[i] = arg1
				end
			end
		end
	end
	CACHE = {}
	REPLACE[arg0] = arg1
	REPLACE[arg1] = nil
end
RegisterEvent('ON_SKILL_REPLACE', OnSkillReplace)
RegisterEvent('CHANGE_SKILL_ICON', OnSkillReplace)

-- 获取一个心法的技能列表
-- X.GetKungfuSkillIDs(dwKungfuID)
-- 获取一个套路的技能列表
-- X.GetKungfuSkillIDs(dwKungfuID, dwMountKungfu)
function X.GetKungfuSkillIDs(dwKungfuID, dwMountKungfu)
	if not dwMountKungfu then
		dwMountKungfu = 0
	end
	if not (CACHE[dwKungfuID] and CACHE[dwKungfuID][dwMountKungfu]) then
		local aSkillID
		if not X.IsEmpty(dwMountKungfu) then -- 获取一个套路的技能列表
			if X.IsFunction(_G.Table_GetNewKungfuSkill) then -- 兼容旧版
				aSkillID = _G.Table_GetNewKungfuSkill(dwKungfuID, dwMountKungfu)
					or _G.Table_GetKungfuSkillList(dwMountKungfu)
			else
				aSkillID = Table_GetKungfuSkillList(dwMountKungfu, dwKungfuID)
			end
		else -- 获取一个心法的技能列表 遍历该心法的所有套路
			if X.IsFunction(_G.Table_GetNewKungfuSkill) and X.IsFunction(_G.Table_GetKungfuSkillList) then -- 兼容旧版
				aSkillID = _G.Table_GetKungfuSkillList(dwKungfuID)
			else
				aSkillID = {}
				for _, dwMKungfuID in ipairs(X.GetMKungfuIDs(dwKungfuID)) do
					for _, dwSkillID in ipairs(X.GetKungfuSkillIDs(dwKungfuID, dwMKungfuID)) do
						table.insert(aSkillID, dwSkillID)
					end
				end
			end
		end
		for i, dwSkillID in ipairs(aSkillID) do
			if REPLACE[dwSkillID] then
				aSkillID[i] = REPLACE[dwSkillID]
			end
		end
		if not CACHE[dwKungfuID] then
			CACHE[dwKungfuID] = {}
		end
		CACHE[dwKungfuID][dwMountKungfu] = aSkillID or {}
	end
	return CACHE[dwKungfuID][dwMountKungfu]
end
end

-- 获取内功心法子套路列表（P面板左侧每列标题即为套路名）
do local CACHE = {}
function X.GetMKungfuIDs(dwKungfuID)
	if not CACHE[dwKungfuID] then
		CACHE[dwKungfuID] = Table_GetMKungfuList(dwKungfuID) or X.CONSTANT.EMPTY_TABLE
	end
	return CACHE[dwKungfuID]
end
end

do local CACHE = {}
function X.GetForceKungfuIDs(dwForceID)
	if not CACHE[dwForceID] then
		if X.IsFunction(_G.Table_GetSkillSchoolKungfu) then
			-- 这个API真是莫名其妙，明明是Force-Kungfu对应表，标题非写成School-Kungfu对应表
			CACHE[dwForceID] = _G.Table_GetSkillSchoolKungfu(dwForceID) or {}
		else
			local aKungfuList = {}
			local SkillSchoolKungfu = X.GetGameTable('SkillSchoolKungfu', true)
			if SkillSchoolKungfu then
				local tLine = SkillSchoolKungfu:Search(dwForceID)
				if tLine then
					local szKungfu = tLine.szKungfu
					for s in string.gmatch(szKungfu, '%d+') do
						local dwID = tonumber(s)
						if dwID then
							table.insert(aKungfuList, dwID)
						end
					end
				end
			end
			CACHE[dwForceID] = aKungfuList
		end
	end
	return CACHE[dwForceID]
end
end

do local CACHE = {}
function X.GetSchoolForceID(dwSchoolID)
	if not CACHE[dwSchoolID] then
		if X.IsFunction(_G.Table_SchoolToForce) then
			CACHE[dwSchoolID] = _G.Table_SchoolToForce(dwSchoolID) or 0
		else
			local ForceToSchool = X.GetGameTable('ForceToSchool', true)
			if ForceToSchool then
				local nCount = ForceToSchool:GetRowCount()
				local dwForceID = 0
				for i = 1, nCount do
					local tLine = ForceToSchool:GetRow(i)
					if dwSchoolID == tLine.dwSchoolID then
						dwForceID = tLine.dwForceID
					end
				end
				CACHE[dwSchoolID] = dwForceID or 0
			end
		end
	end
	return CACHE[dwSchoolID]
end
end

function X.GetTargetSkillIDs(tar)
	local aSchoolID, aSkillID = tar.GetSchoolList(), {}
	for _, dwSchoolID in ipairs(aSchoolID) do
		local dwForceID = X.GetSchoolForceID(dwSchoolID)
		local aKungfuID = X.GetForceKungfuIDs(dwForceID)
		for _, dwKungfuID in ipairs(aKungfuID) do
			for _, dwSkillID in ipairs(X.GetKungfuSkillIDs(dwKungfuID)) do
				table.insert(aSkillID, dwSkillID)
			end
		end
	end
	return aSkillID
end

do
local LIST, LIST_ALL
function X.GetSkillMountList(bIncludePassive)
	if not LIST then
		LIST, LIST_ALL = {}, {}
		local me = X.GetClientPlayer()
		local aList = X.GetTargetSkillIDs(me)
		for _, dwID in ipairs(aList) do
			local nLevel = me.GetSkillLevel(dwID)
			if nLevel > 0 then
				local KSkill = GetSkill(dwID, nLevel)
				if not KSkill.bIsPassiveSkill then
					table.insert(LIST, dwID)
				end
				table.insert(LIST_ALL, dwID)
			end
		end
	end
	return bIncludePassive and LIST_ALL or LIST
end

local function onKungfuChange()
	LIST, LIST_ALL = nil, nil
end
X.RegisterEvent('SKILL_MOUNT_KUNG_FU', onKungfuChange)
X.RegisterEvent('SKILL_UNMOUNT_KUNG_FU', onKungfuChange)
end

-- 判断两个心法ID是不是同一心法，藏剑视为单心法
function X.IsSameKungfu(dwID1, dwID2)
	if dwID1 == dwID2 then
		return true
	end
	if X.CONSTANT.KUNGFU_FORCE_TYPE[dwID1] == X.CONSTANT.FORCE_TYPE.CANG_JIAN
	and X.CONSTANT.KUNGFU_FORCE_TYPE[dwID2] == X.CONSTANT.FORCE_TYPE.CANG_JIAN then
		return true
	end
	return false
end

do
local SKILL_CACHE = setmetatable({}, { __mode = 'v' })
local SKILL_PROXY = setmetatable({}, { __mode = 'v' })
local function reject() assert(false, 'Modify skill info from X.GetSkill is forbidden!') end
function X.GetSkill(dwID, nLevel)
	if nLevel == 0 then
		return
	end
	local KSkill = GetSkill(dwID, nLevel)
	if not KSkill then
		return
	end
	local szKey = dwID .. '#' .. nLevel
	if not SKILL_CACHE[szKey] or not SKILL_PROXY[szKey] then
		SKILL_CACHE[szKey] = {
			szKey = szKey,
			szName = X.GetSkillName(dwID, nLevel),
			dwID = dwID,
			nLevel = nLevel,
			bLearned = nLevel > 0,
			nIcon = Table_GetSkillIconID(dwID, nLevel),
			dwExtID = X.Table_GetSkillExtCDID(dwID),
			bFormation = Table_IsSkillFormation(dwID, nLevel),
		}
		SKILL_PROXY[szKey] = setmetatable({}, { __index = SKILL_CACHE[szKey], __newindex = reject })
	end
	return KSkill, SKILL_PROXY[szKey]
end
end

do
local SKILL_SURFACE_NUM = {}
local function OnChangeSkillSurfaceNum()
	SKILL_SURFACE_NUM[arg0] = arg1
end
RegisterEvent('CHANGE_SKILL_SURFACE_NUM', OnChangeSkillSurfaceNum)
local function GetSkillCDProgress(dwID, nLevel, dwCDID, KObject)
	if dwCDID then
		return KObject.GetSkillCDProgress(dwID, nLevel, dwCDID)
	else
		return KObject.GetSkillCDProgress(dwID, nLevel)
	end
end
function X.GetSkillCDProgress(KObject, dwID, nLevel, bIgnorePublic)
	if not X.IsUserdata(KObject) then
		KObject, dwID, nLevel = X.GetClientPlayer(), KObject, dwID
	end
	if not nLevel then
		nLevel = KObject.GetSkillLevel(dwID)
	end
	if not nLevel then
		return
	end
	local KSkill, info = X.GetSkill(dwID, nLevel)
	if not KSkill or not info then
		return
	end
	-- # 更新CD相关的所有东西
	-- -- 附加技能CD
	-- if info.dwExtID then
	-- 	info.skillExt = X.GetTargetSkill(KObject, info.dwExtID)
	-- end
	-- 充能和透支技能CD刷新
	local nCDMaxCount, dwCDID = KObject.GetCDMaxCount(dwID)
	local nODMaxCount, dwODID = KObject.GetCDMaxOverDraftCount(dwID)
	local _, bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum, bPublic
	if nCDMaxCount > 1 then -- 充能技能CD刷新
		szType = 'CHARGE'
		nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, dwCDID, KObject))
		nInterval = KObject.GetCDInterval(dwCDID)
		nTotal = nInterval
		nLeft, nCount = KObject.GetCDLeft(dwCDID)
		bCool = nLeft > 0
		nCount = nCDMaxCount - nCount
		nMaxCount = nCDMaxCount
	elseif nODMaxCount > 1 then -- 透支技能CD刷新
		szType = 'OVERDRAFT'
		bCool, nLeft, nTotal, nCount, bPublic = GetSkillCDProgress(dwID, nLevel, dwODID, KObject)
		nInterval = KObject.GetCDInterval(dwODID)
		nMaxCount, nCount = KObject.GetOverDraftCoolDown(dwODID)
		if nCount == nMaxCount then -- 透支用完了显示CD
			bCool, nLeft, nTotal, _, bPublic = GetSkillCDProgress(dwID, nLevel, nil, KObject)
		else
			bCool, nLeft, nTotal = false, select(2, GetSkillCDProgress(dwID, nLevel, nil, KObject))
		end
	else -- 普通技能CD刷新
		szType = 'NORMAL'
		if bIgnorePublic then
			nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, dwCDID, KObject))
		else
			nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, nil, KObject))
		end
		bCool = nLeft > 0
		nInterval = nTotal
		nCount, nMaxCount = bCool and 1 or 0, 1
	end
	if bPublic then
		szType = 'PUBLIC'
	end
	nSurfaceNum = SKILL_SURFACE_NUM[dwID]

	-- -- 指定BUFF存在时技能显示特定特效的需求
	-- local tLine = Table_GetSkillEffectBySkill(dwID)
	-- if tLine then
	-- 	local bShow = not not KObject.GetBuff(tLine.dwBuffID, 0)
	-- 	if bShow then
	-- 		if tLine.bAnimate then
	-- 			hBox:SetExtentAnimate(tLine.szUITex, tLine.nFrame)
	-- 		else
	-- 			hBox:SetExtentImage(tLine.szUITex, tLine.nFrame)
	-- 		end
	-- 	else
	-- 		hBox:ClearExtentAnimate()
	-- 	end
	-- end
	return bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum
end
end

-- 秘笈是否激活 全名/短名
do
local RECIPE_CACHE = {}
local function onRecipeUpdate()
	RECIPE_CACHE = {}
end
X.RegisterEvent({'SYNC_ROLE_DATA_END', 'SKILL_UPDATE', 'SKILL_RECIPE_LIST_UPDATE'}, onRecipeUpdate)

local function GetShortName(sz) -- 获取秘笈短名
	local nStart, nEnd = string.find(sz, '·')
	return nStart and X.StringReplaceW(string.sub(sz, nEnd + 1), _L['>'], '')
end

function X.IsRecipeActive(szRecipeName)
	local me = X.GetClientPlayer()
	if not RECIPE_CACHE[szRecipeName] then
		if not me then
			return
		end

		for id, lv in pairs(me.GetAllSkillList())do
			for _, info in pairs(me.GetSkillRecipeList(id, lv) or {}) do
				local t = Table_GetSkillRecipe(info.recipe_id , info.recipe_level)
				if t and (szRecipeName == t.szName or szRecipeName == GetShortName(t.szName)) then
					RECIPE_CACHE[szRecipeName] = info.active and 1 or 0
					break
				end
			end

			if RECIPE_CACHE[szRecipeName] then
				break
			end
		end

		if not RECIPE_CACHE[szRecipeName] then
			RECIPE_CACHE[szRecipeName] = 0
		end
	end

	return RECIPE_CACHE[szRecipeName] == 1
end
end

-- 登出游戏
-- (void) X.Logout(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
function X.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) X.GetChannelSkillFrame(number dwSkillID, number nLevel)
function X.GetChannelSkillFrame(dwSkillID, nLevel)
	local skill = GetSkill(dwSkillID, nLevel)
	if skill then
		return skill.nChannelFrame
	end
end

function X.IsMarker(...)
	local dwID = select('#', ...) == 0 and X.GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == dwID
end

function X.IsLeader(...)
	local dwID = select('#', ...) == 0 and X.GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == dwID
end

function X.IsDistributor(...)
	local dwID = select('#', ...) == 0 and X.GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == dwID
end
X.IsDistributer = X.IsDistributor

-- 判断自己在不在队伍里
-- (bool) X.IsInParty()
function X.IsInParty()
	local me = X.GetClientPlayer()
	return me and me.IsInParty()
end

-- 判断自己在不在团队里
-- (bool) X.IsInRaid()
function X.IsInRaid()
	local me = X.GetClientPlayer()
	return me and me.IsInRaid()
end

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
		MAP_LIST = X.SetmetaReadonly(MAP_LIST)
	end
	return MAP_LIST
end

-- 获取一个地图的信息
-- (table) X.GetMapInfo(dwMapID)
-- (table) X.GetMapInfo(szMapName)
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

-- 获取主角当前所在地图
-- (number) X.GetMapID(bool bFix) 是否做修正
function X.GetMapID(bFix)
	local dwMapID = X.GetClientPlayer().GetMapID()
	return bFix and X.CONSTANT.MAP_MERGE[dwMapID] or dwMapID
end

do
local ARENA_MAP
-- 判断一个地图是不是名剑大会地图
-- (bool) X.IsArenaMap(dwID)
function X.IsArenaMap(dwID)
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
			X.ENVIRONMENT.GAME_BRANCH == 'classic' and {f = 'i', t = 'nIs1V1'} or false,
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
	return ARENA_MAP[dwID]
end
end

-- 判断当前地图是不是名剑大会地图
-- (bool) X.IsInArenaMap()
function X.IsInArenaMap()
	local me = X.GetClientPlayer()
	return me and X.IsArenaMap(me.GetMapID())
end

-- 判断一个地图是不是战场地图
-- (bool) X.IsBattlefieldMap(dwMapID)
function X.IsBattlefieldMap(dwMapID)
	return select(2, GetMapParams(dwMapID)) == MAP_TYPE.BATTLE_FIELD and not X.IsArenaMap(dwMapID)
end

-- 判断当前地图是不是战场地图
-- (bool) X.IsInBattlefieldMap()
function X.IsInBattlefieldMap()
	local me = X.GetClientPlayer()
	return me and X.IsBattlefieldMap(me.GetMapID())
end

-- 判断一个地图是不是秘境地图
-- (bool) X.IsDungeonMap(szMapName, bRaid)
-- (bool) X.IsDungeonMap(dwMapID, bRaid)
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

-- 判断当前地图是不是秘境地图
-- (bool) X.IsInDungeonMap(bool bRaid)
function X.IsInDungeonMap(bRaid)
	local me = X.GetClientPlayer()
	return me and X.IsDungeonMap(me.GetMapID(), bRaid)
end

-- 判断一个地图是不是个人CD秘境地图
-- (bool) X.IsDungeonRoleProgressMap(dwMapID)
function X.IsDungeonRoleProgressMap(dwMapID)
	return (select(8, GetMapParams(dwMapID)))
end

-- 判断当前地图是不是个人CD秘境地图
-- (bool) X.IsInDungeonRoleProgressMap()
function X.IsInDungeonRoleProgressMap()
	local me = X.GetClientPlayer()
	return me and X.IsDungeonRoleProgressMap(me.GetMapID())
end

-- 判断一个地图是不是主城地图
-- (bool) X.IsCityMap(dwMapID)
function X.IsCityMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.CITY and true or false
end

-- 判断当前地图是不是主城地图
-- (bool) X.IsInCityMap()
function X.IsInCityMap()
	local me = X.GetClientPlayer()
	return me and X.IsCityMap(me.GetMapID())
end

-- 判断一个地图是不是野外地图
-- (bool) X.IsVillageMap(dwMapID)
function X.IsVillageMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.VILLAGE and true or false
end

-- 判断当前地图是不是野外地图
-- (bool) X.IsInVillageMap()
function X.IsInVillageMap()
	local me = X.GetClientPlayer()
	return me and X.IsVillageMap(me.GetMapID())
end

-- 判断地图是不是PUBG地图
-- (bool) X.IsPubgMap(dwMapID)
do
local PUBG_MAP = {}
function X.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = X.Table_IsTreasureBattleFieldMap(dwMapID) or false
	end
	return PUBG_MAP[dwMapID]
end
end

-- 判断当前地图是不是PUBG地图
-- (bool) X.IsInPubgMap()
function X.IsInPubgMap()
	local me = X.GetClientPlayer()
	return me and X.IsPubgMap(me.GetMapID())
end

-- 判断地图是不是僵尸地图
-- (bool) X.IsZombieMap(dwMapID)
do
local ZOMBIE_MAP = {}
function X.IsZombieMap(dwMapID)
	if ZOMBIE_MAP[dwMapID] == nil then
		ZOMBIE_MAP[dwMapID] = Table_IsZombieBattleFieldMap
			and Table_IsZombieBattleFieldMap(dwMapID) or false
	end
	return ZOMBIE_MAP[dwMapID]
end
end

-- 判断当前地图是不是僵尸地图
-- (bool) X.IsInZombieMap()
function X.IsInZombieMap()
	local me = X.GetClientPlayer()
	return me and X.IsZombieMap(me.GetMapID())
end

-- 判断地图是不是百战地图
-- (bool) X.IsMonsterMap(dwMapID)
do
local MONSTER_MAP = {}
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

-- 判断当前地图是不是百战地图
-- (bool) X.IsInMonsterMap()
function X.IsInMonsterMap()
	local me = X.GetClientPlayer()
	return me and X.IsMonsterMap(me.GetMapID())
end

-- 判断地图是不是MOBA地图
-- (bool) X.IsMobaMap(dwMapID)
function X.IsMobaMap(dwMapID)
	return X.CONSTANT.MOBA_MAP[dwMapID] or false
end

-- 判断当前地图是不是MOBA地图
-- (bool) X.IsInMobaMap()
function X.IsInMobaMap()
	local me = X.GetClientPlayer()
	return me and X.IsMobaMap(me.GetMapID())
end

-- 判断地图是不是浪客行地图
-- (bool) X.IsStarveMap(dwMapID)
function X.IsStarveMap(dwMapID)
	return X.CONSTANT.STARVE_MAP[dwMapID] or false
end

-- 判断当前地图是不是浪客行地图
-- (bool) X.IsInStarveMap()
function X.IsInStarveMap()
	local me = X.GetClientPlayer()
	return me and X.IsStarveMap(me.GetMapID())
end

-- 判断地图是不是家园地图
-- (bool) X.IsHomelandMap(dwMapID)
function X.IsHomelandMap(dwMapID)
	return select(2, GetMapParams(dwMapID)) == MAP_TYPE.COMMUNITY
end

-- 判断当前地图是不是家园地图
-- (bool) X.IsInHomelandMap()
function X.IsInHomelandMap()
	local me = X.GetClientPlayer()
	return me and X.IsHomelandMap(me.GetMapID())
end

-- 判断地图是不是八荒衡鉴地图
-- (bool) X.IsMonsterMap(dwMapID)
do
local ROGUELIKE_MAP = {}
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

-- 判断当前地图是不是八荒衡鉴地图
-- (bool) X.IsInMonsterMap()
function X.IsInRoguelikeMap()
	local me = X.GetClientPlayer()
	return me and X.IsRoguelikeMap(me.GetMapID())
end

-- 判断地图是不是新背包地图
-- (bool) X.IsExtraBagMap(dwMapID)
function X.IsExtraBagMap(dwMapID)
	return X.IsPubgMap(dwMapID) or X.IsMobaMap(dwMapID) or X.IsStarveMap(dwMapID)
end

-- 判断当前地图是不是新背包地图
-- (bool) X.IsInExtraBagMap()
function X.IsInExtraBagMap()
	local me = X.GetClientPlayer()
	return me and X.IsExtraBagMap(me.GetMapID())
end

-- 判断一个地图是不是比赛地图
-- (bool) X.IsCompetitionMap(dwMapID)
function X.IsCompetitionMap(dwMapID)
	return X.IsArenaMap(dwMapID) or X.IsBattlefieldMap(dwMapID)
		or X.IsPubgMap(dwMapID) or X.IsZombieMap(dwMapID)
		or X.IsMobaMap(dwMapID)
		or dwMapID == 173 -- 齐物阁
		or dwMapID == 181 -- 狼影殿
end

-- 判断当前地图是不是比赛地图
-- (bool) X.IsInCompetitionMap()
function X.IsInCompetitionMap()
	local me = X.GetClientPlayer()
	return me and X.IsCompetitionMap(me.GetMapID())
end

-- 判断地图是不是功能屏蔽地图
-- (bool) X.IsShieldedMap(dwMapID)
function X.IsShieldedMap(dwMapID)
	if X.IsPubgMap(dwMapID) or X.IsZombieMap(dwMapID) then
		return true
	end
	if IsAddonBanMap and IsAddonBanMap(dwMapID) then
		return true
	end
	return false
end

-- 判断当前地图是不是功能屏蔽地图
-- (bool) X.IsInShieldedMap()
function X.IsInShieldedMap()
	local me = X.GetClientPlayer()
	return me and X.IsShieldedMap(me.GetMapID())
end

-- 设置标记目标
---@param nMark number @标记索引
---@param dwID number @目标ID
---@return boolean @是否成功
function X.SetTeamMarkTarget(nMark, dwID)
	local npc = not X.IsPlayer(dwID) and X.GetNpc(dwID) or nil
	if npc and X.IsShieldedNpc(npc.dwTemplateID) then
		return false
	end
	return GetClientTeam().SetTeamMark(nMark, dwID) or false
end

-- 获取所有标记目标
---@return table @所有标记目标
function X.GetTeamMark()
	if not X.IsInParty() then
		return X.CONSTANT.EMPTY_TABLE
	end
	return GetClientTeam().GetTeamMark() or X.CONSTANT.EMPTY_TABLE
end

-- 获取标记目标
---@param nMark number @标记索引
---@return number @目标ID
function X.GetTeamMarkTarget(nMark)
	local tMark = X.GetTeamMark()
	return tMark[nMark]
end

-- 获取目标标记
---@param dwID number @目标ID
---@return number @标记索引
function X.GetTargetTeamMark(dwID)
	if not X.IsInParty() then
		return
	end
	return GetClientTeam().GetMarkIndex(dwID)
end

-- 保存当前团队信息
-- (table) X.GetTeamInfo([table tTeamInfo])
function X.GetTeamInfo(tTeamInfo)
	local tList, me, team = {}, X.GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	end
	tTeamInfo = tTeamInfo or {}
	tTeamInfo.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	tTeamInfo.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	tTeamInfo.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	tTeamInfo.nLootMode = team.nLootMode

	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			local info = team.GetMemberInfo(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
			end
		end
	end
	tTeamInfo.tList = tList
	return tTeamInfo
end

do
local function GetWrongIndex(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end
local function SyncMember(team, dwID, szName, state)
	if state.bForm then --如果这货之前有阵眼
		team.SetTeamFormationLeader(dwID, state.nGroup) -- 阵眼给他
		X.Sysmsg(_L('Restore formation of %d group: %s', state.nGroup + 1, szName))
	end
	if state.nMark then -- 如果这货之前有标记
		team.SetTeamMark(state.nMark, dwID) -- 标记给他
		X.Sysmsg(_L('Restore player marked as [%s]: %s', X.CONSTANT.TEAM_MARK_NAME[state.nMark], szName))
	end
end
-- 恢复团队信息
-- (bool) X.SetTeamInfo(table tTeamInfo)
function X.SetTeamInfo(tTeamInfo)
	local me, team = X.GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	elseif not tTeamInfo then
		return false
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return X.Sysmsg(_L['You are not team leader, permission denied'])
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = tTeamInfo.tList, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				X.Sysmsg(_L('Unable get player of %d group: #%d', nGroup + 1, dwID))
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					X.Sysmsg(_L('Unknown status: %s', szName))
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					X.Sysmsg(_L('Need not adjust: %s', szName))
				else
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == tTeamInfo.szLeader then
					dwLeader = dwID
				end
				if szName == tTeamInfo.szMark then
					dwMark = dwID
				end
				if szName == tTeamInfo.szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
					X.Sysmsg(_L('Restore distributor: %s', szName))
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = GetWrongIndex(tWrong[src.state.nGroup], false)
			table.remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- 直接丢过去
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				table.remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					table.insert(tWrong[nGroup], dst)
				else -- bingo
					X.Sysmsg(_L('Change group of [%s] to %d', dst.szName, nGroup + 1))
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			X.Sysmsg(_L('Change group of [%s] to %d', src.szName, src.state.nGroup + 1))
			SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= tTeamInfo.nLootMode then
		team.SetTeamLootMode(tTeamInfo.nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		X.Sysmsg(_L('Restore team marker: %s', tTeamInfo.szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		X.Sysmsg(_L('Restore team leader: %s', tTeamInfo.szLeader))
	end
	X.Sysmsg(_L['Team list restored'])
end
end

function X.UpdateItemBoxExtend(box, nQuality)
	local szImage = 'ui/Image/Common/Box.UITex'
	local nFrame
	if nQuality == 2 then
		nFrame = 13
	elseif nQuality == 3 then
		nFrame = 12
	elseif nQuality == 4 then
		nFrame = 14
	elseif nQuality == 5 then
		nFrame = 17
	end
	box:ClearExtentImage()
	box:ClearExtentAnimate()
	if nFrame and nQuality < 5 then
		box:SetExtentImage(szImage, nFrame)
	elseif nQuality == 5 then
		box:SetExtentAnimate(szImage, nFrame, -1)
	end
end

do
local l_tGlobalEffect
function X.GetGlobalEffect(nID)
	if l_tGlobalEffect == nil then
		local szPath = 'represent\\common\\global_effect.txt'
		local tTitle = {
			{ f = 'i', t = 'nID'        },
			{ f = 's', t = 'szDesc'     },
			{ f = 'i', t = 'nPlayType'  },
			{ f = 'f', t = 'fPlaySpeed' },
			{ f = 'f', t = 'fScale'     },
			{ f = 's', t = 'szFilePath' },
			{ f = 'i', t = 'nWidth'     },
			{ f = 'i', t = 'nHeight'    },
		}
		l_tGlobalEffect = KG_Table.Load(szPath, tTitle, FILE_OPEN_MODE.NORMAL) or false
	end
	if not l_tGlobalEffect then
		return
	end
	local tLine = l_tGlobalEffect:Search(nID)
	if tLine then
		if not tLine.nWidth then
			tLine.nWidth = 0
		end
		if not tLine.nHeight then
			tLine.nHeight = 0
		end
	end
	return tLine
end
end

function X.GetCharInfo()
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
				Wnd.CloseWindow('CharInfo') -- 强制kill
			end
			Wnd.OpenWindow('CharInfo'):Hide()
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

function X.IsPhoneLock()
	local me = X.GetClientPlayer()
	return me and me.IsTradingMibaoSwitchOpen()
end

function X.IsAccountInDanger()
	local me = X.GetClientPlayer()
	return me.nAccountSecurityState == ACCOUNT_SECURITY_STATE.DANGER
end

function X.IsSafeLocked(nType)
	local me = X.GetClientPlayer()
	if nType == SAFE_LOCK_EFFECT_TYPE.TALK then -- 聊天锁比较特殊
		if _G.SafeLock_IsTalkLocked and _G.SafeLock_IsTalkLocked() then
			return true
		end
	else
		if X.IsAccountInDanger() then
			return true
		end
	end
	if me.CheckSafeLock then
		local bLock = not me.CheckSafeLock(nType)
		if bLock then
			return true
		end
	elseif me.GetSafeLockMaskInfo then
		local tLock = me.GetSafeLockMaskInfo()
		if tLock and tLock[SAFE_LOCK_EFFECT_TYPE.TALK] then
			return true
		end
	end
	return false
end

function X.IsTradeLocked()
	if X.IsAccountInDanger() then
		return true
	end
	local me = X.GetClientPlayer()
	return me.bIsBankPasswordVerified == false
end

-- * 当前道具是否满足装备要求：包括身法，体型，门派，性别，等级，根骨，力量，体质
function X.DoesEquipmentSuit(item, bIsItem, player)
	if not player then
		player = X.GetClientPlayer()
	end
	local requireAttrib = item.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		if bIsItem and not player.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
			return false
		elseif not bIsItem and not player.SatisfyRequire(v.nID, v.nValue) then
			return false
		end
	end
	return true
end

-- * 当前装备是否适合当前内功
do
local CACHE = {}
local m_MountTypeToWeapon = X.KvpToObject({
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.TIAN_CE  , WEAPON_DETAIL.SPEAR        }, -- 天策内功=长兵类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.WAN_HUA  , WEAPON_DETAIL.PEN          }, -- 万花内功=笔类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CHUN_YANG, WEAPON_DETAIL.SWORD        }, -- 纯阳内功=短兵类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.QI_XIU   , WEAPON_DETAIL.DOUBLE_WEAPON}, -- 七秀内功 = 双兵类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.SHAO_LIN , WEAPON_DETAIL.WAND         }, -- 少林内功=棍类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CANG_JIAN, WEAPON_DETAIL.SWORD        }, -- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.GAI_BANG , WEAPON_DETAIL.STICK        }, -- 丐帮内功=短棒
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.MING_JIAO, WEAPON_DETAIL.KNIFE        }, -- 明教内功=弯刀
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.WU_DU    , WEAPON_DETAIL.FLUTE        }, -- 五毒内功=笛类
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.TANG_MEN , WEAPON_DETAIL.BOW          }, -- 唐门内功=千机匣
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CANG_YUN , WEAPON_DETAIL.BLADE_SHIELD }, -- 苍云内功=刀盾
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CHANG_GE , WEAPON_DETAIL.HEPTA_CHORD  }, -- 长歌内功=琴
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.BA_DAO   , WEAPON_DETAIL.BROAD_SWORD  }, -- 霸刀内功=组合刀
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.PENG_LAI , WEAPON_DETAIL.UMBRELLA     }, -- 蓬莱内功=伞
	--WEAPON_DETAIL.FIST = 拳腕
	--WEAPON_DETAIL.DART = 弓弦
	--WEAPON_DETAIL.MACH_DART = 机关暗器
	--WEAPON_DETAIL.SLING_SHOT = 投掷
})
function X.IsItemFitKungfu(itemInfo, ...)
	if X.GetObjectType(itemInfo) == 'ITEM' then
		itemInfo = GetItemInfo(itemInfo.dwTabType, itemInfo.dwIndex)
	end
	local kungfu = ...
	local me = X.GetClientPlayer()
	if select('#', ...) == 0 then
		kungfu = me.GetKungfuMount()
	elseif X.IsNumber(kungfu) then
		kungfu = GetSkill(kungfu, me.GetSkillLevel(kungfu) or 1)
	end
	if itemInfo.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if not kungfu then
			return false
		end
		if itemInfo.nDetail == WEAPON_DETAIL.BIG_SWORD and kungfu.dwMountType == 6 then
			return true
		end

		if (m_MountTypeToWeapon[kungfu.dwMountType] ~= itemInfo.nDetail) then
			return false
		end

		if not itemInfo.nRecommendID or itemInfo.nRecommendID == 0 then
			return true
		end
	end

	if not itemInfo.nRecommendID then
		return
	end
	local aRecommendKungfuID = CACHE[itemInfo.nRecommendID]
	if not aRecommendKungfuID then
		local EquipRecommend = X.GetGameTable('EquipRecommend', true)
		if EquipRecommend then
			local res = EquipRecommend:Search(itemInfo.nRecommendID)
			aRecommendKungfuID = {}
			for i, v in ipairs(X.SplitString(res.kungfu_ids, '|')) do
				table.insert(aRecommendKungfuID, tonumber(v))
			end
		end
		CACHE[itemInfo.nRecommendID] = aRecommendKungfuID
	end

	if not aRecommendKungfuID or not aRecommendKungfuID[1] then
		return
	end

	if aRecommendKungfuID[1] == 0 then
		return true
	end

	if not kungfu then
		return false
	end
	for _, v in ipairs(aRecommendKungfuID) do
		if v == kungfu.dwSkillID then
			return true
		end
	end
end
end

-- 获取物品精炼等级
---@param KItem userdata @物品对象
---@param KPlayer userdata @物品所属角色
---@return number, number, number @[有效精炼等级, 物品精炼等级, 装备栏精炼等级]
function X.GetItemStrengthLevel(KItem, KPlayer)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		if not KPlayer then
			KPlayer = X.GetClientPlayer()
		end
		local dwPackage, dwBox = X.GetItemEquipPos(KItem)
		if dwPackage == INVENTORY_INDEX.EQUIP and KPlayer.GetEquipBoxStrength then
			local KItemInfo = GetItemInfo(KItem.dwTabType, KItem.dwIndex)
			local nMaxStrengthLevel = KItemInfo.nMaxStrengthLevel
			local nBoxStrengthLevel = KPlayer.GetEquipBoxStrength(dwBox)
			local nItemStrengthLevel = KItem.nStrengthLevel
			local nStrengthLevel = math.min(math.max(nItemStrengthLevel, nBoxStrengthLevel), nMaxStrengthLevel)
			return nStrengthLevel, nItemStrengthLevel, nBoxStrengthLevel
		end
	end
	return KItem.nStrengthLevel, KItem.nStrengthLevel, 0
end

-- 获取物品熔嵌孔镶嵌信息
---@param KItem userdata @物品对象
---@param nSlotIndex string @熔嵌孔下标
---@param KPlayer userdata @物品所属角色
---@return number, number, number @[有效熔嵌孔五行石ID, 物品熔嵌孔五行石ID, 装备栏熔嵌孔五行石ID]
function X.GetItemMountDiamondEnchantID(KItem, nSlotIndex, KPlayer)
	if X.ENVIRONMENT.GAME_BRANCH == 'remake' then
		if not KPlayer then
			KPlayer = X.GetClientPlayer()
		end
		local dwPackage, dwBox = X.GetItemEquipPos(KItem)
		if dwPackage == INVENTORY_INDEX.EQUIP and KPlayer.GetEquipBoxMountDiamondEnchantID then
			local dwBoxEnchantID, nBoxQuality = KPlayer.GetEquipBoxMountDiamondEnchantID(dwBox, nSlotIndex)
            local dwItemEnchantID = KItem.GetMountDiamondEnchantID(nSlotIndex)
            local dwEnchantID = KItem.GetAdaptedDiamondEnchantID(nSlotIndex, KItem.nLevel, dwBoxEnchantID)
			return dwEnchantID, dwItemEnchantID, dwBoxEnchantID
		end
	end
	local dwItemEnchantID = KItem.GetMountDiamondEnchantID(nSlotIndex)
	return dwItemEnchantID, dwItemEnchantID, 0
end

-- * 获取物品对应身上装备的位置
function X.GetItemEquipPos(item, nIndex)
	if not nIndex then
		nIndex = 1
	end
	local dwPackage, dwBox, nCount = INVENTORY_INDEX.EQUIP, 0, 1
	if item.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if item.nDetail == WEAPON_DETAIL.BIG_SWORD then
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD
		else
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON
		end
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.ARROW then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.ARROW
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.CHEST then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.CHEST
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.HELM then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.HELM
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.AMULET then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.AMULET
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.RING then
		if nIndex == 1 then
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING
		else
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING
		end
		nCount = 2
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.PENDANT then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.PENDANT
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.PANTS then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.PANTS
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.BOOTS then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BOOTS
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.BANGLE then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BANGLE
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	elseif item.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE then
		dwPackage, dwBox = X.GetClientPlayer().GetEquippedHorsePos()
	end
	return dwPackage, dwBox, nIndex, nCount
end

-- * 当前装备是否是比身上已经装备的更好
function X.IsBetterEquipment(item, dwPackage, dwBox)
	if item.nGenre ~= ITEM_GENRE.EQUIPMENT
	or item.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND
	or item.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND
	or item.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	or item.nSub == X.CONSTANT.EQUIPMENT_SUB.BULLET
	or item.nSub == X.CONSTANT.EQUIPMENT_SUB.MINI_AVATAR
	or item.nSub == X.CONSTANT.EQUIPMENT_SUB.PET then
		return false
	end

	if not dwPackage or not dwBox then
		local nIndex, nCount = 0, 1
		while nIndex < nCount do
			dwPackage, dwBox, nIndex, nCount = X.GetItemEquipPos(item, nIndex + 1)
			if X.IsBetterEquipment(item, dwPackage, dwBox) then
				return true
			end
		end
		return false
	end

	local me = X.GetClientPlayer()
	local equipedItem = GetPlayerItem(me, dwPackage, dwBox)
	if not equipedItem then
		return false
	end
	if me.nLevel < me.nMaxLevel then
		return item.nEquipScore > equipedItem.nEquipScore
	end
	return (item.nEquipScore > equipedItem.nEquipScore) or (item.nLevel > equipedItem.nLevel and item.nQuality >= equipedItem.nQuality)
end

function X.GetCampImage(eCamp, bFight) -- ui\Image\UICommon\CommonPanel2.UITex
	local szUITex, nFrame
	if eCamp == CAMP.GOOD then
		if bFight then
			nFrame = 117
		else
			nFrame = 7
		end
	elseif eCamp == CAMP.EVIL then
		if bFight then
			nFrame = 116
		else
			nFrame = 5
		end
	end
	if nFrame then
		szUITex = 'ui\\Image\\UICommon\\CommonPanel2.UITex'
	end
	return szUITex, nFrame
end

do local _RoleName
function X.GetUserRoleName()
	if X.IsFunction(GetUserRoleName) then
		return GetUserRoleName()
	end
	local me = X.GetClientPlayer()
	if me and not IsRemotePlayer(me.dwID) then
		_RoleName = me.szName
	end
	return _RoleName
end
end

do local ITEM_CACHE = {}
function X.GetItemNameByUIID(nUiId)
	if not ITEM_CACHE[nUiId] then
		local szName = Table_GetItemName(nUiId)
		if szName == '' then
			szName = 'ITEM#' .. nUiId
		end
		ITEM_CACHE[nUiId] = szName
	end
	return ITEM_CACHE[nUiId]
end
end

function X.GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = X.RecipeToSegmentID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return X.GetItemNameByUIID(item.nUiId)
end

function X.GetItemNameByItemInfo(itemInfo, nBookInfo)
	if itemInfo.nGenre == ITEM_GENRE.BOOK and nBookInfo then
		local nBookID, nSegID = X.RecipeToSegmentID(nBookInfo)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return X.GetItemNameByUIID(itemInfo.nUiId)
end

do local ITEM_CACHE = {}
function X.GetItemIconByUIID(nUiId)
	if not ITEM_CACHE[nUiId] then
		local nIcon = Table_GetItemIconID(nUiId)
		if nIcon == -1 then
			nIcon = 1435
		end
		ITEM_CACHE[nUiId] = nIcon
	end
	return ITEM_CACHE[nUiId]
end
end

function X.GetGuildBankBagSize(nPage)
	return X.CONSTANT.INVENTORY_GUILD_PAGE_BOX_COUNT
end

function X.GetGuildBankBagPos(nPage, nIndex)
	return X.CONSTANT.INVENTORY_GUILD_BANK, nPage * X.CONSTANT.INVENTORY_GUILD_PAGE_SIZE + nIndex - 1
end

function X.IsSelf(dwSrcID, dwTarID)
	if X.IsFunction(IsSelf) then
		return IsSelf(dwSrcID, dwTarID)
	end
	return dwSrcID ~= 0 and dwSrcID == dwTarID and X.IsPlayer(dwSrcID) and X.IsPlayer(dwTarID)
end

-- * 获取门派对应心法ID列表
do local m_tForceToKungfu
function X.ForceIDToKungfuIDs(dwForceID)
	if X.IsFunction(ForceIDToKungfuIDs) then
		return ForceIDToKungfuIDs(dwForceID)
	end
	if not m_tForceToKungfu then
		m_tForceToKungfu = {}
		for _, v in ipairs(X.CONSTANT.KUNGFU_LIST) do
			if not m_tForceToKungfu[v.dwForceID] then
				m_tForceToKungfu[v.dwForceID] = {}
			end
			table.insert(m_tForceToKungfu[v.dwForceID], v.dwID)
		end
	end
	return m_tForceToKungfu[dwForceID] or {}
end
end

-- 追加小地图标记
-- (void) X.UpdateMiniFlag(number dwType, KObject tar, number nF1[, number nF2])
-- (void) X.UpdateMiniFlag(number dwType, number nX, number nZ, number nF1[, number nF2])
-- dwType -- 类型 由UI脚本指定 (enum MINI_MAP_POINT)
-- tar    -- 目标对象 KPlayer，KNpc，KDoodad
-- nF1    -- 图标帧次
-- nF2    -- 箭头帧次，默认 48 就行
function X.UpdateMiniFlag(dwType, tar, nF1, nF2, nFadeOutTime, argX)
	local m = Station.Lookup('Normal/Minimap/Wnd_Minimap/Minimap_Map')
	if not m then
		return
	end
	local nX, nZ, dwID
	if X.IsNumber(tar) then
		dwID = GetStringCRC(tar .. nF1)
		nX, nZ = Scene_PlaneGameWorldPosToScene(tar, nF1)
		nF1, nF2, nFadeOutTime = nF2, nFadeOutTime, argX
	else
		dwID = tar.dwID
		nX, nZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	end
	m:UpdataArrowPoint(dwType, dwID, nF1, nF2 or 48, nX, nZ, nFadeOutTime or 16)
end

-- 获取头像文件路径，帧序，是否动画
function X.GetMiniAvatar(dwAvatarID, nRoleType)
	-- mini avatar
	local RoleAvatar = X.GetGameTable('RoleAvatar', true)
	if RoleAvatar then
		local tInfo = RoleAvatar:Search(dwAvatarID)
		if tInfo then
			if nRoleType == ROLE_TYPE.STANDARD_MALE then
				return tInfo.szM2Image, tInfo.nM2ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.STANDARD_FEMALE then
				return tInfo.szF2Image, tInfo.nF2ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.STRONG_MALE then
				return tInfo.szM3Image, tInfo.nM3ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.SEXY_FEMALE then
				return tInfo.szF3Image, tInfo.nF3ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.LITTLE_BOY then
				return tInfo.szM1Image, tInfo.nM1ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.LITTLE_GIRL then
				return tInfo.szF1Image, tInfo.nF1ImgFrame, tInfo.bAnimate
			end
		end
	end
end

-- 获取头像文件路径，帧序，是否动画
function X.GetForceAvatar(dwForceID)
	-- force avatar
	return X.Unpack(X.CONSTANT.FORCE_AVATAR[dwForceID])
end

-- 获取头像文件路径，帧序，是否动画
function X.GetPlayerAvatar(dwForceID, nRoleType, dwAvatarID)
	local szFile, nFrame, bAnimate
	-- mini avatar
	if dwAvatarID and dwAvatarID > 0 then
		szFile, nFrame, bAnimate = X.GetMiniAvatar(dwAvatarID, nRoleType)
	end
	-- force avatar
	if not szFile and dwForceID then
		szFile, nFrame, bAnimate = X.GetForceAvatar(dwForceID)
	end
	return szFile, nFrame, bAnimate
end

-- 获取成就基础信息
function X.GetAchievement(dwAchieveID)
	local Achievement = X.GetGameTable('Achievement', true)
	if Achievement then
		return Achievement:Search(dwAchieveID)
	end
end

-- 获取成就描述信息
function X.GetAchievementInfo(dwAchieveID)
	local AchievementInfo = X.GetGameTable('AchievementInfo', true)
	if AchievementInfo then
		return AchievementInfo:Search(dwAchieveID)
	end
end

-- 获取一个地图的成就列表（区分是否包含五甲）
local MAP_ACHI_NORMAL, MAP_ACHI_ALL
function X.GetMapAchievements(dwMapID, bWujia)
	if not MAP_ACHI_NORMAL then
		local tMapAchiNormal, tMapAchiAll = {}, {}
		local Achievement = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Achievement', true)
		if Achievement then
			local nCount = Achievement:GetRowCount()
			for i = 2, nCount do
				local tLine = Achievement:GetRow(i)
				if tLine and tLine.nVisible == 1 then
					for _, szID in ipairs(X.SplitString(tLine.szSceneID, '|', true)) do
						local dwID = tonumber(szID)
						if dwID then
							if tLine.dwGeneral == 1 then
								if not tMapAchiNormal[dwID] then
									tMapAchiNormal[dwID] = {}
								end
								table.insert(tMapAchiNormal[dwID], tLine.dwID)
							end
							if not tMapAchiAll[dwID] then
								tMapAchiAll[dwID] = {}
							end
							table.insert(tMapAchiAll[dwID], tLine.dwID)
						end
					end
				end
			end
		end
		MAP_ACHI_NORMAL, MAP_ACHI_ALL = tMapAchiNormal, tMapAchiAll
	end
	if bWujia then
		return X.Clone(MAP_ACHI_ALL[dwMapID])
	end
	return X.Clone(MAP_ACHI_NORMAL[dwMapID])
end

do
	local function PeekPlayer(dwID)
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
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'EquipScore Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		PeekPlayer(dwID)
	end
end

do
	local function PeekPlayer(dwID)
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
					local nEnchantID = item.GetMountDiamondEnchantID(i - 1)
					if nEnchantID and nEnchantID > 0 then
						local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(nEnchantID)
						if dwTabType and dwTabIndex then
							aSlotItem[i] = {dwTabType, dwTabIndex}
						end
					end
				end
				-- 五彩石
				local nEnchantID = item.GetMountFEAEnchantID()
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
		if X.IsEmpty(tEquipInfo) then
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
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'EquipInfo Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		PeekPlayer(dwID)
	end
end

do
	local function PeekPlayer(dwID)
		if X.ENVIRONMENT.GAME_BRANCH == 'classic' then
			X.SafeCall(PeekOtherPlayerTalent, dwID)
		else
			X.SafeCall(PeekOtherPlayerTalent, dwID, 0xffffffff)
		end
	end
	local EVENT_KEY = nil
	local PEEK_PLAYER_TALENT_STATE = {}
	local PEEK_PLAYER_TALENT_TIME = {}
	local PEEK_PLAYER_TALENT_CALLBACK = {}
	local function OnGetPlayerTalnetInfoPeekPlayer(player)
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
			X.Debug(X.PACKET_INFO.NAME_SPACE, 'Talent Peek player: ' .. player.dwID, X.DEBUG_LEVEL.LOG)
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
			OnGetPlayerTalnetInfoPeekPlayer(X.GetClientPlayer())
			return
		end
		-- 缓存判定
		local player = X.GetPlayer(dwID)
		if player and PEEK_PLAYER_TALENT_STATE[dwID] == 'SUCCESS' and not bForcePeek then
			OnGetPlayerTalnetInfoPeekPlayer(player)
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
					OnGetPlayerTalnetInfoPeekPlayer(player)
				end
			end)
		end
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'TelentInfo Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		PeekPlayer(dwID)
	end
end

do
	local function PeekPlayer(dwID)
		X.SafeCall(ViewOtherZhenPaiSkill, dwID, true)
		X.SafeCall(Wnd.CloseWindow, 'ZhenPaiSkill')
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
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'ZhenPaiInfo Peek player: ' .. dwID, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		PeekPlayer(dwID)
	end
end

do
local MACRO_ACTION_DATATYPE = {
	['cast'] = 'SKILL',
	['fcast'] = 'SKILL',
}
local MACRO_CONDITION_DATATYPE = {
	['buff'] = 'BUFF',
	['nobuff'] = 'BUFF',
	['bufftime'] = 'BUFF',
	['life'] = 'VOID',
	['mana'] = 'VOID',
	['rage'] = 'VOID',
	['qidian'] = 'VOID',
	['energy'] = 'VOID',
	['sun'] = 'VOID',
	['moon'] = 'VOID',
	['sun_power'] = 'VOID',
	['moon_power'] = 'VOID',
	['skill_energy'] = 'SKILL',
	['skill'] = 'SKILL',
	['noskill'] = 'SKILL',
	['npclevel'] = 'VOID',
	['nearby_enemy'] = 'VOID',
	['yaoxing'] = 'VOID',
	['skill_notin_cd'] = 'SKILL',
	['tbuff'] = 'BUFF',
	['tnobuff'] = 'BUFF',
	['tbufftime'] = 'BUFF',
}
function X.IsMacroValid(szMacro)
	-- /cast [nobuff:太极] 太极无极
	local bDebug = X.IsDebugClient(X.NSFormatString('{$NS}_Macro'))
	for nLine, szLine in ipairs(X.SplitString(szMacro, '\n')) do
		szLine = X.TrimString(szLine)
		if not X.IsEmpty(szLine) then
			-- 拆分 /动作指令 [条件] 动作指令参数
			local szAction, szCondition, szActionData = szLine:match('^/([a-zA-Z_]+)%s*%[([^%]]+)%]%s*(.-)%s*$')
			if not szAction then
				szAction, szActionData = szLine:match('^/([a-zA-Z_]+)%s+(.-)%s*$')
				szCondition = ''
			end
			-- 校验动作指令
			if not szAction then
				local szErrMsg = _L('Syntax error at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szLine .. '}'
				end
				return false, 'SYNTAX_ERROR', nLine, szErrMsg
			end
			local szActionType = MACRO_ACTION_DATATYPE[szAction]
			if not szActionType then
				local szErrMsg = _L('Unknown action at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szAction .. '}'
				end
				return false, 'UNKNOWN_ACTION', nLine, szErrMsg
			end
			-- 校验动作指令参数
			if szActionType == 'SKILL' and not tonumber(szActionData) and not X.GetSkillByName(szActionData) then
				local szErrMsg = _L('Unknown action skill at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szActionData .. '}'
				end
				return false, 'UNKNOWN_ACTION_SKILL', nLine, szErrMsg
			elseif szActionType == 'BUFF' and not tonumber(szActionData) and not X.GetBuffByName(szActionData) then
				local szErrMsg = _L('Unknown action buff at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szActionData .. '}'
				end
				return false, 'UNKNOWN_ACTION_BUFF', nLine, szErrMsg
			end
			-- 校验条件
			for _, szSubCondition in ipairs(X.SplitString(szCondition, {'|', '&'}, true)) do
				-- last_skill~=钟灵毓秀
				-- moon>sun
				-- sun<10
				-- life<0.3
				-- bufftime:太极<4.1
				-- tbuff:流血
				-- 校验【条件指令:条件指令参数(可选数值比较)】类型
				local szJudge, szJudgeData = szSubCondition:match('^([a-zA-Z_]+)%s*%:%s*([^<>~=]+)%s*[<>~=]*%s*[0-9.]*$')
				if not szJudge then
					szJudge, szJudgeData = szSubCondition:match('^([a-zA-Z_]+)%s*[<>~=]*%s*[0-9.%s]*$'), ''
				end
				if szJudge and szJudge ~= 'last_skill' then
					local szJudgeType = MACRO_CONDITION_DATATYPE[szJudge]
					if not szJudgeType then
						local szErrMsg = _L('Unknown condition at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudge .. '}'
						end
						return false, 'UNKNOWN_CONDITION', nLine, szErrMsg
					end
					if szJudgeType == 'SKILL' and not tonumber(szJudgeData) and not X.GetSkillByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition skill at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_CONDITION_SKILL', nLine, szErrMsg
					elseif szJudgeType == 'BUFF' and not tonumber(szJudgeData) and not X.GetBuffByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition buff at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_CONDITION_BUFF', nLine, szErrMsg
					end
				elseif not szSubCondition:match('moon[<>=%s]+sun') and not szSubCondition:match('sun[<>=%s]+moon') then
					szJudge, szJudgeData = szSubCondition:match('^(last_skill)[=~%s]+([^<>=~]+)$')
					if not szJudge then
						local szErrMsg = _L('Unknown condition at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szSubCondition .. '}'
						end
						return false, 'UNKNOWN_CONDITION', nLine, szErrMsg
					end
					if szJudge and not tonumber(szJudgeData) and not X.GetSkillByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition skill at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_ACTION_SKILL', nLine, szErrMsg
					end
				end
			end
		end
	end
	return true
end
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
	function X.GetPlayerGUID(...)
		local dwID = ...
		if select('#', ...) == 0 then
			dwID = X.GetClientPlayerID()
		end
		if not dwID then
			return
		end
		if not PLAYER_GUID[dwID] then
			if dwID == X.GetClientPlayerID() then
				PLAYER_GUID[dwID] = X.GetClientPlayerGlobalID()
			end
		end
		return PLAYER_GUID[dwID]
	end
end


do
	local function PatternReplacer(szContent, tVar, bKeepNMTS, bReplaceSensitiveWord)
		-- 由于涉及缓存，所以该函数仅允许替换静态映射关系
		if szContent == 'me' then
			return X.GetUserRoleName()
		end
		if X.IsTable(tVar) then
			if not X.IsNil(tVar[szContent]) then
				return tVar[szContent]
			end
			if szContent:match('^%d+$') then
				return tVar[tonumber(szContent)]
			end
		end
		local szType = szContent:sub(1, 1)
		local aValue = X.SplitString(szContent:sub(2), ',')
		for k, v in ipairs(aValue) do
			aValue[k] = tonumber(v)
		end
		if szType == 'N' then
			return X.GetTemplateName(TARGET.NPC, aValue[1])
		end
		if szType == 'D' then
			return X.GetTemplateName(TARGET.DOODAD, aValue[1])
		end
		if szType == 'S' then
			return X.GetSkillName(aValue[1], aValue[2])
		end
		if szType == 'B' then
			return X.GetBuffName(aValue[1], aValue[2])
		end
		if szType == 'I' then
			if #aValue == 1 then
				return X.GetItemNameByUIID(aValue[1])
			end
			local KItemInfo = GetItemInfo(aValue[1], aValue[2])
			if KItemInfo then
				return X.GetItemNameByItemInfo(KItemInfo, aValue[3])
			end
		end
		if szType == 'M' then
			local map = X.GetMapInfo(aValue[1])
			if map then
				return map.szName
			end
		end
		-- keep none-matched template string
		if bKeepNMTS then
			if bReplaceSensitiveWord then
				szContent = X.ReplaceSensitiveWord(szContent)
			end
			return '{$' .. szContent .. '}'
		end
	end
	local CACHE, CACHE_KEY, MAX_CACHE = {}, {}, 100
	function X.RenderTemplateString(szTemplate, tVar, nMaxLen, bReplaceSensitiveWord, bKeepNMTS)
		if not szTemplate then
			return
		end
		local szKey = X.EncodeLUAData({szTemplate, tVar, nMaxLen, bReplaceSensitiveWord, bKeepNMTS})
		if not CACHE[szKey] then
			local szText = ''
			local nOriginLen, nLen, nPos = string.len(szTemplate), 0, 1
			local szPart, nStart, nEnd, szContent
			while nPos <= nOriginLen do
				szPart, nStart, nEnd, szContent = nil, nil, nil, nil
				nStart = X.StringFindW(szTemplate, '{$', nPos)
				if nStart then
					nEnd = X.StringFindW(szTemplate, '}', nStart + 2)
					if nEnd then
						szContent = szTemplate:sub(nStart + 2, nEnd - 1)
					end
				end
				if not nStart then
					szPart = szTemplate:sub(nPos)
					nPos = nOriginLen + 1
				elseif not nEnd then
					szPart = szTemplate:sub(nPos, nStart + 1)
					nPos = nStart + 2
				elseif nStart > nPos then
					szPart = szTemplate:sub(nPos, nStart - 1)
					nPos = nStart
				end
				if szPart then
					if bReplaceSensitiveWord then
						szPart = X.ReplaceSensitiveWord(szPart)
					end
					if nMaxLen and nMaxLen > 0 and nLen + X.StringLenW(szPart) > nMaxLen then
						szPart = X.StringSubW(szPart, 1, nMaxLen - nLen)
						szText = szText .. szPart
						nLen = nMaxLen
						break
					else
						szText = szText .. szPart
						nLen = nLen + X.StringLenW(szPart)
					end
				end
				if szContent then
					szPart = PatternReplacer(szContent, tVar, bKeepNMTS, bReplaceSensitiveWord)
					if szPart then
						szText = szText .. szPart
					end
					nPos = nEnd + 1
				end
				if #CACHE_KEY >= MAX_CACHE then
					CACHE[table.remove(CACHE_KEY, 1)] = nil
				end
				CACHE[szKey] = szText
				table.insert(CACHE_KEY, szKey)
			end
		end
		return CACHE[szKey]
	end
end

-- 映射： 套书ID/名称 => 子书籍ID列表；书籍名称 => 书籍ID
local BOOK_SEGMENT_RECIPE = setmetatable({}, {
	__call = function(t, m, k)
		local tBookID2RecipeID = t.tBookID2RecipeID
		local tBookName2RecipeID = t.tBookName2RecipeID
		local tSegmentName2RecipeID = t.tSegmentName2RecipeID
		local tSegmentNameFix = t.tSegmentNameFix
		if not tSegmentNameFix then
			local data = X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/bookfix/{$lang}.jx3dat') or {}
			tSegmentNameFix = data.segment or {}
			t.tSegmentNameFix = tSegmentNameFix
		end
		if not tBookID2RecipeID or not tBookName2RecipeID or not tSegmentName2RecipeID then
			local cache = X.LoadLUAData({'temporary/book-segment.jx3dat', X.PATH_TYPE.GLOBAL})
			if X.IsTable(cache) then
				tBookID2RecipeID = cache.book_id
				tBookName2RecipeID = cache.book_name
				tSegmentName2RecipeID = cache.segment_name
			end
			if not tBookName2RecipeID or not tSegmentName2RecipeID then
				tBookID2RecipeID = {}
				tBookName2RecipeID = {}
				tSegmentName2RecipeID = {}
				local BookSegment = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('BookSegment', true)
				if BookSegment then
					local nCount = BookSegment:GetRowCount()
					for i = 2, nCount do
						local row = BookSegment:GetRow(i)
						-- {
						-- 	dwBookID = 2, dwSegmentID = 1, szBookName = "沉香劈山", szDesc = "沉香救母之传说。", szSegmentName = "沉香劈山上篇",
						-- 	dwBookItemIndex = 7936, dwBookNumber = 2, dwPageCount = 6, nSort = 2, nSubSort = 1, nType = 1,
						-- 	dwPageID_0 = 6, dwPageID_1 = 7, dwPageID_2 = 8, dwPageID_3 = 9, dwPageID_4 = 10, dwPageID_5 = 11, dwPageID_6 = 0, dwPageID_7 = 0, dwPageID_8 = 0, dwPageID_9 = 0
						-- }
						local dwRecipeID = X.SegmentToRecipeID(row.dwBookID, row.dwSegmentID)
						-- 套书
						local szBookName = X.TrimString(row.szBookName)
						if not tBookName2RecipeID[szBookName] then
							tBookName2RecipeID[szBookName] = {}
						end
						table.insert(tBookName2RecipeID[szBookName], dwRecipeID)
						if not tBookID2RecipeID[row.dwBookID] then
							tBookID2RecipeID[row.dwBookID] = {}
						end
						table.insert(tBookID2RecipeID[row.dwBookID], dwRecipeID)
						-- 书籍
						local szSegmentName = X.TrimString(row.szSegmentName)
						tSegmentName2RecipeID[szSegmentName] = dwRecipeID
					end
				end
			end
			if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
				X.SaveLUAData({'temporary/book-segment.jx3dat', X.PATH_TYPE.GLOBAL}, {
					book_id = tBookID2RecipeID,
					book_name = tBookName2RecipeID,
					segment_name = tSegmentName2RecipeID,
				})
			end
			t.tBookID2RecipeID = tBookID2RecipeID
			t.tBookName2RecipeID = tBookName2RecipeID
			t.tSegmentName2RecipeID = tSegmentName2RecipeID
		end
		if m == 'book_id' then
			return tBookName2RecipeID[k]
		end
		if m == 'book_name' then
			return tBookName2RecipeID[k]
		end
		if m == 'segment_name' then
			local k1 = tSegmentNameFix[k]
			if k1 then
				return tSegmentName2RecipeID[k1] or tSegmentName2RecipeID[k]
			end
			return tSegmentName2RecipeID[k]
		end
	end,
})

-- 获取书籍信息
-- X.GetBookSegmentInfo(szSegmentName)
-- X.GetBookSegmentInfo(dwRecipeID)
-- X.GetBookSegmentInfo(dwBookID, dwSegmentID)
function X.GetBookSegmentInfo(...)
	local dwBookID, dwSegmentID
	if select('#', ...) == 1 then
		local dwRecipeID = ...
		if X.IsString(dwRecipeID) then
			dwRecipeID = BOOK_SEGMENT_RECIPE('segment_name', X.TrimString(dwRecipeID))
		end
		if X.IsNumber(dwRecipeID) then
			dwBookID, dwSegmentID = X.RecipeToSegmentID(dwRecipeID)
		end
	else
		dwBookID, dwSegmentID = ...
	end
	if X.IsNumber(dwBookID) and X.IsNumber(dwSegmentID) then
		local BookSegment = X.GetGameTable('BookSegment', true)
		if BookSegment then
			return BookSegment:Search(dwBookID, dwSegmentID)
		end
	end
end

-- 获取套书所有书籍信息
-- X.GetBookAllSegmentInfo(dwBookID)
-- X.GetBookAllSegmentInfo(szBookName)
function X.GetBookAllSegmentInfo(arg0)
	local aRecipeID
	if X.IsString(arg0) then
		aRecipeID = BOOK_SEGMENT_RECIPE('book_name', X.TrimString(arg0))
	elseif X.IsNumber(arg0) then
		aRecipeID = BOOK_SEGMENT_RECIPE('book_id', arg0)
	end
	if aRecipeID then
		local aSegmentInfo = {}
		for _, dwRecipeID in ipairs(aRecipeID) do
			local dwBookID, dwSegmentID = X.RecipeToSegmentID(dwRecipeID)
			table.insert(aSegmentInfo, X.GetBookSegmentInfo(dwBookID, dwSegmentID))
		end
		return aSegmentInfo
	end
end

-- 书籍 <=> 交互物件 映射
local DOODAD_BOOK = setmetatable({}, {
	__call = function(t, m, k)
		local tDoodadID2BookRecipe = t.tDoodadID2BookRecipe
		local tBookRecipe2DoodadID = t.tBookRecipe2DoodadID
		if not tDoodadID2BookRecipe or not tBookRecipe2DoodadID then
			local cache = X.LoadLUAData({'temporary/doodad-book.jx3dat', X.PATH_TYPE.GLOBAL})
			if X.IsTable(cache) then
				tDoodadID2BookRecipe = cache.doodad_book
				tBookRecipe2DoodadID = cache.book_doodad
			end
			if not tDoodadID2BookRecipe or not tBookRecipe2DoodadID then
				tDoodadID2BookRecipe = {}
				tBookRecipe2DoodadID = {}
				local DoodadTemplate = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('DoodadTemplate', true)
				if DoodadTemplate then
					local nCount = DoodadTemplate:GetRowCount()
					for i = 2, nCount do
						local row = DoodadTemplate:GetRow(i)
						if row.szBarText == _L['Copy inscription'] then
							local szSegmentName = string.sub(row.szName, string.len(_L['Inscription * ']) + 1)
							local info = X.GetBookSegmentInfo(szSegmentName)
							if info then
								local dwRecipeID = X.SegmentToRecipeID(info.dwBookID, info.dwSegmentID)
								tDoodadID2BookRecipe[row.nID] = dwRecipeID
								tBookRecipe2DoodadID[dwRecipeID] = row.nID
							end
						end
					end
				end
			end
			X.SaveLUAData({'temporary/doodad-book.jx3dat', X.PATH_TYPE.GLOBAL}, {
				doodad_book = tDoodadID2BookRecipe,
				book_doodad = tBookRecipe2DoodadID,
			}, { passphrase = false })
			t.tDoodadID2BookRecipe = tDoodadID2BookRecipe
			t.tBookRecipe2DoodadID = tBookRecipe2DoodadID
		end
		if m == 'doodad-book' then
			return tDoodadID2BookRecipe[k]
		end
		if m == 'book-doodad' then
			return tBookRecipe2DoodadID[k]
		end
	end,
})

-- 获取碑铭交互物件对应书籍ID
-- X.GetDoodadBookRecipeID(dwDoodadTemplate)
function X.GetDoodadBookRecipeID(dwDoodadTemplate)
	return DOODAD_BOOK('doodad-book', dwDoodadTemplate)
end

-- 获取书籍碑铭交互物件模板ID
-- X.GetBookDoodadID(dwRecipeID)
-- X.GetBookDoodadID(dwBookID, dwSegmentID)
-- X.GetBookDoodadID(szSegmentName)
function X.GetBookDoodadID(...)
	local dwRecipeID
	if select('#', ...) == 1 then
		dwRecipeID = ...
		if X.IsString(dwRecipeID) then
			dwRecipeID = BOOK_SEGMENT_RECIPE('segment_name', X.TrimString(dwRecipeID))
		end
	else
		dwRecipeID = X.SegmentToRecipeID(...)
	end
	if X.IsNumber(dwRecipeID) then
		return DOODAD_BOOK('book-doodad', dwRecipeID)
	end
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
