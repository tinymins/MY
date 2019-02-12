--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 我的装备一览
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_EquipView/lang/')
if not MY.AssertVersion('MY_EquipView', _L['MY_EquipView'], 0x2011800) then
	return
end
local _C = {}

_C.tEquipPos = {
	EQUIPMENT_INVENTORY.BANGLE       , -- 护臂
	EQUIPMENT_INVENTORY.CHEST        , -- 上衣
	EQUIPMENT_INVENTORY.WAIST        , -- 腰带
	EQUIPMENT_INVENTORY.HELM         , -- 头部
	EQUIPMENT_INVENTORY.PANTS        , -- 裤子
	EQUIPMENT_INVENTORY.BOOTS        , -- 鞋子
	EQUIPMENT_INVENTORY.AMULET       , -- 项链
	EQUIPMENT_INVENTORY.LEFT_RING    , -- 左手戒指
	EQUIPMENT_INVENTORY.RIGHT_RING   , -- 右手戒指
	EQUIPMENT_INVENTORY.PENDANT      , -- 腰缀
	EQUIPMENT_INVENTORY.MELEE_WEAPON , -- 普通近战武器
	EQUIPMENT_INVENTORY.RANGE_WEAPON , -- 远程武器
	EQUIPMENT_INVENTORY.ARROW        , -- 暗器
	EQUIPMENT_INVENTORY.BIG_SWORD    , -- 重剑
}

_C.GetSuitIndex = function(me, nLogicIndex)
	local nSuitIndex = me.GetEquipIDArray(nLogicIndex)
	local dwBox
	if nSuitIndex == 0 then
		dwBox = INVENTORY_INDEX.EQUIP
	else
		dwBox = INVENTORY_INDEX['EQUIP_BACKUP'..nSuitIndex]
	end
	return nSuitIndex, dwBox
end

_C.UpdateAllEquipBox = function() -- update boxes
	if not _C.wnd then
		return
	end
	local ui = UI(_C.wnd)
	local me = GetClientPlayer()
	for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
		local nSuitIndex, dwBox = _C.GetSuitIndex(me, i)
		for _, nType in ipairs(_C.tEquipPos) do
			local box = ui:children('#Box_' .. i .. '_' .. nType)[1]
			local item = GetPlayerItem(me, dwBox, nType)
			UpdataItemBoxObject(box, dwBox, nType, item, nil, nSuitIndex)
		end
	end
end
MY.RegisterEvent('BAG_ITEM_UPDATE', _C.UpdateAllEquipBox)

_C.PS = {
	OnPanelActive = function(wnd) -- append ui items
		_C.wnd = wnd
		local ui = UI(wnd)
		for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
			for _, nType in ipairs(_C.tEquipPos) do
				ui:append('Box', 'Box_' .. i .. '_' .. nType)
			end
		end
		_C.PS.OnPanelResize(wnd)
		_C.UpdateAllEquipBox()
	end,
	OnPanelResize = function(wnd) -- correct item pos
		local ui = UI(wnd)
		local w , h  = ui:size()
		local x0, y0 = 0 , 10
		local x , y  = x0, y0
		local dx, dy, dy2 = 50, 48, 52

		for i = 0, EQUIPMENT_SUIT_COUNT - 1 do
			for _, nType in ipairs(_C.tEquipPos) do
				if x + dx > w then
					x, y = x0, y + dy
				end
				ui:children('#Box_' .. i .. '_' .. nType):pos(x, y)
				x = x + dx
			end
			x, y = x0, y + dy2
		end
	end,
	OnPanelDeactive = function()
		_C.wnd = nil
	end
}

MY.RegisterPanel('MY_EquipView', _L['equip view'], _L['General'], 'ui/Image/UICommon/CommonPanel7.UITex|23', _C.PS)
