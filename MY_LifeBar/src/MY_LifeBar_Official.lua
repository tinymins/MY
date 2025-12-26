--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 扁平血条 - 官方托管
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_LifeBar/MY_LifeBar_Official'
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local D = {}
local COUNTDOWN_CACHE = {}

local CACHE_ON_TOP, nTop = {}
local function ApplyCaptionOnTop(dwID)
	nTop = CACHE_ON_TOP[dwID]
	if not nTop then
		return
	end
	rlcmd('set caption on top ' .. dwID .. ' ' .. nTop)
end
local function SetCaptionOnTop(dwID, bTop)
	nTop = bTop and 1 or 0
	if CACHE_ON_TOP[dwID] == nTop then
		return
	end
	CACHE_ON_TOP[dwID] = nTop
	ApplyCaptionOnTop(dwID)
end

local CACHE_ZOOM_IN, nZoomIn = {}
local function ApplyCaptionZoomIn(dwID)
	nZoomIn = CACHE_ZOOM_IN[dwID]
	if not nZoomIn then
		return
	end
	rlcmd('set caption zoom in ' .. dwID .. ' ' .. nZoomIn)
end
local function SetCaptionZoomIn(dwID, bZoomIn)
	nZoomIn = bZoomIn and 1 or 0
	if CACHE_ZOOM_IN[dwID] == nZoomIn then
		return
	end
	CACHE_ZOOM_IN[dwID] = nZoomIn
	ApplyCaptionZoomIn(dwID)
end

local CACHE_EXTRA_TEXT, szExtraText = {}
local function ApplyCaptionExtraText(dwID)
	szExtraText = CACHE_EXTRA_TEXT[dwID]
	if not szExtraText then
		return
	end
	rlcmd('set caption extra text ' .. dwID .. ' ' .. szExtraText)
end
local function SetCaptionExtraText(dwID, szExtraText)
	if CACHE_EXTRA_TEXT[dwID] == szExtraText then
		return
	end
	CACHE_EXTRA_TEXT[dwID] = szExtraText
	ApplyCaptionExtraText(dwID)
end

local CACHE_CAPTION_COLOR, tColor = {}
local function RGB2Dword(nR, nG, nB, nA) return nA * 16777216 + nR * 65536 + nG * 256 + nB end
local function fxTarget(nR, nG, nB, nA) return math.ceil(255 - (255 - nR) * 0.3), math.ceil(255 - (255 - nG) * 0.3), math.ceil(255 - (255 - nB) * 0.3), nA end
local function fxDeath(nR, nG, nB, nA) return math.ceil(nR * 0.4), math.ceil(nG * 0.4), math.ceil(nB * 0.4), nA end
local function fxDeathTarget(nR, nG, nB, nA) return math.ceil(nR * 0.45), math.ceil(nG * 0.45), math.ceil(nB * 0.45), nA end
local function ApplyCaptionColor(dwID)
	tColor = CACHE_CAPTION_COLOR[dwID]
	if not tColor then
		return
	end
	local KTarget, dwColor = (X.IsPlayer(dwID) and X.GetPlayer or X.GetNpc)(dwID), tColor.dwColor
	if KTarget then
		local me = X.GetClientPlayer()
		if dwID == select(2, X.GetCharacterTarget(me)) then
			if KTarget.nMoveState == MOVE_STATE.ON_DEATH then
				dwColor = tColor.dwDeathTargetColor
			else
				dwColor = tColor.dwTargetColor
			end
		elseif KTarget.nMoveState == MOVE_STATE.ON_DEATH then
			dwColor = tColor.dwDeathColor
		end
	end
	rlcmd('set plugin caption color ' .. dwID .. ' 1 ' .. dwColor)
end
local function SetCaptionColor(dwID, nR, nG, nB)
	tColor = CACHE_CAPTION_COLOR[dwID]
	if tColor and tColor.nR == nR and tColor.nG == nG and tColor.nB == nB then
		return
	end
	tColor = {
		nR = nR,
		nG = nG,
		nB = nB,
		dwColor = RGB2Dword(nR, nG, nB, 255),
		dwTargetColor = RGB2Dword(fxTarget(nR, nG, nB, 255)),
		dwDeathColor = RGB2Dword(fxDeath(nR, nG, nB, 255)),
		dwDeathTargetColor = RGB2Dword(fxDeathTarget(nR, nG, nB, 255)),
	}
	CACHE_CAPTION_COLOR[dwID] = tColor
	ApplyCaptionColor(dwID)
end
X.RegisterEvent('TARGET_CHANGE', 'MY_LifeBar_Official', function()
	-- arg0: dwPrevID, arg1: dwPrevType, arg2: dwID, arg3: dwType
	local dwPrevID, dwID = arg0, arg2
	ApplyCaptionColor(dwPrevID)
	ApplyCaptionColor(dwID)
end)

local function ApplyCaption(dwID)
	ApplyCaptionOnTop(dwID)
	ApplyCaptionZoomIn(dwID)
	ApplyCaptionExtraText(dwID)
	ApplyCaptionColor(dwID)
end

local function ResetCaption(dwID)
	CACHE_ON_TOP[dwID] = nil
	CACHE_ZOOM_IN[dwID] = nil
	CACHE_EXTRA_TEXT[dwID] = nil
	CACHE_CAPTION_COLOR[dwID] = nil
	rlcmd('reset caption ' .. dwID)
end

function D.PrioritySorter(a, b)
	if not a.nPriority then
		return false
	end
	if not b.nPriority then
		return true
	end
	return a.nPriority < b.nPriority
