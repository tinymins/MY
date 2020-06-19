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
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall = LIB.Call, LIB.XpCall, LIB.SafeCall
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ScreenShot'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ScreenShot'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local _GLOBAL_CONFIG_ = {'config/screenshot.jx3dat', PATH_TYPE.GLOBAL}
local _MY_ScreenShot = {}
MY_ScreenShot = MY_ScreenShot or {}
MY_ScreenShot.Const = {}
MY_ScreenShot.Const.SHOW_UI = 1
MY_ScreenShot.Const.HIDE_UI = 2
MY_ScreenShot.globalConfig = {
    szFileExName = 'jpg',
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = '',
}
MY_ScreenShot.globalConfig = LIB.LoadLUAData(_GLOBAL_CONFIG_) or MY_ScreenShot.globalConfig
MY_ScreenShot.bUseGlobalConfig = true
MY_ScreenShot.privateConfig = {
    szFileExName = 'jpg',
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = '',
}
RegisterCustomData('MY_ScreenShot.bUseGlobalConfig')
for k, _ in pairs(MY_ScreenShot.privateConfig) do
    RegisterCustomData('MY_ScreenShot.privateConfig.' .. k)
end
-- 取设置
MY_ScreenShot.SetConfig = function(szKey, oValue)
    if MY_ScreenShot.bUseGlobalConfig then
        MY_ScreenShot.globalConfig[szKey] = oValue
        LIB.SaveLUAData(_GLOBAL_CONFIG_, MY_ScreenShot.globalConfig)
    else
        MY_ScreenShot.privateConfig[szKey] = oValue
    end
end
-- 存设置
MY_ScreenShot.GetConfig = function(szKey)
    if MY_ScreenShot.bUseGlobalConfig then
        return MY_ScreenShot.globalConfig[szKey]
    else
        return MY_ScreenShot.privateConfig[szKey]
    end
end
_MY_ScreenShot.ShotScreen = function(szFilePath, nQuality)
    local szFullPath = ScreenShot(szFilePath, nQuality)
    LIB.Sysmsg(_L('Shot screen succeed, file saved as %s .', szFullPath))
