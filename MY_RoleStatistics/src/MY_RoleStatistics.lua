--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色统计框架
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------

local O = {}
local D = {
	aModule = {},
}
local Framework = {}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_RoleStatistics.ini'
local SZ_MOD_INI = PLUGIN_ROOT .. '/ui/MY_RoleStatistics.Mod.ini'

function D.Open(szModule)
	local frame = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics')
	frame:BringToTop()
	D.ActivePage(frame, szModule or 1, true)
end

function D.Close()
	Wnd.CloseWindow('MY_RoleStatistics')
end

function D.IsOpened()
	return Station.Lookup('Normal/MY_RoleStatistics')
end

function D.Toggle()
	if D.IsOpened() then
		D.Close()
	else
		D.Open()
	end
end

-- 注册子模块
function D.RegisterModule(szID, szName, tModule)
	for i, v in X.ipairs_r(D.aModule) do
		if v.szID == szID then
			table.remove(D.aModule, i)
		end
	end
	if szName and tModule then
		table.insert(D.aModule, {
			szID = szID,
			szName = szName,
			tModule = tModule,
		})
	end
	if D.IsOpened() then
		D.Close()
		D.Open()
	end
end

-- 初始化主界面 绘制分页按钮
function D.InitPageSet(frame)
	frame.bInitPageset = true
	local pageset = frame:Lookup('PageSet_All')
	for i, m in ipairs(D.aModule) do
		local frameMod = Wnd.OpenWindow(SZ_MOD_INI, 'MY_RoleStatisticsMod')
		local checkbox = frameMod:Lookup('PageSet_Total/WndCheck_Default')
		local page = frameMod:Lookup('PageSet_Total/Page_Default')
		checkbox:ChangeRelation(pageset, true, true)
		page:ChangeRelation(pageset, true, true)
		Wnd.CloseWindow(frameMod)
		pageset:AddPage(page, checkbox)
		checkbox:Show()
		checkbox:Lookup('', 'Text_CheckDefault'):SetText(m.szName)
		checkbox:SetRelX(checkbox:GetRelX() + checkbox:GetW() * (i - 1))
		checkbox.nIndex = i
		page.nIndex = i
	end
	frame.bInitPageset = nil
end

function D.ActivePage(frame, szModule, bFirst)
	local pageset = frame:Lookup('PageSet_All')
	local pageActive = pageset:GetActivePage()
	local nActiveIndex, nToIndex = pageActive.nIndex, nil
	for i, m in ipairs(D.aModule) do
		if m.szID == szModule or i == szModule then
			nToIndex = i
		end
	end
	if bFirst and not nToIndex then
		nToIndex = 1
	end
	if nToIndex then
		if nToIndex == nActiveIndex then
			local _this = this
			this = pageset
			Framework.OnActivePage()
			this = _this
		else
			pageset:ActivePage(nToIndex - 1)
		end
	end
end

