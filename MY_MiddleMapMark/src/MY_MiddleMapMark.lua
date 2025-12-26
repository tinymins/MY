--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 中地图标记 记录所有NPC和Doodad位置 提供搜索
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_MiddleMapMark/MY_MiddleMapMark'
local PLUGIN_NAME = 'MY_MiddleMapMark'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_MiddleMapMark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_MiddleMapMark', { ['*'] = false, exp = true })
X.RegisterRestriction('MY_MiddleMapMark.MapRestriction', { ['*'] = true })
--------------------------------------------------------------------------------
X.CreateDataRoot(X.PATH_TYPE.GLOBAL)
local l_szKeyword, l_dwMapID, l_nMapIndex, l_renderTime = '', nil, nil, 0
local DB = X.SQLiteConnect(_L['MY_MiddleMapMark'], {'cache/npc_doodad_rec.v5.db', X.PATH_TYPE.GLOBAL})
if not DB then
	return X.OutputSystemMessage(_L['MY_MiddleMapMark'], _L['Cannot connect to database!!!'], X.CONSTANT.MSG_THEME.ERROR)
end
X.SQLiteExecute(DB, [[
	CREATE TABLE IF NOT EXISTS NpcInfo (
		templateid INTEGER NOT NULL,
		poskey INTEGER NOT NULL,
		mapid INTEGER NOT NULL,
		x INTEGER NOT NULL,
		y INTEGER NOT NULL,
		z INTEGER NOT NULL,
		name NVARCHAR(20) NOT NULL,
		title NVARCHAR(20) NOT NULL,
		level INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(templateid, poskey)
	)
]])
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS mmm_name_idx ON NpcInfo(name, mapid)')
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS mmm_title_idx ON NpcInfo(title, mapid)')
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS mmm_template_idx ON NpcInfo(templateid, mapid)')
local DBN_W  = X.SQLitePrepare(DB, 'REPLACE INTO NpcInfo (templateid, poskey, mapid, x, y, z, name, title, level, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DBN_DM  = X.SQLitePrepare(DB, 'DELETE FROM NpcInfo WHERE mapid = ?')
local DBN_RI = X.SQLitePrepare(DB, 'SELECT templateid, poskey, mapid, x, y, z, name, title, level FROM NpcInfo WHERE templateid = ?')
local DBN_RN = X.SQLitePrepare(DB, 'SELECT templateid, poskey, mapid, x, y, z, name, title, level FROM NpcInfo WHERE name LIKE ? OR title LIKE ?')
local DBN_RNM = X.SQLitePrepare(DB, 'SELECT templateid, poskey, mapid, x, y, z, name, title, level FROM NpcInfo WHERE (name LIKE ? AND mapid = ?) OR (title LIKE ? AND mapid = ?)')
X.SQLiteExecute(DB, [[
	CREATE TABLE IF NOT EXISTS DoodadInfo (
		templateid INTEGER NOT NULL,
		poskey INTEGER NOT NULL,
		mapid INTEGER NOT NULL,
		x INTEGER NOT NULL,
		y INTEGER NOT NULL,
		z INTEGER NOT NULL,
		name NVARCHAR(20) NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY (templateid, poskey)
	)
]])
X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS mmm_name_idx ON DoodadInfo(name, mapid)')
local DBD_W  = X.SQLitePrepare(DB, 'REPLACE INTO DoodadInfo (templateid, poskey, mapid, x, y, z, name, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
local DBD_DM  = X.SQLitePrepare(DB, 'DELETE FROM DoodadInfo WHERE mapid = ?')
local DBD_RI = X.SQLitePrepare(DB, 'SELECT templateid, poskey, mapid, x, y, z, name FROM DoodadInfo WHERE templateid = ?')
local DBD_RN = X.SQLitePrepare(DB, 'SELECT templateid, poskey, mapid, x, y, z, name FROM DoodadInfo WHERE name LIKE ?')
local DBD_RNM = X.SQLitePrepare(DB, 'SELECT templateid, poskey, mapid, x, y, z, name FROM DoodadInfo WHERE name LIKE ? AND mapid = ?')

local O = X.CreateUserSettingsModule('MY_MiddleMapMark', _L['General'], {
	bMiddleMapSearch = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_MiddleMapMark'],
		szDescription = X.MakeCaption({
			_L['Show search in middle map panel'],
		}),
		szRestriction = 'MY_MiddleMapMark',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

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

function D.Migration()
	local DB_V1_ROOT = 'cache/NPC_DOODAD_REC/'
	local DB_V1_PATH = X.FormatPath({DB_V1_ROOT, X.PATH_TYPE.DATA})
	local DB_V2_PATH = X.FormatPath({'cache/npc_doodad_rec.v2.db', X.PATH_TYPE.GLOBAL})
	local DB_V3_PATH = X.FormatPath({'cache/npc_doodad_rec.v3.db', X.PATH_TYPE.GLOBAL})
	local DB_V4_PATH = X.FormatPath({'cache/npc_doodad_rec.v4.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V1_PATH) and not IsLocalFileExist(DB_V2_PATH) and not IsLocalFileExist(DB_V3_PATH) and not IsLocalFileExist(DB_V4_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			-- 转移V1旧版数据
			if IsLocalFileExist(DB_V1_PATH) then
				X.SQLiteBeginTransaction(DB)
				for _, dwMapID in ipairs(GetMapList()) do
					local data = X.LoadLUAData({DB_V1_ROOT .. dwMapID .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
					if type(data) == 'string' then
						data = X.DecodeJSON(data)
					end
					if data then
						for _, p in ipairs(data.Npc) do
							X.SQLitePrepareExecute(
								DBN_W,
								p.dwTemplateID,
								GeneNpcInfoPosKey(dwMapID, p.nX, p.nY),
								dwMapID,
								p.nX,
								p.nY,
								-1,
								AnsiToUTF8(p.szName),
								AnsiToUTF8(p.szTitle),
								p.nLevel,
								''
							)
						end
						for _, p in ipairs(data.Doodad) do
							X.SQLitePrepareExecute(
								DBD_W,
								p.dwTemplateID,
								GeneDoodadInfoPosKey(dwMapID, p.nX, p.nY),
								dwMapID,
								p.nX,
								p.nY,
								-1,
								AnsiToUTF8(p.szName),
								''
							)
						end
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage('MY_MiddleMapMark', 'MiddleMapMark cache trans from file to sqlite finished!', X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
					end
				end
				X.SQLiteEndTransaction(DB)
				CPath.DelDir(X.FormatPath({DB_V1_ROOT, X.PATH_TYPE.DATA}))
			end
			-- 转移V2旧版数据
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					X.SQLiteBeginTransaction(DB)
					local aNpcInfo = X.SQLiteGetAll(DB_V2, 'SELECT * FROM NpcInfo WHERE templateid IS NOT NULL')
					if aNpcInfo then
						for _, rec in ipairs(aNpcInfo) do
							if rec.templateid and rec.poskey then
								X.SQLitePrepareExecute(
									DBN_W,
									rec.templateid,
									rec.poskey,
									rec.mapid or -1,
									rec.x or -1,
									rec.y or -1,
									-1,
									rec.name or '',
									rec.title or '',
									rec.level or -1,
									''
								)
							end
						end
					end
					local aDoodadInfo = X.SQLiteGetAll(DB_V2, 'SELECT * FROM DoodadInfo WHERE templateid IS NOT NULL')
					if aDoodadInfo then
						for _, rec in ipairs(aDoodadInfo) do
							if rec.templateid and rec.poskey then
								X.SQLitePrepareExecute(
									DBD_W,
									rec.templateid,
									rec.poskey,
									rec.mapid or -1,
									rec.x or -1,
									rec.y or -1,
									-1,
									rec.name or '',
									''
								)
							end
						end
					end
					X.SQLiteEndTransaction(DB)
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V3旧版数据
			if IsLocalFileExist(DB_V3_PATH) then
				local DB_V3 = SQLite3_Open(DB_V3_PATH)
				if DB_V3 then
					X.SQLiteBeginTransaction(DB)
					local aNpcInfo = X.SQLiteGetAll(DB_V3, 'SELECT * FROM NpcInfo WHERE templateid IS NOT NULL')
					if aNpcInfo then
						for _, rec in ipairs(aNpcInfo) do
							if rec.templateid and rec.poskey then
								X.SQLitePrepareExecute(
									DBN_W,
									rec.templateid,
									rec.poskey,
									rec.mapid or -1,
									rec.x or -1,
									rec.y or -1,
									-1,
									rec.name or '',
									rec.title or '',
									rec.level or -1,
									''
								)
							end
						end
					end
					local aDoodadInfo = X.SQLiteGetAll(DB_V3, 'SELECT * FROM DoodadInfo WHERE templateid IS NOT NULL')
					if aDoodadInfo then
						for _, rec in ipairs(aDoodadInfo) do
							if rec.templateid and rec.poskey then
								X.SQLitePrepareExecute(
									DBD_W,
									rec.templateid,
									rec.poskey,
									rec.mapid or -1,
									rec.x or -1,
									rec.y or -1,
									-1,
									rec.name or '',
									''
								)
							end
						end
					end
					X.SQLiteEndTransaction(DB)
					DB_V3:Release()
				end
				CPath.Move(DB_V3_PATH, DB_V3_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V4旧版数据
			if IsLocalFileExist(DB_V4_PATH) then
				local DB_V4 = SQLite3_Open(DB_V4_PATH)
				if DB_V4 then
					X.SQLiteBeginTransaction(DB)
					local aNpcInfo = X.SQLiteGetAll(DB_V4, 'SELECT * FROM NpcInfo WHERE templateid IS NOT NULL')
					if aNpcInfo then
						for _, rec in ipairs(aNpcInfo) do
							if rec.templateid and rec.poskey then
								X.SQLitePrepareExecute(
									DBN_W,
									rec.templateid,
									rec.poskey,
									rec.mapid or -1,
									rec.x or -1,
									rec.y or -1,
									-1,
									rec.name or '',
									rec.title or '',
									rec.level or -1,
									''
								)
							end
						end
					end
					local aDoodadInfo = X.SQLiteGetAll(DB_V4, 'SELECT * FROM DoodadInfo WHERE templateid IS NOT NULL')
					if aDoodadInfo then
						for _, rec in ipairs(aDoodadInfo) do
							if rec.templateid and rec.poskey then
								X.SQLitePrepareExecute(
									DBD_W,
									rec.templateid,
									rec.poskey,
									rec.mapid or -1,
									rec.x or -1,
									rec.y or -1,
									-1,
									rec.name or '',
									''
								)
							end
						end
					end
					X.SQLiteEndTransaction(DB)
					DB_V4:Release()
				end
				CPath.Move(DB_V4_PATH, DB_V4_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			X.Alert(_L['Migrate succeed!'])
		end)
end
---------------------------------------------------------------
-- 数据采集
---------------------------------------------------------------
local l_npc = {}
local l_doodad = {}
local l_tempMap = false
local MAX_RENDER_INTERVAL = X.ENVIRONMENT.GAME_FPS * 5
local function FlushDB()
	if X.IsEmpty(l_npc) and X.IsEmpty(l_doodad) then
		return
	end
	X.SQLiteBeginTransaction(DB)

	for i, p in pairs(l_npc) do
		if not p.temp then
			X.SQLitePrepareExecute(
				DBN_W,
				p.templateid,
				p.poskey,
				p.mapid,
				p.x,
				p.y,
				p.z,
				AnsiToUTF8(p.name),
				AnsiToUTF8(p.title),
				p.level,
				''
			)
		end
	end
	l_npc = {}

	for i, p in pairs(l_doodad) do
		if not p.temp then
			X.SQLitePrepareExecute(
				DBD_W,
				p.templateid,
				p.poskey,
				p.mapid,
				p.x,
				p.y,
				p.z,
				AnsiToUTF8(p.name),
				''
			)
		end
	end
	l_doodad = {}

	X.SQLiteEndTransaction(DB)
end
local function onLoadingEnding()
	l_tempMap = X.IsInCompetitionMap() or false
	if l_tempMap then
		local dwMapID = X.GetClientPlayer().GetMapID()
		X.SQLitePrepareExecute(DBN_DM, dwMapID)
		X.SQLitePrepareExecute(DBD_DM, dwMapID)
	end
	FlushDB()
end
X.RegisterEvent('LOADING_ENDING', 'MY_MiddleMapMark', onLoadingEnding)

local function Flush()
	FlushDB()
end
X.RegisterFlush('MY_MiddleMapMark_Save', Flush)

local function OnExit()
	DB:Release()
end
X.RegisterExit('MY_MiddleMapMark_Save', OnExit)

local function Rerender()
	D.Search(true)
end

local function AutomaticRerender()
	if X.IsRestricted('MY_MiddleMapMark') or not O.bMiddleMapSearch then
		return
	end
	if GetTime() - l_renderTime > MAX_RENDER_INTERVAL then
		Rerender()
	elseif not X.DelayCall('MY_MiddleMapMark_Refresh') then
		X.DelayCall('MY_MiddleMapMark_Refresh', MAX_RENDER_INTERVAL, Rerender)
	end
end

local NpcTpl = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MY_MiddleMapMark/data/npc/{$lang}.jx3dat')
local DoodadTpl = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MY_MiddleMapMark/data/doodad/{$lang}.jx3dat')
local function OnNpcEnterScene()
	if l_tempMap and X.IsRestricted('MY_MiddleMapMark.MapRestriction') then
		return
	end
	local npc = X.GetNpc(arg0)
	local player = X.GetClientPlayer()
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
	local szName = X.GetNpcName(npc.dwID, { eShowID = 'never' })
	if not szName or X.TrimString(szName) == '' then
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
		z = npc.nZ,
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
X.RegisterEvent('NPC_ENTER_SCENE', 'MY_MIDDLEMAPMARK', OnNpcEnterScene)

local REC_DOODAD_TYPES = {
	[X.CONSTANT.DOODAD_KIND.INVALID     ] = false,
	[X.CONSTANT.DOODAD_KIND.NORMAL      ] = true , -- 普通的Doodad,有Tip,不能操作
	[X.CONSTANT.DOODAD_KIND.CORPSE      ] = false, -- 尸体
	[X.CONSTANT.DOODAD_KIND.QUEST       ] = true , -- 任务相关的Doodad
	[X.CONSTANT.DOODAD_KIND.READ        ] = true , -- 可以看的Doodad
	[X.CONSTANT.DOODAD_KIND.DIALOG      ] = true , -- 可以对话的Doodad
	[X.CONSTANT.DOODAD_KIND.ACCEPT_QUEST] = true , -- 可以接任务的Doodad,本质上上面3个类型是一样的,只是图标不同而已
	[X.CONSTANT.DOODAD_KIND.TREASURE    ] = false, -- 宝箱
	[X.CONSTANT.DOODAD_KIND.ORNAMENT    ] = false, -- 装饰物,不能操作
	[X.CONSTANT.DOODAD_KIND.CRAFT_TARGET] = true , -- 生活技能的采集物
	[X.CONSTANT.DOODAD_KIND.CLIENT_ONLY ] = false, -- 客户端用
	[X.CONSTANT.DOODAD_KIND.CHAIR       ] = true , -- 可以坐的Doodad
	[X.CONSTANT.DOODAD_KIND.GUIDE       ] = false, -- 路标
	[X.CONSTANT.DOODAD_KIND.DOOR        ] = false, -- 门之类有动态障碍的Doodad
	[X.CONSTANT.DOODAD_KIND.NPCDROP     ] = false, -- 使用NPC掉落模式的doodad
	[X.CONSTANT.DOODAD_KIND.SPRINT      ] = false, -- 轻功落脚点
}
local function OnDoodadEnterScene()
	if l_tempMap and X.IsRestricted('MY_MiddleMapMark.MapRestriction') then
		return
	end
	local doodad = X.GetDoodad(arg0)
	local player = X.GetClientPlayer()
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
	local szName = X.GetDoodadName(doodad.dwID, { eShowID = 'never' })
	if not szName or X.TrimString(szName) == '' then
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
		z = doodad.nZ,
		name = szName,
		mapid = dwMapID,
		poskey = dwPosKey,
		templateid = doodad.dwTemplateID,
	}
	-- redraw ui
	AutomaticRerender()
end
X.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_MIDDLEMAPMARK', OnDoodadEnterScene)

function D.SearchNpc(szText, dwMapID)
	local aInfos
	local szSearch = AnsiToUTF8('%' .. szText .. '%')
	if dwMapID then
		aInfos = X.SQLitePrepareGetAll(
			DBN_RNM,
			szSearch,
			dwMapID,
			szSearch,
			dwMapID
		)
	else
		aInfos = X.SQLitePrepareGetAll(
			DBN_RN,
			szSearch,
			szSearch
		)
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
		and (szText == '' or X.StringFindW(info.name, szText) or X.StringFindW(info.title, szText)) then
			table.insert(aInfos, 1, info)
		end
	end
	return aInfos
end

function D.SearchDoodad(szText, dwMapID)
	local aInfos
	local szSearch = AnsiToUTF8('%' .. szText .. '%')
	if dwMapID then
		aInfos = X.SQLitePrepareGetAll(DBD_RNM, szSearch, dwMapID)
	else
		aInfos = X.SQLitePrepareGetAll(DBD_RN, szSearch)
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
		and (szText == '' or X.StringFindW(info.name, szText)) then
			table.insert(aInfos, 1, info)
		end
	end
	return aInfos
end

---------------------------------------------------------------
-- 中地图HOOK
---------------------------------------------------------------
-- HOOK MAP SWITCH
function D.ShowMap()
	D.Search(true)
end

function D.UpdateCurrentMap()
	D.Search(true)
end

-- HOOK OnEditChanged
function D.OnEditChanged()
	if this:GetName() == 'Edit_Search' then
		X.DelayCall('MY_MiddleMapMark__EditChanged', 500, D.Search)
	end
end

-- HOOK OnMouseEnter
function D.OnMouseEnter()
	if this:GetName() == 'Edit_Search' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(
			GetFormatText(_L['MY middle map mark'], nil, 255, 255, 0)
				.. X.CONSTANT.XML_LINE_BREAKER
				.. GetFormatText(_L['Type to search, use comma to split.'], nil, 255, 255, 192),
			w,
			{x - 10, y, w, h},
			X.UI.TIP_POSITION.TOP_BOTTOM
		)
	end
end

-- HOOK OnMouseLeave
function D.OnMouseLeave()
	if this:GetName() == 'Edit_Search' then
		HideTip()
	end
end

function D.HookEdit()
	local edit = Station.Lookup('Topmost1/MiddleMap/Wnd_Tool/Edit_Search')
	if edit then
		HookTableFunc(edit, 'OnEditChanged', D.OnEditChanged, { bAfterOrigin = true })
	end
	D.Search(true)
end
X.RegisterFrameCreate('MiddleMap', 'MY_MiddleMapMark', D.HookEdit)

function D.Hook()
	if X.IsRestricted('MY_MiddleMapMark') or not O.bMiddleMapSearch then
		return
	end
	D.HookEdit()
	HookTableFunc(MiddleMap, 'ShowMap', D.ShowMap, { bAfterOrigin = true })
	HookTableFunc(MiddleMap, 'UpdateCurrentMap', D.UpdateCurrentMap, { bAfterOrigin = true })
	HookTableFunc(MiddleMap, 'OnEditChanged', D.OnEditChanged, { bAfterOrigin = true })
	HookTableFunc(MiddleMap, 'OnMouseEnter', D.OnMouseEnter, { bAfterOrigin = true })
	HookTableFunc(MiddleMap, 'OnMouseLeave', D.OnMouseLeave, { bAfterOrigin = true })
end
X.RegisterInit('MY_MiddleMapMark', D.Hook)

function D.Unhook()
	local h = Station.Lookup('Topmost1/MiddleMap', 'Handle_Inner/Handle_MY_MMM')
	if h then
		h:GetParent():RemoveItem(h)
	end
	UnhookTableFunc(MiddleMap, 'ShowMap', D.ShowMap)
	UnhookTableFunc(MiddleMap, 'UpdateCurrentMap', D.UpdateCurrentMap)
	UnhookTableFunc(MiddleMap, 'OnEditChanged', D.OnEditChanged)
	UnhookTableFunc(MiddleMap, 'OnMouseEnter', D.OnMouseEnter)
	UnhookTableFunc(MiddleMap, 'OnMouseLeave', D.OnMouseLeave)
end
X.RegisterReload('MY_MiddleMapMark', D.Unhook)

X.RegisterEvent('MY_RESTRICTION', function()
	if arg0 and arg0 ~= 'MY_MiddleMapMark' then
		return
	end
	D.Unhook()
	D.Hook()
end)

function D.GetEditSearch()
	return Station.Lookup('Topmost1/MiddleMap/Wnd_NormalMap/Wnd_Tool/Edit_Search')
		or Station.Lookup('Topmost1/MiddleMap/Wnd_Tool/Edit_Search')
end

-- start search
local MAX_DISPLAY_COUNT = 1000
local function OnMMMItemMouseEnter()
	local me = X.GetClientPlayer()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local szTip = (this.decoded and this.name or UTF8ToAnsi(this.name))
		.. (this.level and this.level > 0 and (' lv.' .. this.level) or '')
		.. (this.title and this.title ~= '' and ('\n<' .. (this.decoded and this.title or UTF8ToAnsi(this.title)) .. '>') or '')
	if this.type == 'Doodad' then
		local dwRecipeID = me and X.GetDoodadBookRecipeID(this.templateid)
		if dwRecipeID then
			local dwBookID, dwSegmentID = X.RecipeToSegmentID(dwRecipeID)
			if dwBookID and dwSegmentID then
				if me.IsBookMemorized(dwBookID, dwSegmentID) then
					szTip = szTip .. '\n' .. _L['[Read]']
				else
					szTip = szTip .. '\n' .. _L['[Not read]']
				end
			end
		end
	end
	if IsCtrlKeyDown() then
		if this.templateid then
			szTip = szTip .. '\n' .. this.type .. ' Template ID: ' .. this.templateid
		end
		if this.x and this.y then
			szTip = szTip .. '\n' .. 'Pos: ' .. this.x .. ', ' .. this.y
			if this.z then
				szTip = szTip .. ', ' .. this.z
			end
		end
	end
	OutputTip(GetFormatText(szTip, 136), 450, {x, y, w, h}, ALW.TOP_BOTTOM)
end
local function OnMMMItemMouseLeave()
	HideTip()
end
function D.Search(bForce)
	local frame = Station.Lookup('Topmost1/MiddleMap')
	local player = X.GetClientPlayer()
	if not player or not frame or not frame:IsVisible() then
		return
	end
	local edit = D.GetEditSearch()
	if not edit then
		return
	end
	local szKeyword = edit:GetText()
	local dwMapID = MiddleMap.dwMapID or player.GetMapID()
	local nMapIndex = MiddleMap.nIndex
	if not bForce and l_dwMapID == dwMapID and l_nMapIndex == nMapIndex and l_szKeyword == szKeyword then
		return
	end
	l_renderTime = GetTime()
	l_dwMapID, l_nMapIndex, l_szKeyword = dwMapID, nMapIndex, szKeyword

	local hInner = frame:Lookup('', 'Handle_Inner')
		or frame:Lookup('', 'Handle_Border/Handle_Map/Handle_Inner')
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
		for _, szSearch in ipairs(X.SplitString(szKeyword, ',')) do
			szSearch = X.TrimString(szSearch)
			if szSearch ~= '' then
				aKeywords[i] = szSearch
				i = i + 1
			end
		end
	end
	local nX, nY, item

	for i, szSearch in ipairs(aKeywords) do
		infos = D.SearchNpc(szSearch, dwMapID)
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
					item.x = info.x
					item.y = info.y
					item.z = info.z
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
		infos = D.SearchDoodad(szSearch, dwMapID)
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
					item.x = info.x
					item.y = info.y
					item.z = info.z
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
local PS = { nPriority = 4.1, szRestriction = 'MY_MiddleMapMark' }
function PS.OnPanelActive(wnd)
	D.Migration()

	local ui = X.UI(wnd)
	local nX, nY = 0, 0
	local nW, nH = ui:Size()

	local list, muProgress
	local function UpdateList(szText)
		if X.IsEmpty(szText) then
			list:ListBox('clear')
			for i, s in ipairs(_L['MY_MiddleMapMark TIPS']) do
				list:ListBox('insert', { id = 'TIP' .. i, text = s, r = 255, g = 255, b = 0 })
			end
		else
			local nMaxDisp = 500
			local nDisp = 0
			local nCount = 0
			local tNames = {}
			local infos, szName, szTitle
			list:ListBox('clear')

			infos = D.SearchNpc(szText)
			nCount = nCount + #infos
			for _, info in ipairs(infos) do
				szName  = info.decoded and info.name  or UTF8ToAnsi(info.name)
				szTitle = info.decoded and info.title or UTF8ToAnsi(info.title)
				if not tNames[info.mapid .. szName] then
					list:ListBox('insert', {
						text = '[' .. Table_GetMapName(info.mapid) .. '] ' .. szName
							.. ((szTitle and #szTitle > 0 and '<' .. szTitle .. '>') or ''),
						data = { szName  = szName, dwMapID = info.mapid },
					})
					nDisp = nDisp + 1
					if nDisp >= nMaxDisp then
						return
					end
					tNames[info.mapid .. szName] = true
				end
			end

			infos = D.SearchDoodad(szText)
			nCount = nCount + #infos
			for _, info in ipairs(infos) do
				szName = info.decoded and info.name or UTF8ToAnsi(info.name)
				if not tNames[info.mapid .. szName] then
					list:ListBox('insert', {
						text = '[' .. Table_GetMapName(info.mapid) .. '] ' .. szName,
						data = { szName  = szName, dwMapID = info.mapid },
					})
					nDisp = nDisp + 1
					if nDisp >= nMaxDisp then
						return
					end
					tNames[info.mapid .. szName] = true
				end
			end
		end
	end

	ui:Append('WndEditBox', {
		name = 'WndEdit_Search',
		x = nX, y = nY,
		w = nW - 25, h = 25,
		onChange = function(szText)
			UpdateList(szText)
		end,
	})
	ui:Append('WndButton', {
		name = 'WndButton_Settings',
		x = nX + nW - 25, y = nY, w = 25, h = 25,
		buttonStyle = 'OPTION',
		menu = function()
			return {
				{
					szOption = _L['Show search in middle map panel'],
					bCheck = true, bChecked = O.bMiddleMapSearch,
					fnAction = function()
						O.bMiddleMapSearch = not O.bMiddleMapSearch
						D.Unhook()
						D.Hook()
					end,
				},
				{
					szOption = _L['Clear current map data'],
					fnAction = function()
						local dwMapID = X.GetClientPlayer().GetMapID()
						X.Confirm(_L('Current map (%s) npc and doodad record will be deleted, are you sure?', X.GetMapName(dwMapID) or dwMapID), function()
							X.SQLitePrepareExecute(DBN_DM, dwMapID)
							X.SQLitePrepareExecute(DBD_DM, dwMapID)
							Rerender()
						end)
					end,
				},
			}
		end,
	})
	nY = nY + 25

	muProgress = ui:Append('Image', {
		name = 'Image_Progress',
		x = nX, y = nY,
		w = nW, h = 4,
		image = 'ui/Image/UICommon/RaidTotal.UITex|45',
	})
	nY = nY + 4

	list = ui:Append('WndListBox', {
		name = 'WndListBox_1',
		x = nX, y = nY,
		w = nW, h = nH - nY,
		listBox = {
			{
				'onhover',
				function(id, text, data)
					if X.IsString(id) and id:sub(1, 3) == 'TIP' then
						return false
					end
				end,
			},
			{
				'onlclick',
				function(id, text, data, selected)
					if X.IsString(id) and id:sub(1, 3) == 'TIP' then
						return false
					end
					OpenMiddleMap(data.dwMapID, 0)
					X.UI(D.GetEditSearch()):Text(X.EscapeString(data.szName))
					Station.SetFocusWindow('Topmost1/MiddleMap')
					if not selected then -- avoid unselect
						return false
					end
				end,
			},
		},
	})

	UpdateList('')
end

function PS.OnPanelResize(wnd)
	local ui = X.UI(wnd)
	local nX, nY = ui:Pos()
	local nW, nH = ui:Size()

	ui:Children('#WndEdit_Search'):Width(nW - 25)
	ui:Children('#WndButton_Settings'):Left(nX + nW - 25)
	ui:Children('#Image_Progress'):Width(nW)
	ui:Children('#WndListBox_1'):Size(nW, nH - ui:Children('#Image_Progress'):Top() - 4)
end

X.Panel.Register(_L['General'], 'MY_MiddleMapMark', _L['MY_MiddleMapMark'], 'ui/Image/MiddleMap/MapWindow2.UITex|4', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
