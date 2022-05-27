--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗统计 数据复盘
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Recount/MY_Recount_FP'
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^14.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local DK = MY_Recount_DS.DK
local DK_REC = MY_Recount_DS.DK_REC
local DK_REC_STAT = MY_Recount_DS.DK_REC_STAT
local DK_REC_STAT_DETAIL = MY_Recount_DS.DK_REC_STAT_DETAIL
local DK_REC_STAT_SKILL = MY_Recount_DS.DK_REC_STAT_SKILL
local DK_REC_STAT_SKILL_DETAIL = MY_Recount_DS.DK_REC_STAT_SKILL_DETAIL
local DK_REC_STAT_SKILL_TARGET = MY_Recount_DS.DK_REC_STAT_SKILL_TARGET
local DK_REC_STAT_TARGET = MY_Recount_DS.DK_REC_STAT_TARGET
local DK_REC_STAT_TARGET_DETAIL = MY_Recount_DS.DK_REC_STAT_TARGET_DETAIL
local DK_REC_STAT_TARGET_SKILL = MY_Recount_DS.DK_REC_STAT_TARGET_SKILL
local EVERYTHING_TYPE = MY_Recount_DS.EVERYTHING_TYPE

local D = {}
local O = {}
local PAGE_SIZE = 300
local PAGE_DISPLAY = 19

local function GeneCommonFormatText(szType, nIndex)
	local tIndex = X.IsTable(szType)
		and szType
		or {[szType] = nIndex}
	return function(r)
		local i = tIndex[r[4]] or tIndex['*']
		if i then
			return GetFormatText(r[i])
		end
		return GetFormatText('-')
	end
