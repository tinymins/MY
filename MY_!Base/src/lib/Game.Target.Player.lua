--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Player')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

---获取门派配色
---@param dwForce number @要获取的门派ID
---@param szType 'background'|'foreground' @获取背景色还是前景色
---@return number,number,number @配色RGB
function X.GetForceColor(dwForce, szType)
	if szType == 'background' then
		return X.Unpack(X.CONSTANT.FORCE_BACKGROUND_COLOR[dwForce])
	end
	return X.Unpack(X.CONSTANT.FORCE_FOREGROUND_COLOR[dwForce])
end

---获取阵营配色
---@param nCamp number @要获取的阵营
---@param szType 'background'|'foreground' @获取背景色还是前景色
---@return number,number,number @配色RGB
function X.GetCampColor(nCamp, szType)
	if szType == 'background' then
		return X.Unpack(X.CONSTANT.CAMP_BACKGROUND_COLOR[nCamp])
	end
	return X.Unpack(X.CONSTANT.CAMP_FOREGROUND_COLOR[nCamp])
end

--------------------------------------------------------------------------------
-- 角色信息相关接口
--------------------------------------------------------------------------------

-- 获取玩家自身信息（缓存）
do
local CLIENT_PLAYER_INFO
local function GeneClientPlayerInfo(bForce)
	if not bForce and CLIENT_PLAYER_INFO and CLIENT_PLAYER_INFO.dwID then
		return
	end
	local me = X.GetClientPlayer()
	if me then -- 确保获取到玩家
		if not CLIENT_PLAYER_INFO then
			CLIENT_PLAYER_INFO = {}
		end
		if not X.IsPlayerCrossServer(me.dwID) then -- 确保不在战场
			CLIENT_PLAYER_INFO.dwID   = me.dwID
			CLIENT_PLAYER_INFO.szName = me.szName
		end
		CLIENT_PLAYER_INFO.nX                = me.nX
		CLIENT_PLAYER_INFO.nY                = me.nY
		CLIENT_PLAYER_INFO.nZ                = me.nZ
		CLIENT_PLAYER_INFO.nFaceDirection    = me.nFaceDirection
		CLIENT_PLAYER_INFO.szTitle           = me.szTitle
		CLIENT_PLAYER_INFO.dwForceID         = me.dwForceID
		CLIENT_PLAYER_INFO.nLevel            = me.nLevel
		CLIENT_PLAYER_INFO.nExperience       = me.nExperience
		CLIENT_PLAYER_INFO.nCurrentStamina   = me.nCurrentStamina
		CLIENT_PLAYER_INFO.nCurrentThew      = me.nCurrentThew
		CLIENT_PLAYER_INFO.nMaxStamina       = me.nMaxStamina
		CLIENT_PLAYER_INFO.nMaxThew          = me.nMaxThew
		CLIENT_PLAYER_INFO.nBattleFieldSide  = me.nBattleFieldSide
		CLIENT_PLAYER_INFO.dwSchoolID        = me.dwSchoolID
		CLIENT_PLAYER_INFO.nCurrentTrainValue= me.nCurrentTrainValue
		CLIENT_PLAYER_INFO.nMaxTrainValue    = me.nMaxTrainValue
		CLIENT_PLAYER_INFO.nUsedTrainValue   = me.nUsedTrainValue
		CLIENT_PLAYER_INFO.nDirectionXY      = me.nDirectionXY
		CLIENT_PLAYER_INFO.nCurrentLife      = me.nCurrentLife
		CLIENT_PLAYER_INFO.nMaxLife          = me.nMaxLife
		CLIENT_PLAYER_INFO.fCurrentLife64,
		CLIENT_PLAYER_INFO.fMaxLife64        = X.GetCharacterLife(me)
		CLIENT_PLAYER_INFO.nMaxLifeBase      = me.nMaxLifeBase
		CLIENT_PLAYER_INFO.nCurrentMana      = me.nCurrentMana
		CLIENT_PLAYER_INFO.nMaxMana          = me.nMaxMana
		CLIENT_PLAYER_INFO.nMaxManaBase      = me.nMaxManaBase
		CLIENT_PLAYER_INFO.nCurrentEnergy    = me.nCurrentEnergy
		CLIENT_PLAYER_INFO.nMaxEnergy        = me.nMaxEnergy
		CLIENT_PLAYER_INFO.nEnergyReplenish  = me.nEnergyReplenish
		CLIENT_PLAYER_INFO.bCanUseBigSword   = me.bCanUseBigSword
		CLIENT_PLAYER_INFO.nAccumulateValue  = me.nAccumulateValue
		CLIENT_PLAYER_INFO.nCamp             = me.nCamp
		CLIENT_PLAYER_INFO.bCampFlag         = me.bCampFlag
		CLIENT_PLAYER_INFO.bOnHorse          = me.bOnHorse
		CLIENT_PLAYER_INFO.nMoveState        = me.nMoveState
		CLIENT_PLAYER_INFO.dwTongID          = me.dwTongID
		CLIENT_PLAYER_INFO.nGender           = me.nGender
		CLIENT_PLAYER_INFO.nCurrentRage      = me.nCurrentRage
		CLIENT_PLAYER_INFO.nMaxRage          = me.nMaxRage
		CLIENT_PLAYER_INFO.nCurrentPrestige  = me.nCurrentPrestige
		CLIENT_PLAYER_INFO.bFightState       = me.bFightState
		CLIENT_PLAYER_INFO.nRunSpeed         = me.nRunSpeed
		CLIENT_PLAYER_INFO.nRunSpeedBase     = me.nRunSpeedBase
		CLIENT_PLAYER_INFO.dwTeamID          = me.dwTeamID
		CLIENT_PLAYER_INFO.nRoleType         = me.nRoleType
		CLIENT_PLAYER_INFO.nContribution     = me.nContribution
		CLIENT_PLAYER_INFO.nCoin             = me.nCoin
		CLIENT_PLAYER_INFO.nJustice          = me.nJustice
		CLIENT_PLAYER_INFO.nExamPrint        = me.nExamPrint
		CLIENT_PLAYER_INFO.nArenaAward       = me.nArenaAward
		CLIENT_PLAYER_INFO.nActivityAward    = me.nActivityAward
		CLIENT_PLAYER_INFO.bHideHat          = me.bHideHat
		CLIENT_PLAYER_INFO.bRedName          = me.bRedName
		CLIENT_PLAYER_INFO.dwKillCount       = me.dwKillCount
		CLIENT_PLAYER_INFO.nRankPoint        = me.nRankPoint
		CLIENT_PLAYER_INFO.nTitle            = me.nTitle
		CLIENT_PLAYER_INFO.nTitlePoint       = me.nTitlePoint
		CLIENT_PLAYER_INFO.dwPetID           = me.dwPetID
		CLIENT_PLAYER_INFO.dwMapID           = me.GetMapID()
		CLIENT_PLAYER_INFO.szMapName         = Table_GetMapName(me.GetMapID())
	end
