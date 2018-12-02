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
	GetTarget = MY_TargetMonData.GetTarget,
	GetViewData = MY_TargetMonData.GetViewData,
	SetConfigData = MY_TargetMonConfig.SetData,
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
	local szAnchorBase = frame.tViewData.szAnchorBase
	local tAnchor = GetFrameAnchor(frame, szAnchorBase)
	D.SetConfigData(frame.tViewData.szUuid, {'anchor'}, tAnchor)
end

function D.UpdateAnchor(frame)
	local anchor = frame.tViewData.tAnchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	local x, y = frame:GetAbsPos()
	local w, h = frame:GetSize()
	local cw, ch = Station.GetClientSize()
	if (x < cw or y < ch) and (x + w > 0 and y + h > 0) then
		return
	end
	frame:CorrectPos()
end

function D.UpdateScale(frame)
	-- 禁止系统UI缩放
	local fCurrUIScale = Station.GetUIScale()
	if not frame.fCurrUIScale then
		frame.fCurrUIScale = 1
	end
	if frame.fCurrUIScale ~= fCurrUIScale then
		if frame.bIgnoreSystemUIScale and frame.fCurrUIScale then
			local hList, hItem, txt = frame:Lookup('', 'Handle_List')
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				txt = hItem:Lookup('Handle_Box/Text_ShortName')
				txt:SetFontScale(txt:GetFontScale() * frame.fCurrUIScale / fCurrUIScale)
				txt = hItem:Lookup('Handle_Bar/Text_Name')
				txt:SetFontScale(txt:GetFontScale() * frame.fCurrUIScale / fCurrUIScale)
				txt = hItem:Lookup('Handle_Bar/Text_Process')
				txt:SetFontScale(txt:GetFontScale() * frame.fCurrUIScale / fCurrUIScale)
			end
			frame:Scale(frame.fCurrUIScale / fCurrUIScale, frame.fCurrUIScale / fCurrUIScale)
		end
		frame.fCurrUIScale = fCurrUIScale
	end
	-- 界面自定义缩放
	if not frame.fCurrScale then
		frame.fCurrScale = 1
	end
	local fUIScale = frame.tViewData.fUIScale
	if fUIScale ~= frame.fCurrScale then
		local relScale = fUIScale / frame.fCurrScale
		frame:Scale(relScale, relScale)
		frame.fCurrScale = fUIScale
	end
