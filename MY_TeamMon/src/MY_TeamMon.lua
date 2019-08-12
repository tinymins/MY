--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控核心
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local MY_SplitString, MY_TrimString = LIB.SplitString, LIB.TrimString
local MY_GetFormatText, MY_GetPureText = LIB.GetFormatText, LIB.GetPureText
local FireUIEvent, Table_BuffIsVisible, Table_IsSkillShow = FireUIEvent, Table_BuffIsVisible, Table_IsSkillShow
local GetHeadTextForceFontColor, TargetPanel_SetOpenState = GetHeadTextForceFontColor, TargetPanel_SetOpenState

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon', _L['MY_TeamMon'], 0x2013500) then
	return
end

local MY_TM_META_ROOT = LIB.FormatPath({'userdata/TeamMon/Meta/', PATH_TYPE.GLOBAL})
local MY_TM_DATA_ROOT = LIB.FormatPath({'userdata/TeamMon/Data/', PATH_TYPE.GLOBAL})
local MY_TM_DATA_PASSPHRASE = '89g45ynbtldnsryu98rbny9ps7468hb6npyusiryuxoldg7lbn894bn678b496746'
local MY_TM_DATA_EMBEDDED_ENCRYPTED = false
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
-- 核心优化变量
local MY_TM_CORE_PLAYERID = 0
local MY_TM_CORE_NAME     = 0

local MY_TM_MAX_INTERVAL  = 300
local MY_TM_MAX_CACHE     = 3000 -- 最大的cache数量 主要是UI的问题
local MY_TM_DEL_CACHE     = 1000 -- 每次清理的数量 然后会做一次gc
local MY_TM_INIFILE       = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon.ini'

local MY_TM_SHARE_QUEUE = {}
local MY_TM_MARK_QUEUE  = {}
local MY_TM_MARK_FREE   = true -- 标记空闲
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

	'MY_TM_SET_MARK',
	'PARTY_SET_MARK',
}

local CACHE = {
	TEMP        = {}, -- 近期事件记录MAP 这里用弱表 方便处理
	MAP         = {},
	NPC_LIST    = {},
	DOODAD_LIST = {},
	SKILL_LIST  = {},
	INTERVAL    = {},
	STR         = {},
}

local D = {
	FILE  = {}, -- 文件原始数据
	TEMP  = {}, -- 近期事件记录
	DATA  = {},  -- 需要监控的数据合集
}

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

local O = {
	bEnable             = true,
	bCommon             = true,
	bPushScreenHead     = true,
	bPushCenterAlarm    = true,
	bPushBigFontAlarm   = true,
	bPushTeamPanel      = true, -- 面板buff监控
	bPushFullScreen     = true, -- 全屏泛光
	bPushTeamChannel    = false, -- 团队报警
	bPushWhisperChannel = false, -- 密聊报警
	bPushBuffList       = true,
	bPushPartyBuffList  = true,
}
RegisterCustomData('MY_TeamMon.bEnable')
RegisterCustomData('MY_TeamMon.bCommon')
RegisterCustomData('MY_TeamMon.bPushScreenHead')
RegisterCustomData('MY_TeamMon.bPushCenterAlarm')
RegisterCustomData('MY_TeamMon.bPushBigFontAlarm')
RegisterCustomData('MY_TeamMon.bPushTeamPanel')
RegisterCustomData('MY_TeamMon.bPushFullScreen')
RegisterCustomData('MY_TeamMon.bPushTeamChannel')
RegisterCustomData('MY_TeamMon.bPushWhisperChannel')
RegisterCustomData('MY_TeamMon.bPushBuffList')
RegisterCustomData('MY_TeamMon.bPushPartyBuffList')

local function GetDataPath()
	local szPath = LIB.FormatPath({'userdata/TeamMon/Config.jx3dat', O.bCommon and PATH_TYPE.GLOBAL or PATH_TYPE.ROLE})
	Log('[MY_TeamMon] Data path: ' .. szPath)
	return szPath
end

local function FilterCustomText(szText)
	if not szText then
		return
	end
	if LIB.IsShieldedVersion(2) then
		szText = wsub(szText, 1, 8)
	end
	return LIB.ReplaceSensitiveWord(szText)
end

