--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 数学库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Math')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

-- (table) X.Number2Bitmap(number n)
-- 将一个数值转换成一个Bit表（低位在前 高位在后）
do
local metatable = { __index = function() return 0 end }
function X.Number2Bitmap(n)
	local t = {}
	if n == 0 then
		table.insert(t, 0)
	else
		while n > 0 do
			local nValue = n % 2
			table.insert(t, nValue)
			n = math.floor(n / 2)
		end
	end
	return setmetatable(t, metatable)
end
end

-- (number) Bitmap2Number(table t)
-- 将一个Bit表转换成一个数值（低位在前 高位在后）
function X.Bitmap2Number(t)
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
function X.SetNumberBit(n, i, b)
	n = n or 0
	local t = X.Number2Bitmap(n)
	if b and b ~= 0 then
		t[i] = 1
	else
		t[i] = 0
	end
	return X.Bitmap2Number(t)
end

-- (0/1) GetBit(number n, number i)
-- 获取一个数值的指定比特位
function X.GetNumberBit(n, i)
	return X.Number2Bitmap(n)[i] or 0
end

-- (number) BitAnd(number n1, number n2)
-- 按位与运算
function X.NumberBitAnd(n1, n2)
	local t1 = X.Number2Bitmap(n1)
	local t2 = X.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 1 and t2[i] == 1 and 1 or 0
	end
	return X.Bitmap2Number(t3)
end

-- (number) BitOr(number n1, number n2)
-- 按位或运算
function X.NumberBitOr(n1, n2)
	local t1 = X.Number2Bitmap(n1)
	local t2 = X.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 0 and t2[i] == 0 and 0 or 1
	end
	return X.Bitmap2Number(t3)
end

-- (number) BitXor(number n1, number n2)
-- 按位异或运算
function X.NumberBitXor(n1, n2)
	local t1 = X.Number2Bitmap(n1)
	local t2 = X.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == t2[i] and 0 or 1
	end
	return X.Bitmap2Number(t3)
end

-- (number) BitShl(number n1, number n2, number bit)
-- 左移运算
function X.NumberBitShl(n1, n2, bit)
	local t1 = X.Number2Bitmap(n1)
	if not bit then
		bit = 32
	end
	for i = 1, n2 do
		table.insert(t1, 1, 0)
	end
	while #t1 > bit do
		table.remove(t1)
	end
	return X.Bitmap2Number(t1)
end

-- (number) BitShr(number n1, number n2, number bit)
-- 右移运算
function X.NumberBitShr(n1, n2)
	local t1 = X.Number2Bitmap(n1)
	for i = 1, n2 do
		table.remove(t1, 1)
	end
	return X.Bitmap2Number(t1)
end

-- 格式化数字为指定进制下的字符串表示
function X.NumberBaseN(n, b, digits)
	if not X.IsNumber(n) or X.IsHugeNumber(n) then
		assert(false, 'Input must be a number value except `math.huge`.')
	end
	n = math.floor(n)
	if not b or b == 10 then
		return tostring(n)
	end
	if not digits then
		digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	end
	if b > #digits then
		assert(false, 'Number base can not be larger than digits length.')
	end
	local t = {}
	local sign = ''
	if n < 0 then
		sign = '-'
		n = -n
	end
	repeat
		local d = (n % b) + 1
		n = math.floor(n / b)
		table.insert(t, 1, digits:sub(d, d))
	until n == 0
	return sign .. table.concat(t, '')
end

-- 物理地址 => 段地址 + 段内偏移
function X.NumberToSegment(n, s)
	-- (!(n & (n - 1)))
	if not X.IsNumber(s) or s <= 0 or X.NumberBitAnd(s, s - 1) ~= 0 then
		assert(false, 'segment size must be a positive number and be power of 2')
	end
	if s == 0x20 and GlobelRecipeID2BookID then
		local n, o = GlobelRecipeID2BookID(n)
		if n and o then
			return n - 1, o - 1
		end
	end
	return n / s, n % s
end

-- 段地址 + 段内偏移 => 物理地址
function X.SegmentToNumber(n, o, s)
	-- (!(n & (n - 1)))
	if not X.IsNumber(s) or s <= 0 or X.NumberBitAnd(s, s - 1) ~= 0 then
		assert(false, 'segment size must be a positive number and be power of 2')
	end
	if s == 0x20 and BookID2GlobelRecipeID then
		local n = BookID2GlobelRecipeID(n + 1, o + 1)
		if n then
			return n
		end
	end
	return n * s + o
end

-- 游戏通用 “Recipe下标(基地址0)” 转 “段下标(基地址1)” + “段内下标(基地址1)”
function X.RecipeToSegmentID(dwRecipeID)
	local dwSegmentID, dwOffset = X.NumberToSegment(dwRecipeID, 0x20)
	return dwSegmentID + 1, dwOffset + 1
end

-- 游戏通用 “段下标(基地址1)” + “段内下标(基地址1)” 转 “Recipe下标(基地址0)”
function X.SegmentToRecipeID(dwSegmentID, dwOffset)
	return X.SegmentToNumber(dwSegmentID - 1, dwOffset - 1, 0x20)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
