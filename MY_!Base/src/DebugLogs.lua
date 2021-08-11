--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 各种调试信息输出
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------

X.RegisterEvent('OPEN_WINDOW', X.NSFormatString('{$NS}_DebugLogs'), function()
	if not X.IsDebugClient(true) then
		return
	end
	Log('Event: OPEN_WINDOW')
	Log('== EVENT ARGS BEGIN ==')
	Log(tostring(arg0))
	Log(tostring(arg1))
	Log('== EVENT ARGS END ==')
end)

X.RegisterEvent('ON_WARNING_MESSAGE', X.NSFormatString('{$NS}_DebugLogs'), function()
	if not X.IsDebugClient(true) then
		return
	end
	Log('Event: ON_WARNING_MESSAGE')
	Log('== EVENT ARGS BEGIN ==')
	Log(tostring(arg0))
	Log(tostring(arg1))
	Log('== EVENT ARGS END ==')
end)

X.RegisterMsgMonitor('MSG_NPC_NEARBY', X.NSFormatString('{$NS}_DebugLogs'), function(szChannel, szMsg, nFont, bRich)
	if not X.IsDebugClient(true) then
		return
	end
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	Log('Msg: MSG_NPC_NEARBY')
	Log('== MSG INFO BEGIN ==')
	Log('Channel: ' .. tostring(szChannel))
	Log('Msg: ' .. tostring(szMsg))
	Log('== MSG INFO END ==')
end)
