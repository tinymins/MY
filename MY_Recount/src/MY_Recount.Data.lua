--
-- ս��ͳ�� �����ռ�������
-- by ���� @ ˫���� @ ݶ����
-- Build 20140730
-- 
--[[
[SKILL_RESULT_TYPE]ö�٣�
SKILL_RESULT_TYPE.PHYSICS_DAMAGE       = 0  -- �⹦�˺�
SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE   = 1  -- �����ڹ��˺�
SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE = 2  -- ��Ԫ���ڹ��˺�
SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE   = 3  -- �����ڹ��˺�
SKILL_RESULT_TYPE.POISON_DAMAGE        = 4  -- �����˺�
SKILL_RESULT_TYPE.REFLECTIED_DAMAGE    = 5  -- �����˺�
SKILL_RESULT_TYPE.THERAPY              = 6  -- ����
SKILL_RESULT_TYPE.STEAL_LIFE           = 7  -- ����͵ȡ(<D0>��<D1>�����<D2>����Ѫ��)
SKILL_RESULT_TYPE.ABSORB_THERAPY       = 8  -- ��������
SKILL_RESULT_TYPE.ABSORB_DAMAGE        = 9  -- �����˺�
SKILL_RESULT_TYPE.SHIELD_DAMAGE        = 10 -- ��Ч�˺�
SKILL_RESULT_TYPE.PARRY_DAMAGE         = 11 -- ����
SKILL_RESULT_TYPE.INSIGHT_DAMAGE       = 12 -- ʶ��
SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE     = 13 -- ��Ч�˺�
SKILL_RESULT_TYPE.EFFECTIVE_THERAPY    = 14 -- ��Ч����
SKILL_RESULT_TYPE.TRANSFER_LIFE        = 15 -- ��ȡ����
SKILL_RESULT_TYPE.TRANSFER_MANA        = 16 -- ��ȡ����

-- Data DataDisplay History[] ���ݽṹ
Data = {
    UUID = ս��ͳһ��ʾ��,
    nTimeBegin  = ս����ʼUNIXʱ���,
    nTimeDuring = ս����������,
    LastRecTime = {
        Damage = ���һ���˺����ܼ�¼UNIXʱ���,
        Heal   = ���һ�����Ƽ��ܼ�¼UNIXʱ���,
        ...
    },
    Damage = {                                                -- ���ͳ��
        ��ҵ�dwID = {                                        -- �ö�������ͳ��
            nTotal       = 2314214,                           -- �����
            nTotalEffect = 132144 ,                           -- ��Ч���
            Detail = {                                        -- ����������ͳ��
                SKILL_RESULT.HIT = {
                    nCount       = 10    ,                    -- ���м�¼����
                    nMax         = 34210 ,                    -- �����������ֵ
                    nMaxEffect   = 29817 ,                    -- �������������Чֵ
                    nMin         = 8790  ,                    -- ����������Сֵ
                    nMinEffect   = 7657  ,                    -- ����������С��Чֵ
                    nAvg         = 27818 ,                    -- ��������ƽ��ֵ
                    nAvgEffect   = 27818 ,                    -- ��������ƽ����Чֵ
                    nTotal       = 278560,                    -- �����������˺�
                    nTotalEffect = 224750,                    -- ������������Ч�˺�
                },
                SKILL_RESULT.MISS = { ... },
                SKILL_RESULT.CRITICAL = { ... },
            },
            Skill = {                                         -- ����Ҿ����������ļ���ͳ��
                �����ֻ� = {                                  -- ����������ֻ���ɵ����ͳ��
                    nCount       = 2     ,                    -- ����������ֻ��������
                    nMax         = 13415 ,                    -- ����������ֻ���������
                    nMaxEffect   = 9080  ,                    -- ����������ֻ������Ч�����
                    nTotal       = 23213 ,                    -- ����������ֻ�������ܺ�
                    nTotalEffect = 321421,                    -- ����������ֻ���Ч������ܺ�
                    Detail = {                                -- ����������ֻ�����������ͳ��
                        SKILL_RESULT.HIT = {                    
                            nCount       = 10    ,            -- ����������ֻ����м�¼����
                            nMax         = 34210 ,            -- ����������ֻص����������ֵ
                            nMaxEffect   = 29817 ,            -- ����������ֻص������������Чֵ
                            nMin         = 8790  ,            -- ����������ֻص���������Сֵ
                            nMinEffect   = 7657  ,            -- ����������ֻص���������С��Чֵ
                            nAvg         = 27818 ,            -- ����������ֻص�������ƽ��ֵ
                            nAvgEffect   = 27818 ,            -- ����������ֻص�������ƽ����Чֵ
                            nTotal       = 278560,            -- ����������ֻ������������˺�
                            nTotalEffect = 224750,            -- ����������ֻ�������������Ч�˺�
                        },
                        SKILL_RESULT.MISS = { ... },
                        SKILL_RESULT.CRITICAL = { ... },
                    },
                    Target = {                                -- ����������ֻس�����ͳ��
                        ���dwID = {                          -- ����������ֻػ��е�����������ͳ��
                            nMax         = 13415 ,            -- ����������ֻػ��е�����������˺�
                            nMaxEffect   = 9080  ,            -- ����������ֻػ��е������������Ч�˺�
                            nTotal       = 23213 ,            -- ����������ֻػ��е��������˺��ܺ�
                            nTotalEffect = 321421,            -- ����������ֻػ��е���������Ч�˺��ܺ�
                            Count = {                         -- ����������ֻػ��е������ҽ��ͳ��
                                SKILL_RESULT.HIT      = 5,
                                SKILL_RESULT.MISS     = 3,
                                SKILL_RESULT.CRITICAL = 3,
                            },
                        },
                        Npc���� = { ... },
                        ...
                    },
                }, 
                ���ǻ��� = { ... },
                ...
            },
            Target = {                                        -- ����Ҿ����������Ķ���ͳ��
                ���dwID = {                                  -- ����ҶԸ�dwID�������ɵ����ͳ��
                    nCount       = 2     ,                    -- ����ҶԸ�dwID������������
                    nMax         = 13415 ,                    -- ����ҶԸ�dwID����ҵ�����������
                    nMaxEffect   = 9080  ,                    -- ����ҶԸ�dwID����ҵ��������Ч�����
                    nTotal       = 23213 ,                    -- ����ҶԸ�dwID�����������ܺ�
                    nTotalEffect = 321421,                    -- ����ҶԸ�dwID�������Ч������ܺ�
                    Detail = {                                -- ����ҶԸ�dwID���������������ͳ��
                        SKILL_RESULT.HIT = {                    
                            nCount       = 10    ,            -- ����ҶԸ�dwID��������м�¼����
                            nMax         = 34210 ,            -- ����ҶԸ�dwID����ҵ����������ֵ
                            nMaxEffect   = 29817 ,            -- ����ҶԸ�dwID����ҵ������������Чֵ
                            nMin         = 8790  ,            -- ����ҶԸ�dwID����ҵ���������Сֵ
                            nMinEffect   = 7657  ,            -- ����ҶԸ�dwID����ҵ���������С��Чֵ
                            nAvg         = 27818 ,            -- ����ҶԸ�dwID����ҵ�������ƽ��ֵ
                            nAvgEffect   = 27818 ,            -- ����ҶԸ�dwID����ҵ�������ƽ����Чֵ
                            nTotal       = 278560,            -- ����ҶԸ�dwID����������������˺�
                            nTotalEffect = 224750,            -- ����ҶԸ�dwID�����������������Ч�˺�
                        },
                        SKILL_RESULT.MISS = { ... },
                        SKILL_RESULT.CRITICAL = { ... },
                    },
                    Skill = {                                 -- ����������ֻس�����ͳ��
                        ���dwID = {                          -- ����������ֻػ��е�����������ͳ��
                            nMax         = 13415 ,            -- ����������ֻػ��е�����������˺�
                            nMaxEffect   = 9080  ,            -- ����������ֻػ��е������������Ч�˺�
                            nTotal       = 23213 ,            -- ����������ֻػ��е��������˺��ܺ�
                            nTotalEffect = 321421,            -- ����������ֻػ��е���������Ч�˺��ܺ�
                            Count = {                         -- ����������ֻػ��е������ҽ��ͳ��
                                SKILL_RESULT.HIT      = 5,
                                SKILL_RESULT.MISS     = 3,
                                SKILL_RESULT.CRITICAL = 3,
                            },
                        },
                        Npc���� = { ... },
                        ...
                    },
                },
            },
        },
        NPC������ = { ... },
    },
    Heal = { ... },
    BeHeal = { ... },
    BeDamage = { ... },
    Summary = {
        nDamage = ȫ�ӵ������,
        nEffectDamage = ȫ�ӵ���Ч�����,
        ...
    },
}
]]
local SKILL_RESULT = {
    HIT     = 0, -- ����
    BLOCK   = 1, -- ��
    SHIELD  = 2, -- ��Ч
    MISS    = 3, -- ƫ��
    DODGE   = 4, -- ����
    CRITICAL= 5, -- ����
    INSIGHT = 6, -- ʶ��
}
local AWAYTIME_TYPE = {
    DEATH          = 0,
    OFFLINE        = 1,
    HALFWAY_JOINED = 2,
}

