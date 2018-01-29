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
	nVersion = 数据版本号,
	nTimeBegin  = 战斗开始UNIX时间戳,
	nTimeDuring = 战斗持续秒数,
	bDistinctTargetID = 该数据是否根据目标ID区分同名记录,
	bDistinctEffectID = 该数据是否根据效果ID区分同名记录,
	Awaytime = {
		玩家的dwID = {
			{ 暂离开始时间, 暂离结束时间 }, ...
		}, ...
	},
	Damage = {                                                -- 输出统计
		nTimeDuring = 最后一次记录时离开始的秒数,
		nTotal = 全队的输出量,
		nTotalEffect = 全队的有效输出量,
		Snapshots = {
			{
				nTimeDuring  = 当前快照战斗秒数,
				nTotal       = 当前快照时间全队输出量,
				nTotalEffect = 当前快照时间全队有效输出量,
				Statistics   = {
					玩家的dwID = {
						nTotal       = 当前快照时间该玩家总输出量,
						nTotalEffect = 当前快照时间该玩家总有效输出量,
					},
					NPC的名字 = { ... },
				},
			}, ...
		},
		Statistics = {
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
local AWAYTIME_TYPE = {
	DEATH          = 0,
	OFFLINE        = 1,
	HALFWAY_JOINED = 2,
}
local VERSION = 1

MY_Recount = MY_Recount or {}
MY_Recount.Data = {}
MY_Recount.Data.nMaxHistory       = 10
MY_Recount.Data.nMinFightTime     = 30
MY_Recount.Data.bRecAnonymous     = true
MY_Recount.Data.bIgnoreZeroEffect = false
MY_Recount.Data.bDistinctTargetID = false
MY_Recount.Data.bDistinctEffectID = false

local _Cache = {}
local Data          -- 当前战斗数据记录
local History = {}  -- 历史战斗记录
local SZ_REC_FILE = '$uid@$lang/cache/fight_recount_log.jx3dat'

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
-- 登陆游戏加载保存的数据
function MY_Recount.Data.LoadData(bLoadHistory)
	local data = MY.LoadLUAData(SZ_REC_FILE)
	if data then
		if bLoadHistory then
			History = data.History or {}
			for i = #History, 1, -1 do
				if History[i].nVersion ~= VERSION then
					table.remove(History, i)
				end
			end
		end
		MY_Recount.Data.nMaxHistory       = data.nMaxHistory   or 10
		MY_Recount.Data.nMinFightTime     = data.nMinFightTime or 30
		MY_Recount.Data.bRecAnonymous     = MY.FormatDataStructure(data.bRecAnonymous, true)
		MY_Recount.Data.bIgnoreZeroEffect = MY.FormatDataStructure(data.bIgnoreZeroEffect, false)
		MY_Recount.Data.bDistinctTargetID = MY.FormatDataStructure(data.bDistinctTargetID, false)
		MY_Recount.Data.bDistinctEffectID = MY.FormatDataStructure(data.bDistinctEffectID, false)
	end
	MY_Recount.Data.Init()
end

-- 退出游戏保存数据
function MY_Recount.Data.SaveData(bSaveHistory)
	local data = {
		History = bSaveHistory and History or nil,
		nMaxHistory       = MY_Recount.Data.nMaxHistory,
		nMinFightTime     = MY_Recount.Data.nMinFightTime,
		bRecAnonymous     = MY_Recount.Data.bRecAnonymous,
		bIgnoreZeroEffect = MY_Recount.Data.bIgnoreZeroEffect,
		bDistinctTargetID = MY_Recount.Data.bDistinctTargetID,
		bDistinctEffectID = MY_Recount.Data.bDistinctEffectID,
	}
	local data = MY.SaveLUAData(SZ_REC_FILE, data)
end

-- 过图清除当前战斗数据
do
local function onLoadingEnding()
	MY_Recount.Data.Push()
	MY_Recount.Data.Init(true)
	FireUIEvent('MY_RECOUNT_NEW_FIGHT')
end
MY.RegisterEvent('LOADING_ENDING', onLoadingEnding)
MY.RegisterEvent('RELOAD_UI_ADDON_END', onLoadingEnding)
end

-- 退出战斗 保存数据
MY.RegisterEvent('MY_FIGHT_HINT', function(event)
	if arg0 and MY.GetFightUUID() ~= Data.UUID then -- 进入新的战斗
		MY_Recount.Data.Init()
		FireUIEvent('MY_RECOUNT_NEW_FIGHT')
	else
		MY_Recount.Data.Push()
	end
end)
MY.BreatheCall('MY_Recount_FightTime', 1000, function()
	if MY.IsFighting() then
		Data.nTimeDuring = GetCurrentTime() - Data.nTimeBegin
		for _, szRecordType in ipairs({"Damage", "Heal", "BeDamage", "BeHeal"}) do
			local tInfo = Data[szRecordType]
			local tSnapshot = {
				nTimeDuring  = Data.nTimeDuring,
				nTotal       = tInfo.nTotal,
				nTotalEffect = tInfo.nTotalEffect,
				Statistics   = {},
			}
			for k, v in pairs(tInfo.Statistics) do
				tSnapshot.Statistics[k] = {
					nTotal = v.nTotal,
					nTotalEffect = v.nTotalEffect,
				}
			end
			table.insert(Data[szRecordType].Snapshots, tSnapshot)
		end
	end
end)

-- ################################################################################################## --
--                             #           #             #       #                                    --
--     # # # # # # # # #         #         #             #         #           # # # # # # # # #      --
--         #       #                       #             #   # # # # # # #     #               #      --
--         #       #         # # # # #     # # # #   # # # #   #       #       #               #      --
--         #       #           #         #     #         #       #   #         #               #      --
--         #       #           #       #   #   #         #   # # # # # # #     #               #      --
--   # # # # # # # # # # #     # # # #     #   #         # #       #           #               #      --
--         #       #           #     #     #   #     # # #   # # # # # # #     #               #      --
--         #       #           #     #     #   #         #       #     #       #               #      --
--       #         #           #     #       #           #     # #     #       # # # # # # # # #      --
--       #         #           #     #     #   #         #         # #         #               #      --
--     #           #         #     # #   #       #     # #   # # #     # #                            --
-- ################################################################################################## --
-- 获取统计数据
-- (table) MY_Recount.Data.Get(nIndex) -- 获取指定记录
--     (number)nIndex: 历史记录索引 为0返回当前统计
-- (table) MY_Recount.Data.Get()       -- 获取所有历史记录列表
function MY_Recount.Data.Get(nIndex)
	if not nIndex then
		return History
	elseif nIndex == 0 then
		return Data
	else
		return History[nIndex]
	end
end

-- 删除历史统计数据
-- (table) MY_Recount.Data.Del(nIndex) -- 删除指定序号的记录
--     (number)nIndex: 历史记录索引
-- (table) MY_Recount.Data.Del(data)   -- 删除指定记录
function MY_Recount.Data.Del(data)
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

-- 计算暂离时间
-- MY_Recount.Data.GeneAwayTime(data, dwID, szRecordType)
-- data: 数据
-- dwID: 计算暂离的角色ID 为空则计算团队的暂离时间（目前永远为0）
-- szRecordType: 不同类型的数据在官方时间算法下计算结果可能不一样
--               枚举暂时有 Heal Damage BeDamage BeHeal 四种
function MY_Recount.Data.GeneAwayTime(data, dwID, szRecordType)
	local nFightTime = MY_Recount.Data.GeneFightTime(data, dwID, szRecordType)
	local nAwayTime
	if szRecordType and data[szRecordType] and data[szRecordType].nTimeDuring then
		nAwayTime = data[szRecordType].nTimeDuring - nFightTime
	else
		nAwayTime = data.nTimeDuring - nFightTime
	end
	return math.max(nAwayTime, 0)
end

-- 计算战斗时间
-- MY_Recount.Data.GeneFightTime(data, dwID, szRecordType)
-- data: 数据
-- dwID: 计算战斗时间的角色ID 为空则计算团队的战斗时间
-- szRecordType: 不同类型的数据在官方时间算法下计算结果可能不一样
--               枚举暂时有 Heal Damage BeDamage BeHeal 四种
function MY_Recount.Data.GeneFightTime(data, dwID, szRecordType)
	local nTimeDuring = data.nTimeDuring
	local nTimeBegin  = data.nTimeBegin
	if szRecordType and data[szRecordType] and data[szRecordType].nTimeDuring then
		nTimeDuring = data[szRecordType].nTimeDuring
	end
	if dwID and data.Awaytime and data.Awaytime[dwID] then
		for _, rec in ipairs(data.Awaytime[dwID]) do
			local nAwayBegin = math.max(rec[1], nTimeBegin)
			local nAwayEnd   = rec[2]
			if nAwayEnd then -- 完整的离开记录
				nTimeDuring = nTimeDuring - (nAwayEnd - nAwayBegin)
			else -- 离开了至今没回来的记录
				nTimeDuring = nTimeDuring - (data.nTimeBegin + nTimeDuring - nAwayBegin)
				break
			end
		end
	end
	return math.max(nTimeDuring, 0)
end

-- ################################################################################################## --
--         #       #             #                     #     # # # # # # #       #     # # # # #      --
--     #   #   #   #             #     # # # # # #       #   #   #   #   #       #     #       #      --
--         #       #             #     #         #           #   #   #   #   # # # #   # # # # #      --
--   # # # # # #   # # # #   # # # #   # # # # # #           # # # # # # #     #                      --
--       # #     #     #         #     #     #       # # #       #             # #   # # # # # # #    --
--     #   # #     #   #         #     # # # # # #       #       # # # # #   #   #     #       #      --
--   #     #   #   #   #         # #   #     #           #   # #         #   # # # #   # # # # #      --
--       #         #   #     # # #     # # # # # #       #       #     #         #     #       #      --
--   # # # # #     #   #         #     # #       #       #         # #           # #   # # # # #      --
--     #     #       #           #   #   #       #       #   # # #           # # #     #       # #    --
--       # #       #   #         #   #   # # # # #     #   #                     #   # # # # # #      --
--   # #     #   #       #     # # #     #       #   #       # # # # # # #       #             #      --
-- ################################################################################################## --
-- 记录一次LOG
-- MY_Recount.OnSkillEffect(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nSkillResult, nResultCount, tResult)
-- (number) dwCaster    : 释放者ID
-- (number) dwTarget    : 承受者ID
-- (number) nEffectType : 造成效果的原因（SKILL_EFFECT_TYPE枚举 如SKILL,BUFF）
-- (number) dwID        : 技能ID
-- (number) dwLevel     : 技能等级
-- (number) nSkillResult: 造成的效果结果（SKILL_RESULT枚举 如HIT,MISS）
-- (number) nResultCount      : 造成效果的数值数量（tResult长度）
-- (table ) tResult     : 所有效果数值集合
function MY_Recount.Data.OnSkillEffect(dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult)
	-- 获取释放对象和承受对象
	local hCaster = MY.Game.GetObject(dwCaster)
	if (not IsPlayer(dwCaster)) and hCaster and hCaster.dwEmployer and hCaster.dwEmployer ~= 0 then -- 宠物的数据算在主人统计中
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
		if not MY_Recount.Data.bRecAnonymous then
			return
		end
		szEffectName = "#" .. dwEffectID
	elseif Data.bDistinctEffectID then
		szEffectName = szEffectName .. "#" .. dwEffectID
	end
	local szDamageEffectName, szHealEffectName = szEffectName, szEffectName
	if nEffectType == SKILL_EFFECT_TYPE.BUFF then
		szHealEffectName = szHealEffectName .. "(HOT)"
		szDamageEffectName = szDamageEffectName .. "(DOT)"
	end

	-- 过滤掉无伤害无治疗的命中效果记录
	if MY_Recount.Data.bIgnoreZeroEffect and (
		nSkillResult == SKILL_RESULT.HIT or nSkillResult == SKILL_RESULT.CRITICAL
	) then
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
	if dwCaster ~= me.dwID                 -- 释放者不是自己
	and dwTarget ~= me.dwID                -- 承受者不是自己
	and not MY.IsInArena()                 -- 不在竞技场
	and not MY.IsInBattleField()           -- 不在战场
	and IsPlayer(dwCaster)                 -- 释放者是玩家
	and not me.IsPlayerInMyParty(dwCaster) -- 且释放者不是队友
	and not me.IsPlayerInMyParty(dwTarget) -- 且承受者不是队友
	then -- 则忽视
		return
	end

	-- 未进战则初始化统计数据（即默认当前帧所有的技能日志为进战技能）
	if not MY.GetFightUUID() and
	_Cache.nLastAutoInitFrame ~= GetLogicFrameCount() then
		_Cache.nLastAutoInitFrame = GetLogicFrameCount()
		MY_Recount.Data.Init(true)
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

	-- 识破
	local nValue = tResult[SKILL_RESULT_TYPE.INSIGHT_DAMAGE]
	if nValue and nValue > 0 then
		MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szDamageEffectName, nDamage, nEffectDamage, SKILL_RESULT.INSIGHT)
	elseif nSkillResult == SKILL_RESULT.HIT or
	nSkillResult == SKILL_RESULT.CRITICAL then -- 击中
		if nTherapy > 0 then -- 有治疗
			MY_Recount.Data.AddHealRecord(hCaster, hTarget, szHealEffectName, nTherapy, nEffectTherapy, nSkillResult)
		end
		if nDamage > 0 or nTherapy == 0 then -- 有伤害 或者 无伤害无治疗的效果
			MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szDamageEffectName, nDamage, nEffectDamage, nSkillResult)
		end
	elseif nSkillResult == SKILL_RESULT.BLOCK or  -- 格挡
	nSkillResult == SKILL_RESULT.SHIELD       or  -- 无效
	nSkillResult == SKILL_RESULT.MISS         or  -- 偏离
	nSkillResult == SKILL_RESULT.DODGE      then  -- 闪避
		MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szDamageEffectName, 0, 0, nSkillResult)
	end

	Data.nTimeDuring = GetCurrentTime() - Data.nTimeBegin
