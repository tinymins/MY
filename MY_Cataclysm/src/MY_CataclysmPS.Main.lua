--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队面板主设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Cataclysm/MY_CataclysmPS.Main'
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 1 }

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['configure'], font = 27 }):Height()

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 3, w = 120,
		buttonStyle = 'FLAT',
		text = _L['Load ancient config'],
		onClick = function()
			GetUserInput(_L['Please input ancient config name:'], function(szText)
				MY_CataclysmMain.LoadAncientConfigure(szText)
				MY_CataclysmMain.CheckEnableTeamPanel()
				X.Panel.SwitchTab('MY_Cataclysm', true)
			end, nil, nil, nil, 'common')
		end,
	}):Width() + 5

	-- 恢复默认
	nY = nY + ui:Append('WndButton', {
		x = nX, y = nY + 3, w = 100,
		text = _L['Restore default'],
		buttonStyle = 'FLAT',
		onClick = function()
			MY_CataclysmMain.ConfirmRestoreConfig()
		end,
	}):Height() + 20

	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Cataclysm Team Panel'], font = 27 }):AutoWidth():Height()

	nX = nX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Enable Cataclysm Team Panel'],
		onCheck = MY_CataclysmMain.ToggleTeamPanel, checked = MY_Cataclysm.bEnable,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Only in team'],
		checked = CFG.bShowInRaid,
		onCheck = function(bCheck)
			CFG.bShowInRaid = bCheck
			if MY_CataclysmMain.CheckCataclysmEnable() then
				MY_CataclysmMain.ReloadCataclysmPanel()
			end
			local me = X.GetClientPlayer()
			if me.IsInParty() and not me.IsInRaid() then
				FireUIEvent('MY_CATACLYSM_PANEL_TEAMMATE', CFG.bShowInRaid)
			end
		end,
	}):AutoWidth():Width() + 5

	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = g_tStrings.WINDOW_LOCK,
		checked = not CFG.bDrag,
		onCheck = function(bCheck)
			CFG.bDrag = not bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmMain.GetFrame():EnableDrag(not bCheck)
			end
		end,
	}):AutoWidth():Height() + 5

	-- 提醒框
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = g_tStrings.STR_RAID_TIP_IMAGE, font = 27 }):Height()

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show attention shadow'],
		checked = CFG.bShowAttention,
		onCheck = function(bCheck)
			CFG.bShowAttention = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show caution animate'],
		checked = CFG.bShowCaution,
		onCheck = function(bCheck)
			CFG.bShowCaution = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show screen head'],
		checked = CFG.bShowScreenHead,
		onCheck = function(bCheck)
			CFG.bShowScreenHead = bCheck
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show important skill'],
		checked = CFG.bEnableImportantSkill,
		onCheck = function(bCheck)
			CFG.bEnableImportantSkill = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Attack Warning'],
		checked = CFG.bHPHitAlert,
		onCheck = function(bCheck)
			CFG.bHPHitAlert = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show distance'],
		checked = CFG.bShowDistance,
		onCheck = function(bCheck)
			CFG.bShowDistance = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['ZuiWu Effect'],
		checked = CFG.bShowEffect,
		onCheck = function(bCheck)
			CFG.bShowEffect = bCheck
		end,
		tip = {
			render = _L['Show effect when teammate get ZuiWu, only your ZuiWu will be showen while you\'re BuTianJue.'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show central party member tag'],
		checked = CFG.bShowSputtering,
		onCheck = function(bCheck)
			CFG.bShowSputtering = bCheck
		end,
		tip = {
			render = _L['Show color on right top pos of central member of each party'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 25, h = 25,
		buttonStyle = 'OPTION',
		menu = function()
			return {
				{
					szOption = _L['Set sputtering distance'],
					fnAction = function()
						GetUserInputNumber(
							CFG.nSputteringDistance,
							1000,
							nil,
							function(val) CFG.nSputteringDistance = val or CFG.nSputteringDistance end)
					end,
				},
				{
					szOption = _L['Set sputtering font color'],
					fnAction = function()
						X.UI.OpenColorPicker(function(r, g, b)
							CFG.tSputteringFontColor = { r, g, b }
						end)
					end,
				},
				{
					szOption = _L['Set sputtering font alpha'],
					fnAction = function()
						local fnAction = function(f)
							CFG.nSputteringFontAlpha = math.ceil((1 - f) * 255)
						end
						local fPosX, fPosY = Cursor.GetPos()
						GetUserPercentage(fnAction, nil, 1 - CFG.nSputteringFontAlpha / 255, _L['Set sputtering font alpha'], { fPosX, fPosY, fPosX + 1, fPosY + 1 })
					end,
				},
				{
					szOption = _L['Set sputtering shadow color'],
					fnAction = function()
						X.UI.OpenColorPicker(function(r, g, b)
							CFG.tSputteringShadowColor = { r, g, b }
						end)
					end,
				},
				{
					szOption = _L['Set sputtering shadow alpha'],
					fnAction = function()
						local fnAction = function(f)
							CFG.nSputteringShadowAlpha = math.ceil((1 - f) * 255)
						end
						local fPosX, fPosY = Cursor.GetPos()
						GetUserPercentage(fnAction, nil, 1 - CFG.nSputteringShadowAlpha / 255, _L['Set sputtering shadow alpha'], { fPosX, fPosY, fPosX + 1, fPosY + 1 })
					end,
				},
			}
		end,
		autoEnable = function() return CFG.bShowSputtering end,
	}):Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show target\'s target'],
		checked = CFG.bShowTargetTargetAni,
		onCheck = function(bCheck)
			CFG.bShowTargetTargetAni = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:RefreshTTarget()
			end
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Boss target'],
		checked = CFG.bShowBossTarget,
		onCheck = function(bCheck)
			CFG.bShowBossTarget = bCheck
		end,
	}):AutoWidth():Width() + 5

	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Boss focus'],
		checked = CFG.bShowBossFocus,
		onCheck = function(bCheck)
			CFG.bShowBossFocus = bCheck
		end,
	}):AutoWidth():Height()

	-- 其他
	nX = nPaddingX
	nY = nY + 4
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = g_tStrings.OTHER, font = 27 }):Height()

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show tip at right bottom'],
		checked = CFG.bShowTipAtRightBottom,
		onCheck = function(bCheck)
			CFG.bShowTipAtRightBottom = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Don\'t show tip in fight'],
		checked = CFG.bHideTipInFight,
		onCheck = function(bCheck)
			CFG.bHideTipInFight = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = g_tStrings.STR_RAID_TARGET_ASSIST,
		checked = CFG.bTempTargetEnable,
		onCheck = function(bCheck)
			CFG.bTempTargetEnable = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndSlider', {
		x = nX, y = nY - 1,
		value = CFG.nTempTargetDelay / 75,
		range = {0, 8},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(val)
			CFG.nTempTargetDelay = val * 75
		end,
		textFormatter = function(val)
			return val == 0
				and _L['Target assist no delay.']
				or _L('Target assist delay %dms.', val * 75)
		end,
		autoEnable = function() return CFG.bTempTargetEnable end,
	}):AutoWidth():Width()

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Alt view player'],
		checked = CFG.bAltView,
		onCheck = function(bCheck)
			CFG.bAltView = bCheck
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Disable in fight'],
		checked = not CFG.bAltViewInFight,
		onCheck = function(bCheck)
			CFG.bAltViewInFight = not bCheck
		end,
		autoEnable = function() return CFG.bAltView end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Faster Refresh (Greater performance loss)'],
		checked = CFG.nDrawInterval == 1,
		onCheck = function(bCheck)
			CFG.nDrawInterval = bCheck and 1 or 4
		end,
		tip = {
			render = _L['Refresh every breathe call.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	})

	nY = nY + 25
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Ultimate Refresh HP (Greater performance loss)'],
		checked = CFG.bFasterHP,
		onCheck = function(bCheck)
			CFG.bFasterHP = bCheck
			if MY_CataclysmMain.GetFrame() then
				if bCheck then
					MY_CataclysmMain.GetFrame():RegisterEvent('RENDER_FRAME_UPDATE')
				else
					MY_CataclysmMain.GetFrame():UnRegisterEvent('RENDER_FRAME_UPDATE')
				end
			end
		end,
		tip = {
			render = _L['Refresh every render call.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	})
	nY = nY + 25
end
X.Panel.Register(_L['Raid'], 'MY_Cataclysm', _L['Cataclysm'], 'ui/Image/UICommon/RaidTotal.uitex|62', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
