--
-- 焦点列表
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
-- 
--[[
-- [SKILL_RESULT_TYPE]枚举：
SKILL_RESULT_TYPE.PHYSICS_DAMAGE       = 0  -- 外功伤害
SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE   = 1  -- 阳性内功伤害
SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE = 2  -- 混元性内功伤害
SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE   = 3  -- 阴性内功伤害
SKILL_RESULT_TYPE.POISON_DAMAGE        = 4  -- 毒性伤害
SKILL_RESULT_TYPE.REFLECTIED_DAMAGE    = 5  -- 反弹伤害
SKILL_RESULT_TYPE.THERAPY              = 6  -- 治疗
SKILL_RESULT_TYPE.STEAL_LIFE           = 7  -- 生命偷取(<D0>从<D1>获得了<D2>点气血。)
SKILL_RESULT_TYPE.ABSORB_THERAPY       = 8  -- 化解治疗
SKILL_RESULT_TYPE.ABSORB_DAMAGE        = 9  -- 化解伤害
SKILL_RESULT_TYPE.SHIELD_DAMAGE        = 10 -- 无效伤害
SKILL_RESULT_TYPE.PARRY_DAMAGE         = 11 -- 拆招
SKILL_RESULT_TYPE.INSIGHT_DAMAGE       = 12 -- 识破
SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE     = 13 -- 有效伤害
SKILL_RESULT_TYPE.EFFECTIVE_THERAPY    = 14 -- 有效治疗
SKILL_RESULT_TYPE.TRANSFER_LIFE        = 15 -- 吸取生命
SKILL_RESULT_TYPE.TRANSFER_MANA        = 16 -- 吸取内力

-- Data DataDisplay History[] 数据结构
Data = {
    UUID = 战斗统一标示符,
    nTimeBegin  = 战斗开始UNIX时间戳,
    nTimeDuring = 战斗持续秒数,
    Namelist = {
        玩家的dwID = 玩家的名字,
        ...
    },
    Forcelist = {
        玩家的dwID = 玩家的dwForceID,
        ...
    },
    Damage = {                                                -- 输出统计
        玩家的dwID = {                                        -- 该对象的输出统计
            nTotal       = 2314214,                           -- 总输出
            nTotalEffect = 132144 ,                           -- 有效输出
            Detail = {                                        -- 输出结果分类统计
                SKILL_RESULT.HIT = {
                    nCount       = 10    ,                    -- 命中记录数量
                    nMax         = 34210 ,                    -- 单次命中最大值
                    nMaxEffect   = 29817 ,                    -- 单次命中最大有效值
                    nMin         = 8790  ,                    -- 单次命中最小值
                    nMinEffect   = 7657  ,                    -- 单次命中最小有效值
                    nAvg         = 27818 ,                    -- 单次命中平均值
                    nAvgEffect   = 27818 ,                    -- 单次命中平均有效值
                    nTotal       = 278560,                    -- 所以命中总伤害
                    nTotalEffect = 224750,                    -- 所有命中总有效伤害
                },
                SKILL_RESULT.MISS = { ... },
                SKILL_RESULT.CRITICAL = { ... },
            },
            Skill = {                                         -- 该玩家具体造成输出的技能统计
                四象轮回 = {                                  -- 该玩家四象轮回造成的输出统计
                    nMax         = 13415 ,                    -- 该玩家四象轮回最大输出量
                    nMaxEffect   = 9080  ,                    -- 该玩家四象轮回最大有效输出量
                    nTotal       = 23213 ,                    -- 该玩家四象轮回输出量总和
                    nTotalEffect = 321421,                    -- 该玩家四象轮回有效输出量总和
                    Detail = {                                -- 该玩家四象轮回输出结果分类统计
                        SKILL_RESULT.HIT = {                    
                            nCount       = 10    ,            -- 该玩家四象轮回命中记录数量
                            nMax         = 34210 ,            -- 该玩家四象轮回单次命中最大值
                            nMaxEffect   = 29817 ,            -- 该玩家四象轮回单次命中最大有效值
                            nMin         = 8790  ,            -- 该玩家四象轮回单次命中最小值
                            nMinEffect   = 7657  ,            -- 该玩家四象轮回单次命中最小有效值
                            nAvg         = 27818 ,            -- 单次命中平均值
                            nAvgEffect   = 27818 ,            -- 单次命中平均有效值
                            nTotal       = 278560,            -- 该玩家四象轮回所以命中总伤害
                            nTotalEffect = 224750,            -- 该玩家四象轮回所有命中总有效伤害
                        },
                        SKILL_RESULT.MISS = { ... },
                        SKILL_RESULT.CRITICAL = { ... },
                    },
                    Target = {                                -- 该玩家四象轮回承受者统计
                        玩家dwID = {                          -- 该玩家四象轮回击中的这个玩家数据统计
                            nMax         = 13415 ,            -- 该玩家四象轮回击中的这个玩家最大伤害
                            nMaxEffect   = 9080  ,            -- 该玩家四象轮回击中的这个玩家最大有效伤害
                            nTotal       = 23213 ,            -- 该玩家四象轮回击中的这个玩家伤害总和
                            nTotalEffect = 321421,            -- 该玩家四象轮回击中的这个玩家有效伤害总和
                            Count = {                         -- 该玩家四象轮回击中的这个玩家结果统计
                                SKILL_RESULT.HIT      = 5,
                                SKILL_RESULT.MISS     = 3,
                                SKILL_RESULT.CRITICAL = 3,
                            },
                        },
                        Npc名字 = { ... },
                        ...
                    },
                }, 
                两仪化形 = { ... },
                ...
            }
        },
        NPC的名字 = { ... },
    },
    Heal = { ... },
    BeHeal = { ... },
    BeDamage = { ... },
}
]]
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
local _Cache = {}
_Cache.szIniRoot = MY.GetAddonInfo().szRoot .. 'MY_Recount/ui/'
_Cache.szIniFile = _Cache.szIniRoot .. 'Recount.ini'
_Cache.szCssFile = _Cache.szIniRoot .. 'style'
_Cache.szRecFile = 'cache/FIGHT_RECOUNT_LOG/history'
_Cache.szIniDetail = _Cache.szIniRoot .. 'ShowDetail.ini'

