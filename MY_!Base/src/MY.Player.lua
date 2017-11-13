--------------------------------------------
-- @Desc  : 茗伊插件
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-30 10:47:43
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
--------------------------------------------
-- 本地函数和变量
--------------------------------------------
MY = MY or {}
MY.Player = MY.Player or {}
local _C, _L = {}, MY.LoadLangPack()

-------------------------------------------------------------------------------------------------------
--               #     #       #             # #                         #             #             --
--   # # # #     #     #         #     # # #         # # # # # #         #             #             --
--   #     #   #       #               #                 #         #     #     # # # # # # # # #     --
--   #     #   #   # # # #             #                 #         #     #             #             --
--   #   #   # #       #     # # #     # # # # # #       # # # #   #     #       # # # # # # #       --
--   #   #     #       #         #     #     #         #       #   #     #             #             --
--   #     #   #   #   #         #     #     #       #   #     #   #     #   # # # # # # # # # # #   --
--   #     #   #     # #         #     #     #             #   #   #     #           #   #           --
--   #     #   #       #         #     #     #               #     #     #         #     #       #   --
--   # # #     #       #         #   #       #             #             #       # #       #   #     --
--   #         #       #       #   #                     #               #   # #   #   #     #       --
--   #         #     # #     #       # # # # # # #     #             # # #         # #         # #   --
-------------------------------------------------------------------------------------------------------
_C.tNearNpc = {}      -- 附近的NPC
_C.tNearPlayer = {}   -- 附近的物品
_C.tNearDoodad = {}   -- 附近的玩家

-- 获取附近NPC列表
-- (table) MY.GetNearNpc(void)
function MY.Player.GetNearNpc(nLimit)
	local tNpc, i = {}, 0
	for dwID, _ in pairs(_C.tNearNpc) do
		local npc = GetNpc(dwID)
		if not npc then
			_C.tNearNpc[dwID] = nil
		else
			i = i + 1
			if npc.szName=="" then
				npc.szName = string.gsub(Table_GetNpcTemplateName(npc.dwTemplateID), "^%s*(.-)%s*$", "%1")
			end
			tNpc[dwID] = npc
			if nLimit and i == nLimit then break end
		end
	end
	return tNpc, i
end
MY.GetNearNpc = MY.Player.GetNearNpc

-- 获取附近玩家列表
-- (table) MY.GetNearPlayer(void)
function MY.Player.GetNearPlayer(nLimit)
	local tPlayer, i = {}, 0
	for dwID, _ in pairs(_C.tNearPlayer) do
		local player = GetPlayer(dwID)
		if not player then
			_C.tNearPlayer[dwID] = nil
		else
			i = i + 1
			tPlayer[dwID] = player
			if nLimit and i == nLimit then break end
		end
	end
	return tPlayer, i
end
MY.GetNearPlayer = MY.Player.GetNearPlayer

-- 获取附近物品列表
-- (table) MY.GetNearPlayer(void)
function MY.Player.GetNearDoodad(nLimit)
	local tDoodad, i = {}, 0
	for dwID, _ in pairs(_C.tNearDoodad) do
		local dooded = GetDoodad(dwID)
		if not dooded then
			_C.tNearDoodad[dwID] = nil
		else
			i = i + 1
			tDoodad[dwID] = dooded
			if nLimit and i == nLimit then break end
		end
	end
	return tDoodad, i
end
MY.GetNearDoodad = MY.Player.GetNearDoodad

RegisterEvent("NPC_ENTER_SCENE",    function() _C.tNearNpc[arg0]    = true end)
RegisterEvent("NPC_LEAVE_SCENE",    function() _C.tNearNpc[arg0]    = nil  end)
RegisterEvent("PLAYER_ENTER_SCENE", function() _C.tNearPlayer[arg0] = true end)
RegisterEvent("PLAYER_LEAVE_SCENE", function() _C.tNearPlayer[arg0] = nil  end)
RegisterEvent("DOODAD_ENTER_SCENE", function() _C.tNearDoodad[arg0] = true end)
RegisterEvent("DOODAD_LEAVE_SCENE", function() _C.tNearDoodad[arg0] = nil  end)

