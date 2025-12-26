--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 数学库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Math')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

do
local metatable = { __index = function() return 0 end }
-- 将一个数值转换成一个Bit表（低位在前 高位在后）
---@param nNumber number @要转换的数值
---@return table @数值的比特表
function X.Number2Bitmap(nNumber)
	local tBit = {}
	if nNumber == 0 then
		table.insert(tBit, 0)
	else
		while nNumber > 0 do
			local nValue = nNumber % 2
			table.insert(tBit, nValue)
			nNumber = math.floor(nNumber / 2)
		end
	end
	return setmetatable(tBit, metatable)
end

-- 将一个字符串数值转换成一个Bit表（低位在前 高位在后）
---@param szNumber string @要转换的数值字符串
---@return table @数值的比特表
function X.NumericString2Bitmap(szNumber)
	local tBit = {}
	local szResult = ''
	local nCarry = 0
	while #szNumber > 1 or tonumber(szNumber) > 0 do
		szResult = ''
		nCarry = 0
		for i = 1, #szNumber do
			local nNum = tonumber(szNumber:sub(i, i)) + nCarry * 10
			nCarry = nNum % 2
			szResult = szResult .. tostring(math.floor(nNum / 2))
		end
		if string.sub(szResult, 1, 1) == '0' and #szResult > 1 then
			szResult = string.sub(szResult, 2)
		end
		table.insert(tBit, nCarry)
		szNumber = szResult
	end
	return setmetatable(tBit, metatable)
end
end

-- 将一个Bit表（低位在前 高位在后）转换成一个数值
---@param tBit table @数值的比特表
---@return number @要转换的数值
function X.Bitmap2Number(tBit)
	local nNumber = 0
	for i, v in pairs(tBit) do
		if type(i) == 'number' and v and v ~= 0 then
			nNumber = nNumber + 2 ^ (i - 1)
		end
	end
	return nNumber
end

-- 将一个Bit表（低位在前 高位在后）转换成一个数值字符串
---@param tBit table @数值的比特表
---@return string @要转换的数值
function X.Bitmap2NumericString(tBit)
	local szNumber = '0'
	for i = #tBit, 1, -1 do
		-- 字符串表示的数乘以2
		local szDoubled = ''
		local nCarry = 0
		for j = #szNumber, 1, -1 do
			local nNum = tonumber(szNumber:sub(j, j)) * 2 + nCarry
			nCarry = math.floor(nNum / 10)
			szDoubled = tostring(nNum % 10) .. szDoubled
		end
		if nCarry > 0 then
			szDoubled = tostring(nCarry) .. szDoubled
		end
		-- 如果当前位是1，则结果加1
		if tBit[i] == 1 then
			local szSum = ''
			nCarry = 1  -- 从1开始加，因为我们要加的是1
			for j = #szDoubled, 1, -1 do
				local nNum = tonumber(szDoubled:sub(j, j)) + nCarry
				nCarry = math.floor(nNum / 10)
				szSum = tostring(nNum % 10) .. szSum
			end
			if nCarry > 0 then
				szSum = tostring(nCarry) .. szSum
			end
			szNumber = szSum
		else
			szNumber = szDoubled
		end
	end
	return szNumber
end

-- 设置一个数值的指定比特位
---@param nNumber number @数值
---@param nIndex number @要设置的位
---@param xBit boolean|'0'|'1' @要设置的位的值
---@return number @设置后的数值
function X.SetNumberBit(nNumber, nIndex, xBit)
	nNumber = nNumber or 0
	local tBit = X.Number2Bitmap(nNumber)
	if xBit and xBit ~= 0 then
		tBit[nIndex] = 1
	else
		tBit[nIndex] = 0
	end
	return X.Bitmap2Number(tBit)
end

-- 获取一个数值的指定比特位
---@param nNumber number @数值
---@param nIndex number @要获取的位
---@return '0'|'1' @该位的值
function X.GetNumberBit(nNumber, nIndex)
	return X.Number2Bitmap(nNumber)[nIndex] or 0
end

