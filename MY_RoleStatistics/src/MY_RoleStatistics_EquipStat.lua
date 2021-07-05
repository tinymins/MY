--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 装备统计
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
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_EquipStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

local DB = LIB.SQLiteConnect(_L['MY_RoleStatistics_EquipStat'], {'userdata/role_statistics/equip_stat.v2.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_EquipStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_EquipStat.ini'

DB:Execute([[
	CREATE TABLE IF NOT EXISTS EquipItems (
		ownerkey NVARCHAR(20),
		suitindex INTEGER,
		boxtype INTEGER,
		boxindex INTEGER,
		itemid INTEGER,
		tabtype INTEGER,
		tabindex INTEGER,
		tabsubindex INTEGER,
		stacknum INTEGER,
		uiid INTEGER,
		strength INTEGER,
		durability INTEGER,
		diamond_enchant NVARCHAR(100),
		fea_enchant INTEGER,
		permanent_enchant INTEGER,
		desc NVARCHAR(4000),
		extra NVARCHAR(4000),
		time INTEGER,
		PRIMARY KEY(ownerkey, boxtype, boxindex)
	)
]])
DB:Execute('CREATE INDEX IF NOT EXISTS EquipItems_tab_idx ON EquipItems(tabtype, tabindex, tabsubindex)')
local DB_ItemsW = DB:Prepare([[
	REPLACE INTO
	EquipItems (ownerkey, suitindex, boxtype, boxindex, itemid, tabtype, tabindex, tabsubindex, stacknum, uiid, strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc, extra, time)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]])
local DB_ItemsR = DB:Prepare('SELECT * FROM EquipItems WHERE ownerkey = ? and suitindex = ?')
local DB_ItemsDL = DB:Prepare('DELETE FROM EquipItems WHERE ownerkey = ? AND boxtype = ? AND boxindex >= ?')
local DB_ItemsDA = DB:Prepare('DELETE FROM EquipItems WHERE ownerkey = ?')

DB:Execute([[
	CREATE TABLE IF NOT EXISTS OwnerInfo (
		ownerkey NVARCHAR(20),
		ownername NVARCHAR(20),
		ownerforce INTEGER,
		servername NVARCHAR(20),
		ownerrole INTEGER,
		ownerscore INTEGER,
		ownersuitindex INTEGER,
		ownerextra NVARCHAR(4000),
		time INTEGER,
		PRIMARY KEY(ownerkey)
	)
]])
DB:Execute('CREATE INDEX IF NOT EXISTS OwnerInfo_ownername_idx ON OwnerInfo(ownername)')
DB:Execute('CREATE INDEX IF NOT EXISTS OwnerInfo_servername_idx ON OwnerInfo(servername)')
local DB_OwnerInfoW = DB:Prepare('REPLACE INTO OwnerInfo (ownerkey, ownername, ownerforce, servername, ownerrole, ownerscore, ownersuitindex, ownerextra, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_OwnerInfoR = DB:Prepare('SELECT * FROM OwnerInfo WHERE ownername LIKE ? OR servername LIKE ? ORDER BY time DESC')
local DB_OwnerInfoD = DB:Prepare('DELETE FROM OwnerInfo WHERE ownerkey = ?')
local EQUIPMENT_ITEM_LIST = {
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.HELM or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.HELM,
		box = 'Handle_Equip/Box_Helm',
		durability = 'Handle_Equip/Text_Helm',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.CHEST or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.CHEST,
		box = 'Handle_Equip/Box_Chest',
		durability = 'Handle_Equip/Text_Chest',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.BANGLE or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.BANGLE,
		box = 'Handle_Equip/Box_Bangle',
		durability = 'Handle_Equip/Text_Bangle',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.WAIST or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.WAIST,
		box = 'Handle_Equip/Box_Waist',
		durability = 'Handle_Equip/Text_Waist',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.PANTS or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.PANTS,
		box = 'Handle_Equip/Box_Pants',
		durability = 'Handle_Equip/Text_Pants',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.BOOTS or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.BOOTS,
		box = 'Handle_Equip/Box_Boots',
		durability = 'Handle_Equip/Text_Boots',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.AMULET or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.AMULET,
		box = 'Handle_Equip/Box_Amulet'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.PENDANT or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.PENDANT,
		box = 'Handle_Equip/Box_Pendant'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.RING or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING,
		box = 'Handle_Equip/Box_LeftRing'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.RING or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING,
		box = 'Handle_Equip/Box_RightRing'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON,
		box = 'Handle_Weapon/Box_LightSword',
		durability = 'Handle_Weapon/Text_LightSword',
	},
	{
		label = g_tStrings.WeapenDetail[WEAPON_DETAIL.BIG_SWORD or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD,
		box = 'Handle_Weapon/Box_HeavySword',
		durability = 'Handle_Weapon/Text_HeavySword',
		force = CONSTANT.FORCE_TYPE.CANG_JIAN,
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON,
		box = 'Handle_Weapon/Box_RangeWeapon',
		durability = 'Handle_Weapon/Text_RangeWeapon',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[CONSTANT.EQUIPMENT_SUB.ARROW or 'NULL'],
		pos = CONSTANT.EQUIPMENT_INVENTORY.ARROW,
		box = 'Handle_Weapon/Box_AmmoPouch'
	},
}
local EQUIPMENT_EXTRA_ITEM_LIST = {
	{ key = 'waist'    , box = 'Handle_Equip/Box_Waist_Extend'     }, -- EQUIPMENT_SUB.WAIST_EXTEND
	{ key = 'back'     , box = 'Handle_Equip/Box_Back_Extend'      }, -- EQUIPMENT_SUB.BACK_EXTEND
	{ key = 'face'     , box = 'Handle_Equip/Box_Helm_Extend'      }, -- EQUIPMENT_SUB.FACE_EXTEND
	{ key = 'lshoulder', box = 'Handle_Equip/Box_LShoulder_Extend' }, -- EQUIPMENT_SUB.L_SHOULDER_EXTEND
	{ key = 'rshoulder', box = 'Handle_Equip/Box_RShoulder_Extend' }, -- EQUIPMENT_SUB.R_SHOULDER_EXTEND
	{ key = 'backcloak', box = 'Handle_Equip/Box_BackCloak_Extend' }, -- EQUIPMENT_SUB.BACK_CLOAK_EXTEND
	{ key = 'bag'      , box = 'Handle_Equip/Box_Bag'              }, -- EQUIPMENT_SUB.BAG_EXTEND
	{ key = 'glasses'  , box = 'Handle_Equip/Box_Glasses'          }, -- EQUIPMENT_SUB.GLASSES_EXTEND
	{ key = 'lglove'   , box = 'Handle_Equip/Box_LHand_Extend'     }, -- EQUIPMENT_SUB.L_GLOVE_EXTEND
	{ key = 'rglove'   , box = 'Handle_Equip/Box_RHand_Extend'     }, -- EQUIPMENT_SUB.R_GLOVE_EXTEND
	{ key = 'penpet'   , box = 'Handle_Equip/Box_PendantPet'       }, --
}

local O = LIB.CreateUserSettingsModule('MY_RoleStatistics_EquipStat', _L['General'], {
	bCompactMode = {
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bSaveDB = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	szCurrentOwnerKey = nil,
	dwCurrentSuitIndex = 1,
}

function D.GetPlayerGUID(me)
	return me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName
end

local function GetEquipRecipeDesc(Value1, Value2)
	local szText = ''
	local tRecipeSkillAtrri = g_tTable.EquipmentRecipe:Search(Value1, Value2)
	if tRecipeSkillAtrri then
		szText = tRecipeSkillAtrri.szDesc
	end
	return szText
end

function D.FormatEnchantAttribText(v)
	if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
		local skillEvent = g_tTable.SkillEvent:Search(v.nValue1)
		if skillEvent then
			return FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
		else
			return '<text>text="unknown skill event id:' .. v.nValue1 .. '"</text>'
		end
	elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
		return GetEquipRecipeDesc(v.nValue1, v.nValue2)
	else
		FormatAttributeValue(v)
		return FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
	end
end

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_EquipStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local me = GetClientPlayer()
	local time = GetCurrentTime()
	local ownerkey = AnsiToUTF8(D.GetPlayerGUID(me))
	local ownername = AnsiToUTF8(me.szName)
	local ownerforce = me.dwForceID
	local servername = AnsiToUTF8(LIB.GetRealServer(2))
	local ownerrole = 0
	local ownerscore = 0
	local ownersuitindex = 0
	local ownerextra = ''
	DB:Execute('BEGIN TRANSACTION')

	-- 背包
	for suitindex, _ in ipairs(CONSTANT.INVENTORY_EQUIP_LIST) do
		local boxtype = CONSTANT.INVENTORY_EQUIP_LIST[me.GetEquipIDArray(suitindex - 1) + 1]
		local count = me.GetBoxSize(boxtype)
		for boxindex = 0, count - 1 do
			local KItem = GetPlayerItem(me, boxtype, boxindex)
			DB_ItemsW:ClearBindings()
			local itemid, tabtype, tabindex, tabsubindex = -1, -1, -1, -1
			local stacknum, uiid, strength, durability = 0, 0, 0, 0
			local diamond_enchant, fea_enchant, permanent_enchant, desc, extra = 0, 0, 0, '', ''
			if KItem then
				local aDiamondEnchant = {}
				for i = 1, KItem.GetSlotCount() do
					aDiamondEnchant[i] = KItem.GetMountDiamondEnchantID(i)
				end
				itemid = KItem.dwID
				tabtype = KItem.dwTabType
				tabindex = KItem.dwIndex
				tabsubindex = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
				stacknum = KItem.bCanStack and KItem.nStackNum or 1
				uiid = KItem.nUiId
				strength = KItem.nStrengthLevel
				durability = KItem.nCurrentDurability
				diamond_enchant = AnsiToUTF8(LIB.JsonEncode(aDiamondEnchant)) -- 五行石
				fea_enchant = KItem.nSub == EQUIPMENT_SUB.MELEE_WEAPON and KItem.GetMountFEAEnchantID() or 0 -- 五彩石
				permanent_enchant = KItem.dwPermanentEnchantID -- 附魔
				desc = AnsiToUTF8(GetItemTip(KItem) or '')
			end
			DB_ItemsW:BindAll(
				ownerkey, suitindex, boxtype, boxindex, itemid,
				tabtype, tabindex, tabsubindex, stacknum, uiid,
				strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc, extra, time)
			DB_ItemsW:Execute()
		end
		DB_ItemsDL:ClearBindings()
		DB_ItemsDL:BindAll(ownerkey, boxtype, count)
		DB_ItemsDL:Execute()
	end

	-- 挂饰、其它
	ownerrole = me.nRoleType
	ownerscore = me.GetTotalEquipScore() or 0
	ownersuitindex = me.GetEquipIDArray(0) + 1
	ownerextra = AnsiToUTF8(LIB.JsonEncode({
		waist = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwWaistItemIndex) },
		back = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwBackItemIndex) },
		face = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwFaceItemIndex) },
		lshoulder = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwLShoulderItemIndex) },
		rshoulder = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwRShoulderItemIndex) },
		backcloak = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwBackCloakItemIndex) },
		bag = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwBagItemIndex) },
		glasses = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwGlassesItemIndex) },
		lglove = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.GetSelectPendent and me.GetSelectPendent(KPENDENT_TYPE.LGLOVE)) },
		rglove = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.GetSelectPendent and me.GetSelectPendent(KPENDENT_TYPE.RGLOVE)) },
		penpet = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.GetEquippedPendentPet()) },
	}))

	DB_OwnerInfoW:ClearBindings()
	DB_OwnerInfoW:BindAll(ownerkey, ownername, ownerforce, servername, ownerrole, ownerscore, ownersuitindex, ownerextra, time)
	DB_OwnerInfoW:Execute()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_EquipStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_EquipStat', D.FlushDB)

