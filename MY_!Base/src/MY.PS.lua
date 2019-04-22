--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 插件主界面相关函数
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack()
local INI_PATH = MY.GetAddonInfo().szFrameworkRoot ..'ui/MY.ini'
---------------------------------------------------------------------------------------------
-- 界面开关
---------------------------------------------------------------------------------------------
function MY.GetFrame()
	return Station.Lookup('Normal/MY')
end

function MY.OpenPanel()
	if not MY.IsInitialized() then
		return
	end
	local frame = MY.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, 'MY')
		frame:Hide()
		frame.bVisible = false
		MY.CheckTutorial()
	end
	return frame
end

function MY.ClosePanel()
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	MY.SwitchTab()
	MY.HidePanel(false, true)
	Wnd.CloseWindow(frame)
end

function MY.ReopenPanel()
	if not MY.IsPanelOpened() then
		return
	end
	local bVisible = MY.IsPanelVisible()
	MY.ClosePanel()
	MY.OpenPanel()
	MY.TogglePanel(bVisible, true, true)
end

function MY.ShowPanel(bMute, bNoAnimate)
	local frame = MY.OpenPanel()
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
	MY.RegisterEsc('MY', MY.IsPanelVisible, function() MY.HidePanel() end)
end

function MY.HidePanel(bMute, bNoAnimate)
	local frame = MY.GetFrame()
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
	MY.RegisterEsc('MY')
	Wnd.CloseWindow('PopupMenuPanel')
end

function MY.TogglePanel(bVisible, ...)
	if bVisible == nil then
		if MY.IsPanelVisible() then
			MY.HidePanel()
		else
			MY.ShowPanel()
			MY.FocusPanel()
		end
	elseif bVisible then
		MY.ShowPanel(...)
		MY.FocusPanel()
	else
		MY.HidePanel(...)
	end
end

function MY.FocusPanel(bForce)
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	if not bForce and not Cursor.IsVisible() then
		return
	end
	Station.SetFocusWindow(frame)
end

function MY.ResizePanel(nWidth, nHeight)
	local hFrame = MY.GetFrame()
	if not hFrame then
		return
	end
	MY.UI(hFrame):size(nWidth, nHeight)
end

function MY.IsPanelVisible()
	return MY.GetFrame() and MY.GetFrame():IsVisible()
end

-- if panel visible
function MY.IsPanelOpened()
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
function MY.RedrawCategory(szCategory)
	local frame = MY.GetFrame()
	if not frame then
		return
	end

	-- draw category
	local wndCategoryList = frame:Lookup('Wnd_Total/WndContainer_Category')
	wndCategoryList:Clear()
	for _, ctg in ipairs(TABS_LIST) do
		local nCount = 0
		for i, tab in ipairs(ctg) do
			if not (tab.bShielded and MY.IsShieldedVersion()) then
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
				MY.RedrawTabs(chkCategory.szCategory)
			end
			szCategory = szCategory or ctg.id
		end
	end
	wndCategoryList:FormatAllContentPos()

	MY.SwitchCategory(szCategory)
end

-- MY.SwitchCategory(szCategory)
function MY.SwitchCategory(szCategory)
	local frame = MY.GetFrame()
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

function MY.RedrawTabs(szCategory)
	local frame = MY.GetFrame()
	if not (frame and szCategory) then
		return
	end

	-- draw tabs
	local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	hTabs:Clear()

	for _, ctg in ipairs(TABS_LIST) do
		if ctg.id == szCategory then
			for i, tab in ipairs(ctg) do
				if not (tab.bShielded and MY.IsShieldedVersion()) then
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
					hTab:Lookup('Image_Bg'):FromUITex(MY.GetAddonInfo().szUITexCommon, 3)
					hTab:Lookup('Image_Bg_Active'):FromUITex(MY.GetAddonInfo().szUITexCommon, 1)
					hTab:Lookup('Image_Bg_Hover'):FromUITex(MY.GetAddonInfo().szUITexCommon, 2)
					hTab.OnItemLButtonClick = function()
						MY.SwitchTab(this.szID)
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

	MY.SwitchTab()
