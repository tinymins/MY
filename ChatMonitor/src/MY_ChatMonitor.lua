--
-- ������
-- by ���� @ ˫���� @ ݶ����
-- Build 20140411
--
-- ��Ҫ����: ���ؼ��ֹ��˻�ȡ������Ϣ
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."ChatMonitor/lang/")
local _SUB_ADDON_FOLDER_NAME_ = "ChatMonitor"
MY_ChatMonitor = {}
MY_ChatMonitor.szKeyWords = _L['CHAT_MONITOR_KEYWORDS_SAMPLE']
MY_ChatMonitor.bIsRegexp = false
MY_ChatMonitor.nMaxRecord = 30
MY_ChatMonitor.bShowPreview = true
MY_ChatMonitor.bPlaySound = true
MY_ChatMonitor.bRedirectSysChannel = false
MY_ChatMonitor.bCapture = false
MY_ChatMonitor.bIgnoreSame = true
MY_ChatMonitor.tChannels = { ["MSG_NORMAL"] = true, ["MSG_CAMP"] = true, ["MSG_WORLD"] = true, ["MSG_MAP"] = true, ["MSG_SCHOOL"] = true, ["MSG_GUILD"] = true, ["MSG_FRIEND"] = true }
MY_ChatMonitor.anchor = {
    x = -100,
    y = -150,
    s = "BOTTOMRIGHT",
    r = "BOTTOMRIGHT",
}
RegisterCustomData('MY_ChatMonitor.szKeyWords')
RegisterCustomData('MY_ChatMonitor.bIsRegexp')
RegisterCustomData('MY_ChatMonitor.nMaxRecord')
RegisterCustomData('MY_ChatMonitor.bShowPreview')
RegisterCustomData('MY_ChatMonitor.bCapture')
RegisterCustomData('MY_ChatMonitor.tChannels')
RegisterCustomData('MY_ChatMonitor.bPlaySound')
RegisterCustomData('MY_ChatMonitor.bRedirectSysChannel')
RegisterCustomData('MY_ChatMonitor.anchor')
RegisterCustomData('MY_ChatMonitor.bIgnoreSame')
local _tRecords = {}
local _MY_ChatMonitor = { }
_MY_ChatMonitor.bInited = false
_MY_ChatMonitor.ui = nil
_MY_ChatMonitor.uiBoard = nil
_MY_ChatMonitor.uiTipBoard = nil
_MY_ChatMonitor.szLuaData = 'config/MY_CHATMONITOR'
_MY_ChatMonitor.tChannelGroups = {
    {
        szCaption = g_tStrings.CHANNEL_CHANNEL,
        tChannels = {
            "MSG_NORMAL", "MSG_PARTY", "MSG_MAP", "MSG_BATTLE_FILED", "MSG_GUILD", "MSG_GUILD_ALLIANCE", "MSG_SCHOOL",
            "MSG_WORLD", "MSG_TEAM", "MSG_CAMP", "MSG_GROUP", "MSG_WHISPER", "MSG_SEEK_MENTOR", "MSG_FRIEND", "MSG_SYS"
        },
    }, {
        szCaption = g_tStrings.FIGHT_CHANNEL,
        tChannels = {
            [g_tStrings.STR_NAME_OWN] = {
                "MSG_SKILL_SELF_SKILL", "MSG_SKILL_SELF_BUFF", "MSG_SKILL_SELF_DEBUFF", 
                "MSG_SKILL_SELF_MISS", "MSG_SKILL_SELF_FAILED"
            },
            [g_tStrings.TEAMMATE] = {"MSG_SKILL_PARTY_SKILL", "MSG_SKILL_PARTY_BUFF", "MSG_SKILL_PARTY_DEBUFF", "MSG_SKILL_PARTY_MISS"},
            [g_tStrings.OTHER_PLAYER] = {"MSG_SKILL_OTHERS_SKILL", "MSG_SKILL_OTHERS_MISS"},
            ["NPC"] = {"MSG_SKILL_NPC_SKILL", "MSG_SKILL_NPC_MISS"},
            [g_tStrings.OTHER] = {"MSG_OTHER_DEATH", "MSG_OTHER_ENCHANT", "MSG_OTHER_SCENE"},
        }
    }, {
        szCaption = g_tStrings.CHANNEL_COMMON,
        tChannels = {
            [g_tStrings.ENVIROMENT] = {"MSG_NPC_NEARBY", "MSG_NPC_YELL", "MSG_NPC_PARTY", "MSG_NPC_WHISPER"},
            [g_tStrings.EARN] = {
                "MSG_MONEY", "MSG_EXP", "MSG_ITEM", "MSG_REPUTATION", "MSG_CONTRIBUTE", "MSG_ATTRACTION", "MSG_PRESTIGE",
                "MSG_TRAIN", "MSG_DESGNATION", "MSG_ACHIEVEMENT", "MSG_MENTOR_VALUE", "MSG_THEW_STAMINA", "MSG_TONG_FUND"
            },
        }
    }
}

