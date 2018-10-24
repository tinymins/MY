--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 数学库
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
MY = MY or {}
MY.Math = MY.Math or {}
local _C = {}
local tinsert, tremove = table.insert, table.remove

-- (table) Number2Bitmap(number n)
-- 将一个数值转换成一个Bit表（低位在前 高位在后）
do
local metatable = { __index = function() return 0 end }
function _C.Number2Bitmap(n)
	local t = {}
	if n == 0 then
		tinsert(t, 0)
	else
		while n > 0 do
			local nValue = math.fmod(n, 2)
			tinsert(t, nValue)
			n = math.floor(n / 2)
		end
	end
	return setmetatable(t, metatable)
end
MY.Math.Number2Bitmap = _C.Number2Bitmap
end

-- (number) Bitmap2Number(table t)
-- 将一个Bit表转换成一个数值（低位在前 高位在后）
function _C.Bitmap2Number(t)
	local n = 0
	for i, v in pairs(t) do
		if type(i) == 'number' and v and v ~= 0 then
			n = n + 2 ^ (i - 1)
		end
	end
	return n
end
MY.Math.Bitmap2Number = _C.Bitmap2Number

-- (number) SetBit(number n, number i, bool/0/1 b)
-- 设置一个数值的指定比特位
function MY.Math.SetBit(n, i, b)
	n = n or 0
	local t = _C.Number2Bitmap(n)
	if b and b ~= 0 then
		t[i] = 1
	else
		t[i] = 0
	end
	return _C.Bitmap2Number(t)
end

-- (0/1) GetBit(number n, number i)
-- 获取一个数值的指定比特位
function MY.Math.GetBit(n, i)
	return _C.Number2Bitmap(n)[i] or 0
end

-- (number) BitAnd(number n1, number n2)
-- 按位与运算
function MY.Math.BitAnd(n1, n2)
	local t1 = _C.Number2Bitmap(n1)
	local t2 = _C.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 1 and t2[i] == 1 and 1 or 0
	end
	return _C.Bitmap2Number(t3)
end

-- (number) BitOr(number n1, number n2)
-- 按位或运算
function MY.Math.BitOr(n1, n2)
	local t1 = _C.Number2Bitmap(n1)
	local t2 = _C.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 0 and t2[i] == 0 and 0 or 1
	end
	return _C.Bitmap2Number(t3)
end

-- (number) BitXor(number n1, number n2)
-- 按位异或运算
function MY.Math.BitXor(n1, n2)
	local t1 = _C.Number2Bitmap(n1)
	local t2 = _C.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == t2[i] and 0 or 1
	end
	return _C.Bitmap2Number(t3)
end
