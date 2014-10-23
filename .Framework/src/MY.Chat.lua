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
MY.Chat.bHookedAlready = false
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
_Cache.InitEmotion = function()
    if not _Cache.tEmotion then
        local t = {}
        for i = 1, g_tTable.FaceIcon:GetRowCount() do
            local tLine = g_tTable.FaceIcon:GetRow(i)
            t[tLine.dwID] = {
                nFrame = tLine.nFrame,
                dwID   = tLine.dwID,
                szCmd  = tLine.szCommand,
                szType = tLine.szType,
                szImageFile = tLine.szImageFile
            }
            t[tLine.szCommand] = t[tLine.dwID]
            t[tLine.szImageFile..','..tLine.nFrame..','..tLine.szType] = t[tLine.dwID]
        end
        _Cache.tEmotion = t
    end
end

--[[ 获取聊天表情列表
    typedef emo table
    (emo[]) MY.Chat.GetEmotion()                             -- 返回所有表情列表
    (emo)   MY.Chat.GetEmotion(szCommand)                    -- 返回指定Cmd的表情
    (emo)   MY.Chat.GetEmotion(szImageFile, nFrame, szType)  -- 返回指定图标的表情
]]
MY.Chat.GetEmotion = function(arg0, arg1, arg2)
    _Cache.InitEmotion()
    local t
    if not arg0 then
        t = _Cache.tEmotion
    elseif not arg1 then
        t = _Cache.tEmotion[arg0]
    elseif arg2 then
        arg0 = string.gsub(arg0, '\\\\', '\\')
        t = _Cache.tEmotion[arg0..','..arg1..','..arg2]
    end
    return clone(t)
end

-- 获取复制聊天行Text
MY.Chat.GetCopyLinkText = function(szText, rgbf)
    szText = szText or _L[' * ']
    rgbf   = rgbf   or { f = 10 }
    
    return GetFormatText(szText, rgbf.f, rgbf.r, rgbf.g, rgbf.b, 515,
        "this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end",
        "copylink")
end

-- 获取复制聊天行Text
MY.Chat.GetTimeLinkText = function(rgbf)
    rgbf = rgbf or { f = 10 }
    
    local t =TimeToDate(GetCurrentTime())
    return GetFormatText(string.format("[%02d:%02d.%02d]", t.hour, t.minute, t.second), rgbf.f, rgbf.r, rgbf.g, rgbf.b, 515,
        "this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end",
        "timelink")
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
        elseif p:GetType() == "Image" or p:GetType() == "Animate" then
            local dwID = tonumber(p:GetName())
            if dwID then
                local emo = MY.Chat.GetEmotion(dwID)
                if emo then
                    edit:InsertObj(emo.szCmd, { type = "emotion", text = emo.szCmd, id = emo.dwID })
                end
            end
        end
    end
    Station.SetFocusWindow(edit)
end

