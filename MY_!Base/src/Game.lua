--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��Ϸ������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
local _L = LIB.LoadLangPack()

-- #######################################################################################################
--                                 #                   # # # #   # # # #
--     # # # #   # # # # #       # # # # # # #         #     #   #     #
--     #     #   #       #     #   #       #           # # # #   # # # #
--     #     #   #       #           # # #                     #     #
--     # # # #   #   # #         # #       # #                 #       #
--     #     #   #           # #     #         # #   # # # # # # # # # # #
--     #     #   # # # # #           #                       #   #
--     # # # #   #   #   #     # # # # # # # #           # #       # #
--     #     #   #   #   #         #         #       # #               # #
--     #     #   #     #           #         #         # # # #   # # # #
--     #     #   #   #   #       #           #         #     #   #     #
--   #     # #   # #     #     #         # #           # # # #   # # # #
-- #######################################################################################################
-- ��ȡ��ǰ����������
function LIB.GetServer(nIndex)
	local display_region, display_server, region, server = GetUserServer()
	region = region or display_region
	server = server or display_server
	if nIndex == 1 then
		return region
	elseif nIndex == 2 then
		return server
	else
		return region .. '_' .. server, {region, server}
	end
end

-- ��ȡ��ǰ��������ʾ����
function LIB.GetDisplayServer(nIndex)
	local display_region, display_server = GetUserServer()
	if nIndex == 1 then
		return display_region
	elseif nIndex == 2 then
		return display_server
	else
		return display_region .. '_' .. display_server, {display_region, display_server}
	end
end

-- ��ȡ���ݻ�ͨ������������
function LIB.GetRealServer(nIndex)
	local display_region, display_server, _, _, real_region, real_server = GetUserServer()
	real_region = real_region or display_region
	real_server = real_server or display_server
	if nIndex == 1 then
		return real_region
	elseif nIndex == 2 then
		return real_server
	else
		return real_region .. '_' .. real_server, {real_region, real_server}
	end
end

do
local S2L_CACHE = setmetatable({}, { __mode = 'k' })
local L2S_CACHE = setmetatable({}, { __mode = 'k' })
function LIB.ConvertNpcID(dwID, eType)
	if IsPlayer(dwID) then
		if not S2L_CACHE[dwID] then
			S2L_CACHE[dwID] = { dwID + 0x40000000 }
		end
		return eType == 'short' and dwID or S2L_CACHE[dwID][1]
	else
		if not L2S_CACHE[dwID] then
			L2S_CACHE[dwID] = { dwID - 0x40000000 }
		end
		return eType == 'long' and dwID or L2S_CACHE[dwID][1]
	end
end
end

do
local DISTANCE_TYPE
local PATH = {'config/distance_type.jx3dat', PATH_TYPE.ROLE}
function LIB.GetGlobalDistanceType()
	if not DISTANCE_TYPE then
		DISTANCE_TYPE = LIB.LoadLUAData(PATH) or 'gwwean'
	end
	return DISTANCE_TYPE
end

function LIB.SetGlobalDistanceType(szType)
	DISTANCE_TYPE = szType
	LIB.SaveLUAData(PATH, DISTANCE_TYPE)
end

function LIB.GetDistanceTypeList(bGlobal)
	local t = {
		{ szType = 'gwwean', szText = _L.DISTANCE_TYPE['gwwean'] },
		{ szType = 'euclidean', szText = _L.DISTANCE_TYPE['euclidean'] },
		{ szType = 'plane', szText = _L.DISTANCE_TYPE['plane'] },
	}
	if (bGlobal) then
		insert(t, { szType = 'global', szText = _L.DISTANCE_TYPE['global'] })
	end
	return t
end

function LIB.GetDistanceTypeMenu(bGlobal, eValue, fnAction)
	local t = {}
	for _, p in ipairs(LIB.GetDistanceTypeList(true)) do
		local t1 = {
			szOption = p.szText,
			bCheck = true, bMCheck = true,
			bChecked = p.szType == eValue,
			UserData = p,
			fnAction = fnAction,
		}
		if p.szType == 'global' then
			t1.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
			t1.nFrame = 105
			t1.nMouseOverFrame = 106
			t1.szLayer = 'ICON_RIGHTMOST'
			t1.fnClickIcon = function()
				LIB.OpenPanel()
				LIB.SwitchTab('GlobalConfig')
				Wnd.CloseWindow('PopupMenuPanel')
			end
		end
		insert(t, t1)
	end
	return t
end
end

