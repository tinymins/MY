--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗日志 流式保存原始事件数据
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_CombatLogs', _L['Raid'], {
	bEnable = { -- 数据记录总开关
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nMaxHistory = { -- 最大历史数据数量
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = Schema.Number,
		xDefaultValue = 300,
	},
	nMinFightTime = { -- 最小战斗时间
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = Schema.Number,
		xDefaultValue = 30,
	},
	bOnlyDungeon = { -- 仅在秘境中启用
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bOnlySelf = { -- 仅记录和自己有关的
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}
local DS_ROOT = {'userdata/combat_logs/', PATH_TYPE.ROLE}

local LOG_ENABLE = false -- 计算出来的总开关，按条件随时重算
local LOG_TIME = 0
local LOG_FILE -- 当前日志文件，处于存盘模式，即处于逻辑战斗状态时不为空
local LOG_CACHE = {} -- 尚未存盘的数据（降低磁盘压力）
local LOG_CACHE_LIMIT = 20 -- 缓存数据达到数量触发存盘
local LOG_CRC = 0
local LOG_TARGET_INFO_TIME = {} -- 目标信息记录时间
local LOG_TARGET_INFO_TIME_LIMIT = 10000 -- 目标信息再次记录最小时间间隔
local LOG_DOODAD_INFO_TIME = {} -- 交互物件信息记录时间
local LOG_DOODAD_INFO_TIME_LIMIT = 10000 -- 交互物件信息再次记录最小时间间隔
local LOG_NAMING_COUNT = {} -- 记录中NPC被提及的数量统计，用于命名记录文件

local LOG_REPLAY = {} -- 最近的数据 （进战时候将最近的数据压进来）
local LOG_REPLAY_FRAME = GLOBAL.GAME_FPS * 1 -- 进战时候将多久的数据压进来（逻辑帧）

local LOG_TYPE = {
	FIGHT_TIME                            = 1,  -- 战斗时间
	PLAYER_ENTER_SCENE                    = 2,  -- 玩家进入场景
	PLAYER_LEAVE_SCENE                    = 3,  -- 玩家离开场景
	PLAYER_INFO                           = 4,  -- 玩家信息数据
	PLAYER_FIGHT_HINT                     = 5,  -- 玩家战斗状态改变
	NPC_ENTER_SCENE                       = 6,  -- NPC 进入场景
	NPC_LEAVE_SCENE                       = 7,  -- NPC 离开场景
	NPC_INFO                              = 8,  -- NPC 信息数据
	NPC_FIGHT_HINT                        = 9,  -- NPC 战斗状态改变
	DOODAD_ENTER_SCENE                    = 10, -- 交互物件进入场景
	DOODAD_LEAVE_SCENE                    = 11, -- 交互物件离开场景
	DOODAD_INFO                           = 12, -- 交互物件信息数据
	BUFF_UPDATE                           = 13, -- BUFF 刷新
	PLAYER_SAY                            = 14, -- 角色喊话（仅记录NPC）
	ON_WARNING_MESSAGE                    = 15, -- 显示警告框
	PARTY_ADD_MEMBER                      = 16, -- 团队添加成员
	PARTY_SET_MEMBER_ONLINE_FLAG          = 17, -- 团队成员在线状态改变
	MSG_SYS                               = 18, -- 系统消息
	SYS_MSG_UI_OME_SKILL_CAST_LOG         = 19, -- 技能施放日志
	SYS_MSG_UI_OME_SKILL_CAST_RESPOND_LOG = 20, -- 技能施放结果日志
	SYS_MSG_UI_OME_SKILL_EFFECT_LOG       = 21, -- 技能最终产生的效果（生命值的变化）
	SYS_MSG_UI_OME_SKILL_BLOCK_LOG        = 22, -- 格挡日志
	SYS_MSG_UI_OME_SKILL_SHIELD_LOG       = 23, -- 技能被屏蔽日志
	SYS_MSG_UI_OME_SKILL_MISS_LOG         = 24, -- 技能未命中目标日志
	SYS_MSG_UI_OME_SKILL_HIT_LOG          = 25, -- 技能命中目标日志
	SYS_MSG_UI_OME_SKILL_DODGE_LOG        = 26, -- 技能被闪避日志
	SYS_MSG_UI_OME_COMMON_HEALTH_LOG      = 27, -- 普通治疗日志
	SYS_MSG_UI_OME_DEATH_NOTIFY           = 28, -- 死亡日志
}

-- 更新启用状态
function D.UpdateEnable()
	local bEnable = D.bReady and O.bEnable and (not O.bOnlyDungeon or LIB.IsInDungeon())
	if not bEnable and LOG_ENABLE then
		D.CloseCombatLogs()
	elseif bEnable and not LOG_ENABLE and LIB.IsFighting() then
		D.OpenCombatLogs()
	end
	LOG_ENABLE = bEnable
end
LIB.RegisterEvent('LOADING_ENDING', D.UpdateEnable)

-- 加载历史数据列表
function D.GetHistoryFiles()
	local aFiles = {}
	local szRoot = LIB.FormatPath(DS_ROOT)
	for _, v in ipairs(CPath.GetFileList(szRoot)) do
		if v:find('.jcl.tsv$') then
			insert(aFiles, v)
		end
	end
	sort(aFiles, function(a, b) return a > b end)
	for k, v in ipairs(aFiles) do
		aFiles[k] = szRoot .. v
	end
	return aFiles
end

-- 限制历史数据数量
function D.LimitHistoryFile()
	local aFiles = D.GetHistoryFiles()
	for i = O.nMaxHistory + 1, #aFiles do
		CPath.DelFile(aFiles[i])
	end
end

-- 连接到新的日志文件
function D.OpenCombatLogs()
	D.CloseCombatLogs()
	local szRoot = LIB.FormatPath(DS_ROOT)
	CPath.MakeDir(szRoot)
	local szTime = LIB.FormatTime(GetCurrentTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
	local szMapName = ''
	local me = GetClientPlayer()
	if me then
		local map = LIB.GetMapInfo(me.GetMapID())
		if map then
			szMapName = '-' .. map.szName
		end
	end
	LOG_FILE = szRoot .. szTime .. szMapName .. '.jcl.log'
	LOG_TIME = GetCurrentTime()
	LOG_CACHE = {}
	LOG_TARGET_INFO_TIME = {}
	LOG_DOODAD_INFO_TIME = {}
	LOG_NAMING_COUNT = {}
	LOG_CRC = 0
	Log(LOG_FILE, '', 'clear')
end

-- 关闭到日志文件的连接
function D.CloseCombatLogs()
	if not LOG_FILE then
		return
	end
	D.FlushLogs(true)
	Log(LOG_FILE, '', 'close')
	if GetCurrentTime() - LOG_TIME < O.nMinFightTime then
		CPath.DelFile(LOG_FILE)
	else
		local szName, nCount = '', 0
		for _, p in pairs(LOG_NAMING_COUNT) do
			if p.nCount > nCount then
				nCount = p.nCount
				szName = '-' .. p.szName
			end
		end
		CPath.Move(LOG_FILE, wsub(LOG_FILE, 1, -9) .. szName .. '.jcl')
	end
	LOG_FILE = nil
end
LIB.RegisterReload('MY_CombatLogs', D.CloseCombatLogs)

-- 将缓存数据写入磁盘
function D.FlushLogs(bForce)
	if not LOG_FILE then
		return
	end
	if not bForce and #LOG_CACHE < LOG_CACHE_LIMIT then
		return
	end
	for _, v in ipairs(LOG_CACHE) do
		Log(LOG_FILE, v)
	end
	LOG_CACHE = {}
end

-- 插入事件数据
function D.InsertLog(szEvent, oData, bReplay)
	if not LOG_ENABLE then
		return
	end
	assert(szEvent, 'error: missing event id')
	-- 生成日志行
	local nLFC = GetLogicFrameCount()
	local szLog = nLFC
		.. '\t' .. GetCurrentTime()
		.. '\t' .. GetTime()
		.. '\t' .. szEvent
		.. '\t' .. wgsub(wgsub(LIB.EncodeLUAData(oData), '\\\n', '\\n'), '\t', '\\t')
	local nCRC = GetStringCRC(LOG_CRC .. szLog .. 'c910e9b9-8359-4531-85e0-6897d8c129f7')
	-- 插入缓存
	insert(LOG_CACHE, nCRC .. '\t' .. szLog .. '\n')
	-- 插入最近事件表
	if bReplay ~= false then
		while LOG_REPLAY[1] and nLFC - LOG_REPLAY[1].nLFC > LOG_REPLAY_FRAME do
			remove(LOG_REPLAY, 1)
		end
		insert(LOG_REPLAY, { nLFC = nLFC, szLog = szLog })
	end
	-- 更新流式校验码
	LOG_CRC = nCRC
	-- 检查数据存盘
	D.FlushLogs()
end

-- 重放最近事件
function D.ImportRecentLogs()
	-- 检查最近事件表插入缓存
	local nLFC, nCRC = GetLogicFrameCount(), LOG_CRC
	for _, v in ipairs(LOG_REPLAY) do
		if nLFC - v.nLFC <= LOG_REPLAY_FRAME then
			nCRC = GetStringCRC(nCRC .. v.szLog .. 'c910e9b9-8359-4531-85e0-6897d8c129f7')
			insert(LOG_CACHE, nCRC .. '\t' .. v.szLog .. '\n')
		end
	end
	-- 更新流式校验码
	LOG_CRC = nCRC
	-- 检查数据存盘
	D.FlushLogs()
end

-- 过图清除当前战斗数据
LIB.RegisterEvent({ 'LOADING_ENDING', 'RELOAD_UI_ADDON_END', 'BATTLE_FIELD_END', 'ARENA_END', 'MY_CLIENT_PLAYER_LEAVE_SCENE' }, function()
	D.FlushLogs(true)
end)

-- 退出战斗 保存数据
LIB.RegisterEvent('MY_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local bFighting, szUUID, nDuring = arg0, arg1, arg2
	if not bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring })
	end
	if bFighting then -- 进入新的战斗
		D.OpenCombatLogs()
		D.ImportRecentLogs()
	else
		D.CloseCombatLogs()
	end
	if bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring })
	end
