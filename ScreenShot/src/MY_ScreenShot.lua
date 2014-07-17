----------------------------------------------------
-- 茗伊截图助手 ver 0.2 Build 20140717
-- Code by: 翟一鸣tinymins @ ZhaiYiMing.CoM
-- 电五·双梦镇·茗伊
---------------------------------------------------
local _GLOBAL_CONFIG_ = MY.GetAddonInfo().szRoot.."MY_ScreenShot/data/Global.dat"
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."ScreenShot/lang/")
local _MY_ScreenShot = {}
MY_ScreenShot = MY_ScreenShot or {}
MY_ScreenShot.globalConfig = {
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "./ScreenShot/",
}
MY_ScreenShot.globalConfig = LoadLUAData(_GLOBAL_CONFIG_) or MY_ScreenShot.globalConfig
MY_ScreenShot.bUseGlobalConfig = true
MY_ScreenShot.privateConfig = {
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "./ScreenShot/",
}
RegisterCustomData("MY_ScreenShot.bUseGlobalConfig")
for k, _ in pairs(MY_ScreenShot.privateConfig) do
    RegisterCustomData("MY_ScreenShot.privateConfig." .. k)
end
-- 取设置
MY_ScreenShot.SetConfig = function(szKey, oValue)
    if MY_ScreenShot.bUseGlobalConfig then
        MY_ScreenShot.globalConfig[szKey] = oValue
        SaveLUAData(_GLOBAL_CONFIG_)
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

