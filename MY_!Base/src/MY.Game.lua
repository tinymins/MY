--------------------------------------------
-- @Desc  : 茗伊插件 游戏环境库
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2016-12-06 14:49:07
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi = math.huge, math.pi
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
MY = MY or {}
MY.Game = MY.Game or {}
local _Cache, _L = {}, MY.LoadLangPack()
local _C = {}

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
_Cache.tHotkey = {}
-- 增加系统快捷键
-- (void) MY.RegisterHotKey(string szName, string szTitle, func fnAction)   -- 增加系统快捷键
function MY.Game.RegisterHotKey(szName, szTitle, fnAction)
	insert(_Cache.tHotkey, { szName = szName, szTitle = szTitle, fnAction = fnAction })
end
MY.RegisterHotKey = MY.Game.RegisterHotKey

-- 获取快捷键名称
-- (string) MY.GetHotKeyDisplay(string szName, boolean bBracket, boolean bShort)      -- 取得快捷键名称
function MY.Game.GetHotKeyDisplay(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szDisplay = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szDisplay ~= '' and bBracket then
		szDisplay = '(' .. szDisplay .. ')'
	end
	return szDisplay
end
MY.GetHotKeyDisplay = MY.Game.GetHotKeyDisplay

-- 获取快捷键
-- (table) MY.GetHotKey(string szName, true , true )       -- 取得快捷键
-- (number nKey, boolean bShift, boolean bCtrl, boolean bAlt) MY.GetHotKey(string szName, true , fasle)        -- 取得快捷键
function MY.Game.GetHotKey(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	if nKey==0 then return nil end
	if bBracket then
		return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
	else
		return nKey, bShift, bCtrl, bAlt
	end
end
MY.GetHotKey = MY.Game.GetHotKey

-- 设置快捷键/打开快捷键设置面板    -- HM里面抠出来的
-- (void) MY.SetHotKey()                               -- 打开快捷键设置面板
-- (void) MY.SetHotKey(string szGroup)     -- 打开快捷键设置面板并定位到 szGroup 分组（不可用）
-- (void) MY.SetHotKey(string szCommand, number nKey )     -- 设置快捷键
-- (void) MY.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- 设置快捷键
function MY.Game.SetHotKey(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
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
MY.SetHotKey = MY.Game.SetHotKey

MY.RegisterInit('MYLIB#BIND_HOTKEY', function()
	-- hotkey
	Hotkey.AddBinding('MY_Total', _L['Open/Close main panel'], MY.GetAddonInfo().szName, MY.TogglePanel, nil)
	for _, v in ipairs(_Cache.tHotkey) do
		Hotkey.AddBinding(v.szName, v.szTitle, '', v.fnAction, nil)
	end
	for i = 1, 5 do
		Hotkey.AddBinding('MY_HotKey_Null_'..i, _L['none-function hotkey'], '', function() end, nil)
	end
end)
MY.Game.RegisterHotKey('MY_STOP_CASTING', _L['Stop cast skill'], function() GetClientPlayer().StopCurrentAction() end)
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
function MY.Game.GetServer(nIndex)
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
MY.GetServer = MY.Game.GetServer

-- 获取当前服务器显示名称
function MY.Game.GetDisplayServer(nIndex)
	local display_region, display_server = GetUserServer()
	if nIndex == 1 then
		return display_region
	elseif nIndex == 2 then
		return display_server
	else
		return display_region .. '_' .. display_server, {display_region, display_server}
	end
end
MY.GetDisplayServer = MY.Game.GetDisplayServer

-- 获取数据互通主服务器名称
function MY.Game.GetRealServer(nIndex)
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
MY.GetRealServer = MY.Game.GetRealServer

-- 获取指定对象
-- (KObject, info, bIsInfo) MY.GetObject([number dwType, ]number dwID)
-- dwType: [可选]对象类型枚举 TARGET.*
-- dwID  : 对象ID
-- return: 根据 dwType 类型和 dwID 取得操作对象
--         不存在时返回nil, nil
function MY.Game.GetObject(dwType, dwID)
	if not dwID then
		dwType, dwID = nil, dwType
	end
	local p, info, b

	if not dwType then
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		elseif GetDoodad(dwID) then
			dwType = TARGET.DOODAD
		else
			dwType = TARGET.NPC
		end
	end

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
MY.GetObject = MY.Game.GetObject

-- 获取指定对象的名字
function MY.Game.GetObjectName(obj)
	if not obj then
		return nil
	end

	local szName = obj.szName
	if IsPlayer(obj.dwID) then  -- PLAYER
		if szName == '' then
			szName = nil
		end
		return szName
	elseif obj.nMaxLife then    -- NPC
		if szName == '' then
			szName = string.gsub(Table_GetNpcTemplateName(obj.dwTemplateID), '^%s*(.-)%s*$', '%1')
			if szName == '' then
				if obj.dwEmployer and obj.dwEmployer ~= 0 then
					return MY.GetObjectName(GetPlayer(obj.dwEmployer)) -- 长歌影子
				else
					szName = nil
				end
			end
		end
		if szName and obj.dwEmployer and obj.dwEmployer ~= 0 then
			local szEmpName = MY.GetObjectName(
				(IsPlayer(obj.dwEmployer) and GetPlayer(obj.dwEmployer)) or GetNpc(obj.dwEmployer)
			) or g_tStrings.STR_SOME_BODY

			szName =  szEmpName .. g_tStrings.STR_PET_SKILL_LOG .. (szName or '')
		end
		return szName
	elseif obj.CanLoot then -- DOODAD
		if szName == '' then
			szName = string.gsub(Table_GetDoodadTemplateName(obj.dwTemplateID), '^%s*(.-)%s*$', '%1')
			if szName == '' then
				szName = nil
			end
		end
	elseif obj.IsRepairable then -- ITEM
		return GetItemNameByItem(obj)
	end
end
MY.GetObjectName = MY.Game.GetObjectName

function MY.GetDistance(nX, nY, nZ)
	local me = GetClientPlayer()
	if not nY and not nZ then
		local tar = nX
		nX, nY, nZ = tar.nX, tar.nY, tar.nZ
	elseif not nZ then
		return floor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2) ^ 0.5)/64
	end
	return floor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2 + (me.nZ/8 - nZ/8) ^ 2) ^ 0.5)/64
