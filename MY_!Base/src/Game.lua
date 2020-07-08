--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 游戏环境库
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
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall = LIB.Call, LIB.XpCall, LIB.SafeCall
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _L = LIB.LoadLangPack()

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
-- 获取当前服务器名称
function LIB.GetServer(nIndex)
	local display_region, display_server, region, server = GetUserServer()
	region = region or display_region
	server = server or display_server
	if nIndex == 1 then
		return region
	elseif nIndex == 2 then
		return server
	else
		return region .. '_' .. server, {region, server}
	end
end

-- 获取当前服务器显示名称
function LIB.GetDisplayServer(nIndex)
	local display_region, display_server = GetUserServer()
	if nIndex == 1 then
		return display_region
	elseif nIndex == 2 then
		return display_server
	else
		return display_region .. '_' .. display_server, {display_region, display_server}
	end
end

-- 获取数据互通主服务器名称
function LIB.GetRealServer(nIndex)
	local display_region, display_server, _, _, real_region, real_server = GetUserServer()
	real_region = real_region or display_region
	real_server = real_server or display_server
	if nIndex == 1 then
		return real_region
	elseif nIndex == 2 then
		return real_server
	else
		return real_region .. '_' .. real_server, {real_region, real_server}
	end
end

do
local S2L_CACHE = setmetatable({}, { __mode = 'k' })
local L2S_CACHE = setmetatable({}, { __mode = 'k' })
function LIB.ConvertNpcID(dwID, eType)
	if IsPlayer(dwID) then
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
local DISTANCE_TYPE
local PATH = {'config/distance_type.jx3dat', PATH_TYPE.ROLE}
function LIB.GetGlobalDistanceType()
	if not DISTANCE_TYPE then
		DISTANCE_TYPE = LIB.LoadLUAData(PATH) or 'gwwean'
	end
	return DISTANCE_TYPE
end

function LIB.SetGlobalDistanceType(szType)
	DISTANCE_TYPE = szType
	LIB.SaveLUAData(PATH, DISTANCE_TYPE)
end

function LIB.GetDistanceTypeList(bGlobal)
	local t = {
		{ szType = 'gwwean', szText = _L.DISTANCE_TYPE['gwwean'] },
		{ szType = 'euclidean', szText = _L.DISTANCE_TYPE['euclidean'] },
		{ szType = 'plane', szText = _L.DISTANCE_TYPE['plane'] },
	}
	if (bGlobal) then
		insert(t, { szType = 'global', szText = _L.DISTANCE_TYPE['global'] })
	end
	return t
end

function LIB.GetDistanceTypeMenu(bGlobal, eValue, fnAction)
	local t = {}
	for _, p in ipairs(LIB.GetDistanceTypeList(true)) do
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
				LIB.ShowPanel()
				LIB.SwitchTab('GlobalConfig')
				UI.ClosePopupMenu()
			end
		end
		insert(t, t1)
	end
	return t
end
end

