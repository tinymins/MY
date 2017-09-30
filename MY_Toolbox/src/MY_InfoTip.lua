------------------------------------------
-- 信息条显示
------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Toolbox/lang/")
local _Cache = {
    bFighting = false,
    nLastFightStartTimestarp = 0,
    nLastFightEndTimestarp = 0,
}
local Config_Default = {
    Ping        = { -- 网络延迟
    	bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 95, 255, 95 },
    	anchor = { x = -180, y = -210, s = "BOTTOMCENTER", r = "BOTTOMCENTER" }, nFont = 48,
    },
    TimeMachine = { -- 倍速显示（显示服务器有多卡……）
        bEnable = false, bShowBg = false, bShowTitle = true, rgb = { 31, 255, 31 },
        anchor  = { x = -272, y = -211, s = "BOTTOMCENTER", r = "BOTTOMCENTER" },
    },
    FPS         = { -- FPS
        bEnable = false, bShowBg = true, bShowTitle = true,
    	anchor  = { x = -10, y = -220, s = "BOTTOMRIGHT", r = "BOTTOMRIGHT" },
    },
    Distance    = { -- 目标距离
        bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 255, 255, 0 },
        anchor  = { x = 203, y = -106, s = "CENTER", r = "CENTER" }, nFont = 209,
    },
    SysTime     = { -- 系统时间
        bEnable = false, bShowBg = true, bShowTitle = true,
    	anchor  = { x = 285, y = -18, s = "BOTTOMLEFT", r = "BOTTOMLEFT" },
    },
    FightTime   = { -- 战斗计时
        bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 255, 0, 128 },
        anchor  = { x = 340, y = -214, s = "BOTTOMCENTER", r = "BOTTOMCENTER" }, nFont = 199,
    },
    LotusTime   = { -- 桂花和藕倒计时
        bEnable = false, bShowBg = true, bShowTitle = true,
    	anchor  = { x = -290, y = -38, s = "BOTTOMRIGHT", r = "BOTTOMRIGHT" },
    },
    GPS         = { -- 角色坐标
        bEnable = false, bShowBg = true, bShowTitle = false, rgb = { 255, 255, 255 },
        anchor  = { x = -21, y = 250, s = "TOPRIGHT", r = "TOPRIGHT" }, nFont = 0,
    },
    Speedometer = { -- 角色速度
        bEnable = false, bShowBg = false, bShowTitle = false, rgb = { 255, 255, 255 },
        anchor  = { x = -10, y = 210, s = "TOPRIGHT", r = "TOPRIGHT" }, nFont = 0,
    },
}
local _C = {}
MY_InfoTip = {}
MY_InfoTip.Config = clone(Config_Default)
_C.tTm = {}
_C.nTmFrameCount = GetLogicFrameCount()
_C.tSm = {}
_C.nSmFrameCount = GetLogicFrameCount()
MY_InfoTip.Cache = {
    Ping         = { -- Ping
        formatString = '', title = _L['ping monitor'], prefix = _L['Ping: '], content = _L['%d'],
        GetContent = function() return string.format(MY_InfoTip.Cache.Ping.formatString, GetPingValue() / 2) end
    },
    TimeMachine  = { -- 倍速显示
        formatString = '', title = _L['time machine'], prefix = _L['Rate: '], content = 'x%.2f',
        GetContent = function()
            local s = 1
            if _C.nTmFrameCount ~= GetLogicFrameCount() then
                local tm = _C.tTm[GLOBAL.GAME_FPS] or {}
                tm.frame = GetLogicFrameCount()
                tm.tick  = GetTickCount()
                for i = GLOBAL.GAME_FPS, 1, -1 do
                    _C.tTm[i] = _C.tTm[i - 1]
                end
                _C.tTm[1] = tm
                _C.nTmFrameCount = GetLogicFrameCount()
            end
            local tm = _C.tTm[GLOBAL.GAME_FPS]
            if tm then
                s = 1000 * (GetLogicFrameCount() - tm.frame) / GLOBAL.GAME_FPS / (GetTickCount() - tm.tick)
            end
            return string.format(MY_InfoTip.Cache.TimeMachine.formatString, s)
        end
    },
    Distance  = { -- 目标距离
        formatString = '', title = _L['target distance'], prefix = _L['Distance: '], content = _L['%.1f Foot'],
        GetContent = function()
            local p, s = MY.GetObject(MY.GetTarget()), _L["No Target"]
            if p then
                s = string.format(MY_InfoTip.Cache.Distance.formatString, GetCharacterDistance(GetClientPlayer().dwID, p.dwID)/64)
            end
            return s
        end
    },
    SysTime   = { -- 系统时间
        formatString = '', title = _L['system time'], prefix = _L['Time: '], content = _L['%02d:%02d:%02d'],
        GetContent = function()
            local tDateTime = TimeToDate(GetCurrentTime())
            return string.format(MY_InfoTip.Cache.SysTime.formatString, tDateTime.hour, tDateTime.minute, tDateTime.second)
        end
    },
    FightTime = { -- 战斗计时
        formatString = '', title = _L['fight clock'], prefix = _L['Fight Clock: '], content = "",
        GetContent = function()
            if MY.Player.GetFightUUID() or MY.Player.GetLastFightUUID() then
                return MY_InfoTip.Cache.FightTime.formatString .. MY.GetFightTime("H:mm:ss")
            else
                return _L["Never Fight"]
            end
        end
    },
    LotusTime = { -- 莲花和藕倒计时
        formatString = '', title = _L['lotus clock'], prefix = _L['Lotus Clock: '], content = _L['%d:%d:%d'],
        GetContent = function()
            local nTotal = 6*60*60 - GetLogicFrameCount()/16%(6*60*60)
            return string.format(MY_InfoTip.Cache.LotusTime.formatString, math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
        end
    },
    GPS = { -- 角色坐标
        formatString = '', title = _L['GPS'], prefix = _L['Location: '], content = _L['[%d]%d,%d,%d'],
        GetContent = function()
            local player, text = GetClientPlayer(), ''
            if player then
                text = string.format(MY_InfoTip.Cache.GPS.formatString, player.GetMapID(), player.nX, player.nY, player.nZ)
            end
            return text
        end
    },
    Speedometer = { -- 角色速度
        formatString = '', title = _L['speedometer'], prefix = _L['Speed: '], content = _L['%.2f f/s'],
        GetContent = function()
            local s = 0
            local me = GetClientPlayer()
            if me and _C.nSmFrameCount ~= GetLogicFrameCount() then
                local sm = _C.tSm[GLOBAL.GAME_FPS] or {}
                sm.framecount = GetLogicFrameCount()
                sm.x, sm.y, sm.z = me.nX, me.nY, me.nZ
                for i = GLOBAL.GAME_FPS, 1, -1 do
                    _C.tSm[i] = _C.tSm[i - 1]
                end
                _C.tSm[1] = sm
                _C.nSmFrameCount = GetLogicFrameCount()
            end
            local sm = _C.tSm[GLOBAL.GAME_FPS]
            if sm and me then
                s = math.sqrt(math.pow(me.nX - sm.x, 2) + math.pow(me.nY - sm.y, 2) + math.pow((me.nZ - sm.z) / 8, 2)) / 64
                    / (GetLogicFrameCount() - sm.framecount) * GLOBAL.GAME_FPS
            end
            return string.format(MY_InfoTip.Cache.Speedometer.formatString, s)
        end
    },
}
local _SZ_CONFIG_FILE_ = {'config/infotip.jx3dat', MY_DATA_PATH.ROLE}
local _Cache = {}
local SaveConfig = function() MY.SaveLUAData(_SZ_CONFIG_FILE_, MY_InfoTip.Config) end
local LoadConfig = function()
    local szOrgFile = MY.GetLUADataPath('config/MY_INFO_TIP/$uid.$lang.jx3dat')
    local szFilePath = MY.GetLUADataPath(_SZ_CONFIG_FILE_)
    if IsLocalFileExist(szOrgFile) then
        CPath.Move(szOrgFile, szFilePath)
    end
    local config = MY.LoadLUAData(szFilePath)
    if config then
        if not MY_InfoTip.Config then
            MY_InfoTip.Config = {}
        end
        for k, v in pairs(config) do
            MY_InfoTip.Config[k] = config[k] or MY_InfoTip.Config[k]
        end
    end
end
RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT", function()
    for k, v in pairs(Config_Default) do
        MY_InfoTip.Config[k].anchor = v.anchor
    end
    MY_InfoTip.Reload()
end)
-- 显示信息条
MY_InfoTip.Reload = function()
    for id, cache in pairs(MY_InfoTip.Cache) do
        local cfg = MY_InfoTip.Config[id]
        local frm = MY.UI('Normal/MY_InfoTip_'..id)
        if cfg.bEnable then
            if frm:count()==0 then
                frm = MY.UI.CreateFrame('MY_InfoTip_'..id, {empty = true}):size(220,30):event("UI_SCALED", function()
                    MY.UI(this):anchor(cfg.anchor)
                end):customMode(cache.title, function(anchor)
                    MY.UI(this):bringToTop()
                    cfg.anchor = anchor
                    SaveConfig()
                end, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end):drag(0,0,0,0):drag(false):penetrable(true)
                frm:append("Image", "Image_Default"):children("#Image_Default"):size(220,30):image("UI/Image/UICommon/Commonpanel.UITex",86):alpha(180)
                frm:append("Text", "Text_Default"):children("#Text_Default"):size(220,30):text(cache.title):font(2)[1]:SetHAlign(1)
                local txt = frm:find("#Text_Default")
                frm:breathe(function() txt:text(cache.GetContent()) end)
            end
            if cfg.bShowBg then
                frm:find("#Image_Default"):show()
            else
                frm:find("#Image_Default"):hide()
            end
            if cfg.bShowTitle then
                cache.formatString = _L[cache.prefix] .. _L[cache.content]
            else
                cache.formatString = _L[cache.content]
            end
            frm:children("#Text_Default"):font(cfg.nFont or 0):color(cfg.rgb or {255,255,255})
            frm:anchor(cfg.anchor)
        else
            frm:remove()
        end
    end
    SaveConfig()
