--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗统计 数据源
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
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan = math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local DEBUG = false

local DK = {
	UUID        = DEBUG and 'UUID'        or  1, -- 战斗唯一标识
	BOSSNAME    = DEBUG and 'szBossName'  or  2, -- 日志名字
	VERSION     = DEBUG and 'nVersion'    or  3, -- 数据版本号
	TIME_BEGIN  = DEBUG and 'nTimeBegin'  or  4, -- 战斗开始时间
	TICK_BEGIN  = DEBUG and 'nTickBegin'  or  5, -- 战斗开始毫秒时间
	TIME_DURING = DEBUG and 'nTimeDuring' or  6, -- 战斗持续时间
	TICK_DURING = DEBUG and 'nTickDuring' or  7, -- 战斗持续毫秒时间
	AWAYTIME    = DEBUG and 'Awaytime'    or  8, -- 死亡/掉线时间节点
	NAME_LIST   = DEBUG and 'Namelist'    or  9, -- 名称缓存
	FORCE_LIST  = DEBUG and 'Forcelist'   or 10, -- 势力缓存
	EFFECT_LIST = DEBUG and 'Effectlist'  or 11, -- 效果信息缓存
	DAMAGE      = DEBUG and 'Damage'      or 12, -- 输出统计
	HEAL        = DEBUG and 'Heal'        or 13, -- 治疗统计
	BE_HEAL     = DEBUG and 'BeHeal'      or 14, -- 承疗统计
	BE_DAMAGE   = DEBUG and 'BeDamage'    or 15, -- 承伤统计
	EVERYTHING  = DEBUG and 'Everything'  or 16, -- 战斗复盘
}

local DK_REC = {
	TIME_DURING  = DEBUG and 'nTimeDuring'  or 1,
	TOTAL        = DEBUG and 'nTotal'       or 2,
	TOTAL_EFFECT = DEBUG and 'nTotalEffect' or 3,
	STAT         = DEBUG and 'Statistics'   or 4,
}

local DK_REC_SNAPSHOT = {
	TIME_DURING  = DEBUG and 'nTimeDuring'  or 1,
	TOTAL        = DEBUG and 'nTotal'       or 2,
	TOTAL_EFFECT = DEBUG and 'nTotalEffect' or 3,
	STATISTICS   = DEBUG and 'Statistics'   or 4,
}

local DK_REC_SNAPSHOT_STAT = {
	TOTAL        = DEBUG and 'nTotal'       or 1,
	TOTAL_EFFECT = DEBUG and 'nTotalEffect' or 2,
}

local DK_REC_STAT = {
	TOTAL        = DEBUG and 'nTotal'       or 1,
	TOTAL_EFFECT = DEBUG and 'nTotalEffect' or 2,
	DETAIL       = DEBUG and 'Detail'       or 3,
	SKILL        = DEBUG and 'Skill'        or 4,
	TARGET       = DEBUG and 'Target'       or 5,
}

local DK_REC_STAT_DETAIL = {
	COUNT         = DEBUG and 'nCount'       or  1, -- 命中记录数量（假设nSkillResult是命中）
	NZ_COUNT      = DEBUG and 'nNzCount'     or  2, -- 非零值命中记录数量
	MAX           = DEBUG and 'nMax'         or  3, -- 单次命中最大值
	MAX_EFFECT    = DEBUG and 'nMaxEffect'   or  4, -- 单次命中最大有效值
	MIN           = DEBUG and 'nMin'         or  5, -- 单次命中最小值
	NZ_MIN        = DEBUG and 'nNzMin'       or  6, -- 单次非零值命中最小值
	MIN_EFFECT    = DEBUG and 'nMinEffect'   or  7, -- 单次命中最小有效值
	NZ_MIN_EFFECT = DEBUG and 'nNzMinEffect' or  8, -- 单次非零值命中最小有效值
	TOTAL         = DEBUG and 'nTotal'       or  9, -- 所有命中总伤害
	TOTAL_EFFECT  = DEBUG and 'nTotalEffect' or 10, -- 所有命中总有效伤害
	AVG           = DEBUG and 'nAvg'         or 11, -- 所有命中平均伤害
	NZ_AVG        = DEBUG and 'nNzAvg'       or 12, -- 所有非零值命中平均伤害
	AVG_EFFECT    = DEBUG and 'nAvgEffect'   or 13, -- 所有命中平均有效伤害
	NZ_AVG_EFFECT = DEBUG and 'nNzAvgEffect' or 14, -- 所有非零值命中平均有效伤害
}

local DK_REC_STAT_SKILL = {
	COUNT         = DEBUG and 'nCount'       or  1, -- 该玩家四象轮回释放次数（假设szEffectName是四象轮回）
	NZ_COUNT      = DEBUG and 'nNzCount'     or  2, -- 该玩家非零值四象轮回释放次数
	MAX           = DEBUG and 'nMax'         or  3, -- 该玩家四象轮回最大输出量
	MAX_EFFECT    = DEBUG and 'nMaxEffect'   or  4, -- 该玩家四象轮回最大有效输出量
	TOTAL         = DEBUG and 'nTotal'       or  5, -- 该玩家四象轮回输出量总和
	TOTAL_EFFECT  = DEBUG and 'nTotalEffect' or  6, -- 该玩家四象轮回有效输出量总和
	AVG           = DEBUG and 'nAvg'         or  7, -- 该玩家所有四象轮回平均伤害
	NZ_AVG        = DEBUG and 'nNzAvg'       or  8, -- 该玩家所有非零值四象轮回平均伤害
	AVG_EFFECT    = DEBUG and 'nAvgEffect'   or  9, -- 该玩家所有四象轮回平均有效伤害
	NZ_AVG_EFFECT = DEBUG and 'nNzAvgEffect' or 10, -- 该玩家所有非零值四象轮回平均有效伤害
	DETAIL        = DEBUG and 'Detail'       or 11, -- 该玩家四象轮回输出结果分类统计
	TARGET        = DEBUG and 'Target'       or 12, -- 该玩家四象轮回承受者统计
}

local DK_REC_STAT_SKILL_DETAIL = {
	COUNT         = DEBUG and 'nCount'       or  1, -- 命中记录数量
	NZ_COUNT      = DEBUG and 'nNzCount'     or  2, -- 非零值命中记录数量
	MAX           = DEBUG and 'nMax'         or  3, -- 单次命中最大值
	MAX_EFFECT    = DEBUG and 'nMaxEffect'   or  4, -- 单次命中最大有效值
	MIN           = DEBUG and 'nMin'         or  5, -- 单次命中最小值
	NZ_MIN        = DEBUG and 'nNzMin'       or  6, -- 单次非零值命中最小值
	MIN_EFFECT    = DEBUG and 'nMinEffect'   or  7, -- 单次命中最小有效值
	NZ_MIN_EFFECT = DEBUG and 'nNzMinEffect' or  8, -- 单次非零值命中最小有效值
	TOTAL         = DEBUG and 'nTotal'       or  9, -- 所以命中总伤害
	TOTAL_EFFECT  = DEBUG and 'nTotalEffect' or 10, -- 所有命中总有效伤害
	AVG           = DEBUG and 'nAvg'         or 11, -- 所有命中平均伤害
	NZ_AVG        = DEBUG and 'nNzAvg'       or 12, -- 所有非零值命中平均伤害
	AVG_EFFECT    = DEBUG and 'nAvgEffect'   or 13, -- 所有命中平均有效伤害
	NZ_AVG_EFFECT = DEBUG and 'nNzAvgEffect' or 14, -- 所有非零值命中平均有效伤害
}

local DK_REC_STAT_SKILL_TARGET = {
	MAX          = DEBUG and 'nMax'         or 1, -- 该玩家四象轮回击中的这个玩家最大伤害
	MAX_EFFECT   = DEBUG and 'nMaxEffect'   or 2, -- 该玩家四象轮回击中的这个玩家最大有效伤害
	TOTAL        = DEBUG and 'nTotal'       or 3, -- 该玩家四象轮回击中的这个玩家伤害总和
	TOTAL_EFFECT = DEBUG and 'nTotalEffect' or 4, -- 该玩家四象轮回击中的这个玩家有效伤害总和
	COUNT        = DEBUG and 'Count'        or 5, -- 该玩家四象轮回击中的这个玩家结果统计
	NZ_COUNT     = DEBUG and 'NzCount'      or 6, -- 该玩家非零值四象轮回击中的这个玩家结果统计
}

local DK_REC_STAT_TARGET = {
	COUNT         = DEBUG and 'nCount'       or  1, -- 该玩家对idTarget的技能释放次数
	NZ_COUNT      = DEBUG and 'nNzCount'     or  2, -- 该玩家对idTarget的非零值技能释放次数
	MAX           = DEBUG and 'nMax'         or  3, -- 该玩家对idTarget的技能最大输出量
	MAX_EFFECT    = DEBUG and 'nMaxEffect'   or  4, -- 该玩家对idTarget的技能最大有效输出量
	TOTAL         = DEBUG and 'nTotal'       or  5, -- 该玩家对idTarget的技能输出量总和
	TOTAL_EFFECT  = DEBUG and 'nTotalEffect' or  6, -- 该玩家对idTarget的技能有效输出量总和
	AVG           = DEBUG and 'nAvg'         or  7, -- 该玩家对idTarget的技能平均输出量
	NZ_AVG        = DEBUG and 'nNzAvg'       or  8, -- 该玩家对idTarget的非零值技能平均输出量
	AVG_EFFECT    = DEBUG and 'nAvgEffect'   or  9, -- 该玩家对idTarget的技能平均有效输出量
	NZ_AVG_EFFECT = DEBUG and 'nNzAvgEffect' or 10, -- 该玩家对idTarget的非零值技能平均有效输出量
	DETAIL        = DEBUG and 'Detail'       or 11, -- 该玩家对idTarget的技能输出结果分类统计
	SKILL         = DEBUG and 'Skill'        or 12, -- 该玩家对idTarget的技能具体分别统计
}

local DK_REC_STAT_TARGET_DETAIL = {
	COUNT         = DEBUG and 'nCount'       or  1, -- 命中记录数量（假设nSkillResult是命中）
	NZ_COUNT      = DEBUG and 'nNzCount'     or  2, -- 非零值命中记录数量
	MAX           = DEBUG and 'nMax'         or  3, -- 单次命中最大值
	MAX_EFFECT    = DEBUG and 'nMaxEffect'   or  4, -- 单次命中最大有效值
	MIN           = DEBUG and 'nMin'         or  5, -- 单次命中最小值
	NZ_MIN        = DEBUG and 'nNzMin'       or  6, -- 单次非零值命中最小值
	MIN_EFFECT    = DEBUG and 'nMinEffect'   or  7, -- 单次命中最小有效值
	NZ_MIN_EFFECT = DEBUG and 'nNzMinEffect' or  8, -- 单次非零值命中最小有效值
	TOTAL         = DEBUG and 'nTotal'       or  9, -- 所以命中总伤害
	TOTAL_EFFECT  = DEBUG and 'nTotalEffect' or 10, -- 所有命中总有效伤害
	AVG           = DEBUG and 'nAvg'         or 11, -- 所有命中平均伤害
	NZ_AVG        = DEBUG and 'nNzAvg'       or 12, -- 所有非零值命中平均伤害
	AVG_EFFECT    = DEBUG and 'nAvgEffect'   or 13, -- 所有命中平均有效伤害
	NZ_AVG_EFFECT = DEBUG and 'nNzAvgEffect' or 14, -- 所有非零值命中平均有效伤害
}

local DK_REC_STAT_TARGET_SKILL = {
	MAX          = DEBUG and 'nMax'         or  1, -- 该玩家击中这个玩家的四象轮回最大伤害
	MAX_EFFECT   = DEBUG and 'nMaxEffect'   or  2, -- 该玩家击中这个玩家的四象轮回最大有效伤害
	TOTAL        = DEBUG and 'nTotal'       or  3, -- 该玩家击中这个玩家的四象轮回伤害总和
	TOTAL_EFFECT = DEBUG and 'nTotalEffect' or  4, -- 该玩家击中这个玩家的四象轮回有效伤害总和
	COUNT        = DEBUG and 'Count'        or  5, -- 该玩家击中这个玩家的四象轮回结果统计
	NZ_COUNT     = DEBUG and 'NzCount'      or  6, -- 该玩家非零值击中这个玩家的四象轮回结果统计
}
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