end

function MY_Recount.Data.GetNameAusID(id, data)
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

function MY_Recount.Data.IsParty(id, data)
	local dwID = tonumber(id)
	if dwID then
		if dwID == UI_GetClientPlayerID() then
			return true
		else
			return IsParty(dwID, UI_GetClientPlayerID())
		end
	else
		return false
	end
end

-- 将一条记录插入数组
function _Cache.AddRecord(data, szRecordType, idRecord, idTarget, szEffectName, nValue, nEffectValue, nSkillResult)
	local tInfo   = data[szRecordType]
	local tRecord = tInfo.Statistics[idRecord]
	if not szEffectName or szEffectName == "" then
		return
	end
	------------------------
	-- # 节： tInfo
	------------------------
	tInfo.nTimeDuring = GetCurrentTime() - data.nTimeBegin
	tInfo.nTotal        = tInfo.nTotal + nValue
	tInfo.nTotalEffect  = tInfo.nTotalEffect + nEffectValue
	------------------------
	-- # 节： tRecord
	------------------------
	tRecord.nTotal        = tRecord.nTotal + nValue
	tRecord.nTotalEffect  = tRecord.nTotalEffect + nEffectValue
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

-- 获取索引ID
local function GetObjectKeyID(obj)
	if IsPlayer(obj.dwID) then
		return obj.dwID
	end
	local id = MY.GetObjectName(obj) or g_tStrings.STR_NAME_UNKNOWN
	if Data.bDistinctTargetID then
		id = id .. "#" .. obj.dwID
	end
	return id
