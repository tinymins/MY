--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·注入
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Hook')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local HOOK = setmetatable({}, { __mode = 'k' })
-- X.SetMemberFunctionHook(tTable, szName, fnHook, tOption) -- hook
-- X.SetMemberFunctionHook(tTable, szName, szKey, fnHook, tOption) -- hook
-- X.SetMemberFunctionHook(tTable, szName, szKey, false) -- unhook
function X.SetMemberFunctionHook(t, xArg1, xArg2, xArg3, xArg4)
	local eAction, szName, szKey, fnHook, tOption
	if X.IsTable(t) and X.IsFunction(xArg2) then
		eAction, szName, fnHook, tOption = 'REG', xArg1, xArg2, xArg3
	elseif X.IsTable(t) and X.IsString(xArg2) and X.IsFunction(xArg3) then
		eAction, szName, szKey, fnHook, tOption = 'REG', xArg1, xArg2, xArg3, xArg4
	elseif X.IsTable(t) and X.IsString(xArg2) and xArg3 == false then
		eAction, szName, szKey = 'UNREG', xArg1, xArg2
	end
	if not eAction then
		assert(false, 'Parameters type not recognized, cannot infer action type.')
	end
	-- 匿名注册分配随机标识符
	if eAction == 'REG' and not X.IsString(szKey) then
		szKey = GetTickCount() * 1000
		while X.Get(HOOK, {t, szName, (tostring(szKey))}) do
			szKey = szKey + 1
		end
		szKey = tostring(szKey)
	end
	if eAction == 'REG' or eAction == 'UNREG' then
		local fnCurrentHook = X.Get(HOOK, {t, szName, szKey})
		if fnCurrentHook then
			X.Set(HOOK, {t, szName, szKey}, nil)
			UnhookTableFunc(t, szName, fnCurrentHook)
		end
	end
	if eAction == 'REG' then
		X.Set(HOOK, {t, szName, szKey}, fnHook)
		HookTableFunc(t, szName, fnHook, tOption)
	end
	return szKey
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
