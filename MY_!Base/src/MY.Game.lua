--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 游戏环境库
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local Get, RandomChild = MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
if not MY then
	return OutputMessage('MSG_SYS', '[MYLIB#GAME] Fatal error! MY namespace does not exist!\n')
end
local _L = MY.LoadLangPack()

-- #######################################################################################################
--       #       #               #         #           #           #
--       #       #               #     # # # # # #     # #       # # # #
--       #   # # # # # #         #         #         #     # #     #   #
--   #   # #     #     #     # # # #   # # # # #             # # # # # # #
--   #   #       #     #         #         #   #     # # #   #     #   #
--   #   #       #     #         #     # # # # # #     #   #     # # # #
--   #   # # # # # # # # #       # #       #   #       #   # #     #
--       #       #           # # #     # # # # #     # # #   # # # # # #
--       #     #   #             #         #           #     #     #
--       #     #   #             #     #   # # # #     #   # # # # # # # #
--       #   #       #           #     #   #           # #   #     #
--       # #           # #     # #   #   # # # # #     #   #   # # # # # #
-- #######################################################################################################
do local HOTKEY_CACHE = {}
-- 增加系统快捷键
-- (void) MY.RegisterHotKey(string szName, string szTitle, func fnAction)   -- 增加系统快捷键
function MY.RegisterHotKey(szName, szTitle, fnAction)
	insert(HOTKEY_CACHE, { szName = szName, szTitle = szTitle, fnAction = fnAction })
end