end

-- 插入一条伤害记录
function MY_Recount.Data.AddDamageRecord(hCaster, hTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
	-- 获取索引ID
	local idCaster = GetObjectKeyID(hCaster)
	local idTarget = GetObjectKeyID(hTarget)

	-- 添加伤害记录
	_Cache.InitObjectData(Data, hCaster, 'Damage')
	_Cache.AddRecord(Data, 'Damage'  , idCaster, idTarget, szEffectName, nDamage, nEffectDamage, nSkillResult)
	-- 添加承伤记录
	_Cache.InitObjectData(Data, hTarget, 'BeDamage')
	_Cache.AddRecord(Data, 'BeDamage', idTarget, idCaster, szEffectName, nDamage, nEffectDamage, nSkillResult)
end

-- 插入一条治疗记录
function MY_Recount.Data.AddHealRecord(hCaster, hTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
	-- 获取索引ID
	local idCaster = GetObjectKeyID(hCaster)
	local idTarget = GetObjectKeyID(hTarget)

	-- 添加伤害记录
	_Cache.InitObjectData(Data, hCaster, 'Heal')
	_Cache.AddRecord(Data, 'Heal'    , idCaster, idTarget, szEffectName, nHeal, nEffectHeal, nSkillResult)
	-- 添加承伤记录
	_Cache.InitObjectData(Data, hTarget, 'BeHeal')
	_Cache.AddRecord(Data, 'BeHeal'  , idTarget, idCaster, szEffectName, nHeal, nEffectHeal, nSkillResult)
end

-- 确认对象数据已创建（未创建则创建）
function _Cache.InitObjectData(data, obj, szChannel)
	local id = GetObjectKeyID(obj)
	if IsPlayer(obj.dwID) and not data.Namelist[id] then
		data.Namelist[id]  = MY.Game.GetObjectName(obj) -- 名称缓存
		data.Forcelist[id] = obj.dwForceID or 0         -- 势力缓存
	end

	if not data[szChannel].Statistics[id] then
		data[szChannel].Statistics[id] = {
			szMD5        = obj.dwID, -- 唯一标识
			nTotal       = 0       , -- 总输出
			nTotalEffect = 0       , -- 有效输出
			Detail       = {}      , -- 输出结果按技能结果分类统计
			Skill        = {}      , -- 该玩家具体造成输出的技能统计
			Target       = {}      , -- 该玩家具体对谁造成输出的统计
		}
	end
end

-- 初始化Data
do
local function GeneTypeNS()
	return {
		nTimeDuring  = 0,
		nTotal       = 0,
		nTotalEffect = 0,
		Snapshots    = {},
		Statistics   = {},
	}
end
function MY_Recount.Data.Init(bForceInit)
	if bForceInit or (not Data) or
	(Data.UUID and MY.GetFightUUID() ~= Data.UUID) then
		Data = {
			UUID              = MY.GetFightUUID(),                 -- 战斗唯一标识
			nVersion          = VERSION,                           -- 数据版本号
			bDistinctTargetID = MY_Recount.Data.bDistinctTargetID, -- 是否根据ID区分同名目标
			bDistinctEffectID = MY_Recount.Data.bDistinctEffectID, -- 是否根据ID区分同名效果
			nTimeBegin        = GetCurrentTime(),                  -- 战斗开始时间
			nTimeDuring       =  0,                                -- 战斗持续时间
			Awaytime          = {},                                -- 死亡/掉线时间节点
			Namelist          = {},                                -- 名称缓存
			Forcelist         = {},                                -- 势力缓存
			Damage            = GeneTypeNS(),                      -- 输出统计
			Heal              = GeneTypeNS(),                      -- 治疗统计
			BeHeal            = GeneTypeNS(),                      -- 承疗统计
			BeDamage          = GeneTypeNS(),                      -- 承伤统计
		}
	end

	if not Data.UUID and MY.GetFightUUID() then
		Data.UUID       = MY.GetFightUUID()
		Data.nTimeBegin = GetCurrentTime()
	end
end
end

-- Data数据压入历史记录 并重新初始化Data
function MY_Recount.Data.Push()
	if not (Data and Data.UUID) then
		return
	end

	-- 过滤空记录
	if empty(Data.BeDamage.Statistics)
	and empty(Data.Damage.Statistics)
	and empty(Data.Heal.Statistics)
	and empty(Data.BeHeal.Statistics) then
		return
	end

	-- 计算受伤最多的名字作为战斗名称
	local nMaxValue, szBossName = 0, nil
	local nEnemyMaxValue, szEnemyBossName = 0, nil
	for id, p in pairs(Data.BeDamage.Statistics) do
		if nEnemyMaxValue < p.nTotalEffect and not MY_Recount.Data.IsParty(id, Data) then
			nEnemyMaxValue  = p.nTotalEffect
			szEnemyBossName = MY_Recount.Data.GetNameAusID(id, Data)
		end
		if nMaxValue < p.nTotalEffect and id ~= UI_GetClientPlayerID() then
			nMaxValue  = p.nTotalEffect
			szBossName = MY_Recount.Data.GetNameAusID(id, Data)
		end
	end
	-- 如果没有 则计算输出最多的NPC名字作为战斗名称
	if not szBossName or not szEnemyBossName then
		for id, p in pairs(Data.Damage.Statistics) do
			if nEnemyMaxValue < p.nTotalEffect and not MY_Recount.Data.IsParty(id, Data) then
				nEnemyMaxValue  = p.nTotalEffect
				szEnemyBossName = MY_Recount.Data.GetNameAusID(id, Data)
			end
			if nMaxValue < p.nTotalEffect and not tonumber(id) then
				nMaxValue  = p.nTotalEffect
				szBossName = MY_Recount.Data.GetNameAusID(id, Data)
			end
		end
	end
	Data.szBossName = szEnemyBossName or szBossName or ''

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
		-- if not MY.IsInArena() then
		-- 技能最终产生的效果（生命值的变化）；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID
		-- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResultCount：数值集合
		-- MY_Recount.Data.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
		if arg7 and arg7 ~= 0 then -- bCriticalStrike
			MY_Recount.Data.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.CRITICAL, arg8, arg9)
		else
			MY_Recount.Data.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.HIT, arg8, arg9)
		end
		-- end
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