-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- LIB.GetDistance(OObject[, szType])
-- LIB.GetDistance(nX, nY)
-- LIB.GetDistance(nX, nY, nZ[, szType])
-- LIB.GetDistance(OObject1, OObject2[, szType])
-- LIB.GetDistance(OObject1, nX2, nY2)
-- LIB.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- LIB.GetDistance(nX1, nY1, nX2, nY2)
-- LIB.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': ŷ�Ͼ��� (default)
--         'plane'    : ƽ�����
--         'gwwean'   : ���Ͼ���
--         'global'   : ʹ��ȫ������
function LIB.GetDistance(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	local szType
	local nX1, nY1, nZ1 = 0, 0, 0
	local nX2, nY2, nZ2 = 0, 0, 0
	if IsTable(arg0) then
		arg0 = LIB.GetObject(unpack(arg0))
		if not arg0 then
			return
		end
	end
	if IsTable(arg1) then
		arg1 = LIB.GetObject(unpack(arg1))
		if not arg1 then
			return
		end
	end
	if IsUserdata(arg0) then -- OObject -
		nX1, nY1, nZ1 = arg0.nX, arg0.nY, arg0.nZ
		if IsUserdata(arg1) then -- OObject1, OObject2
			nX2, nY2, nZ2, szType = arg1.nX, arg1.nY, arg1.nZ, arg2
		elseif IsNumber(arg1) and IsNumber(arg2) then -- OObject1, nX2, nY2
			if IsNumber(arg3) then -- OObject1, nX2, nY2, nZ2[, szType]
				nX2, nY2, nZ2, szType = arg1, arg2, arg3, arg4
			else -- OObject1, nX2, nY2[, szType]
				nX2, nY2, szType = arg1, arg2, arg3
			end
		else -- OObject[, szType]
			local me = GetClientPlayer()
			nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg1
		end
	elseif IsNumber(arg0) and IsNumber(arg1) then -- nX1, nY1 -
		if IsNumber(arg2) then
			if IsNumber(arg3) then
				if IsNumber(arg4) and IsNumber(arg5) then -- nX1, nY1, nZ1, nX2, nY2, nZ2[, szType]
					nX1, nY1, nZ1, nX2, nY2, nZ2, szType = arg0, arg1, arg2, arg3, arg4, arg5, arg6
				else -- nX1, nY1, nX2, nY2[, szType]
					nX1, nY1, nX2, nY2, szType = arg0, arg1, arg2, arg3, arg4
				end
			else -- nX1, nY1, nZ1[, szType]
				local me = GetClientPlayer()
				nX1, nY1, nZ1, nX2, nY2, nZ2, szType = me.nX, me.nY, me.nZ, arg0, arg1, arg2, arg3
			end
		else -- nX1, nY1
			local me = GetClientPlayer()
			nX1, nY1, nX2, nY2 = me.nX, me.nY, arg0, arg1
		end
	end
	if not szType or szType == 'global' then
		szType = LIB.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return max(floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, floor(abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

do local BUFF_CACHE = {}
function LIB.GetBuffName(dwBuffID, dwLevel)
	local xKey = dwBuffID
	if dwLevel then
		xKey = dwBuffID .. '_' .. dwLevel
	end
	if not BUFF_CACHE[xKey] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			BUFF_CACHE[xKey] = { tLine.szName, tLine.dwIconID }
		else
			local szName = 'BUFF#' .. dwBuffID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			BUFF_CACHE[xKey] = { szName, 1436 }
		end
	end
	return unpack(BUFF_CACHE[xKey])
end
end

function LIB.GetEndTime(nEndFrame)
	return (nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
end

-- ��ȡָ�����ֵ��Ҽ��˵�
function LIB.GetTargetContextMenu(dwType, szName, dwID)
	local t = {}
	if dwType == TARGET.PLAYER then
		-- ����
		table.insert(t, {
			szOption = _L['copy'],
			fnAction = function()
				LIB.Talk(GetClientPlayer().szName, '[' .. szName .. ']')
			end,
		})
		-- ����
		-- table.insert(t, {
		--     szOption = _L['whisper'],
		--     fnAction = function()
		--         LIB.SwitchChat(szName)
		--     end,
		-- })
		-- ���� ���� ������� ����
		Call(InsertPlayerCommonMenu, t, dwID, szName)
		-- insert invite team
		if szName and InsertInviteTeamMenu then
			InsertInviteTeamMenu(t, szName)
		end
		-- get dwID
		if not dwID and MY_Farbnamen then
			local tInfo = MY_Farbnamen.GetAusName(szName)
			if tInfo then
				dwID = tonumber(tInfo.dwID)
			end
		end
		-- insert view equip
		if dwID and UI_GetClientPlayerID() ~= dwID then
			table.insert(t, {
				szOption = _L['show equipment'],
				fnAction = function()
					ViewInviteToPlayer(dwID)
				end,
			})
		end
		-- insert view arena
		table.insert(t, {
			szOption = g_tStrings.LOOKUP_CORPS,
			-- fnDisable = function() return not GetPlayer(dwID) end,
			fnAction = function()
				Wnd.CloseWindow('ArenaCorpsPanel')
				OpenArenaCorpsPanel(true, dwID)
			end,
		})
	end
	-- view qixue -- mark target
	if dwID and InsertTargetMenu then
		local tx = {}
		InsertTargetMenu(tx, dwType, dwID, szName)
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.LOOKUP_INFO then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then -- �鿴��Ѩ
						table.insert(t, vv)
						break
					end
				end
				break
			end
		end
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.STR_ARENA_INVITE_TARGET -- ������������
			or v.szOption == g_tStrings.LOOKUP_INFO             -- �鿴������Ϣ
			or v.szOption == g_tStrings.CHANNEL_MENTOR          -- ʦͽ
			or v.szOption == g_tStrings.STR_ADD_SHANG           -- ��������
			or v.szOption == g_tStrings.STR_MARK_TARGET         -- ���Ŀ��
			or v.szOption == g_tStrings.STR_MAKE_TRADDING       -- ����
			or v.szOption == g_tStrings.REPORT_RABOT            -- �ٱ����
			then
				table.insert(t, v)
			end
		end
	end

	return t
end

-- ��ȡ����ѡ��˵�
-- (table) LIB.GetDungeonMenu(fnAction, bOnlyRaid)
do
local function RecruitItemToDungeonMenu(p, fnAction, tChecked)
	if p.bParent then
		local t = { szOption = p.TypeName or p.SubTypeName }
		for _, pp in ipairs(p) do
			insert(t, RecruitItemToDungeonMenu(pp, fnAction, tChecked))
		end
		if #t > 0 then
			return t
		end
	else
		-- ������Ӫ �е�ͼID 7�㿪ʼ ����24Сʱ �������Ǹ�����
		if p.nCamp == 7
		and p.nStartTime == 7 and p.nLastTime == 24
		and p.dwMapID and LIB.IsDungeonMap(p.dwMapID) then
			return {
				szOption = p.szName,
				bCheck = tChecked and true or false,
				bChecked = tChecked and tChecked[p.dwMapID] or false,
				bDisable = false,
				UserData = {
					dwID = p.dwMapID,
					szName = p.szName,
				},
				fnAction = fnAction,
			}
		end
	end
	return nil
end
function LIB.GetDungeonMenu(fnAction, bOnlyRaid, tChecked)
	local t = {}
	for _, p in ipairs(LIB.Table_GetTeamRecruit() or {}) do
		insert(t, RecruitItemToDungeonMenu(p, fnAction, tChecked))
	end
	return t
end
end

-- ��ȡ����CD�б����첽��
-- (table) LIB.GetMapSaveCopy(fnAction)
-- (number|nil) LIB.GetMapSaveCopy(dwMapID, fnAction)
do
local QUEUE = {}
local SAVED_COPY_CACHE, REQUEST_FRAME
function LIB.GetMapSaveCopy(arg0, arg1)
	local dwMapID, fnAction
	if IsFunction(arg0) then
		fnAction = arg0
	elseif IsNumber(arg0) then
		if IsFunction(arg1) then
			fnAction = arg1
		end
		dwMapID = arg0
	end
	if SAVED_COPY_CACHE then
		if dwMapID then
			if fnAction then
				fnAction(SAVED_COPY_CACHE[dwMapID])
			end
			return SAVED_COPY_CACHE[dwMapID]
		else
			if fnAction then
				fnAction(SAVED_COPY_CACHE)
			end
			return SAVED_COPY_CACHE
		end
	else
		if fnAction then
			insert(QUEUE, { dwMapID = dwMapID, fnAction = fnAction })
		end
		if REQUEST_FRAME ~= GetLogicFrameCount() then
			ApplyMapSaveCopy()
			REQUEST_FRAME = GetLogicFrameCount()
		end
	end
end

function LIB.IsDungeonResetable(dwMapID)
	if not SAVED_COPY_CACHE then
		return
	end
	if not LIB.IsDungeonMap(dwMapID, false) then
		return false
	end
	return SAVED_COPY_CACHE[dwMapID]
end

local function onApplyPlayerSavedCopyRespond()
	SAVED_COPY_CACHE = arg0
	for _, v in ipairs(QUEUE) do
		if v.dwMapID then
			v.fnAction(SAVED_COPY_CACHE[v.dwMapID])
		else
			v.fnAction(SAVED_COPY_CACHE)
		end
	end
	QUEUE = {}
end
LIB.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', onApplyPlayerSavedCopyRespond)

local function onCopyUpdated()
	SAVED_COPY_CACHE = nil
end
LIB.RegisterEvent('ON_RESET_MAP_RESPOND', onCopyUpdated)
LIB.RegisterEvent('ON_MAP_COPY_PROGRESS_UPDATE', onCopyUpdated)
end

-- ��ͼBOSS�б�
do local BOSS_LIST, BOSS_LIST_CUSTOM
local CACHE_PATH = {'temporary/bosslist.jx3dat', PATH_TYPE.GLOBAL}
local CUSTOM_PATH = {'config/bosslist.jx3dat', PATH_TYPE.GLOBAL}
local function LoadCustomList()
	if not BOSS_LIST_CUSTOM then
		BOSS_LIST_CUSTOM = LIB.LoadLUAData(CUSTOM_PATH) or {}
	end
end
local function SaveCustomList()
	LIB.SaveLUAData(CUSTOM_PATH, BOSS_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if BOSS_LIST and not bForceRefresh then
		return
	end
	LIB.CreateDataRoot(PATH_TYPE.GLOBAL)
	BOSS_LIST = LIB.LoadLUAData(CACHE_PATH)
	if bForceRefresh or not BOSS_LIST then
		BOSS_LIST = {}
		local nCount = g_tTable.DungeonBoss:GetRowCount()
		for i = 2, nCount do
			local tLine = g_tTable.DungeonBoss:GetRow(i)
			local dwMapID = tLine.dwMapID
			local szNpcList = tLine.szNpcList
			for szNpcIndex in string.gmatch(szNpcList, '(%d+)') do
				local p = g_tTable.DungeonNpc:Search(tonumber(szNpcIndex))
				if p then
					if not BOSS_LIST[dwMapID] then
						BOSS_LIST[dwMapID] = {}
					end
					BOSS_LIST[dwMapID][p.dwNpcID] = p.szName
				end
			end
		end
		LIB.SaveLUAData(CACHE_PATH, BOSS_LIST)
		LIB.Sysmsg({_L('Boss list updated to v%s.', select(2, GetVersion()))})
	end

	for dwMapID, tInfo in pairs(LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/bosslist/$lang.jx3dat') or {}) do
		if not BOSS_LIST[dwMapID] then
			BOSS_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or CONSTANT.EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or CONSTANT.EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- ��ȡָ����ͼָ��ģ��ID��NPC�ǲ���BOSS
-- (boolean) LIB.IsBoss(dwMapID, dwTem)
function LIB.IsBoss(dwMapID, dwTemplateID)
	GenerateList()
	return (
		(
			BOSS_LIST[dwMapID] and BOSS_LIST[dwMapID][dwTemplateID]
			and not (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or false
end

LIB.RegisterTargetAddonMenu(PACKET_INFO.NAME_SPACE .. '#Game#Bosslist', function()
	local dwType, dwID = LIB.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = LIB.GetObject(dwType, dwID)
		local szName = LIB.GetObjectName(p)
		local dwMapID = GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if LIB.IsBoss(dwMapID, dwTemplateID) then
			return {
				szOption = _L['Remove from Boss list'],
				fnAction = function()
					GenerateList(true)
					if not BOSS_LIST_CUSTOM[dwMapID] then
						BOSS_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					if BOSS_LIST[dwMapID] and BOSS_LIST[dwMapID][dwTemplateID] then
						BOSS_LIST_CUSTOM[dwMapID].DEL[dwTemplateID] = szName
					end
					BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = nil
					SaveCustomList()
					FireUIEvent('MY_SET_BOSS', dwMapID, dwTemplateID, false)
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, LIB.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		else
			return {
				szOption = _L['Add to Boss list'],
				fnAction = function()
					GenerateList(true)
					if not BOSS_LIST_CUSTOM[dwMapID] then
						BOSS_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = szName
					SaveCustomList()
					FireUIEvent('MY_SET_BOSS', dwMapID, dwTemplateID, true)
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, LIB.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		end
	end
end)
end

-- ��ͼ��ҪNPC�б�
do local INPC_LIST, INPC_LIST_CUSTOM
local CACHE_PATH = {'temporary/inpclist.jx3dat', PATH_TYPE.GLOBAL}
local function LoadCustomList()
	if not INPC_LIST_CUSTOM then
		INPC_LIST_CUSTOM = LIB.LoadLUAData({'config/inpclist.jx3dat', PATH_TYPE.GLOBAL}) or {}
	end
end
local function SaveCustomList()
	LIB.SaveLUAData({'config/inpclist.jx3dat', PATH_TYPE.GLOBAL}, INPC_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if INPC_LIST and not bForceRefresh then
		return
	end
	INPC_LIST = LIB.LoadLUAData(CACHE_PATH)
	if bForceRefresh or not INPC_LIST then
		INPC_LIST = {}
		LIB.SaveLUAData(CACHE_PATH, INPC_LIST)
		LIB.Sysmsg({_L('Important Npc list updated to v%s.', select(2, GetVersion()))})
	end
	for dwMapID, tInfo in pairs(LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/inpclist/$lang.jx3dat') or {}) do
		if not INPC_LIST[dwMapID] then
			INPC_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or CONSTANT.EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or CONSTANT.EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- ��ȡָ����ͼָ��ģ��ID��NPC�ǲ�����ҪNPC
-- (boolean) LIB.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
function LIB.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
	GenerateList()
	return (
		(
			INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID]
			and not (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or (not bNoBoss and LIB.IsBoss(dwMapID, dwTemplateID) or false)
end

-- ��ȡָ��ģ��ID��NPC�ǲ��Ǳ����ε�NPC
-- (boolean) LIB.IsShieldedNpc(dwTemplateID)
function LIB.IsShieldedNpc(dwTemplateID)
	return Table_IsShieldedNpc and Table_IsShieldedNpc(dwTemplateID)
end

LIB.RegisterTargetAddonMenu(PACKET_INFO.NAME_SPACE .. '#Game#ImportantNpclist', function()
	local dwType, dwID = LIB.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = LIB.GetObject(dwType, dwID)
		local szName = LIB.GetObjectName(p)
		local dwMapID = GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if LIB.IsImportantNpc(dwMapID, dwTemplateID, true) then
			return {
				szOption = _L['Remove from important npc list'],
				fnAction = function()
					GenerateList(true)
					if not INPC_LIST_CUSTOM[dwMapID] then
						INPC_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					if INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID] then
						INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID] = szName
					end
					INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = nil
					SaveCustomList()
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, false)
				end,
			}
		else
			return {
				szOption = _L['Add to important npc list'],
				fnAction = function()
					GenerateList(true)
					if not INPC_LIST_CUSTOM[dwMapID] then
						INPC_LIST_CUSTOM[dwMapID] = {
							NAME = szMapName,
							ADD = {},
							DEL = {},
						}
					end
					INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID] = szName
					SaveCustomList()
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, true)
				end,
			}
		end
	end
end)
end

do
local SZ_FORCE_COLOR_FG = 'config/player_force_color.jx3dat'
local MY_FORCE_COLOR_FG_DEFAULT = setmetatable({
	[CONSTANT.FORCE_TYPE.JIANG_HU ] = { 255, 255, 255 }, -- ����
	[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { 255, 178, 95  }, -- ����
	[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { 196, 152, 255 }, -- ��
	[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { 255, 111, 83  }, -- ���
	[CONSTANT.FORCE_TYPE.CHUN_YANG] = { 22 , 216, 216 }, -- ����
	[CONSTANT.FORCE_TYPE.QI_XIU   ] = { 255, 129, 176 }, -- ����
	[CONSTANT.FORCE_TYPE.WU_DU    ] = { 55 , 147, 255 }, -- �嶾
	[CONSTANT.FORCE_TYPE.TANG_MEN ] = { 121, 183, 54  }, -- ����
	[CONSTANT.FORCE_TYPE.CANG_JIAN] = { 214, 249, 93  }, -- �ؽ�
	[CONSTANT.FORCE_TYPE.GAI_BANG ] = { 205, 133, 63  }, -- ؤ��
	[CONSTANT.FORCE_TYPE.MING_JIAO] = { 240, 70 , 96  }, -- ����
	[CONSTANT.FORCE_TYPE.CANG_YUN ] = { 180, 60 , 0   }, -- ����
	[CONSTANT.FORCE_TYPE.CHANG_GE ] = { 100, 250, 180 }, -- ����
	[CONSTANT.FORCE_TYPE.BA_DAO   ] = { 106 ,108, 189 }, -- �Ե�
	[CONSTANT.FORCE_TYPE.PENG_LAI ] = { 171 ,227, 250 }, -- ����
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_FORCE_COLOR_FG_GLOBAL = LIB.LoadLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.GLOBAL}) or {}
local MY_FORCE_COLOR_FG_CUSTOM = {}
local MY_FORCE_COLOR_FG = setmetatable({}, {
	__index = function(t, k)
		return MY_FORCE_COLOR_FG_CUSTOM[k] or MY_FORCE_COLOR_FG_GLOBAL[k] or MY_FORCE_COLOR_FG_DEFAULT[k]
	end,
})

local SZ_FORCE_COLOR_BG = 'config/player_force_color_bg.jx3dat'
local MY_FORCE_COLOR_BG_DEFAULT = setmetatable({
	[CONSTANT.FORCE_TYPE.JIANG_HU ] = { 255, 255, 255 }, -- ����
	[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { 210, 180, 0   }, -- ����
	[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { 127, 31 , 223 }, -- ��
	[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { 160, 0  , 0   }, -- ���
	[CONSTANT.FORCE_TYPE.CHUN_YANG] = { 56 , 175, 255 }, -- ���� 56,175,255,232
	[CONSTANT.FORCE_TYPE.QI_XIU   ] = { 255, 127, 255 }, -- ����
	[CONSTANT.FORCE_TYPE.WU_DU    ] = { 63 , 31 , 159 }, -- �嶾
	[CONSTANT.FORCE_TYPE.TANG_MEN ] = { 0  , 133, 144 }, -- ����
	[CONSTANT.FORCE_TYPE.CANG_JIAN] = { 255, 255, 0   }, -- �ؽ�
	[CONSTANT.FORCE_TYPE.GAI_BANG ] = { 205, 133, 63  }, -- ؤ��
	[CONSTANT.FORCE_TYPE.MING_JIAO] = { 253, 84 , 0   }, -- ����
	[CONSTANT.FORCE_TYPE.CANG_YUN ] = { 180, 60 , 0   }, -- ����
	[CONSTANT.FORCE_TYPE.CHANG_GE ] = { 100, 250, 180 }, -- ����
	[CONSTANT.FORCE_TYPE.BA_DAO   ] = { 71 , 73 , 166 }, -- �Ե�
	[CONSTANT.FORCE_TYPE.PENG_LAI ] = { 195, 171, 227 }, -- ����
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_FORCE_COLOR_BG_GLOBAL = LIB.LoadLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.GLOBAL}) or {}
local MY_FORCE_COLOR_BG_CUSTOM = {}
local MY_FORCE_COLOR_BG = setmetatable({}, {
	__index = function(t, k)
		return MY_FORCE_COLOR_BG_CUSTOM[k] or MY_FORCE_COLOR_BG_GLOBAL[k] or MY_FORCE_COLOR_BG_DEFAULT[k]
	end,
})

local function initForceCustom()
	MY_FORCE_COLOR_FG_CUSTOM = LIB.LoadLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.ROLE}) or {}
	MY_FORCE_COLOR_BG_CUSTOM = LIB.LoadLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.ROLE}) or {}
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end
LIB.RegisterInit(initForceCustom)

function LIB.GetForceColor(dwForce, szType)
	local COLOR = szType == 'background'
		and MY_FORCE_COLOR_BG
		or MY_FORCE_COLOR_FG
	if dwForce == 'all' then
		return COLOR
	end
	return unpack(COLOR[dwForce])
end

function LIB.SetForceColor(dwForce, szType, tCol)
	if dwForce == 'reset' then
		MY_FORCE_COLOR_BG_CUSTOM = {}
		MY_FORCE_COLOR_FG_CUSTOM = {}
		LIB.SaveLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_BG_CUSTOM)
		LIB.SaveLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_FG_CUSTOM)
	elseif szType == 'background' then
		MY_FORCE_COLOR_BG_CUSTOM[dwForce] = tCol
		LIB.SaveLUAData({SZ_FORCE_COLOR_BG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_BG_CUSTOM)
	else
		MY_FORCE_COLOR_FG_CUSTOM[dwForce] = tCol
		LIB.SaveLUAData({SZ_FORCE_COLOR_FG, PATH_TYPE.ROLE}, MY_FORCE_COLOR_FG_CUSTOM)
	end
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end

local SZ_CAMP_COLOR_FG = 'config/player_camp_color.jx3dat'
local MY_CAMP_COLOR_FG_DEFAULT = setmetatable({
	[CAMP.NEUTRAL] = { 255, 255, 255 }, -- ����
	[CAMP.GOOD   ] = {  60, 128, 220 }, -- ������
	[CAMP.EVIL   ] = { 160,  30,  30 }, -- ���˹�
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_CAMP_COLOR_FG_GLOBAL = LIB.LoadLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.GLOBAL}) or {}
local MY_CAMP_COLOR_FG_CUSTOM = {}
local MY_CAMP_COLOR_FG = setmetatable({}, {
	__index = function(t, k)
		return MY_CAMP_COLOR_FG_CUSTOM[k] or MY_CAMP_COLOR_FG_GLOBAL[k] or MY_CAMP_COLOR_FG_DEFAULT[k]
	end,
})

local SZ_CAMP_COLOR_BG = 'config/player_camp_color_bg.jx3dat'
local MY_CAMP_COLOR_BG_DEFAULT = setmetatable({
	[CAMP.NEUTRAL] = { 255, 255, 255 }, -- ����
	[CAMP.GOOD   ] = {  60, 128, 220 }, -- ������
	[CAMP.EVIL   ] = { 160,  30,  30 }, -- ���˹�
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_CAMP_COLOR_BG_GLOBAL = LIB.LoadLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.GLOBAL}) or {}
local MY_CAMP_COLOR_BG_CUSTOM = {}
local MY_CAMP_COLOR_BG = setmetatable({}, {
	__index = function(t, k)
		return MY_CAMP_COLOR_BG_CUSTOM[k] or MY_CAMP_COLOR_BG_GLOBAL[k] or MY_CAMP_COLOR_BG_DEFAULT[k]
	end,
})

local function initCampCustom()
	MY_CAMP_COLOR_FG_CUSTOM = LIB.LoadLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.ROLE}) or {}
	MY_CAMP_COLOR_BG_CUSTOM = LIB.LoadLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.ROLE}) or {}
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end
LIB.RegisterInit(initCampCustom)

function LIB.GetCampColor(nCamp, szType)
	local COLOR = szType == 'background'
		and MY_CAMP_COLOR_BG
		or MY_CAMP_COLOR_FG
	if nCamp == 'all' then
		return COLOR
	end
	return unpack(COLOR[nCamp])
end

function LIB.SetCampColor(nCamp, szType, tCol)
	if nCamp == 'reset' then
		MY_CAMP_COLOR_BG_CUSTOM = {}
		MY_CAMP_COLOR_FG_CUSTOM = {}
		LIB.SaveLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_BG_CUSTOM)
		LIB.SaveLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_FG_CUSTOM)
	elseif szType == 'background' then
		MY_CAMP_COLOR_BG_CUSTOM[nCamp] = tCol
		LIB.SaveLUAData({SZ_CAMP_COLOR_BG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_BG_CUSTOM)
	else
		MY_CAMP_COLOR_FG_CUSTOM[nCamp] = tCol
		LIB.SaveLUAData({SZ_CAMP_COLOR_FG, PATH_TYPE.ROLE}, MY_CAMP_COLOR_FG_CUSTOM)
	end
	FireUIEvent('MY_CAMP_COLOR_UPDATE')
end
end

do
local FORCE_LIST
function LIB.GetForceList()
	FORCE_LIST = {}
	for _, dwForceID in pairs_c(CONSTANT.FORCE_TYPE) do
		if dwForceID ~= CONSTANT.FORCE_TYPE.JIANG_HU then
			insert(FORCE_LIST, dwForceID)
		end
	end
	return FORCE_LIST
end
end

do
local ORDER = {
	-- MT
	10062, --[[ ���� ]]
	10243, --[[ ���� ]]
	10389, --[[ ���� ]]
	10002, --[[ ���� ]]
	-- ����
	10080, --[[ ���� ]]
	10176, --[[ ���� ]]
	10028, --[[ �뾭 ]]
	10448, --[[ ��֪ ]]
	-- �ڹ�
	10225, --[[ ���� ]]
	10081, --[[ ���� ]]
	10175, --[[ ���� ]]
	10242, --[[ ��Ӱ ]]
	10014, --[[ ��ϼ ]]
	10021, --[[ ���� ]]
	10003, --[[ �׾� ]]
	10447, --[[ Ī�� ]]
	-- �⹦
	10390, --[[ ��ɽ ]]
	10224, --[[ ���� ]]
	10144, --[[ ��ˮ ]]
	10145, --[[ ɽ�� ]]
	10015, --[[ ���� ]]
	10026, --[[ ��Ѫ ]]
	10268, --[[ Ц�� ]]
	10464, --[[ �Ե� ]]
	10533, --[[ ���� ]]
}
local KUNGFU_LIST
function LIB.GetKungfuList()
	if not KUNGFU_LIST then
		KUNGFU_LIST = {}
		for _, dwForceID in pairs_c(LIB.GetForceList()) do
			for _, dwKungfuID in ipairs(LIB.GetForceKungfuList(dwForceID)) do
				insert(KUNGFU_LIST, dwKungfuID)
			end
		end
		sort(KUNGFU_LIST, function(p1, p2)
			local i1, i2 = #ORDER + 1, #ORDER + 1
			for i, v in ipairs(ORDER) do
				if v == p1 then
					i1 = i
				end
				if v == p2 then
					i2 = i
				end
			end
			return i1 < i2
		end)
	end
	return KUNGFU_LIST
end
end

do
local KUNGFU_NAME_CACHE = {}
local KUNGFU_SHORT_NAME_CACHE = {}
function LIB.GetKungfuName(dwKungfuID, szType)
	if not KUNGFU_NAME_CACHE[dwKungfuID] then
		KUNGFU_NAME_CACHE[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1) or ''
		KUNGFU_SHORT_NAME_CACHE[dwKungfuID] = wstring.sub(KUNGFU_NAME_CACHE[dwKungfuID], 1, 2)
	end
	if szType == 'short' then
		return KUNGFU_SHORT_NAME_CACHE[dwKungfuID]
	else
		return KUNGFU_NAME_CACHE[dwKungfuID]
	end
end
end

do
local ITEM_CACHE = {}
function LIB.GetItemName(nUiId)
	if not ITEM_CACHE[nUiId] then
		local szName = LIB.GetItemNameByUIID(nUiId)
		local nIcon = Table_GetItemIconID(nUiId)
		if szName ~= '' and nIocn ~= -1 then
			ITEM_CACHE[nUiId] = { szName, nIcon }
		else
			ITEM_CACHE[nUiId] = { 'ITEM#' .. nUiId, 1435 }
		end
	end
	return unpack(ITEM_CACHE[nUiId])
end
end

-------------------------------------------------------------------------------------------------------
--               #     #       #             # #                         #             #             --
--   # # # #     #     #         #     # # #         # # # # # #         #             #             --
--   #     #   #       #               #                 #         #     #     # # # # # # # # #     --
--   #     #   #   # # # #             #                 #         #     #             #             --
--   #   #   # #       #     # # #     # # # # # #       # # # #   #     #       # # # # # # #       --
--   #   #     #       #         #     #     #         #       #   #     #             #             --
--   #     #   #   #   #         #     #     #       #   #     #   #     #   # # # # # # # # # # #   --
--   #     #   #     # #         #     #     #             #   #   #     #           #   #           --
--   #     #   #       #         #     #     #               #     #     #         #     #       #   --
--   # # #     #       #         #   #       #             #             #       # #       #   #     --
--   #         #       #       #   #                     #               #   # #   #   #     #       --
--   #         #     # #     #       # # # # # # #     #             # # #         # #         # #   --
-------------------------------------------------------------------------------------------------------
do
local NEARBY_NPC = {}      -- ������NPC
local NEARBY_PET = {}      -- ������PET
local NEARBY_PLAYER = {}   -- ��������Ʒ
local NEARBY_DOODAD = {}   -- ���������

-- ��ȡָ������
-- (KObject, info, bIsInfo) LIB.GetObject([number dwType, ]number dwID)
-- (KObject, info, bIsInfo) LIB.GetObject([number dwType, ]string szName)
-- dwType: [��ѡ]��������ö�� TARGET.*
-- dwID  : ����ID
-- return: ���� dwType ���ͺ� dwID ȡ�ò�������
--         ������ʱ����nil, nil
function LIB.GetObject(arg0, arg1, arg2)
	local dwType, dwID, szName
	if IsNumber(arg0) then
		if IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		elseif IsString(arg1) then
			dwType, szName = arg0, arg1
		elseif IsNil(arg1) then
			dwID = arg0
		end
	elseif IsString(arg0) then
		szName = arg0
	end
	if not dwID and not szName then
		return
	end

	if dwID and not dwType then
		if NEARBY_PLAYER[dwID] then
			dwType = TARGET.PLAYER
		elseif NEARBY_DOODAD[dwID] then
			dwType = TARGET.DOODAD
		elseif NEARBY_NPC[dwID] then
			dwType = TARGET.NPC
		end
	elseif not dwID and szName then
		local tSearch = {}
		if dwType == TARGET.PLAYER then
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
		elseif dwType == TARGET.NPC then
			tSearch[TARGET.NPC] = NEARBY_NPC
		elseif dwType == TARGET.DOODAD then
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		else
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
			tSearch[TARGET.NPC] = NEARBY_NPC
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		end
		for dwObjectType, NEARBY_OBJECT in pairs(tSearch) do
			for dwObjectID, KObject in pairs(NEARBY_OBJECT) do
				if LIB.GetObjectName(KObject) == szName then
					dwType, dwID = dwObjectType, dwObjectID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return
	end

	local p, info, b
	if dwType == TARGET.PLAYER then
		local me = GetClientPlayer()
		if me and dwID == me.dwID then
			p, info, b = me, me, false
		elseif me and me.IsPlayerInMyParty(dwID) then
			p, info, b = GetPlayer(dwID), GetClientTeam().GetMemberInfo(dwID), true
		else
			p, info, b = GetPlayer(dwID), GetPlayer(dwID), false
		end
	elseif dwType == TARGET.NPC then
		p, info, b = GetNpc(dwID), GetNpc(dwID), false
	elseif dwType == TARGET.DOODAD then
		p, info, b = GetDoodad(dwID), GetDoodad(dwID), false
	elseif dwType == TARGET.ITEM then
		p, info, b = GetItem(dwID), GetItem(dwID), GetItem(dwID)
	end
	return p, info, b
end

-- ��ȡָ�����������
-- LIB.GetObjectName(obj, bRetID)
-- (KObject) obj    Ҫ��ȡ���ֵĶ���
-- (string)  eRetID �Ƿ񷵻ض���ID��Ϣ
--    'auto'   ����Ϊ��ʱ���� -- Ĭ��ֵ
--    'always' ���Ƿ���
--    'never'  ���ǲ�����
function LIB.GetObjectName(obj, eRetID)
	if not obj then
		return nil
	end
	if not eRetID then
		eRetID = 'auto'
	end
	local szType, szName = LIB.GetObjectType(obj), obj.szName
	if szType == 'PLAYER' then -- PLAYER
		szType = 'P'
	elseif szType == 'NPC' then -- NPC
		szType = 'N'
		if IsEmpty(szName) then
			szName = Table_GetNpcTemplateName(obj.dwTemplateID)
			if szName then
				szName = szName:gsub('^%s*(.-)%s*$', '%1')
			end
		end
		if obj.dwEmployer and obj.dwEmployer ~= 0 then
			if LIB.Table_IsSimplePlayer(obj.dwTemplateID) then -- ����Ӱ��
				szName = LIB.GetObjectName(GetPlayer(obj.dwEmployer), eRetID)
			elseif not IsEmpty(szName) then
				local szEmpName = LIB.GetObjectName(
					(IsPlayer(obj.dwEmployer) and GetPlayer(obj.dwEmployer)) or GetNpc(obj.dwEmployer),
					'never'
				) or g_tStrings.STR_SOME_BODY
				szName =  szEmpName .. g_tStrings.STR_PET_SKILL_LOG .. szName
			end
		end
	elseif szType == 'DOODAD' then -- DOODAD
		szType = 'D'
		if IsEmpty(szName) then
			szName = LIB.Table_GetDoodadTemplateName(obj.dwTemplateID)
			if szName then
				szName = szName:gsub('^%s*(.-)%s*$', '%1')
			end
		end
	elseif szType == 'ITEM' then -- ITEM
		szType = 'I'
		szName = LIB.GetItemNameByItem(obj)
	else
		szType = '?'
	end
	if IsEmpty(szName) and eRetID ~= 'never' or eRetID == 'always' then
		local szDispID = szType
		if szType == 'N' then
			szDispID = szDispID .. LIB.ConvertNpcID(obj.dwID) .. '@' .. obj.dwTemplateID
		else
			szDispID = szDispID .. obj.dwID
		end
		szName = IsEmpty(szName) and szDispID or (szName .. '(' .. szDispID .. ')')
	end
	if IsEmpty(szName) then
		szName = nil
	end
	return szName
end

function LIB.GetObjectType(obj)
	if NEARBY_PLAYER[obj.dwID] == obj then
		return 'PLAYER'
	elseif NEARBY_NPC[obj.dwID] == obj then
		return 'NPC'
	elseif NEARBY_DOODAD[obj.dwID] == obj then
		return 'DOODAD'
	elseif GetItem(obj.dwID) == obj then
		return 'ITEM'
	end
	return 'UNKNOWN'
end

-- ��ȡ����NPC�б�
-- (table) LIB.GetNearNpc(void)
function LIB.GetNearNpc(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_NPC) do
		local npc = GetNpc(k)
		if not npc then
			NEARBY_NPC[k] = nil
		else
			insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

function LIB.GetNearNpcID(nLimit)
	local aNpcID = {}
	for k, _ in pairs(NEARBY_NPC) do
		insert(aNpcID, k)
		if nLimit and #aNpcID == nLimit then
			break
		end
	end
	return aNpcID
end

if IsDebugClient() then
function LIB.GetNearNpcTable()
	return NEARBY_NPC
end
end

-- ��ȡ����PET�б�
-- (table) LIB.GetNearPet(void)
function LIB.GetNearPet(nLimit)
	local aPet = {}
	for k, _ in pairs(NEARBY_PET) do
		local npc = GetPet(k)
		if not npc then
			NEARBY_PET[k] = nil
		else
			insert(aPet, npc)
			if nLimit and #aPet == nLimit then
				break
			end
		end
	end
	return aPet
end

function LIB.GetNearPetID(nLimit)
	local aPetID = {}
	for k, _ in pairs(NEARBY_PET) do
		insert(aPetID, k)
		if nLimit and #aPetID == nLimit then
			break
		end
	end
	return aPetID
end

if IsDebugClient() then
function LIB.GetNearPetTable()
	return NEARBY_PET
end
end

-- ��ȡ��������б�
-- (table) LIB.GetNearPlayer(void)
function LIB.GetNearPlayer(nLimit)
	local aPlayer = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		local p = GetPlayer(k)
		if not p then
			NEARBY_PLAYER[k] = nil
		else
			insert(aPlayer, p)
			if nLimit and #aPlayer == nLimit then
				break
			end
		end
	end
	return aPlayer
end

function LIB.GetNearPlayerID(nLimit)
	local aPlayerID = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		insert(aPlayerID, k)
		if nLimit and #aPlayerID == nLimit then
			break
		end
	end
	return aPlayerID
end

if IsDebugClient() then
function LIB.GetNearPlayerTable()
	return NEARBY_PLAYER
end
end

-- ��ȡ������Ʒ�б�
-- (table) LIB.GetNearPlayer(void)
function LIB.GetNearDoodad(nLimit)
	local aDoodad = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		local doodad = GetDoodad(dwID)
		if not doodad then
			NEARBY_DOODAD[dwID] = nil
		else
			insert(aDoodad, doodad)
			if nLimit and #aDoodad == nLimit then
				break
			end
		end
	end
	return aDoodad
end

function LIB.GetNearDoodadID(nLimit)
	local aDoodadID = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		insert(aDoodadID, dwID)
		if nLimit and #aDoodadID == nLimit then
			break
		end
	end
	return aDoodadID
end

if IsDebugClient() then
function LIB.GetNearDoodadTable()
	return NEARBY_DOODAD
end
end

LIB.RegisterEvent('NPC_ENTER_SCENE', function()
	local npc = GetNpc(arg0)
	if npc and npc.dwEmployer ~= 0 then
		NEARBY_PET[arg0] = npc
	end
	NEARBY_NPC[arg0] = npc
end)
LIB.RegisterEvent('NPC_LEAVE_SCENE', function()
	NEARBY_PET[arg0] = nil
	NEARBY_NPC[arg0] = nil
end)
LIB.RegisterEvent('PLAYER_ENTER_SCENE', function() NEARBY_PLAYER[arg0] = GetPlayer(arg0) end)
LIB.RegisterEvent('PLAYER_LEAVE_SCENE', function() NEARBY_PLAYER[arg0] = nil end)
LIB.RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = GetDoodad(arg0) end)
LIB.RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
end

-- ��ȡ���������Ϣ�����棩
do local m_ClientInfo
function LIB.GetClientInfo(arg0)
	if arg0 == true or not (m_ClientInfo and m_ClientInfo.dwID) then
		local me = GetClientPlayer()
		if me then -- ȷ����ȡ�����
			if not m_ClientInfo then
				m_ClientInfo = {}
			end
			if not IsRemotePlayer(me.dwID) then -- ȷ������ս��
				m_ClientInfo.dwID   = me.dwID
				m_ClientInfo.szName = me.szName
			end
			m_ClientInfo.nX                = me.nX
			m_ClientInfo.nY                = me.nY
			m_ClientInfo.nZ                = me.nZ
			m_ClientInfo.nFaceDirection    = me.nFaceDirection
			m_ClientInfo.szTitle           = me.szTitle
			m_ClientInfo.dwForceID         = me.dwForceID
			m_ClientInfo.nLevel            = me.nLevel
			m_ClientInfo.nExperience       = me.nExperience
			m_ClientInfo.nCurrentStamina   = me.nCurrentStamina
			m_ClientInfo.nCurrentThew      = me.nCurrentThew
			m_ClientInfo.nMaxStamina       = me.nMaxStamina
			m_ClientInfo.nMaxThew          = me.nMaxThew
			m_ClientInfo.nBattleFieldSide  = me.nBattleFieldSide
			m_ClientInfo.dwSchoolID        = me.dwSchoolID
			m_ClientInfo.nCurrentTrainValue= me.nCurrentTrainValue
			m_ClientInfo.nMaxTrainValue    = me.nMaxTrainValue
			m_ClientInfo.nUsedTrainValue   = me.nUsedTrainValue
			m_ClientInfo.nDirectionXY      = me.nDirectionXY
			m_ClientInfo.nCurrentLife      = me.nCurrentLife
			m_ClientInfo.nMaxLife          = me.nMaxLife
			m_ClientInfo.nMaxLifeBase      = me.nMaxLifeBase
			m_ClientInfo.nCurrentMana      = me.nCurrentMana
			m_ClientInfo.nMaxMana          = me.nMaxMana
			m_ClientInfo.nMaxManaBase      = me.nMaxManaBase
			m_ClientInfo.nCurrentEnergy    = me.nCurrentEnergy
			m_ClientInfo.nMaxEnergy        = me.nMaxEnergy
			m_ClientInfo.nEnergyReplenish  = me.nEnergyReplenish
			m_ClientInfo.bCanUseBigSword   = me.bCanUseBigSword
			m_ClientInfo.nAccumulateValue  = me.nAccumulateValue
			m_ClientInfo.nCamp             = me.nCamp
			m_ClientInfo.bCampFlag         = me.bCampFlag
			m_ClientInfo.bOnHorse          = me.bOnHorse
			m_ClientInfo.nMoveState        = me.nMoveState
			m_ClientInfo.dwTongID          = me.dwTongID
			m_ClientInfo.nGender           = me.nGender
			m_ClientInfo.nCurrentRage      = me.nCurrentRage
			m_ClientInfo.nMaxRage          = me.nMaxRage
			m_ClientInfo.nCurrentPrestige  = me.nCurrentPrestige
			m_ClientInfo.bFightState       = me.bFightState
			m_ClientInfo.nRunSpeed         = me.nRunSpeed
			m_ClientInfo.nRunSpeedBase     = me.nRunSpeedBase
			m_ClientInfo.dwTeamID          = me.dwTeamID
			m_ClientInfo.nRoleType         = me.nRoleType
			m_ClientInfo.nContribution     = me.nContribution
			m_ClientInfo.nCoin             = me.nCoin
			m_ClientInfo.nJustice          = me.nJustice
			m_ClientInfo.nExamPrint        = me.nExamPrint
			m_ClientInfo.nArenaAward       = me.nArenaAward
			m_ClientInfo.nActivityAward    = me.nActivityAward
			m_ClientInfo.bHideHat          = me.bHideHat
			m_ClientInfo.bRedName          = me.bRedName
			m_ClientInfo.dwKillCount       = me.dwKillCount
			m_ClientInfo.nRankPoint        = me.nRankPoint
			m_ClientInfo.nTitle            = me.nTitle
			m_ClientInfo.nTitlePoint       = me.nTitlePoint
			m_ClientInfo.dwPetID           = me.dwPetID
			m_ClientInfo.dwMapID           = me.GetMapID()
			m_ClientInfo.szMapName         = Table_GetMapName(me.GetMapID())
		end
	end
	if not m_ClientInfo then
		return {}
	end
	if IsString(arg0) then
		return m_ClientInfo[arg0]
	end
	return m_ClientInfo
end

local function onLoadingEnding()
	LIB.GetClientInfo(true)
end
LIB.RegisterEvent('LOADING_ENDING', onLoadingEnding)
end

-- ��ȡΨһ��ʶ��
do local m_szUUID
function LIB.GetClientUUID()
	if not m_szUUID then
		local me = GetClientPlayer()
		if me.GetGlobalID and me.GetGlobalID() ~= '0' then
			m_szUUID = me.GetGlobalID()
		else
			m_szUUID = (LIB.GetRealServer()):gsub('[/\\|:%*%?"<>]', '') .. '_' .. LIB.GetClientInfo().dwID
		end
	end
	return m_szUUID
end
end

do
local FRIEND_LIST_BY_ID, FRIEND_LIST_BY_NAME, FRIEND_LIST_BY_GROUP
local function GeneFriendListCache()
	if not FRIEND_LIST_BY_GROUP then
		local me = GetClientPlayer()
		if me then
			local infos = me.GetFellowshipGroupInfo()
			if infos then
				FRIEND_LIST_BY_ID = {}
				FRIEND_LIST_BY_NAME = {}
				FRIEND_LIST_BY_GROUP = {{ id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND or '' }} -- Ĭ�Ϸ���
				for _, group in ipairs(infos) do
					table.insert(FRIEND_LIST_BY_GROUP, group)
				end
				for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
					for _, p in ipairs(me.GetFellowshipInfo(group.id) or {}) do
						table.insert(group, p)
						FRIEND_LIST_BY_ID[p.id] = p
						FRIEND_LIST_BY_NAME[p.name] = p
					end
				end
				return true
			end
		end
		return false
	end
	return true
end
local function OnFriendListChange()
	FRIEND_LIST_BY_ID = nil
	FRIEND_LIST_BY_NAME = nil
	FRIEND_LIST_BY_GROUP = nil
end
LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , OnFriendListChange)
LIB.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , OnFriendListChange)
LIB.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , OnFriendListChange)
LIB.RegisterEvent('PLAYER_FOE_UPDATE'            , OnFriendListChange)
LIB.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , OnFriendListChange)
LIB.RegisterEvent('DELETE_FELLOWSHIP'            , OnFriendListChange)
LIB.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', OnFriendListChange)
-- ��ȡ�����б�
-- LIB.GetFriendList()         ��ȡ���к����б�
-- LIB.GetFriendList(1)        ��ȡ��һ����������б�
-- LIB.GetFriendList('������') ��ȡ��������Ϊ�����õĺ����б�
function LIB.GetFriendList(arg0)
	local t = {}
	local tGroup = {}
	if GeneFriendListCache() then
		if type(arg0) == 'number' then
			table.insert(tGroup, FRIEND_LIST_BY_GROUP[arg0])
		elseif type(arg0) == 'string' then
			for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
				if group.name == arg0 then
					table.insert(tGroup, Clone(group))
				end
			end
		else
			tGroup = FRIEND_LIST_BY_GROUP
		end
		local n = 0
		for _, group in ipairs(tGroup) do
			for _, p in ipairs(group) do
				t[p.id], n = Clone(p), n + 1
			end
		end
	end
	return t, n
end

-- ��ȡ����
function LIB.GetFriend(arg0)
	if arg0 and GeneFriendListCache() then
		if type(arg0) == 'number' then
			return Clone(FRIEND_LIST_BY_ID[arg0])
		elseif type(arg0) == 'string' then
			return Clone(FRIEND_LIST_BY_NAME[arg0])
		end
	end
end

function LIB.IsFriend(arg0)
	return LIB.GetFriend(arg0) and true or false
end
end

do
local FOE_LIST, FOE_LIST_BY_ID, FOE_LIST_BY_NAME
local function GeneFoeListCache()
	if not FOE_LIST then
		local me = GetClientPlayer()
		if me then
			FOE_LIST = {}
			FOE_LIST_BY_ID = {}
			FOE_LIST_BY_NAME = {}
			if me.GetFoeInfo then
				local infos = me.GetFoeInfo()
				if infos then
					for i, p in ipairs(infos) do
						FOE_LIST_BY_ID[p.id] = p
						FOE_LIST_BY_NAME[p.name] = p
						table.insert(FOE_LIST, p)
					end
					return true
				end
			end
		end
		return false
	end
	return true
end
local function OnFoeListChange()
	FOE_LIST = nil
	FOE_LIST_BY_ID = nil
	FOE_LIST_BY_NAME = nil
end
LIB.RegisterEvent('PLAYER_FOE_UPDATE', OnFoeListChange)
-- ��ȡ�����б�
function LIB.GetFoeList()
	if GeneFoeListCache() then
		return Clone(FOE_LIST)
	end
end
-- ��ȡ����
function LIB.GetFoe(arg0)
	if arg0 and GeneFoeListCache() then
		if type(arg0) == 'number' then
			return FOE_LIST_BY_ID[arg0]
		elseif type(arg0) == 'string' then
			return FOE_LIST_BY_NAME[arg0]
		end
	end
end
end

-- ��ȡ�����б�
function LIB.GetTongMemberList(bShowOffLine, szSorter, bAsc)
	if bShowOffLine == nil then bShowOffLine = false  end
	if szSorter     == nil then szSorter     = 'name' end
	if bAsc         == nil then bAsc         = true   end
	local aSorter = {
		['name'  ] = 'name'                    ,
		['level' ] = 'group'                   ,
		['school'] = 'development_contribution',
		['score' ] = 'score'                   ,
		['map'   ] = 'join_time'               ,
		['remark'] = 'last_offline_time'       ,
	}
	szSorter = aSorter[szSorter]
	-- GetMemberList(bShowOffLine, szSorter, bAsc, nGroupFilter, -1) -- ��������������֪��ʲô��
	return GetTongClient().GetMemberList(bShowOffLine, szSorter or 'name', bAsc, -1, -1)
end

function LIB.GetTongName(dwTongID)
	local szTongName
	if not dwTongID then
		dwTongID = (GetClientPlayer() or CONSTANT.EMPTY_TABLE).dwTongID
	end
	if dwTongID and dwTongID ~= 0 then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, 253)
	else
		szTongName = ''
	end
	return szTongName
