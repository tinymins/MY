---------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : XML 处理函数库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = Boilerplate
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SaveCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------

local byte_escape, byte_slash = (byte('\\')), (byte('/'))
local byte_apos  , byte_quote = (byte('\'')), (byte('"'))
local byte_lf    , byte_tab   = (byte('\n')), (byte('\t'))
local byte_lt    , byte_gt    = (byte('<')) , (byte('>'))
local byte_amp   , byte_eq    = (byte('&')) , (byte('='))
local byte_space , byte_dot   = (byte(' ')) , (byte('.'))
local byte_zero  , byte_nine  = (byte('0')) , (byte('9'))
local byte_char_a, byte_char_e, byte_char_f = (byte('a')), (byte('e')), (byte('f'))
local byte_char_l, byte_char_n, byte_char_r = (byte('l')), (byte('n')), (byte('r'))
local byte_char_s, byte_char_t, byte_char_u = (byte('s')), (byte('t')), (byte('u'))

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

local XMLEncodeComponent = EncodeComponentsString
	or function(str)
		local bytes2string, insert, byte = bytes2string, insert, string.byte
		local bytes_string, len, byte_current = {}, #str, nil
		for i = 1, len do
			byte_current = byte(str, i)
			if byte_current == byte_lf then
				insert(bytes_string, byte_escape)
				-- byte_current = byte_char_n
			elseif byte_current == byte_tab then
				insert(bytes_string, byte_escape)
				-- byte_current = byte_char_t
			elseif byte_current == byte_escape or byte_current == byte_quote then
				insert(bytes_string, byte_escape)
			end
			insert(bytes_string, byte_current)
		end
		return bytes2string(bytes_string)
	end

