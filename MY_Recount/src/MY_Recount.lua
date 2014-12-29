--
-- 战斗统计
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
-- 
local CHANNEL = { -- 统计类型
    DPS  = 1, -- 输出统计
    HPS  = 2, -- 治疗统计
    BDPS = 3, -- 承伤统计
    BHPS = 4, -- 承疗统计
}
local SZ_CHANNEL_KEY = { -- 统计类型数组名
    [CHANNEL.DPS ] = 'Damage',
    [CHANNEL.HPS ] = 'Heal',
    [CHANNEL.BDPS] = 'BeDamage',
    [CHANNEL.BHPS] = 'BeHeal',
}
local SZ_CHANNEL = {
    [CHANNEL.DPS ] = g_tStrings.STR_DAMAGE_STATISTIC    , -- 伤害统计
    [CHANNEL.HPS ] = g_tStrings.STR_THERAPY_STATISTIC   , -- 治疗统计
    [CHANNEL.BDPS] = g_tStrings.STR_BE_DAMAGE_STATISTIC , -- 承伤统计
    [CHANNEL.BHPS] = g_tStrings.STR_BE_THERAPY_STATISTIC, -- 承疗统计
}
local DISPLAY_MODE = { -- 统计显示
    NPC    = 1, -- 只显示NPC
    PLAYER = 2, -- 只显示玩家
    BOTH   = 3, -- 混合显示
}
local SKILL_RESULT = {
    HIT     = 0, -- 命中
    BLOCK   = 1, -- 格挡
    SHIELD  = 2, -- 无效
    MISS    = 3, -- 偏离
    DODGE   = 4, -- 闪避
    CRITICAL= 5, -- 会心
}
local SZ_SKILL_RESULT = {
    [SKILL_RESULT.HIT     ] = g_tStrings.STR_HIT_NAME     ,
    [SKILL_RESULT.BLOCK   ] = g_tStrings.STR_IMMUNITY_NAME,
    [SKILL_RESULT.SHIELD  ] = g_tStrings.STR_SHIELD_NAME  ,
    [SKILL_RESULT.MISS    ] = g_tStrings.STR_MISS_NAME    ,
    [SKILL_RESULT.DODGE   ] = g_tStrings.STR_DODGE_NAME   ,
    [SKILL_RESULT.CRITICAL] = g_tStrings.STR_CS_NAME      ,
}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Recount/lang/")
local _Cache = {
    szIniRoot   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/',
    szCssFile   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/style',
    szIniFile   = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/Recount.ini',
    szIniDetail = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/ShowDetail.ini',
}

-- 新的战斗数据时
MY.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function()
    if not _Cache.bHistoryMode then
        MY_Recount.DisplayData(0)
    end
end)

