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
MY.String.Split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end
MY.String.PatternEscape = function(s) return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')) end
MY.String.UrlEncode = function(w)
    pattern="[^%w%d%._%-%* ]"
    local s=string.gsub(w,pattern,function(c)
        local c=string.format("%%%02X",string.byte(c))
        return c
    end)
    s=string.gsub(s," ","+")
    return s
end