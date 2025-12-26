--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·错误日志
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.ErrorCollect')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local ERROR_FILE = X.FormatPath({'temporary/lua_error.jx3dat', X.PATH_TYPE.GLOBAL})
local ERROR_LIST = X.LoadLUAData(ERROR_FILE, { passphrase = false })
local MAX_MSG_COUNT = 30

if not (X.IsTable(ERROR_LIST) and ERROR_LIST.VERSION == 1) then
	ERROR_LIST = { VERSION = 1 }
end

if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
	local KEY = '/' .. X.StringReplaceW(X.PACKET_INFO.ROOT, '\\', '/'):gsub('/+$', ''):gsub('^.*/', ''):lower() .. '/'
	local function SaveErrorMessage()
		X.SaveLUAData(ERROR_FILE, ERROR_LIST, {
			encoder = 'luatext',
			passphrase = false,
			crc = false,
			indent = '\t',
		})
	end
	local BROKEN_KGUI = IsDebugClient() and not X.IsDebugServer() and not X.IsDebugging()
	local BROKEN_KGUI_ECHO = false
	RegisterEvent('CALL_LUA_ERROR', function()
		if BROKEN_KGUI_ECHO then
			return
		end
		local szMsg = arg0
		local szMsgL = X.StringReplaceW(arg0:lower(), '\\', '/')
		if X.StringFindW(szMsgL, KEY) then
			if BROKEN_KGUI then
				local szMessage = 'Your KGUI is not official, please fix client and try again.'
				BROKEN_KGUI_ECHO = true
				X.SafeCall(X.ErrorLog, '[' .. X.PACKET_INFO.NAME_SPACE .. ']' .. szMessage .. '\n' .. _L[szMessage])
				BROKEN_KGUI_ECHO = false
			end
			X.Log('CALL_LUA_ERROR', szMsg)
			local tError = {}
			for i, v in ipairs(ERROR_LIST) do
				if v.szMsg == szMsg then
					tError = table.remove(ERROR_LIST, i)
				end
			end
			tError.szMsg = szMsg
			tError.nCount = (tError.nCount or 0) + 1
			tError.szTime = X.FormatTime(GetCurrentTime(), '%yyyy/%MM/%dd %hh:%mm:%ss')
			for i = #ERROR_LIST, MAX_MSG_COUNT do
				table.remove(ERROR_LIST, 1)
			end
			table.insert(ERROR_LIST, tError)
		end
		SaveErrorMessage()
	end)
	X.RegisterInit('LIB#AddonErrorMessage', SaveErrorMessage)
end

function X.GetAddonErrorMessage()
	local aMsg = {}
	for _, v in X.ipairs_r(ERROR_LIST) do
		table.insert(aMsg,  v.szTime .. ' x' .. v.nCount .. '\n' .. v.szMsg)
	end
	return table.concat(aMsg, '\n\n')
end

function X.GetAddonErrorMessageFilePath()
	return ERROR_FILE
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
