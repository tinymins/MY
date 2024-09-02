--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Object')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 获取目标类型（仅支持NPC或玩家）
---@param dwID number @目标ID
---@return number @目标类型
function X.GetTargetType(dwID)
	if X.IsPlayer(dwID) then
		return TARGET.PLAYER
	end
	return TARGET.NPC
end

-- 获取目标气血和最大气血
---@param kTar userdata @目标对象
---@return number @目标气血，最大气血
function X.GetTargetLife(kTar)
	if not kTar then
		return
	end
	return X.IS_REMAKE and kTar.fCurrentLife64 or kTar.nCurrentLife,
		X.IS_REMAKE and kTar.fMaxLife64 or kTar.nMaxLife
end

-- 获取目标内力和最大内力
---@param kTar userdata @目标对象
---@return number @目标内力，最大内力
function X.GetTargetMana(kTar)
	if not kTar then
		return
	end
	return kTar.nCurrentMana, kTar.nMaxMana
end

do
local CACHE = {}
local function GetTargetSceneIndex(dwID)
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if not X.IsMonsterMap(me.GetMapID()) then
		return
	end
	local scene = me.GetScene()
	if not scene then
		return
	end
	local nType = X.IsPlayer(dwID) and 0 or 1
	local nIndex = CACHE[dwID]
	if not nIndex or scene.GetTempCustomUnsigned4(1, nIndex * 20 + 1) ~= dwID then
		for i = 0, 9 do
			local nOffset = i * 20 + 1
			if scene.GetTempCustomUnsigned4(nType, nOffset) == dwID then
				CACHE[dwID] = i
				nIndex = i
				break
			end
		end
	end
	return scene, nType, nIndex
end

-- 获取目标精力和最大精力
---@param kTar userdata | number @目标对象或目标ID
---@return number @目标精力，最大精力
function X.GetTargetSpirit(kTar)
	local scene, nType, nIndex = GetTargetSceneIndex(X.IsUserdata(kTar) and kTar.dwID or kTar)
	if scene and nType and nIndex then
		return scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 4),
			scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 8)
	end
end

-- 获取目标耐力和最大耐力
---@param obj userdata | number @目标对象或目标ID
---@return number @目标耐力，最大耐力
function X.GetTargetEndurance(obj)
	local scene, nType, nIndex = GetTargetSceneIndex(X.IsUserdata(obj) and obj.dwID or obj)
	if scene and nType and nIndex then
		return scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 12),
			scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 16)
	end
end
end

-- 求N2在N1的面向角  --  重载+2
-- (number) X.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) X.GetFaceAngel(oN1, oN2, bAbs)
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
function X.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
	if type(nY) == 'userdata' and type(nX) == 'userdata' then
		nX, nY, nFace, nTX, nTY, bAbs = nX.nX, nX.nY, nX.nFaceDirection, nY.nX, nY.nY, nFace
	end
	if type(nX) == 'number' and type(nY) == 'number' and type(nFace) == 'number'
	and type(nTX) == 'number' and type(nTY) == 'number' then
		local nFace = (nFace * 2 * math.pi / 255) - math.pi
		local nSight = (nX == nTX and ((nY > nTY and math.pi / 2) or - math.pi / 2)) or math.atan((nTY - nY) / (nTX - nX))
		local nAngel = ((nSight - nFace) % (math.pi * 2) - math.pi) / math.pi * 180
		if bAbs then
			nAngel = math.abs(nAngel)
		end
		return nAngel
	end
end

--------------------------------------------------------------------------------
-- 角色状态
--------------------------------------------------------------------------------

-- 获取对象是否无敌
-- (mixed) X.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function X.IsInvincible(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return nil
	elseif X.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end

-- 获取对象是否被隔离
-- (mixed) X.IsIsolated([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object isolated state
function X.IsIsolated(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return false
	end
	if X.IS_CLASSIC then
		return false
	end
	return KObject.bIsolated
end

--------------------------------------------------------------------------------
-- 角色模型屏蔽状态
--------------------------------------------------------------------------------

do
local CURRENT_NPC_SHOW_ALL = true
local CURRENT_PLAYER_SHOW_ALL = true
local CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = false
X.RegisterEvent('ON_REPRESENT_CMD', 'LIB#PLAYER_DISPLAY_MODE', function()
	if arg0 == 'show npc' then
		CURRENT_NPC_SHOW_ALL = true
	elseif arg0 == 'hide npc' then
		CURRENT_NPC_SHOW_ALL = false
	elseif arg0 == 'show player' then
		CURRENT_PLAYER_SHOW_ALL = true
	elseif arg0 == 'hide player' then
		CURRENT_PLAYER_SHOW_ALL = false
	elseif arg0 == 'show or hide party player 1' then
		CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = true
	elseif arg0 == 'show or hide party player 0' then
		CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = false
	end
end)

--- 获取 NPC 显示状态
---@return boolean @NPC 是否显示
function X.GetNpcVisibility()
	return CURRENT_NPC_SHOW_ALL
end

--- 设置 NPC 显示状态
---@param bShow boolean @NPC 是否显示
function X.SetNpcVisibility(bShow)
	if bShow then
		rlcmd('show npc')
	else
		rlcmd('hide npc')
	end
end

--- 获取玩家显示状态
---@return boolean, boolean @玩家是否显示 @队友是否强制显示
function X.GetPlayerVisibility()
	if UIGetPlayerDisplayMode and PLAYER_DISPLAY_MODE then
		local eMode = UIGetPlayerDisplayMode()
		if eMode == PLAYER_DISPLAY_MODE.ALL then
			return true, true
		end
		if eMode == PLAYER_DISPLAY_MODE.ONLY_PARTY then
			return false, true
		end
		if eMode == PLAYER_DISPLAY_MODE.ONLY_SELF then
			return false, false
		end
		return true, false
	end
	return CURRENT_PLAYER_SHOW_ALL, CURRENT_PLAYER_SHOW_PARTY_OVERRIDE
end

--- 设置玩家显示状态
---@param bShowAll boolean @玩家是否显示
---@param bShowPartyOverride boolean @队友是否强制显示
function X.SetPlayerVisibility(bShowAll, bShowPartyOverride)
	if UISetPlayerDisplayMode and PLAYER_DISPLAY_MODE then
		if bShowAll then
			return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ALL)
		end
		if bShowPartyOverride then
			return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ONLY_PARTY)
		end
		return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ONLY_SELF)
	end
	if bShowAll then
		rlcmd('show player')
	else
		rlcmd('hide player')
	end
	if bShowPartyOverride then
		rlcmd('show or hide party player 1')
	else
		rlcmd('show or hide party player 0')
	end
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
