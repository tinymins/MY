--[[
#######################################################################################################
      #       #                   #                     #                 
      #         #           # # # # # # # # #         # # # # # # #       
    #   # # # # # # # #     #               #       #   #       #         
    #                       # # # # # # # # #             # # #           
  # #     # # # # # #       #               #         # #       # #       
    #                       # # # # # # # # #     # #       #       # #   
    #     # # # # # #       #               #               #             
    #                       # # # # # # # # #       # # # # # # # # #     
    #     # # # # # #               #                       #             
    #     #         #       #   #     #     #         #     #     #       
    #     # # # # # #       #   #         #   #     #       #       #     
    #     #         #     #       # # # # #   #   #       # #         #   
#######################################################################################################
]]
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _Cache = {
    bFighting = false,
    nLastFightStartTimestarp = 0,
    nLastFightEndTimestarp = 0,
}
local _C = {}
MY_InfoTip = {}
MY_InfoTip.Config = {
    TimeMachine = { -- 倍速显示（显示服务器有多卡……）
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-250, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    FPS       = { -- FPS
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-220, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    Distance  = { -- 目标距离
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-190, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    SysTime   = { -- 系统时间
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-160, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    FightTime = { -- 战斗计时
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-130, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    LotusTime = { -- 莲花和藕倒计时
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-100, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    GPS = { -- 角色坐标
        bEnable = false, bShowBg = true, bShowTitle = false,
        anchor  = { x=-10, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
}
_C.tTm = {}
_C.nTmFrameCount = GetLogicFrameCount()
MY_InfoTip.Cache = {
    TimeMachine  = { -- 目标距离
        formatString = '', title = _L['time machine'], prefix = _L['Rate: '], content = 'x%.2f',
        GetContent = function()
            local s = 1
            if _C.nTmFrameCount ~= GetLogicFrameCount() then
                for i = GLOBAL.GAME_FPS, 1, -1 do
                    _C.tTm[i] = _C.tTm[i - 1]
                end
                _C.tTm[1] = { frame = GetLogicFrameCount(), tick = GetTickCount() }
                _C.nTmFrameCount = GetLogicFrameCount()
            end
            if _C.tTm[GLOBAL.GAME_FPS] then
                s = 1000 * (GetLogicFrameCount() - _C.tTm[GLOBAL.GAME_FPS].frame) / GLOBAL.GAME_FPS / (GetTickCount() - _C.tTm[GLOBAL.GAME_FPS].tick)
            end
            return string.format(MY_InfoTip.Cache.TimeMachine.formatString, s)
        end
    },
    FPS       = { -- FPS
        formatString = '', title = _L['fps monitor'], prefix = _L['FPS: '], content = _L['%d'],
        GetContent = function() return string.format(MY_InfoTip.Cache.FPS.formatString, GetFPS()) end
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
        formatString = '', title = _L['fight clock'], prefix = _L['Fight Clock: '], content = _L['%d:%02d:%02d'],
        GetContent = function()
            local s, nTotal = _L["Never Fight"], MY.Player.GetFightTime()
            if MY.Player.GetFightUUID() or MY.Player.GetLastFightUUID() then
                nTotal = nTotal / 16
                s = string.format(MY_InfoTip.Cache.FightTime.formatString, math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
            end
            return s
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
}
local _SZ_CONFIG_FILE_ = 'config/MY_INFO_TIP/'
local _Cache = {}
local SaveConfig = function() MY.Sys.SaveUserData(_SZ_CONFIG_FILE_, MY_InfoTip.Config) end
local LoadConfig = function()
    local config = MY.Sys.LoadUserData(_SZ_CONFIG_FILE_)
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
    MY_InfoTip.Config.FPS.anchor       = { x=-10, y=-220, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    MY_InfoTip.Config.Distance.anchor  = { x=-10, y=-190, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    MY_InfoTip.Config.SysTime.anchor   = { x=-10, y=-160, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    MY_InfoTip.Config.FightTime.anchor = { x=-10, y=-130, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    MY_InfoTip.Config.LotusTime.anchor = { x=-10, y=-100, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    MY_InfoTip.Config.GPS.anchor       = { x=-10, y=-70 , s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    MY_InfoTip.Reload()
end)
-- 显示信息条
MY_InfoTip.Reload = function()
    for id, cache in pairs(MY_InfoTip.Cache) do
        local cfg = MY_InfoTip.Config[id]
        local frm = MY.UI('Normal/MY_InfoTip_'..id)
        if cfg.bEnable then
            if frm:count()==0 then
                frm = MY.UI.CreateFrame('MY_InfoTip_'..id, {empty = true}):size(220,30):onevent("UI_SCALED", function()
                    MY.UI(this):anchor(cfg.anchor)
                end):customMode(cache.title, function(anchor)
                    MY.UI(this):bringToTop()
                    cfg.anchor = anchor
                    SaveConfig()
                end, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end):drag(0,0,0,0):drag(false):penetrable(true)
                frm:append("Image", "Image_Default"):item("#Image_Default"):size(220,30):image("UI/Image/UICommon/Commonpanel.UITex",86):alpha(180)
                frm:append("Text", "Text_Default"):item("#Text_Default"):size(220,30):text(cache.title):font(2):raw(1):SetHAlign(1)
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
            frm:item("#Text_Default"):font(cfg.nFont or 0):color(cfg.rgb or {255,255,255})
            frm:anchor(cfg.anchor)
        else
            frm:remove()
        end
    end
    SaveConfig()
end
-- 注册INIT事件
MY.RegisterInit(function()
    LoadConfig()
    MY_InfoTip.Reload()
end)


MY.RegisterPanel( "MY_InfoTip", _L["infotip"], _L['General'], "ui/Image/UICommon/ActivePopularize2.UITex|22", {255,255,0,200}, { OnPanelActive = function(wnd)
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
        ui:append("Shadow", "Shadow_InfoTipColor_"..id):item("#Shadow_InfoTipColor_"..id):pos(x, y)
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
