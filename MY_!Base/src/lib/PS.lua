--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 插件主界面相关函数
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT ..'ui/PS.ini'
local IMG_PATH = PACKET_INFO.FRAMEWORK_ROOT ..'img/PS.UITex'
local FRAME_NAME = NSFormatString('{$NS}_PS')

local D = {}
---------------------------------------------------------------------------------------------
-- 界面开关
---------------------------------------------------------------------------------------------
function LIB.GetFrame()
	return Station.SearchFrame(FRAME_NAME)
end

function LIB.OpenPanel()
	if not LIB.AssertVersion('', '', '*') then
		return
	end
	if not LIB.IsInitialized() then
		return
	end
	local frame = LIB.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, FRAME_NAME)
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
	LIB.SwitchTab('Welcome')
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
	LIB.RegisterEsc(PACKET_INFO.NAME_SPACE, LIB.IsPanelVisible, function() LIB.HidePanel() end)
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
	LIB.RegisterEsc(PACKET_INFO.NAME_SPACE)
	UI.ClosePopupMenu()
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

function LIB.IsPanelVisible()
	local frame = LIB.GetFrame()
	return frame and frame:IsVisible()
end

function LIB.IsPanelOpened()
	return not not LIB.GetFrame()
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
	{ szName = _L['JX3BOX' ] },
	{ szName = _L['Search' ] },
	{ szName = _L['Others' ] },
}
local PANEL_TAB_LIST = {}

local function IsShieldedTab(tTab)
	if tTab.bShielded and LIB.IsShieldedVersion() then
		return true
	end
	if tTab.szShieldedKey then
		if LIB.IsShieldedVersion(tTab.szShieldedKey, tTab.nShielded) then
			return true
		end
	else
		if tTab.nShielded and LIB.IsShieldedVersion(tTab.nShielded) then
			return true
		end
	end
	if tTab.IsShielded then
		return tTab.IsShielded()
	end
	return false
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
		chk:Check(true)
	end
end

