--------------------------------------------
-- @Desc  : 茗伊插件
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-05-18 15:18:50
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
--------------------------------------------
-- 本地函数和变量
--------------------------------------------
MY = MY or {}
MY.Player = MY.Player or {}
local _Cache, _L = {}, MY.LoadLangPack()

-- #######################################################################################################
--               #     #       #             # #                         #             #             
--   # # # #     #     #         #     # # #         # # # # # #         #             #             
--   #     #   #       #               #                 #         #     #     # # # # # # # # #     
--   #     #   #   # # # #             #                 #         #     #             #             
--   #   #   # #       #     # # #     # # # # # #       # # # #   #     #       # # # # # # #       
--   #   #     #       #         #     #     #         #       #   #     #             #             
--   #     #   #   #   #         #     #     #       #   #     #   #     #   # # # # # # # # # # #   
--   #     #   #     # #         #     #     #             #   #   #     #           #   #           
--   #     #   #       #         #     #     #               #     #     #         #     #       #   
--   # # #     #       #         #   #       #             #             #       # #       #   #     
--   #         #       #       #   #                     #               #   # #   #   #     #       
--   #         #     # #     #       # # # # # # #     #             # # #         # #         # #  
-- #######################################################################################################
_Cache.tNearNpc = {}      -- 附近的NPC
_Cache.tNearPlayer = {}   -- 附近的物品
_Cache.tNearDoodad = {}   -- 附近的玩家

-- 获取附近NPC列表
-- (table) MY.GetNearNpc(void)
MY.Player.GetNearNpc = function(nLimit)
	local tNpc, i = {}, 0
	for dwID, _ in pairs(_Cache.tNearNpc) do
		local npc = GetNpc(dwID)
		if not npc then
			_Cache.tNearNpc[dwID] = nil
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
MY.Player.GetNearPlayer = function(nLimit)
	local tPlayer, i = {}, 0
	for dwID, _ in pairs(_Cache.tNearPlayer) do
		local player = GetPlayer(dwID)
		if not player then
			_Cache.tNearPlayer[dwID] = nil
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
MY.Player.GetNearDoodad = function(nLimit)
	local tDoodad, i = {}, 0
	for dwID, _ in pairs(_Cache.tNearDoodad) do
		local dooded = GetDoodad(dwID)
		if not dooded then
			_Cache.tNearDoodad[dwID] = nil
		else
			i = i + 1
			tDoodad[dwID] = dooded
			if nLimit and i == nLimit then break end
		end
	end
	return tDoodad, i
end
MY.GetNearDoodad = MY.Player.GetNearDoodad

RegisterEvent("NPC_ENTER_SCENE",    function() _Cache.tNearNpc[arg0]    = true end)
RegisterEvent("NPC_LEAVE_SCENE",    function() _Cache.tNearNpc[arg0]    = nil  end)
RegisterEvent("PLAYER_ENTER_SCENE", function() _Cache.tNearPlayer[arg0] = true end)
RegisterEvent("PLAYER_LEAVE_SCENE", function() _Cache.tNearPlayer[arg0] = nil  end)
RegisterEvent("DOODAD_ENTER_SCENE", function() _Cache.tNearDoodad[arg0] = true end)
RegisterEvent("DOODAD_LEAVE_SCENE", function() _Cache.tNearDoodad[arg0] = nil  end)

-- 获取玩家自身信息（缓存）
local m_ClientInfo
MY.Player.GetClientInfo = function(bForceRefresh)
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
MY.RegisterEvent('LOADING_END', MY.Player.GetClientInfo)

-- 获取唯一标识符
MY.Player.GetUUID = function()
	local me = GetClientPlayer()
	if me.GetGlobalID and me.GetGlobalID() ~= "0" then
		return me.GetGlobalID()
	else
		return (MY.Game.GetServer()):gsub('[/\\|:%*%?"<>]', '') .. "_" .. MY.Player.GetClientInfo().dwID
	end
end

-- 获取好友列表
-- MY.Player.GetFriendList()         获取所有好友列表
-- MY.Player.GetFriendList(1)        获取第一个分组好友列表
-- MY.Player.GetFriendList("挽月堂") 获取分组名称为挽月堂的好友列表
MY.Player.GetFriendList = function(arg0)
	local t = {}
	local me = GetClientPlayer()
	local tGroup = me.GetFellowshipGroupInfo() or {}
	if type(arg0) == "number" then
		for i = #tGroup, 1, -1 do
			if arg0 ~= tGroup[i].id then
				table.remove(tGroup, i)
			end
		end
	elseif type(arg0) == "string" then
		for i = #tGroup, 1, -1 do
			if arg0 ~= tGroup[i].name then
				table.remove(tGroup, i)
			end
		end
	end
	local n = 0
	for _, group in ipairs(tGroup) do
		for _, p in ipairs(me.GetFellowshipInfo(group.id) or {}) do
			t[p.id] = p
			n = n + 1
		end
	end
	
	return t, n
