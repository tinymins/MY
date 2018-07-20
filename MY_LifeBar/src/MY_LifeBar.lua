---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-02-08 10:06:25
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-07-20 18:13:17
---------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
local Config = MY_LifeBar_Config
if not Config then
    return
end

local function GetConfigValue(key, relation, force)
	local cfg, value = Config[key][relation]
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
-----------------------------------------------------------------------------------------

local _L, D = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/lang/'), {}
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
do -- 头顶特效数据刷新
local QUEST_TITLE_EFFECT = {
	["normal_unaccept_proper"] = 1,
	["repeat_unaccept_proper"] = 2,
	["activity_unaccept_proper"] = 45,
	["unaccept_high"] = 5,
	["unaccept_low"] = 6,
	["unaccept_lower"] = 43,
	["accpeted"] = 44,
	["normal_finished"] = 3,
	["repeat_finished"] = 4,
	["activity_finished"] = 46,
	["normal_notneedaccept"] = 44,
	["repeat_notneedaccept"] = 4,
	["activity_notneedaccept"] = 46,
	["lishijie_unaccept"] = 55,
	["lishijie_finished"] = 54,
}
local function UpdateTitleEffect(dwType, dwID)
	local nEffectID = nil
	if dwType == TARGET.PLAYER then
		local nMark = MY.GetMarkIndex(dwID)
		if nMark and PARTY_TITLE_MARK_EFFECT_LIST[nMark] then
			nEffectID = PARTY_TITLE_MARK_EFFECT_LIST[nMark]
		end
	elseif dwType == TARGET.NPC then
		local npc = GetNpc(dwID)
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
			elseif MY.GetMarkIndex(dwID) and PARTY_TITLE_MARK_EFFECT_LIST[MY.GetMarkIndex(dwID)] then -- party mark
				nEffectID = PARTY_TITLE_MARK_EFFECT_LIST[MY.GetMarkIndex(dwID)]
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
	OBJECT_TITLE_EFFECT[dwID] = nEffectID and MY.GetGlobalEffect(nEffectID)
	OVERWRITE_TITLE_EFFECT[dwID] = not OBJECT_TITLE_EFFECT[dwID] -- 强刷系统头顶
end
local function onNpcQuestMarkUpdate()
	UpdateTitleEffect(TARGET.NPC, arg0)
end
MY.RegisterEvent('QUEST_MARK_UPDATE.MY_LifeBar', onNpcQuestMarkUpdate)
MY.RegisterEvent('NPC_DISPLAY_DATA_UPDATE.MY_LifeBar', onNpcQuestMarkUpdate)

local function onNpcQuestMarkUpdateAll()
	for _, dwID in ipairs(MY.GetNearNpcID()) do
		UpdateTitleEffect(TARGET.NPC, dwID)
	end
end
MY.RegisterInit('MY_LifeBar_onNpcQuestMarkUpdateAll', onNpcQuestMarkUpdateAll)

local function onPartySetMark()
	local tID = {}
	for dwID, _ in pairs(OBJECT_TITLE_EFFECT) do
		tID[dwID] = true
	end
	for dwID, _ in pairs(GetClientTeam().GetTeamMark() or {}) do
		tID[dwID] = true
	end
	for dwID, _ in pairs(tID) do
		UpdateTitleEffect(IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC, dwID)
	end
	OVERWRITE_TITLE_EFFECT = {}
end
MY.RegisterInit('MY_LifeBar_onPartySetMark', onPartySetMark)
MY.RegisterEvent('PARTY_SET_MARK.MY_LifeBar', onPartySetMark)
MY.RegisterEvent('PARTY_DELETE_MEMBER.MY_LifeBar', function()
	local me = GetClientPlayer()
	if me.dwID == arg1 then
		onPartySetMark()
	end
end)
MY.RegisterEvent('PARTY_DISBAND.MY_LifeBar', onPartySetMark)
MY.RegisterEvent('PARTY_UPDATE_BASE_INFO.MY_LifeBar', onPartySetMark)

local function onLoadingEnd()
	OVERWRITE_TITLE_EFFECT = {}
end
MY.RegisterEvent('LOADING_END', onLoadingEnd)
end

MY_LifeBar = {}
MY_LifeBar.bEnabled = false
MY_LifeBar.szConfig = 'common'
RegisterCustomData('MY_LifeBar.bEnabled')
RegisterCustomData('MY_LifeBar.szConfig')

