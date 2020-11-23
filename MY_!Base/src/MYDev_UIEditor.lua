--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : UI查看器
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_!Base'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_UIEditor'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local UI_INIFILE = PLUGIN_ROOT .. '/ui/MYDev_UIEditor.ini'
local O = {}
local D = {}

-- stack overflow
local function GetUIStru(el)
	local data = {}
	local function GetInfo(el)
		local szType = el:GetType()
		local szName = el:GetName()
		local bIsWnd = szType:sub(1, 3) == 'Wnd'
		local bChild, hChildItem
		if bIsWnd then
			bChild     = el:GetFirstChild() ~= nil
			hChildItem = el:Lookup('', '')
		elseif szType == 'Handle' or szType == 'TreeLeaf' then
			bChild = el:Lookup(0) ~= nil
		end
		local dat = {
			___id  = el, -- ui metatable
			aPath  = { el:GetTreePath() },
			szType = szType,
			szName = szName,
			aChild = (bChild or hChildItem) and {} or nil
		}
		return dat, bIsWnd, bChild, hChildItem
	end
	local function GetItemStru(el, tab)
		local dat, bIsWnd, bChild = GetInfo(el)
		insert(tab, dat)
		if bChild then
			local i = 0
			while el:Lookup(i) do
				local frame = el:Lookup(i)
				GetItemStru(frame, dat.aChild)
				i = i + 1
			end
		end
	end
	local function GetWinStru(el, tab)
		local dat, bIsWnd, bChild, hChildItem = GetInfo(el)
		insert(tab, dat)
		if hChildItem then
			GetItemStru(hChildItem, dat.aChild)
		end
		if bChild then
			local aChild = tab[#tab]
			local frame = el:GetFirstChild()
			while frame do
				local dat, bIsWnd = GetInfo(frame)
				if bIsWnd then
					GetWinStru(frame, aChild.aChild)
				else
					GetItemStru(frame, aChild.aChild)
				end
				frame = frame:GetNext()
			end
		end
	end
	local dat, bIsWnd, bChild = GetInfo(el)
	if bIsWnd then
		GetWinStru(el, data)
	else
		GetItemStru(el, data)
	end
	return data
end

MYDev_UIEditor = class()

function MYDev_UIEditor.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this.anchor   = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
	this.hNode    = this:CreateItemData(UI_INIFILE, 'TreeLeaf_Node')
	this.hContent = this:CreateItemData(UI_INIFILE, 'TreeLeaf_Content')
	this.hList    = this:Lookup('WndScroll_Tree', '')
	this.hUIPos   = this:Lookup('', 'Image_UIPos')
	this.hList:Clear()
	this:ShowWhenUIHide()
	this:SetPoint(this.anchor.s, 0, 0, this.anchor.r, this.anchor.x, this.anchor.y)
end

do
local nUpdateTime = 0
function MYDev_UIEditor.OnFrameBreathe()
	if GetTime() - nUpdateTime > 500 then
		local elRoot = Station.Lookup(this.szTreePath)
		if elRoot and elRoot ~= this.elRoot then
			D.SetElement(this, elRoot)
		else
			local handle, el = this.hList
			for i = 0, handle:GetItemCount() - 1 do
				el = handle:Lookup(i)
				if el.dat and el.dat.___id and not el.dat.___id:IsValid() then
					D.UpdateTree(this)
					break
				end
			end
			nUpdateTime = GetTime()
		end
	end
	-- this:BringToTop()
end
end

function MYDev_UIEditor.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		this:SetPoint(this.anchor.s, 0, 0, this.anchor.r, this.anchor.x, this.anchor.y)
	end
end

function MYDev_UIEditor.OnFrameDragEnd()
	this.anchor = GetFrameAnchor(this)
end

function MYDev_UIEditor.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Select' then
		local menu = D.GetMeun(this:GetRoot())
		local handle = this:Lookup('', '')
		local nX, nY = handle:GetAbsPos()
		local nW, nH = handle:GetSize()
		menu.nMiniWidth = handle:GetW()
		menu.x = nX
		menu.y = nY + nH
		menu.szLayer = 'Topmost2'
		UI.PopupMenu(menu)
	elseif name == 'Btn_Close' then
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Setting' then
		local frame = this:GetRoot()
		GetUserInput('', function(szTreePath)
			local el = szTreePath and Station.Lookup(szTreePath)
			if el then
				D.SetElement(frame, el)
			end
		end, nil, nil, nil, frame.szTreePath)
	end
end

function MYDev_UIEditor.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		local el = this.dat.___id
		if IsShiftKeyDown() then
			if el and el:IsValid() then
				el:SetVisible(not el:IsVisible())
			end
			return
		end
		if IsAltKeyDown() then
			if not MY_El then
				MY_El = setmetatable({}, {
					__call = function(t, k)
						return t[1]
					end,
				})
			end
			MY_El[1] = el
			return
		end
		if name == 'TreeLeaf_Node' then
			if this:IsExpand() then
				this:Collapse()
			else
				this:Expand()
			end
			this:GetParent():FormatAllItemPos()
		end
		if el and el:IsValid() then
			local frame = this:GetRoot()
			local edit = frame:Lookup('Edit_Log/Edit_Default')
			edit:SetText(GetPureText(concat(D.GetTipInfo(el))))
			edit:SetCaretPos(0)
			local elSel, tElSel = el, {}
			while elSel do
				tElSel[elSel] = true
				elSel = elSel:GetParent()
			end
			frame.tElSel = tElSel
		end
	end
end

function MYDev_UIEditor.OnItemMouseEnter()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		local el = this.dat.___id
		if el and el:IsValid() then
			local szXml = concat(D.GetTipInfo(el))
			local x, y = Cursor.GetPos()
			local w, h = 40, 40
			OutputTip(szXml, 435, { x, y, w, h }, ALW.RIGHT_LEFT):StartMoving()
			return D.SetUIPos(frame, el)
		end
	end
end
-- ReloadUIAddon()
function MYDev_UIEditor.OnItemMouseLeave()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		HideTip()
		return D.SetUIPos(frame)
	end
end

function D.SetUIPos(frame, el)
	local hUIPos = frame.hUIPos
	if el and el:IsValid() then
		local x, y = el:GetAbsPos()
		local w, h = el:GetSize()
		hUIPos:SetSize(w, h)
		hUIPos:SetAbsPos(x, y)
		hUIPos:Show()
		if el:IsVisible() then
			hUIPos:SetFrame(157)
		else
			hUIPos:SetFrame(158)
		end
	else
		hUIPos:Hide()
	end
end

local function table_r(var, level, indent)
	local t = {}
	local szType = type(var)
	if szType == 'nil' then
		insert(t, 'nil')
	elseif szType == 'number' then
		insert(t, tostring(var))
	elseif szType == 'string' then
		insert(t, string.format('%q', var))
	elseif szType == 'function' then
		-- local s = string.dump(var)
		-- insert(t, 'loadstring('')
		-- -- 'string slice too long'
		-- for i = 1, #s, 2000 do
		-- 	insert(t, concat({'', byte(s, i, i + 2000 - 1)}, '\\'))
		-- end
		-- insert(t, '')')
		insert(t, tostring(var))
	elseif szType == 'boolean' then
		insert(t, tostring(var))
	elseif szType == 'table' then
		insert(t, '{')
		local s_tab_equ = '='
		if indent then
			s_tab_equ = ' = '
			if not IsEmpty(var) then
				insert(t, '\n')
			end
		end
		local nohash = true
		local key, val, lastkey, lastval, hasval
		local tlist, thash = {}, {}
		repeat
			key, val = next(var, lastkey)
			if key then
				-- judge if this is a pure list table
				if nohash and (
					type(key) ~= 'number'
					or (lastval == nil and key ~= 1) -- first loop and index is not 1 : hash table
					or (lastkey and lastkey + 1 ~= key)
				) then
					nohash = false
				end
				-- process to insert to table
				-- insert indent
				if indent then
					insert(t, rep(indent, level + 1))
				end
				-- insert key
				if nohash then -- pure list: do not need a key
				elseif type(key) == 'string' and key:find('^[a-zA-Z_][a-zA-Z0-9_]*$') then -- a = val
					insert(t, key)
					insert(t, s_tab_equ)
				else -- [10010] = val -- ['.start with or contains special char'] = val
					insert(t, '[')
					insert(t, table_r(key, level + 1, indent))
					insert(t, ']')
					insert(t, s_tab_equ)
				end
				-- insert value
				insert(t, table_r(val, level + 1, indent))
				insert(t, ',')
				if indent then
					insert(t, '\n')
				end
				lastkey, lastval, hasval = key, val, true
			end
		until not key
		-- remove last `,` if no indent
		if not indent and hasval then
			remove(t)
		end
		-- insert `}` with indent
		if indent and not IsEmpty(var) then
			insert(t, rep(indent, level))
		end
		insert(t, '}')
	else --if (szType == 'userdata') then
		insert(t, '"')
		insert(t, tostring(var))
		insert(t, '"')
	end
	return concat(t)
end

local function var2str(var, indent, level)
	return table_r(var, level or 0, indent)
end

function D.InsertTip(aXml, szTitle, szValue)
	insert(aXml, GetFormatText(szTitle, 67))
	insert(aXml, GetFormatText(szValue .. '\n', 44))
end

function D.GetTipInfo(el)
	-- 通用组件信息
	local szType = el:GetType()
	local aXml = {}
	insert(aXml, GetFormatText('[' .. el:GetName() .. ']\n', 65))
	D.InsertTip(aXml, 'Type: ', szType)
	D.InsertTip(aXml, 'Visible: ', tostring(el:IsVisible()))
	D.InsertTip(aXml, 'Size: ', concat({ el:GetSize() }, ', '))
	D.InsertTip(aXml, 'RelPos: ', concat({ el:GetRelPos() }, ', '))
	D.InsertTip(aXml, 'AbsPos: ', concat({ el:GetAbsPos() }, ', '))
	local szPath1, szPath2 = el:GetTreePath()
	D.InsertTip(aXml, 'Path1: ', szPath1)
	if szPath2 then
		D.InsertTip(aXml, 'Path2: ', szPath2)
	end
	-- 分类组件信息
	if szType == 'Text' then
		D.InsertTip(aXml, 'FontScheme: ', el:GetFontScheme())
		D.InsertTip(aXml, 'Text: ', el:GetText())
		D.InsertTip(aXml, 'TextLen: ', el:GetTextLen())
		D.InsertTip(aXml, 'VAlign: ', el:GetVAlign())
		D.InsertTip(aXml, 'HAlign: ', el:GetHAlign())
		D.InsertTip(aXml, 'RowSpacing: ', el:GetRowSpacing())
		D.InsertTip(aXml, 'IsMultiLine: ', tostring(el:IsMultiLine()))
		D.InsertTip(aXml, 'IsCenterEachLine: ', tostring(el:IsCenterEachLine()))
		D.InsertTip(aXml, 'FontSpacing: ', el:GetFontSpacing())
		D.InsertTip(aXml, 'IsRichText: ', tostring(el:IsRichText()))
		D.InsertTip(aXml, 'FontScale: ', el:GetFontScale())
		D.InsertTip(aXml, 'FontID: ', el:GetFontID())
		D.InsertTip(aXml, 'FontColor: ', el:GetFontColor())
		D.InsertTip(aXml, 'FontBoder: ', el:GetFontBoder())
		D.InsertTip(aXml, 'FontProjection: ', el:GetFontProjection())
		D.InsertTip(aXml, 'TextExtent: ', el:GetTextExtent())
		D.InsertTip(aXml, 'TextPosExtent: ', el:GetTextPosExtent())
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'Image' then
		local szPath, nFrame = el:GetImagePath()
		D.InsertTip(aXml, 'Image: ', szPath or '')
		if nFrame then
			D.InsertTip(aXml, 'Frame: ', nFrame)
		end
		D.InsertTip(aXml, 'ImageType: ', el:GetImageType())
		D.InsertTip(aXml, 'ImageID: ', el:GetImageID())
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'Shadow' then
		D.InsertTip(aXml, 'ShadowColor: ', el:GetShadowColor())
		D.InsertTip(aXml, 'ColorRGB: ', concat({el:GetColorRGB(), ', '}))
		D.InsertTip(aXml, 'IsTriangleFan: ', tostring(el:IsTriangleFan()))
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'Animate' then
		D.InsertTip(aXml, 'IsFinished: ', tostring(el:IsFinished()))
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'Box' then
		D.InsertTip(aXml, 'BoxIndex: ', el:GetBoxIndex())
		-- D.InsertTip(aXml, 'Object: ', hElem:GetObject())
		D.InsertTip(aXml, 'ObjectType: ', el:GetObjectType())
		D.InsertTip(aXml, 'ObjectData: ', concat({el:GetObjectData()}, ', '))
		D.InsertTip(aXml, 'IsEmpty: ', tostring(el:IsEmpty()))
		if not el:IsEmpty() then
			D.InsertTip(aXml, 'IsObjectEnable: ', tostring(el:IsObjectEnable()))
			D.InsertTip(aXml, 'IsObjectCoolDown: ', tostring(el:IsObjectCoolDown()))
			D.InsertTip(aXml, 'IsObjectSelected: ', tostring(el:IsObjectSelected()))
			D.InsertTip(aXml, 'IsObjectMouseOver: ', tostring(el:IsObjectMouseOver()))
			D.InsertTip(aXml, 'IsObjectPressed: ', tostring(el:IsObjectPressed()))
			D.InsertTip(aXml, 'CoolDownPercentage: ', el:GetCoolDownPercentage())
			D.InsertTip(aXml, 'ObjectIcon: ', el:GetObjectIcon())
			D.InsertTip(aXml, 'OverText0: ', ('[Font]%s [Pos]%s [Text]%s'):format(el:GetOverTextFontScheme(0), el:GetOverTextPosition(0), el:GetOverText(0)))
			D.InsertTip(aXml, 'OverText1: ', ('[Font]%s [Pos]%s [Text]%s'):format(el:GetOverTextFontScheme(1), el:GetOverTextPosition(1), el:GetOverText(1)))
			D.InsertTip(aXml, 'OverText2: ', ('[Font]%s [Pos]%s [Text]%s'):format(el:GetOverTextFontScheme(2), el:GetOverTextPosition(2), el:GetOverText(2)))
			D.InsertTip(aXml, 'OverText3: ', ('[Font]%s [Pos]%s [Text]%s'):format(el:GetOverTextFontScheme(3), el:GetOverTextPosition(3), el:GetOverText(3)))
			D.InsertTip(aXml, 'OverText4: ', ('[Font]%s [Pos]%s [Text]%s'):format(el:GetOverTextFontScheme(4), el:GetOverTextPosition(4), el:GetOverText(4)))
		end
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'WndButton' then
		D.InsertTip(aXml, 'ImagePath: ', el:GetAnimatePath())
		D.InsertTip(aXml, 'Normal: ', el:GetAnimateGroupNormal())
		D.InsertTip(aXml, 'Over: ', el:GetAnimateGroupMouseOver())
		D.InsertTip(aXml, 'Down: ', el:GetAnimateGroupMouseDown())
		D.InsertTip(aXml, 'Disable: ', el:GetAnimateGroupDisable())
	end
	-- 数据绑定信息
	insert(aXml, GetFormatText('\n ---------- D Table --------- \n\n', 67))
	for k, v in pairs(el) do
		D.InsertTip(aXml, k .. ': ', tostring(v))
	end
	-- 全局绑定信息
	if szType == 'WndFrame' then
		local G
		if el:IsAddOn() then
			G = _G.GetAddonEnv and _G.GetAddonEnv() or _G
		else
			G = _G.GetInsideEnv and _G.GetInsideEnv() or _G
		end
		if G and G[el:GetName()] then
			insert(aXml, GetFormatText('\n ---------- D Global --------- \n\n', 67))
			for k, v in pairs(G[el:GetName()]) do
				D.InsertTip(aXml, k .. ': ', tostring(v))
				if debug and type(v) == 'function' then
					local d = debug.getinfo(v)
					local t = {}
					for g, v in pairs(d) do
						t[g] = v;
					end
					t.func = nil
					insert(aXml, GetFormatText(EncodeLUAData(t, '\t') .. '\n', 44))
				end
			end
		end
	end
	return aXml
end

do
local nIndex = 0
function D.CreateFrame()
	nIndex = nIndex + 1
	return Wnd.OpenWindow(UI_INIFILE, 'MYDev_UIEditor#' .. nIndex)
end
end

function D.SetElement(frame, el)
	D.UpdateTree(frame, el)
	frame.szTreePath = el:GetTreePath()
	frame:Lookup('Btn_Select', 'Text_Select'):SetText(el:GetTreePath())
end

function D.GetMeun(frame)
	local menu = {}
	for k, v in ipairs({ 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' })do
		insert(menu, { szOption = v })
		local frmIter = Station.Lookup(v):GetFirstChild()
		while frmIter do
			local el = frmIter
			insert(menu[#menu], {
				szOption = frmIter:GetName(),
				bCheck   = true,
				bChecked = frmIter:IsVisible(),
				rgb      = frmIter:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
				fnAction = function()
					D.SetElement(frame, el)
					UI.ClosePopupMenu()
				end,
				fnMouseLeave = function()
					return D.SetUIPos(frame)
				end,
				fnMouseEnter = function()
					return D.SetUIPos(frame, el)
				end,
			})
			frmIter = frmIter:GetNext()
		end
	end
	return menu
end

do
local function AppendTree(handle, tpls, data, i)
	for k, v in ipairs(data) do
		local h
		if v.aChild then
			h = handle:AppendItemFromData(tpls.hNode)
		else
			h = handle:AppendItemFromData(tpls.hContent)
		end
		local txt = h:Lookup(0)
		txt:SetText(v.szName)
		h:SetIndent(i)
		h:FormatAllItemPos()
		h.dat = v
		if v.aChild then
			AppendTree(handle, tpls, v.aChild, i + 1)
		end
	end
end
function D.UpdateTree(frame, elRoot, bDropSel)
	if not elRoot then
		elRoot = frame.elRoot
	end
	local data   = GetUIStru(elRoot)
	local handle = frame.hList
	frame.elRoot = elRoot
	handle:Clear()
	AppendTree(handle, frame, data, 0)
	-- 恢复展开状态
	local el, tElSel = nil, frame.tElSel or {}
	for i = 0, handle:GetItemCount() - 1 do
		el = handle:Lookup(i)
		if (not bDropSel and el.dat and el.dat.___id and tElSel[el.dat.___id]) or i == 0 then
			el:Expand()
		end
	end
	handle:FormatAllItemPos()
end
end

TraceButton_AppendAddonMenu({function()
	if not LIB.IsDebugClient('MYDev_UIEditor') then
		return
	end
	return {{ szOption = _L['MYDev_UIEditor'], fnAction = D.CreateFrame }}
end})