-- Data、DataDisplay、HISTORY_CACHE[szFilePath].Data 数据结构
Data = {
	[DK.UUID] = 战斗统一标示符,
	[DK.VERSION] = 数据版本号,
	[DK.TIME_BEGIN] = 战斗开始UNIX时间戳,
	[DK.TIME_DURING] = 战斗持续秒数,
	[DK.AWAYTIME] = {
		玩家的dwID = {
			{ 暂离开始时间, 暂离结束时间 }, ...
		}, ...
	},
	[DK.DAMAGE] = {                                                -- 输出统计
		[DK_REC.TIME_DURING] = 最后一次记录时离开始的秒数,
		[DK_REC.TOTAL] = 全队的输出量,
		[DK_REC.TOTAL_EFFECT] = 全队的有效输出量,
		[DK_REC.STAT] = {
			玩家的dwID = {                                        -- 该对象的输出统计
				[DK_REC_STAT.TOTAL       ] = 2314214,       -- 总输出
				[DK_REC_STAT.TOTAL_EFFECT] = 132144 ,       -- 有效输出
				[DK_REC_STAT.DETAIL      ] = {              -- 输出结果分类统计
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
				[DK_REC_STAT.SKILL] = {                     -- 该玩家具体造成输出的技能统计
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
							四象轮回 = {                          -- 该玩家四象轮回击中的这个玩家数据统计
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
							两仪化形 = { ... },
							...
						},
					},
				},
			},
			NPC的名字 = { ... },
		},
	},
	[DK.HEAL] = { ... },
	[DK.BE_HEAL] = { ... },
	[DK.BE_DAMAGE] = { ... },
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
local NZ_SKILL_RESULT = {
	[SKILL_RESULT.BLOCK ] = true,
	[SKILL_RESULT.SHIELD] = true,
	[SKILL_RESULT.MISS  ] = true,
	[SKILL_RESULT.DODGE ] = true,
}
local AWAYTIME_TYPE = {
	DEATH          = 0,
	OFFLINE        = 1,
	HALFWAY_JOINED = 2,
}
local EVERYTHING_TYPE = {
	SKILL_EFFECT = 1,
	FIGHT_TIME = 2,
	DEATH = 3,
	ONLINE = 4,
	BUFF_UPDATE = 5,
}
local VERSION = 2

local D = {}
local O = {
	bEnable            = false, -- 数据记录总开关 防止官方SB技能BUFF脚本瞎几把写超高频太卡甩锅给界面逻辑
	bSaveHistoryOnExit = false, -- 退出游戏时保存历史数据
	bSaveHistoryOnExFi = false, -- 脱离战斗时保存历史数据
	nMaxHistory        = 10   , -- 最大历史数据数量
	nMinFightTime      = 30   , -- 最小战斗时间
	bRecEverything     = true , -- 是否采集复盘数据
	bSaveEverything    = false, -- 保存战斗记录时是否存储复盘数据
}
local Data          -- 当前战斗数据记录
local HISTORY_CACHE = setmetatable({}, { __mode = 'v' }) -- 历史战斗记录缓存 { [szFile] = Data }
local KEPT_CACHE = {} -- 保存了但是剔除了复盘记录的战斗记录缓存 { [szFile] = Data }
local UNSAVED_CACHE = {} -- 未保存的战斗记录缓存 { [szFile] = Data }
local DS_DATA_CONFIG = { passphrase = false, crc = false }
local DS_ROOT = {'userdata/fight_stat/', PATH_TYPE.ROLE}
local SZ_CFG_FILE = {'userdata/fight_stat/config.jx3dat', PATH_TYPE.ROLE}
local SKILL_EFFECT_CACHE = {} -- 最近的技能效果缓存 （进战时候将最近的数据压进来）
local BUFF_UPDATE_CACHE = {} -- 最近的BUFF效果缓存 （进战时候将最近的数据压进来）
local LOG_REPLAY_FRAME = GLOBAL.GAME_FPS * 1 -- 进战时候将多久的数据压进来（逻辑帧）

-- 输出两个数里面小一点的那个 其中-1表示极大值
local function Min(a, b)
	if a == -1 then
		return b
	end
	if b == -1 then
		return a
	end
	return min(a, b)
end

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
-- 登录游戏加载保存的数据
function D.LoadData()
	local data = LIB.LoadLUAData(SZ_CFG_FILE, DS_DATA_CONFIG)
	if data then
		if IsTable(data.History) then
			for _, data in ipairs(data.History) do
				UNSAVED_CACHE[LIB.FormatPath(DS_ROOT) .. D.GetDataFileName(data)] = data
			end
			D.SaveHistory()
		end
		O.bEnable            = data.bEnable or false
		O.bSaveHistoryOnExit = data.bSaveHistoryOnExit or data.bSaveHistory or false
		O.bSaveHistoryOnExFi = data.bSaveHistoryOnExFi or false
		O.nMaxHistory        = data.nMaxHistory or 10
		O.nMinFightTime      = data.nMinFightTime or 30
		O.bRecEverything     = data.bRecEverything or false
		O.bSaveEverything    = data.bSaveEverything or false
		MY_Recount_UI.CheckOpen()
	end
	D.InitData()
end

-- 退出游戏保存数据
function D.SaveData()
	local data = {
		bEnable            = O.bEnable           ,
		bSaveHistoryOnExit = O.bSaveHistoryOnExit,
		bSaveHistoryOnExFi = O.bSaveHistoryOnExFi,
		nMaxHistory        = O.nMaxHistory       ,
		nMinFightTime      = O.nMinFightTime     ,
		bRecEverything     = O.bRecEverything    ,
		bSaveEverything    = O.bSaveEverything   ,
	}
	LIB.SaveLUAData(SZ_CFG_FILE, data, DS_DATA_CONFIG)
end

-- 加载历史数据列表
function D.GetHistoryFiles()
	local aFiles = {}
	local aFileName, tFileName = {}, {}
	local szRoot = LIB.FormatPath(DS_ROOT)
	for k, _ in pairs(HISTORY_CACHE) do
		if wfind(k, szRoot) == 1 then
			k = k:sub(#szRoot + 1)
			if not tFileName[k] then
				insert(aFileName, k)
				tFileName[k] = true
			end
		end
	end
	for _, v in ipairs(CPath.GetFileList(szRoot)) do
		if not tFileName[v] then
			insert(aFileName, v)
			tFileName[v] = true
		end
	end
	for _, filename in ipairs(aFileName) do
		local year, month, day, hour, minute, second, bossname, during = filename:match('^(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%_(.-)_(%d+)%.fstt%.jx3dat')
		if year then
			year = tonumber(year)
			month = tonumber(month)
			day = tonumber(day)
			hour = tonumber(hour)
			minute = tonumber(minute)
			second = tonumber(second)
			during = tonumber(during)
			insert(aFiles, {
				year, month, day, hour, minute, second,
				bossname = bossname,
				during = during,
				time = DateToTime(
					year,
					month,
					day,
					hour,
					minute,
					second
				),
				filename = filename:sub(1, -13),
				fullname = filename,
				fullpath = szRoot .. filename,
			})
		end
	end
	local function sortFile(a, b)
		local n = max(#a, #b)
		for i = 1, n do
			if not a[i] then
				return true
			elseif not b[i] then
				return false
			elseif a[i] ~= b[i] then
				return a[i] > b[i]
			end
		end
		return false
	end
	sort(aFiles, sortFile)
	return aFiles
end

-- 限制历史数据数量
function D.LimitHistoryFile()
	local aFiles = D.GetHistoryFiles()
	for i = O.nMaxHistory + 1, #aFiles do
		CPath.DelFile(aFiles[i].fullpath)
		HISTORY_CACHE[aFiles[i].fullpath] = nil
		UNSAVED_CACHE[aFiles[i].fullpath] = nil
		KEPT_CACHE[aFiles[i].fullpath] = nil
	end
end

-- 根据一个数据生成文件名
function D.GetDataFileName(data)
	return LIB.FormatTime(data[DK.TIME_BEGIN], '%yyyy-%MM-%dd-%hh-%mm-%ss')
			.. '_' .. (data[DK.BOSSNAME] or g_tStrings.STR_NAME_UNKNOWN)
			.. '_' .. data[DK.TIME_DURING]
			.. '.fstt.jx3dat'
end

-- 保存缓存的历史数据
function D.SaveHistory()
	for szFilePath, data in pairs(UNSAVED_CACHE) do
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Recount_DS.SaveHistory: ' .. szFilePath, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local saveData = data
		if not O.bSaveEverything then -- 保存数据时剔除复盘数据（防止卡）
			--[[#DEBUG BEGIN]]
			LIB.Debug('MY_Recount_DS.SaveHistoryWithoutEverything: ' .. szFilePath, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			saveData = {}
			for k, v in pairs(data) do
				saveData[k] = k == DK.EVERYTHING
					and {}
					or v
			end
			KEPT_CACHE[szFilePath] = data -- 加入复盘数据保护数组防止被GC
		end
		LIB.SaveLUAData(szFilePath, saveData, DS_DATA_CONFIG)
	end
	D.LimitHistoryFile()
	UNSAVED_CACHE = {}
end

-- 过图清除当前战斗数据
do
local function onLoadingEnding()
	D.Flush()
	FireUIEvent('MY_RECOUNT_NEW_FIGHT')
end
LIB.RegisterEvent('LOADING_ENDING', onLoadingEnding)
LIB.RegisterEvent('RELOAD_UI_ADDON_END', onLoadingEnding)
end

-- 退出战斗 保存数据
LIB.RegisterEvent('MY_FIGHT_HINT', function()
	if not O.bEnable then
		return
	end
	local nLFC, nTime, nTick = GetLogicFrameCount(), GetCurrentTime(), GetTime()
	local bFighting, szUUID, nDuring = arg0, arg1, arg2
	if not bFighting then
		D.InsertEverything(Data, nLFC, nTime, nTick, EVERYTHING_TYPE.FIGHT_TIME, bFighting, szUUID, nDuring)
	end
	if bFighting and szUUID ~= Data[DK.UUID] then -- 进入新的战斗
		D.InitData()
		D.ReplayRecentLog()
		FireUIEvent('MY_RECOUNT_NEW_FIGHT')
	else
		D.Flush()
	end
	if bFighting then
		D.InsertEverything(Data, nLFC, nTime, nTick, EVERYTHING_TYPE.FIGHT_TIME, bFighting, szUUID, nDuring)
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
-- (table) D.Get(szFilePath) -- 获取指定记录
--     (string) szFilePath: 历史记录文件全路径 传'CURRENT'返回当前统计
function D.Get(szFilePath)
	if szFilePath == 'CURRENT' then
		return Data
	end
	if not HISTORY_CACHE[szFilePath] then
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Recount_DS.CacheMiss: ' .. szFilePath, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		HISTORY_CACHE[szFilePath] = LIB.LoadLUAData(szFilePath, DS_DATA_CONFIG)
	end
	return HISTORY_CACHE[szFilePath]
end

-- 删除历史统计数据
-- (void) D.Del(szFilePath) -- 删除指定文件的记录
--     (string)szFilePath: 历史记录文件全路径
-- (void) D.Del(data)       -- 删除指定记录
function D.Del(data)
	if IsString(data) then
		CPath.DelFile(data)
		HISTORY_CACHE[data] = nil
		UNSAVED_CACHE[data] = nil
		KEPT_CACHE[data] = nil
	else
		for szFilePath, v in pairs(HISTORY_CACHE) do
			if v.data == data then
				HISTORY_CACHE[szFilePath] = nil
				CPath.DelFile(szFilePath)
			end
		end
		for szFilePath, v in pairs(UNSAVED_CACHE) do
			if v.data == data then
				UNSAVED_CACHE[szFilePath] = nil
			end
		end
		for szFilePath, v in pairs(KEPT_CACHE) do
			if v.data == data then
				KEPT_CACHE[szFilePath] = nil
			end
		end
	end
end

-- 计算暂离时间
-- D.GeneAwayTime(data, dwID, szRecordType)
-- data: 数据
-- dwID: 计算暂离的角色ID 为空则计算团队的暂离时间（目前永远为0）
-- szRecordType: 不同类型的数据在官方时间算法下计算结果可能不一样
--               枚举暂时有 DK.HEAL DK.DAMAGE DK.BE_DAMAGE DK.BE_HEAL 四种
function D.GeneAwayTime(data, dwID, szRecordType)
	local nFightTime = D.GeneFightTime(data, dwID, szRecordType)
	local nAwayTime
	if szRecordType and data[szRecordType] and data[szRecordType][DK_REC.TIME_DURING] then
		nAwayTime = data[szRecordType][DK_REC.TIME_DURING] - nFightTime
	else
		nAwayTime = data[DK.TIME_DURING] - nFightTime
	end
	return max(nAwayTime, 0)
end

-- 计算战斗时间
-- D.GeneFightTime(data, dwID, szRecordType)
-- data: 数据
-- szRecordType: 不同类型的数据在官方时间算法下计算结果可能不一样
--               枚举暂时有 DK.HEAL DK.DAMAGE DK.BE_DAMAGE DK.BE_HEAL 四种
--               为空则计算普通时间算法
-- dwID: 计算战斗时间的角色ID 为空则计算团队的战斗时间
function D.GeneFightTime(data, szRecordType, dwID)
	local nTimeDuring = data[DK.TIME_DURING]
	local nTimeBegin  = data[DK.TIME_BEGIN]
	if nTimeDuring < 0 then
		nTimeDuring = floor(LIB.GetFightTime() / 1000) + nTimeDuring + 1
	end
	if szRecordType and data[szRecordType] and data[szRecordType][DK_REC.TIME_DURING] then
		nTimeDuring = data[szRecordType][DK_REC.TIME_DURING]
	end
	if dwID and data[DK.AWAYTIME] and data[DK.AWAYTIME][dwID] then
		for _, rec in ipairs(data[DK.AWAYTIME][dwID]) do
			local nAwayBegin = max(rec[1], nTimeBegin)
			local nAwayEnd   = rec[2]
			if nAwayEnd then -- 完整的离开记录
				nTimeDuring = nTimeDuring - (nAwayEnd - nAwayBegin)
			else -- 离开了至今没回来的记录
				nTimeDuring = nTimeDuring - (data[DK.TIME_BEGIN] + nTimeDuring - nAwayBegin)
				break
			end
		end
	end
	return max(nTimeDuring, 0)
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
-- D.ProcessSkillEffect(dwCaster, dwTarget, nEffectType, dwID, dwLevel, nSkillResult, nResultCount, tResult)
-- (number) dwCaster    : 释放者ID
-- (number) dwTarget    : 承受者ID
-- (number) nEffectType : 造成效果的原因（SKILL_EFFECT_TYPE枚举 如SKILL,BUFF）
-- (number) dwID        : 技能ID
-- (number) dwLevel     : 技能等级
-- (number) nSkillResult: 造成的效果结果（SKILL_RESULT枚举 如HIT,MISS）
-- (number) nResultCount: 造成效果的数值数量（tResult长度）
-- (table ) tResult     : 所有效果数值集合
function D.ProcessSkillEffect(nLFC, nTime, nTick, dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult)
	-- 获取释放对象和承受对象
	local KCaster = LIB.GetObject(dwCaster)
	if KCaster and not IsPlayer(dwCaster) and KCaster.dwEmployer and KCaster.dwEmployer ~= 0 then -- 宠物的数据算在主人统计中
		KCaster = LIB.GetObject(KCaster.dwEmployer)
	end
	local KTarget, dwTargetEmployer = LIB.GetObject(dwTarget), nil
	if KTarget and not IsPlayer(dwTarget) and KTarget.dwEmployer and KTarget.dwEmployer ~= 0 then
		dwTargetEmployer = KTarget.dwEmployer
	end
	if not (KCaster and KTarget) then
		return
	end
	dwCaster = KCaster.dwID
	dwTarget = KTarget.dwID

	-- 过滤掉不是队友的以及不是首领的
	local me = GetClientPlayer()
	if dwCaster ~= me.dwID                 -- 释放者不是自己
	and dwTarget ~= me.dwID                -- 承受者不是自己
	and dwTargetEmployer ~= me.dwID        -- 承受者主人不是自己
	and not LIB.IsInArena()                 -- 不在竞技场
	and not LIB.IsInBattleField()           -- 不在战场
	and not me.IsPlayerInMyParty(dwCaster) -- 且释放者不是队友
	and not me.IsPlayerInMyParty(dwTarget) -- 且承受者不是队友
	and not (dwTargetEmployer and me.IsPlayerInMyParty(dwTargetEmployer)) -- 且承受者主人不是队友
	then -- 则忽视
		return
	end

	-- 未进战则初始化统计数据（即默认当前帧所有的技能日志为进战技能）
	if not LIB.GetFightUUID() and D.nLastAutoInitFrame ~= GetLogicFrameCount() then
		D.nLastAutoInitFrame = GetLogicFrameCount()
		D.InitData()
	end

	-- 获取效果名称
	local szEffectID = D.InitEffectData(Data, nEffectType, dwEffectID, dwEffectLevel)
	local nTherapy = tResult[SKILL_RESULT_TYPE.THERAPY] or 0
	local nEffectTherapy = tResult[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] or 0
	local nDamage = (tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE      ] or 0) + -- 外功伤害
					(tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE  ] or 0) + -- 阳性内功伤害
					(tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] or 0) + -- 混元性内功伤害
					(tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE  ] or 0) + -- 阴性内功伤害
					(tResult[SKILL_RESULT_TYPE.POISON_DAMAGE       ] or 0) + -- 毒性伤害
					(tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE   ] or 0)   -- 反弹伤害
	local nEffectDamage = tResult[SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE] or 0

	D.InsertEverything(Data,
		nLFC, nTime, nTick,
		EVERYTHING_TYPE.SKILL_EFFECT, dwCaster, dwTarget,
		nEffectType, dwEffectID, dwEffectLevel, szEffectID,
		nSkillResult, nTherapy, nEffectTherapy, nDamage, nEffectDamage,
		tResult)

	-- 识破
	local nValue = tResult[SKILL_RESULT_TYPE.INSIGHT_DAMAGE]
	if nValue and nValue > 0 then
		D.AddDamageRecord(Data, dwCaster, dwTarget, szEffectID, nDamage, nEffectDamage, SKILL_RESULT.INSIGHT)
	elseif nSkillResult == SKILL_RESULT.HIT -- 击中
		or nSkillResult == SKILL_RESULT.CRITICAL -- 会心
	then
		if nTherapy > 0 then -- 有治疗
			D.AddHealRecord(Data, dwCaster, dwTarget, szEffectID, nTherapy, nEffectTherapy, nSkillResult)
		end
		if nDamage > 0 or nTherapy == 0 then -- 有伤害 或者 无伤害无治疗的效果
			D.AddDamageRecord(Data, dwCaster, dwTarget, szEffectID, nDamage, nEffectDamage, nSkillResult)
		end
	elseif nSkillResult == SKILL_RESULT.BLOCK  -- 格挡
		or nSkillResult == SKILL_RESULT.SHIELD -- 无效
		or nSkillResult == SKILL_RESULT.MISS   -- 偏离
		or nSkillResult == SKILL_RESULT.DODGE  -- 闪避
	then
		D.AddDamageRecord(Data, dwCaster, dwTarget, szEffectID, 0, 0, nSkillResult)
	end
end

function D.OnSkillEffect(dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult)
	local nLFC, nTime, nTick = GetLogicFrameCount(), GetCurrentTime(), GetTime()
	while SKILL_EFFECT_CACHE[1] and nLFC - SKILL_EFFECT_CACHE[1][1] > LOG_REPLAY_FRAME do
		remove(SKILL_EFFECT_CACHE, 1)
	end
	insert(SKILL_EFFECT_CACHE, {nLFC, nTime, nTick, dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult})
	D.ProcessSkillEffect(nLFC, nTime, nTick, dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult)
end

function D.ProcessBuffUpdate(nLFC, nTime, nTick, dwCaster, dwTarget, dwBuffID, dwBuffLevel, nStackNum, bDelete, nEndFrame, bCanCancel)
	local KCaster = LIB.GetObject(dwCaster)
	if KCaster and not IsPlayer(dwCaster) and KCaster.dwEmployer and KCaster.dwEmployer ~= 0 then -- 宠物的数据算在主人统计中
		dwCaster = KCaster.dwEmployer
	end
	local szEffectID = D.InitEffectData(Data, SKILL_EFFECT_TYPE.BUFF, dwBuffID, dwBuffLevel)
	D.InitObjectData(Data, dwCaster)
	D.InitObjectData(Data, dwTarget)
	D.InsertEverything(
		Data,
		nLFC, nTime, nTick,
		EVERYTHING_TYPE.BUFF_UPDATE,
		dwCaster, dwTarget, dwBuffID, dwBuffLevel, szEffectID, bDelete, nStackNum, nEndFrame, bCanCancel)
end

function D.OnBuffUpdate(dwCaster, dwTarget, dwBuffID, dwBuffLevel, nStackNum, bDelete, nEndFrame, bCanCancel)
	if dwBuffID == 0 then
		return
	end
	local nLFC, nTime, nTick = GetLogicFrameCount(), GetCurrentTime(), GetTime()
	while BUFF_UPDATE_CACHE[1] and nLFC - BUFF_UPDATE_CACHE[1][1] > LOG_REPLAY_FRAME do
		remove(BUFF_UPDATE_CACHE, 1)
	end
	insert(BUFF_UPDATE_CACHE, {nLFC, nTime, nTick, dwCaster, dwTarget, dwBuffID, dwBuffLevel, nStackNum, bDelete, nEndFrame, bCanCancel})
	D.ProcessBuffUpdate(nLFC, nTime, nTick, dwCaster, dwTarget, dwBuffID, dwBuffLevel, nStackNum, bDelete, nEndFrame, bCanCancel)
end

function D.ReplayRecentLog()
	local nCurLFC = GetLogicFrameCount()
	for _, v in ipairs(SKILL_EFFECT_CACHE) do
		local nLFC, nTime, nTick, dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult = unpack(v)
		if nCurLFC - nLFC <= LOG_REPLAY_FRAME then
			D.ProcessSkillEffect(nLFC, nTime, nTick, dwCaster, dwTarget, nEffectType, dwEffectID, dwEffectLevel, nSkillResult, nResultCount, tResult)
		end
	end
	for _, v in ipairs(BUFF_UPDATE_CACHE) do
		local nLFC, nTime, nTick, dwCaster, dwTarget, dwBuffID, dwBuffLevel, nStackNum, bDelete, nEndFrame, bCanCancel = unpack(v)
		if nCurLFC - nLFC <= LOG_REPLAY_FRAME then
			D.ProcessBuffUpdate(nLFC, nTime, nTick, dwCaster, dwTarget, dwBuffID, dwBuffLevel, nStackNum, bDelete, nEndFrame, bCanCancel)
		end
	end
end

-- 通过ID计算名字
function D.GetNameAusID(data, dwID)
	if not data or not dwID then
		return
	end
	return data[DK.NAME_LIST][dwID] or g_tStrings.STR_NAME_UNKNOWN
end

-- 通过ID计算势力
function D.GetForceAusID(data, dwID)
	if not data or not dwID then
		return
	end
	return data[DK.FORCE_LIST][dwID] or -1
end

-- 通过ID计算效果信息
function D.GetEffectInfoAusID(data, szEffectID)
	if not data or not szEffectID then
		return
	end
	return unpack(data[DK.EFFECT_LIST][szEffectID] or CONSTANT.EMPTY_TABLE)
end

-- 通过ID用途计算效果名
function D.GetEffectNameAusID(data, szChannel, szEffectID)
	if not data or not szChannel or not szEffectID then
		return
	end
	local info = data[DK.EFFECT_LIST][szEffectID]
	if info and not IsEmpty(info[1]) then
		if info[3] == SKILL_EFFECT_TYPE.BUFF then
			if szChannel == DK.HEAL or szChannel == DK.BE_HEAL then
				return info[1] .. '(HOT)'
			end
			return info[1] .. '(DOT)'
		end
		return info[1]
	end
end

-- 判断是否是友军
function D.IsParty(id)
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

-- 插入复盘数据
function D.InsertEverything(data, nLFC, nTime, nTick, szName, ...)
	if not O.bRecEverything then
		return
	end
	insert(data[DK.EVERYTHING], {nLFC, nTime, nTick, szName, ...})
end

-- 将一条记录插入数组
function D.InsertRecord(data, szRecordType, idRecord, idTarget, szEffectName, nValue, nEffectValue, nSkillResult)
	local tInfo   = data[szRecordType]
	local tRecord = tInfo[DK_REC.STAT][idRecord]
	if not szEffectName or szEffectName == '' then
		return
	end
	------------------------
	-- # 节： tInfo
	------------------------
	tInfo[DK_REC.TIME_DURING ] = GetCurrentTime() - data[DK.TIME_BEGIN]
	tInfo[DK_REC.TOTAL       ] = tInfo[DK_REC.TOTAL] + nValue
	tInfo[DK_REC.TOTAL_EFFECT] = tInfo[DK_REC.TOTAL_EFFECT] + nEffectValue
	------------------------
	-- # 节： tRecord
	------------------------
	tRecord[DK_REC_STAT.TOTAL       ] = tRecord[DK_REC_STAT.TOTAL] + nValue
	tRecord[DK_REC_STAT.TOTAL_EFFECT] = tRecord[DK_REC_STAT.TOTAL_EFFECT] + nEffectValue
	------------------------
	-- # 节： tRecord.Detail
	------------------------
	-- 添加/更新结果分类统计
	if not tRecord[DK_REC_STAT.DETAIL][nSkillResult] then
		tRecord[DK_REC_STAT.DETAIL][nSkillResult] = {
			[DK_REC_STAT_DETAIL.COUNT        ] =  0, -- 命中记录数量（假设nSkillResult是命中）
			[DK_REC_STAT_DETAIL.NZ_COUNT     ] =  0, -- 非零值命中记录数量
			[DK_REC_STAT_DETAIL.MAX          ] =  0, -- 单次命中最大值
			[DK_REC_STAT_DETAIL.MAX_EFFECT   ] =  0, -- 单次命中最大有效值
			[DK_REC_STAT_DETAIL.MIN          ] = -1, -- 单次命中最小值
			[DK_REC_STAT_DETAIL.NZ_MIN       ] = -1, -- 单次非零值命中最小值
			[DK_REC_STAT_DETAIL.MIN_EFFECT   ] = -1, -- 单次命中最小有效值
			[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT] = -1, -- 单次非零值命中最小有效值
			[DK_REC_STAT_DETAIL.TOTAL        ] =  0, -- 所有命中总伤害
			[DK_REC_STAT_DETAIL.TOTAL_EFFECT ] =  0, -- 所有命中总有效伤害
			[DK_REC_STAT_DETAIL.AVG          ] =  0, -- 所有命中平均伤害
			[DK_REC_STAT_DETAIL.NZ_AVG       ] =  0, -- 所有非零值命中平均伤害
			[DK_REC_STAT_DETAIL.AVG_EFFECT   ] =  0, -- 所有命中平均有效伤害
			[DK_REC_STAT_DETAIL.NZ_AVG_EFFECT] =  0, -- 所有非零值命中平均有效伤害
		}
	end
	local tResult = tRecord[DK_REC_STAT.DETAIL][nSkillResult]
	tResult[DK_REC_STAT_DETAIL.COUNT     ] = tResult[DK_REC_STAT_DETAIL.COUNT] + 1 -- 命中次数（假设nSkillResult是命中）
	tResult[DK_REC_STAT_DETAIL.MAX       ] = max(tResult[DK_REC_STAT_DETAIL.MAX], nValue) -- 单次命中最大值
	tResult[DK_REC_STAT_DETAIL.MAX_EFFECT] = max(tResult[DK_REC_STAT_DETAIL.MAX_EFFECT], nEffectValue) -- 单次命中最大有效值
	tResult[DK_REC_STAT_DETAIL.MIN       ] = Min(tResult[DK_REC_STAT_DETAIL.MIN], nValue) -- 单次命中最小值
	tResult[DK_REC_STAT_DETAIL.MIN_EFFECT] = Min(tResult[DK_REC_STAT_DETAIL.MIN_EFFECT], nEffectValue) -- 单次命中最小有效值
	tResult[DK_REC_STAT_DETAIL.TOTAL       ] = tResult[DK_REC_STAT_DETAIL.TOTAL] + nValue -- 所以命中总伤害
	tResult[DK_REC_STAT_DETAIL.TOTAL_EFFECT] = tResult[DK_REC_STAT_DETAIL.TOTAL_EFFECT] + nEffectValue -- 所有命中总有效伤害
	tResult[DK_REC_STAT_DETAIL.AVG         ] = floor(tResult[DK_REC_STAT_DETAIL.TOTAL] / tResult[DK_REC_STAT_DETAIL.COUNT]) -- 单次命中平均值
	tResult[DK_REC_STAT_DETAIL.AVG_EFFECT  ] = floor(tResult[DK_REC_STAT_DETAIL.TOTAL_EFFECT] / tResult[DK_REC_STAT_DETAIL.COUNT]) -- 单次命中平均有效值
	if nValue ~= 0 or NZ_SKILL_RESULT[nSkillResult] then
		tResult[DK_REC_STAT_DETAIL.NZ_COUNT] = tResult[DK_REC_STAT_DETAIL.NZ_COUNT] + 1 -- 命中次数（假设nSkillResult是命中）
		tResult[DK_REC_STAT_DETAIL.NZ_MIN  ] = Min(tResult[DK_REC_STAT_DETAIL.NZ_MIN], nValue) -- 单次命中最小值
		tResult[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT] = Min(tResult[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT], nEffectValue) -- 单次命中最小有效值
		tResult[DK_REC_STAT_DETAIL.NZ_AVG       ] = floor(tResult[DK_REC_STAT_DETAIL.TOTAL] / tResult[DK_REC_STAT_DETAIL.NZ_COUNT]) -- 单次命中平均值
		tResult[DK_REC_STAT_DETAIL.NZ_AVG_EFFECT] = floor(tResult[DK_REC_STAT_DETAIL.TOTAL_EFFECT] / tResult[DK_REC_STAT_DETAIL.NZ_COUNT]) -- 单次命中平均有效值
	end

	------------------------
	-- # 节： tRecord.Skill
	------------------------
	-- 添加具体技能记录
	if not tRecord[DK_REC_STAT.SKILL][szEffectName] then
		tRecord[DK_REC_STAT.SKILL][szEffectName] = {
			[DK_REC_STAT_SKILL.COUNT        ] =  0, -- 该玩家四象轮回释放次数（假设szEffectName是四象轮回）
			[DK_REC_STAT_SKILL.NZ_COUNT     ] =  0, -- 该玩家非零值四象轮回释放次数
			[DK_REC_STAT_SKILL.MAX          ] =  0, -- 该玩家四象轮回最大输出量
			[DK_REC_STAT_SKILL.MAX_EFFECT   ] =  0, -- 该玩家四象轮回最大有效输出量
			[DK_REC_STAT_SKILL.TOTAL        ] =  0, -- 该玩家四象轮回输出量总和
			[DK_REC_STAT_SKILL.TOTAL_EFFECT ] =  0, -- 该玩家四象轮回有效输出量总和
			[DK_REC_STAT_SKILL.AVG          ] =  0, -- 该玩家所有四象轮回平均伤害
			[DK_REC_STAT_SKILL.NZ_AVG       ] =  0, -- 该玩家所有非零值四象轮回平均伤害
			[DK_REC_STAT_SKILL.AVG_EFFECT   ] =  0, -- 该玩家所有四象轮回平均有效伤害
			[DK_REC_STAT_SKILL.NZ_AVG_EFFECT] =  0, -- 该玩家所有非零值四象轮回平均有效伤害
			[DK_REC_STAT_SKILL.DETAIL       ] = {}, -- 该玩家四象轮回输出结果分类统计
			[DK_REC_STAT_SKILL.TARGET       ] = {}, -- 该玩家四象轮回承受者统计
		}
	end
	local tSkillRecord = tRecord[DK_REC_STAT.SKILL][szEffectName]
	tSkillRecord[DK_REC_STAT_SKILL.COUNT       ] = tSkillRecord[DK_REC_STAT_SKILL.COUNT] + 1
	tSkillRecord[DK_REC_STAT_SKILL.MAX         ] = max(tSkillRecord[DK_REC_STAT_SKILL.MAX], nValue)
	tSkillRecord[DK_REC_STAT_SKILL.MAX_EFFECT  ] = max(tSkillRecord[DK_REC_STAT_SKILL.MAX_EFFECT], nEffectValue)
	tSkillRecord[DK_REC_STAT_SKILL.TOTAL       ] = tSkillRecord[DK_REC_STAT_SKILL.TOTAL] + nValue
	tSkillRecord[DK_REC_STAT_SKILL.TOTAL_EFFECT] = tSkillRecord[DK_REC_STAT_SKILL.TOTAL_EFFECT] + nEffectValue
	tSkillRecord[DK_REC_STAT_SKILL.AVG         ] = floor(tSkillRecord[DK_REC_STAT_SKILL.TOTAL] / tSkillRecord[DK_REC_STAT_SKILL.COUNT])
	tSkillRecord[DK_REC_STAT_SKILL.AVG_EFFECT  ] = floor(tSkillRecord[DK_REC_STAT_SKILL.TOTAL_EFFECT] / tSkillRecord[DK_REC_STAT_SKILL.COUNT])
	if nValue ~= 0 or NZ_SKILL_RESULT[nSkillResult] then
		tSkillRecord[DK_REC_STAT_SKILL.NZ_COUNT]     = tSkillRecord[DK_REC_STAT_SKILL.NZ_COUNT] + 1
		tSkillRecord[DK_REC_STAT_SKILL.NZ_AVG]       = floor(tSkillRecord[DK_REC_STAT_SKILL.TOTAL] / tSkillRecord[DK_REC_STAT_SKILL.NZ_COUNT])
		tSkillRecord[DK_REC_STAT_SKILL.NZ_AVG_EFFECT] = floor(tSkillRecord[DK_REC_STAT_SKILL.TOTAL_EFFECT] / tSkillRecord[DK_REC_STAT_SKILL.NZ_COUNT])
	end

	---------------------------------
	-- # 节： tRecord.Skill[x].Detail
	---------------------------------
	-- 添加/更新具体技能结果分类统计
	if not tSkillRecord[DK_REC_STAT_SKILL.DETAIL][nSkillResult] then
		tSkillRecord[DK_REC_STAT_SKILL.DETAIL][nSkillResult] = {
			[DK_REC_STAT_SKILL_DETAIL.COUNT        ] =  0, -- 命中记录数量
			[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT     ] =  0, -- 非零值命中记录数量
			[DK_REC_STAT_SKILL_DETAIL.MAX          ] =  0, -- 单次命中最大值
			[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT   ] =  0, -- 单次命中最大有效值
			[DK_REC_STAT_SKILL_DETAIL.MIN          ] = -1, -- 单次命中最小值
			[DK_REC_STAT_SKILL_DETAIL.NZ_MIN       ] = -1, -- 单次非零值命中最小值
			[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT   ] = -1, -- 单次命中最小有效值
			[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT] = -1, -- 单次非零值命中最小有效值
			[DK_REC_STAT_SKILL_DETAIL.TOTAL        ] =  0, -- 所以命中总伤害
			[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT ] =  0, -- 所有命中总有效伤害
			[DK_REC_STAT_SKILL_DETAIL.AVG          ] =  0, -- 所有命中平均伤害
			[DK_REC_STAT_SKILL_DETAIL.NZ_AVG       ] =  0, -- 所有非零值命中平均伤害
			[DK_REC_STAT_SKILL_DETAIL.AVG_EFFECT   ] =  0, -- 所有命中平均有效伤害
			[DK_REC_STAT_SKILL_DETAIL.NZ_AVG_EFFECT] =  0, -- 所有非零值命中平均有效伤害
		}
	end
	local tResult = tSkillRecord[DK_REC_STAT_SKILL.DETAIL][nSkillResult]
	tResult[DK_REC_STAT_SKILL_DETAIL.COUNT       ] = tResult[DK_REC_STAT_SKILL_DETAIL.COUNT] + 1 -- 命中次数（假设nSkillResult是命中）
	tResult[DK_REC_STAT_SKILL_DETAIL.MAX         ] = max(tResult[DK_REC_STAT_SKILL_DETAIL.MAX], nValue) -- 单次命中最大值
	tResult[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT  ] = max(tResult[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT], nEffectValue) -- 单次命中最大有效值
	tResult[DK_REC_STAT_SKILL_DETAIL.MIN         ] = Min(tResult[DK_REC_STAT_SKILL_DETAIL.MIN], nValue) -- 单次命中最小值
	tResult[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT  ] = Min(tResult[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT], nEffectValue) -- 单次命中最小有效值
	tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL       ] = tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL] + nValue -- 所以命中总伤害
	tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] = tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] + nEffectValue -- 所有命中总有效伤害
	tResult[DK_REC_STAT_SKILL_DETAIL.AVG         ] = floor(tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL] / tResult[DK_REC_STAT_SKILL_DETAIL.COUNT])
	tResult[DK_REC_STAT_SKILL_DETAIL.AVG_EFFECT  ] = floor(tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] / tResult[DK_REC_STAT_SKILL_DETAIL.COUNT])
	if nValue ~= 0 or NZ_SKILL_RESULT[nSkillResult] then
		tResult[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT     ] = tResult[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT] + 1 -- 命中次数（假设nSkillResult是命中）
		tResult[DK_REC_STAT_SKILL_DETAIL.NZ_MIN       ] = Min(tResult[DK_REC_STAT_SKILL_DETAIL.NZ_MIN], nValue) -- 单次命中最小值
		tResult[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT] = Min(tResult[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT], nEffectValue) -- 单次命中最小有效值
		tResult[DK_REC_STAT_SKILL_DETAIL.NZ_AVG       ] = floor(tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL] / tResult[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT])
		tResult[DK_REC_STAT_SKILL_DETAIL.NZ_AVG_EFFECT] = floor(tResult[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] / tResult[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT])
	end

	------------------------------
	-- # 节： tRecord.Skill.Target
	------------------------------
	-- 添加具体技能承受者记录
	if not tSkillRecord[DK_REC_STAT_SKILL.TARGET][idTarget] then
		tSkillRecord[DK_REC_STAT_SKILL.TARGET][idTarget] = {
			[DK_REC_STAT_SKILL_TARGET.MAX         ] = 0, -- 该玩家四象轮回击中的这个玩家最大伤害
			[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT  ] = 0, -- 该玩家四象轮回击中的这个玩家最大有效伤害
			[DK_REC_STAT_SKILL_TARGET.TOTAL       ] = 0, -- 该玩家四象轮回击中的这个玩家伤害总和
			[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] = 0, -- 该玩家四象轮回击中的这个玩家有效伤害总和
			[DK_REC_STAT_SKILL_TARGET.COUNT       ] = {  -- 该玩家四象轮回击中的这个玩家结果统计
				-- [SKILL_RESULT.HIT     ] = 5,
				-- [SKILL_RESULT.MISS    ] = 3,
				-- [SKILL_RESULT.CRITICAL] = 3,
			},
			[DK_REC_STAT_SKILL_TARGET.NZ_COUNT    ] = {  -- 该玩家非零值四象轮回击中的这个玩家结果统计
				-- [SKILL_RESULT.HIT     ] = 5,
				-- [SKILL_RESULT.MISS    ] = 3,
				-- [SKILL_RESULT.CRITICAL] = 3,
			},
		}
	end
	local tSkillTargetData = tSkillRecord[DK_REC_STAT_SKILL.TARGET][idTarget]
	tSkillTargetData[DK_REC_STAT_SKILL_TARGET.MAX         ] = max(tSkillTargetData[DK_REC_STAT_SKILL_TARGET.MAX], nValue)
	tSkillTargetData[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT  ] = max(tSkillTargetData[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT], nEffectValue)
	tSkillTargetData[DK_REC_STAT_SKILL_TARGET.TOTAL       ] = tSkillTargetData[DK_REC_STAT_SKILL_TARGET.TOTAL] + nValue
	tSkillTargetData[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] = tSkillTargetData[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] + nEffectValue
	tSkillTargetData[DK_REC_STAT_SKILL_TARGET.COUNT][nSkillResult] = (tSkillTargetData[DK_REC_STAT_SKILL_TARGET.COUNT][nSkillResult] or 0) + 1
	if nValue ~= 0 then
		tSkillTargetData[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][nSkillResult] = (tSkillTargetData[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][nSkillResult] or 0) + 1
	end

	------------------------
	-- # 节： tRecord.Target
	------------------------
	-- 添加具体承受/释放者记录
	if not tRecord[DK_REC_STAT.TARGET][idTarget] then
		tRecord[DK_REC_STAT.TARGET][idTarget] = {
			[DK_REC_STAT_TARGET.COUNT        ] =  0, -- 该玩家对idTarget的技能释放次数
			[DK_REC_STAT_TARGET.NZ_COUNT     ] =  0, -- 该玩家对idTarget的非零值技能释放次数
			[DK_REC_STAT_TARGET.MAX          ] =  0, -- 该玩家对idTarget的技能最大输出量
			[DK_REC_STAT_TARGET.MAX_EFFECT   ] =  0, -- 该玩家对idTarget的技能最大有效输出量
			[DK_REC_STAT_TARGET.TOTAL        ] =  0, -- 该玩家对idTarget的技能输出量总和
			[DK_REC_STAT_TARGET.TOTAL_EFFECT ] =  0, -- 该玩家对idTarget的技能有效输出量总和
			[DK_REC_STAT_TARGET.AVG          ] =  0, -- 该玩家对idTarget的技能平均输出量
			[DK_REC_STAT_TARGET.NZ_AVG       ] =  0, -- 该玩家对idTarget的非零值技能平均输出量
			[DK_REC_STAT_TARGET.AVG_EFFECT   ] =  0, -- 该玩家对idTarget的技能平均有效输出量
			[DK_REC_STAT_TARGET.NZ_AVG_EFFECT] =  0, -- 该玩家对idTarget的非零值技能平均有效输出量
			[DK_REC_STAT_TARGET.DETAIL       ] = {}, -- 该玩家对idTarget的技能输出结果分类统计
			[DK_REC_STAT_TARGET.SKILL        ] = {}, -- 该玩家对idTarget的技能具体分别统计
		}
	end
	local tTargetRecord = tRecord[DK_REC_STAT.TARGET][idTarget]
	tTargetRecord[DK_REC_STAT_TARGET.COUNT       ] = tTargetRecord[DK_REC_STAT_TARGET.COUNT] + 1
	tTargetRecord[DK_REC_STAT_TARGET.MAX         ] = max(tTargetRecord[DK_REC_STAT_TARGET.MAX], nValue)
	tTargetRecord[DK_REC_STAT_TARGET.MAX_EFFECT  ] = max(tTargetRecord[DK_REC_STAT_TARGET.MAX_EFFECT], nEffectValue)
	tTargetRecord[DK_REC_STAT_TARGET.TOTAL       ] = tTargetRecord[DK_REC_STAT_TARGET.TOTAL] + nValue
	tTargetRecord[DK_REC_STAT_TARGET.TOTAL_EFFECT] = tTargetRecord[DK_REC_STAT_TARGET.TOTAL_EFFECT] + nEffectValue
	tTargetRecord[DK_REC_STAT_TARGET.AVG         ] = floor(tTargetRecord[DK_REC_STAT_TARGET.TOTAL] / tTargetRecord[DK_REC_STAT_TARGET.COUNT])
	tTargetRecord[DK_REC_STAT_TARGET.AVG_EFFECT  ] = floor(tTargetRecord[DK_REC_STAT_TARGET.TOTAL_EFFECT] / tTargetRecord[DK_REC_STAT_TARGET.COUNT])
	if nValue ~= 0 or NZ_SKILL_RESULT[nSkillResult] then
		tTargetRecord[DK_REC_STAT_TARGET.NZ_COUNT     ] = tTargetRecord[DK_REC_STAT_TARGET.NZ_COUNT] + 1
		tTargetRecord[DK_REC_STAT_TARGET.NZ_AVG       ] = floor(tTargetRecord[DK_REC_STAT_TARGET.TOTAL] / tTargetRecord[DK_REC_STAT_TARGET.NZ_COUNT])
		tTargetRecord[DK_REC_STAT_TARGET.NZ_AVG_EFFECT] = floor(tTargetRecord[DK_REC_STAT_TARGET.TOTAL_EFFECT] / tTargetRecord[DK_REC_STAT_TARGET.NZ_COUNT])
	end

	----------------------------------
	-- # 节： tRecord.Target[x].Detail
	----------------------------------
	-- 添加/更新具体承受/释放者结果分类统计
	if not tTargetRecord[DK_REC_STAT_TARGET.DETAIL][nSkillResult] then
		tTargetRecord[DK_REC_STAT_TARGET.DETAIL][nSkillResult] = {
			[DK_REC_STAT_TARGET_DETAIL.COUNT        ] =  0, -- 命中记录数量（假设nSkillResult是命中）
			[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT     ] =  0, -- 非零值命中记录数量
			[DK_REC_STAT_TARGET_DETAIL.MAX          ] =  0, -- 单次命中最大值
			[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT   ] =  0, -- 单次命中最大有效值
			[DK_REC_STAT_TARGET_DETAIL.MIN          ] = -1, -- 单次命中最小值
			[DK_REC_STAT_TARGET_DETAIL.NZ_MIN       ] = -1, -- 单次非零值命中最小值
			[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT   ] = -1, -- 单次命中最小有效值
			[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT] = -1, -- 单次非零值命中最小有效值
			[DK_REC_STAT_TARGET_DETAIL.TOTAL        ] =  0, -- 所以命中总伤害
			[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT ] =  0, -- 所有命中总有效伤害
			[DK_REC_STAT_TARGET_DETAIL.AVG          ] =  0, -- 所有命中平均伤害
			[DK_REC_STAT_TARGET_DETAIL.NZ_AVG       ] =  0, -- 所有非零值命中平均伤害
			[DK_REC_STAT_TARGET_DETAIL.AVG_EFFECT   ] =  0, -- 所有命中平均有效伤害
			[DK_REC_STAT_TARGET_DETAIL.NZ_AVG_EFFECT] =  0, -- 所有非零值命中平均有效伤害
		}
	end
	local tResult = tTargetRecord[DK_REC_STAT_TARGET.DETAIL][nSkillResult]
	tResult[DK_REC_STAT_TARGET_DETAIL.COUNT       ] = tResult[DK_REC_STAT_TARGET_DETAIL.COUNT] + 1 -- 命中次数（假设nSkillResult是命中）
	tResult[DK_REC_STAT_TARGET_DETAIL.MAX         ] = max(tResult[DK_REC_STAT_TARGET_DETAIL.MAX], nValue) -- 单次命中最大值
	tResult[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT  ] = max(tResult[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT], nEffectValue) -- 单次命中最大有效值
	tResult[DK_REC_STAT_TARGET_DETAIL.MIN         ] = Min(tResult[DK_REC_STAT_TARGET_DETAIL.MIN], nValue) -- 单次命中最小值
	tResult[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT  ] = Min(tResult[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT], nEffectValue) -- 单次命中最小有效值
	tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL       ] = tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL] + nValue -- 所以命中总伤害
	tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] = tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] + nEffectValue -- 所有命中总有效伤害
	tResult[DK_REC_STAT_TARGET_DETAIL.AVG         ] = floor(tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL] / tResult[DK_REC_STAT_TARGET_DETAIL.COUNT])
	tResult[DK_REC_STAT_TARGET_DETAIL.AVG_EFFECT  ] = floor(tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] / tResult[DK_REC_STAT_TARGET_DETAIL.COUNT])
	if nValue ~= 0 or NZ_SKILL_RESULT[nSkillResult] then
		tResult[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT     ] = tResult[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT] + 1 -- 命中次数（假设nSkillResult是命中）
		tResult[DK_REC_STAT_TARGET_DETAIL.NZ_MIN       ] = Min(tResult[DK_REC_STAT_TARGET_DETAIL.NZ_MIN], nValue) -- 单次命中最小值
		tResult[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT] = Min(tResult[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT], nEffectValue) -- 单次命中最小有效值
		tResult[DK_REC_STAT_TARGET_DETAIL.NZ_AVG       ] = floor(tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL] / tResult[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT])
		tResult[DK_REC_STAT_TARGET_DETAIL.NZ_AVG_EFFECT] = floor(tResult[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] / tResult[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT])
	end

	---------------------------------
	-- # 节： tRecord.Target[x].Skill
	---------------------------------
	-- 添加承受者具体技能记录
	if not tTargetRecord[DK_REC_STAT_TARGET.SKILL][szEffectName] then
		tTargetRecord[DK_REC_STAT_TARGET.SKILL][szEffectName] = {
			[DK_REC_STAT_TARGET_SKILL.MAX         ] = 0, -- 该玩家击中这个玩家的四象轮回最大伤害
			[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT  ] = 0, -- 该玩家击中这个玩家的四象轮回最大有效伤害
			[DK_REC_STAT_TARGET_SKILL.TOTAL       ] = 0, -- 该玩家击中这个玩家的四象轮回伤害总和
			[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] = 0, -- 该玩家击中这个玩家的四象轮回有效伤害总和
			[DK_REC_STAT_TARGET_SKILL.COUNT       ] = {  -- 该玩家击中这个玩家的四象轮回结果统计
				-- [SKILL_RESULT.HIT     ] = 5,
				-- [SKILL_RESULT.MISS    ] = 3,
				-- [SKILL_RESULT.CRITICAL] = 3,
			},
			[DK_REC_STAT_TARGET_SKILL.NZ_COUNT    ] = {  -- 该玩家非零值击中这个玩家的四象轮回结果统计
				-- [SKILL_RESULT.HIT     ] = 5,
				-- [SKILL_RESULT.MISS    ] = 3,
				-- [SKILL_RESULT.CRITICAL] = 3,
			},
		}
	end
	local tTargetSkillData = tTargetRecord[DK_REC_STAT_TARGET.SKILL][szEffectName]
	tTargetSkillData[DK_REC_STAT_TARGET_SKILL.MAX         ] = max(tTargetSkillData[DK_REC_STAT_TARGET_SKILL.MAX], nValue)
	tTargetSkillData[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT  ] = max(tTargetSkillData[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT], nEffectValue)
	tTargetSkillData[DK_REC_STAT_TARGET_SKILL.TOTAL       ] = tTargetSkillData[DK_REC_STAT_TARGET_SKILL.TOTAL] + nValue
	tTargetSkillData[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] = tTargetSkillData[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] + nEffectValue
	tTargetSkillData[DK_REC_STAT_TARGET_SKILL.COUNT][nSkillResult] = (tTargetSkillData[DK_REC_STAT_TARGET_SKILL.COUNT][nSkillResult] or 0) + 1
	if nValue ~= 0 then
		tTargetSkillData[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][nSkillResult] = (tTargetSkillData[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][nSkillResult] or 0) + 1
	end
