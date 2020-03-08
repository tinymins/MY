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
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
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

local DB = LIB.ConnectDatabase(_L['MY_RoleStatistics_TaskStat'], {'userdata/role_statistics/task_stat.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_TaskStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_TaskStat.ini'

DB:Execute('CREATE TABLE IF NOT EXISTS Task (guid NVARCHAR(20), name NVARCHAR(255), tasksid NVARCHAR(2550), PRIMARY KEY(guid))')
local DB_TaskW = DB:Prepare('REPLACE INTO Task (guid, name, tasksid) VALUES (?, ?, ?)')
local DB_TaskR = DB:Prepare('SELECT * FROM Task')
local DB_TaskD = DB:Prepare('DELETE FROM TaskInfo WHERE guid = ?')
DB:Execute('CREATE TABLE IF NOT EXISTS TaskInfo (guid NVARCHAR(20), account NVARCHAR(255), region NVARCHAR(20), server NVARCHAR(20), name NVARCHAR(20), force INTEGER, camp INTEGER, level INTEGER, task_info NVARCHAR(65535), time INTEGER, PRIMARY KEY(guid))')
local DB_TaskInfoW = DB:Prepare('REPLACE INTO TaskInfo (guid, account, region, server, name, force, camp, level, task_info, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_TaskInfoR = DB:Prepare('SELECT * FROM TaskInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_TaskInfoD = DB:Prepare('DELETE FROM TaskInfo WHERE guid = ?')

local D = {}
local O = {
	aColumn = {
		'name',
		'force',
		'big_war', -- 大战
		'teahouse', -- 茶馆
		'public_routine', -- 公共日常
		'stronghold_trade', -- 据点贸易
		'camp_routine', -- 阵营日常
		'dragon_gate_despair', -- 龙门绝境
		'lexus_reality', -- 列星虚境
		'lidu_ghost_town', -- 李渡鬼城
		'force_routine', -- 勤修不辍
		'picking_fairy_grass', -- 采仙草
		'find_dragon_veins', -- 寻龙脉
		'illustration_routine', -- 美人图
		'time_days',
	},
	szSort = 'time_days',
	szSortOrder = 'desc',
}
RegisterCustomData('Global/MY_RoleStatistics_TaskStat.aColumn')
RegisterCustomData('Global/MY_RoleStatistics_TaskStat.szSort')
RegisterCustomData('Global/MY_RoleStatistics_TaskStat.szSortOrder')

local TASK_STATE = {
	ACCEPTABLE = 1,
	ACCEPTED = 2,
	FINISHABLE = 3,
	FINISHED = 4,
	UNACCEPTABLE = 5,
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
	if eCanAccept == QUEST_RESULT.FAILED then
		return TASK_STATE.UNACCEPTABLE
	end
	if eCanAccept == QUEST_RESULT.FINISHED_MAX_COUNT then
		return TASK_STATE.FINISHED
	end
end

local EXCEL_WIDTH = 960
local TASK_WIDTH = 65
local function GeneCommonFormatText(id)
	return function(r)
		return GetFormatText(r[id])
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
		szTitle = _L['Region'],
		nWidth = 100,
		GetFormatText = GeneCommonFormatText('region'),
		Compare = GeneCommonCompare('region'),
	},
	{ -- 服务器
		id = 'server',
		szTitle = _L['Server'],
		nWidth = 100,
		GetFormatText = GeneCommonFormatText('server'),
		Compare = GeneCommonCompare('server'),
	},
	{ -- 名字
		id = 'name',
		szTitle = _L['Name'],
		nWidth = 130,
		GetFormatText = function(rec)
			local name = rec.name
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name)
		end,
		Compare = GeneCommonCompare('name'),
	},
	{ -- 门派
		id = 'force',
		szTitle = _L['Force'],
		nWidth = 50,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.tForceTitle[rec.force])
		end,
		Compare = GeneCommonCompare('force'),
	},
	{ -- 阵营
		id = 'camp',
		szTitle = _L['Camp'],
		nWidth = 50,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.STR_CAMP_TITLE[rec.camp])
		end,
		Compare = GeneCommonCompare('camp'),
	},
	{ -- 等级
		id = 'level',
		szTitle = _L['Level'],
		nWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- 时间
		id = 'time',
		szTitle = _L['Cache time'],
		nWidth = 165,
		GetFormatText = function(rec)
			return GetFormatText(LIB.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'))
		end,
		Compare = GeneCommonCompare('time'),
	},
	{ -- 时间计时
		id = 'time_days',
		szTitle = _L['Cache time days'],
		nWidth = 120,
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
				return GetFormatText(_L('%d years %d days before', nYears, nDay))
			end
			if nDays > 0 then
				return GetFormatText(_L('%d days %d hours before', nDays, nHour))
			end
			if nHours > 0 then
				return GetFormatText(_L('%d hours %d mins before', nHours, nMinute))
			end
			if nMinutes > 0 then
				return GetFormatText(_L('%d mins %d secs before', nMinutes, nSecond))
			end
			if nSecond > 10 then
				return GetFormatText(_L('%d secs before', nSecond))
			end
			return GetFormatText(_L['Just now'])
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
		aQuestInfo = CONSTANT.QUEST_INFO.BIG_WARS,
	})
	-- 茶馆
	insert(aTask, {
		id = 'teahouse',
		szTitle = _L['Teahouse'],
		aQuestInfo = CONSTANT.QUEST_INFO.TEAHOUSE_ROUTINE,
	})
	-- 勤修不辍
	insert(aTask, {
		id = 'force_routine',
		szTitle = _L['Force routine'],
		tForceQuestInfo = CONSTANT.QUEST_INFO.FORCE_ROUTINE,
	})
	-- 公共日常
	insert(aTask, {
		id = 'public_routine',
		szTitle = _L['Public routine'],
		aQuestInfo = CONSTANT.QUEST_INFO.PUBLIC_ROUTINE,
	})
	-- 阵营日常
	insert(aTask, {
		id = 'camp_routine',
		szTitle = _L['Camp routine'],
		tCampQuestInfo = CONSTANT.QUEST_INFO.CAMP_ROUTINE,
	})
	-- 据点贸易
	insert(aTask, {
		id = 'stronghold_trade',
		szTitle = _L['Stronghold trade'],
		tCampQuestInfo = CONSTANT.QUEST_INFO.CAMP_STRONGHOLD_TRADE,
	})
	-- 晶矿争夺
	insert(aTask, {
		id = 'crystal_scramble',
		szTitle = _L['Crystal scramble'],
		tCampQuestInfo = CONSTANT.QUEST_INFO.CAMP_CRYSTAL_SCRAMBLE,
	})
	-- 'dragon_gate_despair', -- 龙门绝境
	-- 'lexus_reality', -- 列星虚境
	-- 'lidu_ghost_town', -- 李渡鬼城
	-- 采仙草
	insert(aTask, {
		id = 'picking_fairy_grass',
		szTitle = _L['Picking fairy grass'],
		aQuestInfo = CONSTANT.QUEST_INFO.PICKING_FAIRY_GRASS,
	})
	-- 寻龙脉
	insert(aTask, {
		id = 'find_dragon_veins',
		szTitle = _L['Find dragon veins'],
		aQuestInfo = CONSTANT.QUEST_INFO.FIND_DRAGON_VEINS,
	})
	-- 美人图
	insert(aTask, {
		id = 'illustration_routine',
		szTitle = _L['Illustration routine'],
		aQuestInfo = CONSTANT.QUEST_INFO.ILLUSTRATION_ROUTINE,
	})
	-- 用户自定义数据
	DB_TaskR:ClearBindings()
	DB_TaskR:BindAll()
	for _, v in ipairs(DB_TaskR:GetAll()) do
		insert(aTask, {
			id = v.guid,
			szTitle = v.name,
			aQuestInfo = DecodeLUAData(v.tasksid) or {},
		})
	end
	TASK_LIST = aTask
	-- 高速id键索引
	local tTask = {}
	for _, v in ipairs(aTask) do
		tTask[v.id] = v
	end
	TASK_HASH = tTask
