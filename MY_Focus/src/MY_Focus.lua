--
-- 焦点列表
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Focus/lang/")
local _Cache = {}
_Cache.tFocusList = {}
_Cache.szIniFile = MY.GetAddonInfo().szRoot .. 'MY_Focus/ui/MY_Focus.ini'
_Cache.bMinimize = false
MY_Focus = {}
MY_Focus.bEnable    = true  -- 是否启用
MY_Focus.bAutoHide  = true  -- 无焦点自动隐藏
MY_Focus.nMaxDisplay = 5    -- 最大显示数量
MY_Focus.bAutoFocus = true  -- 启用默认焦点
MY_Focus.tAutoFocus = {     -- 默认焦点
    string.char(0xB4, 0xE5, 0xBF, 0xDA, 0xB5, 0xC4, 0xCD, 0xF5, 0xCA, 0xA6, 0xB8, 0xB5)
}
MY_Focus.tFocusList = {     -- 永久焦点
    [TARGET.NPC]    = {},
    [TARGET.PLAYER] = {},
    [TARGET.DOODAD] = {},
}
MY_Focus.anchor = { x=-300, y=220, s="TOPRIGHT", r="TOPRIGHT" } -- 默认坐标
RegisterCustomData("MY_Focus.bEnable")
RegisterCustomData("MY_Focus.bAutoHide")
RegisterCustomData("MY_Focus.nMaxDisplay")
RegisterCustomData("MY_Focus.bAutoFocus")
RegisterCustomData("MY_Focus.tAutoFocus")
RegisterCustomData("MY_Focus.tFocusList")
RegisterCustomData("MY_Focus.anchor")

local m_frame
MY_Focus.Open = function()
    m_frame = Wnd.OpenWindow(_Cache.szIniFile, 'MY_Focus')
    m_frame:Lookup('', 'Handle_List'):Clear()
    MY.UI(m_frame):anchor(MY_Focus.anchor)
    
    MY.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_Focus', function()
        MY_Focus.OnObjectEnterScene(TARGET.PLAYER, arg0)
    end)
    MY.RegisterEvent('NPC_ENTER_SCENE', 'MY_Focus', function()
        MY_Focus.OnObjectEnterScene(TARGET.NPC, arg0)
    end)
    MY.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_Focus', function()
        MY_Focus.OnObjectEnterScene(TARGET.DOODAD, arg0)
    end)
    MY.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_Focus', function()
        MY_Focus.OnObjectLeaveScene(TARGET.PLAYER, arg0)
    end)
    MY.RegisterEvent('NPC_LEAVE_SCENE', 'MY_Focus', function()
        MY_Focus.OnObjectLeaveScene(TARGET.NPC, arg0)
    end)
    MY.RegisterEvent('DOODAD_LEAVE_SCENE', 'MY_Focus', function()
        MY_Focus.OnObjectLeaveScene(TARGET.DOODAD, arg0)
    end)
    MY_Focus.ScanNearby()
end

MY_Focus.Close = function()
    Wnd.CloseWindow(m_frame)
    MY.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_Focus')
    MY.RegisterEvent('NPC_ENTER_SCENE'   , 'MY_Focus')
    MY.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_Focus')
    MY.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_Focus')
    MY.RegisterEvent('NPC_LEAVE_SCENE'   , 'MY_Focus')
    MY.RegisterEvent('DOODAD_LEAVE_SCENE', 'MY_Focus')
end

-- 获取当前显示的焦点列表
MY_Focus.GetDisplayList = function()
    local t = {}
    if _Cache.bMinimize then
        return t
    end
    for i, v in ipairs(_Cache.tFocusList) do
        if i > MY_Focus.nMaxDisplay then
            break
        end
        table.insert(t, v)
    end
    return t
end

-- 获取指定焦点的Handle 没有返回nil
MY_Focus.GetHandle = function(dwType, dwID)
    return Station.Lookup('Normal/MY_Focus', 'Handle_List/Handle_Info_'..dwType..'_'..dwID)
end

-- 添加默认焦点
MY_Focus.AddAutoFocus = function(szName)
    for _, v in ipairs(MY_Focus.tAutoFocus) do
        if v == szName then
            return
        end
    end
    table.insert(MY_Focus.tAutoFocus, szName)
    -- 更新焦点列表
    MY_Focus.ScanNearby()
end