-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- LIB.GetDistance(OObject[, szType])
-- LIB.GetDistance(nX, nY)
-- LIB.GetDistance(nX, nY, nZ[, szType])
-- LIB.GetDistance(OObject1, OObject2[, szType])
-- LIB.GetDistance(OObject1, nX2, nY2)
-- LIB.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- LIB.GetDistance(nX1, nY1, nX2, nY2)
-- LIB.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': 欧氏距离 (default)
--         'plane'    : 平面距离
--         'gwwean'   : 郭氏距离
--         'global'   : 使用全局配置
function LIB.GetDistance(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	local szType
	local nX1, nY1, nZ1 = 0, 0, 0
	local nX2, nY2, nZ2 = 0, 0, 0
	if IsTable(arg0) then
		arg0 = LIB.GetObject(unpack(arg0))
		if not arg0 then
			return
		end
	end
	if IsTable(arg1) then
		arg1 = LIB.GetObject(unpack(arg1))
		if not arg1 then
			return
		end
	end
	if IsUserdata(arg0) then -- OObject -
		nX1, nY1, nZ1 = arg0.nX, arg0.nY, arg0.nZ
		if IsUserdata(arg1) then -- OObject1, OObject2
			nX2, nY2, nZ2, szType = arg1.nX, arg1.nY, arg1.nZ, arg2
		elseif IsNumber(arg1) and IsNumber(arg2) then -- OObject1, nX2, nY2
			if IsNumber(arg3) then -- OObject1, nX2, nY2, nZ2[, szType]
				nX2, nY2, nZ2, szType = arg1, arg2, arg3, arg4
			else -- OObject1, nX2, nY2[, szType]
				nX2, nY2, szType = arg1, arg2, arg3
			end
		else -- OObject[, szType]
			local me = GetClientPlayer()
			nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg1
		end
	elseif IsNumber(arg0) and IsNumber(arg1) then -- nX1, nY1 -
		if IsNumber(arg2) then
			if IsNumber(arg3) then
				if IsNumber(arg4) and IsNumber(arg5) then -- nX1, nY1, nZ1, nX2, nY2, nZ2[, szType]
					nX1, nY1, nZ1, nX2, nY2, nZ2, szType = arg0, arg1, arg2, arg3, arg4, arg5, arg6
				else -- nX1, nY1, nX2, nY2[, szType]
					nX1, nY1, nX2, nY2, szType = arg0, arg1, arg2, arg3, arg4
				end
			else -- nX1, nY1, nZ1[, szType]
				local me = GetClientPlayer()
				nX1, nY1, nZ1, nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg0, arg1, arg2, arg3
			end
		else -- nX1, nY1
			local me = GetClientPlayer()
			nX1, nY1, nX2, nY2 = me.nX, me.nY, arg0, arg1
		end
	end
	if not szType or szType == 'global' then
		szType = LIB.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return max(floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, floor(abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

do local BUFF_CACHE = {}
function LIB.GetBuffName(dwBuffID, dwLevel)
	local xKey = dwBuffID
	if dwLevel then
		xKey = dwBuffID .. '_' .. dwLevel
	end
	if not BUFF_CACHE[xKey] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			BUFF_CACHE[xKey] = { tLine.szName, tLine.dwIconID }
		else
			local szName = 'BUFF#' .. dwBuffID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			BUFF_CACHE[xKey] = { szName, 1436 }
		end
	end
	return unpack(BUFF_CACHE[xKey])
end
end

-- 通过BUFF名称获取BUFF信息
-- (table) LIB.GetBuffByName(szName)
do local CACHE
function LIB.GetBuffByName(szName)
	if not CACHE then
		local aCache, tLine, tExist = {}
		for i = 1, g_tTable.Buff:GetRowCount() do
			tLine = g_tTable.Buff:GetRow(i)
			if tLine and tLine.szName then
				tExist = aCache[tLine.szName]
				if not tExist or (tLine.bShow == 1 and tExist.bShow == 0) then
					aCache[tLine.szName] = tLine
				end
			end
		end
		CACHE = aCache
	end
	return CACHE[szName]
end
end

function LIB.GetEndTime(nEndFrame, bAllowNegative)
	if bAllowNegative then
		return (nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
	end
	return max(0, nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
end

-- 获取指定名字的右键菜单
function LIB.GetTargetContextMenu(dwType, szName, dwID)
	local t = {}
	if dwType == TARGET.PLAYER then
		-- 复制
		insert(t, {
			szOption = _L['copy'],
			fnAction = function()
				LIB.Talk(GetClientPlayer().szName, '[' .. szName .. ']')
			end,
		})
		-- 密聊
		-- insert(t, {
		--     szOption = _L['whisper'],
		--     fnAction = function()
		--         LIB.SwitchChat(szName)
		--     end,
		-- })
		-- 密聊 好友 邀请入帮 跟随
		Call(InsertPlayerCommonMenu, t, dwID, szName)
		-- insert invite team
		if szName and InsertInviteTeamMenu then
			InsertInviteTeamMenu(t, szName)
		end
		-- get dwID
		if not dwID and MY_Farbnamen then
			local tInfo = MY_Farbnamen.GetAusName(szName)
			if tInfo then
				dwID = tonumber(tInfo.dwID)
			end
		end
		-- insert view equip
		if dwID and UI_GetClientPlayerID() ~= dwID then
			insert(t, {
				szOption = _L['show equipment'],
				fnAction = function()
					ViewInviteToPlayer(dwID)
				end,
			})
		end
		-- insert view arena
		insert(t, {
			szOption = g_tStrings.LOOKUP_CORPS,
			-- fnDisable = function() return not GetPlayer(dwID) end,
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
						insert(t, vv)
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
				insert(t, v)
			end
		end
	end

	return t
end

-- 获取秘境选择菜单
-- (table) LIB.GetDungeonMenu(fnAction, bOnlyRaid)
do
local function RecruitItemToDungeonMenu(p, fnAction, tChecked)
	if p.bParent then
		local t = { szOption = p.TypeName or p.SubTypeName }
		for _, pp in ipairs(p) do
			insert(t, RecruitItemToDungeonMenu(pp, fnAction, tChecked))
		end
		if #t > 0 then
			return t
		end
	else
		-- 不限阵营 有地图ID 7点开始 持续24小时 基本就是秘境了
		if p.nCamp == 7
		and p.nStartTime == 7 and p.nLastTime == 24
		and p.dwMapID and LIB.IsDungeonMap(p.dwMapID) then
			return {
				szOption = p.szName,
				bCheck = tChecked and true or false,
				bChecked = tChecked and tChecked[p.dwMapID] or false,
				bDisable = false,
				UserData = {
					dwID = p.dwMapID,
					szName = p.szName,
				},
				fnAction = fnAction,
			}
		end
	end
	return nil
end
function LIB.GetDungeonMenu(fnAction, bOnlyRaid, tChecked)
	local t = {}
	for _, p in ipairs(LIB.Table_GetTeamRecruit() or {}) do
		insert(t, RecruitItemToDungeonMenu(p, fnAction, tChecked))
	end
	return t
end
end

function LIB.GetTypeGroupMap()
	local aGroup, tMapExist = {}, {}
	-- 类型排序权重
	local tWeight = {} -- { ['风起稻香'] = 20, ['风起稻香 - 小队秘境'] = 21 }
	local nCount, tLine, szVersionName = g_tTable.DLCInfo:GetRowCount()
	for i = 2, nCount do
		tLine = g_tTable.DLCInfo:GetRow(i)
		szVersionName = LIB.TrimString(tLine.szDLCName)
		tWeight[szVersionName] = 2000 + i * 10
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
	local tDungeon = {}
	local nCount, tLine, szVersionName, szGroup, dwMapID = g_tTable.DungeonInfo:GetRowCount()
	for i = 2, nCount do
		tLine = g_tTable.DungeonInfo:GetRow(i)
		szVersionName = LIB.TrimString(tLine.szVersionName)
		szGroup = szVersionName
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
		if not CONSTANT.MAP_NAME_FIX[tLine.dwMapID] and not tMapExist[tLine.dwMapID] then
			if not tDungeon[szGroup] then
				tDungeon[szGroup] = {}
			end
			insert(tDungeon[szGroup], {
				dwID = tLine.dwMapID,
				szName = tLine.szLayer3Name .. tLine.szOtherName,
			})
			tMapExist[tLine.dwMapID] = szGroup
		end
	end
	for szGroup, aMapInfo in pairs(tDungeon) do
		insert(aGroup, { szGroup = szGroup, aMapInfo = aMapInfo })
	end
	-- 非秘境
	local tMap = {}
	local nCount, tLine, szGroup = g_tTable.MapList:GetRowCount()
	for i = 2, nCount do
		tLine = g_tTable.MapList:GetRow(i)
		if tLine.szType == 'BIRTH' or tLine.szType == 'SCHOOL' then
			szGroup = _L.MAP_GROUP['Birth / School']
		elseif tLine.szType == 'CITY' or tLine.szType == 'OLD_CITY' then
			szGroup = _L.MAP_GROUP['City / Old city']
		elseif tLine.szType == 'VILLAGE' or tLine.szType == 'OLD_VILLAGE' then
			szGroup = _L.MAP_GROUP['Village / Camp']
		elseif tLine.szType == 'BATTLE_FIELD' or tLine.szType == 'ARENA' then
			szGroup = _L.MAP_GROUP['Battle field / Arena']
		elseif tLine.szType == 'OTHER' or tLine.szType == '' then
			szGroup = _L.MAP_GROUP['Other']
		elseif tLine.szType == 'DUNGEON' or tLine.szType == 'RAID' then
			szGroup = _L.MAP_GROUP['Other dungeon']
		else
			szGroup = nil
		end
		if szGroup and not CONSTANT.MAP_NAME_FIX[tLine.nID] and not tMapExist[tLine.nID] then
			if not tMap[szGroup] then
				tMap[szGroup] = {}
			end
			insert(tMap[szGroup], {
				dwID = tLine.nID,
				szName = tLine.szName,
			})
			tMapExist[tLine.nID] = szGroup
		end
	end
	for szGroup, aMapInfo in pairs(tMap) do
		insert(aGroup, { szGroup = szGroup, aMapInfo = aMapInfo })
	end
	-- 排序
	sort(aGroup, function(a, b)
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

function LIB.GetRegionGroupMap()
	local tMapRegion = {}
	local nCount = g_tTable.MapList:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.MapList:GetRow(i)
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
					insert(tRegion.aRaid, { dwID = tLine.nID, szName = tLine.szMiddleMap })
				else
					if not tRegion.aDungeon then
						tRegion.aDungeon = {}
					end
					insert(tRegion.aDungeon, { dwID = tLine.nID, szName = tLine.szMiddleMap })
				end
			else
				if not tRegion.aMap then
					tRegion.aMap = {}
				end
				insert(tRegion.aMap, { dwID = tLine.nID, szName = tLine.szMiddleMap })
			end
		end
	end
	local aRegion = {}
	local nCount = g_tTable.RegionMap:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.RegionMap:GetRow(i)
		local info = tMapRegion[tLine.dwRegionID]
		if info then
			insert(aRegion, {
				dwID = tLine.dwRegionID,
				szName = tLine.szRegionName,
				aMapInfo = info.aMap,
				aRaidInfo = info.aRaid,
				aDungeonInfo = info.aDungeon,
			})
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
function LIB.GetActivityQuest(szType)
	local aQuestID = {}
	local me = GetClientPlayer()
	local date = TimeToDate(GetCurrentTime())
	local aActive = Table_GetActivityOfDay(date.year, date.month, date.day, ACTIVITY_UI.CALENDER)
	for _, p in ipairs(aActive) do
		if (szType == 'WEEK_TEAM_DUNGEON' and p.szName == _L.ACTIVITY_MAP_TYPE.WEEK_TEAM_DUNGEON)
		or (szType == 'WEEK_RAID_DUNGEON' and p.szName == _L.ACTIVITY_MAP_TYPE.WEEK_RAID_DUNGEON)
		or (szType == 'WEEK_PUBLIC_QUEST' and p.szName == _L.ACTIVITY_MAP_TYPE.WEEK_PUBLIC_QUEST) then
			for _, szQuestID in ipairs(LIB.SplitString(p.szQuestID, ';')) do
				local tLine = Table_GetCalenderActivityQuest(szQuestID)
				if tLine and tLine.nNpcTemplateID ~= -1 then
					local nQuestID = select(2, me.RandomByDailyQuest(szQuestID, tLine.nNpcTemplateID))
					if nQuestID then
						insert(aQuestID, {nQuestID, tLine.nNpcTemplateID})
					end
				end
			end
		end
	end
	return aQuestID
end

-- 获取指定活动地图列表
-- szType枚举值见 @{{武林通鉴 szType 枚举}}
function LIB.GetActivityMap(szType)
	local aMap = {}
	local aQuestInfo = LIB.GetActivityQuest(szType)
	for _, p in ipairs(aQuestInfo) do
		local tInfo = p[1] and Table_GetQuestStringInfo(p[1])
		local dwMapID = tInfo and tInfo.dwDungeonID
		local map = dwMapID and LIB.GetMapInfo(dwMapID)
		if map then
			insert(aMap, map)
		end
	end
	return aMap
end

-- 获取秘境CD列表（异步）
-- (table) LIB.GetMapSaveCopy(fnAction)
-- (number|nil) LIB.GetMapSaveCopy(dwMapID, fnAction)
do
local QUEUE = {}
local SAVED_COPY_CACHE, REQUEST_FRAME
function LIB.GetMapSaveCopy(arg0, arg1)
	local dwMapID, fnAction
	if IsFunction(arg0) then
		fnAction = arg0
	elseif IsNumber(arg0) then
		if IsFunction(arg1) then
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
			insert(QUEUE, { dwMapID = dwMapID, fnAction = fnAction })
		end
		if REQUEST_FRAME ~= GetLogicFrameCount() then
			ApplyMapSaveCopy()
			REQUEST_FRAME = GetLogicFrameCount()
		end
	end
end

function LIB.IsDungeonResetable(dwMapID)
	if not SAVED_COPY_CACHE then
		return
	end
	if not LIB.IsDungeonMap(dwMapID, false) then
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
LIB.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', onApplyPlayerSavedCopyRespond)

local function onCopyUpdated()
	SAVED_COPY_CACHE = nil
end
LIB.RegisterEvent('ON_RESET_MAP_RESPOND', onCopyUpdated)
LIB.RegisterEvent('ON_MAP_COPY_PROGRESS_UPDATE', onCopyUpdated)
end

-- 获取日常周常下次刷新时间和刷新周期
-- (dwTime, dwCircle) LIB.GetRefreshTime(szType)
-- @param szType {string} 刷新类型 daily weekly half-weekly
-- @return dwTime {number} 下次刷新时间
-- @return dwCircle {number} 刷新周期
function LIB.GetRefreshTime(szType)
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

function LIB.IsInSameRefreshTime(szType, dwTime)
	local nNextTime, nCircle = LIB.GetRefreshTime(szType)
	return nNextTime > dwTime and nNextTime - dwTime <= nCircle
end

-- 获取秘境地图刷新时间
-- (number nNextTime, number nCircle) LIB.GetDungeonRefreshTime(dwMapID)
function LIB.GetDungeonRefreshTime(dwMapID)
	local _, nMapType, nMaxPlayerCount = GetMapParams(dwMapID)
	if nMapType == MAP_TYPE.DUNGEON then
		if nMaxPlayerCount <= 5 then -- 5人本
			return LIB.GetRefreshTime('daily')
		end
		if nMaxPlayerCount <= 10 then -- 10人本
			return LIB.GetRefreshTime('half-weekly')
		end
		if nMaxPlayerCount <= 25 then -- 25人本
			return LIB.GetRefreshTime('weekly')
		end
	end
	return 0, 0
end

-- 地图首领列表
do local BOSS_LIST, BOSS_LIST_CUSTOM
local CACHE_PATH = {'temporary/bosslist.jx3dat', PATH_TYPE.GLOBAL}
local CUSTOM_PATH = {'config/bosslist.jx3dat', PATH_TYPE.GLOBAL}
local function LoadCustomList()
	if not BOSS_LIST_CUSTOM then
		BOSS_LIST_CUSTOM = LIB.LoadLUAData(CUSTOM_PATH) or {}
	end
end
local function SaveCustomList()
	LIB.SaveLUAData(CUSTOM_PATH, BOSS_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if BOSS_LIST and not bForceRefresh then
		return
	end
	LIB.CreateDataRoot(PATH_TYPE.GLOBAL)
	BOSS_LIST = LIB.LoadLUAData(CACHE_PATH)
	if bForceRefresh or not BOSS_LIST then
		BOSS_LIST = {}
		local nCount = g_tTable.DungeonBoss:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.DungeonBoss:GetRow(i)
			local dwMapID = tLine.dwMapID
			local szNpcList = tLine.szNpcList
			for szNpcIndex in gmatch(szNpcList, '(%d+)') do
				local p = g_tTable.DungeonNpc:Search(tonumber(szNpcIndex))
				if p then
					if not BOSS_LIST[dwMapID] then
						BOSS_LIST[dwMapID] = {}
					end
					BOSS_LIST[dwMapID][p.dwNpcID] = p.szName
				end
			end
		end
		LIB.SaveLUAData(CACHE_PATH, BOSS_LIST)
		LIB.Sysmsg(_L('Boss list updated to v%s.', select(2, GetVersion())))
	end

	for dwMapID, tInfo in pairs(LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/bosslist/{$lang}.jx3dat') or {}) do
		if not BOSS_LIST[dwMapID] then
			BOSS_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or CONSTANT.EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or CONSTANT.EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- 获取指定地图指定模板ID的NPC是不是首领
-- (boolean) LIB.IsBoss(dwMapID, dwTem)
function LIB.IsBoss(dwMapID, dwTemplateID)
	GenerateList()
	return (
		(
			BOSS_LIST[dwMapID] and BOSS_LIST[dwMapID][dwTemplateID]
			and not (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or false
end

LIB.RegisterTargetAddonMenu(PACKET_INFO.NAME_SPACE .. '#Game#Bosslist', function()
	local dwType, dwID = LIB.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = LIB.GetObject(dwType, dwID)
		local szName = LIB.GetObjectName(p)
		local dwMapID = GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if LIB.IsBoss(dwMapID, dwTemplateID) then
			return {
				szOption = _L['Remove from Boss list'],
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
					FireUIEvent('MY_SET_BOSS', dwMapID, dwTemplateID, false)
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, LIB.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		else
			return {
				szOption = _L['Add to Boss list'],
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
					FireUIEvent('MY_SET_BOSS', dwMapID, dwTemplateID, true)
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, LIB.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		end
	end
end)
end

-- 地图重要NPC列表
do local INPC_LIST, INPC_LIST_CUSTOM
local CACHE_PATH = {'temporary/inpclist.jx3dat', PATH_TYPE.GLOBAL}
local function LoadCustomList()
	if not INPC_LIST_CUSTOM then
		INPC_LIST_CUSTOM = LIB.LoadLUAData({'config/inpclist.jx3dat', PATH_TYPE.GLOBAL}) or {}
	end
end
local function SaveCustomList()
	LIB.SaveLUAData({'config/inpclist.jx3dat', PATH_TYPE.GLOBAL}, INPC_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if INPC_LIST and not bForceRefresh then
		return
	end
	INPC_LIST = LIB.LoadLUAData(CACHE_PATH)
	if bForceRefresh or not INPC_LIST then
		INPC_LIST = {}
		LIB.SaveLUAData(CACHE_PATH, INPC_LIST)
		LIB.Sysmsg(_L('Important Npc list updated to v%s.', select(2, GetVersion())))
	end
	for dwMapID, tInfo in pairs(LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/inpclist/{$lang}.jx3dat') or {}) do
		if not INPC_LIST[dwMapID] then
			INPC_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or CONSTANT.EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or CONSTANT.EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- 获取指定地图指定模板ID的NPC是不是重要NPC
-- (boolean) LIB.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
function LIB.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
	GenerateList()
	return (
		(
			INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID]
			and not (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or (not bNoBoss and LIB.IsBoss(dwMapID, dwTemplateID) or false)
end

-- 获取指定模板ID的NPC是不是被屏蔽的NPC
-- (boolean) LIB.IsShieldedNpc(dwTemplateID, szType)
function LIB.IsShieldedNpc(dwTemplateID, szType)
	if not Table_IsShieldedNpc then
		return false
	end
	local bShieldFocus, bShieldSpeak = Table_IsShieldedNpc(dwTemplateID)
	if szType == 'TALK' then
		return bShieldSpeak
	end
	return bShieldFocus
end

LIB.RegisterTargetAddonMenu(PACKET_INFO.NAME_SPACE .. '#Game#ImportantNpclist', function()
	local dwType, dwID = LIB.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = LIB.GetObject(dwType, dwID)
		local szName = LIB.GetObjectName(p)
		local dwMapID = GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if LIB.IsImportantNpc(dwMapID, dwTemplateID, true) then
			return {
				szOption = _L['Remove from important npc list'],
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
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, false)
				end,
			}
		else
			return {
				szOption = _L['Add to important npc list'],
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
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, true)
				end,
			}
		end
	end
end)
end

do
local SZ_FORCE_COLOR_FG = 'config/player_force_color.jx3dat'
local MY_FORCE_COLOR_FG_GLOBAL = LIB.LoadLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.GLOBAL}) or {}
local MY_FORCE_COLOR_FG_CUSTOM = {}
local MY_FORCE_COLOR_FG = setmetatable({}, {
	__index = function(t, k)
		return MY_FORCE_COLOR_FG_CUSTOM[k] or MY_FORCE_COLOR_FG_GLOBAL[k] or CONSTANT.FORCE_COLOR_FG_DEFAULT[k]
	end,
})

local SZ_FORCE_COLOR_BG = 'config/player_force_color_bg.jx3dat'
local MY_FORCE_COLOR_BG_GLOBAL = LIB.LoadLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.GLOBAL}) or {}
local MY_FORCE_COLOR_BG_CUSTOM = {}
local MY_FORCE_COLOR_BG = setmetatable({}, {
	__index = function(t, k)
		return MY_FORCE_COLOR_BG_CUSTOM[k] or MY_FORCE_COLOR_BG_GLOBAL[k] or CONSTANT.FORCE_COLOR_BG_DEFAULT[k]
	end,
})

local function initForceCustom()
	MY_FORCE_COLOR_FG_CUSTOM = LIB.LoadLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.ROLE}) or {}
	MY_FORCE_COLOR_BG_CUSTOM = LIB.LoadLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.ROLE}) or {}
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end
LIB.RegisterInit(initForceCustom)

function LIB.GetForceColor(dwForce, szType)
	local COLOR = szType == 'background'
		and MY_FORCE_COLOR_BG
		or MY_FORCE_COLOR_FG
	if dwForce == 'all' then
		return COLOR
	end
	return unpack(COLOR[dwForce])
end

function LIB.SetForceColor(dwForce, szType, tCol)
	if dwForce == 'reset' then
		MY_FORCE_COLOR_BG_CUSTOM = {}
		MY_FORCE_COLOR_FG_CUSTOM = {}
		LIB.SaveLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_BG_CUSTOM)
		LIB.SaveLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_FG_CUSTOM)
	elseif szType == 'background' then
		MY_FORCE_COLOR_BG_CUSTOM[dwForce] = tCol
		LIB.SaveLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_BG_CUSTOM)
	else
		MY_FORCE_COLOR_FG_CUSTOM[dwForce] = tCol
		LIB.SaveLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_FG_CUSTOM)
	end
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end

local SZ_CAMP_COLOR_FG = 'config/player_camp_color.jx3dat'
local MY_CAMP_COLOR_FG_GLOBAL = LIB.LoadLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.GLOBAL}) or {}
local MY_CAMP_COLOR_FG_CUSTOM = {}
local MY_CAMP_COLOR_FG = setmetatable({}, {
	__index = function(t, k)
		return MY_CAMP_COLOR_FG_CUSTOM[k] or MY_CAMP_COLOR_FG_GLOBAL[k] or CONSTANT.CAMP_COLOR_FG_DEFAULT[k]
	end,
})

local SZ_CAMP_COLOR_BG = 'config/player_camp_color_bg.jx3dat'
local MY_CAMP_COLOR_BG_GLOBAL = LIB.LoadLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.GLOBAL}) or {}
local MY_CAMP_COLOR_BG_CUSTOM = {}
local MY_CAMP_COLOR_BG = setmetatable({}, {
	__index = function(t, k)
		return MY_CAMP_COLOR_BG_CUSTOM[k] or MY_CAMP_COLOR_BG_GLOBAL[k] or CONSTANT.CAMP_COLOR_BG_DEFAULT[k]
	end,
})

local function initCampCustom()
	MY_CAMP_COLOR_FG_CUSTOM = LIB.LoadLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.ROLE}) or {}
	MY_CAMP_COLOR_BG_CUSTOM = LIB.LoadLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.ROLE}) or {}
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end
LIB.RegisterInit(initCampCustom)

