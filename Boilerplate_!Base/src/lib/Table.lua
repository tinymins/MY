--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 查询全局配置表函数库
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

function LIB.Table_GetCommonEnchantDesc(enchant_id)
	if IsFunction(_G.Table_GetCommonEnchantDesc) then
		return _G.Table_GetCommonEnchantDesc(enchant_id)
	end
	local res = g_tTable.CommonEnchant:Search(enchant_id)
	if res then
		return res.desc
	end
end

function LIB.Table_GetProfessionName(dwProfessionID)
	if IsFunction(_G.Table_GetProfessionName) then
		return _G.Table_GetProfessionName(dwProfessionID)
	end
	local szName = ''
	local tProfession = g_tTable.ProfessionName:Search(dwProfessionID)
	if tProfession then
		szName = tProfession.szName
	end
	return szName
end

function LIB.Table_GetDoodadTemplateName(dwTemplateID)
	if IsFunction(_G.Table_GetDoodadTemplateName) then
		return _G.Table_GetDoodadTemplateName(dwTemplateID)
	end
	local szName = ''
	local tDoodad = g_tTable.DoodadTemplate:Search(dwTemplateID)
	if tDoodad then
		szName = tDoodad.szName
	end
	return szName
end

function LIB.Table_IsTreasureBattleFieldMap(dwMapID)
	if IsFunction(_G.Table_IsTreasureBattleFieldMap) then
		return _G.Table_IsTreasureBattleFieldMap(dwMapID)
	end
	return false
end

function LIB.Table_GetTeamRecruit()
	if IsFunction(_G.Table_GetTeamRecruit) then
		return _G.Table_GetTeamRecruit()
	end
	local res = {}
	local nCount = g_tTable.TeamRecruit:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.TeamRecruit:GetRow(i)
		local dwType = tLine.dwType
		local szTypeName = tLine.szTypeName

		if dwType > 0 then
			res[dwType] = res[dwType] or {Type=dwType, TypeName=szTypeName}
			res[dwType].bParent = true
			local dwSubType = tLine.dwSubType
			local szSubTypeName = tLine.szSubTypeName
			if dwSubType > 0 then
				res[dwType][dwSubType] = res[dwType][dwSubType] or {SubType=dwSubType, SubTypeName=szSubTypeName}
				res[dwType][dwSubType].bParent = true
				insert(res[dwType][dwSubType], tLine)
			else
				insert(res[dwType], tLine)
			end
		end
	end
	return res
end

function LIB.Table_IsSimplePlayer(dwTemplateID)
	if IsFunction(_G.Table_IsSimplePlayer) then
		return _G.Table_IsSimplePlayer(dwTemplateID)
	end
	local tLine = g_tTable.SimplePlayer:Search(dwTemplateID)
	if tLine then
		return true
	end
	return false
end

do
local cache = {}
function LIB.Table_GetSkillExtCDID(dwID)
	if IsFunction(_G.Table_GetSkillExtCDID) then
		return _G.Table_GetSkillExtCDID(dwID)
	end
	if cache[dwID] == nil then
		local tLine = g_tTable.SkillExtCDID:Search(dwID)
		cache[dwID] = tLine and tLine.dwExtID or false
	end
	return cache[dwID] and cache[dwID] or nil
end
end
