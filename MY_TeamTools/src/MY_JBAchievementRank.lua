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
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_JBAchievementRank', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	dwFightBeginTime = 0,
	szFightUUID = '',
	dwDamage = 0,
	dwTherapy = 0,
}

local BOSS_MAP_ACHIEVE_ACQUIRE = X.LoadLUAData({'temporary/achievement_rank.jx3dat', X.PATH_TYPE.GLOBAL}) -- 地图对应的上报成就表（远程）
local BOSS_ACHIEVE_ACQUIRE_LOG = {} -- 等待上传的首领击杀信息
local BOSS_ACHIEVE_ACQUIRE_STATE = {} -- 当前地图首领击杀状态
local DATA_FILE_OLD = {'data/boss_achieve_acquire.jx3dat', X.PATH_TYPE.ROLE}
local DATA_FILE = {'userdata/achievement_rank_acquire.jx3dat', X.PATH_TYPE.ROLE}

function D.LoadData()
	local szPathOld = X.FormatPath(DATA_FILE_OLD)
	local szPath = X.FormatPath(DATA_FILE)
	if IsLocalFileExist(szPathOld) then
		CPath.Move(szPathOld, szPath)
	end
	BOSS_ACHIEVE_ACQUIRE_LOG = X.LoadLUAData(szPath) or {}
end
X.RegisterInit('MY_JBAchievementRank', function()
	D.bReady = true
	D.LoadData()
end)

function D.SaveData()
	local aAchieveAcquireLog = X.Clone(BOSS_ACHIEVE_ACQUIRE_LOG)
	for _, rec in ipairs(aAchieveAcquireLog) do
		rec.bPending = nil
	end
	X.SaveLUAData(DATA_FILE, aAchieveAcquireLog)
end
X.RegisterFlush('MY_JBAchievementRank', D.SaveData)

