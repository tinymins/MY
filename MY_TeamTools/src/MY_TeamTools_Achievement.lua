--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具 - 团队成就
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_Achievement'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local SZ_INI = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_Achievement.ini'
local D = {}
local O = {
	dwMapID = 0,
	szSearch = '',
	szSort = 'name',
	szSortOrder = 'asc',
	aAchievement = {},
}
local MAX_ALL_MAP_ACHI = 40
local ACHIEVE_CACHE = {}
local COUNTER_CACHE = {}
local EXCEL_WIDTH = 1056
local ACHI_MIN_WIDTH = 15
local ACHI_MAX_WIDTH = HUGE
local STAT_SORT = setmetatable({
	['FINISH'] = 3,
	['PROGRESS'] = 2,
	['UNKNOWN'] = 1,
}, { __index = function() return 0 end })

local function GeneCommonFormatText(id)
	return function(r)
		return GetFormatText(r[id], 162, 255, 255, 255)
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

function D.GetColumns()
	local aCol = {
		{ -- 名字
			id = 'name',
			szTitle = _L['Name'],
			nMinWidth = 110, nMaxWidth = 200,
			GetFormatText = function(rec)
				local name = rec.name
				if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
					name = MY_ChatMosaics.MosaicsString(name)
				end
				return GetFormatText(name, 162, LIB.GetForceColor(rec.force, 'foreground'))
			end,
			Compare = GeneCommonCompare('name'),
		},
	}
	for _, dwAchieveID in ipairs(O.aAchievement) do
		local achi = Table_GetAchievement(dwAchieveID)
		if achi then
			insert(aCol, {
				id = 'achievement_' .. dwAchieveID,
				dwAchieveID = dwAchieveID,
				szTitle = achi.szName,
				nMinWidth = ACHI_MIN_WIDTH, nMaxWidth = ACHI_MAX_WIDTH,
				GetFormatText = function(rec)
					local szStat = D.GetPlayerAchievementStat(rec.id, dwAchieveID)
					local szText, nR, nG, nB
					if szStat == 'FINISH' then
						szText, nR, nG, nB = _L['r'], 128, 255, 128
					elseif szStat == 'PROGRESS' then
						szText, nR, nG, nB = _L['x'], 255, 255, 255
					else
						szText, nR, nG, nB = _L['--'], 173, 173, 173
					end
					return GetFormatText(szText, 162, nR, nG, nB, 786,
						'this.playerid=' .. rec.id .. ';this.achieveid=' .. dwAchieveID, 'Text_Achieve')
				end,
				Compare = function(r1, r2)
					local szStat1, aProgressCounter1 = D.GetPlayerAchievementStat(r1.id, dwAchieveID)
					local szStat2, aProgressCounter2 = D.GetPlayerAchievementStat(r2.id, dwAchieveID)
					if szStat1 == szStat2 then
						if szStat1 == 'PROGRESS' then
							local nCounter1, nCounter2 = 0, 0
							for _, v in ipairs(aProgressCounter1) do
								nCounter1 = nCounter1 + v.nNumber
							end
							for _, v in ipairs(aProgressCounter2) do
								nCounter2 = nCounter2 + v.nNumber
							end
							if nCounter1 == nCounter2 then
								return 0
							end
							return nCounter1 > nCounter2 and 1 or -1
						end
						return 0
					end
					return STAT_SORT[szStat1] > STAT_SORT[szStat2] and 1 or -1
				end,
			})
		end
	end
	return aCol
end

