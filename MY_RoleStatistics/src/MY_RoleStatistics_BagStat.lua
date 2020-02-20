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
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_BagStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

if IsLocalFileExist(LIB.FormatPath({'userdata/bagstatistics.db', PATH_TYPE.GLOBAL})) then
	CPath.Move(LIB.FormatPath({'userdata/bagstatistics.db', PATH_TYPE.GLOBAL}), LIB.FormatPath({'userdata/role_statistics/bag_stat.db', PATH_TYPE.GLOBAL}))
end

local DB = LIB.ConnectDatabase(_L['MY_RoleStatistics_BagStat'], {'userdata/role_statistics/bag_stat.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_BagStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_BagStat.ini'
local PAGE_DISPLAY = 15
local NORMAL_MODE_PAGE_SIZE = 50
local COMPACT_MODE_PAGE_SIZE = 150
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

local D = {}
local O = {
	bCompactMode = false,
	tUncheckedNames = {},
}
RegisterCustomData('Global/MY_RoleStatistics_BagStat.bCompactMode')
RegisterCustomData('Global/MY_RoleStatistics_BagStat.tUncheckedNames')

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
	local me = GetClientPlayer()
	for nIndex = 1, LIB.GetGuildBankBagSize(nPage) do
		local dwType, dwX = LIB.GetGuildBankBagPos(nPage, nIndex)
		local tabtype, tabindex, tabsubindex, name, desc, count = -1, -1, -1, '', '', 0
		local KItem = GetPlayerItem(me, dwType, dwX)
		if KItem then
			tabtype = KItem.dwTabType
			tabindex = KItem.dwIndex
			name = KItem.szName
			desc = GetItemText(KItem)
			tabsubindex = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
			count = KItem.bCanStack and KItem.nStackNum or 1
		end
		l_guildcache[dwX] = {
			boxtype = dwType,
			boxindex = dwX,
			tabtype = tabtype,
			tabindex = tabindex,
			tabsubindex = tabsubindex,
			name = name,
			desc = desc,
			count = count,
			time = GetCurrentTime(),
		}
	end
end
LIB.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE.MY_RoleStatistics_BagStat', UpdateTongRepertoryPage)

function FlushDB()
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_BagStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
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
	LIB.Debug('MY_RoleStatistics_BagStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_BagStat', FlushDB)
end

function D.UpdateNames(page)
	local searchname = page:Lookup('Wnd_Total/Wnd_SearchName/Edit_SearchName'):GetText()
	DB_OwnerInfoR:ClearBindings()
	DB_OwnerInfoR:BindAll(AnsiToUTF8('%' .. searchname .. '%'), AnsiToUTF8('%' .. searchname .. '%'))
	local result = DB_OwnerInfoR:GetAll()

	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	container:Clear()
	for _, rec in ipairs(result) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_Name')
		wnd.time = rec.time
		wnd.ownerkey   = UTF8ToAnsi(rec.ownerkey)
		wnd.ownername  = UTF8ToAnsi(rec.ownername)
		wnd.servername = UTF8ToAnsi(rec.servername)
		local ownername = wnd.ownername
		if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
			ownername = MY_ChatMosaics.MosaicsString(ownername)
		end
		wnd:Lookup('CheckBox_Name', 'Text_Name'):SetText(ownername .. ' (' .. wnd.servername .. ')')
		wnd:Lookup('CheckBox_Name'):Check(not MY_RoleStatistics_BagStat.tUncheckedNames[wnd.ownerkey], WNDEVENT_FIRETYPE.PREVENT)
	end
	container:FormatAllContentPos()
	page.nCurrentPage = 1
	D.UpdateItems(page)
end

function D.UpdateItems(page)
	FlushDB()

	local searchitem = page:Lookup('Wnd_Total/Wnd_SearchItem/Edit_SearchItem'):GetText():gsub('%s+', '%%')
	local sqlfrom = '(SELECT B.ownerkey, B.boxtype, B.boxindex, B.tabtype, B.tabindex, B.tabsubindex, B.bagcount, B.bankcount, B.time FROM BagItems AS B LEFT JOIN ItemInfo AS I ON B.tabtype = I.tabtype AND B.tabindex = I.tabindex WHERE B.tabtype != -1 AND B.tabindex != -1 AND (I.name LIKE ? OR I.desc LIKE ?)) AS C LEFT JOIN OwnerInfo AS O ON C.ownerkey = O.ownerkey WHERE '
	local sql  = 'SELECT C.ownerkey AS ownerkey, C.boxtype AS boxtype, C.boxindex AS boxindex, C.tabtype AS tabtype, C.tabindex AS tabindex, C.tabsubindex AS tabsubindex, SUM(C.bagcount) AS bagcount, SUM(C.bankcount) AS bankcount, C.time AS time, O.ownername AS ownername, O.servername AS servername FROM' .. sqlfrom
	local sqlc = 'SELECT COUNT(*) AS count FROM' .. sqlfrom
	local nPageSize = O.bCompactMode and COMPACT_MODE_PAGE_SIZE or NORMAL_MODE_PAGE_SIZE
	local wheres = {}
	local ownerkeys = {}
	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup('CheckBox_Name'):IsCheckBoxChecked() then
			insert(wheres, 'O.ownerkey = ?')
			insert(ownerkeys, wnd.ownerkey)
		end
	end
	local sqlwhere = ((#wheres == 0 and ' 1 = 0 ') or ('(' .. concat(wheres, ' OR ') .. ')'))
	local sqlgroup = ' GROUP BY C.tabtype, C.tabindex'
	sql  = sql  .. sqlwhere .. sqlgroup .. ' LIMIT ' .. nPageSize .. ' OFFSET ' .. ((page.nCurrentPage - 1) * nPageSize)
	sqlc = sqlc .. sqlwhere .. sqlgroup

	-- 绘制页码
	local DB_CountR = DB:Prepare(sqlc)
	DB_CountR:ClearBindings()
	DB_CountR:BindAll(AnsiToUTF8('%' .. searchitem .. '%'), AnsiToUTF8('%' .. searchitem .. '%'), unpack(ownerkeys))
	local nCount = #DB_CountR:GetAll()
	local nPageCount = floor(nCount / nPageSize) + 1
	page:Lookup('Wnd_Total/Wnd_Index/Wnd_IndexEdit/WndEdit_Index'):SetText(page.nCurrentPage)
	page:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexCount/Text_IndexCount'):SprintfText(_L['%d pages'], nPageCount)
	page:Lookup('Wnd_Total/WndScroll_Name/Wnd_SearchInfo', 'Text_SearchInfo'):SprintfText(_L['%d results'], nCount)

	local hOuter = page:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexesOuter')
	local handle = hOuter:Lookup('Handle_Indexes')
	handle:Clear()
	if nPageCount <= PAGE_DISPLAY then
		for i = 0, nPageCount - 1 do
			local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
			hItem.nPage = i + 1
			hItem:Lookup('Text_Index'):SetText(i + 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(i + 1 == page.nCurrentPage)
		end
	else
		local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
		hItem.nPage = 1
		hItem:Lookup('Text_Index'):SetText(1)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(1 == page.nCurrentPage)

		local nStartPage
		if page.nCurrentPage + ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif page.nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = page.nCurrentPage - ceil((PAGE_DISPLAY - 2) / 2)
		end
		for i = 1, PAGE_DISPLAY - 2 do
			local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
			hItem.nPage = nStartPage + i - 1
			hItem:Lookup('Text_Index'):SetText(nStartPage + i - 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(nStartPage + i - 1 == page.nCurrentPage)
		end

		local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
		hItem.nPage = nPageCount
		hItem:Lookup('Text_Index'):SetText(nPageCount)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(nPageCount == page.nCurrentPage)
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

	local handle = page:Lookup('Wnd_Total/WndScroll_Item', 'Handle_Items')
	local scroll = page:Lookup('Wnd_Total/WndScroll_Item/Scroll_Item')
	handle:Clear()
	for _, rec in ipairs(result) do
		local KItemInfo = GetItemInfo(rec.tabtype, rec.tabindex)
		if KItemInfo then
			if O.bCompactMode then
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
			LIB.Debug('MY_RoleStatistics_BagStat', 'KItemInfo not found: ' .. rec.tabtype .. ', ' .. rec.tabindex, DEBUG_LEVEL.WARNING)
		--[[#DEBUG END]]
		end
	end
	handle:FormatAllItemPos()
	scroll:SetScrollPos(0)
end

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_BagStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	Wnd.CloseWindow(frameTemp)

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_BAGSTATISTICS_MODE_CHANGE')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
end

function D.OnActivePage()
	FlushDB()
	D.UpdateNames(this)
end

function D.OnEvent(event)
	if event == 'MY_BAGSTATISTICS_MODE_CHANGE' then
		D.UpdateItems(this)
	elseif event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateNames(this)
	end
end

function D.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_SearchName' then
			local page = this:GetParent():GetParent():GetParent()
			D.UpdateNames(page)
		elseif name == 'WndEdit_Index' then
			local page = this:GetParent():GetParent():GetParent():GetParent()
			page.nCurrentPage = tonumber(this:GetText()) or page.nCurrentPage
			D.UpdateItems(page)
		elseif name == 'Edit_SearchItem' then
			local page = this:GetParent():GetParent():GetParent()
			D.UpdateItems(page)
		end
		return 1
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Name' then
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		D.UpdateItems(page)
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Name' then
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		D.UpdateItems(page)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Only' then
		local wnd = this:GetParent()
		local parent = wnd:GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_Name'):Check(false, WNDEVENT_FIRETYPE.PREVENT)
		end
		wnd:Lookup('CheckBox_Name'):Check(true)
	elseif name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		LIB.Confirm(_L('Are you sure to delete item record of %s?', wnd.ownername), function()
			DB_ItemsDA:ClearBindings()
			DB_ItemsDA:BindAll(wnd.ownerkey)
			DB_ItemsDA:Execute()
			DB_OwnerInfoD:ClearBindings()
			DB_OwnerInfoD:BindAll(wnd.ownerkey)
			DB_OwnerInfoD:Execute()
			D.UpdateNames(page)
		end)
	elseif name == 'Btn_SwitchMode' then
		MY_RoleStatistics_BagStat.bCompactMode = not MY_RoleStatistics_BagStat.bCompactMode
	elseif name == 'Btn_NameAll' then
		local parent = this:GetParent():Lookup('WndContainer_Name')
		local page = this:GetParent():GetParent():GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_Name'):Check(true, WNDEVENT_FIRETYPE.PREVENT)
		end
		D.UpdateItems(page)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Index' then
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent()
		page.nCurrentPage = this.nPage
		D.UpdateItems(page)
	end
end

function D.OnItemMouseEnter()
	if this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	HideTip()
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'Wnd_Name' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatText(_L(
			this.ownername:sub(1, 1) == '['
				and 'Tong: %s\nServer: %s\nSnapshot Time: %s'
				or 'Character: %s\nServer: %s\nSnapshot Time: %s',
			this.ownername,
			this.servername,
			LIB.FormatTime(this.time, '%yyyy-%MM-%dd %hh:%mm:%ss')), nil, 255, 255, 0), 400, {x, y, w, h, false}, nil, false)
	elseif name == 'CheckBox_Name' then
		LIB.ExecuteWithThis(this:GetParent(), D.OnMouseEnter)
	end
end

-- function D.OnMouseLeave()
-- 	HideTip()
-- end

-- Module exports
do
local settings = {
	exports = {
		{
			fields = {
				OnInitPage = D.OnInitPage,
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_RoleStatistics.RegisterModule('BagStat', _L['MY_RoleStatistics_BagStat'], LIB.GeneGlobalNS(settings))
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bCompactMode = true,
				tUncheckedNames = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bCompactMode = true,
				tUncheckedNames = true,
			},
			triggers = {
				bCompactMode = function()
					FireUIEvent('MY_BAGSTATISTICS_MODE_CHANGE')
				end,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_BagStat = LIB.GeneGlobalNS(settings)
end