end

-- 获取好友
MY.Player.GetFriend = function(arg0)
	if not arg0 then return nil end
	local tFriend = MY.Player.GetFriendList()
	if type(arg0) == "number" then
		return tFriend[arg0]
	elseif type(arg0) == "string" then
		for id, p in pairs(tFriend) do
			if p.name == arg0 then
				return p
			end
		end
	end
end

-- 获取好友列表
MY.Player.GetTongMemberList = function(bShowOffLine, szSorter, bAsc)
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

-- 获取帮会成员
MY.Player.GetTongMember = function(arg0)
	if not arg0 then
		return
	end
	
	return GetTongClient().GetMemberInfo(arg0)
end

-- ##################################################################################################
--       #         #   #                   #             #         #                   #             
--       #         #     #         #       #             #         #   #               #             
--       # # #     #                 #     #         #   #         #     #   # # # # # # # # # # #   
--       #         # # # #             #   #           # #         #                 #   #           
--       #     # # #           #           #             #   # # # # # # #         #       #         
--   # # # # #     #   #         #         #             #         #             #     #     #       
--   #       #     #   #           #       #             #       #   #       # #         #     # #   
--   #       #     #   #                   # # # #     # #       #   #                 #             
--   #       #       #       # # # # # # # #         #   #       #   #         #   #     #     #     
--   # # # # #     # #   #                 #             #     #       #       #   #     #       #   
--   #           #     # #                 #             #     #       #     #     #         #   #   
--             #         #                 #             #   #           #           # # # # #       
-- ##################################################################################################
_Cache.nLastFightUUID           = nil
_Cache.nCurrentFightUUID        = nil
_Cache.nCurrentFightBeginFrame  = -1
_Cache.nCurrentFightEndingFrame = -1
_Cache.OnFightStateChange = function(bFightState)
	-- 当没有传bFightState或bFightState为否时 重新获取逻辑战斗状态
	if not bFightState then
		bFightState = MY.Player.IsFighting()
	end
	-- 判定战斗边界
	if bFightState then
		-- 进入战斗判断
		if not _Cache.bFighting then
			_Cache.bFighting = true
			-- 5秒脱战判定缓冲 防止明教隐身错误判定
			if _Cache.nCurrentFightBeginFrame < 0
			or MY.GetFrameCount() - _Cache.nCurrentFightEndingFrame > GLOBAL.GAME_FPS * 5 then
				-- 新的一轮战斗开始
				_Cache.nCurrentFightBeginFrame = MY.GetFrameCount()
				_Cache.nCurrentFightUUID = _Cache.nCurrentFightBeginFrame
				FireUIEvent('MY_FIGHT_HINT', true)
			end
		end
	else
		-- 退出战斗判定
		if _Cache.bFighting then
			_Cache.bFighting = false
			_Cache.nCurrentFightEndingFrame = MY.GetFrameCount()
		end
		if _Cache.nCurrentFightUUID and MY.GetFrameCount() - _Cache.nCurrentFightEndingFrame > GLOBAL.GAME_FPS * 5 then
			_Cache.nLastFightUUID = _Cache.nCurrentFightUUID
			_Cache.nCurrentFightUUID = nil
			FireUIEvent('MY_FIGHT_HINT', false)
		end
	end
end
MY.BreatheCall(_Cache.OnFightStateChange)
MY.RegisterEvent('FIGHT_HINT', function(event) _Cache.OnFightStateChange(arg0) end)
-- 获取当前战斗时间
MY.Player.GetFightTime = function(szFormat)
	local nFrame = 0
	
	if MY.Player.IsFighting() then -- 战斗状态
		nFrame = MY.GetFrameCount() - _Cache.nCurrentFightBeginFrame
	else  -- 脱战状态
		nFrame = _Cache.nCurrentFightEndingFrame - _Cache.nCurrentFightBeginFrame
	end
	
	if szFormat then
		local nSeconds = math.floor(nFrame  / GLOBAL.GAME_FPS)
		local nMinutes = math.floor(nSeconds / 60)
		local nHours   = math.floor(nMinutes / 60)
		local nMinute  = nMinutes % 60
		local nSecond  = nSeconds % 60
		szFormat = szFormat:gsub('f', nFrame)
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
		szFormat = nFrame
	end
	return szFormat
end

-- 获取当前战斗唯一标示符
MY.Player.GetFightUUID = function()
	return _Cache.nCurrentFightUUID
end

-- 获取上次战斗唯一标示符
MY.Player.GetLastFightUUID = function()
	return _Cache.nLastFightUUID
