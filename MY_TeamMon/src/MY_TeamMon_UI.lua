--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon', _L['MY_TeamMon'], 0x2013500) then
	return
end

local JsonEncode = LIB.JsonEncode
local MY_TM_TYPE          = MY_TeamMon.MY_TM_TYPE
local MY_TM_SCRUTINY_TYPE = MY_TeamMon.MY_TM_SCRUTINY_TYPE
local MY_TMUI_INIFILE     = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI.ini'
local MY_TMUI_ITEM_L      = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_ITEM_L.ini'
local MY_TMUI_TALK_L      = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_TALK_L.ini'
local MY_TMUI_ITEM_R      = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_ITEM_R.ini'
local MY_TMUI_TALK_R      = PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_TALK_R.ini'
local MY_TMUI_TYPE        = { 'BUFF', 'DEBUFF', 'CASTING', 'NPC', 'DOODAD', 'CIRCLE', 'TALK', 'CHAT' }
local MY_TMUI_SELECT_TYPE = MY_TMUI_TYPE[1]
local MY_TMUI_SELECT_MAP  = _L['All Data']
local MY_TMUI_TREE_EXPAND = { true } -- 默认第一项展开
local MY_TMUI_SEARCH
local MY_TMUI_DRAG          = false
local MY_TMUI_GLOBAL_SEARCH = false
local MY_TMUI_SEARCH_CACHE  = {}
local MY_TMUI_PANEL_ANCHOR  = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
local MY_TMUI_ANCHOR        = {}
local CHECKBOX_HEIGHT       = 30
local D = {}

local MY_TMUI_DOODAD_ICON = {
	[DOODAD_KIND.INVALID     ] = 1434, -- 无效
	[DOODAD_KIND.NORMAL      ] = 4956,
	[DOODAD_KIND.CORPSE      ] = 179 , -- 尸体
	[DOODAD_KIND.QUEST       ] = 1676, -- 任务
	[DOODAD_KIND.READ        ] = 243 , -- 阅读
	[DOODAD_KIND.DIALOG      ] = 3267, -- 对话
	[DOODAD_KIND.ACCEPT_QUEST] = 1678, -- 接受任务
	[DOODAD_KIND.TREASURE    ] = 3557, -- 宝箱
	[DOODAD_KIND.ORNAMENT    ] = 1395, -- 装饰物
	[DOODAD_KIND.CRAFT_TARGET] = 351 ,
	[DOODAD_KIND.CHAIR       ] = 3912, -- 椅子
	[DOODAD_KIND.CLIENT_ONLY ] = 240 ,
	[DOODAD_KIND.GUIDE       ] = 885 , -- 路牌
	[DOODAD_KIND.DOOR        ] = 1890, -- 门
	[DOODAD_KIND.NPCDROP     ] = 381 ,
}
setmetatable(MY_TMUI_DOODAD_ICON, { __index = function(me, key)
	LIB.Debug('unknown Kind' .. key)
	return 369
end })