function LIB.GetCampColor(nCamp, szType)
	local COLOR = szType == 'background'
		and MY_CAMP_COLOR_BG
		or MY_CAMP_COLOR_FG
	if nCamp == 'all' then
		return COLOR
	end
	return unpack(COLOR[nCamp])
end

function LIB.SetCampColor(nCamp, szType, tCol)
	if nCamp == 'reset' then
		MY_CAMP_COLOR_BG_CUSTOM = {}
		MY_CAMP_COLOR_FG_CUSTOM = {}
		LIB.SaveLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_BG_CUSTOM)
		LIB.SaveLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_FG_CUSTOM)
	elseif szType == 'background' then
		MY_CAMP_COLOR_BG_CUSTOM[nCamp] = tCol
		LIB.SaveLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_BG_CUSTOM)
	else
		MY_CAMP_COLOR_FG_CUSTOM[nCamp] = tCol
		LIB.SaveLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_FG_CUSTOM)
	end
	FireUIEvent('MY_CAMP_COLOR_UPDATE')
end
end

do
local FORCE_LIST
function LIB.GetForceIDS()
	FORCE_LIST = {}
	for _, dwForceID in pairs_c(CONSTANT.FORCE_TYPE) do
		if dwForceID ~= CONSTANT.FORCE_TYPE.JIANG_HU then
			insert(FORCE_LIST, dwForceID)
		end
	end
	return FORCE_LIST
end
end

do
local ORDER = {}
for i, p in ipairs(CONSTANT.KUNGFU_LIST) do
	ORDER[p.dwID] = i
end
local KUNGFU_LIST
function LIB.GetKungfuIDS()
	if not KUNGFU_LIST then
		KUNGFU_LIST = {}
		for _, dwForceID in ipairs(LIB.GetForceIDS()) do
			for _, dwKungfuID in ipairs(LIB.GetForceKungfuIDS(dwForceID)) do
				insert(KUNGFU_LIST, dwKungfuID)
			end
		end
		sort(KUNGFU_LIST, function(p1, p2)
			if not ORDER[p2] then
				return true
			end
			if not ORDER[p1] then
				return false
			end
			return ORDER[p1] < ORDER[p2]
		end)
	end
	return KUNGFU_LIST
end
end

do
local KUNGFU_NAME_CACHE = {}
local KUNGFU_SHORT_NAME_CACHE = {}
function LIB.GetKungfuName(dwKungfuID, szType)
	if not KUNGFU_NAME_CACHE[dwKungfuID] then
		KUNGFU_NAME_CACHE[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1) or ''
		KUNGFU_SHORT_NAME_CACHE[dwKungfuID] = wsub(KUNGFU_NAME_CACHE[dwKungfuID], 1, 2)
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
local NEARBY_PLAYER = {}   -- 附近的物品
local NEARBY_DOODAD = {}   -- 附近的玩家
local NEARBY_FIGHT = {}    -- 附近玩家和NPC战斗状态缓存

-- 获取指定对象
-- (KObject, info, bIsInfo) LIB.GetObject([number dwType, ]number dwID)
-- (KObject, info, bIsInfo) LIB.GetObject([number dwType, ]string szName)
-- dwType: [可选]对象类型枚举 TARGET.*
-- dwID  : 对象ID
-- return: 根据 dwType 类型和 dwID 取得操作对象
--         不存在时返回nil, nil
function LIB.GetObject(arg0, arg1, arg2)
	local dwType, dwID, szName
	if IsNumber(arg0) then
		if IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		elseif IsString(arg1) then
			dwType, szName = arg0, arg1
		elseif IsNil(arg1) then
			dwID = arg0
		end
	elseif IsString(arg0) then
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
				if LIB.GetObjectName(KObject) == szName then
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
		local me = GetClientPlayer()
		if me and dwID == me.dwID then
			p, info, b = me, me, false
		elseif me and me.IsPlayerInMyParty(dwID) then
			p, info, b = GetPlayer(dwID), GetClientTeam().GetMemberInfo(dwID), true
		else
			p, info, b = GetPlayer(dwID), GetPlayer(dwID), false
		end
	elseif dwType == TARGET.NPC then
		p, info, b = GetNpc(dwID), GetNpc(dwID), false
	elseif dwType == TARGET.DOODAD then
		p, info, b = GetDoodad(dwID), GetDoodad(dwID), false
	elseif dwType == TARGET.ITEM then
		p, info, b = GetItem(dwID), GetItem(dwID), GetItem(dwID)
	end
	return p, info, b
end

-- 根据模板ID获取NPC真实名称
local NPC_NAME_CACHE, DOODAD_NAME_CACHE = {}, {}
function LIB.GetTemplateName(dwType, dwTemplateID)
	local CACHE = dwType == TARGET.NPC and NPC_NAME_CACHE or DOODAD_NAME_CACHE
	local szName
	if CACHE[dwTemplateID] then
		szName = CACHE[dwTemplateID]
	end
	if not szName then
		if dwType == TARGET.NPC then
			szName = CONSTANT.NPC_NAME[dwTemplateID] or Table_GetNpcTemplateName(CONSTANT.NPC_NAME_FIX[dwTemplateID] or dwTemplateID)
		else
			szName = CONSTANT.DOODAD_NAME[dwTemplateID] or Table_GetDoodadTemplateName(CONSTANT.DOODAD_NAME_FIX[dwTemplateID] or dwTemplateID)
		end
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		CACHE[dwTemplateID] = szName or ''
	end
	if IsEmpty(szName) then
		szName = nil
	end
	return szName
end

-- 获取指定对象的名字
-- LIB.GetObjectName(obj, eRetID)
-- LIB.GetObjectName(dwType, dwID, eRetID)
-- (KObject) obj    要获取名字的对象
-- (string)  eRetID 是否返回对象ID信息
--    'auto'   名字为空时返回 -- 默认值
--    'always' 总是返回
--    'never'  总是不返回
local OBJECT_NAME = {
	['PLAYER'   ] = LIB.CreateCache('LIB#GetObjectName#PLAYER.v'   ),
	['NPC'      ] = LIB.CreateCache('LIB#GetObjectName#NPC.v'      ),
	['DOODAD'   ] = LIB.CreateCache('LIB#GetObjectName#DOODAD.v'   ),
	['ITEM'     ] = LIB.CreateCache('LIB#GetObjectName#ITEM.v'     ),
	['ITEM_INFO'] = LIB.CreateCache('LIB#GetObjectName#ITEM_INFO.v'),
	['UNKNOWN'  ] = LIB.CreateCache('LIB#GetObjectName#UNKNOWN.v'  ),
}
function LIB.GetObjectName(arg0, arg1, arg2, arg3, arg4)
	local KObject, szType, dwID, nExtraID, eRetID
	if IsNumber(arg0) then
		local dwType = arg0
		dwID, eRetID = arg1, arg2
		KObject = LIB.GetObject(dwType, dwID)
		if dwType == TARGET.PLAYER then
			szType = 'PLAYER'
		elseif dwType == TARGET.NPC then
			szType = 'NPC'
		elseif dwType == TARGET.DOODAD then
			szType = 'DOODAD'
		else
			szType = 'UNKNOWN'
		end
	elseif IsString(arg0) then
		if arg0 == 'PLAYER' or arg0 == 'NPC' or arg0 == 'DOODAD' then
			if IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			else
				local dwType = TARGET[arg0]
				dwID, eRetID = arg1, arg2
				KObject = LIB.GetObject(dwType, dwID)
				szType = arg0
			end
		elseif arg0 == 'ITEM' then
			if IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif IsNumber(arg3) then
				local p = GetPlayer(arg1)
				if p then
					KObject = p.GetItem(arg2, arg3)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg4
				end
			elseif IsNumber(arg2) then
				local p = GetClientPlayer()
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
			if IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif IsNumber(arg3) then
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
			szType = LIB.GetObjectType(KObject)
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
			cache.bFull = not IsEmpty(szName)
		elseif szType == 'NPC' then
			szDispType = 'N'
			if KObject then
				if IsEmpty(szName) then
					szName = LIB.GetTemplateName(TARGET.NPC, KObject.dwTemplateID)
				end
				if KObject.dwEmployer and KObject.dwEmployer ~= 0 then
					if LIB.Table_IsSimplePlayer(KObject.dwTemplateID) then -- 长歌影子
						szName = LIB.GetObjectName(GetPlayer(KObject.dwEmployer), eRetID)
					elseif not IsEmpty(szName) then
						local szEmpName = LIB.GetObjectName(
							(IsPlayer(KObject.dwEmployer) and GetPlayer(KObject.dwEmployer)) or GetNpc(KObject.dwEmployer),
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
			if KObject and IsEmpty(szName) then
				szName = LIB.Table_GetDoodadTemplateName(KObject.dwTemplateID)
				if szName then
					szName = szName:gsub('^%s*(.-)%s*$', '%1')
				end
			end
			cache.bFull = true
		elseif szType == 'ITEM' then
			szDispType = 'I'
			if KObject then
				szName = LIB.GetItemNameByItem(KObject)
			end
			cache.bFull = true
		elseif szType == 'ITEM_INFO' then
			szDispType = 'II'
			if KObject then
				szName = LIB.GetItemNameByItemInfo(KObject, nExtraID)
			end
			cache.bFull = true
		else
			szDispType = '?'
			cache.bFull = false
		end
		if szType == 'NPC' then
			szDispID = LIB.ConvertNpcID(dwID)
			if KObject then
				szDispID = szDispID .. '@' .. KObject.dwTemplateID
			end
		else
			szDispID = dwID
		end
		if IsEmpty(szName) then
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
local CACHE = LIB.CreateCache('LIB#GetObjectType.v')
function LIB.GetObjectType(obj)
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
-- (table) LIB.GetNearNpc(void)
function LIB.GetNearNpc(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_NPC) do
		local npc = GetNpc(k)
		if not npc then
			NEARBY_NPC[k] = nil
		else
			insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

function LIB.GetNearNpcID(nLimit)
	local aNpcID = {}
	for k, _ in pairs(NEARBY_NPC) do
		insert(aNpcID, k)
		if nLimit and #aNpcID == nLimit then
			break
		end
	end
	return aNpcID
end

if IsDebugClient() then
function LIB.GetNearNpcTable()
	return NEARBY_NPC
end
end

-- 获取附近PET列表
-- (table) LIB.GetNearPet(void)
function LIB.GetNearPet(nLimit)
	local aPet = {}
	for k, _ in pairs(NEARBY_PET) do
		local npc = GetNpc(k)
		if not npc then
			NEARBY_PET[k] = nil
		else
			insert(aPet, npc)
			if nLimit and #aPet == nLimit then
				break
			end
		end
	end
	return aPet
end

function LIB.GetNearPetID(nLimit)
	local aPetID = {}
	for k, _ in pairs(NEARBY_PET) do
		insert(aPetID, k)
		if nLimit and #aPetID == nLimit then
			break
		end
	end
	return aPetID
end

if IsDebugClient() then
function LIB.GetNearPetTable()
	return NEARBY_PET
end
end

-- 获取附近玩家列表
-- (table) LIB.GetNearPlayer(void)
function LIB.GetNearPlayer(nLimit)
	local aPlayer = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		local p = GetPlayer(k)
		if not p then
			NEARBY_PLAYER[k] = nil
		else
			insert(aPlayer, p)
			if nLimit and #aPlayer == nLimit then
				break
			end
		end
	end
	return aPlayer
end

function LIB.GetNearPlayerID(nLimit)
	local aPlayerID = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		insert(aPlayerID, k)
		if nLimit and #aPlayerID == nLimit then
			break
		end
	end
	return aPlayerID
end

if IsDebugClient() then
function LIB.GetNearPlayerTable()
	return NEARBY_PLAYER
end
end

-- 获取附近物品列表
-- (table) LIB.GetNearPlayer(void)
function LIB.GetNearDoodad(nLimit)
	local aDoodad = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		local doodad = GetDoodad(dwID)
		if not doodad then
			NEARBY_DOODAD[dwID] = nil
		else
			insert(aDoodad, doodad)
			if nLimit and #aDoodad == nLimit then
				break
			end
		end
	end
	return aDoodad
end

function LIB.GetNearDoodadID(nLimit)
	local aDoodadID = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		insert(aDoodadID, dwID)
		if nLimit and #aDoodadID == nLimit then
			break
		end
	end
	return aDoodadID
end

if IsDebugClient() then
function LIB.GetNearDoodadTable()
	return NEARBY_DOODAD
end
end

LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#FIGHT_HINT_TRIGGER', function()
	for dwID, tar in pairs(NEARBY_NPC) do
		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
			NEARBY_FIGHT[dwID] = tar.bFightState
			FireUIEvent(PACKET_INFO.NAME_SPACE .. '_NPC_FIGHT_HINT', dwID, tar.bFightState)
		end
	end
	for dwID, tar in pairs(NEARBY_PLAYER) do
		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
			NEARBY_FIGHT[dwID] = tar.bFightState
			FireUIEvent(PACKET_INFO.NAME_SPACE .. '_PLAYER_FIGHT_HINT', dwID, tar.bFightState)
		end
	end
end)
LIB.RegisterEvent('NPC_ENTER_SCENE', function()
	local npc = GetNpc(arg0)
	if npc and npc.dwEmployer ~= 0 then
		NEARBY_PET[arg0] = npc
	end
	NEARBY_NPC[arg0] = npc
	NEARBY_FIGHT[arg0] = npc and npc.bFightState or false
end)
LIB.RegisterEvent('NPC_LEAVE_SCENE', function()
	NEARBY_PET[arg0] = nil
	NEARBY_NPC[arg0] = nil
	NEARBY_FIGHT[arg0] = nil
end)
LIB.RegisterEvent('PLAYER_ENTER_SCENE', function()
	local player = GetPlayer(arg0)
	NEARBY_PLAYER[arg0] = player
	NEARBY_FIGHT[arg0] = player and player.bFightState or false
end)
LIB.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	NEARBY_PLAYER[arg0] = nil
	NEARBY_FIGHT[arg0] = nil