MY.Chat.LinkEventHandler = {
    OnNameLClick = function()
        if IsCtrlKeyDown() then
            MY.Chat.CopyChatItem(this)
        else
            MY.SwitchChat(MY.UI(this):text())
            local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
            if edit then
                Station.SetFocusWindow(edit)
            end
        end
    end,
    OnNameRClick = function()
        PopupMenu((function()
            local t = {}
            local szName = MY.UI(this):text():gsub('[%[%]]', '')
            table.insert(t, {
                szOption = _L['copy'],
                fnAction = function()
                    MY.Talk(GetClientPlayer().szName, '[' .. szName .. ']')
                end,
            })
            -- table.insert(t, {
            --     szOption = _L['whisper'],
            --     fnAction = function()
            --         MY.SwitchChat(szName)
            --     end,
            -- })
            pcall(InsertPlayerCommonMenu, t, nil, szName)
            if MY_Farbnamen then
                local tInfo = MY_Farbnamen.GetAusName(szName)
                if tInfo then
                    local dwID = tonumber(tInfo.dwID)
                    if GetClientPlayer().dwID ~= dwID then
                        table.insert(t, {
                            szOption = _L['show equipment'],
                            fnAction = function()
                                ViewInviteToPlayer(dwID)
                            end,
                        })
                    end
                end
            end
            pcall(InsertInviteTeamMenu, t, szName)
            return t
        end)())
    end,
    OnCopyLClick = function()
        MY.Chat.CopyChatLine(this)
    end,
    OnCopyRClick = function()
        MY.Chat.RepeatChatLine(this)
    end,
    OnItemLClick = function()
        OnItemLinkDown(this)
    end,
    OnItemRClick = function()
        if IsCtrlKeyDown() then
            MY.Chat.CopyChatItem(this)
        end
    end,
}
--[[ 绑定link事件响应
    (userdata) MY.Chat.RenderLink(userdata link)    处理link的各种事件绑定 namelink是一个超链接Text元素
    (string) MY.Chat.RenderLink(string szMsg)       格式化szMsg 处理里面的超链接 添加时间相应
]]
MY.Chat.RenderLink = function(argv)
    if type(argv) == 'string' then
        local szMsg = argv
        szMsg = string.gsub(szMsg, "(<text>.-</text>)", function (html)
            local xml = MY.Xml.Decode(html)
            if not (xml and xml[1] and xml[1][''] and xml[1][''].name) then
                return
            end
            
            local name, script = xml[1][''].name, xml[1][''].script
            if script then
                script = script .. '\n'
            else
                script = ''
            end
            
            if name:sub(1, 8) == 'namelink' then
                script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.Chat.LinkEventHandler.OnNameLClick\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnNameRClick'
            elseif name == 'copy' or name == 'copylink' or name == 'timelink' then
                script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end'
            else
                script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=function() MY.Chat.LinkEventHandler.OnItemLClick(this) end\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnItemRClick'
            end
            
            if #script > 0 then
                xml[1][''].eventid = 883
                xml[1][''].script = script
            end
            html = MY.Xml.Encode(xml)
            
            return html
        end)
        argv = szMsg
    elseif type(argv) == 'table' and type(argv.GetName) == 'function' then
        if argv.bMyChatRendered then
            return
        end
        local link = MY.UI(argv)
        local name = link:name()
        if name:sub(1, 8) == 'namelink' then
            link:click(MY.Chat.LinkEventHandler.OnNameLClick, MY.Chat.LinkEventHandler.OnNameRClick)
        elseif name == 'copy' or name == 'copylink' then
            link:click(MY.Chat.LinkEventHandler.OnCopyLClick, MY.Chat.LinkEventHandler.OnCopyRClick)
        else
            link:click(MY.Chat.LinkEventHandler.OnItemLClick, MY.Chat.LinkEventHandler.OnItemRClick)
        end
        argv.bMyChatRendered = true
    end
    
    return argv
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
    for n, w in string.gfind(szMsg, "<(%w+)>(.-)</%1>") do
        if w then
            table.insert(t, w)
        end
    end
    -- Output(t)
    local t2 = {}
    for k, v in pairs(t) do
        if not string.find(v, "name=") then
            if string.find(v, "frame=") then
                local n = string.match(v, "frame=(%d+)")
                local p = string.match(v, 'path="(.-)"')
                local emo = MY.Chat.GetEmotion(p, n, 'image')
                if emo then
                    table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
                end
            elseif string.find(v, "group=") then
                local n = string.match(v, "group=(%d+)")
                local p = string.match(v, 'path="(.-)"')
                local emo = MY.Chat.GetEmotion(p, n, 'animate')
                if emo then
                    table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
                end
            else
                --普通文字
                local s = string.match(v, "\"(.*)\"")
                table.insert(t2, {type= "text", text = s, innerText = s})
            end
        else
            --物品链接
            if string.find(v, "name=\"itemlink\"") then
                local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
                table.insert(t2, {type = "item", text = "["..name.."]", innerText = name, item = userdata})
            --物品信息
            elseif string.find(v, "name=\"iteminfolink\"") then
                local name, version, tab, index = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)")
                table.insert(t2, {type = "iteminfo", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index})
            --姓名
            elseif string.find(v, "name=\"namelink_%d+\"") then
                local name = string.match(v,"%[(.-)%]")
                table.insert(t2, {type = "name", text = "["..name.."]", innerText = "["..name.."]", name = name})
            --任务
            elseif string.find(v, "name=\"questlink\"") then
                local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
                table.insert(t2, {type = "quest", text = "["..name.."]", innerText = name, questid = userdata})
            --生活技艺
            elseif string.find(v, "name=\"recipelink\"") then
                local name, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
                table.insert(t2, {type = "recipe", text = "["..name.."]", innerText = name, craftid = craft, recipeid = recipe})
            --技能
            elseif string.find(v, "name=\"skilllink\"") then
                local name, skillinfo = string.match(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
                local skillKey = {}
                for w in string.gfind(skillinfo, "(.-)%,") do
                    local k, v  = string.match(w, "(.-)=(%w+)")
                    skillKey[k] = v
                end
                skillKey.text = "["..name.."]"
                skillKey.innerText = "["..name.."]"
                table.insert(t2, skillKey)
            --称号
            elseif string.find(v, "name=\"designationlink\"") then
                local name, id, fix = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.bPrefix=(.-)")
                table.insert(t2, {type = "designation", text = "["..name.."]", innerText = name, id = id, prefix = fix})
            --技能秘籍
            elseif string.find(v, "name=\"skillrecipelink\"") then
                local name, id, level = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.dwLevel=(%d+)")
                table.insert(t2, {type = "skillrecipe", text = "["..name.."]", innerText = name, id = id, level = level})
            --书籍
            elseif string.find(v, "name=\"booklink\"") then
                local name, version, tab, index, id = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)\\%s*this.nBookRecipeID=(%d+)")
                table.insert(t2, {type = "book", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index, bookinfo = id})
            --成就
            elseif string.find(v, "name=\"achievementlink\"") then
                local name, id = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
                table.insert(t2, {type = "achievement", text = "["..name.."]", innerText = name, id = id})
            --强化
            elseif string.find(v, "name=\"enchantlink\"") then
                local name, pro, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\%s*this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
                table.insert(t2, {type = "enchant", text = "["..name.."]", innerText = name, proid = pro, craftid = craft, recipeid = recipe})
            --事件
            elseif string.find(v, "name=\"eventlink\"") then
                local name, na, info = string.match(v,"%[(.-)%].-script=\"this.szName=\"(.-)\"\\%s*this.szLinkInfo=\"(.-)\"")
                table.insert(t2, {type = "eventlink", text = "["..name.."]", innerText = name, name = na, linkinfo = info or ""})
            end
        end
    end
    return t2
