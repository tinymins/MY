--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天监控 按关键字过滤获取聊天消息
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ChatMonitor'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatMonitor'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------
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
MY_ChatMonitor.bIgnoreSame         = false
-- MY_ChatMonitor.bRealtimeSave       = false
MY_ChatMonitor.bDistinctServer     = false
MY_ChatMonitor.szTimestrap         = '[%hh:%mm:%ss]'
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
RegisterCustomData('MY_ChatMonitor.tChannels')
RegisterCustomData('MY_ChatMonitor.bPlaySound')
RegisterCustomData('MY_ChatMonitor.bRedirectSysChannel')
RegisterCustomData('MY_ChatMonitor.anchor')
RegisterCustomData('MY_ChatMonitor.bIgnoreSame', 1)
-- RegisterCustomData('MY_ChatMonitor.bRealtimeSave')
RegisterCustomData('MY_ChatMonitor.bDistinctServer')
RegisterCustomData('MY_ChatMonitor.szTimestrap', 1)
_C.bInited = false
_C.ui = nil
_C.uiBoard = nil
_C.szLuaData = 'config/chatmonitor.jx3dat'
do local SZ_OLD_PATH = LIB.FormatPath('config/MY_CHATMONITOR/cfg_{$lang}.jx3dat')
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
LIB.RegisterFlush(D.SaveData)

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
    html = LIB.GetTimeLinkText(rec.time, {
        r = rec.r, g = rec.g, b = rec.b,
        f = rec.font, s = MY_ChatMonitor.szTimestrap,
    }) .. html
    return html
end

function D.OnNotifyCB()
    LIB.ShowPanel()
    LIB.FocusPanel()
    LIB.SwitchTab('MY_ChatMonitor')
    LIB.DismissNotify('MY_ChatMonitor')
end

-- 插入聊天内容时监控聊天信息
_C.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
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
        local szChannelName = g_tStrings.tChannelName[szChannel]
        if szChannelName then
            rec.text = '[' .. szChannelName .. ']\t' .. rec.text
        end
        rec.text = StringLowerW(rec.text)
    end
    rec.hash = gsub(rec.hash, '[\n%s]+', '')
    --------------------------------------------------------------------------------------
    -- 开始计算是否符合过滤器要求
    if MY_ChatMonitor.bIsRegexp then -- regexp
        if not find(rec.text, MY_ChatMonitor.szKeyWords) then
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
    OutputMessage('MSG_MY_MONITOR', szMsg, true, nil, nil, dwTalkerID, szName)
    -- 更新UI
    if _C.uiBoard then
        local nPos = _C.uiBoard:Scroll()
        _C.uiBoard:Append(html)
        if nPos == 100 or nPos == -1 then
            _C.uiBoard:Scroll(100)
        end
    end
    LIB.CreateNotify({
        szKey = 'MY_ChatMonitor',
        szMsg = html,
        fnAction = D.OnNotifyCB,
        bPlaySound = MY_ChatMonitor.bPlaySound,
        szSound = PACKET_INFO.ROOT .. 'MY_ChatMonitor/audio/MsgArrive.ogg',
        szCustomSound = 'MsgArrive.ogg',
        bPopupPreview = MY_ChatMonitor.bShowPreview,
    })
    --------------------------------------------------------------------------------------
    -- 开始处理记录的数据保存
    -- 更新缓存数组 哈希表
    insert(RECORD_LIST, rec)
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
                _C.uiBoard:RemoveItemUntilNewLine()
            end
            remove(RECORD_LIST, 1)
        end
    end
    -- if MY_ChatMonitor.bRealtimeSave then
    --     D.SaveData()
    -- end
end

