--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 查询界面类
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local ipairs_r = LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local XML_LINE_BREAKER = XML_LINE_BREAKER

local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_ChatLog/lang/')
if not LIB.AssertVersion('MY_ChatLog', _L['MY_ChatLog'], 0x2011800) then
	return
end
local D = {}

MY_ChatLog_UI = class()

------------------------------------------------------------------------------------------------------
-- 数据库核心
------------------------------------------------------------------------------------------------------
local SZ_INI = LIB.GetAddonInfo().szRoot .. 'MY_ChatLog/ui/MY_ChatLog.ini'
local PAGE_AMOUNT = 150
local PAGE_DISPLAY = 14
local LOG_TYPE = MY_ChatLog.LOG_TYPE
local MSGTYPE_COLOR = MY_ChatLog.MSGTYPE_COLOR

function D.SetDS(frame, szRoot)
	frame.ds = MY_ChatLog_DS(szRoot)
	D.UpdatePage(frame)
end

function MY_ChatLog_UI.OnFrameCreate()
	if type(MY_ChatLog.tUncheckedChannel) ~= 'table' then
		MY_ChatLog.tUncheckedChannel = {}
	end
	this.tUncheckedChannel = Clone(MY_ChatLog.tUncheckedChannel)
	local container = this:Lookup('Window_Main/WndScroll_ChatChanel/WndContainer_ChatChanel')
	container:Clear()
	for _, info in pairs(LOG_TYPE) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_ChatChannel')
		wnd.id = info.id
		wnd.aChannels = info.channels
		wnd:Lookup('CheckBox_ChatChannel'):Check(not this.tUncheckedChannel[info.id], WNDEVENT_FIRETYPE.PREVENT)
		wnd:Lookup('CheckBox_ChatChannel', 'Text_ChatChannel'):SetText(info.title)
		wnd:Lookup('CheckBox_ChatChannel', 'Text_ChatChannel'):SetFontColor(unpack(MSGTYPE_COLOR[info.channels[1]]))
	end
	container:FormatAllContentPos()

	local handle = this:Lookup('Window_Main/Wnd_Index', 'Handle_IndexesOuter/Handle_Indexes')
	handle:Clear()
	for i = 1, PAGE_DISPLAY do
		handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
	end
	handle:FormatAllItemPos()

	local handle = this:Lookup('Window_Main/WndScroll_ChatLog', 'Handle_ChatLogs')
	handle:Clear()
	for i = 1, PAGE_AMOUNT do
		handle:AppendItemFromIni(SZ_INI, 'Handle_ChatLog')
	end
	handle:FormatAllItemPos()

	this:Lookup('', 'Text_Title'):SetText(_L['MY - MY_ChatLog'])
	this:Lookup('Window_Main/Wnd_Search/Edit_Search'):SetPlaceholderText(_L['Press enter to search ...'])

	this:RegisterEvent('ON_MY_MOSAICS_RESET')
	this:RegisterEvent('ON_MY_CHATLOG_INSERT_MSG')

	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:BringToTop()
	this.SetDS = D.SetDS
end

function MY_ChatLog_UI.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdatePage(this, true)
	elseif event == 'ON_MY_CHATLOG_INSERT_MSG' then
		D.UpdatePage(this, true)
	end
end

function MY_ChatLog_UI.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Only' then
		local wnd = this:GetParent()
		local parent = wnd:GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_ChatChannel'):Check(false, WNDEVENT_FIRETYPE.PREVENT)
		end
		wnd:Lookup('CheckBox_ChatChannel'):Check(true)
	elseif name == 'Btn_ChatChannelAll' then
		local parent = this:GetParent():Lookup('WndScroll_ChatChanel/WndContainer_ChatChanel')
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_ChatChannel'):Check(true, WNDEVENT_FIRETYPE.PREVENT)
		end
		this:GetRoot().nCurrentPage = nil
		this:GetRoot().nLastClickIndex = nil
		D.UpdatePage(this:GetRoot())
	end
end

function MY_ChatLog_UI.OnCheckBoxCheck()
	this:GetRoot().nCurrentPage = nil
	this:GetRoot().nLastClickIndex = nil
	D.UpdatePage(this:GetRoot())
end

function MY_ChatLog_UI.OnCheckBoxUncheck()
	this:GetRoot().nCurrentPage = nil
	this:GetRoot().nLastClickIndex = nil
	D.UpdatePage(this:GetRoot())
end

