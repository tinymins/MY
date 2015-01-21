--
-- �����б�
-- by ���� @ ˫���� @ ݶ����
-- Build 20140730
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Focus/lang/")
local _Cache = {}
_Cache.tFocusList = {}
_Cache.szIniFile = MY.GetAddonInfo().szRoot .. 'MY_Focus/ui/MY_Focus.ini'
_Cache.bMinimize = false
MY_Focus = {}
MY_Focus.bFocusFriend = false -- �Զ��������
MY_Focus.bFocusTong = false -- �Զ��������Ա
MY_Focus.bFocusEnemy= false -- �Զ�����ж����
MY_Focus.bEnable    = true  -- �Ƿ�����
MY_Focus.bAutoHide  = true  -- �޽����Զ�����
MY_Focus.nMaxDisplay= 5     -- �����ʾ����
MY_Focus.bAutoFocus = true  -- ����Ĭ�Ͻ���
MY_Focus.bShowTarget= false -- ��ʾĿ���Ŀ��
MY_Focus.bTraversal = false -- ���������б�
MY_Focus.bHideDeath = false -- ��������Ŀ��
MY_Focus.tAutoFocus = {}    -- Ĭ�Ͻ���
MY_Focus.tFocusList = {     -- ���ý���
    [TARGET.NPC]    = {},
    [TARGET.PLAYER] = {},
    [TARGET.DOODAD] = {},
}
MY_Focus.anchor = { x=-300, y=220, s="TOPRIGHT", r="TOPRIGHT" } -- Ĭ������
RegisterCustomData("MY_Focus.bEnable")
RegisterCustomData("MY_Focus.bAutoHide")
RegisterCustomData("MY_Focus.bFocusFriend")
RegisterCustomData("MY_Focus.bFocusTong")
RegisterCustomData("MY_Focus.bFocusEnemy")
RegisterCustomData("MY_Focus.nMaxDisplay")
RegisterCustomData("MY_Focus.bAutoFocus")
RegisterCustomData("MY_Focus.tAutoFocus")
RegisterCustomData("MY_Focus.tFocusList")
RegisterCustomData("MY_Focus.bShowTarget")
RegisterCustomData("MY_Focus.bTraversal")
RegisterCustomData("MY_Focus.bHideDeath")
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

-- ��ȡ��ǰ��ʾ�Ľ����б�
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

-- ��ȡָ�������Handle û�з���nil
MY_Focus.GetHandle = function(dwType, dwID)
    return Station.Lookup('Normal/MY_Focus', 'Handle_List/Handle_Info_'..dwType..'_'..dwID)
end

-- ���Ĭ�Ͻ���
MY_Focus.AddAutoFocus = function(szName)
    for _, v in ipairs(MY_Focus.tAutoFocus) do
        if v == szName then
            return
        end
    end
    table.insert(MY_Focus.tAutoFocus, szName)
    -- ���½����б�
    MY_Focus.ScanNearby()
end

-- ɾ��Ĭ�Ͻ���
MY_Focus.DelAutoFocus = function(szName)
    for i = #MY_Focus.tAutoFocus, 1, -1 do
        if MY_Focus.tAutoFocus[i] == szName then
            table.remove(MY_Focus.tAutoFocus, i)
        end
    end
    -- ˢ��UI
    if szName:sub(1,1) == '^' then
        -- ������ʽģʽ���ػ潹���б�
        MY_Focus.RescanNearby()
    else
        -- ȫ�ַ�ƥ��ģʽ������Ƿ������ý����� û����ɾ��Handle
        for i = #_Cache.tFocusList, 1, -1 do
            local p = _Cache.tFocusList[i]
            local h = MY.Game.GetObject(p.dwType, p.dwID)
            if h and MY.Game.GetObjectName(h) == szName and
            not MY_Focus.tFocusList[p.dwType][p.dwID] then
                MY_Focus.OnObjectLeaveScene(p.dwType, p.dwID)
            end
        end
    end
end

-- ������ý���
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

-- ɾ�����ý���
MY_Focus.DelStaticFocus = function(dwType, dwID)
    dwType, dwID = tonumber(dwType), tonumber(dwID)
    MY_Focus.tFocusList[dwType][dwID] = nil
    MY_Focus.OnObjectLeaveScene(dwType, dwID)
end

