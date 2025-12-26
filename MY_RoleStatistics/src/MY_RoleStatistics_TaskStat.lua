--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 任务统计（日常统计）
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RoleStatistics/MY_RoleStatistics_TaskStat'
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_TaskStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_RoleStatistics_TaskStat', _L['General'], {
	aColumn = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_TaskStat'],
			_L['Columns'],
		}),
		xSchema = X.Schema.Collection(X.Schema.String),
		xDefaultValue = {
			'name',
			'force',
			'big_war', -- 大战
			'teahouse', -- 茶馆
			'crystal_scramble', -- 晶矿争夺
			'stronghold_trade', -- 据点贸易
			'dragon_gate_despair', -- 龙门绝境
			'lexus_reality', -- 列星虚境
			'lidu_ghost_town', -- 李渡鬼域
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
	},
	szSort = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_TaskStat'],
			_L['Sort'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'time_days',
	},
	szSortOrder = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_TaskStat'],
			_L['Sort Order'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'desc',
	},
	bFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_TaskStat'],
			_L['Float panel'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_TaskStat'],
			_L['Save DB'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

local STAT_DATA_FILE = {'userdata/role_statistics/task_stat.jx3dat', X.PATH_TYPE.GLOBAL}
local PLAYER_REC_FILE = {'userdata/role_statistics/task_stat.jx3dat', X.PATH_TYPE.ROLE}
local PLAYER_REC_INITIAL, PLAYER_REC = nil, nil

local TASK_TYPE = {
	DAILY = 1,
	WEEKLY = 2,
	HALF_WEEKLY = 3,
	ONCE = 4,
}
local TASK_TYPE_STRING = {
	[TASK_TYPE.DAILY] = _L['Daily'],
	[TASK_TYPE.WEEKLY] = _L['Weekly'],
	[TASK_TYPE.HALF_WEEKLY] = _L['Half-weekly'],
	[TASK_TYPE.ONCE] = _L['Once'],
}
local function IsInSamePeriod(dwTime, eType)
	if eType == TASK_TYPE.ONCE then
		return true
	end
	local nNextTime, nCircle
	if eType == TASK_TYPE.DAILY then
		nNextTime, nCircle = X.GetRefreshTime('daily')
	elseif eType == TASK_TYPE.WEEKLY then
		nNextTime, nCircle = X.GetRefreshTime('weekly')
	elseif eType == TASK_TYPE.HALF_WEEKLY then
		nNextTime, nCircle = X.GetRefreshTime('half-weekly')
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

local TASK_MIN_WIDTH = 50
local TASK_MAX_WIDTH = 150

-------------------------------------------------------------------------------------------------------

local function GetFormatSysmsgText(szText)
	return GetFormatText(szText, GetMsgFont('MSG_SYS'), GetMsgFontColor('MSG_SYS'))
end

local DATA_ENV = setmetatable(
	{
		_L                         = _L                          ,
		math                       = math                        ,
		pairs                      = pairs                       ,
		ipairs                     = ipairs                      ,
		tonumber                   = tonumber                    ,
		wstring                    = X.wstring                   ,
		count_c                    = X.count_c                   ,
		pairs_c                    = X.pairs_c                   ,
		ipairs_c                   = X.ipairs_c                  ,
		ipairs_r                   = X.ipairs_r                  ,
		spairs                     = X.spairs                    ,
		spairs_r                   = X.spairs_r                  ,
		sipairs                    = X.sipairs                   ,
		sipairs_r                  = X.sipairs_r                 ,
		IsArray                    = X.IsArray                   ,
		IsDictionary               = X.IsDictionary              ,
		IsEquals                   = X.IsEquals                  ,
		IsNil                      = X.IsNil                     ,
		IsBoolean                  = X.IsBoolean                 ,
		IsNumber                   = X.IsNumber                  ,
		IsUserdata                 = X.IsUserdata                ,
		IsHugeNumber               = X.IsHugeNumber              ,
		IsElement                  = X.IsElement                 ,
		IsEmpty                    = X.IsEmpty                   ,
		IsString                   = X.IsString                  ,
		IsTable                    = X.IsTable                   ,
		IsFunction                 = X.IsFunction                ,
		IsInMonsterMap             = X.IsInMonsterMap            ,
		GetBuff                    = X.GetBuff                   ,
		GetAccount                 = X.GetAccount                ,
		GetServerOriginName        = X.GetServerOriginName       ,
		GetItemAmountInAllPackages = function(...)
			return X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.PACKAGE, ...)
				+ X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.BANK, ...)
		end,
		RegisterEvent              = X.RegisterEvent             ,
		RegisterFrameCreate        = X.RegisterFrameCreate       ,
		ITEM_TABLE_TYPE            = ITEM_TABLE_TYPE             ,
		FORCE_TYPE                 = X.CONSTANT.FORCE_TYPE       ,
		CAMP                       = CAMP                        ,
		TASK_TYPE                  = TASK_TYPE                   ,
		GetActivityQuest           = X.GetActivityQuest          ,
		GetFormatSysmsgText        = GetFormatSysmsgText         ,
		GetFormatText              = GetFormatText               ,
		GetMoneyText               = GetMoneyText                ,
		GetMsgFont                 = GetMsgFont                  ,
		GetMsgFontColor            = GetMsgFontColor             ,
		MoneyOptAdd                = MoneyOptAdd                 ,
		MoneyOptCmp                = MoneyOptCmp                 ,
		MoneyOptSub                = MoneyOptSub                 ,
		Output                     = Output                      ,
	},
	{
		__index = function(t, k)
			if k == 'me' then
				return X.GetClientPlayer()
			end
			if k:find('^arg%d+$') then
				return _G[k]
			end
		end,
	})

