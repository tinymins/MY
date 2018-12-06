--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 记录团队/好友/帮会/密聊 供日后查询
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild = MY.Get, MY.Set, MY.RandomChild
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local XML_LINE_BREAKER = XML_LINE_BREAKER

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_ChatLog/lang/')
if not MY.AssertVersion('MY_ChatLog', _L['MY_ChatLog'], 0x2011800) then
	return
end
MY_ChatLog = MY_ChatLog or {}
MY_ChatLog.bIgnoreTongOnlineMsg    = true -- 帮会上线通知
MY_ChatLog.bIgnoreTongMemberLogMsg = true -- 帮会成员上线下线提示
MY_ChatLog.bRealtimeCommit         = false-- 实时写入数据库
MY_ChatLog.tUncheckedChannel = {}
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')
RegisterCustomData('MY_ChatLog.bRealtimeCommit')
RegisterCustomData('MY_ChatLog.tUncheckedChannel')

------------------------------------------------------------------------------------------------------
-- 数据采集
------------------------------------------------------------------------------------------------------
local TONG_ONLINE_MSG        = '^' .. MY.EscapeString(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG)
local TONG_MEMBER_LOGIN_MSG  = '^' .. MY.EscapeString(g_tStrings.STR_GUILD_MEMBER_LOGIN):gsub('<link 0>', '.-') .. '$'
local TONG_MEMBER_LOGOUT_MSG = '^' .. MY.EscapeString(g_tStrings.STR_GUILD_MEMBER_LOGOUT):gsub('<link 0>', '.-') .. '$'

------------------------------------------------------------------------------------------------------
-- 数据库核心
------------------------------------------------------------------------------------------------------
local PAGE_AMOUNT = 150
local EXPORT_SLICE = 100
local PAGE_DISPLAY = 14
local DIVIDE_TABLE_AMOUNT = 30000 -- 如果某张表大小超过30000
local SINGLE_TABLE_AMOUNT = 20000 -- 则将最久远的20000条消息独立成表
local SZ_INI = MY.GetAddonInfo().szRoot .. 'MY_ChatLog/ui/MY_ChatLog.ini'
local LOG_TYPE = {
	{id = 'whisper', title = g_tStrings.tChannelName['MSG_WHISPER'       ], channels = {'MSG_WHISPER'       }},
	{id = 'party'  , title = g_tStrings.tChannelName['MSG_PARTY'         ], channels = {'MSG_PARTY'         }},
	{id = 'team'   , title = g_tStrings.tChannelName['MSG_TEAM'          ], channels = {'MSG_TEAM'          }},
	{id = 'friend' , title = g_tStrings.tChannelName['MSG_FRIEND'        ], channels = {'MSG_FRIEND'        }},
	{id = 'guild'  , title = g_tStrings.tChannelName['MSG_GUILD'         ], channels = {'MSG_GUILD'         }},
	{id = 'guild_a', title = g_tStrings.tChannelName['MSG_GUILD_ALLIANCE'], channels = {'MSG_GUILD_ALLIANCE'}},
	{id = 'death'  , title = _L['Death Log'], channels = {'MSG_SELF_DEATH', 'MSG_SELF_KILL', 'MSG_PARTY_DEATH', 'MSG_PARTY_KILL'}},
	{id = 'journal', title = _L['Journal Log'], channels = {
		'MSG_MONEY', 'MSG_ITEM', --'MSG_EXP', 'MSG_REPUTATION', 'MSG_CONTRIBUTE', 'MSG_ATTRACTION', 'MSG_PRESTIGE',
		-- 'MSG_TRAIN', 'MSG_MENTOR_VALUE', 'MSG_THEW_STAMINA', 'MSG_TONG_FUND'
	}},
	{id = 'monitor', title = _L['MY Monitor'], channels = {'MSG_MY_MONITOR'}},
}
-- 频道对应数据库中数值 可添加 但不可随意修改
local CHANNELS = {
	[1] = 'MSG_WHISPER',
	[2] = 'MSG_PARTY',
	[3] = 'MSG_TEAM',
	[4] = 'MSG_FRIEND',
	[5] = 'MSG_GUILD',
	[6] = 'MSG_GUILD_ALLIANCE',
	[7] = 'MSG_SELF_DEATH',
	[8] = 'MSG_SELF_KILL',
	[9] = 'MSG_PARTY_DEATH',
	[10] = 'MSG_PARTY_KILL',
	[11] = 'MSG_MONEY',
	[12] = 'MSG_EXP',
	[13] = 'MSG_ITEM',
	[14] = 'MSG_REPUTATION',
	[15] = 'MSG_CONTRIBUTE',
	[16] = 'MSG_ATTRACTION',
	[17] = 'MSG_PRESTIGE',
	[18] = 'MSG_TRAIN',
	[19] = 'MSG_MENTOR_VALUE',
	[20] = 'MSG_THEW_STAMINA',
	[21] = 'MSG_TONG_FUND',
	[22] = 'MSG_MY_MONITOR',
}
local CHANNELS_R = (function() local t = {} for k, v in pairs(CHANNELS) do t[v] = k end return t end)()
local MSGTYPE_COLOR = setmetatable({
	['MSG_MY_MONITOR'] = {255, 255, 0},
}, {__index = function(t, k) return GetMsgFontColor(k, true) end})

local DB, ConnectDB, InsertMsg, DeleteMsg, PushDB, GetChatLogCount, GetChatLog, OptimizeDB, FixSearchDB, ImportDB
do
local STMT = {}
local l_globalid
local l_initialized
local aInsQueue = {}
local aDelQueue = {}
-- ===== 性能测试 =====
-- local msg  = AnsiToUTF8(g_tStrings.STR_TONG_BAO_DESC)
-- local text = AnsiToUTF8(GetPureText(g_tStrings.STR_TONG_BAO_DESC))
-- local hash = GetStringCRC(msg)
-- local channel = CHANNELS_R['MSG_WORLD']
-- for i = 1, 60000 do
-- 	table.insert(aInsQueue, {hash, channel, GetCurrentTime() - i * 30, 'tester', text, msg})
-- end

function InsertMsg(channel, text, msg, talker, time)
	local hash
	msg    = AnsiToUTF8(msg or '') or ''
	text   = AnsiToUTF8(text or '') or ''
	hash   = GetStringCRC(msg)
	talker = talker and AnsiToUTF8(talker or '') or ''
	if not channel or not time or empty(msg) or not text or empty(hash) then
		return
	end
	insert(aInsQueue, {hash, channel, time, talker, text, msg})
end

function DeleteMsg(hash, time)
	if not time or empty(hash) then
		return
	end
	table.insert(aDelQueue, {hash, time})
end

local function CreateTable()
	local name
	repeat
		name = ('ChatLog_%x'):format(math.random(0x100000, 0xFFFFFF))
	until DB:Execute('SELECT count(*) AS count FROM sqlite_master WHERE type = \'table\' AND name = \'' .. name .. '\'')[1].count == 0
	DB:Execute('CREATE TABLE IF NOT EXISTS ' .. name .. ' (hash INTEGER, channel INTEGER, time INTEGER, talker NVARCHAR(20), text NVARCHAR(400) NOT NULL, msg NVARCHAR(4000) NOT NULL, PRIMARY KEY (time, hash))')
	DB:Execute('CREATE INDEX IF NOT EXISTS ' .. name .. '_channel_idx ON ' .. name .. '(channel)')
	DB:Execute('CREATE INDEX IF NOT EXISTS ' .. name .. '_talker_idx ON ' .. name .. '(talker)')
	DB:Execute('CREATE INDEX IF NOT EXISTS ' .. name .. '_text_idx ON ' .. name .. '(text)')
	return name
