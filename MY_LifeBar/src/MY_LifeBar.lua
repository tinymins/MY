---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-02-08 10:06:25
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-03-20 00:34:24
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

local _L, D = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_LifeBar/lang/"), {}
local LB_CACHE = {}
local TONG_NAME_CACHE = {}
local NPC_CACHE = {}
local PLAYER_CACHE = {}
local TARGET_ID = 0
local LAST_FIGHT_STATE = false
local SYS_HEAD_TOP_STATE
local LB = MY_LifeBar_LB
local OT_STATE = MY_LifeBar_LB.OT_STATE
local CHANGGE_REAL_SHADOW_TPLID = 46140 -- 清绝歌影 的主体影子

MY_LifeBar = {}
MY_LifeBar.bEnabled = false
MY_LifeBar.szConfig = "common"
RegisterCustomData("MY_LifeBar.bEnabled")
RegisterCustomData("MY_LifeBar.szConfig")

function D.IsShielded() return MY.IsShieldedVersion() and MY.IsInPubg() end
function D.IsEnabled() return MY_LifeBar.bEnabled and not D.IsShielded() end
function D.IsMapEnabled()
	return D.IsEnabled() and (
		not (
			Config.bOnlyInDungeon or
			Config.bOnlyInArena or
			Config.bOnlyInBattleField
		) or (
			(Config.bOnlyInDungeon     and MY.IsInDungeon(true)) or
			(Config.bOnlyInArena       and MY.IsInArena()) or
			(Config.bOnlyInBattleField and (MY.IsInBattleField() or MY.IsInPubg()))
		)
	)
end

function D.GetNz(nZ,nZ2)
	return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

function D.GetRelation(dwID)
	local me = GetClientPlayer()
	if not me then
		return "Neutrality"
	end
	if Config.nCamp == -1 or not IsPlayer(dwID) then
		if dwID == me.dwID then
			return "Self"
		elseif IsParty(me.dwID, dwID) then
			return "Party"
		elseif IsNeutrality(me.dwID, dwID) then
			return "Neutrality"
		elseif IsEnemy(me.dwID, dwID) then -- 敌对关系
			local r, g, b = GetHeadTextForceFontColor(dwID, me.dwID) -- 我看他的颜色
			if MY.GetFoe(dwID) then
				return "Foe"
			elseif r == 255 and g == 255 and b == 0 then
				return "Neutrality"
			else
				return "Enemy"
			end
		elseif IsAlly(me.dwID, dwID) then -- 相同阵营
			return "Ally"
		else
			return "Neutrality" -- "Other"
		end
	else
		local tar = MY.GetObject(TARGET.PLAYER, dwID)
		if not tar then
			return "Neutrality"
		elseif dwID == me.dwID then
			return "Self"
		elseif IsParty(me.dwID, dwID) then
			return "Party"
		elseif MY.GetFoe(dwID) then
			return "Foe"
		elseif tar.nCamp == Config.nCamp then
			return "Ally"
		elseif not tar.bCampFlag        -- 没开阵营
		or tar.nCamp == CAMP.NEUTRAL    -- 目标中立
		or Config.nCamp == CAMP.NEUTRAL -- 自己中立
		or me.GetScene().nCampType == MAP_CAMP_TYPE.ALL_PROTECT then -- 停战地图
			return "Neutrality"
		else
			return "Enemy"
		end
	end
end

function D.GetForce(dwID)
	if not IsPlayer(dwID) then
		return "Npc"
	else
		local tar = MY.GetObject(TARGET.PLAYER, dwID)
		if not tar then
			return 0
		else
			return tar.dwForceID
		end
	end
end

function D.GetTongName(dwTongID, szFormatString)
	if not szFormatString then
		szFormatString = "%s"
	end
	if not IsNumber(dwTongID) or dwTongID == 0 then
		return
	end
	if not TONG_NAME_CACHE[dwTongID] then
		TONG_NAME_CACHE[dwTongID] = GetTongClient().ApplyGetTongName(dwTongID)
	end
	if TONG_NAME_CACHE[dwTongID] then
		return string.format(szFormatString, TONG_NAME_CACHE[dwTongID])
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

-- 重绘所有UI
function D.Reset()
	LB_CACHE = {}
	LB("clear")
	-- auto adjust index
	MY.BreatheCall("XLifeBar_AdjustIndex", false)
	if Config.bAdjustIndex then
		MY.BreatheCall("XLifeBar_AdjustIndex", function()
			local n = 0
			local t = {}
			-- refresh current index data
			for dwID, lb in pairs(LB_CACHE) do
				n = n + 1
				if n > 200 then
					break
				end
				PostThreadCall(function(info, xScreen, yScreen)
					info.nIndex = yScreen or 0
				end, lb.info, "Scene_GetCharacterTopScreenPos", dwID)

				insert(t, { handle = lb.info.handle, index = lb.info.nIndex })
			end
			-- sort
			table.sort(t, function(a, b) return a.index < b.index end)
			-- adjust
			for i = #t, 1, -1 do
				if t[i].handle and t[i].handle:GetIndex() ~= i - 1 then
					t[i].handle:ExchangeIndex(i - 1)
				end
			end
		end, 500)
	end

	D.AutoSwitchSysHeadTop()
