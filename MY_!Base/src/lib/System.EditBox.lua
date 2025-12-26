--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·聊天框
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.EditBox')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.EditBox_AppendLinkPlayer(szName)
	local edit = X.GetChatInput()
	edit:InsertObj('['.. szName ..']', { type = 'name', text = '['.. szName ..']', name = szName })
	Station.SetFocusWindow(edit)
	return true
end

function X.EditBox_AppendLinkItem(dwID)
	local item = GetItem(dwID)
	if not item then
		return false
	end
	local szName = '[' .. X.GetItemNameByItem(item) ..']'
	local edit = X.GetChatInput()
	edit:InsertObj(szName, { type = 'item', text = szName, item = item.dwID })
	Station.SetFocusWindow(edit)
	return true
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
