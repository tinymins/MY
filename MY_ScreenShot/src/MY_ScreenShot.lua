--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 截图助手
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ScreenShot'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ScreenShot'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------
local SCREENSHOT_MODE = {
	SHOW_UI = 1,
	HIDE_UI = 2,
}
local OR = LIB.CreateUserSettingsModule('MY_ScreenShot', _L['System'], {
	bUseGlobalConfig = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	szFileExName_Global = {
		ePathType = PATH_TYPE.GLOBAL,
		szDataKey = 'szFileExName',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.String,
		xDefaultValue = 'jpg',
	},
	nQuality_Global = {
		ePathType = PATH_TYPE.GLOBAL,
		szDataKey = 'nQuality',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.Number,
		xDefaultValue = 100,
	},
	bAutoHideUI_Global = {
		ePathType = PATH_TYPE.GLOBAL,
		szDataKey = 'bAutoHideUI',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	szFilePath_Global = {
		ePathType = PATH_TYPE.GLOBAL,
		szDataKey = 'szFilePath',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.String,
		xDefaultValue = '',
	},
	szFileExName_Role = {
		ePathType = PATH_TYPE.ROLE,
		szDataKey = 'szFileExName',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.String,
		xDefaultValue = 'jpg',
	},
	nQuality_Role = {
		ePathType = PATH_TYPE.ROLE,
		szDataKey = 'nQuality',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.Number,
		xDefaultValue = 100,
	},
	bAutoHideUI_Role = {
		ePathType = PATH_TYPE.ROLE,
		szDataKey = 'bAutoHideUI',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	szFilePath_Role = {
		ePathType = PATH_TYPE.ROLE,
		szDataKey = 'szFilePath',
		szLabel = _L['MY_ScreenShot'],
		xSchema = Schema.String,
		xDefaultValue = '',
	},
})
local O = setmetatable({}, {
	__index = function(_, k)
		if k == 'bUseGlobalConfig' then
			return OR[k]
		end
		if OR.bUseGlobalConfig then
			return OR[k .. '_Global']
		end
		return OR[k .. '_Role']
	end,
	__newindex = function(_, k, v)
		if k == 'bUseGlobalConfig' then
			OR[k] = v
		elseif OR.bUseGlobalConfig then
			OR[k .. '_Global'] = v
		else
			OG[k .. '_Role'] = v
		end
	end,
})
local D = {}

function D.ShotScreen(szFilePath, nQuality)
	local szFullPath = ScreenShot(szFilePath, nQuality)
	LIB.Sysmsg(_L('Shot screen succeed, file saved as %s .', szFullPath))
end

function D.ShotScreenEx(nShowUI)
	-- 生成可使用的完整截图目录
	local szFolderPath = O.szFilePath
	if szFolderPath~='' and not (sub(szFolderPath,2,2)==':' and IsFileExist(szFolderPath)) then
		LIB.Sysmsg(_L('Shotscreen destination folder error: %s not exist. File has been save to default folder.', szFolderPath))
		szFolderPath = ''
	end
	local szFilePath
	if szFolderPath~='' then
		-- 生成文件完整路径名称
		local tDateTime = TimeToDate(GetCurrentTime())
		local i = 0
		repeat
			szFilePath = szFolderPath .. (format('%04d-%02d-%02d_%02d-%02d-%02d-%03d', tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) ..'.' .. O.szFileExName
			i=i+1
		until not IsFileExist(szFilePath)
	else
		szFilePath = O.szFileExName
	end
	-- 根据nShowUI不同方式实现截图
	local bStationVisible = Station.IsVisible()
	if nShowUI == SCREENSHOT_MODE.HIDE_UI and bStationVisible then
		Station.Hide()
		UI.TempSetShadowHandleVisible(false)
		LIB.DelayCall(100, function()
			D.ShotScreen(szFilePath, O.nQuality)
			LIB.DelayCall(300, function()
				Station.Show()
				UI.RevertShadowHandleVisible()
			end)
		end)
	elseif nShowUI == SCREENSHOT_MODE.SHOW_UI and not bStationVisible then
		Station.Show()
		UI.TempSetShadowHandleVisible(true)
		LIB.DelayCall(100, function()
			D.ShotScreen(szFilePath, O.nQuality)
			LIB.DelayCall(300, function()
				Station.Hide()
				UI.RevertShadowHandleVisible()
			end)
		end)
	else
		D.ShotScreen(szFilePath, O.nQuality)
	end
end

-- 快捷键绑定
LIB.RegisterHotKey('MY_ScreenShot_Hotkey', _L['shotscreen'], function() D.ShotScreenEx((O.bAutoHideUI and SCREENSHOT_MODE.HIDE_UI) or nil) end, nil)
LIB.RegisterHotKey('MY_ScreenShot_Hotkey_HideUI', _L['shotscreen without ui'], function() D.ShotScreenEx(SCREENSHOT_MODE.HIDE_UI) end, nil)
LIB.RegisterHotKey('MY_ScreenShot_Hotkey_ShowUI', _L['shotscreen with ui'], function() D.ShotScreenEx(SCREENSHOT_MODE.SHOW_UI) end, nil)

-- 面板注册
local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local fnRefreshPanel = function(ui)
		ui:Children('#WndCheckBox_HideUI'):Check(O.bAutoHideUI)
		ui:Children('#WndCombo_FileExName'):Text(O.szFileExName)
		ui:Children('#WndTrackbar_Quality'):Value(O.nQuality)
		ui:Children('#WndEditBox_SsRoot'):Text(O.szFilePath)
	end

	ui:Append('WndCheckBox', 'WndCheckBox_UseGlobal'):Pos(30,30):Width(200)
	  :Text(_L['Use global config']):Tip(_L['Check to use global config, otherwise use private setting.'])
	  :Check(function(bChecked) O.bUseGlobalConfig = bChecked fnRefreshPanel(ui) end)
	  :Check(O.bUseGlobalConfig)

	ui:Append('WndCheckBox', 'WndCheckBox_HideUI'):Pos(30,70)
	  :Text(_L['auto hide ui while shot screen']):Tip(_L['Check it if you want to hide ui automatic.'])
	  :Check(function(bChecked) O.bAutoHideUI = bChecked end)
	  :Check(O.bAutoHideUI)

	ui:Append('Text', 'Text_FileExName'):Text(_L['file format']):Pos(30,110)
	ui:Append('WndComboBox', 'WndCombo_FileExName'):Pos(110,110):Width(80)
	  :Menu(function()
		return {
			{szOption = 'jpg', bChecked = O.szFileExName=='jpg', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'jpg' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
			{szOption = 'png', bChecked = O.szFileExName=='png', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'png' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
			{szOption = 'bmp', bChecked = O.szFileExName=='bmp', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'bmp' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
			{szOption = 'tga', bChecked = O.szFileExName=='tga', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'tga' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
		}
	  end)
	  :Text(O.szFileExName)

	ui:Append('Text', 'Text_Quality'):Text(_L['set quality (0-100)']):Pos(30,150)
	ui:Append('WndTrackbar', 'WndTrackbar_Quality'):Pos(180,150)
	  :TrackbarStyle(false):Range(0, 100)
	  :Tip(_L['Set screenshot quality(0-100): the larger number, the image will use more hdd space.'])
	  :Change(function(nValue) O.nQuality = nValue end)

	ui:Append('Text', 'Text_SsRoot'):Text(_L['set folder']):Pos(30,190)
	ui:Append('WndEditBox', 'WndEditBox_SsRoot'):Pos(30,220):Size(620,100)
	  :Text(O.szFilePath)
	  :Change(function(szValue)
		szValue = gsub(szValue, '^%s*(.-)%s*$', '%1')
		szValue = gsub(szValue, '\\', '/')
		szValue = gsub(szValue, '^(.-)/*$', '%1')
		szValue = szValue..((#szValue>0 and '/') or '')
		O.szFilePath = szValue
	  end)
	  :Tip(_L['Set destination folder which screenshot file will be saved. Absolute path required.\nEx: D:/JX3_ScreenShot/\nAttention: let it blank will save screenshot to default folder.'],UI.TIP_POSITION.TOP_BOTTOM)

	ui:Append('WndButton', 'WndButton_HotkeyCheck'):Pos(w-180, 30):ButtonStyle('FLAT'):Width(170)
	  :Text(_L['set default screenshot tool'])
	  :Click(function() LIB.SetHotKey('MY_ScreenShot_Hotkey',1,44,false,false,false) end)

	ui:Append('Text', 'Text_SetHotkey'):Pos(w-140, 60):Color(255,255,0)
	  :Text(_L['>> Set hotkey <<'])
	  :Click(function() LIB.SetHotKey() end)

	fnRefreshPanel(ui)

	-- 注册默认工具检查
	LIB.BreatheCall('MY_ScreenShot_Hotkey_Check', 1000, function()
		local nKey, nShift, nCtrl, nAlt = LIB.GetHotKey('MY_ScreenShot_Hotkey')
		if type(nKey)=='nil' or nKey==0 then
			ui:Children('#WndButton_HotkeyCheck'):Text(_L['set default screenshot tool']):Enable(true)
		else
			ui:Children('#WndButton_HotkeyCheck'):Text(_L['as default already']):Enable(false)
		end
	end)
end

function PS.OnPanelDeactive()
	LIB.BreatheCall('MY_ScreenShot_Hotkey_Check', false)
end

LIB.RegisterPanel(_L['System'], 'ScreenShot', _L['screenshot helper'], 'UI/Image/UICommon/Commonpanel.UITex|9', PS)
