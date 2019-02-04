--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     :
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local MY, UI = MY, MY.UI
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local Get, GetPatch, ApplyPatch, RandomChild = MY.Get, MY.GetPatch, MY.ApplyPatch, MY.RandomChild
---------------------------------------------------------------------------------------------------
local D = {
	ModifyConfig = MY_TargetMonConfig.ModifyConfig,
	GetTarget = MY_TargetMonData.GetTarget,
	GetViewData = MY_TargetMonData.GetViewData,
	RegisterDataUpdateEvent = MY_TargetMonData.RegisterDataUpdateEvent,
}
local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/ui/MY_TargetMon.ini'
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')

function D.UpdateItemHotkey(hItem, i, j)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get('MY_TargetMon_' .. i .. '_' .. j)
	hItem.txtHotkey:SetText(GetKeyShow(nKey, bShift, bCtrl, bAlt, true))
end

function D.UpdateHotkey(frame)
	local i = this.nIndex
	local hList = frame:Lookup('', 'Handle_List')
	for j = 0, hList:GetItemCount() - 1 do
		D.UpdateItemHotkey(hList:Lookup(j), i, j + 1)
	end
end

function D.SaveAnchor(frame)
	local nHeight = frame:GetH()
	frame:SetH(frame.nRowHeight)
	local tAnchor = GetFrameAnchor(frame)
	frame:SetH(nHeight)
	if frame.tViewData.bIgnoreSystemUIScale then
		local fRelativeScale = Station.GetUIScale()
		tAnchor.x = tAnchor.x * fRelativeScale
		tAnchor.y = tAnchor.y * fRelativeScale
	end
	D.ModifyConfig(frame.tViewData.szUuid, 'anchor', tAnchor)
end

function D.UpdateAnchor(frame)
	local anchor = frame.tViewData.tAnchor
	local fRelativeScale = frame.tViewData.bIgnoreSystemUIScale and (1 / Station.GetUIScale()) or 1
	local nHeight = frame:GetH()
	frame:SetH(frame.nRowHeight)
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x * fRelativeScale, anchor.y * fRelativeScale)
	frame:SetH(nHeight)
	local x, y = frame:GetAbsPos()
	local w, h = frame:GetSize()
	local cw, ch = Station.GetClientSize()
	if (x < cw or y < ch) and (x + w > 0 and y + h > 0) then
		return
	end
	frame:CorrectPos()
end

function D.ResetScale(frame)
	-- 界面缩放重置为1.0
	local fUIScale = Station.GetUIScale()
	if frame.fUIScale ~= fUIScale then
		local fRelativeScale = (frame.fUIScale or 1) / fUIScale
		frame:Scale(fRelativeScale, fRelativeScale)
		frame.fUIScale = fUIScale
	end
	this.bScaleReset = true
end

do
function D.UpdateFrame(frame)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local tViewData = D.GetViewData(frame.nIndex)
	if not tViewData then
		return Wnd.CloseWindow(frame)
	end
	local bRequireFormatPos = false
	if frame.tViewData ~= tViewData then
		bRequireFormatPos = true
		frame.tViewData = tViewData
		frame.nWidth = 200
		frame.nHeight = 50
		D.UpdateHotkey(frame)
	end
	local bScaleReset = frame.bScaleReset
	if bScaleReset then
		bRequireFormatPos = true
		frame.bScaleReset = nil
	end
	if frame.nMaxLineCount ~= tViewData.nMaxLineCount then
		bRequireFormatPos = true
		frame.nMaxLineCount = tViewData.nMaxLineCount
	end
	if frame.szAlignment ~= tViewData.szAlignment then
		bRequireFormatPos = true
		frame.szAlignment = tViewData.szAlignment
	end
	local hTotal, hList, nGroup, nIndex, hItem = frame.hTotal, frame.hList, frame.nIndex, 0
	for _, item in ipairs(tViewData.aItem) do
		hItem = hList:Lookup(nIndex)
		nIndex = nIndex + 1
		hItem, bRequireFormatPos = DrawItem(hList, hItem, nGroup, nIndex, tViewData, item, bScaleReset, bRequireFormatPos)
	end
	for i = nIndex, hList:GetItemCount() - 1 do
		hItem = hList:Lookup(i)
		if hItem:IsVisible() then
			bRequireFormatPos = true
			hItem:Hide()
		end
	end
	-- 检查是否需要重绘界面坐标
	if bRequireFormatPos then
		frame.hTemplateItem = DrawItem(hList, frame.hTemplateItem, nGroup, 0, tViewData, nil, bScaleReset, bRequireFormatPos)
		hItem = frame.hTemplateItem
		local nCount = hList:GetItemCount()
		frame.nWidth = ceil(hItem:GetW()) * tViewData.nMaxLineCount
		frame.nHeight = ceil(nCount / tViewData.nMaxLineCount) * ceil(hItem:GetH())
		frame.nRowHeight = ceil(hItem:GetH())
		hList:SetW(frame.nWidth)
		hList:SetIgnoreInvisibleChild(true)
		hList:SetHAlign(ALIGNMENT[tViewData.szAlignment] or ALIGNMENT.LEFT)
		hList:FormatAllItemPosExt()
		hList:SetSize(frame.nWidth, frame.nHeight)
		hTotal:SetSize(frame.nWidth, frame.nHeight)
		frame:SetSize(frame.nWidth, frame.nHeight)
		frame:SetDragArea(0, 0, frame.nWidth, frame.nHeight)
		D.UpdateAnchor(frame)
	end
	if frame.bPenetrable ~= tViewData.bPenetrable
	or frame.bDragable ~= tViewData.bDragable then
		frame.bPenetrable = tViewData.bPenetrable
		frame.bDragable = tViewData.bDragable
		frame:EnableDrag(not tViewData.bPenetrable and tViewData.bDragable)
		frame:SetMousePenetrable(tViewData.bPenetrable)
	end
