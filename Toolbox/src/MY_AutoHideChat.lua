--
-- 自动隐藏聊天栏
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20150105
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _Cache = {}
MY_AutoHideChat = {}
MY_AutoHideChat.bAutoHideChatPanel = false
RegisterCustomData("MY_AutoHideChat.bAutoHideChatPanel")

-- get sys chat bg alpha
MY_AutoHideChat.GetBgAlpha = function()
    return Station.Lookup('Lowest2/ChatPanel1'):Lookup('Wnd_Message', 'Shadow_Back'):GetAlpha() / 255
end

-- show panel
MY_AutoHideChat.ShowChatPanel = function(nShowFrame, nDelayFrame, callback)
    nShowFrame  = nShowFrame  or GLOBAL.GAME_FPS / 4  -- 渐变出现帧数
    nDelayFrame = nDelayFrame or GLOBAL.GAME_FPS * 5  -- 隐藏延迟帧数
    -- return when chat panel is visible
    if not _Cache.bHide then
        if callback then
            pcall(callback)
        end
        return
    end
    -- get start alpha
    local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
    local nStartFrame = GetLogicFrameCount()
    _Cache.bAhAnimate = true
    _Cache.bHide      = false
    -- unregister hide animate
    MY.BreatheCall('MY_AutoHideChat_Hide')
    -- show each
    for i = 1, 10 do
        local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
        if hFrame then
            hFrame:Show(true)
        end
    end
    -- register animate breathe call
    MY.BreatheCall('MY_AutoHideChat_Show', function()
        local nFrame = GetLogicFrameCount()
        if nFrame - nDelayFrame < nStartFrame then
            _Cache.fAhBgAlpha = MY_AutoHideChat.GetBgAlpha()
            return
        end
        -- calc new alpha
        local nAlpha = math.min(math.ceil((nFrame - nDelayFrame - nStartFrame) / nShowFrame * (255 - nStartAlpha) + nStartAlpha), 255)
        -- alpha each panel
        for i = 1, 10 do
            local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
            if hFrame then
                hFrame:SetAlpha(nAlpha)
                hFrame:Lookup('Wnd_Message', 'Shadow_Back'):SetAlpha(nAlpha * _Cache.fAhBgAlpha)
            end
        end
        Station.Lookup('Lowest1/ChatTitleBG'):SetAlpha(nAlpha)
        Station.Lookup('Lowest1/ChatTitleBG', 'Image_BG'):SetAlpha(nAlpha * _Cache.fAhBgAlpha)
        if nAlpha == 255 then
            _Cache.bAhAnimate = false
            if callback then
                pcall(callback)
            end
            return 0
        end
    end)
end

-- hide panel
MY_AutoHideChat.HideChatPanel = function(nHideFrame, nDelayFrame, callback)
    nHideFrame  = nHideFrame  or GLOBAL.GAME_FPS / 2  -- 渐变消失帧数
    nDelayFrame = nDelayFrame or GLOBAL.GAME_FPS * 5  -- 隐藏延迟帧数
    if not _Cache.bAhAnimate then
        -- get bg alpha
        _Cache.fAhBgAlpha = MY_AutoHideChat.GetBgAlpha()
    end
    -- get start alpha
    local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
    local nStartFrame = GetLogicFrameCount()
    _Cache.bAhAnimate = true
    -- unregister show animate
    MY.BreatheCall('MY_AutoHideChat_Show')
    -- register animate breathe call
    MY.BreatheCall('MY_AutoHideChat_Hide', function()
        local nFrame = GetLogicFrameCount()
        if nFrame - nDelayFrame < nStartFrame then
            _Cache.fAhBgAlpha = MY_AutoHideChat.GetBgAlpha()
            return
        end
        -- calc new alpha
        local nAlpha = math.max(math.ceil((1 - (nFrame - nDelayFrame - nStartFrame) / nHideFrame) * nStartAlpha), 0)
        -- if panel setting panel is opened then delay again
        local hPanelSettingFrame = Station.Lookup('Normal/ChatSettingPanel')
        if hPanelSettingFrame and hPanelSettingFrame:IsVisible() then
            nStartFrame = GetLogicFrameCount()
            return
        end
        -- if mouse over chat panel then delay again
        local hMouseOverWnd = Station.GetMouseOverWindow()
        if hMouseOverWnd and hMouseOverWnd:GetRoot():GetName():sub(1, 9) == 'ChatPanel' then
            nStartFrame = GetLogicFrameCount()
            nAlpha = 255
        end
        -- alpha each panel
        for i = 1, 10 do
            local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
            if hFrame then
                hFrame:SetAlpha(nAlpha)
                hFrame:Lookup('Wnd_Message', 'Shadow_Back'):SetAlpha(nAlpha * _Cache.fAhBgAlpha)
                -- hide if alpha turns to zero
                if nAlpha == 0 then
                    hFrame:Hide()
                end
            end
        end
        Station.Lookup('Lowest1/ChatTitleBG'):SetAlpha(nAlpha)
        Station.Lookup('Lowest1/ChatTitleBG', 'Image_BG'):SetAlpha(nAlpha * _Cache.fAhBgAlpha)
        if nAlpha == 0 then
            _Cache.bAhAnimate = false
            _Cache.bHide      = true
            if callback then
                pcall(callback)
            end
            return 0
        end
    end)