end

-- 插入一条伤害记录
function D.AddDamageRecord(data, dwCaster, dwTarget, szEffectID, nDamage, nEffectDamage, nSkillResult)
	-- 添加伤害记录
	D.InitObjectData(data, dwCaster, DK.DAMAGE)
	D.InsertRecord(data, DK.DAMAGE, dwCaster, dwTarget, szEffectID, nDamage, nEffectDamage, nSkillResult)
	-- 添加承伤记录
	D.InitObjectData(data, dwTarget, DK.BE_DAMAGE)
	D.InsertRecord(data, DK.BE_DAMAGE, dwTarget, dwCaster, szEffectID, nDamage, nEffectDamage, nSkillResult)
end

-- 插入一条治疗记录
function D.AddHealRecord(data, dwCaster, dwTarget, szEffectID, nHeal, nEffectHeal, nSkillResult)
	-- 添加伤害记录
	D.InitObjectData(data, dwCaster, DK.HEAL)
	D.InsertRecord(data, DK.HEAL, dwCaster, dwTarget, szEffectID, nHeal, nEffectHeal, nSkillResult)
	-- 添加承伤记录
	D.InitObjectData(data, dwTarget, DK.BE_HEAL)
	D.InsertRecord(data, DK.BE_HEAL, dwTarget, dwCaster, szEffectID, nHeal, nEffectHeal, nSkillResult)