end
end

MY_TargetMonView = class()

do
local function FormatAllItemPosExt(hList)
	local hItem = hList:Lookup(0)
	if not hItem then
		return
	end
	local W = hList:GetW()
	local w, h = hItem:GetSize()
	local columms = max(floor(W / w), 1)
	local ignoreInvisible = hList:IsIgnoreInvisibleChild()
	local aItem = {}
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		if not ignoreInvisible or hItem:IsVisible() then
			insert(aItem, hItem)
		end
	end
	local align, y = hList:GetHAlign(), 0
	while #aItem > 0 do
		local x, deltaX = 0, 0
		if align == ALIGNMENT.LEFT then
			x, deltaX = 0, w
		elseif align == ALIGNMENT.RIGHT then
			x, deltaX = W - w, - w
		elseif align == ALIGNMENT.CENTER then
			x, deltaX = (W - w * min(#aItem, columms)) / 2, w
		end
		for i = 1, min(#aItem, columms) do
			remove(aItem, 1):SetRelPos(x, y)
			x = x + deltaX
		end
		y = y + h
	end
	hList:SetSize(W, y)
	hList:FormatAllItemPos()
end
function MY_TargetMonView.OnFrameCreate()
	this.nIndex = tonumber(this:GetName():sub(#'MY_TargetMon#' + 1))
	this.hTotal = this:Lookup('', '')
	this.hList = this:Lookup('', 'Handle_List')
	this.hList:Clear()
	this.hList.FormatAllItemPosExt = FormatAllItemPosExt
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('HOT_KEY_RELOADED')
	this:RegisterEvent('SKILL_MOUNT_KUNG_FU')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	D.ResetScale(this)
	D.UpdateFrame(this)
	D.RegisterDataUpdateEvent(this, D.UpdateFrame)
end
end

function MY_TargetMonView.OnFrameDestroy()
	D.RegisterDataUpdateEvent(this, false)
end

function MY_TargetMonView.OnFrameDragEnd()
	D.SaveAnchor(this)
end

function MY_TargetMonView.OnItemMouseEnter()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.tViewData.szType
	if name == 'Box_Default' then
		local hItem = this:GetParent():GetParent()
		if eMonType == 'BUFF' and hItem.dwID and hItem.nLevel then
			local w, h = hItem:GetW(), hItem:GetH()
			local x, y = hItem:GetAbsX(), hItem:GetAbsY()
			MY.OutputBuffTip(hItem.dwID, hItem.nLevel, {x, y, w, h}, hItem.nTimeLeft)
		end
		this:SetObjectMouseOver(1)
	end
end

function MY_TargetMonView.OnItemMouseLeave()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.tViewData.szType
	if name == 'Box_Default' then
		if eMonType == 'BUFF' then
			HideTip()
		end
		this:SetObjectMouseOver(0)
	end
end

function MY_TargetMonView.OnItemLButtonDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.tViewData.szType
	if name == 'Box_Default' then
		this:SetObjectPressed(1)
	end
end
MY_TargetMonView.OnItemRButtonDown = MY_TargetMonView.OnItemLButtonDown

function MY_TargetMonView.OnItemLButtonUp()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.tViewData.szType
	if name == 'Box_Default' then
		this:SetObjectPressed(0)
	end
end
MY_TargetMonView.OnItemRButtonUp = MY_TargetMonView.OnItemLButtonUp

function MY_TargetMonView.OnItemRButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	local tViewData = frame.tViewData
	if name == 'Box_Default' and tViewData.szType == 'BUFF' then
		local hItem = this:GetParent():GetParent()
		local KTarget = MY.GetObject(D.GetTarget(tViewData.szTarget, tViewData.szType))
		if not KTarget then
			return
		end
		MY.CancelBuff(KTarget, hItem.dwID, hItem.nLevel)
	end
end

function MY_TargetMonView.OnEvent(event)
	if event == 'HOT_KEY_RELOADED' then
		D.UpdateHotkey(this)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		this:Lookup('', 'Handle_List'):SetAlpha(90)
		UpdateCustomModeWindow(this, _L['[MY TargetMon] '] .. this.tViewData.szCaption, this.tViewData.bPenetrable)
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		this:Lookup('', 'Handle_List'):SetAlpha(255)
		UpdateCustomModeWindow(this, _L['[MY TargetMon] '] .. this.tViewData.szCaption, this.tViewData.bPenetrable)
		if this.tViewData.bDragable then
			this:EnableDrag(true)
		end
		D.SaveAnchor(this)
	elseif event == 'UI_SCALED' then
		D.ResetScale(this)
		D.UpdateAnchor(this)
	end
end

do
local function onDataInit()
	for nIndex, _ in ipairs(D.GetViewData()) do
		if not Station.Lookup('Normal/' .. 'MY_TargetMon#' .. nIndex) then
			Wnd.OpenWindow(INI_PATH, 'MY_TargetMon#' .. nIndex)
		end
	end
end
MY.RegisterEvent('MY_TARGET_MON_DATA_INIT.MY_TargetMonView', onDataInit)
end
