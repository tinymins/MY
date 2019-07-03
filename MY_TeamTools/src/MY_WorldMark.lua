--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 世界标记增强
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : Webster
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
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------

local D = {}
local WM_LIST = {
	[20107] = { id = 1,  col = { 255, 255, 255 } },
	[20108] = { id = 2,  col = { 255, 128, 0   } },
	[20109] = { id = 3,  col = { 0  , 0  , 255 } },
	[20110] = { id = 4,  col = { 0  , 255, 0   } },
	[20111] = { id = 5,  col = { 255, 0  , 0   } },
	[36781] = { id = 6,  col = { 50 , 220, 255 } },
	[36782] = { id = 7,  col = { 255, 100, 220 } },
	[36783] = { id = 8,  col = { 255, 255, 0   } },
	[36784] = { id = 9,  col = { 200, 40,  255 } },
	[36785] = { id = 10, col = { 30,  255, 180 } },
}
local WM_POINT  = {}

MY_WorldMark = {
	bEnable = true
}
LIB.RegisterCustomData('MY_WorldMark')

function D.OnNpcEvent()
	local npc = GetNpc(arg0)
	if npc then
		local mark = WM_LIST[npc.dwTemplateID]
		if mark then
			local tPoint = { npc.nX, npc.nY, npc.nZ }
			local handle = UI.GetShadowHandle('Handle_World_Mark')
			local szName = 'w_' .. mark.id
			if handle:Lookup(szName) then
				handle:RemoveItem(szName)
			end
			WM_POINT[mark.id] = tPoint
		end
	end
end

function D.OnNpcLeave()
	local npc = GetNpc(arg0)
	if npc then
		local mark = WM_LIST[npc.dwTemplateID]
		if mark then
			local tPoint = WM_POINT[mark.id]
			if tPoint then
				local handle = UI.GetShadowHandle('Handle_World_Mark')
				local szName = 'w_' .. mark.id
				local sha = handle:Lookup(szName)
				if not sha then
					handle:AppendItemFromString('<shadow>name="' .. szName ..'"</shadow>')
					sha = handle:Lookup(szName)
				end
				D.Draw(tPoint, sha, mark.col)
			end
		end
	end
end

function D.OnCast(dwSkillID)
	if dwSkillID == 4906 then
		WM_POINT = {}
		UI.GetShadowHandle('Handle_World_Mark'):Clear()
	end
end

function D.OnDoSkillCast()
	D.OnCast(arg1)
end

function D.OnLoadingEnd()
	WM_POINT = {}
	UI.GetShadowHandle('Handle_World_Mark'):Clear()
end

function D.Draw(Point, sha, col)
	local nRadius    = 64
	local nFace      = 128
	local dwRad1     = math.pi
	local dwRad2     = 3 * math.pi + math.pi / 20
	local r, g, b    = unpack(col)
	local nX, nY, nZ = unpack(Point)
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLEFAN)
	sha:ClearTriangleFanPoint()
	sha:AppendTriangleFan3DPoint(nX ,nY, nZ, r, g, b, 80)
	sha:Show()
	local sX, sZ = Scene_PlaneGameWorldPosToScene(nX, nY)
	repeat
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(nX + math.cos(dwRad1) * nRadius, nY + math.sin(dwRad1) * nRadius)
		sha:AppendTriangleFan3DPoint(nX ,nY, nZ, r, g, b, 80, { sX_ - sX, 0, sZ_ - sZ })
		dwRad1 = dwRad1 + math.pi / 16
	until dwRad1 > dwRad2
end

function D.GetEvent()
	if MY_WorldMark.bEnable and not LIB.IsShieldedVersion() then
		return {
			{'DO_SKILL_CAST', D.OnDoSkillCast},
			{'NPC_LEAVE_SCENE', D.OnNpcLeave},
			{'NPC_ENTER_SCENE', D.OnNpcEvent},
			{'LOADING_END', D.OnLoadingEnd},
		}
	else
		D.OnCast(4906)
		return false
	end
end

function MY_WorldMark.CheckEnable()
	LIB.RegisterModuleEvent('MY_WorldMark', D.GetEvent())
end

LIB.RegisterInit('MY_WorldMark', MY_WorldMark.CheckEnable)
LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_WorldMark', MY_WorldMark.CheckEnable)
