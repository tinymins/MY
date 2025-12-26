--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : SQLite
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Storage.SQLite')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local EncodeByteData = X.GetGameAPI('EncodeByteData')
local DecodeByteData = X.GetGameAPI('DecodeByteData')

local function RenameDatabase(szCaption, szPath)
	local i = 0
	local szMalformedPath
	repeat
		szMalformedPath = szPath .. '.' .. i ..  '.malformed'
		i = i + 1
	until not IsLocalFileExist(szMalformedPath)
	CPath.Move(szPath, szMalformedPath)
	if not IsLocalFileExist(szMalformedPath) then
		return
	end
	return szMalformedPath
end

local function DuplicateDatabase(DB_SRC, DB_DST, szCaption)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(szCaption, 'Duplicate database start.', X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	-- 运行 DDL 语句 创建表和索引等
	for _, rec in ipairs(DB_SRC:Execute('SELECT sql FROM sqlite_master')) do
		DB_DST:Execute(rec.sql)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(szCaption, 'Duplicating database: ' .. rec.sql, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	-- 读取表名 依次复制
	for _, rec in ipairs(DB_SRC:Execute('SELECT name FROM sqlite_master WHERE type=\'table\'')) do
		-- 读取列名
		local szTableName, aColumns, aPlaceholders = rec.name, {}, {}
		for _, rec in ipairs(DB_SRC:Execute('PRAGMA table_info(' .. szTableName .. ')')) do
			table.insert(aColumns, rec.name)
			table.insert(aPlaceholders, '?')
		end
		local szColumns, szPlaceholders = table.concat(aColumns, ', '), table.concat(aPlaceholders, ', ')
		local nCount, nPageSize = X.Get(DB_SRC:Execute('SELECT COUNT(*) AS count FROM ' .. szTableName), {1, 'count'}, 0), 10000
		local DB_W = DB_DST:Prepare('REPLACE INTO ' .. szTableName .. ' (' .. szColumns .. ') VALUES (' .. szPlaceholders .. ')')
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(szCaption, 'Duplicating table: ' .. szTableName .. ' (cols)' .. szColumns .. ' (count)' .. nCount, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- 开始读取和写入数据
		DB_DST:Execute('BEGIN TRANSACTION')
		for i = 0, nCount / nPageSize do
			for _, rec in ipairs(DB_SRC:Execute('SELECT ' .. szColumns .. ' FROM ' .. szTableName .. ' LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
				local aValues = { n = #aColumns }
				for i, szKey in ipairs(aColumns) do
					aValues[i] = rec[szKey]
				end
				DB_W:ClearBindings()
				DB_W:BindAll(X.Unpack(aValues))
				DB_W:Execute()
			end
		end
		DB_W:Reset()
		DB_DST:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(szCaption, 'Duplicating table finished: ' .. szTableName, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end

local function ConnectMalformedDatabase(szCaption, szPath, bAlert)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(szCaption, 'Fixing malformed database...', X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local szMalformedPath = RenameDatabase(szCaption, szPath)
	if not szMalformedPath then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(szCaption, 'Fixing malformed database failed... Move file failed...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		return 'FILE_LOCKED'
	else
		local DB_DST = SQLite3_Open(szPath)
		local DB_SRC = SQLite3_Open(szMalformedPath)
		if DB_DST and DB_SRC then
			DuplicateDatabase(DB_SRC, DB_DST, szCaption)
			DB_SRC:Release()
			CPath.DelFile(szMalformedPath)
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(szCaption, 'Fixing malformed database finished...', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return 'SUCCESS', DB_DST
		elseif not DB_SRC then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(szCaption, 'Connect malformed database failed...', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return 'TRANSFER_FAILED', DB_DST
		end
	end
end

function X.SQLiteConnect(szCaption, oPath, fnAction)
	-- 尝试连接数据库
	local szPath = X.FormatPath(oPath)
	CPath.MakeDir(X.GetParentPath(szPath))
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(szCaption, 'Connect database: ' .. szPath, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local DB = SQLite3_Open(szPath)
	if not DB then
		-- 连不上直接重命名原始文件并重新连接
		if IsLocalFileExist(szPath) and RenameDatabase(szCaption, szPath) then
			DB = SQLite3_Open(szPath)
		end
		if not DB then
			X.OutputDebugMessage(szCaption, 'Cannot connect to database!!!', X.DEBUG_LEVEL.ERROR)
			if fnAction then
				fnAction()
			end
			return
		end
	end

	-- 测试数据库完整性
	local aRes = DB:Execute('PRAGMA QUICK_CHECK')
	if X.Get(aRes, {1, 'integrity_check'}) == 'ok' then
		if fnAction then
			fnAction(DB)
		end
		return DB
	else
		-- 记录错误日志
		X.OutputDebugMessage(szCaption, 'Malformed database detected...', X.DEBUG_LEVEL.ERROR)
		for _, rec in ipairs(aRes or {}) do
			X.OutputDebugMessage(szCaption, X.EncodeLUAData(rec), X.DEBUG_LEVEL.ERROR)
		end
		DB:Release()
		-- 准备尝试修复
		if fnAction then
			X.Confirm(_L('%s Database is malformed, do you want to repair database now? Repair database may take a long time and cause a disconnection.', szCaption), function()
				X.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					local szStatus, DB = ConnectMalformedDatabase(szCaption, szPath)
					if szStatus == 'FILE_LOCKED' then
						X.Alert(_L('Database file locked, repair database failed! : %s', szPath))
					else
						X.Alert(_L('%s Database repair finished!', szCaption))
					end
					fnAction(DB)
				end)
			end)
		else
			return select(2, ConnectMalformedDatabase(szCaption, szPath))
		end
	end
end

function X.SQLiteDisconnect(db)
	db:Release()
end

function X.SQLiteBeginTransaction(db)
	db:Execute('BEGIN TRANSACTION')
end

function X.SQLiteEndTransaction(db)
	db:Execute('END TRANSACTION')
end

function X.SQLiteGarbageCollection(db)
	db:Execute('VACUUM')
end

function X.SQLiteExecute(db, szSQL, ...)
	if select('#', ...) == 0 then
		return db:Execute(szSQL)
	end
	local stmt = X.SQLitePrepare(db, szSQL)
	if not stmt then
		return
	end
	return X.SQLitePrepareExecute(stmt, ...)
end

function X.SQLiteGetOne(db, szSQL, ...)
	local stmt = X.SQLitePrepare(db, szSQL)
	if not stmt then
		return
	end
	return X.SQLitePrepareGetOne(stmt, ...)
end

function X.SQLiteGetAll(db, szSQL, ...)
	local stmt = X.SQLitePrepare(db, szSQL)
	if not stmt then
		return
	end
	return X.SQLitePrepareGetAll(stmt, ...)
end

function X.SQLitePrepare(db, szPrepareSQL)
	return db:Prepare(szPrepareSQL)
end

function X.SQLitePrepareExecute(stmt, ...)
	stmt:ClearBindings()
	stmt:BindAll(...)
	stmt:Execute()
end

function X.SQLitePrepareGetOne(stmt, ...)
	stmt:ClearBindings()
	stmt:BindAll(...)
	local data = stmt:GetNext()
	stmt:Reset()
	return data
end

function X.SQLitePrepareGetAll(stmt, ...)
	stmt:ClearBindings()
	stmt:BindAll(...)
	local data = stmt:GetAll()
	stmt:Reset()
	return data
end

function X.SQLiteExecuteANSI(db, szSQL, ...)
	local szSQL = X.ConvertToUTF8(szSQL)
	local aParams = X.ConvertToUTF8({...})
	return X.ConvertToANSI(X.SQLiteExecute(db, szSQL, X.Unpack(aParams)))
end

function X.SQLiteGetOneANSI(db, szSQL, ...)
	local szSQL = X.ConvertToUTF8(szSQL)
	local aParams = X.ConvertToUTF8({...})
	return X.ConvertToANSI(X.SQLiteGetOne(db, szSQL, X.Unpack(aParams)))
end

function X.SQLiteGetAllANSI(db, szSQL, ...)
	local szSQL = X.ConvertToUTF8(szSQL)
	local aParams = X.ConvertToUTF8({...})
	return X.ConvertToANSI(X.SQLiteGetAll(db, szSQL, X.Unpack(aParams)))
end

function X.SQLitePrepareANSI(db, szPrepareSQL)
	local szPrepareSQL = X.ConvertToUTF8(szPrepareSQL)
	return X.ConvertToANSI(X.SQLitePrepare(db, szPrepareSQL))
end

function X.SQLitePrepareExecuteANSI(stmt, ...)
	local aParams = X.ConvertToUTF8({...})
	return X.ConvertToANSI(X.SQLitePrepareExecute(stmt, X.Unpack(aParams)))
end

function X.SQLitePrepareGetOneANSI(stmt, ...)
	local aParams = X.ConvertToUTF8({...})
	return X.ConvertToANSI(X.SQLitePrepareGetOne(stmt, X.Unpack(aParams)))
end

function X.SQLitePrepareGetAllANSI(stmt, ...)
	local aParams = X.ConvertToUTF8({...})
	return X.ConvertToANSI(X.SQLitePrepareGetAll(stmt, X.Unpack(aParams)))
end

------------------------------------------------------------------------------
-- 基于 SQLite 的 NoSQLite 封装
------------------------------------------------------------------------------

function X.NoSQLiteConnect(oPath)
	local db = X.SQLiteConnect('NoSQL', oPath)
	if not db then
		return
	end
	db:Execute('CREATE TABLE IF NOT EXISTS data (key NVARCHAR(256) NOT NULL, value BLOB, PRIMARY KEY (key))')
	local stmtSetter = db:Prepare('REPLACE INTO data (key, value) VALUES (?, ?)')
	local stmtGetter = db:Prepare('SELECT * FROM data WHERE key = ? LIMIT 1')
	local stmtDeleter = db:Prepare('DELETE FROM data WHERE key = ?')
	local stmtAllGetter = db:Prepare('SELECT * FROM data')
	if not stmtSetter or not stmtGetter or not stmtDeleter or not stmtAllGetter then
		X.NoSQLiteDisconnect(db)
		return
	end
	return setmetatable({}, {
		__index = {
			Set = function(_, k, v)
				if not stmtSetter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtSetter:ClearBindings()
				stmtSetter:BindAll(k, EncodeByteData(v))
				stmtSetter:Execute()
				stmtSetter:Reset()
			end,
			Get = function(_, k)
				if not stmtGetter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtGetter:ClearBindings()
				stmtGetter:BindAll(k)
				local res = stmtGetter:GetNext()
				stmtGetter:Reset()
				if res then
					-- res.value: KByteData
					res = DecodeByteData(res.value)
				end
				return res
			end,
			Delete = function(_, k)
				if not stmtDeleter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtDeleter:ClearBindings()
				stmtDeleter:BindAll(k)
				stmtDeleter:Execute()
				stmtDeleter:Reset()
			end,
			GetAll = function(_)
				if not stmtAllGetter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtAllGetter:ClearBindings()
				local res = stmtAllGetter:GetAll()
				stmtAllGetter:Reset()
				local tKvp = {}
				if res then
					for _, v in ipairs(res) do
						tKvp[v.key] = DecodeByteData(v.value)
					end
				end
				return tKvp
			end,
			Release = function(_)
				if stmtSetter then
					stmtSetter:Release()
					stmtSetter = nil
				end
				if stmtGetter then
					stmtGetter:Release()
					stmtGetter = nil
				end
				if stmtDeleter then
					stmtDeleter:Release()
					stmtDeleter = nil
				end
				if stmtAllGetter then
					stmtAllGetter:Release()
					stmtAllGetter = nil
				end
				if db then
					db:Release()
					db = nil
				end
			end,
		},
		__newindex = function() end,
	})
end

function X.NoSQLiteDisconnect(db)
	db:Release()
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