end

--[[ 判断某个频道能否发言
-- (bool) MY.CanTalk(number nChannel)]]
MY.Chat.CanTalk = function(nChannel)
    for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
        if nChannel == PLAYER_TALK_CHANNEL[v] then
            return true
        end
    end
    return false
end
MY.CanTalk = MY.Chat.CanTalk

-- get channel header
_Cache.tTalkChannelHeader = {
    [PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
    [PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
    [PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
    [PLAYER_TALK_CHANNEL.TEAM] = "/p ",
    [PLAYER_TALK_CHANNEL.RAID] = "/t ",
    [PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
    [PLAYER_TALK_CHANNEL.TONG] = "/g ",
    [PLAYER_TALK_CHANNEL.SENCE] = "/y ",
    [PLAYER_TALK_CHANNEL.FORCE] = "/f ",
    [PLAYER_TALK_CHANNEL.CAMP] = "/c ",
    [PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}
--[[ 切换聊天频道
    (void) MY.SwitchChat(number nChannel)
    (void) MY.SwitchChat(string szHeader)
    (void) MY.SwitchChat(string szName)
]]
MY.Chat.SwitchChat = function(nChannel)
    local szHeader = _Cache.tTalkChannelHeader[nChannel]
    if szHeader then
        SwitchChatChannel(szHeader)
    elseif type(nChannel) == "string" then
        if string.sub(nChannel, 1, 1) == "/" then
            SwitchChatChannel(nChannel.." ")
        else
            SwitchChatChannel("/w " .. string.gsub(nChannel,'[%[%]]','') .. " ")
        end
    end
end
MY.SwitchChat = MY.Chat.SwitchChat


-- parse faceicon in talking message
MY.Chat.ParseFaceIcon = function(t)
    local t2 = {}
    for _, v in ipairs(t) do
        if v.type ~= "text" then
            if v.type == "emotion" then
                v.type = "text"
            end
            table.insert(t2, v)
        else
            local nOff, nLen = 1, string.len(v.text)
            while nOff <= nLen do
                local szFace, dwFaceID = nil, nil
                local nPos = StringFindW(v.text, "#", nOff)
                if not nPos then
                    nPos = nLen
                else
                    for i = nPos + 6, nPos + 2, -2 do
                        if i <= nLen then
                            local szTest = string.sub(v.text, nPos, i)
                            local emo = MY.Chat.GetEmotion(szTest)
                            if emo then
                                szFace, dwFaceID = szTest, emo.dwID
                                nPos = nPos - 1
                                break
                            end
                        end
                    end
                end
                if nPos >= nOff then
                    table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos) })
                    nOff = nPos + 1
                end
                if szFace then
                    table.insert(t2, { type = "emotion", text = szFace, id = dwFaceID })
                    nOff = nOff + string.len(szFace)
                end
            end
        end
    end
    return t2
end
-- parse name in talking message
MY.Chat.ParseName = function(t)
    local t2 = {}
    for _, v in ipairs(t) do
        if v.type ~= "text" then
            if v.type == "name" then
                v = { type = "text", text = "["..v.name.."]" }
            end
            table.insert(t2, v)
        else
            local nOff, nLen = 1, string.len(v.text)
            while nOff <= nLen do
                local szName = nil
                local nPos1, nPos2 = string.find(v.text, '%[[^%[%]]+%]', nOff)
                if not nPos1 then
                    nPos1 = nLen
                else
                    szName = string.sub(v.text, nPos1 + 1, nPos2 - 1)
                    nPos1 = nPos1 - 1
                end
                if nPos1 >= nOff then
                    table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos1) })
                    nOff = nPos1 + 1
                end
                if szName then
                    table.insert(t2, { type = "name", name = szName })
                    nOff = nPos2 + 1
                end
            end
        end
    end
    return t2
