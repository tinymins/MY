--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 字符串处理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local AnsiToUTF8 = AnsiToUTF8 or ansi_to_utf8
local UrlEncodeString, UrlDecodeString = UrlEncode, UrlDecode
--------------------------------------------
-- 本地函数和变量
--------------------------------------------

-- 分隔字符串
-- (table) MY.SplitString(string szText, table aSpliter, bool bIgnoreEmptyPart)
-- (table) MY.SplitString(string szText, string szSpliter, bool bIgnoreEmptyPart)
-- szText           原始字符串
-- szSpliter        分隔符
-- aSpliter         多个分隔符
-- bIgnoreEmptyPart 是否忽略空字符串，即'123;234;'被';'分成{'123','234'}还是{'123','234',''}
function MY.SplitString(szText, aSpliter, bIgnoreEmptyPart)
	if IsString(aSpliter) then
		aSpliter = {aSpliter}
	end
	local nOff, tResult, szPart = 1, {}
	while true do
		local nEnd, szEnd
		for _, szSpliter in ipairs(aSpliter) do
			local nPos = StringFindW(szText, szSpliter, nOff)
			if nPos and (not nEnd or nPos < nEnd) then
				nEnd, szEnd = nPos, szSpliter
			end
		end
		if not nEnd then
			szPart = sub(szText, nOff, len(szText))
			if not bIgnoreEmptyPart or szPart ~= '' then
				insert(tResult, szPart)
			end
			break
		else
			szPart = sub(szText, nOff, nEnd - 1)
			if not bIgnoreEmptyPart or szPart ~= '' then
				insert(tResult, szPart)
			end
			nOff = nEnd + len(szEnd)
		end
	end
	return tResult
end

function MY.EscapeString(s)
	return (gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1'))
end

function MY.TrimString(szText)
	if not szText or szText == '' then
		return ''
	end
	return (gsub(szText, '^%s*(.-)%s*$', '%1'))
end

function MY.StringLenW(str)
	return wlen(str)
end

function MY.StringSubW(str,s,e)
	if s < 0 then
		s = wlen(str) + s
	end
	if e < 0 then
		e = wlen(str) + e
	end
	return wsub(str, s, e)
end

function MY.EncryptString(szText)
	return szText:gsub('.', function (c) return format ('%02X', (byte(c) + 13) % 256) end):gsub(' ', '+')
end

local function EncodePostData(data, t, prefix)
	if type(data) == 'table' then
		local first = true
		for k, v in pairs(data) do
			if first then
				first = false
			else
				insert(t, '&')
			end
			if prefix == '' then
				EncodePostData(v, t, k)
			else
				EncodePostData(v, t, prefix .. '[' .. k .. ']')
			end
		end
	else
		if prefix ~= '' then
			insert(t, prefix)
			insert(t, '=')
		end
		insert(t, data)
	end
end

function MY.EncodePostData(data)
	local t = {}
	EncodePostData(data, t, '')
	local text = concat(t)
	return text
end

local function ConvertToUTF8(data)
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == 'string' then
				t[ConvertToUTF8(k)] = ConvertToUTF8(v)
			else
				t[k] = ConvertToUTF8(v)
			end
		end
		return t
	elseif type(data) == 'string' then
		return AnsiToUTF8(data)
	else
		return data
	end
end
MY.ConvertToUTF8 = ConvertToUTF8

local function ConvertToAnsi(data)
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == 'string' then
				t[ConvertToAnsi(k)] = ConvertToAnsi(v)
			else
				t[k] = ConvertToAnsi(v)
			end
		end
		return t
	elseif type(data) == 'string' then
		return UTF8ToAnsi(data)
	else
		return data
	end
end
MY.ConvertToAnsi = ConvertToAnsi

if not UrlEncodeString then
function UrlEncodeString(szText)
	return szText:gsub('([^0-9a-zA-Z ])', function (c) return format ('%%%02X', byte(c)) end):gsub(' ', '+')
end
end

if not UrlDecodeString then
function UrlDecodeString(szText)
	return szText:gsub('+', ' '):gsub('%%(%x%x)', function(h) return char(tonumber(h, 16)) end)
end
end

local function UrlEncode(data)
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			if type(k == 'string') then
				t[UrlEncodeString(k)] = UrlEncode(v)
			else
				t[k] = UrlEncode(v)
			end
		end
		return t
	elseif type(data) == 'string' then
		return UrlEncodeString(data)
	else
		return data
	end
end
MY.UrlEncode = UrlEncode

local function UrlDecode(data)
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			if type(k == 'string') then
				t[UrlDecodeString(k)] = UrlDecode(v)
			else
				t[k] = UrlDecode(v)
			end
		end
		return t
	elseif type(data) == 'string' then
		return UrlDecodeString(data)
	else
		return data
	end
end
MY.UrlDecode = UrlDecode

local m_simpleMatchCache = setmetatable({}, { __mode = 'v' })
function MY.StringSimpleMatch(szText, szFind, bDistinctCase, bDistinctEnEm, bIgnoreSpace)
	if not bDistinctCase then
		szFind = StringLowerW(szFind)
		szText = StringLowerW(szText)
	end
	if not bDistinctEnEm then
		szText = StringEnerW(szText)
	end
	if bIgnoreSpace then
		szFind = StringReplaceW(szFind, ' ', '')
		szFind = StringReplaceW(szFind, g_tStrings.STR_ONE_CHINESE_SPACE, '')
		szText = StringReplaceW(szText, ' ', '')
		szText = StringReplaceW(szText, g_tStrings.STR_ONE_CHINESE_SPACE, '')
	end
	local me = GetClientPlayer()
	if me then
		szFind = szFind:gsub('$zj', me.szName)
		local szTongName = ''
		local tong = GetTongClient()
		if tong and me.dwTongID ~= 0 then
			szTongName = tong.ApplyGetTongName(me.dwTongID) or ''
		end
		szFind = szFind:gsub('$bh', szTongName)
		szFind = szFind:gsub('$gh', szTongName)
	end
	local tFind = m_simpleMatchCache[szFind]
	if not tFind then
		tFind = {}
		for _, szKeywordsLine in ipairs(MY.SplitString(szFind, ';', true)) do
			local tKeyWordsLine = {}
			for _, szKeywords in ipairs(MY.SplitString(szKeywordsLine, ',', true)) do
				local tKeyWords = {}
				for _, szKeyword in ipairs(MY.SplitString(szKeywords, '|', true)) do
					local bNegative = szKeyword:sub(1, 1) == '!'
					if bNegative then
						szKeyword = szKeyword:sub(2)
					end
					if not bDistinctEnEm then
						szKeyword = StringEnerW(szKeyword)
					end
					insert(tKeyWords, { szKeyword = szKeyword, bNegative = bNegative })
				end
				insert(tKeyWordsLine, tKeyWords)
			end
			insert(tFind, tKeyWordsLine)
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
			for _, info in ipairs(tKeyWords) do      -- 符合一个即可
				-- szKeyword = MY.EscapeString(szKeyword) -- 用了wstring还Escape个捷豹
				if info.bNegative then               -- !小铁被吃了
					if not wfind(szText, info.szKeyword) then
						bKeyWord = true
					end
				else                                                    -- 十人   -- 10
					if wfind(szText, info.szKeyword) then
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
