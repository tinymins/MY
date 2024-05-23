--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 查询界面类
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_UI'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.3') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}

------------------------------------------------------------------------------------------------------
-- 数据库核心
------------------------------------------------------------------------------------------------------
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_ChatLog/ui/MY_ChatLog.ini'
local PAGE_AMOUNT = 150
local MSG_TYPE_COLOR = MY_ChatLog.MSG_TYPE_COLOR

function D.SetDS(hFrame, szRoot)
	hFrame.ds = MY_ChatLog_DS(szRoot)
	D.UpdatePage(hFrame)
end

function D.OnFrameCreate()
	local hFrameTemp = X.UI.OpenFrame(SZ_INI, 'MY_ChatLog_UI_Temp')
	local hWndMain = hFrameTemp:Lookup('Wnd_Main')
	hWndMain:ChangeRelation(this:Lookup('Wnd_Total'), true, true)
	hWndMain:SetRelPos(20, 55)
	X.UI.CloseFrame(hFrameTemp)

	this.tUncheckedChannel = X.Clone(MY_ChatLog.tUncheckedChannel)
	local container = this:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel/WndContainer_ChatChanel')
	container:Clear()
	for _, info in pairs(MY_ChatLog.aChannel) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_ChatChannel')
		wnd.szKey = info.szKey
		wnd.aMsgType = info.aMsgType
		wnd:Lookup('CheckBox_ChatChannel'):Check(not this.tUncheckedChannel[info.szKey], WNDEVENT_FIRETYPE.PREVENT)
		wnd:Lookup('CheckBox_ChatChannel', 'Text_ChatChannel'):SetText(info.szTitle)
		wnd:Lookup('CheckBox_ChatChannel', 'Text_ChatChannel'):SetFontColor(unpack(MSG_TYPE_COLOR[info.aMsgType[1]]))
	end
	container:FormatAllContentPos()

	local handle = this:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog', 'Handle_ChatLogs')
	handle:Clear()
	for i = 1, PAGE_AMOUNT do
		handle:AppendItemFromIni(SZ_INI, 'Handle_ChatLog')
	end
	handle:FormatAllItemPos()

	this:Lookup('Wnd_Total/Wnd_Main/Wnd_Search/Edit_Search'):SetPlaceholderText(_L['Press enter to search ...'])

	this:RegisterEvent('ON_MY_MOSAICS_RESET')
	this:RegisterEvent('ON_MY_CHATLOG_INSERT_MSG')
	this:RegisterEvent('ON_MY_CHAT_LOG_RELEASE_DB')
	this:RegisterEvent('ON_MY_CHAT_LOG_CHANNEL_CHANGE')

	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:BringToTop()

	MY_ChatLog.MigrateDB()
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdatePage(this, true)
	elseif event == 'ON_MY_CHATLOG_INSERT_MSG' then
		D.UpdatePage(this, true)
	elseif event == 'ON_MY_CHAT_LOG_RELEASE_DB' then
		this:Destroy()
	elseif event == 'ON_MY_CHAT_LOG_CHANNEL_CHANGE' then
		this:Destroy()
	end
end

function D.OnMouseIn()
	local name = this:GetName()
	if name == 'Wnd_ChatChannel' then
		local szText = ''
		for _, szMsgType in ipairs(this.aMsgType) do
			local szMsgTypeName = g_tStrings.tChannelName[szMsgType]
			if IsCtrlKeyDown() then
				szMsgTypeName = (szMsgTypeName or '') .. '(' .. szMsgType .. ')'
			end
			if szMsgTypeName then
				szText = szText .. GetFormatText(szMsgTypeName .. '\n', 162, GetMsgFontColor(szMsgType))
			end
		end
		X.OutputTip(this, szText, true, X.UI.TIP_POSITION.LEFT_RIGHT)
	end
end

