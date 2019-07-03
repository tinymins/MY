--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 快速登出 指定条件退队/下线
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
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_Logoff/lang/')
if not LIB.AssertVersion('MY_Logoff', _L['MY_Logoff'], 0x2011800) then
	return
end

MY_Logoff = {}
MY_Logoff.bIdleOff = false
MY_Logoff.nIdleOffTime = 30
RegisterCustomData('MY_Logoff.bIdleOff')
RegisterCustomData('MY_Logoff.nIdleOffTime')

local function Logoff(bCompletely, bUnfight, bNotDead)
	if LIB.BreatheCall('MY_LOGOFF') then
		LIB.BreatheCall('MY_LOGOFF', false)
		LIB.Sysmsg({_L['Logoff has been cancelled.']})
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
		LIB.Sysmsg({_L['Logoff is ready for your casting unfight skill.']})
	end
	LIB.BreatheCall('MY_LOGOFF', onBreatheCall)
end

local function IdleOff()
	if not MY_Logoff.bIdleOff then
		if LIB.BreatheCall('MY_LOGOFF_IDLE') then
			LIB.Sysmsg({_L['Idle off has been cancelled.']})
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
			LIB.Sysmsg({szMessage})
		else
			LIB.Sysmsg({_L('Idle off notice: you\'ll auto logoff if you keep idle for %dm %ds.', remainTime / 60, remainTime % 60)})
		end
	end
	LIB.BreatheCall('MY_LOGOFF_IDLE', 1000, onBreatheCall)
	LIB.Sysmsg({_L('Idle off has been started, you\'ll auto logoff if you keep idle for %dm.', MY_Logoff.nIdleOffTime)})
end

local function onInit()
	LIB.DelayCall(2000, IdleOff)
end
LIB.RegisterInit('MY_LOGOFF', onInit)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local x, y = 20, 20
	local w, h = ui:size()

	-- 暂离登出
	ui:append('Text', { x = x + 10, y = y, text = _L['# idle logoff'] })
	y = y + 23

	ui:append('Image', {
		x = x - 15, y = y, w = w - (x - 15) * 2, h = 1,
		image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageframe = 62,
	})
	y = y + 17

	ui:append('WndCheckBox', {
		x = x, y = y, text = _L['enable'],
		checked = MY_Logoff.bIdleOff,
		oncheck = function(bChecked)
			MY_Logoff.bIdleOff = bChecked
			IdleOff()
		end,
	})

	ui:append('WndSliderBox', {
		x = x + 70, y = y, w = 150,
		textfmt = function(val) return _L('Auto logoff when keep idle for %dmin.', val) end,
		range = {1, 1440},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		value = MY_Logoff.nIdleOffTime,
		onchange = function(val)
			MY_Logoff.nIdleOffTime = val
			LIB.DelayCall('MY_LOGOFF_IDLE_TIME_CHANGE', 500, IdleOff)
		end,
	})
	y = y + 40

	-- 快速登出
	ui:append('Text', { x = x + 10, y = y, text = _L['# express logoff'] })
	y = y + 23

	ui:append('Image', {
		x = x - 15, y = y, w = w - (x - 15) * 2, h = 1,
		image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageframe = 62,
	})
	y = y + 17

	ui:append('WndButton', {
		x = x, y = y, w = 120, text = _L['return to role list'],
		onclick = function() Logoff(false) end,
	})

	ui:append('WndButton', {
		x = 145, y = y, w = 170, text = _L['return to role list while not fight'],
		onclick = function() Logoff(false,true) end,
	})

	ui:append('Text', {
		x = 330, y = y, r = 255, g = 255, b = 0, text = _L['* hotkey setting'],
		onclick = function() LIB.SetHotKey() end,
	})
	y = y + 30

	ui:append('WndButton', {
		x = 20, y = y, w = 120, text = _L['return to game login'],
		onclick = function() Logoff(true) end,
	})
	ui:append('WndButton', {
		x = 145, y = y, w = 170, text = _L['return to game login while not fight'],
		onclick = function() Logoff(true,true) end,
	})
	y = y + 30
end
LIB.RegisterPanel('Logoff', _L['express logoff'], _L['General'], 'UI/Image/UICommon/LoginSchool.UITex|24', PS)

do
local menu = {
	szOption = _L['express logoff'],
	{
		szOption = _L['return to role list'],
		fnAction = function()
			Logoff(false)
		end,
	}, {
		szOption = _L['return to game login'],
		fnAction = function()
			Logoff(true)
		end,
	}, {
		szOption = _L['return to role list while not fight'],
		fnAction = function()
			Logoff(false, true)
		end,
	}, {
		szOption = _L['return to game login while not fight'],
		fnAction = function()
			Logoff(true, true)
		end,
	}, {
		bDevide  = true,
	}, {
		szOption = _L['set hotkey'],
		fnAction = function()
			LIB.SetHotKey()
		end,
	},
}
LIB.RegisterAddonMenu('MY_LOGOFF_MENU', menu)
end

LIB.RegisterHotKey('MY_LogOff_RUI', _L['return to role list'], function() Logoff(false) end, nil)
LIB.RegisterHotKey('MY_LogOff_RRL', _L['return to game login'], function() Logoff(true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RUI_UNFIGHT', _L['return to role list while not fight'], function() Logoff(false, true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RRL_UNFIGHT', _L['return to game login while not fight'], function() Logoff(true, true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RUI_UNFIGHT_ALIVE', _L['return to role list while not fight and not dead'], function() Logoff(false, true, true) end, nil)
LIB.RegisterHotKey('MY_LogOff_RRL_UNFIGHT_ALIVE', _L['return to game login while not fight and not dead'], function() Logoff(true, true, true) end, nil)