function Framework.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		D.Close()
	elseif name == 'Btn_Option' then
		local menu = {}
		local tFloatEntryMenu = {
			szOption = _L['Float panel'],
			fnMouseEnter = function()
				local nX, nY = this:GetAbsX(), this:GetAbsY()
				local nW, nH = this:GetW(), this:GetH()
				OutputTip(GetFormatText(_L['Enable float panel on sprint/bag/character panel.'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.TOP_BOTTOM)
			end,
			fnMouseLeave = function()
				HideTip()
			end,
		}
		for _, m in ipairs(D.aModule) do
			if m and m.tModule.szFloatEntry then
				table.insert(tFloatEntryMenu, {
					szOption = m.szName,
					bCheck = true, bChecked = X.Get(_G, m.tModule.szFloatEntry),
					fnAction = function()
						X.Set(_G, m.tModule.szFloatEntry, not X.Get(_G, m.tModule.szFloatEntry))
					end,
				})
			end
		end
		if #tFloatEntryMenu > 0 then
			table.insert(menu, tFloatEntryMenu)
		end
		local tSaveDBMenu = { szOption = _L['Save DB'] }
		for _, m in ipairs(D.aModule) do
			if m and m.tModule.szSaveDB then
				table.insert(tSaveDBMenu, {
					szOption = m.szName,
					bCheck = true, bChecked = X.Get(_G, m.tModule.szSaveDB),
					fnAction = function()
						X.Set(_G, m.tModule.szSaveDB, not X.Get(_G, m.tModule.szSaveDB))
					end,
				})
			end
		end
		if #tSaveDBMenu > 0 then
			table.insert(menu, tSaveDBMenu)
		end
		if #menu > 0 then
			local nX, nY = this:GetAbsPos()
			local nW, nH = this:GetSize()
			menu.nMiniWidth = nW
			menu.x = nX
			menu.y = nY + nH
			UI.PopupMenu(menu)
		end
	end
end

function Framework.OnActivePage()
	if this:GetRoot().bInitPageset then
		return
	end
	local name = this:GetName()
	if name == 'PageSet_All' then
		local page = this:GetActivePage()
		if page.nIndex then
			local m = D.aModule[page.nIndex]
			if not page.bInit then
				if m and m.tModule.OnInitPage then
					local _this = this
					this = page
					m.tModule.OnInitPage()
					this = _this
				end
				page.bInit = true
			end
			if m and m.tModule.OnActivePage then
				local _this = this
				this = page
				m.tModule.OnActivePage()
				this = _this
			end
		end
	end
end

function Framework.OnFrameCreate()
	D.InitPageSet(this)
	this:BringToTop()
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:Lookup('', 'Text_Title'):SetText(X.PACKET_INFO.NAME .. ' - ' .. _L['MY_RoleStatistics'])
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function Framework.OnFrameDestroy()
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

-- 全局广播模块事件
for _, szEvent in ipairs({
	'OnFrameCreate',
	'OnFrameDestroy',
	'OnFrameBreathe',
	'OnFrameRender',
	'OnFrameDragEnd',
	'OnFrameDragSetPosEnd',
	'OnEvent',
}) do
	D[szEvent] = function(...)
		if Framework[szEvent] then
			Framework[szEvent](...)
		end
		local page = this:Lookup('PageSet_All'):GetFirstChild()
		while page do
			if page:GetName() == 'Page_Default' and page.bInit then
				local m = D.aModule[page.nIndex]
				if m and m.tModule[szEvent] then
					local _this = this
					this = page
					m.tModule[szEvent](...)
					this = _this
				end
			end
			page = page:GetNext()
		end
	end
end

-- 根据元素位置转发对应模块事件
for _, szEvent in ipairs({
	'OnSetFocus',
	'OnKillFocus',
	'OnItemLButtonDown',
	'OnItemMButtonDown',
	'OnItemRButtonDown',
	'OnItemLButtonUp',
	'OnItemMButtonUp',
	'OnItemRButtonUp',
	'OnItemLButtonClick',
	'OnItemMButtonClick',
	'OnItemRButtonClick',
	'OnItemMouseEnter',
	'OnItemMouseLeave',
	'OnItemRefreshTip',
	'OnItemMouseWheel',
	'OnItemLButtonDrag',
	'OnItemLButtonDragEnd',
	'OnLButtonDown',
	'OnLButtonUp',
	'OnLButtonClick',
	'OnLButtonHold',
	'OnMButtonDown',
	'OnMButtonUp',
	'OnMButtonClick',
	'OnMButtonHold',
	'OnRButtonDown',
	'OnRButtonUp',
	'OnRButtonClick',
	'OnRButtonHold',
	'OnMouseEnter',
	'OnMouseLeave',
	'OnScrollBarPosChanged',
	'OnEditChanged',
	'OnEditSpecialKeyDown',
	'OnCheckBoxCheck',
	'OnCheckBoxUncheck',
	'OnActivePage',
}) do
	D[szEvent] = function(...)
		local szPrefix = 'Normal/MY_Statistics/PageSet_All/Page_Default'
		local page, nLimit = this, 50
		while page and page:GetName() ~= 'Page_Default' and page:GetTreePath() ~= szPrefix do
			if nLimit > 0 then
				page = page:GetParent()
				nLimit = nLimit - 1
			else
				page = nil
			end
		end
		if page and page ~= this then
			local m = D.aModule[page.nIndex]
			if m and m.tModule[szEvent] then
				return m.tModule[szEvent](...)
			end
		else
			if Framework[szEvent] then
				return Framework[szEvent](...)
			end
		end
	end
end

--------------------------------------------------------
-- Global exports
--------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics',
	exports = {
		{
			fields = {
				Open = D.Open,
				Close = D.Close,
				IsOpened = D.IsOpened,
				Toggle = D.Toggle,
				RegisterModule = D.RegisterModule,
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_RoleStatistics = X.CreateModule(settings)
end

do
local menu = {
	szOption = _L['MY_RoleStatistics'],
	fnAction = function() D.Toggle() end,
}
X.RegisterAddonMenu('MY_RoleStatistics', menu)
end
X.RegisterHotKey('MY_RoleStatistics', _L['Open/Close MY_RoleStatistics'], D.Toggle, nil)

--------------------------------------------------------------------------
-- 设置界面
--------------------------------------------------------------------------
local PS = { nPriority = 5 }
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local nPaddingX, nPaddingY = 25, 25
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()

	ui:Append('WndButton', {
		x = nW - 165, y = nY, w = 150, h = 38,
		text = _L['Open panel'],
		buttonStyle = 'SKEUOMORPHISM_LACE_BORDER',
		onClick = D.Open,
	})

	local aFloatEntry, aSaveDB = {}, {}
	for _, m in ipairs(D.aModule) do
		if m and m.tModule.szFloatEntry then
			table.insert(aFloatEntry, { szName = m.szName, szKey = m.tModule.szFloatEntry })
		end
		if m and m.tModule.szSaveDB then
			table.insert(aSaveDB, { szName = m.szName, szKey = m.tModule.szSaveDB })
		end
	end
	if #aFloatEntry > 0 then
		nX = nPaddingX
		ui:Append('Text', { x = nX, y = nY, text = _L['Float panel'], font = 27 })
		nX = nX + 10
		nY = nY + 35

		for _, p in ipairs(aFloatEntry) do
			nX = nX + ui:Append('WndCheckBox', {
				x = nX, y = nY, w = 200,
				text = p.szName, checked = X.Get(_G, p.szKey),
				onCheck = function(bChecked)
					X.Set(_G, p.szKey, bChecked)
				end,
			}):AutoWidth():Width() + 5
		end
		nY = nY + 40
	end
	if #aSaveDB > 0 then
		nX = nPaddingX
		ui:Append('Text', { x = nX, y = nY, text = _L['Save DB'], font = 27 })
		nX = nX + 10
		nY = nY + 35

		for _, p in ipairs(aSaveDB) do
			nX = nX + ui:Append('WndCheckBox', {
				x = nX, y = nY, w = 200,
				text = p.szName, checked = X.Get(_G, p.szKey),
				onCheck = function(bChecked)
					X.Set(_G, p.szKey, bChecked)
				end,
			}):AutoWidth():Width() + 5
		end
		nY = nY + 40
	end

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, w = nW, text = _L['Tips'], font = 27, multiline = true, alignVertical = 0 })
	nY = nY + 30
	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, w = nW, text = _L['MY_RoleStatistics TIPS'], font = 27, multiline = true, alignVertical = 0 })
end
X.RegisterPanel(_L['General'], 'MY_RoleStatistics', _L['MY_RoleStatistics'], 13491, PS)
