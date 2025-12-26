--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录 发放投票相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKPVote'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

-- 工资结算
local TEAM_VOTE_REQUEST = {}
X.RegisterEvent('TEAM_VOTE_REQUEST', function()
	if arg0 == 1 then
		TEAM_VOTE_REQUEST = {}
		local team = GetClientTeam()
		for k, v in ipairs(team.GetTeamMemberList()) do
			TEAM_VOTE_REQUEST[v] = false
		end
	end
end)

X.RegisterEvent('TEAM_VOTE_RESPOND', function()
	if arg0 == 1 and not X.IsEmpty(TEAM_VOTE_REQUEST) then
		if arg2 == 1 then
			TEAM_VOTE_REQUEST[arg1] = true
		end
		local team  = GetClientTeam()
		local num   = team.GetTeamSize()
		local agree = 0
		for k, v in pairs(TEAM_VOTE_REQUEST) do
			if v then
				agree = agree + 1
			end
		end
		X.OutputAnnounceMessage(_L('Team Members: %d, %d agree %d%%', num, agree, agree / num * 100))
	end
end)

X.RegisterEvent('TEAM_INCOMEMONEY_CHANGE_NOTIFY', function()
	local nTotalRaidMoney = GetClientTeam().nInComeMoney
	if nTotalRaidMoney and nTotalRaidMoney == 0 then
		TEAM_VOTE_REQUEST = {}
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
