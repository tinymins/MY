--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·错误日志
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.ErrorCollect')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local FILE_PATH = {'temporary/lua_error.jx3dat', X.PATH_TYPE.GLOBAL}
local LAST_ERROR_MSG = X.LoadLUAData(FILE_PATH, { passphrase = false }) or {}
local ERROR_MSG = {}

if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
	local KEY = '/' .. X.StringReplaceW(X.PACKET_INFO.ROOT, '\\', '/'):gsub('/+$', ''):gsub('^.*/', ''):lower() .. '/'
	local function SaveErrorMessage()
		X.SaveLUAData(FILE_PATH, ERROR_MSG, { encoder = 'luatext', passphrase = false, crc = false, indent = '\t' })
	end
	local BROKEN_KGUI = IsDebugClient() and not X.IsDebugServer() and not X.IsDebugClient(true)
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
			table.insert(ERROR_MSG, szMsg)
		end
		SaveErrorMessage()
	end)
	X.RegisterInit('LIB#AddonErrorMessage', SaveErrorMessage)
end

function X.GetAddonErrorMessage()
	local szMsg = table.concat(LAST_ERROR_MSG, '\n\n')
	if not X.IsEmpty(szMsg) then
		szMsg = szMsg .. '\n\n'
	end
	return szMsg .. table.concat(ERROR_MSG, '\n\n')
end

function X.GetAddonErrorMessageFilePath()
	return X.FormatPath(FILE_PATH)
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