end

-- 确认对象数据已创建（未创建则创建）
function D.InitObjectData(data, dwID, szChannel)
	-- 名称缓存
	if not data[DK.NAME_LIST][dwID] then
		data[DK.NAME_LIST][dwID] = LIB.GetObjectName(IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC, dwID, 'never') -- 名称缓存
	end
	-- 势力缓存
	if not data[DK.FORCE_LIST][dwID] then
		if IsPlayer(dwID) then
			local player = GetPlayer(dwID)
			if player then
				data[DK.FORCE_LIST][dwID] = player.dwForceID or 0
			end
		else
			data[DK.FORCE_LIST][dwID] = 0
		end
	end
	-- 统计结构体
	if szChannel and not data[szChannel][DK_REC.STAT][dwID] then
		data[szChannel][DK_REC.STAT][dwID] = {
			[DK_REC_STAT.TOTAL       ] = 0 , -- 总输出
			[DK_REC_STAT.TOTAL_EFFECT] = 0 , -- 有效输出
			[DK_REC_STAT.DETAIL      ] = {}, -- 输出结果按技能结果分类统计
			[DK_REC_STAT.SKILL       ] = {}, -- 该玩家具体造成输出的技能统计
			[DK_REC_STAT.TARGET      ] = {}, -- 该玩家具体对谁造成输出的统计
		}
	end
