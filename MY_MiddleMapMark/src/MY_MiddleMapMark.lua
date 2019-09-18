--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 中地图标记 记录所有NPC和Doodad位置 提供搜索
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
local PLUGIN_NAME = 'MY_MiddleMapMark'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_MiddleMapMark'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------
LIB.CreateDataRoot(PATH_TYPE.GLOBAL)
local l_szKeyword, l_dwMapID, l_nMapIndex, l_renderTime = '', nil, nil, 0
local DB = LIB.ConnectDatabase(_L['MY_MiddleMapMark'], {'cache/npc_doodad_rec.v2.db', PATH_TYPE.GLOBAL})
if not DB then
	return LIB.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L['MY_MiddleMapMark'])
end
DB:Execute('CREATE TABLE IF NOT EXISTS NpcInfo (templateid INTEGER, poskey INTEGER, mapid INTEGER, x INTEGER, y INTEGER, name VARCHAR(20) NOT NULL, title VARCHAR(20) NOT NULL, level INTEGER, PRIMARY KEY(templateid, poskey))')
DB:Execute('CREATE INDEX IF NOT EXISTS mmm_name_idx ON NpcInfo(name, mapid)')
DB:Execute('CREATE INDEX IF NOT EXISTS mmm_title_idx ON NpcInfo(title, mapid)')
DB:Execute('CREATE INDEX IF NOT EXISTS mmm_template_idx ON NpcInfo(templateid, mapid)')
local DBN_W  = DB:Prepare('REPLACE INTO NpcInfo (templateid, poskey, mapid, x, y, name, title, level) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
local DBN_DM  = DB:Prepare('DELETE FROM NpcInfo WHERE mapid = ?')
local DBN_RI = DB:Prepare('SELECT templateid, poskey, mapid, x, y, name, title, level FROM NpcInfo WHERE templateid = ?')
local DBN_RN = DB:Prepare('SELECT templateid, poskey, mapid, x, y, name, title, level FROM NpcInfo WHERE name LIKE ? OR title LIKE ?')
local DBN_RNM = DB:Prepare('SELECT templateid, poskey, mapid, x, y, name, title, level FROM NpcInfo WHERE (name LIKE ? AND mapid = ?) OR (title LIKE ? AND mapid = ?)')
DB:Execute('CREATE TABLE IF NOT EXISTS DoodadInfo (templateid INTEGER, poskey INTEGER, mapid INTEGER, x INTEGER, y INTEGER, name VARCHAR(20) NOT NULL, PRIMARY KEY (templateid, poskey))')
DB:Execute('CREATE INDEX IF NOT EXISTS mmm_name_idx ON DoodadInfo(name, mapid)')
local DBD_W  = DB:Prepare('REPLACE INTO DoodadInfo (templateid, poskey, mapid, x, y, name) VALUES (?, ?, ?, ?, ?, ?)')
local DBD_DM  = DB:Prepare('DELETE FROM DoodadInfo WHERE mapid = ?')
local DBD_RI = DB:Prepare('SELECT templateid, poskey, mapid, x, y, name FROM DoodadInfo WHERE templateid = ?')
local DBD_RN = DB:Prepare('SELECT templateid, poskey, mapid, x, y, name FROM DoodadInfo WHERE name LIKE ?')
local DBD_RNM = DB:Prepare('SELECT templateid, poskey, mapid, x, y, name FROM DoodadInfo WHERE name LIKE ? AND mapid = ?')

MY_MiddleMapMark = {}
do
---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
local L16 = 0x10000
local L32 = 0x100000000
-- NPC 最大独立距离8尺（低于该距离的两个实体视为同一个）
-- DOODAD 最大独立距离2尺（低于该距离的两个实体视为同一个）
-- 不可随意更改，更改需要清空数据库重新建立key索引
local NPC_MAX_DISTINCT_DISTANCE = 8 * 64
local DOODAD_MAX_DISTINCT_DISTANCE = 2 * 64
-- 47 - 32 位 mapid
-- 31 - 16 位 x
-- 15 -  0 位 y
local function GeneNpcInfoPosKey(mapid, x, y)
	return mapid * L32 + math.floor(x / NPC_MAX_DISTINCT_DISTANCE) * L16 + math.floor(y / NPC_MAX_DISTINCT_DISTANCE)
end
local function GeneDoodadInfoPosKey(mapid, x, y)
	return mapid * L32 + math.floor(x / DOODAD_MAX_DISTINCT_DISTANCE) * L16 + math.floor(y / DOODAD_MAX_DISTINCT_DISTANCE)
end

local SZ_CACHE_PATH = 'cache/NPC_DOODAD_REC/'
if IsLocalFileExist(LIB.FormatPath({SZ_CACHE_PATH, PATH_TYPE.DATA})) then
	DB:Execute('BEGIN TRANSACTION')
	for _, dwMapID in ipairs(GetMapList()) do
		local data = LIB.LoadLUAData({SZ_CACHE_PATH .. dwMapID .. '.${lang}.jx3dat', PATH_TYPE.DATA})
		if type(data) == 'string' then
			data = LIB.JsonDecode(data)
		end
		if data then
			for _, p in ipairs(data.Npc) do
				DBN_W:ClearBindings()
				DBN_W:BindAll(p.dwTemplateID, GeneNpcInfoPosKey(dwMapID, p.nX, p.nY), dwMapID, p.nX, p.nY, AnsiToUTF8(p.szName), AnsiToUTF8(p.szTitle), p.nLevel)
				DBN_W:Execute()
			end
			for _, p in ipairs(data.Doodad) do
				DBD_W:ClearBindings()
				DBD_W:BindAll(p.dwTemplateID, GeneDoodadInfoPosKey(dwMapID, p.nX, p.nY), dwMapID, p.nX, p.nY, AnsiToUTF8(p.szName))
				DBD_W:Execute()
			end
			--[[#DEBUG BEGIN]]
			LIB.Debug('MiddleMapMark cache trans from file to sqlite finished!', 'MY_MiddleMapMark', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
	end
	DB:Execute('END TRANSACTION')
	CPath.DelDir(LIB.FormatPath({SZ_CACHE_PATH, PATH_TYPE.DATA}))
end

---------------------------------------------------------------
-- 数据采集
---------------------------------------------------------------
local l_npc = {}
local l_doodad = {}
local l_tempMap = false
local MAX_RENDER_INTERVAL = GLOBAL.GAME_FPS * 5
local function FlushDB()
	if IsEmpty(l_npc) and IsEmpty(l_doodad) then
		return
	end
	DB:Execute('BEGIN TRANSACTION')

	for i, p in pairs(l_npc) do
		if not p.temp then
			DBN_W:ClearBindings()
			DBN_W:BindAll(p.templateid, p.poskey, p.mapid, p.x, p.y, AnsiToUTF8(p.name), AnsiToUTF8(p.title), p.level)
			DBN_W:Execute()
		end
	end
	l_npc = {}

	for i, p in pairs(l_doodad) do
		if not p.temp then
			DBD_W:ClearBindings()
			DBD_W:BindAll(p.templateid, p.poskey, p.mapid, p.x, p.y, AnsiToUTF8(p.name))
			DBD_W:Execute()
		end
	end
	l_doodad = {}

	DB:Execute('END TRANSACTION')
end
local function onLoadingEnding()
	l_tempMap = LIB.IsInZombieMap() or LIB.IsInPubg() or LIB.IsInArena() or LIB.IsInBattleField() or false
	if l_tempMap then
		local dwMapID = GetClientPlayer().GetMapID()
		DBN_DM:ClearBindings()
		DBN_DM:BindAll(dwMapID)
		DBN_DM:Execute()
		DBD_DM:ClearBindings()
		DBD_DM:BindAll(dwMapID)
		DBD_DM:Execute()
	end
	FlushDB()
end
LIB.RegisterEvent('LOADING_ENDING.MY_MiddleMapMark', onLoadingEnding)

local function OnExit()
	FlushDB()
	DB:Release()
end
LIB.RegisterExit('MY_MiddleMapMark_Save', OnExit)

local function Rerender()
	MY_MiddleMapMark.Search(l_szKeyword)
end

local function AutomaticRerender()
	if GetTime() - l_renderTime > MAX_RENDER_INTERVAL then
		Rerender()
	elseif not LIB.DelayCall('MY_MiddleMapMark_Refresh') then
		LIB.DelayCall('MY_MiddleMapMark_Refresh', MAX_RENDER_INTERVAL, Rerender)
	end
end

local NpcTpl = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_MiddleMapMark/data/npc/${lang}.jx3dat')
local DoodadTpl = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_MiddleMapMark/data/doodad/${lang}.jx3dat')
local function OnNpcEnterScene()
	if l_tempMap and LIB.IsShieldedVersion() then
		return
	end
	local npc = GetNpc(arg0)
	local player = GetClientPlayer()
	if not (npc and player) then
		return
	end
	-- avoid special npc
	if NpcTpl[npc.dwTemplateID] then
		return
	end
	-- avoid player's pets
	if npc.dwEmployer and npc.dwEmployer ~= 0 then
		return
	end
	-- avoid full number named npc
	local szName = LIB.GetObjectName(npc, 'never')
	if not szName or LIB.TrimString(szName) == '' then
		return
	end
	-- switch map
	local dwMapID = player.GetMapID()
	local dwPosKey = GeneNpcInfoPosKey(dwMapID, npc.nX, npc.nY)

	-- add rec
	l_npc[npc.dwTemplateID .. ',' .. dwPosKey] = {
		decoded = true,
		temp = l_tempMap,
		x = npc.nX,
		y = npc.nY,
		mapid = dwMapID,
		level = npc.nLevel,
		name  = szName,
		title = npc.szTitle,
		poskey = dwPosKey,
		templateid = npc.dwTemplateID,
	}
	-- redraw ui
	AutomaticRerender()
end
LIB.RegisterEvent('NPC_ENTER_SCENE.MY_MIDDLEMAPMARK', OnNpcEnterScene)

local REC_DOODAD_TYPES = {
	[DOODAD_KIND.INVALID     ] = false,
	[DOODAD_KIND.NORMAL      ] = true , -- 普通的Doodad,有Tip,不能操作
	[DOODAD_KIND.CORPSE      ] = false, -- 尸体
	[DOODAD_KIND.QUEST       ] = true , -- 任务相关的Doodad
	[DOODAD_KIND.READ        ] = true , -- 可以看的Doodad
	[DOODAD_KIND.DIALOG      ] = true , -- 可以对话的Doodad
	[DOODAD_KIND.ACCEPT_QUEST] = true , -- 可以接任务的Doodad,本质上上面3个类型是一样的,只是图标不同而已
	[DOODAD_KIND.TREASURE    ] = false, -- 宝箱
	[DOODAD_KIND.ORNAMENT    ] = false, -- 装饰物,不能操作
	[DOODAD_KIND.CRAFT_TARGET] = true , -- 生活技能的采集物
	[DOODAD_KIND.CLIENT_ONLY ] = false, -- 客户端用
	[DOODAD_KIND.CHAIR       ] = true , -- 可以坐的Doodad
	[DOODAD_KIND.GUIDE       ] = false, -- 路标
	[DOODAD_KIND.DOOR        ] = false, -- 门之类有动态障碍的Doodad
	[DOODAD_KIND.NPCDROP     ] = false, -- 使用NPC掉落模式的doodad
	[DOODAD_KIND.SPRINT      ] = false, -- 轻功落脚点
}
local function OnDoodadEnterScene()
	if l_tempMap and LIB.IsShieldedVersion() then
		return
	end
	local doodad = GetDoodad(arg0)
	local player = GetClientPlayer()
	if not (doodad and player) then
		return
	end
	if not REC_DOODAD_TYPES[doodad.nKind] then
		return
	end
	-- avoid special doodad
	if DoodadTpl[doodad.dwTemplateID] then
		return
	end
	-- avoid full number named doodad
	local szName = LIB.GetObjectName(doodad, 'never')
	if not szName or LIB.TrimString(szName) == '' then
		return
	end
	-- switch map
	local dwMapID = player.GetMapID()
	local dwPosKey = GeneDoodadInfoPosKey(dwMapID, doodad.nX, doodad.nY)

	-- add rec
	l_doodad[doodad.dwTemplateID .. ',' .. dwPosKey] = {
		decoded = true,
		temp = l_tempMap,
		x = doodad.nX,
		y = doodad.nY,
		name = szName,
		mapid = dwMapID,
		poskey = dwPosKey,
		templateid = doodad.dwTemplateID,
	}
	-- redraw ui
	AutomaticRerender()
end
LIB.RegisterEvent('DOODAD_ENTER_SCENE.MY_MIDDLEMAPMARK', OnDoodadEnterScene)

function MY_MiddleMapMark.SearchNpc(szText, dwMapID)
	local aInfos
	local szSearch = AnsiToUTF8('%' .. szText .. '%')
	if dwMapID then
		DBN_RNM:ClearBindings()
		DBN_RNM:BindAll(szSearch, dwMapID, szSearch, dwMapID)
		aInfos = DBN_RNM:GetAll()
	else
		DBN_RN:ClearBindings()
		DBN_RN:BindAll(szSearch, szSearch)
		aInfos = DBN_RN:GetAll()
	end
	for i = #aInfos, 1, -1 do
		local p = aInfos[i]
		if (not dwMapID or p.mapid == dwMapID)
		and l_npc[p.templateid .. ',' .. p.poskey] then
			table.remove(aInfos, i)
		end
	end
	for _, info in pairs(l_npc) do
		if (not dwMapID or info.mapid == dwMapID)
		and (wstring.find(info.name, szText) or wstring.find(info.title, szText)) then
			table.insert(aInfos, 1, info)
		end
	end
	return aInfos
end

function MY_MiddleMapMark.SearchDoodad(szText, dwMapID)
	local aInfos
	local szSearch = AnsiToUTF8('%' .. szText .. '%')
	if dwMapID then
		DBD_RNM:ClearBindings()
		DBD_RNM:BindAll(szSearch, dwMapID)
		aInfos = DBD_RNM:GetAll()
	else
		DBD_RN:ClearBindings()
		DBD_RN:BindAll(szSearch)
		aInfos = DBD_RN:GetAll()
	end
	for i = #aInfos, 1, -1 do
		local p = aInfos[i]
		if (not dwMapID or p.mapid == dwMapID)
		and l_doodad[p.templateid .. ',' .. p.poskey] then
			table.remove(aInfos, i)
		end
	end
	for _, info in pairs(l_doodad) do
		if (not dwMapID or info.mapid == dwMapID)
		and (wstring.find(info.name, szText)) then
			table.insert(aInfos, 1, info)
		end
	end
	return aInfos
end
end

---------------------------------------------------------------
-- 中地图HOOK
---------------------------------------------------------------
-- HOOK MAP SWITCH
if MiddleMap._MY_MMM_ShowMap == nil then
	MiddleMap._MY_MMM_ShowMap = MiddleMap.ShowMap or false
end
MiddleMap.ShowMap = function(...)
	if MiddleMap._MY_MMM_ShowMap then
		MiddleMap._MY_MMM_ShowMap(...)
	end
	MY_MiddleMapMark.Search(l_szKeyword)
end

if MiddleMap._MY_MMM_UpdateCurrentMap == nil then
	MiddleMap._MY_MMM_UpdateCurrentMap = MiddleMap.UpdateCurrentMap or false
end
MiddleMap.UpdateCurrentMap = function(...)
	if MiddleMap._MY_MMM_UpdateCurrentMap then
		MiddleMap._MY_MMM_UpdateCurrentMap(...)
	end
	MY_MiddleMapMark.Search(l_szKeyword)
end

-- HOOK OnEditChanged
if MiddleMap._MY_MMM_OnEditChanged == nil then
	MiddleMap._MY_MMM_OnEditChanged = MiddleMap.OnEditChanged or false
end
MiddleMap.OnEditChanged = function()
	if this:GetName() == 'Edit_Search' then
		MY_MiddleMapMark.Search(this:GetText())
	end
	if MiddleMap._MY_MMM_OnEditChanged then
		MiddleMap._MY_MMM_OnEditChanged()
	end
end

-- HOOK OnMouseEnter
if MiddleMap._MY_MMM_OnMouseEnter == nil then
	MiddleMap._MY_MMM_OnMouseEnter = MiddleMap.OnMouseEnter or false
end
MiddleMap.OnMouseEnter = function()
	if this:GetName() == 'Edit_Search' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(
			GetFormatText(_L['Type to search, use comma to split.'], nil, 255, 255, 0),
			w,
			{x - 10, y, w, h},
			UI.TIP_POSITION.TOP_BOTTOM
		)
	end
	if MiddleMap._MY_MMM_OnMouseEnter then
		MiddleMap._MY_MMM_OnMouseEnter()
	end
end

-- HOOK OnMouseLeave
if MiddleMap._MY_MMM_OnMouseLeave == nil then
	MiddleMap._MY_MMM_OnMouseLeave = MiddleMap.OnMouseLeave or false
end
MiddleMap.OnMouseLeave = function()
	if this:GetName() == 'Edit_Search' then
		HideTip()
	end
	if MiddleMap._MY_MMM_OnMouseLeave then
		MiddleMap._MY_MMM_OnMouseLeave()
	end
end

local function onReload()
	for _, szKey in ipairs({
		'OnEditChanged',
		'OnMouseEnter',
		'OnMouseLeave',
		'UpdateCurrentMap',
	}) do
		if MiddleMap['_MY_MMM_' .. szKey] then
			MiddleMap[szKey] = MiddleMap['_MY_MMM_' .. szKey]
			MiddleMap['_MY_MMM_' .. szKey] = nil
		end
	end
end
LIB.RegisterReload('MY_MiddleMapMark', onReload)

-- start search
local MAX_DISPLAY_COUNT = 1000
local function OnMMMItemMouseEnter()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local szTip = (this.decoded and this.name or UTF8ToAnsi(this.name))
		.. (this.level and this.level > 0 and (' lv.' .. this.level) or '')
		.. (this.title and this.title ~= '' and ('\n<' .. (this.decoded and this.title or UTF8ToAnsi(this.title)) .. '>') or '')
	if IsCtrlKeyDown() then
		szTip = szTip .. (this.templateid and ('\n' .. this.type .. ' Template ID: ' .. this.templateid) or '')
	end
	OutputTip(GetFormatText(szTip, 136), 450, {x, y, w, h}, ALW.TOP_BOTTOM)
end
local function OnMMMItemMouseLeave()
	HideTip()
end
function MY_MiddleMapMark.Search(szKeyword)
	local frame = Station.Lookup('Topmost1/MiddleMap')
	local player = GetClientPlayer()
	if not player or not frame or not frame:IsVisible() then
		return
	end

	local dwMapID = MiddleMap.dwMapID or player.GetMapID()
	local nMapIndex = MiddleMap.nIndex
	if l_dwMapID == dwMapID and l_nMapIndex == nMapIndex and l_szKeyword == szKeyword then
		return
	end
	l_renderTime = GetTime()
	l_dwMapID, l_nMapIndex, l_szKeyword = dwMapID, nMapIndex, szKeyword

	local hInner = frame:Lookup('', 'Handle_Inner')
	local nW, nH = hInner:GetSize()
	local hMMM = hInner:Lookup('Handle_MY_MMM')
	if not hMMM then
		hInner:AppendItemFromString('<handle>firstpostype=0 name="Handle_MY_MMM" w=' .. nW .. ' h=' .. nH .. '</handle>')
		hMMM = hInner:Lookup('Handle_MY_MMM')
		hInner:FormatAllItemPos()
	end
	local nCount = 0
	local nItemCount = hMMM:GetItemCount()

	local infos
	local aKeywords = {}
	do
		local i = 1
		for _, szSearch in ipairs(LIB.SplitString(szKeyword, ',')) do
			szSearch = LIB.TrimString(szSearch)
			if szSearch ~= '' then
				aKeywords[i] = szSearch
				i = i + 1
			end
		end
	end
	local nX, nY, item

	for i, szSearch in ipairs(aKeywords) do
		infos = MY_MiddleMapMark.SearchNpc(szSearch, dwMapID)
		for _, info in ipairs(infos) do
			if nCount < MAX_DISPLAY_COUNT then
				nX, nY = MiddleMap.LPosToHPos(info.x, info.y, 13, 13)
				if nX > 0 and nY > 0 and nX < nW and nY < nH then
					nCount = nCount + 1
					if nCount > nItemCount then
						hMMM:AppendItemFromString('<image>w=13 h=13 path="ui/Image/Minimap/MapMark.UITex" frame=95 eventid=784</image>')
						nItemCount = nItemCount + 1
					end
					item = hMMM:Lookup(nCount - 1)
					item:Show()
					item:SetRelPos(nX, nY)
					item.decoded = info.decoded
					item.type = 'Npc'
					item.name = info.name
					item.title = info.title
					item.level = info.level
					item.templateid = info.templateid
					item.OnItemMouseEnter = OnMMMItemMouseEnter
					item.OnItemMouseLeave = OnMMMItemMouseLeave
				end
			end
		end
	end

	for i, szSearch in ipairs(aKeywords) do
		infos = MY_MiddleMapMark.SearchDoodad(szSearch, dwMapID)
		for _, info in ipairs(infos) do
			if nCount < MAX_DISPLAY_COUNT then
				nX, nY = MiddleMap.LPosToHPos(info.x, info.y, 13, 13)
				if nX > 0 and nY > 0 and nX < nW and nY < nH then
					nCount = nCount + 1
					if nCount > nItemCount then
						hMMM:AppendItemFromString('<image>w=13 h=13 path="ui/Image/Minimap/MapMark.UITex" frame=95 eventid=784</image>')
						nItemCount = nItemCount + 1
					end
					item = hMMM:Lookup(nCount - 1)
					item:Show()
					item:SetRelPos(nX, nY)
					item.decoded = info.decoded
					item.type = 'Doodad'
					item.name = info.name
					item.title = info.title
					item.level = info.level
					item.templateid = info.templateid
					item.OnItemMouseEnter = OnMMMItemMouseEnter
					item.OnItemMouseLeave = OnMMMItemMouseLeave
				end
			end
		end
	end

	for i = nCount, nItemCount - 1 do
		hMMM:Lookup(i):Hide()
	end
	hMMM:FormatAllItemPos()
end

---------------------------------------------------------------
-- 主面板搜索
---------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local x, y = ui:Pos()
	local w, h = ui:Size()

	local list = ui:Append('WndListBox', 'WndListBox_1')
	  :Pos(20, 35)
	  :Size(w - 32, h - 50)
	  :ListBox('onlclick', function(hItem, text, id, data, selected)
	  	OpenMiddleMap(data.dwMapID, 0)
	  	UI('Topmost1/MiddleMap/Wnd_NormalMap/Wnd_Tool/Edit_Search'):Text(LIB.EscapeString(data.szName))
	  	Station.SetFocusWindow('Topmost1/MiddleMap')
	  	if not selected then -- avoid unselect
	  		return false
	  	end
	  end)

	local muProgress = ui:Append('Image', 'Image_Progress')
	  :Pos(20, 31)
	  :Size(w - 30, 4)
	  :Image('ui/Image/UICommon/RaidTotal.UITex|45')

	ui:Append('WndEditBox', {
		name = 'WndEdit_Search',
		x = 18, y = 10,
		w = w - 26, h = 25,
		onchange = function(szText)
			if not (szText and #szText > 0) then
				return
			end
			local nMaxDisp = 500
			local nDisp = 0
			local nCount = 0
			local tNames = {}
			local infos, szName, szTitle
			list:ListBox('clear')

			infos = MY_MiddleMapMark.SearchNpc(szText)
			nCount = nCount + #infos
			for _, info in ipairs(infos) do
				szName  = info.decoded and info.name  or UTF8ToAnsi(info.name)
				szTitle = info.decoded and info.title or UTF8ToAnsi(info.title)
				if not tNames[info.mapid .. szName] then
					list:ListBox('insert', '[' .. Table_GetMapName(info.mapid) .. '] ' .. szName ..
					((szTitle and #szTitle > 0 and '<' .. szTitle .. '>') or ''), nil, {
						szName  = szName,
						dwMapID = info.mapid,
					})
					nDisp = nDisp + 1
					if nDisp >= nMaxDisp then
						return
					end
					tNames[info.mapid .. szName] = true
				end
			end

			infos = MY_MiddleMapMark.SearchDoodad(szText)
			nCount = nCount + #infos
			for _, info in ipairs(infos) do
				szName = info.decoded and info.name or UTF8ToAnsi(info.name)
				if not tNames[info.mapid .. szName] then
					list:ListBox('insert', '[' .. Table_GetMapName(info.mapid) .. '] ' .. szName, nil, {
						szName  = szName,
						dwMapID = info.mapid,
					})
					nDisp = nDisp + 1
					if nDisp >= nMaxDisp then
						return
					end
					tNames[info.mapid .. szName] = true
				end
			end
		end,
	})
end

function PS.OnPanelResize(wnd)
	local ui = UI(wnd)
	local x, y = ui:Pos()
	local w, h = ui:Size()

	ui:Children('#WndListBox_1'):Size(w - 32, h - 50)
	ui:Children('#Image_Progress'):Size(w - 30, 4)
	ui:Children('#WndEdit_Search'):Size(w - 26, 25)
end

LIB.RegisterPanel('MY_MiddleMapMark', _L['middle map mark'], _L['General'], 'ui/Image/MiddleMap/MapWindow2.UITex|4', PS)
