--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队告示
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamNoticeOfficial'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.0') then
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
	if X.IsInParty() then
		if X.IsLeader() then
			NoticeBoard_Open(1)
		else
			D.ApplyNoticeBoard()
			X.Sysmsg(_L['Asking..., If no response in longtime, team leader not enable plug-in.'])
		end
	end
end

X.RegisterEvent('FIRST_LOADING_END', 'TEAM_NOTICE', function()
	if not D.bEnable then
		return
	end
	-- 不存在队长不队长的问题了
	if X.IsInParty() then
		D.ApplyNoticeBoard()
	end
end)

-- Global exports
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