-- 获取快捷键名称
-- (string) MY.GetHotKeyDisplay(string szName, boolean bBracket, boolean bShort)      -- 取得快捷键名称
function MY.GetHotKeyDisplay(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szDisplay = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szDisplay ~= '' and bBracket then
		szDisplay = '(' .. szDisplay .. ')'
	end
	return szDisplay
end

-- 获取快捷键
-- (table) MY.GetHotKey(string szName, true , true )       -- 取得快捷键
-- (number nKey, boolean bShift, boolean bCtrl, boolean bAlt) MY.GetHotKey(string szName, true , fasle)        -- 取得快捷键
function MY.GetHotKey(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	if nKey==0 then return nil end
	if bBracket then
		return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
	else
		return nKey, bShift, bCtrl, bAlt
	end
end

-- 设置快捷键/打开快捷键设置面板    -- HM里面抠出来的
-- (void) MY.SetHotKey()                               -- 打开快捷键设置面板
-- (void) MY.SetHotKey(string szGroup)     -- 打开快捷键设置面板并定位到 szGroup 分组（不可用）
-- (void) MY.SetHotKey(string szCommand, number nKey )     -- 设置快捷键
-- (void) MY.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- 设置快捷键
function MY.SetHotKey(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
	if nIndex then
		if not nKey then
			nIndex, nKey = 1, nIndex
		end
		Hotkey.Set(szCommand, nIndex, nKey, bShift == true, bCtrl == true, bAlt == true)
	else
		local szGroup = szCommand or MY.GetAddonInfo().szName

		local frame = Station.Lookup('Topmost/HotkeyPanel')
		if not frame then
			frame = Wnd.OpenWindow('HotkeyPanel')
		elseif not frame:IsVisible() then
			frame:Show()
		end
		if not szGroup then return end
		-- load aKey
		local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
		for k, v in pairs(bindings) do
			if v.szHeader ~= '' then
				if aKey then
					break
				elseif v.szHeader == szGroup then
					aKey = {}
				else
					nI = nI + 1
				end
			end
			if aKey then
				if not v.Hotkey1 then
					v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				if not v.Hotkey2 then
					v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				table.insert(aKey, v)
			end
		end
		if not aKey then return end
		local hP = frame:Lookup('', 'Handle_List')
		local hI = hP:Lookup(nI)
		if hI.bSel then return end
		-- update list effect
		for i = 0, hP:GetItemCount() - 1 do
			local hB = hP:Lookup(i)
			if hB.bSel then
				hB.bSel = false
				if hB.IsOver then
					hB:Lookup('Image_Sel'):SetAlpha(128)
					hB:Lookup('Image_Sel'):Show()
				else
					hB:Lookup('Image_Sel'):Hide()
				end
			end
		end
		hI.bSel = true
		hI:Lookup('Image_Sel'):SetAlpha(255)
		hI:Lookup('Image_Sel'):Show()
		-- update content keys [hI.nGroupIndex]
		local hK = frame:Lookup('', 'Handle_Hotkey')
		local szIniFile = 'UI/Config/default/HotkeyPanel.ini'
		Hotkey.SetCapture(false)
		hK:Clear()
		hK.nGroupIndex = hI.nGroupIndex
		hK:AppendItemFromIni(szIniFile, 'Text_GroupName')
		hK:Lookup(0):SetText(szGroup)
		hK:Lookup(0).bGroup = true
		for k, v in ipairs(aKey) do
			hK:AppendItemFromIni(szIniFile, 'Handle_Binding')
			local hI = hK:Lookup(k)
			hI.bBinding = true
			hI.nIndex = k
			hI.szTip = v.szTip
			hI:Lookup('Text_Name'):SetText(v.szDesc)
			for i = 1, 2, 1 do
				local hK = hI:Lookup('Handle_Key'..i)
				hK.bKey = true
				hK.nIndex = i
				local hotkey = v['Hotkey'..i]
				hotkey.bUnchangeable = v.bUnchangeable
				hK.bUnchangeable = v.bUnchangeable
				local text = hK:Lookup('Text_Key'..i)
				text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
				-- update btn
				if hK.bUnchangeable then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(56)
				elseif hK.bDown then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bRDown then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bSel then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bOver then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(54)
				elseif hotkey.bChange then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(56)
				elseif hotkey.bConflict then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(54)
				else
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(53)
				end
			end
		end
		-- update content scroll
		hK:FormatAllItemPos()
		local wAll, hAll = hK:GetAllItemSize()
		local w, h = hK:GetSize()
		local scroll = frame:Lookup('Scroll_Key')
		local nCountStep = math.ceil((hAll - h) / 10)
		scroll:SetStepCount(nCountStep)
		scroll:SetScrollPos(0)
		if nCountStep > 0 then
			scroll:Show()
			scroll:GetParent():Lookup('Btn_Up'):Show()
			scroll:GetParent():Lookup('Btn_Down'):Show()
		else
			scroll:Hide()
			scroll:GetParent():Lookup('Btn_Up'):Hide()
			scroll:GetParent():Lookup('Btn_Down'):Hide()
		end
		-- update list scroll
		local scroll = frame:Lookup('Scroll_List')
		if scroll:GetStepCount() > 0 then
			local _, nH = hI:GetSize()
			local nStep = math.ceil((nI * nH) / 10)
			if nStep > scroll:GetStepCount() then
				nStep = scroll:GetStepCount()
			end
			scroll:SetScrollPos(nStep)
		end
	end
end

MY.RegisterInit('MYLIB#BIND_HOTKEY', function()
	-- hotkey
	Hotkey.AddBinding('MY_Total', _L['Open/Close main panel'], MY.GetAddonInfo().szName, MY.TogglePanel, nil)
	for _, v in ipairs(HOTKEY_CACHE) do
		Hotkey.AddBinding(v.szName, v.szTitle, '', v.fnAction, nil)
	end
	for i = 1, 5 do
		Hotkey.AddBinding('MY_HotKey_Null_'..i, _L['none-function hotkey'], '', function() end, nil)
	end
end)
MY.RegisterHotKey('MY_STOP_CASTING', _L['Stop cast skill'], function() GetClientPlayer().StopCurrentAction() end)
end

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
-- 获取当前服务器名称
function MY.GetServer(nIndex)
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

-- 获取当前服务器显示名称
function MY.GetDisplayServer(nIndex)
	local display_region, display_server = GetUserServer()
	if nIndex == 1 then
		return display_region
	elseif nIndex == 2 then
		return display_server
	else
		return display_region .. '_' .. display_server, {display_region, display_server}
	end
end

-- 获取数据互通主服务器名称
function MY.GetRealServer(nIndex)
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
function MY.ConvertNpcID(dwID, eType)
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

-- OObject: KObject | {nType, dwID} | {dwID} | {nType, szName} | {szName}
-- MY.GetDistance(OObject[, szType])
-- MY.GetDistance(nX, nY)
-- MY.GetDistance(nX, nY, nZ[, szType])
-- MY.GetDistance(OObject1, OObject2[, szType])
-- MY.GetDistance(OObject1, nX2, nY2)
-- MY.GetDistance(OObject1, nX2, nY2, nZ2[, szType])
-- MY.GetDistance(nX1, nY1, nX2, nY2)
-- MY.GetDistance(nX1, nY1, nZ1, nX2, nY2, nZ2[, szType])
-- szType: 'euclidean': 欧氏距离 (default)
--         'plane'    : 平面距离
--         'gwwean'   : 郭氏距离
function MY.GetDistance(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	local szType = 'euclidean'
	local nX1, nY1, nZ1 = 0, 0, 0
	local nX2, nY2, nZ2 = 0, 0, 0
	if IsTable(arg0) then
		arg0 = MY.GetObject(unpack(arg0))
		if not arg0 then
			return
		end
	end
	if IsTable(arg1) then
		arg1 = MY.GetObject(unpack(arg1))
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
	if szType == 'plane' then
		return floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return max(floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, floor(abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

do local BUFF_CACHE = {}
function MY.GetBuffName(dwBuffID, dwLevel)
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

function MY.GetEndTime(nEndFrame)
	return (nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
end

-- 获取指定名字的右键菜单
function MY.GetTargetContextMenu(dwType, szName, dwID)
	local t = {}
	if dwType == TARGET.PLAYER then
		-- 复制
		table.insert(t, {
			szOption = _L['copy'],
			fnAction = function()
				MY.Talk(GetClientPlayer().szName, '[' .. szName .. ']')
			end,
		})
		-- 密聊
		-- table.insert(t, {
		--     szOption = _L['whisper'],
		--     fnAction = function()
		--         MY.SwitchChat(szName)
		--     end,
		-- })
		-- 密聊 好友 邀请入帮 跟随
		pcall(InsertPlayerCommonMenu, t, dwID, szName)
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
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then -- 查看奇穴
						table.insert(t, vv)
						break
					end
				end
				break
			end
		end
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.STR_ARENA_INVITE_TARGET -- 邀请入名剑队
			or v.szOption == g_tStrings.LOOKUP_INFO             -- 查看更多信息
			or v.szOption == g_tStrings.CHANNEL_MENTOR          -- 师徒
			or v.szOption == g_tStrings.STR_ADD_SHANG           -- 发布悬赏
			or v.szOption == g_tStrings.STR_MARK_TARGET         -- 标记目标
			or v.szOption == g_tStrings.STR_MAKE_TRADDING       -- 交易
			or v.szOption == g_tStrings.REPORT_RABOT            -- 举报外挂
			then
				table.insert(t, v)
			end
		end
	end

	return t
end

-- 获取副本选择菜单
-- (table) MY.GetDungeonMenu(fnAction, bOnlyRaid)
do
local function RecruitItemToDungeonMenu(p, fnAction)
	if p.bParent then
		local t = { szOption = p.TypeName or p.SubTypeName }
		for _, pp in ipairs(p) do
			insert(t, RecruitItemToDungeonMenu(pp, fnAction))
		end
		if #t > 0 then
			return t
		end
	else
		-- 不限阵营 有地图ID 7点开始 持续24小时 基本就是副本了
		if p.nCamp == 7
		and p.nStartTime == 7 and p.nLastTime == 24
		and p.dwMapID and MY.IsDungeonMap(p.dwMapID) then
			return {
				szOption = p.szName,
				bChecked = false,
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
function MY.GetDungeonMenu(fnAction, bOnlyRaid)
	local t = {}
	for _, p in ipairs(Table_GetTeamRecruit() or {}) do
		insert(t, RecruitItemToDungeonMenu(p, fnAction))
	end
	return t
end
end

-- 获取副本CD列表（异步）
-- (table) MY.GetMapSaveCopy(fnAction)
do
local QUEUE = {}
local SAVED_COPY_CACHE, REQUEST_FRAME
function MY.GetMapSaveCopy(fnAction)
	if SAVED_COPY_CACHE then
		if IsFunction(fnAction) then
			fnAction(SAVED_COPY_CACHE)
		end
	else
		if IsFunction(fnAction) then
			insert(QUEUE, fnAction)
		end
		if REQUEST_FRAME ~= GetLogicFrameCount() then
			ApplyMapSaveCopy()
			REQUEST_FRAME = GetLogicFrameCount()
		end
	end
	return SAVED_COPY_CACHE
end

local function onApplyPlayerSavedCopyRespond()
	SAVED_COPY_CACHE = arg0
	for _, fnAction in ipairs(QUEUE) do
		fnAction(SAVED_COPY_CACHE)
	end
	QUEUE = {}
end
MY.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', onApplyPlayerSavedCopyRespond)

local function onCopyUpdated()
	SAVED_COPY_CACHE = nil
end
MY.RegisterEvent('ON_RESET_MAP_RESPOND', onCopyUpdated)
MY.RegisterEvent('ON_MAP_COPY_PROGRESS_UPDATE', onCopyUpdated)
end

-- 地图BOSS列表
do local BOSS_LIST, BOSS_LIST_CUSTOM
local CACHE_PATH = {'temporary/bosslist.jx3dat', MY_DATA_PATH.GLOBAL}
local CUSTOM_PATH = {'config/bosslist.jx3dat', MY_DATA_PATH.GLOBAL}
local function LoadCustomList()
	if not BOSS_LIST_CUSTOM then
		BOSS_LIST_CUSTOM = MY.LoadLUAData(CUSTOM_PATH) or {}
	end
end
local function SaveCustomList()
	MY.SaveLUAData(CUSTOM_PATH, BOSS_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if BOSS_LIST and not bForceRefresh then
		return
	end
	MY.CreateDataRoot(MY_DATA_PATH.GLOBAL)
	BOSS_LIST = MY.LoadLUAData(CACHE_PATH)
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
		MY.SaveLUAData(CACHE_PATH, BOSS_LIST)
		MY.Sysmsg({_L('Boss list updated to v%s.', VERSION)})
	end

	for dwMapID, tInfo in pairs(MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/bosslist/$lang.jx3dat') or {}) do
		if not BOSS_LIST[dwMapID] then
			BOSS_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or EMPTY_TABLE) do
			BOSS_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- 获取指定地图指定模板ID的NPC是不是BOSS
-- (boolean) MY.IsBoss(dwMapID, dwTem)
function MY.IsBoss(dwMapID, dwTemplateID)
	GenerateList()
	return (
		(
			BOSS_LIST[dwMapID] and BOSS_LIST[dwMapID][dwTemplateID]
			and not (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (BOSS_LIST_CUSTOM[dwMapID] and BOSS_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or false
end

MY.RegisterTargetAddonMenu('MYLIB#Game#Bosslist', function()
	local dwType, dwID = MY.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = MY.GetObject(dwType, dwID)
		local szName = MY.GetObjectName(p)
		local dwMapID = GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if MY.IsBoss(dwMapID, dwTemplateID) then
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
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, MY.IsImportantNpc(dwMapID, dwTemplateID))
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
					FireUIEvent('MY_SET_IMPORTANT_NPC', dwMapID, dwTemplateID, MY.IsImportantNpc(dwMapID, dwTemplateID))
				end,
			}
		end
	end
end)
end

-- 地图重要NPC列表
do local INPC_LIST, INPC_LIST_CUSTOM
local function LoadCustomList()
	if not INPC_LIST_CUSTOM then
		INPC_LIST_CUSTOM = MY.LoadLUAData({'config/inpclist.jx3dat', MY_DATA_PATH.GLOBAL}) or {}
	end
end
local function SaveCustomList()
	MY.SaveLUAData({'config/inpclist.jx3dat', MY_DATA_PATH.GLOBAL}, INPC_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if INPC_LIST and not bForceRefresh then
		return
	end
	local VERSION = select(2, GetVersion())
	local CACHE_PATH = 'cache/inpclist/' .. VERSION .. '.jx3dat'
	INPC_LIST = MY.LoadLUAData({CACHE_PATH, MY_DATA_PATH.GLOBAL})
	if bForceRefresh or not INPC_LIST then
		INPC_LIST = {}
		MY.SaveLUAData({CACHE_PATH, MY_DATA_PATH.GLOBAL}, INPC_LIST)
		MY.Sysmsg({_L('Important Npc list updated to v%s.', VERSION)})
	end
	for dwMapID, tInfo in pairs(MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/inpclist/$lang.jx3dat') or {}) do
		if not INPC_LIST[dwMapID] then
			INPC_LIST[dwMapID] = {}
		end
		for dwNpcID, szName in pairs(tInfo.ADD or EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = szName
		end
		for dwNpcID, szName in pairs(tInfo.DEL or EMPTY_TABLE) do
			INPC_LIST[dwMapID][dwNpcID] = nil
		end
	end
end

-- 获取指定地图指定模板ID的NPC是不是重要NPC
-- (boolean) MY.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
function MY.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
	GenerateList()
	return (
		(
			INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID]
			and not (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or (not bNoBoss and MY.IsBoss(dwMapID, dwTemplateID) or false)
end

-- 获取指定模板ID的NPC是不是被屏蔽的NPC
-- (boolean) MY.IsShieldedNpc(dwTemplateID)
function MY.IsShieldedNpc(dwTemplateID)
	return Table_IsShieldedNpc and Table_IsShieldedNpc(dwTemplateID)
end

MY.RegisterTargetAddonMenu('MYLIB#Game#ImportantNpclist', function()
	local dwType, dwID = MY.GetTarget()
	if dwType == TARGET.NPC and (IsCtrlKeyDown() or IsAltKeyDown() or IsShiftKeyDown()) then
		GenerateList()
		local p = MY.GetObject(dwType, dwID)
		local szName = MY.GetObjectName(p)
		local dwMapID = GetClientPlayer().GetMapID()
		local szMapName = Table_GetMapName(dwMapID)
		local dwTemplateID = p.dwTemplateID
		if MY.IsImportantNpc(dwMapID, dwTemplateID, true) then
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
	[FORCE_TYPE.JIANG_HU ] = { 255, 255, 255 }, -- 江湖
	[FORCE_TYPE.SHAO_LIN ] = { 255, 178, 95  }, -- 少林
	[FORCE_TYPE.WAN_HUA  ] = { 196, 152, 255 }, -- 万花
	[FORCE_TYPE.TIAN_CE  ] = { 255, 111, 83  }, -- 天策
	[FORCE_TYPE.CHUN_YANG] = { 22 , 216, 216 }, -- 纯阳
	[FORCE_TYPE.QI_XIU   ] = { 255, 129, 176 }, -- 七秀
	[FORCE_TYPE.WU_DU    ] = { 55 , 147, 255 }, -- 五毒
	[FORCE_TYPE.TANG_MEN ] = { 121, 183, 54  }, -- 唐门
	[FORCE_TYPE.CANG_JIAN] = { 214, 249, 93  }, -- 藏剑
	[FORCE_TYPE.GAI_BANG ] = { 205, 133, 63  }, -- 丐帮
	[FORCE_TYPE.MING_JIAO] = { 240, 70 , 96  }, -- 明教
	[FORCE_TYPE.CANG_YUN ] = { 180, 60 , 0   }, -- 苍云
	[FORCE_TYPE.CHANG_GE ] = { 100, 250, 180 }, -- 长歌
	[FORCE_TYPE.BA_DAO   ] = { 106 ,108, 189 }, -- 霸刀
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_FORCE_COLOR_FG_GLOBAL = MY.LoadLUAData({SZ_FORCE_COLOR_FG, MY_DATA_PATH.GLOBAL}) or {}
local MY_FORCE_COLOR_FG_CUSTOM = {}
local MY_FORCE_COLOR_FG = setmetatable({}, {
	__index = function(t, k)
		return MY_FORCE_COLOR_FG_CUSTOM[k] or MY_FORCE_COLOR_FG_GLOBAL[k] or MY_FORCE_COLOR_FG_DEFAULT[k]
	end,
})

local SZ_FORCE_COLOR_BG = 'config/player_force_color_bg.jx3dat'
local MY_FORCE_COLOR_BG_DEFAULT = setmetatable({
	[FORCE_TYPE.JIANG_HU ] = { 255, 255, 255 }, -- 江湖
	[FORCE_TYPE.SHAO_LIN ] = { 255, 178, 95  }, -- 少林
	[FORCE_TYPE.WAN_HUA  ] = { 196, 152, 255 }, -- 万花
	[FORCE_TYPE.TIAN_CE  ] = { 255, 111, 83  }, -- 天策
	[FORCE_TYPE.CHUN_YANG] = { 22 , 216, 216 }, -- 纯阳
	[FORCE_TYPE.QI_XIU   ] = { 255, 129, 176 }, -- 七秀
	[FORCE_TYPE.WU_DU    ] = { 55 , 147, 255 }, -- 五毒
	[FORCE_TYPE.TANG_MEN ] = { 121, 183, 54  }, -- 唐门
	[FORCE_TYPE.CANG_JIAN] = { 214, 249, 93  }, -- 藏剑
	[FORCE_TYPE.GAI_BANG ] = { 205, 133, 63  }, -- 丐帮
	[FORCE_TYPE.MING_JIAO] = { 240, 70 , 96  }, -- 明教
	[FORCE_TYPE.CANG_YUN ] = { 180, 60 , 0   }, -- 苍云
	[FORCE_TYPE.CHANG_GE ] = { 100, 250, 180 }, -- 长歌
	[FORCE_TYPE.BA_DAO   ] = { 106 ,108, 189 }, -- 霸刀
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_FORCE_COLOR_BG_GLOBAL = MY.LoadLUAData({SZ_FORCE_COLOR_BG, MY_DATA_PATH.GLOBAL}) or {}
local MY_FORCE_COLOR_BG_CUSTOM = {}
local MY_FORCE_COLOR_BG = setmetatable({}, {
	__index = function(t, k)
		return MY_FORCE_COLOR_BG_CUSTOM[k] or MY_FORCE_COLOR_BG_GLOBAL[k] or MY_FORCE_COLOR_BG_DEFAULT[k]
	end,
})

local function initForceCustom()
	MY_FORCE_COLOR_FG_CUSTOM = MY.LoadLUAData({SZ_FORCE_COLOR_FG, MY_DATA_PATH.ROLE}) or {}
	MY_FORCE_COLOR_BG_CUSTOM = MY.LoadLUAData({SZ_FORCE_COLOR_BG, MY_DATA_PATH.ROLE}) or {}
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end
MY.RegisterInit(initForceCustom)

function MY.GetForceColor(dwForce, szType)
	local COLOR = szType == 'background'
		and MY_FORCE_COLOR_BG
		or MY_FORCE_COLOR_FG
	if dwForce == 'all' then
		return COLOR
	end
	return unpack(COLOR[dwForce])
end

local SZ_CAMP_COLOR_FG = 'config/player_camp_color.jx3dat'
local MY_CAMP_COLOR_FG_DEFAULT = setmetatable({
	[CAMP.NEUTRAL] = { 255, 255, 255 }, -- 中立
	[CAMP.GOOD   ] = {  60, 128, 220 }, -- 浩气盟
	[CAMP.EVIL   ] = { 160,  30,  30 }, -- 恶人谷
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_CAMP_COLOR_FG_GLOBAL = MY.LoadLUAData({SZ_CAMP_COLOR_FG, MY_DATA_PATH.GLOBAL}) or {}
local MY_CAMP_COLOR_FG_CUSTOM = {}
local MY_CAMP_COLOR_FG = setmetatable({}, {
	__index = function(t, k)
		return MY_CAMP_COLOR_FG_CUSTOM[k] or MY_CAMP_COLOR_FG_GLOBAL[k] or MY_CAMP_COLOR_FG_DEFAULT[k]
	end,
})

local SZ_CAMP_COLOR_BG = 'config/player_camp_color_bg.jx3dat'
local MY_CAMP_COLOR_BG_DEFAULT = setmetatable({
	[CAMP.NEUTRAL] = { 255, 255, 255 }, -- 中立
	[CAMP.GOOD   ] = {  60, 128, 220 }, -- 浩气盟
	[CAMP.EVIL   ] = { 160,  30,  30 }, -- 恶人谷
}, {
	__index = function(t, k)
		return { 225, 225, 225 }
	end,
	__metatable = true,
})
local MY_CAMP_COLOR_BG_GLOBAL = MY.LoadLUAData({SZ_CAMP_COLOR_BG, MY_DATA_PATH.GLOBAL}) or {}
local MY_CAMP_COLOR_BG_CUSTOM = {}
local MY_CAMP_COLOR_BG = setmetatable({}, {
	__index = function(t, k)
		return MY_CAMP_COLOR_BG_CUSTOM[k] or MY_CAMP_COLOR_BG_GLOBAL[k] or MY_CAMP_COLOR_BG_DEFAULT[k]
	end,
})

local function initCampCustom()
	MY_CAMP_COLOR_FG_CUSTOM = MY.LoadLUAData({SZ_CAMP_COLOR_FG, MY_DATA_PATH.ROLE}) or {}
	MY_CAMP_COLOR_BG_CUSTOM = MY.LoadLUAData({SZ_CAMP_COLOR_BG, MY_DATA_PATH.ROLE}) or {}
	FireUIEvent('MY_FORCE_COLOR_UPDATE')
end
MY.RegisterInit(initCampCustom)

function MY.GetCampColor(nCamp, szType)
	local COLOR = szType == 'background'
		and MY_CAMP_COLOR_BG
		or MY_CAMP_COLOR_FG
	if nCamp == 'all' then
		return COLOR
	end
	return unpack(COLOR[nCamp])
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = XGUI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 20
	local x, y = X, Y

	ui:append('Text', {
		x = X - 10, y = y,
		text = _L['Force color'],
		color = { 255, 255, 0 },
	}, true):autoWidth()
	x, y = X, y + 30
	for _, dwForceID in pairs_c(FORCE_TYPE) do
		local x0 = x
		local sha = ui:append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { MY.GetForceColor(dwForceID, 'background') },
		}, true)
		local txt = ui:append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.tForceTitle[dwForceID],
			color = { MY.GetForceColor(dwForceID, 'foreground') },
		}, true)
		x = x + 105
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetForceColor(dwForceID, 'foreground') },
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_FORCE_COLOR_FG_CUSTOM[dwForceID] = { r, g, b }
					MY.SaveLUAData({SZ_FORCE_COLOR_FG, MY_DATA_PATH.ROLE}, MY_FORCE_COLOR_FG_CUSTOM)
					txt:color(r, g, b)
					XGUI(this):color(r, g, b)
					FireUIEvent('MY_FORCE_COLOR_UPDATE')
				end)
			end,
		})
		x = x + 30
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetForceColor(dwForceID, 'background') },
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_FORCE_COLOR_BG_CUSTOM[dwForceID] = { r, g, b }
					MY.SaveLUAData({SZ_FORCE_COLOR_BG, MY_DATA_PATH.ROLE}, MY_FORCE_COLOR_BG_CUSTOM)
					sha:color(r, g, b)
					XGUI(this):color(r, g, b)
					FireUIEvent('MY_FORCE_COLOR_UPDATE')
				end)
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = X
			y = y + 35
		end
	end
	ui:append('WndButton2', {
		x = x, y = y, w = 160,
		text = _L['Restore default'],
		onclick = function()
			MY_FORCE_COLOR_FG_CUSTOM = {}
			MY_FORCE_COLOR_BG_CUSTOM = {}
			MY.SaveLUAData({SZ_FORCE_COLOR_FG, MY_DATA_PATH.ROLE}, MY_FORCE_COLOR_FG_CUSTOM)
			MY.SaveLUAData({SZ_FORCE_COLOR_BG, MY_DATA_PATH.ROLE}, MY_FORCE_COLOR_BG_CUSTOM)
			MY.SwitchTab('GlobalColor', true)
			FireUIEvent('MY_FORCE_COLOR_UPDATE')
		end,
	})

	y = y + 45
	ui:append('Text', {
		x = X - 10, y = y,
		text = _L['Camp color'],
		color = { 255, 255, 0 },
	}, true):autoWidth()
	x, y = X, y + 30
	for _, nCamp in ipairs({ CAMP.NEUTRAL, CAMP.GOOD, CAMP.EVIL }) do
		local x0 = x
		local sha = ui:append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { MY.GetCampColor(nCamp, 'background') },
		}, true)
		local txt = ui:append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { MY.GetCampColor(nCamp, 'foreground') },
		}, true)
		x = x + 105
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetCampColor(nCamp, 'foreground') },
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_CAMP_COLOR_FG_CUSTOM[nCamp] = { r, g, b }
					MY.SaveLUAData({SZ_CAMP_COLOR_FG, MY_DATA_PATH.ROLE}, MY_CAMP_COLOR_FG_CUSTOM)
					txt:color(r, g, b)
					XGUI(this):color(r, g, b)
					FireUIEvent('MY_CAMP_COLOR_UPDATE')
				end)
			end,
		})
		x = x + 30
		ui:append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { MY.GetCampColor(nCamp, 'background') },
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_CAMP_COLOR_BG_CUSTOM[nCamp] = { r, g, b }
					MY.SaveLUAData({SZ_CAMP_COLOR_BG, MY_DATA_PATH.ROLE}, MY_CAMP_COLOR_BG_CUSTOM)
					sha:color(r, g, b)
					XGUI(this):color(r, g, b)
					FireUIEvent('MY_CAMP_COLOR_UPDATE')
				end)
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = X
			y = y + 35
		end
	end
	ui:append('WndButton2', {
		x = x, y = y, w = 160,
		text = _L['Restore default'],
		onclick = function()
			MY_CAMP_COLOR_FG_CUSTOM = {}
			MY_CAMP_COLOR_BG_CUSTOM = {}
			MY.SaveLUAData({SZ_CAMP_COLOR_FG, MY_DATA_PATH.ROLE}, MY_CAMP_COLOR_FG_CUSTOM)
			MY.SaveLUAData({SZ_CAMP_COLOR_BG, MY_DATA_PATH.ROLE}, MY_CAMP_COLOR_BG_CUSTOM)
			MY.SwitchTab('GlobalColor', true)
			FireUIEvent('MY_CAMP_COLOR_UPDATE')
		end,
	})
end
MY.RegisterPanel('GlobalColor', _L['GlobalColor'], _L['System'], 2673, {255,255,0,200}, PS)
end

do
-- skillid, uitex, frame
local KUNGFU_LIST = setmetatable({
	-- MT
	{ 10062, 'ui/Image/icon/skill_tiance01.UITex',     0 }, -- 铁牢
	{ 10243, 'ui/Image/icon/mingjiao_taolu_7.UITex',   0 }, -- 明尊
	{ 10389, 'ui/Image/icon/Skill_CangY_33.UITex',     0 }, -- 铁骨
	{ 10002, 'ui/Image/icon/skill_shaolin14.UITex',    0 }, -- 少林
	-- 治疗
	{ 10080, 'ui/Image/icon/skill_qixiu02.UITex',      0 }, -- 云裳
	{ 10176, 'ui/Image/icon/wudu_neigong_2.UITex',     0 }, -- 补天
	{ 10028, 'ui/Image/icon/skill_wanhua23.UITex',     0 }, -- 离经
	{ 10448, 'ui/Image/icon/skill_0514_23.UITex',      0 }, -- 相知
	-- 内功
	{ 10225, 'ui/Image/icon/skill_tangm_20.UITex',     0 }, -- 天罗
	{ 10081, 'ui/Image/icon/skill_qixiu03.UITex',      0 }, -- 冰心
	{ 10175, 'ui/Image/icon/wudu_neigong_1.UITex',     0 }, -- 毒经
	{ 10242, 'ui/Image/icon/mingjiao_taolu_8.UITex',   0 }, -- 焚影
	{ 10014, 'ui/Image/icon/skill_chunyang21.UITex',   0 }, -- 紫霞
	{ 10021, 'ui/Image/icon/skill_wanhua17.UITex',     0 }, -- 花间
	{ 10003, 'ui/Image/icon/skill_shaolin10.UITex',    0 }, -- 易经
	{ 10447, 'ui/Image/icon/skill_0514_27.UITex',      0 }, -- 莫问
	-- 外功
	{ 10390, 'ui/Image/icon/Skill_CangY_32.UITex',     0 }, -- 分山
	{ 10224, 'ui/Image/icon/skill_tangm_01.UITex',     0 }, -- 鲸鱼
	{ 10144, 'ui/Image/icon/cangjian_neigong_1.UITex', 0 }, -- 问水
	{ 10145, 'ui/Image/icon/cangjian_neigong_2.UITex', 0 }, -- 山居
	{ 10015, 'ui/Image/icon/skill_chunyang13.UITex',   0 }, -- 备胎剑意
	{ 10026, 'ui/Image/icon/skill_tiance02.UITex',     0 }, -- 傲雪
	{ 10268, 'ui/Image/icon/skill_GB_30.UITex',        0 }, -- 笑尘
	{ 10464, 'ui/Image/icon/daoj_16_8_25_16.UITex',    0 }, -- 霸刀
}, {
	__index = function(me, key)
		for k, v in pairs(me) do
			if v[1] == key then
				return v
			end
		end
	end,
})

function MY.GetKungfuInfo(dwKungfuID)
	if dwKungfuID == 'all' then
		return KUNGFU_LIST
	end
	return unpack(KUNGFU_LIST[dwKungfuID])
end
end

do
local KUNGFU_NAME_CACHE = {}
local KUNGFU_SHORT_NAME_CACHE = {}
function MY.GetKungfuName(dwKungfuID, szType)
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
function MY.GetItemName(nUiId)
	if not ITEM_CACHE[nUiId] then
		local szName = Table_GetItemName(nUiId)
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
local NEARBY_NPC = {}      -- 附近的NPC
local NEARBY_PET = {}      -- 附近的PET
local NEARBY_PLAYER = {}   -- 附近的物品
local NEARBY_DOODAD = {}   -- 附近的玩家

-- 获取指定对象
-- (KObject, info, bIsInfo) MY.GetObject([number dwType, ]number dwID)
-- (KObject, info, bIsInfo) MY.GetObject([number dwType, ]string szName)
-- dwType: [可选]对象类型枚举 TARGET.*
-- dwID  : 对象ID
-- return: 根据 dwType 类型和 dwID 取得操作对象
--         不存在时返回nil, nil
function MY.GetObject(arg0, arg1, arg2)
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
				if MY.GetObjectName(KObject) == szName then
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

-- 获取指定对象的名字
-- MY.GetObjectName(obj, bRetID)
-- (KObject) obj    要获取名字的对象
-- (string)  eRetID 是否返回对象ID信息
--    'auto'   名字为空时返回 -- 默认值
--    'always' 总是返回
--    'never'  总是不返回
function MY.GetObjectName(obj, eRetID)
	if not obj then
		return nil
	end
	if not eRetID then
		eRetID = 'auto'
	end
	local szType, szName = MY.GetObjectType(obj), obj.szName
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
			if Table_IsSimplePlayer(obj.dwTemplateID) then -- 长歌影子
				szName = MY.GetObjectName(GetPlayer(obj.dwEmployer), eRetID)
			elseif not IsEmpty(szName) then
				local szEmpName = MY.GetObjectName(
					(IsPlayer(obj.dwEmployer) and GetPlayer(obj.dwEmployer)) or GetNpc(obj.dwEmployer),
					'never'
				) or g_tStrings.STR_SOME_BODY
				szName =  szEmpName .. g_tStrings.STR_PET_SKILL_LOG .. szName
			end
		end
	elseif szType == 'DOODAD' then -- DOODAD
		szType = 'D'
		if IsEmpty(szName) then
			szName = Table_GetDoodadTemplateName(obj.dwTemplateID)
			if szName then
				szName = szName:gsub('^%s*(.-)%s*$', '%1')
			end
		end
	elseif szType == 'ITEM' then -- ITEM
		szType = 'I'
		szName = GetItemNameByItem(obj)
	else
		szType = '?'
	end
	if IsEmpty(szName) and eRetID ~= 'never' or eRetID == 'always' then
		local szDispID = szType
		if szType == 'N' then
			szDispID = szDispID .. MY.ConvertNpcID(obj.dwID) .. '@' .. obj.dwTemplateID
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

function MY.GetObjectType(obj)
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

-- 获取附近NPC列表
-- (table) MY.GetNearNpc(void)
function MY.GetNearNpc(nLimit)
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

function MY.GetNearNpcID(nLimit)
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
function MY.GetNearNpcTable()
	return NEARBY_NPC
end
end

-- 获取附近PET列表
-- (table) MY.GetNearPet(void)
function MY.GetNearPet(nLimit)
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

function MY.GetNearPetID(nLimit)
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
function MY.GetNearPetTable()
	return NEARBY_PET
end
end

-- 获取附近玩家列表
-- (table) MY.GetNearPlayer(void)
function MY.GetNearPlayer(nLimit)
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

function MY.GetNearPlayerID(nLimit)
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
function MY.GetNearPlayerTable()
	return NEARBY_PLAYER
end
end

-- 获取附近物品列表
-- (table) MY.GetNearPlayer(void)
function MY.GetNearDoodad(nLimit)
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

function MY.GetNearDoodadID(nLimit)
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
function MY.GetNearDoodadTable()
	return NEARBY_DOODAD
end
end

RegisterEvent('NPC_ENTER_SCENE', function()
	local npc = GetNpc(arg0)
	if npc.dwOwnerID ~= 0 then
		NEARBY_PET[arg0] = npc
	end
	NEARBY_NPC[arg0] = npc
end)
RegisterEvent('NPC_LEAVE_SCENE', function()
	NEARBY_PET[arg0] = nil
	NEARBY_NPC[arg0] = nil
end)
RegisterEvent('PLAYER_ENTER_SCENE', function() NEARBY_PLAYER[arg0] = GetPlayer(arg0) end)
RegisterEvent('PLAYER_LEAVE_SCENE', function() NEARBY_PLAYER[arg0] = nil end)
RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = GetDoodad(arg0) end)
RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
end

-- 获取玩家自身信息（缓存）
do local m_ClientInfo
function MY.GetClientInfo(arg0)
	if arg0 == true or not (m_ClientInfo and m_ClientInfo.dwID) then
		local me = GetClientPlayer()
		if me then -- 确保获取到玩家
			if not m_ClientInfo then
				m_ClientInfo = {}
			end
			if not IsRemotePlayer(me.dwID) then -- 确保不在战场
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
MY.RegisterEvent('LOADING_ENDING', MY.GetClientInfo)
end

-- 获取唯一标识符
do local m_szUUID
function MY.GetClientUUID()
	if not m_szUUID then
		local me = GetClientPlayer()
		if me.GetGlobalID and me.GetGlobalID() ~= '0' then
			m_szUUID = me.GetGlobalID()
		else
			m_szUUID = (MY.GetRealServer()):gsub('[/\\|:%*%?"<>]', '') .. '_' .. MY.GetClientInfo().dwID
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
				FRIEND_LIST_BY_GROUP = {{ id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND or '' }} -- 默认分组
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
MY.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , OnFriendListChange)
MY.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , OnFriendListChange)
MY.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , OnFriendListChange)
MY.RegisterEvent('PLAYER_FOE_UPDATE'            , OnFriendListChange)
MY.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , OnFriendListChange)
MY.RegisterEvent('DELETE_FELLOWSHIP'            , OnFriendListChange)
MY.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', OnFriendListChange)
-- 获取好友列表
-- MY.GetFriendList()         获取所有好友列表
-- MY.GetFriendList(1)        获取第一个分组好友列表
-- MY.GetFriendList('挽月堂') 获取分组名称为挽月堂的好友列表
function MY.GetFriendList(arg0)
	local t = {}
	local tGroup = {}
	if GeneFriendListCache() then
		if type(arg0) == 'number' then
			table.insert(tGroup, FRIEND_LIST_BY_GROUP[arg0])
		elseif type(arg0) == 'string' then
			for _, group in ipairs(FRIEND_LIST_BY_GROUP) do
				if group.name == arg0 then
					table.insert(tGroup, clone(group))
				end
			end
		else
			tGroup = FRIEND_LIST_BY_GROUP
		end
		local n = 0
		for _, group in ipairs(tGroup) do
			for _, p in ipairs(group) do
				t[p.id], n = clone(p), n + 1
			end
		end
	end
	return t, n
