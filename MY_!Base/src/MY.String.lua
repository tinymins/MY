--------------------------------------------
-- @Desc  : 茗伊插件 - 字符串处理
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2015-01-25 15:35:26
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-09-22 11:58:22
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
------------------------------------------------------------------------
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local ssub, slen, schar, srep, sbyte, sformat, sgsub =
	  string.sub, string.len, string.char, string.rep, string.byte, string.format, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID = GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID
local UrlEncodeString, UrlDecodeString = UrlEncode, UrlDecode
local AnsiToUTF8 = AnsiToUTF8 or ansi_to_utf8
local setmetatable = setmetatable
--------------------------------------------
-- 本地函数和变量
--------------------------------------------
MY = MY or {}
MY.String = MY.String or {}

-- 分隔字符串
-- (table) MY.String.Split(string szText, string szSpliter, bool bIgnoreEmptyPart)
-- szText           原始字符串
-- szSpliter        分隔符
-- bIgnoreEmptyPart 是否忽略空字符串，即"123;234;"被";"分成{"123","234"}还是{"123","234",""}
function MY.String.Split(szText, szSep, bIgnoreEmptyPart)
	local nOff, tResult, szPart = 1, {}
	while true do
		local nEnd = StringFindW(szText, szSep, nOff)
		if not nEnd then
			szPart = string.sub(szText, nOff, string.len(szText))
			if not bIgnoreEmptyPart or szPart ~= "" then
				table.insert(tResult, szPart)
			end
			break
		else
			szPart = string.sub(szText, nOff, nEnd - 1)
			if not bIgnoreEmptyPart or szPart ~= "" then
				table.insert(tResult, szPart)
			end
			nOff = nEnd + string.len(szSep)
		end
	end
	return tResult
end

-- 转义正则表达式特殊字符
-- (string) MY.String.PatternEscape(string szText)
function MY.String.PatternEscape(s) return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')) end

-- 清除字符串首尾的空白字符
-- (string) MY.String.Trim(string szText)
function MY.String.Trim(szText)
	if not szText or szText == "" then
		return ""
	end
	return (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
end

function MY.String.LenW(str)
	return wstring.len(str)
end

function MY.String.SubW(str,s,e)
	if s < 0 then
		s = wstring.len(str) + s
	end
	if e < 0 then
		e = wstring.len(str) + e
	end
	return wstring.sub(str, s, e)
end

function MY.String.SimpleEcrypt(szText)
	return szText:gsub('.', function (c) return string.format ("%02X", (string.byte(c) + 13) % 256) end):gsub(" ", "+")
end
MY.SimpleEcrypt = MY.String.SimpleEcrypt

local function EncodePostData(data, t, prefix)
	if type(data) == "table" then
		local first = true
		for k, v in pairs(data) do
			if first then
				first = false
			else
				tinsert(t, "&")
			end
			if prefix == "" then
				EncodePostData(v, t, k)
			else
				EncodePostData(v, t, prefix .. "[" .. k .. "]")
			end
		end
	else
		if prefix ~= "" then
			tinsert(t, prefix)
			tinsert(t, "=")
		end
		tinsert(t, data)
	end
end

function MY.EncodePostData(data)
	local t = {}
	EncodePostData(data, t, "")
	local text = table.concat(t)
	return text
end

local function ConvertToUTF8(data)
	if type(data) == "table" then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == "string" then
				t[ConvertToUTF8(k)] = ConvertToUTF8(v)
			else
				t[k] = ConvertToUTF8(v)
			end
		end
		return t
	elseif type(data) == "string" then
		return AnsiToUTF8(data)
	else
		return data
	end
end
MY.ConvertToUTF8 = ConvertToUTF8

local function ConvertToAnsi(data)
	if type(data) == "table" then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == "string" then
				t[ConvertToAnsi(k)] = ConvertToAnsi(v)
			else
				t[k] = ConvertToAnsi(v)
			end
		end
		return t
	elseif type(data) == "string" then
		return UTF8ToAnsi(data)
	else
		return data
	end
end
MY.ConvertToAnsi = ConvertToAnsi

if not UrlEncodeString then
function UrlEncodeString(szText)
	return szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end):gsub(" ", "+")
