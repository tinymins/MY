--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
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
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local INI_FILE = X.PACKET_INFO.ROOT .. 'MY_TargetMon/ui/MY_TargetMon_PS.ini'
local D = {}

function D.OpenPanel()
	if X.IsRestricted('MY_TargetMon') then
		return
	end
	X.UI.CreateFrame('MY_TargetMon_PS', {
		text = _L['MY_TargetMon_PS'],
		w = 1060, h = 660,
	})
end

function D.ClosePanel()
	X.UI.CloseFrame('MY_TargetMon_PS')
end

function D.TogglePanel()
	if Station.Lookup('Normal/MY_TargetMon_PS') then
		D.ClosePanel()
	else
		D.OpenPanel()
	end
end

function D.UpdateDatasetActiveState(frame)
	local hList = frame:Lookup('Wnd_Total/WndScroll_Dataset', 'Handle_DatasetList')
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		hItem:Lookup('Image_DatasetItemBg_Sel'):SetVisible(hItem.dataset.szUUID == frame.szActiveDatasetUUID)
	end
end

function D.DrawDatasetList(frame)
	local aDataset = MY_TargetMonConfig.GetDatasetList()
	local szActiveDatasetUUID
	-- 选中数据
	for _, dataset in ipairs(aDataset) do
		if not szActiveDatasetUUID or dataset.szUUID == frame.szActiveDatasetUUID then
			szActiveDatasetUUID = dataset.szUUID
		end
	end
	frame.szActiveDatasetUUID = szActiveDatasetUUID
	-- 渲染列表
	local hList = frame:Lookup('Wnd_Total/WndScroll_Dataset', 'Handle_DatasetList')
	hList:Clear()
	for _, dataset in ipairs(aDataset) do
		local hItem = hList:AppendItemFromIni(INI_FILE, 'Handle_DatasetItem')
		local aTextColor = dataset.bEnable and {255, 255, 255} or {192, 192, 192}
		hItem:Lookup('Text_DatasetItemTitle'):SetText(dataset.szTitle)
		hItem:Lookup('Text_DatasetItemTitle'):SetFontColor(X.Unpack(aTextColor))
		hItem:Lookup('Text_DatasetItemAuthor'):SetText(dataset.szAuthor)
		hItem:Lookup('Text_DatasetItemAuthor'):SetFontColor(X.Unpack(aTextColor))
		hItem:Lookup('Text_DatasetItemVersion'):SetText(dataset.szVersion)
		hItem:Lookup('Text_DatasetItemVersion'):SetFontColor(X.Unpack(aTextColor))
		hItem:Lookup('Image_DatasetItemBg_Sel'):SetVisible(dataset.szUUID == szActiveDatasetUUID)
		hItem.dataset = dataset
	end
	hList:FormatAllItemPos()
	D.DrawMonitorList(frame)
end

function D.DrawMonitorList(frame)
	local dataset = MY_TargetMonConfig.GetDataset(frame.szActiveDatasetUUID)
	local hList = frame:Lookup('Wnd_Total/WndScroll_Monitor', 'Handle_Monitor_List')
	local szSearchMonitor = frame.szSearchMonitor
	if dataset then
		local nCount = 0
		for i, mon in ipairs(dataset.aMonitor) do
			if not szSearchMonitor
			or szSearchMonitor == ''
			or (mon.szNote and mon.szNote:find(szSearchMonitor))
			or (mon.szContent and mon.szContent:find(szSearchMonitor)) then
				local hItem = hList:Lookup(nCount)
				if not hItem then
					hItem = hList:AppendItemFromIni(INI_FILE, 'Handle_MonitorItem')
				end
				hItem:Lookup('Box_MonitorItem'):SetObjectIcon(mon.nIconID or MY_TargetMonConfig.DEFAULT_MONITOR_ICON_ID)
				hItem:Lookup('Text_MonitorItem'):SetText(mon.szNote)
				hItem:Lookup('Image_MonitorItemRBg'):SetVisible(not X.IsEmpty(mon.szContent))
				hItem:Lookup('Text_MonitorItemDisplayName'):SetText(mon.szContent)
				hItem:Lookup('Text_MonitorItemDisplayName'):SetFontColor(X.Unpack(mon.aContentColor or {255, 255, 255}))
				hItem:SetAlpha(mon.bEnable and 255 or 128)
				hItem.mon = mon
				hItem.nMonitorIndex = i
				hItem.szType = dataset.szType
				nCount = nCount + 1
			end
		end
		for i = hList:GetItemCount() - 1, nCount, -1 do
			hList:RemoveItem(i)
		end
	else
		hList:Clear()
	end
	hList:FormatAllItemPos()
