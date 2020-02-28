--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗统计 数据复盘
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
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {}

local function GeneCommonFormatText(szType, nIndex)
	return function(r)
		if szType == '*' or r[4] == szType then
			return GetFormatText(r[nIndex])
		end
		return GetFormatText('-')
	end
end
local function GeneCommonCompare(szType, nIndex)
	return function(r1, r2)
		local v1 = (szType == '*' or r1[4] == szType)
			and r1[nIndex]
			or 0
		local v2 = (szType == '*' or r2[4] == szType)
			and r2[nIndex]
			or 0
		if v1 == v2 then
			if r1[3] == r2[3] then
				return 0
			end
			return r1[3] > r2[3] and 1 or -1
		end
		return v1 > v2 and 1 or -1
	end
end
local EXCEL_WIDTH = 960
local COLUMN_LIST = {
	{
		id = 'time',
		bSort = true,
		nWidth = 80,
		szTitle = _L['Time (ms)'],
		GetFormatText = function(rec, data)
			return GetFormatText(rec[3] - data.nTickBegin)
		end,
		Compare = GeneCommonCompare('*', 3)
	},
	{
		id = 'type',
		bSort = true,
		nWidth = 50,
		szTitle = _L['Type'],
		GetFormatText = function(rec)
			if rec[4] == 'FIGHT_TIME' then
				return GetFormatText(_L['Fight time'])
			end
			if rec[4] == 'SKILL_EFFECT' then
				if rec[7] == SKILL_EFFECT_TYPE.BUFF then
					return GetFormatText(_L['Buff'])
				end
				if rec[7] == SKILL_EFFECT_TYPE.SKILL then
					return GetFormatText(_L['Skill'])
				end
			end
			return GetFormatText('-')
		end,
		Compare = GeneCommonCompare('*', 4)
	},
	{
		id = 'effectname',
		bSort = true,
		nWidth = 80,
		szTitle = _L['EffectName'],
		GetFormatText = function(rec, data)
			if rec[4] == 'FIGHT_TIME' then
				if rec[5] then
					return GetFormatText(_L['Fighting'])
				end
				return GetFormatText(_L['Unfight'])
			end
			if rec[4] == 'SKILL_EFFECT' then
				local szName = MY_Recount_DS.GetEffectInfoAusID(data, rec[10])
				if IsEmpty(szName) then
					szName = rec[8] .. ',' .. rec[9]
				end
				return GetFormatText(szName)
			end
			return GetFormatText('-')
		end,
		Compare = GeneCommonCompare('SKILL_EFFECT', 10)
	},
	{
		id = 'caster',
		bSort = true,
		nWidth = 100,
		szTitle = _L['Caster'],
		GetFormatText = function(rec, data)
			return GetFormatText(MY_Recount_DS.GetNameAusID(data, rec[5]) or rec[5])
		end,
		Compare = GeneCommonCompare('SKILL_EFFECT', 5)
	},
	{
		id = 'target',
		bSort = true,
		nWidth = 100,
		szTitle = _L['Target'],
		GetFormatText = function(rec, data)
			return GetFormatText(MY_Recount_DS.GetNameAusID(data, rec[6]) or rec[6])
		end,
		Compare = GeneCommonCompare('SKILL_EFFECT', 6)
	},
	{
		id = 'skillresult',
		bSort = true,
		nWidth = 50,
		szTitle = _L['SkillResult'],
		GetFormatText = GeneCommonFormatText('SKILL_EFFECT', 11),
		Compare = GeneCommonCompare('SKILL_EFFECT', 11)
	},
	{
		id = 'therapy',
		bSort = true,
		nWidth = 60,
		szTitle = _L['Therapy'],
		GetFormatText = GeneCommonFormatText('SKILL_EFFECT', 12),
		Compare = GeneCommonCompare('SKILL_EFFECT', 12)
	},
	{
		id = 'effecttherapy',
		bSort = true,
		nWidth = 60,
		szTitle = _L['EffectTherapy'],
		GetFormatText = GeneCommonFormatText('SKILL_EFFECT', 13),
		Compare = GeneCommonCompare('SKILL_EFFECT', 13)
	},
	{
		id = 'damage',
		bSort = true,
		nWidth = 60,
		szTitle = _L['Damage'],
		GetFormatText = GeneCommonFormatText('SKILL_EFFECT', 14),
		Compare = GeneCommonCompare('SKILL_EFFECT', 14)
	},
	{
		id = 'effectdamage',
		bSort = true,
		nWidth = 60,
		szTitle = _L['EffectDamage'],
		GetFormatText = GeneCommonFormatText('SKILL_EFFECT', 15),
		Compare = GeneCommonCompare('SKILL_EFFECT', 15)
	},
	{
		id = 'description',
		bSort = false,
		nWidth = 100,
		szTitle = _L['Description'],
		GetFormatText = function(rec)
			if rec[4] == 'FIGHT_TIME' then
				if rec[5] then
					return GetFormatText(_L('Fighting for %ds.', rec[7]))
				end
				return GetFormatText(_L['Not fighting now.'])
			end
			return GetFormatText('-')
		end,
	},
}
local COLUMN_DICT = {}
for _, p in ipairs(COLUMN_LIST) do
	COLUMN_DICT[p.id] = p
