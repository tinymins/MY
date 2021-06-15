--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标面向显示 （台服用）
-- @ref      : 参考海鳗插件：目标面向显示
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetFace'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetFace'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_TargetFace', _L['MY_Target'], {
	bTargetFace = { -- 是否画出目标面向
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTTargetFace = { -- 是否画出目标的目标的面向
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nSectorDegree = { -- 扇形角度
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Number,
		xDefaultValue = 110,
	},
	nSectorRadius = { -- 扇形半径（尺）
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Number,
		xDefaultValue = 6,
	},
	nSectorAlpha = { -- 扇形透明度
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Number,
		xDefaultValue = 80,
	},
	tTargetFaceColor = { -- 目标面向颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 255, 0, 128 },
	},
	tTTargetFaceColor = { -- 目标的目标面向颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 0, 128, 255 },
	},
	bTargetShape = { -- 目标脚底圈圈
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTTargetShape = { -- 目标的目标脚底圈圈
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nShapeRadius = { -- 脚底圈圈半径
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Number,
		xDefaultValue = 2,
	},
	nShapeAlpha = { -- 脚底圈圈透明度
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Number,
		xDefaultValue = 100,
	},
	tTargetShapeColor = { -- 目标脚底圈圈颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 255, 0, 0 },
	},
	tTTargetShapeColor = { -- 目标的目标脚底圈圈颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetFace'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
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
	local nFace = ceil(128 * nDegree / 360)
	local dwRad1 = PI * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - PI - PI
	end
	local dwRad2 = dwRad1 + (nDegree / 180 * PI)
	local nAlpha2 = 0
	if nDegree == 360 then
		nAlpha, nAlpha2 = nAlpha2, nAlpha
		dwRad2 = dwRad2 + PI / 16
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
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + cos(dwRad1) * nRadius, tar.nY + sin(dwRad1) * nRadius)
		sha:AppendCharacterID(tar.dwID, false, col[1], col[2], col[3], nAlpha2, { sX_ - sX, 0, sZ_ - sZ })
		dwRad1 = dwRad1 + PI / 16
	until dwRad1 >= dwRad2
end

local function onBreathe()
	-- target face
	local dwTarType, dwTarID = LIB.GetTarget()
	local tar = LIB.GetObject(dwTarType, dwTarID)
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
	local dwTTarType, dwTTarID = LIB.GetTarget(tar)
	local ttar = LIB.GetObject(dwTTarType, dwTTarID)
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
	if D.bReady and not LIB.IsShieldedVersion('MY_TargetFace') and (O.bTargetFace or O.bTTargetFace or O.bTargetShape or O.bTTargetShape) then
		local hShaList = UI.GetShadowHandle('MY_TargetFace')
		for _, v in ipairs({'TargetFace', 'TargetShape', 'TTargetFace', 'TTargetShape'}) do
			local sha = hShaList:Lookup(v)
			if not sha then
				hShaList:AppendItemFromString('<shadow>name="' .. v .. '"</shadow>')
				sha = hShaList:Lookup(v)
			end
			C['sha' .. v] = sha
		end
		LIB.BreatheCall('MY_TargetFace', onBreathe)
	else
		for _, v in ipairs({'TargetFace', 'TargetShape', 'TTargetFace', 'TTargetShape'}) do
			local sha = C['sha' .. v]
			if sha and sha:IsValid() then
				sha:Hide()
			end
			C['sha' .. v] = nil
		end
		LIB.BreatheCall('MY_TargetFace', false)
	end
	D.RequireRerender()
end

LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_TargetFace', function()
	if arg0 and arg0 ~= 'MY_TargetFace' then
		return
	end
	D.CheckEnable()
end)
LIB.RegisterInit('MY_TargetFace', function()
	D.bReady = true
	D.CheckEnable()
end)
end

-- Global exports
do
local settings = {
	name = 'MY_TargetFace',
	exports = {
		{
			fields = {
				bTargetFace        = true,
				bTTargetFace       = true,
				nSectorDegree      = true,
				nSectorRadius      = true,
				nSectorAlpha       = true,
				tTargetFaceColor   = true,
				tTTargetFaceColor  = true,
				bTargetShape       = true,
				bTTargetShape      = true,
				nShapeRadius       = true,
				nShapeAlpha        = true,
				tTargetShapeColor  = true,
				tTTargetShapeColor = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bTargetFace        = true,
				bTTargetFace       = true,
				nSectorDegree      = true,
				nSectorRadius      = true,
				nSectorAlpha       = true,
				tTargetFaceColor   = true,
				tTTargetFaceColor  = true,
				bTargetShape       = true,
				bTTargetShape      = true,
				nShapeRadius       = true,
				nShapeAlpha        = true,
				tTargetShapeColor  = true,
				tTTargetShapeColor = true,
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
MY_TargetFace = LIB.CreateModule(settings)
end