MY_Recount = MY_Recount or {}
MY_Recount.bEnable       = true                 -- 是否启用
MY_Recount.nCss          = 1                    -- 当前样式表
MY_Recount.nChannel      = CHANNEL.DPS          -- 当前显示的统计模式
MY_Recount.bShowPerSec   = true                 -- 显示为每秒数据（反之显示总和）
MY_Recount.bShowEffect   = true                 -- 显示有效伤害/治疗
MY_Recount.nDisplayMode  = DISPLAY_MODE.BOTH    -- 统计显示模式（显示NPC/玩家数据）（默认混合显示）
MY_Recount.nPublishLimit = 5                    -- 发布到聊天频道数量
MY_Recount.nDrawInterval = GLOBAL.GAME_FPS / 2  -- UI重绘周期（帧）
MY_Recount.anchor = { x=0, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" } -- 默认坐标
RegisterCustomData("MY_Recount.bEnable")
RegisterCustomData("MY_Recount.nCss")
RegisterCustomData("MY_Recount.nChannel")
RegisterCustomData("MY_Recount.bShowPerSec")
RegisterCustomData("MY_Recount.bShowEffect")
RegisterCustomData("MY_Recount.nDisplayMode")
RegisterCustomData("MY_Recount.nPublishLimit")
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

--[[ 切换绑定显示记录
    MY_Recount.DisplayData(number nHistory): 显示第nHistory条历史记录 当nHistory等于0时显示当前记录
    MY_Recount.DisplayData(table  data): 显示数据为data的历史记录
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

    MY_Recount.UpdateUI(data)
end

MY_Recount.UpdateUI = function(data)
    if not data then
        data = DataDisplay
    end

    if not m_frame then
        return
    end

    -- 获取统计数据
    local tRecord, szUnit
    if MY_Recount.nChannel == CHANNEL.DPS then       -- 伤害统计
        tRecord, szUnit = data.Damage  , 'DPS'
    elseif MY_Recount.nChannel == CHANNEL.HPS then   -- 治疗统计
        tRecord, szUnit = data.Heal    , 'HPS'
    elseif MY_Recount.nChannel == CHANNEL.BDPS then  -- 承伤统计
        tRecord, szUnit = data.BeDamage, 'DPS'
    elseif MY_Recount.nChannel == CHANNEL.BHPS then  -- 承疗统计
        tRecord, szUnit = data.BeHeal  , 'HPS'
    end
    
    -- 计算战斗时间
    local nTimeCount
    if not data.UUID then
        nTimeCount = 0
    elseif data.UUID == MY.Player.GetFightUUID() then
        nTimeCount = MY.Player.GetFightTime() / GLOBAL.GAME_FPS
    else
        nTimeCount = data.nTimeDuring
    end
    nTimeCount = math.max(nTimeCount, 1) -- 防止计算DPS时除以0
    
    -- 整理数据 生成要显示的列表
    local nMaxValue, tResult = 0, {}
    for id, rec in pairs(tRecord) do
        if MY_Recount.nDisplayMode == DISPLAY_MODE.BOTH or  -- 确定显示模式（显示NPC/显示玩家/全部显示）
        (MY_Recount.nDisplayMode == DISPLAY_MODE.NPC    and type(id) == 'string') or
        (MY_Recount.nDisplayMode == DISPLAY_MODE.PLAYER and type(id) == 'number') then
            tRec = {
                id           = id                                    ,
                szName       = MY_Recount.Data.GetNameAusID(id, data),
                dwForceID    = data.Forcelist[id] or -1              ,
                nValue       = rec.nTotal         or  0              ,
                nEffectValue = rec.nTotalEffect   or  0              ,
            }
            table.insert(tResult, tRec)
            nMaxValue = math.max(nMaxValue, tRec.nValue, tRec.nEffectValue)
        end
    end
    
    -- 列表排序
    if MY_Recount.bShowEffect then
        table.sort(tResult, function(p1, p2)
            return p1.nEffectValue > p2.nEffectValue
        end)
    else
        table.sort(tResult, function(p1, p2)
            return p1.nValue > p2.nValue
        end)
    end
    
    -- 渲染列表
    local hList = m_frame:Lookup('Wnd_Main', 'Handle_List')
    for i, p in pairs(tResult) do
        local hItem = hList:Lookup('Handle_LI_' .. p.id)
        if not hItem then
            hItem = hList:AppendItemFromIni(_Cache.szIniFile, 'Handle_Item')
            hItem:SetName('Handle_LI_' .. p.id)
            hItem:Lookup('Text_L'):SetText(p.szName)
            if _Cache.Css.Bar[p.dwForceID] then
                hItem:Lookup('Image_PerFore'):FromUITex(unpack(_Cache.Css.Bar[p.dwForceID]))
                hItem:Lookup('Image_PerBack'):FromUITex(unpack(_Cache.Css.Bar[p.dwForceID]))
            end
        end
        if hItem:GetIndex() ~= i - 1 then
            hItem:ExchangeIndex(i - 1)
        end
        
        hItem:Lookup('Image_PerBack'):SetPercentage(p.nValue / nMaxValue)
        hItem:Lookup('Image_PerFore'):SetPercentage(p.nEffectValue / nMaxValue)
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
    end
    hList:FormatAllItemPos()
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

-- 周期重绘
MY_Recount.OnFrameBreathe = function()
    if this.nLastRedrawFrame and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount.nDrawInterval then
        return
    end
    this.nLastRedrawFrame = GetLogicFrameCount()
    
    MY_Recount.UpdateUI()
end

MY_Recount.OnFrameDragEnd = function()
    this:CorrectPos()
    MY_Recount.anchor = MY.UI(this):anchor()
end

-- ShowDetail界面时间相应
_Cache.OnDetailFrameBreathe = function()
    if this.nLastRedrawFrame and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount.nDrawInterval then
        return
    end
    this.nLastRedrawFrame = GetLogicFrameCount()
    
    local id = this.id
    local szChannel    = this.szChannel
    local szSelectedSkill  = this.szSelectedSkill
    local szSelectedTarget = this.szSelectedTarget
    if tonumber(id) then
        id = tonumber(id)
    end
    -- 获取数据
    local tData = DataDisplay[szChannel][id]
    if not tData then
        return
    end
    
    local szPrimarySort   = this.szPrimarySort or 'Skill'
    local szSecondarySort = (szPrimarySort == 'Skill' and 'Target') or 'Skill'
    local szSelected
    if szPrimarySort == 'Skill' then
        szSelected = this.szSelectedSkill
    else
        szSelected = this.szSelectedTarget
    end
    
    --------------- 技能列表更新 -----------------
    -- 数据收集
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
    -- 界面重绘
    this:Lookup('WndScroll_Skill'):SetH(112)
    this:Lookup('WndScroll_Skill', ''):SetH(112)
    this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
    local hList = this:Lookup('WndScroll_Skill', 'Handle_SkillList')
    hList:SetH(90)
    hList:Clear()
    for i, p in ipairs(tResult) do
        local hItem = hList:AppendItemFromIni(_Cache.szIniDetail, 'Handle_SkillItem')
        hItem:Lookup('Text_SkillNo'):SetText(i)
        hItem:Lookup('Text_SkillName'):SetText(p.szName)
        hItem:Lookup('Text_SkillCount'):SetText(p.nCount)
        hItem:Lookup('Text_SkillTotal'):SetText(p.nTotalEffect)
        hItem:Lookup('Text_SkillPercentage'):SetText((math.floor(p.nTotalEffect / nTotalEffect * 1000) / 10) .. '%')
        
        if szPrimarySort == 'Skill' and szSelectedSkill == p.szKey or
        szPrimarySort == 'Target' and szSelectedTarget == p.szKey then
            hItem:Lookup('Shadow_SkillEntry'):Show()
        end
        hItem.szKey = p.szKey
    end
    hList:FormatAllItemPos()
    
    if szSelected and tData[szPrimarySort][szSelected] then
        this:Lookup('', 'Handle_Spliter'):Show()
        --------------- 技能释放结果列表更新 -----------------
        -- 数据收集
        local tResult, nTotalEffect = {}, tData[szPrimarySort][szSelected].nTotalEffect
        for nSkillResult, p in pairs(tData[szPrimarySort][szSelected].Detail) do
            table.insert(tResult, {
                nCount     = p.nCount,
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
        -- 界面重绘
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
            hItem:Lookup('Text_DetailPercent'):SetText(nTotalEffect > 0 and ((math.floor(p.nTotalEffect / nTotalEffect * 1000) / 10) .. '%') or ' - ')
        end
        hList:FormatAllItemPos()
        
        --------------- 技能释放结果列表更新 -----------------
        -- 数据收集
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
        -- 界面重绘
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
            hItem:Lookup('Text_TargetPercent'):SetText((nTotalEffect > 0 and ((math.floor(p.nTotalEffect / nTotalEffect * 1000) / 10) .. '%') or ' - '))
        end
        hList:FormatAllItemPos()
    else
        this:Lookup('WndScroll_Skill'):SetH(348)
        this:Lookup('WndScroll_Skill', ''):SetH(348)
        this:Lookup('WndScroll_Skill', 'Handle_SkillList'):SetH(332)
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
    local name = this:GetName()
    name:gsub('Handle_LI_(.+)', function(id)
        local szChannel = SZ_CHANNEL_KEY[MY_Recount.nChannel]
        if not Station.Lookup('Normal/MY_Recount_' .. id .. '_' .. szChannel) then
            local frm = Wnd.OpenWindow(_Cache.szIniDetail, 'MY_Recount_' .. id .. '_' .. szChannel)
            frm.id = id
            frm.szChannel = szChannel
            frm.szPrimarySort = ((MY_Recount.nChannel == CHANNEL.DPS or MY_Recount.nChannel == CHANNEL.HPS) and 'Skill') or 'Target'
            frm.szSecondarySort = ((MY_Recount.nChannel == CHANNEL.DPS or MY_Recount.nChannel == CHANNEL.HPS) and 'Target') or 'Skill'
            frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
            frm.OnFrameBreathe = _Cache.OnDetailFrameBreathe
            frm.OnItemLButtonDown = _Cache.OnDetailItemLButtonDown
            frm:Lookup('', 'Text_Default'):SetText(MY_Recount.Data.GetNameAusID(id, DataDisplay) .. ' ' .. SZ_CHANNEL[MY_Recount.nChannel])
            
            MY.UI(frm):children('Btn_Close'):click(_Cache.OnDetailLButtonClick)
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
    elseif name == 'Btn_Switch' then
        PopupMenu(MY_Recount.GetDisplayModeMenu())
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
    end
end

MY_Recount.OnCheckBoxUncheck = function()
    local name = this:GetName()
    if name == 'CheckBox_Minimize' then
        this:GetRoot():Lookup('Wnd_Main'):Show()
        this:GetRoot():SetSize(280, 250)
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
-- 获取设置菜单
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
            end,
            fnDisable = function()
                return not MY_Recount.bEnable
            end,
        }
    }

    -- 过滤短时间记录
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

    -- 风格选择
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

    -- 数值刷新周期
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

    -- 最大历史记录
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

-- 获取历史记录菜单
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
            table.insert(t, {
                szOption = (data.szBossName or '') .. ' (' .. data.nTimeDuring .. 's)',
                rgb = (data == DataDisplay and {255, 255, 0}) or nil,
                fnAction = function()
                    MY_Recount.DisplayData(data)
                end,
            })
        end
    end
    
    return t
end

-- 获取显示模式菜单
MY_Recount.GetDisplayModeMenu = function()
    return {{
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
    }}
end

-- 获取发布菜单
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
                    _L['recount'] .. ' - ' .. frame:Lookup('Wnd_Title', 'Text_Title'):GetText(),
                    true
                )
                local hList = frame:Lookup('Wnd_Main', 'Handle_List')
                for i = 0, MY_Recount.nPublishLimit do
                    local hItem = hList:Lookup(i)
                    if not hItem then
                        break
                    end
                    local bNpc
                    hItem:GetName():gsub('Handle_LI_(.+)', function(id)
                        if not tonumber(id) then
                            bNpc = true
                        end
                    end)
                    MY.Talk(nChannel, i .. '.[' .. hItem:Lookup('Text_L'):GetText() .. ']: ' .. hItem:Lookup('Text_R'):GetText(), bNpc)
                end
            end
        })
    end
    
    return t
end

MY.RegisterPlayerAddonMenu('MY_RECOUNT_MENU', MY_Recount.GetMenu)
MY.RegisterTraceButtonMenu('MY_RECOUNT_MENU', MY_Recount.GetMenu)