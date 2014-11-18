--
-- 其他功能
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140510
--
-- 主要功能: 共站检查 好友头顶
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _MY_ToolBox = {
    bFighting = false,
    nLastFightStartTimestarp = -1,
    nLastFightEndTimestarp = -1,
    tChannels = {
        { nChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS  , szName = _L['system channel']  , rgb = GetMsgFontColor("MSG_SYS"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.TEAM  , szName = _L['team channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.RAID  , szName = _L['raid channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.TONG  , szName = _L['tong channel']  , rgb = GetMsgFontColor("MSG_GUILD" , true) },
    }
}
MY_ToolBox = {}
--[[
#######################################################################################################
            #                         #             #               #                 # # # #     
          #   #             # # # # # # # # # #       #             #     #           #           
        #       #           #                                       #       #   # # # # # # # #   
      #           #         #       #                     # # # # # # #         #     #       #   
  # #               # #     # # # # # # # # # #   # # #             #           #     # # #       
      # # # # # #           #     #                   #     #       #     #     # # # #       #   
      #         #           #   #     #               #       #     #       #   #       # # # #   
      #         #           #   # # # # # # #         #       #     #           #     #           
      #         #           #         #               #             #           #       #         
      #     # #     #       # # # # # # # # # #       #         # # #       #   #   #       #     
      #             #       #         #             #   #                 #     # #   #   #   #   
        # # # # # # #     #           #           #       # # # # # # #       #       # # #       
#######################################################################################################
]]
MY_ToolBox.bBagSearch = true
RegisterCustomData("MY_ToolBox.bBagSearch")
_MY_ToolBox.OnBreathe = function()
    -- bag
    local chks = {
        Station.Lookup("Normal/BigBagPanel/CheckBox_Totle"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Task"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Equipment"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Drug"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Material"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Book"),
        Station.Lookup("Normal/BigBagPanel/CheckBox_Grey"),
    }
    local chkLtd = Station.Lookup("Normal/BigBagPanel/CheckBox_TimeLtd")
    local iptKwd = Station.Lookup("Normal/BigBagPanel/WndEditBox_KeyWord")
    if not MY_ToolBox.bBagSearch then
        if chkLtd then
            chkLtd:Destroy()
            iptKwd:Destroy()
        end
    elseif chks[7] then
        if not chkLtd then
            local nX, nY = chks[7]:GetRelPos()
            local w, h = chks[7]:GetSize()
            for _, chk in ipairs(chks) do
                chk.OnCheckBoxUncheck = function() _MY_ToolBox.bBagTimeLtd = false end
            end
            chkLtd = MY.UI("Normal/BigBagPanel")
              :append("CheckBox_TimeLtd", "WndRadioBox"):children("#CheckBox_TimeLtd")
              :text(_L['Time Limited']):size(w,h):pos(nX + chks[7]:Lookup("",""):GetSize(), nY)
              :check(function(bChecked)
                if bChecked then
                    for _, chk in ipairs(chks) do
                        chk:Check(false)
                    end
                    MY.UI(this):check(false)
                end
                _MY_ToolBox.bBagTimeLtd = bChecked
                _MY_ToolBox.DoFilterBag()
              end):raw(1)
            MY.UI(chkLtd):item("#Text_Default"):left(20)
        end
        if not iptKwd then
            iptKwd = MY.UI("Normal/BigBagPanel")
              :append("WndEditBox_KeyWord", "WndEditBox"):children("#WndEditBox_KeyWord")
              :text(_MY_ToolBox.szBagFilter or ""):size(100,21):pos(60, 30):placeholder(_L['Search'])
              :change(function(txt)
                _MY_ToolBox.szBagFilter = txt
                _MY_ToolBox.DoFilterBag()
              end):raw(1)
        end
    end
    -- bank
    local frmBank = Station.Lookup("Normal/BigBankPanel")
    local chkLtd = Station.Lookup("Normal/BigBankPanel/CheckBox_TimeLtd")
    local iptKwd = Station.Lookup("Normal/BigBankPanel/WndEditBox_KeyWord")
    if not MY_ToolBox.bBagSearch then
        if chkLtd then
            chkLtd:Destroy()
            iptKwd:Destroy()
        end
    elseif frmBank then
        if not chkLtd then
            chkLtd = MY.UI("Normal/BigBankPanel")
              :append("CheckBox_TimeLtd", "WndCheckBox"):children("#CheckBox_TimeLtd")
              :text(_L['Time Limited']):pos(277, 56):check(_MY_ToolBox.bBankTimeLtd or false)
              :check(function(bChecked)
                _MY_ToolBox.bBankTimeLtd = bChecked
                _MY_ToolBox.DoFilterBank()
              end):alpha(200):raw(1)
            _MY_ToolBox.DoFilterBank()
        end
        if not iptKwd then
            iptKwd = MY.UI("Normal/BigBankPanel")
              :append("WndEditBox_KeyWord", "WndEditBox"):children("#WndEditBox_KeyWord")
              :text(_MY_ToolBox.szBankFilter or ""):size(100,21):pos(280, 80):placeholder(_L['Search'])
              :change(function(txt)
                _MY_ToolBox.szBankFilter = txt
                _MY_ToolBox.DoFilterBank()
              end):raw(1)
            _MY_ToolBox.DoFilterBank()
        end
    end
    -- guild bank
    local frmBank = Station.Lookup("Normal/GuildBankPanel")
    local iptKwd = Station.Lookup("Normal/GuildBankPanel/WndEditBox_KeyWord")
    if not MY_ToolBox.bBagSearch then
        if iptKwd then
            iptKwd:Destroy()
        end
    elseif frmBank then
        if not iptKwd then
            iptKwd = MY.UI("Normal/GuildBankPanel")
              :append("WndEditBox_KeyWord", "WndEditBox"):children("#WndEditBox_KeyWord")
              :text(_MY_ToolBox.szGuildBankFilter or ""):size(100,21):pos(60, 25):placeholder(_L['Search'])
              :change(function(txt)
                _MY_ToolBox.szGuildBankFilter = txt
                _MY_ToolBox.DoFilterGuildBank()
              end):raw(1)
            _MY_ToolBox.DoFilterGuildBank()
        end
    end
end
-- 过滤背包
_MY_ToolBox.DoFilterBag = function()
    -- 优化性能 当过滤器为空时不遍历筛选
    if _MY_ToolBox.szBagFilter or _MY_ToolBox.bBagTimeLtd then
        _MY_ToolBox.FilterPackage("Normal/BigBagPanel/", _MY_ToolBox.szBagFilter, _MY_ToolBox.bBagTimeLtd)
        if _MY_ToolBox.szBagFilter == "" then
            _MY_ToolBox.szBagFilter = nil
        end
    end
end
-- 过滤仓库
_MY_ToolBox.DoFilterBank = function()
    -- 优化性能 当过滤器为空时不遍历筛选
    if _MY_ToolBox.szBankFilter or _MY_ToolBox.bBankTimeLtd then
        _MY_ToolBox.FilterPackage("Normal/BigBankPanel/", _MY_ToolBox.szBankFilter, _MY_ToolBox.bBankTimeLtd)
        if _MY_ToolBox.szBankFilter == "" then
            _MY_ToolBox.szBankFilter = nil
        end
    end
end
-- 过滤帮会仓库
_MY_ToolBox.DoFilterGuildBank = function()
    -- 优化性能 当过滤器为空时不遍历筛选
    if _MY_ToolBox.szGuildBankFilter then
        _MY_ToolBox.FilterGuildPackage("Normal/GuildBankPanel/", _MY_ToolBox.szGuildBankFilter)
        if _MY_ToolBox.szGuildBankFilter == "" then
            _MY_ToolBox.szGuildBankFilter = nil
        end
    end
end
-- 过滤背包原始函数
_MY_ToolBox.FilterPackage = function(szTreePath, szFilter, bTimeLtd)
    szFilter = szFilter or ""
    local me = GetClientPlayer()
    MY.UI(szTreePath):find(".Box"):each(function(ui)
        if this.bBag then return end
        local dwBox, dwX, bMatch = this.dwBox, this.dwX, true
        local item = me.GetItem(dwBox, dwX)
        if not item then return end
        if not string.find(item.szName, szFilter) then
            bMatch = false
        end
        if bTimeLtd and item:GetLeftExistTime() == 0 then
            bMatch = false
        end
        if bMatch then
            this:SetAlpha(255)
        else
            this:SetAlpha(50)
        end
    end)
end
-- 过滤帮会仓库原始函数
_MY_ToolBox.FilterGuildPackage = function(szTreePath, szFilter)
    szFilter = szFilter or ""
    local me = GetClientPlayer()
    MY.UI(szTreePath):find(".Box"):each(function(ui)
        local uIID, _, nPage, dwIndex = this:GetObjectData()
        if uIID < 0 then return end
        if not string.find(GetItemNameByUIID(uIID), szFilter) then
            this:SetAlpha(50)
        else
            this:SetAlpha(255)
        end
    end)
end
-- 事件注册
MY.RegisterEvent("BAG_ITEM_UPDATE", _MY_ToolBox.DoFilterBag)
MY.RegisterEvent("BAG_ITEM_UPDATE", _MY_ToolBox.DoFilterBank)
MY.RegisterEvent("BAG_ITEM_UPDATE", _MY_ToolBox.DoFilterGuildBank)
MY.RegisterInit(function() MY.BreatheCall(_MY_ToolBox.OnBreathe, 130) end)
--[[
#######################################################################################################
      #                           #                         #                       #             
      #     # # # # #             #               # # # # # # # # # # #   # # # # # # # # # # #   
      #             #     # # # # # # # # # # #                                                   
  # # # # #       #             #                     # # # # # # #           # # # # # # #       
    #     #     #               #                     #           #           #           #       
    #     #     #               # # # # # #           # # # # # # #           # # # # # # #       
    #     # # # # # # #       #   #       #                                                       
  #     #       #             #   #       #       # # # # # # # # # # #   # # # # # # # # # # #   
    #   #       #           #       #   #         #                   #   #                   #   
      #         #           #         #           #     # # # # #     #       # # # # # #         
    #   #       #         #       # #   # #       #     #       #     #       #         #     #   
  #       #   # #             # #           # #   #     # # # # #   # #   # #             # # #  
#######################################################################################################
]]
MY_ToolBox.bFriendHeadTip = false
RegisterCustomData("MY_ToolBox.bFriendHeadTip")
_MY_ToolBox.FriendHeadTip = function(bEnable)
    if bEnable then
        local frm = MY.UI.CreateFrame("MY_Shadow",true,true):show()
        local fnPlayerEnter = function(dwID)
            local p = MY.Player.GetFriend(dwID)
            if p then
                local shadow = frm:append("MY_FRIEND_TIP"..dwID,"Shadow"):find("#MY_FRIEND_TIP"..dwID):raw(1)
                if shadow then
                    local r,g,b,a = 255,255,255,255
                    local szTip = ">> "..p.name.." <<"
                    shadow:ClearTriangleFanPoint()
                    shadow:SetTriangleFan(GEOMETRY_TYPE.TEXT)
                    shadow:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
                    --shadow:AppendCharacterID(dwCharacterID, bCharacterTop, r, g, b, a [[,fTopDelta, dwFontSchemeID, szText, fSpace, fScale]])
                    shadow:Show()
                end
            end
        end
        MY.RegisterEvent("PLAYER_ENTER_SCENE","MY_FRIEND_TIP",fnPlayerEnter)
        MY.RegisterEvent("PLAYER_LEAVE_SCENE","MY_FRIEND_TIP",function(arg0)
            frm:find("#MY_FRIEND_TIP"..arg0):remove()
        end)
        for _, p in pairs(MY.Player.GetNearPlayer()) do
            fnPlayerEnter(p.dwID)
        end
    else
        MY.RegisterEvent("PLAYER_ENTER_SCENE","MY_FRIEND_TIP")
        MY.RegisterEvent("PLAYER_LEAVE_SCENE","MY_FRIEND_TIP")
        MY.UI("Lowest/MY_Shadow"):remove()
    end
end
MY.RegisterInit(function() if MY_ToolBox.bFriendHeadTip then _MY_ToolBox.FriendHeadTip(true) end end)
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
local _SZ_CONFIG_FILE_ = 'config/MY_ToolBox'
local Config = Config or {}
local _Cache = _Cache or {}
local SaveConfig = function() MY.Sys.SaveUserData(_SZ_CONFIG_FILE_, Config) end
local LoadConfig = function() Config = MY.Sys.LoadUserData(_SZ_CONFIG_FILE_) or Config end
Config.InfoTip = {
    FPS       = { -- FPS
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-190, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    Distance  = { -- 目标距离
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-160, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    SysTime   = { -- 系统时间
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-130, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    FightTime = { -- 战斗计时
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-100, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
    LotusTime = { -- 莲花和藕倒计时
        bEnable = false, bShowBg = true, bShowTitle = true,
        anchor  = { x=-10, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    },
}
RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT", function()
    Config.InfoTip.FPS.anchor       = { x=-10, y=-190, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    Config.InfoTip.Distance.anchor  = { x=-10, y=-160, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    Config.InfoTip.SysTime.anchor   = { x=-10, y=-130, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    Config.InfoTip.FightTime.anchor = { x=-10, y=-100, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    Config.InfoTip.LotusTime.anchor = { x=-10, y=-70 , s="BOTTOMRIGHT", r="BOTTOMRIGHT" }
    _MY_ToolBox.ReloadInfoTip()
end)
_Cache.InfoTip = {
    FPS       = { -- FPS
        formatString = '', title = _L['fps monitor'], prefix = _L['FPS: '], content = _L['%d'],
        GetContent = function() return string.format(_Cache.InfoTip.FPS.formatString, GetFPS()) end
    },
    Distance  = { -- 目标距离
        formatString = '', title = _L['target distance'], prefix = _L['Distance: '], content = _L['%.1f Foot'],
        GetContent = function()
            local p, s = MY.GetObject(MY.GetTarget()), _L["No Target"]
            if p then
                s = string.format(_Cache.InfoTip.Distance.formatString, GetCharacterDistance(GetClientPlayer().dwID, p.dwID)/64)
            end
            return s
        end
    },
    SysTime   = { -- 系统时间
        formatString = '', title = _L['system time'], prefix = _L['Time: '], content = _L['%02d:%02d:%02d'],
        GetContent = function()
            local tDateTime = TimeToDate(GetCurrentTime())
            return string.format(_Cache.InfoTip.SysTime.formatString, tDateTime.hour, tDateTime.minute, tDateTime.second)
        end
    },
    FightTime = { -- 战斗计时
        formatString = '', title = _L['fight clock'], prefix = _L['Fight Clock: '], content = _L['%d:%02d:%02d'],
        GetContent = function()
            local s, nTotal = _L["Never Fight"], 0
            -- 判定战斗边界
            if GetClientPlayer().bFightState then
                -- 进入战斗判断
                if not _MY_ToolBox.bFighting then
                    _MY_ToolBox.bFighting = true
                    -- 5秒脱战判定缓冲 防止明教隐身错误判定
                    if GetLogicFrameCount() - _MY_ToolBox.nLastFightEndTimestarp > 16*5 then
                        _MY_ToolBox.nLastFightStartTimestarp = GetLogicFrameCount()
                    end
                end
                nTotal = GetLogicFrameCount() - _MY_ToolBox.nLastFightStartTimestarp
            else
                -- 退出战斗判定
                if _MY_ToolBox.bFighting then
                    _MY_ToolBox.bFighting = false
                    _MY_ToolBox.nLastFightEndTimestarp = GetLogicFrameCount()
                end
                if _MY_ToolBox.nLastFightStartTimestarp > 0 then 
                    nTotal = _MY_ToolBox.nLastFightEndTimestarp - _MY_ToolBox.nLastFightStartTimestarp
                end
            end
            
            if nTotal > 0 then
                nTotal = nTotal/16
                s = string.format(_Cache.InfoTip.FightTime.formatString, math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
            end
            return s
        end
    },
    LotusTime = { -- 莲花和藕倒计时
        formatString = '', title = _L['lotus clock'], prefix = _L['Lotus Clock: '], content = _L['%d:%d:%d'],
        GetContent = function()
            local nTotal = 6*60*60 - GetLogicFrameCount()/16%(6*60*60)
            return string.format(_Cache.InfoTip.LotusTime.formatString, math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
        end
    },
}
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
_MY_ToolBox.ReloadInfoTip = function()
    for id, cache in pairs(_Cache.InfoTip) do
        local cfg = Config.InfoTip[id]
        local frm = MY.UI('Normal/MY_InfoTip_'..id)
        if cfg.bEnable then
            if frm:count()==0 then
                frm = MY.UI.CreateFrame('MY_InfoTip_'..id,true):size(150,30):onevent("UI_SCALED", function()
                    MY.UI(this):anchor(cfg.anchor)
                end):customMode(cache.title, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end, function(anchor)
                    cfg.anchor = anchor
                    SaveConfig()
                end):drag(0,0,0,0):drag(false):penetrable(true)
                frm:append("Image_Default","Image"):item("#Image_Default"):size(150,30):image("UI/Image/UICommon/Commonpanel.UITex",86):alpha(180)
                frm:append("Text_Default", "Text"):item("#Text_Default"):size(150,30):text(cache.title):font(2):raw(1):SetHAlign(1)
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
    _MY_ToolBox.ReloadInfoTip()
end)
--[[
##########################################################################################################################
      *         *   *                   *                                   *                           *     *           
      *         *     *         *       *         * * * * * * * * * * *       *     * * * * *           *     *           
      * * *     *                 *     *                           *     * * * *   *       *         *       *       *   
      *         * * * *             *   *                           *           *   *   *   *         *       *     *     
      *     * * *           *           *           * * * * * *     *         *     *   *   *       * *       *   *       
  * * * * *     *   *         *         *           *         *     *         * *   *   *   *     *   *       * *         
  *       *     *   *           *       *           *         *     *       * *   * *   *   *         *       *           
  *       *     *   *                   * * * *     *         *     *     *   *     *   *   *         *     * *           
  *       *       *       * * * * * * * *           * * * * * *     *         *       *   *           *   *   *           
  * * * * *     * *   *                 *           *               *         *       *   *           *       *       *   
  *           *     * *                 *                           *         *     *     *   *       *       *       *   
            *         *                 *                       * * *         *   *         * *       *         * * * *   
##########################################################################################################################
]]
MY_ToolBox.bVisualSkill = false
MY_ToolBox.anchorVisualSkill = { x=0, y=-220, s="BOTTOMCENTER", r="BOTTOMCENTER" }
MY_ToolBox.nVisualSkillBoxCount = 5
RegisterCustomData("MY_ToolBox.bVisualSkill")
RegisterCustomData("MY_ToolBox.anchorVisualSkill")
RegisterCustomData("MY_ToolBox.nVisualSkillBoxCount")
-- 加载界面
_MY_ToolBox.ReloadVisualSkill = function()
    -- distory ui
    MY.UI("Normal/MY_ToolBox_VisualSkill"):remove()
    -- unbind event
    MY.RegisterEvent("DO_SKILL_CAST", "MY_ToolBox_VisualSkillCast")
    -- create new   
    if MY_ToolBox.bVisualSkill then
        -- create ui
        local ui = MY.UI.CreateFrame("MY_ToolBox_VisualSkill", true)
        ui:size(130 + 53 * MY_ToolBox.nVisualSkillBoxCount - 32 + 80, 52):anchor(MY_ToolBox.anchorVisualSkill)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_ToolBox.anchorVisualSkill)
          end):customMode(_L['visual skill'], function(anchor)
            MY_ToolBox.anchorVisualSkill = anchor
          end, function(anchor)
            MY_ToolBox.anchorVisualSkill = anchor
          end):penetrable(true)
        -- draw background
        local uiL = ui:append("WndWindow_Lowest", "WndWindow"):children("#WndWindow_Lowest"):size(130 + 53 * MY_ToolBox.nVisualSkillBoxCount - 32 + 80, 52)
        uiL:append("Image_Bg_10", "Image"):item("#Image_Bg_10"):pos(0,0):size(130, 52):image("ui/Image/UICommon/Skills.UITex", 28)
        uiL:append("Image_Bg_11", "Image"):item("#Image_Bg_11"):pos(130,0):size( 53 * MY_ToolBox.nVisualSkillBoxCount - 32, 52):image("ui/Image/UICommon/Skills.UITex", 31)
        uiL:append("Image_Bg_12", "Image"):item("#Image_Bg_12"):pos(130 + 53 * MY_ToolBox.nVisualSkillBoxCount - 32, 0):size(80, 52):image("ui/Image/UICommon/Skills.UITex", 29)
        -- create skill boxes
        local uiN = ui:append("WndWindow_Normal", "WndWindow"):children("#WndWindow_Normal"):size(130 + 53 * MY_ToolBox.nVisualSkillBoxCount - 32 + 80, 52)
        local y = 45
        for i= 1, MY_ToolBox.nVisualSkillBoxCount do
            uiN:append("Box_1"..i, "Box"):item("#Box_1"..i):pos(y+i*53,3):alpha(0)
        end
        uiN:append("Box_10", "Box"):item("#Box_10"):pos(y+MY_ToolBox.nVisualSkillBoxCount*53+300,3):alpha(0)
        -- draw front mask
        local uiT = ui:append("WndWindow_Top", "WndWindow"):children("#WndWindow_Top"):size(130 + 53 * MY_ToolBox.nVisualSkillBoxCount - 32 + 80, 52)
        local y = 42
        for i= 1, MY_ToolBox.nVisualSkillBoxCount do
            uiT:append("Image_1"..i, "Image"):item("#Image_1"..i):pos(y+i*53,0):size(55, 53):image("ui/Image/UICommon/Skills.UITex", 15)
        end
        -- init data and bind event
        _MY_ToolBox.nVisualSkillBoxIndex = 0
        MY.RegisterEvent("DO_SKILL_CAST", "MY_ToolBox_VisualSkillCast", function()
            local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
            if dwID == GetClientPlayer().dwID then
                MY_ToolBox.VisualSkillCast(dwSkillID, dwSkillLevel)
            end
        end)
    end
end
RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT", function()
    MY_ToolBox.anchorVisualSkill = { x=0, y=-220, s="BOTTOMCENTER", r="BOTTOMCENTER" }
    MY.UI('Normal/MY_ToolBox_VisualSkill'):anchor(MY_ToolBox.anchorVisualSkill)
end)
MY_ToolBox.VisualSkillCast = function(dwSkillID, dwSkillLevel)
    local ui = MY.UI("Normal/MY_ToolBox_VisualSkill/WndWindow_Normal")
    if ui:count()==0 then
        return
    end
    -- get name
    local szSkillName, dwIconID = MY.Player.GetSkillName(dwSkillID, dwSkillLevel)
    if dwSkillID == 4097 then -- 骑乘
        dwIconID = 1899
    elseif Table_IsSkillFormation(dwSkillID, dwSkillLevel)        -- 阵法技能
        or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)  -- 阵法释放技能
        -- or dwSkillID == 230     -- (230)  万花伤害阵法施放  七绝逍遥阵
        -- or dwSkillID == 347     -- (347)  纯阳气宗阵法施放  九宫八卦阵
        -- or dwSkillID == 526     -- (526)  七秀治疗阵法施放  花月凌风阵
        -- or dwSkillID == 662     -- (662)  天策防御阵法释放  九襄地玄阵
        -- or dwSkillID == 740     -- (740)  少林防御阵法施放  金刚伏魔阵
        -- or dwSkillID == 745     -- (745)  少林攻击阵法施放  天鼓雷音阵
        -- or dwSkillID == 754     -- (754)  天策攻击阵法释放  卫公折冲阵
        -- or dwSkillID == 778     -- (778)  纯阳剑宗阵法施放  北斗七星阵
        -- or dwSkillID == 781     -- (781)  七秀伤害阵法施放  九音惊弦阵
        -- or dwSkillID == 1020    -- (1020) 万花治疗阵法施放  落星惊鸿阵
        -- or dwSkillID == 1866    -- (1866) 藏剑阵法释放      依山观澜阵
        -- or dwSkillID == 2481    -- (2481) 五毒治疗阵法施放  妙手织天阵
        -- or dwSkillID == 2487    -- (2487) 五毒攻击阵法施放  万蛊噬心阵
        -- or dwSkillID == 3216    -- (3216) 唐门外功阵法施放  流星赶月阵
        -- or dwSkillID == 3217    -- (3217) 唐门内功阵法施放  千机百变阵
        -- or dwSkillID == 4674    -- (4674) 明教攻击阵法施放  炎威破魔阵
        -- or dwSkillID == 4687    -- (4687) 明教防御阵法施放  无量光明阵
        -- or dwSkillID == 5311    -- (5311) 丐帮攻击阵法释放  降龙伏虎阵
        -- or dwSkillID == 13228   -- (13228)  临川列山阵释放  临川列山阵
        -- or dwSkillID == 13275   -- (13275)  锋凌横绝阵施放  锋凌横绝阵
        or dwSkillID == 10         -- (10)    横扫千军           横扫千军
        or dwSkillID == 11         -- (11)    普通攻击-棍攻击    六合棍
        or dwSkillID == 12         -- (12)    普通攻击-枪攻击    梅花枪法
        or dwSkillID == 13         -- (13)    普通攻击-剑攻击    三柴剑法
        or dwSkillID == 14         -- (14)    普通攻击-拳套攻击  长拳
        or dwSkillID == 15         -- (15)    普通攻击-双兵攻击  连环双刀
        or dwSkillID == 16         -- (16)    普通攻击-笔攻击    判官笔法
        or dwSkillID == 1795       -- (1795)  普通攻击-重剑攻击  四季剑法
        or dwSkillID == 2183       -- (2183)  普通攻击-虫笛攻击  大荒笛法
        or dwSkillID == 3121       -- (3121)  普通攻击-弓攻击    罡风镖法
        or dwSkillID == 4326       -- (4326)  普通攻击-双刀攻击  大漠刀法
        or dwSkillID == 13039      -- (13039) 普通攻击_盾刀攻击  卷雪刀
        or dwSkillID == 17         -- (17)    江湖-防身武艺-打坐 打坐
        or dwSkillID == 18         -- (18)    踏云 踏云
        or dwIconID  == 1817       -- 闭阵
        or dwIconID  == 533        -- 打坐
        or dwIconID  == 13         -- 子技能
        or not szSkillName
        or szSkillName == ""
    then
        return
    end
    
    local nAnimateFrameCount, nStartFrame = 8, GetLogicFrameCount()
    -- box enter
    local i = _MY_ToolBox.nVisualSkillBoxIndex
    local boxEnter = ui:item("#Box_1"..i)
    boxEnter:raw(1):SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
    boxEnter:raw(1):SetObjectIcon(dwIconID)
    local nEnterDesLeft = MY_ToolBox.nVisualSkillBoxCount*53 + 45
    boxEnter:fadeTo(nAnimateFrameCount * 75, 255)
    MY.BreatheCall(function()
        local nLeft = boxEnter:left()
        local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
        if nSpentFrameCount < nAnimateFrameCount then
            boxEnter:left(nLeft - (nLeft - nEnterDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
        else
            boxEnter:left(nEnterDesLeft)
            return 0
        end
    end, "#Box_1"..i)
    MY.DelayCall(function()
        boxEnter:fadeTo(nAnimateFrameCount * 75, 0)
    end, "#Box_1"..i, 15000)
    
    -- box leave
    i = ( i + 1 ) % (MY_ToolBox.nVisualSkillBoxCount + 1)
    local boxLeave = ui:item("#Box_1"..i)
    boxLeave:raw(1):SetObjectCoolDown(0)
    local nLeaveDesLeft = -200
    boxLeave:fadeTo(nAnimateFrameCount * 75, 0)
    MY.BreatheCall(function()
        local nLeft = boxLeave:left()
        local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
        if nSpentFrameCount < nAnimateFrameCount then
            boxLeave:left(nLeft - (nLeft - nLeaveDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
        else
            boxLeave:left(45+MY_ToolBox.nVisualSkillBoxCount*53+300)
            return 0
        end
    end, "#Box_1"..i)
    
    -- box middle
    for j = 2, MY_ToolBox.nVisualSkillBoxCount do
        i = ( i + 1 ) % (MY_ToolBox.nVisualSkillBoxCount + 1)
        local box, nDesLeft = ui:item("#Box_1"..i), j*53-8
        MY.BreatheCall(function()
            local nLeft = box:left()
            local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
            if nSpentFrameCount < nAnimateFrameCount then
                box:left(nLeft - (nLeft - nDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
            else
                box:left(nDesLeft)
                return 0
            end
        end, "#Box_1"..i)
    end
    
    -- update index
    _MY_ToolBox.nVisualSkillBoxIndex = ( _MY_ToolBox.nVisualSkillBoxIndex + 1 ) % (MY_ToolBox.nVisualSkillBoxCount + 1)
end
MY.RegisterInit(_MY_ToolBox.ReloadVisualSkill)
--[[
#######################################################################################################
                                                          *     *           *         *           
                                                    *     *     *           *           *         
  * * * *     * *     * * * * * * *   * * * * *     *     *     * * * *     *     * * * * * * *   
    *     *     *     *     *     *     *     *     *     *   *           * * *   *           *   
    *     *     *     *     *   *       *   *       *     * *     *         *         *   *       
    * * *       *     *     * * *       * * *             *         *       *       *       *     
    *     *     *     *     *   *       *   *                               * *   *           *   
    *     *     *     *     *           *           * * * * * * * * *     * *       * * * * *     
    *     *     *     *     *           *           *     *   *     *       *           *         
  * * * *         * *     * * *       * * *         *     *   *     *       *           *         
                                                    *     *   *     *       *           *         
                                                  * * * * * * * * * * *   * *     * * * * * * *  
#######################################################################################################
]]
local _DEFAULT_BUFFMONITOR_CONFIG_FILE_ = MY.GetAddonInfo().szRoot .. "Toolbox/data/buffmon_default"
local _Cache = _Cache or {}
_Cache.handleBoxs = { Self = {}, Target = {} }
MY_BuffMonitor = MY_BuffMonitor or {}

MY_BuffMonitor.bSelfOn = false
MY_BuffMonitor.bTargetOn = false
MY_BuffMonitor.anchorSelf = { s = "CENTER", r = "CENTER", x = -320, y = 150 }
MY_BuffMonitor.anchorTarget = { s = "CENTER", r = "CENTER", x = -320, y = 98 }
MY_BuffMonitor.tBuffList = MY.LoadLUAData(_DEFAULT_BUFFMONITOR_CONFIG_FILE_)
RegisterCustomData("MY_BuffMonitor.bSelfOn")
RegisterCustomData("MY_BuffMonitor.bTargetOn")
RegisterCustomData("MY_BuffMonitor.anchorSelf")
RegisterCustomData("MY_BuffMonitor.anchorTarget")
RegisterCustomData("MY_BuffMonitor.tBuffList")
-- 重置默认设置
MY_BuffMonitor.ReloadDefaultConfig = function()
    MY_BuffMonitor.anchorSelf = { s = "CENTER", r = "CENTER", x = -320, y = 150 }
    MY_BuffMonitor.anchorTarget = { s = "CENTER", r = "CENTER", x = -320, y = 98 }
    MY_BuffMonitor.tBuffList = MY.LoadLUAData(_DEFAULT_BUFFMONITOR_CONFIG_FILE_)
    MY_BuffMonitor.ReloadBuffMonitor()
end
RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT", function()
    MY_BuffMonitor.anchorSelf = { s = "CENTER", r = "CENTER", x = -320, y = 150 }
    MY_BuffMonitor.anchorTarget = { s = "CENTER", r = "CENTER", x = -320, y = 98 }
    MY.UI("Normal/MY_BuffMonitor_Self"):anchor(MY_BuffMonitor.anchorSelf)
    MY.UI("Normal/MY_BuffMonitor_Target"):anchor(MY_BuffMonitor.anchorTarget)
end)
-- 初始化UI
MY_BuffMonitor.ReloadBuffMonitor = function()
    -- unregister render function
    MY.BreatheCall("MY_BuffMonitor_Render_Self")
    MY.BreatheCall("MY_BuffMonitor_Render_Target")
    MY.UI("Normal/MY_BuffMonitor_Self"):remove()
    MY.UI("Normal/MY_BuffMonitor_Target"):remove()
    -- get kungfu id
    local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
    -- functions
    local refreshObjectBuff = function(target, tBuffMonList, handleBoxs)
        local me = GetClientPlayer()
        local nCurrentFrame = GetLogicFrameCount()
        if target then
            -- update buff info
            for _, buff in ipairs(MY.Player.GetBuffList(target)) do
                buff.szName = Table_GetBuffName(buff.dwID, buff.nLevel)
                local nBuffTime, _ = GetBuffTime(buff.dwID, buff.nLevel)
                for _, mon in ipairs(tBuffMonList) do
                    if buff.szName == mon.szName and (buff.dwSkillSrcID == me.dwID or target.dwID == me.dwID) and mon.bOn then
                        mon.nRenderFrame = nCurrentFrame
                        mon.dwIconID = Table_GetBuffIconID(buff.dwID, buff.nLevel)
                        local box = handleBoxs[mon.szName]

                        local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - GetLogicFrameCount()) / 16)

                        box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
                        box:SetOverTextFontScheme(1, 15)
                        box:SetOverText(1, nTimeLeft.."'")

                        if buff.nStackNum == 1 then
                            box:SetOverText(0, "")
                        else
                            box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
                            box:SetOverTextFontScheme(0, 15)
                            box:SetOverText(0, buff.nStackNum)
                        end

                        box:SetObject(1,0)
                        box:SetObjectIcon(mon.dwIconID)

                        local dwPercent = nTimeLeft / ( nBuffTime / 16 )
                        box:SetCoolDownPercentage(dwPercent)
                        
                        if dwPercent < 0.5 and dwPercent > 0.3 then
                            if box.dwPercent ~= 0.5 then
                                box.dwPercent = 0.5
                                box:SetObjectStaring(true)
                            end
                        elseif dwPercent < 0.3 and dwPercent > 0.1 then
                            if box.dwPercent ~= 0.3 then
                                box.dwPercent = 0.3
                                box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 17)
                            end
                        elseif dwPercent < 0.1 then
                            if box.dwPercent ~= 0.1 then
                                box.dwPercent = 0.1
                                box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 20)
                            end
                        else
                            box:SetObjectStaring(false)
                            box:ClearExtentAnimate()
                        end
                    end
                end
            end
        end
        -- update missed buff info
        for _, mon in ipairs(tBuffMonList) do
            if mon.nRenderFrame and mon.nRenderFrame >= 0 and mon.nRenderFrame ~= nCurrentFrame then
                mon.nRenderFrame = -1
                local box = handleBoxs[mon.szName]
                box.dwPercent = 0
                box:SetCoolDownPercentage(0)
                box:SetOverText(0, "")
                box:SetOverText(1, "")
                box:SetObjectStaring(false)
                box:ClearExtentAnimate()
                box:SetObjectSparking(true)
            end
        end
    end
    -- check if enable
    if MY_BuffMonitor.bSelfOn then
        -- create frame
        local ui = MY.UI.CreateFrame("MY_BuffMonitor_Self", true):drag(false)
        -- draw boxes
        local nCount = 0
        for _, mon in ipairs(MY_BuffMonitor.tBuffList[dwKungFuID].Self) do
            if mon.bOn then
                ui:append("Image_Mask_"..mon.szName, "Image"):item("#Image_Mask_"..mon.szName):pos(52 * nCount,0):size(50, 50):image("UI/Image/Common/Box.UITex", 43)
                local box = ui:append("Box_"..mon.szName, "Box"):item("#Box_"..mon.szName):pos(52 * nCount + 3, 3):size(44,44):raw(1)
                
                box:SetObject(1,0)
                box:SetObjectIcon(mon.dwIconID)
                box:SetObjectCoolDown(1)
                box:SetOverText(0, "")
                box:SetOverText(1, "")
                box.dwPercent = 0
                
                _Cache.handleBoxs.Self[mon.szName] = box
                
                nCount = nCount + 1
            end
        end
        ui:size(nCount * 52, 52):anchor(MY_BuffMonitor.anchorSelf)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_BuffMonitor.anchorSelf)
          end):customMode(_L['mingyi self buff monitor'], function(anchor)
            MY_BuffMonitor.anchorSelf = anchor
          end, function(anchor)
            MY_BuffMonitor.anchorSelf = anchor
          end):breathe(function()
            -- register render function
            refreshObjectBuff(GetClientPlayer(), MY_BuffMonitor.tBuffList[dwKungFuID].Self, _Cache.handleBoxs.Self)
        end)
    end
    if MY_BuffMonitor.bTargetOn then
        -- create frame
        local ui = MY.UI.CreateFrame("MY_BuffMonitor_Target", true):drag(false)
        -- draw boxes
        local nCount = 0
        for _, mon in ipairs(MY_BuffMonitor.tBuffList[dwKungFuID].Target) do
            if mon.bOn then
                ui:append("Image_Mask_"..mon.szName, "Image"):item("#Image_Mask_"..mon.szName):pos(52 * nCount,0):size(50, 50):image("UI/Image/Common/Box.UITex", 44)
                local box = ui:append("Box_"..mon.szName, "Box"):item("#Box_"..mon.szName):pos(52 * nCount + 3, 3):size(44,44):raw(1)
                
                box:SetObject(1,0)
                box:SetObjectIcon(mon.dwIconID)
                box:SetObjectCoolDown(1)
                box:SetOverText(0, "")
                box:SetOverText(1, "")

                _Cache.handleBoxs.Target[mon.szName] = box
                
                nCount = nCount + 1
            end
        end
        ui:size(nCount * 52, 52):anchor(MY_BuffMonitor.anchorTarget)
          :onevent("UI_SCALED", function()
            MY.UI(this):anchor(MY_BuffMonitor.anchorTarget)
          end):customMode(_L['mingyi target buff monitor'], function(anchor)
            MY_BuffMonitor.anchorTarget = anchor
          end, function(anchor)
            MY_BuffMonitor.anchorTarget = anchor
          end):breathe(function()
            -- register render function
            refreshObjectBuff(MY.GetObject(MY.GetTarget()), MY_BuffMonitor.tBuffList[dwKungFuID].Target, _Cache.handleBoxs.Target)
        end)
    end
end
MY.RegisterInit(MY_BuffMonitor.ReloadBuffMonitor)
MY.RegisterEvent('SKILL_MOUNT_KUNG_FU', MY_BuffMonitor.ReloadBuffMonitor)
--[[
#######################################################################################################
  * * *         *                 *                     *                   *           *         
  *   *   * * * * * * *       * * * * * * *             * * * * * * * *     * * * *     * * * *   
  *   *       *               *           *           *         *         *   *       *   *       
  *   * *   * * * * *         * * * * * * *           *   * * * * * * *         *     *     *     
  * *     *   *     *         *           *         * *   *     *     *           *     *         
  * *         * * * *         * * * * * * *   *   *   *   * * * * * * *           * * * * * *     
  *   * * *   *     *         *           * *         *   *     *     *     * * * *               
  *   *   *   * * * *     * * * * * * * * *           *   * * * * * * *           *   * * * * *   
  *   *   *   *     *               * *   *           *     *   *         * * * * * *     *       
  * *     *   *   * *           * *       *           *       *                     *   *         
  *       *               * * *           *           *     *   *                   * *       *   
  *     *   * * * * * *               * * *           *   *       * * *     * * * *     * * * *  
#######################################################################################################
]]
MY_Anmerkungen = {}
MY_Anmerkungen.bNotePanelEnable = false
MY_Anmerkungen.anchorNotePanel = { s = "TOPRIGHT", r = "TOPRIGHT", x = -310, y = 135 }
MY_Anmerkungen.nNotePanelWidth = 200
MY_Anmerkungen.nNotePanelHeight = 200
MY_Anmerkungen.szNotePanelContent = ""
MY_Anmerkungen.tPrivatePlayerNotes = {} -- 私有玩家描述
MY_Anmerkungen.tPublicPlayerNotes = {} -- 公共玩家描述
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }
RegisterCustomData("MY_Anmerkungen.bNotePanelEnable")
RegisterCustomData("MY_Anmerkungen.anchorNotePanel")
RegisterCustomData("MY_Anmerkungen.nNotePanelWidth")
RegisterCustomData("MY_Anmerkungen.nNotePanelHeight")
RegisterCustomData("MY_Anmerkungen.szNotePanelContent")
-- 重载便笺
MY_Anmerkungen.ReloadNotePanel = function()
    MY.UI("Normal/MY_Anmerkungen_NotePanel"):remove()
    if MY_Anmerkungen.bNotePanelEnable then
        -- frame
        local ui = MY.UI.CreateFrame("MY_Anmerkungen_NotePanel", true)
        ui:size(MY_Anmerkungen.nNotePanelWidth, MY_Anmerkungen.nNotePanelHeight)
          :drag(true):drag(0,0,MY_Anmerkungen.nNotePanelWidth, 25)
          :anchor(MY_Anmerkungen.anchorNotePanel)
        -- background
        ui:append("Image_Bg", "Image"):item("#Image_Bg"):pos(0,0)
          :size(MY_Anmerkungen.nNotePanelWidth, MY_Anmerkungen.nNotePanelHeight)
          :image("UI/Image/Minimap/Mapmark.UITex", 77):raw(1):SetImageType(10)
        -- title
        ui:append("Text_Title", "Text"):item("#Text_Title"):pos(10,0):size(MY_Anmerkungen.nNotePanelWidth, 25)
          :text(_L['my anmerkungen'])
        -- input box
        ui:append("WndEditBox_Anmerkungen", "WndEditBox"):children("#WndEditBox_Anmerkungen")
          :pos(0, 25):size(MY_Anmerkungen.nNotePanelWidth, MY_Anmerkungen.nNotePanelHeight - 25)
          :multiLine(true):text(MY_Anmerkungen.szNotePanelContent)
          :change(function(txt) MY_Anmerkungen.szNotePanelContent = txt end)
          
        MY.UI.RegisterUIEvent(ui:raw(1), "OnFrameDragEnd", function()
            MY_Anmerkungen.anchorNotePanel = MY.UI("Normal/MY_Anmerkungen_NotePanel"):anchor()
        end)
    end
end
-- 打开一个玩家的记录编辑器
MY_Anmerkungen.OpenPlayerNoteEditPanel = function(dwID, szName)
    local w, h = 300, 270
    local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}
    -- frame
    local ui = MY.UI.CreateFrame("MY_Anmerkungen_PlayerNoteEdit_"..(dwID or 0), true)
    local CloseFrame = function(ui)
        PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
        ui:remove()
    end
    MY.UI.RegisterUIEvent(ui:raw(1), "OnFrameKeyDown", function()
        if GetKeyName(Station.GetMessageKey()) == "Esc" then
            CloseFrame(MY.UI(this))
            return 1
        end
        return 0
    end)
    ui:size(w, h):drag(true):drag(0,0,w,25):anchor( { s = "CENTER", r = "CENTER", x = 0, y = 0 } )
    -- background
    ui:append("Image_Bg", "Image"):item("#Image_Bg"):pos(0,0):size(w, h)
      :image("UI/Image/Minimap/Mapmark.UITex", 77):raw(1):SetImageType(10)
    -- title
    ui:append("Text_Title", "Text"):item("#Text_Title"):pos(10,0):size(w, 25)
      :text(_L['my anmerkungen - player note edit'])
    -- id
    ui:append("Label_ID", "Text"):item("#Label_ID"):pos(20,40)
      :text(_L['ID:'])
    -- id input
    ui:append("WndEditBox_ID", "WndEditBox"):children("#WndEditBox_ID"):pos(80, 40)
      :size(200, 25):text(dwID or note.dwID or ""):multiLine(false)
      :change(function(dwID)
        if dwID == "" or string.find(dwID, "[^%d]") then
            ui:children("#WndButton_Submit"):enable(false)
        else
            ui:children("#WndButton_Submit"):enable(true)
            local rec = MY_Anmerkungen.GetPlayerNote(dwID)
            if rec then
                ui:children("#WndEditBox_Name"):text(rec.szName)
                ui:children("#WndEditBox_Content"):text(rec.szContent)
                ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
                ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
            end
        end
      end)
    -- name
    ui:append("Label_Name", "Text"):item("#Label_Name"):pos(20,70)
      :text(_L['Name:'])
    -- name input
    ui:append("WndEditBox_Name", "WndEditBox"):children("#WndEditBox_Name"):pos(80, 70)
      :size(200, 25):text(szName or note.szName or ""):multiLine(false)
      :change(function(szName)
        local rec = MY_Anmerkungen.GetPlayerNote(szName)
        if rec then
            ui:children("#WndEditBox_ID"):text(rec.dwID)
            ui:children("#WndEditBox_Content"):text(rec.szContent)
            ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
            ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
        end
      end)
    -- content
    ui:append("Label_Content", "Text"):item("#Label_Content"):pos(20,100)
      :text(_L['Content:'])
    -- content input
    ui:append("WndEditBox_Content", "WndEditBox"):children("#WndEditBox_Content"):pos(80, 100)
      :size(200, 80):text(note.szContent or ""):multiLine(true)
    -- alert when group
    ui:append("WndCheckBox_AlertWhenGroup", "WndCheckBox"):children("#WndCheckBox_AlertWhenGroup"):pos(78, 180)
      :text(_L['alert when group']):check(note.bAlertWhenGroup or false)
    -- tip when group
    ui:append("WndCheckBox_TipWhenGroup", "WndCheckBox"):children("#WndCheckBox_TipWhenGroup"):pos(78, 200)
      :text(_L['tip when group']):check(note.bTipWhenGroup or true)
    -- submit button
    ui:append("WndButton_Submit", "WndButton"):children("#WndButton_Submit"):pos(78, 230):width(80)
      :text(_L['sure']):click(function()
        MY_Anmerkungen.SetPlayerNote(
            ui:children("#WndEditBox_ID"):text(),
            ui:children("#WndEditBox_Name"):text(),
            ui:children("#WndEditBox_Content"):text(),
            ui:children("#WndCheckBox_TipWhenGroup"):check(),
            ui:children("#WndCheckBox_AlertWhenGroup"):check()
        )
        CloseFrame(ui)
      end)
    -- cancel button
    ui:append("WndButton_Cancel", "WndButton"):children("#WndButton_Cancel"):pos(163, 230):width(80)
      :text(_L['cancel']):click(function() CloseFrame(ui) end)
    -- delete button
    ui:append("Text_Delete", "Text"):item("#Text_Delete"):pos(250, 228):width(80):alpha(200)
      :text(_L['delete']):color(255,0,0):hover(function(bIn) MY.UI(this):alpha((bIn and 255) or 200) end)
      :click(function()
        MY_Anmerkungen.SetPlayerNote(ui:children("#WndEditBox_ID"):text())
        CloseFrame(ui)
        -- 删除
      end)
      
    -- init data
    ui:children("#WndEditBox_ID"):change()
    PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end
-- 重载右键菜单
MY.RegisterTargetAddonMenu("MY_Anmerkungen_PlayerNotes", function()
    local dwType, dwID = MY.GetTarget()
    if dwType == TARGET.PLAYER then
        local p = MY.GetObject(dwType, dwID)
        return { 
            szOption = _L['edit player note'],
            fnAction = function()
                MY.DelayCall(function()
                    MY_Anmerkungen.OpenPlayerNoteEditPanel(p.dwID, p.szName)
                end, 1)
            end
        }
    end
end)
-- 获取一个玩家的记录
MY_Anmerkungen.GetPlayerNote = function(dwID)
    -- { dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate }
    dwID = tostring(dwID)
    local t, rec = {}, nil
    if not rec then
        rec = MY_Anmerkungen.tPrivatePlayerNotes[dwID]
        if type(rec) ~= "table" then
            rec = MY_Anmerkungen.tPrivatePlayerNotes[tostring(rec)]
        end
        t.bPrivate = true
    end
    if not rec then
        rec = MY_Anmerkungen.tPublicPlayerNotes[dwID]
        if type(rec) ~= "table" then
            rec = MY_Anmerkungen.tPublicPlayerNotes[tostring(rec)]
        end
        t.bPrivate = false
    end
    if not rec then
        t = nil
    else
        t.dwID, t.szName, t.szContent, t,bTipWhenGroup, t.bAlertWhenGroup = rec.dwID, rec.szName, rec.szContent, rec,bTipWhenGroup, rec.bAlertWhenGroup
    end
    return t
end
-- 当有玩家进队时
MY_Anmerkungen.OnPartyAddMember = function()
    MY_Anmerkungen.PartyAddMember(arg1)
end
MY_Anmerkungen.PartyAddMember = function(dwID)
    local team = GetClientTeam()
    local szName = team.GetClientTeamMemberName(dwID)
    -- local dwLeaderID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
    -- local szLeaderName = team.GetClientTeamMemberName(dwLeader)
    local t = MY_Anmerkungen.GetPlayerNote(dwID)
    if t then
        if t.bAlertWhenGroup then
            MessageBox({
                szName = "MY_Anmerkungen_PlayerNotes_"..t.dwID,
                szMessage = _L("Tip: [%s] is in your team.\nNote: %s\n", t.szName, t.szContent),
                {szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
            })
        end
        if t.bTipWhenGroup then
            MY.Sysmsg(_L("Tip: [%s] is in your team.\nNote: %s", t.szName, t.szContent))
        end
    end
end
MY.RegisterEvent("PARTY_ADD_MEMBER", MY_Anmerkungen.OnPartyAddMember)
MY.RegisterEvent("PARTY_SYNC_MEMBER_DATA", MY_Anmerkungen.OnPartyAddMember)
-- 设置一个玩家的记录
MY_Anmerkungen.SetPlayerNote = function(dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate)
    if not dwID then return nil end
    dwID = tostring(dwID)
    if not szName then -- 删除一个玩家的记录
        MY_Anmerkungen.LoadConfig()
        if MY_Anmerkungen.tPrivatePlayerNotes[dwID] then
            MY_Anmerkungen.tPrivatePlayerNotes[MY_Anmerkungen.tPrivatePlayerNotes[dwID].szName] = nil
            MY_Anmerkungen.tPrivatePlayerNotes[dwID] = nil
        end
        if MY_Anmerkungen.tPublicPlayerNotes[dwID] then
            MY_Anmerkungen.tPublicPlayerNotes[MY_Anmerkungen.tPublicPlayerNotes[dwID].szName] = nil
            MY_Anmerkungen.tPublicPlayerNotes[dwID] = nil
        end
        MY_Anmerkungen.SaveConfig()
        return nil
    end
    MY_Anmerkungen.SetPlayerNote(dwID)
    MY_Anmerkungen.LoadConfig()
    local t = {
        dwID = dwID,
        szName = szName,
        szContent = szContent,
        bTipWhenGroup = bTipWhenGroup,
        bAlertWhenGroup = bAlertWhenGroup,
    }
    if bPrivate then
        MY_Anmerkungen.tPrivatePlayerNotes[dwID] = t
        MY_Anmerkungen.tPrivatePlayerNotes[szName] = dwID
    else
        MY_Anmerkungen.tPublicPlayerNotes[dwID] = t
        MY_Anmerkungen.tPublicPlayerNotes[szName] = dwID
    end
    MY_Anmerkungen.SaveConfig()
end
-- 读取公共数据
MY_Anmerkungen.LoadConfig = function()
    MY_Anmerkungen.tPublicPlayerNotes = MY.Json.Decode(MY.Sys.LoadLUAData("config/MY_Anmerkungen_PlayerNotes")) or {}
    MY_Anmerkungen.tPrivatePlayerNotes = MY.Json.Decode(MY.Sys.LoadUserData("config/MY_Anmerkungen_PlayerNotes")) or {}
end
-- 保存公共数据
MY_Anmerkungen.SaveConfig = function()
    MY.Sys.SaveLUAData("config/MY_Anmerkungen_PlayerNotes", MY.Json.Encode(MY_Anmerkungen.tPublicPlayerNotes))
    MY.Sys.SaveUserData("config/MY_Anmerkungen_PlayerNotes", MY.Json.Encode(MY_Anmerkungen.tPrivatePlayerNotes))
end
MY.RegisterInit(MY_Anmerkungen.LoadConfig)
MY.RegisterInit(MY_Anmerkungen.ReloadNotePanel)
--[[
#######################################################################################################
    #       # # # #         # # # # # # # # #                                 #             # #   
      #     #     #         #     #   #     #     # # # # # # # # # # #       #     # # # #       
            #     #         # # # # # # # # #               #                 #     #             
            #     #                 #                     #               # # # #   #             
  # # #   #         # #   # # # # # # # # # # #     # # # # # # # # # #       #     # # # # # #   
      #                             #               #     #     #     #     # # #   #   #     #   
      #   # # # # # #         # # # # # # #         #     # # # #     #     # #   # #   #     #   
      #     #       #         #           #         #     #     #     #   #   #     #   #   #     
      #       #   #           #           #         #     # # # #     #       #     #   #   #     
      # #       #             #     #     #         #     #     #     #       #     #     #       
      #       #   #           #     #     #         # # # # # # # # # #       #   #     #   #     
          # #       # #   # # # # # # # # # # #     #                 #       # #     #       #   
#######################################################################################################
]]
-- 标签栏激活
_MY_ToolBox.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    
    ui:append("WndCheckBox_FriendHeadTip", "WndCheckBox"):children("#WndCheckBox_FriendHeadTip"):pos(20,20)
      :text(_L['friend headtop tips']):check(MY_ToolBox.bFriendHeadTip)
      :check(function(bCheck)
        MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
        _MY_ToolBox.FriendHeadTip(MY_ToolBox.bFriendHeadTip)
    end)
    
    ui:append("WndCheckBox_BagSearch", "WndCheckBox"):children("#WndCheckBox_BagSearch"):pos(140,20)
      :text(_L['package searcher']):check(MY_ToolBox.bBagSearch)
      :check(function(bChecked)
        MY_ToolBox.bBagSearch = bChecked
    end)
    
    ui:append("WndCheckBox_VisualSkill", "WndCheckBox"):children("#WndCheckBox_VisualSkill"):pos(260,20)
      :text(_L['visual skill']):check(MY_ToolBox.bVisualSkill)
      :check(function(bChecked)
        MY_ToolBox.bVisualSkill = bChecked
        _MY_ToolBox.ReloadVisualSkill()
    end)
    
    ui:append("WndSliderBox_VisualSkillCast", "WndSliderBox"):children("#WndSliderBox_VisualSkillCast"):pos(370, 20)
      :sliderStyle(false):range(1, 32):value(MY_ToolBox.nVisualSkillBoxCount)
      :text(_L("display %d skills.", MY_ToolBox.nVisualSkillBoxCount))
      :text(function(val) return _L("display %d skills.", val) end)
      :change(function(val)
        MY_ToolBox.nVisualSkillBoxCount = val
        _MY_ToolBox.ReloadVisualSkill()
      end)
    
    local x, y = 20, 60
    ui:append('WndButton_GongzhanCheck', 'WndButton'):children('#WndButton_GongzhanCheck'):pos(256,y+2):width(120)
      :text(_L['check nearby gongzhan'])
      :lclick(function()
        local tGongZhans = {}
        for _, p in pairs(MY.GetNearPlayer()) do
            for _, buff in pairs(MY.Player.GetBuffList(p)) do
                if (not buff.bCanCancel) and string.find(Table_GetBuffName(buff.dwID, buff.nLevel), _L["GongZhan"]) ~= nil then
                    table.insert(tGongZhans, {p = p, time = (buff.nEndFrame - GetLogicFrameCount()) / 16})
                end
            end
        end
        
        local nChannel = MY_ToolBox.nGongzhanPublishChannel or PLAYER_TALK_CHANNEL.LOCAL_SYS
        
        MY.Talk(nChannel, _L["------------------------------------"])
        for _, r in ipairs(tGongZhans) do
            MY.Talk( nChannel, _L("Detected [%s] has GongZhan buff for %d sec(s).", r.p.szName, r.time) )
        end
        MY.Talk(nChannel, _L("Nearby GongZhan Total Count: %d.", #tGongZhans))
        MY.Talk(nChannel, _L["------------------------------------"])
    end):rmenu(function()
        local t = { { szOption = _L['send to ...'], bDisable = true }, { bDevide = true } }
        for _, tChannel in ipairs(_MY_ToolBox.tChannels) do
            table.insert( t, { 
                szOption = tChannel.szName,
                rgb = tChannel.rgb,
                bCheck = true, bMCheck = true, bChecked = MY_ToolBox.nGongzhanPublishChannel == tChannel.nChannel,
                fnAction = function()
                    MY_ToolBox.nGongzhanPublishChannel = tChannel.nChannel
                end
            } )
        end
        return t
    end)
    
    ui:append("Text_InfoTip", "Text"):find("#Text_InfoTip"):text(_L['* infomation tips']):color(255,255,0):pos(x, y)
    y = y + 30
    for id, cache in pairs(_Cache.InfoTip) do
        local cfg = Config.InfoTip[id]
        ui:append("WndCheckBox_InfoTip_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTip_"..id):pos(x, y):width(100)
          :text(cache.title):check(cfg.bEnable or false)
          :check(function(bChecked)
            cfg.bEnable = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 90
        ui:append("WndCheckBox_InfoTipTitle_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTipTitle_"..id):pos(x, y):width(60)
          :text(_L['title']):check(cfg.bShowTitle or false)
          :check(function(bChecked)
            cfg.bShowTitle = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 40
        ui:append("WndCheckBox_InfoTipBg_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTipBg_"..id):pos(x, y):width(60)
          :text(_L['background']):check(cfg.bShowBg or false)
          :check(function(bChecked)
            cfg.bShowBg = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 45
        ui:append("WndButton_InfoTipFont_"..id, "WndButton"):children("#WndButton_InfoTipFont_"..id):pos(x, y)
          :width(50):text(_L['font'])
          :click(function()
            MY.UI.OpenFontPicker(function(f)
                cfg.nFont = f
                _MY_ToolBox.ReloadInfoTip()
            end)
          end)
        x = x + 60
        ui:append("Shadow_InfoTipColor_"..id, "Shadow"):item("#Shadow_InfoTipColor_"..id):pos(x, y)
          :size(20, 20):color(cfg.rgb or {255,255,255})
          :click(function()
            local me = this
            MY.UI.OpenColorPicker(function(r, g, b)
                MY.UI(me):color(r, g, b)
                cfg.rgb = { r, g, b }
                _MY_ToolBox.ReloadInfoTip()
            end)
          end)
        x = x + 30
        if x + 150 > w then
            x, y = 20, y + 30
        end
    end
    
    local x, y = 20, 200
    ui:append("Text_BuffMonitorTip", "Text"):item("#Text_BuffMonitorTip"):text(_L['* buff monitor']):color(255,255,0):pos(x, y)
    y = y + 30
    ui:append("WndCheckBox_BuffMonitor_Self", "WndCheckBox"):children("#WndCheckBox_BuffMonitor_Self"):pos(x, y)
      :text(_L['self buff monitor']):check(MY_BuffMonitor.bSelfOn)
      :check(function(bChecked)
        MY_BuffMonitor.bSelfOn = bChecked
        MY_BuffMonitor.ReloadBuffMonitor()
      end)
    ui:append("WndComboBox_SelfBuffMonitor", "WndComboBox"):children("#WndComboBox_SelfBuffMonitor"):pos(x + 200, y)
      :text(_L['set self buff monitor'])
      :menu(function()
        local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
        local tBuffMonList = MY_BuffMonitor.tBuffList[dwKungFuID].Self
        local t = {
            {
                szOption = _L['add'],
                fnAction = function()
                    GetUserInput(_L['please input buff name:'], function(szVal)
                        szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
                        if szVal~="" then
                            for i = #tBuffMonList, 1, -1 do 
                                if tBuffMonList[i].szName == szVal then return end
                            end
                            table.insert(tBuffMonList, {szName = szVal, bOn = true, dwIconID = 13})
                            MY_BuffMonitor.ReloadBuffMonitor()
                        end
                    end, function() end, function() end, nil, "" )
                end
            }, { bDevide = true }
        }
        for i, mon in ipairs(tBuffMonList) do
            table.insert(t, {
                szOption = mon.szName,
                bCheck = true, bChecked = mon.bOn,
                fnAction = function(bChecked)
                    mon.bOn = not mon.bOn
                    MY_BuffMonitor.ReloadBuffMonitor()
                end, {
                    szOption = _L['delete'],
                    fnAction = function()
                        table.remove(tBuffMonList, i)
                        MY_BuffMonitor.ReloadBuffMonitor()
                    end,
                }
            })
        end
        return t
      end)
    y = y + 30
    ui:append("WndCheckBox_BuffMonitor_Target", "WndCheckBox"):children("#WndCheckBox_BuffMonitor_Target"):pos(x, y)
      :text(_L['target buff monitor']):check(MY_BuffMonitor.bTargetOn)
      :check(function(bChecked)
        MY_BuffMonitor.bTargetOn = bChecked
        MY_BuffMonitor.ReloadBuffMonitor()
      end)
    ui:append("WndComboBox_TargetBuffMonitor", "WndComboBox"):children("#WndComboBox_TargetBuffMonitor"):pos(x + 200, y)
      :text(_L['set target buff monitor'])
      :menu(function()
        local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
        local tBuffMonList = MY_BuffMonitor.tBuffList[dwKungFuID].Target
        local t = {
            {
                szOption = _L['add'],
                fnAction = function()
                    GetUserInput(_L['please input buff name:'], function(szVal)
                        szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
                        if szVal~="" then
                            for i = #tBuffMonList, 1, -1 do 
                                if tBuffMonList[i].szName == szVal then return end
                            end
                            table.insert(tBuffMonList, {szName = szVal, bOn = true, dwIconID = 13})
                            MY_BuffMonitor.ReloadBuffMonitor()
                        end
                    end, function() end, function() end, nil, "" )
                end
            }, { bDevide = true }
        }
        for i, mon in ipairs(tBuffMonList) do
            table.insert(t, {
                szOption = mon.szName,
                bCheck = true, bChecked = mon.bOn,
                fnAction = function(bChecked)
                    mon.bOn = not mon.bOn
                    MY_BuffMonitor.ReloadBuffMonitor()
                end, {
                    szOption = _L['delete'],
                    fnAction = function()
                        table.remove(tBuffMonList, i)
                        MY_BuffMonitor.ReloadBuffMonitor()
                    end,
                }
            })
        end
        return t
      end)
    -- 随身便笺
    local x, y = 20, 300
    ui:append("Text_Anmerkungen", "Text"):item("#Text_Anmerkungen"):text(_L['* anmerkungen']):color(255,255,0):pos(x, y)
    y = y + 30
    y = y + 10
    ui:append("WndCheckBox_Anmerkungen_NotePanel", "WndCheckBox"):children("#WndCheckBox_Anmerkungen_NotePanel"):pos(x, y)
      :text(_L['my anmerkungen']):check(MY_Anmerkungen.bNotePanelEnable)
      :check(function(bChecked)
        MY_Anmerkungen.bNotePanelEnable = bChecked
        MY_Anmerkungen.ReloadNotePanel()
      end)
    
    y = y - 10
    ui:append("WndSliderBox_Anmerkungen_Width", "WndSliderBox"):children("#WndSliderBox_Anmerkungen_Width"):pos(x + 150, y)
      :sliderStyle(false):range(25, 1000):value(MY_Anmerkungen.nNotePanelWidth)
      :text(_L("width: %dpx.", MY_Anmerkungen.nNotePanelWidth))
      :text(function(val) return _L("width: %dpx.", val) end)
      :change(function(val)
        MY_Anmerkungen.nNotePanelWidth = val
        MY_Anmerkungen.ReloadNotePanel()
      end)
    
    y = y + 20
    ui:append("WndSliderBox_Anmerkungen_Height", "WndSliderBox"):children("#WndSliderBox_Anmerkungen_Height"):pos(x + 150, y)
      :sliderStyle(false):range(50, 1000):value(MY_Anmerkungen.nNotePanelHeight)
      :text(_L("height: %dpx.", MY_Anmerkungen.nNotePanelHeight))
      :text(function(val) return _L("height: %dpx.", val) end)
      :change(function(val)
        MY_Anmerkungen.nNotePanelHeight = val
        MY_Anmerkungen.ReloadNotePanel()
      end)
end
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], _L['General'], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, { OnPanelActive = _MY_ToolBox.OnPanelActive } )