MY_Recount = MY_Recount or {}
MY_Recount.Data = {}
MY_Recount.Data.nMaxHistory   = 10
MY_Recount.Data.nMinFightTime = 30

local _Cache = {
    szRecFile = 'cache/FIGHT_RECOUNT_LOG/',
}
local Data          -- ��ǰս�����ݼ�¼
local History = {}  -- ��ʷս����¼

-- ##################################################################################################
--             #                 #         #             #         #                 # # # # # # #   
--   # # # # # # # # # # #       #   #     #             #         #         # # #   #     #     #   
--       #     #     #         #     #     #             # # # #   #           #     #     #     #   
--       # # # # # # #         #     # # # # # # #       #     #   # #         #     # # # # # # #   
--             #             # #   #       #           #       #   #   #       #     #     #     #   
--     # # # # # # # # #       #           #           #       #   #     #   # # #   #     #     #   
--             #       #       #           #         #   #   #     #     #     #     # # # # # # #   
--   # # # # # # # # # # #     #   # # # # # # # #       #   #     #           #           #         
--             #       #       #           #               #       #           #     # # # # # # #   
--     # # # # # # # # #       #           #             #   #     #           # #         #         
--             #               #           #           #       #             # #           #         
--           # #               #           #         #           # # # # #         # # # # # # # #   
-- ##################################################################################################
-- ��½��Ϸ���ر��������
MY_Recount.Data.LoadData = function()
    local data = MY.Sys.LoadUserData(_Cache.szRecFile) or {}
    History                       = data.History       or {}
    MY_Recount.Data.nMaxHistory   = data.nMaxHistory   or 10
    MY_Recount.Data.nMinFightTime = data.nMinFightTime or 30
    MY_Recount.Data.Init()
