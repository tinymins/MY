
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
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _C = {}
MY_Anmerkungen = {}
MY_Anmerkungen.bNotePanelEnable = false
MY_Anmerkungen.anchorNotePanel = { s = "TOPRIGHT", r = "TOPRIGHT", x = -310, y = 135 }
MY_Anmerkungen.nNotePanelWidth = 200
MY_Anmerkungen.nNotePanelHeight = 200
MY_Anmerkungen.szNotePanelContent = ""
MY_Anmerkungen.tPrivatePlayerNotes = {} -- ˽���������
MY_Anmerkungen.tPublicPlayerNotes = {} -- �����������
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }
RegisterCustomData("MY_Anmerkungen.bNotePanelEnable")
RegisterCustomData("MY_Anmerkungen.anchorNotePanel")
RegisterCustomData("MY_Anmerkungen.nNotePanelWidth")
RegisterCustomData("MY_Anmerkungen.nNotePanelHeight")
RegisterCustomData("MY_Anmerkungen.szNotePanelContent")
-- ���ر��
MY_Anmerkungen.ReloadNotePanel = function()
    MY.UI("Normal/MY_Anmerkungen_NotePanel"):remove()
    if MY_Anmerkungen.bNotePanelEnable then
        -- frame
        local ui = MY.UI.CreateFrame("MY_Anmerkungen_NotePanel", MY.Const.UI.Frame.NORMAL_EMPTY)
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
-- ��һ����ҵļ�¼�༭��
MY_Anmerkungen.OpenPlayerNoteEditPanel = function(dwID, szName)
    local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}
    -- frame
    local ui = MY.UI.CreateFrame("MY_Anmerkungen_PlayerNoteEdit_"..(dwID or 0), MY.Const.UI.Frame.NORMAL)
    local CloseFrame = function(ui)
        MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
        PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
        ui:remove()
        return true
    end
    ui:onuievent("OnFrameKeyDown", function()
        if GetKeyName(Station.GetMessageKey()) == "Esc" then
            CloseFrame(MY.UI(this))
            return 1
        end
        return 0
      end)
      :onuievent("OnCloseButtonClick", CloseFrame)
    
    MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', function()
        return ui and ui:count() > 0
    end, function()
        CloseFrame(ui)
    end)
    
    local w, h = 300, 210
    local x, y = 20 , 0
    
    ui:size(w + 40, h + 90):anchor( { s = "CENTER", r = "CENTER", x = 0, y = 0 } )
    -- title
    ui:text(_L['my anmerkungen - player note edit'])
    -- id
    ui:append("Label_ID", "Text"):item("#Label_ID"):pos(x, y)
      :text(_L['ID:'])
    -- id input
    ui:append("WndEditBox_ID", "WndEditBox"):children("#WndEditBox_ID"):pos(x + 60, y)
      :size(200, 25):multiLine(false):enable(false):color(200,200,200)
      :text(dwID or note.dwID or "")
      -- :change(function(dwID)
      --   if dwID == "" or string.find(dwID, "[^%d]") then
      --       ui:children("#WndButton_Submit"):enable(false)
      --   else
      --       ui:children("#WndButton_Submit"):enable(true)
      --       local rec = MY_Anmerkungen.GetPlayerNote(dwID)
      --       if rec then
      --           ui:children("#WndEditBox_Name"):text(rec.szName)
      --           ui:children("#WndEditBox_Content"):text(rec.szContent)
      --           ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
      --           ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
      --       end
      --   end
      -- end)
    -- name
    ui:append("Label_Name", "Text"):item("#Label_Name"):pos(x, y + 30)
      :text(_L['Name:'])
    -- name input
    ui:append("WndEditBox_Name", "WndEditBox"):children("#WndEditBox_Name"):pos(x + 60, y + 30)
      :size(200, 25):multiLine(false):text(szName or note.szName or "")
      :change(function(szName)
        local rec = MY_Anmerkungen.GetPlayerNote(szName)
        if rec then
            ui:children("#WndButton_Submit"):enable(true)
            ui:children("#WndEditBox_ID"):text(rec.dwID)
            ui:children("#WndEditBox_Content"):text(rec.szContent)
            ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
            ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
        else
            local tInfo
            if MY_Farbnamen then
                tInfo = MY_Farbnamen.GetAusName(szName)
            end
            if tInfo then
                ui:children("#WndButton_Submit"):enable(true)
                ui:children("#WndEditBox_ID"):text(tInfo.dwID)
                ui:children("#WndEditBox_Content"):text('')
                ui:children("#WndCheckBox_TipWhenGroup"):check(true)
                ui:children("#WndCheckBox_AlertWhenGroup"):check(false)
            else
                ui:children("#WndButton_Submit"):enable(false)
                ui:children("#WndEditBox_ID"):text('')
            end
        end
      end)
    -- content
    ui:append("Label_Content", "Text"):item("#Label_Content"):pos(x, y + 60)
      :text(_L['Content:'])
    -- content input
    ui:append("WndEditBox_Content", "WndEditBox"):children("#WndEditBox_Content")
      :pos(x + 60, y + 60):size(200, 80)
      :multiLine(true):text(note.szContent or "")
    -- alert when group
    ui:append("WndCheckBox_AlertWhenGroup", "WndCheckBox"):children("#WndCheckBox_AlertWhenGroup")
      :pos(x + 58, y + 140):width(200)
      :text(_L['alert when group']):check(note.bAlertWhenGroup or false)
    -- tip when group
    ui:append("WndCheckBox_TipWhenGroup", "WndCheckBox"):children("#WndCheckBox_TipWhenGroup")
      :pos(x + 58, y + 160):width(200)
      :text(_L['tip when group']):check(note.bTipWhenGroup or true)
    -- submit button
    ui:append("WndButton_Submit", "WndButton"):children("#WndButton_Submit")
      :pos(x + 58, y + 190):width(80)
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
    ui:append("WndButton_Cancel", "WndButton"):children("#WndButton_Cancel")
      :pos(x + 143, y + 190):width(80)
      :text(_L['cancel']):click(function() CloseFrame(ui) end)
    -- delete button
    ui:append("Text_Delete", "Text"):item("#Text_Delete")
      :pos(x + 230, y + 188):width(80):alpha(200)
      :text(_L['delete']):color(255,0,0):hover(function(bIn) MY.UI(this):alpha((bIn and 255) or 200) end)
      :click(function()
        MY_Anmerkungen.SetPlayerNote(ui:children("#WndEditBox_ID"):text())
        CloseFrame(ui)
        -- ɾ��
      end)
      
    -- init data
    ui:children("#WndEditBox_ID"):change()
    Station.SetFocusWindow(ui:raw(1))
    PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end
