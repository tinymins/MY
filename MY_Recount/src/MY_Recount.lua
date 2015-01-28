--
-- ս��ͳ��
-- by ���� @ ˫���� @ ݶ����
-- Build 20140730
-- 
local CHANNEL = { -- ͳ������
    DPS  = 1, -- ���ͳ��
    HPS  = 2, -- ����ͳ��
    BDPS = 3, -- ����ͳ��
    BHPS = 4, -- ����ͳ��
}
local SZ_CHANNEL_KEY = { -- ͳ������������
    [CHANNEL.DPS ] = 'Damage',
    [CHANNEL.HPS ] = 'Heal',
    [CHANNEL.BDPS] = 'BeDamage',
    [CHANNEL.BHPS] = 'BeHeal',
}
local SZ_CHANNEL = {
    [CHANNEL.DPS ] = g_tStrings.STR_DAMAGE_STATISTIC    , -- �˺�ͳ��
    [CHANNEL.HPS ] = g_tStrings.STR_THERAPY_STATISTIC   , -- ����ͳ��
    [CHANNEL.BDPS] = g_tStrings.STR_BE_DAMAGE_STATISTIC , -- ����ͳ��
    [CHANNEL.BHPS] = g_tStrings.STR_BE_THERAPY_STATISTIC, -- ����ͳ��
}
local DISPLAY_MODE = { -- ͳ����ʾ
    NPC    = 1, -- ֻ��ʾNPC
    PLAYER = 2, -- ֻ��ʾ���
    BOTH   = 3, -- �����ʾ
}
local PUBLISH_MODE = {
    EFFECT = 1, -- ֻ��ʾ��Чֵ
    TOTAL  = 2, -- ֻ��ʾ����ֵ
    BOTH   = 3, -- ͬʱ��ʾ��Ч������
}
local SKILL_RESULT = {
    HIT     = 0, -- ����
    BLOCK   = 1, -- ��
    SHIELD  = 2, -- ��Ч
    MISS    = 3, -- ƫ��
    DODGE   = 4, -- ����
    CRITICAL= 5, -- ����
    INSIGHT = 6, -- ʶ��
}
local SZ_SKILL_RESULT = {
    [SKILL_RESULT.HIT     ] = g_tStrings.STR_HIT_NAME     ,
    [SKILL_RESULT.BLOCK   ] = g_tStrings.STR_IMMUNITY_NAME,
    [SKILL_RESULT.SHIELD  ] = g_tStrings.STR_SHIELD_NAME  ,
    [SKILL_RESULT.MISS    ] = g_tStrings.STR_MSG_MISS     ,
    [SKILL_RESULT.DODGE   ] = g_tStrings.STR_MSG_DODGE    ,
    [SKILL_RESULT.CRITICAL] = g_tStrings.STR_CS_NAME      ,
    [SKILL_RESULT.INSIGHT ] = g_tStrings.STR_MSG_INSIGHT  ,
}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Recount/lang/")
local _Cache = {
    szIniRoot   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/',
    szCssFile   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/style',
    szIniFile   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/Recount.ini',
    szIniDetail = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/ShowDetail.ini',
}

-- �µ�ս������ʱ
MY.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function()
    if not _Cache.bHistoryMode then
        MY_Recount.DisplayData(0)
    end
end)