end

function D.InitEffectData(data, nType, dwID, nLevel)
	local szKey = nType .. ',' .. dwID .. ',' .. nLevel
	if not data[DK.EFFECT_LIST][szKey] then
		local szName, bAnonymous = nil, false
		if nType == SKILL_EFFECT_TYPE.SKILL then
			szName = Table_GetSkillName(dwID, nLevel)
		elseif nType == SKILL_EFFECT_TYPE.BUFF then
			szName = Table_GetBuffName(dwID, nLevel)
		end
		if not szName or szName == '' then
			bAnonymous = true
			szName = '#' .. dwID .. ',' .. nLevel
		end
		data[DK.EFFECT_LIST][szKey] = {szName, bAnonymous, nType, dwID, nLevel}
	end
	return szKey
end

-- 初始化Data
do
local function GeneTypeNS()
	return {
		[DK_REC.TIME_DURING ] = 0,
		[DK_REC.TOTAL       ] = 0,
		[DK_REC.TOTAL_EFFECT] = 0,
		[DK_REC.STAT        ] = {},
	}
end
function D.InitData()
	local bFighting = LIB.IsFighting()
	local nFightTick = bFighting and LIB.GetFightTime() or 0
	Data = {
		[DK.UUID       ] = LIB.GetFightUUID(),                -- 战斗唯一标识
		[DK.VERSION    ] = VERSION,                           -- 数据版本号
		[DK.TIME_BEGIN ] = GetCurrentTime(),                  -- 战斗开始时间
		[DK.TICK_BEGIN ] = GetTime(),                         -- 战斗开始毫秒时间
		[DK.TIME_DURING] = - (nFightTick / 1000) - 1,         -- 战斗持续时间 负数表示本次战斗尚未结束 其数值为记录开始时负的战斗秒数减一
		[DK.TICK_DURING] = - nFightTick - 1,                  -- 战斗持续毫秒时间 负数表示本次战斗尚未结束 其数值为记录开始时负的战斗毫秒数减一
		[DK.AWAYTIME   ] = {},                                -- 死亡/掉线时间节点
		[DK.NAME_LIST  ] = {},                                -- 名称缓存
		[DK.FORCE_LIST ] = {},                                -- 势力缓存
		[DK.EFFECT_LIST] = {},                                -- 效果信息缓存
		[DK.DAMAGE     ] = GeneTypeNS(),                      -- 输出统计
		[DK.HEAL       ] = GeneTypeNS(),                      -- 治疗统计
		[DK.BE_HEAL    ] = GeneTypeNS(),                      -- 承疗统计
		[DK.BE_DAMAGE  ] = GeneTypeNS(),                      -- 承伤统计
		[DK.EVERYTHING ] = {},                                -- 战斗复盘
	}