function D.GetDispColumns()
	local aCol, nW = {}, 0
	local nExtraWidth, nFlexWidth = EXCEL_WIDTH, 0
	for _, col in ipairs(D.GetColumns()) do
		if nExtraWidth < col.nMinWidth then
			break
		end
		col.nFlexWidth = (col.nMaxWidth and not IsHugeNumber(col.nMaxWidth)
			and col.nMaxWidth
			or EXCEL_WIDTH) - col.nMinWidth
		insert(aCol, col)
		nFlexWidth = nFlexWidth + col.nFlexWidth
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	for i, col in ipairs(aCol) do
		col.nWidth = i == #aCol
			and (EXCEL_WIDTH - nW)
			or min(nExtraWidth * col.nFlexWidth / nFlexWidth + col.nMinWidth, col.nMaxWidth or HUGE)
		nW = nW + col.nWidth
	end
	return aCol
end

function D.UpdateAchievementID()
	local aAchievement = {}
	if O.dwMapID == 0 then
		local nCount = g_tTable.Achievement:GetRowCount()
		for i = 2, nCount do
			local achi = g_tTable.Achievement:GetRow(i)
			if achi and achi.nVisible == 1 and achi.dwGeneral == 1
			and (IsEmpty(O.szSearch) or wfind(achi.szName, O.szSearch) or wfind(achi.szDesc, O.szSearch)) then
				insert(aAchievement, achi.dwID)
				if #aAchievement >= MAX_ALL_MAP_ACHI then
					break
				end
			end
		end
	else
		for _, dwAchieveID in ipairs(LIB.GetMapAchievements(O.dwMapID)) do
			local achi = Table_GetAchievement(dwAchieveID)
			if achi and (IsEmpty(O.szSearch) or wfind(achi.szName, O.szSearch) or wfind(achi.szDesc, O.szSearch)) then
				insert(aAchievement, achi.dwID)
			end
		end
	end
	O.aAchievement = aAchievement
	FireUIEvent('MY_TEAMTOOLS_ACHI')
end

LIB.RegisterEvent('LOADING_ENDING', function()
	O.dwMapID = GetClientPlayer().GetMapID()
	O.szSearch = ''
	D.UpdateAchievementID()
end)

-- 获取团队成员列表
function D.GetTeamMemberList(bIsOnLine)
	local me   = GetClientPlayer()
	local team = GetClientTeam()
	if me.IsInParty() then
		if bIsOnLine then
			local tTeam = {}
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = team.GetMemberInfo(v)
				if info and info.bIsOnLine then
					insert(tTeam, v)
				end
			end
			return tTeam
		else
			return team.GetTeamMemberList()
		end
	else
		return { me.dwID }
	end
end

function D.GetPlayerAchievementStat(dwID, dwAchieveID)
	if ACHIEVE_CACHE[dwID] and IsBoolean(ACHIEVE_CACHE[dwID][dwAchieveID]) then
		if ACHIEVE_CACHE[dwID][dwAchieveID] then
			return 'FINISH'
		end
		local achi = Table_GetAchievement(dwAchieveID)
		if achi then
			local aProgressCounter = {}
			if COUNTER_CACHE[dwID] then
				for _, s in ipairs(LIB.SplitString(achi.szCounters, '|', true)) do
					local dwCounter = tonumber(s)
					if dwCounter and COUNTER_CACHE[dwID][dwCounter] then
						insert(aProgressCounter, {
							dwCounter = dwCounter,
							nNumber = COUNTER_CACHE[dwID][dwCounter],
						})
					end
				end
			end
			return 'PROGRESS', aProgressCounter
		end
	end
	return 'UNKNOWN'
end

do
local function AnalysisAchievementRequest(dwAchieveID, tAchieveID, tCounterID)
	local info = Table_GetAchievement(dwAchieveID)
	if info then
		tAchieveID[dwAchieveID] = true
		for _, s in ipairs(LIB.SplitString(info.szCounters, '|', true)) do
			local dwCounter = tonumber(s)
			if dwCounter then
				tCounterID[dwCounter] = true
			end
		end
		for _, s in ipairs(LIB.SplitString(info.szSeries, '|', true)) do
			local dwSerie = tonumber(s)
			if dwSerie and not tAchieveID[dwSerie] then
				AnalysisAchievementRequest(dwSerie, tAchieveID, tCounterID)
			end
		end
		for _, s in ipairs(LIB.SplitString(info.szSubAchievements, '|', true)) do
			local dwSubAchieve = tonumber(s)
			if dwSubAchieve and not tAchieveID[dwSubAchieve] then
				AnalysisAchievementRequest(dwSubAchieve, tAchieveID, tCounterID)
			end
		end
	end
	return tAchieveID, tCounterID
