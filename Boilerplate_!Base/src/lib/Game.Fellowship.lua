--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Fellowship')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 好友相关接口
--------------------------------------------------------------------------------

---获取好友分组
---@return table @好友分组列表
function X.GetFellowshipGroupInfoList()
	local aList
	local smc = X.GetSocialManagerClient()
	if smc then
		aList = smc.GetFellowshipGroupInfo()
	else
		local me = X.GetClientPlayer()
		if me then
			aList = me.GetFellowshipGroupInfo()
		end
	end
	-- 默认分组
	if aList then
		table.insert(aList, 1, {
			id = 0,
			name = g_tStrings.STR_FRIEND_GOOF_FRIEND or '',
		})
	end
	return aList
end

---获取指定好友分组的好友列表
---@param nGroupID number @要获取的好友分组ID
---@return table @该分组下的玩家信息列表
function X.GetFellowshipInfoList(nGroupID)
	-- 组ID可以直接调用官方接口
	if X.IsNumber(nGroupID) then
		local smc = X.GetSocialManagerClient()
		if smc then
			return smc.GetFellowshipInfo(nGroupID)
		end
		local me = X.GetClientPlayer()
		if me then
			return me.GetFellowshipInfo(nGroupID)
		end
	end
end

do
local FELLOWSHIP_CACHE
local function OnFellowshipUpdate()
	FELLOWSHIP_CACHE = nil
end
X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_FOE_UPDATE'            , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , OnFellowshipUpdate)
X.RegisterEvent('DELETE_FELLOWSHIP'            , OnFellowshipUpdate)
X.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', OnFellowshipUpdate)

-- 获取好友
---@param xPlayerID number | string @要获取的玩家名称或ID
---@return table @匹配的玩家信息
function X.GetFellowshipInfo(xPlayerID)
	if not FELLOWSHIP_CACHE then
		local me = X.GetClientPlayer()
		if me then
			local aGroupInfo = X.GetFellowshipGroupInfoList()
			if aGroupInfo then
				FELLOWSHIP_CACHE = {}
				for _, tGroup in ipairs(aGroupInfo) do
					for _, tInfo in ipairs(X.GetFellowshipInfoList(tGroup.id) or {}) do
						FELLOWSHIP_CACHE[tInfo.id] = tInfo
						if tInfo.name then
							FELLOWSHIP_CACHE[tInfo.name] = tInfo
						else
							local info = X.GetPlayerEntryInfo(tInfo.id)
							if info then
								FELLOWSHIP_CACHE[info.dwPlayerID] = tInfo
								FELLOWSHIP_CACHE[info.szName] = tInfo
							end
						end
					end
				end
			end
		end
	end
	return FELLOWSHIP_CACHE and X.Clone(FELLOWSHIP_CACHE[xPlayerID])
end

-- 判断是否是好友
---@param xPlayerID number | string @要判断的玩家名称或ID
---@return boolean @是否是好友
function X.IsFellowship(xPlayerID)
	return X.GetFellowshipInfo(xPlayerID) and true or false
end

-- 遍历好友
---@param fnIter function @迭代器，返回0时停止迭代
function X.IterFellowshipInfo(fnIter)
	local aGroup = X.GetFellowshipGroupInfoList() or {}
	table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFellowshipInfo = X.GetFellowshipInfoList(v.id) or {}
		for _, info in ipairs(aFellowshipInfo) do
			if fnIter(info, v.id) == 0 then
				return
			end
		end
	end
end
end

---申请好友名片
---@param xPlayerID string | string[] @要申请的玩家唯一ID或者唯一ID列表（缘起为 dwID）
function X.ApplyFellowshipCard(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.ApplyFellowshipCard(xPlayerID)
	end
	local fcc = X.GetFellowshipCardClient()
	if fcc then
		return fcc.ApplyFellowshipCard(255, xPlayerID)
	end
end

---获取玩家名片信息
---@param xPlayerID number @要获取的玩家唯一ID（缘起为 dwID）
---@return table @玩家的名片信息
function X.GetFellowshipCardInfo(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.GetFellowshipCardInfo(xPlayerID)
	end
	local info = X.GetFellowshipInfo(xPlayerID)
	local fcc = X.GetFellowshipCardClient()
	local card = info and fcc and fcc.GetFellowshipCardInfo(info.id)
	if card then
		return {
			dwLandMapID = card.dwLandMapID,
			nLandIndex = card.nLandIndex,
			Praiseinfo = card.Praiseinfo,
			nPHomeCopyIndex = card.nPHomeCopyIndex,
			nLandCopyIndex = card.nLandCopyIndex,
			dwPHomeSkin = card.dwPHomeSkin,
			bIsTwoWayFriend = info.istwoway,
			dwPHomeMapID = card.dwPHomeMapID,
		}
	end
end

---获取玩家所在地图
---@param xPlayerID number @要获取的玩家唯一ID（缘起为 dwID）
---@return boolean @玩家所在地图
function X.GetFellowshipMapID(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.GetFellowshipMapID(xPlayerID)
	end
	local info = X.GetFellowshipInfo(xPlayerID)
	local fcc = X.GetFellowshipCardClient()
	local card = info and fcc and fcc.GetFellowshipCardInfo(info.id)
	if card then
		return card.dwMapID
	end
end

--------------------------------------------------------------------------------
-- 仇人相关接口
--------------------------------------------------------------------------------
do
local FOE_LIST, FOE_CACHE
local function GetFoeInfo()
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.GetFoeInfo()
	end
	local me = X.GetClientPlayer()
	if me and me.GetFoeInfo then
		return me.GetFoeInfo()
	end
end
local function GeneFoeCache()
	if not FOE_LIST then
		local aInfo = GetFoeInfo()
		if aInfo then
			FOE_LIST = {}
			FOE_CACHE = {}
			for i, p in ipairs(aInfo) do
				FOE_CACHE[p.id] = p
				if p.name then
					FOE_CACHE[p.name] = p
				else
					local info = X.GetPlayerEntryInfo(p.id)
					if info then
						FOE_CACHE[info.dwPlayerID] = p
						FOE_CACHE[info.szName] = p
					end
				end
				table.insert(FOE_LIST, p)
			end
			return true
		end
		return false
	end
	return true
end
local function OnFoeUpdate()
	FOE_LIST = nil
	FOE_CACHE = nil
end
X.RegisterEvent('PLAYER_FOE_UPDATE', OnFoeUpdate)

-- 获取仇人列表
---@return table @仇人列表
function X.GetFoeInfoList()
	if GeneFoeCache() then
		return X.Clone(FOE_LIST)
	end
end

-- 获取仇人
---@param xPlayerID number | string @仇人名称或仇人ID
---@return userdata @仇人对象
function X.GetFoeInfo(xPlayerID)
	if xPlayerID and GeneFoeCache() then
		return FOE_CACHE[xPlayerID]
	end
end
end

-- 判断是否是仇人
---@param xPlayerID number | string @要判断的玩家名称或ID
---@return boolean @是否是仇人
function X.IsFoe(xPlayerID)
	return X.GetFoeInfo(xPlayerID) and true or false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