local function ConstructSpeech(aText, aXml, szText, nFont, nR, nG, nB)
	if aXml then
		if IsString(nFont) then
			insert(aXml, nFont)
		else
			insert(aXml, MY_GetFormatText(szText, nFont, nR, nG, nB))
		end
	end
	if aText then
		insert(aText, szText)
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('MY_TM_LOADING_END')
	this:RegisterEvent('MY_TM_CREATE_CACHE')
	this:RegisterEvent('LOADING_END')
	D.Enable(O.bEnable)
	D.Log('init success!')
	LIB.BreatheCall('MY_TM_CACHE_CLEAR', 60 * 2 * 1000, function()
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
					-- 	LIB.SetTarget(TARGET.NPC, vv)
					-- 	LIB.SetTarget(dwType, dwID)
					-- end
					-- 血量变化检查
					if npc.nMaxLife > 1 then
						local nLife = floor(npc.nCurrentLife / npc.nMaxLife * 100)
						if tab.nLife ~= nLife then
							local nStart = tab.nLife or nLife
							local nStep = nLife >= nStart and 1 or -1
							if tab.nLife then
								nStart = nStart + nStep
							end
							for nLife = nStart, nLife, nStep do
								FireUIEvent('MY_TM_NPC_LIFE_CHANGE', dwTemplateID, nLife)
							end
							tab.nLife = nLife
						end
					end
					-- 蓝量变化检查
					-- if bTempTarget then
					if npc.nMaxMana > 1 then
						local nMana = floor(npc.nCurrentMana / npc.nMaxMana * 100)
						if tab.nMana ~= nMana then
							local nStart = tab.nMana or nMana
							local nStep = nMana >= nStart and 1 or -1
							if tab.nMana then
								nStart = nStart + nStep
							end
							for nMana = nStart, nMana, nStep do
								FireUIEvent('MY_TM_NPC_MANA_CHANGE', dwTemplateID, nMana)
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
	elseif szEvent == 'PARTY_SET_MARK' or szEvent == 'MY_TM_SET_MARK' then
		if #MY_TM_MARK_QUEUE >= 1 then
			local r = remove(MY_TM_MARK_QUEUE, 1)
			local res, err = pcall(r.fnAction)
			if not res then
				LIB.Debug('MY_TeamMon_Mark ERROR: ' .. err, _L['MY_TeamMon'], DEBUG_LEVEL.WARNING)
			end
		else
			MY_TM_MARK_FREE = true
		end
	elseif szEvent == 'PLAYER_SAY' then
		if not IsPlayer(arg1) then
			local szText = MY_GetPureText(arg0)
			if szText and szText ~= '' then
				D.OnCallMessage('TALK', szText, arg1, arg3 == '' and '%' or arg3)
			else
				LIB.Debug('GetPureText ERROR: ' .. arg0, _L['MY_TeamMon'], DEBUG_LEVEL.WARNING)
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
		D.OnNpcInfoChange(szEvent, arg0, arg1)
	elseif szEvent == 'LOADING_END' or szEvent == 'MY_TM_CREATE_CACHE' or szEvent == 'MY_TM_LOADING_END' then
		D.CreateData(szEvent)
	end
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
			szMsg = wgsub(szMsg, _L['['] .. szTarget .. _L[']'], ' [' .. szTarget .. '] ')
			szMsg = wgsub(szMsg, _L['['] .. g_tStrings.STR_YOU .. _L[']'], ' [' .. szTarget .. '] ')
		end
		if me.IsInParty() then
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, szMsg, szKey .. GetStringCRC(szType .. szMsg))
		end
	elseif szType == 'WHISPER' then
		if szTarget then
			szMsg = wgsub(szMsg, '[' .. szTarget .. ']', _L['['] .. g_tStrings.STR_YOU .. _L[']'])
			szMsg = wgsub(szMsg, _L['['] .. szTarget .. _L[']'], _L['['] .. g_tStrings.STR_YOU .. _L[']'])
		end
		if szTarget == me.szName then
			LIB.OutputWhisper(szMsg, _L['MY_TeamMon'])
		else
			LIB.Talk(szTarget, szMsg, szKey .. GetStringCRC(szType .. szMsg))
		end
	elseif szType == 'RAID_WHISPER' then
		if me.IsInParty() then
			local team = GetClientTeam()
			for _, v in ipairs(team.GetTeamMemberList()) do
				local szName = team.GetClientTeamMemberName(v)
				local szText = wgsub(szMsg, '[' .. szName .. ']', _L['['] .. g_tStrings.STR_YOU ..  _L[']'])
				if szName == me.szName then
					LIB.OutputWhisper(szText, _L['MY_TeamMon'])
				else
					LIB.Talk(szName, szText, szKey .. GetStringCRC(szType .. szText .. szName))
				end
			end
		end
	end
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
	local szLang  = select(3, GetVersion())
	local dwMapID = LIB.GetMapID(true)
	local me = GetClientPlayer()
	-- 用于更新 BUFF / CAST / NPC 缓存处理 不需要再获取本地对象
	MY_TM_CORE_NAME     = me.szName
	MY_TM_CORE_PLAYERID = me.dwID
	D.Log('get player info cache success!')
	-- 重建metatable 获取ALL数据的方法 主要用于UI 逻辑中毫无作用
	for kType, vTable in pairs(D.FILE)  do
		setmetatable(D.FILE[kType], { __index = function(me, index)
			if index == _L['All data'] then
				local t = {}
				for k, v in pairs(vTable) do
					if k ~= -9 then
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
	-- 判断战场使用条件
	if LIB.IsInArena() and LIB.IsShieldedVersion(2) then
		LIB.Sysmsg(_L['MY_TeamMon is blocked in arena, temporary disabled.'])
		D.Log('MAPID: ' .. dwMapID ..  ' create data Failed:' .. GetTime() - nTime  .. 'ms')
	else
		-- 重建MAP
		for _, v in ipairs({ 'BUFF', 'DEBUFF', 'CASTING', 'NPC', 'DOODAD' }) do
			if D.FILE[v][dwMapID] then -- 本地图数据
				CreateCache(v, D.FILE[v][dwMapID])
			end
			if D.FILE[v][-1] then -- 通用数据
				CreateCache(v, D.FILE[v][-1])
			end
		end
		-- 单独重建TALK数据
		do
			for _, vType in ipairs({ 'TALK', 'CHAT' }) do
				local data  = D.FILE[vType]
				local talk  = D.DATA[vType]
				CACHE.MAP[vType] = {
					HIT   = {},
					OTHER = {},
				}
				local cache = CACHE.MAP[vType]
				if data[-1] then -- 通用数据
					for k, v in ipairs(data[-1]) do
						talk[#talk + 1] = v
					end
				end
				if data[dwMapID] then -- 本地图数据
					for k, v in ipairs(data[dwMapID]) do
						talk[#talk + 1] = v
					end
				end
				for k, v in ipairs(talk) do
					if v.szContent then
						if v.szContent:find('$me') or v.szContent:find('$team') or v.bSearch or v.bReg then
							insert(cache.OTHER, v)
						else
							cache.HIT[v.szContent] = cache.HIT[v.szContent] or {}
							cache.HIT[v.szContent][v.szTarget or 'sys'] = v
						end
					else
						LIB.Sysmsg('[Warning] ' .. vType .. ' data is not szContent #' .. k .. ', please do check it!', 'MY_TeamMon', DEBUG_LEVEL.WARNING)
					end
				end
				D.Log('create ' .. vType .. ' data success!')
			end
		end
		if O.bPushTeamPanel then
			local tBuff = {}
			for k, v in ipairs(D.DATA.BUFF) do
				if v[MY_TM_TYPE.BUFF_GET] and v[MY_TM_TYPE.BUFF_GET].bTeamPanel then
					insert(tBuff, v.dwID)
				end
			end
			for k, v in ipairs(D.DATA.DEBUFF) do
				if v[MY_TM_TYPE.BUFF_GET] and v[MY_TM_TYPE.BUFF_GET].bTeamPanel then
					insert(tBuff, v.dwID)
				end
			end
			pcall(Raid_MonitorBuffs, tBuff)
		end
		D.Log('MAPID: ' .. dwMapID ..  ' create data success:' .. GetTime() - nTime  .. 'ms')
	end
	-- gc
	if szEvent ~= 'MY_TM_CREATE_CACHE' then
		CACHE.NPC_LIST   = {}
		CACHE.SKILL_LIST = {}
		CACHE.STR        = {}
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
	elseif nScrutinyType == MY_TM_SCRUTINY_TYPE.TEAM and (not LIB.IsParty(dwID) and dwID ~= MY_TM_CORE_PLAYERID) then
		return false
	elseif nScrutinyType == MY_TM_SCRUTINY_TYPE.ENEMY and not IsEnemy(MY_TM_CORE_PLAYERID, dwID) then
		return false
	elseif nScrutinyType == MY_TM_SCRUTINY_TYPE.TARGET then
		local obj = LIB.GetObject(LIB.GetTarget())
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
	if not LIB.IsMarker() then
		return
	end
	local fnAction = function()
		local team = GetClientTeam()
		local tTeamMark, tMarkList = team.GetTeamMark(), {} -- tmd 什么鬼结构。。。
		for k, v in pairs(tTeamMark) do
			tMarkList[v] = k
		end
		if szType == 'NPC' then
			for k, v in ipairs(tMark) do
				if v then
					if not tMarkList[k] or tMarkList[k] == 0 or (tMarkList[k] and tMarkList[k] ~= dwCharacterID) then
						local p = tMarkList[k] and GetNpc(tMarkList[k])
						if not p or (p and p.dwTemplateID ~= dwID) then
							return team.SetTeamMark(k, dwCharacterID)
						end
					end
				end
			end
		elseif szType == 'BUFF' or szType == 'DEBUFF' then
			for k, v in ipairs(tMark) do
				if v then
					if not tMarkList[k] or tMarkList[k] == 0 or (tMarkList[k] and tMarkList[k] ~= dwCharacterID) then
						local p
						if tMarkList[k] then
							p = IsPlayer(tMarkList[k]) and GetPlayer(tMarkList[k]) or GetNpc(tMarkList[k])
						end
						if not p or (p and not LIB.GetBuff(p, dwID)) then
							return team.SetTeamMark(k, dwCharacterID)
						end
					end
				end
			end
		elseif szType == 'CASTING' then
			for k, v in ipairs(tMark) do
				if v then
					if not tMarkList[k] or (tMarkList[k] and tMarkList[k] ~= dwCharacterID) then
						return team.SetTeamMark(k, dwCharacterID)
					end
				end
			end
		end
		FireUIEvent('MY_TM_SET_MARK', false) -- 标记失败的案例
	end
	insert(MY_TM_MARK_QUEUE, { fnAction = fnAction })
	if MY_TM_MARK_FREE then
		MY_TM_MARK_FREE = false
		local f = table.remove(MY_TM_MARK_QUEUE, 1)
		pcall(f.fnAction)
	end
end
-- 倒计时处理 支持定义无限的倒计时
function D.CountdownEvent(data, nClass)
	if data.tCountdown then
		for k, v in ipairs(data.tCountdown) do
			if nClass == v.nClass then
				local szKey = k .. '.' .. (data.dwID or 0) .. '.' .. (data.nLevel or 0) .. '.' .. (data.nIndex or 0)
				local tParam = {
					key      = v.key,
					nFrame   = v.nFrame,
					nTime    = v.nTime,
					nRefresh = v.nRefresh,
					szName   = FilterCustomText(v.szName or data.szName),
					nIcon    = v.nIcon or data.nIcon or 340,
					bTalk    = v.bTeamChannel,
					bHold    = v.bHold
				}
				D.FireCountdownEvent(nClass, szKey, tParam)
			end
		end
	end
end

-- 发布事件 为了方便日后修改 集中起来
function D.FireCountdownEvent(nClass, szKey, tParam)
	tParam.bTalk = O.bPushTeamChannel and tParam.bTalk
	nClass       = tParam.key and MY_TM_TYPE.COMMON or nClass
	szKey        = tParam.key or szKey
	FireUIEvent('MY_TM_ST_CREATE', nClass, szKey, tParam)
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
		return LIB.GetObjectName(KObject)
	else
		return dwID
	end
end

-- local a=GetTime();for i=1, 10000 do FireUIEvent('BUFF_UPDATE',UI_GetClientPlayerID(),false,1,true,i,1,1,1,1,0) end;Output(GetTime()-a)
-- 事件操作
function D.OnBuff(dwCaster, bDelete, bCanCancel, dwBuffID, nCount, nBuffLevel, dwSkillSrcID)
	local szType = bCanCancel and 'BUFF' or 'DEBUFF'
	local key = dwBuffID .. '_' .. nBuffLevel
	local data = D.GetData(szType, dwBuffID, nBuffLevel)
	local nTime = GetTime()
	if not bDelete then
		-- 近期记录
		if Table_BuffIsVisible(dwBuffID, nBuffLevel) or not LIB.IsShieldedVersion(2) then
			local tWeak, tTemp = CACHE.TEMP[szType], D.TEMP[szType]
			if not tWeak[key] then
				local t = {
					dwMapID      = LIB.GetMapID(),
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
		if data.nScrutinyType and not D.CheckScrutinyType(data.nScrutinyType, dwCaster) then -- 监控对象检查
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
		D.CountdownEvent(data, nClass)
		if cfg then
			local szName, nIcon = LIB.GetBuffName(dwBuffID, nBuffLevel)
			local KObject = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
			if not KObject then
				return -- D.Log('ERROR ' .. szType .. ' object:' .. dwCaster .. ' does not exist!')
			end
			if data.szName then
				szName = FilterCustomText(data.szName)
			end
			nIcon  = data.nIcon or nIcon
			local szSrcName = LIB.GetObjectName(KObject)
			local aXml, aText = {}, {}
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szSrcName == MY_TM_CORE_NAME and g_tStrings.STR_YOU or szSrcName, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if nClass == MY_TM_TYPE.BUFF_GET then
				ConstructSpeech(aText, aXml, _L['Get buff'], 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, szName .. ' x' .. nCount, 44, 255, 255, 0)
				if data.szNote and not LIB.IsShieldedVersion(2) then
					ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote), 44, 255, 255, 255)
				end
			else
				ConstructSpeech(aText, aXml, _L['Lose buff'], 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
			end
			local szXml, szText = concat(aXml), concat(aText)
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm and (MY_TM_CORE_PLAYERID == dwCaster or not IsPlayer(dwCaster)) then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { GetHeadTextForceFontColor(dwCaster, MY_TM_CORE_PLAYERID) })
			end

			-- 获得处理
			if nClass == MY_TM_TYPE.BUFF_GET then
				if cfg.bSelect then
					SetTarget(IsPlayer(dwCaster) and TARGET.PLAYER or TARGET.NPC, dwCaster)
				end
				if cfg.bAutoCancel and MY_TM_CORE_PLAYERID == dwCaster then
					LIB.CancelBuff(dwBuffID)
				end
				if cfg.tMark then
					D.SetTeamMark(szType, cfg.tMark, dwCaster, dwBuffID, nBuffLevel)
				end
				-- 重要Buff列表
				if O.bPushPartyBuffList and IsPlayer(dwCaster) and cfg.bPartyBuffList and (LIB.IsParty(dwCaster) or MY_TM_CORE_PLAYERID == dwCaster) then
					FireUIEvent('MY_TM_PARTY_BUFF_LIST', dwCaster, data.dwID, data.nLevel, data.nIcon)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', dwCaster, szType, 'MY_TM_BUFF_' .. data.dwID, {
						dwBuffID = data.dwID,
						szText = szName,
						col = data.col or (szType == 'BUFF' and {0, 255, 0} or {255, 0, 0}),
					})
					FireUIEvent('MY_TM_SA_CREATE', szType, dwCaster, { dwID = data.dwID, col = data.col, text = szName })
				end
				if MY_TM_CORE_PLAYERID == dwCaster then
					if O.bPushBuffList and cfg.bBuffList then
						local col = szType == 'BUFF' and { 0, 255, 0 } or { 255, 0, 0 }
						if data.col then
							col = data.col
						end
						FireUIEvent('MY_TM_BL_CREATE', data.dwID, data.nLevel, col, data)
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
				if O.bPushTeamPanel and cfg.bTeamPanel and (not cfg.bOnlySelfSrc or dwSkillSrcID == MY_TM_CORE_PLAYERID) then
					FireUIEvent('MY_RAID_REC_BUFF', dwCaster, {
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
				D.Talk('RAID', szText, szSrcName)
			end
			if O.bPushWhisperChannel and cfg.bWhisperChannel then
				D.Talk('WHISPER', szText, szSrcName)
			end
		end
	end
end
-- 技能事件
function D.OnSkillCast(dwCaster, dwCastID, dwLevel, szEvent)
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
	if Table_IsSkillShow(dwCastID, dwLevel) or not LIB.IsShieldedVersion(2) then
		local tWeak, tTemp = CACHE.TEMP.CASTING, D.TEMP.CASTING
		if not tWeak[key] then
			local t = {
				dwMapID      = LIB.GetMapID(),
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
		local szName, nIcon = LIB.GetSkillName(dwCastID, dwLevel)
		local KObject = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
		if not KObject then
			return -- D.Log('ERROR CASTING object:' .. dwCaster .. ' does not exist!')
		end
		if data.szName then
			szName = FilterCustomText(data.szName)
		end
		nIcon  = data.nIcon or nIcon
		local szSrcName = LIB.GetObjectName(KObject)
		local dwTargetType, dwTargetID = KObject.GetTarget()
		local szTargetName
		if dwTargetID > 0 then
			szTargetName = LIB.GetObjectName(IsPlayer(dwTargetID) and GetPlayer(dwTargetID) or GetNpc(dwTargetID))
		end
		local cfg, nClass
		if szEvent == 'UI_OME_SKILL_CAST_LOG' then
			cfg, nClass = data[MY_TM_TYPE.SKILL_BEGIN], MY_TM_TYPE.SKILL_BEGIN
		else
			cfg, nClass = data[MY_TM_TYPE.SKILL_END], MY_TM_TYPE.SKILL_END
		end
		D.CountdownEvent(data, nClass)
		if cfg then
			local aXml, aText = {}, {}
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szSrcName, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if nClass == MY_TM_TYPE.SKILL_END then
				ConstructSpeech(aText, aXml, _L['use of'], 44, 255, 255, 255)
			else
				ConstructSpeech(aText, aXml, _L['Casting'], 44, 255, 255, 255)
			end
			ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
			ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
			ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			if data.bMonTarget and szTargetName then
				ConstructSpeech(aText, aXml, g_tStrings.TARGET, 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aText, aXml, szTargetName == MY_TM_CORE_NAME and g_tStrings.STR_YOU or szTargetName, 44, 255, 255, 0)
				ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
			end
			if data.szNote and not LIB.IsShieldedVersion(2) then
				ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote), 44, 255, 255, 255)
			end
			local szXml, szText = concat(aXml), concat(aText)
			if O.bPushCenterAlarm and cfg.bCenterAlarm then
				FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
			end
			-- 特大文字
			if O.bPushBigFontAlarm and cfg.bBigFontAlarm then
				FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { GetHeadTextForceFontColor(dwCaster, MY_TM_CORE_PLAYERID) })
			end
			if not LIB.IsShieldedVersion(2) and cfg.bSelect then
				SetTarget(IsPlayer(dwCaster) and TARGET.PLAYER or TARGET.NPC, dwCaster)
			end
			if cfg.tMark then
				D.SetTeamMark('CASTING', cfg.tMark, dwCaster, dwSkillID, dwLevel)
			end
			-- 头顶报警
			if O.bPushScreenHead and cfg.bScreenHead then
				FireUIEvent('MY_LIFEBAR_COUNTDOWN', dwCaster, 'CASTING', 'MY_TM_CASTING_' .. data.dwID, {
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
				D.Talk('RAID', szText, szTargetName)
			end
			if O.bPushWhisperChannel and cfg.bWhisperChannel then
				D.Talk('RAID_WHISPER', szText, szTargetName)
			end
		end
	end
end

-- NPC事件
function D.OnNpcEvent(npc, bEnter)
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
				dwMapID      = LIB.GetMapID(),
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
					local szNote, szName = nil, FilterCustomText(data.szName)
					if not LIB.IsShieldedVersion(2) then
						szNote = FilterCustomText(data.szNote) or szName
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
		D.CountdownEvent(data, nClass)
		if cfg then
			local szName = LIB.GetObjectName(npc)
			if data.szName then
				szName = FilterCustomText(data.szName)
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
				if data.szNote and not LIB.IsShieldedVersion(2) then
					ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote), 44, 255, 255, 255)
				end
			else
				ConstructSpeech(aText, aXml, _L['Disappear'], 44, 255, 255, 255)
			end
			local szXml, szText = concat(aXml), concat(aText)
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
				if not LIB.IsShieldedVersion(2) and cfg.bSelect then
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
		if doodad.nKind ~= DOODAD_KIND.ORNAMENT or not LIB.IsShieldedVersion(2) then
			local tWeak, tTemp = CACHE.TEMP.DOODAD, D.TEMP.DOODAD
			if not tWeak[doodad.dwTemplateID] then
				local t = {
					dwMapID      = LIB.GetMapID(),
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
					local szNote, szName = nil, FilterCustomText(data.szName)
					if not LIB.IsShieldedVersion(2) then
						szNote = FilterCustomText(data.szNote) or szName
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
		D.CountdownEvent(data, nClass)
		if cfg then
			local szName = doodad.szName
			if data.szName then
				szName = FilterCustomText(data.szName)
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
				if data.szNote and not LIB.IsShieldedVersion(2) then
					ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(data.szNote), 44, 255, 255, 255)
				end
			else
				ConstructSpeech(aText, aXml, _L['Disappear'], 44, 255, 255, 255)
			end
			local szXml, szText = concat(aXml), concat(aText)
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
	local data = D.GetData('DOODAD', dwTemplateID)
	if data then
		D.CountdownEvent(data, MY_TM_TYPE.DOODAD_ALLLEAVE)
	end
end
-- 系统和NPC喊话处理
-- OutputMessage('MSG_SYS', 1..'\n')
function D.OnCallMessage(szEvent, szContent, dwNpcID, szNpcName)
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
	local tInfo, data
	local cache = CACHE.MAP[szEvent]
	if cache.HIT[szContent] then
		if cache.HIT[szContent][szNpcName or 'sys'] then
			data = cache.HIT[szContent][szNpcName or 'sys']
		elseif cache.HIT[szContent]['%'] then
			data = cache.HIT[szContent]['%']
		end
	end
	-- 不适用wstring 性能考虑为前提
	if not data then
		local bInParty = me.IsInParty()
		local team     = GetClientTeam()
		for k, v in ipairs_r(cache.OTHER) do
			local content = v.szContent
			if v.szContent:find('$me') then
				content = v.szContent:gsub('$me', me.szName) -- 转换me是自己名字
			end
			if bInParty and content:find('$team') then
				local c = content
				for kk, vv in ipairs(team.GetTeamMemberList()) do
					if string.find(szContent, c:gsub('$team', team.GetClientTeamMemberName(vv)), nil, true) and (v.szTarget == szNpcName or v.szTarget == '%') then -- hit
						tInfo = { dwID = vv, szName = team.GetClientTeamMemberName(vv) }
						data = v
						break
					end
				end
			else
				if v.szTarget == szNpcName or v.szTarget == '%' then
					if (v.bReg and string.find(szContent, content)) or
						(not v.bReg and string.find(szContent, content, nil, true))
					then
						data = v
						break
					end
				end
			end
		end
	end
	if data then
		local nClass = szEvent == 'TALK' and MY_TM_TYPE.TALK_MONITOR or MY_TM_TYPE.CHAT_MONITOR
		D.CountdownEvent(data, nClass)
		local cfg = data[nClass]
		if cfg then
			if data.szContent:find('$me') then
				tInfo = { dwID = me.dwID, szName = me.szName }
			end
			local aXml, aText = {}, {}
			local szNote = nil
			if data.szNote and not LIB.IsShieldedVersion(2) then
				szNote = data.szNote
			end
			if tInfo and not szNote then
				ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aText, aXml, szNpcName or _L['JX3'], 44, 255, 255, 0)
				ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
				ConstructSpeech(aText, aXml, _L['is calling'], 44, 255, 255, 255)
				ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
				ConstructSpeech(aText, aXml, tInfo.szName == me.szName and g_tStrings.STR_YOU or tInfo.szName, 44, 255, 255, 0)
				ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
				ConstructSpeech(aText, aXml, _L['\'s name.'], 44, 255, 255, 255)
			else
				ConstructSpeech(aText, aXml, FilterCustomText(szNote) or szContent, 44, 255, 255, 255)
			end
			local szXml, szText = concat(aXml), concat(aText)
			szText = szText:gsub('$me', me.szName)
			if tInfo then -- 点了人名
				szText = szText:gsub('$team', tInfo.szName)
				if O.bPushWhisperChannel and cfg.bWhisperChannel then
					D.Talk('WHISPER', szText, tInfo.szName)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead then
					FireUIEvent('MY_LIFEBAR_COUNTDOWN', tInfo.dwID, 'TIME', 'MY_TM_TIME_' .. tInfo.dwID, {
						nTime = GetTime() + 5000,
						szText = _L('%s call name', szNpcName or g_tStrings.SYSTEM),
						col = data.col,
						bHideProgress = true,
					})
					FireUIEvent('MY_TM_SA_CREATE', 'TIME', tInfo.dwID, { text = _L('%s call name', szNpcName or g_tStrings.SYSTEM)})
				end
				if not LIB.IsShieldedVersion(2) and cfg.bSelect then
					SetTarget(TARGET.PLAYER, tInfo.dwID)
				end
			else -- 没点名
				if O.bPushWhisperChannel and cfg.bWhisperChannel then
					D.Talk('RAID_WHISPER', szText)
				end
				-- 头顶报警
				if O.bPushScreenHead and cfg.bScreenHead and not LIB.IsShieldedVersion(2) then
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
				if (tInfo and tInfo.dwID == me.dwID) or not tInfo then
					FireUIEvent('MY_TM_FS_CREATE', szEvent, { nTime  = 3, col = data.col or { 0, 255, 0 }, bFlash = true })
				end
			end
			if O.bPushTeamChannel and cfg.bTeamChannel then
				if tInfo and not data.szNote then
					D.Talk('RAID', szText, tInfo.szName)
				else
					D.Talk('RAID', szText)
				end
			end
		end
	end
