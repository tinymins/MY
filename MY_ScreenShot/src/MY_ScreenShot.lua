----------------------------------------------------
-- 茗伊截图助手 ver 0.2 Build 20140717
-- Code by: 翟一鸣tinymins @ ZhaiYiMing.CoM
-- 电五·双梦镇·茗伊
---------------------------------------------------
local _GLOBAL_CONFIG_ = {"config/screenshot.jx3dat", MY_DATA_PATH.GLOBAL}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ScreenShot/lang/")
local _MY_ScreenShot = {}
MY_ScreenShot = MY_ScreenShot or {}
MY_ScreenShot.Const = {}
MY_ScreenShot.Const.SHOW_UI = 1
MY_ScreenShot.Const.HIDE_UI = 2
MY_ScreenShot.globalConfig = {
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "",
}
MY_ScreenShot.globalConfig = MY.LoadLUAData(_GLOBAL_CONFIG_) or MY_ScreenShot.globalConfig
MY_ScreenShot.bUseGlobalConfig = true
MY_ScreenShot.privateConfig = {
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "",
}
RegisterCustomData("MY_ScreenShot.bUseGlobalConfig")
for k, _ in pairs(MY_ScreenShot.privateConfig) do
    RegisterCustomData("MY_ScreenShot.privateConfig." .. k)
end
-- 取设置
MY_ScreenShot.SetConfig = function(szKey, oValue)
    if MY_ScreenShot.bUseGlobalConfig then
        MY_ScreenShot.globalConfig[szKey] = oValue
        MY.SaveLUAData(_GLOBAL_CONFIG_, MY_ScreenShot.globalConfig)
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
    MY.Sysmsg({_L("Shot screen succeed, file saved as %s .", szFullPath)})