end

-- �˳���Ϸ��������
MY_Recount.Data.SaveData = function()
    local data = {
        History       = History,
        nMaxHistory   = MY_Recount.Data.nMaxHistory  ,
        nMinFightTime = MY_Recount.Data.nMinFightTime,
    }
    MY.Sys.SaveUserData(_Cache.szRecFile, data)
end

-- ��ͼ�����ǰս������
MY.RegisterEvent('LOADING_END', function()
    MY_Recount.Data.Push()
    MY_Recount.Data.Init(true)
    FireUIEvent('MY_RECOUNT_NEW_FIGHT')
end)

-- �˳�ս�� ��������
MY.RegisterEvent('MY_FIGHT_HINT', function(event)
    if arg0 and MY.Player.GetFightUUID() ~= Data.UUID then -- �����µ�ս��
        MY_Recount.Data.Init()
        FireUIEvent('MY_RECOUNT_NEW_FIGHT')
    else
        MY_Recount.Data.Push()
    end
end)
MY.BreatheCall('MY_Recount_FightTime', function()
    if MY.Player.IsFighting() then
        Data.nTimeDuring = GetCurrentTime() - Data.nTimeBegin
    end
end)

-- ##################################################################################################
--                             #           #             #       #                                   
--     # # # # # # # # #         #         #             #         #           # # # # # # # # #     
--         #       #                       #             #   # # # # # # #     #               #     
--         #       #         # # # # #     # # # #   # # # #   #       #       #               #     
--         #       #           #         #     #         #       #   #         #               #     
--         #       #           #       #   #   #         #   # # # # # # #     #               #     
--   # # # # # # # # # # #     # # # #     #   #         # #       #           #               #     
--         #       #           #     #     #   #     # # #   # # # # # # #     #               #     
--         #       #           #     #     #   #         #       #     #       #               #     
--       #         #           #     #       #           #     # #     #       # # # # # # # # #     
--       #         #           #     #     #   #         #         # #         #               #     
--     #           #         #     # #   #       #     # #   # # #     # #                           
-- ##################################################################################################
-- ��ȡͳ������
-- (table) MY_Recount.Data.Get(nIndex) -- ��ȡָ����¼
--     (number)nIndex: ��ʷ��¼���� Ϊ0���ص�ǰͳ��
-- (table) MY_Recount.Data.Get()       -- ��ȡ������ʷ��¼�б�
MY_Recount.Data.Get = function(nIndex)
    if not nIndex then
        return History
    elseif nIndex == 0 then
        return Data
    else
        return History[nIndex]
    end
end

-- ɾ����ʷͳ������
-- (table) MY_Recount.Data.Del(nIndex) -- ɾ��ָ����ŵļ�¼
--     (number)nIndex: ��ʷ��¼����
-- (table) MY_Recount.Data.Del(data)   -- ɾ��ָ����¼
MY_Recount.Data.Del = function(data)
    if type(data) == 'number' then
        table.remove(History, data)
    else
        for i = #History, 1, -1 do
            if History[i] == data then
                table.remove(History, i)
            end
        end
    end
end

-- ��������ʱ��
-- MY_Recount.Data.GeneAwayTime(data, dwID, szRecordType)
-- data: ����
-- dwID: ��������Ľ�ɫID Ϊ��������Ŷӵ�����ʱ�䣨Ŀǰ��ԶΪ0��
-- szRecordType: ��ͬ���͵������ڹٷ�ʱ���㷨�¼��������ܲ�һ��
--               ö����ʱ�� Heal Damage BeDamage BeHeal ����
MY_Recount.Data.GeneAwayTime = function(data, dwID, szRecordType)
    local nFightTime = MY_Recount.Data.GeneFightTime(data, dwID, szRecordType)
    local nAwayTime
    if szRecordType and data.LastRecTime and data.LastRecTime[szRecordType] then
        nAwayTime = data.LastRecTime[szRecordType] - data.nTimeBegin - nFightTime
    else
        nAwayTime = data.nTimeDuring - nFightTime
    end
    return math.max(nAwayTime, 0)
end

-- ����ս��ʱ��
-- MY_Recount.Data.GeneFightTime(data, dwID, szRecordType)
-- data: ����
-- dwID: ����ս��ʱ��Ľ�ɫID Ϊ��������Ŷӵ�ս��ʱ��
-- szRecordType: ��ͬ���͵������ڹٷ�ʱ���㷨�¼��������ܲ�һ��
--               ö����ʱ�� Heal Damage BeDamage BeHeal ����
MY_Recount.Data.GeneFightTime = function(data, dwID, szRecordType)
    local nTimeDuring = data.nTimeDuring
    local nTimeBegin  = data.nTimeBegin
    if szRecordType and data.LastRecTime and data.LastRecTime[szRecordType] then
        nTimeDuring = data.LastRecTime[szRecordType] - nTimeBegin
    end
    if dwID and data.Awaytime and data.Awaytime[dwID] then
        for _, rec in ipairs(data.Awaytime[dwID]) do
            local nAwayBegin = math.max(rec[1], nTimeBegin)
            local nAwayEnd   = rec[2]
            if nAwayEnd then -- �������뿪��¼
                nTimeDuring = nTimeDuring - (nAwayEnd - nAwayBegin)
            else -- �뿪������û�����ļ�¼
                nTimeDuring = nTimeDuring - (data.nTimeBegin + nTimeDuring - nAwayBegin)
                break
            end
        end
    end
    return math.max(nTimeDuring, 0)