end
local function GeneCommonCompare(szType, nIndex)
	local tIndex = X.IsTable(szType)
		and szType
		or {[szType] = nIndex}
	return function(r1, r2)
		local i1 = tIndex[r1[4]] or tIndex['*']
		local i2 = tIndex[r2[4]] or tIndex['*']
		local v1 = i1 and r1[i1] or 0
		local v2 = i2 and r2[i2] or 0
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
			return GetFormatText(rec[3] - data[DK.TICK_BEGIN])
		end,
		Compare = GeneCommonCompare('*', 3)
	},
	{
		id = 'type',
		bSort = true,
		nWidth = 50,
		szTitle = _L['Type'],
		GetFormatText = function(rec)
			if rec[4] == EVERYTHING_TYPE.FIGHT_TIME then
				return GetFormatText(_L['Fight time'])
			end
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
				if rec[7] == SKILL_EFFECT_TYPE.BUFF then
					return GetFormatText(_L['Buff'])
				end
				if rec[7] == SKILL_EFFECT_TYPE.SKILL then
					return GetFormatText(_L['Skill'])
				end
			end
			if rec[4] == EVERYTHING_TYPE.DEATH then
				return GetFormatText(_L['Death'])
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				return GetFormatText(_L['Buff'])
			end
			if rec[4] == EVERYTHING_TYPE.ONLINE then
				if rec[6] then
					return GetFormatText(_L['Online'])
				end
				return GetFormatText(_L['Offline'])
			end
			if rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE then
				return GetFormatText(_L['Target'])
			end
			if rec[4] == EVERYTHING_TYPE.SYS_MSG then
				return GetFormatText(_L['System'])
			end
			if rec[4] == EVERYTHING_TYPE.PLAYER_SAY then
				return GetFormatText(_L['Talk'])
			end
			if rec[4] == EVERYTHING_TYPE.WARNING_MESSAGE then
				return GetFormatText(_L['Warning'])
			end
			if rec[4] == EVERYTHING_TYPE.FIGHT_HINT then
				return GetFormatText(_L['Fight hint'])
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
			if rec[4] == EVERYTHING_TYPE.FIGHT_TIME then
				if rec[5] then
					return GetFormatText(_L['Fighting'])
				end
				return GetFormatText(_L['Unfight'])
			end
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
				local szName, bAnonymous = MY_Recount_DS.GetEffectInfoAusID(data, rec[10])
				if X.IsEmpty(szName) or bAnonymous then
					szName = rec[8] .. ',' .. rec[9]
				end
				return GetFormatText(szName)
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				local szName, bAnonymous = MY_Recount_DS.GetEffectInfoAusID(data, rec[9])
				if X.IsEmpty(szName) or bAnonymous then
					szName = rec[7] .. ',' .. rec[8]
				end
				return GetFormatText(szName)
			end
			if rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE then
				return GetFormatText(rec[8])
			end
			if rec[4] == EVERYTHING_TYPE.SYS_MSG then
				return GetFormatText(_L['System'])
			end
			if rec[4] == EVERYTHING_TYPE.PLAYER_SAY then
				return GetFormatText(rec[7])
			end
			if rec[4] == EVERYTHING_TYPE.WARNING_MESSAGE then
				return GetFormatText(_L['System'])
			end
			if rec[4] == EVERYTHING_TYPE.FIGHT_HINT then
				return GetFormatText(rec[7] and _L['Start fight'] or _L['Finish fight'])
			end
			return GetFormatText('-')
		end,
		Compare = GeneCommonCompare({[EVERYTHING_TYPE.SKILL_EFFECT] = 10, [EVERYTHING_TYPE.BUFF_UPDATE] = 9})
	},
	{
		id = 'caster',
		bSort = true,
		nWidth = 130,
		szTitle = _L['Caster'],
		GetFormatText = function(rec, data)
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
				return GetFormatText(MY_Recount_DS.GetNameAusID(data, rec[5]) or rec[5])
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				return GetFormatText(MY_Recount_DS.GetNameAusID(data, rec[5]) or rec[5])
			end
			if rec[4] == EVERYTHING_TYPE.DEATH then
				return GetFormatText(rec[8] or rec[6])
			end
			if rec[4] == EVERYTHING_TYPE.FIGHT_HINT then
				return GetFormatText(rec[8])
			end
			return GetFormatText('-')
		end,
		Compare = GeneCommonCompare({[EVERYTHING_TYPE.SKILL_EFFECT] = 5, [EVERYTHING_TYPE.BUFF_UPDATE] = 5})
	},
	{
		id = 'target',
		bSort = true,
		nWidth = 130,
		szTitle = _L['Target'],
		GetFormatText = function(rec, data)
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
				return GetFormatText(MY_Recount_DS.GetNameAusID(data, rec[6]) or rec[6])
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				return GetFormatText(MY_Recount_DS.GetNameAusID(data, rec[6]) or rec[6])
			end
			if rec[4] == EVERYTHING_TYPE.DEATH then
				return GetFormatText(rec[7] or rec[5])
			end
			return GetFormatText('-')
		end,
		Compare = GeneCommonCompare({[EVERYTHING_TYPE.SKILL_EFFECT] = 6, [EVERYTHING_TYPE.BUFF_UPDATE] = 6})
	},
	{
		id = 'skillresult',
		bSort = true,
		nWidth = 50,
		szTitle = _L['SkillResult'],
		GetFormatText = function(rec)
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
				return GetFormatText(MY_Recount.SKILL_RESULT_NAME[rec[11]] or '')
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				return GetFormatText(rec[10] and _L['Wither'] or _L['Acquired'])
			end
			if rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE then
				return GetFormatText(rec[5] == 1 and _L['Appear'] or _L['Disappear'])
			end
			return GetFormatText('-')
		end,
		Compare = GeneCommonCompare(EVERYTHING_TYPE.SKILL_EFFECT, 11)
	},
	{
		id = 'therapy',
		bSort = true,
		nWidth = 60,
		szTitle = _L['Therapy'],
		GetFormatText = GeneCommonFormatText(EVERYTHING_TYPE.SKILL_EFFECT, 12),
		Compare = GeneCommonCompare(EVERYTHING_TYPE.SKILL_EFFECT, 12)
	},
	{
		id = 'effecttherapy',
		bSort = true,
		nWidth = 60,
		szTitle = _L['EffectTherapy'],
		GetFormatText = GeneCommonFormatText(EVERYTHING_TYPE.SKILL_EFFECT, 13),
		Compare = GeneCommonCompare(EVERYTHING_TYPE.SKILL_EFFECT, 13)
	},
	{
		id = 'damage',
		bSort = true,
		nWidth = 60,
		szTitle = _L['Damage'],
		GetFormatText = GeneCommonFormatText(EVERYTHING_TYPE.SKILL_EFFECT, 14),
		Compare = GeneCommonCompare(EVERYTHING_TYPE.SKILL_EFFECT, 14)
	},
	{
		id = 'effectdamage',
		bSort = true,
		nWidth = 60,
		szTitle = _L['EffectDamage'],
		GetFormatText = GeneCommonFormatText(EVERYTHING_TYPE.SKILL_EFFECT, 15),
		Compare = GeneCommonCompare(EVERYTHING_TYPE.SKILL_EFFECT, 15)
	},
	{
		id = 'description',
		bSort = false,
		nWidth = 100,
		szTitle = _L['Description'],
		GetFormatText = function(rec)
			if rec[4] == EVERYTHING_TYPE.FIGHT_TIME then
				if rec[5] then
					return GetFormatText(_L('Fighting for %ds.', rec[7] / 1000))
				end
				if rec[7] > 0 then
					return GetFormatText(_L('Last fighting for %ds.', rec[7] / 1000))
				end
				return GetFormatText(_L['Not fighting now.'])
			end
			if rec[4] == EVERYTHING_TYPE.DEATH then
				if IsPlayer(rec[5]) then
					if IsPlayer(rec[6]) then
						return GetFormatText(_L('[%s] killed [%s].', rec[8], rec[7]))
					end
					return GetFormatText(_L('%s killed [%s].', rec[8], rec[7]))
				end
				if IsPlayer(rec[6]) then
					return GetFormatText(_L('[%s] killed %s.', rec[8], rec[7]))
				end
				return GetFormatText(_L('%s killed %s.', rec[8], rec[7]))
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				if not rec[10] then
					if rec[11] == 1 then
						return GetFormatText(_L(
							rec[13]
								and 'Remain time %s, cancellable.'
								or 'Remain time %s, uncancellable.',
							X.FormatDuration((rec[12] - rec[1]) / X.ENVIRONMENT.GAME_FPS, 'CHINESE')))
					end
					return GetFormatText(_L(
						rec[13]
							and 'Stacknum %d, remain time %s, cancellable.'
							or 'Stacknum %d, remain time %s, uncancellable.',
						rec[11], X.FormatDuration((rec[12] - rec[1]) / X.ENVIRONMENT.GAME_FPS, 'CHINESE')))
				end
			end
			if rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE then
				return GetFormatText(
					'[' .. (rec[8] or X.GetObjectName(rec[6], rec[7])) .. ']'
					.. _L.TARGET[rec[6]]
					.. (rec[5] == 1 and _L['Appear'] or _L['Disappear'])
					.. _L['.'])
			end
			if rec[4] == EVERYTHING_TYPE.SYS_MSG then
				return GetFormatText(rec[5])
			end
			if rec[4] == EVERYTHING_TYPE.PLAYER_SAY then
				return GetFormatText(rec[5])
			end
			if rec[4] == EVERYTHING_TYPE.WARNING_MESSAGE then
				return GetFormatText(rec[5])
			end
			if rec[4] == EVERYTHING_TYPE.FIGHT_HINT then
				return GetFormatText(_L(rec[7] and '[%s] start fight.' or '[%s] finish fight.', rec[8]))
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
	D.UpdateData(frame)
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
		if col.Compare then
			hCol.szKey = col.id
		end
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

-- 搜索匹配
function D.MatchRecSearch(data, rec, szSearch, nSearch, bEffectName, bCaster, bTarget)
	if not szSearch or szSearch == '' then
		return true
	end
	if (
		(szSearch == _L['Skill'] and rec[4] == EVERYTHING_TYPE.SKILL_EFFECT and rec[7] == SKILL_EFFECT_TYPE.SKILL)
		or (szSearch == _L['Buff'] and rec[4] == EVERYTHING_TYPE.SKILL_EFFECT and rec[7] == SKILL_EFFECT_TYPE.BUFF)
		or (szSearch == _L['Fight time'] and rec[4] == EVERYTHING_TYPE.FIGHT_TIME)
		or (szSearch == _L['Death'] and rec[4] == EVERYTHING_TYPE.DEATH)
		or (szSearch == _L['Online'] and rec[4] == EVERYTHING_TYPE.ONLINE and rec[6])
		or (szSearch == _L['Offline'] and rec[4] == EVERYTHING_TYPE.ONLINE and not rec[6])
		or (szSearch == _L['Target'] and rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE)
		or (szSearch == _L['Appear'] and rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE and rec[5] == 1)
		or (szSearch == _L['Disappear'] and rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE and rec[5] == 0)
		or (szSearch == _L['System'] and rec[4] == EVERYTHING_TYPE.SYS_MSG)
		or (szSearch == _L['Talk'] and rec[4] == EVERYTHING_TYPE.PLAYER_SAY)
		or (szSearch == _L['Warning'] and rec[4] == EVERYTHING_TYPE.WARNING_MESSAGE)
		or (szSearch == _L['Fight hint'] and rec[4] == EVERYTHING_TYPE.FIGHT_HINT)
		or (rec[4] == EVERYTHING_TYPE.DEATH and (
			X.StringFindW(rec[7] or '', szSearch)
			or X.StringFindW(rec[8] or '', szSearch)
		))
		or (rec[4] == EVERYTHING_TYPE.SKILL_EFFECT and (
			nSearch == rec[8]
			or (bCaster and nSearch == rec[5])
			or (bCaster and X.StringFindW(MY_Recount_DS.GetNameAusID(data, rec[5]) or '', szSearch))
			or (bTarget and nSearch == rec[6])
			or (bTarget and X.StringFindW(MY_Recount_DS.GetNameAusID(data, rec[6]) or '', szSearch))
			or (bEffectName and X.StringFindW(MY_Recount_DS.GetEffectInfoAusID(data, rec[10]) or '', szSearch))
			or (bEffectName and szSearch == MY_Recount.SKILL_RESULT_NAME[rec[11]])
			or (szSearch == _L['Therapy'] and rec[12] > 0)
			or (szSearch == _L['EffectTherapy'] and rec[13] > 0)
			or (szSearch == _L['Damage'] and rec[14] > 0)
			or (szSearch == _L['EffectDamage'] and rec[15] > 0)
		))
		or (rec[4] == EVERYTHING_TYPE.BUFF_UPDATE and (
			nSearch == rec[7]
			or (bCaster and nSearch == rec[5])
			or (bCaster and X.StringFindW(MY_Recount_DS.GetNameAusID(data, rec[5]) or '', szSearch))
			or (bTarget and nSearch == rec[6])
			or (bTarget and X.StringFindW(MY_Recount_DS.GetNameAusID(data, rec[6]) or '', szSearch))
			or (bEffectName and X.StringFindW(MY_Recount_DS.GetEffectInfoAusID(data, rec[9]) or '', szSearch))
		))
		or (rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE and (
			nSearch == rec[7]
			or X.StringFindW(rec[8] or '', szSearch))
		)
		or (rec[4] == EVERYTHING_TYPE.PLAYER_SAY and X.StringFindW(rec[6] or '', szSearch))
		or ((rec[4] == EVERYTHING_TYPE.SYS_MSG
				or rec[4] == EVERYTHING_TYPE.PLAYER_SAY
				or rec[4] == EVERYTHING_TYPE.WARNING_MESSAGE)
			and X.StringFindW(rec[5], szSearch))
		or (rec[4] == EVERYTHING_TYPE.FIGHT_HINT and (
			nSearch == rec[6]
			or X.StringFindW(rec[8], szSearch)
		))
	) then
		return true
	end
	return false
end

-- 根据搜索和配置过滤生成显示列表
function D.UpdateData(frame)
	local aSearch = X.SplitString(frame:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):GetText(), ' ', true)
	local bEffectName = frame:Lookup('Wnd_Total/WndCheckBox_EffectName'):IsCheckBoxChecked()
	local bCaster = frame:Lookup('Wnd_Total/WndCheckBox_Caster'):IsCheckBoxChecked()
	local bTarget = frame:Lookup('Wnd_Total/WndCheckBox_Target'):IsCheckBoxChecked()
	local bTargetNotCaster = frame:Lookup('Wnd_Total/WndCheckBox_TargetNotCaster'):IsCheckBoxChecked()
	for i, v in ipairs(aSearch) do
		aSearch[i] = { v, tonumber(v) }
	end
	if X.IsEmpty(aSearch) then
		aSearch = nil
	end
	local data, aRec = frame.data, {}
	for _, rec in ipairs(data[DK.EVERYTHING]) do
		local bMatch = true
		-- 零数值记录
		if bMatch and not MY_Recount_UI.bShowZeroVal then
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT and rec[14] == 0 and rec[12] == 0
			and not MY_Recount.IsImportantEffect(rec[7] .. ',' .. rec[8] .. ',' .. rec[9]) then
				bMatch = false
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				bMatch = false
			end
		end
		-- 没名字记录
		if bMatch and MY_Recount_UI.bHideAnonymous then
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT and select(2, MY_Recount_DS.GetEffectInfoAusID(data, rec[10])) then
				bMatch = false
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE and select(2, MY_Recount_DS.GetEffectInfoAusID(data, rec[9])) then
				bMatch = false
			end
			if rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE and X.IsEmpty(rec[8]) then
				bMatch = false
			end
		end
		-- 释放者和目标是同一人
		if bTargetNotCaster then
			if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT and rec[5] == rec[6] then
				bMatch = false
			end
			if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
				bMatch = false
			end
		end
		-- 搜索匹配
		if bMatch and aSearch then
			for _, v in ipairs(aSearch) do
				bMatch = D.MatchRecSearch(data, rec, v[1], v[2], bEffectName, bCaster, bTarget)
				if not bMatch then
					break
				end
			end
		end
		if bMatch then
			table.insert(aRec, rec)
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
		table.sort(aRec, Sorter)
	end
	frame.disp = aRec
