--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 基础库加载完成处理
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
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
if IsDebugClient() then
_G[LIB.GetAddonInfo().szNameSpace .. '_DebugSetVal'] = function(szKey, oVal)
	LIB[szKey] = oVal
end
end

_G[LIB.GetAddonInfo().szNameSpace] = setmetatable({}, {
	__metatable = true,
	__index = LIB,
	__newindex = function() assert(false, 'DO NOT modify ' .. LIB.GetAddonInfo().szNameSpace .. ' after initialized!!!') end
})

FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_BASE_LOADING_END')

-- 修复剑心导致玩家头像越来越大的问题。。。
do
local nInitWidth, nFinalWidth
LIB.RegisterEvent('ON_FRAME_CREATE.FixJXPlayer', function()
	if arg0:GetName() == 'Player' then
		nInitWidth = arg0:GetW()
	end
end)
local function RevertWidth()
	local frame = Station.Lookup('Normal/Player')
	if not frame or not nInitWidth then
		return
	end
	nFinalWidth = frame:GetW()
	frame:SetW(nInitWidth)
end
local function ApplyWidth()
	local frame = Station.Lookup('Normal/Player')
	if not frame or not nFinalWidth then
		return
	end
	frame:SetW(nFinalWidth)
end
LIB.RegisterReload('FixJXPlayer', RevertWidth)
LIB.RegisterEvent('ON_ENTER_CUSTOM_UI_MODE.FixJXPlayer', RevertWidth)
LIB.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE.FixJXPlayer', ApplyWidth)
end
