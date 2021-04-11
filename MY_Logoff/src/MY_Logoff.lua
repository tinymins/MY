--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 快速登出 指定条件退队/下线
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Logoff'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Logoff'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

MY_Logoff = {}
MY_Logoff.bIdleOff = false
MY_Logoff.nIdleOffTime = 30
RegisterCustomData('MY_Logoff.bIdleOff')
RegisterCustomData('MY_Logoff.nIdleOffTime')

local function Logoff(bCompletely, bUnfight, bNotDead)
	if LIB.BreatheCall('MY_LOGOFF') then
		LIB.BreatheCall('MY_LOGOFF', false)
		LIB.Sysmsg(_L['Logoff has been cancelled.'])
		return
	end
	local function onBreatheCall()
		local me = GetClientPlayer()
		if not me then
			return
		end
		if bUnfight and me.bFightState then
			return
		end
		if bNotDead and me.nMoveState == MOVE_STATE.ON_DEATH then
			return
		end
		LIB.Logout(bCompletely)
	end
	onBreatheCall()
	if bUnfight then
		LIB.Sysmsg(_L['Logoff is ready for your casting unfight skill.'])
	end
	LIB.BreatheCall('MY_LOGOFF', onBreatheCall)
end

local function IdleOff()
	if not MY_Logoff.bIdleOff then
		if LIB.BreatheCall('MY_LOGOFF_IDLE') then
			LIB.Sysmsg(_L['Idle off has been cancelled.'])
			LIB.BreatheCall('MY_LOGOFF_IDLE', false)
		end
		return
	end
	if LIB.BreatheCall('MY_LOGOFF_IDLE') then
		return
	end
	local function onBreatheCall()
		local nIdleTime = (Station.GetIdleTime()) / 1000 - 300
		local remainTime = MY_Logoff.nIdleOffTime * 60 - nIdleTime
		if remainTime <= 0 then
			return LIB.Logout(true)
		end
		if remainTime > 1200 and remainTime % 600 ~= 0 then
			return
		end
		if remainTime > 300 and remainTime % 300 ~= 0 then
			return
		end
		if remainTime > 10 and remainTime % 10 ~= 0 then
			return
		end
		if remainTime <= 60 then
			local szMessage = _L('Idle off notice: you\'ll auto logoff if you keep idle for %ds.', remainTime)
			if remainTime <= 10 then
				OutputMessage('MSG_ANNOUNCE_YELLOW', szMessage)
			end
			LIB.Sysmsg(szMessage)
		else
			LIB.Sysmsg(_L('Idle off notice: you\'ll auto logoff if you keep idle for %dm %ds.', remainTime / 60, remainTime % 60))
		end
	end
	LIB.BreatheCall('MY_LOGOFF_IDLE', 1000, onBreatheCall)
	LIB.Sysmsg(_L('Idle off has been started, you\'ll auto logoff if you keep idle for %dm.', MY_Logoff.nIdleOffTime))
end

local function onInit()
	LIB.DelayCall(2000, IdleOff)
end
LIB.RegisterInit('MY_LOGOFF', onInit)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local x, y = X, Y
	local w, h = ui:Size()

	-- 暂离登出
	x = X
	ui:Append('Text', { x = x, y = y, text = _L['Idle logoff'], font = 27 })
	y = y + 35

	x = X + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Enable'],
		checked = MY_Logoff.bIdleOff,
		oncheck = function(bChecked)
			MY_Logoff.bIdleOff = bChecked
			IdleOff()
		end,
	}):AutoWidth():Width() + 5

	ui:Append('WndTrackbar', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('Auto logoff when keep idle for %dmin.', val) end,
		range = {1, 1440},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = MY_Logoff.nIdleOffTime,
		onchange = function(val)
			MY_Logoff.nIdleOffTime = val
			LIB.DelayCall('MY_LOGOFF_IDLE_TIME_CHANGE', 500, IdleOff)
		end,
		autoenable = function() return MY_Logoff.bIdleOff end,
	})
	y = y + 40

	-- 快速登出
	x = X
	ui:Append('Text', { x = x, y = y, text = _L['Express logoff'], font = 27 })
	y = y + 35

	x = X + 10
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 120,
		text = _L['Return to role list'], buttonstyle = 'FLAT',
		onclick = function() Logoff(false) end,
	}):Width() + 5

	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 170,
		text = _L['Return to role list while not fight'], buttonstyle = 'FLAT',
		onclick = function() Logoff(false,true) end,
	}):Width() + 5

	ui:Append('WndButton', {
		x = x, y = y, w = 100,
		text = _L['Hotkey setting'], buttonstyle = 'FLAT',
		onclick = function() LIB.SetHotKey() end,
	})
	y = y + 30

	x = X + 10
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 120,
		text = _L['Return to game login'], buttonstyle = 'FLAT',
		onclick = function() Logoff(true) end,
	}):Width() + 5
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 170,
		text = _L['Return to game login while not fight'], buttonstyle = 'FLAT',
		onclick = function() Logoff(true,true) end,
	}):Width() + 5
	y = y + 30

	x = X
	y = y + 20
	ui:Append('Text', { x = x, y = y, w = w - x * 2, text = _L['Tips'], font = 27, multiline = true, valign = 0 })
	y = y + 30
	x = X + 10
	ui:Append('Text', { x = x, y = y, w = w - x * 2, text = _L['MY_Logoff TIPS'], font = 27, multiline = true, valign = 0 })
end
LIB.RegisterPanel(_L['System'], 'Logoff', _L['Express logoff'], 'UI/Image/UICommon/LoginSchool.UITex|24', PS)

do
local menu = {
	szOption = _L['Express logoff'],
	{
		szOption = _L['Return to role list'],
		fnAction = function()
			Logoff(false)
		end,
	}, {
		szOption = _L['Return to game login'],
		fnAction = function()
			Logoff(true)
		end,
	}, {
		szOption = _L['Return to role list while not fight'],
		fnAction = function()
			Logoff(false, true)
		end,
	}, {
		szOption = _L['Return to game login while not fight'],
		fnAction = function()
			Logoff(true, true)
		end,
	}, {
		bDevide  = true,
	}, {
		szOption = _L['Set hotkey'],
		fnAction = function()
			LIB.SetHotKey()
		end,
	},
}
LIB.RegisterAddonMenu('MY_LOGOFF_MENU', menu)
end

LIB.RegisterHotKey('MY_LogOff_RUI', _L['Return to role list'], function() Logoff(false) end, nil)
LIB.RegisterHotKey('MY_LogOff_RRL', _L['Return to game login'], function() Logoff(true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RUI_UNFIGHT', _L['Return to role list while not fight'], function() Logoff(false, true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RRL_UNFIGHT', _L['Return to game login while not fight'], function() Logoff(true, true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RUI_UNFIGHT_ALIVE', _L['Return to role list while not fight and not dead'], function() Logoff(false, true, true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RRL_UNFIGHT_ALIVE', _L['Return to game login while not fight and not dead'], function() Logoff(true, true, true) end, nil)