function D.IsShielded() return MY.IsShieldedVersion() and MY.IsInShieldedMap() end
function D.IsEnabled() return MY_LifeBar.bEnabled and not D.IsShielded() end
function D.IsMapEnabled()
	return D.IsEnabled() and (
		not (
			Config.bOnlyInDungeon or
			Config.bOnlyInArena or
			Config.bOnlyInBattleField
		) or (
			(Config.bOnlyInDungeon     and MY.IsInDungeon()) or
			(Config.bOnlyInArena       and MY.IsInArena()) or
			(Config.bOnlyInBattleField and (MY.IsInBattleField() or MY.IsInPubg() or MY.IsInZombieMap()))
		)
	)
end

function D.GetNz(nZ,nZ2)
	return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

function D.GetRelation(dwID)
	local me = GetClientPlayer()
	if not me then
		return 'Neutrality'
	end
	if Config.nCamp == -1 or not IsPlayer(dwID) then
		if dwID == me.dwID then
			return 'Self'
		elseif IsParty(me.dwID, dwID) then
			return 'Party'
		elseif IsNeutrality(me.dwID, dwID) then
			return 'Neutrality'
		elseif IsEnemy(me.dwID, dwID) then -- 敌对关系
			local r, g, b = GetHeadTextForceFontColor(dwID, me.dwID) -- 我看他的颜色
			if MY.GetFoe(dwID) then
				return 'Foe'
			elseif r == 255 and g == 255 and b == 0 then
				return 'Neutrality'
			else
				return 'Enemy'
			end
		elseif IsAlly(me.dwID, dwID) then -- 相同阵营
			return 'Ally'
		else
			return 'Neutrality' -- 'Other'
		end
	else
		local tar = MY.GetObject(TARGET.PLAYER, dwID)
		if not tar then
			return 'Neutrality'
		elseif dwID == me.dwID then
			return 'Self'
		elseif IsParty(me.dwID, dwID) then
			return 'Party'
		elseif MY.GetFoe(dwID) then
			return 'Foe'
		elseif tar.nCamp == Config.nCamp then
			return 'Ally'
		elseif not tar.bCampFlag        -- 没开阵营
		or tar.nCamp == CAMP.NEUTRAL    -- 目标中立
		or Config.nCamp == CAMP.NEUTRAL -- 自己中立
		or me.GetScene().nCampType == MAP_CAMP_TYPE.ALL_PROTECT then -- 停战地图
			return 'Neutrality'
		else
			return 'Enemy'
		end
	end
end

function D.GetForce(dwID)
	if not IsPlayer(dwID) then
		return 'Npc'
	else
		local tar = MY.GetObject(TARGET.PLAYER, dwID)
		if not tar then
			return 0
		else
			return tar.dwForceID
		end
	end
end

function D.GetTongName(dwTongID)
	if not IsNumber(dwTongID) or dwTongID == 0 then
		return
	end
	if not TONG_NAME_CACHE[dwTongID] then
		TONG_NAME_CACHE[dwTongID] = GetTongClient().ApplyGetTongName(dwTongID)
	end
	if TONG_NAME_CACHE[dwTongID] then
		return TONG_NAME_CACHE[dwTongID]
	end
end

function D.AutoSwitchSysHeadTop()
	if not Config('loaded') then
		return
	end
	if D.IsMapEnabled() then
		if Config.eCss == '' then
			Config('reset')
		end
		D.SaveSysHeadTop()
		D.HideSysHeadTop()
	else
		D.ResumeSysHeadTop()
	end
end
function D.HideSysHeadTop()
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC, GLOBAL_HEAD_NAME , false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC, GLOBAL_HEAD_TITLE, false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC, GLOBAL_HEAD_LIFE , false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_NAME , false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_TITLE, false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_LIFE , false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER, GLOBAL_HEAD_GUILD, false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE , false)
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, false)
	SetGlobalTopIntelligenceLife(false)