-- ������������ʱ���������Ϣ
_MY_ChatMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
    -- filter
    if MY_ChatMonitor.bCapture and MY_ChatMonitor.szKeyWords and MY_ChatMonitor.szKeyWords~='' then
        local rec = {
            text = '',    -- ���㵱ǰ��Ϣ�Ĵ��������� ����ƥ��
            hash = '',    -- ���㵱ǰ��Ϣ�Ĺ�ϣ ���ڹ�����ͬ
            html = '',    -- ��ϢԴ����UI XML
        }
        -- ����ϵͳ��Ϣ��ɫ
        local rgbSysMsg = GetMsgFontColor("MSG_SYS", true)
        -- ������ϢԴ����UI
        if bRich then
            rec.html = szMsg
            -- ��ʽ����Ϣ
            local tMsgContent = MY.Chat.FormatContent(szMsg)
            -- �����Ϣ�Ƿ��ǲ���Լ�������
            if tMsgContent[1].type == "text" and tMsgContent[1].displayText == "" then
                return
            end
            -- ƴ����Ϣ
            if r == rgbSysMsg[1] and g == rgbSysMsg[2] and b == rgbSysMsg[3] then -- ϵͳ��Ϣ
                for i, v in ipairs(tMsgContent) do
                    rec.text = rec.text .. v.text
                end
            else -- �������ϵͳ��Ϣ��������һ������֮ǰ�Ķ��� ���ơ�[��Ӫ][������][����]˵����
                -- STR_TALK_HEAD_WHISPER = "���ĵ�˵��",
                -- STR_TALK_HEAD_WHISPER_REPLY = "�����ĵض�",
                -- STR_TALK_HEAD_SAY = "˵��",
                -- STR_TALK_HEAD_SAY1 = "��",
                -- STR_TALK_HEAD_SAY2 = "��������",
                local bSkiped = false
                for i, v in ipairs(tMsgContent) do
                    if (i < 4 and not bSkiped) and (
                        v.text == g_tStrings.STR_TALK_HEAD_WHISPER or
                        v.text == g_tStrings.STR_TALK_HEAD_SAY or
                        v.text == g_tStrings.STR_TALK_HEAD_SAY1 or
                        v.text == g_tStrings.STR_TALK_HEAD_SAY2
                    ) then
                        bSkiped = true
                        rec.text = ''
                    else
                        rec.text = rec.text .. v.text
                    end
                end
            end
        else
            rec.text = szMsg
            rec.html = GetFormatText(szMsg, nil, rgbSysMsg[1], rgbSysMsg[2], rgbSysMsg[3])
        end
        
        if not MY_ChatMonitor.bIsRegexp then
            rec.text = StringLowerW(rec.text)
        end
        rec.hash = string.gsub(rec.text, '[\n%s]+', '')
        --------------------------------------------------------------------------------------
        -- ��ʼ�����Ƿ���Ϲ�����Ҫ��
        local bCatch = false
        if MY_ChatMonitor.bIsRegexp then    -- regexp
            if string.find(rec.text, MY_ChatMonitor.szKeyWords) then
                bCatch = true
            end
        else        -- normal
            -- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������;��ս
            local bKeyWordsLine = false
            for _, szKeyWordsLine in ipairs( MY.String.Split(StringLowerW(MY_ChatMonitor.szKeyWords), ';') ) do -- ����һ������
                if bKeyWordsLine then break end
                -- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������
                local bKeyWords = true
                for _, szKeyWords in ipairs( MY.String.Split(szKeyWordsLine, ',') ) do            -- ����ȫ������
                    if not bKeyWords then break end
                    -- 10|ʮ��
                    local bKeyWord = false
                    for _, szKeyWord in ipairs( MY.String.Split(szKeyWords, '|') ) do         -- ����һ������
                        if bKeyWord then break end
                        szKeyWord = MY.String.PatternEscape(szKeyWord)
                        if string.sub(szKeyWord, 1, 1)=="!" then    -- !С��������
                            szKeyWord = string.sub(szKeyWord, 2)
                            if not string.find(rec.text, szKeyWord) then
                                bKeyWord = true
                            end
                        else                                        -- ʮ��   -- 10
                            if string.find(rec.text, szKeyWord) then
                                bKeyWord = true
                            end
                        end
                    end
                    bKeyWords = bKeyWords and bKeyWord
                end
                bKeyWordsLine = bKeyWordsLine or bKeyWords
            end
            bCatch = bKeyWordsLine
        end
        --------------------------------------------------------------------------------------------
        -- �������Ҫ��  -- ��֤��Ϣ��ϣ �����������������Ϣ
        if bCatch and (not (_tRecords[rec.hash] and MY_ChatMonitor.bIgnoreSame)) then
            -- ��֤��¼�Ƿ񳬹���������
            if #_tRecords >= MY_ChatMonitor.nMaxRecord then 
                -- �����¼�б�
                _tRecords[_tRecords[1].hash] = _tRecords[_tRecords[1].hash] - 1
                if _tRecords[_tRecords[1].hash] <= 0 then
                    _tRecords[_tRecords[1].hash] = nil
                end
                table.remove(_tRecords, 1)
                -- ����UI
                if _MY_ChatMonitor.uiBoard then
                    local nCopyLinkCount = 0
                    _MY_ChatMonitor.uiBoard:hdl(1):children():each(function(ui)
                        if nCopyLinkCount <= 1 then
                            local name = ui:name()
                            if this:GetType() == "Text" and
                            (name == 'timelink' or
                             name == 'copylink' or
                             name == 'copy') then
                                nCopyLinkCount = nCopyLinkCount + 1
                            end
                        end
                        if nCopyLinkCount <= 1 then
                            ui:remove()
                        end
                    end)
                end
            end
            
            -- ��ʼ��װһ����¼ rec
            rec.html = MY.Chat.GetTimeLinkText({r=r, g=g, b=b, f=nFont}) .. rec.html
            -- save animiate group into name
            rec.html = string.gsub(rec.html, "group=(%d+) </a", "group=%1 name=\"%1\" </a")	
            -- render link event
            rec.html = MY.Chat.RenderLink(rec.html)
            -- render player name color
            if MY_Farbnamen and MY_Farbnamen.Render then
                rec.html = MY_Farbnamen.Render(rec.html)
            end
            
            -- ������ʾ��
            if MY_ChatMonitor.bPlaySound then
                MY.Sys.PlaySound(MY.GetAddonInfo().szRoot.."ChatMonitor\\audio\\MsgArrive.wav", "MsgArrive.wav")
            end
            
            -- ��������ض���ϵͳ��Ϣ�����
            if MY_ChatMonitor.bRedirectSysChannel and not ( r==rgbSysMsg[1] and g==rgbSysMsg[2] and b==rgbSysMsg[3] ) then
                OutputMessage("MSG_SYS", GetFormatText("",nil, 255,255,0)..szMsg, true)
            end
            
            -- ����UI
            if _MY_ChatMonitor.uiBoard then
                _MY_ChatMonitor.uiBoard:append(rec.html)
            end
            if MY_ChatMonitor.bShowPreview then
                _MY_ChatMonitor.ShowTip(rec.html)
            end
            
            -- ���»������� ��ϣ��
            _tRecords[rec.hash] = (_tRecords[rec.hash] or 0) + 1
            table.insert(_tRecords, rec)
        end
    end
