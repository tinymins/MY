--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : UI查看器
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MYDev_UIManager/lang/')
if not LIB.AssertVersion('MYDev_UIManager', _L['MYDev_UIEditor'], 0x2011800) then
	return
end

-- stack overflow
local function GetUIStru(ui)
	local data = {}
	local function GetInfo(ui)
		local szType = ui:GetType()
		local szName = ui:GetName()
		local bIsWnd = szType:sub(1, 3) == 'Wnd'
		local bChild, hChildItem
		if bIsWnd then
			bChild     = ui:GetFirstChild() ~= nil
			hChildItem = ui:Lookup('', '')
		elseif szType == 'Handle' or szType == 'TreeLeaf' then
			bChild = ui:Lookup(0) ~= nil
		end
		local dat = {
			___id  = ui, -- ui metatable
			aPath  = { ui:GetTreePath() },
			szType = szType,
			szName = szName,
			aChild = (bChild or hChildItem) and {} or nil
		}
		return dat, bIsWnd, bChild, hChildItem
	end
	local function GetItemStru(ui, tab)
		local dat, bIsWnd, bChild = GetInfo(ui)
		insert(tab, dat)
		if bChild then
			local i = 0
			while ui:Lookup(i) do
				local frame = ui:Lookup(i)
				GetItemStru(frame, dat.aChild)
				i = i + 1
			end
		end
	end
	local function GetWinStru(ui, tab)
		local dat, bIsWnd, bChild, hChildItem = GetInfo(ui)
		insert(tab, dat)
		if hChildItem then
			GetItemStru(hChildItem, dat.aChild)
		end
		if bChild then
			local aChild = tab[#tab]
			local frame = ui:GetFirstChild()
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
	local dat, bIsWnd, bChild = GetInfo(ui)
	if bIsWnd then
		GetWinStru(ui, data)
	else
		GetItemStru(ui, data)
	end
	return data
end

local UI_INIFILE = LIB.GetAddonInfo().szRoot .. 'MYDev_UIManager/ui/MYDev_UIEditor.ini'
local UI_ANCHOR  = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
local D = {}
MYDev_UIEditor = {}

function MYDev_UIEditor.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this.hNode    = this:CreateItemData(UI_INIFILE, 'TreeLeaf_Node')
	this.hContent = this:CreateItemData(UI_INIFILE, 'TreeLeaf_Content')
	this.hList    = this:Lookup('WndScroll_Tree', '')
	this.hUIPos   = this:Lookup('', 'Image_UIPos')
	this.hList:Clear()
	this:ShowWhenUIHide()
	local a = UI_ANCHOR
	this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
end

-- function MYDev_UIEditor.OnFrameBreathe()
-- 	this:BringToTop()
-- end

function MYDev_UIEditor.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		local a = UI_ANCHOR
		this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	end
end

function MYDev_UIEditor.OnFrameDragEnd()
	UI_ANCHOR = GetFrameAnchor(this)
end

function MYDev_UIEditor.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Select' then
		local menu = D.GetMeun()
		local handle = this:Lookup('', '')
		local nX, nY = handle:GetAbsPos()
		local nW, nH = handle:GetSize()
		menu.nMiniWidth = handle:GetW()
		menu.x = nX
		menu.y = nY + nH
		PopupMenu(menu)
	elseif szName == 'Btn_Close' then
		D.CloseFrame()
	end
end

function MYDev_UIEditor.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'TreeLeaf_Node' or szName == 'TreeLeaf_Content' then
		if szName == 'TreeLeaf_Node' then
			if this:IsExpand() then
				this:Collapse()
			else
				this:Expand()
			end
			this:GetParent():FormatAllItemPos()
		end
		local ui = this.dat.___id
		if ui and ui:IsValid() then
			local frame = D.GetFrame()
			local edit = frame:Lookup('Edit_Log/Edit_Default')
			edit:SetText(GetPureText(table.concat(D.GetTipInfo(ui))))
			edit:SetCaretPos(0)
		end
	end
end

function MYDev_UIEditor.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == 'TreeLeaf_Node' or szName == 'TreeLeaf_Content' then
		local ui = this.dat.___id
		if ui and ui:IsValid() then
			local szXml = table.concat(D.GetTipInfo(ui))
			local x, y = Cursor.GetPos()
			local w, h = 40, 40
			local frame = OutputTip(szXml, 435, { x, y, w, h }, ALW.RIGHT_LEFT)
			frame:StartMoving()
			return D.SetUIPos(ui)
		end
	end
end
-- ReloadUIAddon()
function MYDev_UIEditor.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'TreeLeaf_Node' or szName == 'TreeLeaf_Content' then
		HideTip()
		return D.SetUIPos()
	end
end

function D.SetUIPos(ui)
	local frame = D.GetFrame()
	local hUIPos = frame.hUIPos
	if ui and ui:IsValid() then
		local x, y = ui:GetAbsPos()
		local w, h = ui:GetSize()
		hUIPos:SetSize(w, h)
		hUIPos:SetAbsPos(x, y)
		hUIPos:Show()
		if ui:IsVisible() then
			hUIPos:SetFrame(157)
		else
			hUIPos:SetFrame(158)
		end
	else
		hUIPos:Hide()
	end
end

function D.GetTipInfo(ui)
	local xml = {
		GetFormatText('[' .. ui:GetName() .. ']\n', 65)
	}
	insert(xml, GetFormatText('Type: ', 67))
	insert(xml, GetFormatText(ui:GetType() .. '\n', 44))
	insert(xml, GetFormatText('Visible: ', 67))
	insert(xml, GetFormatText(tostring(ui:IsVisible()) .. '\n', 44))
	insert(xml, GetFormatText('Size: ', 67))
	insert(xml, GetFormatText(table.concat({ ui:GetSize() }, ', ') .. '\n', 44))
	insert(xml, GetFormatText('RelPos: ', 67))
	insert(xml, GetFormatText(table.concat({ ui:GetRelPos() }, ', ') .. '\n', 44))
	insert(xml, GetFormatText('AbsPos: ', 67))
	insert(xml, GetFormatText(table.concat({ ui:GetAbsPos() }, ', ') .. '\n', 44))
	local szPath1, szPath2 = ui:GetTreePath()
	insert(xml, GetFormatText('Path1: ', 67))
	insert(xml, GetFormatText(szPath1 .. '\n', 44))
	if szPath2 then
		insert(xml, GetFormatText('Path2: ', 67))
		insert(xml, GetFormatText(szPath2 .. '\n', 44))
	end
	insert(xml, GetFormatText('\n ---------- D Table --------- \n\n', 67))
	for k, v in pairs(ui) do
		insert(xml, GetFormatText(k .. ': ', 67))
		insert(xml, GetFormatText(tostring(v) .. '\n', 44))
	end
	if ui:GetType() == 'WndFrame' then
		local G
		if ui:IsAddOn() then
			G = GetAddonEnv and GetAddonEnv() or _G
		else
			G = _G
		end
		if G and G[ui:GetName()] then
			insert(xml, GetFormatText('\n ---------- D Global --------- \n\n', 67))
			for k, v in pairs(G[ui:GetName()]) do
				insert(xml, GetFormatText(k .. ': ', 67))
				insert(xml, GetFormatText(tostring(v) .. '\n', 44))
				if debug and type(v) == 'function' then
					local d = debug.getinfo(v)
					local t = {}
					for g, v in pairs(d) do
						t[g] = v;
					end
					t.func = nil
					insert(xml, GetFormatText(var2str(t, '\t') .. '\n', 44))
				end
			end
		end
	end
	return xml
end

function D.OpenFrame()
	return Wnd.OpenWindow(UI_INIFILE, 'MYDev_UIEditor')
end

function D.CloseFrame()
	return Wnd.CloseWindow('MYDev_UIEditor')
end

function D.GetFrame()
	return Station.Lookup('Topmost1/MYDev_UIEditor')
end
D.IsOpened = D.GetFrame
function D.ToggleFrame()
	if D.IsOpened() then
		D.CloseFrame()
	else
		D.OpenFrame()
	end
end

function D.GetMeun()
	local menu = {}
	for k, v in ipairs({ 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' })do
		insert(menu, { szOption = v })
		local frame = Station.Lookup(v):GetFirstChild()
		while frame do
			local ui = frame
			insert(menu[#menu], {
				szOption = frame:GetName(),
				bCheck   = true,
				bChecked = frame:IsVisible(),
				rgb      = frame:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
				fnAction = function()
					D.UpdateTree(ui)
					local frame = D.GetFrame()
					frame:Lookup('Btn_Select', 'Text_Select'):SetText(ui:GetTreePath())
					Wnd.CloseWindow(GetPopupMenu())
				end,
				fnMouseLeave = function()
					return D.SetUIPos()
				end,
				fnMouseEnter = function()
					return D.SetUIPos(ui)
				end,
			})
			frame = frame:GetNext()
		end
	end
	return menu
end

function D.UpdateTree(ui)
	local data   = GetUIStru(ui)
	local frame  = D.GetFrame()
	local handle = frame.hList
	handle:Clear()
	local nIndent = 0
	local function AppendTree(data, i)
		for k, v in ipairs(data) do
			local h
			if v.aChild then
				h = handle:AppendItemFromData(frame.hNode)
			else
				h = handle:AppendItemFromData(frame.hContent)
			end
			local txt = h:Lookup(0)
			txt:SetText(v.szName)
			h:SetIndent(i)
			h:FormatAllItemPos()
			h.dat = v
			if v.aChild then
				AppendTree(v.aChild, i + 1)
			end
		end
	end
	AppendTree(data, nIndent)
	handle:Lookup(0):Expand()
	handle:FormatAllItemPos()
end

TraceButton_AppendAddonMenu({{ szOption = _L['MYDev_UIEditor'], fnAction = D.ToggleFrame }})