end
function D.SaveSysHeadTop()
	if SYS_HEAD_TOP_STATE then
		return
	end
	SYS_HEAD_TOP_STATE = {
		['GLOBAL_HEAD_NPC_NAME'          ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME ),
		['GLOBAL_HEAD_NPC_TITLE'         ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE),
		['GLOBAL_HEAD_NPC_LIFE'          ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LIFE ),
		['GLOBAL_HEAD_OTHERPLAYER_NAME'  ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME ),
		['GLOBAL_HEAD_OTHERPLAYER_TITLE' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE),
		['GLOBAL_HEAD_OTHERPLAYER_LIFE'  ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LIFE ),
		['GLOBAL_HEAD_OTHERPLAYER_GUILD' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD),
		['GLOBAL_HEAD_CLIENTPLAYER_NAME' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME ),
		['GLOBAL_HEAD_CLIENTPLAYER_TITLE'] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE),
		['GLOBAL_HEAD_CLIENTPLAYER_LIFE' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE ),
		['GLOBAL_HEAD_CLIENTPLAYER_GUILD'] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD),
		['GLOBAL_TOP_INTELLIGENCE_LIFE'  ] = GetGlobalTopIntelligenceLife(),
	}
end
function D.ResumeSysHeadTop()
	if not SYS_HEAD_TOP_STATE then
		return
	end
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_NAME'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_TITLE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_LIFE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_NAME'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_TITLE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_LIFE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_GUILD'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_NAME'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_TITLE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_LIFE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_GUILD'])
	SetGlobalTopIntelligenceLife(SYS_HEAD_TOP_STATE['GLOBAL_TOP_INTELLIGENCE_LIFE'])
	SYS_HEAD_TOP_STATE = nil
end
MY.RegisterExit(D.ResumeSysHeadTop)

function D.Repaint()
	for _, lb in pairs(LB_CACHE) do
		lb:Paint(true)
	end
end
MY.RegisterEvent('UI_SCALED', D.Repaint)

function D.Reset()
	-- 重置缓存
	LB_CACHE = {}
	LB('clear')
	-- 恢复官方标记
	for dwID, _ in pairs(OVERWRITE_TITLE_EFFECT) do
		if OBJECT_TITLE_EFFECT[dwID] then
			SceneObject_SetTitleEffect(IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC, dwID, OBJECT_TITLE_EFFECT[dwID].nID)
		end
	end
	OVERWRITE_TITLE_EFFECT = {}
	-- 自适应遮挡顺序
	if MY_LifeBar.bEnabled and Config.bScreenPosSort then
		local dwID, dwLastID, nCount
		local function onGetCharacterTopScreenPos(dwID, xScreen, yScreen)
			OBJECT_SCREEN_POS_Y_CACHE[dwID] = yScreen or 0
		end
		local function onBreathe()
			nCount = 0
			repeat
				dwID = next(LB_CACHE, dwID)
				if dwID then
					PostThreadCall(onGetCharacterTopScreenPos, dwID, 'Scene_GetCharacterTopScreenPos', dwID)
				end
				nCount = nCount + 1
			until nCount > 30 or dwID == dwLastID
			dwLastID = dwID
		end
		MY.BreatheCall('MY_LifeBar_ScreenPosSort', onBreathe)
	else
		MY.BreatheCall('MY_LifeBar_ScreenPosSort', false)
	end
	D.AutoSwitchSysHeadTop()
end
MY.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED', D.Reset)
MY.RegisterEvent('LOADING_END', D.AutoSwitchSysHeadTop)

