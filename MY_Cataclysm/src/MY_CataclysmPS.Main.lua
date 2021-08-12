--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板主设置界面
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
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 1 }

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['configure'], font = 27 }):Height()

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 3, w = 120, h = 25,
		buttonstyle = 'FLAT',
		text = _L['Load ancient config'],
		onclick = function()
			GetUserInput(_L['Please input ancient config name:'], function(szText)
				MY_CataclysmMain.LoadAncientConfigure(szText)
				MY_CataclysmMain.CheckEnableTeamPanel()
				X.SwitchTab('MY_Cataclysm', true)
			end, nil, nil, nil, 'common')
		end,
	}):Width() + 5

	-- 恢复默认
	nY = nY + ui:Append('WndButton', {
		x = nX, y = nY + 3, w = 100,
		text = _L['Restore default'],
		buttonstyle = 'FLAT',
		onclick = function()
			MY_CataclysmMain.ConfirmRestoreConfig()
		end,
	}):Height() + 20

	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Cataclysm Team Panel'], font = 27 }):AutoWidth():Height()

	nX = nX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Enable Cataclysm Team Panel'],
		oncheck = MY_CataclysmMain.ToggleTeamPanel, checked = MY_Cataclysm.bEnable,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Only in team'],
		checked = CFG.bShowInRaid,
		oncheck = function(bCheck)
			CFG.bShowInRaid = bCheck
			if MY_CataclysmMain.CheckCataclysmEnable() then
				MY_CataclysmMain.ReloadCataclysmPanel()
			end
			local me = GetClientPlayer()
			if me.IsInParty() and not me.IsInRaid() then
				FireUIEvent('CTM_PANEL_TEAMATE', CFG.bShowInRaid)
			end
		end,
	}):AutoWidth():Width() + 5

	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = g_tStrings.WINDOW_LOCK,
		checked = not CFG.bDrag,
		oncheck = function(bCheck)
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
		oncheck = function(bCheck)
			CFG.bShowAttention = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show caution animate'],
		checked = CFG.bShowCaution,
		oncheck = function(bCheck)
			CFG.bShowCaution = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show screen head'],
		checked = CFG.bShowScreenHead,
		oncheck = function(bCheck)
			CFG.bShowScreenHead = bCheck
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Attack Warning'],
		checked = CFG.bHPHitAlert,
		oncheck = function(bCheck)
			CFG.bHPHitAlert = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show distance'],
		checked = CFG.bShowDistance,
		oncheck = function(bCheck)
			CFG.bShowDistance = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['ZuiWu Effect'],
		checked = CFG.bShowEffect,
		oncheck = function(bCheck)
			CFG.bShowEffect = bCheck
		end,
		tip = _L['Show effect when teammate get ZuiWu, only your ZuiWu will be showen while you\'re BuTianJue.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show central party member tag'],
		checked = CFG.bShowSputtering,
		oncheck = function(bCheck)
			CFG.bShowSputtering = bCheck
		end,
		tip = _L['Show color on right top pos of central member of each party'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 25, h = 25,
		buttonstyle = 'OPTION',
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
						UI.OpenColorPicker(function(r, g, b)
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
						UI.OpenColorPicker(function(r, g, b)
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
		autoenable = function() return CFG.bShowSputtering end,
	}):Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show target\'s target'],
		checked = CFG.bShowTargetTargetAni,
		oncheck = function(bCheck)
			CFG.bShowTargetTargetAni = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:RefreshTTarget()
			end
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Boss target'],
		checked = CFG.bShowBossTarget,
		oncheck = function(bCheck)
			CFG.bShowBossTarget = bCheck
		end,
	}):AutoWidth():Width() + 5

	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Boss focus'],
		checked = CFG.bShowBossFocus,
		oncheck = function(bCheck)
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
		oncheck = function(bCheck)
			CFG.bShowTipAtRightBottom = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Don\'t show tip in fight'],
		checked = CFG.bHideTipInFight,
		oncheck = function(bCheck)
			CFG.bHideTipInFight = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = g_tStrings.STR_RAID_TARGET_ASSIST,
		checked = CFG.bTempTargetEnable,
		oncheck = function(bCheck)
			CFG.bTempTargetEnable = bCheck
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY - 1,
		value = CFG.nTempTargetDelay / 75,
		range = {0, 8},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(val)
			CFG.nTempTargetDelay = val * 75
		end,
		textfmt = function(val)
			return val == 0
				and _L['Target assist no delay.']
				or _L('Target assist delay %dms.', val * 75)
		end,
		autoenable = function() return CFG.bTempTargetEnable end,
	}):AutoWidth():Width()

	nX = nPaddingX + 10
	nY = nY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Alt view player'],
		checked = CFG.bAltView,
		oncheck = function(bCheck)
			CFG.bAltView = bCheck
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Disable in fight'],
		checked = not CFG.bAltViewInFight,
		oncheck = function(bCheck)
			CFG.bAltViewInFight = not bCheck
		end,
		autoenable = function() return CFG.bAltView end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 10
	nY = nY + 25
	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Faster Refresh HP (Greater performance loss)'],
		checked = CFG.bFasterHP,
		oncheck = function(bCheck)
			CFG.bFasterHP = bCheck
			if MY_CataclysmMain.GetFrame() then
				if bCheck then
					MY_CataclysmMain.GetFrame():RegisterEvent('RENDER_FRAME_UPDATE')
				else
					MY_CataclysmMain.GetFrame():UnRegisterEvent('RENDER_FRAME_UPDATE')
				end
			end
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 25
end
X.RegisterPanel(_L['Raid'], 'MY_Cataclysm', _L['Cataclysm'], 'ui/Image/UICommon/RaidTotal.uitex|62', PS)
