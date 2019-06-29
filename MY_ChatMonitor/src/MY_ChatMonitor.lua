--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天监控 按关键字过滤获取聊天消息
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
--[[
    RECORD_LIST = {
        -- （数组部分）监控记录
        {
            html = 消息A的UI序列化值(szMsg) 消息源数据UI XML,
            hash = 消息A的HASH值 计算当前消息的哈希 用于过滤相同,
            text = 消息A的纯文本 计算当前消息的纯文字内容 用于匹配,
        }, ...
    }
    RECORD_HASH = {
        -- （哈希部分）记录数量
        [消息A的HASH值] = 相同的消息A捕获的数量, -- 当为0时删除改HASH
        ...
    }
]]
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_ChatMonitor/lang/')
if not LIB.AssertVersion('MY_ChatMonitor', _L['MY_ChatMonitor'], 0x2011800) then
	return
end
local D = {}
local _C = {}
local DATA_FILE = 'userdata/chatmonitor.jx3dat'
local RECORD_LIST, RECORD_HASH = {}, {}
MY_ChatMonitor = {}
MY_ChatMonitor.szKeyWords          = _L.CHAT_MONITOR_KEYWORDS_SAMPLE
MY_ChatMonitor.bIsRegexp           = false
MY_ChatMonitor.nMaxRecord          = 30
MY_ChatMonitor.bShowPreview        = true
MY_ChatMonitor.bPlaySound          = true
MY_ChatMonitor.bRedirectSysChannel = false
MY_ChatMonitor.bCapture            = false
MY_ChatMonitor.bBlockWords         = true
MY_ChatMonitor.bIgnoreSame         = false
-- MY_ChatMonitor.bRealtimeSave       = false
MY_ChatMonitor.bDistinctServer     = false
MY_ChatMonitor.szTimestrap         = '[hh:mm:ss]'
MY_ChatMonitor.anchor              = { x = -100, y = -150, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' }
MY_ChatMonitor.tChannels           = {
    ['MSG_NORMAL'] = true, ['MSG_CAMP' ] = true, ['MSG_WORLD' ] = true, ['MSG_MAP'     ] = true,
    ['MSG_SCHOOL'] = true, ['MSG_GUILD'] = true, ['MSG_FRIEND'] = true, ['MSG_IDENTITY'] = true,
}
RegisterCustomData('MY_ChatMonitor.szKeyWords')
RegisterCustomData('MY_ChatMonitor.bIsRegexp')
RegisterCustomData('MY_ChatMonitor.nMaxRecord')
RegisterCustomData('MY_ChatMonitor.bShowPreview')
RegisterCustomData('MY_ChatMonitor.bCapture')
RegisterCustomData('MY_ChatMonitor.bBlockWords')
RegisterCustomData('MY_ChatMonitor.tChannels')
RegisterCustomData('MY_ChatMonitor.bPlaySound')
RegisterCustomData('MY_ChatMonitor.bRedirectSysChannel')
RegisterCustomData('MY_ChatMonitor.anchor')
RegisterCustomData('MY_ChatMonitor.bIgnoreSame', 1)
-- RegisterCustomData('MY_ChatMonitor.bRealtimeSave')
RegisterCustomData('MY_ChatMonitor.bDistinctServer')
RegisterCustomData('MY_ChatMonitor.szTimestrap')
_C.bInited = false
_C.ui = nil
_C.uiBoard = nil
_C.szLuaData = 'config/chatmonitor.jx3dat'
do local SZ_OLD_PATH = LIB.FormatPath('config/MY_CHATMONITOR/cfg_$lang.jx3dat')
    if IsLocalFileExist(SZ_OLD_PATH) then
        CPath.Move(SZ_OLD_PATH, LIB.FormatPath({_C.szLuaData, PATH_TYPE.GLOBAL}))
    end
end
_C.tChannelGroups = {
    {
        szCaption = g_tStrings.CHANNEL_CHANNEL,
        tChannels = {
            'MSG_NORMAL', 'MSG_PARTY', 'MSG_MAP', 'MSG_BATTLE_FILED', 'MSG_GUILD', 'MSG_GUILD_ALLIANCE', 'MSG_SCHOOL', 'MSG_WORLD',
            'MSG_TEAM', 'MSG_CAMP', 'MSG_GROUP', 'MSG_WHISPER', 'MSG_SEEK_MENTOR', 'MSG_FRIEND', 'MSG_IDENTITY', 'MSG_SYS',
        },
    }, {
        szCaption = g_tStrings.FIGHT_CHANNEL,
        tChannels = {
            [g_tStrings.STR_NAME_OWN] = {
                'MSG_SKILL_SELF_HARMFUL_SKILL', 'MSG_SKILL_SELF_BENEFICIAL_SKILL', 'MSG_SKILL_SELF_BUFF',
                'MSG_SKILL_SELF_BE_HARMFUL_SKILL', 'MSG_SKILL_SELF_BE_BENEFICIAL_SKILL', 'MSG_SKILL_SELF_DEBUFF',
                'MSG_SKILL_SELF_SKILL', 'MSG_SKILL_SELF_MISS', 'MSG_SKILL_SELF_FAILED', 'MSG_SELF_DEATH',
            },
            [g_tStrings.TEAMMATE] = {
                'MSG_SKILL_PARTY_HARMFUL_SKILL', 'MSG_SKILL_PARTY_BENEFICIAL_SKILL', 'MSG_SKILL_PARTY_BUFF',
                'MSG_SKILL_PARTY_BE_HARMFUL_SKILL', 'MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL', 'MSG_SKILL_PARTY_DEBUFF',
                'MSG_SKILL_PARTY_SKILL', 'MSG_SKILL_PARTY_MISS', 'MSG_PARTY_DEATH',
            },
            [g_tStrings.OTHER_PLAYER] = {'MSG_SKILL_OTHERS_SKILL', 'MSG_SKILL_OTHERS_MISS', 'MSG_OTHERS_DEATH'},
            ['NPC'] = {'MSG_SKILL_NPC_SKILL', 'MSG_SKILL_NPC_MISS', 'MSG_NPC_DEATH'},
            [g_tStrings.OTHER] = {'MSG_OTHER_ENCHANT', 'MSG_OTHER_SCENE'},
        },
    }, {
        szCaption = g_tStrings.CHANNEL_COMMON,
        tChannels = {
            [g_tStrings.ENVIROMENT] = {'MSG_NPC_NEARBY', 'MSG_NPC_YELL', 'MSG_NPC_PARTY', 'MSG_NPC_WHISPER'},
            [g_tStrings.EARN] = {
                'MSG_MONEY', 'MSG_EXP', 'MSG_ITEM', 'MSG_REPUTATION', 'MSG_CONTRIBUTE',
                'MSG_ATTRACTION', 'MSG_PRESTIGE', 'MSG_TRAIN', 'MSG_DESGNATION',
                'MSG_ACHIEVEMENT', 'MSG_MENTOR_VALUE', 'MSG_THEW_STAMINA', 'MSG_TONG_FUND'
            },
        },
    }
}
_C.nLastLoadDataTime = -1000000

function D.SaveData()
    local TYPE = MY_ChatMonitor.bDistinctServer
        and PATH_TYPE.SERVER or PATH_TYPE.ROLE
    LIB.SaveLUAData({DATA_FILE, TYPE}, {list = RECORD_LIST, hash = RECORD_HASH})
end
LIB.RegisterExit(D.SaveData)

function D.LoadData()
    local data = MY_ChatMonitor.bDistinctServer
        and (LIB.LoadLUAData({DATA_FILE, PATH_TYPE.SERVER}) or {})
        or (LIB.LoadLUAData({DATA_FILE, PATH_TYPE.ROLE}) or {})
    RECORD_LIST = data.list or {}
    RECORD_HASH = data.hash or {}
end
LIB.RegisterInit(D.LoadData)

function D.GetHTML(rec)
    -- render link event
    local html = LIB.RenderChatLink(rec.html)
    -- render player name color
    if MY_Farbnamen and MY_Farbnamen.Render then
        html = MY_Farbnamen.Render(html)
    end
    html = LIB.GetTimeLinkText({
        r = rec.r, g = rec.g, b = rec.b,
        f = rec.font, s = MY_ChatMonitor.szTimestrap,
    }, rec.time) .. html
    return html
end

function D.OnNotifyCB()
    LIB.ShowPanel()
    LIB.FocusPanel()
    LIB.SwitchTab('MY_ChatMonitor')
    LIB.DismissNotify('MY_ChatMonitor')
end

-- 插入聊天内容时监控聊天信息
_C.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b, szChannel)
    -- is enabled
    if not MY_ChatMonitor.bCapture
    or not MY_ChatMonitor.szKeyWords
    or MY_ChatMonitor.szKeyWords == '' then
        return
    end
    --------------------------------------------------------------------------------------
    -- 开始生成一条记录
    local rec = { text = '', hash = '', html = '' }
    -- 计算消息源数据UI
    if bRich then
        rec.html = szMsg
        -- 格式化消息
        local tMsgContent = LIB.FormatChatContent(szMsg)
        -- 检测消息是否是插件自己产生的
        if tMsgContent[1] and tMsgContent[1].type == 'text' and tMsgContent[1].innerText == '' then
            return
        end
        -- 拼接消息
        if szChannel == 'MSG_SYS' then -- 系统消息
            for i, v in ipairs(tMsgContent) do
                rec.text = rec.text .. v.text
            end
            rec.hash = rec.text
        else -- 如果不是系统信息则在哈希中舍弃第一个名字之前的东西 类似“[阵营][浩气盟][茗伊]说：”
            -- STR_TALK_HEAD_WHISPER = '悄悄地说：',
            -- STR_TALK_HEAD_WHISPER_REPLY = '你悄悄地对',
            -- STR_TALK_HEAD_SAY = '说：',
            -- STR_TALK_HEAD_SAY1 = '：',
            -- STR_TALK_HEAD_SAY2 = '大声喊：',
            local bSkiped = false
            for i, v in ipairs(tMsgContent) do
                if (i < 4 and not bSkiped) and (
                    v.text == g_tStrings.STR_TALK_HEAD_WHISPER or
                    v.text == g_tStrings.STR_TALK_HEAD_SAY or
                    v.text == g_tStrings.STR_TALK_HEAD_SAY1 or
                    v.text == g_tStrings.STR_TALK_HEAD_SAY2
                ) then
                    bSkiped = true
                    rec.hash = ''
                else
                    rec.text = rec.text .. v.text
                    rec.hash = rec.hash .. v.text
                end
            end
        end
    else
        rec.text = szMsg
        rec.hash = szMsg
        rec.html = GetFormatText(szMsg, nil, GetMsgFontColor('MSG_SYS'))
    end

    if not MY_ChatMonitor.bIsRegexp then
        rec.text = StringLowerW(rec.text)
    end
    rec.hash = string.gsub(rec.hash, '[\n%s]+', '')
    --------------------------------------------------------------------------------------
    -- 开始计算是否符合过滤器要求
    if MY_ChatMonitor.bIsRegexp then -- regexp
        if not string.find(rec.text, MY_ChatMonitor.szKeyWords) then
            return
        end
    else -- normal
        if not LIB.StringSimpleMatch(rec.text, MY_ChatMonitor.szKeyWords) then
            return
        end
    end
    -- 验证消息哈希 如果存在则跳过该消息
    if MY_ChatMonitor.bIgnoreSame and RECORD_HASH[rec.hash] then
        return
    end
    --------------------------------------------------------------------------------------
    -- 如果符合要求
    -- 开始渲染一条记录的UIXML字符串
    rec.r, rec.g, rec.b = r, g, b
    rec.font = nFont
    rec.time = GetCurrentTime()
    local html = D.GetHTML(rec)
    -- 如果设置重定向到系统消息则输出（输出时加个标记防止又被自己捕捉了死循环）
    if MY_ChatMonitor.bRedirectSysChannel and szChannel ~= 'MSG_SYS' then
        OutputMessage('MSG_SYS', GetFormatText('', nil, 255,255,0) .. szMsg, true)
    end
    -- 广播消息
    OutputMessage('MSG_MY_MONITOR', szMsg, true)
    -- 更新UI
    if _C.uiBoard then
        local nPos = _C.uiBoard:scroll()
        _C.uiBoard:append(html)
        if nPos == 100 or nPos == -1 then
            _C.uiBoard:scroll(100)
        end
    end
    LIB.CreateNotify({
        szKey = 'MY_ChatMonitor',
        szMsg = html,
        fnAction = D.OnNotifyCB,
        bPlaySound = MY_ChatMonitor.bPlaySound,
        szSound = LIB.GetAddonInfo().szRoot .. 'MY_ChatMonitor/audio/MsgArrive.ogg',
        szCustomSound = 'MsgArrive.ogg',
        bPopupPreview = MY_ChatMonitor.bShowPreview,
    })
    --------------------------------------------------------------------------------------
    -- 开始处理记录的数据保存
    -- 更新缓存数组 哈希表
    table.insert(RECORD_LIST, rec)
    RECORD_HASH[rec.hash] = (RECORD_HASH[rec.hash] or 0) + 1
    -- 验证记录是否超过限制条数
    local nOverflowed = #RECORD_LIST - MY_ChatMonitor.nMaxRecord
    if nOverflowed > 0 then
        -- 处理记录列表
        for i = nOverflowed, 1, -1 do
            local hash = RECORD_LIST[1].hash
            if hash and RECORD_HASH[hash] then
                RECORD_HASH[hash] = RECORD_HASH[hash] - 1
                if RECORD_HASH[hash] <= 0 then
                    RECORD_HASH[hash] = nil
                end
            end
            if _C.uiBoard then
                _C.uiBoard:removeItemUntilNewLine()
            end
            table.remove(RECORD_LIST, 1)
        end
    end
    -- if MY_ChatMonitor.bRealtimeSave then
    --     D.SaveData()
    -- end
