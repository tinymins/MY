--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���ż�¼����Դ��
-- @author   : ���� @˫���� @׷����Ӱ
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
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
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

function DS:ctor(szFilePath)
	local t = LIB.LoadLUAData(szFilePath)
	if t then
		self.DATA = {
			GKP_Map = t.GKP_Map or '',
			GKP_Time = t.GKP_Time or 0,
			GKP_Record = t.GKP_Record or {},
			GKP_Account = t.GKP_Account or {},
		}
	end
	self.szFilePath = szFilePath
end

function DS:IsDataInited()
	return self.DATA and true or false
end

function DS:InitData()
	if not self.DATA then
		self.DATA = GetClearData()
	end
end

function DS:ClearData()
	self.DATA = GetClearData()
	FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'ALL')
end

function DS:IsEmpty()
	return #self.DATA.GKP_Record == 0 and #self.DATA.GKP_Account == 0
end

-- ���ݴ���
function DS:SaveData()
	LIB.SaveLUAData(self:GetFilePath(), {
		GKP_Map = self.DATA.GKP_Map,
		GKP_Time = self.DATA.GKP_Time,
		GKP_Record = self.DATA.GKP_Record,
		GKP_Account = self.DATA.GKP_Account,
	})
end

-- ��һ֡����
function DS:DelaySaveData()
	LIB.BreatheCall('MY_GKP_DS#' .. self:GetFilePath(), function()
		self:SaveData()
	end)
end

-- ��ȡ����·��������Ϊ�¼���ʶ����
function DS:GetFilePath()
	return self.szFilePath
end

-- ����ʱ��
function DS:SetTime(nTime)
	if IsNumber(nTime) and nTime ~= self.DATA.GKP_Time then
		self.DATA.GKP_Time = nTime
		self:DelaySaveData()
		FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'TIME')
	end
end

-- ��ȡʱ��
function DS:GetTime()
	return self.DATA.GKP_Time
end

-- ���õ�ͼ
function DS:SetMap(szMap)
	if IsString(szMap) and szMap ~= self.DATA.GKP_Map then
		self.DATA.GKP_Map = szMap
		self:DelaySaveData()
		FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'MAP')
	end
end

-- ��ȡ��ͼ
function DS:GetMap()
	return self.DATA.GKP_Map
end

-- ���á��޸�������¼
function DS:SetAuctionRec(rec)
	local rec = Clone(rec)
	if not rec.key then
		rec.key = LIB.GetUUID()
	end
	local nIndex = #self.DATA.GKP_Record + 1
	if rec.key then
		for i, v in ipairs(self.DATA.GKP_Record) do
			if v.key == rec.key then
				nIndex = i
			end
		end
	end
	self.DATA.GKP_Record[nIndex] = rec
	self:DelaySaveData()
	FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'AUCTION')
end

-- ��ȡָ��key��������¼
function DS:GetAuctionRec(szKey)
	for _, v in ipairs(self.DATA.GKP_Record) do
		if v.key == szKey then
			return v
		end
	end
end

-- �滻������¼
function DS:SetAuctionList(aList)
	local aList = Clone(aList)
	for _, rec in ipairs(aList) do
		if not rec.key then
			rec.key = LIB.GetUUID()
		end
	end
	self.DATA.GKP_Record = aList
	self:DelaySaveData()
	FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'AUCTION')
end

-- ��ȡ�����ܶ�
function DS:GetAuctionSum(bAccurate)
	local a, b = 0, 0
	for k, v in ipairs(self.DATA.GKP_Record) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				a = a + v.nMoney
			else
				b = b + v.nMoney
			end
		end
	end
	if bAccurate then
		return a + b
	else
		return a, b
	end
end

-- ��ȡ������¼������
function DS:GetAuctionList(szKey, szSort)
	if not szKey then
		szKey = 'nTime'
	end
	if not szSort then
		szSort = 'desc'
	end
	local aList = {}
	for _, v in ipairs(self.DATA.GKP_Record) do
		insert(aList, v)
	end
	sort(aList, function(a, b)
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

-- ���á��޸���Ǯ��¼
function DS:SetPaymentRec(rec)
	local rec = Clone(rec)
	if not rec.key then
		rec.key = LIB.GetUUID()
	end
	local nIndex = #self.DATA.GKP_Account + 1
	if rec.key then
		for i, v in ipairs(self.DATA.GKP_Account) do
			if v.key == rec.key then
				nIndex = i
			end
		end
	end
	self.DATA.GKP_Account[nIndex] = rec
	self:DelaySaveData()
	FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'PAYMENT')
end

-- ��ȡָ��key����Ǯ��¼
function DS:GetPaymentRec(szKey)
	for _, v in ipairs(self.DATA.GKP_Account) do
		if v.key == szKey then
			return v
		end
	end
end

-- �滻��Ǯ��¼
function DS:SetPaymentList(aList)
	local aList = Clone(aList)
	for _, rec in ipairs(aList) do
		if not rec.key then
			rec.key = LIB.GetUUID()
		end
	end
	self.DATA.GKP_Account = aList
	self:DelaySaveData()
	FireUIEvent('MY_GKP_DATA_UPDATE', self:GetFilePath(), 'PAYMENT')
end

-- ��ȡ��Ǯ��¼�б�������
function DS:GetPaymentList(szKey, szSort)
	if not szKey then
		szKey = 'nTime'
	end
	if not szSort then
		szSort = 'desc'
	end
	local aList = {}
	for _, v in ipairs(self.DATA.GKP_Account) do
		insert(aList, v)
	end
	sort(aList, function(a, b)
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

-- ��ȡ��Ǯ�ܶ�
function DS:GetPaymentSum(bAccurate)
	local a, b = 0, 0
	for k, v in ipairs(self.DATA.GKP_Account) do
		if not v.bDelete then
			if tonumber(v.nGold) > 0 then
				a = a + v.nGold
			else
				b = b + v.nGold
			end
		end
	end
	if bAccurate then
		return a + b
	else
		return a, b
	end
end

-- ���ݲ��������ȡ���
function MY_GKP_DS(szFilePath, bCreate)
	szFilePath = szFilePath:lower():gsub('/', '\\')
	if not wfind(szFilePath:sub(-7):lower(), '.jx3dat') then
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