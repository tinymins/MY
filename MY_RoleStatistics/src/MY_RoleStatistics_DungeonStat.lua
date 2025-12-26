--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 秘境CD统计
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RoleStatistics/MY_RoleStatistics_DungeonStat'
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_DungeonStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(X.FormatPath({'userdata/role_statistics', X.PATH_TYPE.GLOBAL}))

local DB = X.SQLiteConnect(_L['MY_RoleStatistics_DungeonStat'], {'userdata/role_statistics/dungeon_stat.v3.db', X.PATH_TYPE.GLOBAL})
if not DB then
	return X.OutputSystemMessage(_L['MY_RoleStatistics_DungeonStat'], _L['Cannot connect to database!!!'], X.CONSTANT.MSG_THEME.ERROR)
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]

X.SQLiteExecute(DB, [[
	CREATE TABLE IF NOT EXISTS DungeonInfo (
		guid NVARCHAR(20) NOT NULL,
		account NVARCHAR(255) NOT NULL,
		region NVARCHAR(20) NOT NULL,
		server NVARCHAR(20) NOT NULL,
		name NVARCHAR(20) NOT NULL,
		force INTEGER NOT NULL,
		level INTEGER NOT NULL,
		equip_score INTEGER NOT NULL,
		copy_info NVARCHAR(65535) NOT NULL,
		progress_info NVARCHAR(65535) NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(guid)
	)
]])
local DB_DungeonInfoW = X.SQLitePrepare(DB, 'REPLACE INTO DungeonInfo (guid, account, region, server, name, force, level, equip_score, copy_info, progress_info, time, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_DungeonInfoG = X.SQLitePrepare(DB, 'SELECT * FROM DungeonInfo WHERE guid = ?')
local DB_DungeonInfoR = X.SQLitePrepare(DB, 'SELECT * FROM DungeonInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_DungeonInfoD = X.SQLitePrepare(DB, 'DELETE FROM DungeonInfo WHERE guid = ?')

local O = X.CreateUserSettingsModule('MY_RoleStatistics_DungeonStat', _L['General'], {
	aColumn = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_DungeonStat'],
			_L['Columns'],
		}),
		xSchema = X.Schema.Collection(X.Schema.String),
		xDefaultValue = {
			'name',
			'force',
			'recommend_raid_dungeon',
			'week_raid_dungeon',
			'week_team_dungeon',
			'time_days',
		},
	},
	szSort = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_DungeonStat'],
			_L['Sort'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'time_days',
	},
	szSortOrder = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_DungeonStat'],
			_L['Sort Order'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'desc',
	},
	bFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_DungeonStat'],
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
			_L['MY_RoleStatistics_DungeonStat'],
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
local D = {
	tMapSaveCopy = {}, -- 单秘境 CD
	bMapSaveCopyValid = false, -- 客户端缓存的单秘境 CD 数据有效
	dwMapSaveCopyRequestTime = 0, -- 最后一次请求单秘境 CD 时间
	tMapProgress = {}, -- 单首领 CD 进度
	tMapProgressValid = {}, -- 客户端缓存的单首领 CD 进度数据有效
	tMapProgressRequestTime = setmetatable({}, { __index = function() return 0 end }), -- 客户端缓存的单首领 CD 进度数据有效
	aMapProgressRequestQueue = {}, -- 单首领 CD 获取队列 （一次获取太多可能会被踢）
}

local DUNGEON_MIN_WIDTH = 100
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
local function GetDungeonMapColumnID(dwMapID, szVia)
	local szColumnID = 'dungeon_' .. dwMapID
	if szVia then
		szColumnID = szColumnID .. '@' .. szVia
	end
	return szColumnID
end
local function GetColumnDungeonMapID(szColumnID)
	if not X.StringFindW(szColumnID, 'dungeon_') then
		return
	end
	local dwMapID, szVia = X.StringReplaceW(szColumnID, 'dungeon_', ''), ''
	if X.StringFindW(dwMapID, '@') then
		local ids = X.SplitString(dwMapID, '@')
		dwMapID, szVia = tonumber(ids[1]), ids[2]
	else
		dwMapID = tonumber(dwMapID)
	end
	if not dwMapID then
		return
	end
	return dwMapID, szVia
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
			return GetFormatText(name, 162, X.GetForceColor(rec.force, 'foreground'))
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
			return GetFormatText(X.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
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
	if id == 'week_team_dungeon' then
		if X.IS_REMAKE then
			return {
				id = id,
				szTitle = _L['Week routine: '] .. _L.ACTIVITY_WEEK_TEAM_DUNGEON,
				nMinWidth = DUNGEON_MIN_WIDTH * #X.GetActivityMap('WEEK_TEAM_DUNGEON'),
			}
		end
	elseif id == 'week_raid_dungeon' then
		if X.IS_REMAKE then
			return {
				id = id,
				szTitle = _L['Week routine: '] .. _L.ACTIVITY_WEEK_RAID_DUNGEON,
				nMinWidth = DUNGEON_MIN_WIDTH * #X.GetActivityMap('WEEK_RAID_DUNGEON'),
			}
		end
	elseif id == 'recommend_team_dungeon' then
		if X.IS_REMAKE then
			return {
				id = id,
				szTitle = _L['Recommend: team dungeon'],
				nMinWidth = DUNGEON_MIN_WIDTH * #X.GetRecommendDungeonMapList(false),
			}
		end
	elseif id == 'recommend_raid_dungeon' then
		if X.IS_REMAKE then
			return {
				id = id,
				szTitle = _L['Recommend: raid dungeon'],
				nMinWidth = DUNGEON_MIN_WIDTH * #X.GetRecommendDungeonMapList(true),
			}
		end
	else
		local mapid, via = GetColumnDungeonMapID(id)
		local map = mapid and X.GetMapInfo(mapid)
		if map then
			local col = { -- 秘境CD
				id = id,
				szTitle = map.szName,
				nMinWidth = DUNGEON_MIN_WIDTH,
			}
			if via then
				local colVia = t[via]
				if colVia then
					col.szTitleTip = col.szTitle .. ' (' .. colVia.szTitle .. ')'
				end
			end
			if X.IsCDProgressMap(map.dwID) then
				col.GetFormatText = function(rec)
					local aCopyID = rec.copy_info[map.dwID]
					local aBossKill = rec.progress_info[map.dwID]
					local nNextTime, nCircle = X.GetDungeonRefreshTime(map.dwID)
					if not aBossKill or nNextTime - nCircle > rec.time then
						return GetFormatText(_L['--'], 162, 255, 255, 255)
					end
					local aXml = {}
					if IsCtrlKeyDown() and aCopyID then
						table.insert(aXml, GetFormatText(table.concat(aCopyID, ',') .. ' '))
					end
					local szBossKill = ''
					for _, bKill in ipairs(aBossKill) do
						if szBossKill ~= '' then
							szBossKill = szBossKill .. ','
						end
						szBossKill = szBossKill .. (bKill and '1' or '0')
					end
					for _, bKill in ipairs(aBossKill) do
						table.insert(aXml, '<image>path="' .. PLUGIN_ROOT .. '/img/MY_RoleStatistics.UITex" name="Image_ProgressBoss" eventid=786 frame='
							.. (bKill and 1 or 0) .. ' w=12 h=12 script="this.mapid=' .. map.dwID .. ';this.progress_info=\'' .. szBossKill .. '\'"</image>')
					end
					return table.concat(aXml)
				end
				col.Compare = function(r1, r2)
					local k1 = r1.progress_info and r1.progress_info[map.dwID]
					local k2 = r2.progress_info and r2.progress_info[map.dwID]
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
					if s1 == s2 then
						return 0
					end
					return s1 > s2 and 1 or -1
				end
			else
				col.GetFormatText = function(rec)
					local aCopyID = rec.copy_info[map.dwID]
					local nNextTime, nCircle = X.GetDungeonRefreshTime(map.dwID)
					local szText = nNextTime - nCircle < rec.time
						and (aCopyID and aCopyID[1] or _L['None'])
						or (_L['--'])
					return GetFormatText(szText, 162, 255, 255, 255, 786, 'this.mapid=' .. map.dwID, 'Text_CD')
				end
				col.Compare = function(r1, r2)
					local k1 = r1.copy_info and r1.copy_info[map.dwID] and r1.copy_info[map.dwID][1]
					local k2 = r2.copy_info and r2.copy_info[map.dwID] and r2.copy_info[map.dwID][1]
					if k1 and not k2 then
						return 1
					end
					if k2 and not k1 then
						return -1
					end
					if not k1 and not k2 then
						return 0
					end
					if k1 == k2 then
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
			local k1 = r1[p.szKey]
			local k2 = r2[p.szKey]
			if k1 and not k2 then
				return 1
			end
			if k2 and not k1 then
				return -1
			end
			if not k1 and not k2 then
				return 0
			end
			if k1 == k2 then
				return 0
			end
			return k1 > k2 and 1 or -1
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

do
local REC_CACHE
function D.GetClientPlayerRec(bForceUpdate)
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local rec = REC_CACHE
	local guid = X.GetClientPlayerGlobalID()
	if not rec then
		rec = {}
		REC_CACHE = rec
	end
	D.UpdateMapProgress(bForceUpdate)

	-- 基础信息
	rec.guid = guid
	rec.account = X.GetAccount() or ''
	rec.region = X.GetRegionOriginName()
	rec.server = X.GetServerOriginName()
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

function D.ProcessProgressRequestQueue()
	local szKey = 'MY_RoleStatistics_DungeonStat__ProcessProgressRequestQueue'
	if #D.aMapProgressRequestQueue > 0 then
		X.BreatheCall(szKey, function()
			local dwID = table.remove(D.aMapProgressRequestQueue)
			if dwID then
				D.tMapProgressRequestTime[dwID] = GetTime()
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(
					_L['PMTool'],
					_L('[MY_RoleStatistics_DungeonStat] ApplyDungeonRoleProgress: %d.', dwID),
					X.DEBUG_LEVEL.PM_LOG)
				--[[#DEBUG END]]
				ApplyDungeonRoleProgress(dwID, X.GetClientPlayerID())
			else
				X.BreatheCall(szKey, false)
			end
		end)
	else
		X.BreatheCall(szKey, false)
	end
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/dungeon_stat.v2.db', X.PATH_TYPE.GLOBAL})
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
					X.SQLiteBeginTransaction(DB)
					local aDungeonInfo = X.SQLiteGetAll(DB_V2, 'SELECT * FROM DungeonInfo WHERE guid IS NOT NULL AND name IS NOT NULL')
					if aDungeonInfo then
						for _, rec in ipairs(aDungeonInfo) do
							X.SQLitePrepareExecute(
								DB_DungeonInfoW,
								rec.guid,
								rec.account,
								rec.region,
								rec.server,
								rec.name,
								rec.force,
								rec.level,
								rec.equip_score,
								rec.copy_info,
								rec.progress_info,
								rec.time,
								''
							)
						end
					end
					X.SQLiteEndTransaction(DB)
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			FireUIEvent('MY_ROLE_STAT_DUNGEON_UPDATE')
			X.Alert(_L['Migrate succeed!'])
		end)
end

function D.FlushDB(bForceUpdate)
	if not D.bReady or not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]

	local rec = X.Clone(D.GetClientPlayerRec(bForceUpdate))
	D.EncodeRow(rec)

	X.SQLiteBeginTransaction(DB)
	X.SQLitePrepareExecute(
		DB_DungeonInfoW,
		rec.guid, rec.account, rec.region, rec.server,
		rec.name, rec.force, rec.level, rec.equip_score,
		rec.copy_info, rec.progress_info, rec.time, ''
	)
	X.SQLiteEndTransaction(DB)

	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.OutputDebugMessage('MY_RoleStatistics_DungeonStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
end
X.RegisterFlush('MY_RoleStatistics_DungeonStat', function() D.FlushDB() end)

function D.InitDB()
	local me = X.GetClientPlayer()
	if me then
		local result = X.SQLitePrepareGetAll(DB_DungeonInfoG, AnsiToUTF8(X.GetClientPlayerGlobalID()))
		local rec = result[1]
		if rec then
			D.DecodeRow(rec)
			D.tMapSaveCopy = X.DecodeLUAData(rec.copy_info) or {}
			D.tMapProgress = X.DecodeLUAData(rec.progress_info) or {}
		end
	end
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
		X.OutputDebugMessage('MY_RoleStatistics_DungeonStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		X.SQLitePrepareExecute(DB_DungeonInfoD, AnsiToUTF8(X.GetClientPlayerGlobalID()))
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_RoleStatistics_DungeonStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_DUNGEON_UPDATE')
end

function D.GetColumns()
	local aCol = {}
	for _, id in ipairs(O.aColumn) do
		if id == 'week_team_dungeon' then
			for _, map in ipairs(X.GetActivityMap('WEEK_TEAM_DUNGEON')) do
				local col = COLUMN_DICT[GetDungeonMapColumnID(map.dwID, id)]
				if col then
					table.insert(aCol, col)
				end
			end
		elseif id == 'week_raid_dungeon' then
			for _, map in ipairs(X.GetActivityMap('WEEK_RAID_DUNGEON')) do
				local col = COLUMN_DICT[GetDungeonMapColumnID(map.dwID, id)]
				if col then
					table.insert(aCol, col)
				end
			end
		elseif id == 'recommend_team_dungeon' then
			for _, map in ipairs(X.GetRecommendDungeonMapList(false)) do
				local col = COLUMN_DICT[GetDungeonMapColumnID(map.dwID, id)]
				if col then
					table.insert(aCol, col)
				end
			end
		elseif id == 'recommend_raid_dungeon' then
			for _, map in ipairs(X.GetRecommendDungeonMapList(true)) do
				local col = COLUMN_DICT[GetDungeonMapColumnID(map.dwID, id)]
				if col then
					table.insert(aCol, col)
				end
			end
		else
			local col = COLUMN_DICT[id]
			if col then
				table.insert(aCol, col)
			end
		end
	end
	return aCol
end

function D.GetTableColumns()
	local aColumn = D.GetColumns()
	local nLFixIndex, nLFixWidth = -1, 0
	for nIndex, col in ipairs(aColumn) do
		nLFixWidth = nLFixWidth + (col.nMinWidth or 100)
		if nLFixWidth > 450 then
			break
		end
		if col.id == 'name' then
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
		if col.id == 'time' or col.id == 'time_days' then
			nRFixIndex = nIndex
		end
	end
	local aTableColumn = {}
	for nIndex, col in ipairs(aColumn) do
		local szFixed = nIndex <= nLFixIndex
			and 'left'
			or (nIndex >= nRFixIndex and 'right' or nil)
		local c = {
			key = col.id,
			title = col.szTitle,
			titleTip = col.szTitleTip or col.szTitle,
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
			draggable = not col.id:find('@') or not aColumn[nIndex - 1] or aColumn[nIndex - 1].id:gsub('.+@', '') ~= col.id:gsub('.+@', ''),
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
	local szUSearch = AnsiToUTF8('%' .. szSearch .. '%')
	local result = X.SQLitePrepareGetAll(DB_DungeonInfoR, szUSearch, szUSearch, szUSearch, szUSearch)

	for _, rec in ipairs(result) do
		D.DecodeRow(rec)
	end

	ui:Fetch('WndTable_Stat')
		:Columns(D.GetTableColumns())
		:DataSource(result)
end

function D.UpdateMapProgress(bForceUpdate)
	local me = X.GetClientPlayer()
	if not me then -- 确保不可能在切换GS时请求
		return
	end
	local tProgressBossMapID = {}
	-- 监控数据里的地图 ID
	for _, col in ipairs(D.GetColumns()) do
		local dwID = GetColumnDungeonMapID(col.id)
		if dwID then
			tProgressBossMapID[dwID] = true
		end
	end
	-- 已经有 CD 的地图 ID
	for k, v in pairs(D.tMapSaveCopy) do
		if v then
			tProgressBossMapID[k] = true
		end
	end
	-- 获取这些地图的进度
	for dwID, _ in pairs(tProgressBossMapID) do
		local aProgressBoss = dwID and X.IsCDProgressMap(dwID) and X.GetMapCDProgressInfo(dwID)
		if aProgressBoss then
			-- 强制刷新秘境进度，或者进度数据已过期并且5秒内未请求过，则发起请求
			if bForceUpdate or (not D.tMapProgressValid[dwID] and GetTime() - D.tMapProgressRequestTime[dwID] > 5000) then
				if not X.Contains(D.aMapProgressRequestQueue, dwID) then
					table.insert(D.aMapProgressRequestQueue, dwID)
				end
			end
			-- 检测是否有进度数据（修正脏数据标记位）
			local bMapProgressValid = D.tMapProgressValid[dwID]
			if not bMapProgressValid then
				for i, boss in ipairs(aProgressBoss) do
					if GetDungeonRoleProgress(dwID, X.GetClientPlayerID(), boss.dwProgressID) then
						bMapProgressValid = true
						break
					end
				end
			end
			-- 已经获取到进度的秘境，或者没有 CD 数据的秘境
			if bMapProgressValid or (D.bMapSaveCopyValid and not D.tMapSaveCopy[dwID]) then
				local aProgress = {}
				for i, boss in ipairs(aProgressBoss) do
					aProgress[i] = GetDungeonRoleProgress(dwID, X.GetClientPlayerID(), boss.dwProgressID)
				end
				D.tMapProgress[dwID] = aProgress
			end
		end
		D.ProcessProgressRequestQueue()
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
	rec.copy_info = X.EncodeLUAData(rec.copy_info)
	rec.progress_info = X.EncodeLUAData(rec.progress_info)
end

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
	rec.copy_info = X.DecodeLUAData(rec.copy_info or '') or {}
	rec.progress_info = X.DecodeLUAData(rec.progress_info or '') or {}
end

function D.GetDungeonRecTipInfo(rec, dwMapID)
	local col = COLUMN_DICT[GetDungeonMapColumnID(dwMapID)]
	if col then
		local a = {}
		local nMaxPlayerCount = select(3, GetMapParams(dwMapID))
		table.insert(a, GetFormatText(col.szTitle, 162, 255, 255, 0))
		table.insert(a, GetFormatText(':  ', 162, 255, 255, 0))
		table.insert(a, col.GetFormatText(rec))
		table.insert(a, GetFormatText('\n', 162, 255, 255, 255))
		return { dwMapID = dwMapID, nMaxPlayerCount = nMaxPlayerCount, szXml = table.concat(a) }
	else
		local map = X.GetMapInfo(dwMapID)
		local aCopyID = rec.copy_info[dwMapID]
		if map and aCopyID then
			local a = {}
			local nMaxPlayerCount = select(3, GetMapParams(dwMapID))
			table.insert(a, GetFormatText(map.szName, 162, 255, 255, 0))
			table.insert(a, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(a, GetFormatText(table.concat(aCopyID, ',')))
			table.insert(a, GetFormatText('\n', 162, 255, 255, 255))
			return { dwMapID = dwMapID, nMaxPlayerCount = nMaxPlayerCount, szXml = table.concat(a) }
		end
	end
end

function D.GetRowTip(rec, bFloat)
	local aXml = {}
	for _, id in ipairs(TIP_COLUMN) do
		if id == 'DUNGEON' then
			local aMapID = {}
			for _, col in ipairs(D.GetColumns()) do
				local dwMapID = GetColumnDungeonMapID(col.id)
				if dwMapID then
					table.insert(aMapID, dwMapID)
				end
			end
			for dwMapID, _ in pairs(rec.copy_info) do
				table.insert(aMapID, dwMapID)
			end
			local tDungeon, aDungeon = {}, {}
			for _, dwMapID in ipairs(aMapID) do
				local info = dwMapID and not tDungeon[dwMapID] and D.GetDungeonRecTipInfo(rec, dwMapID)
				if info then
					table.insert(aDungeon, info)
					tDungeon[dwMapID] = true
				end
			end
			table.sort(aDungeon, function(p1, p2)
				if p1.nMaxPlayerCount == p2.nMaxPlayerCount then
					return p1.dwMapID < p2.dwMapID
				end
				return p1.nMaxPlayerCount < p2.nMaxPlayerCount
			end)
			local nMaxPlayerCount = 0
			for _, p in ipairs(aDungeon) do
				if nMaxPlayerCount ~= p.nMaxPlayerCount then
					nMaxPlayerCount = p.nMaxPlayerCount
					table.insert(aXml, GetFormatText(_L('---- %d players dungeon ----', nMaxPlayerCount) .. '\n', 162, 255, 255, 0))
				end
				table.insert(aXml, p.szXml)
			end
		else
			local col = COLUMN_DICT[id]
			if col and (not bFloat or not col.bHideInFloat) then
				table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
				table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
				table.insert(aXml, col.GetFormatText(rec))
				table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
			end
		end
	end
	return table.concat(aXml)
end

function D.OutputRowTip(this, rec)
	local bFloat = this:GetRoot():GetName() ~= 'MY_RoleStatistics'
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local nPosType = bFloat and X.UI.TIP_POSITION.TOP_BOTTOM or X.UI.TIP_POSITION.RIGHT_LEFT
	OutputTip(D.GetRowTip(rec, bFloat), 450, {x, y, w, h}, nPosType)
end

function D.CloseRowTip()
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
					D.FlushDB(true)
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
				-- 秘境选项
				local tDungeonChecked = {}
				for _, id in ipairs(aColumn) do
					local dwID = GetColumnDungeonMapID(id)
					if dwID then
						tDungeonChecked[dwID] = true
					end
				end
				local tDungeonMenu = X.GetDungeonMenu({
					fnAction = function(info)
						fnAction(GetDungeonMapColumnID(info.dwID), DUNGEON_MIN_WIDTH)
					end,
					tChecked = tDungeonChecked,
					bStarveMap = false,
					bMonsterMap = false,
				})
				-- 动态活动秘境选项
				for _, szType in ipairs({
					'week_team_dungeon',
					'week_raid_dungeon',
					'recommend_team_dungeon',
					'recommend_raid_dungeon',
				}) do
					local col = COLUMN_DICT[szType]
					if col then
						table.insert(tDungeonMenu, {
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
				table.insert(t, tDungeonMenu)
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
				return D.GetRowTip(rec, false), true
			end,
			position = X.UI.TIP_POSITION.RIGHT_LEFT,
		},
		rowMenuRClick = function(rec, index)
			local menu = {
				{
					szOption = _L['Delete'],
					fnAction = function()
						X.SQLitePrepareExecute(DB_DungeonInfoD, AnsiToUTF8(rec.guid))
						D.UpdateUI(page)
					end,
					rgb = { 255, 128, 128 },
				},
			}
			PopupMenu(menu)
		end,
		onColumnsChange = function(aColumns)
			local tAccKeys, tAccKeySuffix = {}, {}
			for _, col in ipairs(D.GetTableColumns()) do
				if col.key:find('@') then
					local szSuffix = col.key:gsub('.+@', '')
					if not tAccKeySuffix[szSuffix] then
						tAccKeys[col.key] = true
						tAccKeySuffix[szSuffix] = true
					end
				else
					tAccKeys[col.key] = true
				end
			end
			local aKeys, tKeys = {}, {}
			for _, col in ipairs(aColumns) do
				if tAccKeys[col.key] then
					local szKey = col.key:gsub('.+@', '')
					if not tKeys[szKey] then
						table.insert(aKeys, szKey)
						tKeys[szKey] = true
					end
				end
			end
			O.aColumn = aKeys
			D.UpdateUI(page)
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS')
	frame:RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND')
	frame:RegisterEvent('MY_ROLE_STAT_DUNGEON_UPDATE')

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
	D.Migration()
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
		X.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			X.SQLitePrepareExecute(DB_DungeonInfoD, AnsiToUTF8(wnd.guid))
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Image_ProgressBoss' or name == 'Text_CD' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local aText = {}
		local map = X.GetMapInfo(this.mapid)
		if map then
			local szName = map.szName
			local aCD = D.tMapSaveCopy[map.dwID]
			if not X.IsEmpty(aCD) then
				szName = szName .. ' (' .. table.concat(aCD, ', ') .. ')'
			end
			table.insert(aText, szName)
		end
		if name == 'Image_ProgressBoss' then
			table.insert(aText, '')
			local aBossKill = X.SplitString(this.progress_info, ',')
			for i, boss in ipairs(X.GetMapCDProgressInfo(this.mapid)) do
				table.insert(aText, boss.szName .. '\t' .. _L[aBossKill[i] == '1' and 'x' or 'r'])
			end
		end
		table.insert(aText, '')
		local nTime = X.GetDungeonRefreshTime(this.mapid) - GetCurrentTime()
		table.insert(aText, _L('Refresh: %s', X.FormatDuration(nTime, 'CHINESE')))
		OutputTip(GetFormatText(table.concat(aText, '\n'), 162, 255, 255, 255), 400, { x, y, w, h })
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
	if bFloatEntry then
		if D.bFloatEntry then
			return
		end
		X.UI.RegisterFloatBar('MY_RoleStatistics_DungeonEntry', {
			nPriority = 100.2,
			tAnchor = { s = 'TOPLEFT', r = 'TOPLEFT', x = 370 - 5 + 72, y = 30 - 5 + 13 },
			fnCreate = function(wnd)
				wnd:SetSize(24, 24)
				local frameTemp = X.UI.OpenFrame(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_DungeonEntry.ini', 'MY_RoleStatistics_DungeonEntry')
				local btn = frameTemp:Lookup('Btn_MY_RoleStatistics_DungeonEntry')
				btn:ChangeRelation(wnd, true, true)
				btn:SetRelPos(2, 2)
				X.UI.CloseFrame(frameTemp)
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
			end,
		})
	else
		if not D.bFloatEntry then
			return
		end
		X.UI.RegisterFloatBar('MY_RoleStatistics_DungeonEntry', false)
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
	name = 'MY_RoleStatistics_DungeonStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnResizePage',
				szSaveDB = 'MY_RoleStatistics_DungeonStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_DungeonStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('DungeonStat', _L['MY_RoleStatistics_DungeonStat'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
MY_RoleStatistics_DungeonStat = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_RoleStatistics_DungeonStat', function()
	D.bReady = true
	D.UpdateFloatEntry()
end)

X.RegisterInit('MY_RoleStatistics_DungeonStat', function()
	X.DelayCall('MY_RoleStatistics_DungeonStat__InitMapProgress', 60000, function()
		D.UpdateMapProgress()
	end)
	D.InitDB()
end)

X.RegisterExit('MY_RoleStatistics_DungeonStat', function()
	if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
		D.UpdateMapProgress()
	end
end)

X.RegisterReload('MY_RoleStatistics_DungeonStat', function()
	D.ApplyFloatEntry(false)
end)

-- 首领死亡刷新秘境进度（秘境内同步拾取则视为进度更新）
X.RegisterEvent('SYNC_LOOT_LIST', 'MY_RoleStatistics_DungeonStat__UpdateMapCopy', function()
	if not D.bReady or not X.IsInDungeonMap() then
		return
	end
	local me = X.GetClientPlayer()
	if me then
		D.bMapSaveCopyValid = false
		D.tMapProgressValid[me.GetMapID()] = false
	end
	X.DelayCall('MY_RoleStatistics_DungeonStat__UpdateMapCopy', 300, function() D.UpdateMapProgress() end)
end)

X.RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS', function()
	local dwMapID, dwPlayerID = arg0, arg1
	if dwPlayerID ~= X.GetClientPlayerID() then
		return
	end
	D.tMapProgressValid[dwMapID] = true
	D.FlushDB()
end)

X.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', function()
	local tMapCopy = arg0
	D.tMapSaveCopy = tMapCopy
	D.bMapSaveCopyValid = true
	D.FlushDB()
end)

X.RegisterFrameCreate('Player', 'MY_RoleStatistics_DungeonStat', function()
	D.UpdateFloatEntry()
end)


--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