end
X.RegisterEvent('LOADING_ENDING', function()
	GeneClientPlayerInfo(true)
end)
---获取玩家自身信息（缓存）
---@param bForce boolean @是否强制刷新缓存
---@return unknown @玩家的自身信息，或自身信息子字段数据
function X.GetClientPlayerInfo(bForce)
	GeneClientPlayerInfo(bForce)
	if not CLIENT_PLAYER_INFO then
		return X.CONSTANT.EMPTY_TABLE
	end
	return CLIENT_PLAYER_INFO
end
end

---获取玩家自身角色属性
function X.GetClientPlayerCharInfo()
	local me = X.GetClientPlayer()
	local kungfu = X.GetClientPlayer().GetKungfuMount()
	local data = {
		dwID = me.dwID,
		szName = me.szName,
		dwForceID = me.dwForceID,
		nEquipScore = me.GetTotalEquipScore() or 0,
		dwMountKungfuID = kungfu and kungfu.dwSkillID or 0,
		dwActualMountKungfuID = kungfu and kungfu.dwSkillID or 0,
	}
	if CharInfoMore_GetShowValue then
		local aCategory, aContent, tTip = CharInfoMore_GetShowValue()
		local nCategoryIndex, nSubLen, nSubIndex = 0, -1, 0
		for _, content in ipairs(aContent) do
			if nSubIndex > nSubLen then
				nCategoryIndex = nCategoryIndex + 1
				local category = aCategory[nCategoryIndex]
				if category then
					table.insert(data, {
						category = true,
						label = category[1],
					})
					nSubLen, nSubIndex = category[2], 1
				end
			end
			table.insert(data, {
				label = content[1],
				value = content[2],
				tip = tTip[content[3]],
			})
			nSubIndex = nSubIndex + 1
		end
	else
		local frame = Station.Lookup('Normal/CharInfo')
		if not frame or not frame:IsVisible() then
			if frame then
				X.UI.CloseFrame('CharInfo') -- 强制kill
			end
			X.UI.OpenFrame('CharInfo'):Hide()
		end
		local hCharInfo = Station.Lookup('Normal/CharInfo')
		local handle = hCharInfo:Lookup('WndScroll_Property', '')
		for i = 0, handle:GetVisibleItemCount() -1 do
			local h = handle:Lookup(i)
			table.insert(data, {
				szTip = h.szTip,
				label = h:Lookup(0):GetText(),
				value = h:Lookup(1):GetText(),
			})
		end
	end
	return data
