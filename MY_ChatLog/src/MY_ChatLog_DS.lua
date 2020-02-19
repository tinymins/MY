--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 数据库集群控制器
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- 数据库控制器
------------------------------------------------------------------------------------------------------
local EXPORT_SLICE = 100
local SINGLE_DB_AMOUNT = 20000 -- 单个数据库节点最大数量
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
local CHANNELS_R = LIB.FlipObjectKV(CHANNELS)

local function SToNChannel(aChannel)
	local aNChannel = {}
	for _, szChannel in ipairs(aChannel) do
		insert(aNChannel, CHANNELS_R[szChannel])
	end
	return aNChannel
end

local function NewDB(szRoot, nMinTime, nMaxTime)
	local szPath
	repeat
		szPath = szRoot .. ('chatlog_%x'):format(math.random(0x100000, 0xFFFFFF)) .. '.db'
	until not IsLocalFileExist(szPath)
	local db = MY_ChatLog_DB(szPath)
	db:SetMinTime(nMinTime)
	db:SetMaxTime(nMaxTime)
	db:SetInfo('user_global_id', GetClientPlayer().GetGlobalID())
	return db
end

local function SortDB(aDB)
	sort(aDB, function(a, b) return a:GetMinTime() < b:GetMinTime() end)
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
		LIB.Debug(_L['MY_ChatLog'], 'Init node list...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for _, szName in ipairs(CPath.GetFileList(self.szRoot) or {}) do
			local db, bConn = szName:find('^chatlog_[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]%.db$') and MY_ChatLog_DB(self.szRoot .. szName)
			if db then
				if bFixProblem then
					bConn = db:Connect(true)
					if bConn then
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Checking malformed node ' .. db:ToString(), DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						local nMinTime, nMinRecTime = db:GetMinTime(), db:GetMinRecTime()
						if nMinRecTime < nMinTime then
							--[[#DEBUG BEGIN]]
							LIB.Debug(_L['MY_ChatLog'], 'Fix min time of ' .. db:ToString() .. ' from ' .. nMinTime .. ' to ' .. nMinRecTime, DEBUG_LEVEL.WARNING)
							--[[#DEBUG END]]
							db:SetMinTime(nMinRecTime)
						end
						local nMaxTime, nMaxRecTime = db:GetMaxTime(), db:GetMaxRecTime()
						if nMaxRecTime > nMaxTime then
							--[[#DEBUG BEGIN]]
							LIB.Debug(_L['MY_ChatLog'], 'Fix max time of ' .. db:ToString() .. ' from ' .. nMaxTime .. ' to ' .. nMaxRecTime, DEBUG_LEVEL.WARNING)
							--[[#DEBUG END]]
							db:SetMaxTime(nMaxRecTime)
						end
					else
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Connect failed for checking malformed node ' .. db:ToString(), DEBUG_LEVEL.WARNING)
						--[[#DEBUG END]]
					end
				else
					bConn = db:Connect()
				end
				if bConn and db:GetInfo('user_global_id') == GetClientPlayer().GetGlobalID() then
					insert(aDB, db)
				else
					--[[#DEBUG BEGIN]]
					if bConn then
						LIB.Debug(_L['MY_ChatLog'], 'Ignore foreign node ' .. db:ToString(), DEBUG_LEVEL.WARNING)
					else
						LIB.Debug(_L['MY_ChatLog'], 'Ignore unconnectable node ' .. db:ToString(), DEBUG_LEVEL.WARNING)
					end
					--[[#DEBUG END]]
					db:Disconnect()
				end
			end
		end
		SortDB(aDB)
		-- 删除集群中错误的空节点
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Check empty node...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for i, db in ipairs_r(aDB) do
			if not (i == #aDB and IsHugeNumber(db:GetMaxTime())) and db:CountMsg() == 0 then
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Removing unexpected empty node: ' .. db:ToString(), DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				db:DeleteDB()
				remove(aDB, i)
			end
		end
		-- 修复覆盖区域不连续的节点（覆盖区中断问题、分段冲突问题）
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Check node continuously...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		do
			local i = 1
			while i < #aDB do
				local db1, db2 = aDB[i], aDB[i + 1]
				-- 检测中间节点最大值
				if IsHugeNumber(db1:GetMaxTime()) then
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Unexpected huge MaxTime: ' .. db1:ToString(), DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					if not bFixProblem then
						return false
					end
					db1:SetMaxTime(db1:GetMaxRecTime())
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Fix unexpected huge MaxTime: ' .. db1:ToString(), DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
				end
				-- 检测区域连续性
				if db1:GetMaxTime() ~= db2:GetMinTime() then
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Unexpected noncontinuously time between ' .. db1:ToString() .. ' and ' .. db2:ToString(), DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					if not bFixProblem then
						return false
					end
					if db1:GetMaxRecTime() <= db2:GetMinTime() then -- 覆盖区中断 扩充左侧区域
						db1:SetMaxTime(db2:GetMinTime())
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Fix noncontinuously time by modify ' .. db1:ToString(), DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					elseif db1:GetMaxTime() <= db2:GetMinRecTime() then -- 覆盖区中断 扩充右侧区域
						db2:SetMinTime(db1:GetMaxTime())
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Fix noncontinuously time by modify ' .. db2:ToString(), DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					elseif db1:GetMaxTime() >= db2:GetMaxTime() then -- 覆盖区冲突 右侧区域完全被左侧区域包裹 将右侧节点并入左侧节点中
						for _, rec in ipairs(db2:SelectMsg()) do
							db1:InsertMsg(rec.nChannel, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
						end
						db1:Flush()
						db2:DeleteDB()
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Fix noncontinuously time by merge ' .. db2:ToString() .. ' to ' .. db1:ToString(), DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						remove(aDB, i + 1)
						i = i - 1
					else -- 覆盖区域冲突 将右侧节点的冲突区域数据移动到左侧节点中
						db1:SetMaxTime(db1:GetMaxRecTime())
						for _, rec in ipairs(db2:SelectMsg(nil, nil, 0, db1:GetMaxTime())) do
							db1:InsertMsg(rec.nChannel, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
						end
						db1:Flush()
						db2:DeleteMsgInterval(nil, nil, 0, db1:GetMaxTime())
						db2:SetMinTime(db1:GetMaxTime())
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Fix noncontinuously time by moving data from ' .. db2:ToString() .. ' to ' .. db1:ToString(), DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					end
				end
				i = i + 1
			end
		end
		-- 检查集群最新活跃节点是否存在
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Check latest node...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local db = aDB[#aDB]
		if db and IsHugeNumber(db:GetMaxTime()) then -- 存在： 检查集群最新活跃节点压力是否超限
			if db:CountMsg() > SINGLE_DB_AMOUNT then
				db:SetMaxTime(db:GetMaxRecTime())
				local dbNew = NewDB(self.szRoot, db:GetMaxTime(), HUGE)
				insert(aDB, dbNew)
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Create new empty active node ' .. dbNew:ToString() .. ' after ' .. db:ToString(), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		else -- 不存在： 创建
			local nMinTime = 0
			if db then
				local nMaxTime = db:GetMaxRecTime()
				db:SetMaxTime(nMaxTime)
				nMinTime = nMaxTime
			end
			local dbNew = NewDB(self.szRoot, nMinTime, HUGE)
			insert(aDB, dbNew)
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_ChatLog'], 'Create new empty active node ' .. dbNew:ToString(), DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
		-- 检查集群最久远节点开始时间是否为0
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Check oldest node...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local db = aDB[1]
		if db:GetMinTime() ~= 0 then
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_ChatLog'], 'Unexpected MinTime for first DB: ' .. db:ToString(), DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			db:SetMinTime(0)
			--[[#DEBUG BEGIN]]
			LIB.Debug(_L['MY_ChatLog'], 'Fix unexpected MinTime for first DB: ' .. db:ToString(), DEBUG_LEVEL.LOG)
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
	LIB.Debug(_L['MY_ChatLog'], 'OptimizeDB Start!', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	if self:ReinitDB(true) then
		--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'Checking node time zone overflow...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for _, db in ipairs(self.aDB) do
			local nMinTime, nMinRecTime = db:GetMinTime(), db:GetMinRecTime()
			if nMinTime > nMinRecTime then
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Node logic error detected: MinTime > MinRecTime in ' .. db:ToString(), DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				db:SetMinTime(nMinRecTime)
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Fix logic error: ' .. db:ToString(), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
			local nMaxTime, nMaxRecTime = db:GetMaxTime(), db:GetMaxRecTime()
			if nMaxTime < nMaxRecTime then
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Node logic error detected: MaxTime < MaxRecTime in ' .. db:ToString(), DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				db:SetMaxTime(nMaxRecTime)
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Fix logic error: ' .. db:ToString(), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		end
		SortDB(self.aDB)
		local i = 1
		while i <= #self.aDB do
			local db = self.aDB[i]
			if db:CountMsg() > SINGLE_DB_AMOUNT then -- 单个节点压力过大 转移超出部分到下一个节点
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Node count exceed limit: ' .. db:ToString() .. ' ' .. db:CountMsg(), DEBUG_LEVEL.WARNING)
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
						dbNew:InsertMsg(rec.nChannel, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
						db:DeleteMsg(rec.szHash, rec.nTime)
					end
					dbNew:Flush()
					nOffset = nOffset + SINGLE_DB_AMOUNT
					i = i + 1
					insert(self.aDB, i, dbNew)
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Moving ' .. SINGLE_DB_AMOUNT .. ' records from ' .. db:ToString() .. ' to ' .. dbNew:ToString(), DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
				end
				-- 处理剩下不超过单个节点最大负载的结果
				if nCount - nOffset == 0 then
					-- 刚好没有了 且当前是活跃节点 则创建新的活跃节点
					if i == #self.aDB then
						local dbNew = NewDB(self.szRoot, nMinTime, HUGE)
						i = i + 1
						insert(self.aDB, i, dbNew)
						--[[#DEBUG BEGIN]]
						LIB.Debug(_L['MY_ChatLog'], 'Create new active node: ' .. dbNew:ToString(), DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					end
				else
					-- 还有则合并到下一个节点
					local dbNext, rec
					if i == #self.aDB then
						dbNext = NewDB(self.szRoot, aRec[nOffset + 1].nTime, HUGE)
						i = i + 1
						insert(self.aDB, i, dbNext)
					else
						dbNext = self.aDB[i + 1]
						dbNext:SetMinTime(aRec[nOffset + 1].nTime)
					end
					for i = nOffset + 1, nCount do
						rec = aRec[i]
						db:DeleteMsg(rec.szHash, rec.nTime)
						dbNext:InsertMsg(rec.nChannel, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
					end
					dbNext:Flush()
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Moving ' .. #aRec .. ' records from ' .. db:ToString() .. ' to ' .. dbNext:ToString(), DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
				end
				db:Flush()
				db:SetMaxTime(nMaxTime)
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Modify node property: ' .. db:ToString(), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				-- 压缩数据库
				db:GarbageCollection()
				--[[#DEBUG BEGIN]]
				LIB.Debug(_L['MY_ChatLog'], 'Node GarbageCollection: ' .. db:ToString(), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			elseif db:CountMsg() < SINGLE_DB_AMOUNT then -- 单个节点压力过小 与下个节点合并
				if i < #self.aDB then
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Node count insufficient: ' .. db:ToString() .. ' ' .. db:CountMsg(), DEBUG_LEVEL.WARNING)
					--[[#DEBUG END]]
					local dbNext = self.aDB[i + 1]
					dbNext:SetMinTime(db:GetMinTime())
					for _, rec in ipairs(db:SelectMsg()) do
						dbNext:InsertMsg(rec.nChannel, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
					end
					dbNext:Flush()
					--[[#DEBUG BEGIN]]
					LIB.Debug(_L['MY_ChatLog'], 'Merge node ' .. db:ToString() .. ' to ' .. dbNext:ToString(), DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					db:DeleteDB()
					remove(self.aDB, i)
					i = i - 1
				end
			end
			i = i + 1
		end
	--[[#DEBUG BEGIN]]
		LIB.Debug(_L['MY_ChatLog'], 'OptimizeDB Finished!', DEBUG_LEVEL.LOG)
	else
		LIB.Debug(_L['MY_ChatLog'], 'OptimizeDB Failed! ReinitDB Failed!', DEBUG_LEVEL.WARNING)
	--[[#DEBUG END]]
	end
	return self
end

function DS:InsertMsg(szChannel, szText, szMsg, szTalker, nTime)
	if not szTalker then
		szTalker = ''
	end
	if szMsg and szText then
		local szuMsg    = AnsiToUTF8(szMsg)
		local szuText   = AnsiToUTF8(szText)
		local szHash    = GetStringCRC(szMsg)
		local szuTalker = AnsiToUTF8(szTalker)
		local nChannel  = CHANNELS_R[szChannel]
		if nChannel and nTime and not IsEmpty(szMsg) and szText and not IsEmpty(szHash) then
			insert(self.aInsertQueue, {szHash = szHash, nChannel = nChannel, nTime = nTime, szTalker = szuTalker, szText = szuText, szMsg = szuMsg})
			insert(self.aInsertQueueAnsi, {szHash = szHash, szChannel = szChannel, nTime = nTime, szTalker = szTalker, szText = szText, szMsg = szMsg})
		end
	end
	FireUIEvent('ON_MY_CHATLOG_INSERT_MSG', self.szRoot)
	return self
end

function DS:CountMsg(aChannel, szSearch)
	if #aChannel == 0 then
		return 0
	end
	if not self:InitDB() then
		return 0
	end
	if not szSearch then
		szSearch = ''
	end
	local szuSearch = szSearch == '' and '' or AnsiToUTF8('%' .. szSearch .. '%')
	local aNChannel, nCount = SToNChannel(aChannel), 0
	for _, db in ipairs(self.aDB) do
		nCount = nCount + db:CountMsg(aNChannel, szuSearch)
	end
	local tChannel = LIB.FlipObjectKV(aChannel)
	for _, rec in ipairs(self.aInsertQueueAnsi) do
		if tChannel[rec.szChannel] and (wfind(rec.szText, szSearch) or wfind(rec.szTalker, szSearch)) then
			nCount = nCount + 1
		end
	end
	return nCount
end

function DS:SelectMsg(aChannel, szSearch, nStartTime, nEndTime, nOffset, nLimit, bUTF8)
	if #aChannel == 0 then
		return {}
	end
	if not self:InitDB() then
		return {}
	end
	if not szSearch then
		szSearch = ''
	end
	local szuSearch = szSearch == '' and '' or AnsiToUTF8('%' .. szSearch .. '%')
	local aNChannel, aResult = SToNChannel(aChannel), {}
	for _, db in ipairs(self.aDB) do
		if nLimit == 0 then
			break
		end
		local nCount = db:CountMsg(aNChannel, szuSearch)
		if nOffset < nCount then
			local res = db:SelectMsg(aNChannel, szuSearch, nStartTime, nEndTime, nOffset, nLimit)
			if bUTF8 then
				for _, p in ipairs(res) do
					insert(aResult, p)
				end
			else
				for _, p in ipairs(res) do
					p.szChannel = CHANNELS[p.nChannel]
					p.nChannel = nil
					p.szTalker = UTF8ToAnsi(p.szTalker)
					p.szText = UTF8ToAnsi(p.szText)
					p.szMsg = UTF8ToAnsi(p.szMsg)
					insert(aResult, p)
				end
			end
			nLimit = max(nLimit - nCount + nOffset, 0)
		end
		nOffset = max(nOffset - nCount, 0)
	end
	if nLimit > 0 then
		local tChannel = LIB.FlipObjectKV(aChannel)
		local nCount = 0
		for i, rec in ipairs(self.aInsertQueueAnsi) do
			if nLimit == 0 then
				break
			end
			if tChannel[rec.szChannel] and (wfind(rec.szText, szSearch) or wfind(rec.szTalker, szSearch)) then
				if nOffset > 0 then
					nOffset = nOffset - 1
				else
					if bUTF8 then
						insert(aResult, Clone(self.aInsertQueue[i]))
					else
						insert(aResult, Clone(rec))
					end
					nLimit = nLimit - 1
				end
			end
		end
	end
	return aResult
end

function DS:DeleteMsg(szHash, nTime)
	if nTime and not IsEmpty(szHash) then
		insert(self.aDeleteQueue, {szHash = szHash, nTime = nTime})
	end
	return self
end

function DS:FlushDB()
	if (not IsEmpty(self.aInsertQueue) or not IsEmpty(self.aDeleteQueue)) and self:InitDB() then
		-- 插入记录
		sort(self.aInsertQueue, function(a, b) return a.nTime < b.nTime end)
		local i, db = 1, self.aDB[1]
		for _, p in ipairs(self.aInsertQueue) do
			while db and p.nTime > db:GetMaxTime() do
				i = i + 1
				db = self.aDB[i]
			end
			assert(db, 'ChatLog db indexing error while FlushDB: [i]' .. i .. ' [time]' .. p.nTime)
			db:InsertMsg(p.nChannel, p.szText, p.szMsg, p.szTalker, p.nTime, p.szHash)
		end
		self.aInsertQueue = {}
		self.aInsertQueueAnsi = {}
		-- 删除记录
		sort(self.aDeleteQueue, function(a, b) return a.nTime < b.nTime end)
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
