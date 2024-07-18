--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 插件主界面相关函数
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/PS')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT ..'ui/PS.ini'
local IMG_PATH = X.PACKET_INFO.FRAMEWORK_ROOT ..'img/PS.UITex'
local FRAME_NAME = X.NSFormatString('{$NS}_PS')

local D = {}
---------------------------------------------------------------------------------------------
-- 界面开关
---------------------------------------------------------------------------------------------
function X.GetFrame()
	return Station.SearchFrame(FRAME_NAME)
end

function X.OpenPanel()
	if not X.AssertVersion('', '', '*') then
		return
	end
	if not X.IsInitialized() then
		return
	end
	local frame = X.GetFrame()
	if not frame then
		frame = X.UI.OpenFrame(INI_PATH, FRAME_NAME)
		frame:Hide()
		frame.bVisible = false
		X.CheckTutorial()
	end
	return frame
end

function X.ClosePanel()
	local frame = X.GetFrame()
	if not frame then
		return
	end
	X.SwitchTab('Welcome')
	X.HidePanel(false, true)
	X.UI.CloseFrame(frame)
end

function X.ReopenPanel()
	if not X.IsPanelOpened() then
		return
	end
	local bVisible = X.IsPanelVisible()
	local szCurrentTabID = X.GetCurrentTabID()
	X.ClosePanel()
	X.OpenPanel()
	if szCurrentTabID then
		X.SwitchTab(szCurrentTabID)
	end
	X.TogglePanel(bVisible, true, true)
end

function X.ShowPanel(bMute, bNoAnimate)
	local frame = X.OpenPanel()
	if not frame then
		return
	end
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
	X.RegisterEsc(X.PACKET_INFO.NAME_SPACE, X.IsPanelVisible, function() X.HidePanel() end)
end

function X.HidePanel(bMute, bNoAnimate)
	local frame = X.GetFrame()
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
	X.RegisterEsc(X.PACKET_INFO.NAME_SPACE)
	X.UI.ClosePopupMenu()
end

function X.TogglePanel(bVisible, ...)
	if bVisible == nil then
		if X.IsPanelVisible() then
			X.HidePanel()
		else
			X.ShowPanel()
			X.FocusPanel()
		end
	elseif bVisible then
		X.ShowPanel(...)
		X.FocusPanel()
	else
		X.HidePanel(...)
	end
end

function X.FocusPanel(bForce)
	local frame = X.GetFrame()
	if not frame then
		return
	end
	if not bForce and not Cursor.IsVisible() then
		return
	end
	Station.SetFocusWindow(frame)
end

function X.IsPanelVisible()
	local frame = X.GetFrame()
	return frame and frame:IsVisible()
end

function X.IsPanelOpened()
	return not not X.GetFrame()
end

---------------------------------------------------------------------------------------------
-- 选项卡
---------------------------------------------------------------------------------------------
local PANEL_CATEGORY_LIST = {
	{ szName = _L['General'] },
	{ szName = _L['Target' ] },
	{ szName = _L['Chat'   ] },
	{ szName = _L['Battle' ] },
	{ szName = _L['Raid'   ] },
	{ szName = _L['System' ] },
	{ szName = _L['Search' ] },
	{ szName = _L['Others' ] },
}
local PANEL_TAB_LIST = {}

function X.GetPanelCategoryList()
	return X.Clone(PANEL_CATEGORY_LIST)
end

local function IsTabRestricted(tTab)
	if tTab.szRestriction and X.IsRestricted(tTab.szRestriction) then
		return true
	end
	if tTab.IsRestricted then
		return tTab.IsRestricted()
	end
	return false
end

-- X.SwitchCategory(szCategory)
function X.SwitchCategory(szCategory)
	local frame = X.GetFrame()
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
		chk:Check(true)
	end
end

