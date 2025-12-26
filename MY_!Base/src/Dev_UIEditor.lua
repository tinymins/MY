--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : UI查看器
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/UIEditor')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. '/lang/Dev/')
--------------------------------------------------------------------------------

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local O = {}
local D = {}
local UI_INIFILE = X.PACKET_INFO.FRAMEWORK_ROOT .. '/ui/Dev_UIEditor.ini'
local FRAME_NAME = X.NSFormatString('{$NS}Dev_UIEditor')
local EL_NAME = X.NSFormatString('{$NS}_El')

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
		table.insert(tab, dat)
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
		table.insert(tab, dat)
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

do
local nIndex = 0
function D.OnFrameCreate()
	nIndex = nIndex + 1
	this:SetName(FRAME_NAME .. '#' .. nIndex)
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
end

do
local nUpdateTime = 0
function D.OnFrameBreathe()
	if GetTime() - nUpdateTime > 500 then
		local elRoot = Station.Lookup(this.szTreePath)
		if elRoot and elRoot ~= this.elRoot then
			D.SetElement(this, elRoot)
		else
			local handle, el = this.hList, nil
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

function D.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		this:SetPoint(this.anchor.s, 0, 0, this.anchor.r, this.anchor.x, this.anchor.y)
	end
end

function D.OnFrameDragEnd()
	this.anchor = GetFrameAnchor(this)
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Select' then
		local menu = D.GetMenu(this:GetRoot())
		local handle = this:Lookup('', '')
		local nX, nY = handle:GetAbsPos()
		local nW, nH = handle:GetSize()
		menu.nMiniWidth = handle:GetW()
		menu.x = nX
		menu.y = nY + nH
		menu.szLayer = 'Topmost2'
		X.UI.PopupMenu(menu)
	elseif name == 'Btn_Close' then
		X.UI.CloseFrame(this:GetRoot())
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

function D.OnItemLButtonClick()
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
			if not _G[EL_NAME] then
				_G[EL_NAME] = setmetatable({}, {
					__call = function(t, k)
						return t[1]
					end,
				})
			end
			_G[EL_NAME][1] = el
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
			edit:SetText(GetPureText(table.concat(D.GetTipInfo(el))))
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

function D.OnItemMouseEnter()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'TreeLeaf_Node' or name == 'TreeLeaf_Content' then
		local el = this.dat.___id
		if el and el:IsValid() then
			local szXml = table.concat(D.GetTipInfo(el))
			local x, y = Cursor.GetPos()
			local w, h = 40, 40
			OutputTip(szXml, 435, { x, y, w, h }, ALW.RIGHT_LEFT):StartMoving()
			return D.SetUIPos(frame, el)
		end
	end
