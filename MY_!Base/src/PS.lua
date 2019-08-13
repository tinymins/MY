--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 插件主界面相关函数
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT ..'ui/MY.ini'
---------------------------------------------------------------------------------------------
-- 界面开关
---------------------------------------------------------------------------------------------
function LIB.GetFrame()
	return Station.Lookup('Normal/MY')
end

function LIB.OpenPanel()
	if not LIB.IsInitialized() then
		return
	end
	local frame = LIB.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, 'MY')
		frame:Hide()
		frame.bVisible = false
		LIB.CheckTutorial()
	end
	return frame
end

function LIB.ClosePanel()
	local frame = LIB.GetFrame()
	if not frame then
		return
	end
	LIB.SwitchTab()
	LIB.HidePanel(false, true)
	Wnd.CloseWindow(frame)
end

function LIB.ReopenPanel()
	if not LIB.IsPanelOpened() then
		return
	end
	local bVisible = LIB.IsPanelVisible()
	LIB.ClosePanel()
	LIB.OpenPanel()
	LIB.TogglePanel(bVisible, true, true)
end

function LIB.ShowPanel(bMute, bNoAnimate)
	local frame = LIB.OpenPanel()
	if not frame:IsVisible() then
		frame:Show()
		frame.bVisible = true
		if not bNoAnimate then
			frame.bToggling = true
			tweenlite.from(300, frame, {
				relY = frame:GetRelY() - 10,
				alpha = 0,
				complete = function()
					frame.bToggling = false
				end,
			})
		end
		if not bMute then
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end
	end
	frame:BringToTop()
	LIB.RegisterEsc('MY', LIB.IsPanelVisible, function() LIB.HidePanel() end)
end

function LIB.HidePanel(bMute, bNoAnimate)
	local frame = LIB.GetFrame()
	if not frame then
		return
	end
	if not frame.bToggling then
		if bNoAnimate then
			frame:Hide()
		else
			local nY = frame:GetRelY()
			local nAlpha = frame:GetAlpha()
			tweenlite.to(300, frame, {relY = nY + 10, alpha = 0, complete = function()
				frame:SetRelY(nY)
				frame:SetAlpha(nAlpha)
				frame:Hide()
				frame.bToggling = false
			end})
			frame.bToggling = true
		end
		frame.bVisible = false
	end
	if not bMute then
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	LIB.RegisterEsc('MY')
	Wnd.CloseWindow('PopupMenuPanel')
end

function LIB.TogglePanel(bVisible, ...)
	if bVisible == nil then
		if LIB.IsPanelVisible() then
			LIB.HidePanel()
		else
			LIB.ShowPanel()
			LIB.FocusPanel()
		end
	elseif bVisible then
		LIB.ShowPanel(...)
		LIB.FocusPanel()
	else
		LIB.HidePanel(...)
	end
end

function LIB.FocusPanel(bForce)
	local frame = LIB.GetFrame()
	if not frame then
		return
	end
	if not bForce and not Cursor.IsVisible() then
		return
	end
	Station.SetFocusWindow(frame)
end

function LIB.ResizePanel(nWidth, nHeight)
	local hFrame = LIB.GetFrame()
	if not hFrame then
		return
	end
	LIB.UI(hFrame):size(nWidth, nHeight)
end

function LIB.IsPanelVisible()
	return LIB.GetFrame() and LIB.GetFrame():IsVisible()
end

-- if panel visible
function LIB.IsPanelOpened()
	return Station.Lookup('Normal/MY')
end

