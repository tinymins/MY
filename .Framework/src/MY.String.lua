--------------------------------------------
-- @Desc  : ������� - �ַ�������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2015-01-25 15:35:26
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-05-22 15:53:57
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
--------------------------------------------
-- ���غ����ͱ���
--------------------------------------------
MY = MY or {}
MY.String = MY.String or {}

-- �ָ��ַ���
-- (table) MY.String.Split(string szText, string szSpliter)
MY.String.Split = function(szText, szSep)
	local nOff, tResult = 1, {}
	while true do
		local nEnd = StringFindW(szText, szSep, nOff)
		if not nEnd then
			table.insert(tResult, string.sub(szText, nOff, string.len(szText)))
			break
		else
			table.insert(tResult, string.sub(szText, nOff, nEnd - 1))
			nOff = nEnd + string.len(szSep)
		end
	end
	return tResult
end

-- ת��������ʽ�����ַ�
-- (string) MY.String.PatternEscape(string szText)
MY.String.PatternEscape = function(s) return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')) end

-- ����ַ�����β�Ŀհ��ַ�
-- (string) MY.String.Trim(string szText)
MY.String.Trim = function(szText)
	if not szText or szText == "" then
		return ""
	end
	return (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
end

-- ת��Ϊ URL ����
-- (string) MY.String.UrlEncode(string szText)
MY.String.UrlEncode = function(szText)
	return szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end):gsub(" ", "+")
end

-- ���� URL ����
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
	-- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������;��ս
	local bKeyWordsLine = false
	for _, szKeyWordsLine in ipairs( MY.String.Split(szFind, ';') ) do         -- ����һ������
		-- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������
		local bKeyWords = true
		for _, szKeyWords in ipairs( MY.String.Split(szKeyWordsLine, ',') ) do -- ����ȫ������
			-- 10|ʮ��
			local bKeyWord = false
			for _, szKeyWord in ipairs( MY.String.Split(szKeyWords, '|') ) do  -- ����һ������
				-- szKeyWord = MY.String.PatternEscape(szKeyWord) -- ����wstring��Escape���ݱ�
				if string.sub(szKeyWord, 1, 1) == "!" then                     -- !С��������
					szKeyWord = string.sub(szKeyWord, 2)
					if not wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				else                                                           -- ʮ��   -- 10
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