end
MY_ScreenShot.ShotScreen = function(nShowUI)
    -- 生成可使用的完整截图目录
    local szFolderPath = MY_ScreenShot.GetConfig("szFilePath")
    if szFolderPath~="" and not (string.sub(szFolderPath,2,2)==":" and IsFileExist(szFolderPath)) then
        MY.Sysmsg({_L("Shotscreen destination folder error: %s not exist. File has been save to default folder.", szFolderPath)})
        szFolderPath = ""
    end
    local szFilePath
    if szFolderPath~="" then
        -- 生成文件完整路径名称
        local tDateTime = TimeToDate(GetCurrentTime())
        local i = 0
        repeat
            szFilePath = szFolderPath .. (string.format("%04d-%02d-%02d_%02d-%02d-%02d-%03d", tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) .."." .. MY_ScreenShot.GetConfig("szFileExName")
            i=i+1
        until not IsFileExist(szFilePath)
    else
        szFilePath = MY_ScreenShot.GetConfig("szFileExName")
    end
    -- 根据nShowUI不同方式实现截图
    local bStationVisible = Station.IsVisible()
    if nShowUI == MY_ScreenShot.Const.HIDE_UI and bStationVisible then
        Station.Hide()
        MY.DelayCall(100, function()
            _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'))
            MY.DelayCall(300, function()
                Station.Show()
            end)
        end)
    elseif nShowUI == MY_ScreenShot.Const.SHOW_UI and not bStationVisible then
        Station.Show()
        MY.DelayCall(100, function()
            _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'))
            MY.DelayCall(300, function()
                Station.Hide()
            end)
        end)
    else
        _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'))
    end
end
-- 标签栏激活
_MY_ScreenShot.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    local fnRefreshPanel = function(ui)
        ui:children("#WndCheckBox_HideUI"):check(MY_ScreenShot.GetConfig('bAutoHideUI'))
        ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName"))
        ui:children("#WndSliderBox_Quality"):value(MY_ScreenShot.GetConfig("nQuality"))
        ui:children("#WndEditBox_SsRoot"):text(MY_ScreenShot.GetConfig("szFilePath"))
    end
    
    ui:append("WndCheckBox", "WndCheckBox_UseGlobal"):children("#WndCheckBox_UseGlobal"):pos(30,30):width(200)
      :text(_L["use global config"]):tip(_L['Check to use global config, otherwise use private setting.'])
      :check(function(bChecked) MY_ScreenShot.bUseGlobalConfig = bChecked fnRefreshPanel(ui) end)
      :check(MY_ScreenShot.bUseGlobalConfig)
    
    ui:append("WndCheckBox", "WndCheckBox_HideUI"):children("#WndCheckBox_HideUI"):pos(30,70)
      :text(_L['auto hide ui while shot screen']):tip(_L['Check it if you want to hide ui automatic.'])
      :check(function(bChecked) MY_ScreenShot.SetConfig("bAutoHideUI", bChecked) end)
      :check(MY_ScreenShot.GetConfig("bAutoHideUI"))
      
    ui:append("Text", "Text_FileExName"):find("#Text_FileExName"):text(_L['file format']):pos(30,110)
    ui:append("WndComboBox", "WndCombo_FileExName"):children('#WndCombo_FileExName'):pos(110,110):width(80)
      :menu(function()
        return {
            {szOption = "jpg", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="jpg", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "jpg") ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName")) end, fnAutoClose = function() return true end},
            {szOption = "png", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="png", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "png") ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName")) end, fnAutoClose = function() return true end},
            {szOption = "bmp", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="bmp", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "bmp") ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName")) end, fnAutoClose = function() return true end},
            {szOption = "tga", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="tga", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "tga") ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName")) end, fnAutoClose = function() return true end},
        }
      end)
      :text(MY_ScreenShot.GetConfig("szFileExName"))
    
    ui:append("Text", "Text_Quality"):find("#Text_Quality"):text(_L['set quality (0-100)']):pos(30,150)
    ui:append("WndSliderBox", "WndSliderBox_Quality"):children("#WndSliderBox_Quality"):pos(180,150)
      :sliderStyle(false):range(0, 100)
      :tip(_L['Set screenshot quality(0-100): the larger number, the image will use more hdd space.'])
      :change(function(raw, nValue) MY_ScreenShot.SetConfig('nQuality', nValue) end)
    
    ui:append("Text", "Text_SsRoot"):find("#Text_SsRoot"):text(_L['set folder']):pos(30,190)
    ui:append("WndEditBox", "WndEditBox_SsRoot"):children("#WndEditBox_SsRoot"):pos(30,220):size(620,100)
      :text(MY_ScreenShot.GetConfig("szFilePath"))
      :change(function(raw, szValue)
        szValue = string.gsub(szValue, "^%s*(.-)%s*$", "%1")
        szValue = string.gsub(szValue, "\\", "/")
        szValue = string.gsub(szValue, "^(.-)/*$", "%1")
        szValue = szValue..((#szValue>0 and '/') or '')
        MY_ScreenShot.SetConfig("szFilePath", szValue)
      end)
      :tip(_L['Set destination folder which screenshot file will be saved. Absolute path required.\nEx: D:/JX3_ScreenShot/\nAttention: let it blank will save screenshot to default folder.'],MY.Const.UI.Tip.POS_TOP)
    
    ui:append("WndButton", "WndButton_HotkeyCheck"):children("#WndButton_HotkeyCheck"):pos(w-180, 30):width(170)
      :text(_L["set default screenshot tool"])
      :click(function() MY.Game.SetHotKey("MY_ScreenShot_Hotkey",1,44,false,false,false) end)
    
    ui:append("Text", "Text_SetHotkey"):find("#Text_SetHotkey"):pos(w-140, 60):color(255,255,0)
      :text(_L['>> set hotkey <<'])
      :click(function() MY.Game.SetHotKey() end)
    
    fnRefreshPanel(ui)
    
    -- 注册默认工具检查
    MY.BreatheCall("MY_ScreenShot_Hotkey_Check", 1000, function()
        local nKey, nShift, nCtrl, nAlt = MY.Game.GetHotKey("MY_ScreenShot_Hotkey")
        if type(nKey)=="nil" or nKey==0 then
            ui:children("#WndButton_HotkeyCheck"):text(_L["set default screenshot tool"]):enable(true)
        else
            ui:children("#WndButton_HotkeyCheck"):text(_L["as default already"]):enable(false)
        end
    end)
end
_MY_ScreenShot.OnPanelDeactive = function( ... )
    MY.BreatheCall("MY_ScreenShot_Hotkey_Check", false)
end
-- 快捷键绑定
-----------------------------------------------
MY.Game.AddHotKey("MY_ScreenShot_Hotkey", _L["shotscreen"], function() MY_ScreenShot.ShotScreen((MY_ScreenShot.GetConfig('bAutoHideUI') and MY_ScreenShot.Const.HIDE_UI) or nil) end, nil)
MY.Game.AddHotKey("MY_ScreenShot_Hotkey_HideUI", _L["shotscreen without ui"], function() MY_ScreenShot.ShotScreen(MY_ScreenShot.Const.HIDE_UI) end, nil)
MY.Game.AddHotKey("MY_ScreenShot_Hotkey_ShowUI", _L["shotscreen with ui"], function() MY_ScreenShot.ShotScreen(MY_ScreenShot.Const.SHOW_UI) end, nil)
MY.RegisterPanel( "ScreenShot", _L["screenshot helper"], _L['System'], "UI/Image/UICommon/Commonpanel.UITex|9", {255,127,0,200}, { OnPanelActive = _MY_ScreenShot.OnPanelActive, OnPanelDeactive = _MY_ScreenShot.OnPanelDeactive } )