end

function D.CreateMonitor(frame, nIndex)
	local dataset = MY_TargetMonConfig.GetDataset(frame.szActiveDatasetUUID)
	if not dataset then
		return
	end
	GetUserInput(dataset.szType == 'BUFF' and _L['Please Input Monitor Buff Id'] or _L['Please Input Monitor Skill Id'], function(szID)
		local dwID = tonumber(szID)
		if not dwID then
			X.Alert(_L['Invalid Input Number'])
			return
		end
		X.DelayCall(function()
			GetUserInput(dataset.szType == 'BUFF' and _L['Please Input Monitor Buff Level'] or _L['Please Input Monitor Skill Level'], function(szLevel)
				local nLevel = tonumber(szLevel)
				if not nLevel then
					X.Alert(_L['Invalid Input Number'])
					return
				end
				MY_TargetMonConfig.CreateMonitor(dataset.szUUID, nIndex, dwID, nLevel)
			end)
		end)
	end)
end

function D.OnFrameCreate()
	X.UI.AppendFromIni(this:Lookup('Wnd_Total'), INI_FILE, 'Wnd_Total', true)
	this:Lookup('', 'Text_Title'):SetText(_L['MY_TargetMon_PS'])
	this:Lookup('Wnd_Total/Btn_CreateDataset', 'Text_CreateDataset'):SetText(_L['Create Config'])
	this:Lookup('Wnd_Total/Btn_ImportExportDataset', 'Text_ImportExportDataset'):SetText(_L['Import Export'])
	this:Lookup('Wnd_Total/Btn_CreateMonitor', 'Text_CreateMonitor'):SetText(_L['Create Monitor'])
	this:Lookup('Wnd_Total/Wnd_SearchMonitor/Edit_SearchMonitor'):SetPlaceholderText(_L['Search Monitor'])
	X.UI.AdaptComponentAppearance(this:Lookup('Wnd_Total/Btn_CreateDataset'))
	X.UI.AdaptComponentAppearance(this:Lookup('Wnd_Total/Btn_ImportExportDataset'))
	X.UI.AdaptComponentAppearance(this:Lookup('Wnd_Total/Btn_CreateMonitor'))
	X.UI.AdaptComponentAppearance(this:Lookup('Wnd_Total/WndScroll_Dataset/Btn_Dataset_All'))
	X.UI.AdaptComponentAppearance(this:Lookup('Wnd_Total/WndScroll_Monitor/Scroll_Monitor'))
	this:RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_RELOAD')
	this:RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
	this:RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, -100)
	D.DrawDatasetList(this)
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Close' then
		X.UI.CloseFrame(this:GetRoot())
	elseif name == 'Btn_CreateDataset' then
		MY_TargetMonConfig.CreateDataset()
	elseif name == 'Btn_CreateMonitor' then
		D.CreateMonitor(frame, nil)
	elseif name == 'Btn_ImportExportDataset' then
		local menu = {}
		table.insert(menu, {
			szOption = _L['Subscribe remote data'],
			fnAction = function()
				MY_TargetMon_Subscribe.OpenPanel()
				X.UI.ClosePopupMenu()
			end,
		})
		table.insert(menu, X.CONSTANT.MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['Import local data'],
			fnAction = function()
				local szFile = GetOpenFileName(
					_L['Please select data file.'],
					'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
					X.GetAbsolutePath(MY_TargetMonConfig.REMOTE_DATA_ROOT)
				)
				if not X.IsEmpty(szFile) then
					MY_TargetMonConfig.ImportDatasetFile(szFile)
				end
				X.UI.ClosePopupMenu()
			end,
		})
		local t1 = { szOption = _L['Export local data'] }
		local aExportUUID = {}
		for _, dataset in ipairs(MY_TargetMonConfig.GetDatasetList()) do
			table.insert(t1, {
				szOption = MY_TargetMonConfig.GetDatasetTitle(dataset),
				bCheck = true,
				fnAction = function(_, bChecked)
					for i, v in ipairs(aExportUUID) do
						if v == dataset.szUUID then
							table.remove(aExportUUID, i)
							break
						end
					end
					if bChecked then
						table.insert(aExportUUID, dataset.szUUID)
					end
				end,
			})
		end
		table.insert(t1, X.CONSTANT.MENU_DIVIDER)
		table.insert(t1, {
			szOption = _L['Ensure export'],
			fnAction = function()
				if MY_TargetMonConfig.ExportDatasetFile(aExportUUID) then
					X.UI.ClosePopupMenu()
				end
			end,
		})
		table.insert(t1, {
			szOption = _L['Ensure export (with indent)'],
			fnAction = function()
				if MY_TargetMonConfig.ExportDatasetFile(aExportUUID, true) then
					X.UI.ClosePopupMenu()
				end
			end,
		})
		table.insert(menu, t1)
		table.insert(menu, X.CONSTANT.MENU_DIVIDER)
		if MY_TargetMonConfig.HasAncientData() then
			table.insert(menu, {
				szOption = _L['Import ancient data'],
				fnAction = function()
					X.Confirm(_L['Sure to import ancient dataset? Current data with same uuid will be overwritten.'], function()
						MY_TargetMonConfig.ImportAncientData(function(aDataset)
							local aName = {}
							for _, dataset in ipairs(aDataset) do
								table.insert(aName, MY_TargetMonConfig.GetDatasetTitle(dataset))
							end
							X.Alert(_L['Ancient datasets import success:'] .. '\n\n' .. table.concat(aName, '\n'))
						end)
					end)
					X.UI.ClosePopupMenu()
				end,
			})
		end
		table.insert(menu, {
			szOption = _L['Delete all datasets'],
			rgb = {255, 0, 0},
			fnAction = function()
				X.Confirm(_L['Sure to delete all datasets? This operation can not be undone.'], function()
					MY_TargetMonConfig.DeleteAllDataset()
				end)
				X.UI.ClosePopupMenu()
			end,
		})
		table.insert(menu, X.CONSTANT.MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['Open data folder'],
			fnAction = function()
				local szRoot = X.GetAbsolutePath(MY_TargetMonConfig.REMOTE_DATA_ROOT):gsub('/', '\\')
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
			X.OutputBuffTip({x, y, w, h}, this.mon.dwID, this.mon.nLevel == 0 and 1 or this.mon.nLevel)
		elseif this.szType == 'SKILL' then
			local w, h = this:GetW(), this:GetH()
			local x, y = this:GetAbsX(), this:GetAbsY()
			X.OutputSkillTip({x, y, w, h}, this.mon.dwID, this.mon.nLevel)
		end
	elseif name == 'Image_DatasetItemConfig' then
		this:SetFrame(106)
	end
end

function D.OnItemMouseOut()
	local name = this:GetName()
	if name == 'Handle_MonitorItem' then
		this:Lookup('Image_MonitorItem'):Show()
		this:Lookup('Box_MonitorItem'):SetObjectMouseOver(false)
		X.HideTip()
	elseif name == 'Image_DatasetItemConfig' then
		this:SetFrame(105)
	end
end

function D.OnItemLButtonUp()
	local name = this:GetName()
	if name == 'Handle_DatasetItem'
	or name == 'Handle_MonitorItem' then
		-- DragEnd bug fix
		X.DelayCall(50, function()
			if not X.UI.IsDragDropOpened() then
				return
			end
			X.UI.CloseDragDrop()
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Handle_DatasetItem' then
		frame.szActiveDatasetUUID = this.dataset.szUUID
		D.UpdateDatasetActiveState(frame)
		D.DrawMonitorList(frame)
	elseif name == 'Handle_MonitorItem' then
		MY_TargetMon_MonitorPanel.Open(frame.szActiveDatasetUUID, this.mon.szUUID)
	elseif name == 'Image_DatasetItemConfig' then
		MY_TargetMon_ConfigPanel.Open(this:GetParent().dataset.szUUID)
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Image_DatasetItemConfig' then
		local dataset = this:GetParent().dataset
		local menu = {}
		table.insert(menu, {
			szOption = _L['Enable'],
			bCheck = true, bChecked = dataset.bEnable,
			fnAction = function()
				dataset.bEnable = not dataset.bEnable
				FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
				X.UI.ClosePopupMenu()
			end,
		})
		table.insert(menu, X.CONSTANT.MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['Delete'],
			rgb = { 255, 0, 0 },
			fnAction = function()
				X.Confirm(_L['Sure to delete monitor? This operation can not be undone.'], function()
					MY_TargetMonConfig.DeleteDataset(dataset.szUUID)
				end)
				X.UI.ClosePopupMenu()
			end,
		})
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		menu.x = nX
		menu.y = nY + nH
		menu.nMiniWidth = nW
		X.UI.PopupMenu(menu)
	elseif name == 'Handle_MonitorItem' then
		local dataset = MY_TargetMonConfig.GetDataset(frame.szActiveDatasetUUID)
		local mon = this.mon
		local nMonitorIndex = this.nMonitorIndex
		local menu = {}
		table.insert(menu, {
			szOption = _L['Insert'],
			fnAction = function()
				D.CreateMonitor(frame, nMonitorIndex)
				MY.UI.ClosePopupMenu()
			end,
		})
		if this.nMonitorIndex ~= 1 then
			table.insert(menu, {
				szOption = _L['Move to top'],
				fnAction = function()
					for i, m in ipairs(dataset.aMonitor) do
						if m == mon then
							table.remove(dataset.aMonitor, i)
							break
						end
					end
					table.insert(dataset.aMonitor, 1, mon)
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					MY.UI.ClosePopupMenu()
				end,
			})
		end
		if this.nMonitorIndex ~= #dataset.aMonitor then
			table.insert(menu, {
				szOption = _L['Move to bottom'],
				fnAction = function()
					for i, m in ipairs(dataset.aMonitor) do
						if m == mon then
							table.remove(dataset.aMonitor, i)
							break
						end
					end
					table.insert(dataset.aMonitor, mon)
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					MY.UI.ClosePopupMenu()
				end,
			})
		end
		local nX, nY = Cursor.GetPos()
		local nW, nH = 40, 40
		menu.x = nX
		menu.y = nY + nH
		menu.nMiniWidth = nW
		X.UI.PopupMenu(menu)
	end
end

function D.OnItemLButtonDrag()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Handle_DatasetItem' then
		if not X.IsEmpty(frame.szSearchMonitor) then
			return
		end
		X.UI.OpenDragDrop(this, this, 'MY_TargetMon_PS#Handle_DatasetItem', this.dataset.szUUID)
	elseif name == 'Handle_MonitorItem' then
		if not X.IsEmpty(frame.szSearchMonitor) then
			return
		end
		X.UI.OpenDragDrop(this, this, 'MY_TargetMon_PS#Handle_MonitorItem', this.mon.szUUID)
	end
end

function D.OnItemMouseHover()
	local name = this:GetName()
	if name == 'Handle_DatasetItem' then
		if not X.UI.IsDragDropOpened() then
			local aView, view = MY_TargetMonData.GetViewData(), nil
			local nMonitorCount = 0
			for _, v in ipairs(aView) do
				if v.szUUID == this.dataset.szUUID then
					view = v
				end
				nMonitorCount = nMonitorCount + #v.aMonitor
			end
			local szText = GetFormatText(
				view
					and _L('Current dataset total monitor count is %d, active monitors count is %d, visible monitors count is %d.', #this.dataset.aMonitor, #view.aMonitor, #view.aItem)
					or  _L['Current dataset is not active.'],
				162, 255, 255, 255
			)
			if nMonitorCount > MY_TargetMonData.MY_TARGET_MON_DATA_MAX_LIMIT then
				szText = szText
					.. GetFormatText(
						'\n' .. _L('Total monitors reaches max limit: %d/%d.', nMonitorCount, MY_TargetMonData.MY_TARGET_MON_DATA_MAX_LIMIT),
						162, 255, 86, 86
					)
			end
			X.OutputTip(this, szText, true, X.UI.TIP_POSITION.TOP_BOTTOM)
			return
		end
		local szDragGroupID = X.UI.GetDragDropData()
		if szDragGroupID == 'MY_TargetMon_PS#Handle_DatasetItem' then
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
	if name == 'Handle_DatasetItem' then
		if not X.UI.IsDragDropOpened() then
			return
		end
		local dropEl, szDragGroupID, xData = X.UI.CloseDragDrop()
		if szDragGroupID ~= 'MY_TargetMon_PS#Handle_DatasetItem'
		or not dropEl or dropEl:GetName() ~= 'Handle_DatasetItem' or dropEl:GetRoot() ~= frame then
			return
		end
		local szDragUUID = xData
		local szDropUUID = dropEl.dataset.szUUID
		if szDragUUID == szDropUUID then
			return
		end
		local aDataset = MY_TargetMonConfig.GetDatasetList()
		local nPosition, dragDataset = 0, nil
		for _, dataset in ipairs(aDataset) do
			if dataset.szUUID == szDragUUID then
				nPosition = 1
				break
			elseif dataset.szUUID == szDropUUID then
				break
			end
		end
		for i, dataset in ipairs(aDataset) do
			if dataset.szUUID == szDragUUID then
				dragDataset = table.remove(aDataset, i)
				break
			end
		end
		for i, dataset in ipairs(aDataset) do
			if dataset.szUUID == szDropUUID then
				table.insert(aDataset, i + nPosition, dragDataset)
				break
			end
		end
		FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
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
		local dataset = MY_TargetMonConfig.GetDataset(frame.szActiveDatasetUUID)
		local nPosition, dragDataset = 0, nil
		for _, mon in ipairs(dataset.aMonitor) do
			if mon.szUUID == szDragUUID then
				nPosition = 1
				break
			elseif mon.szUUID == szDropUUID then
				break
			end
		end
		for i, mon in ipairs(dataset.aMonitor) do
			if mon.szUUID == szDragUUID then
				dragDataset = table.remove(dataset.aMonitor, i)
				break
			end
		end
		for i, mon in ipairs(dataset.aMonitor) do
			if mon.szUUID == szDropUUID then
				table.insert(dataset.aMonitor, i + nPosition, dragDataset)
				break
			end
		end
		FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
	end
end

function D.OnEvent(event)
	if event == 'MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY' or event == 'MY_TARGET_MON_CONFIG__DATASET_RELOAD' then
		local frame = this
		X.DelayCall('MY_TargetMon_PS_DrawConfigList', 100, function()
			D.DrawDatasetList(frame)
		end)
	elseif event == 'MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY' then
		local frame = this
		X.DelayCall('MY_TargetMon_PS_DrawConfigList', 300, function()
			D.DrawMonitorList(frame)
		end)
	end
end

X.RegisterHotKey('MY_TargetMon_PS', _L['Open/close MY_TargetMon'], D.TogglePanel)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
				OpenPanel = D.OpenPanel,
				ClosePanel = D.ClosePanel,
			},
		},
	},
}
MY_TargetMon_PS = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
