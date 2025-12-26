--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·时间
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Time')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- Format `prime`:
--   It's not particularly common for expressions of time.
--   It's similar to degrees-minutes-seconds: instead of decimal degrees (38.897212°,-77.036519°) you write (38° 53′ 49.9632″, -77° 2′ 11.4678″).
--   Both are derived from a sexagesimal counting system such as that devised in Ancient Babylon:
--   the single prime represents the first sexagesimal division and the second the next, and so on.
--   17th-century astronomers used a third division of 1/60th of a second.
--   The advantage of using minute and second symbols for time is that it obviously expresses a duration rather than a time.
--   From the time 01:00:00 to the time 02:34:56 is a duration of 1 hour, 34 minutes and 56 seconds (1h 34′ 56″)
--   Prime markers start single and are multiplied for subsequent appearances, so minutes use a single prime ′ and seconds use a double-prime ″.
--   They are pronounced minutes and seconds respectively in the case of durations like this.
--   Note that a prime ′ is not a straight-apostrophe ' or a printer's apostrophe ’, although straight-apostrophes are a reasonable approximation and printer's apostrophes do occur as well.

---@class FormatDurationUnitItem @格式化时间配置项参数
---@field normal string @正常显示格式
---@field fixed string @固定宽度显示格式
---@field skipNull boolean @为空是否跳过
---@field delimiter string @分隔符

---@class FormatDurationUnit @格式化时间配置参数
---@field year FormatDurationUnitItem | string @年数
---@field day FormatDurationUnitItem | string @天数
---@field hour FormatDurationUnitItem | string @小时数
---@field minute FormatDurationUnitItem | string @分钟数
---@field second FormatDurationUnitItem | string @秒钟数

---@type table<string, FormatDurationUnit>
local FORMAT_TIME_COUNT_PRESET = {
	['CHINESE'] = {
		year = { normal = '%d' .. g_tStrings.STR_YEAR, fixed = '%04d' .. g_tStrings.STR_YEAR, skipNull = true },
		day = { normal = '%d' .. g_tStrings.STR_BUFF_H_TIME_D_SHORT, fixed = '%02d' .. g_tStrings.STR_BUFF_H_TIME_D_SHORT, skipNull = true },
		hour = { normal = '%d' .. g_tStrings.STR_TIME_HOUR, fixed = '%02d' .. g_tStrings.STR_TIME_HOUR, skipNull = true },
		minute = { normal = '%d' .. g_tStrings.STR_TIME_MINUTE, fixed = '%02d' .. g_tStrings.STR_TIME_MINUTE, skipNull = true },
		second = { normal = '%d' .. g_tStrings.STR_TIME_SECOND, fixed = '%02d' .. g_tStrings.STR_TIME_SECOND, skipNull = true },
	},
	['ENGLISH_ABBR'] = {
		year = { normal = '%dy', fixed = '%04dy' },
		day = { normal = '%dd', fixed = '%02dd' },
		hour = { normal = '%dh', fixed = '%02dh' },
		minute = { normal = '%dm', fixed = '%02dm' },
		second = { normal = '%ds', fixed = '%02ds' },
	},
	['PRIME'] = {
		minute = { normal = '%d\'', fixed = '%02d\'' },
		second = { normal = '%d"', fixed = '%02d"' },
	},
	['SYMBOL'] = {
		hour = { normal = '%d', fixed = '%02d', delimiter = ':' },
		minute = { normal = '%d', fixed = '%02d', delimiter = ':' },
		second = { normal = '%d', fixed = '%02d' },
	},
}
local FORMAT_TIME_UNIT_LIST = {
	{ key = 'year' },
	{ key = 'day', radix = 365 },
	{ key = 'hour', radix = 24 },
	{ key = 'minute', radix = 60 },
	{ key = 'second', radix = 60 },
}