end

local KTarget, aCountDown, nR, nG, nB
local tCountDownItem, szCountDownText, nCountDownSecond, fCountDownPercent
function D.DrawLifeBar(dwID)
	KTarget = (X.IsPlayer(dwID) and X.GetPlayer or X.GetNpc)(dwID)
	if not KTarget then
		return
	end
	aCountDown = COUNTDOWN_CACHE[dwID]
	nR, nG, nB = nil, nil, nil
	while aCountDown and #aCountDown > 0 do
		tCountDownItem, szCountDownText, nCountDownSecond, fCountDownPercent = aCountDown[1], nil, nil, nil
		-- 根据不同类型倒计时计算倒计时时间、文字
		if tCountDownItem.szType == 'BUFF' or tCountDownItem.szType == 'DEBUFF' then
			local KBuff = KTarget.GetBuff(tCountDownItem.dwBuffID, 0)
			if KBuff then
				nCountDownSecond = (KBuff.GetEndTime() - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
				szCountDownText = tCountDownItem.szText or X.GetBuffName(KBuff.dwID, KBuff.nLevel)
				if KBuff.nStackNum > 1 then
					szCountDownText = szCountDownText .. 'x' .. KBuff.nStackNum
				end
			end
		elseif tCountDownItem.szType == 'CASTING' then
			local nType, dwSkillID, dwSkillLevel, fCastPercent = X.GetCharacterOTActionState(KTarget)
			if dwSkillID == tCountDownItem.dwSkillID
			and (
				nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
				or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE
			) then
				fCountDownPercent = fCastPercent
				szCountDownText = tCountDownItem.szText or X.GetSkillName(dwSkillID, dwSkillLevel)
			end
		elseif tCountDownItem.szType == 'NPC' or tCountDownItem.szType == 'DOODAD' then
			szCountDownText = tCountDownItem.szText or ''
		else --if tData.szType == 'TIME' then
			if tCountDownItem.nLogicFrame then
				nCountDownSecond = (tCountDownItem.nLogicFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
			elseif tCountDownItem.nTime then
				nCountDownSecond = (tCountDownItem.nTime - GetTime()) / 1000
			end
			if nCountDownSecond > 0 then
				szCountDownText = tCountDownItem.szText or ''
			end
		end
		-- 剩余时间不大于零不需要显示
		if nCountDownSecond and nCountDownSecond <= 0 then
			nCountDownSecond = nil
		end
		-- 百分比不大于零不需要显示
		if fCountDownPercent and fCountDownPercent <= 0 then
			fCountDownPercent = nil
		end
		-- 如果是可用倒计时显示，中断剩余的判断
		if szCountDownText then
			if tCountDownItem.tColor then
				nR, nG, nB = unpack(tCountDownItem.tColor)
			end
			if not X.IsEmpty(szCountDownText) and not tCountDownItem.bHideProgress then
				if nCountDownSecond then
					szCountDownText = szCountDownText .. '_' .. X.FormatDuration(math.min(nCountDownSecond, 5999), 'PRIME')
				elseif fCountDownPercent then
					szCountDownText = szCountDownText .. '_' .. math.floor(fCountDownPercent * 100) .. '%'
				end
			end
			break
		end
		-- 如果没有找到可用倒计时，则移除该倒计时
		table.remove(aCountDown, 1)
	end
	if szCountDownText then
		SetCaptionOnTop(dwID, true)
		SetCaptionZoomIn(dwID, true)
		SetCaptionExtraText(dwID, szCountDownText)
		if nR and nG and nB then
			SetCaptionColor(dwID, nR, nG, nB)
		end
	elseif #aCountDown == 0 then
		COUNTDOWN_CACHE[dwID] = nil
		ResetCaption(dwID)
	end
end

X.BreatheCall('MY_LifeBar_Official', function()
	for dwID, _ in pairs(COUNTDOWN_CACHE) do
		D.DrawLifeBar(dwID)
	end
end)

function D.ProcessCountdown(dwID, szType, szKey, tData)
	if not COUNTDOWN_CACHE[dwID] then
		COUNTDOWN_CACHE[dwID] = {}
	end
	for i, p in X.ipairs_r(COUNTDOWN_CACHE[dwID]) do
		if p.szType == szType and p.szKey == szKey then
			table.remove(COUNTDOWN_CACHE[dwID], i)
		end
	end
	if tData then
		local tData = X.Clone(tData)
		if tData.col then
			local r, g, b = X.HumanColor2RGB(tData.col)
			if r and g and b then
				tData.tColor = {r, g, b}
			end
			tData.col = nil
		end
		tData.szType = szType
		tData.szKey = szKey
		table.insert(COUNTDOWN_CACHE[dwID], 1, tData)
		table.sort(COUNTDOWN_CACHE[dwID], D.PrioritySorter)
	elseif #COUNTDOWN_CACHE[dwID] == 0 then
		COUNTDOWN_CACHE[dwID] = nil
		ResetCaption(dwID)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_LifeBar_Official',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'ProcessCountdown'
			},
			root = D,
		},
	},
}
MY_LifeBar_Official = X.CreateModule(settings)
end

X.RegisterEvent({'PLAYER_ENTER_SCENE', 'NPC_ENTER_SCENE'}, 'MY_LifeBar_Official', function()
	local dwID = arg0
	X.DelayCall(function() ApplyCaption(dwID) end)
	X.DelayCall(200, function() ApplyCaption(dwID) end)
	X.DelayCall(500, function() ApplyCaption(dwID) end)
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
