--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·计算符号
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Operator')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.GetOperatorName(szOperator, L)
	return L and L[szOperator] or _L.OPERATOR[szOperator]
end

function X.InsertOperatorMenu(t, szOperator, fnAction, aOperator, L)
	for _, szOp in ipairs(aOperator or { '==', '!=', '<', '>=', '>', '<=' }) do
		table.insert(t, {
			szOption = L and L[szOp] or _L.OPERATOR[szOp],
			bCheck = true, bMCheck = true,
			bChecked = szOperator == szOp,
			fnAction = function() fnAction(szOp) end,
		})
	end
	return t
end

function X.JudgeOperator(szOperator, dwLeftValue, dwRightValue)
	if szOperator == '>' then
		return dwLeftValue > dwRightValue
	elseif szOperator == '>=' then
		return dwLeftValue >= dwRightValue
	elseif szOperator == '<' then
		return dwLeftValue < dwRightValue
	elseif szOperator == '<=' then
		return dwLeftValue <= dwRightValue
	elseif szOperator == '=' or szOperator == '==' or szOperator == '===' then
		return dwLeftValue == dwRightValue
	elseif szOperator == '<>' or szOperator == '~=' or szOperator == '!=' or szOperator == '!==' then
		return dwLeftValue ~= dwRightValue
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