end
function D.AnalysisAchievementRequest(aAchievement)
	local tAchieveID, tCounterID = {}, {}
	for _, dwAchieveID in ipairs(aAchievement) do
		AnalysisAchievementRequest(dwAchieveID, tAchieveID, tCounterID)
	end
	local aAchieveID, aCounterID = {}, {}
	for dwAchieveID, _ in pairs(tAchieveID) do
		insert(aAchieveID, dwAchieveID)
	end
	for dwCounterID, _ in pairs(tCounterID) do
		insert(aCounterID, dwCounterID)
	end
	return aAchieveID, aCounterID
end
end

function D.UpdateSelfData()
	local aAchieveID, aCounterID = D.AnalysisAchievementRequest(O.aAchievement)
	local me = GetClientPlayer()
	if not ACHIEVE_CACHE[me.dwID] then
		ACHIEVE_CACHE[me.dwID] = {}
	end
	if not COUNTER_CACHE[me.dwID] then
		COUNTER_CACHE[me.dwID] = {}
	end
	for _, dwAchieveID in ipairs(aAchieveID) do
		ACHIEVE_CACHE[me.dwID][dwAchieveID] = me.IsAchievementAcquired(dwAchieveID)
	end
	for _, dwCounterID in ipairs(aCounterID) do
		COUNTER_CACHE[me.dwID][dwCounterID] = me.GetAchievementCount(dwCounterID)
	end
	FireUIEvent('MY_TEAMTOOLS_ACHI')
end

function D.RequestTeamData()
	-- 计算强制请求和刷新请求列表
	local aAchieveID, aCounterID = D.AnalysisAchievementRequest(O.aAchievement)
	local aRequestID, aRefreshID, tRequestID = {}, {}, {}
	local aTeamMemberList = D.GetTeamMemberList(true)
	for _, dwID in ipairs(aTeamMemberList) do
		for _, dwAchieveID in ipairs(aAchieveID) do
			if not ACHIEVE_CACHE[dwID] or IsNil(ACHIEVE_CACHE[dwID][dwAchieveID]) then
				tRequestID[dwID] = true
			end
		end
		for _, dwCounterID in ipairs(aCounterID) do
			if not COUNTER_CACHE[dwID] or IsNil(COUNTER_CACHE[dwID][dwCounterID]) then
				tRequestID[dwID] = true
			end
		end
	end
	for _, dwID in ipairs(aTeamMemberList) do
		if dwID ~= UI_GetClientPlayerID() then
			if tRequestID[dwID] then
				insert(aRequestID, dwID)
			else
				insert(aRefreshID, dwID)
			end
		end
	end
	if (not IsEmpty(aAchieveID) or not IsEmpty(aCounterID)) and (not IsEmpty(aRequestID) or not IsEmpty(aRefreshID)) then
		if #aRequestID == #aTeamMemberList - 1 then
			aRequestID = nil
		end
		if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			LIB.Systopmsg(_L['Fetch teammate\'s data failed, please unlock talk and reopen.'])
		else
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TEAMTOOLS_ACHI_REQ', {aAchieveID, aCounterID, aRequestID, nil})
		end
	end
	-- 刷新自己的
	D.UpdateSelfData()
end

