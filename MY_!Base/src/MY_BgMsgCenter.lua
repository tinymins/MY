--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背景通讯处理函数集成
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
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
-----------------------------------------------------------------------------------------------------------
-- 测试用（请求共享位置）
LIB.RegisterBgMsg('ASK_CURRENT_LOC', function(_, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf then
		return
	end
	MessageBox({
		szName = 'ASK_CURRENT_LOC' .. dwTalkerID,
		szMessage = _L('[%s] wants to get your location, would you like to share?', szTalkerName), {
			szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
				local me = GetClientPlayer()
				LIB.SendBgMsg(szTalkerName, 'REPLY_CURRENT_LOC', { me.GetMapID(), me.nX, me.nY, me.nZ })
			end
		}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
	})
end)

-- 测试用（查看版本信息）
LIB.RegisterBgMsg('MY_VERSION_CHECK', function(_, oData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf then
		return
	end
	local bSilent = oData[1]
	if not bSilent and LIB.IsInParty() then
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('I\'ve installed MY plugins v%s', LIB.GetVersion()))
	end
	LIB.SendBgMsg(szTalkerName, 'MY_VERSION_REPLY', LIB.GetVersion())
end)

-- 测试用（调试工具）
LIB.RegisterBgMsg('MY_GFN_CHECK', function(_, oData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf or LIB.IsDebugClient(true) then
		return
	end
	LIB.SendBgMsg(szTalkerName, 'MY_GFN_REPLY', {oData[1], XpCall(Get(_G, oData[2]), select(3, unpack(oData)))})
end)

-- 进组查看属性
LIB.RegisterBgMsg('RL', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not bIsSelf then
		if data[1] == 'ASK' then
			LIB.Confirm(_L('[%s] want to see your info, OK?', szName), function()
				local me = GetClientPlayer()
				local nGongZhan = LIB.GetBuff(me, 3219) and 1 or 0
				local bEx = PACKET_INFO.AUTHOR_ROLES[me.dwID] == me.szName and 'Author' or 'Player'
				LIB.SendBgMsg(szName, 'RL', {'Feedback', me.dwID, UI_GetPlayerMountKungfuID(), nGongZhan, bEx})
			end)
		end
	end
end)

-- 查看完整属性
LIB.RegisterBgMsg('CHAR_INFO', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not bIsSelf and data[2] == UI_GetClientPlayerID() then
		if data[1] == 'ASK'  then
			if not MY_CharInfo or MY_CharInfo.bEnable or data[3] == 'DEBUG' then
				local aInfo = LIB.GetCharInfo()
				if not LIB.IsParty(dwID) and not data[3] == 'DEBUG' then
					for _, v in ipairs(aInfo) do
						v.tip = nil
					end
				end
				LIB.SendBgMsg(LIB.IsParty(dwID) and PLAYER_TALK_CHANNEL.RAID or szName, 'CHAR_INFO', {'ACCEPT', dwID, aInfo})
			else
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', {'REFUSE', dwID})
			end
		end
	end
end)

-- 搬运JH_ABOUT
LIB.RegisterBgMsg('MY_ABOUT', function(_, data, nChannel, dwID, szName, bIsSelf)
	if data[1] == 'Author' then -- 版本检查 自用 可以绘制详细表格
		local me, szTong = GetClientPlayer(), ''
		if me.dwTongID > 0 then
			szTong = GetTongClient().ApplyGetTongName(me.dwTongID) or 'Failed'
		end
		local szServer = select(2, GetUserServer())
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_ABOUT', {'info',
			me.GetTotalEquipScore(),
			me.GetMapID(),
			szTong,
			me.nRoleType,
			PACKET_INFO.VERSION,
			szServer,
			LIB.GetBuff(me, 3219)
		})
	elseif data[1] == 'TeamAuth' then -- 防止有人睡着 遇到了不止一次了
		local team = GetClientTeam()
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwID)
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwID)
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
	elseif data[1] == 'TeamLeader' then
		GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwID)
	elseif data[1] == 'TeamMark' then
		GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwID)
	elseif data[1] == 'TeamDistribute' then
		GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
	elseif data[1] == 'SHIELDED' then
		LIB.IsShieldedVersion(data[2], data[3], data[4])
	elseif data[1] == 'DEBUG' then
		LIB.IsDebugClient(data[2], data[3], data[4])
	end
end)