end

-- 获取好友
function MY.GetFriend(arg0)
	if arg0 and GeneFriendListCache() then
		if type(arg0) == 'number' then
			return clone(FRIEND_LIST_BY_ID[arg0])
		elseif type(arg0) == 'string' then
			return clone(FRIEND_LIST_BY_NAME[arg0])
		end
	end
end

function MY.IsFriend(arg0)
	return MY.GetFriend(arg0) and true or false
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
MY.RegisterEvent('PLAYER_FOE_UPDATE', OnFoeListChange)
-- 获取仇人列表
function MY.GetFoeList()
	if GeneFoeListCache() then
		return clone(FOE_LIST)
	end
end
-- 获取仇人
function MY.GetFoe(arg0)
	if arg0 and GeneFoeListCache() then
		if type(arg0) == 'number' then
			return FOE_LIST_BY_ID[arg0]
		elseif type(arg0) == 'string' then
			return FOE_LIST_BY_NAME[arg0]
		end
	end
end
end

-- 获取好友列表
function MY.GetTongMemberList(bShowOffLine, szSorter, bAsc)
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
	-- GetMemberList(bShowOffLine, szSorter, bAsc, nGroupFilter, -1) -- 后面两个参数不知道什么鬼
	return GetTongClient().GetMemberList(bShowOffLine, szSorter or 'name', bAsc, -1, -1)
