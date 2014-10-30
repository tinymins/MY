--
-- 聊天监控
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140411
--
-- 主要功能: 按关键字过滤获取聊天消息
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

-- 插入聊天内容时监控聊天信息
_MY_ChatMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
    -- filter
    if MY_ChatMonitor.bCapture and MY_ChatMonitor.szKeyWords and MY_ChatMonitor.szKeyWords~='' then
        local rec = {
            text = '',    -- 计算当前消息的纯文字内容 用于匹配
            hash = '',    -- 计算当前消息的哈希 用于过滤相同
            html = '',    -- 消息源数据UI XML
        }
        -- 计算系统消息颜色
        local rgbSysMsg = GetMsgFontColor("MSG_SYS", true)
        -- 计算消息源数据UI
        if bRich then
            rec.html = szMsg
            -- 格式化消息
            local tMsgContent = MY.Chat.FormatContent(szMsg)
            -- 检测消息是否是插件自己产生的
            if tMsgContent[1].type == "text" and tMsgContent[1].displayText == "" then
                return
            end
            -- 拼接消息
            if r == rgbSysMsg[1] and g == rgbSysMsg[2] and b == rgbSysMsg[3] then -- 系统消息
                for i, v in ipairs(tMsgContent) do
                    rec.text = rec.text .. v.text
                end
            else -- 如果不是系统信息则舍弃第一个名字之前的东西 类似“[阵营][浩气盟][茗伊]说：”
                -- STR_TALK_HEAD_WHISPER = "悄悄地说：",
                -- STR_TALK_HEAD_WHISPER_REPLY = "你悄悄地对",
                -- STR_TALK_HEAD_SAY = "说：",
                -- STR_TALK_HEAD_SAY1 = "：",
                -- STR_TALK_HEAD_SAY2 = "大声喊：",
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
        -- 开始计算是否符合过滤器要求
        local bCatch = false
        if MY_ChatMonitor.bIsRegexp then    -- regexp
            if string.find(rec.text, MY_ChatMonitor.szKeyWords) then
                bCatch = true
            end
        else        -- normal
            -- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁;大战
            local bKeyWordsLine = false
            for _, szKeyWordsLine in ipairs( MY.String.Split(StringLowerW(MY_ChatMonitor.szKeyWords), ';') ) do -- 符合一个即可
                if bKeyWordsLine then break end
                -- 10|十人,血战天策|XZTC,!小铁被吃了,!开宴黑铁
                local bKeyWords = true
                for _, szKeyWords in ipairs( MY.String.Split(szKeyWordsLine, ',') ) do            -- 必须全部符合
                    if not bKeyWords then break end
                    -- 10|十人
                    local bKeyWord = false
                    for _, szKeyWord in ipairs( MY.String.Split(szKeyWords, '|') ) do         -- 符合一个即可
                        if bKeyWord then break end
                        szKeyWord = MY.String.PatternEscape(szKeyWord)
                        if string.sub(szKeyWord, 1, 1)=="!" then    -- !小铁被吃了
                            szKeyWord = string.sub(szKeyWord, 2)
                            if not string.find(rec.text, szKeyWord) then
                                bKeyWord = true
                            end
                        else                                        -- 十人   -- 10
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
        -- 如果符合要求  -- 验证消息哈希 如果存在则跳过该消息
        if bCatch and (not (_tRecords[rec.hash] and MY_ChatMonitor.bIgnoreSame)) then
            -- 验证记录是否超过限制条数
            if #_tRecords >= MY_ChatMonitor.nMaxRecord then 
                -- 处理记录列表
                _tRecords[_tRecords[1].hash] = _tRecords[_tRecords[1].hash] - 1
                if _tRecords[_tRecords[1].hash] <= 0 then
                    _tRecords[_tRecords[1].hash] = nil
                end
                table.remove(_tRecords, 1)
                -- 处理UI
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
            
            -- 开始组装一条记录 rec
            rec.html = MY.Chat.GetTimeLinkText({r=r, g=g, b=b, f=nFont}) .. rec.html
            -- save animiate group into name
            rec.html = string.gsub(rec.html, "group=(%d+) </a", "group=%1 name=\"%1\" </a")	
            -- render link event
            rec.html = MY.Chat.RenderLink(rec.html)
            -- render player name color
            if MY_Farbnamen and MY_Farbnamen.Render then
                rec.html = MY_Farbnamen.Render(rec.html)
            end
            
            -- 发出提示音
            if MY_ChatMonitor.bPlaySound then
                MY.Sys.PlaySound(MY.GetAddonInfo().szRoot.."ChatMonitor\\audio\\MsgArrive.wav", "MsgArrive.wav")
            end
            
            -- 如果设置重定向到系统消息则输出
            if MY_ChatMonitor.bRedirectSysChannel and not ( r==rgbSysMsg[1] and g==rgbSysMsg[2] and b==rgbSysMsg[3] ) then
                OutputMessage("MSG_SYS", GetFormatText("",nil, 255,255,0)..szMsg, true)
            end
            
            -- 更新UI
            if _MY_ChatMonitor.uiBoard then
                _MY_ChatMonitor.uiBoard:append(rec.html)
            end
            if MY_ChatMonitor.bShowPreview then
                _MY_ChatMonitor.ShowTip(rec.html)
            end
            
            -- 更新缓存数组 哈希表
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
            MY.UI(raw):autocomplete('search')
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
            for szChannel, tChannel in pairs({
                ['MSG_NORMAL'] = { szName = _L['nearby channel'], tCol = GetMsgFontColor("MSG_NORMAL", true) },
                ['MSG_SYS'] = { szName = _L['system channel'], tCol = GetMsgFontColor("MSG_SYS", true) },
                ['MSG_FRIEND'] = { szName = _L['friend channel'], tCol = GetMsgFontColor("MSG_FRIEND", true) },
                ['MSG_TEAM'] = { szName = _L['raid channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
                ['MSG_GUILD'] = { szName = _L['tong channel'], tCol = GetMsgFontColor("MSG_GUILD", true) },
                ['MSG_GUILD_ALLIANCE'] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
                ['MSG_MAP'] = { szName = _L['map channel'], tCol = GetMsgFontColor("MSG_MAP", true) },
                ['MSG_SCHOOL'] = { szName = _L['school channel'], tCol = GetMsgFontColor("MSG_SCHOOL", true) },
                ['MSG_CAMP'] = { szName = _L['camp channel'], tCol = GetMsgFontColor("MSG_CAMP", true) },
                ['MSG_WORLD'] = { szName = _L['world channel'], tCol = GetMsgFontColor("MSG_WORLD", true) },
                ['MSG_WHISPER'] = { szName = _L['whisper channel'], tCol = GetMsgFontColor("MSG_WHISPER", true) },
            }) do
                table.insert(t,{
                    szOption = tChannel.szName,
                    rgb = tChannel.tCol,
                    fnAction = function()
                        MY_ChatMonitor.tChannels[szChannel] = not MY_ChatMonitor.tChannels[szChannel]
                        _MY_ChatMonitor.RegisterMsgMonitor()
                    end,
                    bCheck = true,
                    bChecked = MY_ChatMonitor.tChannels[szChannel]
                })
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
    MY.DelayCall('MY_ChatMonitor_Hide')
    MY.DelayCall('MY_ChatMonitor_Hide', function()
        _MY_ChatMonitor.uiFrame:fadeOut(500)
    end, 5000)
end

_MY_ChatMonitor.Init = function()
    if _MY_ChatMonitor.bInited then
        return
    end
    _MY_ChatMonitor.bInited = true
    _MY_ChatMonitor.RegisterMsgMonitor()
    
    _MY_ChatMonitor.uiFrame = MY.UI.CreateFrame('MY_ChatMonitor',true):size(250,150):hover(function(bIn)
        MY.DelayCall('MY_ChatMonitor_Hide')
        if not bIn then MY.DelayCall(function() _MY_ChatMonitor.uiFrame:fadeOut(500) end,5000,'MY_ChatMonitor_Hide') end
    end):toggle(false)
    
    -- 移动提示窗位置
    _MY_ChatMonitor.uiFrame:onevent("UI_SCALED", function()
        _MY_ChatMonitor.uiFrame:anchor(MY_ChatMonitor.anchor)
    end):customMode(_L["chat monitor"], function()
        MY.DelayCall('MY_ChatMonitor_Hide')
        _MY_ChatMonitor.uiFrame:show():alpha(255)
    end, function()
        MY_ChatMonitor.anchor = _MY_ChatMonitor.uiFrame:anchor()
        _MY_ChatMonitor.uiFrame:alpha(0):hide()
    end):anchor(MY_ChatMonitor.anchor)
    
    _MY_ChatMonitor.uiFrame:append('Image_bg',"Image")
      :find('#Image_bg'):size(300,300)
      :image('UI/Image/Minimap/Minimap2.UITex',8)
      :click(function()
        MY.OpenPanel()
        MY.ActivePanel('ChatMonitor')
        _MY_ChatMonitor.uiFrame:fadeOut(500)
      end)
    
    _MY_ChatMonitor.uiTipBoard = _MY_ChatMonitor.uiFrame:append('Handle_Tip',"Handle")
      :find('#Handle_Tip'):handleStyle(3):pos(10,10):size(230,130)

    _MY_ChatMonitor.uiTipBoard:append('Text1','Text'):find('#Text1')
      :text(_L['welcome to use mingyi chat monitor.'])
    
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

MY.RegisterPanel( "ChatMonitor", _L["chat monitor"], _L['General'], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, {
    OnPanelActive = _MY_ChatMonitor.OnPanelActive,
    OnPanelDeactive = function()
        _MY_ChatMonitor.uiBoard = nil
    end
})
