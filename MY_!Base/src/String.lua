--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 字符串处理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local AnsiToUTF8 = AnsiToUTF8 or _G.ansi_to_utf8
local UrlEncodeString, UrlDecodeString = UrlEncode, UrlDecode
--------------------------------------------
-- 本地函数和变量
--------------------------------------------

-- 分隔字符串
-- (table) LIB.SplitString(string szText, table aSpliter, bool bIgnoreEmptyPart)
-- (table) LIB.SplitString(string szText, string szSpliter, bool bIgnoreEmptyPart)
-- szText           原始字符串
-- szSpliter        分隔符
-- aSpliter         多个分隔符
-- bIgnoreEmptyPart 是否忽略空字符串，即'123;234;'被';'分成{'123','234'}还是{'123','234',''}
-- nMaxPart         最多分成几份，即'1;2;3;4'被';'分隔时，如果最多三份则得到{'1','2','3;4'}
function LIB.SplitString(szText, aSpliter, bIgnoreEmptyPart, nMaxPart)
	if IsString(aSpliter) then
		aSpliter = {aSpliter}
	end
	local nOff, nLen, aResult, nResult, szPart, nEnd, szEnd, nPos = 1, #szText, {}, 0
	while true do
		nEnd, szEnd = nil
		if not nMaxPart or nMaxPart > nResult + 1 then
			for _, szSpliter in ipairs(aSpliter) do
				if szSpliter == '' then
					nPos = #wsub(sub(szText, nOff), 1, 1)
					if nPos == 0 then
						nPos = nil
					else
						nPos = nOff + nPos
					end
				else
					nPos = StringFindW(szText, szSpliter, nOff)
				end
				if nPos and (not nEnd or nPos < nEnd) then
					nEnd, szEnd = nPos, szSpliter
				end
			end
		end
		if not nEnd then
			szPart = sub(szText, nOff, len(szText))
			if not bIgnoreEmptyPart or szPart ~= '' then
				nResult = nResult + 1
				insert(aResult, szPart)
			end
			break
		end
		szPart = sub(szText, nOff, nEnd - 1)
		if not bIgnoreEmptyPart or szPart ~= '' then
			nResult = nResult + 1
			insert(aResult, szPart)
		end
		nOff = nEnd + len(szEnd)
		if nOff > nLen then
			break
		end
	end
	return aResult
end

function LIB.EscapeString(s)
	return (gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1'))
end

function LIB.TrimString(szText)
	if not szText or szText == '' then
		return ''
	end
	return (gsub(szText, '^%s*(.-)%s*$', '%1'))
end

function LIB.EncryptString(szText)
	return szText:gsub('.', function (c) return format ('%02X', (byte(c) + 13) % 256) end):gsub(' ', '+')
end

function LIB.SimpleEncryptString(szText)
	local a = {}
	for i = 1, #szText do
		a[i] = char((szText:byte(i) + 13) % 256)
	end
	return (LIB.Base64Encode(concat(a)):gsub('/', '-'):gsub('+', '_'):gsub('=', '.'))
end

function LIB.SimpleDecryptString(szCipher)
	local szBin = LIB.Base64Decode((szCipher:gsub('-', '/'):gsub('_', '+'):gsub('%.', '=')))
	if not szBin then
		return
	end
	local a = {}
	for i = 1, #szBin do
		a[i] = char((szBin:byte(i) - 13 + 256) % 256)
	end
	return concat(a)
end

function LIB.SimpleDecodeString(szCipher, bTripSlashes)
	local aPhrase = {'v', 'u', 'S', 'r', 'q', '9', 'O', 'b'}
	local nPhrase = #aPhrase
	for i, v in ipairs(aPhrase) do
		aPhrase[i] = v:byte()
	end

	local aText, ch1, ch2 = {}
	for i = 1, #szCipher, 2 do
		ch1 = szCipher:byte(i) - 65;
		ch2 = szCipher:byte(i + 1) - 65;
		ch1 = LIB.NumberBitOr(LIB.NumberBitShl(ch1, 4, 64), ch2)
		aText[(i + 1) / 2] = char(LIB.NumberBitXor(ch1, aPhrase[(((i + 1) / 2) - 1) % nPhrase + 1]))
	end
	return concat(aText)
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
		insert(t, tostring(data))
	end
end

function LIB.EncodePostData(data)
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
LIB.ConvertToUTF8 = ConvertToUTF8

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
LIB.ConvertToAnsi = ConvertToAnsi

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
LIB.UrlEncode = UrlEncode

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
LIB.UrlDecode = UrlDecode

local m_simpleMatchCache = setmetatable({}, { __mode = 'v' })
function LIB.StringSimpleMatch(szText, szFind, bDistinctCase, bDistinctEnEm, bIgnoreSpace)
	if not bDistinctCase then
		szFind = StringLowerW(szFind)
		szText = StringLowerW(szText)
	end
	if not bDistinctEnEm then
		szText = StringEnerW(szText)
	end
	if bIgnoreSpace then
		szFind = wgsub(szFind, ' ', '')
		szFind = wgsub(szFind, g_tStrings.STR_ONE_CHINESE_SPACE, '')
		szText = wgsub(szText, ' ', '')
		szText = wgsub(szText, g_tStrings.STR_ONE_CHINESE_SPACE, '')
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
		for _, szKeywordsLine in ipairs(LIB.SplitString(szFind, ';', true)) do
			local tKeyWordsLine = {}
			for _, szKeywords in ipairs(LIB.SplitString(szKeywordsLine, ',', true)) do
				local tKeyWords = {}
				for _, szKeyword in ipairs(LIB.SplitString(szKeywords, '|', true)) do
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
				-- szKeyword = LIB.EscapeString(szKeyword) -- 用了wstring还Escape个捷豹
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

function LIB.IsSensitiveWord(szText)
	if not _G.TextFilterCheck then
		return false
	end
	return not _G.TextFilterCheck(szText)
end

function LIB.ReplaceSensitiveWord(szText)
	if not _G.TextFilterReplace then
		return szText
	end
	local bResult, szResult = _G.TextFilterReplace(szText)
	if not bResult then
		return szText
	end
	return szResult
end

do
local CACHE = setmetatable({}, { __mode = 'v' })
function LIB.GetFormatText(...)
	local szKey = EncodeLUAData({...})
	if not CACHE[szKey] then
		CACHE[szKey] = {GetFormatText(...)}
	end
	return CACHE[szKey][1]
end
end

do
local CACHE = setmetatable({}, { __mode = 'v' })
function LIB.GetPureText(szXml, szDriver)
	if not szDriver then
		szDriver = 'AUTO'
	end
	local cache = CACHE[szXml]
	if not cache then
		cache = {}
		CACHE[szXml] = cache
	end
	if IsNil(cache.c) and (szDriver == 'CPP' or szDriver == 'AUTO') then
		cache.c = GetPureText
			and GetPureText(szXml)
			or false
	end
	if IsNil(cache.l) and (szDriver == 'LUA' or (szDriver == 'AUTO' and not cache.c)) then
		local aXMLNode = LIB.XMLDecode(szXml)
		cache.l = LIB.XMLGetPureText(aXMLNode) or false
	end
	if szDriver == 'CPP' then
		return cache.c
	end
	if szDriver == 'LUA' then
		return cache.l
	end
	return cache.c or cache.l
end
end
