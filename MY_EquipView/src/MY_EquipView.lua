--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 我的装备一览
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local ipairs_r = LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local EQUIPMENT_SUIT_COUNT = LIB.EQUIPMENT_SUIT_COUNT
------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_EquipView/lang/')
if not LIB.AssertVersion('MY_EquipView', _L['MY_EquipView'], 0x2011800) then
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
LIB.RegisterEvent('BAG_ITEM_UPDATE', _C.UpdateAllEquipBox)

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

LIB.RegisterPanel('MY_EquipView', _L['equip view'], _L['General'], 'ui/Image/UICommon/CommonPanel7.UITex|23', _C.PS)