MY_Recount = MY_Recount or {}
MY_Recount.bEnable       = true                 -- �Ƿ�����
MY_Recount.nCss          = 1                    -- ��ǰ��ʽ��
MY_Recount.nChannel      = CHANNEL.DPS          -- ��ǰ��ʾ��ͳ��ģʽ
MY_Recount.bShowPerSec   = true                 -- ��ʾΪÿ�����ݣ���֮��ʾ�ܺͣ�
MY_Recount.bShowEffect   = true                 -- ��ʾ��Ч�˺�/����
MY_Recount.nDisplayMode  = DISPLAY_MODE.BOTH    -- ͳ����ʾģʽ����ʾNPC/������ݣ���Ĭ�ϻ����ʾ��
MY_Recount.nPublishLimit = 30                   -- ����������Ƶ������
MY_Recount.nPublishMode  = PUBLISH_MODE.TOTAL   -- ����ģʽ
MY_Recount.nDrawInterval = GLOBAL.GAME_FPS / 2  -- UI�ػ����ڣ�֡��
MY_Recount.anchor = { x=0, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" } -- Ĭ������
RegisterCustomData("MY_Recount.bEnable")
RegisterCustomData("MY_Recount.nCss")
RegisterCustomData("MY_Recount.nChannel")
RegisterCustomData("MY_Recount.bShowPerSec")
RegisterCustomData("MY_Recount.bShowEffect")
RegisterCustomData("MY_Recount.nDisplayMode")
RegisterCustomData("MY_Recount.nPublishLimit")
RegisterCustomData("MY_Recount.nPublishMode")
RegisterCustomData("MY_Recount.nDrawInterval")
RegisterCustomData("MY_Recount.anchor")

local m_frame
MY_Recount.Open = function()
    -- open
    m_frame = Wnd.OpenWindow(_Cache.szIniFile, 'MY_Recount')
    -- pos
    MY.UI(m_frame):anchor(MY_Recount.anchor)
    -- draw
    MY_Recount.DrawUI()
end

MY_Recount.Close = function()
    Wnd.CloseWindow(m_frame)
end

MY.RegisterInit(function()
    MY_Recount.LoadCustomCss()
    if MY_Recount.bEnable then
        MY_Recount.Open()
    else
        MY_Recount.Close()
    end
end)

--[[
##########################################################################
                              #         #               #             #   
                              #       #   #         #   #             #   
  # #     # # # # # # #     #       #       #       # # # # #   #     #   
    #     #       #       #     # #           #   #     #       #     #   
    #     #       #       # # #     # # # # #     # # # # # # # #     #   
    #     #       #           #                         #       #     #   
    #     #       #         #                       # # # # #   #     #   
    #     #       #       # # #   # # # # # # #     #   #   #   #     #   
    #     #       #                   #             #   #   #   #     #   
      # #     # # # # #       #     #       #       #   #   #         #   
                          # #     # # # # # # #     #   # # #         #   
                                              #         #         # # #   
##########################################################################
]]

MY_Recount.LoadCustomCss = function(nCss)
    if not nCss then
        nCss = MY_Recount.nCss
    else
        MY_Recount.nCss = nCss
    end
    
    _Cache.Css = (MY.LoadLUAData(_Cache.szCssFile, true) or {})[nCss] or {
        Bar = {}
    }
end

--[[ �л�����ʾ��¼
    MY_Recount.DisplayData(number nHistory): ��ʾ��nHistory����ʷ��¼ ��nHistory����0ʱ��ʾ��ǰ��¼
    MY_Recount.DisplayData(table  data): ��ʾ����Ϊdata����ʷ��¼
]]
MY_Recount.DisplayData = function(data)
    if type(data) == 'number' then
        data = MY_Recount.Data.Get(data)
    end
    _Cache.bHistoryMode = (data ~= MY_Recount.Data.Get(0))
    
    if type(data) == 'table' then
        DataDisplay = data
        MY_Recount.DrawUI()
    end
end

MY_Recount.DrawUI = function(data)
    if not data then
        data = DataDisplay
    end
    if not m_frame then
        return
    end

    m_frame:Lookup('Wnd_Title', 'Text_Title'):SetText(SZ_CHANNEL[MY_Recount.nChannel])
    m_frame:Lookup('Wnd_Main', 'Handle_List'):Clear()
    m_frame:Lookup('Wnd_Main', 'Handle_Me').bInited = nil

    MY_Recount.UpdateUI(data)
end

MY_Recount.UpdateUI = function(data)
    if not data then
        data = DataDisplay
    end

    if not m_frame then
        return
    end

    -- ��ȡͳ������
    local tRecord, szUnit
    if MY_Recount.nChannel == CHANNEL.DPS then       -- �˺�ͳ��
        tRecord, szUnit = data.Damage  , 'DPS'
    elseif MY_Recount.nChannel == CHANNEL.HPS then   -- ����ͳ��
        tRecord, szUnit = data.Heal    , 'HPS'
    elseif MY_Recount.nChannel == CHANNEL.BDPS then  -- ����ͳ��
        tRecord, szUnit = data.BeDamage, 'DPS'
    elseif MY_Recount.nChannel == CHANNEL.BHPS then  -- ����ͳ��
        tRecord, szUnit = data.BeHeal  , 'HPS'
    end
    
    -- ����ս��ʱ��
    local nTimeCount = 0
    if data.UUID == MY.Player.GetFightUUID() then
        nTimeCount = MY.Player.GetFightTime() / GLOBAL.GAME_FPS
    else
        nTimeCount = data.nTimeDuring
    end
    local szTimeCount = MY.Sys.FormatTimeCount('M:ss', nTimeCount)
    nTimeCount  = math.max(nTimeCount, 1) -- ��ֹ����DPSʱ����0
    -- �Լ��ļ�¼
    local tMyRec
    
    -- �������� ����Ҫ��ʾ���б�
    local nMaxValue, tResult = 0, {}
    for id, rec in pairs(tRecord) do
        if MY_Recount.nDisplayMode == DISPLAY_MODE.BOTH or  -- ȷ����ʾģʽ����ʾNPC/��ʾ���/ȫ����ʾ��
        (MY_Recount.nDisplayMode == DISPLAY_MODE.NPC    and type(id) == 'string') or
        (MY_Recount.nDisplayMode == DISPLAY_MODE.PLAYER and type(id) == 'number') then
            tRec = {
                id           = id                                    ,
                szMD5        = rec.szMD5                             ,
                szName       = MY_Recount.Data.GetNameAusID(id, data),
                dwForceID    = data.Forcelist[id] or -1              ,
                nValue       = rec.nTotal         or  0              ,
                nEffectValue = rec.nTotalEffect   or  0              ,
            }
            table.insert(tResult, tRec)
            nMaxValue = math.max(nMaxValue, tRec.nValue, tRec.nEffectValue)
        end
    end
    
    -- �б�����
    if MY_Recount.bShowEffect then
        table.sort(tResult, function(p1, p2)
            return p1.nEffectValue > p2.nEffectValue
        end)
    else
        table.sort(tResult, function(p1, p2)
            return p1.nValue > p2.nValue
        end)
    end
    
    -- ��Ⱦ�б�
    local hList = m_frame:Lookup('Wnd_Main', 'Handle_List')
    for i, p in pairs(tResult) do
        -- �Լ��ļ�¼
        if p.id == UI_GetClientPlayerID() then
            tMyRec = {
                id           = p.id          ,
                szMD5        = p.szMD5       ,
                szName       = p.szName      ,
                dwForceID    = p.dwForceID   ,
                nValue       = p.nValue      ,
                nEffectValue = p.nEffectValue,
                nRank        = i             ,
            }
        end
        local hItem = hList:Lookup('Handle_LI_' .. (p.szMD5 or p.id))
        if not hItem then
            hItem = hList:AppendItemFromIni(_Cache.szIniFile, 'Handle_Item')
            hItem:SetName('Handle_LI_' .. (p.szMD5 or p.id))
            if _Cache.Css.Bar[p.dwForceID] then
                hItem:Lookup('Image_PerFore'):FromUITex(unpack(_Cache.Css.Bar[p.dwForceID]))
                hItem:Lookup('Image_PerBack'):FromUITex(unpack(_Cache.Css.Bar[p.dwForceID]))
            end
            hItem.id = p.id
        end
        if hItem:GetIndex() ~= i - 1 then
            hItem:ExchangeIndex(i - 1)
        end
        hItem:Lookup('Text_L'):SetText(string.format('%d.%s', i, p.szName))
        
        if nMaxValue > 0 then
            hItem:Lookup('Image_PerBack'):SetPercentage(p.nValue / nMaxValue)
            hItem:Lookup('Image_PerFore'):SetPercentage(p.nEffectValue / nMaxValue)
        end
        if MY_Recount.bShowEffect then
            if MY_Recount.bShowPerSec then
                hItem:Lookup('Text_R'):SetText(math.floor(p.nEffectValue / nTimeCount) .. ' ' .. szUnit)
            else
                hItem:Lookup('Text_R'):SetText(p.nEffectValue)
            end
        else
            if MY_Recount.bShowPerSec then
                hItem:Lookup('Text_R'):SetText(math.floor(p.nValue / nTimeCount) .. ' ' .. szUnit)
            else
                hItem:Lookup('Text_R'):SetText(p.nValue)
            end
        end
        hItem.data = p
    end
    hList.szUnit     = szUnit
    hList.nTimeCount = nTimeCount
    hList:FormatAllItemPos()
    
    -- ��Ⱦ�ײ��Լ���ͳ��
    local hItem = m_frame:Lookup('Wnd_Main', 'Handle_Me')
    -- ��ʼ����ɫ
    if not hItem.bInited then
        local dwForceID = (MY.Player.GetClientInfo() or {}).dwForceID
        if dwForceID then
            if _Cache.Css.Bar[dwForceID] then
                hItem:Lookup('Image_Me_PerFore'):FromUITex(unpack(_Cache.Css.Bar[dwForceID]))
                hItem:Lookup('Image_Me_PerBack'):FromUITex(unpack(_Cache.Css.Bar[dwForceID]))
            end
            hItem.bInited = true
        end
    end
    if tMyRec then
        if nMaxValue > 0 then
            hItem:Lookup('Image_Me_PerBack'):SetPercentage(tMyRec.nValue / nMaxValue)
            hItem:Lookup('Image_Me_PerFore'):SetPercentage(tMyRec.nEffectValue / nMaxValue)
        else
            hItem:Lookup('Image_Me_PerBack'):SetPercentage(1)
            hItem:Lookup('Image_Me_PerFore'):SetPercentage(1)
        end
        -- ���ս����ʱ
        hItem:Lookup('Text_Me_L'):SetText('[' .. tMyRec.nRank .. '] ' .. szTimeCount)
        -- �Ҳ�����
        if MY_Recount.bShowEffect then
            if MY_Recount.bShowPerSec then
                hItem:Lookup('Text_Me_R'):SetText(math.floor(tMyRec.nEffectValue / nTimeCount) .. ' ' .. szUnit)
            else
                hItem:Lookup('Text_Me_R'):SetText(tMyRec.nEffectValue)
            end
        else
            if MY_Recount.bShowPerSec then
                hItem:Lookup('Text_Me_R'):SetText(math.floor(tMyRec.nValue / nTimeCount) .. ' ' .. szUnit)
            else
                hItem:Lookup('Text_Me_R'):SetText(tMyRec.nValue)
            end
        end
    else
        hItem:Lookup('Text_Me_L'):SetText(szTimeCount)
        hItem:Lookup('Text_Me_R'):SetText('')
        hItem:Lookup('Image_Me_PerBack'):SetPercentage(1)
        hItem:Lookup('Image_Me_PerFore'):SetPercentage(0)
    end
end
--[[
##########################################################################
                                    #                 #         #         
                          # # # # # # # # # # #       #   #     #         
  # #     # # # # # # #       #     #     #         #     #     #         
    #     #       #           # # # # # # #         #     # # # # # # #   
    #     #       #                 #             # #   #       #         
    #     #       #         # # # # # # # # #       #           #         
    #     #       #                 #       #       #           #         
    #     #       #       # # # # # # # # # # #     #   # # # # # # # #   
    #     #       #                 #       #       #           #         
      # #     # # # # #     # # # # # # # # #       #           #         
                                    #               #           #         
                                  # #               #           #         
##########################################################################
]]

-- �����ػ�
MY_Recount.OnFrameBreathe = function()
    if this.nLastRedrawFrame and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount.nDrawInterval then
        return
    end
    this.nLastRedrawFrame = GetLogicFrameCount()
    
    -- ����սʱ��ˢ��UI
    if not _Cache.bHistoryMode and not MY.Player.GetFightUUID() then
        return
    end
    
    MY_Recount.UpdateUI()
end

MY_Recount.OnFrameDragEnd = function()
    this:CorrectPos()
    MY_Recount.anchor = MY.UI(this):anchor()
end

-- ShowDetail����ʱ����Ӧ
_Cache.OnDetailFrameBreathe = function()
    if this.nLastRedrawFrame and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount.nDrawInterval then
        return
    end
    this.nLastRedrawFrame = GetLogicFrameCount()
    
    local id        = this.id
    local szChannel = this.szChannel
    if tonumber(id) then
        id = tonumber(id)
    end
    -- ��ȡ����
    local tData = DataDisplay[szChannel][id]
    if not tData then
        this:Lookup('WndScroll_Detail', 'Handle_DetailList'):Clear()
        this:Lookup('WndScroll_Skill' , 'Handle_SkillList' ):Clear()
        this:Lookup('WndScroll_Target', 'Handle_TargetList'):Clear()
        return
    end
    
    local szPrimarySort   = this.szPrimarySort or 'Skill'
    local szSecondarySort = (szPrimarySort == 'Skill' and 'Target') or 'Skill'
    
    --------------- һ�������б���� -----------------
    -- �����ռ�
    local tResult, nTotalEffect = {}, tData.nTotalEffect
    if szPrimarySort == 'Skill' then
        for szSkillName, p in pairs(tData.Skill) do
            table.insert(tResult, {
                szKey        = szSkillName   ,
                szName       = szSkillName   ,
                nCount       = p.nCount      ,
                nTotalEffect = p.nTotalEffect,
            })
        end
    else
        for id, p in pairs(tData.Target) do
            table.insert(tResult, {
                szKey        = id                              ,
                szName       = MY_Recount.Data.GetNameAusID(id),
                nCount       = p.nCount                        ,
                nTotalEffect = p.nTotalEffect                  ,
            })
        end
    end
    table.sort(tResult, function(p1, p2)
        return p1.nTotalEffect > p2.nTotalEffect
    end)
    -- Ĭ��ѡ�е�һ��
    if this.bFirstRendering then
        if tResult[1] then
            if szPrimarySort == 'Skill' then
                this.szSelectedSkill  = tResult[1].szKey
            else
                this.szSelectedTarget = tResult[1].szKey
            end
        end
        this.bFirstRendering = nil
    end
    local szSelected
    local szSelectedSkill  = this.szSelectedSkill
    local szSelectedTarget = this.szSelectedTarget
    if szPrimarySort == 'Skill' then
        szSelected = this.szSelectedSkill
    else
        szSelected = this.szSelectedTarget
    end
    -- �����ػ�
    local hSelectedItem
    this:Lookup('WndScroll_Skill'):SetSize(480, 112)
    this:Lookup('WndScroll_Skill', ''):SetSize(480, 112)
    this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
    local hList = this:Lookup('WndScroll_Skill', 'Handle_SkillList')
    hList:SetSize(480, 90)
    hList:Clear()
    for i, p in ipairs(tResult) do
        local hItem = hList:AppendItemFromIni(_Cache.szIniDetail, 'Handle_SkillItem')
        hItem:Lookup('Text_SkillNo'):SetText(i)
        hItem:Lookup('Text_SkillName'):SetText(p.szName)
        hItem:Lookup('Text_SkillCount'):SetText(p.nCount)
        hItem:Lookup('Text_SkillTotal'):SetText(p.nTotalEffect)
        hItem:Lookup('Text_SkillPercentage'):SetText(nTotalEffect > 0 and _L('%.1f%%', math.floor(p.nTotalEffect / nTotalEffect * 100)) or ' - ')
        
        if szPrimarySort == 'Skill' and szSelectedSkill == p.szKey or
        szPrimarySort == 'Target' and szSelectedTarget == p.szKey then
            hSelectedItem = hItem
            hItem:Lookup('Shadow_SkillEntry'):Show()
        end
        hItem.szKey = p.szKey
        hItem.OnItemLButtonDown = _Cache.OnDetailItemLButtonDown
    end
    hList:FormatAllItemPos()
    
    if szSelected and tData[szPrimarySort][szSelected] then
        this:Lookup('', 'Handle_Spliter'):Show()
        --------------- ���������ͷŽ���б���� -----------------
        -- �����ռ�
        local tResult, nTotalEffect, nCount = {}, tData[szPrimarySort][szSelected].nTotalEffect, tData[szPrimarySort][szSelected].nCount
        for nSkillResult, p in pairs(tData[szPrimarySort][szSelected].Detail) do
            table.insert(tResult, {
                nCount     = p.nCount    ,
                nMinEffect = p.nMinEffect,
                nAvgEffect = p.nAvgEffect,
                nMaxEffect = p.nMaxEffect,
                nTotalEffect = p.nTotalEffect,
                szSkillResult = SZ_SKILL_RESULT[nSkillResult],
            })
        end
        table.sort(tResult, function(p1, p2)
            return p1.nAvgEffect > p2.nAvgEffect
        end)
        -- �����ػ�
        this:Lookup('WndScroll_Detail'):Show()
        local hList = this:Lookup('WndScroll_Detail', 'Handle_DetailList')
        hList:Clear()
        for i, p in ipairs(tResult) do
            local hItem = hList:AppendItemFromIni(_Cache.szIniDetail, 'Handle_DetailItem')
            hItem:Lookup('Text_DetailNo'):SetText(i)
            hItem:Lookup('Text_DetailType'):SetText(p.szSkillResult)
            hItem:Lookup('Text_DetailMin'):SetText(p.nMinEffect)
            hItem:Lookup('Text_DetailAverage'):SetText(p.nAvgEffect)
            hItem:Lookup('Text_DetailMax'):SetText(p.nMaxEffect)
            hItem:Lookup('Text_DetailCount'):SetText(p.nCount)
            hItem:Lookup('Text_DetailPercent'):SetText(nCount > 0 and _L('%.1f%%', math.floor(p.nCount / nCount * 100)) or ' - ')
        end
        hList:FormatAllItemPos()
        
        -- ���������� ��ǿ�û�����
        if hSelectedItem and not this:Lookup('WndScroll_Target'):IsVisible() then
            -- ˵���Ǹմ�δѡ��״̬�л����� ������������ѡ����
            local hScroll = this:Lookup('WndScroll_Skill/Scroll_Skill_List')
            hScroll:SetScrollPos(math.ceil(hScroll:GetStepCount() * hSelectedItem:GetIndex() / hSelectedItem:GetParent():GetItemCount()))
        end
        
        --------------- ���������ͷŽ���б���� -----------------
        -- �����ռ�
        local tResult, nTotalEffect = {}, tData[szPrimarySort][szSelected].nTotalEffect
        if szPrimarySort == 'Skill' then
            for id, p in pairs(tData.Skill[szSelectedSkill].Target) do
                table.insert(tResult, {
                    nHitCount      = p.Count[SKILL_RESULT.HIT] or 0,
                    nMissCount     = p.Count[SKILL_RESULT.MISS] or 0,
                    nCriticalCount = p.Count[SKILL_RESULT.CRITICAL] or 0,
                    nMaxEffect     = p.nMaxEffect,
                    nTotalEffect   = p.nTotalEffect,
                    szName         = MY_Recount.Data.GetNameAusID(id, DataDisplay),
                })
            end
        else
            for szSkillName, p in pairs(tData.Target[szSelectedTarget].Skill) do
                table.insert(tResult, {
                    nHitCount      = p.Count[SKILL_RESULT.HIT] or 0,
                    nMissCount     = p.Count[SKILL_RESULT.MISS] or 0,
                    nCriticalCount = p.Count[SKILL_RESULT.CRITICAL] or 0,
                    nMaxEffect     = p.nMaxEffect,
                    nTotalEffect   = p.nTotalEffect,
                    szName         = szSkillName,
                })
            end
        end
        table.sort(tResult, function(p1, p2)
            return p1.nTotalEffect > p2.nTotalEffect
        end)
        -- �����ػ�
        this:Lookup('WndScroll_Target'):Show()
        local hList = this:Lookup('WndScroll_Target', 'Handle_TargetList')
        hList:Clear()
        for i, p in ipairs(tResult) do
            local hItem = hList:AppendItemFromIni(_Cache.szIniDetail, 'Handle_TargetItem')
            hItem:Lookup('Text_TargetNo'):SetText(i)
            hItem:Lookup('Text_TargetName'):SetText(p.szName)
            hItem:Lookup('Text_TargetTotal'):SetText(p.nTotalEffect)
            hItem:Lookup('Text_TargetMax'):SetText(p.nMaxEffect)
            hItem:Lookup('Text_TargetHit'):SetText(p.nHitCount)
            hItem:Lookup('Text_TargetCritical'):SetText(p.nCriticalCount)
            hItem:Lookup('Text_TargetMiss'):SetText(p.nMissCount)
            hItem:Lookup('Text_TargetPercent'):SetText((nTotalEffect > 0 and _L('%.1f%%', math.floor(p.nTotalEffect / nTotalEffect * 100)) or ' - '))
        end
        hList:FormatAllItemPos()
    else
        this:Lookup('WndScroll_Skill'):SetSize(480, 348)
        this:Lookup('WndScroll_Skill', ''):SetSize(480, 348)
        this:Lookup('WndScroll_Skill', 'Handle_SkillList'):SetSize(480, 332)
        this:Lookup('WndScroll_Skill', 'Handle_SkillList'):FormatAllItemPos()
        this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
        this:Lookup('WndScroll_Detail'):Hide()
        this:Lookup('WndScroll_Target'):Hide()
        this:Lookup('', 'Handle_Spliter'):Hide()
    end
    
end
_Cache.OnDetailLButtonClick = function()
    local name = this:GetName()
    if name == 'Btn_Close' then
        MY.RegisterEsc(this:GetRoot():GetTreePath())
        Wnd.CloseWindow(this:GetRoot())
    elseif name == 'Btn_Switch' then
        if this:GetRoot().szPrimarySort == 'Skill' then
            this:GetRoot().szPrimarySort = 'Target'
        else
            this:GetRoot().szPrimarySort = 'Skill'
        end
        this:GetRoot().nLastRedrawFrame = 0
    elseif name == 'Btn_Unselect' then
        this:GetRoot().szSelectedSkill  = nil
        this:GetRoot().szSelectedTarget = nil
        this:GetRoot().nLastRedrawFrame = 0
    end
end
_Cache.OnDetailItemLButtonDown = function()
    local name = this:GetName()
    if name == 'Handle_SkillItem' then
        if this:GetRoot().szPrimarySort == 'Skill' then
            this:GetRoot().szSelectedSkill = this.szKey
        else
            this:GetRoot().szSelectedTarget = this.szKey
        end
        this:GetRoot().nLastRedrawFrame = 0
    end
end

MY_Recount.OnItemLButtonClick = function()
    local id = this.id
    local name = this:GetName()
    if name == 'Handle_Me' then
        id = UI_GetClientPlayerID()
        name = 'Handle_LI_' .. UI_GetClientPlayerID()
    end
    name:gsub('Handle_LI_(.+)', function()
        local szChannel = SZ_CHANNEL_KEY[MY_Recount.nChannel]
        if not Station.Lookup('Normal/MY_Recount_' .. id .. '_' .. szChannel) then
            local frm = Wnd.OpenWindow(_Cache.szIniDetail, 'MY_Recount_' .. id .. '_' .. szChannel)
            frm.id = id
            frm.bFirstRendering = true
            frm.szChannel = szChannel
            frm.szPrimarySort = ((MY_Recount.nChannel == CHANNEL.DPS or MY_Recount.nChannel == CHANNEL.HPS) and 'Skill') or 'Target'
            frm.szSecondarySort = ((MY_Recount.nChannel == CHANNEL.DPS or MY_Recount.nChannel == CHANNEL.HPS) and 'Target') or 'Skill'
            frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
            frm.OnFrameBreathe = _Cache.OnDetailFrameBreathe
            frm.OnItemLButtonDown = _Cache.OnDetailItemLButtonDown
            frm:Lookup('', 'Text_Default'):SetText(MY_Recount.Data.GetNameAusID(id, DataDisplay) .. ' ' .. SZ_CHANNEL[MY_Recount.nChannel])
            MY.RegisterEsc(frm:GetTreePath(), function()
                if Station.Lookup('Normal/MY_Recount_' .. id .. '_' .. szChannel) then
                    return true
                else
                    MY.RegisterEsc('MY_Recount_' .. id .. '_' .. szChannel)
                end
            end, function()
                if frm.szSelectedSkill or frm.szSelectedTarget then
                    frm.szSelectedSkill  = nil
                    frm.szSelectedTarget = nil
                else
                    MY.RegisterEsc(frm:GetTreePath())
                    MY.UI(frm):remove()
                end
            end)
            
            MY.UI(frm):children('Btn_Close'):click(_Cache.OnDetailLButtonClick)
        end
    end)
end

MY_Recount.OnItemRefreshTip = function()
    local id = this.id
    local name = this:GetName()
    if name == 'Handle_Me' then
        id = UI_GetClientPlayerID()
        name = 'Handle_LI_' .. UI_GetClientPlayerID()
    end
    name:gsub('Handle_LI_(.+)', function()
        if tonumber(id) then
            id = tonumber(id)
        end
        local x, y = this:GetAbsPos()
        local w, h = this:GetSize()
        local tRec = DataDisplay[SZ_CHANNEL_KEY[MY_Recount.nChannel]][id]
        if tRec then
            local szXml = ''
            local szColon = g_tStrings.STR_COLON
            for szSkillName, p in pairs(tRec.Skill) do
                szXml = szXml .. GetFormatText(szSkillName .. "\n", nil, 255, 150, 0)
                szXml = szXml .. GetFormatText(_L['total: '] .. p.nTotal .. ' ' .. _L['effect: '] .. p.nTotalEffect .. "\n")
                for _, nSkillResult in ipairs({
                    SKILL_RESULT.HIT     ,
                    SKILL_RESULT.INSIGHT ,
                    SKILL_RESULT.CRITICAL,
                    SKILL_RESULT.MISS    ,
                }) do
                    local nCount = 0
                    if p.Detail[nSkillResult] then
                        nCount = p.Detail[nSkillResult].nCount
                    end
                    szXml = szXml .. GetFormatText(SZ_SKILL_RESULT[nSkillResult] .. szColon, nil, 255, 202, 126)
                    szXml = szXml .. GetFormatText(string.format('%2d', nCount) .. ' ')
                end
                szXml = szXml .. GetFormatText('\n')
            end
            OutputTip(szXml, 500, {x, y, w, h})
        end
    end)
end

MY_Recount.OnLButtonClick = function()
    local name = this:GetName()
    if name == 'Btn_Right' then
        if MY_Recount.nChannel == CHANNEL.DPS then
            MY_Recount.nChannel = CHANNEL.HPS
        elseif MY_Recount.nChannel == CHANNEL.HPS then
            MY_Recount.nChannel = CHANNEL.BDPS
        elseif MY_Recount.nChannel == CHANNEL.BDPS then
            MY_Recount.nChannel = CHANNEL.BHPS
        elseif MY_Recount.nChannel == CHANNEL.BHPS then
            MY_Recount.nChannel = CHANNEL.DPS
        end
        MY_Recount.DrawUI()
    elseif name == 'Btn_Left' then
        if MY_Recount.nChannel == CHANNEL.HPS then
            MY_Recount.nChannel = CHANNEL.DPS
        elseif MY_Recount.nChannel == CHANNEL.BDPS then
            MY_Recount.nChannel = CHANNEL.HPS
        elseif MY_Recount.nChannel == CHANNEL.BHPS then
            MY_Recount.nChannel = CHANNEL.BDPS
        elseif MY_Recount.nChannel == CHANNEL.DPS then
            MY_Recount.nChannel = CHANNEL.BHPS
        end
        MY_Recount.DrawUI()
    elseif name == 'Btn_Option' then
        PopupMenu(MY_Recount.GetMenu())
    elseif name == 'Btn_History' then
        PopupMenu(MY_Recount.GetHistoryMenu())
    elseif name == 'Btn_Empty' then
        MY_Recount.Data.Init(true)
        DataDisplay = MY_Recount.Data.Get(0)
        MY_Recount.DrawUI()
    elseif name == 'Btn_Issuance' then
        PopupMenu(MY_Recount.GetPublishMenu())
    end
end

MY_Recount.OnCheckBoxCheck = function()
    local name = this:GetName()
    if name == 'CheckBox_Minimize' then
        this:GetRoot():Lookup('Wnd_Main'):Hide()
        this:GetRoot():SetSize(280, 30)
        this:GetRoot():Lookup('Wnd_Title', 'Image_Bg'):Hide()
    end
end

MY_Recount.OnCheckBoxUncheck = function()
    local name = this:GetName()
    if name == 'CheckBox_Minimize' then
        this:GetRoot():Lookup('Wnd_Main'):Show()
        this:GetRoot():SetSize(280, 262)
        this:GetRoot():Lookup('Wnd_Title', 'Image_Bg'):Show()
    end
end

--[[
##################################################################################################
        #       #             #           #                 #                         #   #       
  # # # # # # # # # # #         #       #             #     #                         #     #     
        #       #           # # # # # # # # #         #     #               # # # # # # # # # #   
                # # #       #       #       #         # # # # # # # #       #         #           
  # # # # # # #             # # # # # # # # #       #       #               #         #           
    #     #       #         #       #       #     #         #               # # # #   #     #     
      #     #   #           # # # # # # # # #               #               #     #   #     #     
            #                       #                 # # # # # # #         #     #   #   #       
  # # # # # # # # # # #   # # # # # # # # # # #             #               #     #     #     #   
        #   #   #                   #                       #               #   # #   #   #   #   
      #     #     #                 #                       #               #       #       # #   
  # #       #       # #             #             # # # # # # # # # # #   #       #           #   
##################################################################################################
]]
-- ��ȡ���ò˵�
MY_Recount.GetMenu = function()
    local t = {
        szOption = _L["fight recount"],
        {
            szOption = _L['enable'],
            bCheck = true,
            bChecked = MY_Recount.bEnable,
            fnAction = function()
                MY_Recount.bEnable = not MY_Recount.bEnable
                if MY_Recount.bEnable then
                    MY_Recount.Open()
                else
                    MY_Recount.Close()
                end
            end,
        }, {
            szOption = _L['display as per second'],
            bCheck = true,
            bChecked = MY_Recount.bShowPerSec,
            fnAction = function()
                MY_Recount.bShowPerSec = not MY_Recount.bShowPerSec
                MY_Recount.DrawUI()
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        }, {
            szOption = _L['display effective value'],
            bCheck = true,
            bChecked = MY_Recount.bShowEffect,
            fnAction = function()
                MY_Recount.bShowEffect = not MY_Recount.bShowEffect
                MY_Recount.DrawUI()
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        },
        {   -- �л�ͳ������
            szOption = _L['switch recount mode'],
            {
                szOption = _L['display only npc record'],
                bCheck = true, bMCheck = true,
                bChecked = MY_Recount.nDisplayMode == DISPLAY_MODE.NPC,
                fnAction = function()
                    MY_Recount.nDisplayMode = DISPLAY_MODE.NPC
                    MY_Recount.DrawUI()
                end,
            }, {
                szOption = _L['display only player record'],
                bCheck = true, bMCheck = true,
                bChecked = MY_Recount.nDisplayMode == DISPLAY_MODE.PLAYER,
                fnAction = function()
                    MY_Recount.nDisplayMode = DISPLAY_MODE.PLAYER
                    MY_Recount.DrawUI()
                end,
            }, {
                szOption = _L['display all record'],
                bCheck = true, bMCheck = true,
                bChecked = MY_Recount.nDisplayMode == DISPLAY_MODE.BOTH,
                fnAction = function()
                    MY_Recount.nDisplayMode = DISPLAY_MODE.BOTH
                    MY_Recount.DrawUI()
                end,
            }
        }
    }

    -- ���˶�ʱ���¼
    local t1 = {
        szOption = _L['filter short fight'],
        fnDisable = function()
            return not MY_Recount.bEnable
        end,
    }
    for _, i in pairs({ -1, 10, 30, 60, 90, 120, 180 }) do
        local szOption
        if i < 0 then
            szOption = _L['no time limit']
        elseif i < 60 then
            szOption = _L('less than %d second', i)
        elseif i == 90 then
            szOption = _L('less than %d minute and a half', i / 60)
        else
            szOption = _L('less than %d minute', i / 60)
        end
        table.insert(t1, {
            szOption = szOption,
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.Data.nMinFightTime == i,
            fnAction = function()
                MY_Recount.Data.nMinFightTime = i
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        })
    end
    table.insert(t, t1)

    -- ���ѡ��
    local t1 = {
        szOption = _L['theme'],
        fnDisable = function()
            return not MY_Recount.bEnable
        end,
    }
    for i, _ in ipairs(MY.LoadLUAData(_Cache.szCssFile, true)) do
        table.insert(t1, {
            szOption = i,
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.nCss == i,
            fnAction = function()
                MY_Recount.LoadCustomCss(i)
                MY_Recount.DrawUI()
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        })
    end
    table.insert(t, t1)

    -- ��ֵˢ������
    local t1 = {
        szOption = _L['redraw interval'],
        fnDisable = function()
            return not MY_Recount.bEnable
        end,
    }
    for _, i in ipairs({1, GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS, GLOBAL.GAME_FPS * 2}) do
        local szOption
        if i == 1 then
            szOption = _L['realtime refresh']
        else
            szOption = _L('every %.1f second', i / GLOBAL.GAME_FPS)
        end
        table.insert(t1, {
            szOption = szOption,
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.nDrawInterval == i,
            fnAction = function()
                MY_Recount.nDrawInterval = i
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        })
    end
    table.insert(t, t1)

    -- �����ʷ��¼
    local t1 = {
        szOption = _L['max history'],
        fnDisable = function()
            return not MY_Recount.bEnable
        end,
    }
    for i = 1, 20 do
        table.insert(t1, {
            szOption = i,
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.Data.nMaxHistory == i,
            fnAction = function()
                MY_Recount.Data.nMaxHistory = i
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        })
    end
    table.insert(t, t1)

    return t
end

-- ��ȡ��ʷ��¼�˵�
MY_Recount.GetHistoryMenu = function()
    local t = {{
        szOption = _L["current fight"],
        rgb = (MY_Recount.Data.Get(0) == DataDisplay and {255, 255, 0}) or nil,
        fnAction = function()
            MY_Recount.DisplayData(0)
        end,
    }}
    
    for _, data in ipairs(MY_Recount.Data.Get()) do
        if data.UUID and data.nTimeDuring then
            local t1 = {
                szOption = (data.szBossName or '') .. ' (' .. MY.Sys.FormatTimeCount('M:ss', data.nTimeDuring) .. ')',
                rgb = (data == DataDisplay and {255, 255, 0}) or nil,
                fnAction = function()
                    MY_Recount.DisplayData(data)
                end,
                szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
                nFrame = 49,
                nMouseOverFrame = 51,
                nIconWidth = 17,
                nIconHeight = 17,
                szLayer = "ICON_RIGHTMOST",
                fnClickIcon = function()
                    MY_Recount.Data.Del(data)
                    Wnd.CloseWindow('PopupMenuPanel')
                end,
            }
            if MY.Sys.GetLang() == 'vivn' then
                t1.szLayer = "ICON_RIGHT"
            end
            table.insert(t, t1)
        end
    end
    
    return t
end

-- ��ȡ�����˵�
MY_Recount.GetPublishMenu = function()
    local t = {}
    
    local t1 = {
        szOption = _L['publish limit'],
    }
    for _, i in pairs({
        1,2,3,4,5,8,10,15,20,30,50,100
    }) do
        table.insert(t1, {
            szOption = _L('top %d', i),
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.nPublishLimit == i,
            fnAction = function()
                MY_Recount.nPublishLimit = i
            end,
        })
    end
    table.insert(t, t1)
    
    -- ��������
    table.insert(t, {
        szOption = _L['publish mode'],
        {
            szOption = _L['only effect value'],
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT,
            fnAction = function()
                MY_Recount.nPublishMode = PUBLISH_MODE.EFFECT
            end,
        }, {
            szOption = _L['only total value'],
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL,
            fnAction = function()
                MY_Recount.nPublishMode = PUBLISH_MODE.TOTAL
            end,
        }, {
            szOption = _L['effect and total value'],
            bCheck = true, bMCheck = true,
            bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.BOTH,
            fnAction = function()
                MY_Recount.nPublishMode = PUBLISH_MODE.BOTH
            end,
        }
    })
    
    for nChannel, szChannel in pairs({
        [PLAYER_TALK_CHANNEL.RAID] = 'MSG_TEAM',
        [PLAYER_TALK_CHANNEL.TEAM] = 'MSG_PARTY',
        [PLAYER_TALK_CHANNEL.TONG] = 'MSG_GUILD',
    }) do
        table.insert(t, {
            szOption = g_tStrings.tChannelName[szChannel],
            rgb = GetMsgFontColor(szChannel, true),
            fnAction = function()
                local frame = Station.Lookup('Normal/MY_Recount')
                if not frame then
                    return
                end
                MY.Talk(
                    nChannel,
                    '[' .. _L['mingyi plugin'] .. ']' ..
                    _L['fight recount'] .. ' - ' ..
                    frame:Lookup('Wnd_Title', 'Text_Title'):GetText() ..
                    ((DataDisplay.szBossName and ' - ' .. DataDisplay.szBossName) or ''),
                    true
                )
                MY.Talk(nChannel, '------------------------')
                local hList      = frame:Lookup('Wnd_Main', 'Handle_List')
                local szUnit     = (' ' .. hList.szUnit) or ''
                local nTimeCount = hList.nTimeCount or 0
                local tResult = {} -- �ռ�����
                local nMaxNameLen = 0
                for i = 0, MY_Recount.nPublishLimit do
                    local hItem = hList:Lookup(i)
                    if not hItem then
                        break
                    end
                    table.insert(tResult, hItem.data)
                    nMaxNameLen = math.max(nMaxNameLen, wstring.len(hItem.data.szName))
                end
                -- ��������
                for i, p in ipairs(tResult) do
                    local szText = string.format('%02d', i) .. '.[' .. p.szName .. ']'
                    for i = wstring.len(p.szName), nMaxNameLen - 1 do
                        szText = szText .. g_tStrings.STR_ONE_CHINESE_SPACE
                    end
                    if MY_Recount.nPublishMode == PUBLISH_MODE.BOTH then
                        szText = szText .. _L('%7d%s(Effect) %7d%s(Total)',
                            p.nEffectValue / nTimeCount, szUnit,
                            p.nValue / nTimeCount, szUnit
                        )
                    elseif MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT then
                        szText = szText .. _L('%7d%s(Effect)',
                            p.nEffectValue / nTimeCount, szUnit
                        )
                    elseif MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL then
                        szText = szText .. _L('%7d%s(Total)',
                            p.nValue / nTimeCount, szUnit
                        )
                    end
                    
                    MY.Talk(nChannel, szText, p.id == p.szName)
                end
                
                MY.Talk(nChannel, '------------------------')
            end
        })
    end
    
    return t
end

MY.RegisterPlayerAddonMenu('MY_RECOUNT_MENU', MY_Recount.GetMenu)
MY.RegisterTraceButtonMenu('MY_RECOUNT_MENU', MY_Recount.GetMenu)
