--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队监控设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamMon/lang/')
if not LIB.AssertVersion('MY_TeamMon', _L['MY_TeamMon'], 0x2013500) then
	return
end

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local nX, nY = X, Y
	local nLineH = 22

	-- ui:append('WndButton2', {
	-- 	x = 400, y = 20, text = g_tStrings.HELP_PANEL,
	-- 	onclick = function()
	-- 		OpenInternetExplorer('https://github.com/luckyyyyy/JH/blob/dev/JH_DBM/README.md')
	-- 	end,
	-- })

	nX, nY = ui:append('Text', { x = X, y = Y, text = _L['Master switch'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndCheckBox', {
		x = X + 10, y = nY, text = _L['Enable MY_TeamMon'],
		checked = MY_TeamMon.bEnable,
		oncheck = function(bCheck)
			MY_TeamMon.Enable(bCheck, true)
			MY_TeamMon.bEnable = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	if Circle and not LIB.IsShieldedVersion(2) then
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Circle Enable'],
			checked = Circle.bEnable,
			oncheck = function(bCheck)
				Circle.Enable(bCheck)
				if bCheck then
					FireUIEvent('CIRCLE_RELOAD')
				end
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Circle Border'],
			checked = Circle.bBorder,
			oncheck = function(bCheck)
				Circle.bBorder = bCheck
				FireUIEvent('CIRCLE_RELOAD')
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
	end
	nY = nY + nLineH

	nX, nY = ui:append('Text', { x = X, y = nY + 5, text = _L['Enable alarm (master switch)'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndCheckBox', {
		x = X + 10, y = nY,
		text = _L['Team channel alarm'],
		color = GetMsgFontColor('MSG_TEAM', true),
		checked = MY_TeamMon.bPushTeamChannel,
		oncheck = function(bCheck)
			MY_TeamMon.bPushTeamChannel = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndCheckBox', {
		x = nX + 5, y = nY,
		text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
		checked = MY_TeamMon.bPushWhisperChannel,
		oncheck = function(bCheck)
			MY_TeamMon.bPushWhisperChannel = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Buff list'],
		checked = MY_TeamMon.bPushBuffList,
		oncheck = function(bCheck)
			MY_TeamMon.bPushBuffList = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Center alarm'],
		checked = MY_TeamMon.bPushCenterAlarm,
		oncheck = function(bCheck)
			MY_TeamMon.bPushCenterAlarm = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = X + 5
	if not LIB.IsShieldedVersion(2) then
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Large text alarm'],
			checked = MY_TeamMon.bPushBigFontAlarm,
			oncheck = function(bCheck)
				MY_TeamMon.bPushBigFontAlarm = bCheck
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
		nX = ui:append('WndCheckBox', {
			x = nX + 5, y = nY, text = _L['Fullscreen alarm'],
			checked = MY_TeamMon.bPushFullScreen,
			oncheck = function(bCheck)
				MY_TeamMon.bPushFullScreen = bCheck
			end,
		}, true):autoWidth():pos('BOTTOMRIGHT')
	end
	nX = ui:append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Party buff list'],
		checked = MY_TeamMon.bPushPartyBuffList,
		oncheck = function(bCheck)
			MY_TeamMon.bPushPartyBuffList = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndCheckBox', {
		x = nX + 5, y = nY, text = _L['Lifebar alarm'],
		tip = _L['Requires MY_LifeBar loaded.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		checked = MY_TeamMon.bPushScreenHead,
		oncheck = function(bCheck)
			MY_TeamMon.bPushScreenHead = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('Text', { x = X, y = nY + 5, text = _L['Team panel bind show buff'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndCheckBox', {
		x = X + 10, y = nY, text = _L['Team panel bind show buff'],
		checked = MY_TeamMon.bPushTeamPanel,
		oncheck = function(bCheck)
			MY_TeamMon.bPushTeamPanel = bCheck
			FireUIEvent('MY_TM_CREATE_CACHE')
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('Text', { x = X, y = nY + 5, text = _L['Buff list'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndComboBox', {
		x = X + 10, y = nY, text = _L['Max buff count'],
		menu = function()
			local menu = {}
			for k, v in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }) do
				table.insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BL.nCount == v, fnAction = function()
					FireUIEvent('MY_TM_BL_RESIZE', nil, v)
				end })
			end
			return menu
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndComboBox', {
		x = nX + 5, y = nY, text = _L['Buff size'],
		menu = function()
			local menu = {}
			for k, v in ipairs({ 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 100 }) do
				table.insert(menu, { szOption = v, bMCheck = true, bChecked = MY_TeamMon_BL.fScale == v / 55, fnAction = function()
					FireUIEvent('MY_TM_BL_RESIZE', v / 55)
				end })
			end
			return menu
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('Text', { x = X, y = nY + 5, text = _L['Data save mode'], font = 27 }, true):autoWidth():pos('BOTTOMRIGHT')
	nX, nY = ui:append('WndCheckBox', {
		x = X + 10, y = nY, text = _L['Use common data'],
		checked = MY_TeamMon.bCommon,
		oncheck = function(bCheck)
			MY_TeamMon.bCommon = bCheck
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndButton2', {
		x = X + 5, y = nY + 15, text = _L['Data panel'],
		onclick = MY_TeamMon_UI.TogglePanel,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndButton2', {
		x = nX + 5, y = nY + 15, text = _L['Export data'],
		onclick = MY_TeamMon_UI.OpenExportPanel,
	}, true):autoWidth():pos('BOTTOMRIGHT')
	nX = ui:append('WndButton2', {
		x = nX + 5, y = nY + 15, text = _L['Import data'],
		menu = function()
			local szLang = select(3, GetVersion())
			local menu = {}
			table.insert(menu, { szOption = _L['Import data (local)'], fnAction = function() MY_TeamMon_UI.OpenImportPanel() end }) -- 有传参 不要改
			local szLang = select(3, GetVersion())
			if szLang == 'zhcn' or szLang == 'zhtw' then
				table.insert(menu, { szOption = _L['Import data (web)'], fnAction = MY_TeamMon_RR.OpenPanel })
			end
			return menu
		end,
	}, true):autoWidth():pos('BOTTOMRIGHT')
end

LIB.RegisterPanel('MY_TeamMon', _L['MY_TeamMon'], _L['Raid'], 'ui/Image/UICommon/FBlist.uitex|34', PS)