-------------------------------------------------------------------------------------------------------

local COLUMN_LIST = {
	-- guid
	{
		szKey = 'guid',
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayerGlobalID()
		end,
	},
	-- account
	{
		szKey = 'account',
		GetValue = function(prevVal, prevRec)
			return X.GetAccount() or ''
		end,
	},
	-- 大区
	{
		szKey = 'region',
		szTitle = _L['Region'],
		bTable = true,
		bRowTip = true,
		nMinWidth = 100,
		nMaxWidth = 100,
		GetValue = function(prevVal, prevRec)
			return X.GetRegionOriginName()
		end,
	},
	-- 服务器
	{
		szKey = 'server',
		szTitle = _L['Server'],
		bTable = true,
		bRowTip = true,
		nMinWidth = 100,
		nMaxWidth = 100,
		GetValue = function(prevVal, prevRec)
			return X.GetServerOriginName()
		end,
	},
	-- 名字
	{
		szKey = 'name',
		szTitle = _L['Name'],
		bTable = true,
		bRowTip = true,
		nMinWidth = 110,
		nMaxWidth = 200,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().szName
		end,
		GetFormatText = function(name, rec)
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name, 162, X.GetForceColor(rec.force, 'foreground'))
		end,
	},
	-- 门派
	{
		szKey = 'force',
		szTitle = _L['Force'],
		bTable = true,
		bRowTip = true,
		nMinWidth = 50,
		nMaxWidth = 70,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().dwForceID
		end,
		GetFormatText = function(force, rec)
			return GetFormatText(g_tStrings.tForceTitle[force], 162, 255, 255, 255)
		end,
	},
	-- 阵营
	{
		szKey = 'camp',
		szTitle = _L['Camp'],
		bTable = true,
		bRowTip = true,
		nMinWidth = 50,
		nMaxWidth = 50,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().nCamp
		end,
		GetFormatText = function(camp, rec)
			return GetFormatText(g_tStrings.STR_CAMP_TITLE[camp], 162, 255, 255, 255)
		end,
	},
	-- 等级
	{
		szKey = 'level',
		szTitle = _L['Level'],
		bTable = true,
		bRowTip = true,
		nMinWidth = 50,
		nMaxWidth = 50,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().nLevel
		end,
	},
}
-- 分版本列配置
do
	local f = X.LoadLUAData(PLUGIN_ROOT .. '/data/task/{$edition}.jx3dat')
	if X.IsFunction(f) then
		local t = f(DATA_ENV)
		if X.IsTable(t) then
			for _, col in ipairs(t) do
				if not col.nMinWidth then
					col.nMinWidth = TASK_MIN_WIDTH
				end
				if not col.nMaxWidth then
					col.nMaxWidth = TASK_MAX_WIDTH
				end
				if not col.GetTitleFormatTip then
					col.GetTitleFormatTip = function()
						local aTitleTipXml = {
							GetFormatText(col.szTitle .. '\n', 162, 255, 255, 255),
							GetFormatText(_L['Refresh type:'] .. TASK_TYPE_STRING[col.eType] .. '\n', 162, 255, 128, 0)
						}
						local function InsertTitleTipXml(aInfo)
							local info = Table_GetQuestStringInfo(aInfo[1])
							if info then
								if IsCtrlKeyDown() then
									table.insert(aTitleTipXml, GetFormatText('(' .. aInfo[1] .. ')', 162, 255, 128, 0))
								end
								table.insert(aTitleTipXml, GetFormatText('[' .. info.szName .. ']\n', 162, 255, 255, 0))
							end
						end
						local aQuestInfo = col.aQuestInfo or (col.GetQuestInfo and col.GetQuestInfo())
						if aQuestInfo then
							for _, aInfo in ipairs(aQuestInfo) do
								InsertTitleTipXml(aInfo)
							end
						end
						local tCampQuestInfo = col.tCampQuestInfo or (col.GetCampQuestInfo and col.GetCampQuestInfo())
						if tCampQuestInfo then
							for _, aCampQuestInfo in pairs(tCampQuestInfo) do
								for _, aInfo in ipairs(aCampQuestInfo) do
									InsertTitleTipXml(aInfo)
								end
							end
						end
						local tForceQuestInfo = col.tForceQuestInfo or (col.GetForceQuestInfo and col.GetForceQuestInfo())
						if tForceQuestInfo then
							for _, aForceQuestInfo in pairs(tForceQuestInfo) do
								for _, aInfo in ipairs(aForceQuestInfo) do
									InsertTitleTipXml(aInfo)
								end
							end
						end
						return table.concat(aTitleTipXml)
					end
				end
				if not col.GetFormatText then
					col.GetFormatText = function(val, rec)
						local tTaskState = {}
						local function CountTaskState(aQuestInfo)
							for _, aInfo in ipairs(aQuestInfo) do
								if rec.tTaskInfo[aInfo[1]] then
									tTaskState[rec.tTaskInfo[aInfo[1]]] = (tTaskState[rec.tTaskInfo[aInfo[1]]] or 0) + 1
								end
							end
						end
						local aQuestInfo = col.aQuestInfo or (col.GetQuestInfo and col.GetQuestInfo())
						if aQuestInfo then
							CountTaskState(aQuestInfo)
						end
						local tCampQuestInfo = col.tCampQuestInfo or (col.GetCampQuestInfo and col.GetCampQuestInfo())
						if tCampQuestInfo and tCampQuestInfo[rec.camp] then
							CountTaskState(tCampQuestInfo[rec.camp])
						end
						local tForceQuestInfo = col.tForceQuestInfo or (col.GetForceQuestInfo and col.GetForceQuestInfo())
						if tForceQuestInfo and tForceQuestInfo[rec.force] then
							CountTaskState(tForceQuestInfo[rec.force])
						end
						local aBuffInfo = col.aBuffInfo or (col.GetBuffInfo and col.GetBuffInfo())
						if aBuffInfo then
							for _, aInfo in ipairs(aBuffInfo) do
								local szKey = aInfo[1] .. '_' .. (aInfo[2] or 0)
								if rec.tBuffInfo[szKey] then
									tTaskState[rec.tBuffInfo[szKey]] = (tTaskState[rec.tBuffInfo[szKey]] or 0) + 1
								end
							end
						end
						-- local tCampBuffInfo = col.aCampBuffInfo or (col.GetCampBuffInfo and col.GetCampBuffInfo())
						-- local tForceBuffInfo = col.aForceBuffInfo or (col.GetForceBuffInfo and col.GetForceBuffInfo())
						local szState, r, g, b
						if not IsInSamePeriod(rec.time, col.eType) then
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
						return GetFormatText(szState, 162, r, g, b)
					end
				end
				if not col.GetFormatTip then
					col.GetFormatTip = function(val, rec)
						local aXml = {}
						local function InsertTaskState(aInfo)
							if IsCtrlKeyDown() then
								table.insert(aXml, GetFormatText('(' .. aInfo[1] .. ')', 162, 255, 128, 0))
							end
							table.insert(aXml, GetFormatText('[' .. X.Get(Table_GetQuestStringInfo(aInfo[1]), 'szName', '') .. ']: ', 162, 255, 255, 0))
							if rec.tTaskInfo[aInfo[1]] == TASK_STATE.ACCEPTABLE then
								table.insert(aXml, GetFormatText(_L['Acceptable'] .. '\n', 162, 255, 255, 255))
							elseif rec.tTaskInfo[aInfo[1]] == TASK_STATE.UNACCEPTABLE then
								table.insert(aXml, GetFormatText(_L['Unacceptable'] .. '\n', 162, 255, 255, 255))
							elseif rec.tTaskInfo[aInfo[1]] == TASK_STATE.ACCEPTED then
								table.insert(aXml, GetFormatText(_L['Accepted'] .. '\n', 162, 255, 255, 255))
							elseif rec.tTaskInfo[aInfo[1]] == TASK_STATE.FINISHED then
								table.insert(aXml, GetFormatText(_L['Finished'] .. '\n', 162, 255, 255, 255))
							elseif rec.tTaskInfo[aInfo[1]] == TASK_STATE.FINISHABLE then
								table.insert(aXml, GetFormatText(_L['Finishable'] .. '\n', 162, 255, 255, 255))
							else
								table.insert(aXml, GetFormatText(_L['Unknown'] .. '\n', 162, 255, 255, 255))
							end
						end
						local aQuestInfo = col.aQuestInfo or (col.GetQuestInfo and col.GetQuestInfo())
						if aQuestInfo then
							for _, aInfo in ipairs(aQuestInfo) do
								InsertTaskState(aInfo)
							end
						end
						local tCampQuestInfo = col.tCampQuestInfo or (col.GetCampQuestInfo and col.GetCampQuestInfo())
						if tCampQuestInfo and tCampQuestInfo[rec.camp] then
							for _, aInfo in ipairs(tCampQuestInfo[rec.camp]) do
								InsertTaskState(aInfo)
							end
						end
						local tForceQuestInfo = col.tForceQuestInfo or (col.GetForceQuestInfo and col.GetForceQuestInfo())
						if tForceQuestInfo and tForceQuestInfo[rec.force] then
							for _, aInfo in ipairs(tForceQuestInfo[rec.force]) do
								InsertTaskState(aInfo)
							end
						end
						return table.concat(aXml)
					end
				end
				if not col.Compare then
					col.Compare = function(v1, v2, r1, r2)
						local k1, k2 = 0, 0
						local tWeight = {
							[TASK_STATE.FINISHABLE] = 10000,
							[TASK_STATE.ACCEPTED] = 1000,
							[TASK_STATE.ACCEPTABLE] = 100,
							[TASK_STATE.UNACCEPTABLE] = 10,
							[TASK_STATE.FINISHED] = 1,
						}
						local aQuestInfo = col.aQuestInfo or (col.GetQuestInfo and col.GetQuestInfo())
						if aQuestInfo then
							for _, aInfo in ipairs(aQuestInfo) do
								k1 = k1 + (r1.tTaskInfo[aInfo[1]] and tWeight[r1.tTaskInfo[aInfo[1]]] or 0)
								k2 = k2 + (r2.tTaskInfo[aInfo[1]] and tWeight[r2.tTaskInfo[aInfo[1]]] or 0)
							end
						end
						local tCampQuestInfo = col.tCampQuestInfo or (col.GetCampQuestInfo and col.GetCampQuestInfo())
						if tCampQuestInfo and tCampQuestInfo[r1.camp] then
							for _, aInfo in ipairs(tCampQuestInfo[r1.camp]) do
								k1 = k1 + (r1.tTaskInfo[aInfo[1]] and tWeight[r1.tTaskInfo[aInfo[1]]] or 0)
							end
						end
						if tCampQuestInfo and tCampQuestInfo[r2.camp] then
							for _, aInfo in ipairs(tCampQuestInfo[r2.camp]) do
								k2 = k2 + (r2.tTaskInfo[aInfo[1]] and tWeight[r2.tTaskInfo[aInfo[1]]] or 0)
							end
						end
						local tForceQuestInfo = col.tForceQuestInfo or (col.GetForceQuestInfo and col.GetForceQuestInfo())
						if tForceQuestInfo and tForceQuestInfo[r1.force] then
							for _, aInfo in ipairs(tForceQuestInfo[r1.force]) do
								k1 = k1 + (r1.tTaskInfo[aInfo[1]] and tWeight[r1.tTaskInfo[aInfo[1]]] or 0)
							end
						end
						if tForceQuestInfo and tForceQuestInfo[r2.force] then
							for _, aInfo in ipairs(tForceQuestInfo[r2.force]) do
								k2 = k2 + (r2.tTaskInfo[aInfo[1]] and tWeight[r2.tTaskInfo[aInfo[1]]] or 0)
							end
						end
						if not IsInSamePeriod(r1.time, col.eType) then
							k1 = 0
						end
						if not IsInSamePeriod(r2.time, col.eType) then
							k2 = 0
						end
						if k1 == k2 then
							return 0
						end
						return k1 > k2 and 1 or -1
					end
				end
				table.insert(COLUMN_LIST, col)
			end
		end
	end
