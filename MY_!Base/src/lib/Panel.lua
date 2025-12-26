--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 插件主界面相关函数
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/PS')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------
local IMG_PATH = X.PACKET_INFO.FRAMEWORK_ROOT ..'img/PS.UITex'
local FRAME_NAME = X.NSFormatString('{$NS}_PS')

local D = {}
---------------------------------------------------------------------------------------------
-- 界面开关
---------------------------------------------------------------------------------------------
function D.GetFrame()
	return Station.SearchFrame(FRAME_NAME)
end

function D.Open()
	if not X.AssertVersion('', '', '*') then
		return
	end
	if not X.IsInitialized() then
		return
	end
	local frame = D.GetFrame()
	if not frame then
		frame = X.UI.CreateFrame(FRAME_NAME, {
			maximize = true,
			resize = true,
			minWidth = 400,
			minHeight = 400,
			onRemove = function()
				D.Hide()
				return true
			end,
		}):Raw()
		frame:Hide()
		frame.bVisible = false
		D.InitPanel(frame)
		X.CheckTutorial()
	end
	return frame
end

function D.Close()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	D.SwitchTab('Welcome')
	D.Hide(false, true)
	X.UI.CloseFrame(frame)
end

function D.Reopen()
	if not D.IsOpened() then
		return
	end
	local bVisible = D.IsVisible()
	local szCurrentTabID = D.GetCurrentTabID()
	D.Close()
	D.Open()
	if szCurrentTabID then
		D.SwitchTab(szCurrentTabID)
	end
	D.Toggle(bVisible, true, true)
end

function D.Show(bMute, bNoAnimate)
	local frame = D.Open()
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
	X.RegisterEsc(X.PACKET_INFO.NAME_SPACE, D.IsVisible, function() D.Hide() end)
end

function D.Hide(bMute, bNoAnimate)
	local frame = D.GetFrame()
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
	X.RegisterEsc(X.PACKET_INFO.NAME_SPACE, false)
	X.UI.ClosePopupMenu()
end

function D.Toggle(bVisible, ...)
	if bVisible == nil then
		if D.IsVisible() then
			D.Hide()
		else
			D.Show()
			D.Focus()
		end
	elseif bVisible then
		D.Show(...)
		D.Focus()
	else
		D.Hide(...)
	end
end

function D.Focus(bForce)
	local frame = D.GetFrame()
	if not frame then
		return
	end
	if not bForce and not Cursor.IsVisible() then
		return
	end
	Station.SetFocusWindow(frame)
end

function D.IsVisible()
	local frame = D.GetFrame()
	return frame and frame:IsVisible()
end

function D.IsOpened()
	return not not D.GetFrame()
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

function D.GetCategoryList()
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

function D.SwitchCategory(szCategory)
	local frame = D.GetFrame()
	if not frame then
		return
	end

	local uiCheckCategory
	frame.uiCategories:Children('.WndTab'):Each(function(uiCategory)
		if uiCategory:Data('Category') == szCategory then
			uiCheckCategory = uiCategory
		end
	end)
	if not uiCheckCategory then
		uiCheckCategory = frame.uiCategories:Children('.WndTab'):First()
	end
	uiCheckCategory:Check(true)
end

function D.SwitchTab(szKey, bForceUpdate)
	local frame = D.GetFrame()
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
		D.SwitchCategory(tTab.szCategory)
	end
	-- 判断标签页是否已激活
	if frame.szCurrentTabKey == tTab.szKey and not bForceUpdate then
		return
	end
	if frame.szCurrentTabKey ~= tTab.szKey then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	-- 处理标签页背景选中状态
	frame.uiTabs:Find('#Wnd_Tab'):Each(function(uiWnd)
		uiWnd:Children('#Image_Tab_Bg_Active'):Visible(
			uiWnd:Data('Key') == szKey
		)
	end)
	-- 事件处理、界面绘制
	-- get main panel
	local wnd = frame.MAIN_WND
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
	frame.uiMain:Scroll(0)
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

function D.RedrawTab(szKey)
	if D.GetCurrentTabID() == szKey then
		D.SwitchTab(szKey, true)
	end
end

function D.GetCurrentTabID()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	return frame.szCurrentTabKey
end