do local INIT = false
function D.UpdateSaveDB()
	if not INIT then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_EquipStat', 'Remove from database...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local guid = AnsiToUTF8(D.GetPlayerGUID(me))
		DB_ItemsDA:ClearBindings()
		DB_ItemsDA:BindAll(guid)
		DB_ItemsDA:Execute()
		DB_OwnerInfoD:ClearBindings()
		DB_OwnerInfoD:BindAll(guid)
		DB_OwnerInfoD:Execute()
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_RoleStatistics_EquipStat', 'Remove from database finished...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_EQUIP_UPDATE')
end
LIB.RegisterInit('MY_RoleStatistics_BagUpdateSaveDB', function() INIT = true end)
end

function D.UpdateNames(page)
	local searchname = page:Lookup('Wnd_Total/Wnd_SearchName/Edit_SearchName'):GetText()
	DB_OwnerInfoR:ClearBindings()
	DB_OwnerInfoR:BindAll(AnsiToUTF8('%' .. searchname .. '%'), AnsiToUTF8('%' .. searchname .. '%'))
	local result = DB_OwnerInfoR:GetAll()

	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	container:Clear()
	for _, rec in ipairs(result) do
		for k, v in pairs(rec) do
			if IsString(v) then
				rec[k] = UTF8ToAnsi(v)
			end
		end
		rec.ownerextra = LIB.JsonDecode(rec.ownerextra or '') or {}
	end
	if result[1] and not lodash.some(result, function(r) return r.ownerkey == D.szCurrentOwnerKey end) then
		D.szCurrentOwnerKey = result[1].ownerkey
	end
	for _, rec in ipairs(result) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_Name')
		wnd.time = rec.time
		wnd.ownerkey   = rec.ownerkey
		wnd.ownername  = rec.ownername
		wnd.ownerforce = rec.ownerforce
		wnd.servername = rec.servername
		wnd.ownerrole = rec.ownerrole
		wnd.ownerscore = rec.ownerscore
		wnd.ownersuitindex = rec.ownersuitindex
		wnd.ownerextra = rec.ownerextra
		local ownername = wnd.ownername
		if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
			ownername = MY_ChatMosaics.MosaicsString(ownername)
		end
		wnd:Lookup('', 'Text_Name'):SetText(ownername .. ' (' .. wnd.servername .. ')')
	end
	container:FormatAllContentPos()
	D.UpdateItems(page)
