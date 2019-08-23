--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 圈圈连线
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_CC'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local TARGET = TARGET
local INI_SHADOW          = PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini'
local CIRCLE_MAX_RADIUS   = 30    -- 最大的半径
local CIRCLE_LINE_ALPHA   = 165   -- 线和边框最大透明度
local CIRCLE_MAX_CIRCLE   = 2
local CIRCLE_RESERT_DRAW  = false -- 全局重绘
local CIRCLE_DEFAULT_DATA = { bEnable = true, nAngle = 80, nRadius = 4, col = { 0, 255, 0 }, bBorder = true }
local CIRCLE_PANEL_ANCHOR = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
local CIRCLE_RULE = {
	[TARGET.NPC] = {},
	[TARGET.DOODAD] = {},
}
local CIRCLE_CACHE = {
	[TARGET.NPC] = {},
	[TARGET.DOODAD] = {},
}
local H_CIRCLE = UI.GetShadowHandle('Handle_Shadow_Circle')
local H_LINE = UI.GetShadowHandle('Handle_Shadow_Line')
local H_NAME = UI.GetShadowHandle('Handle_Shadow_Name')

local D = {}
local O = {
	bEnable = true,
	bBorder = true, -- 全局的边框模式 边框会造成卡
}
RegisterCustomData('MY_TeamMon_CC.bEnable')
RegisterCustomData('MY_TeamMon_CC.bBorder')

function D.UpdateRule()
	CIRCLE_RULE[TARGET.NPC] = {}
	local aData = MY_TeamMon and MY_TeamMon.GetTable and MY_TeamMon.GetTable('NPC')
	if aData then
		for _, data in spairs(aData[-1], aData[LIB.GetMapID()]) do
			if not IsEmpty(data.aCircle) or data.bDrawLine then
				CIRCLE_RULE[TARGET.NPC][data.dwID] = data
			end
		end
	end
	CIRCLE_RULE[TARGET.DOODAD] = {}
	local aData = MY_TeamMon and MY_TeamMon.GetTable and MY_TeamMon.GetTable('DOODAD')
	if aData then
		for _, data in spairs(aData[-1], aData[LIB.GetMapID()]) do
			if not IsEmpty(data.aCircle) or data.bDrawLine then
				CIRCLE_RULE[TARGET.DOODAD][data.dwID] = data
			end
		end
	end
	D.RescanNearby()
end

function D.DrawLine(dwType, tar, ttar, sha, col)
	sha:SetTriangleFan(GEOMETRY_TYPE.LINE, 3)
	sha:ClearTriangleFanPoint()
	local r, g, b = unpack(col)
	if dwType == TARGET.DOODAD then
		sha:AppendDoodadID(tar.dwID, r, g, b, CIRCLE_LINE_ALPHA)
	elseif dwType == TARGET.NPC then
		sha:AppendCharacterID(tar.dwID, true, r, g, b, CIRCLE_LINE_ALPHA)
	elseif dwType == 'Point' then -- 可能需要用到
		sha:AppendTriangleFan3DPoint(tar.nX, tar.nY, tar.nZ, r, g, b, CIRCLE_LINE_ALPHA)
	end
	sha:AppendCharacterID(ttar.dwID, true, r, g, b, CIRCLE_LINE_ALPHA)
	sha:Show()
end

function D.DrawShape(dwType, tar, sha, nAngle, nRadius, col, nAlpha)
	local nRadius = nRadius * 64
	local nFace = ceil(128 * nAngle / 360)
	local dwRad1 = PI * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - PI - PI
	end
	local dwRad2 = dwRad1 + (nAngle / 180 * PI)
	local nStep = 16
	if nAngle <= 45 then nStep = 180 end
	if nAngle == 360 then
		dwRad2 = dwRad2 + PI / 20
	end
	-- nAlpha 补偿
	if not nAlpha then
		nAlpha = 50
		local ap = 2.5 * (nRadius / 64)
		if ap > 35 then
			nAlpha = 15
		else
			nAlpha = nAlpha - ap
		end
		nAlpha = nAlpha + (360 - nAngle) / 6
	end
	local r, g, b = unpack(col)
	-- orgina point
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLEFAN)
	sha:ClearTriangleFanPoint()
	if dwType == TARGET.DOODAD then
		sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha)
	else
		sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha)
	end
	sha:Show()
	-- relative points
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	repeat
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + cos(dwRad1) * nRadius, tar.nY + sin(dwRad1) * nRadius)
		if dwType == TARGET.DOODAD then
			sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		else
			sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		end
		dwRad1 = dwRad1 + PI / nStep
	until dwRad1 > dwRad2
end

