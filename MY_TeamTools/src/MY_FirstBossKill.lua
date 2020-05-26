--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 分享首次击杀
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local D = {}
local O = {
	bEnable = false,
}
RegisterCustomData('MY_FirstBossKill.bEnable')

local BOSS_ACHIEVE_ACQUIRE_LOG = {} -- 等待上传的首领击杀信息
local BOSS_ACHIEVE_ACQUIRE_STATE = {} -- 当前地图首领击杀状态
local DATA_FILE = {'data/boss_achieve_acquire.jx3dat', PATH_TYPE.ROLE}

function D.LoadData()
	BOSS_ACHIEVE_ACQUIRE_LOG = LIB.LoadLUAData(DATA_FILE) or {}
end
LIB.RegisterInit('MY_FirstBossKill', D.LoadData)

function D.SaveData()
	local aAchieveAcquireLog = Clone(BOSS_ACHIEVE_ACQUIRE_LOG)
	for _, rec in ipairs(aAchieveAcquireLog) do
		rec.bPending = nil
	end
	LIB.SaveLUAData(DATA_FILE, aAchieveAcquireLog)
end
LIB.RegisterFlush('MY_FirstBossKill', D.SaveData)

function D.CheckUpdateAcquire()
	if not O.bEnable then
		return
	end
	for _, p in ipairs(BOSS_ACHIEVE_ACQUIRE_LOG) do
		if not p.bPending then
			local szServerU = AnsiToUTF8(p.szServer)
			local szNameU = AnsiToUTF8(p.szName)
			local szLeaderU = AnsiToUTF8(p.szLeader)
			local szTeammateU = AnsiToUTF8(p.szTeammate)
			local szAchieve = Table_GetAchievement(p.dwAchieveID).szName
			local szTime = LIB.FormatTime(p.dwTime, '%yyyy-%MM-%dd %hh:%mm:%ss')
			local nCRC = GetStringCRC('MY_BKR_AhfB6aBL9o$8R9t3ka6Uk6@#^^KHLoMtZCdS@5e2@T_'
				.. szServerU .. ','
				.. szNameU .. ','
				.. szLeaderU .. ','
				.. szTeammateU .. ','
				.. p.dwAchieveID .. ','
				.. p.dwTime .. ',' .. p.nFightTime)
			local szURL = 'https://bkr.uploads.j3cx.com/api/bkr/uploads?' .. LIB.EncodePostData(LIB.UrlEncode({
				s = szServerU,
				n = szNameU,
				l = szLeaderU,
				m = szTeammateU,
				a = p.dwAchieveID,
				t = p.dwTime,
				d = p.nFightTime,
				c = nCRC, _ = GetCurrentTime(),
			}))
			LIB.Sysmsg(_L('Try share boss kill: %s - %ds (%s).', szAchieve, p.nFightTime / 1000, szTime))
			--[[#DEBUG BEGIN]]
			LIB.Debug(szURL, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			local tConfig = {
				url = szURL,
				driver = 'auto', method = 'auto',
				fulfilled = function()
					for i, v in ipairs_r(BOSS_ACHIEVE_ACQUIRE_LOG) do
						if v.dwAchieveID == p.dwAchieveID then
							remove(BOSS_ACHIEVE_ACQUIRE_LOG, i)
						end
					end
					LIB.Sysmsg(_L('Share boss kill success: %s - %ds (%s).', szAchieve, p.nFightTime / 1000, szTime))
				end,
				complete = function()
					for _, v in ipairs_r(BOSS_ACHIEVE_ACQUIRE_LOG) do
						if v.dwAchieveID == p.dwAchieveID then
							v.bPending = nil
						end
					end
				end,
			}
			p.bPending = true
			LIB.Ajax(tConfig)
		end
	end
end

LIB.RegisterEvent('LOADING_ENDING.MY_FirstBossKill', function()
	if not LIB.IsInDungeon() then
		return
	end
	local me = GetClientPlayer()
	local dwMapID = me.GetMapID()
	local tBossAchieveAcquireState = {}
	for _, dwAchieveID in ipairs(LIB.GetMapAchievements(dwMapID) or CONSTANT.EMPTY_TABLE) do
		local achi = Table_GetAchievement(dwAchieveID)
		if achi and wfind(achi.szName, _L['Full win']) then
			for _, s in ipairs(LIB.SplitString(achi.szSubAchievements, '|', true)) do
				local dwSubAchieve = tonumber(s)
				if dwSubAchieve then
					tBossAchieveAcquireState[dwSubAchieve] = me.IsAchievementAcquired(dwSubAchieve)
				end
			end
			-- aBossAchieve[dwAchieveID] = me.IsAchievementAcquired(dwAchieveID)
		end
	end
	--[[#DEBUG BEGIN]]
	if not IsEmpty(tBossAchieveAcquireState) then
		LIB.Debug('Current map boss achieve: ' .. LIB.EncodePostData(tBossAchieveAcquireState) .. '.', DEBUG_LEVEL.LOG)
	end
	--[[#DEBUG END]]
	BOSS_ACHIEVE_ACQUIRE_STATE = tBossAchieveAcquireState
end)

LIB.RegisterEvent({
	'NEW_ACHIEVEMENT.MY_FirstBossKill',
	'SYNC_ACHIEVEMENT_DATA.MY_FirstBossKill',
	'UPDATE_ACHIEVEMENT_POINT.MY_FirstBossKill',
	'UPDATE_ACHIEVEMENT_COUNT.MY_FirstBossKill',
}, function()
	local me = GetClientPlayer()
	for dwAchieveID, bAcquired in pairs(BOSS_ACHIEVE_ACQUIRE_STATE) do
		if not bAcquired and me.IsAchievementAcquired(dwAchieveID) then
			local aTeammate, szLeader = {}, ''
			local team = GetClientTeam()
			if team then
				-- 队长
				local dwLeader = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
				local leader = dwLeader and team.GetMemberInfo(dwLeader)
				if leader then
					szLeader = leader.szName
				end
				-- 团员
				for _, dwTarID in ipairs(team.GetTeamMemberList()) do
					local info = team.GetMemberInfo(dwTarID)
					if info then
						insert(aTeammate, info.szName .. ',' .. info.dwMountKungfuID)
					end
				end
			end
			insert(BOSS_ACHIEVE_ACQUIRE_LOG, {
				szServer = LIB.GetRealServer(2),
				szName = me.szName,
				szLeader = szLeader,
				szTeammate = concat(aTeammate, ';'),
				dwAchieveID = dwAchieveID,
				dwTime = GetCurrentTime(),
				nFightTime = LIB.GetFightTime(),
			})
			BOSS_ACHIEVE_ACQUIRE_STATE[dwAchieveID] = true
		end
	end
	D.CheckUpdateAcquire()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		checked = MY_FirstBossKill.bEnable,
		text = _L['Share boss kill'],
		oncheck = function(bChecked)
			MY_FirstBossKill.bEnable = bChecked
		end,
		tip = _L['Share boss kill record for kill rank.'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	}):AutoWidth():Width() + 5
	y = y + 20
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
				bEnable = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			triggers = {
				bEnable = function(_, v)
					if v then
						D.CheckUpdateAcquire()
					end
				end,
			},
			root = O,
		},
	},
}
MY_FirstBossKill = LIB.GeneGlobalNS(settings)
end
