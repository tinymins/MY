--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·账户
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Account')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local CURRENT_ACCOUNT
function X.GetAccount()
	if X.IsNil(CURRENT_ACCOUNT) then
		if not CURRENT_ACCOUNT and Login_GetAccount then
			local bSuccess, szAccount = X.XpCall(Login_GetAccount)
			if bSuccess and not X.IsEmpty(szAccount) then
				CURRENT_ACCOUNT = szAccount
			end
		end
		if not CURRENT_ACCOUNT and GetUserAccount then
			local bSuccess, szAccount = X.XpCall(GetUserAccount)
			if bSuccess and not X.IsEmpty(szAccount) then
				CURRENT_ACCOUNT = szAccount
			end
		end
		if not CURRENT_ACCOUNT then
			local bSuccess, hFrame = X.XpCall(function() return X.UI.OpenFrame('LoginPassword') end)
			if bSuccess and hFrame then
				local hEdit = hFrame:Lookup('WndPassword/Edit_Account')
				if hEdit then
					CURRENT_ACCOUNT = hEdit:GetText()
				end
				X.UI.CloseFrame(hFrame)
			end
		end
		if not CURRENT_ACCOUNT then
			CURRENT_ACCOUNT = false
		end
	end
	return CURRENT_ACCOUNT or nil
end
end

if _G.Login_GetTimeOfFee then
	function X.GetTimeOfFee()
		-- [仅客户端使用]返回帐号月卡截止时间，计点剩余秒数，计天剩余秒数和总截止时间
		local dwMonthEndTime, nPointLeftTime, nDayLeftTime, dwEndTime = _G.Login_GetTimeOfFee()
		if dwMonthEndTime <= 1229904000 then
			dwMonthEndTime = 0
		end
		return dwEndTime, dwMonthEndTime, nPointLeftTime, nDayLeftTime
	end
else
	local bInit, dwMonthEndTime, dwPointEndTime, dwDayEndTime = false, 0, 0, 0
	local frame = Station.Lookup('Lowest/Scene')
	local data = frame and frame[X.NSFormatString('{$NS}_TimeOfFee')]
	if data then
		bInit, dwMonthEndTime, dwPointEndTime, dwDayEndTime = true, X.Unpack(data)
	else
		X.RegisterMsgMonitor('MSG_SYS', 'LIB#GetTimeOfFee', function(szChannel, szMsg)
			-- 点卡剩余时间为：558小时41分33秒
			local szHour, szMinute, szSecond = szMsg:match(_L['Point left time: (%d+)h(%d+)m(%d+)s'])
			if szHour and szMinute and szSecond then
				local dwTime = GetCurrentTime()
				bInit = true
				dwPointEndTime = dwTime + tonumber(szHour) * 3600 + tonumber(szMinute) * 60 + tonumber(szSecond)
			end
			-- 您的月卡剩余总时间：49天19小时
			local szDay, szHour = szMsg:match(_L['Month time left days: (%d+)d(%d+)h'])
			if szDay and szHour then
				local dwTime = GetCurrentTime()
				bInit = true
				dwPointEndTime = dwTime + tonumber(szDay) * 3600 * 24 + tonumber(szHour) * 3600
			end
			-- 包月时间截止至：xxxx/xx/xx xx:xx
			local szYear, szMonth, szDay, szHour, szMinute = szMsg:match(_L['Month time to: (%d+)y(%d+)m(%d+)d (%d+)h(%d+)m'])
			if szYear and szMonth and szDay and szHour and szMinute then
				bInit = true
				dwMonthEndTime = X.DateToTime(szYear, szMonth, szDay, szHour, szMinute, 0)
			end
			if bInit then
				local dwTime = GetCurrentTime()
				if dwMonthEndTime > dwTime then -- 优先消耗月卡 即点卡结束时间需要加上月卡时间
					dwPointEndTime = dwPointEndTime + dwMonthEndTime - dwTime
				end
				local frame = Station.Lookup('Lowest/Scene')
				if frame then
					frame[X.NSFormatString('{$NS}_TimeOfFee')] = X.Pack(dwMonthEndTime, dwPointEndTime, dwDayEndTime)
				end
				X.RegisterMsgMonitor('MSG_SYS', 'LIB#GetTimeOfFee', false)
			end
		end)
	end
	function X.GetTimeOfFee()
		local dwTime = GetCurrentTime()
		local dwEndTime = math.max(dwMonthEndTime, dwPointEndTime, dwDayEndTime)
		return dwEndTime, dwMonthEndTime, math.max(dwPointEndTime - dwTime, 0), math.max(dwDayEndTime - dwTime, 0)
	end
end

-- 登出游戏
-- (void) X.Logout(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
function X.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end

do
local bExiting = false
X.RegisterEvent('PLAYER_EXIT_GAME', function()
	bExiting = true
end)
---游戏是否处于退出状态
---@return boolean 是否正在退出
function X.IsGameExiting()
	return bExiting
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