end
MY_ScreenShot.ShotScreen = function(nShowUI)
    -- 生成可使用的完整截图目录
    local szFolderPath = MY_ScreenShot.GetConfig('szFilePath')
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
            szFilePath = szFolderPath .. (format('%04d-%02d-%02d_%02d-%02d-%02d-%03d', tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) ..'.' .. MY_ScreenShot.GetConfig('szFileExName')
            i=i+1
        until not IsFileExist(szFilePath)
    else
        szFilePath = MY_ScreenShot.GetConfig('szFileExName')
    end
    -- 根据nShowUI不同方式实现截图
    local bStationVisible = Station.IsVisible()
    if nShowUI == MY_ScreenShot.Const.HIDE_UI and bStationVisible then
        Station.Hide()
        UI.TempSetShadowHandleVisible(false)
        LIB.DelayCall(100, function()
            _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'))
            LIB.DelayCall(300, function()
                Station.Show()
                UI.RevertShadowHandleVisible()
            end)
        end)
    elseif nShowUI == MY_ScreenShot.Const.SHOW_UI and not bStationVisible then
        Station.Show()
        UI.TempSetShadowHandleVisible(true)
        LIB.DelayCall(100, function()
            _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'))
            LIB.DelayCall(300, function()
                Station.Hide()
                UI.RevertShadowHandleVisible()
            end)
        end)
    else
        _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'))
    end
end
-- 标签栏激活
_MY_ScreenShot.OnPanelActive = function(wnd)
    local ui = UI(wnd)
    local w, h = ui:Size()
    local fnRefreshPanel = function(ui)
        ui:Children('#WndCheckBox_HideUI'):Check(MY_ScreenShot.GetConfig('bAutoHideUI'))
        ui:Children('#WndCombo_FileExName'):Text(MY_ScreenShot.GetConfig('szFileExName'))
        ui:Children('#WndTrackbar_Quality'):Value(MY_ScreenShot.GetConfig('nQuality'))
        ui:Children('#WndEditBox_SsRoot'):Text(MY_ScreenShot.GetConfig('szFilePath'))
    end

    ui:Append('WndCheckBox', 'WndCheckBox_UseGlobal'):Pos(30,30):Width(200)
      :Text(_L['use global config']):Tip(_L['Check to use global config, otherwise use private setting.'])
      :Check(function(bChecked) MY_ScreenShot.bUseGlobalConfig = bChecked fnRefreshPanel(ui) end)
      :Check(MY_ScreenShot.bUseGlobalConfig)

    ui:Append('WndCheckBox', 'WndCheckBox_HideUI'):Pos(30,70)
      :Text(_L['auto hide ui while shot screen']):Tip(_L['Check it if you want to hide ui automatic.'])
      :Check(function(bChecked) MY_ScreenShot.SetConfig('bAutoHideUI', bChecked) end)
      :Check(MY_ScreenShot.GetConfig('bAutoHideUI'))

    ui:Append('Text', 'Text_FileExName'):Text(_L['file format']):Pos(30,110)
    ui:Append('WndComboBox', 'WndCombo_FileExName'):Pos(110,110):Width(80)
      :Menu(function()
        return {
            {szOption = 'jpg', bChecked = MY_ScreenShot.GetConfig('szFileExName')=='jpg', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() MY_ScreenShot.SetConfig('szFileExName', 'jpg') ui:Children('#WndCombo_FileExName'):Text(MY_ScreenShot.GetConfig('szFileExName')) end, fnAutoClose = function() return true end},
            {szOption = 'png', bChecked = MY_ScreenShot.GetConfig('szFileExName')=='png', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() MY_ScreenShot.SetConfig('szFileExName', 'png') ui:Children('#WndCombo_FileExName'):Text(MY_ScreenShot.GetConfig('szFileExName')) end, fnAutoClose = function() return true end},
            {szOption = 'bmp', bChecked = MY_ScreenShot.GetConfig('szFileExName')=='bmp', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() MY_ScreenShot.SetConfig('szFileExName', 'bmp') ui:Children('#WndCombo_FileExName'):Text(MY_ScreenShot.GetConfig('szFileExName')) end, fnAutoClose = function() return true end},
            {szOption = 'tga', bChecked = MY_ScreenShot.GetConfig('szFileExName')=='tga', rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() MY_ScreenShot.SetConfig('szFileExName', 'tga') ui:Children('#WndCombo_FileExName'):Text(MY_ScreenShot.GetConfig('szFileExName')) end, fnAutoClose = function() return true end},
        }
      end)
      :Text(MY_ScreenShot.GetConfig('szFileExName'))

    ui:Append('Text', 'Text_Quality'):Text(_L['set quality (0-100)']):Pos(30,150)
    ui:Append('WndTrackbar', 'WndTrackbar_Quality'):Pos(180,150)
      :TrackbarStyle(false):Range(0, 100)
      :Tip(_L['Set screenshot quality(0-100): the larger number, the image will use more hdd space.'])
      :Change(function(nValue) MY_ScreenShot.SetConfig('nQuality', nValue) end)

    ui:Append('Text', 'Text_SsRoot'):Text(_L['set folder']):Pos(30,190)
    ui:Append('WndEditBox', 'WndEditBox_SsRoot'):Pos(30,220):Size(620,100)
      :Text(MY_ScreenShot.GetConfig('szFilePath'))
      :Change(function(szValue)
        szValue = gsub(szValue, '^%s*(.-)%s*$', '%1')
        szValue = gsub(szValue, '\\', '/')
        szValue = gsub(szValue, '^(.-)/*$', '%1')
        szValue = szValue..((#szValue>0 and '/') or '')
        MY_ScreenShot.SetConfig('szFilePath', szValue)
      end)
      :Tip(_L['Set destination folder which screenshot file will be saved. Absolute path required.\nEx: D:/JX3_ScreenShot/\nAttention: let it blank will save screenshot to default folder.'],UI.TIP_POSITION.TOP_BOTTOM)

    ui:Append('WndButton', 'WndButton_HotkeyCheck'):Pos(w-180, 30):ButtonStyle(2):Width(170)
      :Text(_L['set default screenshot tool'])
      :Click(function() LIB.SetHotKey('MY_ScreenShot_Hotkey',1,44,false,false,false) end)

    ui:Append('Text', 'Text_SetHotkey'):Pos(w-140, 60):Color(255,255,0)
      :Text(_L['>> set hotkey <<'])
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
_MY_ScreenShot.OnPanelDeactive = function( ... )
    LIB.BreatheCall('MY_ScreenShot_Hotkey_Check', false)
end
-- 快捷键绑定
-----------------------------------------------
LIB.RegisterHotKey('MY_ScreenShot_Hotkey', _L['shotscreen'], function() MY_ScreenShot.ShotScreen((MY_ScreenShot.GetConfig('bAutoHideUI') and MY_ScreenShot.Const.HIDE_UI) or nil) end, nil)
LIB.RegisterHotKey('MY_ScreenShot_Hotkey_HideUI', _L['shotscreen without ui'], function() MY_ScreenShot.ShotScreen(MY_ScreenShot.Const.HIDE_UI) end, nil)
LIB.RegisterHotKey('MY_ScreenShot_Hotkey_ShowUI', _L['shotscreen with ui'], function() MY_ScreenShot.ShotScreen(MY_ScreenShot.Const.SHOW_UI) end, nil)
LIB.RegisterPanel( 'ScreenShot', _L['screenshot helper'], _L['System'], 'UI/Image/UICommon/Commonpanel.UITex|9', { OnPanelActive = _MY_ScreenShot.OnPanelActive, OnPanelDeactive = _MY_ScreenShot.OnPanelDeactive } )