end

-- NPC死亡事件 触发倒计时
function D.OnDeath(dwCharacterID, dwKiller)
	local npc = GetNpc(dwCharacterID)
	if npc then
		local data = D.GetData('NPC', npc.dwTemplateID)
		if data then
			local dwTemplateID = npc.dwTemplateID
			D.CountdownEvent(data, MY_TM_TYPE.NPC_DEATH)
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
				D.CountdownEvent(data, MY_TM_TYPE.NPC_ALLDEATH)
			end
		end
	end
end

-- NPC进出战斗事件 触发倒计时
function D.OnNpcFight(dwTemplateID, bFight)
	local data = D.GetData('NPC', dwTemplateID)
	if data then
		if bFight then
			D.CountdownEvent(data, MY_TM_TYPE.NPC_FIGHT)
		elseif data.tCountdown then -- 脱离的时候清空下
			for k, v in ipairs(data.tCountdown) do
				if v.nClass == MY_TM_TYPE.NPC_FIGHT and not v.bFightHold then
					local class = v.key and MY_TM_TYPE.COMMON or v.nClass
					FireUIEvent('MY_TM_ST_DEL', class, v.key or (k .. '.'  .. data.dwID .. '.' .. (data.nLevel or 0)), true) -- try kill
				end
			end
		end
	end