end)

function D.WillRecID(dwID)
	if O.bOnlySelf then
		if not IsPlayer(dwID) then
			local npc = GetNpc(dwID)
			if npc then
				dwID = npc.dwEmployer
			end
		end
		return dwID == UI_GetClientPlayerID()
	end
	return true
end

-- 保存目标信息
function D.OnTargetUpdate(dwID, bForce)
	if not IsNumber(dwID) then
		return
	end
	local bIsPlayer = IsPlayer(dwID)
	if not bIsPlayer then
		if not LOG_NAMING_COUNT[dwID] then
			LOG_NAMING_COUNT[dwID] = {
				nCount = 0,
				szName = '',
			}
		end
		LOG_NAMING_COUNT[dwID].nCount = LOG_NAMING_COUNT[dwID].nCount + 1
	end
	if not bForce and LOG_TARGET_INFO_TIME[dwID] and LOG_TARGET_INFO_TIME[dwID] - GetTime() < LOG_TARGET_INFO_TIME_LIMIT then
		return
	end
	if bIsPlayer then
		local player = GetPlayer(dwID)
		if not player then
			return
		end
		local szName = player.szName
		local dwForceID = player.dwForceID
		local dwMountKungfuID = -1
		if dwID == UI_GetClientPlayerID() then
			dwMountKungfuID = UI_GetPlayerMountKungfuID()
		else
			local info = GetClientTeam().GetMemberInfo(dwID)
			if info and not IsEmpty(info.dwMountKungfuID) then
				dwMountKungfuID = info.dwMountKungfuID
			else
				local kungfu = player.GetKungfuMount()
				if kungfu then
					dwMountKungfuID = kungfu.dwSkillID
				end
			end
		end
		local aEquip, nEquipScore = {}, player.GetTotalEquipScore()
		for nEquipIndex, tEquipInfo in pairs(LIB.GetPlayerEquipInfo(player)) do
			insert(aEquip, {
				nEquipIndex,
				tEquipInfo.dwTabType,
				tEquipInfo.dwTabIndex,
				tEquipInfo.nStrengthLevel,
				tEquipInfo.aSlotItem,
				tEquipInfo.dwPermanentEnchantID,
				tEquipInfo.dwTemporaryEnchantID,
				tEquipInfo.dwTemporaryEnchantLeftSeconds,
			})
		end
		local szGUID = LIB.GetPlayerGUID(dwID) or ''
		local aTalent = LIB.GetPlayerTalentInfo(player)
		if aTalent then
			for i, p in ipairs(aTalent) do
				aTalent[i] = {
					p.nIndex,
					p.dwSkillID,
					p.dwSkillLevel,
				}
			end
		end
		D.InsertLog(LOG_TYPE.PLAYER_INFO, { dwID, szName, dwForceID, dwMountKungfuID, nEquipScore, aEquip, aTalent, szGUID })
	else
		local npc = GetNpc(dwID)
		if not npc then
			return
		end
		local szName = LIB.GetObjectName(npc, 'never') or ''
		LOG_NAMING_COUNT[dwID].szName = szName
		D.InsertLog(LOG_TYPE.NPC_INFO, { dwID, szName, npc.dwTemplateID, npc.dwEmployer, npc.nX, npc.nY, npc.nZ })
	end
	LOG_TARGET_INFO_TIME[dwID] = GetTime()
