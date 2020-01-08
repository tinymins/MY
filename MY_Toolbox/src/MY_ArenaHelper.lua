--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 竞技场自动切换团队频道
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bAutoSwitchTalkChannel = true,
	bRestoreAuthorityInfo = true,
	bAutoShowModel = true,
}
RegisterCustomData('MY_ArenaHelper.bAutoSwitchTalkChannel')
RegisterCustomData('MY_ArenaHelper.bRestoreAuthorityInfo')
RegisterCustomData('MY_ArenaHelper.bAutoShowModel')

function D.Apply()
	-- 竞技场自动切换团队频道
	if MY_ArenaHelper.bAutoSwitchTalkChannel then
		LIB.RegisterEvent('LOADING_ENDING.MY_ArenaHelper', function()
			local bIsBattleField = (GetClientPlayer().GetScene().nType == MAP_TYPE.BATTLE_FIELD)
			local nChannel, szName = EditBox_GetChannel()
			if bIsBattleField and (nChannel == PLAYER_TALK_CHANNEL.RAID or nChannel == PLAYER_TALK_CHANNEL.TEAM) then
				O.JJCAutoSwitchTalkChannel_OrgChannel = nChannel
				LIB.SwitchChat(PLAYER_TALK_CHANNEL.BATTLE_FIELD)
			elseif not bIsBattleField and nChannel == PLAYER_TALK_CHANNEL.BATTLE_FIELD then
				LIB.SwitchChat(O.JJCAutoSwitchTalkChannel_OrgChannel or PLAYER_TALK_CHANNEL.RAID)
			end
		end)
	else
		LIB.RegisterEvent('LOADING_ENDING.MY_ArenaHelper')
	end
end
LIB.RegisterInit('MY_ArenaHelper', D.Apply)

-- auto restore team authourity info in arena
do local l_tTeamInfo, l_bConfigEnd
LIB.RegisterEvent('ARENA_START', function() l_bConfigEnd = true end)
LIB.RegisterEvent('LOADING_ENDING', function() l_bConfigEnd = false end)
LIB.RegisterEvent('PARTY_DELETE_MEMBER', function() l_bConfigEnd = false end)
local function RestoreTeam()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not l_tTeamInfo
	or not O.bRestoreAuthorityInfo
	or not LIB.IsLeader()
	or not me.IsInParty() or not LIB.IsInArena() then
		return
	end
	LIB.SetTeamInfo(l_tTeamInfo)
end
LIB.RegisterEvent('PARTY_ADD_MEMBER', RestoreTeam)

local function SaveTeam()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me.IsInParty() or not LIB.IsInArena() or l_bConfigEnd then
		return
	end
	l_tTeamInfo = LIB.GetTeamInfo()
end
LIB.RegisterEvent({'TEAM_AUTHORITY_CHANGED', 'PARTY_SET_FORMATION_LEADER', 'TEAM_CHANGE_MEMBER_GROUP'}, SaveTeam)
end

-- 进入JJC自动显示所有人物
do local l_bHideNpc, l_bHidePlayer, l_bShowParty, l_lock
LIB.RegisterEvent('ON_REPRESENT_CMD', function()
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
LIB.RegisterEvent('LOADING_END', function()
	if not O.bAutoShowModel then
		return
	end
	if LIB.IsInArena() or LIB.IsInBattleField() then
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

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	-- 竞技场频道切换
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto switch talk channel when into battle field'],
		checked = MY_ArenaHelper.bAutoSwitchTalkChannel,
		oncheck = function(bChecked)
			MY_ArenaHelper.bAutoSwitchTalkChannel = bChecked
		end,
	})
	y = y + 25

	-- 竞技场自动恢复队伍信息
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto restore team info in arena'],
		checked = MY_ArenaHelper.bRestoreAuthorityInfo,
		oncheck = function(bChecked)
			MY_ArenaHelper.bRestoreAuthorityInfo = bChecked
		end,
	})
	y = y + 25

	-- 竞技场战场自动取消屏蔽
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto cancel hide player in arena and battlefield'],
		checked = MY_ArenaHelper.bAutoShowModel,
		oncheck = function(bChecked)
			MY_ArenaHelper.bAutoShowModel = bChecked
		end,
	})
	y = y + 25
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bAutoSwitchTalkChannel = true,
				bRestoreAuthorityInfo = true,
				bAutoShowModel = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bAutoSwitchTalkChannel = true,
				bRestoreAuthorityInfo = true,
				bAutoShowModel = true,
			},
			triggers = {
				bAutoSwitchTalkChannel = D.Apply,
			},
			root = O,
		},
	},
}
MY_ArenaHelper = LIB.GeneGlobalNS(settings)
end
