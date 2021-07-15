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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
	return
end
--------------------------------------------------------------------------

local MY_TM_REMOTE_DATA_ROOT = MY_TeamMon.MY_TM_REMOTE_DATA_ROOT

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local nX, nY = X, Y
	local nLineH = 22

	-- ui:Append('WndButton', {
	-- 	x = 400, y = 20, text = g_tStrings.HELP_PANEL,
	-- 	buttonstyle = 'FLAT',
	-- 	onclick = function()
	-- 		OpenInternetExplorer('https://github.com/luckyyyyy/JH/blob/dev/JH_DBM/README.md')
	-- 	end,
	-- })

	nX, nY = ui:Append('Text', { x = X, y = Y, text = _L['Master switch'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = X + 10, y = nY, text = _L['Enable MY_TeamMon'],
		checked = MY_TeamMon.bEnable,
		oncheck = function(bCheck)
			MY_TeamMon.bEnable = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	if not LIB.IsShieldedVersion('MY_TargetMon', 2) then
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Enable circle'],
			checked = MY_TeamMon_CC.bEnable,
			oncheck = function(bCheck)
				MY_TeamMon_CC.bEnable = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Circle border'],
			checked = MY_TeamMon_CC.bBorder,
			oncheck = function(bCheck)
				MY_TeamMon_CC.bBorder = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nY = nY + nLineH

	nX, nY = ui:Append('Text', { x = X, y = nY + 5, text = _L['Enable alarm (master switch)'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = X + 10, y = nY,
		text = _L['Team channel alarm'],
		color = GetMsgFontColor('MSG_TEAM', true),
		checked = MY_TeamMon.bPushTeamChannel,
		oncheck = function(bCheck)
			MY_TeamMon.bPushTeamChannel = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY,
		text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
		checked = MY_TeamMon.bPushWhisperChannel,
		oncheck = function(bCheck)
			MY_TeamMon.bPushWhisperChannel = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Buff list'],
		checked = MY_TeamMon.bPushBuffList,
		oncheck = function(bCheck)
			MY_TeamMon.bPushBuffList = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Center alarm'],
		checked = MY_TeamMon.bPushCenterAlarm,
		oncheck = function(bCheck)
			MY_TeamMon.bPushCenterAlarm = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = X + 5
	if not LIB.IsShieldedVersion('MY_TargetMon', 2) then
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Large text alarm'],
			checked = MY_TeamMon.bPushBigFontAlarm,
			oncheck = function(bCheck)
				MY_TeamMon.bPushBigFontAlarm = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Fullscreen alarm'],
			checked = MY_TeamMon.bPushFullScreen,
			oncheck = function(bCheck)
				MY_TeamMon.bPushFullScreen = bCheck
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nX = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Party buff list'],
		checked = MY_TeamMon.bPushPartyBuffList,
		oncheck = function(bCheck)
			MY_TeamMon.bPushPartyBuffList = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Lifebar alarm'],
		tip = _L['Requires MY_LifeBar loaded.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		checked = MY_TeamMon.bPushScreenHead,
		oncheck = function(bCheck)
			MY_TeamMon.bPushScreenHead = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = X, y = nY + 5, text = _L['Team panel bind show buff'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = X + 10, y = nY, text = _L['Team panel bind show buff'],
		checked = MY_TeamMon.bPushTeamPanel,
		oncheck = function(bCheck)
			MY_TeamMon.bPushTeamPanel = bCheck
			FireUIEvent('MY_TM_CREATE_CACHE')
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = X, y = nY + 5, text = _L['Buff list'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndComboBox', {
		x = X + 10, y = nY, text = _L['Max buff count'],
		menu = function()
			local menu = {}
			for k, v in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }) do
				insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BL.nCount == v, fnAction = function()
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
				insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BL.fScale == v / 55, fnAction = function()
					MY_TeamMon_BL.fScale = v / 55
				end })
			end
			return menu
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = X, y = nY + 5, text = _L['Data save mode'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = X + 10, y = nY, text = _L['Use common data'],
		checked = MY_TeamMon.bCommon,
		oncheck = function(bCheck)
			MY_TeamMon.bCommon = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = X + 5, y = nY + 15, text = _L['Data panel'],
		buttonstyle = 'FLAT',
		onclick = MY_TeamMon_UI.TogglePanel,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Export data'],
		buttonstyle = 'FLAT',
		onclick = MY_TeamMon_UI.OpenExportPanel,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY + 15, text = _L['Import data'],
		buttonstyle = 'FLAT',
		menu = function()
			local menu = {}
			insert(menu, {
				szOption = _L['Import data (local)'],
				fnAction = function() MY_TeamMon_UI.OpenImportPanel() end,
			})
			local szLang = GLOBAL.GAME_LANG
			if szLang == 'zhcn' or szLang == 'zhtw' then
				insert(menu, {
					szOption = _L['Import data (web)'],
					fnAction = function() MY_TeamMon_RR.OpenPanel() end,
				})
			end
			insert(menu, {
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
		buttonstyle = 'FLAT',
		onclick = function()
			local szRoot = LIB.GetAbsolutePath(MY_TM_REMOTE_DATA_ROOT):gsub('/', '\\')
			LIB.OpenFolder(szRoot)
			UI.OpenTextEditor(szRoot)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
end

LIB.RegisterPanel(_L['Raid'], 'MY_TeamMon', _L['MY_TeamMon'], 'ui/Image/UICommon/FBlist.uitex|34', PS)
