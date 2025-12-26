--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队监控设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon.PS'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local MY_TEAM_MON_REMOTE_DATA_ROOT = MY_TeamMon.MY_TEAM_MON_REMOTE_DATA_ROOT

local PS = { nPriority = 11, szRestriction = 'MY_TeamMon' }

function PS.IsRestricted()
	return X.IsRestricted('MY_TeamMon')
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
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
	if not X.IsRestricted('MY_TeamMon_CircleLine') then
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Enable circle'],
			checked = MY_TeamMon_CircleLine.bEnable,
			onCheck = function(bCheck)
				MY_TeamMon_CircleLine.bEnable = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Circle border'],
			checked = MY_TeamMon_CircleLine.bBorder,
			onCheck = function(bCheck)
				MY_TeamMon_CircleLine.bBorder = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nY = nY + nLineH

	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Enable alarm (master switch)'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	local uiContainer = ui:Append('WndContainer', { x = nPaddingX + 5, y = nY, w = nW - nPaddingX * 2 - 5, h = 'auto', containerType = X.UI.WND_CONTAINER_STYLE.LEFT_TOP })
	uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
		text = _L['Team channel alarm'],
		color = GetMsgFontColor('MSG_TEAM', true),
		checked = MY_TeamMon.bPushTeamChannel,
		onCheck = function(bCheck)
			MY_TeamMon.bPushTeamChannel = bCheck
		end,
	}):AutoWidth()
	uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
		text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
		checked = MY_TeamMon.bPushWhisperChannel,
		onCheck = function(bCheck)
			MY_TeamMon.bPushWhisperChannel = bCheck
		end,
	}):AutoWidth()
	if not X.IsRestricted('MY_TeamMon_BuffList') then
		uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
			text = _L['Buff list'],
			checked = MY_TeamMon.bPushBuffList,
			onCheck = function(bCheck)
				MY_TeamMon.bPushBuffList = bCheck
			end,
		}):AutoWidth()
	end
	if not X.IsRestricted('MY_TeamMon_CenterAlarm') then
		uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
			text = _L['Center alarm'],
			checked = MY_TeamMon.bPushCenterAlarm,
			onCheck = function(bCheck)
				MY_TeamMon.bPushCenterAlarm = bCheck
			end,
		}):AutoWidth()
	end
	uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
		text = _L['Voice alarm'],
		checked = MY_TeamMon.bPushVoiceAlarm,
		onCheck = function(bCheck)
			MY_TeamMon.bPushVoiceAlarm = bCheck
		end,
	}):AutoWidth()
	if not X.IsRestricted('MY_TeamMon_LargeTextAlarm') then
		uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
			text = _L['Large text alarm'],
			checked = MY_TeamMon.bPushBigFontAlarm,
			onCheck = function(bCheck)
				MY_TeamMon.bPushBigFontAlarm = bCheck
			end,
		}):AutoWidth()
	end
	if not X.IsRestricted('MY_TeamMon_FullScreenAlarm') then
		uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
			text = _L['Fullscreen alarm'],
			checked = MY_TeamMon.bPushFullScreen,
			onCheck = function(bCheck)
				MY_TeamMon.bPushFullScreen = bCheck
			end,
		}):AutoWidth()
	end
	if not X.IsRestricted('MY_TeamMon_PartyBuffList') then
		uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
			text = _L['Party buff list'],
			checked = MY_TeamMon.bPushPartyBuffList,
			onCheck = function(bCheck)
				MY_TeamMon.bPushPartyBuffList = bCheck
			end,
		}):AutoWidth()
	end
	if not X.IsRestricted('MY_TeamMon_ScreenHeadAlarm') then
		uiContainer:Append('WndDummyWrapper'):Append('WndCheckBox', {
			text = _L['Lifebar alarm'],
			tip = {
				render = _L['Requires MY_LifeBar loaded.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			checked = MY_TeamMon.bPushScreenHead,
			onCheck = function(bCheck)
				MY_TeamMon.bPushScreenHead = bCheck
			end,
		}):AutoWidth()
	end
	nX = nPaddingX
	nY = nY + uiContainer:Height()

	nX, nY = ui:Append('Text', { x = nX, y = nY + 5, w = 'auto', text = _L['Voice alarm function'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Show voice recommendation confirm on load data'],
		checked = MY_TeamMon.bShowVoicePacketRecommendation,
		onCheck = function(bCheck)
			MY_TeamMon.bShowVoicePacketRecommendation = bCheck
		end,
	}):Width() + 5
	nX, nY = ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto', text = _L['Prefer use official voice'],
		checked = MY_TeamMon_VoiceAlarm.bPreferOfficial,
		onCheck = function(bCheck)
			MY_TeamMon_VoiceAlarm.bPreferOfficial = bCheck
		end,
	}):Pos('BOTTOMRIGHT')

	if not X.IsRestricted('MY_TeamMon.Cataclysm') then
		nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Team panel bind show buff'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = nPaddingX + 10, y = nY, text = _L['Team panel bind show buff'],
			checked = MY_TeamMon.bPushTeamPanel,
			onCheck = function(bCheck)
				MY_TeamMon.bPushTeamPanel = bCheck
				FireUIEvent('MY_TEAM_MON_CREATE_CACHE')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end

	if not X.IsRestricted('MY_TeamMon_BuffList') then
		nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Buff list'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = nPaddingX + 10, y = nY, text = _L['Max buff count'],
			menu = function()
				local menu = {}
				for k, v in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }) do
					table.insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BuffList.nCount == v, fnAction = function()
						MY_TeamMon_BuffList.nCount = v
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
					table.insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BuffList.fScale == v / 55, fnAction = function()
						MY_TeamMon_BuffList.fScale = v / 55
					end })
				end
				return menu
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end

	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Countdown configure'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndSlider', {
		x = nPaddingX + 10, y = nY, w = nW - nPaddingX * 2, rw = nW / 3, h = 22,
		range = {0, 3601},
		value = MY_TeamMon_SpellTimer.nBelowDecimal,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(val)
			X.DelayCall('MY_TeamMon_SpellTimer_nBelowDecimal', 300, function()
				MY_TeamMon_SpellTimer.nBelowDecimal = val
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
		x = nPaddingX + 5, y = nY + 15, text = _L['Open data panel'],
		buttonStyle = 'FLAT',
		onClick = MY_TeamMon_UI.TogglePanel,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Data voice subscribe'],
		buttonStyle = 'FLAT',
		onClick = function() MY_TeamMon_Subscribe.OpenPanel() end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Preview voice packet'],
		buttonStyle = 'FLAT',
		-- menu = function()
		-- 	return {
		-- 		{
		-- 			szOption = _L['Preview official voice packet'],
		-- 			fnAction = function() MY_TeamMon_VoiceAlarm_Previewer.Open('OFFICIAL') end,
		-- 		},
		-- 		{
		-- 			szOption = _L['Preview custom voice packet'],
		-- 			fnAction = function() MY_TeamMon_VoiceAlarm_Previewer.Open('CUSTOM') end,
		-- 		},
		-- 	}
		-- end,
		onClick = function() MY_TeamMon_VoiceAlarm_Previewer.Open('OFFICIAL') end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Import local data'],
		buttonStyle = 'FLAT',
		onClick = function() MY_TeamMon_UI.OpenImportPanel() end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Open data folder'],
		buttonStyle = 'FLAT',
		onClick = function()
			local szRoot = X.GetAbsolutePath(MY_TEAM_MON_REMOTE_DATA_ROOT):gsub('/', '\\')
			X.OpenFolder(szRoot)
			X.UI.OpenTextEditor(szRoot)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
end

X.Panel.Register(_L['Raid'], 'MY_TeamMon', _L['MY_TeamMon'], 'ui/Image/UICommon/FBlist.uitex|34', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
