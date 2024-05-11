--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背包助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/PS'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^20.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local PS = { nPriority = 1 }
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 25, 25
	local nW, nH = ui:Size()
	local nX, nY = nPaddingX, nPaddingY
	local nLH = 28

	nX, nY = MY_BagEx_GenericFilters.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nPaddingX
	nY = nY + nLH
	nX, nY = MY_BagEx_Bag.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nPaddingX
	nY = nY + nLH
	nX, nY = MY_BagEx_Bank.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nPaddingX
	nY = nY + nLH
	nX, nY = MY_BagEx_GuildBank.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
end
X.RegisterPanel(_L['General'], 'MY_BagEx', _L['MY_BagEx'], 374, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
