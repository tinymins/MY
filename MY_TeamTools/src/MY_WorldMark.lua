--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 世界标记增强
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : Webster
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
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------

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
MY.RegisterCustomData('MY_WorldMark')

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
	if MY_WorldMark.bEnable and not MY.IsShieldedVersion() then
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
	MY.RegisterModuleEvent('MY_WorldMark', D.GetEvent())
end

MY.RegisterInit('MY_WorldMark', MY_WorldMark.CheckEnable)
MY.RegisterEvent('MY_SHIELDED_VERSION.MY_WorldMark', MY_WorldMark.CheckEnable)
