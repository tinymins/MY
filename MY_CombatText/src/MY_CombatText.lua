-- @Author: Webster
-- @Date:   2015-12-06 02:44:30
-- @Last Modified by:   William Chan
-- @Last Modified time: 2017-04-21 15:32:37

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
		Y轴轨迹数 以 floor(3.5 / UI缩放) 决定，其初始Y轴高度不同。
		在轨迹全部被占用后会随机分摊到屏幕顶部左右两边。
	其他类型：使用轨迹合并16-32帧，后来的文本会顶走前面的文本，从而跳过这部分停留的帧数。
]]

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_CombatText/lang/")
local Table_GetBuffName, Table_GetSkillName, Table_BuffIsVisible = Table_GetBuffName, Table_GetSkillName, Table_BuffIsVisible
local GetUserRoleName = GetUserRoleName
local pairs, ipairs, unpack = pairs, ipairs, unpack
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
local GetPlayer, GetNpc, IsPlayer = GetPlayer, GetNpc, IsPlayer
local GetSkill, GetTime, Random = GetSkill, GetTime, Random
local SKILL_RESULT_TYPE = SKILL_RESULT_TYPE

local COMBAT_TEXT_INIFILE        = MY.GetAddonInfo().szRoot .. "MY_CombatText/ui/MY_CombatText_Render.ini"
local COMBAT_TEXT_CONFIG         = MY.GetAddonInfo().szRoot .. "MY_CombatText/config.jx3dat"
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
	["EXP"]                                  = true,
}
local COMBAT_TEXT_IGNORE_TYPE = {}
local COMBAT_TEXT_IGNORE = {}
local COMBAT_TEXT_EVENT  = { "COMMON_HEALTH_TEXT", "SKILL_EFFECT_TEXT", "SKILL_MISS", "SKILL_DODGE", "SKILL_BUFF", "BUFF_IMMUNITY" }
local COMBAT_TEXT_STRING = { -- 需要变成特定字符串的伤害类型
	[SKILL_RESULT_TYPE.SHIELD_DAMAGE]  = g_tStrings.STR_MSG_ABSORB,
	[SKILL_RESULT_TYPE.ABSORB_DAMAGE]  = g_tStrings.STR_MSG_ABSORB,
	[SKILL_RESULT_TYPE.PARRY_DAMAGE]   = g_tStrings.STR_MSG_COUNTERACT,
	[SKILL_RESULT_TYPE.INSIGHT_DAMAGE] = g_tStrings.STR_MSG_INSIGHT,
}
local COMBAT_TEXT_COLOR = { --不需要修改的内定颜色
	YELLOW = { 255, 255, 0   },
	RED    = { 255, 0,   0   },
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
local COMBAT_TEXT_LEAVE  = {}
local COMBAT_TEXT_FREE   = {}
local COMBAT_TEXT_SHADOW = {}
local COMBAT_TEXT_QUEUE  = {}
local COMBAT_TEXT_CACHE  = { -- buff的名字cache
	BUFF   = {},
	DEBUFF = {},
}
local CombatText = {}

MY_CombatText = {
	bEnable      = true,
	bRender      = true,
	fScale       = 1,
	nStyle       = 1, -- default
	nMaxAlpha    = 240,
	nTime        = 40,
	nFadeIn      = 4,
	nFadeOut     = 8,
	nFont        = 19,
	bImmunity    = false,
	bCritical    = false,
	tCriticalC   = { 255, 255, 255 },
	tCriticalH   = { 0,   255, 0   },
	tCriticalB   = { 255, 0,   0   },
	-- $name 名字 $sn   技能名 $crit 会心 $val  数值
	szSkill      = "$sn" .. g_tStrings.STR_COLON .. "$crit $val",
	szTherapy    = "$sn" .. g_tStrings.STR_COLON .. "$crit +$val",
	szDamage     = "$sn" .. g_tStrings.STR_COLON .. "$crit -$val",
	bCasterNotI  = false,
	bSnShorten2  = false,
	bTherEffOnly = false,
	col = { -- 颜色呗
		["DAMAGE"]                               = { 255, 0,   0   }, -- 自己受到的伤害
		[SKILL_RESULT_TYPE.THERAPY]              = { 0,   255, 0   }, -- 治疗
		[SKILL_RESULT_TYPE.PHYSICS_DAMAGE]       = { 255, 255, 255 }, -- 外公
		[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE]   = { 255, 128, 128 }, -- 阳
		[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] = { 255, 255, 0   }, -- 混元
		[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE]   = { 12,  242, 255 }, -- 阴
		[SKILL_RESULT_TYPE.POISON_DAMAGE]        = { 128, 255, 128 }, -- 有毒啊
		[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]    = { 255, 128, 128 }, -- 反弹 ？？
	}
}
MY.RegisterCustomData("MY_CombatText", 2)

local function IsEnabled()
	return MY_CombatText.bEnable
end
local MY_CombatText = MY_CombatText

function MY_CombatText.OnFrameCreate()
	for k, v in ipairs(COMBAT_TEXT_EVENT) do
		this:RegisterEvent(v)
	end
	this:ShowWhenUIHide()
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("FIGHT_HINT")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("LOADING_END")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("ON_EXP_LOG")
	CombatText.handle = this:Lookup("", "")
	-- uninit
	local frame = Station.Lookup("Lowest/CombatText")
	local events = { "SKILL_EFFECT_TEXT", "COMMON_HEALTH_TEXT", "SKILL_MISS", "SKILL_DODGE", "SKILL_BUFF", "BUFF_IMMUNITY", "ON_EXP_LOG", "FIGHT_HINT" }
	if frame then
		for k, v in ipairs(events) do
			frame:UnRegisterEvent(v)
		end
	end
	CombatText.FreeQueue()
	COMBAT_TEXT_UI_SCALE   = Station.GetUIScale()
	COMBAT_TEXT_TRAJECTORY = CombatText.TrajectoryCount()
	MY.BreatheCall("COMBAT_TEXT_CACHE", 1000 * 60 * 5, function()
		local count = 0
		for k, v in pairs(COMBAT_TEXT_LEAVE) do
			count = count + 1
		end
		if count > 10000 then
			COMBAT_TEXT_LEAVE = {}
			Log("[MY] CombatText cache beyond 10000 !!!")
		end
	end)
end

-- for i=1,5 do FireUIEvent("SKILL_EFFECT_TEXT",UI_GetClientPlayerID(),1073741860,true,5,1111,111,1)end
-- for i=1,5 do FireUIEvent("SKILL_EFFECT_TEXT",UI_GetClientPlayerID(),1073741860,false,5,1111,111,1)end
-- for i=1, 5 do FireEvent("SKILL_BUFF", UI_GetClientPlayerID(), true, 103, 1) end
-- FireUIEvent("SKILL_MISS", UI_GetClientPlayerID(), UI_GetClientPlayerID())
-- FireUIEvent("SYS_MSG", "UI_OME_EXP_LOG", UI_GetClientPlayerID(), UI_GetClientPlayerID())
function MY_CombatText.OnEvent(szEvent)
	if szEvent == "FIGHT_HINT" then -- 进出战斗文字
		if arg0 then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MSG_ENTER_FIGHT)
		else
			OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MSG_LEAVE_FIGHT)
		end
	elseif szEvent == "COMMON_HEALTH_TEXT" then
		if arg1 ~= 0 then
			CombatText.OnCommonHealth(arg0, arg1)
		end
	elseif szEvent == "SKILL_EFFECT_TEXT" then
		CombatText.OnSkillText(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	elseif szEvent == "SKILL_BUFF" then
		CombatText.OnSkillBuff(arg0, arg1, arg2, arg3)
	elseif szEvent == "BUFF_IMMUNITY" then
		if not MY_CombatText.bImmunity and arg1 == COMBAT_TEXT_PLAYERID then
			CombatText.OnBuffImmunity(arg0)
		end
	elseif szEvent == "SKILL_MISS" then
		if arg0 == COMBAT_TEXT_PLAYERID or arg1 == COMBAT_TEXT_PLAYERID then
			CombatText.OnSkillMiss(arg1)
		end
	elseif szEvent == "UI_SCALED" then
		COMBAT_TEXT_UI_SCALE   = Station.GetUIScale()
		COMBAT_TEXT_TRAJECTORY = CombatText.TrajectoryCount()
	elseif szEvent == "SKILL_DODGE" then
		if arg0 == COMBAT_TEXT_PLAYERID or arg1 == COMBAT_TEXT_PLAYERID then
			CombatText.OnSkillDodge(arg1)
		end
	elseif szEvent == "NPC_ENTER_SCENE" then
		COMBAT_TEXT_LEAVE[arg0] = nil
	elseif szEvent == "ON_EXP_LOG" then
		CombatText.OnExpLog(arg0, arg1)
	elseif szEvent == "SYS_MSG" then
		if arg0 == "UI_OME_DEATH_NOTIFY" then
			if not IsPlayer(arg1) then
				COMBAT_TEXT_LEAVE[arg1] = true
			end
		end
	elseif szEvent == "LOADING_END" then
		CombatText.FreeQueue()
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
	setmetatable(COMBAT_TEXT_QUEUE, { __index = function(me) return me["TOP"] end, __newindex = function(me) return me["TOP"] end })
end

function CombatText.OnFrameRender()
	local nTime     = GetTime()
	local nFadeIn   = MY_CombatText.nFadeIn
	local nFadeOut  = MY_CombatText.nFadeOut
	local nMaxAlpha = MY_CombatText.nMaxAlpha
	local nFont     = MY_CombatText.nFont
	local nDelay    = MY_CombatText.nTime
	local g_fScale  = MY_CombatText.fScale
	for k, v in pairs(COMBAT_TEXT_SHADOW) do
		local nFrame = (nTime - v.nTime) / nDelay + 1 -- 每一帧是多少毫秒 这里越小 动画越快
		local nBefore = floor(nFrame)
		local nAfter  = ceil(nFrame)
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
			if v.szPoint == "TOP" or v.szPoint == "TOP_LEFT" or v.szPoint == "TOP_RIGHT" then
				local tTop = COMBAT_TEXT_POINT[v.szPoint]
				nTop = (-60 * g_fScale) + v.nSort * (-40 * g_fScale) - (tTop[nBefore] + (tTop[nAfter] - tTop[nBefore]) * fDiff)
				if v.szPoint == "TOP_LEFT" or v.szPoint == "TOP_RIGHT" then
					if v.szPoint == "TOP_LEFT" then
						nLeft = -250
					elseif v.szPoint == "TOP_RIGHT" then
						nLeft = 250
					end
					nTop = nTop -50
				end
			elseif v.szPoint == "LEFT" then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				nLeft = -60 - (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				nAlpha = nAlpha * 0.85
			elseif v.szPoint == "RIGHT" then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				nLeft = 60 + (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				nAlpha = nAlpha * 0.9
			elseif v.szPoint == "BOTTOM_LEFT" or v.szPoint == "BOTTOM_RIGHT" then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				local tTop = COMBAT_TEXT_POINT[v.szPoint]
				if v.szPoint == "BOTTOM_LEFT" then
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
				if v.nType == SKILL_RESULT_TYPE.THERAPY then -- 治疗缩小
					if v.bCriticalStrike then
						fScale = max(fScale * 0.7, COMBAT_TEXT_SCALE.NORMAL[#COMBAT_TEXT_SCALE.NORMAL] + 0.1)
					end
					if v.dwTargetID == COMBAT_TEXT_PLAYERID then
						fScale = fScale * 0.95
					end
				elseif v.szPoint == "TOP_LEFT" or v.szPoint == "TOP_RIGHT" then -- 左右缩小
					fScale = fScale * 0.85
				end
				if v.szPoint == "TOP" or v.szPoint == "TOP_LEFT" or v.szPoint == "TOP_RIGHT" then
					fScale = fScale * g_fScale
				end
			end
			-- draw
			local r, g, b = unpack(v.col)
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
			if not v.bJump and v.szPoint ~= "TOP" and nFrame >= 16 and nFrame <= 32 then
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
			if v.bJump and v.szPoint ~= "TOP" and nFrame >= 16 and nFrame <= 32 then
				v.nTime = v.nTime - (32 - nFrame) * nDelay
			else
				v.nFrame = nFrame
			end
		else
			if v.szPoint == "RIGHT" and v.dwTargetID == COMBAT_TEXT_PLAYERID then
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
				local dat = tremove(vv, 1)
				if dat.dat.szPoint == "TOP" then
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

MY_CombatText.OnFrameBreathe = CombatText.OnFrameRender
MY_CombatText.OnFrameRender  = CombatText.OnFrameRender

function CombatText.TrajectoryCount()
	if MY_CombatText.fScale < 1.5 then
		return floor(3.5 / COMBAT_TEXT_UI_SCALE / MY_CombatText.fScale)
	else
		return floor(3.5 / COMBAT_TEXT_UI_SCALE)
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
			and v.szPoint == "TOP"
			and v.nFrame < 15
		then
			local fSort = (COMBAT_TEXT_POINT.TOP[floor(v.nFrame) + 1] + v.nSort * fRange * COMBAT_TEXT_POINT.TOP[COMBAT_TEXT_TOTAL]) / COMBAT_TEXT_POINT.TOP[COMBAT_TEXT_TOTAL]
			for i = 1, COMBAT_TEXT_TRAJECTORY do
				if fSort < tSort[i].fRange then
					tSort[i].nCount = tSort[i].nCount + 1
					break
				end
			end
		end
	end
	tsort(tSort, TrajectorySort)
	local nSort = tSort[1].nSort - 1
	local szPoint = "TOP"
	if tSort[1].nCount == 1 then
		szPoint = Random(2) == 1 and "TOP_LEFT" or "TOP_RIGHT"
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
		if szPoint == "TOP" then
			local nSort, point = CombatText.GetTrajectory(dat.dwTargetID, true)
			dat.nSort = nSort
			dat.szPoint = point
		end
		dat.nTime = GetTime()
		COMBAT_TEXT_SHADOW[shadow] = dat
	else
		COMBAT_TEXT_QUEUE[szPoint][dwTargetID] = COMBAT_TEXT_QUEUE[szPoint][dwTargetID] or {}
		tinsert(COMBAT_TEXT_QUEUE[szPoint][dwTargetID], { shadow = shadow, dat = dat })
	end
end

local tTherapyType = {
	[SKILL_RESULT_TYPE.STEAL_LIFE]        = true,
	[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] = true,
	[SKILL_RESULT_TYPE.THERAPY]           = true,
}

function CombatText.OnSkillText(dwCasterID, dwTargetID, bCriticalStrike, nType, nValue, dwSkillID, dwSkillLevel, nEffectType)
	-- 过滤 有效治疗 有效伤害 西区内力 化解治疗
	if nType == SKILL_RESULT_TYPE.EFFECTIVE_DAMAGE
--	or nType == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY
	or (nType == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY and not MY_CombatText.bTherEffOnly)
	or (nType == SKILL_RESULT_TYPE.THERAPY and MY_CombatText.bTherEffOnly)
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
	-- 把治疗归类为一种 方便处理
	local bStealLife = nType == SKILL_RESULT_TYPE.STEAL_LIFE and true
	nType = tTherapyType[nType] and SKILL_RESULT_TYPE.THERAPY or nType
	if nType == SKILL_RESULT_TYPE.THERAPY and nValue == 0 then
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

	local szName, szText, szReplaceText
	-- skill name
	if not bStealLife then
		szName = nEffectType == SKILL_EFFECT_TYPE.BUFF and Table_GetBuffName(dwSkillID, dwSkillLevel) or Table_GetSkillName(dwSkillID, dwSkillLevel)
	else -- 吸血技能偷取避免重复获取 浪费性能
		szName = g_tStrings.SKILL_STEAL_LIFE
	end
	-- replace
	if nType == SKILL_RESULT_TYPE.THERAPY then
		szReplaceText = MY_CombatText.szTherapy
	else
		szReplaceText = MY_CombatText.szSkill
	end
	-- point color
	local szPoint = "TOP"
	local col     = MY_CombatText.col[nType]
	if COMBAT_TEXT_STRING[nType] then
		szText = COMBAT_TEXT_STRING[nType]
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = "LEFT"
			col = COMBAT_TEXT_COLOR.YELLOW
		end
	elseif nType == SKILL_RESULT_TYPE.THERAPY then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = "BOTTOM_RIGHT"
		end
		if bCriticalStrike and MY_CombatText.bCritical then
			col = MY_CombatText.tCriticalH
		end
	else
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = "BOTTOM_LEFT"
		end
	end
	if szPoint == "BOTTOM_LEFT" then -- 左下角肯定是伤害
		-- 苍云反弹技能修正颜色
		if p and p.dwID ~= COMBAT_TEXT_PLAYERID and  p.dwForceID == 21 and nEffectType ~= SKILL_EFFECT_TYPE.BUFF then
			local hSkill = GetSkill(dwSkillID, dwSkillLevel)
			if hSkill and hSkill.dwBelongSchool ~= 18 and hSkill.dwBelongSchool ~= 0 then
				nType = SKILL_RESULT_TYPE.REFLECTIED_DAMAGE
				col = MY_CombatText.col[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]
			end
		end
		if nType ~= SKILL_RESULT_TYPE.REFLECTIED_DAMAGE then
			col = MY_CombatText.col["DAMAGE"]
			if bCriticalStrike and MY_CombatText.bCritical then
				col = MY_CombatText.tCriticalB
			end
		end
		szReplaceText = MY_CombatText.szDamage
	end
	if szPoint == "TOP" and bCriticalStrike and nType ~= SKILL_RESULT_TYPE.THERAPY and MY_CombatText.bCritical then
		col = MY_CombatText.tCriticalC
	end
	-- draw text
	if not szText then -- 还未被定义的
		local szCasterName = ""
		if p then
			if employer then
				szCasterName = employer.szName
			else
				szCasterName = p.szName
			end
		end
		if MY_CombatText.bCasterNotI and szCasterName == GetUserRoleName() then
			szCasterName = ""
		end
		if MY_CombatText.bSnShorten2 then
			szName = wstring.sub(szName, 1, 2) -- wstring是兼容台服的 台服utf-8
		end
		szText = szReplaceText
		szText = szText:gsub("(%s?)$crit(%s?)", (bCriticalStrike and "%1".. g_tStrings.STR_CS_NAME .. "%2" or ""))
		szText = szText:gsub("$name", szCasterName)
		szText = szText:gsub("$sn", szName)
		szText = szText:gsub("$val", nValue or "")
	end
	CombatText.CreateText(shadow, dwTargetID, szText, szPoint, nType, bCriticalStrike, col)
end

function CombatText.OnSkillBuff(dwCharacterID, bCanCancel, dwID, nLevel)
	if not Table_BuffIsVisible(dwID, nLevel) then
		return
	end
	local szBuffName = Table_GetBuffName(dwID, nLevel)
	if szBuffName == "" then
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
	CombatText.CreateText(shadow, dwCharacterID, szBuffName, "RIGHT", "SKILL_BUFF", false, col)
end

function CombatText.OnSkillMiss(dwTargetID)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	local szPoint = dwTargetID == COMBAT_TEXT_PLAYERID and "LEFT" or "TOP"
	CombatText.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_MISS, szPoint, "SKILL_MISS", false, COMBAT_TEXT_COLOR.WHITE)
end

function CombatText.OnBuffImmunity(dwTargetID)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	CombatText.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_IMMUNITY, "LEFT", "BUFF_IMMUNITY", false, COMBAT_TEXT_COLOR.WHITE)
end
-- FireUIEvent("COMMON_HEALTH_TEXT", GetClientPlayer().dwID, -8888)
function CombatText.OnCommonHealth(dwCharacterID, nDeltaLife)
	if nDeltaLife < 0 and dwCharacterID ~= COMBAT_TEXT_PLAYERID then
		return
	end
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	local szPoint = "BOTTOM_LEFT"
	if nDeltaLife > 0 then
		if dwCharacterID ~= COMBAT_TEXT_PLAYERID then
			szPoint = "TOP"
		else
			szPoint = "BOTTOM_RIGHT"
		end
	end
	local szText = nDeltaLife > 0 and "+" .. nDeltaLife or nDeltaLife
	local col    = nDeltaLife > 0 and MY_CombatText.col[SKILL_RESULT_TYPE.THERAPY] or MY_CombatText.col["DAMAGE"]
	CombatText.CreateText(shadow, dwCharacterID, szText, szPoint, "COMMON_HEALTH", false, col)
end

function CombatText.OnSkillDodge(dwTargetID)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	CombatText.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_DODGE, "LEFT", "SKILL_DODGE", false, COMBAT_TEXT_COLOR.RED)
end

function CombatText.OnExpLog(dwCharacterID, nExp)
	local shadow = CombatText.GetFreeShadow()
	if not shadow then -- 没有空闲的shadow
		return
	end
	CombatText.CreateText(shadow, dwCharacterID, g_tStrings.STR_COMBATMSG_EXP .. nExp, "CENTER", "EXP", true, COMBAT_TEXT_COLOR.PURPLE)
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
		local sha = handle:AppendItemFromIni(COMBAT_TEXT_INIFILE, "Shadow_Content")
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()
		tinsert(COMBAT_TEXT_FREE, sha)
		return sha
	end
	Log("[MY] CombatText Get Free Item Failed!!!")
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
			MY.Sysmsg({_L["CombatText Config loaded"]})
		else
			MY.Sysmsg({_L["CombatText Config failed"]})
		end
	end
end

function CombatText.CheckEnable()
	local frame = Station.Lookup("Lowest/CombatText")
	local ui = Station.Lookup("Lowest/MY_CombatText")
	if MY_CombatText.bRender then
		COMBAT_TEXT_INIFILE = MY.GetAddonInfo().szRoot .. "MY_CombatText/ui/MY_CombatText_Render.ini"
	else
		COMBAT_TEXT_INIFILE = MY.GetAddonInfo().szRoot .. "MY_CombatText/ui/MY_CombatText.ini"
	end
	if MY_CombatText.bEnable then
		COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[MY_CombatText.nStyle] and COMBAT_TEXT_STYLES[MY_CombatText.nStyle] or COMBAT_TEXT_STYLES[0]
		CombatText.LoadConfig()
		if ui then
			Wnd.CloseWindow(ui)
		end
		Wnd.OpenWindow(COMBAT_TEXT_INIFILE, "MY_CombatText")
	else
		local events = { "SKILL_EFFECT_TEXT", "COMMON_HEALTH_TEXT", "SKILL_MISS", "SKILL_DODGE", "SKILL_BUFF", "BUFF_IMMUNITY", "SYS_MSG", "FIGHT_HINT" }
		if frame then
			for k, v in ipairs(events) do
				frame:UnRegisterEvent(v)
				frame:RegisterEvent(v)
			end
		end
		if ui then
			CombatText.FreeQueue()
			Wnd.CloseWindow(ui)
			MY.BreatheCall("COMBAT_TEXT_CACHE", false)
			collectgarbage("collect")
		end
	end
	setmetatable(COMBAT_TEXT_POINT, { __index = function(me, key)
		if key == "TOP_LEFT" or key == "TOP_RIGHT" then
			return me["TOP"]
		end
	end })
	setmetatable(MY_CombatText.col, { __index = function() return COMBAT_TEXT_COLOR.WHITE end })
	local mt = { __index = function(me)
		return me[#me]
	end }
	setmetatable(COMBAT_TEXT_SCALE.CRITICAL, mt)
	setmetatable(COMBAT_TEXT_SCALE.NORMAL,   mt)
end

local PS = {}
function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 10
	local x, y = X, Y
	local deltaY = 28

	ui:append("Text", { x = x, y = y, text = _L["CombatText"], font = 27 })
	x = x + 10
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Enable CombatText"], color = { 255, 128, 0 },
		checked = MY_CombatText.bEnable,
		oncheck = function(bCheck)
			MY_CombatText.bEnable = bCheck
			CombatText.CheckEnable()
		end,
	})
	x = x + 130

	ui:append("WndCheckBox", {
		x = x, y = y, w = 200, text = _L["Enable Render"],
		checked = MY_CombatText.bRender,
		oncheck = function(bCheck)
			MY_CombatText.bRender = bCheck
			CombatText.CheckEnable()
		end,
		autoenable = IsEnabled,
	})
	x = x + 170

	ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Disable Immunity"],
		checked = MY_CombatText.bImmunity,
		oncheck = function(bCheck)
			MY_CombatText.bImmunity = bCheck
		end,
		autoenable = IsEnabled,
	})
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = x, y = y, text = g_tStrings.STR_QUESTTRACE_CHANGE_ALPHA, color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 70
	ui:append("WndSliderBox", {
		x = x, y = y, text = "",
		range = {1, 255},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_CombatText.nMaxAlpha,
		onchange = function(nVal)
			MY_CombatText.nMaxAlpha = nVal
		end,
		autoenable = IsEnabled,
	})

	x = x + 180
	ui:append("Text", { x = x, y = y, text = _L["Hold time"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 70
	ui:append("WndSliderBox", {
		x = x, y = y, textfmt = function(val) return val .. _L["ms"] end,
		range = {700, 2500},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_CombatText.nTime * COMBAT_TEXT_TOTAL,
		onchange = function(nVal)
			MY_CombatText.nTime = nVal / COMBAT_TEXT_TOTAL
		end,
		autoenable = IsEnabled,
	})
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = x, y = y, text = _L["FadeIn time"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 70
	ui:append("WndSliderBox", {
		x = x, y = y, textfmt = function(val) return val .. _L["Frame"] end,
		range = {0, 15},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_CombatText.nFadeIn,
		onchange = function(nVal)
			MY_CombatText.nFadeIn = nVal
		end,
		autoenable = IsEnabled,
	})

	x = x + 180
	ui:append("Text", { x = x, y = y, text = _L["FadeOut time"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 70
	ui:append("WndSliderBox", {
		x = x, y = y, textfmt = function(val) return val .. _L["Frame"] end,
		rang = {0, 15},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_CombatText.nFadeOut,
		onchange = function(nVal)
			MY_CombatText.nFadeOut = nVal
		end,
		autoenable = IsEnabled,
	})
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = x, y = y, text = _L["Font Size"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 70
	ui:append("WndSliderBox", {
		x = x, y = y, textfmt = function(val) return (val / 100) .. _L["times"] end,
		range = {50, 200},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_CombatText.fScale * 100,
		onchange = function(nVal)
			MY_CombatText.fScale = nVal / 100
			COMBAT_TEXT_TRAJECTORY = CombatText.TrajectoryCount()
		end,
		autoenable = IsEnabled,
	})
	y = y + deltaY

	x = X
	ui:append("Text", { x = x, y = y, text = _L["Circle Style"], font = 27, autoenable = IsEnabled })
	x = x + 70
	ui:append("WndRadioBox", {
		x = x, y = y + 5, text = _L["hit feel"],
		group = "style",
		checked = MY_CombatText.nStyle == 0,
		oncheck = function()
			MY_CombatText.nStyle = 0
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[0]
		end,
		autoenable = IsEnabled,
	})
	x = x + 90

	ui:append("WndRadioBox", {
		x = x, y = y + 5, text = _L["low hit feel"],
		group = "style",
		checked = MY_CombatText.nStyle == 1,
		oncheck = function()
			MY_CombatText.nStyle = 1
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[1]
		end,
		autoenable = IsEnabled,
	})
	x = x + 90

	ui:append("WndRadioBox", {
		x = x, y = y + 5, text = _L["soft"],
		group = "style",
		checked = MY_CombatText.nStyle == 2,
		oncheck = function()
			MY_CombatText.nStyle = 2
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[2]
		end,
		autoenable = IsEnabled,
	})
	x = x + 60

	ui:append("WndRadioBox", {
		x = x, y = y + 5, text = _L["Scale only"],
		group = "style",
		checked = MY_CombatText.nStyle == 3,
		oncheck = function()
			MY_CombatText.nStyle = 3
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[3]
		end,
		autoenable = IsEnabled,
	})
	x = x + 90
	y = y + deltaY

	x = X
	ui:append("Text", { x = x, y = y, text = _L["Text Style"], font = 27, autoenable = IsEnabled })
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = x, y = y, text = _L["Skill Style"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 110
	ui:append("WndEditBox", {
		x = x, y = y, w = 250, h = 25, text = MY_CombatText.szSkill, limit = 30,
		onchange = function(szText)
			MY_CombatText.szSkill = szText
		end,
		autoenable = IsEnabled,
	})
	x = x + 250
	if MY_CombatText.bCritical then
		x = x + 10
		ui:append("Text", { x = x, y = y, text = _L["critical beat"], autoenable = IsEnabled }) --会心伤害
		x = x + 70
		ui:append("Shadow", {
			x = x, y = y + 8, color = MY_CombatText.tCriticalC, w = 15, h = 15,
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_CombatText.tCriticalC = { r, g, b }
					XGUI(this):color(r, g, b)
				end)
			end,
			autoenable = IsEnabled,
		})
	end
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = x, y = y, text = _L["Damage Style"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 110
	ui:append("WndEditBox", {
		x = x, y = y, w = 250, h = 25, text = MY_CombatText.szDamage, limit = 30,
		onchange = function(szText)
			MY_CombatText.szDamage = szText
		end,
		autoenable = IsEnabled,
	})
	x = x + 250
	if MY_CombatText.bCritical then
		x = x + 10
		ui:append("Text", { x = x, y = y, text = _L["critical beaten"], autoenable = IsEnabled }) --会心承伤
		x = x + 70
		ui:append("Shadow", {
			x = x, y = y + 8, color = MY_CombatText.tCriticalB, w = 15, h = 15,
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_CombatText.tCriticalB = { r, g, b }
					XGUI(this):color(r, g, b)
				end)
			end,
			autoenable = IsEnabled,
		})
	end
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = 10, y = y, text = _L["Therapy Style"], color = { 255, 255, 200 }, autoenable = IsEnabled })
	x = x + 110
	ui:append("WndEditBox", {
		x = x, y = y, w = 250, h = 25, text = MY_CombatText.szTherapy, limit = 30,
		onchange = function(szText)
			MY_CombatText.szTherapy = szText
		end,
		autoenable = IsEnabled,
	})
	x = x + 250
	if MY_CombatText.bCritical then
		x = x + 10
		ui:append("Text", { x = x, y = y, text = _L["critical heaten"], autoenable = IsEnabled }) --会心承疗
		x = x + 70
		ui:append("Shadow", {
			x = x, y = y + 8, color = MY_CombatText.tCriticalH, w = 15, h = 15,
			onclick = function()
				local this = this
				XGUI.OpenColorPicker(function(r, g, b)
					MY_CombatText.tCriticalH = { r, g, b }
					XGUI(this):color(r, g, b)
				end)
			end,
			autoenable = IsEnabled,
		})
	end
	y = y + deltaY

	x = X + 10
	ui:append("Text", { x = x, y = y, text = _L["CombatText Tips"], color = { 196, 196, 196 }, autoenable = IsEnabled })
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x, y = y, w = 190, text = _L["$name not me"], checked = MY_CombatText.bCasterNotI,
		oncheck = function(bCheck)
			MY_CombatText.bCasterNotI = bCheck
		end,
		autoenable = IsEnabled,
	})
	x = x + 190

	ui:append("WndCheckBox", {
		x = x, y = y, w = 110, text = _L["$sn shorten(2)"], checked = MY_CombatText.bSnShorten2,
		oncheck = function(bCheck)
			MY_CombatText.bSnShorten2 = bCheck
		end,
		autoenable = IsEnabled,
	})
	x = x + 110

	ui:append("WndCheckBox", {
		x = x, y = y, w = 140, text = _L["therapy effective only"], checked = MY_CombatText.bTherEffOnly,
		oncheck = function(bCheck)
			MY_CombatText.bTherEffOnly = bCheck
		end,
		autoenable = IsEnabled,
	})
	x = x + 140

	ui:append("WndButton", {
		x = x, y = y, text = _L["Font edit"],
		onclick = function()
			XGUI.OpenFontPicker(function(nFont)
				MY_CombatText.nFont = nFont
			end)
		end,
		autoenable = IsEnabled,
	})
	y = y + deltaY

	x = X
	ui:append("Text", { x = x, y = y, text = _L["Color edit"], font = 27, autoenable = IsEnabled })
	x = x + 10
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Critical Color"], checked = MY_CombatText.bCritical and true or false,
		oncheck = function(bCheck)
			MY_CombatText.bCritical = bCheck
			MY.OpenPanel()
			MY.SwitchTab("MY_CombatText", true)
		end,
		autoenable = IsEnabled,
	})
	y = y + deltaY

	x = X + 10
	local i = 0
	for k, v in pairs(MY_CombatText.col) do
		if k ~= SKILL_RESULT_TYPE.EFFECTIVE_THERAPY then
			ui:append("Text", { x = x + (i % 8) * 65, y = y + 30 * floor(i / 8), text = _L["CombatText Color " .. k], autoenable = IsEnabled })
			ui:append("Shadow", {
				x = x + (i % 8) * 65 + 35, y = y + 30 * floor(i / 8) + 8, color = v, w = 15, h = 15,
				onclick = function()
					local this = this
					XGUI.OpenColorPicker(function(r, g, b)
						MY_CombatText.col[k] = { r, g, b }
						XGUI(this):color(r, g, b)
					end)
				end,
				autoenable = IsEnabled,
			})
			i = i + 1
		end
	end

	if IsFileExist(COMBAT_TEXT_CONFIG) then
		ui:append("WndButton3", { x = 350, y = 0, text = _L["Load CombatText Config"] }):Click(CombatText.CheckEnable)
	end
end
MY.RegisterPanel("MY_CombatText", _L["CombatText"], _L["System"], 2041, {255, 255, 0}, PS)

local function GetPlayerID()
	local me = GetClientPlayer()
	if me then
		COMBAT_TEXT_PLAYERID = me.dwID
		-- MY.Debug("CombatText get player id " .. me.dwID, MY_DEBUG.LOG)
	else
		MY.Sysmsg({"CombatText get player id failed!!! try again"}, MY_DEBUG.ERROR)
		MY.DelayCall(1000, GetPlayerID)
	end
end
MY.RegisterEvent("LOADING_END.MY_CombatText", GetPlayerID) -- 很重要的优化
MY.RegisterEvent("ON_PVP_SHOW_SELECT_PLAYER.MY_CombatText", function()
	COMBAT_TEXT_PLAYERID = arg0
end)
MY.RegisterEvent("FIRST_LOADING_END.MY_CombatText", CombatText.CheckEnable)