end

function MY.GetTongName(dwTongID)
	local szTongName
	if not dwTongID then
		dwTongID = (GetClientPlayer() or EMPTY_TABLE).dwTongID
	end
	if dwTongID and dwTongID ~= 0 then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, 253)
	else
		szTongName = ''
	end
	return szTongName
end

-- 获取帮会成员
function MY.GetTongMember(arg0)
	if not arg0 then
		return
	end

	return GetTongClient().GetMemberInfo(arg0)
end

function MY.IsTongMember(arg0)
	return MY.GetTongMember(arg0) and true or false
end

-- 判断是不是队友
function MY.IsParty(dwID)
	return GetClientPlayer().IsPlayerInMyParty(dwID)
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
	-- 判定战斗边界
	if MY.IsFighting() then
		-- 进入战斗判断
		if not FIGHTING then
			FIGHTING = true
			-- 5秒脱战判定缓冲 防止明教隐身错误判定
			if not FIGHT_UUID
			or GetTickCount() - FIGHT_END_TICK > 5000 then
				-- 新的一轮战斗开始
				FIGHT_BEGIN_TICK = GetTickCount()
				FIGHT_UUID = FIGHT_BEGIN_TICK
				FireUIEvent('MY_FIGHT_HINT', true)
			end
		end
	else
		-- 退出战斗判定
		if FIGHTING then
			FIGHT_END_TICK, FIGHTING = GetTickCount(), false
		elseif FIGHT_UUID and GetTickCount() - FIGHT_END_TICK > 5000 then
			LAST_FIGHT_UUID, FIGHT_UUID = FIGHT_UUID, nil
			FireUIEvent('MY_FIGHT_HINT', false)
		end
	end
