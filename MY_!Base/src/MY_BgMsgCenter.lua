--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背景通讯处理函数集成
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local ipairs_r = LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
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
LIB.RegisterBgMsg('MY_VERSION_CHECK', function(_, nChannel, dwTalkerID, szTalkerName, bSelf, bSilent)
	if bSelf then
		return
	end
	if not bSilent and LIB.IsInParty() then
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, _L('I\'ve installed MY plugins v%s', LIB.GetVersion()))
	end
	LIB.SendBgMsg(szTalkerName, 'MY_VERSION_REPLY', LIB.GetVersion())
end)

-- 测试用（调试工具）
LIB.RegisterBgMsg('MY_GFN_CHECK', function(_, nChannel, dwTalkerID, szTalkerName, bSelf, szKey, szGFN, ...)
	if bSelf or LIB.IsDebugClient(true) then
		return
	end
	LIB.SendBgMsg(szTalkerName, 'MY_GFN_REPLY', szKey, XpCall(Get(_G, szGFN), ...))
end)

-- 进组查看属性
LIB.RegisterBgMsg('RL', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf then
		if data[1] == 'ASK' then
			LIB.Confirm(_L('[%s] want to see your info, OK?', szName), function()
				local me = GetClientPlayer()
				local nGongZhan = LIB.GetBuff(3219) and 1 or 0
				local bEx = LIB.GetAddonInfo().tAuthor[me.dwID] == me.szName and 'Author' or 'Player'
				LIB.SendBgMsg(szName, 'RL', 'Feedback', me.dwID, UI_GetPlayerMountKungfuID(), nGongZhan, bEx)
			end)
		end
	end
end)

-- 查看完整属性
LIB.RegisterBgMsg('CHAR_INFO', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf and data[2] == UI_GetClientPlayerID() then
		if data[1] == 'ASK'  then
			if not MY_CharInfo or MY_CharInfo.bEnable or data[3] == 'DEBUG' then
				local aInfo = LIB.GetCharInfo()
				if not LIB.IsParty(dwID) and not data[3] == 'DEBUG' then
					for _, v in ipairs(aInfo) do
						v.tip = nil
					end
				end
				LIB.SendBgMsg(LIB.IsParty(dwID) and PLAYER_TALK_CHANNEL.RAID or szName, 'CHAR_INFO', 'ACCEPT', dwID, aInfo)
			else
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', 'REFUSE', dwID)
			end
		end
	end
end)

-- 搬运JH_ABOUT
LIB.RegisterBgMsg('MY_ABOUT', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if data[1] == 'Author' then -- 版本检查 自用 可以绘制详细表格
		local me, szTong = GetClientPlayer(), ''
		if me.dwTongID > 0 then
			szTong = GetTongClient().ApplyGetTongName(me.dwTongID) or 'Failed'
		end
		local szServer = select(2, GetUserServer())
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_ABOUT', 'info',
			me.GetTotalEquipScore(),
			me.GetMapID(),
			szTong,
			me.nRoleType,
			LIB.GetAddonInfo().dwVersion,
			szServer,
			LIB.GetBuff(3219)
		)
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
	end
end)

-- 团队副本CD
do local LAST_TIME = {}
LIB.RegisterBgMsg('MY_MAP_COPY_ID_REQUEST', function(_, nChannel, dwID, szName, bIsSelf, dwMapID, aPlayerID)
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
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_MAP_COPY_ID', dwMapID, tMapID[dwMapID] or -1)
	end
	LIB.GetMapSaveCopy(fnAction)
	LAST_TIME[dwMapID] = GetCurrentTime()
end)
end

-- 进入团队副本
do local MSG_MAP_ID, MSG_ID
local function OnSwitchMap(dwMapID, dwID, dwCopyID)
	if not LIB.IsInParty() then
		return
	end
	LIB.Debug({'Switch dungeon :' .. dwMapID}, LIB.GetAddonInfo().szNameSpace, DEBUG_LEVEL.LOG)
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_SWITCH_MAP', dwMapID, dwID, dwCopyID)
end

local function OnCrossMapGoFB()
	local dwMapID, dwID = this.tInfo.MapID, this.tInfo.ID
	if not LIB.IsDungeonResetable(dwMapID) or (LIB.IsInParty() and not LIB.IsLeader()) then
		OnSwitchMap(dwMapID, dwID, LIB.GetMapSaveCopy(dwMapID))
	else
		MSG_MAP_ID, MSG_ID = dwMapID, dwID
	end
	return FORMAT_WMSG_RET(true, true)
end

local function OnFBAppendItemFromIni(hList)
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		UnhookTableFunc(hItem, 'OnItemLButtonDBClick', OnCrossMapGoFB)
		HookTableFunc(hItem, 'OnItemLButtonDBClick', OnCrossMapGoFB, { bAfterOrigin = true, bHookReturn = true })
	end
end

LIB.RegisterFrameCreate('CrossMap.' .. LIB.GetAddonInfo().szNameSpace .. '#CD', function(name, frame)
	local hList = frame:Lookup('Wnd_CrossFB', 'Handle_DifficultyList')
	if hList then
		OnFBAppendItemFromIni(hList)
		HookTableFunc(hList, 'AppendItemFromIni', OnFBAppendItemFromIni, { bAfterOrigin = true })
	end
	local btn = frame:Lookup('Wnd_CrossFB/Btn_GoGoGo')
	if btn then
		HookTableFunc(btn, 'OnLButtonUp', OnCrossMapGoFB, { bAfterOrigin = true })
	end
	LIB.Debug({'Cross panel hooked.'}, LIB.GetAddonInfo().szNameSpace, DEBUG_LEVEL.LOG)
end)

LIB.RegisterEvent('MY_MESSAGE_BOX_ACTION.' .. LIB.GetAddonInfo().szNameSpace .. '#CD', function()
	if arg0 ~= 'crossmap_dungeon_reset' then
		return
	end
	if arg1 == 'ACTION' and arg2 == g_tStrings.STR_HOTKEY_SURE and MSG_MAP_ID then
		OnSwitchMap(MSG_MAP_ID, MSG_ID, nil)
	end
	MSG_MAP_ID = nil
end)
end
