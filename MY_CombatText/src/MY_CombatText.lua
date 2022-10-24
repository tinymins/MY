--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗浮动文字
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_CombatText/MY_CombatText'
local PLUGIN_NAME = 'MY_CombatText'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_CombatText'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^14.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SKILL_RESULT_TYPE = SKILL_RESULT_TYPE
local GetSkill, Random = GetSkill, Random
local Table_GetBuffName, Table_GetSkillName, Table_BuffIsVisible = Table_GetBuffName, Table_GetSkillName, Table_BuffIsVisible

-- 战斗浮动文字设计思路
--[[
	停留时间：使用（总帧数 * 每帧时间）来决定总停留时间，
	alpha：   使用帧数来决定fadein和fadeout。
	排序：    顶部使用简易见缝插针，分配空闲轨迹，最大程度上保证性能和浮动数值清晰。
	坐标轨迹：使用关键帧形式，一共32关键帧，部分类型有延长帧。
	出现：    对出现做1帧的延迟处理，即1帧出现5次伤害则分5帧依次出现。
	-------------------------------------------------------------------------------
	初始坐标类型：分为 顶部 左 右 左下 右下 中心
	顶部：
		Y轴轨迹数 以 math.floor(3.5 / UI缩放) 决定，其初始Y轴高度不同。
		在轨迹全部被占用后会随机分摊到屏幕顶部左右两边。
	其他类型：使用轨迹合并16-32帧，后来的文本会顶走前面的文本，从而跳过这部分停留的帧数。
]]

local COMBAT_TEXT_INIFILE        = X.PACKET_INFO.ROOT .. 'MY_CombatText/ui/MY_CombatText_Render.ini'
local COMBAT_TEXT_CONFIG         = X.FormatPath({'config/CombatText.jx3dat', X.PATH_TYPE.GLOBAL})
local COMBAT_TEXT_PLAYERID       = 0
local COMBAT_TEXT_TOTAL          = 32
local COMBAT_TEXT_UI_SCALE       = 1
local COMBAT_TEXT_TRAJECTORY     = 4   -- 顶部Y轴轨迹数量 根据缩放大小变化 0.8就是5条了 屏幕小更多
local COMBAT_TEXT_MAX_COUNT      = 100 -- 最多同屏显示100个 再多部分机器吃不消了
local COMBAT_TEXT_CRITICAL = { -- 需要会心跳帧的伤害类型
	[SKILL_RESULT_TYPE.PHYSICS_DAMAGE]       = true,
	[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE]   = true,
	[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] = true,
	[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE]   = true,
	[SKILL_RESULT_TYPE.POISON_DAMAGE]        = true,
	[SKILL_RESULT_TYPE.THERAPY]              = true,
	[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]    = true,
	[SKILL_RESULT_TYPE.STEAL_LIFE]           = true,
	['EXP']                                  = true,
	['CRITICAL_MSG']                         = true,
}
local COMBAT_TEXT_IGNORE_TYPE = {}
local COMBAT_TEXT_IGNORE = {}
local COMBAT_TEXT_EVENT  = { 'COMMON_HEALTH_TEXT', 'SKILL_EFFECT_TEXT', 'SKILL_MISS', 'SKILL_DODGE', 'SKILL_BUFF', 'BUFF_IMMUNITY' }
local COMBAT_TEXT_OFFICIAL_EVENT = { 'SKILL_EFFECT_TEXT', 'COMMON_HEALTH_TEXT', 'SKILL_MISS', 'SKILL_DODGE', 'SKILL_BUFF', 'BUFF_IMMUNITY', 'ON_EXP_LOG', 'SYS_MSG', 'FIGHT_HINT' }
local COMBAT_TEXT_STRING = { -- 需要变成特定字符串的伤害类型
	[SKILL_RESULT_TYPE.SHIELD_DAMAGE ] = g_tStrings.STR_MSG_ABSORB,
	[SKILL_RESULT_TYPE.ABSORB_DAMAGE ] = g_tStrings.STR_MSG_ABSORB,
	[SKILL_RESULT_TYPE.PARRY_DAMAGE  ] = g_tStrings.STR_MSG_COUNTERACT,
	[SKILL_RESULT_TYPE.INSIGHT_DAMAGE] = g_tStrings.STR_MSG_INSIGHT,
}
local COMBAT_TEXT_COLOR = { --不需要修改的内定颜色
	YELLOW = { 255, 255, 0   },
	RED    = X.ENVIRONMENT.GAME_PROVIDER == 'remote'
		and { 253, 86, 86 }
		or { 255, 0, 0 },
	PURPLE = { 255, 0,   255 },
	WHITE  = { 255, 255, 255 }
}