end

_MY_ChatMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    
    ui:append('Label_KeyWord','Text'):find('#Label_KeyWord')
      :pos(22,15):size(100,25):text(_L['key words:'])
    
    ui:append('WndAutoComplete_KeyWord','WndAutoComplete'):children('#WndAutoComplete_KeyWord')
      :pos(80,15):size(w-226,25):text(MY_ChatMonitor.szKeyWords)
      :change(function(szText) MY_ChatMonitor.szKeyWords = szText end)
      :click(function(nButton, raw)
        if IsPopupMenuOpened() then
            MY.UI(raw):autocomplete('close')
        else
            MY.UI(raw):autocomplete('search', '')
        end
    end):autocomplete('option', 'beforeSearch', function(wnd, option)
        option.source = {}
        for _, szOpt in ipairs(MY.LoadLUAData(_MY_ChatMonitor.szLuaData) or {}) do
            if type(szOpt)=="string" then
                table.insert(option.source, szOpt)
            end
        end
    end):autocomplete('option', 'beforePopup', function(menu, wnd, option)
        if #menu > 0 then
            table.insert(menu, { bDevide = true })
        end
        table.insert(menu, { szOption = _L['add'], fnAction = function()
            local edit = ui:children('#WndAutoComplete_KeyWord')
            GetUserInput("", function(szVal)
                szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
                if szVal~="" then
                    local t = MY.LoadLUAData(_MY_ChatMonitor.szLuaData) or {}
                    for i = #t, 1, -1 do 
                        if t[i] == szVal then return end
                    end
                    table.insert(t, szVal)
                    MY.SaveLUAData(_MY_ChatMonitor.szLuaData, t)
                end
            end, function() end, function() end, nil, edit:text() )
        end })
    end):autocomplete('option', 'beforeDelete', function(szOption, fnDoDelete, option)
        local t = MY.LoadLUAData(_MY_ChatMonitor.szLuaData) or {}
        for i = #t, 1, -1 do 
            if t[i] == szOption then
                table.remove(t, i)
            end
        end
        MY.SaveLUAData(_MY_ChatMonitor.szLuaData, t)
    end)

    ui:append('Image_Help','Image'):find('#Image_Help')
      :image('UI/Image/UICommon/Commonpanel2.UITex',48)
      :pos(8,10):size(25,25)
      :hover(function(bIn) this:SetAlpha( (bIn and 255 ) or 180) end)
      :click(function(nButton)
        local szText = "<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(_L['CHAT_MONITOR_TIP']) .." font=207 </text>"
        local x, y = Cursor.GetPos()
        local w, h = this:GetSize()
        OutputTip(szText, 450, {x, y, w, h})
    end):alpha(180)
    
    ui:append('Image_Setting','Image'):find('#Image_Setting'):pos(w-26,13):image('UI/Image/UICommon/Commonpanel.UITex',18):size(30,30):alpha(200):hover(function(bIn) this:SetAlpha((bIn and 255) or 200) end):click(function()
        PopupMenu((function() 
            local t = {}
            for _, cg in ipairs(_MY_ChatMonitor.tChannelGroups) do
                local _t = { szOption = cg.szCaption }
                if cg.tChannels[1] then
                    for _, szChannel in ipairs(cg.tChannels) do
                        table.insert(_t,{
                            szOption = g_tStrings.tChannelName[szChannel],
                            rgb = GetMsgFontColor(szChannel, true),
                            fnAction = function()
                                MY_ChatMonitor.tChannels[szChannel] = not MY_ChatMonitor.tChannels[szChannel]
                                _MY_ChatMonitor.RegisterMsgMonitor()
                            end,
                            bCheck = true,
                            bChecked = MY_ChatMonitor.tChannels[szChannel]
                        })
                    end
                else
                    for szPrefix, tChannels in pairs(cg.tChannels) do
                        if #_t > 0 then
                            table.insert(_t,{ bDevide = true })
                        end
                        table.insert(_t,{
                            szOption = szPrefix,
                            bDisable = true,
                        })
                        for _, szChannel in ipairs(tChannels) do
                            table.insert(_t,{
                                szOption = g_tStrings.tChannelName[szChannel],
                                rgb = GetMsgFontColor(szChannel, true),
                                fnAction = function()
                                    MY_ChatMonitor.tChannels[szChannel] = not MY_ChatMonitor.tChannels[szChannel]
                                    _MY_ChatMonitor.RegisterMsgMonitor()
                                end,
                                bCheck = true,
                                bChecked = MY_ChatMonitor.tChannels[szChannel]
                            })
                        end
                    end
                end
                table.insert(t, _t)
            end
            table.insert(t, { bDevide = true })
            table.insert(t,{
                szOption = _L['show message preview box'],
                fnAction = function()
                    MY_ChatMonitor.bShowPreview = not MY_ChatMonitor.bShowPreview
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bShowPreview
            })
            table.insert(t,{
                szOption = _L['play new message alert sound'],
                fnAction = function()
                    MY_ChatMonitor.bPlaySound = not MY_ChatMonitor.bPlaySound
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bPlaySound
            })
            table.insert(t,{
                szOption = _L['output to system channel'],
                fnAction = function()
                    MY_ChatMonitor.bRedirectSysChannel = not MY_ChatMonitor.bRedirectSysChannel
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bRedirectSysChannel
            })
            table.insert(t,{
                szOption = _L['ignore same message'],
                fnAction = function()
                    MY_ChatMonitor.bIgnoreSame = not MY_ChatMonitor.bIgnoreSame
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bIgnoreSame
            })
            table.insert(t, { bDevide = true })
            table.insert(t,{
                szOption = _L['regular expression'],
                fnAction = function()
                    if MY_ChatMonitor.bIsRegexp then
                        MY_ChatMonitor.bIsRegexp = not MY_ChatMonitor.bIsRegexp
                    else
                        MessageBox({
                            szName = "MY_ChatMonitor_Regexp",
                            szMessage = _L["Are you sure you want to turn on regex mode?\nRegex is something advanced, make sure you know what you are doing."],
                            {szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() MY_ChatMonitor.bIsRegexp = not MY_ChatMonitor.bIsRegexp end},
                            {szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end},
                        })
                    end
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bIsRegexp
            })
            return t
        end)())
    end)

    ui:append('Button_ChatMonitor_Switcher','WndButton'):find('#Button_ChatMonitor_Switcher'):pos(w-136,15):width(50):text((MY_ChatMonitor.bCapture and _L['stop']) or _L['start']):click(function()
        if MY_ChatMonitor.bCapture then
            MY.UI(this):text(_L['start'])
            MY_ChatMonitor.bCapture = false
        else
            MY.UI(this):text(_L['stop'])
            MY_ChatMonitor.bCapture = true
        end
    end)
    
    ui:append('Button_Clear','WndButton'):find('#Button_Clear'):pos(w-81,15):width(50):text(_L['clear']):click(function()
        _tRecords = {}
        _MY_ChatMonitor.uiBoard:clear()
    end)
    
    _MY_ChatMonitor.uiBoard = ui
      :append('WndScrollBox_TalkList','WndScrollBox')
      :children('#WndScrollBox_TalkList')
      :handleStyle(3):pos(20,50):size(w-21, h - 70)
    
    for i = 1, #_tRecords, 1 do
        _MY_ChatMonitor.uiBoard:append( _tRecords[i].html )
    end
    _MY_ChatMonitor.ui = MY.UI(wnd)
    _MY_ChatMonitor.Init()