end

do local MY_CACHE_BUFF = {}
function MY.GetBuffName(dwBuffID, dwLevel)
	local xKey = dwBuffID
	if dwLevel then
		xKey = dwBuffID .. '_' .. dwLevel
	end
	if not MY_CACHE_BUFF[xKey] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			MY_CACHE_BUFF[xKey] = { tLine.szName, tLine.dwIconID }
		else
			local szName = 'BUFF#' .. dwBuffID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			MY_CACHE_BUFF[xKey] = { szName, 1436 }
		end
	end
	return unpack(MY_CACHE_BUFF[xKey])
end
end

function MY.GetEndTime(nEndFrame)
	return (nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
end

-- 获取指定名字的右键菜单
function MY.Game.GetTargetContextMenu(dwType, szName, dwID)
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
			then
				table.insert(t, v)
			end
		end
	end

	return t
end
MY.GetTargetContextMenu = MY.Game.GetTargetContextMenu

-- 判断一个地图是不是副本
-- (bool) MY.Game.IsDungeonMap(szMapName, bRaid)
-- (bool) MY.Game.IsDungeonMap(dwMapID, bRaid)
function MY.Game.IsDungeonMap(dwMapID, bRaid)
	if not _Cache.tMapList then
		_Cache.tMapList = {}
		for _, dwMapID in ipairs(GetMapList()) do
			local map          = { dwMapID = dwMapID }
			local szName       = Table_GetMapName(dwMapID)
			local tDungeonInfo = g_tTable.DungeonInfo:Search(dwMapID)
			if tDungeonInfo and tDungeonInfo.dwClassID == 3 then
				map.bDungeon = true
			end
			_Cache.tMapList[szName] = map
			_Cache.tMapList[dwMapID] = map
		end
	end
	local map = _Cache.tMapList[dwMapID]
	if map then
		dwMapID = map.dwMapID
	end
	if bRaid then -- 严格判断25人本
		return map and map.bDungeon
	else -- 只判断地图的类型
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
	end
end
MY.IsDungeonMap = MY.Game.IsDungeonMap

-- 地图BOSS列表
do local BOSS_LIST, BOSS_LIST_CUSTOM
local function LoadCustomList()
	if not BOSS_LIST_CUSTOM then
		BOSS_LIST_CUSTOM = MY.LoadLUAData({'config/bosslist.jx3dat', MY_DATA_PATH.GLOBAL}) or {}
	end
end
local function SaveCustomList()
	MY.SaveLUAData({'config/bosslist.jx3dat', MY_DATA_PATH.GLOBAL}, BOSS_LIST_CUSTOM, IsDebugClient() and '\t' or nil)
end
local function GenerateList(bForceRefresh)
	LoadCustomList()
	if BOSS_LIST and not bForceRefresh then
		return
	end
	local VERSION = select(2, GetVersion())
	local CACHE_PATH = 'cache/bosslist/' .. VERSION .. '.jx3dat'
	BOSS_LIST = MY.LoadLUAData({CACHE_PATH, MY_DATA_PATH.GLOBAL})
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
		MY.SaveLUAData({CACHE_PATH, MY_DATA_PATH.GLOBAL}, BOSS_LIST)
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

MY.RegisterTargetAddonMenu('MY.Game.Bosslist', function()
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
-- (boolean) MY.IsImportantNpc(dwMapID, dwTem)
function MY.IsImportantNpc(dwMapID, dwTemplateID, bNoBoss)
	GenerateList()
	return (
		(
			INPC_LIST[dwMapID] and INPC_LIST[dwMapID][dwTemplateID]
			and not (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].DEL[dwTemplateID])
		) or (INPC_LIST_CUSTOM[dwMapID] and INPC_LIST_CUSTOM[dwMapID].ADD[dwTemplateID])
	) and true or (not bNoBoss and MY.IsBoss(dwMapID, dwTemplateID) or false)
end

MY.RegisterTargetAddonMenu('MY.Game.ImportantNpclist', function()
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
local MY_KUNGFU_LIST = setmetatable({
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
		return MY_KUNGFU_LIST
	end
	return unpack(MY_KUNGFU_LIST[dwKungfuID])
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
local MY_CACHE_ITEM = {}
function MY.GetItemName(nUiId)
	if not MY_CACHE_ITEM[nUiId] then
		local szName = Table_GetItemName(nUiId)
		local nIcon = Table_GetItemIconID(nUiId)
		if szName ~= '' and nIocn ~= -1 then
			MY_CACHE_ITEM[nUiId] = { szName, nIcon }
		else
			MY_CACHE_ITEM[nUiId] = { 'ITEM#' .. nUiId, 1435 }
		end
	end
	return unpack(MY_CACHE_ITEM[nUiId])
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
MY_NEARBY_NPC = {}      -- 附近的NPC
MY_NEARBY_PLAYER = {}   -- 附近的物品
MY_NEARBY_DOODAD = {}   -- 附近的玩家

-- 获取附近NPC列表
-- (table) MY.GetNearNpc(void)
function MY.Game.GetNearNpc(nLimit)
	local tNpc, i = {}, 0
	for dwID, _ in pairs(MY_NEARBY_NPC) do
		local npc = GetNpc(dwID)
		if not npc then
			MY_NEARBY_NPC[dwID] = nil
		else
			i = i + 1
			if npc.szName=='' then
				npc.szName = string.gsub(Table_GetNpcTemplateName(npc.dwTemplateID), '^%s*(.-)%s*$', '%1')
			end
			tNpc[dwID] = npc
			if nLimit and i == nLimit then break end
		end
	end
	return tNpc, i
end
MY.GetNearNpc = MY.Game.GetNearNpc

-- 获取附近玩家列表
-- (table) MY.GetNearPlayer(void)
function MY.Game.GetNearPlayer(nLimit)
	local tPlayer, i = {}, 0
	for dwID, _ in pairs(MY_NEARBY_PLAYER) do
		local player = GetPlayer(dwID)
		if not player then
			MY_NEARBY_PLAYER[dwID] = nil
		else
			i = i + 1
			tPlayer[dwID] = player
			if nLimit and i == nLimit then break end
		end
	end
	return tPlayer, i
end
MY.GetNearPlayer = MY.Game.GetNearPlayer

-- 获取附近物品列表
-- (table) MY.GetNearPlayer(void)
function MY.Game.GetNearDoodad(nLimit)
	local tDoodad, i = {}, 0
	for dwID, _ in pairs(MY_NEARBY_DOODAD) do
		local dooded = GetDoodad(dwID)
		if not dooded then
			MY_NEARBY_DOODAD[dwID] = nil
		else
			i = i + 1
			tDoodad[dwID] = dooded
			if nLimit and i == nLimit then break end
		end
	end
	return tDoodad, i
end
MY.GetNearDoodad = MY.Game.GetNearDoodad

RegisterEvent('NPC_ENTER_SCENE',    function() MY_NEARBY_NPC[arg0]    = true end)
RegisterEvent('NPC_LEAVE_SCENE',    function() MY_NEARBY_NPC[arg0]    = nil  end)
RegisterEvent('PLAYER_ENTER_SCENE', function() MY_NEARBY_PLAYER[arg0] = true end)
RegisterEvent('PLAYER_LEAVE_SCENE', function() MY_NEARBY_PLAYER[arg0] = nil  end)
RegisterEvent('DOODAD_ENTER_SCENE', function() MY_NEARBY_DOODAD[arg0] = true end)
RegisterEvent('DOODAD_LEAVE_SCENE', function() MY_NEARBY_DOODAD[arg0] = nil  end)
end

-- 获取玩家自身信息（缓存）
do local m_ClientInfo
function MY.Game.GetClientInfo(bForceRefresh)
	if bForceRefresh or not (m_ClientInfo and m_ClientInfo.dwID) then
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
		end
	end

	return m_ClientInfo or {}
end
MY.GetClientInfo = MY.Game.GetClientInfo
MY.RegisterEvent('LOADING_ENDING', MY.Game.GetClientInfo)
end

-- 获取唯一标识符
do local m_szUUID
function MY.GetClientUUID()
	if not m_szUUID then
		local me = GetClientPlayer()
		if me.GetGlobalID and me.GetGlobalID() ~= '0' then
			m_szUUID = me.GetGlobalID()
		else
			m_szUUID = (MY.Game.GetRealServer()):gsub('[/\\|:%*%?"<>]', '') .. '_' .. MY.Game.GetClientInfo().dwID
		end
	end
	return m_szUUID
end
end

function _C.GeneFriendListCache()
	if not _C.tFriendListByGroup then
		local me = GetClientPlayer()
		if me then
			local infos = me.GetFellowshipGroupInfo()
			if infos then
				_C.tFriendListByID = {}
				_C.tFriendListByName = {}
				_C.tFriendListByGroup = {{ id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND or '' }} -- 默认分组
				for _, group in ipairs(infos) do
					table.insert(_C.tFriendListByGroup, group)
				end
				for _, group in ipairs(_C.tFriendListByGroup) do
					for _, p in ipairs(me.GetFellowshipInfo(group.id) or {}) do
						table.insert(group, p)
						_C.tFriendListByID[p.id] = p
						_C.tFriendListByName[p.name] = p
					end
				end
				return true
			end
		end
		return false
	end
	return true
end
function _C.OnFriendListChange()
	_C.tFriendListByID = nil
	_C.tFriendListByName = nil
	_C.tFriendListByGroup = nil
end
MY.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , _C.OnFriendListChange)
MY.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , _C.OnFriendListChange)
MY.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , _C.OnFriendListChange)
MY.RegisterEvent('PLAYER_FOE_UPDATE'            , _C.OnFriendListChange)
MY.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , _C.OnFriendListChange)
MY.RegisterEvent('DELETE_FELLOWSHIP'            , _C.OnFriendListChange)
MY.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', _C.OnFriendListChange)
-- 获取好友列表
-- MY.Game.GetFriendList()         获取所有好友列表
-- MY.Game.GetFriendList(1)        获取第一个分组好友列表
-- MY.Game.GetFriendList('挽月堂') 获取分组名称为挽月堂的好友列表
function MY.Game.GetFriendList(arg0)
	local t = {}
	local tGroup = {}
	if _C.GeneFriendListCache() then
		if type(arg0) == 'number' then
			table.insert(tGroup, _C.tFriendListByGroup[arg0])
		elseif type(arg0) == 'string' then
			for _, group in ipairs(_C.tFriendListByGroup) do
				if group.name == arg0 then
					table.insert(tGroup, clone(group))
				end
			end
		else
			tGroup = _C.tFriendListByGroup
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
function MY.Game.GetFriend(arg0)
	if arg0 and _C.GeneFriendListCache() then
		if type(arg0) == 'number' then
			return clone(_C.tFriendListByID[arg0])
		elseif type(arg0) == 'string' then
			return clone(_C.tFriendListByName[arg0])
		end
	end
