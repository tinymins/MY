---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
MY = MY or {}
MY.Chat = MY.Chat or {}
local _Cache, _L = {}, MY.LoadLangPack()

-- 海鳗里面抠出来的
-- 聊天复制并发布
MY.Chat.RepeatChatLine = function(hTime)
    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
    if not edit then
        return
    end
    MY.Chat.CopyChatLine(hTime)
    local tMsg = edit:GetTextStruct()
    if #tMsg == 0 then
        return
    end
    local nChannel, szName = EditBox_GetChannel()
    if MY.CanTalk(nChannel) then
        GetClientPlayer().Talk(nChannel, szName or "", tMsg)
        edit:ClearText()
    end
end

-- 聊天表情初始化
MY.Chat.InitFaceIcon = function()
    if not _Cache.tFacIcon then
        local t = { image = {}, animate = {} }
        for i = 1, g_tTable.FaceIcon:GetRowCount() do
            local tLine = g_tTable.FaceIcon:GetRow(i)
            if tLine.szType == "animate" then
                t.animate[tLine.nFrame] = { szCmd = tLine.szCommand, dwID = tLine.dwID }
            else
                t.image[tLine.nFrame] = { szCmd = tLine.szCommand, dwID = tLine.dwID }
            end
        end
        _Cache.tFacIcon = t
    end
end

-- 复制聊天行
MY.Chat.CopyChatLine = function(hTime)
    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
    if not edit then
        return
    end
    edit:ClearText()
    local h, i, bBegin = hTime:GetParent(), hTime:GetIndex(), nil
    -- loop
    MY.Chat.InitFaceIcon()
    for i = i + 1, h:GetItemCount() - 1 do
        local p = h:Lookup(i)
        if p:GetType() == "Text" then
            local szName = p:GetName()
            if szName ~= "timelink" and szName ~= "copylink" and szName ~= "msglink" and szName ~= "time" then
                local szText, bEnd = p:GetText(), false
                if StringFindW(szText, "\n") then
                    szText = StringReplaceW(szText, "\n", "")
                    bEnd = true
                end
                if szName == "itemlink" then
                    edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
                elseif szName == "iteminfolink" then
                    edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
                elseif string.sub(szName, 1, 8) == "namelink" then
                    if bBegin == nil then
                        bBegin = false
                    end
                    edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
                elseif szName == "questlink" then
                    edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
                elseif szName == "recipelink" then
                    edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
                elseif szName == "enchantlink" then
                    edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
                elseif szName == "skilllink" then
                    local o = clone(p.skillKey)
                    o.type, o.text = "skill", szText
                    edit:InsertObj(szText, o)
                elseif szName =="skillrecipelink" then
                    edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
                elseif szName =="booklink" then
                    edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
                elseif szName =="achievementlink" then
                    edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
                elseif szName =="designationlink" then
                    edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
                elseif szName =="eventlink" then
                    edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
                else
                    -- NPC 喊话特殊处理
                    if bBegin == nil then
                        local r, g, b = p:GetFontColor()
                        if r == 255 and g == 150 and b == 0 then
                            bBegin = false
                        end
                    end
                    if bBegin == false then
                        for _, v in ipairs({g_tStrings.STR_TALK_HEAD_WHISPER, g_tStrings.STR_TALK_HEAD_SAY, g_tStrings.STR_TALK_HEAD_SAY1, g_tStrings.STR_TALK_HEAD_SAY2 }) do
                            local nB, nE = StringFindW(szText, v)
                            if nB then
                                szText, bBegin = string.sub(szText, nB + nE), true
                                edit:ClearText()
                            end
                        end
                    end
                    if szText ~= "" and (table.getn(edit:GetTextStruct()) > 0 or szText ~= g_tStrings.STR_FACE) then
                        edit:InsertText(szText)
                    end
                end
                if bEnd then
                    break
                end
            end
        elseif p:GetType() == "Image" then
            local nFrame = p:GetFrame()
            local tEmotion = _Cache.tFacIcon.image[nFrame]
            if tEmotion then
                edit:InsertObj(tEmotion.szCmd, { type = "emotion", text = tEmotion.szCmd, id = tEmotion.dwID })
            end
        elseif p:GetType() == "Animate" then
            local nGroup = tonumber(p:GetName())
            if nGroup then
                local tEmotion = _Cache.tFacIcon.animate[nGroup]
                if tEmotion then
                    edit:InsertObj(tEmotion.szCmd, { type = "emotion", text = tEmotion.szCmd, id = tEmotion.dwID })
                end
            end
        end
    end
    Station.SetFocusWindow(edit)
end

