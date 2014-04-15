--
-- 聊天监控
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140411
--
-- 主要功能: 按关键字过滤获取聊天消息
-- 
local _L = MY.LoadLangPack()
MY_ChatMonitor = {}
MY_ChatMonitor.szKeyWords = "大战|成就|大明宫|XZTC|血战天策"
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
                tCapture.szTime = string.format("[%02d:%02d.%02d]", t.hour, t.minute, t.second)
                _MY_ChatMonitor.ui:children('#Label_ID_'.._MY_ChatMonitor.nCurrentCapture):text(tCapture.szName or '')
                _MY_ChatMonitor.ui:children('#Label_Time_'.._MY_ChatMonitor.nCurrentCapture):text(tCapture.szTime..(tCapture.szType or '['.._L['NEARBY']..']'))
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
    ui:append('Label_KeyWord','Text'):children('#Label_KeyWord'):pos(20,15):size(100,25):text(_L['key words:'])
    ui:append('EditBox_KeyWord','WndEditBox'):children('#EditBox_KeyWord'):pos(80,15):size(380,25):text(MY_ChatMonitor.szKeyWords):change(function(szText) MY_ChatMonitor.szKeyWords = szText end)
    ui:append('CheckBox_KeyWord','WndCheckBox'):children('#CheckBox_KeyWord'):pos(460,17):text(_L['regexp']):check(function(b) MY_ChatMonitor.bIsRegexp = b end):check(MY_ChatMonitor.bIsRegexp)
    ui:append('WndWindow_Test','WndWindow'):children('#WndWindow_Test'):toggle(false)
    ui:append('Button_Switcher','WndButton'):children('#Button_Switcher'):pos(520,15):width(50):text((_MY_ChatMonitor.bCapture and _L['stop']) or _L['start']):click(function()
        if _MY_ChatMonitor.bCapture then
            MY.UI(this):text(_L['start'])
            _MY_ChatMonitor.bCapture = false
        else
            MY.UI(this):text(_L['stop'])
            MY_ChatMonitor.HookChatPanel()
            _MY_ChatMonitor.bCapture = true
        end
    end)
    ui:append('Button_Clear','WndButton'):children('#Button_Clear'):pos(575,15):width(50):text(_L['clear']):click(function()
        ui:children('#^EditBox_Capture_'):text('')
        ui:children('#^Label_ID_'):text(_L['waiting...'])
        ui:children('#^Label_Time_'):text('[00:00:00]')
        _MY_ChatMonitor.nCurrentCapture = -1
        _MY_ChatMonitor.tCapture = {}
    end)
    for i = 0, 9, 1 do
        ui:append('Label_ID_'..i,'Text'):children('#Label_ID_'..i):pos(20,i*40+62):size(100,25):text((_MY_ChatMonitor.tCapture[i] and _MY_ChatMonitor.tCapture[i].szName) or _L['waiting...']):color({238,130,238}):click(function() if string.find( this:GetText(),'%[' ) then MY.SwitchChat(string.gsub(this:GetText(),'[%[%]]','')) end end)
        ui:append('Label_Time_'..i,'Text'):children('#Label_Time_'..i):pos(20,i*40+45):size(100,25):text((_MY_ChatMonitor.tCapture[i] and _MY_ChatMonitor.tCapture[i].szTime) or '[00:00:00]')
        ui:append('EditBox_Capture_'..i,'WndEditBox'):children('#EditBox_Capture_'..i):pos(125,i*40+45):size(500,40):multiLine(true):text((_MY_ChatMonitor.tCapture[i] and _MY_ChatMonitor.tCapture[i].szText) or '')
    end
    _MY_ChatMonitor.ui = MY.UI(wnd)
end
MY.RegisterPanel( "ChatMonitor", _L["chat monitor"], "interface\\MY\\ui\\MainPanel.ini", "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, { OnPanelActive = _MY_ChatMonitor.OnPanelActive, OnPanelDeactive = function() 
    _MY_ChatMonitor.bCapture = false end } )