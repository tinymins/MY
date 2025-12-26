--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 弹出菜单
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.DragDrop')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local PLUGIN_NAME = X.NSFormatString('{$NS}_DragDrop')

local DRAG_FRAME_NAME = X.NSFormatString('{$NS}_UI__Drag')
local DROP_FRAME_NAME = X.NSFormatString('{$NS}_UI__Drop')

local D = {}
local DATA, HOVER_EL

function D.IsOpened()
	return DATA ~= nil
end

function D.Open(raw, capture, ...)
	if D.IsOpened() then
		return
	end
	local captureEl
	local nX, nY = Cursor.GetPos()
	local nW, nH
	local nCaptureX, nCaptureY
	if X.IsElement(capture) then
		captureEl = capture
	elseif X.IsTable(capture) then
		captureEl = capture.element
		nCaptureX = capture.x
		nCaptureY = capture.y
		nW = capture.w
		nH = capture.h
	end
	if not captureEl then
		captureEl = raw
	end
	if not nCaptureX then
		nCaptureX = 0
	end
	if not nCaptureY then
		nCaptureY = 0
	end
	if not nW then
		nW = captureEl:GetW()
	end
	if not nH then
		nH = captureEl:GetH()
	end
	local nCaptureW, nCaptureH = captureEl:GetW(), captureEl:GetH()
	-- 拽入位置提示
	local frame = X.UI.OpenFrame(X.PACKET_INFO.FRAMEWORK_ROOT .. '/ui/DragDrop.ini', DROP_FRAME_NAME)
	frame:SetAlpha(150)
	frame:Hide()
	-- 拖拽状态提示
	local frame = X.UI.OpenFrame(X.PACKET_INFO.FRAMEWORK_ROOT .. '/ui/DragDrop.ini', DRAG_FRAME_NAME)
	frame:Lookup('', ''):SetSize(nW + 4, nH + 4)
	frame:Lookup('', 'Image_Background'):SetSize(nW + 4, nH + 4)
	frame:Lookup('', 'Handle_ScreenShot'):SetSize(nW, nH)
	frame:Lookup('', 'Handle_ScreenShot/Image_ScreenShot'):SetSize(nCaptureW, nCaptureH)
	frame:Lookup('', 'Handle_ScreenShot/Image_ScreenShot'):SetRelPos(-nCaptureX, -nCaptureY)
	if captureEl:GetBaseType() == 'Wnd' then
		frame:Lookup('', 'Handle_ScreenShot/Image_ScreenShot'):FromWindow(captureEl)
	else
		frame:Lookup('', 'Handle_ScreenShot/Image_ScreenShot'):FromItem(captureEl)
	end
	frame:Lookup('', 'Handle_ScreenShot'):FormatAllItemPos()
	frame:SetRelPos(nX, nY)
	frame:SetSize(nW, nH)
	frame:StartMoving()
	frame:BringToTop()
	Cursor.Switch(X.UI.CURSOR.ON_DRAG)
	DATA = X.Pack(...)
	X.DelayCall(X.NSFormatString('{$NS}_UI__DragDrop_Clear'), false)
end

function D.Close()
	local frame = Station.SearchFrame(DRAG_FRAME_NAME)
	if frame then
		local xData = DATA
		local dropEl = HOVER_EL
		HOVER_EL = nil
		X.DelayCall(X.NSFormatString('{$NS}_UI__DragDrop_Clear'), 50, function() DATA = nil end) -- 由于 Click 在 DragEnd 之后
		Cursor.Switch(X.UI.CURSOR.NORMAL)
		frame:EndMoving()
		X.UI.CloseFrame(DRAG_FRAME_NAME)
		X.UI.CloseFrame(DROP_FRAME_NAME)
		return dropEl, X.Unpack(xData)
	end
end

function D.GetData()
	if DATA then
		return X.Unpack(DATA)
	end
end

function D.SetHoverEl(el, rect, bAcceptable, eCursor)
	if not D.IsOpened() then
		return
	end
	local frame = Station.SearchFrame(DROP_FRAME_NAME)
	if not frame then
		return
	end
	if el then
		local nX, nY, nW, nH
		if X.IsElement(rect) then
			nX, nY = rect:GetAbsPos()
			nW, nH = rect:GetSize()
		elseif X.IsTable(rect) then
			nX = rect.x
			nY = rect.y
			nW = rect.w
			nH = rect.h
		end
		if not nX then
			nX = el:GetAbsX()
		end
		if not nY then
			nY = el:GetAbsY()
		end
		if not nW then
			nW = el:GetW()
		end
		if not nH then
			nH = el:GetH()
		end
		frame:SetRelPos(nX - 2, nY - 2)
		frame:Lookup('', ''):SetSize(nW + 4, nH + 4)
		frame:Lookup('', 'Image_Background'):SetSize(nW + 4, nH + 4)
		frame:Show()
	else
		frame:Hide()
	end
	HOVER_EL = el
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = PLUGIN_NAME,
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'IsOpened',
				'Open',
				'Close',
				'GetData',
				'SetHoverEl',
			},
			root = D,
		},
	},
}
_G[PLUGIN_NAME] = X.CreateModule(settings)
end

X.UI.IsDragDropOpened = D.IsOpened
X.UI.OpenDragDrop = D.Open
X.UI.CloseDragDrop = D.Close
X.UI.GetDragDropData = D.GetData
X.UI.SetDragDropHoverEl = D.SetHoverEl

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