end

-- ##################################################################################################
--         #       #             #                     #     # # # # # # #       #     # # # # #     
--     #   #   #   #             #     # # # # # #       #   #   #   #   #       #     #       #     
--         #       #             #     #         #           #   #   #   #   # # # #   # # # # #     
--   # # # # # #   # # # #   # # # #   # # # # # #           # # # # # # #     #                     
--       # #     #     #         #     #     #       # # #       #             # #   # # # # # # #   
--     #   # #     #   #         #     # # # # # #       #       # # # # #   #   #     #       #     
--   #     #   #   #   #         # #   #     #           #   # #         #   # # # #   # # # # #     
--       #         #   #     # # #     # # # # # #       #       #     #         #     #       #     
--   # # # # #     #   #         #     # #       #       #         # #           # #   # # # # #     
--     #     #       #           #   #   #       #       #   # # #           # # #     #       # #   
--       # #       #   #         #   #   # # # # #     #   #                     #   # # # # # #     
--   # #     #   #       #     # # #     #       #   #       # # # # # # #       #             #     
-- ##################################################################################################
-- ��¼һ��LOG
-- MY_Recount.OnSkillEffect(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nSkillResult, nCount, tResult)
-- (number) dwCaster    : �ͷ���ID
-- (number) dwTarget    : ������ID
-- (number) nEffectType : ���Ч����ԭ��SKILL_EFFECT_TYPEö�� ��SKILL,BUFF��
-- (number) dwID        : ����ID
-- (number) dwLevel     : ���ܵȼ�
-- (number) nSkillResult: ��ɵ�Ч�������SKILL_RESULTö�� ��HIT,MISS��
-- (number) nCount      : ���Ч������ֵ������tResult���ȣ�
-- (table ) tResult     : ����Ч����ֵ����
MY_Recount.Data.OnSkillEffect = function(dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nCount, tResult)
    -- ��ȡ�ͷŶ���ͳ��ܶ���
    local hCaster = MY.Game.GetObject(dwCaster)
    if (not IsPlayer(dwCaster)) and hCaster and hCaster.dwEmployer and hCaster.dwEmployer ~= 0 then -- �����������������ͳ����
        hCaster = MY.Game.GetObject(hCaster.dwEmployer)
    end
    local hTarget = MY.Game.GetObject(dwTarget)
    if not (hCaster and hTarget) then
        return
    end
    dwCaster = hCaster.dwID
    dwTarget = hTarget.dwID
    
    -- ��ȡЧ������
    local szEffectName
    if nEffectType == SKILL_EFFECT_TYPE.SKILL then
        szEffectName = Table_GetSkillName(dwEffectID, dwEffectLevel)
    elseif nEffectType == SKILL_EFFECT_TYPE.BUFF then
        szEffectName = Table_GetBuffName(dwEffectID, dwEffectLevel) .. '(BUFF)'
    end
    if not szEffectName then
        return
    end
    
    -- ���˵����˺������Ƶ�����Ч����¼
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
    
    -- ���˵����Ƕ��ѵ��Լ�����BOSS��
    local me = GetClientPlayer()
    local team = GetClientTeam()
    if (IsPlayer(dwCaster) and not (me.IsPlayerInMyParty(dwCaster) or team.IsPlayerInTeam(dwCaster) or dwCaster == me.dwID)) then
        -- �ͷ���������Ҳ��Ƕ��������
        return
    end
    
    
    local nTherapy = tResult[SKILL_RESULT_TYPE.THERAPY] or 0
    local nEffectTherapy = tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0
    local nDamage = (tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE      ] or 0) + -- �⹦�˺�
                    (tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE  ] or 0) + -- �����ڹ��˺�
                    (tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] or 0) + -- ��Ԫ���ڹ��˺�
                    (tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE  ] or 0) + -- �����ڹ��˺�
                    (tResult[SKILL_RESULT_TYPE.POISON_DAMAGE       ] or 0) + -- �����˺�
                    (tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE   ] or 0)   -- �����˺�
    local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0

    -- ʶ��
    local nValue = tResult[SKILL_RESULT_TYPE.INSIGHT_DAMAGE]
    if nValue and nValue > 0 then
        MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, SKILL_RESULT.INSIGHT)
    elseif nSkillResult == SKILL_RESULT.HIT or
    nSkillResult == SKILL_RESULT.CRITICAL then -- ����
        if nTherapy > 0 then -- ������
            MY_Recount.Data.AddHealRecord(hCaster, hTarget, szEffectName, nTherapy, nEffectTherapy, nSkillResult)
        end
        if nDamage > 0 then -- ���˺�
            MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
        end
    elseif nSkillResult == SKILL_RESULT.BLOCK or  -- ��
    nSkillResult == SKILL_RESULT.SHIELD       or  -- ��Ч
    nSkillResult == SKILL_RESULT.MISS         or  -- ƫ��
    nSkillResult == SKILL_RESULT.DODGE      then  -- ����
        MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, 0, 0, nSkillResult)
    end
    
    Data.nTimeDuring = GetCurrentTime() - Data.nTimeBegin
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

