--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 常用工具
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
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

do
local TARGET_TYPE, TARGET_ID
local function onHotKey()
	if TARGET_TYPE then
		LIB.SetTarget(TARGET_TYPE, TARGET_ID)
		TARGET_TYPE, TARGET_ID = nil
	else
		TARGET_TYPE, TARGET_ID = LIB.GetTarget()
		LIB.SetTarget(TARGET.PLAYER, UI_GetClientPlayerID())
	end
end
LIB.RegisterHotKey('MY_AutoLoopMeAndTarget', _L['Loop target between me and target'], onHotKey)
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 25, 25
	local W, H = ui:Size()
	local x, y = X, Y
	local deltaY = 28

	-- 目标
	x = X
	y = y + ui:Append('Text', { x = x, y = y, h = 'auto', text = _L['Target'], color = {255, 255, 0} }):Height() + 5
	x = x + 10
	x, y = MY_FooterTip.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)

	-- 战斗
	x = X
	y = y + ui:Append('Text', { x = x, y = y, h = 'auto', text = _L['Battle'], color = {255, 255, 0} }):Height() + 5
	x = x + 10
	x, y = MY_VisualSkill.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_DynamicActionBarPos.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_ArenaHelper.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_ShenxingHelper.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)

	-- 其他
	x = X
	y = y + ui:Append('Text', { x = x, y = y, h = 'auto', text = _L['Others'], color = {255, 255, 0} }):Height() + 5
	x = x + 10
	x, y = MY_AchievementWiki.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_PetWiki.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_YunMacro.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_ItemWiki.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_ItemPrice.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)

	x, y = X + 10, y + deltaY
	if MY_BagEx then
		x, y = MY_BagEx.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	end
	if MY_BagSort then
		x, y = MY_BagSort.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	end
	x, y = MY_HideAnnounceBg.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_FriendTipLocation.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)

	x, y = X + 10, y + deltaY
	x, y = MY_Domesticate.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)
	x, y = MY_Memo.OnPanelActivePartial(ui, X + 10, Y, W, H, x, y, deltaY)

	-- 右侧浮动
	MY_GongzhanCheck.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	MY_LockFrame.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	MY_AutoSell.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	MY_DynamicItem.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
end
LIB.RegisterPanel(_L['General'], 'MY_ToolBox', _L['MY_ToolBox'], 'UI/Image/Common/Money.UITex|243', PS)