---@class FormatDurationControl @格式化时间控制参数
---@field mode "'normal'" | "'fixed'" | "'fixed-except-leading'" @格式化模式
---@field maxUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @开始单位，最大只显示到该单位，默认值：'year'。
---@field keepUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @零值也保留的单位位置，默认值：'second'。
---@field accuracyUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @精度结束单位，精度低于该单位的数据将被省去，默认值：'second'。

-- 格式化计时时间
---@param nTime number @时间
---@param tUnitFmt FormatDurationUnit | string @格式化参数 或 预设方案名（见 `FORMAT_TIME_COUNT_PRESET`）
---@param tControl FormatDurationControl @控制参数
function X.FormatDuration(nTime, tUnitFmt, tControl)
	if X.IsString(tUnitFmt) then
		tUnitFmt = FORMAT_TIME_COUNT_PRESET[tUnitFmt]
	end
	if not X.IsTable(tUnitFmt) then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: invalid UnitFormat.'))
	end
	-- 格式化模式
	local mode = tControl and tControl.mode or 'normal'
	-- 开始单位，最大只显示到该单位
	local maxUnit = tControl and tControl.maxUnit or 'year'
	local maxUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == maxUnit then
			maxUnitIndex = i
			break
		end
	end
	if maxUnitIndex == -1 then
		maxUnitIndex = 1
		maxUnit = FORMAT_TIME_UNIT_LIST[maxUnitIndex].key
	end
	-- 零值也保留的单位位置
	local keepUnit = tControl and tControl.keepUnit or 'second'
	local keepUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == keepUnit then
			keepUnitIndex = i
			break
		end
	end
	if keepUnitIndex == -1 then
		keepUnitIndex = #FORMAT_TIME_UNIT_LIST
		keepUnit = FORMAT_TIME_UNIT_LIST[keepUnitIndex].key
	end
	-- 精度结束单位，精度低于该单位的数据将被省去
	local accuracy = tControl and tControl.accuracyUnit or 'second'
	local accuracyUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == accuracy then
			accuracyUnitIndex = i
			break
		end
	end
	if accuracyUnitIndex == -1 then
		accuracyUnitIndex = #FORMAT_TIME_UNIT_LIST
		accuracy = FORMAT_TIME_UNIT_LIST[accuracyUnitIndex].key
	end
	if maxUnitIndex > keepUnitIndex then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: maxUnit must be less than keepUnit.'))
	end
	if maxUnitIndex > accuracyUnitIndex then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: maxUnit must be less than accuracyUnit.'))
	end
	-- 计算完整各个单位数据
	local aValue = {}
	for i, unit in X.ipairs_r(FORMAT_TIME_UNIT_LIST) do
		if i > 1 then
			aValue[i] = nTime % unit.radix
			nTime = math.floor(nTime / unit.radix)
		else
			aValue[i] = nTime
		end
	end
	-- 合并超出开始单位或不存在的单位数据到下级单位中
	for i, unit in ipairs(FORMAT_TIME_UNIT_LIST) do
		if i < maxUnitIndex or not tUnitFmt[unit.key] then
			local nextUnit = FORMAT_TIME_UNIT_LIST[i + 1]
			if nextUnit then
				aValue[i + 1] = aValue[i + 1] + aValue[i] * nextUnit.radix
				aValue[i] = 0
			end
		end
	end
	-- 合并超出精度单位的数据到上级单位中
	for i, unit in X.ipairs_r(FORMAT_TIME_UNIT_LIST) do
		if i > accuracyUnitIndex then
			local prevUnit = FORMAT_TIME_UNIT_LIST[i - 1]
			if prevUnit then
				aValue[i - 1] = aValue[i - 1] + aValue[i] / unit.radix
				aValue[i] = 0
			end
		end
	end
	-- 单位依次拼接
	local szText, szSplitter = '', ''
	for i, unit in ipairs(FORMAT_TIME_UNIT_LIST) do
		local fmt = tUnitFmt[unit.key]
		if X.IsString(fmt) then
			fmt = { normal = fmt }
		end
		if i >= maxUnitIndex and i <= accuracyUnitIndex -- 单位在最大最小允许显示之间
		and fmt -- 并且单位自定义格式化数据存在
		and (
			aValue[i] > 0 --数据不为空
			or (szText ~= '' and not fmt.skipNull) -- 或者数据为空但高位有值且该单位格式化数据要求不可省略
			or i >= keepUnitIndex -- 单位位于零值保留单位之后
		) then
			local formatString = (mode == 'normal' or (mode == 'fixed-except-leading' and szText == ''))
				and (fmt.normal)
				or (fmt.fixed or fmt.normal)
			szText = szText .. szSplitter .. formatString:format(math.ceil(aValue[i]))
			szSplitter = fmt.delimiter or ''
		end
	end
	return szText
