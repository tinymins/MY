--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 聊天记录 设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_ExportDB'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_ChatLog.RealtimeCommit', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local D = {
	bExporting = false,
}
local EXPORT_SLICE = 100

function D.Start(szExportFile, aMsgType, nPerSec, onProgress)
	if D.bExporting then
		return X.OutputSystemMessage(_L['Already exporting, please wait.'])
	end
	local ds = MY_ChatLog_DS(MY_ChatLog.GetRoot())
	if not ds then
		return
	end
	local db = MY_ChatLog_DB(szExportFile)
	if not db:Connect() then
		return
	end
	db:SetMinTime(0)
	db:SetMaxTime(math.huge)
	db:SetInfo('version', '2')
	db:SetInfo('user_global_id', X.GetClientPlayerGlobalID())
	D.bExporting = true

	if onProgress then
		onProgress(_L['Preparing'], 0)
	end

	local nPage, nPageCount = 0, math.ceil(ds:CountMsg(aMsgType, '') / EXPORT_SLICE)
	local function Export()
		if nPage > nPageCount then
			D.bExporting = false
			db:Disconnect()
			local szFile = X.GetAbsolutePath(szExportFile)
			X.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
			X.OutputSystemMessage(_L('Chatlog export succeed, file saved as %s', szFile))
			return 0
		end
		local data = ds:SelectMsg(aMsgType, '', nil, nil, nPage * EXPORT_SLICE, EXPORT_SLICE, true)
		for i, rec in ipairs(data) do
			db:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
		end
		if onProgress then
			onProgress(_L['exporting'], nPage / nPageCount)
		end
		db:Flush()
		nPage = nPage + 1
	end
	X.BreatheCall('MY_ChatLog_ExportDB', Export)
end

function D.IsRunning()
	return D.bExporting
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatLog_ExportDB',
	exports = {
		{
			fields = {
				'Start',
				'IsRunning',
			},
			root = D,
		},
	},
}
MY_ChatLog_ExportDB = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