end
-- 注册INIT事件
MY.RegisterInit("MY_INFOTIP", function()
    LoadConfig()
    MY_InfoTip.Reload()
end)


MY.RegisterPanel( "MY_InfoTip", _L["infotip"], _L['System'], "ui/Image/UICommon/ActivePopularize2.UITex|22", {255,255,0,200}, { OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    local x, y = 50, 20

    ui:append("Text", "Text_InfoTip"):find("#Text_InfoTip")
      :pos(x, y):width(350)
      :text(_L['* infomation tips']):color(255,255,0)
    y = y + 5

    for id, cache in pairs(MY_InfoTip.Cache) do
        x, y = 55, y + 30

        local cfg = MY_InfoTip.Config[id]
        ui:append("WndCheckBox", "WndCheckBox_InfoTip_"..id):children("#WndCheckBox_InfoTip_"..id):pos(x, y):width(250)
          :text(cache.title):check(cfg.bEnable or false)
          :check(function(bChecked)
            cfg.bEnable = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 220
        ui:append("WndCheckBox", "WndCheckBox_InfoTipTitle_"..id):children("#WndCheckBox_InfoTipTitle_"..id):pos(x, y):width(60)
          :text(_L['title']):check(cfg.bShowTitle or false)
          :check(function(bChecked)
            cfg.bShowTitle = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 70
        ui:append("WndCheckBox", "WndCheckBox_InfoTipBg_"..id):children("#WndCheckBox_InfoTipBg_"..id):pos(x, y):width(60)
          :text(_L['background']):check(cfg.bShowBg or false)
          :check(function(bChecked)
            cfg.bShowBg = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 70
        ui:append("WndButton", "WndButton_InfoTipFont_"..id):children("#WndButton_InfoTipFont_"..id):pos(x, y)
          :width(50):text(_L['font'])
          :click(function()
            MY.UI.OpenFontPicker(function(f)
                cfg.nFont = f
                MY_InfoTip.Reload()
            end)
          end)
        x = x + 60
        ui:append("Shadow", "Shadow_InfoTipColor_"..id):children("#Shadow_InfoTipColor_"..id):pos(x, y)
          :size(20, 20):color(cfg.rgb or {255,255,255})
          :click(function()
            local me = this
            MY.UI.OpenColorPicker(function(r, g, b)
                MY.UI(me):color(r, g, b)
                cfg.rgb = { r, g, b }
                MY_InfoTip.Reload()
            end)
          end)
    end
end})