end

-- 保存交互物件信息
function D.OnDoodadUpdate(dwID, bForce)
	if not bForce and LOG_DOODAD_INFO_TIME[dwID] and LOG_DOODAD_INFO_TIME[dwID] - GetTime() < LOG_DOODAD_INFO_TIME_LIMIT then
		return
	end
	local doodad = GetDoodad(dwID)
	if not doodad then
		return
	end
	D.InsertLog(LOG_TYPE.DOODAD_INFO, { dwID, doodad.dwTemplateID, doodad.nX, doodad.nY, doodad.nZ })
	LOG_DOODAD_INFO_TIME[dwID] = GetTime()
end

-- 系统日志监控（数据源）
LIB.RegisterEvent('SYS_MSG', function()
	if not LOG_ENABLE then
		return
	end
	if arg0 == 'UI_OME_SKILL_CAST_LOG' then
		-- 技能施放日志；
		-- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID (arg3)dwLevel：技能等级
		-- D.OnSkillCast(arg1, arg2, arg3)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_CAST_LOG, { arg1, arg2, arg3 })
		end
	elseif arg0 == 'UI_OME_SKILL_CAST_RESPOND_LOG' then
		-- 技能施放结果日志；
		-- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID
		-- (arg3)dwLevel：技能等级 (arg4)nRespond：见枚举型[[SKILL_RESULT_CODE]]
		-- D.OnSkillCastRespond(arg1, arg2, arg3, arg4)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_CAST_RESPOND_LOG, { arg1, arg2, arg3, arg4 })
		end
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		-- if not LIB.IsInArena() then
		-- 技能最终产生的效果（生命值的变化）；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID
		-- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResultCount：数值集合
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_EFFECT_LOG, { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 })
		end
	elseif arg0 == 'UI_OME_SKILL_BLOCK_LOG' then
		-- 格挡日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)nType：Effect的类型
		-- (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级 (arg6)nDamageType：伤害类型，见枚举型[[SKILL_RESULT_TYPE]]
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_BLOCK_LOG, { arg1, arg2, arg3, arg4, arg5, arg6 })
		end
	elseif arg0 == 'UI_OME_SKILL_SHIELD_LOG' then
		-- 技能被屏蔽日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_SHIELD_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_MISS_LOG' then
		-- 技能未命中目标日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_MISS_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		-- 技能命中目标日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_HIT_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_DODGE_LOG' then
		-- 技能被闪避日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_DODGE_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_COMMON_HEALTH_LOG' then
		-- 普通治疗日志；
		-- (arg1)dwCharacterID：承疗玩家ID (arg2)nDeltaLife：增加血量值
		-- D.OnCommonHealth(arg1, arg2)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_COMMON_HEALTH_LOG, { arg1, arg2 })
		end
	elseif arg0 == 'UI_OME_DEATH_NOTIFY' then
		-- 死亡日志；
		-- (arg1)dwCharacterID：死亡目标ID (arg2)dwKiller：击杀者ID
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_DEATH_NOTIFY, { arg1, arg2 })
		end
	end
