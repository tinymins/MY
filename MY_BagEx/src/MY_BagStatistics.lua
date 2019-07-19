--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背包统计
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
LIB.CreateDataRoot(PATH_TYPE.GLOBAL)

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_BagEx/lang/')
local DB = LIB.ConnectDatabase(_L['MY_BagStatistics'], {'userdata/bagstatistics.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L['MY_BagStatistics'])
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_BagEx/ui/MY_BagStatistics.ini'
local PAGE_DISPLAY = 8
local NORMAL_MODE_PAGE_SIZE = 50
local COMPACT_MODE_PAGE_SIZE = 200
DB:Execute('CREATE TABLE IF NOT EXISTS BagItems (ownerkey NVARCHAR(20), boxtype INTEGER, boxindex INTEGER, tabtype INTEGER, tabindex INTEGER, tabsubindex INTEGER, bagcount INTEGER, bankcount INTEGER, time INTEGER, PRIMARY KEY(ownerkey, boxtype, boxindex))')
DB:Execute('CREATE INDEX IF NOT EXISTS BagItems_tab_idx ON BagItems(tabtype, tabindex, tabsubindex)')
local DB_ItemsW = DB:Prepare('REPLACE INTO BagItems (ownerkey, boxtype, boxindex, tabtype, tabindex, tabsubindex, bagcount, bankcount, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_ItemsDL = DB:Prepare('DELETE FROM BagItems WHERE ownerkey = ? AND boxtype = ? AND boxindex >= ?')
local DB_ItemsDA = DB:Prepare('DELETE FROM BagItems WHERE ownerkey = ?')
DB:Execute('CREATE TABLE IF NOT EXISTS OwnerInfo (ownerkey NVARCHAR(20), ownername NVARCHAR(20), servername NVARCHAR(20), time INTEGER, PRIMARY KEY(ownerkey))')
DB:Execute('CREATE INDEX IF NOT EXISTS OwnerInfo_ownername_idx ON OwnerInfo(ownername)')
DB:Execute('CREATE INDEX IF NOT EXISTS OwnerInfo_servername_idx ON OwnerInfo(servername)')
local DB_OwnerInfoW = DB:Prepare('REPLACE INTO OwnerInfo (ownerkey, ownername, servername, time) VALUES (?, ?, ?, ?)')
local DB_OwnerInfoR = DB:Prepare('SELECT * FROM OwnerInfo WHERE ownername LIKE ? OR servername LIKE ? ORDER BY time DESC')
local DB_OwnerInfoD = DB:Prepare('DELETE FROM OwnerInfo WHERE ownerkey = ?')
DB:Execute('CREATE TABLE IF NOT EXISTS ItemInfo (tabtype INTEGER, tabindex INTEGER, tabsubindex INTEGER, name NVARCHAR(20), desc NVARCHAR(800), PRIMARY KEY(tabtype, tabindex, tabsubindex))')
DB:Execute('CREATE INDEX IF NOT EXISTS ItemInfo_name_idx ON ItemInfo(name)')
DB:Execute('CREATE INDEX IF NOT EXISTS ItemInfo_desc_idx ON ItemInfo(desc)')
local DB_ItemInfoW = DB:Prepare('REPLACE INTO ItemInfo (tabtype, tabindex, tabsubindex, name, desc) VALUES (?, ?, ?, ?, ?)')

MY_BagStatistics = {}
MY_BagStatistics.bCompactMode = false
MY_BagStatistics.tUncheckedNames = {}
RegisterCustomData('Global/MY_BagStatistics.bCompactMode')
RegisterCustomData('Global/MY_BagStatistics.tUncheckedNames')

local FlushDB
do
local GetItemText
do
local l_tItemText = {}
function GetItemText(KItem)
	if KItem then
		if GetItemTip then
			local nBookID = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
			local szKey = KItem.dwTabType .. ',' .. KItem.dwIndex .. ',' .. nBookID
			if not l_tItemText[szKey] then
				l_tItemText[szKey] = ''
				l_tItemText[szKey] = LIB.Xml.GetPureText(GetItemTip(KItem))
			end
			return l_tItemText[szKey]
		else
			return KItem.szName
		end
	else
		return ''
	end
end
end

local l_guildcache = {}
local function UpdateTongRepertoryPage()
	local nPage = arg0
	local offset = nPage * CONSTANT.INVENTORY_GUILD_PAGE_SIZE
	local boxtype = CONSTANT.INVENTORY_GUILD_BANK
	for boxindex = offset, offset + 7 * 14 - 1 do
		local tabtype, tabindex, tabsubindex, name, desc, count = -1, -1, -1, '', '', 0
		local KItem = GetPlayerItem(me, boxtype, boxindex)
		if KItem then
			tabtype = KItem.dwTabType
			tabindex = KItem.dwIndex
			name = KItem.szName
			desc = GetItemText(KItem)
			tabsubindex = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
			count = KItem.bCanStack and KItem.nStackNum or 1
		end
		l_guildcache[boxindex] = {boxtype = boxtype, boxindex = boxindex, tabtype = tabtype, tabindex = tabindex, tabsubindex = tabsubindex, name = name, desc = desc, count = count, time = GetCurrentTime()}
	end
end
LIB.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE.MY_BagStatistics', UpdateTongRepertoryPage)

function FlushDB()
	--[[#DEBUG BEGIN]]
	LIB.Debug({'Flushing to database...'}, 'MY_BagStatistics', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local me = GetClientPlayer()
	local time = GetCurrentTime()
	local ownerkey = AnsiToUTF8(me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName)
	local ownername = AnsiToUTF8(me.szName)
	local servername = AnsiToUTF8(LIB.GetRealServer(2))
	DB:Execute('BEGIN TRANSACTION')

	-- 背包
	for boxtype = INVENTORY_INDEX.PACKAGE, INVENTORY_INDEX.PACKAGE + 6 - 1 do
		local count = me.GetBoxSize(boxtype)
		for boxindex = 0, count - 1 do
			local KItem = GetPlayerItem(me, boxtype, boxindex)
			DB_ItemsW:ClearBindings()
			if KItem then
				DB_ItemInfoW:ClearBindings()
				DB_ItemInfoW:BindAll(KItem.dwTabType, KItem.dwIndex, KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1, AnsiToUTF8(KItem.szName), AnsiToUTF8(GetItemText(KItem)))
				DB_ItemInfoW:Execute()
				DB_ItemsW:BindAll(ownerkey, boxtype, boxindex, KItem.dwTabType, KItem.dwIndex, KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1, KItem.bCanStack and KItem.nStackNum or 1, 0, time)
			else
				DB_ItemsW:BindAll(ownerkey, boxtype, boxindex, -1, -1, -1, 0, 0, time)
			end
			DB_ItemsW:Execute()
		end
		DB_ItemsDL:ClearBindings()
		DB_ItemsDL:BindAll(ownerkey, boxtype, count)
		DB_ItemsDL:Execute()
	end
	DB_OwnerInfoW:ClearBindings()
	DB_OwnerInfoW:BindAll(ownerkey, ownername, servername, time)
	DB_OwnerInfoW:Execute()

	-- 仓库
	for boxtype = INVENTORY_INDEX.BANK, INVENTORY_INDEX.BANK + me.GetBankPackageCount() - 1 do
		local count = me.GetBoxSize(boxtype)
		for boxindex = 0, count - 1 do
			local KItem = GetPlayerItem(me, boxtype, boxindex)
			DB_ItemsW:ClearBindings()
			if KItem then
				DB_ItemInfoW:ClearBindings()
				DB_ItemInfoW:BindAll(KItem.dwTabType, KItem.dwIndex, KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1, AnsiToUTF8(KItem.szName), AnsiToUTF8(GetItemText(KItem)))
				DB_ItemInfoW:Execute()
				DB_ItemsW:BindAll(ownerkey, boxtype, boxindex, KItem.dwTabType, KItem.dwIndex, KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1, 0, KItem.bCanStack and KItem.nStackNum or 1, time)
			else
				DB_ItemsW:BindAll(ownerkey, boxtype, boxindex, -1, -1, -1, 0, 0, time)
			end
			DB_ItemsW:Execute()
		end
		DB_ItemsDL:ClearBindings()
		DB_ItemsDL:BindAll(ownerkey, boxtype, count)
		DB_ItemsDL:Execute()
	end

	-- 帮会仓库
	if not IsEmpty(l_guildcache) then
		local ownerkey = 'tong' .. me.dwTongID
		local ownername = AnsiToUTF8('[' .. LIB.GetTongName(me.dwTongID) .. ']')
		for _, info in pairs(l_guildcache) do
			DB_ItemInfoW:ClearBindings()
			DB_ItemInfoW:BindAll(info.tabtype, info.tabindex, info.tabsubindex, AnsiToUTF8(info.name), AnsiToUTF8(info.desc))
			DB_ItemInfoW:Execute()
			DB_ItemsW:ClearBindings()
			DB_ItemsW:BindAll(ownerkey, info.boxtype, info.boxindex, info.tabtype, info.tabindex, info.tabsubindex, 0, info.count, time)
			DB_ItemsW:Execute()
		end
		DB_OwnerInfoW:ClearBindings()
		DB_OwnerInfoW:BindAll(ownerkey, ownername, servername, time)
		DB_OwnerInfoW:Execute()
	end

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	LIB.Debug({'Flushing to database finished...'}, 'MY_BagStatistics', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterEvent('PLAYER_LEAVE_GAME.MY_BagStatistics', FlushDB)
end

function MY_BagStatistics.Open()
	Wnd.OpenWindow(SZ_INI, 'MY_BagStatistics')
end

function MY_BagStatistics.Close()
	Wnd.CloseWindow('MY_BagStatistics')
end

function MY_BagStatistics.IsOpened()
	return Station.Lookup('Normal/MY_BagStatistics')
end

function MY_BagStatistics.Toggle()
	if MY_BagStatistics.IsOpened() then
		MY_BagStatistics.Close()
	else
		MY_BagStatistics.Open()
	end
end

function MY_BagStatistics.UpdateNames(frame)
	local searchname = frame:Lookup('Window_Main/Wnd_SearchName/Edit_SearchName'):GetText()
	DB_OwnerInfoR:ClearBindings()
	DB_OwnerInfoR:BindAll(AnsiToUTF8('%' .. searchname .. '%'), AnsiToUTF8('%' .. searchname .. '%'))
	local result = DB_OwnerInfoR:GetAll()

	local container = frame:Lookup('Window_Main/WndScroll_Name/WndContainer_Name')
	container:Clear()
	for _, rec in ipairs(result) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_Name')
		wnd.ownerkey   = UTF8ToAnsi(rec.ownerkey)
		wnd.ownername  = UTF8ToAnsi(rec.ownername)
		wnd.servername = UTF8ToAnsi(rec.servername)
		wnd:Lookup('CheckBox_Name', 'Text_Name'):SetText(wnd.ownername .. ' (' .. wnd.servername .. ')')
		wnd:Lookup('CheckBox_Name'):Check(not MY_BagStatistics.tUncheckedNames[wnd.ownerkey], WNDEVENT_FIRETYPE.PREVENT)
	end
	container:FormatAllContentPos()
	frame.nCurrentPage = 1
	MY_BagStatistics.UpdateItems(frame)
end

function MY_BagStatistics.UpdateItems(frame)
	FlushDB()

	local searchitem = frame:Lookup('Window_Main/Wnd_SearchItem/Edit_SearchItem'):GetText():gsub('%s+', '%%')
	local sqlfrom = '(SELECT B.ownerkey, B.boxtype, B.boxindex, B.tabtype, B.tabindex, B.tabsubindex, B.bagcount, B.bankcount, B.time FROM BagItems AS B LEFT JOIN ItemInfo AS I ON B.tabtype = I.tabtype AND B.tabindex = I.tabindex WHERE B.tabtype != -1 AND B.tabindex != -1 AND (I.name LIKE ? OR I.desc LIKE ?)) AS C LEFT JOIN OwnerInfo AS O ON C.ownerkey = O.ownerkey WHERE '
	local sql  = 'SELECT C.ownerkey AS ownerkey, C.boxtype AS boxtype, C.boxindex AS boxindex, C.tabtype AS tabtype, C.tabindex AS tabindex, C.tabsubindex AS tabsubindex, SUM(C.bagcount) AS bagcount, SUM(C.bankcount) AS bankcount, C.time AS time, O.ownername AS ownername, O.servername AS servername FROM' .. sqlfrom
	local sqlc = 'SELECT COUNT(*) AS count FROM' .. sqlfrom
	local nPageSize = MY_BagStatistics.bCompactMode and COMPACT_MODE_PAGE_SIZE or NORMAL_MODE_PAGE_SIZE
	local wheres = {}
	local ownerkeys = {}
	local container = frame:Lookup('Window_Main/WndScroll_Name/WndContainer_Name')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup('CheckBox_Name'):IsCheckBoxChecked() then
			insert(wheres, 'O.ownerkey = ?')
			insert(ownerkeys, wnd.ownerkey)
		end
	end
	local sqlwhere = ((#wheres == 0 and ' 1 = 0 ') or ('(' .. concat(wheres, ' OR ') .. ')'))
	local sqlgroup = ' GROUP BY C.tabtype, C.tabindex'
	sql  = sql  .. sqlwhere .. sqlgroup .. ' LIMIT ' .. nPageSize .. ' OFFSET ' .. ((frame.nCurrentPage - 1) * nPageSize)
	sqlc = sqlc .. sqlwhere .. sqlgroup

	-- 绘制页码
	local DB_CountR = DB:Prepare(sqlc)
	DB_CountR:ClearBindings()
	DB_CountR:BindAll(AnsiToUTF8('%' .. searchitem .. '%'), AnsiToUTF8('%' .. searchitem .. '%'), unpack(ownerkeys))
	local nCount = #DB_CountR:GetAll()
	local nPageCount = floor(nCount / nPageSize) + 1
	frame:Lookup('Window_Main/Wnd_Index/Wnd_IndexEdit/WndEdit_Index'):SetText(frame.nCurrentPage)
	frame:Lookup('Window_Main/Wnd_Index', 'Handle_IndexCount/Text_IndexCount'):SprintfText(_L['%d pages'], nPageCount)
	frame:Lookup('Window_Main/WndScroll_Name/Wnd_SearchInfo', 'Text_SearchInfo'):SprintfText(_L['%d results'], nCount)

	local hOuter = frame:Lookup('Window_Main/Wnd_Index', 'Handle_IndexesOuter')
	local handle = hOuter:Lookup('Handle_Indexes')
	handle:Clear()
	if nPageCount <= PAGE_DISPLAY then
		for i = 0, nPageCount - 1 do
			local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
			hItem.nPage = i + 1
			hItem:Lookup('Text_Index'):SetText(i + 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(i + 1 == frame.nCurrentPage)
		end
	else
		local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
		hItem.nPage = 1
		hItem:Lookup('Text_Index'):SetText(1)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(1 == frame.nCurrentPage)

		local nStartPage
		if frame.nCurrentPage + ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif frame.nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = frame.nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2)
		end
		for i = 1, PAGE_DISPLAY - 2 do
			local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
			hItem.nPage = nStartPage + i - 1
			hItem:Lookup('Text_Index'):SetText(nStartPage + i - 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(nStartPage + i - 1 == frame.nCurrentPage)
		end

		local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
		hItem.nPage = nPageCount
		hItem:Lookup('Text_Index'):SetText(nPageCount)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(nPageCount == frame.nCurrentPage)
	end
	handle:SetSize(hOuter:GetSize())
	handle:FormatAllItemPos()
	handle:SetSizeByAllItemSize()
	hOuter:FormatAllItemPos()

	-- 绘制列表
	local DB_ItemInfoR = DB:Prepare(sql)
	DB_ItemInfoR:ClearBindings()
	DB_ItemInfoR:BindAll(AnsiToUTF8('%' .. searchitem .. '%'), AnsiToUTF8('%' .. searchitem .. '%'), unpack(ownerkeys))
	local result = DB_ItemInfoR:GetAll()

	local sqlbelongs = 'SELECT * FROM (SELECT ownerkey, SUM(bagcount) AS bagcount, SUM(bankcount) AS bankcount FROM BagItems WHERE tabtype = ? AND tabindex = ? AND tabsubindex = ? GROUP BY ownerkey) AS B LEFT JOIN OwnerInfo AS O ON B.ownerkey = O.ownerkey WHERE '
	sqlbelongs = sqlbelongs .. ((#wheres == 0 and ' 1 = 0 ') or ('(' .. concat(wheres, ' OR ') .. ')'))
	local DB_BelongsR = DB:Prepare(sqlbelongs)

	local handle = frame:Lookup('Window_Main/WndScroll_Item', 'Handle_Items')
	local scroll = frame:Lookup('Window_Main/WndScroll_Item/Scroll_Item')
	handle:Clear()
	for _, rec in ipairs(result) do
		local KItemInfo = GetItemInfo(rec.tabtype, rec.tabindex)
		if KItemInfo then
			if MY_BagStatistics.bCompactMode then
				local count = 0
				local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_ItemCompact')
				local box = hItem:Lookup('Box_ItemCompact')

				DB_BelongsR:ClearBindings()
				DB_BelongsR:BindAll(rec.tabtype, rec.tabindex, rec.tabsubindex, unpack(ownerkeys))
				local result = DB_BelongsR:GetAll()
				local aTip = {}
				for _, rec in ipairs(result) do
					count = count + rec.bankcount + rec.bagcount
					insert(aTip, _L('%s (%s)\tBankx%d Bagx%d Totalx%d\n', UTF8ToAnsi(rec.ownername), UTF8ToAnsi(rec.servername), rec.bankcount, rec.bagcount, rec.bankcount + rec.bagcount))
				end
				UI.UpdateItemInfoBoxObject(box, nil, rec.tabtype, rec.tabindex, count, rec.tabsubindex)
				box.tip = GetItemInfoTip(nil, rec.tabtype, rec.tabindex, nil, nil, rec.tabsubindex) .. GetFormatText(concat(aTip))
			else
				local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Item')
				UI.UpdateItemInfoBoxObject(hItem:Lookup('Box_Item'), nil, rec.tabtype, rec.tabindex, 1, rec.tabsubindex)
				UI.UpdateItemInfoBoxObject(hItem:Lookup('Handle_ItemInfo/Text_ItemName'), nil, rec.tabtype, rec.tabindex, 1, rec.tabsubindex)
				hItem:Lookup('Text_ItemStatistics'):SprintfText(_L['Bankx%d Bagx%d Totalx%d'], rec.bankcount, rec.bagcount, rec.bankcount + rec.bagcount)
				if KItemInfo.nGenre == ITEM_GENRE.TASK_ITEM then
					hItem:Lookup('Handle_ItemInfo/Text_ItemDesc'):SetText(g_tStrings.STR_ITEM_H_QUEST_ITEM)
				elseif KItemInfo.nBindType == ITEM_BIND.BIND_ON_PICKED then
					hItem:Lookup('Handle_ItemInfo/Text_ItemDesc'):SetText(g_tStrings.STR_ITEM_H_BIND_AFTER_PICK)
				elseif KItemInfo.nBindType == ITEM_BIND.BIND_ON_TIME_LIMITATION then
					hItem:Lookup('Handle_ItemInfo/Text_ItemDesc'):SetText(g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION1)
				else
					hItem:Lookup('Handle_ItemInfo/Text_ItemDesc'):SetText('')
				end
				hItem:Lookup('Handle_ItemInfo'):FormatAllItemPos()

				DB_BelongsR:ClearBindings()
				DB_BelongsR:BindAll(rec.tabtype, rec.tabindex, rec.tabsubindex, unpack(ownerkeys))
				local result = DB_BelongsR:GetAll()
				local hBelongsList = hItem:Lookup('Handle_ItemBelongs')
				hBelongsList:Clear()
				for _, rec in ipairs(result) do
					hBelongsList:AppendItemFromIni(SZ_INI, 'Text_ItemBelongs'):SprintfText(_L['%s (%s)\tBankx%d Bagx%d Totalx%d\n'], UTF8ToAnsi(rec.ownername), UTF8ToAnsi(rec.servername), rec.bankcount, rec.bagcount, rec.bankcount + rec.bagcount)
				end
				hBelongsList:FormatAllItemPos()
				hBelongsList:SetSizeByAllItemSize()
				hItem:Lookup('Shadow_ItemHover'):SetH(0)
				hItem:SetSizeByAllItemSize()
				hItem:SetH(hItem:GetH() + 7)
				hItem:Lookup('Shadow_ItemHover'):SetH(hItem:GetH())
			end
		--[[#DEBUG BEGIN]]
		else
			LIB.Debug({'KItemInfo not found: ' .. rec.tabtype .. ', ' .. rec.tabindex}, 'MY_BagStatistics', DEBUG_LEVEL.WARNING)
		--[[#DEBUG END]]
		end
	end
	handle:FormatAllItemPos()
	scroll:SetScrollPos(0)
end

function MY_BagStatistics.OnFrameCreate()
	FlushDB()

	MY_BagStatistics.UpdateNames(this)
	this:BringToTop()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(PACKET_INFO.NAME .. ' - ' .. _L['MY_BagStatistics'])
	this:RegisterEvent('MY_BAGSTATISTICS_MODE_CHANGE')
end

function MY_BagStatistics.OnEvent(event)
	if event == 'MY_BAGSTATISTICS_MODE_CHANGE' then
		MY_BagStatistics.UpdateItems(this)
	end
end

function MY_BagStatistics.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_SearchName' then
			MY_BagStatistics.UpdateNames(frame)
		elseif name == 'WndEdit_Index' then
			frame.nCurrentPage = tonumber(this:GetText()) or frame.nCurrentPage
		end
		MY_BagStatistics.UpdateItems(frame)
		return 1
	end
end

function MY_BagStatistics.OnCheckBoxCheck()
	MY_BagStatistics.UpdateItems(this:GetRoot())
end

function MY_BagStatistics.OnCheckBoxUncheck()
	MY_BagStatistics.UpdateItems(this:GetRoot())
end

function MY_BagStatistics.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		MY_BagStatistics.Close()
	elseif name == 'Btn_Only' then
		local wnd = this:GetParent()
		local parent = wnd:GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_Name'):Check(false, WNDEVENT_FIRETYPE.PREVENT)
		end
		wnd:Lookup('CheckBox_Name'):Check(true)
	elseif name == 'Btn_Delete' then
		local wnd = this:GetParent()
		LIB.Confirm(_L('Are you sure to delete item record of %s?', wnd.ownername), function()
			DB_ItemsDA:ClearBindings()
			DB_ItemsDA:BindAll(wnd.ownerkey)
			DB_ItemsDA:Execute()
			DB_OwnerInfoD:ClearBindings()
			DB_OwnerInfoD:BindAll(wnd.ownerkey)
			DB_OwnerInfoD:Execute()
			MY_BagStatistics.UpdateNames(wnd:GetRoot())
		end)
	elseif name == 'Btn_SwitchMode' then
		MY_BagStatistics.bCompactMode = not MY_BagStatistics.bCompactMode
		FireUIEvent('MY_BAGSTATISTICS_MODE_CHANGE')
	elseif name == 'Btn_NameAll' then
		local parent = this:GetParent():Lookup('WndContainer_Name')
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_Name'):Check(true, WNDEVENT_FIRETYPE.PREVENT)
		end
		MY_BagStatistics.UpdateItems(this:GetRoot())
	end
end

function MY_BagStatistics.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Index' then
		this:GetRoot().nCurrentPage = this.nPage
		MY_BagStatistics.UpdateItems(this:GetRoot())
	end
end

function MY_BagStatistics.OnItemMouseEnter()
	if this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	end
end
MY_BagStatistics.OnItemRefreshTip = MY_BagStatistics.OnItemMouseEnter

function MY_BagStatistics.OnItemMouseLeave()
	HideTip()
end

do
local menu = {
	szOption = _L['MY_BagStatistics'],
	fnAction = function() MY_BagStatistics.Toggle() end,
}
LIB.RegisterAddonMenu('MY_BAGSTATISTICS_MENU', menu)
end
LIB.RegisterHotKey('MY_BagStatistics', _L['MY_BagStatistics'], MY_BagStatistics.Toggle, nil)
