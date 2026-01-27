--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 云世界标记
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_YunWorldMark'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_YunWorldMark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^29.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local FRAME_NAME = 'MY_YunWorldMark'
local D = {}

function D.OpenPanel(szModule)
	local ui = X.UI.CreateFrame(FRAME_NAME, {
		w = 760,
		h = 520,
		close = true,
		resize = true,
		minWidth = 760,
		minHeight = 520,
		text = X.PACKET_INFO.NAME .. _L.SPLIT_DOT .. _L[MODULE_NAME],
		anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = -100 },
		onSizeChange = function()
			local ui = X.UI(this)
			local nW, nH = ui:Size()
			ui:Children('#Btn_Option'):Left(nW - 40)
			ui:Children('#PageSet_All'):Size(nW, nH - 48)
			D.PageSetModule.BroadcastPageEvent(this, 'OnResizePage')
		end,
	})
	ui:Append('WndPageSet', { name = 'PageSet_All', x = 0, y = 48, w = 760, h = 520 - 48 })
	ui:Append('WndButton', {
		name = 'Btn_Option',
		x = 760 - 40, y = 54, w = 20, h = 20,
		buttonStyle = 'OPTION',
		menu = function()
			return {
				{
					szOption = _L['Get current mark data'],
					fnAction = function()
						X.UI.ClosePopupMenu()
						MY_YunWorldMark_Subscribe.ShowSceneWorldMark()
					end,
				},
				{
					szOption = _L['Restore world mark position'],
					fnAction = function()
						X.UI.ClosePopupMenu()
						X.UI.GetUserInput({
							title = _L['Please input world mark json:'],
							initialValue = '',
							multiline = true,
							maxLength = 99999,
							fnAction = function(szText)
								if X.IsEmpty(szText) then
									return
								end
								local data = X.DecodeJSON(szText)
								if not X.IsTable(data) then
									X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
									return
								end
								D.ApplyWorldMark(data)
							end,
						})
					end,
				},
				{
					szOption = _L['Manage my online world mark'],
					fnAction = function()
						X.OpenBrowser('https://j3cx.com/world-mark/mine')
						X.UI.ClosePopupMenu()
					end,
				},
			}
		end,
	})
	local frame = ui:Raw()
	frame:BringToTop()
	D.PageSetModule.DrawUI(frame)
	D.PageSetModule.ActivePage(frame, szModule or 1, true)
end

function D.ClosePanel()
	X.UI.CloseFrame(FRAME_NAME)
end

function D.IsPanelOpened()
	return Station.Lookup('Normal/' .. FRAME_NAME)
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
	D.PageSetModule.RegisterModule(szKey, szName, tModule)
	if D.IsPanelOpened() then
		D.ClosePanel()
		D.OpenPanel()
	end
end

--------------------------------------------------------------------------------
-- 世界标记应用
--------------------------------------------------------------------------------

function D.ApplyWorldMark(aList)
	if type(SetWorldMark) ~= 'function' then
		X.OutputAnnounceMessage(_L['Failed.'])
		return
	end
	if not X.IsTable(aList) then
		X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
		return
	end

	local nWillApply = 0
	for i, pt in ipairs(aList) do
		if X.IsTable(pt) then
			local nX = tonumber(pt.x) or 0
			local nY = tonumber(pt.y) or 0
			local nZ = tonumber(pt.z) or 0
			if not (nX == 0 and nY == 0 and nZ == 0) then
				local nIndex = tonumber(pt.mark) or i
				if nIndex > 0 then
					nWillApply = nWillApply + 1
				end
			end
		end
	end

	X.Confirm(_L('About to clear all current world marks and set %d new world marks, continue?', nWillApply), function()
		SetWorldMark(0)

		local nApplied = 0
		for i, pt in ipairs(aList) do
			if X.IsTable(pt) then
				local nX = tonumber(pt.x) or 0
				local nY = tonumber(pt.y) or 0
				local nZ = tonumber(pt.z) or 0
				if not (nX == 0 and nY == 0 and nZ == 0) then
					local nIndex = tonumber(pt.mark) or i
					if nIndex > 0 then
						SetWorldMark(nIndex, nX, nY, nZ)
						nApplied = nApplied + 1
					end
				end
			end
		end

		X.OutputAnnounceMessage(_L('Done, %s marks applied.', tostring(nApplied)))
	end)
end

function D.ApplyYunWorldMark(szURL)
	if X.IsEmpty(szURL) then
		return
	end
	if type(SetWorldMark) ~= 'function' then
		X.OutputAnnounceMessage(_L['Failed.'])
		return
	end

	local LUA_CONFIG = { passphrase = false, crc = false, compress = false }
	X.FetchLUAData(szURL, LUA_CONFIG)
		:Then(function(data)
			if not data then
				X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
				return
			end
			D.ApplyWorldMark(data)
		end)
		:Catch(function(error)
			X.OutputAnnounceMessage((error and error.message) or _L['Failed.'])
		end)
end

D.PageSetModule = X.UI.CreatePageSetModule(D, 'Wnd_Total/PageSet_All')

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenPanel',
				'ClosePanel',
				'TogglePanel',
				'IsPanelOpened',
				'RegisterModule',
				'ApplyWorldMark',
				'ApplyYunWorldMark',
			},
			root = D,
		},
	},
}
MY_YunWorldMark = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
