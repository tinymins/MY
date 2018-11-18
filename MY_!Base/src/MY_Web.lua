--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÍøÒ³½çÃæ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
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
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
MY_Web = {}
MY_WebBase = class()

local function UpdateControls(frame)
	frame:Lookup('Wnd_Controls/Btn_GoBack'):Enable(#frame.backwards > 0)
	frame:Lookup('Wnd_Controls/Btn_GoForward'):Enable(#frame.forwards > 0)
end

local function FormatURL(url)
	if not url:find('://') then
		url = 'http://' .. url
	end
	return url
end

local function GoToURL(frame, url)
	frame.url = url
	frame:Lookup('Wnd_Web/WndWeb'):Navigate(url)
	frame:Lookup('Wnd_Controls/Edit_Input'):SetText(url)
end

local function GoToInputURL(frame)
	local url = FormatURL(frame:Lookup('Wnd_Controls/Edit_Input'):GetText())
	if frame.url == url then
		return
	end
	insert(frame.backwards, frame.url)
	frame.forwards = {}
	GoToURL(frame, url)
	UpdateControls(frame)
end

function MY_WebBase.OnFrameCreate()
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
end

function MY_WebBase.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Refresh' or name == 'Btn_Refresh2' then
		frame:Lookup('Wnd_Web/WndWeb'):Navigate(frame.url)
	elseif name == 'Btn_GoBack' then
		local url = remove(frame.backwards)
		if not url then
			return
		end
		insert(frame.forwards, frame.url)
		GoToURL(frame, url)
		UpdateControls(frame)
	elseif name == 'Btn_GoForward' then
		local url = remove(frame.forwards)
		if not url then
			return
		end
		insert(frame.backwards, frame.url)
		GoToURL(frame, url)
		UpdateControls(frame)
	elseif name == 'Btn_GoTo' then
		GoToInputURL(frame)
	elseif name == 'Btn_OuterOpen' then
		MY.OpenBrowser(frame.url)
	elseif name == 'Btn_Close' then
		MY_Web.Close(frame)
	end
end

function MY_WebBase.OnMouseEnter()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		Cursor.Switch(CURSOR.LEFTTOP_RIGHTBOTTOM)
	end
end

function MY_WebBase.OnMouseLeave()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		Cursor.Switch(CURSOR.NORMAL)
	end
end

function MY_WebBase.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = UI(this:GetRoot()):size()
	end
end

function MY_WebBase.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nMinW, nMinH = UI(this:GetRoot()):minSize()
		local nW = max(this.fDragW + nDeltaX, nMinW or 10)
		local nH = max(this.fDragH + nDeltaY, nMinH or 10)
		UI(this:GetRoot()):size(nW, nH)
	end
end

function MY_WebBase.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		GoToInputURL(frame)
		return 1
	end
end

do
local WINDOWS = setmetatable({}, { __mode = 'v' })
local function OnResizePanel()
	local h = this:Lookup('', '')
	local nWidth, nHeight = this:GetSize()
	local nHeaderHeight = h:Lookup('Image_TitleBg'):GetH()
	h:Lookup('Text_Title'):SetW(nWidth - 171)
	h:Lookup('Image_TitleBg'):SetW(nWidth - 4)
	h:SetSize(nWidth, nHeight)
	this:SetSize(nWidth, nHeight)
	this:Lookup('Btn_Close'):SetRelX(nWidth - 35)
	this:Lookup('CheckBox_Maximize'):SetRelX(nWidth - 60)
	this:Lookup('Btn_OuterOpen'):SetRelX(nWidth - 91)
	this:Lookup('Btn_Refresh2'):SetRelX(nWidth - 121)
	this:Lookup('Btn_Drag'):SetRelPos(nWidth - 18, nHeight - 20)
	this:Lookup('CheckBox_Maximize'):SetRelX(nWidth - 63)
	this:Lookup('Wnd_Web'):SetRelPos(0, nHeaderHeight)
	this:Lookup('Wnd_Web'):SetSize(nWidth, nHeight - nHeaderHeight)
	this:Lookup('Wnd_Web/WndWeb'):SetRelPos(5, 0)
	this:Lookup('Wnd_Web/WndWeb'):SetSize(nWidth - 8, nHeight - nHeaderHeight - 5)
	this:Lookup('Wnd_Controls'):SetW(nWidth)
	this:Lookup('Wnd_Controls', 'Image_Edit'):SetW(nWidth - 241)
	this:Lookup('Wnd_Controls/Edit_Input'):SetW(nWidth - 251)
	this:Lookup('Wnd_Controls/Btn_GoTo'):SetRelX(nWidth - 56)
	this:SetDragArea(0, 0, nWidth, nHeaderHeight)
	-- reset position
	local an = GetFrameAnchor(this)
	this:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function MY_Web.Open(url, options)
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
		Wnd.CloseWindow(WINDOWS[szKey])
	end
	WINDOWS[szKey] = Wnd.OpenWindow(MY.GetAddonInfo().szFrameworkRoot .. 'ui/MY_Web.ini', 'MY_Web#' .. szKey)

	local frame = WINDOWS[szKey]
	local ui = UI(frame)
	if options.driver == 'ie' then
		ui:children('#Wnd_Web'):append('WndWebPage', { name = 'WndWeb' })
	else --if options.driver == 'chrome' then
		ui:children('#Wnd_Web'):append('WndWebCef', { name = 'WndWeb' })
	end
	if options.controls == false then
		frame:Lookup('Wnd_Controls'):Hide()
		frame:Lookup('', 'Image_TitleBg'):SetH(48)
	end
	if options.title then
		frame:Lookup('', 'Text_Title'):SetText(options.title)
	end
	ui:minSize(290, 150)
	ui:size(OnResizePanel)
	ui:size(options.w or 500, options.h or 600)
	ui:anchor(options.anchor or {})
	url = FormatURL(url)
	frame.forwards = {}
	frame.backwards = {}
	GoToURL(frame, url)
	UpdateControls(frame)

	return szKey
end

function MY_Web.Close(szKey)
	if IsString(szKey) then
		if not WINDOWS[szKey] then
			return
		end
		Wnd.CloseWindow(WINDOWS[szKey])
		WINDOWS[szKey] = nil
	else
		for k, v in pairs(WINDOWS) do
			if v == szKey then
				WINDOWS[k] = nil
			end
		end
		Wnd.CloseWindow(szKey)
	end
end
end