end

function D.GetStringStru(szString)
	if CACHE.STR[szString] then
		return CACHE.STR[szString]
	else
		local data = {}
		for k, v in ipairs(MY_SplitString(szString, ';')) do
			local line = MY_SplitString(v, ',')
			if line[1] and line[2] and tonumber(MY_TrimString(line[1])) and MY_TrimString(line[2]) ~= '' then
				line[1] = tonumber(MY_TrimString(line[1]))
				line[2] = MY_TrimString(line[2])
				insert(data, line)
			end
		end
		CACHE.STR[szString] = data
		return data
	end
end
-- 不该放在倒计时中 需要重构
function D.OnNpcInfoChange(szEvent, dwTemplateID, nPer)
	local data = D.GetData('NPC', dwTemplateID)
	if data and data.tCountdown then
		local dwType = szEvent == 'MY_TM_NPC_LIFE_CHANGE' and MY_TM_TYPE.NPC_LIFE or MY_TM_TYPE.NPC_MANA
		for k, v in ipairs(data.tCountdown) do
			if v.nClass == dwType then
				local tLife = D.GetStringStru(v.nTime)
				for kk, vv in ipairs(tLife) do
					local nVper = vv[1] * 100
					if nVper == nPer then -- hit
						local szName = v.szName or LIB.GetTemplateName(dwTemplateID)
						local aXml, aText = {}, {}
						ConstructSpeech(aText, aXml, MY_TM_LEFT_BRACKET, MY_TM_LEFT_BRACKET_XML)
						ConstructSpeech(aText, aXml, szName, 44, 255, 255, 0)
						ConstructSpeech(aText, aXml, MY_TM_RIGHT_BRACKET, MY_TM_RIGHT_BRACKET_XML)
						ConstructSpeech(aText, aXml, dwType == MY_TM_TYPE.NPC_LIFE and _L['\'s life remaining to '] or _L['\'s mana reaches '], 44, 255, 255, 255)
						ConstructSpeech(aText, aXml, ' ' .. nVper .. '%', 44, 255, 255, 0)
						ConstructSpeech(aText, aXml, ' ' .. FilterCustomText(vv[2]), 44, 255, 255, 255)
						local szXml, szText = concat(aXml), concat(aText)
						if O.bPushCenterAlarm then
							FireUIEvent('MY_TM_CA_CREATE', szXml, 3, true)
						end
						if O.bPushBigFontAlarm then
							FireUIEvent('MY_TM_LARGE_TEXT', szText, data.col or { 255, 128, 0 })
						end
						if O.bPushTeamChannel and v.bTeamChannel then
							D.Talk('RAID', szText)
						end
						if vv[3] and tonumber(MY_TrimString(vv[3])) then
							local szKey = k .. '.' .. dwTemplateID .. '.' .. kk
							local tParam = {
								key    = v.key,
								nFrame = v.nFrame,
								nTime  = tonumber(MY_TrimString(vv[3])),
								szName = vv[2],
								nIcon  = v.nIcon,
								bTalk  = v.bTeamChannel,
								bHold  = v.bHold
							}
							D.FireCountdownEvent(v.nClass, szKey, tParam)
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
	local data = D.GetData('NPC', dwTemplateID)
	if data then
		D.CountdownEvent(data, MY_TM_TYPE.NPC_ALLLEAVE)
	end
