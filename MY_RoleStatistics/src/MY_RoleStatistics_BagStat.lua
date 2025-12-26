--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 背包统计
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RoleStatistics/MY_RoleStatistics_BagStat'
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_BagStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

CPath.MakeDir(X.FormatPath({'userdata/role_statistics', X.PATH_TYPE.GLOBAL}))

local DB = X.SQLiteConnect(_L['MY_RoleStatistics_BagStat'], {'userdata/role_statistics/bag_stat.v4.db', X.PATH_TYPE.GLOBAL})
if not DB then
	return X.OutputSystemMessage(_L['MY_RoleStatistics_BagStat'], _L['Cannot connect to database!!!'], X.CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_BagStat.ini'
local PAGE_DISPLAY = 15
local NORMAL_MODE_PAGE_SIZE = 50
local COMPACT_MODE_PAGE_SIZE = 150
X.SQLiteExecute(DB, [[
	CREATE TABLE IF NOT EXISTS BagItems (
		ownerkey NVARCHAR(20) NOT NULL,
		boxtype INTEGER NOT NULL,
		boxindex INTEGER NOT NULL,
		tabtype INTEGER NOT NULL,
		tabindex INTEGER NOT NULL,
		tabsubindex INTEGER NOT NULL,
		bagcount INTEGER NOT NULL,
		bankcount INTEGER NOT NULL,
		itemid INTEGER NOT NULL,
		uiid INTEGER NOT NULL,
		exist_time INTEGER NOT NULL,
		strength INTEGER NOT NULL,
		durability INTEGER NOT NULL,
		diamond_enchant NVARCHAR(100) NOT NULL,
		fea_enchant INTEGER NOT NULL,
		permanent_enchant INTEGER NOT NULL,
		desc NVARCHAR(4000) NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(ownerkey, boxtype, boxindex)
	)
]])
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS BagItems_tab_idx ON BagItems(tabtype, tabindex, tabsubindex)')
local DB_ItemsW = X.SQLitePrepare(DB, [[
	REPLACE INTO BagItems (
		ownerkey, boxtype, boxindex, tabtype, tabindex, tabsubindex, bagcount, bankcount,
		itemid, uiid, exist_time, strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc,
		time, extra
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]])
local DB_ItemsDL = X.SQLitePrepare(DB, 'DELETE FROM BagItems WHERE ownerkey = ? AND boxtype = ? AND boxindex >= ?')
local DB_ItemsDA = X.SQLitePrepare(DB, 'DELETE FROM BagItems WHERE ownerkey = ?')
X.SQLiteExecute(DB, [[
	CREATE TABLE IF NOT EXISTS OwnerInfo (
		ownerkey NVARCHAR(20) NOT NULL,
		ownername NVARCHAR(20) NOT NULL,
		servername NVARCHAR(20) NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(ownerkey)
	)
]])
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS OwnerInfo_ownername_idx ON OwnerInfo(ownername)')
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS OwnerInfo_servername_idx ON OwnerInfo(servername)')
local DB_OwnerInfoW = X.SQLitePrepare(DB, 'REPLACE INTO OwnerInfo (ownerkey, ownername, servername, time, extra) VALUES (?, ?, ?, ?, ?)')
local DB_OwnerInfoR = X.SQLitePrepare(DB, 'SELECT * FROM OwnerInfo WHERE ownername LIKE ? OR servername LIKE ? ORDER BY time DESC')
local DB_OwnerInfoD = X.SQLitePrepare(DB, 'DELETE FROM OwnerInfo WHERE ownerkey = ?')
X.SQLiteExecute(DB, [[
	CREATE TABLE IF NOT EXISTS ItemInfo (
		tabtype INTEGER NOT NULL,
		tabindex INTEGER NOT NULL,
		tabsubindex INTEGER NOT NULL,
		name NVARCHAR(20) NOT NULL,
		genre INTEGER NOT NULL,
		quality INTEGER NOT NULL,
		exist_type INTEGER NOT NULL,
		desc NVARCHAR(4000) NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(tabtype, tabindex, tabsubindex)
	)
]])
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS ItemInfo_name_idx ON ItemInfo(name)')
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS ItemInfo_desc_idx ON ItemInfo(desc)')
local DB_ItemInfoW = X.SQLitePrepare(DB, 'REPLACE INTO ItemInfo (tabtype, tabindex, tabsubindex, name, genre, quality, exist_type, desc, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')

local BOX_TYPE = X.KvpToObject({
	-- 100 - 199: Equip
	{X.CONSTANT.INVENTORY_INDEX.EQUIP, 100},
	{X.CONSTANT.INVENTORY_INDEX.EQUIP_BACKUP1, 101},
	{X.CONSTANT.INVENTORY_INDEX.EQUIP_BACKUP2, 102},
	{X.CONSTANT.INVENTORY_INDEX.EQUIP_BACKUP3, 103},
	-- 200 - 299: Bag
	{X.CONSTANT.INVENTORY_INDEX.PACKAGE, 200},
	{X.CONSTANT.INVENTORY_INDEX.PACKAGE1, 201},
	{X.CONSTANT.INVENTORY_INDEX.PACKAGE2, 202},
	{X.CONSTANT.INVENTORY_INDEX.PACKAGE3, 203},
	{X.CONSTANT.INVENTORY_INDEX.PACKAGE4, 204},
	{X.CONSTANT.INVENTORY_INDEX.PACKAGE_MIBAO, 205},
	-- 300 - 399: Bank
	{X.CONSTANT.INVENTORY_INDEX.BANK, 300},
	{X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE1, 301},
	{X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE2, 302},
	{X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE3, 303},
	{X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE4, 304},
	{X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE5, 305},
	-- 400 Deprecated Guild Bank
	-- 401 - 499: Guild Bank
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK, 401},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE1, 402},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE2, 403},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE3, 404},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE4, 405},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE5, 406},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE6, 407},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE7, 408},
	{X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE8, 409},
})

