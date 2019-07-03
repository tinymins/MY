--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Json 处理模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------
-- local lua_value = LIB.JsonDecode(raw_json_text)
-- local raw_json_text = LIB.JsonEncode(lua_table_or_value)
-- local pretty_json_text = LIB.JsonEncode(lua_table_or_value, true)
---------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------

-- if JsonEncode and JsonDecode then
-- 	LIB.JsonEncode  = JsonEncode
-- 	LIB.JsonEncode = JsonEncode
-- 	LIB.JsonDecode  = JsonDecode
-- 	LIB.JsonDecode = JsonDecode
-- else
--
-- Simple JSON encoding and decoding in pure Lua.
--
-- @author hightman, Jeffrey Friedl
-- @refer http://regex.info/blog/
--
-- local lua_value = LIB.JsonDecode(raw_json_text)
-- local raw_json_text = LIB.JsonEncode(lua_table_or_value)
-- local pretty_json_text = LIB.JsonEncode(lua_table_or_value, true)
---------------------------------------------------------------------------
local pairs, ipairs = pairs, ipairs
local char, srep = string.char, string.rep
local floor, HUGE, max = math.floor, math.huge, math.max
local tonumber, tostring = tonumber, tostring
local type = type
local tconcat, tinsert = table.concat, table.insert

-- decode util functions
local function unicode_codepoint_as_utf8(codepoint)
	-- codepoint is a number
	if codepoint <= 127 then
		return char(codepoint)
	elseif codepoint <= 2047 then
		-- 110yyyxx 10xxxxxx         <-- useful notation from http://en.wikipedia.org/wiki/Utf8
		local highpart = floor(codepoint / 0x40)
		local lowpart  = codepoint - (0x40 * highpart)
		return char(0xC0 + highpart, 0x80 + lowpart)
	elseif codepoint <= 65535 then
		-- 1110yyyy 10yyyyxx 10xxxxxx
		local highpart  = floor(codepoint / 0x1000)
		local remainder = codepoint - 0x1000 * highpart
		local midpart   = floor(remainder / 0x40)
		local lowpart   = remainder - 0x40 * midpart
		highpart = 0xE0 + highpart
		midpart  = 0x80 + midpart
		lowpart  = 0x80 + lowpart
		-- Check for an invalid character (thanks Andy R. at Adobe).
		-- See table 3.7, page 93, in http://www.unicode.org/versions/Unicode5.2.0/ch03.pdf#G28070
		if ( highpart == 0xE0 and midpart < 0xA0 ) or
			( highpart == 0xED and midpart > 0x9F ) or
			( highpart == 0xF0 and midpart < 0x90 ) or
			( highpart == 0xF4 and midpart > 0x8F ) then
			return '?'
		else
			return char(highpart, midpart, lowpart)
		end
	else
		-- 11110zzz 10zzyyyy 10yyyyxx 10xxxxxx
		local highpart  = floor(codepoint / 0x40000)
		local remainder = codepoint - 0x40000 * highpart
		local midA      = floor(remainder / 0x1000)
		remainder       = remainder - 0x1000 * midA
		local midB      = floor(remainder / 0x40)
		local lowpart   = remainder - 0x40 * midB
		return char(0xF0 + highpart, 0x80 + midA, 0x80 + midB, 0x80 + lowpart)
	end
end

local function decode_error(message, text, location)
	if text then
		if location then
			message = string.format('%s at char %d of: %s', message, location, text)
		else
			message = string.format('%s: %s', message, text)
		end
	end
	assert(false, message)
end

local function grok_number(text, start)
	-- Grab the integer part
	local integer_part = text:match('^-?[1-9]%d*', start) or text:match('^-?0', start)
	if not integer_part then
		decode_error('expected number', text, start)
	end
	local i = start + integer_part:len()
	-- Grab an optional decimal part
	local decimal_part = text:match('^%.%d+', i) or ''
	i = i + decimal_part:len()
	-- Grab an optional exponential part
	local exponent_part = text:match('^[eE][-+]?%d+', i) or ''
	i = i + exponent_part:len()
	local full_number_text = integer_part .. decimal_part .. exponent_part
	local as_number = tonumber(full_number_text)
	if not as_number then
		decode_error('bad number', text, start)
	end
	return as_number, i