end

-- RegisterMsgMonitor
function D.RegisterMessage(bEnable)
	if bEnable then
		LIB.RegisterMsgMonitor('MY_TeamMon_MON', function(szMsg, nFont, bRich)
			if not GetClientPlayer() then
				return
			end
			if bRich then
				szMsg = MY_GetPureText(szMsg)
			end
			-- local res, err = pcall(D.OnCallMessage, 'CHAT', szMsg:gsub('\r', ''))
			-- if not res then
			-- 	return LIB.Sysmsg(err, DEBUG_LEVEL.WARNING)
			-- end
			szMsg = szMsg:gsub('\r', '')
			D.OnCallMessage('CHAT', szMsg)
		end, { 'MSG_SYS' })
	else
		LIB.RegisterMsgMonitor('MY_TeamMon_MON')
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
	if bEnable then
		local res, err = pcall(D.Open)
		if not res then
			return LIB.Sysmsg(err, DEBUG_LEVEL.WARNING)
		end
		if bFireUIEvent then
			FireUIEvent('MY_TM_LOADING_END')
			for _, v in pairs(LIB.GetNearNpcID()) do
				FireUIEvent('MY_TM_NPC_ENTER_SCENE', v)
			end
		end
	else
		D.Close()
	end
end

function D.Init()
	if not MY_TM_DATA_EMBEDDED_ENCRYPTED then
		-- 自动生成内置加密数据
		local DAT_ROOT = 'MY_TeamMon/data/'
		local SRC_ROOT = PACKET_INFO.ROOT .. '!src-dist/dat/' .. DAT_ROOT
		for _, szFile in ipairs(CPath.GetFileList(SRC_ROOT)) do
			LIB.Sysmsg(_L['Encrypt and compressing: '] .. DAT_ROOT .. szFile)
			local uuid = szFile:sub(1, -13)
			local lang = szFile:sub(-11, -8)
			if lang == 'zhcn' or lang == 'zhtw' then
				local data = LoadDataFromFile(SRC_ROOT .. szFile)
				if IsEncodedData(data) then
					data = DecodeData(data)
				end
				data = EncodeData(data, true, true)
				SaveDataToFile(data, LIB.FormatPath({'userdata/TeamMon/Data/' .. uuid .. '.jx3dat', PATH_TYPE.GLOBAL}, {lang = lang}), MY_TM_DATA_PASSPHRASE)
			end
		end
		MY_TM_DATA_EMBEDDED_ENCRYPTED = true
	end
	D.LoadUserData()
	Wnd.OpenWindow(MY_TM_INIFILE, 'MY_TeamMon')