end

-- 格式化时间
-- (string) X.FormatTime(nTimestamp, szFormat)
-- nTimestamp UNIX时间戳
-- szFormat   格式化字符串
--   %yyyy 年份四位对齐
--   %yy   年份两位对齐
--   %MM   月份两位对齐
--   %dd   日期两位对齐
--   %y    年份
--   %m    月份
--   %d    日期
--   %hh   小时两位对齐
--   %mm   分钟两位对齐
--   %ss   秒钟两位对齐
--   %h    小时
--   %m    分钟
--   %s    秒钟
function X.FormatTime(nTimestamp, szFormat)
	local t = TimeToDate(nTimestamp)
	szFormat = X.StringReplaceW(szFormat, '%yyyy', string.format('%04d', t.year  ))
	szFormat = X.StringReplaceW(szFormat, '%yy'  , string.format('%02d', t.year % 100))
	szFormat = X.StringReplaceW(szFormat, '%MM'  , string.format('%02d', t.month ))
	szFormat = X.StringReplaceW(szFormat, '%dd'  , string.format('%02d', t.day   ))
	szFormat = X.StringReplaceW(szFormat, '%hh'  , string.format('%02d', t.hour  ))
	szFormat = X.StringReplaceW(szFormat, '%mm'  , string.format('%02d', t.minute))
	szFormat = X.StringReplaceW(szFormat, '%ss'  , string.format('%02d', t.second))
	szFormat = X.StringReplaceW(szFormat, '%y', t.year  )
	szFormat = X.StringReplaceW(szFormat, '%M', t.month )
	szFormat = X.StringReplaceW(szFormat, '%d', t.day   )
	szFormat = X.StringReplaceW(szFormat, '%h', t.hour  )
	szFormat = X.StringReplaceW(szFormat, '%m', t.minute)
	szFormat = X.StringReplaceW(szFormat, '%s', t.second)
	return szFormat
end

function X.GetEndTime(nEndFrame, bAllowNegative)
	if bAllowNegative then
		return (nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
	end
	return math.max(0, nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
end

function X.DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
	return DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
end

function X.TimeToDate(nTimestamp)
	local date = TimeToDate(nTimestamp)
	return date.year, date.month, date.day, date.hour, date.minute, date.second
end

---格式化数字小数点
---(string) X.FormatNumberDot(nValue, nDot, bDot, nMin)
---@param nValue number @要格式化的数字
---@param nDot number? @小数点位数
---@param bDot boolean? @小数点不足补位0
---@param nMin number? @数值超过多少显示精简数值
function X.FormatNumberDot(nValue, nDot, bDot, nMin)
	if not nDot then
		nDot = 0
	end
	if not nMin then
		nMin = 100000
	end
	local szUnit = ''
	if nValue >= nMin then
		if nValue >= 100000000 then
			nValue = nValue / 100000000
			szUnit = g_tStrings.DIGTABLE.tCharDiH[3]
		elseif nValue > 10000 then
			nValue = nValue / 10000
			szUnit = g_tStrings.DIGTABLE.tCharDiH[2]
		end
	end
	return math.floor(nValue * math.pow(10, nDot)) / math.pow(10, nDot) .. szUnit
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