end)
LIB.RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = GetDoodad(arg0) end)
LIB.RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
end

do local CACHE = {}
function LIB.GetFurnitureInfo(szKey, oVal)
	if szKey == 'nRepresentID' then
		szKey = 'dwModelID'
	end
	if not CACHE[szKey] then
		CACHE[szKey] = {}
		for i = 2, g_tTable.HomelandFurnitureInfo:GetRowCount() do
			local tLine = g_tTable.HomelandFurnitureInfo:GetRow(i)
			if tLine and tLine[szKey] then
				CACHE[szKey][tLine[szKey]] = tLine
			end
		end
	end
	return Clone(CACHE[szKey][oVal])
end
end

local Homeland_GetNearbyObjectsInfo = _G.Homeland_GetNearbyObjectsInfo or GetInsideEnv().Homeland_GetNearbyObjectsInfo
function LIB.GetNearFurniture(nDis)
	if not Homeland_GetNearbyObjectsInfo then
		return CONSTANT.EMPTY_TABLE
	end
	if not nDis then
		nDis = 6
	end
	local aFurniture, tID = {}, {}
	for _, p in ipairs(Homeland_GetNearbyObjectsInfo(nDis)) do
		local dwID = LIB.NumberBitShl(p.BaseId, 32, 64) + p.InstID
		local info = not tID[dwID] and LIB.GetFurnitureInfo('nRepresentID', p.RepresentID)
		if info then
			info.dwID = dwID
			info.nInstID = p.InstID
			info.nBaseID = p.BaseId
			insert(aFurniture, info)
			tID[dwID] = true
		end
	end
	return aFurniture
end

