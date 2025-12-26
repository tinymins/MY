--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 截图助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ScreenShot/MY_ScreenShot'
local PLUGIN_NAME = 'MY_ScreenShot'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ScreenShot'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SCREENSHOT_MODE = {
	SHOW_UI = 1,
	HIDE_UI = 2,
}
local O = X.CreateUserSettingsModule('MY_ScreenShot', _L['System'], {
	szFileExName = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ScreenShot'],
		szDescription = X.MakeCaption({
			_L['file format'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'jpg',
	},
	nQuality = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ScreenShot'],
		szDescription = X.MakeCaption({
			_L['set quality (0-100)'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 100,
	},
	bAutoHideUI = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ScreenShot'],
		szDescription = X.MakeCaption({
			_L['auto hide ui while shot screen'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	szFilePath = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ScreenShot'],
		szDescription = X.MakeCaption({
			_L['set folder'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
})
local D = {}

function D.ShotScreen(szFilePath, nQuality)
	local szFullPath = ScreenShot(szFilePath, nQuality)
	X.OutputSystemMessage(_L('Shot screen succeed, file saved as %s .', szFullPath))
end

function D.ShotScreenEx(nShowUI)
	-- 生成可使用的完整截图目录
	local szFolderPath = O.szFilePath
	if szFolderPath~='' and not (string.sub(szFolderPath,2,2)==':' and IsFileExist(szFolderPath)) then
		X.OutputSystemMessage(_L('Shotscreen destination folder error: %s not exist. File has been save to default folder.', szFolderPath))
		szFolderPath = ''
	end
	local szFilePath
	if szFolderPath~='' then
		-- 生成文件完整路径名称
		local tDateTime = TimeToDate(GetCurrentTime())
		local i = 0
		repeat
			szFilePath = szFolderPath .. (string.format('%04d-%02d-%02d_%02d-%02d-%02d-%03d', tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) ..'.' .. O.szFileExName
			i=i+1
		until not IsFileExist(szFilePath)
	else
		szFilePath = O.szFileExName
	end
	-- 根据nShowUI不同方式实现截图
	local bStationVisible = Station.IsVisible()
	if nShowUI == SCREENSHOT_MODE.HIDE_UI and bStationVisible then
		Station.Hide()
		X.UI.SetShadowHandleVisible('*', false)
		X.DelayCall(100, function()
			D.ShotScreen(szFilePath, O.nQuality)
			X.DelayCall(300, function()
				Station.Show()
				X.UI.SetShadowHandleVisible('*', true)
			end)
		end)
	elseif nShowUI == SCREENSHOT_MODE.SHOW_UI and not bStationVisible then
		Station.Show()
		X.UI.SetShadowHandleVisible('*', true)
		X.DelayCall(100, function()
			D.ShotScreen(szFilePath, O.nQuality)
			X.DelayCall(300, function()
				Station.Hide()
				X.UI.SetShadowHandleVisible('*', true)
			end)
		end)
	else
		D.ShotScreen(szFilePath, O.nQuality)
	end
end

-- 快捷键绑定
X.RegisterHotKey('MY_ScreenShot_Hotkey', _L['shotscreen'], function() D.ShotScreenEx((O.bAutoHideUI and SCREENSHOT_MODE.HIDE_UI) or nil) end, nil)
X.RegisterHotKey('MY_ScreenShot_Hotkey_HideUI', _L['shotscreen without ui'], function() D.ShotScreenEx(SCREENSHOT_MODE.HIDE_UI) end, nil)
X.RegisterHotKey('MY_ScreenShot_Hotkey_ShowUI', _L['shotscreen with ui'], function() D.ShotScreenEx(SCREENSHOT_MODE.SHOW_UI) end, nil)

-- 面板注册
local PS = {}

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local fnRefreshPanel = function(ui)
		ui:Children('#WndCheckBox_HideUI'):Check(O.bAutoHideUI)
		ui:Children('#WndCombo_FileExName'):Text(O.szFileExName)
		ui:Children('#WndSlider_Quality'):Value(O.nQuality)
		ui:Children('#WndEditBox_SsRoot'):Text(O.szFilePath)
	end

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_HideUI',
		x = 30, y = 70,
		text = _L['auto hide ui while shot screen'],
		tip = {
			render = _L['Check it if you want to hide ui automatic.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		checked = O.bAutoHideUI,
		onCheck = function(bChecked) O.bAutoHideUI = bChecked end,
	})

	ui:Append('Text', { name = 'Text_FileExName', x = 30, y = 110, text = _L['file format'] })

	ui:Append('WndComboBox', {
		name = 'WndCombo_FileExName',
		x = 110, y = 110, w = 80,
		text = O.szFileExName,
		menu = function()
			return {
				{szOption = 'jpg', bChecked = O.szFileExName=='jpg', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'jpg' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
				{szOption = 'png', bChecked = O.szFileExName=='png', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'png' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
				{szOption = 'bmp', bChecked = O.szFileExName=='bmp', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'bmp' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
				{szOption = 'tga', bChecked = O.szFileExName=='tga', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() O.szFileExName = 'tga' ui:Children('#WndCombo_FileExName'):Text(O.szFileExName) end, fnAutoClose = function() return true end},
			}
		end,
	})

	ui:Append('Text', { name = 'Text_Quality', x = 30, y = 150, text = _L['set quality (0-100)'] })
	ui:Append('WndSlider', {
		name = 'WndSlider_Quality',
		x = 180, y = 150,
		sliderStyle = false,
		range = {0, 100},
		tip = {
			render = _L['Set screenshot quality(0-100): the larger number, the image will use more hdd space.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		onChange = function(nValue) O.nQuality = nValue end,
	})

	ui:Append('Text', { name = 'Text_SsRoot', x = 30, y = 190, text = _L['set folder'] })
	ui:Append('WndEditBox', {
		name = 'WndEditBox_SsRoot',
		x = 30, y = 220, w = 620, h = 100,
		text = O.szFilePath,
		tip = {
			render = _L['Set destination folder which screenshot file will be saved. Absolute path required.\nEx: D:/JX3_ScreenShot/\nAttention: let it blank will save screenshot to default folder.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		onChange = function(szValue)
			szValue = string.gsub(szValue, '^%s*(.-)%s*$', '%1')
			szValue = string.gsub(szValue, '\\', '/')
			szValue = string.gsub(szValue, '^(.-)/*$', '%1')
			szValue = szValue..((#szValue>0 and '/') or '')
			O.szFilePath = szValue
		end,
	})

	ui:Append('WndButton', {
		name = 'WndButton_HotkeyCheck',
		x = nW - 180, y = 30,
		buttonStyle = 'FLAT',
		text = _L['set default screenshot tool'],
		onClick = function()
			X.SetHotKey('MY_ScreenShot_Hotkey',1,44,false,false,false)
		end,
	})

	ui:Append('Text', {
		name = 'Text_SetHotkey',
		x = nW - 140, y = 60,
		text = _L['>> Set hotkey <<'],
		r = 255, g = 255, b = 0,
		onClick = function() X.SetHotKey() end,
	})

	fnRefreshPanel(ui)

	-- 注册默认工具检查
	X.BreatheCall('MY_ScreenShot_Hotkey_Check', 1000, function()
		local nKey, nShift, nCtrl, nAlt = X.GetHotKey('MY_ScreenShot_Hotkey')
		if type(nKey)=='nil' or nKey==0 then
			ui:Children('#WndButton_HotkeyCheck'):Text(_L['set default screenshot tool']):Enable(true)
		else
			ui:Children('#WndButton_HotkeyCheck'):Text(_L['as default already']):Enable(false)
		end
	end)
end

function PS.OnPanelDeactive()
	X.BreatheCall('MY_ScreenShot_Hotkey_Check', false)
end

X.Panel.Register(_L['System'], 'ScreenShot', _L['screenshot helper'], 'UI/Image/UICommon/Commonpanel.UITex|9', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