local Data          -- 当前战斗数据记录
local DataDisplay   -- 当前显示的战斗记录
local History       -- 历史战斗记录
MY.RegisterInit(function()
    History = MY.Sys.LoadUserData(_Cache.szRecFile) or {}
    MY_Recount.InitData()
    DataDisplay = Data
end)
MY.RegisterExit(function()
    MY.Sys.SaveUserData(_Cache.szRecFile, History)
end)
MY.RegisterEvent('LOADING_END', function()
    local bNotHistory
    if Data == DataDisplay then
        bNotHistory = true
    end
    MY_Recount.PushData()
    MY_Recount.InitData(true)
    if bNotHistory then
        MY_Recount.DisplayData(0)
    end
end) -- 过图清数据

MY.RegisterEvent('MY_FIGHT_HINT', function(bEnterFight)
    if bEnterFight and MY.Player.GetFightUUID() ~= Data.UUID then -- 进入新的战斗
        MY_Recount.InitData()
        if DataDisplay == History[1] then
            DataDisplay = Data
        end
        MY_Recount.DrawUI()
    else
        Data.nTimeDuring = MY.Player.GetFightTime() / GLOBAL.GAME_FPS
        -- 计算受伤最多的名字作为战斗名称
        local nMaxValue, szBossName = 0, ''
        for id, p in pairs(Data.BeDamage) do
            if nMaxValue < p.nTotalEffect and id ~= UI_GetClientPlayerID() then
                nMaxValue  = p.nTotalEffect
                szBossName = _Cache.GetNameAusID(id, Data)
            end
        end
        Data.szBossName = szBossName
        
        local UUID = Data.UUID
        MY_Recount.PushData()
    end
end)

