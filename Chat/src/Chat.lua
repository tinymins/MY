local _L = MY.LoadLangPack("Interface/MY/Chat/lang/")
local CHAT_TIME = {
    HOUR_MIN = 1,
    HOUR_MIN_SEC = 2,
}
-- init vars
MY_Chat = MY_Chat or {}
MY_Chat.bLockPostion = false
MY_Chat.anchor = { x=10, y=-60, s="BOTTOMLEFT", r="BOTTOMLEFT" }
MY_Chat.bEnableBalloon = true
MY_Chat.bChatCopy = true
MY_Chat.bBlockWords = false
MY_Chat.tBlockWords = {}
MY_Chat.bChatTime = true
MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
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
MY_Chat.frame:SetPoint(MY_Chat.anchor.s, 0, 0, MY_Chat.anchor.r, MY_Chat.anchor.x, MY_Chat.anchor.y)
MY_Chat.frame:CorrectPos()
MY.RegisterEvent("UI_SCALED",function()
    MY_Chat.frame:SetPoint(MY_Chat.anchor.s, 0, 0, MY_Chat.anchor.r, MY_Chat.anchor.x, MY_Chat.anchor.y)
    MY_Chat.frame:CorrectPos()
end)

MY_Chat.L

MY.RegisterInit(function()
    -- init ui
    for i,v in ipairs({
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
    }) do
        MY.UI(MY_Chat.frame):append(v.name,"WndRadioBox"):child("#"..v.name):width(20):text(v.title):font(197):color(v.color):pos(i*30+15,25):check(function()
            -- Switch Chat Channel Here
            MY.SwitchChat(v.channel)
            MY.UI(this):check(false)
        end):find(".Text"):pos(4,-18):width(20)
    end
    MY.UI(MY_Chat.frame):append("Check_Leave","WndCheckBox"):child("#Check_Leave"):width(25):text(_L["AWAY"]):pos(375,25):find(".Text"):pos(5,-16):width(25):font(197)
    MY.UI(MY_Chat.frame):append("Check_Busy","WndCheckBox"):child("#Check_Busy"):width(25):text(_L["BUSY"]):pos(405,25):find(".Text"):pos(5,-16):width(25):font(197)
    
    MY.UI(MY_Chat.frame):child("#Btn_Option"):menu(function() return {
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
        }, {
            szOption = _L['channel setting'], {
            
            }
        }
    } end)
end)