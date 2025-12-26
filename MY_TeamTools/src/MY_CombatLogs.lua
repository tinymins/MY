--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 战斗日志 流式保存原始事件数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_CombatLogs'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_CombatLogs.BanHDD', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_CombatLogs', _L['Raid'], {
	bEnable = { -- 数据记录总开关
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nMaxHistory = { -- 最大历史数据数量
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Max history'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 300,
	},
	nMinFightTime = { -- 最小战斗时间
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Min fight time'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 30,
	},
	bEnableInDungeon = { -- 在秘境中启用
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Enable in dungeon'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableInArena = { -- 在名剑大会中启用
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Enable in arena'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bEnableInBattleField = { -- 在战场中启用
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Enable in battlefield'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableInOtherMaps = { -- 在其他类型地图中启用
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Enable in other maps'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bNearbyAll = { -- 保存附近所有角色事件记录
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Save all nearby records'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTargetInformation = { -- 保存角色状态数据
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['PVP mode'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nTargetInformationThrottle = { -- 保存角色状态数据节流时间间隔
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_CombatLogs'],
			_L['Target Information Throttle Time'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 200,
	},
})
local D = {}
local DS_ROOT = {'userdata/combat_logs/', X.PATH_TYPE.ROLE}

local LOG_ENABLE = false -- 计算出来的总开关，按条件随时重算
local LOG_TARGET_INFORMATION_ENABLE = false -- 计算出来的目标状态记录开关，按条件随时重算
local LOG_TARGET_INFORMATION_THROTTLE = 0 -- 计算出来的目标状态记录限流，按条件随时重算
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
local LOG_TARGET_LOCATION_TIME = {} -- 记录角色坐标节流器数据

local LOG_REPLAY = {} -- 最近的数据 （进战时候将最近的数据压进来）
local LOG_REPLAY_FRAME = X.ENVIRONMENT.GAME_FPS * 1 -- 进战时候将多久的数据压进来（逻辑帧）

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
	TARGET_INFORMATION                    = 29, -- 目标状态信息
}

-- 更新启用状态
function D.UpdateEnable()
	local bEnable = D.bReady and O.bEnable
	if X.IsRestricted('MY_CombatLogs.BanHDD') and X.GetDiskType() == 'HDD' then
		bEnable = false
	end
	if bEnable then
		if X.IsInDungeonMap() then
			bEnable = O.bEnableInDungeon
		elseif X.IsInArenaMap() then
			bEnable = O.bEnableInArena
		elseif X.IsInBattlefieldMap() then
			bEnable = O.bEnableInBattleField
		else
			bEnable = O.bEnableInOtherMaps
		end
	end
	if not bEnable and LOG_ENABLE then
		D.CloseCombatLogs()
	elseif bEnable and not LOG_ENABLE and X.IsFighting() then
		D.OpenCombatLogs()
	end
	LOG_ENABLE = bEnable
	LOG_TARGET_INFORMATION_ENABLE = false
	if bEnable and O.bTargetInformation and X.IsInArenaMap() then
		LOG_TARGET_INFORMATION_ENABLE = true
	end
	LOG_TARGET_INFORMATION_THROTTLE = O.nTargetInformationThrottle
end
X.RegisterEvent('LOADING_ENDING', D.UpdateEnable)

-- 加载历史数据列表
function D.GetHistoryFiles()
	local aFiles = {}
	local szRoot = X.FormatPath(DS_ROOT)
	for _, v in ipairs(CPath.GetFileList(szRoot)) do
		if v:find('.jcl.tsv$') then
			table.insert(aFiles, v)
		end
	end
	table.sort(aFiles, function(a, b) return a > b end)
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
	local szRoot = X.FormatPath(DS_ROOT)
	CPath.MakeDir(szRoot)
	local szTime = X.FormatTime(GetCurrentTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
	local szMapName = ''
	local me = X.GetClientPlayer()
	if me then
		local map = X.GetMapInfo(me.GetMapID())
		if map then
			szMapName = '-' .. map.szName
		end
		szMapName = szMapName .. '(' .. me.GetMapID().. ')'
	end
	LOG_FILE = szRoot .. szTime .. szMapName .. '.jcl.log'
	LOG_TIME = GetCurrentTime()
	LOG_CACHE = {}
	LOG_TARGET_INFO_TIME = {}
	LOG_DOODAD_INFO_TIME = {}
	LOG_TARGET_LOCATION_TIME = {}
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
				szName = '-' .. p.szName .. '(' .. p.dwTemplateID .. ')'
			end
		end
		CPath.Move(LOG_FILE, X.StringSubW(LOG_FILE, 1, -9) .. szName .. '.jcl')
	end
	LOG_FILE = nil
end
X.RegisterReload('MY_CombatLogs', D.CloseCombatLogs)

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
		.. '\t' .. X.StringReplaceW(X.StringReplaceW(X.EncodeLUAData(oData), '\\\n', '\\n'), '\t', '\\t')
	local nCRC = GetStringCRC(LOG_CRC .. szLog .. X.SECRET['HASH::MY_COMBAT_JCL'])
	-- 插入缓存
	table.insert(LOG_CACHE, nCRC .. '\t' .. szLog .. '\n')
	-- 插入最近事件表
	if bReplay ~= false then
		while LOG_REPLAY[1] and nLFC - LOG_REPLAY[1].nLFC > LOG_REPLAY_FRAME do
			table.remove(LOG_REPLAY, 1)
		end
		table.insert(LOG_REPLAY, { nLFC = nLFC, szLog = szLog })
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
			nCRC = GetStringCRC(nCRC .. v.szLog .. X.SECRET['HASH::MY_COMBAT_JCL'])
			table.insert(LOG_CACHE, nCRC .. '\t' .. v.szLog .. '\n')
		end
	end
	-- 更新流式校验码
	LOG_CRC = nCRC
	-- 检查数据存盘
	D.FlushLogs()
end

-- 过图清除当前战斗数据
X.RegisterEvent({ 'LOADING_ENDING', 'RELOAD_UI_ADDON_END', 'BATTLE_FIELD_END', 'ARENA_END', 'MY_CLIENT_PLAYER_LEAVE_SCENE' }, function()
	D.FlushLogs(true)
end)

-- 退出战斗 保存数据
X.RegisterEvent('MY_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local bFighting, szUUID, nDuring = arg0, arg1, arg2
	local dwMapID = X.GetMapID()
	if not bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring, dwMapID })
	end
	if bFighting then -- 进入新的战斗
		D.OpenCombatLogs()
		D.ImportRecentLogs()
	else
		D.CloseCombatLogs()
	end
	if bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring, dwMapID })
	end
