--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 秘境CD统计
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_DungeonStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

local DB = LIB.SQLiteConnect(_L['MY_RoleStatistics_DungeonStat'], {'userdata/role_statistics/dungeon_stat.v2.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_DungeonStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_DungeonStat.ini'

DB:Execute('CREATE TABLE IF NOT EXISTS DungeonInfo (guid NVARCHAR(20), account NVARCHAR(255), region NVARCHAR(20), server NVARCHAR(20), name NVARCHAR(20), force INTEGER, level INTEGER, equip_score INTEGER, copy_info NVARCHAR(65535), progress_info NVARCHAR(65535), time INTEGER, PRIMARY KEY(guid))')
local DB_DungeonInfoW = DB:Prepare('REPLACE INTO DungeonInfo (guid, account, region, server, name, force, level, equip_score, copy_info, progress_info, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_DungeonInfoG = DB:Prepare('SELECT * FROM DungeonInfo WHERE guid = ?')
local DB_DungeonInfoR = DB:Prepare('SELECT * FROM DungeonInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_DungeonInfoD = DB:Prepare('DELETE FROM DungeonInfo WHERE guid = ?')

local O = LIB.CreateUserSettingsModule('MY_RoleStatistics_DungeonStat', _L['General'], {
	aColumn = {
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Collection(Schema.String),
		xDefaultValue = {
			'name',
			'force',
			'week_team_dungeon',
			'week_raid_dungeon',
			'dungeon_427',
			'dungeon_428',
			'time_days',
		},
	},
	szSort = {
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.String,
		xDefaultValue = 'time_days',
	},
	szSortOrder = {
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.String,
		xDefaultValue = 'desc',
	},
	bFloatEntry = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceFloatEntry = {
		ePathType = PATH_TYPE.ROLE,
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bSaveDB = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	tMapSaveCopy = {}, -- 单秘境 CD
	bMapSaveCopyValid = false, -- 客户端缓存的单秘境 CD 数据有效
	dwMapSaveCopyRequestTime = 0, -- 最后一次请求单秘境 CD 时间
	tMapProgress = {}, -- 单首领 CD 进度
	tMapProgressValid = {}, -- 客户端缓存的单首领 CD 进度数据有效
	tMapProgressRequestTime = setmetatable({}, { __index = function() return 0 end }), -- 客户端缓存的单首领 CD 进度数据有效
}

local EXCEL_WIDTH = 960
local DUNGEON_MIN_WIDTH = 80
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
	{ -- 等级
		id = 'level',
		szTitle = _L['Level'],
		nMinWidth = 50, nMaxWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- 装分
		id = 'equip_score',
		bHideInFloat = true,
		szTitle = _L['EquSC'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('equip_score'),
		Compare = GeneCommonCompare('equip_score'),
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
local COLUMN_DICT = setmetatable({}, { __index = function(t, id)
	if id == 'week_team_dungeon' then
		if GLOBAL.GAME_BRANCH ~= 'classic' then
			return {
				id = id,
				szTitle = _L['Week routine: '] .. _L.ACTIVITY_WEEK_TEAM_DUNGEON,
				nMinWidth = DUNGEON_MIN_WIDTH * #LIB.GetActivityMap('WEEK_TEAM_DUNGEON'),
			}
		end
	elseif id == 'week_raid_dungeon' then
		if GLOBAL.GAME_BRANCH ~= 'classic' then
			return {
				id = id,
				szTitle = _L['Week routine: '] .. _L.ACTIVITY_WEEK_RAID_DUNGEON,
				nMinWidth = DUNGEON_MIN_WIDTH * #LIB.GetActivityMap('WEEK_RAID_DUNGEON'),
			}
		end
	elseif wfind(id, 'dungeon_') then
		local id, via = wgsub(id, 'dungeon_', ''), ''
		if wfind(id, '@') then
			local ids = LIB.SplitString(id, '@')
			id, via = tonumber(ids[1]), ids[2]
		else
			id = tonumber(id)
		end
		local map = id and LIB.GetMapInfo(id)
		if map then
			local col = { -- 秘境CD
				id = 'dungeon_' .. id,
				szTitle = map.szName,
				nMinWidth = DUNGEON_MIN_WIDTH,
			}
			if via then
				local colVia = t[via]
				if colVia then
					col.szTitleTip = col.szTitle .. ' (' .. colVia.szTitle .. ')'
				end
			end
			if LIB.IsDungeonRoleProgressMap(map.dwID) then
				col.GetFormatText = function(rec)
					local aBossKill = rec.progress_info[map.dwID]
					local nNextTime, nCircle = LIB.GetDungeonRefreshTime(map.dwID)
					if not aBossKill or nNextTime - nCircle > rec.time then
						return GetFormatText(_L['--'], 162, 255, 255, 255)
					end
					local aXml = {}
					for _, bKill in ipairs(aBossKill) do
						insert(aXml, '<image>path="' .. PLUGIN_ROOT .. '/img/MY_RoleStatistics.UITex" name="Image_ProgressBoss" eventid=786 frame='
							.. (bKill and 1 or 0) .. ' w=12 h=12 script="this.mapid=' .. map.dwID .. '"</image>')
					end
					return concat(aXml)
				end
				col.Compare = function(r1, r2)
					local k1 = r1.progress_info[map.dwID]
					local k2 = r2.progress_info[map.dwID]
					if k1 and not k2 then
						return 1
					end
					if k2 and not k1 then
						return -1
					end
					if not k1 and not k2 then
						return 0
					end
					local s1, s2 = 0, 0
					for _, p in ipairs(k1) do
						if p then
							s1 = s1 + 1
						end
					end
					for _, p in ipairs(k2) do
						if p then
							s2 = s2 + 1
						end
					end
					return s1 > s2 and 1 or -1
				end
			else
				col.GetFormatText = function(rec)
					local aCopyID = rec.copy_info[map.dwID]
					local nNextTime, nCircle = LIB.GetDungeonRefreshTime(map.dwID)
					local szText = nNextTime - nCircle < rec.time
						and (aCopyID and aCopyID[1] or _L['None'])
						or (_L['--'])
					return GetFormatText(szText, 162, 255, 255, 255, 786, 'this.mapid=' .. map.dwID, 'Text_CD')
				end
				col.Compare = function(r1, r2)
					local k1 = r1.copy_info[map.dwID] and r1.copy_info[map.dwID][1]
					local k2 = r2.copy_info[map.dwID] and r2.copy_info[map.dwID][1]
					if k1 and not k2 then
						return 1
					end
					if k2 and not k1 then
						return -1
					end
					if not k1 and not k2 then
						return 0
					end
					return k1 > k2 and 1 or -1
				end
			end
			return col
		end
	end
end })
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
local TIP_COLUMN = {
	'region',
	'server',
	'name',
	'force',
	'level',
	'equip_score',
	'DUNGEON',
	'time',
	'time_days',
}

function D.GetPlayerGUID(me)
	return me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName
end

do
local REC_CACHE
function D.GetClientPlayerRec(bForceUpdate)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rec = REC_CACHE
	local guid = D.GetPlayerGUID(me)
	if not rec then
		rec = {}
		REC_CACHE = rec
	end
	D.UpdateMapProgress(bForceUpdate)

	-- 基础信息
	rec.guid = guid
	rec.account = LIB.GetAccount() or ''
	rec.region = LIB.GetRealServer(1)
	rec.server = LIB.GetRealServer(2)
	rec.name = me.szName
	rec.force = me.dwForceID
	rec.level = me.nLevel
	rec.equip_score = me.GetBaseEquipScore() + me.GetStrengthEquipScore() + me.GetMountsEquipScore()
	rec.time = GetCurrentTime()
	rec.copy_info = D.tMapSaveCopy
	rec.progress_info = D.tMapProgress
	return rec
end
end

function D.FlushDB(bForceUpdate)
	if not D.bReady or not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]

	local rec = Clone(D.GetClientPlayerRec(bForceUpdate))
	D.EncodeRow(rec)

	DB:Execute('BEGIN TRANSACTION')
	DB_DungeonInfoW:ClearBindings()
	DB_DungeonInfoW:BindAll(
		rec.guid, rec.account, rec.region, rec.server,
		rec.name, rec.force, rec.level, rec.equip_score,
		rec.copy_info, rec.progress_info, rec.time)
	DB_DungeonInfoW:Execute()
	DB_DungeonInfoW:Reset()
	DB:Execute('END TRANSACTION')

	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	LIB.Debug('MY_RoleStatistics_DungeonStat', _L('Flushing to database costs %dms...', nTickCount), DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_DungeonStat', function() D.FlushDB() end)

function D.InitDB()
	local me = GetClientPlayer()
	if me then
		DB_DungeonInfoG:ClearBindings()
		DB_DungeonInfoG:BindAll(AnsiToUTF8(D.GetPlayerGUID(me)))
		local result = DB_DungeonInfoG:GetAll()
		DB_DungeonInfoG:Reset()
		local rec = result[1]
		if rec then
			D.DecodeRow(rec)
			D.tMapSaveCopy = DecodeLUAData(rec.copy_info) or {}
			D.tMapProgress = DecodeLUAData(rec.progress_info) or {}
		end
	end
end
LIB.RegisterInit('MY_RoleStatistics_DungeonStat', D.InitDB)

function D.UpdateSaveDB()
	if not D.bReady then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_DungeonStat', 'Remove from database...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB_DungeonInfoD:ClearBindings()
		DB_DungeonInfoD:BindAll(AnsiToUTF8(D.GetPlayerGUID(me)))
		DB_DungeonInfoD:Execute()
		DB_DungeonInfoD:Reset()
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_DungeonStat', 'Remove from database finished...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_DUNGEON_UPDATE')
end

function D.GetColumns()
	local aCol = {}
	for _, id in ipairs(O.aColumn) do
		if id == 'week_team_dungeon' then
			for _, map in ipairs(LIB.GetActivityMap('WEEK_TEAM_DUNGEON')) do
				local col = COLUMN_DICT['dungeon_' .. map.dwID .. '@' .. id]
				if col then
					insert(aCol, col)
				end
			end
		elseif id == 'week_raid_dungeon' then
			for _, map in ipairs(LIB.GetActivityMap('WEEK_RAID_DUNGEON')) do
				local col = COLUMN_DICT['dungeon_' .. map.dwID .. '@' .. id]
				if col then
					insert(aCol, col)
				end
			end
		else
			local col = COLUMN_DICT[id]
			if col then
				insert(aCol, col)
			end
		end
	end
	return aCol
end

function D.UpdateUI(page)
	local hCols = page:Lookup('Wnd_Total/WndScroll_DungeonStat', 'Handle_DungeonStatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetColumns(), 0, nil
	local nExtraWidth = EXCEL_WIDTH
	for i, col in ipairs(aCol) do
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_DungeonStatColumn')
		local txt = hCol:Lookup('Text_DungeonStat_Title')
		local imgAsc = hCol:Lookup('Image_DungeonStat_Asc')
		local imgDesc = hCol:Lookup('Image_DungeonStat_Desc')
		local nWidth = i == #aCol
			and (EXCEL_WIDTH - nX)
			or min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or HUGE)
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_DungeonStat_Break'):Hide()
		end
		hCol.szSort = col.id
		hCol.szTip = col.szTitleTip
		hCol.szDebugTip = 'id: ' .. col.id
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
	DB_DungeonInfoR:ClearBindings()
	DB_DungeonInfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = DB_DungeonInfoR:GetAll()
	DB_DungeonInfoR:Reset()

	for _, rec in ipairs(result) do
		D.DecodeRow(rec)
	end

	if Sorter then
		sort(result, Sorter)
	end

	local aCol = D.GetColumns()
	local hList = page:Lookup('Wnd_Total/WndScroll_DungeonStat', 'Handle_List')
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

function D.UpdateMapProgress(bForceUpdate)
	local me = GetClientPlayer()
	if not me then -- 确保不可能在切换GS时请求
		return
	end
	for _, col in ipairs(D.GetColumns()) do
		local szID = wfind(col.id, 'dungeon_') and wgsub(col.id, 'dungeon_', '')
		local dwID = szID and tonumber(szID)
		local aProgressBoss = dwID and LIB.IsDungeonRoleProgressMap(dwID) and Table_GetCDProcessBoss(dwID)
		if aProgressBoss then
			-- 强制刷新秘境进度，或者进度数据已过期并且5秒内未请求过，则发起请求
			if bForceUpdate or (not D.tMapProgressValid[dwID] and GetTime() - D.tMapProgressRequestTime[dwID] > 5000) then
				D.tMapProgressRequestTime[dwID] = GetTime()
				--[[#DEBUG BEGIN]]
				LIB.Debug(
					_L['PMTool'],
					_L('[MY_RoleStatistics_DungeonStat] ApplyDungeonRoleProgress: %d.', dwID),
					DEBUG_LEVEL.PMLOG)
				--[[#DEBUG END]]
				ApplyDungeonRoleProgress(dwID, UI_GetClientPlayerID())
			end
			-- 已经获取到进度的秘境，或者没有 CD 数据的秘境
			if D.tMapProgressValid[dwID] or (D.bMapSaveCopyValid and not D.tMapSaveCopy[dwID]) then
				local aProgress = {}
				for i, boss in ipairs(aProgressBoss) do
					aProgress[i] = GetDungeonRoleProgress(dwID, UI_GetClientPlayerID(), boss.dwProgressID)
				end
				D.tMapProgress[dwID] = aProgress
			end
		end
	end
	-- 强制刷新秘境进度，或者进度数据已过期并且5秒内未请求过，则发起请求
	if bForceUpdate or (not D.bMapSaveCopyValid and GetTime() - D.dwMapSaveCopyRequestTime > 5000) then
		D.dwMapSaveCopyRequestTime = GetTime()
		ApplyMapSaveCopy()
	end
end

function D.EncodeRow(rec)
	rec.guid   = AnsiToUTF8(rec.guid)
	rec.name   = AnsiToUTF8(rec.name)
	rec.region = AnsiToUTF8(rec.region)
	rec.server = AnsiToUTF8(rec.server)
	rec.copy_info = EncodeLUAData(rec.copy_info)
	rec.progress_info = EncodeLUAData(rec.progress_info)
end

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
	rec.copy_info = DecodeLUAData(rec.copy_info or '') or {}
	rec.progress_info = DecodeLUAData(rec.progress_info or '') or {}
end

function D.OutputRowTip(this, rec)
	local aXml = {}
	local bFloat = this:GetRoot():GetName() ~= 'MY_RoleStatistics'
	for _, id in ipairs(TIP_COLUMN) do
		if id == 'DUNGEON' then
			local tDungeon, aDungeon = {}, {}
			for _, col in ipairs(D.GetColumns()) do
				if wfind(col.id, 'dungeon_') then
					local a, dwMapID = {}, tonumber(col.id:sub(#'dungeon_' + 1))
					local nMaxPlayerCount = select(3, GetMapParams(dwMapID))
					insert(a, GetFormatText(col.szTitle, 162, 255, 255, 0))
					insert(a, GetFormatText(':  ', 162, 255, 255, 0))
					insert(a, col.GetFormatText(rec))
					insert(a, GetFormatText('\n', 162, 255, 255, 255))
					insert(aDungeon, { dwMapID = dwMapID, nMaxPlayerCount = nMaxPlayerCount, szXml = concat(a) })
					tDungeon[dwMapID] = true
				end
			end
			for dwMapID, aCopyID in pairs(rec.copy_info) do
				if not tDungeon[dwMapID] then
					local map = LIB.GetMapInfo(dwMapID)
					if map then
						local a = {}
						local nMaxPlayerCount = select(3, GetMapParams(dwMapID))
						insert(a, GetFormatText(map.szName, 162, 255, 255, 0))
						insert(a, GetFormatText(':  ', 162, 255, 255, 0))
						insert(a, GetFormatText(concat(aCopyID, ',')))
						insert(a, GetFormatText('\n', 162, 255, 255, 255))
						insert(aDungeon, { dwMapID = dwMapID, nMaxPlayerCount = nMaxPlayerCount, szXml = concat(a) })
					end
					tDungeon[dwMapID] = true
				end
			end
			sort(aDungeon, function(p1, p2)
				if p1.nMaxPlayerCount == p2.nMaxPlayerCount then
					return p1.dwMapID < p2.dwMapID
				end
				return p1.nMaxPlayerCount < p2.nMaxPlayerCount
			end)
			local nMaxPlayerCount = 0
			for _, p in ipairs(aDungeon) do
				if nMaxPlayerCount ~= p.nMaxPlayerCount then
					nMaxPlayerCount = p.nMaxPlayerCount
					insert(aXml, GetFormatText(_L('---- %d players dungeon ----', nMaxPlayerCount) .. '\n', 162, 255, 255, 0))
				end
				insert(aXml, p.szXml)
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
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_DungeonStat')
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
									O.aColumn = aColumn
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
									O.aColumn = aColumn
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								remove(aColumn, i)
								O.aColumn = aColumn
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
						O.aColumn = aColumn
						bExist = true
						break
					end
				end
				if not bExist then
					if nMinW + nWidth > EXCEL_WIDTH then
						LIB.Alert(_L['Too many column selected, width overflow, please delete some!'])
					else
						insert(aColumn, id)
						O.aColumn = aColumn
					end
				end
				D.FlushDB(true)
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
			-- 秘境选项
			local tDungeonChecked = {}
			for _, id in ipairs(aColumn) do
				local szID = wfind(id, 'dungeon_') and wgsub(id, 'dungeon_', '')
				local dwID = szID and tonumber(szID)
				if dwID then
					tDungeonChecked[dwID] = true
				end
			end
			local tDungeonMenu = LIB.GetDungeonMenu(function(info)
				fnAction('dungeon_' .. info.dwID, DUNGEON_MIN_WIDTH)
			end, nil, tDungeonChecked)
			-- 动态活动秘境选项
			for _, szType in ipairs({
				'week_team_dungeon',
				'week_raid_dungeon',
			}) do
				local col = COLUMN_DICT[szType]
				if col then
					insert(tDungeonMenu, {
						szOption = col.szTitle,
						bCheck = true, bChecked = tChecked[col.id],
						fnAction = function()
							fnAction(col.id, col.nMinWidth)
						end,
					})
				end
			end
			-- 子菜单标题
			tDungeonMenu.szOption = _L['Dungeon copy']
			insert(t, tDungeonMenu)
			return t
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS')
	frame:RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND')
	frame:RegisterEvent('MY_ROLE_STAT_DUNGEON_UPDATE')
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
				MY_RoleStatistics_DungeonStat[p.szSetKey] = true
				MY_RoleStatistics_DungeonStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end, function()
				MY_RoleStatistics_DungeonStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end)
			return
		end
	end
end

function D.OnActivePage()
	D.CheckAdvice()
	D.FlushDB(true)
	D.UpdateUI(this)
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateUI(this)
	elseif event == 'UPDATE_DUNGEON_ROLE_PROGRESS' or event == 'ON_APPLY_PLAYER_SAVED_COPY_RESPOND' then
		D.FlushDB()
		D.UpdateUI(this)
	elseif event == 'MY_ROLE_STAT_DUNGEON_UPDATE' then
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
			DB_DungeonInfoD:ClearBindings()
			DB_DungeonInfoD:BindAll(AnsiToUTF8(wnd.guid))
			DB_DungeonInfoD:Execute()
			DB_DungeonInfoD:Reset()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_DungeonStatColumn' then
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
					DB_DungeonInfoD:ClearBindings()
					DB_DungeonInfoD:BindAll(AnsiToUTF8(rec.guid))
					DB_DungeonInfoD:Execute()
					DB_DungeonInfoD:Reset()
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
	elseif name == 'Image_ProgressBoss' or name == 'Text_CD' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local aText = {}
		local map = LIB.GetMapInfo(this.mapid)
		if map then
			local szName = map.szName
			local aCD = D.tMapSaveCopy[map.dwID]
			if not IsEmpty(aCD) then
				szName = szName .. ' (' .. concat(aCD, ', ') .. ')'
			end
			insert(aText, szName)
		end
		if name == 'Image_ProgressBoss' then
			insert(aText, '')
			local rec = this:GetParent():GetParent():GetParent().rec
			for i, boss in ipairs(Table_GetCDProcessBoss(this.mapid)) do
				insert(aText, boss.szName .. '\t' .. _L[rec.progress_info[this.mapid][i] and 'x' or 'r'])
			end
		end
		insert(aText, '')
		local nTime = LIB.GetDungeonRefreshTime(this.mapid) - GetCurrentTime()
		insert(aText, _L('Refresh: %s', LIB.FormatTimeCounter(nTime, 2, 2)))
		OutputTip(GetFormatText(concat(aText, '\n'), 162, 255, 255, 255), 400, { x, y, w, h })
	elseif name == 'Handle_DungeonStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = GetFormatText(this.szTip or this:Lookup('Text_DungeonStat_Title'):GetText(), 162, 255, 255, 255)
		if IsCtrlKeyDown() and this.szDebugTip then
			szXml = szXml .. CONSTANT.XML_LINE_BREAKER .. GetFormatText(this.szDebugTip, 102)
		end
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

-- 浮动框
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/SprintPower')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_DungeonEntry')
	if bFloatEntry then
		if btn then
			return
		end
		local frameTemp = Wnd.OpenWindow(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_DungeonEntry.ini', 'MY_RoleStatistics_DungeonEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_DungeonEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(72, 13)
		Wnd.CloseWindow(frameTemp)
		btn.OnMouseEnter = function()
			local rec = D.GetClientPlayerRec(true)
			if not rec then
				return
			end
			D.OutputRowTip(this, rec)
		end
		btn.OnMouseLeave = function()
			D.CloseRowTip()
		end
		btn.OnLButtonClick = function()
			MY_RoleStatistics.Open('DungeonStat')
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

-- 首领死亡刷新秘境进度（秘境内同步拾取则视为进度更新）
LIB.RegisterEvent('SYNC_LOOT_LIST', 'MY_RoleStatistics_DungeonStat__UpdateMapCopy', function()
	if not D.bReady or not LIB.IsInDungeon() then
		return
	end
	local me = GetClientPlayer()
	if me then
		D.bMapSaveCopyValid = false
		D.tMapProgressValid[me.GetMapID()] = false
	end
	LIB.DelayCall('MY_RoleStatistics_DungeonStat__UpdateMapCopy', 300, function() D.UpdateMapProgress() end)
end)
LIB.RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS', function()
	local dwMapID, dwPlayerID = arg0, arg1
	if dwPlayerID ~= UI_GetClientPlayerID() then
		return
	end
	D.tMapProgressValid[dwMapID] = true
	D.FlushDB()
end)
LIB.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', function()
	local tMapCopy = arg0
	D.tMapSaveCopy = tMapCopy
	D.bMapSaveCopyValid = true
	D.FlushDB()
end)
LIB.RegisterInit('MY_RoleStatistics_DungeonEntry', function()
	D.UpdateMapProgress()
end)
LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_RoleStatistics_DungeonStat', function()
	D.bReady = true
	D.UpdateSaveDB()
	D.FlushDB()
	D.UpdateFloatEntry()
end)
LIB.RegisterReload('MY_RoleStatistics_DungeonEntry', function() D.ApplyFloatEntry(false) end)
LIB.RegisterFrameCreate('SprintPower', 'MY_RoleStatistics_DungeonEntry', D.UpdateFloatEntry)

-- Module exports
do
local settings = {
	name = 'MY_RoleStatistics_DungeonStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				szSaveDB = 'MY_RoleStatistics_DungeonStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_DungeonStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('DungeonStat', _L['MY_RoleStatistics_DungeonStat'], LIB.CreateModule(settings))
end

-- Global exports
do
local settings = {
	name = 'MY_RoleStatistics_DungeonStat',
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
MY_RoleStatistics_DungeonStat = LIB.CreateModule(settings)
end
