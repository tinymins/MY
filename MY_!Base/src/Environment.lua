--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 环境相关
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
local _L = LIB.LoadLangPack()
---------------------------------------------------------------------------------------------------

-- 获取游戏语言
function LIB.GetLang()
	local _, _, lang = GetVersion()
	return lang
end

-- 获取功能屏蔽等级
do
local SHIELDED_LEVEL = LIB.GetLang() == 'zhcn' and 0 or 1 -- 全部功能限制开关
local FUNCTION_SHIELDED_LEVEL = {}
function LIB.IsShieldedVersion(szKey, nLevel, bSet)
	if not IsString(szKey) then
		szKey, nLevel, bSet = nil, szKey, nLevel
	end
	if bSet then
		if not nLevel then
			return
		end
		if szKey then
			if FUNCTION_SHIELDED_LEVEL[szKey] == nLevel then
				return
			end
			FUNCTION_SHIELDED_LEVEL[szKey] = nLevel
		else
			if SHIELDED_LEVEL == nLevel then
				return
			end
			SHIELDED_LEVEL = nLevel
		end
		LIB.DelayCall(PACKET_INFO.NAME_SPACE .. '#SHIELDED_VERSION', 75, function()
			if LIB.IsPanelOpened() then
				LIB.ReopenPanel()
			end
			FireUIEvent(PACKET_INFO.NAME_SPACE .. '_SHIELDED_VERSION', szKey)
		end)
	else
		if not IsNumber(nLevel) then
			nLevel = 1
		end
		if SHIELDED_LEVEL >= nLevel then
			return false
		end
		local nKeyLevel = FUNCTION_SHIELDED_LEVEL[szKey]
		if nKeyLevel and nKeyLevel >= nLevel then
			return false
		end
		return true
	end
end
end

-- 获取是否测试客户端
-- (bool) LIB.IsDebugClient()
-- (bool) LIB.IsDebugClient(string szKey[, bool bDebug])
-- (bool) LIB.IsDebugClient(bool bManually)
do
local DEBUG = {}
function LIB.IsDebugClient(szKey, bDebug)
	if not szKey and IsDebugClient() then
		return true
	end
	if IsString(szKey) then
		if IsBoolean(bDebug) then
			DEBUG[szKey] = bDebug
		end
		return DEBUG[szKey] or false
	end
	return PACKET_INFO.DEBUG_LEVEL <= DEBUG_LEVEL.DEBUG
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