end

-- 根据页码渲染列表
function D.DrawData(frame)
	local data = frame.data
	local aRec = frame.disp
	local nPage = frame.nPage or 1
	local hList = frame:Lookup('Wnd_Total/WndScroll_FP', 'Handle_List')
	local nOffset = (nPage - 1) * PAGE_SIZE
	for i = 1, PAGE_SIZE do
		local rec = aRec[nOffset + i]
		local hRow = hList:Lookup(i - 1) or hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		local hRowItemList = hRow:Lookup('Handle_RowItemList')
		local nX = 0
		if rec then
			for j, col in ipairs(COLUMN_LIST) do
				local hItem = hRowItemList:Lookup(j - 1) or hRowItemList:AppendItemFromIni(SZ_INI, 'Handle_Item') -- 外部居中层
				local hItemContent = hItem:Lookup('Handle_ItemContent') -- 内部文本布局层
				hItemContent:Clear()
				hItemContent:AppendItemFromString(col.GetFormatText(rec, data))
				hItemContent:SetW(99999)
				hItemContent:FormatAllItemPos()
				hItemContent:SetSizeByAllItemSize()
				local nWidth = col.nWidth
				if j == #COLUMN_LIST then
					nWidth = EXCEL_WIDTH - nX
				end
				hItem:SetRelX(nX + 4)
				hItem:SetW(nWidth - 8)
				hItemContent:SetRelPos(
					hItem:GetW() < hItemContent:GetW()
						and 0
						or (nWidth - hItemContent:GetW()) / 2,
					(hItem:GetH() - hItemContent:GetH()) / 2)
				hItem:FormatAllItemPos()
				nX = nX + nWidth
			end
		end
		hRowItemList:FormatAllItemPos()
		hRow.rec = rec
		hRow:SetVisible(rec and true or false)
	end
	hList:FormatAllItemPos()

	local nPageCount = math.ceil(#aRec / PAGE_SIZE)
	local hOuter = frame:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexesOuter')
	local handle = hOuter:Lookup('Handle_Indexes')
	if nPageCount <= PAGE_DISPLAY then
		for i = 0, PAGE_DISPLAY - 1 do
			local hItem = handle:Lookup(i)
			hItem.nPage = i + 1
			hItem:Lookup('Text_Index'):SetText(i + 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(i + 1 == nPage)
			hItem:SetVisible(i < nPageCount)
		end
	else
		local hItem = handle:Lookup(0)
		hItem.nPage = 1
		hItem:Lookup('Text_Index'):SetText(1)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(1 == nPage)
		hItem:Show()

		local hItem = handle:Lookup(PAGE_DISPLAY - 1)
		hItem.nPage = nPageCount
		hItem:Lookup('Text_Index'):SetText(nPageCount)
		hItem:Lookup('Text_IndexUnderline'):SetVisible(nPageCount == nPage)
		hItem:Show()

		local nStartPage
		if nPage + math.ceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif nPage - math.ceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = nPage - math.ceil((PAGE_DISPLAY - 2) / 2)
		end
		for i = 1, PAGE_DISPLAY - 2 do
			local hItem = handle:Lookup(i)
			hItem.nPage = nStartPage + i - 1
			hItem:Lookup('Text_Index'):SetText(nStartPage + i - 1)
			hItem:Lookup('Text_IndexUnderline'):SetVisible(nStartPage + i - 1 == nPage)
			hItem:SetVisible(true)
		end
	end
	handle:SetSize(hOuter:GetSize())
	handle:FormatAllItemPos()
	handle:SetSizeByAllItemSize()
	hOuter:FormatAllItemPos()

	local szTitle = _L['MY_Recount_FP']
	if data[DK.BOSSNAME] then
		szTitle = szTitle .. ' - ' .. data[DK.BOSSNAME]
	end
	frame:Lookup('', 'Text_Title'):SetText(szTitle)
	frame:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexCount/Text_IndexCount'):SprintfText(_L['Total %d pages'], nPageCount)
end

function D.OutputTip(this, rec)
	local aXml = {}
	local data = this:GetRoot().data
	-- 时间
	table.insert(aXml, GetFormatText(_L['Time']))
	table.insert(aXml, GetFormatText(':  '))
	table.insert(aXml, GetFormatText(X.FormatTime(rec[2], '%yyyy/%MM/%dd %hh:%mm:%ss')))
	table.insert(aXml, GetFormatText('\n'))
	-- 逻辑帧
	table.insert(aXml, GetFormatText(_L['Framecount']))
	table.insert(aXml, GetFormatText(':  '))
	table.insert(aXml, GetFormatText(rec[1]))
	table.insert(aXml, GetFormatText('\n'))
	-- 毫秒时间
	table.insert(aXml, GetFormatText(_L['Tick']))
	table.insert(aXml, GetFormatText(':  '))
	table.insert(aXml, GetFormatText(rec[3]))
	table.insert(aXml, GetFormatText('\n'))
	-- 事件
	local col = COLUMN_DICT['type']
	table.insert(aXml, GetFormatText(col.szTitle))
	table.insert(aXml, GetFormatText(':  '))
	table.insert(aXml, col.GetFormatText(rec))
	table.insert(aXml, GetFormatText('\n'))
	if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
		-- 名称
		local col = COLUMN_DICT['effectname']
		local szName, bAnonymous = MY_Recount_DS.GetEffectInfoAusID(data, rec[10])
		if X.IsEmpty(szName) or bAnonymous then
			szName = rec[8] .. ',' .. rec[9]
		else
			szName = szName .. ' (' .. rec[8] .. ',' .. rec[9] .. ')'
		end
		table.insert(aXml, GetFormatText(col.szTitle))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(szName))
		table.insert(aXml, GetFormatText('\n'))
		-- 释放者
		local col = COLUMN_DICT['caster']
		local dwID = rec[5]
		local szName = MY_Recount_DS.GetNameAusID(data, rec[5])
		table.insert(aXml, GetFormatText(col.szTitle))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(szName and (szName .. ' (' .. dwID .. ')') or dwID))
		table.insert(aXml, GetFormatText('\n'))
		-- 目标
		local col = COLUMN_DICT['target']
		local dwID = rec[6]
		local szName = MY_Recount_DS.GetNameAusID(data, rec[6])
		table.insert(aXml, GetFormatText(col.szTitle))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(szName and (szName .. ' (' .. dwID .. ')') or dwID))
		table.insert(aXml, GetFormatText('\n'))
		-- 数值们
		for _, id in ipairs({
			'skillresult',
			'therapy',
			'effecttherapy',
			'damage',
			'effectdamage',
		}) do
			local col = COLUMN_DICT[id]
			table.insert(aXml, GetFormatText(col.szTitle))
			table.insert(aXml, GetFormatText(':  '))
			table.insert(aXml, col.GetFormatText(rec))
			table.insert(aXml, GetFormatText('\n'))
		end
	end
	if rec[4] == EVERYTHING_TYPE.BUFF_UPDATE then
		-- 名称
		local col = COLUMN_DICT['effectname']
		local szName, bAnonymous = MY_Recount_DS.GetEffectInfoAusID(data, rec[9])
		if X.IsEmpty(szName) or bAnonymous then
			szName = rec[7] .. ',' .. rec[8]
		else
			szName = szName .. ' (' .. rec[7] .. ',' .. rec[8] .. ')'
		end
		table.insert(aXml, GetFormatText(col.szTitle))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(szName))
		table.insert(aXml, GetFormatText('\n'))
		-- 释放者
		local col = COLUMN_DICT['caster']
		local dwID = rec[5]
		local szName = MY_Recount_DS.GetNameAusID(data, rec[5])
		table.insert(aXml, GetFormatText(col.szTitle))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(szName and (szName .. ' (' .. dwID .. ')') or dwID))
		table.insert(aXml, GetFormatText('\n'))
		-- 目标
		local col = COLUMN_DICT['target']
		local dwID = rec[6]
		local szName = MY_Recount_DS.GetNameAusID(data, rec[6])
		table.insert(aXml, GetFormatText(col.szTitle))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(szName and (szName .. ' (' .. dwID .. ')') or dwID))
		table.insert(aXml, GetFormatText('\n'))
	end
	if rec[4] == EVERYTHING_TYPE.ENTER_LEAVE_SCENE then
		-- 模板ID
		if rec[6] == TARGET.NPC or rec[6] == TARGET.DOODAD then
			table.insert(aXml, GetFormatText(_L['TemplateID']))
			table.insert(aXml, GetFormatText(':  '))
			table.insert(aXml, GetFormatText(rec[9]))
			table.insert(aXml, GetFormatText('\n'))
		end
		-- 血量
		table.insert(aXml, GetFormatText(_L['Life']))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(rec[10] .. '/' .. rec[11]))
		table.insert(aXml, GetFormatText('\n'))
		-- 内力
		table.insert(aXml, GetFormatText(_L['Mana']))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(rec[12] .. '/' .. rec[13]))
		table.insert(aXml, GetFormatText('\n'))
	end
	if rec[4] == EVERYTHING_TYPE.FIGHT_HINT then
		-- 模板ID
		if rec[5] == TARGET.NPC then
			table.insert(aXml, GetFormatText(_L['TemplateID']))
			table.insert(aXml, GetFormatText(':  '))
			table.insert(aXml, GetFormatText(rec[9]))
			table.insert(aXml, GetFormatText('\n'))
		end
		-- 血量
		table.insert(aXml, GetFormatText(_L['Life']))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(rec[10] .. '/' .. rec[11]))
		table.insert(aXml, GetFormatText('\n'))
		-- 内力
		table.insert(aXml, GetFormatText(_L['Mana']))
		table.insert(aXml, GetFormatText(':  '))
		table.insert(aXml, GetFormatText(rec[12] .. '/' .. rec[13]))
		table.insert(aXml, GetFormatText('\n'))
	end
	-- 描述
	local col = COLUMN_DICT['description']
	table.insert(aXml, GetFormatText(col.szTitle))
	table.insert(aXml, GetFormatText(':  '))
	table.insert(aXml, col.GetFormatText(rec))
	table.insert(aXml, GetFormatText('\n'))

	if IsCtrlKeyDown() then
		table.insert(aXml, GetFormatText(X.EncodeLUAData(rec, '  ')))
	end

	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, X.UI.TIP_POSITION.RIGHT_LEFT)