-- 获取玩家自身信息（缓存）
local m_ClientInfo
function MY.Player.GetClientInfo(bForceRefresh)
	if bForceRefresh or not (m_ClientInfo and m_ClientInfo.dwID) then
		local me = GetClientPlayer()
		if me then -- 确保获取到玩家
			if not m_ClientInfo then
				m_ClientInfo = {}
			end
			if not IsRemotePlayer(me.dwID) then -- 确保不在战场
				m_ClientInfo.dwID   = me.dwID
				m_ClientInfo.szName = me.szName
			end
			m_ClientInfo.nX                = me.nX
			m_ClientInfo.nY                = me.nY
			m_ClientInfo.nZ                = me.nZ
			m_ClientInfo.nFaceDirection    = me.nFaceDirection
			m_ClientInfo.szTitle           = me.szTitle
			m_ClientInfo.dwForceID         = me.dwForceID
			m_ClientInfo.nLevel            = me.nLevel
			m_ClientInfo.nExperience       = me.nExperience
			m_ClientInfo.nCurrentStamina   = me.nCurrentStamina
			m_ClientInfo.nCurrentThew      = me.nCurrentThew
			m_ClientInfo.nMaxStamina       = me.nMaxStamina
			m_ClientInfo.nMaxThew          = me.nMaxThew
			m_ClientInfo.nBattleFieldSide  = me.nBattleFieldSide
			m_ClientInfo.dwSchoolID        = me.dwSchoolID
			m_ClientInfo.nCurrentTrainValue= me.nCurrentTrainValue
			m_ClientInfo.nMaxTrainValue    = me.nMaxTrainValue
			m_ClientInfo.nUsedTrainValue   = me.nUsedTrainValue
			m_ClientInfo.nDirectionXY      = me.nDirectionXY
			m_ClientInfo.nCurrentLife      = me.nCurrentLife
			m_ClientInfo.nMaxLife          = me.nMaxLife
			m_ClientInfo.nMaxLifeBase      = me.nMaxLifeBase
			m_ClientInfo.nCurrentMana      = me.nCurrentMana
			m_ClientInfo.nMaxMana          = me.nMaxMana
			m_ClientInfo.nMaxManaBase      = me.nMaxManaBase
			m_ClientInfo.nCurrentEnergy    = me.nCurrentEnergy
			m_ClientInfo.nMaxEnergy        = me.nMaxEnergy
			m_ClientInfo.nEnergyReplenish  = me.nEnergyReplenish
			m_ClientInfo.bCanUseBigSword   = me.bCanUseBigSword
			m_ClientInfo.nAccumulateValue  = me.nAccumulateValue
			m_ClientInfo.nCamp             = me.nCamp
			m_ClientInfo.bCampFlag         = me.bCampFlag
			m_ClientInfo.bOnHorse          = me.bOnHorse
			m_ClientInfo.nMoveState        = me.nMoveState
			m_ClientInfo.dwTongID          = me.dwTongID
			m_ClientInfo.nGender           = me.nGender
			m_ClientInfo.nCurrentRage      = me.nCurrentRage
			m_ClientInfo.nMaxRage          = me.nMaxRage
			m_ClientInfo.nCurrentPrestige  = me.nCurrentPrestige
			m_ClientInfo.bFightState       = me.bFightState
			m_ClientInfo.nRunSpeed         = me.nRunSpeed
			m_ClientInfo.nRunSpeedBase     = me.nRunSpeedBase
			m_ClientInfo.dwTeamID          = me.dwTeamID
			m_ClientInfo.nRoleType         = me.nRoleType
			m_ClientInfo.nContribution     = me.nContribution
			m_ClientInfo.nCoin             = me.nCoin
			m_ClientInfo.nJustice          = me.nJustice
			m_ClientInfo.nExamPrint        = me.nExamPrint
			m_ClientInfo.nArenaAward       = me.nArenaAward
			m_ClientInfo.nActivityAward    = me.nActivityAward
			m_ClientInfo.bHideHat          = me.bHideHat
			m_ClientInfo.bRedName          = me.bRedName
			m_ClientInfo.dwKillCount       = me.dwKillCount
			m_ClientInfo.nRankPoint        = me.nRankPoint
			m_ClientInfo.nTitle            = me.nTitle
			m_ClientInfo.nTitlePoint       = me.nTitlePoint
			m_ClientInfo.dwPetID           = me.dwPetID
		end
	end

	return m_ClientInfo or {}
end
MY.GetClientInfo = MY.Player.GetClientInfo
MY.RegisterEvent('LOADING_ENDING', MY.Player.GetClientInfo)

-- 获取唯一标识符
local m_szUUID
function MY.Player.GetUUID()
	if not m_szUUID then
		local me = GetClientPlayer()
		if me.GetGlobalID and me.GetGlobalID() ~= "0" then
			m_szUUID = me.GetGlobalID()
		else
			m_szUUID = (MY.Game.GetRealServer()):gsub('[/\\|:%*%?"<>]', '') .. "_" .. MY.Player.GetClientInfo().dwID
		end
	end
	return m_szUUID
end

