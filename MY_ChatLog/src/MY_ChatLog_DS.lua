--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 聊天记录 数据库集群控制器
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_DS'
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

------------------------------------------------------------------------------------------------------
-- 数据库控制器
------------------------------------------------------------------------------------------------------
local EXPORT_SLICE = 100
local SINGLE_DB_AMOUNT = 20000 -- 单个数据库节点最大数量

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

local function NewDB(szRoot, nMinTime, nMaxTime)
	local szPath
	repeat
		szPath = szRoot .. ('chatlog_%x'):format(X.Random(0x100000, 0xFFFFFF)) .. '.v2.db'
	until not IsLocalFileExist(szPath)
	local db = MY_ChatLog_DB(szPath)
	db:SetMinTime(nMinTime)
	db:SetMaxTime(nMaxTime)
	db:SetInfo('version', '2')
	db:SetInfo('user_global_id', X.GetClientPlayerGlobalID())
	return db
end

local function SortDB(aDB)
	table.sort(aDB, function(a, b) return a:GetMinTime() < b:GetMinTime() end)
end

local DS = class()
local DS_CACHE = setmetatable({}, {__mode = 'v'})

function DS:ctor(szRoot)
	self.szRoot = szRoot
	self.aInsertQueue = {}
	self.aDeleteQueue = {}
	self.aInsertQueueAnsi = {}
	return self
end

