--
-- @Author: Zhai Yiming
-- @Date:   2017-01-22 18:30:42
-- @Email:  root@derzh.com
-- @Project: JX3 UI
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-01-23 19:15:45
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_BagEx/lang/")
local DB = SQLite3_Open(MY.FormatPath({"userdata/bagstatistics.db", MY_DATA_PATH.GLOBAL}))
if not DB then
	return MY.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L["MY_BagStatistics"])
end
local SZ_INI = MY.GetAddonInfo().szRoot .. "MY_BagEx/ui/MY_BagStatistics.ini"
DB:Execute("CREATE TABLE IF NOT EXISTS BagItems (ownerkey NVARCHAR(20), boxtype INTEGER, boxindex INTEGER, tabtype INTEGER, tabindex INTEGER, time INTEGER, PRIMARY KEY(ownerkey, boxtype, boxindex))")
DB:Execute("CREATE INDEX IF NOT EXISTS BagItems_tab_idx ON BagItems(tabtype, tabindex)")
local DB_IW = DB:Prepare("REPLACE INTO BagItems (ownerkey, boxtype, boxindex, tabtype, tabindex, time) VALUES (?, ?, ?, ?, ?, ?)")
local DB_IDL = DB:Prepare("DELETE FROM BagItems WHERE ownerkey = ? AND boxtype = ? AND boxindex >= ?")
DB:Execute("CREATE TABLE IF NOT EXISTS OwnerInfo (ownerkey NVARCHAR(20), ownername NVARCHAR(20), servername NVARCHAR(20), time INTEGER, PRIMARY KEY(ownerkey))")
DB:Execute("CREATE INDEX IF NOT EXISTS OwnerInfo_ownername_idx ON OwnerInfo(ownername)")
DB:Execute("CREATE INDEX IF NOT EXISTS OwnerInfo_servername_idx ON OwnerInfo(servername)")
local DB_OW = DB:Prepare("REPLACE INTO OwnerInfo (ownerkey, ownername, servername, time) VALUES (?, ?, ?, ?)")
local DB_OR = DB:Prepare("SELECT * FROM OwnerInfo WHERE ownername LIKE ? OR servername LIKE ? ORDER BY time DESC")

MY_BagStatistics = {}
MY_BagStatistics.tUncheckedNames = {}
RegisterCustomData("Global/MY_BagStatistics.tUncheckedNames")

local PushDB
do
local l_guildcache = {}
local function UpdateTongRepertoryPage()
	local nPage = arg0
	local offset = nPage * INVENTORY_GUILD_PAGE_SIZE
	local boxtype = INVENTORY_GUILD_BANK
	for boxindex = offset, offset + 7 * 14 - 1 do
		local tabtype, tabindex = -1, -1
		local KItem = GetPlayerItem(me, boxtype, boxindex)
		if KItem then
			tabtype = KItem.dwTabType
			tabindex = KItem.dwIndex
		end
		l_guildcache[boxindex] = {boxtype = boxtype, boxindex = boxindex, tabtype = tabtype, tabindex = tabindex, time = GetCurrentTime()}
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

	for boxtype = INVENTORY_INDEX.PACKAGE, INVENTORY_INDEX.PACKAGE + 6 - 1 do
		local count = me.GetBoxSize(boxtype)
		for boxindex = 0, count - 1 do
			local KItem = GetPlayerItem(me, boxtype, boxindex)
			DB_IW:ClearBindings()
			if KItem then
				DB_IW:BindAll(ownerkey, boxtype, boxindex, KItem.dwTabType, KItem.dwIndex, time)
			else
				DB_IW:BindAll(ownerkey, boxtype, boxindex, -1, -1, time)
			end
			DB_IW:Execute()
		end
		DB_IDL:ClearBindings()
		DB_IDL:BindAll(ownerkey, boxtype, count)
		DB_IDL:Execute()
	end
	DB_OW:ClearBindings()
	DB_OW:BindAll(ownerkey, ownername, servername, time)
	DB_OW:Execute()

	for boxtype = INVENTORY_INDEX.BANK, INVENTORY_INDEX.BANK + me.GetBankPackageCount() - 1 do
		local count = me.GetBoxSize(boxtype)
		for boxindex = 0, count - 1 do
			local KItem = GetPlayerItem(me, boxtype, boxindex)
			DB_IW:ClearBindings()
			if KItem then
				DB_IW:BindAll(ownerkey, boxtype, boxindex, KItem.dwTabType, KItem.dwIndex, time)
			else
				DB_IW:BindAll(ownerkey, boxtype, boxindex, -1, -1, time)
			end
			DB_IW:Execute()
		end
		DB_IDL:ClearBindings()
		DB_IDL:BindAll(ownerkey, boxtype, count)
		DB_IDL:Execute()
	end
	
	if not empty(l_guildcache) then
		local ownerkey = "tong" .. me.dwTongID
		local ownername = AnsiToUTF8(MY.GetTongName(me.dwTongID))
		for _, info in pairs(l_guildcache) do
			DB_IW:ClearBindings()
			DB_IW:BindAll(ownerkey, info.boxtype, info.boxindex, info.tabtype, info.tabindex, time)
			DB_IW:Execute()
		end
		DB_OW:ClearBindings()
		DB_OW:BindAll(ownerkey, ownername, servername, time)
		DB_OW:Execute()
	end
	
	DB:Execute("END TRANSACTION")
	MY.Debug({"Pushing to database finished..."}, "MY_BagStatistics", MY_DEBUG.LOG)
end
MY.RegisterEvent("PLAYER_LEAVE_GAME.MY_BagStatistics", PushDB)
end

function MY_BagStatistics.Open()
	Wnd.OpenWindow(SZ_INI, "MY_BagStatistics")
end

function MY_BagStatistics.UpdateNames(frame)
	local searchname = frame:Lookup("Window_Main/Wnd_SearchName/Edit_SearchName"):GetText()
	DB_OR:ClearBindings()
	DB_OR:BindAll(AnsiToUTF8("%" .. searchname .. "%"), AnsiToUTF8("%" .. searchname .. "%"))
	local result = DB_OR:GetAll()
	
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
end

function MY_BagStatistics.UpdateItems()
end

function MY_BagStatistics.OnFrameCreate()
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
