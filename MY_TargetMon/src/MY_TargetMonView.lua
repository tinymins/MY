--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     :
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
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------
local D = {
	ModifyConfig = MY_TargetMonConfig.ModifyConfig,
	GetTarget = MY_TargetMonData.GetTarget,
	GetViewData = MY_TargetMonData.GetViewData,
	RegisterDataUpdateEvent = MY_TargetMonData.RegisterDataUpdateEvent,
}
local INI_PATH = PACKET_INFO.ROOT .. 'MY_TargetMon/ui/MY_TargetMon.ini'

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
local function DrawItem(hList, hItem, nGroup, nIndex, tViewData, item, bScaleReset, bRequireFormatPos)
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
		hItem.fIconFontScale = LIB.GetFontScale()
		hItem.fOtherFontScale = LIB.GetFontScale()
		local fRelativeScale = 1 / Station.GetUIScale()
		hItem:Scale(fRelativeScale, fRelativeScale)
		hItem:Hide()
		D.UpdateItemHotkey(hItem, nGroup, nIndex)
		bRequireFormatPos = true
	end
	if hItem.fUIScale ~= tViewData.fUIScale
	or bScaleReset then
		local fRelativeScale = tViewData.fUIScale / hItem.fUIScale
		hItem:Scale(fRelativeScale, fRelativeScale)
		hItem.nBoxW = hItem.imgBoxBg:GetW()
		hItem.nBoxH = hItem.imgBoxBg:GetH()
		hItem.fUIScale = tViewData.fUIScale
	end
	if hItem.bCdBar ~= tViewData.bCdBar
	or hItem.nCdBarWidth ~= tViewData.nCdBarWidth
	or hItem.fIconFontScale ~= tViewData.fIconFontScale
	or hItem.fOtherFontScale ~= tViewData.fOtherFontScale
	or bScaleReset then
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
			hItem:SetSize(hItem.nBoxW, hItem.nBoxH
				+ (hItem.txtShortName:GetRelY() - hItem.nBoxH) * 2
				+ hItem.txtShortName:GetH() * tViewData.fOtherFontScale / tViewData.fUIScale * Station.GetUIScale())
		end
		hItem.txtTime:SetFontScale(tViewData.fIconFontScale * 1.2)
		hItem.txtHotkey:SetFontScale(tViewData.fIconFontScale)
		hItem.txtStackNum:SetFontScale(tViewData.fIconFontScale)
		hItem.txtProcess:SetFontScale(tViewData.fOtherFontScale)
		hItem.txtLongName:SetFontScale(tViewData.fOtherFontScale)
		hItem.txtShortName:SetFontScale(tViewData.fOtherFontScale)
		hItem.bCdBar = tViewData.bCdBar
		hItem.nCdBarWidth = tViewData.nCdBarWidth
		hItem.fIconFontScale = tViewData.fIconFontScale
		hItem.fOtherFontScale = tViewData.fOtherFontScale
		bRequireFormatPos = true
	end
	if hItem.szCdBarUITex ~= tViewData.szCdBarUITex and tViewData.bCdBar then
		UI(hItem.imgProcess):Image(tViewData.szCdBarUITex)
		hItem.szCdBarUITex = tViewData.szCdBarUITex
	end
	if hItem.szBoxBgUITex ~= tViewData.szBoxBgUITex then
		UI(hItem.imgBoxBg):Image(tViewData.szBoxBgUITex)
		hItem.szBoxBgUITex = tViewData.szBoxBgUITex
	end
	if item then
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
		if hItem.fCdBar ~= item.fCdBar and tViewData.bCdBar then
			hItem.imgProcess:SetPercentage(item.fCdBar)
			hItem.fCdBar = item.fCdBar
		end
		if hItem.szCdBarUITex ~= tViewData.szCdBarUITex and tViewData.bCdBar then
			UI(hItem.imgProcess):Image(tViewData.szCdBarUITex)
			hItem.szCdBarUITex = tViewData.szCdBarUITex
		end
		if hItem.szBoxBgUITex ~= tViewData.szBoxBgUITex then
			UI(hItem.imgBoxBg):Image(tViewData.szBoxBgUITex)
			hItem.szBoxBgUITex = tViewData.szBoxBgUITex
		end
		if hItem.bStaring ~= item.bStaring then
			hItem.box:SetObjectStaring(item.bStaring)
			hItem.bStaring = item.bStaring
		end
		if hItem.bSparking ~= item.bSparking then
			hItem.box:SetObjectSparking(item.bSparking)
			hItem.bSparking = item.bSparking
		end
		if hItem.szBoxExtentAnimate ~= item.szExtentAnimate then
			if item.szExtentAnimate and item.szExtentAnimate ~= '' then
				local szPath, nFrame = unpack(LIB.SplitString(item.szExtentAnimate, '|'))
				hItem.box:SetExtentAnimate(szPath, nFrame)
			else
				hItem.box:ClearExtentAnimate()
			end
			hItem.szBoxExtentAnimate = item.szExtentAnimate
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
			hItem.txtLongName:SetFontColor(unpack(item.aLongAliasRGB))
			hItem.nLongAliasR, hItem.nLongAliasG, hItem.nLongAliasB = unpack(item.aLongAliasRGB)
		end
		if hItem.szLongName ~= item.szLongName then
			hItem.txtLongName:SetText(item.szLongName)
			hItem.szLongName = item.szLongName
		end
		if hItem.nShortAliasR ~= item.aShortAliasRGB[1]
		or hItem.nShortAliasG ~= item.aShortAliasRGB[2]
		or hItem.nShortAliasB ~= item.aShortAliasRGB[3] then
			hItem.txtShortName:SetFontColor(unpack(item.aShortAliasRGB))
			hItem.nShortAliasR, hItem.nShortAliasG, hItem.nShortAliasB = unpack(item.aShortAliasRGB)
		end
		if hItem.szShortName ~= item.szShortName then
			hItem.txtShortName:SetText(item.szShortName)
			hItem.szShortName = item.szShortName
		end
		if not hItem:IsVisible() then
			bRequireFormatPos = true
			hItem:Show()
		end
		hItem.dwID = item.dwID
		hItem.nLevel = item.nLevel
	end
	return hItem, bRequireFormatPos
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
			LIB.OutputBuffTip({x, y, w, h}, hItem.dwID, hItem.nLevel, hItem.nTimeLeft)
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
		local KTarget = LIB.GetObject(D.GetTarget(tViewData.szTarget, tViewData.szType))
		if not KTarget then
			return
		end
		LIB.CancelBuff(KTarget, hItem.dwID, hItem.nLevel)
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
LIB.RegisterEvent('MY_TARGET_MON_DATA_INIT.MY_TargetMonView', onDataInit)
end
