--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标方位显示
-- @author   : Webster
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Target/MY_TargetLine'
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetLine'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TargetLine', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_Target/ui/MY_TargetLine.ini'
local IMG_PATH = X.PACKET_INFO.ROOT .. 'MY_Target/img/MY_TargetLine.uitex'

local O = X.CreateUserSettingsModule('MY_TargetLine', _L['Target'], {
	bTarget = { -- 启用目标追踪线
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Display the line from self to target'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTargetRL = { -- 启用新版连线
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Display the line from self to target'],
			_L['New style'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTTarget = { -- 显示目标与目标的目标连接线
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Display the line target self to target target'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTTargetRL = { -- 启用新版连线
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Display the line target self to target target'],
			_L['New style'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAtHead = { -- 连接线从头部开始
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['From head to head'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nLineWidth = { -- 连接线宽度
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Line width'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Number,
		xDefaultValue = 3,
	},
	nLineAlpha = { -- 连接线不透明度
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Line alpha'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Number,
		xDefaultValue = 150,
	},
	tTargetColor = { -- 颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Display the line from self to target'],
			_L['Change color'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 0, 255, 0 },
	},
	tTTargetColor = { -- 颜色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Target'],
		szDescription = X.MakeCaption({
			_L['MY_TargetLine'],
			_L['Display the line target self to target target'],
			_L['Change color'],
		}),
		szRestriction = 'MY_TargetLine',
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
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
	local hShaList = X.UI.GetShadowHandle('MY_TargetLine')
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
	local me = X.GetClientPlayer()
	local dwTarType, dwTarID = X.GetCharacterTarget(me)
	local tar = X.GetTargetHandle(dwTarType, dwTarID)
	local dwTTarType, dwTTarID = X.GetCharacterTarget(tar)
	local ttar = X.GetTargetHandle(dwTTarType, dwTTarID)
	local dwTarLineSrcType, dwTarLineSrcID, dwTarLineDstType, dwTarLineDstID
	local dwTTarLineSrcType, dwTTarLineSrcID, dwTTarLineDstType, dwTTarLineDstID
	if not C.bRestricted then
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
	C.bRestricted = X.IsRestricted('MY_TargetLine')
	if D.bReady and (O.bTarget or O.bTTarget) and not C.bRestricted then
		X.BreatheCall('MY_TargetLine', D.UpdateLine)
	else
		X.BreatheCall('MY_TargetLine', false)
	end
	D.RequireRerender()
	D.UpdateLine()
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
MY_TargetLine = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('MY_RESTRICTION', 'MY_TargetLine', function()
	if arg0 and arg0 ~= 'MY_TargetLine' then
		return
	end
	D.CheckEnable()
end)

X.RegisterUserSettingsInit('MY_TargetLine', function()
	D.bReady = true
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