end
MY.GetFriend = MY.Game.GetFriend

function _C.GeneFoeListCache()
	if not _C.tFoeList then
		local me = GetClientPlayer()
		if me then
			_C.tFoeList = {}
			_C.tFoeListByID = {}
			_C.tFoeListByName = {}
			if me.GetFoeInfo then
				local infos = me.GetFoeInfo()
				if infos then
					for i, p in ipairs(infos) do
						_C.tFoeListByID[p.id] = p
						_C.tFoeListByName[p.name] = p
						table.insert(_C.tFoeList, p)
					end
					return true
				end
			end
		end
		return false
	end
	return true
end
function _C.OnFoeListChange()
	_C.tFoeList = nil
	_C.tFoeListByID = nil
	_C.tFoeListByName = nil
end
MY.RegisterEvent('PLAYER_FOE_UPDATE', _C.OnFoeListChange)
-- 获取仇人列表
function MY.Game.GetFoeList()
	if _C.GeneFoeListCache() then
		return clone(_C.tFoeList)
	end
end
-- 获取仇人
function MY.Game.GetFoe(arg0)
	if arg0 and _C.GeneFoeListCache() then
		if type(arg0) == 'number' then
			return _C.tFoeListByID[arg0]
		elseif type(arg0) == 'string' then
			return _C.tFoeListByName[arg0]
		end
	end
