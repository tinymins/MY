--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 数据库支持类 仅做读写功能
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
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------
local DB = class()
local DB_CACHE = setmetatable({}, {__mode = 'v'})
local SELECT_MSG = 'SELECT hash AS szHash, channel AS nChannel, time AS nTime, talker AS szTalker, text AS szText, msg AS szMsg FROM ChatLog'
local DELETE_MSG = 'DELETE FROM ChatLog'

local function FormatCommonParam(szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	if not szSearch then
		szSearch = ''
	end
	if not nMinTime then
		nMinTime = 0
	end
	if not nMaxTime then
		nMaxTime = HUGE
	end
	if not nOffset then
		nOffset = 0
	end
	if not nLimit then
		nLimit = HUGE
	end
	return szSearch, nMinTime, nMaxTime, nOffset, nLimit
end

local function AppendCommonWhere(szSQL, aValue, aChannel, szSearch, nMinTime, nMaxTime)
	local szWhere = ''
	local aWhere = {}
	if aChannel then
		for _, nChannel in ipairs(aChannel) do
			insert(aWhere, 'channel = ?')
			insert(aValue, nChannel)
		end
	end
	if #aWhere > 0 then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (' .. concat(aWhere, ' OR ') .. ')'
	end
	if not IsEmpty(nMinTime) then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (time >= ?)'
		insert(aValue, nMinTime)
	end
	if not IsEmpty(nMaxTime) and not IsHugeNumber(nMaxTime) then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (time <= ?)'
		insert(aValue, nMaxTime)
	end
	if not IsEmpty(szSearch) then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (talker LIKE ? OR text LIKE ?)'
		insert(aValue, szSearch)
		insert(aValue, szSearch)
	end
	if #szWhere > 0 then
		if wfind(szSQL, ' WHERE ') then
			szSQL = szSQL .. ' AND' .. szWhere
		else
			szSQL = szSQL .. ' WHERE' .. szWhere
		end
	end
	return szSQL
end

local function AppendCommonLimit(szSQL, aValue, nOffset, nLimit)
	if (nOffset and not nLimit) or IsHugeNumber(nLimit) then
		nLimit = -1
	end
	if nLimit then
		szSQL = szSQL .. ' LIMIT ?'
		insert(aValue, nLimit)
	end
	if nOffset then
		szSQL = szSQL .. ' OFFSET ?'
		insert(aValue, nOffset)
	end
	return szSQL
end

function DB:ctor(szFilePath)
	self.szFilePath = szFilePath
	self.aInsertQueue = {}
	self.aDeleteQueue = {}
	return self
end

function DB:GetFilePath()
	return self.szFilePath
end

function DB:ToString()
	return '"' .. self:GetFilePath() .. '"(' .. self:GetMinTime() .. ',' .. self:GetMaxTime() .. ')'
end

function DB:Connect(bCheck)
	if not self:IsConnected() then
		if bCheck then
			self.db = LIB.SQLiteConnect(_L['MY_ChatLog'], self.szFilePath)
		else
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_ChatLog'], 'Quick connect database: ' .. self.szFilePath, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			self.db = SQLite3_Open(self.szFilePath)
		end
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Init database with STMT', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		if self.db then
			self.db:Execute('CREATE TABLE IF NOT EXISTS ChatInfo (key NVARCHAR(128), value NVARCHAR(4096), PRIMARY KEY (key))')
			self.stmtInfoGet = self.db:Prepare('SELECT value FROM ChatInfo WHERE key = ?')
			self.stmtInfoSet = self.db:Prepare('REPLACE INTO ChatInfo (key, value) VALUES (?, ?)')
			self.db:Execute('CREATE TABLE IF NOT EXISTS ChatLog (hash INTEGER, channel INTEGER, time INTEGER, talker NVARCHAR(20), text NVARCHAR(400) NOT NULL, msg NVARCHAR(4000) NOT NULL, PRIMARY KEY (time, hash))')
			self.db:Execute('CREATE INDEX IF NOT EXISTS ChatLog_channel_idx ON ChatLog(channel)')
			self.db:Execute('CREATE INDEX IF NOT EXISTS ChatLog_talker_idx ON ChatLog(talker)')
			self.db:Execute('CREATE INDEX IF NOT EXISTS ChatLog_text_idx ON ChatLog(text)')
			self.stmtCount = self.db:Prepare('SELECT channel AS nChannel, COUNT(*) AS nCount FROM ChatLog WHERE talker LIKE ? OR text LIKE ? GROUP BY nChannel')
			self.stmtInsert = self.db:Prepare('REPLACE INTO ChatLog (hash, channel, time, talker, text, msg) VALUES (?, ?, ?, ?, ?, ?)')
			self.stmtDelete = self.db:Prepare('DELETE FROM ChatLog WHERE hash = ? AND time = ?')
		end
		if self:IsConnected() then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_ChatLog'], 'Init database finished: ' .. self.szFilePath, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return true
		end
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Init database failed: ' .. self.szFilePath, DEBUG_LEVEL.WARNING)
		--[[#DEBUG END]]
		self:Disconnect()
		return false
	end
	return true
end

function DB:IsConnected()
	if self.db and self.stmtInfoGet and self.stmtInfoSet and self.stmtCount and self.stmtInsert and self.stmtDelete then
		return true
	end
	return false
end

function DB:Disconnect()
	if self.db then
		self.db:Release()
		self.db = nil
		self.stmtInfoGet = nil
		self.stmtInfoSet = nil
		self.stmtCount = nil
		self.stmtInsert = nil
		self.stmtDelete = nil
	end
	return true
end

function DB:GarbageCollection()
	if not self:Connect() then
		return false
	end
	self.db:Execute('VACUUM')
	return true
end

function DB:DeleteDB()
	if not self:Disconnect() then
		return false
	end
	CPath.DelFile(self.szFilePath)
	return true
end

function DB:SetInfo(szKey, oValue)
	if not self:Connect() then
		return false
	end
	self.stmtInfoSet:ClearBindings()
	self.stmtInfoSet:BindAll(szKey, EncodeLUAData(oValue))
	self.stmtInfoSet:GetAll()
	return true
end

function DB:GetInfo(szKey)
	if not self:Connect() then
		return nil, false
	end
	self.stmtInfoGet:ClearBindings()
	self.stmtInfoGet:BindAll(szKey)
	local res, success = Get(self.stmtInfoGet:GetAll(), {1, 'value'})
	if success then
		res = DecodeLUAData(res)
	end
	return res, success
end

function DB:SetMinTime(nMinTime)
	if not self:Connect() then
		return false
	end
	self:Flush()
	local nMinRecTime = self:GetMinRecTime()
	assert(nMinRecTime == -1 or nMinRecTime >= nMinTime, '[MY_ChatLog_DB:SetMinTime] MinTime cannot be larger than MinRecTime.')
	self:SetInfo('min_time', nMinTime)
	self._nMinTime = nMinTime
	return true
end

function DB:GetMinTime()
	if not self._nMinTime then
		self._nMinTime = self:GetInfo('min_time') or 0
	end
	return self._nMinTime
end

function DB:SetMaxTime(nMaxTime)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if nMaxTime <= 0 then
		nMaxTime = HUGE
	end
	local nMaxRecTime = self:GetMaxRecTime()
	assert(nMaxRecTime <= nMaxTime, '[MY_ChatLog_DB:SetMaxTime] MaxTime cannot be smaller than MaxRecTime.')
	self:SetInfo('max_time', IsHugeNumber(nMaxTime) and 0 or nMaxTime)
	self._nMaxTime = nMaxTime
	return true
end

function DB:GetMaxTime()
	if not self._nMaxTime then
		self._nMaxTime = self:GetInfo('max_time') or 0
		if self._nMaxTime == 0 then
			self._nMaxTime = HUGE
		end
	end
	return self._nMaxTime
end

function DB:InsertMsg(nChannel, szText, szMsg, szTalker, nTime, szHash)
	local nMinTime, nMaxTime = self:GetMinTime(), self:GetMaxTime()
	assert(nTime >= nMinTime and nTime <= nMaxTime,
		'[MY_ChatLog_DB:InsertMsg] Time(' ..nTime .. ') must between MinTime(' .. nMinTime .. ') and MaxTime(' .. nMaxTime .. ').')
	if not nChannel or not nTime or IsEmpty(szMsg) or not szText or IsEmpty(szHash) then
		return
	end
	insert(self.aInsertQueue, {szHash = szHash, nChannel = nChannel, nTime = nTime, szTalker = szTalker, szText = szText, szMsg = szMsg})
end

function DB:CountMsg(aChannel, szSearch, nMinTime, nMaxTime)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if IsTable(aChannel) and IsEmpty(aChannel) then
		return 0
	end
	szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
	local bMinTime = not IsEmpty(nMinTime) and self:GetMinTime() >= nMinTime
	local bMaxTime = not IsEmpty(nMaxTime) and not IsHugeNumber(nMaxTime) and self:GetMaxTime() >= nMaxTime
	if not aChannel and IsEmpty(szSearch) and not bMinTime and not bMaxTime then
		if not self.nCountCache then
			self.nCountCache = Get(self.db:Execute('SELECT COUNT(*) AS nCount FROM ChatLog'), {1, 'nCount'}, 0)
		end
		return self.nCountCache
	end
	if not self.tCountCache then
		self.tCountCache = {}
	end
	local szKey = szSearch
		.. '_' .. (bMinTime and nMinTime or '0')
		.. '_' .. (bMaxTime and nMaxTime or '0')
	local tCount = self.tCountCache[szKey]
	if not tCount then
		local aResult
		if IsEmpty(szSearch) then
			aResult = self.db:Execute('SELECT channel AS nChannel, COUNT(*) AS nCount FROM ChatLog GROUP BY channel')
		elseif bMinTime or bMaxTime then
			local szSQL = 'SELECT channel AS nChannel, COUNT(*) AS nCount FROM ChatLog'
			local aValue = {}
			szSQL = AppendCommonWhere(szSQL, aValue, aChannel, szSearch, nMinTime, nMaxTime)
			local stmt = self.db:Prepare(szSQL)
			stmt:ClearBindings()
			stmt:BindAll(unpack(aValue))
			aResult = stmt:GetAll()
		else
			self.stmtCount:ClearBindings()
			self.stmtCount:BindAll(szSearch, szSearch)
			aResult = self.stmtCount:GetAll()
		end
		tCount = {}
		for _, rec in ipairs(aResult) do
			tCount[rec.nChannel] = rec.nCount
		end
		self.tCountCache[szKey] = tCount
	end
	local nCount = 0
	if aChannel then
		for _, nChannel in ipairs(aChannel) do
			nCount = nCount + (tCount[nChannel] or 0)
		end
	else
		for _, n in pairs(tCount) do
			nCount = nCount + n
		end
	end
	return nCount
end

function DB:SelectMsg(aChannel, szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if IsTable(aChannel) and IsEmpty(aChannel) then
		return {}
	end
	szSearch, nMinTime, nMaxTime, nOffset, nLimit = FormatCommonParam(szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	local szSQL, aValue = SELECT_MSG, {}
	szSQL = AppendCommonWhere(szSQL, aValue, aChannel, szSearch, nMinTime, nMaxTime)
	szSQL = szSQL .. ' ORDER BY nTime ASC'
	szSQL = AppendCommonLimit(szSQL, aValue, nOffset, nLimit)
	local stmt = self.db:Prepare(szSQL)
	stmt:ClearBindings()
	stmt:BindAll(unpack(aValue))
	return (stmt:GetAll())
end

function DB:GetMinRecTime()
	if not self:Connect() then
		return false
	end
	self:Flush()
	local rec = self.db:Execute('SELECT time AS nTime FROM ChatLog ORDER BY nTime ASC LIMIT 1')[1]
	return rec and rec.nTime or -1
end

function DB:GetMaxRecTime()
	if not self:Connect() then
		return false
	end
	self:Flush()
	local rec = self.db:Execute('SELECT time AS nTime FROM ChatLog ORDER BY nTime DESC LIMIT 1')[1]
	return rec and rec.nTime or -1
end

function DB:DeleteMsg(szHash, nTime)
	if nTime and not IsEmpty(szHash) then
		insert(self.aDeleteQueue, {szHash = szHash, nTime = nTime})
	end
end

function DB:DeleteMsgInterval(aChannel, szSearch, nMinTime, nMaxTime)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if IsTable(aChannel) and IsEmpty(aChannel) then
		return true
	end
	szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
	local szSQL, aValue = DELETE_MSG, {}
	szSQL = AppendCommonWhere(szSQL, aValue, aChannel, szSearch, nMinTime, nMaxTime)
	if szSQL ~= DELETE_MSG then
		local stmt = self.db:Prepare(szSQL)
		stmt:ClearBindings()
		stmt:BindAll(unpack(aValue))
		stmt:GetAll()
		self:FlushCache()
		return true
	end
	return false
end

function DB:Flush()
	if not IsEmpty(self.aInsertQueue) or not IsEmpty(self.aDeleteQueue) then
		if not self:Connect() then
			return false
		end
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
		self:FlushCache()
	end
	return true
end

function DB:FlushCache()
	self.tCountCache = nil
	self.nCountCache = nil
end

function MY_ChatLog_DB(szFilePath)
	if not DB_CACHE[szFilePath] then
		DB_CACHE[szFilePath] = DB.new(szFilePath)
	end
	return DB_CACHE[szFilePath]
end
