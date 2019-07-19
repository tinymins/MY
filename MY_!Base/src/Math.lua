--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 数学库
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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

-- (table) LIB.Number2Bitmap(number n)
-- 将一个数值转换成一个Bit表（低位在前 高位在后）
do
local metatable = { __index = function() return 0 end }
function LIB.Number2Bitmap(n)
	local t = {}
	if n == 0 then
		insert(t, 0)
	else
		while n > 0 do
			local nValue = math.fmod(n, 2)
			insert(t, nValue)
			n = math.floor(n / 2)
		end
	end
	return setmetatable(t, metatable)
end
end

-- (number) Bitmap2Number(table t)
-- 将一个Bit表转换成一个数值（低位在前 高位在后）
function LIB.Bitmap2Number(t)
	local n = 0
	for i, v in pairs(t) do
		if type(i) == 'number' and v and v ~= 0 then
			n = n + 2 ^ (i - 1)
		end
	end
	return n
end

-- (number) SetBit(number n, number i, bool/0/1 b)
-- 设置一个数值的指定比特位
function LIB.SetNumberBit(n, i, b)
	n = n or 0
	local t = LIB.Number2Bitmap(n)
	if b and b ~= 0 then
		t[i] = 1
	else
		t[i] = 0
	end
	return LIB.Bitmap2Number(t)
end

-- (0/1) GetBit(number n, number i)
-- 获取一个数值的指定比特位
function LIB.GetNumberBit(n, i)
	return LIB.Number2Bitmap(n)[i] or 0
end

-- (number) BitAnd(number n1, number n2)
-- 按位与运算
function LIB.NumberBitAnd(n1, n2)
	local t1 = LIB.Number2Bitmap(n1)
	local t2 = LIB.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 1 and t2[i] == 1 and 1 or 0
	end
	return LIB.Bitmap2Number(t3)
end

-- (number) BitOr(number n1, number n2)
-- 按位或运算
function LIB.NumberBitOr(n1, n2)
	local t1 = LIB.Number2Bitmap(n1)
	local t2 = LIB.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 0 and t2[i] == 0 and 0 or 1
	end
	return LIB.Bitmap2Number(t3)
end

-- (number) BitXor(number n1, number n2)
-- 按位异或运算
function LIB.NumberBitXor(n1, n2)
	local t1 = LIB.Number2Bitmap(n1)
	local t2 = LIB.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == t2[i] and 0 or 1
	end
	return LIB.Bitmap2Number(t3)
end