MY_Recount = {}
MY_Recount.bEnable       = true              -- 是否启用
MY_Recount.nCss          = 1                 -- 当前样式表
MY_Recount.nChannel      = CHANNEL.DPS       -- 当前显示的统计模式
MY_Recount.nMaxHistory   = 20                -- 最大历史记录
MY_Recount.bShowPerSec   = true              -- 显示为每秒数据（反之显示总和）
MY_Recount.bShowEffect   = true              -- 显示有效伤害/治疗
MY_Recount.nDisplayMode  = DISPLAY_MODE.BOTH -- 统计显示模式（显示NPC/玩家数据）（默认混合显示）
MY_Recount.nMinFightTime = 30
MY_Recount.nPublishLimit = 5
MY_Recount.anchor = { x=0, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" } -- 默认坐标
RegisterCustomData("MY_Recount.bEnable")
RegisterCustomData("MY_Recount.nCss")
RegisterCustomData("MY_Recount.nChannel")
RegisterCustomData("MY_Recount.nMaxHistory")
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
##################################################################################################
        #       #             #                     #     # # # # # # #       #     # # # # #     
    #   #   #   #             #     # # # # # #       #   #   #   #   #       #     #       #     
        #       #             #     #         #           #   #   #   #   # # # #   # # # # #     
  # # # # # #   # # # #   # # # #   # # # # # #           # # # # # # #     #                     
      # #     #     #         #     #     #       # # #       #             # #   # # # # # # #   
    #   # #     #   #         #     # # # # # #       #       # # # # #   #   #     #       #     
  #     #   #   #   #         # #   #     #           #   # #         #   # # # #   # # # # #     
      #         #   #     # # #     # # # # # #       #       #     #         #     #       #     
  # # # # #     #   #         #     # #       #       #         # #           # #   # # # # #     
    #     #       #           #   #   #       #       #   # # #           # # #     #       # #   
      # #       #   #         #   #   # # # # #     #   #                     #   # # # # # #     
  # #     #   #       #     # # #     #       #   #       # # # # # # #       #             #     
##################################################################################################
]]
--[[ 记录一次LOG
    MY_Recount.OnSkillEffect(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nSkillResult, nCount, tResult)
    (number) dwCaster    : 释放者ID
    (number) dwTarget    : 承受者ID
    (number) nEffectType : 造成效果的原因（SKILL_EFFECT_TYPE枚举 如SKILL,BUFF）
    (number) dwID        : 技能ID
    (number) dwLevel     : 技能等级
    (number) nSkillResult: 造成的效果结果（SKILL_RESULT枚举 如HIT,MISS）
    (number) nCount      : 造成效果的数值数量（tResult长度）
    (table ) tResult     : 所有效果数值集合
]]
MY_Recount.OnSkillEffect = function(dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nCount, tResult)
    -- 获取释放对象和承受对象
    local hCaster = MY.Game.GetObject(dwCaster)
    if hCaster and hCaster.dwEmployer and hCaster.dwEmployer ~= 0 then -- 宠物的数据算在主人统计中
        hCaster = MY.Game.GetObject(hCaster.dwEmployer)
    end
    local hTarget = MY.Game.GetObject(dwTarget)
    if not (hCaster and hTarget) then
        return
    end
    dwCaster = hCaster.dwID
    dwTarget = hTarget.dwID
    
    -- 获取效果名称
    local szEffectName
    if nEffectType == SKILL_EFFECT_TYPE.SKILL then
        szEffectName = Table_GetSkillName(dwEffectID, dwEffectLevel)
    elseif nEffectType == SKILL_EFFECT_TYPE.BUFF then
        szEffectName = Table_GetBuffName(dwEffectID, dwEffectLevel)
    end
    if not szEffectName then
        return
    end
    
    -- 过滤掉无伤害无治疗的命中效果记录
    if nSkillResult == SKILL_RESULT.HIT or nSkillResult == SKILL_RESULT.CRITICAL then
        local bRec
        for _, v in pairs(tResult) do
            if v > 0 then
                bRec = true
                break
            end
        end
        if not bRec then
            return
        end
    end
    
    -- 过滤掉不是队友的以及不是BOSS的
    local me = GetClientPlayer()
    local team = GetClientTeam()
    if (IsPlayer(dwCaster) and
    not (me.IsPlayerInMyParty(dwCaster) or team.IsPlayerInTeam(dwCaster) or dwCaster == me.dwID)) or -- 释放者是玩家且不是队友则忽视
    (not IsPlayer(dwCaster) and (hCaster.nIntensity ~= 2 and hCaster.nIntensity ~= 6)) -- 释放者是NPC却不是BOSS则忽视
    then
        return
    end
    
    
    local nTherapy = tResult[SKILL_RESULT_TYPE.THERAPY] or 0
    local nEffectTherapy = tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0
    local nDamage = (tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE      ] or 0) + -- 外功伤害
                    (tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE  ] or 0) + -- 阳性内功伤害
                    (tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] or 0) + -- 混元性内功伤害
                    (tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE  ] or 0) + -- 阴性内功伤害
                    (tResult[SKILL_RESULT_TYPE.POISON_DAMAGE       ] or 0) + -- 毒性伤害
                    (tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE   ] or 0)   -- 反弹伤害
    local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0

    if nSkillResult == SKILL_RESULT.HIT or
    nSkillResult == SKILL_RESULT.CRITICAL then -- 击中
        if nTherapy > 0 then -- 有治疗
            MY_Recount.AddHealRecord(hCaster, hTarget, szEffectName, nTherapy, nEffectTherapy, nSkillResult)
        end
        if nDamage > 0 then -- 有伤害
            MY_Recount.AddDamageRecord(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
        end
    elseif nSkillResult == SKILL_RESULT.BLOCK or  -- 格挡
    nSkillResult == SKILL_RESULT.SHIELD       or  -- 无效
    nSkillResult == SKILL_RESULT.MISS         or  -- 偏离
    nSkillResult == SKILL_RESULT.DODGE      then  -- 闪避
        MY_Recount.AddDamageRecord(hCaster, hTarget, szEffectName, 0, 0, nSkillResult)
    end
end

_Cache.GetNameAusID = function(id, data)
    if not id then
        return
    end
    if not data then
        data = DataDisplay
    end
    
    local dwID = tonumber(id)
    local szName
    if dwID then
        szName = data.Namelist[dwID]
    else
        szName = id
    end
    
    if not szName then
        szName = ''
    end
    return szName
end

-- 将一条记录插入数组
_Cache.AddRecord = function(tRecord, idTarget, szEffectName, nValue, nEffectValue, nSkillResult)
    tRecord.nTotal              = tRecord.nTotal + nValue
    tRecord.nTotalEffect        = tRecord.nTotalEffect + nEffectValue
    -- 添加/更新结果分类统计
    _Cache.InitResultDetailData(tRecord.Detail, nSkillResult)
    local tResult = tRecord.Detail[nSkillResult]
    tResult.nCount       = tResult.nCount + 1                                -- 命中次数（假设nSkillResult是命中）
    tResult.nMax         = math.max(tResult.nMax, nValue)                    -- 单次命中最大值
    tResult.nMaxEffect   = math.max(tResult.nMaxEffect, nEffectValue)        -- 单次命中最大有效值
    tResult.nMin         = (tResult.nMin ~= -1 and math.min(tResult.nMin, nValue)) or nValue                         -- 单次命中最小值
    tResult.nMinEffect   = (tResult.nMinEffect ~= -1 and math.min(tResult.nMinEffect, nEffectValue)) or nEffectValue -- 单次命中最小有效值
    tResult.nTotal       = tResult.nTotal + nValue                           -- 所以命中总伤害
    tResult.nTotalEffect = tResult.nTotalEffect + nEffectValue               -- 所有命中总有效伤害
    tResult.nAvg         = math.floor(tResult.nTotal / tResult.nCount)       -- 单次命中平均值
    tResult.nAvgEffect   = math.floor(tResult.nTotalEffect / tResult.nCount) -- 单次命中平均有效值
    -- 添加具体技能记录
    _Cache.InitSkillData(tRecord.Skill, szEffectName)
    local tSkillRecord = tRecord.Skill[szEffectName]
    tSkillRecord.nCount              = tSkillRecord.nCount + 1
    tSkillRecord.nMax                = math.max(tSkillRecord.nMax, nValue)
    tSkillRecord.nMaxEffect          = math.max(tSkillRecord.nMaxEffect, nEffectValue)
    tSkillRecord.nTotal              = tSkillRecord.nTotal + nValue
    tSkillRecord.nTotalEffect        = tSkillRecord.nTotalEffect + nEffectValue
    tSkillRecord.nAvg                = math.floor(tSkillRecord.nTotal / tSkillRecord.nCount)
    tSkillRecord.nAvgEffect          = math.floor(tSkillRecord.nTotalEffect / tSkillRecord.nCount)
    -- 添加/更新具体技能结果分类统计
    _Cache.InitResultDetailData(tSkillRecord.Detail, nSkillResult)
    local tResult = tSkillRecord.Detail[nSkillResult]
    tResult.nCount       = tResult.nCount + 1                           -- 命中次数（假设nSkillResult是命中）
    tResult.nMax         = math.max(tResult.nMax, nValue)               -- 单次命中最大值
    tResult.nMaxEffect   = math.max(tResult.nMaxEffect, nEffectValue)   -- 单次命中最大有效值
    tResult.nMin         = (tResult.nMin ~= -1 and math.min(tResult.nMin, nValue)) or nValue                         -- 单次命中最小值
    tResult.nMinEffect   = (tResult.nMinEffect ~= -1 and math.min(tResult.nMinEffect, nEffectValue)) or nEffectValue -- 单次命中最小有效值
    tResult.nTotal       = tResult.nTotal + nValue                      -- 所以命中总伤害
    tResult.nTotalEffect = tResult.nTotalEffect + nEffectValue          -- 所有命中总有效伤害
    tResult.nAvg         = math.floor(tResult.nTotal / tResult.nCount)
    tResult.nAvgEffect   = math.floor(tResult.nTotalEffect / tResult.nCount)
    -- 添加具体技能承受者记录
    _Cache.InitSkillTargetData(tSkillRecord.Target, idTarget)
    local tSkillTargetData = tSkillRecord.Target[idTarget]
    tSkillTargetData.nMax                = math.max(tSkillTargetData.nMax, nValue)
    tSkillTargetData.nMaxEffect          = math.max(tSkillTargetData.nMaxEffect, nEffectValue)
    tSkillTargetData.nTotal              = tSkillTargetData.nTotal + nValue
    tSkillTargetData.nTotalEffect        = tSkillTargetData.nTotalEffect + nEffectValue
    tSkillTargetData.Count[nSkillResult] = (tSkillTargetData.Count[nSkillResult] or 0) + 1
end

-- 插入一条伤害记录
MY_Recount.AddDamageRecord = function(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
    -- 获取索引ID
    local idCaster = (IsPlayer(hCaster.dwID) and hCaster.dwID) or MY.GetObjectName(hCaster)
    local idTarget = (IsPlayer(hTarget.dwID) and hTarget.dwID) or MY.GetObjectName(hTarget)
    
    -- 添加伤害记录
    _Cache.InitObjectData(Data, hCaster, 'Damage')
    _Cache.AddRecord(Data.Damage[idCaster], idTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
    -- 添加承伤记录
    _Cache.InitObjectData(Data, hTarget, 'BeDamage')
    _Cache.AddRecord(Data.BeDamage[idTarget], idCaster, szEffectName, nDamage, nEffectDamage, nSkillResult)
end

-- 插入一条治疗记录
MY_Recount.AddHealRecord = function(hCaster, hTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
    -- 获取索引ID
    local idCaster = (IsPlayer(hCaster.dwID) and hCaster.dwID) or MY.GetObjectName(hCaster)
    local idTarget = (IsPlayer(hTarget.dwID) and hTarget.dwID) or MY.GetObjectName(hTarget)
    
    -- 添加伤害记录
    _Cache.InitObjectData(Data, hCaster, 'Heal')
    _Cache.AddRecord(Data.Heal[idCaster], idTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
    -- 添加承伤记录
    _Cache.InitObjectData(Data, hTarget, 'BeHeal')
    _Cache.AddRecord(Data.BeHeal[idTarget], idCaster, szEffectName, nHeal, nEffectHeal, nSkillResult)
end

-- 初始化Data
MY_Recount.InitData = function(bForceInit)
    local bNew
    if bForceInit or (not Data) or
    (Data.UUID and MY.Player.GetFightUUID() ~= Data.UUID) then
        Data = {
            UUID        = MY.Player.GetFightUUID(), -- 战斗唯一标识
            nTimeBegin  = GetCurrentTime(),         -- 战斗开始时间
            nTimeDuring = 0,                        -- 战斗持续时间
            Namelist    = {},                       -- 名称缓存
            Forcelist   = {},                       -- 势力缓存
            Damage      = {},                       -- 输出统计
            Heal        = {},                       -- 治疗统计
            BeHeal      = {},                       -- 承疗统计
            BeDamage    = {},                       -- 承伤统计
        }
    end
    
    if not Data.UUID and MY.Player.GetFightUUID() then
        Data.UUID       = MY.Player.GetFightUUID()
        Data.nTimeBegin = GetCurrentTime()
    end
end

-- Data数据压入历史记录 并重新初始化Data
MY_Recount.PushData = function()
    if not (Data and Data.UUID) then
        return
    end
    
    if Data.nTimeDuring > MY_Recount.nMinFightTime then
        table.insert(History, 1, Data)
        while #History > MY_Recount.nMaxHistory do
            table.remove(History)
        end
    end
    
    MY_Recount.InitData(true)
end

-- 确认对象数据已创建（未创建则创建）
_Cache.InitObjectData = function(data, obj, szChannel)
    local id = (IsPlayer(obj.dwID) and obj.dwID) or MY.GetObjectName(obj)
    if IsPlayer(obj.dwID) and not data.Namelist[id] then
        -- 名称缓存
        data.Namelist[id] = MY.Game.GetObjectName(obj)
        -- 势力缓存
        data.Forcelist[id] = obj.dwForceID or 0
    end
    
    if szChannel and not data[szChannel][id] then
        data[szChannel][id] = {
            nTotal       = 0 , -- 总输出
            nTotalEffect = 0 , -- 有效输出
            Detail       = {}, -- 输出结果按技能结果分类统计
            Skill        = {}, -- 该玩家具体造成输出的技能统计
        }
    end
end

_Cache.InitResultDetailData = function(tDetail, nSkillResult)
    if not tDetail[nSkillResult] then
        tDetail[nSkillResult] = {
            nCount       =  0, -- 命中记录数量
            nMax         =  0, -- 单次命中最大值
            nMaxEffect   =  0, -- 单次命中最大有效值
            nMin         = -1, -- 单次命中最小值
            nMinEffect   = -1, -- 单次命中最小有效值
            nTotal       =  0, -- 所以命中总伤害
            nTotalEffect =  0, -- 所有命中总有效伤害
            nAvg         =  0, -- 所有命中平均伤害
            nAvgEffect   =  0, -- 所有命中平均有效伤害
        }
    end
end

_Cache.InitSkillData = function(tSkill, szSkillName)
    if not tSkill[szSkillName] then
        tSkill[szSkillName] = {
            nCount       =  0, -- 该玩家四象轮回释放次数
            nMax         =  0, -- 该玩家四象轮回最大输出量
            nMaxEffect   =  0, -- 该玩家四象轮回最大有效输出量
            nTotal       =  0, -- 该玩家四象轮回输出量总和
            nTotalEffect =  0, -- 该玩家四象轮回有效输出量总和
            Detail       = {}, -- 该玩家四象轮回输出结果分类统计
            Target       = {}, -- 该玩家四象轮回承受者统计
        }
    end
end
_Cache.InitSkillTargetData = function(tSkillTarget, id)
    if not tSkillTarget[id] then
        tSkillTarget[id] = {
            nMax         = 0,            -- 该玩家四象轮回击中的这个玩家最大伤害
            nMaxEffect   = 0,            -- 该玩家四象轮回击中的这个玩家最大有效伤害
            nTotal       = 0,            -- 该玩家四象轮回击中的这个玩家伤害总和
            nTotalEffect = 0,            -- 该玩家四象轮回击中的这个玩家有效伤害总和
            Count = {                    -- 该玩家四象轮回击中的这个玩家结果统计
                -- SKILL_RESULT.HIT      = 5,
                -- SKILL_RESULT.MISS     = 3,
                -- SKILL_RESULT.CRITICAL = 3,
            },
        }
    end
end

-- 系统日志监控（数据源）
MY.RegisterEvent('SYS_MSG', function()
    if arg0 == "UI_OME_SKILL_CAST_LOG" then
        -- 技能施放日志；
        -- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID (arg3)dwLevel：技能等级
        -- MY_Recount.OnSkillCast(arg1, arg2, arg3)
    elseif arg0 == "UI_OME_SKILL_CAST_RESPOND_LOG" then
        -- 技能施放结果日志；
        -- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID
        -- (arg3)dwLevel：技能等级 (arg4)nRespond：见枚举型[[SKILL_RESULT_CODE]]
        -- MY_Recount.OnSkillCastRespond(arg1, arg2, arg3, arg4)
    elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then
        -- 技能最终产生的效果（生命值的变化）；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID 
        -- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResultCount：数值集合
        -- MY_Recount.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        if arg7 and arg7 ~= 0 then -- bCriticalStrike
            MY_Recount.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.CRITICAL, arg8, arg9)
        else
            MY_Recount.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.HIT, arg8, arg9)
        end
    elseif arg0 == "UI_OME_SKILL_BLOCK_LOG" then
        -- 格挡日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)nType：Effect的类型
        -- (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级 (arg6)nDamageType：伤害类型，见枚举型[[SKILL_RESULT_TYPE]]
        MY_Recount.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.BLOCK, nil, {})
    elseif arg0 == "UI_OME_SKILL_SHIELD_LOG" then
        -- 技能被屏蔽日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        MY_Recount.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.SHIELD, nil, {})
    elseif arg0 == "UI_OME_SKILL_MISS_LOG" then
        -- 技能未命中目标日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        MY_Recount.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.MISS, nil, {})
    elseif arg0 == "UI_OME_SKILL_HIT_LOG" then
        -- 技能命中目标日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        -- MY_Recount.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.HIT, nil, {})
    elseif arg0 == "UI_OME_SKILL_DODGE_LOG" then
        -- 技能被闪避日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        MY_Recount.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.DODGE, nil, {})
    elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
        -- 普通治疗日志；
        -- (arg1)dwCharacterID：承疗玩家ID (arg2)nDeltaLife：增加血量值
        -- MY_Recount.OnCommonHealth(arg1, arg2)
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
MY_Recount.DisplayData = function(nHistory)
    if type(nHistory) == 'table' then
        DataDisplay = nHistory
    elseif nHistory == 0 then
        DataDisplay = Data
    elseif nHistory and History[nHistory] then
        DataDisplay = History[nHistory]
    end
    MY_Recount.DrawUI()
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
    local szIni = _Cache.szIniFile

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
                id           = id                           ,
                szName       = _Cache.GetNameAusID(id, data),
                dwForceID    = data.Forcelist[id] or -1     ,
                nValue       = rec.nTotal         or  0     ,
                nEffectValue = rec.nTotalEffect   or  0     ,
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
            hItem = hList:AppendItemFromIni(szIni, 'Handle_Item')
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
    MY_Recount.UpdateUI()