-- JJC中使用的数据源（不能记录溢出数据）
-- MY.RegisterEvent("SKILL_EFFECT_TEXT", function(event)
--     if MY.IsInArena() then
--         local dwCasterID      = arg0
--         local dwTargetID      = arg1
--         local bCriticalStrike = arg2
--         local nType           = arg3
--         local nValue          = arg4
--         local dwSkillID       = arg5
--         local dwSkillLevel    = arg6
--         local nEffectType     = arg7
--         local nResultCount    = 1
--         local tResult         = { [nType] = nValue }

--         if nType == SKILL_RESULT_TYPE.PHYSICS_DAMAGE -- 外功伤害
--         or nType == SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE -- 阳性内功伤害
--         or nType == SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE -- 中性内功伤害
--         or nType == SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE -- 阴性内功伤害
--         or nType == SKILL_RESULT_TYPE.POISON_DAMAGE then -- 毒性内功伤害
--         -- if nType == SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE then -- 有效伤害值
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] = nValue
--         elseif nType == SKILL_RESULT_TYPE.REFLECTIED_DAMAGE then -- 反弹伤害
--             dwCasterID, dwTargetID = dwTargetID, dwCasterID
--         elseif nType == SKILL_RESULT_TYPE.THERAPY then -- 治疗
--         -- elseif nType == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY then -- 有效治疗量
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] = nValue
--         elseif nType == SKILL_RESULT_TYPE.STEAL_LIFE then -- 偷取生命值
--             dwTargetID = dwCasterID
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] = nValue
--         elseif nType == SKILL_RESULT_TYPE.ABSORB_DAMAGE then -- 吸收伤害
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] = 0
--         elseif nType == SKILL_RESULT_TYPE.SHIELD_DAMAGE then -- 内力抵消伤害
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] = 0
--         elseif nType == SKILL_RESULT_TYPE.PARRY_DAMAGE then -- 闪避伤害
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] = 0
--         elseif nType == SKILL_RESULT_TYPE.INSIGHT_DAMAGE then -- 识破伤害
--             nResultCount = nResultCount + 1
--             tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] = 0
--         end
--         if bCriticalStrike then -- bCriticalStrike
--             MY_Recount.Data.OnSkillEffect(dwCasterID, dwTargetID, nEffectType, dwSkillID, dwSkillLevel, SKILL_RESULT.CRITICAL, nResultCount, tResult)
--         else
--             MY_Recount.Data.OnSkillEffect(dwCasterID, dwTargetID, nEffectType, dwSkillID, dwSkillLevel, SKILL_RESULT.HIT, nResultCount, tResult)
--         end
--     end
-- end)


