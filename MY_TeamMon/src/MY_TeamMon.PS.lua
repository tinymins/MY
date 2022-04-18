--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
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
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------

local MY_TM_REMOTE_DATA_ROOT = MY_TeamMon.MY_TM_REMOTE_DATA_ROOT

local PS = {}

function PS.IsRestricted()
	return X.IsRestricted('MY_TeamMon')
end

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local nW = ui:Size()
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	local nLineH = 22

	-- ui:Append('WndButton', {
	-- 	x = 400, y = 20, text = g_tStrings.HELP_PANEL,
	-- 	buttonStyle = 'FLAT',
	-- 	onClick = function()
	-- 		OpenInternetExplorer('https://github.com/luckyyyyy/JH/blob/dev/JH_DBM/README.md')
	-- 	end,
	-- })

	nX, nY = ui:Append('Text', { x = nPaddingX, y = nPaddingY, text = _L['Master switch'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = nPaddingX + 10, y = nY, text = _L['Enable MY_TeamMon'],
		checked = MY_TeamMon.bEnable,
		onCheck = function(bCheck)
			MY_TeamMon.bEnable = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	if not X.IsRestricted('MY_TeamMon_CC') then
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Enable circle'],
			checked = MY_TeamMon_CC.bEnable,
			onCheck = function(bCheck)
				MY_TeamMon_CC.bEnable = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Circle border'],
			checked = MY_TeamMon_CC.bBorder,
			onCheck = function(bCheck)
				MY_TeamMon_CC.bBorder = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nY = nY + nLineH

	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Enable alarm (master switch)'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = nPaddingX + 10, y = nY,
		text = _L['Team channel alarm'],
		color = GetMsgFontColor('MSG_TEAM', true),
		checked = MY_TeamMon.bPushTeamChannel,
		onCheck = function(bCheck)
			MY_TeamMon.bPushTeamChannel = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY,
		text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
		checked = MY_TeamMon.bPushWhisperChannel,
		onCheck = function(bCheck)
			MY_TeamMon.bPushWhisperChannel = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Buff list'],
		checked = MY_TeamMon.bPushBuffList,
		onCheck = function(bCheck)
			MY_TeamMon.bPushBuffList = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Center alarm'],
		checked = MY_TeamMon.bPushCenterAlarm,
		onCheck = function(bCheck)
			MY_TeamMon.bPushCenterAlarm = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = nPaddingX + 5
	if not X.IsRestricted('MY_TeamMon_LT') then
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Large text alarm'],
			checked = MY_TeamMon.bPushBigFontAlarm,
			onCheck = function(bCheck)
				MY_TeamMon.bPushBigFontAlarm = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end
	if not X.IsRestricted('MY_TeamMon_FS') then
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Fullscreen alarm'],
			checked = MY_TeamMon.bPushFullScreen,
			onCheck = function(bCheck)
				MY_TeamMon.bPushFullScreen = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nX = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Party buff list'],
		checked = MY_TeamMon.bPushPartyBuffList,
		onCheck = function(bCheck)
			MY_TeamMon.bPushPartyBuffList = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Lifebar alarm'],
		tip = {
			render = _L['Requires MY_LifeBar loaded.'],
			position = UI.TIP_POSITION.BOTTOM_TOP,
		},
		checked = MY_TeamMon.bPushScreenHead,
		onCheck = function(bCheck)
			MY_TeamMon.bPushScreenHead = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Team panel bind show buff'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nPaddingX + 10, y = nY, text = _L['Team panel bind show buff'],
		checked = MY_TeamMon.bPushTeamPanel,
		onCheck = function(bCheck)
			MY_TeamMon.bPushTeamPanel = bCheck
			FireUIEvent('MY_TM_CREATE_CACHE')
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Buff list'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndComboBox', {
		x = nPaddingX + 10, y = nY, text = _L['Max buff count'],
		menu = function()
			local menu = {}
			for k, v in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }) do
				table.insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BL.nCount == v, fnAction = function()
					MY_TeamMon_BL.nCount = v
				end })
			end
			return menu
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndComboBox', {
		x = nX + 5, y = nY, text = _L['Buff size'],
		menu = function()
			local menu = {}
			for k, v in ipairs({ 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 100 }) do
				table.insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BL.fScale == v / 55, fnAction = function()
					MY_TeamMon_BL.fScale = v / 55
				end })
			end
			return menu
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Countdown configure'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nPaddingX + 10, y = nY, w = nW - nPaddingX * 2, rw = nW / 3, h = 22,
		range = {0, 3601},
		value = MY_TeamMon_ST.nBelowDecimal,
		trackbarStyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onChange = function(val)
			X.DelayCall('MY_TeamMon_ST_nBelowDecimal', 300, function()
				MY_TeamMon_ST.nBelowDecimal = val
			end)
		end,
		textFormatter = function(val)
			if val == 0 then
				return _L['Never show decimal.']
			end
			if val == 3601 then
				return _L['Always show decimal.']
			end
			return _L('Show countdown decimal when duration below: %ds.', val)
		end,
	}):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Data save mode'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nPaddingX + 10, y = nY, text = _L['Use common data'],
		checked = MY_TeamMon.bCommon,
		onCheck = function(bCheck)
			MY_TeamMon.bCommon = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nPaddingX + 5, y = nY + 15, text = _L['Data panel'],
		buttonStyle = 'FLAT',
		onClick = MY_TeamMon_UI.TogglePanel,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Export data'],
		buttonStyle = 'FLAT',
		onClick = MY_TeamMon_UI.OpenExportPanel,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Import data'],
		buttonStyle = 'FLAT',
		menu = function()
			local menu = {}
			table.insert(menu, {
				szOption = _L['Import data (local)'],
				fnAction = function() MY_TeamMon_UI.OpenImportPanel() end,
			})
			local szLang = ENVIRONMENT.GAME_LANG
			if szLang == 'zhcn' or szLang == 'zhtw' then
				table.insert(menu, {
					szOption = _L['Import data (web)'],
					fnAction = function() MY_TeamMon_RR.OpenPanel() end,
				})
			end
			table.insert(menu, {
				szOption = _L['Clear data'],
				fnAction = function()
					MY_TeamMon.RemoveData(nil, nil, _L['All data'])
				end,
			})
			return menu
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Open data folder'],
		buttonStyle = 'FLAT',
		onClick = function()
			local szRoot = X.GetAbsolutePath(MY_TM_REMOTE_DATA_ROOT):gsub('/', '\\')
			X.OpenFolder(szRoot)
			UI.OpenTextEditor(szRoot)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
end

X.RegisterPanel(_L['Raid'], 'MY_TeamMon', _L['MY_TeamMon'], 'ui/Image/UICommon/FBlist.uitex|34', PS)