end)

-- 系统BUFF监控（数据源）
LIB.RegisterEvent('BUFF_UPDATE', function()
	-- local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
	--     = arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11
	if not LOG_ENABLE then
		return
	end
	-- buff update：
	-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
	-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
	-- arg8：nLevel，arg9：dwSkillSrcID
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.BUFF_UPDATE, { arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 })
	end
end)

LIB.RegisterEvent('PLAYER_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_ENTER_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_LEAVE_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('NPC_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_ENTER_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('NPC_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_LEAVE_SCENE, { arg0 })
	end
end)

LIB.RegisterEvent('DOODAD_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_ENTER_SCENE, { arg0 })
end)

LIB.RegisterEvent('DOODAD_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_LEAVE_SCENE, { arg0 })
end)

-- 系统消息日志
LIB.RegisterMsgMonitor('MSG_SYS.MY_Recount_DS_Everything', function(szChannel, szMsg, nFont, bRich)
	if not LOG_ENABLE then
		return
	end
	local szText = szMsg
	if bRich then
		if LIB.ContainsEchoMsgHeader(szMsg) then
			return
		end
		szText = LIB.GetPureText(szMsg)
	end
	szText = szText:gsub('\r', '')
	D.InsertLog(LOG_TYPE.MSG_SYS, { szText, szChannel })
end)

-- 角色喊话日志
LIB.RegisterEvent('PLAYER_SAY', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szContent, arg1: dwTalkerID, arg2: nChannel, arg3: szName, arg4: bOnlyShowBallon
	-- arg5: bSecurity, arg6: bGMAccount, arg7: bCheater, arg8: dwTitleID, arg9: szMsg
	if not IsPlayer(arg1) and D.WillRecID(arg1) then
		local szText = LIB.GetPureText(arg0)
		if szText and szText ~= '' then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.PLAYER_SAY, { szText, arg1, arg2, arg3 })
		end
	end
end)