function LIB.SwitchTab(szKey, bForceUpdate)
	local frame = LIB.GetFrame()
	if not frame then
		return
	end
	local tTab = lodash.find(PANEL_TAB_LIST, function(tTab) return tTab.szKey == szKey end)
	if not tTab then
		--[[#DEBUG BEGIN]]
		if not tTab then
			LIB.Debug(NSFormatString('{$NS}.SwitchTab'), _L('Cannot find tab: %s', szKey), DEBUG_LEVEL.WARNING)
		end
		--[[#DEBUG END]]
		return
	end
	-- 判断主分类是否正确
	if tTab.szCategory and frame.szCurrentCategoryName ~= tTab.szCategory then
		LIB.SwitchCategory(tTab.szCategory)
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
		local res, err, trace = XpCall(wnd.OnPanelDeactive, wnd)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. NSFormatString('\n{$NS}#OnPanelDeactive\n') .. trace .. '\n')
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
	wnd:SetContainerType(CONSTANT.WND_CONTAINER_STYLE.CUSTOM)
	-- ready to draw
	if tTab.OnPanelActive then
		local res, err, trace = XpCall(tTab.OnPanelActive, wnd)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. NSFormatString('\n{$NS}#OnPanelActive\n') .. trace .. '\n')
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

function LIB.RedrawTab(szKey)
	if LIB.GetCurrentTabID() == szKey then
		LIB.SwitchTab(szKey, true)
	end
end

function LIB.GetCurrentTabID()
	local frame = LIB.GetFrame()
	if not frame then
		return
	end
	return frame.szCurrentTabKey
end

-- 注册选项卡
-- (void) LIB.RegisterPanel(szCategory, szKey, szName, szIconTex, options)
-- szCategory      选项卡所在分类
-- szKey           选项卡唯一 KEY
-- szName          选项卡按钮标题
-- szIconTex       选项卡图标文件|图标帧
-- options         选项卡各种响应函数 {
--   options.bShielded               屏蔽的选项卡
--   options.nShielded               屏蔽等级的选项卡
--   options.bWelcome                欢迎页（默认页）选项卡
--   options.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
--   options.OnPanelDeactive(wnd)    选项卡取消激活
-- }
-- Ex： LIB.RegisterPanel('测试', 'Test', '测试标签', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', { OnPanelActive = function(wnd) end })
function LIB.RegisterPanel(szCategory, szKey, szName, szIconTex, options)
	-- 分类不存在则创建
	if not options.bHide and not lodash.find(PANEL_CATEGORY_LIST, function(tCategory) return tCategory.szName == szCategory end) then
		insert(PANEL_CATEGORY_LIST, {
			szName = szCategory,
		})
	end
	-- 移除已存在的
	for i, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szKey == szKey then
			remove(tTab, i)
			break
		end
	end
	-- 判断非注销面板调用
	if szName ~= false then
		-- 格式化图标信息
		if IsNumber(szIconTex) then
			szIconTex = 'FromIconID|' .. szIconTex
		elseif not IsString(szIconTex) then
			szIconTex = 'UI/Image/Common/Logo.UITex|6'
		end
		local dwIconFrame = gsub(szIconTex, '.*%|(%d+)', '%1')
		if dwIconFrame then
			dwIconFrame = tonumber(dwIconFrame)
			szIconTex = gsub(szIconTex, '%|.*', '')
		end
		local nPriority = options.nPriority or (GetStringCRC(szKey) + 100000)
		-- 创建数据结构、插入数组
		insert(PANEL_TAB_LIST, {
			szKey           = szKey                  ,
			szName          = szName                 ,
			szCategory      = szCategory             ,
			szIconTex       = szIconTex              ,
			dwIconFrame     = dwIconFrame            ,
			nPriority       = nPriority              ,
			bWelcome        = options.bWelcome       ,
			bHide           = options.bHide          ,
			bShielded       = options.bShielded      ,
			nShielded       = options.nShielded      ,
			IsShielded      = options.IsShielded     ,
			OnPanelActive   = options.OnPanelActive  ,
			OnPanelScroll   = options.OnPanelScroll  ,
			OnPanelResize   = options.OnPanelResize  ,
			OnPanelBreathe  = options.OnPanelBreathe ,
			OnPanelDeactive = options.OnPanelDeactive,
		})
		-- 重新根据权重排序数组
		sort(PANEL_TAB_LIST, function(t1, t2)
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
	FireUIEvent(NSFormatString('{$NS}_PANEL_UPDATE'))
end

---------------------------------------------------------------------------------------------
-- 窗口函数
---------------------------------------------------------------------------------------------
function D.ResizePanel(frame, nWidth, nHeight)
	UI(frame):Size(nWidth, nHeight)
end

function D.RedrawCategory(frame, szCategory)
	local container = frame:Lookup('Wnd_Total/WndContainer_Category')
	container:Clear()
	for _, tCategory in ipairs(PANEL_CATEGORY_LIST) do
		if lodash.some(PANEL_TAB_LIST, function(tTab) return tTab.szCategory == tCategory.szName and not tTab.bHide and not IsShieldedTab(tTab) end) then
			local chkCategory = container:AppendContentFromIni(INI_PATH, 'CheckBox_Category')
			if not szCategory then
				szCategory = tCategory.szName
			end
			chkCategory.szCategory = tCategory.szName
			chkCategory:Lookup('', 'Text_Category'):SetText(tCategory.szName)
		end
	end
	container:FormatAllContentPos()
	LIB.SwitchCategory(szCategory)
end

function D.RedrawTabs(frame, szCategory)
	local scroll = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	scroll:Clear()
	for _, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szCategory == szCategory and not tTab.bHide and not IsShieldedTab(tTab) then
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
	local tWelcomeTab = lodash.find(PANEL_TAB_LIST, function(tTab) return tTab.szCategory == szCategory and tTab.bWelcome and not IsShieldedTab(tTab) end)
		or lodash.find(PANEL_TAB_LIST, function(tTab) return not tTab.szCategory and tTab.bWelcome and not IsShieldedTab(tTab) end)
	if tWelcomeTab then
		LIB.SwitchTab(tWelcomeTab.szKey)
	end
end

function D.OnSizeChanged()
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
		local res, err, trace = XpCall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. NSFormatString('\n{$NS}#OnPanelResize\n') .. trace .. '\n')
		end
		hWndMainPanel:FormatAllContentPos()
	elseif hWndMainPanel.OnPanelActive then
		if hWndMainPanel.OnPanelDeactive then
			local res, err, trace = XpCall(hWndMainPanel.OnPanelDeactive, hWndMainPanel)
			if not res then
				FireUIEvent('CALL_LUA_ERROR', err .. NSFormatString('\n{$NS}#OnPanelResize->OnPanelDeactive\n') .. trace .. '\n')
			end
		end
		hWndMainPanel:Clear()
		hWndMainPanel:Lookup('', ''):Clear()
		local res, err, trace = XpCall(hWndMainPanel.OnPanelActive, hWndMainPanel)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. NSFormatString('\n{$NS}#OnPanelResize->OnPanelActive\n') .. trace .. '\n')
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
		LIB.ClosePanel()
	elseif name == 'Btn_Weibo' then
		LIB.OpenBrowser(PACKET_INFO.AUTHOR_WEIBO_URL)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Tab' then
		LIB.SwitchTab(this.szKey)
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
		local ui = UI(frame)
		frame.tMaximizeAnchor = ui:Anchor()
		frame.nMaximizeW, frame.nMaximizeH = ui:Size()
		ui:Pos(0, 0):Event('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
			ui:Size(Station.GetClientSize())
		end):Drag(false)
		D.ResizePanel(frame, Station.GetClientSize())
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		local frame = this:GetRoot()
		D.ResizePanel(frame, frame.nMaximizeW, frame.nMaximizeH)
		UI(this:GetRoot())
			:Event('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
			:Drag(true)
			:Anchor(frame.tMaximizeAnchor)
	end
end

function D.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = UI(this:GetRoot()):Size()
	end
end

function D.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		HideTip()
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nW = max(this.fDragW + nDeltaX, 500)
		local nH = max(this.fDragH + nDeltaY, 300)
		D.ResizePanel(this:GetRoot(), nW, nH)
	end
end

function D.OnFrameCreate()
	this.MAIN_SCROLL = this:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel')
	this.MAIN_WND = this:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	this.MAIN_HANDLE = this:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel', '')
	local fScale = 1 + max(Font.GetOffset() * 0.03, 0)
	this:Lookup('', 'Text_Title'):SetText(_L('%s V%s Build %s %s', PACKET_INFO.NAME, PACKET_INFO.NATURAL_VERSION, PACKET_INFO.VERSION, PACKET_INFO.BUILD))
	this:Lookup('', 'Text_Author'):SetText('-- by ' .. PACKET_INFO.AUTHOR_SIGNATURE)
	this:Lookup('Wnd_Total/Btn_Weibo', 'Text_Default'):SetText(_L('Author @%s', PACKET_INFO.AUTHOR_WEIBO))
	this:Lookup('Wnd_Total/Btn_Weibo', 'Image_Icon'):FromUITex(PACKET_INFO.LOGO_UITEX, PACKET_INFO.LOGO_MAIN_FRAME)
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
	UI(this):Size(D.OnSizeChanged)
	D.RedrawCategory(this)
	D.ResizePanel(this, 960 * fScale, 630 * fScale)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:CorrectPos()
	this:RegisterEvent('UI_SCALED')
end

function LIB.OnFrameBreathe()
	if this.MAIN_WND and this.MAIN_WND.OnPanelBreathe then
		Call(this.MAIN_WND.OnPanelBreathe, this.MAIN_WND)
	end
end

function LIB.OnEvent(event)
	if event == 'UI_SCALED' then
		LIB.ExecuteWithThis(this.MAIN_SCROLL, LIB.OnScrollBarPosChanged)
		D.OnSizeChanged()
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

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
_G[FRAME_NAME] = LIB.GeneGlobalNS(settings)
end