MY_ScreenShot.ShotScreen = function(nShowUI, nQuality, bFullPath)
    if nQuality==nil then
        local szFilePath, nQuality ,bFullPath, szFolderPath, bStationVisible, _SettingData
        _SettingData = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal) or _ScreenShotHelperData
        local tDateTime = TimeToDate(GetCurrentTime())
        local i=0
        szFolderPath = _SettingData.szFilePath
        if not IsFileExist(szFolderPath) then
            szFolderPath = _ScreenShotHelperDataDefault.szFilePath
            OutputMessage("MSG_SYS", "截图文件夹设置错误：".._SettingData.szFilePath.."目录不存在。已保存截图到默认位置。\n")
        end
        repeat
            szFilePath = szFolderPath .. (string.format("%04d-%02d-%02d_%02d-%02d-%02d-%03d", tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) .."." .. _SettingData.szFileExName
            i=i+1
        until not IsFileExist(szFilePath)
        nQuality = _SettingData.nQuality
        bFullPath = true -- bFullPath = (string.sub(szFilePath,2,2) == ":")
        bStationVisible = Station.IsVisible()
        if nShowUI == 0 then
            if bStationVisible then Station.Hide() end
            MY.DelayCall(function()
                MY_ScreenShot.ShotScreen(szFilePath, nQuality, bFullPath)
                if bStationVisible then Station.Show() end
            end,100)
        elseif nShowUI == 1 then
            if not bStationVisible then Station.Show() end
            MY.DelayCall(function()
                MY_ScreenShot.ShotScreen(szFilePath, nQuality, bFullPath)
                if not bStationVisible then Station.Hide() end
            end,100)
        else
            if bStationVisible and _SettingData.bAutoHideUI then Station.Hide() end
            MY.DelayCall(function()
                MY_ScreenShot.ShotScreen(szFilePath, nQuality, bFullPath)
                if bStationVisible and _SettingData.bAutoHideUI then Station.Show() end
            end,100)
        end
    else
        local szFullPath = ScreenShot(nShowUI, nQuality, bFullPath)
        OutputMessage("MSG_SYS", "[茗伊插件]截图成功，文件已保存："..szFullPath.."\n")
    end
end
-- 注册INIT事件
MY.RegisterInit(function()
    MY.BreatheCall("Tms_ScreenShot_Hotkey_Check", function() local nKey, nShift, nCtrl, nAlt = Hotkey.Get("Tms_ScreenShot_Hotkey") if nKey==0 then Hotkey.Set("Tms_ScreenShot_Hotkey",1,44,false,false,false) end end, 10000)
    
end)
-- 标签栏激活
_MY_ScreenShot.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local fnRefreshPanel = function(ui)
        ui:children("#WndCheckBox_HideUI"):check(MY_ScreenShot.GetConfig('bAutoHideUI'))
        ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName"))
        ui:children("#WndTrackBar_Quality"):value(MY_ScreenShot.GetConfig("nQuality"))
        
    end
    
    ui:append("WndCheckBox_UseGlobal", "WndCheckBox"):children("#WndCheckBox_UseGlobal"):pos(10,10)
      :text(_L["使用所有账号全局设定"]):tip(_L['勾选该项则该角色使用公共设定，取消勾选则该角色使用单独设定。'])
      :check(function() MY_ScreenShot.bUseGlobalConfig = not MY_ScreenShot.bUseGlobalConfig end)
      :check(MY_ScreenShot.bUseGlobalConfig)
    
    ui:append("WndCheckBox_HideUI", "WndCheckBox"):children("#WndCheckBox_HideUI"):pos(10,40)
      :text(_L['截图时隐藏UI']):tip(_L['勾选该项则截图时自动隐藏UI。'])
      :check(function(bChecked) MY_ScreenShot.SetConfig("bAutoHideUI", bChecked) end)
      
    ui:append("Text_FileExName", "Text"):find("#Text_FileExName"):text(_L['截图格式']):pos(10,70)
    ui:append('WndCombo_FileExName','WndComboBox'):children('#WndCombo_FileExName')
      :text(MY_ScreenShot.GetConfig("szFileExName")):pos(80,70):width(80)
      :menu(function()
        local t = {
            {szOption = "jpg", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="jpg", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "jpg") end, fnAutoClose = function() return true end},
            {szOption = "png", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="png", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "png") end, fnAutoClose = function() return true end},
            {szOption = "bmp", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="bmp", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "bmp") end, fnAutoClose = function() return true end},
            {szOption = "tga", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="tga", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "tga") end, fnAutoClose = function() return true end},
        }
        return t
      end)
    
    ui:append("Text_Quality", "Text"):find("#Text_Quality"):text(_L['设置截图精度(0-100)']):pos(10,100)
    ui:append("WndSliderBox_Quality", "WndSliderBox"):children("#WndSliderBox_Quality"):pos(10,130)
      :sliderStyle(false):range(0, 100)
      :tip(_L['设置截图精度(0-100)：越大越清晰 图片也会越占空间。'])
      :change(function(nValue) MY_ScreenShot.SetConfig('nQuality', nValue) Output(nValue) end)
    
    ui:append("Text_SsRoot", "Text"):find("#Text_SsRoot"):text(_L['图片文件夹：']):pos(10,170)
    ui:append("WndEditBox_SsRoot", "WndEditBox"):children("#WndEditBox_SsRoot"):pos(110,170):size(400,20)
      :text(MY_ScreenShot.GetConfig("szFilePath"))
      :change(function(szValue)
        szValue = string.gsub(szValue, "^%s*(.-)%s*$", "%1")
        szValue = string.gsub(szValue, "^(.-)[\/]*$", "%1")..'/'
        MY_ScreenShot.SetConfig("szFilePath", szValue)
      end)
      :tip(_L['设置截图文件夹，截图文件将保存到设置的目录中，支持绝对路径和相对路径，相对路径基于/bin/zhcn/。\n注：为空则恢复默认文件夹'],MY.Const.UI.Tip.POS_TOP)
    
end
-- 快捷键绑定
-----------------------------------------------
MY.Game.AddHotKey("MY_ScreenShot_Hotkey", "截图并保存", function() MY_ScreenShot.ShotScreen(-1) end, nil)
MY.Game.AddHotKey("MY_ScreenShot_Hotkey_HideUI", "隐藏UI截图并保存", function() MY_ScreenShot.ShotScreen(0) end, nil)
MY.Game.AddHotKey("MY_ScreenShot_Hotkey_ShowUI", "显示UI截图并保存", function() MY_ScreenShot.ShotScreen(1) end, nil)
MY.RegisterPanel( "ScreenShot", _L["screenshot helper"], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, { OnPanelActive = _MY_ScreenShot.OnPanelActive, OnPanelDeactive = nil } )
