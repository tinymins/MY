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
-- local aXMLNode = LIB.XMLDecode(szXML: string)
-- local szXML = LIB.XMLEncode(xml: aXMLNode | XMLNode)
---------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------

local function bytes2string(bytes)
	local char, insert, concat, unpack = string.char, insert, concat, unpack
	local count = #bytes
	if count > 100 then
		local t, i = {}, 1
		while i <= count do
			insert(t, char(unpack(bytes, i, min(i + 99, count))))
			i = i + 100
		end
		return concat(t)
	else
		return char(unpack(bytes))
	end
end

local function XMLEscape(str)
	return (str:gsub('\\', '\\\\'):gsub('"', '\\"'))
end

local function XMLUnescape(str)
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

local function XMLCreateNode(type)
	return { type = type, attrs = {}, data = {}, children = {} }
end

local function XMLIsNode(node)
	return IsTable(node)
		and IsString(node.type)
		and IsTable(node.attrs)
		and IsTable(node.data)
		and IsTable(node.children)
end

local function XMLGetNodeType(node)
	return node.type
end

local function XMLGetNodeAttr(node, key)
	return node.attrs[key]
end

local function XMLSetNodeAttr(node, key, val)
	node.attrs[key] = val
end

local function XMLGetNodeData(node, key)
	return node.data[key]
end

local function XMLSetNodeData(node, key, val)
	node.data[key] = val
end

local function XMLGetNodeChildren(node)
	return node.children
end