end
end

if not UrlDecodeString then
function UrlDecodeString(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end
end

local function UrlEncode(data)
	if type(data) == "table" then
		local t = {}
		for k, v in pairs(data) do
			if type(k == "string") then
				t[UrlEncodeString(k)] = UrlEncode(v)
			else
				t[k] = UrlEncode(v)
			end
		end
		return t
	elseif type(data) == "string" then
		return UrlEncodeString(data)
	else
		return data
	end
end
MY.UrlEncode = UrlEncode

local function UrlDecode(data)
	if type(data) == "table" then
		local t = {}
		for k, v in pairs(data) do
			if type(k == "string") then
				t[UrlDecodeString(k)] = UrlDecode(v)
			else
				t[k] = UrlDecode(v)
			end
		end
		return t
	elseif type(data) == "string" then
		return UrlDecodeString(data)
	else
		return data
	end
end
MY.UrlDecode = UrlDecode


local m_simpleMatchCache = setmetatable({}, { __mode = "v" })
function MY.String.SimpleMatch(szText, szFind, bDistinctCase, bDistinctEnEm, bIgnoreSpace)
	if not bDistinctCase then
		szFind = StringLowerW(szFind)
		szText = StringLowerW(szText)
	end
	if not bDistinctEnEm then
		szFind = StringEnerW(szFind)
		szText = StringEnerW(szText)
	end
	if bIgnoreSpace then
		szFind = StringReplaceW(szFind, " ", "")
		szFind = StringReplaceW(szFind, g_tStrings.STR_ONE_CHINESE_SPACE, "")
		szText = StringReplaceW(szText, " ", "")
		szText = StringReplaceW(szText, g_tStrings.STR_ONE_CHINESE_SPACE, "")
	end
	local me = GetClientPlayer()
	if me then
		szFind = szFind:gsub("$zj", me.szName)
		local szTongName = ""
		local tong = GetTongClient()
		if tong and me.dwTongID ~= 0 then
			szTongName = tong.ApplyGetTongName(me.dwTongID) or ""
		end
		szFind = szFind:gsub("$bh", szTongName)
		szFind = szFind:gsub("$gh", szTongName)
	end
	local tFind = m_simpleMatchCache[szFind]
	if not tFind then
		tFind = {}
		for _, szKeyWordsLine in ipairs(MY.String.Split(szFind, ';', true)) do
			local tKeyWordsLine = {}
			for _, szKeyWords in ipairs(MY.String.Split(szKeyWordsLine, ',', true)) do
				local tKeyWords = {}
				for _, szKeyWord in ipairs(MY.String.Split(szKeyWords, '|', true)) do
					tinsert(tKeyWords, szKeyWord)
				end
				tinsert(tKeyWordsLine, tKeyWords)
			end
			tinsert(tFind, tKeyWordsLine)
		end
		m_simpleMatchCache[szFind] = tFind
	end
	-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
	local bKeyWordsLine = false
	for _, tKeyWordsLine in ipairs(tFind) do         -- 符合一个即可
		-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
		local bKeyWords = true
		for _, tKeyWords in ipairs(tKeyWordsLine) do -- 必须全部符合
			-- 10|十人
			local bKeyWord = false
			for _, szKeyWord in ipairs(tKeyWords) do  -- 符合一个即可
				-- szKeyWord = MY.String.PatternEscape(szKeyWord) -- 用了wstring还Escape个捷豹
				if szKeyWord:sub(1, 1) == "!" then              -- !小铁被吃了
					szKeyWord = szKeyWord:sub(2)
					if not wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				else                                                    -- 十人   -- 10
					if wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				end
				if bKeyWord then
					break
				end
			end
			bKeyWords = bKeyWords and bKeyWord
			if not bKeyWords then
				break
			end
		end
		bKeyWordsLine = bKeyWordsLine or bKeyWords
		if bKeyWordsLine then
			break
		end
	end
	return bKeyWordsLine
end
