--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控核心
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^13.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
local bRestricted = X.ENVIRONMENT.GAME_BRANCH == 'classic'
X.RegisterRestriction('MY_TeamMon', { ['*'] = false, classic = true })
X.RegisterRestriction('MY_TeamMon.MapRestriction', { ['*'] = true })
X.RegisterRestriction('MY_TeamMon.HiddenBuff', { ['*'] = true })
X.RegisterRestriction('MY_TeamMon.HiddenSkill', { ['*'] = true })
X.RegisterRestriction('MY_TeamMon.HiddenDoodad', { ['*'] = true })
X.RegisterRestriction('MY_TeamMon.Note', { ['*'] = true })
X.RegisterRestriction('MY_TeamMon.AutoSelect', { ['*'] = true })
--------------------------------------------------------------------------

local MY_SplitString, MY_TrimString = X.SplitString, X.TrimString
local MY_GetFormatText, MY_GetPureText = X.GetFormatText, X.GetPureText
local FireUIEvent, MY_IsVisibleBuff, Table_IsSkillShow = FireUIEvent, X.IsVisibleBuff, Table_IsSkillShow
local GetHeadTextForceFontColor, TargetPanel_SetOpenState = GetHeadTextForceFontColor, TargetPanel_SetOpenState

local MY_TM_REMOTE_DATA_ROOT = X.FormatPath({'userdata/team_mon/remote/', X.PATH_TYPE.GLOBAL})
local MY_TM_TYPE = {
	OTHER           = 0,
	BUFF_GET        = 1,
	BUFF_LOSE       = 2,
	NPC_ENTER       = 3,
	NPC_LEAVE       = 4,
	NPC_TALK        = 5,
	NPC_LIFE        = 6,
	NPC_FIGHT       = 7,
	SKILL_BEGIN     = 8,
	SKILL_END       = 9,
	SYS_TALK        = 10,
	NPC_ALLLEAVE    = 11,
	NPC_DEATH       = 12,
	NPC_ALLDEATH    = 13,
	TALK_MONITOR    = 14,
	COMMON          = 15,
	NPC_MANA        = 16,
	DOODAD_ENTER    = 17,
	DOODAD_LEAVE    = 18,
	DOODAD_ALLLEAVE = 19,
	CHAT_MONITOR    = 20,
}
local MY_TM_SCRUTINY_TYPE = { SELF = 1, TEAM = 2, ENEMY = 3, TARGET = 4 }
local MY_TM_SPECIAL_MAP = {
	COMMON = -1, -- 通用
	CITY = -2, -- 主城
	DUNGEON = -3, -- 秘境
	TEAM_DUNGEON = -4, -- 小队秘境
	RAID_DUNGEON = -5, -- 团队秘境
	STARVE = -6, -- 浪客行
	VILLAGE = -7, -- 野外
	RECYCLE_BIN = -9, -- 回收站
}
local MY_TM_SPECIAL_MAP_NAME = {
	[MY_TM_SPECIAL_MAP.COMMON] = _L['Common data'],
	[MY_TM_SPECIAL_MAP.CITY] = _L['City data'],
	[MY_TM_SPECIAL_MAP.VILLAGE] = _L['Village data'],
	[MY_TM_SPECIAL_MAP.DUNGEON] = _L['Dungeon data'],
	[MY_TM_SPECIAL_MAP.TEAM_DUNGEON] = _L['Team dungeon data'],
	[MY_TM_SPECIAL_MAP.RAID_DUNGEON] = _L['Raid dungeon data'],
	[MY_TM_SPECIAL_MAP.STARVE] = _L['Starve data'],
	[MY_TM_SPECIAL_MAP.RECYCLE_BIN] = _L['Recycle bin data'],
}
local MY_TM_SPECIAL_MAP_INFO = {}
for _, dwMapID in pairs(MY_TM_SPECIAL_MAP) do
	local map = X.SetmetaReadonly({
		dwID = dwMapID,
		dwMapID = dwMapID,
		szName = MY_TM_SPECIAL_MAP_NAME[dwMapID],
	})
	MY_TM_SPECIAL_MAP_INFO[map.szName] = map
	MY_TM_SPECIAL_MAP_INFO[map.dwMapID] = map
end
-- 核心优化变量
local MY_TM_CORE_PLAYERID = 0
local MY_TM_CORE_NAME     = 0

local MY_TM_MAX_INTERVAL  = 300
local MY_TM_MAX_CACHE     = 3000 -- 最大的cache数量 主要是UI的问题
local MY_TM_DEL_CACHE     = 1000 -- 每次清理的数量 然后会做一次gc
local MY_TM_INIFILE       = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon.ini'

local MY_TM_SHARE_QUEUE  = {}
local MY_TM_MARK_QUEUE   = {}
local MY_TM_MARK_IDLE    = true -- 标记空闲
local MY_TM_SHIELDED_MAP = false -- 标记当前在功能限制地图 限制所有功能监听
local MY_TM_PVP_MAP      = false -- 标记当前在可能发生PVP战斗的地图 限制战斗功能监听
----
local MY_TM_LEFT_BRACKET      = _L['[']
local MY_TM_RIGHT_BRACKET     = _L[']']
local MY_TM_LEFT_BRACKET_XML  = MY_GetFormatText(MY_TM_LEFT_BRACKET, 44, 255, 255, 255)
local MY_TM_RIGHT_BRACKET_XML = MY_GetFormatText(MY_TM_RIGHT_BRACKET, 44, 255, 255, 255)
----
local MY_TM_TYPE_LIST = { 'BUFF', 'DEBUFF', 'CASTING', 'NPC', 'DOODAD', 'TALK', 'CHAT' }

local MYTM_EVENTS = {
	'NPC_ENTER_SCENE',
	'NPC_LEAVE_SCENE',
	'MY_TM_NPC_FIGHT',
	'MY_TM_NPC_ENTER_SCENE',
	'MY_TM_NPC_ALL_LEAVE_SCENE',
	'MY_TM_NPC_LIFE_CHANGE',
	'MY_TM_NPC_MANA_CHANGE',

	'DOODAD_ENTER_SCENE',
	'DOODAD_LEAVE_SCENE',
	'MY_TM_DOODAD_ENTER_SCENE',
	'MY_TM_DOODAD_ALL_LEAVE_SCENE',

	'BUFF_UPDATE',
	'SYS_MSG',
	'DO_SKILL_CAST',

	'PLAYER_SAY',
	'ON_WARNING_MESSAGE',

	'PARTY_SET_MARK',
}

local CACHE = {
	TEMP        = {}, -- 近期事件记录MAP 这里用弱表 方便处理
	MAP         = {},
	NPC_LIST    = {},
	DOODAD_LIST = {},
	SKILL_LIST  = {},
	INTERVAL    = {},
	CD_STR      = {},
	HP_CD_STR   = {},
}

local D = X.SetmetaLazyload({
	FILE   = {}, -- 文件原始数据
	CONFIG = {}, -- 文件原始配置项
	TEMP   = {}, -- 近期事件记录
	DATA   = {}, -- 需要监控的数据合集
}, {
	PW = function() return X.SECRET['FILE::TEAM_MON_DATA_PW'] end,
})

-- 初始化table 虽然写法没有直接写来得好 但是为了方便以后改动
do
	for k, v in ipairs(MY_TM_TYPE_LIST) do
		D.FILE[v]         = {}
		D.DATA[v]         = {}
		D.TEMP[v]         = {}
		CACHE.MAP[v]      = {}
		CACHE.INTERVAL[v] = {}
		CACHE.TEMP[v]     = setmetatable({}, { __mode = 'v' })
		if v == 'TALK' or v == 'CHAT' then -- init talk stru
			CACHE.MAP[v].HIT   = {}
			CACHE.MAP[v].OTHER = {}
		end
	end
end

