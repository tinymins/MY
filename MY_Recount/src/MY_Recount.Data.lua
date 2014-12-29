--
-- 战斗统计 数据收集处理部分
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
-- 
--[[
[SKILL_RESULT_TYPE]枚举：
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
                    nCount       = 2     ,                    -- 该玩家四象轮回输出次数
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
                            nAvg         = 27818 ,            -- 该玩家四象轮回单次命中平均值
                            nAvgEffect   = 27818 ,            -- 该玩家四象轮回单次命中平均有效值
                            nTotal       = 278560,            -- 该玩家四象轮回所有命中总伤害
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
            },
            Target = {                                        -- 该玩家具体造成输出的对象统计
                玩家dwID = {                                  -- 该玩家对该dwID的玩家造成的输出统计
                    nCount       = 2     ,                    -- 该玩家对该dwID的玩家输出次数
                    nMax         = 13415 ,                    -- 该玩家对该dwID的玩家单次最大输出量
                    nMaxEffect   = 9080  ,                    -- 该玩家对该dwID的玩家单次最大有效输出量
                    nTotal       = 23213 ,                    -- 该玩家对该dwID的玩家输出量总和
                    nTotalEffect = 321421,                    -- 该玩家对该dwID的玩家有效输出量总和
                    Detail = {                                -- 该玩家对该dwID的玩家输出结果分类统计
                        SKILL_RESULT.HIT = {                    
                            nCount       = 10    ,            -- 该玩家对该dwID的玩家命中记录数量
                            nMax         = 34210 ,            -- 该玩家对该dwID的玩家单次命中最大值
                            nMaxEffect   = 29817 ,            -- 该玩家对该dwID的玩家单次命中最大有效值
                            nMin         = 8790  ,            -- 该玩家对该dwID的玩家单次命中最小值
                            nMinEffect   = 7657  ,            -- 该玩家对该dwID的玩家单次命中最小有效值
                            nAvg         = 27818 ,            -- 该玩家对该dwID的玩家单次命中平均值
                            nAvgEffect   = 27818 ,            -- 该玩家对该dwID的玩家单次命中平均有效值
                            nTotal       = 278560,            -- 该玩家对该dwID的玩家所有命中总伤害
                            nTotalEffect = 224750,            -- 该玩家对该dwID的玩家所有命中总有效伤害
                        },
                        SKILL_RESULT.MISS = { ... },
                        SKILL_RESULT.CRITICAL = { ... },
                    },
                    Skill = {                                 -- 该玩家四象轮回承受者统计
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
            },
        },
        NPC的名字 = { ... },
    },
    Heal = { ... },
    BeHeal = { ... },
    BeDamage = { ... },
}
]]
local SKILL_RESULT = {
    HIT     = 0, -- 命中
    BLOCK   = 1, -- 格挡
    SHIELD  = 2, -- 无效
    MISS    = 3, -- 偏离
    DODGE   = 4, -- 闪避
    CRITICAL= 5, -- 会心
    INSIGHT = 6, -- 识破
}

MY_Recount = MY_Recount or {}
MY_Recount.Data = {}
MY_Recount.Data.nMaxHistory   = 20
MY_Recount.Data.nMinFightTime = 30

local _Cache = {
    szRecFile = 'cache/FIGHT_RECOUNT_LOG/data',
}
local Data          -- 当前战斗数据记录
local History       -- 历史战斗记录

