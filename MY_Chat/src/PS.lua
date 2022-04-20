--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local MODULE_NAME = 'MY_Chat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
	return
end
--------------------------------------------------------------------------

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local W, H = ui:Size()
	local nPaddingX, nPaddingY = 20, 20
	local x, y = nPaddingX, nPaddingY
	local lineHeight = 29

	if MY_Farbnamen and MY_Farbnamen.OnPanelActivePartial then
		x, y = MY_Farbnamen.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
	end
	x, y = MY_ChatSwitch.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
	x, y = MY_TeamBalloon.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
	x, y = MY_ChatCopy.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
	x, y = MY_AutoHideChat.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
	x, y = MY_WhisperMetion.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
	x, y = MY_ChatEmotion.OnPanelActivePartial(ui, nPaddingX, nPaddingY, W, H, x, y, lineHeight)
end
X.RegisterPanel(_L['Chat'], 'MY_ChatSwitch', _L['chat helper'], 'UI/Image/UICommon/ActivePopularize2.UITex|20', PS)
