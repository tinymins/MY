--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 世界标记增强
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : Webster
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_WorldMark'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

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

local O = X.CreateUserSettingsModule('MY_WorldMark', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_WorldMark'],
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

function D.OnNpcEvent()
	local npc = X.GetNpc(arg0)
	if npc then
		local mark = WM_LIST[npc.dwTemplateID]
		if mark then
			local tPoint = { npc.nX, npc.nY, npc.nZ }
			local handle = X.UI.GetShadowHandle('Handle_World_Mark')
			local szName = 'w_' .. mark.id
			if handle:Lookup(szName) then
				handle:RemoveItem(szName)
			end
			WM_POINT[mark.id] = tPoint
		end
	end
end

function D.OnNpcLeave()
	local npc = X.GetNpc(arg0)
	if npc then
		local mark = WM_LIST[npc.dwTemplateID]
		if mark then
			local tPoint = WM_POINT[mark.id]
			if tPoint then
				local handle = X.UI.GetShadowHandle('Handle_World_Mark')
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
		X.UI.GetShadowHandle('Handle_World_Mark'):Clear()
	end
end

function D.OnDoSkillCast()
	D.OnCast(arg1)
end

function D.OnLoadingEnd()
	WM_POINT = {}
	X.UI.GetShadowHandle('Handle_World_Mark'):Clear()
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
	if O.bEnable and not X.IsRestricted('MY_WorldMark') then
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

function D.CheckEnable()
	X.RegisterModuleEvent('MY_WorldMark', D.GetEvent())
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_WorldMark',
	exports = {
		{
			fields = {
				'CheckEnable',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_WorldMark = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('MY_RESTRICTION', 'MY_WorldMark', function()
	if arg0 and arg0 ~= 'MY_WorldMark' then
		return
	end
	D.CheckEnable()
end)
X.RegisterUserSettingsInit('MY_WorldMark', D.CheckEnable)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
