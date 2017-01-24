--
-- @Author: Zhai Yiming
-- @Date:   2017-01-22 18:30:42
-- @Email:  root@derzh.com
-- @Project: JX3 UI
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-01-24 15:55:23
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_BagEx/lang/")
 DB = SQLite3_Open(MY.FormatPath({"userdata/bagstatistics.db", MY_DATA_PATH.GLOBAL}))
if not DB then
	return MY.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L["MY_BagStatistics"])
end
local SZ_INI = MY.GetAddonInfo().szRoot .. "MY_BagEx/ui/MY_BagStatistics.ini"
DB:Execute("CREATE TABLE IF NOT EXISTS BagItems (ownerkey NVARCHAR(20), boxtype INTEGER, boxindex INTEGER, tabtype INTEGER, tabindex INTEGER, tabsubindex INTEGER, bagcount INTEGER, bankcount INTEGER, time INTEGER, PRIMARY KEY(ownerkey, boxtype, boxindex))")
DB:Execute("CREATE INDEX IF NOT EXISTS BagItems_tab_idx ON BagItems(tabtype, tabindex, tabsubindex)")
local DB_ItemsW = DB:Prepare("REPLACE INTO BagItems (ownerkey, boxtype, boxindex, tabtype, tabindex, tabsubindex, bagcount, bankcount, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
local DB_ItemsDL = DB:Prepare("DELETE FROM BagItems WHERE ownerkey = ? AND boxtype = ? AND boxindex >= ?")
DB:Execute("CREATE TABLE IF NOT EXISTS OwnerInfo (ownerkey NVARCHAR(20), ownername NVARCHAR(20), servername NVARCHAR(20), time INTEGER, PRIMARY KEY(ownerkey))")
DB:Execute("CREATE INDEX IF NOT EXISTS OwnerInfo_ownername_idx ON OwnerInfo(ownername)")
DB:Execute("CREATE INDEX IF NOT EXISTS OwnerInfo_servername_idx ON OwnerInfo(servername)")
local DB_OwnerInfoW = DB:Prepare("REPLACE INTO OwnerInfo (ownerkey, ownername, servername, time) VALUES (?, ?, ?, ?)")
local DB_OwnerInfoR = DB:Prepare("SELECT * FROM OwnerInfo WHERE ownername LIKE ? OR servername LIKE ? ORDER BY time DESC")
DB:Execute("CREATE TABLE IF NOT EXISTS ItemInfo (tabtype INTEGER, tabindex INTEGER, tabsubindex INTEGER, name NVARCHAR(20), desc NVARCHAR(800), PRIMARY KEY(tabtype, tabindex, tabsubindex))")
DB:Execute("CREATE INDEX IF NOT EXISTS ItemInfo_name_idx ON ItemInfo(name)")
DB:Execute("CREATE INDEX IF NOT EXISTS ItemInfo_desc_idx ON ItemInfo(desc)")
local DB_ItemInfoW = DB:Prepare("REPLACE INTO ItemInfo (tabtype, tabindex, tabsubindex, name, desc) VALUES (?, ?, ?, ?, ?)")

MY_BagStatistics = {}
MY_BagStatistics.tUncheckedNames = {}
RegisterCustomData("Global/MY_BagStatistics.tUncheckedNames")

local PushDB
do
local GetItemText
do
local l_tItemText = {}
function GetItemText(KItem)
	if KItem then
		if GetItemTip then
			local szKey = KItem.dwTabType .. ',' .. KItem.dwIndex
			if not l_tItemText[szKey] then
				l_tItemText[szKey] = ""
				l_tItemText[szKey] = MY.Xml.GetPureText(GetItemTip(KItem))
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
	local offset = nPage * INVENTORY_GUILD_PAGE_SIZE
	local boxtype = INVENTORY_GUILD_BANK
	for boxindex = offset, offset + 7 * 14 - 1 do
		local tabtype, tabindex, tabsubindex, name, desc, count = -1, -1, -1, "", "", 0
		local KItem = GetPlayerItem(me, boxtype, boxindex)
		if KItem then
			tabtype = KItem.dwTabType
			tabindex = KItem.dwIndex
			name = KItem.szName
			desc = GetItemText(KItem)
			tabsubindex = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
			count = KItem.nStackNum
		end
		l_guildcache[boxindex] = {boxtype = boxtype, boxindex = boxindex, tabtype = tabtype, tabindex = tabindex, tabsubindex = tabsubindex, name = name, desc = desc, count = count, time = GetCurrentTime()}
	end
end
MY.RegisterEvent("UPDATE_TONG_REPERTORY_PAGE.MY_BagStatistics", UpdateTongRepertoryPage)

function PushDB()
	MY.Debug({"Pushing to database..."}, "MY_BagStatistics", MY_DEBUG.LOG)
	local me = GetClientPlayer()
	local time = GetCurrentTime()
	local ownerkey = AnsiToUTF8(me.GetGlobalID() ~= "0" and me.GetGlobalID() or me.szName)
	local ownername = AnsiToUTF8(me.szName)
	local servername = AnsiToUTF8(MY.Game.GetRealServer(2))
	DB:Execute("BEGIN TRANSACTION")

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
				DB_ItemsW:BindAll(ownerkey, boxtype, boxindex, KItem.dwTabType, KItem.dwIndex, KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1, KItem.nStackNum, 0, time)
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
				DB_ItemsW:BindAll(ownerkey, boxtype, boxindex, KItem.dwTabType, KItem.dwIndex, KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1, 0, KItem.nStackNum, time)
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
	if not empty(l_guildcache) then
		local ownerkey = "tong" .. me.dwTongID
		local ownername = AnsiToUTF8("[" .. MY.GetTongName(me.dwTongID) .. "]")
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

	DB:Execute("END TRANSACTION")
	MY.Debug({"Pushing to database finished..."}, "MY_BagStatistics", MY_DEBUG.LOG)
end
MY.RegisterEvent("PLAYER_LEAVE_GAME.MY_BagStatistics", PushDB)
end

function MY_BagStatistics.Open()
	Wnd.OpenWindow(SZ_INI, "MY_BagStatistics")
end

function MY_BagStatistics.Close()
	Wnd.CloseWindow("MY_BagStatistics")
end

function MY_BagStatistics.IsOpened()
	return Station.Lookup("Normal/MY_BagStatistics")
end

function MY_BagStatistics.Toggle()
	if MY_BagStatistics.IsOpened() then
		MY_BagStatistics.Close()
	else
		MY_BagStatistics.Open()
	end
end

function MY_BagStatistics.UpdateNames(frame)
	local searchname = frame:Lookup("Window_Main/Wnd_SearchName/Edit_SearchName"):GetText()
	DB_OwnerInfoR:ClearBindings()
	DB_OwnerInfoR:BindAll(AnsiToUTF8("%" .. searchname .. "%"), AnsiToUTF8("%" .. searchname .. "%"))
	local result = DB_OwnerInfoR:GetAll()
	
	local container = frame:Lookup("Window_Main/WndScroll_Name/WndContainer_Name")
	container:Clear()
	for _, rec in ipairs(result) do
		local wnd = container:AppendContentFromIni(SZ_INI, "Wnd_Name")
		wnd.ownerkey   = UTF8ToAnsi(rec.ownerkey)
		wnd.ownername  = UTF8ToAnsi(rec.ownername)
		wnd.servername = UTF8ToAnsi(rec.servername)
		wnd:Lookup("CheckBox_Name", "Text_Name"):SetText(wnd.ownername .. " (" .. wnd.servername .. ")")
		wnd:Lookup("CheckBox_Name"):Check(not MY_BagStatistics.tUncheckedNames[wnd.ownerkey], WNDEVENT_FIRETYPE.PREVENT)
	end
	container:FormatAllContentPos()
	MY_BagStatistics.UpdateItems(frame)
end

function MY_BagStatistics.UpdateItems(frame)
	local searchitem = frame:Lookup("Window_Main/Wnd_SearchItem/Edit_SearchItem"):GetText():gsub("%s+", "%%")
	local sql = "SELECT C.ownerkey AS ownerkey, C.boxtype AS boxtype, C.boxindex AS boxindex, C.tabtype AS tabtype, C.tabindex AS tabindex, C.tabsubindex AS tabsubindex, SUM(C.bagcount) AS bagcount, SUM(C.bankcount) AS bankcount, C.time AS time, O.ownername AS ownername, O.servername AS servername FROM(SELECT B.ownerkey, B.boxtype, B.boxindex, B.tabtype, B.tabindex, B.tabsubindex, B.bagcount, B.bankcount, B.time FROM BagItems AS B LEFT JOIN ItemInfo AS I ON B.tabtype = I.tabtype AND B.tabindex = I.tabindex WHERE B.tabtype != -1 AND B.tabindex != -1 AND (I.name LIKE ? OR I.desc LIKE ?)) AS C LEFT JOIN OwnerInfo AS O ON C.ownerkey = O.ownerkey WHERE "
	local wheres = {}
	local ownerkeys = {}
	local container = frame:Lookup("Window_Main/WndScroll_Name/WndContainer_Name")
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup("CheckBox_Name"):IsCheckBoxChecked() then
			table.insert(wheres, "O.ownerkey = ?")
			table.insert(ownerkeys, wnd.ownerkey)
		end
	end
	sql = sql .. ((#wheres == 0 and " 1 = 0 ") or ("(" .. table.concat(wheres, " OR ") .. ")")) .. " GROUP BY C.tabtype, C.tabindex"
	
	local sqlc = "SELECT * FROM (SELECT ownerkey, SUM(bagcount) AS bagcount, SUM(bankcount) AS bankcount FROM BagItems WHERE tabtype = ? AND tabindex = ? AND tabsubindex = ? GROUP BY ownerkey) AS B LEFT JOIN OwnerInfo AS O ON B.ownerkey = O.ownerkey WHERE "
	sqlc = sqlc .. ((#wheres == 0 and " 1 = 0 ") or ("(" .. table.concat(wheres, " OR ") .. ")"))
	local DB_CountR = DB:Prepare(sqlc)
	
	local DB_ItemInfoR = DB:Prepare(sql)
	DB_ItemInfoR:ClearBindings()
	DB_ItemInfoR:BindAll(AnsiToUTF8("%" .. searchitem .. "%"), AnsiToUTF8("%" .. searchitem .. "%"), unpack(ownerkeys))
	local result = DB_ItemInfoR:GetAll()
	
	local hList = frame:Lookup("Window_Main/WndScroll_Item", "Handle_Items")
	hList:Clear()
	for _, rec in ipairs(result) do
		local KItemInfo = GetItemInfo(rec.tabtype, rec.tabindex)
		if KItemInfo then
			local hItem = hList:AppendItemFromIni(SZ_INI, "Handle_Item")
			UpdateItemInfoBoxObject(hItem:Lookup("Box_Item"), nil, rec.tabtype, rec.tabindex, 1, rec.tabsubindex)
			UpdateItemInfoBoxObject(hItem:Lookup("Handle_ItemInfo/Text_ItemName"), nil, rec.tabtype, rec.tabindex, 1, rec.tabsubindex)
			hItem:Lookup("Text_ItemStatistics"):SprintfText(_L["Bankx%d Bagx%d Totalx%d"], rec.bankcount, rec.bagcount, rec.bankcount + rec.bagcount)
			if KItemInfo.nGenre == ITEM_GENRE.TASK_ITEM then
				hItem:Lookup("Handle_ItemInfo/Text_ItemDesc"):SetText(g_tStrings.STR_ITEM_H_QUEST_ITEM)
			elseif KItemInfo.nBindType == ITEM_BIND.BIND_ON_PICKED then
				hItem:Lookup("Handle_ItemInfo/Text_ItemDesc"):SetText(g_tStrings.STR_ITEM_H_BIND_AFTER_PICK)
			elseif KItemInfo.nBindType == ITEM_BIND.BIND_ON_TIME_LIMITATION then
				hItem:Lookup("Handle_ItemInfo/Text_ItemDesc"):SetText(g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION1)
			else
				hItem:Lookup("Handle_ItemInfo/Text_ItemDesc"):SetText("")
			end
			hItem:Lookup("Handle_ItemInfo"):FormatAllItemPos()
			
			DB_CountR:ClearBindings()
			DB_CountR:BindAll(rec.tabtype, rec.tabindex, rec.tabsubindex, unpack(ownerkeys))
			local result = DB_CountR:GetAll()
			local hBelongsList = hItem:Lookup("Handle_ItemBelongs")
			hBelongsList:Clear()
			for _, rec in ipairs(result) do
				hBelongsList:AppendItemFromIni(SZ_INI, "Text_ItemBelongs"):SprintfText(_L['%s (%s)\tBankx%d Bagx%d Totalx%d\n'], UTF8ToAnsi(rec.ownername), UTF8ToAnsi(rec.servername), rec.bankcount, rec.bagcount, rec.bankcount + rec.bagcount)
			end
			hBelongsList:FormatAllItemPos()
			hBelongsList:SetSizeByAllItemSize()
			hItem:Lookup("Shadow_ItemHover"):SetH(0)
			hItem:SetSizeByAllItemSize()
			hItem:SetH(hItem:GetH() + 7)
			hItem:Lookup("Shadow_ItemHover"):SetH(hItem:GetH())
		else
			MY.Debug({"KItemInfo not found: " .. rec.tabtype .. ", " .. rec.tabindex}, "MY_BagStatistics", MY_DEBUG.WARNING)
		end
	end
	hList:FormatAllItemPos()
end

function MY_BagStatistics.OnFrameCreate()
	PushDB()
	
	MY_BagStatistics.UpdateNames(this)
	this:BringToTop()
	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
end

function MY_BagStatistics.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == "Enter" then
		if name == "Edit_SearchName" then
			MY_BagStatistics.UpdateNames(frame)
		elseif name == "WndEdit_Index" then
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
	if name == "Btn_Close" then
		MY_BagStatistics.Close()
	elseif name == "Btn_Only" then
		local wnd = this:GetParent()
		local parent = wnd:GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup("CheckBox_Name"):Check(false, WNDEVENT_FIRETYPE.PREVENT)
		end
		wnd:Lookup("CheckBox_Name"):Check(true)
	end
end

do
local menu = {
	szOption = _L["MY_BagStatistics"],
	fnAction = function() MY_BagStatistics.Toggle() end,
}
MY.RegisterPlayerAddonMenu('MY_BAGSTATISTICS_MENU', menu)
MY.RegisterTraceButtonMenu('MY_BAGSTATISTICS_MENU', menu)
MY.Game.AddHotKey("MY_BagStatistics", _L['MY_BagStatistics'], MY_BagStatistics.Toggle, nil)
end
