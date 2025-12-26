--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.SafeLock')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.IsPhoneLock()
	local me = X.GetClientPlayer()
	return me and me.IsTradingMibaoSwitchOpen()
end

function X.IsAccountInDanger()
	local me = X.GetClientPlayer()
	return me.nAccountSecurityState == ACCOUNT_SECURITY_STATE.DANGER
end

function X.IsSafeLocked(nType)
	local me = X.GetClientPlayer()
	if nType == SAFE_LOCK_EFFECT_TYPE.TALK then -- 聊天锁比较特殊
		if _G.SafeLock_IsTalkLocked and _G.SafeLock_IsTalkLocked() then
			return true
		end
	else
		if X.IsAccountInDanger() then
			return true
		end
	end
	if me.CheckSafeLock then
		local bLock = not me.CheckSafeLock(nType)
		if bLock then
			return true
		end
	elseif me.GetSafeLockMaskInfo then
		local tLock = me.GetSafeLockMaskInfo()
		if tLock and tLock[SAFE_LOCK_EFFECT_TYPE.TALK] then
			return true
		end
	end
	return false
end

function X.IsTradeLocked()
	if X.IsAccountInDanger() then
		return true
	end
	local me = X.GetClientPlayer()
	return me.bIsBankPasswordVerified == false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