-- �����Ҽ��˵�
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
-- ��ȡһ����ҵļ�¼
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
-- ������ҽ���ʱ
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
            MY.Sysmsg({_L("Tip: [%s] is in your team.\nNote: %s", t.szName, t.szContent)})
        end
    end
end
MY.RegisterEvent("PARTY_ADD_MEMBER", MY_Anmerkungen.OnPartyAddMember)
MY.RegisterEvent("PARTY_SYNC_MEMBER_DATA", MY_Anmerkungen.OnPartyAddMember)
-- ����һ����ҵļ�¼
MY_Anmerkungen.SetPlayerNote = function(dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate)
    if not dwID then return nil end
    dwID = tostring(dwID)
    if not szName then -- ɾ��һ����ҵļ�¼
        MY_Anmerkungen.LoadConfig()
        if MY_Anmerkungen.tPrivatePlayerNotes[dwID] then
            MY_Anmerkungen.tPrivatePlayerNotes[MY_Anmerkungen.tPrivatePlayerNotes[dwID].szName] = nil
            MY_Anmerkungen.tPrivatePlayerNotes[dwID] = nil
        end
        if MY_Anmerkungen.tPublicPlayerNotes[dwID] then
            MY_Anmerkungen.tPublicPlayerNotes[MY_Anmerkungen.tPublicPlayerNotes[dwID].szName] = nil
            MY_Anmerkungen.tPublicPlayerNotes[dwID] = nil
        end
        if _C.list then
            _C.list:listbox('delete', nil, dwID)
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
    if _C.list then
        _C.list:listbox('update', _L('[%s] %s', t.szName, t.szContent), dwID, t)
    end
    MY_Anmerkungen.SaveConfig()
end
-- ��ȡ��������
MY_Anmerkungen.LoadConfig = function()
    MY_Anmerkungen.tPublicPlayerNotes = MY.Json.Decode(MY.Sys.LoadLUAData("config/MY_Anmerkungen_PlayerNotes")) or {}
    MY_Anmerkungen.tPrivatePlayerNotes = MY.Json.Decode(MY.Sys.LoadUserData("config/MY_Anmerkungen_PlayerNotes")) or {}
end
-- ���湫������
MY_Anmerkungen.SaveConfig = function()
    MY.Sys.SaveLUAData("config/MY_Anmerkungen_PlayerNotes", MY.Json.Encode(MY_Anmerkungen.tPublicPlayerNotes))
    MY.Sys.SaveUserData("config/MY_Anmerkungen_PlayerNotes", MY.Json.Encode(MY_Anmerkungen.tPrivatePlayerNotes))
end
MY.RegisterInit(MY_Anmerkungen.LoadConfig)
MY.RegisterInit(MY_Anmerkungen.ReloadNotePanel)
MY.RegisterPanel( "MY_Anmerkungen", _L["anmerkungen"], _L['Chat'], "ui/Image/button/ShopButton.UITex|12", {255,255,0,200}, { OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    local x, y = 0, 0

    local list = ui:append('WndListBox_1', 'WndListBox'):children('#WndListBox_1')
      :pos(x, y)
      :size(w, h)
      :listbox('onlclick', function(szText, szID, data, bSelected)
        MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
        return false
      end)
    for dwID, t in pairs(MY_Anmerkungen.tPublicPlayerNotes) do
        if tonumber(dwID) then
            list:listbox('insert', _L('[%s] %s', t.szName, t.szContent), t.dwID, t)
        end
    end
    _C.list = list
end, OnPanelDeactive = function()
    _C.list = nil
end})
