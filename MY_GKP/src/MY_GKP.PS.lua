--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKP.PS'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {}

---------------------------------------------------------------------->
-- 获取补贴方案菜单
----------------------------------------------------------------------<
function D.GetSubsidiesMenu()
	local menu = { szOption = _L['Edit Allowance Protocols'], rgb = { 255, 0, 0 } }
	table.insert(menu, {
		szOption = _L['Add New Protocols'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			GetUserInput(_L['New Protocol  Format: Protocol\'s Name, Money'], function(txt)
				local t = X.SplitString(txt, ',')
				local aSubsidies = MY_GKP.aSubsidies
				table.insert(aSubsidies, { t[1], tonumber(t[2]) or '', true })
				MY_GKP.aSubsidies = aSubsidies
			end)
		end,
	})
	table.insert(menu, { bDevide = true})
	for k, v in ipairs(MY_GKP.aSubsidies) do
		table.insert(menu, {
			szOption = v[1],
			bCheck = true,
			bChecked = v[3],
			fnAction = function()
				v[3] = not v[3]
				MY_GKP.aSubsidies = MY_GKP.aSubsidies
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				local aSubsidies = MY_GKP.aSubsidies
				for ii, vv in ipairs(aSubsidies) do
					if v == vv then
						table.remove(aSubsidies, ii)
					end
				end
				MY_GKP.aSubsidies = aSubsidies
				X.UI.ClosePopupMenu()
			end,
		})
	end
	return menu
end
---------------------------------------------------------------------->
-- 获取拍卖方案菜单
----------------------------------------------------------------------<
function D.GetSchemeMenu()
	local menu = { szOption = _L['Edit Auction Protocols'], rgb = { 255, 0, 0 } }
	table.insert(menu,{
		szOption = _L['Edit All Protocols'],
		rgb = { 255, 255, 0 },
		fnAction = function()
			local a = {}
			if X.IsTable(MY_GKP.aScheme) then
				for k, v in ipairs(MY_GKP.aScheme) do
					table.insert(a, tostring(v[1]) .. ',' .. tostring(v[2]))
				end
			end
			GetUserInput(_L['New Protocol Format: Money, Step; Money, Step'], function(txt)
				local t = X.SplitString(txt, ';')
				local aScheme = {}
				for k, v in ipairs(t) do
					local a = X.SplitString(v, ',')
					if a[1] and a[2] then
						a[1] = tonumber(a[1])
						a[2] = tonumber(a[2])
					end
					if not X.IsEmpty(a[1]) and not X.IsEmpty(a[2]) then
						table.insert(aScheme, { a[1], a[2], true })
					end
				end
				MY_GKP.aScheme = aScheme
			end, nil, nil, nil, table.concat(a, ';'))
		end
	})
	table.insert(menu, { bDevide = true })
	for k, v in ipairs(MY_GKP.aScheme) do
		table.insert(menu,{
			szOption = v[1] .. ',' .. v[2],
			bCheck = true,
			bChecked = v[3],
			fnAction = function()
				v[3] = not v[3]
				MY_GKP.aScheme = MY_GKP.aScheme
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				local aScheme = MY_GKP.aScheme
				for ii, vv in ipairs(aScheme) do
					if v == vv then
						table.remove(aScheme, ii)
					end
				end
				MY_GKP.aScheme = aScheme
				X.UI.ClosePopupMenu()
			end,
		})
	end

	return menu
end

local PS = { nPriority = 2 }

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 25, 25
	local nX, nY, nLFY = nPaddingX, nPaddingY, nPaddingY
	local nLineHeightS, nLineHeightM, nLineHeightL = 22, 28, 32
	local nW, nH = ui:Size()

	ui:Append('WndButton', {
		x = nW - 165, y = nPaddingY, w = 150, h = 38,
		text = _L['Open Panel'],
		buttonStyle = 'SKEUOMORPHISM_LACE_BORDER',
		onClick = MY_GKP_MI.OpenPanel,
	})

	nX, nY, nLFY = MY_GKPLoot.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLineHeightM, nX, nY, nLFY)
	nX, nY = nPaddingX, nLFY + 10

	ui:Append('Text', { x = nX, y = nY, text = _L['Preference Setting'], font = 27 })
	nY = nY + 28

	nX = nX + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Popup Record for Distributor'], checked = MY_GKP.bOn,
		onCheck = function(bChecked)
			MY_GKP.bOn = bChecked
		end,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Clause with 0 Gold as Record'], checked = MY_GKP.bDisplayEmptyRecords,
		onCheck = function(bChecked)
			MY_GKP.bDisplayEmptyRecords = bChecked
		end,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		color = { 255, 128, 0 } , text = _L['Show Gold Brick'], checked = MY_GKP.bShowGoldBrick,
		onCheck = function(bChecked)
			MY_GKP.bShowGoldBrick = bChecked
		end,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Remind Wipe Data When Enter Dungeon'], checked = MY_GKP.bAlertMessage,
		onCheck = function(bChecked)
			MY_GKP.bAlertMessage = bChecked
		end,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['Automatic Reception with Record From Distributor'], checked = MY_GKP.bAutoSync,
		onCheck = function(bChecked)
			MY_GKP.bAutoSync = bChecked
		end,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['Sync system reception'], checked = MY_GKP.bSyncSystem,
		onCheck = function(bChecked)
			MY_GKP.bSyncSystem = bChecked
		end,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['Prefer use new bidding panel'], checked = MY_GKP.bNewBidding,
		onCheck = function(bChecked)
			MY_GKP.bSyncSystem = bChecked
		end,
	})
	nY = nY + 28

	nY = nY + 5
	ui:Append('WndComboBox', { x = nX, y = nY, w = 150, text = _L['Edit Allowance Protocols'], menu = D.GetSubsidiesMenu })
	ui:Append('WndComboBox', { x = nX + 160, y = nY, text = _L['Edit Auction Protocols'], menu = D.GetSchemeMenu })
	nY = nY + 28

	nX = nPaddingX
	nY = nY + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Money Record'], font = 27 })
	nY = nY + 28

	nX = nX + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 150, checked = MY_GKP.bMoneySystem, text = _L['Track Money Trend in the System'],
		onCheck = function(bChecked)
			MY_GKP.bMoneySystem = bChecked
		end,
	})
	nY = nY + 28

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Enable Money Trend'],
		checked = MY_GKP.bMoneyTalk,
		onCheck = function(bChecked)
			MY_GKP.bMoneyTalk = bChecked
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Money trend only distributor'],
		checked = MY_GKP.bMoneyTalkOnlyDistributor,
		onCheck = function(bChecked)
			MY_GKP.bMoneyTalkOnlyDistributor = bChecked
		end,
		autoEnable = function() return MY_GKP.bMoneyTalk end,
	}):Width() + 5
	nY = nY + 28
end
X.Panel.Register(_L['General'], 'MY_GKP', _L['GKP Golden Team Record'], 2490, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