function _C.GeneFriendListCache()
	if not _C.tFriendListByGroup then
		local me = GetClientPlayer()
		if me then
			local infos = me.GetFellowshipGroupInfo()
			if infos then
				_C.tFriendListByID = {}
				_C.tFriendListByName = {}
				_C.tFriendListByGroup = {{ id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND or "" }} -- 默认分组
				for _, group in ipairs(infos) do
					table.insert(_C.tFriendListByGroup, group)
				end
				for _, group in ipairs(_C.tFriendListByGroup) do
					for _, p in ipairs(me.GetFellowshipInfo(group.id) or {}) do
						table.insert(group, p)
						_C.tFriendListByID[p.id] = p
						_C.tFriendListByName[p.name] = p
					end
				end
				return true
			end
		end
		return false
	end
	return true
end
function _C.OnFriendListChange()
	_C.tFriendListByID = nil
	_C.tFriendListByName = nil
	_C.tFriendListByGroup = nil
end
MY.RegisterEvent("PLAYER_FELLOWSHIP_UPDATE"     , _C.OnFriendListChange)
MY.RegisterEvent("PLAYER_FELLOWSHIP_CHANGE"     , _C.OnFriendListChange)
MY.RegisterEvent("PLAYER_FELLOWSHIP_LOGIN"      , _C.OnFriendListChange)
MY.RegisterEvent("PLAYER_FOE_UPDATE"            , _C.OnFriendListChange)
MY.RegisterEvent("PLAYER_BLACK_LIST_UPDATE"     , _C.OnFriendListChange)
MY.RegisterEvent("DELETE_FELLOWSHIP"            , _C.OnFriendListChange)
MY.RegisterEvent("FELLOWSHIP_TWOWAY_FLAG_CHANGE", _C.OnFriendListChange)
-- 获取好友列表
-- MY.Player.GetFriendList()         获取所有好友列表
-- MY.Player.GetFriendList(1)        获取第一个分组好友列表
-- MY.Player.GetFriendList("挽月堂") 获取分组名称为挽月堂的好友列表
function MY.Player.GetFriendList(arg0)
	local t = {}
	local tGroup = {}
	if _C.GeneFriendListCache() then
		if type(arg0) == "number" then
			table.insert(tGroup, _C.tFriendListByGroup[arg0])
		elseif type(arg0) == "string" then
			for _, group in ipairs(_C.tFriendListByGroup) do
				if group.name == arg0 then
					table.insert(tGroup, clone(group))
				end
			end
		else
			tGroup = _C.tFriendListByGroup
		end
		local n = 0
		for _, group in ipairs(tGroup) do
			for _, p in ipairs(group) do
				t[p.id], n = clone(p), n + 1
			end
		end
	end
	return t, n
end

-- 获取好友
function MY.Player.GetFriend(arg0)
	if arg0 and _C.GeneFriendListCache() then
		if type(arg0) == "number" then
			return clone(_C.tFriendListByID[arg0])
		elseif type(arg0) == "string" then
			return clone(_C.tFriendListByName[arg0])
		end
	end
end
MY.GetFriend = MY.Player.GetFriend

function _C.GeneFoeListCache()
	if not _C.tFoeList then
		local me = GetClientPlayer()
		if me then
			_C.tFoeList = {}
			_C.tFoeListByID = {}
			_C.tFoeListByName = {}
			if me.GetFoeInfo then
				local infos = me.GetFoeInfo()
				if infos then
					for i, p in ipairs(infos) do
						_C.tFoeListByID[p.id] = p
						_C.tFoeListByName[p.name] = p
						table.insert(_C.tFoeList, p)
					end
					return true
				end
			end
		end
		return false
	end
	return true
end
function _C.OnFoeListChange()
	_C.tFoeList = nil
	_C.tFoeListByID = nil
	_C.tFoeListByName = nil
end
MY.RegisterEvent("PLAYER_FOE_UPDATE", _C.OnFoeListChange)
-- 获取仇人列表
function MY.Player.GetFoeList()
	if _C.GeneFoeListCache() then
		return clone(_C.tFoeList)
	end
end
-- 获取仇人
function MY.Player.GetFoe(arg0)
	if arg0 and _C.GeneFoeListCache() then
		if type(arg0) == "number" then
			return _C.tFoeListByID[arg0]
		elseif type(arg0) == "string" then
			return _C.tFoeListByName[arg0]
		end
	end
end
MY.GetFoe = MY.Player.GetFoe

