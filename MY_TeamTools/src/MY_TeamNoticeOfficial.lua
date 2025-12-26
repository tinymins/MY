--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队告示
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamNoticeOfficial'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {
	bEnable = not not NoticeBoard_Open,
}

function D.ApplyNoticeBoard()
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		X.DelayCall('MY_TeamNoticeOfficial__ApplyNoticeBoard', 500, D.ApplyNoticeBoard)
		return
	end
	ApplyNoticeBoard(1)
end

function D.OpenFrame()
	if not D.bEnable then
		return
	end
	if X.IsClientPlayerInParty() then
		if X.IsClientPlayerTeamLeader() then
			NoticeBoard_Open(1)
		else
			D.ApplyNoticeBoard()
			X.OutputSystemMessage(_L['Asking..., If no response in longtime, team leader not enable plug-in.'])
		end
	end
end

function D.UpdateHookFrame(hFrame, bForce)
	if not hFrame then
		return
	end
	local nW, nH = hFrame:GetSize()
	if not bForce and hFrame.__nMY_TeamNotice_W == nW and hFrame.__nMY_TeamNotice_H == nH then
		return
	end
	local hEdit = hFrame:Lookup('Edit_Text')
	local hEditBg = hFrame:Lookup('', 'Handle_Bg/Image_TextEditBg')
	local hEditMaxText = hFrame:Lookup('', 'Handle_Bg/Text_TextMax')
	nW = nW - 24
	hEdit:SetH(nH - 89 - 30)
	hEditBg:SetH(nH - 89 - 30)
	hEditMaxText:SetRelY(nH - 17 - 30)
	hEditMaxText:SetAbsY(hFrame:GetAbsY() + nH - 17 - 30 - 15)

	local ui = X.UI(hFrame)
	local nX = 12
	local nY = nH - 40
	local nItemW = (nW + 5) / 3 - 5
	local uiBtnRaidTools = ui:Fetch('WndBtn_RaidTools')
	if uiBtnRaidTools:Count() == 0 then
		uiBtnRaidTools = ui:Append('WndButton', {
			name = 'WndBtn_RaidTools',
			text = _L['MY_TeamTools'],
			buttonStyle = 'FLAT',
			onClick = MY_TeamTools.Toggle,
		})
	end
	uiBtnRaidTools:Pos(nX, nY):Width(nItemW)

	local uiBtnGKP = ui:Fetch('WndBtn_GKP')
	if uiBtnGKP:Count() == 0 then
		uiBtnGKP = ui:Append('WndButton', {
			name = 'WndBtn_GKP',
			text = _L['GKP Golden Team Record'],
			buttonStyle = 'FLAT',
			onClick = function()
				if MY_GKP then
					MY_GKP_MI.TogglePanel()
				else
					X.Alert(_L['You haven\'t had MY_GKP installed and loaded yet.'])
				end
			end,
		})
	end
	uiBtnGKP:Pos(nX + nItemW + 5, nY):Width(nItemW)

	local uiBtnTeamMon = ui:Fetch('WndBtn_TeamMon')
	if uiBtnTeamMon:Count() == 0 then
		uiBtnTeamMon = ui:Append('WndButton', {
			name = 'WndBtn_TeamMon',
			text = _L['Import Data'],
			buttonStyle = 'FLAT',
			onClick = MY_TeamMon_Subscribe.OpenPanel,
		})
	end
	uiBtnTeamMon:Pos(nX + (nItemW + 5) * 2, nY):Width(nItemW)
end

function D.UpdateHook(bForce)
	for i = 1, 1 do
		local hFrame = Station.Lookup('Normal/NoticeBoard' .. i)
		D.UpdateHookFrame(hFrame, bForce)
	end
end

X.RegisterEvent('FIRST_LOADING_END', 'TEAM_NOTICE', function()
	if not D.bEnable then
		return
	end
	-- 不存在队长不队长的问题了
	if X.IsClientPlayerInParty() then
		D.ApplyNoticeBoard()
	end
end)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamNoticeOfficial',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'bEnable',
				'OpenFrame',
			},
			root = D,
		},
	},
}
MY_TeamNoticeOfficial = X.CreateModule(settings)
end

if D.bEnable then
	X.BreatheCall('MY_TeamNoticeOfficial', function() D.UpdateHook() end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
