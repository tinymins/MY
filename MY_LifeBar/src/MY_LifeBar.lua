--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 扁平血条
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_LifeBar/MY_LifeBar'
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_LifeBar', { ['*'] = true })
X.RegisterRestriction('MY_LifeBar.MapRestriction', { ['*'] = true })
X.RegisterRestriction('MY_LifeBar.SpecialNpc', { ['*'] = true, intl = false })
--------------------------------------------------------------------------------

local Config = MY_LifeBar_Config
if not Config then
	return
end

local GetConfigValue, GetConfigComputeValue
do
local cfg, value, bInDungeon
function GetConfigValue(key, relation, force)
	cfg, value = Config[key][relation], nil
	if force == 'Npc' or force == 'Player' then
		value = cfg[force]
	else
		if cfg.DifferentiateForce then
			value = cfg[force]
		end
		if value == nil then
			value = Config[key][relation]['Player']
		end
	end
	return value
end
function GetConfigComputeValue(key, relation, force, bFight, bPet, bCurrentTarget, bFullLife)
	cfg = GetConfigValue(key, relation, force)
	if not cfg then
		return false
	end
	if not cfg.bEnable then
		return false
	end
	if cfg.bOnlyFighting and not bFight then
		return false
	end
	if cfg.bHideFullLife and bFullLife then
		return false
	end
	if cfg.bHidePets and bPet then
		return false
	end
	if cfg.bHideInDungeon and bInDungeon then
		return false
	end
	if cfg.bOnlyTarget and not bCurrentTarget then
		return false
	end
	return true
end
X.RegisterEvent('LOADING_ENDING', 'MY_LifeBar__GetConfigComputeValue', function()
	bInDungeon = X.IsInDungeonMap()
end)
end
-----------------------------------------------------------------------------------------

local NPC_HIDDEN = X.CONSTANT.NPC_HIDDEN
local LB_CACHE = {}
local TONG_NAME_CACHE = {}
local NPC_CACHE = {}
local PLAYER_CACHE = {}
local COUNTDOWN_CACHE = {}
local LAST_FIGHT_STATE = false
local SYS_HEAD_TOP_STATE
local LB = MY_LifeBar_LB
local CHANGGE_REAL_SHADOW_TPLID = 46140 -- 清绝歌影 的主体影子
local OBJECT_SCREEN_POS_Y_CACHE = {}
local OBJECT_TITLE_EFFECT, OVERWRITE_TITLE_EFFECT = {}, {}
local DRAW_TARGET_TYPE, DRAW_TARGET_ID, LB_ADJUST_INDEX_ID = TARGET.PLAYER, nil, nil
do -- 头顶特效数据刷新
local QUEST_TITLE_EFFECT = {
	['normal_unaccept_proper'] = 1,
	['repeat_unaccept_proper'] = 2,
	['activity_unaccept_proper'] = 45,
	['unaccept_high'] = 5,
	['unaccept_low'] = 6,
	['unaccept_lower'] = 43,
	['accpeted'] = 44,
	['normal_finished'] = 3,
	['repeat_finished'] = 4,
	['activity_finished'] = 46,
	['normal_notneedaccept'] = 44,
	['repeat_notneedaccept'] = 4,
	['activity_notneedaccept'] = 46,
	['lishijie_unaccept'] = 55,
	['lishijie_finished'] = 54,
}
local function UpdateTitleEffect(dwType, dwID)
	local nEffectID = nil
	if dwType == TARGET.PLAYER then
		local nMark = X.GetCharacterTeamMark(dwID)
		if nMark and PARTY_TITLE_MARK_EFFECT_LIST[nMark] then
			nEffectID = PARTY_TITLE_MARK_EFFECT_LIST[nMark]
		end
	elseif dwType == TARGET.NPC then
		local npc = X.GetNpc(dwID)
		if npc then
			local aQuestState = GetNpcQuestState(npc) or {}
			if aQuestState.normal_finished_proper or aQuestState.normal_finished_high or aQuestState.normal_finished_higher
			or aQuestState.normal_finished_low or aQuestState.normal_finished_lower or aQuestState.repeat_finished_proper
			or aQuestState.repeat_finished_high or aQuestState.repeat_finished_higher or aQuestState.repeat_finished_low
			or aQuestState.repeat_finished_lower or aQuestState.activity_finished_proper or aQuestState.activity_finished_high
			or aQuestState.activity_finished_higher or aQuestState.activity_finished_low or aQuestState.activity_finished_lower then
				nEffectID = QUEST_TITLE_EFFECT.normal_finished
			elseif aQuestState.activity_unaccept_proper then
				nEffectID = QUEST_TITLE_EFFECT.activity_unaccept_proper
			elseif aQuestState.normal_unaccept_proper then
				nEffectID = QUEST_TITLE_EFFECT.normal_unaccept_proper
			elseif aQuestState.repeat_unaccept_proper then
				nEffectID = QUEST_TITLE_EFFECT.repeat_unaccept_proper
			elseif aQuestState.activity_notneedaccept_proper or aQuestState.activity_notneedaccept_low or aQuestState.activity_notneedaccept_lower
			or aQuestState.activity_notneedaccept_high or aQuestState.activity_notneedaccept_higher then
				nEffectID = QUEST_TITLE_EFFECT.activity_notneedaccept
			elseif aQuestState.repeat_notneedaccept_proper or aQuestState.repeat_notneedaccept_low or aQuestState.repeat_notneedaccept_lower
			or aQuestState.repeat_notneedaccept_high or aQuestState.repeat_notneedaccept_higher then
				nEffectID = QUEST_TITLE_EFFECT.repeat_notneedaccept
			elseif aQuestState.normal_notneedaccept_proper then
			-- or aQuestState.normal_notneedaccept_low or aQuestState.normal_notneedaccept_lower
			-- or aQuestState.normal_notneedaccept_high or aQuestState.normal_notneedaccept_higher
				nEffectID = QUEST_TITLE_EFFECT.normal_notneedaccept
			elseif X.GetCharacterTeamMark(dwID) and PARTY_TITLE_MARK_EFFECT_LIST[X.GetCharacterTeamMark(dwID)] then -- party mark
				nEffectID = PARTY_TITLE_MARK_EFFECT_LIST[X.GetCharacterTeamMark(dwID)]
			elseif aQuestState.normal_unaccept_high or aQuestState.repeat_unaccept_high or aQuestState.activity_unaccept_high then
				nEffectID = QUEST_TITLE_EFFECT.unaccept_high
			elseif aQuestState.normal_unaccept_low or aQuestState.repeat_unaccept_low or aQuestState.activity_unaccept_low then
				nEffectID = QUEST_TITLE_EFFECT.unaccept_low
			elseif aQuestState.normal_unaccept_lower or aQuestState.repeat_unaccept_lower or aQuestState.activity_unaccept_lower then
				nEffectID = QUEST_TITLE_EFFECT.unaccept_lower
			elseif aQuestState.normal_accepted_proper or aQuestState.normal_accepted_low
			or aQuestState.normal_accepted_lower or aQuestState.normal_accepted_high -- or aQuestState.normal_accepted_higher
			or aQuestState.repeat_accepted_proper or aQuestState.repeat_accepted_high -- or aQuestState.repeat_accepted_higher
			or aQuestState.repeat_accepted_low or aQuestState.repeat_accepted_lower or aQuestState.activity_accepted_proper
			or aQuestState.activity_accepted_low or aQuestState.activity_accepted_lower or aQuestState.activity_accepted_high then
				nEffectID = QUEST_TITLE_EFFECT.accpeted
			end
		end
	end
	OBJECT_TITLE_EFFECT[dwID] = nEffectID and X.GetGlobalEffect(nEffectID)
	OVERWRITE_TITLE_EFFECT[dwID] = not OBJECT_TITLE_EFFECT[dwID] -- 强刷系统头顶
