---------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : XML 处理函数库
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
---------------------------------------------------------
-- Simple JX3 XML decoding and encoding in pure Lua.
---------------------------------------------------------
-- local lua_value = LIB.Xml.Decode(raw_xml_text)
-- local raw_xml_text = LIB.Xml.Encode(lua_table_or_value)
---------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
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
local LIB, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------

local xmlDecode = function(xml)
	local function str2var(str)
		if str == 'true' then
			return true
		elseif str == 'false' then
			return false
		elseif tonumber(str) then
			return tonumber(str)
		end
	end
	local insert, remove, concat = table.insert, table.remove, table.concat
	local find, sub, gsub, char, byte = string.find, string.sub, string.gsub, string.char, string.byte
	local function bytes2string(bytes)
		local count = #bytes
		if count > 100 then
			local t, i = {}, 1
			while i <= count do
				insert(t, char(unpack(bytes, i, math.min(i + 99, count))))
				i = i + 100
			end
			return concat(t)
		else
			return char(unpack(bytes))
		end
	end
	local t = {[''] = {}}
	local p = t
	local p1
	local stack = {}
	local state = 'text'
	local unpack = unpack or table.unpack
	local pos, len = 1, #xml
	local byte_current
	local byte_apos, byte_quot, byte_escape, byte_slash = (byte('"')) , (byte('"')), (byte('\\')), (byte('/'))
	local byte_lt, byte_gt, byte_amp, byte_eq, byte_space = (byte('<')), (byte('>')), (byte('&')), (byte('=')), (byte(' '))
	local byte_char_n, byte_char_t, byte_lf, byte_tab = (byte('n')), (byte('t')), (byte('\n')), (byte('\t'))
	local pos1, pos2, byte_quote, key, b_escaping, bytes_string
	-- <        label         attribute_key=attribute_value>        text_key=text_value<        /     label         >
	-- label_lt label_opening attribute                    label_gt text               label_lt slash label_closing label_gt
	while pos <= len do
		byte_current = byte(xml, pos)
		if state == 'text' then
			if byte_current == byte_lt then
				state = 'label_lt'
			elseif byte_current ~= byte_space then
				state = 'text_key'
				pos1 = pos
			end
		elseif state == 'label_lt' then
			if byte_current == byte_slash then
				state = 'label_closing'
				pos1 = pos + 1
			elseif byte_current ~= byte_space then
				state = 'label_opening'
				pos1 = pos
			end
		elseif state == 'label_opening' then
			if byte_current == byte_gt then
				state = 'text'
				p1 = { ['.'] = xml:sub(pos1, pos - 1), [''] = {} }
				insert(stack, p1)
				insert(p, p1)
				p = p1
			elseif byte_current == byte_space then
				state = 'attribute'
				p1 = { ['.'] = xml:sub(pos1, pos - 1), [''] = {} }
				insert(stack, p1)
				insert(p, p1)
				p = p1
			end
		elseif state == 'label_closing' then
			if byte_current == byte_gt then
				state = 'text'
				remove(stack)
				p = stack[#stack] or t
			end
		elseif state == 'attribute' then
			if byte_current == byte_gt then
				state = 'text'
			elseif byte_current ~= byte_space then
				state = 'attribute_key'
				pos1 = pos
			end
		elseif state == 'attribute_key' then
			if byte_current == byte_space then
				key = xml:sub(pos1, pos - 1)
				state = 'attribute_key_end'
			elseif byte_current == byte_eq then
				key = xml:sub(pos1, pos - 1)
				state = 'attribute_eq'
			end
		elseif state == 'attribute_key_end' then
			if byte_current == byte_eq then
				state = 'attribute_eq'
			elseif byte_current ~= byte_space then
				state = 'attribute'
				p[key] = key
				pos = pos - 1
			end
		elseif state == 'attribute_eq' then
			if byte_current == byte_apos
			or byte_current == byte_quot then
				byte_quote = byte_current
				state = 'attribute_value_string'
				bytes_string = {}
				pos1 = pos + 1
			elseif byte_current ~= byte_space then
				state = 'attribute_value'
				pos1 = pos
			end
		elseif state == 'attribute_value_string' then
			if b_escaping then
				b_escaping = false
				if byte_current == byte_char_n then
					byte_current = byte_lf
				elseif byte_current == byte_char_t then
					byte_current = byte_tab
				end
				insert(bytes_string, byte_current)
			elseif byte_current == byte_escape then
				b_escaping = true
			elseif byte_current == byte_quote then
				p[key] = bytes2string(bytes_string)
				state = 'attribute'
			else
				insert(bytes_string, byte_current)
			end
		elseif state == 'attribute_value' then
			if byte_current == byte_space then
				p[key] = str2var(xml:sub(pos1, pos))
				state = 'attribute'
			elseif byte_current == byte_gt then
				p[key] = str2var(xml:sub(pos1, pos - 1))
				state = 'text'
			end
		elseif state == 'text_key' then
			if byte_current == byte_space then
				key = xml:sub(pos1, pos - 1)
				state = 'text_key_end'
			elseif byte_current == byte_eq then
				key = xml:sub(pos1, pos - 1)
				state = 'text_eq'
			end
		elseif state == 'text_key_end' then
			if byte_current == byte_eq then
				state = 'text_eq'
			elseif byte_current ~= byte_space then
				state = 'text'
				p[''][key] = key
				pos = pos - 1
			end
		elseif state == 'text_eq' then
			if byte_current == byte_apos
			or byte_current == byte_quot then
				byte_quote = byte_current
				state = 'text_value_string'
				bytes_string = {}
				pos1 = pos + 1
			elseif byte_current ~= byte_space then
				state = 'text_value'
				pos1 = pos
			end
		elseif state == 'text_value_string' then
			if b_escaping then
				b_escaping = false
				if byte_current == byte_char_n then
					byte_current = byte_lf
				elseif byte_current == byte_char_t then
					byte_current = byte_tab
				end
				insert(bytes_string, byte_current)
			elseif byte_current == byte_escape then
				b_escaping = true
			elseif byte_current == byte_quote then
				p[''][key] = bytes2string(bytes_string)
				state = 'text'
			else
				insert(bytes_string, byte_current)
			end
		elseif state == 'text_value' then
			if byte_current == byte_space then
				p[''][key] = str2var(xml:sub(pos1, pos))
				state = 'text'
			elseif byte_current == byte_lt then
				p[''][key] = str2var(xml:sub(pos1, pos - 1))
				state = 'label_lt'
			end
		end
		pos = pos + 1
	end
	if #stack ~= 0 then
		return Log('XML decode error: unclosed elements detected.' .. #stack .. ' stacks on `' .. xml .. '`')
	end
	return t
end

local xmlEscape = function(str)
	return (str:gsub('\\', '\\\\'):gsub('"', '\\"'))
end

local bytes2string = function(bytes)
	local char, insert, concat, unpack = string.char, insert, concat, unpack
	local count = #bytes
	if count > 100 then
		local t, i = {}, 1
		while i <= count do
			insert(t, char(unpack(bytes, i, math.min(i + 99, count))))
			i = i + 100
		end
		return concat(t)
	else
		return char(unpack(bytes))
	end
end

local xmlUnescape = function(str)
	local bytes2string, insert, byte = bytes2string, insert, string.byte
	local bytes_string, b_escaping, len, byte_current = {}, false, #str
	local byte_char_n, byte_char_t, byte_lf, byte_tab, byte_escape = (byte('n')), (byte('t')), (byte('\n')), (byte('\t')), (byte('\\'))
	for i = 1, len do
		byte_current = byte(str, i)
		if b_escaping then
			b_escaping = false
			if byte_current == byte_char_n then
				byte_current = byte_lf
			elseif byte_current == byte_char_t then
				byte_current = byte_tab
			end
			insert(bytes_string, byte_current)
		elseif byte_current == byte_escape then
			b_escaping = true
		else
			insert(bytes_string, byte_current)
		end
	end
	return bytes2string(bytes_string)
end

local xmlEncode
xmlEncode = function(xml)
	local t = {}

	-- head
	if xml['.'] then
		insert(t, '<')
		insert(t, xml['.'])

		-- attributes
		local attr = ''
		for k, v in pairs(xml) do
			if type(k) == 'string' and string.find(k, '^[a-zA-Z0-9_]+$') then
				insert(t, ' ')
				insert(t, k)
				insert(t, '=')
				if type(v) == 'string' then
					insert(t, '"')
					insert(t, xmlEscape(v))
					insert(t, '"')
				elseif type(v) == 'boolean' then
					insert(t, (( v and 'true' ) or 'false'))
				else
					insert(t, tostring(v))
				end
			end
		end

		insert(t, '>')
	end
	-- inner attritubes
	local text = ''
	if xml[''] then
		for k, v in pairs(xml['']) do
			insert(t, ' ')
			insert(t, k)
			insert(t, '=')
			if type(v) == 'string' then
				insert(t, '"')
				insert(t, xmlEscape(v))
				insert(t, '"')
			elseif type(v) == 'boolean' then
				insert(t, (( v and 'true' ) or 'false'))
			else
				insert(t, tostring(v))
			end
		end
	end

	-- children
	for _, v in ipairs(xml) do
		insert(t, xmlEncode(v))
	end

	if xml['.'] then
		insert(t, '</')
		insert(t, xml['.'])
		insert(t, '>')
	end

	return (concat(t))
end

local xml2Text = function(xml)
	local t = {}
	local xmls = xmlDecode(xml)
	if xmls then
		for _, xml in ipairs(xmls) do
			if xml[''] then
				insert(t, xml[''].text)
			end
		end
	end
	return concat(t)
end

local function GetNodeType(node)
	return node['.']
end

local function GetNodeData(node)
	return node['']
end

-- public API
MY = MY or {}
LIB.Xml = LIB.Xml or {}

-- 解析 XML 数据，成功返回数据，失败返回 nil 加错误信息
-- (mixed) LIB.Xml.Decode(string szData)
LIB.Xml.Decode = xmlDecode

-- 编码 XML 数据，成功返回 XML 字符串，失败返回 nil
-- (string) LIB.Xml.Encode(tData)
-- tData 变量数据，Table保存的XML数据
LIB.Xml.Encode = xmlEncode

-- 转义 XML 字符串
-- (string) LIB.Xml.Escape(raw_str)
LIB.Xml.Escape = xmlEscape

-- 反转义 XML 字符串
-- (string) LIB.Xml.Unescape(escaped_str)
LIB.Xml.Unescape = xmlUnescape

-- xml转纯文字
LIB.Xml.GetPureText = xml2Text

-- xml节点类型
LIB.Xml.GetNodeType = GetNodeType

-- xml节点属性
LIB.Xml.GetNodeData = GetNodeData
