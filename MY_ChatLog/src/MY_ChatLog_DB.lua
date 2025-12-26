--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 聊天记录 数据库支持类 仅做读写功能
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_DB'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local DB = class()
local DB_CACHE = setmetatable({}, {__mode = 'v'})
local SELECT_MSG = 'SELECT hash AS szHash, type AS szMsgType, time AS nTime, talker AS szTalker, text AS szText, msg AS szMsg FROM ChatLog'
local DELETE_MSG = 'DELETE FROM ChatLog'

local function FormatCommonParam(szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	if not szSearch then
		szSearch = ''
	end
	if not nMinTime then
		nMinTime = 0
	end
	if not nMaxTime then
		nMaxTime = math.huge
	end
	if not nOffset then
		nOffset = 0
	end
	if not nLimit then
		nLimit = math.huge
	end
	return szSearch, nMinTime, nMaxTime, nOffset, nLimit
end

local function AppendCommonWhere(szSQL, aValue, aMsgType, szSearch, nMinTime, nMaxTime)
	local szWhere = ''
	local aWhere = {}
	if aMsgType then
		for _, szMsgType in ipairs(aMsgType) do
			table.insert(aWhere, 'type = ?')
			table.insert(aValue, szMsgType)
		end
	end
	if #aWhere > 0 then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (' .. table.concat(aWhere, ' OR ') .. ')'
	end
	if X.IsNumber(nMinTime) and nMinTime > 0 then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (time >= ?)'
		table.insert(aValue, nMinTime)
	end
	if X.IsNumber(nMaxTime) and not X.IsHugeNumber(nMaxTime) then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (time <= ?)'
		table.insert(aValue, nMaxTime)
	end
	if X.IsString(szSearch) and not X.IsEmpty(szSearch) then
		if #szWhere > 0 then
			szWhere = szWhere .. ' AND'
		end
		szWhere = szWhere .. ' (talker LIKE ? OR text LIKE ?)'
		table.insert(aValue, szSearch)
		table.insert(aValue, szSearch)
	end
	if #szWhere > 0 then
		if X.StringFindW(szSQL, ' WHERE ') then
			szSQL = szSQL .. ' AND' .. szWhere
		else
			szSQL = szSQL .. ' WHERE' .. szWhere
		end
	end
	return szSQL
end

local function AppendCommonLimit(szSQL, aValue, nOffset, nLimit)
	if (nOffset and not nLimit) or X.IsHugeNumber(nLimit) then
		nLimit = -1
	end
	if nLimit then
		szSQL = szSQL .. ' LIMIT ?'
		table.insert(aValue, nLimit)
	end
	if nOffset then
		szSQL = szSQL .. ' OFFSET ?'
		table.insert(aValue, nOffset)
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
			self.db = X.SQLiteConnect(_L['MY_ChatLog'], self.szFilePath)
		else
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_ChatLog'], 'Quick connect database: ' .. self.szFilePath, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			self.db = SQLite3_Open(self.szFilePath)
		end
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Init database with STMT', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		if self.db then
			X.SQLiteExecute(self.db, [[
				CREATE TABLE IF NOT EXISTS ChatInfo (
					key NVARCHAR(128) NOT NULL,
					value NVARCHAR(4096) NOT NULL,
					PRIMARY KEY (key)
				)
			]])
			self.stmtInfoGet = X.SQLitePrepare(self.db, 'SELECT value FROM ChatInfo WHERE key = ?')
			self.stmtInfoSet = X.SQLitePrepare(self.db, 'REPLACE INTO ChatInfo (key, value) VALUES (?, ?)')
			X.SQLiteExecute(self.db, [[
				CREATE TABLE IF NOT EXISTS ChatLog (
					hash INTEGER NOT NULL,
					type VARCHAR(64) NOT NULL,
					time INTEGER NOT NULL,
					talker NVARCHAR(20) NOT NULL,
					text NVARCHAR(400) NOT NULL,
					msg NVARCHAR(4000) NOT NULL,
					PRIMARY KEY (time, hash)
				)
			]])
			X.SQLiteExecute(self.db, 'CREATE INDEX IF NOT EXISTS ChatLog_type_idx ON ChatLog(type)')
			X.SQLiteExecute(self.db, 'CREATE INDEX IF NOT EXISTS ChatLog_talker_idx ON ChatLog(talker)')
			X.SQLiteExecute(self.db, 'CREATE INDEX IF NOT EXISTS ChatLog_text_idx ON ChatLog(text)')
			self.stmtCount = X.SQLitePrepare(self.db, 'SELECT type AS szMsgType, COUNT(*) AS nCount FROM ChatLog WHERE talker LIKE ? OR text LIKE ? GROUP BY szMsgType')
			self.stmtInsert = X.SQLitePrepare(self.db, 'REPLACE INTO ChatLog (hash, type, time, talker, text, msg) VALUES (?, ?, ?, ?, ?, ?)')
			self.stmtDelete = X.SQLitePrepare(self.db, 'DELETE FROM ChatLog WHERE hash = ? AND time = ?')
		end
		if self:IsConnected() then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_ChatLog'], 'Init database finished: ' .. self.szFilePath, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return true
		end
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Init database failed: ' .. self.szFilePath, X.DEBUG_LEVEL.WARNING)
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
	X.SQLiteExecute(self.db, 'VACUUM')
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
	X.SQLitePrepareExecute(self.stmtInfoSet, szKey, X.EncodeLUAData(oValue))
	return true
end

function DB:GetInfo(szKey)
	if not self:Connect() then
		return nil, false
	end
	local res, success = X.Get(X.SQLitePrepareGetOne(self.stmtInfoGet, szKey), {'value'})
	if success then
		res = X.DecodeLUAData(res)
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
		nMaxTime = math.huge
	end
	local nMaxRecTime = self:GetMaxRecTime()
	assert(nMaxRecTime <= nMaxTime, '[MY_ChatLog_DB:SetMaxTime] MaxTime cannot be smaller than MaxRecTime.')
	self:SetInfo('max_time', X.IsHugeNumber(nMaxTime) and 0 or nMaxTime)
	self._nMaxTime = nMaxTime
	return true
end

function DB:GetMaxTime()
	if not self._nMaxTime then
		self._nMaxTime = self:GetInfo('max_time') or 0
		if self._nMaxTime == 0 then
			self._nMaxTime = math.huge
		end
	end
	return self._nMaxTime
end

function DB:InsertMsg(szMsgType, szText, szMsg, szTalker, nTime, szHash)
	local nMinTime, nMaxTime = self:GetMinTime(), self:GetMaxTime()
	assert(nTime >= nMinTime and nTime <= nMaxTime,
		'[MY_ChatLog_DB:InsertMsg] Time(' ..nTime .. ') must between MinTime(' .. nMinTime .. ') and MaxTime(' .. nMaxTime .. ').')
	if not szMsgType or not nTime or X.IsEmpty(szMsg) or not szText or X.IsEmpty(szHash) then
		return
	end
	table.insert(self.aInsertQueue, {szHash = szHash, szMsgType = szMsgType, nTime = nTime, szTalker = szTalker, szText = szText, szMsg = szMsg})
end

function DB:CountMsg(aMsgType, szSearch, nMinTime, nMaxTime)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if X.IsTable(aMsgType) and X.IsEmpty(aMsgType) then
		return 0
	end
	szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
	local bMinTime = X.IsNumber(nMinTime) and nMinTime > self:GetMinTime()
	local bMaxTime = X.IsNumber(nMaxTime) and nMaxTime < self:GetMaxTime()
	if not aMsgType and X.IsEmpty(szSearch) and not bMinTime and not bMaxTime then
		if not self.nCountCache then
			self.nCountCache = X.Get(X.SQLiteGetAll(self.db, 'SELECT COUNT(*) AS nCount FROM ChatLog'), {1, 'nCount'}, 0)
		end
		return self.nCountCache
	end
	if not self.tCountCache then
		self.tCountCache = {}
	end
	local szKey = szSearch
		.. '_' .. (bMinTime and nMinTime or '0')
		.. '_' .. (bMaxTime and nMaxTime or 'inf')
	local tCount = self.tCountCache[szKey]
	if not tCount then
		local aResult
		if X.IsEmpty(szSearch) and not bMinTime and not bMaxTime then
			aResult = X.SQLiteGetAll(self.db, 'SELECT type AS szMsgType, COUNT(*) AS nCount FROM ChatLog GROUP BY type')
		elseif bMinTime or bMaxTime then
			local szSQL = 'SELECT type AS szMsgType, COUNT(*) AS nCount FROM ChatLog'
			local aValue = {}
			szSQL = AppendCommonWhere(szSQL, aValue, aMsgType, szSearch, nMinTime, nMaxTime)
			aResult = X.SQLitePrepareGetAll(X.SQLitePrepare(self.db, szSQL), unpack(aValue))
		else
			aResult = X.SQLitePrepareGetAll(self.stmtCount, szSearch, szSearch)
		end
		tCount = {}
		for _, rec in ipairs(aResult) do
			if rec.szMsgType then
				tCount[rec.szMsgType] = rec.nCount
			end
		end
		self.tCountCache[szKey] = tCount
	end
	local nCount = 0
	if aMsgType then
		for _, szMsgType in ipairs(aMsgType) do
			nCount = nCount + (tCount[szMsgType] or 0)
		end
	else
		for _, n in pairs(tCount) do
			nCount = nCount + n
		end
	end
	return nCount
end

function DB:SelectMsg(aMsgType, szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if X.IsTable(aMsgType) and X.IsEmpty(aMsgType) then
		return {}
	end
	szSearch, nMinTime, nMaxTime, nOffset, nLimit = FormatCommonParam(szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	local szSQL, aValue = SELECT_MSG, {}
	szSQL = AppendCommonWhere(szSQL, aValue, aMsgType, szSearch, nMinTime, nMaxTime)
	szSQL = szSQL .. ' ORDER BY nTime ASC'
	szSQL = AppendCommonLimit(szSQL, aValue, nOffset, nLimit)
	return X.SQLiteGetAll(self.db, szSQL, unpack(aValue))
end

function DB:GetMinRecTime()
	if not self:Connect() then
		return false
	end
	self:Flush()
	local rec = X.SQLiteGetAll(self.db, 'SELECT time AS nTime FROM ChatLog ORDER BY nTime ASC LIMIT 1')[1]
	return rec and rec.nTime or -1
end

function DB:GetMaxRecTime()
	if not self:Connect() then
		return false
	end
	self:Flush()
	local rec = X.SQLiteGetAll(self.db, 'SELECT time AS nTime FROM ChatLog ORDER BY nTime DESC LIMIT 1')[1]
	return rec and rec.nTime or -1
end

function DB:DeleteMsg(szHash, nTime)
	if nTime and not X.IsEmpty(szHash) then
		table.insert(self.aDeleteQueue, {szHash = szHash, nTime = nTime})
	end
end

function DB:DeleteMsgByCondition(aMsgType, szSearch, nMinTime, nMaxTime)
	if not self:Connect() then
		return false
	end
	self:Flush()
	if X.IsTable(aMsgType) and X.IsEmpty(aMsgType) then
		return true
	end
	szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
	local szSQL, aValue = DELETE_MSG, {}
	szSQL = AppendCommonWhere(szSQL, aValue, aMsgType, szSearch, nMinTime, nMaxTime)
	if szSQL ~= DELETE_MSG then
		X.SQLiteGetAll(self.db, szSQL, unpack(aValue))
		self:FlushCache()
		return true
	end
	return false
end

function DB:Flush()
	if not X.IsEmpty(self.aInsertQueue) or not X.IsEmpty(self.aDeleteQueue) then
		if not self:Connect() then
			return false
		end
		X.SQLiteBeginTransaction(self.db)
		-- 插入记录
		for _, data in ipairs(self.aInsertQueue) do
			X.SQLitePrepareExecute(self.stmtInsert, data.szHash, data.szMsgType, data.nTime, data.szTalker, data.szText, data.szMsg)
		end
		self.aInsertQueue = {}
		-- 删除记录
		for _, data in ipairs(self.aDeleteQueue) do
			X.SQLitePrepareExecute(self.stmtDelete, data.szHash, data.nTime)
		end
		self.aDeleteQueue = {}
		X.SQLiteEndTransaction(self.db)
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