_C.OnPanelActive = function(wnd)
    local ui = UI(wnd)
    local w, h = ui:Size()

    ui:Append('Text', { x = 22, y = 15, w = 100, h = 25, text = _L['key words:'] })

    ui:Append('WndAutocomplete', {
        x = 80, y = 15, w = w - 226, h = 25, text = MY_ChatMonitor.szKeyWords,
        onchange = function(szText) MY_ChatMonitor.szKeyWords = szText end,
        onfocus = function(self)
            local source = {}
            for _, szOpt in ipairs(LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}) do
                if type(szOpt) == 'string' then
                    insert(source, szOpt)
                end
            end
            self:Autocomplete('option', 'source', source)
        end,
        onclick = function()
            if IsPopupMenuOpened() then
                UI(this):Autocomplete('close')
            else
                local source = {}
                for _, szOpt in ipairs(LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}) do
                    if type(szOpt) == 'string' then
                        insert(source, szOpt)
                    end
                end
                UI(this):Autocomplete('option', 'source', source)
                UI(this):Autocomplete('search', '')
            end
        end,
        autocomplete = {
            -- { 'option', 'beforeSearch', function(raw, option, text) end },
            {
                'option', 'beforePopup', function(wnd, option, text, menu)
                    if #menu > 0 then
                        insert(menu, { bDevide = true })
                    end
                    insert(menu, { szOption = _L['add'], fnAction = function()
                        GetUserInput('', function(szVal)
                            szVal = (gsub(szVal, '^%s*(.-)%s*$', '%1'))
                            if szVal~='' then
                                local t = LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}
                                for i = #t, 1, -1 do
                                    if t[i] == szVal then return end
                                end
                                insert(t, szVal)
                                LIB.SaveLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}, t)
                            end
                        end, function() end, function() end, nil, UI(wnd):Text() )
                    end })
                end,
            },
            {
                'option', 'beforeDelete', function(szOption, fnDoDelete, option)
                    local t = LIB.LoadLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}) or {}
                    for i = #t, 1, -1 do
                        if t[i] == szOption then
                            remove(t, i)
                        end
                    end
                    LIB.SaveLUAData({_C.szLuaData, PATH_TYPE.GLOBAL}, t)
                end,
            },
        },
    })

    ui:Append('Image', {
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

    ui:Append('WndButton', {
        x = w - 26, y = 15, w = 25, h = 25,
        buttonstyle = 'OPTION',
        -- onhover = function(bIn) this:SetAlpha((bIn and 255) or 200) end,
        menu = function()
            local t = LIB.GetChatChannelMenu(function(szChannel)
                MY_ChatMonitor.tChannels[szChannel] = not MY_ChatMonitor.tChannels[szChannel]
                _C.RegisterMsgMonitor()
            end, MY_ChatMonitor.tChannels)
            insert(t, { bDevide = true })
            insert(t,{
                szOption = _L['timestrap format'], {
                    szOption = '[%hh:%mm:%ss]',
                    fnAction = function()
                        MY_ChatMonitor.szTimestrap = '[%hh:%mm:%ss]'
                    end,
                    bCheck = true, bMCheck = true,
                    bChecked = MY_ChatMonitor.szTimestrap == '[%hh:%mm:%ss]'
                }, {
                    szOption = '[%MM/%dd %hh:%mm:%ss]',
                    fnAction = function()
                        MY_ChatMonitor.szTimestrap = '[%MM/%dd %hh:%mm:%ss]'
                    end,
                    bCheck = true, bMCheck = true,
                    bChecked = MY_ChatMonitor.szTimestrap == '[%MM/%dd %hh:%mm:%ss]'
                }, {
                    szOption = _L['custom'],
                    fnAction = function()
                        GetUserInput(_L['custom timestrap (eg:[%yyyy/%MM/%dd_%hh:%mm:%ss])'], function(szText)
                            MY_ChatMonitor.szTimestrap = szText
                        end, nil, nil, nil, MY_ChatMonitor.szTimestrap)
                    end,
                },
            })
            insert(t,{
                szOption = _L['max record count'],
                fnAction = function()
                    GetUserInputNumber(MY_ChatMonitor.nMaxRecord, 1000, nil, function(val)
                        MY_ChatMonitor.nMaxRecord = val or MY_ChatMonitor.nMaxRecord
                    end, nil, function() return not LIB.IsPanelVisible() end)
                end,
            })
            insert(t,{
                szOption = _L['show message preview box'],
                fnAction = function()
                    MY_ChatMonitor.bShowPreview = not MY_ChatMonitor.bShowPreview
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bShowPreview
            })
            insert(t,{
                szOption = _L['play new message alert sound'],
                fnAction = function()
                    MY_ChatMonitor.bPlaySound = not MY_ChatMonitor.bPlaySound
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bPlaySound
            })
            insert(t,{
                szOption = _L['output to system channel'],
                fnAction = function()
                    MY_ChatMonitor.bRedirectSysChannel = not MY_ChatMonitor.bRedirectSysChannel
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bRedirectSysChannel
            })
            insert(t,{
                szOption = _L['ignore same message'],
                fnAction = function()
                    MY_ChatMonitor.bIgnoreSame = not MY_ChatMonitor.bIgnoreSame
                end,
                bCheck = true,
                bChecked = MY_ChatMonitor.bIgnoreSame
            })
            if IsCtrlKeyDown() then
                -- insert(t, {
                --     szOption = _L['Realtime save'],
                --     fnAction = function()
                --         MY_ChatMonitor.bRealtimeSave = not MY_ChatMonitor.bRealtimeSave
                --     end,
                --     bCheck = true,
                --     bChecked = MY_ChatMonitor.bRealtimeSave
                -- })
                insert(t, {
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
            insert(t, { bDevide = true })
            insert(t,{
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
        end,
    })

    ui:Append('WndButton', {
        name = 'Button_ChatMonitor_Switcher',
        x = w - 134, y = 15, w = 50,
        text = (MY_ChatMonitor.bCapture and _L['stop']) or _L['start'],
        onclick = function()
            if MY_ChatMonitor.bCapture then
                UI(this):Text(_L['start'])
                MY_ChatMonitor.bCapture = false
            else
                UI(this):Text(_L['stop'])
                MY_ChatMonitor.bCapture = true
            end
        end,
    })

    ui:Append('WndButton', {
        x = w - 79, y = 15, w = 50,
        text = _L['clear'],
        onclick = function()
            RECORD_LIST = {}
            RECORD_HASH = {}
            _C.uiBoard:Clear()
        end,
    })

    _C.uiBoard = ui:Append('WndScrollBox', {
        name = 'WndScrollBox_TalkList',
        x = 20, y = 50, w = w - 21, h = h - 70, handlestyle = 3,
    })

    for i = 1, #RECORD_LIST, 1 do
        _C.uiBoard:Append(D.GetHTML(RECORD_LIST[i]))
    end
    _C.uiBoard:Scroll(100)
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
        if bCapture then insert(t, szChannel) end
    end
    UnRegisterMsgMonitor(_C.OnMsgArrive)
    RegisterMsgMonitor(_C.OnMsgArrive, t)
end

LIB.RegisterHotKey('MY_ChatMonitor_Hotkey', _L['chat monitor'],
    function()
        if MY_ChatMonitor.bCapture then
            UI(LIB.GetFrame()):Find('#Button_ChatMonitor_Switcher'):Text(_L['start'])
            MY_ChatMonitor.bCapture = false
        else
            UI(LIB.GetFrame()):Find('#Button_ChatMonitor_Switcher'):Text(_L['stop'])
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