end
local function onPlayerStateUpdate()
	UpdateTitleEffect(TARGET.PLAYER, arg0)
end
X.RegisterEvent('PLAYER_STATE_UPDATE', 'MY_LifeBar', onPlayerStateUpdate)

local function onNpcQuestMarkUpdate()
	UpdateTitleEffect(TARGET.NPC, arg0)
end
X.RegisterEvent('QUEST_MARK_UPDATE', 'MY_LifeBar', onNpcQuestMarkUpdate)
X.RegisterEvent('NPC_DISPLAY_DATA_UPDATE', 'MY_LifeBar', onNpcQuestMarkUpdate)

local function onNpcQuestMarkUpdateAll()
	for _, dwID in ipairs(X.GetNearNpcID()) do
		UpdateTitleEffect(TARGET.NPC, dwID)
	end
end
X.RegisterEvent('LEAVE_STORY_MODE', 'MY_LifeBar', onNpcQuestMarkUpdateAll)
X.RegisterInit('MY_LifeBar_onNpcQuestMarkUpdateAll', onNpcQuestMarkUpdateAll)

local function onPartySetMark()
	local tID = {}
	for dwID, _ in pairs(OBJECT_TITLE_EFFECT) do
		tID[dwID] = true
	end
	for dwID, _ in pairs(GetClientTeam().GetTeamMark() or {}) do
		tID[dwID] = true
	end
	for dwID, _ in pairs(tID) do
		UpdateTitleEffect(X.IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC, dwID)
	end
	OVERWRITE_TITLE_EFFECT = {}
end
X.RegisterInit('MY_LifeBar_onPartySetMark', onPartySetMark)
X.RegisterEvent('PARTY_SET_MARK', 'MY_LifeBar', onPartySetMark)
X.RegisterEvent('PARTY_DELETE_MEMBER', 'MY_LifeBar', function()
	local me = X.GetClientPlayer()
	if me.dwID == arg1 then
		onPartySetMark()
	end
end)
X.RegisterEvent('PARTY_DISBAND', 'MY_LifeBar', onPartySetMark)
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', 'MY_LifeBar', onPartySetMark)

local function onLoadingEnd()
	OVERWRITE_TITLE_EFFECT = {}
end
X.RegisterEvent('LOADING_END', onLoadingEnd)
end

local O = X.CreateUserSettingsModule('MY_LifeBar', _L['General'], {
	bEnabled = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['Enable'],
		}),
		szRestriction = 'MY_LifeBar',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoHideSysHeadtop = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['Auto hide system headtop'],
		}),
		szRestriction = 'MY_LifeBar',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

function D.IsShielded()
	if X.IsRestricted('MY_LifeBar') then
		return true
	end
	return X.IsRestricted('MY_LifeBar.MapRestriction') and X.IsInShieldedMap()
end

function D.IsEnabled()
	return D.bReady and O.bEnabled and not D.IsShielded()
end