function D.OnMouseOut()
	local name = this:GetName()
	if name == 'Wnd_ChatChannel' then
		X.HideTip()
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		X.UI.CloseFrame(this:GetRoot())
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

function D.OnCheckBoxCheck()
	this:GetRoot().nCurrentPage = nil
	this:GetRoot().nLastClickIndex = nil
	D.UpdatePage(this:GetRoot())
end

function D.OnCheckBoxUncheck()
	this:GetRoot().nCurrentPage = nil
	this:GetRoot().nLastClickIndex = nil
	D.UpdatePage(this:GetRoot())
end

function D.OnItemMouseIn()
	local name = this:GetName()
	if name == 'Handle_ChatLog' then
		if IsCtrlKeyDown() and g_tStrings.tChannelName[this.szMsgType] then
			local szXml = GetFormatText(g_tStrings.tChannelName[this.szMsgType] .. ' (' .. this.szMsgType .. ')', 162, GetMsgFontColor(this.szMsgType))
			X.OutputTip( this, szXml, true)
		end
	end
end

function D.OnItemMouseOut()
	local name = this:GetName()
	if name == 'Handle_ChatLog' then
		X.HideTip()
	end
end

function D.OnItemLButtonClick()
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

function D.OnEditSpecialKeyDown()
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

function D.OnItemRButtonClick()
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
					frame.ds:FlushDB()
					this:GetRoot().nLastClickIndex = nil
					D.UpdatePage(this:GetRoot(), true)
				end,
			},
			{
				szOption = _L['Copy this record'],
				fnAction = function()
					X.CopyChatLine(this:Lookup('Handle_ChatLog_Msg'):Lookup(0), true)
				end,
			},
		}
		PopupMenu(menu)
	end
end