function D.DrawBorder(dwType, tar, sha, nAngle, nRadius, col)
	local nRadius = nRadius * 64
	local nThick = 1 + (5 * nRadius / 64 / 20)
	local nFace = ceil(128 * nAngle / 360)
	local dwRad1 = PI * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - PI - PI
	end
	local dwRad2 = dwRad1 + (nAngle / 180 * PI)
	local nStep = 16
	if nAngle <= 45 then nStep = 180 end
	if nAngle == 360 then
		dwRad2 = dwRad2 + PI / 20
	end
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	local r, g, b = unpack(col)
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLESTRIP)
	sha:ClearTriangleFanPoint()
	repeat
		local tRad = { nRadius, nRadius - nThick }
		for _, v in ipairs(tRad) do
			local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + cos(dwRad1) * v , tar.nY + sin(dwRad1) * v)
			if dwType == TARGET.DOODAD then
				sha:AppendDoodadID(tar.dwID, r, g, b, CIRCLE_LINE_ALPHA, { sX_ - sX, 0, sZ_ - sZ })
			else
				sha:AppendCharacterID(tar.dwID, false, r, g, b, CIRCLE_LINE_ALPHA, { sX_ - sX, 0, sZ_ - sZ })
			end
		end
		dwRad1 = dwRad1 + PI / nStep
	until dwRad1 > dwRad2
end

function D.DrawObject(dwType, dwID, KObject)
	local cache = CIRCLE_CACHE[dwType][dwID]
	if not cache then
		return
	end
	if not KObject then
		KObject = LIB.GetObject(dwType, dwID)
	end
	if not KObject then
		return
	end
	if cache.aCircle then
		for _, circle in ipairs(cache.aCircle) do
			if not circle.shaCircle or circle.shaCircle.nFaceDirection ~= KObject.nFaceDirection or CIRCLE_RESERT_DRAW then -- 第一次绘制、面向不对、强制重绘
				if not circle.shaCircle then
					circle.shaCircle = H_CIRCLE:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Circle')
				end
				circle.shaCircle.nFaceDirection = KObject.nFaceDirection
				D.DrawShape(dwType, KObject, circle.shaCircle, circle.nAngle, circle.nRadius, circle.col, circle.nAlpha)
			end
			if O.bBorder and circle.bBorder then
				if not circle.shaBorder or circle.shaBorder.nFaceDirection ~= KObject.nFaceDirection or CIRCLE_RESERT_DRAW then -- 第一次绘制、面向不对、强制重绘
					if not circle.shaBorder then
						circle.shaBorder = H_CIRCLE:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Border')
					end
					circle.shaBorder.nFaceDirection = KObject.nFaceDirection
					D.DrawBorder(dwType, KObject, circle.shaBorder, circle.nAngle, circle.nRadius, circle.col)
				end
			end
		end
	end
	if cache.bDrawLine then
		local dwTarType, dwTarID = TARGET.PLAYER, UI_GetClientPlayerID()
		if dwType == TARGET.NPC then
			dwTarType, dwTarID = KObject.GetTarget()
		end
		local tar = LIB.GetObject(dwTarType, dwTarID)
		if tar and dwTarType == TARGET.PLAYER and dwTarID ~= 0
		and (not cache.bDrawLineOnlyStareMe or dwTarID == UI_GetClientPlayerID()) then
			if not cache.shaLine or cache.shaLine.dwTarID ~= dwTarID then
				if not cache.shaLine then
					cache.shaLine = H_LINE:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Line')
				end
				cache.shaLine.dwTarID = dwTarID
				local r, g, b = 0, 255, 255
				if dwType == TARGET.NPC then
					if dwTarID == UI_GetClientPlayerID() then
						r, g, b = 255, 0, 128
					else
						r, g, b = 255, 255, 0
					end
				end
				D.DrawLine(dwType, KObject, tar, cache.shaLine, { r, g, b })
			end
		elseif cache.shaLine then
			local parent = cache.shaLine:GetParent()
			if parent then
				parent:RemoveItem(cache.shaLine)
			end
			cache.shaLine = nil
		end
	end
	if cache.bDrawName then
		local szText = cache.szNote or LIB.GetObjectName(KObject)
		if not cache.shaName or cache.shaName.szText ~= szText then
			if not cache.shaName then
				cache.shaName = H_NAME:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Name')
				cache.shaName:SetTriangleFan(GEOMETRY_TYPE.TEXT)
			end
			local r, g, b = 255, 128, 0
			if dwType == TARGET.DOODAD then
				cache.shaName:AppendDoodadID(dwID, r, g, b, 255, 50, 40, szText, 1, 1)
			else
				cache.shaName:AppendCharacterID(dwID, true, r, g, b, 255, 50, 40, szText, 1, 1)
			end
			cache.shaName.szText = szText
		end
	end
