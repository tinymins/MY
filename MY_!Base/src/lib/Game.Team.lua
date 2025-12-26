--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Team')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 获取一个角色是否是队伍标记者
---@param dwID number @角色ID
---@return boolean @角色是否是队伍标记者
function X.IsPlayerTeamMarker(dwID)
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == dwID
end

-- 获取当前角色是否是队伍标记者
---@return boolean @角色是否是队伍标记者
function X.IsClientPlayerTeamMarker()
	local dwID = X.GetClientPlayerID()
	return X.IsPlayerTeamMarker(dwID)
end

-- 获取一个角色是否是队伍队长
---@param dwID number @角色ID
---@return boolean @角色是否是队伍队长
function X.IsPlayerTeamLeader(dwID)
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == dwID
end

-- 获取当前角色是否是队伍队长
---@return boolean @角色是否是队伍队长
function X.IsClientPlayerTeamLeader()
	local dwID = X.GetClientPlayerID()
	return X.IsPlayerTeamLeader(dwID)
end

-- 获取一个角色是否是队伍分配者
---@param dwID number @角色ID
---@return boolean @角色是否是队伍分配者
function X.IsPlayerTeamDistributor(dwID)
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == dwID
end

-- 获取当前角色是否是队伍分配者
---@return boolean @角色是否是队伍分配者
function X.IsClientPlayerTeamDistributor()
	local dwID = X.GetClientPlayerID()
	return X.IsPlayerTeamDistributor(dwID)
end

-- 判断自己在不在队伍里
-- (bool) X.IsClientPlayerInParty()
function X.IsClientPlayerInParty()
	local me = X.GetClientPlayer()
	return me and me.IsInParty()
end

-- 判断自己在不在团队里
-- (bool) X.IsClientPlayerInRaid()
function X.IsClientPlayerInRaid()
	local me = X.GetClientPlayer()
	return me and me.IsInRaid()
end

---判断当前团队、房间切换状态
---@return '"TEAM"' | '"ROOM"' @当前地图、房间切换激活标签
function X.GetCurrentTeamSwitchType()
	if TeamSwitchBtn_IsCheckRoom then
		return TeamSwitchBtn_IsCheckRoom()
			and 'ROOM'
			or 'TEAM'
	end
	return 'TEAM'
end

-- 设置标记目标
---@param nMark number @标记索引
---@param dwID number @目标ID
---@return boolean @是否成功
function X.SetTeamMarkCharacter(nMark, dwID)
	local npc = not X.IsPlayer(dwID) and X.GetNpc(dwID) or nil
	if npc and X.IsShieldedNpc(npc.dwTemplateID) then
		return false
	end
	return GetClientTeam().SetTeamMark(nMark, dwID) or false
end

-- 获取所有标记目标
---@return table @所有标记目标
function X.GetTeamMark()
	if not X.IsClientPlayerInParty() then
		return X.CONSTANT.EMPTY_TABLE
	end
	return GetClientTeam().GetTeamMark() or X.CONSTANT.EMPTY_TABLE
end

-- 获取标记目标
---@param nMark number @标记索引
---@return number @目标ID
function X.GetTeamMarkCharacter(nMark)
	local tMark = X.GetTeamMark()
	return tMark[nMark]
end

-- 获取目标标记
---@param dwID number @目标ID
---@return number @标记索引
function X.GetCharacterTeamMark(dwID)
	if not X.IsClientPlayerInParty() then
		return
	end
	return GetClientTeam().GetMarkIndex(dwID)
end

-- 获取团队成员ID列表
---@return table @成员ID列表
function X.GetTeamMemberList()
	local me   = X.GetClientPlayer()
	local team = GetClientTeam()
	if me.IsInParty() then
		return team.GetTeamMemberList()
	end
	return { me.dwID }
end

-- 获取团队成员信息
---@param dwID number @需要获取的角色ID
---@return table @成员信息，获取失败返回空
function X.GetTeamMemberInfo(dwID)
	local me = X.GetClientPlayer()
	if me.IsInParty() then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(dwID)
		if info then
			return {
				dwID = dwID,
				szGlobalID = info.szGlobalID,
				szName = info.szName,
				nLevel = info.nLevel,
				bOnline = info.bIsOnLine,
				bDeathFlag = info.bDeathFlag,
				nCamp = info.nCamp,
				dwForceID = info.dwForceID,
				dwKungfuID = info.dwMountKungfuID,
				dwActualMountKungfuID = info.dwActualMountKungfuID or info.dwMountKungfuID,
				nMaxLife = info.nMaxLife,
				nCurrentLife = info.nCurrentLife,
				nMaxMana = info.nMaxMana,
				nCurrentMana = info.nCurrentMana,
				dwMapID = info.dwMapID,
				nMapCopyIndex = info.nMapCopyIndex,
				nPosX = info.nPosX,
				nPosY = info.nPosY,
				nRoleType = info.nRoleType,
				nFormationCoefficient = info.nFormationCoefficient,
				dwMiniAvatarID = info.dwMiniAvatarID,
				-- nVipType = info.nVipType,
				bIdentityVisible = info.bIdentityVisiable,
				dwIdentityVisible = info.dwIdentityVisiable,
			}
		end
		return
	end
	if dwID == UI_GetClientPlayerID() then
		return {
			dwID = dwID,
			szGlobalID = X.GetClientPlayerGlobalID(),
			szName = me.szName,
			nLevel = me.nLevel,
			bOnline = true,
			bDeathFlag = me.nMoveState == MOVE_STATE.ON_DEATH,
			nCamp = me.nCamp,
			dwForceID = me.dwForceID,
			dwKungfuID = UI_GetPlayerMountKungfuID(),
			nMaxLife = me.nMaxLife,
			nCurrentLife = me.nCurrentLife,
			nMaxMana = me.nMaxMana,
			nCurrentMana = me.nCurrentMana,
			dwMapID = me.GetMapID(),
			nMapCopyIndex = X.GetMapSaveCopy(me.GetMapID()) or 0,
			nPosX = me.nX,
			nPosY = me.nY,
			nRoleType = me.nRoleType,
			nFormationCoefficient = 0,
			dwMiniAvatarID = me.dwMiniAvatarID,
			-- nVipType = info.nVipType,
			bIdentityVisible = true,
			dwIdentityVisible = 0,
		}
	end