end

function D.SaveData()
	LIB.SaveLUAData(GetDataPath(), D.FILE)
end

-- 获取整个表
function D.GetTable(szType, bTemp)
	if bTemp then
		if szType == 'CIRCLE' then -- 如果请求圈圈的近期数据 返回NPC的
			szType = 'NPC'
		end
		return D.TEMP[szType]
	else
		if szType == 'CIRCLE' then -- 如果请求圈圈
			return Circle.GetData()
		else
			return D.FILE[szType]
		end
	end
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

local function UpgradeFocusData(data, aFocus)
	if not aFocus then
		return
	end
	local nCount = 0
	for dwMapID, aData in pairs(aFocus) do
		if not data['NPC'][dwMapID] then
			data['NPC'][dwMapID] = {}
		end
		for _, focus in ipairs(aData) do
			local npc
			for _, p in ipairs(data['NPC'][dwMapID]) do
				if p.dwID == focus.dwID then
					npc = p
					break
				end
			end
			if not npc then
				npc = {
					["nFrame"] = focus.nFrame,
					["dwID"] = focus.dwID,
				}
				insert(data['NPC'][dwMapID], npc)
			end
			if not npc.aFocus then
				npc.aFocus = {}
			end
			insert(npc.aFocus, {
				szDisplay = focus.szDisplay,
				tRelation = focus.tRelation,
				nMaxDistance = focus.nMaxDistance,
			})
			nCount = nCount + 1
		end
	end
	if nCount > 0 then
		LIB.Sysmsg(_L('%s focus rules converted, if you are data author please notice that focus auto convert will not last long, you should export your data again.', nCount), _L['MY_TeamMon'], 'MSG_SYS.ERROR')
	end