end
end

-- Data数据压入历史记录 并重新初始化Data
function D.Flush()
	if Data and Data[DK.UUID] then
		-- 过滤空记录
		if IsEmpty(Data[DK.BE_DAMAGE][DK_REC.STAT])
		and IsEmpty(Data[DK.DAMAGE][DK_REC.STAT])
		and IsEmpty(Data[DK.HEAL][DK_REC.STAT])
		and IsEmpty(Data[DK.BE_HEAL][DK_REC.STAT]) then
			return
		end

		-- 计算受伤最多的名字作为战斗名称
		local nMaxValue, szBossName = 0, nil
		local nEnemyMaxValue, szEnemyBossName = 0, nil
		for id, p in pairs(Data[DK.BE_DAMAGE][DK_REC.STAT]) do
			if nEnemyMaxValue < p[DK_REC_STAT.TOTAL_EFFECT] and not D.IsParty(id) then
				nEnemyMaxValue  = p[DK_REC_STAT.TOTAL_EFFECT]
				szEnemyBossName = D.GetNameAusID(Data, id)
			end
			if nMaxValue < p[DK_REC_STAT.TOTAL_EFFECT] and id ~= UI_GetClientPlayerID() then
				nMaxValue  = p[DK_REC_STAT.TOTAL_EFFECT]
				szBossName = D.GetNameAusID(Data, id)
			end
		end
		-- 如果没有 则计算输出最多的NPC名字作为战斗名称
		if not szBossName or not szEnemyBossName then
			for id, p in pairs(Data[DK.DAMAGE][DK_REC.STAT]) do
				if nEnemyMaxValue < p[DK_REC_STAT.TOTAL_EFFECT] and not D.IsParty(id) then
					nEnemyMaxValue  = p[DK_REC_STAT.TOTAL_EFFECT]
					szEnemyBossName = D.GetNameAusID(Data, id)
				end
				if nMaxValue < p[DK_REC_STAT.TOTAL_EFFECT] and not tonumber(id) then
					nMaxValue  = p[DK_REC_STAT.TOTAL_EFFECT]
					szBossName = D.GetNameAusID(Data, id)
				end
			end
		end
		Data[DK.BOSSNAME] = szEnemyBossName or szBossName or g_tStrings.STR_NAME_UNKNOWN

		local nFightTick = LIB.GetFightTime() or 0
		Data[DK.TIME_DURING] = floor(nFightTick / 1000) + Data[DK.TIME_DURING] + 1
		Data[DK.TICK_DURING] = nFightTick + Data[DK.TICK_DURING] + 1

		if Data[DK.TIME_DURING] > O.nMinFightTime then
			local szFilePath = LIB.FormatPath(DS_ROOT) .. D.GetDataFileName(Data)
			HISTORY_CACHE[szFilePath] = Data
			UNSAVED_CACHE[szFilePath] = Data
			if O.bSaveHistoryOnExFi then
				D.SaveHistory()
			end
		end
	end
	D.InitData()
end

-- 系统日志监控（数据源）
LIB.RegisterEvent('SYS_MSG', function()
	if not O.bEnable then
		return
	end
	if arg0 == 'UI_OME_SKILL_CAST_LOG' then
		-- 技能施放日志；
		-- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID (arg3)dwLevel：技能等级
		-- D.OnSkillCast(arg1, arg2, arg3)
	elseif arg0 == 'UI_OME_SKILL_CAST_RESPOND_LOG' then
		-- 技能施放结果日志；
		-- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID
		-- (arg3)dwLevel：技能等级 (arg4)nRespond：见枚举型[[SKILL_RESULT_CODE]]
		-- D.OnSkillCastRespond(arg1, arg2, arg3, arg4)
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		-- if not LIB.IsInArena() then
		-- 技能最终产生的效果（生命值的变化）；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID
		-- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResultCount：数值集合
		-- D.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
		if arg7 and arg7 ~= 0 then -- bCriticalStrike
			D.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.CRITICAL, arg8, arg9)
		else
			D.OnSkillEffect(arg1, arg2, arg4, arg5, arg6, SKILL_RESULT.HIT, arg8, arg9)
		end
		-- end
	elseif arg0 == 'UI_OME_SKILL_BLOCK_LOG' then
		-- 格挡日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)nType：Effect的类型
		-- (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级 (arg6)nDamageType：伤害类型，见枚举型[[SKILL_RESULT_TYPE]]
		D.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.BLOCK, nil, {})
	elseif arg0 == 'UI_OME_SKILL_SHIELD_LOG' then
		-- 技能被屏蔽日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		D.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.SHIELD, nil, {})
	elseif arg0 == 'UI_OME_SKILL_MISS_LOG' then
		-- 技能未命中目标日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		D.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.MISS, nil, {})
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		-- 技能命中目标日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		-- D.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.HIT, nil, {})
	elseif arg0 == 'UI_OME_SKILL_DODGE_LOG' then
		-- 技能被闪避日志；
		-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标
		-- (arg3)nType：Effect的类型 (arg4)dwID：Effect的ID (arg5)dwLevel：Effect的等级
		D.OnSkillEffect(arg1, arg2, arg3, arg4, arg5, SKILL_RESULT.DODGE, nil, {})
	elseif arg0 == 'UI_OME_COMMON_HEALTH_LOG' then
		-- 普通治疗日志；
		-- (arg1)dwCharacterID：承疗玩家ID (arg2)nDeltaLife：增加血量值
		-- D.OnCommonHealth(arg1, arg2)
	end
end)

-- JJC中使用的数据源（不能记录溢出数据）
-- LIB.RegisterEvent('SKILL_EFFECT_TEXT', function(event)
--     if LIB.IsInArena() then
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
--             D.OnSkillEffect(dwCasterID, dwTargetID, nEffectType, dwSkillID, dwSkillLevel, SKILL_RESULT.CRITICAL, nResultCount, tResult)
--         else
--             D.OnSkillEffect(dwCasterID, dwTargetID, nEffectType, dwSkillID, dwSkillLevel, SKILL_RESULT.HIT, nResultCount, tResult)
--         end
--     end
-- end)


-- 系统BUFF监控（数据源）
LIB.RegisterEvent('BUFF_UPDATE', function()
	if not O.bEnable then
		return
	end
	-- buff update：
	-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
	-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
	-- arg8：nLevel，arg9：dwSkillSrcID
	D.OnBuffUpdate(arg9, arg0, arg4, arg8, arg5, arg1, arg6, arg3)
end)

-- 有人死了活了做一下时间轴记录
function D.OnTeammateStateChange(dwID, bLeave, nAwayType, bAddWhenRecEmpty)
	if not (Data and Data[DK.AWAYTIME]) then
		return
	end
	-- 获得一个人的记录
	local rec = Data[DK.AWAYTIME][dwID]
	if not rec then -- 初始化一个记录
		if not bLeave and not bAddWhenRecEmpty then
			return -- 不是一次暂离的开始并且不强制记录则跳过
		end
		rec = {}
		Data[DK.AWAYTIME][dwID] = rec
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
		insert(rec, { GetCurrentTime(), nil, nAwayType })
	else -- 暂离回来
		if #rec == 0 then -- 没记录到暂离开始 创建一个从本次战斗开始的暂离（俗称还没开打你就死了。。）
			insert(rec, { Data[DK.TIME_BEGIN], GetCurrentTime(), nAwayType })
		elseif not rec[#rec][2] then -- 如果最后一次暂离还没回来 则完成最后一次暂离的记录
			rec[#rec][2] = GetCurrentTime()
		end
	end
end
LIB.RegisterEvent('PARTY_UPDATE_MEMBER_INFO', function()
	if not O.bEnable then
		return
	end
	local team = GetClientTeam()
	local info = team.GetMemberInfo(arg1)
	if info then
		D.OnTeammateStateChange(arg1, info.bDeathFlag, AWAYTIME_TYPE.DEATH, false)
	end
end)
LIB.RegisterEvent('SYS_MSG', function()
	if not O.bEnable then
		return
	end
	if arg0 ~= 'UI_OME_DEATH_NOTIFY' then
		return
	end
	-- 插入数据到日志
	local nLFC, nTime, nTick = GetLogicFrameCount(), GetCurrentTime(), GetTime()
	local dwID, dwKiller = arg1, arg2
	if LIB.IsParty(dwID) or LIB.IsParty(dwKiller) then
		D.InsertEverything(
			Data, nLFC, nTime, nTick,
			EVERYTHING_TYPE.DEATH, dwID, dwKiller,
			LIB.GetObjectName(IsPlayer(dwID) and TARGET.PLAYER or TARGET.NPC, dwID),
			LIB.GetObjectName(IsPlayer(dwKiller) and TARGET.PLAYER or TARGET.NPC, dwKiller)
		)
	end
end)
LIB.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', function()
	if not O.bEnable then
		return
	end
	if LIB.IsParty(arg1) then
		local nLFC, nTime, nTick = GetLogicFrameCount(), GetCurrentTime(), GetTime()
		D.InsertEverything(
			Data, nLFC, nTime, nTick,
			EVERYTHING_TYPE.ONLINE, arg1, arg2,
			LIB.GetObjectName(TARGET.PLAYER, arg1)
		)
	end
	if arg2 == 0 then -- 有人掉线
		D.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.OFFLINE, false)
	else -- 有人上线
		D.OnTeammateStateChange(arg1, false, AWAYTIME_TYPE.OFFLINE, false)
		local team = GetClientTeam()
		local info = team.GetMemberInfo(arg1)
		if info and info.bDeathFlag then -- 上线死着的 结束离线暂离 开始死亡暂离
			D.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.DEATH, false)
		end
	end
end)
LIB.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- 开战扫描队友 记录开战就死掉/掉线的人
	if not O.bEnable then
		return
	end
	local team = GetClientTeam()
	local me = GetClientPlayer()
	if team and me and (me.IsInParty() or me.IsInRaid()) then
		for _, dwID in ipairs(team.GetTeamMemberList()) do
			local info = team.GetMemberInfo(dwID)
			if info then
				if not info.bIsOnLine then
					D.OnTeammateStateChange(dwID, true, AWAYTIME_TYPE.OFFLINE, true)
				elseif info.bDeathFlag then
					D.OnTeammateStateChange(dwID, true, AWAYTIME_TYPE.DEATH, true)
				end
			end
		end
	end
end)
LIB.RegisterEvent('PARTY_ADD_MEMBER', function() -- 中途有人进队 补上暂离记录
	if not O.bEnable then
		return
	end
	local team = GetClientTeam()
	local info = team.GetMemberInfo(arg1)
	if info then
		D.OnTeammateStateChange(arg1, false, AWAYTIME_TYPE.HALFWAY_JOINED, true)
		if info.bDeathFlag then
			D.OnTeammateStateChange(arg1, true, AWAYTIME_TYPE.DEATH, true)
		end
	end
end)

LIB.RegisterInit('MY_Recount_DS', function()
	D.LoadData()
end)

LIB.RegisterFlush('MY_Recount_DS', function()
	D.SaveData()
	if O.bSaveHistoryOnExit then
		D.SaveHistory()
	end
end)