end

function D.UpdateItems(page)
	D.FlushDB()

	-- 刷新装备套数选择
	local container = page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_PageNum/WndContainer_PageNum')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		wnd:Lookup('CheckBox_PageNum'):Check(wnd.nSuitIndex == D.dwCurrentSuitIndex, WNDEVENT_FIRETYPE.PREVENT)
	end

	-- 获取角色数据
	local ownername = ''
	local ownerforce = -1
	local ownerrole = 0
	local ownerscore = 0
	local ownersuitindex = 0
	local ownerextra = {}
	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd.ownerkey == D.szCurrentOwnerKey then
			ownername = wnd.ownername
			ownerforce = wnd.ownerforce
			ownerrole = wnd.ownerrole
			ownerscore = wnd.ownerscore
			ownersuitindex = wnd.ownersuitindex
		end
	end
	if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
		ownername = MY_ChatMosaics.MosaicsString(ownername)
	end

	-- 绘制右侧详情
	local aXml = {}

	-- 绘制装备
	DB_ItemsR:ClearBindings()
	DB_ItemsR:BindAll(AnsiToUTF8(D.szCurrentOwnerKey), D.dwCurrentSuitIndex)
	local tResult = {}
	for _, rec in ipairs(DB_ItemsR:GetAll()) do
		for k, v in pairs(rec) do
			if IsString(v) then
				rec[k] = UTF8ToAnsi(v)
			end
			rec.diamond_enchant = LIB.JsonDecode(rec.diamond_enchant) or {}
		end
		tResult[rec.boxindex] = rec
	end
	local handle = page:Lookup('Wnd_Total/Wnd_ItemPage', '')
	-- local nTitleLen = 0
	-- for _, info in ipairs(EQUIPMENT_ITEM_LIST) do
	-- 	nTitleLen = max(wlen(info.label or '') + 1, nTitleLen)
	-- end
	for _, info in ipairs(EQUIPMENT_ITEM_LIST) do
		local visible = info.label and (not info.force or info.force == ownerforce)
		local rec = visible and info.pos and tResult[info.pos]
		local box = info.box and handle:Lookup(info.box)
		local txtDurability = info.durability and handle:Lookup(info.durability)
		if visible then
			local szPos = info.label or ''
			szPos = szPos .. g_tStrings.STR_COLON
			-- szPos = szPos .. rep(g_tStrings.STR_ONE_CHINESE_SPACE, nTitleLen - wlen(szPos))
			insert(aXml, GetFormatText(szPos, 162))
		end
		if rec and rec.tabtype >= 0 then
			local KItemInfo = GetItemInfo(rec.tabtype, rec.tabindex)
			if KItemInfo then
				if box then
					UI.UpdateItemInfoBoxObject(box, nil, rec.tabtype, rec.tabindex, rec.stacknum, rec.tabsubindex)
					UpdateItemBoxExtend(box, KItemInfo.nGenre, KItemInfo.nQuality, rec.strength)
					box.OnItemMouseEnter = nil
					box.OnItemRefreshTip = nil
					box.tip = rec.desc
				end
				if txtDurability then
					local nDurability = floor(rec.durability / KItemInfo.nMaxDurability * 100)
					local nFont = 167
					if nDurability < 30 then
						nFont = 159
					elseif nDurability <= 70 then
						nFont = 16
					end
					txtDurability:SetFontScheme(nFont)
					txtDurability:SetText(nDurability .. '%')
				end
				insert(aXml, GetFormatText('[' .. KItemInfo.szName .. ']', 162, GetItemFontColorByQuality(KItemInfo.nQuality)))
				-- 强化等级
				for _ = 1, rec.strength do
					insert(aXml, '<image>w=16 h=16 path="ui/Image/UICommon/FEPanel.UITex" frame=39 </image>')
				end
				-- 五行石
				for _, nEnchantID in ipairs(rec.diamond_enchant) do
					local nType, nTabIndex = GetDiamondInfoFromEnchantID(nEnchantID)
					local diamon = nType and nTabIndex and GetItemInfo(nType, nTabIndex)
					if diamon then
						insert(aXml, '<image>w=24 h=24 path="fromiconid" frame=' .. Table_GetItemIconID(diamon.nUiId) .. '</image>')
					else
						insert(aXml, '<image>w=24 h=24 path="ui/Image/UICommon/FEPanel.UITex" frame=5 </image>')
					end
				end
				-- 附魔
				if rec.permanent_enchant ~= 0 then
					local szImagePath = 'ui/Image/UICommon/FEPanel.UITex'
					local nFrame = 41
					local szText = Table_GetCommonEnchantDesc(rec.permanent_enchant)
					if szText then
						szText = gsub(szText, 'font=%d+', 'font=113')
						insert(aXml, CONSTANT.XML_LINE_BREAKER)
						insert(aXml, GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE, 113))
						insert(aXml, GetFormatImage(szImagePath, nFrame, 20, 20))
						insert(aXml, GetFormatText(' ', 113))
						insert(aXml, szText)
					else
						local enchantAttrib = GetItemEnchantAttrib(rec.permanent_enchant);
						if enchantAttrib then
							for k, v in pairs(enchantAttrib) do
								szText = D.FormatEnchantAttribText(v)
								if szText ~= '' then
									szText = gsub(szText, 'font=%d+', 'font=113')
									insert(aXml, CONSTANT.XML_LINE_BREAKER)
									insert(aXml, GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE, 113))
									insert(aXml, GetFormatImage(szImagePath, nFrame, 20, 20))
									insert(aXml, GetFormatText(' ', 113))
									insert(aXml, szText)
								end
							end
						end
					end
				end
				-- 五彩石
				if KItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
					insert(aXml, CONSTANT.XML_LINE_BREAKER)
					-- insert(aXml, GetFormatText(rep(g_tStrings.STR_ONE_CHINESE_SPACE, nTitleLen) .. ' ', 162))
					-- insert(aXml, GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE, 162))
					insert(aXml, GetFormatText(g_tStrings.STR_COLOR_DIAMOND .. g_tStrings.STR_COLON, 162))
					if rec.fea_enchant == 0 then
						insert(aXml, '<image>w=20 h=20 path="ui/Image/UICommon/FEPanel.UITex" frame=5 </image>')
						insert(aXml, '<text>text=' .. EncodeComponentsString(' ' .. g_tStrings.STR_ITEM_H_COLOR_DIAMOND) .. ' font=161 valign=1 h=24 richtext=0 </text>')
					else
						local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(rec.fea_enchant)
						local diamon = GetItemInfo(dwTabType, dwIndex)
						insert(aXml, '<image>w=20 h=20 path="fromiconid" frame=' .. Table_GetItemIconID(diamon.nUiId) .. '</image>')
						insert(aXml, GetFormatText(' [' .. diamon.szName .. ']', 162, GetItemFontColorByQuality(diamon.nQuality)))
					end
				end
			--[[#DEBUG BEGIN]]
			else
				LIB.Debug('MY_RoleStatistics_EquipStat', 'KItemInfo not found: ' .. rec.tabtype .. ', ' .. rec.tabindex, DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			end
		else
			if box then
				box:ClearObject()
			end
			if txtDurability then
				txtDurability:SetText('')
			end
			if visible then
				insert(aXml, GetFormatText(_L['None'], 162))
			end
		end
		if visible then
			insert(aXml, CONSTANT.XML_LINE_BREAKER)
		end
	end

	-- 绘制挂饰、其它
	for _, info in ipairs(EQUIPMENT_EXTRA_ITEM_LIST) do
		local aItemData = ownerextra[info.key] or {}
		local dwTabType, dwTabIndex = aItemData[1], aItemData[2]
		local KItemInfo = not IsEmpty(dwTabIndex) and GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwTabIndex)
		local box = info.box and handle:Lookup(info.box)
		if KItemInfo then
			if box then
				box:SetObjectIcon(Table_GetItemIconID(KItemInfo.nUiId))
				box.bItemInfo = true
				box.dwTabType = dwTabType
				box.dwTabIndex = dwTabIndex
				UpdateItemBoxExtend(box, KItemInfo.nGenre, KItemInfo.nQuality)
			end
		else
			if box then
				box:ClearObject()
			end
		end
	end

	-- 绘制详情
	local txtName = page:Lookup('Wnd_Total/Wnd_ItemPage', 'Text_RoleName')
	txtName:SetText(ownername)
	txtName:SetFontColor(LIB.GetForceColor(ownerforce, 'foreground'))
	local txtEquipScore = page:Lookup('Wnd_Total/Wnd_ItemPage', 'Text_EquipScore')
	txtEquipScore:SetVisible(ownersuitindex == D.dwCurrentSuitIndex)
	txtEquipScore:SetText(_L('Equip score: %s', ownerscore))
	local hBoard = page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo', 'Handle_EquipInfo')
	hBoard:Clear()
	hBoard:AppendItemFromString(concat(aXml))
	hBoard:FormatAllItemPos()
end

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_EquipStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	Wnd.CloseWindow(frameTemp)

	local container = wnd:Lookup('Wnd_ItemPage/WndScroll_PageNum/WndContainer_PageNum')
	container:Clear()
	for nIndex, _ in ipairs(CONSTANT.INVENTORY_EQUIP_LIST) do
		local wndPage = container:AppendContentFromIni(SZ_INI, 'Wnd_PageNum')
		wndPage:Lookup('CheckBox_PageNum', 'Text_PageNum'):SetText(nIndex)
		wndPage.nSuitIndex = nIndex
	end
	container:FormatAllContentPos()

	local frame = this:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_EQUIP_UPDATE')
end

function D.OnActivePage()
	if not O.bAdviceSaveDB and not O.bSaveDB then
		LIB.Confirm(_L('%s stat has not been enabled, this character\'s data will not be saved, are you willing to save this character?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]), function()
			MY_RoleStatistics_EquipStat.bSaveDB = true
			MY_RoleStatistics_EquipStat.bAdviceSaveDB = true
		end, function()
			MY_RoleStatistics_EquipStat.bAdviceSaveDB = true
		end)
	end
	D.FlushDB()
	D.UpdateNames(this)
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateNames(this)
	elseif event == 'MY_ROLE_STAT_EQUIP_UPDATE' then
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
		end
		return 1
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_PageNum' then
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent()
		D.dwCurrentSuitIndex = this:GetParent().nSuitIndex
		D.UpdateItems(page)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Wnd_Name' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent()
		D.szCurrentOwnerKey = wnd.ownerkey
		D.UpdateNames(page)
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
	end
end

function D.OnItemMouseEnter()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(true)
	end
	if this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	elseif this.bItemInfo then
		LIB.OutputItemInfoTip(this, this.dwTabType, this.dwTabIndex)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(false)
	end
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
			LIB.FormatTime(this.time, '%yyyy-%MM-%dd %hh:%mm:%ss')), nil, 255, 255, 0), 400, {x, y, w, h, false}, ALW.RIGHT_LEFT_AND_BOTTOM_TOP, false)
	end
end

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_RoleStatistics_EquipStat', function()
	D.bReady = true
	D.UpdateSaveDB()
	D.FlushDB()
end)

-- function D.OnMouseLeave()
-- 	HideTip()
-- end

-- Module exports
do
local settings = {
	name = 'MY_RoleStatistics_EquipStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				szSaveDB = 'MY_RoleStatistics_EquipStat.bSaveDB',
				szFloatEntry = false,
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('EquipStat', _L['MY_RoleStatistics_EquipStat'], LIB.CreateModule(settings))
end

-- Global exports
do
local settings = {
	name = 'MY_RoleStatistics_EquipStat',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'bSaveDB',
				'bAdviceSaveDB',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bSaveDB',
				'bAdviceSaveDB',
			},
			root = O,
		},
	},
}
MY_RoleStatistics_EquipStat = LIB.CreateModule(settings)
end
