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
	bTargetRL     = true,          -- 启用新版连线
	bTTarget      = false,         -- 显示目标与目标的目标连接线
	bTTargetRL    = true,          -- 启用新版连线
	bAtHead       = true,          -- 连接线从头部开始
	nLineWidth    = 3,             -- 连接线宽度
	nLineAlpha    = 150,           -- 连接线不透明度
	tTargetColor  = { 0, 255, 0 }, -- 颜色
	tTTargetColor = { 255, 0, 0 }, -- 颜色
}
local C, D = {}, {}

RegisterCustomData('MY_TargetLine.bTarget')
RegisterCustomData('MY_TargetLine.bTargetRL')
RegisterCustomData('MY_TargetLine.bTTarget')
RegisterCustomData('MY_TargetLine.bTTargetRL')
RegisterCustomData('MY_TargetLine.nLineWidth')
RegisterCustomData('MY_TargetLine.nLineAlpha')
RegisterCustomData('MY_TargetLine.tTargetColor')
RegisterCustomData('MY_TargetLine.tTTargetColor')

function D.RequireRerender()
	C.bReRender = true
end

do
local function DrawShadowLine(sha, dwSrcID, dwDstID, aCol, nAlpha, nWidth)
	local r, g, b = unpack(aCol)
	sha:SetTriangleFan(GEOMETRY_TYPE.LINE, nWidth)
	sha:ClearTriangleFanPoint()
	sha:AppendCharacterID(dwSrcID, MY_TargetLine.bAtHead, r, g, b, nAlpha)
	sha:AppendCharacterID(dwDstID, MY_TargetLine.bAtHead, r, g, b, nAlpha)
	sha:Show()
end
local function GetShadow(szName)
	local hShaList = UI.GetShadowHandle('MY_TargetLine')
	local sha = hShaList:Lookup(szName)
	if not sha then
		hShaList:AppendItemFromString('<shadow>name="' .. szName .. '"</shadow>')
		sha = hShaList:Lookup(szName)
	end
	return sha
end
local bCurTargetRL, dwCurTarLineSrcID, dwCurTarLineDstID, shaTLine
local bCurTTargetRL, dwCurTTarLineSrcID, dwCurTTarLineDstID, shaTTLine
function D.UpdateLine()
	local me = GetClientPlayer()
	local tar = MY.GetObject(MY.GetTarget(me))
	local ttar = MY.GetObject(MY.GetTarget(tar))
	local dwTarLineSrcID, dwTarLineDstID, dwTTarLineSrcID, dwTTarLineDstID
	if me and tar and (not ttar or ttar.dwID ~= me.dwID) then
		dwTarLineSrcID = me.dwID
		dwTarLineDstID = tar.dwID
	end
	if me and tar and ttar then
		dwTTarLineSrcID = tar.dwID
		dwTTarLineDstID = ttar.dwID
	end

	-- show connect
	if dwCurTarLineSrcID ~= dwTarLineSrcID or dwCurTarLineDstID ~= dwTarLineDstID or bCurTargetRL ~= O.bTargetRL or C.bReRender then
		if bCurTargetRL ~= O.bTargetRL then
			if dwCurTarLineSrcID and dwCurTarLineDstID then
				if bCurTargetRL then
					if dwCurTarLineSrcID then
						rlcmd(('set target sfx connection %s %s %s'):format(dwCurTarLineSrcID, 0, 1))
					end
				else
					if shaTLine then
						shaTLine:Hide()
					end
				end
			end
			bCurTargetRL = O.bTargetRL
		end
		if O.bTarget and dwTarLineSrcID and dwTarLineDstID then
			if O.bTargetRL then
				rlcmd(('set target sfx connection %s %s %s'):format(dwTarLineSrcID, dwTarLineDstID, 1))
			else
				if not shaTLine then
					shaTLine = GetShadow('TLine')
				end
				DrawShadowLine(shaTLine, dwTarLineSrcID, dwTarLineDstID, O.tTargetColor, O.nLineAlpha, O.nLineWidth)
			end
		else
			if dwCurTarLineSrcID then
				rlcmd(('set target sfx connection %s %s %s'):format(dwCurTarLineSrcID, 0, 1))
			end
			if shaTLine then
				shaTLine:Hide()
			end
		end
		bCurTargetRL, dwCurTarLineSrcID, dwCurTarLineDstID = O.bTargetRL, dwTarLineSrcID, dwTarLineDstID
	end

	if dwCurTTarLineSrcID ~= dwTTarLineSrcID or dwCurTTarLineDstID ~= dwTTarLineDstID or bCurTTargetRL ~= O.bTTargetRL or C.bReRender then
		if bCurTTargetRL ~= O.bTTargetRL then
			if dwCurTTarLineSrcID and dwCurTTarLineDstID then
				if bCurTTargetRL then
					if dwCurTTarLineSrcID then
						rlcmd(('set target sfx connection %s %s %s'):format(dwCurTTarLineSrcID, 0, 1))
					end
				else
					if shaTTLine then
						shaTTLine:Hide()
					end
				end
			end
			bCurTTargetRL = O.bTTargetRL
		end
		if O.bTTarget and dwTTarLineSrcID and dwTTarLineDstID then
			if O.bTTargetRL then
				rlcmd(('set target sfx connection %s %s %s'):format(dwTTarLineSrcID, dwTTarLineDstID, 2))
			else
				if not shaTTLine then
					shaTTLine = GetShadow('TTLine')
				end
				DrawShadowLine(shaTTLine, dwTTarLineSrcID, dwTTarLineDstID, O.tTTargetColor, O.nLineAlpha, O.nLineWidth)
			end
		else
			if dwCurTTarLineSrcID then
				rlcmd(('set target sfx connection %s %s %s'):format(dwCurTTarLineSrcID, 0, 2))
			end
			if shaTTLine then
				shaTTLine:Hide()
			end
		end
		bCurTTargetRL, dwCurTTarLineSrcID, dwCurTTarLineDstID = O.bTTargetRL, dwTTarLineSrcID, dwTTarLineDstID
	end

	C.bReRender = false
end
end

function D.CheckEnable()
	if (O.bTarget or O.bTTarget) and not MY.IsShieldedVersion() then
		MY.BreatheCall('MY_TargetLine', D.UpdateLine)
	else
		MY.BreatheCall('MY_TargetLine', false)
	end
	D.RequireRerender()
	D.UpdateLine()
end
MY.RegisterInit('MY_TargetLine', D.CheckEnable)
MY.RegisterEvent('MY_SHIELDED_VERSION.MY_TargetLine', D.CheckEnable)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bTarget       = true,
				bTargetRL     = true,
				bTTarget      = true,
				bTTargetRL    = true,
				bAtHead       = true,
				nLineWidth    = true,
				nLineAlpha    = true,
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
				bTargetRL     = true,
				bTTarget      = true,
				bTTargetRL    = true,
				bAtHead       = true,
				nLineWidth    = true,
				nLineAlpha    = true,
				tTargetColor  = true,
				tTTargetColor = true,
			},
			triggers = {
				bTarget       = D.CheckEnable,
				bTargetRL     = D.RequireRerender,
				bTTarget      = D.CheckEnable,
				bTTargetRL    = D.RequireRerender,
				bAtHead       = D.RequireRerender,
				nLineWidth    = D.RequireRerender,
				nLineAlpha    = D.RequireRerender,
				tTargetColor  = D.RequireRerender,
				tTTargetColor = D.RequireRerender,
			},
			root = O,
		},
	},
}
MY_TargetLine = MY.GeneGlobalNS(settings)
end