end
MY.BreatheCall('MYLIB#ListenFightStateChange', ListenFightStateChange)

-- 获取当前战斗时间
function MY.GetFightTime(szFormat)
	local nTick = 0
	if MY.IsFighting() then -- 战斗状态
		nTick = GetTickCount() - FIGHT_BEGIN_TICK
	else  -- 脱战状态
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

-- 获取当前战斗唯一标示符
function MY.GetFightUUID()
	return FIGHT_UUID
end

-- 获取上次战斗唯一标示符
function MY.GetLastFightUUID()
	return LAST_FIGHT_UUID
end
end

-- 获取自身是否处于逻辑战斗状态
-- (bool) MY.IsFighting()
do local ARENA_START = false
function MY.IsFighting()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and MY.IsInArena() and ARENA_START then
		bFightState = true
	elseif not bFightState and MY.IsInDungeon() then
		-- 在副本且附近队友进战且附近敌对NPC进战则判断处于战斗状态
		local bPlayerFighting, bNpcFighting
		for _, p in ipairs(MY.GetNearPlayer()) do
			if me.IsPlayerInMyParty(p.dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for _, p in ipairs(MY.GetNearNpc()) do
				if IsEnemy(me.dwID, p.dwID) and p.bFightState then
					bNpcFighting = true
					break
				end
			end
		end
		bFightState = bPlayerFighting and bNpcFighting
	end
	return bFightState
end
MY.RegisterEvent('LOADING_ENDING.MY-PLAYER', function() ARENA_START = nil end)
MY.RegisterEvent('ARENA_START.MY-PLAYER', function() ARENA_START = true end)
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
-- 取得目标类型和ID
-- (dwType, dwID) MY.GetTarget()       -- 取得自己当前的目标类型和ID
-- (dwType, dwID) MY.GetTarget(object) -- 取得指定操作对象当前的目标类型和ID
function MY.GetTarget(object)
	if not object then
		object = GetClientPlayer()
	end
	if object then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end

-- 取得目标的目标类型和ID
-- (dwType, dwID) MY.GetTargetTarget()       -- 取得自己当前的目标的目标类型和ID
-- (dwType, dwID) MY.GetTargetTarget(object) -- 取得指定操作对象当前的目标的目标类型和ID
function MY.GetTargetTarget(object)
    local nTarType, dwTarID = MY.GetTarget(object)
    local KTar = MY.GetObject(nTarType, dwTarID)
    if not KTar then
        return
    end
    return MY.GetTarget(KTar)
end

-- 根据 dwType 类型和 dwID 设置目标
-- (void) MY.SetTarget([number dwType, ]number dwID)
-- (void) MY.SetTarget([number dwType, ]string szName)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID
function MY.SetTarget(arg0, arg1)
	local dwType, dwID, szNames
	if IsUserdata(arg0) then
		dwType, dwID = TARGET[MY.GetObjectType(arg0)], arg0.dwID
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
	if szNames then
		local tTarget = {}
		for _, szName in pairs(MY.SplitString(szNames:gsub('[%[%]]', ''), '|')) do
			tTarget[szName] = true
		end
		if not dwID and (not dwType or dwType == TARGET.NPC) then
			for _, p in ipairs(MY.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and (not dwType or dwType == TARGET.PLAYER) then
			for _, p in ipairs(MY.GetNearPlayer()) do
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
	SetTarget(dwType, dwID)
	return true
end

-- 设置/取消 临时目标
-- MY.SetTempTarget(dwType, dwID)
-- MY.ResumeTarget()
do
local TEMP_TARGET = { TARGET.NO_TARGET, 0 }
function MY.SetTempTarget(dwType, dwID)
	TargetPanel_SetOpenState(true)
	TEMP_TARGET = { GetClientPlayer().GetTarget() }
	MY.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end

function MY.ResumeTarget()
	TargetPanel_SetOpenState(true)
	-- 当之前的目标不存在时，切到空目标
	if TEMP_TARGET[1] ~= TARGET.NO_TARGET and not MY.GetObject(unpack(TEMP_TARGET)) then
		TEMP_TARGET = { TARGET.NO_TARGET, 0 }
	end
	MY.SetTarget(unpack(TEMP_TARGET))
	TEMP_TARGET = { TARGET.NO_TARGET, 0 }
	TargetPanel_SetOpenState(false)
end
end

-- 临时设置目标为指定目标并执行函数
-- (void) MY.WithTarget(dwType, dwID, callback)
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

	MY.SetTempTarget(r.dwType, r.dwID)
	local status, err = pcall(r.callback)
	if not status then
		MY.Debug({err}, 'MYLIB#WithTarget', MY_DEBUG.ERROR)
	end
	MY.ResumeTarget()

	LOCK_WITH_TARGET = false
	WithTargetHandle()
end
function MY.WithTarget(dwType, dwID, callback)
	-- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
	table.insert(WITH_TARGET_LIST, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	WithTargetHandle()
end
end

-- 求N2在N1的面向角  --  重载+2
-- (number) MY.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) MY.GetFaceAngel(oN1, oN2, bAbs)
-- @param nX    N1的X坐标
-- @param nY    N1的Y坐标
-- @param nFace N1的面向[0, 255]
-- @param nTX   N2的X坐标
-- @param nTY   N2的Y坐标
-- @param bAbs  返回角度是否只允许正数
-- @param oN1   N1对象
-- @param oN2   N2对象
-- @return nil    参数错误
-- @return number 面向角(-180, 180]
function MY.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
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

-- 装备名为szName的装备
-- (void) MY.Equip(szName)
-- szName  装备名称
function MY.Equip(szName)
	local me = GetClientPlayer()
	for i=1,6 do
		if me.GetBoxSize(i)>0 then
			for j=0, me.GetBoxSize(i)-1 do
				local item = me.GetItem(i,j)
				if item == nil then
					j=j+1
				elseif Table_GetItemName(item.nUiId)==szName then -- GetItemNameByItem(item)
					local eRetCode, nEquipPos = me.GetEquipPos(i, j)
					if szName==_L['ji guan'] or szName==_L['nu jian'] then
						for k=0,15 do
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

-- 获取对象的buff列表
-- (table) MY.GetBuffList(KObject)
function MY.GetBuffList(KObject)
	KObject = KObject or GetClientPlayer()
	local aBuffTable = {}
	local nCount = KObject.GetBuffCount() or 0
	for i = 1, nCount do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = KObject.GetBuff(i - 1)
		if dwID then
			table.insert(aBuffTable, {
				dwID         = dwID        ,
				nLevel       = nLevel      ,
				bCanCancel   = bCanCancel  ,
				nEndFrame    = nEndFrame   ,
				nIndex       = nIndex      ,
				nStackNum    = nStackNum   ,
				dwSkillSrcID = dwSkillSrcID,
				bValid       = bValid      ,
				nCount       = i           ,
			})
		end
	end
	return aBuffTable
end

-- 获取对象的buff
-- tBuff: {[dwID1] = nLevel1, [dwID2] = nLevel2}
-- (table) MY.GetBuff(dwID[, nLevel[, dwSkillSrcID]])
-- (table) MY.GetBuff(KObject, dwID[, nLevel[, dwSkillSrcID]])
-- (table) MY.GetBuff(tBuff[, dwSkillSrcID])
-- (table) MY.GetBuff(KObject, tBuff[, dwSkillSrcID])
function MY.GetBuff(KObject, dwID, nLevel, dwSkillSrcID)
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
				return MY.Debug({'KObject neither has a function named GetBuffByOwner nor named GetBuff.'}, 'MY.GetBuff', MY_DEBUG.ERROR)
			end
			for _, buff in ipairs(MY.GetBuffList(KObject)) do
				if (tBuff[buff.dwID] == buff.nLevel or tBuff[buff.dwID] == 0) and buff.dwSkillSrcID == dwSkillSrcID then
					return {
						dwID         = buff.dwID        ,
						nLevel       = buff.nLevel      ,
						bCanCancel   = buff.bCanCancel  ,
						nEndFrame    = buff.nEndFrame   ,
						nIndex       = buff.nIndex      ,
						nStackNum    = buff.nStackNum   ,
						dwSkillSrcID = buff.dwSkillSrcID,
						bValid       = buff.bValid      ,
						nCount       = buff.nCount      ,
						GetEndTime = function() return buff.nEndFrame end,
					}
				end
			end
			-- return MY.Debug({'KObject do not have a function named GetBuffByOwner.'}, 'MY.GetBuff', MY_DEBUG.ERROR)
		end
	else
		if not KObject.GetBuff then
			return MY.Debug({'KObject do not have a function named GetBuff.'}, 'MY.GetBuff', MY_DEBUG.ERROR)
		end
		for k, v in pairs(tBuff) do
			local KBuff = KObject.GetBuff(k, v)
			if KBuff then
				return KBuff
			end
		end
	end
end

-- 点掉自己的buff
-- (table) MY.CancelBuff([KObject = me, ]dwID[, nLevel = 0])
function MY.CancelBuff(KObject, dwID, nLevel)
	if type(KObject) ~= 'userdata' then
		KObject, dwID, nLevel = nil, KObject, dwID
	end
	if not KObject then
		KObject = GetClientPlayer()
	end
	local tBuffs = MY.GetBuffList(KObject)
	for _, buff in ipairs(tBuffs) do
		if (type(dwID) == 'string' and Table_GetBuffName(buff.dwID, buff.nLevel) == dwID or buff.dwID == dwID)
		and (not nLevel or nLevel == 0 or buff.nLevel == nLevel) then
			KObject.CancelBuff(buff.nIndex)
		end
	end
end

do
local BUFF_CACHE
function MY.IsBossFocusBuff(dwID, nLevel, nStackNum)
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

-- 获取对象是否无敌
-- (mixed) MY.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function MY.IsInvincible(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return nil
	elseif MY.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end

-- 获取对象当前是否可读条
-- (bool) MY.CanOTAction([object KObject])
function MY.CanOTAction(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return
	end
	return KObject.nMoveState == MOVE_STATE.ON_STAND or KObject.nMoveState == MOVE_STATE.ON_FLOAT
end

-- 通过技能名称获取技能对象
-- (table) MY.GetSkillByName(szName)
do local PLAYER_SKILL_CACHE = {} -- 玩家技能列表[缓存] 技能名反查ID
function MY.GetSkillByName(szName)
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

-- 判断技能名称是否有效
-- (bool) MY.IsValidSkill(szName)
function MY.IsValidSkill(szName)
	if MY.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) MY.CanUseSkill(number dwSkillID[, dwLevel])
do local BOX
function MY.CanUseSkill(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == 'string' then
		if not MY.IsValidSkill(dwSkillID) then
			return false
		end
		dwSkillID = MY.GetSkillByName(dwSkillID).dwSkillID
	end
	if not BOX then
		BOX = XGUI.CreateFrame('MY_SKILL', { w = 0, h = 0, empty = true }):hide():append('Box', {}, true)
	end
	local me, box = GetClientPlayer(), BOX
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

-- 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）
-- (string, number) MY.GetSkillName(number dwSkillID[, number dwLevel])
do local SKILL_CACHE = {} -- 技能列表缓存 技能ID查技能名称图标
function MY.GetSkillName(dwSkillID, dwLevel)
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

-- 登出游戏
-- (void) MY.Logout(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
function MY.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) MY.GetChannelSkillFrame(number dwSkillID)
do local SKILL_EX = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/skill_ex.jx3dat') or {}
function MY.GetChannelSkillFrame(dwSkillID)
	local t = SKILL_EX[dwSkillID]
	if t then
		return t.nChannelFrame
	end
end
end

function MY.IsMarker()
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == UI_GetClientPlayerID()
end

function MY.IsLeader()
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == UI_GetClientPlayerID()
end

function MY.IsDistributer()
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == UI_GetClientPlayerID()
end

-- 判断自己在不在队伍里
-- (bool) MY.IsInParty()
function MY.IsInParty()
	local me = GetClientPlayer()
	return me and me.IsInParty()
end

-- 判断当前地图是不是竞技场
-- (bool) MY.IsInArena()
function MY.IsInArena()
	local me = GetClientPlayer()
	return me and (
		me.GetScene().bIsArenaMap or -- JJC
		me.GetMapID() == 173 or      -- 齐物阁
		me.GetMapID() == 181         -- 狼影殿
	)
end
MY.IsInArena = MY.IsInArena

-- 判断当前地图是不是战场
-- (bool) MY.IsInBattleField()
function MY.IsInBattleField()
	local me = GetClientPlayer()
	return me and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD and not MY.IsInArena()
end

-- 判断一个地图是不是副本
-- (bool) MY.IsDungeonMap(szMapName, bRaid)
-- (bool) MY.IsDungeonMap(dwMapID, bRaid)
do local MAP_LIST
function MY.IsDungeonMap(dwMapID, bRaid)
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
	if bRaid then -- 严格判断25人本
		return map and map.bDungeon
	else -- 只判断地图的类型
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
	end
end
end

-- 判断一个地图是不是个人CD副本
-- (bool) MY.IsDungeonRoleProgressMap(dwMapID)
function MY.IsDungeonRoleProgressMap(dwMapID)
	return (select(8, GetMapParams(dwMapID)))
end
MY.IsDungeonRoleProgressMap = MY.IsDungeonRoleProgressMap

-- 判断当前地图是不是副本
-- (bool) MY.IsInDungeon(bool bRaid)
function MY.IsInDungeon(bRaid)
	local me = GetClientPlayer()
	return me and MY.IsDungeonMap(me.GetMapID(), bRaid)
end

-- 判断地图是不是PUBG
-- (bool) MY.IsPubgMap(dwMapID)
do
local PUBG_MAP = {}
function MY.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = Table_IsTreasureBattleFieldMap
			and Table_IsTreasureBattleFieldMap(dwMapID) or false
	end
	return PUBG_MAP[dwMapID]
end
end

-- 判断当前地图是不是PUBG
-- (bool) MY.IsInPubg()
function MY.IsInPubg()
	local me = GetClientPlayer()
	return me and MY.IsPubgMap(me.GetMapID())
end

-- 判断地图是不是僵尸地图
-- (bool) MY.IsZombieMap(dwMapID)
do
local ZOMBIE_MAP = {}
function MY.IsZombieMap(dwMapID)
	if ZOMBIE_MAP[dwMapID] == nil then
		ZOMBIE_MAP[dwMapID] = Table_IsZombieBattleFieldMap
			and Table_IsZombieBattleFieldMap(dwMapID) or false
	end
	return ZOMBIE_MAP[dwMapID]
end
end

-- 判断当前地图是不是僵尸地图
-- (bool) MY.IsInZombieMap()
function MY.IsInZombieMap()
	local me = GetClientPlayer()
	return me and MY.IsZombieMap(me.GetMapID())
end

-- 判断地图是不是功能屏蔽地图
-- (bool) MY.IsShieldedMap(dwMapID)
function MY.IsShieldedMap(dwMapID)
	return MY.IsPubgMap(dwMapID) or MY.IsZombieMap(dwMapID)
end

-- 判断当前地图是不是PUBG
-- (bool) MY.IsInShieldedMap()
function MY.IsInShieldedMap()
	local me = GetClientPlayer()
	return me and MY.IsShieldedMap(me.GetMapID())
end

do local MARK_NAME = { _L['Cloud'], _L['Sword'], _L['Ax'], _L['Hook'], _L['Drum'], _L['Shear'], _L['Stick'], _L['Jade'], _L['Dart'], _L['Fan'] }
-- 获取标记中文名
-- (string) MY.GetMarkName([number nIndex])
function MY.GetMarkName(nIndex)
	if nIndex then
		return MARK_NAME[nIndex]
	else
		return clone(MARK_NAME)
	end
end

function MY.GetMarkIndex(dwID)
	if not MY.IsInParty() then
		return
	end
	return GetClientTeam().GetMarkIndex(dwID)
end

-- 保存当前团队信息
-- (table) MY.GetTeamInfo([table tTeamInfo])
function MY.GetTeamInfo(tTeamInfo)
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
	if state.bForm then --如果这货之前有阵眼
		team.SetTeamFormationLeader(dwID, state.nGroup) -- 阵眼给他
		MY.Sysmsg({_L('restore formation of %d group: %s', state.nGroup + 1, szName)})
	end
	if state.nMark then -- 如果这货之前有标记
		team.SetTeamMark(state.nMark, dwID) -- 标记给他
		MY.Sysmsg({_L('restore player marked as [%s]: %s', MARK_NAME[state.nMark], szName)})
	end
end
-- 恢复团队信息
-- (bool) MY.SetTeamInfo(table tTeamInfo)
function MY.SetTeamInfo(tTeamInfo)
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
		return MY.Sysmsg({_L['You are not team leader, permission denied']})
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
				MY.Sysmsg({_L('unable get player of %d group: #%d', nGroup + 1, dwID)})
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					MY.Sysmsg({_L('unknown status: %s', szName)})
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					MY.Sysmsg({_L('need not adjust: %s', szName)})
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
					MY.Sysmsg({_L('restore distributor: %s', szName)})
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
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- 直接丢过去
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				table.remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					table.insert(tWrong[nGroup], dst)
				else -- bingo
					MY.Sysmsg({_L('change group of [%s] to %d', dst.szName, nGroup + 1)})
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			MY.Sysmsg({_L('change group of [%s] to %d', src.szName, src.state.nGroup + 1)})
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
		MY.Sysmsg({_L('restore team marker: %s', tTeamInfo.szMark)})
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		MY.Sysmsg({_L('restore team leader: %s', tTeamInfo.szLeader)})
	end
	MY.Sysmsg({_L['Team list restored']})
end
end

function MY.UpdateItemBoxExtend(box, nQuality)
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
function MY.GetGlobalEffect(nID)
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