end

-- 获取自身是否处于逻辑战斗状态
-- (bool) MY.Player.IsFighting()
MY.Player.IsFighting = function()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	
	if not bFightState and MY.Player.IsInArena() then
		bFightState = true
	elseif not bFightState and MY.Player.IsInDungeon() then
	-- 在副本且附近队友进战则判断处于战斗状态
		for dwID, p in pairs(MY.Player.GetNearPlayer()) do
			if me.IsPlayerInMyParty(dwID) and p.bFightState then
				bFightState = true
				break
			end
		end
	end
	return bFightState
end

-- #######################################################################################################
--                                   #                                                       #                   
--   # # # # # # # # # # #         #                               # # # # # # # # #         #     # # # # #     
--             #             # # # # # # # # # # #       #         #               #         #                   
--           #               #                   #     #   #       #               #     # # # #                 
--     # # # # # # # # # #   #                   #     #   #       # # # # # # # # #         #   # # # # # # #   
--     #     #     #     #   #     # # # # #     #     # # # #     #               #       # #         #         
--     #     # # # #     #   #     #       #     #   #   #   #     #               #       # # #       #         
--     #     #     #     #   #     #       #     #   #   #   #     # # # # # # # # #     #   #     #   #   #     
--     #     # # # #     #   #     #       #     #   #     #       #               #         #     #   #     #   
--     #     #     #     #   #     # # # # #     #     # #   # #   #               #         #   #     #     #   
--     # # # # # # # # # #   #                   #                 # # # # # # # # #         #         #         
--     #                 #   #               # # #                 #               #         #       # #         
-- #######################################################################################################
-- 取得目标类型和ID
-- (dwType, dwID) MY.GetTarget()       -- 取得自己当前的目标类型和ID
-- (dwType, dwID) MY.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
MY.Player.GetTarget = function(object)
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
MY.Player.SetTarget = function(dwType, dwID)
	-- check dwType
	if type(dwType)=="userdata" then
		dwType, dwID = ( IsPlayer(dwType) and TARGET.PLAYER ) or TARGET.NPC, dwType.dwID
	elseif type(dwType)=="string" then
		dwType, dwID = 0, dwType
	end
	-- conv if dwID is string
	if type(dwID)=="string" then
		for _, p in pairs(MY.GetNearNpc()) do
			if p.szName == dwID then
				dwType, dwID = TARGET.NPC, p.dwID
			end
		end
		for _, p in pairs(MY.GetNearPlayer()) do
			if p.szName == dwID then
				dwType, dwID = TARGET.PLAYER, p.dwID
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
_Cache.pTempTarget = { TARGET.NO_TARGET, 0 }
MY.Player.SetTempTarget = function(dwType, dwID)
	TargetPanel_SetOpenState(true)
	_Cache.pTempTarget = { GetClientPlayer().GetTarget() }
	MY.Player.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end
MY.SetTempTarget = MY.Player.SetTempTarget
MY.Player.ResumeTarget = function()
	TargetPanel_SetOpenState(true)
	-- 当之前的目标不存在时，切到空目标
	if _Cache.pTempTarget[1] ~= TARGET.NO_TARGET and not MY.GetObject(unpack(_Cache.pTempTarget)) then
		_Cache.pTempTarget = { TARGET.NO_TARGET, 0 }
	end
	MY.Player.SetTarget(unpack(_Cache.pTempTarget))
	_Cache.pTempTarget = { TARGET.NO_TARGET, 0 }
	TargetPanel_SetOpenState(false)
end
MY.ResumeTarget = MY.Player.ResumeTarget

-- 临时设置目标为指定目标并执行函数
-- (void) MY.Player.WithTarget(dwType, dwID, callback)
_Cache.tWithTarget = {}
_Cache.lockWithTarget = false
_Cache.WithTargetHandle = function()
	if _Cache.lockWithTarget or
	#_Cache.tWithTarget == 0 then
		return
	end

	_Cache.lockWithTarget = true
	local r = table.remove(_Cache.tWithTarget, 1)
	
	MY.Player.SetTempTarget(r.dwType, r.dwID)
	local status, err = pcall(r.callback)
	if not status then
		MY.Debug({err}, 'MY.Player.lua#WithTargetHandle', MY_DEBUG.ERROR)
	end
	MY.Player.ResumeTarget()
	
	_Cache.lockWithTarget = false
	_Cache.WithTargetHandle()
