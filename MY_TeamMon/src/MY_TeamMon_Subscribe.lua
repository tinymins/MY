--------------------------------------------------------------------------------
-- v is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队监控订阅界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_Subscribe'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local D = {}

function D.OpenPanel(szModule)
	local ui = X.UI.CreateFrame('MY_TeamMon_Subscribe', {
		w = 1000, h = 700,
		close = true,
		text = X.PACKET_INFO.NAME .. _L.SPLIT_DOT .. _L['MY_TeamMon_Subscribe'],
		anchor = 'CENTER',
	})
	ui:Append('WndPageSet', {
		name = 'PageSet_All',
		x = 0, y = 48, w = 1000, h = 700 - 48,
	})
	ui:Append('WndButton', {
		name = 'Btn_Option',
		x = 960, y = 54, w = 20, h = 20,
		buttonStyle = 'OPTION',
	})
	local frame = ui:Raw()
	frame:BringToTop()
	D.PageSetModule.DrawUI(frame)
	D.PageSetModule.ActivePage(frame, szModule or 1, true)
end

function D.ClosePanel()
	X.UI.CloseFrame('MY_TeamMon_Subscribe')
end

function D.IsPanelOpened()
	return Station.Lookup('Normal/MY_TeamMon_Subscribe')
end

function D.TogglePanel()
	if D.IsPanelOpened() then
		D.ClosePanel()
	else
		D.OpenPanel()
	end
end

-- 注册子模块
function D.RegisterModule(szKey, szName, tModule)
	if not D.PageSetModule or not szName or not tModule then
		return
	end
	if tModule.szFloatEntry then
		table.insert(D.aFloatEntry, { szName = szName, szKey = tModule.szFloatEntry })
	end
	if tModule.szSaveDB then
		table.insert(D.aSaveDB, { szName = szName, szKey = tModule.szSaveDB })
	end
	D.PageSetModule.RegisterModule(szKey, szName, tModule)
	if D.IsPanelOpened() then
		D.ClosePanel()
		D.OpenPanel()
	end
end

D.PageSetModule = X.UI.CreatePageSetModule(D, 'Wnd_Total/PageSet_All')

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_Subscribe',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenPanel',
				'ClosePanel',
				'TogglePanel',
				'IsPanelOpened',
				'RegisterModule',
			},
			root = D,
		},
	},
}
MY_TeamMon_Subscribe = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
