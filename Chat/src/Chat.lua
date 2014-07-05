local _L = MY.LoadLangPack("Interface/MY/Chat/lang/")
local CHAT_TIME = {
    HOUR_MIN = 1,
    HOUR_MIN_SEC = 2,
}
-- init vars
MY_Chat = MY_Chat or {}
local _Cache = {
    ['tChannels'] = {
        {name="Radio_Say",      title=_L["SAY"],      head={string=g_tStrings.HEADER_SHOW_SAY,          code="/s "}, channel=PLAYER_TALK_CHANNEL.NEARBY       , color={255, 255, 255}},--说
        {name="Radio_Map",      title=_L["MAP"],      head={string=g_tStrings.HEADER_SHOW_MAP,          code="/y "}, channel=PLAYER_TALK_CHANNEL.SENCE        , color={255, 126, 126}},--地
        {name="Radio_World",    title=_L["WORLD"],    head={string=g_tStrings.HEADER_SHOW_WORLD,        code="/h "}, channel=PLAYER_TALK_CHANNEL.WORLD        , color={252, 204, 204}},--世
        {name="Radio_Party",    title=_L["PARTY"],    head={string=g_tStrings.HEADER_SHOW_CHAT_PARTY,   code="/p "}, channel=PLAYER_TALK_CHANNEL.TEAM         , color={140, 178, 253}},--队
        {name="Radio_Team",     title=_L["TEAM"],     head={string=g_tStrings.HEADER_SHOW_TEAM,         code="/t "}, channel=PLAYER_TALK_CHANNEL.RAID         , color={ 73, 168, 241}},--团
        {name="Radio_Battle",   title=_L["BATTLE"],   head={string=g_tStrings.HEADER_SHOW_BATTLE_FIELD, code="/b "}, channel=PLAYER_TALK_CHANNEL.BATTLE_FIELD , color={255, 126, 126}},--战
        {name="Radio_Tong",     title=_L["FACTION"],  head={string=g_tStrings.HEADER_SHOW_CHAT_FACTION, code="/g "}, channel=PLAYER_TALK_CHANNEL.TONG         , color={  0, 200,  72}},--帮
        {name="Radio_School",   title=_L["SCHOOL"],   head={string=g_tStrings.HEADER_SHOW_SCHOOL,       code="/f "}, channel=PLAYER_TALK_CHANNEL.FORCE        , color={  0, 255, 255}},--派
        {name="Radio_Camp",     title=_L["CAMP"],     head={string=g_tStrings.HEADER_SHOW_CAMP,         code="/c "}, channel=PLAYER_TALK_CHANNEL.CAMP         , color={155, 230,  58}},--阵
        {name="Radio_Friend",   title=_L["FRIEND"],   head={string=g_tStrings.HEADER_SHOW_FRIEND,       code="/o "}, channel=PLAYER_TALK_CHANNEL.FRIENDS      , color={241, 114, 183}},--友
        {name="Radio_Alliance", title=_L["ALLIANCE"], head={string=g_tStrings.HEADER_SHOW_CHAT_ALLIANCE,code="/a "}, channel=PLAYER_TALK_CHANNEL.TONG_ALLIANCE, color={178, 240, 164}},--盟
    }
}
MY_Chat.bLockPostion = false
MY_Chat.anchor = { x=10, y=-60, s="BOTTOMLEFT", r="BOTTOMLEFT" }
MY_Chat.bEnableBalloon = true
MY_Chat.bChatCopy = true
MY_Chat.bBlockWords = false
MY_Chat.tBlockWords = {}
MY_Chat.bChatTime = true
MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
MY_Chat.tChannel = {
    ["Radio_Say"] = true,
    ["Radio_Map"] = true,
    ["Radio_World"] = true,
    ["Radio_Party"] = true,
    ["Radio_Team"] = true,
    ["Radio_Battle"] = true,
    ["Radio_Tong"] = true,
    ["Radio_School"] = true,
    ["Radio_Camp"] = true,
    ["Radio_Friend"] = true,
    ["Radio_Alliance"] = true,
    ["Check_Away"] = true,
    ["Check_Busy"] = true,
}
-- register settings
RegisterCustomData("Account\\MY_Chat.bLockPostion")
RegisterCustomData("Account\\MY_Chat.postion")
RegisterCustomData("Account\\MY_Chat.bEnableBalloon")
RegisterCustomData("Account\\MY_Chat.bChatCopy")
RegisterCustomData("Account\\MY_Chat.bBlockWords")
RegisterCustomData("Account\\MY_Chat.tBlockWords")
RegisterCustomData("Account\\MY_Chat.bChatTime")
RegisterCustomData("Account\\MY_Chat.nChatTime")
-- Event
-- function ChatPanel.OnEvent(event)
--     if event == "UI_SCALED" then
--         ChatPanel.UpdateAnchor(this)
--     elseif event == "PLAYER_TALK" then
--         if ChatPanel.bEnable then
--             ChatPanel.OnTalk()
--         end
--         if ChatPanel.bChatLog then
--             ChatLog.OnTalk()
--         end
--     elseif event == "PLAYER_SAY" then
--         if ChatPanel.bTalkBalloon then
--             ChatPanel.OnSay()
--         end
--     end
-- end