end

function D.OnObjectEnterScene(dwType, dwID)
	local tar = LIB.GetObject(dwType, dwID)
	local rule = CIRCLE_RULE[dwType][tar.dwTemplateID]
	if rule and (not rule.bDrawOnlyMyEmployer or dwType ~= TARGET.NPC or tar.dwEmployer == UI_GetClientPlayerID()) then
		local cache = setmetatable({}, { __index = rule })
		if rule.aCircle then
			local aCircle = {}
			for _, rule in ipairs(rule.aCircle) do
				insert(aCircle, setmetatable({}, { __index = rule }))
			end
			cache.aCircle = aCircle
		end
		CIRCLE_CACHE[dwType][dwID] = cache
	end
	D.DrawObject(dwType, dwID)
end

function D.OnObjectLeaveScene(dwType, dwID)
	local cache, parent = CIRCLE_CACHE[dwType][dwID]
	if cache then
		if cache.aCircle then
			for _, circle in ipairs(cache.aCircle) do
				if circle.shaCircle then
					parent = circle.shaCircle:GetParent()
					if parent then
						parent:RemoveItem(circle.shaCircle)
					end
				end
				circle.shaCircle = nil
				if circle.shaBorder then
					parent = circle.shaBorder:GetParent()
					if parent then
						parent:RemoveItem(circle.shaBorder)
					end
				end
				circle.shaBorder = nil
			end
		end
		if cache.shaLine then
			parent = cache.shaLine:GetParent()
			if parent then
				parent:RemoveItem(cache.shaLine)
			end
			cache.shaLine = nil
		end
		if cache.shaName then
			parent = cache.shaName:GetParent()
			if parent then
				parent:RemoveItem(cache.shaName)
			end
			cache.shaName = nil
		end
		CIRCLE_CACHE[dwType][dwID] = nil
	end
end

function D.OnBreathe()
	local me = GetClientPlayer()
	if not me then
		return
	end
	for dwID, cache in pairs(CIRCLE_CACHE[TARGET.NPC]) do
		D.DrawObject(TARGET.NPC, dwID)
	end
	for dwID, cache in pairs(CIRCLE_CACHE[TARGET.DOODAD]) do
		D.DrawObject(TARGET.DOODAD, dwID)
	end
	CIRCLE_RESERT_DRAW = false
end

function D.RescanNearby()
	H_CIRCLE:Clear()
	H_LINE:Clear()
	H_NAME:Clear()
	if LIB.IsShieldedVersion(2) then
		return
	end
	for _, dwID in pairs(LIB.GetNearNpcID()) do
		D.OnObjectEnterScene(TARGET.NPC, dwID)
	end
	for _, dwID in pairs(LIB.GetNearDoodadID()) do
		D.OnObjectEnterScene(TARGET.DOODAD, dwID)
	end
end

function D.OnTMDataReload()
	if arg0 and not arg0['NPC'] and not arg0['DOODAD'] then
		return
	end
	D.UpdateRule()
end

function D.CheckEnable()
	if O.bEnable and not LIB.IsShieldedVersion(2) then
		LIB.RegisterModuleEvent('MY_TeamMon_CC', {
			{ '#BREATHE', D.OnBreathe },
			{ 'NPC_ENTER_SCENE', function() D.OnObjectEnterScene(TARGET.NPC, arg0) end },
			{ 'NPC_LEAVE_SCENE', function() D.OnObjectLeaveScene(TARGET.NPC, arg0) end },
			{ 'DOODAD_ENTER_SCENE', function() D.OnObjectEnterScene(TARGET.DOODAD, arg0) end },
			{ 'DOODAD_LEAVE_SCENE', function() D.OnObjectLeaveScene(TARGET.DOODAD, arg0) end },
			{ 'LOADING_ENDING', D.UpdateRule },
			{ 'MY_TM_CC_RELOAD', D.UpdateRule },
			{ 'MY_TM_DATA_RELOAD', D.OnTMDataReload },
			{ 'MY_TM_CC_RESERT_DRAW', function() CIRCLE_RESERT_DRAW = true end }
		})
		D.UpdateRule()
	else
		LIB.RegisterModuleEvent('MY_TeamMon_CC', false)
	end
end

LIB.RegisterInit('MY_TeamMon_CC', D.CheckEnable)
LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_TeamMon_CC', D.CheckEnable)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bEnable = true,
				bBorder = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				bBorder = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_TeamMon_CC = LIB.GeneGlobalNS(settings)
end
