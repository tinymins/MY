--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 基础库加载完成处理
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PROXY = {}
if IsDebugClient() then
function PROXY.DebugSetVal(szKey, oVal)
	PROXY[szKey] = oVal
end
end

for k, v in pairs(X) do
	PROXY[k] = v
	X[k] = nil
end
setmetatable(X, {
	__metatable = true,
	__index = PROXY,
	__newindex = function() assert(false, X.NSFormatString('DO NOT modify {$NS} after initialized!!!')) end,
	__tostring = function(t) return X.NSFormatString('{$NS} (base library)') end,
})
FireUIEvent(X.NSFormatString('{$NS}_BASE_LOADING_END'))

X.RegisterInit(X.NSFormatString('{$NS}#AUTHOR_TIP'), function()
	local Farbnamen = _G.MY_Farbnamen
	if Farbnamen and Farbnamen.RegisterHeader then
		for dwID, szName in X.pairs_c(X.PACKET_INFO.AUTHOR_ROLES) do
			Farbnamen.RegisterHeader(szName, dwID, X.PACKET_INFO.AUTHOR_HEADER)
		end
		for szName, _ in X.pairs_c(X.PACKET_INFO.AUTHOR_PROTECT_NAMES) do
			Farbnamen.RegisterHeader(szName, '*', X.PACKET_INFO.AUTHOR_FAKE_HEADER)
		end
	end
end)
