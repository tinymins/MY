--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���ż�¼ ϵͳ����ʰȡ����HOOK
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
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
	local data = MY_GKP_Loot.GetItemData(GetClientPlayer(), d, tData.nLootIndex)
	if not data then
		return
	end
	UI.PopupMenu(MY_GKP_Loot.GetItemBiddingMenu(tData.dwDoodadID, data))
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
LIB.RegisterFrameCreate('GoldTeamLootList.MY_GKPGoldTeamLootHook', D.HookGoldTeamLootList)

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
LIB.RegisterReload('MY_GKPGoldTeamLootHook', D.UnhookGoldTeamLootList)