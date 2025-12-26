--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 圈圈连线
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_CircleLine'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_CircleLine'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_TeamMon_CircleLine', { ['*'] = true, exp = true })
--------------------------------------------------------------------------------
local TARGET = TARGET
local INI_SHADOW          = X.PACKET_INFO.UI_COMPONENT_ROOT .. 'Shadow.ini'
local CIRCLE_MAX_RADIUS   = 30    -- 最大的半径
local CIRCLE_LINE_ALPHA   = 240   -- 线和边框最大透明度
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
local H_CIRCLE = X.UI.GetShadowHandle('Handle_Shadow_Circle')
local H_LINE = X.UI.GetShadowHandle('Handle_Shadow_Line')
local H_NAME = X.UI.GetShadowHandle('Handle_Shadow_Name')

local O = X.CreateUserSettingsModule('MY_TeamMon_CircleLine', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_CircleLine'],
			_L['Enable circle'],
		}),
		szRestriction = 'MY_TeamMon_CircleLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bBorder = { -- 全局的边框模式 边框会造成卡
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_CircleLine'],
			_L['Circle border'],
		}),
		szRestriction = 'MY_TeamMon_CircleLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

function D.UpdateRule()
	if MY_TeamMon and MY_TeamMon.IterTable and MY_TeamMon.GetTable then
		CIRCLE_RULE[TARGET.NPC] = {}
		CIRCLE_RULE[TARGET.DOODAD] = {}
		for _, ds in ipairs({
			{ szType = 'NPC', dwType = TARGET.NPC},
			{ szType = 'DOODAD', dwType = TARGET.DOODAD},
		}) do
			for _, data in MY_TeamMon.IterTable(MY_TeamMon.GetTable(ds.szType), 0, true) do
				if not X.IsEmpty(data.aCircle) or data.bDrawLine then
					CIRCLE_RULE[ds.dwType][data.dwID] = data
				end
			end
		end
		D.RescanNearby()
	end
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
	local nFace = math.ceil(128 * nAngle / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end
	local dwRad2 = dwRad1 + (nAngle / 180 * math.pi)
	local nStep = 16
	if nAngle <= 45 then nStep = 180 end
	if nAngle == 360 then
		dwRad2 = dwRad2 + math.pi / 20
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
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + math.cos(dwRad1) * nRadius, tar.nY + math.sin(dwRad1) * nRadius)
		if dwType == TARGET.DOODAD then
			sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		else
			sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		end
		dwRad1 = dwRad1 + math.pi / nStep
	until dwRad1 > dwRad2
end

function D.DrawBorder(dwType, tar, sha, nAngle, nRadius, col)
	local nRadius = nRadius * 64
	local nThick = 1 + (5 * nRadius / 64 / 20)
	local nFace = math.ceil(128 * nAngle / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end
	local dwRad2 = dwRad1 + (nAngle / 180 * math.pi)
	local nStep = 16
	if nAngle <= 45 then nStep = 180 end
	if nAngle == 360 then
		dwRad2 = dwRad2 + math.pi / 20
	end
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	local r, g, b = unpack(col)
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLESTRIP)
	sha:ClearTriangleFanPoint()
	repeat
		local tRad = { nRadius, nRadius - nThick }
		for _, v in ipairs(tRad) do
			local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + math.cos(dwRad1) * v , tar.nY + math.sin(dwRad1) * v)
			if dwType == TARGET.DOODAD then
				sha:AppendDoodadID(tar.dwID, r, g, b, CIRCLE_LINE_ALPHA, { sX_ - sX, 0, sZ_ - sZ })
			else
				sha:AppendCharacterID(tar.dwID, false, r, g, b, CIRCLE_LINE_ALPHA, { sX_ - sX, 0, sZ_ - sZ })
			end
		end
		dwRad1 = dwRad1 + math.pi / nStep
	until dwRad1 > dwRad2
end

function D.DrawObject(dwType, dwID, KObject)
	local cache = CIRCLE_CACHE[dwType][dwID]
	if not cache then
		return
	end
	if not KObject then
		KObject = X.GetTargetHandle(dwType, dwID)
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
		local dwTarType, dwTarID = TARGET.PLAYER, X.GetClientPlayerID()
		if dwType == TARGET.NPC then
			dwTarType, dwTarID = KObject.GetTarget()
		end

		local tar = X.GetTargetHandle(dwTarType, dwTarID) or X.GetClientPlayer()

		if not cache.bDrawLineOnlyStareMe or dwTarID == X.GetClientPlayerID() then
			if not cache.shaLine or cache.shaLine.dwTarID ~= dwTarID then
				if not cache.shaLine then
					cache.shaLine = H_LINE:AppendItemFromIni(INI_SHADOW, 'Shadow', 'Shadow_Line')
				end
				cache.shaLine.dwTarID = dwTarID
				local r, g, b = 0, 255, 255
				if dwType == TARGET.NPC then
					if dwTarID == X.GetClientPlayerID() then
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
		local szText = cache.szNote or X.GetTargetName(dwType, dwID)
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
	local tar = X.GetTargetHandle(dwType, dwID)
	local rule = CIRCLE_RULE[dwType][tar.dwTemplateID]
	if rule and (not rule.bDrawOnlyMyEmployer or dwType ~= TARGET.NPC or tar.dwEmployer == X.GetClientPlayerID()) then
		local cache = setmetatable({}, { __index = rule })
		if rule.aCircle then
			local aCircle = {}
			for _, rule in ipairs(rule.aCircle) do
				table.insert(aCircle, setmetatable({}, { __index = rule }))
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
	local me = X.GetClientPlayer()
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
	if X.IsRestricted('MY_TeamMon_CircleLine') then
		return
	end
	for _, dwID in pairs(X.GetNearNpcID()) do
		D.OnObjectEnterScene(TARGET.NPC, dwID)
	end
	for _, dwID in pairs(X.GetNearDoodadID()) do
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
	if D.bReady and O.bEnable and not X.IsRestricted('MY_TeamMon_CircleLine') then
		X.RegisterModuleEvent('MY_TeamMon_CircleLine', {
			{ '#BREATHE', D.OnBreathe },
			{ 'NPC_ENTER_SCENE', function() D.OnObjectEnterScene(TARGET.NPC, arg0) end },
			{ 'NPC_LEAVE_SCENE', function() D.OnObjectLeaveScene(TARGET.NPC, arg0) end },
			{ 'DOODAD_ENTER_SCENE', function() D.OnObjectEnterScene(TARGET.DOODAD, arg0) end },
			{ 'DOODAD_LEAVE_SCENE', function() D.OnObjectLeaveScene(TARGET.DOODAD, arg0) end },
			{ 'LOADING_ENDING', D.UpdateRule },
			{ 'MY_TEAM_MON__CIRCLE_LINE__RELOAD', D.UpdateRule },
			{ 'MY_TEAM_MON_DATA_RELOAD', D.OnTMDataReload },
			{ 'MY_TEAM_MON__CIRCLE_LINE__RESERT_DRAW', function() CIRCLE_RESERT_DRAW = true end }
		})
		D.UpdateRule()
	else
		X.RegisterModuleEvent('MY_TeamMon_CircleLine', false)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_CircleLine',
	exports = {
		{
			fields = {
				'bEnable',
				'bBorder',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'bBorder',
			},
			triggers = {
				bEnable = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_TeamMon_CircleLine = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon_CircleLine', function()
	if arg0 and arg0 ~= 'MY_TeamMon_CircleLine' then
		return
	end
	D.CheckEnable()
end)
X.RegisterUserSettingsInit('MY_TeamMon_CircleLine', function()
	D.bReady = true
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
