--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Homeland')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local HL_INFO_CACHE = {}
local HL_INFO_CALLBACK = {}
local function FindHLInfo(aList, tQuery)
	for _, info in ipairs(aList) do
		if tQuery.dwMapID and tQuery.nCopyIndex
		and tQuery.dwMapID == info.dwMapID and tQuery.nCopyIndex == info.nCopyIndex then
			return info
		end
		if tQuery.dwCenterID and tQuery.dwMapID and tQuery.nLineIndex
		and tQuery.dwCenterID == info.dwCenterID and tQuery.dwMapID == info.dwMapID and tQuery.nLineIndex == info.nLineIndex then
			return info
		end
	end
end

local GetRelationCenter = _G.GetRelationCenter or _G.HomeLand_GetRelationCenter
X.RegisterEvent('HOME_LAND_RESULT_CODE_INT', 'LIB#HL', function()
	local nResultType = arg0
	if nResultType == X.CONSTANT.HOMELAND_RESULT_CODE.APPLY_COMMUNITY_INFO then -- 申请分线详情
		local dwMapID, nCopyIndex, dwCenterID, nLineIndex = arg1, arg2, arg3, arg4
		local szCenterName
		for _, info in ipairs(X.IsFunction(GetRelationCenter) and GetRelationCenter(dwCenterID) or X.CONSTANT.EMPTY_TABLE) do
			if info.dwCenterID == dwCenterID then
				szCenterName = info.szCenterName
			end
		end
		table.insert(HL_INFO_CACHE, X.FreezeTable({
			dwMapID = dwMapID,
			nCopyIndex = nCopyIndex,
			dwCenterID = dwCenterID,
			szCenterName = szCenterName,
			nLineIndex = nLineIndex,
		}))
		for i, v in X.ipairs_r(HL_INFO_CALLBACK) do
			local info = FindHLInfo(HL_INFO_CACHE, v.tQuery)
			if info then
				X.SafeCall(v.fnCallback, info)
				table.remove(HL_INFO_CALLBACK, i)
			end
		end
	end
end)

local ApplyCommunityInfo = _G.HomeLand_ApplyCommunityInfo
function X.GetHLLineInfo(tQuery, fnCallback)
	local info = FindHLInfo(HL_INFO_CACHE, tQuery)
	if info then
		X.SafeCall(fnCallback, info)
		return info
	end
	if X.IsFunction(ApplyCommunityInfo) and tQuery.dwMapID and tQuery.nCopyIndex then
		table.insert(HL_INFO_CALLBACK, {
			tQuery = tQuery,
			fnCallback = fnCallback,
		})
		if tQuery.nLineIndex then
			ApplyCommunityInfo(tQuery.dwMapID, tQuery.nCopyIndex, tQuery.nLineIndex)
		else
			ApplyCommunityInfo(tQuery.dwMapID, tQuery.nCopyIndex)
		end
	end
end
end

do local CACHE = {}
function X.GetFurnitureInfo(szKey, oVal)
	if szKey == 'nRepresentID' then
		szKey = 'dwModelID'
	end
	if not CACHE[szKey] then
		CACHE[szKey] = {}
		local HomelandFurnitureInfo = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('HomelandFurnitureInfo', true)
		if HomelandFurnitureInfo then
			for i = 2, HomelandFurnitureInfo:GetRowCount() do
				local tLine = HomelandFurnitureInfo:GetRow(i)
				if tLine and tLine[szKey] then
					CACHE[szKey][tLine[szKey]] = X.RecursiveFreezeTable(tLine)
				end
			end
		end
	end
	return CACHE[szKey][oVal]
end
end

do
local GetNearbyFurnitureInfoList = _G.GetNearbyFurnitureInfoList
local HomeLand_GetFurniture2GameID = _G.HomeLand_GetFurniture2GameID
function X.GetNearFurniture(nDis)
	if not nDis then
		nDis = 256
	end
	local nPlaneDis = nDis / 32
	local aFurniture, tID = {}, {}
	local me = X.GetClientPlayer()
	if X.IsFunction(GetNearbyFurnitureInfoList) and X.IsFunction(HomeLand_GetFurniture2GameID) then
		for _, p in ipairs(GetNearbyFurnitureInfoList('ui get objects info v_0', nDis)) do
			if X.GetCharacterDistance(me, p, 'plane') <= nPlaneDis then
				local dwID = X.NumberBitShl(p.BaseId, 32, 64) + p.InstID
				local info = not tID[dwID] and X.GetFurnitureInfo('nRepresentID', p.RepresentID)
				if info then
					info = setmetatable(p, { __index = info })
					info.dwID = dwID
					info.nInstID = p.InstID
					info.nBaseID = p.BaseId
					info.nGameID = HomeLand_GetFurniture2GameID(p.RepresentID)
					table.insert(aFurniture, info)
					tID[dwID] = true
				end
			end
		end
	end
	return aFurniture
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
