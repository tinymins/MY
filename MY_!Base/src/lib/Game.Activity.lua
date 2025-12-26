--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Activity')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- {{活动任务 szType 枚举}}
-- DAILY_BIG_WAR      大战·系列任务
-- DAILY_CAMP_ROUTINE 阵营日常
-- WEEK_TEAM_DUNGEON  武林通鉴·秘境
-- WEEK_RAID_DUNGEON  武林通鉴·团队秘境
-- WEEK_PUBLIC_QUEST  武林通鉴·公共任务

-- 获取指定活动任务列表
---@param szType string @szType枚举值见 {{活动任务 szType 枚举}}
---@return table @活动任务列表
function X.GetActivityQuest(szType)
	local aQuestID = {}
	local me = X.GetClientPlayer()
	local date = TimeToDate(GetCurrentTime())
	local aActive = Table_GetActivityOfDay(date.year, date.month, date.day, ACTIVITY_UI.CALENDER)
	for _, p in ipairs(aActive) do
		if p.szQuestID and (
			(szType == p.szName)
			or (szType == 'DAILY_BIG_WAR' and p.szName == _L.ACTIVITY_DAILY_BIG_WAR)
			or (szType == 'DAILY_CAMP_ROUTINE' and p.szName == _L.ACTIVITY_DAILY_CAMP_ROUTINE)
			or (szType == 'WEEK_TEAM_DUNGEON' and p.szName == _L.ACTIVITY_WEEK_TEAM_DUNGEON)
			or (szType == 'WEEK_RAID_DUNGEON' and p.szName == _L.ACTIVITY_WEEK_RAID_DUNGEON)
			or (szType == 'WEEK_PUBLIC_QUEST' and p.szName == _L.ACTIVITY_WEEK_PUBLIC_QUEST)
		) then
			for _, szQuestID in ipairs(X.SplitString(p.szQuestID, ';')) do
				local dwQuestID = tonumber(szQuestID)
				local tLine = dwQuestID and Table_GetCalenderActivityQuest(dwQuestID)
				if tLine and tLine.nNpcTemplateID ~= -1 then
					local nQuestID = select(2, me.RandomByDailyQuest(dwQuestID, tLine.nNpcTemplateID))
					if nQuestID then
						table.insert(aQuestID, {nQuestID, tLine.nNpcTemplateID})
					end
				end
			end
		end
	end
	if szType == 'DAILY_BIG_WAR' and #aQuestID == 0 then
		local szPattern = '^' .. _L['Big war']
		local tLine
		for nLine = 1, g_tTable.Quests:GetRowCount() do
			tLine = g_tTable.Quests:GetRow(nLine)
			if tLine.szName:find(szPattern) then
				table.insert(aQuestID, {tLine.nID, 869})
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
