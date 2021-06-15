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
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 1 }

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	x = X
	y = y + ui:Append('Text', { x = x, y = y, text = _L['configure'], font = 27 }):Height()

	x = X + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Configuration name'] }):AutoWidth():Width() + 5

	do local szConfigName = MY_Cataclysm.szConfigName
	x = x + ui:Append('WndEditBox', {
		x = x, y = y + 3, w = 200, h = 25,
		text = MY_Cataclysm.szConfigName,
		onchange = function(txt)
			szConfigName = LIB.TrimString(txt)
		end,
		onblur = function()
			if szConfigName == MY_Cataclysm.szConfigName then
				return
			end
			MY_CataclysmMain.SetConfigureName(szConfigName)
			MY_CataclysmMain.CheckEnableTeamPanel()
			LIB.SwitchTab('MY_Cataclysm', true)
		end,
	}):Width() + 5
	end

	-- 恢复默认
	y = y + ui:Append('WndButton', {
		x = x, y = y + 3,
		text = _L['Restore default'],
		buttonstyle = 'FLAT',
		onclick = function()
			MY_CataclysmMain.ConfirmRestoreConfig()
		end,
	}):Height() + 20

	x = X
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Cataclysm Team Panel'], font = 27 }):AutoWidth():Height()

	x = x + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Enable Cataclysm Team Panel'],
		oncheck = MY_CataclysmMain.ToggleTeamPanel, checked = MY_Cataclysm.bEnable,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Only in team'],
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

	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.WINDOW_LOCK,
		checked = not CFG.bDrag,
		oncheck = function(bCheck)
			CFG.bDrag = not bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmMain.GetFrame():EnableDrag(not bCheck)
			end
		end,
	}):AutoWidth():Height() + 5

	-- 提醒框
	x = X
	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_RAID_TIP_IMAGE, font = 27 }):Height()

	x = X + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show attention shadow'],
		checked = CFG.bShowAttention,
		oncheck = function(bCheck)
			CFG.bShowAttention = bCheck
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show caution animate'],
		checked = CFG.bShowCaution,
		oncheck = function(bCheck)
			CFG.bShowCaution = bCheck
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show screen head'],
		checked = CFG.bShowScreenHead,
		oncheck = function(bCheck)
			CFG.bShowScreenHead = bCheck
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
	}):AutoWidth():Width() + 5

	x = X + 10
	y = y + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Attack Warning'],
		checked = CFG.bHPHitAlert,
		oncheck = function(bCheck)
			CFG.bHPHitAlert = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show distance'],
		checked = CFG.bShowDistance,
		oncheck = function(bCheck)
			CFG.bShowDistance = bCheck
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['ZuiWu Effect'],
		checked = CFG.bShowEffect,
		oncheck = function(bCheck)
			CFG.bShowEffect = bCheck
		end,
		tip = _L['Show effect when teammate get ZuiWu, only your ZuiWu will be showen while you\'re BuTianJue.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show central party member tag'],
		checked = CFG.bShowSputtering,
		oncheck = function(bCheck)
			CFG.bShowSputtering = bCheck
		end,
		tip = _L['Show color on right top pos of central member of each party'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 25, h = 25,
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
							CFG.nSputteringFontAlpha = ceil((1 - f) * 255)
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
							CFG.nSputteringShadowAlpha = ceil((1 - f) * 255)
						end
						local fPosX, fPosY = Cursor.GetPos()
						GetUserPercentage(fnAction, nil, 1 - CFG.nSputteringShadowAlpha / 255, _L['Set sputtering shadow alpha'], { fPosX, fPosY, fPosX + 1, fPosY + 1 })
					end,
				},
			}
		end,
		autoenable = function() return CFG.bShowSputtering end,
	}):Width() + 5

	x = X + 10
	y = y + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show target\'s target'],
		checked = CFG.bShowTargetTargetAni,
		oncheck = function(bCheck)
			CFG.bShowTargetTargetAni = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:RefreshTTarget()
			end
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Boss target'],
		checked = CFG.bShowBossTarget,
		oncheck = function(bCheck)
			CFG.bShowBossTarget = bCheck
		end,
	}):AutoWidth():Width() + 5

	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Boss focus'],
		checked = CFG.bShowBossFocus,
		oncheck = function(bCheck)
			CFG.bShowBossFocus = bCheck
		end,
	}):AutoWidth():Height()

	-- 其他
	x = X
	y = y + 4
	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.OTHER, font = 27 }):Height()

	x = X + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show tip at right bottom'],
		checked = CFG.bShowTipAtRightBottom,
		oncheck = function(bCheck)
			CFG.bShowTipAtRightBottom = bCheck
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Don\'t show tip in fight'],
		checked = CFG.bHideTipInFight,
		oncheck = function(bCheck)
			CFG.bHideTipInFight = bCheck
		end,
	}):AutoWidth():Width() + 5

	x = X + 10
	y = y + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = g_tStrings.STR_RAID_TARGET_ASSIST,
		checked = CFG.bTempTargetEnable,
		oncheck = function(bCheck)
			CFG.bTempTargetEnable = bCheck
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndTrackbar', {
		x = x, y = y - 1,
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

	x = X + 10
	y = y + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Alt view player'],
		checked = CFG.bAltView,
		oncheck = function(bCheck)
			CFG.bAltView = bCheck
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Disable in fight'],
		checked = not CFG.bAltViewInFight,
		oncheck = function(bCheck)
			CFG.bAltViewInFight = not bCheck
		end,
		autoenable = function() return CFG.bAltView end,
	}):AutoWidth():Width() + 5

	x = X + 10
	y = y + 25
	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
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
	y = y + 25
end
LIB.RegisterPanel(_L['Raid'], 'MY_Cataclysm', _L['Cataclysm'], 'ui/Image/UICommon/RaidTotal.uitex|62', PS)
