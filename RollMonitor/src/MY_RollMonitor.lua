local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."RollMonitor/lang/")
MY_RollMonitor = { nMode = 1, nPublish = 0, nPublishChannel = PLAYER_TALK_CHANNEL.RAID, bPublishRestart = true }
MY_RollMonitor.SortType = {
    FIRST = 1,  -- ֻ��¼��һ��
    LAST  = 2,  -- ֻ��¼���һ��
    MAX   = 3,  -- ���ҡ��ȡ��ߵ�
    MIN   = 4,  -- ���ҡ��ȡ��͵�
    AVG   = 5,  -- ���ҡ��ȡƽ��ֵ
    AVG2  = 6,  -- ȥ��������ȡƽ��ֵ
}
RegisterCustomData('MY_RollMonitor.nMode')
RegisterCustomData('MY_RollMonitor.nPublish')
RegisterCustomData('MY_RollMonitor.bPublishRestart')
RegisterCustomData('MY_RollMonitor.nPublishChannel')
local _MY_RollMonitor = {
    uiTextBoard = nil,
    aRecords = {},
    aMode = {
        [1] = { szID = 'nFirst', szName = _L['only first score'           ] },    -- ֻ��¼��һ��
        [2] = { szID = 'nLast' , szName = _L['only last score'            ] },    -- ֻ��¼���һ��
        [3] = { szID = 'nMax'  , szName = _L['highest score'              ] },    -- ���ҡ��ȡ��ߵ�
        [4] = { szID = 'nMin'  , szName = _L['lowest score'               ] },    -- ���ҡ��ȡ��͵�
        [5] = { szID = 'nAvg'  , szName = _L['average score'              ] },    -- ���ҡ��ȡƽ��ֵ
        [6] = { szID = 'nAvg2' , szName = _L['average score with out pole'] },    -- ȥ��������ȡƽ��ֵ
    },
    tChannels = {
        { nChannel = PLAYER_TALK_CHANNEL.TEAM  , szName = _L['team channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.RAID  , szName = _L['raid channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.TONG  , szName = _L['tong channel']  , rgb = GetMsgFontColor("MSG_GUILD" , true) },
    }
}
-- �¼���Ӧ����
--[[ �����
    (void) MY_RollMonitor.OpenPanel()
]]
MY_RollMonitor.OpenPanel = function()
    MY.OpenPanel()
    MY.SwitchTab('RollMonitor')
end
--[[ ���ROLL��
     (void) MY_RollMonitor.Clear([settings])
        (array) settings : ������ֵ�ԣ����в������ǿ�ѡ�ģ�Ĭ�϶�ȡ�û����á�
          (boolean) echo       : �Ƿ������¿�ʼ������Ϣ
          (number)  channel    : ����Ƶ��
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
--[[ ���������
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
--[[ ����ROLL��
     (void) MY_RollMonitor.Echo([settings])
        (array) settings : ������ֵ�ԣ����в������ǿ�ѡ�ģ�Ĭ�϶�ȡ�û����á�
          (enum)    sortType   : ����ʽ ö�� MY_RollMonitor.SortType
          (number)  limit      : �����ʾ��������
          (number)  channel    : ����Ƶ��
          (boolean) showUnroll : �Ƿ���ʾδROLL��
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

-- ��ǩ������Ӧ����
_MY_RollMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    -- ��¼ģʽ
    ui:append("WndComboBox", "WndCombo_RecordType"):children('#WndCombo_RecordType')
      :pos(20, 10):width(180):text(_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szName)
      :menu(function()
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
    -- ���
    ui:append("WndButton", "WndButton_Clear"):children('#WndButton_Clear')
      :pos(w-176, 10):width(90):text(_L['restart'])
      :lclick(function(nButton)
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
    -- ����
    ui:append("WndButton", "WndButton_Publish"):children('#WndButton_Publish')
      :pos(w-86, 10):width(80):text(_L['publish'])
      :rmenu(function()
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
    -- �����
    _MY_RollMonitor.uiBoard = ui
      :append("WndScrollBox", "WndScrollBox_Record"):children('#WndScrollBox_Record')
      :pos(20, 40):size(w-26, h-60):handleStyle(3)
      :text(_L['average score with out pole'])
    
    _MY_RollMonitor.RedrawBoard()
end
_MY_RollMonitor.OnPanelDeactive = function()
    MY.BreatheCall('MY_RollMonitorRedraw')
    _MY_RollMonitor.uiBoard = nil
end
-- �ػ洰��
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
-- ϵͳƵ����ش�����
_MY_RollMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
    for szName, nRoll in string.gmatch(szMsg, _L['ROLL_MONITOR_EXP'] ) do
        -- ��ʱ����
        nRoll = tonumber(nRoll)
        local nTotal, nAvg, nAvg2 = 0
        -- ��ǰҪ���ɵ�һ����ҵļ�¼
        local aRecord = {
            szName = szName,
            nFirst = nRoll,
            nMax =   nRoll,
            nMin =   nRoll,
        }
        -- �жϻ����и�����Ƿ��Ѵ��ڼ�¼
        for i = 1, #_MY_RollMonitor.aRecords, 1 do
            if _MY_RollMonitor.aRecords[i].szName == szName then
                aRecord = _MY_RollMonitor.aRecords[i]
                break
            end
        end
        -- ��ʽ������ ���¸���ֵ
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
        -- ������д�ؼ�¼����
        for i = #_MY_RollMonitor.aRecords, 1, -1 do
            if _MY_RollMonitor.aRecords[i].szName == szName then
                table.remove(_MY_RollMonitor.aRecords, i)
            end
        end
        table.insert(_MY_RollMonitor.aRecords, aRecord)
        _MY_RollMonitor.RedrawBoard()
    end
end
-- ע��ϵͳƵ�����
_MY_RollMonitor.RegisterMsgMonitor = function()
    local t = {'MSG_SYS'}
    UnRegisterMsgMonitor(_MY_RollMonitor.OnMsgArrive)
    RegisterMsgMonitor(_MY_RollMonitor.OnMsgArrive, t)
end
_MY_RollMonitor.RegisterMsgMonitor()
MY.RegisterPanel( "RollMonitor", _L["roll monitor"], _L['General'], "UI/Image/UICommon/LoginCommon.UITex|30", {255,255,0,200}, { OnPanelActive = _MY_RollMonitor.OnPanelActive, OnPanelDeactive = _MY_RollMonitor.OnPanelDeactive } )
