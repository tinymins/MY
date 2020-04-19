--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 全局系统消息通知模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
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
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------

MY_Notify = {}
MY_Notify.anchor = { x = -100, y = -150, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' }
MY_Notify.bDesc = false
MY_Notify.bDisableDismiss = false
RegisterCustomData('MY_Notify.anchor')
RegisterCustomData('MY_Notify.bDesc')
RegisterCustomData('MY_Notify.bDisableDismiss')

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
	return opt.szKey
end
LIB.CreateNotify = MY_Notify.Create

function D.Dismiss(szKey, bOnlyData)
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

function MY_Notify.Dismiss(...)
	if MY_Notify.bDisableDismiss then
		return
	end
	return D.Dismiss(...)
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
	for _, v in ipairs(NOTIFY_LIST) do
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
	local nStart, nCount, nStep = 1, min(#NOTIFY_LIST, 100), 1
	if MY_Notify.bDesc then
		nStart, nStep = #NOTIFY_LIST, -1
	end
	for nIndex = nStart, nStart + (nCount - 1) * nStep, nStep do
		local notify = NOTIFY_LIST[nIndex]
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
MY_Notify.DrawNotifies = D.DrawNotifies

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
			bDismiss = (not notify.fnAction or notify.fnAction(notify.szKey))
		elseif name == 'Handle_Notify_View' then
			notify = this:GetParent().notify
			bDismiss = (not notify.fnAction or notify.fnAction(notify.szKey))
		elseif name == 'Handle_Notify_Dismiss' then
			notify = this:GetParent().notify
			if notify.fnCancel then
				notify.fnCancel(notify.szKey)
			end
			bDismiss = true
		end
		if bDismiss then
			D.Dismiss(notify.szKey, true)
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
	l_uiTipBoard:Clear():Append(szMsg)
	l_uiFrame:FadeTo(500, 255)
	local szHoverFrame = Station.GetMouseOverWindow() and Station.GetMouseOverWindow():GetRoot():GetName()
	if szHoverFrame == 'MY_NotifyTip' then
		LIB.DelayCall('MY_NotifyTip_Hide', 5000)
	else
		LIB.DelayCall('MY_NotifyTip_Hide', 5000, function()
			l_uiFrame:FadeOut(500)
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
		events = {{ 'UI_SCALED', function() l_uiFrame:Anchor(MY_Notify.anchor) end }},
	})
	:CustomMode(_L['MY_Notify'], function()
		LIB.DelayCall('MY_NotifyTip_Hide')
		l_uiFrame:Show():Alpha(255)
	end, function()
		MY_Notify.anchor = l_uiFrame:Anchor()
		l_uiFrame:Alpha(0):Hide()
	end)
	:Anchor(MY_Notify.anchor)
	-- init tip panel handle and bind animation function
	l_uiTipBoard = l_uiFrame:Append('WndScrollBox', {
		handlestyle = 3, x = 0, y = 0, w = 250, h = 150,
		onclick = function()
			if LIB.IsInCustomUIMode() then
				return
			end
			MY_Notify.OpenPanel()
			l_uiFrame:FadeOut(500)
		end,
		onhover = function(bIn)
			if LIB.IsInCustomUIMode() then
				return
			end
			if bIn then
				LIB.DelayCall('MY_NotifyTip_Hide')
				l_uiFrame:FadeIn(500)
			else
				LIB.DelayCall('MY_NotifyTip_Hide', function()
					l_uiFrame:FadeOut(500)
				end, 5000)
			end
		end,
	})
end
LIB.RegisterInit('MY_NotifyTip', OnInit)
end