-- 获取好友列表
function MY.Player.GetTongMemberList(bShowOffLine, szSorter, bAsc)
	if bShowOffLine == nil then bShowOffLine = false  end
	if szSorter     == nil then szSorter     = 'name' end
	if bAsc         == nil then bAsc         = true   end
	local aSorter = {
		["name"  ] = "name"                    ,
		["level" ] = "group"                   ,
		["school"] = "development_contribution",
		["score" ] = "score"                   ,
		["map"   ] = "join_time"               ,
		["remark"] = "last_offline_time"       ,
	}
	szSorter = aSorter[szSorter]
	-- GetMemberList(bShowOffLine, szSorter, bAsc, nGroupFilter, -1) -- 后面两个参数不知道什么鬼
	return GetTongClient().GetMemberList(bShowOffLine, szSorter or 'name', bAsc, -1, -1)
end

function MY.GetTongName(dwTongID)
	local szTongName
	if not dwTongID then
		dwTongID = (GetClientPlayer() or EMPTY_TABLE).dwTongID
	end
	if dwTongID and dwTongID ~= 0 then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, 253)
	else
		szTongName = ""
	end
	return szTongName
end

-- 获取帮会成员
function MY.Player.GetTongMember(arg0)
	if not arg0 then
		return
	end

	return GetTongClient().GetMemberInfo(arg0)
end
MY.GetTongMember = MY.Player.GetTongMember

-- 判断是不是队友
function MY.Player.IsParty(dwID)
	return GetClientPlayer().IsPlayerInMyParty(dwID)
end
MY.IsParty = MY.Player.IsParty

-------------------------------------------------------------------------------------------------------
--       #         #   #                   #             #         #                   #             --
--       #         #     #         #       #             #         #   #               #             --
--       # # #     #                 #     #         #   #         #     #   # # # # # # # # # # #   --
--       #         # # # #             #   #           # #         #                 #   #           --
--       #     # # #           #           #             #   # # # # # # #         #       #         --
--   # # # # #     #   #         #         #             #         #             #     #     #       --
--   #       #     #   #           #       #             #       #   #       # #         #     # #   --
--   #       #     #   #                   # # # #     # #       #   #                 #             --
--   #       #       #       # # # # # # # #         #   #       #   #         #   #     #     #     --
--   # # # # #     # #   #                 #             #     #       #       #   #     #       #   --
--   #           #     # #                 #             #     #       #     #     #         #   #   --
--             #         #                 #             #   #           #           # # # # #       --
-------------------------------------------------------------------------------------------------------
_C.nLastFightUUID  = nil
_C.nFightUUID      = nil
_C.nFightBeginTick = -1
_C.nFightEndTick   = -1
function _C.OnFightStateChange()
	-- 判定战斗边界
	if MY.IsFighting() then
		-- 进入战斗判断
		if not _C.bFighting then
			_C.bFighting = true
			-- 5秒脱战判定缓冲 防止明教隐身错误判定
			if not _C.nFightUUID
			or GetTickCount() - _C.nFightEndTick > 5000 then
				-- 新的一轮战斗开始
				_C.nFightBeginTick = GetTickCount()
				_C.nFightUUID = _C.nFightBeginTick
				FireUIEvent('MY_FIGHT_HINT', true)
			end
		end
	else
		-- 退出战斗判定
		if _C.bFighting then
			_C.nFightEndTick, _C.bFighting = GetTickCount(), false
		elseif _C.nFightUUID and GetTickCount() - _C.nFightEndTick > 5000 then
			_C.nLastFightUUID, _C.nFightUUID = _C.nFightUUID, nil
			FireUIEvent('MY_FIGHT_HINT', false)
		end
	end
end
MY.BreatheCall(_C.OnFightStateChange)

-- 获取当前战斗时间
function MY.Player.GetFightTime(szFormat)
	local nTick = 0
	if MY.IsFighting() then -- 战斗状态
		nTick = GetTickCount() - _C.nFightBeginTick
	else  -- 脱战状态
		nTick = _C.nFightEndTick - _C.nFightBeginTick
	end

	if szFormat then
		local nSeconds = math.floor(nTick / 1000)
		local nMinutes = math.floor(nSeconds / 60)
		local nHours   = math.floor(nMinutes / 60)
		local nMinute  = nMinutes % 60
		local nSecond  = nSeconds % 60
		szFormat = szFormat:gsub('f', math.floor(nTick / 1000 * GLOBAL.GAME_FPS))
		szFormat = szFormat:gsub('H', nHours)
		szFormat = szFormat:gsub('M', nMinutes)
		szFormat = szFormat:gsub('S', nSeconds)
		szFormat = szFormat:gsub('hh', string.format('%02d', nHours ))
		szFormat = szFormat:gsub('mm', string.format('%02d', nMinute))
		szFormat = szFormat:gsub('ss', string.format('%02d', nSecond))
		szFormat = szFormat:gsub('h', nHours)
		szFormat = szFormat:gsub('m', nMinute)
		szFormat = szFormat:gsub('s', nSecond)

		if szFormat:sub(1, 1) ~= '0' and tonumber(szFormat) then
			szFormat = tonumber(szFormat)
		end
	else
		szFormat = nTick
	end
	return szFormat
