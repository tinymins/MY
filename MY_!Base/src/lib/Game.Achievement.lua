--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Achievement')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 获取成就基础信息
function X.GetAchievement(dwAchieveID)
	local Achievement = X.GetGameTable('Achievement', true)
	if Achievement then
		return Achievement:Search(dwAchieveID)
	end
end

-- 获取成就描述信息
function X.GetAchievementInfo(dwAchieveID)
	local AchievementInfo = X.GetGameTable('AchievementInfo', true)
	if AchievementInfo then
		return AchievementInfo:Search(dwAchieveID)
	end
end

-- 获取一个地图的成就列表（区分是否包含五甲）
local MAP_ACHI_NORMAL, MAP_ACHI_ALL
function X.GetMapAchievements(dwMapID, bWujia)
	if not MAP_ACHI_NORMAL then
		local tMapAchiNormal, tMapAchiAll = {}, {}
		local Achievement = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Achievement', true)
		if Achievement then
			local nCount = Achievement:GetRowCount()
			for i = 2, nCount do
				local tLine = Achievement:GetRow(i)
				if tLine and tLine.nVisible == 1 then
					for _, szID in ipairs(X.SplitString(tLine.szSceneID, '|', true)) do
						local dwID = tonumber(szID)
						if dwID then
							if tLine.dwGeneral == 1 then
								if not tMapAchiNormal[dwID] then
									tMapAchiNormal[dwID] = {}
								end
								table.insert(tMapAchiNormal[dwID], tLine.dwID)
							end
							if not tMapAchiAll[dwID] then
								tMapAchiAll[dwID] = {}
							end
							table.insert(tMapAchiAll[dwID], tLine.dwID)
						end
					end
				end
			end
		end
		MAP_ACHI_NORMAL, MAP_ACHI_ALL = tMapAchiNormal, tMapAchiAll
	end
	if bWujia then
		return X.Clone(MAP_ACHI_ALL[dwMapID])
	end
	return X.Clone(MAP_ACHI_NORMAL[dwMapID])
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