end

-- 初始化/生效 设置
MY_AutoHideChat.ApplyConfig = function()
    if MY_AutoHideChat.bAutoHideChatPanel then
        -- get bg alpha
        if not _Cache.fAhBgAlpha then
            _Cache.fAhBgAlpha = Station.Lookup('Lowest2/ChatPanel1'):Lookup('Wnd_Message', 'Shadow_Back'):GetAlpha() / 255
            _Cache.bAhAnimate = _Cache.bAhAnimate or false
        end
        -- hook chat panel as event listener
        MY.Chat.HookChatPanel('MY_AutoHideChat', function() end,function(h, szMsg)
            -- if szMsg is empty (means nothing appended) then return
            if not (szMsg and #szMsg > 0) then
                return
            end
            -- if not active panel msg then return
            if not h:GetRoot():Lookup('CheckBox_Title'):IsCheckBoxChecked() then
                return
            end
            -- if input box get focus then return
            local hFocus = Station.GetFocusWindow()
            if hFocus and hFocus:GetTreePath() == 'Lowest2/EditBox/Edit_Input/' then
                return
            end
            -- show when new msg
            MY_AutoHideChat.ShowChatPanel(GLOBAL.GAME_FPS / 4, 0, function()
                -- hide after 5 sec
                MY_AutoHideChat.HideChatPanel(GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS * 5)
            end)
        end)
        
        -- hook chat edit box
        local hEditInput = Station.Lookup('Lowest2/EditBox/Edit_Input')
        -- save org
        if hEditInput._MY_T_AHCP_OnSetFocus == nil then
            hEditInput._MY_T_AHCP_OnSetFocus = hEditInput.OnSetFocus or false
        end
        -- show when chat panel get focus
        hEditInput.OnSetFocus  = function()
            MY_AutoHideChat.ShowChatPanel(GLOBAL.GAME_FPS / 4, 0)
            if this._MY_T_AHCP_OnSetFocus then
                this._MY_T_AHCP_OnSetFocus()
            end
        end
        -- save org
        if hEditInput._MY_T_AHCP_OnKillFocus == nil then
            hEditInput._MY_T_AHCP_OnKillFocus = hEditInput.OnKillFocus or false
        end
        -- hide after input box lost focus for 5 sec
        hEditInput.OnKillFocus = function()
            MY_AutoHideChat.HideChatPanel(GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS * 5)
            if this._MY_T_AHCP_OnKillFocus then
                this._MY_T_AHCP_OnKillFocus()
            end
        end
    else
        local hEditInput = Station.Lookup('Lowest2/EditBox/Edit_Input')
        if hEditInput._MY_T_AHCP_OnSetFocus then
            hEditInput.OnSetFocus = hEditInput._MY_T_AHCP_OnSetFocus
        else
            hEditInput.OnSetFocus = nil
        end
        hEditInput._MY_T_AHCP_OnSetFocus = nil
        
        if hEditInput._MY_T_AHCP_OnKillFocus then
            hEditInput.OnKillFocus = hEditInput._MY_T_AHCP_OnKillFocus
        else
            hEditInput.OnKillFocus = nil
        end
        hEditInput._MY_T_AHCP_OnKillFocus = nil
        
        MY.BreatheCall('MY_AutoHideChat_Hide')
        MY.BreatheCall('MY_AutoHideChat_Show')
        _Cache.bAhAnimate = false
        MY_AutoHideChat.ShowChatPanel()
    end
end
MY.RegisterInit(MY_AutoHideChat.ApplyConfig)