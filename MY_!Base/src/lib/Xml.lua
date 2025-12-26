--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : XML 处理函数库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
-- Simple JX3 XML decoding and encoding in pure Lua.
--------------------------------------------------------------------------------
-- local aXMLNode = X.XMLDecode(szXML: string)
-- local szXML = X.XMLEncode(xml: aXMLNode | XMLNode)
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Xml')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local Log = Log or print

local byte_escape, byte_slash = (string.byte('\\')), (string.byte('/'))
local byte_apos  , byte_quote = (string.byte('\'')), (string.byte('"'))
local byte_cr    , byte_lf    = (string.byte('\r')), (string.byte('\n'))
local byte_space , byte_tab   = (string.byte(' ')), (string.byte('\t'))
local byte_lt    , byte_gt    = (string.byte('<')) , (string.byte('>'))
local byte_amp   , byte_eq    = (string.byte('&')) , (string.byte('='))
local byte_comma , byte_dot   = (string.byte(',')) , (string.byte('.'))
local byte_zero  , byte_nine  = (string.byte('0')) , (string.byte('9'))
local byte_char_a, byte_char_e, byte_char_f = (string.byte('a')), (string.byte('e')), (string.byte('f'))
local byte_char_l, byte_char_n, byte_char_r = (string.byte('l')), (string.byte('n')), (string.byte('r'))
local byte_char_s, byte_char_t, byte_char_u = (string.byte('s')), (string.byte('t')), (string.byte('u'))

local function bytes2string(bytes)
	local char, insert, concat, unpack = string.char, table.insert, table.concat, X.Unpack
	local count = #bytes
	if count > 100 then
		local t, i = {}, 1
		while i <= count do
			table.insert(t, string.char(unpack(bytes, i, math.min(i + 99, count))))
			i = i + 100
		end
		return table.concat(t)
	else
		return string.char(unpack(bytes))
	end
end

local function IsSpaceCharCode(byte_current)
	return byte_current == byte_space or byte_current == byte_tab
		or byte_current == byte_cr or byte_current == byte_lf
end

local XMLEncodeComponent = EncodeComponentsString
	or function(str)
		local bytes2string, insert, byte = bytes2string, table.insert, string.byte
		local bytes_string, len, byte_current = {}, #str, nil
		for i = 1, len do
			byte_current = string.byte(str, i)
			if byte_current == byte_lf then
				table.insert(bytes_string, byte_escape)
				-- byte_current = byte_char_n
			elseif byte_current == byte_tab then
				table.insert(bytes_string, byte_escape)
				-- byte_current = byte_char_t
			elseif byte_current == byte_escape or byte_current == byte_quote then
				table.insert(bytes_string, byte_escape)
			end
			table.insert(bytes_string, byte_current)
		end
		return bytes2string(bytes_string)
	end

local XMLDecodeComponent = _G.DecodeComponentsString
	or (GetPureText
		and function(str)
			return GetPureText('<text>text=' .. str .. '</text>')
		end)
	or function(str)
		local bytes2string, insert, byte = bytes2string, table.insert, string.byte
		local bytes_string, b_escaping, b_partial_gbk, len, byte_current = {}, false, false, #str, nil
		for i = 2, len - 1 do -- str starts with and ends with quote
			byte_current = string.byte(str, i)
			if b_partial_gbk then
				if byte_current >= 64 and byte_current <= 254 then
					b_partial_gbk = false
				else
					X.OutputDebugMessage('XML decode component error: partial GBK character detected at ' .. i .. ' on `' .. str .. '`', X.DEBUG_LEVEL.LOG)
					return
				end
			elseif X.ENVIRONMENT.CODE_PAGE == X.CODE_PAGE.GBK and byte_current >= 129 and byte_current <= 254 then
				b_partial_gbk = true
			elseif b_escaping then
				b_escaping = false
				-- if byte_current == byte_char_n then
					-- byte_current = byte_lf
				-- elseif byte_current == byte_char_t then
					-- byte_current = byte_tab
				-- else
				if byte_current ~= byte_lf and byte_current ~= byte_escape then
					table.insert(bytes_string, byte_escape)
				end
				table.insert(bytes_string, byte_current)
			elseif byte_current == byte_escape then
				b_escaping = true
			else
				table.insert(bytes_string, byte_current)
			end
		end
		return bytes2string(bytes_string)
	end

local function XMLCreateNode(type)
	return { type = type, attrs = {}, data = {}, children = {} }
end

