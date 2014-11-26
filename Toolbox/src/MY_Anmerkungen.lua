
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
    ui:append("Label_Name", "Text"):item("#Label_Name"):pos(20,70)
      :text(_L['Name:'])
    -- name input
    ui:append("WndEditBox_Name", "WndEditBox"):children("#WndEditBox_Name"):pos(80, 70)
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
            ui:children("#WndButton_Submit"):enable(false)
            ui:children("#WndEditBox_ID"):text('')
        end
      end)
    -- content
    ui:append("Label_Content", "Text"):item("#Label_Content"):pos(20,100)
      :text(_L['Content:'])
    -- content input
    ui:append("WndEditBox_Content", "WndEditBox"):children("#WndEditBox_Content"):pos(80, 100)
      :size(200, 80):multiLine(true):text(note.szContent or "")
    -- alert when group
    ui:append("WndCheckBox_AlertWhenGroup", "WndCheckBox"):children("#WndCheckBox_AlertWhenGroup")
      :pos(78, 180):width(200)
      :text(_L['alert when group']):check(note.bAlertWhenGroup or false)
    -- tip when group
    ui:append("WndCheckBox_TipWhenGroup", "WndCheckBox"):children("#WndCheckBox_TipWhenGroup")
      :pos(78, 200):width(200)
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