local function OpenDragPanel(el)
	local frame = Wnd.OpenWindow(PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_DRAG.ini', 'MY_TeamMon_DRAG')
	local x, y = Cursor.GetPos()
	local w, h = el:GetSize()
	-- local x, y = el:GetAbsPos()
	frame.szName = this:GetName()
	frame:SetAbsPos(x, y)
	frame:StartMoving()
	frame.data = el.dat
	local szName = D.GetDataName(MY_TMUI_SELECT_TYPE, el.dat)
	frame:Lookup('', 'Text'):SetText(szName or el.dat.key)
	frame:SetSize(w, h)
	frame:Lookup('', 'Image'):SetSize(w, h)
	frame:Lookup('', 'Text'):SetSize(w, h)
	frame:Lookup('', ''):FormatAllItemPos()
	frame:BringToTop()
	MY_TMUI_DRAG = true
end

local function CloseDragPanel()
	local frame = Station.Lookup('Normal1/MY_TeamMon_DRAG')
	if frame then
		frame:EndMoving()
		Wnd.CloseWindow(frame)
		return frame.data, frame.szName
	end
end

local function DragPanelIsOpened()
	return Station.Lookup('Normal1/MY_TeamMon_DRAG') and Station.Lookup('Normal1/MY_TeamMon_DRAG'):IsVisible()
end

function D.OnFrameCreate()
	this:RegisterEvent('MY_TMUI_TEMP_UPDATE')
	this:RegisterEvent('MY_TMUI_TEMP_RELOAD')
	this:RegisterEvent('MY_TMUI_DATA_RELOAD')
	if type(Circle) ~= 'nil' then
		this:RegisterEvent('CIRCLE_RELOAD')
	end
	this:RegisterEvent('UI_SCALED')
	-- Esc
	LIB.RegisterEsc('MY_TeamMon', D.IsOpened, D.ClosePanel)
	-- CreateItemData
	this.hItemL = this:CreateItemData(MY_TMUI_ITEM_L, 'Handle_L')
	this.hTalkL = this:CreateItemData(MY_TMUI_TALK_L, 'Handle_TALK_L')
	this.hItemR = this:CreateItemData(MY_TMUI_ITEM_R, 'Handle_R')
	this.hTalkR = this:CreateItemData(MY_TMUI_TALK_R, 'Handle_TALK_R')
	-- tree
	this.hTreeT = this:CreateItemData(MY_TMUI_INIFILE, 'TreeLeaf_Node')
	this.hTreeC = this:CreateItemData(MY_TMUI_INIFILE, 'TreeLeaf_Content')
	this.hTreeH = this:Lookup('PageSet_Main/WndScroll_Tree', 'Handle_Tree_List')

	MY_TMUI_SEARCH = nil -- 重置搜索
	MY_TMUI_GLOBAL_SEARCH = false
	MY_TMUI_DRAG = false

	this.hPageSet = this:Lookup('PageSet_Main')
	local ui = UI(this)
	ui:text(_L['MY_TeamMon Plug-in'])
	for k, v in ipairs(MY_TMUI_TYPE) do
		local txt = this.hPageSet:Lookup('CheckBox_' .. v, 'Text_Page_' .. v)
		txt:SetText(_L[v])
		if v == 'CIRCLE' and type(Circle) == 'nil' then
			this.hPageSet:Lookup('CheckBox_' .. v):Hide()
			txt:SetFontColor(192, 192, 192)
		end
	end
	ui:append('WndButton3', {
		x = 835, y = 50, w = 150,
		text = g_tStrings.SYS_MENU,
		menu = function()
			local menu = {}
			insert(menu, { szOption = _L['Import Data (local)'], fnAction = function() D.OpenImportPanel() end }) -- 有传参 不要改
			local szLang = select(3, GetVersion())
			if szLang == 'zhcn' or szLang == 'zhtw' then
				insert(menu, { szOption = _L['Import Data (web)'], fnAction = MY_TeamMon_RR.OpenPanel })
			end
			insert(menu, { szOption = _L['Export Data'], fnAction = D.OpenExportPanel })
			return menu
		end,
	})
	-- debug
	if LIB.IsDebugClient(true) then
		ui:append('WndButton', { text = 'Reload', x = 10, y = 10, onclick = ReloadUIAddon })
		ui:append('WndButton', {
			name = 'On', text = 'Enable', x = 110, y = 10, enable = not MY_TeamMon.bEnable,
			onclick = function()
				MY_TeamMon.Enable(true, true)
				this:Enable(false)
				ui:children('#Off'):enable(true)
				MY_TeamMon.bEnable = true
			end,
		})
		ui:append('WndButton', {
			name = 'Off', text = 'Disable', x = 210, y = 10, enable = MY_TeamMon.bEnable,
			onclick = function()
				MY_TeamMon.Enable(false)
				this:Enable(false)
				ui:children('#On'):enable(true)
				MY_TeamMon.bEnable = false
			end,
		})
	end
	local uiPageSetMain = ui:children('#PageSet_Main')
	local uiSearch = uiPageSetMain:append('WndEditBox', {
		name = 'WndEdit_Search',
		x = 50, y = 38, w = 500, h = 25,
		text = '', placeholder = g_tStrings.SEARCH,
		onchange = function(szText)
			if LIB.TrimString(szText) == '' then
				MY_TMUI_SEARCH = nil
			else
				MY_TMUI_SEARCH = LIB.TrimString(szText)
			end
			FireUIEvent('MY_TMUI_TEMP_RELOAD')
			FireUIEvent('MY_TMUI_DATA_RELOAD')
		end,
		onblur = function()
			FireUIEvent('MY_TMUI_FREECACHE')
		end,
	}, true)
	uiPageSetMain:append('WndCheckBox', {
		x = 560, y = 38, checked = MY_TMUI_GLOBAL_SEARCH, text = _L['Global Search'],
		oncheck = function(bCheck)
			MY_TMUI_GLOBAL_SEARCH = bCheck
			FireUIEvent('MY_TMUI_TEMP_RELOAD')
			FireUIEvent('MY_TMUI_DATA_RELOAD')
		end,
	})
	uiPageSetMain:append('WndButton2', {
		name = 'NewFace', x = 720, y = 40, text = _L['New Face'],
		onclick = function()
			Circle.OpenAddPanel(nil, nil, MY_TMUI_SELECT_MAP ~= _L['All Data'] and LIB.GetMapInfo(MY_TMUI_SELECT_MAP))
		end,
	})
	uiPageSetMain:append('WndButton2', {
		x = 860, y = 40, text = _L['Clear Record'],
		onclick = function()
			LIB.Confirm(_L['Confirm?'], function()
				MY_TeamMon.ClearTemp(MY_TMUI_SELECT_TYPE)
			end)
		end,
	})
	D.UpdateAnchor(this)
	-- 首次加载
	for k, v in ipairs(MY_TMUI_TYPE) do
		if MY_TMUI_SELECT_TYPE == v then
			this.hPageSet:ActivePage(k - 1)
			break
		end
	end
end

function D.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'MY_TMUI_TEMP_UPDATE' then
		local szType = (MY_TMUI_SELECT_TYPE == 'CIRCLE' and arg0 == 'NPC') and 'CIRCLE' or arg0
		if szType ~= MY_TMUI_SELECT_TYPE then
			return
		end
		D.UpdateRList(arg1)
	elseif szEvent == 'MY_TMUI_TEMP_RELOAD' or szEvent == 'MY_TMUI_DATA_RELOAD' or szEvent == 'CIRCLE_RELOAD' then
		if szEvent == 'CIRCLE_RELOAD' and arg0 and MY_TMUI_SELECT_TYPE == 'CIRCLE' then
			MY_TMUI_SELECT_MAP = arg0
		end
		if szEvent == 'MY_TMUI_DATA_RELOAD' or szEvent == 'CIRCLE_RELOAD' then
			D.RefreshTable('L')
		elseif szEvent == 'MY_TMUI_TEMP_RELOAD' then
			D.RefreshTable('R')
		end
	end
end

function D.OnFrameDragEnd()
	MY_TMUI_ANCHOR = GetFrameAnchor(this)
end

function D.RefreshTable(szRefresh)
	if szRefresh == 'L' then
		D.UpdateLList()
		D.UpdateTree()
	elseif szRefresh == 'R' then
		D.UpdateRList()
	end
end
-- 用于刷新滚动条 来刷新内容
function D.RefreshScroll(szRefresh)
	local frame = D.GetFrame()
	local szName = format('WndScroll_%s_%s/Btn_%s_%s_ALL', MY_TMUI_SELECT_TYPE, szRefresh, MY_TMUI_SELECT_TYPE, szRefresh)
	local hWndScroll = frame.hPageSet:GetActivePage():Lookup(szName)
	LIB.ExecuteWithThis(hWndScroll, D.OnScrollBarPosChanged)
end

function D.ConflictCheck()
	if MY_TMUI_SELECT_TYPE == 'BUFF' or MY_TMUI_SELECT_TYPE == 'DEBUFF'	or MY_TMUI_SELECT_TYPE == 'CASTING' then
		local data = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
		local bMsg = false
		for k, v in pairs(data) do
			if k ~= -9 then
				local tTemp = {}
				for kk, vv in ipairs(v) do
					tTemp[vv.dwID] = tTemp[vv.dwID] or {}
					insert(tTemp[vv.dwID], vv)
				end
				for kk, vv in pairs(tTemp) do
					if #vv > 1 then
						for kkk, vvv in ipairs(vv) do
							if not vvv.bCheckLevel then
								bMsg = true
								LIB.Sysmsg(
									_L['Data Conflict'] .. ' ' .. _L[MY_TMUI_SELECT_TYPE] .. ' '
									.. D.GetMapName(k) .. ' :: ' .. vvv.dwID .. ' :: '
									.. (vvv.szName or D.GetDataName(MY_TMUI_SELECT_TYPE, vvv)), _L['MY_TeamMon'], 'MSG_SYS.ERROR')
								break
							end
						end
					end
				end
			end
		end
		if bMsg then
			LIB.Sysmsg(_L['Data Conflict Please check.'], _L['MY_TeamMon'], 'MSG_SYS.ERROR')
		end
	end
end

function D.OnActivePage()
	local nPage = this:GetActivePageIndex()
	MY_TMUI_SELECT_TYPE = MY_TMUI_TYPE[nPage + 1]
	if MY_TMUI_SELECT_TYPE ~= 'CIRCLE' then
		this:Lookup('NewFace'):Hide()
	else
		this:Lookup('NewFace'):Show()
	end
	D.RefreshTable('L')
	D.RefreshTable('R')
	FireUIEvent('MY_TMUI_SWITCH_PAGE')
	D.ConflictCheck()
	D.UpdateBG()
end

function D.UpdateBG()
	-- background
	local frame = D.GetFrame()
	local info = IsNumber(MY_TMUI_SELECT_MAP) and g_tTable.DungeonInfo:Search(MY_TMUI_SELECT_MAP)
	if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' and info and info.szDungeonImage2 then
		frame:Lookup('', 'Handle_BG'):Show()
		frame:Lookup('', 'Handle_BG/Image_BG'):FromUITex(info.szDungeonImage2, 0)
		frame:Lookup('', 'Handle_BG/Text_BgTitle'):SetText(info.szLayer3Name .. g_tStrings.STR_CONNECT .. info.szOtherName)
	else
		frame:Lookup('', 'Handle_BG'):Hide()
	end
end

function D.UpdateTree()
	local frame     = D.GetFrame()
	local nSelectID = MY_TMUI_SELECT_MAP
	local tDungeon  = MY_TeamMon.GetDungeon()
	local data      = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
	local dwMapID   = LIB.GetMapID()
	local tCount    = {}
	local hSelect
	local function GetCount(data)
		local nCount = data and #data or 0
		if MY_TMUI_SEARCH and data then
			nCount = 0
			for k, v in ipairs(data) do
				if D.CheckSearch(MY_TMUI_SELECT_TYPE, v) then
					nCount = nCount + 1
				end
			end
		end
		return nCount
	end
	local function Format(hTreeT, hTreeC, key, ...)
		local nCount = GetCount(data[key])
		local szName = D.GetMapName(key) or key
		local tFilter = { ... }
		for i = 1, select('#', ...) do
			szName = szName:gsub(tFilter[i], '') or szName
		end
		if key ~= _L['All Data'] then
			local szClassName = hTreeT.szName or hTreeT:Lookup(1):GetText()
			hTreeT.szName = szClassName
			tCount[hTreeT] = tCount[hTreeT] or 0
			tCount[hTreeT] = tCount[hTreeT] + nCount
			hTreeT:Lookup(1):SetText(szClassName .. ' ('.. tCount[hTreeT] .. ')')
		end
		hTreeC:Lookup(1):SetText(szName .. ' ('.. nCount .. ')')
		hTreeC.dwMapID = key
		hTreeC.nCount = nCount
		if nCount == 0 then
			hTreeC.col = { 168, 168, 168 }
			hTreeC:Lookup(1):SetFontColor(168, 168, 168)
		end
		if nSelectID == key then
			hTreeC:Lookup(0):Show()
			hTreeC:Lookup(1):SetFontColor(255, 255, 0)
			frame.hTreeH.hSelect = hTreeC
		end
		if dwMapID == key then
			hSelect = hTreeT
			hTreeC.col = { 168, 168, 255 }
			hTreeC:Lookup(1):SetFontColor(168, 168, 255)
		end
	end
	frame.hTreeH:Clear()
	local hTreeT = frame.hTreeH:AppendItemFromData(frame.hTreeT)
	hTreeT:Lookup(1):SetText(g_tStrings.STR_GUILD_ALL .. '/' .. g_tStrings.OTHER)
	-- 全部 / 通用
	local hTreeC = frame.hTreeH:AppendItemFromData(frame.hTreeC)
	Format(hTreeT, hTreeC, _L['All Data'])
	local hTreeC = frame.hTreeH:AppendItemFromData(frame.hTreeC)
	Format(hTreeT, hTreeC, -1)
	-- 其他
	for k, v in pairs(data) do
		if (k > 0 and not LIB.IsDungeonMap(k, true)) and (tonumber(k) and k > 0) then
			local hTreeC = frame.hTreeH:AppendItemFromData(frame.hTreeC)
			Format(hTreeT, hTreeC, k)
		end
	end
	for _, v in ipairs(tDungeon) do
		local hTreeT = frame.hTreeH:AppendItemFromData(frame.hTreeT)
		hTreeT:Lookup(1):SetText(v.szLayer3Name)
		for _, vv in ipairs(v.aList) do
			local hTreeC = frame.hTreeH:AppendItemFromData(frame.hTreeC)
			Format(hTreeT, hTreeC, vv, _L['Battle of Taiyuan'], _L['YongWangXingGong'], v.szLayer3Name)
		end
	end
	local hTreeT = frame.hTreeH:AppendItemFromData(frame.hTreeT)
	hTreeT:Lookup(1):SetText(_L['Recycle bin'])
	local hTreeC = frame.hTreeH:AppendItemFromData(frame.hTreeC)
	Format(hTreeT, hTreeC, -9)
	if hSelect then
		local hLocation = hSelect:Lookup('Image_Location')
		local w, h = hSelect:Lookup(1):GetTextExtent()
		hLocation:SetRelX(w)
		hLocation:Show()
		hSelect:FormatAllItemPos()
	end
	-- 还原列表展开
	local n = 1
	for i = 0, frame.hTreeH:GetItemCount() - 1 do
		local item = frame.hTreeH:Lookup(i)
		if item and item:GetIndent() == 0 then
			if MY_TMUI_TREE_EXPAND[n] then
				item:Expand()
			else
				item:Collapse()
			end
			if tCount[item] == 0 then
				item:Lookup(1):SetFontColor(222, 222, 222)
			end
			n = n + 1
		end
	end
	frame.hTreeH:FormatAllItemPos()
end

function D.OnItemLButtonDown()
	local szName = this:GetName()
	if IsCtrlKeyDown() then
		if szName == 'Handle_R' or szName == 'Handle_L' then
			local data = {}
			local szName
			if this:Lookup('Text') then
				if MY_TMUI_SELECT_TYPE == 'CASTING' then
					szName = '[' .. Table_GetSkillName(this.dat.dwID, this.dat.nLevel) .. ']'
					data = {
						type = 'skill',
						skill_id = this.dat.dwID,
						skill_level = this.dat.nLevel,
						text = szName
					}
				else
					szName = this:Lookup('Text'):GetText()
					data   = { type = 'text', text = szName }
				end
			elseif this:Lookup('Text_Name') and this:Lookup('Text_Content') then
				szName = this:Lookup('Text_Name'):GetText() .. g_tStrings.STR_COLON .. this:Lookup('Text_Content'):GetText()
				data   = { type = 'text', text = szName }
			end
			if szName then
				local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
				edit:InsertObj(szName, data)
				Station.SetFocusWindow(edit)
			end
		end
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Close' then
		D.ClosePanel()
	end
end

function D.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'TreeLeaf_Node' then
		if this:IsExpand() then
			this:Collapse()
		else
			this:Expand()
		end
		local handle = this:GetParent()
		MY_TMUI_TREE_EXPAND = {}
		for i = 0, handle:GetItemCount() - 1 do
			local item = handle:Lookup(i)
			if item and item:GetIndent() == 0 then
				insert(MY_TMUI_TREE_EXPAND, item:IsExpand())
			end
		end
		handle:FormatAllItemPos()
	elseif szName == 'TreeLeaf_Content' then
		-- 重新着色
		local handle = this:GetParent()
		if handle.hSelect and handle.hSelect:IsValid() then
			handle.hSelect:Lookup(0):Hide()
			local col = handle.hSelect.col and handle.hSelect.col or { 255, 255, 255 }
			handle.hSelect:Lookup(1):SetFontColor(unpack(col))
		end
		this:Lookup(0):Show()
		this:Lookup(1):SetFontColor(255, 255, 0)
		handle.hSelect = this
		-- 刷新数据
		MY_TMUI_SELECT_MAP = this.dwMapID
		D.UpdateLList()
		D.UpdateBG()
	elseif szName == 'Handle_L' then
		if MY_TMUI_DRAG or IsCtrlKeyDown() then
			return
		end
		if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
			Circle.OpenDataPanel(this.dat)
		else
			D.OpenSettingPanel(this.dat, MY_TMUI_SELECT_TYPE)
		end
	end
end

function D.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == 'TreeLeaf_Content' then
		local menu = {}
		local dwMapID = this.dwMapID
		if dwMapID ~= _L['All Data'] then
			local szName =
			insert(menu, { szOption = this:Lookup(1):GetText(), bDisable = true })
			insert(menu, { bDevide = true })
			insert(menu, { szOption = _L['Clear this map data'], rgb = { 255, 0, 0 }, fnAction = function()
				if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
					Circle.RemoveData(dwMapID, nil, true)
				else
					D.RemoveData(dwMapID, nil, LIB.GetMapInfo(dwMapID))
				end
			end })
			PopupMenu(menu)
		end
	elseif szName == 'Handle_L' then
		local t = this.dat
		local menu = {}
		local name = this:Lookup('Text') and this:Lookup('Text'):GetText() or t.szContent
		if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' then -- 太长
			insert(menu, { szOption = g_tStrings.CHAT_NAME .. g_tStrings.STR_COLON .. name, bDisable = true })
		end
		insert(menu, { szOption = _L['Class'] .. g_tStrings.STR_COLON .. (D.GetMapName(t.dwMapID) or t.dwMapID), bDisable = true })
		insert(menu, { bDevide = true })
		insert(menu, { szOption = g_tStrings.STR_FRIEND_MOVE_TO })
		insert(menu[#menu], { szOption = _L['Manual input'], fnAction = function()
			GetUserInput(g_tStrings.MSG_INPUT_MAP_NAME, function(szText)
				local map = LIB.GetMapInfo(szText)
				if map then
					if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
						return Circle.MoveData(t.dwMapID, t.nIndex, map, IsCtrlKeyDown())
					else
						return D.MoveData(t.dwMapID, t.nIndex, map, IsCtrlKeyDown())
					end
				end
				return LIB.Alert(_L['The map does not exist'])
			end)
		end })
		insert(menu[#menu], { bDevide = true })
		D.InsertDungeonMenu(menu[#menu], function(dwMapID)
			if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
				Circle.MoveData(t.dwMapID, t.nIndex, dwMapID, IsCtrlKeyDown())
			else
				D.MoveData(t.dwMapID, t.nIndex, dwMapID, IsCtrlKeyDown())
			end
		end)
		insert(menu, { bDevide = true })
		insert(menu, { szOption = _L['Share Data'], bDisable = not LIB.IsInParty(), fnAction = function()
			if LIB.IsLeader() or LIB.IsDebugClient(true) then
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TM_SHARE', MY_TMUI_SELECT_TYPE, t.dwMapID, t)
				LIB.Topmsg(g_tStrings.STR_MAIL_SUCCEED)
			else
				return LIB.Alert(_L['You are not team leader.'])
			end
		end })
		insert(menu, { bDevide = true })
		insert(menu, { szOption = g_tStrings.STR_FRIEND_DEL, rgb = { 255, 0, 0 }, fnAction = function()
			if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
				Circle.RemoveData(t.dwMapID, t.nIndex, true)
			else
				D.RemoveData(t.dwMapID, t.nIndex, name)
			end
		end })
		PopupMenu(menu)
	elseif szName == 'Handle_R' then
		local menu = {}
		local t = this.dat
		local szName = D.GetDataName(MY_TMUI_SELECT_TYPE, t)
		-- insert(menu, { szOption = _L['Add to monitor list'], fnAction = function() D.OpenAddPanel(MY_TMUI_SELECT_TYPE, t) end })
		-- insert(menu, { bDevide = true })
		insert(menu, { szOption = g_tStrings.STR_DATE .. g_tStrings.STR_COLON .. FormatTime('%Y%m%d %H:%M:%S',t.nCurrentTime) , bDisable = true })
		if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' then
			insert(menu, { szOption = g_tStrings.CHAT_NAME .. g_tStrings.STR_COLON .. szName, bDisable = true })
		end
		insert(menu, { szOption = g_tStrings.MAP_TALK .. g_tStrings.STR_COLON .. Table_GetMapName(t.dwMapID), bDisable = true })
		if MY_TMUI_SELECT_TYPE ~= 'NPC' and MY_TMUI_SELECT_TYPE ~= 'CIRCLE' and MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'DOODAD' then
			insert(menu, { szOption = g_tStrings.STR_SKILL_H_CAST_TIME .. (t.szSrcName or g_tStrings.STR_CRAFT_NONE) .. (t.bIsPlayer and _L['(player)'] or ''), bDisable = true })
		end
		if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' then
			local cmenu = { szOption = _L['Interval Time'] }
			local tInterval
			if t.nLevel then
				tInterval = MY_TeamMon.GetIntervalData(MY_TMUI_SELECT_TYPE, t.dwID .. '_' .. t.nLevel)
			else
				tInterval = MY_TeamMon.GetIntervalData(MY_TMUI_SELECT_TYPE, t.dwID)
			end

			if tInterval and #tInterval > 1 then
				local nTime = tInterval[#tInterval]
				for k, v in ipairs_r(tInterval) do
					if #cmenu == 16 then break end
					insert(cmenu, { szOption = string.format('%.1f', (nTime - v) / 1000) .. g_tStrings.STR_TIME_SECOND })
					nTime = v
				end
				remove(cmenu, 1)
			else
				insert(cmenu, { szOption = g_tStrings.STR_FIGHT_NORECORD, bDisable = true })
			end
			insert(menu, cmenu)
		end
		PopupMenu(menu)
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'TreeLeaf_Node' or szName == 'TreeLeaf_Content' then
		local handle = this:GetParent()
		if handle.hSelect ~= this and this:IsValid() and this:Lookup(0) and this:Lookup(0):IsValid() then
			this:Lookup(0):Hide()
		end
	elseif szName == 'Handle_L' or szName == 'Handle_R' then
		if MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT' then
			if this:Lookup('Image_Light') and this:Lookup('Image_Light'):IsValid() then
				this:Lookup('Image_Light'):Hide()
			end
		else
			if this:Lookup('Image') and this:Lookup('Image'):IsValid() then
				this:Lookup('Image'):SetFrame(7)
				local box = this:Lookup('Box')
				if box and box:IsValid() then
					box:SetObjectMouseOver(false)
				end
			end
		end
	end
	HideTip()
end

function D.OnItemMouseEnter()
	local szName = this:GetName()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	if szName == 'TreeLeaf_Node' or szName == 'TreeLeaf_Content' then
		this:Lookup(0):Show()
		if szName == 'TreeLeaf_Content' then
			local info = IsNumber(this.dwMapID) and g_tTable.DungeonInfo:Search(this.dwMapID)
			local szXml = GetFormatText((D.GetMapName(this.dwMapID) or this.dwMapID) ..' (' .. this.nCount ..  ')\n', 47, 255, 255, 0)
			if info and LIB.TrimString(info.szBossInfo) ~= '' then
				local tBoss = LIB.SplitString(info.szBossInfo, ' ')
				for k, v in ipairs(tBoss or {}) do
					if LIB.TrimString(v) ~= '' then
						szXml = szXml .. GetFormatText(k .. ') ' .. v .. '\n', 47, 255, 255, 255)
					end
				end
				szXml = szXml .. GetFormatImage(info.szDungeonImage3, 0, 200, 200)
			end
			if IsCtrlKeyDown() then
				szXml = szXml .. GetFormatText('\n\n' .. g_tStrings.DEBUG_INFO_ITEM_TIP .. '\nMapID:' .. this.dwMapID, 47, 255, 0, 0)
			end
			OutputTip(szXml, 300, { x, y, w, h })
		end
	elseif szName == 'Handle_L' or szName == 'Handle_R' then
		if MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT' then
			this:Lookup('Image_Light'):Show()
		else
			this:Lookup('Image'):SetFrame(8)
			local box = this:Lookup('Box')
			box:SetObjectMouseOver(true)
		end
		if szName == 'Handle_R' and MY_TMUI_SELECT_TYPE == 'CIRCLE' then -- circle fix
			D.OutputTip('NPC', this.dat, { x, y, w, h })
		else
			D.OutputTip(MY_TMUI_SELECT_TYPE, this.dat, { x, y, w, h })
		end

	end
end

function D.OnItemLButtonDrag()
	local szName = this:GetName()
	if szName == 'Handle_L' or szName == 'Handle_R' then
		OpenDragPanel(this)
	end
end

function D.OnItemLButtonDragEnd()
	local szName = this:GetName()
	if not DragPanelIsOpened() then
		return
	end
	local data, szAction = CloseDragPanel()
	if szName == 'TreeLeaf_Content' then
		if szAction:find('Handle.+L') then
			if data and data.dwMapID ~= this.dwMapID then
				if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
					Circle.MoveData(data.dwMapID, data.nIndex, this.dwMapID, IsCtrlKeyDown())
				else
					D.MoveData(data.dwMapID, data.nIndex, this.dwMapID, IsCtrlKeyDown())
				end
			end
		elseif szAction:find('Handle.+R') then
			D.OpenAddPanel(MY_TMUI_SELECT_TYPE, data)
		end
	elseif szName:find('Handle.+L') then
		if szAction:find('Handle.+L') and not szName:find('Handle.+List_L') then
			if MY_TMUI_SELECT_MAP ~= _L['All Data'] then
				if MY_TMUI_SELECT_TYPE == 'CIRCLE' then
					Circle.Exchange(MY_TMUI_SELECT_MAP, data.nIndex, this.dat.nIndex)
				else
					D.Exchange(MY_TMUI_SELECT_MAP, data.nIndex, this.dat.nIndex)
				end
			else
				D.UpdateTree(this:GetRoot())
			end
		elseif szAction:find('Handle.+R') then
			D.OpenAddPanel(MY_TMUI_SELECT_TYPE, data)
		end
	end
	LIB.DelayCall(50, function() -- 由于 click在 dragend 之后
		MY_TMUI_DRAG = false
	end)
end

-- 优化核心函数 根据滚动条加载内容
function D.OnScrollBarPosChanged()
	-- print(this:GetName())
	local hWndScroll = this:GetParent()
	local szName = hWndScroll:GetName()
	local dir = szName:match('WndScroll_' .. MY_TMUI_SELECT_TYPE .. '_(.*)')
	if dir then
		local handle = hWndScroll:Lookup('', string.format('Handle_%s_List_%s', MY_TMUI_SELECT_TYPE, dir))
		local nPer = this:GetScrollPos() / math.max(1, this:GetStepCount())
		local nCount = math.ceil(handle:GetItemCount() * nPer)
		for i = math.max(0, nCount - 21), nCount + 21, 1 do -- 每次渲染两页
			local h = handle:Lookup(i)
			if h then
				if not h.bDraw then
					if MY_TMUI_SELECT_TYPE == 'BUFF' or MY_TMUI_SELECT_TYPE == 'DEBUFF' then
						D.SetBuffItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'CASTING' then
						D.SetCastingItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'NPC' then
						D.SetNpcItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'DOODAD' then
						D.SetDoodadItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'CIRCLE' and dir == 'L' then
						D.SetCircleItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'CIRCLE' and dir == 'R'  then
						D.SetNpcItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'TALK' then
						D.SetTalkItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'CHAT' then
						D.SetChatItemAction(h)
					end
				end
			else
				break
			end
		end
	end
end

function D.OutputTip(szType, data, rect)
	if szType == 'BUFF' or szType == 'DEBUFF' then
		LIB.OutputBuffTip(data.dwID, data.nLevel, rect)
	elseif szType == 'CASTING' then
		OutputSkillTip(data.dwID, data.nLevel, rect)
	elseif szType == 'NPC' then
		LIB.OutputNpcTemplateTip(data.dwID, rect)
	elseif szType == 'DOODAD' then
		LIB.OutputDoodadTemplateTip(data.dwID, rect)
	elseif szType == 'TALK' then
		OutputTip(GetFormatText((data.szTarget or _L['Warning Box']) .. '\t', 41, 255, 255, 0) .. GetFormatText((D.GetMapName(data.dwMapID) or data.dwMapID) .. '\n', 41, 255, 255, 255) .. GetFormatText(data.szContent, 41, 255, 255, 255), 300, rect)
	elseif szType == 'CHAT' then
		OutputTip(GetFormatText(_L['CHAT'] .. '\t', 41, 255, 255, 0) .. GetFormatText((D.GetMapName(data.dwMapID) or data.dwMapID) .. '\n', 41, 255, 255, 255) .. GetFormatText(data.szContent, 41, 255, 255, 255), 300, rect)
	elseif szType == 'CIRCLE' then
		Circle.OutputTip(data, rect)
	end
end

function D.InsertDungeonMenu(menu, fnAction)
	local me = GetClientPlayer()
	local dwMapID = me.GetMapID()
	local tDungeon =  MY_TeamMon.GetDungeon()
	local data = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
	insert(menu, { szOption = g_tStrings.CHANNEL_COMMON .. ' (' .. (data[-1] and #data[-1] or 0) .. ')', fnAction = function()
		if fnAction then
			fnAction(-1)
		end
	end })
	insert(menu, { bDevide = true })
	for k, v in ipairs(tDungeon) do
		local tMenu = { szOption = v.szLayer3Name }
		for _, vv in ipairs(v.aList) do
			insert(tMenu, {
				szOption = Table_GetMapName(vv) .. ' (' .. (data[vv] and #data[vv] or 0) .. ')',
				rgb      = { 255, 128, 0 },
				szIcon   = dwMapID == vv and 'ui/Image/Minimap/Minimap.uitex',
				szLayer  = dwMapID == vv and 'ICON_RIGHT',
				nFrame   = dwMapID == vv and 10,
				fnAction = function()
					if fnAction then
						fnAction(vv)
					end
				end
			})
		end
		insert(menu, tMenu)
	end
end

function D.OpenImportPanel(szDefault, szTitle, fnAction)
	local ui = UI.CreateFrame('MY_TeamMon_DataPanel', { w = 720, h = 330, text = _L['Import Data'], close = true })
	local nX, nY = ui:append('Text', { x = 20, y = 50, text = _L['includes'], font = 27 }, true):pos('BOTTOMRIGHT')
	nX = 20
	for k, v in ipairs(MY_TMUI_TYPE) do
		nX = ui:append('WndCheckBox', { name = v, x = nX + 5, y = nY, checked = true, text = _L[v] }, true):autoWidth():pos('BOTTOMRIGHT')
	end
	nY = 110
	nX, nY = ui:append('Text', { x = 20, y = nY, text = _L['File Name'], font = 27 }, true):pos('BOTTOMRIGHT')
	nX = ui:append('WndEditBox', { name = 'FilePtah', x = 25, y = nY, w = 450, h = 25, text = szTitle, enable = not szDefault }, true):pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndButton2', { x = nX + 5, y = nY, text = _L['Browse'], enable = not szDefault,
		onclick = function()
			local szFile = GetOpenFileName(_L['please select data file.'], 'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0')
			if szFile ~= '' and not szFile:lower():find('interface') then
				LIB.Alert(_L['please select interface path.'])
				ui:children('#FilePtah'):text('')
			else
				ui:children('#FilePtah'):text(szFile)
			end
		end,
	}, true):pos('BOTTOMRIGHT')
	nY = nY + 10
	nX, nY = ui:append('Text', { x = 20, y = nY, text = _L['Import mode'], font = 27 }, true):pos('BOTTOMRIGHT')
	local nType = 1
	nX = ui:append('WndRadioBox', {
		x = 25, y = nY,
		text = _L['Cover'],
		group = 'type', checked = true,
		oncheck = function()
			nType = 1
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['Merge Priority new file'], group = 'type',
		oncheck = function()
			nType = 3
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['Merge Priority old file'], group = 'type',
		oncheck = function()
			nType = 2
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	ui:append('WndButton3', {
		x = 285, y = nY + 30, text = g_tStrings.STR_HOTKEY_SURE,
		onclick = function()
			local config = {
				bFullPath  = not szDefault,
				szFileName = szDefault or ui:children('#FilePtah'):text(),
				nMode      = nType,
				tList      = {}
			}
			for k, v in ipairs(MY_TMUI_TYPE) do
				if ui:children('#' .. v):check() then
					config.tList[v] = true
				end
			end
			local bStatus, szMsg = MY_TeamMon.LoadConfigureFile(config)
			LIB.Debug('#MY_TeamMon# load config: ' .. tostring(szMsg))
			if bStatus then
				LIB.Alert(_L('Import success %s', szTitle or szMsg))
				ui:remove()
				if fnAction then
					fnAction()
				end
			else
				LIB.Alert(_L('Import failed %s', szTitle or _L[szMsg]))
			end
		end,
	})
end

function D.OpenExportPanel()
	local ui = UI.CreateFrame('MY_TeamMon_DataPanel', { w = 720, h = 330, text = _L['Export Data'], close = true })
	local nX, nY = ui:append('Text', { x = 20, y = 50, text = _L['includes'], font = 27 }, true):pos('BOTTOMRIGHT')
	nX = 20
	for k, v in ipairs(MY_TMUI_TYPE) do
		nX = ui:append('WndCheckBox', { name = v, x = nX + 5, y = nY, checked = true, text = _L[v] }, true):autoWidth():pos('BOTTOMRIGHT')
	end
	nY = 110
	local szFileName = 'TM-' .. select(3, GetVersion()) .. FormatTime('-%Y%m%d_%H.%M', GetCurrentTime()) .. '.jx3dat'
	nX, nY = ui:append('Text', { x = 20, y = nY, text = _L['File Name'], font = 27 }, true):pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndEditBox', {
		x = 25, y = nY, w = 500, h = 25,
		text = szFileName,
		onchange = function(szText)
			szFileName = szText
		end,
	}, true):pos('BOTTOMRIGHT')
	nY = nY + 10
	nX, nY = ui:append('Text', { x = 20, y = nY, text = _L['File Format'], font = 27 }, true):pos('BOTTOMRIGHT')
	local nType = 1
	nX = ui:append('WndRadioBox', {
		x = 25, y = nY,
		text = _L['LUA TABLE'], group = 'type',
		checked = true,
		oncheck = function()
			nType = 1
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['JSON'], group = 'type', enable = false,
		onclick = function()
			nType = 2
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	ui:append('WndCheckBox', 'Format', { x = 20, y = nY + 50, text = _L['Format content'] })
	ui:append('WndButton3', {
		x = 285, y = nY + 30, text = g_tStrings.STR_HOTKEY_SURE,
		onclick = function()
			local config = {
				bFormat = ui:children('#Format'):check(),
				szFileName = szFileName,
				bJson = nType == 2,
				tList = {}
			}
			for k, v in ipairs(MY_TMUI_TYPE) do
				if ui:children('#' .. v):check() then
					config.tList[v] = true
				end
			end
			local path = MY_TeamMon.SaveConfigureFile(config)
			LIB.Alert(_L('Export success %s', path))
			ui:remove()
		end,
	})
end

function D.MoveData( ... )
	MY_TeamMon.MoveData(MY_TMUI_SELECT_TYPE, ... )
end

function D.Exchange( ... )
	MY_TeamMon.Exchange(MY_TMUI_SELECT_TYPE, ...)
end

function D.RemoveData(dwMapID, nIndex, szMsg)
	local function fnAction()
		MY_TeamMon.RemoveData(MY_TMUI_SELECT_TYPE, dwMapID, nIndex)
	end
	if not nIndex then
		LIB.Confirm(FormatString(g_tStrings.MSG_DELETE_NAME, szMsg), fnAction)
	else
		fnAction()
	end
end

function D.GetSearchCache(data)
	if not MY_TMUI_SEARCH_CACHE[MY_TMUI_SELECT_TYPE] then
		MY_TMUI_SEARCH_CACHE[MY_TMUI_SELECT_TYPE] = {}
	end
	local tab = MY_TMUI_SEARCH_CACHE[MY_TMUI_SELECT_TYPE]
	local szString
	if data.dwMapID and data.nIndex then
		if tab[data.dwMapID] and tab[data.dwMapID][data.nIndex] then
			szString = tab[data.dwMapID][data.nIndex]
		else
			tab[data.dwMapID] = tab[data.dwMapID] or {}
			tab[data.dwMapID][data.nIndex] = JsonEncode(data)
			szString = tab[data.dwMapID][data.nIndex]
		end
	else -- 临时记录 暂时还不做缓存处理
		szString = JsonEncode(data)
	end
	return szString
end

function D.CheckSearch(szType, data)
	if MY_TMUI_GLOBAL_SEARCH then
		if D.GetSearchCache(data):find(MY_TMUI_SEARCH, nil, true) then
			return true
		end
	else
		local szName = D.GetDataName(szType, data)
		if tostring(szName):find(MY_TMUI_SEARCH, nil, true)
			or (data.szNote   and tostring(data.szNote):find(MY_TMUI_SEARCH, nil, true))
			or (data.key      and tostring(data.key):find(MY_TMUI_SEARCH, nil, true)) -- 画圈圈
			or (data.dwID     and tostring(data.dwID):find(MY_TMUI_SEARCH, nil, true))
			or (data.dwMapID  and D.GetMapName(data.dwMapID):find(MY_TMUI_SEARCH, nil, true))
			or (data.szTarget and tostring(data.szTarget):find(MY_TMUI_SEARCH, nil, true))
		then
			return true
		end
	end
	return false
end

function D.GetDataName(szType, data)
	local szName, nIcon
	if szType == 'CASTING' then
		szName, nIcon = LIB.GetSkillName(data.dwID, data.nLevel)
	elseif szType == 'NPC' or szType == 'CIRCLE' then
		if data.dwID then
			szName = LIB.GetTemplateName(data.dwID) or data.dwID
			nIcon = data.nFrame
		end
	elseif szType == 'DOODAD' then
		local doodad = GetDoodadTemplate(data.dwID)
		szName = doodad.szName ~= '' and doodad.szName or data.dwID
		nIcon  = MY_TMUI_DOODAD_ICON[doodad.nKind]
	elseif szType == 'TALK' or szType == 'CHAT' then
		szName = data.szContent
	else
		szName, nIcon = LIB.GetBuffName(data.dwID, data.nLevel)
	end
	nIcon  = data.nIcon  or nIcon
	szName = data.szName or szName
	return szName, nIcon
end

function D.SetBuffItemAction(h)
	local dat = h.dat
	local szName, nIcon = D.GetDataName('BUFF', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local nSec = select(3, GetBuffTime(dat.dwID, dat.nLevel))
	if not nSec then
		h:Lookup('Text_R'):SetText('N/A')
	elseif nSec > 24 * 60 * 60 / GLOBAL.GAME_FPS then
		h:Lookup('Text_R'):SetText(_L['infinite'])
	else
		nSec = nSec / GLOBAL.GAME_FPS
		h:Lookup('Text_R'):SetText(LIB.FormatTimeCounter(nSec, 1))
	end
	h:Lookup('Image_RBg'):Show()
	local box = h:Lookup('Box')
	box:SetObjectIcon(nIcon)
	if dat.nCount then
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		box:SetOverText(0, dat.nCount)
	end
	h.bDraw = true
end

function D.SetCastingItemAction(h)
	local dat = h.dat
	local szName, nIcon = D.GetDataName('CASTING', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local hSkill = GetSkillInfo({ skill_id = dat.dwID, skill_level = dat.nLevel })
	if not hSkill or hSkill.AreaRadius == 0 then
		h:Lookup('Text_R'):SetText('N/A')
	else
		h:Lookup('Text_R'):SetText(hSkill.AreaRadius / 64 .. g_tStrings.STR_METER)
	end
	h:Lookup('Image_RBg'):Show()
	local box = h:Lookup('Box')
	box:SetObjectIcon(nIcon)
	h.bDraw = true
end

function D.SetNpcItemAction(h)
	local dat = h.dat
	local szName = D.GetDataName('NPC', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local box = h:Lookup('Box')
	box:ClearObjectIcon()
	box:SetExtentImage('ui/Image/TargetPanel/Target.UITex', dat.nFrame)
	h.bDraw = true
end

function D.SetDoodadItemAction(h)
	local dat = h.dat
	local szName, nIcon = D.GetDataName('DOODAD', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local box = h:Lookup('Box')
	box:SetObjectIcon(nIcon)
	h.bDraw = true
end

function D.SetCircleItemAction(h)
	local dat = h.dat
	h:Lookup('Text'):SetText(dat.szNote and string.format('%s (%s)', dat.key, dat.szNote) or dat.key)
	local box = h:Lookup('Box')
	if dat.tCircles then
		h:Lookup('Text'):SetFontColor(unpack(dat.tCircles[1].col))
	end
	if dat.dwType == TARGET.NPC then
		box:SetObjectIcon(2397)
	else
		box:SetObjectIcon(2396)
	end
	h.bDraw = true
end

function D.SetTalkItemAction(h)
	local dat = h.dat
	h:Lookup('Text_Name'):SetText(dat.szTarget or _L['Warning Box'])
	if not dat.szTarget or dat.szTarget == '%' then -- system and %%
		h:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	end
	h:Lookup('Text_Content'):SetText(dat.szContent)
	if dat.col then
		h:Lookup('Text_Content'):SetFontColor(unpack(dat.col))
	end
	h.bDraw = true
end

function D.SetChatItemAction(h)
	local dat = h.dat
	h:Lookup('Text_Name'):SetText(_L['CHAT'])
	h:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	h:Lookup('Text_Content'):SetText(dat.szContent)
	if dat.col then
		h:Lookup('Text_Content'):SetFontColor(unpack(dat.col))
	end
	h.bDraw = true
end

function D.GetMapName(dwMapID)
	if dwMapID == _L['All Data'] then
		return dwMapID
	end
	local map = LIB.GetMapInfo(dwMapID)
	return map and map.szName
end

-- 更新监控数据
function D.UpdateLList()
	local tab = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
	if tab then
		local dat, dat2 = tab[MY_TMUI_SELECT_MAP] or {}, {}
		if MY_TMUI_SEARCH then
			for k, v in ipairs(dat) do
				if D.CheckSearch(MY_TMUI_SELECT_TYPE, v) then
					insert(dat2, v)
				end
			end
		else
			dat2 = dat
		end
		D.DrawTableL(dat2)
	end
end

function D.DrawTableL(data)
	local frame = D.GetFrame()
	local page = frame.hPageSet:GetActivePage()
	local handle = page:Lookup('WndScroll_' .. MY_TMUI_SELECT_TYPE .. '_L', 'Handle_' .. MY_TMUI_SELECT_TYPE .. '_List_L')
	local hItemData = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and frame.hTalkL or frame.hItemL
	handle:Clear()
	if #data > 0 then
		for k, v in ipairs_r(data) do
			local h = handle:AppendItemFromData(hItemData, 'Handle_L')
			h.dat = v
		end
	end
	handle:FormatAllItemPos()
	D.RefreshScroll('L')
end

-- 更新临时数据
function D.UpdateRList(data)
	if data then
		D.DrawTableR(data, true)
	else
		local tab, tab2 = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE, true), {}
		if tab then
			if MY_TMUI_SEARCH then
				for k, v in ipairs(tab) do
					if D.CheckSearch(MY_TMUI_SELECT_TYPE, v) then
						insert(tab2, v)
					end
				end
			else
				tab2 = tab
			end
			D.DrawTableR(tab2)
		end
	end
end

function D.DrawTableR(data, bInsert)
	local frame = D.GetFrame()
	local page = frame.hPageSet:GetActivePage()
	local handle = page:Lookup('WndScroll_' .. MY_TMUI_SELECT_TYPE .. '_R', 'Handle_' .. MY_TMUI_SELECT_TYPE .. '_List_R')
	if not bInsert then
		handle:Clear()
		local hItemData = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and frame.hTalkR or frame.hItemR
		if #data > 0 then
			for k, v in ipairs_r(data) do
				local h = handle:AppendItemFromData(hItemData, 'Handle_R')
				h.dat = v
			end
		end
	else
		-- 少一个 InsertItemFromData
		local szIniFile = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and MY_TMUI_TALK_R or MY_TMUI_ITEM_R
		local szSectionName = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and 'Handle_TALK_R' or 'Handle_R'
		if not MY_TMUI_SEARCH or D.CheckSearch(MY_TMUI_SELECT_TYPE, data) then
			handle:InsertItemFromIni(0, false, szIniFile, szSectionName, 'Handle_R')
			local h = handle:Lookup(0)
			h.dat = data
		end
	end
	handle:FormatAllItemPos()
	D.RefreshScroll('R')
end

-- 添加面板
function D.OpenAddPanel(szType, data)
	if szType == 'CIRCLE' then
		Circle.OpenAddPanel(IsCtrlKeyDown() and data.dwID or D.GetDataName('NPC', data), TARGET.NPC, Table_GetMapName(data.dwMapID), MY_TMUI_SELECT_MAP)
	else
		local szName, nIcon = _L[szType], 340
		if szType ~= 'TALK' and szType ~= 'CHAT' then
			szName, nIcon = D.GetDataName(szType, data)
		end
		local ui = UI.CreateFrame('MY_TeamMon_NewData', { w = 380, h = 250, text = szName, focus = true, close = true })
		local nX, nY = 0, 0
		ui:event('MY_TMUI_SWITCH_PAGE', function() ui:remove() end)
		ui:event('MY_TMUI_TEMP_RELOAD', function() ui:remove() end)
		if szType ~= 'NPC' then
			nX, nY = ui:append('Box', { name = 'Box_Icon', w = 48, h = 48, x = 166, y = 40, icon = nIcon }, true):pos('BOTTOMRIGHT')
		else
			nX, nY = ui:append('Box', {
				name = 'Box_Icon', w = 48, h = 48, x = 166, y = 40, icon = nIcon,
				image = 'ui/Image/TargetPanel/Target.uitex', imageframe = data.nFrame,
			}, true):pos('BOTTOMRIGHT')
		end
		ui:children('#Box_Icon'):hover(function(bHover)
			this:SetObjectMouseOver(bHover)
			if bHover then
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				D.OutputTip(szType, data, { x, y, w, h })
			else
				HideTip()
			end
		end)
		nX, nY = ui:append('WndEditBox', {
			name = 'map', x = 100, y = nY + 15, w = 200, h = 30,
			text = MY_TMUI_SELECT_MAP ~= _L['All Data'] and D.GetMapName(MY_TMUI_SELECT_MAP) or D.GetMapName(data.dwMapID),
			autocomplete = {{'option', 'source', LIB.GetMapNameList()}},
			onchange = function()
				local me = this
				if me:GetText() == '' then
					local menu = {}
					D.InsertDungeonMenu(menu, function(dwMapID)
						me:SetText(D.GetMapName(dwMapID))
					end)
					local nX, nY = this:GetAbsPos()
					local nW, nH = this:GetSize()
					menu.nMiniWidth = nW
					menu.x = nX
					menu.y = nY + nH
					menu.fnAutoClose = function() return not me or not me:IsValid() end
					menu.bShowKillFocus = true
					menu.bDisableSound = true
					PopupMenu(menu)
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		ui:append('WndButton3', {
			x = 120, y = nY + 40, text = _L['Add'],
			onclick = function()
				local txt = ui:children('#map'):text()
				local map = LIB.GetMapInfo(txt)
				if not map then
					return LIB.Alert(_L['The map does not exist'])
				end
				local tab = select(2, MY_TeamMon.CheckSameData(szType, map.dwID, data.dwID or data.szContent, data.nLevel or data.szTarget))
				if tab then
					return LIB.Confirm(_L['Data exists, editor?'], function()
						D.OpenSettingPanel(tab, szType)
						ui:remove()
					end)
				end
				local dat = {
					dwID      = data.dwID,
					nLevel    = data.nLevel,
					nFrame    = data.nFrame,
					szContent = data.szContent,
					szTarget  = data.szTarget
				}
				MY_TMUI_SELECT_MAP = map.dwID
				D.OpenSettingPanel(MY_TeamMon.AddData(szType, map.dwID, dat), szType)
				ui:remove()
			end,
		})
	end
end
-- 数据调试面板
function D.OpenJosnPanel(data, fnAction)
	local ui = UI.CreateFrame('MY_TeamMon_JsonPanel', { w = 720,h = 500, text = _L['MY_TeamMon DEBUG Panel'], close = true })
	ui:event('MY_TMUI_DATA_RELOAD', function() ui:remove() end)
	ui:event('MY_TMUI_SWITCH_PAGE', function() ui:remove() end)
	ui:append('WndEditBox', {
		name = 'CODE', w = 660, h = 350, x = 30, y = 60,
		color = { 255, 255, 0 },
		text = JsonEncode(data, true),
		multiline = true, limit = 999999,
		onchange = function()
			local code = ui:children('#CODE')
			local dat  = LIB.JsonDecode(code:text())
			if dat then
				code:Color(255, 255, 0)
				else
				code:Color(255, 0, 0)
			end
		end,
	})
	ui:append('WndButton3',{
		x = 30, y = 440,
		text = g_tStrings.STR_HOTKEY_SURE,
		onclick = function()
			LIB.Confirm(_L['Confirm?'], function()
				local dat = LIB.JsonDecode(ui:children('#CODE'):text())
				if fnAction and dat then
					ui:Remove()
					return fnAction(dat)
				end
			end)
		end,
	})
end

-- 设置面板
function D.OpenSettingPanel(data, szType)
	local function GetScrutinyTypeMenu()
		local menu = {
			{ szOption = g_tStrings.STR_GUILD_ALL, bMCheck = true, bChecked = type(data.nScrutinyType) == 'nil', fnAction = function() data.nScrutinyType = nil end },
			-- { bDevide = true },
			{ szOption = g_tStrings.MENTOR_SELF, bMCheck = true, bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.SELF, fnAction = function() data.nScrutinyType = MY_TM_SCRUTINY_TYPE.SELF end },
			{ szOption = _L['Team'], bMCheck = true, bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.TEAM, fnAction = function() data.nScrutinyType = MY_TM_SCRUTINY_TYPE.TEAM end },
			{ szOption = _L['Enemy'], bMCheck = true, bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.ENEMY, fnAction = function() data.nScrutinyType = MY_TM_SCRUTINY_TYPE.ENEMY end },
			{ szOption = g_tStrings.STR_RAID_TIP_TARGET, bMCheck = true, bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.TARGET, fnAction = function() data.nScrutinyType = MY_TM_SCRUTINY_TYPE.TARGET end },
		}
		return menu
	end
	local function GetKungFuMenu()
		local menu = {}
		if data.tKungFu then
			insert(menu, { szOption = _L['no request'], bCheck = true, bChecked = type(data.tKungFu) == 'nil', fnAction = function()
				data.tKungFu = nil
				GetPopupMenu():Hide()
			end })
		end
		for k, v in ipairs(CONSTANT.KUNGFU_LIST) do
			insert(menu, {
				szOption = LIB.GetSkillName(v.dwID, 1),
				bCheck   = true,
				bChecked = data.tKungFu and data.tKungFu['SKILL#' .. v.dwID],
				szIcon   = v.szUITex,
				nFrame   = v.nFrame,
				szLayer  = 'ICON_RIGHTMOST',
				fnAction = function()
					data.tKungFu = data.tKungFu or {}
					if not data.tKungFu['SKILL#' .. v.dwID] then
						data.tKungFu['SKILL#' .. v.dwID] = true
					else
						data.tKungFu['SKILL#' .. v.dwID] = nil
						if IsEmpty(data.tKungFu) then
							data.tKungFu = nil
						end
					end
				end
			})
		end
		return menu
	end
	local function GetMarkMenu(nClass)
		local menu = {}
		for k, v in ipairs_c(PARTY_MARK_ICON_FRAME_LIST) do
			insert(menu, {
				szOption = LIB.GetMarkName(k),
				szIcon = PARTY_MARK_ICON_PATH,
				nFrame = v, szLayer = 'ICON_RIGHT',
				bCheck = true, bChecked = data[nClass] and data[nClass].tMark and data[nClass].tMark[k],
				fnAction = function(_, bCheck)
					if bCheck then
						data[nClass] = data[nClass] or {}
						if not data[nClass].tMark then
							data[nClass].tMark = {}
							for kk, vv in ipairs_c(PARTY_MARK_ICON_FRAME_LIST) do
								data[nClass].tMark[kk] = false
							end
						end
						data[nClass].tMark[k] = true
					else
						data[nClass].tMark[k] = false
						local bDelete = true
						for k, v in ipairs(data[nClass].tMark) do
							if v then
								bDelete = false
								break
							end
						end
						if bDelete then
							data[nClass].tMark = nil
						end
						if IsEmpty(data[nClass]) then data[nClass] = nil end
					end
				end,
			})
		end
		return menu
	end
	local function SetDataClass(nClass, key, value)
		if value then
			data[nClass] = data[nClass] or {}
			data[nClass][key] = value
		else
			data[nClass][key] = nil
			if IsEmpty(data[nClass]) then
				data[nClass] = nil
			end
		end
	end

	local function UI_tonumber(szNum, nDefault)
		if tonumber(szNum) then
			return tonumber(szNum)
		else
			return nDefault
		end
	end

	local function SetCountdownType(dat, val, ui)
		dat.nClass = val
		ui:text(_L['Countdown TYPE ' ..  dat.nClass])
		GetPopupMenu():Hide()
	end

	local function CheckCountdown(tTime)
		if tonumber(tTime) then
			return true
		else
			local tab = {}
			local t = LIB.SplitString(tTime, ';')
			for k, v in ipairs(t) do
				local time = LIB.SplitString(v, ',')
				if time[1] and time[2] and tonumber(LIB.TrimString(time[1])) and time[2] ~= '' then
					insert(tab, { nTime = tonumber(time[1]), szName = time[2] })
				elseif LIB.TrimString(time[1]) ~= '' and not tonumber(time[1]) then
					return false
				elseif tonumber(time[1]) and (not time[2] or LIB.TrimString(time[2]) == '') then
					return false
				end
			end
			if IsEmpty(tab) then
				return false
			else
				sort(tab, function(a, b)
					return a.nTime < b.nTime
				end)
				return tab
			end
		end
	end
	local tSkillInfo
	local me = GetClientPlayer()
	local file = 'ui/Image/UICommon/Feedanimials.uitex'
	local szName, nIcon = _L[szType], 340
	if szType ~= 'TALK' and szType ~= 'CHAT' then
		szName, nIcon = D.GetDataName(szType, data)
	elseif szType == 'CHAT' then
		nIcon = 439
	end
	local ui = UI.CreateFrame('MY_TeamMon_SettingPanel', { w = 770, h = 450, text = szName, close = true, focus = true })
	local frame = Station.Lookup('Normal/MY_TeamMon_SettingPanel')
	ui:event('MY_TMUI_DATA_RELOAD', function() ui:remove() end)
	ui:event('MY_TMUI_SWITCH_PAGE', function() ui:remove() end)
	frame.OnFrameDragEnd = function()
		MY_TMUI_PANEL_ANCHOR = GetFrameAnchor(frame, 'LEFTTOP')
	end
	local nX, nY, _ = 0, 0, 0
	local function fnClickBox()
		local menu, box = {}, this
		if szType ~= 'TALK' and szType ~= 'CHAT' then
			insert(menu, { szOption = _L['Edit Name'], fnAction = function()
				GetUserInput(_L['Edit Name'], function(szText)
					if LIB.TrimString(szText) == '' then
						data.szName = nil
						ui:text(szName)
					else
						data.szName = szText
						ui:text(szText)
					end
				end, nil, nil, nil, data.szName or szName)
			end})
			insert(menu, { bDevide = true })
		end
		if szType ~= 'NPC' and szType ~= 'TALK' and szType ~= 'CHAT' then
			insert(menu, { szOption = _L['Edit Iocn'], fnAction = function()
				UI.OpenIconPanel(function(nIcon)
					data.nIcon = nIcon
					box:SetObjectIcon(nIcon)
				end)
			end})
			insert(menu, { bDevide = true })
		end
		insert(menu, {
			szOption = _L['Edit Color'],
			szLayer = 'ICON_RIGHT',
			szIcon = 'ui/Image/UICommon/Feedanimials.uitex',
			nFrame = 86,
			nMouseOverFrame = 87,
			fnClickIcon = function()
				data.col = nil
				ui:children('#Shadow_Color'):alpha(0)
			end,
			fnAction = function()
				UI.OpenColorPicker(function(r, g, b)
					data.col = { r, g, b }
					ui:children('#Shadow_Color'):color(r, g, b):alpha(255)
				end)
			end
		})
		insert(menu, { bDevide = true })
		insert(menu, { szOption = _L['raw data, Please be careful'], color = { 255, 255, 0 }, fnAction = function()
			D.OpenJosnPanel(data, function(dat)
				local file = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
				if file and file[MY_TMUI_SELECT_MAP] and file[data.dwMapID][data.nIndex] then
					file[data.dwMapID][data.nIndex] = dat
				end
				FireUIEvent('MY_TM_CREATE_CACHE')
				FireUIEvent('MY_TMUI_DATA_RELOAD')
				D.OpenSettingPanel(file[data.dwMapID][data.nIndex], szType)
			end)
		end })
		PopupMenu(menu)
	end

	ui:append('Shadow', { name = 'Shadow_Color', w = 52, h = 52, x = 359, y = 38, color = data.col, alpha = data.col and 255 or 0 })
	if szType ~= 'NPC' then
		nX, nY = ui:append('Box', { name = 'Box_Icon', w = 48, h = 48, x = 361, y = 40, icon = nIcon }, true):pos('BOTTOMRIGHT')
	else
		nX, nY = ui:append('Box', {
			name = 'Box_Icon', w = 48, h = 48, x = 361, y = 40, icon = nIcon,
			image = 'ui/Image/TargetPanel/Target.uitex', imageframe = data.nFrame,
		}, true):pos('BOTTOMRIGHT')
	end
	ui:children('#Box_Icon'):hover(function(bHover)
		this:SetObjectMouseOver(bHover)
		if bHover then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			D.OutputTip(szType, data, { x, y, w, h })
		else
			HideTip()
		end
	end):click(fnClickBox)
	if szType == 'BUFF' or szType == 'DEBUFF' then
		nX, nY = ui:append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndComboBox', {
			x = 30, y = nY, w = 200, text = _L['Scrutiny Type'],
			menu = function()
				return GetScrutinyTypeMenu(data)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndComboBox', {
			x = nX + 5, y = nY + 2, w = 200, text = _L['Self KungFu require'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('Text', { x = nX + 5, y = nY, text = _L['Count Achieve'] }, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndEditBox', {
			x = nX + 2, y = nY + 2, w = 30, h = 26,
			text = data.nCount or 1, edittype = 0,
			onchange = function(nNum)
				data.nCount = UI_tonumber(nNum)
				if data.nCount == 1 then
					data.nCount = nil
				end
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bCheckLevel, text = _L['Check Level'],
			oncheck = function(bCheck)
				data.bCheckLevel = bCheck and true or nil
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		-- get buff
		local cfg = data[MY_TM_TYPE.BUFF_GET] or {}
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Get Buff'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndComboBox', {
			x = nX + 5, y = nY + 8, w = 60, h = 25, text = _L['Mark'],
			menu = function()
				return GetMarkMenu(MY_TM_TYPE.BUFF_GET)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bCenterAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Screen Head Alarm'],
			tip = _L['Requires MY_LifeBar loaded.'], tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bScreenHead', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bFullScreen', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT

		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bPartyBuffList, text = _L['Party Buff List'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bPartyBuffList', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bBuffList, text = _L['Buff List'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bBuffList', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bTeamPanel, text = _L['Team Panel'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bTeamPanel', bCheck)
				ui:children('#bOnlySelfSrc'):enable(bCheck)
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			name = 'bOnlySelfSrc',
			x = nX + 5, y = nY, checked = cfg.bOnlySelfSrc, text = _L['Only Source Self'], enable = cfg.bTeamPanel == true,
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bOnlySelfSrc', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nY = nY + CHECKBOX_HEIGHT

		if not LIB.IsShieldedVersion() then
			local _ui = ui:append('WndCheckBox', {
				x = 30, y = nY, checked = cfg.bSelect, text = _L['Auto Select'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bSelect', bCheck)
				end,
			}, true):autoWidth()
			nX = _ui:pos('BOTTOMRIGHT')
			if szType == 'BUFF' then
				nX, nY = ui:append('WndCheckBox', {
					x = nX + 5, y = nY, checked = cfg.bAutoCancel, text = _L['Auto Cancel Buff'],
					oncheck = function(bCheck)
						SetDataClass(MY_TM_TYPE.BUFF_GET, 'bAutoCancel', bCheck)
					end,
				}, true):autoWidth():pos('BOTTOMRIGHT')
			else
				nX, nY = _ui:pos('BOTTOMRIGHT')
			end
		end
		-- 失去buff
		local cfg = data[MY_TM_TYPE.BUFF_LOSE] or {}
		nX, nY = ui:append('Text', { x = 20, y = nY + 5, text = _L['Lose Buff'], font = 27 }, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bCenterAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'CASTING' then
		nX, nY = ui:append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndComboBox', {
			x = 30, y = nY + 2, text = _L['Scrutiny Type'],
			menu = function()
				return GetScrutinyTypeMenu(data)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndComboBox', {
			x = nX + 5, y = nY + 2, text = _L['Self KungFu require'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bCheckLevel, text = _L['Check Level'],
			oncheck = function(bCheck)
				data.bCheckLevel = bCheck and true or nil
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bMonTarget, text = _L['Show Target Name'],
			oncheck = function(bCheck)
				data.bMonTarget = bCheck and true or nil
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')

		local cfg = data[MY_TM_TYPE.SKILL_END] or {}
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Skills using a success'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndComboBox', {
			x = nX + 5, y = nY + 8, w = 160, h = 25, text = _L['Mark'],
			menu = function()
				return GetMarkMenu(MY_TM_TYPE.SKILL_END)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.SKILL_END, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.SKILL_END, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.SKILL_END, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_END, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_END, 'bFullScreen', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
		-- local tRecipeKey = me.GetSkillRecipeKey(data.dwID, data.nLevel)
		-- tSkillInfo = GetSkillInfo(tRecipeKey)
		-- if tSkillInfo and tSkillInfo.CastTime ~= 0 then
			local cfg = data[MY_TM_TYPE.SKILL_BEGIN] or {}
			nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Skills began to release'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
			nX, nY = ui:append('WndComboBox', {
				x = nX + 5, y = nY + 8, w = 160, h = 25, text = _L['Mark'],
				menu = function()
					return GetMarkMenu(MY_TM_TYPE.SKILL_BEGIN)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			nX = ui:append('WndCheckBox', {
				x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bTeamChannel', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bWhisperChannel', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bCenterAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			if not LIB.IsShieldedVersion() then
				nX = ui:append('WndCheckBox', {
					x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
					oncheck = function(bCheck)
						SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bBigFontAlarm', bCheck)
					end,
				}, true):autoWidth():pos('BOTTOMRIGHT')
			end
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Screen Head Alarm'],
				tip = _L['Requires MY_LifeBar loaded.'], tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bScreenHead', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
			if not LIB.IsShieldedVersion() then
				nX = ui:append('WndCheckBox', {
					x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
					oncheck = function(bCheck)
						SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bFullScreen', bCheck)
					end,
				}, true):autoWidth():pos('BOTTOMRIGHT')
			end
			nY = nY + CHECKBOX_HEIGHT
		-- end
	elseif szType == 'NPC' then
		nX, nY = ui:append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndComboBox', {
			x = 30, y = nY + 2, text = _L['Self KungFu require'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}, true):pos('BOTTOMRIGHT')
		nX = ui:append('Text', { x = nX + 5, y = nY, text = _L['Count Achieve'] }, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndEditBox', {
			x = nX + 2, y = nY + 2, w = 30, h = 26,
			text = data.nCount or 1, edittype = 0,
			onchange = function(nNum)
				data.nCount = UI_tonumber(nNum)
				if data.nCount == 1 then
					data.nCount = nil
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bAllLeave, text = _L['Must All leave scene'],
			oncheck = function(bCheck)
				data.bAllLeave = bCheck and true or nil
				if bCheck then
					ui:children('#NPC_LEAVE_TEXT'):text(_L['All Leave scene'])
				else
					ui:children('#NPC_LEAVE_TEXT'):text(_L['Leave scene'])
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.NPC_ENTER] or {}
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Enter scene'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndComboBox', {
			x = nX + 5, y = nY + 8, w = 160, h = 25, text = _L['Mark'],
			menu = function()
				return GetMarkMenu(MY_TM_TYPE.NPC_ENTER)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Screen Head Alarm'],
			tip = _L['Requires MY_LifeBar loaded.'], tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bScreenHead', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bFullScreen', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
		nX, nY = ui:append('Text', {
			name = 'NPC_LEAVE_TEXT', x = 20, y = nY + 5,
			text = data.bAllLeave and _L['All Leave scene'] or _L['Leave scene'], font = 27,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.NPC_LEAVE] or {}
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'DOODAD' then
		nX, nY = ui:append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndComboBox', {
			x = 30, y = nY + 2, text = _L['Self KungFu require'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('Text', { x = nX + 5, y = nY, text = _L['Count Achieve'] }, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndEditBox', {
			x = nX + 2, y = nY + 2, w = 30, h = 26, text = data.nCount or 1, edittype = 0,
			onchange = function(nNum)
				data.nCount = UI_tonumber(nNum)
				if data.nCount == 1 then
					data.nCount = nil
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bAllLeave, text = _L['Must All leave scene'],
			oncheck = function(bCheck)
				data.bAllLeave = bCheck and true or nil
				if bCheck then
					ui:children('#DOODAD_LEAVE_TEXT'):text(_L['All Leave scene'])
				else
					ui:children('#DOODAD_LEAVE_TEXT'):text(_L['Leave scene'])
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.DOODAD_ENTER] or {}
		nX, nY = ui:append('Text', { x = 20, y = nY + 5, text = _L['Enter scene'], font = 27 }, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Screen Head Alarm'],
			tip = _L['Requires MY_LifeBar loaded.'], tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bScreenHead', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bFullScreen', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
		nX, nY = ui:append('Text', {
			name = 'DOODAD_LEAVE_TEXT', x = 20, y = nY + 5,
			text = data.bAllLeave and _L['All Leave scene'] or _L['Leave scene'], font = 27,
		}, true):pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.DOODAD_LEAVE] or {}
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'TALK' then
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Alert Content'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szNote, w = 650, h = 25,
			onchange = function(text)
				local szText = LIB.TrimString(text)
				if szText == '' then
					data.szNote = nil
				else
					data.szNote = szText
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Speaker'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szTarget or _L['Warning Box'], w = 650, h = 25,
			onchange = function(text)
				local szText = LIB.TrimString(text)
				if szText == '' or szText == _L['Warning Box'] then
					data.szTarget = nil
				else
					data.szTarget = szText
				end
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}, true):pos('BOTTOMRIGHT')
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Content'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		_, nY = ui:append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szContent, w = 650, h = 55, multiline = true,
			onchange = function(text)
				data.szContent = LIB.TrimString(text)
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('Text', { x = nX, y = nY, text = _L['Tips:$me behalf of self, $team behalf of team, Only allow a time'], alpha = 200 }, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('Text', { x = 20, y = nY + 5, text = _L['Trigger Talk'], font = 27 }, true):pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.TALK_MONITOR] or {}
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY + 10, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bScreenHead, text = _L['Screen Head Alarm'],
			tip = _L['Requires MY_LifeBar loaded.'], tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bScreenHead', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bFullScreen', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'CHAT' then
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Alert Content'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szNote, w = 650, h = 25,
			onchange = function(text)
				local szText = LIB.TrimString(text)
				if szText == '' then
					data.szNote = nil
				else
					data.szNote = szText
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		nX = ui:append('Text', { x = 20, y = nY + 5, text = _L['Chat Content'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		_, nY = ui:append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szContent, w = 650, h = 85, multiline = true,
			onchange = function(text)
				data.szContent = text:gsub('\r', '')
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('Text', { x = nX, y = nY, text = _L['Tips:$me behalf of self, $team behalf of team, Only allow a time'], alpha = 200 }, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('Text', { x = 20, y = nY + 5, text = _L['Trigger Chat'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.CHAT_MONITOR] or {}
		nX = ui:append('WndCheckBox', {
			x = 30, y = nY + 10, checked = cfg.bTeamChannel, text = _L['Team Channel Alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bTeamChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bWhisperChannel, text = _L['Whisper Channel Alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bWhisperChannel', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bCenterAlarm, text = _L['Center Alarm'],
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bCenterAlarm', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bBigFontAlarm, text = _L['Big Font Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bBigFontAlarm', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bScreenHead, text = _L['Screen Head Alarm'],
			tip = _L['Requires MY_LifeBar loaded.'], tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			oncheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bScreenHead', bCheck)
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		if not LIB.IsShieldedVersion() then
			nX = ui:append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bFullScreen, text = _L['Full Screen Alarm'],
				oncheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bFullScreen', bCheck)
				end,
			}, true):autoWidth():pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	end
	if szType ~= 'TALK' and szType ~= 'CHAT' then
		nX, nY = ui:append('Text', { x = 20, y = nY, text = _L['Add Content'], font = 27 }, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('WndEditBox', {
			x = 30, y = nY, text = data.szNote, w = 650, h = 25, limit = 10,
			onchange = function(text)
				local szText = LIB.TrimString(text)
				if szText == '' then
					data.szNote = nil
				else
					data.szNote = szText
				end
			end,
		}, true):pos('BOTTOMRIGHT')
	end
	-- 倒计时
	nX, nY = ui:append('Text', { x = 20, y = nY + 5, text = _L['Countdown'], font = 27 }, true):pos('BOTTOMRIGHT')
	for k, v in ipairs(data.tCountdown or {}) do
		nX = ui:append('WndComboBox', {
			name = 'Countdown' .. k, x = 30, w = 155, h = 25, y = nY,
			color = v.key and { 255, 255, 0 },
			text = v.nClass == -1 and _L['Please Select Type'] or _L['Countdown TYPE ' ..  v.nClass],
			menu = function()
				local menu = {}
				if IsCtrlKeyDown() then
					insert(menu, { szOption = _L['Set Countdown Key'], rgb = { 255, 255, 0 } , fnAction = function()
						GetUserInput(_L['Countdown Key'], function(szKey)
							if LIB.TrimString(szKey) == '' then
								v.key = nil
							else
								v.key = LIB.TrimString(szKey)
							end
							D.OpenSettingPanel(data, szType)
						end, nil, nil, nil, v.key)
					end })
					insert(menu, { bDevide = true })
					insert(menu, { szOption = _L['Hold Countdown'], bCheck = true, bChecked = v.bHold, fnAction = function()
						v.bHold = not v.bHold
					end })
					if v.nClass == MY_TM_TYPE.NPC_FIGHT then
						insert(menu, { szOption = _L['Hold Fight Countdown'], bCheck = true, bChecked = v.bFightHold, fnAction = function()
							v.bFightHold = not v.bFightHold
						end })
					end

					insert(menu, { bDevide = true })
					insert(menu, { szOption = _L['Color Picker'], bDisable = true })
					-- Color Picker
					for i = 0, 8 do
						insert(menu, {
							bMCheck = true,
							bChecked = v.nFrame == i,
							fnAction = function()
								v.nFrame = i
							end,
							szIcon = PACKET_INFO.UITEX_ST,
							nFrame = i,
							szLayer = 'ICON_FILL',
						})
					end
				else
					insert(menu, { szOption = _L['Please Select Type'], bDisable = true, bChecked = v.nClass == -1 })
					insert(menu, { bDevide = true })
					if szType == 'BUFF' or szType == 'DEBUFF' then
						for kk, vv in ipairs({ MY_TM_TYPE.BUFF_GET, MY_TM_TYPE.BUFF_LOSE }) do
							insert(menu, { szOption = _L['Countdown TYPE ' .. vv], bMCheck = true, bChecked = v.nClass == vv, fnAction = function()
								SetCountdownType(v, vv, ui:children('#Countdown' .. k))
							end })
						end
					elseif szType == 'CASTING' then
						insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.SKILL_END], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.SKILL_END, fnAction = function()
							SetCountdownType(v, MY_TM_TYPE.SKILL_END, ui:children('#Countdown' .. k))
						end })
						-- if tSkillInfo and tSkillInfo.CastTime ~= 0 then
							insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.SKILL_BEGIN], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.SKILL_BEGIN, fnAction = function()
								SetCountdownType(v, MY_TM_TYPE.SKILL_BEGIN, ui:children('#Countdown' .. k))
							end })
						-- end
					elseif szType == 'NPC' then
						for kk, vv in ipairs({ MY_TM_TYPE.NPC_ENTER, MY_TM_TYPE.NPC_LEAVE, MY_TM_TYPE.NPC_ALLLEAVE, MY_TM_TYPE.NPC_FIGHT, MY_TM_TYPE.NPC_DEATH, MY_TM_TYPE.NPC_ALLDEATH, MY_TM_TYPE.NPC_LIFE, --[[MY_TM_TYPE.NPC_MANA]] }) do
							insert(menu, { szOption = _L['Countdown TYPE ' .. vv], bMCheck = true, bChecked = v.nClass == vv, fnAction = function()
								SetCountdownType(v, vv, ui:children('#Countdown' .. k))
								if vv == MY_TM_TYPE.NPC_LIFE or vv == MY_TM_TYPE.NPC_MANA then
									LIB.Alert(_L['Npc Life/Mana Alarm, different format, Recommended reading Help!'])
								end
							end })
						end
					elseif szType == 'DOODAD' then
						for kk, vv in ipairs({ MY_TM_TYPE.DOODAD_ENTER, MY_TM_TYPE.DOODAD_LEAVE, MY_TM_TYPE.DOODAD_ALLLEAVE }) do
							insert(menu, { szOption = _L['Countdown TYPE ' .. vv], bMCheck = true, bChecked = v.nClass == vv, fnAction = function()
								SetCountdownType(v, vv, ui:children('#Countdown' .. k))
							end })
						end
					elseif szType == 'TALK' then
						insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.TALK_MONITOR], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.TALK_MONITOR, fnAction = function()
							SetCountdownType(v, MY_TM_TYPE.TALK_MONITOR, ui:children('#Countdown' .. k))
						end })
					elseif szType == 'CHAT' then
						insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.CHAT_MONITOR], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.CHAT_MONITOR, fnAction = function()
							SetCountdownType(v, MY_TM_TYPE.CHAT_MONITOR, ui:children('#Countdown' .. k))
						end })
					end
				end
				return menu
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('Box', {
			x = nX + 5, y = nY, w = 24, h = 24, icon = v.nIcon or nIcon,
			hover = function(bHover) this:SetObjectMouseOver(bHover) end,
			onclick = function()
				local box = this
				UI.OpenIconPanel(function(nIcon)
					v.nIcon = nIcon
					box:SetObjectIcon(nIcon)
				end)
			end,
		}, true):pos('BOTTOMRIGHT')
		local bLife = v.nClass ~= MY_TM_TYPE.NPC_LIFE and v.nClass ~= MY_TM_TYPE.NPC_MANA and tonumber(v.nTime)
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY - 2, text = _L['TC'], color = GetMsgFontColor('MSG_TEAM', true), checked = v.bTeamChannel,
			oncheck = function(bCheck)
				v.bTeamChannel = bCheck and true or nil
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		ui:append('WndEditBox', {
			name = 'CountdownName' .. k, x = nX + 5, y = nY, w = 295, h = 25, text = v.szName,
			visible = bLife or false,
			onchange = function(szName)
				v.szName = szName
			end,
		}, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndEditBox', {
			name = 'CountdownTime' .. k, x = nX + 5 + (bLife and 300 or 0), y = nY, w = bLife and 100 or 400, h = 25,
			text = v.nTime, color = (v.nClass ~= MY_TM_TYPE.NPC_LIFE and not CheckCountdown(v.nTime)) and { 255, 0, 0 },
			onchange = function(szNum)
				v.nTime = UI_tonumber(szNum, szNum)
				local edit = ui:children('#CountdownTime' .. k)
				if szNum == '' then
					return
				end
				if v.nClass == MY_TM_TYPE.NPC_LIFE or v.nClass == MY_TM_TYPE.NPC_MANA then
					return
				else
					if tonumber(szNum) then
						if this:GetW() > 200 then
							local x, y = edit:pos()
							edit:pos(x + 300, y):size(100, 25):color(255, 255, 255)
							ui:children('#CountdownName' .. k):visible(true):text(v.szName or g_tStrings.CHAT_NAME)
						end
					else
						if CheckCountdown(szNum) then
							local x, y = this:GetAbsPos()
							local w, h = this:GetSize()
							local xml = { GetFormatText(_L['Countdown Preview'] .. '\n', 0, 255, 255, 0) }
							for k, v in ipairs(CheckCountdown(szNum)) do
								insert(xml, GetFormatText(v.nTime .. ' - ' .. v.szName .. '\n'))
							end
							OutputTip(concat(xml), 300, { x, y, w, h }, 1, true, 'MY_TeamMon')
							edit:color(255, 255, 255)
						else
							HideTip()
							edit:color(255, 0, 0)
						end
						if this:GetW() < 200 then
							local x, y = edit:pos()
							edit:pos(x - 300, y):size(400, 25)
							ui:children('#CountdownName' .. k):visible(false)
						end
					end
				end
			end,
		}, true):pos('BOTTOMRIGHT')
		nX = ui:append('WndEditBox', {
			x = nX + 5, y = nY, w = 30, h = 25,
			text = v.nRefresh, edittype = 0,
			onchange = function(szNum)
				v.nRefresh = UI_tonumber(szNum)
			end,
		}, true):pos('BOTTOMRIGHT')
		nX, nY = ui:append('Image', {
			x = nX + 5, y = nY, w = 26, h = 26,
			image = file, imageframe = 86,
			hover = function(bIn)
				if bIn then
					this:SetFrame(87)
				else
					this:SetFrame(86)
				end
			end,
			onclick = function()
				if v.nClass ~= -1 then
					local class = v.key and MY_TM_TYPE.COMMON or v.nClass
					if data.dwID then
						FireUIEvent('MY_TM_ST_DEL', class, v.key or (k .. '.'  .. data.dwID .. '.' .. (data.nLevel or 0)), true) -- try kill
					else
						FireUIEvent('MY_TM_ST_DEL', class, v.key or (data.nIndex .. '.' .. k), true) -- try kill
					end
				end
				if #data.tCountdown == 1 then
					data.tCountdown = nil
				else
					remove(data.tCountdown, k)
				end
				D.OpenSettingPanel(data, szType)
			end,
		}, true):pos('BOTTOMRIGHT')
	end
	nX = ui:append('WndButton2', {
		x = 30, y = nY + 10, text = _L['Add Countdown'],
		enable = not (data.tCountdown and #data.tCountdown > 10),
		onclick = function()
			data.tCountdown = data.tCountdown or {}
			local icon = nIocn or 13
			if szType == 'NPC' then	icon = 13 end
			insert(data.tCountdown, { nTime = _L['10,Countdown Name;25,Countdown Name'], nClass = -1, nIcon = icon })
			D.OpenSettingPanel(data, szType)
		end,
	}, true):pos('BOTTOMRIGHT')
	-- nX = ui:append('WndButton2', {
	-- 	x = 640, y = nY + 10, text = g_tStrings.HELP_PANEL,
	-- 	onclick = function()
	-- 		OpenInternetExplorer('https://github.com/luckyyyyy/JH/blob/master/JH_DBM/README.md')
	-- 	end,
	-- }, true):pos('BOTTOMRIGHT')
	nY = nY + 35
	ui:append('WndButton2', {
		x = 335, y = nY + 10, text = g_tStrings.STR_FRIEND_DEL, color = { 255, 0, 0 },
		onclick = function()
			LIB.Confirm(_L['Sure to delete?'], function()
				D.RemoveData(data.dwMapID, data.nIndex, szName or _L['This data'])
			end)
		end,
	})
	nY = nY + 40
	local w, h = ui:size()
	ui:size(w, nY + 25):anchor(MY_TMUI_PANEL_ANCHOR)
end

function D.UpdateAnchor(frame)
	local a = MY_TMUI_ANCHOR
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	end
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_TeamMon_UI')
end

D.IsOpened = D.GetFrame

function D.TogglePanel()
	if D.IsOpened() then
		D.ClosePanel()
	else
		D.OpenPanel()
	end
end
function D.OpenPanel(szType)
	if not D.IsOpened() then
		if szType then
			MY_TMUI_SELECT_TYPE = szType
		end
		Wnd.OpenWindow(MY_TMUI_INIFILE, 'MY_TeamMon_UI')
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function D.ClosePanel()
	if D.IsOpened() then
		FireUIEvent('MY_TMUI_FREECACHE')
		Wnd.CloseWindow(D.GetFrame())
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
		LIB.RegisterEsc('MY_TeamMon')
	end
end

LIB.RegisterEvent('MY_TMUI_FREECACHE', function()
	MY_TMUI_SEARCH_CACHE = {}
end)
LIB.RegisterAddonMenu({ szOption = _L['MY_TeamMon'], fnAction = D.TogglePanel })
LIB.RegisterHotKey('MY_TeamMon_UI', _L['Open MY_TeamMon Panel'], D.TogglePanel)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				OpenPanel       = D.OpenPanel,
				ClosePanel      = D.ClosePanel,
				IsOpened        = D.GetFrame,
				TogglePanel     = D.TogglePanel,
				OpenImportPanel = D.OpenImportPanel,
				OpenExportPanel = D.OpenExportPanel,
			},
		},
	},
}
MY_TeamMon_UI = LIB.GeneGlobalNS(settings)
end
