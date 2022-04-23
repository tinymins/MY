--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录 系统拍团拾取界面HOOK
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
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {}

function D.OnGoldTeamLootListItemRButtonClick()
	local tData = this:GetParent().tData
	if not tData then
		return
	end
	local d = GetDoodad(tData.dwDoodadID)
	if not d then
		return
	end
	local data = MY_GKPLoot.GetItemData(GetClientPlayer(), d, tData.nLootIndex)
	if not data then
		return
	end
	UI.PopupMenu(MY_GKPLoot.GetItemBiddingMenu(tData.dwDoodadID, data))
end

function D.HookGoldTeamLootList()
	local h = Station.Lookup('Normal/GoldTeamLootList/WndScroll_LootList', 'Handle_LootList')
	if not h then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		local hItem = h:Lookup(i)
		local hBtn = hItem and hItem:Lookup('Handle_Btn_Bid')
		if hBtn then
			hBtn:RegisterEvent(42)
			hBtn.OnItemRButtonClick = D.OnGoldTeamLootListItemRButtonClick
		end
	end
	if not h.__FormatAllItemPos then
		h.__FormatAllItemPos = h.FormatAllItemPos
		h.FormatAllItemPos = function()
			h:__FormatAllItemPos()
			D.HookGoldTeamLootList()
		end
	end
end
X.RegisterFrameCreate('GoldTeamLootList', 'MY_GKPGoldTeamLootHook', D.HookGoldTeamLootList)

function D.UnhookGoldTeamLootList()
	local h = Station.Lookup('Normal/GoldTeamLootList/WndScroll_LootList', 'Handle_LootList')
	if not h then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		local hItem = h:Lookup(i)
		local hBtn = hItem and hItem:Lookup('Handle_Btn_Bid')
		if hBtn then
			hBtn.OnItemRButtonClick = nil
		end
	end
	if h.__FormatAllItemPos then
		h.FormatAllItemPos = h.__FormatAllItemPos
		h.__FormatAllItemPos = nil
	end
end
X.RegisterReload('MY_GKPGoldTeamLootHook', D.UnhookGoldTeamLootList)
