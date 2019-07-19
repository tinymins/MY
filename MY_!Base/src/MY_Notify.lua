--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 全局系统消息通知模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local EMPTY_TABLE, MENU_DIVIDER, XML_LINE_BREAKER = LIB.EMPTY_TABLE, LIB.MENU_DIVIDER, LIB.XML_LINE_BREAKER
-----------------------------------------------------------------------------------------------------------

MY_Notify = {}
MY_Notify.anchor = { x = -100, y = -150, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' }
RegisterCustomData('MY_Notify.anchor')

local _L = LIB.LoadLangPack()
local D = {}
local NOTIFY_LIST = {}
local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT .. 'ui/MY_Notify.ini'
local ENTRY_INI_PATH = PACKET_INFO.FRAMEWORK_ROOT .. 'ui/MY_NotifyIcon.ini'

function MY_Notify.Create(opt)
	insert(NOTIFY_LIST, {
		bUnread = true,
		szKey = opt.szKey,
		szMsg = opt.szMsg,
		fnAction = opt.fnAction,
		fnCancel = opt.fnCancel,
	})
	D.UpdateEntry()
	D.DrawNotifies()
	if opt.bPopupPreview then
		D.ShowTip(opt.szMsg)
	end
	if opt.bPlaySound then
		LIB.PlaySound(opt.szSound or 'Notify.ogg', opt.szCustomSound)
	end
	return szKey
end
LIB.CreateNotify = MY_Notify.Create

function MY_Notify.Dismiss(szKey, bOnlyData)
	for i, v in ipairs_r(NOTIFY_LIST) do
		if v.szKey == szKey then
			remove(NOTIFY_LIST, i)
			FireUIEvent('MY_NOTIFY_DISMISS', szKey)
		end
	end
	if bOnlyData then
		return
	end
	D.UpdateEntry()
	D.DrawNotifies(true)
end
LIB.DismissNotify = MY_Notify.Dismiss

function MY_Notify.OpenPanel()
	Wnd.OpenWindow(INI_PATH, 'MY_Notify')
end

function D.UpdateEntry()
	local container = Station.Lookup('Normal/TopMenu/WndContainer_ListOther')
	if not container then
		return
	end
	local nUnread = 0
	for i, v in ipairs(NOTIFY_LIST) do
		if v.bUnread then
			nUnread = nUnread + 1
		end
	end
	local wItem = container:Lookup('Wnd_News_XJ')
	if #NOTIFY_LIST == 0 then
		-- if wItem then
		-- 	-- container:SetW(container:GetW() - wItem:GetW())
		-- 	wItem:Destroy()
		-- 	container:FormatAllContentPos()
		-- end
		wItem:Hide()
		container:FormatAllContentPos()
	else
		-- if not wItem then
		-- 	wItem = container:AppendContentFromIni(ENTRY_INI_PATH, 'Wnd_MY_NotifyIcon')
		-- 	-- container:SetW(container:GetW() + wItem:GetW())
		-- 	local h = wItem:Lookup('Wnd_MY_NotifyIcon_Inner', '')
		-- 	h:Lookup('Image_MY_NotifyIcon'):SetAlpha(230)
		-- 	h.OnItemMouseEnter = function() this:Lookup('Image_MY_NotifyIcon'):SetAlpha(255) end
		-- 	h.OnItemMouseLeave = function() this:Lookup('Image_MY_NotifyIcon'):SetAlpha(230) end
		-- 	h.OnItemLButtonDown = function() this:Lookup('Image_MY_NotifyIcon'):SetAlpha(230) end
		-- 	h.OnItemLButtonUp = function() this:Lookup('Image_MY_NotifyIcon'):SetAlpha(255) end
		-- 	h.OnItemLButtonClick = function() MY_Notify.OpenPanel() end
		-- 	container:FormatAllContentPos()
		-- end
		-- wItem:Lookup('Wnd_MY_NotifyIcon_Inner', 'Handle_MY_NotifyIcon_Num'):SetVisible(nUnread > 0)
		-- wItem:Lookup('Wnd_MY_NotifyIcon_Inner', 'Handle_MY_NotifyIcon_Num/Text_MY_NotifyIcon_Num'):SetText(nUnread)
		wItem:Show()
		wItem:Lookup('Btn_News_XJ', 'Image_Red_Pot'):SetVisible(nUnread > 0)
		wItem:Lookup('Btn_News_XJ').OnLButtonClick = function() MY_Notify.OpenPanel() end
		container:FormatAllContentPos()
	end
end
LIB.RegisterInit('MY_Notify', D.UpdateEntry)

function D.RemoveEntry()
	local container = Station.Lookup('Normal/TopMenu/WndContainer_List')
	if not container then
		return
	end
	local wItem = container:Lookup('Wnd_MY_NotifyIcon')
	if wItem then
		wItem:Destroy()
		container:FormatAllContentPos()
	end
end
LIB.RegisterReload('MY_Notify', D.RemoveEntry)

function D.DrawNotifies(bAutoClose)
	if bAutoClose and #NOTIFY_LIST == 0 then
		return Wnd.CloseWindow('MY_Notify')
	end
	local hList = Station.Lookup('Normal/MY_Notify/Window_Main/WndScroll_Notify', 'Handle_Notifies')
	if not hList then
		return
	end
	hList:Clear()
	for i, notify in ipairs(NOTIFY_LIST) do
		local hItem = hList:AppendItemFromIni(INI_PATH, 'Handle_Notify')
		local hMsg = hItem:Lookup('Handle_Notify_Msg')
		local nDeltaH = hMsg:GetH()
		hMsg:AppendItemFromString(notify.szMsg)
		hMsg:FormatAllItemPos()
		nDeltaH = max(select(2, hMsg:GetAllItemSize()), 25) - nDeltaH
		hMsg:SetH(hMsg:GetH() + nDeltaH)
		hItem:SetH(hItem:GetH() + nDeltaH)
		for _, v in ipairs({
			{ name = 'Shadow_NotifyHover', scaleH = 1 },
			{ name = 'Shadow_NotifySelect', scaleH = 1 },
			{ name = 'Image_Notify_Spliter', scaleY = 1 },
			{ name = 'Image_Notify_Unread', scaleY = 0.5 },
			{ name = 'Handle_Notify_View', scaleY = 0.5 },
			{ name = 'Handle_Notify_Dismiss', scaleY = 0.5 },
		}) do
			local p = hItem:Lookup(v.name)
			if p then
				if v.scaleH then
					p:SetH(p:GetH() + nDeltaH * v.scaleH)
				end
				if v.scaleY then
					p:SetRelY(p:GetRelY() + nDeltaH * v.scaleY)
				end
			end
		end
		hItem:Lookup('Handle_Notify_View'):SetVisible(not not notify.fnAction)
		hItem:Lookup('Image_Notify_Unread'):SetVisible(notify.bUnread)
		hItem:FormatAllItemPos()
		hItem.notify = notify
	end
	hList:FormatAllItemPos()
end

function MY_Notify.OnFrameCreate()
	D.DrawNotifies()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
end

function MY_Notify.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Notify'
	or name == 'Handle_Notify_View'
	or name == 'Handle_Notify_Dismiss' then
		local bDismiss, notify
		if name == 'Handle_Notify' then
			notify = this.notify
			bDismiss = not notify.fnAction or notify.fnAction(notify.szKey)
		elseif name == 'Handle_Notify_View' then
			notify = this:GetParent().notify
			bDismiss = not notify.fnAction or notify.fnAction(notify.szKey)
		elseif name == 'Handle_Notify_Dismiss' then
			notify = this:GetParent().notify
			if notify.fnCancel then
				notify.fnCancel(notify.szKey)
			end
			bDismiss = true
		end
		if bDismiss then
			MY_Notify.Dismiss(notify.szKey, true)
		end
		notify.bUnread = false
		D.UpdateEntry()
		D.DrawNotifies(true)
	end
end

function MY_Notify.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	end
end

do
local l_uiFrame, l_uiTipBoard
function D.ShowTip(szMsg)
	l_uiTipBoard:clear():append(szMsg)
	l_uiFrame:fadeTo(500, 255)
	local szHoverFrame = Station.GetMouseOverWindow() and Station.GetMouseOverWindow():GetRoot():GetName()
	if szHoverFrame == 'MY_NotifyTip' then
		LIB.DelayCall('MY_NotifyTip_Hide', 5000)
	else
		LIB.DelayCall('MY_NotifyTip_Hide', 5000, function()
			l_uiFrame:fadeOut(500)
		end)
	end
end

local function OnInit()
	if l_uiFrame then
		return
	end
	-- init tip frame
	l_uiFrame = UI.CreateFrame('MY_NotifyTip', {
		level = 'Topmost', empty = true,
		w = 250, h = 150, visible = false,
		events = {{ 'UI_SCALED', function() l_uiFrame:anchor(MY_Notify.anchor) end }},
	})
	:customMode(_L['MY_Notify'], function()
		LIB.DelayCall('MY_NotifyTip_Hide')
		l_uiFrame:show():alpha(255)
	end, function()
		MY_Notify.anchor = l_uiFrame:anchor()
		l_uiFrame:alpha(0):hide()
	end)
	:anchor(MY_Notify.anchor)
	-- init tip panel handle and bind animation function
	l_uiTipBoard = l_uiFrame:append('WndScrollBox', {
		handlestyle = 3, x = 0, y = 0, w = 250, h = 150,
		onclick = function()
			if LIB.IsInCustomUIMode() then
				return
			end
			MY_Notify.OpenPanel()
			l_uiFrame:fadeOut(500)
		end,
		onhover = function(bIn)
			if LIB.IsInCustomUIMode() then
				return
			end
			if bIn then
				LIB.DelayCall('MY_NotifyTip_Hide')
				l_uiFrame:fadeIn(500)
			else
				LIB.DelayCall('MY_NotifyTip_Hide', function()
					l_uiFrame:fadeOut(500)
				end, 5000)
			end
		end,
	}, true)
end
LIB.RegisterInit('MY_NotifyTip', OnInit)
end