end

_MY_ChatMonitor.ShowTip = function(szMsg)
    if szMsg then
        _MY_ChatMonitor.uiTipBoard:clear():append(szMsg)
    end
    _MY_ChatMonitor.uiFrame:fadeTo(500, 255)
    if Station.GetMouseOverWindow() and
    Station.GetMouseOverWindow():GetRoot():GetName() == 'MY_ChatMonitor' then
        MY.DelayCall('MY_ChatMonitor_Hide', 5000)
    else
        MY.DelayCall('MY_ChatMonitor_Hide', function()
            _MY_ChatMonitor.uiFrame:fadeOut(500)
        end, 5000)
    end
end

_MY_ChatMonitor.Init = function()
    if _MY_ChatMonitor.bInited then
        return
    end
    _MY_ChatMonitor.bInited = true
    _MY_ChatMonitor.RegisterMsgMonitor()

    -- create tip frame
    _MY_ChatMonitor.uiFrame = MY.UI.CreateFrame('MY_ChatMonitor', MY.Const.UI.Frame.TOPMOST_EMPTY)
      :size(250,150)
      :toggle(false)
      :onevent("UI_SCALED", function() -- �ƶ���ʾ��λ��
        _MY_ChatMonitor.uiFrame:anchor(MY_ChatMonitor.anchor)
      end)
      :customMode(_L["chat monitor"], function()
        MY.DelayCall('MY_ChatMonitor_Hide')
        _MY_ChatMonitor.uiFrame:show():alpha(255)
      end, function()
        MY_ChatMonitor.anchor = _MY_ChatMonitor.uiFrame:anchor()
        _MY_ChatMonitor.uiFrame:alpha(0):hide()
      end)
      :anchor(MY_ChatMonitor.anchor)
      
    -- bind animate function
    _MY_ChatMonitor.uiFrame:append('Image_bg',"Image")
      :find('#Image_bg'):size(250,150)
      :image('UI/Image/Minimap/Minimap2.UITex',8)
      :click(function()
        MY.OpenPanel()
        MY.SwitchTab('ChatMonitor')
        _MY_ChatMonitor.uiFrame:fadeOut(500)
      end)
      :hover(function(bIn, bCurIn)
        if bIn ~= bCurIn then
            return
        end
        if bCurIn then
            MY.DelayCall('MY_ChatMonitor_Hide')
            _MY_ChatMonitor.uiFrame:fadeIn(500)
        else
            MY.DelayCall(function()
                _MY_ChatMonitor.uiFrame:fadeOut(500)
            end, 5000, 'MY_ChatMonitor_Hide')
        end
      end)
    -- init tip panel animate
    MY.DelayCall(function()
        _MY_ChatMonitor.uiFrame:fadeOut(500)
    end, 10000, 'MY_ChatMonitor_Hide')

    -- init tip panel handle
    _MY_ChatMonitor.uiTipBoard = _MY_ChatMonitor.uiFrame:append('Handle_Tip',"Handle")
      :find('#Handle_Tip'):handleStyle(3):pos(10,10):size(230,130)
    -- init welcome word
    _MY_ChatMonitor.uiTipBoard:append('Text1','Text'):find('#Text1')
      :text(_L['welcome to use mingyi chat monitor.'])
    -- show tip
    _MY_ChatMonitor.ShowTip()
