--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标方位显示
-- @author   : Webster
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
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
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Target/lang/')
if not MY.AssertVersion('MY_TargetLine', _L['MY_TargetLine'], 0x2011800) then
	return
end

local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_Target/ui/MY_TargetLine.ini'
local IMG_PATH = MY.GetAddonInfo().szRoot .. 'MY_Target/img/MY_TargetLine.uitex'

local O = {
	bTarget       = false,         -- 启用目标追踪线
	bTTarget      = false,         -- 显示目标与目标的目标连接线
	nConnWidth    = 3,             -- 连接线宽度
	nConnAlpha    = 150,           -- 连接线不透明度
	tTargetColor  = { 0, 255, 0 }, -- 颜色
	tTTargetColor = { 255, 0, 0 }, -- 颜色
}
local C, D = {}, {}

RegisterCustomData('MY_TargetLine.bTarget')
RegisterCustomData('MY_TargetLine.bTTarget')
RegisterCustomData('MY_TargetLine.nConnWidth')
RegisterCustomData('MY_TargetLine.nConnAlpha')
RegisterCustomData('MY_TargetLine.tTargetColor')
RegisterCustomData('MY_TargetLine.tTTargetColor')

function D.RequireRerender()
	C.bReRender = true
end

do
local function DrawLine(tar, ttar, sha, col, nAlpha)
	sha:SetTriangleFan(GEOMETRY_TYPE.LINE, O.nConnWidth)
	sha:ClearTriangleFanPoint()
	local r, g, b = unpack(col)
	sha:AppendCharacterID(tar.dwID, true, r, g, b, nAlpha)
	sha:AppendCharacterID(ttar.dwID, true, r, g, b, nAlpha)
	sha:Show()
end

local function onBreathe()
	local me = GetClientPlayer()
	local dwTarType, dwTarID = MY.GetTarget()
	local tar = MY.GetObject(dwTarType, dwTarID)
	local dwTTarType, dwTTarID = MY.GetTarget(tar)
	local ttar = MY.GetObject(dwTTarType, dwTTarID)

	-- show connect
	if O.bTarget and me and tar and tar.dwID ~= me.dwID
	and (not ttar or not O.bTTarget or (ttar and ttar.dwID ~= me.dwID)) then
		if C.bReRender
		or C.dwTarID ~= tar.dwID
		or (ttar and C.dwTTarID ~= ttar.dwID)
		or (not ttar and C.dwTTarID ~= 0) then
			DrawLine(me, tar, C.shaTLine, O.tTargetColor, O.nConnAlpha)
		end
	else
		C.shaTLine:Hide()
	end
	C.dwTarID = dwTTarID

	if O.bTTarget and tar and ttar then
		if C.bReRender or C.dwTTarID ~= ttar.dwID then
			DrawLine(tar, ttar, C.shaTTLine, O.tTTargetColor, O.nConnAlpha)
		end
	else
		C.shaTTLine:Hide()
	end
	C.dwTTarID = dwTTarID

	C.bReRender = false
end

function D.CheckEnable()
	if not MY.IsShieldedVersion() and (O.bTarget or O.bTTarget) then
		local hShaList = UI.GetShadowHandle('MY_TargetLine')
		for _, v in ipairs({'TLine', 'TTLine', 'Name'}) do
			local sha = hShaList:Lookup(v)
			if not sha then
				hShaList:AppendItemFromString('<shadow>name="' .. v .. '"</shadow>')
				sha = hShaList:Lookup(v)
			end
			C['sha' .. v] = sha
		end
		MY.BreatheCall('MY_TargetLine', onBreathe)
	else
		for _, v in ipairs({'TLine', 'TTLine', 'Name'}) do
			local sha = C['sha' .. v]
			if sha and sha:IsValid() then
				sha:Hide()
			end
			C['sha' .. v] = nil
		end
		MY.BreatheCall('MY_TargetLine', false)
	end
	D.RequireRerender()
end

MY.RegisterInit('MY_TargetLine', D.CheckEnable)
MY.RegisterEvent('MY_SHIELDED_VERSION.MY_TargetLine', D.CheckEnable)
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bTarget       = true,
				bTTarget      = true,
				nConnWidth    = true,
				nConnAlpha    = true,
				tTargetColor  = true,
				tTTargetColor = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bTarget       = true,
				bTTarget      = true,
				nConnWidth    = true,
				nConnAlpha    = true,
				tTargetColor  = true,
				tTTargetColor = true,
			},
			triggers = {
				bTarget       = D.CheckEnable,
				bTTarget      = D.CheckEnable,
				nConnWidth    = D.RequireRerender,
				nConnAlpha    = D.RequireRerender,
				tTargetColor  = D.RequireRerender,
				tTTargetColor = D.RequireRerender,
			},
			root = O,
		},
	},
}
MY_TargetLine = MY.GeneGlobalNS(settings)
end
