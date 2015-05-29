--------------------------------------------
-- @Desc  : 茗伊插件 - 字符串处理
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2015-01-25 15:35:26
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-05-29 10:06:20
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
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
MY.String.Split = function(szText, szSep, bIgnoreEmptyPart)
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
	local me = GetClientPlayer()
	if me then
		szFind = szFind:gsub("$zj", GetClientPlayer().szName)
		local szTongName = ""
		local tong = GetTongClient()
		if tong and me.dwTongID ~= 0 then
			szTongName = tong.ApplyGetTongName(me.dwTongID) or ""
		end
		szFind = szFind:gsub("$gh", szTongName)
	end
	-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
	local bKeyWordsLine = false
	for _, szKeyWordsLine in ipairs( MY.String.Split(szFind, ';', true) ) do         -- 符合一个即可
		-- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
		local bKeyWords = true
		for _, szKeyWords in ipairs( MY.String.Split(szKeyWordsLine, ',', true) ) do -- 必须全部符合
			-- 10|十人
			local bKeyWord = false
			for _, szKeyWord in ipairs( MY.String.Split(szKeyWords, '|', true) ) do  -- 符合一个即可
				-- szKeyWord = MY.String.PatternEscape(szKeyWord) -- 用了wstring还Escape个捷豹
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
