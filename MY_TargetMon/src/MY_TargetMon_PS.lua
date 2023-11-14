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
	local aConfig = MY_TargetMon.GetConfigList()
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
	local config = MY_TargetMon.GetConfig(frame.szActiveConfigUUID)
	local hList = frame:Lookup('Wnd_Total/WndScroll_Monitor', 'Handle_Monitor_List')
	hList:Clear()
	if config then
		for _, mon in ipairs(config.aMonitor) do
			local hItem = hList:AppendItemFromIni(INI_FILE, 'Handle_MonitorItem')
			hItem:Lookup('Box_MonitorItem'):SetObjectIcon(mon.nIconID or 13)
			hItem:Lookup('Text_MonitorItem'):SetText(mon.szNote)
			hItem:Lookup('Image_MonitorItemRBg'):SetVisible(not X.IsEmpty(mon.szContent))
			hItem:Lookup('Text_MonitorItemDisplayName'):SetText(mon.szContent)
			hItem:Lookup('Text_MonitorItemDisplayName'):SetFontColor(X.Unpack(mon.aContentColor))
			hItem.mon = mon
			hItem.szType = config.szType
		end
	end
	hList:FormatAllItemPos()
end

function D.OnFrameCreate()
	this:Lookup('', 'Text_Title'):SetText(_L['MY_TargetMon_PS'])
	this:Lookup('Wnd_Total/Btn_CreateConfig', 'Text_CreateConfig'):SetText(_L['Create Config'])
	this:Lookup('Wnd_Total/Btn_ImportConfig', 'Text_ImportConfig'):SetText(_L['Import Config'])
	this:Lookup('Wnd_Total/Btn_CreateMonitor', 'Text_CreateMonitor'):SetText(_L['Create Monitor'])
	this:Lookup('Wnd_Total/Wnd_SearchMonitor/Edit_SearchMonitor'):SetPlaceholderText(_L['Search Monitor'])
	this:RegisterEvent('MY_TARGET_MON_CONFIG_MODIFY')
	this:RegisterEvent('MY_TARGET_MON_DATA_MODIFY')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, -100)
	D.DrawConfigList(this)
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_CreateConfig' then
		MY_TargetMon.CreateConfig()
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
	elseif name == 'Image_ConfigItemConfig' then
		MY_TargetMon_ConfigPanel.Open(this:GetParent().config.szUUID)
	end
end

function D.OnEvent(event)
	if event == 'MY_TARGET_MON_CONFIG_MODIFY' or event == 'MY_TARGET_MON_DATA_MODIFY' then
		local frame = this
		X.DelayCall('MY_TargetMon_PS_DrawConfigList', 100, function()
			D.DrawConfigList(frame)
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