end

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
		D.UpdateScale(frame)
		D.UpdateAnchor(frame)
	end
	local hTotal, hList, nIndex, hItem = frame.hTotal, frame.hList, 0
	for _, item in ipairs(tViewData.aItem) do
		hItem = hList:Lookup(nIndex)
		nIndex = nIndex + 1
		if not hItem then
			hItem = hList:AppendItemFromIni(INI_PATH, 'Handle_Item')
			hItem.hBox         = hItem:Lookup('Handle_Box')
			hItem.box          = hItem.hBox:Lookup('Box_Default')
			hItem.imgBoxBg     = hItem.hBox:Lookup('Image_BoxBg')
			hItem.nBoxW        = hItem.imgBoxBg:GetW()
			hItem.nBoxH        = hItem.imgBoxBg:GetH()
			hItem.txtTime      = hItem.hBox:Lookup('Text_Time')
			hItem.txtHotkey    = hItem.hBox:Lookup('Text_Hotkey')
			hItem.txtStackNum  = hItem.hBox:Lookup('Text_StackNum')
			hItem.txtShortName = hItem.hBox:Lookup('Text_ShortName')
			hItem.hCDBar       = hItem:Lookup('Handle_Bar')
			hItem.txtProcess   = hItem.hCDBar:Lookup('Text_Process')
			hItem.imgProcess   = hItem.hCDBar:Lookup('Image_Process')
			hItem.txtLongName  = hItem.hCDBar:Lookup('Text_Name')
			hItem.imgProcess:SetPercentage(0)
			hItem.fUIScale = 1
			hItem.fFontScale = MY.GetFontScale()
			D.UpdateItemHotkey(hItem, frame.nIndex, nIndex)
			bRequireFormatPos = true
		end
		if hItem.fUIScale ~= tViewData.fUIScale then
			hItem:Scale(tViewData.fUIScale / hItem.fUIScale)
			hItem.fUIScale = tViewData.fUIScale
		end
		if hItem.bCdBar ~= tViewData.bCdBar
		or hItem.nCdBarWidth ~= tViewData.nCdBarWidth
		or hItem.fFontScale ~= tViewData.fFontScale then
			if tViewData.bCdBar then
				hItem.hCDBar:Show()
				hItem.txtShortName:Hide()
				hItem.hCDBar:SetW(tViewData.nCdBarWidth)
				hItem.imgProcess:SetW(tViewData.nCdBarWidth)
				hItem.txtProcess:SetW(tViewData.nCdBarWidth - 10)
				hItem.txtLongName:SetW(tViewData.nCdBarWidth - 10)
				hItem:SetSize(hItem.nBoxW + tViewData.nCdBarWidth, hItem.nBoxH)
			else
				hItem.hCDBar:Hide()
				hItem.txtShortName:Show()
				hItem:SetSize(hItem.nBoxW, hItem.nBoxH + hItem.txtShortName:GetH() * tViewData.fFontScale)
			end
			hItem.txtTime:SetFontScale(tViewData.fFontScale * 1.2)
			hItem.txtHotkey:SetFontScale(tViewData.fFontScale)
			hItem.txtStackNum:SetFontScale(tViewData.fFontScale)
			hItem.txtProcess:SetFontScale(tViewData.fFontScale)
			hItem.txtLongName:SetFontScale(tViewData.fFontScale)
			hItem.txtShortName:SetFontScale(tViewData.fFontScale)
			hItem.bCdBar = tViewData.bCdBar
			hItem.nCdBarWidth = tViewData.nCdBarWidth
			hItem.fFontScale = tViewData.fFontScale
		end
		if hItem.nIcon ~= item.nIcon then
			hItem.box:SetObjectIcon(item.nIcon)
			hItem.nIcon = item.nIcon
		end
		if hItem.bCd ~= item.bCd then
			hItem.box:SetObjectCoolDown(item.bCd)
			hItem.bCd = item.bCd
		end
		if hItem.fCd ~= item.fCd and item.bCd then
			hItem.box:SetCoolDownPercentage(item.fCd)
			hItem.fCd = item.fCd
		end
		if hItem.fProgress ~= item.fCd and tViewData.bCdBar then
			hItem.imgProcess:SetPercentage(1 - item.fCd)
			hItem.fProgress = item.fCd
		end
		if hItem.szCdBarUITex ~= item.szCdBarUITex and tViewData.bCdBar then
			UI(hItem.imgProcess):image(tViewData.szCdBarUITex)
			hItem.szCdBarUITex = item.szCdBarUITex
		end
		if hItem.bStaring ~= item.bStaring then
			hItem.box:SetObjectStaring(item.bStaring)
			hItem.bStaring = item.bStaring
		end
		if hItem.bSparking ~= item.bSparking then
			hItem.box:SetObjectSparking(item.bSparking)
			hItem.bSparking = item.bSparking
		end
		if hItem.szBoxExtentAnimate ~= item.aExtentAnimate[1]
		or hItem.nBoxExtentAnimate ~= item.aExtentAnimate[2] then
			if hItem.szBoxExtentAnimate then
				hItem.box:SetExtentAnimate(hItem.szBoxExtentAnimate, hItem.nBoxExtentAnimate)
			else
				hItem.box:ClearExtentAnimate()
			end
			hItem.szBoxExtentAnimate, hItem.nBoxExtentAnimate = unpack(item.aExtentAnimate)
		end
		if hItem.szTimeLeft ~= item.szTimeLeft then
			hItem.txtTime:SetText(item.szTimeLeft)
			hItem.txtProcess:SetText(item.szTimeLeft)
			hItem.szTimeLeft = item.szTimeLeft
		end
		if hItem.szStackNum ~= item.szStackNum then
			hItem.txtStackNum:SetText(item.szStackNum)
			hItem.szStackNum = item.szStackNum
		end
		if hItem.nLongAliasR ~= item.aLongAliasRGB[1]
		or hItem.nLongAliasG ~= item.aLongAliasRGB[2]
		or hItem.nLongAliasB ~= item.aLongAliasRGB[3] then
			hItem.txtLongName:SetFontColor(hItem.nLongAliasR, hItem.nLongAliasG, hItem.nLongAliasB)
			hItem.nLongAliasR, hItem.nLongAliasG, hItem.nLongAliasB = unpack(item.aLongAliasRGB)
		end
		if hItem.szLongName ~= item.szLongName then
			hItem.txtLongName:SetText(item.szLongName)
			hItem.szLongName = item.szLongName
		end
		if hItem.nShortAliasR ~= item.aShortAliasRGB[1]
		or hItem.nShortAliasG ~= item.aShortAliasRGB[2]
		or hItem.nShortAliasB ~= item.aShortAliasRGB[3] then
			hItem.txtShortName:SetFontColor(hItem.nShortAliasR, hItem.nShortAliasG, hItem.nShortAliasB)
			hItem.nShortAliasR, hItem.nShortAliasG, hItem.nShortAliasB = unpack(item.aShortAliasRGB)
		end
		if hItem.szShortName ~= item.szShortName then
			hItem.txtShortName:SetText(item.szShortName)
			hItem.szShortName = item.szShortName
		end
		hItem:Show()
		hItem.dwID = item.dwID
		hItem.nLevel = item.nLevel
	end
	for i = nIndex, hList:GetItemCount() - 1 do
		hList:Lookup(i):Hide()
	end
	-- 检查是否需要重绘界面坐标
	if bRequireFormatPos then
		frame.nWidth = 200
		frame.nHeight = 50
		hItem = hList:Lookup(0)
		if hItem then
			frame.nWidth = max(frame.nWidth, hItem:GetW() * min(tViewData.nMaxLineCount, nIndex))
			frame.nHeight = max(frame.nHeight, ceil(nIndex / tViewData.nMaxLineCount) * hItem:GetH())
		end
		hList:SetW(frame.nWidth)
		hList:FormatAllItemPosExt()
		hList:SetSize(frame.nWidth, frame.nHeight)
		hTotal:SetSize(frame.nWidth, frame.nHeight)
		frame:SetSize(frame.nWidth, frame.nHeight)
		frame:SetDragArea(0, 0, frame.nWidth, frame.nHeight)
	end
	if frame.bPenetrable ~= tViewData.bPenetrable
	or frame.bDragable ~= tViewData.bDragable then
		frame.bPenetrable = tViewData.bPenetrable
		frame.bDragable = tViewData.bDragable
		frame:EnableDrag(not tViewData.bPenetrable and tViewData.bDragable)
		frame:SetMousePenetrable(tViewData.bPenetrable)
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
	D.UpdateFrame(this)
end
end

function MY_TargetMonView.OnFrameBreathe()
	D.UpdateFrame(this)
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
		D.UpdateScale(this)
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