function MY_ChatLog_UI.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Index' then
		this:GetRoot().nCurrentPage = this.nPage
		D.UpdatePage(this:GetRoot())
	elseif name == 'Handle_ChatLog' then
		local nLastClickIndex = this:GetRoot().nLastClickIndex
		if IsCtrlKeyDown() then
			this:Lookup('Shadow_ChatLogSelect'):SetVisible(not this:Lookup('Shadow_ChatLogSelect'):IsVisible())
		elseif IsShiftKeyDown() then
			if nLastClickIndex then
				local hList, hItem = this:GetParent()
				for i = nLastClickIndex, this:GetIndex(), (nLastClickIndex - this:GetIndex() > 0 and -1 or 1) do
					hItem = hList:Lookup(i)
					if hItem:IsVisible() then
						hItem:Lookup('Shadow_ChatLogSelect'):Show()
					end
				end
			end
		else
			local hList, hItem = this:GetParent()
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if hItem:IsVisible() then
					hItem:Lookup('Shadow_ChatLogSelect'):Hide()
				end
			end
			this:Lookup('Shadow_ChatLogSelect'):Show()
		end
		this:GetRoot().nLastClickIndex = this:GetIndex()
	end
end

function MY_ChatLog_UI.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'WndEdit_Index' then
			frame.nCurrentPage = tonumber(this:GetText()) or frame.nCurrentPage
		end
		D.UpdatePage(this:GetRoot())
		return 1
	end
end

function MY_ChatLog_UI.OnItemRButtonClick()
	local this = this
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Handle_ChatLog' then
		local nLastClickIndex = this:GetRoot().nLastClickIndex
		if IsCtrlKeyDown() then
			this:Lookup('Shadow_ChatLogSelect'):SetVisible(not this:Lookup('Shadow_ChatLogSelect'):IsVisible())
		elseif IsShiftKeyDown() then
			if nLastClickIndex then
				local hList, hItem = this:GetParent()
				for i = nLastClickIndex, this:GetIndex(), (nLastClickIndex - this:GetIndex() > 0 and -1 or 1) do
					hItem = hList:Lookup(i)
					if hItem:IsVisible() then
						hItem:Lookup('Shadow_ChatLogSelect'):Show()
					end
				end
			end
		elseif not this:Lookup('Shadow_ChatLogSelect'):IsVisible() then
			local hList, hItem = this:GetParent()
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if hItem:IsVisible() then
					hItem:Lookup('Shadow_ChatLogSelect'):Hide()
				end
			end
			this:Lookup('Shadow_ChatLogSelect'):Show()
		end
		this:GetRoot().nLastClickIndex = this:GetIndex()

		local menu = {
			{
				szOption = _L['Delete record'],
				fnAction = function()
					local hList, hItem = this:GetParent()
					for i = 0, hList:GetItemCount() - 1 do
						hItem = hList:Lookup(i)
						if hItem:IsVisible() and hItem:Lookup('Shadow_ChatLogSelect'):IsVisible() then
							frame.ds:DeleteMsg(hItem.hash, hItem.time)
						end
					end
					this:GetRoot().nLastClickIndex = nil
					D.UpdatePage(this:GetRoot(), true)
				end,
			}, {
				szOption = _L['Copy this record'],
				fnAction = function()
					LIB.CopyChatLine(this:Lookup('Handle_ChatLog_Msg'):Lookup(0), true)
				end,
			}
		}
		PopupMenu(menu)
	end
end