end

function MY.SwitchTab(szID, bForceUpdate)
	local frame = MY.GetFrame()
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
		if not tab then
			MY.Debug({_L('Cannot find tab: %s', szID)}, 'MY.SwitchTab#' .. szID, DEBUG_LEVEL.WARNING)
		end
	end

	-- check if category is right
	if category then
		local szCategory = frame:Lookup('Wnd_Total/WndContainer_Category').szCategory
		if category.id ~= szCategory then
			MY.SwitchCategory(category.id)
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
		local res, err = pcall(wnd.OnPanelDeactive, wnd)
		if not res then
			MY.Debug({GetTraceback(err)}, 'MY#OnPanelDeactive', DEBUG_LEVEL.ERROR)
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
	wnd:SetContainerType(WND_CONTAINER_STYLE.WND_CONTAINER_STYLE_CUSTOM)

	-- ready to draw
	if not tab then
		-- 欢迎页
		local ui = MY.UI(wnd)
		local w, h = ui:size()
		ui:append('Image', { name = 'Image_Adv', x = 0, y = 0, image = MY.GetAddonInfo().szUITexPoster, imageframe = (GetTime() % 2) })
		ui:append('Text', { name = 'Text_Adv', x = 10, y = 300, w = 557, font = 200 })
		ui:append('Text', { name = 'Text_Memory', x = 10, y = 300, w = 150, alpha = 150, font = 162, halign = 2 })
		ui:append('Text', { name = 'Text_Svr', x = 10, y = 345, w = 557, font = 204, text = MY.GetServer() .. ' (' .. MY.GetRealServer() .. ')', alpha = 220 })
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
			tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
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
			tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			limit = 6,
			text = MY.LoadLUAData({'config/realname.jx3dat', PATH_TYPE.ROLE}) or GetClientPlayer().szName:gsub('@.-$', ''),
			onchange = function(szText)
				MY.SaveLUAData({'config/realname.jx3dat', PATH_TYPE.ROLE}, szText)
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
				MY.OpenBrowser('https://j3cx.com/serendipity')
			end,
		}, true):autoWidth():width()
		-- 用户设置
		ui:append('WndButton', {
			x = 7, y = 405, w = 130,
			name = 'WndButton_UserPreferenceFolder',
			text = _L['Open user preference folder'],
			onclick = function()
				local szRoot = MY.FormatPath({'', PATH_TYPE.ROLE})
				if OpenFolder then
					OpenFolder(szRoot)
				end
				MY.UI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		ui:append('WndButton', {
			x = 142, y = 405, w = 130,
			name = 'WndButton_ServerPreferenceFolder',
			text = _L['Open server preference folder'],
			onclick = function()
				local szRoot = MY.FormatPath({'', PATH_TYPE.SERVER})
				if OpenFolder then
					OpenFolder(szRoot)
				end
				MY.UI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		ui:append('WndButton', {
			x = 277, y = 405, w = 130,
			name = 'WndButton_GlobalPreferenceFolder',
			text = _L['Open global preference folder'],
			onclick = function()
				local szRoot = MY.FormatPath({'', PATH_TYPE.GLOBAL})
				if OpenFolder then
					OpenFolder(szRoot)
				end
				MY.UI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		wnd.OnPanelResize = function(wnd)
			local w, h = MY.UI(wnd):size()
			local scaleH = w / 557 * 278
			local bottomH = 90
			if scaleH > h - bottomH then
				ui:children('#Image_Adv'):size((h - bottomH) / 278 * 557, (h - bottomH))
				ui:children('#Text_Memory'):pos(w - 150, h - bottomH + 10)
				ui:children('#Text_Adv'):pos(10, h - bottomH + 10)
				ui:children('#Text_Svr'):pos(10, h - bottomH + 35)
			else
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
		MY.BreatheCall('MYLIB#TAB#DEFAULT', 500, function()
			local player = GetClientPlayer()
			if player then
				ui:children('#Text_Adv'):text(_L('%s, welcome to use mingyi plugins!', player.szName) .. 'v' .. MY.GetVersion())
			end
			ui:children('#Text_Memory'):text(format('Memory:%.1fMB', collectgarbage('count') / 1024))
		end)
		wnd.OnPanelDeactive = function()
			MY.BreatheCall('MYLIB#TAB#DEFAULT', false)
		end
		wnd:FormatAllContentPos()
	else
		if tab.fn.OnPanelActive then
			local res, err = pcall(tab.fn.OnPanelActive, wnd)
			if not res then
				MY.Debug({GetTraceback(err)}, 'MY#OnPanelActive', DEBUG_LEVEL.ERROR)
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

function MY.RedrawTab(szID)
	if MY.GetCurrentTabID() == szID then
		MY.SwitchTab(szID, true)
	end
end

function MY.GetCurrentTabID()
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	return frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel').szID
end

-- 注册选项卡
-- (void) MY.RegisterPanel( szID, szTitle, szCategory, szIconTex, options )
-- szID            选项卡唯一ID
-- szTitle         选项卡按钮标题
-- szCategory      选项卡所在分类
-- szIconTex       选项卡图标文件|图标帧
-- options         选项卡各种响应函数 {
--   options.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
--   options.OnPanelDeactive(wnd)    选项卡取消激活
--   options.bShielded               国服和谐的选项卡
-- }
-- Ex： MY.RegisterPanel( 'Test', '测试标签', '测试', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', {255,255,0,200}, { OnPanelActive = function(wnd) end } )
function MY.RegisterPanel(szID, szTitle, szCategory, szIconTex, options)
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
		fn          = {
			OnPanelResize   = options.OnPanelResize  ,
			OnPanelActive   = options.OnPanelActive  ,
			OnPanelDeactive = options.OnPanelDeactive,
			OnPanelScroll   = options.OnPanelScroll  ,
		},
	})

	if MY.IsInitialized() then
		MY.RedrawCategory()
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
		local res, err = pcall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			MY.Debug({GetTraceback(err)}, 'MY#OnPanelResize', DEBUG_LEVEL.ERROR)
		end
		hWndMainPanel:FormatAllContentPos()
	elseif hWndMainPanel.OnPanelActive then
		if hWndMainPanel.OnPanelDeactive then
			local res, err = pcall(hWndMainPanel.OnPanelDeactive, hWndMainPanel)
			if not res then
				MY.Debug({GetTraceback(err)}, 'MY#OnPanelResize->OnPanelDeactive', DEBUG_LEVEL.ERROR)
			end
		end
		hWndMainPanel:Clear()
		hWndMainPanel:Lookup('', ''):Clear()
		local res, err = pcall(hWndMainPanel.OnPanelActive, hWndMainPanel)
		if not res then
			MY.Debug({GetTraceback(err)}, 'MY#OnPanelResize->OnPanelActive', DEBUG_LEVEL.ERROR)
		end
		hWndMainPanel:FormatAllContentPos()
	end
	hWndMainPanel:FormatAllContentPos()
	hWndMainPanel:Lookup('', ''):FormatAllItemPos()
	-- reset position
	local an = GetFrameAnchor(frame)
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function MY.OnItemLButtonDBClick()
	local name = this:GetName()
	if name == 'Handle_DBClick' then
		this:GetRoot():Lookup('CheckBox_Maximize'):ToggleCheck()
	end
end

function MY.OnMouseWheel()
	local p = this
	while p do
		if p:GetType() == 'WndContainer' then
			return
		end
		p = p:GetParent()
	end
	return true
end

function MY.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		MY.ClosePanel()
	elseif name == 'Btn_Weibo' then
		MY.OpenBrowser('https://weibo.com/zymah')
	end
end

do local anchor, w, h
function MY.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		local ui = MY.UI(this:GetRoot())
		anchor = ui:anchor()
		w, h = ui:size()
		ui:pos(0, 0):event('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
			ui:size(Station.GetClientSize())
		end):drag(false)
		MY.ResizePanel(Station.GetClientSize())
	end
end

function MY.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		MY.ResizePanel(w, h)
		MY.UI(this:GetRoot())
			:event('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
			:drag(true)
			:anchor(anchor)
	end
end
end

function MY.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = MY.UI(this:GetRoot()):size()
	end
end

function MY.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		HideTip()
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nW = math.max(this.fDragW + nDeltaX, 500)
		local nH = math.max(this.fDragH + nDeltaY, 300)
		MY.ResizePanel(nW, nH)
	end
end

function MY.OnFrameCreate()
	local fScale = 1 + math.max(Font.GetOffset() * 0.03, 0)
	this:Lookup('', 'Text_Title'):SetText(_L['mingyi plugins'] .. ' v' .. MY.GetVersion() .. ' Build ' .. MY.GetAddonInfo().szBuild)
	this:Lookup('', 'Text_Author'):SetText(_L['author\'s signature'])
	this:Lookup('', 'Image_Icon'):SetSize(30, 30)
	this:Lookup('', 'Image_Icon'):FromUITex(MY.GetAddonInfo().szUITexCommon, 0)
	this:Lookup('Wnd_Total/Btn_Weibo', 'Text_Default'):SetText(_L['author\'s weibo'])
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
	this.intact = true
	MY.RedrawCategory()
	MY.ResizePanel(780 * fScale, 540 * fScale)
	MY.ExecuteWithThis(this, OnSizeChanged)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:CorrectPos()
	this:RegisterEvent('UI_SCALED')
	MY.UI(this):size(OnSizeChanged)
end

function MY.OnEvent(event)
	if event == 'UI_SCALED' then
		MY.ExecuteWithThis(this:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel'), MY.OnScrollBarPosChanged)
		OnSizeChanged()
	end
end

function MY.OnScrollBarPosChanged()
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
	for _, dwForceID in pairs_c(FORCE_TYPE) do
		local x0 = x
		local sha = ui:append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { MY.GetForceColor(dwForceID, 'background') },
		}, true)
		local txt = ui:append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { MY.GetForceColor(dwForceID, 'foreground') },
		}, true)
		x = x + 105
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetForceColor(dwForceID, 'foreground') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					MY.SetForceColor(dwForceID, 'foreground', { r, g, b })
					txt:color(r, g, b)
					UI(this):color(r, g, b)
				end)
			end,
		})
		x = x + 30
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetForceColor(dwForceID, 'background') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					MY.SetForceColor(dwForceID, 'background', { r, g, b })
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
			MY.SetForceColor('reset')
			MY.SwitchTab('GlobalColor', true)
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
			color = { MY.GetCampColor(nCamp, 'background') },
		}, true)
		local txt = ui:append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { MY.GetCampColor(nCamp, 'foreground') },
		}, true)
		x = x + 105
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetCampColor(nCamp, 'foreground') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					MY.SetCampColor(nCamp, 'foreground', { r, g, b })
					txt:color(r, g, b)
					UI(this):color(r, g, b)
				end)
			end,
		})
		x = x + 30
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetCampColor(nCamp, 'background') },
			onclick = function()
				local this = this
				UI.OpenColorPicker(function(r, g, b)
					MY.SetCampColor(nCamp, 'background', { r, g, b })
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
			MY.SetCampColor('reset')
			MY.SwitchTab('GlobalColor', true)
		end,
	})
end
MY.RegisterPanel('GlobalColor', _L['GlobalColor'], _L['System'], 'ui\\Image\\button\\CommonButton_1.UITex|70', PS)
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

	for _, p in ipairs(MY.GetDistanceTypeList()) do
		x = x + ui:append('WndRadioBox', {
			x = x, y = y, w = 100, h = 25, group = 'distance type',
			text = p.szText,
			checked = MY.GetGlobalDistanceType() == p.szType,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				MY.SetGlobalDistanceType(p.szType)
			end,
		}, true):autoWidth():width() + 10
	end
end
MY.RegisterPanel('GlobalConfig', _L['GlobalConfig'], _L['System'], 'ui\\Image\\Minimap\\Minimap.UITex|181', PS)
end