MY_Chat.OnFrameDragEnd = function() this:CorrectPos() MY_Chat.anchor = GetFrameAnchor(this) end

-- open window
MY_Chat.frame = Wnd.OpenWindow("Interface\\MY\\Chat\\ui\\Chat.ini", "MY_Chat")
-- load settings
MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
MY_Chat.UpdateAnchor = function() MY_Chat.frame:SetPoint(MY_Chat.anchor.s, 0, 0, MY_Chat.anchor.r, MY_Chat.anchor.x, MY_Chat.anchor.y) MY_Chat.frame:CorrectPos() end
MY_Chat.UpdateAnchor()
MY.RegisterEvent( "UI_SCALED", MY_Chat.UpdateAnchor )
-- re init
MY_Chat.ReInitUI = function()
    -- clear
    MY.UI(MY_Chat.frame):find(".WndCheckBox"):remove()
    MY.UI(MY_Chat.frame):find(".WndRadioBox"):remove()
    -- reinit
    local i = 0
    -- init ui
    for _, v in ipairs(_Cache.tChannels) do
        if MY_Chat.tChannel[v.name] then
            i = i + 1
            MY.UI(MY_Chat.frame):append(v.name,"WndRadioBox"):child("#"..v.name):width(20):text(v.title):font(197):color(v.color):pos(i*30+15,25):check(function()
                -- Switch Chat Channel Here
                MY.SwitchChat(v.channel)
                Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
                MY.UI(this):check(false)
            end):find(".Text"):pos(4,-18):width(20)
        end
    end
    
    i = i + 1
    MY.UI(MY_Chat.frame):append("Check_Away","WndCheckBox"):child("#Check_Away"):width(25):text(_L["AWAY"]):pos(i*30+15,25):check(function()
        MY.SwitchChat("/afk")
    end, function()
        MY.SwitchChat("/cafk")
    end):find(".Text"):pos(5,-16):width(25):font(197)
    
    i = i + 1
    MY.UI(MY_Chat.frame):append("Check_Busy","WndCheckBox"):child("#Check_Busy"):width(25):text(_L["BUSY"]):pos(i*30+15,25):check(function()
        MY.SwitchChat("/atr")
    end, function()
        MY.SwitchChat("/catr")
    end):find(".Text"):pos(5,-16):width(25):font(197)
    
