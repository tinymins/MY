--
-- 自动隐藏聊天栏
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20150105
--
local STATE = {
    SHOW    = 1, -- 已显示
    HIDE    = 2, -- 已隐藏
    SHOWING = 3, -- 渐变显示中
    HIDDING = 4, -- 渐变隐藏中
}
local m_nState = STATE.SHOW
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
    nDelayFrame = nDelayFrame or 0                    -- 隐藏延迟帧数
    -- switch case
    if m_nState == STATE.SHOW then
        -- return when chat panel is visible
        if callback then
            pcall(callback)
        end
        return
    elseif m_nState == STATE.SHOWING then
        return
    elseif m_nState == STATE.HIDE then
        -- show each
        for i = 1, 10 do
            local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
            if hFrame then
                hFrame:SetMousePenetrable(false)
            end
        end
    elseif m_nState == STATE.HIDDING then
        -- unregister hide animate
        MY.BreatheCall('MY_AutoHideChat_Hide')
    end
    m_nState = STATE.SHOWING
    
    -- get start alpha
    local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
    local nStartFrame = GetLogicFrameCount()
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
            m_nState = STATE.SHOW
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
    -- switch case
    if m_nState == STATE.SHOW then
        -- get bg alpha
        _Cache.fAhBgAlpha = MY_AutoHideChat.GetBgAlpha()
    elseif m_nState == STATE.SHOWING then
        return
    elseif m_nState == STATE.HIDE then
        -- return when chat panel is not visible
        if callback then
            pcall(callback)
        end
        return
    elseif m_nState == STATE.HIDDING then
        -- unregister hide animate
        MY.BreatheCall('MY_AutoHideChat_Hide')
    end
    m_nState = STATE.HIDDING
    
    -- get start alpha
    local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
    local nStartFrame = GetLogicFrameCount()
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
                    hFrame:SetMousePenetrable(true)
                end
            end
        end
        Station.Lookup('Lowest1/ChatTitleBG'):SetAlpha(nAlpha)
        Station.Lookup('Lowest1/ChatTitleBG', 'Image_BG'):SetAlpha(nAlpha * _Cache.fAhBgAlpha)
        if nAlpha == 0 then
            m_nState = STATE.HIDE
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
        MY.HookChatPanel('MY_AutoHideChat', nil, function(h, channel, param, msg)
            -- if msg is empty (means nothing appended) then return
            if not (msg and #msg > 0) then
                return
            end
            -- if input box get focus then return
            local focus = Station.GetFocusWindow()
            if focus and focus:GetTreePath() == 'Lowest2/EditBox/Edit_Input/' then
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
        MY.Chat.HookChatPanel('MY_AutoHideChat')
        
        MY_AutoHideChat.ShowChatPanel()
    end
end
MY.RegisterInit('MY_AUTOHIDECHAT', MY_AutoHideChat.ApplyConfig)