end

MY_Recount.OnFrameDragEnd = function()
    this:CorrectPos()
    MY_Recount.anchor = MY.UI(this):anchor()
end

-- ShowDetail界面时间相应
_Cache.OnDetailFrameBreathe = function()
    local id = this.id
    local szChannel = this.szChannel
    local szSkillName = this.szSkillName
    if tonumber(id) then
        id = tonumber(id)
    end
    -- 获取数据
    local tData = DataDisplay[szChannel][id]
    if not tData then
        return
    end
    
    --------------- 技能列表更新 -----------------
    -- 数据收集
    local tResult, nTotalEffect = {}, tData.nTotalEffect
    for szSkillName, p in pairs(tData.Skill) do
        table.insert(tResult, {
            szSkillName  = szSkillName   ,
            nCount       = p.nCount      ,
            nTotalEffect = p.nTotalEffect,
        })
    end
    table.sort(tResult, function(p1, p2)
        return p1.nTotalEffect > p2.nTotalEffect
    end)
    -- 界面重绘
    local hList = this:Lookup('WndScroll_Skill', 'Handle_SkillList')
    hList:Clear()
    for i, p in ipairs(tResult) do
        local hItem = hList:AppendItemFromIni(_Cache.szIniDetail, 'Handle_SkillItem')
        hItem:Lookup('Text_SkillNo'):SetText(i)
        hItem:Lookup('Text_SkillName'):SetText(p.szSkillName)
        hItem:Lookup('Text_SkillCount'):SetText(p.nCount)
        hItem:Lookup('Text_SkillTotal'):SetText(p.nTotalEffect)
        hItem:Lookup('Text_SkillPercentage'):SetText((math.floor(p.nTotalEffect / nTotalEffect * 1000) / 10) .. '%')
        if szSkillName == p.szSkillName then
            hItem:Lookup('Shadow_SkillEntry'):Show()
        end
        hItem.szSkillName = p.szSkillName
    end
    hList:FormatAllItemPos()
    
    if szSkillName and tData.Skill[szSkillName] then
        --------------- 技能释放结果列表更新 -----------------
        -- 数据收集
        local tResult, nTotalEffect = {}, tData.Skill[szSkillName].nTotalEffect
        for nSkillResult, p in pairs(tData.Skill[szSkillName].Detail) do
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
            hItem:Lookup('Text_DetailPercent'):SetText((math.floor(p.nTotalEffect / nTotalEffect * 1000) / 10) .. '%')
        end
        hList:FormatAllItemPos()
        
        --------------- 技能释放结果列表更新 -----------------
        -- 数据收集
        local tResult, nTotalEffect = {}, tData.Skill[szSkillName].nTotalEffect
        for id, p in pairs(tData.Skill[szSkillName].Target) do
            table.insert(tResult, {
                nHitCount      = p.Count[SKILL_RESULT.HIT] or 0,
                nMissCount     = p.Count[SKILL_RESULT.MISS] or 0,
                nCriticalCount = p.Count[SKILL_RESULT.CRITICAL] or 0,
                nMaxEffect     = p.nMaxEffect,
                nTotalEffect   = p.nTotalEffect,
                szName         = _Cache.GetNameAusID(id, DataDisplay),
            })
        end
        table.sort(tResult, function(p1, p2)
            return p1.nTotalEffect > p2.nTotalEffect
        end)
        -- 界面重绘
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
            hItem:Lookup('Text_TargetPercent'):SetText((math.floor(p.nTotalEffect / nTotalEffect * 1000) / 10) .. '%')
        end
        hList:FormatAllItemPos()
    else
        this:Lookup('WndScroll_Detail', 'Handle_DetailList'):Clear()
        this:Lookup('WndScroll_Detail', 'Handle_DetailList'):FormatAllItemPos()
        this:Lookup('WndScroll_Target', 'Handle_TargetList'):Clear()
        this:Lookup('WndScroll_Target', 'Handle_TargetList'):FormatAllItemPos()
    end
    