---------------------------------------------------------------------------------------------
-- 选项卡
---------------------------------------------------------------------------------------------
do local TABS_LIST = {
	{ id = _L['General'] },
	{ id = _L['Target'] },
	{ id = _L['Chat'] },
	{ id = _L['Battle'] },
	{ id = _L['Raid'] },
	{ id = _L['System'] },
	{ id = _L['Others'] },
}
--[[ tTabs:
	{
		{
			id = ,
			{
				[tab]
			}, {...}
		},
		{
			[category]
		}, {...}
	}
]]
function LIB.RedrawCategory(szCategory)
	local frame = LIB.GetFrame()
	if not frame then
		return
	end

	-- draw category
	local wndCategoryList = frame:Lookup('Wnd_Total/WndContainer_Category')
	wndCategoryList:Clear()
	for _, ctg in ipairs(TABS_LIST) do
		local nCount = 0
		for i, tab in ipairs(ctg) do
			if not ((tab.bShielded or tab.nShielded) and LIB.IsShieldedVersion(tab.nShielded)) then
				nCount = nCount + 1
			end
		end
		if nCount > 0 then
			local chkCategory = wndCategoryList:AppendContentFromIni(INI_PATH, 'CheckBox_Category')
			chkCategory.szCategory = ctg.id
			chkCategory:Lookup('', 'Text_Category'):SetText(ctg.id)
			chkCategory.OnCheckBoxCheck = function()
				if chkCategory.bActived then
					return
				end
				wndCategoryList.szCategory = chkCategory.szCategory

				PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
				local p = chkCategory:GetParent():GetFirstChild()
				while p do
					if p.szCategory ~= chkCategory.szCategory then
						p.bActived = false
						p:Check(false)
					end
					p = p:GetNext()
				end
				LIB.RedrawTabs(chkCategory.szCategory)
			end
			szCategory = szCategory or ctg.id
		end
	end
	wndCategoryList:FormatAllContentPos()

	LIB.SwitchCategory(szCategory)
end

-- LIB.SwitchCategory(szCategory)
function LIB.SwitchCategory(szCategory)
	local frame = LIB.GetFrame()
	if not frame then
		return
	end

	local container = frame:Lookup('Wnd_Total/WndContainer_Category')
	local chk = container:GetFirstChild()
	while(chk and chk.szCategory ~= szCategory) do
		chk = chk:GetNext()
	end
	if not chk then
		chk = container:GetFirstChild()
	end
	if chk then
		container.szCategory = chk.szCategory
		chk:Check(true)
	end
end

function LIB.RedrawTabs(szCategory)
	local frame = LIB.GetFrame()
	if not (frame and szCategory) then
		return
	end

	-- draw tabs
	local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	hTabs:Clear()

	for _, ctg in ipairs(TABS_LIST) do
		if ctg.id == szCategory then
			for i, tab in ipairs(ctg) do
				if not ((tab.bShielded or tab.nShielded) and LIB.IsShieldedVersion(tab.nShielded)) then
					local hTab = hTabs:AppendItemFromIni(INI_PATH, 'Handle_Tab')
					hTab.szID = tab.szID
					hTab:Lookup('Text_Tab'):SetText(tab.szTitle)
					if tab.szIconTex == 'FromIconID' then
						hTab:Lookup('Image_TabIcon'):FromIconID(tab.dwIconFrame)
					elseif tab.dwIconFrame then
						hTab:Lookup('Image_TabIcon'):FromUITex(tab.szIconTex, tab.dwIconFrame)
					else
						hTab:Lookup('Image_TabIcon'):FromTextureFile(tab.szIconTex)
					end
					hTab:Lookup('Image_Bg'):FromUITex(PACKET_INFO.UITEX_COMMON, 3)
					hTab:Lookup('Image_Bg_Active'):FromUITex(PACKET_INFO.UITEX_COMMON, 1)
					hTab:Lookup('Image_Bg_Hover'):FromUITex(PACKET_INFO.UITEX_COMMON, 2)
					hTab.OnItemLButtonClick = function()
						LIB.SwitchTab(this.szID)
					end
					hTab.OnItemMouseEnter = function()
						this:Lookup('Image_Bg_Hover'):Show()
					end
					hTab.OnItemMouseLeave = function()
						this:Lookup('Image_Bg_Hover'):Hide()
					end
				end
			end
		end
	end
	hTabs:FormatAllItemPos()

	LIB.SwitchTab()
end

