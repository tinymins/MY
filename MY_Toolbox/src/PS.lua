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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
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

local PS = { nPriority = 0 }
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local nPaddingX, nPaddingY = 25, 25
	local nW, nH = ui:Size()
	local nX, nY = nPaddingX, nPaddingY
	local nLH = 28

	-- 目标
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, h = 'auto', text = _L['Target'], color = {255, 255, 0} }):Height() + 5
	nX = nX + 10
	nX, nY = MY_FooterTip.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	-- 战斗
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, h = 'auto', text = _L['Battle'], color = {255, 255, 0} }):Height() + 5
	nX = nX + 10
	nX, nY = MY_VisualSkill.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_DynamicActionBarPos.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_ArenaHelper.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_ShenxingHelper.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	-- 其他
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, h = 'auto', text = _L['Others'], color = {255, 255, 0} }):Height() + 5
	nX = nX + 10
	nX, nY = MY_AchievementWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_PetWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_YunMacro.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_ItemWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_ItemPrice.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = nPaddingX + 10, nY + nLH
	if MY_BagEx then
		nX, nY = MY_BagEx.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	end
	if MY_BagSort then
		nX, nY = MY_BagSort.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	end
	nX, nY = MY_HideAnnounceBg.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_FriendTipLocation.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_Domesticate.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_Memo.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = MY_AutoSell.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = nPaddingX + 10, nY + nLH

	-- 右侧浮动
	MY_GongzhanCheck.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	MY_LockFrame.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	MY_DynamicItem.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
end
LIB.RegisterPanel(_L['General'], 'MY_Toolbox', _L['MY_Toolbox'], 134, PS)
