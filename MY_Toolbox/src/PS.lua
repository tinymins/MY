--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 常用工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
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
	local X, Y = 20, 20
	local W, H = ui:Size()
	local x, y = X, Y
	x, y = MY_GongzhanCheck.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_FooterTip.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	if MY_BagEx then
		x, y = MY_BagEx.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	end
	if MY_BagSort then
		x, y = MY_BagSort.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	end
	x, y = MY_VisualSkill.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_ShenxingHelper.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_AutoHideChat.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_WhisperMetion.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_ArenaHelper.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_ChangGeShadow.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_Memo.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_HideAnnounceBg.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_EnergyBar.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_AchievementWiki.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_LockFrame.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x, y = MY_AutoSell.OnPanelActivePartial(ui, X, Y, W, H, x, y)
end
LIB.RegisterPanel('MY_ToolBox', _L['toolbox'], _L['General'], 'UI/Image/Common/Money.UITex|243', PS)