-- 打开一个拾取交互物件（当前帧重复调用仅打开一次防止庖丁）
function LIB.OpenDoodad(me, doodad)
	LIB.Throttle(PACKET_INFO.NAME_SPACE .. '#OpenDoodad' .. doodad.dwID, 375, function()
		--[[#DEBUG BEGIN]]
		LIB.Debug('Open Doodad ' .. doodad.dwID .. ' [' .. doodad.szName .. '] at ' .. GetLogicFrameCount() .. '.', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		OpenDoodad(me, doodad)
	end)
end

-- 交互一个拾取交互物件（当前帧重复调用仅交互一次防止庖丁）
function LIB.InteractDoodad(dwID)
	LIB.Throttle(PACKET_INFO.NAME_SPACE .. '#InteractDoodad' .. dwID, 375, function()
		--[[#DEBUG BEGIN]]
		LIB.Debug('Open Doodad ' .. dwID .. ' at ' .. GetLogicFrameCount() .. '.', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		InteractDoodad(dwID)
	end)
end

-- 获取玩家自身信息（缓存）
do local m_ClientInfo
function LIB.GetClientInfo(arg0)
	if arg0 == true or not (m_ClientInfo and m_ClientInfo.dwID) then
		local me = GetClientPlayer()
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
	if IsString(arg0) then
		return m_ClientInfo[arg0]
	end
	return m_ClientInfo
end

local function onLoadingEnding()
	LIB.GetClientInfo(true)
end
LIB.RegisterEvent('LOADING_ENDING', onLoadingEnding)
end

-- 获取唯一标识符
do local m_szUUID
function LIB.GetClientUUID()
	if not m_szUUID then
		local me = GetClientPlayer()
		if me.GetGlobalID and me.GetGlobalID() ~= '0' then
			m_szUUID = me.GetGlobalID()
		else
			m_szUUID = (LIB.GetRealServer()):gsub('[/\\|:%*%?"<>]', '') .. '_' .. LIB.GetClientInfo().dwID
		end
	end
	return m_szUUID
end
end

do
local FRIEND_LIST_BY_ID, FRIEND_LIST_BY_NAME, FRIEND_LIST_BY_GROUP
local function GeneFriendListCache()
	if not FRIEND_LIST_BY_GROUP then
		local me = GetClientPlayer()
		if me then
			local infos = me.GetFellowshipGroupInfo()
			if infos then
				FRIEND_LIST_BY_ID = {}
				FRIEND_LIST_BY_NAME = {}
				FRIEND_LIST_BY_GROUP = {{ id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND or '' }} -- 默认分组
				for _, group in ipairs(infos) do
					insert(FRIEND_LIST_BY_GROUP, group)
				end
				for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
					for _, p in ipairs(me.GetFellowshipInfo(group.id) or {}) do
						insert(group, p)
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
LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , OnFriendListChange)
LIB.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , OnFriendListChange)
LIB.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , OnFriendListChange)
LIB.RegisterEvent('PLAYER_FOE_UPDATE'            , OnFriendListChange)
LIB.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , OnFriendListChange)
LIB.RegisterEvent('DELETE_FELLOWSHIP'            , OnFriendListChange)
LIB.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', OnFriendListChange)
-- 获取好友列表
-- LIB.GetFriendList()         获取所有好友列表
-- LIB.GetFriendList(1)        获取第一个分组好友列表
-- LIB.GetFriendList('挽月堂') 获取分组名称为挽月堂的好友列表
function LIB.GetFriendList(arg0)
	local t = {}
	local n = 0
	local tGroup = {}
	if GeneFriendListCache() then
		if type(arg0) == 'number' then
			insert(tGroup, FRIEND_LIST_BY_GROUP[arg0])
		elseif type(arg0) == 'string' then
			for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
				if group.name == arg0 then
					insert(tGroup, Clone(group))
				end
			end
		else
			tGroup = FRIEND_LIST_BY_GROUP
		end
		for _, group in ipairs(tGroup) do
			for _, p in ipairs(group) do
				t[p.id], n = Clone(p), n + 1
			end
		end
	end
	return t, n
end

-- 获取好友
function LIB.GetFriend(arg0)
	if arg0 and GeneFriendListCache() then
		if type(arg0) == 'number' then
			return Clone(FRIEND_LIST_BY_ID[arg0])
		elseif type(arg0) == 'string' then
			return Clone(FRIEND_LIST_BY_NAME[arg0])
		end
	end
end

function LIB.IsFriend(arg0)
	return LIB.GetFriend(arg0) and true or false
end
end

do
local FOE_LIST, FOE_LIST_BY_ID, FOE_LIST_BY_NAME
local function GeneFoeListCache()
	if not FOE_LIST then
		local me = GetClientPlayer()
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
						insert(FOE_LIST, p)
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
LIB.RegisterEvent('PLAYER_FOE_UPDATE', OnFoeListChange)
-- 获取仇人列表
function LIB.GetFoeList()
	if GeneFoeListCache() then
		return Clone(FOE_LIST)
	end
end
-- 获取仇人
function LIB.GetFoe(arg0)
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
function LIB.GetTongMemberList(bShowOffLine, szSorter, bAsc)
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

function LIB.GetTongName(dwTongID)
	local szTongName
	if not dwTongID then
		dwTongID = (GetClientPlayer() or CONSTANT.EMPTY_TABLE).dwTongID
	end
	if dwTongID and dwTongID ~= 0 then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, 253)
	else
		szTongName = ''
	end
	return szTongName
end

-- 获取帮会成员
function LIB.GetTongMember(arg0)
	if not arg0 then
		return
	end

	return GetTongClient().GetMemberInfo(arg0)
end

function LIB.IsTongMember(arg0)
	return LIB.GetTongMember(arg0) and true or false
end

-- 判断是不是队友
function LIB.IsParty(dwID)
	if dwID == UI_GetClientPlayerID() then
		return true
	end
	local me = GetClientPlayer()
	return me and me.IsPlayerInMyParty(dwID)
end

-- 判断关系
function LIB.GetRelation(dwSelfID, dwPeerID)
	if not dwPeerID then
		dwPeerID = dwSelfID
		dwSelfID = GetControlPlayerID()
	end
	if not IsPlayer(dwPeerID) then
		local npc = GetNpc(dwPeerID)
		if npc and npc.dwEmployer ~= 0 and GetPlayer(npc.dwEmployer) then
			dwPeerID = npc.dwEmployer
		end
	end
	if LIB.IsSelf(dwSelfID, dwPeerID) then
		return 'Self'
	end
	local dwSrcID, dwTarID = dwSelfID, dwPeerID
	if not IsPlayer(dwTarID) then
		dwSrcID, dwTarID = dwTarID, dwSrcID
	end
	if IsParty(dwSrcID, dwTarID) then
		return 'Party'
	elseif IsNeutrality(dwSrcID, dwTarID) then
		return 'Neutrality'
	elseif IsEnemy(dwSrcID, dwTarID) then -- 敌对关系
		if LIB.GetFoe(dwPeerID) then
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
function LIB.IsEnemy(dwSelfID, dwPeerID)
	return LIB.GetRelation(dwSelfID, dwPeerID) == 'Enemy'
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
	if LIB.IsFighting() then
		-- 进入战斗判断
		if not FIGHTING then
			FIGHTING = true
			-- 5秒脱战判定缓冲 防止明教隐身错误判定
			if not FIGHT_UUID
			or GetTickCount() - FIGHT_END_TICK > 5000 then
				-- 新的一轮战斗开始
				FIGHT_BEGIN_TICK = GetTickCount()
				FIGHT_UUID = FIGHT_BEGIN_TICK
				FireUIEvent(PACKET_INFO.NAME_SPACE .. '_FIGHT_HINT', true, FIGHT_UUID, 0)
			end
		end
	else
		-- 退出战斗判定
		if FIGHTING then
			FIGHT_END_TICK, FIGHTING = GetTickCount(), false
		elseif FIGHT_UUID and GetTickCount() - FIGHT_END_TICK > 5000 then
			LAST_FIGHT_UUID, FIGHT_UUID = FIGHT_UUID, nil
			FireUIEvent(PACKET_INFO.NAME_SPACE .. '_FIGHT_HINT', false, LAST_FIGHT_UUID, FIGHT_END_TICK - FIGHT_BEGIN_TICK)
		end
	end
end
LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#ListenFightStateChange', ListenFightStateChange)

-- 获取当前战斗时间
function LIB.GetFightTime(szFormat)
	local nTick = 0
	if FIGHTING then -- 战斗状态
		nTick = GetTickCount() - FIGHT_BEGIN_TICK
	else  -- 脱战状态
		nTick = FIGHT_END_TICK - FIGHT_BEGIN_TICK
	end

	if szFormat then
		local nSeconds = floor(nTick / 1000)
		local nMinutes = floor(nSeconds / 60)
		local nHours   = floor(nMinutes / 60)
		local nMinute  = nMinutes % 60
		local nSecond  = nSeconds % 60
		szFormat = szFormat:gsub('f', floor(nTick / 1000 * GLOBAL.GAME_FPS))
		szFormat = szFormat:gsub('H', nHours)
		szFormat = szFormat:gsub('M', nMinutes)
		szFormat = szFormat:gsub('S', nSeconds)
		szFormat = szFormat:gsub('hh', format('%02d', nHours ))
		szFormat = szFormat:gsub('mm', format('%02d', nMinute))
		szFormat = szFormat:gsub('ss', format('%02d', nSecond))
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
function LIB.GetFightUUID()
	return FIGHT_UUID
end

-- 获取上次战斗唯一标示符
function LIB.GetLastFightUUID()
	return LAST_FIGHT_UUID
end
end

-- 获取自身是否处于逻辑战斗状态
-- (bool) LIB.IsFighting()
do local ARENA_START = false
function LIB.IsFighting()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and LIB.IsInArena() and ARENA_START then
		bFightState = true
	elseif not bFightState and LIB.IsInDungeon() then
		-- 在秘境且附近队友进战且附近敌对NPC进战则判断处于战斗状态
		local bPlayerFighting, bNpcFighting
		for _, p in ipairs(LIB.GetNearPlayer()) do
			if me.IsPlayerInMyParty(p.dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for _, p in ipairs(LIB.GetNearNpc()) do
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
LIB.RegisterEvent('LOADING_ENDING.MY-PLAYER', function() ARENA_START = nil end)
LIB.RegisterEvent('ARENA_START.MY-PLAYER', function() ARENA_START = true end)
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
-- (dwType, dwID) LIB.GetTarget()       -- 取得自己当前的目标类型和ID
-- (dwType, dwID) LIB.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
function LIB.GetTarget(...)
	local object = ...
	if select('#', ...) == 0 then
		object = GetClientPlayer()
	end
	if object and object.GetTarget then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end

-- 取得目标的目标类型和ID
-- (dwType, dwID) LIB.GetTargetTarget()       -- 取得自己当前的目标的目标类型和ID
-- (dwType, dwID) LIB.GetTargetTarget(object) -- 取得指定操作对象当前的目标的目标类型和ID
function LIB.GetTargetTarget(object)
    local nTarType, dwTarID = LIB.GetTarget(object)
    local KTar = LIB.GetObject(nTarType, dwTarID)
    if not KTar then
        return
    end
    return LIB.GetTarget(KTar)
end

-- 根据 dwType 类型和 dwID 设置目标
-- (void) LIB.SetTarget([number dwType, ]number dwID)
-- (void) LIB.SetTarget([number dwType, ]string szName)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID
function LIB.SetTarget(arg0, arg1)
	local dwType, dwID, szNames
	if IsUserdata(arg0) then
		dwType, dwID = TARGET[LIB.GetObjectType(arg0)], arg0.dwID
	elseif IsString(arg0) then
		szNames = arg0
	elseif IsNumber(arg0) then
		if IsNil(arg1) then
			dwID = arg0
		elseif IsString(arg1) then
			dwType, szNames = arg0, arg1
		elseif IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		end
	end
	if not dwID and not szNames then
		return
	end
	if dwID and not dwType then
		dwType = IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC
	end
	if szNames then
		local tTarget = {}
		for _, szName in pairs(LIB.SplitString(szNames:gsub('[%[%]]', ''), '|')) do
			tTarget[szName] = true
		end
		if not dwID and (not dwType or dwType == TARGET.NPC) then
			for _, p in ipairs(LIB.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and (not dwType or dwType == TARGET.PLAYER) then
			for _, p in ipairs(LIB.GetNearPlayer()) do
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
	if dwType == TARGET.NPC then
		local npc = GetNpc(dwID)
		if npc and not npc.IsSelectable() and LIB.IsShieldedVersion('TARGET') then
			--[[#DEBUG BEGIN]]
			LIB.Debug('SetTarget', 'Set target to unselectable npc.', DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.DOODAD then
		if LIB.IsShieldedVersion('TARGET') then
			--[[#DEBUG BEGIN]]
			LIB.Debug('SetTarget', 'Set target to doodad.', DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	end
	SetTarget(dwType, dwID)
	return true
end

-- 设置/取消 临时目标
-- LIB.SetTempTarget(dwType, dwID)
-- LIB.ResumeTarget()
do
local TEMP_TARGET = { TARGET.NO_TARGET, 0 }
function LIB.SetTempTarget(dwType, dwID)
	TargetPanel_SetOpenState(true)
	TEMP_TARGET = { GetClientPlayer().GetTarget() }
	LIB.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end

function LIB.ResumeTarget()
	TargetPanel_SetOpenState(true)
	-- 当之前的目标不存在时，切到空目标
	if TEMP_TARGET[1] ~= TARGET.NO_TARGET and not LIB.GetObject(unpack(TEMP_TARGET)) then
		TEMP_TARGET = { TARGET.NO_TARGET, 0 }
	end
	LIB.SetTarget(unpack(TEMP_TARGET))
	TEMP_TARGET = { TARGET.NO_TARGET, 0 }
	TargetPanel_SetOpenState(false)
end
end

-- 临时设置目标为指定目标并执行函数
-- (void) LIB.WithTarget(dwType, dwID, callback)
do
local WITH_TARGET_LIST = {}
local LOCK_WITH_TARGET = false
local function WithTargetHandle()
	if LOCK_WITH_TARGET or
	#WITH_TARGET_LIST == 0 then
		return
	end

	LOCK_WITH_TARGET = true
	local r = remove(WITH_TARGET_LIST, 1)

	LIB.SetTempTarget(r.dwType, r.dwID)
	local res, err, trace = XpCall(r.callback)
	if not res then
		FireUIEvent('CALL_LUA_ERROR', err .. '\n' .. PACKET_INFO.NAME_SPACE .. '#WithTarget\n' .. trace .. '\n')
	end
	LIB.ResumeTarget()

	LOCK_WITH_TARGET = false
	WithTargetHandle()
end
function LIB.WithTarget(dwType, dwID, callback)
	-- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
	insert(WITH_TARGET_LIST, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	WithTargetHandle()
end
end

-- 求N2在N1的面向角  --  重载+2
-- (number) LIB.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) LIB.GetFaceAngel(oN1, oN2, bAbs)
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
function LIB.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
	if type(nY) == 'userdata' and type(nX) == 'userdata' then
		nX, nY, nFace, nTX, nTY, bAbs = nX.nX, nX.nY, nX.nFaceDirection, nY.nX, nY.nY, nFace
	end
	if type(nX) == 'number' and type(nY) == 'number' and type(nFace) == 'number'
	and type(nTX) == 'number' and type(nTY) == 'number' then
		local nFace = (nFace * 2 * PI / 255) - PI
		local nSight = (nX == nTX and ((nY > nTY and PI / 2) or - PI / 2)) or atan((nTY - nY) / (nTX - nX))
		local nAngel = ((nSight - nFace) % (PI * 2) - PI) / PI * 180
		if bAbs then
			nAngel = abs(nAngel)
		end
		return nAngel
	end
end

function LIB.GetBagPackageIndex()
	return LIB.IsInExtraBagMap()
		and INVENTORY_INDEX.LIMITED_PACKAGE
		or INVENTORY_INDEX.PACKAGE
end

function LIB.GetBagPackageCount()
	if _G.Bag_GetPacketCount then
		return _G.Bag_GetPacketCount()
	end
	return LIB.IsInExtraBagMap() and 1 or 6
end

function LIB.GetBankPackageCount()
	local me = GetClientPlayer()
	return me.GetBankPackageCount() + 1 -- 逻辑写挫了 返回的比真实的少一个
end

-- 获取背包空位总数
-- (number) LIB.GetFreeBagBoxNum()
function LIB.GetFreeBagBoxNum()
	local me, nFree = GetClientPlayer(), 0
	local nIndex = LIB.GetBagPackageIndex()
	for i = nIndex, nIndex + LIB.GetBagPackageCount() do
		nFree = nFree + me.GetBoxFreeRoomSize(i)
	end
	return nFree
end

-- 获取第一个背包空位
-- (number, number) LIB.GetFreeBagBox()
function LIB.GetFreeBagBox()
	local me = GetClientPlayer()
	local nIndex = LIB.GetBagPackageIndex()
	for i = nIndex, nIndex + LIB.GetBagPackageCount() do
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
-- (number dwBox, number dwX) LIB.WalkBagItem(fnWalker)
function LIB.WalkBagItem(fnWalker)
	local me = GetClientPlayer()
	local nIndex = LIB.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + LIB.GetBagPackageCount() do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local it = me.GetItem(dwBox, dwX)
			if it and fnWalker(it, dwBox, dwX) == 0 then
				return
			end
		end
	end
end

-- 获取一样东西在背包的数量
function LIB.GetItemAmount(dwTabType, dwIndex, nBookID)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if nBookID then
		local nBookID, nSegmentID = GlobelRecipeID2BookID(nBookID)
		return me.GetItemAmount(dwTabType, dwIndex, nBookID, nSegmentID)
	end
	return me.GetItemAmount(dwTabType, dwIndex)
end

-- 获取一样东西在背包、装备、仓库的数量
do local CACHE, FULL_CACHE
local function InsertItem(cache, it)
	if it then
		if it.nGenre == ITEM_GENRE.BOOK then
			local szKey = it.dwTabType .. ',' .. it.dwIndex .. ',' .. it.nBookID
			cache[szKey] = (cache[szKey] or 0) + (it.bCanStack and it.nStackNum or 1)
		else
			local szKey = it.dwTabType .. ',' .. it.dwIndex
			cache[szKey] = (cache[szKey] or 0) + (it.bCanStack and it.nStackNum or 1)
		end
	end
end
function LIB.GetItemAmountInAllPackages(dwTabType, dwIndex, nBookID, bFull)
	if IsBoolean(nBookID) then
		nBookID, bFull = nil, nBookID
	end
	local cache = CACHE
	if bFull then
		cache = FULL_CACHE
	end
	if not cache then
		cache = {}
		local me = GetClientPlayer()
		if not me then
			return
		end
		local nIndex = bFull and 1 or LIB.GetBagPackageIndex()
		local nCount = bFull and 7 or LIB.GetBagPackageCount()
		for dwBox = nIndex, nCount do
			for dwX = 0, me.GetBoxSize(dwBox) - 1 do
				InsertItem(cache, me.GetItem(dwBox, dwX))
			end
		end
		for dwBox = INVENTORY_INDEX.BANK, INVENTORY_INDEX.BANK + LIB.GetBankPackageCount() - 1 do
			for dwX = 0,  me.GetBoxSize(dwBox) - 1 do
				InsertItem(cache, GetPlayerItem(me, dwBox, dwX))
			end
		end
		for nLogicIndex = 0, CONSTANT.EQUIPMENT_SUIT_COUNT - 1 do
			local nSuitIndex = me.GetEquipIDArray(nLogicIndex)
			local dwBox = nSuitIndex == 0
				and INVENTORY_INDEX.EQUIP
				or INVENTORY_INDEX['EQUIP_BACKUP' .. nSuitIndex]
			for dwX = 0, EQUIPMENT_INVENTORY.TOTAL - 1 do
				InsertItem(cache, GetPlayerItem(me, dwBox, dwX))
			end
		end
		if bFull then
			FULL_CACHE = cache
		else
			CACHE = cache
		end
	end
	local szKey = dwTabType .. ',' .. dwIndex
	if nBookID then
		szKey = szKey .. ',' .. nBookID
	end
	return cache[szKey] or 0
end
LIB.RegisterEvent({
	'BAG_ITEM_UPDATE.' .. PACKET_INFO.NAME_SPACE .. '#LIB#GetItemAmountInAllPackages',
	'BANK_ITEM_UPDATE.' .. PACKET_INFO.NAME_SPACE .. '#LIB#GetItemAmountInAllPackages',
	'LOADING_ENDING.' .. PACKET_INFO.NAME_SPACE .. '#LIB#GetItemAmountInAllPackages'
}, function()
	CACHE, FULL_CACHE = nil
end)
end

-- 装备名为szName的装备
-- (void) LIB.Equip(szName)
-- szName  装备名称
function LIB.Equip(szName)
	local me = GetClientPlayer()
	for i=1,6 do
		if me.GetBoxSize(i) > 0 then
			for j = 0, me.GetBoxSize(i) - 1 do
				local item = me.GetItem(i, j)
				if item == nil then
					j=j + 1
				elseif LIB.GetItemNameByUIID(item.nUiId) == szName then -- LIB.GetItemNameByItem(item)
					local eRetCode, nEquipPos = me.GetEquipPos(i, j)
					if szName == _L['ji guan'] or szName == _L['nu jian'] then
						for k = 0,15 do
							if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, k) == nil then
								OnExchangeItem(i, j, INVENTORY_INDEX.BULLET_PACKAGE, k)
								return
							end
						end
						return
					else
						OnExchangeItem(i, j, INVENTORY_INDEX.EQUIP, nEquipPos)
						return
					end
				end
			end
		end
	end
end

-- 使用物品
-- (bool) LIB.UseItem(szName)
-- (bool) LIB.UseItem(dwTabType, dwIndex, nBookID)
function LIB.UseItem(dwTabType, dwIndex, nBookID)
	local bUse = false
	if IsString(dwTabType) then
		LIB.WalkBagItem(function(item, dwBox, dwX)
			if LIB.GetObjectName('ITEM', item) == dwTabType then
				bUse = true
				OnUseItem(dwBox, dwX)
				return 0
			end
		end)
	else
		LIB.WalkBagItem(function(item, dwBox, dwX)
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
-- 下标为 nIndex 的 BUFF 缓存
local BUFF_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_PROXY = setmetatable({}, { __mode = 'v' })
-- 下标为 目标对象 的 BUFF列表 缓存
local BUFF_LIST_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_LIST_PROXY = setmetatable({}, { __mode = 'v' })
-- 获取BUFF缓存标识
local function GetBuffKey(dwID, nLevel, dwSkillSrcID)
	return dwSkillSrcID .. ':' .. dwID .. ',' .. nLevel
end
-- 缓存保护
local function Reject()
	assert(false, 'Modify buff list from ' .. PACKET_INFO.NAME_SPACE .. '.GetBuffList is forbidden!')
end
-- 缓存检查
local function GeneObjectBuffCache(KObject, nIndex)
	-- 检查对象缓存
	local aCache, aProxy = BUFF_LIST_CACHE[KObject], BUFF_LIST_PROXY[KObject]
	if not aCache or not aProxy then
		aCache = {}
		aProxy = setmetatable({}, { __index = aCache, __newindex = Reject })
		BUFF_LIST_CACHE[KObject] = aCache
		BUFF_LIST_PROXY[KObject] = aProxy
	end
	-- 检查BUFF缓存
	local nCount, raw = 0
	for i = 1, KObject.GetBuffCount() or 0 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = KObject.GetBuff(i - 1)
		if dwID then
			if not BUFF_CACHE[nIndex] or not BUFF_PROXY[nIndex] then
				BUFF_CACHE[nIndex] = {}
				BUFF_PROXY[nIndex] = setmetatable({}, { __index = BUFF_CACHE[nIndex], __newindex = Reject })
			end
			nCount, raw = nCount + 1, BUFF_CACHE[nIndex]
			raw.szKey        = dwSkillSrcID .. ':' .. dwID .. ',' .. nLevel
			raw.dwID         = dwID
			raw.nLevel       = nLevel
			raw.bCanCancel   = bCanCancel
			raw.nEndFrame    = nEndFrame
			raw.nIndex       = nIndex
			raw.nStackNum    = nStackNum
			raw.dwSkillSrcID = dwSkillSrcID
			raw.bValid       = bValid
			raw.szName, raw.nIcon = LIB.GetBuffName(dwID, nLevel)
			aCache[nCount] = BUFF_PROXY[nIndex]
		end
	end
	-- 删除对象过期BUFF缓存
	for i = nCount + 1, aCache.nCount or 0 do
		aCache[i] = nil
	end
	aCache.nCount = nCount
	if nIndex then
		return BUFF_PROXY[nIndex]
	end
	return aProxy, nCount
end

-- 获取对象的buff列表和数量
-- (table, number) LIB.GetBuffList(KObject)
-- 注意：返回表每帧会重复利用，如有缓存需求请调用LIB.CloneBuff接口固化数据
function LIB.GetBuffList(KObject)
	if KObject then
		return GeneObjectBuffCache(KObject)
	end
	return CONSTANT.EMPTY_TABLE, 0
end

-- 获取对象的buff
-- tBuff: {[dwID1] = nLevel1, [dwID2] = nLevel2}
-- (table) LIB.GetBuff(dwID[, nLevel[, dwSkillSrcID]])
-- (table) LIB.GetBuff(KObject, dwID[, nLevel[, dwSkillSrcID]])
-- (table) LIB.GetBuff(tBuff[, dwSkillSrcID])
-- (table) LIB.GetBuff(KObject, tBuff[, dwSkillSrcID])
function LIB.GetBuff(KObject, dwID, nLevel, dwSkillSrcID)
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
	if IsNumber(dwSkillSrcID) and dwSkillSrcID > 0 then
		if KObject.GetBuffByOwner then
			for k, v in pairs(tBuff) do
				local KBuffNode = KObject.GetBuffByOwner(k, v, dwSkillSrcID)
				if KBuffNode then
					return GeneObjectBuffCache(KObject, KBuffNode.nIndex)
				end
			end
		else
			local aBuff, nCount, buff = LIB.GetBuffList(KObject)
			for i = 1, nCount do
				buff = aBuff[i]
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
-- (table) LIB.CancelBuff(KObject, dwID[, nLevel = 0])
function LIB.CancelBuff(KObject, dwID, nLevel)
	local KBuffNode = KObject.GetBuff(dwID, nLevel or 0)
	if KBuffNode then
		KObject.CancelBuff(KBuffNode.nIndex)
	end
end

function LIB.CloneBuff(buff, dst)
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
function LIB.IsBossFocusBuff(dwID, nLevel, nStackNum)
	if not BUFF_CACHE then
		BUFF_CACHE = {}
		for i = 2, g_tTable.BossFocusBuff:GetRowCount() do
			local tLine = g_tTable.BossFocusBuff:GetRow(i)
			if tLine then
				if not BUFF_CACHE[tLine.nBuffID] then
					BUFF_CACHE[tLine.nBuffID] = {}
				end
				BUFF_CACHE[tLine.nBuffID][tLine.nBuffLevel] = tLine.nBuffStack
			end
		end
	end
	return BUFF_CACHE[dwID] and BUFF_CACHE[dwID][nLevel] and nStackNum >= BUFF_CACHE[dwID][nLevel]
end
end

function LIB.IsVisibleBuff(dwID, nLevel)
	if Table_BuffIsVisible(dwID, nLevel) then
		return true
	end
	if LIB.IsBossFocusBuff(dwID, nLevel, 0xffff) then
		return true
	end
	return false
end

-- 获取对象是否无敌
-- (mixed) LIB.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function LIB.IsInvincible(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return nil
	elseif LIB.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end

-- 获取对象当前是否可读条
-- (bool) LIB.CanOTAction([object KObject])
function LIB.CanOTAction(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return
	end
	return KObject.nMoveState == MOVE_STATE.ON_STAND or KObject.nMoveState == MOVE_STATE.ON_FLOAT
end

-- 通过技能名称获取技能信息
-- (table) LIB.GetSkillByName(szName)
do local CACHE
function LIB.GetSkillByName(szName)
	if not CACHE then
		local aCache, tLine, tExist = {}
		for i = 1, g_tTable.Skill:GetRowCount() do
			tLine = g_tTable.Skill:GetRow(i)
			if tLine and tLine.dwIconID and tLine.fSortOrder and tLine.szName then
				tExist = aCache[tLine.szName]
				if not tExist or tLine.fSortOrder > tExist.fSortOrder then
					aCache[tLine.szName] = tLine
				end
			end
		end
		CACHE = aCache
	end
	return CACHE[szName]
end
end

-- 判断技能名称是否有效
-- (bool) LIB.IsValidSkill(szName)
function LIB.IsValidSkill(szName)
	if LIB.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) LIB.CanUseSkill(number dwSkillID[, dwLevel])
do
local box
function LIB.CanUseSkill(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == 'string' then
		if not LIB.IsValidSkill(dwSkillID) then
			return false
		end
		dwSkillID = LIB.GetSkillByName(dwSkillID).dwSkillID
	end
	if not box or not box:IsValid() then
		box = UI.GetTempElement('Box.MYLib_Skill')
	end
	local me = GetClientPlayer()
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
-- (string, number) LIB.GetSkillName(number dwSkillID[, number dwLevel])
do local SKILL_CACHE = {} -- 技能列表缓存 技能ID查技能名称图标
function LIB.GetSkillName(dwSkillID, dwLevel)
	if not SKILL_CACHE[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (StringFindW(tLine.szDesc, '_') == nil  or StringFindW(tLine.szDesc, '<') ~= nil)
		then
			SKILL_CACHE[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = 'SKILL#' .. dwSkillID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			SKILL_CACHE[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(SKILL_CACHE[dwSkillID])
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
RegisterEvent("ON_SKILL_REPLACE", OnSkillReplace)
RegisterEvent("CHANGE_SKILL_ICON", OnSkillReplace)

-- 获取一个心法的技能列表
-- LIB.GetKungfuSkillIDS(dwKungfuID)
-- 获取一个套路的技能列表
-- LIB.GetKungfuSkillIDS(dwKungfuID, dwMountKungfu)
function LIB.GetKungfuSkillIDS(dwKungfuID, dwMountKungfu)
	if not dwMountKungfu then
		dwMountKungfu = 0
	end
	if not (CACHE[dwKungfuID] and CACHE[dwKungfuID][dwMountKungfu]) then
		local aSkillID
		if not IsEmpty(dwMountKungfu) then -- 获取一个套路的技能列表
			if IsFunction(_G.Table_GetNewKungfuSkill) then -- 兼容旧版
				aSkillID = _G.Table_GetNewKungfuSkill(dwKungfuID, dwMountKungfu)
					or _G.Table_GetKungfuSkillList(dwMountKungfu)
			else
				aSkillID = Table_GetKungfuSkillList(dwMountKungfu, dwKungfuID)
			end
		else -- 获取一个心法的技能列表 遍历该心法的所有套路
			if IsFunction(_G.Table_GetNewKungfuSkill) and IsFunction(_G.Table_GetKungfuSkillList) then -- 兼容旧版
				aSkillID = _G.Table_GetKungfuSkillList(dwKungfuID)
			else
				aSkillID = {}
				for _, dwMKungfuID in ipairs(LIB.GetMKungfuIDS(dwKungfuID)) do
					for _, dwSkillID in ipairs(LIB.GetKungfuSkillIDS(dwKungfuID, dwMKungfuID)) do
						insert(aSkillID, dwSkillID)
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
	return CACHE[dwKungfuID]
end
end

-- 获取内功心法子套路列表（P面板左侧每列标题即为套路名）
do local CACHE = {}
function LIB.GetMKungfuIDS(dwKungfuID)
	if not CACHE[dwKungfuID] then
		CACHE[dwKungfuID] = Table_GetMKungfuList(dwKungfuID) or CONSTANT.EMPTY_TABLE
	end
	return CACHE[dwKungfuID]
end
end

do local CACHE = {}
function LIB.GetForceKungfuIDS(dwForceID)
	if not CACHE[dwForceID] then
		if IsFunction(_G.Table_GetSkillSchoolKungfu) then
			-- 这个API真是莫名其妙，明明是Force-Kungfu对应表，标题非写成School-Kungfu对应表
			CACHE[dwForceID] = _G.Table_GetSkillSchoolKungfu(dwForceID) or {}
		else
			local aKungfuList = {}
			local tLine = g_tTable.SkillSchoolKungfu:Search(dwForceID)
			if tLine then
				local szKungfu = tLine.szKungfu
				for s in gmatch(szKungfu, '%d+') do
					local dwID = tonumber(s)
					if dwID then
						insert(aKungfuList, dwID)
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
function LIB.GetSchoolForceID(dwSchoolID)
	if not CACHE[dwSchoolID] then
		if IsFunction(_G.Table_SchoolToForce) then
			CACHE[dwSchoolID] = _G.Table_SchoolToForce(dwSchoolID) or 0
		else
			local nCount = g_tTable.ForceToSchool:GetRowCount()
			local dwForceID = 0
			for i = 1, nCount do
				local tLine = g_tTable.ForceToSchool:GetRow(i)
				if dwSchoolID == tLine.dwSchoolID then
					dwForceID = tLine.dwForceID
				end
			end
			CACHE[dwSchoolID] = dwForceID or 0
		end
	end
	return CACHE[dwSchoolID]
end
end

function LIB.GetTargetSkillIDS(tar)
	local aSchoolID, aSkillID = tar.GetSchoolList(), {}
	for _, dwSchoolID in ipairs(aSchoolID) do
		local dwForceID = LIB.GetSchoolForceID(dwSchoolID)
		local aKungfuID = LIB.GetForceKungfuIDS(dwForceID)
		for _, dwKungfuID in ipairs(aKungfuID) do
			for _, dwSkillID in ipairs(LIB.GetKungfuSkillIDS(dwKungfuID)) do
				insert(aSkillID, dwSkillID)
			end
		end
	end
	return aSkillID
end

do
local LIST, LIST_ALL
function LIB.GetSkillMountList(bIncludePassive)
	if not LIST then
		LIST, LIST_ALL = {}, {}
		local me = GetClientPlayer()
		local aList = LIB.GetTargetSkillIDS(me)
		for _, dwID in ipairs(aList) do
			local nLevel = me.GetSkillLevel(dwID)
			if nLevel > 0 then
				local KSkill = GetSkill(dwID, nLevel)
				if not KSkill.bIsPassiveSkill then
					insert(LIST, dwID)
				end
				insert(LIST_ALL, dwID)
			end
		end
	end
	return bIncludePassive and LIST_ALL or LIST
end

local function onKungfuChange()
	LIST, LIST_ALL = nil
end
LIB.RegisterEvent('SKILL_MOUNT_KUNG_FU', onKungfuChange)
LIB.RegisterEvent('SKILL_UNMOUNT_KUNG_FU', onKungfuChange)
end

do
local SKILL_CACHE = setmetatable({}, { __mode = 'v' })
local SKILL_PROXY = setmetatable({}, { __mode = 'v' })
local function reject() assert(false, 'Modify skill info from LIB.GetSkill is forbidden!') end
function LIB.GetSkill(dwID, nLevel)
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
			szName = LIB.GetSkillName(dwID, nLevel),
			dwID = dwID,
			nLevel = nLevel,
			bLearned = nLevel > 0,
			nIcon = Table_GetSkillIconID(dwID, nLevel),
			dwExtID = LIB.Table_GetSkillExtCDID(dwID),
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
RegisterEvent("CHANGE_SKILL_SURFACE_NUM", OnChangeSkillSurfaceNum)
local function GetSkillCDProgress(dwID, nLevel, dwCDID, KObject)
	if dwCDID then
		return KObject.GetSkillCDProgress(dwID, nLevel, dwCDID)
	else
		return KObject.GetSkillCDProgress(dwID, nLevel)
	end
end
function LIB.GetSkillCDProgress(KObject, dwID, nLevel, bIgnorePublic)
	if not IsUserdata(KObject) then
		KObject, dwID, nLevel = GetClientPlayer(), KObject, dwID
	end
	if not nLevel then
		nLevel = KObject.GetSkillLevel(dwID)
	end
	if not nLevel then
		return
	end
	local KSkill, info = LIB.GetSkill(dwID, nLevel)
	if not KSkill or not info then
		return
	end
	-- # 更新CD相关的所有东西
	-- -- 附加技能CD
	-- if info.dwExtID then
	-- 	info.skillExt = LIB.GetTargetSkill(KObject, info.dwExtID)
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

-- 登出游戏
-- (void) LIB.Logout(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
function LIB.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) LIB.GetChannelSkillFrame(number dwSkillID, number nLevel)
function LIB.GetChannelSkillFrame(dwSkillID, nLevel)
	local skill = GetSkill(dwSkillID, nLevel)
	if skill then
		return skill.nChannelFrame
	end
end

function LIB.IsMarker(...)
	local dwID = select('#', ...) == 0 and UI_GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == dwID
end

function LIB.IsLeader(...)
	local dwID = select('#', ...) == 0 and UI_GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == dwID
end

function LIB.IsDistributer(...)
	local dwID = select('#', ...) == 0 and UI_GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == dwID
end

-- 判断自己在不在队伍里
-- (bool) LIB.IsInParty()
function LIB.IsInParty()
	local me = GetClientPlayer()
	return me and me.IsInParty()
end

-- 判断自己在不在团队里
-- (bool) LIB.IsInRaid()
function LIB.IsInRaid()
	local me = GetClientPlayer()
	return me and me.IsInRaid()
end

-- 判断当前地图是不是竞技场
-- (bool) LIB.IsInArena()
function LIB.IsInArena()
	local me = GetClientPlayer()
	return me and (
		me.GetScene().bIsArenaMap or -- JJC
		me.GetMapID() == 173 or      -- 齐物阁
		me.GetMapID() == 181         -- 狼影殿
	)
end

-- 判断当前地图是不是战场
-- (bool) LIB.IsInBattleField()
function LIB.IsInBattleField()
	local me = GetClientPlayer()
	return me and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD and not LIB.IsInArena()
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
				szName   = Table_GetMapName(dwMapID),
				bDungeon = false,
			}
			local tDungeonInfo = g_tTable.DungeonInfo:Search(dwMapID)
			if tDungeonInfo and tDungeonInfo.dwClassID == 3 then
				map.bDungeon = true
			end
			map = LIB.SetmetaReadonly(map)
			MAP_LIST[map.dwID] = map
			MAP_LIST[map.szName] = map
		end
		MAP_LIST = LIB.SetmetaReadonly(MAP_LIST)
	end
	return MAP_LIST
end

-- 判断一个地图是不是秘境
-- (bool) LIB.IsDungeonMap(szMapName, bRaid)
-- (bool) LIB.IsDungeonMap(dwMapID, bRaid)
function LIB.IsDungeonMap(dwMapID, bRaid)
	if not MAP_LIST then
		GenerateMapInfo()
	end
	local map = MAP_LIST[dwMapID]
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

-- 获取一个地图的信息
-- (table) LIB.GetMapInfo(dwMapID)
-- (table) LIB.GetMapInfo(szMapName)
function LIB.GetMapInfo(arg0)
	if not MAP_LIST then
		GenerateMapInfo()
	end
	if arg0 and CONSTANT.MAP_NAME_FIX[arg0] then
		arg0 = CONSTANT.MAP_NAME_FIX[arg0]
	end
	return MAP_LIST[arg0]
end
end

function LIB.GetMapNameList()
	local aList, tMap = {}, {}
	for k, v in ipairs_r(GetMapList()) do
		local szName = Table_GetMapName(v)
		if not tMap[szName] then
			tMap[szName] = true
			insert(aList, szName)
		end
	end
	return aList
end

-- 判断一个地图是不是个人CD秘境
-- (bool) LIB.IsDungeonRoleProgressMap(dwMapID)
function LIB.IsDungeonRoleProgressMap(dwMapID)
	return (select(8, GetMapParams(dwMapID)))
end

-- 判断当前地图是不是秘境
-- (bool) LIB.IsInDungeon(bool bRaid)
function LIB.IsInDungeon(bRaid)
	local me = GetClientPlayer()
	return me and LIB.IsDungeonMap(me.GetMapID(), bRaid)
end

-- 判断一个地图是不是主城
-- (bool) LIB.IsCityMap(dwMapID)
function LIB.IsCityMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.CITY and true or false
end

-- 判断当前地图是不是主城
-- (bool) LIB.IsInCity()
function LIB.IsInCity()
	local me = GetClientPlayer()
	return me and LIB.IsCityMap(me.GetMapID())
end

-- 判断地图是不是PUBG
-- (bool) LIB.IsPubgMap(dwMapID)
do
local PUBG_MAP = {}
function LIB.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = LIB.Table_IsTreasureBattleFieldMap(dwMapID) or false
	end
	return PUBG_MAP[dwMapID]
end
end

-- 判断当前地图是不是PUBG
-- (bool) LIB.IsInPubg()
function LIB.IsInPubg()
	local me = GetClientPlayer()
	return me and LIB.IsPubgMap(me.GetMapID())
end

-- 判断地图是不是僵尸地图
-- (bool) LIB.IsZombieMap(dwMapID)
do
local ZOMBIE_MAP = {}
function LIB.IsZombieMap(dwMapID)
	if ZOMBIE_MAP[dwMapID] == nil then
		ZOMBIE_MAP[dwMapID] = Table_IsZombieBattleFieldMap
			and Table_IsZombieBattleFieldMap(dwMapID) or false
	end
	return ZOMBIE_MAP[dwMapID]
end
end

-- 判断当前地图是不是僵尸地图
-- (bool) LIB.IsInZombieMap()
function LIB.IsInZombieMap()
	local me = GetClientPlayer()
	return me and LIB.IsZombieMap(me.GetMapID())
end

-- 判断地图是不是MOBA地图
-- (bool) LIB.IsMobaMap(dwMapID)
function LIB.IsMobaMap(dwMapID)
	return CONSTANT.MOBA_MAP[dwMapID] or false
end

-- 判断当前地图是不是MOBA地图
-- (bool) LIB.IsInMobaMap()
function LIB.IsInMobaMap()
	local me = GetClientPlayer()
	return me and LIB.IsMobaMap(me.GetMapID())
end

-- 判断地图是不是浪客行地图
-- (bool) LIB.IsStarveMap(dwMapID)
function LIB.IsStarveMap(dwMapID)
	return CONSTANT.STARVE_MAP[dwMapID] or false
end

-- 判断当前地图是不是浪客行地图
-- (bool) LIB.IsInStarveMap()
function LIB.IsInStarveMap()
	local me = GetClientPlayer()
	return me and LIB.IsStarveMap(me.GetMapID())
end

-- 判断地图是不是新背包地图
-- (bool) LIB.IsExtraBagMap(dwMapID)
function LIB.IsExtraBagMap(dwMapID)
	return LIB.IsPubgMap(dwMapID) or LIB.IsMobaMap(dwMapID) or LIB.IsStarveMap(dwMapID)
end

-- 判断当前地图是不是新背包地图
-- (bool) LIB.IsInExtraBagMap()
function LIB.IsInExtraBagMap()
	local me = GetClientPlayer()
	return me and LIB.IsExtraBagMap(me.GetMapID())
end

-- 判断地图是不是功能屏蔽地图
-- (bool) LIB.IsShieldedMap(dwMapID)
function LIB.IsShieldedMap(dwMapID)
	if LIB.IsPubgMap(dwMapID) or LIB.IsZombieMap(dwMapID) then
		return true
	end
	if IsAddonBanMap and IsAddonBanMap(dwMapID) then
		return true
	end
	return false
end

-- 判断当前地图是不是PUBG
-- (bool) LIB.IsInShieldedMap()
function LIB.IsInShieldedMap()
	local me = GetClientPlayer()
	return me and LIB.IsShieldedMap(me.GetMapID())
end

-- 获取主角当前所在地图
-- (number) LIB.GetMapID(bool bFix) 是否做修正
function LIB.GetMapID(bFix)
	local dwMapID = GetClientPlayer().GetMapID()
	return bFix and CONSTANT.MAP_NAME_FIX[dwMapID] or dwMapID
end

do local MARK_NAME = { _L['Cloud'], _L['Sword'], _L['Ax'], _L['Hook'], _L['Drum'], _L['Shear'], _L['Stick'], _L['Jade'], _L['Dart'], _L['Fan'] }
-- 获取标记中文名
-- (string) LIB.GetMarkName([number nIndex])
function LIB.GetMarkName(nIndex)
	if nIndex then
		return MARK_NAME[nIndex]
	else
		return Clone(MARK_NAME)
	end
end

function LIB.GetMarkIndex(dwID)
	if not LIB.IsInParty() then
		return
	end
	return GetClientTeam().GetMarkIndex(dwID)
end

-- 保存当前团队信息
-- (table) LIB.GetTeamInfo([table tTeamInfo])
function LIB.GetTeamInfo(tTeamInfo)
	local tList, me, team = {}, GetClientPlayer(), GetClientTeam()
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
		LIB.Sysmsg(_L('restore formation of %d group: %s', state.nGroup + 1, szName))
	end
	if state.nMark then -- 如果这货之前有标记
		team.SetTeamMark(state.nMark, dwID) -- 标记给他
		LIB.Sysmsg(_L('restore player marked as [%s]: %s', MARK_NAME[state.nMark], szName))
	end
end
-- 恢复团队信息
-- (bool) LIB.SetTeamInfo(table tTeamInfo)
function LIB.SetTeamInfo(tTeamInfo)
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	elseif not tTeamInfo then
		return false
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return LIB.Sysmsg(_L['You are not team leader, permission denied'])
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
				LIB.Sysmsg(_L('unable get player of %d group: #%d', nGroup + 1, dwID))
			else
				if not tSaved[szName] then
					szName = gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					LIB.Sysmsg(_L('unknown status: %s', szName))
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					LIB.Sysmsg(_L('need not adjust: %s', szName))
				else
					insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == tTeamInfo.szLeader then
					dwLeader = dwID
				end
				if szName == tTeamInfo.szMark then
					dwMark = dwID
				end
				if szName == tTeamInfo.szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
					LIB.Sysmsg(_L('restore distributor: %s', szName))
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
			remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- 直接丢过去
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					insert(tWrong[nGroup], dst)
				else -- bingo
					LIB.Sysmsg(_L('change group of [%s] to %d', dst.szName, nGroup + 1))
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			LIB.Sysmsg(_L('change group of [%s] to %d', src.szName, src.state.nGroup + 1))
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
		LIB.Sysmsg(_L('restore team marker: %s', tTeamInfo.szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		LIB.Sysmsg(_L('restore team leader: %s', tTeamInfo.szLeader))
	end
	LIB.Sysmsg(_L['Team list restored'])
end
end

function LIB.UpdateItemBoxExtend(box, nQuality)
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
function LIB.GetGlobalEffect(nID)
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

function LIB.GetCharInfo()
	local me = GetClientPlayer()
	local kungfu = GetClientPlayer().GetKungfuMount()
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
					insert(data, {
						category = true,
						label = category[1],
					})
					nSubLen, nSubIndex = category[2], 1
				end
			end
			insert(data, {
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
			insert(data, {
				szTip = h.szTip,
				label = h:Lookup(0):GetText(),
				value = h:Lookup(1):GetText(),
			})
		end
	end
	return data
end

function LIB.IsPhoneLock()
	local me = GetClientPlayer()
	return me and me.IsTradingMibaoSwitchOpen()
end

function LIB.IsAccountInDanger()
	local me = GetClientPlayer()
	return me.nAccountSecurityState == ACCOUNT_SECURITY_STATE.DANGER
end

function LIB.IsSafeLocked(nType)
	local me = GetClientPlayer()
	if nType == SAFE_LOCK_EFFECT_TYPE.TALK then -- 聊天锁比较特殊
		if me.GetSafeLockMaskInfo then
			local tLock = me.GetSafeLockMaskInfo()
			if tLock then
				return tLock[SAFE_LOCK_EFFECT_TYPE.TALK]
			end
		end
		if _G.SafeLock_IsTalkLocked then
			return _G.SafeLock_IsTalkLocked()
		end
		return false
	end
	if LIB.IsAccountInDanger() then
		return true
	end
	return not me.CheckSafeLock(nType)
end

function LIB.IsTradeLocked()
	if LIB.IsAccountInDanger() then
		return true
	end
	local me = GetClientPlayer()
	return me.bIsBankPasswordVerified == false
end

-- * 当前道具是否满足装备要求：包括身法，体型，门派，性别，等级，根骨，力量，体质
function LIB.DoesEquipmentSuit(item, bIsItem, player)
	if not player then
		player = GetClientPlayer()
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
local m_MountTypeToWeapon = {
	[CONSTANT.KUNGFU_TYPE.TIAN_CE  ] = WEAPON_DETAIL.SPEAR        , -- 天策内功=长兵类
	[CONSTANT.KUNGFU_TYPE.WAN_HUA  ] = WEAPON_DETAIL.PEN          , -- 万花内功=笔类
	[CONSTANT.KUNGFU_TYPE.CHUN_YANG] = WEAPON_DETAIL.SWORD        , -- 纯阳内功=短兵类
	[CONSTANT.KUNGFU_TYPE.QI_XIU   ] = WEAPON_DETAIL.DOUBLE_WEAPON, -- 七秀内功 = 双兵类
	[CONSTANT.KUNGFU_TYPE.SHAO_LIN ] = WEAPON_DETAIL.WAND         , -- 少林内功=棍类
	[CONSTANT.KUNGFU_TYPE.CANG_JIAN] = WEAPON_DETAIL.SWORD        , -- 藏剑内功=短兵类,重兵类 WEAPON_DETAIL.BIG_SWORD
	[CONSTANT.KUNGFU_TYPE.GAI_BANG ] = WEAPON_DETAIL.STICK        , -- 丐帮内功=短棒
	[CONSTANT.KUNGFU_TYPE.MING_JIAO] = WEAPON_DETAIL.KNIFE        , -- 明教内功=弯刀
	[CONSTANT.KUNGFU_TYPE.WU_DU    ] = WEAPON_DETAIL.FLUTE        , -- 五毒内功=笛类
	[CONSTANT.KUNGFU_TYPE.TANG_MEN ] = WEAPON_DETAIL.BOW          , -- 唐门内功=千机匣
	[CONSTANT.KUNGFU_TYPE.CANG_YUN ] = WEAPON_DETAIL.BLADE_SHIELD , -- 苍云内功=刀盾
	[CONSTANT.KUNGFU_TYPE.CHANG_GE ] = WEAPON_DETAIL.HEPTA_CHORD  , -- 长歌内功=琴
	[CONSTANT.KUNGFU_TYPE.BA_DAO   ]	= WEAPON_DETAIL.BROAD_SWORD  , -- 霸刀内功=组合刀
	[CONSTANT.KUNGFU_TYPE.PENG_LAI ]	= WEAPON_DETAIL.UMBRELLA     , -- 蓬莱内功=伞
	--WEAPON_DETAIL.FIST = 拳腕
	--WEAPON_DETAIL.DART = 弓弦
	--WEAPON_DETAIL.MACH_DART = 机关暗器
	--WEAPON_DETAIL.SLING_SHOT = 投掷
}
function LIB.IsItemFitKungfu(itemInfo, ...)
	if LIB.GetObjectType(itemInfo) == 'ITEM' then
		itemInfo = GetItemInfo(itemInfo.dwTabType, itemInfo.dwIndex)
	end
	local kungfu = ...
	local me = GetClientPlayer()
	if select('#', ...) == 0 then
		kungfu = me.GetKungfuMount()
	elseif IsNumber(kungfu) then
		kungfu = GetSkill(kungfu, me.GetSkillLevel(kungfu) or 1)
	end
	if itemInfo.nSub == CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
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
		local res = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
		aRecommendKungfuID = {}
		for i, v in ipairs(LIB.SplitString(res.kungfu_ids, "|")) do
			insert(aRecommendKungfuID, tonumber(v))
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

-- * 获取物品对应身上装备的位置
function LIB.GetItemEquipPos(item, nIndex)
	if not nIndex then
		nIndex = 1
	end
	local dwPackage, dwBox, nCount = INVENTORY_INDEX.EQUIP, 0, 1
	if item.nSub == CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if item.nDetail == WEAPON_DETAIL.BIG_SWORD then
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD
		else
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON
		end
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.ARROW then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.ARROW
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.CHEST then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.CHEST
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.HELM then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.HELM
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.AMULET then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.AMULET
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.RING then
		if nIndex == 1 then
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING
		else
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING
		end
		nCount = 2
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.WAIST then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.WAIST
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.PENDANT then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.PENDANT
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.PANTS then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.PANTS
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.BOOTS then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.BOOTS
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.BANGLE then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.BANGLE
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.BACK_EXTEND then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.FACE_EXTEND then
		dwBox = CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.HORSE then
		dwPackage, dwBox = GetClientPlayer().GetEquippedHorsePos()
	end
	return dwPackage, dwBox, nIndex, nCount
end

-- * 当前装备是否是比身上已经装备的更好
function LIB.IsBetterEquipment(item, dwPackage, dwBox)
	if item.nGenre ~= ITEM_GENRE.EQUIPMENT
	or item.nSub == CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND
	or item.nSub == CONSTANT.EQUIPMENT_SUB.BACK_EXTEND
	or item.nSub == CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	or item.nSub == CONSTANT.EQUIPMENT_SUB.BULLET
	or item.nSub == CONSTANT.EQUIPMENT_SUB.MINI_AVATAR
	or item.nSub == CONSTANT.EQUIPMENT_SUB.PET then
		return false
	end

	if not dwPackage or not dwBox then
		local nIndex, nCount = 0, 1
		while nIndex < nCount do
			dwPackage, dwBox, nIndex, nCount = LIB.GetItemEquipPos(item, nIndex + 1)
			if LIB.IsBetterEquipment(item, dwPackage, dwBox) then
				return true
			end
		end
		return false
	end

	local me = GetClientPlayer()
	local equipedItem = GetPlayerItem(me, dwPackage, dwBox)
	if not equipedItem then
		return false
	end
	if me.nLevel < me.nMaxLevel then
		return item.nEquipScore > equipedItem.nEquipScore
	end
	return (item.nEquipScore > equipedItem.nEquipScore) or (item.nLevel > equipedItem.nLevel and item.nQuality >= equipedItem.nQuality)
end

function LIB.GetCampImage(eCamp, bFight) -- ui\Image\UICommon\CommonPanel2.UITex
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
function LIB.GetUserRoleName()
	if IsFunction(GetUserRoleName) then
		return GetUserRoleName()
	end
	local me = GetClientPlayer()
	if me and not IsRemotePlayer(me.dwID) then
		_RoleName = me.szName
	end
	return _RoleName
end
end

do local ITEM_CACHE = {}
function LIB.GetItemNameByUIID(nUiId)
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

function LIB.GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return LIB.GetItemNameByUIID(item.nUiId)
end

function LIB.GetItemNameByItemInfo(itemInfo, nBookInfo)
	if itemInfo.nGenre == ITEM_GENRE.BOOK and nBookInfo then
		local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return LIB.GetItemNameByUIID(itemInfo.nUiId)
end

do local ITEM_CACHE = {}
function LIB.GetItemIconByUIID(nUiId)
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

function LIB.GetGuildBankBagSize(nPage)
	return CONSTANT.INVENTORY_GUILD_PAGE_BOX_COUNT
end

function LIB.GetGuildBankBagPos(nPage, nIndex)
	return CONSTANT.INVENTORY_GUILD_BANK, nPage * CONSTANT.INVENTORY_GUILD_PAGE_SIZE + nIndex - 1
end

function LIB.IsSelf(dwSrcID, dwTarID)
	if IsFunction(IsSelf) then
		return IsSelf(dwSrcID, dwTarID)
	end
	return dwSrcID ~= 0 and dwSrcID == dwTarID and IsPlayer(dwSrcID) and IsPlayer(dwTarID)
end

-- * 获取门派对应心法ID列表
do local m_tForceToKungfu
function LIB.ForceIDToKungfuIDs(dwForceID)
	if IsFunction(ForceIDToKungfuIDs) then
		return ForceIDToKungfuIDs(dwForceID)
	end
	if not m_tForceToKungfu then
		m_tForceToKungfu = {
			[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { 10002, 10003, },
			[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { 10021, 10028, },
			[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { 10026, 10062, },
			[CONSTANT.FORCE_TYPE.CHUN_YANG] = { 10014, 10015, },
			[CONSTANT.FORCE_TYPE.QI_XIU   ] = { 10080, 10081, },
			[CONSTANT.FORCE_TYPE.WU_DU    ] = { 10175, 10176, },
			[CONSTANT.FORCE_TYPE.TANG_MEN ] = { 10224, 10225, },
			[CONSTANT.FORCE_TYPE.CANG_JIAN] = { 10144, 10145, },
			[CONSTANT.FORCE_TYPE.GAI_BANG ] = { 10268, },
			[CONSTANT.FORCE_TYPE.MING_JIAO] = { 10242, 10243, },
			[CONSTANT.FORCE_TYPE.CANG_YUN ] = { 10389, 10390, },
			[CONSTANT.FORCE_TYPE.CHANG_GE ] = { 10447, 10448, },
			[CONSTANT.FORCE_TYPE.BA_DAO   ] = { 10464, },
		}
	end
	return m_tForceToKungfu[dwForceID] or {}
end
end

-- 追加小地图标记
-- (void) LIB.UpdateMiniFlag(number dwType, KObject tar, number nF1[, number nF2])
-- (void) LIB.UpdateMiniFlag(number dwType, number nX, number nZ, number nF1[, number nF2])
-- dwType -- 类型 由UI脚本指定 (enum MINI_MAP_POINT)
-- tar    -- 目标对象 KPlayer，KNpc，KDoodad
-- nF1    -- 图标帧次
-- nF2    -- 箭头帧次，默认 48 就行
function LIB.UpdateMiniFlag(dwType, tar, nF1, nF2, nFadeOutTime, argX)
	local m = Station.Lookup('Normal/Minimap/Wnd_Minimap/Minimap_Map')
	if not m then
		return
	end
	local nX, nZ, dwID
	if IsNumber(tar) then
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
function LIB.GetMiniAvatar(dwAvatarID, nRoleType)
	-- mini avatar
	local tInfo = g_tTable.RoleAvatar:Search(dwAvatarID)
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

-- 获取头像文件路径，帧序，是否动画
function LIB.GetForceAvatar(dwForceID)
	-- force avatar
	return unpack(CONSTANT.FORCE_AVATAR[dwForceID])
end

-- 获取头像文件路径，帧序，是否动画
function LIB.GetPlayerAvatar(dwForceID, nRoleType, dwAvatarID)
	local szFile, nFrame, bAnimate
	-- mini avatar
	if dwAvatarID and dwAvatarID > 0 then
		szFile, nFrame, bAnimate = LIB.GetMiniAvatar(dwAvatarID, nRoleType)
	end
	-- force avatar
	if not szFile and dwForceID then
		szFile, nFrame, bAnimate = LIB.GetForceAvatar(dwForceID)
	end
	return szFile, nFrame, bAnimate
end

-- 获取一个地图的成就列表（区分是否包含五甲）
local MAP_ACHI_NORMAL, MAP_ACHI_ALL
function LIB.GetMapAchievements(dwMapID, bWujia)
	if not MAP_ACHI_NORMAL then
		local tMapAchiNormal, tMapAchiAll = {}, {}
		local nCount = g_tTable.Achievement:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.Achievement:GetRow(i)
			if tLine and tLine.nVisible == 1 then
				for _, szID in ipairs(LIB.SplitString(tLine.szSceneID, '|', true)) do
					local dwID = tonumber(szID)
					if dwID then
						if tLine.dwGeneral == 1 then
							if not tMapAchiNormal[dwID] then
								tMapAchiNormal[dwID] = {}
							end
							insert(tMapAchiNormal[dwID], tLine.dwID)
						end
						if not tMapAchiAll[dwID] then
							tMapAchiAll[dwID] = {}
						end
						insert(tMapAchiAll[dwID], tLine.dwID)
					end
				end
			end
		end
		MAP_ACHI_NORMAL, MAP_ACHI_ALL = tMapAchiNormal, tMapAchiAll
	end
	if bWujia then
		return Clone(MAP_ACHI_ALL[dwMapID])
	end
	return Clone(MAP_ACHI_NORMAL[dwMapID])
end

function LIB.GetPlayerEquipInfo(player)
	local tEquipInfo = {}
	for nItemIndex = 0, EQUIPMENT_INVENTORY.TOTAL do
		local item = GetPlayerItem(player, INVENTORY_INDEX.EQUIP, nItemIndex)
		if item then
			-- 五行石
			local aSlotItem = {}
			for i = 1, item.GetSlotCount() do
				local nEnchantID = item.GetMountDiamondEnchantID(i - 1)
				if nEnchantID > 0 then
					local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(nEnchantID)
					if dwTabType and dwTabIndex then
						aSlotItem[i] = {dwTabType, dwTabIndex}
					end
				end
			end
			-- 五彩石
			local nEnchantID = item.GetMountFEAEnchantID()
			if nEnchantID ~= 0 then
				local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
				if dwTabType and dwTabIndex then
					aSlotItem[0] = {dwTabType, dwTabIndex}
				end
			end
			-- 插入结果集
			tEquipInfo[nItemIndex] = {
				dwTabType = item.dwTabType,
				dwTabIndex = item.dwIndex,
				nStrengthLevel = item.nStrengthLevel,
				aSlotItem = aSlotItem,
				dwPermanentEnchantID = item.dwPermanentEnchantID,
				dwTemporaryEnchantID = item.dwTemporaryEnchantID,
				dwTemporaryEnchantLeftSeconds = item.GetTemporaryEnchantLeftSeconds(),
			}
		end
	end
	return tEquipInfo
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
	['skill_notin_cd'] = 'SKILL',
	['tbuff'] = 'BUFF',
	['tnobuff'] = 'BUFF',
	['tbufftime'] = 'BUFF',
}
function LIB.IsMacroValid(szMacro)
	-- /cast [nobuff:太极] 太极无极
	local bDebug = LIB.IsDebugClient('MY_Macro')
	for nLine, szLine in ipairs(LIB.SplitString(szMacro, '\n')) do
		szLine = LIB.TrimString(szLine)
		if not IsEmpty(szLine) then
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
			if szActionType == 'SKILL' and not tonumber(szActionData) and not LIB.GetSkillByName(szActionData) then
				local szErrMsg = _L('Unknown action skill at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szActionData .. '}'
				end
				return false, 'UNKNOWN_ACTION_SKILL', nLine, szErrMsg
			elseif szActionType == 'BUFF' and not tonumber(szActionData) and not LIB.GetBuffByName(szActionData) then
				local szErrMsg = _L('Unknown action buff at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szActionData .. '}'
				end
				return false, 'UNKNOWN_ACTION_BUFF', nLine, szErrMsg
			end
			-- 校验条件
			for _, szSubCondition in ipairs(LIB.SplitString(szCondition, {'|', '&'}, true)) do
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
					if szJudgeType == 'SKILL' and not tonumber(szJudgeData) and not LIB.GetSkillByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition skill at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_CONDITION_SKILL', nLine, szErrMsg
					elseif szJudgeType == 'BUFF' and not tonumber(szJudgeData) and not LIB.GetBuffByName(szJudgeData) then
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
					if szJudge and not tonumber(szJudgeData) and not LIB.GetSkillByName(szJudgeData) then
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