-- 同名目标数据合并
function D.MergeTargetData(tDst, tSrc, data, szChannel, bMergeNpc, bMergeEffect, bHideAnonymous)
	------------------------
	-- # 节： tRecord
	------------------------
	-- 合并总数据
	tDst[DK_REC_STAT.TOTAL] = tDst[DK_REC_STAT.TOTAL] + tSrc[DK_REC_STAT.TOTAL]
	tDst[DK_REC_STAT.TOTAL_EFFECT] = tDst[DK_REC_STAT.TOTAL_EFFECT] + tSrc[DK_REC_STAT.TOTAL_EFFECT]
	------------------------
	-- # 节： tRecord.Detail
	------------------------
	-- 合并分类详情（命中、会心、偏离...）
	for nType, tSrcDetail in pairs(tSrc[DK_REC_STAT.DETAIL]) do
		local tDstDetail = tDst[DK_REC_STAT.DETAIL][nType]
		if not tDstDetail then
			tDstDetail = {
				[DK_REC_STAT_DETAIL.COUNT        ] =  0, -- 命中记录数量（假设nSkillResult是命中）
				[DK_REC_STAT_DETAIL.NZ_COUNT     ] =  0, -- 非零值命中记录数量
				[DK_REC_STAT_DETAIL.MAX          ] =  0, -- 单次命中最大值
				[DK_REC_STAT_DETAIL.MAX_EFFECT   ] =  0, -- 单次命中最大有效值
				[DK_REC_STAT_DETAIL.MIN          ] = -1, -- 单次命中最小值
				[DK_REC_STAT_DETAIL.NZ_MIN       ] = -1, -- 单次非零值命中最小值
				[DK_REC_STAT_DETAIL.MIN_EFFECT   ] = -1, -- 单次命中最小有效值
				[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT] = -1, -- 单次非零值命中最小有效值
				[DK_REC_STAT_DETAIL.TOTAL        ] =  0, -- 所有命中总伤害
				[DK_REC_STAT_DETAIL.TOTAL_EFFECT ] =  0, -- 所有命中总有效伤害
				[DK_REC_STAT_DETAIL.AVG          ] =  0, -- 所有命中平均伤害
				[DK_REC_STAT_DETAIL.NZ_AVG       ] =  0, -- 所有非零值命中平均伤害
				[DK_REC_STAT_DETAIL.AVG_EFFECT   ] =  0, -- 所有命中平均有效伤害
				[DK_REC_STAT_DETAIL.NZ_AVG_EFFECT] =  0, -- 所有非零值命中平均有效伤害
			}
			tDst[DK_REC_STAT.DETAIL][nType] = tDstDetail
		end
		tDstDetail[DK_REC_STAT_DETAIL.COUNT        ] = tDstDetail[DK_REC_STAT_DETAIL.COUNT] + tSrcDetail[DK_REC_STAT_DETAIL.COUNT]
		tDstDetail[DK_REC_STAT_DETAIL.NZ_COUNT     ] = tDstDetail[DK_REC_STAT_DETAIL.NZ_COUNT] + tSrcDetail[DK_REC_STAT_DETAIL.NZ_COUNT]
		tDstDetail[DK_REC_STAT_DETAIL.MAX          ] = max(tDstDetail[DK_REC_STAT_DETAIL.MAX], tSrcDetail[DK_REC_STAT_DETAIL.MAX])
		tDstDetail[DK_REC_STAT_DETAIL.MAX_EFFECT   ] = max(tDstDetail[DK_REC_STAT_DETAIL.MAX_EFFECT], tSrcDetail[DK_REC_STAT_DETAIL.MAX_EFFECT])
		tDstDetail[DK_REC_STAT_DETAIL.MIN          ] = Min(tDstDetail[DK_REC_STAT_DETAIL.MIN], tSrcDetail[DK_REC_STAT_DETAIL.MIN])
		tDstDetail[DK_REC_STAT_DETAIL.NZ_MIN       ] = Min(tDstDetail[DK_REC_STAT_DETAIL.NZ_MIN], tSrcDetail[DK_REC_STAT_DETAIL.NZ_MIN])
		tDstDetail[DK_REC_STAT_DETAIL.MIN_EFFECT   ] = Min(tDstDetail[DK_REC_STAT_DETAIL.MIN_EFFECT], tSrcDetail[DK_REC_STAT_DETAIL.MIN_EFFECT])
		tDstDetail[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT] = Min(tDstDetail[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT], tSrcDetail[DK_REC_STAT_DETAIL.NZ_MIN_EFFECT])
		tDstDetail[DK_REC_STAT_DETAIL.TOTAL        ] = tDstDetail[DK_REC_STAT_DETAIL.TOTAL] + tSrcDetail[DK_REC_STAT_DETAIL.TOTAL]
		tDstDetail[DK_REC_STAT_DETAIL.TOTAL_EFFECT ] = tDstDetail[DK_REC_STAT_DETAIL.TOTAL_EFFECT] + tSrcDetail[DK_REC_STAT_DETAIL.TOTAL_EFFECT]
		tDstDetail[DK_REC_STAT_DETAIL.AVG          ] = floor(tDstDetail[DK_REC_STAT_DETAIL.TOTAL] / tDstDetail[DK_REC_STAT_DETAIL.COUNT])
		tDstDetail[DK_REC_STAT_DETAIL.NZ_AVG       ] = floor(tDstDetail[DK_REC_STAT_DETAIL.TOTAL] / tDstDetail[DK_REC_STAT_DETAIL.NZ_COUNT])
		tDstDetail[DK_REC_STAT_DETAIL.AVG_EFFECT   ] = floor(tDstDetail[DK_REC_STAT_DETAIL.TOTAL_EFFECT] / tDstDetail[DK_REC_STAT_DETAIL.COUNT])
		tDstDetail[DK_REC_STAT_DETAIL.NZ_AVG_EFFECT] = floor(tDstDetail[DK_REC_STAT_DETAIL.TOTAL_EFFECT] / tDstDetail[DK_REC_STAT_DETAIL.NZ_COUNT])
	end
	------------------------
	-- # 节： tRecord.Skill
	------------------------
	-- 合并技能统计（四象轮回、两仪化形...）
	for szEffectID, tSrcSkill in pairs(tSrc[DK_REC_STAT.SKILL]) do
		if not bHideAnonymous or not select(2, D.GetEffectInfoAusID(data, szEffectID)) then
			local id = bMergeEffect
				and D.GetEffectNameAusID(data, szChannel, szEffectID)
				or szEffectID
			local tDstSkill = tDst[DK_REC_STAT.SKILL][id]
			if not tDstSkill then
				tDstSkill = {
					[DK_REC_STAT_SKILL.COUNT        ] =  0, -- 该玩家四象轮回释放次数（假设szEffectName是四象轮回）
					[DK_REC_STAT_SKILL.NZ_COUNT     ] =  0, -- 该玩家非零值四象轮回释放次数
					[DK_REC_STAT_SKILL.MAX          ] =  0, -- 该玩家四象轮回最大输出量
					[DK_REC_STAT_SKILL.MAX_EFFECT   ] =  0, -- 该玩家四象轮回最大有效输出量
					[DK_REC_STAT_SKILL.TOTAL        ] =  0, -- 该玩家四象轮回输出量总和
					[DK_REC_STAT_SKILL.TOTAL_EFFECT ] =  0, -- 该玩家四象轮回有效输出量总和
					[DK_REC_STAT_SKILL.AVG          ] =  0, -- 该玩家所有四象轮回平均伤害
					[DK_REC_STAT_SKILL.NZ_AVG       ] =  0, -- 该玩家所有非零值四象轮回平均伤害
					[DK_REC_STAT_SKILL.AVG_EFFECT   ] =  0, -- 该玩家所有四象轮回平均有效伤害
					[DK_REC_STAT_SKILL.NZ_AVG_EFFECT] =  0, -- 该玩家所有非零值四象轮回平均有效伤害
					[DK_REC_STAT_SKILL.DETAIL       ] = {}, -- 该玩家四象轮回输出结果分类统计
					[DK_REC_STAT_SKILL.TARGET       ] = {}, -- 该玩家四象轮回承受者统计
				}
				tDst[DK_REC_STAT.SKILL][id] = tDstSkill
			end
			tDstSkill[DK_REC_STAT_SKILL.COUNT        ] = tDstSkill[DK_REC_STAT_SKILL.COUNT] + tSrcSkill[DK_REC_STAT_SKILL.COUNT]
			tDstSkill[DK_REC_STAT_SKILL.NZ_COUNT     ] = tDstSkill[DK_REC_STAT_SKILL.NZ_COUNT] + tSrcSkill[DK_REC_STAT_SKILL.NZ_COUNT]
			tDstSkill[DK_REC_STAT_SKILL.MAX          ] = max(tDstSkill[DK_REC_STAT_SKILL.MAX], tSrcSkill[DK_REC_STAT_SKILL.MAX])
			tDstSkill[DK_REC_STAT_SKILL.MAX_EFFECT   ] = max(tDstSkill[DK_REC_STAT_SKILL.MAX_EFFECT], tSrcSkill[DK_REC_STAT_SKILL.MAX_EFFECT])
			tDstSkill[DK_REC_STAT_SKILL.TOTAL        ] = tDstSkill[DK_REC_STAT_SKILL.TOTAL] + tSrcSkill[DK_REC_STAT_SKILL.TOTAL]
			tDstSkill[DK_REC_STAT_SKILL.TOTAL_EFFECT ] = tDstSkill[DK_REC_STAT_SKILL.TOTAL_EFFECT] + tSrcSkill[DK_REC_STAT_SKILL.TOTAL_EFFECT]
			tDstSkill[DK_REC_STAT_SKILL.AVG          ] = floor(tDstSkill[DK_REC_STAT_SKILL.TOTAL] / tDstSkill[DK_REC_STAT_SKILL.COUNT])
			tDstSkill[DK_REC_STAT_SKILL.AVG_EFFECT   ] = floor(tDstSkill[DK_REC_STAT_SKILL.TOTAL_EFFECT] / tDstSkill[DK_REC_STAT_SKILL.COUNT])
			tDstSkill[DK_REC_STAT_SKILL.NZ_AVG       ] = floor(tDstSkill[DK_REC_STAT_SKILL.TOTAL] / tDstSkill[DK_REC_STAT_SKILL.NZ_COUNT])
			tDstSkill[DK_REC_STAT_SKILL.NZ_AVG_EFFECT] = floor(tDstSkill[DK_REC_STAT_SKILL.TOTAL_EFFECT] / tDstSkill[DK_REC_STAT_SKILL.NZ_COUNT])
			---------------------------------
			-- # 节： tRecord.Skill[x].Detail
			---------------------------------
			-- 合并技能详情统计（四象轮回的命中、会心...）
			for nType, tSrcSkillDetail in pairs(tSrcSkill[DK_REC_STAT_SKILL.DETAIL]) do
				local tDstSkillDetail = tDstSkill[DK_REC_STAT_SKILL.DETAIL][nType]
				if not tDstSkillDetail then
					tDstSkillDetail = {
						[DK_REC_STAT_SKILL_DETAIL.COUNT        ] =  0, -- 命中记录数量
						[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT     ] =  0, -- 非零值命中记录数量
						[DK_REC_STAT_SKILL_DETAIL.MAX          ] =  0, -- 单次命中最大值
						[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT   ] =  0, -- 单次命中最大有效值
						[DK_REC_STAT_SKILL_DETAIL.MIN          ] = -1, -- 单次命中最小值
						[DK_REC_STAT_SKILL_DETAIL.NZ_MIN       ] = -1, -- 单次非零值命中最小值
						[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT   ] = -1, -- 单次命中最小有效值
						[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT] = -1, -- 单次非零值命中最小有效值
						[DK_REC_STAT_SKILL_DETAIL.TOTAL        ] =  0, -- 所以命中总伤害
						[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT ] =  0, -- 所有命中总有效伤害
						[DK_REC_STAT_SKILL_DETAIL.AVG          ] =  0, -- 所有命中平均伤害
						[DK_REC_STAT_SKILL_DETAIL.NZ_AVG       ] =  0, -- 所有非零值命中平均伤害
						[DK_REC_STAT_SKILL_DETAIL.AVG_EFFECT   ] =  0, -- 所有命中平均有效伤害
						[DK_REC_STAT_SKILL_DETAIL.NZ_AVG_EFFECT] =  0, -- 所有非零值命中平均有效伤害
					}
					tDstSkill[DK_REC_STAT_SKILL.DETAIL][nType] = tDstSkillDetail
				end
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.COUNT        ] = tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.COUNT] + tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.COUNT]
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT     ] = tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT] + tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT]
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MAX          ] = max(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MAX], tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.MAX])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT   ] = max(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT], tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MIN          ] = Min(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MIN], tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.MIN])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_MIN       ] = Min(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_MIN], tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_MIN])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT   ] = Min(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT], tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT] = Min(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT], tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL        ] = tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL] + tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL]
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT ] = tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] + tSrcSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT]
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.AVG          ] = floor(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL] / tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.COUNT])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_AVG       ] = floor(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL] / tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.AVG_EFFECT   ] = floor(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] / tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.COUNT])
				tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_AVG_EFFECT] = floor(tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] / tDstSkillDetail[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT])
			end
			------------------------------
			-- # 节： tRecord.Skill.Target
			------------------------------
			-- 合并技能目标统计（四象轮回对江湖试炼木桩、江湖初级木桩...）
			for dwID, tSrcSkillTarget in pairs(tSrcSkill[DK_REC_STAT_SKILL.TARGET]) do
				local id = bMergeNpc and D.GetNameAusID(data, dwID) or dwID
				local tDstSkillTarget = tDstSkill[DK_REC_STAT_SKILL.TARGET][id]
				if not tDstSkillTarget then
					tDstSkillTarget = {
						[DK_REC_STAT_SKILL_TARGET.MAX         ] = 0, -- 该玩家四象轮回击中的这个玩家最大伤害
						[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT  ] = 0, -- 该玩家四象轮回击中的这个玩家最大有效伤害
						[DK_REC_STAT_SKILL_TARGET.TOTAL       ] = 0, -- 该玩家四象轮回击中的这个玩家伤害总和
						[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] = 0, -- 该玩家四象轮回击中的这个玩家有效伤害总和
						[DK_REC_STAT_SKILL_TARGET.COUNT       ] = {}, -- 该玩家四象轮回击中的这个玩家结果统计
						[DK_REC_STAT_SKILL_TARGET.NZ_COUNT    ] = {}, -- 该玩家非零值四象轮回击中的这个玩家结果统计
					}
					tDstSkill[DK_REC_STAT_SKILL.TARGET][id] = tDstSkillTarget
				end
				tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.MAX         ] = tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.MAX] + tSrcSkillTarget[DK_REC_STAT_SKILL_TARGET.MAX]
				tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT  ] = tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT] + tSrcSkillTarget[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT]
				tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.TOTAL       ] = tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.TOTAL] + tSrcSkillTarget[DK_REC_STAT_SKILL_TARGET.TOTAL]
				tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] = tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] + tSrcSkillTarget[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT]
				for k, v in pairs(tSrcSkillTarget[DK_REC_STAT_SKILL_TARGET.COUNT]) do
					tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.COUNT][k] = (tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.COUNT][k] or 0) + v
				end
				for k, v in pairs(tSrcSkillTarget[DK_REC_STAT_SKILL_TARGET.NZ_COUNT]) do
					tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][k] = (tDstSkillTarget[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][k] or 0) + v
				end
			end
		end
	end
	------------------------
	-- # 节： tRecord.Target
	------------------------
	-- 合并目标统计（江湖试炼木桩、江湖初级木桩...）
	for dwID, tSrcTarget in pairs(tSrc[DK_REC_STAT.TARGET]) do
		local id = bMergeNpc and D.GetNameAusID(data, dwID) or dwID
		local tDstTarget = tDst[DK_REC_STAT.TARGET][id]
		if not tDstTarget then
			tDstTarget = {
				[DK_REC_STAT_TARGET.COUNT        ] =  0, -- 该玩家对idTarget的技能释放次数
				[DK_REC_STAT_TARGET.NZ_COUNT     ] =  0, -- 该玩家对idTarget的非零值技能释放次数
				[DK_REC_STAT_TARGET.MAX          ] =  0, -- 该玩家对idTarget的技能最大输出量
				[DK_REC_STAT_TARGET.MAX_EFFECT   ] =  0, -- 该玩家对idTarget的技能最大有效输出量
				[DK_REC_STAT_TARGET.TOTAL        ] =  0, -- 该玩家对idTarget的技能输出量总和
				[DK_REC_STAT_TARGET.TOTAL_EFFECT ] =  0, -- 该玩家对idTarget的技能有效输出量总和
				[DK_REC_STAT_TARGET.AVG          ] =  0, -- 该玩家对idTarget的技能平均输出量
				[DK_REC_STAT_TARGET.NZ_AVG       ] =  0, -- 该玩家对idTarget的非零值技能平均输出量
				[DK_REC_STAT_TARGET.AVG_EFFECT   ] =  0, -- 该玩家对idTarget的技能平均有效输出量
				[DK_REC_STAT_TARGET.NZ_AVG_EFFECT] =  0, -- 该玩家对idTarget的非零值技能平均有效输出量
				[DK_REC_STAT_TARGET.DETAIL       ] = {}, -- 该玩家对idTarget的技能输出结果分类统计
				[DK_REC_STAT_TARGET.SKILL        ] = {}, -- 该玩家对idTarget的技能具体分别统计
			}
			tDst[DK_REC_STAT.TARGET][id] = tDstTarget
		end
		tDstTarget[DK_REC_STAT_TARGET.COUNT        ] = tDstTarget[DK_REC_STAT_TARGET.COUNT] + tSrcTarget[DK_REC_STAT_TARGET.COUNT]
		tDstTarget[DK_REC_STAT_TARGET.NZ_COUNT     ] = tDstTarget[DK_REC_STAT_TARGET.NZ_COUNT] + tSrcTarget[DK_REC_STAT_TARGET.NZ_COUNT]
		tDstTarget[DK_REC_STAT_TARGET.MAX          ] = max(tDstTarget[DK_REC_STAT_TARGET.MAX], tSrcTarget[DK_REC_STAT_TARGET.MAX])
		tDstTarget[DK_REC_STAT_TARGET.MAX_EFFECT   ] = max(tDstTarget[DK_REC_STAT_TARGET.MAX_EFFECT], tSrcTarget[DK_REC_STAT_TARGET.MAX_EFFECT])
		tDstTarget[DK_REC_STAT_TARGET.TOTAL        ] = tDstTarget[DK_REC_STAT_TARGET.TOTAL] + tSrcTarget[DK_REC_STAT_TARGET.TOTAL]
		tDstTarget[DK_REC_STAT_TARGET.TOTAL_EFFECT ] = tDstTarget[DK_REC_STAT_TARGET.TOTAL_EFFECT] + tSrcTarget[DK_REC_STAT_TARGET.TOTAL_EFFECT]
		tDstTarget[DK_REC_STAT_TARGET.AVG          ] = floor(tDstTarget[DK_REC_STAT_TARGET.TOTAL] / tDstTarget[DK_REC_STAT_TARGET.COUNT])
		tDstTarget[DK_REC_STAT_TARGET.AVG_EFFECT   ] = floor(tDstTarget[DK_REC_STAT_TARGET.TOTAL_EFFECT] / tDstTarget[DK_REC_STAT_TARGET.COUNT])
		tDstTarget[DK_REC_STAT_TARGET.NZ_AVG       ] = floor(tDstTarget[DK_REC_STAT_TARGET.TOTAL] / tDstTarget[DK_REC_STAT_TARGET.NZ_COUNT])
		tDstTarget[DK_REC_STAT_TARGET.NZ_AVG_EFFECT] = floor(tDstTarget[DK_REC_STAT_TARGET.TOTAL_EFFECT] / tDstTarget[DK_REC_STAT_TARGET.NZ_COUNT])
		----------------------------------
		-- # 节： tRecord.Target[x].Detail
		----------------------------------
		-- 合并目标技能详情统计（四象轮回的命中、会心...）
		for nType, tSrcTargetDetail in pairs(tSrcTarget[DK_REC_STAT_TARGET.DETAIL]) do
			local tDstTargetDetail = tDstTarget[DK_REC_STAT_TARGET.DETAIL][nType]
			if not tDstTargetDetail then
				tDstTargetDetail = {
					[DK_REC_STAT_TARGET_DETAIL.COUNT        ] =  0, -- 命中记录数量（假设nSkillResult是命中）
					[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT     ] =  0, -- 非零值命中记录数量
					[DK_REC_STAT_TARGET_DETAIL.MAX          ] =  0, -- 单次命中最大值
					[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT   ] =  0, -- 单次命中最大有效值
					[DK_REC_STAT_TARGET_DETAIL.MIN          ] = -1, -- 单次命中最小值
					[DK_REC_STAT_TARGET_DETAIL.NZ_MIN       ] = -1, -- 单次非零值命中最小值
					[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT   ] = -1, -- 单次命中最小有效值
					[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT] = -1, -- 单次非零值命中最小有效值
					[DK_REC_STAT_TARGET_DETAIL.TOTAL        ] =  0, -- 所以命中总伤害
					[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT ] =  0, -- 所有命中总有效伤害
					[DK_REC_STAT_TARGET_DETAIL.AVG          ] =  0, -- 所有命中平均伤害
					[DK_REC_STAT_TARGET_DETAIL.NZ_AVG       ] =  0, -- 所有非零值命中平均伤害
					[DK_REC_STAT_TARGET_DETAIL.AVG_EFFECT   ] =  0, -- 所有命中平均有效伤害
					[DK_REC_STAT_TARGET_DETAIL.NZ_AVG_EFFECT] =  0, -- 所有非零值命中平均有效伤害
				}
				tDstTarget[DK_REC_STAT_TARGET.DETAIL][nType] = tDstTargetDetail
			end
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.COUNT        ] = tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.COUNT] + tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.COUNT]
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT     ] = tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT] + tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT]
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MAX          ] = max(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MAX], tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.MAX])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT   ] = max(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT], tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MIN          ] = Min(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MIN], tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.MIN])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_MIN       ] = Min(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_MIN], tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_MIN])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT   ] = Min(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT], tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT] = Min(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT], tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL        ] = tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL] + tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL]
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT ] = tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] + tSrcTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT]
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.AVG          ] = floor(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL] / tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.COUNT])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_AVG       ] = floor(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL] / tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.AVG_EFFECT   ] = floor(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] / tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.COUNT])
			tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_AVG_EFFECT] = floor(tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] / tDstTargetDetail[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT])
		end
		---------------------------------
		-- # 节： tRecord.Target[x].Skill
		---------------------------------
		-- 合并目标技能统计（江湖试炼木桩被四象轮回、两仪化形...）
		for szEffectID, tSrcTargetSkill in pairs(tSrcTarget[DK_REC_STAT_TARGET.SKILL]) do
			if not bHideAnonymous or not select(2, D.GetEffectInfoAusID(data, szEffectID)) then
				local id = bMergeEffect
					and D.GetEffectNameAusID(data, szChannel, szEffectID)
					or szEffectID
				local tDstTargetSkill = tDstTarget[DK_REC_STAT_TARGET.SKILL][id]
				if not tDstTargetSkill then
					tDstTargetSkill = {
						[DK_REC_STAT_TARGET_SKILL.MAX         ] = 0, -- 该玩家击中这个玩家的四象轮回最大伤害
						[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT  ] = 0, -- 该玩家击中这个玩家的四象轮回最大有效伤害
						[DK_REC_STAT_TARGET_SKILL.TOTAL       ] = 0, -- 该玩家击中这个玩家的四象轮回伤害总和
						[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] = 0, -- 该玩家击中这个玩家的四象轮回有效伤害总和
						[DK_REC_STAT_TARGET_SKILL.COUNT       ] = {}, -- 该玩家击中这个玩家的四象轮回结果统计
						[DK_REC_STAT_TARGET_SKILL.NZ_COUNT    ] = {}, -- 该玩家非零值击中这个玩家的四象轮回结果统计
					}
					tDstTarget[DK_REC_STAT_TARGET.SKILL][id] = tDstTargetSkill
				end
				tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.MAX         ] = max(tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.MAX], tSrcTargetSkill[DK_REC_STAT_TARGET_SKILL.MAX])
				tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT  ] = max(tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT], tSrcTargetSkill[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT])
				tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.TOTAL       ] = tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.TOTAL] + tSrcTargetSkill[DK_REC_STAT_TARGET_SKILL.TOTAL]
				tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] = tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] + tSrcTargetSkill[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT]
				for k, v in pairs(tSrcTargetSkill[DK_REC_STAT_TARGET_SKILL.COUNT]) do
					tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.COUNT][k] = (tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.COUNT][k] or 0) + v
				end
				for k, v in pairs(tSrcTargetSkill[DK_REC_STAT_TARGET_SKILL.NZ_COUNT]) do
					tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][k] = (tDstTargetSkill[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][k] or 0) + v
				end
			end
		end
	end
