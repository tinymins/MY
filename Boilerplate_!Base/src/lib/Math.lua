--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 数学库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local LIB = Boilerplate
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SaveCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------

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
			local nValue = mod(n, 2)
			insert(t, nValue)
			n = floor(n / 2)
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
	for i = 1, max(#t1, #t2) do
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
	for i = 1, max(#t1, #t2) do
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
	for i = 1, max(#t1, #t2) do
		t3[i] = t1[i] == t2[i] and 0 or 1
	end
	return LIB.Bitmap2Number(t3)
end

-- (number) BitShl(number n1, number n2, number bit)
-- 左移运算
function LIB.NumberBitShl(n1, n2, bit)
	local t1 = LIB.Number2Bitmap(n1)
	if not bit then
		bit = 32
	end
	for i = 1, n2 do
		insert(t1, 1, 0)
	end
	while #t1 > bit do
		remove(t1)
	end
	return LIB.Bitmap2Number(t1)
end

-- (number) BitShr(number n1, number n2, number bit)
-- 右移运算
function LIB.NumberBitShr(n1, n2)
	local t1 = LIB.Number2Bitmap(n1)
	for i = 1, n2 do
		remove(t1, 1)
	end
	return LIB.Bitmap2Number(t1)
end

-- 格式化数字为指定进制下的字符串表示
function LIB.NumberBaseN(n, b, digits)
	n = floor(n)
	if not b or b == 10 then
		return tostring(n)
	end
	if not digits then
		digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	end
	assert(b <= #digits, 'Number base can not be larger than digits length.')
	local t = {}
	local sign = ''
	if n < 0 then
		sign = '-'
		n = -n
	end
	repeat
		local d = (n % b) + 1
		n = floor(n / b)
		insert(t, 1, digits:sub(d, d))
	until n == 0
	return sign .. concat(t, '')
end