end

local function InitDB(force)
	MY.Debug({'Initializing database...'}, 'MY_ChatLog', MY_DEBUG.LOG)

	-- 数据库写入基本信息
	DB:Execute('CREATE TABLE IF NOT EXISTS ChatLogInfo (key NVARCHAR(128), value NVARCHAR(4096), PRIMARY KEY (key))')
	DB:Execute('REPLACE INTO ChatLogInfo (key, value) VALUES (\'userguid\', \'' .. l_globalid .. '\')')

	-- 初始化聊天记录索引表
	if DB:Execute('SELECT count(*) AS count FROM sqlite_master WHERE type = \'table\' AND name = \'ChatLogIndex\'')[1].count == 0 then
		-- 判断是否会卡 给予提示
		if not force then
			local confirmtext
			local result = DB:Execute('SELECT * FROM ChatLog LIMIT 1 OFFSET 50000')
			if result and result[1] then
				confirmtext = _L('You have over %d chatlogs requires to be transformed before use ChatLog, this may take a few minutes and may cause a disconnection, continue?', 50000)
			else
				local result = DB:Execute('SELECT count(*) AS count FROM ChatLog')
				if result and result[1] and result[1].count then
					confirmtext = _L('You have %d chatlogs requires to be transformed before use ChatLog, this may take a few minutes and may cause a disconnection, continue?', result[1].count)
				end
			end
			if confirmtext then
				MY.Confirm(confirmtext, function()
					OptimizeDB(true)
				end)
				return MY.Debug({'Initializing database performance alert...'}, 'MY_ChatLog', MY_DEBUG.LOG)
			end
		end
		-- 开始初始化
		MY.Debug({'Creating database...'}, 'MY_ChatLog', MY_DEBUG.LOG)
		DB:Execute('BEGIN TRANSACTION')
		DB:Execute('DROP TABLE IF EXISTS ChatLogUser')
		-- 创建索引表
		DB:Execute('CREATE TABLE IF NOT EXISTS ChatLogIndex (name NVARCHAR(100), stime INTEGER, etime INTEGER, count INTEGER, detailcount NVARCHAR(4000), PRIMARY KEY (name))')
		DB:Execute('CREATE INDEX IF NOT EXISTS ChatLogIndex_stime_idx ON ChatLogIndex(stime)')
		-- 创建第一张记录表 并迁徙历史记录
		local name = CreateTable()
		MY.Debug({'Importing chatlog from v1 version...'}, 'MY_ChatLog', MY_DEBUG.LOG)
		local result = DB:Execute('SELECT name FROM sqlite_master WHERE type = \'table\' AND (name = \'ChatLog\' OR name LIKE \'ChatLog/_%/_%\' ESCAPE \'/\') ORDER BY name')
		for _, rec in ipairs(result) do
			DB:Execute('REPLACE INTO ' .. name .. ' SELECT * FROM ' .. rec.name)
			DB:Execute('DROP TABLE ' .. rec.name)
		end
		DB:Execute('REPLACE INTO ChatLogIndex (name, stime, etime, count, detailcount) VALUES (\'' .. name .. '\', 0, -1, (SELECT count(*) FROM ' .. name .. '), \'\')')
		MY.Debug({'Importing chatlog from v1 version finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)

		DB:Execute('END TRANSACTION')
		MY.Debug({'Creating database finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	end
	l_initialized = true
	MY.Debug({'Initializing database finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)

	-- 导入旧版数据
	local SZ_OLD_PATH = MY.FormatPath('userdata/CHAT_LOG/$uid/') -- %s/%s.$lang.jx3dat
	if IsLocalFileExist(SZ_OLD_PATH) then
		MY.Debug({'Importing old data...'}, 'MY_ChatLog', MY_DEBUG.LOG)
		local nScanDays = 365 * 3
		local nDailySec = 24 * 3600
		local date = TimeToDate(GetCurrentTime())
		local dwEndedTime = GetCurrentTime() - date.hour * 3600 - date.minute * 60 - date.second
		local dwStartTime = dwEndedTime - nScanDays * nDailySec
		local nHour, nMin, nSec
		local function regexp(...)
			nHour, nMin, nSec = ...
			return ''
		end
		local szTalker
		local function regexpN(...)
			szTalker = ...
		end
		for _, szChannel in ipairs({'MSG_WHISPER', 'MSG_PARTY', 'MSG_TEAM', 'MSG_FRIEND', 'MSG_GUILD', 'MSG_GUILD_ALLIANCE'}) do
			local SZ_CHANNEL_PATH = SZ_OLD_PATH .. szChannel .. '/'
			if IsLocalFileExist(SZ_CHANNEL_PATH) then
				for dwTime = dwStartTime, dwEndedTime, nDailySec do
					local szDate = MY.FormatTime('yyyyMMdd', dwTime)
					local data = MY.LoadLUAData(SZ_CHANNEL_PATH .. szDate .. '.$lang.jx3dat')
					if data then
						for _, szMsg in ipairs(data) do
							nHour, nMin, nSec, szTalker = nil
							szMsg = szMsg:gsub('<text>text="%[(%d+):(%d+):(%d+)%]".-</text>', regexp)
							szMsg:gsub('text="%[([^"<>]-)%]"[^<>]-name="namelink_', regexpN)
							if nHour and nMin and nSec and szTalker then
								InsertMsg(CHANNELS_R[szChannel], GetPureText(szMsg), szMsg, szTalker, dwTime + nHour * 3600 + nMin * 60 + nSec)
							end
						end
					end
				end
			end
		end
		PushDB()
		CPath.DelDir(SZ_OLD_PATH)
		MY.Debug({'Importing old data finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	end
end

function ConnectDB(force)
	if not DB then
		local DB_PATH = MY.FormatPath({'userdata/chat_log.db', MY_DATA_PATH.ROLE})
		local SZ_OLD_PATH = MY.FormatPath('userdata/CHAT_LOG/$uid.db')
		if IsLocalFileExist(SZ_OLD_PATH) then
			CPath.Move(SZ_OLD_PATH, DB_PATH)
		end
		MY.ConnectDatabase(_L['chat log'], DB_PATH, function(arg0)
			DB = arg0
			if not DB then
				return MY.Debug({'Cannot connect to database!!!'}, 'MY_ChatLog', MY_DEBUG.ERROR)
			end
			InitDB(force)
		end)
	elseif not l_initialized then
		InitDB(force)
	end
	return l_initialized
end

function ImportDB(file)
	if not (IsLocalFileExist(file) and ConnectDB(true)) then
		return
	end
	local amount, count = 0
	local DBI = SQLite3_Open(file)
	local tables = DBI:Execute('SELECT name FROM sqlite_master WHERE type = \'table\' AND (name = \'ChatLog\' OR name LIKE \'ChatLog/_%\' ESCAPE \'/\') ORDER BY name')
	for _, rec in ipairs(tables) do
		count = DBI:Execute('SELECT count(*) AS count FROM ' .. rec.name)[1].count
		for index = 0, count, 100000 do
			local result = DBI:Execute('SELECT * FROM ' .. rec.name .. ' ORDER BY time ASC LIMIT 100000 OFFSET ' .. index)
			for _, rec in ipairs(result) do
				insert(aInsQueue, {rec.hash, rec.channel, rec.time, rec.talker, rec.text, rec.msg})
			end
			amount = amount + #result
			PushDB()
			OptimizeDB(false)
		end
	end
	return amount
end

function FixSearchDB(deep)
	if not ConnectDB(true) then
		return
	end
	MY.Debug({'Fixing chatlog search indexes...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	local count = 0
	DB:Execute('BEGIN TRANSACTION')
	local tables = DB:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC')
	for _, info in ipairs(tables) do
		local DB_W = DB:Prepare('UPDATE ' .. info.name .. ' SET text = ? WHERE hash = ? and time = ?')
		local result = DB:Execute('SELECT hash, time, msg FROM ' .. info.name .. (deep and '' or ' WHERE text = \'\''))
		for _, rec in ipairs(result) do
			DB_W:ClearBindings()
			DB_W:BindAll(AnsiToUTF8(GetPureText(UTF8ToAnsi(rec.msg) or '') or '') or '', rec.hash, rec.time)
			DB_W:Execute()
		end
		count = count + #result
	end
	DB:Execute('END TRANSACTION')
	MY.Debug({'Fixing chatlog search indexes finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	return count
end

function OptimizeDB(deep)
	if not ConnectDB(true) then
		return
	end
	DB:Execute('BEGIN TRANSACTION')

	-- 删除不在监控的频道
	if deep then
		MY.Debug({'Deleting unwatched channels...'}, 'MY_ChatLog', MY_DEBUG.LOG)
		local tables = DB:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC')
		-- 枚举所有监控的频道
		local where = ''
		local tChannels, aWheres = {}, {}
		for _, info in ipairs(LOG_TYPE) do
			for _, szChannel in ipairs(info.channels) do
				tChannels[szChannel] = true
			end
		end
		for szChannel, _ in pairs(tChannels) do
			insert(aWheres, 'channel <> ' .. CHANNELS_R[szChannel])
		end
		if #aWheres > 0 then
			where = ' WHERE ' .. concat(aWheres, ' AND ')
		end
		for i, info in ipairs(tables) do
			DB:Execute('DELETE FROM ' .. info.name .. where)
			DB:Execute('UPDATE ChatLogIndex SET count = (SELECT count(*) FROM ' .. info.name .. '), detailcount = \'\' WHERE name = \'' .. info.name .. '\'')
		end
		MY.Debug({'Deleting unwatched channels finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	end

	-- 拆记录中的大表
	local tables = DB:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC')
	for i, info in ipairs(tables) do
		if info.count > DIVIDE_TABLE_AMOUNT then
			MY.Debug({'Dividing large chatlog table: ' .. info.name}, 'MY_ChatLog', MY_DEBUG.LOG)
			-- 确定分割点
			local etime = DB:Execute('SELECT time FROM ' .. info.name .. ' ORDER BY time ASC LIMIT 1 OFFSET ' .. (SINGLE_TABLE_AMOUNT - 1))[1].time
			-- 创建新表/调整旧表
			local newinfo = {
				name  = CreateTable(),
				stime = info.stime,
				etime = etime,
			}
			insert(tables, i, newinfo)
			info.stime = newinfo.etime + 1
			-- 转移数据
			DB:Execute('REPLACE INTO ' .. newinfo.name .. ' SELECT * FROM ' .. info.name .. ' WHERE time <= ' .. etime)
			DB:Execute('DELETE FROM ' .. info.name .. ' WHERE time <= ' .. etime)
			-- 更新数量索引
			info.count = DB:Execute('SELECT count(*) AS count FROM ' .. info.name)[1].count
			DB:Execute('REPLACE INTO ChatLogIndex (name, stime, etime, count, detailcount) VALUES (\''
				.. info.name .. '\', ' .. info.stime .. ', ' .. info.etime .. ', ' .. info.count .. ', \'\')')
			newinfo.count = DB:Execute('SELECT count(*) AS count FROM ' .. newinfo.name)[1].count
			DB:Execute('REPLACE INTO ChatLogIndex (name, stime, etime, count, detailcount) VALUES (\''
				.. newinfo.name .. '\', ' .. newinfo.stime .. ', ' .. newinfo.etime .. ', ' .. newinfo.count .. ', \'\')')
			MY.Debug({'Dividing large chatlog table ' .. info.name .. ' -> ' .. newinfo.name .. ' finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
		end
	end

	-- 合并记录中的小表
	if deep then
		local tables = DB:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC')
		for i, info in ipairs(tables) do
			local nextinfo = tables[i + 1]
			if nextinfo and (info.count + nextinfo.count) <= DIVIDE_TABLE_AMOUNT then
				MY.Debug({'Merging small chatlog table: ' .. info.name .. ', ' .. nextinfo.name}, 'MY_ChatLog', MY_DEBUG.LOG)
				DB:Execute('REPLACE INTO ' .. info.name .. ' SELECT * FROM ' .. nextinfo.name)
				DB:Execute('DROP TABLE ' .. nextinfo.name)
				DB:Execute('UPDATE ChatLogIndex SET count = (SELECT count(*) FROM ' .. info.name .. '), detailcount = \'\', etime = ' .. nextinfo.etime .. ' WHERE name = \'' .. info.name .. '\'')
				DB:Execute('DELETE FROM ChatLogIndex WHERE name = \'' .. nextinfo.name .. '\'')
				remove(tables, i + 1)
				MY.Debug({'Merging small chatlog table (' .. info.name .. ', ' .. nextinfo.name .. ') finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
			end
		end
	end

	DB:Execute('END TRANSACTION')
	if deep then
		MY.Debug({'Compressing database...'}, 'MY_ChatLog', MY_DEBUG.LOG)
		DB:Execute('VACUUM')
		MY.Debug({'Compressing database finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	end
end

function PushDB()
	if #aInsQueue == 0 and #aDelQueue == 0 then
		return MY.Debug({'Pushing to database skipped due to empty queue...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	elseif not ConnectDB() then
		return MY.Debug({'Database has not been initialized yet, PushDB failed.'}, 'MY_ChatLog', MY_DEBUG.ERROR)
	end
	MY.Debug({'Pushing to database...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	local tables = DB:Execute('SELECT * FROM ChatLogIndex ORDER BY stime DESC')
	DB:Execute('BEGIN TRANSACTION')
	-- 插入记录
	for _, data in ipairs(aInsQueue) do
		for _, info in ipairs(tables) do
			if data[3] >= info.stime and (info.etime == -1 or data[3] <= info.etime) then
				if not info.stmtIns then
					info.stmtIns = DB:Prepare('REPLACE INTO ' .. info.name .. ' (hash, channel, time, talker, text, msg) VALUES (?, ?, ?, ?, ?, ?)')
				end
				info.stmtIns:ClearBindings()
				info.stmtIns:BindAll(unpack(data))
				info.stmtIns:Execute()
				break
			end
		end
	end
	aInsQueue = {}
	-- 删除记录
	for _, data in ipairs(aDelQueue) do
		for _, info in ipairs(tables) do
			if data[2] >= info.stime and (info.etime == -1 or data[2] <= info.etime) then
				if not info.stmtDel then
					info.stmtDel = DB:Prepare('DELETE FROM ' .. info.name .. ' WHERE hash = ? AND time = ?')
				end
				info.stmtDel:ClearBindings()
				info.stmtDel:BindAll(unpack(data))
				info.stmtDel:Execute()
				break
			end
		end
	end
	aDelQueue = {}
	-- 更新记录索引
	local stmtUpd = DB:Execute('UPDATE ChatLogIndex SET count = ?, detailcount = \'\' WHERE name = ?')
	for _, info in ipairs(tables) do
		if info.stmtIns or info.stmtDel then
			DB:Execute('UPDATE ChatLogIndex SET count = (SELECT count(*) FROM ' .. info.name .. '), detailcount = \'\' WHERE name = \'' .. info.name .. '\'')
		end
	end
	DB:Execute('END TRANSACTION')
	MY.Debug({'Pushing to database finished...'}, 'MY_ChatLog', MY_DEBUG.LOG)
	FireUIEvent('ON_MY_CHATLOG_PUSHDB')
end

local function GetChatLogTableCount(channels, search)
	local stmtUpd
	local usearch = AnsiToUTF8('%' .. search .. '%')
	local tables  = DB:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC')
	for _, info in ipairs(tables) do
		info.detailcountcache = info.detailcount and MY.JsonDecode(info.detailcount)
		if not info.detailcountcache then
			info.detailcountcache = {list = {}, cache = {}}
		end
		if not info.detailcountcache.cache[search] then
			-- 创建缓存
			insert(info.detailcountcache.list, 1, search)
			info.detailcountcache.cache[search] = {}
			local result
			if search == '' then
				result = DB:Execute('SELECT channel, count(*) AS count FROM ' .. info.name .. ' GROUP BY channel')
			else
				local stmtSel = DB:Prepare('SELECT channel, count(*) AS count FROM ' .. info.name .. ' WHERE talker LIKE ? OR text LIKE ? GROUP BY channel')
				stmtSel:ClearBindings()
				stmtSel:BindAll(usearch, usearch)
				result = stmtSel:GetAll()
			end
			for _, rec in ipairs(result) do
				info.detailcountcache.cache[search][rec.channel] = rec.count
			end
			-- 缓存最大5个
			while info.detailcountcache.list[6] do
				local index = info.detailcountcache.list[6] == '' and 5 or 6
				info.detailcountcache.cache[info.detailcountcache.list[index]] = nil
				remove(info.detailcountcache.list, index)
			end
			-- 保存缓存
			if not stmtUpd then
				stmtUpd = DB:Prepare('UPDATE ChatLogIndex SET detailcount = ? WHERE name = ?')
			end
			stmtUpd:ClearBindings()
			stmtUpd:BindAll(MY.JsonEncode(info.detailcountcache), info.name)
			stmtUpd:Execute()
		end
	end
	return tables
end

function GetChatLogCount(channels, search)
	local count   = 0
	local tables  = GetChatLogTableCount(channels, search)
	for _, info in ipairs(tables) do
		for _, channel in ipairs(channels) do
			if info.detailcountcache.cache[search][channel] then
				count = count + info.detailcountcache.cache[search][channel]
			end
		end
	end
	return count
end

function GetChatLog(channels, search, offset, limit)
	local DB_R, wheres, values = nil, {}, {}
	for _, channel in ipairs(channels) do
		insert(wheres, 'channel = ?')
		insert(values, channel)
	end
	local sql  = ''
	local where = ''
	if #wheres > 0 then
		where = where .. ' (' .. concat(wheres, ' OR ') .. ')'
	else
		where = ' 1 = 0'
	end
	if search ~= '' then
		if #where > 0 then
			where = where .. ' AND'
		end
		where = where .. ' (talker LIKE ? OR text LIKE ?)'
		insert(values, AnsiToUTF8('%' .. search .. '%'))
		insert(values, AnsiToUTF8('%' .. search .. '%'))
	end
	if #where > 0 then
		sql  = sql .. ' WHERE' .. where
	end
	insert(values, limit)
	insert(values, offset)
	sql = sql .. ' ORDER BY time ASC LIMIT ? OFFSET ?'

	local index, count, result, data = 0, 0, {}, nil
	local tables  = GetChatLogTableCount(channels, search)
	for _, info in ipairs(tables) do
		if limit == 0 then
			break
		end
		count = 0
		for _, channel in ipairs(channels) do
			if info.detailcountcache.cache[search][channel] then
				count = count + info.detailcountcache.cache[search][channel]
			end
		end
		offset = max(offset - count, 0)
		if index >= offset and count > 0 then
			DB_R = DB:Prepare('SELECT * FROM ' .. info.name .. sql)
			DB_R:ClearBindings()
			values[#values - 1] = limit
			values[#values] = offset
			DB_R:BindAll(unpack(values))
			data = DB_R:GetAll()
			for _, rec in ipairs(data) do
				if rec.hash == GetStringCRC(rec.msg) then
					insert(result, rec)
				end
			end
			limit = max(limit - #data, 0)
		end
		index = index + count
	end

	return result
end

local function InitMsgMon()
	local me = GetClientPlayer()
	l_globalid = me.GetGlobalID()

	local tChannels, aChannels = {}, {}
	for _, info in ipairs(LOG_TYPE) do
		for _, szChannel in ipairs(info.channels) do
			tChannels[szChannel] = true
		end
	end
	for szChannel, _ in pairs(tChannels) do
		insert(aChannels, szChannel)
	end
	local function OnMsg(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szTalker)
		local szText = szMsg
		if bRich then
			szText = GetPureText(szMsg)
		else
			szMsg = GetFormatText(szMsg, nFont, r, g, b)
		end
		-- filters
		if szChannel == 'MSG_GUILD' then
			if MY_ChatLog.bIgnoreTongOnlineMsg and szText:find(TONG_ONLINE_MSG) then
				return
			end
			if MY_ChatLog.bIgnoreTongMemberLogMsg and (
				szText:find(TONG_MEMBER_LOGIN_MSG) or szText:find(TONG_MEMBER_LOGOUT_MSG)
			) then
				return
			end
		end
		InsertMsg(CHANNELS_R[szChannel], szText, szMsg, szTalker, GetCurrentTime())

		if MY_ChatLog.bRealtimeCommit then
			PushDB()
		end
	end
	MY.RegisterMsgMonitor('MY_ChatLog', OnMsg, aChannels)
	MY.RegisterEvent('LOADING_ENDING.MY_ChatLog_Save', PushDB)
	MY.RegisterIdle('MY_ChatLog_Save', PushDB)
end
MY.RegisterInit('MY_ChatLog_InitMon', InitMsgMon)

local function ReleaseDB()
	if not ConnectDB(true) then
		return
	end
	PushDB()
	OptimizeDB(false)
	DB:Release()
end
MY.RegisterExit('MY_Chat_Release', ReleaseDB)
MY.RegisterEvent('DISCONNECT.MY_Chat_Release', ReleaseDB)
end

function MY_ChatLog.Open()
	if not ConnectDB() then
		return
	end
	Wnd.OpenWindow(SZ_INI, 'MY_ChatLog'):BringToTop()
end

function MY_ChatLog.Close()
	Wnd.CloseWindow('MY_ChatLog')
end

function MY_ChatLog.IsOpened()
	return Station.Lookup('Normal/MY_ChatLog')
end

function MY_ChatLog.Toggle()
	if MY_ChatLog.IsOpened() then
		MY_ChatLog.Close()
	else
		MY_ChatLog.Open()
	end
end

function MY_ChatLog.OnFrameCreate()
	if type(MY_ChatLog.tUncheckedChannel) ~= 'table' then
		MY_ChatLog.tUncheckedChannel = {}
	end
	local container = this:Lookup('Window_Main/WndScroll_ChatChanel/WndContainer_ChatChanel')
	container:Clear()
	for _, info in pairs(LOG_TYPE) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_ChatChannel')
		wnd.id = info.id
		wnd.aChannels = info.channels
		wnd:Lookup('CheckBox_ChatChannel'):Check(not MY_ChatLog.tUncheckedChannel[info.id], WNDEVENT_FIRETYPE.PREVENT)
		wnd:Lookup('CheckBox_ChatChannel', 'Text_ChatChannel'):SetText(info.title)
		wnd:Lookup('CheckBox_ChatChannel', 'Text_ChatChannel'):SetFontColor(unpack(MSGTYPE_COLOR[info.channels[1]]))
	end
	container:FormatAllContentPos()

	local handle = this:Lookup('Window_Main/Wnd_Index', 'Handle_IndexesOuter/Handle_Indexes')
	handle:Clear()
	for i = 1, PAGE_DISPLAY do
		handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
	end
	handle:FormatAllItemPos()

	local handle = this:Lookup('Window_Main/WndScroll_ChatLog', 'Handle_ChatLogs')
	handle:Clear()
	for i = 1, PAGE_AMOUNT do
		handle:AppendItemFromIni(SZ_INI, 'Handle_ChatLog')
	end
	handle:FormatAllItemPos()

	this:Lookup('', 'Text_Title'):SetText(_L['MY - MY_ChatLog'])
	this:Lookup('Window_Main/Wnd_Search/Edit_Search'):SetPlaceholderText(_L['press enter to search ...'])

	MY_ChatLog.UpdatePage(this)
	this:RegisterEvent('ON_MY_MOSAICS_RESET')
	this:RegisterEvent('ON_MY_CHATLOG_PUSHDB')

	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
end

function MY_ChatLog.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		MY_ChatLog.UpdatePage(this, true)
	elseif event == 'ON_MY_CHATLOG_PUSHDB' then
		MY_ChatLog.UpdatePage(this, true, true)
	end
end

function MY_ChatLog.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		MY_ChatLog.Close()
	elseif name == 'Btn_Only' then
		local wnd = this:GetParent()
		local parent = wnd:GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_ChatChannel'):Check(false, WNDEVENT_FIRETYPE.PREVENT)
		end
		wnd:Lookup('CheckBox_ChatChannel'):Check(true)
	end
end

function MY_ChatLog.OnCheckBoxCheck()
	this:GetRoot().nCurrentPage = nil
	this:GetRoot().nLastClickIndex = nil
	MY_ChatLog.UpdatePage(this:GetRoot())
end

function MY_ChatLog.OnCheckBoxUncheck()
	this:GetRoot().nCurrentPage = nil
	this:GetRoot().nLastClickIndex = nil
	MY_ChatLog.UpdatePage(this:GetRoot())
end

function MY_ChatLog.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Index' then
		this:GetRoot().nCurrentPage = this.nPage
		MY_ChatLog.UpdatePage(this:GetRoot())
	elseif name == 'Handle_ChatLog' then
		local nLastClickIndex = this:GetRoot().nLastClickIndex
		if IsCtrlKeyDown() then
			this:Lookup('Shadow_ChatLogSelect'):SetVisible(not this:Lookup('Shadow_ChatLogSelect'):IsVisible())
		elseif IsShiftKeyDown() then
			if nLastClickIndex then
				local hList, hItem = this:GetParent()
				for i = nLastClickIndex, this:GetIndex(), (nLastClickIndex - this:GetIndex() > 0 and -1 or 1) do
					hItem = hList:Lookup(i)
					if hItem:IsVisible() then
						hItem:Lookup('Shadow_ChatLogSelect'):Show()
					end
				end
			end
		else
			local hList, hItem = this:GetParent()
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if hItem:IsVisible() then
					hItem:Lookup('Shadow_ChatLogSelect'):Hide()
				end
			end
			this:Lookup('Shadow_ChatLogSelect'):Show()
		end
		this:GetRoot().nLastClickIndex = this:GetIndex()
	end
end

function MY_ChatLog.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'WndEdit_Index' then
			frame.nCurrentPage = tonumber(this:GetText()) or frame.nCurrentPage
		end
		MY_ChatLog.UpdatePage(this:GetRoot())
		return 1
	end
end

function MY_ChatLog.OnItemRButtonClick()
	local this = this
	local name = this:GetName()
	if name == 'Handle_ChatLog' then
		local nLastClickIndex = this:GetRoot().nLastClickIndex
		if IsCtrlKeyDown() then
			this:Lookup('Shadow_ChatLogSelect'):SetVisible(not this:Lookup('Shadow_ChatLogSelect'):IsVisible())
		elseif IsShiftKeyDown() then
			if nLastClickIndex then
				local hList, hItem = this:GetParent()
				for i = nLastClickIndex, this:GetIndex(), (nLastClickIndex - this:GetIndex() > 0 and -1 or 1) do
					hItem = hList:Lookup(i)
					if hItem:IsVisible() then
						hItem:Lookup('Shadow_ChatLogSelect'):Show()
					end
				end
			end
		elseif not this:Lookup('Shadow_ChatLogSelect'):IsVisible() then
			local hList, hItem = this:GetParent()
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if hItem:IsVisible() then
					hItem:Lookup('Shadow_ChatLogSelect'):Hide()
				end
			end
			this:Lookup('Shadow_ChatLogSelect'):Show()
		end
		this:GetRoot().nLastClickIndex = this:GetIndex()

		local menu = {
			{
				szOption = _L['delete record'],
				fnAction = function()
					local hList, hItem = this:GetParent()
					for i = 0, hList:GetItemCount() - 1 do
						hItem = hList:Lookup(i)
						if hItem:IsVisible() and hItem:Lookup('Shadow_ChatLogSelect'):IsVisible() then
							DeleteMsg(hItem.hash, hItem.time)
						end
					end
					this:GetRoot().nLastClickIndex = nil
					MY_ChatLog.UpdatePage(this:GetRoot(), true)
				end,
			}, {
				szOption = _L['copy this record'],
				fnAction = function()
					MY.CopyChatLine(this:Lookup('Handle_ChatLog_Msg'):Lookup(0), true)
				end,
			}
		}
		PopupMenu(menu)
	end
end

function MY_ChatLog.UpdatePage(frame, noscroll, nopushdb)
	if not nopushdb then
		PushDB()
	end
	local container = frame:Lookup('Window_Main/WndScroll_ChatChanel/WndContainer_ChatChanel')
	local channels = {}
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup('CheckBox_ChatChannel'):IsCheckBoxChecked() then
			for _, szChannel in ipairs(wnd.aChannels) do
				insert(channels, CHANNELS_R[szChannel])
			end
			MY_ChatLog.tUncheckedChannel[wnd.id] = nil
		else
			MY_ChatLog.tUncheckedChannel[wnd.id] = true
		end
	end
	local search = frame:Lookup('Window_Main/Wnd_Search/Edit_Search'):GetText()

	local nCount = GetChatLogCount(channels, search)
	local nPageCount = ceil(nCount / PAGE_AMOUNT)
	local bInit = not frame.nCurrentPage
	if bInit then
		frame.nCurrentPage = nPageCount
	else
		frame.nCurrentPage = min(max(frame.nCurrentPage, 1), nPageCount)
	end
	frame:Lookup('Window_Main/Wnd_Index/Wnd_IndexEdit/WndEdit_Index'):SetText(frame.nCurrentPage)
	frame:Lookup('Window_Main/Wnd_Index', 'Handle_IndexCount/Text_IndexCount'):SprintfText(_L['total %d pages'], nPageCount)

	local hOuter = frame:Lookup('Window_Main/Wnd_Index', 'Handle_IndexesOuter')
	local handle = hOuter:Lookup('Handle_Indexes')
	if nPageCount <= PAGE_DISPLAY then
		for i = 0, PAGE_DISPLAY - 1 do
			local hItem = handle:Lookup(i)
			hItem.nPage = i + 1
			hItem:Lookup('Text_Index'):SetText(i + 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(i + 1 == frame.nCurrentPage)
			hItem:SetVisible(i < nPageCount)
		end
	else
		local hItem = handle:Lookup(0)
		hItem.nPage = 1
		hItem:Lookup('Text_Index'):SetText(1)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(1 == frame.nCurrentPage)
		hItem:Show()

		local hItem = handle:Lookup(PAGE_DISPLAY - 1)
		hItem.nPage = nPageCount
		hItem:Lookup('Text_Index'):SetText(nPageCount)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(nPageCount == frame.nCurrentPage)
		hItem:Show()

		local nStartPage
		if frame.nCurrentPage + ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif frame.nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = frame.nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2)
		end
		for i = 1, PAGE_DISPLAY - 2 do
			local hItem = handle:Lookup(i)
			hItem.nPage = nStartPage + i - 1
			hItem:Lookup('Text_Index'):SetText(nStartPage + i - 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(nStartPage + i - 1 == frame.nCurrentPage)
			hItem:SetVisible(true)
		end
	end
	handle:SetSize(hOuter:GetSize())
	handle:FormatAllItemPos()
	handle:SetSizeByAllItemSize()
	hOuter:FormatAllItemPos()

	local data = GetChatLog(channels, search, (frame.nCurrentPage - 1) * PAGE_AMOUNT, PAGE_AMOUNT)
	local scroll = frame:Lookup('Window_Main/WndScroll_ChatLog/Scroll_ChatLog')
	local handle = frame:Lookup('Window_Main/WndScroll_ChatLog', 'Handle_ChatLogs')
	for i = 1, PAGE_AMOUNT do
		local rec = data[i]
		local hItem = handle:Lookup(i - 1)
		if rec then
			local f = GetMsgFont(CHANNELS[rec.channel])
			local r, g, b = unpack(MSGTYPE_COLOR[CHANNELS[rec.channel]])
			local h = hItem:Lookup('Handle_ChatLog_Msg')
			h:Clear()
			h:AppendItemFromString(MY.GetTimeLinkText({r=r, g=g, b=b, f=f, s='[yyyy/MM/dd][hh:mm:ss]'}, rec.time))
			local nCount = h:GetItemCount()
			h:AppendItemFromString(UTF8ToAnsi(rec.msg))
			for i = nCount, h:GetItemCount() - 1 do
				MY.RenderChatLink(h:Lookup(i))
			end
			if MY_Farbnamen and MY_Farbnamen.Render then
				for i = nCount, h:GetItemCount() - 1 do
					MY_Farbnamen.Render(h:Lookup(i))
				end
			end
			if MY_ChatMosaics and MY_ChatMosaics.Mosaics then
				MY_ChatMosaics.Mosaics(h)
			end
			local last = h:Lookup(h:GetItemCount() - 1)
			if last and last:GetType() == 'Text' and last:GetText():sub(-1) == '\n' then
				last:SetText(last:GetText():sub(0, -2))
			end
			h:FormatAllItemPos()
			local nW, nH = h:GetAllItemSize()
			h:SetH(nH)
			hItem:Lookup('Shadow_ChatLogHover'):SetH(nH + 3)
			hItem:Lookup('Shadow_ChatLogSelect'):SetH(nH + 3)
			hItem:SetH(nH + 3)
			hItem.hash = rec.hash
			hItem.time = rec.time
			hItem.text = rec.text
			if not frame.nLastClickIndex then
				hItem:Lookup('Shadow_ChatLogSelect'):Hide()
			end
			hItem:Show()
		else
			hItem:Hide()
		end
	end
	handle:FormatAllItemPos()

	if not noscroll then
		scroll:SetScrollPos(bInit and scroll:GetStepCount() or 0)
	end
end

------------------------------------------------------------------------------------------------------
-- 数据导出
------------------------------------------------------------------------------------------------------
local function htmlEncode(html)
	return html
	:gsub('&', '&amp;')
	:gsub(' ', '&ensp;')
	:gsub('<', '&lt;')
	:gsub('>', '&gt;')
	:gsub('"', '&quot;')
	:gsub('\n', '<br>')
end

local function getHeader()
	local szHeader = [[<!DOCTYPE html>
<html>
<head><meta http-equiv='Content-Type' content='text/html; charset=]]
	.. ((MY.GetLang() == 'zhcn' and 'GBK') or 'UTF-8') .. [[' />
<style>
*{font-size: 12px}
a{line-height: 16px}
input, button, select, textarea {outline: none}
body{background-color: #000; margin: 8px 8px 45px 8px}
#browserWarning{background-color: #f00; font-weight: 800; color:#fff; padding: 8px; position: fixed; opacity: 0.92; top: 0; left: 0; right: 0}
.channel{color: #fff; font-weight: 800; font-size: 32px; padding: 0; margin: 30px 0 0 0}
.date{color: #fff; font-weight: 800; font-size: 24px; padding: 0; margin: 0}
a.content{font-family: cursive}
span.emotion_44{width:21px; height: 21px; display: inline-block; background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAO/SURBVDhPnZT7U4xRGMfff4GftEVKYsLutkVETKmsdrtY9QMNuTRDpVZS2Fw2utjcL1NSYaaUa5gRFSK5mzFukzHGYAbjOmTC7tv79vWcs2+bS7k9M985u+c953PO85zneYS+zBQThYChKvj7ejg1zDnqfN1hipkKZdnfmXFKKLRD3aHXecMyPQh1q+PRVr4Qj2qycKZkAfLmRyJitA80tCaa1irb+rZR3m4I9huIgsQQvKxKxZemXEgNuZAvrIPcWoSuqzbYH5bhcZMV6fHjETjcA6OGuPUNHuk9AJM1g3E4IxId9TnwcuvHJV0phHQuD9L5fODFPtf8mwcV2JIVg4kab6h9VL+Co/VhGOOrQlnSBHQcWeyE3SqG1JKHzoaVkC4WQr68HniyGUAb6QFf86FtC0qzTRhL3kVPCfsRrKGTUsNH4lX5PDiOLoZ0yQrpzCoOlW9uoLGAu4/2cgK2kC6QGiG9rsCr5gKkm8ZBTTFWcIIQH2dAyHAV7q+d5nLNJVV/Psq3NkO+RNC3lb+s8VHWBNFtE4jFJGgolsmhfnheZKTTfzS2WL6/3XlTcr/r3iYC71S+Oo2teXfdhjlTAzDCawCXwNJnx8xgvC9Jgrg7EfZ98yAeSoGjLt3p+lkrZHp1+cp6GosJbkPXnXwuudWKLjpUvJiPvctMPM2YBH9K5pZsPeyls2HfkwzHQTPE49nobFrNX12+pgC/1zUGL+r5T6G5uyfNVSgcejs3CvYSgu4laFUKxBM5Lih3/Xtgb2otxNOaJdBR1TFxaIM5nG6ahK9lc+HYnwbxSCbE+hWQmtf+GcpCQ/FuLp7dc9MAHzdYo3X4vG0m7LuSYK+cD8eBDIinLehsZGn1E5QgbI6L8pd707gS62ZNhD+xmARTrAF69SA8sSX0hKA6tee2lJ+uh6L4MggrCHYgP5QOf1ebAUPgEGo0UVw8V1kGbEoYg090WwcVAH+wbvApBawAxZPLac7CH1Oi2H+py8LGWZN4E+KwbouibhOh8UR9Wjjat82Ao8IJ7jyYDrF6AaRTOUplkavHsyAezaRvZnRUL8KxpQZM8POAobeOFUClatB5oSY5BB+2Unx3z4FtSZyrcrply4ylmC/CRwoVaz562qP+XafS0MfgYSqsMGjxzGbiEPshCkMtpVkNSzUzn3tJYcqbFohJIzzA+oayvW8zUsdiVRHq5w6LUYvalDDcsBhxb00c6s2RyE8Igl7ryWPYq8u/s+nUGNTUF/xpM8tlLvqtJW9MscoL/6v9P1QQvgHonm5Hx/sAiwAAAABJRU5ErkJggg==')}
#controls{background-color: #fff; height: 25px; position: fixed; opacity: 0.92; bottom: 0; left: 0; right: 0}
#mosaics{width: 200px;height: 20px}
]]

	for k, v in pairs(g_tStrings.tForceTitle) do
		szHeader = szHeader .. ('.force-%s{color:#%02X%02X%02X}'):format(k, MY.GetForceColor(k, 'forecolor'))
	end

	szHeader = szHeader .. [[
</style></head>
<body>
<div id='browserWarning'>Please allow running JavaScript on this page!</div>
<div id='controls' style='display:none'>
	<input type='range' id='mosaics' min='0' max='200' value='0'>
	<script type='text/javascript'>
	(function() {
		var timerid, blurRadius;
		var setMosaicHandler = function() {
			var filter = 'blur(' + blurRadius + ')';console.log(filter);
			var eles = document.getElementsByClassName('namelink');
			for(i = eles.length - 1; i >= 0; i--) {
				eles[i].style['filter'] = filter;
				eles[i].style['-o-filter'] = filter;
				eles[i].style['-ms-filter'] = filter;
				eles[i].style['-moz-filter'] = filter;
				eles[i].style['-webkit-filter'] = filter;
			}
			timerid = null;
		}
		var setMosaic = function(radius) {
			if (timerid)
				clearTimeout(timerid);
			blurRadius = radius;
			timerid = setTimeout(setMosaicHandler, 50);
		}
		document.getElementById('mosaics').oninput = function() {
			setMosaic((this.value / 100 + 0.5) + 'px');
		}
	})();
	</script>
</div>
<script type='text/javascript'>
	(function () {
		var Sys = {};
		var ua = navigator.userAgent.toLowerCase();
		var s;
		(s = ua.match(/rv:([\d.]+)\) like gecko/)) ? Sys.ie = s[1] :
		(s = ua.match(/msie ([\d.]+)/)) ? Sys.ie = s[1] :
		(s = ua.match(/firefox\/([\d.]+)/)) ? Sys.firefox = s[1] :
		(s = ua.match(/chrome\/([\d.]+)/)) ? Sys.chrome = s[1] :
		(s = ua.match(/opera.([\d.]+)/)) ? Sys.opera = s[1] :
		(s = ua.match(/version\/([\d.]+).*safari/)) ? Sys.safari = s[1] : 0;

		// if (Sys.ie) document.write('IE: ' + Sys.ie);
		// if (Sys.firefox) document.write('Firefox: ' + Sys.firefox);
		// if (Sys.chrome) document.write('Chrome: ' + Sys.chrome);
		// if (Sys.opera) document.write('Opera: ' + Sys.opera);
		// if (Sys.safari) document.write('Safari: ' + Sys.safari);

		if (!Sys.chrome && !Sys.firefox) {
			document.getElementById('browserWarning').innerHTML = '<a>WARNING: Please use </a><a href='http://www.google.cn/chrome/browser/desktop/index.html' style='color: yellow;'>Chrome</a></a> to browse this page!!!</a>';
		} else {
			document.getElementById('controls').style['display'] = null;
			document.getElementById('browserWarning').style['display'] = 'none';
		}
	})();
</script>
<div>
<a style='color: #fff;margin: 0 10px'>]] .. GetClientPlayer().szName .. ' @ ' .. MY.GetServer() ..
' Exported at ' .. MY.FormatTime('yyyyMMdd hh:mm:ss', GetCurrentTime()) .. '</a><hr />'

	return szHeader
end

local function getFooter()
	return [[
</div>
</body>
</html>]]
end

local function getChannelTitle(szChannel)
	return [[<p class='channel'>]] .. (g_tStrings.tChannelName[szChannel] or '') .. [[</p><hr />]]
end

local function getDateTitle(szDate)
	return [[<p class='date'>]] .. (szDate or '') .. [[</p>]]
end

local function convertXml2Html(szXml)
	local aXml = MY.Xml.Decode(szXml)
	local t = {}
	if aXml then
		local text, name
		for _, xml in ipairs(aXml) do
			text = xml[''].text
			name = xml[''].name
			if text then
				local force
				text = htmlEncode(text)
				insert(t, '<a')
				if name and name:sub(1, 9) == 'namelink_' then
					insert(t, ' class="namelink')
					if MY_Farbnamen and MY_Farbnamen.Get then
						local info = MY_Farbnamen.Get((text:gsub('[%[%]]', '')))
						if info then
							force = info.dwForceID
							insert(t, ' force-')
							insert(t, info.dwForceID)
						end
					end
					insert(t, '"')
				end
				if not force and xml[''].r and xml[''].g and xml[''].b then
					insert(t, (' style="color:#%02X%02X%02X"'):format(xml[''].r, xml[''].g, xml[''].b))
				end
				insert(t, '>')
				insert(t, text)
				insert(t, '</a>')
			elseif name and name:sub(1, 8) == 'emotion_' then
				insert(t, '<span class="')
				insert(t, name)
				insert(t, '"></span>')
			end
		end
	end
	return concat(t)
end

local l_bExporting
function MY_ChatLog.ExportConfirm()
	if l_bExporting then
		return MY.Sysmsg({_L['Already exporting, please wait.']})
	end
	local ui = UI.CreateFrame('MY_ChatLog_Export', {
		simple = true, esc = true, close = true, w = 140,
		level = 'Normal1', text = _L['export chatlog'], alpha = 233,
	})
	local btnSure
	local tChannels = {}
	local x, y = 10, 10
	for nGroup, info in ipairs(LOG_TYPE) do
		ui:append('WndCheckBox', {
			x = x, y = y, w = 100,
			text = info.title,
			checked = true,
			oncheck = function(checked)
				tChannels[nGroup] = checked
				if checked then
					btnSure:enable(true)
				else
					btnSure:enable(false)
					for nGroup, info in ipairs(LOG_TYPE) do
						if tChannels[nGroup] then
							btnSure:enable(true)
							break
						end
					end
				end
			end,
		})
		y = y + 30
		tChannels[nGroup] = true
	end
	y = y + 10

	btnSure = ui:append('WndButton', {
		x = x, y = y, w = 120,
		text = _L['export chatlog'],
		onclick = function()
			local aChannels = {}
			for nGroup, info in ipairs(LOG_TYPE) do
				if tChannels[nGroup] then
					for _, szChannel in ipairs(info.channels) do
						table.insert(aChannels, CHANNELS_R[szChannel])
					end
				end
			end
			MY_ChatLog.Export(
				MY.FormatPath({'export/ChatLog/$name@$server@' .. MY.FormatTime('yyyyMMddhhmmss') .. '.html', MY_DATA_PATH.ROLE}),
				aChannels, 10,
				function(title, progress)
					OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Exporting chatlog: %s, %.2f%%.', title, progress * 100))
				end
			)
			ui:remove()
		end,
	}, true)
	y = y + 30
	ui:height(y + 50)
	ui:anchor({s = 'CENTER', r = 'CENTER', x = 0, y = 0})
end

function MY_ChatLog.Export(szExportFile, aChannels, nPerSec, onProgress)
	if l_bExporting then
		return MY.Sysmsg({_L['Already exporting, please wait.']})
	end
	if not ConnectDB(true) then
		return
	end
	if onProgress then
		onProgress(_L['preparing'], 0)
	end
	local status = Log(szExportFile, getHeader(), 'clear')
	if status ~= 'SUCCEED' then
		return MY.Sysmsg({_L('Error: open file error %s [%s]', szExportFile, status)})
	end
	l_bExporting = true

	local nPage, nPageCount = 0, ceil(GetChatLogCount(aChannels, '') / EXPORT_SLICE)
	local function Export()
		if nPage > nPageCount then
			l_bExporting = false
			Log(szExportFile, getFooter(), 'close')
			if onProgress then
				onProgress(_L['Export succeed'], 1)
			end
			local szFile = GetRootPath() .. szExportFile:gsub('/', '\\')
			MY.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
			MY.Sysmsg({_L('Chatlog export succeed, file saved as %s', szFile)})
			return 0
		end
		local data = GetChatLog(aChannels, '', nPage * EXPORT_SLICE, EXPORT_SLICE)
		for i, rec in ipairs(data) do
			local f = GetMsgFont(CHANNELS[rec.channel])
			local r, g, b = unpack(MSGTYPE_COLOR[CHANNELS[rec.channel]])
			Log(szExportFile, convertXml2Html(MY.GetTimeLinkText({r=r, g=g, b=b, f=f, s='[yyyy/MM/dd][hh:mm:ss]'}, rec.time)))
			Log(szExportFile, convertXml2Html(UTF8ToAnsi(rec.msg)))
		end
		if onProgress then
			onProgress(_L['exporting'], nPage / nPageCount)
		end
		nPage = nPage + 1
	end
	MY.BreatheCall('MY_ChatLog_Export', Export)
end

------------------------------------------------------------------------------------------------------
-- 设置界面绘制
------------------------------------------------------------------------------------------------------
do
local menu = {
	szOption = _L['chat log'],
	fnAction = function() MY_ChatLog.Toggle() end,
}
MY.RegisterAddonMenu('MY_CHATLOG_MENU', menu)
end
MY.RegisterHotKey('MY_ChatLog', _L['chat log'], MY_ChatLog.Toggle, nil)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local x, y = 50, 50
	local dy = 40
	local wr = 200

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr,
		text = _L['filter tong member log message'],
		checked = MY_ChatLog.bIgnoreTongMemberLogMsg,
		oncheck = function(bChecked)
			MY_ChatLog.bIgnoreTongMemberLogMsg = bChecked
		end
	})
	y = y + dy

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr,
		text = _L['filter tong online message'],
		checked = MY_ChatLog.bIgnoreTongOnlineMsg,
		oncheck = function(bChecked)
			MY_ChatLog.bIgnoreTongOnlineMsg = bChecked
		end
	})
	y = y + dy

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr,
		text = _L['realtime database commit'],
		checked = MY_ChatLog.bRealtimeCommit,
		oncheck = function(bChecked)
			MY_ChatLog.bRealtimeCommit = bChecked
		end
	})
	y = y + dy

	ui:append('WndButton', {
		x = x, y = y, w = 150,
		text = _L['open chatlog'],
		onclick = function()
			MY_ChatLog.Open()
		end,
	})
	y = y + dy

	ui:append('WndButton', {
		x = x, y = y, w = 150,
		text = _L['export chatlog'],
		onclick = function()
			MY_ChatLog.ExportConfirm()
		end,
	})
	y = y + dy

	ui:append('WndButton', {
		x = x, y = y, w = 150,
		text = _L['optimize/compress datebase'],
		onclick = function()
			MY.Confirm(_L['optimize/compress datebase will take a long time and may cause a disconnection, are you sure to continue?'], function()
				MY.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					OptimizeDB(true)
					MY.Alert(_L['Optimize finished!'])
				end)
			end)
		end,
	})
	y = y + dy

	ui:append('WndButton', {
		x = x, y = y, w = 150,
		text = _L['fix search datebase'],
		onclick = function()
			MY.Confirm(_L['fix search datebase may take a long time and cause a disconnection, are you sure to continue?'], function()
				MY.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					MY.Alert(_L('%d chatlogs fixed!', FixSearchDB()))
				end)
			end)
		end,
	})
	y = y + dy

	ui:append('WndButton', {
		x = x, y = y, w = 150,
		text = _L['reindex search datebase'],
		onclick = function()
			MY.Confirm(_L['reindex search datebase may take a long time and cause a disconnection, are you sure to continue?'], function()
				MY.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					MY.Alert(_L('%d chatlogs reindexed!', FixSearchDB(true)))
				end)
			end)
		end,
	})
	y = y + dy

	ui:append('WndButton', {
		x = x, y = y, w = 150,
		text = _L['import chatlog'],
		onclick = function()
			local file = GetOpenFileName(_L['Please select your chatlog database file.'], 'Database File(*.db)\0*.db\0All Files(*.*)\0*.*\0\0', MY.FormatPath({'userdata/', MY_DATA_PATH.ROLE}))
			if not empty(file) then
				MY.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
						MY.Alert(_L('%d chatlogs imported!', ImportDB(file)))
				end)
			end
		end,
	})
	y = y + dy
end
MY.RegisterPanel( 'ChatLog', _L['chat log'], _L['Chat'], 'ui/Image/button/SystemButton.UITex|43', PS)