end
--[[ 发布聊天内容
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape])
-- szTarget         -- 密聊的目标角色名
-- szText               -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- nChannel         -- *可选* 聊天频道，PLAYER_TALK_CHANNLE.*，默认为近聊
-- bNoEscape    -- *可选* 不解析聊天内容中的表情图片和名字，默认为 false
-- bSaveDeny    -- *可选* 在聊天输入栏保留不可发言的频道内容，默认为 false
-- 特别注意：nChannel, szText 两者的参数顺序可以调换，战场/团队聊天频道智能切换]]
MY.Chat.Talk = function(nChannel, szText, bNoEscape, bSaveDeny)
    local szTarget, me = "", GetClientPlayer()
    -- channel
    if not nChannel then
        nChannel = PLAYER_TALK_CHANNEL.NEARBY
    elseif type(nChannel) == "string" then
        if not szText then
            szText = nChannel
            nChannel = PLAYER_TALK_CHANNEL.NEARBY
        elseif type(szText) == "number" then
            szText, nChannel = nChannel, szText
        else
            szTarget = nChannel
            nChannel = PLAYER_TALK_CHANNEL.WHISPER
        end
    elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
        nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
    elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
        return MY.Sysmsg({szText}, '')
    end
    -- say body
    local tSay = nil
    if type(szText) == "table" then
        tSay = szText
    else
        local tar = MY.GetObject(me.GetTarget())
        szText = string.gsub(szText, "%$zj", '['..me.szName..']')
        if tar then
            szText = string.gsub(szText, "%$mb", '['..tar.szName..']')
        end
        tSay = {{ type = "text", text = szText .. "\n"}}
    end
    if not bNoEscape then
        tSay = MY.Chat.ParseFaceIcon(tSay)
        tSay = MY.Chat.ParseName(tSay)
    end
    if not MY.Chat.bHookedAlready then
        local nLen = 0
        for i, v in ipairs(tSay) do
            if nLen <= 64 then
                nLen = nLen + MY.String.LenW(v.text or v.name or '')
                if nLen > 64 then
                    if v.text then v.text = MY.String.SubW(v.text, 1, 64 - nLen ) end
                    if v.name then v.name = MY.String.SubW(v.name, 1, 64 - nLen ) end
                    for j=#tSay, i+1, -1 do
                        table.remove(tSay, j)
                    end
                end
            end
        end
    end
    me.Talk(nChannel, szTarget, tSay)
    if bSaveDeny and not MY.CanTalk(nChannel) then
        local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
        edit:ClearText()
        for _, v in ipairs(tSay) do
            if v.type == "text" then
                edit:InsertText(v.text)
            else
                edit:InsertObj(v.text, v)
            end
        end
        -- change to this channel
        MY.SwitchChat(nChannel)
    end
