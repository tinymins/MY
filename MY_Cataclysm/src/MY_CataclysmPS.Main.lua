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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
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
			MY_Cataclysm.SetConfigureName(szConfigName)
			MY_Cataclysm.CheckEnableTeamPanel()
			LIB.SwitchTab('MY_Cataclysm', true)
		end,
	}):Width() + 5
	end

	-- 恢复默认
	y = y + ui:Append('WndButton', {
		x = x, y = y + 3,
		text = _L['Restore default'],
		buttonstyle = 2,
		onclick = function()
			MY_Cataclysm.ConfirmRestoreConfig()
		end,
	}):Height() + 20

	x = X
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Cataclysm Team Panel'], font = 27 }):AutoWidth():Height()

	x = x + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Enable Cataclysm Team Panel'],
		oncheck = MY_Cataclysm.ToggleTeamPanel, checked = MY_Cataclysm.bEnable,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Only in team'],
		checked = CFG.bShowInRaid,
		oncheck = function(bCheck)
			CFG.bShowInRaid = bCheck
			if MY_Cataclysm.CheckCataclysmEnable() then
				MY_Cataclysm.ReloadCataclysmPanel()
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
			if MY_Cataclysm.GetFrame() then
				MY_Cataclysm.GetFrame():EnableDrag(not bCheck)
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
			if MY_Cataclysm.GetFrame() then
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

	local me = GetClientPlayer()
	if me.dwForceID == CONSTANT.FORCE_TYPE.WU_DU then
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, text = _L['ZuiWu Effect'],
			color = { LIB.GetForceColor(6) },
			checked = CFG.bShowEffect,
			oncheck = function(bCheck)
				CFG.bShowEffect = bCheck
			end,
		}):AutoWidth():Width() + 5
	end

	x = X + 10
	y = y + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show target\'s target'],
		checked = CFG.bShowTargetTargetAni,
		oncheck = function(bCheck)
			CFG.bShowTargetTargetAni = bCheck
			if MY_Cataclysm.GetFrame() then
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
	-- y = y + ui:Append('WndCheckBox', { x = 10, y = nY, text = _L['Faster Refresh HP(Greater performance loss)'], checked = CFG.bFasterHP, enable = false })
	-- :Click(function(bCheck)
	-- 	CFG.bFasterHP = bCheck
	-- 	if MY_Cataclysm.GetFrame() then
	-- 		if bCheck then
	-- 			MY_Cataclysm.GetFrame():RegisterEvent('RENDER_FRAME_UPDATE')
	-- 		else
	-- 			MY_Cataclysm.GetFrame():UnRegisterEvent('RENDER_FRAME_UPDATE')
	-- 		end
	-- 	end
	-- end, true, true):Pos('BOTTOMRIGHT')
	y = y + 25
end
LIB.RegisterPanel(_L['Raid'], 'MY_Cataclysm', _L['Cataclysm'], 'ui/Image/UICommon/RaidTotal.uitex|62', PS)
