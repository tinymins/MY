--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 基础库加载完成处理
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/LoadingEnd')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local PROXY = X.NSLock(X, X.NSFormatString('{$NS} (base library)'))
if IsDebugClient() then
function PROXY.DebugSetVal(szKey, oVal)
	PROXY[szKey] = oVal
end
end
FireUIEvent(X.NSFormatString('{$NS}_BASE_LOADING_END'))

X.RegisterInit(X.NSFormatString('{$NS}#AUTHOR_TIP'), function()
	local Farbnamen = _G.MY_Farbnamen
	if not Farbnamen then
		return
	end
	if Farbnamen.RegisterNameIDHeader then
		for dwID, szName in X.pairs_c(X.PACKET_INFO.AUTHOR_ROLES) do
			Farbnamen.RegisterNameIDHeader(szName, dwID, X.PACKET_INFO.AUTHOR_HEADER)
		end
		for szName, _ in X.pairs_c(X.PACKET_INFO.AUTHOR_PROTECT_NAMES) do
			Farbnamen.RegisterNameIDHeader(szName, '*', X.PACKET_INFO.AUTHOR_FAKE_HEADER)
		end
	end
	if Farbnamen.RegisterGlobalIDHeader then
		for szGlobalID, _ in X.pairs_c(X.PACKET_INFO.AUTHOR_GLOBAL_IDS) do
			Farbnamen.RegisterGlobalIDHeader(szGlobalID, X.PACKET_INFO.AUTHOR_HEADER)
		end
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
