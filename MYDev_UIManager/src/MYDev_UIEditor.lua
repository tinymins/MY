--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : UI²é¿´Æ÷
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MYDev_UIManager/lang/')
if not LIB.AssertVersion('MYDev_UIManager', _L['MYDev_UIEditor'], 0x2011800) then
	return
end

local UI_INIFILE = PACKET_INFO.ROOT .. 'MYDev_UIManager/ui/MYDev_UIEditor.ini'
local O = {}
local D = {}

-- stack overflow
local function GetUIStru(el)
	local data = {}
	local function GetInfo(el)
		local szType = el:GetType()
		local szName = el:GetName()
		local bIsWnd = szType:sub(1, 3) == 'Wnd'
		local bChild, hChildItem
		if bIsWnd then
			bChild     = el:GetFirstChild() ~= nil
			hChildItem = el:Lookup('', '')
		elseif szType == 'Handle' or szType == 'TreeLeaf' then
			bChild = el:Lookup(0) ~= nil
		end
		local dat = {
			___id  = el, -- ui metatable
			aPath  = { el:GetTreePath() },
			szType = szType,
			szName = szName,
			aChild = (bChild or hChildItem) and {} or nil
		}
		return dat, bIsWnd, bChild, hChildItem
	end
	local function GetItemStru(el, tab)
		local dat, bIsWnd, bChild = GetInfo(el)
		insert(tab, dat)
		if bChild then
			local i = 0
			while el:Lookup(i) do
				local frame = el:Lookup(i)
				GetItemStru(frame, dat.aChild)
				i = i + 1
			end
		end
	end
	local function GetWinStru(el, tab)
		local dat, bIsWnd, bChild, hChildItem = GetInfo(el)
		insert(tab, dat)
		if hChildItem then
			GetItemStru(hChildItem, dat.aChild)
		end
		if bChild then
			local aChild = tab[#tab]
			local frame = el:GetFirstChild()
			while frame do
				local dat, bIsWnd = GetInfo(frame)
				if bIsWnd then
					GetWinStru(frame, aChild.aChild)
				else
					GetItemStru(frame, aChild.aChild)
				end
				frame = frame:GetNext()
			end
		end
	end
	local dat, bIsWnd, bChild = GetInfo(el)
	if bIsWnd then
		GetWinStru(el, data)
	else
		GetItemStru(el, data)
	end
	return data
end

MYDev_UIEditor = class()

function MYDev_UIEditor.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this.anchor   = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
	this.hNode    = this:CreateItemData(UI_INIFILE, 'TreeLeaf_Node')
	this.hContent = this:CreateItemData(UI_INIFILE, 'TreeLeaf_Content')
	this.hList    = this:Lookup('WndScroll_Tree', '')
	this.hUIPos   = this:Lookup('', 'Image_UIPos')
	this.hList:Clear()
	this:ShowWhenUIHide()
	this:SetPoint(this.anchor.s, 0, 0, this.anchor.r, this.anchor.x, this.anchor.y)
end

do
local nUpdateTime = 0
function MYDev_UIEditor.OnFrameBreathe()
	if GetTime() - nUpdateTime > 500 then
		local handle, el = this.hList
		for i = 0, handle:GetItemCount() - 1 do
			el = handle:Lookup(i)
			if el.dat and el.dat.___id and not el.dat.___id:IsValid() then
				D.UpdateTree(this)
				break
			end
		end
		nUpdateTime = GetTime()
	end
	-- this:BringToTop()
end
end

function MYDev_UIEditor.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		this:SetPoint(this.anchor.s, 0, 0, this.anchor.r, this.anchor.x, this.anchor.y)
	end
end

function MYDev_UIEditor.OnFrameDragEnd()
	this.anchor = GetFrameAnchor(this)
end

function MYDev_UIEditor.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Select' then
		local menu = D.GetMeun(this:GetRoot())
		local handle = this:Lookup('', '')
		local nX, nY = handle:GetAbsPos()
		local nW, nH = handle:GetSize()
		menu.nMiniWidth = handle:GetW()
		menu.x = nX
		menu.y = nY + nH
		PopupMenu(menu)
	elseif name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	end
end

function MYDev_UIEditor.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		if name == 'TreeLeaf_Node' then
			if this:IsExpand() then
				this:Collapse()
			else
				this:Expand()
			end
			this:GetParent():FormatAllItemPos()
		end
		local el = this.dat.___id
		if el and el:IsValid() then
			local frame = this:GetRoot()
			local edit = frame:Lookup('Edit_Log/Edit_Default')
			edit:SetText(GetPureText(concat(D.GetTipInfo(el))))
			edit:SetCaretPos(0)
			local elSel, tElSel = el, {}
			while elSel do
				tElSel[elSel] = true
				elSel = elSel:GetParent()
			end
			frame.tElSel = tElSel
		end
	end
end

function MYDev_UIEditor.OnItemMouseEnter()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		local el = this.dat.___id
		if el and el:IsValid() then
			local szXml = concat(D.GetTipInfo(el))
			local x, y = Cursor.GetPos()
			local w, h = 40, 40
			OutputTip(szXml, 435, { x, y, w, h }, ALW.RIGHT_LEFT):StartMoving()
			return D.SetUIPos(frame, el)
		end
	end
end
-- ReloadUIAddon()
function MYDev_UIEditor.OnItemMouseLeave()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		HideTip()
		return D.SetUIPos(frame)
	end
end

function D.SetUIPos(frame, el)
	local hUIPos = frame.hUIPos
	if el and el:IsValid() then
		local x, y = el:GetAbsPos()
		local w, h = el:GetSize()
		hUIPos:SetSize(w, h)
		hUIPos:SetAbsPos(x, y)
		hUIPos:Show()
		if el:IsVisible() then
			hUIPos:SetFrame(157)
		else
			hUIPos:SetFrame(158)
		end
	else
		hUIPos:Hide()
	end
end

function D.GetTipInfo(el)
	local xml = {
		GetFormatText('[' .. el:GetName() .. ']\n', 65)
	}
	insert(xml, GetFormatText('Type: ', 67))
	insert(xml, GetFormatText(el:GetType() .. '\n', 44))
	insert(xml, GetFormatText('Visible: ', 67))
	insert(xml, GetFormatText(tostring(el:IsVisible()) .. '\n', 44))
	insert(xml, GetFormatText('Size: ', 67))
	insert(xml, GetFormatText(table.concat({ el:GetSize() }, ', ') .. '\n', 44))
	insert(xml, GetFormatText('RelPos: ', 67))
	insert(xml, GetFormatText(table.concat({ el:GetRelPos() }, ', ') .. '\n', 44))
	insert(xml, GetFormatText('AbsPos: ', 67))
	insert(xml, GetFormatText(table.concat({ el:GetAbsPos() }, ', ') .. '\n', 44))
	local szPath1, szPath2 = el:GetTreePath()
	insert(xml, GetFormatText('Path1: ', 67))
	insert(xml, GetFormatText(szPath1 .. '\n', 44))
	if szPath2 then
		insert(xml, GetFormatText('Path2: ', 67))
		insert(xml, GetFormatText(szPath2 .. '\n', 44))
	end
	insert(xml, GetFormatText('\n ---------- D Table --------- \n\n', 67))
	for k, v in pairs(el) do
		insert(xml, GetFormatText(k .. ': ', 67))
		insert(xml, GetFormatText(tostring(v) .. '\n', 44))
	end
	if el:GetType() == 'WndFrame' then
		local G
		if el:IsAddOn() then
			G = GetAddonEnv and GetAddonEnv() or _G
		else
			G = _G
		end
		if G and G[el:GetName()] then
			insert(xml, GetFormatText('\n ---------- D Global --------- \n\n', 67))
			for k, v in pairs(G[el:GetName()]) do
				insert(xml, GetFormatText(k .. ': ', 67))
				insert(xml, GetFormatText(tostring(v) .. '\n', 44))
				if debug and type(v) == 'function' then
					local d = debug.getinfo(v)
					local t = {}
					for g, v in pairs(d) do
						t[g] = v;
					end
					t.func = nil
					insert(xml, GetFormatText(EncodeLUAData(t, '\t') .. '\n', 44))
				end
			end
		end
	end
	return xml
end

do
local nIndex = 0
function D.CreateFrame()
	nIndex = nIndex + 1
	return Wnd.OpenWindow(UI_INIFILE, 'MYDev_UIEditor#' .. nIndex)
end
end

function D.GetMeun(frame)
	local menu = {}
	for k, v in ipairs({ 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' })do
		insert(menu, { szOption = v })
		local frmIter = Station.Lookup(v):GetFirstChild()
		while frmIter do
			local el = frmIter
			insert(menu[#menu], {
				szOption = frmIter:GetName(),
				bCheck   = true,
				bChecked = frmIter:IsVisible(),
				rgb      = frmIter:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
				fnAction = function()
					D.UpdateTree(frame, el)
					frame:Lookup('Btn_Select', 'Text_Select'):SetText(el:GetTreePath())
					Wnd.CloseWindow(GetPopupMenu())
				end,
				fnMouseLeave = function()
					return D.SetUIPos(frame)
				end,
				fnMouseEnter = function()
					return D.SetUIPos(frame, el)
				end,
			})
			frmIter = frmIter:GetNext()
		end
	end
	return menu
end

do
local function AppendTree(handle, tpls, data, i)
	for k, v in ipairs(data) do
		local h
		if v.aChild then
			h = handle:AppendItemFromData(tpls.hNode)
		else
			h = handle:AppendItemFromData(tpls.hContent)
		end
		local txt = h:Lookup(0)
		txt:SetText(v.szName)
		h:SetIndent(i)
		h:FormatAllItemPos()
		h.dat = v
		if v.aChild then
			AppendTree(handle, tpls, v.aChild, i + 1)
		end
	end
end
function D.UpdateTree(frame, elRoot, bDropSel)
	if not elRoot then
		elRoot = frame.elRoot
	end
	local data   = GetUIStru(elRoot)
	local handle = frame.hList
	frame.elRoot = elRoot
	handle:Clear()
	AppendTree(handle, frame, data, 0)
	-- »Ö¸´Õ¹¿ª×´Ì¬
	local el, tElSel = nil, frame.tElSel or {}
	for i = 0, handle:GetItemCount() - 1 do
		el = handle:Lookup(i)
		if (not bDropSel and el.dat and el.dat.___id and tElSel[el.dat.___id]) or i == 0 then
			el:Expand()
		end
	end
	handle:FormatAllItemPos()
end
end

TraceButton_AppendAddonMenu({{ szOption = _L['MYDev_UIEditor'], fnAction = D.CreateFrame }})