end
MY.Player.WithTarget = function(dwType, dwID, callback)
	-- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
	table.insert(_Cache.tWithTarget, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	_Cache.WithTargetHandle()
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
MY.Player.GetFaceAngel = function(nX, nY, nFace, nTX, nTY, bAbs)
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
MY.Player.Equip = function(szName)
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
-- (table) MY.GetBuffList(obj)
MY.Player.GetBuffList = function(obj)
	obj = obj or GetClientPlayer()
	local aBuffTable = {}
	local nCount = obj.GetBuffCount() or 0
	for i=1,nCount,1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
		if dwID then
			table.insert(aBuffTable,{dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame, nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid})
		end
	end
	return aBuffTable
end
MY.GetBuffList = MY.Player.GetBuffList

-- 获取对象的buff
-- (table) MY.GetBuff(obj)
MY.Player.GetBuff = function(obj, dwID, nLevel)
	if type(obj) == "number" then
		obj, dwID, nLevel = GetClientPlayer(), obj, dwID
	end
	if not nLevel then
		for _, buff in ipairs(MY.Player.GetBuffList(obj)) do
			if buff.dwID == dwID then
				return buff
			end
		end
	else
		for _, buff in ipairs(MY.Player.GetBuffList(obj)) do
			if buff.dwID == dwID and buff.nLevel == nLevel then
				return buff
			end
		end
	end
	return nil
end
MY.GetBuff = MY.Player.GetBuff

-- 获取对象是否无敌
-- (mixed) MY.Player.IsInvincible([object obj])
-- @return <nil >: invalid obj
-- @return <bool>: object invincible state
MY.Player.IsInvincible = function(obj)
	obj = obj or GetClientPlayer()
	if not obj then
		return nil
	elseif MY.Player.GetBuff(obj, 961) then
		return true
	else
		return false
	end
end
MY.IsInvincible = MY.Player.IsInvincible

_Cache.tPlayerSkills = {}   -- 玩家技能列表[缓存]   -- 技能名反查ID
_Cache.tSkillCache = {}     -- 技能列表缓存         -- 技能ID查技能名称图标
-- 通过技能名称获取技能对象
-- (table) MY.GetSkillByName(szName)
MY.Player.GetSkillByName = function(szName)
	if table.getn(_Cache.tPlayerSkills)==0 then
		for i = 1, g_tTable.Skill:GetRowCount() do
			local tLine = g_tTable.Skill:GetRow(i)
			if tLine~=nil and tLine.dwIconID~=nil and tLine.fSortOrder~=nil and tLine.szName~=nil and tLine.dwIconID~=13 and ( (not _Cache.tPlayerSkills[tLine.szName]) or tLine.fSortOrder>_Cache.tPlayerSkills[tLine.szName].fSortOrder) then
				_Cache.tPlayerSkills[tLine.szName] = tLine
			end
		end
	end
	return _Cache.tPlayerSkills[szName]
end

-- 判断技能名称是否有效
-- (bool) MY.IsValidSkill(szName)
MY.Player.IsValidSkill = function(szName)
	if MY.Player.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) MY.CanUseSkill(number dwSkillID[, dwLevel])
MY.Player.CanUseSkill = function(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == "string" then if MY.IsValidSkill(dwSkillID) then dwSkillID = MY.Player.GetSkillByName(dwSkillID).dwSkillID else return false end end
	local me, box = GetClientPlayer(), _Cache.hBox
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
MY.Player.GetSkillName = function(dwSkillID, dwLevel)
	if not _Cache.tSkillCache[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (StringFindW(tLine.szDesc, "_") == nil  or StringFindW(tLine.szDesc, "<") ~= nil)
		then
			_Cache.tSkillCache[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = "SKILL#" .. dwSkillID
			if dwLevel then
				szName = szName .. ":" .. dwLevel
			end
			_Cache.tSkillCache[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(_Cache.tSkillCache[dwSkillID])
end

-- 登出游戏
-- (void) MY.LogOff(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
MY.Player.LogOff = function(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) MY.Player.GetChannelSkillFrame(number dwSkillID)
MY.Player.GetChannelSkillFrame = function(dwSkillID)
	local t = _Cache.tSkillEx[dwSkillID]
	if t then
		return t.nChannelFrame
	end
end
-- Load skill extend data
_Cache.tSkillEx = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot.."data/skill_ex", true) or {}

-- 判断当前地图是不是竞技场
-- (bool) MY.Player.IsInArena()
MY.Player.IsInArena = function()
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
MY.Player.IsInBattleField = function()
	local me = GetClientPlayer()
	return me and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD and not MY.Player.IsInArena()
end
MY.IsInBattleField = MY.Player.IsInBattleField

-- 判断当前地图是不是副本
-- (bool) MY.Player.IsInDungeon()
MY.Player.IsInDungeon = function()
	local me = GetClientPlayer()
	return me and MY.Game.IsDungeonMap(me.GetMapID())
end
MY.IsInDungeon = MY.Player.IsInDungeon
