---------------------------------------------------------
-- Simple JX3 XML decoding and encoding in pure Lua.
---------------------------------------------------------
-- @author 翟一鸣 @tinymins
-- @refer http://zhaiyiming.com/
---------------------------------------------------------
-- local lua_value = MY.Xml.Decode(raw_xml_text)
-- local raw_xml_text = MY.Xml.Encode(lua_table_or_value)
---------------------------------------------------------
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat

local xmlDecode = function(xml)
	local function str2var(str)
		if str == "true" then
			return true
		elseif str == "false" then
			return false
		elseif tonumber(str) then
			return tonumber(str)
		end
	end
	local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
	local find, sub, gsub, char, byte = string.find, string.sub, string.gsub, string.char, string.byte
	local function bytes2string(bytes)
		local count = #bytes
		if count > 100 then
			local t, i = {}, 1
			while i < count do
				tinsert(char(unpack(bytes, i, i + 100)))
				i = i + 100
			end
			return tconcat(t)
		else
			return char(unpack(bytes))
		end
	end
	local t = {}
	local p = t
	local p1
	local stack = {}
	local state = "text"
	local unpack = unpack or table.unpack
	local pos, len = 1, #xml
	local byte_current
	local byte_apos, byte_quot, byte_escape, byte_slash = (byte("'")) , (byte('"')), (byte("\\")), (byte("/"))
	local byte_lt, byte_gt, byte_amp, byte_eq, byte_space = (byte("<")), (byte(">")), (byte("&")), (byte("=")), (byte(" "))
	local byte_char_n, byte_char_t, byte_lf, byte_tab = (byte("n")), (byte("t")), (byte("\n")), (byte("\t"))
	local pos1, pos2, byte_quote, key, b_escaping, bytes_string
	-- <        label         attribute_key=attribute_value>        text_key=text_value<        /     label         >       
	-- label_lt label_opening attribute                    label_gt text               label_lt slash label_closing label_gt
	while pos <= len do
		byte_current = byte(xml, pos)
		if state == "text" then
			if byte_current == byte_lt then
				state = "label_lt"
			elseif byte_current ~= byte_space then
				state = "text_key"
				pos1 = pos
			end
		elseif state == "label_lt" then
			if byte_current == byte_slash then
				state = "label_closing"
			elseif byte_current ~= byte_space then
				state = "label_opening"
				pos1 = pos
			end
		elseif state == "label_opening" then
			if byte_current == byte_gt then
				state = "text"
				p1 = { ["."] = xml:sub(pos1, pos - 1), [''] = {} }
				tinsert(stack, p1)
				tinsert(p, p1)
				p = p1
			elseif byte_current == byte_space then
				state = "attribute"
				p1 = { ["."] = xml:sub(pos1, pos - 1), [''] = {} }
				tinsert(stack, p1)
				tinsert(p, p1)
				p = p1
			end
		elseif state == "label_closing" then
			if byte_current == byte_gt then
				state = "text"
				tremove(stack)
				p = stack[#stack] or t
			end
		elseif state == "attribute" then
			if byte_current == byte_gt then
				state = "text"
			elseif byte_current ~= byte_space then
				state = "attribute_key"
				pos1 = pos
			end
		elseif state == "attribute_key" then
			if byte_current == byte_space then
				key = xml:sub(pos1, pos - 1)
				state = "attribute_key_end"
			elseif byte_current == byte_eq then
				key = xml:sub(pos1, pos - 1)
				state = "attribute_eq"
			end
		elseif state == "attribute_key_end" then
			if byte_current == byte_eq then
				state = "attribute_eq"
			elseif byte_current ~= byte_space then
				state = "attribute"
				p[key] = key
				pos = pos - 1
			end
		elseif state == "attribute_eq" then
			if byte_current == byte_apos
			or byte_current == byte_quot then
				byte_quote = byte_current
				state = "attribute_value_string"
				bytes_string = {}
				pos1 = pos + 1
			elseif byte_current ~= byte_space then
				state = "attribute_value"
				pos1 = pos
			end
		elseif state == "attribute_value_string" then
			if b_escaping then
				b_escaping = false
				if byte_current == byte_char_n then
					byte_current = byte_lf
				elseif byte_current == byte_char_t then
					byte_current = byte_tab
				end
				tinsert(bytes_string, byte_current)
			elseif byte_current == byte_escape then
				b_escaping = true
			elseif byte_current == byte_quote then
				p[key] = bytes2string(bytes_string)
				state = "attribute"
			else
				tinsert(bytes_string, byte_current)
			end
		elseif state == "attribute_value" then
			if byte_current == byte_space then
				p[key] = str2var(xml:sub(pos1, pos))
				state = "attribute"
			elseif byte_current == byte_gt then
				p[key] = str2var(xml:sub(pos1, pos - 1))
				state = "text"
			end
		elseif state == "text_key" then
			if byte_current == byte_space then
				key = xml:sub(pos1, pos - 1)
				state = "text_key_end"
			elseif byte_current == byte_eq then
				key = xml:sub(pos1, pos - 1)
				state = "text_eq"
			end
		elseif state == "text_key_end" then
			if byte_current == byte_eq then
				state = "text_eq"
			elseif byte_current ~= byte_space then
				state = "text"
				p[key][''] = key
				pos = pos - 1
			end
		elseif state == "text_eq" then
			if byte_current == byte_apos
			or byte_current == byte_quot then
				byte_quote = byte_current
				state = "text_value_string"
				bytes_string = {}
				pos1 = pos + 1
			elseif byte_current ~= byte_space then
				state = "text_value"
				pos1 = pos
			end
		elseif state == "text_value_string" then
			if b_escaping then
				b_escaping = false
				if byte_current == byte_char_n then
					byte_current = byte_lf
				elseif byte_current == byte_char_t then
					byte_current = byte_tab
				end
				tinsert(bytes_string, byte_current)
			elseif byte_current == byte_escape then
				b_escaping = true
			elseif byte_current == byte_quote then
				p[''][key] = bytes2string(bytes_string)
				state = "text"
			else
				tinsert(bytes_string, byte_current)
			end
		elseif state == "text_value" then
			if byte_current == byte_space then
				p[''][key] = str2var(xml:sub(pos1, pos))
				state = "text"
			elseif byte_current == byte_gt then
				p[''][key] = str2var(xml:sub(pos1, pos - 1))
				state = "text"
			end
		end
		pos = pos + 1
	end
	assert(#stack == 0, "XML decode error: unclosed elements detected.")
	return t
end

local xmlEscape = function(str)
	return (str:gsub('\\', '\\\\'):gsub('"', '\\"'))
end

local bytes2string = function(bytes)
	local char, tinsert, tconcat, unpack = string.char, tinsert, tconcat, unpack
	local count = #bytes
	if count > 100 then
		local t, i = {}, 1
		while i < count do
			tinsert(char(unpack(bytes, i, i + 100)))
			i = i + 100
		end
		return tconcat(t)
	else
		return char(unpack(bytes))
	end
end

local xmlUnescape = function(str)
	local bytes2string, tinsert, byte = bytes2string, tinsert, string.byte
	local bytes_string, b_escaping, len, byte_current = {}, false, #str
	local byte_char_n, byte_char_t, byte_lf, byte_tab, byte_escape = (byte("n")), (byte("t")), (byte("\n")), (byte("\t")), (byte("\\"))
	for i = 1, len do
		byte_current = byte(str, i)
		if b_escaping then
			b_escaping = false
			if byte_current == byte_char_n then
				byte_current = byte_lf
			elseif byte_current == byte_char_t then
				byte_current = byte_tab
			end
			tinsert(bytes_string, byte_current)
		elseif byte_current == byte_escape then
			b_escaping = true
		else
			tinsert(bytes_string, byte_current)
		end
	end
	return bytes2string(bytes_string)
end

local xmlEncode
xmlEncode = function(xml)
	local t = {}
	
	-- head
	if xml['.'] then
		tinsert(t, '<')
		tinsert(t, xml['.'])
		
		-- attributes
		local attr = ''
		for k, v in pairs(xml) do
			if type(k) == 'string' and string.find(k, "^[a-zA-Z0-9_]+$") then
				tinsert(t, ' ')
				tinsert(t, k)
				tinsert(t, '=')
				if type(v) == 'string' then
					tinsert(t, '"')
					tinsert(t, xmlEscape(v))
					tinsert(t, '"')
				elseif type(v) == 'boolean' then
					tinsert(t, (( v and 'true' ) or 'false'))
				else
					tinsert(t, tostring(v))
				end
			end
		end
		
		tinsert(t, '>')
	end
	-- inner attritubes
	local text = ''
	if xml[''] then
		for k, v in pairs(xml['']) do
			tinsert(t, ' ')
			tinsert(t, k)
			tinsert(t, '=')
			if type(v) == 'string' then
				tinsert(t, '"')
				tinsert(t, xmlEscape(v))
				tinsert(t, '"')
			elseif type(v) == 'boolean' then
				tinsert(t, (( v and 'true' ) or 'false'))
			else
				tinsert(t, tostring(v))
			end
		end
	end
	
	-- children
	for _, v in ipairs(xml) do
		tinsert(t, xmlEncode(v))
	end
	
	if xml['.'] then
		tinsert(t, '</')
		tinsert(t, xml['.'])
		tinsert(t, '>')
	end
	
	return (tconcat(t))
end

local xml2Text = function(xml)
	local t = {}
	local xmls = xmlDecode(xml)
	if xmls then
		for _, xml in ipairs(xmls) do
			if xml[''] then
				tinsert(t, xml[''].text)
			end
		end
	end
	return tconcat(t)
end

-- public API
MY = MY or {}
MY.Xml = MY.Xml or {}

-- 解析 XML 数据，成功返回数据，失败返回 nil 加错误信息
-- (mixed) MY.Xml.Decode(string szData)
MY.Xml.Decode = xmlDecode

-- 编码 XML 数据，成功返回 XML 字符串，失败返回 nil
-- (string) MY.Xml.Encode(tData)
-- tData 变量数据，Table保存的XML数据
MY.Xml.Encode = xmlEncode

-- 转义 XML 字符串
-- (string) MY.Xml.Escape(raw_str)
MY.Xml.Escape = xmlEscape

-- 反转义 XML 字符串
-- (string) MY.Xml.Unescape(escaped_str)
MY.Xml.Unescape = xmlUnescape

-- xml转纯文字
MY.Xml.GetPureText = xml2Text
