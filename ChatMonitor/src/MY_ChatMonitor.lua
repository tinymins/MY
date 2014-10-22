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
local _MY_ChatMonitor = { }
_MY_ChatMonitor.bInited = false
_MY_ChatMonitor.tCapture = {}
_MY_ChatMonitor.ui = nil
_MY_ChatMonitor.uiBoard = nil
_MY_ChatMonitor.uiTipBoard = nil
_MY_ChatMonitor.szLuaData = 'config/MY_CHATMONITOR'

-- 插入聊天内容时监控聊天信息
_MY_ChatMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
    -- filter
    if MY_ChatMonitor.bCapture and MY_ChatMonitor.szKeyWords and MY_ChatMonitor.szKeyWords~='' then
        local tCapture = {
            szText = '',    -- 计算当前消息的纯文字内容 用于匹配
            szHash = '',    -- 计算当前消息的哈希 用于过滤相同
            szMsg  = '',    -- 消息源数据UI
            szTime = '',    -- 消息时间UI
        }
        -- 计算系统消息颜色
        local colMsgSys = GetMsgFontColor("MSG_SYS", true)
        -- 计算消息源数据UI
        if bRich then
            tCapture.szMsg  = szMsg
            -- 格式化消息
            local tMsgContent = MY.Chat.FormatContent(szMsg)
            -- 检测消息是否是插件产生的
            if tMsgContent[1].type=="text" and tMsgContent[1].text=="" then return end
            -- 拼接消息
            for i, v in ipairs(tMsgContent) do
                -- 如果不是系统信息且第一个是名字 类似“[阵营][浩气盟][茗伊]说：” 则舍弃头部标签
                if i~=1 or (r==colMsgSys[1] and g==colMsgSys[2] and b==colMsgSys[3]) or v[2].type~="name" then
                    tCapture.szText = tCapture.szText .. v[1]
                end
            end
        else
            tCapture.szMsg  = GetFormatText(szMsg, nil, colMsgSys[1], colMsgSys[2], colMsgSys[3])
            tCapture.szText = szMsg
        end
        
        if not MY_ChatMonitor.bIsRegexp then
            tCapture.szText = StringLowerW(tCapture.szText)
        end
        tCapture.szHash = string.gsub(tCapture.szText,'\n', '')
        --------------------------------------------------------------------------------------
        -- 开始计算是否符合过滤器要求
        local bCatch = false
        if MY_ChatMonitor.bIsRegexp then    -- regexp
            if string.find(tCapture.szText, MY_ChatMonitor.szKeyWords) then bCatch = true end
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
                            if not string.find(tCapture.szText, szKeyWord) then bKeyWord = true end
                        else                                        -- 十人   -- 10
                            if string.find(tCapture.szText, szKeyWord) then bKeyWord = true end
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
        if bCatch and (not _MY_ChatMonitor.tCapture[tCapture.szHash]) then
            -- 验证记录是否超过限制条数
            if #_MY_ChatMonitor.tCapture >= MY_ChatMonitor.nMaxRecord then 
                -- 处理记录列表
                _MY_ChatMonitor.tCapture[_MY_ChatMonitor.tCapture[1].szHash] = nil
                table.remove(_MY_ChatMonitor.tCapture, 1)
                -- 处理UI
                local bEnd = false
                if _MY_ChatMonitor.uiBoard then
                    _MY_ChatMonitor.uiBoard:hdl(1):children():each(function()
                        if not bEnd then
                            if this:GetType()=="Text" and StringFindW(this:GetText(), "\n") then
                                bEnd = true
                            end
                            this:GetParent():RemoveItem(this:GetIndex())
                        end
                    end)
                end
            end
            -- 开始组装一条记录 tCapture
            local t =TimeToDate(GetCurrentTime())
            tCapture.szTime = GetFormatText(string.format("[%02d:%02d.%02d]", t.hour, t.minute, t.second), 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "timelink")
            -- save animiate group into name
            tCapture.szMsg = string.gsub(tCapture.szMsg, "group=(%d+) </a", "group=%1 name=\"%1\" </a")	
            -- render link event
            tCapture.szMsg = MY.Chat.RenderLink(tCapture.szMsg)
            -- render player name color
            if MY_Farbnamen and MY_Farbnamen.Render then
                tCapture.szMsg = MY_Farbnamen.Render(tCapture.szMsg)
            end
            -- 发出提示音
            if MY_ChatMonitor.bPlaySound then MY.Sys.PlaySound(MY.GetAddonInfo().szRoot.."ChatMonitor\\audio\\MsgArrive.wav", "MsgArrive.wav") end
            
            -- 如果设置重定向到系统消息则输出
            if MY_ChatMonitor.bRedirectSysChannel and not ( r==255 and g==255 and b==0 ) then
                OutputMessage("MSG_SYS", GetFormatText("",nil, 255,255,0)..szMsg, true)
            end
            -- 更新UI
            if _MY_ChatMonitor.uiBoard then
                _MY_ChatMonitor.uiBoard:append(tCapture.szTime..tCapture.szMsg)
                -- _MY_ChatMonitor.uiBoard:find('#^.*link'):each(function()
                --     MY.Chat.RenderLink(this)
                -- end)
            end
            -- 更新缓存数组 哈希表
            _MY_ChatMonitor.tCapture[tCapture.szHash] = true
            table.insert(_MY_ChatMonitor.tCapture, tCapture)
            _MY_ChatMonitor.ShowTip(tCapture.szTime..tCapture.szMsg)
        end
    end