end
MY.GetFoe = MY.Game.GetFoe

-- 获取好友列表
function MY.Game.GetTongMemberList(bShowOffLine, szSorter, bAsc)
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
function MY.Game.GetTongMember(arg0)
	if not arg0 then
		return
	end

	return GetTongClient().GetMemberInfo(arg0)
end
MY.GetTongMember = MY.Game.GetTongMember

-- 判断是不是队友
function MY.Game.IsParty(dwID)
	return GetClientPlayer().IsPlayerInMyParty(dwID)
end
MY.IsParty = MY.Game.IsParty

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
_C.nLastFightUUID  = nil
_C.nFightUUID      = nil
_C.nFightBeginTick = -1
_C.nFightEndTick   = -1
function _C.OnFightStateChange()
	-- 判定战斗边界
	if MY.IsFighting() then
		-- 进入战斗判断
		if not _C.bFighting then
			_C.bFighting = true
			-- 5秒脱战判定缓冲 防止明教隐身错误判定
			if not _C.nFightUUID
			or GetTickCount() - _C.nFightEndTick > 5000 then
				-- 新的一轮战斗开始
				_C.nFightBeginTick = GetTickCount()
				_C.nFightUUID = _C.nFightBeginTick
				FireUIEvent('MY_FIGHT_HINT', true)
			end
		end
	else
		-- 退出战斗判定
		if _C.bFighting then
			_C.nFightEndTick, _C.bFighting = GetTickCount(), false
		elseif _C.nFightUUID and GetTickCount() - _C.nFightEndTick > 5000 then
			_C.nLastFightUUID, _C.nFightUUID = _C.nFightUUID, nil
			FireUIEvent('MY_FIGHT_HINT', false)
		end
	end