end

-- ��ȡ����Ա
function LIB.GetTongMember(arg0)
	if not arg0 then
		return
	end

	return GetTongClient().GetMemberInfo(arg0)
end

function LIB.IsTongMember(arg0)
	return LIB.GetTongMember(arg0) and true or false
end

-- �ж��ǲ��Ƕ���
function LIB.IsParty(dwID)
	return GetClientPlayer().IsPlayerInMyParty(dwID)
end

-- �жϹ�ϵ
function LIB.GetRelation(dwSelfID, dwPeerID)
	if not dwPeerID then
		dwPeerID = dwSelfID
		dwSelfID = GetControlPlayerID()
	end
	if not IsPlayer(dwPeerID) then
		local npc = GetNpc(dwPeerID)
		if npc and npc.dwEmployer ~= 0 and GetPlayer(npc.dwEmployer) then
			dwPeerID = npc.dwEmployer
		end
	end
	if LIB.IsSelf(dwSelfID, dwPeerID) then
		return 'Self'
	end
	local dwSrcID, dwTarID = dwSelfID, dwPeerID
	if not IsPlayer(dwTarID) then
		dwSrcID, dwTarID = dwTarID, dwSrcID
	end
	if IsParty(dwSrcID, dwTarID) then
		return 'Party'
	elseif IsNeutrality(dwSrcID, dwTarID) then
		return 'Neutrality'
	elseif IsEnemy(dwSrcID, dwTarID) then -- �жԹ�ϵ
		if LIB.GetFoe(dwPeerID) then
			return 'Foe'
		else
			return 'Enemy'
		end
	elseif IsAlly(dwSrcID, dwTarID) then -- ��ͬ��Ӫ
		return 'Ally'
	else
		return 'Enemy' -- 'Other'
	end