end
-- init
MY.RegisterInit(function()
    MY_Chat.ReInitUI()
    
    MY.UI(MY_Chat.frame):child("#Btn_Option"):menu(function()
        local t = {
            {
                szOption = _L["about..."]
            }, {
                bDevide = true
            }, {
                szOption = _L["lock postion"],
                bCheck = true,
                bChecked = MY_Chat.bLockPostion,
                fnAction = function()
                    MY_Chat.bLockPostion = not MY_Chat.bLockPostion
                    MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
                end
            }, {
                szOption = _L["team balloon"],
                bCheck = true,
                bChecked = MY_Chat.bEnableBalloon,
                fnAction = function()
                    MY_Chat.bEnableBalloon = not MY_Chat.bEnableBalloon
                end
            }, {
                szOption = _L["chat copy"],
                bCheck = true,
                bChecked = MY_Chat.bChatCopy,
                fnAction = function()
                    MY_Chat.bChatCopy = not MY_Chat.bChatCopy
                end
            }, {
                szOption = _L["chat filter"],
                bCheck = true,
                bChecked = MY_Chat.bBlockWords,
                fnAction = function()
                    MY_Chat.bBlockWords = not MY_Chat.bBlockWords
                end, {
                    szOption = _L['keyword manager']
                }
            }, {
                szOption = _L["chat time"],
                bCheck = true,
                bChecked = MY_Chat.bChatTime,
                fnAction = function()
                    MY_Chat.bChatTime = not MY_Chat.bChatTime
                end, {
                    szOption = _L['hh:mm'],
                    bMCheck = true,
                    bChecked = MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN,
                    fnAction = function()
                        MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN
                    end,
                },{
                    szOption = _L['hh:mm:ss'],
                    bMCheck = true,
                    bChecked = MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN_SEC,
                    fnAction = function()
                        MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
                    end,
                }
            }, {
                bDevide = true
            }
        }
        local tChannel = { szOption = _L['channel setting'] }
        for _, v in ipairs(_Cache.tChannels) do
            table.insert(tChannel, {
                szOption = v.title, bCheck = true, bChecked = MY_Chat.tChannel[v.name], rgb = v.color,
                fnAction = function() MY_Chat.tChannel[v.name] = not MY_Chat.tChannel[v.name] MY_Chat.ReInitUI() end,
            })
        end
        table.insert(t, tChannel)
        return t
    end)
    -- load settings
    MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
end)

-- hook chat panel
MY.HookChatPanel("MY_Chat", function(h, szMsg)
    -- chat filter
    local t = MY.Chat.FormatContent(szMsg)
    local szText = ""
    for k, v in ipairs(t) do
        if v.text ~= "" then
            if v.type == "text" or v.type == "faceicon" then
                szText = szText .. v.text
            end
        end
    end
    for _,szWord in ipairs(MY_Chat.tBlockWords) do
        if string.find(szText, MY.String.PatternEscape(szWord)) then
            return ""
        end
    end
    -- save animiate group into name
    if MY_Chat.bChatTime or MY_Chat.bChatCopy then
        szMsg = string.gsub(szMsg, "group=(%d+) </a", "group=%1 name=\"%1\" </a")
    end
    
    return szMsg, h:GetItemCount()
end, function(h, szMsg, i)
    if MY_Chat.bChatTime then
        -- chat time
        local h2 = h:Lookup(i)
        if h2 and h2:GetType() == "Text" then
            local r, g, b = h2:GetFontColor()
            if r == 255 and g == 255 and b == 0 then
                return
            end
            local t =TimeToDate(GetCurrentTime())
            -- create timestrap text
            local szTime
            if MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN_SEC then
                szTime = GetFormatText(string.format("[%02d:%02d:%02d]", t.hour, t.minute, t.second), 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "timelink")
            else
                szTime = GetFormatText(string.format("[%02d:%02d]", t.hour, t.minute), 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "timelink")
            end
            -- insert timestrap text
            h:InsertItemFromString(i, false, szTime)
        end
    elseif MY_Chat.bChatCopy then
        -- chat copy
        local h2 = h:Lookup(i)
        if h2 and h2:GetType() == "Text" then
            local r, g, b = h2:GetFontColor()
            if r == 255 and g == 255 and b == 0 then
                return
            end
            local t =TimeToDate(GetCurrentTime())
            local szTime = GetFormatText(_L["*"], 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "copylink")
            h:InsertItemFromString(i, false, szTime)
        end
    end
end)