local O = X.CreateUserSettingsModule('MY_RoleStatistics_BagStat', _L['General'], {
	bCompactMode = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_BagStat'],
			_L['Switch compact mode'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bHideEquipped = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_BagStat'],
			_L['Hide equipped item'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tUncheckedNames = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_BagStat'],
			_L['Unchecked Names'],
		}),
		bNoExport = true,
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
	bFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_BagStat'],
			_L['Float panel'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		szDescription = X.MakeCaption({
			_L['MY_RoleStatistics_BagStat'],
			_L['Save DB'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	szFilterType = 'All',
	tCheckedNames = {},
}

local FILTER_LIST = {
	{ name = 'All'      , where = '' },
	{ name = 'Task'     , where = 'I.genre = 2' },
	{ name = 'Equipment', where = 'I.genre = 0' },
	{ name = 'Drug'     , where = 'I.genre = 1 OR genre = 14' },
	{ name = 'Material' , where = 'I.genre = 3' },
	{ name = 'Book'     , where = 'I.genre = 4' },
	{ name = 'Furniture', where = 'I.genre = 20', visible = X.IS_REMAKE },
	{ name = 'Grey'     , where = 'I.quality = 0' },
	{ name = 'TimeLtd'  , where = 'I.exist_type <> -1 AND I.exist_type <> ' .. ITEM_EXIST_TYPE.PERMANENT },
}

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
				l_tItemText[szKey] = X.GetPureText(X.GetItemTip(KItem), 'LUA') or ''
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
	local dwBox = X.CONSTANT.INVENTORY_GUILD_BANK_LIST[nPage + 1]
	local me = X.GetClientPlayer()
	for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
		local kItem = X.GetInventoryItem(me, dwBox, dwX)
		local boxtype, boxindex = dwBox, dwX
		local aItemData, aItemInfoData = D.ItemToData(kItem, 'BANK')
		l_guildcache[boxtype .. ',' .. boxindex] = {
			boxtype = boxtype,
			boxindex = boxindex,
			aItemData = aItemData,
			aItemInfoData = aItemInfoData,
		}
	end
end
X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_RoleStatistics_BagStat', UpdateTongRepertoryPage)

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/bag_stat.v2.db', X.PATH_TYPE.GLOBAL})
	local DB_V3_PATH = X.FormatPath({'userdata/role_statistics/bag_stat.v3.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V2_PATH) and not IsLocalFileExist(DB_V3_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			-- 转移V2旧版数据
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					X.SQLiteBeginTransaction(DB)
					local aBagItems = X.SQLiteGetAll(DB_V2, 'SELECT * FROM BagItems WHERE ownerkey IS NOT NULL AND boxtype IS NOT NULL AND tabtype IS NOT NULL')
					if aBagItems then
						for _, rec in ipairs(aBagItems) do
							local sboxtype = BOX_TYPE[rec.boxtype]
							if sboxtype then
								X.SQLitePrepareExecute(
									DB_ItemsW,
									rec.ownerkey,
									sboxtype,
									rec.boxindex,
									rec.tabtype,
									rec.tabindex,
									rec.tabsubindex,
									rec.bagcount,
									rec.bankcount,
									-1,
									-1,
									-1,
									-1,
									-1,
									'',
									-1,
									-1,
									'',
									rec.time,
									''
								)
							end
						end
					end
					local aOwnerInfo = X.SQLiteGetAll(DB_V2, 'SELECT * FROM OwnerInfo WHERE ownerkey IS NOT NULL')
					if aOwnerInfo then
						for _, rec in ipairs(aOwnerInfo) do
							X.SQLitePrepareExecute(
								DB_OwnerInfoW,
								rec.ownerkey,
								rec.ownername,
								rec.servername,
								rec.time,
								''
							)
						end
					end
					local aItemInfo = X.SQLiteGetAll(DB_V2, 'SELECT * FROM ItemInfo WHERE tabtype IS NOT NULL')
					if aItemInfo then
						for _, rec in ipairs(aItemInfo) do
							X.SQLitePrepareExecute(
								DB_ItemInfoW,
								rec.tabtype,
								rec.tabindex,
								rec.tabsubindex,
								rec.name,
								-1,
								-1,
								-1,
								rec.desc,
								''
							)
						end
					end
					X.SQLiteEndTransaction(DB)
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V3旧版数据
			if IsLocalFileExist(DB_V3_PATH) then
				local DB_V3 = SQLite3_Open(DB_V3_PATH)
				if DB_V3 then
					X.SQLiteBeginTransaction(DB)
					local aBagItems = X.SQLiteGetAll(DB_V3, 'SELECT * FROM BagItems WHERE ownerkey IS NOT NULL AND boxtype IS NOT NULL AND tabtype IS NOT NULL')
					if aBagItems then
						for _, rec in ipairs(aBagItems) do
							local sboxtype = BOX_TYPE[rec.boxtype]
							if sboxtype then
								X.SQLitePrepareExecute(
									DB_ItemsW,
									rec.ownerkey,
									sboxtype,
									rec.boxindex,
									rec.tabtype,
									rec.tabindex,
									rec.tabsubindex,
									rec.bagcount,
									rec.bankcount,
									rec.itemid,
									rec.uiid,
									rec.exist_time,
									rec.strength,
									rec.durability,
									rec.diamond_enchant,
									rec.fea_enchant,
									rec.permanent_enchant,
									rec.desc,
									rec.time,
									rec.extra
								)
							end
						end
					end
					local aOwnerInfo = X.SQLiteGetAll(DB_V3, 'SELECT * FROM OwnerInfo WHERE ownerkey IS NOT NULL')
					if aOwnerInfo then
						for _, rec in ipairs(aOwnerInfo) do
							X.SQLitePrepareExecute(
								DB_OwnerInfoW,
								rec.ownerkey,
								rec.ownername,
								rec.servername,
								rec.time,
								rec.extra
							)
						end
					end
					local aItemInfo = X.SQLiteGetAll(DB_V3, 'SELECT * FROM ItemInfo WHERE tabtype IS NOT NULL')
					if aItemInfo then
						for _, rec in ipairs(aItemInfo) do
							X.SQLitePrepareExecute(
								DB_ItemInfoW,
								rec.tabtype,
								rec.tabindex,
								rec.tabsubindex,
								rec.name,
								rec.genre,
								rec.quality,
								rec.exist_type,
								rec.desc,
								rec.extra
							)
						end
					end
					X.SQLiteEndTransaction(DB)
					DB_V3:Release()
				end
				CPath.Move(DB_V3_PATH, DB_V3_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			FireUIEvent('MY_ROLE_STAT_BAG_UPDATE')
			X.Alert(_L['Migrate succeed!'])
		end)
end

function D.ItemToData(KItem, szBagType)
	local KItemInfo = KItem and GetItemInfo(KItem.dwTabType, KItem.dwIndex)
	local tabtype, tabindex, tabsubindex, bagcount, bankcount = -1, -1, -1, 0, 0
	local itemid, uiid, exist_time, strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc = -1, -1, -1, -1, -1, '', -1, -1, ''
	local time, extra = GetCurrentTime(), ''
	local aItemInfoData
	if KItem and KItemInfo then
		tabtype = KItem.dwTabType
		tabindex = KItem.dwIndex
		tabsubindex = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
		aItemInfoData = {
			tabtype,
			tabindex,
			tabsubindex,
			AnsiToUTF8(KItem.szName),
			KItem.nGenre,
			KItem.nQuality,
			KItemInfo.nExistType,
			AnsiToUTF8(GetItemText(KItem)),
			''
		}

		local aDiamondEnchant = {}
		if KItem.nGenre == ITEM_GENRE.EQUIPMENT then
			for i = 1, KItem.GetSlotCount() do
				aDiamondEnchant[i] = X.GetItemMountDiamondEnchantID(KItem, i - 1)
			end
		end
		if szBagType == 'BANK' then
			bagcount = 0
			bankcount = KItem.bCanStack and KItem.nStackNum or 1
		else
			bagcount = KItem.bCanStack and KItem.nStackNum or 1
			bankcount = 0
		end
		itemid = KItem.dwID
		uiid = KItem.nUiId
		strength = X.GetItemStrengthLevel(KItem)
		durability = KItem.nCurrentDurability
		diamond_enchant = AnsiToUTF8(X.EncodeJSON(aDiamondEnchant)) -- 五行石
		fea_enchant = KItem.nSub == EQUIPMENT_SUB.MELEE_WEAPON and KItem.GetMountFEAEnchantID() or 0 -- 五彩石
		permanent_enchant = KItem.dwPermanentEnchantID -- 附魔
		desc = AnsiToUTF8(X.GetItemTip(KItem) or '')
	end
	local aItemData = {
		tabtype, tabindex, tabsubindex, bagcount, bankcount,
		itemid, uiid, exist_time, strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc,
		time, extra
	}
	return aItemData, aItemInfoData
end

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]
	local me = X.GetClientPlayer()
	local time = GetCurrentTime()
	local ownerkey = AnsiToUTF8(X.GetClientPlayerGlobalID())
	local ownername = AnsiToUTF8(me.szName)
	local servername = AnsiToUTF8(X.GetServerOriginName())
	X.SQLiteBeginTransaction(DB)

	-- 背包
	local aPackageBoxType = {}
	for _, v in ipairs(X.CONSTANT.INVENTORY_EQUIP_LIST) do
		table.insert(aPackageBoxType, v)
	end
	for _, v in ipairs(X.CONSTANT.INVENTORY_PACKAGE_LIST) do
		table.insert(aPackageBoxType, v)
	end
	for _, boxtype in ipairs(aPackageBoxType) do
		local sboxtype = BOX_TYPE[boxtype]
		if sboxtype then
			local count = X.GetInventoryBoxSize(boxtype)
			for boxindex = 0, count - 1 do
				local aItemData, aItemInfoData = D.ItemToData(X.GetInventoryItem(me, boxtype, boxindex))
				if aItemInfoData then
					X.SQLitePrepareExecute(DB_ItemInfoW, unpack(aItemInfoData))
				end
				X.SQLitePrepareExecute(DB_ItemsW, ownerkey, sboxtype, boxindex, unpack(aItemData))
			end
			X.SQLitePrepareExecute(DB_ItemsDL, ownerkey, sboxtype, count)
			--[[#DEBUG BEGIN]]
		else
			X.OutputDebugMessage('MY_RoleStatistics_BagStat', 'bag boxtype not in static map: ' .. boxtype, X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
		end
	end

	X.SQLitePrepareExecute(DB_OwnerInfoW, ownerkey, ownername, servername, time, '')

	-- 仓库
	for _, boxtype in ipairs(X.CONSTANT.INVENTORY_BANK_LIST) do
		local sboxtype = BOX_TYPE[boxtype]
		if sboxtype then
			local count = X.GetInventoryBoxSize(boxtype)
			for boxindex = 0, count - 1 do
				local aItemData, aItemInfoData = D.ItemToData(X.GetInventoryItem(me, boxtype, boxindex), 'BANK')
				if aItemInfoData then
					X.SQLitePrepareExecute(DB_ItemInfoW, unpack(aItemInfoData))
				end
				X.SQLitePrepareExecute(DB_ItemsW, ownerkey, sboxtype, boxindex, unpack(aItemData))
			end
			X.SQLitePrepareExecute(DB_ItemsDL, ownerkey, sboxtype, count)
			--[[#DEBUG BEGIN]]
		else
			X.OutputDebugMessage('MY_RoleStatistics_BagStat', 'bank boxtype not in static map: ' .. boxtype, X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
		end
	end

	-- 帮会仓库
	if not X.IsEmpty(l_guildcache) then
		local ownerkey = 'tong' .. me.dwTongID
		local ownername = AnsiToUTF8('[' .. X.GetTongName(me.dwTongID) .. ']')
		for _, info in pairs(l_guildcache) do
			local sboxtype = BOX_TYPE[info.boxtype]
			if sboxtype then
				if info.aItemInfoData then
					X.SQLitePrepareExecute(DB_ItemInfoW, unpack(info.aItemInfoData))
				end
				X.SQLitePrepareExecute(DB_ItemsW, ownerkey, sboxtype, info.boxindex, unpack(info.aItemData))
				--[[#DEBUG BEGIN]]
			else
				X.OutputDebugMessage('MY_RoleStatistics_BagStat', 'guild bank boxtype not in static map: ' .. info.boxtype, X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
			end
		end

		X.SQLitePrepareExecute(DB_OwnerInfoW, ownerkey, ownername, servername, time, '')
	end

	X.SQLiteEndTransaction(DB)
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.OutputDebugMessage('MY_RoleStatistics_BagStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
end
X.RegisterFlush('MY_RoleStatistics_BagStat', D.FlushDB)
end

do local INIT = false
function D.UpdateSaveDB()
	if not INIT then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_RoleStatistics_BagStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		for _, guid in ipairs({
			AnsiToUTF8(X.GetClientPlayerGlobalID()),
			'tong' .. me.dwTongID,
		}) do
			X.SQLitePrepareExecute(DB_ItemsDA, guid)
			X.SQLitePrepareExecute(DB_OwnerInfoD, guid)
		end
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_RoleStatistics_BagStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_BAG_UPDATE')
end
X.RegisterInit('MY_RoleStatistics_BagUpdateSaveDB', function()
	D.tCheckedNames[X.GetClientPlayerGlobalID()] = true
	INIT = true
end)
end

function D.UpdateNames(page)
	local searchname = page:Lookup('Wnd_Total/Wnd_SearchName/Edit_SearchName'):GetText()
	local result = X.SQLitePrepareGetAll(
		DB_OwnerInfoR,
		AnsiToUTF8('%' .. searchname .. '%'),
		AnsiToUTF8('%' .. searchname .. '%')
	)

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
		wnd:Lookup('CheckBox_Name'):Check(D.tCheckedNames[wnd.ownerkey], WNDEVENT_FIRETYPE.PREVENT)
	end
	container:FormatAllContentPos()
	page.nCurrentPage = 1
	D.UpdateItems(page)
end

function D.SaveNameChecks(container)
	-- local tUncheckedNames = {}
	-- for i = 0, container:GetAllContentCount() - 1 do
	-- 	local wnd = container:LookupContent(i)
	-- 	if not wnd:Lookup('CheckBox_Name'):IsCheckBoxChecked() then
	-- 		tUncheckedNames[wnd.ownerkey] = true
	-- 	end
	-- end
	-- O.tUncheckedNames = tUncheckedNames
end

function D.UpdateItems(page)
	D.FlushDB()

	local searchitem = AnsiToUTF8('%' .. page:Lookup('Wnd_Total/Wnd_SearchItem/Edit_SearchItem'):GetText():gsub('%s+', '%%') .. '%')
	local sqlfilter = ''
	for _, p in ipairs(FILTER_LIST) do
		if p.name == D.szFilterType and not X.IsEmpty(p.where) then
			sqlfilter = sqlfilter .. ' AND (' .. p.where .. ') '
		end
	end
	if O.bHideEquipped then
		sqlfilter = sqlfilter .. ' AND B.boxtype >= 200 '
	end
	local sqlfrom = [[
		(
			SELECT B.ownerkey, B.boxtype, B.boxindex, B.tabtype, B.tabindex, B.tabsubindex, B.strength, B.uiid, B.desc as itemtip, B.bagcount, B.bankcount, B.time
				FROM BagItems
				AS B
			LEFT JOIN ItemInfo
				AS I
			ON
				B.tabtype = I.tabtype AND B.tabindex = I.tabindex
			WHERE
				B.tabtype != -1 AND B.tabindex != -1 AND B.boxtype != 400 AND (I.name LIKE ? OR I.desc LIKE ?) ]] .. sqlfilter .. [[
		)
			AS C
		LEFT JOIN OwnerInfo
			AS O
		ON C.ownerkey = O.ownerkey
		WHERE
	]]
	local sql  = [[
		SELECT
			C.ownerkey AS ownerkey,
			C.boxtype AS boxtype,
			C.boxindex AS boxindex,
			C.tabtype AS tabtype,
			C.tabindex AS tabindex,
			C.tabsubindex AS tabsubindex,
			C.strength AS strength,
			C.uiid AS uiid,
			C.itemtip AS itemtip,
			SUM(C.bagcount) AS bagcount,
			SUM(C.bankcount) AS bankcount,
			C.time AS time,
			O.ownername AS ownername,
			O.servername AS servername
		FROM
	]] .. sqlfrom
	local sqlc = 'SELECT COUNT(*) AS count FROM' .. sqlfrom
	local nPageSize = O.bCompactMode and COMPACT_MODE_PAGE_SIZE or NORMAL_MODE_PAGE_SIZE
	local wheres = {}
	local ownerkeys = {}
	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup('CheckBox_Name'):IsCheckBoxChecked() then
			table.insert(wheres, 'O.ownerkey = ?')
			table.insert(ownerkeys, AnsiToUTF8(wnd.ownerkey))
		end
	end
	local sqlwhere = ((#wheres == 0 and ' 1 = 0 ') or ('(' .. table.concat(wheres, ' OR ') .. ')'))
	local sqlgroup = ' GROUP BY C.tabtype, C.tabindex'
	sql  = sql  .. sqlwhere .. sqlgroup .. ' ORDER BY C.tabtype ASC, C.tabindex ASC ' .. ' LIMIT ' .. nPageSize .. ' OFFSET ' .. ((page.nCurrentPage - 1) * nPageSize)
	sqlc = sqlc .. sqlwhere .. sqlgroup

	-- 绘制页码
	local DB_CountR = X.SQLitePrepare(DB, sqlc)
	local nCount = #X.SQLitePrepareGetAll(
		DB_CountR,
		searchitem,
		searchitem,
		unpack(ownerkeys)
	)
	local nPageCount = math.floor(nCount / nPageSize) + 1
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
		if page.nCurrentPage + math.ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif page.nCurrentPage - math.ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = page.nCurrentPage - math.ceil((PAGE_DISPLAY - 2) / 2)
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
	local result = X.SQLiteGetAll(
		DB,
		sql,
		searchitem,
		searchitem,
		unpack(ownerkeys)
	)

	local sqlbelongs = 'SELECT * FROM (SELECT ownerkey, SUM(bagcount) AS bagcount, SUM(bankcount) AS bankcount FROM BagItems WHERE tabtype = ? AND tabindex = ? AND tabsubindex = ? GROUP BY ownerkey) AS B LEFT JOIN OwnerInfo AS O ON B.ownerkey = O.ownerkey WHERE '
	sqlbelongs = sqlbelongs .. ((#wheres == 0 and ' 1 = 0 ') or ('(' .. table.concat(wheres, ' OR ') .. ')'))
	local DB_BelongsR = X.SQLitePrepare(DB, sqlbelongs)

	local handle = page:Lookup('Wnd_Total/WndScroll_Item', 'Handle_Items')
	local scroll = page:Lookup('Wnd_Total/WndScroll_Item/Scroll_Item')
	handle:Clear()
	for _, rec in ipairs(result) do
		local KItemInfo = GetItemInfo(rec.tabtype, rec.tabindex)
		if KItemInfo then
			local bMaxStrength = KItemInfo.nMaxStrengthLevel > 0 and rec.strength == KItemInfo.nMaxStrengthLevel
			if O.bCompactMode then
				local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_ItemCompact')
				local box = hItem:Lookup('Box_ItemCompact')
				local result = X.SQLitePrepareGetAll(DB_BelongsR, rec.tabtype, rec.tabindex, rec.tabsubindex, unpack(ownerkeys))
				local count = 0
				for _, rec in ipairs(result) do
					count = count + rec.bankcount + rec.bagcount
				end
				X.UI.UpdateItemInfoBoxObject(box, nil, rec.tabtype, rec.tabindex, count, rec.tabsubindex)
				UpdateItemBoxExtend(box, KItemInfo.nGenre, KItemInfo.nQuality, bMaxStrength)
				box.itemdata = rec
				box.belongsdata = result
			else
				local hItem = handle:AppendItemFromIni(SZ_INI, 'Handle_Item')
				X.UI.UpdateItemInfoBoxObject(hItem:Lookup('Box_Item'), nil, rec.tabtype, rec.tabindex, 1, rec.tabsubindex)
				X.UI.UpdateItemInfoBoxObject(hItem:Lookup('Handle_ItemInfo/Text_ItemName'), nil, rec.tabtype, rec.tabindex, 1, rec.tabsubindex)
				UpdateItemBoxExtend(hItem:Lookup('Box_Item'), KItemInfo.nGenre, KItemInfo.nQuality, bMaxStrength)
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

				local result = X.SQLitePrepareGetAll(DB_BelongsR, rec.tabtype, rec.tabindex, rec.tabsubindex, unpack(ownerkeys))
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
			X.OutputDebugMessage('MY_RoleStatistics_BagStat', 'KItemInfo not found: ' .. rec.tabtype .. ', ' .. rec.tabindex, X.DEBUG_LEVEL.WARNING)
		--[[#DEBUG END]]
		end
	end
	handle:FormatAllItemPos()
	scroll:SetScrollPos(0)
end

function D.OnInitPage()
	local frameTemp = X.UI.OpenFrame(SZ_INI, 'MY_RoleStatistics_BagStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	X.UI.CloseFrame(frameTemp)
	X.UI.AdaptComponentAppearance(wnd:Lookup('WndScroll_Name/Scroll_Name'))
	X.UI.AdaptComponentAppearance(wnd:Lookup('WndScroll_Item/Scroll_Item'))

	local page = this
	local ui = X.UI(page)
	local nX, nY = 440, 20
	for _, p in ipairs(FILTER_LIST) do
		nX = nX + ui:Append('WndRadioBox', {
			x = nX, y = nY, w = 'auto', h = 25,
			group = 'FilterType',
			text = _L.BAG_FILTER_TYPE[p.name],
			checked = D.szFilterType == p.name,
			onCheck = function(bChecked)
				if not bChecked then
					return
				end
				D.szFilterType = p.name
				D.UpdateItems(page)
			end,
		}):AutoWidth():Width()
	end

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_BAGSTATISTICS_MODE_CHANGE')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_BAG_UPDATE')

	D.OnResizePage()
end

function D.OnResizePage()
	local page = this
	local ui = X.UI(page)
	local nW, nH = ui:Size()

	page:Lookup('Wnd_Total'):SetSize(nW, nH)
	page:Lookup('Wnd_Total/WndScroll_Name'):SetH(nH - 78)
	page:Lookup('Wnd_Total/WndScroll_Name', 'Image_Name'):SetH(nH - 78)
	page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name'):SetH(nH - 108)
	page:Lookup('Wnd_Total/WndScroll_Name/Scroll_Name'):SetH(nH - 108)
	page:Lookup('Wnd_Total/WndScroll_Name/Btn_NameAll'):SetRelY(nH - 90)
	page:Lookup('Wnd_Total/WndScroll_Name/Wnd_SearchInfo'):SetRelY(nH - 103)
	page:Lookup('Wnd_Total/WndScroll_Item'):SetSize(nW - 220, nH - 109)
	page:Lookup('Wnd_Total/WndScroll_Item', ''):SetSize(nW - 220, nH - 109)
	page:Lookup('Wnd_Total/WndScroll_Item', 'Image_Item'):SetSize(nW - 235, nH - 109)
	page:Lookup('Wnd_Total/WndScroll_Item', 'Handle_Items'):SetSize(nW - 235, nH - 121)
	page:Lookup('Wnd_Total/WndScroll_Item', 'Handle_Items'):FormatAllItemPos()
	page:Lookup('Wnd_Total/WndScroll_Item', ''):FormatAllItemPos()
	page:Lookup('Wnd_Total/WndScroll_Item/Scroll_Item'):SetRelX(nW - 235)
	page:Lookup('Wnd_Total/WndScroll_Item/Scroll_Item'):SetH(nH - 83)
	page:Lookup('Wnd_Total/Wnd_Index'):SetRelY(nH - 58)
	page:Lookup('Wnd_Total/Wnd_Index'):SetW(nW - 235)
	page:Lookup('Wnd_Total/Wnd_Index', ''):SetW(nW - 235)
	page:Lookup('Wnd_Total/Wnd_Index', 'Image_Index'):SetW(nW - 235)
	page:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexesOuter'):SetW(nW - 341)
	page:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexesOuter'):FormatAllItemPos()
	page:Lookup('Wnd_Total/Wnd_Index/Wnd_IndexEdit'):SetRelX(nW - 275)

	PAGE_DISPLAY = math.max(15, math.floor((nW - 341) / 35))
	NORMAL_MODE_PAGE_SIZE = math.max(50, math.ceil(nH / 150))
	COMPACT_MODE_PAGE_SIZE = math.max(150, math.floor((nW - 235) / 51) * math.ceil((nH - 121) / 51))
	D.UpdateNames(this)
end

function D.OnActivePage()
	D.Migration()

	if not O.bAdviceSaveDB and not O.bSaveDB then
		X.Confirm(_L('%s stat has not been enabled, this character\'s data will not be saved, are you willing to save this character?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]), function()
			MY_RoleStatistics_BagStat.bSaveDB = true
			MY_RoleStatistics_BagStat.bAdviceSaveDB = true
		end, function()
			MY_RoleStatistics_BagStat.bAdviceSaveDB = true
		end)
	end

	D.UpdateNames(this)
end

function D.OnEvent(event)
	if event == 'MY_BAGSTATISTICS_MODE_CHANGE' then
		D.UpdateItems(this)
	elseif event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateNames(this)
	elseif event == 'MY_ROLE_STAT_BAG_UPDATE' then
		D.FlushDB()
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
		D.SaveNameChecks(this:GetParent():GetParent())
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Name' then
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		D.UpdateItems(page)
		D.SaveNameChecks(this:GetParent():GetParent())
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
		X.Confirm(_L('Are you sure to delete item record of %s?', wnd.ownername), function()
			X.SQLitePrepareExecute(DB_ItemsDA, wnd.ownerkey)
			X.SQLitePrepareExecute(DB_OwnerInfoD, wnd.ownerkey)
			D.UpdateNames(page)
		end)
	elseif name == 'Btn_SwitchMode' then
		X.UI.PopupMenu({
			{
				szOption = _L['Switch compact mode'],
				bCheck = true, bChecked = MY_RoleStatistics_BagStat.bCompactMode,
				fnAction = function ()
					MY_RoleStatistics_BagStat.bCompactMode = not MY_RoleStatistics_BagStat.bCompactMode
					X.UI.ClosePopupMenu()
				end,
			},
			{
				szOption = _L['Hide equipped item'],
				bCheck = true, bChecked = MY_RoleStatistics_BagStat.bHideEquipped,
				fnAction = function ()
					MY_RoleStatistics_BagStat.bHideEquipped = not MY_RoleStatistics_BagStat.bHideEquipped
					X.UI.ClosePopupMenu()
				end,
			},
		})
	elseif name == 'Btn_NameAll' then
		local parent = this:GetParent():Lookup('WndContainer_Name')
		local page = this:GetParent():GetParent():GetParent()
		for i = 0, parent:GetAllContentCount() - 1 do
			local wnd = parent:LookupContent(i)
			wnd:Lookup('CheckBox_Name'):Check(true, WNDEVENT_FIRETYPE.PREVENT)
		end
		D.UpdateItems(page)
		D.SaveNameChecks(parent)
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
	if this.itemdata and this.belongsdata then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()

		local rec = this.itemdata
		local aXml = {}

		if X.IsEmpty(rec.itemtip) then
			table.insert(aXml, GetItemInfoTip(nil, rec.tabtype, rec.tabindex, nil, nil, rec.tabsubindex) or '')
		else
			table.insert(aXml, UTF8ToAnsi(rec.itemtip) or '')
		end

		if IsCtrlKeyDown() then
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(aXml, GetFormatText('ItemInfo: ' .. rec.tabtype .. ', ' .. rec.tabindex, 102))
			if rec.tabsubindex ~= -1 then
				table.insert(aXml, GetFormatText('ItemInfo: ' .. rec.tabsubindex, 102))
			end
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(aXml, GetFormatText('Box: ' .. rec.boxtype .. ', ' .. rec.boxindex, 102))
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(aXml, GetFormatText('IconID: ' .. (Table_GetItemIconID(rec.uiid) or ''), 102))
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(aXml, GetFormatText('Strength: ' .. rec.strength, 102))
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
		end

		local aBelongsTip = {}
		for _, rec in ipairs(this.belongsdata) do
			table.insert(aBelongsTip, _L('%s (%s)\tBankx%d Bagx%d Totalx%d\n', UTF8ToAnsi(rec.ownername), UTF8ToAnsi(rec.servername), rec.bankcount, rec.bagcount, rec.bankcount + rec.bagcount))
		end
		table.insert(aXml, GetFormatText(table.concat(aBelongsTip)))

		OutputTip(table.concat(aXml), 400, {x, y, w, h, false}, nil, false)
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
			X.FormatTime(this.time, '%yyyy-%MM-%dd %hh:%mm:%ss')), nil, 255, 255, 0), 400, {x, y, w, h, false}, nil, false)
	elseif name == 'CheckBox_Name' then
		X.ExecuteWithThis(this:GetParent(), D.OnMouseEnter)
	end
end

-- 浮动框
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/BigBagPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_BagEntry')
	if bFloatEntry then
		if btn then
			return
		end
		local nX, nY = 90, 7
		if X.UI.IS_GLASSMORPHISM then
			nX, nY = 14, 3
		end
		local frameTemp = X.UI.OpenFrame(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_BagEntry.ini', 'MY_RoleStatistics_BagEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_BagEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(nX, nY)
		if X.UI.IS_GLASSMORPHISM then
			X.UI.SetButtonUITex(
				btn,
				'ui\\image\\UItimate\\UICommon\\Button11.UITex',
				0,
				1,
				2,
				3
			)
		end
		X.UI.CloseFrame(frameTemp)
		btn.OnLButtonClick = function()
			MY_RoleStatistics.Open('BagStat')
		end
	else
		if not btn then
			return
		end
		btn:Destroy()
	end
end

function D.UpdateFloatEntry()
	if not D.bReady then
		return
	end
	D.ApplyFloatEntry(O.bFloatEntry)
end

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics_BagStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnResizePage',
				szSaveDB = 'MY_RoleStatistics_BagStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_BagStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('BagStat', _L['MY_RoleStatistics_BagStat'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics_BagStat',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'bCompactMode',
				'bHideEquipped',
				'tUncheckedNames',
				'bSaveDB',
				'bAdviceSaveDB',
				'bFloatEntry',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bCompactMode',
				'bHideEquipped',
				'tUncheckedNames',
				'bSaveDB',
				'bAdviceSaveDB',
				'bFloatEntry',
			},
			triggers = {
				bCompactMode = function()
					FireUIEvent('MY_BAGSTATISTICS_MODE_CHANGE')
				end,
				bHideEquipped = function()
					FireUIEvent('MY_BAGSTATISTICS_MODE_CHANGE')
				end,
				bSaveDB = D.UpdateSaveDB,
				bFloatEntry = D.UpdateFloatEntry,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_BagStat = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_RoleStatistics_BagStat', function()
	D.bReady = true
	D.UpdateFloatEntry()
end)

X.RegisterExit('MY_RoleStatistics_BagStat', function()
	if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
	end
end)

X.RegisterReload('MY_RoleStatistics_BagStat', function()
	D.ApplyFloatEntry(false)
end)

X.RegisterFrameCreate('BigBagPanel', 'MY_RoleStatistics_BagStat', function()
	D.UpdateFloatEntry()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
