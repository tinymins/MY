--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 我的装备一览
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_EquipView'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_EquipView'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local _C = {}

_C.tEquipPos = {
	CONSTANT.EQUIPMENT_INVENTORY.BANGLE       , -- 护臂
	CONSTANT.EQUIPMENT_INVENTORY.CHEST        , -- 上衣
	CONSTANT.EQUIPMENT_INVENTORY.WAIST        , -- 腰带
	CONSTANT.EQUIPMENT_INVENTORY.HELM         , -- 头部
	CONSTANT.EQUIPMENT_INVENTORY.PANTS        , -- 裤子
	CONSTANT.EQUIPMENT_INVENTORY.BOOTS        , -- 鞋子
	CONSTANT.EQUIPMENT_INVENTORY.AMULET       , -- 项链
	CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING    , -- 左手戒指
	CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING   , -- 右手戒指
	CONSTANT.EQUIPMENT_INVENTORY.PENDANT      , -- 腰缀
	CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON , -- 普通近战武器
	CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON , -- 远程武器
	CONSTANT.EQUIPMENT_INVENTORY.ARROW        , -- 暗器
	CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD    , -- 重剑
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
	for i = 0, CONSTANT.EQUIPMENT_SUIT_COUNT - 1 do
		local nSuitIndex, dwBox = _C.GetSuitIndex(me, i)
		for _, nType in ipairs(_C.tEquipPos) do
			local box = ui:Children('#Box_' .. i .. '_' .. nType)[1]
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
		for i = 0, CONSTANT.EQUIPMENT_SUIT_COUNT - 1 do
			for _, nType in ipairs(_C.tEquipPos) do
				ui:Append('Box', 'Box_' .. i .. '_' .. nType)
			end
		end
		_C.PS.OnPanelResize(wnd)
		_C.UpdateAllEquipBox()
	end,
	OnPanelResize = function(wnd) -- correct item pos
		local ui = UI(wnd)
		local w , h  = ui:Size()
		local x0, y0 = 0 , 10
		local x , y  = x0, y0
		local dx, dy, dy2 = 50, 48, 52

		for i = 0, CONSTANT.EQUIPMENT_SUIT_COUNT - 1 do
			for _, nType in ipairs(_C.tEquipPos) do
				if x + dx > w then
					x, y = x0, y + dy
				end
				ui:Children('#Box_' .. i .. '_' .. nType):Pos(x, y)
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
