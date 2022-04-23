--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌì¸¨Öú
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatCopy'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------

if RegisterMsgHook then
	RegisterMsgHook(
		function(szMsg, nFont, bRich, r, g, b, szType, dwTalkerID, szName)
			if not bRich then
				szMsg = GetFormatText(szMsg, nFont, r, g, b)
				bRich = true
			end
			szMsg = '<null name="MY_Chat::'
				.. GetCurrentTime()
				.. '/' .. (nFont or '') .. '/' .. (r or '') .. '/' .. (g or '') .. '/' .. (b or '')
				.. '/' .. (szType or '') .. '/' .. (dwTalkerID or '') .. '/' .. (szName or '')
				.. '" lockshowhide=1></null>'
				.. szMsg
			return szMsg, nFont, bRich, r, g, b
		end,
		X.Clone(CONSTANT.MSG_TYPE_LIST)
	)
end

local function ParseMessageInfo(...)
	local szInfo
	if X.IsElement((...)) then
		local h, i, j = ...
		for i = i, j do
			local el = h:Lookup(i)
			if el:GetType() == 'Null' and el:GetName():find('^MY_Chat::.+$') then
				szInfo = el:GetName():sub(10)
				break
			end
		end
	elseif X.IsString((...)) then
		local szMsg = ...
		local i, j = szMsg:find('"MY_Chat::[^"]+"')
		if i then
			szInfo = szMsg:sub(i + 1, j - 1)
		end
	end
	if szInfo then
		local aInfo = X.SplitString(szInfo, '/')
		local tInfo = {
			dwTime       = tonumber(aInfo[1]),
			nFont        = tonumber(aInfo[2]),
			nR           = tonumber(aInfo[3]),
			nG           = tonumber(aInfo[4]),
			nB           = tonumber(aInfo[5]),
			szChannel    = aInfo[6]          ,
			dwTalkerID   = tonumber(aInfo[7]),
			szTalkerName = aInfo[8]          ,
		}
		Log(X.EncodeLUAData(tInfo))
		return tInfo
	end
end

-- Global exports
do
local settings = {
	name = 'MY_Chat',
	exports = {
		{
			fields = {
				ParseMessageInfo = ParseMessageInfo,
			},
		},
	},
}
MY_Chat = X.CreateModule(settings)
end
