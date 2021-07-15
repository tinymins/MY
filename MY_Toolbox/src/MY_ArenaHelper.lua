--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 竞技场自动切换团队频道
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_ArenaHelper', _L['General'], {
	bRestoreAuthorityInfo = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoShowModel = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

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

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	-- 竞技场自动恢复队伍信息
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Auto restore team info in arena'],
		checked = MY_ArenaHelper.bRestoreAuthorityInfo,
		oncheck = function(bChecked)
			MY_ArenaHelper.bRestoreAuthorityInfo = bChecked
		end,
	})
	y = y + deltaY

	-- 竞技场战场自动取消屏蔽
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Auto cancel hide player in arena and battlefield'],
		checked = MY_ArenaHelper.bAutoShowModel,
		oncheck = function(bChecked)
			MY_ArenaHelper.bAutoShowModel = bChecked
		end,
	})
	y = y + deltaY
	return x, y
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
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bRestoreAuthorityInfo',
				'bAutoShowModel',
			},
			root = O,
		},
	},
}
MY_ArenaHelper = LIB.CreateModule(settings)
end
