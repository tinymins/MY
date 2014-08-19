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
    _MY_ToolBox.FilterPackage("Normal/BigBagPanel/", _MY_ToolBox.szBagFilter, _MY_ToolBox.bBagTimeLtd)
end
-- 过滤仓库
_MY_ToolBox.DoFilterBank = function()
    _MY_ToolBox.FilterPackage("Normal/BigBankPanel/", _MY_ToolBox.szBankFilter, _MY_ToolBox.bBankTimeLtd)
end
-- 过滤帮会仓库
_MY_ToolBox.DoFilterGuildBank = function()
    _MY_ToolBox.FilterGuildPackage("Normal/GuildBankPanel/", _MY_ToolBox.szGuildBankFilter)
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
MY_ToolBox.InfoTip = {
    -- FPS
    FPS       = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-190, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['fps monitor'],
                  breathe = function() MY.UI(this):find("#Text_Default"):text(_L("FPS: %d", GetFPS())) end },
    -- 目标距离
    Distance  = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-160, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['target distance'],
                      breathe = function()
                    local p, s = MY.GetObject(MY.GetTarget()), _L["No Target"]
                    if p then
                        s = _L('Distance: %.1f Foot', GetCharacterDistance(GetClientPlayer().dwID, p.dwID)/64)
                    end
                    MY.UI(this):find("#Text_Default"):text(s)
                  end },
    -- 系统时间
    SysTime   = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-130, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['system time'],
                  breathe = function()
                    local tDateTime = TimeToDate(GetCurrentTime())
                    MY.UI(this):find("#Text_Default"):text(_L("Time: %02d:%02d:%02d", tDateTime.hour, tDateTime.minute, tDateTime.second))
                  end },
    -- 战斗计时
    FightTime = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-100, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['fight clock'],
                  breathe = function()
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
                        s = _L("Fight Clock: %d:%02d:%02d", math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
                    end
                    MY.UI(this):find("#Text_Default"):text(s)
                  end },
    -- 莲花和藕倒计时
    LotusTime = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['lotus clock'],
                  breathe = function()
                    local nTotal = 6*60*60 - GetLogicFrameCount()/16%(6*60*60)
                    MY.UI(this):find("#Text_Default"):text(_L("Lotus Clock: %d:%d:%d", math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60)))
                  end },
}
for k, v in pairs(MY_ToolBox.InfoTip) do
    RegisterCustomData("MY_ToolBox.InfoTip."..k..".bEnable")
    RegisterCustomData("MY_ToolBox.InfoTip."..k..".bShowBg")
    RegisterCustomData("MY_ToolBox.InfoTip."..k..".anchor")
end
-- 显示信息条
_MY_ToolBox.ReloadInfoTip = function()
    for id, p in pairs(MY_ToolBox.InfoTip) do
        local frm = MY.UI('Normal/MY_InfoTip_'..id)
        if p.bEnable then
            if frm:count()==0 then
                frm = MY.UI.CreateFrame('MY_InfoTip_'..id,true):size(150,30):onevent("UI_SCALED", function()
                    MY.UI(this):anchor(p.anchor)
                end):customMode(p.title, function(anchor)
                    p.anchor = anchor
                end, function(anchor)
                    p.anchor = anchor
                end):breathe(p.breathe):drag(0,0,0,0):drag(false)
                frm:append("Image_Default","Image"):find("#Image_Default"):size(150,30):image("UI/Image/UICommon/Commonpanel.UITex",86):alpha(180)
                frm:append("Text_Default", "Text"):find("#Text_Default"):size(150,30):text(p.title):font(2):raw(1):SetHAlign(1)
                -- frm:find("#Text_Default"):raw(1):SetVAlign(1)
            end
            if p.bShowBg then
                frm:find("#Image_Default"):show()
            else
                frm:find("#Image_Default"):hide()
            end
            frm:anchor(p.anchor)
        else
            frm:remove()
        end
    end