end
-- 加载界面
MY.RegisterEvent('LOGIN_GAME', function() MY.UI.CreateFrame("MY_LifeBar", { level = "Lowest", empty = true }) end)
-- 重载配置文件并重绘
MY.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED', function() D.Reset() end)
-- 过图可能切换开关状态
MY.RegisterEvent('LOADING_END', D.AutoSwitchSysHeadTop)

local function CheckInvalidRect(dwType, dwID, me)
	local lb = LB_CACHE[dwID]
	local object, info = MY.GetObject(dwType, dwID)
	if not object then
		lb:Remove()
		LB_CACHE[dwID] = nil
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
			LB_CACHE[dwID] = lb
		end
		-- 基本属性设置
		lb:SetForce(D.GetForce(dwID))
			:SetRelation(D.GetRelation(dwID))
			:SetLife(info.nCurrentLife / info.nMaxLife)
			:SetTong(D.GetTongName(object.dwTongID, "[%s]"))
			:SetTitle(object.szTitle)
			:Create()
		local szName = MY.GetObjectName(object)
		if szName then
			if not Config.bShowDistance or dwID == me.dwID then
				lb:SetName(szName)
			else
				lb:SetName(
					szName .. _L.STR_SPLIT_DOT
					.. math.floor(GetCharacterDistance(me.dwID, dwID) / 64)
					.. g_tStrings.STR_METER
				)
			end
		end
		if me.bFightState ~= LAST_FIGHT_STATE then
			lb:DrawLife()
		end
		-- 读条判定
		local nState = lb:GetOTState()
		if nState ~= OT_STATE.ON_SKILL then
			local nType, dwSkillID, dwSkillLevel, fProgress = object.GetSkillOTActionState()
			if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
				lb:SetOTTitle(Table_GetSkillName(dwSkillID, dwSkillLevel)):DrawOTTitle():SetOTPercentage(fProgress):SetOTState(OT_STATE.START_SKILL)
			end
		end
		if nState == OT_STATE.START_SKILL then                              -- 技能读条开始
			lb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(0):SetOTState(OT_STATE.ON_SKILL)
		elseif nState == OT_STATE.ON_SKILL then                             -- 技能读条中
			local nType, dwSkillID, dwSkillLevel, fProgress = object.GetSkillOTActionState()
			if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
				lb:SetOTPercentage(fProgress):SetOTTitle(Table_GetSkillName(dwSkillID, dwSkillLevel))
			else
				lb:SetOTPercentage(1):SetOTState(OT_STATE.SUCCEED)
			end
		elseif nState == OT_STATE.START_PREPARE then                        -- 读条开始
			lb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(0):SetOTState(OT_STATE.ON_PREPARE):DrawOTTitle()
		elseif nState == OT_STATE.ON_PREPARE then                           -- 读条中
			if not object.GetOTActionState or object.GetOTActionState() == 0 then    -- 为0 说明没有读条
				lb:SetOTPercentage(1):SetOTState(OT_STATE.SUCCEED)
			else
				lb:SetOTPercentage(( GetLogicFrameCount() - lb.info.OT.nStartFrame ) / lb.info.OT.nFrameCount)
			end
		elseif nState == OT_STATE.START_CHANNEL then                        -- 逆读条开始
			lb:DrawOTBarBorder(Config.nAlpha):SetOTPercentage(1):SetOTState(OT_STATE.ON_CHANNEL):DrawOTTitle()
		elseif nState == OT_STATE.ON_CHANNEL then                           -- 逆读条中
			local nPercentage = 1 - ( GetLogicFrameCount() - lb.info.OT.nStartFrame ) / lb.info.OT.nFrameCount
			if object.GetOTActionState and
			object.GetOTActionState() == 2 and -- 为2 说明在读条引导保护 计算当前帧进度
			nPercentage >= 0 then
				lb:SetOTPercentage(nPercentage):DrawOTTitle()
			else
				lb:SetOTPercentage(0):SetOTState(OT_STATE.SUCCEED)
			end
		elseif nState == OT_STATE.SUCCEED then                              -- 读条成功
			if GetLogicFrameCount() - lb.info.OT.nStartFrame < 16 then -- 渐变
				local rgba = { nil,nil,nil, Config.nAlpha - (GetLogicFrameCount() - lb.info.OT.nStartFrame) * (Config.nAlpha/16) }
				lb:DrawOTBarBorder(rgba[4]):DrawOTBar(rgba):DrawOTTitle(rgba)
			else
				local rgba = { nil,nil,nil, 0 }
				lb:SetOTTitle("", rgba):SetOTState(OT_STATE.IDLE):DrawOTBarBorder(0):DrawOTBar(rgba)
			end
		elseif nState == OT_STATE.BREAK then                                -- 读条打断
			if GetLogicFrameCount() - lb.info.OT.nStartFrame < 16 then -- 渐变
				local rgba = { 255,0,0, Config.nAlpha - (GetLogicFrameCount() - lb.info.OT.nStartFrame) * (Config.nAlpha/16) }
				lb:DrawOTBarBorder(rgba[4]):DrawOTBar(rgba):DrawOTTitle(rgba)
			else
				lb:SetOTTitle(""):SetOTState(OT_STATE.IDLE):DrawOTBarBorder(0):DrawOTBar({nil,nil,nil,0})
			end
		end
	elseif lb then
		lb:Remove()
		LB_CACHE[dwID] = nil
	end
