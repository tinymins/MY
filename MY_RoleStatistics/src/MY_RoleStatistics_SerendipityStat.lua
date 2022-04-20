--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 奇遇统计（尝试触发次数统计）
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_SerendipityStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
	return
end
--------------------------------------------------------------------------

if ENVIRONMENT.GAME_BRANCH == 'classic' then
	return
end

local SERENDIPITY_LIST, MAP_POINT_LIST = unpack(X.LoadLUAData(PLUGIN_ROOT .. '/data/serendipity/{$lang}.jx3dat', { passphrase = false }) or {})
if not SERENDIPITY_LIST or not MAP_POINT_LIST then
	return X.Sysmsg(_L['MY_RoleStatistics_SerendipityStat'], _L['Cannot load serendipity data!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SERENDIPITY_HASH = {}
for _, v in ipairs(SERENDIPITY_LIST) do
	SERENDIPITY_HASH[v.nID] = v
end

CPath.MakeDir(X.FormatPath({'userdata/role_statistics', X.PATH_TYPE.GLOBAL}))

local DB = X.SQLiteConnect(_L['MY_RoleStatistics_SerendipityStat'], {'userdata/role_statistics/serendipity_stat.v3.db', X.PATH_TYPE.GLOBAL})
if not DB then
	return X.Sysmsg(_L['MY_RoleStatistics_SerendipityStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_TIP_INI = X.PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_SerendipityTip.ini'

DB:Execute([[
	CREATE TABLE IF NOT EXISTS Info (
		guid NVARCHAR(20) NOT NULL,
		account NVARCHAR(255) NOT NULL,
		region NVARCHAR(20) NOT NULL,
		server NVARCHAR(20) NOT NULL,
		name NVARCHAR(20) NOT NULL,
		force INTEGER NOT NULL,
		camp INTEGER NOT NULL,
		level INTEGER NOT NULL,
		serendipity_info NVARCHAR(65535) NOT NULL,
		item_count NVARCHAR(65535) NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(guid)
	)
]])
local InfoW = DB:Prepare('REPLACE INTO Info (guid, account, region, server, name, force, camp, level, serendipity_info, item_count, time, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local InfoG = DB:Prepare('SELECT * FROM Info WHERE guid = ?')
local InfoR = DB:Prepare('SELECT * FROM Info WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local InfoD = DB:Prepare('DELETE FROM Info WHERE guid = ?')
local MINI_MAP_POINT_MAX_DISTANCE = math.pow(300, 2)

local O = X.CreateUserSettingsModule('MY_RoleStatistics_SerendipityStat', _L['General'], {
	aColumn = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Collection(X.Schema.OneOf(X.Schema.String, X.Schema.Number)),
		xDefaultValue = {
			'name',
			'force',
			1, 2, 3, 4, 5, 6, 7, 8, 9,
			'time_days',
		},
	},
	szSort = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.String,
		xDefaultValue = 'time_days',
	},
	szSortOrder = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.String,
		xDefaultValue = 'desc',
	},
	bFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
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
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bMapMark = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bMapMarkHideAcquired = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTipHideFinished = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

function D.GetPlayerGUID(me)
	return me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName
end

-----------------------------------------------------------------------------------------------
-- 多个渠道奇遇次数监控
-----------------------------------------------------------------------------------------------
local SERENDIPITY_COUNTER = {}
local REGISTER_EVENT, REGISTER_MSG = {}, {}

local function RegisterEvent(szEvent, szKey, ...)
	if not REGISTER_EVENT[szEvent] then
		REGISTER_EVENT[szEvent] = {}
	end
	REGISTER_EVENT[szEvent][szKey] = true
	return X.RegisterEvent(szEvent, szKey, ...)
end

local function RegisterMsgMonitor(szEvent, szKey, ...)
	if not REGISTER_MSG[szEvent] then
		REGISTER_MSG[szEvent] = {}
	end
	REGISTER_MSG[szEvent][szKey] = true
	return X.RegisterMsgMonitor(szEvent, szKey, ...)
end

X.RegisterEvent('LOADING_ENDING', 'MY_RoleStatistics_SerendipityStat', function()
	for k, t in pairs(REGISTER_EVENT) do
		for v, _ in pairs(t) do
			X.RegisterEvent(k, v, false)
		end
	end
	for k, t in pairs(REGISTER_MSG) do
		for v, _ in pairs(t) do
			X.RegisterMsgMonitor(k, v, false)
		end
	end
	local function DelayTrigger()
		FireUIEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
	end
	local function OnSerendipityTrigger()
		X.DelayCall('MY_ROLE_STAT_SERENDIPITY_UPDATE', DelayTrigger)
	end
	local PARSE_TEXT = setmetatable({}, {__index = function(t, k)
		t[k] = wstring.gsub(k, '{$name}', GetClientPlayer().szName)
		return t[k]
	end})
	local function SerendipityStringTrigger(szText, aSearch, nID, nNum)
		for _, szSearch in ipairs(aSearch) do
			szSearch = PARSE_TEXT[szSearch]
			if szText:sub(1, #szSearch) == szSearch then
				SERENDIPITY_COUNTER[nID] = nNum
					or ((SERENDIPITY_COUNTER[nID] or 0) + 1)
				return OnSerendipityTrigger()
			end
		end
	end
	local dwMapID = GetClientPlayer().GetMapID()
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		if serendipity.dwMapID == dwMapID then
			-- 今日失败的判断们
			if serendipity.nBuffType == 1 then
				RegisterEvent('BUFF_UPDATE', 'MY_RoleStatistics_SerendipityStat_AttemptBuff' .. serendipity.nID, function()
					-- buff update：
					-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
					-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
					-- arg8：nLevel，arg9：dwSkillSrcID
					if arg0 == UI_GetClientPlayerID() and arg4 == serendipity.dwBuffID then
						OnSerendipityTrigger()
					end
				end)
			end
			if serendipity.aRejectOpenWindow then
				RegisterEvent('OPEN_WINDOW', 'MY_RoleStatistics_SerendipityStat_RejectOpenWindow' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aRejectOpenWindow, serendipity.nID, serendipity.nMaxAttemptNum)
				end)
			end
			if serendipity.aRejectWarningMessage then
				RegisterEvent('ON_WARNING_MESSAGE', 'MY_RoleStatistics_SerendipityStat_RejectWarningMessage' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aRejectWarningMessage, serendipity.nID, serendipity.nMaxAttemptNum)
				end)
			end
			if serendipity.aRejectNpcSayTo then
				RegisterMsgMonitor('MSG_NPC_NEARBY', 'MY_RoleStatistics_SerendipityStat_RejectNpcSayTo' .. serendipity.nID, function(szChannel, szMsg, nFont, bRich)
					if bRich then
						szMsg = GetPureText(szMsg)
					end
					SerendipityStringTrigger(szMsg, serendipity.aRejectNpcSayTo, serendipity.nID, serendipity.nMaxAttemptNum)
				end)
			end
			-- 尝试一次的判断们
			if serendipity.aAttemptOpenWindow then
				RegisterEvent('OPEN_WINDOW', 'MY_RoleStatistics_SerendipityStat_AttemptOpenWindow' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aAttemptOpenWindow, serendipity.nID)
				end)
			end
			if serendipity.aAttemptNpcSayTo then
				RegisterMsgMonitor('MSG_NPC_NEARBY', 'MY_RoleStatistics_SerendipityStat_AttemptNpcSayTo' .. serendipity.nID, function(szChannel, szMsg, nFont, bRich)
					if bRich then
						szMsg = GetPureText(szMsg)
					end
					SerendipityStringTrigger(szMsg, serendipity.aAttemptNpcSayTo, serendipity.nID)
				end)
			end
			if serendipity.aAttemptLootItem then
				RegisterEvent('LOOT_ITEM', 'MY_RoleStatistics_SerendipityStat_AttemptLootItem' .. serendipity.nID, function()
					if arg0 == UI_GetClientPlayerID() then
						local item = GetItem(arg1)
						if item then
							for _, v in ipairs(serendipity.aAttemptLootItem) do
								if v[1] == item.dwTabType and v[2] == item.dwIndex then
									SERENDIPITY_COUNTER[serendipity.nID] = (SERENDIPITY_COUNTER[serendipity.nID] or 0) + arg2
									OnSerendipityTrigger()
								end
							end
						end
					end
				end)
			end
			if serendipity.aAttemptItem then
				RegisterEvent('BAG_ITEM_UPDATE', 'MY_RoleStatistics_SerendipityStat_AttemptItem' .. serendipity.nID, function()
					local dwBox, dwX = arg0, arg1
					local me = GetClientPlayer()
					local item = GetPlayerItem(me, dwBox, dwX)
					if item then
						for _, v in ipairs(serendipity.aAttemptItem) do
							if v[1] == item.dwTabType and v[2] == item.dwIndex then
								OnSerendipityTrigger()
								break
							end
						end
					else
						OnSerendipityTrigger()
					end
				end)
			end
			if serendipity.aFailureOpenWindow then
				RegisterEvent('OPEN_WINDOW', 'MY_RoleStatistics_SerendipityStat_FailureOpenWindow' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aFailureOpenWindow, serendipity.nID)
				end)
			end
			if serendipity.aFailureNpcSayTo then
				RegisterMsgMonitor('MSG_NPC_NEARBY', 'MY_RoleStatistics_SerendipityStat_FailureNpcSayTo' .. serendipity.nID, function(szChannel, szMsg, nFont, bRich)
					if bRich then
						szMsg = GetPureText(szMsg)
					end
					SerendipityStringTrigger(szMsg, serendipity.aFailureNpcSayTo, serendipity.nID)
				end)
			end
			if serendipity.aFailureWarningMessage then
				RegisterEvent('ON_WARNING_MESSAGE', 'MY_RoleStatistics_SerendipityStat_FailureWarningMessage' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aFailureWarningMessage, serendipity.nID)
				end)
			end
			if serendipity.aFailureLootItem then
				RegisterEvent('LOOT_ITEM', 'MY_RoleStatistics_SerendipityStat_FailureLootItem' .. serendipity.nID, function()
					if arg0 == UI_GetClientPlayerID() then
						local item = GetItem(arg1)
						if item then
							for _, v in ipairs(serendipity.aFailureLootItem) do
								if v[1] == item.dwTabType and v[2] == item.dwIndex then
									SERENDIPITY_COUNTER[serendipity.nID] = (SERENDIPITY_COUNTER[serendipity.nID] or 0) + arg2
									OnSerendipityTrigger()
								end
							end
						end
					end
				end)
			end
		end
	end
end)

-----------------------------------------------------------------------------------------------
-- 获取是否是福源宠物
-----------------------------------------------------------------------------------------------
local FellowPetLucky = KG_Table.Load('settings\\Domesticate\\FellowPetLucky.tab', {
	{f = 'i', t = 'Date'},
	{f = 'i', t = 'PetIndex0'},
	{f = 'i', t = 'PetIndex1'},
	{f = 'i', t = 'PetIndex2'},
}, FILE_OPEN_MODE.NORMAL)

function D.GetLuckyFellowPet()
	local tTime = TimeToDate(GetCurrentTime())
	local nDate = tTime.month * 100 + tTime.day
	local tLine = FellowPetLucky:Search(nDate)
	if tLine then
		return {
			[tLine.PetIndex0] = true,
			[tLine.PetIndex1] = true,
			[tLine.PetIndex2] = true,
		}
	end
	return CONSTANT.EMPTY_TABLE
end

-----------------------------------------------------------------------------------------------
-- 可信的奇遇次数和周期计算
-----------------------------------------------------------------------------------------------
local function IsInSamePeriod(dwTime)
	local nNextTime, nCircle = X.GetRefreshTime('daily')
	return dwTime >= nNextTime - nCircle
end

-- 获取奇遇今天尝试了几次 -1表示已完成不需要尝试
local function GetSerendipityDailyCount(me, tab)
	if tab.dwPet and me.IsFellowPetAcquired(tab.dwPet) then
		return -1
	end
	if tab.dwQuest and me.GetQuestState(tab.dwQuest) == QUEST_STATE.FINISHED then
		return -1
	end
	if tab.aItemAcquired then
		for _, v in ipairs(tab.aItemAcquired) do
			if X.GetItemAmountInAllPackages(v[1], v[2]) > 0 then
				return -1
			end
		end
	end
	if tab.dwAchieve and me.IsAchievementAcquired(tab.dwAchieve) then
		return -1
	end
	if tab.dwSerendipity then
		local serendipity = Table_GetAdventure(tab.dwSerendipity)
		if serendipity then
			if serendipity.dwFinishID ~= 0 and me.GetAdventureFlag(serendipity.dwFinishID) then
				return -1
			end
			if serendipity.nFinishQuestID ~= 0 and me.GetQuestPhase(serendipity.nFinishQuestID) == 3 then
				return -1
			end
		end
	end
	if tab.nBuffType == 1 then
		local buff = X.GetBuff(me, tab.dwBuffID, 0)
		if buff then
			return buff.nStackNum
		end
		return 0
	end
end

local TASK_MIN_WIDTH = 42
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
		szTitle = _L['Region'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('region'),
		Compare = GeneCommonCompare('region'),
	},
	{ -- 服务器
		id = 'server',
		szTitle = _L['Server'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('server'),
		Compare = GeneCommonCompare('server'),
	},
	{ -- 名字
		id = 'name',
		szTitle = _L['Name'],
		nMinWidth = 110, nMaxWidth = 200,
		GetFormatText = function(rec)
			local name = rec.name
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name, 162, X.GetForceColor(rec.force, 'foreground'))
		end,
		Compare = GeneCommonCompare('name'),
	},
	{ -- 门派
		id = 'force',
		szTitle = _L['Force'],
		nMinWidth = 50, nMaxWidth = 70,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.tForceTitle[rec.force], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('force'),
	},
	{ -- 阵营
		id = 'camp',
		szTitle = _L['Camp'],
		nMinWidth = 50, nMaxWidth = 50,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.STR_CAMP_TITLE[rec.camp], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('camp'),
	},
	{ -- 等级
		id = 'level',
		szTitle = _L['Level'],
		nMinWidth = 50, nMaxWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- 时间
		id = 'time',
		szTitle = _L['Cache time'],
		nMinWidth = 165, nMaxWidth = 200,
		GetFormatText = function(rec)
			return GetFormatText(X.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
	{ -- 时间计时
		id = 'time_days',
		szTitle = _L['Cache time days'],
		nMinWidth = 120, nMaxWidth = 120,
		GetFormatText = function(rec)
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
		Compare = GeneCommonCompare('time'),
	},
}

local COLUMN_DICT = setmetatable({}, { __index = function(t, id)
	local serendipity = SERENDIPITY_HASH[id]
	if serendipity then
		local col = { -- 秘境CD
			id = id,
			szTitle = serendipity.szName,
			nMinWidth = TASK_MIN_WIDTH,
			nMaxWidth = TASK_MAX_WIDTH,
		}
		col.GetTitleFormatTip = function()
			local aTitleTipXml = {
				GetFormatText(serendipity.szName .. '\n', 162, 255, 255, 255),
			}
			if serendipity.szNick then
				table.insert(aTitleTipXml, GetFormatText('<' .. serendipity.szNick .. '>\n', 162, 255, 255, 255))
			end
			if serendipity.dwMapID then
				local map = X.GetMapInfo(serendipity.dwMapID)
				if map then
					table.insert(aTitleTipXml, GetFormatText('(' .. map.szName .. ')\n', 162, 255, 255, 255))
				end
			end
			return table.concat(aTitleTipXml)
		end
		col.GetText = function(rec)
			local nCount = rec.serendipity_info[id]
			local szState, r, g, b = nil, 255, 255, 255
			if nCount == -1 then
				szState, r, g, b = _L['Finished'], 128, 255, 128
			elseif not IsInSamePeriod(rec.time) then
				szState = _L['Unknown']
			elseif serendipity.nMaxAttemptNum > 0 then
				if serendipity.aAttemptItem then -- 包里有可用触发奇遇道具进行数量补偿
					for _, v in ipairs(serendipity.aAttemptItem) do
						nCount = (nCount or 0) - X.Get(rec.item_count, v, 0)
					end
				end
				if nCount and nCount >= serendipity.nMaxAttemptNum then
					r, g, b = 255, 170, 170
				end
				szState = (nCount or 0) .. '/' .. serendipity.nMaxAttemptNum
			else
				szState = (nCount or 0)
			end
			return szState, r, g, b
		end
		col.GetFormatText = function(rec)
			local szState, r, g, b = col.GetText(rec)
			return GetFormatText(szState, 162, r, g, b)
		end
		col.Compare = function(r1, r2)
			local k1, k2 = r1.serendipity_info[id] or 0, r2.serendipity_info[id] or 0
			if not IsInSamePeriod(r1.time) then
				k1 = 0
			end
			if not IsInSamePeriod(r2.time) then
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

do
local REC_CACHE
function D.GetClientPlayerRec()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rec = REC_CACHE
	local guid = D.GetPlayerGUID(me)
	if not rec then
		rec = {
			serendipity_info = {},
			item_count = {},
		}
		-- 如果在同一个CD周期 则保留数据库中的次数统计
		InfoG:ClearBindings()
		InfoG:BindAll(AnsiToUTF8(guid))
		local result = InfoG:GetAll()
		InfoG:Reset()
		if result and result[1] and result[1].time and IsInSamePeriod(result[1].time) then
			rec.serendipity_info = X.DecodeLUAData(result[1].serendipity_info) or rec.serendipity_info
			rec.item_count = X.DecodeLUAData(result[1].item_count) or rec.item_count
		end
		rec.serendipity_info = rec.serendipity_info
		rec.item_count = rec.item_count
		REC_CACHE = rec
	end

	-- 基础信息
	rec.guid = guid
	rec.account = X.GetAccount() or ''
	rec.region = X.GetRealServer(1)
	rec.server = X.GetRealServer(2)
	rec.name = me.szName
	rec.force = me.dwForceID
	rec.camp = me.nCamp
	rec.level = me.nLevel
	rec.time = GetCurrentTime()

	-- 统计可信的次数
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		local nDailyCount = GetSerendipityDailyCount(me, serendipity)
		if nDailyCount then
			rec.serendipity_info[serendipity.nID] = nDailyCount
		end
		if serendipity.aAttemptItem then
			for _, v in ipairs(serendipity.aAttemptItem) do
				if not rec.item_count[v[1]] then
					rec.item_count[v[1]] = {}
				end
				rec.item_count[v[1]][v[2]] = X.GetItemAmountInAllPackages(v[1], v[2])
				if X.IsEmpty(rec.item_count[v[1]][v[2]]) then
					rec.item_count[v[1]][v[2]] = nil
				end
				if X.IsEmpty(rec.item_count[v[1]]) then
					rec.item_count[v[1]] = nil
				end
			end
		end
		if SERENDIPITY_COUNTER[serendipity.nID] then
			rec.serendipity_info[serendipity.nID] = math.min((rec.serendipity_info[serendipity.nID] or 0) + SERENDIPITY_COUNTER[serendipity.nID], serendipity.nMaxAttemptNum)
		end
		SERENDIPITY_COUNTER[serendipity.nID] = nil
	end
	return rec
end
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/serendipity_stat.v2.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V2_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			-- 转移V2旧版数据
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					DB:Execute('BEGIN TRANSACTION')
					local aInfo = DB_V2:Execute('SELECT * FROM Info WHERE guid IS NOT NULL AND region IS NOT NULL AND name IS NOT NULL')
					if aInfo then
						for _, rec in ipairs(aInfo) do
							InfoW:ClearBindings()
							InfoW:BindAll(
								rec.guid,
								rec.account,
								rec.region,
								rec.server,
								rec.name,
								rec.force,
								rec.camp,
								rec.level,
								rec.serendipity_info,
								rec.item_count,
								rec.time,
								''
							)
							InfoW:Execute()
						end
						InfoW:Reset()
					end
					DB:Execute('END TRANSACTION')
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			FireUIEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
			X.Alert(_L['Migrate succeed!'])
		end)
end

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]

	local rec = X.Clone(D.GetClientPlayerRec())
	D.EncodeRow(rec)

	DB:Execute('BEGIN TRANSACTION')
	InfoW:ClearBindings()
	InfoW:BindAll(
		rec.guid, rec.account, rec.region, rec.server,
		rec.name, rec.force, rec.camp, rec.level,
		rec.serendipity_info, rec.item_count, rec.time, '')
	InfoW:Execute()
	InfoW:Reset()
	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.Debug('MY_RoleStatistics_SerendipityStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
X.RegisterFlush('MY_RoleStatistics_SerendipityStat', D.FlushDB)

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
		X.Debug('MY_RoleStatistics_SerendipityStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		InfoD:ClearBindings()
		InfoD:BindAll(AnsiToUTF8(D.GetPlayerGUID(me)))
		InfoD:Execute()
		InfoD:Reset()
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_SerendipityStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
end
X.RegisterInit('MY_RoleStatistics_SerendipityUpdateSaveDB', function() INIT = true end)
end

function D.GetColumns()
	local aCol = {}
	for _, id in ipairs(O.aColumn) do
		local col = COLUMN_DICT[id]
		if col then
			table.insert(aCol, col)
		end
	end
	return aCol
end

function D.GetTableColumns()
	local aColumn = D.GetColumns()
	local aTableColumn = {}
	local nFixIndex, nFixWidth = -1, 0
	for nIndex, col in ipairs(aColumn) do
		nFixWidth = nFixWidth + (col.nMinWidth or 100)
		if nFixWidth > 600 then
			break
		end
		if col.id == 'name' then
			nFixIndex = nIndex
			break
		end
	end
	for nIndex, col in ipairs(aColumn) do
		local bFixed = nIndex <= nFixIndex
		local c = {
			key = col.id,
			title = col.szTitle,
			titleTip = col.szTitleTip
				or (col.GetTitleFormatTip and function()
					return col.GetTitleFormatTip(), true
				end)
				or col.szTitle,
			alignHorizontal = 'center',
			render = col.GetFormatText
				and function(value, record, index)
					return col.GetFormatText(record)
				end
				or nil,
			sorter = col.Compare
				and function(v1, v2, r1, r2)
					return col.Compare(r1, r2)
				end
				or nil,
			draggable = true,
		}
		if bFixed then
			c.fixed = true
			c.width = col.nMinWidth or 100
		else
			c.minWidth = col.nMinWidth
			c.maxWidth = col.nMaxWidth
		end
		table.insert(aTableColumn, c)
	end
	return aTableColumn
end

function D.UpdateUI(page)
	local ui = UI(page)

	local szSearch = ui:Fetch('WndEditBox_Search'):Text()
	local szUSearch = AnsiToUTF8('%' .. szSearch .. '%')
	InfoR:ClearBindings()
	InfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = InfoR:GetAll()
	InfoR:Reset()

	for _, rec in ipairs(result) do
		D.DecodeRow(rec)
	end

	ui:Fetch('WndTable_Stat')
		:Columns(D.GetTableColumns())
		:DataSource(result)
end

function D.EncodeRow(rec)
	rec.guid = AnsiToUTF8(rec.guid)
	rec.region = AnsiToUTF8(rec.region)
	rec.server = AnsiToUTF8(rec.server)
	rec.name = AnsiToUTF8(rec.name)
	rec.serendipity_info = X.EncodeLUAData(rec.serendipity_info)
	rec.item_count = X.EncodeLUAData(rec.item_count)
end

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
	rec.serendipity_info = X.DecodeLUAData(rec.serendipity_info or '') or {}
	rec.item_count = X.DecodeLUAData(rec.item_count or '') or {}
end

function D.OutputRowTip(this, rec)
	local frame = Wnd.OpenWindow(SZ_TIP_INI, 'MY_RoleStatistics_SerendipityTip')
	local hList = frame:Lookup('', 'Handle_List')
	local imgBg = frame:Lookup('', 'Image_Bg')
	local imgBreak = frame:Lookup('', 'Image_SerendipityStat_Break')
	hList:Clear()
	hList:AppendItemFromIni(SZ_TIP_INI, 'Handle_Title'):Lookup('Text_Title'):SetText(
		rec.region .. ' ' .. rec.server .. ' - ' .. rec.name
		.. ' (' .. g_tStrings.tForceTitle[rec.force] .. ' ' .. rec.level .. g_tStrings.STR_LEVEL .. ')')
	local dwMapID = GetClientPlayer().GetMapID()
	local tLuckPet = D.GetLuckyFellowPet()
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		local col = COLUMN_DICT[serendipity.nID]
		local szText, r, g, b = col.GetText(rec)
		if not O.bTipHideFinished or szText ~= _L['Finished'] then
			local hItem = hList:AppendItemFromIni(SZ_TIP_INI, 'Handle_Item')
			local szName = serendipity.szName
			if serendipity.szNick then
				szName = szName .. '<' .. serendipity.szNick .. '>'
			end
			hItem:Lookup('Image_Lucky'):SetVisible(serendipity.dwPet and tLuckPet[serendipity.dwPet] or false)
			hItem:Lookup('Text_Name'):SetText(szName)
			hItem:Lookup('Text_Name'):SetFontColor(255, 255, 128)
			hItem:Lookup('Text_Name').OnItemLButtonClick = function()
				if serendipity.dwAchieve and MY_AchievementWiki then
					MY_AchievementWiki.Open(serendipity.dwAchieve)
					Wnd.CloseWindow(frame)
				end
			end
			hItem:Lookup('Text_Name'):RegisterEvent(16)
			local map = serendipity.dwMapID and X.GetMapInfo(serendipity.dwMapID)
			hItem:Lookup('Text_Map'):SetText(map and map.szName or '')
			if dwMapID == serendipity.dwMapID then
				hItem:Lookup('Text_Map'):SetFontColor(168, 240, 240)
			else
				hItem:Lookup('Text_Map'):SetFontColor(192, 192, 192)
			end
			hItem:Lookup('Text_State'):SetText(szText)
			hItem:Lookup('Text_State'):SetFontColor(r, g, b)
		end
	end
	hList:FormatAllItemPos()
	local nDeltaY = select(2, hList:GetAllItemSize()) + hList:GetRelY() - hList:GetH()
	hList:SetH(hList:GetH() + nDeltaY)
	imgBg:SetH(imgBg:GetH() + nDeltaY)
	imgBreak:SetH(imgBreak:GetH() + nDeltaY)
	frame:SetH(frame:GetH() + nDeltaY)
	frame.OnFrameBreathe = function()
		local wnd, item = Station.GetMouseOverWindow()
		if wnd then
			if wnd:GetName() == 'Btn_MY_RoleStatistics_SerendipityEntry' then
				return
			end
			local frame = wnd:GetRoot()
			local name = frame:GetName()
			if name == 'MY_RoleStatistics_SerendipityTip' then
				return
			end
			if name == 'MY_RoleStatistics' then
				while item do
					if item:GetName() == 'Handle_Row' then
						return
					end
					item = item:GetParent()
				end
			end
		end
		Wnd.CloseWindow(frame)
	end
	if this:GetRoot():GetName() == 'MY_RoleStatistics' then
		frame:SetPoint('CENTER', 0, 0, this:GetRoot():GetTreePath(), 'CENTER', 0, 0)
	else
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		local nCW, nCH = Station.GetClientSize()
		nX = nX + nW / 2 - frame:GetW() / 2
		nY = (nY + nH + frame:GetH() < nCH)
			and (nY + nH - 2)
			or (nY - frame:GetH() + 2)
		frame:SetRelPos(nX, nY)
	end
end

function D.CloseRowTip()
	-- Wnd.CloseWindow('MY_RoleStatistics_SerendipityTip')
end

function D.OnInitPage()
	local page = this
	local ui = UI(page)

	ui:Append('WndEditBox', {
		name = 'WndEditBox_Search',
		x = 20, y = 20, w = 300, h = 25,
		appearance = 'SEARCH_RIGHT',
		placeholder = _L['Press ENTER to search...'],
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.UpdateUI(page)
				return 1
			end
		end,
	})

	ui:Append('WndCheckBox', {
		x = 380, y = 21, w = 160,
		text = _L['Tip hide finished'],
		checked = MY_RoleStatistics_SerendipityStat.bTipHideFinished,
		onCheck = function()
			MY_RoleStatistics_SerendipityStat.bTipHideFinished = not MY_RoleStatistics_SerendipityStat.bTipHideFinished
		end,
		autoEnable = function() return MY_RoleStatistics_SerendipityStat.bFloatEntry end,
	})

	ui:Append('WndCheckBox', {
		x = 540, y = 21, w = 130,
		text = _L['Map mark'],
		checked = MY_RoleStatistics_SerendipityStat.bMapMark,
		onCheck = function()
			MY_RoleStatistics_SerendipityStat.bMapMark = not MY_RoleStatistics_SerendipityStat.bMapMark
		end,
	})

	ui:Append('WndCheckBox', {
		x = 670, y = 21, w = 130,
		text = _L['Map mark hide acquired'],
		checked = MY_RoleStatistics_SerendipityStat.bMapMarkHideAcquired,
		onCheck = function()
			MY_RoleStatistics_SerendipityStat.bMapMarkHideAcquired = not MY_RoleStatistics_SerendipityStat.bMapMarkHideAcquired
		end,
		autoEnable = function() return MY_RoleStatistics_SerendipityStat.bMapMark end,
	})

	ui:Append('WndComboBox', {
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
				for nIndex, id in ipairs(aColumn) do
					local col = COLUMN_DICT[id]
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
							CONSTANT.MENU_DIVIDER,
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
					tChecked[id] = true
				end
				-- 未添加的
				local function fnAction(id, nWidth)
					local bExist = false
					for i, v in ipairs(aColumn) do
						if v == id then
							table.remove(aColumn, i)
							O.aColumn = aColumn
							bExist = true
							break
						end
					end
					if not bExist then
						table.insert(aColumn, id)
						O.aColumn = aColumn
					end
					UpdateMenu()
					D.FlushDB()
					D.UpdateUI(page)
				end
				-- 普通选项
				for _, col in ipairs(COLUMN_LIST) do
					if not tChecked[col.id] then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								fnAction(col.id, col.nMinWidth)
							end,
						})
					end
				end
				-- 奇遇选项
				local t1 = { szOption = _L['Serendipity'], nMaxHeight = 1000 }
				for _, serendipity in ipairs(SERENDIPITY_LIST) do
					if not tChecked[serendipity.nID] then
						local col = COLUMN_DICT[serendipity.nID]
						if col then
							table.insert(t1, {
								szOption = col.szTitle,
								bCheck = true, bChecked = tChecked[col.id],
								fnAction = function()
									fnAction(col.id, col.nMinWidth)
								end,
							})
						end
						tChecked[serendipity.nID] = true
					end
				end
				table.insert(t, t1)
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
		onRowHover = function(bIn, rec)
			if bIn then
				D.OutputRowTip(this, rec)
			else
				D.CloseRowTip()
			end
		end,
		rowMenuRClick = function(rec, index)
			local menu = {
				{
					szOption = _L['Delete'],
					fnAction = function()
						InfoD:ClearBindings()
						InfoD:BindAll(AnsiToUTF8(rec.guid))
						InfoD:Execute()
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

	ui:Append('WndButton', {
		x = 440, y = 590, w = 120,
		text = _L['Refresh'],
		onClick = function()
			D.FlushDB()
			D.UpdateUI(page)
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
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
				MY_RoleStatistics_SerendipityStat[p.szSetKey] = true
				MY_RoleStatistics_SerendipityStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end, function()
				MY_RoleStatistics_SerendipityStat[p.szAdviceKey] = true
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
	elseif event == 'MY_ROLE_STAT_SERENDIPITY_UPDATE' then
		D.FlushDB()
		D.UpdateUI(this)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		X.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			InfoD:ClearBindings()
			InfoD:BindAll(AnsiToUTF8(wnd.guid))
			InfoD:Reset()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemMouseEnter()
	if this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	HideTip()
end

-------------------------------------------------------------------------------------------------------
-- 浮动框
-------------------------------------------------------------------------------------------------------
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/SprintPower')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_SerendipityEntry')
	if X.IsNil(bFloatEntry) then
		bFloatEntry = O.bFloatEntry
	end
	if bFloatEntry then
		if btn then
			return
		end
		local frameTemp = Wnd.OpenWindow(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_SerendipityEntry.ini', 'MY_RoleStatistics_SerendipityEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_SerendipityEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(61, 60)
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
			MY_RoleStatistics.Open('SerendipityStat')
		end
	else
		if not btn then
			return
		end
		btn:Destroy()
	end
end
function D.UpdateFloatEntry()
	if not D.bReady then
		return
	end
	D.ApplyFloatEntry(O.bFloatEntry)
end
X.RegisterInit('MY_RoleStatistics_SerendipityEntry', function()
	D.bReady = true
	D.UpdateFloatEntry()
end)
X.RegisterReload('MY_RoleStatistics_SerendipityEntry', function() D.ApplyFloatEntry(false) end)
X.RegisterFrameCreate('SprintPower', 'MY_RoleStatistics_SerendipityEntry', D.UpdateFloatEntry)

-------------------------------------------------------------------------------------------------------
-- 地图标记
-------------------------------------------------------------------------------------------------------
function D.OnMMMItemMouseEnter()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local mark = this.data
	local aXml = {}
	-- 名字
	if mark.dwType and mark.dwID then
		table.insert(aXml, GetFormatText(X.GetTemplateName(mark.dwType, mark.dwID) .. '\n', 162, 255, 255, 0))
	end
	-- 奇遇名称
	if mark.nSerendipityID then
		local serendipity = SERENDIPITY_HASH[mark.nSerendipityID]
		if serendipity then
			table.insert(aXml, GetFormatText(serendipity.szName .. _L[' - '], 162, 255, 255, 255))
		end
	end
	-- 奇遇类型
	if mark.szType == 'TRIGGER' then
		table.insert(aXml, GetFormatText(_L['Trigger'] .. '\n', 162, 255, 255, 255))
	elseif mark.szType == 'LOOT' then
		table.insert(aXml, GetFormatText(_L['Loot item'] .. '\n', 162, 255, 255, 255))
	end
	-- 当前统计
	local szState, r, g, b
	if mark.nSerendipityID then
		local col = COLUMN_DICT[mark.nSerendipityID]
		if col then
			local rec = D.GetClientPlayerRec()
			if rec then
				szState, r, g, b = col.GetText(rec)
			end
		end
	end
	if szState then
		table.insert(aXml, GetFormatText(szState .. '\n', 162, r, g, b))
	end
	-- 调用显示
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
end

function D.OnMMMItemMouseLeave()
	HideTip()
end

function D.GetVisibleMapPoint(dwMapID)
	local aMapPoint = {}
	local player = GetClientPlayer()
	if player then
		for _, mark in ipairs(MAP_POINT_LIST) do
			local bShow = mark.dwMapID == dwMapID and mark.aPosition and true or false
			if bShow and O.bMapMarkHideAcquired then
				if mark.dwPet and player.IsFellowPetAcquired(mark.dwPet) then
					bShow = false
				end
				if bShow and mark.nSerendipityID then
					local serendipity = SERENDIPITY_HASH[mark.nSerendipityID]
					if serendipity and GetSerendipityDailyCount(player, serendipity) == -1 then
						bShow = false
					end
				end
			end
			if bShow then
				table.insert(aMapPoint, mark)
			end
		end
	end
	return aMapPoint
end

function D.DrawMapMark()
	local frame = Station.Lookup('Topmost1/MiddleMap')
	local player = GetClientPlayer()
	if not player or not frame or not frame:IsVisible() then
		return
	end
	local hInner = frame:Lookup('', 'Handle_Inner')
	local nW, nH = hInner:GetSize()
	local hMMM = hInner:Lookup('Handle_MY_SerendipityMMM')
	if not hMMM then
		hInner:AppendItemFromString('<handle>firstpostype=0 name="Handle_MY_SerendipityMMM" w=' .. nW .. ' h=' .. nH .. '</handle>')
		hMMM = hInner:Lookup('Handle_MY_SerendipityMMM')
		hInner:FormatAllItemPos()
	end
	local nCount = 0
	local nItemCount = hMMM:GetItemCount()

	for _, mark in ipairs(D.GetVisibleMapPoint(MiddleMap.dwMapID or player.GetMapID())) do
		if mark.aPosition then
			for _, pos in ipairs(mark.aPosition) do
				local nX, nY = MiddleMap.LPosToHPos(pos[1], pos[2], 13, 13)
				if nX > 0 and nY > 0 and nX < nW and nY < nH then
					nCount = nCount + 1
					if nCount > nItemCount then
						hMMM:AppendItemFromString('<image>w=10 h=10 alpha=210 path="ui/Image/UICommon/CommonPanel4.UITex" frame=69 eventid=784</image>')
						nItemCount = nItemCount + 1
					end
					local item = hMMM:Lookup(nCount - 1)
					item:Show()
					item:SetRelPos(nX, nY)
					item:SetFrame(mark.szType == 'TRIGGER' and 69 or 90)
					item.data = mark
					item.OnItemMouseEnter = D.OnMMMItemMouseEnter
					item.OnItemMouseLeave = D.OnMMMItemMouseLeave
				end
			end
		end
	end

	for i = nCount, nItemCount - 1 do
		hMMM:Lookup(i):Hide()
	end
	hMMM:FormatAllItemPos()
end

function D.DrawMiniMapPoint()
	local me = GetClientPlayer()
	if not me then
		return
	end
	for _, mark in ipairs(D.GetVisibleMapPoint(me.GetMapID())) do
		if mark.aPosition then
			for _, pos in ipairs(mark.aPosition) do
				if math.pow((me.nX - pos[1]) / 64, 2) + math.pow((me.nY - pos[2]) / 64, 2) <= MINI_MAP_POINT_MAX_DISTANCE then
					X.UpdateMiniFlag(CONSTANT.MINI_MAP_POINT.FUNCTION_NPC,
						pos[1], pos[2], 21, 47, ENVIRONMENT.GAME_FPS)
				end
			end
		end
	end
end

function D.HookMiniMapMark()
	X.BreatheCall('MY_RoleStatistics_SerendipityMiniMapMark', 1000, D.DrawMiniMapPoint)
end

function D.UnhookMiniMapMark()
	X.BreatheCall('MY_RoleStatistics_SerendipityMiniMapMark', false)
end
X.RegisterReload('MY_RoleStatistics_SerendipityMiniMapMark', D.UnhookMiniMapMark)

function D.HookMapMark()
	D.UnhookMapMark()
	HookTableFunc(MiddleMap, 'ShowMap', D.DrawMapMark, { bAfterOrigin = true })
	HookTableFunc(MiddleMap, 'UpdateCurrentMap', D.DrawMapMark, { bAfterOrigin = true })
end

function D.UnhookMapMark()
	local h = Station.Lookup('Topmost1/MiddleMap', 'Handle_Inner/Handle_MY_SerendipityMMM')
	if h then
		h:GetParent():RemoveItem(h)
	end
	UnhookTableFunc(MiddleMap, 'ShowMap', D.DrawMapMark)
	UnhookTableFunc(MiddleMap, 'UpdateCurrentMap', D.DrawMapMark)
end
X.RegisterReload('MY_RoleStatistics_SerendipityMapMark', D.UnhookMapMark)

function D.CheckMapMark()
	if D.bReady and O.bMapMark then
		D.HookMapMark()
		D.DrawMapMark()
		D.HookMiniMapMark()
	else
		D.UnhookMapMark()
		D.UnhookMiniMapMark()
	end
end
X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_RoleStatistics_SerendipityStat', function()
	D.bReady = true
	D.CheckMapMark()
	if not ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
	end
	D.UpdateFloatEntry()
end)

-- Module exports
do
local settings = {
	name = 'MY_RoleStatistics_SerendipityStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				szSaveDB = 'MY_RoleStatistics_SerendipityStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_SerendipityStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('SerendipityStat', _L['MY_RoleStatistics_SerendipityStat'], X.CreateModule(settings))
end

-- Global exports
do
local settings = {
	name = 'MY_RoleStatistics_SerendipityStat',
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
				'bMapMark',
				'bMapMarkHideAcquired',
				'bTipHideFinished',
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
				'bMapMark',
				'bMapMarkHideAcquired',
				'bTipHideFinished',
			},
			triggers = {
				bFloatEntry = D.UpdateFloatEntry,
				bSaveDB = D.UpdateSaveDB,
				bMapMark = D.CheckMapMark,
				bMapMarkHideAcquired = D.CheckMapMark,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_SerendipityStat = X.CreateModule(settings)
end