-- 有人死了活了做一下时间轴记录
function _Cache.OnTeammateStateChange(dwID, bLeave, nAwayType, bAddWhenRecEmpty)
	if not (Data and Data.Awaytime) then
		return
	end
	-- 获得一个人的记录
	local rec = Data.Awaytime[dwID]
	if not rec then -- 初始化一个记录
		if not bLeave and not bAddWhenRecEmpty then
			return -- 不是一次暂离的开始并且不强制记录则跳过
		end
		rec = {}
		Data.Awaytime[dwID] = rec
	elseif #rec > 0 then -- 检查逻辑
		if bLeave then -- 有人死了
			if not rec[#rec][2] then -- 并且最后一条记录还是死的
				return
			end
		else -- 有人活了
			if rec[#rec][2] then -- 并且本来就是活的
				return
			end
		end
	end
	-- 插入数据到记录
	if bLeave then -- 暂离开始
		table.insert(rec, { GetCurrentTime(), nil, nAwayType })
	else -- 暂离回来
		if #rec == 0 then -- 没记录到暂离开始 创建一个从本次战斗开始的暂离（俗称还没开打你就死了。。）
			table.insert(rec, { Data.nTimeBegin, GetCurrentTime(), nAwayType })
		elseif not rec[#rec][2] then -- 如果最后一次暂离还没回来 则完成最后一次暂离的记录
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
	if arg2 == 0 then -- 有人掉线
		_Cache.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.OFFLINE, false)
	else -- 有人上线
		_Cache.OnTeammateStateChange(arg1, false, AWAYTIME_TYPE.OFFLINE, false)
		local team = GetClientTeam()
		local info = team.GetMemberInfo(arg1)
		if info and info.bDeathFlag then -- 上线死着的 结束离线暂离 开始死亡暂离
			_Cache.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.DEATH, false)
		end
	end
end)
MY.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- 开战扫描队友 记录开战就死掉/掉线的人
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
MY.RegisterEvent('PARTY_ADD_MEMBER', function() -- 中途有人进队 补上暂离记录
	local team = GetClientTeam()
	local info = team.GetMemberInfo(arg1)
	if info then
		_Cache.OnTeammateStateChange(arg1, false, AWAYTIME_TYPE.HALFWAY_JOINED, true)
		if info.bDeathFlag then
			_Cache.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.DEATH, true)
		end
	end
end)
