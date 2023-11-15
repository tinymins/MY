--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon_PS'
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local INI_FILE = X.PACKET_INFO.ROOT .. 'MY_TargetMon/ui/MY_TargetMon_PS.ini'
local D = {}

function D.Open()
	Wnd.OpenWindow(INI_FILE, 'MY_TargetMon_PS')
end

function D.Close()
	Wnd.CloseWindow('MY_TargetMon_PS')
end

function D.UpdateConfigActiveState(frame)
	local hList = frame:Lookup('Wnd_Total/WndScroll_Config', 'Handle_ConfigList')
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		hItem:Lookup('Image_ConfigItemBg_Sel'):SetVisible(hItem.config.szUUID == frame.szActiveConfigUUID)
	end
end

function D.DrawConfigList(frame)
	local aConfig = MY_TargetMonConfig.GetConfigList()
	local szActiveConfigUUID
	-- 选中数据
	for _, config in ipairs(aConfig) do
		if not szActiveConfigUUID or config.szUUID == frame.szActiveConfigUUID then
			szActiveConfigUUID = config.szUUID
		end
	end
	frame.szActiveConfigUUID = szActiveConfigUUID
	-- 渲染列表
	local hList = frame:Lookup('Wnd_Total/WndScroll_Config', 'Handle_ConfigList')
	hList:Clear()
	for _, config in ipairs(aConfig) do
		local hItem = hList:AppendItemFromIni(INI_FILE, 'Handle_ConfigItem')
		local aTextColor = config.bEnable and {255, 255, 255} or {192, 192, 192}
		hItem:Lookup('Text_ConfigItemTitle'):SetText(config.szTitle)
		hItem:Lookup('Text_ConfigItemTitle'):SetFontColor(X.Unpack(aTextColor))
		hItem:Lookup('Text_ConfigItemAuthor'):SetText(config.szAuthor)
		hItem:Lookup('Text_ConfigItemAuthor'):SetFontColor(X.Unpack(aTextColor))
		hItem:Lookup('Text_ConfigItemVersion'):SetText(config.szVersion)
		hItem:Lookup('Text_ConfigItemVersion'):SetFontColor(X.Unpack(aTextColor))
		hItem:Lookup('Image_ConfigItemBg_Sel'):SetVisible(config.szUUID == szActiveConfigUUID)
		hItem.config = config
	end
	hList:FormatAllItemPos()
	D.DrawMonitorList(frame)
end

function D.DrawMonitorList(frame)
	local config = MY_TargetMonConfig.GetConfig(frame.szActiveConfigUUID)
	local hList = frame:Lookup('Wnd_Total/WndScroll_Monitor', 'Handle_Monitor_List')
	local szSearchMonitor = frame.szSearchMonitor
	if config then
		for i, mon in ipairs(config.aMonitor) do
			if not szSearchMonitor
			or szSearchMonitor == ''
			or (mon.szNote and mon.szNote:find(szSearchMonitor))
			or (mon.szContent and mon.szContent:find(szSearchMonitor)) then
				local hItem = hList:Lookup(i - 1)
				if not hItem then
					hItem = hList:AppendItemFromIni(INI_FILE, 'Handle_MonitorItem')
				end
				hItem:Lookup('Box_MonitorItem'):SetObjectIcon(mon.nIconID or 13)
				hItem:Lookup('Text_MonitorItem'):SetText(mon.szNote)
				hItem:Lookup('Image_MonitorItemRBg'):SetVisible(not X.IsEmpty(mon.szContent))
				hItem:Lookup('Text_MonitorItemDisplayName'):SetText(mon.szContent)
				hItem:Lookup('Text_MonitorItemDisplayName'):SetFontColor(X.Unpack(mon.aContentColor or {255, 255, 255}))
				hItem:SetAlpha(mon.bEnable and 255 or 128)
				hItem.mon = mon
				hItem.szType = config.szType
			end
		end
		for i = hList:GetItemCount() - 1, #config.aMonitor, -1 do
			hList:RemoveItem(i)
		end
	else
		hList:Clear()
	end
	hList:FormatAllItemPos()
end