-- ��һ����¼��������
_Cache.AddRecord = function(data, szRecordType, idRecord, idTarget, szEffectName, nValue, nEffectValue, nSkillResult)
    local tSummary = data.Summary
    local tRecords = data[szRecordType]
    local tRecord  = tRecords[idRecord]
    if not szEffectName or szEffectName == "" then
        return
    end
    data.LastRecTime[szRecordType] = GetCurrentTime()
    ------------------------
    -- # �ڣ� data.Summary
    ------------------------
    tSummary['n'       .. szRecordType] = tSummary['n'       .. szRecordType] + nValue
    tSummary['nEffect' .. szRecordType] = tSummary['nEffect' .. szRecordType] + nEffectValue
    ------------------------
    -- # �ڣ� tRecord
    ------------------------
    tRecord.nTotal        = tRecord.nTotal + nValue
    tRecord.nTotalEffect  = tRecord.nTotalEffect + nEffectValue
    ------------------------
    -- # �ڣ� tRecord.Detail
    ------------------------
    -- ���/���½������ͳ��
    if not tRecord.Detail[nSkillResult] then
        tRecord.Detail[nSkillResult] = {
            nCount       =  0, -- ���м�¼����
            nMax         =  0, -- �����������ֵ
            nMaxEffect   =  0, -- �������������Чֵ
            nMin         = -1, -- ����������Сֵ
            nMinEffect   = -1, -- ����������С��Чֵ
            nTotal       =  0, -- �����������˺�
            nTotalEffect =  0, -- ������������Ч�˺�
            nAvg         =  0, -- ��������ƽ���˺�
            nAvgEffect   =  0, -- ��������ƽ����Ч�˺�
        }
    end
    local tResult = tRecord.Detail[nSkillResult]
    tResult.nCount       = tResult.nCount + 1                                -- ���д���������nSkillResult�����У�
    tResult.nMax         = math.max(tResult.nMax, nValue)                    -- �����������ֵ
    tResult.nMaxEffect   = math.max(tResult.nMaxEffect, nEffectValue)        -- �������������Чֵ
    tResult.nMin         = (tResult.nMin ~= -1 and math.min(tResult.nMin, nValue)) or nValue                         -- ����������Сֵ
    tResult.nMinEffect   = (tResult.nMinEffect ~= -1 and math.min(tResult.nMinEffect, nEffectValue)) or nEffectValue -- ����������С��Чֵ
    tResult.nTotal       = tResult.nTotal + nValue                           -- �����������˺�
    tResult.nTotalEffect = tResult.nTotalEffect + nEffectValue               -- ������������Ч�˺�
    tResult.nAvg         = math.floor(tResult.nTotal / tResult.nCount)       -- ��������ƽ��ֵ
    tResult.nAvgEffect   = math.floor(tResult.nTotalEffect / tResult.nCount) -- ��������ƽ����Чֵ
    
    ------------------------
    -- # �ڣ� tRecord.Skill
    ------------------------
    -- ��Ӿ��弼�ܼ�¼
    if not tRecord.Skill[szEffectName] then
        tRecord.Skill[szEffectName] = {
            nCount       =  0, -- ����������ֻ��ͷŴ���
            nMax         =  0, -- ����������ֻ���������
            nMaxEffect   =  0, -- ����������ֻ������Ч�����
            nTotal       =  0, -- ����������ֻ�������ܺ�
            nTotalEffect =  0, -- ����������ֻ���Ч������ܺ�
            Detail       = {}, -- ����������ֻ�����������ͳ��
            Target       = {}, -- ����������ֻس�����ͳ��
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
    -- # �ڣ� tRecord.Skill[x].Detail
    ---------------------------------
    -- ���/���¾��弼�ܽ������ͳ��
    if not tSkillRecord.Detail[nSkillResult] then
        tSkillRecord.Detail[nSkillResult] = {
            nCount       =  0, -- ���м�¼����
            nMax         =  0, -- �����������ֵ
            nMaxEffect   =  0, -- �������������Чֵ
            nMin         = -1, -- ����������Сֵ
            nMinEffect   = -1, -- ����������С��Чֵ
            nTotal       =  0, -- �����������˺�
            nTotalEffect =  0, -- ������������Ч�˺�
            nAvg         =  0, -- ��������ƽ���˺�
            nAvgEffect   =  0, -- ��������ƽ����Ч�˺�
        }
    end
    local tResult = tSkillRecord.Detail[nSkillResult]
    tResult.nCount       = tResult.nCount + 1                           -- ���д���������nSkillResult�����У�
    tResult.nMax         = math.max(tResult.nMax, nValue)               -- �����������ֵ
    tResult.nMaxEffect   = math.max(tResult.nMaxEffect, nEffectValue)   -- �������������Чֵ
    tResult.nMin         = (tResult.nMin ~= -1 and math.min(tResult.nMin, nValue)) or nValue                         -- ����������Сֵ
    tResult.nMinEffect   = (tResult.nMinEffect ~= -1 and math.min(tResult.nMinEffect, nEffectValue)) or nEffectValue -- ����������С��Чֵ
    tResult.nTotal       = tResult.nTotal + nValue                      -- �����������˺�
    tResult.nTotalEffect = tResult.nTotalEffect + nEffectValue          -- ������������Ч�˺�
    tResult.nAvg         = math.floor(tResult.nTotal / tResult.nCount)
    tResult.nAvgEffect   = math.floor(tResult.nTotalEffect / tResult.nCount)
    
    ------------------------------
    -- # �ڣ� tRecord.Skill.Target
    ------------------------------
    -- ��Ӿ��弼�ܳ����߼�¼
    if not tSkillRecord.Target[idTarget] then
        tSkillRecord.Target[idTarget] = {
            nMax         = 0,            -- ����������ֻػ��е�����������˺�
            nMaxEffect   = 0,            -- ����������ֻػ��е������������Ч�˺�
            nTotal       = 0,            -- ����������ֻػ��е��������˺��ܺ�
            nTotalEffect = 0,            -- ����������ֻػ��е���������Ч�˺��ܺ�
            Count = {                    -- ����������ֻػ��е������ҽ��ͳ��
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
    -- # �ڣ� tRecord.Target
    ------------------------
    -- ��Ӿ������/�ͷ��߼�¼
    if not tRecord.Target[idTarget] then
        tRecord.Target[idTarget] = {
            nCount       =  0, -- ����Ҷ�idTarget�ļ����ͷŴ���
            nMax         =  0, -- ����Ҷ�idTarget�ļ�����������
            nMaxEffect   =  0, -- ����Ҷ�idTarget�ļ��������Ч�����
            nTotal       =  0, -- ����Ҷ�idTarget�ļ���������ܺ�
            nTotalEffect =  0, -- ����Ҷ�idTarget�ļ�����Ч������ܺ�
            Detail       = {}, -- ����Ҷ�idTarget�ļ�������������ͳ��
            Skill        = {}, -- ����Ҷ�idTarget�ļ��ܾ���ֱ�ͳ��
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
    -- # �ڣ� tRecord.Target[x].Detail
    ----------------------------------
    -- ���/���¾������/�ͷ��߽������ͳ��
    if not tTargetRecord.Detail[nSkillResult] then
        tTargetRecord.Detail[nSkillResult] = {
            nCount       =  0, -- ���м�¼����������nSkillResult�����У�
            nMax         =  0, -- �����������ֵ
            nMaxEffect   =  0, -- �������������Чֵ
            nMin         = -1, -- ����������Сֵ
            nMinEffect   = -1, -- ����������С��Чֵ
            nTotal       =  0, -- �����������˺�
            nTotalEffect =  0, -- ������������Ч�˺�
            nAvg         =  0, -- ��������ƽ���˺�
            nAvgEffect   =  0, -- ��������ƽ����Ч�˺�
        }
    end
    local tResult = tTargetRecord.Detail[nSkillResult]
    tResult.nCount       = tResult.nCount + 1                           -- ���д���������nSkillResult�����У�
    tResult.nMax         = math.max(tResult.nMax, nValue)               -- �����������ֵ
    tResult.nMaxEffect   = math.max(tResult.nMaxEffect, nEffectValue)   -- �������������Чֵ
    tResult.nMin         = (tResult.nMin ~= -1 and math.min(tResult.nMin, nValue)) or nValue                         -- ����������Сֵ
    tResult.nMinEffect   = (tResult.nMinEffect ~= -1 and math.min(tResult.nMinEffect, nEffectValue)) or nEffectValue -- ����������С��Чֵ
    tResult.nTotal       = tResult.nTotal + nValue                      -- �����������˺�
    tResult.nTotalEffect = tResult.nTotalEffect + nEffectValue          -- ������������Ч�˺�
    tResult.nAvg         = math.floor(tResult.nTotal / tResult.nCount)
    tResult.nAvgEffect   = math.floor(tResult.nTotalEffect / tResult.nCount)
    
    ---------------------------------
    -- # �ڣ� tRecord.Target[x].Skill
    ---------------------------------
    -- ��ӳ����߾��弼�ܼ�¼
    if not tTargetRecord.Skill[szEffectName] then
        tTargetRecord.Skill[szEffectName] = {
            nMax         = 0,            -- ����һ��������ҵ������ֻ�����˺�
            nMaxEffect   = 0,            -- ����һ��������ҵ������ֻ������Ч�˺�
            nTotal       = 0,            -- ����һ��������ҵ������ֻ��˺��ܺ�
            nTotalEffect = 0,            -- ����һ��������ҵ������ֻ���Ч�˺��ܺ�
            Count = {                    -- ����һ��������ҵ������ֻؽ��ͳ��
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

-- ����һ���˺���¼
MY_Recount.Data.AddDamageRecord = function(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
    -- ��ȡ����ID
    local idCaster = (IsPlayer(hCaster.dwID) and hCaster.dwID) or MY.GetObjectName(hCaster) or g_tStrings.STR_NAME_UNKNOWN
    local idTarget = (IsPlayer(hTarget.dwID) and hTarget.dwID) or MY.GetObjectName(hTarget) or g_tStrings.STR_NAME_UNKNOWN
    
    -- ����˺���¼
    _Cache.InitObjectData(Data, hCaster, 'Damage')
    _Cache.AddRecord(Data, 'Damage'  , idCaster, idTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
    -- ��ӳ��˼�¼
    _Cache.InitObjectData(Data, hTarget, 'BeDamage')
    _Cache.AddRecord(Data, 'BeDamage', idTarget, idCaster, szEffectName, nDamage, nEffectDamage, nSkillResult)
end

-- ����һ�����Ƽ�¼
MY_Recount.Data.AddHealRecord = function(hCaster, hTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
    -- ��ȡ����ID
    local idCaster = (IsPlayer(hCaster.dwID) and hCaster.dwID) or MY.GetObjectName(hCaster) or g_tStrings.STR_NAME_UNKNOWN
    local idTarget = (IsPlayer(hTarget.dwID) and hTarget.dwID) or MY.GetObjectName(hTarget) or g_tStrings.STR_NAME_UNKNOWN
    
    -- ����˺���¼
    _Cache.InitObjectData(Data, hCaster, 'Heal')
    _Cache.AddRecord(Data, 'Heal'    , idCaster, idTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
    -- ��ӳ��˼�¼
    _Cache.InitObjectData(Data, hTarget, 'BeHeal')
    _Cache.AddRecord(Data, 'BeHeal'  , idTarget, idCaster, szEffectName, nHeal, nEffectHeal, nSkillResult)
end

-- ȷ�϶��������Ѵ�����δ�����򴴽���
_Cache.InitObjectData = function(data, obj, szChannel)
    local id = (IsPlayer(obj.dwID) and obj.dwID) or MY.GetObjectName(obj) or g_tStrings.STR_NAME_UNKNOWN
    if IsPlayer(obj.dwID) and not data.Namelist[id] then
        data.Namelist[id]  = MY.Game.GetObjectName(obj) -- ���ƻ���
        data.Forcelist[id] = obj.dwForceID or 0         -- ��������
    end
    
    if not data[szChannel][id] then
        data[szChannel][id] = {
            szMD5        = obj.dwID, -- Ψһ��ʶ
            nTotal       = 0       , -- �����
            nTotalEffect = 0       , -- ��Ч���
            Detail       = {}      , -- �����������ܽ������ͳ��
            Skill        = {}      , -- ����Ҿ����������ļ���ͳ��
            Target       = {}      , -- ����Ҿ����˭��������ͳ��
        }
    end
end

-- ��ʼ��Data
MY_Recount.Data.Init = function(bForceInit)
    local bNew
    if bForceInit or (not Data) or
    (Data.UUID and MY.Player.GetFightUUID() ~= Data.UUID) then
        Data = {
            UUID         = MY.Player.GetFightUUID(), -- ս��Ψһ��ʶ
            nTimeBegin   = GetCurrentTime(),         -- ս����ʼʱ��
            nTimeDuring  =  0,                       -- ս������ʱ��
            Awaytime     = {},                       -- ����/����ʱ��ڵ�
            Namelist     = {},                       -- ���ƻ���
            Forcelist    = {},                       -- ��������
            Damage       = {},                       -- ���ͳ��
            Heal         = {},                       -- ����ͳ��
            BeHeal       = {},                       -- ����ͳ��
            BeDamage     = {},                       -- ����ͳ��
            LastRecTime  = {},                       -- ���һ�μ�¼ʱ��
            Summary      = {                         -- ͳ���ܺ�
                nDamage   = 0, nEffectDamage   = 0,
                nHeal     = 0, nEffectHeal     = 0,
                nBeHeal   = 0, nEffectBeHeal   = 0,
                nBeDamage = 0, nEffectBeDamage = 0,
            },
        }
    end
    
    if not Data.UUID and MY.Player.GetFightUUID() then
        Data.UUID       = MY.Player.GetFightUUID()
        Data.nTimeBegin = GetCurrentTime()
    end
end

-- Data����ѹ����ʷ��¼ �����³�ʼ��Data
MY_Recount.Data.Push = function()
    if not (Data and Data.UUID) then
        return
    end
    
    -- ������������������Ϊս������
    local nMaxValue, szBossName = 0, nil
    for id, p in pairs(Data.BeDamage) do
        if nMaxValue < p.nTotalEffect and id ~= UI_GetClientPlayerID() then
            nMaxValue  = p.nTotalEffect
            szBossName = MY_Recount.Data.GetNameAusID(id, Data)
        end
    end
    -- ���û�� ������������NPC������Ϊս������
    if not szBossName then
        for id, p in pairs(Data.Damage) do
            if nMaxValue < p.nTotalEffect and not tonumber(id) then
                nMaxValue  = p.nTotalEffect
                szBossName = MY_Recount.Data.GetNameAusID(id, Data)
            end
        end
    end
    Data.szBossName = szBossName or ''
    
    if Data.nTimeDuring > MY_Recount.Data.nMinFightTime then
        table.insert(History, 1, Data)
        while #History > MY_Recount.Data.nMaxHistory do
            table.remove(History)
        end
    end
    
    MY_Recount.Data.Init(true)
end

-- ϵͳ��־��أ�����Դ��
MY.RegisterEvent('SYS_MSG', function()
    if arg0 == "UI_OME_SKILL_CAST_LOG" then
        -- ����ʩ����־��
        -- (arg1)dwCaster������ʩ���� (arg2)dwSkillID������ID (arg3)dwLevel�����ܵȼ�
        -- MY_Recount.OnSkillCast(arg1, arg2, arg3)
    elseif arg0 == "UI_OME_SKILL_CAST_RESPOND_LOG" then
        -- ����ʩ�Ž����־��
        -- (arg1)dwCaster������ʩ���� (arg2)dwSkillID������ID
        -- (arg3)dwLevel�����ܵȼ� (arg4)nRespond����ö����[[SKILL_RESULT_CODE]]
        -- MY_Recount.OnSkillCastRespond(arg1, arg2, arg3, arg4)
    elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then
        -- δ��ս���ʼ��ͳ�����ݣ���Ĭ�ϵ�ǰ֡���еļ�����־Ϊ��ս���ܣ�
        if not MY.Player.GetFightUUID() and
        _Cache.nLastAutoInitFrame ~= GetLogicFrameCount() then
            _Cache.nLastAutoInitFrame = GetLogicFrameCount()
            MY_Recount.Data.Init(true)
        end
        -- �������ղ�����Ч��������ֵ�ı仯����
        -- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)bReact���Ƿ�Ϊ���� (arg4)nType��Effect���� (arg5)dwID:Effect��ID 
        -- (arg6)dwLevel��Effect�ĵȼ� (arg7)bCriticalStrike���Ƿ���� (arg8)nCount��tResultCount���ݱ���Ԫ�ظ��� (arg9)tResultCount����ֵ����
        -- MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        if arg7 and arg7 ~= 0 then -- bCriticalStrike
            MY_Recount.Data.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.CRITICAL, arg8, arg9)
        else
            MY_Recount.Data.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.HIT, arg8, arg9)
        end
    elseif arg0 == "UI_OME_SKILL_BLOCK_LOG" then
        -- ����־��
        -- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)nType��Effect������
        -- (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ� (arg6)nDamageType���˺����ͣ���ö����[[SKILL_RESULT_TYPE]]
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.BLOCK, nil, {})
    elseif arg0 == "UI_OME_SKILL_SHIELD_LOG" then
        -- ���ܱ�������־��
        -- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
        -- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.SHIELD, nil, {})
    elseif arg0 == "UI_OME_SKILL_MISS_LOG" then
        -- ����δ����Ŀ����־��
        -- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� 
        -- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.MISS, nil, {})
    elseif arg0 == "UI_OME_SKILL_HIT_LOG" then
        -- ��������Ŀ����־��
        -- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
        -- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
        -- MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.HIT, nil, {})
    elseif arg0 == "UI_OME_SKILL_DODGE_LOG" then
        -- ���ܱ�������־��
        -- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
        -- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
        MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.DODGE, nil, {})
    elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
        -- ��ͨ������־��
        -- (arg1)dwCharacterID���������ID (arg2)nDeltaLife������Ѫ��ֵ
        -- MY_Recount.OnCommonHealth(arg1, arg2)
    end
end)

-- �������˻�����һ��ʱ�����¼
_Cache.OnTeammateStateChange = function(dwID, bLeave, nAwayType, bAddWhenRecEmpty)
    if not (Data and Data.Awaytime) then
        return
    end
    -- ���һ���˵ļ�¼
    local rec = Data.Awaytime[dwID]
    if not rec then -- ��ʼ��һ����¼
        if not bLeave and not bAddWhenRecEmpty then
            return -- ����һ������Ŀ�ʼ���Ҳ�ǿ�Ƽ�¼������
        end
        rec = {}
        Data.Awaytime[dwID] = rec
    elseif #rec > 0 then -- ����߼�
        if bLeave then -- ��������
            if not rec[#rec][2] then -- �������һ����¼��������
                return
            end
        else -- ���˻���
            if rec[#rec][2] then -- ���ұ������ǻ��
                return
            end
        end
    end
    -- �������ݵ���¼
    if bLeave then -- ���뿪ʼ
        table.insert(rec, { GetCurrentTime(), nil, nAwayType })
    else -- �������
        if #rec == 0 then -- û��¼�����뿪ʼ ����һ���ӱ���ս����ʼ�����루�׳ƻ�û����������ˡ�����
            table.insert(rec, { Data.nTimeBegin, GetCurrentTime(), nAwayType })
        elseif not rec[#rec][2] then -- ������һ�����뻹û���� ��������һ������ļ�¼
            rec[#rec][2] = GetCurrentTime()
        end
    end
end
MY.RegisterEvent('PARTY_UPDATE_MEMBER_INFO', function()
    local team = GetClientTeam()
    local info = team.GetMemberInfo(arg1)
    if info then
        _Cache.OnTeammateStateChange(arg1, info.bDeathFlag, AWAYTIME_TYPE.DEATH, false)
    end
end)
MY.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', function()
    if arg2 == 0 then -- ���˵���
        _Cache.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.OFFLINE, false)
    else -- ��������
        _Cache.OnTeammateStateChange(arg1, false, AWAYTIME_TYPE.OFFLINE, false)
        local team = GetClientTeam()
        local info = team.GetMemberInfo(arg1)
        if info and info.bDeathFlag then -- �������ŵ� ������������ ��ʼ��������
            _Cache.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.DEATH, false)
        end
    end
end)
MY.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- ��սɨ����� ��¼��ս������/���ߵ���
    local team = GetClientTeam()
    local me = GetClientPlayer()
    if team and me and (me.IsInParty() or me.IsInRaid()) then
        for _, dwID in ipairs(team.GetTeamMemberList()) do
            local info = team.GetMemberInfo(dwID)
            if info then
                if not info.bIsOnLine then
                    _Cache.OnTeammateStateChange(dwID, true, AWAYTIME_TYPE.OFFLINE, true)
                elseif info.bDeathFlag then
                    _Cache.OnTeammateStateChange(dwID, true, AWAYTIME_TYPE.DEATH, true)
                end
            end
        end
    end
end)
MY.RegisterEvent('PARTY_ADD_MEMBER', function() -- ��;���˽��� ���������¼
    local team = GetClientTeam()
    local info = team.GetMemberInfo(arg1)
    if info then
        _Cache.OnTeammateStateChange(arg1, false, AWAYTIME_TYPE.HALFWAY_JOINED, true)
        if info.bDeathFlag then
            _Cache.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.DEATH, true)
        end
    end
end)
