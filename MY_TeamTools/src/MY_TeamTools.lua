--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具框架
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamTools'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {}
local O = {
	aModule = {},
	nActivePageIndex = nil,
}
local Framework = {}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_TeamTools.ini'
local SZ_MOD_INI = PLUGIN_ROOT .. '/ui/MY_TeamTools.Mod.ini'

function D.Open(szModule)
	local frame = X.UI.OpenFrame(SZ_INI, 'MY_TeamTools')
	frame:BringToTop()
	D.ActivePage(frame, szModule or 1, true)
end

function D.Close()
	X.UI.CloseFrame('MY_TeamTools')
end

function D.IsOpened()
	return Station.Lookup('Normal/MY_TeamTools')
end

function D.Toggle()
	if D.IsOpened() then
		D.Close()
	else
		D.Open()
	end
end

-- 注册子模块
function D.RegisterModule(szID, szName, env)
	for i, v in X.ipairs_r(O.aModule) do
		if v.szID == szID then
			table.remove(O.aModule, i)
		end
	end
	if szName and env then
		table.insert(O.aModule, {
			szID = szID,
			szName = szName,
			env = env,
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
	for i, m in ipairs(O.aModule) do
		local frameMod = X.UI.OpenFrame(SZ_MOD_INI, 'MY_TeamToolsMod')
		local checkbox = frameMod:Lookup('PageSet_Total/WndCheck_Default')
		local page = frameMod:Lookup('PageSet_Total/Page_Default')
		checkbox:ChangeRelation(pageset, true, true)
		page:ChangeRelation(pageset, true, true)
		X.UI.CloseFrame(frameMod)
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
	for i, m in ipairs(O.aModule) do
		if m.szID == szModule or i == szModule or i == O.nActivePageIndex then
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
		O.nActivePageIndex = nToIndex
	end
end

function Framework.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		D.Close()
	elseif name == 'Btn_Option' then
		local menu = {}
		table.insert(menu, {
			szOption = _L['Option'],
			fnAction = function()
				X.ShowPanel()
				X.FocusPanel()
				X.SwitchTab('MY_TeamTools')
			end,
		})
		local tFloatEntryMenu = { szOption = _L['Float panel'] }
		for _, m in ipairs(O.aModule) do
			if m and m.env.szFloatEntry then
				table.insert(tFloatEntryMenu, {
					szOption = m.szName,
					bCheck = true, bChecked = X.Get(_G, m.env.szFloatEntry),
					fnAction = function()
						X.Set(_G, m.env.szFloatEntry, not X.Get(_G, m.env.szFloatEntry))
					end,
				})
			end
		end
		if #tFloatEntryMenu > 0 then
			table.insert(menu, tFloatEntryMenu)
		end
		local tSaveDBMenu = { szOption = _L['Save DB'] }
		for _, m in ipairs(O.aModule) do
			if m and m.env.szSaveDB then
				table.insert(tSaveDBMenu, {
					szOption = m.szName,
					bCheck = true, bChecked = X.Get(_G, m.env.szSaveDB),
					fnAction = function()
						X.Set(_G, m.env.szSaveDB, not X.Get(_G, m.env.szSaveDB))
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
			X.UI.PopupMenu(menu)
		end
	end
end

function Framework.OnActivePage()
	local frame = this:GetRoot()
	if frame.bInitPageset then
		return
	end
	local name = this:GetName()
	if name == 'PageSet_All' then
		local page = this:GetActivePage()
		if page.nIndex then
			if X.IsElement(frame.pActivePage) then
				local m = O.aModule[frame.pActivePage.nIndex]
				if m and m.env.OnDeactivePage then
					local _this = this
					this = frame.pActivePage
					m.env.OnDeactivePage()
					this = _this
				end
			end
			local m = O.aModule[page.nIndex]
			if not page.bInit then
				if m and m.env.OnInitPage then
					local _this = this
					this = page
					m.env.OnInitPage()
					this = _this
				end
				page.bInit = true
			end
			if m and m.env.OnActivePage then
				local _this = this
				this = page
				m.env.OnActivePage()
				this = _this
			end
			frame.pActivePage = page
			O.nActivePageIndex = page.nIndex
		end
	end
end

function Framework.OnFrameCreate()
	D.InitPageSet(this)
	this:BringToTop()
	this:RegisterEvent('PARTY_ADD_MEMBER')
	this:RegisterEvent('PARTY_DELETE_MEMBER')
	this:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	-- 标题修改
	local szTitle = X.PACKET_INFO.NAME .. ' - ' .. _L['MY_TeamTools']
	if X.IsInParty() then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		szTitle = _L('%s\'s Team', info.szName) .. ' (' .. team.GetTeamSize() .. '/' .. team.nGroupNum * 5  .. ')'
	end
	this:Lookup('', 'Text_Title'):SetText(szTitle)
	-- 注册关闭
	X.RegisterEsc('MY_TeamTools', D.IsOpened, D.Close)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function Framework.OnFrameDestroy()
	if X.IsElement(this.pActivePage) then
		local m = O.aModule[this.pActivePage.nIndex]
		if m and m.env.OnDeactivePage then
			local _this = this
			this = this.pActivePage
			m.env.OnDeactivePage()
			this = _this
		end
	end
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	X.RegisterEsc('MY_TeamTools')
end

function Framework.OnEvent(event)
	-- update title
	if event == 'PARTY_ADD_MEMBER'
		or event == 'PARTY_DELETE_MEMBER'
		or event == 'TEAM_AUTHORITY_CHANGED'
	then
		local team = GetClientTeam()
		local dwID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		local info = team.GetMemberInfo(dwID)
		if info then
			this:Lookup('', 'Text_Title'):SetText(_L('%s\'s Team', info.szName) .. ' (' .. team.GetTeamSize() .. '/' .. team.nGroupNum * 5  .. ')')
		end
	end
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
				local m = O.aModule[page.nIndex]
				if m and m.env[szEvent] then
					local _this = this
					this = page
					m.env[szEvent](...)
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
			local m = O.aModule[page.nIndex]
			if m and m.env[szEvent] then
				return m.env[szEvent](...)
			end
		else
			if Framework[szEvent] then
				return Framework[szEvent](...)
			end
		end
	end
end

-- Global exports
do
local settings = {
	name = 'MY_TeamTools',
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
MY_TeamTools = X.CreateModule(settings)
end

do
local menu = {
	szOption = _L['MY_TeamTools'],
	fnAction = function() D.Toggle() end,
}
X.RegisterAddonMenu('MY_TeamTools', menu)
end
X.RegisterHotKey('MY_RaidTools', _L['Open/Close MY_TeamTools'], D.Toggle, nil)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
