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
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/achievement-rank/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.8') then
	return
end
--------------------------------------------------------------------------
local D = {
	dwFightBeginTime = 0,
	dwDamage = 0,
	dwTherapy = 0,
}
local O = {
	bEnable = false,
}
RegisterCustomData('MY_AchievementRank.bEnable')

local BOSS_MAP_ACHIEVE_ACQUIRE = LIB.LoadLUAData({'temporary/fbk-achieves.jx3dat', PATH_TYPE.GLOBAL}) -- 地图对应的上报成就表（远程）
local BOSS_ACHIEVE_ACQUIRE_LOG = {} -- 等待上传的首领击杀信息
local BOSS_ACHIEVE_ACQUIRE_STATE = {} -- 当前地图首领击杀状态
local DATA_FILE = {'data/boss_achieve_acquire.jx3dat', PATH_TYPE.ROLE}

function D.LoadData()
	BOSS_ACHIEVE_ACQUIRE_LOG = LIB.LoadLUAData(DATA_FILE) or {}
end
LIB.RegisterInit('MY_AchievementRank', D.LoadData)

function D.SaveData()
	local aAchieveAcquireLog = Clone(BOSS_ACHIEVE_ACQUIRE_LOG)
	for _, rec in ipairs(aAchieveAcquireLog) do
		rec.bPending = nil
	end
	LIB.SaveLUAData(DATA_FILE, aAchieveAcquireLog)
end
LIB.RegisterFlush('MY_AchievementRank', D.SaveData)