function D.OnFrameCreate()
	this:Lookup('', 'Text_Title'):SetText(_L['MY_TargetMon_PS'])
	this:Lookup('Wnd_Total/Btn_CreateConfig', 'Text_CreateConfig'):SetText(_L['Create Config'])
	this:Lookup('Wnd_Total/Btn_ImportConfig', 'Text_ImportConfig'):SetText(_L['Import Export'])
	this:Lookup('Wnd_Total/Btn_CreateMonitor', 'Text_CreateMonitor'):SetText(_L['Create Monitor'])
	this:Lookup('Wnd_Total/Wnd_SearchMonitor/Edit_SearchMonitor'):SetPlaceholderText(_L['Search Monitor'])
	this:RegisterEvent('MY_TARGET_MON_CONFIG_MODIFY')
	this:RegisterEvent('MY_TARGET_MON_CONFIG_MONITOR_MODIFY')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, -100)
	D.DrawConfigList(this)
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_CreateConfig' then
		MY_TargetMonConfig.CreateConfig()
	elseif name == 'Btn_CreateMonitor' then
		local config = MY_TargetMonConfig.GetConfig(frame.szActiveConfigUUID)
		if not config then
			return
		end
		GetUserInput(config.szType == 'BUFF' and _L['Please Input Monitor Buff Id'] or _L['Please Input Monitor Skill Id'], function(szID)
			local dwID = tonumber(szID)
			if not dwID then
				X.Alert(_L['Invalid Input Number'])
				return
			end
			X.DelayCall(function()
				GetUserInput(config.szType == 'BUFF' and _L['Please Input Monitor Buff Level'] or _L['Please Input Monitor Skill Level'], function(szLevel)
					local nLevel = tonumber(szLevel)
					if not nLevel then
						X.Alert(_L['Invalid Input Number'])
						return
					end
					MY_TargetMonConfig.CreateMonitor(config.szUUID, dwID, nLevel)
				end)
			end)
		end)
	elseif name == 'Btn_ImportConfig' then
		local menu = {}
		table.insert(menu, {
			szOption = _L['Import local data'],
			fnAction = function()
				X.UI.ClosePopupMenu()
				local szFile = GetOpenFileName(
					_L['Please select data file.'],
					'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
					X.GetAbsolutePath({'userdata/target_mon/remote/', X.PATH_TYPE.GLOBAL})
				)
				if X.IsEmpty(szFile) then
					return
				end
				MY_TargetMonConfig.ImportConfigFile(szFile)
			end,
		})
		local t1 = { szOption = _L['Export local data'] }
		local aExportUUID = {}
		for _, config in ipairs(MY_TargetMonConfig.GetConfigList()) do
			table.insert(t1, {
				szOption = MY_TargetMonConfig.GetConfigTitle(config),
				bCheck = true,
				fnAction = function(_, bChecked)
					for i, v in ipairs(aExportUUID) do
						if v == config.szUUID then
							table.remove(aExportUUID, i)
							break
						end
					end
					if bChecked then
						table.insert(aExportUUID, config.szUUID)
					end
				end,
			})
		end
		table.insert(t1, X.CONSTANT.MENU_DIVIDER)
		table.insert(t1, {
			szOption = _L['Ensure export'],
			fnAction = function()
				if MY_TargetMonConfig.ExportConfigFile(aExportUUID) then
					X.UI.ClosePopupMenu()
				end
			end,
		})
		table.insert(t1, {
			szOption = _L['Ensure export (with indent)'],
			fnAction = function()
				if MY_TargetMonConfig.ExportConfigFile(aExportUUID, true) then
					X.UI.ClosePopupMenu()
				end
			end,
		})
		table.insert(menu, t1)
		table.insert(menu, X.CONSTANT.MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['Open data folder'],
			fnAction = function()
				local szRoot = X.GetAbsolutePath({'userdata/target_mon/remote/', X.PATH_TYPE.GLOBAL}):gsub('/', '\\')
				X.OpenFolder(szRoot)
				X.UI.OpenTextEditor(szRoot)
				X.UI.ClosePopupMenu()
			end,
		})
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		menu.x = nX
		menu.y = nY + nH
		menu.nMiniWidth = nW
		X.UI.PopupMenu(menu)
	end
end

function D.OnEditChanged()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Edit_SearchMonitor' then
		frame.szSearchMonitor = X.TrimString(this:GetText())
		D.DrawMonitorList(frame)
	end
end

function D.OnItemMouseIn()
	local name = this:GetName()
	if name == 'Handle_MonitorItem' then
		this:Lookup('Image_MonitorItem'):Hide()
		this:Lookup('Box_MonitorItem'):SetObjectMouseOver(true)
		if this.szType == 'BUFF' then
			local w, h = this:GetW(), this:GetH()
			local x, y = this:GetAbsX(), this:GetAbsY()
			X.OutputBuffTip({x, y, w, h}, this.mon.dwID, this.mon.nLevel)
		elseif this.szType == 'SKILL' then
			local w, h = this:GetW(), this:GetH()
			local x, y = this:GetAbsX(), this:GetAbsY()
			X.OutputSkillTip({x, y, w, h}, this.mon.dwID, this.mon.nLevel)
		end
	elseif name == 'Image_ConfigItemConfig' then
		this:SetFrame(106)
	end
end

function D.OnItemMouseOut()
	local name = this:GetName()
	if name == 'Handle_MonitorItem' then
		this:Lookup('Image_MonitorItem'):Show()
		this:Lookup('Box_MonitorItem'):SetObjectMouseOver(false)
		X.HideTip()
	elseif name == 'Image_ConfigItemConfig' then
		this:SetFrame(105)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Handle_ConfigItem' then
		frame.szActiveConfigUUID = this.config.szUUID
		D.UpdateConfigActiveState(frame)
		D.DrawMonitorList(frame)
	elseif name == 'Handle_MonitorItem' then
		MY_TargetMon_MonitorPanel.Open(frame.szActiveConfigUUID, this.mon.szUUID)
	elseif name == 'Image_ConfigItemConfig' then
		MY_TargetMon_ConfigPanel.Open(this:GetParent().config.szUUID)
	end