end

function D.PopupRowMenu(frame, rec)
	local data = frame.data
	local menu = {}
	-- 复制
	local t = { szOption = _L['Copy'] }
	for nChannel, szChannel in pairs({
		[PLAYER_TALK_CHANNEL.RAID] = 'MSG_TEAM',
		[PLAYER_TALK_CHANNEL.TEAM] = 'MSG_PARTY',
		[PLAYER_TALK_CHANNEL.TONG] = 'MSG_GUILD',
	}) do
		table.insert(t, {
			szOption = g_tStrings.tChannelName[szChannel],
			rgb = GetMsgFontColor(szChannel, true),
			fnAction = function()
				local szText = X.FormatTime(rec[2], '[%hh:%mm:%ss] ')
				if rec[4] == EVERYTHING_TYPE.FIGHT_TIME then
					if rec[5] then
						szText = szText .. _L('Fighting for %ds.', rec[7] / 1000)
					elseif rec[7] > 0 then
						szText = szText .. _L('Last fighting for %ds.', rec[7] / 1000)
					else
						szText = szText .. GetFormatText(_L['Not fighting now.'])
					end
				elseif rec[4] == EVERYTHING_TYPE.DEATH then
					if IsPlayer(rec[5]) then
						if IsPlayer(rec[6]) then
							szText = szText .. _L('[%s] killed [%s].', rec[8], rec[7])
						else
							szText = szText .. _L('%s killed [%s].', rec[8], rec[7])
						end
					else
						if IsPlayer(rec[6]) then
							szText = szText .. _L('[%s] killed %s.', rec[8], rec[7])
						else
							szText = szText .. _L('%s killed %s.', rec[8], rec[7])
						end
					end
				elseif rec[4] == EVERYTHING_TYPE.ONLINE then
					if rec[6] then
						szText = szText .. _L('[%s] get online.', rec[7])
					else
						szText = szText .. _L('[%s] get offline.', rec[7])
					end
				elseif rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
					local szName, bAnonymous = MY_Recount_DS.GetEffectInfoAusID(data, rec[10])
					if X.IsEmpty(szName) or bAnonymous then
						szName = rec[8] .. ',' .. rec[9]
					end
					local szCaster = MY_Recount_DS.GetNameAusID(data, rec[5]) or rec[5]
					local szTarget = MY_Recount_DS.GetNameAusID(data, rec[6]) or rec[6]
					local szEffectType = rec[7] == SKILL_EFFECT_TYPE.BUFF
						and _L['Buff']
						or _L['Skill']
					local szResultType = MY_Recount.SKILL_RESULT_NAME[rec[11]]
					if szResultType and rec[11] ~= MY_Recount.SKILL_RESULT.HIT then
						szText = szText .. _L('%s use %s %s(%s) cause %s ', szCaster, szEffectType, szName, szResultType, szTarget)
					else
						szText = szText .. _L('%s use %s %s cause %s ', szCaster, szEffectType, szName, szTarget)
					end
					local nTherapy = rec[12]
					local nEffectTherapy = rec[13]
					local nDamage = rec[14]
					local nEffectDamage = rec[15]
					if nTherapy == 0 and nDamage == 0 then
						szText = szText .. _L['no effect']
					else
						if nTherapy > 0 then
							szText = szText .. _L('get healed by %d', nTherapy)
							if nTherapy ~= nEffectTherapy then
								szText = szText .. _L[',']
								szText = szText .. _L('effect healed %d', nEffectTherapy)
							end
						end
						if nDamage > 0 then
							if nTherapy > 0 then
								szText = szText .. _L[',']
							end
							szText = szText .. _L('get damaged by %d', nDamage)
							if nDamage ~= nEffectDamage then
								szText = szText .. _L[',']
								szText = szText .. _L('effect damaged %d', nEffectDamage)
							end
						end
					end
					szText = szText .. _L['.']
				else
					szText = szText .. '-'
				end
				X.SendChat(nChannel, szText)
			end,
		})
	end
	table.insert(menu, t)
	-- 搜索
	local dwCaster, szCaster, dwTarget, szTarget
	if rec[4] == EVERYTHING_TYPE.DEATH then
		dwCaster, szCaster, dwTarget, szTarget = rec[6], rec[8], rec[5], rec[7]
	elseif rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
		dwCaster = rec[5]
		szCaster = MY_Recount_DS.GetNameAusID(data, rec[5]) or rec[5]
		dwTarget = rec[6]
		szTarget = MY_Recount_DS.GetNameAusID(data, rec[6]) or rec[6]
	end
	if dwCaster then
		table.insert(menu, {
			szOption = _L('Search for %s', szCaster),
			fnAction = function()
				D.SetSearch(frame, dwCaster)
			end,
		})
	end
	if dwTarget then
		table.insert(menu, {
			szOption = _L('Search for %s', szTarget),
			fnAction = function()
				D.SetSearch(frame, dwTarget)
			end,
		})
	end
	if rec[4] == EVERYTHING_TYPE.SKILL_EFFECT then
		local szName = MY_Recount_DS.GetEffectInfoAusID(data, rec[10]) or rec[10]
		table.insert(menu, {
			szOption = _L('Search for %s', szName),
			fnAction = function()
				D.SetSearch(frame, szName)
			end,
		})
	end
	PopupMenu(menu)