end
MY.GetFightTime = MY.Player.GetFightTime

-- 获取当前战斗唯一标示符
function MY.Player.GetFightUUID()
	return _C.nFightUUID
end

-- 获取上次战斗唯一标示符
function MY.Player.GetLastFightUUID()
	return _C.nLastFightUUID
end

-- 获取自身是否处于逻辑战斗状态
-- (bool) MY.Player.IsFighting()
function MY.Player.IsFighting()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and MY.Player.IsInArena() and _C.bJJCStart then
		bFightState = true
	elseif not bFightState and MY.Player.IsInDungeon() then
		-- 在副本且附近队友进战且附近敌对NPC进战则判断处于战斗状态
		local bPlayerFighting, bNpcFighting
		for dwID, p in pairs(MY.Player.GetNearPlayer()) do
			if me.IsPlayerInMyParty(dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for dwID, p in pairs(MY.Player.GetNearNpc()) do
				if IsEnemy(me.dwID, dwID) and p.bFightState then
					bNpcFighting = true
					break
				end
			end
		end
		bFightState = bPlayerFighting and bNpcFighting
	end
	return bFightState
end
MY.IsFighting = MY.Player.IsFighting
MY.RegisterEvent("LOADING_ENDING.MY-PLAYER", function() _C.bJJCStart = nil end)
MY.RegisterEvent("ARENA_START.MY-PLAYER", function() _C.bJJCStart = true end)

-------------------------------------------------------------------------------------------------------------------
--                                   #                                                       #                   --
--   # # # # # # # # # # #         #                               # # # # # # # # #         #     # # # # #     --
--             #             # # # # # # # # # # #       #         #               #         #                   --
--           #               #                   #     #   #       #               #     # # # #                 --
--     # # # # # # # # # #   #                   #     #   #       # # # # # # # # #         #   # # # # # # #   --
--     #     #     #     #   #     # # # # #     #     # # # #     #               #       # #         #         --
--     #     # # # #     #   #     #       #     #   #   #   #     #               #       # # #       #         --
--     #     #     #     #   #     #       #     #   #   #   #     # # # # # # # # #     #   #     #   #   #     --
--     #     # # # #     #   #     #       #     #   #     #       #               #         #     #   #     #   --
--     #     #     #     #   #     # # # # #     #     # #   # #   #               #         #   #     #     #   --
--     # # # # # # # # # #   #                   #                 # # # # # # # # #         #         #         --
--     #                 #   #               # # #                 #               #         #       # #         --
-------------------------------------------------------------------------------------------------------------------
-- 取得目标类型和ID
-- (dwType, dwID) MY.GetTarget()       -- 取得自己当前的目标类型和ID
-- (dwType, dwID) MY.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
function MY.Player.GetTarget(object)
	if not object then
		object = GetClientPlayer()
	end
	if object then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end
MY.GetTarget = MY.Player.GetTarget

-- 根据 dwType 类型和 dwID 设置目标
-- (void) MY.SetTarget([number dwType, ]number dwID)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID
function MY.Player.SetTarget(dwType, dwID)
	-- check dwType
	if type(dwType) == "userdata" then
		dwType, dwID = ( IsPlayer(dwType) and TARGET.PLAYER ) or TARGET.NPC, dwType.dwID
	elseif type(dwType) == "string" then
		dwType, dwID = nil, dwType
	end
	-- conv if dwID is string
	if type(dwID) == "string" then
		local tTarget = {}
		for _, szName in pairs(MY.String.Split(dwID:gsub('[%[%]]', ''), "|")) do
			tTarget[szName] = true
		end
		dwID = nil
		if not dwID and dwType ~= TARGET.PLAYER then
			for _, p in pairs(MY.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and dwType ~= TARGET.NPC then
			for _, p in pairs(MY.GetNearPlayer()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.PLAYER, p.dwID
					break
				end
			end
		end
	end
	if not dwType or dwType <= 0 then
		dwType, dwID = TARGET.NO_TARGET, 0
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	SetTarget(dwType, dwID)
end
MY.SetTarget = MY.Player.SetTarget

-- 设置/取消 临时目标
-- MY.Player.SetTempTarget(dwType, dwID)
-- MY.Player.ResumeTarget()
_C.pTempTarget = { TARGET.NO_TARGET, 0 }
function MY.Player.SetTempTarget(dwType, dwID)
	TargetPanel_SetOpenState(true)
	_C.pTempTarget = { GetClientPlayer().GetTarget() }
	MY.Player.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end
MY.SetTempTarget = MY.Player.SetTempTarget
function MY.Player.ResumeTarget()
	TargetPanel_SetOpenState(true)
	-- 当之前的目标不存在时，切到空目标
	if _C.pTempTarget[1] ~= TARGET.NO_TARGET and not MY.GetObject(unpack(_C.pTempTarget)) then
		_C.pTempTarget = { TARGET.NO_TARGET, 0 }
	end
	MY.Player.SetTarget(unpack(_C.pTempTarget))
	_C.pTempTarget = { TARGET.NO_TARGET, 0 }
	TargetPanel_SetOpenState(false)
end
MY.ResumeTarget = MY.Player.ResumeTarget

-- 临时设置目标为指定目标并执行函数
-- (void) MY.Player.WithTarget(dwType, dwID, callback)
_C.tWithTarget = {}
_C.lockWithTarget = false
function _C.WithTargetHandle()
	if _C.lockWithTarget or
	#_C.tWithTarget == 0 then
		return
	end

	_C.lockWithTarget = true
	local r = table.remove(_C.tWithTarget, 1)

	MY.Player.SetTempTarget(r.dwType, r.dwID)
	local status, err = pcall(r.callback)
	if not status then
		MY.Debug({err}, 'MY.Player.lua#WithTargetHandle', MY_DEBUG.ERROR)
	end
	MY.Player.ResumeTarget()

	_C.lockWithTarget = false
	_C.WithTargetHandle()
end
function MY.Player.WithTarget(dwType, dwID, callback)
	-- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
	table.insert(_C.tWithTarget, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	_C.WithTargetHandle()
end

-- 求N2在N1的面向角  --  重载+2
-- (number) MY.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) MY.GetFaceAngel(oN1, oN2, bAbs)
-- @param nX    N1的X坐标
-- @param nY    N1的Y坐标
-- @param nFace N1的面向[0, 255]
-- @param nTX   N2的X坐标
-- @param nTY   N2的Y坐标
-- @param bAbs  返回角度是否只允许正数
-- @param oN1   N1对象
-- @param oN2   N2对象
-- @return nil    参数错误
-- @return number 面向角(-180, 180]
function MY.Player.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
	if type(nY) == "userdata" and type(nX) == "userdata" then
		nX, nY, nFace, nTX, nTY, bAbs = nX.nX, nX.nY, nX.nFaceDirection, nY.nX, nY.nY, nFace
	end
	if type(nX) == "number" and type(nY) == "number" and type(nFace) == "number"
	and type(nTX) == "number" and type(nTY) == "number" then
		local nFace = (nFace * 2 * math.pi / 255) - math.pi
		local nSight = (nX == nTX and ((nY > nTY and math.pi / 2) or - math.pi / 2)) or math.atan((nTY - nY) / (nTX - nX))
		local nAngel = ((nSight - nFace) % (math.pi * 2) - math.pi) / math.pi * 180
		if bAbs then
			nAngel = math.abs(nAngel)
		end
		return nAngel
	end
end
MY.GetFaceAngel = MY.Player.GetFaceAngel

-- 装备名为szName的装备
-- (void) MY.Equip(szName)
-- szName  装备名称
function MY.Player.Equip(szName)
	local me = GetClientPlayer()
	for i=1,6 do
		if me.GetBoxSize(i)>0 then
			for j=0, me.GetBoxSize(i)-1 do
				local item = me.GetItem(i,j)
				if item == nil then
					j=j+1
				elseif Table_GetItemName(item.nUiId)==szName then -- GetItemNameByItem(item)
					local eRetCode, nEquipPos = me.GetEquipPos(i, j)
					if szName==_L["ji guan"] or szName==_L["nu jian"] then
						for k=0,15 do
							if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, k) == nil then
								OnExchangeItem(i, j, INVENTORY_INDEX.BULLET_PACKAGE, k)
								return
							end
						end
						return
					else
						OnExchangeItem(i, j, INVENTORY_INDEX.EQUIP, nEquipPos)
						return
					end
				end
			end
		end
	end
end

-- 获取对象的buff列表
-- (table) MY.GetBuffList(KObject)
function MY.GetBuffList(KObject)
	KObject = KObject or GetClientPlayer()
	local aBuffTable = {}
	local nCount = KObject.GetBuffCount() or 0
	for i=1,nCount,1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = KObject.GetBuff(i - 1)
		if dwID then
			table.insert(aBuffTable, {
				dwID         = dwID        ,
				nLevel       = nLevel      ,
				bCanCancel   = bCanCancel  ,
				nEndFrame    = nEndFrame   ,
				nIndex       = nIndex      ,
				nStackNum    = nStackNum   ,
				dwSkillSrcID = dwSkillSrcID,
				bValid       = bValid      ,
			})
		end
	end
	return aBuffTable
end

-- 获取对象的buff
-- (table) MY.GetBuff([KObject, ]dwID[, nLevel])
function MY.Player.GetBuff(KObject, dwID, nLevel)
	local tBuff = {}
	if type(KObject) ~= "userdata" then
		KObject, dwID, nLevel = GetClientPlayer(), KObject, dwID
	end
	if type(dwID) == "table" then
		tBuff = dwID
	elseif type(dwID) == "number" then
		if type(nLevel) == "number" then
			tBuff[dwID] = nLevel
		else
			tBuff[dwID] = 0
		end
	end
	if not KObject.GetBuff then
		return MY.Debug({"KObject do not have a function named GetBuff."}, "MY.Player.GetBuff", MY_DEBUG.ERROR)
	end
	for k, v in pairs(tBuff) do
		local KBuff = KObject.GetBuff(k, v)
		if KBuff then
			return KBuff
		end
	end
end
MY.GetBuff = MY.Player.GetBuff

-- 点到自己的buff
-- (table) MY.CancelBuff([KObject = me, ]dwID[, nLevel = 0])
function MY.CancelBuff(KObject, dwID, nLevel)
	if type(KObject) ~= 'userdata' then
		KObject, dwID, nLevel = nil, KObject, dwID
	end
	if not KObject then
		KObject = GetClientPlayer()
	end
	local tBuffs = MY.GetBuffList(KObject)
	for _, buff in ipairs(tBuffs) do
		if (type(dwID) == 'string' and Table_GetBuffName(buff.dwID, buff.nLevel) == dwID or buff.dwID == dwID)
		and (not nLevel or nLevel == 0 or buff.nLevel == nLevel) then
			KObject.CancelBuff(buff.nIndex)
		end
	end
end

-- 获取对象是否无敌
-- (mixed) MY.Player.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function MY.Player.IsInvincible(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return nil
	elseif MY.Player.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end
MY.IsInvincible = MY.Player.IsInvincible

_C.tPlayerSkills = {}   -- 玩家技能列表[缓存]   -- 技能名反查ID
_C.tSkillCache = {}     -- 技能列表缓存         -- 技能ID查技能名称图标
-- 通过技能名称获取技能对象
-- (table) MY.GetSkillByName(szName)
function MY.Player.GetSkillByName(szName)
	if table.getn(_C.tPlayerSkills)==0 then
		for i = 1, g_tTable.Skill:GetRowCount() do
			local tLine = g_tTable.Skill:GetRow(i)
			if tLine~=nil and tLine.dwIconID~=nil and tLine.fSortOrder~=nil and tLine.szName~=nil and tLine.dwIconID~=13 and ( (not _C.tPlayerSkills[tLine.szName]) or tLine.fSortOrder>_C.tPlayerSkills[tLine.szName].fSortOrder) then
				_C.tPlayerSkills[tLine.szName] = tLine
			end
		end
	end
	return _C.tPlayerSkills[szName]
end

-- 判断技能名称是否有效
-- (bool) MY.IsValidSkill(szName)
function MY.Player.IsValidSkill(szName)
	if MY.Player.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) MY.CanUseSkill(number dwSkillID[, dwLevel])
function MY.Player.CanUseSkill(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == "string" then if MY.IsValidSkill(dwSkillID) then dwSkillID = MY.Player.GetSkillByName(dwSkillID).dwSkillID else return false end end
	local me, box = GetClientPlayer(), _C.hBox
	if me and box then
		if not dwLevel then
			if dwSkillID ~= 9007 then
				dwLevel = me.GetSkillLevel(dwSkillID)
			else
				dwLevel = 1
			end
		end
		if dwLevel > 0 then
			box:EnableObject(false)
			box:SetObjectCoolDown(1)
			box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
			UpdataSkillCDProgress(me, box)
			return box:IsObjectEnable() and not box:IsObjectCoolDown()
		end
	end
	return false
end

-- 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）
-- (string, number) MY.Player.GetSkillName(number dwSkillID[, number dwLevel])
function MY.Player.GetSkillName(dwSkillID, dwLevel)
	if not _C.tSkillCache[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (StringFindW(tLine.szDesc, "_") == nil  or StringFindW(tLine.szDesc, "<") ~= nil)
		then
			_C.tSkillCache[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = "SKILL#" .. dwSkillID
			if dwLevel then
				szName = szName .. ":" .. dwLevel
			end
			_C.tSkillCache[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(_C.tSkillCache[dwSkillID])
end

-- 登出游戏
-- (void) MY.Logout(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
function MY.Player.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end
MY.Logout = MY.Player.Logout

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) MY.Player.GetChannelSkillFrame(number dwSkillID)
function MY.Player.GetChannelSkillFrame(dwSkillID)
	local t = _C.tSkillEx[dwSkillID]
	if t then
		return t.nChannelFrame
	end
end
-- Load skill extend data
_C.tSkillEx = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. "data/skill_ex.jx3dat") or {}

-- 判断自己在不在队伍里
-- (bool) MY.Player.IsInParty()
function MY.Player.IsInParty()
	local me = GetClientPlayer()
	return me and me.IsInParty()
end
MY.IsInParty = MY.Player.IsInParty

-- 判断当前地图是不是竞技场
-- (bool) MY.Player.IsInArena()
function MY.Player.IsInArena()
	local me = GetClientPlayer()
	return me and (
		me.GetScene().bIsArenaMap or -- JJC
		me.GetMapID() == 173 or      -- 齐物阁
		me.GetMapID() == 181         -- 狼影殿
	)
end
MY.IsInArena = MY.Player.IsInArena

-- 判断当前地图是不是战场
-- (bool) MY.Player.IsInBattleField()
function MY.Player.IsInBattleField()
	local me = GetClientPlayer()
	return me and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD and not MY.Player.IsInArena()
end
MY.IsInBattleField = MY.Player.IsInBattleField

-- 判断当前地图是不是副本
-- (bool) MY.Player.IsInDungeon(bool bType)
function MY.Player.IsInDungeon(bType)
	local me = GetClientPlayer()
	return me and MY.IsDungeonMap(me.GetMapID(), bType)
end
MY.IsInDungeon = MY.Player.IsInDungeon

do local MARK_NAME = { _L["Cloud"], _L["Sword"], _L["Ax"], _L["Hook"], _L["Drum"], _L["Shear"], _L["Stick"], _L["Jade"], _L["Dart"], _L["Fan"] }
-- 保存当前团队信息
-- (table) MY.GetTeamInfo([table tTeamInfo])
function MY.GetTeamInfo(tTeamInfo)
	local tList, me, team = {}, GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	end
	tTeamInfo = tTeamInfo or {}
	tTeamInfo.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	tTeamInfo.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	tTeamInfo.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	tTeamInfo.nLootMode = team.nLootMode

	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			local info = team.GetMemberInfo(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
			end
		end
	end
	tTeamInfo.tList = tList
	return tTeamInfo
end

local function GetWrongIndex(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end
local function SyncMember(team, dwID, szName, state)
	if state.bForm then --如果这货之前有阵眼
		team.SetTeamFormationLeader(dwID, state.nGroup) -- 阵眼给他
		MY.Sysmsg({_L("restore formation of %d group: %s", state.nGroup + 1, szName)})
	end
	if state.nMark then -- 如果这货之前有标记
		team.SetTeamMark(state.nMark, dwID) -- 标记给他
		MY.Sysmsg({_L("restore player marked as [%s]: %s", MARK_NAME[state.nMark], szName)})
	end
end
-- 恢复团队信息
-- (bool) MY.SetTeamInfo(table tTeamInfo)
function MY.SetTeamInfo(tTeamInfo)
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	elseif not tTeamInfo then
		return false
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return MY.Sysmsg({_L["You are not team leader, permission denied"]})
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = tTeamInfo.tList, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				MY.Sysmsg({_L("unable get player of %d group: #%d", nGroup + 1, dwID)})
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, "@.*", "")
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					MY.Sysmsg({_L("unknown status: %s", szName)})
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					MY.Sysmsg({_L("need not adjust: %s", szName)})
				else
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == tTeamInfo.szLeader then
					dwLeader = dwID
				end
				if szName == tTeamInfo.szMark then
					dwMark = dwID
				end
				if szName == tTeamInfo.szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
					MY.Sysmsg({_L("restore distributor: %s", szName)})
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = GetWrongIndex(tWrong[src.state.nGroup], false)
			table.remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- 直接丢过去
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				table.remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					table.insert(tWrong[nGroup], dst)
				else -- bingo
					MY.Sysmsg({_L("change group of [%s] to %d", dst.szName, nGroup + 1)})
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			MY.Sysmsg({_L("change group of [%s] to %d", src.szName, src.state.nGroup + 1)})
			SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= tTeamInfo.nLootMode then
		team.SetTeamLootMode(tTeamInfo.nLootMode)
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		MY.Sysmsg({_L("restore team leader: %s", tTeamInfo.szLeader)})
	end
	if dwMark  ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		MY.Sysmsg({_L("restore team marker: %s", tTeamInfo.szMark)})
	end
	MY.Sysmsg({_L["Team list restored"]})
end
end
