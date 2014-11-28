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
MY_ToolBox.bAvoidBlackShenxingCD = true
RegisterCustomData("MY_ToolBox.bAvoidBlackShenxingCD")
MY_ToolBox.ApplyConfig = function()
    if MY_ToolBox.bFriendHeadTip then
        _MY_ToolBox.FriendHeadTip(true)
    end
    
    if MY_ToolBox.bAvoidBlackShenxingCD then
        MY.RegisterEvent('DO_SKILL_CAST', 'MY_ToolBox_AvoidBlackShenxingCD', function()
            local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
            local player = GetClientPlayer()
            if not( player and
            player.dwID == dwID and
            Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)) then
                return
            end
            local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = player.GetSkillPrepareState()
            if not (bIsPrepare and dwSkillID == 3691) then
                return
            end
            MY.Sysmsg({_L['Shenxing has been cancelled, cause you got the zhenyan.']})
            player.StopCurrentAction()
        end)
    else
        MY.RegisterEvent('DO_SKILL_CAST', 'MY_ToolBox_AvoidBlackShenxingCD')
    end
end
MY.RegisterInit(MY_ToolBox.ApplyConfig)
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
      :text(_L['package searcher']):check(MY_BagSearch.bEnable or false)
      :check(function(bChecked)
        MY_BagSearch.bEnable = bChecked
    end)
    
    ui:append("WndCheckBox_VisualSkill", "WndCheckBox"):children("#WndCheckBox_VisualSkill"):pos(260,20)
      :text(_L['visual skill']):check(MY_VisualSkill.bEnable or false)
      :check(function(bChecked)
        MY_VisualSkill.bEnable = bChecked
        MY_VisualSkill.Reload()
    end)
    
    ui:append("WndSliderBox_VisualSkillCast", "WndSliderBox"):children("#WndSliderBox_VisualSkillCast"):pos(370, 20)
      :sliderStyle(false):range(1, 32):value(MY_VisualSkill.nVisualSkillBoxCount)
      :text(_L("display %d skills.", MY_VisualSkill.nVisualSkillBoxCount))
      :text(function(val) return _L("display %d skills.", val) end)
      :change(function(val)
        MY_VisualSkill.nVisualSkillBoxCount = val
        MY_VisualSkill.Reload()
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
    for id, cache in pairs(MY_InfoTip.Cache) do
        local cfg = MY_InfoTip.Config[id]
        ui:append("WndCheckBox_InfoTip_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTip_"..id):pos(x, y):width(100)
          :text(cache.title):check(cfg.bEnable or false)
          :check(function(bChecked)
            cfg.bEnable = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 90
        ui:append("WndCheckBox_InfoTipTitle_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTipTitle_"..id):pos(x, y):width(60)
          :text(_L['title']):check(cfg.bShowTitle or false)
          :check(function(bChecked)
            cfg.bShowTitle = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 40
        ui:append("WndCheckBox_InfoTipBg_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTipBg_"..id):pos(x, y):width(60)
          :text(_L['background']):check(cfg.bShowBg or false)
          :check(function(bChecked)
            cfg.bShowBg = bChecked
            MY_InfoTip.Reload()
          end)
        x = x + 45
        ui:append("WndButton_InfoTipFont_"..id, "WndButton"):children("#WndButton_InfoTipFont_"..id):pos(x, y)
          :width(50):text(_L['font'])
          :click(function()
            MY.UI.OpenFontPicker(function(f)
                cfg.nFont = f
                MY_InfoTip.Reload()
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
                MY_InfoTip.Reload()
            end)
          end)
        x = x + 30
        if x + 150 > w then
            x, y = 20, y + 30
        end
    end
    
    local x, y = 220, 200
    ui:append("WndCheckBox_AvoidBlackShenxingCD", "WndCheckBox"):children("#WndCheckBox_AvoidBlackShenxingCD")
      :pos(x, y):width(150)
      :text(_L['avoid blacking shenxing cd']):check(MY_ToolBox.bAvoidBlackShenxingCD or false)
      :check(function(bChecked)
        MY_ToolBox.bAvoidBlackShenxingCD = bChecked
        MY_ToolBox.ApplyConfig()
      end)
    
    local x, y = 20, 200
    ui:append("Text_BuffMonitorTip", "Text"):item("#Text_BuffMonitorTip"):text(_L['* buff monitor']):color(255,255,0):pos(x, y)
    x = x + 100
    ui:append("WndCheckBox_BuffMonitor_Undragable", "WndCheckBox"):children("#WndCheckBox_BuffMonitor_Undragable"):pos(x, y)
      :text(_L['undragable']):check(not MY_BuffMonitor.bDragable)
      :check(function(bChecked)
        MY_BuffMonitor.bDragable = not bChecked
        MY_BuffMonitor.ReloadBuffMonitor()
      end)
    x = 20
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
