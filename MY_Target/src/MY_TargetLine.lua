--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标方位显示
-- @author   : Webster
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetLine'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local INI_PATH = PACKET_INFO.ROOT .. 'MY_Target/ui/MY_TargetLine.ini'
local IMG_PATH = PACKET_INFO.ROOT .. 'MY_Target/img/MY_TargetLine.uitex'

local O = LIB.CreateUserSettingsModule('MY_TargetLine', _L['MY_Target'], {
	bTarget = { -- 启用目标追踪线
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTargetRL = { -- 启用新版连线
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bTTarget = { -- 显示目标与目标的目标连接线
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTTargetRL = { -- 启用新版连线
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAtHead = { -- 连接线从头部开始
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	nLineWidth = { -- 连接线宽度
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Number,
		xDefaultValue = 3,
	},
	nLineAlpha = { -- 连接线不透明度
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Number,
		xDefaultValue = 150,
	},
	tTargetColor = { -- 颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 0, 255, 0 },
	},
	tTTargetColor = { -- 颜色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetLine'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 255, 0, 0 },
	},
})
local C, D = {}, {}

function D.RequireRerender()
	C.bReRender = true
end

do
local function DrawShadowLine(sha, dwSrcType, dwSrcID, dwDstType, dwDstID, aCol, nAlpha, nWidth)
	local r, g, b = unpack(aCol)
	sha:SetTriangleFan(GEOMETRY_TYPE.LINE, nWidth)
	sha:ClearTriangleFanPoint()
	if dwSrcType == TARGET.DOODAD then
		sha:AppendDoodadID(dwSrcID, r, g, b, nAlpha)
	else
		sha:AppendCharacterID(dwSrcID, MY_TargetLine.bAtHead, r, g, b, nAlpha)
	end
	if dwDstType == TARGET.DOODAD then
		sha:AppendDoodadID(dwDstID, r, g, b, nAlpha)
	else
		sha:AppendCharacterID(dwDstID, MY_TargetLine.bAtHead, r, g, b, nAlpha)
	end
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
	if not D.bReady then
		return
	end
	local me = GetClientPlayer()
	local dwTarType, dwTarID = LIB.GetTarget(me)
	local tar = LIB.GetObject(dwTarType, dwTarID)
	local dwTTarType, dwTTarID = LIB.GetTarget(tar)
	local ttar = LIB.GetObject(dwTTarType, dwTTarID)
	local dwTarLineSrcType, dwTarLineSrcID, dwTarLineDstType, dwTarLineDstID
	local dwTTarLineSrcType, dwTTarLineSrcID, dwTTarLineDstType, dwTTarLineDstID
	if not C.bShielded then
		if me and tar and (not ttar or ttar.dwID ~= me.dwID) then
			dwTarLineSrcType = TARGET.PLAYER
			dwTarLineSrcID = me.dwID
			dwTarLineDstType = dwTarType
			dwTarLineDstID = dwTarID
		end
		if me and tar and ttar then
			dwTTarLineSrcType = dwTarType
			dwTTarLineSrcID = dwTarID
			dwTTarLineDstType = dwTTarType
			dwTTarLineDstID = dwTTarID
		end
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
				DrawShadowLine(
					shaTLine,
					dwTarLineSrcType, dwTarLineSrcID,
					dwTarLineDstType, dwTarLineDstID,
					O.tTargetColor, O.nLineAlpha, O.nLineWidth)
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
				DrawShadowLine(
					shaTTLine,
					dwTTarLineSrcType, dwTTarLineSrcID,
					dwTTarLineDstType, dwTTarLineDstID,
					O.tTTargetColor, O.nLineAlpha, O.nLineWidth)
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
	C.bShielded = LIB.IsShieldedVersion('MY_TargetLine')
	if D.bReady and (O.bTarget or O.bTTarget) and not C.bShielded then
		LIB.BreatheCall('MY_TargetLine', D.UpdateLine)
	else
		LIB.BreatheCall('MY_TargetLine', false)
	end
	D.RequireRerender()
	D.UpdateLine()
end
LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_TargetLine', function()
	if arg0 and arg0 ~= 'MY_TargetLine' then
		return
	end
	D.CheckEnable()
end)
LIB.RegisterInit('MY_TargetLine', function()
	D.bReady = true
	D.CheckEnable()
end)

-- Global exports
do
local settings = {
	name = 'MY_TargetLine',
	exports = {
		{
			fields = {
				'bTarget',
				'bTargetRL',
				'bTTarget',
				'bTTargetRL',
				'bAtHead',
				'nLineWidth',
				'nLineAlpha',
				'tTargetColor',
				'tTTargetColor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bTarget',
				'bTargetRL',
				'bTTarget',
				'bTTargetRL',
				'bAtHead',
				'nLineWidth',
				'nLineAlpha',
				'tTargetColor',
				'tTTargetColor',
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
MY_TargetLine = LIB.CreateModule(settings)
end