end

function D.OnItemLButtonDrag()
	local name = this:GetName()
	if name == 'Handle_ConfigItem' then
		X.UI.OpenDragDrop(this, this, 'MY_TargetMon_PS#Handle_ConfigItem', this.config.szUUID)
	elseif name == 'Handle_MonitorItem' then
		X.UI.OpenDragDrop(this, this, 'MY_TargetMon_PS#Handle_MonitorItem', this.mon.szUUID)
	end
end

function D.OnItemMouseHover()
	local name = this:GetName()
	if name == 'Handle_ConfigItem' then
		if not X.UI.IsDragDropOpened() then
			return
		end
		local szDragGroupID = X.UI.GetDragDropData()
		if szDragGroupID == 'MY_TargetMon_PS#Handle_ConfigItem' then
			X.UI.SetDragDropHoverEl(
				this,
				{
					x = this:GetAbsX(),
					y = this:GetAbsY() + 1,
					w = this:GetW(),
					h = this:GetH() - 2,
				},
				true
			)
		end
	elseif name == 'Handle_MonitorItem' then
		if not X.UI.IsDragDropOpened() then
			return
		end
		local szDragGroupID = X.UI.GetDragDropData()
		if szDragGroupID == 'MY_TargetMon_PS#Handle_MonitorItem' then
			X.UI.SetDragDropHoverEl(
				this,
				{
					x = this:GetAbsX(),
					y = this:GetAbsY() + 1,
					w = this:GetW(),
					h = this:GetH() - 2,
				},
				true
			)
		end
	end
end
D.OnItemMouseEnter = D.OnItemMouseHover

function D.OnItemLButtonDragEnd()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Handle_ConfigItem' then
		if not X.UI.IsDragDropOpened() then
			return
		end
		local dropEl, szDragGroupID, xData = X.UI.CloseDragDrop()
		if szDragGroupID ~= 'MY_TargetMon_PS#Handle_ConfigItem'
		or not dropEl or dropEl:GetName() ~= 'Handle_ConfigItem' or dropEl:GetRoot() ~= frame then
			return
		end
		local szDragUUID = xData
		local szDropUUID = dropEl.config.szUUID
		if szDragUUID == szDropUUID then
			return
		end
		local aConfig = MY_TargetMonConfig.GetConfigList()
		local nPosition, dragConfig = 0, nil
		for _, config in ipairs(aConfig) do
			if config.szUUID == szDragUUID then
				nPosition = 1
				break
			elseif config.szUUID == szDropUUID then
				break
			end
		end
		for i, config in ipairs(aConfig) do
			if config.szUUID == szDragUUID then
				dragConfig = table.remove(aConfig, i)
				break
			end
		end
		for i, config in ipairs(aConfig) do
			if config.szUUID == szDropUUID then
				table.insert(aConfig, i + nPosition, dragConfig)
				break
			end
		end
		FireUIEvent('MY_TARGET_MON_CONFIG_MODIFY')
	elseif name == 'Handle_MonitorItem' then
		if not X.UI.IsDragDropOpened() then
			return
		end
		local dropEl, szDragGroupID, xData = X.UI.CloseDragDrop()
		if szDragGroupID ~= 'MY_TargetMon_PS#Handle_MonitorItem'
		or not dropEl or dropEl:GetName() ~= 'Handle_MonitorItem' or dropEl:GetRoot() ~= frame then
			return
		end
		local szDragUUID = xData
		local szDropUUID = dropEl.mon.szUUID
		if szDragUUID == szDropUUID then
			return
		end
		local config = MY_TargetMonConfig.GetConfig(frame.szActiveConfigUUID)
		local nPosition, dragConfig = 0, nil
		for _, mon in ipairs(config.aMonitor) do
			if mon.szUUID == szDragUUID then
				nPosition = 1
				break
			elseif mon.szUUID == szDropUUID then
				break
			end
		end
		for i, mon in ipairs(config.aMonitor) do
			if mon.szUUID == szDragUUID then
				dragConfig = table.remove(config.aMonitor, i)
				break
			end
		end
		for i, mon in ipairs(config.aMonitor) do
			if mon.szUUID == szDropUUID then
				table.insert(config.aMonitor, i + nPosition, dragConfig)
				break
			end
		end
		FireUIEvent('MY_TARGET_MON_CONFIG_MODIFY')
	end
end

function D.OnEvent(event)
	if event == 'MY_TARGET_MON_CONFIG_MODIFY' then
		local frame = this
		X.DelayCall('MY_TargetMon_PS_DrawConfigList', 100, function()
			D.DrawConfigList(frame)
		end)
	elseif event == 'MY_TARGET_MON_CONFIG_MONITOR_MODIFY' then
		local frame = this
		X.DelayCall('MY_TargetMon_PS_DrawConfigList', 300, function()
			D.DrawMonitorList(frame)
		end)
	end
end

-- Global exports
do
local settings = {
	name = 'MY_TargetMon_PS',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				Open = D.Open,
				Close = D.Close,
			},
		},
	},
}
MY_TargetMon_PS = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