local COMBAT_TEXT_STYLES = {
	[0] = {
		2, 4.5, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	[1] = {
		2, 4.5, 4, 3, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	[2] = {
		1, 2, 3, 4.5, 3, 3, 3, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	[3] = {
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	}
}

local COMBAT_TEXT_SCALE = { -- 各种伤害的缩放帧数 一共32帧
	CRITICAL = { -- 会心
		2, 4.5, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	NORMAL = { -- 普通伤害
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
	},
}

local COMBAT_TEXT_POINT = {
	TOP = { -- 伤害 往上的 分四组 普通 慢 慢 块~~
		0,   6,   12,  18,  24,  30,  36,  42,
		45,  48,  51,  54,  57,  60,  63,  66,
		69,  72,  75,  78,  81,  84,  87,  90,
		100, 110, 120, 130, 140, 150, 160, 170,
	},
	RIGHT = { -- 从左往右的
		8,   16,  24,  32,  40,  48,  56,  64,
		72,  80,  88,  96,  104, 112, 120, 128,
		136, 136, 136, 136, 136, 136, 136, 136,
		136, 136, 136, 136, 136, 136, 136, 136,
		139, 142, 145, 148, 151, 154, 157, 160,
		163, 166, 169, 172, 175, 178, 181, 184,
	},
	LEFT = { -- 从右到左
		8,   16,  24,  32,  40,  48,  56,  64,
		72,  80,  88,  96,  104, 112, 120, 128,
		136, 136, 136, 136, 136, 136, 136, 136,
		136, 136, 136, 136, 136, 136, 136, 136,
		139, 142, 145, 148, 151, 154, 157, 160,
		163, 166, 169, 172, 175, 178, 181, 184,
	},
	BOTTOM_LEFT = { -- 左下角
		5,   10,  15,  20,  25,  30,  35,  40,
		45,  50,  55,  60,  65,  70,  75,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		82,  84,  86,  88,  90,  92,  94,  96,
		98,  100, 102, 104, 106, 108, 110, 112,
	},
	BOTTOM_RIGHT = {
		5,   10,  15,  20,  25,  30,  35,  40,
		45,  50,  55,  60,  65,  70,  75,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		82,  84,  86,  88,  90,  92,  94,  96,
		98,  100, 102, 104, 106, 108, 110, 112,
	},
}

local COMBAT_TEXT_TYPE_COLOR = X.KvpToObject({
	{'DAMAGE'                              , X.ENVIRONMENT.GAME_PROVIDER == 'remote' and { 253, 86, 86 } or { 255, 0, 0 }}, -- 自己受到的伤害
	{SKILL_RESULT_TYPE.THERAPY             , { 0,   255, 0   }}, -- 治疗
	{SKILL_RESULT_TYPE.PHYSICS_DAMAGE      , { 255, 255, 255 }}, -- 外功
	{SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE  , { 255, 128, 128 }}, -- 阳
	{SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE, { 255, 255, 0   }}, -- 混元
	{SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE  , { 12,  242, 255 }}, -- 阴
	{SKILL_RESULT_TYPE.POISON_DAMAGE       , { 128, 255, 128 }}, -- 有毒啊
	{SKILL_RESULT_TYPE.REFLECTIED_DAMAGE   , { 255, 128, 128 }}, -- 反弹？？
	{SKILL_RESULT_TYPE.SPIRIT              , { 160,   0, 160 }}, -- 精神
	{SKILL_RESULT_TYPE.STAYING_POWER       , { 255, 169,   0 }}, -- 耐力
})

local COMBAT_TEXT_TYPE_CLASS = X.KvpToObject({
	{SKILL_RESULT_TYPE.STEAL_LIFE       , 'THERAPY'},
	{SKILL_RESULT_TYPE.EFFECTIVE_THERAPY, 'THERAPY'},
	{SKILL_RESULT_TYPE.THERAPY          , 'THERAPY'},
})

local COMBAT_TEXT_LEAVE  = {}
local COMBAT_TEXT_FREE   = {}
local COMBAT_TEXT_SHADOW = {}
local COMBAT_TEXT_QUEUE  = {}
local COMBAT_TEXT_CACHE  = { -- buff的名字cache
	BUFF   = {},
	DEBUFF = {},
}
local CombatText = {}

local O = X.CreateUserSettingsModule('MY_CombatText', _L['System'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bRender = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nStyle = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nMaxAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 240,
	},
	nTime = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 40,
	},
	nFadeIn = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 4,
	},
	nFadeOut = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 8,
	},
	nFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 19,
	},
	bImmunity = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bCritical = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tCriticalC = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 255, 255, 255 },
	},
	tCriticalH = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 0, 255, 0 },
	},
	tCriticalB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = X.ENVIRONMENT.GAME_PROVIDER == 'remote' and { 253, 86, 86 } or { 255, 0, 0 },
	},
	-- $name 名字 $sn   技能名 $crit 会心 $val  数值
	szSkill = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.String,
		xDefaultValue = '$sn' .. g_tStrings.STR_COLON .. '$crit $val',
	},
	szTherapy = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.String,
		xDefaultValue = '$sn' .. g_tStrings.STR_COLON .. '$crit +$val',
	},
	szDamage = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.String,
		xDefaultValue = '$sn' .. g_tStrings.STR_COLON .. '$crit -$val',
	},
	bCasterNotI = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSnShorten2 = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTherEffOnly = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	col = { -- 颜色呗
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Map(X.Schema.OneOf(X.Schema.String, X.Schema.Number), X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number)),
		xDefaultValue = {},
	},
})
local D = {
	col = setmetatable({}, { __index = function(_, k) return O.col[k] or COMBAT_TEXT_TYPE_COLOR[k] or COMBAT_TEXT_COLOR.WHITE end })
}

local function IsEnabled()
	return D.bReady and O.bEnable
end

function D.HideOfficialCombat()
	local frame = Station.Lookup('Lowest/CombatText')
	if frame then
		for _, v in ipairs(COMBAT_TEXT_OFFICIAL_EVENT) do
			frame:UnRegisterEvent(v)
		end
	end
end

function D.ShowOfficialCombat()
	local frame = Station.Lookup('Lowest/CombatText')
	if frame then
		for _, v in ipairs(COMBAT_TEXT_OFFICIAL_EVENT) do
			frame:UnRegisterEvent(v)
			frame:RegisterEvent(v)
		end
	end
end

function D.OnFrameCreate()
	for k, v in ipairs(COMBAT_TEXT_EVENT) do
		this:RegisterEvent(v)
	end
	this:ShowWhenUIHide()
	this:RegisterEvent('SYS_MSG')
	this:RegisterEvent('FIGHT_HINT')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('NPC_ENTER_SCENE')
	this:RegisterEvent('ON_EXP_LOG')
	this:RegisterEvent('COINSHOP_ON_OPEN')
	this:RegisterEvent('COINSHOP_ON_CLOSE')
	this:RegisterEvent('ENTER_STORY_MODE')
	this:RegisterEvent('LEAVE_STORY_MODE')
	CombatText.handle = this:Lookup('', '')
	CombatText.FreeQueue()
	CombatText.UpdateTrajectoryCount()
	X.BreatheCall('COMBAT_TEXT_CACHE', 1000 * 60 * 5, function()
		local count = 0
		for k, v in pairs(COMBAT_TEXT_LEAVE) do
			count = count + 1
		end
		if count > 10000 then
			COMBAT_TEXT_LEAVE = {}
			Log('[MY] CombatText cache beyond 10000 !!!')
		end
	end)
end

