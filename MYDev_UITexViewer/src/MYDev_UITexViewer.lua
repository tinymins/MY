--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 开发者工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MYDev_UITexViewer/MYDev_UITexViewer'
local PLUGIN_NAME = 'MYDev_UITexViewer'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_UITexViewer'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MYDev_UITexViewer', {
	szUITexPath = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
})
local _Cache = {}
MYDev_UITexViewer = {}

_Cache.OnPanelActive = function(wnd)
	local ui = X.UI(wnd)
	local w, h = ui:Size()
	local x, y = 20, 20

	_Cache.tUITexList = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MYDev_UITexViewer/data/data.jx3dat') or {}

	local uiBoard = ui:Append('WndScrollHandleBox', 'WndScrollHandleBox_ImageList')
	  :HandleStyle(3):Pos(x, y+25):Size(w-21, h - 70)

	local uiEdit = ui:Append('WndEditBox', 'WndEdit_Copy')
	  :Pos(x, h-30):Size(w-20, 25):Multiline(true)

	ui:Append('WndAutocomplete', 'WndAutocomplete_UITexPath')
	  :Pos(x, y):Size(w-20, 25):Text(O.szUITexPath)
	  :Change(function(szText)
		local tInfo = KG_Table.Load(szText .. '.txt', {
		-- 图片文件帧信息表的表头名字
			{f = 'i', t = 'nFrame' },             -- 图片帧 ID
			{f = 'i', t = 'nLeft'  },             -- 帧位置: 距离左侧像素(X位置)
			{f = 'i', t = 'nTop'   },             -- 帧位置: 距离顶端像素(Y位置)
			{f = 'i', t = 'nWidth' },             -- 帧宽度
			{f = 'i', t = 'nHeight'},             -- 帧高度
			{f = 's', t = 'szFile' },             -- 帧来源文件(无作用)
		}, FILE_OPEN_MODE.NORMAL)
		if not tInfo then
			return
		end

		O.szUITexPath = szText
		uiBoard:Clear()
		for i = 0, 256 do
			local tLine = tInfo:Search(i)
			if not tLine then
				break
			end

			if tLine.nWidth ~= 0 and tLine.nHeight ~= 0 then
				uiBoard:Append('<image>eventid=277 name="Image_'..i..'"</image>')
				  :Image(szText .. '.UITex', tLine.nFrame)
				  :Size(tLine.nWidth, tLine.nHeight)
				  :Alpha(220)
				  :Hover(function(bIn) X.UI(this):Alpha((bIn and 255) or 220) end)
				  :Tip(szText .. '.UITex#' .. i .. '\n' .. tLine.nWidth .. 'x' .. tLine.nHeight .. '\n' .. _L['(left click to generate xml)'], X.UI.TIP_POSITION.TOP_BOTTOM)
				  :Click(function() uiEdit:Text('<image>w='..tLine.nWidth..' h='..tLine.nHeight..' path="' .. szText .. '.UITex" frame=' .. i ..'</image>') end)
			end
		end
	  end)
	  :Click(function(nButton)
		if IsPopupMenuOpened() then
			X.UI(this):Autocomplete('close')
		else
			X.UI(this):Autocomplete('search', '')
		end
	  end)
	  :Autocomplete('option', 'maxOption', 20)
	  :Autocomplete('option', 'source', _Cache.tUITexList)
	  :Change()
end

_Cache.OnPanelDeactive = function(wnd)
	_Cache.tUITexList = nil
	collectgarbage('collect')
end

X.RegisterPanel(_L['Development'], 'Dev_UITexViewer', _L['UITexViewer'], 'ui/Image/UICommon/BattleFiled.UITex|7', {
	IsRestricted = function()
		return not X.IsDebugClient('Dev_UITexViewer')
	end,
	OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = _Cache.OnPanelDeactive
})

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