function D.IsMapEnabled()
	return D.IsEnabled() and (
		not (
			Config.bOnlyInDungeon or
			Config.bOnlyInArena or
			Config.bOnlyInBattleField
		) or (
			(Config.bOnlyInDungeon     and X.IsInDungeonMap()) or
			(Config.bOnlyInArena       and X.IsInArenaMap()) or
			(Config.bOnlyInBattleField and (X.IsInBattlefieldMap() or X.IsInPubgMap() or X.IsInZombieMap()))
		)
	)
end

function D.GetNz(nZ,nZ2)
	return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

function D.GetRelation(dwSrcID, dwTarID, KSrc, KTar)
	if Config.nCamp == -1 or not X.IsPlayer(dwTarID) then
		return X.GetCharacterRelation(dwSrcID, dwTarID)
	else
		if not KTar then
			return 'Neutrality'
		elseif dwTarID == dwSrcID then
			return 'Self'
		elseif IsParty(dwSrcID, dwTarID) then
			return 'Party'
		elseif X.IsFoe(dwTarID) then
			return 'Foe'
		elseif KTar.nCamp == Config.nCamp then
			return 'Ally'
		elseif not KTar.bCampFlag        -- 没开阵营
		or KTar.nCamp == CAMP.NEUTRAL    -- 目标中立
		or Config.nCamp == CAMP.NEUTRAL -- 自己中立
		or KSrc.GetScene().nCampType == MAP_CAMP_TYPE.ALL_PROTECT then -- 停战地图
			return 'Neutrality'
		else
			return 'Enemy'
		end
	end
end

function D.GetForce(dwType, dwID, KObject)
	if dwType == TARGET.PLAYER then
		return KObject and KObject.dwForceID or 0
	else
		return 'Npc'
	end
end

function D.GetTongName(dwTongID)
	if not X.IsNumber(dwTongID) or dwTongID == 0 then
		return
	end
	if not TONG_NAME_CACHE[dwTongID] then
		TONG_NAME_CACHE[dwTongID] = X.GetTongName(dwTongID)
	end
	if TONG_NAME_CACHE[dwTongID] then
		return TONG_NAME_CACHE[dwTongID]
	end
end

function D.AutoSwitchSysHeadTop()
	if not Config('loaded') then
		return
	end
	if D.bReady and Config.eCss == '' and D.IsMapEnabled() then
		Config('reset')
	end
	if D.bReady and O.bAutoHideSysHeadtop and D.IsMapEnabled() then
		D.SaveSysHeadTop()
		D.HideSysHeadTop()
	else
		D.ResumeSysHeadTop()
	end
end
function D.HideSysHeadTop()
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC, X.CONSTANT.GLOBAL_HEAD.NAME , false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC, X.CONSTANT.GLOBAL_HEAD.TITLE, false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC, X.CONSTANT.GLOBAL_HEAD.LIFE , false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER, X.CONSTANT.GLOBAL_HEAD.NAME , false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER, X.CONSTANT.GLOBAL_HEAD.TITLE, false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER, X.CONSTANT.GLOBAL_HEAD.LIFE , false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER, X.CONSTANT.GLOBAL_HEAD.GUILD, false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.NAME , false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.TITLE, false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.LIFE , false)
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.GUILD, false)
	X.SafeCall(_G.SetGlobalTopIntelligenceLife, false)
	X.SafeCall(_G.Addon_ShowNpcBalloon, false)
	X.SafeCall(_G.Addon_ShowPlayerBalloon, false)
end
function D.SaveSysHeadTop()
	if SYS_HEAD_TOP_STATE then
		return
	end
	SYS_HEAD_TOP_STATE = {
		['NPC_NAME'          ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC         , X.CONSTANT.GLOBAL_HEAD.NAME ),
		['NPC_TITLE'         ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC         , X.CONSTANT.GLOBAL_HEAD.TITLE),
		['NPC_LIFE'          ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC         , X.CONSTANT.GLOBAL_HEAD.LIFE ),
		['OTHERPLAYER_NAME'  ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.NAME ),
		['OTHERPLAYER_TITLE' ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.TITLE),
		['OTHERPLAYER_LIFE'  ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.LIFE ),
		['OTHERPLAYER_GUILD' ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.GUILD),
		['CLIENTPLAYER_NAME' ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.NAME ),
		['CLIENTPLAYER_TITLE'] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.TITLE),
		['CLIENTPLAYER_LIFE' ] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.LIFE ),
		['CLIENTPLAYER_GUILD'] = GetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.GUILD),
		['INTELLIGENCE_LIFE' ] = select(2, X.SafeCall(_G.GetGlobalTopIntelligenceLife)),
		['NPC_BALLOON'       ] = select(2, X.SafeCall(_G.Addon_IsNpcBalloon)),
		['PLAYER_BALLOON'    ] = select(2, X.SafeCall(_G.Addon_IsPlayerBalloon)),
	}