-- 删除默认焦点
MY_Focus.DelAutoFocus = function(szName)
    for i = #MY_Focus.tAutoFocus, 1, -1 do
        if MY_Focus.tAutoFocus[i] == szName then
            table.remove(MY_Focus.tAutoFocus, i)
        end
    end
    -- 刷新UI
    if szName:sub(1,1) == '^' then
        -- 正则表达式模式：重绘焦点列表
        MY_Focus.RescanNearby()
    else
        -- 全字符匹配模式：检查是否在永久焦点中 没有则删除Handle
        for i = #_Cache.tFocusList, 1, -1 do
            local p = _Cache.tFocusList[i]
            local h = GetTargetHandle(p.dwType, p.dwID)
            if h and MY.Game.GetObjectName(h) == szName and
            not MY_Focus.tFocusList[p.dwType][p.dwID] then
                MY_Focus.OnObjectLeaveScene(p.dwType, p.dwID)
            end
        end
    end
end

-- 添加永久焦点
MY_Focus.AddStaticFocus = function(dwType, dwID)
    dwType, dwID = tonumber(dwType), tonumber(dwID)
    for _dwType, tFocusList in pairs(MY_Focus.tFocusList) do
        for _dwID, _ in pairs(tFocusList) do
            if _dwType == dwType and _dwID == dwID then
                return
            end
        end
    end
    MY_Focus.tFocusList[dwType][dwID] = true
    MY_Focus.OnObjectEnterScene(dwType, dwID)
end

-- 删除永久焦点
MY_Focus.DelStaticFocus = function(dwType, dwID)
    dwType, dwID = tonumber(dwType), tonumber(dwID)
    MY_Focus.tFocusList[dwType][dwID] = nil
    MY_Focus.OnObjectLeaveScene(dwType, dwID)
end

-- 重新扫描附近对象更新焦点列表（只增不减）
MY_Focus.ScanNearby = function()
    for dwID, _ in pairs(MY.Player.GetNearPlayer()) do
        MY_Focus.OnObjectEnterScene(TARGET.PLAYER, dwID)
    end
    for dwID, _ in pairs(MY.Player.GetNearNpc()) do
        MY_Focus.OnObjectEnterScene(TARGET.NPC, dwID)
    end
    for dwID, _ in pairs(MY.Player.GetNearDoodad()) do
        MY_Focus.OnObjectEnterScene(TARGET.DOODAD, dwID)
    end
end

-- 对象进入视野
MY_Focus.OnObjectEnterScene = function(dwType, dwID, nRetryCount)
    if nRetryCount and nRetryCount >5 then
        return
    end
    local obj = GetTargetHandle(dwType, dwID)
    if not obj then
        return
    end

    local szName = MY.Game.GetObjectName(obj)
    -- 解决玩家刚进入视野时名字为空的问题
    if dwType == TARGET.PLAYER and szName == '' then
        MY.DelayCall(function()
            MY_Focus.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
        end, 300)
    else -- 判断是否需要焦点
        local bFocus = false
        -- 判断永久焦点
        if MY_Focus.tFocusList[dwType][dwID] then
            bFocus = true
        end
        -- 判断默认焦点
        if MY_Focus.bAutoFocus and not bFocus then
            for _, v in ipairs(MY_Focus.tAutoFocus) do
                if v == szName or
                (v:sub(1,1) == '^' and string.find(szName, v)) then
                    bFocus = true
                end
            end
        end
        if bFocus then
            MY_Focus.AddFocus(dwType, dwID)
        end
    end
end

-- 对象离开视野
MY_Focus.OnObjectLeaveScene = function(dwType, dwID)
    MY_Focus.DelFocus(dwType, dwID)
end

-- 目标加入焦点列表
MY_Focus.AddFocus = function(dwType, dwID, szName)
    local nIndex
    for i, p in ipairs(_Cache.tFocusList) do
        if p.dwType == dwType and p.dwID == dwID then
            nIndex = i
            break
        end
    end
    if not nIndex then
        table.insert(_Cache.tFocusList, {dwType = dwType, dwID = dwID, szName = szName})
        nIndex = #_Cache.tFocusList
    end
    if nIndex < MY_Focus.nMaxDisplay then
        MY_Focus.DrawFocus(dwType, dwID)
        MY_Focus.AdjustUI()
    end
end

-- 目标移除焦点列表
MY_Focus.DelFocus = function(dwType, dwID)
    -- 从列表数据中删除
    for i = #_Cache.tFocusList, 1, -1 do
        local p = _Cache.tFocusList[i]
        if p.dwType == dwType and p.dwID == dwID then
            table.remove(_Cache.tFocusList, i)
            break
        end
    end
    -- 从UI中删除
    local hItem = Station.Lookup('Normal/MY_Focus', 'Handle_List/Handle_Info_'..dwType..'_'..dwID)
    if hItem then
        MY.UI(hItem):remove()
        -- 补上UI（超过数量限制时）
        local p = _Cache.tFocusList[MY_Focus.nMaxDisplay]
        if p then
            MY_Focus.DrawFocus(p.dwType, p.dwID)
        end
    end