X.RegisterEvent('MY_FIGHT_HINT', function()
	if arg0 then
		D.dwFightBeginTime = GetCurrentTime()
		D.szFightUUID = arg1
		D.dwDamage = 0
		D.dwTherapy = 0
	end
end)
X.RegisterEvent('SYS_MSG', function()
	if arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		-- 技能最终产生的效果（生命值的变化）；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID
		-- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResult：数值集合
		local KCaster = X.GetObject(arg1)
		if KCaster and not IsPlayer(arg1) and KCaster.dwEmployer and KCaster.dwEmployer ~= 0 then -- 宠物的数据算在主人统计中
			KCaster = X.GetObject(KCaster.dwEmployer)
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
	local szFightUUIDU = AnsiToUTF8(p.szFightUUID)
	local szURL = 'https://push.j3cx.com/api/achievement-rank/uploads?'
		.. X.EncodePostData(X.UrlEncode(X.SignPostData({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			server = szServerU,
			name = szNameU,
			leader = szLeaderU,
			teammate = szTeammateU,
			guid = szClientGUIDU,
			achieve = p.dwAchieveID,
			time = p.dwTime,
			fightBegin = p.dwFightBeginTime,
			fightDuring = p.nFightTime,
			fightUUID = szFightUUIDU,
			damage = p.dwDamage,
			therapy = p.dwTherapy,
			roleType = p.nRoleType,
			onymous = bOnymous and 1 or 0,
		}, 'MY_BKR_AhfB6aBL9o$8R9t3ka6Uk6@#^^KHLoMtZCdS@5e2@T')))
	--[[#DEBUG BEGIN]]
	X.Debug(szURL, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local tConfig = {
		url = szURL,
		driver = 'auto', mode = 'auto', method = 'auto',
		fulfilled = onfulfilled,
		complete = oncomplete,
	}
	X.Ajax(tConfig)
	X.EnsureAjax(tConfig)
end

function D.CheckUpdateAcquire()
	if not D.bReady or not O.bEnable then
		return
	end
	for _, p in ipairs(BOSS_ACHIEVE_ACQUIRE_LOG) do
		if not p.bPending then
			local szAchieve = X.GetAchievement(p.dwAchieveID).szName
			local szTime = X.FormatTime(p.dwTime, '%yyyy-%MM-%dd %hh:%mm:%ss')
			p.bPending = true
			X.Sysmsg(_L('Try share boss kill: %s - %ds (%s).', szAchieve, p.nFightTime / 1000, szTime))
			D.ShareBKR(p, true,
				function()
					for i, v in X.ipairs_r(BOSS_ACHIEVE_ACQUIRE_LOG) do
						if v.dwAchieveID == p.dwAchieveID then
							table.remove(BOSS_ACHIEVE_ACQUIRE_LOG, i)
						end
					end
					X.Sysmsg(_L('Share boss kill success: %s - %ds (%s).', szAchieve, p.nFightTime / 1000, szTime))
				end,
				function()
					for _, v in X.ipairs_r(BOSS_ACHIEVE_ACQUIRE_LOG) do
						if v.dwAchieveID == p.dwAchieveID then
							v.bPending = nil
						end
					end
				end)
		end
	end
end

function D.ShotAchievementAcquire()
	local me = GetClientPlayer()
	local aAcquired = {}
	for i = 1, g_tTable.Achievement:GetRowCount() do
		local achi = g_tTable.Achievement:GetRow(i)
		if me.IsAchievementAcquired(achi.dwID) then
			table.insert(aAcquired, achi.dwID)
		end
	end
	X.SaveLUAData({'userdata/achievement_acquire_shot.jx3dat', X.PATH_TYPE.ROLE}, aAcquired, { crc = false, passphrase = false })
end

function D.UpdateMapBossAchieveAcquire()
	if not BOSS_MAP_ACHIEVE_ACQUIRE then
		X.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = 'https://pull.j3cx.com/config/achievement-rank'
				.. '?l=' .. GLOBAL.GAME_LANG
				.. '&L=' .. GLOBAL.GAME_EDITION
				.. '&_=' .. GetCurrentTime(),
			success = function(html, status)
				local data = X.JsonDecode(html)
				if X.IsTable(data) then
					BOSS_MAP_ACHIEVE_ACQUIRE = data
					X.SaveLUAData(
						{'temporary/fbk-achieves.jx3dat', X.PATH_TYPE.GLOBAL},
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
	for _, dwAchieveID in ipairs(X.GetMapAchievements(dwMapID) or CONSTANT.EMPTY_TABLE) do
		local achi = X.GetAchievement(dwAchieveID)
		if achi and wstring.find(achi.szName, _L['Full win']) then
			table.insert(aMapAchievements, dwAchieveID)
		end
	end
	-- 初始化所有监听成就状态
	for _, dwAchieveID in X.sipairs(
		aMapAchievements,
		X.IsTable(BOSS_MAP_ACHIEVE_ACQUIRE) and BOSS_MAP_ACHIEVE_ACQUIRE[dwMapID] or CONSTANT.EMPTY_TABLE,
		X.IsTable(BOSS_MAP_ACHIEVE_ACQUIRE) and BOSS_MAP_ACHIEVE_ACQUIRE['*'] or CONSTANT.EMPTY_TABLE
	) do
		local achi = X.GetAchievement(dwAchieveID)
		if achi then
			for _, s in ipairs(X.SplitString(achi.szSubAchievements, '|', true)) do
				local dwSubAchieve = tonumber(s)
				if dwSubAchieve then
					tBossAchieveAcquireState[dwSubAchieve] = me.IsAchievementAcquired(dwSubAchieve)
				end
			end
			tBossAchieveAcquireState[dwAchieveID] = me.IsAchievementAcquired(dwAchieveID)
		end
	end
	--[[#DEBUG BEGIN]]
	if not X.IsEmpty(tBossAchieveAcquireState) then
		X.Debug('Current map boss achieve: ' .. X.EncodePostData(tBossAchieveAcquireState) .. '.', X.DEBUG_LEVEL.LOG)
	end
	--[[#DEBUG END]]
	BOSS_ACHIEVE_ACQUIRE_STATE = tBossAchieveAcquireState
end
X.RegisterEvent('LOADING_ENDING', 'MY_JBAchievementRank', D.UpdateMapBossAchieveAcquire)

X.RegisterEvent({
	'NEW_ACHIEVEMENT',
	'SYNC_ACHIEVEMENT_DATA',
	'UPDATE_ACHIEVEMENT_POINT',
	'UPDATE_ACHIEVEMENT_COUNT',
}, 'MY_JBAchievementRank', function()
	local me = GetClientPlayer()
	for dwAchieveID, bAcquired in pairs(BOSS_ACHIEVE_ACQUIRE_STATE) do
		if not bAcquired and me.IsAchievementAcquired(dwAchieveID) then
			local aTeammate, szLeader = {}, ''
			local team = X.IsInParty() and GetClientTeam()
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
					local guid = X.GetPlayerGUID(dwTarID) or 0
					if info then
						table.insert(aTeammate, info.szName .. ',' .. info.dwMountKungfuID .. ',' .. guid)
					end
				end
			else
				szLeader = me.szName
				table.insert(aTeammate, me.szName .. ',' .. UI_GetPlayerMountKungfuID())
			end
			local rec = {
				szServer = X.GetRealServer(2),
				szName = me.szName,
				szLeader = szLeader,
				szTeammate = table.concat(aTeammate, ';'),
				dwAchieveID = dwAchieveID,
				dwTime = GetCurrentTime(),
				dwFightBeginTime = D.dwFightBeginTime,
				szFightUUID = D.szFightUUID,
				dwDamage = D.dwDamage,
				nRoleType = me.nRoleType,
				nFightTime = X.GetFightTime(),
				szClientGUID = X.GetClientGUID(),
			}
			table.insert(BOSS_ACHIEVE_ACQUIRE_LOG, rec)
			BOSS_ACHIEVE_ACQUIRE_STATE[dwAchieveID] = true
			-- D.ShareBKR(rec, false)
		end
	end
	D.CheckUpdateAcquire()
	-- D.ShotAchievementAcquire()
end)

X.RegisterExit('MY_JBAchievementRank', D.ShotAchievementAcquire)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	nX = nPaddingX
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Dungeon Rank'], font = 27 }):Height() + 2

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		checked = MY_JBAchievementRank.bEnable,
		text = _L['Share boss kill'],
		oncheck = function(bChecked)
			MY_JBAchievementRank.bEnable = bChecked
		end,
		tip = _L['Share boss kill record for kill rank.'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('Text', {
		x = nX, y = nY, h = 25,
		text = _L['(Checked this option to join dungeon rank.)'],
		color = { 172, 172, 172 },
	}):AutoWidth():Width() + 5

	nLFY = nY + nLH
	return nX, nY, nLFY
end

-- Global exports
do
local settings = {
	name = 'MY_JBAchievementRank',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
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
MY_JBAchievementRank = X.CreateModule(settings)
end