-- ����ɨ�踽��������½����б�ֻ��������
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

-- ���������Ұ
MY_Focus.OnObjectEnterScene = function(dwType, dwID, nRetryCount)
    if nRetryCount and nRetryCount >5 then
        return
    end
    local obj = MY.Game.GetObject(dwType, dwID)
    if not obj then
        return
    end

    local szName = MY.Game.GetObjectName(obj)
    -- �����Ҹս�����Ұʱ����Ϊ�յ�����
    if dwType == TARGET.PLAYER and not szName then
        MY.DelayCall(function()
            MY_Focus.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
        end, 300)
    elseif szName then -- �ж��Ƿ���Ҫ����
        local bFocus = false
        -- �ж����ý���
        if MY_Focus.tFocusList[dwType][dwID] then
            bFocus = true
        end
        -- �ж�Ĭ�Ͻ���
        if MY_Focus.bAutoFocus and not bFocus then
            for _, v in ipairs(MY_Focus.tAutoFocus) do
                if v == szName or
                (v:sub(1,1) == '^' and string.find(szName, v)) then
                    bFocus = true
                end
            end
        end
        -- �жϺ���
        if dwType == TARGET.PLAYER and
        MY_Focus.bFocusFriend and
        MY.Player.GetFriend(dwID) then
            bFocus = true
        end
        -- �ж�ͬ���
        if dwType == TARGET.PLAYER and
        MY_Focus.bFocusTong and
        dwID ~= UI_GetClientPlayerID() and
        MY.Player.GetTongMember(dwID) then
            bFocus = true
        end
        -- �жϵж����
        if dwType == TARGET.PLAYER and
        MY_Focus.bFocusEnemy and
        IsEnemy(UI_GetClientPlayerID(), dwID) then
            bFocus = true
        end
        -- ���뽹��
        if bFocus then
            MY_Focus.AddFocus(dwType, dwID)
        end
    end
end

-- �����뿪��Ұ
MY_Focus.OnObjectLeaveScene = function(dwType, dwID)
    MY_Focus.DelFocus(dwType, dwID)
end

-- Ŀ����뽹���б�
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

-- Ŀ���Ƴ������б�
MY_Focus.DelFocus = function(dwType, dwID)
    -- ���б�������ɾ��
    for i = #_Cache.tFocusList, 1, -1 do
        local p = _Cache.tFocusList[i]
        if p.dwType == dwType and p.dwID == dwID then
            table.remove(_Cache.tFocusList, i)
            break
        end
    end
    -- ��UI��ɾ��
    local hItem = Station.Lookup('Normal/MY_Focus', 'Handle_List/Handle_Info_'..dwType..'_'..dwID)
    if hItem then
        MY.UI(hItem):remove()
        -- ����UI��������������ʱ��
        local p = _Cache.tFocusList[MY_Focus.nMaxDisplay]
        if p then
            MY_Focus.DrawFocus(p.dwType, p.dwID)
        end
    end
end

-- ��ȡ�����б�
MY_Focus.GetFocusList = function()
    local t = {}
    for _, v in ipairs(_Cache.tFocusList) do
        table.insert(t, v)
    end
    return t
end

-- ��ս����б�
MY_Focus.ClearFocus = function()
    _Cache.tFocusList = {}
    
    local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
    if not hList then
        return
    end
    hList:Clear()
end

-- ����ɨ�踽������
MY_Focus.RescanNearby = function()
    MY_Focus.ClearFocus()
    MY_Focus.ScanNearby()
end

-- �ػ��б�
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

-- �����б�
MY_Focus.UpdateList = function()
    for i, p in ipairs(MY_Focus.GetDisplayList()) do
        MY_Focus.DrawFocus(p.dwType, p.dwID)
    end
end

