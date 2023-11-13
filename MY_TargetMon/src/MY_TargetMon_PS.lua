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

function D.OnFrameCreate()
	this:Lookup('', 'Text_Title'):SetText(_L['MY_TargetMon'])
	this:Lookup('Wnd_Total/Btn_CreateCategory', 'Text_CreateCategory'):SetText(_L['Create Category'])
	this:Lookup('Wnd_Total/Btn_ImportCategory', 'Text_ImportCategory'):SetText(_L['Import Category'])
	this:Lookup('Wnd_Total/Btn_CreateRecord', 'Text_CreateRecord'):SetText(_L['Create Record'])
	this:Lookup('Wnd_Total/Wnd_SearchContent/Edit_SearchContent'):SetPlaceholderText(_L['Search content'])
end

function D.OnItemMouseIn()
	local name = this:GetName()
	if name == 'Handle_ContentItem' then
		this:Lookup('Image_ContentItem'):Hide()
		this:Lookup('Box_ContentItem'):SetObjectMouseOver(true)
	elseif name == 'Image_CategoryItemConfig' then
		this:SetFrame(106)
	end
end

function D.OnItemMouseOut()
	local name = this:GetName()
	if name == 'Handle_ContentItem' then
		this:Lookup('Image_ContentItem'):Show()
		this:Lookup('Box_ContentItem'):SetObjectMouseOver(false)
	elseif name == 'Image_CategoryItemConfig' then
		this:SetFrame(105)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
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
