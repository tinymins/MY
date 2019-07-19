--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动隐藏聊天栏
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local EMPTY_TABLE, MENU_DIVIDER, XML_LINE_BREAKER = LIB.EMPTY_TABLE, LIB.MENU_DIVIDER, LIB.XML_LINE_BREAKER
-----------------------------------------------------------------------------------------------------------
local STATE = {
    SHOW    = 1, -- 已显示
    HIDE    = 2, -- 已隐藏
    SHOWING = 3, -- 渐变显示中
    HIDDING = 4, -- 渐变隐藏中
}
local m_nState = STATE.SHOW
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT..'MY_Toolbox/lang/')
local _Cache = {}
MY_AutoHideChat = {}
MY_AutoHideChat.bAutoHideChatPanel = false
RegisterCustomData('MY_AutoHideChat.bAutoHideChatPanel')

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
            Call(callback)
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
        LIB.BreatheCall('MY_AutoHideChat_Hide', false)
    end
    m_nState = STATE.SHOWING

    -- get start alpha
    local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
    local nStartFrame = GetLogicFrameCount()
    -- register animate breathe call
    LIB.BreatheCall('MY_AutoHideChat_Show', function()
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
                Call(callback)
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
            Call(callback)
        end
        return
    elseif m_nState == STATE.HIDDING then
        -- unregister hide animate
        LIB.BreatheCall('MY_AutoHideChat_Hide', false)
    end
    m_nState = STATE.HIDDING

    -- get start alpha
    local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
    local nStartFrame = GetLogicFrameCount()
    -- register animate breathe call
    LIB.BreatheCall('MY_AutoHideChat_Hide', function()
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
                Call(callback)
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
        LIB.HookChatPanel('AFTER.MY_AutoHideChat', function(h)
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
        LIB.HookChatPanel('AFTER.MY_AutoHideChat', false)

        MY_AutoHideChat.ShowChatPanel()
    end
end
LIB.RegisterInit('MY_AUTOHIDECHAT', MY_AutoHideChat.ApplyConfig)
