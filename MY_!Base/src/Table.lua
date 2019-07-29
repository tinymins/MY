--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 查询全局配置表函数库
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

if IsFunction(Table_GetCommonEnchantDesc) then
	LIB.Table_GetCommonEnchantDesc = Table_GetCommonEnchantDesc
else
	function LIB.Table_GetCommonEnchantDesc(enchant_id)
		local res = g_tTable.CommonEnchant:Search(enchant_id)
		if res then
			return res.desc
		end
	end
end

if IsFunction(Table_GetProfessionName) then
	LIB.Table_GetProfessionName = Table_GetProfessionName
else
	function LIB.Table_GetProfessionName(dwProfessionID)
		local szName = ''
		local tProfession = g_tTable.ProfessionName:Search(dwProfessionID)
		if tProfession then
			szName = tProfession.szName
		end
		return szName
	end
end

if IsFunction(Table_GetDoodadTemplateName) then
	LIB.Table_GetDoodadTemplateName = Table_GetDoodadTemplateName
else
	function LIB.Table_GetDoodadTemplateName(dwTemplateID)
		local szName = ''
		local tDoodad = g_tTable.DoodadTemplate:Search(dwTemplateID)
		if tDoodad then
			szName = tDoodad.szName
		end
		return szName
	end
end

if IsFunction(Table_IsTreasureBattleFieldMap) then
	LIB.Table_IsTreasureBattleFieldMap = Table_IsTreasureBattleFieldMap
else
	function LIB.Table_IsTreasureBattleFieldMap()
		return false
	end
end

if IsFunction(Table_GetTeamRecruit) then
	LIB.Table_GetTeamRecruit = Table_GetTeamRecruit
else
	function LIB.Table_GetTeamRecruit()
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
					table.insert(res[dwType][dwSubType], tLine)
				else
					table.insert(res[dwType], tLine)
				end
			end
		end
		return res
	end
end

if IsFunction(Table_IsSimplePlayer) then
	LIB.Table_IsSimplePlayer = Table_IsSimplePlayer
else
	function LIB.Table_IsSimplePlayer(dwTemplateID)
		local tLine = g_tTable.SimplePlayer:Search(dwTemplateID)
		if tLine then
			return true
		end
		return false
	end
end

if IsFunction(Table_SchoolToForce) then
	LIB.Table_SchoolToForce = Table_SchoolToForce
else
	function LIB.Table_SchoolToForce(dwSchoolID)
		local nCount = g_tTable.ForceToSchool:GetRowCount()
		local dwForceID = 0
		for i = 1, nCount do
			tLine = g_tTable.ForceToSchool:GetRow(i)
			if dwSchoolID == tLine.dwSchoolID then
				dwForceID = tLine.dwForceID
			end
		end
		return dwForceID
	end
end

if IsFunction(Table_GetSkillSchoolKungfu) then
	LIB.Table_GetSkillSchoolKungfu = Table_GetSkillSchoolKungfu
else
	function LIB.Table_GetSkillSchoolKungfu(dwSchoolID)
		local tKungFungList = {}
		local tLine = g_tTable.SkillSchoolKungfu:Search(dwSchoolID)
		if tLine then
			local szKungfu = tLine.szKungfu
			for s in string.gmatch(szKungfu, "%d+") do
				local dwID = tonumber(s)
				if dwID then
					table.insert(tKungFungList, dwID)
				end
			end
		end
		return tKungFungList
	end
end

if IsFunction(Table_GetMKungfuList) then
	LIB.Table_GetMKungfuList = Table_GetMKungfuList
else
	function LIB.Table_GetMKungfuList(dwKungfuID)
		local tLine = g_tTable.MKungfuKungfu:Search(dwKungfuID)
		local tKungfu = {}
		if tLine and tLine.szKungfu then
			local szKungfu = tLine.szKungfu
			for s in string.gmatch(szKungfu, "%d+") do
				local dwID = tonumber(s)
				if dwID then
					table.insert(tKungfu, dwID)
				end
			end
		end
		return tKungfu
	end
end


if IsFunction(Table_GetNewKungfuSkill) then
	LIB.Table_GetNewKungfuSkill = Table_GetNewKungfuSkill
else
	function LIB.Table_GetNewKungfuSkill(dwMountKungfu, dwKungfuID)
		local tLine = g_tTable.SkillKungFuShow:Search(dwMountKungfu) or {}
		if empty(tLine) then
			return nil
		end
		if tLine.dwKungfu ~= dwKungfuID then
			return nil
		end
		local tSkill = {}
		local szSkill = tLine.szNewSkillID
		for s in string.gmatch(szSkill, "%d+") do
			local dwID = tonumber(s)
			if dwID then
				table.insert(tSkill, dwID)
			end
		end
		if tSkill and not empty(tSkill) then
			return tSkill
		end
		return nil
	end
end

if IsFunction(Table_GetKungfuSkillList) then
	LIB.Table_GetKungfuSkillList = Table_GetKungfuSkillList
else
	function LIB.Table_GetKungfuSkillList(dwKungfuID)
		local tSkill = {}
		local tLine = g_tTable.KungfuSkill:Search(dwKungfuID)
		if tLine then
			local szSkill = tLine.szSkill
			for s in string.gmatch(szSkill, "%d+") do
				local dwID = tonumber(s)
				if dwID then
					table.insert(tSkill, dwID)
				end
			end
		end
		return tSkill
	end
end

if IsFunction(Table_GetSkillExtCDID) then
	LIB.Table_GetSkillExtCDID = Table_GetSkillExtCDID
else
	local cache = {}
	function LIB.Table_GetSkillExtCDID(dwID)
		if cache[dwID] == nil then
			local tLine = g_tTable.SkillExtCDID:Search(dwID)
			cache[dwID] = tLine and tLine.dwExtID or false
		end
		return cache[dwID] and cache[dwID] or nil
	end
end
