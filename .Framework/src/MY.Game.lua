---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
MY = MY or {}
MY.Game = MY.Game or {}
local _Cache, _L = {}, MY.LoadLangPack()
--[[
#######################################################################################################
      #       #               #         #           #           #         
      #       #               #     # # # # # #     # #       # # # #     
      #   # # # # # #         #         #         #     # #     #   #     
  #   # #     #     #     # # # #   # # # # #             # # # # # # #   
  #   #       #     #         #         #   #     # # #   #     #   #     
  #   #       #     #         #     # # # # # #     #   #     # # # #     
  #   # # # # # # # # #       # #       #   #       #   # #     #         
      #       #           # # #     # # # # #     # # #   # # # # # #     
      #     #   #             #         #           #     #     #         
      #     #   #             #     #   # # # #     #   # # # # # # # #   
      #   #       #           #     #   #           # #   #     #         
      # #           # #     # #   #   # # # # #     #   #   # # # # # #   
#######################################################################################################
]]
_Cache.tHotkey = {}
--[[ 增加系统快捷键
    (void) MY.AddHotKey(string szName, string szTitle, func fnAction)   -- 增加系统快捷键
]]
MY.Game.AddHotKey = function(szName, szTitle, fnAction)
    if string.sub(szName, 1, 3) ~= "MY_" then
        szName = "MY_" .. szName
    end
    table.insert(_Cache.tHotkey, { szName = szName, szTitle = szTitle, fnAction = fnAction })
end
--[[ 获取快捷键名称
    (string) MY.GetHotKeyName(string szName, boolean bBracket, boolean bShort)      -- 取得快捷键名称
]]
MY.Game.GetHotKeyName = function(szName, bBracket, bShort)
    if string.sub(szName, 1, 3) ~= "MY_" then
        szName = "MY_" .. szName
    end
    local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
    local szKey = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
    if szKey ~= "" and bBracket then
        szKey = "(" .. szKey .. ")"
    end
    return szKey
end
--[[ 获取快捷键
    (table) MY.GetHotKey(string szName, true , true )       -- 取得快捷键
    (number nKey, boolean bShift, boolean bCtrl, boolean bAlt) MY.GetHotKey(string szName, true , fasle)        -- 取得快捷键
]]
MY.Game.GetHotKey = function(szName, bBracket, bShort)
    if string.sub(szName, 1, 3) ~= "MY_" then
        szName = "MY_" .. szName
    end
    local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
    if nKey==0 then return nil end
    if bBracket then
        return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
    else
        return nKey, bShift, bCtrl, bAlt
    end