-- 复制Item到输入框
MY.Chat.CopyChatItem = function(p)
    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
    if not edit then
        return
    end
    if p:GetType() == "Text" then
        local szText, szName = p:GetText(), p:GetName()
        if szName == "itemlink" then
            edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
        elseif szName == "iteminfolink" then
            edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
        elseif string.sub(szName, 1, 8) == "namelink" then
            if bBegin == nil then
                bBegin = false
            end
            edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
        elseif szName == "questlink" then
            edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
        elseif szName == "recipelink" then
            edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
        elseif szName == "enchantlink" then
            edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
        elseif szName == "skilllink" then
            local o = clone(p.skillKey)
            o.type, o.text = "skill", szText
            edit:InsertObj(szText, o)
        elseif szName =="skillrecipelink" then
            edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
        elseif szName =="booklink" then
            edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
        elseif szName =="achievementlink" then
            edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
        elseif szName =="designationlink" then
            edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
        elseif szName =="eventlink" then
            edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
        end
        Station.SetFocusWindow(edit)
    end
end

--解析消息
MY.Chat.FormatContent = function(szMsg)
    local t = {}
    for w in string.gfind(szMsg, "<text>text=(.-)</text>") do
        if w then
            table.insert(t, w)
        end
    end
    --Output(t)
    local t2 = {}
    for k, v in pairs(t) do
        if not string.find(v, "name=") then
            if string.find(v, "frame=") then
                local n = string.match(v, "frame=(%d+)")
                local szCmd, nFaceID = ChatPanel.GetFaceCommand("image", tonumber(n))
                table.insert(t2, {type = "faceicon", text = szCmd, nFaceID = nFaceID})
            elseif string.find(v, "group=") then
                local n = string.match(v, "group=(%d+)")
                local szCmd, nFaceID = ChatPanel.GetFaceCommand("animate", tonumber(n))
                table.insert(t2, {type = "faceicon", text = szCmd, nFaceID = nFaceID})
            else
                local s = string.match(v, "\"(.-)\"")
                if string.find(s, "：") then
                    s = string.sub(s, string.find(s, "：") + 2, -1)
                end
                table.insert(t2, {type= "text", text = s})
            end
        else
            --物品链接
            if string.find(v, "name=\"itemlink\"") then
                local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "item", text = name, item = userdata}})
            --物品信息
            elseif string.find(v, "name=\"iteminfolink\"") then
                local name, version, tab, index = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\this.dwTabType=(%d+)\\this.dwIndex=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "iteminfo", text = name, version = version, tabtype = tab, index = index}})
            --姓名
            elseif string.find(v, "name=\"namelink\"") then
                local name = string.match(v,"%[(.-)%]")
                table.insert(t2, {"["..name.."]", {type = "name", text = "["..name.."]", name = name}})
            --任务
            elseif string.find(v, "name=\"questlink\"") then
                local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "quest", text = name, questid = userdata}})
            --生活技艺
            elseif string.find(v, "name=\"recipelink\"") then
                local name, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\this.dwRecipeID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "recipe", text = name, craftid = craft, recipeid = recipe}})
            --技能
            elseif string.find(v, "name=\"skilllink\"") then
                local name, skillinfo = string.match(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
                local skillKey = {}
                for w in string.gfind(skillinfo, "(.-)%,") do
                    local k, v  = string.match(w, "(.-)=(%w+)")
                    skillKey[k] = v
                end
                table.insert(t2, {"["..name.."]", skillKey})
            --称号
            elseif string.find(v, "name=\"designationlink\"") then
                local name, id, fix = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\this.bPrefix=(.-)")
                table.insert(t2, {"["..name.."]", {type = "designation", text = name, id = id, prefix = fix}})
            --技能秘籍
            elseif string.find(v, "name=\"skillrecipelink\"") then
                local name, id, level = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\this.dwLevel=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "skillrecipe", text = name, id = id, level = level}})
            --书籍
            elseif string.find(v, "name=\"booklink\"") then
                local name, version, tab, index, id = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\this.dwTabType=(%d+)\\this.dwIndex=(%d+)\\this.nBookRecipeID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "book", text = name, version = version, tabtype = tab, index = index, bookinfo = id}})
            --成就
            elseif string.find(v, "name=\"achievementlink\"") then
                local name, id = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "achievement", text = name, id = id}})
            --强化
            elseif string.find(v, "name=\"enchantlink\"") then
                local name, pro, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\this.dwCraftID=(%d+)\\this.dwRecipeID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "enchant", text = name, proid = pro, craftid = craft, recipeid = recipe}})
            --事件
            elseif string.find(v, "name=\"eventlink\"") then
                local name, na, info = string.match(v,"%[(.-)%].-script=\"this.szName=\"(.-)\"\\this.szLinkInfo=\"(.-)\"")
                table.insert(t2, {"["..name.."]", {type = "eventlink", text = name, name = na, linkinfo = info or ""}})
            end
        end
    end
    return t2
end
