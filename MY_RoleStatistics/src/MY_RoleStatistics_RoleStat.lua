--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色统计
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
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_RoleStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

local DB = LIB.ConnectDatabase(_L['MY_RoleStatistics_RoleStat'], {'userdata/role_statistics/role_stat.v2.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_RoleStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_RoleStat.ini'

DB:Execute('CREATE TABLE IF NOT EXISTS RoleInfo (guid NVARCHAR(20), account NVARCHAR(255), region NVARCHAR(20), server NVARCHAR(20), name NVARCHAR(20), force INTEGER, level INTEGER, equip_score INTEGER, pet_score INTEGER, gold INTEGER, silver INTEGER, copper INTEGER, contribution INTEGER, contribution_remain INTEGER, justice INTEGER, justice_remain INTEGER, prestige INTEGER, prestige_remain INTEGER, camp_point INTEGER, camp_point_percentage INTEGER, camp_level INTEGER, arena_award INTEGER, arena_award_remain INTEGER, exam_print INTEGER, exam_print_remain INTEGER, achievement_score INTEGER, coin INTEGER, mentor_score INTEGER, time INTEGER, PRIMARY KEY(guid))')
DB:Execute('ALTER TABLE RoleInfo ADD COLUMN starve INTEGER')
DB:Execute('ALTER TABLE RoleInfo ADD COLUMN starve_remain INTEGER')
DB:Execute('ALTER TABLE RoleInfo ADD COLUMN architecture INTEGER')
DB:Execute('ALTER TABLE RoleInfo ADD COLUMN architecture_remain INTEGER')
local DB_RoleInfoW = DB:Prepare('REPLACE INTO RoleInfo (guid, account, region, server, name, force, level, equip_score, pet_score, gold, silver, copper, contribution, contribution_remain, justice, justice_remain, prestige, prestige_remain, camp_point, camp_point_percentage, camp_level, arena_award, arena_award_remain, exam_print, exam_print_remain, achievement_score, coin, mentor_score, starve, starve_remain, architecture, architecture_remain, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_RoleInfoCoinW = DB:Prepare('UPDATE RoleInfo SET coin = ? WHERE account = ? AND region = ?')
local DB_RoleInfoG = DB:Prepare('SELECT * FROM RoleInfo WHERE guid = ?')
local DB_RoleInfoR = DB:Prepare('SELECT * FROM RoleInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_RoleInfoD = DB:Prepare('DELETE FROM RoleInfo WHERE guid = ?')

local D = {}
local O = {
	aColumn = {
		'name',
		'force',
		'level',
		'achievement_score',
		'pet_score',
		'justice',
		'justice_remain',
		'exam_print',
		'coin',
		'money',
		'time_days',
	},
	szSort = 'time_days',
	szSortOrder = 'desc',
	aAlertColumn = {
		'money',
		'achievement_score',
		'pet_score',
		'contribution',
		'justice',
		'starve',
		'prestige',
		'camp_point',
		'arena_award',
		'exam_print',
	},
	tAlertTodayVal = nil,
	dwLastAlertTime = 0,
	tSummaryIgnoreGUID = {},
	bFloatEntry = false,
	bAdviceFloatEntry = false,
	bSaveDB = false,
	bAdviceSaveDB = false,
}
RegisterCustomData('Global/MY_RoleStatistics_RoleStat.aColumn')
RegisterCustomData('Global/MY_RoleStatistics_RoleStat.szSort')
RegisterCustomData('Global/MY_RoleStatistics_RoleStat.szSortOrder')
RegisterCustomData('MY_RoleStatistics_RoleStat.aAlertColumn')
RegisterCustomData('MY_RoleStatistics_RoleStat.tAlertTodayVal')
RegisterCustomData('MY_RoleStatistics_RoleStat.tSummaryIgnoreGUID')
RegisterCustomData('MY_RoleStatistics_RoleStat.bFloatEntry')
RegisterCustomData('MY_RoleStatistics_RoleStat.bAdviceFloatEntry')
RegisterCustomData('MY_RoleStatistics_RoleStat.bSaveDB')
RegisterCustomData('MY_RoleStatistics_RoleStat.bAdviceSaveDB')

local function GetFormatSysmsgText(szText)
	return GetFormatText(szText, GetMsgFont('MSG_SYS'), GetMsgFontColor('MSG_SYS'))
end

local function GeneCommonFormatText(id)
	return function(r)
		return GetFormatText(r[id], 162, 255, 255, 255)
	end
end
local function GeneCommonSummaryFormatText(id)
	return function(rs)
		local v = 0
		for _, r in ipairs(rs) do
			if IsNumber(r[id]) then
				v = v + r[id]
			end
		end
		return GetFormatText(v, 162, 255, 255, 255)
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
local function GeneWeeklyFormatText(id)
	return function(r)
		local nNextTime, nCircle = LIB.GetRefreshTime('weekly')
		local szText = (nNextTime - nCircle < r.time and r[id] and r[id] >= 0)
			and r[id]
			or _L['--']
		return GetFormatText(szText, 162, 255, 255, 255)
	end
end
local function GeneWeeklySummaryFormatText(id)
	return function(rs)
		local nNextTime, nCircle = LIB.GetRefreshTime('weekly')
		local v = nil
		for _, r in ipairs(rs) do
			if nNextTime - nCircle < r.time and IsNumber(r[id]) and r[id] >= 0 then
				if not v then
					v = 0
				end
				v = v + r[id]
			end
		end
		return GetFormatText(v or '--', 162, 255, 255, 255)
	end
end
local function GeneWeeklyCompare(id)
	return function(r1, r2)
		local nNextTime, nCircle = LIB.GetRefreshTime('weekly')
		local v1 = nNextTime - nCircle < r1.time
			and r1[id]
			or -1
		local v2 = nNextTime - nCircle < r2.time
			and r2[id]
			or -1
		if v1 == v2 then
			return 0
		end
		return v1 > v2 and 1 or -1
	end
end
local COLUMN_LIST = {
	-- guid,
	-- account,
	{ -- 大区
		id = 'region',
		bHideInFloat = true,
		szTitle = _L['Region'],
		nWidth = 100,
		GetFormatText = GeneCommonFormatText('region'),
		Compare = GeneCommonCompare('region'),
	},
	{ -- 服务器
		id = 'server',
		bHideInFloat = true,
		szTitle = _L['Server'],
		nWidth = 100,
		GetFormatText = GeneCommonFormatText('server'),
		Compare = GeneCommonCompare('server'),
	},
	{ -- 名字
		id = 'name',
		bHideInFloat = true,
		szTitle = _L['Name'],
		nWidth = 130,
		GetFormatText = function(rec)
			local name = rec.name
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name, nil, LIB.GetForceColor(rec.force, 'foreground'))
		end,
		GetSummaryFormatText = function()
			return GetFormatText(_L['Summary'], nil, 255, 255, 0)
		end,
	},
	{ -- 门派
		id = 'force',
		bHideInFloat = true,
		szTitle = _L['Force'],
		nWidth = 50,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.tForceTitle[rec.force], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('force'),
	},
	{ -- 等级
		id = 'level',
		bHideInFloat = true,
		szTitle = _L['Level'],
		nWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- 装分
		id = 'equip_score',
		bHideInFloat = true,
		szTitle = _L['Equip score'],
		szShortTitle = _L['EquSC'],
		nWidth = 60,
		GetFormatText = GeneCommonFormatText('equip_score'),
		Compare = GeneCommonCompare('equip_score'),
	},
	{ -- 宠物分
		id = 'pet_score',
		bHideInFloat = true,
		szTitle = _L['PetSC'],
		nWidth = 55,
		GetFormatText = GeneCommonFormatText('pet_score'),
		Compare = GeneCommonCompare('pet_score'),
	},
	{ -- 金钱
		id = 'money',
		szTitle = _L['Money'],
		nWidth = 200,
		GetFormatText = function(rec)
			return GetMoneyText({ nGold = rec.gold, nSilver = rec.silver, nCopper = rec.copper }, 105)
		end,
		Compare = function(r1, r2)
			if r1.gold == r2.gold then
				if r1.silver == r2.silver then
					if r1.copper == r2.copper then
						return 0
					end
					return r1.copper > r2.copper and 1 or -1
				end
				return r1.silver > r2.silver and 1 or -1
			end
			return r1.gold > r2.gold and 1 or -1
		end,
		GetSummaryFormatText = function(recs)
			local tMoney = { nGold = 0, nSilver = 0, nCopper = 0 }
			for _, rec in ipairs(recs) do
				tMoney = MoneyOptAdd(tMoney, { nGold = rec.gold, nSilver = rec.silver, nCopper = rec.copper })
			end
			return GetMoneyText(tMoney, 105)
		end,
	},
	{ -- 江贡
		id = 'contribution',
		szTitle = _L['Contribution'],
		szShortTitle = _L['Contri'],
		nWidth = 70,
		GetFormatText = GeneCommonFormatText('contribution'),
		Compare = GeneCommonCompare('contribution'),
	},
	{ -- 江贡周余
		id = 'contribution_remain',
		szTitle = _L['Contribution remain'],
		szShortTitle = _L['Contri_remain'],
		nWidth = 70,
		GetFormatText = GeneWeeklyFormatText('contribution_remain'),
		Compare = GeneWeeklyCompare('contribution_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('contribution_remain'),
	},
	{ -- 侠义
		id = 'justice',
		szTitle = _L['Justice'],
		szShortTitle = _L['Justi'],
		nWidth = 60,
		GetFormatText = GeneCommonFormatText('justice'),
		Compare = GeneCommonCompare('justice'),
	},
	{ -- 侠义周余
		id = 'justice_remain',
		szTitle = _L['Justice remain'],
		szShortTitle = _L['Justi_remain'],
		nWidth = 60,
		GetFormatText = GeneWeeklyFormatText('justice_remain'),
		Compare = GeneWeeklyCompare('justice_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('justice_remain'),
	},
	{ -- 浪客笺
		id = 'starve',
		szTitle = _L['Starve'],
		nWidth = 60,
		GetFormatText = GeneWeeklyFormatText('starve'),
		Compare = GeneWeeklyCompare('starve'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('starve'),
	},
	{ -- 浪客笺周余
		id = 'starve_remain',
		szTitle = _L['Starve remain'],
		szShortTitle = _L['Starv_remain'],
		nWidth = 60,
		GetFormatText = GeneWeeklyFormatText('starve_remain'),
		Compare = GeneWeeklyCompare('starve_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('starve_remain'),
	},
	{ -- 园宅币
		id = 'architecture',
		szTitle = _L['Architecture'],
		nWidth = 60,
		GetFormatText = GeneWeeklyFormatText('architecture'),
		Compare = GeneWeeklyCompare('architecture'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('architecture'),
	},
	{ -- 园宅币周余
		id = 'architecture_remain',
		szTitle = _L['Architecture remain'],
		szShortTitle = _L['Arch_remain'],
		nWidth = 60,
		GetFormatText = GeneWeeklyFormatText('architecture_remain'),
		Compare = GeneWeeklyCompare('architecture_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('architecture_remain'),
	},
	{
		-- 威望
		id = 'prestige',
		szTitle = _L['Prestige'],
		szShortTitle = _L['Presti'],
		nWidth = 70,
		GetFormatText = GeneCommonFormatText('prestige'),
		Compare = GeneCommonCompare('prestige'),
	},
	{ -- 威望周余
		id = 'prestige_remain',
		szTitle = _L['Prestige remain'],
		szShortTitle = _L['Presti_remain'],
		nWidth = 70,
		GetFormatText = GeneWeeklyFormatText('prestige_remain'),
		Compare = GeneWeeklyCompare('prestige_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('prestige_remain'),
	},
	{
		-- 战阶积分
		id = 'camp_point',
		szTitle = _L['Camp point'],
		nWidth = 70,
		GetFormatText = GeneWeeklyFormatText('camp_point'),
		Compare = GeneWeeklyCompare('camp_point'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('camp_point'),
	},
	{
		-- 战阶等级
		id = 'camp_level',
		szTitle = _L['Camp level'],
		nWidth = 70,
		GetFormatText = function(rec)
			return GetFormatText(rec.camp_level .. ' + ' .. rec.camp_point_percentage .. '%', 162, 255, 255, 255)
		end,
		Compare = function(r1, r2)
			if r1.camp_level == r2.camp_level then
				if r1.camp_point_percentage == r2.camp_point_percentage then
					return 0
				end
				return r1.camp_point_percentage > r2.camp_point_percentage and 1 or -1
			end
			return r1.camp_level > r2.camp_level and 1 or -1
		end,
	},
	{
		-- 名剑币
		id = 'arena_award',
		szTitle = _L['Arena award'],
		nWidth = 60,
		GetFormatText = GeneCommonFormatText('arena_award'),
		Compare = GeneCommonCompare('arena_award'),
	},
	{
		-- 名剑币周余
		id = 'arena_award_remain',
		szTitle = _L['Arena award remain'],
		szShortTitle = _L['Aren awa remain'],
		nWidth = 60,
		GetFormatText = GeneWeeklyFormatText('arena_award_remain'),
		Compare = GeneWeeklyCompare('arena_award_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('arena_award_remain'),
	},
	{
		-- 监本
		id = 'exam_print',
		szTitle = _L['Exam print'],
		szShortTitle = _L['ExamPt'],
		nWidth = 55,
		GetFormatText = GeneCommonFormatText('exam_print'),
		Compare = GeneCommonCompare('exam_print'),
		GetSummaryFormatText = GeneCommonSummaryFormatText('exam_print'),
	},
	{
		-- 监本周余
		id = 'exam_print_remain',
		szTitle = _L['Exam print remain'],
		szShortTitle = _L['ExamPt_remain'],
		nWidth = 55,
		GetFormatText = GeneWeeklyFormatText('exam_print_remain'),
		Compare = GeneWeeklyCompare('exam_print_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('exam_print_remain'),
	},
	{
		-- 资历
		id = 'achievement_score',
		bHideInFloat = true,
		szTitle = _L['Achievement score'],
		szShortTitle = _L['AchiSC'],
		nWidth = 70,
		GetFormatText = GeneCommonFormatText('achievement_score'),
		Compare = GeneCommonCompare('achievement_score'),
	},
	{
		-- 通宝
		id = 'coin',
		bHideInFloat = true,
		szTitle = _L['Coin'],
		nWidth = 70,
		GetFormatText = GeneCommonFormatText('coin'),
		Compare = GeneCommonCompare('coin'),
		GetSummaryFormatText = function(recs)
			local tAccount, nCoin = {}, 0
			for _, rec in ipairs(recs) do
				if not tAccount[rec.account] and IsNumber(rec.coin) then
					nCoin = nCoin + rec.coin
					tAccount[rec.account] = true
				end
			end
			return GetFormatText(nCoin)
		end,
	},
	{
		-- 师徒分
		id = 'mentor_score',
		bHideInFloat = true,
		szTitle = _L['Mentor score'],
		nWidth = 70,
		GetFormatText = GeneCommonFormatText('mentor_score'),
		Compare = GeneCommonCompare('mentor_score'),
	},
	{
		-- 时间
		id = 'time',
		bHideInFloat = true,
		szTitle = _L['Cache time'],
		nWidth = 165,
		GetFormatText = function(rec)
			return GetFormatText(LIB.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
	{
		-- 时间计时
		id = 'time_days',
		bHideInFloat = true,
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
local COLUMN_DICT = {}
for _, p in ipairs(COLUMN_LIST) do
	if not p.Compare then
		p.Compare = function(r1, r2)
			if r1[p.szKey] == r2[p.szKey] then
				return 0
			end
			return r1[p.szKey] > r2[p.szKey] and 1 or -1
		end
	end
	COLUMN_DICT[p.id] = p
end
local EXCEL_WIDTH = 960

-- 小退提示
local function GeneCommonCompareText(id, szTitle)
	return function(r1, r2)
		if r1[id] == r2[id] then
			return
		end
		local szOp = r1[id] <= r2[id]
			and ' increased by %s'
			or ' decreased by %s'
		return GetFormatSysmsgText(_L(szTitle .. szOp, abs(r2[id] - r1[id])))
	end
end
local ALERT_COLUMN = {
	{ -- 装分
		id = 'equip_score',
		szTitle = _L['Equip score'],
		GetValue = function(me)
			return me.GetBaseEquipScore() + me.GetStrengthEquipScore() + me.GetMountsEquipScore()
		end,
		GetCompareText = GeneCommonCompareText('equip_score', 'Equip score'),
	},
	{ -- 宠物分
		id = 'pet_score',
		szTitle = _L['Pet score'],
		GetValue = function(me)
			return me.GetAcquiredFellowPetScore() + me.GetAcquiredFellowPetMedalScore()
		end,
		GetCompareText = GeneCommonCompareText('pet_score', 'Pet score'),
	},
	{ -- 金钱
		id = 'money',
		szTitle = _L['Money'],
		nWidth = 200,
		GetValue = function(me)
			return me.GetMoney()
		end,
		GetCompareText = function(r1, r2)
			local money = MoneyOptSub(r2.money, r1.money)
			local nCompare = MoneyOptCmp(money, 0)
			if nCompare == 0 then
				return
			end
			local f = GetMsgFont('MSG_SYS')
			local r, g, b = GetMsgFontColor('MSG_SYS')
			local szExtra = 'font=' .. f .. ' r=' .. r .. ' g=' .. g .. ' b=' .. b
			return GetFormatSysmsgText(nCompare >= 0 and _L['Money increased by '] or _L['Money decreased by '])
				.. GetMoneyText({ nGold = abs(money.nGold), nSilver = abs(money.nSilver), nCopper = abs(money.nCopper) }, szExtra)
		end,
	},
	{ -- 江贡
		id = 'contribution',
		szTitle = _L['Contribution'],
		GetValue = function(me)
			return me.nContribution
		end,
		GetCompareText = GeneCommonCompareText('contribution', 'Contribution'),
	},
	{ -- 侠义
		id = 'justice',
		szTitle = _L['Justice'],
		GetValue = function(me)
			return me.nJustice
		end,
		GetCompareText = GeneCommonCompareText('justice', 'Justice'),
	},
	{ -- 浪客笺
		id = 'starve',
		szTitle = _L['Starve'],
		GetValue = function(me)
			return LIB.GetItemAmountInAllPackages(5, 34797, true)
		end,
		GetCompareText = GeneCommonCompareText('starve', 'Starve'),
	},
	{
		-- 威望
		id = 'prestige',
		szTitle = _L['Prestige'],
		GetValue = function(me)
			return me.nCurrentPrestige
		end,
		GetCompareText = GeneCommonCompareText('prestige', 'Prestige'),
	},
	{
		-- 战阶积分
		id = 'camp_point',
		szTitle = _L['Camp point'],
		GetValue = function(me)
			return me.nTitlePoint
		end,
		GetCompareText = GeneCommonCompareText('camp_point', 'Camp point'),
	},
	{
		-- 名剑币
		id = 'arena_award',
		szTitle = _L['Arena award'],
		GetValue = function(me)
			return me.nArenaAward
		end,
		GetCompareText = GeneCommonCompareText('arena_award', 'Arena award'),
	},
	{
		-- 监本
		id = 'exam_print',
		szTitle = _L['Exam print'],
		GetValue = function(me)
			return me.nExamPrint
		end,
		GetCompareText = GeneCommonCompareText('exam_print', 'Exam print'),
	},
	{
		-- 资历
		id = 'achievement_score',
		szTitle = _L['Achievement score'],
		GetValue = function(me)
			return me.GetAchievementRecord()
		end,
		GetCompareText = GeneCommonCompareText('achievement_score', 'Achievement score'),
	},
	{
		-- 师徒分
		id = 'mentor_score',
		szTitle = _L['Mentor score'],
		GetValue = function(me)
			return me.dwTAEquipsScore
		end,
		GetCompareText = GeneCommonCompareText('mentor_score', 'Mentor score'),
	},
}
local ALERT_COLUMN_DICT = {}
for _, p in ipairs(ALERT_COLUMN) do
	ALERT_COLUMN_DICT[p.id] = p
end

do
local INFO_CACHE = {}
LIB.RegisterFrameCreate('regionPQreward.MY_RoleStatistics_RoleStat', function()
	local frame = arg0
	if not frame then
		return
	end
	local txt = frame:Lookup('', 'Text_discrible')
	txt.__SetText = txt.SetText
	txt.SetText = function(txt, szText)
		local szNum = szText:match(_L['Current week can acquire (%d+) Langke Jian.'])
		if szNum then
			INFO_CACHE['starve_remain'] = tonumber(szNum)
		end
		txt:__SetText(szText)
	end
end)

local REC_CACHE
function D.GetClientPlayerRec()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rec = REC_CACHE
	local guid = me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName
	if not rec then
		rec = {
			starve_remain = -1,
		}
		-- 如果在同一个CD周期 则保留数据库中的次数统计
		DB_RoleInfoG:ClearBindings()
		DB_RoleInfoG:BindAll(AnsiToUTF8(guid))
		local result = DB_RoleInfoG:GetAll()
		if result and result[1] and result[1].time then
			local dwTime, dwCircle = LIB.GetRefreshTime('weekly')
			if dwTime - dwCircle < result[1].time then
				rec.starve_remain = result[1].starve_remain
			end
		end
		REC_CACHE = rec
	end

	-- 基础信息
	rec.guid = guid
	rec.account = LIB.GetAccount() or ''
	rec.region = LIB.GetRealServer(1)
	rec.server = LIB.GetRealServer(2)
	rec.name = me.szName
	rec.force = me.dwForceID
	rec.level = me.nLevel
	rec.equip_score = me.GetBaseEquipScore() + me.GetStrengthEquipScore() + me.GetMountsEquipScore()
	rec.pet_score = me.GetAcquiredFellowPetScore() + me.GetAcquiredFellowPetMedalScore()
	local money = me.GetMoney()
	rec.gold = money.nGold
	rec.silver = money.nSilver
	rec.copper = money.nCopper
	rec.contribution = me.nContribution
	rec.contribution_remain = me.GetContributionRemainSpace()
	rec.justice = me.nJustice
	rec.justice_remain = me.GetJusticeRemainSpace()
	rec.prestige = me.nCurrentPrestige
	rec.prestige_remain = me.GetPrestigeRemainSpace()
	rec.camp_point = me.nTitlePoint
	rec.camp_point_percentage = me.GetRankPointPercentage()
	rec.camp_level = me.nTitle
	rec.arena_award = me.nArenaAward
	rec.arena_award_remain = me.GetArenaAwardRemainSpace()
	rec.exam_print = me.nExamPrint
	rec.exam_print_remain = me.GetExamPrintRemainSpace()
	rec.achievement_score = me.GetAchievementRecord()
	rec.architecture = me.nArchitecture
	rec.architecture_remain = me.GetArchitectureRemainSpace()
	rec.coin = me.nCoin
	rec.mentor_score = me.dwTAEquipsScore
	rec.starve = LIB.GetItemAmountInAllPackages(5, 34797, true)
	rec.time = GetCurrentTime()

	for k, v in pairs(INFO_CACHE) do
		rec[k] = v
	end
	return rec
end
end

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_RoleStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]

	local rec = Clone(D.GetClientPlayerRec())
	D.EncodeRow(rec)

	DB:Execute('BEGIN TRANSACTION')

	DB_RoleInfoW:ClearBindings()
	DB_RoleInfoW:BindAll(
		rec.guid, rec.account, rec.region, rec.server,
		rec.name, rec.force, rec.level, rec.equip_score,
		rec.pet_score, rec.gold, rec.silver, rec.copper,
		rec.contribution, rec.contribution_remain, rec.justice, rec.justice_remain,
		rec.prestige, rec.prestige_remain, rec.camp_point, rec.camp_point_percentage,
		rec.camp_level, rec.arena_award, rec.arena_award_remain, rec.exam_print,
		rec.exam_print_remain, rec.achievement_score, rec.coin, rec.mentor_score,
		rec.starve, rec.starve_remain, rec.architecture, rec.architecture_remain,
		rec.time)
	DB_RoleInfoW:Execute()

	DB_RoleInfoCoinW:ClearBindings()
	DB_RoleInfoCoinW:BindAll(rec.coin, rec.account, rec.region)
	DB_RoleInfoCoinW:Execute()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_RoleStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_RoleStat', D.FlushDB)

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
		LIB.Debug('MY_RoleStatistics_RoleStat', 'Remove from database...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB_RoleInfoD:ClearBindings()
		DB_RoleInfoD:BindAll(AnsiToUTF8(me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName))
		DB_RoleInfoD:Execute()
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_RoleStat', 'Remove from database finished...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_ROLE_UPDATE')
end
LIB.RegisterInit('MY_RoleStatistics_RoleUpdateSaveDB', function() INIT = true end)
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
	local hCols = page:Lookup('Wnd_Total/WndScroll_RoleStat', 'Handle_RoleStatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetColumns(), 0, nil
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_RoleStatColumn')
		local txt = hCol:Lookup('Text_RoleStat_Title')
		local imgAsc = hCol:Lookup('Image_RoleStat_Asc')
		local imgDesc = hCol:Lookup('Image_RoleStat_Desc')
		local nWidth = i == #aCol and (EXCEL_WIDTH - nX) or col.nWidth
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_RoleStat_Break'):Hide()
		end
		hCol.szSort = col.id
		hCol:SetRelX(nX)
		hCol:SetW(nWidth)
		txt:SetW(nWidth)
		txt:SetText(col.szShortTitle or col.szTitle)
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
	DB_RoleInfoR:ClearBindings()
	DB_RoleInfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = DB_RoleInfoR:GetAll()

	for _, rec in ipairs(result) do
		D.DecodeRow(rec)
	end

	if Sorter then
		sort(result, Sorter)
	end

	local aCol = D.GetColumns()
	-- 列表
	local hList = page:Lookup('Wnd_Total/WndScroll_RoleStat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(result) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		hRow.rec = rec
		hRow:Lookup('Image_RowBg'):SetVisible(i % 2 == 1)
		-- 绘制列
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
		-- 绘制复选框
		UI(hRow):Append('CheckBox', {
			x = 5, y = 2, w = EXCEL_WIDTH - 10,
			checked = IsEmpty(O.tSummaryIgnoreGUID) or not O.tSummaryIgnoreGUID[rec.guid] or false,
			oncheck = function(bCheck)
				O.tSummaryIgnoreGUID[rec.guid] = not bCheck or nil
				D.UpdateUI(page)
			end,
			visible = O.bConfigSummary or false,
		})
		-- 格式化位置
		hRow:FormatAllItemPos()
	end
	hList:FormatAllItemPos()

	-- 汇总
	local aSum = {}
	for _, rec in ipairs(result) do
		if IsEmpty(O.tSummaryIgnoreGUID) or not O.tSummaryIgnoreGUID[rec.guid] then
			insert(aSum, rec)
		end
	end
	local hSum = page:Lookup('Wnd_Total/WndScroll_RoleStat', 'Handle_Sum')
	hSum:Clear()
	local hRow = hSum:AppendItemFromIni(SZ_INI, 'Handle_Row', 'Handle_SumRow')
	hRow:Lookup('Image_RowBg'):SetVisible(false)
	local nX = 0
	for j, col in ipairs(aCol) do
		local hItem = hRow:AppendItemFromIni(SZ_INI, 'Handle_Item') -- 外部居中层
		local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
		hItemContent:AppendItemFromString(col.GetSummaryFormatText and col.GetSummaryFormatText(aSum) or GetFormatText('--'))
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
	hSum:FormatAllItemPos()
end

function D.EncodeRow(rec)
	rec.guid   = AnsiToUTF8(rec.guid)
	rec.name   = AnsiToUTF8(rec.name)
	rec.region = AnsiToUTF8(rec.region)
	rec.server = AnsiToUTF8(rec.server)
end

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
end

function D.OutputRowTip(this, rec)
	local aXml = {}
	local bFloat = this:GetRoot():GetName() ~= 'MY_RoleStatistics'
	for _, col in ipairs(COLUMN_LIST) do
		if not bFloat or not col.bHideInFloat then
			insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			insert(aXml, col.GetFormatText(rec))
			insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
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
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_RoleStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(page, true, true)
	Wnd.CloseWindow(frameTemp)

	-- 显示列
	UI(wnd):Append('WndComboBox', {
		x = 800, y = 20, w = 180,
		text = _L['Columns'],
		menu = function()
			local t, c, nW = {}, {}, 0
			for i, id in ipairs(O.aColumn) do
				local col = COLUMN_DICT[id]
				if col then
					insert(t, {
						szOption = col.szTitle,
						{
							szOption = _L['Move up'],
							fnAction = function()
								if i > 1 then
									O.aColumn[i], O.aColumn[i - 1] = O.aColumn[i - 1], O.aColumn[i]
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Move down'],
							fnAction = function()
								if i < #O.aColumn then
									O.aColumn[i], O.aColumn[i + 1] = O.aColumn[i + 1], O.aColumn[i]
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								remove(O.aColumn, i)
								D.UpdateUI(page)
								UI.ClosePopupMenu()
							end,
						},
					})
					c[id] = true
					nW = nW + col.nWidth
				end
			end
			for _, col in ipairs(COLUMN_LIST) do
				if not c[col.id] then
					insert(t, {
						szOption = col.szTitle,
						fnAction = function()
							if nW + col.nWidth > EXCEL_WIDTH then
								LIB.Alert(_L['Too many column selected, width overflow, please delete some!'])
							else
								insert(O.aColumn, col.id)
							end
							D.UpdateUI(page)
							UI.ClosePopupMenu()
						end,
					})
				end
			end
			return t
		end,
	})

	-- ESC提示列
	UI(wnd):Append('WndComboBox', {
		x = 600, y = 20, w = 180,
		text = _L['Columns alert when esc'],
		menu = function()
			local t, c = {}, {}
			for i, id in ipairs(O.aAlertColumn) do
				local col = ALERT_COLUMN_DICT[id]
				if col then
					insert(t, {
						szOption = col.szTitle,
						{
							szOption = _L['Move up'],
							fnAction = function()
								if i > 1 then
									O.aAlertColumn[i], O.aAlertColumn[i - 1] = O.aAlertColumn[i - 1], O.aAlertColumn[i]
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Move down'],
							fnAction = function()
								if i < #O.aAlertColumn then
									O.aAlertColumn[i], O.aAlertColumn[i + 1] = O.aAlertColumn[i + 1], O.aAlertColumn[i]
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								remove(O.aAlertColumn, i)
								UI.ClosePopupMenu()
							end,
						},
					})
					c[id] = true
				end
			end
			for _, col in ipairs(ALERT_COLUMN) do
				if not c[col.id] then
					insert(t, {
						szOption = col.szTitle,
						fnAction = function()
							insert(O.aAlertColumn, col.id)
							UI.ClosePopupMenu()
						end,
					})
				end
			end
			return t
		end,
	})

	UI(wnd):Append('WndButton', {
		x = 25, y = 552, w = 25, h = 25,
		buttonstyle = 'OPTION',
		onclick = function()
			O.bConfigSummary = not O.bConfigSummary
			D.UpdateUI(page)
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_ROLE_UPDATE')
end

function D.CheckAdvice()
	for _, p in ipairs({
		{
			szMsg = _L('%s stat has not been enabled, this character\'s data will not be saved, are you willing to save this character?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]),
			szAdviceKey = 'bAdviceSaveDB',
			szSetKey = 'bSaveDB',
		},
		{
			szMsg = _L('%s stat float entry has not been enabled, are you willing to enable it?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]),
			szAdviceKey = 'bAdviceFloatEntry',
			szSetKey = 'bFloatEntry',
		},
	}) do
		if not O[p.szAdviceKey] and not O[p.szSetKey] then
			LIB.Confirm(p.szMsg, function()
				MY_RoleStatistics_RoleStat[p.szSetKey] = true
				MY_RoleStatistics_RoleStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end, function()
				MY_RoleStatistics_RoleStat[p.szAdviceKey] = true
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
	elseif event == 'MY_ROLE_STAT_ROLE_UPDATE' then
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
			DB_RoleInfoD:ClearBindings()
			DB_RoleInfoD:BindAll(AnsiToUTF8(wnd.guid))
			DB_RoleInfoD:Execute()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_RoleStatColumn' then
		if this.szSort then
			local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
			if O.szSort == this.szSort then
				O.szSortOrder = O.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				O.szSort = this.szSort
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
					DB_RoleInfoD:ClearBindings()
					DB_RoleInfoD:BindAll(AnsiToUTF8(rec.guid))
					DB_RoleInfoD:Execute()
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
	elseif name == 'Handle_RoleStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = GetFormatText(this:Lookup('Text_RoleStat_Title'):GetText(), 162, 255, 255, 255)
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

local ALERT_INIT_VAL = {}
LIB.RegisterInit('MY_RoleStatistics_RoleStat__AlertCol', function()
	local me = GetClientPlayer()
	for _, col in ipairs(ALERT_COLUMN) do
		ALERT_INIT_VAL[col.id] = col.GetValue(me)
	end
	if not IsTable(O.tAlertTodayVal) or not IsNumber(O.tAlertTodayVal.nTime)
	or not LIB.IsInSameRefreshTime('daily', O.tAlertTodayVal.nTime) then
		O.tAlertTodayVal = {}
		for _, col in ipairs(ALERT_COLUMN) do
			O.tAlertTodayVal[col.id] = col.GetValue(me)
		end
		O.tAlertTodayVal.nTime = GetCurrentTime()
	end
end)
LIB.RegisterFrameCreate('OptionPanel.MY_RoleStatistics_RoleStat__AlertCol', function()
	local me = GetClientPlayer()
	local tVal = {}
	for _, col in ipairs(ALERT_COLUMN) do
		tVal[col.id] = col.GetValue(me)
	end

	local aText, aDailyText = {}, {}
	for _, id in ipairs(O.aAlertColumn) do
		local col = ALERT_COLUMN_DICT[id]
		if col then
			insert(aText, (col.GetCompareText(ALERT_INIT_VAL, tVal)))
			insert(aDailyText, (col.GetCompareText(O.tAlertTodayVal, tVal)))
		end
	end
	local szText, szDailyText = concat(aText, GetFormatSysmsgText(_L[','])), concat(aDailyText, GetFormatSysmsgText(_L[',']))
	if GetTime() - O.dwLastAlertTime > 10000 or O.szLastAlert ~= szText or O.szLastDailyAlert ~= szDailyText then
		if not IsEmpty(szText) and szText ~= szDailyText then
			LIB.Sysmsg({ GetFormatSysmsgText(_L['Current online ']) .. szText .. GetFormatSysmsgText(_L['.']), rich = true })
		end
		if not IsEmpty(szDailyText) then
			LIB.Sysmsg({ GetFormatSysmsgText(_L['Today online ']) .. szDailyText .. GetFormatSysmsgText(_L['.']), rich = true })
		end
		O.dwLastAlertTime = GetTime()
		O.szLastAlert = szText
		O.szLastDailyAlert = szDailyText
	end
end)

-- 浮动框
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/SprintPower')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_RoleEntry')
	if IsNil(bFloatEntry) then
		bFloatEntry = O.bFloatEntry
	end
	if bFloatEntry then
		if btn then
			return
		end
		local frameTemp = Wnd.OpenWindow(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_RoleEntry.ini', 'MY_RoleStatistics_RoleEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_RoleEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(55, -8)
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
			MY_RoleStatistics.Open('RoleStat')
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
LIB.RegisterInit('MY_RoleStatistics_RoleEntry', D.UpdateFloatEntry)
LIB.RegisterReload('MY_RoleStatistics_RoleEntry', function() D.ApplyFloatEntry(false) end)
LIB.RegisterFrameCreate('SprintPower.MY_RoleStatistics_RoleEntry', D.UpdateFloatEntry)

-- Module exports
do
local settings = {
	exports = {
		{
			fields = {
				OnInitPage = D.OnInitPage,
				szFloatEntry = 'MY_RoleStatistics_RoleStat.bFloatEntry',
				szSaveDB = 'MY_RoleStatistics_RoleStat.bSaveDB',
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_RoleStatistics.RegisterModule('RoleStat', _L['MY_RoleStatistics_RoleStat'], LIB.GeneGlobalNS(settings))
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
				aAlertColumn = true,
				tAlertTodayVal = true,
				tSummaryIgnoreGUID = true,
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
				aAlertColumn = true,
				tAlertTodayVal = true,
				tSummaryIgnoreGUID = true,
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
MY_RoleStatistics_RoleStat = LIB.GeneGlobalNS(settings)
end
