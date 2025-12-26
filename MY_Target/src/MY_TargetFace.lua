--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标面向显示 （台服用）
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Target/MY_TargetFace'
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetFace'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TargetFace', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_TargetFace', _L['Target'], {
	bTargetFace = { -- 是否画出目标面向
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the sector of target facing'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTTargetFace = { -- 是否画出目标的目标的面向
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the sector of target target facing'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nSectorDegree = { -- 扇形角度
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['The sector angle'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Number,
		xDefaultValue = 110,
	},
	nSectorRadius = { -- 扇形半径（尺）
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['The sector radius'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Number,
		xDefaultValue = 6,
	},
	nSectorAlpha = { -- 扇形透明度
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['The sector transparency'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Number,
		xDefaultValue = 80,
	},
	tTargetFaceColor = { -- 目标面向颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the sector of target facing'],
			_L['Color'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 255, 0, 128 },
	},
	tTTargetFaceColor = { -- 目标的目标面向颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the sector of target target facing'],
			_L['Color'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 0, 128, 255 },
	},
	bTargetShape = { -- 目标脚底圈圈
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the foot shape of target'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTTargetShape = { -- 目标的目标脚底圈圈
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the foot shape of target target'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nShapeRadius = { -- 脚底圈圈半径
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['The foot shape radius'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	nShapeAlpha = { -- 脚底圈圈透明度
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['The foot shape transparency'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Number,
		xDefaultValue = 100,
	},
	tTargetShapeColor = { -- 目标脚底圈圈颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the foot shape of target'],
			_L['Color'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 255, 0, 0 },
	},
	tTTargetShapeColor = { -- 目标的目标脚底圈圈颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetFace'],
			_L['Display the foot shape of target target'],
			_L['Color'],
		}),
		szRestriction = 'MY_TargetFace',
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 0, 0, 255 },
	},
})
local C, D = {}, {}

function D.RequireRerender()
	C.bReRender = true
end

do
local function DrawShape(tar, sha, nDegree, nRadius, nAlpha, col)
	nRadius = nRadius * 64
	local nFace = math.ceil(128 * nDegree / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end
	local dwRad2 = dwRad1 + (nDegree / 180 * math.pi)
	local nAlpha2 = 0
	if nDegree == 360 then
		nAlpha, nAlpha2 = nAlpha2, nAlpha
		dwRad2 = dwRad2 + math.pi / 16
	end
	-- orgina point
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLEFAN)
	sha:ClearTriangleFanPoint()
	sha:AppendCharacterID(tar.dwID, false, col[1], col[2], col[3], nAlpha)
	sha:Show()
	-- relative points
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	repeat
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + math.cos(dwRad1) * nRadius, tar.nY + math.sin(dwRad1) * nRadius)
		sha:AppendCharacterID(tar.dwID, false, col[1], col[2], col[3], nAlpha2, { sX_ - sX, 0, sZ_ - sZ })
		dwRad1 = dwRad1 + math.pi / 16
	until dwRad1 >= dwRad2
end

