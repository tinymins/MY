--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 全局系统消息通知模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/Notify')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local MODULE_NAME = X.NSFormatString('{$NS}_Notify')
local PLUGIN_NAME = X.NSFormatString('{$NS}_Notify')
local PLUGIN_ROOT = X.PACKET_INFO.FRAMEWORK_ROOT
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/notify/')

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['System'], {
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = -100, y = -150, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' },
	},
	bEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bDesc = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bDisableDismiss = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

local FRAME_NAME = MODULE_NAME
local TIP_FRAME_NAME = MODULE_NAME .. 'Tip'

local NOTIFY_LIST = {}
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Notify.ini'

function D.Create(opt)
	table.insert(NOTIFY_LIST, {
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
		X.PlaySound(opt.szSound or 'Notify.ogg')
	end
	return opt.szKey
end
X.CreateNotify = D.Create

function D.Dismiss(szKey, bOnlyData)
	for i, v in X.ipairs_r(NOTIFY_LIST) do
		if v.szKey == szKey then
			table.remove(NOTIFY_LIST, i)
			FireUIEvent(X.NSFormatString('{$NS}_NOTIFY_DISMISS'), szKey)
		end
	end
	if bOnlyData then
		return
	end
	D.UpdateEntry()
	D.DrawNotifies(true)
end

function X.DismissNotify(...)
	if O.bDisableDismiss then
		return
	end
	return D.Dismiss(...)
end

function D.OpenPanel()
	Wnd.OpenWindow(INI_PATH, FRAME_NAME)
end

function D.HookEntry()
	local container = Station.Lookup('Normal/TopMenu/WndContainer_ListOther')
	if not container then
		return
	end
	local wItem = container:Lookup('Wnd_News_XJ')
	if not wItem then
		return
	end
	wItem:Lookup('Btn_News_XJ').OnMouseEnter = function()
		local szXml = GetFormatText(_L['Addon notification'], 59)
			.. X.CONSTANT.XML_LINE_BREAKER
			.. GetFormatText(_L['Click to view addon notification.'], 162)
		X.OutputTip(this, szXml, true, X.UI.TIP_POSITION.RIGHT_LEFT_AND_BOTTOM_TOP)
	end
	wItem:Lookup('Btn_News_XJ').OnLButtonClick = function()
		local menu = {}
		for _, p in pairs(wItem.tPacket) do
			if p.nTotal > 0 then
				table.insert(menu, {
					szOption = p.szName .. (p.nUnread and '  (' .. p.nUnread .. ')' or ''),
					fnAction = p.fnAction,
				})
			end
		end
		if #menu == 1 then
			menu[1].fnAction()
		else
			PopupMenu(menu)
		end
	end
end

function D.UpdateEntry()
	-- local container = Station.Lookup('Normal/TopMenu/WndContainer_List')
	-- if not container then
	-- 	return
	-- end
	local container = Station.Lookup('Normal/TopMenu/WndContainer_ListOther')
	if not container then
		return
	end
	local wItem = container:Lookup('Wnd_News_XJ')
	if not wItem then
		return
	end
	-- 计算数量
	local nTotal, nUnread = 0, 0
	if O.bEntry then
		for _, v in ipairs(NOTIFY_LIST) do
			if v.bUnread then
				nUnread = nUnread + 1
			end
		end
		nTotal = #NOTIFY_LIST
	end
	if not wItem.tPacket then
		wItem.tPacket = {}
	end
	if nTotal > 0 then
		wItem.tPacket[X.PACKET_INFO.NAME_SPACE] = {
			szName = X.PACKET_INFO.NAME,
			nTotal = nTotal,
			nUnread = nUnread,
			fnAction = D.OpenPanel,
		}
	else
		wItem.tPacket[X.PACKET_INFO.NAME_SPACE] = nil
	end
	-- 重新绘制
	local bShow, nUnread = false, 0
	for _, p in pairs(wItem.tPacket) do
		if p.nTotal > 0 then
			bShow = true
		end
		nUnread = nUnread + p.nUnread
	end
	if bShow then
		-- if not wItem then
		-- 	wItem = container:AppendContentFromIni(ENTRY_INI_PATH, 'Wnd_' .. FRAME_NAME .. 'Icon')
		-- 	-- container:SetW(container:GetW() + wItem:GetW())
		-- 	local h = wItem:Lookup('Wnd_' .. FRAME_NAME .. 'Icon_Inner', '')
		-- 	h:Lookup('Image_' .. FRAME_NAME .. 'Icon'):SetAlpha(230)
		-- 	h.OnItemMouseEnter = function() this:Lookup('Image_' .. FRAME_NAME .. 'Icon'):SetAlpha(255) end
		-- 	h.OnItemMouseLeave = function() this:Lookup('Image_' .. FRAME_NAME .. 'Icon'):SetAlpha(230) end
		-- 	h.OnItemLButtonDown = function() this:Lookup('Image_' .. FRAME_NAME .. 'Icon'):SetAlpha(230) end
		-- 	h.OnItemLButtonUp = function() this:Lookup('Image_' .. FRAME_NAME .. 'Icon'):SetAlpha(255) end
		-- 	h.OnItemLButtonClick = function() D.OpenPanel() end
		-- 	container:FormatAllContentPos()
		-- end
		-- wItem:Lookup('Wnd_' .. FRAME_NAME .. 'Icon_Inner', 'Handle_' .. FRAME_NAME .. 'Icon_Num'):SetVisible(nUnread > 0)
		-- wItem:Lookup('Wnd_' .. FRAME_NAME .. 'Icon_Inner', 'Handle_' .. FRAME_NAME .. 'Icon_Num/Text_' .. FRAME_NAME .. 'Icon_Num'):SetText(nUnread)
		wItem:Show()
		wItem:Lookup('Btn_News_XJ', 'Image_Red_Pot'):SetVisible(nUnread > 0)
		container:FormatAllContentPos()
	else
		-- if wItem then
		-- 	-- container:SetW(container:GetW() - wItem:GetW())
		-- 	wItem:Destroy()
		-- 	container:FormatAllContentPos()
		-- end
		wItem:Hide()
		container:FormatAllContentPos()
	end
end

function D.UnhookEntry()
	local container = Station.Lookup('Normal/TopMenu/WndContainer_ListOther')
	if not container then
		return
	end
	local wItem = container:Lookup('Wnd_News_XJ')
	if not wItem then
		return
	end
	wItem.tPacket = nil
	wItem:Hide()
	wItem:Lookup('Btn_News_XJ').OnMouseEnter = nil
	wItem:Lookup('Btn_News_XJ').OnLButtonClick = nil
	-- local container = Station.Lookup('Normal/TopMenu/WndContainer_List')
	-- if not container then
	-- 	return
	-- end
	-- local wItem = container:Lookup('Wnd_' .. FRAME_NAME .. 'Icon')
	-- if wItem then
	-- 	wItem:Destroy()
	-- 	container:FormatAllContentPos()
	-- end
end

function D.DrawNotifies(bAutoClose)
	if bAutoClose and #NOTIFY_LIST == 0 then
		return Wnd.CloseWindow(FRAME_NAME)
	end
	local hList = Station.Lookup('Normal/' .. FRAME_NAME .. '/Window_Main/WndScroll_Notify', 'Handle_Notifies')
	if not hList then
		return
	end
	hList:Clear()
	local nStart, nCount, nStep = 1, math.min(#NOTIFY_LIST, 100), 1
	if O.bDesc then
		nStart, nStep = #NOTIFY_LIST, -1
	end
	for nIndex = nStart, nStart + (nCount - 1) * nStep, nStep do
		local notify = NOTIFY_LIST[nIndex]
		local hItem = hList:AppendItemFromIni(INI_PATH, 'Handle_Notify')
		local hMsg = hItem:Lookup('Handle_Notify_Msg')
		local nDeltaH = hMsg:GetH()
		hMsg:AppendItemFromString(notify.szMsg)
		hMsg:FormatAllItemPos()
		nDeltaH = math.max(select(2, hMsg:GetAllItemSize()), 25) - nDeltaH
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

function D.OnFrameCreate()
	D.DrawNotifies()
	this:Lookup('', 'Text_Title'):SetText(X.PACKET_INFO.NAME .. ' - ' .. _L['Notify center'])
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
end

function D.OnItemLButtonClick()
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

function D.OnLButtonClick()
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
	if szHoverFrame == TIP_FRAME_NAME then
		X.DelayCall(TIP_FRAME_NAME .. '_Hide', 5000)
	else
		X.DelayCall(TIP_FRAME_NAME .. '_Hide', 5000, function()
			l_uiFrame:FadeOut(500)
		end)
	end
end

local function OnInit()
	if l_uiFrame then
		return
	end
	-- init tip frame
	l_uiFrame = X.UI.CreateFrame(TIP_FRAME_NAME, {
		level = 'Topmost', empty = true,
		w = 250, h = 150, visible = false,
		anchor = O.anchor,
		events = {{ 'UI_SCALED', function() l_uiFrame:Anchor(O.anchor) end }},
		customLayout = _L[FRAME_NAME],
		onCustomLayout = function(bEnter, anchor)
			if bEnter then
				X.DelayCall(TIP_FRAME_NAME .. '_Hide', false)
				l_uiFrame:Show():Alpha(255)
			else
				O.anchor = l_uiFrame:Anchor()
				l_uiFrame:Alpha(0):Hide()
			end
		end,
	})
	-- init tip panel handle and bind animation function
	l_uiTipBoard = l_uiFrame:Append('WndScrollHandleBox', {
		handleStyle = 3, x = 0, y = 0, w = 250, h = 150,
		onClick = function()
			if X.IsInCustomUIMode() then
				return
			end
			D.OpenPanel()
			l_uiFrame:FadeOut(500)
		end,
		onHover = function(bIn)
			if X.IsInCustomUIMode() then
				return
			end
			if bIn then
				X.DelayCall(TIP_FRAME_NAME .. '_Hide')
				l_uiFrame:FadeIn(500)
			else
				X.DelayCall(TIP_FRAME_NAME .. '_Hide', function()
					l_uiFrame:FadeOut(500)
				end, 5000)
			end
		end,
	})
end
X.RegisterInit(TIP_FRAME_NAME, OnInit)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	nX = nPaddingX
	nY = nLFY

	ui:Append('Text', {
		x = nPaddingX - 10, y = nY,
		text = _L['Notify center'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = _L['Show in minimap'],
		checked = O.bEntry,
		onCheck = function(bChecked)
			O.bEntry = bChecked
			D.UpdateEntry()
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Order desc'],
		checked = O.bDesc,
		onCheck = function(bChecked)
			O.bDesc = bChecked
			D.DrawNotifies()
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Disable dismiss'],
		checked = O.bDisableDismiss,
		onCheck = function(bChecked)
			O.bDisableDismiss = bChecked
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + nLH
	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterInit(FRAME_NAME, function()
	D.HookEntry()
	D.UpdateEntry()
end)
X.RegisterUserSettingsInit(MODULE_NAME, function()
	D.UpdateEntry()
end)
X.RegisterReload(FRAME_NAME, D.UnhookEntry)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