-- for i=1,5 do FireUIEvent('SKILL_EFFECT_TEXT',UI_GetClientPlayerID(),1073741860,true,5,1111,111,1)end
-- for i=1,5 do FireUIEvent('SKILL_EFFECT_TEXT',UI_GetClientPlayerID(),1073741860,false,5,1111,111,1)end
-- for i=1, 5 do FireEvent('SKILL_BUFF', UI_GetClientPlayerID(), true, 103, 1) end
-- FireUIEvent('SKILL_MISS', UI_GetClientPlayerID(), UI_GetClientPlayerID())
-- FireUIEvent('SYS_MSG', 'UI_OME_EXP_LOG', UI_GetClientPlayerID(), UI_GetClientPlayerID())
function D.OnEvent(szEvent)
	if szEvent == 'FIGHT_HINT' then -- 进出战斗文字
		if arg0 then
			OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.STR_MSG_ENTER_FIGHT)
		else
			OutputMessage('MSG_ANNOUNCE_YELLOW', g_tStrings.STR_MSG_LEAVE_FIGHT)
		end
	elseif szEvent == 'COMMON_HEALTH_TEXT' then
		if arg1 ~= 0 then
			CombatText.OnCommonHealth(arg0, arg1)
		end
	elseif szEvent == 'SKILL_EFFECT_TEXT' then
		-- 贯体治疗有效值 SKILL_EFFECT_TEXT 无法显示，于是让所有有效治疗走 SYS_MSG -> UI_OME_SKILL_EFFECT_LOG 通道
		if arg3 == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY then
			return
		end
		CombatText.OnSkillText(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	elseif szEvent == 'SKILL_BUFF' then
		CombatText.OnSkillBuff(arg0, arg1, arg2, arg3)
	elseif szEvent == 'BUFF_IMMUNITY' then
		if not O.bImmunity and arg1 == COMBAT_TEXT_PLAYERID then
			CombatText.OnBuffImmunity(arg0)
		end
	elseif szEvent == 'SKILL_MISS' then
		if arg0 == COMBAT_TEXT_PLAYERID or arg1 == COMBAT_TEXT_PLAYERID then
			CombatText.OnSkillMiss(arg1)
		end
	elseif szEvent == 'UI_SCALED' then
		CombatText.UpdateTrajectoryCount()
	elseif szEvent == 'SKILL_DODGE' then
		if arg0 == COMBAT_TEXT_PLAYERID or arg1 == COMBAT_TEXT_PLAYERID then
			CombatText.OnSkillDodge(arg1)
		end
	elseif szEvent == 'NPC_ENTER_SCENE' then
		COMBAT_TEXT_LEAVE[arg0] = nil
	elseif szEvent == 'ON_EXP_LOG' then
		CombatText.OnExpLog(arg0, arg1)
	elseif szEvent == 'SYS_MSG' then
		if arg0 == 'UI_OME_DEATH_NOTIFY' then
			if not IsPlayer(arg1) then
				COMBAT_TEXT_LEAVE[arg1] = true
			end
		elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
			-- 技能最终产生的效果（生命值的变化）；
			-- (arg1)dwCaster：施放者 (arg2)dwTarget：目标 (arg3)bReact：是否为反击 (arg4)nType：Effect类型 (arg5)dwID:Effect的ID
			-- (arg6)dwLevel：Effect的等级 (arg7)bCriticalStrike：是否会心 (arg8)nCount：tResultCount数据表中元素个数 (arg9)tResultCount：数值集合
			-- 贯体治疗有效值 SKILL_EFFECT_TEXT 无法显示，于是让所有有效治疗走 SYS_MSG -> UI_OME_SKILL_EFFECT_LOG 通道
			if arg9[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] then
				CombatText.OnSkillText(arg1, arg2, arg7, SKILL_RESULT_TYPE.EFFECTIVE_THERAPY, arg9[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY], arg5, arg6, arg4)
			end
			-- dwCasterID, dwTargetID, bCriticalStrike, nType, nValue, dwSkillID, dwSkillLevel, nEffectType
		end
	elseif szEvent == 'LOADING_END' then
		this:Show()
		CombatText.FreeQueue()
	elseif szEvent == 'COINSHOP_ON_OPEN' or szEvent == 'ENTER_STORY_MODE' then
		this:HideWhenUIHide()
	elseif szEvent == 'COINSHOP_ON_CLOSE' or szEvent == 'LEAVE_STORY_MODE' then
		this:ShowWhenUIHide()
	end
end

function CombatText.FreeQueue()
	COMBAT_TEXT_LEAVE  = {}
	COMBAT_TEXT_FREE   = {}
	COMBAT_TEXT_SHADOW = {}
	COMBAT_TEXT_CACHE  = {
		BUFF   = {},
		DEBUFF = {},
	}
	CombatText.handle:Clear()
	COMBAT_TEXT_QUEUE = {
		TOP          = {},
		LEFT         = {},
		RIGHT        = {},
		BOTTOM_LEFT  = {},
		BOTTOM_RIGHT = {},
	}
	setmetatable(COMBAT_TEXT_QUEUE, { __index = function(me) return me['TOP'] end, __newindex = function(me) return me['TOP'] end })
end

function CombatText.OnFrameRender()
	if not D.bReady then
		return
	end
	local nTime     = GetTime()
	local nFadeIn   = O.nFadeIn
	local nFadeOut  = O.nFadeOut
	local nMaxAlpha = O.nMaxAlpha
	local nFont     = O.nFont
	local nDelay    = O.nTime
	local g_fScale  = O.fScale
	for k, v in pairs(COMBAT_TEXT_SHADOW) do
		local nFrame = (nTime - v.nTime) / nDelay + 1 -- 每一帧是多少毫秒 这里越小 动画越快
		local nBefore = math.floor(nFrame)
		local nAfter  = math.ceil(nFrame)
		local fDiff   = nFrame - nBefore
		local nTotal  = COMBAT_TEXT_POINT[v.szPoint] and #COMBAT_TEXT_POINT[v.szPoint] or COMBAT_TEXT_TOTAL
		k:ClearTriangleFanPoint()
		if nBefore < nTotal then
			local nTop   = 0
			local nLeft  = 0
			local nAlpha = nMaxAlpha
			local fScale = 1
			local bTop   = true
			-- alpha
			if nFrame < nFadeIn then
				nAlpha = nMaxAlpha * nFrame / nFadeIn
			elseif nFrame > nTotal - nFadeOut then
				nAlpha = nMaxAlpha * (nTotal - nFrame) / nFadeOut
			end
			-- 坐标
			if v.szPoint == 'TOP' or v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then
				local tTop = COMBAT_TEXT_POINT[v.szPoint]
				nTop = (-60 * g_fScale) + v.nSort * (-40 * g_fScale) - (tTop[nBefore] + (tTop[nAfter] - tTop[nBefore]) * fDiff)
				if v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then
					if v.szPoint == 'TOP_LEFT' then
						nLeft = -250
					elseif v.szPoint == 'TOP_RIGHT' then
						nLeft = 250
					end
					nTop = nTop -50
				end
			elseif v.szPoint == 'LEFT' then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				nLeft = -60 - (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				nAlpha = nAlpha * 0.85
			elseif v.szPoint == 'RIGHT' then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				nLeft = 60 + (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				nAlpha = nAlpha * 0.9
			elseif v.szPoint == 'BOTTOM_LEFT' or v.szPoint == 'BOTTOM_RIGHT' then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				local tTop = COMBAT_TEXT_POINT[v.szPoint]
				if v.szPoint == 'BOTTOM_LEFT' then
					nLeft = -130 - (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				else
					nLeft = 130 + (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				end
				nTop = 50 + tTop[nBefore] + (tTop[nAfter] - tTop[nBefore]) * fDiff
				fScale = 1.5
			end
			-- 缩放
			if COMBAT_TEXT_CRITICAL[v.nType] then
				local tScale  = v.bCriticalStrike and COMBAT_TEXT_SCALE.CRITICAL or COMBAT_TEXT_SCALE.NORMAL
				fScale  = tScale[nBefore]
				if tScale[nBefore] > tScale[nAfter] then
					fScale = fScale - ((tScale[nBefore] - tScale[nAfter]) * fDiff)
				elseif tScale[nBefore] < tScale[nAfter] then
					fScale = fScale + ((tScale[nAfter] - tScale[nBefore]) * fDiff)
				end
				if COMBAT_TEXT_TYPE_CLASS[v.nType] == 'THERAPY' then -- 治疗缩小
					if v.bCriticalStrike then
						fScale = math.max(fScale * 0.7, COMBAT_TEXT_SCALE.NORMAL[#COMBAT_TEXT_SCALE.NORMAL] + 0.1)
					end
					if v.dwTargetID == COMBAT_TEXT_PLAYERID then
						fScale = fScale * 0.95
					end
				elseif v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then -- 左右缩小
					fScale = fScale * 0.85
				end
				if v.szPoint == 'TOP' or v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then
					fScale = fScale * g_fScale
				end
			end
			-- draw
			local r, g, b = unpack(v.col or {255, 255, 255})
			if not COMBAT_TEXT_LEAVE[v.dwTargetID] or not v.object or not v.tPoint[1] then
				k:AppendCharacterID(v.dwTargetID, bTop, r, g, b, nAlpha, { 0, 0, 0, nLeft * COMBAT_TEXT_UI_SCALE, nTop * COMBAT_TEXT_UI_SCALE}, nFont, v.szText, 1, fScale)
				if v.object and v.object.nX then
					v.tPoint = { v.object.nX, v.object.nY, v.object.nZ }
				else -- DEBUG  JX3Client   [Script index] pointer invalid. call stack: 暂无完美解决方案 都会造成内存泄露
					if not COMBAT_TEXT_LEAVE[v.dwTargetID] then
						COMBAT_TEXT_LEAVE[v.dwTargetID] = true
					end
				end
			else
				local x, y, z = unpack(v.tPoint)
				k:AppendTriangleFan3DPoint(x, y, z, r, g, b, nAlpha, { 0, 1.65 * 64, 0, nLeft * COMBAT_TEXT_UI_SCALE, nTop * COMBAT_TEXT_UI_SCALE}, nFont, v.szText, 1, fScale)
			end
			-- 合并伤害 后顶前
			if not v.bJump and v.szPoint ~= 'TOP' and nFrame >= 16 and nFrame <= 32 then
				for kk, vv in pairs(COMBAT_TEXT_SHADOW) do
					if k ~= kk
						and vv.nFrame <= 32
						and v.szPoint == vv.szPoint
						and not vv.bJump
						and v.nTime > vv.nTime
					then
						vv.bJump = true
					end
				end
			end
			if v.bJump and v.szPoint ~= 'TOP' and nFrame >= 16 and nFrame <= 32 then
				v.nTime = v.nTime - (32 - nFrame) * nDelay
			else
				v.nFrame = nFrame
			end
		else
			if v.szPoint == 'RIGHT' and v.dwTargetID == COMBAT_TEXT_PLAYERID then
				local tCache = v.col == COMBAT_TEXT_COLOR.RED and COMBAT_TEXT_CACHE.DEBUFF or COMBAT_TEXT_CACHE.BUFF
				if tCache[v.szText] then
					tCache[v.szText] = nil
				end
			end
			k.free = true
			COMBAT_TEXT_SHADOW[k] = nil
		end
	end
	for k, v in pairs(COMBAT_TEXT_QUEUE) do
		for kk, vv in pairs(v) do
			if #vv > 0 then
				local dat = table.remove(vv, 1)
				if dat.dat.szPoint == 'TOP' then
					local nSort, szPoint = CombatText.GetTrajectory(dat.dat.dwTargetID)
					dat.dat.nSort   = nSort
					dat.dat.szPoint = szPoint
				end
				dat.dat.nTime = GetTime()
				COMBAT_TEXT_SHADOW[dat.shadow] = dat.dat
			else
				COMBAT_TEXT_QUEUE[k][kk] = nil
			end
		end
	end
end

D.OnFrameBreathe = CombatText.OnFrameRender
D.OnFrameRender  = CombatText.OnFrameRender

function CombatText.UpdateTrajectoryCount()
	if D.bReady then
		COMBAT_TEXT_UI_SCALE   = Station.GetUIScale()
		COMBAT_TEXT_TRAJECTORY = O.fScale < 1.5
			and math.floor(3.5 / COMBAT_TEXT_UI_SCALE / O.fScale)
			or math.floor(3.5 / COMBAT_TEXT_UI_SCALE)
	end
end


local function TrajectorySort(a, b)
	if a.nCount == b.nCount then
		return a.nSort < b.nSort
	else
		return a.nCount < b.nCount
	end
end

-- 最大程度上使用见缝插针效果 缺少缓存 待补充
function CombatText.GetTrajectory(dwTargetID, bCriticalStrike)
	local tSort = {}
	local fRange = 1 / COMBAT_TEXT_TRAJECTORY
	for i = 1, COMBAT_TEXT_TRAJECTORY do
		tSort[i] = { nSort = i, nCount = 0, fRange = i * fRange }
	end
	for k, v in pairs(COMBAT_TEXT_SHADOW) do
		if v.dwTargetID == dwTargetID
			and v.szPoint == 'TOP'
			and v.nFrame < 15
		then
			local fSort = (COMBAT_TEXT_POINT.TOP[math.floor(v.nFrame) + 1] + v.nSort * fRange * COMBAT_TEXT_POINT.TOP[COMBAT_TEXT_TOTAL]) / COMBAT_TEXT_POINT.TOP[COMBAT_TEXT_TOTAL]
			for i = 1, COMBAT_TEXT_TRAJECTORY do
				if fSort < tSort[i].fRange then
					tSort[i].nCount = tSort[i].nCount + 1
					break
				end
			end
		end
	end
	table.sort(tSort, TrajectorySort)
	local nSort = tSort[1].nSort - 1
	local szPoint = 'TOP'
	if tSort[1].nCount == 1 then
		szPoint = Random(2) == 1 and 'TOP_LEFT' or 'TOP_RIGHT'
		nSort = 0
	end
	return nSort, szPoint
end

function CombatText.CreateText(shadow, dwTargetID, szText, szPoint, nType, bCriticalStrike, col)
	local object, tPoint
	local bIsPlayer = IsPlayer(dwTargetID)
	if dwTargetID ~= COMBAT_TEXT_PLAYERID then
		object = bIsPlayer and GetPlayer(dwTargetID) or GetNpc(dwTargetID)
		if object and object.nX then
			tPoint = { object.nX, object.nY, object.nZ }
		end
	end
	local dat = {
		szPoint         = szPoint,
		nSort           = 0,
		dwTargetID      = dwTargetID,
		szText          = szText,
		nType           = nType,
		nFrame          = 0,
		bCriticalStrike = bCriticalStrike,
		col             = col,
		object          = object,
		tPoint          = tPoint,
	}
	if dat.bCriticalStrike then
		if szPoint == 'TOP' then
			local nSort, point = CombatText.GetTrajectory(dat.dwTargetID, true)
			dat.nSort = nSort
			dat.szPoint = point
		end
		dat.nTime = GetTime()
		COMBAT_TEXT_SHADOW[shadow] = dat
	else
		COMBAT_TEXT_QUEUE[szPoint][dwTargetID] = COMBAT_TEXT_QUEUE[szPoint][dwTargetID] or {}
		table.insert(COMBAT_TEXT_QUEUE[szPoint][dwTargetID], { shadow = shadow, dat = dat })
	end
end

function CombatText.OnSkillText(dwCasterID, dwTargetID, bCriticalStrike, nType, nValue, dwSkillID, dwSkillLevel, nEffectType)
	-- 过滤 有效治疗 有效伤害 汲取内力 化解治疗
	if nType == SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE
--	or nType == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY
	or (nType == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY and not O.bTherEffOnly)
	or (nType == SKILL_RESULT_TYPE.THERAPY and O.bTherEffOnly)
	or nType == SKILL_RESULT_TYPE.TRANSFER_MANA
	or nType == SKILL_RESULT_TYPE.ABSORB_THERAPY
	or nType == SKILL_RESULT_TYPE.TRANSFER_LIFE
	then
		return
	end
	if (dwCasterID == COMBAT_TEXT_PLAYERID and (COMBAT_TEXT_IGNORE[dwSkillID] or COMBAT_TEXT_IGNORE_TYPE[nType]))
		or nType == SKILL_RESULT_TYPE.STEAL_LIFE and COMBAT_TEXT_IGNORE_TYPE[nType]
	then
		return
	end
	-- 过滤无效治疗
	if COMBAT_TEXT_TYPE_CLASS[nType] == 'THERAPY' and nValue == 0 then
		return
	end
	local bIsPlayer = IsPlayer(dwCasterID)
	local p = bIsPlayer and GetPlayer(dwCasterID) or GetNpc(dwCasterID)
	local employer, dwEmployerID
	if not bIsPlayer and p then
		dwEmployerID = p.dwEmployer
		if dwEmployerID ~= 0 then -- NPC要算归属圈
			employer = GetPlayer(dwEmployerID)
		end
	end
	if dwCasterID ~= COMBAT_TEXT_PLAYERID and dwTargetID ~= COMBAT_TEXT_PLAYERID and dwEmployerID ~= COMBAT_TEXT_PLAYERID then -- 和我没什么卵关系
		return
	end
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end

	local szSkillName, szText, szReplaceText, bStaticSign
	-- replace text / point / color
	local szPoint = 'TOP'
	local col     = D.col[nType]
	-- skill type effect by class and presets
	if COMBAT_TEXT_STRING[nType] then -- 需要变成特定字符串的伤害类型
		szText = COMBAT_TEXT_STRING[nType]
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'LEFT'
			col = COMBAT_TEXT_COLOR.YELLOW
		end
	elseif COMBAT_TEXT_TYPE_CLASS[nType] == 'THERAPY' then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_RIGHT'
		end
		if bCriticalStrike and O.bCritical then
			col = O.tCriticalH
		end
		szReplaceText = O.szTherapy
	else
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_LEFT'
			szReplaceText = O.szDamage
		end
		szReplaceText = O.szSkill
	end
	-- specific skill type overwrite
	if nType == SKILL_RESULT_TYPE.STEAL_LIFE then -- 吸血技能偷取避免重复获取 浪费性能
		szSkillName = g_tStrings.SKILL_STEAL_LIFE
	elseif nType == SKILL_RESULT_TYPE.SPIRIT then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_RIGHT'
		end
		szReplaceText = O.szSkill
		szSkillName = g_tStrings.SKILL_SPIRIT
		bStaticSign = true
	elseif nType == SKILL_RESULT_TYPE.STAYING_POWER then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_RIGHT'
		end
		szReplaceText = O.szSkill
		szSkillName = g_tStrings.SKILL_STAYING_POWER
		bStaticSign = true
	end
	-- skill name fallback
	if not szSkillName then
		szSkillName = nEffectType == SKILL_EFFECT_TYPE.BUFF
			and Table_GetBuffName(dwSkillID, dwSkillLevel)
			or Table_GetSkillName(dwSkillID, dwSkillLevel)
	end
	if szPoint == 'BOTTOM_LEFT' then -- 左下角肯定是伤害
		-- 苍云反弹技能修正颜色
		if p and p.dwID ~= COMBAT_TEXT_PLAYERID and  p.dwForceID == 21 and nEffectType ~= SKILL_EFFECT_TYPE.BUFF then
			local hSkill = GetSkill(dwSkillID, dwSkillLevel)
			if hSkill and hSkill.dwBelongSchool ~= 18 and hSkill.dwBelongSchool ~= 0 then
				nType = SKILL_RESULT_TYPE.REFLECTIED_DAMAGE
				col = D.col[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]
			end
		end
		if nType ~= SKILL_RESULT_TYPE.REFLECTIED_DAMAGE then
			col = D.col.DAMAGE
			if bCriticalStrike and O.bCritical then
				col = O.tCriticalB
			end
		end
	end
	if szPoint == 'TOP' and bCriticalStrike and COMBAT_TEXT_TYPE_CLASS[nType] ~= 'THERAPY' and O.bCritical then
		col = O.tCriticalC
	end
	-- draw text
	if not szText then -- 还未被定义的
		local szCasterName = ''
		if p then
			if employer then
				szCasterName = employer.szName
			else
				szCasterName = p.szName
			end
		end
		if O.bCasterNotI and szCasterName == GetClientPlayer().szName then
			szCasterName = ''
		end
		if O.bSnShorten2 then
			szSkillName = X.StringSubW(szSkillName, 1, 2) -- wstring是兼容台服的 台服utf-8
		end
		szText = szReplaceText
		szText = szText:gsub('(%s?)$crit(%s?)', (bCriticalStrike and '%1'.. g_tStrings.STR_CS_NAME .. '%2' or ''))
		szText = szText:gsub('$name', szCasterName)
		szText = szText:gsub('$sn', szSkillName)
		szText = szText:gsub('$val', (bStaticSign and X.IsNumber(nValue) and nValue > 0 and '+' or '') .. (nValue or ''))
	end
	CombatText.CreateText(shadow, dwTargetID, szText, szPoint, nType, bCriticalStrike, col)
end

function CombatText.OnSkillBuff(dwCharacterID, bCanCancel, dwID, nLevel)
	if not Table_BuffIsVisible(dwID, nLevel) then
		return
	end
	local szBuffName = Table_GetBuffName(dwID, nLevel)
	if szBuffName == '' then
		return
	end
	local tCache = bCanCancel and COMBAT_TEXT_CACHE.BUFF or COMBAT_TEXT_CACHE.DEBUFF
	if tCache[szBuffName] then
		return
	end
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	tCache[szBuffName] = true
	local col = bCanCancel and COMBAT_TEXT_COLOR.YELLOW or COMBAT_TEXT_COLOR.RED
	CombatText.CreateText(shadow, dwCharacterID, szBuffName, 'RIGHT', 'SKILL_BUFF', false, col)
end

function CombatText.OnSkillMiss(dwTargetID)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	local szPoint = dwTargetID == COMBAT_TEXT_PLAYERID and 'LEFT' or 'TOP'
	CombatText.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_MISS, szPoint, 'SKILL_MISS', false, COMBAT_TEXT_COLOR.WHITE)
end

function CombatText.OnBuffImmunity(dwTargetID)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	CombatText.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_IMMUNITY, 'LEFT', 'BUFF_IMMUNITY', false, COMBAT_TEXT_COLOR.WHITE)
end
-- FireUIEvent('COMMON_HEALTH_TEXT', GetClientPlayer().dwID, -8888)
function CombatText.OnCommonHealth(dwCharacterID, nDeltaLife)
	if nDeltaLife < 0 and dwCharacterID ~= COMBAT_TEXT_PLAYERID then
		return
	end
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	local szPoint = 'BOTTOM_LEFT'
	if nDeltaLife > 0 then
		if dwCharacterID ~= COMBAT_TEXT_PLAYERID then
			szPoint = 'TOP'
		else
			szPoint = 'BOTTOM_RIGHT'
		end
	end
	local szText = nDeltaLife > 0 and '+' .. nDeltaLife or nDeltaLife
	local col    = nDeltaLife > 0 and D.col[SKILL_RESULT_TYPE.THERAPY] or D.col.DAMAGE
	CombatText.CreateText(shadow, dwCharacterID, szText, szPoint, 'COMMON_HEALTH', false, col)
end

function CombatText.OnSkillDodge(dwTargetID)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	CombatText.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_DODGE, 'LEFT', 'SKILL_DODGE', false, COMBAT_TEXT_COLOR.RED)
end

function CombatText.OnExpLog(dwCharacterID, nExp)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	CombatText.CreateText(shadow, dwCharacterID, g_tStrings.STR_COMBATMSG_EXP .. nExp, 'CENTER', 'EXP', true, COMBAT_TEXT_COLOR.PURPLE)
end

function CombatText.OnCenterMsg(szText, bCritical, tCol)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	local dwID = GetControlPlayerID()
	local szType = bCritical and 'CRITICAL_MSG' or 'MSG'
	if not tCol then
		tCol = bCritical and COMBAT_TEXT_COLOR.RED or COMBAT_TEXT_COLOR.YELLOW
	end
	CombatText.CreateText(shadow, dwID, szText, 'CENTER', szType, bCritical, tCol)
end

function CombatText.GetFreeShadow()
	for k, v in ipairs(COMBAT_TEXT_FREE) do
		if v.free then
			v.free = false
			return v
		end
	end
	if #COMBAT_TEXT_FREE < COMBAT_TEXT_MAX_COUNT then
		local handle = CombatText.handle
		local sha = handle:AppendItemFromIni(COMBAT_TEXT_INIFILE, 'Shadow_Content')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()
		table.insert(COMBAT_TEXT_FREE, sha)
		return sha
	end
	Log('[MY] CombatText Get Free Item Failed!!!')
	Log(_L('[MY] Same time combat text reach limit %d, please check server script.', COMBAT_TEXT_MAX_COUNT))
end

function CombatText.LoadConfig()
	local bExist = IsFileExist(COMBAT_TEXT_CONFIG)
	if bExist then
		local data = LoadLUAData(COMBAT_TEXT_CONFIG)
		if data then
			COMBAT_TEXT_CRITICAL    = data.COMBAT_TEXT_CRITICAL    or COMBAT_TEXT_CRITICAL
			COMBAT_TEXT_SCALE       = data.COMBAT_TEXT_SCALE       or COMBAT_TEXT_SCALE
			COMBAT_TEXT_POINT       = data.COMBAT_TEXT_POINT       or COMBAT_TEXT_POINT
			COMBAT_TEXT_EVENT       = data.COMBAT_TEXT_EVENT       or COMBAT_TEXT_EVENT
			COMBAT_TEXT_IGNORE_TYPE = data.COMBAT_TEXT_IGNORE_TYPE or {}
			COMBAT_TEXT_IGNORE      = data.COMBAT_TEXT_IGNORE      or {}
			X.Sysmsg(_L['CombatText Config loaded'])
		else
			X.Sysmsg(_L['CombatText Config failed'])
		end
	end
end

function CombatText.CheckEnable()
	local ui = Station.Lookup('Lowest/MY_CombatText')
	if IsEnabled() then
		if O.bRender then
			COMBAT_TEXT_INIFILE = X.PACKET_INFO.ROOT .. 'MY_CombatText/ui/MY_CombatText_Render.ini'
		else
			COMBAT_TEXT_INIFILE = X.PACKET_INFO.ROOT .. 'MY_CombatText/ui/MY_CombatText.ini'
		end
		COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[O.nStyle] and COMBAT_TEXT_STYLES[O.nStyle] or COMBAT_TEXT_STYLES[0]
		CombatText.LoadConfig()
		if ui then
			Wnd.CloseWindow(ui)
		end
		Wnd.OpenWindow(COMBAT_TEXT_INIFILE, 'MY_CombatText')
		D.HideOfficialCombat()
	else
		if ui then
			CombatText.FreeQueue()
			Wnd.CloseWindow(ui)
			X.BreatheCall('COMBAT_TEXT_CACHE', false)
			collectgarbage('collect')
		end
		D.ShowOfficialCombat()
	end
	setmetatable(COMBAT_TEXT_POINT, { __index = function(me, key)
		if key == 'TOP_LEFT' or key == 'TOP_RIGHT' then
			return me['TOP']
		end
	end })
	local mt = { __index = function(me)
		return me[#me]
	end }
	setmetatable(COMBAT_TEXT_SCALE.CRITICAL, mt)
	setmetatable(COMBAT_TEXT_SCALE.NORMAL,   mt)
end


--------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------
do
local settings = {
	name = 'MY_CombatText',
	exports = {
		{
			root = D,
			preset = 'UIEvent',
		},
	},
}
MY_CombatText = X.CreateModule(settings)
end


local PS = {}
function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local W, H = ui:Size()
	local nPaddingX, nPaddingY = 20, 10
	local x, y = nPaddingX, nPaddingY
	local deltaY = 28

	ui:Append('Text', { x = x, y = y, text = _L['CombatText'], font = 27 })
	x = x + 10
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Enable CombatText'], color = { 255, 128, 0 },
		checked = O.bEnable,
		onCheck = function(bCheck)
			O.bEnable = bCheck
			CombatText.CheckEnable()
		end,
	})
	x = x + 130

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 200, text = _L['Enable Render'],
		checked = O.bRender,
		onCheck = function(bCheck)
			O.bRender = bCheck
			CombatText.CheckEnable()
		end,
		autoEnable = IsEnabled,
	})
	x = x + 170

	ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Disable Immunity'],
		checked = O.bImmunity,
		onCheck = function(bCheck)
			O.bImmunity = bCheck
		end,
		autoEnable = IsEnabled,
	})
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_QUESTTRACE_CHANGE_ALPHA, color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 70
	ui:Append('WndTrackbar', {
		x = x, y = y, text = '',
		range = {1, 255},
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.nMaxAlpha,
		onChange = function(nVal)
			O.nMaxAlpha = nVal
		end,
		autoEnable = IsEnabled,
	})

	x = x + 180
	ui:Append('Text', { x = x, y = y, text = _L['Hold time'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 70
	ui:Append('WndTrackbar', {
		x = x, y = y, textFormatter = function(val) return val .. _L['ms'] end,
		range = {700, 2500},
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.nTime * COMBAT_TEXT_TOTAL,
		onChange = function(nVal)
			O.nTime = nVal / COMBAT_TEXT_TOTAL
		end,
		autoEnable = IsEnabled,
	})
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = _L['FadeIn time'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 70
	ui:Append('WndTrackbar', {
		x = x, y = y, textFormatter = function(val) return val .. _L['Frame'] end,
		range = {0, 15},
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.nFadeIn,
		onChange = function(nVal)
			O.nFadeIn = nVal
		end,
		autoEnable = IsEnabled,
	})

	x = x + 180
	ui:Append('Text', { x = x, y = y, text = _L['FadeOut time'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 70
	ui:Append('WndTrackbar', {
		x = x, y = y, textFormatter = function(val) return val .. _L['Frame'] end,
		rang = {0, 15},
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.nFadeOut,
		onChange = function(nVal)
			O.nFadeOut = nVal
		end,
		autoEnable = IsEnabled,
	})
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = _L['Font Size'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 70
	ui:Append('WndTrackbar', {
		x = x, y = y, textFormatter = function(val) return (val / 100) .. _L['times'] end,
		range = {50, 200},
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = O.fScale * 100,
		onChange = function(nVal)
			O.fScale = nVal / 100
			CombatText.UpdateTrajectoryCount()
		end,
		autoEnable = IsEnabled,
	})
	y = y + deltaY

	x = nPaddingX
	ui:Append('Text', { x = x, y = y, text = _L['Circle Style'], font = 27, autoEnable = IsEnabled })
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('WndRadioBox', {
		x = x, y = y + 5, text = _L['hit feel'],
		group = 'style',
		checked = O.nStyle == 0,
		onCheck = function()
			O.nStyle = 0
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[0]
		end,
		autoEnable = IsEnabled,
	})
	x = x + 90

	ui:Append('WndRadioBox', {
		x = x, y = y + 5, text = _L['low hit feel'],
		group = 'style',
		checked = O.nStyle == 1,
		onCheck = function()
			O.nStyle = 1
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[1]
		end,
		autoEnable = IsEnabled,
	})
	x = x + 90

	ui:Append('WndRadioBox', {
		x = x, y = y + 5, text = _L['soft'],
		group = 'style',
		checked = O.nStyle == 2,
		onCheck = function()
			O.nStyle = 2
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[2]
		end,
		autoEnable = IsEnabled,
	})
	x = x + 60

	ui:Append('WndRadioBox', {
		x = x, y = y + 5, text = _L['Scale only'],
		group = 'style',
		checked = O.nStyle == 3,
		onCheck = function()
			O.nStyle = 3
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[3]
		end,
		autoEnable = IsEnabled,
	})
	x = x + 90
	y = y + deltaY

	x = nPaddingX
	ui:Append('Text', { x = x, y = y, text = _L['Text Style'], font = 27, autoEnable = IsEnabled })
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = _L['Skill Style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 110
	ui:Append('WndEditBox', {
		x = x, y = y, w = 250, h = 25, text = O.szSkill, limit = 30,
		onChange = function(szText)
			O.szSkill = szText
		end,
		autoEnable = IsEnabled,
	})
	x = x + 250
	if O.bCritical then
		x = x + 10
		ui:Append('Text', { x = x, y = y, text = _L['critical beat'], autoEnable = IsEnabled }) --会心伤害
		x = x + 70
		ui:Append('Shadow', {
			x = x, y = y + 8, color = O.tCriticalC, w = 15, h = 15,
			onClick = function()
				local this = this
				X.UI.OpenColorPicker(function(r, g, b)
					O.tCriticalC = { r, g, b }
					X.UI(this):Color(r, g, b)
				end)
			end,
			autoEnable = IsEnabled,
		})
	end
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = _L['Damage Style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 110
	ui:Append('WndEditBox', {
		x = x, y = y, w = 250, h = 25, text = O.szDamage, limit = 30,
		onChange = function(szText)
			O.szDamage = szText
		end,
		autoEnable = IsEnabled,
	})
	x = x + 250
	if O.bCritical then
		x = x + 10
		ui:Append('Text', { x = x, y = y, text = _L['critical beaten'], autoEnable = IsEnabled }) --会心承伤
		x = x + 70
		ui:Append('Shadow', {
			x = x, y = y + 8, color = O.tCriticalB, w = 15, h = 15,
			onClick = function()
				local this = this
				X.UI.OpenColorPicker(function(r, g, b)
					O.tCriticalB = { r, g, b }
					X.UI(this):Color(r, g, b)
				end)
			end,
			autoEnable = IsEnabled,
		})
	end
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = _L['Therapy Style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	x = x + 110
	ui:Append('WndEditBox', {
		x = x, y = y, w = 250, h = 25, text = O.szTherapy, limit = 30,
		onChange = function(szText)
			O.szTherapy = szText
		end,
		autoEnable = IsEnabled,
	})
	x = x + 250
	if O.bCritical then
		x = x + 10
		ui:Append('Text', { x = x, y = y, text = _L['critical heaten'], autoEnable = IsEnabled }) --会心承疗
		x = x + 70
		ui:Append('Shadow', {
			x = x, y = y + 8, color = O.tCriticalH, w = 15, h = 15,
			onClick = function()
				local this = this
				X.UI.OpenColorPicker(function(r, g, b)
					O.tCriticalH = { r, g, b }
					X.UI(this):Color(r, g, b)
				end)
			end,
			autoEnable = IsEnabled,
		})
	end
	y = y + deltaY

	x = nPaddingX + 10
	ui:Append('Text', { x = x, y = y, text = _L['CombatText Tips'], color = { 196, 196, 196 }, autoEnable = IsEnabled })
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 190, text = _L['$name not me'], checked = O.bCasterNotI,
		onCheck = function(bCheck)
			O.bCasterNotI = bCheck
		end,
		autoEnable = IsEnabled,
	})
	x = x + 190

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 110, text = _L['$sn shorten(2)'], checked = O.bSnShorten2,
		onCheck = function(bCheck)
			O.bSnShorten2 = bCheck
		end,
		autoEnable = IsEnabled,
	})
	x = x + 110

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 140, text = _L['therapy effective only'], checked = O.bTherEffOnly,
		onCheck = function(bCheck)
			O.bTherEffOnly = bCheck
		end,
		autoEnable = IsEnabled,
	})
	x = x + 140

	ui:Append('WndButton', {
		x = x, y = y, text = _L['Font edit'],
		onClick = function()
			X.UI.OpenFontPicker(function(nFont)
				O.nFont = nFont
			end)
		end,
		tip = {
			render = function() return _L('Current font: %d', O.nFont) end,
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		autoEnable = IsEnabled,
	})
	y = y + deltaY

	x = nPaddingX
	ui:Append('Text', { x = x, y = y, text = _L['Color edit'], font = 27, autoEnable = IsEnabled })
	x = x + 10
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Critical Color'], checked = O.bCritical and true or false,
		onCheck = function(bCheck)
			O.bCritical = bCheck
			X.ShowPanel()
			X.FocusPanel()
			X.SwitchTab('MY_CombatText', true)
		end,
		autoEnable = IsEnabled,
	})
	y = y + deltaY

	x = nPaddingX + 10
	local i = 0
	for k, v in pairs(COMBAT_TEXT_TYPE_COLOR) do
		if k ~= SKILL_RESULT_TYPE.EFFECTIVE_THERAPY then
			ui:Append('Text', { x = x + (i % 8) * 65, y = y + 30 * math.floor(i / 8), text = _L['CombatText Color ' .. k], autoEnable = IsEnabled })
			ui:Append('Shadow', {
				x = x + (i % 8) * 65 + 35, y = y + 30 * math.floor(i / 8) + 8, color = v, w = 15, h = 15,
				onClick = function()
					local this = this
					X.UI.OpenColorPicker(function(r, g, b)
						O.col[k] = { r, g, b }
						O.col = O.col
						X.UI(this):Color(r, g, b)
					end)
				end,
				autoEnable = IsEnabled,
			})
			i = i + 1
		end
	end

	if IsFileExist(COMBAT_TEXT_CONFIG) then
		ui:Append('WndButton', {
			x = W - 120 - nPaddingX, y = 15, w = 120, h = 40,
			text = _L['Load CombatText Config'],
			buttonStyle = 'SKEUOMORPHISM_LACE_BORDER',
			onClick = CombatText.CheckEnable,
		})
	end
end
X.RegisterPanel(_L['System'], 'MY_CombatText', _L['CombatText'], 2041, PS)

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

local function GetPlayerID()
	local me = GetControlPlayer()
	if me then
		COMBAT_TEXT_PLAYERID = me.dwID
		--[[#DEBUG BEGIN]]
		-- X.Debug('CombatText get player id ' .. me.dwID, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	else
		--[[#DEBUG BEGIN]]
		X.Debug('CombatText get player id failed!!! try again', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		X.DelayCall(1000, GetPlayerID)
	end
end
X.RegisterUserSettingsInit('MY_CombatText', function()
	D.bReady = true
	CombatText.UpdateTrajectoryCount()
	CombatText.CheckEnable()
end)
X.RegisterEvent('LOADING_END', 'MY_CombatText', GetPlayerID) -- 很重要的优化
X.RegisterEvent('ON_NEW_PROXY_SKILL_LIST_NOTIFY', 'MY_CombatText', GetPlayerID) -- 长歌控制主体ID切换
X.RegisterEvent('ON_CLEAR_PROXY_SKILL_LIST_NOTIFY', 'MY_CombatText', GetPlayerID) -- 长歌控制主体ID切换
X.RegisterEvent('ON_PVP_SHOW_SELECT_PLAYER', 'MY_CombatText', function()
	COMBAT_TEXT_PLAYERID = arg0
end)
X.RegisterEvent('MY_COMBATTEXT_MSG', 'MY_CombatText', function()
	CombatText.OnCenterMsg(arg0, arg1, arg2)
end)
X.RegisterEvent('FIRST_LOADING_END', 'MY_CombatText', CombatText.CheckEnable)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
