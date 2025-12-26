--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : JX3BOX 分页
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JB.PS'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TeamTools_JB', { ['*'] = false })
--------------------------------------------------------------------------

local PS = {
	-- nPriority = 0,
	-- bWelcome = true,
}

function PS.IsRestricted()
	if X.IsDebugServer() then
		return true
	end
	return X.IsRestricted('MY_TeamTools_JB')
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY, LH = 20, 20, 30
	local nW, nH = ui:Size()
	local nX, nY, nLFY = nPaddingX, nPaddingY, nPaddingY

	-- 角色认证
	nX, nY, nLFY = MY_JBBind.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)

	-- 快捷入团
	nX = nPaddingX
	nLFY = nLFY + 5
	nX, nY, nLFY = MY_JBTeam.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)

	-- 赛事上报
	nX = nPaddingX
	nLFY = nLFY + 5
	nX, nY, nLFY = MY_JBAchievementRank.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)
	nX, nY, nLFY = MY_CombatLogs.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)

	-- 数据同步
	nLFY = nLFY + 5
	nX = nPaddingX
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Data sync'], font = 27 }):Height() + 2
	nX = nPaddingX + 10
	nX, nY, nLFY = MY_JBLoverSync.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)
	nX = nX + 5
	nX, nY, nLFY = MY_JBAchievementSync.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)

	-- 赛事投票
	nX = nPaddingX
	nLFY = nLFY + 5
	nX, nY, nLFY = MY_JBEventVote.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)

	-- 团队快照
	nX = nPaddingX
	nLFY = nLFY + 5
	nX, nY, nLFY = MY_JBTeamSnapshot.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, LH, nX, nY, nLFY)
end

X.Panel.Register(_L['Raid'], 'MY_JX3BOX', _L['Team Platform'], 5962, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