end

function D.SetPage(frame, nPage)
	frame.nPage = nPage
	D.DrawData(frame)
end

function D.SetSearch(frame, szSearch)
	frame:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):SetText(szSearch)
	D.UpdateData(frame)
	D.SetPage(frame, 1)
end

function MY_Recount_FP.OnFrameCreate()
	this.szSortKey = 'time'
	this.szSortOrder = 'asc'
	this:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):SetPlaceholderText(_L['Press enter to search ...'])
	this:Lookup('Wnd_Total/WndCheckBox_EffectName', 'Text_CheckBox_EffectName'):SetText(_L['EffectName'])
	this:Lookup('Wnd_Total/WndCheckBox_Caster', 'Text_CheckBox_Caster'):SetText(_L['Caster'])
	this:Lookup('Wnd_Total/WndCheckBox_Target', 'Text_CheckBox_Target'):SetText(_L['Target'])
	this:Lookup('Wnd_Total/WndCheckBox_TargetNotCaster', 'Text_CheckBox_TargetNotCaster'):SetText(_L['Target not caster'])

	local handle = this:Lookup('Wnd_Total/Wnd_Index', 'Handle_IndexesOuter/Handle_Indexes')
	handle:Clear()
	for i = 1, PAGE_DISPLAY do
		handle:AppendItemFromIni(SZ_INI, 'Handle_Index')
	end
	handle:FormatAllItemPos()

	this:RegisterEvent('MY_RECOUNT_UI_CONFIG_UPDATE')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	D.DrawHead(this)
	this.SetDS = D.SetDS