end
MY.Talk = MY.Chat.Talk

_Cache.tHookChatFun = {}
--[[ HOOK聊天栏 ]]
MY.Chat.HookChatPanel = function(arg0, arg1, arg2)
    local fnBefore, fnAfter, id
    if type(arg0)=="string" then
        id, fnBefore, fnAfter = arg0, arg1, arg2
    elseif type(arg1)=="string" then
        id, fnBefore, fnAfter = arg1, arg0, arg2
    elseif type(arg2)=="string" then
        id, fnBefore, fnAfter = arg2, arg0, arg1
    else
        id, fnBefore, fnAfter = nil, arg0, arg1
    end
    if type(fnBefore)~="function" and type(fnAfter)~="function" then
        return nil
    end
    if id then
        for i=#_Cache.tHookChatFun, 1, -1 do
            if _Cache.tHookChatFun[i].id == id then
                table.remove(_Cache.tHookChatFun, i)
            end
        end
    end
    if fnBefore then
        table.insert(_Cache.tHookChatFun, {fnBefore = fnBefore, fnAfter = fnAfter, id = id})
    end
end
MY.HookChatPanel = MY.Chat.HookChatPanel

_Cache.HookChatPanelHandle = function(h, szMsg)
    -- add name to emotion icon
    szMsg = string.gsub(szMsg, "<animate>.-path=\"(.-)\"(.-)group=(%d+).-</animate>", function (szImagePath, szExtra, szGroup)
        local emo = MY.Chat.GetEmotion(szImagePath, szGroup, 'animate')
        if emo then
            return '<animate>path="'..szImagePath..'"'..szExtra..'group='..szGroup..' name="'..emo.dwID..'"</animate>'
        end
    end)
    szMsg = string.gsub(szMsg, "<image>.-path=\"(.-)\"(.-)frame=(%d+).-</image>", function (szImagePath, szExtra, szFrame)
        local emo = MY.Chat.GetEmotion(szImagePath, szFrame, 'image')
        if emo then
            return '<image>path="'..szImagePath..'"'..szExtra..'frame='..szFrame..' name="'..emo.dwID..'"</image>'
        end
    end)
    -- deal with fnBefore
    for i,handle in ipairs(_Cache.tHookChatFun) do
        -- try to execute fnBefore and get return values
        local result = { pcall(handle.fnBefore, h, szMsg) }
        -- when fnBefore execute succeed
        if result[1] then
            -- remove execute status flag
            table.remove(result, 1)
            if type(result[1])=="string" then
                szMsg = result[1]
            end
            -- remove returned szMsg
            table.remove(result, 1)
        end
        -- the rest is fnAfter param
        _Cache.tHookChatFun[i].param = result
    end
    -- call ori append
    h:_AppendItemFromString_MY(szMsg)
    -- deal with fnAfter
    for i,handle in ipairs(_Cache.tHookChatFun) do
        pcall(handle.fnAfter, h, szMsg, unpack(handle.param))
    end
end
MY.RegisterEvent("CHAT_PANEL_INIT", function ()
    for i = 1, 10 do
        local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
        local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
        if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
            h._AppendItemFromString_MY = h._AppendItemFromString_MY or h.AppendItemFromString
            h.AppendItemFromString = _Cache.HookChatPanelHandle
        end
    end
end)
MY.RegisterInit(function()
    if Station.Lookup("Lowest2/ChatPanel1/Wnd_Message").bMyHooked then
        MY.Chat.bHookedAlready = true
    else
        MY.Chat.bHookedAlready = false
    end
    Station.Lookup("Lowest2/ChatPanel1/Wnd_Message").bMyHooked = true   
end)