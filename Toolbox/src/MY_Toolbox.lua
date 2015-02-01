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
        local frm = MY.UI.CreateFrame("MY_Shadow", MY.Const.UI.Frame.LOWEST_EMPTY):show()
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
    -- 好友高亮
    if MY_ToolBox.bFriendHeadTip then
        _MY_ToolBox.FriendHeadTip(true)
    end
    
    -- 试炼之地九宫助手
    MY.RegisterEvent('OPEN_WINDOW', 'JiugongHelper', function(arg0, szText)
        if MY.IsShieldedVersion() then
            return
        end
        -- 确定当前对话对象是醉逍遥（18707）
        local target = GetTargetHandle(GetClientPlayer().GetTarget())
        if target and target.dwTemplateID ~= 18707 then
            return
        end
        -- 匹配字符串
        string.gsub(szText, "<T1916><(T%d+)><T1926><(T%d+)><T1928><(T%d+)><T1924>.+<T1918><(T%d+)><T1931><(T%d+)><T1933><(T%d+)><T1935>.+<T1920><(T%d+)><T1937><(T%d+)><T1938><(T%d+)><T1939>", function(n1,n2,n3,n4,n5,n6,n7,n8,n9)
            local tNumList = {
                T1925 = 1, T1927 = 2, T1929 = 3,
                T1930 = 4, T1932 = 5, T1934 = 6,
                T1936 = 7, T1922 = 8, T1923 = 9,
                T1940 = false,
            }
            local tDefaultSolution = {
                {8,1,6,3,5,7,4,9,2},
                {6,1,8,7,5,3,2,9,4},
                {4,9,2,3,5,7,8,1,6},
                {2,9,4,7,5,3,6,1,8},
                {6,7,2,1,5,9,8,3,4},
                {8,3,4,1,5,9,6,7,2},
                {2,7,6,9,5,1,4,3,8},
                {4,3,8,9,5,1,2,7,6},
            }
            
            n1,n2,n3,n4,n5,n6,n7,n8,n9 = tNumList[n1],tNumList[n2],tNumList[n3],tNumList[n4],tNumList[n5],tNumList[n6],tNumList[n7],tNumList[n8],tNumList[n9]
            local tQuestion = {n1,n2,n3,n4,n5,n6,n7,n8,n9}
            local tSolution
            for _, solution in ipairs(tDefaultSolution) do
                local bNotMatch = false
                for i, v in ipairs(solution) do
                    if tQuestion[i] and tQuestion[i] ~= v then
                        bNotMatch = true
                        break
                    end
                end
                if not bNotMatch then
                    tSolution = solution
                    break
                end
            end
            local szText = _L['The kill sequence is: ']
            if tSolution then
                for i, v in ipairs(tQuestion) do
                    if not tQuestion[i] then
                        szText = szText .. NumberToChinese(tSolution[i]) .. ' '
                    end
                end
            else
                szText = szText .. _L['failed to calc.']
            end
            MY.Sysmsg({szText})
            OutputWarningMessage("MSG_WARNING_RED", szText, 10)
        end)
    end)
    
    -- 防止神行CD被吃
    if MY_ToolBox.bAvoidBlackShenxingCD then
        MY.RegisterEvent('DO_SKILL_CAST', 'MY_ToolBox_AvoidBlackShenxingCD', function()
            local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
            if not(UI_GetClientPlayerID() == dwID and
            Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)) then
                return
            end
            local player = GetClientPlayer()
            if not player then
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
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], _L['General'], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, { OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    local x, y = 20, 30
    
    -- 检测附近共战
    ui:append('WndButton_GongzhanCheck', 'WndButton'):children('#WndButton_GongzhanCheck')
      :pos(w - 140, y):width(120)
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
    
    -- 好友高亮
    ui:append("WndCheckBox_FriendHeadTip", "WndCheckBox"):children("#WndCheckBox_FriendHeadTip")
      :pos(x, y):width(180)
      :text(_L['friend headtop tips'])
      :check(MY_ToolBox.bFriendHeadTip)
      :check(function(bCheck)
        MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
        _MY_ToolBox.FriendHeadTip(MY_ToolBox.bFriendHeadTip)
      end)
    y = y + 30
    
    -- 背包搜索
    ui:append("WndCheckBox_BagSearch", "WndCheckBox"):children("#WndCheckBox_BagSearch")
      :pos(x, y)
      :text(_L['package searcher'])
      :check(MY_BagSearch.bEnable or false)
      :check(function(bChecked)
        MY_BagSearch.bEnable = bChecked
      end)
    y = y + 30
    
    -- 显示历史技能列表
    ui:append("WndCheckBox_VisualSkill", "WndCheckBox"):children("#WndCheckBox_VisualSkill")
      :pos(x, y):width(160)
      :text(_L['visual skill'])
      :check(MY_VisualSkill.bEnable or false)
      :check(function(bChecked)
        MY_VisualSkill.bEnable = bChecked
        MY_VisualSkill.Reload()
      end)
    
    ui:append("WndSliderBox_VisualSkillCast", "WndSliderBox"):children("#WndSliderBox_VisualSkillCast")
      :pos(x + 160, y)
      :sliderStyle(false):range(1, 32)
      :value(MY_VisualSkill.nVisualSkillBoxCount)
      :text(_L("display %d skills.", MY_VisualSkill.nVisualSkillBoxCount))
      :text(function(val) return _L("display %d skills.", val) end)
      :change(function(val)
        MY_VisualSkill.nVisualSkillBoxCount = val
        MY_VisualSkill.Reload()
      end)
    y = y + 30
    
    -- 防止神行CD被黑
    ui:append("WndCheckBox_AvoidBlackShenxingCD", "WndCheckBox"):children("#WndCheckBox_AvoidBlackShenxingCD")
      :pos(x, y):width(150)
      :text(_L['avoid blacking shenxing cd']):check(MY_ToolBox.bAvoidBlackShenxingCD or false)
      :check(function(bChecked)
        MY_ToolBox.bAvoidBlackShenxingCD = bChecked
        MY_ToolBox.ApplyConfig()
      end)
    y = y + 30
    
    -- 自动隐藏聊天栏
    ui:append("WndCheckBox_AutoHideChatPanel", "WndCheckBox"):children("#WndCheckBox_AutoHideChatPanel")
      :pos(x, y):width(150)
      :text(_L['auto hide chat panel']):check(MY_AutoHideChat.bAutoHideChatPanel)
      :check(function(bChecked)
        MY_AutoHideChat.bAutoHideChatPanel = bChecked
        MY_AutoHideChat.ApplyConfig()
      end)
    y = y + 30
    
    -- BUFF监控
    ui:append("Text_BuffMonitorTip", "Text"):item("#Text_BuffMonitorTip")
      :pos(x, y)
      :color(255,255,0)
      :text(_L['* buff monitor'])
    
    ui:append("WndCheckBox_BuffMonitor_Undragable", "WndCheckBox"):children("#WndCheckBox_BuffMonitor_Undragable")
      :pos(x + 100, y):width(100)
      :text(_L['undragable']):check(not MY_BuffMonitor.bDragable)
      :check(function(bChecked)
        MY_BuffMonitor.bDragable = not bChecked
        MY_BuffMonitor.ReloadBuffMonitor()
      end)
    y = y + 30
    
    ui:append("WndCheckBox_BuffMonitor_Self", "WndCheckBox"):children("#WndCheckBox_BuffMonitor_Self")
      :pos(x, y)
      :text(_L['self buff monitor'])
      :check(MY_BuffMonitor.bSelfOn)
      :check(function(bChecked)
        MY_BuffMonitor.bSelfOn = bChecked
        MY_BuffMonitor.ReloadBuffMonitor()
      end)
    
    ui:append("WndComboBox_SelfBuffMonitor", "WndComboBox"):children("#WndComboBox_SelfBuffMonitor")
      :pos(x + 200, y)
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
    
    ui:append("WndCheckBox_BuffMonitor_Target", "WndCheckBox"):children("#WndCheckBox_BuffMonitor_Target")
      :pos(x, y)
      :text(_L['target buff monitor'])
      :check(MY_BuffMonitor.bTargetOn)
      :check(function(bChecked)
        MY_BuffMonitor.bTargetOn = bChecked
        MY_BuffMonitor.ReloadBuffMonitor()
      end)
    
    ui:append("WndComboBox_TargetBuffMonitor", "WndComboBox"):children("#WndComboBox_TargetBuffMonitor")
      :pos(x + 200, y)
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
    y = y + 30
    
    -- 随身便笺
    ui:append("Text_Anmerkungen", "Text"):item("#Text_Anmerkungen")
      :pos(x, y)
      :color(255,255,0)
      :text(_L['* anmerkungen'])
    y = y + 30
    
    ui:append("WndCheckBox_Anmerkungen_NotePanel", "WndCheckBox"):children("#WndCheckBox_Anmerkungen_NotePanel")
      :pos(x, y + 10)
      :text(_L['my anmerkungen']):check(MY_Anmerkungen.bNotePanelEnable)
      :check(function(bChecked)
        MY_Anmerkungen.bNotePanelEnable = bChecked
        MY_Anmerkungen.ReloadNotePanel()
      end)
    
    ui:append("WndSliderBox_Anmerkungen_Width", "WndSliderBox"):children("#WndSliderBox_Anmerkungen_Width")
      :pos(x + 150, y)
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
end})