end
MY_Recount_FP = class()

local SZ_INI = PLUGIN_ROOT .. '/ui/MY_Recount_FP.ini'

function D.SetDS(frame, data)
	frame.data = data
	D.DrawData(frame)
end

function D.DrawHead(frame)
	local hCols = frame:Lookup('Wnd_Total/WndScroll_FP', 'Handle_FPColumns')
	hCols:Clear()
	local nX = 0
	for i, col in ipairs(COLUMN_LIST) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_FPColumn')
		local txt = hCol:Lookup('Text_FP_Title')
		local imgAsc = hCol:Lookup('Image_FP_Asc')
		local imgDesc = hCol:Lookup('Image_FP_Desc')
		local nWidth = i == #COLUMN_LIST and (EXCEL_WIDTH - nX) or col.nWidth
		local nSortDelta = nWidth > 80 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_DungeonStat_Break'):Hide()
		end
		hCol.szKey = col.id
		hCol:SetRelX(nX)
		hCol:SetW(nWidth)
		txt:SetW(nWidth)
		txt:SetText(col.szTitle)
		imgAsc:SetRelX(nWidth - nSortDelta)
		imgDesc:SetRelX(nWidth - nSortDelta)
		imgAsc:SetVisible(frame.szSortKey == col.id and frame.szSortOrder == 'asc')
		imgDesc:SetVisible(frame.szSortKey == col.id and frame.szSortOrder == 'desc')
		hCol:FormatAllItemPos()
		nX = nX + nWidth
	end
	hCols:FormatAllItemPos()
end

function D.DrawData(frame)
	local data = frame.data
	local szSearch = frame:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):GetText()
	local aRec = {}
	if IsEmpty(szSearch) then
		for k, v in ipairs(data.Everything) do
			aRec[k] = v
		end
	else
		local nSearch = tonumber(szSearch)
		for _, rec in ipairs(data.Everything) do
			if (szSearch == _L['Skill'] and rec[4] == 'SKILL_EFFECT' )
			or (szSearch == _L['Fight time'] and rec[4] == 'FIGHT_TIME' )
			or (rec[4] == 'SKILL_EFFECT' and (
				nSearch == rec[8] or nSearch == rec[5] or nSearch == rec[6]
				or szSearch == MY_Recount_DS.GetNameAusID(data, rec[5])
				or szSearch == MY_Recount_DS.GetNameAusID(data, rec[6])
			)) then
				insert(aRec, rec)
			end
		end
	end
	local szSortKey, szSortOrder = frame.szSortKey, frame.szSortOrder
	local Sorter
	for _, col in ipairs(COLUMN_LIST) do
		if szSortKey == col.id then
			Sorter = function(r1, r2)
				if szSortOrder == 'asc' then
					return col.Compare(r1, r2) < 0
				end
				return col.Compare(r1, r2) > 0
			end
			break
		end
	end
	if Sorter then
		sort(aRec, Sorter)
	end
	local hList = frame:Lookup('Wnd_Total/WndScroll_FP', 'Handle_List')
	hList:Clear()
	for _, rec in ipairs(aRec) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		local nX = 0
		for j, col in ipairs(COLUMN_LIST) do
			local hItem = hRow:AppendItemFromIni(SZ_INI, 'Handle_Item') -- 外部居中层
			local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
			hItemContent:AppendItemFromString(col.GetFormatText(rec, data))
			hItemContent:SetW(99999)
			hItemContent:FormatAllItemPos()
			hItemContent:SetSizeByAllItemSize()
			local nWidth = col.nWidth
			if j == #COLUMN_LIST then
				nWidth = EXCEL_WIDTH - nX
			end
			hItem:SetRelX(nX)
			hItem:SetW(nWidth)
			hItemContent:SetRelPos((nWidth - hItemContent:GetW()) / 2, (hItem:GetH() - hItemContent:GetH()) / 2)
			hItem:FormatAllItemPos()
			nX = nX + nWidth
		end
		hRow.rec = rec
		hRow:FormatAllItemPos()
	end
	hList:FormatAllItemPos()
end

