--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 奇遇统计（尝试触发次数统计）
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RoleStatistics/MY_RoleStatistics_SerendipityStat'
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_SerendipityStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^15.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local SERENDIPITY_LIST, MAP_POINT_LIST = unpack(X.LoadLUAData(PLUGIN_ROOT .. '/data/serendipity/{$edition}.jx3dat', { passphrase = false }) or {})
if not SERENDIPITY_LIST or not MAP_POINT_LIST then
	return
end
local SERENDIPITY_HASH = {}
for _, v in ipairs(SERENDIPITY_LIST) do
	SERENDIPITY_HASH[v.nID] = v
end

local SZ_TIP_INI = X.PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_SerendipityTip.ini'
local STAT_DATA_FILE = {'userdata/role_statistics/serendipity_stat.jx3dat', X.PATH_TYPE.GLOBAL}
local PLAYER_REC_FILE = {'userdata/role_statistics/serendipity_stat.jx3dat', X.PATH_TYPE.ROLE}
local PLAYER_REC_INITIAL, PLAYER_REC = nil, nil

local MINI_MAP_POINT_MAX_DISTANCE = math.pow(300, 2)

local O = X.CreateUserSettingsModule('MY_RoleStatistics_SerendipityStat', _L['General'], {
	aColumn = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Collection(X.Schema.String),
		xDefaultValue = (function()
			local aKey = {
				'name',
			}
			for i = #SERENDIPITY_LIST, math.max(1, #SERENDIPITY_LIST - 14), -1 do
				local nID = SERENDIPITY_LIST[i].nID
				if nID then
					table.insert(aKey, 'serendipity_' .. nID)
				end
			end
			table.insert(aKey, 'time_days')
			return aKey
		end)(),
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
		t[k] = X.StringReplaceW(k, '{$name}', X.GetClientPlayer().szName)
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
	local dwMapID = X.GetClientPlayer().GetMapID()
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		if serendipity.dwMapID == dwMapID then
			-- 今日失败的判断们
			if serendipity.nBuffType == 1 then
				RegisterEvent('BUFF_UPDATE', 'MY_RoleStatistics_SerendipityStat_AttemptBuff' .. serendipity.nID, function()
					-- buff update：
					-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
					-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
					-- arg8：nLevel，arg9：dwSkillSrcID
					if arg0 == X.GetClientPlayerID() and arg4 == serendipity.dwBuffID then
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
					if arg0 == X.GetClientPlayerID() then
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
					local me = X.GetClientPlayer()
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
					if arg0 == X.GetClientPlayerID() then
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
	local tLine = FellowPetLucky and FellowPetLucky:Search(nDate)
	if tLine then
		return {
			[tLine.PetIndex0] = true,
			[tLine.PetIndex1] = true,
			[tLine.PetIndex2] = true,
		}
	end
	return X.CONSTANT.EMPTY_TABLE
end

-----------------------------------------------------------------------------------------------
-- 可信的奇遇次数
-----------------------------------------------------------------------------------------------
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
		local Adventure = X.GetGameTable('Adventure')
		local serendipity = Adventure and Adventure:Search(tab.dwSerendipity)
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

-- 获取奇遇当前尝试了几次，当前周期可以尝试几次
local function GetSerendipityCounter(serendipity, value)
	local nCount
	if value then
		nCount = value.count or 0
		if nCount ~= -1 and serendipity.nMaxAttemptNum > 0 then
			if value.extra then
				nCount = nCount - value.extra
			end
		end
	end
	return nCount, serendipity.nMaxAttemptNum
end

-- 获取奇遇状态字符串，提示配色
local function GetSerendipityCounterText(serendipity, value)
	local szText, r, g, b = nil, 255, 255, 255
	local nCount, nMaxAttemptNum = GetSerendipityCounter(serendipity, value)
	if nCount == -1 then
		szText, r, g, b = _L['Finished'], 128, 255, 128
	elseif nMaxAttemptNum > 0 then
		if nCount and nCount >= nMaxAttemptNum then
			r, g, b = 255, 170, 170
		end
		szText = (nCount or 0) .. '/' .. nMaxAttemptNum
	else
		szText = tostring(nCount or 0)
	end
	return szText, r, g, b
end

local COLUMN_LIST = {
	-- guid
	{
		szKey = 'guid',
		GetValue = function(prevVal, prevRec)
			return X.GetPlayerGUID()
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
		nMinWidth = 50,
		nMaxWidth = 70,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().dwForceID
		end,
		GetFormatText = function(force)
			return GetFormatText(g_tStrings.tForceTitle[force], 162, 255, 255, 255)
		end,
	},
	-- 阵营
	{
		szKey = 'camp',
		szTitle = _L['Camp'],
		bTable = true,
		nMinWidth = 50,
		nMaxWidth = 50,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().nCamp
		end,
		GetFormatText = function(camp)
			return GetFormatText(g_tStrings.STR_CAMP_TITLE[camp], 162, 255, 255, 255)
		end,
	},
	-- 等级
	{
		szKey = 'level',
		szTitle = _L['Level'],
		bTable = true,
		nMinWidth = 50,
		nMaxWidth = 50,
		GetValue = function(prevVal, prevRec)
			return X.GetClientPlayer().nLevel
		end,
	},
	-- 时间
	{
		szKey = 'time',
		szTitle = _L['Cache time'],
		bTable = true,
		nMinWidth = 165,
		nMaxWidth = 200,
		GetValue = function(prevVal, prevRec)
			return GetCurrentTime()
		end,
		GetFormatText = function(time)
			return GetFormatText(X.FormatTime(time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
		end,
	},
	-- 时间计时
	{
		szKey = 'time_days',
		szTitle = _L['Cache time days'],
		bTable = true,
		nMinWidth = 120,
		nMaxWidth = 120,
		GetValue = function(prevVal, prevRec)
			return GetCurrentTime()
		end,
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
	},
}

for _, serendipity in ipairs(SERENDIPITY_LIST) do
	local szKey = 'serendipity_' .. serendipity.nID
	table.insert(COLUMN_LIST, {
		szKey = szKey,
		szTitle = serendipity.szName,
		bTable = true,
		nMinWidth = 48,
		nMaxWidth = 150,
		szRefreshCircle = 'daily',
		GetTitleTip = function()
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
			return table.concat(aTitleTipXml), true
		end,
		GetValue = function(prevVal, prevRec)
			local value = {
				count = GetSerendipityDailyCount(X.GetClientPlayer(), serendipity) or X.Get(prevVal, 'count'),
				extra = 0,
			}
			-- 包里有可用触发奇遇道具进行数量补偿
			if serendipity.aAttemptItem then
				for _, v in ipairs(serendipity.aAttemptItem) do
					value.extra = value.extra + X.GetItemAmountInAllPackages(v[1], v[2])
				end
			end
			-- 本次在线触发记录
			if SERENDIPITY_COUNTER[serendipity.nID] then
				value.count = math.min((value.count or 0) + SERENDIPITY_COUNTER[serendipity.nID], serendipity.nMaxAttemptNum)
			end
			return value
		end,
		Compare = function(v1, v2, r1, r2)
			local k1 = v1 and v1.count or 0
			local k2 = v2 and v2.count or 0
			if k1 == k2 then
				return 0
			end
			return k1 > k2 and 1 or -1
		end,
		GetFormatText = function(v, rec)
			local szState, r, g, b = GetSerendipityCounterText(serendipity, rec)
			return GetFormatText(szState, 162, r, g, b)
		end,
	})
end

local COLUMN_DICT = {}
for _, col in ipairs(COLUMN_LIST) do
	if not col.GetFormatText then
		col.GetFormatText = function(v)
			return GetFormatText(v, 162, 255, 255, 255)
		end
	end
	if not col.Compare then
		col.Compare = function(v1, v2)
			if v1 == v2 then
				return 0
			end
			return v1 > v2 and 1 or -1
		end
	end
	COLUMN_DICT[col.szKey] = col
end

-- 移除不在同一个刷新周期内的数据字段
function D.FilterColumnCircle(rec)
	if X.IsNumber(rec.time) then
		for _, col in ipairs(COLUMN_LIST) do
			if col.szRefreshCircle
			and col.szKey:find('serendipity_') == 1 and rec[col.szKey] and rec[col.szKey].count ~= -1 then
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
		PLAYER_REC[col.szKey] = col.GetValue(PLAYER_REC_INITIAL[col.szKey], PLAYER_REC_INITIAL)
	end
	return X.Clone(PLAYER_REC)
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/serendipity_stat.v2.db', X.PATH_TYPE.GLOBAL})
	local DB_V3_PATH = X.FormatPath({'userdata/role_statistics/serendipity_stat.v3.db', X.PATH_TYPE.GLOBAL})
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
					local aInfo = X.ConvertToAnsi(DB_V2:Execute('SELECT * FROM Info WHERE guid IS NOT NULL AND region IS NOT NULL AND name IS NOT NULL'))
					if aInfo then
						for _, rec in ipairs(aInfo) do
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
									time = rec.time,
								}
								local t = X.DecodeLUAData(rec.serendipity_info)
								if X.IsTable(t) then
									for k, v in pairs(t) do
										if X.IsNumber(v) then
											data[rec.guid]['serendipity_' .. k] = {
												count = v,
												extra = 0,
											}
										end
									end
								end
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
					local aInfo = X.ConvertToAnsi(DB_V3:Execute('SELECT * FROM Info WHERE guid IS NOT NULL AND region IS NOT NULL AND name IS NOT NULL'))
					if aInfo then
						for _, rec in ipairs(aInfo) do
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
									time = rec.time,
								}
								local t = X.DecodeLUAData(rec.serendipity_info)
								if X.IsTable(t) then
									for k, v in pairs(t) do
										if X.IsNumber(v) then
											data[rec.guid]['serendipity_' .. k] = {
												count = v,
												extra = 0,
											}
										end
									end
								end
							end
						end
					end
					DB_V3:Release()
				end
				CPath.Move(DB_V3_PATH, DB_V3_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			X.SaveLUAData(STAT_DATA_FILE, data)
			FireUIEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
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
		data[X.GetPlayerGUID()] = rec
		X.SaveLUAData(STAT_DATA_FILE, data)
	end
	X.SaveLUAData(PLAYER_REC_FILE, rec)
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.Debug('MY_RoleStatistics_SerendipityStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.PM_LOG)
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
		X.Debug('MY_RoleStatistics_SerendipityStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local data = X.LoadLUAData(STAT_DATA_FILE) or {}
		data[X.GetPlayerGUID()] = nil
		X.SaveLUAData(STAT_DATA_FILE, data)
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_SerendipityStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
end

function D.GetTableColumns()
	local aColumn = {}
	for _, szKey in ipairs(O.aColumn) do
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
			title = col.szTitle,
			titleTip = col.szTitleTip
				or col.GetTitleTip
				or col.szTitle,
			alignHorizontal = 'center',
			render = col.GetFormatText,
			sorter = col.Compare,
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

function D.UpdateUI(page)
	local ui = X.UI(page)

	local szSearch = ui:Fetch('WndEditBox_Search'):Text()
	local data = D.GetPlayerRecords()
	local result = {}
	for _, rec in pairs(data) do
		if szSearch == ''
		or X.StringFindW(tostring(rec.account or ''), szSearch)
		or X.StringFindW(tostring(rec.name or ''), szSearch)
		or X.StringFindW(tostring(rec.region or ''), szSearch)
		or X.StringFindW(tostring(rec.server or ''), szSearch) then
			table.insert(result, rec)
		end
	end

	ui:Fetch('WndTable_Stat')
		:Columns(D.GetTableColumns())
		:DataSource(result)
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
	local dwMapID = X.GetClientPlayer().GetMapID()
	local tLuckPet = D.GetLuckyFellowPet()
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		local szText, r, g, b = GetSerendipityCounterText(serendipity, rec['serendipity_' .. serendipity.nID])
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
	local ui = X.UI(page)

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
				local function fnAction(szKey, nWidth)
					local bExist = false
					for i, v in ipairs(aColumn) do
						if v == szKey then
							table.remove(aColumn, i)
							O.aColumn = aColumn
							bExist = true
							break
						end
					end
					if not bExist then
						table.insert(aColumn, szKey)
						O.aColumn = aColumn
					end
					UpdateMenu()
					D.FlushDB()
					D.UpdateUI(page)
				end
				local t1 = { szOption = _L['Serendipity'], nMaxHeight = 1000 }
				for _, col in ipairs(COLUMN_LIST) do
					if col.bTable then
						if col.szKey:find('serendipity_') == 1 then -- 奇遇选项
							table.insert(t1, {
								szOption = col.szTitle,
								bCheck = true, bChecked = tChecked[col.szKey],
								fnAction = function()
									fnAction(col.szKey, col.nMinWidth)
								end,
							})
						elseif not tChecked[col.szKey] then -- 普通选项
							table.insert(t, {
								szOption = col.szTitle,
								bCheck = true, bChecked = tChecked[col.szKey],
								fnAction = function()
									fnAction(col.szKey, col.nMinWidth)
								end,
							})
						end
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
			D.UpdateUI(page)
		end)
	end
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

-------------------------------------------------------------------------------------------------------
-- 地图标记
-------------------------------------------------------------------------------------------------------
function D.OnMMMItemMouseEnter()
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local mark = this.data
	local serendipity = mark.nSerendipityID and SERENDIPITY_HASH[mark.nSerendipityID]
	local aXml = {}
	-- 名字
	if mark.dwType and mark.dwID then
		table.insert(aXml, GetFormatText(X.GetTemplateName(mark.dwType, mark.dwID) .. '\n', 162, 255, 255, 0))
	end
	-- 奇遇名称
	if serendipity then
		table.insert(aXml, GetFormatText(serendipity.szName .. _L[' - '], 162, 255, 255, 255))
	end
	-- 奇遇类型
	if mark.szType == 'TRIGGER' then
		table.insert(aXml, GetFormatText(_L['Trigger'] .. '\n', 162, 255, 255, 255))
	elseif mark.szType == 'LOOT' then
		table.insert(aXml, GetFormatText(_L['Loot item'] .. '\n', 162, 255, 255, 255))
	end
	-- 当前统计
	local szState, r, g, b
	if serendipity then
		local col = COLUMN_DICT[serendipity.nID]
		if col then
			local rec = D.GetClientPlayerRec()
			if rec then
				szState, r, g, b = GetSerendipityCounterText(serendipity, rec[serendipity.nID])
			end
		end
	end
	if szState then
		table.insert(aXml, GetFormatText(szState .. '\n', 162, r, g, b))
	end
	-- 调用显示
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
end

function D.OnMMMItemMouseLeave()
	HideTip()
end

function D.GetVisibleMapPoint(dwMapID)
	local aMapPoint = {}
	local player = X.GetClientPlayer()
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
	local player = X.GetClientPlayer()
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
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	for _, mark in ipairs(D.GetVisibleMapPoint(me.GetMapID())) do
		if mark.aPosition then
			for _, pos in ipairs(mark.aPosition) do
				if math.pow((me.nX - pos[1]) / 64, 2) + math.pow((me.nY - pos[2]) / 64, 2) <= MINI_MAP_POINT_MAX_DISTANCE then
					X.UpdateMiniFlag(X.CONSTANT.MINI_MAP_POINT.FUNCTION_NPC,
						pos[1], pos[2], 21, 47, X.ENVIRONMENT.GAME_FPS)
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

--------------------------------------------------------
-- 接口导出
--------------------------------------------------------

function D.GetSerendipityMapID(dwSerendipity)
	local serendipity
	for _, v in ipairs(SERENDIPITY_LIST) do
		if v.dwSerendipity == dwSerendipity then
			serendipity = v
			break
		end
	end
	if serendipity then
		return serendipity.dwMapID
	end
end

function D.GetSerendipityCounter(dwPlayerID, dwSerendipity)
	local rec = dwPlayerID == X.GetClientPlayerID()
		and D.GetClientPlayerRec()
		or D.GetPlayerRecords()[dwPlayerID]
	local serendipity
	for _, v in ipairs(SERENDIPITY_LIST) do
		if v.dwSerendipity == dwSerendipity then
			serendipity = v
			break
		end
	end
	if serendipity then
		return GetSerendipityCounter(serendipity, rec['serendipity_' .. serendipity.nID])
	end
end

function D.GetSerendipityCounterText(dwPlayerID, dwSerendipity)
	local rec = dwPlayerID == X.GetClientPlayerID()
		and D.GetClientPlayerRec()
		or D.GetPlayerRecords()[dwPlayerID]
	local serendipity
	for _, v in ipairs(SERENDIPITY_LIST) do
		if v.dwSerendipity == dwSerendipity then
			serendipity = v
			break
		end
	end
	if serendipity then
		return GetSerendipityCounterText(serendipity, rec['serendipity_' .. serendipity.nID])
	end
end

--------------------------------------------------------------------------------
-- Module exports
--------------------------------------------------------------------------------
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
				tAPI = {
					GetSerendipityMapID = D.GetSerendipityMapID,
					GetSerendipityCounter = D.GetSerendipityCounter,
					GetSerendipityCounterText = D.GetSerendipityCounterText,
				},
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('SerendipityStat', _L['MY_RoleStatistics_SerendipityStat'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_RoleStatistics_SerendipityStat', function()
	D.bReady = true
	D.CheckMapMark()
	D.UpdateFloatEntry()
end)

X.RegisterInit('MY_RoleStatistics_SerendipityStat', function()
	D.bReady = true
	D.UpdateFloatEntry()
end)

X.RegisterExit('MY_RoleStatistics_SerendipityStat', function()
	if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
	end
end)

X.RegisterReload('MY_RoleStatistics_SerendipityStat', function()
	D.UnhookMiniMapMark()
	D.UnhookMapMark()
	D.ApplyFloatEntry(false)
end)

X.RegisterFlush('MY_RoleStatistics_SerendipityStat', function()
	D.FlushDB()
end)

X.RegisterFrameCreate('SprintPower', 'MY_RoleStatistics_SerendipityStat', function()
	D.UpdateFloatEntry()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