end

-- �ж��ǲ��Ǻ���
function LIB.IsEnemy(dwSelfID, dwPeerID)
	return LIB.GetRelation(dwSelfID, dwPeerID) == 'Enemy'
end

-------------------------------------------------------------------------------------------------------
--       #         #   #                   #             #         #                   #             --
--       #         #     #         #       #             #         #   #               #             --
--       # # #     #                 #     #         #   #         #     #   # # # # # # # # # # #   --
--       #         # # # #             #   #           # #         #                 #   #           --
--       #     # # #           #           #             #   # # # # # # #         #       #         --
--   # # # # #     #   #         #         #             #         #             #     #     #       --
--   #       #     #   #           #       #             #       #   #       # #         #     # #   --
--   #       #     #   #                   # # # #     # #       #   #                 #             --
--   #       #       #       # # # # # # # #         #   #       #   #         #   #     #     #     --
--   # # # # #     # #   #                 #             #     #       #       #   #     #       #   --
--   #           #     # #                 #             #     #       #     #     #         #   #   --
--             #         #                 #             #   #           #           # # # # #       --
-------------------------------------------------------------------------------------------------------
do
local LAST_FIGHT_UUID  = nil
local FIGHT_UUID       = nil
local FIGHT_BEGIN_TICK = -1
local FIGHT_END_TICK   = -1
local FIGHTING         = false
local function ListenFightStateChange()
	-- �ж�ս���߽�
	if LIB.IsFighting() then
		-- ����ս���ж�
		if not FIGHTING then
			FIGHTING = true
			-- 5����ս�ж����� ��ֹ�������������ж�
			if not FIGHT_UUID
			or GetTickCount() - FIGHT_END_TICK > 5000 then
				-- �µ�һ��ս����ʼ
				FIGHT_BEGIN_TICK = GetTickCount()
				FIGHT_UUID = FIGHT_BEGIN_TICK
				FireUIEvent('MY_FIGHT_HINT', true)
			end
		end
	else
		-- �˳�ս���ж�
		if FIGHTING then
			FIGHT_END_TICK, FIGHTING = GetTickCount(), false
		elseif FIGHT_UUID and GetTickCount() - FIGHT_END_TICK > 5000 then
			LAST_FIGHT_UUID, FIGHT_UUID = FIGHT_UUID, nil
			FireUIEvent('MY_FIGHT_HINT', false)
		end
	end