end
--[[ 设置快捷键/打开快捷键设置面板    -- HM里面抠出来的
    (void) MY.SetHotKey()                               -- 打开快捷键设置面板
    (void) MY.SetHotKey(string szGroup)     -- 打开快捷键设置面板并定位到 szGroup 分组（不可用）
    (void) MY.SetHotKey(string szCommand, number nKey )     -- 设置快捷键
    (void) MY.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- 设置快捷键
]]
MY.Game.SetHotKey = function(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
    if nIndex then
        if string.sub(szCommand, 1, 3) ~= "MY_" then
            szCommand = "MY_" .. szCommand
        end
        if not nKey then nIndex, nKey = 1, nIndex end
        Hotkey.Set(szCommand, nIndex, nKey, bShift == true, bCtrl == true, bAlt == true)
    else
        local szGroup = szCommand or MY.GetAddonInfo().szName

        local frame = Station.Lookup("Topmost/HotkeyPanel")
        if not frame then
            frame = Wnd.OpenWindow("HotkeyPanel")
        elseif not frame:IsVisible() then
            frame:Show()
        end
        if not szGroup then return end
        -- load aKey
        local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
        for k, v in pairs(bindings) do
            if v.szHeader ~= "" then
                if aKey then
                    break
                elseif v.szHeader == szGroup then
                    aKey = {}
                else
                    nI = nI + 1
                end
            end
            if aKey then
                if not v.Hotkey1 then
                    v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
                end
                if not v.Hotkey2 then
                    v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
                end
                table.insert(aKey, v)
            end
        end
        if not aKey then return end
        local hP = frame:Lookup("", "Handle_List")
        local hI = hP:Lookup(nI)
        if hI.bSel then return end
        -- update list effect
        for i = 0, hP:GetItemCount() - 1 do
            local hB = hP:Lookup(i)
            if hB.bSel then
                hB.bSel = false
                if hB.IsOver then
                    hB:Lookup("Image_Sel"):SetAlpha(128)
                    hB:Lookup("Image_Sel"):Show()
                else
                    hB:Lookup("Image_Sel"):Hide()
                end
            end
        end
        hI.bSel = true
        hI:Lookup("Image_Sel"):SetAlpha(255)
        hI:Lookup("Image_Sel"):Show()
        -- update content keys [hI.nGroupIndex]
        local hK = frame:Lookup("", "Handle_Hotkey")
        local szIniFile = "UI/Config/default/HotkeyPanel.ini"
        Hotkey.SetCapture(false)
        hK:Clear()
        hK.nGroupIndex = hI.nGroupIndex
        hK:AppendItemFromIni(szIniFile, "Text_GroupName")
        hK:Lookup(0):SetText(szGroup)
        hK:Lookup(0).bGroup = true
        for k, v in ipairs(aKey) do
            hK:AppendItemFromIni(szIniFile, "Handle_Binding")
            local hI = hK:Lookup(k)
            hI.bBinding = true
            hI.nIndex = k
            hI.szTip = v.szTip
            hI:Lookup("Text_Name"):SetText(v.szDesc)
            for i = 1, 2, 1 do
                local hK = hI:Lookup("Handle_Key"..i)
                hK.bKey = true
                hK.nIndex = i
                local hotkey = v["Hotkey"..i]
                hotkey.bUnchangeable = v.bUnchangeable
                hK.bUnchangeable = v.bUnchangeable
                local text = hK:Lookup("Text_Key"..i)
                text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
                -- update btn
                if hK.bUnchangeable then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
                elseif hK.bDown then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
                elseif hK.bRDown then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
                elseif hK.bSel then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
                elseif hK.bOver then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
                elseif hotkey.bChange then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
                elseif hotkey.bConflict then
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
                else
                    hK:Lookup("Image_Key"..hK.nIndex):SetFrame(53)
                end
            end
        end
        -- update content scroll
        hK:FormatAllItemPos()
        local wAll, hAll = hK:GetAllItemSize()
        local w, h = hK:GetSize()
        local scroll = frame:Lookup("Scroll_Key")
        local nCountStep = math.ceil((hAll - h) / 10)
        scroll:SetStepCount(nCountStep)
        scroll:SetScrollPos(0)
        if nCountStep > 0 then
            scroll:Show()
            scroll:GetParent():Lookup("Btn_Up"):Show()
            scroll:GetParent():Lookup("Btn_Down"):Show()
        else
            scroll:Hide()
            scroll:GetParent():Lookup("Btn_Up"):Hide()
            scroll:GetParent():Lookup("Btn_Down"):Hide()
        end
        -- update list scroll
        local scroll = frame:Lookup("Scroll_List")
        if scroll:GetStepCount() > 0 then
            local _, nH = hI:GetSize()
            local nStep = math.ceil((nI * nH) / 10)
            if nStep > scroll:GetStepCount() then
                nStep = scroll:GetStepCount()
            end
            scroll:SetScrollPos(nStep)
        end
    end
end

MY.RegisterInit(function()
    -- hotkey
    Hotkey.AddBinding("MY_Total", _L["Open/Close main panel"], MY.GetAddonInfo().szName, MY.TogglePanel, nil)
    for _, v in ipairs(_Cache.tHotkey) do
        Hotkey.AddBinding(v.szName, v.szTitle, "", v.fnAction, nil)
    end
    for i = 1, 5 do
        Hotkey.AddBinding('MY_HotKey_Null_'..i, _L['none-function hotkey'], "", function() end, nil)
    end
end)
--[[
#######################################################################################################
                                #                   # # # #   # # # #     
    # # # #   # # # # #       # # # # # # #         #     #   #     #     
    #     #   #       #     #   #       #           # # # #   # # # #     
    #     #   #       #           # # #                     #     #       
    # # # #   #   # #         # #       # #                 #       #     
    #     #   #           # #     #         # #   # # # # # # # # # # #   
    #     #   # # # # #           #                       #   #           
    # # # #   #   #   #     # # # # # # # #           # #       # #       
    #     #   #   #   #         #         #       # #               # #   
    #     #   #     #           #         #         # # # #   # # # #     
    #     #   #   #   #       #           #         #     #   #     #     
  #     # #   # #     #     #         # #           # # # #   # # # #     
#######################################################################################################
]]
--[[ 获取当前服务器
]]
MY.Game.GetServer = function()
    return table.concat({GetUserServer()},'_'), {GetUserServer()}
end

--[[ 获取指定对象的名字
]]
MY.Game.GetObjectName = function(tar)
    local szName = tar.szName
    if IsPlayer(tar.dwID) then
        return szName
    else
        if szName == "" then
            szName = string.gsub(Table_GetNpcTemplateName(tar.dwTemplateID), "^%s*(.-)%s*$", "%1")
            if szName == "" then
                szName = tar.dwID
            end
        end
        if tar.dwEmployer and tar.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(tar.dwTemplateID) then
            local emp = GetPlayer(tar.dwEmployer)
            if not emp then
                szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
            else
                szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
            end
        end
        return szName
    end
end
MY.GetObjectName = MY.Game.GetObjectName