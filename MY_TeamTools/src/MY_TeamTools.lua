--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队工具框架
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamTools'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {
	aFloatEntry = {},
	aSaveDB = {},
	nActivePageIndex = nil,
	szStatRange = 'RAID',
}
local Framework = {}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_TeamTools.ini'
local SZ_MOD_INI = PLUGIN_ROOT .. '/ui/MY_TeamTools.Mod.ini'

function D.Open(szModule)
	local ui = X.UI.CreateFrame('MY_TeamTools', {
		w = 1096, h = 700,
		close = true,
		text = X.PACKET_INFO.NAME .. _L.SPLIT_DOT .. _L['MY_TeamTools'],
		anchor = 'CENTER',
		onSizeChange = function()
			local ui = X.UI(this)
			local nW, nH = ui:Size()
			ui:Children('#Btn_Option'):Left(nW - 40)
			ui:Children('#PageSet_All'):Size(nW, nH - 48)
			D.PageSetModule.BroadcastPageEvent(this, 'OnResizePage')
		end,
	})
	local frame = ui:Raw()
	D.PageSetModule.DrawUI(frame)
	D.PageSetModule.ActivePage(frame, szModule or 1, true)
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
function D.RegisterModule(szKey, szName, tModule)
	if not D.PageSetModule or not szName or not tModule then
		return
	end
	if tModule.szFloatEntry then
		table.insert(D.aFloatEntry, { szName = szName, szKey = tModule.szFloatEntry })
	end
	if tModule.szSaveDB then
		table.insert(D.aSaveDB, { szName = szName, szKey = tModule.szSaveDB })
	end
	D.PageSetModule.RegisterModule(szKey, szName, tModule)
	if D.IsOpened() then
		D.Close()
		D.Open()
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		D.Close()
	elseif name == 'Btn_Option' then
		local menu = {}
		table.insert(menu, {
			szOption = _L['Option'],
			fnAction = function()
				X.Panel.Show()
				X.Panel.Focus()
				X.Panel.SwitchTab('MY_TeamTools')
			end,
		})
		local tFloatEntryMenu = { szOption = _L['Float panel'] }
		for _, m in ipairs(D.aFloatEntry) do
			table.insert(tFloatEntryMenu, {
				szOption = m.szName,
				bCheck = true, bChecked = X.Get(_G, m.szKey),
				fnAction = function()
					X.Set(_G, m.szKey, not X.Get(_G, m.szKey))
				end,
			})
		end
		if #tFloatEntryMenu > 0 then
			table.insert(menu, tFloatEntryMenu)
		end
		local tSaveDBMenu = { szOption = _L['Save DB'] }
		for _, m in ipairs(D.aSaveDB) do
			table.insert(tSaveDBMenu, {
				szOption = m.szName,
				bCheck = true, bChecked = X.Get(_G, m.szKey),
				fnAction = function()
					X.Set(_G, m.szKey, not X.Get(_G, m.szKey))
				end,
			})
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

function D.OnFrameCreate()
	this:BringToTop()
	this:RegisterEvent('PARTY_ADD_MEMBER')
	this:RegisterEvent('PARTY_DELETE_MEMBER')
	this:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	local frame = this
	local ui = X.UI(frame)
	ui:Append('WndPageSet', {
		name = 'PageSet_All',
		x = 0, y = 48, w = 1096, h = 700 - 48,
	})
	ui:Append('WndButton', {
		name = 'Btn_Option',
		x = 1056, y = 54, w = 20, h = 20,
		buttonStyle = 'OPTION',
	})
	-- 模式选择
	local aStatRange = {
		{ szKey = 'RAID', szName = _L['Raid Stat'] },
		{ szKey = 'ROOM', szName = _L['Room Stat'] },
	}
	ui:Append('WndComboBox', {
		name = 'WndComboBox_Mode',
		x = 930, y = 52, w = 110, h = 26,
		text = (function()
			for _, v in ipairs(aStatRange) do
				if v.szKey == D.szStatRange then
					return v.szName
				end
			end
			return aStatRange[1].szName
		end)(),
		menu = function()
			local menu = {}
			local ui = X.UI(this)
			for _, tMode in ipairs(aStatRange) do
				table.insert(menu, {
					szOption = tMode.szName,
					fnAction = function()
						D.szStatRange = tMode.szKey
						FireUIEvent('MY_TEAM_TOOLS__STAT_RANGE_CHANGE')
						ui:Text(tMode.szName)
						X.UI.ClosePopupMenu()
					end,
				})
			end
			return menu
		end,
	})
	-- 标题修改
	local szTitle = X.PACKET_INFO.NAME .. ' - ' .. _L['MY_TeamTools']
	if X.IsClientPlayerInParty() then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		szTitle = _L('%s\'s Team', info.szName) .. ' (' .. team.GetTeamSize() .. '/' .. team.nGroupNum * 5  .. ')'
	end
	frame:Lookup('', 'Text_Title'):SetText(szTitle)
	-- 注册关闭
	X.RegisterEsc('MY_TeamTools', D.IsOpened, D.Close)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function D.OnFrameDestroy()
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	X.RegisterEsc('MY_TeamTools', false)
end

function D.OnEvent(event)
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

D.PageSetModule = X.UI.CreatePageSetModule(D, 'Wnd_Total/PageSet_All')
--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamTools',
	exports = {
		{
			root = D,
			fields = {
				'szStatRange',
				Open = D.Open,
				Close = D.Close,
				IsOpened = D.IsOpened,
				Toggle = D.Toggle,
				RegisterModule = D.RegisterModule,
			},
			interceptors = {
				['*'] = function(k)
					if D.PageSetModule and D.PageSetModule.tModuleAPI[k] then
						return D.PageSetModule.tModuleAPI[k]
					end
				end,
			},
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