end

-- 清空焦点列表
MY_Focus.ClearFocus = function()
    _Cache.tFocusList = {}
    
    local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
    if not hList then
        return
    end
    hList:Clear()
end

-- 重新扫描附近焦点
MY_Focus.RescanNearby = function()
    MY_Focus.ClearFocus()
    MY_Focus.ScanNearby()
end

-- 重绘列表
MY_Focus.RedrawList = function(hList)
    if not hList then
        hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
        if not hList then
            return
        end
    end
    hList:Clear()
    MY_Focus.UpdateList()
end

-- 更新列表
MY_Focus.UpdateList = function()
    for i, p in ipairs(MY_Focus.GetDisplayList()) do
        MY_Focus.DrawFocus(p.dwType, p.dwID)
    end
end

-- 绘制指定的焦点Handle（没有则添加创建）
MY_Focus.DrawFocus = function(dwType, dwID)
    local obj = GetTargetHandle(dwType, dwID)
    local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
    if not (obj and hList) then
        return
    end

    local hItem = MY_Focus.GetHandle(dwType, dwID)
    if not hItem then
        hItem = hList:AppendItemFromIni(_Cache.szIniFile, 'Handle_Info')
        hItem:SetName('Handle_Info_'..dwType..'_'..dwID)
    end
    
    -- 名字
    hItem:Lookup('Handle_Name/Text_Name'):SetText(MY.Game.GetObjectName(obj))
    -- 心法
    if dwType == TARGET.PLAYER then
        local kungfu = obj.GetKungfuMount()
        if kungfu then
            hItem:Lookup('Handle_Name/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(kungfu.dwSkillID))
        end
    end
    -- 血量
    local szLife = ''
    if obj.nCurrentLife > 10000 then
        szLife = szLife .. FormatString(g_tStrings.MPNEY_TENTHOUSAND, math.floor(obj.nCurrentLife / 1000) / 10)
    else
        szLife = szLife .. obj.nCurrentLife
    end
    if obj.nMaxLife > 0 then
        local nPercent = math.floor(obj.nCurrentLife / obj.nMaxLife * 100)
        if nPercent > 100 then
            nPercent = 100
        end
        szLife = szLife .. '(' .. nPercent .. '%)'
        hItem:Lookup('Handle_LM/Image_Health'):SetPercentage(obj.nCurrentLife / obj.nMaxLife)
        hItem:Lookup('Handle_LM/Text_Health'):SetText(szLife)
    end
    if obj.nMaxMana > 0 then
        hItem:Lookup('Handle_LM/Image_Mana'):SetPercentage(obj.nCurrentMana / obj.nMaxMana)
        hItem:Lookup('Handle_LM/Text_Mana'):SetText(obj.nCurrentMana .. '/' .. obj.nMaxMana)
    end
    -- 选中状态
    hItem:Lookup('Image_Select'):Hide()
    local player = GetClientPlayer()
    if player then
        local dwTargetType, dwTargetID = player.GetTarget()
        if dwTargetType == dwType and dwTargetID == dwID then
            hItem:Lookup('Image_Select'):Show()
        end
    end
    -- 目标距离
    local nDistance = math.floor(GetCharacterDistance(UI_GetClientPlayerID(), dwID) * 10 / 64) / 10
    hItem:Lookup('Handle_Compass/Compass_Distance'):SetText(nDistance)
    -- 自身面向
    if player then
        hItem:Lookup('Handle_Compass/Image_Player'):Show()
        hItem:Lookup('Handle_Compass/Image_Player'):SetRotate( - player.nFaceDirection / 128 * math.pi)
    end
    -- 相对位置
    hItem:Lookup('Handle_Compass/Image_PointRed'):Hide()
    hItem:Lookup('Handle_Compass/Image_PointGreen'):Hide()
    if player and nDistance > 0 then
        local h
        if IsEnemy(UI_GetClientPlayerID(), dwID) then
            h = hItem:Lookup('Handle_Compass/Image_PointRed')
        else
            h = hItem:Lookup('Handle_Compass/Image_PointGreen')
        end
        h:Show()
        local nRotate = 0
        -- 特判角度
        if player.nX == obj.nX then
            if player.nY > obj.nY then
                nRotate = math.pi / 2
            else
                nRotate = - math.pi / 2
            end
        else
            nRotate = math.atan((player.nY - obj.nY) / (player.nX - obj.nX))
        end
        if nRotate < 0 then
            nRotate = nRotate + math.pi
        end
        if obj.nY < player.nY then
            nRotate = math.pi + nRotate
        end
        local nRadius = 13.5
        h:SetRelPos(nRadius + nRadius * math.cos(nRotate) + 2, nRadius - 3 - 13.5 * math.sin(nRotate))
        h:GetParent():FormatAllItemPos()
    end
    
    hItem:FormatAllItemPos()
    hList:FormatAllItemPos()
end

-- 自适应调整界面大小
MY_Focus.AdjustUI = function()
    local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
    if not hList then
        return
    end
    
    local tList = MY_Focus.GetDisplayList()
    hList:SetSize(240, 70 * #tList)
    hList:GetRoot():SetSize(240, 70 * #tList + 32)
    if #tList == 0 and MY_Focus.bAutoHide and not _Cache.bMinimize then
        hList:GetRoot():Hide()
    elseif (not MY_Focus.bAutoHide) or #tList ~= 0 then
        hList:GetRoot():Show()
    end
end

-- 获取内功心法字符串
local m_tKungfuName = {}
MY_Focus.GetKungfuName = function(dwKungfuID)
    if not m_tKungfuName[dwKungfuID] then
        m_tKungfuName[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1)
    end
    return m_tKungfuName[dwKungfuID]
end

--[[
##########################################################################
                                    #                 #         #         
                          # # # # # # # # # # #       #   #     #         
  # #     # # # # # # #       #     #     #         #     #     #         
    #     #       #           # # # # # # #         #     # # # # # # #   
    #     #       #                 #             # #   #       #         
    #     #       #         # # # # # # # # #       #           #         
    #     #       #                 #       #       #           #         
    #     #       #       # # # # # # # # # # #     #   # # # # # # # #   
    #     #       #                 #       #       #           #         
      # #     # # # # #     # # # # # # # # #       #           #         
                                    #               #           #         
                                  # #               #           #         
##########################################################################
]]

-- 周期重绘
local m_nTick = 0
MY_Focus.OnFrameBreathe = function()
    if m_nTick == 0 then
        MY_Focus.UpdateList()
    end
    MY_Focus.AdjustUI()
    m_nTick = m_nTick + 1
    if m_nTick > 1 then
        m_nTick = 0
    end
end

MY_Focus.OnFrameDragSetPosEnd = function()
    this:CorrectPos()
    MY_Focus.anchor = MY.UI(this):anchor('TOPRIGHT')
end

MY_Focus.OnItemLButtonClick = function()
    local name = this:GetName()
    name:gsub('Handle_Info_(%d+)_(%d+)', function(dwType, dwID)
        SetTarget(dwType, dwID)
    end)
end

MY_Focus.OnItemRButtonClick = function()
    local name = this:GetName()
    name:gsub('Handle_Info_(%d+)_(%d+)', function(dwType, dwID)
        PopupMenu({{
            szOption = _L['delete focus'],
            fnAction = function()
                MY_Focus.DelStaticFocus(dwType, dwID)
            end
        }})
    end)
end

MY_Focus.OnLButtonClick = function()
    local name = this:GetName()
    if name == 'Btn_Setting' then
        PopupMenu(MY_Focus.GetMenu())
    end
end

MY_Focus.OnCheckBoxCheck = function()
    local name = this:GetName()
    if name == 'CheckBox_Minimize' then
        _Cache.bMinimize = true
        this:GetRoot():Lookup('', 'Handle_List'):Hide()
    end
end

MY_Focus.OnCheckBoxUncheck = function()
    local name = this:GetName()
    if name == 'CheckBox_Minimize' then
        _Cache.bMinimize = false
        this:GetRoot():Lookup('', 'Handle_List'):Show()
    end
end

-- 获取设置菜单
MY_Focus.GetMenu = function()
    local t = {
        szOption = _L["focus list"],
        {
            szOption = _L['enable'],
            bCheck = true,
            bChecked = MY_Focus.bEnable,
            fnAction = function()
                MY_Focus.bEnable = not MY_Focus.bEnable
                if MY_Focus.bEnable then
                    MY_Focus.Open()
                else
                    MY_Focus.Close()
                end
            end,
        }, {
            szOption = _L['hide when empty'],
            bCheck = true,
            bChecked = MY_Focus.bAutoHide,
            fnAction = function()
                MY_Focus.bAutoHide = not MY_Focus.bAutoHide
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end,
        }, {
            szOption = _L["auto focus"],
            bCheck = true,
            bChecked = MY_Focus.bAutoFocus,
            fnAction = function()
                MY_Focus.bAutoFocus = not MY_Focus.bAutoFocus
                MY_Focus.RescanNearby()
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end, {
                szOption = _L['namelist manager'],
                fnAction = function()
                    local muDel
                    local AddListItem = function(muList, szText)
                        local i = muList:hdl(1):children():count()
                        local muItem = muList:append('<handle><image>w=300 h=25 eventid=371 name="Image_Bg" </image><text>name="Text_Default" </text></handle>'):hdl(1):children():last()
                        local hHandle = muItem:raw(1)
                        hHandle.Value = szText
                        local hText = muItem:children("#Text_Default"):pos(10, 2):text(szText or ""):raw(1)
                        muItem:children("#Image_Bg"):image("UI/Image/Common/TextShadow.UITex",5):alpha(0):hover(function(bIn)
                            if hHandle.Selected then return nil end
                            if bIn then
                                MY.UI(this):fadeIn(100)
                            else
                                MY.UI(this):fadeTo(500,0)
                            end
                        end):click(function(nButton)
                            if nButton == MY.Const.Event.Mouse.RBUTTON then
                                hHandle.Selected = true
                                PopupMenu({{
                                    szOption = _L["delete"],
                                    fnAction = function()
                                        muDel:click()
                                    end,
                                }})
                            else
                                hHandle.Selected = not hHandle.Selected
                            end
                            if hHandle.Selected then
                                MY.UI(this):image("UI/Image/Common/TextShadow.UITex",2)
                            else
                                MY.UI(this):image("UI/Image/Common/TextShadow.UITex",5)
                            end
                        end)
                    end
                    local ui = MY.UI.CreateFrame("MY_Focus_NamelistManager"):text(_L["namelist manager"])
                    ui:append("Image_Spliter", "Image"):find("#Image_Spliter"):pos(-10,25):size(360, 10):image("UI/Image/UICommon/Commonpanel.UITex",42)
                    local muEditBox = ui:append("WndEditBox_Keyword", "WndEditBox"):find("#WndEditBox_Keyword"):pos(0,0):size(170, 25)
                    local muList = ui:append("WndScrollBox_KeywordList", "WndScrollBox"):find("#WndScrollBox_KeywordList"):handleStyle(3):pos(0,30):size(340, 380)
                    -- add
                    ui:append("WndButton_Add", "WndButton"):find("#WndButton_Add"):pos(180,0):width(80):text(_L["add"]):click(function()
                        local szText = muEditBox:text()
                        muEditBox:text("")
                        -- 去掉前后空格
                        szText = (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
                        -- 验证是否为空
                        if szText=="" then return nil end
                        -- 验证是否重复
                        for i, v in ipairs(MY_Focus.tAutoFocus) do
                            if v==szText then return nil end
                        end
                        -- 加入表
                        AddListItem(muList, szText)
                        MY_Focus.AddAutoFocus(szText)
                    end)
                    -- del
                    muDel = ui:append("WndButton_Del", "WndButton"):find("#WndButton_Del"):pos(260,0):width(80):text(_L["delete"]):click(function()
                        muList:hdl(1):children():each(function(ui)
                            if this.Selected then
                                MY_Focus.DelAutoFocus(this.Value)
                                ui:remove()
                            end
                        end)
                    end)
                    -- insert data to ui
                    for i, v in ipairs(MY_Focus.tAutoFocus) do
                        AddListItem(muList, v)
                    end
                end,
                fnDisable = function()
                    return not MY_Focus.bAutoFocus
                end
            },
        }
    }

    local t1 = {
        szOption = _L['max display length'],
    }
    for i = 1, 15 do
        table.insert(t1, {
            szOption = i,
            bMCheck = true,
            bChecked = MY_Focus.nMaxDisplay == i,
            fnAction = function()
                MY_Focus.nMaxDisplay = i
                MY_Focus.RedrawList()
            end,
        })
    end
    table.insert(t, t1)

    return t
end

MY.RegisterTargetAddonMenu('MY_Focus', function()
    local dwType, dwID = GetClientPlayer().GetTarget()
    return {
        szOption = _L['add to focus list'],
        fnAction = function()
            MY_Focus.AddStaticFocus(dwType, dwID)
        end
    }
end)

MY.RegisterInit(function()
    if MY_Focus.bEnable then
        MY_Focus.Open()
    else
        MY_Focus.Close()
    end
end)
MY.RegisterPlayerAddonMenu('MY_FOCUS_MENU', MY_Focus.GetMenu)
MY.RegisterTraceButtonMenu('MY_FOCUS_MENU', MY_Focus.GetMenu)