function D.UpdatePage(hFrame, bKeepScroll)
	-- 更新大小
	local nW, nH = hFrame:GetW() - 40, hFrame:GetH() - 75
	hFrame:Lookup('Wnd_Total/Wnd_Main'):SetSize(nW, nH)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel'):SetH(nH - 25)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel', ''):SetH(nH - 25)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel', 'Image_ChatChanel'):SetH(nH - 25)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel/WndContainer_ChatChanel'):SetH(nH - 60)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel/Scroll_ChatChanel'):SetH(nH - 25)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog'):SetSize(nW - 200, nH - 30)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog', ''):SetSize(nW - 215, nH - 30)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog', 'Image_ChatLog'):SetSize(nW - 215, nH - 30)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog', 'Handle_ChatLogs'):SetSize(nW - 215, nH - 40)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog/Scroll_ChatLog'):SetRelX(nW - 215)
	hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog/Scroll_ChatLog'):SetH(nH - 30)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index'):SetRelY(nH - 25)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index'):SetW(nW - 215)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index', ''):SetW(nW - 215)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index', 'Image_Index'):SetW(nW - 215)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index', 'Handle_IndexesOuter'):SetW(nW - 360)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index/Wnd_IndexEdit'):SetRelX(nW - 270)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Btn_ChatChannelAll'):SetRelY(nH - 27)
	-- 重新渲染
	local container = hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatChanel/WndContainer_ChatChanel')
	local aMsgType = {}
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup('CheckBox_ChatChannel'):IsCheckBoxChecked() then
			for _, szMsgType in ipairs(wnd.aMsgType) do
				table.insert(aMsgType, szMsgType)
			end
			hFrame.tUncheckedChannel[wnd.szKey] = nil
		else
			hFrame.tUncheckedChannel[wnd.szKey] = true
		end
	end
	local szSearch = hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Search/Edit_Search'):GetText()
	local nCount = hFrame.ds:CountMsg(aMsgType, szSearch)
	local nPageCount = math.ceil(nCount / PAGE_AMOUNT)
	local bInit = not hFrame.nCurrentPage
	local nCurrentPage = bInit and nPageCount or math.min(math.max(hFrame.nCurrentPage, 1), nPageCount)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index/Wnd_IndexEdit/WndEdit_Index'):SetText(nCurrentPage)
	hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index', 'Handle_IndexCount/Text_IndexCount'):SprintfText(_L['Total %d pages'], nPageCount)

	local hOuter = hFrame:Lookup('Wnd_Total/Wnd_Main/Wnd_Index', 'Handle_IndexesOuter')
	local handle = hOuter:Lookup('Handle_Indexes')
	local PAGE_DISPLAY = math.floor((hOuter:GetW() - 10) / 48)
	handle:Clear()
	for i = 1, PAGE_DISPLAY do
		handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
	end
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
		if nCurrentPage + math.ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif nCurrentPage - math.ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = nCurrentPage - math.ceil((PAGE_DISPLAY - 2) / 2)
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

	local data = hFrame.ds:SelectMsg(aMsgType, szSearch, nil, nil, (nCurrentPage - 1) * PAGE_AMOUNT, PAGE_AMOUNT)
	local scroll = hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog/Scroll_ChatLog')
	local bScrollBottom = scroll:GetScrollPos() == scroll:GetStepCount()
	local handle = hFrame:Lookup('Wnd_Total/Wnd_Main/WndScroll_ChatLog', 'Handle_ChatLogs')
	for i = 1, PAGE_AMOUNT do
		local rec = data[i]
		local hItem = handle:Lookup(i - 1)
		if rec then
			hItem:SetW(nW - 215)
			hItem:Lookup('Shadow_ChatLogHover'):SetW(nW - 215)
			hItem:Lookup('Shadow_ChatLogSelect'):SetW(nW - 215)
			hItem:Lookup('Handle_ChatLog_Msg'):SetW(nW - 215)
			local f = GetMsgFont(rec.szMsgType)
			local r, g, b = unpack(MSG_TYPE_COLOR[rec.szMsgType])
			local h = hItem:Lookup('Handle_ChatLog_Msg')
			h:Clear()
			h:AppendItemFromString(X.GetChatTimeXML(rec.nTime, {
				r = r, g = g, b = b, f = f,
				s = '[%yyyy/%MM/%dd][%hh:%mm:%ss]', richtext = rec.szMsg,
			}))
			local nCount = h:GetItemCount()
			local szMsg = rec.szMsg
			if MY_ChatEmotion and MY_ChatEmotion.Render then
				szMsg = MY_ChatEmotion.Render(szMsg)
			end
			h:AppendItemFromString(szMsg)
			for i = nCount, h:GetItemCount() - 1 do
				X.RenderChatLink(h:Lookup(i))
			end
			if MY_Farbnamen and MY_Farbnamen.Render then
				MY_Farbnamen.Render(h, { nStartIndex = nCount })
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
			hItem.text = rec.szText --TODO
			hItem.szMsgType = rec.szMsgType
			if not hFrame.nLastClickIndex then
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
	MY_ChatLog.tUncheckedChannel = X.Clone(hFrame.tUncheckedChannel)
end

function D.Open(szRoot)
	if not MY_ChatLog.InitDB() then
		return
	end
	-- 创建窗体
	local hFrame = X.UI.CreateFrame('MY_ChatLog_UI', {
		w = 1000, h = 700,
		close = true,
		maximize = true,
		resize = true,
		minWidth = 1000,
		minHeight = 700,
		text = _L['MY - MY_ChatLog'],
		anchor = 'CENTER',
		onSizeChange = function()
			D.UpdatePage(this)
		end,
	}):Raw()
	-- 更新窗体数据
	local nIndex = 0
	while Station.Lookup('Normal/MY_ChatLog_UI#' .. nIndex) do
		nIndex = nIndex + 1
	end
	hFrame:SetName('MY_ChatLog_UI#' .. nIndex)
	D.SetDS(hFrame, szRoot)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatLog_UI',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'Open',
			},
			root = D,
		},
	},
}
MY_ChatLog_UI = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
