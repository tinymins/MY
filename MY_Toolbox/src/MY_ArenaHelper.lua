--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 名剑大会自动切换团队频道
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_ArenaHelper'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^16.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ArenaHelper', _L['General'], {
	bRestoreAuthorityInfo = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoShowModel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoShowModelBattlefield = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

-- auto restore team authourity info in arena
do local l_tTeamInfo, l_bConfigEnd
X.RegisterEvent('ARENA_START', function() l_bConfigEnd = true end)
X.RegisterEvent('LOADING_ENDING', function() l_bConfigEnd = false end)
X.RegisterEvent('PARTY_DELETE_MEMBER', function() l_bConfigEnd = false end)
local function RestoreTeam()
	local me, team = X.GetClientPlayer(), GetClientTeam()
	if not l_tTeamInfo
	or not O.bRestoreAuthorityInfo
	or not X.IsLeader()
	or not me.IsInParty() or not X.IsInArena() then
		return
	end
	X.SetTeamInfo(l_tTeamInfo)
end
X.RegisterEvent('PARTY_ADD_MEMBER', RestoreTeam)

local function SaveTeam()
	local me, team = X.GetClientPlayer(), GetClientTeam()
	if not me.IsInParty() or not X.IsInArena() or l_bConfigEnd then
		return
	end
	l_tTeamInfo = X.GetTeamInfo()
end
X.RegisterEvent({'TEAM_AUTHORITY_CHANGED', 'PARTY_SET_FORMATION_LEADER', 'TEAM_CHANGE_MEMBER_GROUP'}, SaveTeam)
end

-- 进入JJC自动显示所有人物
do local l_bHideNpc, l_bHidePlayer, l_bShowParty, l_lock
X.RegisterEvent('ON_REPRESENT_CMD', function()
	if l_lock then
		return
	end
	if arg0 == 'show npc' or arg0 == 'hide npc' then
		l_bHideNpc = arg0 == 'hide npc'
	elseif arg0 == 'show player' or arg0 == 'hide player' then
		l_bHidePlayer = arg0 == 'hide player'
	elseif arg0 == 'show or hide party player 0' or 'show or hide party player 1' then
		l_bShowParty = arg0 == 'show or hide party player 1'
	end
end)
X.RegisterEvent('LOADING_END', function()
	if not O.bAutoShowModel and not O.bAutoShowModelBattlefield then
		return
	end
	if (X.IsInArena() and O.bAutoShowModel) or (X.IsInBattleField() and O.bAutoShowModelBattlefield) then
		l_lock = true
		rlcmd('show npc')
		rlcmd('show player')
		rlcmd('show or hide party player 0')
	else
		l_lock = true
		if l_bHideNpc then
			rlcmd('hide npc')
		else
			rlcmd('show npc')
		end
		if l_bHidePlayer then
			rlcmd('hide player')
		else
			rlcmd('show player')
		end
		if l_bShowParty then
			rlcmd('show or hide party player 1')
		else
			rlcmd('show or hide party player 0')
		end
		l_lock = false
	end
end)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	-- 名剑大会自动恢复队伍信息
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto restore team info in arena'],
		checked = MY_ArenaHelper.bRestoreAuthorityInfo,
		onCheck = function(bChecked)
			MY_ArenaHelper.bRestoreAuthorityInfo = bChecked
		end,
	})
	nY = nY + nLH

	-- 名剑大会战场自动取消屏蔽
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto cancel hide player in arena'],
		checked = MY_ArenaHelper.bAutoShowModel,
		onCheck = function(bChecked)
			MY_ArenaHelper.bAutoShowModel = bChecked
		end,
	}):Width() + 5

	-- 名剑大会战场自动取消屏蔽
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto cancel hide player in battlefield'],
		checked = MY_ArenaHelper.bAutoShowModelBattlefield,
		onCheck = function(bChecked)
			MY_ArenaHelper.bAutoShowModelBattlefield = bChecked
		end,
	}):Width() + 5

	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_ArenaHelper',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bRestoreAuthorityInfo',
				'bAutoShowModel',
				'bAutoShowModelBattlefield',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bRestoreAuthorityInfo',
				'bAutoShowModel',
				'bAutoShowModelBattlefield',
			},
			root = O,
		},
	},
}
MY_ArenaHelper = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
