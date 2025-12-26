--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 角色统计框架
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RoleStatistics/MY_RoleStatistics'
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics'
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
}

function D.Open(szModule)
	local function onSizeChange()
		local ui = X.UI(this)
		local nW, nH = ui:Size()
		ui:Children('#Btn_Option'):Left(nW - 40)
		ui:Children('#PageSet_All'):Size(nW, nH - 48)
		D.PageSetModule.BroadcastPageEvent(this, 'OnResizePage')
	end
	local ui = X.UI.CreateFrame('MY_RoleStatistics', {
		w = 1104, h = 700,
		close = true,
		maximize = true,
		resize = true,
		minWidth = 1000,
		minHeight = 700,
		text = X.PACKET_INFO.NAME .. _L.SPLIT_DOT .. _L['MY_RoleStatistics'],
		anchor = 'CENTER',
		onSizeChange = onSizeChange,
	})
	ui:Append('WndPageSet', {
		name = 'PageSet_All',
		x = 0, y = 48, w = 1000, h = 700 - 48,
	})
	ui:Append('WndButton', {
		name = 'Btn_Option',
		x = 960, y = 54, w = 20, h = 20,
		buttonStyle = 'OPTION',
	})
	local frame = ui:Raw()
	frame:BringToTop()
	X.ExecuteWithThis(frame, onSizeChange)
	D.PageSetModule.DrawUI(frame)
	D.PageSetModule.ActivePage(frame, szModule or 1, true)
end

function D.Close()
	X.UI.CloseFrame('MY_RoleStatistics')
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
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function D.OnFrameDestroy()
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

D.PageSetModule = X.UI.CreatePageSetModule(D, 'Wnd_Total/PageSet_All')

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics',
	exports = {
		{
			root = D,
			fields = {
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
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 25, 25
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()

	ui:Append('WndButton', {
		x = nW - 165, y = nY, w = 150, h = 38,
		text = _L['Open panel'],
		buttonStyle = 'SKEUOMORPHISM_LACE_BORDER',
		onClick = D.Open,
	})

	if #D.aFloatEntry > 0 then
		nX = nPaddingX
		ui:Append('Text', { x = nX, y = nY, text = _L['Float panel'], font = 27 })
		nX = nX + 10
		nY = nY + 35

		for _, p in ipairs(D.aFloatEntry) do
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
	if #D.aSaveDB > 0 then
		nX = nPaddingX
		ui:Append('Text', { x = nX, y = nY, text = _L['Save DB'], font = 27 })
		nX = nX + 10
		nY = nY + 35

		for _, p in ipairs(D.aSaveDB) do
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
X.Panel.Register(_L['General'], 'MY_RoleStatistics', _L['MY_RoleStatistics'], 13491, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