end
-- 时间
table.insert(COLUMN_LIST, {
	szKey = 'time',
	szTitle = _L['Cache time'],
	bTable = true,
	bRowTip = true,
	nMinWidth = 165,
	nMaxWidth = 200,
	GetValue = function(prevVal, prevRec)
		return GetCurrentTime()
	end,
	GetFormatText = function(time, rec)
		return GetFormatText(X.FormatTime(time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
	end,
})
-- 时间计时
table.insert(COLUMN_LIST, {
	szKey = 'time_days',
	szTitle = _L['Cache time days'],
	bTable = true,
	bRowTip = true,
	nMinWidth = 120,
	nMaxWidth = 120,
	Compare = function(v1, v2, r1, r2)
		v1, v2 = r1.time, r2.time
		if v1 == v2 then
			return 0
		end
		return v1 > v2 and 1 or -1
	end,
	GetFormatText = function(v, rec)
		local nTime = GetCurrentTime() - rec.time
		local nSeconds = math.floor(nTime)
		local nMinutes = math.floor(nSeconds / 60)
		local nHours   = math.floor(nMinutes / 60)
		local nDays    = math.floor(nHours / 24)
		local nYears   = math.floor(nDays / 365)
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
})

local COLUMN_DICT = {}
for _, col in ipairs(COLUMN_LIST) do
	if not col.GetFormatText then
		col.GetFormatText = function(v, rec)
			if not v then
				return GetFormatText('--', 162, 255, 255, 255)
			end
			return GetFormatText(v, 162, 255, 255, 255)
		end
	end
	if not col.Compare then
		col.Compare = function(v1, v2)
			if v1 == v2 then
				return 0
			end
			if not v1 then
				return -1
			end
			if not v2 then
				return 1
			end
			return v1 > v2 and 1 or -1
		end
	end
	COLUMN_DICT[col.szKey] = col
end

for _, col in ipairs(COLUMN_LIST) do
	X.SafeCall(col.Collector)
end

-- 移除不在同一个刷新周期内的数据字段
function D.FilterColumnCircle(rec)
	if X.IsNumber(rec.time) then
		for _, col in ipairs(COLUMN_LIST) do
			if col.szRefreshCircle then
				local dwTime, dwCircle = X.GetRefreshTime(col.szRefreshCircle)
				if dwTime - dwCircle >= rec.time then
					rec[col.szKey] = nil
				end
			end
		end
	end
end

function D.GetPlayerRecords()
	local result = X.LoadLUAData(STAT_DATA_FILE) or {}
	for _, rec in pairs(result) do
		D.FilterColumnCircle(rec)
	end
	return result
end

function D.GetClientPlayerRec()
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	-- 缓存数据
	if not PLAYER_REC_INITIAL then
		PLAYER_REC_INITIAL = X.LoadLUAData(PLAYER_REC_FILE) or {}
		D.FilterColumnCircle(PLAYER_REC_INITIAL)
		PLAYER_REC = X.Clone(PLAYER_REC_INITIAL)
		D.FilterColumnCircle(PLAYER_REC)
	end
	-- 获取各列数据
	for _, col in ipairs(COLUMN_LIST) do
		if col.GetValue then
			PLAYER_REC[col.szKey] = col.GetValue(PLAYER_REC_INITIAL[col.szKey], PLAYER_REC_INITIAL)
		end
	end
	-- 获取任务、BUFF状态
	local tTaskInfo = {}
	local tBuffInfo = {}
	for _, col in ipairs(COLUMN_LIST) do
		local aQuestInfo = col.aQuestInfo or (col.GetQuestInfo and col.GetQuestInfo())
		if aQuestInfo then
			for _, aInfo in ipairs(aQuestInfo) do
				tTaskInfo[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
			end
		end
		local tCampQuestInfo = col.tCampQuestInfo or (col.GetCampQuestInfo and col.GetCampQuestInfo())
		if tCampQuestInfo and tCampQuestInfo[me.nCamp] then
			for _, aInfo in ipairs(tCampQuestInfo[me.nCamp]) do
				tTaskInfo[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
			end
		end
		local tForceQuestInfo = col.tForceQuestInfo or (col.GetForceQuestInfo and col.GetForceQuestInfo())
		if tForceQuestInfo and tForceQuestInfo[me.dwForceID] then
			for _, aInfo in ipairs(tForceQuestInfo[me.dwForceID]) do
				tTaskInfo[aInfo[1]] = GetTaskState(me, aInfo[1], aInfo[2])
			end
		end
		local aBuffInfo = col.aBuffInfo or (col.GetBuffInfo and col.GetBuffInfo())
		if aBuffInfo then
			for _, aInfo in ipairs(aBuffInfo) do
				local nState = me.GetBuff(aInfo[1], aInfo[2] or 0)
					and TASK_STATE.FINISHED
					or TASK_STATE.UNKNOWN
				if nState == TASK_STATE.FINISHED then
					tBuffInfo[aInfo[1] .. '_0'] = TASK_STATE.FINISHED
				end
				tBuffInfo[aInfo[1] .. '_' .. (aInfo[2] or 0)] = nState
			end
		end
	end
	PLAYER_REC.tTaskInfo = tTaskInfo
	PLAYER_REC.tBuffInfo = tBuffInfo

	return X.Clone(PLAYER_REC)
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/task_stat.v2.db', X.PATH_TYPE.GLOBAL})
	local DB_V3_PATH = X.FormatPath({'userdata/role_statistics/task_stat.v3.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V2_PATH) and not IsLocalFileExist(DB_V3_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			local data = X.LoadLUAData(STAT_DATA_FILE) or {}
			-- 转移V2旧版数据
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					local aTaskInfo = X.SQLiteExecuteANSI(DB_V2, 'SELECT * FROM TaskInfo WHERE guid IS NOT NULL AND name IS NOT NULL')
					if aTaskInfo then
						for _, rec in ipairs(aTaskInfo) do
							if not data[rec.guid] or data[rec.guid].time <= rec.time then
								data[rec.guid] = {
									guid = rec.guid,
									account = rec.account,
									region = rec.region,
									server = rec.server,
									name = rec.name,
									force = rec.force,
									camp = rec.camp,
									level = rec.level,
									tTaskInfo = X.DecodeLUAData(rec.task_info or '') or {},
									tBuffInfo = X.DecodeLUAData(rec.buff_info or '') or {},
									time = rec.time,
								}
							end
						end
					end
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V3旧版数据
			if IsLocalFileExist(DB_V3_PATH) then
				local DB_V3 = SQLite3_Open(DB_V3_PATH)
				if DB_V3 then
					local aTaskInfo = X.SQLiteExecuteANSI(DB_V3, 'SELECT * FROM TaskInfo WHERE guid IS NOT NULL AND name IS NOT NULL')
					if aTaskInfo then
						for _, rec in ipairs(aTaskInfo) do
							if not data[rec.guid] or data[rec.guid].time <= rec.time then
								data[rec.guid] = {
									guid = rec.guid,
									account = rec.account,
									region = rec.region,
									server = rec.server,
									name = rec.name,
									force = rec.force,
									camp = rec.camp,
									level = rec.level,
									tTaskInfo = X.DecodeLUAData(rec.task_info or '') or {},
									tBuffInfo = X.DecodeLUAData(rec.buff_info or '') or {},
									time = rec.time,
								}
							end
						end
					end
					DB_V3:Release()
				end
				CPath.Move(DB_V3_PATH, DB_V3_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			X.SaveLUAData(STAT_DATA_FILE, data)
			FireUIEvent('MY_ROLE_STAT_TASK_UPDATE')
			X.Alert(_L['Migrate succeed!'])
		end)
end

function D.FlushDB()
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]
	local rec = D.GetClientPlayerRec()
	if O.bSaveDB then
		local data = X.LoadLUAData(STAT_DATA_FILE) or {}
		data[X.GetClientPlayerGlobalID()] = D.GetClientPlayerRec()
		X.SaveLUAData(STAT_DATA_FILE, data)
	end
	X.SaveLUAData(PLAYER_REC_FILE, rec)
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.OutputDebugMessage('MY_RoleStatistics_TaskStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
end

function D.UpdateSaveDB()
	if not D.bReady then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_RoleStatistics_TaskStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local data = X.LoadLUAData(STAT_DATA_FILE) or {}
		data[X.GetClientPlayerGlobalID()] = nil
		X.SaveLUAData(STAT_DATA_FILE, data)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_RoleStatistics_TaskStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_TASK_UPDATE')
end

function D.GetTableColumns()
	local aColumn = {}
	for nIndex, szKey in ipairs(O.aColumn) do
		local col = COLUMN_DICT[szKey]
		if col then
			table.insert(aColumn, col)
		end
	end
	local nLFixIndex, nLFixWidth = -1, 0
	for nIndex, col in ipairs(aColumn) do
		nLFixWidth = nLFixWidth + (col.nMinWidth or 100)
		if nLFixWidth > 450 then
			break
		end
		if col.szKey == 'name' then
			nLFixIndex = nIndex
			break
		end
	end
	local nRFixIndex, nRFixWidth = math.huge, 0
	for nIndex, col in X.ipairs_r(aColumn) do
		if nIndex <= nLFixIndex then
			break
		end
		nRFixWidth = nRFixWidth + (col.nMinWidth or 100)
		if nRFixWidth > 300 then
			break
		end
		if col.szKey == 'time' or col.szKey == 'time_days' then
			nRFixIndex = nIndex
		end
	end
	local aTableColumn = {}
	for nIndex, col in ipairs(aColumn) do
		local szFixed = nIndex <= nLFixIndex
			and 'left'
			or (nIndex >= nRFixIndex and 'right' or nil)
		local c = {
			key = col.szKey,
			title = col.szTitleAbbr or col.szTitle,
			titleTip = col.szTitleTip
				or (col.GetTitleFormatTip and function()
					return col.GetTitleFormatTip(), true
				end)
				or col.szTitle,
			alignHorizontal = col.szAlignHorizontal or 'center',
			render = col.GetFormatText
				and function(value, record, index)
					return col.GetFormatText(value, record)
				end
				or nil,
			sorter = col.Compare
				and function(v1, v2, r1, r2)
					return col.Compare(v1, v2, r1, r2)
				end
				or nil,
			tip = col.GetFormatTip
				and function(value, record, index)
					return col.GetFormatTip(value, record), true
				end
				or nil,
			draggable = true,
		}
		if szFixed then
			c.fixed = szFixed
			c.width = col.nMinWidth or 100
		else
			c.minWidth = col.nMinWidth
			c.maxWidth = col.nMaxWidth
		end
		table.insert(aTableColumn, c)
	end
	return aTableColumn
end

function D.GetResult(szSearch)
	-- 搜索
	local data = D.GetPlayerRecords()
	local result = {}
	for _, rec in pairs(data) do
		if not X.IsString(szSearch)
		or szSearch == ''
		or X.StringFindW(tostring(rec.account or ''), szSearch)
		or X.StringFindW(tostring(rec.name or ''), szSearch)
		or X.StringFindW(tostring(rec.region or ''), szSearch)
		or X.StringFindW(tostring(rec.server or ''), szSearch) then
			table.insert(result, rec)
		end
	end
	return result
end

function D.UpdateUI(page)
	local ui = X.UI(page)

	local szSearch = ui:Fetch('WndEditBox_Search'):Text()
	local result = D.GetResult(szSearch)

	ui:Fetch('WndTable_Stat')
		:Columns(D.GetTableColumns())
		:DataSource(result)
end

function D.GetRowTip(rec)
	local aXml = {}
	for _, col in ipairs(COLUMN_LIST) do
		if col.bRowTip then
			table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec[col.szKey], rec))
			table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	return table.concat(aXml)
end

function D.OutputFloatEntryTip(this)
	local rec = D.GetClientPlayerRec()
	if not rec then
		return
	end
	local aXml = {}
	for _, col in ipairs(COLUMN_LIST) do
		if col.bFloatTip then
			table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec[col.szKey], rec))
			table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
end

function D.CloseFloatEntryTip()
	HideTip()
end

function D.OnInitPage()
	local page = this
	local ui = X.UI(page)

	ui:Append('WndEditBox', {
		name = 'WndEditBox_Search',
		x = 20, y = 20, w = 388, h = 25,
		appearance = 'SEARCH_RIGHT',
		placeholder = _L['Press ENTER to search...'],
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.UpdateUI(page)
				return 1
			end
		end,
	})

	-- 显示列
	ui:Append('WndComboBox', {
		name = 'WndComboBox_DisplayColumns',
		x = 800, y = 20, w = 180,
		text = _L['Columns'],
		menu = function()
			local t = {}
			local function UpdateMenu()
				local aColumn, tChecked, nMinW = O.aColumn, {}, 0
				for i = 1, #t do
					t[i] = nil
				end
				-- 已添加的
				for nIndex, szKey in ipairs(aColumn) do
					local col = COLUMN_DICT[szKey]
					if col then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								local nOffset = IsShiftKeyDown() and 1 or -1
								if nIndex + nOffset < 1 or nIndex + nOffset > #O.aColumn then
									return
								end
								local aColumn = O.aColumn
								aColumn[nIndex], aColumn[nIndex + nOffset] = aColumn[nIndex + nOffset], aColumn[nIndex]
								O.aColumn = aColumn
								UpdateMenu()
								D.UpdateUI(page)
							end,
							fnMouseEnter = function()
								if #O.aColumn == 1 then
									return
								end
								local szText = _L['Click to move up, Hold SHIFT to move down.']
								if nIndex == 1 then
									szText = _L['Hold SHIFT click to move down.']
								elseif nIndex == #O.aColumn then
									szText = _L['Click to move up.']
								end
								local nX, nY = this:GetAbsX(), this:GetAbsY()
								local nW, nH = this:GetW(), this:GetH()
								OutputTip(GetFormatText(szText, nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.LEFT_RIGHT)
							end,
							fnMouseLeave = function()
								HideTip()
							end,
							{
								szOption = _L['Move up'],
								fnAction = function()
									if nIndex > 1 then
										aColumn[nIndex], aColumn[nIndex - 1] = aColumn[nIndex - 1], aColumn[nIndex]
										O.aColumn = aColumn
										UpdateMenu()
										D.UpdateUI(page)
									end
								end,
							},
							{
								szOption = _L['Move down'],
								fnAction = function()
									if nIndex < #aColumn then
										aColumn[nIndex], aColumn[nIndex + 1] = aColumn[nIndex + 1], aColumn[nIndex]
										O.aColumn = aColumn
										UpdateMenu()
										D.UpdateUI(page)
									end
								end,
							},
							X.CONSTANT.MENU_DIVIDER,
							{
								szOption = _L['Delete'],
								fnAction = function()
									table.remove(aColumn, nIndex)
									O.aColumn = aColumn
									UpdateMenu()
									D.UpdateUI(page)
								end,
								rgb = { 255, 128, 128 },
							},
						})
						nMinW = nMinW + col.nMinWidth
					end
					tChecked[szKey] = true
				end
				-- 未添加的
				for _, col in ipairs(COLUMN_LIST) do
					if col.bTable and not tChecked[col.szKey] then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								local aColumn = O.aColumn
								table.insert(aColumn, col.szKey)
								O.aColumn = aColumn
								UpdateMenu()
								D.FlushDB()
								D.UpdateUI(page)
							end,
						})
					end
				end
			end
			UpdateMenu()
			return t
		end,
	})

	ui:Append('WndTable', {
		name = 'WndTable_Stat',
		x = 20, y = 60, w = 960, h = 530,
		sort = O.szSort,
		sortOrder = O.szSortOrder,
		onSortChange = function(szSort, szSortOrder)
			O.szSort, O.szSortOrder = szSort, szSortOrder
		end,
		rowTip = {
			render = function(rec)
				return D.GetRowTip(rec), true
			end,
			position = X.UI.TIP_POSITION.RIGHT_LEFT,
		},
		rowMenuRClick = function(rec, index)
			local menu = {
				{
					szOption = _L['Delete'],
					fnAction = function()
						local data = X.LoadLUAData(STAT_DATA_FILE) or {}
						data[rec.guid] = nil
						X.SaveLUAData(STAT_DATA_FILE, data)
						D.UpdateUI(page)
					end,
					rgb = { 255, 128, 128 },
				},
			}
			PopupMenu(menu)
		end,
		onColumnsChange = function(aColumns)
			local aKeys = {}
			for _, col in ipairs(aColumns) do
				table.insert(aKeys, col.key)
			end
			O.aColumn = aKeys
			D.UpdateUI(page)
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('QUEST_ACCEPTED')
	frame:RegisterEvent('QUEST_CANCELED')
	frame:RegisterEvent('QUEST_FINISHED')
	frame:RegisterEvent('DAILY_QUEST_UPDATE')
	frame:RegisterEvent('MY_ROLE_STAT_TASK_UPDATE')

	D.OnResizePage()
end

function D.OnResizePage()
	local page = this
	local ui = X.UI(page)
	local nW, nH = ui:Size()

	ui:Fetch('WndComboBox_DisplayColumns'):Left(nW - 200)
	ui:Fetch('WndTable_Stat'):Size(nW - 40, nH - 100)
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
			X.Confirm(p.szMsg, function()
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
	D.Migration()
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
end

-- 浮动框
function D.ApplyFloatEntry(bFloatEntry)
	if bFloatEntry then
		if D.bFloatEntry then
			return
		end
		X.UI.RegisterFloatBar('MY_RoleStatistics_TaskEntry', {
			nPriority = 100.3,
			tAnchor = { s = 'TOPLEFT', r = 'TOPLEFT', x = 370 - 5 + 72, y = 30 - 5 + 37 },
			fnCreate = function(wnd)
				wnd:SetSize(24, 24)
				local frameTemp = X.UI.OpenFrame(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_TaskEntry.ini', 'MY_RoleStatistics_TaskEntry')
				local btn = frameTemp:Lookup('Btn_MY_RoleStatistics_TaskEntry')
				btn:ChangeRelation(wnd, true, true)
				btn:SetRelPos(2, 2)
				X.UI.CloseFrame(frameTemp)
				btn.OnMouseEnter = function()
					D.OutputFloatEntryTip(this)
				end
				btn.OnMouseLeave = function()
					D.CloseFloatEntryTip()
				end
				btn.OnLButtonClick = function()
					MY_RoleStatistics.Open('TaskStat')
				end
			end,
		})
	else
		if not D.bFloatEntry then
			return
		end
		X.UI.RegisterFloatBar('MY_RoleStatistics_TaskEntry', false)
	end
	D.bFloatEntry = bFloatEntry
end

function D.UpdateFloatEntry()
	if not D.bReady then
		return
	end
	D.ApplyFloatEntry(O.bFloatEntry)
end

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics_TaskStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnResizePage',
				szSaveDB = 'MY_RoleStatistics_TaskStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_TaskStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('TaskStat', _L['MY_RoleStatistics_TaskStat'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics_TaskStat',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'aColumn',
				'szSort',
				'szSortOrder',
				'bFloatEntry',
				'bSaveDB',
				'bAdviceSaveDB',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'aColumn',
				'szSort',
				'szSortOrder',
				'bFloatEntry',
				'bSaveDB',
				'bAdviceSaveDB',
			},
			triggers = {
				bFloatEntry = D.UpdateFloatEntry,
				bSaveDB = D.UpdateSaveDB,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_TaskStat = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_RoleStatistics_TaskStat', function()
	D.bReady = true
	D.UpdateFloatEntry()
end)

X.RegisterFlush('MY_RoleStatistics_TaskStat', function()
	D.FlushDB()
end)

X.RegisterExit('MY_RoleStatistics_TaskStat', function()
	if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
	end
end)

X.RegisterReload('MY_RoleStatistics_TaskStat', function()
	D.ApplyFloatEntry(false)
end)

X.RegisterFrameCreate('Player', 'MY_RoleStatistics_TaskStat',  function()
	D.UpdateFloatEntry()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