end
_Cache.OnDetailLButtonClick = function()
    local name = this:GetName()
    if name == 'Btn_Close' then
        Wnd.CloseWindow(this:GetRoot())
    end
end
_Cache.OnDetailItemLButtonDown = function()
    local name = this:GetName()
    if name == 'Handle_SkillItem' then
        this:GetRoot().szSkillName = this.szSkillName
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
            frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
            frm.OnFrameBreathe = _Cache.OnDetailFrameBreathe
            frm.OnItemLButtonDown = _Cache.OnDetailItemLButtonDown
            frm:Lookup('', 'Text_Default'):SetText(_Cache.GetNameAusID(id, DataDisplay) .. ' ' .. SZ_CHANNEL[MY_Recount.nChannel])
            
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
        MY_Recount.InitData(true)
        DataDisplay = Data
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
            bChecked = MY_Recount.nMinFightTime == i,
            fnAction = function()
                MY_Recount.nMinFightTime = i
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
            bChecked = MY_Recount.nMaxHistory == i,
            fnAction = function()
                MY_Recount.nMaxHistory = i
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
        rgb = (Data == DataDisplay and {255, 255, 0}) or nil,
        fnAction = function()
            MY_Recount.DisplayData(0)
        end,
    }}
    
    for _, data in ipairs(History) do
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