end
MY.RegisterInit(_MY_ChatMonitor.Init)

_MY_ChatMonitor.RegisterMsgMonitor = function()
    local t = {}
    for szChannel, bCapture in pairs(MY_ChatMonitor.tChannels) do
        if bCapture then table.insert(t, szChannel) end
    end
    UnRegisterMsgMonitor(_MY_ChatMonitor.OnMsgArrive)
    RegisterMsgMonitor(_MY_ChatMonitor.OnMsgArrive, t)
end

MY.Game.AddHotKey("MY_ChatMonitor_Hotkey", _L["chat monitor"],
    function()
        if MY_ChatMonitor.bCapture then
            MY.UI(MY.GetFrame()):find('#Button_ChatMonitor_Switcher'):text(_L['start'])
            MY_ChatMonitor.bCapture = false
        else
            MY.UI(MY.GetFrame()):find('#Button_ChatMonitor_Switcher'):text(_L['stop'])
            MY_ChatMonitor.bCapture = true
        end
    end
, nil)

MY.RegisterPanel( "ChatMonitor", _L["chat monitor"], _L['Chat'], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, {
    OnPanelActive = _MY_ChatMonitor.OnPanelActive,
    OnPanelDeactive = function()
        _MY_ChatMonitor.uiBoard = nil
    end
})
