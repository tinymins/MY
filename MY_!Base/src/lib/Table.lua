--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 查询全局配置表函数库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Table')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

X.Table = {}

function X.Table.GetCommonEnchantDesc(enchant_id)
	if X.IsFunction(_G.Table_GetCommonEnchantDesc) then
		return _G.Table_GetCommonEnchantDesc(enchant_id)
	end
	local CommonEnchant = X.GetGameTable('CommonEnchant', true)
	if CommonEnchant then
		local res = CommonEnchant:Search(enchant_id)
		if res then
			return res.desc
		end
	end
end

function X.Table.GetProfessionName(dwProfessionID)
	if X.IsFunction(_G.Table_GetProfessionName) then
		return _G.Table_GetProfessionName(dwProfessionID)
	end
	local szName = ''
	local ProfessionName = X.GetGameTable('ProfessionName', true)
	if ProfessionName then
		local tProfession = ProfessionName:Search(dwProfessionID)
		if tProfession then
			szName = tProfession.szName
		end
	end
	return szName
end

function X.Table.GetDoodadTemplateName(dwTemplateID)
	if X.IsFunction(_G.Table_GetDoodadTemplateName) then
		return _G.Table_GetDoodadTemplateName(dwTemplateID)
	end
	local szName = ''
	local DoodadTemplate = X.GetGameTable('DoodadTemplate', true)
	if DoodadTemplate then
		local tDoodad = DoodadTemplate:Search(dwTemplateID)
		if tDoodad then
			szName = tDoodad.szName
		end
	end
	return szName
end

function X.Table.IsTreasureBattleFieldMap(dwMapID)
	if X.IsFunction(_G.Table_IsTreasureBattleFieldMap) then
		return _G.Table_IsTreasureBattleFieldMap(dwMapID)
	end
	return false
end

function X.Table.GetTeamRecruit()
	if X.IsFunction(_G.Table_GetTeamRecruit) then
		return _G.Table_GetTeamRecruit()
	end
	local res = {}
	local TeamRecruit = X.GetGameTable('TeamRecruit', true)
	if TeamRecruit then
		local nCount = TeamRecruit:GetRowCount()
		for i = 2, nCount do
			local tLine = TeamRecruit:GetRow(i)
			local dwType = tLine.dwType
			local szTypeName = tLine.szTypeName

			if dwType > 0 then
				res[dwType] = res[dwType] or {Type=dwType, TypeName=szTypeName}
				res[dwType].bParent = true
				local dwSubType = tLine.dwSubType
				local szSubTypeName = tLine.szSubTypeName
				if dwSubType > 0 then
					res[dwType][dwSubType] = res[dwType][dwSubType] or {SubType=dwSubType, SubTypeName=szSubTypeName}
					res[dwType][dwSubType].bParent = true
					table.insert(res[dwType][dwSubType], tLine)
				else
					table.insert(res[dwType], tLine)
				end
			end
		end
	end
	return res
end

function X.Table.IsSimplePlayer(dwTemplateID)
	if X.IsFunction(_G.Table_IsSimplePlayer) then
		return _G.Table_IsSimplePlayer(dwTemplateID)
	end
	local SimplePlayer = X.GetGameTable('SimplePlayer', true)
	if SimplePlayer then
		local tLine = SimplePlayer:Search(dwTemplateID)
		if tLine then
			return true
		end
	end
	return false
end

do
local cache = {}
function X.Table.GetSkillExtCDID(dwID)
	if X.IsFunction(_G.Table_GetSkillExtCDID) then
		return _G.Table_GetSkillExtCDID(dwID)
	end
	if cache[dwID] == nil then
		local SkillExtCDID = X.GetGameTable('SkillExtCDID', true)
		if SkillExtCDID then
			local tLine = SkillExtCDID:Search(dwID)
			cache[dwID] = tLine and tLine.dwExtID or false
		end
	end
	return cache[dwID] and cache[dwID] or nil
end
end

function X.Table.GetAllPartnerNpcInfo()
	if not Table_GetAllPartnerNpcInfo then
		return
	end
	return Table_GetAllPartnerNpcInfo()
end

X.NSLock(X.Table, X.NSFormatString('{$NS}.Table (table library)'))

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
