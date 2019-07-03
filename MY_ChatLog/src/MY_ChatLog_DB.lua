--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 数据库支持类 仅做读写功能
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local XML_LINE_BREAKER = XML_LINE_BREAKER

local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_ChatLog/lang/')
if not LIB.AssertVersion('MY_ChatLog', _L['MY_ChatLog'], 0x2013500) then
	return
end
-------------------------------------------------------------------------------------------------------------
local DB = class()
local DB_CACHE = setmetatable({}, {__mode = 'v'})

function DB:ctor(szFilePath)
	self.nStartTime = nStartTime
	self.nEndTime = nEndTime
	self.szFilePath = szFilePath
	self.aInsertQueue = {}
	self.aDeleteQueue = {}
	return self
end

function DB:Connect()
	if not self.db then
		self.db = LIB.ConnectDatabase(_L['chat log'], self.szFilePath)
		self.db:Execute('CREATE TABLE IF NOT EXISTS ChatLog (hash INTEGER, channel INTEGER, time INTEGER, talker NVARCHAR(20), text NVARCHAR(400) NOT NULL, msg NVARCHAR(4000) NOT NULL, PRIMARY KEY (time, hash))')
		self.db:Execute('CREATE INDEX IF NOT EXISTS ChatLog_channel_idx ON ChatLog(channel)')
		self.db:Execute('CREATE INDEX IF NOT EXISTS ChatLog_talker_idx ON ChatLog(talker)')
		self.db:Execute('CREATE INDEX IF NOT EXISTS ChatLog_text_idx ON ChatLog(text)')
		self.stmtCount = self.db:Prepare('SELECT channel AS nChannel, COUNT(*) AS nCount FROM ChatLog WHERE talker LIKE ? OR text LIKE ? GROUP BY nChannel')
		self.stmtInsert = self.db:Prepare('REPLACE INTO ChatLog (hash, channel, time, talker, text, msg) VALUES (?, ?, ?, ?, ?, ?)')
		self.stmtDelete = self.db:Prepare('DELETE FROM ChatLog WHERE hash = ? AND time = ?')
	end
	return self
end

function DB:Disconnect()
	if self.db then
		self.db:Release()
		self.db = nil
	end
	return self
end

function DB:Move(szFilePath)
	self:Disconnect()
	DB_CACHE[self.szFilePath] = nil
	CPath.Move(self.szFilePath, szFilePath)
	self.szFilePath = szFilePath
	DB_CACHE[self.szFilePath] = self
	return self
end

function DB:InsertMsg(nChannel, szText, szMsg, szTalker, nTime, szHash)
	if not nChannel or not nTime or IsEmpty(szMsg) or not szText or IsEmpty(szHash) then
		return
	end
	insert(self.aInsertQueue, {szHash = szHash, nChannel = nChannel, nTime = nTime, szTalker = szTalker, szText = szText, szMsg = szMsg})
end

function DB:CountMsg(aChannel, szSearch)
	self:Connect():PushDB()
	if not aChannel then
		if not self.nCountCache then
			self.nCountCache = Get(self.db:Execute('SELECT COUNT(*) AS nCount FROM ChatLog'), {1, 'nCount'}, 0)
		end
		return self.nCountCache
	end
	if not self.tCountCache or self.szCountCacheKey ~= szSearch then
		local aResult
		if szSearch == '' then
			aResult = self.db:Execute('SELECT channel AS nChannel, COUNT(*) AS nCount FROM ChatLog GROUP BY channel')
		else
			self.stmtCount:ClearBindings()
			self.stmtCount:BindAll(szSearch, szSearch)
			aResult = self.stmtCount:GetAll()
		end
		self.tCountCache = {}
		for _, rec in ipairs(aResult) do
			self.tCountCache[rec.nChannel] = rec.nCount
		end
		self.szCountCacheKey = szSearch
	end
	local nCount = 0
	for _, nChannel in ipairs(aChannel) do
		nCount = nCount + (self.tCountCache[nChannel] or 0)
	end
	return nCount
end

function DB:SelectMsg(aChannel, szSearch, nOffset, nLimit)
	self:Connect():PushDB()
	local aWhere, aValue = {}, {}
	if aChannel then
		for _, nChannel in ipairs(aChannel) do
			insert(aWhere, 'channel = ?')
			insert(aValue, nChannel)
		end
	end
	local szSQL  = ''
	local szWhere = ''
	if #aWhere > 0 then
		szWhere = szWhere .. ' (' .. concat(aWhere, ' OR ') .. ')'
	end
	if szSearch ~= '' then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (talker LIKE ? OR text LIKE ?)'
		insert(aValue, szSearch)
		insert(aValue, szSearch)
	end
	if #szWhere > 0 then
		szSQL  = szSQL .. ' WHERE' .. szWhere
	end
	insert(aValue, nLimit)
	insert(aValue, nOffset)

	szSQL = 'SELECT hash AS szHash, channel AS nChannel, time AS nTime, talker AS szTalker, text AS szText, msg AS szMsg FROM ChatLog'
		.. szSQL .. ' ORDER BY nTime ASC LIMIT ? OFFSET ?'
	local stmt = self.db:Prepare(szSQL)
	stmt:ClearBindings()
	stmt:BindAll(unpack(aValue))
	return (stmt:GetAll())
end

function DB:GetFirstMsg()
	self:Connect():PushDB()
	return self.db:Execute('SELECT hash AS szHash, channel AS nChannel, time AS nTime, talker AS szTalker, text AS szText, msg AS szMsg FROM ChatLog ORDER BY nTime ASC LIMIT 1')[1]
end

function DB:GetLastMsg()
	self:Connect():PushDB()
	return self.db:Execute('SELECT hash AS szHash, channel AS nChannel, time AS nTime, talker AS szTalker, text AS szText, msg AS szMsg FROM ChatLog ORDER BY nTime DESC LIMIT 1')[1]
end

function DB:DeleteMsg(szHash, nTime)
	if nTime and not IsEmpty(szHash) then
		insert(self.aDeleteQueue, {szHash = szHash, nTime = nTime})
	end
	return self
end

function DB:PushDB()
	if not IsEmpty(self.aInsertQueue) or not IsEmpty(self.aDeleteQueue) then
		self:Connect()
		self.db:Execute('BEGIN TRANSACTION')
		-- 插入记录
		for _, data in ipairs(self.aInsertQueue) do
			self.stmtInsert:ClearBindings()
			self.stmtInsert:BindAll(data.szHash, data.nChannel, data.nTime, data.szTalker, data.szText, data.szMsg)
			self.stmtInsert:Execute()
		end
		self.aInsertQueue = {}
		-- 删除记录
		for _, data in ipairs(self.aDeleteQueue) do
			self.stmtDelete:ClearBindings()
			self.stmtDelete:BindAll(data.szHash, data.nTime)
			self.stmtDelete:Execute()
		end
		self.aDeleteQueue = {}
		self.db:Execute('END TRANSACTION')
		self.tCountCache = nil
		self.nCountCache = nil
	end
	return self
end

function MY_ChatLog_DB(szFilePath)
	if not DB_CACHE[szFilePath] then
		DB_CACHE[szFilePath] = DB.new(szFilePath)
	end
	return DB_CACHE[szFilePath]
end
