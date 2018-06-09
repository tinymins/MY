-- @Author: Webster
-- @Date:   2016-02-24 00:09:06
-- @Last modified by:   Emil Zhai
-- @Last modified time: 2016-12-08 17:55:51

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')

local pairs, ipairs = pairs, ipairs
local GetCurrentTime = GetCurrentTime
local tinsert = table.insert
local GetPlayer, GetNpc, IsPlayer = GetPlayer, GetNpc, IsPlayer
local SKILL_RESULT_TYPE = SKILL_RESULT_TYPE
local MY_IsParty, MY_GetSkillName, MY_GetBuffName = MY.IsParty, MY.GetSkillName, MY.GetBuffName

local MAX_COUNT  = 5
local PLAYER_ID  = 0
local DAMAGE_LOG = {}
local DEATH_LOG  = {}

local function OnSkillEffectLog(dwCaster, dwTarget, nEffectType, dwSkillID, dwLevel, bCriticalStrike, nCount, tResult)
	if not tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE] then -- 没有反弹的情况下
		if not IsPlayer(dwTarget) or not MY_IsParty(dwTarget) and dwTarget ~= PLAYER_ID then -- 目标不是队友也不是自己
			return
		end
	else
		if not IsPlayer(dwCaster) or not MY_IsParty(dwCaster) and dwCaster ~= PLAYER_ID then -- 目标不是队友也不是自己
			return
		end
	end
	local KCaster = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
	local KTarget = IsPlayer(dwTarget) and GetPlayer(dwTarget) or GetNpc(dwTarget)

	local szSkill = nEffectType == SKILL_EFFECT_TYPE.SKILL and MY_GetSkillName(dwSkillID, dwLevel) or MY_GetBuffName(dwSkillID, dwLevel)
		-- 五类伤害
	if IsPlayer(dwTarget)
		and tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.POISON_DAMAGE]
	then
		local szCaster
		if KCaster then
			if IsPlayer(dwCaster) then
				szCaster = KCaster.szName
			else
				szCaster = MY.GetObjectName(KCaster)
			end
		else
			szCaster = _L['OUTER GUEST']
		end
		local key = dwTarget == PLAYER_ID and 'self' or dwTarget
		if not DAMAGE_LOG[key] then
			DAMAGE_LOG[key] = {}
		elseif DAMAGE_LOG[key][MAX_COUNT] then
			DAMAGE_LOG[key][MAX_COUNT] = nil
		end
		tinsert(DAMAGE_LOG[key], 1, {
			nCurrentTime    = GetCurrentTime(),
			szKiller        = szCaster,
			szSkill         = szSkill .. (nEffectType == SKILL_EFFECT_TYPE.BUFF and '(BUFF)' or ''),
			tResult         = tResult,
			bCriticalStrike = bCriticalStrike,
		})
	end
	-- 有反弹伤害
	if tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE] and IsPlayer(dwCaster) then
		local szTarget
		if KTarget then
			if IsPlayer(dwTarget) then
				szTarget = KTarget.szName
			else
				szTarget = MY.GetObjectName(KTarget)
			end
		else
			szTarget = _L['OUTER GUEST']
		end

		local key = dwCaster == PLAYER_ID and 'self' or dwCaster
		if not DAMAGE_LOG[key] then
			DAMAGE_LOG[key] = {}
		elseif DAMAGE_LOG[key][MAX_COUNT] then
			DAMAGE_LOG[key][MAX_COUNT] = nil
		end
		tinsert(DAMAGE_LOG[key], 1, {
			nCurrentTime    = GetCurrentTime(),
			szKiller        = szTarget,
			szSkill         = szSkill .. (nEffectType == SKILL_EFFECT_TYPE.BUFF and '(BUFF)' or ''),
			tResult         = tResult,
			bCriticalStrike = bCriticalStrike,
		})
	end
end