--[[
##################################################################################################
            #                 #         #             #         #                 # # # # # # #   
  # # # # # # # # # # #       #   #     #             #         #         # # #   #     #     #   
      #     #     #         #     #     #             # # # #   #           #     #     #     #   
      # # # # # # #         #     # # # # # # #       #     #   # #         #     # # # # # # #   
            #             # #   #       #           #       #   #   #       #     #     #     #   
    # # # # # # # # #       #           #           #       #   #     #   # # #   #     #     #   
            #       #       #           #         #   #   #     #     #     #     # # # # # # #   
  # # # # # # # # # # #     #   # # # # # # # #       #   #     #           #           #         
            #       #       #           #               #       #           #     # # # # # # #   
    # # # # # # # # #       #           #             #   #     #           # #         #         
            #               #           #           #       #             # #           #         
          # #               #           #         #           # # # # #         # # # # # # # #   
##################################################################################################
]]
-- 登陆游戏加载保存的数据
MY.RegisterInit(function()
    local data = MY.Sys.LoadUserData(_Cache.szRecFile) or {}
    History                       = data.History       or {}
    MY_Recount.Data.nMaxHistory   = data.nMaxHistory   or 20
    MY_Recount.Data.nMinFightTime = data.nMinFightTime or 30
    MY_Recount.Data.Init()
end)

-- 退出游戏保存数据
MY.RegisterExit(function()
    local data = {
        History       = History,
        nMaxHistory   = MY_Recount.Data.nMaxHistory  ,
        nMinFightTime = MY_Recount.Data.nMinFightTime,
    }
    MY.Sys.SaveUserData(_Cache.szRecFile, data)
end)

-- 过图清除当前战斗数据
MY.RegisterEvent('LOADING_END', function()
    MY_Recount.Data.Push()
    MY_Recount.Data.Init(true)
    FireUIEvent('MY_RECOUNT_NEW_FIGHT')
end)

-- 退出战斗 保存数据
MY.RegisterEvent('MY_FIGHT_HINT', function(bEnterFight)
    if bEnterFight and MY.Player.GetFightUUID() ~= Data.UUID then -- 进入新的战斗
        MY_Recount.Data.Init()
        FireUIEvent('MY_RECOUNT_NEW_FIGHT')
    else
        Data.nTimeDuring = MY.Player.GetFightTime() / GLOBAL.GAME_FPS
        -- 计算受伤最多的名字作为战斗名称
        local nMaxValue, szBossName = 0, ''
        for id, p in pairs(Data.BeDamage) do
            if nMaxValue < p.nTotalEffect and id ~= UI_GetClientPlayerID() then
                nMaxValue  = p.nTotalEffect
                szBossName = MY_Recount.Data.GetNameAusID(id, Data)
            end
        end
        Data.szBossName = szBossName
        
        MY_Recount.Data.Push()
    end
end)

--[[
##################################################################################################
                            #           #             #       #                                   
    # # # # # # # # #         #         #             #         #           # # # # # # # # #     
        #       #                       #             #   # # # # # # #     #               #     
        #       #         # # # # #     # # # #   # # # #   #       #       #               #     
        #       #           #         #     #         #       #   #         #               #     
        #       #           #       #   #   #         #   # # # # # # #     #               #     
  # # # # # # # # # # #     # # # #     #   #         # #       #           #               #     
        #       #           #     #     #   #     # # #   # # # # # # #     #               #     
        #       #           #     #     #   #         #       #     #       #               #     
      #         #           #     #       #           #     # #     #       # # # # # # # # #     
      #         #           #     #     #   #         #         # #         #               #     
    #           #         #     # #   #       #     # #   # # #     # #                           
##################################################################################################
]]
--[[ 获取统计数据
    (table) MY_Recount.Data.Get(nIndex) -- 获取指定记录
        (number)nIndex: 历史记录索引 为0返回当前统计
    (table) MY_Recount.Data.Get()       -- 获取所有历史记录列表
]]
MY_Recount.Data.Get = function(nIndex)
    if not nIndex then
        return History
    elseif nIndex == 0 then
        return Data
    else
        return History[nIndex]
    end
