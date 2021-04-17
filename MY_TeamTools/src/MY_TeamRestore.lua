--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 保存团队
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamRestore'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local DATA_PATH = {'userdata/team_restore.jx3dat', PATH_TYPE.SERVER}
local D = {}
local O = {
	bKeepMark = true,
	bKeepForm = true,
	SaveList = LIB.LoadLUAData(DATA_PATH) or {},
	szMarkImage = PARTY_MARK_ICON_PATH,
	tMarkFrame = PARTY_MARK_ICON_FRAME_LIST,
}

function D.LoadLUAData()
	O.SaveList = LIB.LoadLUAData(DATA_PATH) or {}
end

function D.SaveLUAData()
	LIB.SaveLUAData(DATA_PATH, O.SaveList)
end

function D.Save(nIndex, szName)
	local tList, tList2, me, team = {}, {}, GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return LIB.Sysmsg(_L['You are not in a team'], CONSTANT.MSG_THEME.ERROR)
	end
	local tSave = {}
	tSave.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	tSave.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	tSave.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	tSave.nLootMode = team.nLootMode
	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		tList2[nGroup] = {}
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			local info = team.GetMemberInfo(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
				insert(tList2[nGroup], {
					dwMountKungfuID = info.dwMountKungfuID,
					nMark = tMark[dwID],
					bForm = dwID == tGroupInfo.dwFormationLeader,
					nGroup = nGroup,
				})
			end
		end
	end
	szName = LIB.TrimString(szName)
	if IsEmpty(szName) then
		szName = LIB.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss')
	end
	tSave.name = szName
	tSave.data = tList
	tSave.data2 = tList2
	-- saved ok
	if not nIndex or nIndex > #O.SaveList then
		nIndex = #O.SaveList + 1
	end
	O.SaveList[nIndex] = tSave
	D.SaveLUAData()
	LIB.Sysmsg(_L['Team list data saved'])
end
function D.Delete(nIndex)
	remove(O.SaveList, nIndex)
	D.SaveLUAData()
end
function D.SyncMember(team, dwID, szName, state)
	if O.bKeepForm and state.bForm then --如果这货之前有阵眼
		team.SetTeamFormationLeader(dwID, state.nGroup) -- 阵眼给他
		LIB.Sysmsg(_L('Restore formation of %d group: %s', state.nGroup + 1, szName))
	end
	if O.bKeepMark and state.nMark then -- 如果这货之前有标记
		team.SetTeamMark(state.nMark, dwID) -- 标记给他
		LIB.Sysmsg(_L('Restore player marked as [%s]: %s', LIB.GetMarkName(state.nMark), szName))
	end
end

function D.GetWrongIndex(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end

function D.Restore(n)
	-- 获取自己和团队操作对象
	local me, team = GetClientPlayer(), GetClientTeam()
	-- update之前保存的团队列表
	D.LoadLUAData()

	if not me or not me.IsInParty() then
		return LIB.Sysmsg(_L['You are not in a team'], CONSTANT.MSG_THEME.ERROR)
	elseif not O.SaveList[n] then
		return LIB.Sysmsg(_L['You have not saved team list data'], CONSTANT.MSG_THEME.ERROR)
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return LIB.Sysmsg(_L['You are not team leader, permission denied'], CONSTANT.MSG_THEME.ERROR)
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = O.SaveList[n].data, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				LIB.Sysmsg(_L('Unable get player of %d group: #%d', nGroup + 1, dwID), CONSTANT.MSG_THEME.ERROR)
			else
				if not tSaved[szName] then
					szName = gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					LIB.Sysmsg(_L('Unknown status: %s', szName))
				elseif state.nGroup == nGroup then
					D.SyncMember(team, dwID, szName, state)
					LIB.Sysmsg(_L('Need not adjust: %s', szName))
				else
					insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == O.SaveList[n].szLeader then
					dwLeader = dwID
				end
				if szName == O.SaveList[n].szMark then
					dwMark = dwID
				end
				if szName == O.SaveList[n].szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE,dwID)
					LIB.Sysmsg(_L('Restore distributor: %s', szName))
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = D.GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = D.GetWrongIndex(tWrong[src.state.nGroup], false)
			remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- 直接丢过去
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					insert(tWrong[nGroup], dst)
				else -- bingo
					LIB.Sysmsg(_L('Change group of [%s] to %d', dst.szName, nGroup + 1))
					D.SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			LIB.Sysmsg(_L('Change group of [%s] to %d', src.szName, src.state.nGroup + 1))
			D.SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = D.GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= O.SaveList[n].nLootMode then
		team.SetTeamLootMode(O.SaveList[n].nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		LIB.Sysmsg(_L('Restore team marker: %s', O.SaveList[n].szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		LIB.Sysmsg(_L('Restore team leader: %s', O.SaveList[n].szLeader))
	end
	LIB.Sysmsg(_L['Team list restored'])
end

function D.Restore2(n)
	D.LoadLUAData()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return LIB.Sysmsg(_L['You are not in a team'], CONSTANT.MSG_THEME.ERROR)
	elseif not O.SaveList[n] then
		return LIB.Sysmsg(_L['You have not saved team list data'], CONSTANT.MSG_THEME.ERROR)
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return LIB.Sysmsg(_L['You are not team leader, permission denied'], CONSTANT.MSG_THEME.ERROR)
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	local tSaved, tWrong, dwLeader, dwMark = O.SaveList[n].data2, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for k,v in pairs(tGroupInfo.MemberList) do
			local info = team.GetMemberInfo(v)
			tWrong[v] = { nGroup = nGroup, dwMountKungfuID = info.dwMountKungfuID }
		end
	end

	local fnAction = function(dwMountKungfuID,nGroup,dwID)
		for k,v in pairs(tWrong) do
			if dwMountKungfuID and v.dwMountKungfuID == dwMountKungfuID then -- 只要内功匹配的人
				return k,v
			elseif nGroup and v.nGroup == nGroup and k ~= dwID then -- 不是自己的同组人要一个
				return k,v
			end
		end
		return false,false
	end

	for nGroup,tGroup in pairs(tSaved) do
		for k,v in ipairs(tGroup) do
			local tGroupInfo = team.GetGroupInfo(nGroup)
			local dwID,tab = fnAction(v.dwMountKungfuID)
			if dwID then
				local info = team.GetMemberInfo(dwID)
				if nGroup == tab.nGroup then
					tWrong[dwID] = nil
					LIB.Sysmsg(_L('Need not adjust: %s', info.szName))
					D.SyncMember(team, dwID, info.szName, v)
				else
					if #tGroupInfo.MemberList < 5 then
						team.ChangeMemberGroup(dwID,nGroup,0)
						tWrong[dwID] = nil
						LIB.Sysmsg(_L('Change group of [%s] to %d', info.szName, nGroup + 1))
						D.SyncMember(team, dwID, info.szName, v)
					else
						local ddwID,dtab = fnAction(false,nGroup,dwID)
						if ddwID then
							team.ChangeMemberGroup(dwID,nGroup,ddwID)
							tWrong[ddwID].nGroup = tab.nGroup -- update
							tWrong[dwID] = nil
							LIB.Sysmsg(_L('Change group of [%s] to %d', info.szName, nGroup + 1))
							D.SyncMember(team, dwID, info.szName, v)
						end
					end
				end
			end
		end
	end
	-- restore others
	if team.nLootMode ~= O.SaveList[n].nLootMode then
		team.SetTeamLootMode(O.SaveList[n].nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		LIB.Sysmsg(_L('Restore team marker: %s', O.SaveList[n].szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		LIB.Sysmsg(_L('Restore team leader: %s', O.SaveList[n].szLeader))
	end
	LIB.Sysmsg(_L['Team list restored'])
end

function D.OnPanelActivePartial(ui, X, Y, W, H, nX, nY)
	nX = X
	nX, nY = ui:Append('Text', { x = nX, y = nY + 15, text = _L['MY_TeamRestore'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = X + 10
	nY = nY + 5
	for i, v in ipairs(O.SaveList) do
		nX = ui:Append('WndButton', {
			x = nX + 5, y = nY, w = 80, text = v.name,
			buttonstyle = 'FLAT',
			tip = v.name .. '\n' .. _L['Left click to recovery, right click for more.'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
			onlclick = function()
				if IsCtrlKeyDown() then
					D.Restore2(i)
				else
					D.Restore(i)
				end
			end,
			rmenu = function()
				local menu = {
					{
						szOption = _L['Restore'],
						fnAction = function()
							D.Restore(i)
						end,
					},
					{
						szOption = _L['Restore2'],
						fnAction = function()
							D.Restore2(i)
						end,
					},
					{
						szOption = _L['Delete'],
						fnAction = function()
							D.Delete(i)
							LIB.SwitchTab('MY_TeamTools', true)
						end,
					},
					{
						szOption = _L['Rename'],
						fnAction = function()
							GetUserInput(_L['Save team name'], function(text)
								text = LIB.TrimString(text)
								if not IsEmpty(text) then
									v.name = text
									D.SaveLUAData()
									LIB.SwitchTab('MY_TeamTools', true)
								end
							end, nil, nil, nil, nil, 50)
						end,
					},
					{
						szOption = _L['Replace'],
						fnAction = function()
							D.Save(i)
						end,
					},
				}
				local menu1 = { szOption = _L['Detail'] }
				insert(menu1, { szOption = _L('Leader:%s', v['szLeader']) })
				insert(menu1, { szOption = _L('Distribute:%s', v['szDistribute']) })
				insert(menu1, { szOption = _L('Mark:%s', v['szMark']) })
				insert(menu1, { bDevide = true })
				for i = 1, 5 do
					insert(menu1, { szOption = _L('Party %d', i) })
				end
				for kk, vv in pairs(v['data']) do
					insert(menu1[5 + vv.nGroup], { szOption = kk })
				end
				insert(menu, menu1)
				return menu
			end,
		}):Pos('BOTTOMRIGHT') + 10
		if nX + 80 > W then
			nX = X + 10
			nY = nY + 28
		end
	end

	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY, text = _L['Save Team'],
		buttonstyle = 'FLAT',
		onclick = function()
			GetUserInput(_L['Save team name'], function(text)
				D.Save(nil, text)
				LIB.SwitchTab('MY_TeamTools', true)
			end, nil, nil, nil, nil, 50)
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 28

	return nX, nY
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_TeamRestore = LIB.GeneGlobalNS(settings)
end