-- 意外摔伤 会触发这个日志
local function OnCommonHealthLog(dwCharacterID, nDeltaLife)
	-- 过滤非玩家和治疗日志
	if not IsPlayer(dwCharacterID) or nDeltaLife >= 0 then
		return
	end
	local p = GetPlayer(dwCharacterID)
	if not p then
		return
	end
	if MY_IsParty(dwCharacterID) or dwCharacterID == PLAYER_ID then
		local key = dwCharacterID == PLAYER_ID and 'self' or dwCharacterID
		if not DAMAGE_LOG[key] then
			DAMAGE_LOG[key] = {}
		elseif DAMAGE_LOG[key][MAX_COUNT] then
			DAMAGE_LOG[key][MAX_COUNT] = nil
		end
		tinsert(DAMAGE_LOG[key], 1, { nCurrentTime = GetCurrentTime(), nCount = nDeltaLife * -1 })
	end
end

local function OnSkill(dwCaster, dwSkillID, dwLevel)
	local p = GetPlayer(dwCaster)
	if not p then return end

	local key = dwCaster == PLAYER_ID and 'self' or dwCaster
	if not DAMAGE_LOG[key] then
		DAMAGE_LOG[key] = {}
	elseif DAMAGE_LOG[key][MAX_COUNT] then
		DAMAGE_LOG[key][MAX_COUNT] = nil
	end
	tinsert(DAMAGE_LOG[key], 1, {
		nCurrentTime = GetCurrentTime(),
		szKiller     = p.szName,
		szSkill      = MY_GetSkillName(dwSkillID, dwLevel),
	})
end
-- 这里的szKiller有个很大的坑
-- 因为策划不喜欢写模板名称 导致NPC名字全是空的 摔死和淹死也是空
-- 这就特别郁闷
local function OnDeath(dwCharacterID, dwKiller)
	if IsPlayer(dwCharacterID) and (MY_IsParty(dwCharacterID) or dwCharacterID == PLAYER_ID) then
		dwCharacterID = dwCharacterID == PLAYER_ID and 'self' or dwCharacterID
		DEATH_LOG[dwCharacterID] = DEATH_LOG[dwCharacterID] or {}
		local killer = (IsPlayer(dwKiller) and GetPlayer(dwKiller)) or (not IsPlayer(dwKiller) and GetNpc(dwKiller))
		local szKiller = killer and MY.GetObjectName(killer)
		if DAMAGE_LOG[dwCharacterID] then
			tinsert(DEATH_LOG[dwCharacterID], {
				nCurrentTime = GetCurrentTime(),
				data         = DAMAGE_LOG[dwCharacterID],
				szKiller     = szKiller
			})
		else
			tinsert(DEATH_LOG[dwCharacterID], {
				nCurrentTime = GetCurrentTime(),
				data         = { szCaster = szKiller },
				szKiller     = szKiller
			})
		end
		DAMAGE_LOG[dwCharacterID] = nil
		FireUIEvent('MY_RAIDTOOLS_DEATH', dwCharacterID)
	end
end

RegisterEvent('LOADING_END', function()
	DAMAGE_LOG = {}
	PLAYER_ID  = UI_GetClientPlayerID()
end)

RegisterEvent('SYS_MSG', function()
	if arg0 == 'UI_OME_DEATH_NOTIFY' then -- 死亡记录
		OnDeath(arg1, arg2)
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then -- 技能记录
		OnSkillEffectLog(arg1, arg2, arg4, arg5, arg6, arg7, arg8, arg9)
	elseif arg0 == 'UI_OME_COMMON_HEALTH_LOG' then
		OnCommonHealthLog(arg1, arg2)
	end
end)

RegisterEvent('DO_SKILL_CAST', function()
	if arg1 == 608 and IsPlayer(arg0) then -- 自觉经脉
		OnSkill(arg0, arg1, arg2)
	end
end)

function MY_RaidTools.GetDeathLog()
	return DEATH_LOG
end

function MY_RaidTools.ClearDeathLog()
	DEATH_LOG = {}
	FireUIEvent('MY_RAIDTOOLS_DEATH')
end