local XMLDecodeComponent = _G.DecodeComponentsString
	or (GetPureText
		and function(str)
			return GetPureText('<text>text=' .. str .. '</text>')
		end)
	or function(str)
		local bytes2string, insert, byte = bytes2string, insert, string.byte
		local bytes_string, b_escaping, len, byte_current = {}, false, #str, nil
		for i = 1, len do
			byte_current = byte(str, i)
			if b_escaping then
				b_escaping = false
				-- if byte_current == byte_char_n then
					-- byte_current = byte_lf
				-- elseif byte_current == byte_char_t then
					-- byte_current = byte_tab
				-- else
				if byte_current ~= byte_lf and byte_current ~= byte_escape then
					insert(bytes_string, byte_escape)
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
	local pos1, pos2, byte_quoting_char, key, b_escaping
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
			or byte_current == byte_quote then
				byte_quoting_char = byte_current
				state = 'attribute_value_string'
				pos1 = pos
			elseif byte_current ~= byte_space then
				if byte_current >= byte_zero and byte_current <= byte_nine then
					state = 'attribute_value_number'
				elseif byte_current == byte_dot then
					state = 'attribute_value_dot_number'
				elseif byte_current == byte_char_t then
					state = 'attribute_value_pending_t'
				elseif byte_current == byte_char_f then
					state = 'attribute_value_pending_f'
				elseif byte_current == byte_gt then
					state = 'text'
				else
					state = 'attribute'
					pos = pos - 1
				end
				pos1 = pos
			end
		elseif state == 'attribute_value_string' then
			if b_escaping then
				b_escaping = false
			elseif byte_current == byte_escape then
				b_escaping = true
			elseif byte_current == byte_quoting_char then
				p.attrs[key] = XMLDecodeComponent((xml:sub(pos1, pos)))
				state = 'attribute'
			end
		elseif state == 'attribute_value_number' or state == 'attribute_value_dot_number' then
			if byte_current == byte_dot and state == 'attribute_value_number' then
				state = 'attribute_value_dot_number'
			elseif byte_current < byte_zero or byte_current > byte_nine then
				p.attrs[key] = tonumber(xml:sub(pos1, pos - 1))
				if byte_current == byte_space then
					state = 'attribute'
				elseif byte_current == byte_gt then
					state = 'text'
				else
					state = 'attribute'
					pos = pos - 1
				end
			end
		elseif state == 'attribute_value_pending_t' then
			if byte_current == byte_char_r then
				state = 'attribute_value_pending_tr'
			else
				state = 'attribute'
				pos = pos - 2
			end
		elseif state == 'attribute_value_pending_tr' then
			if byte_current == byte_char_u then
				state = 'attribute_value_pending_tru'
			else
				state = 'attribute'
				pos = pos - 3
			end
		elseif state == 'attribute_value_pending_tru' then
			if byte_current == byte_char_e then
				p.attrs[key] = true
				state = 'attribute'
			else
				state = 'attribute'
				pos = pos - 4
			end
		elseif state == 'attribute_value_pending_f' then
			if byte_current == byte_char_a then
				state = 'attribute_value_pending_fa'
			else
				state = 'attribute'
				pos = pos - 2
			end
		elseif state == 'attribute_value_pending_fa' then
			if byte_current == byte_char_l then
				state = 'attribute_value_pending_fal'
			else
				state = 'attribute'
				pos = pos - 3
			end
		elseif state == 'attribute_value_pending_fal' then
			if byte_current == byte_char_s then
				state = 'attribute_value_pending_fals'
			else
				state = 'attribute'
				pos = pos - 4
			end
		elseif state == 'attribute_value_pending_fals' then
			if byte_current == byte_char_e then
				p.attrs[key] = false
				state = 'attribute'
			else
				state = 'attribute'
				pos = pos - 5
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
			or byte_current == byte_quote then
				byte_quoting_char = byte_current
				state = 'text_value_string'
				pos1 = pos
			elseif byte_current ~= byte_space then
				if byte_current >= byte_zero and byte_current <= byte_nine then
					state = 'text_value_number'
				elseif byte_current == byte_dot then
					state = 'text_value_dot_number'
				elseif byte_current == byte_char_t then
					state = 'text_value_pending_t'
				elseif byte_current == byte_char_f then
					state = 'text_value_pending_f'
				elseif byte_current == byte_lt then
					state = 'label_lt'
				else
					state = 'text'
					pos = pos - 1
				end
				pos1 = pos
			end
		elseif state == 'text_value_string' then
			if b_escaping then
				b_escaping = false
			elseif byte_current == byte_escape then
				b_escaping = true
			elseif byte_current == byte_quoting_char then
				p.data[key] = XMLDecodeComponent((xml:sub(pos1, pos)))
				state = 'text'
			end
		elseif state == 'text_value_number' or state == 'text_value_dot_number' then
			if byte_current == byte_dot and state == 'text_value_number' then
				state = 'text_value_dot_number'
			elseif byte_current < byte_zero or byte_current > byte_nine then
				p.data[key] = tonumber(xml:sub(pos1, pos - 1))
				if byte_current == byte_space then
					state = 'text'
				elseif byte_current == byte_gt then
					state = 'text'
				else
					state = 'text'
					pos = pos - 1
				end
			end
		elseif state == 'text_value_pending_t' then
			if byte_current == byte_char_r then
				state = 'text_value_pending_tr'
			else
				state = 'text'
				pos = pos - 2
			end
		elseif state == 'text_value_pending_tr' then
			if byte_current == byte_char_u then
				state = 'text_value_pending_tru'
			else
				state = 'text'
				pos = pos - 3
			end
		elseif state == 'text_value_pending_tru' then
			if byte_current == byte_char_e then
				p.data[key] = true
				state = 'text'
			else
				state = 'text'
				pos = pos - 4
			end
		elseif state == 'text_value_pending_f' then
			if byte_current == byte_char_a then
				state = 'text_value_pending_fa'
			else
				state = 'text'
				pos = pos - 2
			end
		elseif state == 'text_value_pending_fa' then
			if byte_current == byte_char_l then
				state = 'text_value_pending_fal'
			else
				state = 'text'
				pos = pos - 3
			end
		elseif state == 'text_value_pending_fal' then
			if byte_current == byte_char_s then
				state = 'text_value_pending_fals'
			else
				state = 'text'
				pos = pos - 4
			end
		elseif state == 'text_value_pending_fals' then
			if byte_current == byte_char_e then
				p.data[key] = false
				state = 'text'
			else
				state = 'text'
				pos = pos - 5
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
				insert(t, XMLEncodeComponent(v))
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
				insert(t, XMLEncodeComponent(v))
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

-- 编码 XML 字符串
-- (string) LIB.XMLEncodeComponent(raw_str: string)
LIB.XMLEncodeComponent = XMLEncodeComponent

-- 解码 XML 字符串
-- (string) LIB.XMLDecodeComponent(escaped_str: string)
LIB.XMLDecodeComponent = XMLDecodeComponent

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