LIB.RegisterBgMsg('MY_TEAMTOOLS_ACHI_RES', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	local aAchieveRes, aCounterRes = data[1], data[2]
	if not ACHIEVE_CACHE[dwTalkerID] then
		ACHIEVE_CACHE[dwTalkerID] = {}
	end
	if not COUNTER_CACHE[dwTalkerID] then
		COUNTER_CACHE[dwTalkerID] = {}
	end
	for _, v in ipairs(aAchieveRes) do
		ACHIEVE_CACHE[dwTalkerID][v[1]] = v[2]
	end
	for _, v in ipairs(aCounterRes) do
		COUNTER_CACHE[dwTalkerID][v[1]] = v[2]
	end
	FireUIEvent('MY_TEAMTOOLS_ACHI')
end)

function D.OutputRowTip(this, rec)
	local aXml = {}
	for _, col in ipairs(D.GetColumns()) do
		if col.dwAchieveID then
			insert(aXml, GetFormatText('[' .. col.szTitle .. ']', 162, 255, 255, 0))
		else
			insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
		end
		insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
		insert(aXml, col.GetFormatText(rec))
		if IsCtrlKeyDown() then
			insert(aXml, GetFormatText('\t' .. col.id, 162, 255, 0, 0))
		else
			insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local nPosType = UI.TIP_POSITION.RIGHT_LEFT
	OutputTip(concat(aXml), 450, {x, y, w, h}, nPosType)
end

function D.OutputAchieveTip(dwAchieveID, dwID)
	local achi = Table_GetAchievement(dwAchieveID)
	if not achi then
		return
	end
	local aXml = {}
	-- 成就名称
	insert(aXml, GetFormatText('[' .. achi.szName .. ']', 162, 255, 255, 0))
	-- 完成状态
	if dwID then
		insert(aXml, GetFormatText(' ', 162, 255, 255, 255))
		local szStat, aProgressCounter = D.GetPlayerAchievementStat(dwID, dwAchieveID)
		if szStat == 'FINISH' then
			insert(aXml, GetFormatText(_L['(Finished)'] .. '\n', 162, 255, 255, 255))
		elseif szStat == 'PROGRESS' then
			if IsEmpty(aProgressCounter) then
				insert(aXml, GetFormatText(_L['(Progress)'] .. '\n', 162, 173, 173, 173))
			else
				insert(aXml, GetFormatText('(', 162, 255, 255, 255))
				for i, progress in ipairs(aProgressCounter) do
					local nTriggerVal, nPoint, nExp, nPrefix, nPostfix, nShiftID = Table_GetAchievementInfo(progress.dwCounter)
					if i ~= 1 then
						insert(aXml, GetFormatText(', ', 162, 255, 255, 255))
					end
					insert(aXml, GetFormatText(progress.nNumber .. '/' .. nTriggerVal, 162, 255, 255, 255))
				end
				insert(aXml, GetFormatText(')\n', 162, 255, 255, 255))
			end
		else --if szStat == 'UNKNOWN' then
			insert(aXml, GetFormatText(_L['(Unknown)'] .. '\n', 162, 255, 255, 255))
		end
	else
		insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
	end
	insert(aXml, GetFormatText(achi.szDesc .. '\n', 162, 255, 255, 255))
	-- 子成就
	for _, s in ipairs(LIB.SplitString(achi.szSubAchievements, '|', true)) do
		local dwSubAchieveID = tonumber(s)
		if dwSubAchieveID then
			local achi = Table_GetAchievement(dwSubAchieveID)
			if dwID then
				local szStat, aProgressCounter = D.GetPlayerAchievementStat(dwID, dwSubAchieveID)
				if achi then
					if szStat == 'FINISH' then
						insert(aXml, GetFormatText(_L['r'], 162, 128, 255, 128))
					elseif szStat == 'PROGRESS' then
						insert(aXml, GetFormatText(_L['x'], 162, 173, 173, 173))
					else --if szStat == 'UNKNOWN' then
						insert(aXml, GetFormatText(_L['?'], 162, 173, 173, 173))
					end
					insert(aXml, GetFormatText(' ', 162, 255, 255, 255))
				end
				insert(aXml, GetFormatText(achi.szName, 162, 255, 255, 255))
				if not IsEmpty(aProgressCounter) then
					insert(aXml, GetFormatText(' (', 162, 255, 255, 255))
					for i, progress in ipairs(aProgressCounter) do
						local nTriggerVal, nPoint, nExp, nPrefix, nPostfix, nShiftID = Table_GetAchievementInfo(progress.dwCounter)
						if i ~= 1 then
							insert(aXml, GetFormatText(', ', 162, 255, 255, 255))
						end
						insert(aXml, GetFormatText(progress.nNumber .. '/' .. nTriggerVal, 162, 255, 255, 255))
					end
					insert(aXml, GetFormatText(')', 162, 255, 255, 255))
				end
				insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
			else
				insert(aXml, GetFormatText(_L[' '] .. achi.szName .. '\n', 162, 255, 255, 255))
			end
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
end

