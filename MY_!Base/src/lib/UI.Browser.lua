--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : Õ¯“≥ΩÁ√Ê
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.Browser')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local D = {}
local WINDOWS = setmetatable({}, { __mode = 'v' })
local OPTIONS = setmetatable({}, { __mode = 'k' })
local FRAME_NAME = X.NSFormatString('{$NS}_Browser')

local function UpdateControls(frame, action, url)
	local wndWeb = frame:Lookup('Wnd_Total/Wnd_Web/WndWeb')
	if action == 'refresh' then
		wndWeb:Refresh()
	elseif action == 'back' then
		wndWeb:GoBack()
	elseif action == 'forward' then
		wndWeb:GoForward()
	elseif action == 'go' then
		if not url then
			url = frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):GetText()
		end
		wndWeb:Navigate(url)
	end
	frame:Lookup('Wnd_Total/Wnd_Controls/Btn_GoBack'):Enable(wndWeb:CanGoBack())
	frame:Lookup('Wnd_Total/Wnd_Controls/Btn_GoForward'):Enable(wndWeb:CanGoForward())
end

local function UpdateFrameVisualState(frame, eVisualState)
	if eVisualState == X.UI.FRAME_VISUAL_STATE.MAXIMIZE then
		X.UI(frame):FrameVisualState(X.UI.FRAME_VISUAL_STATE.MAXIMIZE)
	elseif eVisualState == X.UI.FRAME_VISUAL_STATE.MINIMIZE then
		X.UI(frame):FrameVisualState(X.UI.FRAME_VISUAL_STATE.MINIMIZE)
		frame:Lookup('', ''):SetH(46)
		frame:Lookup('Btn_Drag'):Hide()
	elseif eVisualState == X.UI.FRAME_VISUAL_STATE.NORMAL then
		X.UI(frame):FrameVisualState(X.UI.FRAME_VISUAL_STATE.NORMAL)
		frame:Lookup('', ''):SetH(frame:GetH())
		frame:Lookup('Btn_Drag'):Show()
	end
end

function D.OnFrameCreate()
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	local options = OPTIONS[frame] or {}
	if name == 'Btn_Refresh' or name == 'Btn_Refresh2' then
		UpdateControls(frame, 'refresh')
	elseif name == 'Btn_GoBack' then
		UpdateControls(frame, 'back')
	elseif name == 'Btn_GoForward' then
		UpdateControls(frame, 'forward')
	elseif name == 'Btn_GoTo' then
		UpdateControls(frame, 'go')
	elseif name == 'Btn_OuterOpen' then
		X.OpenBrowser(options.openurl or frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):GetText(), 'outer')
	elseif name == 'Btn_Close' then
		X.UI.CloseBrowser(frame)
	end
end

function D.OnItemLButtonDBClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Handle_DBClick' or name == 'Handle_DBClick2' then
		if X.UI(frame):FrameVisualState() == X.UI.FRAME_VISUAL_STATE.MINIMIZE then
			UpdateFrameVisualState(frame, X.UI.FRAME_VISUAL_STATE.NORMAL)
		else
			frame:Lookup('WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize'):ToggleCheck()
		end
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'CheckBox_Maximize' then
		UpdateFrameVisualState(frame, X.UI.FRAME_VISUAL_STATE.MAXIMIZE)
	elseif name == 'CheckBox_Minimize' then
		UpdateFrameVisualState(frame, X.UI.FRAME_VISUAL_STATE.MINIMIZE)
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'CheckBox_Maximize' then
		UpdateFrameVisualState(frame, X.UI.FRAME_VISUAL_STATE.NORMAL)
	elseif name == 'CheckBox_Minimize' then
		UpdateFrameVisualState(frame, X.UI.FRAME_VISUAL_STATE.NORMAL)
	end
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		Cursor.Switch(CURSOR.LEFTTOP_RIGHTBOTTOM)
	end
end

function D.OnMouseLeave()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		Cursor.Switch(CURSOR.NORMAL)
	end
end

function D.OnDragButtonBegin()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = X.UI(frame):Size()
	end
end

function D.OnDragButton()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Drag' then
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nMinW, nMinH = X.UI(frame):MinSize()
		local nW = math.max(this.fDragW + nDeltaX, nMinW or 10)
		local nH = math.max(this.fDragH + nDeltaY, nMinH or 10)
		X.UI(frame):Size(nW, nH)
	end
end

function D.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		UpdateControls(frame, 'go')
		return 1
	end
end

function D.OnKillFocus()
	local name = this:GetName()
	if name == 'Edit_Input' then
		this:SetCaretPos(0)
	end
end

function D.OnWebLoadEnd()
	local edit = this:GetRoot():Lookup('Wnd_Total/Wnd_Controls/Edit_Input')
	edit:SetText(this:GetLocationURL())
	edit:SetCaretPos(0)
end

function D.OnTitleChanged()
	this:GetRoot():Lookup('', 'Text_Title'):SetText(this:GetLocationName())
end

function D.OnHistoryChanged()
	UpdateControls(this:GetRoot())
end

function D.GetFrame(szKey)
	return Station.SearchFrame(FRAME_NAME .. '#' .. szKey)
end