end)

function D.WillRecID(dwID)
	if not D.bReady then
		return false
	end
	if not O.bNearbyAll then
		if not X.IsPlayer(dwID) then
			local npc = X.GetNpc(dwID)
			if npc then
				dwID = npc.dwEmployer
			end
		end
		return dwID == X.GetClientPlayerID()
	end
	return true
end

-- 保存目标信息
function D.OnTargetUpdate(dwID, bForce)
	if not X.IsNumber(dwID) then
		return
	end
	local bIsPlayer = X.IsPlayer(dwID)
	if bIsPlayer and not X.IsTeammate(dwID) and not X.IsInArenaMap() and not X.IsInBattlefieldMap() then
		return
	end
	if not bIsPlayer then
		if not LOG_NAMING_COUNT[dwID] then
			LOG_NAMING_COUNT[dwID] = {
				nCount = 0,
				szName = '',
				dwTemplateID = 0,
			}
		end
		LOG_NAMING_COUNT[dwID].nCount = LOG_NAMING_COUNT[dwID].nCount + 1
	end
	if not bForce and LOG_TARGET_INFO_TIME[dwID] and GetTime() - LOG_TARGET_INFO_TIME[dwID] < LOG_TARGET_INFO_TIME_LIMIT then
		D.OnTargetInformationUpdate(bIsPlayer and TARGET.PLAYER or TARGET.NPC, dwID)
		return
	end
	if bIsPlayer then
		local player = X.GetPlayer(dwID)
		if not player then
			return
		end
		local szName = player.szName
		local dwForceID = player.dwForceID
		local dwMountKungfuID = -1
		if dwID == X.GetClientPlayerID() then
			dwMountKungfuID = UI_GetPlayerMountKungfuID()
		else
			local info = X.GetTeamMemberInfo(dwID)
			if info and not X.IsEmpty(info.dwActualMountKungfuID) then
				dwMountKungfuID = info.dwActualMountKungfuID
			else
				local kungfu = player.GetKungfuMount()
				if kungfu then
					dwMountKungfuID = kungfu.dwSkillID
				end
			end
		end
		local szGUID = X.GetPlayerGlobalID(dwID) or ''
		local aEquip, nEquipScore, aTalent, tZhenPai
		local function OnGet()
			D.InsertLog(LOG_TYPE.PLAYER_INFO, { dwID, szName, dwForceID, dwMountKungfuID, nEquipScore, aEquip, aTalent, szGUID, tZhenPai })
		end
		X.GetPlayerEquipScore(dwID, function(nScore)
			nEquipScore = nScore
			OnGet()
		end)
		X.GetPlayerEquipInfo(dwID, function(tEquip)
			aEquip = {}
			for nEquipIndex, tEquipInfo in pairs(tEquip) do
				table.insert(aEquip, {
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
			OnGet()
		end)
		X.GetPlayerTalentInfo(dwID, function(a)
			aTalent = {}
			for i, p in ipairs(a) do
				aTalent[i] = {
					p.nIndex,
					p.dwSkillID,
					p.dwSkillLevel,
				}
			end
			OnGet()
		end)
		X.GetPlayerZhenPaiInfo(dwID, function(a)
			tZhenPai = {}
			for k, p in pairs(a) do
				if p ~= 0 then
					tZhenPai[k] = p
				end
			end
			OnGet()
		end)
		D.OnTargetInformationUpdate(TARGET.PLAYER, dwID)
	else
		local npc = X.GetNpc(dwID)
		if not npc then
			return
		end
		local szName = X.GetNpcName(dwID, { eShowID = 'never' }) or ''
		LOG_NAMING_COUNT[dwID].szName = szName
		LOG_NAMING_COUNT[dwID].dwTemplateID = npc.dwTemplateID
		D.InsertLog(LOG_TYPE.NPC_INFO, { dwID, szName, npc.dwTemplateID, npc.dwEmployer, npc.nX, npc.nY, npc.nZ, npc.nFaceDirection })
	end
	LOG_TARGET_INFO_TIME[dwID] = GetTime()
end

-- 保存交互物件信息
function D.OnDoodadUpdate(dwID, bForce)
	if not bForce and LOG_DOODAD_INFO_TIME[dwID] and GetTime() - LOG_DOODAD_INFO_TIME[dwID] < LOG_DOODAD_INFO_TIME_LIMIT then
		return
	end
	local doodad = X.GetDoodad(dwID)
	if not doodad then
		return
	end
	D.InsertLog(LOG_TYPE.DOODAD_INFO, { dwID, doodad.dwTemplateID, doodad.nX, doodad.nY, doodad.nZ, doodad.nFaceDirection })
	LOG_DOODAD_INFO_TIME[dwID] = GetTime()
end

function D.OnTargetInformationUpdate(dwType, dwID)
	if not LOG_TARGET_INFORMATION_ENABLE then
		return
	end
	if LOG_TARGET_LOCATION_TIME[dwID] and GetTime() - LOG_TARGET_LOCATION_TIME[dwID] < LOG_TARGET_INFORMATION_THROTTLE then
		return
	end
	local tar
	if dwType == TARGET.PLAYER then
		tar = X.GetPlayer(dwID)
	elseif dwType == TARGET.NPC then
		tar = X.GetNpc(dwID)
	elseif dwType == TARGET.DOODAD then
		tar = X.GetDoodad(dwID)
	end
	if tar then
		local nLife, nMaxLife = X.GetCharacterLife(tar)
		local nMana, nMaxMana = X.GetCharacterMana(tar)
		local nDamageAbsorbValue = tar.nDamageAbsorbValue
		D.InsertLog(LOG_TYPE.TARGET_INFORMATION, {
			dwType, dwID,
			tar.nX, tar.nY, tar.nZ, tar.nFaceDirection,
			nLife, nMaxLife, nMana, nMaxMana, nDamageAbsorbValue,
		})
	end
	LOG_TARGET_LOCATION_TIME[dwID] = GetTime() -- 忽略 doodad 与 player 的 id 冲突，为了性能，一般也不会冲突
end

-- 系统日志监控（数据源）
X.RegisterEvent('SYS_MSG', function()
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
		-- if not X.IsInArenaMap() then
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
X.RegisterEvent('BUFF_UPDATE', function()
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

X.RegisterEvent('PLAYER_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_ENTER_SCENE, { arg0 })
	end
end)

X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_LEAVE_SCENE, { arg0 })
	end
end)

X.RegisterEvent('NPC_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_ENTER_SCENE, { arg0 })
	end
end)

X.RegisterEvent('NPC_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_LEAVE_SCENE, { arg0 })
	end
end)

X.RegisterEvent('DOODAD_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_ENTER_SCENE, { arg0 })
end)

X.RegisterEvent('DOODAD_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_LEAVE_SCENE, { arg0 })
end)

-- 系统消息日志
X.RegisterMsgMonitor('MSG_SYS', 'MY_CombatLogs', function(szChannel, szMsg, nFont, bRich)
	if not LOG_ENABLE then
		return
	end
	local szText = szMsg
	if bRich then
		if X.ContainsEchoMsgHeader(szMsg) then
			return
		end
		szText = X.GetPureText(szMsg)
	end
	szText = szText:gsub('\r', '')
	D.InsertLog(LOG_TYPE.MSG_SYS, { szText, szChannel })
end)

-- 角色喊话日志
X.RegisterEvent('PLAYER_SAY', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szContent, arg1: dwTalkerID, arg2: nChannel, arg3: szName, arg4: bOnlyShowBallon
	-- arg5: bSecurity, arg6: bGMAccount, arg7: bCheater, arg8: dwTitleID, arg9: szMsg
	if not X.IsPlayer(arg1) and D.WillRecID(arg1) then
		local szText = X.GetPureText(arg0)
		if szText and szText ~= '' then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.PLAYER_SAY, { szText, arg1, arg2, arg3 })
		end
	end
end)

-- 系统警告框日志
X.RegisterEvent('ON_WARNING_MESSAGE', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szWarningType, arg1: szText
	D.InsertLog(LOG_TYPE.ON_WARNING_MESSAGE, { arg0, arg1 })
end)

-- 玩家进入退出战斗日志
X.RegisterEvent('MY_PLAYER_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = X.GetTargetHandle(TARGET.PLAYER, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = X.GetCharacterLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.PLAYER_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- NPC 进入退出战斗日志
X.RegisterEvent('MY_NPC_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = X.GetTargetHandle(TARGET.NPC, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = X.GetCharacterLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.NPC_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- 上线下线日志
X.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', function()
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
X.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- 开战扫描队友 记录开战就死掉/掉线的人
	if not LOG_ENABLE then
		return
	end
	local team = GetClientTeam()
	local me = X.GetClientPlayer()
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
X.RegisterEvent('PARTY_ADD_MEMBER', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nGroupIndex
	if D.WillRecID(arg1) then
		D.OnTargetUpdate(arg1)
		D.InsertLog(LOG_TYPE.PARTY_ADD_MEMBER, { arg0, arg1, arg2 })
	end
end)

function D.GetOptionsMenu()
	local bBan = X.IsRestricted('MY_CombatLogs.BanHDD') and X.GetDiskType() == 'HDD'
	local fnMouseEnter = bBan
		and function()
			local nX, nY = this:GetAbsX(), this:GetAbsY()
			local nW, nH = this:GetW(), this:GetH()
			OutputTip(GetFormatText(_L['This feature has been disabled on HDD disk machine for performance issues.'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
		end
		or nil
	local fnMouseLeave = bBan
		and function()
			HideTip()
		end
		or nil
	local menu = {
		szOption = _L['MY_CombatLogs'],
		bCheck = true,
		bChecked = not bBan and MY_CombatLogs.bEnable,
		fnAction = function()
			MY_CombatLogs.bEnable = not MY_CombatLogs.bEnable
		end,
		fnMouseEnter = fnMouseEnter,
		fnMouseLeave = fnMouseLeave,
		fnDisable = function() return bBan end,
	}
	table.insert(menu, {
		szOption = _L['Enable in dungeon'],
		bCheck = true,
		bChecked = MY_CombatLogs.bEnableInDungeon,
		fnAction = function()
			MY_CombatLogs.bEnableInDungeon = not MY_CombatLogs.bEnableInDungeon
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	table.insert(menu, {
		szOption = _L['Enable in arena'],
		bCheck = true,
		bChecked = MY_CombatLogs.bEnableInArena,
		fnAction = function()
			MY_CombatLogs.bEnableInArena = not MY_CombatLogs.bEnableInArena
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	table.insert(menu, {
		szOption = _L['Enable in battlefield'],
		bCheck = true,
		bChecked = MY_CombatLogs.bEnableInBattleField,
		fnAction = function()
			MY_CombatLogs.bEnableInBattleField = not MY_CombatLogs.bEnableInBattleField
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	table.insert(menu, {
		szOption = _L['Enable in other maps'],
		bCheck = true,
		bChecked = MY_CombatLogs.bEnableInOtherMaps,
		fnAction = function()
			MY_CombatLogs.bEnableInOtherMaps = not MY_CombatLogs.bEnableInOtherMaps
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	table.insert(menu, X.CONSTANT.MENU_DIVIDER)
	table.insert(menu, {
		szOption = _L['Save all nearby records'],
		bCheck = true,
		bChecked = MY_CombatLogs.bNearbyAll,
		fnAction = function()
			MY_CombatLogs.bNearbyAll = not MY_CombatLogs.bNearbyAll
		end,
		fnMouseEnter = function()
			local nX, nY = this:GetAbsX(), this:GetAbsY()
			local nW, nH = this:GetW(), this:GetH()
			OutputTip(GetFormatText(_L['Check to save all nearby records, otherwise only save records related to me'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.TOP_BOTTOM)
		end,
		fnMouseLeave = function()
			HideTip()
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	table.insert(menu, {
		szOption = _L['PVP mode'],
		bCheck = true,
		bChecked = MY_CombatLogs.bTargetInformation,
		fnAction = function()
			MY_CombatLogs.bTargetInformation = not MY_CombatLogs.bTargetInformation
		end,
		fnMouseEnter = function()
			local nX, nY = this:GetAbsX(), this:GetAbsY()
			local nW, nH = this:GetW(), this:GetH()
			OutputTip(GetFormatText(_L['Save target information on event\n(Only in arena)'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.TOP_BOTTOM)
		end,
		fnMouseLeave = function()
			HideTip()
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	table.insert(menu, X.CONSTANT.MENU_DIVIDER)
	local m0 = {
		szOption = _L['Max history'],
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	}
	for _, i in ipairs({10, 20, 30, 50, 100, 200, 300, 500, 1000, 2000, 5000}) do
		table.insert(m0, {
			szOption = tostring(i),
			fnAction = function()
				MY_CombatLogs.nMaxHistory = i
			end,
			bCheck = true,
			bMCheck = true,
			bChecked = MY_CombatLogs.nMaxHistory == i,
		})
	end
	table.insert(menu, m0)
	local m0 = {
		szOption = _L['Min fight time'],
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	}
	for _, i in ipairs({10, 20, 30, 60, 90, 120, 180, 240}) do
		table.insert(m0, {
			szOption = _L('%s second(s)', i),
			fnAction = function()
				MY_CombatLogs.nMinFightTime = i
			end,
			bCheck = true,
			bMCheck = true,
			bChecked = MY_CombatLogs.nMinFightTime == i,
		})
	end
	table.insert(menu, m0)
	table.insert(menu, {
		szOption = _L['Show data files'],
		fnAction = function()
			local szRoot = X.GetAbsolutePath(DS_ROOT)
			X.OpenFolder(szRoot)
			X.UI.OpenTextEditor(szRoot)
		end,
		fnDisable = function() return bBan or not MY_CombatLogs.bEnable end,
	})
	return menu
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	local bBan = X.IsRestricted('MY_CombatLogs.BanHDD') and X.GetDiskType() == 'HDD'

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['MY_CombatLogs'],
		checked = not bBan and MY_CombatLogs.bEnable,
		enable = not bBan,
		tip = bBan and {
			render = _L['This feature has been disabled on HDD disk machine for performance issues.'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		} or nil,
		onCheck = function(bChecked)
			MY_CombatLogs.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 25, h = 25,
		buttonStyle = 'OPTION',
		autoEnable = function() return MY_CombatLogs.bEnable end,
		menu = D.GetOptionsMenu,
	}):Width() + 5

	nLFY = nY + nLH
	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_CombatLogs',
	exports = {
		{
			fields = {
				'GetOptionsMenu',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'nMaxHistory',
				'nMinFightTime',
				'bEnableInDungeon',
				'bEnableInArena',
				'bEnableInBattleField',
				'bEnableInOtherMaps',
				'bNearbyAll',
				'bTargetInformation',
				'nTargetInformationThrottle',
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
				'bEnableInDungeon',
				'bEnableInArena',
				'bEnableInBattleField',
				'bEnableInOtherMaps',
				'bNearbyAll',
				'bTargetInformation',
				'nTargetInformationThrottle',
			},
			triggers = {
				bEnable                    = D.UpdateEnable,
				bEnableInDungeon           = D.UpdateEnable,
				bEnableInArena             = D.UpdateEnable,
				bEnableInBattleField       = D.UpdateEnable,
				bEnableInOtherMaps         = D.UpdateEnable,
				bNearbyAll                 = D.UpdateEnable,
				bTargetInformation         = D.UpdateEnable,
				nTargetInformationThrottle = D.UpdateEnable,
			},
			root = O,
		},
	},
}
MY_CombatLogs = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_CombatLogs', function()
	D.bReady = true
	D.UpdateEnable()
end)

X.RegisterUserSettingsRelease('MY_CombatLogs', function()
	D.bReady = false
end)

X.RegisterEvent('MY_RESTRICTION', 'MY_CombatLogs.BanHDD', function()
	if arg0 and arg0 ~= 'MY_CombatLogs.BanHDD' then
		return
	end
	D.UpdateEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