-- 注册选项卡
-- (void) X.Panel.Register(szCategory, szKey, szName, szIconTex, options)
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
-- Ex： X.Panel.Register('测试', 'Test', '测试标签', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', { OnPanelActive = function(wnd) end })
function D.Register(szCategory, szKey, szName, szIconTex, options)
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

function D.InitPanel(frame)
	local ui = X.UI(frame)
	frame.uiCategories = ui:Append('WndTabs', {
		x = 0, y = 49,
		w = 960, h = 30,
	})
	frame.uiBtnAbout = ui:Append('WndButton', {
		x = 796, y = X.UI.IS_GLASSMORPHISM and 53 or 46,
		w = 140, h = X.UI.IS_GLASSMORPHISM and 25 or 40,
		buttonStyle = 'FLAT_RADIUS',
		text = _L('Author @%s', X.PACKET_INFO.AUTHOR_FEEDBACK),
		onClick = function()
			X.OpenBrowser(X.PACKET_INFO.AUTHOR_FEEDBACK_URL)
		end,
	})
	frame.uiBtnAboutIcon = ui:Append('Image', {
		x = 796, y = 5, w = 80, h = 80,
		image = X.PACKET_INFO.LOGO_IMAGE,
		imageFrame = X.PACKET_INFO.LOGO_MAIN_FRAME,
	})
	frame.uiTabs = ui:Append('WndScrollWindowBox', {
		name = 'WndScrollWindowBox_Tabs',
		x = 15, y = 91,
		w = 183, h = 520,
		padding = 0,
		image = 'NULL',
		containerType = X.UI.WND_CONTAINER_STYLE.LEFT_TOP,
	})
	if X.UI.IS_GLASSMORPHISM then
		frame.uiImageTabsSplitter = ui:Append('Image', {
			x = 195, y = 93, w = 3, h = 518,
			image = 'ui\\Image\\UItimate\\UICommon\\Common.UITex',
			imageFrame = 7,
		})
	else
		frame.uiImageTabsSplitter = ui:Append('Image', {
			x = 195, y = 93, w = 6, h = 518,
			image = 'ui\\Image\\UICommon\\CommonPanel.UITex',
			imageFrame = 43,
		})
	end
	frame.uiMain = ui:Append('WndScrollWindowBox', {
		name = 'WndScrollWindowBox_Main',
		x = 213, y = 91,
		w = 746, h = 520,
		padding = 0,
		image = 'NULL',
		containerType = X.UI.WND_CONTAINER_STYLE.LEFT_TOP,
	})
	frame.MAIN_WND = frame.uiMain:Raw():Lookup('WndContainer_Scroll')
	ui:Text(_L('%s v%s Build %s', X.PACKET_INFO.NAME, X.PACKET_INFO.VERSION, X.PACKET_INFO.BUILD))
	ui:Find('#Text_Author'):Text('-- by ' .. X.PACKET_INFO.AUTHOR_SIGNATURE)
	X.UI(frame):Size(D.OnSizeChange)
	D.RedrawCategory(frame)
	local fScale = 1 + math.max(Font.GetOffset() * 0.03, 0)
	D.ResizePanel(frame, 980 * fScale, 640 * fScale)
	frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	frame:CorrectPos()
	frame:RegisterEvent('UI_SCALED')
end

function D.ResizePanel(frame, nWidth, nHeight)
	X.UI(frame):Size(nWidth, nHeight)
end

function D.RedrawCategory(frame, szCategory)
	frame.uiCategories:Clear()
	frame.uiCategories:Append('WndWindow', { w = 20, h = 30 })
	for _, tCategory in ipairs(PANEL_CATEGORY_LIST) do
		local bExist = false
		for _, tTab in ipairs(PANEL_TAB_LIST) do
			if tTab.szCategory == tCategory.szName and not tTab.bHide and not IsTabRestricted(tTab) then
				bExist = true
				break
			end
		end
		if bExist then
			local uiTab = frame.uiCategories:Append('WndTab', {
				w = 100, h = 30,
				text = tCategory.szName,
				onCheck = function()
					frame.szCurrentCategoryName = tCategory.szName
					PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
					D.RedrawTabs(frame, tCategory.szName)
				end,
			})
			uiTab:Data('Category', tCategory.szName)
		end
	end
	D.SwitchCategory(szCategory)
end

function D.RedrawTabs(frame, szCategory)
	frame.uiTabs:Clear()
	for _, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szCategory == szCategory and not tTab.bHide and not IsTabRestricted(tTab) then
			local uiTab = frame.uiTabs:Append('WndWindow', {
				name = 'Wnd_Tab',
				w = 168, h = X.UI.IS_GLASSMORPHISM and 35 or 52,
				onHover = function(bIn)
					X.UI(this):Fetch('Image_Tab_Bg_Hover'):Visible(bIn)
				end,
				onClick = function()
					D.SwitchTab(tTab.szKey)
				end,
			})
			local uiIcon
			if X.UI.IS_GLASSMORPHISM then
				uiTab:Append('Image', {
					name = 'Image_Tab_Bg',
					x = 0, y = 0, w = 168, h = 34,
					image = 'ui\\Image\\UItimate\\UICommon\\Button9.UITex', imageFrame = 0,
				})
				uiTab:Append('Image', {
					name = 'Image_Tab_Bg_Active',
					x = 0, y = 0, w = 168, h = 34, visible = tTab.szKey == frame.szCurrentTabKey,
					image = 'ui\\Image\\UItimate\\UICommon\\Button9.UITex', imageFrame = 2,
				})
				uiTab:Append('Image', {
					name = 'Image_Tab_Bg_Hover',
					x = 0, y = 0, w = 168, h = 34, visible = false,
					image = 'ui\\Image\\UItimate\\UICommon\\Button9.UITex', imageFrame = 1,
				})
				uiTab:Append('Text', {
					name = 'Text_Tab',
					x = 36, y = 3, w = 128, h = 32,
					text = tTab.szName,
				})
				uiIcon = uiTab:Append('Image', { name = 'Image_TabIcon', x = 5, y = 5, w = 28, h = 28 })
			else
				uiTab:Append('Image', {
					name = 'Image_Tab_Bg',
					x = 0, y = 0, w = 168, h = 50,
					image = IMG_PATH, imageFrame = 0,
				})
				uiTab:Append('Image', {
					name = 'Image_Tab_Bg_Active',
					x = 0, y = 0, w = 168, h = 50, visible = tTab.szKey == frame.szCurrentTabKey,
					image = IMG_PATH, imageFrame = 1,
				})
				uiTab:Append('Image', {
					name = 'Image_Tab_Bg_Hover',
					x = 0, y = 0, w = 168, h = 50, visible = false,
					image = IMG_PATH, imageFrame = 2,
				})
				uiTab:Append('Text', {
					name = 'Text_Tab',
					x = 66, y = 16, w = 97, h = 20,
					text = tTab.szName,
				})
				uiIcon = uiTab:Append('Image', { x = 15, y = 7, w = 38, h = 38 })
			end
			if tTab.szIconTex == 'FromIconID' then
				uiIcon:Icon(tTab.dwIconFrame)
			elseif tTab.dwIconFrame then
				uiIcon:Image(tTab.szIconTex, tTab.dwIconFrame)
			else
				uiIcon:Image(tTab.szIconTex)
			end
			uiTab:Data('Key', tTab.szKey)
		end
	end

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
		D.SwitchTab(tWelcomeTab.szKey, true)
	end
end

function D.OnSizeChange()
	local frame = this
	if not frame then
		return
	end
	-- fix size
	local nWidth, nHeight = frame:GetSize()
	local bHideTabs = nWidth < 550
	local nMainWidth = bHideTabs and (nWidth - 10) or (nWidth - 225)
	local nMainHeight = nHeight - 100
	frame.uiCategories:Width(nWidth)
	frame.uiBtnAbout:Left(nWidth - 160)
	frame.uiBtnAboutIcon:Left(nWidth - 160)
	frame.uiTabs:Height(nMainHeight)
	frame.uiTabs:Visible(not bHideTabs)
	frame.uiImageTabsSplitter:Height(nHeight - 106)
	frame.uiImageTabsSplitter:Visible(not bHideTabs)
	frame.uiMain:Left(bHideTabs and 5 or 213)
	frame.uiMain:Size(nMainWidth, nMainHeight)

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

function D.OnPanelScroll()
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

function D.OnFrameBreathe()
	if this.MAIN_WND and this.MAIN_WND.OnPanelBreathe then
		X.Call(this.MAIN_WND.OnPanelBreathe, this.MAIN_WND)
	end
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		D.OnSizeChange()
		D.OnPanelScroll()
	end
end

function D.OnScrollBarPosChanged()
	if this:GetParent():GetName() == 'WndScrollWindowBox_Main' then
		D.OnPanelScroll()
	end
end

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = X.NSFormatString('{$NS}.Panel'),
	exports = {
		{
			fields = {
				'GetFrame',
				'Open',
				'Close',
				'Reopen',
				'Show',
				'Hide',
				'Toggle',
				'Focus',
				'IsVisible',
				'IsOpened',
				'GetCategoryList',
				'SwitchCategory',
				'SwitchTab',
				'RedrawTab',
				'GetCurrentTabID',
				'Register',
			},
			root = D,
		},
	},
}
X.Panel = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 官方调用导出
--------------------------------------------------------------------------------
X.TogglePanel = D.Toggle

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