end

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
MY_Recount.Data.OnSkillEffect = function(dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nCount, tResult)
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
    if (IsPlayer(dwCaster) and not (me.IsPlayerInMyParty(dwCaster) or team.IsPlayerInTeam(dwCaster) or dwCaster == me.dwID)) then
        -- 释放者是玩家且不是队友则忽视
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
            MY_Recount.Data.AddHealRecord(hCaster, hTarget, szEffectName, nTherapy, nEffectTherapy, nSkillResult)
        end
        if nDamage > 0 then -- 有伤害
            MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
        end
    elseif nSkillResult == SKILL_RESULT.BLOCK or  -- 格挡
    nSkillResult == SKILL_RESULT.SHIELD       or  -- 无效
    nSkillResult == SKILL_RESULT.MISS         or  -- 偏离
    nSkillResult == SKILL_RESULT.DODGE      then  -- 闪避
        MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, 0, 0, nSkillResult)
    end
    
    -- 识破
    local nValue = tResult[SKILL_RESULT_TYPE.INSIGHT_DAMAGE]
    if nValue and nValue > 0 then
        MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, SKILL_RESULT.INSIGHT)
    end
end

MY_Recount.Data.GetNameAusID = function(id, data)
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
    
    ------------------------
    -- # 节： tRecord.Detail
    ------------------------
    -- 添加/更新结果分类统计
    if not tRecord.Detail[nSkillResult] then
        tRecord.Detail[nSkillResult] = {
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
    
    ------------------------
    -- # 节： tRecord.Skill
    ------------------------
    -- 添加具体技能记录
    if not tRecord.Skill[szEffectName] then
        tRecord.Skill[szEffectName] = {
            nCount       =  0, -- 该玩家四象轮回释放次数
            nMax         =  0, -- 该玩家四象轮回最大输出量
            nMaxEffect   =  0, -- 该玩家四象轮回最大有效输出量
            nTotal       =  0, -- 该玩家四象轮回输出量总和
            nTotalEffect =  0, -- 该玩家四象轮回有效输出量总和
            Detail       = {}, -- 该玩家四象轮回输出结果分类统计
            Target       = {}, -- 该玩家四象轮回承受者统计
        }
    end
    local tSkillRecord = tRecord.Skill[szEffectName]
    tSkillRecord.nCount              = tSkillRecord.nCount + 1
    tSkillRecord.nMax                = math.max(tSkillRecord.nMax, nValue)
    tSkillRecord.nMaxEffect          = math.max(tSkillRecord.nMaxEffect, nEffectValue)
    tSkillRecord.nTotal              = tSkillRecord.nTotal + nValue
    tSkillRecord.nTotalEffect        = tSkillRecord.nTotalEffect + nEffectValue
    tSkillRecord.nAvg                = math.floor(tSkillRecord.nTotal / tSkillRecord.nCount)
    tSkillRecord.nAvgEffect          = math.floor(tSkillRecord.nTotalEffect / tSkillRecord.nCount)
    
    ---------------------------------
    -- # 节： tRecord.Skill[x].Detail
    ---------------------------------
    -- 添加/更新具体技能结果分类统计
    if not tSkillRecord.Detail[nSkillResult] then
        tSkillRecord.Detail[nSkillResult] = {
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
    
    ------------------------------
    -- # 节： tRecord.Skill.Target
    ------------------------------
    -- 添加具体技能承受者记录
    if not tSkillRecord.Target[idTarget] then
        tSkillRecord.Target[idTarget] = {
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
    local tSkillTargetData = tSkillRecord.Target[idTarget]
    tSkillTargetData.nMax                = math.max(tSkillTargetData.nMax, nValue)
    tSkillTargetData.nMaxEffect          = math.max(tSkillTargetData.nMaxEffect, nEffectValue)
    tSkillTargetData.nTotal              = tSkillTargetData.nTotal + nValue
    tSkillTargetData.nTotalEffect        = tSkillTargetData.nTotalEffect + nEffectValue
    tSkillTargetData.Count[nSkillResult] = (tSkillTargetData.Count[nSkillResult] or 0) + 1
    
    ------------------------
    -- # 节： tRecord.Target
    ------------------------
    -- 添加具体承受/释放者记录
    if not tRecord.Target[idTarget] then
        tRecord.Target[idTarget] = {
            nCount       =  0, -- 该玩家对idTarget的技能释放次数
            nMax         =  0, -- 该玩家对idTarget的技能最大输出量
            nMaxEffect   =  0, -- 该玩家对idTarget的技能最大有效输出量
            nTotal       =  0, -- 该玩家对idTarget的技能输出量总和
            nTotalEffect =  0, -- 该玩家对idTarget的技能有效输出量总和
            Detail       = {}, -- 该玩家对idTarget的技能输出结果分类统计
            Skill        = {}, -- 该玩家对idTarget的技能具体分别统计
        }
    end
    local tTargetRecord = tRecord.Target[idTarget]
    tTargetRecord.nCount              = tTargetRecord.nCount + 1
    tTargetRecord.nMax                = math.max(tTargetRecord.nMax, nValue)
    tTargetRecord.nMaxEffect          = math.max(tTargetRecord.nMaxEffect, nEffectValue)
    tTargetRecord.nTotal              = tTargetRecord.nTotal + nValue
    tTargetRecord.nTotalEffect        = tTargetRecord.nTotalEffect + nEffectValue
    tTargetRecord.nAvg                = math.floor(tTargetRecord.nTotal / tTargetRecord.nCount)
    tTargetRecord.nAvgEffect          = math.floor(tTargetRecord.nTotalEffect / tTargetRecord.nCount)
    
    ----------------------------------
    -- # 节： tRecord.Target[x].Detail
    ----------------------------------
    -- 添加/更新具体承受/释放者结果分类统计
    if not tTargetRecord.Detail[nSkillResult] then
        tTargetRecord.Detail[nSkillResult] = {
            nCount       =  0, -- 命中记录数量（假设nSkillResult是命中）
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
    local tResult = tTargetRecord.Detail[nSkillResult]
    tResult.nCount       = tResult.nCount + 1                           -- 命中次数（假设nSkillResult是命中）
    tResult.nMax         = math.max(tResult.nMax, nValue)               -- 单次命中最大值
    tResult.nMaxEffect   = math.max(tResult.nMaxEffect, nEffectValue)   -- 单次命中最大有效值
    tResult.nMin         = (tResult.nMin ~= -1 and math.min(tResult.nMin, nValue)) or nValue                         -- 单次命中最小值
    tResult.nMinEffect   = (tResult.nMinEffect ~= -1 and math.min(tResult.nMinEffect, nEffectValue)) or nEffectValue -- 单次命中最小有效值
    tResult.nTotal       = tResult.nTotal + nValue                      -- 所以命中总伤害
    tResult.nTotalEffect = tResult.nTotalEffect + nEffectValue          -- 所有命中总有效伤害
    tResult.nAvg         = math.floor(tResult.nTotal / tResult.nCount)
    tResult.nAvgEffect   = math.floor(tResult.nTotalEffect / tResult.nCount)
    
    ---------------------------------
    -- # 节： tRecord.Target[x].Skill
    ---------------------------------
    -- 添加承受者具体技能记录
    if not tTargetRecord.Skill[szEffectName] then
        tTargetRecord.Skill[szEffectName] = {
            nMax         = 0,            -- 该玩家击中这个玩家的四象轮回最大伤害
            nMaxEffect   = 0,            -- 该玩家击中这个玩家的四象轮回最大有效伤害
            nTotal       = 0,            -- 该玩家击中这个玩家的四象轮回伤害总和
            nTotalEffect = 0,            -- 该玩家击中这个玩家的四象轮回有效伤害总和
            Count = {                    -- 该玩家击中这个玩家的四象轮回结果统计
                -- SKILL_RESULT.HIT      = 5,
                -- SKILL_RESULT.MISS     = 3,
                -- SKILL_RESULT.CRITICAL = 3,
            },
        }
    end
    local tTargetSkillData = tTargetRecord.Skill[szEffectName]
    tTargetSkillData.nMax                = math.max(tTargetSkillData.nMax, nValue)
    tTargetSkillData.nMaxEffect          = math.max(tTargetSkillData.nMaxEffect, nEffectValue)
    tTargetSkillData.nTotal              = tTargetSkillData.nTotal + nValue
    tTargetSkillData.nTotalEffect        = tTargetSkillData.nTotalEffect + nEffectValue
    tTargetSkillData.Count[nSkillResult] = (tTargetSkillData.Count[nSkillResult] or 0) + 1
end

-- 插入一条伤害记录
MY_Recount.Data.AddDamageRecord = function(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
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
MY_Recount.Data.AddHealRecord = function(hCaster, hTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
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

-- 确认对象数据已创建（未创建则创建）
_Cache.InitObjectData = function(data, obj, szChannel)
    local id = (IsPlayer(obj.dwID) and obj.dwID) or MY.GetObjectName(obj)
    if IsPlayer(obj.dwID) and not data.Namelist[id] then
        data.Namelist[id]  = MY.Game.GetObjectName(obj) -- 名称缓存
        data.Forcelist[id] = obj.dwForceID or 0         -- 势力缓存
    end
    
    if not data[szChannel][id] then
        data[szChannel][id] = {
            nTotal       = 0 ,                    -- 总输出
            nTotalEffect = 0 ,                    -- 有效输出
            Detail       = {},                    -- 输出结果按技能结果分类统计
            Skill        = {},                    -- 该玩家具体造成输出的技能统计
            Target       = {},                    -- 该玩家具体对谁造成输出的统计
        }
    end
end

-- 初始化Data
MY_Recount.Data.Init = function(bForceInit)
    local bNew
    if bForceInit or (not Data) or
    (Data.UUID and MY.Player.GetFightUUID() ~= Data.UUID) then
        Data = {
            UUID        = MY.Player.GetFightUUID(), -- 战斗唯一标识
            nTimeBegin  = GetCurrentTime(),         -- 战斗开始时间
            nTimeDuring =  0,                       -- 战斗持续时间
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
MY_Recount.Data.Push = function()
    if not (Data and Data.UUID) then
        return
    end
    
    if Data.nTimeDuring > MY_Recount.Data.nMinFightTime then
        table.insert(History, 1, Data)
        while #History > MY_Recount.Data.nMaxHistory do
            table.remove(History)
        end
    end
    
    MY_Recount.Data.Init(true)
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
        -- MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        if arg7 and arg7 ~= 0 then -- bCriticalStrike
            MY_Recount.Data.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.CRITICAL, arg8, arg9)
        else
            MY_Recount.Data.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.HIT, arg8, arg9)
        end
    elseif arg0 == "UI_OME_SKILL_BLOCK_LOG" then
        -- 格挡日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)nType：Effect的类型
        -- (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级 (arg6)nDamageType：伤害类型，见枚举型[[SKILL_RESULT_TYPE]]
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.BLOCK, nil, {})
    elseif arg0 == "UI_OME_SKILL_SHIELD_LOG" then
        -- 技能被屏蔽日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.SHIELD, nil, {})
    elseif arg0 == "UI_OME_SKILL_MISS_LOG" then
        -- 技能未命中目标日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.MISS, nil, {})
    elseif arg0 == "UI_OME_SKILL_HIT_LOG" then
        -- 技能命中目标日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        -- MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.HIT, nil, {})
    elseif arg0 == "UI_OME_SKILL_DODGE_LOG" then
        -- 技能被闪避日志；
        -- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
        -- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.DODGE, nil, {})
    elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
        -- 普通治疗日志；
        -- (arg1)dwCharacterID：承疗玩家ID (arg2)nDeltaLife：增加血量值
        -- MY_Recount.OnCommonHealth(arg1, arg2)
    end
end)