end

function D.LoadUserData()
	local data = LIB.LoadLUAData(GetDataPath())
	if data then
		for k, v in pairs(D.FILE) do
			D.FILE[k] = data[k] or {}
		end
		UpgradeFocusData(D.FILE, data['FOCUS'])
		FireUIEvent('MY_TM_DATA_RELOAD')
	else
		local szLang = select(3, GetVersion())
		local config = {
			nMode = 1,
			tList = {},
			szFileName = szLang ..  '.jx3dat',
		}
		-- default data
		for _, v in ipairs(MY_TM_TYPE_LIST) do
			config.tList[v] = true
		end
		D.LoadConfigureFile(config)
	end
	D.Log('load custom data success!')
end

function D.LoadConfigureFile(config)
	local szFullPath = config.szFileName:sub(2, 2) == ':'
		and config.szFileName
		or LIB.GetAbsolutePath(MY_TM_DATA_ROOT .. config.szFileName)
	local szFilePath = LIB.GetRelativePath(szFullPath, {'', PATH_TYPE.NORMAL}) or szFullPath
	if not IsFileExist(szFilePath) then
		return false, 'File does not exist.'
	end
	local data = LIB.LoadLUAData(szFilePath, { passphrase = MY_TM_DATA_PASSPHRASE })
		or LIB.LoadLUAData(szFilePath, { passphrase = false })
	if not data then
		return false, 'Can not read data file.'
	else
		if config.nMode == 1 then
			if config.tList['CIRCLE'] then
				if Circle then
					local dat = { Circle = data['CIRCLE'] }
					Circle.LoadCircleData(dat)
				end
				config.tList['CIRCLE'] = nil
			end
			for k, v in pairs(config.tList) do
				D.FILE[k] = data[k] or {}
			end
		elseif config.nMode == 2 or config.nMode == 3 then
			if config.tList['CIRCLE'] then
				if Circle then
					local dat = { Circle = data['CIRCLE'] }
					Circle.LoadCircleMergeData(dat, config.nMode == 3 and true or false)
				end
				config.tList['CIRCLE'] = nil
			end
			local fnMergeData = function(tab_data)
				for szType, _ in pairs(config.tList) do
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
			if config.nMode == 2 then -- 源文件优先
				fnMergeData(data)
			elseif config.nMode == 3 then -- 新文件优先
				-- 其实就是交换下顺序
				local tab_data = clone(D.FILE)
				for k, v in pairs(config.tList) do
					D.FILE[k] = data[k] or {}
				end
				fnMergeData(tab_data)
			end
		end
		if config.tList['NPC'] then
			UpgradeFocusData(D.FILE, data['FOCUS'])
		end
		FireUIEvent('MY_TM_CREATE_CACHE')
		FireUIEvent('MY_TM_DATA_RELOAD')
		FireUIEvent('MY_TMUI_DATA_RELOAD')
		return true, szFullPath:gsub('\\', '/')
	end
end

function D.SaveConfigureFile(config)
	local data = {}
	for k, v in pairs(config.tList) do
		data[k] = D.FILE[k]
	end
	if config.tList['CIRCLE'] then
		if Circle then
			data['CIRCLE'] = Circle.GetData()
		end
	end
	-- HM.20170504: add meta data
	data['__meta'] = {
		szLang = select(3, GetVersion()),
		szAuthor = GetUserRoleName(),
		szServer = select(4, GetUserServer()),
		nTimeStamp = GetCurrentTime()
	}
	local root = GetRootPath():gsub('\\', '/')
	local path = MY_TM_DATA_ROOT .. config.szFileName
	if config.bJson then
		path = path .. '.json'
		SaveDataToFile(LIB.JsonEncode(data, config.bFormat), path)
		-- Log(path, LIB.JsonEncode(data, config.bFormat), 'close')
		-- SaveLUAData(path, LIB.JsonEncode(data, config.bFormat), nil, false)
	else
		local option = {
			passphrase = MY_TM_DATA_PASSPHRASE,
			crc = true,
			compress = true,
		}
		if config.bFormat then
			option.indent = '\t'
			option.crc = false
			option.compress = false
			option.passphrase = false
		end
		LIB.SaveLUAData(path, data, option)
	end
	LIB.GetAbsolutePath(path):gsub('/', '\\')
	return root .. path