function X.SwitchTab(szKey, bForceUpdate)
	local frame = X.GetFrame()
	if not frame then
		return
	end
	local tTab
	for _, t in ipairs(PANEL_TAB_LIST) do
		if t.szKey == szKey then
			tTab = t
			break
		end
	end
	if not tTab then
		--[[#DEBUG BEGIN]]
		if not tTab then
			X.OutputDebugMessage(X.NSFormatString('{$NS}.SwitchTab'), _L('Cannot find tab: %s', szKey), X.DEBUG_LEVEL.WARNING)
		end
		--[[#DEBUG END]]
		return
	end
	-- 判断主分类是否正确
	if tTab.szCategory and frame.szCurrentCategoryName ~= tTab.szCategory then
		X.SwitchCategory(tTab.szCategory)
	end
	-- 判断标签页是否已激活
	if frame.szCurrentTabKey == tTab.szKey and not bForceUpdate then
		return
	end
	if frame.szCurrentTabKey ~= tTab.szKey then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	-- 处理标签页背景选中状态
	local scrollTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	for i = 0, scrollTabs:GetItemCount() - 1 do
		if scrollTabs:Lookup(i).szKey == szKey then
			scrollTabs:Lookup(i):Lookup('Image_Bg_Active'):Show()
		else
			scrollTabs:Lookup(i):Lookup('Image_Bg_Active'):Hide()
		end
	end
	-- 事件处理、界面绘制
	-- get main panel
	local wnd = frame.MAIN_WND
	local scroll = frame.MAIN_SCROLL
	-- fire custom registered on switch event
	if wnd.OnPanelDeactive then
		local res, err, trace = X.XpCall(wnd.OnPanelDeactive, wnd)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelDeactive'), trace)
		end
	end
	-- clear all events
	wnd.OnPanelActive   = nil
	wnd.OnPanelResize   = nil
	wnd.OnPanelScroll   = nil
	wnd.OnPanelBreathe  = nil
	wnd.OnPanelDeactive = nil
	-- reset main panel status
	scroll:SetScrollPos(0)
	wnd:Clear()
	wnd:Lookup('', ''):Clear()
	wnd:SetContainerType(X.UI.WND_CONTAINER_STYLE.CUSTOM)
	-- ready to draw
	if tTab.OnPanelActive then
		local res, err, trace = X.XpCall(tTab.OnPanelActive, wnd)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelActive'), trace)
		end
		wnd:FormatAllContentPos()
	end
	wnd.OnPanelActive   = tTab.OnPanelActive
	wnd.OnPanelResize   = tTab.OnPanelResize
	wnd.OnPanelScroll   = tTab.OnPanelScroll
	wnd.OnPanelBreathe  = tTab.OnPanelBreathe
	wnd.OnPanelDeactive = tTab.OnPanelDeactive
	frame.szCurrentTabKey = szKey
end

function X.RedrawTab(szKey)
	if X.GetCurrentTabID() == szKey then
		X.SwitchTab(szKey, true)
	end
end

function X.GetCurrentTabID()
	local frame = X.GetFrame()
	if not frame then
		return
	end
	return frame.szCurrentTabKey
end

-- 注册选项卡
-- (void) X.RegisterPanel(szCategory, szKey, szName, szIconTex, options)
-- szCategory      选项卡所在分类
-- szKey           选项卡唯一 KEY
-- szName          选项卡按钮标题
-- szIconTex       选项卡图标文件|图标帧
-- options         选项卡各种响应函数 {
--   options.szRestriction           选项卡功能限制获取标识符
--   options.bWelcome                欢迎页（默认页）选项卡
--   options.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
--   options.OnPanelDeactive(wnd)    选项卡取消激活
-- }
-- Ex： X.RegisterPanel('测试', 'Test', '测试标签', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', { OnPanelActive = function(wnd) end })
function X.RegisterPanel(szCategory, szKey, szName, szIconTex, options)
	-- 分类不存在则创建
	if not options.bHide then
		local bExist = false
		for _, v in ipairs(PANEL_CATEGORY_LIST) do
			if v.szName == szCategory then
				bExist = true
				break
			end
		end
		if not bExist then
			table.insert(PANEL_CATEGORY_LIST, {
				szName = szCategory,
			})
		end
	end
	-- 移除已存在的
	for i, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szKey == szKey then
			table.remove(tTab, i)
			break
		end
	end
	-- 判断非注销面板调用
	if szName ~= false then
		-- 格式化图标信息
		if X.IsNumber(szIconTex) then
			szIconTex = 'FromIconID|' .. szIconTex
		elseif not X.IsString(szIconTex) then
			szIconTex = 'UI/Image/Common/Logo.UITex|6'
		end
		local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
		if dwIconFrame then
			dwIconFrame = tonumber(dwIconFrame)
			szIconTex = string.gsub(szIconTex, '%|.*', '')
		end
		local nPriority = options.nPriority or (GetStringCRC(szKey) + 100000)
		-- 创建数据结构、插入数组
		table.insert(PANEL_TAB_LIST, {
			szKey           = szKey                  ,
			szName          = szName                 ,
			szCategory      = szCategory             ,
			szIconTex       = szIconTex              ,
			dwIconFrame     = dwIconFrame            ,
			nPriority       = nPriority              ,
			bWelcome        = options.bWelcome       ,
			bHide           = options.bHide          ,
			szRestriction   = options.szRestriction  ,
			IsRestricted    = options.IsRestricted   ,
			OnPanelActive   = options.OnPanelActive  ,
			OnPanelScroll   = options.OnPanelScroll  ,
			OnPanelResize   = options.OnPanelResize  ,
			OnPanelBreathe  = options.OnPanelBreathe ,
			OnPanelDeactive = options.OnPanelDeactive,
		})
		-- 重新根据权重排序数组
		table.sort(PANEL_TAB_LIST, function(t1, t2)
			if t1.bWelcome then
				return true
			elseif t2.bWelcome then
				return false
			else
				return t1.nPriority < t2.nPriority
			end
		end)
	end
	-- 通知重绘
	FireUIEvent(X.NSFormatString('{$NS}_PANEL_UPDATE'))
end

---------------------------------------------------------------------------------------------
-- 窗口函数
---------------------------------------------------------------------------------------------
function D.ResizePanel(frame, nWidth, nHeight)
	X.UI(frame):Size(nWidth, nHeight)
end

function D.RedrawCategory(frame, szCategory)
	local container = frame:Lookup('Wnd_Total/WndContainer_Category')
	container:Clear()
	for _, tCategory in ipairs(PANEL_CATEGORY_LIST) do
		local bExist = false
		for _, tTab in ipairs(PANEL_TAB_LIST) do
			if tTab.szCategory == tCategory.szName and not tTab.bHide and not IsTabRestricted(tTab) then
				bExist = true
				break
			end
		end
		if bExist then
			local chkCategory = container:AppendContentFromIni(INI_PATH, 'CheckBox_Category')
			if not szCategory then
				szCategory = tCategory.szName
			end
			chkCategory.szCategory = tCategory.szName
			chkCategory:Lookup('', 'Text_Category'):SetText(tCategory.szName)
		end
	end
	container:FormatAllContentPos()
	X.SwitchCategory(szCategory)
end

function D.RedrawTabs(frame, szCategory)
	local scroll = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	scroll:Clear()
	for _, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szCategory == szCategory and not tTab.bHide and not IsTabRestricted(tTab) then
			local hTab = scroll:AppendItemFromIni(INI_PATH, 'Handle_Tab')
			hTab.szKey = tTab.szKey
			hTab:Lookup('Text_Tab'):SetText(tTab.szName)
			if tTab.szIconTex == 'FromIconID' then
				hTab:Lookup('Image_TabIcon'):FromIconID(tTab.dwIconFrame)
			elseif tTab.dwIconFrame then
				hTab:Lookup('Image_TabIcon'):FromUITex(tTab.szIconTex, tTab.dwIconFrame)
			else
				hTab:Lookup('Image_TabIcon'):FromTextureFile(tTab.szIconTex)
			end
			hTab:Lookup('Image_Bg'):FromUITex(IMG_PATH, 0)
			hTab:Lookup('Image_Bg_Active'):FromUITex(IMG_PATH, 1)
			hTab:Lookup('Image_Bg_Hover'):FromUITex(IMG_PATH, 2)
		end
	end
	scroll:FormatAllItemPos()
	local tWelcomeTab
	for _, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szCategory == szCategory and tTab.bWelcome and not IsTabRestricted(tTab) then
			tWelcomeTab = tTab
			break
		end
	end
	if not tWelcomeTab then
		for _, tTab in ipairs(PANEL_TAB_LIST) do
			if not tTab.szCategory and tTab.bWelcome and not IsTabRestricted(tTab) then
				tWelcomeTab = tTab
				break
			end
		end
	end
	if tWelcomeTab then
		X.SwitchTab(tWelcomeTab.szKey, true)
	end
end

function D.OnSizeChange()
	local frame = this
	if not frame then
		return
	end
	-- fix size
	local nWidth, nHeight = frame:GetSize()
	local hTotal = frame:Lookup('', '')
	hTotal:Lookup('Text_Author'):SetRelY(nHeight - 25 - 30)
	hTotal:FormatAllItemPos()
	local wnd = frame:Lookup('Wnd_Total')
	wnd:Lookup('WndContainer_Category'):SetSize(nWidth - 22, 32)
	wnd:Lookup('WndContainer_Category'):FormatAllContentPos()
	wnd:Lookup('Btn_Weibo'):SetRelPos(nWidth - 135, 55)
	wnd:Lookup('WndScroll_Tabs'):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):FormatAllItemPos()
	wnd:Lookup('WndScroll_Tabs/ScrollBar_Tabs'):SetSize(16, nHeight - 111)

	local hWndTotal = wnd:Lookup('', '')
	wnd:Lookup('', ''):SetSize(nWidth, nHeight)
	hWndTotal:Lookup('Image_Breaker'):SetSize(6, nHeight - 340)
	hWndTotal:Lookup('Image_TabBg'):SetSize(nWidth - 2, 33)
	hWndTotal:Lookup('Handle_DBClick'):SetSize(nWidth, 54)

	local bHideTabs = nWidth < 550
	wnd:Lookup('WndScroll_Tabs'):SetVisible(not bHideTabs)
	hWndTotal:Lookup('Image_Breaker'):SetVisible(not bHideTabs)

	if bHideTabs then
		nWidth = nWidth + 181
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(5)
	else
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(186)
	end

	wnd:Lookup('WndScroll_MainPanel'):SetSize(nWidth - 191, nHeight - 100)
	frame.MAIN_SCROLL:SetSize(20, nHeight - 100)
	frame.MAIN_SCROLL:SetRelPos(nWidth - 209, 0)
	frame.MAIN_WND:SetSize(nWidth - 201, nHeight - 100)
	frame.MAIN_HANDLE:SetSize(nWidth - 201, nHeight - 100)
	local hWndMainPanel = frame.MAIN_WND
	if hWndMainPanel.OnPanelResize then
		local res, err, trace = X.XpCall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelResize'), trace)
		end
		hWndMainPanel:FormatAllContentPos()
	elseif hWndMainPanel.OnPanelActive then
		if hWndMainPanel.OnPanelDeactive then
			local res, err, trace = X.XpCall(hWndMainPanel.OnPanelDeactive, hWndMainPanel)
			if not res then
				X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelResize->OnPanelDeactive'), trace)
			end
		end
		hWndMainPanel:Clear()
		hWndMainPanel:Lookup('', ''):Clear()
		local res, err, trace = X.XpCall(hWndMainPanel.OnPanelActive, hWndMainPanel)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelResize->OnPanelActive'), trace)
		end
		hWndMainPanel:FormatAllContentPos()
	end
	hWndMainPanel:FormatAllContentPos()
	hWndMainPanel:Lookup('', ''):FormatAllItemPos()
	-- reset position
	local an = GetFrameAnchor(frame)
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function D.OnItemLButtonDBClick()
	local name = this:GetName()
	if name == 'Handle_DBClick' then
		this:GetRoot():Lookup('CheckBox_Maximize'):ToggleCheck()
	end
end

function D.OnMouseWheel()
	local el = this
	while el do
		if el:GetType() == 'WndContainer' then
			return
		end
		el = el:GetParent()
	end
	return true
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		X.ClosePanel()
	elseif name == 'Btn_Weibo' then
		X.OpenBrowser(X.PACKET_INFO.AUTHOR_FEEDBACK_URL)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Tab' then
		X.SwitchTab(this.szKey)
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Category' then
		local frame = this:GetRoot()
		local container = this:GetParent()
		local el = container:GetFirstChild()
		while el do
			if el ~= this then
				el:Check(false)
			end
			el = el:GetNext()
		end
		frame.szCurrentCategoryName = this.szCategory
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		D.RedrawTabs(frame, this.szCategory)
	elseif name == 'CheckBox_Maximize' then
		local frame = this:GetRoot()
		local ui = X.UI(frame)
		frame.tMaximizeAnchor = ui:Anchor()
		frame.nMaximizeW, frame.nMaximizeH = ui:Size()
		ui:Pos(0, 0)
			:Event('UI_SCALED', 'FRAME_MAXIMIZE_RESIZE', function()
				ui:Size(Station.GetClientSize())
			end)
			:Drag(false)
		D.ResizePanel(frame, Station.GetClientSize())
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		local frame = this:GetRoot()
		D.ResizePanel(frame, frame.nMaximizeW, frame.nMaximizeH)
		X.UI(this:GetRoot())
			:Event('UI_SCALED', 'FRAME_MAXIMIZE_RESIZE', false)
			:Drag(true)
			:Anchor(frame.tMaximizeAnchor)
	end
end

function D.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = X.UI(this:GetRoot()):Size()
	end
end

function D.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		HideTip()
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nW = math.max(this.fDragW + nDeltaX, 500)
		local nH = math.max(this.fDragH + nDeltaY, 300)
		D.ResizePanel(this:GetRoot(), nW, nH)
	end
end

function D.OnFrameCreate()
	this.MAIN_SCROLL = this:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel')
	this.MAIN_WND = this:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	this.MAIN_HANDLE = this:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel', '')
	local fScale = 1 + math.max(Font.GetOffset() * 0.03, 0)
	this:Lookup('', 'Text_Title'):SetText(_L('%s v%s Build %s', X.PACKET_INFO.NAME, X.PACKET_INFO.VERSION, X.PACKET_INFO.BUILD))
	this:Lookup('', 'Text_Author'):SetText('-- by ' .. X.PACKET_INFO.AUTHOR_SIGNATURE)
	this:Lookup('Wnd_Total/Btn_Weibo', 'Text_Default'):SetText(_L('Author @%s', X.PACKET_INFO.AUTHOR_FEEDBACK))
	this:Lookup('Wnd_Total/Btn_Weibo', 'Image_Icon'):FromUITex(X.PACKET_INFO.LOGO_IMAGE, X.PACKET_INFO.LOGO_MAIN_FRAME)
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
	X.UI(this):Size(D.OnSizeChange)
	D.RedrawCategory(this)
	D.ResizePanel(this, 960 * fScale, 630 * fScale)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:CorrectPos()
	this:RegisterEvent('UI_SCALED')
end

function D.OnFrameBreathe()
	if this.MAIN_WND and this.MAIN_WND.OnPanelBreathe then
		X.Call(this.MAIN_WND.OnPanelBreathe, this.MAIN_WND)
	end
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		X.ExecuteWithThis(this.MAIN_SCROLL, X.OnScrollBarPosChanged)
		D.OnSizeChange()
	end
end

function D.OnScrollBarPosChanged()
	local name = this:GetName()
	if name == 'ScrollBar_MainPanel' then
		local wnd = this:GetRoot().MAIN_WND
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

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