LIB.RegisterEvent('MY_FIGHT_HINT', function()
	if arg0 then
		D.dwFightBeginTime = GetCurrentTime()
		D.dwDamage = 0
		D.dwTherapy = 0
	end
end)
LIB.RegisterEvent('SYS_MSG', function()
	if arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		-- 技能最终产生的效果（生命值的变化）；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID
		-- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResult：数值集合
		local KCaster = LIB.GetObject(arg1)
		if KCaster and not IsPlayer(arg1) and KCaster.dwEmployer and KCaster.dwEmployer ~= 0 then -- 宠物的数据算在主人统计中
			KCaster = LIB.GetObject(KCaster.dwEmployer)
		end
		if KCaster and KCaster.dwID == UI_GetClientPlayerID() then
			D.dwDamage = D.dwDamage + (arg9[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0)
			D.dwTherapy = D.dwTherapy + (arg9[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0)
		end
	end
end)

function D.ShareBKR(p, bOnymous, onfulfilled, oncomplete)
	local szServerU = AnsiToUTF8(p.szServer)
	local szNameU = AnsiToUTF8(p.szName)
	local szLeaderU = AnsiToUTF8(p.szLeader)
	local szTeammateU = AnsiToUTF8(p.szTeammate)
	local szClientGUIDU = AnsiToUTF8(p.szClientGUID)
	local szURL = 'https://push.j3cx.com/api/achievement-rank/uploads?'
		.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
			lang = AnsiToUTF8(LIB.GetLang()),
			server = szServerU,
			name = szNameU,
			leader = szLeaderU,
			teammate = szTeammateU,
			guid = szClientGUIDU,
			achieve = p.dwAchieveID,
			time = p.dwTime,
			fightBegin = p.dwFightBeginTime,
			fightDuring = p.nFightTime,
			damage = p.dwDamage,
			therapy = p.dwTherapy,
			roleType = p.nRoleType,
			onymous = bOnymous and 1 or 0,
		}, 'MY_BKR_AhfB6aBL9o$8R9t3ka6Uk6@#^^KHLoMtZCdS@5e2@T')))
	--[[#DEBUG BEGIN]]
	LIB.Debug(szURL, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local tConfig = {
		url = szURL,
		driver = 'auto', mode = 'auto', method = 'auto',
		fulfilled = onfulfilled,
		complete = oncomplete,
	}
	LIB.Ajax(tConfig)
	LIB.EnsureAjax(tConfig)
end

function D.CheckUpdateAcquire()
	if not O.bEnable then
		return
	end
	for _, p in ipairs(BOSS_ACHIEVE_ACQUIRE_LOG) do
		if not p.bPending then
			local szAchieve = Table_GetAchievement(p.dwAchieveID).szName
			local szTime = LIB.FormatTime(p.dwTime, '%yyyy-%MM-%dd %hh:%mm:%ss')
			p.bPending = true
			LIB.Sysmsg(_L('Try share boss kill: %s - %ds (%s).', szAchieve, p.nFightTime / 1000, szTime))
			D.ShareBKR(p, true,
				function()
					for i, v in ipairs_r(BOSS_ACHIEVE_ACQUIRE_LOG) do
						if v.dwAchieveID == p.dwAchieveID then
							remove(BOSS_ACHIEVE_ACQUIRE_LOG, i)
						end
					end
					LIB.Sysmsg(_L('Share boss kill success: %s - %ds (%s).', szAchieve, p.nFightTime / 1000, szTime))
				end,
				function()
					for _, v in ipairs_r(BOSS_ACHIEVE_ACQUIRE_LOG) do
						if v.dwAchieveID == p.dwAchieveID then
							v.bPending = nil
						end
					end
				end)
		end
	end
end

function D.UpdateMapBossAchieveAcquire()
	if not BOSS_MAP_ACHIEVE_ACQUIRE then
		LIB.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = 'https://cdn.j3cx.com/config/achievement-rank.json'
				.. '?lang=' .. LIB.GetLang()
				.. '&_=' .. GetCurrentTime(),
			success = function(html, status)
				local data = LIB.JsonDecode(html)
				if IsTable(data) then
					BOSS_MAP_ACHIEVE_ACQUIRE = data
					LIB.SaveLUAData(
						{'temporary/fbk-achieves.jx3dat', PATH_TYPE.GLOBAL},
						data)
					D.UpdateMapBossAchieveAcquire()
				end
			end,
		})
	end
	local me = GetClientPlayer()
	local dwMapID = me.GetMapID()
	local tBossAchieveAcquireState = {}
	-- 根据成就名称自动识别地图全胜成就
	local aMapAchievements = {}
	for _, dwAchieveID in ipairs(LIB.GetMapAchievements(dwMapID) or CONSTANT.EMPTY_TABLE) do
		local achi = Table_GetAchievement(dwAchieveID)
		if achi and wfind(achi.szName, _L['Full win']) then
			insert(aMapAchievements, dwAchieveID)
		end
	end
	-- 初始化所有监听成就状态
	for _, dwAchieveID in sipairs(
		aMapAchievements,
		IsTable(BOSS_MAP_ACHIEVE_ACQUIRE) and BOSS_MAP_ACHIEVE_ACQUIRE[dwMapID] or CONSTANT.EMPTY_TABLE,
		IsTable(BOSS_MAP_ACHIEVE_ACQUIRE) and BOSS_MAP_ACHIEVE_ACQUIRE['*'] or CONSTANT.EMPTY_TABLE
	) do
		local achi = Table_GetAchievement(dwAchieveID)
		if achi then
			for _, s in ipairs(LIB.SplitString(achi.szSubAchievements, '|', true)) do
				local dwSubAchieve = tonumber(s)
				if dwSubAchieve then
					tBossAchieveAcquireState[dwSubAchieve] = me.IsAchievementAcquired(dwSubAchieve)
				end
			end
			tBossAchieveAcquireState[dwAchieveID] = me.IsAchievementAcquired(dwAchieveID)
		end
	end
	--[[#DEBUG BEGIN]]
	if not IsEmpty(tBossAchieveAcquireState) then
		LIB.Debug('Current map boss achieve: ' .. LIB.EncodePostData(tBossAchieveAcquireState) .. '.', DEBUG_LEVEL.LOG)
	end
	--[[#DEBUG END]]
	BOSS_ACHIEVE_ACQUIRE_STATE = tBossAchieveAcquireState
end
LIB.RegisterEvent('LOADING_ENDING.MY_AchievementRank', D.UpdateMapBossAchieveAcquire)

LIB.RegisterEvent({
	'NEW_ACHIEVEMENT.MY_AchievementRank',
	'SYNC_ACHIEVEMENT_DATA.MY_AchievementRank',
	'UPDATE_ACHIEVEMENT_POINT.MY_AchievementRank',
	'UPDATE_ACHIEVEMENT_COUNT.MY_AchievementRank',
}, function()
	local me = GetClientPlayer()
	for dwAchieveID, bAcquired in pairs(BOSS_ACHIEVE_ACQUIRE_STATE) do
		if not bAcquired and me.IsAchievementAcquired(dwAchieveID) then
			local aTeammate, szLeader = {}, ''
			local team = LIB.IsInParty() and GetClientTeam()
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
					local guid = LIB.GetPlayerGUID(dwTarID) or 0
					if info then
						insert(aTeammate, info.szName .. ',' .. info.dwMountKungfuID .. ',' .. guid)
					end
				end
			else
				szLeader = me.szName
				insert(aTeammate, me.szName .. ',' .. UI_GetPlayerMountKungfuID())
			end
			local rec = {
				szServer = LIB.GetRealServer(2),
				szName = me.szName,
				szLeader = szLeader,
				szTeammate = concat(aTeammate, ';'),
				dwAchieveID = dwAchieveID,
				dwTime = GetCurrentTime(),
				dwFightBeginTime = D.dwFightBeginTime,
				dwDamage = D.dwDamage,
				nRoleType = me.nRoleType,
				nFightTime = LIB.GetFightTime(),
				szClientGUID = LIB.GetClientGUID(),
			}
			insert(BOSS_ACHIEVE_ACQUIRE_LOG, rec)
			BOSS_ACHIEVE_ACQUIRE_STATE[dwAchieveID] = true
			-- D.ShareBKR(rec, false)
		end
	end
	D.CheckUpdateAcquire()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		checked = MY_AchievementRank.bEnable,
		text = _L['Share boss kill'],
		oncheck = function(bChecked)
			MY_AchievementRank.bEnable = bChecked
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
MY_AchievementRank = LIB.GeneGlobalNS(settings)
end
