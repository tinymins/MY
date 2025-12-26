--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标选择增强替代官方TAB
-- @author   : Webster
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Target/MY_TargetSelect'
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetSelect'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TargetSelect__PUBG', { ['*'] = true })
--------------------------------------------------------------------------

local D = {}

function D.CalcFace(me, tar, nDis)
	local nX = tar.nX - me.nX
	local nY = tar.nY - me.nY
	local nFace =  me.nFaceDirection / 256 * 360
	local nDeg = 0
	if nY == 0 then
		if nX < 0 then
			nDeg = 180
		end
	elseif nX == 0 then
		if nY > 0 then
			nDeg = 90
		else
			nDeg = 270
		end
	else
		nDeg = math.deg(math.atan(nY / nX))
		if nX < 0 then
			nDeg = 180 + nDeg
		elseif nY < 0 then
			nDeg = 360 + nDeg
		end
	end
	local nAngle = nFace - nDeg
	if nAngle < -180 then
		nAngle = nAngle + 360
	elseif nAngle > 180 then
		nAngle = nAngle - 360
	end
	nAngle = math.abs(nAngle)
	if nAngle > 100 then
		return math.huge
	elseif nAngle < 5 then
		return -999
	else
		return nAngle
	end
end

local tJustList = {}
local nJustFrame = 0
local LOWER_DIS = 35
local tLowerNpc = {
	[12944] = true, -- 碧蝶
	[9998]  = true, -- 灵蛇
	[9999]  = true, -- 玉蟾
	[9997]  = true, -- 天蛛
	[9956]  = true, -- 圣蝎
	-- [46140] = true, -- 长歌影子 清绝影歌
	[46297] = true, -- 长歌影子 疏影横斜
	[48049] = true, --五毒苗疆生物
}

-- 获取两者之间的关系
-- 敌对返回 0 中立返回 1 友好返回 2
function D.GetRelation(dwID)
	local me = GetClientPlayer()
	if IsEnemy(me.dwID, dwID) then
		return 0
	-- elseif IsAlly(me.dwID, dwID)then
	-- 	return 2
	else
		return 1
	end
end

function D.UpdateRestrict()
	D.bRestrict = X.IsRestricted('MY_TargetSelect__PUBG') and X.IsInPubgMap()
end

