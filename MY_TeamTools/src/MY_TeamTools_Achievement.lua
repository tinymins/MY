--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队工具 - 团队成就
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamTools_Achievement'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_Achievement'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_Achievement.ini'
local O = X.CreateUserSettingsModule('MY_TeamTools_Achievement', _L['Raid'], {
	bIntelligentHide = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_TeamTools_Achievement'],
			_L['Intelligent hide'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {
	dwMapID = 0,
	szSearch = '',
	szSort = 'name',
	szSortOrder = 'asc',
	aAchievement = {},
	aSearchAC = {},
}

local MAX_ALL_MAP_ACHI = 40
local ACHIEVE_CACHE = {}
local COUNTER_CACHE = {}
local EXCEL_WIDTH = 1056
local ACHI_MIN_WIDTH = 15
local ACHI_MAX_WIDTH = math.huge
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
				return GetFormatText(name, 162, X.GetForceColor(rec.force, 'foreground'))
			end,
			Compare = GeneCommonCompare('name'),
		},
	}
	for _, dwAchieveID in ipairs(D.aAchievement) do
		local achi = X.GetAchievement(dwAchieveID)
		if achi then
			table.insert(aCol, {
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
						'this.playerid=' .. X.EncodeLUAData(rec.id) .. ';this.achieveid=' .. X.EncodeLUAData(dwAchieveID), 'Text_Achieve')
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
		col.nFlexWidth = (col.nMaxWidth and not X.IsHugeNumber(col.nMaxWidth)
			and col.nMaxWidth
			or EXCEL_WIDTH) - col.nMinWidth
		table.insert(aCol, col)
		nFlexWidth = nFlexWidth + col.nFlexWidth
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	for i, col in ipairs(aCol) do
		col.nWidth = i == #aCol
			and (EXCEL_WIDTH - nW)
			or math.min(nExtraWidth * col.nFlexWidth / nFlexWidth + col.nMinWidth, col.nMaxWidth or math.huge)
		nW = nW + col.nWidth
	end
	return aCol
end

function D.UpdateSearchAC()
	local DungeonInfo = X.GetGameTable('DungeonInfo', true)
	local info = DungeonInfo and DungeonInfo:Search(D.dwMapID)
	D.aSearchAC = info
		and X.SplitString(info.szBossInfo, ' ', true)
		or {}
	FireUIEvent('MY_TEAM_TOOLS__ACHIEVE_SEARCH_AC')
end

function D.AchievementSorter(a, b)
	local v1 = a.dwSub == 10
		and 0
		or 1
	local v2 = b.dwSub == 10
		and 0
		or 1
	if v1 == v2 then
		return a.dwID > b.dwID
	end
	return v1 > v2
end

function D.UpdateAchievementID()
	local aAchievement = {}
	if D.dwMapID == 0 then
		local Achievement = X.GetGameTable('Achievement', true)
		if Achievement then
			local nCount = Achievement:GetRowCount()
			for i = 2, nCount do
				local achi = Achievement:GetRow(i)
				if achi and achi.nVisible == 1 and achi.dwGeneral == 1
				and (not O.bIntelligentHide or achi.dwSub ~= 10) -- 隐藏声望成就
				and (X.IsEmpty(D.szSearch) or X.StringFindW(achi.szName, D.szSearch) or X.StringFindW(achi.szDesc, D.szSearch)) then
					table.insert(aAchievement, achi)
					if #aAchievement >= MAX_ALL_MAP_ACHI then
						break
					end
				end
			end
		end
	else
		for _, dwAchieveID in ipairs(X.GetMapAchievements(D.dwMapID) or X.CONSTANT.EMPTY_TABLE) do
			local achi = X.GetAchievement(dwAchieveID)
			if achi
			and (not O.bIntelligentHide or achi.dwSub ~= 10) -- 隐藏声望成就
			and (X.IsEmpty(D.szSearch) or X.StringFindW(achi.szName, D.szSearch) or X.StringFindW(achi.szDesc, D.szSearch)) then
				table.insert(aAchievement, achi)
			end
		end
	end
	table.sort(aAchievement, D.AchievementSorter)
	for i, achi in ipairs(aAchievement) do
		aAchievement[i] = achi.dwID
	end
	D.aAchievement = aAchievement
	FireUIEvent('MY_TEAM_TOOLS__ACHIEVE')
end

X.RegisterEvent('LOADING_ENDING', function()
	if MY_TeamTools.IsOpened() then
		return
	end
	D.dwMapID = X.GetClientPlayer().GetMapID()
	D.szSearch = ''
	D.UpdateSearchAC()
	D.UpdateAchievementID()
end)

-- 获取成员列表
function D.GetMemberList(bIsOnLine)
	local aList = {}
	if MY_TeamTools.szStatRange == 'RAID' then
		for _, dwID in ipairs(X.GetTeamMemberList()) do
			local tMember = X.GetTeamMemberInfo(dwID)
			if tMember and (not bIsOnLine or tMember.bOnline) then
				table.insert(aList, {
					dwID = tMember.dwID,
					szGlobalID = tMember.szGlobalID,
					szName = tMember.szName,
					dwForceID = tMember.dwForceID,
				})
			end
		end
	elseif MY_TeamTools.szStatRange == 'ROOM' then
		for _, szGlobalID in ipairs(X.GetRoomMemberList()) do
			local tMember = X.GetRoomMemberInfo(szGlobalID)
			local szServerName = tMember and X.GetServerNameByID(tMember.dwServerID)
			if tMember and szServerName then
				table.insert(aList, {
					szGlobalID = tMember.szGlobalID,
					szName = tMember.szName .. g_tStrings.STR_CONNECT .. szServerName,
					dwForceID = tMember.dwForceID,
				})
			end
		end
	end
	return aList
end

function D.GetPlayerAchievementStat(dwID, dwAchieveID)
	if ACHIEVE_CACHE[dwID] and X.IsBoolean(ACHIEVE_CACHE[dwID][dwAchieveID]) then
		if ACHIEVE_CACHE[dwID][dwAchieveID] then
			return 'FINISH'
		end
		local achi = X.GetAchievement(dwAchieveID)
		if achi then
			local aProgressCounter = {}
			if COUNTER_CACHE[dwID] then
				for _, s in ipairs(X.SplitString(achi.szCounters, '|', true)) do
					local dwCounter = tonumber(s)
					if dwCounter and COUNTER_CACHE[dwID][dwCounter] then
						table.insert(aProgressCounter, {
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

do local ACHIEVE_POINT_CACHE = {}
function D.GetAchievementPoint(dwAchieveID)
	if not ACHIEVE_POINT_CACHE[dwAchieveID] then
		local nAchievePoint = X.Get(X.GetAchievementInfo(dwAchieveID), {'nPoint'}, 0)
		local achi = X.GetAchievement(dwAchieveID)
		if achi then
			for _, s in ipairs(X.SplitString(achi.szCounters, '|', true)) do
				local dwCounter = tonumber(s)
				if dwCounter then
					nAchievePoint = nAchievePoint + X.Get(X.GetAchievementInfo(dwCounter), {'nPoint'}, 0)
				end
			end
		end
		ACHIEVE_POINT_CACHE[dwAchieveID] = nAchievePoint
	end
	return ACHIEVE_POINT_CACHE[dwAchieveID]
end
end

do
local function AnalysisAchievementRequest(dwAchieveID, tAchieveID, tCounterID)
	local info = X.GetAchievement(dwAchieveID)
	if info then
		tAchieveID[dwAchieveID] = true
		for _, s in ipairs(X.SplitString(info.szCounters, '|', true)) do
			local dwCounter = tonumber(s)
			if dwCounter then
				tCounterID[dwCounter] = true
			end
		end
		for _, s in ipairs(X.SplitString(info.szSeries, '|', true)) do
			local dwSerie = tonumber(s)
			if dwSerie and not tAchieveID[dwSerie] then
				AnalysisAchievementRequest(dwSerie, tAchieveID, tCounterID)
			end
		end
		for _, s in ipairs(X.SplitString(info.szSubAchievements, '|', true)) do
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
		table.insert(aAchieveID, dwAchieveID)
	end
	for dwCounterID, _ in pairs(tCounterID) do
		table.insert(aCounterID, dwCounterID)
	end
	return aAchieveID, aCounterID
end
end

function D.UpdateSelfData()
	local aAchieveID, aCounterID = D.AnalysisAchievementRequest(D.aAchievement)
	local dwID, szGlobalID = X.GetClientPlayerID(), X.GetClientPlayerGlobalID()
	local me = X.GetClientPlayer()
	if not ACHIEVE_CACHE[dwID] then
		ACHIEVE_CACHE[dwID] = {}
	end
	if not COUNTER_CACHE[dwID] then
		COUNTER_CACHE[dwID] = {}
	end
	for _, dwAchieveID in ipairs(aAchieveID) do
		ACHIEVE_CACHE[dwID][dwAchieveID] = me.IsAchievementAcquired(dwAchieveID)
	end
	for _, dwCounterID in ipairs(aCounterID) do
		COUNTER_CACHE[dwID][dwCounterID] = me.GetAchievementCount(dwCounterID)
	end
	ACHIEVE_CACHE[szGlobalID] = ACHIEVE_CACHE[dwID]
	COUNTER_CACHE[szGlobalID] = COUNTER_CACHE[dwID]
	FireUIEvent('MY_TEAM_TOOLS__ACHIEVE')
end

function D.RequestTeamData()
	-- 计算强制请求和刷新请求列表
	local aAchieveID, aCounterID = D.AnalysisAchievementRequest(D.aAchievement)
	local aTeamRequestID, aTeamRefreshID, tTeamRequestID = {}, {}, {}
	local aRoomRequestID, aRoomRefreshID, tRoomRequestID = {}, {}, {}
	local aMemberList = D.GetMemberList(true)
	if MY_TeamTools.szStatRange == 'RAID' then
		for _, tMember in ipairs(aMemberList) do
			for _, dwAchieveID in ipairs(aAchieveID) do
				if not ACHIEVE_CACHE[tMember.dwID] or X.IsNil(ACHIEVE_CACHE[tMember.dwID][dwAchieveID]) then
					tTeamRequestID[tMember.dwID] = true
				end
			end
			for _, dwCounterID in ipairs(aCounterID) do
				if not COUNTER_CACHE[tMember.dwID] or X.IsNil(COUNTER_CACHE[tMember.dwID][dwCounterID]) then
					tTeamRequestID[tMember.dwID] = true
				end
			end
		end
		for _, tMember in ipairs(aMemberList) do
			if tMember.dwID ~= X.GetClientPlayerID() then
				if tTeamRequestID[tMember.dwID] then
					table.insert(aTeamRequestID, tMember.dwID)
				else
					table.insert(aTeamRefreshID, tMember.dwID)
				end
			end
		end
		if (not X.IsEmpty(aAchieveID) or not X.IsEmpty(aCounterID)) and (not X.IsEmpty(aTeamRequestID) or not X.IsEmpty(aTeamRefreshID)) then
			if #aTeamRequestID == #aMemberList - 1 then
				aTeamRequestID = nil
			end
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				X.OutputSystemAnnounceMessage(_L['Fetch teammate\'s data failed, please unlock talk and reopen.'])
			else
				X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TEAM_TOOLS__ACHIEVE_REQ', {aAchieveID, aCounterID, aTeamRequestID, nil})
			end
		end
	elseif MY_TeamTools.szStatRange == 'ROOM' then
		for _, tMember in ipairs(aMemberList) do
			for _, dwAchieveID in ipairs(aAchieveID) do
				if not ACHIEVE_CACHE[tMember.szGlobalID] or X.IsNil(ACHIEVE_CACHE[tMember.szGlobalID][dwAchieveID]) then
					tRoomRequestID[tMember.szGlobalID] = true
				end
			end
			for _, dwCounterID in ipairs(aCounterID) do
				if not COUNTER_CACHE[tMember.szGlobalID] or X.IsNil(COUNTER_CACHE[tMember.szGlobalID][dwCounterID]) then
					tRoomRequestID[tMember.szGlobalID] = true
				end
			end
		end
		for _, tMember in ipairs(aMemberList) do
			if tMember.szGlobalID ~= X.GetClientPlayerGlobalID() then
				if tRoomRequestID[tMember.szGlobalID] then
					table.insert(aRoomRequestID, tMember.szGlobalID)
				else
					table.insert(aRoomRefreshID, tMember.szGlobalID)
				end
			end
		end
		if (not X.IsEmpty(aAchieveID) or not X.IsEmpty(aCounterID)) and (not X.IsEmpty(aRoomRequestID) or not X.IsEmpty(aRoomRefreshID)) then
			if #aRoomRequestID == #aMemberList - 1 then
				aRoomRequestID = nil
			end
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				X.OutputSystemAnnounceMessage(_L['Fetch teammate\'s data failed, please unlock talk and reopen.'])
			else
				X.SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, 'MY_TEAM_TOOLS__ACHIEVE_REQ', {aAchieveID, aCounterID, aRoomRequestID, nil})
			end
		end
	end
	-- 刷新自己的
	D.UpdateSelfData()
end

function D.DelayRequestTeamData()
	X.DelayCall('MY_TeamTools_Achievement_DelayReq', 1000, D.RequestTeamData)
end

X.RegisterBgMsg('MY_TEAM_TOOLS__ACHIEVE_RES', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	local aAchieveRes, aCounterRes, szGlobalID = data[1], data[2], data[3]
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
	if X.IsString(szGlobalID) then
		ACHIEVE_CACHE[szGlobalID] = ACHIEVE_CACHE[dwTalkerID]
		COUNTER_CACHE[szGlobalID] = COUNTER_CACHE[dwTalkerID]
	end
	FireUIEvent('MY_TEAM_TOOLS__ACHIEVE')
end)

function D.OutputRowTip(this, rec)
	local aXml, nAchievePoint, nAciquiePoint = {}, 0, 0
	local aCol = D.GetColumns()
	local nLen = 0
	for _, col in ipairs(aCol) do
		if col.dwAchieveID then
			nLen = math.max(nLen, X.StringLenW(col.szTitle))
		end
	end
	for _, col in ipairs(aCol) do
		if col.dwAchieveID then
			local nPoint = D.GetAchievementPoint(col.dwAchieveID)
			local szSpace = g_tStrings.STR_ONE_CHINESE_SPACE:rep(nLen - X.StringLenW(col.szTitle))
			if D.GetPlayerAchievementStat(rec.id, col.dwAchieveID) == 'FINISH' then
				nAciquiePoint = nAciquiePoint + nPoint
			end
			nAchievePoint = nAchievePoint + nPoint
			table.insert(aXml, GetFormatText('[' .. col.szTitle .. ']' .. szSpace .. '  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec))
			table.insert(aXml, GetFormatText(' (+' .. nPoint .. ')', 162, 255, 128, 0))
		else
			table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec))
		end
		if IsCtrlKeyDown() then
			table.insert(aXml, GetFormatText('\t' .. col.id, 162, 255, 0, 0))
		else
			table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	table.insert(aXml, 5, GetFormatText(_L('Achievement point: %d / %d', nAciquiePoint, nAchievePoint) .. '\n', 162, 255, 128, 0))
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local nPosType = X.UI.TIP_POSITION.RIGHT_LEFT
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, nPosType)
end

function D.OutputAchieveTip(dwAchieveID, dwID)
	local achi = X.GetAchievement(dwAchieveID)
	if not achi then
		return
	end
	local aXml = {}
	-- 成就名称
	table.insert(aXml, GetFormatText('[' .. achi.szName .. ']', 162, 255, 255, 0))
	-- 完成状态
	if dwID then
		table.insert(aXml, GetFormatText(' ', 162, 255, 255, 255))
		local szStat, aProgressCounter = D.GetPlayerAchievementStat(dwID, dwAchieveID)
		if szStat == 'FINISH' then
			table.insert(aXml, GetFormatText(_L['(Finished)'] .. '\n', 162, 255, 255, 255))
		elseif szStat == 'PROGRESS' then
			if X.IsEmpty(aProgressCounter) then
				table.insert(aXml, GetFormatText(_L['(Progress)'] .. '\n', 162, 173, 173, 173))
			else
				table.insert(aXml, GetFormatText('(', 162, 255, 255, 255))
				for i, progress in ipairs(aProgressCounter) do
					local nTriggerVal = X.Get(X.GetAchievementInfo(progress.dwCounter), {'nTriggerVal'}, 1)
					if i ~= 1 then
						table.insert(aXml, GetFormatText(', ', 162, 255, 255, 255))
					end
					table.insert(aXml, GetFormatText(progress.nNumber .. '/' .. nTriggerVal, 162, 255, 255, 255))
				end
				table.insert(aXml, GetFormatText(')\n', 162, 255, 255, 255))
			end
		else --if szStat == 'UNKNOWN' then
			table.insert(aXml, GetFormatText(_L['(Unknown)'] .. '\n', 162, 255, 255, 255))
		end
	else
		table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
	end
	table.insert(aXml, GetFormatText(_L('Achievement point: %d', D.GetAchievementPoint(dwAchieveID)) .. '\n', 162, 255, 128, 0))
	table.insert(aXml, GetFormatText(achi.szDesc .. '\n', 162, 255, 255, 255))
	-- 子成就
	for _, s in ipairs(X.SplitString(achi.szSubAchievements, '|', true)) do
		local dwSubAchieveID = tonumber(s)
		if dwSubAchieveID then
			local achi = X.GetAchievement(dwSubAchieveID)
			if dwID then
				local szStat, aProgressCounter = D.GetPlayerAchievementStat(dwID, dwSubAchieveID)
				if achi then
					if szStat == 'FINISH' then
						table.insert(aXml, GetFormatText(_L['r'], 162, 128, 255, 128))
					elseif szStat == 'PROGRESS' then
						table.insert(aXml, GetFormatText(_L['x'], 162, 173, 173, 173))
					else --if szStat == 'UNKNOWN' then
						table.insert(aXml, GetFormatText(_L['?'], 162, 173, 173, 173))
					end
					table.insert(aXml, GetFormatText(' ', 162, 255, 255, 255))
				end
				table.insert(aXml, GetFormatText(achi.szName, 162, 255, 255, 255))
				if not X.IsEmpty(aProgressCounter) then
					table.insert(aXml, GetFormatText(' (', 162, 255, 255, 255))
					for i, progress in ipairs(aProgressCounter) do
						local nTriggerVal = X.Get(X.GetAchievementInfo(progress.dwCounter), {'nTriggerVal'}, 1)
						if i ~= 1 then
							table.insert(aXml, GetFormatText(', ', 162, 255, 255, 255))
						end
						table.insert(aXml, GetFormatText(progress.nNumber .. '/' .. nTriggerVal, 162, 255, 255, 255))
					end
					table.insert(aXml, GetFormatText(')', 162, 255, 255, 255))
				end
				table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
			else
				table.insert(aXml, GetFormatText(_L[' '] .. achi.szName .. '\n', 162, 255, 255, 255))
			end
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
end

function D.UpdatePage(page)
	X.UI(page):Fetch('Wnd_Total/WndAutocomplete_Map')
		:Text(D.tMapName[D.dwMapID] or '', WNDEVENT_FIRETYPE.PREVENT)

	local hCols = page:Lookup('Wnd_Total/WndScroll_Stat', 'Handle_StatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetDispColumns(), 0, nil
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromData(page.hStatColumnData, 'Handle_StatColumn')
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
		if D.szSort == col.id then
			Sorter = function(r1, r2)
				if D.szSortOrder == 'asc' then
					return col.Compare(r1, r2) < 0
				end
				return col.Compare(r1, r2) > 0
			end
		end
		imgAsc:SetVisible(D.szSort == col.id and D.szSortOrder == 'asc')
		imgDesc:SetVisible(D.szSort == col.id and D.szSortOrder == 'desc')
		hCol:FormatAllItemPos()
		nX = nX + nWidth
	end
	hCols:FormatAllItemPos()

	local aRec = {}
	local aMemberList = D.GetMemberList()
	for _, tMember in ipairs(aMemberList) do
		table.insert(aRec, {
			id = tMember.dwID or tMember.szGlobalID,
			name = tMember.szName,
			force = tMember.dwForceID,
			achi = (tMember.dwID and ACHIEVE_CACHE[tMember.dwID])
				or (tMember.szGlobalID and ACHIEVE_CACHE[tMember.szGlobalID])
				or X.CONSTANT.EMPTY_TABLE,
		})
	end

	if Sorter then
		table.sort(aRec, Sorter)
	end

	local aCol = D.GetDispColumns()
	local hList = page:Lookup('Wnd_Total/WndScroll_Stat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(aRec) do
		local hRow = hList:AppendItemFromData(page.hRowData, 'Handle_Row')
		hRow.rec = rec
		hRow:Lookup('Image_RowBg'):SetVisible(i % 2 == 1)
		local nX = 0
		for j, col in ipairs(aCol) do
			local hItem = hRow:AppendItemFromData(page.hItemData, 'Handle_Item') -- 外部居中层
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

function D.DelayUpdatePage(page)
	X.DelayCall('MY_TeamTools_Achievement__DelayUpdatePage', 200, function()
		if X.IsElement(page) then
			D.UpdatePage(page)
		end
	end)
end

function D.SetSearch(szSearch)
	D.szSearch = szSearch
	D.UpdateAchievementID()
end

function D.OnInitPage()
	if not D.tMapMenu or not D.tMapName or not D.aMapName or not D.tMapID then
		local tMapMenu, tMapName, aMapName = {}, {}, {}
		table.insert(tMapMenu, {
			szOption = _L['All map'],
			fnAction = function()
				D.dwMapID = 0
				D.UpdateSearchAC()
				D.UpdateAchievementID()
				D.RequestTeamData()
				X.UI.ClosePopupMenu()
			end,
		})
		tMapName[0] = _L['All map']
		table.insert(aMapName, _L['All map'])
		table.insert(tMapMenu, {
			szOption = _L['Current map'],
			fnAction = function()
				D.dwMapID = X.GetClientPlayer().GetMapID()
				D.UpdateSearchAC()
				D.UpdateAchievementID()
				D.RequestTeamData()
				X.UI.ClosePopupMenu()
			end,
		})
		for _, group in ipairs(X.GetTypeGroupMap()) do
			local tSub = { szOption = group.szGroup }
			for _, info in ipairs(group.aMapInfo) do
				table.insert(tSub, {
					szOption = info.szName,
					fnAction = function()
						D.dwMapID = info.dwID
						D.UpdateSearchAC()
						D.UpdateAchievementID()
						D.RequestTeamData()
						X.UI.ClosePopupMenu()
					end
				})
				tMapName[info.dwID] = info.szName
				table.insert(aMapName, info.szName)
			end
			table.insert(tMapMenu, tSub)
		end
		D.tMapMenu = tMapMenu
		D.aMapName = aMapName
		D.tMapName = tMapName
		D.tMapID = X.FlipObjectKV(tMapName)
	end
	local frameTemp = X.UI.OpenFrame(SZ_INI, 'MY_TeamTools_Achievement')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	X.UI.CloseFrame(frameTemp)
	X.UI.AdaptComponentAppearance(wnd:Lookup('WndScroll_Stat/Scroll_Stat_All'))

	local nX = 20
	nX = nX + X.UI(wnd):Append('WndAutocomplete', {
		x = nX, y = 20, w = 250, h = 25,
		name = 'WndAutocomplete_Map',
		onChange = function(szText)
			if D.tMapID[szText] then
				D.dwMapID = D.tMapID[szText]
				D.UpdateSearchAC()
				D.UpdateAchievementID()
				D.RequestTeamData()
			end
		end,
		autocomplete = {{'option', 'source', D.aMapName}},
		menu = function() return D.tMapMenu end,
	}):Width() + 5

	nX = nX + X.UI(wnd):Append('WndAutocomplete', {
		x = nX, y = 20, w = 200, h = 25,
		name = 'WndAutocomplete_Search',
		text = D.szSearch,
		placeholder = _L['Search'],
		onChange = function(szText)
			X.Debounce(
				'MY_TeamTools_Achievement_Search',
				500,
				D.SetSearch,
				szText)
			X.Debounce('MY_TeamTools_Achievement_RequestTeamData', 2000, D.RequestTeamData)
		end,
		autocomplete = {{'option', 'source', D.aSearchAC}},
		onClick = function() X.UI(this):Autocomplete('search', '') end,
		onBlur = function()
			D.RequestTeamData()
			X.Debounce('MY_TeamTools_Achievement_RequestTeamData', false)
		end,
	}):Width() + 5

	nX = nX + X.UI(wnd):Append('WndCheckBox', {
		x = nX, y = 20, w = 200,
		text = _L['Intelligent hide'],
		checked = O.bIntelligentHide,
		onCheck = function(bChecked)
			O.bIntelligentHide = bChecked
			D.UpdateAchievementID()
		end,
		tip = {
			render = _L['Hide unimportant achievements'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	}):Width() + 5

	X.UI(wnd):Append('WndButton', {
		x = 960, y = 20, w = 120,
		text = _L['Refresh'],
		onClick = function()
			D.RequestTeamData()
			X.OutputSystemAnnounceMessage(_L['Team achievement request sent.'])
		end,
	})

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAM_TOOLS__ACHIEVE')
	frame:RegisterEvent('MY_TEAM_TOOLS__ACHIEVE_SEARCH_AC')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('NEW_ACHIEVEMENT')
	frame:RegisterEvent('SYNC_ACHIEVEMENT_DATA')
	frame:RegisterEvent('UPDATE_ACHIEVEMENT_POINT')
	frame:RegisterEvent('UPDATE_ACHIEVEMENT_COUNT')
	frame:RegisterEvent('PARTY_DELETE_MEMBER')
	frame:RegisterEvent('PARTY_DISBAND')
	frame:RegisterEvent('GLOBAL_ROOM_DETAIL_INFO')
	frame:RegisterEvent('MY_TEAM_TOOLS__STAT_RANGE_CHANGE')
	this.hRowData = frame:CreateItemData(SZ_INI, 'Handle_Row')
	this.hItemData = frame:CreateItemData(SZ_INI, 'Handle_Item')
	this.hStatColumnData = frame:CreateItemData(SZ_INI, 'Handle_StatColumn')
end

function D.OnActivePage()
	D.RequestTeamData()
	D.UpdatePage(this)
end

function D.OnEvent(event)
	if event == 'MY_TEAM_TOOLS__ACHIEVE' then
		D.DelayUpdatePage(this)
	elseif event == 'MY_TEAM_TOOLS__ACHIEVE_SEARCH_AC' then
		X.UI(this):Fetch('Wnd_Total/WndAutocomplete_Search'):Autocomplete('option', 'source', D.aSearchAC)
	elseif event == 'ON_MY_MOSAICS_RESET' then
		D.UpdatePage(this)
	elseif event == 'NEW_ACHIEVEMENT' or event == 'SYNC_ACHIEVEMENT_DATA'
		or event == 'UPDATE_ACHIEVEMENT_POINT' or event == 'UPDATE_ACHIEVEMENT_COUNT'
		or event == 'PARTY_DELETE_MEMBER' or event == 'PARTY_DISBAND'
		or event == 'GLOBAL_ROOM_DETAIL_INFO'
		or event == 'MY_TEAM_TOOLS__STAT_RANGE_CHANGE'
	then
		D.UpdateSelfData()
		D.DelayUpdatePage(this)
		D.DelayRequestTeamData()
	elseif event == 'PARTY_ADD_MEMBER' or event == 'PARTY_UPDATE_BASE_INFO' then
		D.DelayRequestTeamData()
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Clear' then
		X.Confirm(_L['Clear record'], D.ClearAchievementLog)
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
		if IsCtrlKeyDown() then
			if this.achieveid then
				X.InsertChatInput('achievement', this.achieveid)
			end
		elseif this.col.id then
			local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
			if D.szSort == this.col.id then
				D.szSortOrder = D.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				D.szSort = this.col.id
			end
			D.UpdatePage(page)
		end
	elseif name == 'Text_Achieve' then
		if not this.achieveid then
			return
		end
		if IsCtrlKeyDown() then
			if this.achieveid then
				X.InsertChatInput('achievement', this.achieveid)
			end
		else
			local AchievementPanel = _G.AchievementPanel or GetInsideEnv().AchievementPanel
			if AchievementPanel then
				AchievementPanel.Open(nil, this.achieveid)
			end
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

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamTools_Achievement_Module',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnDeactivePage',
				bStatRange = true,
			},
			root = D,
		},
	},
}
MY_TeamTools.RegisterModule('Achievement', _L['MY_TeamTools_Achievement'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamTools_Achievement',
	exports = {
		{
			fields = {
				'bIntelligentHide',
			},
			root = O,
		},
		{
			preset = 'UIEvent',
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'bIntelligentHide',
			},
			root = O,
		},
	},
}
MY_TeamTools_Achievement = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
