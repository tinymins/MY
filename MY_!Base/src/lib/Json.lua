--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : Json 处理模块
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Json')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

-- 	X.EncodeJSON = JsonEncode
-- 	X.DecodeJSON = JsonDecode

-- 编码 JSON 数据，成功返回 JSON 字符串，失败返回 nil
-- (string) X.EncodeJSON(vData[, bPretty])
-- vData 变量数据，支持字符串、数字、Table/Userdata
-- bIndent 加缩进美化，默认无
function X.EncodeJSON(vData, bIndent)
	return JsonEncode(vData, bIndent and true or false)
end

-- 解析 JSON 数据，成功返回数据，失败返回 nil 加错误信息和错误堆栈
-- (mixed) X.DecodeJSON(string szData)
function X.DecodeJSON(value)
	local res, err, trace = X.XpCall(JsonDecode, value)
	if res then
		return err
	end
	if X.IsString(err) then
		err = err:gsub('^[^\n]-%.lua%:%d+%: ', '')
	end
	return nil, err, trace
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