end

function MY_LifeBar.OnFrameBreathe()
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

	if me.bFightState ~= LAST_FIGHT_STATE then
		LAST_FIGHT_STATE = me.bFightState
	end
end

-- -- event
-- MY.RegisterEvent("SYS_MSG", function()
--     if arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
--         Output(arg1, arg4, arg5, arg0, "UI_OME_SKILL_HIT_LOG")
--     elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
--         Output(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 ,arg11, arg12, arg13, GetPlayer(arg1).szName, GetSkill(arg5, arg6).szSkillName)
--     end
-- end)
-- 逆读条事件响应
MY.RegisterEvent("DO_SKILL_CAST", function()
	local dwID, dwSkillID = arg0, arg1
	local skill = GetSkill(arg1, 1)
	if skill.bIsChannelSkill then
		local lb = LB_CACHE[dwID]
		if lb then
			local nFrame = MY.GetChannelSkillFrame(dwSkillID) or 0
			lb:StartOTBar(skill.szSkillName, nFrame, true)
		end
	end
end)
-- 读条打断事件响应
MY.RegisterEvent("OT_ACTION_PROGRESS_BREAK", function()
	local lb = LB_CACHE[arg0]
	if lb then
		lb:SetOTState(OT_STATE.BREAK)
	end
end)
-- MY.RegisterEvent("OT_ACTION_PROGRESS", function()Output("OT_ACTION_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("OT_ACTION_PROGRESS_UPDATE", function()Output("OT_ACTION_PROGRESS_UPDATE",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_SKILL_PREPARE_PROGRESS", function()Output("DO_SKILL_PREPARE_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_SKILL_CHANNEL_PROGRESS", function()Output("DO_SKILL_CHANNEL_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_SKILL_HOARD_PROGRESS", function()Output("DO_SKILL_HOARD_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- 拾取事件响应
MY.RegisterEvent("DO_PICK_PREPARE_PROGRESS", function()
	local dooadad = GetDoodad(arg1)
	local szName = dooadad.szName
	if szName == "" then
		szName = GetDoodadTemplate(dooadad.dwTemplateID).szName
	end
	LB_CACHE[UI_GetClientPlayerID()]:StartOTBar(szName, arg0, false)
end)
-- MY.RegisterEvent("DO_CUSTOM_OTACTION_PROGRESS ", function()Output("DO_CUSTOM_OTACTION_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("DO_RECIPE_PREPARE_PROGRESS", function()Output("DO_RECIPE_PREPARE_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)
-- MY.RegisterEvent("ON_SKILL_CHANNEL_PROGRESS ", function()Output("ON_SKILL_CHANNEL_PROGRESS",arg0, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13) end)

RegisterEvent("NPC_ENTER_SCENE",function()
	NPC_CACHE[arg0] = true
end)

RegisterEvent("NPC_LEAVE_SCENE",function()
	local lb = LB_CACHE[arg0]
	if lb then
		lb:Remove()
		LB_CACHE[arg0] = nil
	end
	NPC_CACHE[arg0] = nil
end)

RegisterEvent("PLAYER_ENTER_SCENE",function()
	PLAYER_CACHE[arg0] = true
end)

RegisterEvent("PLAYER_LEAVE_SCENE",function()
	local lb = LB_CACHE[arg0]
	if lb then
		lb:Remove()
		LB_CACHE[arg0] = nil
	end
	PLAYER_CACHE[arg0] = nil
end)

RegisterEvent("UPDATE_SELECT_TARGET",function()
	local _, dwID = MY.GetTarget()
	if TARGET_ID == dwID then
		return
	end
	local dwOldTargetID = TARGET_ID
	TARGET_ID = dwID
	if LB_CACHE[dwOldTargetID] then
		LB_CACHE[dwOldTargetID]:DrawNames():DrawLife()
	end
	if LB_CACHE[dwID] then
		LB_CACHE[dwID]:DrawNames():DrawLife()
	end
end)

local function onSwitch()
	MY_LifeBar.bEnabled = not MY_LifeBar.bEnabled
	D.Reset(true)
end
MY.Game.RegisterHotKey("MY_XLifeBar_S", _L["x lifebar"], onSwitch)

setmetatable(MY_LifeBar, {
	__index = {
		Reset = D.Reset,
		IsEnabled = D.IsEnabled,
		IsShielded = D.IsShielded,
	},
	__metatable = true,
})