local O = X.CreateUserSettingsModule('MY_TeamMon', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bCommon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushScreenHead = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushCenterAlarm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushBigFontAlarm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushTeamPanel = { -- 面板buff监控
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushFullScreen = { -- 全屏泛光
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushTeamChannel = { -- 团队报警
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bPushWhisperChannel = { -- 密聊报警
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bPushBuffList = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPushPartyBuffList = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})

local function GetUserDataPath()
	local ePathType = O.bCommon and X.PATH_TYPE.GLOBAL or X.PATH_TYPE.ROLE
	local szPathV1 = X.FormatPath({'userdata/TeamMon/Config.jx3dat', ePathType})
	local szPath = X.FormatPath({'userdata/team_mon/local.jx3dat', ePathType})
	if IsLocalFileExist(szPathV1) then
		local data = X.LoadLUAData(szPathV1)
		X.SaveLUAData(szPath, {
			data = data,
			config = {},
		})
		CPath.DelFile(szPathV1)
	end
	X.Debug('[MY_TeamMon] Data path: ' .. szPath, X.DEBUG_LEVEL.LOG)
	return szPath
end

local function RenderCustomText(szTemplate, szSender, szReceiver, aBackreferences)
	local tVar = X.Clone(aBackreferences) or {}
	tVar.sender = szSender
	tVar.receiver = szReceiver
	return X.RenderTemplateString(szTemplate, tVar, -1, false, false)
end

local function FilterCustomText(szTemplate, szSender, szReceiver, aBackreferences)
	local tVar = X.Clone(aBackreferences) or {}
	tVar.sender = szSender
	tVar.receiver = szReceiver
	return X.RenderTemplateString(szTemplate, tVar, -1, true, false)
end

local function ParseCustomText(szTemplate, szSender, szReceiver, aBackreferences)
	local tVar = X.Clone(aBackreferences) or {}
	tVar.sender = szSender
	tVar.receiver = szReceiver
	return X.RenderTemplateString(szTemplate, tVar, 8, true, true)
end

local function ConstructSpeech(aText, aXml, szText, nFont, nR, nG, nB)
	if aXml then
		if X.IsString(nFont) then
			table.insert(aXml, nFont)
		else
			table.insert(aXml, MY_GetFormatText(szText, nFont, nR, nG, nB))
		end
	end
	if aText then
		table.insert(aText, szText)
	end
end

-- 解析分段倒计时
---@param szCountdown string @倒计时字符串，如 “10,文本提示;20,文本提示;30,文本提示”
---@return table @倒计时列表
local function ParseCountdown(szCountdown)
	if not CACHE.CD_STR[szCountdown] then
		local aCountdown, bError = {}, false
		for _, szPart in ipairs(MY_SplitString(szCountdown, ';')) do
			local aParams, bPartError = MY_SplitString(szPart, ','), true
			if #aParams == 2 then
				local nTime = tonumber(aParams[1])
				local szContent = aParams[2]
				if nTime and szContent and nTime and szContent ~= '' then
					table.insert(aCountdown, {
						nTime = nTime,
						szContent = szContent,
					})
					bPartError = false
				end
			end
			if bPartError then
				bError = true
			end
		end
		if X.IsEmpty(aCountdown) then
			aCountdown = nil
		else
			table.sort(aCountdown, function(a, b)
				return a.nTime < b.nTime
			end)
		end
		CACHE.CD_STR[szCountdown] = {aCountdown, bError}
	end
	return X.Clone(CACHE.CD_STR[szCountdown][1]), CACHE.CD_STR[szCountdown][2]
end

-- 解析气血内力监控
---@param szString string @气血内力监控字符串，如 “0.5-,气血下降50%提示;0.3+,气血回升30%提示,5;0.1,气血10%提示,15”，时间可选，不填时间时仅显示提示不显示倒计时
---@return table @气血内力监控列表
local function ParseHPCountdown(szString)
	if not CACHE.HP_CD_STR[szString] then
		local aHPCountdown, bError = {}, false
		for _, szPart in ipairs(MY_SplitString(szString, ';')) do
			local aParams, bPartError = MY_SplitString(szPart, ','), true
			if #aParams >= 2 and #aParams <= 3 then
				local nValue, szOperator = nil, aParams[1]:sub(-1)
				if szOperator == '+' or szOperator == '-' or szOperator == '*' then
					nValue = tonumber(aParams[1]:sub(1, -2))
				else
					szOperator = '*'
					nValue = tonumber(aParams[1])
				end
				local szContent = aParams[2]
				local nTime = aParams[3] and tonumber(aParams[3]) or nil
				if nValue and szOperator and szContent ~= '' and (nTime or not aParams[3]) then
					table.insert(aHPCountdown, {
						nValue = nValue,
						szOperator = szOperator,
						szContent = szContent,
						nTime = nTime,
					})
					bPartError = false
				end
			end
			if bPartError then
				bError = true
			end
		end
		if X.IsEmpty(aHPCountdown) then
			aHPCountdown = nil
		else
			table.sort(aHPCountdown, function(a, b)
				return a.nValue > b.nValue
			end)
		end
		CACHE.HP_CD_STR[szString] = {aHPCountdown, bError}
	end
	return X.Clone(CACHE.HP_CD_STR[szString][1]), CACHE.HP_CD_STR[szString][2]
end

function D.OnFrameCreate()
	this:RegisterEvent('MY_TM_LOADING_END')
	this:RegisterEvent('MY_TM_CREATE_CACHE')
	this:RegisterEvent('LOADING_END')
	D.Enable(O.bEnable)
	D.Log('init success!')
	X.BreatheCall('MY_TM_CACHE_CLEAR', 60 * 2 * 1000, function()
		for k, v in ipairs(MY_TM_TYPE_LIST) do
			if #D.TEMP[v] > MY_TM_MAX_CACHE then
				D.FreeCache(v)
			end
		end
		for k, v in pairs(CACHE.INTERVAL) do
			for kk, vv in pairs(v) do
				if #vv > MY_TM_MAX_INTERVAL then
					CACHE.INTERVAL[k][kk] = {}
				end
			end
		end
	end)
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	if not me then
		return
	end
	-- local dwType, dwID = me.GetTarget()
	for dwTemplateID, npcInfo in pairs(CACHE.NPC_LIST) do
		local data = D.GetData('NPC', dwTemplateID)
		if data then
			-- local bTempTarget = false
			-- for kk, vv in ipairs(data.tCountdown or {}) do
			-- 	if vv.nClass == MY_TM_TYPE.NPC_MANA then
			-- 		bTempTarget = true
			-- 		break
			-- 	end
			-- end
			local bFightFlag = false
			local fLifePer, fManaPer
			-- TargetPanel_SetOpenState(true)
			for dwNpcID, tab in pairs(npcInfo.tList) do
				local npc = GetNpc(dwNpcID)
				if npc then
					-- if bTempTarget then
					-- 	X.SetTarget(TARGET.NPC, vv)
					-- 	X.SetTarget(dwType, dwID)
					-- end
					-- 血量变化检查
					local fCurrentLife, fMaxLife = X.GetObjectLife(npc)
					if fMaxLife > 1 then
						local nLife = math.floor(fCurrentLife / fMaxLife * 100)
						if tab.nLife ~= nLife then
							local nStart = tab.nLife or nLife
							local bIncrease = nLife >= nStart
							local nStep = bIncrease and 1 or -1
							if tab.nLife then
								nStart = nStart + nStep
							end
							for nLife = nStart, nLife, nStep do
								FireUIEvent('MY_TM_NPC_LIFE_CHANGE', dwTemplateID, nLife, bIncrease)
							end
							tab.nLife = nLife
						end
					end
					-- 蓝量变化检查
					-- if bTempTarget then
					if npc.nMaxMana > 1 then
						local nMana = math.floor(npc.nCurrentMana / npc.nMaxMana * 100)
						if tab.nMana ~= nMana then
							local nStart = tab.nMana or nMana
							local bIncrease = nMana >= nStart
							local nStep = bIncrease and 1 or -1
							if tab.nMana then
								nStart = nStart + nStep
							end
							for nMana = nStart, nMana, nStep do
								FireUIEvent('MY_TM_NPC_MANA_CHANGE', dwTemplateID, nMana, bIncrease)
							end
							tab.nMana = nMana
						end
					end
					-- end
					-- 战斗标记检查
					if npc.bFightState ~= tab.bFightState then
						if npc.bFightState then
							local nTime = GetTime()
							npcInfo.nSec = nTime
							FireUIEvent('MY_TM_NPC_FIGHT', dwTemplateID, true, nTime)
						else
							local nTime = GetTime() - (npcInfo.nSec or GetTime())
							npcInfo.nSec = nil
							FireUIEvent('MY_TM_NPC_FIGHT', dwTemplateID, false, nTime)
						end
						tab.bFightState = npc.bFightState
					end
				end
			end
			-- TargetPanel_SetOpenState(false)
		end
	end
end

function D.OnSetMark(bFinish)
	if bFinish then
		MY_TM_MARK_IDLE = true
	end
	if MY_TM_MARK_IDLE and #MY_TM_MARK_QUEUE >= 1 then
		MY_TM_MARK_IDLE = false
		local r = table.remove(MY_TM_MARK_QUEUE, 1)
		local res, err, trace = X.XpCall(r.fnAction)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', 'MY_TeamMon_Mark ERROR: ' .. err .. '\n' .. trace)
			D.OnSetMark(true)
		end
	end
end

function D.OnEvent(szEvent)
	if szEvent == 'BUFF_UPDATE' then
		D.OnBuff(arg0, arg1, arg3, arg4, arg5, arg8, arg9)
	elseif szEvent == 'SYS_MSG' then
		if arg0 == 'UI_OME_DEATH_NOTIFY' then
			if not IsPlayer(arg1) then
				D.OnDeath(arg1, arg2)
			end
		elseif arg0 == 'UI_OME_SKILL_CAST_LOG' then
			D.OnSkillCast(arg1, arg2, arg3, arg0)
		elseif (arg0 == 'UI_OME_SKILL_BLOCK_LOG'
		or arg0 == 'UI_OME_SKILL_SHIELD_LOG' or arg0 == 'UI_OME_SKILL_MISS_LOG'
		or arg0 == 'UI_OME_SKILL_DODGE_LOG'	or arg0 == 'UI_OME_SKILL_HIT_LOG')
		and arg3 == SKILL_EFFECT_TYPE.SKILL then
			D.OnSkillCast(arg1, arg4, arg5, arg0)
		elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' and arg4 == SKILL_EFFECT_TYPE.SKILL then
			D.OnSkillCast(arg1, arg5, arg6, arg0)
		end
	elseif szEvent == 'DO_SKILL_CAST' then
		D.OnSkillCast(arg0, arg1, arg2, szEvent)
	elseif szEvent == 'PARTY_SET_MARK' then
		D.OnSetMark(true)
	elseif szEvent == 'PLAYER_SAY' then
		if not IsPlayer(arg1) then
			local szText = MY_GetPureText(arg0)
			if szText and szText ~= '' then
				D.OnCallMessage('TALK', szText, arg1, arg3 == '' and '%' or arg3)
			else
				X.Debug(_L['MY_TeamMon'], 'GetPureText ERROR: ' .. arg0, X.DEBUG_LEVEL.WARNING)
			end
		end
	elseif szEvent == 'ON_WARNING_MESSAGE' then
		D.OnCallMessage('TALK', arg1)
	elseif szEvent == 'DOODAD_ENTER_SCENE' or szEvent == 'MY_TM_DOODAD_ENTER_SCENE' then
		local doodad = GetDoodad(arg0)
		if doodad then
			D.OnDoodadEvent(doodad, true)
		end
	elseif szEvent == 'DOODAD_LEAVE_SCENE' then
		local doodad = GetDoodad(arg0)
		if doodad then
			D.OnDoodadEvent(doodad, false)
		end
	elseif szEvent == 'MY_TM_DOODAD_ALL_LEAVE_SCENE' then
		D.OnDoodadAllLeave(arg0)
	elseif szEvent == 'NPC_ENTER_SCENE' or szEvent == 'MY_TM_NPC_ENTER_SCENE' then
		local npc = GetNpc(arg0)
		if npc then
			D.OnNpcEvent(npc, true)
		end
	elseif szEvent == 'NPC_LEAVE_SCENE' then
		local npc = GetNpc(arg0)
		if npc then
			D.OnNpcEvent(npc, false)
		end
	elseif szEvent == 'MY_TM_NPC_ALL_LEAVE_SCENE' then
		D.OnNpcAllLeave(arg0)
	elseif szEvent == 'MY_TM_NPC_FIGHT' then
		D.OnNpcFight(arg0, arg1)
	elseif szEvent == 'MY_TM_NPC_LIFE_CHANGE' or szEvent == 'MY_TM_NPC_MANA_CHANGE' then
		D.OnNpcInfoChange(szEvent, arg0, arg1, arg2)
	elseif szEvent == 'LOADING_END' or szEvent == 'MY_TM_CREATE_CACHE' or szEvent == 'MY_TM_LOADING_END' then
		D.FireCrossMapEvent('before')
		D.CreateData(szEvent)
		X.DelayCall('MY_TeamMon__FireCrossMapEvent__after', D.FireCrossMapEvent, 'after')
	end
end

function D.SendChat(...)
	if bRestricted then
		return
	end
	return X.SendChat(...)
end

function D.SendBgMsg(...)
	if bRestricted then
		return
	end
	return X.SendBgMsg(...)
end

function D.Log(szMsg)
	return Log('[MY_TeamMon] ' .. szMsg)
end

function D.Talk(szType, szMsg, szTarget)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local szKey = 'MY_TeamMon.' .. GetLogicFrameCount()
	if szType == 'RAID' then
		if szTarget then
			szMsg = X.StringReplaceW(szMsg, _L['['] .. szTarget .. _L[']'], ' [' .. szTarget .. '] ')
			szMsg = X.StringReplaceW(szMsg, _L['['] .. g_tStrings.STR_YOU .. _L[']'], ' [' .. szTarget .. '] ')
		end
		if me.IsInParty() then
			D.SendChat(PLAYER_TALK_CHANNEL.RAID, szMsg, { uuid = szKey .. GetStringCRC(szType .. szMsg) })
		end
	elseif szType == 'WHISPER' then
		if szTarget then
			szMsg = X.StringReplaceW(szMsg, '[' .. szTarget .. ']', _L['['] .. g_tStrings.STR_YOU .. _L[']'])
			szMsg = X.StringReplaceW(szMsg, _L['['] .. szTarget .. _L[']'], _L['['] .. g_tStrings.STR_YOU .. _L[']'])
		end
		if szTarget == me.szName then
			X.OutputWhisper(szMsg, _L['MY_TeamMon'])
		else
			D.SendChat(szTarget, szMsg, { uuid = szKey .. GetStringCRC(szType .. szMsg) })
		end
	elseif szType == 'RAID_WHISPER' then
		if me.IsInParty() then
			local team = GetClientTeam()
			for _, v in ipairs(team.GetTeamMemberList()) do
				local szName = team.GetClientTeamMemberName(v)
				local szText = X.StringReplaceW(szMsg, '[' .. szName .. ']', _L['['] .. g_tStrings.STR_YOU ..  _L[']'])
				if szName == me.szName then
					X.OutputWhisper(szText, _L['MY_TeamMon'])
				else
					D.SendChat(szName, szText, { uuid = szKey .. GetStringCRC(szType .. szText .. szName) })
				end
			end
		end
	end
end

-- 更新当前地图使用条件
function D.UpdateShieldStatus()
	local bRestricted = X.IsRestricted('MY_TeamMon.MapRestriction')
	local bRestrictedMap = bRestricted and (
		X.IsInArena() or X.IsInBattleField()
		or X.IsInPubg() or X.IsInZombieMap()
		or X.IsInMobaMap())
	local bPvpMap = bRestricted and not X.IsInDungeon()
	if bRestrictedMap then
		X.Sysmsg(_L['MY_TeamMon is blocked in this map, temporary disabled.'])
	end
	MY_TM_SHIELDED_MAP, MY_TM_PVP_MAP = bRestrictedMap, bPvpMap
end

local function CreateCache(szType, tab)
	local data  = D.DATA[szType]
	local cache = CACHE.MAP[szType]
	for k, v in ipairs(tab) do
		data[#data + 1] = v
		if v.nLevel then
			cache[v.dwID] = cache[v.dwID] or {}
			cache[v.dwID][v.nLevel] = k
		else -- other
			cache[v.dwID] = k
		end
	end
	D.Log('create ' .. szType .. ' data success!')
end
-- 核心函数 缓存创建 UI缓存创建
function D.CreateData(szEvent)
	local nTime   = GetTime()
	local dwMapID = X.GetMapID(true)
	local me = GetClientPlayer()
	-- 用于更新 BUFF / CAST / NPC 缓存处理 不需要再获取本地对象
	MY_TM_CORE_NAME     = me.szName
	MY_TM_CORE_PLAYERID = me.dwID
	D.Log('get player info cache success!')
	-- 更新功能屏蔽状态
	D.UpdateShieldStatus()
	-- 重建metatable 获取ALL数据的方法 主要用于UI 逻辑中毫无作用
	for kType, vTable in pairs(D.FILE)  do
		setmetatable(D.FILE[kType], { __index = function(me, index)
			if index == _L['All data'] then
				local t = {}
				for k, v in pairs(vTable) do
					if k ~= MY_TM_SPECIAL_MAP.RECYCLE_BIN then
						for kk, vv in ipairs(v) do
							t[#t +1] = vv
						end
					end
				end
				return t
			end
		end })
		-- 重建所有数据的metatable
		for k, v in pairs(vTable) do
			for kk, vv in ipairs(v) do
				setmetatable(vv, { __index = function(_, val)
					if val == 'dwMapID' then
						return k
					elseif val == 'nIndex' then
						return kk
					end
				end })
			end
		end
	end
	D.Log('create metatable success!')
	-- 清空当前数据和MAP
	for k, v in pairs(D.DATA) do
		D.DATA[k] = {}
	end
	for k, v in pairs(CACHE.MAP) do
		CACHE.MAP[k] = {}
		if k == 'TALK' or k == 'CHAT' then
			CACHE.MAP[k].HIT   = {}
			CACHE.MAP[k].OTHER = {}
		end
	end
	pcall(Raid_MonitorBuffs) -- clear
	-- 重建MAP
	for _, v in ipairs({ 'BUFF', 'DEBUFF', 'CASTING', 'NPC', 'DOODAD' }) do
		for _, d in D.IterTable(MY_TeamMon.GetTable(v), dwMapID, false) do
			CreateCache(v, d)
		end
	end
	-- 单独重建TALK数据
	do
		for _, vType in ipairs({ 'TALK', 'CHAT' }) do
			local data = D.FILE[vType]
			local talk = D.DATA[vType]
			CACHE.MAP[vType] = {
				HIT   = {},
				OTHER = {},
			}
			local cache = CACHE.MAP[vType]
			for _, v in D.IterTable(data, dwMapID, true) do
				talk[#talk + 1] = v
			end
			for k, v in ipairs(talk) do
				if v.szContent then
					if v.szContent:find('{$me}') or v.szContent:find('{$team}') or v.bSearch or v.bReg then -- 具有通配符和搜索标记的数据不作 HIT 高速匹配策略考虑
						table.insert(cache.OTHER, v)
					elseif not cache.HIT[v.szContent] then -- 按照数据优先级顺序（地图＞地图组＞通用），同级按照下标先后顺序，只取第一个匹配结果
						cache.HIT[v.szContent] = cache.HIT[v.szContent] or {}
						cache.HIT[v.szContent][v.szTarget or 'sys'] = v
					end
				else
					X.Debug('MY_TeamMon', '[Warning] ' .. vType .. ' data is not szContent #' .. k .. ', please do check it!', X.DEBUG_LEVEL.WARNING)
				end
			end
			D.Log('create ' .. vType .. ' data success!')
		end
	end
	if O.bPushTeamPanel then
		local tBuff = {}
		for k, v in ipairs(D.DATA.BUFF) do
			if v[MY_TM_TYPE.BUFF_GET] and v[MY_TM_TYPE.BUFF_GET].bTeamPanel then
				table.insert(tBuff, v.dwID)
			end
		end
		for k, v in ipairs(D.DATA.DEBUFF) do
			if v[MY_TM_TYPE.BUFF_GET] and v[MY_TM_TYPE.BUFF_GET].bTeamPanel then
				table.insert(tBuff, v.dwID)
			end
		end
		pcall(Raid_MonitorBuffs, tBuff)
	end
	D.Log('MAPID: ' .. dwMapID ..  ' create data success:' .. GetTime() - nTime  .. 'ms')
	-- gc
	if szEvent ~= 'MY_TM_CREATE_CACHE' then
		CACHE.NPC_LIST   = {}
		CACHE.SKILL_LIST = {}
		CACHE.HP_CD_STR  = {}
		D.Log('collectgarbage(\'count\') ' .. collectgarbage('count'))
		collectgarbage('collect')
		D.Log('collectgarbage(\'collect\') ' .. collectgarbage('count'))
	end
	FireUIEvent('MY_TMUI_FREECACHE')
end

function D.FreeCache(szType)
	local t = {}
	local tTemp = D.TEMP[szType]
	for i = MY_TM_DEL_CACHE, #tTemp do
		t[#t + 1] = tTemp[i]
	end
	D.TEMP[szType] = t
	collectgarbage('collect')
	FireUIEvent('MY_TMUI_TEMP_RELOAD', szType)
	D.Log(szType .. ' cache clear!')
end

function D.CheckScrutinyType(nScrutinyType, dwID)
	if nScrutinyType == MY_TM_SCRUTINY_TYPE.SELF and dwID ~= MY_TM_CORE_PLAYERID then
		return false
	elseif nScrutinyType == MY_TM_SCRUTINY_TYPE.TEAM and (not X.IsParty(dwID) and dwID ~= MY_TM_CORE_PLAYERID) then
		return false
	elseif nScrutinyType == MY_TM_SCRUTINY_TYPE.ENEMY and not IsEnemy(MY_TM_CORE_PLAYERID, dwID) then
		return false
	elseif nScrutinyType == MY_TM_SCRUTINY_TYPE.TARGET then
		local obj = X.GetObject(X.GetTarget())
		if not obj or obj and obj.dwID ~= dwID then
			return false
		end
	end
	return true
end

function D.CheckKungFu(tKungFu)
	if tKungFu['SKILL#' .. UI_GetPlayerMountKungfuID()] then
		return true
	end
	return false
end

-- 智能标记逻辑
function D.SetTeamMark(szType, tMark, dwCharacterID, dwID, nLevel)
	if not X.IsMarker() or bRestricted then
		return
	end
	local function fnGetNextMark()
		local team, tar = GetClientTeam()
		local tTeamMark = X.FlipObjectKV(team.GetTeamMark())
		if szType == 'NPC' then
			for nMark, bMark in ipairs(tMark) do
				if bMark and tTeamMark[nMark] ~= dwCharacterID then
					tar = tTeamMark[nMark] and tTeamMark[nMark] ~= 0 and X.GetObject(tTeamMark[nMark])
					if not tar or tar.dwTemplateID ~= dwID then
						return nMark, dwCharacterID
					end
				end
			end
		elseif szType == 'BUFF' or szType == 'DEBUFF' then
			for nMark, bMark in ipairs(tMark) do
				if bMark and tTeamMark[nMark] ~= dwCharacterID then
					tar = tTeamMark[nMark] and tTeamMark[nMark] ~= 0 and X.GetObject(tTeamMark[nMark])
					if not tar or not X.GetBuff(tar, dwID) then
						return nMark, dwCharacterID
					end
				end
			end
		elseif szType == 'CASTING' then
			for nMark, bMark in ipairs(tMark) do
				if bMark and (not tTeamMark[nMark] or tTeamMark[nMark] ~= dwCharacterID) then
					return nMark, dwCharacterID
				end
			end
		end
	end
	local fnAction = function()
		local nMark, dwCharacterID = fnGetNextMark()
		if nMark and dwCharacterID and X.SetTeamMarkTarget(nMark, dwCharacterID) then
			return
		end
		D.OnSetMark(true) -- 标记失败 直接处理下一个
	end
	table.insert(MY_TM_MARK_QUEUE, {
		fnAction = fnAction,
	})
	D.OnSetMark()
end
-- 倒计时处理 支持定义无限的倒计时
function D.CountdownEvent(data, nClass, szSender, szReceiver, aBackreferences)
	if data.tCountdown then
		for k, v in ipairs(data.tCountdown) do
			if nClass == v.nClass then
				local nType, szKey = nClass, v.key
				if szKey then
					nType = MY_TM_TYPE.COMMON
					szKey = RenderCustomText(szKey, szSender, szReceiver, aBackreferences)
				else
					szKey = k .. '.' .. (data.dwID or 0) .. '.' .. (data.nLevel or 0) .. '.' .. (data.nIndex or 0) .. '.' .. X.EncodeLUAData(aBackreferences)
				end
				local tParam = {
					nFrame   = v.nFrame,
					nTime    = v.nTime,
					nRefresh = v.nRefresh,
					szName   = FilterCustomText(v.szName or data.szName, szSender, szReceiver, aBackreferences),
					nIcon    = v.nIcon or data.nIcon or 340,
					bTalk    = v.bTeamChannel,
					bHold    = v.bHold,
				}
				D.FireCountdownEvent(nType, szKey, tParam, szSender, szReceiver)
			end
		end
	end
end

-- 发布事件 为了方便日后修改 集中起来
function D.FireCountdownEvent(nType, szKey, tParam, szSender, szReceiver)
	if not O.bPushTeamChannel then
		tParam.bTalk = false
	end
	FireUIEvent('MY_TM_ST_CREATE', nType, szKey, tParam, szSender, szReceiver)
end

function D.GetSrcName(dwID)
	if not dwID then
		return nil
	end
	if dwID == 0 then
		return g_tStrings.COINSHOP_SOURCE_NULL
	end
	local KObject = IsPlayer(dwID) and GetPlayer(dwID) or GetNpc(dwID)
	if KObject then
		return X.GetObjectName(KObject)
	else
		return dwID
	end
end

-- local a=GetTime();for i=1, 10000 do FireUIEvent('BUFF_UPDATE',UI_GetClientPlayerID(),false,1,true,i,1,1,1,1,0) end;Output(GetTime()-a)
-- 事件操作
function D.OnBuff(dwOwner, bDelete, bCanCancel, dwBuffID, nCount, nBuffLevel, dwSkillSrcID)
	if MY_TM_SHIELDED_MAP or (MY_TM_PVP_MAP and dwOwner ~= MY_TM_CORE_PLAYERID) then
		return
	end
	local szType = bCanCancel and 'BUFF' or 'DEBUFF'
	local key = dwBuffID .. '_' .. nBuffLevel
	local data = D.GetData(szType, dwBuffID, nBuffLevel)
	local nTime = GetTime()
	if not bDelete then
		-- 近期记录
		if MY_IsVisibleBuff(dwBuffID, nBuffLevel) or not X.IsRestricted('MY_TeamMon.HiddenBuff') then
			local tWeak, tTemp = CACHE.TEMP[szType], D.TEMP[szType]
			if not tWeak[key] then
				local t = {
					dwMapID      = X.GetMapID(),
					dwID         = dwBuffID,
					nLevel       = nBuffLevel,
					bIsPlayer    = dwSkillSrcID ~= 0 and IsPlayer(dwSkillSrcID),
					szSrcName    = D.GetSrcName(dwSkillSrcID),
					nCurrentTime = GetCurrentTime()
				}
				tWeak[key] = t
				tTemp[#tTemp + 1] = tWeak[key]
				FireUIEvent('MY_TMUI_TEMP_UPDATE', szType, t)
			end
			-- 记录时间
			CACHE.INTERVAL[szType][key] = CACHE.INTERVAL[szType][key] or {}
			if #CACHE.INTERVAL[szType][key] > 0 then
				if nTime - CACHE.INTERVAL[szType][key][#CACHE.INTERVAL[szType][key]] > 1000 then
					CACHE.INTERVAL[szType][key][#CACHE.INTERVAL[szType][key] + 1] = nTime
				end
			else
				CACHE.INTERVAL[szType][key][#CACHE.INTERVAL[szType][key] + 1] = nTime
			end
		end
	end
	if data then
		local cfg, nClass
		if data.nScrutinyType and not D.CheckScrutinyType(data.nScrutinyType, dwOwner) then -- 监控对象检查
			return
		end
		if data.tKungFu and not D.CheckKungFu(data.tKungFu) then -- 自身身法需求检查
			return
		end
		if data.nCount and nCount < data.nCount then -- 层数检查
			return
		end
		if bDelete then
			cfg, nClass = data[MY_TM_TYPE.BUFF_LOSE], MY_TM_TYPE.BUFF_LOSE
		else
			cfg, nClass = data[MY_TM_TYPE.BUFF_GET], MY_TM_TYPE.BUFF_GET
		end
		local szSender = X.GetObjectName(IsPlayer(dwSkillSrcID) and TARGET.PLAYER or TARGET.NPC, dwSkillSrcID)
		local szReceiver = X.GetObjectName(IsPlayer(dwOwner) and TARGET.PLAYER or TARGET.NPC, dwOwner)
		D.CountdownEvent(data, nClass, szSender, szReceiver)
		if cfg then
			local szName, nIcon = X.GetBuffName(dwBuffID, nBuffLevel)
			if data.szName then
				szName = FilterCustomText(data.szName, szSender, szReceiver)
			end
			if data.nIcon then
				nIcon = data.nIcon
			end
			local aXml, aText = {}, {}
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szReceiver == MY_TM_CORE_NAME and g_tStrings.STR_YOU or szReceiver, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if nClass == MY_TM_TYPE.BUFF_GET then
				ConstructSpeech(aText, aXml, _L['Get buff'], 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, szName .. ' x' .. nCount, 44, 255, 255, 0)
				if data.szNote and not X.IsRestricted('MY_TeamMon.Note') then
					ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote, szSender, szReceiver), 44, 255, 255, 255)
				end
			else
				ConstructSpeech(aText, aXml, _L['Lose buff'], 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
			end
			local szXml, szText = table.concat(aXml), table.concat(aText)
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm and (MY_TM_CORE_PLAYERID == dwOwner or not IsPlayer(dwOwner)) then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { GetHeadTextForceFontColor(dwOwner, MY_TM_CORE_PLAYERID) })
			end

			-- 获得处理
			if nClass == MY_TM_TYPE.BUFF_GET then
				if cfg.bSelect then
					SetTarget(IsPlayer(dwOwner) and TARGET.PLAYER or TARGET.NPC, dwOwner)
				end
				if cfg.bAutoCancel and MY_TM_CORE_PLAYERID == dwOwner then
					X.CancelBuff(GetClientPlayer(), dwBuffID)
				end
				if cfg.tMark then
					D.SetTeamMark(szType, cfg.tMark, dwOwner, dwBuffID, nBuffLevel)
				end
				-- 重要Buff列表
				if O.bPushPartyBuffList and IsPlayer(dwOwner) and cfg.bPartyBuffList and (X.IsParty(dwOwner) or MY_TM_CORE_PLAYERID == dwOwner) then
					FireUIEvent('MY_TM_PARTY_BUFF_LIST', dwOwner, data.dwID, data.nLevel, data.nIcon)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', dwOwner, szType, 'MY_TM_BUFF_' .. data.dwID, {
						dwBuffID = data.dwID,
						szText = szName,
						col = data.col or (szType == 'BUFF' and {0, 255, 0} or {255, 0, 0}),
					})
					FireUIEvent('MY_TM_SA_CREATE', szType, dwOwner, { dwID = data.dwID, col = data.col, text = szName })
				end
				if MY_TM_CORE_PLAYERID == dwOwner then
					if O.bPushBuffList and cfg.bBuffList then
						local col = szType == 'BUFF' and { 0, 255, 0 } or { 255, 0, 0 }
						if data.col then
							col = data.col
						end
						FireUIEvent('MY_TM_BL_CREATE', data.dwID, data.nLevel, col, data, szSender, szReceiver)
					end
					-- 全屏泛光
					if O.bPushFullScreen and cfg.bFullScreen then
						FireUIEvent('MY_TM_FS_CREATE', data.dwID .. '_'  .. data.nLevel, {
							nTime = 3,
							col = data.col,
							tBindBuff = { data.dwID, data.nLevel }
						})
					end
				end
				-- 添加到团队面板
				if O.bPushTeamPanel and cfg.bTeamPanel and (not cfg.bOnlySelfSrc or dwSkillSrcID == MY_TM_CORE_PLAYERID) and X.IsEmpty(data.aCataclysmBuff) then
					FireUIEvent('MY_RAID_REC_BUFF', dwOwner, {
						dwID      = data.dwID,
						nLevel    = data.bCheckLevel and data.nLevel or 0,
						nLevelEx  = data.nLevel,
						nStackNum = data.nCount,
						col       = data.col,
						nIcon     = data.nIcon,
						bOnlyMine = cfg.bOnlySelfSrc,
					})
				end
			end
			if O.bPushTeamChannel and cfg.bTeamChannel then
				D.Talk('RAID', szText, szReceiver)
			end
			if O.bPushWhisperChannel and cfg.bWhisperChannel then
				D.Talk('WHISPER', szText, szReceiver)
			end
		end
	end
end

-- 技能事件
function D.OnSkillCast(dwCaster, dwCastID, dwLevel, szEvent)
	if MY_TM_SHIELDED_MAP or (MY_TM_PVP_MAP and dwCaster ~= MY_TM_CORE_PLAYERID) then
		return
	end
	local key = dwCastID .. '_' .. dwLevel
	local nTime = GetTime()
	CACHE.SKILL_LIST[dwCaster] = CACHE.SKILL_LIST[dwCaster] or {}
	if CACHE.SKILL_LIST[dwCaster][key] and nTime - CACHE.SKILL_LIST[dwCaster][key] < 62.5 then -- 1/16
		return
	end
	if dwCastID == 13165 then -- 内功切换
		if szEvent == 'UI_OME_SKILL_CAST_LOG' then
			FireUIEvent('MY_KUNGFU_SWITCH', dwCaster)
		end
	end
	local data = D.GetData('CASTING', dwCastID, dwLevel)
	if Table_IsSkillShow(dwCastID, dwLevel) or not X.IsRestricted('MY_TeamMon.HiddenSkill') then
		local tWeak, tTemp = CACHE.TEMP.CASTING, D.TEMP.CASTING
		if not tWeak[key] then
			local t = {
				dwMapID      = X.GetMapID(),
				dwID         = dwCastID,
				nLevel       = dwLevel,
				bIsPlayer    = IsPlayer(dwCaster),
				szSrcName    = D.GetSrcName(dwCaster),
				nCurrentTime = GetCurrentTime()
			}
			tWeak[key] = t
			tTemp[#tTemp + 1] = tWeak[key]
			FireUIEvent('MY_TMUI_TEMP_UPDATE', 'CASTING', t)
		end
		CACHE.INTERVAL.CASTING[key] = CACHE.INTERVAL.CASTING[key] or {}
		CACHE.INTERVAL.CASTING[key][#CACHE.INTERVAL.CASTING[key] + 1] = nTime
		CACHE.SKILL_LIST[dwCaster][key] = nTime
	end
	-- 监控数据
	if data then
		if data.nScrutinyType and not D.CheckScrutinyType(data.nScrutinyType, dwCaster) then -- 监控对象检查
			return
		end
		if data.tKungFu and not D.CheckKungFu(data.tKungFu) then -- 自身身法需求检查
			return
		end
		local szName, nIcon = X.GetSkillName(dwCastID, dwLevel)
		local szSender, szReceiver
		local KObject = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
		if KObject then
			szSender = X.GetObjectName(KObject)
			szReceiver = X.GetObjectName(X.GetObject(KObject.GetTarget()), 'auto')
		else
			szSender = X.GetObjectName(IsPlayer(dwCaster) and TARGET.PLAYER or TARGET.NPC, dwCaster)
		end
		if data.szName then
			szName = FilterCustomText(data.szName, szSender, szReceiver)
		end
		if data.nIcon then
			nIcon = data.nIcon
		end
		local cfg, nClass
		if szEvent == 'UI_OME_SKILL_CAST_LOG' then
			cfg, nClass = data[MY_TM_TYPE.SKILL_BEGIN], MY_TM_TYPE.SKILL_BEGIN
		else
			cfg, nClass = data[MY_TM_TYPE.SKILL_END], MY_TM_TYPE.SKILL_END
		end
		D.CountdownEvent(data, nClass, szSender, szReceiver)
		if cfg then
			local aXml, aText = {}, {}
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szSender, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if nClass == MY_TM_TYPE.SKILL_END then
				ConstructSpeech(aText, aXml, _L['use of'], 44, 255, 255, 255)
			else
				ConstructSpeech(aText, aXml, _L['Casting'], 44, 255, 255, 255)
			end
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if data.bMonTarget and szReceiver then
				ConstructSpeech(aText, aXml, g_tStrings.TARGET, 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aText, aXml, szReceiver == MY_TM_CORE_NAME and g_tStrings.STR_YOU or szReceiver, 44, 255, 255, 0)
				ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			end
			if data.szNote and not X.IsRestricted('MY_TeamMon.Note') then
				ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote, szSender, szReceiver), 44, 255, 255, 255)
			end
			local szXml, szText = table.concat(aXml), table.concat(aText)
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { GetHeadTextForceFontColor(dwCaster, MY_TM_CORE_PLAYERID) })
			end
			if not X.IsRestricted('MY_TeamMon.AutoSelect') and cfg.bSelect then
				SetTarget(IsPlayer(dwCaster) and TARGET.PLAYER or TARGET.NPC, dwCaster)
			end
			if cfg.tMark then
				D.SetTeamMark('CASTING', cfg.tMark, dwCaster, dwCastID, dwLevel)
			end
			-- 头顶报警
			if O.bPushScreenHead and cfg.bScreenHead then
				FireUIEvent('MY_LIFEBAR_COUNTDOWN', dwCaster, 'CASTING', 'MY_TM_CASTING_' .. data.dwID, {
					dwSkillID = dwCastID,
					szText = szName,
					col = data.col,
				})
				FireUIEvent('MY_TM_SA_CREATE', 'CASTING', dwCaster, { text = szName, col = data.col })
			end
			-- 全屏泛光
			if O.bPushFullScreen and cfg.bFullScreen then
				FireUIEvent('MY_TM_FS_CREATE', data.dwID .. '#SKILL#'  .. data.nLevel, { nTime = 3, col = data.col})
			end
			if O.bPushTeamChannel and cfg.bTeamChannel then
				D.Talk('RAID', szText, szReceiver)
			end
			if O.bPushWhisperChannel and cfg.bWhisperChannel then
				D.Talk('RAID_WHISPER', szText, szReceiver)
			end
		end
	end
end

-- NPC事件
function D.OnNpcEvent(npc, bEnter)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local data = D.GetData('NPC', npc.dwTemplateID)
	local nTime = GetTime()
	if bEnter then
		if not CACHE.NPC_LIST[npc.dwTemplateID] then
			CACHE.NPC_LIST[npc.dwTemplateID] = {
				tList       = {},
				nTime       = -1,
				nCount      = 0,
			}
		end
		CACHE.NPC_LIST[npc.dwTemplateID].tList[npc.dwID] = {
			bFightState = false,
		}
		CACHE.NPC_LIST[npc.dwTemplateID].nCount = CACHE.NPC_LIST[npc.dwTemplateID].nCount + 1
		local tWeak, tTemp = CACHE.TEMP.NPC, D.TEMP.NPC
		if not tWeak[npc.dwTemplateID] then
			local t = {
				dwMapID      = X.GetMapID(),
				dwID         = npc.dwTemplateID,
				nFrame       = select(2, GetNpcHeadImage(npc.dwID)),
				col          = { GetHeadTextForceFontColor(npc.dwID, MY_TM_CORE_PLAYERID) },
				nCurrentTime = GetCurrentTime()
			}
			tWeak[npc.dwTemplateID] = t
			tTemp[#tTemp + 1] = tWeak[npc.dwTemplateID]
			FireUIEvent('MY_TMUI_TEMP_UPDATE', 'NPC', t)
		end
		CACHE.INTERVAL.NPC[npc.dwTemplateID] = CACHE.INTERVAL.NPC[npc.dwTemplateID] or {}
		if #CACHE.INTERVAL.NPC[npc.dwTemplateID] > 0 then
			if nTime - CACHE.INTERVAL.NPC[npc.dwTemplateID][#CACHE.INTERVAL.NPC[npc.dwTemplateID]] > 500 then
				CACHE.INTERVAL.NPC[npc.dwTemplateID][#CACHE.INTERVAL.NPC[npc.dwTemplateID] + 1] = nTime
			end
		else
			CACHE.INTERVAL.NPC[npc.dwTemplateID][#CACHE.INTERVAL.NPC[npc.dwTemplateID] + 1] = nTime
		end
	else
		local npcInfo = CACHE.NPC_LIST[npc.dwTemplateID]
		if npcInfo then
			local tab = npcInfo.tList[npc.dwID]
			if tab then
				npcInfo.tList[npc.dwID] = nil
				npcInfo.nCount = npcInfo.nCount - 1
				if tab.bFightState then
					FireUIEvent('MY_TM_NPC_FIGHT', npc.dwTemplateID, false, GetTime() - (tab.nSec or GetTime()))
				end
				if npcInfo.nCount == 0 then
					CACHE.NPC_LIST[npc.dwTemplateID] = nil
					FireUIEvent('MY_TM_NPC_ALL_LEAVE_SCENE', npc.dwTemplateID)
				end
			end
		end
	end
	if data then
		local cfg, nClass, nCount
		if data.tKungFu and not D.CheckKungFu(data.tKungFu) then -- 自身身法需求检查
			return
		end
		local szSender = nil
		local szReceiver = X.GetObjectName(npc)
		if bEnter then
			cfg, nClass = data[MY_TM_TYPE.NPC_ENTER], MY_TM_TYPE.NPC_ENTER
			nCount = CACHE.NPC_LIST[npc.dwTemplateID].nCount
		else
			cfg, nClass = data[MY_TM_TYPE.NPC_LEAVE], MY_TM_TYPE.NPC_LEAVE
		end
		if nClass == MY_TM_TYPE.NPC_LEAVE then
			if data.bAllLeave and CACHE.NPC_LIST[npc.dwTemplateID] then
				return
			end
		else
			-- 场地上的NPC数量没达到预期数量
			if data.nCount and nCount < data.nCount then
				return
			end
			if cfg then
				if cfg.tMark then
					D.SetTeamMark('NPC', cfg.tMark, npc.dwID, npc.dwTemplateID)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					local szNote, szName = nil, FilterCustomText(data.szName, szSender, szReceiver)
					if not X.IsRestricted('MY_TeamMon.Note') then
						szNote = FilterCustomText(data.szNote, szSender, szReceiver) or szName
					end
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', npc.dwID, 'NPC', 'MY_TM_NPC_' .. npc.dwID, {
						szText = szNote,
						col = data.col,
					})
					FireUIEvent('MY_TM_SA_CREATE', 'NPC', npc.dwID, { text = szNote, col = data.col, szName = szName })
				end
			end
			if nTime - CACHE.NPC_LIST[npc.dwTemplateID].nTime < 500 then -- 0.5秒内进入相同的NPC直接忽略
				return -- D.Log('IGNORE NPC ENTER SCENE ID:' .. npc.dwTemplateID .. ' TIME:' .. nTime .. ' TIME2:' .. CACHE.NPC_LIST[npc.dwTemplateID].nTime)
			else
				CACHE.NPC_LIST[npc.dwTemplateID].nTime = nTime
			end
		end
		D.CountdownEvent(data, nClass, szSender, szReceiver)
		if cfg then
			local szName = szReceiver
			if data.szName then
				szName = FilterCustomText(data.szName, szSender, szReceiver)
			end
			local aXml, aText = {}, {}
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if nClass == MY_TM_TYPE.NPC_ENTER then
				ConstructSpeech(aText, aXml, _L['Appear'], 44, 255, 255, 255)
				if nCount > 1 then
					ConstructSpeech(aText, aXml, ' x' .. nCount, 44, 255, 255, 0)
				end
				if data.szNote and not X.IsRestricted('MY_TeamMon.Note') then
					ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote, szSender, szReceiver), 44, 255, 255, 255)
				end
			else
				ConstructSpeech(aText, aXml, _L['Disappear'], 44, 255, 255, 255)
			end
			local szXml, szText = table.concat(aXml), table.concat(aText)
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { GetHeadTextForceFontColor(npc.dwID, MY_TM_CORE_PLAYERID) })
			end

			if O.bPushTeamChannel and cfg.bTeamChannel then
				D.Talk('RAID', szText)
			end
			if O.bPushWhisperChannel and cfg.bWhisperChannel then
				D.Talk('RAID_WHISPER', szText)
			end

			if nClass == MY_TM_TYPE.NPC_ENTER then
				if not X.IsRestricted('MY_TeamMon.AutoSelect') and cfg.bSelect then
					SetTarget(TARGET.NPC, npc.dwID)
				end
				if O.bPushFullScreen and cfg.bFullScreen then
					FireUIEvent('MY_TM_FS_CREATE', 'NPC', { nTime  = 3, col = data.col, bFlash = true })
				end
			end
		end
	end
end

-- DOODAD事件
function D.OnDoodadEvent(doodad, bEnter)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local data = D.GetData('DOODAD', doodad.dwTemplateID)
	local nTime = GetTime()
	if bEnter then
		if not CACHE.DOODAD_LIST[doodad.dwTemplateID] then
			CACHE.DOODAD_LIST[doodad.dwTemplateID] = {
				tList       = {},
				nTime       = -1,
				nCount      = 0,
			}
		end
		CACHE.DOODAD_LIST[doodad.dwTemplateID].tList[doodad.dwID] = {}
		CACHE.DOODAD_LIST[doodad.dwTemplateID].nCount = CACHE.DOODAD_LIST[doodad.dwTemplateID].nCount + 1
		if doodad.nKind ~= DOODAD_KIND.ORNAMENT or not X.IsRestricted('MY_TeamMon.HiddenDoodad') then
			local tWeak, tTemp = CACHE.TEMP.DOODAD, D.TEMP.DOODAD
			if not tWeak[doodad.dwTemplateID] then
				local t = {
					dwMapID      = X.GetMapID(),
					dwID         = doodad.dwTemplateID,
					nCurrentTime = GetCurrentTime()
				}
				tWeak[doodad.dwTemplateID] = t
				tTemp[#tTemp + 1] = tWeak[doodad.dwTemplateID]
				FireUIEvent('MY_TMUI_TEMP_UPDATE', 'DOODAD', t)
			end
		end
		CACHE.INTERVAL.DOODAD[doodad.dwTemplateID] = CACHE.INTERVAL.DOODAD[doodad.dwTemplateID] or {}
		if #CACHE.INTERVAL.DOODAD[doodad.dwTemplateID] > 0 then
			if nTime - CACHE.INTERVAL.DOODAD[doodad.dwTemplateID][#CACHE.INTERVAL.DOODAD[doodad.dwTemplateID]] > 500 then
				CACHE.INTERVAL.DOODAD[doodad.dwTemplateID][#CACHE.INTERVAL.DOODAD[doodad.dwTemplateID] + 1] = nTime
			end
		else
			CACHE.INTERVAL.DOODAD[doodad.dwTemplateID][#CACHE.INTERVAL.DOODAD[doodad.dwTemplateID] + 1] = nTime
		end
	else
		local doodadInfo = CACHE.DOODAD_LIST[doodad.dwTemplateID]
		if doodadInfo then
			local tab = doodadInfo.tList[doodad.dwID]
			if tab then
				doodadInfo.tList[doodad.dwID] = nil
				doodadInfo.nCount = doodadInfo.nCount - 1
				if doodadInfo.nCount == 0 then
					CACHE.DOODAD_LIST[doodad.dwTemplateID] = nil
					FireUIEvent('MY_TM_DOODAD_ALL_LEAVE_SCENE', doodad.dwTemplateID)
				end
			end
		end
	end
	if data then
		local cfg, nClass, nCount
		if data.tKungFu and not D.CheckKungFu(data.tKungFu) then -- 自身身法需求检查
			return
		end
		local szSender = nil
		local szReceiver = X.GetObjectName(doodad)
		if bEnter then
			cfg, nClass = data[MY_TM_TYPE.DOODAD_ENTER], MY_TM_TYPE.DOODAD_ENTER
			nCount = CACHE.DOODAD_LIST[doodad.dwTemplateID].nCount
		else
			cfg, nClass = data[MY_TM_TYPE.DOODAD_LEAVE], MY_TM_TYPE.DOODAD_LEAVE
		end
		if nClass == MY_TM_TYPE.DOODAD_LEAVE then
			if data.bAllLeave and CACHE.DOODAD_LIST[doodad.dwTemplateID] then
				return
			end
		else
			-- 场地上的DOODAD数量没达到预期数量
			if data.nCount and nCount < data.nCount then
				return
			end
			if cfg then
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					local szNote, szName = nil, FilterCustomText(data.szName, szSender, szReceiver)
					if not X.IsRestricted('MY_TeamMon.Note') then
						szNote = FilterCustomText(data.szNote, szSender, szReceiver) or szName
					end
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', doodad.dwID, 'DOODAD', 'MY_TM_DOODAD_' .. doodad.dwID, {
						szText = szNote,
						col = data.col,
					})
					FireUIEvent('MY_TM_SA_CREATE', 'DOODAD', doodad.dwID, { text = szNote, col = data.col, szName = szName })
				end
			end
			if nTime - CACHE.DOODAD_LIST[doodad.dwTemplateID].nTime < 500 then
				return
			else
				CACHE.DOODAD_LIST[doodad.dwTemplateID].nTime = nTime
			end
		end
		D.CountdownEvent(data, nClass, szSender, szReceiver)
		if cfg then
			local szName = szReceiver
			if data.szName then
				szName = FilterCustomText(data.szName, szSender, szReceiver)
			end
			local aXml, aText = {}, {}
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if nClass == MY_TM_TYPE.DOODAD_ENTER then
				ConstructSpeech(aText, aXml, _L['Appear'], 44, 255, 255, 255)
				if nCount > 1 then
					ConstructSpeech(aText, aXml, ' x' .. nCount, 44, 255, 255, 0)
				end
				if data.szNote and not X.IsRestricted('MY_TeamMon.Note') then
					ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote, szSender, szReceiver), 44, 255, 255, 255)
				end
			else
				ConstructSpeech(aText, aXml, _L['Disappear'], 44, 255, 255, 255)
			end
			local szXml, szText = table.concat(aXml), table.concat(aText)
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { 255, 255, 0 })
			end

			if O.bPushTeamChannel and cfg.bTeamChannel then
				D.Talk('RAID', szText)
			end
			if O.bPushWhisperChannel and cfg.bWhisperChannel then
				D.Talk('RAID_WHISPER', szText)
			end

			if nClass == MY_TM_TYPE.DOODAD_ENTER then
				if O.bPushFullScreen and cfg.bFullScreen then
					FireUIEvent('MY_TM_FS_CREATE', 'DOODAD', { nTime  = 3, col = data.col, bFlash = true })
				end
			end
		end
	end
end

function D.OnDoodadAllLeave(dwTemplateID)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local data = D.GetData('DOODAD', dwTemplateID)
	if data then
		local szSender = nil
		local szReceiver = X.GetTemplateName(TARGET.DOODAD, dwTemplateID)
		D.CountdownEvent(data, MY_TM_TYPE.DOODAD_ALLLEAVE, szSender, szReceiver)
	end
end

-- 系统和NPC喊话处理
-- OutputMessage('MSG_SYS', 1..'\n')
function D.OnCallMessage(szEvent, szContent, dwNpcID, szNpcName)
	if MY_TM_SHIELDED_MAP then
		return
	end
	if dwNpcID and not IsPlayer(dwNpcID) then
		local npc = GetNpc(dwNpcID)
		if npc and X.IsShieldedNpc(npc.dwTemplateID, 'TALK') then
			return
		end
	end
	-- 近期记录
	szContent = tostring(szContent)
	local me = GetClientPlayer()
	local key = (szNpcName or 'sys') .. '::' .. szContent
	local tWeak, tTemp = CACHE.TEMP[szEvent], D.TEMP[szEvent]
	if not tWeak[key] then
		local t = {
			dwMapID      = me.GetMapID(),
			szContent    = szContent,
			szTarget     = szNpcName,
			nCurrentTime = GetCurrentTime()
		}
		tWeak[key] = t
		tTemp[#tTemp + 1] = tWeak[key]
		FireUIEvent('MY_TMUI_TEMP_UPDATE', szEvent, t)
	end
	local cache, data = CACHE.MAP[szEvent], nil
	if cache.HIT[szContent] then
		data = cache.HIT[szContent][szNpcName or 'sys']
			or cache.HIT[szContent]['%']
	end
	local szSender, dwReceiverID, szReceiver, aBackreferences = szNpcName or _L['JX3']
	if not data then -- 涉及匹配的规则不会被缓存，不适用 wstring ，性能考虑为前提
		local bInParty = me.IsInParty()
		local team     = GetClientTeam()
		for _, v in ipairs(cache.OTHER) do -- 按照数据优先级顺序（地图＞地图组＞通用），同级按照下标先后顺序，只取第一个匹配结果
			local content = v.szContent
			if v.szContent:find('{$me}', nil, true) then
				dwReceiverID = me.dwID
				szReceiver = me.szName
				content = v.szContent:gsub('{$me}', me.szName) -- 转换me是自己名字
			else
				dwReceiverID, szReceiver = nil
			end
			if bInParty and content:find('{$team}', nil, true) then
				local c = content
				for _, vv in ipairs(team.GetTeamMemberList()) do
					if string.find(szContent, c:gsub('{$team}', team.GetClientTeamMemberName(vv)), nil, true) and (v.szTarget == szNpcName or v.szTarget == '%') then -- hit
						data = v
						dwReceiverID = vv
						szReceiver = team.GetClientTeamMemberName(vv)
						break
					end
				end
				if dwReceiverID and szReceiver then
					break
				end
			elseif v.szTarget == szNpcName or v.szTarget == '%' then
				if v.bReg then
					local res = {string.find(szContent, content)}
					if res[1] then
						table.remove(res, 1)
						table.remove(res, 1)
						data = v
						aBackreferences = res
						break
					end
				elseif string.find(szContent, content, nil, true) then
					data = v
					break
				end
			end
		end
	end
	if data then
		local nClass = szEvent == 'TALK'
			and MY_TM_TYPE.TALK_MONITOR
			or MY_TM_TYPE.CHAT_MONITOR
		if not dwReceiverID and not szReceiver and data.szContent:find('{$me}', nil, true) then
			dwReceiverID = me.dwID
			szReceiver = me.szName
		end
		D.CountdownEvent(data, nClass, szSender, szReceiver, aBackreferences)
		local cfg = data[nClass]
		if cfg then
			local aXml, aText, aTalkXml, aTalkText = {}, {}, {}, {}
			if szReceiver then
				ConstructSpeech(aTalkText, aTalkXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aTalkText, aTalkXml, szSender, 44, 255, 255, 0)
				ConstructSpeech(aTalkText, aTalkXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
				ConstructSpeech(aTalkText, aTalkXml, _L['is calling'], 44, 255, 255, 255)
				ConstructSpeech(aTalkText, aTalkXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aTalkText, aTalkXml, szReceiver == me.szName and g_tStrings.STR_YOU or szReceiver, 44, 255, 255, 0)
				ConstructSpeech(aTalkText, aTalkXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
				ConstructSpeech(aTalkText, aTalkXml, _L['\'s name.'], 44, 255, 255, 255)
			else
				ConstructSpeech(aTalkText, aTalkXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aTalkText, aTalkXml, szSender, 44, 255, 255, 0)
				ConstructSpeech(aTalkText, aTalkXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
				ConstructSpeech(aTalkText, aTalkXml, g_tStrings.HEADER_SHOW_SAY, 44, 255, 255, 0)
				ConstructSpeech(aTalkText, aTalkXml, szContent, 44, 255, 255, 0)
			end
			if data.szNote then
				ConstructSpeech(aText, aXml, FilterCustomText(data.szNote, szSender, szReceiver, aBackreferences) or szContent, 44, 255, 255, 255)
			end
			local szXml, szText, szTalkXml, szTalkText = table.concat(aXml), table.concat(aText), table.concat(aTalkXml), table.concat(aTalkText)
			if X.IsEmpty(szXml) then
				szXml = szTalkXml
			end
			if X.IsEmpty(szText) then
				szText = szTalkText
			end
			if dwReceiverID then -- 点了人名
				if O.bPushWhisperChannel and cfg.bWhisperChannel then
					D.Talk('WHISPER', szTalkText, szReceiver)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', dwReceiverID, 'TIME', 'MY_TM_TIME_' .. dwReceiverID, {
						nTime = GetTime() + 5000,
						szText = _L('%s call name', szNpcName or g_tStrings.SYSTEM),
						col = data.col,
						bHideProgress = true,
					})
					FireUIEvent('MY_TM_SA_CREATE', 'TIME', dwReceiverID, { text = _L('%s call name', szNpcName or g_tStrings.SYSTEM)})
				end
				if not X.IsRestricted('MY_TeamMon.AutoSelect') and cfg.bSelect then
					SetTarget(TARGET.PLAYER, dwReceiverID)
				end
			else -- 没点名
				if O.bPushWhisperChannel and cfg.bWhisperChannel then
					D.Talk('RAID_WHISPER', szTalkText)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', dwNpcID or me.dwID, 'TIME', 'MY_TM_TIME_' .. (dwNpcID or me.dwID), {
						nTime = GetTime() + 5000,
						szText = szText,
						col = data.col,
						bHideProgress = true,
					})
					FireUIEvent('MY_TM_SA_CREATE', 'TIME', dwNpcID or me.dwID, { text = szText })
				end
			end
			-- 中央报警
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', #aXml > 0 and szXml or szText, 3, #aXml > 0)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { 255, 128, 0 })
			end
			if O.bPushFullScreen and cfg.bFullScreen then
				if not dwReceiverID or dwReceiverID == me.dwID then
					FireUIEvent('MY_TM_FS_CREATE', szEvent, { nTime  = 3, col = data.col or { 0, 255, 0 }, bFlash = true })
				end
			end
			if O.bPushTeamChannel and cfg.bTeamChannel then
				if szReceiver and not data.szNote then
					D.Talk('RAID', szTalkText, szReceiver)
				else
					D.Talk('RAID', szTalkText)
				end
			end
		end
	end
end

-- NPC死亡事件 触发倒计时
function D.OnDeath(dwCharacterID, dwKiller)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local npc = GetNpc(dwCharacterID)
	if npc then
		local data = D.GetData('NPC', npc.dwTemplateID)
		if data then
			local dwTemplateID = npc.dwTemplateID
			local szSender = X.GetObjectName(X.GetObject(dwKiller), 'auto')
			local szReceiver = X.GetObjectName(npc)
			D.CountdownEvent(data, MY_TM_TYPE.NPC_DEATH, szSender, szReceiver)
			local bAllDeath = true
			if CACHE.NPC_LIST[dwTemplateID] then
				for k, v in pairs(CACHE.NPC_LIST[dwTemplateID].tList) do
					local npc = GetNpc(k)
					if npc and npc.nMoveState ~= MOVE_STATE.ON_DEATH then
						bAllDeath = false
						break
					end
				end
			end
			if bAllDeath then
				D.CountdownEvent(data, MY_TM_TYPE.NPC_ALLDEATH, szSender, szReceiver)
			end
		end
	end
end

-- NPC进出战斗事件 触发倒计时
function D.OnNpcFight(dwTemplateID, bFight)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local data = D.GetData('NPC', dwTemplateID)
	if data then
		local szSender = nil
		local szReceiver = X.GetTemplateName(TARGET.NPC, dwTemplateID)
		if bFight then
			D.CountdownEvent(data, MY_TM_TYPE.NPC_FIGHT, szSender, szReceiver)
		elseif data.tCountdown then -- 脱离的时候清空下
			for k, v in ipairs(data.tCountdown) do
				if v.nClass == MY_TM_TYPE.NPC_FIGHT and not v.bFightHold then
					local nClass = v.key and MY_TM_TYPE.COMMON or v.nClass
					local szKey = v.key or (k .. '.' .. (data.dwID or 0) .. '.' .. (data.nLevel or 0) .. '.' .. (data.nIndex or 0))
					FireUIEvent('MY_TM_ST_DEL', nClass, szKey) -- try kill
				end
			end
		end
	end
end

-- 不该放在倒计时中 需要重构
function D.OnNpcInfoChange(szEvent, dwTemplateID, nPer, bIncrease)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local data = D.GetData('NPC', dwTemplateID)
	if data and data.tCountdown then
		local dwType = szEvent == 'MY_TM_NPC_LIFE_CHANGE' and MY_TM_TYPE.NPC_LIFE or MY_TM_TYPE.NPC_MANA
		local szSender = nil
		local szReceiver = X.GetTemplateName(TARGET.NPC, dwTemplateID)
		for k, v in ipairs(data.tCountdown) do
			if v.nClass == dwType then
				local aHPCountdown = ParseHPCountdown(v.nTime)
				for kk, tHpCd in ipairs(aHPCountdown) do
					if tHpCd.nValue == nPer
					and (tHpCd.szOperator == '*' or (bIncrease and tHpCd.szOperator == '+') or (not bIncrease and tHpCd.szOperator == '-')) then -- hit
						local szName = FilterCustomText(data.szName, szSender, szReceiver) or szReceiver
						local aXml, aText = {}, {}
						ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
						ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
						ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
						ConstructSpeech(aText, aXml, dwType == MY_TM_TYPE.NPC_LIFE and _L['\'s life remaining to '] or _L['\'s mana reaches '], 44, 255, 255, 255)
						ConstructSpeech(aText, aXml, ' ' .. tHpCd.nValue .. '%', 44, 255, 255, 0)
						ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(tHpCd.szContent, szSender, szReceiver), 44, 255, 255, 255)
						local szXml, szText = table.concat(aXml), table.concat(aText)
						if O.bPushCenterAlarm then
							FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
						end
						if O.bPushBigFontAlarm then
							FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { 255, 128, 0 })
						end
						if O.bPushTeamChannel and v.bTeamChannel then
							D.Talk('RAID', szText)
						end
						if tHpCd.nTime then
							local nType, szKey = v.nClass, v.key
							if szKey then
								nType = MY_TM_TYPE.COMMON
							else
								szKey = k .. '.' .. dwTemplateID .. '.' .. kk
							end
							local tParam = {
								nFrame = v.nFrame,
								nTime  = tHpCd.nTime,
								szName = FilterCustomText(tHpCd.szContent, szSender, szReceiver),
								nIcon  = v.nIcon,
								bTalk  = v.bTeamChannel,
								bHold  = v.bHold,
							}
							D.FireCountdownEvent(nType, szKey, tParam, szSender, szReceiver)
						end
						break
					end
				end
			end
		end
	end
end

-- NPC 全部消失的倒计时处理
function D.OnNpcAllLeave(dwTemplateID)
	if MY_TM_SHIELDED_MAP then
		return
	end
	local data = D.GetData('NPC', dwTemplateID)
	local szSender = nil
	local szReceiver = X.GetTemplateName(TARGET.NPC, dwTemplateID)
	if data then
		D.CountdownEvent(data, MY_TM_TYPE.NPC_ALLLEAVE, szSender, szReceiver)
	end
end

local MAP_ID, PREV_MAP_ID
function D.FireCrossMapEvent(szWhen)
	local dwMapID = X.GetMapID(true)
	if szWhen == 'before' then
		if PREV_MAP_ID and PREV_MAP_ID ~= dwMapID then
			local map = PREV_MAP_ID and X.GetMapInfo(PREV_MAP_ID)
			if map then
				local szEvent = 'CHAT'
				local szContent = _L('Leave map %s.', map.szName)
				D.OnCallMessage(szEvent, szContent)
			end
			PREV_MAP_ID = dwMapID
		end
	elseif szWhen == 'after' then
		if MAP_ID ~= dwMapID then
			local map = X.GetMapInfo(dwMapID)
			if map then
				local szEvent = 'CHAT'
				local szContent = _L('Enter map %s.', map.szName)
				D.OnCallMessage(szEvent, szContent)
			end
			MAP_ID = dwMapID
		end
	end
end

-- RegisterMsgMonitor
function D.RegisterMessage(bEnable)
	if bEnable then
		X.RegisterMsgMonitor('MSG_SYS', 'MY_TeamMon_MON', function(szChannel, szMsg, nFont, bRich)
			if MY_TM_SHIELDED_MAP then
				return
			end
			if not GetClientPlayer() then
				return
			end
			if bRich then
				szMsg = MY_GetPureText(szMsg)
			end
			-- local res, err = pcall(D.OnCallMessage, 'CHAT', szMsg:gsub('\r', ''))
			-- if not res then
			-- 	return X.Debug(err, X.DEBUG_LEVEL.WARNING)
			-- end
			szMsg = szMsg:gsub('\r', '')
			D.OnCallMessage('CHAT', szMsg)
		end)
	else
		X.RegisterMsgMonitor('MSG_SYS', 'MY_TeamMon_MON', false)
	end
end

-- UI操作
function D.GetFrame()
	return Station.Lookup('Normal/MY_TeamMon')
end

function D.Open()
	local frame = D.GetFrame()
	if frame then
		for k, v in ipairs(MYTM_EVENTS) do
			frame:UnRegisterEvent(v)
			frame:RegisterEvent(v)
		end
		D.RegisterMessage(true)
	end
end

function D.Close()
	local frame = D.GetFrame()
	if frame then
		for k, v in ipairs(MYTM_EVENTS) do
			frame:UnRegisterEvent(v)  -- kill all event
		end
		D.RegisterMessage(false)
		FireUIEvent('MY_TM_ST_CLEAR')
		CACHE.NPC_LIST = {}
		CACHE.SKILL_LIST = {}
		collectgarbage('collect')
	end
end

function D.Enable(bEnable, bFireUIEvent)
	if D.bReady and bEnable then
		local res, err = pcall(D.Open)
		if not res then
			return X.Debug(err, X.DEBUG_LEVEL.WARNING)
		end
		if bFireUIEvent then
			FireUIEvent('MY_TM_LOADING_END')
			for _, v in pairs(X.GetNearNpcID()) do
				FireUIEvent('MY_TM_NPC_ENTER_SCENE', v)
			end
		end
	else
		D.Close()
	end
end

function D.Init()
	local K = string.char(75, 69)
	local k = string.char(80, 87)
	if X.IsString(D[k]) then
		D[k] = X[K](D[k] .. string.char(77, 89))
	end
	D.LoadUserData()
	Wnd.OpenWindow(MY_TM_INIFILE, 'MY_TeamMon')
end

-- 保存用户监控数据、配置
function D.SaveUserData()
	X.SaveLUAData(
		GetUserDataPath(),
		{
			data = D.FILE,
			config = D.CONFIG,
		})
end

-- 加载用户监控数据、配置
function D.LoadUserData()
	local data = X.LoadLUAData(GetUserDataPath())
	if X.IsTable(data) then
		for k, v in pairs(D.FILE) do
			D.FILE[k] = data.data[k] or {}
		end
		D.CONFIG = data.config or {}
		FireUIEvent('MY_TM_DATA_RELOAD')
	else
		D.ImportDataFromFile(
			X.ENVIRONMENT.GAME_EDITION ..  '.jx3dat',
			MY_TM_TYPE_LIST,
			'REPLACE',
			function()
				D.Log('load custom data finish!')
			end)
	end
end

-- 获取用户配置项
function D.GetUserConfig(szKey)
	return D.CONFIG[szKey]
end

-- 设置用户配置项
function D.SetUserConfig(szKey, oVal)
	D.CONFIG[szKey] = oVal
end

-- 从文件导入数据
function D.ImportDataFromFile(szFileName, aType, szMode, fnAction)
	local szFullPath = szFileName:sub(2, 2) == ':'
		and szFileName
		or X.GetAbsolutePath(MY_TM_REMOTE_DATA_ROOT .. szFileName)
	local szFilePath = X.GetRelativePath(szFullPath, {'', X.PATH_TYPE.NORMAL}) or szFullPath
	if not IsFileExist(szFilePath) then
		X.SafeCall(fnAction, false, 'File does not exist.')
		return
	end
	local data = X.LoadLUAData(szFilePath, { passphrase = D.PW })
		or X.LoadLUAData(szFilePath, { passphrase = '89g45ynbtldnsryu98rbny9ps7468hb6npyusiryuxoldg7lbn894bn678b496746' })
		or X.LoadLUAData(szFilePath, { passphrase = false })
	if not data then
		X.SafeCall(fnAction, false, 'Can not read data file.')
		return
	end
	if not aType then
		aType = X.Clone(MY_TM_TYPE_LIST)
	end
	if szMode == 'REPLACE' then
		for _, k in ipairs(aType) do
			D.FILE[k] = data[k] or {}
		end
	elseif szMode == 'MERGE_OVERWRITE' or szMode == 'MERGE_SKIP' then
		local fnMergeData = function(tab_data)
			for _, szType in ipairs(aType) do
				if tab_data[szType] then
					for k, v in pairs(tab_data[szType]) do
						for kk, vv in ipairs(v) do
							if not D.CheckSameData(szType, k, vv.dwID or vv.szContent, vv.nLevel or vv.szTarget) then
								D.FILE[szType][k] = D.FILE[szType][k] or {}
								table.insert(D.FILE[szType][k], vv)
							end
						end
					end
				end
			end
		end
		if szMode == 'MERGE_SKIP' then -- 源文件优先
			fnMergeData(data)
		elseif szMode == 'MERGE_OVERWRITE' then -- 新文件优先
			-- 其实就是交换下顺序
			local tab_data = clone(D.FILE)
			for _, k in ipairs(aType) do
				D.FILE[k] = data[k] or {}
			end
			fnMergeData(tab_data)
		end
	end
	FireUIEvent('MY_TM_CREATE_CACHE')
	FireUIEvent('MY_TM_DATA_RELOAD')
	FireUIEvent('MY_TMUI_DATA_RELOAD')
	-- szFilePath, aType, szMode, tMeta
	X.SafeCall(fnAction, true, szFullPath:gsub('\\', '/'), aType, szMode, X.Clone(data.__meta))
end

-- 导出数据到文件
function D.ExportDataToFile(szFileName, aType, szFormat, szAuthor, fnAction)
	local data = {}
	for _, k in ipairs(aType) do
		data[k] = D.FILE[k]
	end
	-- HM.20170504: add meta data
	data['__meta'] = {
		szEdition = X.ENVIRONMENT.GAME_EDITION,
		szAuthor = not X.IsEmpty(szAuthor)
			and szAuthor
			or GetUserRoleName(),
		szServer = select(4, GetUserServer()),
		nTimeStamp = GetCurrentTime(),
	}
	local szPath = MY_TM_REMOTE_DATA_ROOT .. szFileName
	if szFormat == 'JSON' or szFormat == 'JSON_FORMATED' then
		if szFormat ~= 'JSON' then
			szPath = szPath .. '.' .. szFormat:lower():sub(6)
		end
		szPath = szPath .. '.json'
		SaveDataToFile(X.EncodeJSON(data, szFormat == 'JSON_FORMATED'), szPath)
	else
		if szFormat ~= 'LUA' then
			szPath = szPath .. '.' .. szFormat:lower():sub(5)
		end
		szPath = szPath .. '.jx3dat'
		local option = {
			passphrase = szFormat == 'LUA_ENCRYPTED'
				and D.PW
				or false,
			crc = szFormat == 'LUA_ENCRYPTED',
			compress = szFormat == 'LUA_ENCRYPTED',
			indent = szFormat == 'LUA_FORMATED' and '\t' or nil,
		}
		X.SaveLUAData(szPath, data, option)
	end
	X.SafeCall(fnAction, X.GetAbsolutePath(szPath))
end

-- 获取整个表
function D.GetTable(szType, bTemp)
	if bTemp then
		return D.TEMP[szType]
	else
		return D.FILE[szType]
	end
end

-- 迭代数据表子序列
function D.IterTable(data, dwMapID, bIterItem)
	local res = {}
	if data then
		if dwMapID == 0 then
			dwMapID = X.GetMapID(true)
		end
		if data[MY_TM_SPECIAL_MAP.COMMON] then
			table.insert(res, data[MY_TM_SPECIAL_MAP.COMMON])
		end
		if X.IsDungeonMap(dwMapID) then
			table.insert(res, data[MY_TM_SPECIAL_MAP.DUNGEON])
		end
		if X.IsDungeonMap(dwMapID, true) then
			table.insert(res, data[MY_TM_SPECIAL_MAP.RAID_DUNGEON])
		end
		if X.IsDungeonMap(dwMapID, false) then
			table.insert(res, data[MY_TM_SPECIAL_MAP.TEAM_DUNGEON])
		end
		if X.IsCityMap(dwMapID) then
			table.insert(res, data[MY_TM_SPECIAL_MAP.CITY])
		end
		if X.IsVillageMap(dwMapID) then
			table.insert(res, data[MY_TM_SPECIAL_MAP.VILLAGE])
		end
		if X.IsStarveMap(dwMapID) then
			table.insert(res, data[MY_TM_SPECIAL_MAP.STARVE])
		end
		if data[dwMapID] then
			table.insert(res, data[dwMapID])
		end
	end
	if bIterItem then
		return X.sipairs_r(unpack(res))
	end
	return X.ipairs_r(res)
end

function D.GetMapName(dwMapID)
	if dwMapID == _L['All data'] then
		return dwMapID
	end
	local map = D.GetMapInfo(dwMapID)
	if map then
		return map.szName
	end
	return '#' .. dwMapID
end

function D.GetMapInfo(id)
	return MY_TM_SPECIAL_MAP_INFO[id] or X.GetMapInfo(id)
end

local function GetData(tab, szType, dwID, nLevel)
	-- D.Log('LOOKUP TYPE:' .. szType .. ' ID:' .. dwID .. ' LEVEL:' .. nLevel)
	if nLevel then
		for k, v in ipairs(tab) do
			if v.dwID == dwID and (not v.bCheckLevel or v.nLevel == nLevel) then
				CACHE.MAP[szType][dwID][nLevel] = k
				return v
			end
		end
	else
		for k, v in ipairs(tab) do
			if v.dwID == dwID then
				CACHE.MAP[szType][dwID] = k
				return v
			end
		end
	end
end

-- 获取监控数据 注意 不是获取文件内的 如果想找文件内的 请使用 GetTable
function D.GetData(szType, dwID, nLevel)
	local cache = CACHE.MAP[szType][dwID]
	if cache then
		local tab = D.DATA[szType]
		if nLevel then
			if cache[nLevel] then
				local data = tab[cache[nLevel]]
				if data and data.dwID == dwID and (not data.bCheckLevel or data.nLevel == nLevel) then
					-- D.Log('HIT TYPE:' .. szType .. ' ID:' .. dwID .. ' LEVEL:' .. nLevel)
					return data
				else
					-- D.Log('RELOOKUP TYPE:' .. szType .. ' ID:' .. dwID .. ' LEVEL:' .. nLevel)
					return GetData(tab, szType, dwID, nLevel)
				end
			else
				for k, v in pairs(cache) do
					local data = tab[cache[k]]
					if data and data.dwID == dwID and (not data.bCheckLevel or data.nLevel == nLevel) then
						return data
					end
				end
				return GetData(tab, szType, dwID, nLevel)
			end
		else
			local data = tab[cache]
			if data and data.dwID == dwID then
				-- D.Log('HIT TYPE:' .. szType .. ' ID:' .. dwID .. ' LEVEL:0')
				return data
			else
				-- D.Log('RELOOKUP TYPE:' .. szType .. ' ID:' .. dwID .. ' LEVEL:0')
				return GetData(tab, szType, dwID)
			end
		end
	-- else
		-- D.Log('IGNORE TYPE:' .. szType .. ' ID:' .. dwID .. ' LEVEL:' .. (nLevel or 0))
	end
end

-- 删除 移动 添加 清空
function D.RemoveData(szType, dwMapID, nIndex)
	if nIndex then
		if D.FILE[szType][dwMapID] and D.FILE[szType][dwMapID][nIndex] then
			if dwMapID == MY_TM_SPECIAL_MAP.RECYCLE_BIN then
				table.remove(D.FILE[szType][dwMapID], nIndex)
				if #D.FILE[szType][dwMapID] == 0 then
					D.FILE[szType][dwMapID] = nil
				end
				FireUIEvent('MY_TM_CREATE_CACHE')
				FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
				FireUIEvent('MY_TMUI_DATA_RELOAD')
			else
				D.MoveData(szType, dwMapID, nIndex, MY_TM_SPECIAL_MAP.RECYCLE_BIN)
			end
		end
	elseif dwMapID then
		if D.FILE[szType][dwMapID] then
			D.FILE[szType][dwMapID] = nil
			FireUIEvent('MY_TM_CREATE_CACHE')
			FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
			FireUIEvent('MY_TMUI_DATA_RELOAD')
		end
	else
		if D.FILE[szType] then
			D.FILE[szType] = {}
			FireUIEvent('MY_TM_CREATE_CACHE')
			FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
			FireUIEvent('MY_TMUI_DATA_RELOAD')
		end
	end
	FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
end

function D.CheckSameData(szType, dwMapID, dwID, nLevel)
	if D.FILE[szType][dwMapID] then
		if dwMapID ~= MY_TM_SPECIAL_MAP.RECYCLE_BIN then
			for k, v in ipairs(D.FILE[szType][dwMapID]) do
				if type(dwID) == 'string' then
					if dwID == v.szContent and nLevel == v.szTarget then
						return k, v
					end
				else
					if dwID == v.dwID and (not v.bCheckLevel or nLevel == v.nLevel) then
						return k, v
					end
				end
			end
		end
	end
end

function D.MoveData(szType, dwMapID, nIndex, dwTargetMapID, bCopy)
	if dwMapID == dwTargetMapID then
		return
	end
	if D.FILE[szType][dwMapID] and D.FILE[szType][dwMapID][nIndex] then
		local data = D.FILE[szType][dwMapID][nIndex]
		if D.CheckSameData(szType, dwTargetMapID, data.dwID or data.szContent, data.nLevel or data.szTarget) then
			return X.Alert(_L['Same data exist'])
		end
		D.FILE[szType][dwTargetMapID] = D.FILE[szType][dwTargetMapID] or {}
		table.insert(D.FILE[szType][dwTargetMapID], clone(D.FILE[szType][dwMapID][nIndex]))
		if not bCopy then
			table.remove(D.FILE[szType][dwMapID], nIndex)
			if #D.FILE[szType][dwMapID] == 0 then
				D.FILE[szType][dwMapID] = nil
			end
		end
		FireUIEvent('MY_TM_CREATE_CACHE')
		FireUIEvent('MY_TMUI_DATA_RELOAD')
		FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
	end
end
-- 交换 其实没用 满足强迫症
function D.Exchange(szType, dwMapID, nIndex1, nIndex2)
	if nIndex1 == nIndex2 then
		return
	end
	if D.FILE[szType][dwMapID] then
		local data1 = D.FILE[szType][dwMapID][nIndex1]
		local data2 = D.FILE[szType][dwMapID][nIndex2]
		if data1 and data2 then
			-- local data = table.remove(D.FILE[szType][dwMapID], nIndex1)
			-- table.insert(D.FILE[szType][dwMapID], nIndex2 + 1, data)
			D.FILE[szType][dwMapID][nIndex1] = data2
			D.FILE[szType][dwMapID][nIndex2] = data1
			FireUIEvent('MY_TM_CREATE_CACHE')
			FireUIEvent('MY_TMUI_DATA_RELOAD')
			FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
		end
	end
end

function D.AddData(szType, dwMapID, data)
	D.FILE[szType][dwMapID] = D.FILE[szType][dwMapID] or {}
	table.insert(D.FILE[szType][dwMapID], data)
	FireUIEvent('MY_TM_CREATE_CACHE')
	FireUIEvent('MY_TMUI_DATA_RELOAD')
	FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
	return D.FILE[szType][dwMapID][#D.FILE[szType][dwMapID]]
end

function D.ClearTemp(szType)
	CACHE.INTERVAL[szType] = {}
	D.TEMP[szType] = {}
	FireUIEvent('MY_TMUI_TEMP_RELOAD')
	collectgarbage('collect')
	D.Log('clear ' .. szType .. ' cache success!')
end

function D.GetIntervalData(szType, key)
	if CACHE.INTERVAL[szType] then
		return CACHE.INTERVAL[szType][key]
	end
end

function D.ConfirmShare()
	if #MY_TM_SHARE_QUEUE > 0 then
		local t = MY_TM_SHARE_QUEUE[1]
		X.Confirm(_L('%s share a %s data to you, accept?', t.szName, _L[t.szType]), function()
			local data = t.tData
			local nIndex = D.CheckSameData(t.szType, t.dwMapID, data.dwID or data.szContent, data.nLevel or data.szTarget)
			if nIndex then
				D.RemoveData(t.szType, t.dwMapID, nIndex)
			end
			D.AddData(t.szType, t.dwMapID, data)
			table.remove(MY_TM_SHARE_QUEUE, 1)
			X.DelayCall(100, D.ConfirmShare)
		end, function()
			table.remove(MY_TM_SHARE_QUEUE, 1)
			X.DelayCall(100, D.ConfirmShare)
		end)
	end
end

function D.OnShare(_, data, nChannel, dwID, szName, bIsSelf)
	if not bIsSelf then
		table.insert(MY_TM_SHARE_QUEUE, {
			szType  = data[1],
			tData   = data[3],
			szName  = szName,
			dwMapID = data[2]
		})
		D.ConfirmShare()
	end
end

X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon', function()
	if arg0 and arg0 ~= 'MY_TeamMon' then
		return
	end
	FireUIEvent('MY_TM_DATA_RELOAD')
end)
X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon.MapRestriction', function()
	if arg0 and arg0 ~= 'MY_TeamMon.MapRestriction' then
		return
	end
	D.UpdateShieldStatus()
end)
X.RegisterInit('MY_TeamMon', function()
	X.RegisterEvent('LOADING_ENDING', 'MY_TeamMon', function()
		FireUIEvent('MY_TM_DATA_RELOAD')
	end)
	D.bReady = true
	D.Init()
end)
X.RegisterFlush('MY_TeamMon', D.SaveUserData)
X.RegisterBgMsg('MY_TM_SHARE', D.OnShare)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				MY_TM_REMOTE_DATA_ROOT = MY_TM_REMOTE_DATA_ROOT,
				MY_TM_SPECIAL_MAP      = MY_TM_SPECIAL_MAP     ,
				MY_TM_TYPE             = MY_TM_TYPE            ,
				MY_TM_SCRUTINY_TYPE    = MY_TM_SCRUTINY_TYPE   ,
				FilterCustomText       = FilterCustomText      ,
				ParseCustomText        = ParseCustomText       ,
				ParseCountdown         = ParseCountdown        ,
				ParseHPCountdown       = ParseHPCountdown      ,
				'Enable',
				'GetTable',
				IterTable = function(...)
					if X.IsRestricted('MY_TeamMon') then
						return X.ipairs_r({})
					end
					return D.IterTable(...)
				end,
				'GetMapName',
				'GetMapInfo',
				'GetData',
				'GetIntervalData',
				'RemoveData',
				'MoveData',
				'CheckSameData',
				'ClearTemp',
				'AddData',
				'GetUserConfig',
				'SetUserConfig',
				'ImportDataFromFile',
				'ExportDataToFile',
				'Exchange',
				'SendChat',
				'SendBgMsg',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'bCommon',
				'bPushScreenHead',
				'bPushCenterAlarm',
				'bPushBigFontAlarm',
				'bPushTeamPanel',
				'bPushFullScreen',
				'bPushTeamChannel',
				'bPushWhisperChannel',
				'bPushBuffList',
				'bPushPartyBuffList',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'bCommon',
				'bPushScreenHead',
				'bPushCenterAlarm',
				'bPushBigFontAlarm',
				'bPushTeamPanel',
				'bPushFullScreen',
				'bPushTeamChannel',
				'bPushWhisperChannel',
				'bPushBuffList',
				'bPushPartyBuffList',
			},
			triggers = {
				bEnable = function(k, v)
					D.Enable(v, true)
				end,
			},
			root = O,
		},
	},
}
MY_TeamMon = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
