--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录 发放投票相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
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
local MY, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_GKP/lang/')
-- 工资结算
local TEAM_VOTE_REQUEST = {}
MY.RegisterEvent('TEAM_VOTE_REQUEST', function()
	if arg0 == 1 then
		TEAM_VOTE_REQUEST = {}
		local team = GetClientTeam()
		for k, v in ipairs(team.GetTeamMemberList()) do
			TEAM_VOTE_REQUEST[v] = false
		end
	end
end)

MY.RegisterEvent('TEAM_VOTE_RESPOND', function()
	if arg0 == 1 and not IsEmpty(TEAM_VOTE_REQUEST) then
		if arg2 == 1 then
			TEAM_VOTE_REQUEST[arg1] = true
		end
		local team  = GetClientTeam()
		local num   = team.GetTeamSize()
		local agree = 0
		for k, v in pairs(TEAM_VOTE_REQUEST) do
			if v then
				agree = agree + 1
			end
		end
		MY.Topmsg(_L('Team Members: %d, %d agree %d%%', num, agree, agree / num * 100))
	end
end)

MY.RegisterEvent('TEAM_INCOMEMONEY_CHANGE_NOTIFY', function()
	local nTotalRaidMoney = GetClientTeam().nInComeMoney
	if nTotalRaidMoney and nTotalRaidMoney == 0 then
		TEAM_VOTE_REQUEST = {}
	end
end)