end

local COLUMN_DICT = setmetatable({}, { __index = function(t, id)
	local task = TASK_HASH[id]
	if task then
		local col = { -- 副本CD
			id = id,
			szTitle = task.szTitle,
			nWidth = TASK_WIDTH,
		}
		col.GetTitleFormatTip = function()
			local aTitleTipXml = {GetFormatText(task.szTitle .. '\n')}
			local function InsertTitleTipXml(aInfo)
				if IsCtrlKeyDown() then
					insert(aTitleTipXml, GetFormatText('(' .. aInfo[1] .. ')', nil, 255, 128, 0))
				end
				insert(aTitleTipXml, GetFormatText('[' .. Table_GetQuestStringInfo(aInfo[1]).szName .. ']\n', nil, 255, 255, 0))
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
			local szState, r, g, b
			if tTaskState[TASK_STATE.FINISHABLE] then
				szState = _L['Finishable']
			elseif tTaskState[TASK_STATE.ACCEPTED] then
				szState = _L['Accepted']
			elseif tTaskState[TASK_STATE.ACCEPTABLE] then
				szState = _L['Acceptable']
			elseif tTaskState[TASK_STATE.FINISHED] then
				szState = _L['Finished']
			elseif tTaskState[TASK_STATE.UNACCEPTABLE] then
				szState = _L['Unacceptable']
			else
				szState = _L['None']
			end
			return GetFormatText(szState or _L['Unknown'], nil, r, g, b, 786, 'this.id="' .. id .. '"', 'Text_QuestState')
		end
		col.GetFormatTip = function(rec)
			local aXml = {}
			local function InsertTaskState(aInfo)
				if IsCtrlKeyDown() then
					insert(aXml, GetFormatText('(' .. aInfo[1] .. ')', nil, 255, 128, 0))
				end
				insert(aXml, GetFormatText('[' .. Table_GetQuestStringInfo(aInfo[1]).szName .. ']: ', nil, 255, 255, 0))
				if rec.task_info[aInfo[1]] == TASK_STATE.ACCEPTABLE then
					insert(aXml, GetFormatText(_L['Acceptable'] .. '\n'))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.UNACCEPTABLE then
					insert(aXml, GetFormatText(_L['Unacceptable'] .. '\n'))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.ACCEPTED then
					insert(aXml, GetFormatText(_L['Accepted'] .. '\n'))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.FINISHED then
					insert(aXml, GetFormatText(_L['Finished'] .. '\n'))
				elseif rec.task_info[aInfo[1]] == TASK_STATE.FINISHABLE then
					insert(aXml, GetFormatText(_L['Finishable'] .. '\n'))
				else
					insert(aXml, GetFormatText(_L['Unknown'] .. '\n'))
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
local TIP_COLIMN = {
	'region',
	'server',
	'name',
	'force',
	'camp',
	'level',
	'TASK',
	'time',
	'time_days',
}

function D.FlushDB()
	InitTaskList()
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_TaskStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local me = GetClientPlayer()
	local guid = AnsiToUTF8(me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName)
	local account = LIB.GetAccount() or ''
	local region = AnsiToUTF8(LIB.GetRealServer(1))
	local server = AnsiToUTF8(LIB.GetRealServer(2))
	local name = AnsiToUTF8(me.szName)
	local force = me.dwForceID
	local camp = me.nCamp
	local level = me.nLevel
	local time = GetCurrentTime()
	local tTaskState = {}
	for _, id in ipairs(O.aColumn) do
		local task = TASK_HASH[id]
		if task then
			if task.aQuestInfo then
				for _, aInfo in ipairs(task.aQuestInfo) do
					tTaskState[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
				end
			end
			if task.tCampQuestInfo and task.tCampQuestInfo[me.nCamp] then
				for _, aInfo in ipairs(task.tCampQuestInfo[me.nCamp]) do
					tTaskState[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
				end
			end
			if task.tForceQuestInfo and task.tForceQuestInfo[me.dwForceID] then
				for _, aInfo in ipairs(task.tForceQuestInfo[me.dwForceID]) do
					tTaskState[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
				end
			end
		end
	end
	local task_info = EncodeLUAData(tTaskState)

	DB:Execute('BEGIN TRANSACTION')

	DB_TaskInfoW:ClearBindings()
	DB_TaskInfoW:BindAll(guid, account, region, server, name, force, camp, level, task_info, time)
	DB_TaskInfoW:Execute()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_TaskStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_TaskStat', D.FlushDB)

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
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_TaskStatColumn')
		local txt = hCol:Lookup('Text_TaskStat_Title')
		local imgAsc = hCol:Lookup('Image_TaskStat_Asc')
		local imgDesc = hCol:Lookup('Image_TaskStat_Desc')
		local nWidth = i == #aCol and (EXCEL_WIDTH - nX) or col.nWidth
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

	for _, p in ipairs(result) do
		p.task_info = DecodeLUAData(p.task_info or '') or {}
	end

	if Sorter then
		sort(result, Sorter)
	end

	local aCol = D.GetColumns()
	local hList = page:Lookup('Wnd_Total/WndScroll_TaskStat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(result) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		rec.guid   = UTF8ToAnsi(rec.guid)
		rec.name   = UTF8ToAnsi(rec.name)
		rec.region = UTF8ToAnsi(rec.region)
		rec.server = UTF8ToAnsi(rec.server)
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
			local nWidth = col.nWidth
			if j == #aCol then
				nWidth = EXCEL_WIDTH - nX
			end
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
			local t, aColumn, tChecked, nW = {}, O.aColumn, {}, 0
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
					nW = nW + col.nWidth
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
					if nW + nWidth > EXCEL_WIDTH then
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
							fnAction(col.id, col.nWidth)
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
								fnAction(col.id, col.nWidth)
							end,
						})
					end
					tChecked[task.id] = true
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
end

function D.OnActivePage()
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
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		LIB.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			DB_TaskInfoD:ClearBindings()
			DB_TaskInfoD:BindAll(wnd.guid)
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
					DB_TaskInfoD:BindAll(rec.guid)
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
		local aXml = {}
		for _, id in ipairs(TIP_COLIMN) do
			if id == 'TASK' then
				for _, col in ipairs(D.GetColumns()) do
					if TASK_HASH[col.id] then
						insert(aXml, GetFormatText(col.szTitle))
						insert(aXml, GetFormatText(':  '))
						insert(aXml, col.GetFormatText(this.rec))
						insert(aXml, GetFormatText('\n'))
					end
				end
			else
				local col = COLUMN_DICT[id]
				insert(aXml, GetFormatText(col.szTitle))
				insert(aXml, GetFormatText(':  '))
				insert(aXml, col.GetFormatText(this.rec))
				insert(aXml, GetFormatText('\n'))
			end
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.RIGHT_LEFT)
	elseif name == 'Handle_TaskStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = this.col.GetTitleFormatTip
			and this.col.GetTitleFormatTip()
			or GetFormatText(this:Lookup('Text_TaskStat_Title'):GetText())
		OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	elseif name == 'Text_QuestState' then
		local id = this.id
		local rec = this:GetParent():GetParent():GetParent().rec
		local col = COLUMN_DICT[id]
		if col and col.GetFormatTip then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local szXml = col.GetFormatTip(rec)
			OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
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

-- Module exports
do
local settings = {
	exports = {
		{
			fields = {
				OnInitPage = D.OnInitPage,
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
			},
			root = O,
		},
	},
}
MY_RoleStatistics_TaskStat = LIB.GeneGlobalNS(settings)
end
