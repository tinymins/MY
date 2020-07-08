--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 任务统计（日常统计）
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
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_TaskStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

local DB = LIB.ConnectDatabase(_L['MY_RoleStatistics_TaskStat'], {'userdata/role_statistics/task_stat.v2.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_TaskStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_TaskStat.ini'

DB:Execute('CREATE TABLE IF NOT EXISTS Task (guid NVARCHAR(20), name NVARCHAR(255), task_info NVARCHAR(65535), PRIMARY KEY(guid))')
local DB_TaskW = DB:Prepare('REPLACE INTO Task (guid, name, task_info) VALUES (?, ?, ?)')
local DB_TaskR = DB:Prepare('SELECT * FROM Task')
local DB_TaskD = DB:Prepare('DELETE FROM TaskInfo WHERE guid = ?')
DB:Execute('CREATE TABLE IF NOT EXISTS TaskInfo (guid NVARCHAR(20), account NVARCHAR(255), region NVARCHAR(20), server NVARCHAR(20), name NVARCHAR(20), force INTEGER, camp INTEGER, level INTEGER, task_info NVARCHAR(65535), buff_info NVARCHAR(65535), time INTEGER, PRIMARY KEY(guid))')
local DB_TaskInfoW = DB:Prepare('REPLACE INTO TaskInfo (guid, account, region, server, name, force, camp, level, task_info, buff_info, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_TaskInfoG = DB:Prepare('SELECT * FROM TaskInfo WHERE guid = ?')
local DB_TaskInfoR = DB:Prepare('SELECT * FROM TaskInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_TaskInfoD = DB:Prepare('DELETE FROM TaskInfo WHERE guid = ?')

local D = {}
local O = {
	aColumn = {
		'name',
		'force',
		'big_war', -- 大战
		'teahouse', -- 茶馆
		'crystal_scramble', -- 晶矿争夺
		'stronghold_trade', -- 据点贸易
		'dragon_gate_despair', -- 龙门绝境
		'lexus_reality', -- 列星虚境
		'lidu_ghost_town', -- 李渡鬼城
		'public_routine', -- 公共日常
		'force_routine', -- 勤修不辍
		'rookie_routine', -- 浪客行
		'picking_fairy_grass', -- 采仙草
		'find_dragon_veins', -- 寻龙脉
		'illustration_routine', -- 美人图
		'sneak_routine', -- 美人图潜行
		'exam_sheng', -- 省试
		'exam_hui', -- 会试
		'time_days',
	},
	szSort = 'time_days',
	szSortOrder = 'desc',
	bFloatEntry = false,
	bAdviceFloatEntry = false,
	bSaveDB = false,
	bAdviceSaveDB = false,
}
RegisterCustomData('Global/MY_RoleStatistics_TaskStat.aColumn')
RegisterCustomData('Global/MY_RoleStatistics_TaskStat.szSort')
RegisterCustomData('Global/MY_RoleStatistics_TaskStat.szSortOrder')
RegisterCustomData('MY_RoleStatistics_TaskStat.bFloatEntry')
RegisterCustomData('MY_RoleStatistics_TaskStat.bAdviceFloatEntry')
RegisterCustomData('MY_RoleStatistics_TaskStat.bSaveDB', 20200618)
RegisterCustomData('MY_RoleStatistics_TaskStat.bAdviceSaveDB', 20200618)

local TASK_TYPE = {
	DAILY = 1,
	WEEKLY = 2,
	HALF_WEEKLY = 3,
	ONECE = 4,
}
local TASK_TYPE_STRING = {
	[TASK_TYPE.DAILY] = _L['Daily'],
	[TASK_TYPE.WEEKLY] = _L['Weekly'],
	[TASK_TYPE.HALF_WEEKLY] = _L['Half-weekly'],
	[TASK_TYPE.ONECE] = _L['Onece'],
}
local function IsInSamePeriod(dwTime, eType)
	if eType == TASK_TYPE.ONECE then
		return true
	end
	local nNextTime, nCircle
	if eType == TASK_TYPE.DAILY then
		nNextTime, nCircle = LIB.GetRefreshTime('daily')
	elseif eType == TASK_TYPE.WEEKLY then
		nNextTime, nCircle = LIB.GetRefreshTime('weekly')
	elseif eType == TASK_TYPE.HALF_WEEKLY then
		nNextTime, nCircle = LIB.GetRefreshTime('half-weekly')
	end
	return dwTime >= nNextTime - nCircle
end

local TASK_STATE = {
	ACCEPTABLE = 1,
	ACCEPTED = 2,
	FINISHABLE = 3,
	FINISHED = 4,
	UNACCEPTABLE = 5,
	UNKNOWN = 6,
}
local function GetTaskState(me, dwQuestID, dwNpcTemplateID)
	-- 获取身上任务状态 -1: 任务id非法 0: 任务不存在 1: 任务正在进行中 2: 任务完成但还没有交 3: 任务已完成
	local nState = me.GetQuestPhase(dwQuestID)
	if nState == 1 then
		return TASK_STATE.ACCEPTED
	end
	if nState == 2 then
		return TASK_STATE.FINISHABLE
	end
	if nState == 3 then
		return TASK_STATE.FINISHED
	end
	-- 获取任务状态
	if me.GetQuestState(dwQuestID) == QUEST_STATE.FINISHED then
		return TASK_STATE.FINISHED
	end
	-- 获取是否可接
	local eCanAccept = me.CanAcceptQuest(dwQuestID, dwNpcTemplateID)
	if eCanAccept == QUEST_RESULT.SUCCESS then
		return TASK_STATE.ACCEPTABLE
	end
	if eCanAccept == QUEST_RESULT.ALREADY_ACCEPTED then
		return TASK_STATE.ACCEPTED
	end
	if eCanAccept == QUEST_RESULT.FINISHED_MAX_COUNT then
		return TASK_STATE.FINISHED
	end
	-- local KQuestInfo = GetQuestInfo(dwQuestID)
	-- if KQuestInfo.bRepeat then -- 可重复任务没到达上限一定可接（有时候地图不对会误判不可接受）
	-- 	return TASK_STATE.ACCEPTABLE
	-- end
	-- if eCanAccept == QUEST_RESULT.FAILED then
	-- 	return TASK_STATE.UNACCEPTABLE
	-- end
	return TASK_STATE.UNKNOWN
end

local EXCEL_WIDTH = 960
local TASK_MIN_WIDTH = 35
local TASK_MAX_WIDTH = 150
local function GeneCommonFormatText(id)
	return function(r)
		return GetFormatText(r[id], 162, 255, 255, 255)
	end
end
local function GeneCommonCompare(id)
	return function(r1, r2)
		if r1[id] == r2[id] then
			return 0
		end
		return r1[id] > r2[id] and 1 or -1
	end
end
local COLUMN_LIST = {
	-- guid,
	-- account,
	{ -- 大区
		id = 'region',
		bHideInFloat = true,
		szTitle = _L['Region'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('region'),
		Compare = GeneCommonCompare('region'),
	},
	{ -- 服务器
		id = 'server',
		bHideInFloat = true,
		szTitle = _L['Server'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('server'),
		Compare = GeneCommonCompare('server'),
	},
	{ -- 名字
		id = 'name',
		bHideInFloat = true,
		szTitle = _L['Name'],
		nMinWidth = 110, nMaxWidth = 200,
		GetFormatText = function(rec)
			local name = rec.name
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name, 162, LIB.GetForceColor(rec.force, 'foreground'))
		end,
		Compare = GeneCommonCompare('name'),
	},
	{ -- 门派
		id = 'force',
		bHideInFloat = true,
		szTitle = _L['Force'],
		nMinWidth = 50, nMaxWidth = 70,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.tForceTitle[rec.force], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('force'),
	},
	{ -- 阵营
		id = 'camp',
		bHideInFloat = true,
		szTitle = _L['Camp'],
		nMinWidth = 50, nMaxWidth = 50,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.STR_CAMP_TITLE[rec.camp], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('camp'),
	},
	{ -- 等级
		id = 'level',
		bHideInFloat = true,
		szTitle = _L['Level'],
		nMinWidth = 50, nMaxWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- 时间
		id = 'time',
		bHideInFloat = true,
		szTitle = _L['Cache time'],
		nMinWidth = 165, nMaxWidth = 200,
		GetFormatText = function(rec)
			return GetFormatText(LIB.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
	{ -- 时间计时
		id = 'time_days',
		bHideInFloat = true,
		szTitle = _L['Cache time days'],
		nMinWidth = 120, nMaxWidth = 120,
		GetFormatText = function(rec)
			local nTime = GetCurrentTime() - rec.time
			local nSeconds = floor(nTime)
			local nMinutes = floor(nSeconds / 60)
			local nHours   = floor(nMinutes / 60)
			local nDays    = floor(nHours / 24)
			local nYears   = floor(nDays / 365)
			local nDay     = nDays % 365
			local nHour    = nHours % 24
			local nMinute  = nMinutes % 60
			local nSecond  = nSeconds % 60
			if nYears > 0 then
				return GetFormatText(_L('%d years %d days before', nYears, nDay), 162, 255, 255, 255)
			end
			if nDays > 0 then
				return GetFormatText(_L('%d days %d hours before', nDays, nHour), 162, 255, 255, 255)
			end
			if nHours > 0 then
				return GetFormatText(_L('%d hours %d mins before', nHours, nMinute), 162, 255, 255, 255)
			end
			if nMinutes > 0 then
				return GetFormatText(_L('%d mins %d secs before', nMinutes, nSecond), 162, 255, 255, 255)
			end
			if nSecond > 10 then
				return GetFormatText(_L('%d secs before', nSecond), 162, 255, 255, 255)
			end
			return GetFormatText(_L['Just now'], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
}
local TASK_LIST, TASK_HASH
local function InitTaskList(bReload)
	if TASK_LIST and not bReload then
		return
	end
	local aTask = {}
	-- 内嵌数据
	-- 大战
	insert(aTask, {
		id = 'big_war',
		szTitle = _L['Big war'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.BIG_WARS,
	})
	-- 茶馆
	insert(aTask, {
		id = 'teahouse',
		szTitle = _L['Teahouse'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.TEAHOUSE_ROUTINE,
	})
	-- 勤修不辍
	insert(aTask, {
		id = 'force_routine',
		szTitle = _L['Force routine'],
		eType = TASK_TYPE.DAILY,
		tForceQuestInfo = CONSTANT.QUEST_INFO.FORCE_ROUTINE,
	})
	-- 浪客行
	insert(aTask, {
		id = 'rookie_routine',
		szTitle = _L['Rookie routine'],
		eType = TASK_TYPE.WEEKLY,
		aQuestInfo = CONSTANT.QUEST_INFO.ROOKIE_ROUTINE,
	})
	-- 晶矿争夺
	insert(aTask, {
		id = 'crystal_scramble',
		szTitle = _L['Crystal scramble'],
		eType = TASK_TYPE.DAILY,
		tCampQuestInfo = CONSTANT.QUEST_INFO.CAMP_CRYSTAL_SCRAMBLE,
	})
	-- 据点贸易
	insert(aTask, {
		id = 'stronghold_trade',
		szTitle = _L['Stronghold trade'],
		eType = TASK_TYPE.DAILY,
		tCampQuestInfo = CONSTANT.QUEST_INFO.CAMP_STRONGHOLD_TRADE,
	})
	-- 龙门绝境
	insert(aTask, {
		id = 'dragon_gate_despair',
		szTitle = _L['Dragon gate despair'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.DRAGON_GATE_DESPAIR,
	})
	-- 列星虚境
	insert(aTask, {
		id = 'lexus_reality',
		szTitle = _L['Lexus reality'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.LEXUS_REALITY,
	})
	-- 李渡鬼城
	insert(aTask, {
		id = 'lidu_ghost_town',
		szTitle = _L['Lidu ghost town'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.LIDU_GHOST_TOWN,
	})
	-- 公共日常
	insert(aTask, {
		id = 'public_routine',
		szTitle = _L['Public routine'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.PUBLIC_ROUTINE,
	})
	-- 采仙草
	insert(aTask, {
		id = 'picking_fairy_grass',
		szTitle = _L['Picking fairy grass'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.PICKING_FAIRY_GRASS,
	})
	-- 寻龙脉
	insert(aTask, {
		id = 'find_dragon_veins',
		szTitle = _L['Find dragon veins'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.FIND_DRAGON_VEINS,
	})
	-- 美人图
	insert(aTask, {
		id = 'illustration_routine',
		szTitle = _L['Illustration routine'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.ILLUSTRATION_ROUTINE,
	})
	-- 美人图潜行
	insert(aTask, {
		id = 'sneak_routine',
		szTitle = _L['Sneak routine'],
		eType = TASK_TYPE.DAILY,
		aQuestInfo = CONSTANT.QUEST_INFO.SNEAK_ROUTINE,
	})
	-- 省试
	insert(aTask, {
		id = 'exam_sheng',
		szTitle = _L['Exam sheng'],
		eType = TASK_TYPE.WEEKLY,
		aBuffInfo = CONSTANT.BUFF_INFO.EXAM_SHENG,
	})
	-- 会试
	insert(aTask, {
		id = 'exam_hui',
		szTitle = _L['Exam hui'],
		eType = TASK_TYPE.WEEKLY,
		aBuffInfo = CONSTANT.BUFF_INFO.EXAM_HUI,
	})
	-- 用户自定义数据
	DB_TaskR:ClearBindings()
	DB_TaskR:BindAll()
	for _, v in ipairs(DB_TaskR:GetAll()) do
		local tTaskInfo = DecodeLUAData(v.task_info) or {}
		insert(aTask, {
			id = v.guid,
			szTitle = v.name,
			eType = tTaskInfo.type or TASK_TYPE.DAILY,
			aQuestInfo = tTaskInfo.quests,
			tCampQuestInfo = tTaskInfo.camp_quests,
			tForceQuestInfo = tTaskInfo.force_quests,
			aBuffInfo = tTaskInfo.buffs,
			tCampBuffInfo = tTaskInfo.camp_buffs,
			tForceBuffInfo = tTaskInfo.force_buffs,
		})
	end
	TASK_LIST = aTask
	-- 高速id键索引
	local tTask = setmetatable({}, {
		__index = function(_, id)
			if id == 'week_team_dungeon' then
				return {
					id = id,
					szTitle = _L.ACTIVITY_MAP_TYPE.WEEK_TEAM_DUNGEON,
					eType = TASK_TYPE.WEEKLY,
					aQuestInfo = LIB.GetActivityQuest('WEEK_TEAM_DUNGEON'),
				}
			elseif id == 'week_raid_dungeon' then
				return {
					id = id,
					szTitle = _L.ACTIVITY_MAP_TYPE.WEEK_RAID_DUNGEON,
					eType = TASK_TYPE.WEEKLY,
					aQuestInfo = LIB.GetActivityQuest('WEEK_RAID_DUNGEON'),
				}
			elseif id == 'week_public_quest' then
				return {
					id = id,
					szTitle = _L.ACTIVITY_MAP_TYPE.WEEK_PUBLIC_QUEST,
					eType = TASK_TYPE.WEEKLY,
					aQuestInfo = LIB.GetActivityQuest('WEEK_PUBLIC_QUEST'),
				}
			end
		end,
	})
	for _, v in ipairs(aTask) do
		tTask[v.id] = v
	end
	TASK_HASH = tTask
end

local COLUMN_DICT = setmetatable({}, { __index = function(t, id)
	if not TASK_HASH then
		InitTaskList()
	end
	local task = TASK_HASH[id]
	if task then
		local col = { -- 秘境CD
			id = id,
			szTitle = task.szTitle,
			nMinWidth = TASK_MIN_WIDTH,
			nMaxWidth = TASK_MAX_WIDTH,
		}
		col.GetTitleFormatTip = function()
			local aTitleTipXml = {
				GetFormatText(task.szTitle .. '\n', 162, 255, 255, 255),
				GetFormatText(_L['Refresh type:'] .. TASK_TYPE_STRING[task.eType] .. '\n', 162, 255, 128, 0)
			}
			local function InsertTitleTipXml(aInfo)
				if IsCtrlKeyDown() then
					insert(aTitleTipXml, GetFormatText('(' .. aInfo[1] .. ')', 162, 255, 128, 0))
				end
				insert(aTitleTipXml, GetFormatText('[' .. Table_GetQuestStringInfo(aInfo[1]).szName .. ']\n', 162, 255, 255, 0))
			end
			if task.aQuestInfo then
				for _, aInfo in ipairs(task.aQuestInfo) do
					InsertTitleTipXml(aInfo)
				end
			end
			if task.tCampQuestInfo then
				for _, aCampQuestInfo in pairs(task.tCampQuestInfo) do
					for _, aInfo in ipairs(aCampQuestInfo) do
						InsertTitleTipXml(aInfo)
					end
				end
			end
			if task.tForceQuestInfo then
				for _, aForceQuestInfo in pairs(task.tForceQuestInfo) do
					for _, aInfo in ipairs(aForceQuestInfo) do
						InsertTitleTipXml(aInfo)
					end
				end
			end
			return concat(aTitleTipXml)
		end
		col.GetFormatText = function(rec)
			local tTaskState = {}
			local function CountTaskState(aQuestInfo)
				for _, aInfo in ipairs(aQuestInfo) do
					if rec.task_info[aInfo[1]] then
						tTaskState[rec.task_info[aInfo[1]]] = (tTaskState[rec.task_info[aInfo[1]]] or 0) + 1
					end
				end
			end
			if task.aQuestInfo then
				CountTaskState(task.aQuestInfo)
			end
			if task.tCampQuestInfo and task.tCampQuestInfo[rec.camp] then
				CountTaskState(task.tCampQuestInfo[rec.camp])
			end
			if task.tForceQuestInfo and task.tForceQuestInfo[rec.force] then
				CountTaskState(task.tForceQuestInfo[rec.force])
			end
			if task.aBuffInfo then
				for _, aInfo in ipairs(task.aBuffInfo) do
					local szKey = aInfo[1] .. '_' .. (aInfo[2] or 0)
					if rec.buff_info[szKey] then
						tTaskState[rec.buff_info[szKey]] = (tTaskState[rec.buff_info[szKey]] or 0) + 1
					end
				end
			end
			local szState, r, g, b
			if not IsInSamePeriod(rec.time, task.eType) then
				szState = _L['--']
			elseif tTaskState[TASK_STATE.FINISHABLE] then
				szState = _L['Finishable']
			elseif tTaskState[TASK_STATE.ACCEPTED] then
				szState = _L['Accepted']
			elseif tTaskState[TASK_STATE.ACCEPTABLE] then
				szState = _L['Acceptable']
			elseif tTaskState[TASK_STATE.FINISHED] then
				szState, r, g, b = _L['Finished'], 128, 255, 128
			elseif tTaskState[TASK_STATE.UNACCEPTABLE] then
				szState = _L['Unacceptable']
			elseif tTaskState[TASK_STATE.UNKNOWN] then
				szState = _L['--']
			else
				szState = _L['None']
			end
			return GetFormatText(szState, 162, r, g, b, 786, 'this.id="' .. id .. '"', 'Text_QuestState')
		end
		col.GetFormatTip = function(rec)
			local aXml = {}
			local function InsertTaskState(aInfo)
				if IsCtrlKeyDown() then
					insert(aXml, GetFormatText('(' .. aInfo[1] .. ')', 162, 255, 128, 0))
				end
				insert(aXml, GetFormatText('[' .. Table_GetQuestStringInfo(aInfo[1]).szName .. ']: ', 162, 255, 255, 0))
				if rec.task_info[aInfo[1]] == TASK_STATE.ACCEPTABLE then
					insert(aXml, GetFormatText(_L['Acceptable'] .. '\n', 162, 255, 255, 255))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.UNACCEPTABLE then
					insert(aXml, GetFormatText(_L['Unacceptable'] .. '\n', 162, 255, 255, 255))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.ACCEPTED then
					insert(aXml, GetFormatText(_L['Accepted'] .. '\n', 162, 255, 255, 255))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.FINISHED then
					insert(aXml, GetFormatText(_L['Finished'] .. '\n', 162, 255, 255, 255))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.FINISHABLE then
					insert(aXml, GetFormatText(_L['Finishable'] .. '\n', 162, 255, 255, 255))
				else
					insert(aXml, GetFormatText(_L['Unknown'] .. '\n', 162, 255, 255, 255))
				end
			end
			if task.aQuestInfo then
				for _, aInfo in ipairs(task.aQuestInfo) do
					InsertTaskState(aInfo)
				end
			end
			if task.tCampQuestInfo and task.tCampQuestInfo[rec.camp] then
				for _, aInfo in ipairs(task.tCampQuestInfo[rec.camp]) do
					InsertTaskState(aInfo)
				end
			end
			if task.tForceQuestInfo and task.tForceQuestInfo[rec.force] then
				for _, aInfo in ipairs(task.tForceQuestInfo[rec.force]) do
					InsertTaskState(aInfo)
				end
			end
			return concat(aXml)
		end
		col.Compare = function(r1, r2)
			local k1, k2 = 0, 0
			local tWeight = {
				[TASK_STATE.FINISHABLE] = 10000,
				[TASK_STATE.ACCEPTED] = 1000,
				[TASK_STATE.ACCEPTABLE] = 100,
				[TASK_STATE.UNACCEPTABLE] = 10,
				[TASK_STATE.FINISHED] = 1,
			}
			if task.aQuestInfo then
				for _, aInfo in ipairs(task.aQuestInfo) do
					k1 = k1 + (r1.task_info[aInfo[1]] and tWeight[r1.task_info[aInfo[1]]] or 0)
					k2 = k2 + (r2.task_info[aInfo[1]] and tWeight[r2.task_info[aInfo[1]]] or 0)
				end
			end
			if task.tCampQuestInfo and task.tCampQuestInfo[r1.camp] then
				for _, aInfo in ipairs(task.tCampQuestInfo[r1.camp]) do
					k1 = k1 + (r1.task_info[aInfo[1]] and tWeight[r1.task_info[aInfo[1]]] or 0)
				end
			end
			if task.tCampQuestInfo and task.tCampQuestInfo[r2.camp] then
				for _, aInfo in ipairs(task.tCampQuestInfo[r2.camp]) do
					k2 = k2 + (r2.task_info[aInfo[1]] and tWeight[r2.task_info[aInfo[1]]] or 0)
				end
			end
			if task.tForceQuestInfo and task.tForceQuestInfo[r1.force] then
				for _, aInfo in ipairs(task.tForceQuestInfo[r1.force]) do
					k1 = k1 + (r1.task_info[aInfo[1]] and tWeight[r1.task_info[aInfo[1]]] or 0)
				end
			end
			if task.tForceQuestInfo and task.tForceQuestInfo[r2.force] then
				for _, aInfo in ipairs(task.tForceQuestInfo[r2.force]) do
					k2 = k2 + (r2.task_info[aInfo[1]] and tWeight[r2.task_info[aInfo[1]]] or 0)
				end
			end
			if not IsInSamePeriod(r1.time, task.eType) then
				k1 = 0
			end
			if not IsInSamePeriod(r2.time, task.eType) then
				k2 = 0
			end
			if k1 == k2 then
				return 0
			end
			return k1 > k2 and 1 or -1
		end
		return col
	end
end })
for _, p in ipairs(COLUMN_LIST) do
	COLUMN_DICT[p.id] = p
end

local ACTIVITY_LIST = {
	'week_team_dungeon',
	'week_raid_dungeon',
	'week_public_quest',
}

local TIP_COLUMN = {
	'region',
	'server',
	'name',
	'force',
	'camp',
	'level',
	'TASK',
	'ACTIVITY',
	'time',
	'time_days',
}

do
local REC_CACHE
function D.GetClientPlayerRec()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rec = REC_CACHE
	local guid = me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName
	if not rec then
		rec = {}
		REC_CACHE = rec
	end
	InitTaskList()

	-- 基础信息
	rec.guid = guid
	rec.account = LIB.GetAccount() or ''
	rec.region = LIB.GetRealServer(1)
	rec.server = LIB.GetRealServer(2)
	rec.name = me.szName
	rec.force = me.dwForceID
	rec.camp = me.nCamp
	rec.level = me.nLevel
	rec.time = GetCurrentTime()
	rec.task_info = {}
	rec.buff_info = {}

	local aTask = {}
	-- 任务选项
	for _, task in ipairs(TASK_LIST) do
		insert(aTask, task)
	end
	-- 动态活动秘境选项
	for _, szType in ipairs(ACTIVITY_LIST) do
		insert(aTask, TASK_HASH[szType])
	end

	for _, task in ipairs(aTask) do
		if task.aQuestInfo then
			for _, aInfo in ipairs(task.aQuestInfo) do
				rec.task_info[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
			end
		end
		if task.tCampQuestInfo and task.tCampQuestInfo[me.nCamp] then
			for _, aInfo in ipairs(task.tCampQuestInfo[me.nCamp]) do
				rec.task_info[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
			end
		end
		if task.tForceQuestInfo and task.tForceQuestInfo[me.dwForceID] then
			for _, aInfo in ipairs(task.tForceQuestInfo[me.dwForceID]) do
				rec.task_info[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
			end
		end
		if task.aBuffInfo then
			for _, aInfo in ipairs(task.aBuffInfo) do
				local nState = me.GetBuff(aInfo[1], aInfo[2] or 0)
					and TASK_STATE.FINISHED
					or TASK_STATE.UNKNOWN
				if nState == TASK_STATE.FINISHED then
					rec.buff_info[aInfo[1] .. '_0'] = TASK_STATE.FINISHED
				end
				rec.buff_info[aInfo[1] .. '_' .. (aInfo[2] or 0)] = nState
			end
		end
	end
	return rec
end
end

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_TaskStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local rec = Clone(D.GetClientPlayerRec())
	D.EncodeRow(rec)

	DB:Execute('BEGIN TRANSACTION')
	DB_TaskInfoW:ClearBindings()
	DB_TaskInfoW:BindAll(
		rec.guid, rec.account, rec.region, rec.server,
		rec.name, rec.force, rec.camp, rec.level,
		rec.task_info, rec.buff_info, rec.time)
	DB_TaskInfoW:Execute()
	DB:Execute('END TRANSACTION')

	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_TaskStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_TaskStat', D.FlushDB)

do local INIT = false
function D.UpdateSaveDB()
	if not INIT then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_TaskStat', 'Remove from database...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB_TaskInfoD:ClearBindings()
		DB_TaskInfoD:BindAll(AnsiToUTF8(me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName))
		DB_TaskInfoD:Execute()
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_TaskStat', 'Remove from database finished...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_TASK_UPDATE')
end
LIB.RegisterInit('MY_RoleStatistics_TaskUpdateSaveDB', function() INIT = true end)
end

function D.GetColumns()
	local aCol = {}
	for _, id in ipairs(O.aColumn) do
		local col = COLUMN_DICT[id]
		if col then
			insert(aCol, col)
		end
	end
	return aCol
end

function D.UpdateUI(page)
	local hCols = page:Lookup('Wnd_Total/WndScroll_TaskStat', 'Handle_TaskStatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetColumns(), 0, nil
	local nExtraWidth = EXCEL_WIDTH
	for i, col in ipairs(aCol) do
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_TaskStatColumn')
		local txt = hCol:Lookup('Text_TaskStat_Title')
		local imgAsc = hCol:Lookup('Image_TaskStat_Asc')
		local imgDesc = hCol:Lookup('Image_TaskStat_Desc')
		local nWidth = i == #aCol
			and (EXCEL_WIDTH - nX)
			or min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or HUGE)
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_TaskStat_Break'):Hide()
		end
		hCol.col = col
		hCol:SetRelX(nX)
		hCol:SetW(nWidth)
		txt:SetW(nWidth)
		txt:SetText(col.szTitle)
		imgAsc:SetRelX(nWidth - nSortDelta)
		imgDesc:SetRelX(nWidth - nSortDelta)
		if O.szSort == col.id then
			Sorter = function(r1, r2)
				if O.szSortOrder == 'asc' then
					return col.Compare(r1, r2) < 0
				end
				return col.Compare(r1, r2) > 0
			end
		end
		imgAsc:SetVisible(O.szSort == col.id and O.szSortOrder == 'asc')
		imgDesc:SetVisible(O.szSort == col.id and O.szSortOrder == 'desc')
		hCol:FormatAllItemPos()
		nX = nX + nWidth
	end
	hCols:FormatAllItemPos()

	local szSearch = page:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):GetText()
	local szUSearch = AnsiToUTF8('%' .. szSearch .. '%')
	DB_TaskInfoR:ClearBindings()
	DB_TaskInfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = DB_TaskInfoR:GetAll()

	for _, rec in ipairs(result) do
		D.DecodeRow(rec)
	end

	if Sorter then
		sort(result, Sorter)
	end

	local aCol = D.GetColumns()
	local nExtraWidth = EXCEL_WIDTH
	for i, col in ipairs(aCol) do
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	local hList = page:Lookup('Wnd_Total/WndScroll_TaskStat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(result) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		hRow.rec = rec
		hRow:Lookup('Image_RowBg'):SetVisible(i % 2 == 1)
		local nX = 0
		for j, col in ipairs(aCol) do
			local hItem = hRow:AppendItemFromIni(SZ_INI, 'Handle_Item') -- 外部居中层
			local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
			hItemContent:AppendItemFromString(col.GetFormatText(rec))
			hItemContent:SetW(99999)
			hItemContent:FormatAllItemPos()
			hItemContent:SetSizeByAllItemSize()
			local nWidth = j == #aCol
				and (EXCEL_WIDTH - nX)
				or min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or HUGE)
			hItem:SetRelX(nX)
			hItem:SetW(nWidth)
			hItemContent:SetRelPos((nWidth - hItemContent:GetW()) / 2, (hItem:GetH() - hItemContent:GetH()) / 2)
			hItem:FormatAllItemPos()
			nX = nX + nWidth
		end
		hRow:FormatAllItemPos()
	end
	hList:FormatAllItemPos()
end

function D.EncodeRow(rec)
	rec.guid   = AnsiToUTF8(rec.guid)
	rec.name   = AnsiToUTF8(rec.name)
	rec.region = AnsiToUTF8(rec.region)
	rec.server = AnsiToUTF8(rec.server)
	rec.task_info = EncodeLUAData(rec.task_info)
	rec.buff_info = EncodeLUAData(rec.buff_info)
end

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
	rec.task_info = DecodeLUAData(rec.task_info or '') or {}
	rec.buff_info = DecodeLUAData(rec.buff_info or '') or {}
end

function D.OutputRowTip(this, rec)
	local aXml = {}
	local bFloat = this:GetRoot():GetName() ~= 'MY_RoleStatistics'
	local tActivity = LIB.FlipObjectKV(ACTIVITY_LIST)
	for _, id in ipairs(TIP_COLUMN) do
		if id == 'TASK' then
			for _, col in ipairs(D.GetColumns()) do
				if TASK_HASH[col.id] and not tActivity[col.id] then
					insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
					insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
					insert(aXml, col.GetFormatText(rec))
					insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
				end
			end
		elseif id == 'ACTIVITY' then
			for _, szType in ipairs(ACTIVITY_LIST) do
				local col = COLUMN_DICT[szType]
				if col and (not bFloat or not col.bHideInFloat) then
					insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
					insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
					insert(aXml, col.GetFormatText(rec))
					insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
				end
			end
		else
			local col = COLUMN_DICT[id]
			if col and (not bFloat or not col.bHideInFloat) then
				insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
				insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
				insert(aXml, col.GetFormatText(rec))
				insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
			end
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local nPosType = bFloat and UI.TIP_POSITION.TOP_BOTTOM or UI.TIP_POSITION.RIGHT_LEFT
	OutputTip(concat(aXml), 450, {x, y, w, h}, nPosType)
end

function D.CloseRowTip()
	HideTip()
end

function D.OnInitPage()
	local page = this
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_TaskStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(page, true, true)
	Wnd.CloseWindow(frameTemp)

	UI(wnd):Append('WndComboBox', {
		x = 800, y = 20, w = 180,
		text = _L['Columns'],
		menu = function()
			local t, aColumn, tChecked, nMinW = {}, O.aColumn, {}, 0
			-- 已添加的
			for i, id in ipairs(aColumn) do
				local col = COLUMN_DICT[id]
				if col then
					insert(t, {
						szOption = col.szTitle,
						{
							szOption = _L['Move up'],
							fnAction = function()
								if i > 1 then
									aColumn[i], aColumn[i - 1] = aColumn[i - 1], aColumn[i]
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Move down'],
							fnAction = function()
								if i < #aColumn then
									aColumn[i], aColumn[i + 1] = aColumn[i + 1], aColumn[i]
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								remove(aColumn, i)
								D.UpdateUI(page)
								UI.ClosePopupMenu()
							end,
						},
					})
					nMinW = nMinW + col.nMinWidth
				end
				tChecked[id] = true
			end
			-- 未添加的
			local function fnAction(id, nWidth)
				local bExist = false
				for i, v in ipairs(aColumn) do
					if v == id then
						remove(aColumn, i)
						bExist = true
						break
					end
				end
				if not bExist then
					if nMinW + nWidth > EXCEL_WIDTH then
						LIB.Alert(_L['Too many column selected, width overflow, please delete some!'])
					else
						insert(aColumn, id)
					end
				end
				D.FlushDB()
				D.UpdateUI(page)
				UI.ClosePopupMenu()
			end
			-- 普通选项
			for _, col in ipairs(COLUMN_LIST) do
				if not tChecked[col.id] then
					insert(t, {
						szOption = col.szTitle,
						fnAction = function()
							fnAction(col.id, col.nMinWidth)
						end,
					})
				end
			end
			-- 任务选项
			for _, task in ipairs(TASK_LIST) do
				if not tChecked[task.id] then
					local col = COLUMN_DICT[task.id]
					if col then
						insert(t, {
							szOption = col.szTitle,
							bCheck = true, bChecked = tChecked[col.id],
							fnAction = function()
								fnAction(col.id, col.nMinWidth)
							end,
						})
					end
					tChecked[task.id] = true
				end
			end
			-- 动态活动秘境选项
			for _, szType in ipairs(ACTIVITY_LIST) do
				if not tChecked[szType] then
					local col = COLUMN_DICT[szType]
					if col then
						insert(t, {
							szOption = col.szTitle,
							bCheck = true, bChecked = tChecked[col.id],
							fnAction = function()
								fnAction(col.id, col.nMinWidth)
							end,
						})
						tChecked[szType] = true
					end
				end
			end
			return t
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('QUEST_ACCEPTED')
	frame:RegisterEvent('QUEST_CANCELED')
	frame:RegisterEvent('QUEST_FINISHED')
	frame:RegisterEvent('DAILY_QUEST_UPDATE')
	frame:RegisterEvent('MY_ROLE_STAT_TASK_UPDATE')
end

function D.CheckAdvice()
	for _, p in ipairs({
		{
			szMsg = _L('%s stat has not been enabled, this character\'s data will not be saved, are you willing to save this character?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]),
			szAdviceKey = 'bAdviceSaveDB',
			szSetKey = 'bSaveDB',
		},
		-- {
		-- 	szMsg = _L('%s stat float entry has not been enabled, are you willing to enable it?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]),
		-- 	szAdviceKey = 'bAdviceFloatEntry',
		-- 	szSetKey = 'bFloatEntry',
		-- },
	}) do
		if not O[p.szAdviceKey] and not O[p.szSetKey] then
			LIB.Confirm(p.szMsg, function()
				MY_RoleStatistics_TaskStat[p.szSetKey] = true
				MY_RoleStatistics_TaskStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end, function()
				MY_RoleStatistics_TaskStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end)
			return
		end
	end
end

function D.OnActivePage()
	D.CheckAdvice()
	D.FlushDB()
	D.UpdateUI(this)
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateUI(this)
	elseif event == 'QUEST_ACCEPTED' or event == 'QUEST_CANCELED'
	or event == 'QUEST_FINISHED' or event == 'DAILY_QUEST_UPDATE' then
		D.FlushDB()
		D.UpdateUI(this)
	elseif event == 'MY_ROLE_STAT_TASK_UPDATE' then
		D.FlushDB()
		D.UpdateUI(this)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		LIB.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			DB_TaskInfoD:ClearBindings()
			DB_TaskInfoD:BindAll(AnsiToUTF8(wnd.guid))
			DB_TaskInfoD:Execute()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_TaskStatColumn' then
		if this.col.id then
			local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
			if O.szSort == this.col.id then
				O.szSortOrder = O.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				O.szSort = this.col.id
			end
			D.UpdateUI(page)
		end
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Row' then
		local rec = this.rec
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		local menu = {
			{
				szOption = _L['Delete'],
				fnAction = function()
					DB_TaskInfoD:ClearBindings()
					DB_TaskInfoD:BindAll(AnsiToUTF8(rec.guid))
					DB_TaskInfoD:Execute()
					D.UpdateUI(page)
				end,
			},
		}
		PopupMenu(menu)
	end
end

function D.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_Search' then
			local page = this:GetParent():GetParent():GetParent()
			D.UpdateUI(page)
		end
		return 1
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Row' then
		D.OutputRowTip(this, this.rec)
	elseif name == 'Handle_TaskStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = this.col.GetTitleFormatTip
			and this.col.GetTitleFormatTip()
			or GetFormatText(this:Lookup('Text_TaskStat_Title'):GetText(), 162, 255, 255, 255)
		OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	elseif name == 'Text_QuestState' then
		local id = this.id
		local rec = this:GetParent():GetParent():GetParent().rec
		local col = COLUMN_DICT[id]
		if col and col.GetFormatTip then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szXml = col.GetFormatTip(rec)
			if not IsEmpty(szXml) then
				OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
			end
		end
	elseif this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	HideTip()
end

-- 浮动框
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/SprintPower')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_TaskEntry')
	if bFloatEntry then
		if btn then
			return
		end
		local frameTemp = Wnd.OpenWindow(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_TaskEntry.ini', 'MY_RoleStatistics_TaskEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_TaskEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(72, 37)
		Wnd.CloseWindow(frameTemp)
		btn.OnMouseEnter = function()
			local rec = D.GetClientPlayerRec()
			if not rec then
				return
			end
			D.OutputRowTip(this, rec)
		end
		btn.OnMouseLeave = function()
			D.CloseRowTip()
		end
		btn.OnLButtonClick = function()
			MY_RoleStatistics.Open('TaskStat')
		end
	else
		if not btn then
			return
		end
		btn:Destroy()
	end
end
function D.UpdateFloatEntry()
	D.ApplyFloatEntry(O.bFloatEntry)
end
LIB.RegisterInit('MY_RoleStatistics_TaskEntry', D.UpdateFloatEntry)
LIB.RegisterReload('MY_RoleStatistics_TaskEntry', function() D.ApplyFloatEntry(false) end)
LIB.RegisterFrameCreate('SprintPower.MY_RoleStatistics_TaskEntry', D.UpdateFloatEntry)

-- Module exports
do
local settings = {
	exports = {
		{
			fields = {
				OnInitPage = D.OnInitPage,
				szFloatEntry = 'MY_RoleStatistics_TaskStat.bFloatEntry',
				szSaveDB = 'MY_RoleStatistics_TaskStat.bSaveDB',
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_RoleStatistics.RegisterModule('TaskStat', _L['MY_RoleStatistics_TaskStat'], LIB.GeneGlobalNS(settings))
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				aColumn = true,
				szSort = true,
				szSortOrder = true,
				bFloatEntry = true,
				bSaveDB = true,
				bAdviceSaveDB = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				aColumn = true,
				szSort = true,
				szSortOrder = true,
				bFloatEntry = true,
				bSaveDB = true,
				bAdviceSaveDB = true,
			},
			triggers = {
				bFloatEntry = D.UpdateFloatEntry,
				bSaveDB = D.UpdateSaveDB,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_TaskStat = LIB.GeneGlobalNS(settings)
end