do
local function fxTarget(r, g, b, a) return 255 - (255 - r) * 0.3, 255 - (255 - g) * 0.3, 255 - (255 - b) * 0.3, a end
local function fxDeath(r, g, b, a) return ceil(r * 0.4), ceil(g * 0.4), ceil(b * 0.4), a end
local function fxDeathTarget(r, g, b, a) return ceil(r * 0.45), ceil(g * 0.45), ceil(b * 0.45), a end
local function CheckInvalidRect(dwType, dwID, me)
	local lb = LB_CACHE[dwID]
	local object, info = MY.GetObject(dwType, dwID)
	if not object then
		if lb then
			lb:Remove()
			LB_CACHE[dwID] = nil
		end
		return
	end
	local bVisible = true
	-- 距离判断
	if bVisible and Config.nDistance > 0 then
		local nDisX, nDisY, nDisZ = me.nX - object.nX, me.nY - object.nY, (me.nZ - object.nZ) * 0.125
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
	if bVisible
	and dwType == TARGET.NPC
	and not object.CanSeeName()
	and (
		object.dwTemplateID ~= CHANGGE_REAL_SHADOW_TPLID
		or (IsEnemy(me.dwID, dwID) and MY.IsShieldedVersion())
	) and not (Config.bShowSpecialNpc and (not Config.bShowSpecialNpcOnlyEnemy or IsEnemy(me.dwID, dwID))) then
		bVisible = false
	end
	if bVisible then
		if not lb then
			-- 创建和设置不会改变的东西
			lb = LB(dwType, dwID)
			lb:SetDistanceFmt('%d' .. g_tStrings.STR_METER)
			LB_CACHE[dwID] = lb
		end
		local fTextScale = Config.fTextScale
		local dwTarType, dwTarID = me.GetTarget()
		local relation = D.GetRelation(dwID)
		local force = D.GetForce(dwID)
		local nPriority = OBJECT_SCREEN_POS_Y_CACHE[dwID] or 0 -- 默认根据屏幕坐标排序
		if Config.bMineOnTop and dwType == TARGET.PLAYER and dwID == me.dwID then -- 自身永远最前
			nPriority = nPriority + 10000
		end
		local szName = MY.GetObjectName(object, (Config.bShowObjectID and (Config.bShowObjectIDOnlyUnnamed and 'auto' or 'always') or 'never'))
		-- 常规配色
		local r, g, b = unpack(GetConfigValue('Color', relation, force))
		-- 倒计时/名字/帮会/称号部分
		local aCountDown, szCountDown = COUNTDOWN_CACHE[dwID], ''
		while aCountDown and #aCountDown > 0 do
			local tData, szText, nSec = aCountDown[1]
			if tData.szType == 'BUFF' then
				local KBuff = object.GetBuff(tData.dwBuffID, 0)
				if KBuff then
					nSec = (KBuff.GetEndTime() - GetLogicFrameCount()) / GLOBAL.GAME_FPS
					szText = tData.szText
				end
			else
				if tData.nLogicFrame then
					nSec = (tData.nLogicFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
				elseif tData.nTime then
					nSec = (tData.nTime - GetTime()) / 1000
				end
				szText = tData.szText
			end
			if nSec and nSec >= 0 and szText and szText ~= '' then
				if tData.tColor then
					r, g, b = unpack(tData.tColor)
				end
				nPriority = nPriority + 100000
				fTextScale = fTextScale * 1.15
				szCountDown = tData.szText .. '_' .. MY.FormatTimeCount(nSec >= 60 and 'M\'ss"' or 'ss"', min(nSec, 5999))
				break
			else
				remove(aCountDown, 1)
			end
		end
		lb:SetCD(szCountDown)
		-- 名字
		local bShowName = GetConfigValue('ShowName', relation, force)
		if bShowName then
			lb:SetName(szName)
		end
		lb:SetNameVisible(bShowName)
		-- 心法
		local bShowKungfu = Config.bShowKungfu and dwType == TARGET.PLAYER and dwID ~= me.dwID
		if bShowKungfu then
			local kunfu = object.GetKungfuMount()
			if kunfu and kunfu.dwSkillID and kunfu.dwSkillID ~= 0 then
				lb:SetKungfu(MY.GetKungfuName(kunfu.dwSkillID, 'short'))
			else
				lb:SetKungfu(g_tStrings.tForceTitle[object.dwForceID])
			end
		end
		lb:SetKungfuVisible(bShowKungfu)
		-- 距离
		if Config.bShowDistance then
			lb:SetDistance(GetCharacterDistance(me.dwID, dwID) / 64)
		end
		lb:SetDistanceVisible(Config.bShowDistance)
		-- 帮会
		local bShowTong = GetConfigValue('ShowTong', relation, force)
		if bShowTong then
			lb:SetTong(D.GetTongName(object.dwTongID) or '')
		end
		lb:SetTongVisible(bShowTong)
		-- 称号
		local bShowTitle = GetConfigValue('ShowTitle', relation, force)
		if bShowTitle then
			lb:SetTitle(object.szTitle or '')
		end
		lb:SetTitleVisible(bShowTitle)
		-- 血条部分
		lb:SetLife(info.nCurrentLife, info.nMaxLife)
		local bShowLife = szName ~= '' and GetConfigValue('ShowLife', relation, force)
		if bShowLife then
			lb:SetLifeBar(Config.nLifeOffsetX, Config.nLifeOffsetY, Config.nLifeWidth, Config.nLifeHeight, Config.nLifePadding)
			lb:SetLifeBarBorder(Config.nLifeBorder, Config.nLifeBorderR, Config.nLifeBorderG, Config.nLifeBorderB)
		end
		lb:SetLifeBarVisible(bShowLife)
		-- 血量数值部分
		local bShowLifePercent = GetConfigValue('ShowLifePer', relation, force) and (not Config.bHideLifePercentageWhenFight or me.bFightState)
		if bShowLifePercent then
			lb:SetLifeText(Config.nLifePerOffsetX, Config.nLifePerOffsetY, Config.bHideLifePercentageDecimal and '%.0f' or '%.1f')
		end
		lb:SetLifeTextVisible(bShowLifePercent)
		-- 头顶特效
		local tEffect = OBJECT_TITLE_EFFECT[dwID]
		if tEffect then
			lb:SetSFX(tEffect.szFilePath, tEffect.fScale * Config.fTitleEffectScale, Config.nTitleEffectOffsetY, tEffect.nWidth, tEffect.nHeight)
		else
			lb:ClearSFX()
		end
		-- 各种数据生效
		lb:SetScale((Config.bSystemUIScale and MY.GetUIScale() or 1) * Config.fGlobalUIScale)
		lb:SetColor(r, g, b, Config.nAlpha, Config.nFont)
		lb:SetColorFx(
			object.nMoveState == MOVE_STATE.ON_DEATH
			and (dwID == dwTarID and fxDeathTarget or fxDeath)
			or (dwID == dwTarID and fxTarget or nil)
		)
		lb:SetFont(Config.nFont)
		lb:SetTextsPos(Config.nTextOffsetY, Config.nTextLineHeight)
		lb:SetTextsScale((Config.bSystemUIScale and MY.GetFontScale() or 1) * fTextScale)
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

local function onBreathe()
	if not D.IsMapEnabled() then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end

	-- local _, _, fPitch = Camera_GetRTParams()
	for k , v in pairs(NPC_CACHE) do
		CheckInvalidRect(TARGET.NPC, k, me)
	end

	for k , v in pairs(PLAYER_CACHE) do
		CheckInvalidRect(TARGET.PLAYER, k, me)
	end
end
MY.BreatheCall('MY_LifeBar', onBreathe)
end

RegisterEvent('NPC_ENTER_SCENE',function()
	NPC_CACHE[arg0] = true
end)

RegisterEvent('NPC_LEAVE_SCENE',function()
	local lb = LB_CACHE[arg0]
	if lb then
		lb:Remove()
		LB_CACHE[arg0] = nil
	end
	NPC_CACHE[arg0] = nil
end)

RegisterEvent('PLAYER_ENTER_SCENE',function()
	PLAYER_CACHE[arg0] = true
end)

RegisterEvent('PLAYER_LEAVE_SCENE',function()
	local lb = LB_CACHE[arg0]
	if lb then
		lb:Remove()
		LB_CACHE[arg0] = nil
	end
	PLAYER_CACHE[arg0] = nil
end)

RegisterEvent('MY_LIFEBAR_COUNTDOWN', function()
	local dwID, szType, szKey, tData = arg0, arg1, arg2, arg3
	if not COUNTDOWN_CACHE[dwID] then
		COUNTDOWN_CACHE[dwID] = {}
	end
	for i, p in ipairs_r(COUNTDOWN_CACHE[dwID]) do
		if p.szType == szType and p.szKey == szKey then
			remove(COUNTDOWN_CACHE[dwID], i)
		end
	end
	if tData then
		local tData = clone(tData)
		if tData.col then
			local r, g, b = MY.HumanColor2RGB(tData.col)
			if r and g and b then
				tData.tColor = {r, g, b}
			end
			tData.col = nil
		end
		tData.szType = szType
		tData.szKey = szKey
		insert(COUNTDOWN_CACHE[dwID], 1, tData)
	elseif #COUNTDOWN_CACHE[dwID] == 0 then
		COUNTDOWN_CACHE[dwID] = nil
	end
end)

local function onSwitch()
	MY_LifeBar.bEnabled = not MY_LifeBar.bEnabled
	D.Reset(true)
end
MY.Game.RegisterHotKey('MY_LifeBar_S', _L['x lifebar'], onSwitch)

setmetatable(MY_LifeBar, {
	__index = {
		Reset = D.Reset,
		Repaint = D.Repaint,
		IsEnabled = D.IsEnabled,
		IsShielded = D.IsShielded,
	},
	__metatable = true,
})