end
-- 注册INIT事件
MY.RegisterInit(function() _MY_ToolBox.ReloadInfoTip() end)
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
          end)
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
MY_ToolBox.VisualSkillCast = function(dwSkillID, dwSkillLevel)
    local ui = MY.UI("Normal/MY_ToolBox_VisualSkill/WndWindow_Normal")
    if ui:count()==0 then return end
    -- get name
    local szSkillName, dwIconID = MY.Player.GetSkillName(dwSkillID, dwSkillLevel)
    if not szSkillName or szSkillName == "" or dwIconID == 13 then
        return
    end
    local nAnimateFrameCount, nStartFrame = 8, GetLogicFrameCount()
    -- box enter
    local i = _MY_ToolBox.nVisualSkillBoxIndex
    local boxEnter = ui:item("#Box_1"..i)
    boxEnter:raw(1):EnableObject(false)
    boxEnter:raw(1):SetObjectCoolDown(1)
    boxEnter:raw(1):SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
    boxEnter:raw(1):SetObjectIcon(Table_GetSkillIconID(dwSkillID, dwSkillLevel))
    UpdataSkillCDProgress(GetClientPlayer(), boxEnter:raw(1))
    local nEnterDesLeft = MY_ToolBox.nVisualSkillBoxCount*53 + 45
    MY.BreatheCall(function()
        local nLeft = boxEnter:left()
        local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
        if nSpentFrameCount < nAnimateFrameCount then
            boxEnter:alpha(255 * (nSpentFrameCount/nAnimateFrameCount)):left(nLeft - (nLeft - nEnterDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
        else
            boxEnter:alpha(255):left(nEnterDesLeft):raw(1):SetObjectCoolDown(0)
            return 0
        end
    end)
    
    -- box leave
    i = ( i + 1 ) % (MY_ToolBox.nVisualSkillBoxCount + 1)
    local boxLeave = ui:item("#Box_1"..i)
    boxLeave:raw(1):SetObjectCoolDown(0)
    local nLeaveDesLeft = -200
    MY.BreatheCall(function()
        local nLeft = boxLeave:left()
        local nSpentFrameCount = GetLogicFrameCount() - nStartFrame
        if nSpentFrameCount < nAnimateFrameCount then
            boxLeave:alpha(255 * (1-nSpentFrameCount/nAnimateFrameCount)):left(nLeft - (nLeft - nLeaveDesLeft)/(nAnimateFrameCount - nSpentFrameCount))
        else
            boxLeave:alpha(0):left(45+MY_ToolBox.nVisualSkillBoxCount*53+300)
            return 0
        end
    end)
    
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
        end)
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
            -- update missed buff info
            for _, mon in ipairs(tBuffMonList) do
                if mon.nRenderFrame and mon.nRenderFrame > 0 and mon.nRenderFrame ~= nCurrentFrame then
                    mon.nRenderFrame = -1
                    local box = handleBoxs[mon.szName]
                    box:SetOverText(0, "")
                    box:SetOverText(1, "")
                    box:SetObjectStaring(false)
                    box:ClearExtentAnimate()
                    box:SetObjectSparking(true)
                end
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
          end)
        -- register render function
        MY.BreatheCall("MY_BuffMonitor_Render_Self", function()
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
          end)
        -- register render function
        MY.BreatheCall("MY_BuffMonitor_Render", function()
            refreshObjectBuff(MY.GetObject(MY.GetTarget()), MY_BuffMonitor.tBuffList[dwKungFuID].Target, _Cache.handleBoxs.Target)
        end)
    end
end
MY.RegisterInit(MY_BuffMonitor.ReloadBuffMonitor)
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
    for id, p in pairs(MY_ToolBox.InfoTip) do
        ui:append("WndCheckBox_InfoTip_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTip_"..id):pos(x, y)
          :text(p.title):check(MY_ToolBox.InfoTip[id].bEnable)
          :check(function(bChecked)
            MY_ToolBox.InfoTip[id].bEnable = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 120
        ui:append("WndCheckBox_InfoTipBg_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTipBg_"..id):pos(x, y)
          :text(_L['show background']):check(MY_ToolBox.InfoTip[id].bShowBg)
          :check(function(bChecked)
            MY_ToolBox.InfoTip[id].bShowBg = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 150
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
end
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, { OnPanelActive = _MY_ToolBox.OnPanelActive } )