function D.UpdatePage(page)
	UI(page):Fetch('Wnd_Total/WndAutocomplete_Map')
		:Text(D.tMapName[O.dwMapID] or '', WNDEVENT_FIRETYPE.PREVENT)

	local hCols = page:Lookup('Wnd_Total/WndScroll_Stat', 'Handle_StatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetDispColumns(), 0, nil
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_StatColumn')
		local hTitle = hCol:Lookup('Handle_Stat_Title')
		local txt = hTitle:Lookup('Text_Stat_Title')
		local imgAsc = hCol:Lookup('Image_Stat_Asc')
		local imgDesc = hCol:Lookup('Image_Stat_Desc')
		local nWidth, nHeight = col.nWidth, hCol:GetH()
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_Stat_Break'):Hide()
		end
		hCol.col = col
		hCol.achieveid = col.dwAchieveID
		hCol:SetRelX(nX)
		hCol:SetW(nWidth)
		hTitle:SetRelX(3)
		hTitle:SetSize(nWidth - 5, nHeight)
		txt:SetText(col.szTitle)
		txt:AutoSize()
		if hTitle:GetW() < txt:GetW() and hTitle:GetW() > 80 then
			txt:SetW(hTitle:GetW())
		end
		txt:SetRelX(hTitle:GetW() > txt:GetW() and (hTitle:GetW() - txt:GetW()) / 2 or 0)
		txt:SetRelY((hTitle:GetH() - txt:GetH()) / 2)
		hTitle:FormatAllItemPos()
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

	local me = GetClientPlayer()
	local team = GetClientTeam()
	local bIsInParty = LIB.IsInParty()
	local aRec = {}
	local aTeamMemberList = D.GetTeamMemberList()
	for _, dwID in ipairs(aTeamMemberList) do
		local info = bIsInParty and team.GetMemberInfo(dwID)
		if info or dwID == me.dwID then
			insert(aRec, {
				id = dwID,
				name = info and info.szName or me.szName,
				force = info and info.dwForceID or me.dwForceID,
				achi = ACHIEVE_CACHE[dwID] or CONSTANT.EMPTY_TABLE,
			})
		end
	end

	if Sorter then
		sort(aRec, Sorter)
	end

	local aCol = D.GetDispColumns()
	local hList = page:Lookup('Wnd_Total/WndScroll_Stat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(aRec) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
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

function D.SetSearch(szSearch)
	O.szSearch = szSearch
	D.UpdateAchievementID()
end

function D.OnInitPage()
	if not D.tMapMenu or not D.tMapName or not D.aMapName or not D.tMapID then
		local tMapMenu, tMapName, aMapName = {}, {}, {}
		insert(tMapMenu, {
			szOption = _L['All map'],
			fnAction = function()
				O.dwMapID = 0
				D.UpdateAchievementID()
				D.RequestTeamData()
				UI.ClosePopupMenu()
			end,
		})
		tMapName[0] = _L['All map']
		insert(aMapName, _L['All map'])
		insert(tMapMenu, {
			szOption = _L['Current map'],
			fnAction = function()
				O.dwMapID = GetClientPlayer().GetMapID()
				D.UpdateAchievementID()
				D.RequestTeamData()
				UI.ClosePopupMenu()
			end,
		})
		for _, group in ipairs(LIB.GetTypeGroupMap()) do
			local tSub = { szOption = group.szGroup }
			for _, info in ipairs(group.aMapInfo) do
				insert(tSub, {
					szOption = info.szName,
					fnAction = function()
						O.dwMapID = info.dwID
						D.UpdateAchievementID()
						D.RequestTeamData()
						UI.ClosePopupMenu()
					end
				})
				tMapName[info.dwID] = info.szName
				insert(aMapName, info.szName)
			end
			insert(tMapMenu, tSub)
		end
		D.tMapMenu = tMapMenu
		D.aMapName = aMapName
		D.tMapName = tMapName
		D.tMapID = LIB.FlipObjectKV(tMapName)
	end
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_TeamTools_Achievement')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	Wnd.CloseWindow(frameTemp)

	UI(wnd):Append('WndAutocomplete', {
		x = 20, y = 20, w = 200,
		name = 'WndAutocomplete_Map',
		onchange = function(szText)
			if D.tMapID[szText] then
				O.dwMapID = D.tMapID[szText]
				D.UpdateAchievementID()
				D.RequestTeamData()
			end
		end,
		autocomplete = {{'option', 'source', D.aMapName}},
		menu = function() return D.tMapMenu end,
	})

	local ui = UI(wnd):Fetch('Wnd_Search/Edit_Search')
	ui:Change(function()
		LIB.Debounce(
			'MY_TeamTools_Achievement_Search',
			1000,
			D.SetSearch,
			this:GetText())
	end)
	ui:Blur(function() D.RequestTeamData() end)
	ui:Text(O.szSearch, WNDEVENT_FIRETYPE.PREVENT)

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAMTOOLS_ACHI')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	this.hAchievement = frame:CreateItemData(SZ_INI, 'Handle_Item_Achievement')
end

function D.OnActivePage()
	D.RequestTeamData()
	D.UpdatePage(this)
end

function D.OnEvent(event)
	if event == 'MY_TEAMTOOLS_ACHI' then
		D.UpdatePage(this)
	elseif event == 'ON_MY_MOSAICS_RESET' then
		D.UpdatePage(this)
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Clear' then
		LIB.Confirm(_L['Clear record'], D.ClearAchievementLog)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Row' then
		local AchievementPanel = _G.AchievementPanel or GetInsideEnv().AchievementPanel
		if AchievementPanel then
			AchievementPanel.Compare(this.rec.id)
		end
	elseif name == 'Handle_StatColumn' then
		if this.col.id then
			local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
			if O.szSort == this.col.id then
				O.szSortOrder = O.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				O.szSort = this.col.id
			end
			D.UpdatePage(page)
		end
	elseif name == 'Text_Achieve' then
		if not this.achieveid then
			return
		end
		local AchievementPanel = _G.AchievementPanel or GetInsideEnv().AchievementPanel
		if AchievementPanel then
			AchievementPanel.Open(nil, this.achieveid)
		end
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Row' then
		D.OutputRowTip(this, this.rec)
	elseif name == 'Handle_StatColumn' or name == 'Text_Achieve' then
		if not this.achieveid then
			return
		end
		D.OutputAchieveTip(this.achieveid, this.playerid)
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'Handle_Achievement' then
		if this and this:Lookup('Image_Cover') and this:Lookup('Image_Cover'):IsValid() then
			this:Lookup('Image_Cover'):Hide()
		end
	end
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
MY_TeamTools.RegisterModule('Achievement', _L['MY_TeamTools_Achievement'], LIB.GeneGlobalNS(settings))
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
			},
		},
	},
}
MY_TeamTools_Achievement = LIB.GeneGlobalNS(settings)
end