end
-- ReloadUIAddon()
function D.OnItemMouseLeave()
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
		table.insert(t, 'nil')
	elseif szType == 'number' then
		table.insert(t, tostring(var))
	elseif szType == 'string' then
		table.insert(t, string.format('%q', var))
	elseif szType == 'function' then
		-- local s = string.dump(var)
		-- table.insert(t, 'loadstring('')
		-- -- 'string slice too long'
		-- for i = 1, #s, 2000 do
		-- 	table.insert(t, table.concat({'', string.byte(s, i, i + 2000 - 1)}, '\\'))
		-- end
		-- table.insert(t, '')')
		table.insert(t, tostring(var))
	elseif szType == 'boolean' then
		table.insert(t, tostring(var))
	elseif szType == 'table' then
		table.insert(t, '{')
		local s_tab_equ = '='
		if indent then
			s_tab_equ = ' = '
			if not X.IsEmpty(var) then
				table.insert(t, '\n')
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
					table.insert(t, string.rep(indent, level + 1))
				end
				-- insert key
				if nohash then -- pure list: do not need a key
				elseif type(key) == 'string' and key:find('^[a-zA-Z_][a-zA-Z0-9_]*$') then -- a = val
					table.insert(t, key)
					table.insert(t, s_tab_equ)
				else -- [10010] = val -- ['.start with or contains special char'] = val
					table.insert(t, '[')
					table.insert(t, table_r(key, level + 1, indent))
					table.insert(t, ']')
					table.insert(t, s_tab_equ)
				end
				-- insert value
				table.insert(t, table_r(val, level + 1, indent))
				table.insert(t, ',')
				if indent then
					table.insert(t, '\n')
				end
				lastkey, lastval, hasval = key, val, true
			end
		until not key
		-- remove last `,` if no indent
		if not indent and hasval then
			table.remove(t)
		end
		-- insert `}` with indent
		if indent and not X.IsEmpty(var) then
			table.insert(t, string.rep(indent, level))
		end
		table.insert(t, '}')
	else --if (szType == 'userdata') then
		table.insert(t, '"')
		table.insert(t, tostring(var))
		table.insert(t, '"')
	end
	return table.concat(t)
end

local function var2str(var, indent, level)
	return table_r(var, level or 0, indent)
end

function D.InsertTip(aXml, szTitle, szValue)
	table.insert(aXml, GetFormatText(tostring(szTitle), 67))
	table.insert(aXml, GetFormatText(tostring(szValue) .. '\n', 44))
end

function D.GetTipInfo(el)
	-- 通用组件信息
	local szType = el:GetType()
	local aXml = {}
	table.insert(aXml, GetFormatText('[' .. el:GetName() .. ']\n', 65))
	D.InsertTip(aXml, 'Type: ', szType)
	D.InsertTip(aXml, 'Visible: ', tostring(el:IsVisible()))
	D.InsertTip(aXml, 'Size: ', table.concat({ el:GetSize() }, ', '))
	D.InsertTip(aXml, 'RelPos: ', table.concat({ el:GetRelPos() }, ', '))
	D.InsertTip(aXml, 'AbsPos: ', table.concat({ el:GetAbsPos() }, ', '))
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
		D.InsertTip(aXml, 'FontColor: ', table.concat({ el:GetFontColor() }, ', '))
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
		D.InsertTip(aXml, 'ShadowColor: ', table.concat({ el:GetShadowColor() }, ', '))
		D.InsertTip(aXml, 'ColorRGB: ', table.concat({ el:GetColorRGB() }, ', '))
		D.InsertTip(aXml, 'IsTriangleFan: ', tostring(el:IsTriangleFan()))
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'Animate' then
		D.InsertTip(aXml, 'IsFinished: ', tostring(el:IsFinished()))
		D.InsertTip(aXml, 'Index: ', el:GetIndex())
	elseif szType == 'Box' then
		D.InsertTip(aXml, 'BoxIndex: ', el:GetBoxIndex())
		-- D.InsertTip(aXml, 'Object: ', hElem:GetObject())
		D.InsertTip(aXml, 'ObjectType: ', el:GetObjectType())
		D.InsertTip(aXml, 'ObjectData: ', table.concat({ el:GetObjectData() }, ', '))
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
	table.insert(aXml, GetFormatText('\n ---------- D Table --------- \n\n', 67))
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
			table.insert(aXml, GetFormatText('\n ---------- D Global --------- \n\n', 67))
			for k, v in pairs(G[el:GetName()]) do
				D.InsertTip(aXml, k .. ': ', tostring(v))
				if debug and type(v) == 'function' then
					local d = debug.getinfo(v)
					local t = {}
					for g, v in pairs(d) do
						t[g] = v;
					end
					t.func = nil
					table.insert(aXml, GetFormatText(X.EncodeLUAData(t, '\t') .. '\n', 44))
				end
			end
		end
	end
	return aXml
end

function D.CreateFrame()
	return X.UI.OpenFrame(UI_INIFILE, FRAME_NAME)
end

function D.SetElement(frame, el)
	D.UpdateTree(frame, el)
	frame.szTreePath = el:GetTreePath()
	frame:Lookup('Btn_Select', 'Text_Select'):SetText(el:GetTreePath())
end

function D.GetMenu(frame)
	local menu = {}
	for k, v in ipairs({ 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' }) do
		table.insert(menu, { szOption = v })
		local frmLayer = Station.Lookup(v)
		local frmIter = frmLayer and frmLayer:GetFirstChild()
		while frmIter do
			local el = frmIter
			table.insert(menu[#menu], {
				szOption = frmIter:GetName(),
				bCheck   = true,
				bChecked = frmIter:IsVisible(),
				rgb      = frmIter:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
				fnAction = function()
					D.SetElement(frame, el)
					X.UI.ClosePopupMenu()
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

local SHARED_MEMORY = X.SHARED_MEMORY
if not SHARED_MEMORY.UI_EDITOR then
	TraceButton_AppendAddonMenu({function()
		for _, f in ipairs(SHARED_MEMORY.UI_EDITOR) do
			local v = f()
			if v then
				return v
			end
		end
	end})
	SHARED_MEMORY.UI_EDITOR = {}
end
table.insert(SHARED_MEMORY.UI_EDITOR, function()
	if not X.IsDebugging('Dev_UIEditor') then
		return
	end
	return {{ szOption = _L['Dev_UIEditor'], fnAction = D.CreateFrame }}
end)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
