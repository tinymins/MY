--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 各种调试信息输出
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/DebugLogs')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

X.RegisterEvent('OPEN_WINDOW', X.NSFormatString('{$NS}_DebugLogs'), function()
	if not X.IsDebugging() and not X.IsDebugging('Dev_DebugLogs') then
		return
	end
	X.Log('Event: OPEN_WINDOW')
	X.Log('== EVENT ARGS BEGIN ==')
	X.Log(tostring(arg0))
	X.Log(tostring(arg1))
	X.Log('== EVENT ARGS END ==')
end)

X.RegisterEvent('ON_WARNING_MESSAGE', X.NSFormatString('{$NS}_DebugLogs'), function()
	if not X.IsDebugging() and not X.IsDebugging('Dev_DebugLogs') then
		return
	end
	X.Log('Event: ON_WARNING_MESSAGE')
	X.Log('== EVENT ARGS BEGIN ==')
	X.Log(tostring(arg0))
	X.Log(tostring(arg1))
	X.Log('== EVENT ARGS END ==')
end)

X.RegisterMsgMonitor('MSG_NPC_NEARBY', X.NSFormatString('{$NS}_DebugLogs'), function(szChannel, szMsg, nFont, bRich)
	if not X.IsDebugging() and not X.IsDebugging('Dev_DebugLogs') then
		return
	end
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	X.Log('Msg: MSG_NPC_NEARBY')
	X.Log('== MSG INFO BEGIN ==')
	X.Log('Channel: ' .. tostring(szChannel))
	X.Log('Msg: ' .. tostring(szMsg))
	X.Log('== MSG INFO END ==')
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