local function OnResizePanel()
	local h = this:Lookup('', '')
	local nWidth, nHeight = this:GetSize()
	local nHeaderHeight = h:Lookup('Image_TitleBg'):GetH()
	this:SetSize(nWidth, nHeight)
	this:Lookup('Wnd_Total'):SetSize(nWidth, nHeight)
	this:Lookup('Wnd_Total', ''):SetSize(nWidth, nHeight)
	this:Lookup('Wnd_Total', 'Handle_DBClick2'):SetW(nWidth)
	this:Lookup('Wnd_Total/Wnd_Web'):SetRelPos(0, nHeaderHeight)
	this:Lookup('Wnd_Total/Wnd_Web'):SetSize(nWidth, nHeight - nHeaderHeight)
	this:Lookup('Wnd_Total/Wnd_Web/WndWeb'):SetRelPos(5, 0)
	this:Lookup('Wnd_Total/Wnd_Web/WndWeb'):SetSize(nWidth - 8, nHeight - nHeaderHeight - 5)
	this:Lookup('Wnd_Total/Wnd_Controls'):SetW(nWidth)
	this:Lookup('Wnd_Total/Wnd_Controls', 'Image_Edit'):SetW(nWidth - 241)
	this:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):SetW(nWidth - 251)
	this:Lookup('Wnd_Total/Wnd_Controls/Btn_GoTo'):SetRelX(nWidth - 56)
	this:Lookup('WndContainer_TitleBtnR'):SetRelX(nWidth - 6 - this:Lookup('WndContainer_TitleBtnR'):GetW())
	this:Lookup('WndContainer_TitleBtnR'):FormatAllContentPos()
	this:Lookup('Btn_Drag'):SetRelPos(nWidth - 18, nHeight - 20)
	local nTitleWidth = nWidth - 45 - 10
	local pWnd = this:Lookup('WndContainer_TitleBtnR'):GetFirstChild()
	while pWnd do
		nTitleWidth = nTitleWidth - pWnd:GetW()
		pWnd = pWnd:GetNext()
	end
	h:Lookup('Text_Title'):SetW(nTitleWidth)
	h:Lookup('Image_TitleBg'):SetW(nWidth - 4)
	h:Lookup('Handle_DBClick'):SetW(nWidth)
	h:SetSize(nWidth, nHeight)
	this:SetDragArea(0, 0, nWidth, nHeaderHeight)
	-- reset position
	local an = GetFrameAnchor(this)
	this:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function D.Open(url, options)
	if not options then
		options = {}
	end
	local szKey = options.key
	if not szKey then
		szKey = GetTickCount()
		while WINDOWS[tostring(szKey)] do
			szKey = szKey + 0.1
		end
		szKey = tostring(szKey)
	end
	if WINDOWS[szKey] then
		X.UI.CloseFrame(WINDOWS[szKey])
	end
	WINDOWS[szKey] = X.UI.OpenFrame(X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Browser.ini', FRAME_NAME)
	OPTIONS[WINDOWS[szKey]] = options
	--[[#DEBUG BEGIN]]
	X.Debug(X.PACKET_INFO.NAME_SPACE, 'UI.OpenBrowser #' .. szKey .. ': ' .. url, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]

	local frame = WINDOWS[szKey]
	frame:SetName(FRAME_NAME .. '#' .. szKey)
	if options.layer then
		frame:ChangeRelation(options.layer)
	end
	local ui = X.UI(frame)
	if options.driver == 'ie' then
		ui:Fetch('Wnd_Web'):Append('WndWebPage', { name = 'WndWeb' })
	else --if options.driver == 'chrome' then
		ui:Fetch('Wnd_Web'):Append('WndWebCef', { name = 'WndWeb' })
	end
	if ui:Fetch('Wnd_Web/WndWeb'):Count() == 0 then
		ui:Fetch('Wnd_Web'):Append('WndWebPage', { name = 'WndWeb' })
	end
	if ui:Fetch('Wnd_Web/WndWeb'):Count() == 0 then
		X.Debug(X.NSFormatString('{$NS}.UI.Browser'), 'Create WndWebPage/WndWebCef failed!', X.DEBUG_LEVEL.ERROR)
		X.UI.CloseFrame(frame)
		return
	end
	if options.controls == false then
		frame:Lookup('Wnd_Total/Wnd_Controls'):Hide()
		frame:Lookup('', 'Image_TitleBg'):SetH(48)
	else
		frame:Lookup('WndContainer_TitleBtnR/Wnd_Refresh2'):Destroy()
	end
	if options.readonly then
		frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):Enable(false)
	end
	frame:Lookup('', 'Text_Title'):SetText(options.title or '')
	frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):SetText(url)
	frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):SetCaretPos(0)

	local nContainerWidth = 1
	local pWnd = frame:Lookup('WndContainer_TitleBtnR'):GetFirstChild()
	while pWnd do
		nContainerWidth = nContainerWidth + pWnd:GetW()
		pWnd = pWnd:GetNext()
	end
	frame:Lookup('WndContainer_TitleBtnR'):FormatAllContentPos()
	frame:Lookup('WndContainer_TitleBtnR'):SetW(nContainerWidth)

	ui:MinSize(290, 150)
	ui:Size(OnResizePanel)
	ui:Size(options.w or 500, options.h or 600)
	ui:Anchor(options.anchor or 'CENTER')
	UpdateControls(frame, 'go')

	return szKey
end

function D.Close(szKey)
	if X.IsString(szKey) then
		if not WINDOWS[szKey] then
			return
		end
		X.UI.CloseFrame(WINDOWS[szKey])
		WINDOWS[szKey] = nil
	else
		for k, v in pairs(WINDOWS) do
			if v == szKey then
				WINDOWS[k] = nil
			end
		end
		X.UI.CloseFrame(szKey)
	end
end

-- Global exports
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

X.UI.LookupBrowser = D.GetFrame
X.UI.OpenBrowser = D.Open
X.UI.CloseBrowser = D.Close

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
