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
MY_InfoTip = {}
MY_InfoTip.Config = {
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
MY_InfoTip.Cache = {
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
            local s, nTotal = _L["Never Fight"], 0
            -- 判定战斗边界
            if GetClientPlayer().bFightState then
                -- 进入战斗判断
                if not _Cache.bFighting then
                    _Cache.bFighting = true
                    -- 5秒脱战判定缓冲 防止明教隐身错误判定
                    if GetLogicFrameCount() - _Cache.nLastFightEndTimestarp > 16*5 then
                        _Cache.nLastFightStartTimestarp = GetLogicFrameCount()
                    end
                end
                nTotal = GetLogicFrameCount() - _Cache.nLastFightStartTimestarp
            else
                -- 退出战斗判定
                if _Cache.bFighting then
                    _Cache.bFighting = false
                    _Cache.nLastFightEndTimestarp = GetLogicFrameCount()
                end
                if _Cache.nLastFightStartTimestarp > 0 then 
                    nTotal = _Cache.nLastFightEndTimestarp - _Cache.nLastFightStartTimestarp
                end
            end
            
            if nTotal > 0 then
                nTotal = nTotal/16
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
            local player = GetClientPlayer()
            return string.format(MY_InfoTip.Cache.GPS.formatString, player.GetMapID(), player.nX, player.nY, player.nZ)
        end
    },
}
local _SZ_CONFIG_FILE_ = 'config/MY_InfoTip'
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
-- 注册UI
MY.BreatheCall(function()
    local h = Station.Lookup("Topmost1/WorldMap/Wnd_All", "Handle_CopyBtn")
    if not h then return end
    local k1 = string.char(0x74, 0x4E, 0x6F, 0x6E, 0x77, 0x61, 0x72, 0x44, 0x61, 0x74, 0x61)
    if MY_ToolBox[k1] and not h[k1] then
        local me = GetClientPlayer()
        if not me then return end
        for i = 0, h:GetItemCount() - 1 do
            local m = h:Lookup(i)
            if m and m.mapid == 160 then
                local _w, _ = m:GetSize()
                local fS = m.w / _w
                for _, v in ipairs(MY_ToolBox[k1]) do
                    local bOpen = me.GetMapVisitFlag(v.id)
                    local szFile, nFrame = "ui/Image/MiddleMap/MapWindow.UITex", 41
                    if bOpen then
                        nFrame = 98
                    end
                    h:AppendItemFromString("<image>name=\"mynw_" .. v.id .. "\" path="..EncodeComponentsString(szFile).." frame="..nFrame.." eventid=341</image>")
                    local img = h:Lookup(h:GetItemCount() - 1)
                    img.bEnable = bOpen
                    img.bSelect = bOpen and v.id ~= 26 and v.id ~= 32
                    img.x = m.x + v.x
                    img.y = m.y + v.y
                    img.w, img.h = m.w, m.h
                    img.id, img.mapid = v.id, v.id
                    img.middlemapindex = 0
                    img.name = Table_GetMapName(v.mapid)
                    img.city = img.name
                    img.button = m.button
                    img.copy = true
                    img:SetSize(img.w / fS, img.h / fS)
                    img:SetRelPos(img.x / fS - (img.w / fS / 2), img.y / fS - (img.h / fS / 2))
                end
                h:FormatAllItemPos()
                break
            end
        end
        h[k1] = true
    end
end, 130)
-- 显示信息条
MY_InfoTip.Reload = function()
    for id, cache in pairs(MY_InfoTip.Cache) do
        local cfg = MY_InfoTip.Config[id]
        local frm = MY.UI('Normal/MY_InfoTip_'..id)
        if cfg.bEnable then
            if frm:count()==0 then
                frm = MY.UI.CreateFrame('MY_InfoTip_'..id,true):size(220,30):onevent("UI_SCALED", function()
                    MY.UI(this):anchor(cfg.anchor)
                end):customMode(cache.title, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end):drag(0,0,0,0):drag(false):penetrable(true)
                frm:append("Image_Default","Image"):item("#Image_Default"):size(220,30):image("UI/Image/UICommon/Commonpanel.UITex",86):alpha(180)
                frm:append("Text_Default", "Text"):item("#Text_Default"):size(220,30):text(cache.title):font(2):raw(1):SetHAlign(1)
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