function D.OutputTip(this, rec)
	local aXml = {}
	local data = this:GetRoot().data
	-- 时间
	insert(aXml, GetFormatText(_L['Time']))
	insert(aXml, GetFormatText(':  '))
	insert(aXml, GetFormatText(LIB.FormatTime(rec[2], '%yyyy/%MM/%dd %hh:%mm:%ss')))
	insert(aXml, GetFormatText('\n'))
	-- 逻辑帧
	insert(aXml, GetFormatText(_L['Framecount']))
	insert(aXml, GetFormatText(':  '))
	insert(aXml, GetFormatText(rec[1]))
	insert(aXml, GetFormatText('\n'))
	-- 毫秒时间
	insert(aXml, GetFormatText(_L['Tick']))
	insert(aXml, GetFormatText(':  '))
	insert(aXml, GetFormatText(rec[3]))
	insert(aXml, GetFormatText('\n'))
	-- 事件
	local col = COLUMN_DICT['type']
	insert(aXml, GetFormatText(col.szTitle))
	insert(aXml, GetFormatText(':  '))
	insert(aXml, col.GetFormatText(rec))
	insert(aXml, GetFormatText('\n'))
	if rec[4] == 'SKILL_EFFECT' then
		-- 名称
		local col = COLUMN_DICT['effectname']
		local szName = rec[8] .. '/' .. rec[9]
		insert(aXml, GetFormatText(col.szTitle))
		insert(aXml, GetFormatText(':  '))
		insert(aXml, GetFormatText(IsEmpty(rec[10]) and szName or (rec[10] .. ' (' .. szName .. ')')))
		insert(aXml, GetFormatText('\n'))
		-- 释放者
		local col = COLUMN_DICT['caster']
		local dwID = rec[5]
		local szName = MY_Recount_DS.GetNameAusID(data, rec[5])
		insert(aXml, GetFormatText(col.szTitle))
		insert(aXml, GetFormatText(':  '))
		insert(aXml, GetFormatText(szName and (szName .. ' (' .. dwID .. ')') or dwID))
		insert(aXml, GetFormatText('\n'))
		-- 目标
		local col = COLUMN_DICT['target']
		local dwID = rec[6]
		local szName = MY_Recount_DS.GetNameAusID(data, rec[6])
		insert(aXml, GetFormatText(col.szTitle))
		insert(aXml, GetFormatText(':  '))
		insert(aXml, GetFormatText(szName and (szName .. ' (' .. dwID .. ')') or dwID))
		insert(aXml, GetFormatText('\n'))
		-- 数值们
		for _, id in ipairs({
			'skillresult',
			'therapy',
			'effecttherapy',
			'damage',
			'effectdamage',
		}) do
			local col = COLUMN_DICT[id]
			insert(aXml, GetFormatText(col.szTitle))
			insert(aXml, GetFormatText(':  '))
			insert(aXml, col.GetFormatText(rec))
			insert(aXml, GetFormatText('\n'))
		end
	end
	-- 描述
	local col = COLUMN_DICT['description']
	insert(aXml, GetFormatText(col.szTitle))
	insert(aXml, GetFormatText(':  '))
	insert(aXml, col.GetFormatText(rec))
	insert(aXml, GetFormatText('\n'))

	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.RIGHT_LEFT)
end

function MY_Recount_FP.OnFrameCreate()
	this.szSortKey = 'time'
	this.szSortOrder = 'asc'
	this:Lookup('', 'Text_Title'):SetText(_L['MY_Recount_FP'])
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	D.DrawHead(this)
	this.SetDS = D.SetDS
end

function MY_Recount_FP.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	end
end

function MY_Recount_FP.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_Search' then
			D.DrawData(this:GetRoot())
		end
		return 1
	end
end

function MY_Recount_FP.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_FPColumn' then
		Output(name, this)
		if this.szKey then
			local frame = this:GetRoot()
			if frame.szSortKey == this.szKey then
				frame.szSortOrder = frame.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				frame.szSortKey = this.szKey
			end
			D.DrawHead(frame)
			D.DrawData(frame)
		end
	end
end

function MY_Recount_FP.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Row' then
		D.OutputTip(this, this.rec)
	elseif name == 'Handle_FPColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = GetFormatText(this.szTip or this:Lookup('Text_FP_Title'):GetText())
		OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	end
end
MY_Recount_FP.OnItemRefreshTip = MY_Recount_FP.OnItemMouseEnter

function MY_Recount_FP.OnItemMouseLeave()
	HideTip()
end

do
local nIndex = 0
function MY_Recount_FP_Open(data)
	nIndex = nIndex + 1
	Wnd.OpenWindow(SZ_INI, 'MY_Recount_FP#' .. nIndex):SetDS(data)
end
end
