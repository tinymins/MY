--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÍøÒ³½çÃæ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
MY_Web = {}
MY_WebBase = class()

local function UpdateControls(frame, action, url)
	local wndWeb = frame:Lookup('Wnd_Web/WndWeb')
	if action == 'refresh' then
		wndWeb:Refresh()
	elseif action == 'back' then
		wndWeb:GoBack()
	elseif action == 'forward' then
		wndWeb:GoForward()
	elseif action == 'go' then
		if not url then
			url = frame:Lookup('Wnd_Controls/Edit_Input'):GetText()
		end
		wndWeb:Navigate(url)
	end
	frame:Lookup('Wnd_Controls/Btn_GoBack'):Enable(wndWeb:CanGoBack())
	frame:Lookup('Wnd_Controls/Btn_GoForward'):Enable(wndWeb:CanGoForward())
end

function MY_WebBase.OnFrameCreate()
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
end

function MY_WebBase.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Refresh' or name == 'Btn_Refresh2' then
		UpdateControls(frame, 'refresh')
	elseif name == 'Btn_GoBack' then
		UpdateControls(frame, 'back')
	elseif name == 'Btn_GoForward' then
		UpdateControls(frame, 'forward')
	elseif name == 'Btn_GoTo' then
		UpdateControls(frame, 'go')
	elseif name == 'Btn_OuterOpen' then
		LIB.OpenBrowser(frame:Lookup('Wnd_Controls/Edit_Input'):GetText())
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
		this.fDragW, this.fDragH = UI(this:GetRoot()):Size()
	end
end

function MY_WebBase.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nMinW, nMinH = UI(this:GetRoot()):MinSize()
		local nW = max(this.fDragW + nDeltaX, nMinW or 10)
		local nH = max(this.fDragH + nDeltaY, nMinH or 10)
		UI(this:GetRoot()):Size(nW, nH)
	end
end

function MY_WebBase.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		UpdateControls(frame, 'go')
		return 1
	end
end

function MY_WebBase.OnKillFocus()
	local name = this:GetName()
	if name == 'Edit_Input' then
		this:SetCaretPos(0)
	end
end

function MY_WebBase.OnWebLoadEnd()
	local edit = this:GetRoot():Lookup('Wnd_Controls/Edit_Input')
	edit:SetText(this:GetLocationURL())
	edit:SetCaretPos(0)
end

function MY_WebBase.OnTitleChanged()
	this:GetRoot():Lookup('', 'Text_Title'):SetText(this:GetLocationName())
end

function MY_WebBase.OnHistoryChanged()
	UpdateControls(this:GetRoot())
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

function MY_Web.GetFrame(szKey)
	return Station.SearchFrame('MY_Web#' .. szKey)
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
	WINDOWS[szKey] = Wnd.OpenWindow(PACKET_INFO.FRAMEWORK_ROOT .. 'ui/MY_Web.ini', 'MY_Web#' .. szKey)

	local frame = WINDOWS[szKey]
	if options.layer then
		frame:ChangeRelation(options.layer)
	end
	local ui = UI(frame)
	if options.driver == 'ie' then
		ui:Children('#Wnd_Web'):Append('WndWebPage', { name = 'WndWeb' })
	else --if options.driver == 'chrome' then
		ui:Children('#Wnd_Web'):Append('WndWebCef', { name = 'WndWeb' })
	end
	if options.controls == false then
		frame:Lookup('Wnd_Controls'):Hide()
		frame:Lookup('', 'Image_TitleBg'):SetH(48)
	end
	if options.title then
		frame:Lookup('', 'Text_Title'):SetText(options.title)
	end
	frame:Lookup('Wnd_Controls/Edit_Input'):SetText(url)
	ui:MinSize(290, 150)
	ui:Size(OnResizePanel)
	ui:Size(options.w or 500, options.h or 600)
	ui:Anchor(options.anchor or 'CENTER')
	UpdateControls(frame, 'go')

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