end

-- 获取房间信息
---@return table @房间信息
function X.GetRoomInfo()
	if RoomBase_GetRoomInfo then
		local info = RoomBase_GetRoomInfo()
		return {
			eRoomState     = info.eRoomState   , -- 1
			nMapCDProgress = info.nRoomProgress, -- 31
			nTargetMapID   = info.nTargetMapID , -- 668
			szOwnerID      = info.szOwnerID    , -- "432345564230575012"
			bBiddingMode   = info.bBiddingMode , -- false
		}
	end
end

-- 获取房间成员GlobalID列表
---@return table @成员GlobalID列表
function X.GetRoomMemberList()
	if RoomBase_GetRoomInfo then
		local info = RoomBase_GetRoomInfo()
		if info then
			local aList = {}
			for _, v in ipairs(info) do
				table.insert(aList, v.szGlobalID)
			end
			if #aList == 0 then
				table.insert(aList, X.GetClientPlayerGlobalID())
			end
			return aList
		end
	end
	return { X.GetClientPlayerGlobalID() }
end

-- 获取房间成员信息
---@param szGlobalID string @需要获取的角色GlobalID
---@return table @成员信息，获取失败返回空
function X.GetRoomMemberInfo(szGlobalID)
	if RoomBase_GetRoomInfo then
		local info = RoomBase_GetRoomInfo()
		if info then
			for _, v in ipairs(info) do
				if v.szGlobalID == szGlobalID then
					return {
						szGlobalID = v.szGlobalID,
						szName = v.szName,
						nLevel = v.nLevel,
						nCamp = v.nCamp,
						nRoleType = v.nRoleType,
						dwForceID = v.dwForceID,
						dwKungfuID = v.dwKungfuID,
						nEquipScore = v.nEquipScore,
						dwMiniAvatarID = v.dwMiniAvatarID,
						nMemberIndex = v.nMemberIndex,
						dwServerID = v.dwCenterID,
						nMapCDProgress = v.nProcess,
						nClientVersionType = v.nClientVersionType,
					}
				end
			end
		end
	end
	local me = X.GetClientPlayer()
	if szGlobalID == X.GetClientPlayerGlobalID() then
		local tInfo = X.GetRoomInfo()
		return {
			szGlobalID = X.GetClientPlayerGlobalID(),
			szName = me.szName,
			nLevel = me.nLevel,
			nCamp = me.nCamp,
			nRoleType = me.nRoleType,
			dwForceID = me.dwForceID,
			dwKungfuID = UI_GetPlayerMountKungfuID(),
			nEquipScore = me.GetTotalEquipScore() or 0,
			dwMiniAvatarID = me.dwMiniAvatarID,
			nMemberIndex = 0,
			dwServerID = X.GetServerID(),
			nMapCDProgress = tInfo and tInfo.nMapCDProgress or 0,
			nClientVersionType = 0,
		}
	end
end

-- 保存当前团队信息
-- (table) X.GetTeamInfo([table tTeamInfo])
function X.GetTeamInfo(tTeamInfo)
	local tList, me, team = {}, X.GetClientPlayer(), GetClientTeam()
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

do
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
		X.OutputSystemMessage(_L('Restore formation of %d group: %s', state.nGroup + 1, szName))
	end
	if state.nMark then -- 如果这货之前有标记
		team.SetTeamMark(state.nMark, dwID) -- 标记给他
		X.OutputSystemMessage(_L('Restore player marked as [%s]: %s', X.CONSTANT.TEAM_MARK_NAME[state.nMark], szName))
	end
end
-- 恢复团队信息
-- (bool) X.SetTeamInfo(table tTeamInfo)
function X.SetTeamInfo(tTeamInfo)
	local me, team = X.GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	elseif not tTeamInfo then
		return false
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return X.OutputSystemMessage(_L['You are not team leader, permission denied'])
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
				X.OutputSystemMessage(_L('Unable get player of %d group: #%d', nGroup + 1, dwID))
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					X.OutputSystemMessage(_L('Unknown status: %s', szName))
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					X.OutputSystemMessage(_L('Need not adjust: %s', szName))
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
					X.OutputSystemMessage(_L('Restore distributor: %s', szName))
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
					X.OutputSystemMessage(_L('Change group of [%s] to %d', dst.szName, nGroup + 1))
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			X.OutputSystemMessage(_L('Change group of [%s] to %d', src.szName, src.state.nGroup + 1))
			SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= tTeamInfo.nLootMode then
		team.SetTeamLootMode(tTeamInfo.nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		X.OutputSystemMessage(_L('Restore team marker: %s', tTeamInfo.szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		X.OutputSystemMessage(_L('Restore team leader: %s', tTeamInfo.szLeader))
	end
	X.OutputSystemMessage(_L['Team list restored'])
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