-- 系统警告框日志
LIB.RegisterEvent('ON_WARNING_MESSAGE', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szWarningType, arg1: szText
	D.InsertLog(LOG_TYPE.ON_WARNING_MESSAGE, { arg0, arg1 })
end)

-- 玩家进入退出战斗日志
LIB.RegisterEvent('MY_PLAYER_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = LIB.GetObject(TARGET.PLAYER, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = LIB.GetObjectLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.PLAYER_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- NPC 进入退出战斗日志
LIB.RegisterEvent('MY_NPC_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = LIB.GetObject(TARGET.NPC, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = LIB.GetObjectLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.NPC_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- 上线下线日志
LIB.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nOnlineFlag
	if not D.WillRecID(arg1) then
		return
	end
	D.OnTargetUpdate(arg1)
	D.InsertLog(LOG_TYPE.PARTY_SET_MEMBER_ONLINE_FLAG, { arg0, arg1, arg2 })
end)

-- 进出战斗暂离记录
LIB.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- 开战扫描队友 记录开战就死掉/掉线的人
	if not LOG_ENABLE then
		return
	end
	local team = GetClientTeam()
	local me = GetClientPlayer()
	if not team or not me or (not me.IsInParty() and not me.IsInRaid()) then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		local info = team.GetMemberInfo(dwID)
		if info and D.WillRecID(dwID) then
			D.OnTargetUpdate(dwID)
			if not info.bIsOnLine then
				D.InsertLog(LOG_TYPE.PARTY_SET_MEMBER_ONLINE_FLAG, { team.dwTeamID, dwID, 0 })
			elseif info.bDeathFlag then
				D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_DEATH_NOTIFY, { dwID, nil })
			end
		end
	end
