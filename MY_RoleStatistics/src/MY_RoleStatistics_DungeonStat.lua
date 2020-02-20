--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 副本CD统计
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
local MODULE_NAME = 'MY_RoleStatistics_DungeonStat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(LIB.FormatPath({'userdata/role_statistics', PATH_TYPE.GLOBAL}))

local DB = LIB.ConnectDatabase(_L['MY_RoleStatistics_DungeonStat'], {'userdata/role_statistics/dungeon_stat.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg(_L['MY_RoleStatistics_DungeonStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_DungeonStat.ini'

DB:Execute('CREATE TABLE IF NOT EXISTS DungeonInfo (guid NVARCHAR(20), account NVARCHAR(255), region NVARCHAR(20), server NVARCHAR(20), name NVARCHAR(20), force INTEGER, level INTEGER, equip_score INTEGER, copy_info NVARCHAR(65535), progress_info NVARCHAR(65535), time INTEGER, PRIMARY KEY(guid))')
local DB_DungeonInfoW = DB:Prepare('REPLACE INTO DungeonInfo (guid, account, region, server, name, force, level, equip_score, copy_info, progress_info, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_DungeonInfoR = DB:Prepare('SELECT * FROM DungeonInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_DungeonInfoD = DB:Prepare('DELETE FROM DungeonInfo WHERE guid = ?')

local D = {}
local O = {
	aColumn = {
		'name',
		'force',
		'dungeon_340',
		'dungeon_426',
		'dungeon_427',
		'dungeon_428',
		'time_days',
	},
	szSort = 'time_days',
	szSortOrder = 'desc',
	tMapSaveCopy = {}, -- 单副本 CD
	tMapProgress = {}, -- 单BOSS CD
}
RegisterCustomData('Global/MY_RoleStatistics_DungeonStat.aColumn')
RegisterCustomData('Global/MY_RoleStatistics_DungeonStat.szSort')
RegisterCustomData('Global/MY_RoleStatistics_DungeonStat.szSortOrder')

local EXCEL_WIDTH = 960
local DUNGEON_WIDTH = 80
local function GeneCommonFormatText(id)
	return function(r)
		return GetFormatText(r[id])
	end
end
local function GeneCommonCompare(id)
	return function(r1, r2)
		if r1[id] == r2[id] then
			return 0
		end
		return r1[id] > r2[id] and 1 or -1
	end
end
local COLUMN_LIST = {
	-- guid,
	-- account,
	{ -- 大区
		id = 'region',
		szTitle = _L['Region'],
		nWidth = 100,
		GetFormatText = GeneCommonFormatText('region'),
		Compare = GeneCommonCompare('region'),
	},
	{ -- 服务器
		id = 'server',
		szTitle = _L['Server'],
		nWidth = 100,
		GetFormatText = GeneCommonFormatText('server'),
		Compare = GeneCommonCompare('server'),
	},
	{ -- 名字
		id = 'name',
		szTitle = _L['Name'],
		nWidth = 130,
		GetFormatText = function(rec)
			local name = rec.name
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name)
		end,
	},
	{ -- 门派
		id = 'force',
		szTitle = _L['Force'],
		nWidth = 50,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.tForceTitle[rec.force])
		end,
		Compare = GeneCommonCompare('force'),
	},
	{ -- 等级
		id = 'level',
		szTitle = _L['Level'],
		nWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- 装分
		id = 'equip_score',
		szTitle = _L['Equip score'],
		nWidth = 60,
		GetFormatText = GeneCommonFormatText('equip_score'),
		Compare = GeneCommonCompare('equip_score'),
	},
	{
		-- 时间
		id = 'time',
		szTitle = _L['Cache time'],
		nWidth = 165,
		GetFormatText = function(rec)
			return GetFormatText(LIB.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'))
		end,
		Compare = GeneCommonCompare('time'),
	},
	{
		-- 时间计时
		id = 'time_days',
		szTitle = _L['Cache time days'],
		nWidth = 120,
		GetFormatText = function(rec)
			local nTime = GetCurrentTime() - rec.time
			local nSeconds = floor(nTime)
			local nMinutes = floor(nSeconds / 60)
			local nHours   = floor(nMinutes / 60)
			local nDays    = floor(nHours / 24)
			local nYears   = floor(nDays / 365)
			local nDay     = nDays % 365
			local nHour    = nHours % 24
			local nMinute  = nMinutes % 60
			local nSecond  = nSeconds % 60
			if nYears > 0 then
				return GetFormatText(_L('%d years %d days before', nYears, nDay))
			end
			if nDays > 0 then
				return GetFormatText(_L('%d days %d hours before', nDays, nHour))
			end
			if nHours > 0 then
				return GetFormatText(_L('%d hours %d mins before', nHours, nMinute))
			end
			if nMinutes > 0 then
				return GetFormatText(_L('%d mins %d secs before', nMinutes, nSecond))
			end
			if nSecond > 10 then
				return GetFormatText(_L('%d secs before', nSecond))
			end
			return GetFormatText(_L['Just now'])
		end,
		Compare = GeneCommonCompare('time'),
	},
}
local COLUMN_DICT = setmetatable({}, { __index = function(_, id)
	if wfind(id, 'dungeon_') then
		local id = tonumber(wgsub(id, 'dungeon_', ''))
		local map = id and LIB.GetMapInfo(id)
		if map then
			local col = { -- 副本CD
				id = 'dungeon_' .. id,
				szTitle = map.szName,
				nWidth = DUNGEON_WIDTH,
			}
			if LIB.IsDungeonRoleProgressMap(map.dwID) then
				col.GetFormatText = function(rec)
					local aBossKill = rec.progress_info[map.dwID]
					if not aBossKill then
						return GetFormatText(_L['Unknown'])
					end
					local aXml = {}
					for _, bKill in ipairs(aBossKill) do
						insert(aXml, '<image>path="ui/Image/UITga/FBcdPanel01.UITex" name="Image_ProgressBoss" eventid=786 frame='
							.. (bKill and 20 or 21) .. ' w=12 h=12 script="this.mapid=' .. map.dwID .. '"</image>')
					end
					return concat(aXml)
				end
				col.Compare = function(r1, r2)
					local k1 = r1.progress_info[map.dwID]
					local k2 = r2.progress_info[map.dwID]
					if k1 and not k2 then
						return 1
					end
					if k2 and not k1 then
						return -1
					end
					if not k1 and not k2 then
						return 0
					end
					local s1, s2 = 0, 0
					for _, p in ipairs(k1) do
						if p then
							s1 = s1 + 1
						end
					end
					for _, p in ipairs(k2) do
						if p then
							s2 = s2 + 1
						end
					end
					return s1 > s2 and 1 or -1
				end
			else
				col.GetFormatText = function(rec)
					local nCopyID = rec.copy_info[map.dwID]
					if not nCopyID then
						return GetFormatText(_L['None'])
					end
					return GetFormatText(nCopyID)
				end
				col.Compare = function(r1, r2)
					local k1 = r1.copy_info[map.dwID]
					local k2 = r2.copy_info[map.dwID]
					if k1 and not k2 then
						return 1
					end
					if k2 and not k1 then
						return -1
					end
					if not k1 and not k2 then
						return 0
					end
					return k1 > k2 and 1 or -1
				end
			end
			return col
		end
	end
end })
for _, p in ipairs(COLUMN_LIST) do
	if not p.Compare then
		p.Compare = function(r1, r2)
			if r1[p.szKey] == r2[p.szKey] then
				return 0
			end
			return r1[p.szKey] > r2[p.szKey] and 1 or -1
		end
	end
	COLUMN_DICT[p.id] = p
end
local TIP_COLIMN = {
	'region',
	'server',
	'name',
	'force',
	'level',
	'equip_score',
	'DUNGEON',
	'time',
	'time_days',
}

function D.FlushDB()
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_DungeonStat', 'Flushing to database...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local me = GetClientPlayer()
	local guid = AnsiToUTF8(me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName)
	local account = LIB.GetAccount() or ''
	local region = AnsiToUTF8(LIB.GetRealServer(1))
	local server = AnsiToUTF8(LIB.GetRealServer(2))
	local name = AnsiToUTF8(me.szName)
	local force = me.dwForceID
	local level = me.nLevel
	local equip_score = me.GetBaseEquipScore() + me.GetStrengthEquipScore() + me.GetMountsEquipScore()
	local time = GetCurrentTime()
	local copy_info = EncodeLUAData(O.tMapSaveCopy)
	local progress_info = EncodeLUAData(O.tMapProgress)

	DB:Execute('BEGIN TRANSACTION')

	DB_DungeonInfoW:ClearBindings()
	DB_DungeonInfoW:BindAll(guid, account, region, server, name, force, level, equip_score, copy_info, progress_info, time)
	DB_DungeonInfoW:Execute()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	LIB.Debug('MY_RoleStatistics_DungeonStat', 'Flushing to database finished...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
LIB.RegisterFlush('MY_RoleStatistics_DungeonStat', D.FlushDB)

function D.GetColumns()
	local aCol = {}
	for _, id in ipairs(O.aColumn) do
		local col = COLUMN_DICT[id]
		if col then
			insert(aCol, col)
		end
	end
	return aCol
end

function D.UpdateUI(page)
	local hCols = page:Lookup('Wnd_Total/WndScroll_DungeonStat', 'Handle_DungeonStatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetColumns(), 0, nil
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_DungeonStatColumn')
		local txt = hCol:Lookup('Text_DungeonStat_Title')
		local imgAsc = hCol:Lookup('Image_DungeonStat_Asc')
		local imgDesc = hCol:Lookup('Image_DungeonStat_Desc')
		local nWidth = i == #aCol and (EXCEL_WIDTH - nX) or col.nWidth
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_DungeonStat_Break'):Hide()
		end
		hCol.szSort = col.id
		hCol:SetRelX(nX)
		hCol:SetW(nWidth)
		txt:SetW(nWidth)
		txt:SetText(col.szTitle)
		imgAsc:SetRelX(nWidth - nSortDelta)
		imgDesc:SetRelX(nWidth - nSortDelta)
		if O.szSort == col.id then
			Sorter = function(r1, r2)
				if O.szSortOrder == 'asc' then
					return col.Compare(r1, r2) < 0
				end
				return col.Compare(r1, r2) > 0
			end
		end
		imgAsc:SetVisible(O.szSort == col.id and O.szSortOrder == 'asc')
		imgDesc:SetVisible(O.szSort == col.id and O.szSortOrder == 'desc')
		hCol:FormatAllItemPos()
		nX = nX + nWidth
	end
	hCols:FormatAllItemPos()

	local szSearch = page:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):GetText()
	local szUSearch = AnsiToUTF8('%' .. szSearch .. '%')
	DB_DungeonInfoR:ClearBindings()
	DB_DungeonInfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = DB_DungeonInfoR:GetAll()

	for _, p in ipairs(result) do
		p.copy_info = DecodeLUAData(p.copy_info or '') or {}
		p.progress_info = DecodeLUAData(p.progress_info or '') or {}
	end

	if Sorter then
		sort(result, Sorter)
	end

	local aCol = D.GetColumns()
	local hList = page:Lookup('Wnd_Total/WndScroll_DungeonStat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(result) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		rec.guid   = UTF8ToAnsi(rec.guid)
		rec.name   = UTF8ToAnsi(rec.name)
		rec.region = UTF8ToAnsi(rec.region)
		rec.server = UTF8ToAnsi(rec.server)
		hRow.rec = rec
		hRow:Lookup('Image_RowBg'):SetVisible(i % 2 == 1)
		local nX = 0
		for j, col in ipairs(aCol) do
			local hItem = hRow:AppendItemFromIni(SZ_INI, 'Handle_Item') -- 外部居中层
			local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
			hItemContent:AppendItemFromString(col.GetFormatText(rec))
			hItemContent:SetW(99999)
			hItemContent:FormatAllItemPos()
			hItemContent:SetSizeByAllItemSize()
			local nWidth = col.nWidth
			if j == #aCol then
				nWidth = EXCEL_WIDTH - nX
			end
			hItem:SetRelX(nX)
			hItem:SetW(nWidth)
			hItemContent:SetRelPos((nWidth - hItemContent:GetW()) / 2, (hItem:GetH() - hItemContent:GetH()) / 2)
			hItem:FormatAllItemPos()
			nX = nX + nWidth
		end
		hRow:FormatAllItemPos()
	end
	hList:FormatAllItemPos()
end

function D.OnGetMapSaveCopyResopnse(tMapCopy)
	O.tMapSaveCopy = tMapCopy
end

function D.UpdateMapCopy()
	for _, id in ipairs(O.aColumn) do
		local szID = wfind(id, 'dungeon_') and wgsub(id, 'dungeon_', '')
		local dwID = szID and tonumber(szID)
		local aProgressBoss = dwID and LIB.IsDungeonRoleProgressMap(dwID) and Table_GetCDProcessBoss(dwID)
		if aProgressBoss then
			ApplyDungeonRoleProgress(dwID, UI_GetClientPlayerID())
			local aProgress = {}
			for i, boss in ipairs(aProgressBoss) do
				aProgress[i] = GetDungeonRoleProgress(dwID, UI_GetClientPlayerID(), boss.dwProgressID)
			end
			O.tMapProgress[dwID] = aProgress
		end
	end
	LIB.GetMapSaveCopy(D.OnGetMapSaveCopyResopnse)
end

function D.OnInitPage()
	local page = this
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_DungeonStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(page, true, true)
	Wnd.CloseWindow(frameTemp)

	UI(wnd):Append('WndComboBox', {
		x = 800, y = 20, w = 180,
		text = _L['Columns'],
		menu = function()
			local t, c, nW = {}, {}, 0
			for i, id in ipairs(O.aColumn) do
				local col = COLUMN_DICT[id]
				if col then
					insert(t, {
						szOption = col.szTitle,
						{
							szOption = _L['Move up'],
							fnAction = function()
								if i > 1 then
									O.aColumn[i], O.aColumn[i - 1] = O.aColumn[i - 1], O.aColumn[i]
									D.UpdateUI(page)
								end
								Wnd.CloseWindow('PopupMenuPanel')
							end,
						},
						{
							szOption = _L['Move down'],
							fnAction = function()
								if i < #O.aColumn then
									O.aColumn[i], O.aColumn[i + 1] = O.aColumn[i + 1], O.aColumn[i]
									D.UpdateUI(page)
								end
								Wnd.CloseWindow('PopupMenuPanel')
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								remove(O.aColumn, i)
								D.UpdateUI(page)
								Wnd.CloseWindow('PopupMenuPanel')
							end,
						},
					})
					c[id] = true
					nW = nW + col.nWidth
				end
			end
			for _, col in ipairs(COLUMN_LIST) do
				if not c[col.id] then
					insert(t, {
						szOption = col.szTitle,
						fnAction = function()
							if nW + col.nWidth > EXCEL_WIDTH then
								LIB.Alert(_L['Too many column selected, width overflow, please delete some!'])
							else
								insert(O.aColumn, col.id)
							end
							D.UpdateUI(page)
							Wnd.CloseWindow('PopupMenuPanel')
						end,
					})
				end
			end
			-- 副本选项
			local tChecked = {}
			for _, id in ipairs(O.aColumn) do
				local szID = wfind(id, 'dungeon_') and wgsub(id, 'dungeon_', '')
				local dwID = szID and tonumber(szID)
				if dwID then
					tChecked[dwID] = true
				end
			end
			local tDungeonMenu = LIB.GetDungeonMenu(function(info)
				local bExist = false
				for i, id in ipairs(O.aColumn) do
					if id == 'dungeon_' .. info.dwID then
						remove(O.aColumn, i)
						bExist = true
						break
					end
				end
				if not bExist then
					if nW + DUNGEON_WIDTH > EXCEL_WIDTH then
						LIB.Alert(_L['Too many column selected, width overflow, please delete some!'])
					else
						insert(O.aColumn, 'dungeon_' .. info.dwID)
					end
				end
				D.UpdateMapCopy()
				D.FlushDB()
				D.UpdateUI(page)
				Wnd.CloseWindow('PopupMenuPanel')
			end, nil, tChecked)
			tDungeonMenu.szOption = _L['Dungoen copy']
			insert(t, tDungeonMenu)
			return t
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS')
	frame:RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND')
end

function D.OnActivePage()
	D.UpdateMapCopy()
	D.FlushDB()
	D.UpdateUI(this)
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateUI(this)
	elseif event == 'UPDATE_DUNGEON_ROLE_PROGRESS' or event == 'ON_APPLY_PLAYER_SAVED_COPY_RESPOND' then
		D.UpdateMapCopy()
		D.FlushDB()
		D.UpdateUI(this)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		LIB.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			DB_DungeonInfoD:ClearBindings()
			DB_DungeonInfoD:BindAll(wnd.guid)
			DB_DungeonInfoD:Execute()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_DungeonStatColumn' then
		if this.szSort then
			local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
			if O.szSort == this.szSort then
				O.szSortOrder = O.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				O.szSort = this.szSort
			end
			D.UpdateUI(page)
		end
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Row' then
		local rec = this.rec
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		local menu = {
			{
				szOption = _L['Delete'],
				fnAction = function()
					DB_DungeonInfoD:ClearBindings()
					DB_DungeonInfoD:BindAll(rec.guid)
					DB_DungeonInfoD:Execute()
					D.UpdateUI(page)
				end,
			},
		}
		PopupMenu(menu)
	end
end

function D.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_Search' then
			local page = this:GetParent():GetParent():GetParent()
			D.UpdateUI(page)
		end
		return 1
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Row' then
		local aXml = {}
		for _, id in ipairs(TIP_COLIMN) do
			if id == 'DUNGEON' then
				for _, id in ipairs(O.aColumn) do
					if wfind(id, 'dungeon_') then
						local col = COLUMN_DICT[id]
						insert(aXml, GetFormatText(col.szTitle))
						insert(aXml, GetFormatText(':  '))
						insert(aXml, col.GetFormatText(this.rec))
						insert(aXml, GetFormatText('\n'))
					end
				end
			else
				local col = COLUMN_DICT[id]
				insert(aXml, GetFormatText(col.szTitle))
				insert(aXml, GetFormatText(':  '))
				insert(aXml, col.GetFormatText(this.rec))
				insert(aXml, GetFormatText('\n'))
			end
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.RIGHT_LEFT)
	elseif name == 'Image_ProgressBoss' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local aText = {}
		local rec = this:GetParent():GetParent():GetParent().rec
		for i, boss in ipairs(Table_GetCDProcessBoss(this.mapid)) do
			insert(aText, boss.szName .. '\t' .. _L[rec.progress_info[this.mapid][i] and 'x' or 'r'])
		end
		OutputTip(GetFormatText(concat(aText, '\n')), 400, { x, y, w, h })
	elseif name == 'Handle_DungeonStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = GetFormatText(this:Lookup('Text_DungeonStat_Title'):GetText())
		OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	elseif this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	HideTip()
end

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
MY_RoleStatistics.RegisterModule('DungeonStat', _L['MY_RoleStatistics_DungeonStat'], LIB.GeneGlobalNS(settings))
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				aColumn = true,
				szSort = true,
				szSortOrder = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				aColumn = true,
				szSort = true,
				szSortOrder = true,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_DungeonStat = LIB.GeneGlobalNS(settings)
end
