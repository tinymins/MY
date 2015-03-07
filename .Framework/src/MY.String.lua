--------------------------------------------
-- @Desc  : 茗伊插件 - 字符串处理
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2015-01-25 15:35:26
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-03-07 13:11:25
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
--------------------------------------------
-- 本地函数和变量
--------------------------------------------
MY = MY or {}
MY.String = MY.String or {}

-- 分隔字符串
-- (table) MY.String.Split(string szText, string szSpliter)
MY.String.Split = function(s, p)
	local rt= {}
	string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
	return rt
end

-- 转义正则表达式特殊字符
-- (string) MY.String.PatternEscape(string szText)
MY.String.PatternEscape = function(s) return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')) end

-- 清除字符串首尾的空白字符
-- (string) MY.String.Trim(string szText)
MY.String.Trim = function(szText)
	if not szText or szText == "" then
		return ""
	end
	return (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
end

-- 转换为 URL 编码
-- (string) MY.String.UrlEncode(string szText)
MY.String.UrlEncode = function(szText)
	return szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end):gsub(" ", "+")
end

-- 解析 URL 编码
-- (string) MY.String.UrlDecode(string szText)
MY.String.UrlDecode = function(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end

MY.String.LenW = function(str)
	return wstring.len(str)
end

MY.String.SubW = function(str,s,e)
	if s < 0 then
		s = wstring.len(str) + s
	end
	if e < 0 then
		e = wstring.len(str) + e
	end
	return wstring.sub(str, s, e)
end

MY.String.SimpleEcrypt = function(szText)
	return szText:gsub('.', function (c) return string.format ("%02X", (string.byte(c) + 13) % 256) end):gsub(" ", "+")
end

MY.String.SimpleMatch = function(szText, szFind, bDistinctCase)
	if not bDistinctCase then
		szFind = StringLowerW(szFind)
		szText = StringLowerW(szText)
	end
	-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
	local bKeyWordsLine = false
	for _, szKeyWordsLine in ipairs( MY.String.Split(szFind, ';') ) do         -- 符合一个即可
		-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
		local bKeyWords = true
		for _, szKeyWords in ipairs( MY.String.Split(szKeyWordsLine, ',') ) do -- 必须全部符合
			-- 10|十人
			local bKeyWord = false
			for _, szKeyWord in ipairs( MY.String.Split(szKeyWords, '|') ) do  -- 符合一个即可
				szKeyWord = MY.String.PatternEscape(szKeyWord)
				if string.sub(szKeyWord, 1, 1) == "!" then                     -- !小铁被吃了
					szKeyWord = string.sub(szKeyWord, 2)
					if not wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				else                                                           -- 十人   -- 10
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