local function onBreathe()
	local me = X.GetClientPlayer()
	-- target face
	local dwTarType, dwTarID = X.GetCharacterTarget(me)
	local tar = X.GetTargetHandle(dwTarType, dwTarID)
	if O.bTargetFace and tar then
		DrawShape(tar, C.shaTargetFace, O.nSectorDegree, O.nSectorRadius, O.nSectorAlpha, O.tTargetFaceColor)
	elseif C.shaTargetFace and C.shaTargetFace:IsValid() then
		C.shaTargetFace:Hide()
	end
	-- foot shape
	if C.bReRender then
		if O.bTargetShape and tar then
			DrawShape(tar, C.shaTargetShape, 360, O.nShapeRadius / 2, O.nShapeAlpha, O.tTargetShapeColor)
		elseif C.shaTargetShape and C.shaTargetShape:IsValid() then
			C.shaTargetShape:Hide()
		end
	end
	-- target target face
	local dwTTarType, dwTTarID = X.GetCharacterTarget(tar)
	local ttar = X.GetTargetHandle(dwTTarType, dwTTarID)
	local bIsTarget = tar and dwTarID == dwTTarID
	if O.bTTargetFace and ttar and (not O.bTargetFace or not bIsTarget) then
		DrawShape(ttar, C.shaTTargetFace, O.nSectorDegree, O.nSectorRadius, O.nSectorAlpha, O.tTTargetFaceColor)
	elseif C.shaTTargetFace and C.shaTTargetFace:IsValid() then
		C.shaTTargetFace:Hide()
	end
	-- target target shape
	if C.bReRender then
		if O.bTTargetShape and ttar and (not O.bTargetShape or not bIsTarget) then
			DrawShape(ttar, C.shaTTargetShape, 360, O.nShapeRadius / 2, O.nShapeAlpha, O.tTTargetShapeColor)
		elseif C.shaTTargetShape and C.shaTTargetShape:IsValid() then
			C.shaTTargetShape:Hide()
		end
	end
	C.bReRender = false
end

function D.CheckEnable()
	if D.bReady and not X.IsRestricted('MY_TargetFace') and (O.bTargetFace or O.bTTargetFace or O.bTargetShape or O.bTTargetShape) then
		local hShaList = X.UI.GetShadowHandle('MY_TargetFace')
		for _, v in ipairs({'TargetFace', 'TargetShape', 'TTargetFace', 'TTargetShape'}) do
			local sha = hShaList:Lookup(v)
			if not sha then
				hShaList:AppendItemFromString('<shadow>name="' .. v .. '"</shadow>')
				sha = hShaList:Lookup(v)
			end
			C['sha' .. v] = sha
		end
		X.BreatheCall('MY_TargetFace', onBreathe)
	else
		for _, v in ipairs({'TargetFace', 'TargetShape', 'TTargetFace', 'TTargetShape'}) do
			local sha = C['sha' .. v]
			if sha and sha:IsValid() then
				sha:Hide()
			end
			C['sha' .. v] = nil
		end
		X.BreatheCall('MY_TargetFace', false)
	end
	D.RequireRerender()
end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetFace',
	exports = {
		{
			fields = {
				'bTargetFace',
				'bTTargetFace',
				'nSectorDegree',
				'nSectorRadius',
				'nSectorAlpha',
				'tTargetFaceColor',
				'tTTargetFaceColor',
				'bTargetShape',
				'bTTargetShape',
				'nShapeRadius',
				'nShapeAlpha',
				'tTargetShapeColor',
				'tTTargetShapeColor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bTargetFace',
				'bTTargetFace',
				'nSectorDegree',
				'nSectorRadius',
				'nSectorAlpha',
				'tTargetFaceColor',
				'tTTargetFaceColor',
				'bTargetShape',
				'bTTargetShape',
				'nShapeRadius',
				'nShapeAlpha',
				'tTargetShapeColor',
				'tTTargetShapeColor',
			},
			triggers = {
				bTargetFace        = D.CheckEnable,
				bTTargetFace       = D.CheckEnable,
				nSectorDegree      = D.RequireRerender,
				nSectorRadius      = D.RequireRerender,
				nSectorAlpha       = D.RequireRerender,
				tTargetFaceColor   = D.RequireRerender,
				tTTargetFaceColor  = D.RequireRerender,
				bTargetShape       = D.CheckEnable,
				bTTargetShape      = D.CheckEnable,
				nShapeRadius       = D.RequireRerender,
				nShapeAlpha        = D.RequireRerender,
				tTargetShapeColor  = D.RequireRerender,
				tTTargetShapeColor = D.RequireRerender,
			},
			root = O,
		},
	},
}
MY_TargetFace = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('MY_RESTRICTION', 'MY_TargetFace', function()
	if arg0 and arg0 ~= 'MY_TargetFace' then
		return
	end
	D.CheckEnable()
end)

X.RegisterUserSettingsInit('MY_TargetFace', function()
	D.bReady = true
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