-- 团队副本CD
do local LAST_TIME = {}
LIB.RegisterBgMsg('MY_MAP_COPY_ID_REQUEST', function(_, aData, nChannel, dwID, szName, bIsSelf)
	local dwMapID, aPlayerID = aData[1], aData[2]
	if LAST_TIME[dwMapID] and GetCurrentTime() - LAST_TIME[dwMapID] < 5 then
		return
	end
	if aPlayerID then
		local bResponse = false
		for _, dwID in ipairs(aPlayerID) do
			if dwID == UI_GetClientPlayerID() then
				bResponse = true
				break
			end
		end
		if not bResponse then
			return
		end
	end
	local function fnAction(tMapID)
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_MAP_COPY_ID', {dwMapID, tMapID[dwMapID] or -1})
	end
	LIB.GetMapSaveCopy(fnAction)
	LAST_TIME[dwMapID] = GetCurrentTime()
end)
end

-- 切换地图
do
local l_nSwitchMapID, l_nSwitchSubID
local l_nEnteringMapID, l_nEnteringSubID, l_dwEnteringTime, l_dwEnteringSwitchTime

-- 点击进入某地图（进入前）
local function OnSwitchMap(dwMapID, dwSubID, aMapCopy, dwTime)
	if not LIB.IsInParty() then
		return
	end
	l_nEnteringMapID = dwMapID
	l_nEnteringSubID = dwSubID
	l_dwEnteringSwitchTime = dwTime
	--[[#DEBUG BEGIN]]
	local szDebug = 'Switch map: ' .. dwMapID
	if dwSubID then
		szDebug = szDebug .. '(' .. dwSubID .. ')'
	end
	if aMapCopy then
		szDebug = szDebug .. ' #' .. concat(aMapCopy, ',')
	end
	if dwTime then
		szDebug = szDebug .. ' @' .. dwTime
	end
	LIB.Debug(PACKET_INFO.NAME_SPACE, szDebug, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_SWITCH_MAP', {dwMapID, dwSubID, aMapCopy, dwTime})
end

-- 成功进入某地图并加载完成（进入后）
local function OnEnterMap(dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime)
	if not LIB.IsInParty() then
		return
	end
	--[[#DEBUG BEGIN]]
	local szDebug = 'Enter map: ' .. dwMapID
	if dwSubID then
		szDebug = szDebug .. '(' .. dwSubID .. ')'
	end
	if aMapCopy then
		szDebug = szDebug .. ' #' .. concat(aMapCopy, ',')
	end
	if dwTime then
		szDebug = szDebug .. ' @' .. dwTime
	end
	if dwSwitchTime then
		szDebug = szDebug .. ' <- ' .. dwSwitchTime
	end
	LIB.Debug(PACKET_INFO.NAME_SPACE, szDebug, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_ENTER_MAP', {dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime})
end

local function OnCrossMapGoFB()
	local dwTime = GetCurrentTime()
	local dwMapID, dwID = this.tInfo.MapID, this.tInfo.ID
	-- 副本可重置且是队长则会弹出重置提示框 走 crossmap_dungeon_reset 流程
	if LIB.IsDungeonResetable(dwMapID) and LIB.IsLeader() then
		l_nSwitchMapID, l_nSwitchSubID = dwMapID, dwID
	else
		LIB.GetMapSaveCopy(dwMapID, function(aMapCopy)
			OnSwitchMap(dwMapID, dwID, aMapCopy, dwTime)
		end)
	end
	return LIB.FORMAT_WMSG_RET(true, true)
end

local function OnFBAppendItemFromIni(hList)
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		UnhookTableFunc(hItem, 'OnItemLButtonDBClick', OnCrossMapGoFB)
		HookTableFunc(hItem, 'OnItemLButtonDBClick', OnCrossMapGoFB, { bAfterOrigin = true, bHookReturn = true })
	end
end

LIB.RegisterFrameCreate('CrossMap.' .. PACKET_INFO.NAME_SPACE .. '#CD', function(name, frame)
	local hList = frame:Lookup('Wnd_CrossFB', 'Handle_DifficultyList')
	if hList then
		OnFBAppendItemFromIni(hList)
		HookTableFunc(hList, 'AppendItemFromIni', OnFBAppendItemFromIni, { bAfterOrigin = true })
	end
	local btn = frame:Lookup('Wnd_CrossFB/Btn_GoGoGo')
	if btn then
		HookTableFunc(btn, 'OnLButtonUp', OnCrossMapGoFB, { bAfterOrigin = true })
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug(PACKET_INFO.NAME_SPACE, 'Cross panel hooked.', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end)

LIB.RegisterEvent('MY_MESSAGE_BOX_ACTION.' .. PACKET_INFO.NAME_SPACE .. '#CD', function()
	if arg0 ~= 'crossmap_dungeon_reset' then
		return
	end
	if arg1 == 'ACTION' and arg2 == g_tStrings.STR_HOTKEY_SURE and l_nSwitchMapID then
		OnSwitchMap(l_nSwitchMapID, l_nSwitchSubID, nil, GetCurrentTime())
	end
	l_nSwitchMapID, l_nSwitchSubID = nil
end)

LIB.RegisterEvent('LOADING_ENDING.' .. PACKET_INFO.NAME_SPACE .. '#CD', function()
	l_dwEnteringTime = GetCurrentTime()
	local dwMapID = GetClientPlayer().GetMapID()
	LIB.GetMapSaveCopy(dwMapID, function(aMapCopy)
		local nSubID, dwSwitchTime
		if dwMapID == l_nEnteringMapID then
			nSubID, dwSwitchTime = l_nEnteringSubID, l_dwEnteringSwitchTime
		end
		OnEnterMap(dwMapID, nSubID, aMapCopy, l_dwEnteringTime, dwSwitchTime)
	end)
end)

LIB.RegisterBgMsg('MY_ENTER_MAP_REQ', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not l_dwEnteringTime then
		return
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug(PACKET_INFO.NAME_SPACE, 'Enter map request from ' .. szTalkerName, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local dwMapID = GetClientPlayer().GetMapID()
	LIB.GetMapSaveCopy(dwMapID, function(aMapCopy)
		local nSubID, dwSwitchTime
		if dwMapID == l_nEnteringMapID then
			nSubID, dwSwitchTime = l_nEnteringSubID, l_dwEnteringSwitchTime
		end
		OnEnterMap(dwMapID, nSubID, aMapCopy, l_dwEnteringTime, dwSwitchTime)
	end)
end)
end

do local LAST_ACHI_TIME, LAST_COUNTER_TIME = {}, {}
LIB.RegisterBgMsg('MY_TEAMTOOLS_ACHI_REQ', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf then
		--[[#DEBUG BEGIN]]
		LIB.Debug(PACKET_INFO.NAME_SPACE, 'Team achievement request sent.', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		return
	end
	local aAchieveID, aCounterID, aRequestID, aRefreshID = data[1], data[2], data[3], data[4]
	local dwID = UI_GetClientPlayerID()
	local bRequest, bRefresh, bResponse = false, false, false
	if not bResponse then
		if aRequestID then
			for _, v in ipairs(aRequestID) do
				if bRequest then
					break
				end
				if v == dwID then
					bRequest = true
				end
			end
		else
			bRequest = true
		end
		if bRequest then
			bResponse = true
		end
	end
	if not bResponse then
		if aRefreshID then
			for _, v in ipairs(aRefreshID) do
				if bRefresh then
					break
				end
				if v == dwID then
					bRefresh = true
				end
			end
		else
			bRefresh = true
		end
		if bRefresh then
			for _, vv in ipairs(aAchieveID) do
				if bResponse then
					break
				end
				if not LAST_ACHI_TIME[vv] then
					bResponse = true
				end
			end
			for _, vv in ipairs(aCounterID) do
				if bResponse then
					break
				end
				if not LAST_COUNTER_TIME[vv] then
					bResponse = true
				end
			end
		end
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug(PACKET_INFO.NAME_SPACE, 'Achievement request from ' .. szTalkerName
		.. ', will ' .. (bResponse and '' or 'not ') .. 'response.', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	if bResponse then
		local me = GetClientPlayer()
		local aAchieveRes, aCounterRes = {}, {}
		for _, dwAchieveID in ipairs(aAchieveID) do
			LAST_ACHI_TIME[dwAchieveID] = GetCurrentTime()
			insert(aAchieveRes, {dwAchieveID, me.IsAchievementAcquired(dwAchieveID)})
		end
		for _, dwCounterID in ipairs(aCounterID) do
			LAST_COUNTER_TIME[dwCounterID] = GetCurrentTime()
			insert(aCounterRes, {dwCounterID, me.GetAchievementCount(dwCounterID)})
		end
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TEAMTOOLS_ACHI_RES', {aAchieveRes, aCounterRes})
	end
end)
LIB.RegisterEvent({
	'NEW_ACHIEVEMENT',
	'SYNC_ACHIEVEMENT_DATA',
	'UPDATE_ACHIEVEMENT_POINT',
	'UPDATE_ACHIEVEMENT_COUNT',
}, function()
	LAST_ACHI_TIME, LAST_COUNTER_TIME = {}, {}
end)
end
