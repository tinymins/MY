--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录数据源类
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKP_DS'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local DS = class()
local DS_CACHE = setmetatable({}, { __mode = 'v' })

local function GetClearData()
	return {
		GKP_Map = '',
		GKP_Time = 0,
		GKP_Record = {},
		GKP_Account = {},
	}
end

local function GetCache(DATA)
	local CACHE = {
		GKP_Record_Index = {},
		GKP_Account_Index = {},
	}
	for i, rec in ipairs(DATA.GKP_Record) do
		CACHE.GKP_Record_Index[rec.key] = i
	end
	for i, rec in ipairs(DATA.GKP_Account) do
		CACHE.GKP_Account_Index[rec.key] = i
	end
	return CACHE
end

function DS:ctor(szFilePath)
	local t = X.LoadLUAData(szFilePath)
	if t then
		self.DATA = {
			GKP_Map = t.GKP_Map or '',
			GKP_Time = t.GKP_Time or 0,
			GKP_Record = t.GKP_Record or {},
			GKP_Account = t.GKP_Account or {},
		}
		self.CACHE = GetCache(self.DATA)
	end
	self.szFilePath = szFilePath
end

function DS:IsDataInited()
	return self.DATA and true or false
end

function DS:InitData()
	if not self.DATA then
		self.DATA = GetClearData()
		self.CACHE = GetCache(self.DATA)
	end
end

function DS:ClearData()
	self.DATA = GetClearData()
	self.CACHE = GetCache(self.DATA)
	self:DelayFireUpdate('ALL')
end

function DS:IsEmpty()
	return #self.DATA.GKP_Record == 0 and #self.DATA.GKP_Account == 0
end

-- 数据存盘
function DS:SaveData()
	X.SaveLUAData(self:GetFilePath(), {
		GKP_Map = self.DATA.GKP_Map,
		GKP_Time = self.DATA.GKP_Time,
		GKP_Record = self.DATA.GKP_Record,
		GKP_Account = self.DATA.GKP_Account,
	})
end

-- 下一帧存盘
function DS:DelaySaveData()
	X.DelayCall('MY_GKP_DS__DelaySaveData#' .. self:GetFilePath(), function()
		self:SaveData()
	end)
end

-- 下一帧发送更新事件
function DS:DelayFireUpdate(szType)
	X.DelayCall('MY_GKP_DS__DelayFireUpdate#' .. self:GetFilePath() .. '#' .. szType, function()
		FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), szType)
	end)
end

-- 获取数据路径（可作为事件标识符）
function DS:GetFilePath()
	return self.szFilePath
end

-- 设置时间
function DS:SetTime(nTime)
	if X.IsNumber(nTime) and nTime ~= self.DATA.GKP_Time then
		self.DATA.GKP_Time = nTime
		self:DelaySaveData()
		self:DelayFireUpdate('TIME')
	end
end

-- 获取时间
function DS:GetTime()
	return self.DATA.GKP_Time
end

-- 设置地图
function DS:SetMap(szMap)
	if X.IsString(szMap) and szMap ~= self.DATA.GKP_Map then
		self.DATA.GKP_Map = szMap
		self:DelaySaveData()
		self:DelayFireUpdate('MAP')
	end
end

-- 获取地图
function DS:GetMap()
	return self.DATA.GKP_Map
end