-- 按位与运算
---@param nNumber1 number @数值1
---@param nNumber2 number @数值2
---@return number @按位与运算后的值
function X.NumberBitAnd(nNumber1, nNumber2)
	local tBit1 = X.Number2Bitmap(nNumber1)
	local tBit2 = X.Number2Bitmap(nNumber2)
	local tBit = {}
	for i = 1, math.max(#tBit1, #tBit2) do
		tBit[i] = tBit1[i] == 1 and tBit2[i] == 1 and 1 or 0
	end
	return X.Bitmap2Number(tBit)
end

-- 按位或运算
---@param nNumber1 number @数值1
---@param nNumber2 number @数值2
---@return number @按位或运算后的值
function X.NumberBitOr(nNumber1, nNumber2)
	local tBit1 = X.Number2Bitmap(nNumber1)
	local tBit2 = X.Number2Bitmap(nNumber2)
	local tBit = {}
	for i = 1, math.max(#tBit1, #tBit2) do
		tBit[i] = tBit1[i] == 0 and tBit2[i] == 0 and 0 or 1
	end
	return X.Bitmap2Number(tBit)
end

-- 按位异或运算
---@param nNumber1 number @数值1
---@param nNumber2 number @数值2
---@return number @按位异或运算后的值
function X.NumberBitXor(nNumber1, nNumber2)
	local tBit1 = X.Number2Bitmap(nNumber1)
	local tBit2 = X.Number2Bitmap(nNumber2)
	local tBit = {}
	for i = 1, math.max(#tBit1, #tBit2) do
		tBit[i] = tBit1[i] == tBit2[i] and 0 or 1
	end
	return X.Bitmap2Number(tBit)
end

-- 左移运算
---@param nNumber number @数值
---@param nShift number @左移数量
---@param nNumberBit number @数值总Bit位数，默认32位
---@return number @左移运算后的值
function X.NumberBitShl(nNumber, nShift, nNumberBit)
	local tBit = X.Number2Bitmap(nNumber)
	if not nNumberBit then
		nNumberBit = 32
	end
	for i = 1, nShift do
		table.insert(tBit, 1, 0)
	end
	while #tBit > nNumberBit do
		table.remove(tBit)
	end
	return X.Bitmap2Number(tBit)
end

-- 右移运算
---@param nNumber number @数值
---@param nShift number @右移数量
---@return number @右移运算后的值
function X.NumberBitShr(nNumber, nShift)
	local tBit = X.Number2Bitmap(nNumber)
	for i = 1, nShift do
		table.remove(tBit, 1)
	end
	return X.Bitmap2Number(tBit)
end

-- 格式化数字为指定进制下的字符串表示
---@param nNumber number @数值
---@param nBase number @进制值
---@param szDigits string @进制位表示，默认为 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ
---@return string @转换进制后的数值字符串
function X.NumberBaseN(nNumber, nBase, szDigits)
	if not X.IsNumber(nNumber) or X.IsHugeNumber(nNumber) then
		assert(false, 'Input must be a number value except `math.huge`.')
	end
	nNumber = math.floor(nNumber)
	if not nBase or nBase == 10 then
		return tostring(nNumber)
	end
	if not szDigits then
		szDigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	end
	if nBase > #szDigits then
		assert(false, 'Number base can not be larger than digits length.')
	end
	local t = {}
	local szSign = ''
	if nNumber < 0 then
		szSign = '-'
		nNumber = -nNumber
	end
	repeat
		local d = (nNumber % nBase) + 1
		nNumber = math.floor(nNumber / nBase)
		table.insert(t, 1, szDigits:sub(d, d))
	until nNumber == 0
	return szSign .. table.concat(t, '')
end

-- 数值转换：物理地址 => 段地址 + 段内偏移
---@param nNumber number @物理地址数值
---@param nSegmentSize number @段长度
---@return number,number @转换后的段地址,段内偏移
function X.NumberToSegment(nNumber, nSegmentSize)
	-- (!(n & (n - 1)))
	if not X.IsNumber(nSegmentSize) or nSegmentSize <= 0 or X.NumberBitAnd(nSegmentSize, nSegmentSize - 1) ~= 0 then
		assert(false, 'segment size must be a positive number and be power of 2')
	end
	if nSegmentSize == 0x20 and GlobelRecipeID2BookID then
		local n, o = GlobelRecipeID2BookID(nNumber)
		if n and o then
			return n - 1, o - 1
		end
	end
	return nNumber / nSegmentSize, nNumber % nSegmentSize
end

-- 数值转换：段地址 + 段内偏移 => 物理地址
---@param nSegment number @段地址
---@param nOffset number @段内偏移
---@param nSegmentSize number @段长度
---@return number @转换后的物理地址数值
function X.SegmentToNumber(nSegment, nOffset, nSegmentSize)
	-- (!(n & (n - 1)))
	if not X.IsNumber(nSegmentSize) or nSegmentSize <= 0 or X.NumberBitAnd(nSegmentSize, nSegmentSize - 1) ~= 0 then
		assert(false, 'segment size must be a positive number and be power of 2')
	end
	if nSegmentSize == 0x20 and BookID2GlobelRecipeID then
		local n = BookID2GlobelRecipeID(nSegment + 1, nOffset + 1)
		if n then
			return n
		end
	end
	return nSegment * nSegmentSize + nOffset
end

-- 游戏通用 “Recipe下标(基地址0)” 转 “段下标(基地址1)” + “段内下标(基地址1)”
---@param dwRecipeID number @Recipe下标(基地址0)
---@return number,number @段下标(基地址1),段内下标(基地址1)
function X.RecipeToSegmentID(dwRecipeID)
	local dwSegmentID, dwOffset = X.NumberToSegment(dwRecipeID, 0x20)
	return dwSegmentID + 1, dwOffset + 1
end

-- 游戏通用 “段下标(基地址1)” + “段内下标(基地址1)” 转 “Recipe下标(基地址0)”
---@param dwSegmentID number @段下标(基地址1)
---@param dwOffset number @段内下标(基地址1)
---@return number @Recipe下标(基地址0)
function X.SegmentToRecipeID(dwSegmentID, dwOffset)
	return X.SegmentToNumber(dwSegmentID - 1, dwOffset - 1, 0x20)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