end

local function grok_string(text, start)
	if text:sub(start,start) ~= '"' then
		decode_error('expected string\'s opening quote', text, start)
	end
	local i = start + 1 -- +1 to bypass the initial quote
	local text_len = text:len()
	local VALUE = ''
	while i <= text_len do
		local c = text:sub(i,i)
		if c == '"' then
			return VALUE, i + 1
		end
		if c ~= '\\' then
			VALUE = VALUE .. c
			i = i + 1
		elseif text:match('^\\b', i) then
			VALUE = VALUE .. '\b'
			i = i + 2
		elseif text:match('^\\f', i) then
			VALUE = VALUE .. '\f'
			i = i + 2
		elseif text:match('^\\n', i) then
			VALUE = VALUE .. '\n'
			i = i + 2
		elseif text:match('^\\r', i) then
			VALUE = VALUE .. '\r'
			i = i + 2
		elseif text:match('^\\t', i) then
			VALUE = VALUE .. '\t'
			i = i + 2
		else
			local hex = text:match('^\\u([0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
			if hex then
				i = i + 6 -- bypass what we just read
				-- We have a Unicode codepoint. It could be standalone, or if in the proper range and
				-- followed by another in a specific range, it'll be a two-code surrogate pair.
				local codepoint = tonumber(hex, 16)
				if codepoint >= 0xD800 and codepoint <= 0xDBFF then
					-- it's a hi surrogate... see whether we have a following low
					local lo_surrogate = text:match('^\\u([dD][cdefCDEF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
					if lo_surrogate then
						i = i + 6 -- bypass the low surrogate we just read
						codepoint = 0x2400 + (codepoint - 0xD800) * 0x400 + tonumber(lo_surrogate, 16)
					else
						-- not a proper low, so we'll just leave the first codepoint as is and spit it out.
					end
				end
				VALUE = VALUE .. unicode_codepoint_as_utf8(codepoint)
			else
				-- just pass through what's escaped
				VALUE = VALUE .. text:match('^\\(.)', i)
				i = i + 2
			end
		end
	end
	decode_error('unclosed string', text, start)
end

local function skip_whitespace(text, start)
	local match_start, match_end = text:find('^[ \n\r\t]+', start) -- [http://www.ietf.org/rfc/rfc4627.txt] Section 2
	if match_end then
		return match_end + 1
	else
		return start
	end
end

-- this function later define
local grok_one

local function grok_object(text, start)
	local i = skip_whitespace(text, start + 1) -- +1 to skip the '{'
	local VALUE = {}
	if text:sub(i,i) == '}' then
		return VALUE, i + 1
	end
	local text_len = text:len()
	while i <= text_len do
		local key, new_i = grok_string(text, i)
		i = skip_whitespace(text, new_i)
		if text:sub(i, i) ~= ':' then
			decode_error('expected colon', text, i)
		end
		i = skip_whitespace(text, i + 1)
		local val, new_i = grok_one(text, i)
		VALUE[key] = val
		-- Expect now either '}' to end things, or a ',' to allow us to continue.
		i = skip_whitespace(text, new_i)
		local c = text:sub(i,i)
		if c == '}' then
			return VALUE, i + 1
		end
		if text:sub(i, i) ~= ',' then
			decode_error('expected comma or \'}\'', text, i)
		end
		i = skip_whitespace(text, i + 1)
	end
	decode_error('unclosed \'{\'', text, start)
end

local function grok_array(text, start)
	local i = skip_whitespace(text, start + 1) -- +1 to skip the '['
	local VALUE = {}
	if text:sub(i,i) == ']' then
		return VALUE, i + 1
	end
	local text_len = text:len()
	local nIndex = 1
	while i <= text_len do
		local val, new_i = grok_one(text, i)
		-- table.insert(VALUE, val) -- this will cause a bug: table.insert(VALUE, nil) -- [null,null,1] -> {1}
		VALUE[nIndex] = val
		i = skip_whitespace(text, new_i)
		-- Expect now either ']' to end things, or a ',' to allow us to continue.
		local c = text:sub(i,i)
		if c == ']' then
			return VALUE, i + 1
		end
		if text:sub(i, i) ~= ',' then
			decode_error('expected comma or \'[\'', text, i)
		end
		i = skip_whitespace(text, i + 1)
		nIndex = nIndex + 1
	end
	decode_error('unclosed \'[\'', text, start)
end

grok_one = function(text, start)
	start = skip_whitespace(text, start)
	if start > text:len() then
		decode_error('unexpected end of string', text, nil)
	end
	if text:find('^"', start) then
		return grok_string(text, start)
	elseif text:find('^[-0123456789 ]', start) then
		return grok_number(text, start)
	elseif text:find('^%{', start) then
		return grok_object(text, start)
	elseif text:find('^%[', start) then
		return grok_array(text, start)
	elseif text:find('^true', start) then
		return true, start + 4
	elseif text:find('^false', start) then
		return false, start + 5
	elseif text:find('^null', start) then
		return nil, start + 4
	else
		decode_error('cant parse JSON', text, start)
	end
end

-- @return result[, error]
local function decode_value(text)
	if type(text) ~= 'string' then
		return nil, string.format('expected string argument to Json_Decode(), got %s', type(text))
	end
	if text:match('^%s*$') then
		return nil, 'empty string passed to Json_Decode()'
	end
	if text:match('^%s*<') then
		return nil, 'HTML passed to Json_Decode()'
	end
	-- Ensure that it's not UTF-32 or UTF-16.
	-- Those are perfectly valid encodings for JSON (as per RFC 4627 section 3),
	-- but this package can't handle them.
	if text:sub(1,1):byte() == 0 or (text:len() >= 2 and text:sub(2,2):byte() == 0) then
		return nil, 'JSON package groks only UTF-8, sorry'
	end
	local success, value = pcall(grok_one, text, 1)
	if success then
		return value
	else
		return nil, value
	end
end

-- encode util functions
local function backslash_replacement_function(c)
	if c == '\n' then
		return '\\n'
	elseif c == '\r' then
		return '\\r'
	elseif c == '\t' then
		return '\\t'
	elseif c == '\b' then
		return '\\b'
	elseif c == '\f' then
		return '\\f'
	elseif c == '"' then
		return '\\"'
	elseif c == '\\' then
		return '\\\\'
	else
		return string.format('\\u%04x', c:byte())
	end
end

local chars_to_be_escaped_in_JSON_string
= '['
..    '"'    -- class sub-pattern to match a double quote
..    '%\\'  -- class sub-pattern to match a backslash
..    '%z'   -- class sub-pattern to match a null
..    '\001' .. '-' .. '\031' -- class sub-pattern to match control characters
.. ']'

local function json_string_literal(value)
	local newval = value:gsub(chars_to_be_escaped_in_JSON_string, backslash_replacement_function)
	return '"' .. newval .. '"'
end

local function object_or_array(T)
	-- We need to inspect all the keys... if there are any strings, we'll convert to a JSON
	-- object. If there are only numbers, it's a JSON array.
	--
	-- If we'll be converting to a JSON object, we'll want to sort the keys so that the
	-- end result is deterministic.
	local string_keys = { }
	local number_keys = { }
	local number_keys_must_be_strings = false
	local maximum_number_key
	-- fetch all keys
	for key in pairs(T) do
		if type(key) == 'string' then
			tinsert(string_keys, key)
		elseif type(key) == 'number' then
			tinsert(number_keys, key)
			if key <= 0 or key >= HUGE then
				number_keys_must_be_strings = true
			elseif not maximum_number_key or key > maximum_number_key then
				maximum_number_key = key
			end
		end
	end
	-- An empty table, or a numeric-only array
	if #string_keys == 0 and not number_keys_must_be_strings then
		if #number_keys > 0 then
			return nil, maximum_number_key -- an array
		else
			-- have to guess, so we'll pick array, since empty arrays are likely more common than empty objects
			return nil
		end
	end
	-- An object with number map
	local map = nil
	table.sort(string_keys)
	if #number_keys > 0 then
		map = {}
		for key, val in pairs(T) do
			map[key] = val
		end
		table.sort(number_keys)
		for _, number_key in ipairs(number_keys) do
			local string_key = tostring(number_key)
			if map[string_key] == nil then
				tinsert(string_keys , string_key)
				map[string_key] = T[number_key]
			end
		end
	end
	return string_keys, nil, map
end

-- @param mixed value
-- @param table parent
-- @param string|nil indent non-nil indent means pretty-printing
local function encode_value(value, parents, indent)
	if value == nil then
		return 'null'
	elseif type(value) == 'string' then
		return json_string_literal(value)
	elseif type(value) == 'number' then
		if value ~= value then
			-- NaN (Not a Number).
			-- JSON has no NaN, so we have to fudge the best we can. This should really be a package option.
			return 'null'
		elseif value >= HUGE then
			-- Positive infinity. JSON has no INF, so we have to fudge the best we can. This should
			-- really be a package option. Note: at least with some implementations, positive infinity
			-- is both '>= HUGE' and '<= -HUGE', which makes no sense but that's how it is.
			-- Negative infinity is properly '<= -HUGE'. So, we must be sure to check the '>='
			-- case first.
			return '1e+9999'
		elseif value <= -HUGE then
			-- Negative infinity.
			-- JSON has no INF, so we have to fudge the best we can. This should really be a package option.
			return '-1e+9999'
		else
			return tostring(value)
		end
	elseif type(value) == 'boolean' then
		return tostring(value)
	elseif type(value) ~= 'table' and type(value) ~= 'userdata' then
		return json_string_literal(tostring(value))
	else
		-- A table to be converted to either a JSON object or array.
		local T = value
		if parents[T] then
			return nil
		end
		parents[T] = true
		-------------
		local result_value
		local object_keys, maximum_number_key, map = object_or_array(T)
		if maximum_number_key then
			-- An array
			local ITEMS = {}
			for i = 1, maximum_number_key do
				tinsert(ITEMS, encode_value(T[i], parents, indent))
			end
			if indent then
				result_value = '[ ' .. tconcat(ITEMS, ', ') .. ' ]'
			else
				result_value = '[' .. tconcat(ITEMS, ',') .. ']'
			end
		elseif object_keys then
			-- An object
			local TT = map or T
			if indent then
				local KEYS = {}
				local max_key_length = 0
				for _, key in ipairs(object_keys) do
					local encoded = encode_value(tostring(key), parents, '')
					max_key_length = max(max_key_length, #encoded)
					tinsert(KEYS, encoded)
				end
				local key_indent = indent .. '    '
				local subtable_indent = indent .. srep(' ', max_key_length + 2 + 4)
				local FORMAT = '%s%' .. string.format('%d', max_key_length) .. 's: %s'
				local COMBINED_PARTS = {}
				for i, key in ipairs(object_keys) do
					local encoded_val = encode_value(TT[key], parents, subtable_indent)
					if encoded_val then
						tinsert(COMBINED_PARTS, string.format(FORMAT, key_indent, KEYS[i], encoded_val))
					end
				end
				result_value = '{\n' .. tconcat(COMBINED_PARTS, ',\n') .. '\n' .. indent .. '}'
			else
				local PARTS = {}
				for _, key in ipairs(object_keys) do
					local encoded_val = encode_value(TT[key], parents, indent)
					if encoded_val then
						local encoded_key = encode_value(tostring(key), parents, indent)
						tinsert(PARTS, string.format('%s:%s', encoded_key, encoded_val))
					end
				end
				result_value = '{' .. tconcat(PARTS, ',') .. '}'
			end
		else
			result_value = '[]'
		end
		parents[T] = false
		return result_value
	end
end

-- 编码 JSON 数据，成功返回 JSON 字符串，失败返回 nil
-- (string) LIB.JsonEncode(vData[, bPretty])
-- vData 变量数据，支持字符串、数字、Table/Userdata
-- bPretty 是否增加缩进美化，默认为 false
function LIB.JsonEncode(vData, bPretty)
	return encode_value(vData, {}, bPretty and '')
end

-- 解析 JSON 数据，成功返回数据，失败返回 nil 加错误信息
-- (mixed) LIB.JsonDecode(string szData)
function LIB.JsonDecode(value)
	return decode_value(value)
end

-- end