end

_C.OnPanelActive = function(wnd)
    local ui = UI(wnd)
    local w, h = ui:size()

    ui:append('Text', { x = 22, y = 15, w = 100, h = 25, text = _L['key words:'] })

    ui:append('WndAutocomplete', {
        x = 80, y = 15, w = w - 226, h = 25, text = MY_ChatMonitor.szKeyWords,
        onchange = function(szText) MY_ChatMonitor.szKeyWords = szText end,
        onfocus = function(self)
            local source = {}
            for _, szOpt in ipairs(LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}) do
                if type(szOpt) == 'string' then
                    table.insert(source, szOpt)
                end
            end
            self:autocomplete('option', 'source', source)
        end,
        onclick = function()
            if IsPopupMenuOpened() then
                UI(this):autocomplete('close')
            else
                local source = {}
                for _, szOpt in ipairs(LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}) do
                    if type(szOpt) == 'string' then
                        table.insert(source, szOpt)
                    end
                end
                UI(this):autocomplete('option', 'source', source)
                UI(this):autocomplete('search', '')
            end
        end,
        autocomplete = {
            -- { 'option', 'beforeSearch', function(raw, option, text) end },
            {
                'option', 'beforePopup', function(wnd, option, text, menu)
                    if #menu > 0 then
                        table.insert(menu, { bDevide = true })
                    end
                    table.insert(menu, { szOption = _L['add'], fnAction = function()
                        GetUserInput('', function(szVal)
                            szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
                            if szVal~='' then
                                local t = LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}
                                for i = #t, 1, -1 do
                                    if t[i] == szVal then return end
                                end
                                table.insert(t, szVal)
                                LIB.SaveLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}, t)
                            end
                        end, function() end, function() end, nil, UI(wnd):text() )
                    end })
                end,
            },
            {
                'option', 'beforeDelete', function(szOption, fnDoDelete, option)
                    local t = LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}
                    for i = #t, 1, -1 do
                        if t[i] == szOption then
                            table.remove(t, i)
                        end
                    end
                    LIB.SaveLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}, t)
                end,
            },
        },
    })

    ui:append('Image', {
        image = 'UI/Image/UICommon/Commonpanel2.UITex', imageframe = 48,
        x = 8, y = 10, w = 25, h = 25, alpha = 180,
        onhover = function(bIn) this:SetAlpha( (bIn and 255 ) or 180) end,
        onclick = function()
            local szText = '<image>path="ui/Image/UICommon/Talk_Face.UITex" frame=25 w=24 h=24</image> <text>text=' .. EncodeComponentsString(_L['CHAT_MONITOR_TIP']) ..' font=207 </text>'
            local x, y = Cursor.GetPos()
            local w, h = this:GetSize()
            OutputTip(szText, 450, {x, y, w, h})
        end,
    })

    ui:append('Image', {
        x = w - 26, y = 13,
        image = 'UI/Image/UICommon/Commonpanel.UITex', imageframe = 18,
        w = 30, h = 30, alpha = 200,
        onhover = function(bIn) this:SetAlpha((bIn and 255) or 200) end,
        onclick = function()
            PopupMenu((function()
                local t = LIB.GetChatChannelMenu(function(szChannel)
                    MY_ChatMonitor.tChannels[szChannel] = not MY_ChatMonitor.tChannels[szChannel]
                    _C.RegisterMsgMonitor()
                end, MY_ChatMonitor.tChannels)
                table.insert(t, { bDevide = true })
                table.insert(t,{
                    szOption = _L['timestrap format'], {
                        szOption = '[hh:mm:ss]',
                        fnAction = function()
                            MY_ChatMonitor.szTimestrap = '[hh:mm:ss]'
                        end,
                        bCheck = true, bMCheck = true,
                        bChecked = MY_ChatMonitor.szTimestrap == '[hh:mm:ss]'
                    }, {
                        szOption = '[MM/dd hh:mm:ss]',
                        fnAction = function()
                            MY_ChatMonitor.szTimestrap = '[MM/dd hh:mm:ss]'
                        end,
                        bCheck = true, bMCheck = true,
                        bChecked = MY_ChatMonitor.szTimestrap == '[MM/dd hh:mm:ss]'
                    }, {
                        szOption = _L['custom'],
                        fnAction = function()
                            GetUserInput(_L['custom timestrap (eg:[yyyy/MM/dd_hh:mm:ss])'], function(szText)
                                MY_ChatMonitor.szTimestrap = szText
                            end, nil, nil, nil, MY_ChatMonitor.szTimestrap)
                        end,
                    },
                })
                table.insert(t,{
                    szOption = _L['max record count'],
                    fnAction = function()
                        GetUserInputNumber(MY_ChatMonitor.nMaxRecord, 1000, nil, function(val)
                            MY_ChatMonitor.nMaxRecord = val or MY_ChatMonitor.nMaxRecord
                        end, nil, function() return not LIB.IsPanelVisible() end)
                    end,
                })
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
                if IsCtrlKeyDown() then
                    -- table.insert(t, {
                    --     szOption = _L['Realtime save'],
                    --     fnAction = function()
                    --         MY_ChatMonitor.bRealtimeSave = not MY_ChatMonitor.bRealtimeSave
                    --     end,
                    --     bCheck = true,
                    --     bChecked = MY_ChatMonitor.bRealtimeSave
                    -- })
                    table.insert(t, {
                        szOption = _L['Distinct server'],
                        fnAction = function()
                            MY_ChatMonitor.bDistinctServer = not MY_ChatMonitor.bDistinctServer
                            D.LoadData()
                            LIB.SwitchTab('MY_ChatMonitor', true)
                        end,
                        bCheck = true,
                        bChecked = MY_ChatMonitor.bDistinctServer
                    })
                end
                if MY_Chat then
                    table.insert(t,{
                        szOption = _L['hide blockwords'],
                        fnAction = function()
                            MY_ChatMonitor.bBlockWords = not MY_ChatMonitor.bBlockWords
                        end,
                        bCheck = true,
                        bChecked = MY_ChatMonitor.bBlockWords, {
                            szOption = _L['edit'],
                            fnAction = function()
                                LIB.SwitchTab('MY_ChatBlock')
                            end,
                        }
                    })
                end
                table.insert(t, { bDevide = true })
                table.insert(t,{
                    szOption = _L['regular expression'],
                    fnAction = function()
                        if MY_ChatMonitor.bIsRegexp then
                            MY_ChatMonitor.bIsRegexp = not MY_ChatMonitor.bIsRegexp
                        else
                            MessageBox({
                                szName = 'MY_ChatMonitor_Regexp',
                                szMessage = _L['Are you sure you want to turn on regex mode?\nRegex is something advanced, make sure you know what you are doing.'],
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
        end,
    })

    ui:append('WndButton', {
        name = 'Button_ChatMonitor_Switcher',
        x = w - 136, y = 15, w = 50,
        text = (MY_ChatMonitor.bCapture and _L['stop']) or _L['start'],
        onclick = function()
            if MY_ChatMonitor.bCapture then
                UI(this):text(_L['start'])
                MY_ChatMonitor.bCapture = false
            else
                UI(this):text(_L['stop'])
                MY_ChatMonitor.bCapture = true
            end
        end,
    })

    ui:append('WndButton', {
        x = w - 81, y = 15, w = 50,
        text = _L['clear'],
        onclick = function()
            RECORD_LIST = {}
            RECORD_HASH = {}
            _C.uiBoard:clear()
        end,
    })

    _C.uiBoard = ui:append('WndScrollBox', {
        name = 'WndScrollBox_TalkList',
        x = 20, y = 50, w = w - 21, h = h - 70, handlestyle = 3,
    }, true)

    for i = 1, #RECORD_LIST, 1 do
        _C.uiBoard:append(D.GetHTML(RECORD_LIST[i]))
    end
    _C.uiBoard:scroll(100)
    _C.ui = UI(wnd)
    _C.Init()
end

_C.Init = function()
    if _C.bInited then
        return
    end
    _C.bInited = true
    _C.RegisterMsgMonitor()
end
LIB.RegisterInit('MY_CHATMONITOR', _C.Init)

_C.RegisterMsgMonitor = function()
    local t = {}
    for szChannel, bCapture in pairs(MY_ChatMonitor.tChannels) do
        if bCapture then table.insert(t, szChannel) end
    end
    UnRegisterMsgMonitor(_C.OnMsgArrive)
    RegisterMsgMonitor(_C.OnMsgArrive, t)
end

LIB.RegisterHotKey('MY_ChatMonitor_Hotkey', _L['chat monitor'],
    function()
        if MY_ChatMonitor.bCapture then
            UI(LIB.GetFrame()):find('#Button_ChatMonitor_Switcher'):text(_L['start'])
            MY_ChatMonitor.bCapture = false
        else
            UI(LIB.GetFrame()):find('#Button_ChatMonitor_Switcher'):text(_L['stop'])
            MY_ChatMonitor.bCapture = true
        end
    end
, nil)

LIB.RegisterPanel('MY_ChatMonitor', _L['chat monitor'], _L['Chat'], 'UI/Image/Minimap/Minimap.UITex|197', {
    OnPanelActive = _C.OnPanelActive,
    OnPanelDeactive = function()
        _C.uiBoard = nil
    end
})