end

-- 删除 移动 添加 清空
function D.RemoveData(szType, dwMapID, nIndex)
	if nIndex then
		if D.FILE[szType][dwMapID] and D.FILE[szType][dwMapID][nIndex] then
			if dwMapID == -9 then
				table.remove(D.FILE[szType][dwMapID], nIndex)
				if #D.FILE[szType][dwMapID] == 0 then
					D.FILE[szType][dwMapID] = nil
				end
				FireUIEvent('MY_TM_CREATE_CACHE')
				FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
				FireUIEvent('MY_TMUI_DATA_RELOAD')
			else
				D.MoveData(szType, dwMapID, nIndex, -9)
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
		if dwMapID ~= -9 then
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
			return LIB.Alert(_L['Same data exist'])
		end
		D.FILE[szType][dwTargetMapID] = D.FILE[szType][dwTargetMapID] or {}
		insert(D.FILE[szType][dwTargetMapID], clone(D.FILE[szType][dwMapID][nIndex]))
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
	insert(D.FILE[szType][dwMapID], data)
	FireUIEvent('MY_TM_CREATE_CACHE')
	FireUIEvent('MY_TMUI_DATA_RELOAD')
	FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
	return D.FILE[szType][dwMapID][#D.FILE[szType][dwMapID]]
end

function D.ClearTemp(szType)
	if szType == 'CIRCLE' then -- 如果请求圈圈的近期数据 返回NPC的
		szType = 'NPC'
	end
	CACHE.INTERVAL[szType] = {}
	D.TEMP[szType] = {}
	FireUIEvent('MY_TMUI_TEMP_RELOAD')
	collectgarbage('collect')
	D.Log('clear ' .. szType .. ' cache success!')
end

function D.GetIntervalData(szType, key)
	if szType == 'CIRCLE' then -- 如果请求圈圈的近期数据 返回NPC的
		szType = 'NPC'
	end
	if CACHE.INTERVAL[szType] then
		return CACHE.INTERVAL[szType][key]
	end
end

function D.ConfirmShare()
	if #MY_TM_SHARE_QUEUE > 0 then
		local t = MY_TM_SHARE_QUEUE[1]
		LIB.Confirm(_L('%s share a %s data to you, accept?', t.szName, _L[t.szType]), function()
			if t.szType ~= 'CIRCLE' then
				local data = t.tData
				local nIndex = D.CheckSameData(t.szType, t.dwMapID, data.dwID or data.szContent, data.nLevel or data.szTarget)
				if nIndex then
					D.RemoveData(t.szType, t.dwMapID, nIndex)
				end
				D.AddData(t.szType, t.dwMapID, data)
			else
				local data = t.tData
				local nIndex = Circle.CheckSameData(t.dwMapID, data.key, data.dwType)
				if nIndex then
					Circle.RemoveData(t.dwMapID, nIndex)
				end
				Circle.AddData(t.dwMapID, data)
			end
			table.remove(MY_TM_SHARE_QUEUE, 1)
			LIB.DelayCall(100, D.ConfirmShare)
		end, function()
			table.remove(MY_TM_SHARE_QUEUE, 1)
			LIB.DelayCall(100, D.ConfirmShare)
		end)
	end
end

function D.OnShare(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf then
		if data[1] ~= 'CIRCLE' or type(Circle) ~= 'nil' then
			insert(MY_TM_SHARE_QUEUE, {
				szType  = data[1],
				tData   = data[3],
				szName  = szName,
				dwMapID = data[2]
			})
			D.ConfirmShare()
		end
	end
end

LIB.RegisterInit('MY_TeamMon', D.Init)
LIB.RegisterExit('MY_TeamMon', D.SaveData)
LIB.RegisterBgMsg('MY_TM_SHARE', D.OnShare)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				FilterCustomText    = FilterCustomText   ,
				Enable              = D.Enable           ,
				GetTable            = D.GetTable         ,
				GetData             = D.GetData          ,
				GetIntervalData     = D.GetIntervalData  ,
				RemoveData          = D.RemoveData       ,
				MoveData            = D.MoveData         ,
				CheckSameData       = D.CheckSameData    ,
				ClearTemp           = D.ClearTemp        ,
				AddData             = D.AddData          ,
				SaveConfigureFile   = D.SaveConfigureFile,
				LoadConfigureFile   = D.LoadConfigureFile,
				Exchange            = D.Exchange         ,
				MY_TM_META_ROOT     = MY_TM_META_ROOT    ,
				MY_TM_DATA_ROOT     = MY_TM_DATA_ROOT    ,
				MY_TM_TYPE          = MY_TM_TYPE         ,
				MY_TM_SCRUTINY_TYPE = MY_TM_SCRUTINY_TYPE,
			},
		},
		{
			fields = {
				bEnable             = true,
				bCommon             = true,
				bPushScreenHead     = true,
				bPushCenterAlarm    = true,
				bPushBigFontAlarm   = true,
				bPushTeamPanel      = true,
				bPushFullScreen     = true,
				bPushTeamChannel    = true,
				bPushWhisperChannel = true,
				bPushBuffList       = true,
				bPushPartyBuffList  = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable             = true,
				bCommon             = true,
				bPushScreenHead     = true,
				bPushCenterAlarm    = true,
				bPushBigFontAlarm   = true,
				bPushTeamPanel      = true,
				bPushFullScreen     = true,
				bPushTeamChannel    = true,
				bPushWhisperChannel = true,
				bPushBuffList       = true,
				bPushPartyBuffList  = true,
			},
			root = O,
		},
	},
}
MY_TeamMon = LIB.GeneGlobalNS(settings)
end
