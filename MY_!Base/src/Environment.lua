--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 环境相关
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
---------------------------------------------------------------------------------------------------

-- 获取游戏语言
function LIB.GetLang()
	local _, _, lang = GetVersion()
	return lang
end

-- 获取功能屏蔽等级
do
local DELAY_EVENT = {}
local SHIELDED_LEVEL = { ['*'] = LIB.GetLang() == 'zhcn' and 0 or 1 }
function LIB.IsShieldedVersion(szKey, nLevel, bSet)
	if not IsString(szKey) then
		szKey, nLevel, bSet = '*', szKey, nLevel
	end
	if bSet then
		-- 通用禁止设为空
		if szKey == '*' and IsNil(nLevel) then
			return
		end
		-- 设置值
		if SHIELDED_LEVEL[szKey] == nLevel then
			return
		end
		SHIELDED_LEVEL[szKey] = nLevel
		-- 发起事件通知
		local szEvent = PACKET_INFO.NAME_SPACE .. '#SHIELDED_VERSION'
		if szKey == '*' or szKey == '!' then
			for k, _ in pairs(DELAY_EVENT) do
				LIB.DelayCall(k, false)
			end
			szKey = nil
		else
			szEvent = szEvent .. '#' .. szKey
		end
		LIB.DelayCall(szEvent, 75, function()
			if LIB.IsPanelOpened() then
				LIB.ReopenPanel()
			end
			DELAY_EVENT[szEvent] = nil
			FireUIEvent(PACKET_INFO.NAME_SPACE .. '_SHIELDED_VERSION', szKey)
		end)
		DELAY_EVENT[szEvent] = true
	else
		if not IsNumber(nLevel) then
			nLevel = 1
		end
		if not IsNil(SHIELDED_LEVEL['!']) then
			return SHIELDED_LEVEL['!'] < nLevel
		end
		if not IsNil(SHIELDED_LEVEL[szKey]) then
			return SHIELDED_LEVEL[szKey] < nLevel
		end
		return SHIELDED_LEVEL['*'] < nLevel
	end
end
end

-- 获取是否测试客户端
-- (bool) LIB.IsDebugClient()
-- (bool) LIB.IsDebugClient(bool bManually = false)
-- (bool) LIB.IsDebugClient(string szKey[, bool bDebug, bool bSet])
do
local DELAY_EVENT = {}
local DEBUG = { ['*'] = PACKET_INFO.DEBUG_LEVEL <= DEBUG_LEVEL.DEBUG }
function LIB.IsDebugClient(szKey, bDebug, bSet)
	if not IsString(szKey) then
		szKey, bDebug, bSet = '*', szKey, bDebug
	end
	if bSet then
		-- 通用禁止设为空
		if szKey == '*' and IsNil(bDebug) then
			return
		end
		-- 设置值
		if DEBUG[szKey] == bDebug then
			return
		end
		DEBUG[szKey] = bDebug
		-- 发起事件通知
		local szEvent = PACKET_INFO.NAME_SPACE .. '#DEBUG'
		if szKey == '*' or szKey == '!' then
			for k, _ in pairs(DELAY_EVENT) do
				LIB.DelayCall(k, false)
			end
			szKey = nil
		else
			szEvent = szEvent .. '#' .. szKey
		end
		LIB.DelayCall(szEvent, 75, function()
			if LIB.IsPanelOpened() then
				LIB.ReopenPanel()
			end
			DELAY_EVENT[szEvent] = nil
			FireUIEvent(PACKET_INFO.NAME_SPACE .. '_DEBUG', szKey)
		end)
		DELAY_EVENT[szEvent] = true
	else
		if not IsNil(DEBUG['!']) then
			return DEBUG['!']
		end
		if szKey == '*' and not bDebug then
			return IsDebugClient()
		end
		if not IsNil(DEBUG[szKey]) then
			return DEBUG[szKey]
		end
		return DEBUG['*']
	end
end
end

-- 获取是否测试服务器
function LIB.IsDebugServer()
	local ip = select(7, GetUserServer())
	if ip:find('^192%.') or ip:find('^10%.') then
		return true
	end
	return false
end