end
LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#ListenFightStateChange', ListenFightStateChange)

-- ��ȡ��ǰս��ʱ��
function LIB.GetFightTime(szFormat)
	local nTick = 0
	if LIB.IsFighting() then -- ս��״̬
		nTick = GetTickCount() - FIGHT_BEGIN_TICK
	else  -- ��ս״̬
		nTick = FIGHT_END_TICK - FIGHT_BEGIN_TICK
	end

	if szFormat then
		local nSeconds = math.floor(nTick / 1000)
		local nMinutes = math.floor(nSeconds / 60)
		local nHours   = math.floor(nMinutes / 60)
		local nMinute  = nMinutes % 60
		local nSecond  = nSeconds % 60
		szFormat = szFormat:gsub('f', math.floor(nTick / 1000 * GLOBAL.GAME_FPS))
		szFormat = szFormat:gsub('H', nHours)
		szFormat = szFormat:gsub('M', nMinutes)
		szFormat = szFormat:gsub('S', nSeconds)
		szFormat = szFormat:gsub('hh', string.format('%02d', nHours ))
		szFormat = szFormat:gsub('mm', string.format('%02d', nMinute))
		szFormat = szFormat:gsub('ss', string.format('%02d', nSecond))
		szFormat = szFormat:gsub('h', nHours)
		szFormat = szFormat:gsub('m', nMinute)
		szFormat = szFormat:gsub('s', nSecond)

		if szFormat:sub(1, 1) ~= '0' and tonumber(szFormat) then
			szFormat = tonumber(szFormat)
		end
	else
		szFormat = nTick
	end
	return szFormat
end

-- ��ȡ��ǰս��Ψһ��ʾ��
function LIB.GetFightUUID()
	return FIGHT_UUID
end

-- ��ȡ�ϴ�ս��Ψһ��ʾ��
function LIB.GetLastFightUUID()
	return LAST_FIGHT_UUID
end
end