function D.SearchTarget()
	if D.bRestrict then
		return
	end
	local nFrame = GetLogicFrameCount()
	if (nFrame - nJustFrame) > 12 then
		tJustList = {}
	end
	nJustFrame = nFrame
	local me = GetClientPlayer()
	local _, dwTarget = me.GetTarget()
	-- load player
	local tList, tList2 = {}, {}
	for _, v in ipairs(X.GetNearPlayer()) do
		if v.dwID == dwTarget or v.nMoveState == MOVE_STATE.ON_DEATH then
			-- skip current target
			-- IsAlly IsEnemy
		elseif IsEnemy(me.dwID, v.dwID) and not me.IsPlayerInMyParty(v.dwID) then
			local nDis = X.GetCharacterDistance(me, v)
			if  nDis > LOWER_DIS and not X.IsEmpty(tList) then
				-- need not far target
			else
				local item = { dwID = v.dwID, nType = TARGET.PLAYER }
				item.nSel = tJustList[v.dwID] or 0
				item.nForce = 1
				item.nDis = math.floor(nDis / 4)
				item.nHP = math.floor(10 * v.nCurrentLife / math.max(1, v.nMaxLife))
				item.nFace = D.CalcFace(me, v, nDis)
				item.nRelation = D.GetRelation(v.dwID)
				if (item.nDis == 0 or (item.nHP and item.nHP < 4)) and item.nFace == 0 then
					item.nForce = 0
				end
				if nDis > LOWER_DIS then
					table.insert(tList2, item)
				else
					table.insert(tList, item)
				end
			end
		end
	end
	local bEmptyPlayer = X.IsEmpty(tList)
	local bEmptyPlayer2 = X.IsEmpty(tList2)
	-- load npc
	if bEmptyPlayer then
		for _, v in ipairs(X.GetNearNpc()) do
			if v.dwID == dwTarget or v.nMoveState == MOVE_STATE.ON_DEATH or not v.IsSelectable() then
				-- skip current target
			elseif IsEnemy(me.dwID, v.dwID) or IsAlly(me.dwID, v.dwID) or IsNeutrality(me.dwID, v.dwID) then
				local nDis = X.GetCharacterDistance(me, v)
				if  nDis > LOWER_DIS and not X.IsEmpty(tList) then
					-- need not far target
				else
					local item = { dwID = v.dwID, nType = TARGET.NPC }
					item.nSel = tJustList[v.dwID] or 0
					item.nForce = 0
					item.nNpc = 0
					if GetNpcIntensity(v) ~= 4 then
						item.nNpc = item.nNpc + 1
					end
					-- 清歌绝影的影子=46140
					if v.dwTemplateID == 46140 then
						item.nRealType = TARGET.NPC
						item.nType = TARGET.PLAYER
						item.nForce = 0
						item.nNpc = 0
					end
					if tLowerNpc[v.dwTemplateID] then -- 降到最低的NPC 五毒宠物长歌影子之类的
						item.nForce = 2
					end
					------
					if IsNeutrality(me.dwID, v.dwID) then
						item.nNpc = item.nNpc + 1
					end
					item.nDis = math.floor(nDis / 4)
					item.nHP = math.floor(5 * v.nCurrentLife / math.max(1, v.nMaxLife))
					item.nFace = D.CalcFace(me, v, nDis)
					-- 如果是NPC并且面向在背后了 还大于10尺 就众生平等 不考虑是否敌对
					if item.nFace ~= math.huge and item.nDis > 10 then
						item.nRelation = math.huge
					else
						-- NPC 优先级 红 > 黄 = 绿
						item.nRelation = D.GetRelation(v.dwID)
					end
					if nDis > LOWER_DIS then
						table.insert(tList2, item)
					else
						table.insert(tList, item)
					end
				end
			end
		end
	end
	-- sort list
	if X.IsEmpty(tList) then
		tList = tList2
	end
	-- for _, v in ipairs(tList) do
	-- 	if v.dwID == 1073747661 or v.dwID == 1073747659 then
	-- 		Output(v)
	-- 	end
	-- end
	table.sort(tList, function(a, b)
		-- just list
		if a.nSel ~= b.nSel then
			return a.nSel < b.nSel
		end
		if a.nRelation ~= b.nRelation then
			return a.nRelation < b.nRelation
		end
		-- npc lower
		-- if a.nType ~= b.nType then
		-- 	return a.nType > b.nType
		-- end
		-- force lower
		if a.nForce ~= b.nForce  then
			return a.nForce < b.nForce
		end
		-- if (a.dwID == 1073747661 and b.dwID ==1073747659) then
		-- 	Output(123)
		-- end
		-- face
		if a.nFace and a.nFace ~= b.nFace and math.abs(a.nFace - b.nFace) > 5 then
			return a.nFace < b.nFace
		end
		-- npc
		if a.nNpc and b.nNpc and a.nNpc ~= b.nNpc then
			return a.nNpc < b.nNpc
		end
		-- near(<16, hp dis >= 40%)
		if a.nDis and a.nHp and a.nDis < 4 and b.nDis < 4 and math.abs(a.nDis - b.nDis) < 2 and math.abs(a.nHp - b.nHp) >= 3 then
			return a.nHp < b.nHp
		end
		-- dist
		if a.nDis and a.nDis ~= b.nDis then
			return a.nDis < b.nDis
		end
		-- nHp
		if a.nHp and a.nHp ~= b.nHp then
			return a.nHp < b.nHp
		end
		-- party
		-- if a.nParty then
		-- 	return a.nParty < b.nParty
		-- end
		return false
	end)
	if not X.IsEmpty(tList) then
		-- select first target
		local dwTarget = tList[1].dwID
		tJustList[dwTarget] = 1
		SetTarget(tList[1].nRealType or tList[1].nType, dwTarget)
	end
end

X.RegisterHotKey('MY_TargetSelect', _L['Smart select target'], function() D.SearchTarget() end, nil)

X.RegisterEvent('MY_RESTRICTION', 'MY_TargetSelect__PUBG', function()
	if arg0 and arg0 ~= 'MY_TargetSelect__PUBG' then
		return
	end
	D.UpdateRestrict()
end)
X.RegisterEvent('LOADING_END', D.UpdateRestrict)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
