--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 全局染色设置
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local LIB = Boilerplate
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps/')

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local X, Y = 20, 20
	local x, y = X, Y

	ui:Append('Text', {
		x = X - 10, y = y,
		text = _L['Force color'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	x, y = X, y + 30
	for _, dwForceID in pairs_c(CONSTANT.FORCE_TYPE) do
		local x0 = x
		local sha = ui:Append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { LIB.GetForceColor(dwForceID, 'background') },
		})
		local txt = ui:Append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { LIB.GetForceColor(dwForceID, 'foreground') },
		})
		x = x + 105
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetForceColor(dwForceID, 'foreground') },
			oncolorpick = function(r, g, b)
				txt:Color(r, g, b)
				LIB.SetForceColor(dwForceID, 'foreground', { r, g, b })
			end,
		})
		x = x + 30
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetForceColor(dwForceID, 'background') },
			oncolorpick = function(r, g, b)
				sha:Color(r, g, b)
				LIB.SetForceColor(dwForceID, 'background', { r, g, b })
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = X
			y = y + 35
		end
	end
	ui:Append('WndButton', {
		x = x, y = y, w = 160, h = 25,
		buttonstyle = 'FLAT',
		text = _L['Restore default'],
		onclick = function()
			LIB.SetForceColor('reset')
			LIB.SwitchTab('GlobalColor', true)
		end,
	})

	y = y + 45
	ui:Append('Text', {
		x = X - 10, y = y,
		text = _L['Camp color'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	x, y = X, y + 30
	for _, nCamp in ipairs({ CAMP.NEUTRAL, CAMP.GOOD, CAMP.EVIL }) do
		local x0 = x
		local sha = ui:Append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { LIB.GetCampColor(nCamp, 'background') },
		})
		local txt = ui:Append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { LIB.GetCampColor(nCamp, 'foreground') },
		})
		x = x + 105
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetCampColor(nCamp, 'foreground') },
			oncolorpick = function(r, g, b)
				txt:Color(r, g, b)
				LIB.SetCampColor(nCamp, 'foreground', { r, g, b })
			end,
		})
		x = x + 30
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetCampColor(nCamp, 'background') },
			oncolorpick = function(r, g, b)
				sha:Color(r, g, b)
				LIB.SetCampColor(nCamp, 'background', { r, g, b })
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = X
			y = y + 35
		end
	end
	ui:Append('WndButton', {
		x = x, y = y, w = 160, h = 25,
		text = _L['Restore default'],
		buttonstyle = 'FLAT',
		onclick = function()
			LIB.SetCampColor('reset')
			LIB.SwitchTab('GlobalColor', true)
		end,
	})
end

LIB.RegisterPanel(_L['System'], 'GlobalColor', _L['Global color'], 'ui\\Image\\button\\CommonButton_1.UITex|70', PS)
