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
local MODULE_NAME = 'MY_RoleStatistics_SerendipityStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local PASSPHRASE = 'gbn9@#4uirae823&^*423otyeaseaw'
if LIB.IsDebugClient('MY_RoleStatistics_SerendipityStat', true) then
	-- 自动生成内置加密数据
	local DAT_ROOT = 'MY_RoleStatistics/data/serendipity/'
	local SRC_ROOT = PACKET_INFO.ROOT .. '!src-dist/dat/' .. DAT_ROOT
	for _, szFile in ipairs(CPath.GetFileList(SRC_ROOT)) do
		LIB.Sysmsg(_L['Encrypt and compressing: '] .. DAT_ROOT .. szFile)
		local data = LoadDataFromFile(SRC_ROOT .. szFile)
		data = EncodeData(data, true, true)
		SaveDataToFile(data, PACKET_INFO.ROOT .. DAT_ROOT .. szFile, PASSPHRASE)
	end
end
local SERENDIPITY_LIST, MAP_POINT_LIST = unpack(LIB.LoadLUAData(PLUGIN_ROOT .. '/data/serendipity/{$lang}.jx3dat', { passphrase = PASSPHRASE }) or {})
if not SERENDIPITY_LIST or not MAP_POINT_LIST then
	return LIB.Sysmsg(_L['MY_RoleStatistics_SerendipityStat'], _L['Cannot load serendipity data!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SERENDIPITY_HASH = {}
for _, v in ipairs(SERENDIPITY_LIST) do
	SERENDIPITY_HASH[v.nID] = v
end

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

local DB = LIB.ConnectDatabase(_L['MY_RoleStatistics_SerendipityStat'], {'userdata/role_statistics/serendipity_stat.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_SerendipityStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_SerendipityStat.ini'
local SZ_TIP_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_SerendipityTip.ini'

DB:Execute('CREATE TABLE IF NOT EXISTS Info (guid NVARCHAR(20), account NVARCHAR(255), region NVARCHAR(20), server NVARCHAR(20), name NVARCHAR(20), force INTEGER, camp INTEGER, level INTEGER, serendipity_info NVARCHAR(65535), item_count NVARCHAR(65535), time INTEGER, PRIMARY KEY(guid))')
local InfoW = DB:Prepare('REPLACE INTO Info (guid, account, region, server, name, force, camp, level, serendipity_info, item_count, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local InfoG = DB:Prepare('SELECT * FROM Info WHERE guid = ?')
local InfoR = DB:Prepare('SELECT * FROM Info WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local InfoD = DB:Prepare('DELETE FROM Info WHERE guid = ?')

local D = {}
local O = {
	aColumn = {
		'name',
		'force',
		1, 2, 3, 4, 5, 6, 7, 8, 9,
		'time_days',
	},
	szSort = 'time_days',
	szSortOrder = 'desc',
	bFloatEntry = false,
}
RegisterCustomData('Global/MY_RoleStatistics_SerendipityStat.aColumn')
RegisterCustomData('Global/MY_RoleStatistics_SerendipityStat.szSort')
RegisterCustomData('Global/MY_RoleStatistics_SerendipityStat.szSortOrder')
RegisterCustomData('MY_RoleStatistics_SerendipityStat.bFloatEntry')

-----------------------------------------------------------------------------------------------
-- 多个渠道奇遇次数监控
-----------------------------------------------------------------------------------------------
local SERENDIPITY_COUNTER = {}
local REGISTER_EVENT, REGISTER_MSG = {}, {}

local function RegisterEvent(szID, ...)
	REGISTER_EVENT[szID] = true
	return LIB.RegisterEvent(szID, ...)
end

local function RegisterMsgMonitor(szID, ...)
	REGISTER_MSG[szID] = true
	return LIB.RegisterMsgMonitor(szID, ...)
end

LIB.RegisterEvent('LOADING_ENDING.MY_RoleStatistics_SerendipityStat', function()
	for k, _ in pairs(REGISTER_EVENT) do
		LIB.RegisterEvent(k, false)
	end
	for k, _ in pairs(REGISTER_MSG) do
		LIB.RegisterMsgMonitor(k, false)
	end
	local function DelayTrigger()
		FireUIEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
	end
	local function OnSerendipityTrigger()
		LIB.DelayCall('MY_ROLE_STAT_SERENDIPITY_UPDATE', DelayTrigger)
	end
	local PARSE_TEXT = setmetatable({}, {__index = function(t, k)
		t[k] = wgsub(k, '{$name}', GetClientPlayer().szName)
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
				RegisterEvent('BUFF_UPDATE.MY_RoleStatistics_SerendipityStat_AttemptBuff' .. serendipity.nID, function()
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
				RegisterEvent('OPEN_WINDOW.MY_RoleStatistics_SerendipityStat_RejectOpenWindow' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aRejectOpenWindow, serendipity.nID, serendipity.nMaxAttemptNum)
				end)
			end
			if serendipity.aRejectWarningMessage then
				RegisterEvent('ON_WARNING_MESSAGE.MY_RoleStatistics_SerendipityStat_RejectWarningMessage' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aRejectWarningMessage, serendipity.nID, serendipity.nMaxAttemptNum)
				end)
			end
			if serendipity.aRejectNpcSayTo then
				RegisterMsgMonitor('MY_RoleStatistics_SerendipityStat_RejectNpcSayTo' .. serendipity.nID, function(szMsg, nFont, bRich)
					if bRich then
						szMsg = GetPureText(szMsg)
					end
					SerendipityStringTrigger(szMsg, serendipity.aRejectNpcSayTo, serendipity.nID, serendipity.nMaxAttemptNum)
				end, { "MSG_NPC_NEARBY" })
			end
			-- 尝试一次的判断们
			if serendipity.aAttemptOpenWindow then
				RegisterEvent('OPEN_WINDOW.MY_RoleStatistics_SerendipityStat_AttemptOpenWindow' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aAttemptOpenWindow, serendipity.nID)
				end)
			end
			if serendipity.aAttemptNpcSayTo then
				RegisterMsgMonitor('MY_RoleStatistics_SerendipityStat_AttemptNpcSayTo' .. serendipity.nID, function(szMsg, nFont, bRich)
					if bRich then
						szMsg = GetPureText(szMsg)
					end
					SerendipityStringTrigger(szMsg, serendipity.aAttemptNpcSayTo, serendipity.nID)
				end, { "MSG_NPC_NEARBY" })
			end
			if serendipity.aAttemptLootItem then
				RegisterEvent('LOOT_ITEM.MY_RoleStatistics_SerendipityStat_AttemptLootItem' .. serendipity.nID, function()
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
				RegisterEvent('BAG_ITEM_UPDATE.MY_RoleStatistics_SerendipityStat_AttemptItem' .. serendipity.nID, function()
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
				RegisterEvent('OPEN_WINDOW.MY_RoleStatistics_SerendipityStat_FailureOpenWindow' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aFailureOpenWindow, serendipity.nID)
				end)
			end
			if serendipity.aFailureNpcSayTo then
				RegisterMsgMonitor('MY_RoleStatistics_SerendipityStat_FailureNpcSayTo' .. serendipity.nID, function(szMsg, nFont, bRich)
					if bRich then
						szMsg = GetPureText(szMsg)
					end
					SerendipityStringTrigger(szMsg, serendipity.aFailureNpcSayTo, serendipity.nID)
				end, { "MSG_NPC_NEARBY" })
			end
			if serendipity.aFailureWarningMessage then
				RegisterEvent('ON_WARNING_MESSAGE.MY_RoleStatistics_SerendipityStat_FailureWarningMessage' .. serendipity.nID, function()
					SerendipityStringTrigger(arg1, serendipity.aFailureWarningMessage, serendipity.nID)
				end)
			end
			if serendipity.aFailureLootItem then
				RegisterEvent('LOOT_ITEM.MY_RoleStatistics_SerendipityStat_FailureLootItem' .. serendipity.nID, function()
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
	local nNextTime, nCircle = LIB.GetRefreshTime('daily')
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
			if LIB.GetItemAmountInAllPackages(v[1], v[2]) > 0 then
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
		local buff = LIB.GetBuff(me, tab.dwBuffID, 0)
		if buff then
			return buff.nStackNum
		end
		return 0
	end
end

local EXCEL_WIDTH = 960
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
			return GetFormatText(name, 162, LIB.GetForceColor(rec.force, 'foreground'))
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
			return GetFormatText(LIB.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
	{ -- 时间计时
		id = 'time_days',
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

local COLUMN_DICT = setmetatable({}, { __index = function(t, id)
	local serendipity = SERENDIPITY_HASH[id]
	if serendipity then
		local col = { -- 副本CD
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
				insert(aTitleTipXml, GetFormatText('<' .. serendipity.szNick .. '>\n', 162, 255, 255, 255))
			end
			if serendipity.dwMapID then
				local map = LIB.GetMapInfo(serendipity.dwMapID)
				if map then
					insert(aTitleTipXml, GetFormatText('(' .. map.szName .. ')\n', 162, 255, 255, 255))
				end
			end
			return concat(aTitleTipXml)
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
						nCount = (nCount or 0) - Get(rec.item_count, v, 0)
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

function D.FlushDB()
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_SerendipityStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
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
	local tSerendipityInfo = {}
	local tItemCount = {}

	-- 如果在同一个CD周期 则保留数据库中的次数统计
	InfoG:ClearBindings()
	InfoG:BindAll(guid)
	local result = InfoG:GetAll()
	if result and result[1] and IsInSamePeriod(result[1].time) then
		tSerendipityInfo = DecodeLUAData(result[1].serendipity_info) or tSerendipityInfo
		tItemCount = DecodeLUAData(result[1].item_count) or tItemCount
	end

	-- 统计可信的次数
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		local nDailyCount = GetSerendipityDailyCount(me, serendipity)
		if nDailyCount then
			tSerendipityInfo[serendipity.nID] = nDailyCount
		end
		if serendipity.aAttemptItem then
			for _, v in ipairs(serendipity.aAttemptItem) do
				if not tItemCount[v[1]] then
					tItemCount[v[1]] = {}
				end
				tItemCount[v[1]][v[2]] = LIB.GetItemAmountInAllPackages(v[1], v[2])
				if IsEmpty(tItemCount[v[1]][v[2]]) then
					tItemCount[v[1]][v[2]] = nil
				end
				if IsEmpty(tItemCount[v[1]]) then
					tItemCount[v[1]] = nil
				end
			end
		end
		if SERENDIPITY_COUNTER[serendipity.nID] then
			tSerendipityInfo[serendipity.nID] = min((tSerendipityInfo[serendipity.nID] or 0) + SERENDIPITY_COUNTER[serendipity.nID], serendipity.nMaxAttemptNum)
		end
		SERENDIPITY_COUNTER[serendipity.nID] = nil
	end
	local serendipity_info = EncodeLUAData(tSerendipityInfo)
	local item_count = EncodeLUAData(tItemCount)

	DB:Execute('BEGIN TRANSACTION')

	InfoW:ClearBindings()
	InfoW:BindAll(guid, account, region, server, name, force, camp, level, serendipity_info, item_count, time)
	InfoW:Execute()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_SerendipityStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_SerendipityStat', D.FlushDB)

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
	local hCols = page:Lookup('Wnd_Total/WndScroll_SerendipityStat', 'Handle_SerendipityStatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetColumns(), 0, nil
	local nExtraWidth = EXCEL_WIDTH
	for i, col in ipairs(aCol) do
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_SerendipityStatColumn')
		local txt = hCol:Lookup('Text_SerendipityStat_Title')
		local imgAsc = hCol:Lookup('Image_SerendipityStat_Asc')
		local imgDesc = hCol:Lookup('Image_SerendipityStat_Desc')
		local nWidth = i == #aCol
			and (EXCEL_WIDTH - nX)
			or min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or HUGE)
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_SerendipityStat_Break'):Hide()
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
	InfoR:ClearBindings()
	InfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = InfoR:GetAll()

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
	local hList = page:Lookup('Wnd_Total/WndScroll_SerendipityStat', 'Handle_List')
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

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
	rec.serendipity_info = DecodeLUAData(rec.serendipity_info or '') or {}
	rec.item_count = DecodeLUAData(rec.item_count or '') or {}
end

function D.OutputRowTip(this, rec)
	local frame = Wnd.OpenWindow(SZ_TIP_INI, 'MY_RoleStatistics_SerendipityTip')
	local hList = frame:Lookup('', 'Handle_List')
	hList:Clear()
	hList:AppendItemFromIni(SZ_TIP_INI, 'Handle_Title'):Lookup('Text_Title'):SetText(
		rec.region .. ' ' .. rec.server .. ' - ' .. rec.name
		.. ' (' .. g_tStrings.tForceTitle[rec.force] .. ' ' .. rec.level .. g_tStrings.STR_LEVEL .. ')')
	local dwMapID = GetClientPlayer().GetMapID()
	local tLuckPet = D.GetLuckyFellowPet()
	for _, serendipity in ipairs(SERENDIPITY_LIST) do
		local col = COLUMN_DICT[serendipity.nID]
		local hItem = hList:AppendItemFromIni(SZ_TIP_INI, 'Handle_Item')
		local szName = serendipity.szName
		if serendipity.szNick then
			szName = szName .. '<' .. serendipity.szNick .. '>'
		end
		hItem:Lookup('Image_Lucky'):SetVisible(serendipity.dwPet and tLuckPet[serendipity.dwPet] or false)
		hItem:Lookup('Text_Name'):SetText(szName)
		hItem:Lookup('Text_Name'):SetFontColor(255, 255, 128)
		hItem:Lookup('Text_Name').OnItemLButtonClick = function()
			if serendipity.dwAchieve then
				MY_Web.Open('https://j3cx.com/wiki/' .. serendipity.dwAchieve, { w = 850, h = 610 })
				Wnd.CloseWindow(frame)
			end
		end
		hItem:Lookup('Text_Name'):RegisterEvent(16)
		local map = serendipity.dwMapID and LIB.GetMapInfo(serendipity.dwMapID)
		hItem:Lookup('Text_Map'):SetText(map and map.szName or '')
		if dwMapID == serendipity.dwMapID then
			hItem:Lookup('Text_Map'):SetFontColor(168, 240, 240)
		else
			hItem:Lookup('Text_Map'):SetFontColor(192, 192, 192)
		end
		local szText, r, g, b = col.GetText(rec)
		hItem:Lookup('Text_State'):SetText(szText)
		hItem:Lookup('Text_State'):SetFontColor(r, g, b)
	end
	hList:FormatAllItemPos()
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
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_SerendipityStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(page, true, true)
	Wnd.CloseWindow(frameTemp)

	UI(wnd):Append('WndCheckBox', {
		x = 670, y = 21, w = 180,
		text = _L['Float panel'],
		checked = MY_RoleStatistics_SerendipityStat.bFloatEntry,
		oncheck = function()
			MY_RoleStatistics_SerendipityStat.bFloatEntry = not MY_RoleStatistics_SerendipityStat.bFloatEntry
		end,
	})

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
			-- 奇遇选项
			local t1 = { szOption = _L['Serendipity'], nMaxHeight = 1000 }
			for _, serendipity in ipairs(SERENDIPITY_LIST) do
				if not tChecked[serendipity.nID] then
					local col = COLUMN_DICT[serendipity.nID]
					if col then
						insert(t1, {
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
			insert(t, t1)
			return t
		end,
	})

	UI(wnd):Append('WndButton', {
		x = 440, y = 590, w = 120,
		text = _L['Refresh'],
		onclick = function()
			D.FlushDB()
			D.UpdateUI(page)
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_SERENDIPITY_UPDATE')
end

function D.OnActivePage()
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
		LIB.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			InfoD:ClearBindings()
			InfoD:BindAll(wnd.guid)
			InfoD:Execute()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_SerendipityStatColumn' then
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
					InfoD:ClearBindings()
					InfoD:BindAll(rec.guid)
					InfoD:Execute()
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
	elseif name == 'Handle_SerendipityStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = this.col.GetTitleFormatTip
			and this.col.GetTitleFormatTip()
			or GetFormatText(this:Lookup('Text_SerendipityStat_Title'):GetText(), 162, 255, 255, 255)
		OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
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

-------------------------------------------------------------------------------------------------------
-- 浮动框
-------------------------------------------------------------------------------------------------------
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/SprintPower')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_SerendipityEntry')
	if IsNil(bFloatEntry) then
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
			local me = GetClientPlayer()
			if not me then
				return
			end
			D.FlushDB()
			InfoG:ClearBindings()
			InfoG:BindAll(me.GetGlobalID() or me.szName)
			local result = InfoG:GetAll()
			local rec = result[1]
			if not rec then
				return
			end
			D.DecodeRow(rec)
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
	D.ApplyFloatEntry(O.bFloatEntry)
end
LIB.RegisterInit('MY_RoleStatistics_SerendipityEntry', D.UpdateFloatEntry)
LIB.RegisterReload('MY_RoleStatistics_SerendipityEntry', function() D.ApplyFloatEntry(false) end)
LIB.RegisterFrameCreate('SprintPower.MY_RoleStatistics_SerendipityEntry', D.UpdateFloatEntry)

-------------------------------------------------------------------------------------------------------
-- 地图标记
-------------------------------------------------------------------------------------------------------
function D.OnMMMItemMouseEnter()
	local mark = this.data
	local aXml = {}
	if mark.dwType and mark.dwID then
		insert(aXml, GetFormatText(LIB.GetTemplateName(mark.dwType, mark.dwID) .. '\n', 162, 255, 255, 0))
	end
	if mark.nSerendipityID then
		local serendipity = SERENDIPITY_HASH[mark.nSerendipityID]
		if serendipity then
			insert(aXml, GetFormatText(serendipity.szName .. _L[' - '], 162, 255, 255, 255))
		end
	end
	if mark.szType == 'TRIGGER' then
		insert(aXml, GetFormatText(_L['Trigger'], 162, 255, 255, 255))
	elseif mark.szType == 'LOOT' then
		insert(aXml, GetFormatText(_L['Loot item'], 162, 255, 255, 255))
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
end

function D.OnMMMItemMouseLeave()
	HideTip()
end

function D.DrawMapMark()
	local frame = Station.Lookup('Topmost1/MiddleMap')
	local player = GetClientPlayer()
	if not player or not frame or not frame:IsVisible() then
		return
	end
	local dwMapID = MiddleMap.dwMapID or player.GetMapID()
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

	for _, mark in ipairs(MAP_POINT_LIST) do
		if mark.dwMapID == dwMapID and mark.aPosition then
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

function D.HookMapMark()
	HookTableFunc(MiddleMap, 'ShowMap', D.DrawMapMark, { bAfterOrigin = true })
	HookTableFunc(MiddleMap, 'UpdateCurrentMap', D.DrawMapMark, { bAfterOrigin = true })
end
LIB.RegisterInit('MY_RoleStatistics_SerendipityMapMark', D.HookMapMark)

function D.UnhookMapMark()
	local h = Station.Lookup('Topmost1/MiddleMap', 'Handle_Inner/Handle_MY_SerendipityMMM')
	if h then
		h:GetParent():RemoveItem(h)
	end
	UnhookTableFunc(MiddleMap, 'ShowMap', D.DrawMapMark)
	UnhookTableFunc(MiddleMap, 'UpdateCurrentMap', D.DrawMapMark)
end
LIB.RegisterReload('MY_RoleStatistics_SerendipityMapMark', D.UnhookMapMark)

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
MY_RoleStatistics.RegisterModule('SerendipityStat', _L['MY_RoleStatistics_SerendipityStat'], LIB.GeneGlobalNS(settings))
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
			},
			triggers = {
				bFloatEntry = D.UpdateFloatEntry,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_SerendipityStat = LIB.GeneGlobalNS(settings)
end