end

function D.GetMergeTargetData(data, szChannel, id, bMergeNpc, bMergeEffect, bHideAnonymous)
	if not bMergeNpc and not bMergeEffect and not bHideAnonymous then
		return data[szChannel][DK_REC.STAT][id]
	end
	local tData = nil
	for dwID, tSrcData in pairs(data[szChannel][DK_REC.STAT]) do
		if dwID == id or D.GetNameAusID(data, dwID) == id then
			if not tData then
				tData = {
					[DK_REC_STAT.TOTAL       ] = 0,
					[DK_REC_STAT.TOTAL_EFFECT] = 0,
					[DK_REC_STAT.TARGET      ] = {},
					[DK_REC_STAT.SKILL       ] = {},
					[DK_REC_STAT.DETAIL      ] = {},
				}
			end
			D.MergeTargetData(tData, tSrcData, data, szChannel, bMergeNpc, bMergeEffect, bHideAnonymous)
		end
	end
	return tData
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				GetHistoryFiles = D.GetHistoryFiles,
				Get = D.Get,
				Del = D.Del,
				GeneAwayTime = D.GeneAwayTime,
				GeneFightTime = D.GeneFightTime,
				GetNameAusID = D.GetNameAusID,
				GetForceAusID = D.GetForceAusID,
				GetEffectInfoAusID = D.GetEffectInfoAusID,
				GetEffectNameAusID = D.GetEffectNameAusID,
				Flush = D.Flush,
				GetMergeTargetData = D.GetMergeTargetData,
				EVERYTHING_TYPE = EVERYTHING_TYPE,
				DK = DK,
				DK_REC = DK_REC,
				DK_REC_SNAPSHOT = DK_REC_SNAPSHOT,
				DK_REC_SNAPSHOT_STAT = DK_REC_SNAPSHOT_STAT,
				DK_REC_STAT = DK_REC_STAT,
				DK_REC_STAT_DETAIL = DK_REC_STAT_DETAIL,
				DK_REC_STAT_SKILL = DK_REC_STAT_SKILL,
				DK_REC_STAT_SKILL_DETAIL = DK_REC_STAT_SKILL_DETAIL,
				DK_REC_STAT_SKILL_TARGET = DK_REC_STAT_SKILL_TARGET,
				DK_REC_STAT_TARGET = DK_REC_STAT_TARGET,
				DK_REC_STAT_TARGET_DETAIL = DK_REC_STAT_TARGET_DETAIL,
				DK_REC_STAT_TARGET_SKILL = DK_REC_STAT_TARGET_SKILL,
			},
		},
		{
			fields = {
				bEnable            = true,
				bSaveHistoryOnExit = true,
				bSaveHistoryOnExFi = true,
				nMaxHistory        = true,
				nMinFightTime      = true,
				bRecEverything     = true,
				bSaveEverything    = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable            = true,
				bSaveHistoryOnExit = true,
				bSaveHistoryOnExFi = true,
				nMaxHistory        = true,
				nMinFightTime      = true,
				bRecEverything     = true,
				bSaveEverything    = true,
			},
			triggers = {
				bEnable = function()
					D.SaveData()
					MY_Recount_UI.CheckOpen()
				end,
				bSaveHistoryOnExit = D.SaveData,
				bSaveHistoryOnExFi = D.SaveData,
				nMaxHistory        = D.SaveData,
				nMinFightTime      = D.SaveData,
				bRecEverything     = D.SaveData,
				bSaveEverything    = D.SaveData,
			},
			root = O,
		},
	},
}
MY_Recount_DS = LIB.GeneGlobalNS(settings)
end