end)

-- 中途有人进队 补上暂离记录
LIB.RegisterEvent('PARTY_ADD_MEMBER', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nGroupIndex
	if D.WillRecID(arg1) then
		D.OnTargetUpdate(arg1)
		D.InsertLog(LOG_TYPE.PARTY_ADD_MEMBER, { arg0, arg1, arg2 })
	end
end)

LIB.RegisterUserSettingsUpdate('@@INIT@@.MY_CombatLogs', function()
	D.bReady = true
	D.UpdateEnable()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['MY_CombatLogs'],
		checked = MY_CombatLogs.bEnable,
		oncheck = function(bChecked)
			MY_CombatLogs.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 25, h = 25,
		buttonstyle = 'OPTION',
		autoenable = function() return MY_CombatLogs.bEnable end,
		menu = function()
			local menu = {}
			insert(menu, {
				szOption = _L['Only in dungeon'],
				bCheck = true,
				bChecked = MY_CombatLogs.bOnlyDungeon,
				fnAction = function()
					MY_CombatLogs.bOnlyDungeon = not MY_CombatLogs.bOnlyDungeon
				end,
			})
			insert(menu, {
				szOption = _L['Only self related'],
				bCheck = true,
				bChecked = MY_CombatLogs.bOnlySelf,
				fnAction = function()
					MY_CombatLogs.bOnlySelf = not MY_CombatLogs.bOnlySelf
				end,
			})
			local m0 = { szOption = _L['Max history'] }
			for _, i in ipairs({10, 20, 30, 50, 100, 200, 300, 500, 1000, 2000, 5000}) do
				insert(m0, {
					szOption = tostring(i),
					fnAction = function()
						MY_CombatLogs.nMaxHistory = i
					end,
					bCheck = true,
					bMCheck = true,
					bChecked = MY_CombatLogs.nMaxHistory == i,
				})
			end
			insert(menu, m0)
			local m0 = { szOption = _L['Min fight time'] }
			for _, i in ipairs({10, 20, 30, 60, 90, 120, 180, 240}) do
				insert(m0, {
					szOption = _L('%s second(s)', i),
					fnAction = function()
						MY_CombatLogs.nMinFightTime = i
					end,
					bCheck = true,
					bMCheck = true,
					bChecked = MY_CombatLogs.nMinFightTime == i,
				})
			end
			insert(menu, m0)
			insert(menu, {
				szOption = _L['Show data files'],
				fnAction = function()
					local szRoot = LIB.GetAbsolutePath(DS_ROOT)
					LIB.OpenFolder(szRoot)
					UI.OpenTextEditor(szRoot)
				end,
			})
			return menu
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + LH
	return nX, nY, nLFY
end


-- Global exports
do
local settings = {
	name = 'MY_CombatLogs',
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
				'nMaxHistory',
				'nMinFightTime',
				'bOnlyDungeon',
				'bOnlySelf',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'nMaxHistory',
				'nMinFightTime',
				'bOnlyDungeon',
				'bOnlySelf',
			},
			triggers = {
				bEnable      = D.UpdateEnable,
				bOnlyDungeon = D.UpdateEnable,
				bOnlySelf    = D.UpdateEnable,
			},
			root = O,
		},
	},
}
MY_CombatLogs = LIB.CreateModule(settings)
end