end
function D.ResumeSysHeadTop()
	if not SYS_HEAD_TOP_STATE then
		return
	end
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC         , X.CONSTANT.GLOBAL_HEAD.NAME , SYS_HEAD_TOP_STATE['NPC_NAME'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC         , X.CONSTANT.GLOBAL_HEAD.TITLE, SYS_HEAD_TOP_STATE['NPC_TITLE'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.NPC         , X.CONSTANT.GLOBAL_HEAD.LIFE , SYS_HEAD_TOP_STATE['NPC_LIFE'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.NAME , SYS_HEAD_TOP_STATE['OTHERPLAYER_NAME'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.TITLE, SYS_HEAD_TOP_STATE['OTHERPLAYER_TITLE'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.LIFE , SYS_HEAD_TOP_STATE['OTHERPLAYER_LIFE'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.OTHERPLAYER , X.CONSTANT.GLOBAL_HEAD.GUILD, SYS_HEAD_TOP_STATE['OTHERPLAYER_GUILD'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.NAME , SYS_HEAD_TOP_STATE['CLIENTPLAYER_NAME'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.TITLE, SYS_HEAD_TOP_STATE['CLIENTPLAYER_TITLE'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.LIFE , SYS_HEAD_TOP_STATE['CLIENTPLAYER_LIFE'])
	SetGlobalTopHeadFlag(X.CONSTANT.GLOBAL_HEAD.CLIENTPLAYER, X.CONSTANT.GLOBAL_HEAD.GUILD, SYS_HEAD_TOP_STATE['CLIENTPLAYER_GUILD'])
	X.SafeCall(_G.SetGlobalTopIntelligenceLife, SYS_HEAD_TOP_STATE['INTELLIGENCE_LIFE'])
	X.SafeCall(_G.Addon_ShowNpcBalloon, SYS_HEAD_TOP_STATE['NPC_BALLOON'])
	X.SafeCall(_G.Addon_ShowPlayerBalloon, SYS_HEAD_TOP_STATE['PLAYER_BALLOON'])
	SYS_HEAD_TOP_STATE = nil
end

function D.Repaint()
	for _, lb in pairs(LB_CACHE) do
		lb:Paint(true)
	end
end
X.RegisterEvent('UI_SCALED', D.Repaint)

function D.UpdateShadowHandleParam()
	local sh = X.UI.GetShadowHandle('MY_LifeBar')
	if not sh then
		return
	end
	if Config.bShowWhenUIHide then
		sh:ShowWhenUIHide()
	else
		sh:HideWhenUIHide()
	end
end

function D.Reset()
	if not D.bUserPreferencesReady then
		return
	end
	-- 重置缓存
	LB_CACHE = {}
	LB('clear')
	D.UpdateShadowHandleParam()
	-- 恢复官方标记
	for dwID, _ in pairs(OVERWRITE_TITLE_EFFECT) do
		if OBJECT_TITLE_EFFECT[dwID] then
			SceneObject_SetTitleEffect(X.IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC, dwID, OBJECT_TITLE_EFFECT[dwID].nID)
		end
	end
	OVERWRITE_TITLE_EFFECT = {}
	-- 自适应遮挡顺序
	if D.bReady and O.bEnabled and Config.bScreenPosSort then
		local dwLastID, nCount
		local function onGetCharacterTopScreenPos(dwID, xScreen, yScreen)
			OBJECT_SCREEN_POS_Y_CACHE[dwID] = yScreen or 0
		end
		local function onBreathe()
			nCount = 0
			repeat
				if LB_ADJUST_INDEX_ID and LB_CACHE[LB_ADJUST_INDEX_ID] == nil then
					LB_ADJUST_INDEX_ID = nil
				end
				LB_ADJUST_INDEX_ID = next(LB_CACHE, LB_ADJUST_INDEX_ID)
				if LB_ADJUST_INDEX_ID then
					PostThreadCall(onGetCharacterTopScreenPos, LB_ADJUST_INDEX_ID, 'Scene_GetCharacterTopScreenPos', LB_ADJUST_INDEX_ID)
				end
				nCount = nCount + 1
			until nCount > 30 or LB_ADJUST_INDEX_ID == dwLastID
			dwLastID = LB_ADJUST_INDEX_ID
		end
		X.BreatheCall('MY_LifeBar_ScreenPosSort', onBreathe)
	else
		X.BreatheCall('MY_LifeBar_ScreenPosSort', false)
	end
	D.AutoSwitchSysHeadTop()
end
X.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED', D.Reset)
X.RegisterEvent('LOADING_END', D.AutoSwitchSysHeadTop)
X.RegisterEvent('MY_RESTRICTION', D.Reset)
X.RegisterEvent('COINSHOP_ON_CLOSE', D.AutoSwitchSysHeadTop)

do
local CheckInvalidRect
do
local bRestrictedVersion = X.IsRestricted('MY_LifeBar.SpecialNpc')
X.RegisterEvent('MY_RESTRICTION', function()
	if arg0 and arg0 ~= 'MY_LifeBar.SpecialNpc' then
		return
	end
	bRestrictedVersion = X.IsRestricted('MY_LifeBar.SpecialNpc')
end)
local function fxTarget(r, g, b, a) return 255 - (255 - r) * 0.3, 255 - (255 - g) * 0.3, 255 - (255 - b) * 0.3, a end
local function fxDeath(r, g, b, a) return math.ceil(r * 0.4), math.ceil(g * 0.4), math.ceil(b * 0.4), a end
local function fxDeathTarget(r, g, b, a) return math.ceil(r * 0.45), math.ceil(g * 0.45), math.ceil(b * 0.45), a end
local lb, info, bVisible, bFight, nDisX, nDisY, nDisZ, fTextScale, dwTarType, dwTarID, relation, force, nPriority, szName, szTongName, r, g, b
local aCountDown, szCountDown, bPet, bShowName, bShowKungfu, kunfu, bShowTong, bShowTitle, bShowLife, bShowLifePercent, tEffect, fCurrentLife, fMaxLife
local bSpecialNpcVisible, bShowDistance, bCurrentTarget, bFullLife
local function IsSpecialNpcVisible(dwID, me, object)
	if not X.IsBoolean(bSpecialNpcVisible) then
		bSpecialNpcVisible = false
		if object.dwTemplateID == CHANGGE_REAL_SHADOW_TPLID and (not bRestrictedVersion or not IsEnemy(me.dwID, dwID)) then
			bSpecialNpcVisible = true
		elseif not bRestrictedVersion
		and Config.bShowSpecialNpc and (not bRestrictedVersion or X.IsInDungeonMap())
		and (not Config.bShowSpecialNpcOnlyEnemy or IsEnemy(me.dwID, dwID)) then
			bSpecialNpcVisible = true
		end
	end
	return bSpecialNpcVisible
end
function CheckInvalidRect(dwType, dwID, me, object)
	lb = LB_CACHE[dwID]
	info = dwType == TARGET.PLAYER and me.IsPlayerInMyParty(dwID) and GetClientTeam().GetMemberInfo(dwID) or nil
	if not object then
		if lb then
			lb:Remove()
			LB_CACHE[dwID] = nil
		end
		return
	end
	bVisible = true
	bSpecialNpcVisible = nil
	bCurrentTarget = dwID == dwTarID
	-- 显示标记判断
	if bVisible and (dwType == TARGET.NPC or dwType == TARGET.PLAYER) and X.IsCharacterIsolated(me) ~= X.IsCharacterIsolated(object) then
		bVisible = false
	end
	-- 距离判断
	if bVisible and Config.nDistance > 0 then
		nDisX, nDisY, nDisZ = me.nX - object.nX, me.nY - object.nY, (me.nZ - object.nZ) * 0.125
		bVisible = nDisX * nDisX + nDisY * nDisY + nDisZ * nDisZ < Config.nDistance
	end
	-- 高度差判断
	if bVisible and Config.nVerticalDistance > 0 then
		bVisible = me.nZ - object.nZ < Config.nVerticalDistance
	end
	-- 这是镜头补偿判断 但是不好用先不加
	-- if bVisible then
	-- 	bVisible = fPitch > -0.8 or D.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5
	-- end
	if bVisible and dwType == TARGET.NPC and NPC_HIDDEN[object.dwTemplateID] then
		bVisible = false
	end
	if bVisible then
		if not lb then
			-- 创建和设置不会改变的东西
			lb = LB(dwType, dwID)
			lb:SetDistanceFmt('%.' .. Config.nDistanceDecimal .. 'f' .. g_tStrings.STR_METER)
			lb:SetDistance(0)
			LB_CACHE[dwID] = lb
		end
		bFight = X.IsFighting()
		fTextScale = Config.fTextScale
		dwTarType, dwTarID = me.GetTarget()
		relation = D.GetRelation(me.dwID, dwID, me, object)
		force = D.GetForce(dwType, dwID, object)
		fCurrentLife, fMaxLife = X.GetCharacterLife(info)
		bFullLife = fCurrentLife == fMaxLife
		nPriority = OBJECT_SCREEN_POS_Y_CACHE[dwID] or 0 -- 默认根据屏幕坐标排序
		if Config.bMineOnTop and dwType == TARGET.PLAYER and dwID == me.dwID then -- 自身永远最前
			nPriority = nPriority + 20000
		end
		if Config.bTargetOnTop and bCurrentTarget then -- 目标永远最前
			nPriority = nPriority + 10000
		end
		szName = X.GetTargetName(dwType, dwID, {
			eShowID = Config.bShowObjectID and (Config.bShowObjectIDOnlyUnnamed and 'auto' or 'always') or 'never',
			bShowSuffix = false,
			bShowServerName = false,
		})
		bPet = dwType == TARGET.NPC and object.dwEmployer ~= 0 and X.IsPlayer(object.dwEmployer)
		if MY_ChatMosaics and MY_ChatMosaics.MosaicsString and szName and (dwType == TARGET.PLAYER or bPet) then
			szName = MY_ChatMosaics.MosaicsString(szName)
		end
		-- 常规配色
		r, g, b = unpack(GetConfigValue('Color', relation, force) or {255, 255, 255})
		-- 倒计时/名字/帮会/称号部分
		aCountDown, szCountDown = COUNTDOWN_CACHE[dwID], ''
		while aCountDown and #aCountDown > 0 do
			local tData, szText, nSec, fPer = aCountDown[1], nil, nil, nil
			if tData.szType == 'BUFF' or tData.szType == 'DEBUFF' then
				local KBuff = object.GetBuff(tData.dwBuffID, 0)
				if KBuff then
					nSec = (KBuff.GetEndTime() - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
					szText = tData.szText or X.GetBuffName(KBuff.dwID, KBuff.nLevel)
					if KBuff.nStackNum > 1 then
						szText = szText .. 'x' .. KBuff.nStackNum
					end
				end
			elseif tData.szType == 'CASTING' then
				local nType, dwSkillID, dwSkillLevel, fCastPercent = X.GetCharacterOTActionState(object)
				if dwSkillID == tData.dwSkillID
				and (
					nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
					or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
					or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE
				) then
					fPer = fCastPercent
					szText = tData.szText or X.GetSkillName(dwSkillID, dwSkillLevel)
				end
			elseif tData.szType == 'NPC' or tData.szType == 'DOODAD' then
				szText = tData.szText or ''
			else --if tData.szType == 'TIME' then
				if tData.nLogicFrame then
					nSec = (tData.nLogicFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
				elseif tData.nTime then
					nSec = (tData.nTime - GetTime()) / 1000
				end
				if nSec > 0 then
					szText = tData.szText or ''
				end
			end
			if nSec and nSec <= 0 then
				nSec = nil
			end
			if fPer and fPer <= 0 then
				fPer = nil
			end
			if szText then
				if tData.tColor then
					r, g, b = unpack(tData.tColor)
				end
				nPriority = nPriority + 100000
				fTextScale = fTextScale * 1.15
				if not X.IsEmpty(szText) and not tData.bHideProgress then
					if nSec then
						szCountDown = X.FormatDuration(math.min(nSec, 5999), 'PRIME')
					elseif fPer then
						szCountDown = math.floor(fPer * 100) .. '%'
					end
					szCountDown = szText .. '_' .. szCountDown
				end
				break
			else
				table.remove(aCountDown, 1)
			end
		end
		lb:SetCD(szCountDown)
		-- 名字
		bShowName = GetConfigComputeValue('ShowName', relation, force, bFight, bPet, bCurrentTarget, bFullLife)
		if bShowName and dwType == TARGET.NPC and not object.CanSeeName() then
			bShowName = IsSpecialNpcVisible(dwID, me, object)
		end
		if bShowName then
			lb:SetName(szName)
		end
		lb:SetNameVisible(bShowName)
		-- 心法
		bShowKungfu = Config.bShowKungfu and dwType == TARGET.PLAYER and dwID ~= me.dwID
		if bShowKungfu then
			kunfu = object.GetKungfuMount()
			if kunfu and kunfu.dwSkillID and kunfu.dwSkillID ~= 0 then
				lb:SetKungfu(X.GetKungfuName(kunfu.dwSkillID, 'short'))
			else
				lb:SetKungfu(g_tStrings.tForceTitle[object.dwForceID])
			end
		end
		lb:SetKungfuVisible(bShowKungfu)
		-- 距离
		bShowDistance = Config.bShowDistance and (not Config.bShowDistanceOnlyTarget or bCurrentTarget)
		if bShowDistance then
			lb:SetDistance(X.GetCharacterDistance(me, object))
		end
		lb:SetDistanceVisible(bShowDistance)
		-- 帮会
		bShowTong = GetConfigComputeValue('ShowTong', relation, force, bFight, bPet, bCurrentTarget, bFullLife)
		if bShowTong then
			szTongName = D.GetTongName(object.dwTongID) or ''
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString and szTongName and (dwType == TARGET.PLAYER or bPet) then
				szTongName = MY_ChatMosaics.MosaicsString(szTongName)
			end
			lb:SetTong(szTongName)
		end
		lb:SetTongVisible(bShowTong)
		-- 称号
		bShowTitle = GetConfigComputeValue('ShowTitle', relation, force, bFight, bPet, bCurrentTarget, bFullLife)
		if bShowTitle then
			lb:SetTitle(object.szTitle or '')
		end
		lb:SetTitleVisible(bShowTitle)
		-- 血条部分
		if not fCurrentLife or fMaxLife == 0 then
			fCurrentLife, fMaxLife = X.GetCharacterLife(object)
		end
		lb:SetLife(fCurrentLife, fMaxLife)
		bShowLife = szName ~= '' and GetConfigComputeValue('ShowLife', relation, force, bFight, bPet, bCurrentTarget, bFullLife)
		if bShowLife and dwType == TARGET.NPC and not object.CanSeeLifeBar() then
			bShowLife = IsSpecialNpcVisible(dwID, me, object)
		end
		if bShowLife then
			lb:SetLifeBar(Config.nLifeOffsetX, Config.nLifeOffsetY, Config.nLifeWidth, Config.nLifeHeight, Config.nLifePadding)
			lb:SetLifeBarBorder(Config.nLifeBorder, Config.nLifeBorderR, Config.nLifeBorderG, Config.nLifeBorderB)
		end
		lb:SetLifeBarVisible(bShowLife)
		-- 血量数值部分
		bShowLifePercent = GetConfigComputeValue('ShowLifePer', relation, force, bFight, bPet, bCurrentTarget, bFullLife)
		if bShowLifePercent and dwType == TARGET.NPC and not object.CanSeeLifeBar() then
			bShowLifePercent = IsSpecialNpcVisible(dwID, me, object)
		end
		if bShowLifePercent then
			lb:SetLifeText(Config.nLifePerOffsetX, Config.nLifePerOffsetY, Config.bHideLifePercentageDecimal and '%.0f' or '%.1f')
		end
		lb:SetLifeTextVisible(bShowLifePercent)
		-- 头顶特效
		tEffect = OBJECT_TITLE_EFFECT[dwID]
		if tEffect then
			lb:SetSFX(tEffect.szFilePath, tEffect.fScale * Config.fTitleEffectScale, Config.nTitleEffectOffsetY, tEffect.nWidth, tEffect.nHeight)
		else
			lb:ClearSFX()
		end
		-- 各种数据生效
		lb:SetScale(X.GetUIScale() * (Config.bSystemUIScale and X.GetUIScale() or 1) * Config.fGlobalUIScale)
		lb:SetColor(r, g, b, Config.nAlpha)
		lb:SetColorFx(
			object.nMoveState == MOVE_STATE.ON_DEATH
			and (bCurrentTarget and fxDeathTarget or fxDeath)
			or (bCurrentTarget and fxTarget or nil)
		)
		lb:SetFont(Config.nFont)
		lb:SetTextsPos(Config.nTextOffsetY, Config.nTextLineHeight)
		lb:SetTextsScale((Config.bSystemUIScale and X.GetFontScale() or 1) * fTextScale)
		lb:SetTextsSpacing(Config.fTextSpacing)
		lb:SetPriority(nPriority)
		lb:Create():Paint()
	elseif lb then
		lb:Remove()
		LB_CACHE[dwID] = nil
	end
	-- 屏蔽官方标记
	if OBJECT_TITLE_EFFECT[dwID] and not OVERWRITE_TITLE_EFFECT[dwID] and lb then
		OVERWRITE_TITLE_EFFECT[dwID] = true
		SceneObject_SetTitleEffect(dwType, dwID, TITLE_EFFECT_NONE)
	elseif OVERWRITE_TITLE_EFFECT[dwID] and not lb then
		if OBJECT_TITLE_EFFECT[dwID] then
			SceneObject_SetTitleEffect(dwType, dwID, OBJECT_TITLE_EFFECT[dwID].nID)
		end
		OVERWRITE_TITLE_EFFECT[dwID] = nil
	end
end
end

do
local nRoundLeft, nRoundLimit = 0, 50 -- 每帧最大重绘血条数量
local dwLastType, dwLastID, me, KTar, dwTarType, dwTarID
local function onBreathe()
	if not D.IsMapEnabled() then
		return
	end
	me = X.GetClientPlayer()
	if not me then
		return
	end
	-- local _, _, fPitch = Camera_GetRTParams()
	-- 自己和目标最重要 每次都要绘制
	CheckInvalidRect(TARGET.PLAYER, me.dwID, me, me)
	dwTarType, dwTarID = me.GetTarget()
	if dwTarType == TARGET.PLAYER or dwTarType == TARGET.NPC then
		KTar = X.GetTargetHandle(dwTarType, dwTarID)
		if KTar then
			CheckInvalidRect(dwTarType, dwTarID, me, KTar)
		end
	end
	-- 轮流绘制其他目标
	nRoundLeft = nRoundLimit
	while nRoundLeft > 0 do
		if DRAW_TARGET_TYPE == TARGET.NPC then
			if DRAW_TARGET_ID and NPC_CACHE[DRAW_TARGET_ID] == nil then
				DRAW_TARGET_ID = nil
			end
			DRAW_TARGET_ID = next(NPC_CACHE, DRAW_TARGET_ID)
			if DRAW_TARGET_ID then
				KTar = NPC_CACHE[DRAW_TARGET_ID]
			else
				DRAW_TARGET_TYPE, DRAW_TARGET_ID = TARGET.PLAYER, nil
			end
		elseif DRAW_TARGET_TYPE == TARGET.PLAYER then
			if DRAW_TARGET_ID and PLAYER_CACHE[DRAW_TARGET_ID] == nil then
				DRAW_TARGET_ID = nil
			end
			DRAW_TARGET_ID = next(PLAYER_CACHE, DRAW_TARGET_ID)
			if DRAW_TARGET_ID then
				KTar = PLAYER_CACHE[DRAW_TARGET_ID]
			else
				DRAW_TARGET_TYPE, DRAW_TARGET_ID = TARGET.NPC, nil
			end
		end
		if DRAW_TARGET_ID then
			CheckInvalidRect(DRAW_TARGET_TYPE, DRAW_TARGET_ID, me, KTar)
			if DRAW_TARGET_TYPE == dwLastType and DRAW_TARGET_ID == dwLastID then
				return
			end
		end
		nRoundLeft = nRoundLeft - 1
	end
	dwLastType, dwLastID = DRAW_TARGET_TYPE, DRAW_TARGET_ID
end
X.FrameCall('MY_LifeBar', onBreathe)
end
end

X.RegisterEvent('NPC_ENTER_SCENE',function()
	NPC_CACHE[arg0] = X.GetNpc(arg0)
end)

X.RegisterEvent('NPC_LEAVE_SCENE',function()
	local lb = LB_CACHE[arg0]
	if lb then
		if LB_ADJUST_INDEX_ID == arg0 then
			LB_ADJUST_INDEX_ID = next(LB_CACHE, LB_ADJUST_INDEX_ID)
		end
		lb:Remove()
		LB_CACHE[arg0] = nil
	end
	if DRAW_TARGET_TYPE == TARGET.NPC and DRAW_TARGET_ID == arg0 then
		DRAW_TARGET_ID = next(NPC_CACHE, DRAW_TARGET_ID)
		if not DRAW_TARGET_ID then
			DRAW_TARGET_TYPE = TARGET.PLAYER
		end
	end
	NPC_CACHE[arg0] = nil
end)

X.RegisterEvent('PLAYER_ENTER_SCENE',function()
	PLAYER_CACHE[arg0] = X.GetPlayer(arg0)
end)

X.RegisterEvent('PLAYER_LEAVE_SCENE',function()
	local lb = LB_CACHE[arg0]
	if lb then
		if LB_ADJUST_INDEX_ID == arg0 then
			LB_ADJUST_INDEX_ID = next(LB_CACHE, LB_ADJUST_INDEX_ID)
		end
		lb:Remove()
		LB_CACHE[arg0] = nil
	end
	if DRAW_TARGET_TYPE == TARGET.PLAYER and DRAW_TARGET_ID == arg0 then
		DRAW_TARGET_ID = next(PLAYER_CACHE, DRAW_TARGET_ID)
		if not DRAW_TARGET_ID then
			DRAW_TARGET_TYPE = TARGET.NPC
		end
	end
	PLAYER_CACHE[arg0] = nil
end)

local function PrioritySorter(a, b)
	if a.nPriority == b.nPriority then
		return false
	end
	if not b.nPriority then
		return true
	end
	if not a.nPriority then
		return false
	end
	return a.nPriority < b.nPriority
end
function D.ProcessCountdown(dwID, szType, szKey, tData)
	if not D.IsEnabled() then
		return false
	end
	if not COUNTDOWN_CACHE[dwID] then
		COUNTDOWN_CACHE[dwID] = {}
	end
	for i, p in X.ipairs_r(COUNTDOWN_CACHE[dwID]) do
		if p.szType == szType and p.szKey == szKey then
			table.remove(COUNTDOWN_CACHE[dwID], i)
		end
	end
	if tData then
		local tData = X.Clone(tData)
		if tData.col then
			local r, g, b = X.HumanColor2RGB(tData.col)
			if r and g and b then
				tData.tColor = {r, g, b}
			end
			tData.col = nil
		end
		tData.szType = szType
		tData.szKey = szKey
		table.insert(COUNTDOWN_CACHE[dwID], 1, tData)
		table.sort(COUNTDOWN_CACHE[dwID], PrioritySorter)
	elseif #COUNTDOWN_CACHE[dwID] == 0 then
		COUNTDOWN_CACHE[dwID] = nil
	end
	return true
end

-----------------------------------------------------------------------------------------
-- 对话泡泡
-----------------------------------------------------------------------------------------
local function OnCharacterSay(dwID, nChannel, szMsg)
	if dwID == 0 or not D.bReady then
		return
	end
	local szMsgType = X.CONSTANT.PLAYER_TALK_CHANNEL_TO_MSG_TYPE[nChannel]
	local bc = szMsgType and Config.BalloonChannel[szMsgType]
	if not bc or not bc.bEnable then
		return
	end
	local dwType = X.IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC
	local object = X.GetTargetHandle(dwType, dwID)
	if not object then
		return
	end
	local lb = LB_CACHE[dwID]
	if not lb then
		return
	end
	local me = X.GetClientPlayer()
	local scene = me.GetScene()
	if dwType == TARGET.PLAYER and IsEnemy(me.dwID, dwID) and (scene.bIsArenaMap or X.IsShieldedMap(scene.dwMapID)) then
		return
	end
	local relation = D.GetRelation(me.dwID, dwID, me, object)
	local force = D.GetForce(dwType, dwID, object)
	local cfg = GetConfigValue('ShowBalloon', relation, force)
	if not cfg.bEnable then
		return
	end
	if MY_ChatEmotion and MY_ChatEmotion.Render then
		szMsg = MY_ChatEmotion.Render(szMsg)
	end
	if MY_Farbnamen then
		szMsg = MY_Farbnamen.Render(szMsg)
	end
	lb:SetBalloon(szMsg, GetTime(), bc.nDuring, Config.nBalloonOffsetY)
end

local function onSwitch()
	O.bEnabled = not O.bEnabled
	D.Reset()
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_LifeBar',
	exports = {
		{
			fields = {
				'Reset',
				'Repaint',
				'IsEnabled',
				'IsShielded',
				'UpdateShadowHandleParam',
			},
			root = D,
		},
		{
			fields = {
				'bEnabled',
				'bAutoHideSysHeadtop',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnabled',
				'bAutoHideSysHeadtop',
			},
			triggers = {
				bEnabled = function()
					D.Reset(true)
				end,
			},
			root = O,
		},
	},
}
MY_LifeBar = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterHotKey('MY_LifeBar_S', _L['MY_LifeBar'], onSwitch)

X.RegisterEvent('CHARACTER_SAY', function()
	local szMsg = Table_GetSmartDialog(arg3, arg0)
	szMsg = GetFormatText(szMsg)
	OnCharacterSay(arg1, arg2, szMsg)
end)

X.RegisterEvent('PLAYER_SAY', function()
	OnCharacterSay(arg1, arg2, arg0)
end)

X.RegisterEvent('MY_LIFEBAR_COUNTDOWN', function()
	local dwID, szType, szKey, tData = arg0, arg1, arg2, arg3
	if MY_LifeBar_ScreenArrow.ProcessCountdown(dwID, szType, szKey, tData) then
		return
	end
	if D.ProcessCountdown(dwID, szType, szKey, tData) then
		return
	end
	MY_LifeBar_Official.ProcessCountdown(dwID, szType, szKey, tData)
end)

X.RegisterEvent({'FIRST_SYNC_USER_PREFERENCES_END', 'RELOAD_UI_ADDON_END'}, function()
	D.bUserPreferencesReady = true
end)

X.RegisterUserSettingsInit('MY_LifeBar', function()
	D.bReady = true
	D.Reset()
end)

X.RegisterUserSettingsRelease('MY_LifeBar', function()
	D.bReady = false
	D.Reset()
end)

X.RegisterExit(D.ResumeSysHeadTop)
X.RegisterReload(D.ResumeSysHeadTop)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
