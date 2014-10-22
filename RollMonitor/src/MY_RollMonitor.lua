local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."RollMonitor/lang/")
MY_RollMonitor = { nMode = 1, nPublish = 0, nPublishChannel = PLAYER_TALK_CHANNEL.RAID, bPublishRestart = true }
MY_RollMonitor.SortType = {
    FIRST = 1,  -- 只记录第一次
    LAST  = 2,  -- 只记录最后一次
    MAX   = 3,  -- 多次摇点取最高点
    MIN   = 4,  -- 多次摇点取最低点
    AVG   = 5,  -- 多次摇点取平均值
    AVG2  = 6,  -- 去掉最高最低取平均值
}
RegisterCustomData('MY_RollMonitor.nMode')
RegisterCustomData('MY_RollMonitor.nPublish')
RegisterCustomData('MY_RollMonitor.bPublishRestart')
RegisterCustomData('MY_RollMonitor.nPublishChannel')
local _MY_RollMonitor = {
    uiTextBoard = nil,
    aRecords = {},
    aMode = {
        [1] = { szID = 'nFirst', szName = _L['only first score'           ] },    -- 只记录第一次
        [2] = { szID = 'nLast' , szName = _L['only last score'            ] },    -- 只记录最后一次
        [3] = { szID = 'nMax'  , szName = _L['highest score'              ] },    -- 多次摇点取最高点
        [4] = { szID = 'nMin'  , szName = _L['lowest score'               ] },    -- 多次摇点取最低点
        [5] = { szID = 'nAvg'  , szName = _L['average score'              ] },    -- 多次摇点取平均值
        [6] = { szID = 'nAvg2' , szName = _L['average score with out pole'] },    -- 去掉最高最低取平均值
    },
    tChannels = {
        { nChannel = PLAYER_TALK_CHANNEL.TEAM  , szName = _L['team channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.RAID  , szName = _L['raid channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.TONG  , szName = _L['tong channel']  , rgb = GetMsgFontColor("MSG_GUILD" , true) },
    }
}
-- 事件响应处理
--[[ 打开面板
    (void) MY_RollMonitor.OpenPanel()
]]
MY_RollMonitor.OpenPanel = function()
    MY.OpenPanel()
    MY.ActivePanel('RollMonitor')
end
--[[ 清空ROLL点
     (void) MY_RollMonitor.Clear([settings])
        (array) settings : 参数键值对，所有参数都是可选的，默认读取用户设置。
          (boolean) echo       : 是否发送重新开始聊天消息
          (number)  channel    : 发送频道
]]
MY_RollMonitor.Clear = function(param)
    param = param or {}
    if type(param.echo) == 'nil' then
        param.echo = MY_RollMonitor.bPublishRestart
    end
    param.channel = param.channel or MY_RollMonitor.nPublishChannel
    
    _MY_RollMonitor.aRecords = {}
    _MY_RollMonitor.RedrawBoard()
    if param.echo then
        MY.Talk(param.channel, _L['----------- roll restart -----------']..'\n')
    end
end
--[[ 获得排序结果
]]
MY_RollMonitor.GetResult = function(sortType)
    sortType = sortType or MY_RollMonitor.nMode
    local t = {}
    for _, aRecord in pairs(_MY_RollMonitor.aRecords) do
        table.insert(t, { szName = aRecord.szName, nRoll = aRecord[_MY_RollMonitor.aMode[sortType].szID], nCount = #aRecord })
    end
    table.sort(t, function(v1, v2) return v1.nRoll > v2.nRoll end)
    return t
end
--[[ 发布ROLL点
     (void) MY_RollMonitor.Echo([settings])
        (array) settings : 参数键值对，所有参数都是可选的，默认读取用户设置。
          (enum)    sortType   : 排序方式 枚举 MY_RollMonitor.SortType
          (number)  limit      : 最大显示条数限制
          (number)  channel    : 发送频道
          (boolean) showUnroll : 是否显示未ROLL点
]]
MY_RollMonitor.Echo = function(param)
    param = param or {}
    param.sortType = param.sortType or MY_RollMonitor.nMode
    param.limit    = param.limit    or MY_RollMonitor.nPublish
    param.channel  = param.channel  or MY_RollMonitor.nPublishChannel
    if type(param.showUnroll) == 'nil' then param.showUnroll = MY_RollMonitor.bPublishUnroll end

    MY.Talk(param.channel, string.format('[%s][%s]%s\n',_L['mingyi plugin'],_L["roll monitor"],_MY_RollMonitor.aMode[param.sortType].szName), true)
    MY.Talk(param.channel, _L['-------------------------------']..'\n')
    for i, aRecord in ipairs(MY_RollMonitor.GetResult(param.sortType)) do
        if param.limit > 0 and i > param.limit then break end
        MY.Talk(param.channel, _L( '[%s] rolls for %d times, valid score is %s.', aRecord.szName, aRecord.nCount, string.gsub(aRecord.nRoll, '(%d+%.%d%d)%d+','%1')) .. '\n' )
    end
    local team = GetClientTeam()
    if team and param.showUnroll then
        local szUnrolledNames = ''
        for _, dwID in ipairs(team.GetTeamMemberList()) do
            local szName, bUnRoll = team.GetClientTeamMemberName(dwID), true
            for _, aRecord in ipairs(_MY_RollMonitor.aRecords) do
                if aRecord.szName == szName then
                    bUnRoll = false
                end
            end
            if bUnRoll then szUnrolledNames = szUnrolledNames .. '[' .. szName .. ']' end
        end
        if szUnrolledNames~='' then
            MY.Talk(param.channel, szUnrolledNames .. _L["haven't roll yet."]..'\n')
        end
    end
    MY.Talk(param.channel, _L['-------------------------------']..'\n')
end

-- 标签激活响应函数
_MY_RollMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    -- 记录模式
    ui:append('WndCombo_RecordType','WndComboBox'):children('#WndCombo_RecordType'):text(_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szName):pos(20,20):width(180):menu(function()
        local t = {}
        for iMode, tMode in ipairs(_MY_RollMonitor.aMode) do
            table.insert( t, { 
                szOption = tMode.szName,
                fnAction = function()
                    MY_RollMonitor.nMode = iMode
                    _MY_RollMonitor.RedrawBoard()
                    table.sort(_MY_RollMonitor.aRecords,function(v1,v2)return v1[tMode.szID] > v2[tMode.szID] end)
                    ui:children('#WndCombo_RecordType'):text(tMode.szName)
                end
            } )
        end
        return t
    end)
    -- 清空
    ui:append('WndButton_Clear','WndButton'):children('#WndButton_Clear'):text(_L['restart']):pos(w-196,20):width(90):lclick(function(nButton)
        MY_RollMonitor.Clear()
    end):rmenu(function()
        local t = { {
            szOption = _L['publish while restart'], 
            bCheck = true, bMCheck = false, bChecked = MY_RollMonitor.bPublishRestart,
            fnAction = function() MY_RollMonitor.bPublishRestart = not MY_RollMonitor.bPublishRestart end,
        }, { bDevide = true } }
        for _, tChannel in ipairs(_MY_RollMonitor.tChannels) do
            table.insert( t, { 
                szOption = tChannel.szName,
                rgb = tChannel.rgb,
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublishChannel == tChannel.nChannel,
                fnAction = function()
                    MY_RollMonitor.nPublishChannel = tChannel.nChannel
                end
            } )
        end
        return t
    end):tip(_L['left click to restart, right click to open setting.'], MY.Const.UI.Tip.POS_TOP)
    -- 发布
    ui:append('WndButton_Publish','WndButton'):children('#WndButton_Publish'):text(_L['publish']):pos(w-106,20):width(80):rmenu(function()
        local t = { {
            szOption = _L['publish setting'], {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 3,
                fnAction = function() MY_RollMonitor.nPublish = 3 end,
                szOption = _L('publish top %d', 3)
            }, {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 5,
                fnAction = function() MY_RollMonitor.nPublish = 5 end,
                szOption = _L('publish top %d', 5)
            }, {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 10,
                fnAction = function() MY_RollMonitor.nPublish = 10 end,
                szOption = _L('publish top %d', 10)
            }, {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 0,
                fnAction = function() MY_RollMonitor.nPublish = 0 end,
                szOption = _L['publish all']
            }, { bDevide = true }, {
                bCheck = true, bChecked = MY_RollMonitor.bPublishUnroll,
                fnAction = function() MY_RollMonitor.bPublishUnroll = not MY_RollMonitor.bPublishUnroll end,
                szOption = _L['publish unroll']
            }
        }, { bDevide = true } }
        for _, tChannel in ipairs(_MY_RollMonitor.tChannels) do
            table.insert( t, { 
                szOption = tChannel.szName,
                rgb = tChannel.rgb,
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublishChannel == tChannel.nChannel,
                fnAction = function()
                    MY_RollMonitor.nPublishChannel = tChannel.nChannel
                end
            } )
        end
        return t
    end):lclick(function()
        MY_RollMonitor.Echo()
    end):tip(_L['left click to publish, right click to open setting.'], MY.Const.UI.Tip.POS_TOP, { x = -80 })
    -- 输出板
    ui:append('WndScrollBox_Record','WndScrollBox'):children('#WndScrollBox_Record'):handleStyle(3):pos(20,50):size(w-46,400):text(_L['去掉最高最低取平均值']):append('Text_Default','Text'):find('#Text_Default')
    _MY_RollMonitor.uiBoard = ui:children('#WndScrollBox_Record')
    _MY_RollMonitor.RedrawBoard()
end
_MY_RollMonitor.OnPanelDeactive = function()
    MY.BreatheCall('MY_RollMonitorRedraw')
    _MY_RollMonitor.uiBoard = nil
end
-- 重绘窗口
_MY_RollMonitor.RedrawBoard = function()
    if _MY_RollMonitor.uiBoard then
        local szHTML = ''
        for _, aRecord in ipairs(MY_RollMonitor.GetResult()) do
            szHTML = szHTML ..
                MY.Chat.GetCopyLinkText() ..
                GetFormatText('['..aRecord.szName..']', nil, nil, nil, nil, 515, nil, 'namelink_0') ..
                GetFormatText(_L( ' rolls for %d times, valid score is %s.', aRecord.nCount, (string.gsub(aRecord.nRoll,'(%d+%.%d%d)%d+','%1')) ) .. '\n')
        end
        local team = GetClientTeam()
        if team then
            local szUnrolledNames = ''
            for _, dwID in ipairs(team.GetTeamMemberList()) do
                local szName, bUnRoll = team.GetClientTeamMemberName(dwID), true
                for _, aRecord in ipairs(_MY_RollMonitor.aRecords) do
                    if aRecord.szName == szName then
                        bUnRoll = false
                    end
                end
                if bUnRoll then
                    szUnrolledNames = szUnrolledNames .. GetFormatText('['..szName..']', nil, nil, nil, nil, 515, nil, 'namelink_0')
                end
            end
            if szUnrolledNames~='' then
                szHTML = szHTML ..
                MY.Chat.GetCopyLinkText() ..
                szUnrolledNames .. GetFormatText(_L["haven't roll yet."])
            end
        end
        szHTML = MY.Chat.RenderLink(szHTML)
        if MY_Farbnamen and MY_Farbnamen.Render then
            szHTML = MY_Farbnamen.Render(szHTML)
        end
        _MY_RollMonitor.uiBoard:clear():append(szHTML)
    end
end
-- 系统频道监控处理函数
_MY_RollMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
    for szName, nRoll in string.gmatch(szMsg, _L['ROLL_MONITOR_EXP'] ) do
        -- 临时变量
        nRoll = tonumber(nRoll)
        local nTotal, nAvg, nAvg2 = 0
        -- 当前要生成的一个玩家的记录
        local aRecord = {
            szName = szName,
            nFirst = nRoll,
            nMax =   nRoll,
            nMin =   nRoll,
        }
        -- 判断缓存中该玩家是否已存在记录
        for i = 1, #_MY_RollMonitor.aRecords, 1 do
            if _MY_RollMonitor.aRecords[i].szName == szName then
                aRecord = _MY_RollMonitor.aRecords[i]
                break
            end
        end
        -- 格式化数组 更新各数值
        table.insert(aRecord, nRoll)
        table.sort(aRecord)
        local nTotal = 0
        for i = 1, #aRecord, 1 do
            nTotal = nTotal + aRecord[i]
        end
        aRecord.nAvg = nTotal / #aRecord
        if #aRecord > 2 then
            aRecord.nAvg2 = (nTotal - aRecord[1] - aRecord[#aRecord]) / (#aRecord - 2)
        else
            aRecord.nAvg2 = aRecord.nAvg
        end
        aRecord.nLast = nRoll
        if aRecord.nMax < nRoll then aRecord.nMax = nRoll end
        if aRecord.nMin > nRoll then aRecord.nMin = nRoll end
        -- 将数组写回记录缓存
        for i = #_MY_RollMonitor.aRecords, 1, -1 do
            if _MY_RollMonitor.aRecords[i].szName == szName then
                table.remove(_MY_RollMonitor.aRecords, i)
            end
        end
        table.insert(_MY_RollMonitor.aRecords, aRecord)
        _MY_RollMonitor.RedrawBoard()
    end
end
-- 注册系统频道监控
_MY_RollMonitor.RegisterMsgMonitor = function()
    local t = {'MSG_SYS'}
    UnRegisterMsgMonitor(_MY_RollMonitor.OnMsgArrive)
    RegisterMsgMonitor(_MY_RollMonitor.OnMsgArrive, t)
end
_MY_RollMonitor.RegisterMsgMonitor()
MY.RegisterPanel( "RollMonitor", _L["roll monitor"], "UI/Image/UICommon/LoginCommon.UITex|30", {255,255,0,200}, { OnPanelActive = _MY_RollMonitor.OnPanelActive, OnPanelDeactive = _MY_RollMonitor.OnPanelDeactive } )