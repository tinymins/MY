--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 网页界面
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
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

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	local options = OPTIONS[frame] or {}
	if name == 'Btn_Refresh' then
		UpdateControls(frame, 'refresh')
	elseif name == 'Btn_GoBack' then
		UpdateControls(frame, 'back')
	elseif name == 'Btn_GoForward' then
		UpdateControls(frame, 'forward')
	elseif name == 'Btn_GoTo' then
		UpdateControls(frame, 'go')
	elseif name == 'Btn_Close' then
		X.UI.CloseBrowser(frame)
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
	this:GetRoot().uiTitle:Text(this:GetLocationName())
end

function D.OnHistoryChanged()
	UpdateControls(this:GetRoot())
end

function D.GetFrame(szKey)
	return Station.SearchFrame(FRAME_NAME .. '#' .. szKey)
end

local function OnResizePanel()
	local frame = this
	local nWidth, nHeight = frame:GetSize()
	local nHeaderHeight = frame.uiTitleBg:Height()
	frame:Lookup('Wnd_Total/Wnd_Web'):SetRelPos(0, nHeaderHeight)
	frame:Lookup('Wnd_Total/Wnd_Web'):SetSize(nWidth, nHeight - nHeaderHeight)
	frame:Lookup('Wnd_Total/Wnd_Web/WndWeb'):SetRelPos(5, 0)
	frame:Lookup('Wnd_Total/Wnd_Web/WndWeb'):SetSize(nWidth - 8, nHeight - nHeaderHeight - 5)
	frame:Lookup('Wnd_Total/Wnd_Controls'):SetW(nWidth)
	frame:Lookup('Wnd_Total/Wnd_Controls', 'Image_Edit'):SetW(nWidth - 241)
	frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):SetW(nWidth - 251)
	frame:Lookup('Wnd_Total/Wnd_Controls/Btn_GoTo'):SetRelX(nWidth - 56)
	frame.uiTitle:Width(nWidth - 200)
	frame.uiTitleBg:Width(nWidth - 4)
	-- reset position
	local an = GetFrameAnchor(frame)
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
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
	local ui = X.UI.CreateFrame(FRAME_NAME, {
		text = '',
		resize = true,
		minimize = true,
		maximize = true,
		esc = true,
		frameRightControl = (function()
			local aControl = {}
			if options.controls == false then
				table.insert(aControl, function(hWnd)
					X.UI(hWnd):Append('WndButton', {
						y = X.UI.IS_GLASSMORPHISM and 5 or 3, w = 24, h = 24,
						buttonStyle = {
							szImage = 'ui\\Image\\Common\\DialogueLabel.UITex',
							nNormalGroup = 14,
							nMouseOverGroup = 15,
							nMouseDownGroup = 16,
							nDisableGroup = 17,
						},
						onClick = function()
							UpdateControls(this:GetRoot(), 'refresh')
						end,
					})
				end)
			end
			table.insert(aControl, function(hWnd)
				X.UI(hWnd):Append('WndButton', {
					y = 5, w = 22, h = 22,
					buttonStyle = {
						szImage = 'ui\\Image\\UICommon\\Camera3.UITex',
						nNormalGroup = 23,
						nMouseOverGroup = 24,
						nMouseDownGroup = 25,
						nDisableGroup = 32,
					},
					onClick = function()
						X.OpenBrowser(options.openurl or this:GetRoot():Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):GetText(), 'outer')
					end,
				})
			end)
			return aControl
		end)(),
		onFrameVisualStateChange = function()
			local ui = X.UI(this)
			local nW, nH = ui:ContainerSize()
			local eVisualState = ui:FrameVisualState()
			if eVisualState == X.UI.FRAME_VISUAL_STATE.MAXIMIZE then
			elseif eVisualState == X.UI.FRAME_VISUAL_STATE.MINIMIZE then
				this:SetH(X.UI.IS_GLASSMORPHISM and 33 or 46)
				this:Lookup('', ''):SetH(X.UI.IS_GLASSMORPHISM and 33 or 46)
			elseif eVisualState == X.UI.FRAME_VISUAL_STATE.NORMAL then
			end
		end,
	})
	local frame = ui:Raw()
	local uiStatic = X.UI(frame:Lookup('', ''))
	frame.uiTitleBg = uiStatic:Append('Image', {
		x = 2, y = 2, w = 767, h = 75,
		imageType = X.UI.IMAGE_TYPE.LEFT_CENTER_RIGHT, visible = not X.UI.IS_GLASSMORPHISM,
		image = 'ui\\Image\\UICommon\\ActivePopularize.UITex', imageFrame = 48,
	})
	uiStatic:Append('Image', {
		x = 18, y = X.UI.IS_GLASSMORPHISM and 7 or 15, w = 22, h = 22,
		image = 'ui\\Image\\Minimap\\Minimap.UITex', imageFrame = 184,
	})
	frame.uiTitle = uiStatic:Append('Text', {
		x = 45, y = X.UI.IS_GLASSMORPHISM and 2 or 11,
		w = 600, h = 30,
	})
	X.UI.AppendFromIni(frame:Lookup('Wnd_Total'), X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Browser.ini', 'Wnd_Total', true)

	frame:SetName(FRAME_NAME .. '#' .. szKey)
	WINDOWS[szKey] = frame
	OPTIONS[WINDOWS[szKey]] = options
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'UI.OpenBrowser #' .. szKey .. ': ' .. url, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]

	if options.layer then
		frame:ChangeRelation(options.layer)
	end
	if options.driver == 'ie' then
		ui:Fetch('Wnd_Web'):Append('WndWebPage', { name = 'WndWeb', w = 100, h = 100 })
	else --if options.driver == 'chrome' then
		ui:Fetch('Wnd_Web'):Append('WndWebCef', { name = 'WndWeb', w = 100, h = 100 })
	end
	if ui:Fetch('Wnd_Web/WndWeb'):Count() == 0 then
		ui:Fetch('Wnd_Web'):Append('WndWebPage', { name = 'WndWeb', w = 100, h = 100 })
	end
	if ui:Fetch('Wnd_Web/WndWeb'):Count() == 0 then
		X.OutputDebugMessage(X.NSFormatString('{$NS}.UI.Browser'), 'Create WndWebPage/WndWebCef failed!', X.DEBUG_LEVEL.ERROR)
		X.UI.CloseFrame(frame)
		return
	end
	if options.controls == false then
		frame:Lookup('Wnd_Total/Wnd_Controls'):Hide()
		frame.uiTitleBg:Height(48)
	end
	if options.readonly then
		frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):Enable(false)
	end
	frame.uiTitle:Text(options.title or '')
	frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):SetText(url)
	frame:Lookup('Wnd_Total/Wnd_Controls/Edit_Input'):SetCaretPos(0)

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

X.UI.LookupBrowser = D.GetFrame
X.UI.OpenBrowser = D.Open
X.UI.CloseBrowser = D.Close

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
