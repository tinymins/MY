---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-02-08 10:06:25
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-06-22 01:37:36
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
	if D.IsMapEnabled() then
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
end
function D.SaveSysHeadTop()
	if SYS_HEAD_TOP_STATE then
		return
	end
	SYS_HEAD_TOP_STATE = {
		['GLOBAL_HEAD_NPC_NAME'          ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME ),
		['GLOBAL_HEAD_NPC_TITLE'         ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE),
		['GLOBAL_HEAD_NPC_LEFE'          ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LIFE ),
		['GLOBAL_HEAD_OTHERPLAYER_NAME'  ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME ),
		['GLOBAL_HEAD_OTHERPLAYER_TITLE' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE),
		['GLOBAL_HEAD_OTHERPLAYER_LEFE'  ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LIFE ),
		['GLOBAL_HEAD_OTHERPLAYER_GUILD' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD),
		['GLOBAL_HEAD_CLIENTPLAYER_NAME' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME ),
		['GLOBAL_HEAD_CLIENTPLAYER_TITLE'] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE),
		['GLOBAL_HEAD_CLIENTPLAYER_LEFE' ] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE ),
		['GLOBAL_HEAD_CLIENTPLAYER_GUILD'] = GetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD),
	}
end
function D.ResumeSysHeadTop()
	if not SYS_HEAD_TOP_STATE then
		return
	end
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_NAME'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_TITLE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_NPC         , GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_NPC_LEFE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_NAME'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_TITLE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_LEFE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_OTHERPLAYER , GLOBAL_HEAD_GUILD, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_OTHERPLAYER_GUILD'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_NAME , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_NAME'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_TITLE, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_TITLE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_LIFE , SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_LEFE'])
	SetGlobalTopHeadFlag(GLOBAL_HEAD_CLIENTPLAYER, GLOBAL_HEAD_GUILD, SYS_HEAD_TOP_STATE['GLOBAL_HEAD_CLIENTPLAYER_GUILD'])
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
	LB_CACHE = {}
	LB('clear')
	-- -- auto adjust index
	-- if MY_LifeBar.bEnabled and Config.bAdjustIndex then
	-- 	MY.BreatheCall('MY_LifeBar_AdjustIndex', function()
	-- 		local n = 0
	-- 		local t = {}
	-- 		-- refresh current index data
	-- 		for dwID, lb in pairs(LB_CACHE) do
	-- 			n = n + 1
	-- 			if n > 200 then
	-- 				break
	-- 			end
	-- 			PostThreadCall(function(info, xScreen, yScreen)
	-- 				info.nIndex = yScreen or 0
	-- 			end, lb.info, 'Scene_GetCharacterTopScreenPos', dwID)

	-- 			insert(t, { handle = lb.info.handle, index = lb.info.nIndex })
	-- 		end
	-- 		-- sort
	-- 		table.sort(t, function(a, b) return a.index < b.index end)
	-- 		-- adjust
	-- 		for i = #t, 1, -1 do
	-- 			if t[i].handle and t[i].handle:GetIndex() ~= i - 1 then
	-- 				t[i].handle:ExchangeIndex(i - 1)
	-- 			end
	-- 		end
	-- 	end, 500)
	-- else
	-- 	MY.BreatheCall('MY_LifeBar_AdjustIndex', false)
	-- end
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
	local bVisible = Config.nDistance <= 0
	if not bVisible then
		local nDisX, nDisY = me.nX - object.nX, me.nY - object.nY
		bVisible = nDisX * nDisX + nDisY * nDisY < Config.nDistance
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
	) and not Config.bShowSpecialNpc then
		bVisible = false
	end
	if bVisible then
		if not lb then
			lb = LB(dwType, dwID)
				:SetFont(Config.nFont)
				:SetTextsPos(Config.nTextOffsetY, Config.nTextLineHeight)
				:SetDistanceFmt('%d' .. g_tStrings.STR_METER)
				:Create()
			LB_CACHE[dwID] = lb
		end
		local dwTarType, dwTarID = me.GetTarget()
		local relation = D.GetRelation(dwID)
		local force = D.GetForce(dwID)
		local szName = MY.GetObjectName(object, (Config.bShowAllObjectID and 'always') or (Config.bShowUnnamedObjectID and 'auto') or 'never')
		-- 常规配色
		local r, g, b = unpack(GetConfigValue('Color', relation, force))
		-- 倒计时/名字/帮会/称号部分
		local cd = COUNTDOWN_CACHE[dwID]
		if cd then
			if cd.szType ~= 'BUFF' or object.GetBuff(cd.dwID) then
				local nSec
				if cd.nLFC then
					nSec = (cd.nLFC - GetLogicFrameCount()) / GLOBAL.GAME_FPS
				else
					nSec = (cd.nTime - GetTime()) / 1000
				end
				if cd.col then
					local cr, cg, cb = MY.HumanColor2RGB(cd.col)
					if cr and cg and cb then
						r, g, b = cr, cg, cb
					end
				end
				lb:SetCD(cd.szText .. '_' .. MY.FormatTimeCount(nSec >= 60 and 'M\'ss"' or 'ss"', min(nSec, 5999)))
			else
				COUNTDOWN_CACHE[dwID] = nil
			end
		else
			lb:SetCD('')
		end
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
			lb:SetLifeBar(Config.nLifeOffsetX, Config.nLifeOffsetY, Config.nLifeWidth, Config.nLifeHeight)
		end
		lb:SetLifeBarVisible(bShowLife)
		-- 血量数值部分
		local bShowLifePercent = GetConfigValue('ShowLifePer', relation, force) and (not Config.bHideLifePercentageWhenFight or me.bFightState)
		if bShowLifePercent then
			lb:SetLifeText(Config.nLifePerOffsetX, Config.nLifePerOffsetY, Config.bHideLifePercentageDecimal and '%.0f' or '%.1f')
		end
		lb:SetLifeTextVisible(bShowLifePercent)
		-- 配色生效
		lb:SetColor(r, g, b, Config.nAlpha, Config.nFont)
		lb:SetColorFx(
			object.nMoveState == MOVE_STATE.ON_DEATH
			and (dwID == dwTarID and fxDeathTarget or fxDeath)
			or (dwID == dwTarID and fxTarget or nil)
		)
		lb:Create():Paint()
	elseif lb then
		lb:Remove()
		LB_CACHE[dwID] = nil
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
	if arg1 then
		COUNTDOWN_CACHE[arg0] = {
			dwID = arg1,
			szType = arg2,
			szText = arg3,
			nLFC = arg4,
			col = arg5,
		}
	else
		COUNTDOWN_CACHE[arg0] = nil
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