-- ��ȡ�����Ƿ����߼�ս��״̬
-- (bool) LIB.IsFighting()
do local ARENA_START = false
function LIB.IsFighting()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and LIB.IsInArena() and ARENA_START then
		bFightState = true
	elseif not bFightState and LIB.IsInDungeon() then
		-- �ڸ����Ҹ������ѽ�ս�Ҹ����ж�NPC��ս���жϴ���ս��״̬
		local bPlayerFighting, bNpcFighting
		for _, p in ipairs(LIB.GetNearPlayer()) do
			if me.IsPlayerInMyParty(p.dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for _, p in ipairs(LIB.GetNearNpc()) do
				if IsEnemy(p.dwID, me.dwID) and p.bFightState then
					bNpcFighting = true
					break
				end
			end
		end
		bFightState = bPlayerFighting and bNpcFighting
	end
	return bFightState
end
LIB.RegisterEvent('LOADING_ENDING.MY-PLAYER', function() ARENA_START = nil end)
LIB.RegisterEvent('ARENA_START.MY-PLAYER', function() ARENA_START = true end)
end

-------------------------------------------------------------------------------------------------------------------
--                                   #                                                       #                   --
--   # # # # # # # # # # #         #                               # # # # # # # # #         #     # # # # #     --
--             #             # # # # # # # # # # #       #         #               #         #                   --
--           #               #                   #     #   #       #               #     # # # #                 --
--     # # # # # # # # # #   #                   #     #   #       # # # # # # # # #         #   # # # # # # #   --
--     #     #     #     #   #     # # # # #     #     # # # #     #               #       # #         #         --
--     #     # # # #     #   #     #       #     #   #   #   #     #               #       # # #       #         --
--     #     #     #     #   #     #       #     #   #   #   #     # # # # # # # # #     #   #     #   #   #     --
--     #     # # # #     #   #     #       #     #   #     #       #               #         #     #   #     #   --
--     #     #     #     #   #     # # # # #     #     # #   # #   #               #         #   #     #     #   --
--     # # # # # # # # # #   #                   #                 # # # # # # # # #         #         #         --
--     #                 #   #               # # #                 #               #         #       # #         --
-------------------------------------------------------------------------------------------------------------------
-- ȡ��Ŀ�����ͺ�ID
-- (dwType, dwID) LIB.GetTarget()       -- ȡ���Լ���ǰ��Ŀ�����ͺ�ID
-- (dwType, dwID) LIB.GetTarget(object) -- ȡ��ָ����������ǰ��Ŀ�����ͺ�ID
function LIB.GetTarget(...)
	local object = ...
	if select('#', ...) == 0 then
		object = GetClientPlayer()
	end
	if object then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end

-- ȡ��Ŀ���Ŀ�����ͺ�ID
-- (dwType, dwID) LIB.GetTargetTarget()       -- ȡ���Լ���ǰ��Ŀ���Ŀ�����ͺ�ID
-- (dwType, dwID) LIB.GetTargetTarget(object) -- ȡ��ָ����������ǰ��Ŀ���Ŀ�����ͺ�ID
function LIB.GetTargetTarget(object)
    local nTarType, dwTarID = LIB.GetTarget(object)
    local KTar = LIB.GetObject(nTarType, dwTarID)
    if not KTar then
        return
    end
    return LIB.GetTarget(KTar)
end

-- ���� dwType ���ͺ� dwID ����Ŀ��
-- (void) LIB.SetTarget([number dwType, ]number dwID)
-- (void) LIB.SetTarget([number dwType, ]string szName)
-- dwType   -- *��ѡ* Ŀ������
-- dwID     -- Ŀ�� ID
function LIB.SetTarget(arg0, arg1)
	local dwType, dwID, szNames
	if IsUserdata(arg0) then
		dwType, dwID = TARGET[LIB.GetObjectType(arg0)], arg0.dwID
	elseif IsString(arg0) then
		szNames = arg0
	elseif IsNumber(arg0) then
		if IsNil(arg1) then
			dwID = arg0
		elseif IsString(arg1) then
			dwType, szNames = arg0, arg1
		elseif IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		end
	end
	if not dwID and not szNames then
		return
	end
	if dwID and not dwType then
		dwType = IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC
	end
	if szNames then
		local tTarget = {}
		for _, szName in pairs(LIB.SplitString(szNames:gsub('[%[%]]', ''), '|')) do
			tTarget[szName] = true
		end
		if not dwID and (not dwType or dwType == TARGET.NPC) then
			for _, p in ipairs(LIB.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and (not dwType or dwType == TARGET.PLAYER) then
			for _, p in ipairs(LIB.GetNearPlayer()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.PLAYER, p.dwID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return false
	end
	if dwType == TARGET.NPC then
		local npc = GetNpc(dwID)
		if npc and not npc.IsSelectable() and LIB.IsShieldedVersion() then
			--[[#DEBUG BEGIN]]
			LIB.Debug({'Set target to unselectable npc.'}, 'SetTarget', DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.DOODAD then
		if LIB.IsShieldedVersion() then
			--[[#DEBUG BEGIN]]
			LIB.Debug({'Set target to doodad.'}, 'SetTarget', DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	end
	SetTarget(dwType, dwID)
	return true
end

-- ����/ȡ�� ��ʱĿ��
-- LIB.SetTempTarget(dwType, dwID)
-- LIB.ResumeTarget()
do
local TEMP_TARGET = { TARGET.NO_TARGET, 0 }
function LIB.SetTempTarget(dwType, dwID)
	TargetPanel_SetOpenState(true)
	TEMP_TARGET = { GetClientPlayer().GetTarget() }
	LIB.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end

function LIB.ResumeTarget()
	TargetPanel_SetOpenState(true)
	-- ��֮ǰ��Ŀ�겻����ʱ���е���Ŀ��
	if TEMP_TARGET[1] ~= TARGET.NO_TARGET and not LIB.GetObject(unpack(TEMP_TARGET)) then
		TEMP_TARGET = { TARGET.NO_TARGET, 0 }
	end
	LIB.SetTarget(unpack(TEMP_TARGET))
	TEMP_TARGET = { TARGET.NO_TARGET, 0 }
	TargetPanel_SetOpenState(false)
end
end

-- ��ʱ����Ŀ��Ϊָ��Ŀ�겢ִ�к���
-- (void) LIB.WithTarget(dwType, dwID, callback)
do
local WITH_TARGET_LIST = {}
local LOCK_WITH_TARGET = false
local function WithTargetHandle()
	if LOCK_WITH_TARGET or
	#WITH_TARGET_LIST == 0 then
		return
	end

	LOCK_WITH_TARGET = true
	local r = table.remove(WITH_TARGET_LIST, 1)

	LIB.SetTempTarget(r.dwType, r.dwID)
	local res, err, trace = XpCall(r.callback)
	if not res then
		FireUIEvent('CALL_LUA_ERROR', err .. '\n' .. PACKET_INFO.NAME_SPACE .. '#WithTarget' .. '\n' .. trace .. '\n')
	end
	LIB.ResumeTarget()

	LOCK_WITH_TARGET = false
	WithTargetHandle()
end
function LIB.WithTarget(dwType, dwID, callback)
	-- ��Ϊ�ͻ��˶��߳� ���Լ�����Դ�� ��ֹ������ʱĿ���ͻ
	table.insert(WITH_TARGET_LIST, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	WithTargetHandle()
end
end

-- ��N2��N1�������  --  ����+2
-- (number) LIB.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) LIB.GetFaceAngel(oN1, oN2, bAbs)
-- @param nX    N1��X����
-- @param nY    N1��Y����
-- @param nFace N1������[0, 255]
-- @param nTX   N2��X����
-- @param nTY   N2��Y����
-- @param bAbs  ���ؽǶ��Ƿ�ֻ��������
-- @param oN1   N1����
-- @param oN2   N2����
-- @return nil    ��������
-- @return number �����(-180, 180]
function LIB.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
	if type(nY) == 'userdata' and type(nX) == 'userdata' then
		nX, nY, nFace, nTX, nTY, bAbs = nX.nX, nX.nY, nX.nFaceDirection, nY.nX, nY.nY, nFace
	end
	if type(nX) == 'number' and type(nY) == 'number' and type(nFace) == 'number'
	and type(nTX) == 'number' and type(nTY) == 'number' then
		local nFace = (nFace * 2 * math.pi / 255) - math.pi
		local nSight = (nX == nTX and ((nY > nTY and math.pi / 2) or - math.pi / 2)) or math.atan((nTY - nY) / (nTX - nX))
		local nAngel = ((nSight - nFace) % (math.pi * 2) - math.pi) / math.pi * 180
		if bAbs then
			nAngel = math.abs(nAngel)
		end
		return nAngel
	end
end

-- װ����ΪszName��װ��
-- (void) LIB.Equip(szName)
-- szName  װ������
function LIB.Equip(szName)
	local me = GetClientPlayer()
	for i=1,6 do
		if me.GetBoxSize(i) > 0 then
			for j = 0, me.GetBoxSize(i) - 1 do
				local item = me.GetItem(i, j)
				if item == nil then
					j=j + 1
				elseif LIB.GetItemNameByUIID(item.nUiId) == szName then -- LIB.GetItemNameByItem(item)
					local eRetCode, nEquipPos = me.GetEquipPos(i, j)
					if szName == _L['ji guan'] or szName == _L['nu jian'] then
						for k = 0,15 do
							if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, k) == nil then
								OnExchangeItem(i, j, INVENTORY_INDEX.BULLET_PACKAGE, k)
								return
							end
						end
						return
					else
						OnExchangeItem(i, j, INVENTORY_INDEX.EQUIP, nEquipPos)
						return
					end
				end
			end
		end
	end
end

do
local BUFF_LIST_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_LIST_PROXY = setmetatable({}, { __mode = 'v' })
local function reject() assert(false, 'Modify buff list from ' .. PACKET_INFO.NAME_SPACE .. '.GetBuffList is forbidden!') end
-- ��ȡ�����buff�б�
-- (table) LIB.GetBuffList(KObject)
function LIB.GetBuffList(...)
	local KObject
	if select('#', ...) == 0 then
		KObject = GetClientPlayer()
	else
		KObject = ...
	end
	local aBuffTable = {}
	if KObject then
		local aCache, aProxy = BUFF_LIST_CACHE[KObject], BUFF_LIST_PROXY[KObject]
		if not aCache or not aProxy then
			aCache, aProxy = {}, {}
			BUFF_LIST_CACHE[KObject] = aCache
			BUFF_LIST_PROXY[KObject] = aProxy
		end
		local nCount, raw = 0
		for i = 1, KObject.GetBuffCount() or 0 do
			local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = KObject.GetBuff(i - 1)
			if dwID then
				nCount = nCount + 1
				if not aCache[nCount] or not aProxy[nCount] then
					aCache[nCount] = {}
					aProxy[nCount] = setmetatable({}, { __index = aCache[nCount], __newindex = reject })
				end
				raw = aCache[nCount]
				raw.szKey        = dwSkillSrcID .. ':' .. dwID .. ',' .. nLevel
				raw.dwID         = dwID
				raw.nLevel       = nLevel
				raw.szName       = szName
				raw.nIcon        = nIcon
				raw.bCanCancel   = bCanCancel
				raw.nEndFrame    = nEndFrame
				raw.nIndex       = nIndex
				raw.nStackNum    = nStackNum
				raw.dwSkillSrcID = dwSkillSrcID
				raw.bValid       = bValid
				raw.nCount       = i
				raw.szName, raw.nIcon = LIB.GetBuffName(dwID, nLevel)
			end
		end
		for i = nCount + 1, #aCache do
			aCache[i] = nil
		end
		for i = nCount + 1, #aProxy do
			aProxy[i] = nil
		end
		return aProxy
	end
	return CONSTANT.EMPTY_TABLE
end
end

function LIB.CloneBuff(buff, dst)
	if not dst then
		dst = {}
	end
	dst.szKey = buff.szKey
	dst.dwID = buff.dwID
	dst.nLevel = buff.nLevel
	dst.szName = buff.szName
	dst.nIcon = buff.nIcon
	dst.bCanCancel = buff.bCanCancel
	dst.nEndFrame = buff.nEndFrame
	dst.nIndex = buff.nIndex
	dst.nStackNum = buff.nStackNum
	dst.dwSkillSrcID = buff.dwSkillSrcID
	dst.bValid = buff.bValid
	dst.nCount = buff.nCount
	dst.szName = buff.szName
	dst.nIcon = buff.nIcon
	return dst
end

do
local BUFF_CACHE = setmetatable({}, { __mode = 'v' })
local BUFF_PROXY = setmetatable({}, { __mode = 'v' })
local function reject() assert(false, 'Modify buff from ' .. PACKET_INFO.NAME_SPACE .. '.GetBuff is forbidden!') end
-- ��ȡ�����buff
-- tBuff: {[dwID1] = nLevel1, [dwID2] = nLevel2}
-- (table) LIB.GetBuff(dwID[, nLevel[, dwSkillSrcID]])
-- (table) LIB.GetBuff(KObject, dwID[, nLevel[, dwSkillSrcID]])
-- (table) LIB.GetBuff(tBuff[, dwSkillSrcID])
-- (table) LIB.GetBuff(KObject, tBuff[, dwSkillSrcID])
function LIB.GetBuff(KObject, dwID, nLevel, dwSkillSrcID)
	local tBuff = {}
	if type(KObject) ~= 'userdata' then
		KObject, dwID, nLevel, dwSkillSrcID = GetClientPlayer(), KObject, dwID, nLevel
	end
	if type(dwID) == 'table' then
		tBuff, dwSkillSrcID = dwID, nLevel
	elseif type(dwID) == 'number' then
		if type(nLevel) == 'number' then
			tBuff[dwID] = nLevel
		else
			tBuff[dwID] = 0
		end
	end
	if IsNumber(dwSkillSrcID) and dwSkillSrcID > 0 then
		if KObject.GetBuffByOwner then
			for k, v in pairs(tBuff) do
				local KBuff = KObject.GetBuffByOwner(k, v, dwSkillSrcID)
				if KBuff then
					return KBuff
				end
			end
		else
			if not KObject.GetBuff then
				--[[#DEBUG BEGIN]]
				LIB.Debug({'KObject neither has a function named GetBuffByOwner nor named GetBuff.'}, PACKET_INFO.NAME_SPACE .. '.GetBuff', DEBUG_LEVEL.ERROR)
				--[[#DEBUG END]]
				return
			end
			for _, buff in ipairs(LIB.GetBuffList(KObject)) do
				if (tBuff[buff.dwID] == buff.nLevel or tBuff[buff.dwID] == 0) and buff.dwSkillSrcID == dwSkillSrcID then
					local tCache, tProxy = BUFF_CACHE[KObject], BUFF_PROXY[KObject]
					if not tCache or not tProxy then
						tCache, tProxy = {}, {}
						BUFF_CACHE[KObject] = tCache
						BUFF_PROXY[KObject] = tProxy
					end
					if not tCache[buff.szKey] or not tProxy[buff.szKey] then
						tCache[buff.szKey] = {}
						tProxy[buff.szKey] = setmetatable({}, { __index = tCache[buff.szKey], __newindex = reject })
					end
					local raw = tCache[buff.szKey]
					raw.dwID         = buff.dwID
					raw.nLevel       = buff.nLevel
					raw.bCanCancel   = buff.bCanCancel
					raw.nEndFrame    = buff.nEndFrame
					raw.nIndex       = buff.nIndex
					raw.nStackNum    = buff.nStackNum
					raw.dwSkillSrcID = buff.dwSkillSrcID
					raw.bValid       = buff.bValid
					raw.nCount       = buff.nCount
					raw.GetEndTime = function() return buff.nEndFrame end
					return tProxy[buff.szKey]
				end
			end
			-- --[[#DEBUG BEGIN]]
			-- LIB.Debug({'KObject do not have a function named GetBuffByOwner.'}, PACKET_INFO.NAME_SPACE .. '.GetBuff', DEBUG_LEVEL.ERROR)
			-- --[[#DEBUG END]]
			-- return
		end
	else
		if not KObject.GetBuff then
			--[[#DEBUG BEGIN]]
			LIB.Debug({'KObject do not have a function named GetBuff.'}, PACKET_INFO.NAME_SPACE .. '.GetBuff', DEBUG_LEVEL.ERROR)
			--[[#DEBUG END]]
			return
		end
		for k, v in pairs(tBuff) do
			local KBuff = KObject.GetBuff(k, v)
			if KBuff then
				return KBuff
			end
		end
	end
end
end

-- ����Լ���buff
-- (table) LIB.CancelBuff([KObject = me, ]dwID[, nLevel = 0])
function LIB.CancelBuff(KObject, dwID, nLevel)
	if type(KObject) ~= 'userdata' then
		KObject, dwID, nLevel = nil, KObject, dwID
	end
	if not KObject then
		KObject = GetClientPlayer()
	end
	local tBuffs = LIB.GetBuffList(KObject)
	for _, buff in ipairs(tBuffs) do
		if (type(dwID) == 'string' and Table_GetBuffName(buff.dwID, buff.nLevel) == dwID or buff.dwID == dwID)
		and (not nLevel or nLevel == 0 or buff.nLevel == nLevel) then
			KObject.CancelBuff(buff.nIndex)
		end
	end
end

do
local BUFF_CACHE
function LIB.IsBossFocusBuff(dwID, nLevel, nStackNum)
	if not BUFF_CACHE then
		BUFF_CACHE = {}
		for i = 2, g_tTable.BossFocusBuff:GetRowCount() do
			local tLine = g_tTable.BossFocusBuff:GetRow(i)
			if tLine then
				if not BUFF_CACHE[tLine.nBuffID] then
					BUFF_CACHE[tLine.nBuffID] = {}
				end
				BUFF_CACHE[tLine.nBuffID][tLine.nBuffLevel] = tLine.nBuffStack
			end
		end
	end
	return BUFF_CACHE[dwID] and BUFF_CACHE[dwID][nLevel] and nStackNum >= BUFF_CACHE[dwID][nLevel]
end
end

-- ��ȡ�����Ƿ��޵�
-- (mixed) LIB.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function LIB.IsInvincible(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return nil
	elseif LIB.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end

-- ��ȡ����ǰ�Ƿ�ɶ���
-- (bool) LIB.CanOTAction([object KObject])
function LIB.CanOTAction(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return
	end
	return KObject.nMoveState == MOVE_STATE.ON_STAND or KObject.nMoveState == MOVE_STATE.ON_FLOAT
end

-- ͨ���������ƻ�ȡ���ܶ���
-- (table) LIB.GetSkillByName(szName)
do local PLAYER_SKILL_CACHE = {} -- ��Ҽ����б�[����] ����������ID
function LIB.GetSkillByName(szName)
	if table.getn(PLAYER_SKILL_CACHE)==0 then
		for i = 1, g_tTable.Skill:GetRowCount() do
			local tLine = g_tTable.Skill:GetRow(i)
			if tLine~=nil and tLine.dwIconID~=nil and tLine.fSortOrder~=nil and tLine.szName~=nil and tLine.dwIconID~=13 and ( (not PLAYER_SKILL_CACHE[tLine.szName]) or tLine.fSortOrder>PLAYER_SKILL_CACHE[tLine.szName].fSortOrder) then
				PLAYER_SKILL_CACHE[tLine.szName] = tLine
			end
		end
	end
	return PLAYER_SKILL_CACHE[szName]
end
end

-- �жϼ��������Ƿ���Ч
-- (bool) LIB.IsValidSkill(szName)
function LIB.IsValidSkill(szName)
	if LIB.GetSkillByName(szName)==nil then return false else return true end
end

-- �жϵ�ǰ�û��Ƿ����ĳ������
-- (bool) LIB.CanUseSkill(number dwSkillID[, dwLevel])
do
local box
function LIB.CanUseSkill(dwSkillID, dwLevel)
	-- �жϼ����Ƿ���Ч ����������ת��Ϊ����ID
	if type(dwSkillID) == 'string' then
		if not LIB.IsValidSkill(dwSkillID) then
			return false
		end
		dwSkillID = LIB.GetSkillByName(dwSkillID).dwSkillID
	end
	if not box or not box:IsValid() then
		box = UI.GetTempElement('Box.MYLib_Skill')
	end
	local me = GetClientPlayer()
	if me and box then
		if not dwLevel then
			if dwSkillID ~= 9007 then
				dwLevel = me.GetSkillLevel(dwSkillID)
			else
				dwLevel = 1
			end
		end
		if dwLevel > 0 then
			box:EnableObject(false)
			box:SetObjectCoolDown(1)
			box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
			UpdataSkillCDProgress(me, box)
			return box:IsObjectEnable() and not box:IsObjectCoolDown()
		end
	end
	return false
end
end

-- ���ݼ��� ID ���ȼ���ȡ���ܵ����Ƽ�ͼ�� ID�����û��洦����
-- (string, number) LIB.GetSkillName(number dwSkillID[, number dwLevel])
do local SKILL_CACHE = {} -- �����б����� ����ID�鼼������ͼ��
function LIB.GetSkillName(dwSkillID, dwLevel)
	if not SKILL_CACHE[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (StringFindW(tLine.szDesc, '_') == nil  or StringFindW(tLine.szDesc, '<') ~= nil)
		then
			SKILL_CACHE[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = 'SKILL#' .. dwSkillID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			SKILL_CACHE[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(SKILL_CACHE[dwSkillID])
end
end

do
local CACHE = {}
local REPLACE = {}
local function OnSkillReplace()
	for _, aList in pairs(CACHE) do
		for _, group in ipairs(aList) do
			for i, v in ipairs(group) do
				if v == arg0 then
					group[i] = arg1
				end
			end
		end
	end
	REPLACE[arg0] = arg1
	REPLACE[arg1] = nil
end
RegisterEvent("ON_SKILL_REPLACE", OnSkillReplace)
RegisterEvent("CHANGE_SKILL_ICON", OnSkillReplace)
function LIB.GetKungfuSkillIDs(dwKungfuID)
	if not CACHE[dwKungfuID] then
		local aSubKungfuID, aList = LIB.Table_GetMKungfuList(dwKungfuID), {}
		for _, dwSubKungfuID in ipairs(aSubKungfuID) do
			local aSub = { dwSubKungfuID = dwSubKungfuID }
			local aSkillID = LIB.Table_GetNewKungfuSkill(dwKungfuID, dwSubKungfuID)
			if not aSkillID then
				aSkillID = LIB.Table_GetKungfuSkillList(dwSubKungfuID)
			end
			for _, dwSkillID in ipairs(aSkillID) do
				if REPLACE[dwSkillID] then
					Output(REPLACE, dwSkillID)
				end
				insert(aSub, REPLACE[dwSkillID] or dwSkillID)
			end
			insert(aList, aSub)
		end
		CACHE[dwKungfuID] = aList
	end
	return CACHE[dwKungfuID]
end
end

do local CACHE = {}
function LIB.GetForceKungfuList(dwForceID)
	if not CACHE[dwForceID] then
		CACHE[dwForceID] = LIB.Table_GetSkillSchoolKungfu(dwForceID)
	end
	return CACHE[dwForceID]
end
end

do local CACHE = {}
function LIB.GetSchoolForceID(dwSchoolID)
	if not CACHE[dwSchoolID] then
		CACHE[dwSchoolID] = LIB.Table_SchoolToForce(dwSchoolID)
	end
	return CACHE[dwSchoolID]
end
end

function LIB.GetTargetSkillIDs(tar)
	local aSchoolID, aSkillID = tar.GetSchoolList(), {}
	for _, dwSchoolID in ipairs(aSchoolID) do
		local dwForceID = LIB.GetSchoolForceID(dwSchoolID)
		local aKungfuID = LIB.GetForceKungfuList(dwForceID)
		for _, dwKungfuID in ipairs(aKungfuID) do
			for _, aGroup in ipairs(LIB.GetKungfuSkillIDs(dwKungfuID)) do
				for _, dwSkillID in ipairs(aGroup) do
					insert(aSkillID, dwSkillID)
				end
			end
		end
	end
	return aSkillID
end

do
local LIST, LIST_ALL
function LIB.GetSkillMountList(bIncludePassive)
	if not LIST then
		LIST, LIST_ALL = {}, {}
		local me = GetClientPlayer()
		local aList = LIB.GetTargetSkillIDs(me)
		for _, dwID in ipairs(aList) do
			local nLevel = me.GetSkillLevel(dwID)
			if nLevel > 0 then
				local KSkill = GetSkill(dwID, nLevel)
				if not KSkill.bIsPassiveSkill then
					insert(LIST, dwID)
				end
				insert(LIST_ALL, dwID)
			end
		end
	end
	return bIncludePassive and LIST_ALL or LIST
end

local function onKungfuChange()
	LIST, LIST_ALL = nil
end
LIB.RegisterEvent('SKILL_MOUNT_KUNG_FU', onKungfuChange)
LIB.RegisterEvent('SKILL_UNMOUNT_KUNG_FU', onKungfuChange)
end

do
local SKILL_CACHE = setmetatable({}, { __mode = 'v' })
local SKILL_PROXY = setmetatable({}, { __mode = 'v' })
local function reject() assert(false, 'Modify skill info from LIB.GetSkill is forbidden!') end
function LIB.GetSkill(dwID, nLevel)
	local KSkill = GetSkill(dwID, nLevel)
	if not KSkill then
		return
	end
	local szKey = dwID .. '#' .. nLevel
	if not SKILL_CACHE[szKey] or not SKILL_PROXY[szKey] then
		SKILL_CACHE[szKey] = {
			szKey = szKey,
			szName = LIB.GetSkillName(dwID, nLevel),
			dwID = dwID,
			nLevel = nLevel,
			bLearned = nLevel > 0,
			nIcon = Table_GetSkillIconID(dwID, nLevel),
			dwExtID = LIB.Table_GetSkillExtCDID(dwID),
			bFormation = Table_IsSkillFormation(dwID, nLevel),
		}
		SKILL_PROXY[szKey] = setmetatable({}, { __index = SKILL_CACHE[szKey], __newindex = reject })
	end
	return KSkill, SKILL_PROXY[szKey]
end
end

do
local SKILL_SURFACE_NUM = {}
local function OnChangeSkillSurfaceNum()
	SKILL_SURFACE_NUM[arg0] = arg1
end
RegisterEvent("CHANGE_SKILL_SURFACE_NUM", OnChangeSkillSurfaceNum)
local function GetSkillCDProgress(dwID, nLevel, dwCDID, KObject)
	if dwCDID then
		return KObject.GetSkillCDProgress(dwID, nLevel, dwCDID)
	else
		return KObject.GetSkillCDProgress(dwID, nLevel)
	end
end
function LIB.GetSkillCDProgress(KObject, dwID, nLevel, bIgnorePublic)
	if not IsUserdata(KObject) then
		KObject, dwID, nLevel = GetClientPlayer(), KObject, dwID
	end
	if not nLevel then
		nLevel = KObject.GetSkillLevel(dwID)
	end
	if not nLevel then
		return
	end
	local KSkill, info = LIB.GetSkill(dwID, nLevel)
	if not KSkill or not info then
		return
	end
	-- # ����CD��ص����ж���
	-- -- ���Ӽ���CD
	-- if info.dwExtID then
	-- 	info.skillExt = LIB.GetTargetSkill(KObject, info.dwExtID)
	-- end
	-- ���ܺ�͸֧����CDˢ��
	local nCDMaxCount, dwCDID = KObject.GetCDMaxCount(dwID)
	local nODMaxCount, dwODID = KObject.GetCDMaxOverDraftCount(dwID)
	local _, bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum, bPublic
	if nCDMaxCount > 1 then -- ���ܼ���CDˢ��
		szType = 'CHARGE'
		nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, dwCDID, KObject))
		nInterval = KObject.GetCDInterval(dwCDID)
		nTotal = nInterval
		nLeft, nCount = KObject.GetCDLeft(dwCDID)
		bCool = nLeft > 0
		nCount = nCDMaxCount - nCount
		nMaxCount = nCDMaxCount
	elseif nODMaxCount > 1 then -- ͸֧����CDˢ��
		szType = 'OVERDRAFT'
		bCool, nLeft, nTotal, nCount, bPublic = GetSkillCDProgress(dwID, nLevel, dwODID, KObject)
		nInterval = KObject.GetCDInterval(dwODID)
		nMaxCount, nCount = KObject.GetOverDraftCoolDown(dwODID)
		if nCount == nMaxCount then -- ͸֧��������ʾCD
			bCool, nLeft, nTotal, _, bPublic = GetSkillCDProgress(dwID, nLevel, nil, KObject)
		else
			bCool, nLeft, nTotal = false, select(2, GetSkillCDProgress(dwID, nLevel, nil, KObject))
		end
	else -- ��ͨ����CDˢ��
		szType = 'NORMAL'
		if bIgnorePublic then
			nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, dwCDID, KObject))
		else
			nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, nil, KObject))
		end
		bCool = nLeft > 0
		nInterval = nTotal
		nCount, nMaxCount = bCool and 1 or 0, 1
	end
	if bPublic then
		szType = 'PUBLIC'
	end
	nSurfaceNum = SKILL_SURFACE_NUM[dwID]

	-- -- ָ��BUFF����ʱ������ʾ�ض���Ч������
	-- local tLine = Table_GetSkillEffectBySkill(dwID)
	-- if tLine then
	-- 	local bShow = not not KObject.GetBuff(tLine.dwBuffID, 0)
	-- 	if bShow then
	-- 		if tLine.bAnimate then
	-- 			hBox:SetExtentAnimate(tLine.szUITex, tLine.nFrame)
	-- 		else
	-- 			hBox:SetExtentImage(tLine.szUITex, tLine.nFrame)
	-- 		end
	-- 	else
	-- 		hBox:ClearExtentAnimate()
	-- 	end
	-- end
	return bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum
end
end

-- �ǳ���Ϸ
-- (void) LIB.Logout(bCompletely)
-- bCompletely Ϊtrue���ص�½ҳ Ϊfalse���ؽ�ɫҳ Ĭ��Ϊfalse
function LIB.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end

-- ���ݼ��� ID ��ȡ����֡�������������ܷ��� nil
-- (number) LIB.GetChannelSkillFrame(number dwSkillID)
do local SKILL_EX = LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/skill_ex.jx3dat') or {}
function LIB.GetChannelSkillFrame(dwSkillID)
	local t = SKILL_EX[dwSkillID]
	if t then
		return t.nChannelFrame
	end
end
end

function LIB.IsMarker()
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == UI_GetClientPlayerID()
end

function LIB.IsLeader()
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == UI_GetClientPlayerID()
end

function LIB.IsDistributer()
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == UI_GetClientPlayerID()
end

-- �ж��Լ��ڲ��ڶ�����
-- (bool) LIB.IsInParty()
function LIB.IsInParty()
	local me = GetClientPlayer()
	return me and me.IsInParty()
end

-- �жϵ�ǰ��ͼ�ǲ��Ǿ�����
-- (bool) LIB.IsInArena()
function LIB.IsInArena()
	local me = GetClientPlayer()
	return me and (
		me.GetScene().bIsArenaMap or -- JJC
		me.GetMapID() == 173 or      -- �����
		me.GetMapID() == 181         -- ��Ӱ��
	)
end

-- �жϵ�ǰ��ͼ�ǲ���ս��
-- (bool) LIB.IsInBattleField()
function LIB.IsInBattleField()
	local me = GetClientPlayer()
	return me and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD and not LIB.IsInArena()
end

-- �ж�һ����ͼ�ǲ��Ǹ���
-- (bool) LIB.IsDungeonMap(szMapName, bRaid)
-- (bool) LIB.IsDungeonMap(dwMapID, bRaid)
do local MAP_LIST
function LIB.IsDungeonMap(dwMapID, bRaid)
	if not MAP_LIST then
		MAP_LIST = {}
		for _, dwMapID in ipairs(GetMapList()) do
			local map          = { dwMapID = dwMapID }
			local szName       = Table_GetMapName(dwMapID)
			local tDungeonInfo = g_tTable.DungeonInfo:Search(dwMapID)
			if tDungeonInfo and tDungeonInfo.dwClassID == 3 then
				map.bDungeon = true
			end
			MAP_LIST[szName] = map
			MAP_LIST[dwMapID] = map
		end
	end
	local map = MAP_LIST[dwMapID]
	if map then
		dwMapID = map.dwMapID
	end
	if bRaid == true then -- �ϸ��ж�25�˱�
		return map and map.bDungeon
	elseif bRaid == false then -- �ϸ��ж�5�˱�
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON and not (map and map.bDungeon)
	else -- ֻ�жϵ�ͼ������
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
	end
end
end

-- �ж�һ����ͼ�ǲ��Ǹ���CD����
-- (bool) LIB.IsDungeonRoleProgressMap(dwMapID)
function LIB.IsDungeonRoleProgressMap(dwMapID)
	return (select(8, GetMapParams(dwMapID)))
end

-- �жϵ�ǰ��ͼ�ǲ��Ǹ���
-- (bool) LIB.IsInDungeon(bool bRaid)
function LIB.IsInDungeon(bRaid)
	local me = GetClientPlayer()
	return me and LIB.IsDungeonMap(me.GetMapID(), bRaid)
end

-- �жϵ�ͼ�ǲ���PUBG
-- (bool) LIB.IsPubgMap(dwMapID)
do
local PUBG_MAP = {}
function LIB.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = LIB.Table_IsTreasureBattleFieldMap(dwMapID) or false
	end
	return PUBG_MAP[dwMapID]
end
end

-- �жϵ�ǰ��ͼ�ǲ���PUBG
-- (bool) LIB.IsInPubg()
function LIB.IsInPubg()
	local me = GetClientPlayer()
	return me and LIB.IsPubgMap(me.GetMapID())
end

-- �жϵ�ͼ�ǲ��ǽ�ʬ��ͼ
-- (bool) LIB.IsZombieMap(dwMapID)
do
local ZOMBIE_MAP = {}
function LIB.IsZombieMap(dwMapID)
	if ZOMBIE_MAP[dwMapID] == nil then
		ZOMBIE_MAP[dwMapID] = Table_IsZombieBattleFieldMap
			and Table_IsZombieBattleFieldMap(dwMapID) or false
	end
	return ZOMBIE_MAP[dwMapID]
end
end

-- �жϵ�ǰ��ͼ�ǲ��ǽ�ʬ��ͼ
-- (bool) LIB.IsInZombieMap()
function LIB.IsInZombieMap()
	local me = GetClientPlayer()
	return me and LIB.IsZombieMap(me.GetMapID())
end

-- �жϵ�ͼ�ǲ��ǹ������ε�ͼ
-- (bool) LIB.IsShieldedMap(dwMapID)
function LIB.IsShieldedMap(dwMapID)
	if LIB.IsPubgMap(dwMapID) or LIB.IsZombieMap(dwMapID) then
		return true
	end
	if IsAddonBanMap and IsAddonBanMap(dwMapID) then
		return true
	end
	return false
end

-- �жϵ�ǰ��ͼ�ǲ���PUBG
-- (bool) LIB.IsInShieldedMap()
function LIB.IsInShieldedMap()
	local me = GetClientPlayer()
	return me and LIB.IsShieldedMap(me.GetMapID())
end

do local MARK_NAME = { _L['Cloud'], _L['Sword'], _L['Ax'], _L['Hook'], _L['Drum'], _L['Shear'], _L['Stick'], _L['Jade'], _L['Dart'], _L['Fan'] }
-- ��ȡ���������
-- (string) LIB.GetMarkName([number nIndex])
function LIB.GetMarkName(nIndex)
	if nIndex then
		return MARK_NAME[nIndex]
	else
		return Clone(MARK_NAME)
	end
end

function LIB.GetMarkIndex(dwID)
	if not LIB.IsInParty() then
		return
	end
	return GetClientTeam().GetMarkIndex(dwID)
end

-- ���浱ǰ�Ŷ���Ϣ
-- (table) LIB.GetTeamInfo([table tTeamInfo])
function LIB.GetTeamInfo(tTeamInfo)
	local tList, me, team = {}, GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	end
	tTeamInfo = tTeamInfo or {}
	tTeamInfo.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	tTeamInfo.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	tTeamInfo.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	tTeamInfo.nLootMode = team.nLootMode

	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			local info = team.GetMemberInfo(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
			end
		end
	end
	tTeamInfo.tList = tList
	return tTeamInfo
end

local function GetWrongIndex(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end
local function SyncMember(team, dwID, szName, state)
	if state.bForm then --������֮ǰ������
		team.SetTeamFormationLeader(dwID, state.nGroup) -- ���۸���
		LIB.Sysmsg({_L('restore formation of %d group: %s', state.nGroup + 1, szName)})
	end
	if state.nMark then -- ������֮ǰ�б��
		team.SetTeamMark(state.nMark, dwID) -- ��Ǹ���
		LIB.Sysmsg({_L('restore player marked as [%s]: %s', MARK_NAME[state.nMark], szName)})
	end
end
-- �ָ��Ŷ���Ϣ
-- (bool) LIB.SetTeamInfo(table tTeamInfo)
function LIB.SetTeamInfo(tTeamInfo)
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	elseif not tTeamInfo then
		return false
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return LIB.Sysmsg({_L['You are not team leader, permission denied']})
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = tTeamInfo.tList, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				LIB.Sysmsg({_L('unable get player of %d group: #%d', nGroup + 1, dwID)})
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					LIB.Sysmsg({_L('unknown status: %s', szName)})
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					LIB.Sysmsg({_L('need not adjust: %s', szName)})
				else
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == tTeamInfo.szLeader then
					dwLeader = dwID
				end
				if szName == tTeamInfo.szMark then
					dwMark = dwID
				end
				if szName == tTeamInfo.szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
					LIB.Sysmsg({_L('restore distributor: %s', szName)})
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = GetWrongIndex(tWrong[src.state.nGroup], false)
			table.remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- ֱ�Ӷ���ȥ
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				table.remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					table.insert(tWrong[nGroup], dst)
				else -- bingo
					LIB.Sysmsg({_L('change group of [%s] to %d', dst.szName, nGroup + 1)})
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			LIB.Sysmsg({_L('change group of [%s] to %d', src.szName, src.state.nGroup + 1)})
			SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= tTeamInfo.nLootMode then
		team.SetTeamLootMode(tTeamInfo.nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		LIB.Sysmsg({_L('restore team marker: %s', tTeamInfo.szMark)})
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		LIB.Sysmsg({_L('restore team leader: %s', tTeamInfo.szLeader)})
	end
	LIB.Sysmsg({_L['Team list restored']})
end
end

function LIB.UpdateItemBoxExtend(box, nQuality)
	local szImage = 'ui/Image/Common/Box.UITex'
	local nFrame
	if nQuality == 2 then
		nFrame = 13
	elseif nQuality == 3 then
		nFrame = 12
	elseif nQuality == 4 then
		nFrame = 14
	elseif nQuality == 5 then
		nFrame = 17
	end
	box:ClearExtentImage()
	box:ClearExtentAnimate()
	if nFrame and nQuality < 5 then
		box:SetExtentImage(szImage, nFrame)
	elseif nQuality == 5 then
		box:SetExtentAnimate(szImage, nFrame, -1)
	end
end

do
local l_tGlobalEffect
function LIB.GetGlobalEffect(nID)
	if l_tGlobalEffect == nil then
		local szPath = 'represent\\common\\global_effect.txt'
		local tTitle = {
			{ f = 'i', t = 'nID'        },
			{ f = 's', t = 'szDesc'     },
			{ f = 'i', t = 'nPlayType'  },
			{ f = 'f', t = 'fPlaySpeed' },
			{ f = 'f', t = 'fScale'     },
			{ f = 's', t = 'szFilePath' },
			{ f = 'i', t = 'nWidth'     },
			{ f = 'i', t = 'nHeight'    },
		}
		l_tGlobalEffect = KG_Table.Load(szPath, tTitle, FILE_OPEN_MODE.NORMAL) or false
	end
	if not l_tGlobalEffect then
		return
	end
	local tLine = l_tGlobalEffect:Search(nID)
	if tLine then
		if not tLine.nWidth then
			tLine.nWidth = 0
		end
		if not tLine.nHeight then
			tLine.nHeight = 0
		end
	end
	return tLine
end
end

function LIB.GetCharInfo()
	local me = GetClientPlayer()
	local kungfu = GetClientPlayer().GetKungfuMount()
	local data = {
		dwID = me.dwID,
		szName = me.szName,
		dwForceID = me.dwForceID,
		nEquipScore = me.GetTotalEquipScore() or 0,
		dwMountKungfuID = kungfu and kungfu.dwSkillID or 0,
	}
	if CharInfoMore_GetShowValue then
		local aCategory, aContent, tTip = CharInfoMore_GetShowValue()
		local nCategoryIndex, nSubLen, nSubIndex = 0, -1, 0
		for _, content in ipairs(aContent) do
			if nSubIndex > nSubLen then
				nCategoryIndex = nCategoryIndex + 1
				local category = aCategory[nCategoryIndex]
				if category then
					insert(data, {
						category = true,
						label = category[1],
					})
					nSubLen, nSubIndex = category[2], 1
				end
			end
			insert(data, {
				label = content[1],
				value = content[2],
				tip = tTip[content[3]],
			})
			nSubIndex = nSubIndex + 1
		end
	else
		local frame = Station.Lookup('Normal/CharInfo')
		if not frame or not frame:IsVisible() then
			if frame then
				Wnd.CloseWindow('CharInfo') -- ǿ��kill
			end
			Wnd.OpenWindow('CharInfo'):Hide()
		end
		local hCharInfo = Station.Lookup('Normal/CharInfo')
		local handle = hCharInfo:Lookup('WndScroll_Property', '')
		for i = 0, handle:GetVisibleItemCount() -1 do
			local h = handle:Lookup(i)
			table.insert(data, {
				szTip = h.szTip,
				label = h:Lookup(0):GetText(),
				value = h:Lookup(1):GetText(),
			})
		end
	end
	return data
end

function LIB.IsPhoneLock()
	local me = GetClientPlayer()
	return me and me.IsTradingMibaoSwitchOpen()
end

-- * ��ǰ�����Ƿ�����װ��Ҫ�󣺰������������ͣ����ɣ��Ա𣬵ȼ������ǣ�����������
function LIB.DoesEquipmentSuit(item, bIsItem, player)
	if not player then
		player = GetClientPlayer()
	end
	local requireAttrib = item.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		if bIsItem and not player.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
			return false
		elseif not bIsItem and not player.SatisfyRequire(v.nID, v.nValue) then
			return false
		end
	end
	return true
end

-- * ��ǰװ���Ƿ��ʺϵ�ǰ�ڹ�
do
local CACHE = {}
local m_MountTypeToWeapon = {
	[CONSTANT.KUNGFU_TYPE.TIAN_CE  ] = WEAPON_DETAIL.SPEAR        , -- ����ڹ�=������
	[CONSTANT.KUNGFU_TYPE.WAN_HUA  ] = WEAPON_DETAIL.PEN          , -- ���ڹ�=����
	[CONSTANT.KUNGFU_TYPE.CHUN_YANG] = WEAPON_DETAIL.SWORD        , -- �����ڹ�=�̱���
	[CONSTANT.KUNGFU_TYPE.QI_XIU   ] = WEAPON_DETAIL.DOUBLE_WEAPON, -- �����ڹ� = ˫����
	[CONSTANT.KUNGFU_TYPE.SHAO_LIN ] = WEAPON_DETAIL.WAND         , -- �����ڹ�=����
	[CONSTANT.KUNGFU_TYPE.CANG_JIAN] = WEAPON_DETAIL.SWORD        , -- �ؽ��ڹ�=�̱���,�ر��� WEAPON_DETAIL.BIG_SWORD
	[CONSTANT.KUNGFU_TYPE.GAI_BANG ] = WEAPON_DETAIL.STICK        , -- ؤ���ڹ�=�̰�
	[CONSTANT.KUNGFU_TYPE.MING_JIAO] = WEAPON_DETAIL.KNIFE        , -- �����ڹ�=�䵶
	[CONSTANT.KUNGFU_TYPE.WU_DU    ] = WEAPON_DETAIL.FLUTE        , -- �嶾�ڹ�=����
	[CONSTANT.KUNGFU_TYPE.TANG_MEN ] = WEAPON_DETAIL.BOW          , -- �����ڹ�=ǧ��ϻ
	[CONSTANT.KUNGFU_TYPE.CANG_YUN ] = WEAPON_DETAIL.BLADE_SHIELD , -- �����ڹ�=����
	[CONSTANT.KUNGFU_TYPE.CHANG_GE ] = WEAPON_DETAIL.HEPTA_CHORD  , -- �����ڹ�=��
	[CONSTANT.KUNGFU_TYPE.BA_DAO   ]	= WEAPON_DETAIL.BROAD_SWORD  , -- �Ե��ڹ�=��ϵ�
	[CONSTANT.KUNGFU_TYPE.PENG_LAI ]	= WEAPON_DETAIL.UMBRELLA     , -- �����ڹ�=ɡ
	--WEAPON_DETAIL.FIST = ȭ��
	--WEAPON_DETAIL.DART = ����
	--WEAPON_DETAIL.MACH_DART = ���ذ���
	--WEAPON_DETAIL.SLING_SHOT = Ͷ��
}
function LIB.IsItemFitKungfu(itemInfo, kungfu)
	if tostring(itemInfo):find('^KGItem:') then
		itemInfo = GetItemInfo(itemInfo.dwTabType, itemInfo.dwIndex)
	end
	if itemInfo.nSub == CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		local player = GetClientPlayer()
		local skill  = kungfu or player.GetKungfuMount()
		if not skill then
			return false
		end
		if itemInfo.nDetail == WEAPON_DETAIL.BIG_SWORD and skill.dwMountType == 6 then
			return true
		end

		if (m_MountTypeToWeapon[skill.dwMountType] ~= itemInfo.nDetail) then
			return false
		end

		if not itemInfo.nRecommendID or itemInfo.nRecommendID == 0 then
			return true
		end
	end

	if not itemInfo.nRecommendID then
		return
	end
	local aRecommendKungfuID = CACHE[itemInfo.nRecommendID]
	if not aRecommendKungfuID then
		local res = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
		aRecommendKungfuID = {}
		for i, v in ipairs(LIB.SplitString(res.kungfu_ids, "|")) do
			insert(aRecommendKungfuID, tonumber(v))
		end
		CACHE[itemInfo.nRecommendID] = aRecommendKungfuID
	end

	if not aRecommendKungfuID or not aRecommendKungfuID[1] then
		return
	end

	if aRecommendKungfuID[1] == 0 then
		return true
	end

	local player = GetClientPlayer()
	local skill  = kungfu or player.GetKungfuMount()
	if not skill then
		return false
	end
	for _, v in ipairs(aRecommendKungfuID) do
		if v == skill.dwSkillID then
			return true
		end
	end
end
end

-- * ��ȡ��Ʒ��Ӧ����װ����λ��
function LIB.GetItemEquipPos(item, nIndex)
	if not nIndex then
		nIndex = 1
	end
	local dwPackage, dwBox, nCount = INVENTORY_INDEX.EQUIP, 0, 1
	if item.nSub == CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if item.nDetail == WEAPON_DETAIL.BIG_SWORD then
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD
		else
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON
		end
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.ARROW then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.ARROW
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.CHEST then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.CHEST
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.HELM then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.HELM
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.AMULET then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.AMULET
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.RING then
		if nIndex == 1 then
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING
		else
			dwBox = CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING
		end
		nCount = 2
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.WAIST then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.WAIST
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.PENDANT then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.PENDANT
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.PANTS then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.PANTS
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.BOOTS then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.BOOTS
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.BANGLE then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.BANGLE
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.BACK_EXTEND then
		dwBox = CONSTANT.EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.FACE_EXTEND then
		dwBox = CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	elseif item.nSub == CONSTANT.EQUIPMENT_SUB.HORSE then
		dwPackage, dwBox = GetClientPlayer().GetEquippedHorsePos()
	end
	return dwPackage, dwBox, nIndex, nCount
end

-- * ��ǰװ���Ƿ��Ǳ������Ѿ�װ���ĸ���
function LIB.IsBetterEquipment(item, dwPackage, dwBox)
	if item.nGenre ~= ITEM_GENRE.EQUIPMENT
	or item.nSub == CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND
	or item.nSub == CONSTANT.EQUIPMENT_SUB.BACK_EXTEND
	or item.nSub == CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	or item.nSub == CONSTANT.EQUIPMENT_SUB.BULLET
	or item.nSub == CONSTANT.EQUIPMENT_SUB.MINI_AVATAR
	or item.nSub == CONSTANT.EQUIPMENT_SUB.PET then
		return false
	end

	if not dwPackage or not dwBox then
		local nIndex, nCount = 0, 1
		while nIndex < nCount do
			dwPackage, dwBox, nIndex, nCount = LIB.GetItemEquipPos(item, nIndex + 1)
			if LIB.IsBetterEquipment(item, dwPackage, dwBox) then
				return true
			end
		end
		return false
	end

	local me = GetClientPlayer()
	local equipedItem = GetPlayerItem(me, dwPackage, dwBox)
	if not equipedItem then
		return false
	end
	if me.nLevel < me.nMaxLevel then
		return item.nEquipScore > equipedItem.nEquipScore
	end
	return (item.nEquipScore > equipedItem.nEquipScore) or (item.nLevel > equipedItem.nLevel and item.nQuality >= equipedItem.nQuality)
end

if IsFunction(GetCampImageFrame) then
	LIB.GetCampImageFrame = GetCampImageFrame
else
	function LIB.GetCampImageFrame(eCamp, bFight) -- ui\Image\UICommon\CommonPanel2.UITex
		local nFrame = nil
		if eCamp == CAMP.GOOD then
			if bFight then
				nFrame = 117
			else
				nFrame = 7
			end
		elseif eCamp == CAMP.EVIL then
			if bFight then
				nFrame = 116
			else
				nFrame = 5
			end
		end
		return nFrame
	end
end

if IsFunction(GetCampImage) then
	LIB.GetCampImage = GetCampImage
else
	function LIB.GetCampImage(eCamp, bFight)
		local nFrame = LIB.GetCampImageFrame(eCamp, bFight)
		if nFrame then
			return 'ui\\Image\\UICommon\\CommonPanel2.UITex', nFrame
		end
	end
end

if IsFunction(GetUserRoleName) then
	LIB.GetUserRoleName = GetUserRoleName
else
	local _RoleName = ''
	function LIB.GetUserRoleName()
		local me = GetClientPlayer()
		if me and not IsRemotePlayer(me.dwID) then
			_RoleName = me.szName
		end
		return _RoleName
	end
end

if IsFunction(GetItemNameByItem) then
	LIB.GetItemNameByItem = GetItemNameByItem
else
	function LIB.GetItemNameByItem(item)
		if item.nGenre == ITEM_GENRE.BOOK then
			local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
			return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
		else
			return LIB.GetItemNameByUIID(item.nUiId)
		end
	end
end

if IsFunction(GetItemNameByItemInfo) then
	LIB.GetItemNameByItemInfo = GetItemNameByItemInfo
else
	function LIB.GetItemNameByItemInfo(itemInfo, nBookInfo)
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			if nBookInfo then
				local nBookID, nSegID = GlobelRecipeID2BookID(nBookInfo)
				return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
			else
				return LIB.GetItemNameByUIID(itemInfo.nUiId)
			end
		else
			return LIB.GetItemNameByUIID(itemInfo.nUiId)
		end
	end
end

if IsFunction(GetItemNameByUIID) then
	LIB.GetItemNameByUIID = GetItemNameByUIID
else
	function LIB.GetItemNameByUIID(nUiId)
		return Table_GetItemName(nUiId)
	end
end

if IsFunction(GetGuildBankBagPos) then
	LIB.GetGuildBankBagPos = GetGuildBankBagPos
else
	function LIB.GetGuildBankBagPos(nPage, nIndex)
		return CONSTANT.INVENTORY_GUILD_BANK, nPage * CONSTANT.INVENTORY_GUILD_PAGE_SIZE + nIndex
	end
end

if IsFunction(IsSelf) then
	LIB.IsSelf = IsSelf
else
	function LIB.IsSelf(dwSrcID, dwTarID)
		return dwSrcID ~= 0 and dwSrcID == dwTarID and IsPlayer(dwSrcID) and IsPlayer(dwTarID)
	end
end


if IsFunction(ForceIDToKungfuIDs) then
	LIB.ForceIDToKungfuIDs = ForceIDToKungfuIDs
else
	-- * ��ȡ���ɶ�Ӧ�ķ�ID�б�
	local m_tForceToKungfu
	function LIB.ForceIDToKungfuIDs(dwForceID)
		if not m_tForceToKungfu then
			m_tForceToKungfu = {
				[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { 10002, 10003, },
				[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { 10021, 10028, },
				[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { 10026, 10062, },
				[CONSTANT.FORCE_TYPE.CHUN_YANG] = { 10014, 10015, },
				[CONSTANT.FORCE_TYPE.QI_XIU   ] = { 10080, 10081, },
				[CONSTANT.FORCE_TYPE.WU_DU    ] = { 10175, 10176, },
				[CONSTANT.FORCE_TYPE.TANG_MEN ] = { 10224, 10225, },
				[CONSTANT.FORCE_TYPE.CANG_JIAN] = { 10144, 10145, },
				[CONSTANT.FORCE_TYPE.GAI_BANG ] = { 10268, },
				[CONSTANT.FORCE_TYPE.MING_JIAO] = { 10242, 10243, },
				[CONSTANT.FORCE_TYPE.CANG_YUN ] = { 10389, 10390, },
				[CONSTANT.FORCE_TYPE.CHANG_GE ] = { 10447, 10448, },
				[CONSTANT.FORCE_TYPE.BA_DAO   ] = { 10464, },
			}
		end
		return m_tForceToKungfu[dwForceID] or {}
	end
end