local function XMLIsNode(node)
	return X.IsTable(node)
		and X.IsString(node.type)
		and X.IsTable(node.attrs)
		and X.IsTable(node.data)
		and X.IsTable(node.children)
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
	local insert, remove, concat, unpack = table.insert, table.remove, table.concat, X.Unpack
	local find, sub, gsub, char, byte = string.find, string.sub, string.gsub, string.char, string.byte
	local t = XMLCreateNode('')
	local p = t
	local p1
	local stack = {}
	local state = 'text'
	local pos, xlen = 1, #xml
	local byte_current
	local pos1, pos2, byte_quoting_char, key, b_escaping, b_partial_gbk
	-- <        label         attribute_key=attribute_value>        text_key=text_value<        /     label         >
	-- label_lt label_opening attribute                    label_gt text               label_lt slash label_closing label_gt
	while pos <= xlen do
		byte_current = string.byte(xml, pos)
		if state == 'text' then
			if byte_current == byte_lt then
				state = 'label_lt'
			elseif not IsSpaceCharCode(byte_current) then
				state = 'text_key'
				pos1 = pos
			end
		elseif state == 'label_lt' then
			if byte_current == byte_slash then
				state = 'label_closing'
				pos1 = pos + 1
			elseif not IsSpaceCharCode(byte_current) then
				state = 'label_opening'
				pos1 = pos
			end
		elseif state == 'label_opening' then
			if byte_current == byte_gt then
				state = 'text'
				p1 = XMLCreateNode(xml:sub(pos1, pos - 1))
				table.insert(stack, p1)
				table.insert(p.children, p1)
				p = p1
			elseif IsSpaceCharCode(byte_current) then
				state = 'attribute'
				p1 = XMLCreateNode(xml:sub(pos1, pos - 1))
				table.insert(stack, p1)
				table.insert(p.children, p1)
				p = p1
			end
		elseif state == 'label_closing' then
			if byte_current == byte_gt then
				state = 'text'
				table.remove(stack)
				p = stack[#stack] or t
			end
		elseif state == 'attribute' then
			if byte_current == byte_gt then
				state = 'text'
			elseif not IsSpaceCharCode(byte_current) then
				state = 'attribute_key'
				pos1 = pos
			end
		elseif state == 'attribute_key' then
			if IsSpaceCharCode(byte_current) then
				key = xml:sub(pos1, pos - 1)
				state = 'attribute_key_end'
			elseif byte_current == byte_eq then
				key = xml:sub(pos1, pos - 1)
				state = 'attribute_eq'
			end
		elseif state == 'attribute_key_end' then
			if byte_current == byte_eq then
				state = 'attribute_eq'
			elseif not IsSpaceCharCode(byte_current) then
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
			elseif not IsSpaceCharCode(byte_current) then
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
			if b_partial_gbk then
				if byte_current >= 64 and byte_current <= 254 then
					b_partial_gbk = false
				else
					X.OutputDebugMessage('XML decode error: partial GBK character detected at ' .. pos .. ' on `' .. xml .. '`', X.DEBUG_LEVEL.LOG)
					return
				end
			elseif X.ENVIRONMENT.CODE_PAGE == X.CODE_PAGE.GBK and byte_current >= 129 and byte_current <= 254 then
				b_partial_gbk = true
			elseif b_escaping then
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
				if IsSpaceCharCode(byte_current) then
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
			if IsSpaceCharCode(byte_current) then
				key = xml:sub(pos1, pos - 1)
				state = 'text_key_end'
			elseif byte_current == byte_eq then
				key = xml:sub(pos1, pos - 1)
				state = 'text_eq'
			elseif byte_current == byte_lt then
				key = xml:sub(pos1, pos - 1)
				state = 'text_key_end'
				pos = pos - 1
			end
		elseif state == 'text_key_end' then
			if byte_current == byte_eq then
				state = 'text_eq'
			elseif not IsSpaceCharCode(byte_current) then
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
			elseif not IsSpaceCharCode(byte_current) then
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
			if b_partial_gbk then
				if byte_current >= 64 and byte_current <= 254 then
					b_partial_gbk = false
				else
					X.OutputDebugMessage('XML decode error: partial GBK character detected at ' .. pos .. ' on `' .. xml .. '`', X.DEBUG_LEVEL.LOG)
					return
				end
			elseif X.ENVIRONMENT.CODE_PAGE == X.CODE_PAGE.GBK and byte_current >= 129 and byte_current <= 254 then
				b_partial_gbk = true
			elseif b_escaping then
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
				if IsSpaceCharCode(byte_current) then
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
		X.OutputDebugMessage('XML decode error: unclosed elements detected. ' .. #stack .. ' stacks on `' .. xml .. '`', X.DEBUG_LEVEL.LOG)
		return
	end
	return t.children
end

local function XMLEncode(xml)
	local t = {}
	if XMLIsNode(xml) then
		-- head open
		table.insert(t, '<')
		table.insert(t, xml.type)
		-- attributes
		for k, v in pairs(xml.attrs) do
			table.insert(t, ' ')
			table.insert(t, k)
			table.insert(t, '=')
			if type(v) == 'string' then
				table.insert(t, XMLEncodeComponent(v))
			elseif type(v) == 'boolean' then
				table.insert(t, (( v and 'true' ) or 'false'))
			else
				table.insert(t, tostring(v))
			end
		end
		-- head close
		table.insert(t, '>')
		-- data
		for k, v in pairs(xml.data) do
			table.insert(t, ' ')
			table.insert(t, k)
			table.insert(t, '=')
			if type(v) == 'string' then
				table.insert(t, XMLEncodeComponent(v))
			elseif type(v) == 'boolean' then
				table.insert(t, (( v and 'true' ) or 'false'))
			else
				table.insert(t, tostring(v))
			end
		end
		-- children
		for _, v in ipairs(XMLGetNodeChildren(xml)) do
			table.insert(t, XMLEncode(v))
		end
		-- node close
		table.insert(t, '</')
		table.insert(t, XMLGetNodeType(xml))
		table.insert(t, '>')
	elseif X.IsTable(xml) then
		for _, v in ipairs(xml) do
			table.insert(t, XMLEncode(v))
		end
	end
	return (table.concat(t))
end

local function XMLGetPureText(xml)
	local a = {}
	if XMLIsNode(xml) then
		table.insert(a, XMLGetNodeData(xml, 'text') or '')
		for _, v in ipairs(XMLGetNodeChildren(xml)) do
			table.insert(a, XMLGetPureText(v))
		end
	elseif X.IsTable(xml) then
		for _, v in ipairs(xml) do
			table.insert(a, XMLGetPureText(v))
		end
	end
	return table.concat(a)
end

-- 解析 XML 数据，成功返回数据，失败返回 nil 加错误信息
-- (XMLNode[] | nil) X.XMLDecode(szData: string)
X.XMLDecode = XMLDecode

-- 编码 XML 数据，成功返回 XML 字符串，失败返回 nil
-- (string) X.XMLEncode(xml: XMLNode[] | XMLNode)
X.XMLEncode = XMLEncode

-- 编码 XML 字符串
-- (string) X.XMLEncodeComponent(raw_str: string)
X.XMLEncodeComponent = XMLEncodeComponent

-- 解码 XML 字符串
-- (string) X.XMLDecodeComponent(escaped_str: string)
X.XMLDecodeComponent = XMLDecodeComponent

-- XML 转纯文字
-- (string) X.XMLGetPureText(xml: XMLNode[] | XMLNode)
X.XMLGetPureText = XMLGetPureText

-- 创建 XML 节点
-- (XMLNode) X.XMLCreateNode(type: string)
X.XMLCreateNode = XMLCreateNode

-- 判断是否是 XML 节点
-- (boolean) X.XMLIsNode(xml: XMLNode | any)
X.XMLIsNode = XMLIsNode

-- 获取 XML 节点类型
-- (string) X.XMLGetNodeType(xml: XMLNode)
X.XMLGetNodeType = XMLGetNodeType

-- 获取 XML 节点属性
-- (string | number | boolean) X.XMLGetNodeAttr(xml: XMLNode, key: string)
X.XMLGetNodeAttr = XMLGetNodeAttr

-- 设置 XML 节点属性
-- (void) X.XMLSetNodeAttr(xml: XMLNode, key: string, val: string | number | boolean)
X.XMLSetNodeAttr = XMLSetNodeAttr

-- 获取 XML 节点数据
-- (string | number | boolean) X.XMLGetNodeData(xml: XMLNode, key: string)
X.XMLGetNodeData = XMLGetNodeData

-- 设置 XML 节点数据
-- (void) X.XMLSetNodeData(xml: XMLNode, key: string, val: string | number | boolean)
X.XMLSetNodeData = XMLSetNodeData

-- 获取 XML 子节点列表
-- (XMLNode[]) X.XMLGetNodeChildren(xml: XMLNode)
X.XMLGetNodeChildren = XMLGetNodeChildren

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