end

_MY_ChatMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    ui:append('Label_KeyWord','Text'):find('#Label_KeyWord'):pos(22,15):size(100,25):text(_L['key words:'])
    ui:append('EditBox_KeyWord','WndEditComboBox'):children('#EditBox_KeyWord'):pos(80,15):size(w-246,25):text(MY_ChatMonitor.szKeyWords):change(function(szText) MY_ChatMonitor.szKeyWords = szText end):menu(function()
        local edit, t = ui:children('#EditBox_KeyWord'), {}
        for _, szOpt in ipairs(MY.LoadLUAData(_MY_ChatMonitor.szLuaData) or {}) do
            if type(szOpt)=="string" then
                table.insert(t, {
                    szOption = szOpt, {
                        szOption = _L['use'],
                        fnAction = function() edit:text(szOpt) end
                    }, {
                        szOption = _L['delete'],
                        fnAction = function()
                            local t = MY.LoadLUAData(_MY_ChatMonitor.szLuaData) or {}
                            for i = #t, 1, -1 do 
                                if t[i] == szOpt then table.remove(t, i) end
                            end
                            MY.SaveLUAData(_MY_ChatMonitor.szLuaData, t)
                        end
                    }
                })
            end
        end
        if #t > 0 then table.insert(t, { bDevide = true }) end
        table.insert(t, { szOption = _L['add'], fnAction = function()
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
        return t
    end):alpha(180)
    ui:append('Image_Help','Image'):find('#Image_Help'):image('UI/Image/UICommon/Commonpanel2.UITex',48):pos(8,10):size(25,25):hover(function(bIn) this:SetAlpha( (bIn and 255 ) or 180) end):click(function(nButton)
        local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(_L['CHAT_MONITOR_TIP']) .." font=207 </text>"
        local x, y = Cursor.GetPos()
        local w, h = this:GetSize()
        OutputTip(szText, 450, {x, y, w, h})
    end):alpha(180)
    ui:append('Image_Setting','Image'):find('#Image_Setting'):pos(w-46,13):image('UI/Image/UICommon/Commonpanel.UITex',18):size(30,30):alpha(200):hover(function(bIn) this:SetAlpha((bIn and 255) or 200) end):click(function()
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
    ui:append('Button_ChatMonitor_Switcher','WndButton'):find('#Button_ChatMonitor_Switcher'):pos(w-156,15):width(50):text((MY_ChatMonitor.bCapture and _L['stop']) or _L['start']):click(function()
        if MY_ChatMonitor.bCapture then
            MY.UI(this):text(_L['start'])
            MY_ChatMonitor.bCapture = false
        else
            MY.UI(this):text(_L['stop'])
            MY_ChatMonitor.bCapture = true
        end
    end)
    ui:append('Button_Clear','WndButton'):find('#Button_Clear'):pos(w-101,15):width(50):text(_L['clear']):click(function()
        _MY_ChatMonitor.tCapture = {}
        _MY_ChatMonitor.uiBoard:clear()
    end)
    _MY_ChatMonitor.uiBoard = ui:append('WndScrollBox_TalkList','WndScrollBox'):children('#WndScrollBox_TalkList'):handleStyle(3):pos(20,50):size(w-41,405)
    for i = 1, #_MY_ChatMonitor.tCapture, 1 do
        _MY_ChatMonitor.uiBoard:append( _MY_ChatMonitor.tCapture[i].szTime .. _MY_ChatMonitor.tCapture[i].szMsg )
    end
    _MY_ChatMonitor.ui = MY.UI(wnd)
    _MY_ChatMonitor.Init()
end

_MY_ChatMonitor.ShowTip = function(szMsg)
    if not MY_ChatMonitor.bShowPreview then return end
    if szMsg then
        _MY_ChatMonitor.uiTipBoard:clear():append(szMsg)
        _MY_ChatMonitor.uiTipBoard:find('#^.*link'):del('#^namelink_'):click(function(nFlag) 
            if nFlag==1 and IsCtrlKeyDown() then
                MY_ChatMonitor.CopyChatItem(this)
            end
        end)
        _MY_ChatMonitor.uiTipBoard:find('#^namelink_'):click(function(nFlag) 
            local szName = this:GetText()
            if nFlag==-1 then
                PopupMenu((function()
                    local t = {}
                    table.insert(t, {
                        szOption = _L['copy'],
                        fnAction = function()
                            MY.Talk(GetClientPlayer().szName, szName)
                        end,
                    })
                    table.insert(t, {
                        szOption = _L['whisper'],
                        fnAction = function()
                            MY.SwitchChat(szName)
                        end,
                    })
                    pcall(InsertInviteTeamMenu, t, string.gsub(szName, '[%[%]]', ''))
                    return t
                end)())
            elseif nFlag==1 then
                if IsCtrlKeyDown() then
                    MY_ChatMonitor.CopyChatItem(this)
                else
                    MY.SwitchChat(szName)
                    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
                    if edit then Station.SetFocusWindow(edit) end
                end
            end
        end)
    end
    _MY_ChatMonitor.uiFrame:fadeTo(500,255)
    MY.DelayCall('MY_ChatMonitor_Hide')
    MY.DelayCall(function() _MY_ChatMonitor.uiFrame:fadeOut(500) end,5000,'MY_ChatMonitor_Hide')
end
_MY_ChatMonitor.Init = function()
    if _MY_ChatMonitor.bInited then return end
    _MY_ChatMonitor.bInited = true
    
    _MY_ChatMonitor.RegisterMsgMonitor()
    local fnOnTipClick = function() MY.ActivePanel('ChatMonitor') MY.OpenPanel() _MY_ChatMonitor.uiFrame:fadeOut(500) end
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
    
    _MY_ChatMonitor.uiFrame:append('Image_bg',"Image"):find('#Image_bg'):image('UI/Image/Minimap/Minimap2.UITex',8):size(300,300):click(fnOnTipClick)
    -- _MY_ChatMonitor.uiTest = _MY_ChatMonitor.uiFrame:append('WndWindow_Test','WndWindow'):children('#WndWindow_Test'):toggle(false)
    _MY_ChatMonitor.uiTipBoard = _MY_ChatMonitor.uiFrame:append('Handle_Tip',"Handle"):find('#Handle_Tip'):handleStyle(3):pos(10,10):size(230,130)

    _MY_ChatMonitor.uiTipBoard:append('Text1','Text'):find('#Text1'):text(_L['welcome to use mingyi chat monitor.']):click(fnOnTipClick)
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
MY_ChatMonitor.CopyChatLine = _MY_ChatMonitor.CopyChatLine
MY_ChatMonitor.RepeatChatLine = _MY_ChatMonitor.RepeatChatLine
MY_ChatMonitor.CopyChatItem = _MY_ChatMonitor.CopyChatItem
MY.RegisterPanel( "ChatMonitor", _L["chat monitor"], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, { OnPanelActive = _MY_ChatMonitor.OnPanelActive, OnPanelDeactive = function() _MY_ChatMonitor.uiBoard = nil end } )