end

function MY_Recount_FP.OnEvent(event)
	if event == 'MY_RECOUNT_UI_CONFIG_UPDATE' then
		D.UpdateData(this)
		D.DrawData(this)
	end
end

function MY_Recount_FP.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Refresh' then
		D.UpdateData(this:GetRoot())
		D.DrawData(this:GetRoot())
	end
end

function MY_Recount_FP.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_Search' then
			D.UpdateData(this:GetRoot())
			D.SetPage(this:GetRoot(), 1)
		elseif name == 'WndEdit_Index' then
			local nPage = tonumber(this:GetText())
			if nPage then
				D.SetPage(this:GetRoot(), nPage)
			end
		end
		return 1
	end
end

function MY_Recount_FP.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'WndCheckBox_EffectName' or name == 'WndCheckBox_Caster'
	or name == 'WndCheckBox_Target' or name == 'WndCheckBox_TargetNotCaster' then
		local frame = this:GetRoot()
		D.UpdateData(frame)
		D.DrawData(frame)
	end
end

function MY_Recount_FP.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'WndCheckBox_EffectName' or name == 'WndCheckBox_Caster'
	or name == 'WndCheckBox_Target' or name == 'WndCheckBox_TargetNotCaster' then
		local frame = this:GetRoot()
		D.UpdateData(frame)
		D.DrawData(frame)
	end
end

function MY_Recount_FP.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_FPColumn' then
		if this.szKey then
			local frame = this:GetRoot()
			if frame.szSortKey == this.szKey then
				frame.szSortOrder = frame.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				frame.szSortKey = this.szKey
			end
			D.DrawHead(frame)
			D.UpdateData(frame)
			D.DrawData(frame)
		end
	elseif name == 'Handle_Index' then
		D.SetPage(this:GetRoot(), this.nPage)
	end
end

function MY_Recount_FP.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Row' then
		D.PopupRowMenu(this:GetRoot(), this.rec)
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
		OutputTip(szXml, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
