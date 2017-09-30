-----------------------------------------------
-- @Desc  : 中地图标记
--  记录所有NPC和Doodad位置 提供搜索和显示
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-12-04 11:51:31
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-02-08 17:59:40
-----------------------------------------------
MY.CreateDataRoot(MY_DATA_PATH.GLOBAL)
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_MiddleMapMark/lang/")
local l_szKeyword = ""
local SZ_DB_PATH = MY.FormatPath({"cache/npc_doodad_rec.db", MY_DATA_PATH.GLOBAL})
local DB = SQLite3_Open(SZ_DB_PATH)
if not DB then
	return MY.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L["MY_MiddleMapMark"])
end
DB:Execute("CREATE TABLE IF NOT EXISTS NpcInfo (templateid INTEGER, poskey INTEGER, mapid INTEGER, x INTEGER, y INTEGER, name VARCHAR(20) NOT NULL, title VARCHAR(20) NOT NULL, level INTEGER, PRIMARY KEY(templateid, poskey))")
DB:Execute("CREATE INDEX IF NOT EXISTS mmm_name_idx ON NpcInfo(name, mapid)")
DB:Execute("CREATE INDEX IF NOT EXISTS mmm_title_idx ON NpcInfo(title, mapid)")
DB:Execute("CREATE INDEX IF NOT EXISTS mmm_template_idx ON NpcInfo(templateid, mapid)")
local DBN_W  = DB:Prepare("REPLACE INTO NpcInfo (templateid, poskey, mapid, x, y, name, title, level) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
local DBN_RI = DB:Prepare("SELECT templateid, poskey, mapid, x, y, name, title, level FROM NpcInfo WHERE templateid = ?")
local DBN_RN = DB:Prepare("SELECT templateid, poskey, mapid, x, y, name, title, level FROM NpcInfo WHERE name LIKE ? OR title LIKE ?")
local DBN_RNM = DB:Prepare("SELECT templateid, poskey, mapid, x, y, name, title, level FROM NpcInfo WHERE (name LIKE ? AND mapid = ?) OR (title LIKE ? AND mapid = ?)")
DB:Execute("CREATE TABLE IF NOT EXISTS DoodadInfo (templateid INTEGER, poskey INTEGER, mapid INTEGER, x INTEGER, y INTEGER, name VARCHAR(20) NOT NULL, PRIMARY KEY (templateid, poskey))")
DB:Execute("CREATE INDEX IF NOT EXISTS mmm_name_idx ON DoodadInfo(name, mapid)")
local DBD_W  = DB:Prepare("REPLACE INTO DoodadInfo (templateid, poskey, mapid, x, y, name) VALUES (?, ?, ?, ?, ?, ?)")
local DBD_RI = DB:Prepare("SELECT templateid, poskey, mapid, x, y, name FROM DoodadInfo WHERE templateid = ?")
local DBD_RN = DB:Prepare("SELECT templateid, poskey, mapid, x, y, name FROM DoodadInfo WHERE name LIKE ?")
local DBD_RNM = DB:Prepare("SELECT templateid, poskey, mapid, x, y, name FROM DoodadInfo WHERE name LIKE ? AND mapid = ?")

MY_MiddleMapMark = {}
do
---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
local L16 = 0x10000
local L32 = 0x100000000
local MAX_DISTINCT_DISTANCE = 2 * 64 -- 最大独立距离2尺（低于该距离的两个实体视为同一个）-- 不可随意更改，更改需要清空数据库重新建立key索引
local function GeneInfoPosKey(mapid, x, y)
	-- 47 - 32 位 mapid
	-- 31 - 16 位 x
	-- 15 -  0 位 y
	return mapid * L32 + math.floor(x / MAX_DISTINCT_DISTANCE) * L16 + math.floor(y / MAX_DISTINCT_DISTANCE)
end

local SZ_CACHE_PATH = "cache/NPC_DOODAD_REC/"
if IsLocalFileExist(MY.FormatPath(SZ_CACHE_PATH)) then
	DB:Execute("BEGIN TRANSACTION")
	for _, dwMapID in ipairs(GetMapList()) do
		local data = MY.LoadLUAData(SZ_CACHE_PATH .. dwMapID .. ".$lang.jx3dat")
		if type(data) == 'string' then
			data = MY.JsonDecode(data)
		end
		if data then
			for _, p in ipairs(data.Npc) do
				DBN_W:ClearBindings()
				DBN_W:BindAll(p.dwTemplateID, GeneInfoPosKey(dwMapID, p.nX, p.nY), dwMapID, p.nX, p.nY, AnsiToUTF8(p.szName), AnsiToUTF8(p.szTitle), p.nLevel)
				DBN_W:Execute()
			end
			for _, p in ipairs(data.Doodad) do
				DBD_W:ClearBindings()
				DBD_W:BindAll(p.dwTemplateID, GeneInfoPosKey(dwMapID, p.nX, p.nY), dwMapID, p.nX, p.nY, AnsiToUTF8(p.szName))
				DBD_W:Execute()
			end
			MY.Debug({"MiddleMapMark cache trans from file to sqlite finished!"}, "MY_MiddleMapMark", MY_DEBUG.LOG)
		end
	end
	DB:Execute("END TRANSACTION")
	CPath.DelDir(MY.FormatPath(SZ_CACHE_PATH))
end

---------------------------------------------------------------
-- 数据采集
---------------------------------------------------------------
local l_npc = {}
local l_doodad = {}
local function PushDB()
	if empty(l_npc) and empty(l_doodad) then
		return
	end
	DB:Execute("BEGIN TRANSACTION")

	for i, p in pairs(l_npc) do
		DBN_W:ClearBindings()
		DBN_W:BindAll(p.templateid, p.poskey, p.mapid, p.x, p.y, AnsiToUTF8(p.name), AnsiToUTF8(p.title), p.level)
		DBN_W:Execute()
	end
	l_npc = {}

	for i, p in pairs(l_doodad) do
		DBD_W:ClearBindings()
		DBD_W:BindAll(p.templateid, p.poskey, p.mapid, p.x, p.y, AnsiToUTF8(p.name))
		DBD_W:Execute()
	end
	l_doodad = {}

	DB:Execute("END TRANSACTION")
end
MY.RegisterEvent('LOADING_ENDING.MY_MiddleMapMark', PushDB)

local function OnExit()
	PushDB()
	DB:Release()
end
MY.RegisterExit("MY_MiddleMapMark_Save", OnExit)

local NpcTpl = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "MY_MiddleMapMark/data/npc/$lang.jx3dat")
local DoodadTpl = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "MY_MiddleMapMark/data/doodad/$lang.jx3dat")
local m_nLastRedrawFrame = GetLogicFrameCount()
local MARK_RENDER_INTERVAL = GLOBAL.GAME_FPS * 5
local function OnNpcEnterScene()
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
	local szName = MY.GetObjectName(npc)
	if not szName or MY.String.Trim(szName) == '' then
		return
	end
	-- switch map
	local dwMapID = player.GetMapID()
	local dwPosKey = GeneInfoPosKey(dwMapID, npc.nX, npc.nY)

	-- add rec
	l_npc[npc.dwTemplateID .. "," .. dwPosKey] = {
		decoded = true,
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
	-- if GetLogicFrameCount() - m_nLastRedrawFrame > MARK_RENDER_INTERVAL then
	-- 	m_nLastRedrawFrame = GetLogicFrameCount()
	-- 	MY_MiddleMapMark.Search(_Cache.szKeyword)
	-- end
end
MY.RegisterEvent("NPC_ENTER_SCENE.MY_MIDDLEMAPMARK", OnNpcEnterScene)

local function OnDoodadEnterScene()
	local doodad = GetDoodad(arg0)
	local player = GetClientPlayer()
	if not (doodad and player) then
		return
	end
	if doodad.nKind == DOODAD_KIND.CORPSE then
		return
	end
	-- avoid special doodad
	if DoodadTpl[doodad.dwTemplateID] then
		return
	end
	-- avoid full number named doodad
	local szName = MY.GetObjectName(doodad)
	if not szName or MY.String.Trim(szName) == '' then
		return
	end
	-- switch map
	local dwMapID = player.GetMapID()
	local dwPosKey = GeneInfoPosKey(dwMapID, doodad.nX, doodad.nY)

	-- add rec
	l_doodad[doodad.dwTemplateID .. "," .. dwPosKey] = {
		decoded = true,
		x = doodad.nX,
		y = doodad.nY,
		name = szName,
		mapid = dwMapID,
		poskey = dwPosKey,
		templateid = doodad.dwTemplateID,
	}
	-- redraw ui
	-- if GetLogicFrameCount() - m_nLastRedrawFrame > MARK_RENDER_INTERVAL then
	-- 	m_nLastRedrawFrame = GetLogicFrameCount()
	-- 	MY_MiddleMapMark.Search(_Cache.szKeyword)
	-- end
end
MY.RegisterEvent("DOODAD_ENTER_SCENE.MY_MIDDLEMAPMARK", OnDoodadEnterScene)

function MY_MiddleMapMark.SearchNpc(szText, dwMapID)
	local aInfos
	local szSearch = AnsiToUTF8("%" .. szText .. "%")
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
		if l_npc[p.templateid .. "," .. p.poskey] then
			table.remove(aInfos, i)
		end
	end
	for _, info in pairs(l_npc) do
		if wstring.find(info.name, szText)
		or wstring.find(info.title, szText) then
			table.insert(aInfos, 1, info)
		end
	end
	return aInfos
end

function MY_MiddleMapMark.SearchDoodad(szText, dwMapID)
	local aInfos
	local szSearch = AnsiToUTF8("%" .. szText .. "%")
	if dwMapID then
		DBD_RNM:ClearBindings()
		DBD_RNM:BindAll(szSearch, dwMapID)
		return DBD_RNM:GetAll()
	else
		DBD_RN:ClearBindings()
		DBD_RN:BindAll(szSearch)
		return DBD_RN:GetAll()
	end
	for i = #aInfos, 1, -1 do
		local p = aInfos[i]
		if l_doodad[p.templateid .. "," .. p.poskey] then
			table.remove(aInfos, i)
		end
	end
	for _, info in pairs(l_doodad) do
		if wstring.find(info.name, szText) then
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
	-- for mapid changing
	local dwMapID = MiddleMap.dwMapID
	MY.DelayCall(function()
		if dwMapID ~= MiddleMap.dwMapID then
			MY_MiddleMapMark.Search(l_szKeyword)
		end
	end, 200)
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
			MY.Const.UI.Tip.POS_TOP
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

-- start search
local MAX_DISPLAY_COUNT = 1000
local function OnMMMItemMouseEnter()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local szTip = this.decoded and this.name or UTF8ToAnsi(this.name) ..
	((this.level and this.level > 0 and ' lv.' .. this.level) or '') ..
	((this.title and this.title ~= '' and '\n<' .. (this.decoded and this.title or UTF8ToAnsi(this.title)) .. '>') or '')
	if IsCtrlKeyDown() then
		szTip = szTip .. ((this.templateid and '\n' .. this.type .. ' Template ID: ' .. this.templateid))
	end
	OutputTip(GetFormatText(szTip, 136), 450, {x, y, w, h}, ALW.TOP_BOTTOM)
end
local function OnMMMItemMouseLeave()
	HideTip()
end
function MY_MiddleMapMark.Search(szKeyword)
	local frame = Station.Lookup("Topmost1/MiddleMap")
	local player = GetClientPlayer()
	if not player or not frame or not frame:IsVisible() then
		return
	end

	local hInner = frame:Lookup("", "Handle_Inner")
	local nW, nH = hInner:GetSize()
	local hMMM = hInner:Lookup("Handle_MY_MMM")
	if not hMMM then
		hInner:AppendItemFromString('<handle>firstpostype=0 name="Handle_MY_MMM" w=' .. nW .. ' h=' .. nH .. '</handle>')
		hMMM = hInner:Lookup("Handle_MY_MMM")
		hInner:FormatAllItemPos()
	end
	local nCount = 0
	local nItemCount = hMMM:GetItemCount()

	if l_szKeyword == szKeyword then
		return
	end
	l_szKeyword = szKeyword

	local infos
	local dwMapID = MiddleMap.dwMapID or player.GetMapID()
	local aKeywords = {}
	do
		local i = 1
		for _, szSearch in ipairs(MY.String.Split(szKeyword, ',')) do
			szSearch = MY.String.Trim(szSearch)
			if szSearch ~= "" then
				aKeywords[i] = szSearch
				i = i + 1
			end
		end
	end
	local nX, nY

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
					item.type = "Npc"
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
					item.type = "Doodad"
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
	local ui = MY.UI(wnd)
	local x, y = ui:pos()
	local w, h = ui:size()

	local list = ui:append("WndListBox", "WndListBox_1"):children('#WndListBox_1')
	  :pos(20, 35)
	  :size(w - 32, h - 50)
	  :listbox('onlclick', function(hItem, text, id, data, selected)
	  	OpenMiddleMap(data.dwMapID, 0)
	  	MY.UI('Topmost1/MiddleMap/Wnd_Tool/Edit_Search'):text(MY.String.PatternEscape(data.szName))
	  	Station.SetFocusWindow('Topmost1/MiddleMap')
	  	if not selected then -- avoid unselect
	  		return false
	  	end
	  end)

	local muProgress = ui:append("Image", "Image_Progress"):children('#Image_Progress')
	  :pos(20, 31)
	  :size(w - 30, 4)
	  :image('ui/Image/UICommon/RaidTotal.UITex|45')

	ui:append('WndEditBox', {
		name = 'WndEdit_Search',
		x = 18, y = 10,
		w = w - 26, h = 25,
		onchange = function(raw, szText)
			if not (szText and #szText > 0) then
				return
			end
			local nMaxDisp = 500
			local nDisp = 0
			local nCount = 0
			local tNames = {}
			local infos, szName, szTitle
			list:listbox('clear')

			infos = MY_MiddleMapMark.SearchNpc(szText)
			nCount = nCount + #infos
			for _, info in ipairs(infos) do
				szName  = info.decoded and info.name  or UTF8ToAnsi(info.name)
				szTitle = info.decoded and info.title or UTF8ToAnsi(info.title)
				if not tNames[info.mapid .. szName] then
					list:listbox('insert', '[' .. Table_GetMapName(info.mapid) .. '] ' .. szName ..
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
					list:listbox('insert', '[' .. Table_GetMapName(info.mapid) .. '] ' .. szName, nil, {
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
	local ui = MY.UI(wnd)
	local x, y = ui:pos()
	local w, h = ui:size()

	ui:children('#WndListBox_1'):size(w - 32, h - 50)
	ui:children('#Image_Progress'):size(w - 30, 4)
	ui:children('#WndEdit_Search'):size(w - 26, 25)
end

MY.RegisterPanel("MY_MiddleMapMark", _L["middle map mark"], _L['General'], "ui/Image/MiddleMap/MapWindow2.UITex|4", {255,255,0,200}, PS)