local function XMLDecode(xml)
	local function str2var(str)
		if str == 'true' then
			return true
		elseif str == 'false' then
			return false
		elseif tonumber(str) then
			return tonumber(str)
		end
	end
	local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
	local find, sub, gsub, char, byte = string.find, string.sub, string.gsub, string.char, string.byte
	local function bytes2string(bytes)
		local count = #bytes
		if count > 100 then
			local t, i = {}, 1
			while i <= count do
				insert(t, char(unpack(bytes, i, min(i + 99, count))))
				i = i + 100
			end
			return concat(t)
		else
			return char(unpack(bytes))
		end
	end
	local t = XMLCreateNode('')
	local p = t
	local p1
	local stack = {}
	local state = 'text'
	local pos, xlen = 1, #xml
	local byte_current
	local byte_apos, byte_quot, byte_escape, byte_slash = (byte('"')) , (byte('"')), (byte('\\')), (byte('/'))
	local byte_lt, byte_gt, byte_amp, byte_eq, byte_space = (byte('<')), (byte('>')), (byte('&')), (byte('=')), (byte(' '))
	local byte_char_n, byte_char_t, byte_lf, byte_tab = (byte('n')), (byte('t')), (byte('\n')), (byte('\t'))
	local pos1, pos2, byte_quote, key, b_escaping, bytes_string
	-- <        label         attribute_key=attribute_value>        text_key=text_value<        /     label         >
	-- label_lt label_opening attribute                    label_gt text               label_lt slash label_closing label_gt
	while pos <= xlen do
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
				p1 = XMLCreateNode(xml:sub(pos1, pos - 1))
				insert(stack, p1)
				insert(p.children, p1)
				p = p1
			elseif byte_current == byte_space then
				state = 'attribute'
				p1 = XMLCreateNode(xml:sub(pos1, pos - 1))
				insert(stack, p1)
				insert(p.children, p1)
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
				p.attrs[key] = key
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
				p.attrs[key] = bytes2string(bytes_string)
				state = 'attribute'
			else
				insert(bytes_string, byte_current)
			end
		elseif state == 'attribute_value' then
			if byte_current == byte_space then
				p.attrs[key] = str2var(xml:sub(pos1, pos))
				state = 'attribute'
			elseif byte_current == byte_gt then
				p.attrs[key] = str2var(xml:sub(pos1, pos - 1))
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
				p.data[key] = key
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
				p.data[key] = bytes2string(bytes_string)
				state = 'text'
			else
				insert(bytes_string, byte_current)
			end
		elseif state == 'text_value' then
			if byte_current == byte_space then
				p.data[key] = str2var(xml:sub(pos1, pos))
				state = 'text'
			elseif byte_current == byte_lt then
				p.data[key] = str2var(xml:sub(pos1, pos - 1))
				state = 'label_lt'
			end
		end
		pos = pos + 1
	end
	if #stack ~= 0 then
		return Log('XML decode error: unclosed elements detected.' .. #stack .. ' stacks on `' .. xml .. '`')
	end
	return t.children
end

local function XMLEncode(xml)
	local t = {}
	if XMLIsNode(xml) then
		-- head open
		insert(t, '<')
		insert(t, xml.type)
		-- attributes
		for k, v in pairs(xml.attrs) do
			insert(t, ' ')
			insert(t, k)
			insert(t, '=')
			if type(v) == 'string' then
				insert(t, '"')
				insert(t, XMLEscape(v))
				insert(t, '"')
			elseif type(v) == 'boolean' then
				insert(t, (( v and 'true' ) or 'false'))
			else
				insert(t, tostring(v))
			end
		end
		-- head close
		insert(t, '>')
		-- data
		for k, v in pairs(xml.data) do
			insert(t, ' ')
			insert(t, k)
			insert(t, '=')
			if type(v) == 'string' then
				insert(t, '"')
				insert(t, XMLEscape(v))
				insert(t, '"')
			elseif type(v) == 'boolean' then
				insert(t, (( v and 'true' ) or 'false'))
			else
				insert(t, tostring(v))
			end
		end
		-- children
		for _, v in ipairs(XMLGetNodeChildren(xml)) do
			insert(t, XMLEncode(v))
		end
		-- node close
		insert(t, '</')
		insert(t, XMLGetNodeType(xml))
		insert(t, '>')
	elseif IsTable(xml) then
		for _, v in ipairs(xml) do
			insert(t, XMLEncode(v))
		end
	end
	return (concat(t))
end

local function XMLGetPureText(xml)
	local a = {}
	if XMLIsNode(xml) then
		insert(a, XMLGetNodeData(xml, 'text') or '')
		for _, v in ipairs(XMLGetNodeChildren(xml)) do
			insert(a, XMLGetPureText(v))
		end
	elseif IsTable(xml) then
		for _, v in ipairs(xml) do
			insert(a, XMLGetPureText(v))
		end
	end
	return concat(a)
end

-- 解析 XML 数据，成功返回数据，失败返回 nil 加错误信息
-- (XMLNode[] | nil) LIB.XMLDecode(szData: string)
LIB.XMLDecode = XMLDecode

-- 编码 XML 数据，成功返回 XML 字符串，失败返回 nil
-- (string) LIB.XMLEncode(xml: XMLNode[] | XMLNode)
LIB.XMLEncode = XMLEncode

-- 转义 XML 字符串
-- (string) LIB.XMLEscape(raw_str: string)
LIB.XMLEscape = XMLEscape

-- 反转义 XML 字符串
-- (string) LIB.XMLUnescape(escaped_str: string)
LIB.XMLUnescape = XMLUnescape

-- XML 转纯文字
-- (string) LIB.XMLGetPureText(xml: XMLNode[] | XMLNode)
LIB.XMLGetPureText = XMLGetPureText

-- 创建 XML 节点
-- (XMLNode) LIB.XMLCreateNode(type: string)
LIB.XMLCreateNode = XMLCreateNode

-- 判断是否是 XML 节点
-- (boolean) LIB.XMLIsNode(xml: XMLNode | any)
LIB.XMLIsNode = XMLIsNode

-- 获取 XML 节点类型
-- (string) LIB.XMLGetNodeType(xml: XMLNode)
LIB.XMLGetNodeType = XMLGetNodeType

-- 获取 XML 节点属性
-- (string | number | boolean) LIB.XMLGetNodeAttr(xml: XMLNode, key: string)
LIB.XMLGetNodeAttr = XMLGetNodeAttr

-- 设置 XML 节点属性
-- (void) LIB.XMLSetNodeAttr(xml: XMLNode, key: string, val: string | number | boolean)
LIB.XMLSetNodeAttr = XMLSetNodeAttr

-- 获取 XML 节点数据
-- (string | number | boolean) LIB.XMLGetNodeData(xml: XMLNode, key: string)
LIB.XMLGetNodeData = XMLGetNodeData

-- 设置 XML 节点数据
-- (void) LIB.XMLSetNodeData(xml: XMLNode, key: string, val: string | number | boolean)
LIB.XMLSetNodeData = XMLSetNodeData

-- 获取 XML 子节点列表
-- (XMLNode[]) LIB.XMLGetNodeChildren(xml: XMLNode)
LIB.XMLGetNodeChildren = XMLGetNodeChildren