end

do
local REQUEST_TIME = {}
local PLAYER_GLOBAL_ID = {}
local function RequestTeammateGlobalID()
	local me = X.GetClientPlayer()
	local team = GetClientTeam()
	if not me or X.IsPlayerCrossServer(me.dwID) or not team or not me.IsInParty() then
		return
	end
	local nTime = GetTime()
	local aRequestGlobalID = {}
	for _, dwTarID in ipairs(team.GetTeamMemberList()) do
		local info = team.GetMemberInfo(dwTarID)
		if not PLAYER_GLOBAL_ID[dwTarID]
		and (info and info.bIsOnLine)
		and (not REQUEST_TIME[dwTarID] or nTime - REQUEST_TIME[dwTarID] > 2000) then
			table.insert(aRequestGlobalID, dwTarID)
			REQUEST_TIME[dwTarID] = nTime
		end
	end
	if not X.IsEmpty(aRequestGlobalID) then
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, X.NSFormatString('{$NS}_GLOBAL_ID_REQUEST'), {aRequestGlobalID}, true)
	end
end
X.RegisterEvent('LOADING_END', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_LEVEL_UP_RAID', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_ADD_MEMBER', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', RequestTeammateGlobalID)
X.RegisterBgMsg(X.NSFormatString('{$NS}_GLOBAL_ID'), function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	PLAYER_GLOBAL_ID[dwTalkerID] = data
end)
-- 获取唯一标识符
function X.GetPlayerGlobalID(dwID)
	if dwID == X.GetClientPlayerID() then
		return X.GetClientPlayerGlobalID()
	end
	local szGlobalID = PLAYER_GLOBAL_ID[dwID]
	if not szGlobalID then
		local kTarget = X.GetPlayer(dwID)
		if kTarget then
			szGlobalID = kTarget.GetGlobalID()
		end
		if szGlobalID == '0' then
			szGlobalID = nil
		end
		PLAYER_GLOBAL_ID[dwID] = szGlobalID
	end
	return szGlobalID
end
end

-- 拼接角色跨服名
---@param szName string @角色原始名
---@param szServerName string @角色服务器名
---@return string @角色跨服名
function X.AssemblePlayerGlobalName(szName, szServerName)
	return szName .. g_tStrings.STR_CONNECT .. szServerName
end

-- 拆分角色名与角色服务器
---@param szGlobalName string @角色跨服名，本服可不加后缀
---@param bFallbackServerName boolean @角色名不包含服务器时是否视为当前主服务器角色
---@return string, string | nil @去除跨服服务器后缀的角色名, 角色所在服务器名
function X.DisassemblePlayerGlobalName(szGlobalName, bFallbackServerName)
	local nPos, szServerName = X.StringFindW(szGlobalName, g_tStrings.STR_CONNECT), nil
	if nPos then
		szServerName = szGlobalName:sub(nPos + #g_tStrings.STR_CONNECT)
		szGlobalName = szGlobalName:sub(1, nPos - 1)
	end
	if bFallbackServerName and not szServerName then
		szServerName = X.GetServerOriginName()
	end
	return szGlobalName, szServerName
end

-- 格式化原始角色名
---@param szName string @角色名
---@return string @去除跨服服务器后缀的角色名
function X.ExtractPlayerOriginName(szName)
	return (X.DisassemblePlayerGlobalName(szName))
end

-- 拼接角色完整名
---@param szName string @角色原始名
---@param szSuffix? string @角色后缀名
---@param szServerName? string @角色服务器名
---@return string @角色完整名
function X.AssemblePlayerName(szName, szSuffix, szServerName)
	if szSuffix then
		szName = szName .. szSuffix
	end
	if szServerName then
		szName = szName .. g_tStrings.STR_CONNECT .. szServerName
	end
	return szName
end

-- 拆分角色名、后缀、角色服务器
---@param szGlobalName string @角色跨服名，本服可不加后缀
---@param bFallbackServerName boolean @角色名不包含服务器时是否视为当前主服务器角色
---@return string, string, string | nil @角色原始名, 角色后缀名, 角色所在服务器名
function X.DisassemblePlayerName(szGlobalName, bFallbackServerName)
	local nPos, szServerName = X.StringFindW(szGlobalName, g_tStrings.STR_CONNECT), nil
	if nPos then
		szServerName = szGlobalName:sub(nPos + #g_tStrings.STR_CONNECT)
		szGlobalName = szGlobalName:sub(1, nPos - 1)
	end
	if bFallbackServerName and not szServerName then
		szServerName = X.GetServerOriginName()
	end
	local nPos, szSuffix = X.StringFindW(szGlobalName, '@'), ''
	if nPos then
		szSuffix = szGlobalName:sub(nPos)
		szGlobalName = szGlobalName:sub(1, nPos - 1)
	end
	return szGlobalName, szSuffix, szServerName
end

-- 格式化基础角色名
---@param szName string @角色名
---@return string @去除跨服服务器后缀和转服后缀的角色名
function X.ExtractPlayerBaseName(szName)
	return (X.DisassemblePlayerName(szName))
end

--------------------------------------------------------------------------------
-- 其他角色装备信息相关
--------------------------------------------------------------------------------

-- 查看角色装备标记位
local PEEK_PLAYER_ACTION = {}
local function OnPeekOtherPlayerResult(xKey, eState)
	local dwID = X.IsNumber(xKey) and xKey or nil
	local kPlayer = dwID and X.GetPlayer(dwID)
	local szGlobalID = kPlayer and kPlayer.GetGlobalID()
	if not X.IsGlobalID(szGlobalID) then
		szGlobalID = X.IsGlobalID(xKey)
			and xKey
			or nil
	end
	if dwID then
		for _, fnAction in ipairs(PEEK_PLAYER_ACTION[dwID] or X.CONSTANT.EMPTY_TABLE) do
			X.SafeCall(fnAction, dwID, eState, kPlayer)
		end
		PEEK_PLAYER_ACTION[dwID] = nil
		X.DelayCall('LIB#PeekOtherPlayer#' .. dwID, false)
	end
	if szGlobalID then
		for _, fnAction in ipairs(PEEK_PLAYER_ACTION[szGlobalID] or X.CONSTANT.EMPTY_TABLE) do
			X.SafeCall(fnAction, szGlobalID, eState, kPlayer)
		end
		PEEK_PLAYER_ACTION[szGlobalID] = nil
		X.DelayCall('LIB#PeekOtherPlayer#' .. szGlobalID, false)
	end
end
X.RegisterEvent('PEEK_OTHER_PLAYER', function()
	OnPeekOtherPlayerResult(arg1, arg0)
end)

-- 获取其他角色对象
---@param dwID number @要获取的角色ID
---@param fnAction? fun(dwID: number, eState: number, kPlayer: userdata?): void @回调函数
function X.PeekOtherPlayerByID(dwID, fnAction)
	if not PEEK_PLAYER_ACTION[dwID] then
		PEEK_PLAYER_ACTION[dwID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[dwID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. dwID, 1000, function()
		OnPeekOtherPlayerResult(dwID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(dwID, true)
end

-- 获取其他角色对象
---@param szGlobalID string @要获取的角色唯一ID
---@param fnAction? fun(szGlobalID: string, eState: number, kPlayer: userdata?): void @回调函数
function X.PeekOtherPlayerByGlobalID(dwServerID, szGlobalID, fnAction)
	if not PEEK_PLAYER_ACTION[szGlobalID] then
		PEEK_PLAYER_ACTION[szGlobalID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[szGlobalID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. szGlobalID, 1000, function()
		OnPeekOtherPlayerResult(szGlobalID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(nil, true, dwServerID, szGlobalID)
end

-- 查看其他角色装备
---@param dwID number @要查看的角色ID
---@param fnAction? fun(dwID: number, eState: number, kPlayer: userdata?): void @回调函数
function X.ViewOtherPlayerByID(dwID, fnAction)
	if not PEEK_PLAYER_ACTION[dwID] then
		PEEK_PLAYER_ACTION[dwID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[dwID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. dwID, 1000, function()
		OnPeekOtherPlayerResult(dwID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(dwID, false)
end

-- 查看其他角色装备
---@param szGlobalID string @要查看的角色唯一ID
---@param fnAction? fun(szGlobalID: string, eState: number, kPlayer: userdata?): void @回调函数
function X.ViewOtherPlayerByGlobalID(dwServerID, szGlobalID, fnAction)
	if not PEEK_PLAYER_ACTION[szGlobalID] then
		PEEK_PLAYER_ACTION[szGlobalID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[szGlobalID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. szGlobalID, 1000, function()
		OnPeekOtherPlayerResult(szGlobalID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(nil, false, dwServerID, szGlobalID)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
