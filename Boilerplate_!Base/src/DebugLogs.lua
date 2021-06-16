--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 各种调试信息输出
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SaveCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------

LIB.RegisterEvent(NSFormatString('OPEN_WINDOW.{$NS}_DebugLogs'), function()
	if not LIB.IsDebugClient(true) then
		return
	end
	Log('Event: OPEN_WINDOW')
	Log('== EVENT ARGS BEGIN ==')
	Log(tostring(arg0))
	Log(tostring(arg1))
	Log('== EVENT ARGS END ==')
end)

LIB.RegisterEvent(NSFormatString('ON_WARNING_MESSAGE.{$NS}_DebugLogs'), function()
	if not LIB.IsDebugClient(true) then
		return
	end
	Log('Event: ON_WARNING_MESSAGE')
	Log('== EVENT ARGS BEGIN ==')
	Log(tostring(arg0))
	Log(tostring(arg1))
	Log('== EVENT ARGS END ==')
end)

LIB.RegisterMsgMonitor(NSFormatString('MSG_NPC_NEARBY.{$NS}_DebugLogs'), function(szChannel, szMsg, nFont, bRich)
	if not LIB.IsDebugClient(true) then
		return
	end
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	Log('Msg: MSG_NPC_NEARBY')
	Log('== MSG INFO BEGIN ==')
	Log('Channel: ' .. tostring(szChannel))
	Log('Msg: ' .. tostring(szMsg))
	Log('== MSG INFO END ==')
end)