-- 设置、修改拍卖记录
function DS:SetAuctionRec(rec)
	local rec = X.Clone(rec)
	if not rec.key then
		rec.key = X.GetUUID()
	end
	local nIndex = self.CACHE.GKP_Record_Index[rec.key]
		or (#self.DATA.GKP_Record + 1)
	self.DATA.GKP_Record[nIndex] = rec
	self.CACHE.GKP_Record_Index[rec.key] = nIndex
	self:DelaySaveData()
	self:DelayFireUpdate('AUCTION')
end

-- 获取指定key的拍卖记录
function DS:GetAuctionRec(szKey)
	local nIndex = self.CACHE.GKP_Record_Index[szKey]
	if nIndex then
		return self.DATA.GKP_Record[nIndex]
	end
end

-- 替换拍卖记录
function DS:SetAuctionList(aList)
	local aList = X.Clone(aList)
	for _, rec in ipairs(aList) do
		if not rec.key then
			rec.key = X.GetUUID()
		end
	end
	self.DATA.GKP_Record = aList
	self.CACHE = GetCache(self.DATA)
	self:DelaySaveData()
	self:DelayFireUpdate('AUCTION')
end

-- 获取每个人拍卖总额
function DS:GetAuctionPlayerSum(bAccurate)
	-- 计算每个人的非系统金团欠款记录
	local tArrears = {}
	for _, v in ipairs(self.DATA.GKP_Record) do
		if not v.bDelete and not v.bSystem and v.nMoney > 0 then
			if not tArrears[v.szPlayer] then
				tArrears[v.szPlayer] = 0
			end
			tArrears[v.szPlayer] = tArrears[v.szPlayer] + v.nMoney
		end
	end
	-- 计算拍卖收入
	local tIncome, tSubsidy = {}, {} -- 正数是拍装备罚款金额 负数是宴席补贴钱金额
	for _, v in ipairs(self.DATA.GKP_Record) do
		if not v.bDelete then
			local nMoney = tonumber(v.nMoney)
			if nMoney > 0 then
				if v.bSystem and v.dwIndex == 0 and tArrears[v.szPlayer] then -- 系统金团同步来的追加 优先抵冲分配者记录欠款投币
					local nOffset = math.min(tArrears[v.szPlayer], nMoney)
					nMoney = nMoney - nOffset
					tArrears[v.szPlayer] = tArrears[v.szPlayer] - nOffset
				end
				if not tIncome[v.szPlayer] then
					tIncome[v.szPlayer] = 0
				end
				tIncome[v.szPlayer] = tIncome[v.szPlayer] + nMoney
			else
				if not tSubsidy[v.szPlayer] then
					tSubsidy[v.szPlayer] = 0
				end
				tSubsidy[v.szPlayer] = tSubsidy[v.szPlayer] + nMoney
			end
		end
	end
	if bAccurate then
		local tAccurate = {}
		for szPlayer, nMoney in pairs(tIncome) do
			if not tAccurate[szPlayer] then
				tAccurate[szPlayer] = 0
			end
			tAccurate[szPlayer] = tAccurate[szPlayer] + nMoney
		end
		for szPlayer, nMoney in pairs(tSubsidy) do
			if not tAccurate[szPlayer] then
				tAccurate[szPlayer] = 0
			end
			tAccurate[szPlayer] = tAccurate[szPlayer] + nMoney
		end
		return tAccurate
	else
		return tIncome, tSubsidy
	end
end

-- 获取拍卖总额
function DS:GetAuctionSum(bAccurate)
	if bAccurate then
		local nAccurate = 0
		local tAccurate = self:GetAuctionPlayerSum(bAccurate)
		for _, nMoney in pairs(tAccurate) do
			nAccurate = nAccurate + nMoney
		end
		return nAccurate
	else
		local nIncome, nSubsidy = 0, 0
		local tIncome, tSubsidy = self:GetAuctionPlayerSum(bAccurate)
		for _, nMoney in pairs(tIncome) do
			nIncome = nIncome + nMoney
		end
		for _, nMoney in pairs(tSubsidy) do
			nSubsidy = nSubsidy + nMoney
		end
		return nIncome, nSubsidy
	end
end

-- 获取拍卖记录（排序）
function DS:GetAuctionList(szKey, szSort)
	if not szKey then
		szKey = 'nTime'
	end
	if not szSort then
		szSort = 'desc'
	end
	local aList = {}
	for _, v in ipairs(self.DATA.GKP_Record) do
		table.insert(aList, v)
	end
	table.sort(aList, function(a, b)
		if a[szKey] and b[szKey] then
			if szSort == 'asc' then
				if a[szKey] ~= b[szKey] then
					return a[szKey] < b[szKey]
				elseif a.key and b.key then
					return a.key < b.key
				else
					return a.nTime < b.nTime
				end
			else
				if a[szKey] ~= b[szKey] then
					return a[szKey] > b[szKey]
				elseif a.key and b.key then
					return a.key > b.key
				else
					return a.nTime > b.nTime
				end
			end
		else
			return false
		end
	end)
	return aList
end

-- 设置、修改收钱记录
function DS:SetPaymentRec(rec)
	local rec = X.Clone(rec)
	if not rec.key then
		rec.key = X.GetUUID()
	end
	local nIndex = self.CACHE.GKP_Account_Index[rec.key]
		or (#self.DATA.GKP_Account + 1)
	self.DATA.GKP_Account[nIndex] = rec
	self.CACHE.GKP_Account_Index[rec.key] = nIndex
	self:DelaySaveData()
	self:DelayFireUpdate('PAYMENT')
end

-- 获取指定key的收钱记录
function DS:GetPaymentRec(szKey)
	local nIndex = self.CACHE.GKP_Account_Index[szKey]
	if nIndex then
		return self.DATA.GKP_Account[nIndex]
	end
end

-- 替换收钱记录
function DS:SetPaymentList(aList)
	local aList = X.Clone(aList)
	for _, rec in ipairs(aList) do
		if not rec.key then
			rec.key = X.GetUUID()
		end
	end
	self.DATA.GKP_Account = aList
	self.CACHE = GetCache(self.DATA)
	self:DelaySaveData()
	self:DelayFireUpdate('PAYMENT')
end

-- 获取收钱记录列表（排序）
function DS:GetPaymentList(szKey, szSort)
	if not szKey then
		szKey = 'nTime'
	end
	if not szSort then
		szSort = 'desc'
	end
	local aList = {}
	for _, v in ipairs(self.DATA.GKP_Account) do
		table.insert(aList, v)
	end
	table.sort(aList, function(a, b)
		if a[szKey] and b[szKey] then
			if szSort == 'asc' then
				if a[szKey] ~= b[szKey] then
					return a[szKey] < b[szKey]
				elseif a.key and b.key then
					return a.key < b.key
				else
					return a.nTime < b.nTime
				end
			else
				if a[szKey] ~= b[szKey] then
					return a[szKey] > b[szKey]
				elseif a.key and b.key then
					return a.key > b.key
				else
					return a.nTime > b.nTime
				end
			end
		else
			return false
		end
	end)
	return aList
end

-- 获取每个角色收钱总额
function DS:GetPaymentPlayerSum(bAccurate)
	local tIncome, tOutcome = {}, {}
	for _, v in ipairs(self.DATA.GKP_Account) do
		if not v.bDelete then
			local nMoney = tonumber(v.nGold)
			if nMoney > 0 then
				if not tIncome[v.szPlayer] then
					tIncome[v.szPlayer] = 0
				end
				tIncome[v.szPlayer] = tIncome[v.szPlayer] + v.nGold
			else
				if not tOutcome[v.szPlayer] then
					tOutcome[v.szPlayer] = 0
				end
				tOutcome[v.szPlayer] = tOutcome[v.szPlayer] + v.nGold
			end
		end
	end
	if bAccurate then
		local tAccurate = {}
		for szPlayer, nMoney in pairs(tIncome) do
			if not tAccurate[szPlayer] then
				tAccurate[szPlayer] = 0
			end
			tAccurate[szPlayer] = tAccurate[szPlayer] + nMoney
		end
		for szPlayer, nMoney in pairs(tOutcome) do
			if not tAccurate[szPlayer] then
				tAccurate[szPlayer] = 0
			end
			tAccurate[szPlayer] = tAccurate[szPlayer] + nMoney
		end
		return tAccurate
	else
		return tIncome, tOutcome
	end
end

-- 获取收钱总额
function DS:GetPaymentSum(bAccurate)
	if bAccurate then
		local nAccurate = 0
		local tAccurate = self:GetPaymentPlayerSum(bAccurate)
		for _, nMoney in pairs(tAccurate) do
			nAccurate = nAccurate + nMoney
		end
		return nAccurate
	else
		local nIncome, nOutcome = 0, 0
		local tIncome, tOutcome = self:GetPaymentPlayerSum(bAccurate)
		for _, nMoney in pairs(tIncome) do
			nIncome = nIncome + nMoney
		end
		for _, nMoney in pairs(tOutcome) do
			nOutcome = nOutcome + nMoney
		end
		return nIncome, nOutcome
	end
end

-- 数据操作对象获取入口
function MY_GKP_DS(szFilePath, bCreate)
	szFilePath = szFilePath:lower():gsub('/', '\\')
	if not X.StringFindW(szFilePath:sub(-7):lower(), '.jx3dat') then
		szFilePath = szFilePath .. '.jx3dat'
	end
	if not DS_CACHE[szFilePath] then
		DS_CACHE[szFilePath] = DS.new(szFilePath)
	end
	local ds = DS_CACHE[szFilePath]
	if not ds:IsDataInited() then
		if not bCreate then
			return
		end
		ds:InitData()
	end
	return ds
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