end
MY.BreatheCall(_C.OnFightStateChange)

-- 获取当前战斗时间
function MY.Game.GetFightTime(szFormat)
	local nTick = 0
	if MY.IsFighting() then -- 战斗状态
		nTick = GetTickCount() - _C.nFightBeginTick
	else  -- 脱战状态
		nTick = _C.nFightEndTick - _C.nFightBeginTick
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
MY.GetFightTime = MY.Game.GetFightTime

-- 获取当前战斗唯一标示符
function MY.GetFightUUID()
	return _C.nFightUUID
end

-- 获取上次战斗唯一标示符
function MY.GetLastFightUUID()
	return _C.nLastFightUUID
end

-- 获取自身是否处于逻辑战斗状态
-- (bool) MY.IsFighting()
function MY.IsFighting()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and MY.Game.IsInArena() and _C.bJJCStart then
		bFightState = true
	elseif not bFightState and MY.Game.IsInDungeon() then
		-- 在副本且附近队友进战且附近敌对NPC进战则判断处于战斗状态
		local bPlayerFighting, bNpcFighting
		for dwID, p in pairs(MY.Game.GetNearPlayer()) do
			if me.IsPlayerInMyParty(dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for dwID, p in pairs(MY.Game.GetNearNpc()) do
				if IsEnemy(me.dwID, dwID) and p.bFightState then
					bNpcFighting = true
					break
				end
			end
		end
		bFightState = bPlayerFighting and bNpcFighting
	end
	return bFightState
end
MY.RegisterEvent('LOADING_ENDING.MY-PLAYER', function() _C.bJJCStart = nil end)
MY.RegisterEvent('ARENA_START.MY-PLAYER', function() _C.bJJCStart = true end)

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
function MY.Game.GetTarget(object)
	if not object then
		object = GetClientPlayer()
	end
	if object then
		return object.GetTarget()
	else
		return TARGET.NO_TARGET, 0
	end
end
MY.GetTarget = MY.Game.GetTarget

-- 根据 dwType 类型和 dwID 设置目标
-- (void) MY.SetTarget([number dwType, ]number dwID)
-- dwType   -- *可选* 目标类型
-- dwID     -- 目标 ID
function MY.Game.SetTarget(dwType, dwID)
	-- check dwType
	if type(dwType) == 'userdata' then
		dwType, dwID = ( IsPlayer(dwType) and TARGET.PLAYER ) or TARGET.NPC, dwType.dwID
	elseif type(dwType) == 'string' then
		dwType, dwID = nil, dwType
	end
	-- conv if dwID is string
	if type(dwID) == 'string' then
		local tTarget = {}
		for _, szName in pairs(MY.String.Split(dwID:gsub('[%[%]]', ''), '|')) do
			tTarget[szName] = true
		end
		dwID = nil
		if not dwID and dwType ~= TARGET.PLAYER then
			for _, p in pairs(MY.GetNearNpc()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.NPC, p.dwID
					break
				end
			end
		end
		if not dwID and dwType ~= TARGET.NPC then
			for _, p in pairs(MY.GetNearPlayer()) do
				if tTarget[p.szName] then
					dwType, dwID = TARGET.PLAYER, p.dwID
					break
				end
			end
		end
	end
	if not dwType or dwType <= 0 then
		dwType, dwID = TARGET.NO_TARGET, 0
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	SetTarget(dwType, dwID)
end
MY.SetTarget = MY.Game.SetTarget

-- 设置/取消 临时目标
-- MY.Game.SetTempTarget(dwType, dwID)
-- MY.Game.ResumeTarget()
_C.pTempTarget = { TARGET.NO_TARGET, 0 }
function MY.Game.SetTempTarget(dwType, dwID)
	TargetPanel_SetOpenState(true)
	_C.pTempTarget = { GetClientPlayer().GetTarget() }
	MY.Game.SetTarget(dwType, dwID)
	TargetPanel_SetOpenState(false)
end
MY.SetTempTarget = MY.Game.SetTempTarget
function MY.Game.ResumeTarget()
	TargetPanel_SetOpenState(true)
	-- 当之前的目标不存在时，切到空目标
	if _C.pTempTarget[1] ~= TARGET.NO_TARGET and not MY.GetObject(unpack(_C.pTempTarget)) then
		_C.pTempTarget = { TARGET.NO_TARGET, 0 }
	end
	MY.Game.SetTarget(unpack(_C.pTempTarget))
	_C.pTempTarget = { TARGET.NO_TARGET, 0 }
	TargetPanel_SetOpenState(false)
end
MY.ResumeTarget = MY.Game.ResumeTarget

-- 临时设置目标为指定目标并执行函数
-- (void) MY.Game.WithTarget(dwType, dwID, callback)
_C.tWithTarget = {}
_C.lockWithTarget = false
function _C.WithTargetHandle()
	if _C.lockWithTarget or
	#_C.tWithTarget == 0 then
		return
	end

	_C.lockWithTarget = true
	local r = table.remove(_C.tWithTarget, 1)

	MY.Game.SetTempTarget(r.dwType, r.dwID)
	local status, err = pcall(r.callback)
	if not status then
		MY.Debug({err}, 'MY.Game.lua#WithTargetHandle', MY_DEBUG.ERROR)
	end
	MY.Game.ResumeTarget()

	_C.lockWithTarget = false
	_C.WithTargetHandle()
end
function MY.WithTarget(dwType, dwID, callback)
	-- 因为客户端多线程 所以加上资源锁 防止设置临时目标冲突
	table.insert(_C.tWithTarget, {
		dwType   = dwType  ,
		dwID     = dwID    ,
		callback = callback,
	})
	_C.WithTargetHandle()
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
function MY.Game.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
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
MY.GetFaceAngel = MY.Game.GetFaceAngel

-- 装备名为szName的装备
-- (void) MY.Equip(szName)
-- szName  装备名称
function MY.Game.Equip(szName)
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
function MY.Game.GetBuff(KObject, dwID, nLevel, dwSkillSrcID)
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
		if not KObject.GetBuffByOwner then
			return MY.Debug({'KObject do not have a function named GetBuffByOwner.'}, 'MY.Game.GetBuff', MY_DEBUG.ERROR)
		end
		for k, v in pairs(tBuff) do
			local KBuff = KObject.GetBuffByOwner(k, v, dwSkillSrcID)
			if KBuff then
				return KBuff
			end
		end
	else
		if not KObject.GetBuff then
			return MY.Debug({'KObject do not have a function named GetBuff.'}, 'MY.Game.GetBuff', MY_DEBUG.ERROR)
		end
		for k, v in pairs(tBuff) do
			local KBuff = KObject.GetBuff(k, v)
			if KBuff then
				return KBuff
			end
		end
	end
end
MY.GetBuff = MY.Game.GetBuff

-- 点到自己的buff
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
-- (mixed) MY.Game.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function MY.Game.IsInvincible(KObject)
	KObject = KObject or GetClientPlayer()
	if not KObject then
		return nil
	elseif MY.Game.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end
MY.IsInvincible = MY.Game.IsInvincible

_C.tPlayerSkills = {}   -- 玩家技能列表[缓存]   -- 技能名反查ID
_C.tSkillCache = {}     -- 技能列表缓存         -- 技能ID查技能名称图标
-- 通过技能名称获取技能对象
-- (table) MY.GetSkillByName(szName)
function MY.Game.GetSkillByName(szName)
	if table.getn(_C.tPlayerSkills)==0 then
		for i = 1, g_tTable.Skill:GetRowCount() do
			local tLine = g_tTable.Skill:GetRow(i)
			if tLine~=nil and tLine.dwIconID~=nil and tLine.fSortOrder~=nil and tLine.szName~=nil and tLine.dwIconID~=13 and ( (not _C.tPlayerSkills[tLine.szName]) or tLine.fSortOrder>_C.tPlayerSkills[tLine.szName].fSortOrder) then
				_C.tPlayerSkills[tLine.szName] = tLine
			end
		end
	end
	return _C.tPlayerSkills[szName]
end

-- 判断技能名称是否有效
-- (bool) MY.IsValidSkill(szName)
function MY.Game.IsValidSkill(szName)
	if MY.Game.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) MY.CanUseSkill(number dwSkillID[, dwLevel])
function MY.Game.CanUseSkill(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == 'string' then if MY.IsValidSkill(dwSkillID) then dwSkillID = MY.Game.GetSkillByName(dwSkillID).dwSkillID else return false end end
	local me, box = GetClientPlayer(), _C.hBox
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

-- 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）
-- (string, number) MY.Game.GetSkillName(number dwSkillID[, number dwLevel])
function MY.GetSkillName(dwSkillID, dwLevel)
	if not _C.tSkillCache[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (StringFindW(tLine.szDesc, '_') == nil  or StringFindW(tLine.szDesc, '<') ~= nil)
		then
			_C.tSkillCache[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = 'SKILL#' .. dwSkillID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			_C.tSkillCache[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(_C.tSkillCache[dwSkillID])
end

-- 登出游戏
-- (void) MY.Logout(bCompletely)
-- bCompletely 为true返回登陆页 为false返回角色页 默认为false
function MY.Game.Logout(bCompletely)
	if bCompletely then
		ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
	else
		ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
	end
end
MY.Logout = MY.Game.Logout

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) MY.GetChannelSkillFrame(number dwSkillID)
function MY.GetChannelSkillFrame(dwSkillID)
	local t = _C.tSkillEx[dwSkillID]
	if t then
		return t.nChannelFrame
	end
end
-- Load skill extend data
_C.tSkillEx = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/skill_ex.jx3dat') or {}

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
-- (bool) MY.Game.IsInParty()
function MY.Game.IsInParty()
	local me = GetClientPlayer()
	return me and me.IsInParty()
end
MY.IsInParty = MY.Game.IsInParty

-- 判断当前地图是不是竞技场
-- (bool) MY.Game.IsInArena()
function MY.Game.IsInArena()
	local me = GetClientPlayer()
	return me and (
		me.GetScene().bIsArenaMap or -- JJC
		me.GetMapID() == 173 or      -- 齐物阁
		me.GetMapID() == 181         -- 狼影殿
	)
end
MY.IsInArena = MY.Game.IsInArena

-- 判断当前地图是不是战场
-- (bool) MY.Game.IsInBattleField()
function MY.Game.IsInBattleField()
	local me = GetClientPlayer()
	return me and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD and not MY.Game.IsInArena()
end
MY.IsInBattleField = MY.Game.IsInBattleField

-- 判断当前地图是不是副本
-- (bool) MY.Game.IsInDungeon(bool bRaid)
function MY.Game.IsInDungeon(bRaid)
	local me = GetClientPlayer()
	return me and MY.IsDungeonMap(me.GetMapID(), bRaid)
end
MY.IsInDungeon = MY.Game.IsInDungeon

-- 判断地图是不是PUBG
-- (bool) MY.Game.IsInPubg(dwMapID)
do
local PUBG_MAP = {}
function MY.Game.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = Table_IsTreasureBattleFieldMap(dwMapID)
	end
	return PUBG_MAP[dwMapID]
end
MY.IsPubgMap = MY.Game.IsPubgMap
end

-- 判断当前地图是不是PUBG
-- (bool) MY.Game.IsInPubg()
function MY.Game.IsInPubg()
	local me = GetClientPlayer()
	return me and MY.IsPubgMap(me.GetMapID())
end
MY.IsInPubg = MY.Game.IsInPubg

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
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		MY.Sysmsg({_L('restore team leader: %s', tTeamInfo.szLeader)})
	end
	if dwMark  ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		MY.Sysmsg({_L('restore team marker: %s', tTeamInfo.szMark)})
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