function LIB.SwitchTab(szID, bForceUpdate)
	local frame = LIB.GetFrame()
	if not frame then
		return
	end

	local category, tab
	if szID then
		for _, ctg in ipairs(TABS_LIST) do
			for _, p in ipairs(ctg) do
				if p.szID == szID then
					category, tab = ctg, p
				end
			end
		end
		--[[#DEBUG BEGIN]]
		if not tab then
			LIB.Debug(_L('Cannot find tab: %s', szID), PACKET_INFO.NAME_SPACE .. '.SwitchTab#' .. szID, DEBUG_LEVEL.WARNING)
		end
		--[[#DEBUG END]]
	end

	-- check if category is right
	if category then
		local szCategory = frame:Lookup('Wnd_Total/WndContainer_Category').szCategory
		if category.id ~= szCategory then
			LIB.SwitchCategory(category.id)
		end
	end

	-- check if tab is alreay actived and update tab active status
	if tab then
		-- get tab window
		local hTab
		local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
		for i = 0, hTabs:GetItemCount() - 1 do
			if hTabs:Lookup(i).szID == szID then
				hTab = hTabs:Lookup(i)
			end
		end
		if (not hTab) or (hTab.bActived and not bForceUpdate) then
			return
		end
		if not hTab.bActived then
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end

		-- deal with ui response
		local hTabs = hTab:GetParent()
		for i = 0, hTabs:GetItemCount() - 1 do
			hTabs:Lookup(i).bActived = false
			hTabs:Lookup(i):Lookup('Image_Bg_Active'):Hide()
		end
		hTab.bActived = true
		hTab:Lookup('Image_Bg_Active'):Show()
	end

	-- get main panel
	local wnd = frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	local scroll = frame:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel')
	-- fire custom registered on switch event
	if wnd.OnPanelDeactive then
		local res, err, trace = XpCall(wnd.OnPanelDeactive, wnd)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. '\nMY#OnPanelDeactive\n' .. trace .. '\n')
		end
	end
	-- clear all events
	wnd.OnPanelActive   = nil
	wnd.OnPanelDeactive = nil
	wnd.OnPanelResize   = nil
	wnd.OnPanelScroll   = nil
	-- reset main panel status
	scroll:SetScrollPos(0)
	wnd:Clear()
	wnd:Lookup('', ''):Clear()
	wnd:SetContainerType(CONSTANT.WND_CONTAINER_STYLE.WND_CONTAINER_STYLE_CUSTOM)

	-- ready to draw
	if not tab then
		-- 欢迎页
		local ui = LIB.UI(wnd)
		local w, h = ui:size()
		ui:append('Shadow', { name = 'Shadow_Adv', x = 0, y = 0, color = { 140, 140, 140 } })
		ui:append('Image', { name = 'Image_Adv', x = 0, y = 0, image = PACKET_INFO.UITEX_POSTER, imageframe = (GetTime() % 2) })
		ui:append('Text', { name = 'Text_Adv', x = 10, y = 300, w = 557, font = 200 })
		ui:append('Text', { name = 'Text_Memory', x = 10, y = 300, w = 150, alpha = 150, font = 162, halign = 2 })
		ui:append('Text', { name = 'Text_Svr', x = 10, y = 345, w = 557, font = 204, text = LIB.GetServer() .. ' (' .. LIB.GetRealServer() .. ')', alpha = 220 })
		local x = 7
		-- 奇遇分享
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityNotify',
			text = _L['Show share notify.'],
			checked = MY_Serendipity.bEnable,
			oncheck = function()
				MY_Serendipity.bEnable = not MY_Serendipity.bEnable
			end,
			tip = _L['Monitor serendipity and show share notify.'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		}, true):autoWidth():width()
		local xS0 = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityAutoShare',
			text = _L['Auto share.'],
			checked = MY_Serendipity.bAutoShare,
			oncheck = function()
				MY_Serendipity.bAutoShare = not MY_Serendipity.bAutoShare
			end,
		}, true):autoWidth():width()
		-- 自动分享子项
		x = xS0
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipitySilentMode',
			text = _L['Silent mode.'],
			checked = MY_Serendipity.bSilentMode,
			oncheck = function()
				MY_Serendipity.bSilentMode = not MY_Serendipity.bSilentMode
			end,
			autovisible = function() return MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		x = x + 5
		x = x + ui:append('WndEditBox', {
			x = x, y = 375, w = 105, h = 25,
			name = 'WndEditBox_SerendipitySilentMode',
			placeholder = _L['Realname, leave blank for anonymous.'],
			tip = _L['Realname, leave blank for anonymous.'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
			limit = 6,
			text = LIB.LoadLUAData({'config/realname.jx3dat', PATH_TYPE.ROLE}) or GetClientPlayer().szName:gsub('@.-$', ''),
			onchange = function(szText)
				LIB.SaveLUAData({'config/realname.jx3dat', PATH_TYPE.ROLE}, szText)
			end,
			autovisible = function() return MY_Serendipity.bAutoShare end,
		}, true):width()
		-- 手动分享子项
		x = xS0
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityNotifyTip',
			text = _L['Show notify tip.'],
			checked = MY_Serendipity.bPreview,
			oncheck = function()
				MY_Serendipity.bPreview = not MY_Serendipity.bPreview
			end,
			autovisible = function() return not MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityNotifySound',
			text = _L['Play notify sound.'],
			checked = MY_Serendipity.bSound,
			oncheck = function()
				MY_Serendipity.bSound = not MY_Serendipity.bSound
			end,
			autoenable = function() return not MY_Serendipity.bAutoShare end,
			autovisible = function() return not MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		x = x + ui:append('WndButton', {
			x = x, y = 375,
			name = 'WndButton_SerendipitySearch',
			text = _L['serendipity'],
			onclick = function()
				LIB.OpenBrowser('https://j3cx.com/serendipity')
			end,
		}, true):autoWidth():width()
		-- 用户设置
		ui:append('WndButton', {
			x = 7, y = 405, w = 130,
			name = 'WndButton_UserPreferenceFolder',
			text = _L['Open user preference folder'],
			onclick = function()
				local szRoot = LIB.GetAbsolutePath({'', PATH_TYPE.ROLE}):gsub('/', '\\')
				if OpenFolder then
					OpenFolder(szRoot)
				end
				UI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		ui:append('WndButton', {
			x = 142, y = 405, w = 130,
			name = 'WndButton_ServerPreferenceFolder',
			text = _L['Open server preference folder'],
			onclick = function()
				local szRoot = LIB.GetAbsolutePath({'', PATH_TYPE.SERVER}):gsub('/', '\\')
				if OpenFolder then
					OpenFolder(szRoot)
				end
				UI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		ui:append('WndButton', {
			x = 277, y = 405, w = 130,
			name = 'WndButton_GlobalPreferenceFolder',
			text = _L['Open global preference folder'],
			onclick = function()
				local szRoot = LIB.GetAbsolutePath({'', PATH_TYPE.GLOBAL}):gsub('/', '\\')
				if OpenFolder then
					OpenFolder(szRoot)
				end
				UI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		wnd.OnPanelResize = function(wnd)
			local w, h = LIB.UI(wnd):size()
			local scaleH = w / 557 * 278
			local bottomH = 90
			if scaleH > h - bottomH then
				ui:children('#Shadow_Adv'):size((h - bottomH) / 278 * 557, (h - bottomH))
				ui:children('#Image_Adv'):size((h - bottomH) / 278 * 557, (h - bottomH))
				ui:children('#Text_Memory'):pos(w - 150, h - bottomH + 10)
				ui:children('#Text_Adv'):pos(10, h - bottomH + 10)
				ui:children('#Text_Svr'):pos(10, h - bottomH + 35)
			else
				ui:children('#Shadow_Adv'):size(w, scaleH)
				ui:children('#Image_Adv'):size(w, scaleH)
				ui:children('#Text_Memory'):pos(w - 150, scaleH + 10)
				ui:children('#Text_Adv'):pos(10, scaleH + 10)
				ui:children('#Text_Svr'):pos(10, scaleH + 35)
			end
			ui:children('#WndCheckBox_SerendipityNotify'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipityAutoShare'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipitySilentMode'):top(scaleH + 65)
			ui:children('#WndEditBox_SerendipitySilentMode'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipityNotifyTip'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipityNotifySound'):top(scaleH + 65)
			ui:children('#WndButton_SerendipitySearch'):top(scaleH + 65)
			ui:children('#WndButton_UserPreferenceFolder'):top(scaleH + 95)
			ui:children('#WndButton_ServerPreferenceFolder'):top(scaleH + 95)
			ui:children('#WndButton_GlobalPreferenceFolder'):top(scaleH + 95)
		end
		wnd.OnPanelResize(wnd)
		LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#TAB#DEFAULT', 500, function()
			local me = GetClientPlayer()
			if me then
				ui:children('#Text_Adv'):text(_L('%s, welcome to use %s!', me.szName, PACKET_INFO.NAME) .. 'v' .. LIB.GetVersion())
			end
			ui:children('#Text_Memory'):text(format('Memory:%.1fMB', collectgarbage('count') / 1024))
		end)
		wnd.OnPanelDeactive = function()
			LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#TAB#DEFAULT', false)
		end
		wnd:FormatAllContentPos()
	else
		if tab.fn.OnPanelActive then
			local res, err, trace = XpCall(tab.fn.OnPanelActive, wnd)
			if not res then
				FireUIEvent('CALL_LUA_ERROR', err .. '\nMY#OnPanelActive\n' .. trace .. '\n')
			end
			wnd:FormatAllContentPos()
		end
		wnd.OnPanelResize   = tab.fn.OnPanelResize
		wnd.OnPanelActive   = tab.fn.OnPanelActive
		wnd.OnPanelDeactive = tab.fn.OnPanelDeactive
		wnd.OnPanelScroll   = tab.fn.OnPanelScroll
	end
	wnd.szID = szID
end

function LIB.RedrawTab(szID)
	if LIB.GetCurrentTabID() == szID then
		LIB.SwitchTab(szID, true)
	end
end

function LIB.GetCurrentTabID()
	local frame = LIB.GetFrame()
	if not frame then
		return
	end
	return frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel').szID
end

-- 注册选项卡
-- (void) LIB.RegisterPanel( szID, szTitle, szCategory, szIconTex, options )
-- szID            选项卡唯一ID
-- szTitle         选项卡按钮标题
-- szCategory      选项卡所在分类
-- szIconTex       选项卡图标文件|图标帧
-- options         选项卡各种响应函数 {
--   options.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
--   options.OnPanelDeactive(wnd)    选项卡取消激活
--   options.bShielded               国服和谐的选项卡
-- }
-- Ex： LIB.RegisterPanel( 'Test', '测试标签', '测试', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', {255,255,0,200}, { OnPanelActive = function(wnd) end } )
function LIB.RegisterPanel(szID, szTitle, szCategory, szIconTex, options)
	local category
	for _, ctg in ipairs(TABS_LIST) do
		for i = #ctg, 1, -1 do
			if ctg[i].szID == szID then
				table.remove(ctg, i)
			end
		end
		if ctg.id == szCategory then
			category = ctg
		end
	end
	if szTitle == nil then
		return
	end

	if not category then
		table.insert(TABS_LIST, {
			id = szCategory,
		})
		category = TABS_LIST[#TABS_LIST]
	end
	-- format szIconTex
	if type(szIconTex) == 'number' then
		szIconTex = 'FromIconID|' .. szIconTex
	elseif type(szIconTex) ~= 'string' then
		szIconTex = 'UI/Image/Common/Logo.UITex|6'
	end
	local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
	if dwIconFrame then
		dwIconFrame = tonumber(dwIconFrame)
	end
	szIconTex = string.gsub(szIconTex, '%|.*', '')

	-- format other params
	if not IsTable(options) then
		options = {}
	end
	table.insert( category, {
		szID        = szID       ,
		szTitle     = szTitle    ,
		szCategory  = szCategory ,
		szIconTex   = szIconTex  ,
		dwIconFrame = dwIconFrame,
		bShielded   = options.bShielded,
		nShielded   = options.nShielded,
		fn          = {
			OnPanelResize   = options.OnPanelResize  ,
			OnPanelActive   = options.OnPanelActive  ,
			OnPanelDeactive = options.OnPanelDeactive,
			OnPanelScroll   = options.OnPanelScroll  ,
		},
	})

	if LIB.IsInitialized() then
		LIB.RedrawCategory()
	end
end
end

---------------------------------------------------------------------------------------------
-- 窗口函数
---------------------------------------------------------------------------------------------
local function OnSizeChanged()
	local frame = this
	if not frame then
		return
	end
	-- fix size
	local nWidth, nHeight = frame:GetSize()
	local wnd = frame:Lookup('Wnd_Total')
	wnd:Lookup('WndContainer_Category'):SetSize(nWidth - 22, 32)
	wnd:Lookup('WndContainer_Category'):FormatAllContentPos()
	wnd:Lookup('Btn_Weibo'):SetRelPos(nWidth - 135, 55)
	wnd:Lookup('WndScroll_Tabs'):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):FormatAllItemPos()
	wnd:Lookup('WndScroll_Tabs/ScrollBar_Tabs'):SetSize(16, nHeight - 111)

	local hWnd = wnd:Lookup('', '')
	wnd:Lookup('', ''):SetSize(nWidth, nHeight)
	hWnd:Lookup('Image_Breaker'):SetSize(6, nHeight - 340)
	hWnd:Lookup('Image_TabBg'):SetSize(nWidth - 2, 33)
	hWnd:Lookup('Handle_DBClick'):SetSize(nWidth, 54)

	local bHideTabs = nWidth < 550
	wnd:Lookup('WndScroll_Tabs'):SetVisible(not bHideTabs)
	hWnd:Lookup('Image_Breaker'):SetVisible(not bHideTabs)

	if bHideTabs then
		nWidth = nWidth + 181
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(5)
	else
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(186)
	end

	wnd:Lookup('WndScroll_MainPanel'):SetSize(nWidth - 191, nHeight - 100)
	wnd:Lookup('WndScroll_MainPanel/ScrollBar_MainPanel'):SetSize(20, nHeight - 100)
	wnd:Lookup('WndScroll_MainPanel/ScrollBar_MainPanel'):SetRelPos(nWidth - 209, 0)
	wnd:Lookup('WndScroll_MainPanel/WndContainer_MainPanel'):SetSize(nWidth - 201, nHeight - 100)
	wnd:Lookup('WndScroll_MainPanel/WndContainer_MainPanel', ''):SetSize(nWidth - 201, nHeight - 100)
	local hWndMainPanel = frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	if hWndMainPanel.OnPanelResize then
		local res, err, trace = XpCall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. '\nMY#OnPanelResize\n' .. trace .. '\n')
		end
		hWndMainPanel:FormatAllContentPos()
	elseif hWndMainPanel.OnPanelActive then
		if hWndMainPanel.OnPanelDeactive then
			local res, err, trace = XpCall(hWndMainPanel.OnPanelDeactive, hWndMainPanel)
			if not res then
				FireUIEvent('CALL_LUA_ERROR', err .. '\nMY#OnPanelResize->OnPanelDeactive\n' .. trace .. '\n')
			end
		end
		hWndMainPanel:Clear()
		hWndMainPanel:Lookup('', ''):Clear()
		local res, err, trace = XpCall(hWndMainPanel.OnPanelActive, hWndMainPanel)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. '\nMY#OnPanelResize->OnPanelActive\n' .. trace .. '\n')
		end
		hWndMainPanel:FormatAllContentPos()
	end
	hWndMainPanel:FormatAllContentPos()
	hWndMainPanel:Lookup('', ''):FormatAllItemPos()
	-- reset position
	local an = GetFrameAnchor(frame)
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function LIB.OnItemLButtonDBClick()
	local name = this:GetName()
	if name == 'Handle_DBClick' then
		this:GetRoot():Lookup('CheckBox_Maximize'):ToggleCheck()
	end
end

function LIB.OnMouseWheel()
	local p = this
	while p do
		if p:GetType() == 'WndContainer' then
			return
		end
		p = p:GetParent()
	end
	return true
end

function LIB.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		LIB.ClosePanel()
	elseif name == 'Btn_Weibo' then
		LIB.OpenBrowser(PACKET_INFO.AUTHOR_WEIBO_URL)
	end
end

do local anchor, w, h
function LIB.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		local ui = LIB.UI(this:GetRoot())
		anchor = ui:anchor()
		w, h = ui:size()
		ui:pos(0, 0):event('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
			ui:size(Station.GetClientSize())
		end):drag(false)
		LIB.ResizePanel(Station.GetClientSize())
	end
end

function LIB.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		LIB.ResizePanel(w, h)
		LIB.UI(this:GetRoot())
			:event('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
			:drag(true)
			:anchor(anchor)
	end
end
end

function LIB.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = LIB.UI(this:GetRoot()):size()
	end
end

function LIB.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		HideTip()
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nW = math.max(this.fDragW + nDeltaX, 500)
		local nH = math.max(this.fDragH + nDeltaY, 300)
		LIB.ResizePanel(nW, nH)
	end
end

function LIB.OnFrameCreate()
	local fScale = 1 + math.max(Font.GetOffset() * 0.03, 0)
	this:Lookup('', 'Text_Title'):SetText(PACKET_INFO.NAME .. ' v' .. LIB.GetVersion() .. ' Build ' .. PACKET_INFO.BUILD)
	this:Lookup('', 'Text_Author'):SetText('-- by ' .. PACKET_INFO.AUTHOR_SIGNATURE)
	this:Lookup('Wnd_Total/Btn_Weibo', 'Text_Default'):SetText(_L('Author @%s', PACKET_INFO.AUTHOR_WEIBO))
	this:Lookup('Wnd_Total/Btn_Weibo', 'Image_Icon'):FromUITex(PACKET_INFO.UITEX_COMMON, PACKET_INFO.MAINICON_FRAME)
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
	this.intact = true
	LIB.RedrawCategory()
	LIB.ResizePanel(780 * fScale, 540 * fScale)
	LIB.ExecuteWithThis(this, OnSizeChanged)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:CorrectPos()
	this:RegisterEvent('UI_SCALED')
	LIB.UI(this):size(OnSizeChanged)
end

function LIB.OnEvent(event)
	if event == 'UI_SCALED' then
		LIB.ExecuteWithThis(this:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel'), LIB.OnScrollBarPosChanged)
		OnSizeChanged()
	end
end

function LIB.OnScrollBarPosChanged()
	local name = this:GetName()
	if name == 'ScrollBar_MainPanel' then
		local wnd = this:GetParent():Lookup('WndContainer_MainPanel')
		if not wnd.OnPanelScroll then
			return
		end
		local scale = Station.GetUIScale()
		local scrollX, scrollY = wnd:GetStartRelPos()
		scrollX = scrollX == 0 and 0 or -scrollX / scale
		scrollY = scrollY == 0 and 0 or -scrollY / scale
		wnd.OnPanelScroll(wnd, scrollX, scrollY)
	end
end

---------------------------------------------------------------------------------------------
-- 基础库界面注册
---------------------------------------------------------------------------------------------
-- 全局染色设置
do
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 20
	local x, y = X, Y

	ui:append('Text', {
		x = X - 10, y = y,
		text = _L['Force color'],
		color = { 255, 255, 0 },
	}, true):autoWidth()
	x, y = X, y + 30
	for _, dwForceID in pairs_c(CONSTANT.FORCE_TYPE) do
		local x0 = x
		local sha = ui:append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { LIB.GetForceColor(dwForceID, 'background') },
		}, true)
		local txt = ui:append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { LIB.GetForceColor(dwForceID, 'foreground') },
		}, true)
		x = x + 105
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetForceColor(dwForceID, 'foreground') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					LIB.SetForceColor(dwForceID, 'foreground', { r, g, b })
					txt:color(r, g, b)
					UI(this):color(r, g, b)
				end)
			end,
		})
		x = x + 30
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetForceColor(dwForceID, 'background') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					LIB.SetForceColor(dwForceID, 'background', { r, g, b })
					sha:color(r, g, b)
					UI(this):color(r, g, b)
				end)
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = X
			y = y + 35
		end
	end
	ui:append('WndButton2', {
		x = x, y = y, w = 160,
		text = _L['Restore default'],
		onclick = function()
			LIB.SetForceColor('reset')
			LIB.SwitchTab('GlobalColor', true)
		end,
	})

	y = y + 45
	ui:append('Text', {
		x = X - 10, y = y,
		text = _L['Camp color'],
		color = { 255, 255, 0 },
	}, true):autoWidth()
	x, y = X, y + 30
	for _, nCamp in ipairs({ CAMP.NEUTRAL, CAMP.GOOD, CAMP.EVIL }) do
		local x0 = x
		local sha = ui:append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { LIB.GetCampColor(nCamp, 'background') },
		}, true)
		local txt = ui:append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { LIB.GetCampColor(nCamp, 'foreground') },
		}, true)
		x = x + 105
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetCampColor(nCamp, 'foreground') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					LIB.SetCampColor(nCamp, 'foreground', { r, g, b })
					txt:color(r, g, b)
					UI(this):color(r, g, b)
				end)
			end,
		})
		x = x + 30
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { LIB.GetCampColor(nCamp, 'background') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					LIB.SetCampColor(nCamp, 'background', { r, g, b })
					sha:color(r, g, b)
					UI(this):color(r, g, b)
				end)
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = X
			y = y + 35
		end
	end
	ui:append('WndButton2', {
		x = x, y = y, w = 160,
		text = _L['Restore default'],
		onclick = function()
			LIB.SetCampColor('reset')
			LIB.SwitchTab('GlobalColor', true)
		end,
	})
