--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 查询全局配置表函数库
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
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

function LIB.Table_SchoolToForce(dwSchoolID)
	if IsFunction(_G.Table_SchoolToForce) then
		return _G.Table_SchoolToForce(dwSchoolID)
	end
	local nCount = g_tTable.ForceToSchool:GetRowCount()
	local dwForceID = 0
	for i = 1, nCount do
		local tLine = g_tTable.ForceToSchool:GetRow(i)
		if dwSchoolID == tLine.dwSchoolID then
			dwForceID = tLine.dwForceID
		end
	end
	return dwForceID
end

function LIB.Table_GetSkillSchoolKungfu(dwSchoolID)
	if IsFunction(_G.Table_GetSkillSchoolKungfu) then
		return _G.Table_GetSkillSchoolKungfu(dwSchoolID)
	end
	local tKungFungList = {}
	local tLine = g_tTable.SkillSchoolKungfu:Search(dwSchoolID)
	if tLine then
		local szKungfu = tLine.szKungfu
		for s in gmatch(szKungfu, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				insert(tKungFungList, dwID)
			end
		end
	end
	return tKungFungList
end

function LIB.Table_GetMKungfuList(dwKungfuID)
	if IsFunction(_G.Table_GetMKungfuList) then
		return _G.Table_GetMKungfuList(dwKungfuID)
	end
	local tLine = g_tTable.MKungfuKungfu:Search(dwKungfuID)
	local tKungfu = {}
	if tLine and tLine.szKungfu then
		local szKungfu = tLine.szKungfu
		for s in gmatch(szKungfu, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				insert(tKungfu, dwID)
			end
		end
	end
	return tKungfu
end


function LIB.Table_GetNewKungfuSkill(dwMountKungfu, dwKungfuID)
	if IsFunction(_G.Table_GetNewKungfuSkill) then
		return _G.Table_GetNewKungfuSkill(dwMountKungfu, dwKungfuID)
	end
	local tLine = g_tTable.SkillKungFuShow:Search(dwMountKungfu) or {}
	if IsEmpty(tLine) then
		return nil
	end
	if tLine.dwKungfu ~= dwKungfuID then
		return nil
	end
	local tSkill = {}
	local szSkill = tLine.szNewSkillID
	for s in gmatch(szSkill, "%d+") do
		local dwID = tonumber(s)
		if dwID then
			insert(tSkill, dwID)
		end
	end
	if tSkill and not IsEmpty(tSkill) then
		return tSkill
	end
	return nil
end

function LIB.Table_GetKungfuSkillList(dwKungfuID)
	if IsFunction(_G.Table_GetKungfuSkillList) then
		return _G.Table_GetKungfuSkillList(dwKungfuID)
	end
	local tSkill = {}
	local tLine = g_tTable.KungfuSkill:Search(dwKungfuID)
	if tLine then
		local szSkill = tLine.szSkill
		for s in gmatch(szSkill, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				insert(tSkill, dwID)
			end
		end
	end
	return tSkill
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
