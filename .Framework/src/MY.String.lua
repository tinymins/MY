---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
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
    local str = szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = str:gsub(" ", "+")
    return str
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