function D.UpdatePage(frame, bKeepScroll)
	local container = frame:Lookup('Window_Main/WndScroll_ChatChanel/WndContainer_ChatChanel')
	local aChannel = {}
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup('CheckBox_ChatChannel'):IsCheckBoxChecked() then
			for _, szChannel in ipairs(wnd.aChannels) do
				insert(aChannel, szChannel)
			end
			frame.tUncheckedChannel[wnd.id] = nil
		else
			frame.tUncheckedChannel[wnd.id] = true
		end
	end
	local szSearch = frame:Lookup('Window_Main/Wnd_Search/Edit_Search'):GetText()
	local nCount = frame.ds:CountMsg(aChannel, szSearch)
	local nPageCount = ceil(nCount / PAGE_AMOUNT)
	local bInit = not frame.nCurrentPage
	local nCurrentPage = bInit and nPageCount or min(max(frame.nCurrentPage, 1), nPageCount)
	frame:Lookup('Window_Main/Wnd_Index/Wnd_IndexEdit/WndEdit_Index'):SetText(nCurrentPage)
	frame:Lookup('Window_Main/Wnd_Index', 'Handle_IndexCount/Text_IndexCount'):SprintfText(_L['Total %d pages'], nPageCount)

	local hOuter = frame:Lookup('Window_Main/Wnd_Index', 'Handle_IndexesOuter')
	local handle = hOuter:Lookup('Handle_Indexes')
	if nPageCount <= PAGE_DISPLAY then
		for i = 0, PAGE_DISPLAY - 1 do
			local hItem = handle:Lookup(i)
			hItem.nPage = i + 1
			hItem:Lookup('Text_Index'):SetText(i + 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(i + 1 == nCurrentPage)
			hItem:SetVisible(i < nPageCount)
		end
	else
		local hItem = handle:Lookup(0)
		hItem.nPage = 1
		hItem:Lookup('Text_Index'):SetText(1)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(1 == nCurrentPage)
		hItem:Show()

		local hItem = handle:Lookup(PAGE_DISPLAY - 1)
		hItem.nPage = nPageCount
		hItem:Lookup('Text_Index'):SetText(nPageCount)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(nPageCount == nCurrentPage)
		hItem:Show()

		local nStartPage
		if nCurrentPage + ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2)
		end
		for i = 1, PAGE_DISPLAY - 2 do
			local hItem = handle:Lookup(i)
			hItem.nPage = nStartPage + i - 1
			hItem:Lookup('Text_Index'):SetText(nStartPage + i - 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(nStartPage + i - 1 == nCurrentPage)
			hItem:SetVisible(true)
		end
	end
	handle:SetSize(hOuter:GetSize())
	handle:FormatAllItemPos()
	handle:SetSizeByAllItemSize()
	hOuter:FormatAllItemPos()

	local data = frame.ds:SelectMsg(aChannel, szSearch, (nCurrentPage - 1) * PAGE_AMOUNT, PAGE_AMOUNT)
	local scroll = frame:Lookup('Window_Main/WndScroll_ChatLog/Scroll_ChatLog')
	local bScrollBottom = scroll:GetScrollPos() == scroll:GetStepCount()
	local handle = frame:Lookup('Window_Main/WndScroll_ChatLog', 'Handle_ChatLogs')
	for i = 1, PAGE_AMOUNT do
		local rec = data[i]
		local hItem = handle:Lookup(i - 1)
		if rec then
			local f = GetMsgFont(rec.szChannel)
			local r, g, b = unpack(MSGTYPE_COLOR[rec.szChannel])
			local h = hItem:Lookup('Handle_ChatLog_Msg')
			h:Clear()
			h:AppendItemFromString(LIB.GetTimeLinkText({r=r, g=g, b=b, f=f, s='[yyyy/MM/dd][hh:mm:ss]'}, rec.nTime))
			local nCount = h:GetItemCount()
			h:AppendItemFromString(rec.szMsg)
			for i = nCount, h:GetItemCount() - 1 do
				LIB.RenderChatLink(h:Lookup(i))
			end
			if MY_Farbnamen and MY_Farbnamen.Render then
				for i = nCount, h:GetItemCount() - 1 do
					MY_Farbnamen.Render(h:Lookup(i))
				end
			end
			if MY_ChatMosaics and MY_ChatMosaics.Mosaics then
				MY_ChatMosaics.Mosaics(h)
			end
			local last = h:Lookup(h:GetItemCount() - 1)
			if last and last:GetType() == 'Text' and last:GetText():sub(-1) == '\n' then
				last:SetText(last:GetText():sub(0, -2))
			end
			h:FormatAllItemPos()
			local nW, nH = h:GetAllItemSize()
			h:SetH(nH)
			hItem:Lookup('Shadow_ChatLogHover'):SetH(nH + 3)
			hItem:Lookup('Shadow_ChatLogSelect'):SetH(nH + 3)
			hItem:SetH(nH + 3)
			hItem.hash = rec.szHash
			hItem.time = rec.nTime
			hItem.text = rec.szText
			if not frame.nLastClickIndex then
				hItem:Lookup('Shadow_ChatLogSelect'):Hide()
			end
			hItem:Show()
		else
			hItem:Hide()
		end
	end
	handle:FormatAllItemPos()

	if bKeepScroll then
		if bScrollBottom then
			scroll:SetScrollPos(scroll:GetStepCount())
		end
	else
		scroll:SetScrollPos(bInit and scroll:GetStepCount() or 0)
	end
	MY_ChatLog.tUncheckedChannel = Clone(frame.tUncheckedChannel)
end


do
local nIndex = 0
function MY_ChatLog_Open(szRoot)
	nIndex = nIndex + 1
	Wnd.OpenWindow(SZ_INI, 'MY_ChatLog#' .. nIndex):SetDS(szRoot)
end
end