-- ����ָ���Ľ���Handle��û������Ӵ�����
MY_Focus.DrawFocus = function(dwType, dwID)
    local obj, info, bInfo = MY.Game.GetObject(dwType, dwID)
    local hList = Station.Lookup('Normal/MY_Focus', 'Handle_List')
    if not (obj and hList) then
        return
    end

    local hItem = MY_Focus.GetHandle(dwType, dwID)
    if not hItem then
        hItem = hList:AppendItemFromIni(_Cache.szIniFile, 'Handle_Info')
        hItem:SetName('Handle_Info_'..dwType..'_'..dwID)
    end
    
    -- ����
    hItem:Lookup('Handle_Name/Text_Name'):SetText(MY.Game.GetObjectName(obj) or obj.dwID)
    -- �ķ�
    if dwType == TARGET.PLAYER then
        if bInfo and info.dwMountKungfuID then
            hItem:Lookup('Handle_Name/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(info.dwMountKungfuID))
        else
            local kungfu = obj.GetKungfuMount()
            if kungfu then
                hItem:Lookup('Handle_Name/Text_Kungfu'):SetText(MY_Focus.GetKungfuName(kungfu.dwSkillID))
            end
        end
    end
    -- Ѫ��
    if dwType ~= TARGET.DOODAD then
        local nCurrentLife, nMaxLife = info.nCurrentLife, info.nMaxLife
        local nCurrentMana, nMaxMana = info.nCurrentMana, info.nMaxMana
        local szLife = ''
        if nCurrentLife > 10000 then
            szLife = szLife .. FormatString(g_tStrings.MPNEY_TENTHOUSAND, math.floor(nCurrentLife / 1000) / 10)
        else
            szLife = szLife .. nCurrentLife
        end
        if nMaxLife > 0 then
            local nPercent = math.floor(nCurrentLife / nMaxLife * 100)
            if nPercent > 100 then
                nPercent = 100
            end
            szLife = szLife .. '(' .. nPercent .. '%)'
            hItem:Lookup('Handle_LM/Image_Health'):SetPercentage(nCurrentLife / nMaxLife)
            hItem:Lookup('Handle_LM/Text_Health'):SetText(szLife)
        end
        if nMaxMana > 0 then
            hItem:Lookup('Handle_LM/Image_Mana'):SetPercentage(nCurrentMana / nMaxMana)
            hItem:Lookup('Handle_LM/Text_Mana'):SetText(nCurrentMana .. '/' .. nMaxMana)
        end
    end
    -- ����
    if dwType ~= TARGET.DOODAD then
        local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = obj.GetSkillPrepareState()
        if MY_Focus.bTraversal and dwType == TARGET.PLAYER
        and (not bIsPrepare and obj.GetOTActionState() == 1) then
            MY.Player.WithTarget(dwType, dwID, function()
                local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = obj.GetSkillPrepareState()
                if bIsPrepare then
                    hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
                    hItem:Lookup('Handle_Progress/Text_Progress'):SetText(MY_Focus.GetSkillName(dwSkillID, dwSkillLevel))
                else
                    hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
                    hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
                end
            end)
        else
            if bIsPrepare then
                hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
                hItem:Lookup('Handle_Progress/Text_Progress'):SetText(MY_Focus.GetSkillName(dwSkillID, dwSkillLevel))
            else
                hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
                hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
            end
        end
    end
    -- Ŀ���Ŀ��
    if MY_Focus.bShowTarget and dwType ~= TARGET.DOODAD then
        local tp, id = obj.GetTarget()
        local tar = MY.Game.GetObject(tp, id)
        if tar then
            hItem:Lookup('Handle_Progress/Text_Target'):SetText(MY.Game.GetObjectName(tar) or tar.dwID)
        else
            hItem:Lookup('Handle_Progress/Text_Target'):SetText('')
        end
    end
    -- ѡ��״̬
    hItem:Lookup('Image_Select'):Hide()
    local player = GetClientPlayer()
    if player then
        local dwTargetType, dwTargetID = player.GetTarget()
        if dwTargetType == dwType and dwTargetID == dwID then
            hItem:Lookup('Image_Select'):Show()
        end
    end
    -- Ŀ�����
    local nDistance = math.floor(math.sqrt(math.pow(player.nX - obj.nX, 2) + math.pow(player.nY - obj.nY, 2)) * 10 / 64) / 10
    hItem:Lookup('Handle_Compass/Compass_Distance'):SetText(nDistance)
    -- ��������
    if player then
        hItem:Lookup('Handle_Compass/Image_Player'):Show()
        hItem:Lookup('Handle_Compass/Image_Player'):SetRotate( - player.nFaceDirection / 128 * math.pi)
    end
    -- ���λ��
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
        -- ���нǶ�
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

-- ����Ӧ���������С
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

-- ��ȡ�ڹ��ķ��ַ���
local m_tKungfuName = {}
MY_Focus.GetKungfuName = function(dwKungfuID)
    if not m_tKungfuName[dwKungfuID] then
        m_tKungfuName[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1)
    end
    return m_tKungfuName[dwKungfuID]
end

-- ��ȡ���������ַ���
local m_tSkillName = {}
MY_Focus.GetSkillName = function(dwSkillID, dwSkillLevel)
    if not m_tSkillName[dwSkillID] then
        m_tSkillName[dwSkillID] = Table_GetSkillName(dwSkillID, dwSkillLevel)
    end
    return m_tSkillName[dwSkillID]
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

-- �����ػ�
MY_Focus.OnFrameBreathe = function()
    if MY_Focus.bHideDeath then
        for _, p in ipairs(MY_Focus.GetFocusList()) do
            if p.dwType == TARGET.NPC or p.dwType == TARGET.PLAYER then
                local tar = MY.GetObject(p.dwType, p.dwID)
                if not tar or tar.nMoveState == MOVE_STATE.ON_DEATH then
                    MY_Focus.DelFocus(p.dwType, p.dwID)
                end
            end
        end
    end
    MY_Focus.UpdateList()
    MY_Focus.AdjustUI()
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
        dwType, dwID = tonumber(dwType), tonumber(dwID)
        local t = {}
        if dwType == TARGET.PLAYER then
            t = MY.Game.GetTargetContextMenu(dwType, this:Lookup('Handle_Name/Text_Name'):GetText(), dwID)
        end
        table.insert(t, 1, {
            szOption = _L['delete focus'],
            fnAction = function()
                MY_Focus.DelStaticFocus(dwType, dwID)
            end
        })
        PopupMenu(t)
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

-- ��ȡ���ò˵�
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
            szOption = _L['auto focus friend'],
            bCheck = true,
            bChecked = MY_Focus.bFocusFriend,
            fnAction = function()
                MY_Focus.bFocusFriend = not MY_Focus.bFocusFriend
                MY_Focus.RescanNearby()
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end,
        }, {
            szOption = _L['auto focus tong'],
            bCheck = true,
            bChecked = MY_Focus.bFocusTong,
            fnAction = function()
                MY_Focus.bFocusTong = not MY_Focus.bFocusTong
                MY_Focus.RescanNearby()
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end,
        }, {
            szOption = _L['auto focus enemy'],
            bCheck = true,
            bChecked = MY_Focus.bFocusEnemy,
            fnAction = function()
                MY_Focus.bFocusEnemy = not MY_Focus.bFocusEnemy
                MY_Focus.RescanNearby()
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end,
        }, {
            szOption = _L['show focus\'s target'],
            bCheck = true,
            bChecked = MY_Focus.bShowTarget,
            fnAction = function()
                MY_Focus.bShowTarget = not MY_Focus.bShowTarget
                MY_Focus.RedrawList()
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end,
        }, {
            szOption = _L['traversal object'],
            bCheck = true,
            bChecked = MY_Focus.bTraversal,
            fnAction = function()
                MY_Focus.bTraversal = not MY_Focus.bTraversal
            end,
            fnDisable = function()
                return not MY_Focus.bEnable
            end,
        }, {
            szOption = _L['hide dead object'],
            bCheck = true,
            bChecked = MY_Focus.bHideDeath,
            fnAction = function()
                MY_Focus.bHideDeath = not MY_Focus.bHideDeath
                MY_Focus.RescanNearby()
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
                    MY.UI.OpenListEditor('MY_Focus_NamelistManager', MY_Focus.tAutoFocus, function(szText)
                        -- ȥ��ǰ��ո�
                        szText = (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
                        -- ��֤�Ƿ�Ϊ��
                        if szText=="" then return nil end
                        -- ��֤�Ƿ��ظ�
                        for i, v in ipairs(MY_Focus.tAutoFocus) do
                            if v==szText then
                                return false
                            end
                        end
                        -- �����
                        MY_Focus.AddAutoFocus(szText)
                    end, function(szText)
                        MY_Focus.DelAutoFocus(szText)
                    end)
                    :text(_L["namelist manager"])
                end,
                fnDisable = function()
                    return not MY_Focus.bAutoFocus
                end
            },
        }
    }

    local t1 = {
        szOption = _L['max display length'],
        fnDisable = function()
            return not MY_Focus.bEnable
        end,
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
        end,
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