end
LIB.RegisterPanel('GlobalColor', _L['GlobalColor'], _L['System'], 'ui\\Image\\button\\CommonButton_1.UITex|70', PS)
end

-- 全局杂项设置
do
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 20
	local x, y = X, Y

	ui:append('Text', {
		x = X - 10, y = y,
		text = _L['Distance type'],
		color = { 255, 255, 0 },
	}, true):autoWidth()
	x, y = X, y + 30

	for _, p in ipairs(LIB.GetDistanceTypeList()) do
		x = x + ui:append('WndRadioBox', {
			x = x, y = y, w = 100, h = 25, group = 'distance type',
			text = p.szText,
			checked = LIB.GetGlobalDistanceType() == p.szType,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				LIB.SetGlobalDistanceType(p.szType)
			end,
		}, true):autoWidth():width() + 10
	end
	x, y = X, y + 30

	ui:append('Text', {
		x = X - 10, y = y,
		text = _L['System Info'],
		color = { 255, 255, 0 },
	}, true):autoWidth()
	y = y + 30

	local uiMemory = ui:append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	}, true)
	y = y + 25

	local uiSize = ui:append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	}, true)
	y = y + 25

	local uiUIScale = ui:append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	}, true)
	y = y + 25

	local uiFontScale = ui:append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	}, true)
	y = y + 25

	local function onRefresh()
		uiMemory:text(format('Memory: %.2fMB', collectgarbage('count') / 1024))
		uiSize:text(format('UISize: %.2fx%.2f', Station.GetClientSize()))
		uiUIScale:text(format('UIScale: %.2f (%.2f)', LIB.GetUIScale(), LIB.GetOriginUIScale()))
		uiFontScale:text(format('FontScale: %.2f (%.2f)', LIB.GetFontScale(), Font.GetOffset()))
	end
	onRefresh()
	LIB.BreatheCall('GlobalConfig', onRefresh)
end

function PS.OnPanelDeactive()
	LIB.BreatheCall('GlobalConfig', false)
end
LIB.RegisterPanel('GlobalConfig', _L['GlobalConfig'], _L['System'], 'ui\\Image\\Minimap\\Minimap.UITex|181', PS)
end