function DS:InitDB(bFixProblem)
	if not self.aDB then
		-- 初始化数据库集群列表
		local aDB = {}
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Init node list...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for _, szName in ipairs(CPath.GetFileList(self.szRoot) or {}) do
			local db, bConn = szName:find('^chatlog_[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]%.v2%.db$') and MY_ChatLog_DB(self.szRoot .. szName)
			if db then
				if bFixProblem then
					bConn = db:Connect(true)
					if bConn then
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Checking malformed node ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						local nMinTime, nMinRecTime = db:GetMinTime(), db:GetMinRecTime()
						if nMinRecTime < nMinTime then
							--[[#DEBUG BEGIN]]
							X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix min time of ' .. db:ToString() .. ' from ' .. nMinTime .. ' to ' .. nMinRecTime, X.DEBUG_LEVEL.WARNING)
							--[[#DEBUG END]]
							db:SetMinTime(nMinRecTime)
						end
						local nMaxTime, nMaxRecTime = db:GetMaxTime(), db:GetMaxRecTime()
						if nMaxRecTime > nMaxTime then
							--[[#DEBUG BEGIN]]
							X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix max time of ' .. db:ToString() .. ' from ' .. nMaxTime .. ' to ' .. nMaxRecTime, X.DEBUG_LEVEL.WARNING)
							--[[#DEBUG END]]
							db:SetMaxTime(nMaxRecTime)
						end
					else
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Connect failed for checking malformed node ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
						--[[#DEBUG END]]
					end
				else
					bConn = db:Connect()
				end
				if not bConn then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Ignore unconnectable node ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					db:Disconnect()
				elseif db:GetInfo('user_global_id') ~= X.GetClientPlayerGlobalID() then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Ignore foreign node ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					db:Disconnect()
				elseif db:GetInfo('version') ~= '2' then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Ignore other version node ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					db:Disconnect()
				else
					table.insert(aDB, db)
				end
			end
		end
		SortDB(aDB)
		-- 删除集群中错误的空节点
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Check empty node...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for i, db in X.ipairs_r(aDB) do
			if not (i == #aDB and X.IsHugeNumber(db:GetMaxTime())) and db:CountMsg() == 0 then
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Removing unexpected empty node: ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				db:DeleteDB()
				table.remove(aDB, i)
			end
		end
		-- 修复覆盖区域不连续的节点（覆盖区中断问题、分段冲突问题）
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Check node continuously...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		do
			local i = 1
			while i < #aDB do
				local db1, db2 = aDB[i], aDB[i + 1]
				-- 检测中间节点最大值
				if X.IsHugeNumber(db1:GetMaxTime()) then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Unexpected huge MaxTime: ' .. db1:ToString(), X.DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					if not bFixProblem then
						return false
					end
					db1:SetMaxTime(db1:GetMaxRecTime())
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix unexpected huge MaxTime: ' .. db1:ToString(), X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
				end
				-- 检测区域连续性
				if db1:GetMaxTime() ~= db2:GetMinTime() then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Unexpected noncontinuously time between ' .. db1:ToString() .. ' and ' .. db2:ToString(), X.DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					if not bFixProblem then
						return false
					end
					if db1:GetMaxRecTime() <= db2:GetMinTime() then -- 覆盖区中断 扩充左侧区域
						db1:SetMaxTime(db2:GetMinTime())
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix noncontinuously time by modify ' .. db1:ToString(), X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					elseif db1:GetMaxTime() <= db2:GetMinRecTime() then -- 覆盖区中断 扩充右侧区域
						db2:SetMinTime(db1:GetMaxTime())
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix noncontinuously time by modify ' .. db2:ToString(), X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					elseif db1:GetMaxTime() >= db2:GetMaxTime() then -- 覆盖区冲突 右侧区域完全被左侧区域包裹 将右侧节点并入左侧节点中
						for _, rec in ipairs(db2:SelectMsg()) do
							db1:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
						end
						db1:Flush()
						db2:DeleteDB()
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix noncontinuously time by merge ' .. db2:ToString() .. ' to ' .. db1:ToString(), X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						table.remove(aDB, i + 1)
						i = i - 1
					else -- 覆盖区域冲突 将右侧节点的冲突区域数据移动到左侧节点中
						db1:SetMaxTime(db1:GetMaxRecTime())
						for _, rec in ipairs(db2:SelectMsg(nil, nil, 0, db1:GetMaxTime())) do
							db1:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
						end
						db1:Flush()
						db2:DeleteMsgByCondition(nil, nil, 0, db1:GetMaxTime())
						db2:SetMinTime(db1:GetMaxTime())
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix noncontinuously time by moving data from ' .. db2:ToString() .. ' to ' .. db1:ToString(), X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					end
				end
				i = i + 1
			end
		end
		-- 检查集群最新活跃节点是否存在
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Check latest node...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local db = aDB[#aDB]
		if db and X.IsHugeNumber(db:GetMaxTime()) then -- 存在： 检查集群最新活跃节点压力是否超限
			if db:CountMsg() > SINGLE_DB_AMOUNT then
				db:SetMaxTime(db:GetMaxRecTime())
				local dbNew = NewDB(self.szRoot, db:GetMaxTime(), math.huge)
				table.insert(aDB, dbNew)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Create new empty active node ' .. dbNew:ToString() .. ' after ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		else -- 不存在： 创建
			local nMinTime = 0
			if db then
				local nMaxTime = db:GetMaxRecTime()
				db:SetMaxTime(nMaxTime)
				nMinTime = nMaxTime
			end
			local dbNew = NewDB(self.szRoot, nMinTime, math.huge)
			table.insert(aDB, dbNew)
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_ChatLog'], 'Create new empty active node ' .. dbNew:ToString(), X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
		-- 检查集群最久远节点开始时间是否为0
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Check oldest node...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local db = aDB[1]
		if db:GetMinTime() ~= 0 then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_ChatLog'], 'Unexpected MinTime for first DB: ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			db:SetMinTime(0)
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix unexpected MinTime for first DB: ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
		self.aDB = aDB
	end
	return self
end

function DS:ReinitDB(bFixProblem)
	self:FlushDB()
	self:ReleaseDB()
	self.aDB = nil
	return self:InitDB(bFixProblem)
end

function DS:OptimizeDB()
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(_L['MY_ChatLog'], 'OptimizeDB Start!', X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	if self:ReinitDB(true) then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'Checking node time zone overflow...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for _, db in ipairs(self.aDB) do
			local nMinTime, nMinRecTime = db:GetMinTime(), db:GetMinRecTime()
			if nMinTime > nMinRecTime then
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Node logic error detected: MinTime > MinRecTime in ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				db:SetMinTime(nMinRecTime)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix logic error: ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
			local nMaxTime, nMaxRecTime = db:GetMaxTime(), db:GetMaxRecTime()
			if nMaxTime < nMaxRecTime then
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Node logic error detected: MaxTime < MaxRecTime in ' .. db:ToString(), X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				db:SetMaxTime(nMaxRecTime)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Fix logic error: ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		end
		SortDB(self.aDB)
		local i = 1
		while i <= #self.aDB do
			local db = self.aDB[i]
			if db:CountMsg() > SINGLE_DB_AMOUNT then -- 单个节点压力过大 转移超出部分到下一个节点
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Node count exceed limit: ' .. db:ToString() .. ' ' .. db:CountMsg(), X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				local aRec = db:SelectMsg(nil, nil, nil, nil, SINGLE_DB_AMOUNT)
				local nMaxTime, nMinTime = aRec[1].nTime, aRec[#aRec].nTime
				-- 超出部分超过单个节点最大负载 直接独立节点
				local nCount, nOffset = #aRec, 0
				while nOffset + SINGLE_DB_AMOUNT < nCount do
					local dbNew, rec = NewDB(
						self.szRoot,
						aRec[nOffset + 1].nTime,
						(aRec[nOffset + SINGLE_DB_AMOUNT + 1] or aRec[nOffset + SINGLE_DB_AMOUNT]).nTime)
					for i = 1, SINGLE_DB_AMOUNT do
						rec = aRec[nOffset + i]
						dbNew:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
						db:DeleteMsg(rec.szHash, rec.nTime)
					end
					dbNew:Flush()
					nOffset = nOffset + SINGLE_DB_AMOUNT
					i = i + 1
					table.insert(self.aDB, i, dbNew)
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Moving ' .. SINGLE_DB_AMOUNT .. ' records from ' .. db:ToString() .. ' to ' .. dbNew:ToString(), X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
				end
				-- 处理剩下不超过单个节点最大负载的结果
				if nCount - nOffset == 0 then
					-- 刚好没有了 且当前是活跃节点 则创建新的活跃节点
					if i == #self.aDB then
						local dbNew = NewDB(self.szRoot, nMinTime, math.huge)
						i = i + 1
						table.insert(self.aDB, i, dbNew)
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage(_L['MY_ChatLog'], 'Create new active node: ' .. dbNew:ToString(), X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					end
				else
					-- 还有则合并到下一个节点
					local dbNext, rec
					if i == #self.aDB then
						dbNext = NewDB(self.szRoot, aRec[nOffset + 1].nTime, math.huge)
						i = i + 1
						table.insert(self.aDB, i, dbNext)
					else
						dbNext = self.aDB[i + 1]
						dbNext:SetMinTime(aRec[nOffset + 1].nTime)
					end
					for i = nOffset + 1, nCount do
						rec = aRec[i]
						db:DeleteMsg(rec.szHash, rec.nTime)
						dbNext:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
					end
					dbNext:Flush()
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Moving ' .. #aRec .. ' records from ' .. db:ToString() .. ' to ' .. dbNext:ToString(), X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
				end
				db:Flush()
				db:SetMaxTime(nMaxTime)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Modify node property: ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				-- 压缩数据库
				db:GarbageCollection()
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(_L['MY_ChatLog'], 'Node GarbageCollection: ' .. db:ToString(), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			elseif db:CountMsg() < SINGLE_DB_AMOUNT then -- 单个节点压力过小 与下个节点合并
				if i < #self.aDB then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Node count insufficient: ' .. db:ToString() .. ' ' .. db:CountMsg(), X.DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					local dbNext = self.aDB[i + 1]
					dbNext:SetMinTime(db:GetMinTime())
					for _, rec in ipairs(db:SelectMsg()) do
						dbNext:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
					end
					dbNext:Flush()
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(_L['MY_ChatLog'], 'Merge node ' .. db:ToString() .. ' to ' .. dbNext:ToString(), X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					db:DeleteDB()
					table.remove(self.aDB, i)
					i = i - 1
				end
			end
			i = i + 1
		end
	--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(_L['MY_ChatLog'], 'OptimizeDB Finished!', X.DEBUG_LEVEL.LOG)
	else
		X.OutputDebugMessage(_L['MY_ChatLog'], 'OptimizeDB Failed! ReinitDB Failed!', X.DEBUG_LEVEL.WARNING)
	--[[#DEBUG END]]
	end
	return self
end

function DS:InsertMsg(szMsgType, szText, szMsg, szTalker, nTime)
	if not szTalker then
		szTalker = ''
	end
	if szMsg and szText then
		local szuMsg    = AnsiToUTF8(szMsg)
		local szuText   = AnsiToUTF8(szText)
		local szHash    = GetStringCRC(szMsg)
		local szuTalker = AnsiToUTF8(szTalker)
		if szMsgType and nTime and not X.IsEmpty(szMsg) and szText and not X.IsEmpty(szHash) then
			table.insert(self.aInsertQueue, {szHash = szHash, szMsgType = szMsgType, nTime = nTime, szTalker = szuTalker, szText = szuText, szMsg = szuMsg})
			table.insert(self.aInsertQueueAnsi, {szHash = szHash, szMsgType = szMsgType, nTime = nTime, szTalker = szTalker, szText = szText, szMsg = szMsg})
		end
	end
	FireUIEvent('ON_MY_CHATLOG_INSERT_MSG', self.szRoot)
	return self
end

function DS:CountMsg(aMsgType, szSearch, nMinTime, nMaxTime)
	if X.IsTable(aMsgType) and X.IsEmpty(aMsgType) then
		return 0
	end
	if not self:InitDB() then
		return 0
	end
	szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
	local szuSearch = X.IsEmpty(szSearch) and '' or AnsiToUTF8('%' .. szSearch .. '%')
	local nCount = 0
	for _, db in ipairs(self.aDB) do
		nCount = nCount + db:CountMsg(aMsgType, szuSearch, nMinTime, nMaxTime)
	end
	local tMsgType = aMsgType and X.FlipObjectKV(aMsgType)
	for _, rec in ipairs(self.aInsertQueueAnsi) do
		if rec.nTime >= nMinTime
		and rec.nTime <= nMaxTime
		and (not tMsgType or tMsgType[rec.szMsgType])
		and (szSearch == '' or X.StringFindW(rec.szText, szSearch) or X.StringFindW(rec.szTalker, szSearch)) then
			nCount = nCount + 1
		end
	end
	return nCount
end

function DS:SelectMsg(aMsgType, szSearch, nMinTime, nMaxTime, nOffset, nLimit, bUTF8)
	if X.IsTable(aMsgType) and X.IsEmpty(aMsgType) then
		return {}
	end
	if not self:InitDB() then
		return {}
	end
	szSearch, nMinTime, nMaxTime, nOffset, nLimit = FormatCommonParam(szSearch, nMinTime, nMaxTime, nOffset, nLimit)
	local szuSearch = X.IsEmpty(szSearch) and '' or AnsiToUTF8('%' .. szSearch .. '%')
	local aResult = {}
	for _, db in ipairs(self.aDB) do
		if nLimit == 0 then
			break
		end
		local nCount = db:CountMsg(aMsgType, szuSearch, nMinTime, nMaxTime)
		if nOffset < nCount then
			local res = db:SelectMsg(aMsgType, szuSearch, nMinTime, nMaxTime, nOffset, nLimit)
			if bUTF8 then
				for _, p in ipairs(res) do
					table.insert(aResult, p)
				end
			else
				for _, p in ipairs(res) do
					p.szMsgType = p.szMsgType
					p.szTalker = UTF8ToAnsi(p.szTalker)
					p.szText = UTF8ToAnsi(p.szText)
					p.szMsg = UTF8ToAnsi(p.szMsg)
					table.insert(aResult, p)
				end
			end
			if not X.IsHugeNumber(nLimit) then
				nLimit = math.max(nLimit - nCount + nOffset, 0)
			end
		end
		nOffset = math.max(nOffset - nCount, 0)
	end
	if X.IsHugeNumber(nLimit) or nLimit > 0 then
		local tMsgType = aMsgType and X.FlipObjectKV(aMsgType)
		for i, rec in ipairs(self.aInsertQueueAnsi) do
			if nLimit == 0 then
				break
			end
			if rec.nTime >= nMinTime
			and rec.nTime <= nMaxTime
			and (not tMsgType or tMsgType[rec.szMsgType])
			and (szSearch == '' or X.StringFindW(rec.szText, szSearch) or X.StringFindW(rec.szTalker, szSearch)) then
				if nOffset > 0 then
					nOffset = nOffset - 1
				else
					if bUTF8 then
						table.insert(aResult, X.Clone(self.aInsertQueue[i]))
					else
						table.insert(aResult, X.Clone(rec))
					end
					if not X.IsHugeNumber(nLimit) then
						nLimit = nLimit - 1
					end
				end
			end
		end
	end
	return aResult
end

function DS:FindMsgIndex(aMsgType, szSearch, nMinTime, nMaxTime, nTime, szHash)
	szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
	if nMinTime > nTime or nMaxTime < nTime then
		return -1
	end
	local nIndex = self:CountMsg(aMsgType, szSearch, nMinTime, nTime - 1)
	local aMsg = self:SelectMsg(aMsgType, szSearch, nTime, nTime)
	for _, v in ipairs(aMsg) do
		if v.szHash == szHash then
			return nIndex
		end
		nIndex = nIndex + 1
	end
	return -1
end

function DS:DeleteMsg(szHash, nTime)
	if nTime and not X.IsEmpty(szHash) then
		table.insert(self.aDeleteQueue, {szHash = szHash, nTime = nTime})
	end
	return self
end

function DS:DeleteMsgByCondition(aMsgType, szSearch, nMinTime, nMaxTime)
	if self:InitDB() then
		self:FlushDB()
		szSearch, nMinTime, nMaxTime = FormatCommonParam(szSearch, nMinTime, nMaxTime)
		local szuSearch = X.IsEmpty(szSearch) and '' or AnsiToUTF8('%' .. szSearch .. '%')
		for _, db in ipairs(self.aDB) do
			if (X.IsEmpty(nMaxTime) or X.IsHugeNumber(nMaxTime) or db:GetMinTime() <= nMaxTime)
			and (X.IsEmpty(nMinTime) or db:GetMaxTime() >= nMinTime) then
				db:DeleteMsgByCondition(aMsgType, szuSearch, nMinTime, nMaxTime)
			end
		end
	end
	return self
end

function DS:FlushDB()
	if (not X.IsEmpty(self.aInsertQueue) or not X.IsEmpty(self.aDeleteQueue)) and self:InitDB() then
		-- 插入记录
		table.sort(self.aInsertQueue, function(a, b) return a.nTime < b.nTime end)
		local i, db = 1, self.aDB[1]
		for _, p in ipairs(self.aInsertQueue) do
			while db and p.nTime > db:GetMaxTime() do
				i = i + 1
				db = self.aDB[i]
			end
			assert(db, 'ChatLog db indexing error while FlushDB: [i]' .. i .. ' [time]' .. p.nTime)
			db:InsertMsg(p.szMsgType, p.szText, p.szMsg, p.szTalker, p.nTime, p.szHash)
		end
		self.aInsertQueue = {}
		self.aInsertQueueAnsi = {}
		-- 删除记录
		table.sort(self.aDeleteQueue, function(a, b) return a.nTime < b.nTime end)
		local i, db = 1, self.aDB[1]
		for _, p in ipairs(self.aDeleteQueue) do
			while db and p.nTime > db:GetMaxTime() do
				i = i + 1
				db = self.aDB[i]
			end
			assert(db, 'ChatLog db indexing error while FlushDB: [i]' .. i .. ' [time]' .. p.nTime)
			db:DeleteMsg(p.szHash, p.nTime)
		end
		self.aDeleteQueue = {}
		-- 执行数据库操作
		for _, db in ipairs(self.aDB) do
			db:Flush()
		end
	end
	return self
end

function DS:ReleaseDB()
	if self.aDB then
		for _, db in ipairs(self.aDB) do
			db:Disconnect()
		end
		self.aDB = nil
	end
	return self
end

function MY_ChatLog_DS(szRoot)
	if not DS_CACHE[szRoot] then
		DS_CACHE[szRoot] = DS.new(szRoot)
	end
	return DS_CACHE[szRoot]
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
