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
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, {}

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
	y = y + ui:Append('WndButton2', {
		x = x, y = y + 3, text = _L['Restore default'],
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
		x = x, y = y, text = _L['Don\'t show Tip in fight'],
		checked = CFG.bHideTipInFight,
		oncheck = function(bCheck)
			CFG.bHideTipInFight = bCheck
		end,
	}):AutoWidth():Width() + 5

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
LIB.RegisterPanel('MY_Cataclysm', _L['Cataclysm'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|62', PS)
