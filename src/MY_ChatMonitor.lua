--
-- 聊天监控
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140411
--
-- 主要功能: 按关键字过滤获取聊天消息
-- 
local _L = MY.LoadLangPack()
MY_ChatMonitor = {}
MY_ChatMonitor.szKeyWords = ""
MY_ChatMonitor.bIsRegexp = false
MY_ChatMonitor.nMaxCapture = 10
RegisterCustomData('MY_ChatMonitor.szKeyWords')
RegisterCustomData('MY_ChatMonitor.bIsRegexp')
RegisterCustomData('MY_ChatMonitor.nMaxCapture')
local _MY_ChatMonitor = { }
_MY_ChatMonitor.nCurrentCapture = -1
_MY_ChatMonitor.tCapture = {}
_MY_ChatMonitor.bCapture = false
_MY_ChatMonitor.ui = nil

-- 插入聊天内容时监控聊天信息
_MY_ChatMonitor.Chat_AppendItemFromString_Hook = function(h, szMsg)
    h:_AppendItemFromString_MY_ChatMonitor(szMsg)
	-- filter
    if _MY_ChatMonitor.bCapture and _MY_ChatMonitor.ui and MY_ChatMonitor.szKeyWords and MY_ChatMonitor.szKeyWords~='' then
        local tCapture = {}
        tCapture.szText = ''
        _MY_ChatMonitor.ui:child('#WndWindow_Test'):clear():append(szMsg):children('.Handle'):child():each(function(ele)
            local szName = ele:GetName()
            if szName == "msglink" then
                tCapture.szType = ele:GetText()
            elseif string.sub(szName, 1, 8) == "namelink" then
                tCapture.szName = ele:GetText()
            else
                tCapture.szText = tCapture.szText .. ele:GetText()
            end
        end)
        local bCatch = false
        if MY_ChatMonitor.bIsRegexp then
            if string.find(tCapture.szText, MY_ChatMonitor.szKeyWords) then bCatch = true end
        else
            local split = function(s, p)
                local rt= {}
                string.gsub(s, '[^'..p..']+', function(w) 
                    w = string.gsub(w, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')
                    table.insert(rt, w) 
                end )
                return rt
            end
            local tKeyWords = split(MY_ChatMonitor.szKeyWords, '|')
            for _, szKeyWord in ipairs(tKeyWords) do
                if string.find(tCapture.szText, szKeyWord) then bCatch = true end
            end
        end
        
        if tCapture.szName and bCatch then
            tCapture.szText = string.gsub(tCapture.szText,'\n', '')
            tCapture.szText = string.gsub(tCapture.szText,'^.-：', '')
            if type(_MY_ChatMonitor.tCapture[_MY_ChatMonitor.nCurrentCapture])~="table" or tCapture.szText ~= _MY_ChatMonitor.tCapture[_MY_ChatMonitor.nCurrentCapture].szText then
                _MY_ChatMonitor.nCurrentCapture = (_MY_ChatMonitor.nCurrentCapture + 1) % MY_ChatMonitor.nMaxCapture
                local t =TimeToDate(GetCurrentTime())
                local szTime = string.format("[%02d:%02d.%02d]", t.hour, t.minute, t.second)
                _MY_ChatMonitor.ui:children('#Label_ID_'.._MY_ChatMonitor.nCurrentCapture):text(tCapture.szName or '')
                _MY_ChatMonitor.ui:children('#Label_Time_'.._MY_ChatMonitor.nCurrentCapture):text(szTime..(tCapture.szType or '['.._L['NEARBY']..']'))
                _MY_ChatMonitor.ui:children('#EditBox_Capture_'.._MY_ChatMonitor.nCurrentCapture):text(tCapture.szText or '')
                _MY_ChatMonitor.tCapture[_MY_ChatMonitor.nCurrentCapture] = tCapture
            end
        end
    end
end
-- hook chat panel
MY_ChatMonitor.HookChatPanel = function()
	for i = 1, 10 do
		local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
		local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
		if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
            if not h._AppendItemFromString_MY_ChatMonitor then
                -- 保存原始函数 用来兼容其他插件
                h._AppendItemFromString_MY_ChatMonitor = h.AppendItemFromString
            end
            -- HOOK上自己的函数
            h.AppendItemFromString = _MY_ChatMonitor.Chat_AppendItemFromString_Hook
        end
	end
end

_MY_ChatMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    ui:append('Label_KeyWord','Text'):children('#Label_KeyWord'):pos(20,15):size(100,25):text('关键字：')
    ui:append('EditBox_KeyWord','WndEditBox'):children('#EditBox_KeyWord'):pos(80,15):size(380,25):text(MY_ChatMonitor.szKeyWords):change(function(szText) MY_ChatMonitor.szKeyWords = szText end)
    ui:append('CheckBox_KeyWord','WndCheckBox'):children('#CheckBox_KeyWord'):pos(460,17):text('正则'):check(function(b) MY_ChatMonitor.bIsRegexp = b end):check(MY_ChatMonitor.bIsRegexp)
    ui:append('WndWindow_Test','WndWindow'):children('#WndWindow_Test'):toggle(false)
    ui:append('Button_KeyWord','WndButton'):children('#Button_KeyWord'):pos(520,15):text('开始监控'):click(function()
        if _MY_ChatMonitor.bCapture then
            MY.UI(this):text('开始监控')
            _MY_ChatMonitor.bCapture = false
        else
            MY.UI(this):text('暂停监控')
            MY_ChatMonitor.HookChatPanel()
            _MY_ChatMonitor.bCapture = true
        end
    end)
    for i = 0, 9, 1 do
        ui:append('Label_ID_'..i,'Text'):children('#Label_ID_'..i):pos(20,i*40+62):size(100,25):text('等待中…'):color({238,130,238}):click(function() if string.find( this:GetText(),'%[' ) then MY.SwitchChat(string.gsub(this:GetText(),'[%[%]]','')) end end)
        ui:append('Label_Time_'..i,'Text'):children('#Label_Time_'..i):pos(20,i*40+45):size(100,25):text('[00:00:00]')
        ui:append('EditBox_Capture_'..i,'WndEditBox'):children('#EditBox_Capture_'..i):pos(125,i*40+45):size(500,40):multiLine(true):text('')
    end
    _MY_ChatMonitor.nCurrentCapture = -1
    _MY_ChatMonitor.ui = MY.UI(wnd)
end
MY.RegisterPanel( "ChatMonitor", _L["chat monitor"], "interface\\MY\\ui\\MainPanel.ini", "UI/Image/UICommon/LoginSchool.UITex|24", {255,127,0,200}, { OnPanelActive = _MY_ChatMonitor.OnPanelActive, OnPanelDeactive = function() 
    _MY_ChatMonitor.bCapture = false end } )