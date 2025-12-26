--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Skill')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 招式
--------------------------------------------------------------------------------

-- 获取对象运功状态
do local bNewAPI
function X.GetCharacterOTActionState(KObject)
	if not KObject then
		return
	end
	local nType, dwSkillID, dwSkillLevel, fCastPercent
	if X.IsNil(bNewAPI) then
		bNewAPI = pcall(function()
			if not KObject.GetSkillOTActionState then
				assert(false)
			end
		end)
	end
	if bNewAPI then
		nType, dwSkillID, dwSkillLevel, fCastPercent = KObject.GetSkillOTActionState()
	else
		nType, dwSkillID, dwSkillLevel, fCastPercent = KObject.GetSkillPrepareState()
		nType = KObject.GetOTActionState()
	end
	return nType, dwSkillID, dwSkillLevel, fCastPercent
end
end

function X.GetClientPlayerOTActionState()
	local KObject = X.GetClientPlayer()
	return X.GetCharacterOTActionState(KObject)
end

-- 获取对象当前是否可读条
-- (bool) X.CanCharacterOTAction([object KObject])
function X.CanCharacterOTAction(KObject)
	if not KObject then
		return
	end
	return KObject.nMoveState == MOVE_STATE.ON_STAND or KObject.nMoveState == MOVE_STATE.ON_FLOAT
end

function X.CanClientPlayerOTAction()
	local KObject = X.GetClientPlayer()
	return X.CanCharacterOTAction(KObject)
end

-- 通过技能名称获取技能信息
-- (table) X.GetSkillByName(szName)
do local CACHE
function X.GetSkillByName(szName)
	if not CACHE then
		local aCache, tLine, tExist = {}, nil, nil
		local Skill = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Skill', true)
		if Skill then
			for i = 1, Skill:GetRowCount() do
				tLine = Skill:GetRow(i)
				if tLine and tLine.dwIconID and tLine.fSortOrder and tLine.szName then
					tExist = aCache[tLine.szName]
					if not tExist or tLine.fSortOrder > tExist.fSortOrder then
						aCache[tLine.szName] = tLine
					end
				end
			end
		end
		CACHE = aCache
	end
	return CACHE[szName]
end
end

-- 判断技能名称是否有效
-- (bool) X.IsValidSkill(szName)
function X.IsValidSkill(szName)
	if X.GetSkillByName(szName)==nil then return false else return true end
end

-- 判断当前用户是否可用某个技能
-- (bool) X.CanUseSkill(number dwSkillID[, dwLevel])
do
local box
function X.CanUseSkill(dwSkillID, dwLevel)
	-- 判断技能是否有效 并将中文名转换为技能ID
	if type(dwSkillID) == 'string' then
		if not X.IsValidSkill(dwSkillID) then
			return false
		end
		dwSkillID = X.GetSkillByName(dwSkillID).dwSkillID
	end
	if not box or not box:IsValid() then
		box = X.UI.GetTempElement('Box', X.NSFormatString('{$NS}Lib__Skill'))
	end
	local me = X.GetClientPlayer()
	if me and box then
		if not dwLevel then
			if dwSkillID ~= 9007 then
				dwLevel = me.GetSkillLevel(dwSkillID)
			else
				dwLevel = 1
			end
		end
		if dwLevel > 0 then
			box:EnableObject(false)
			box:SetObjectCoolDown(1)
			box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
			UpdataSkillCDProgress(me, box)
			return box:IsObjectEnable() and not box:IsObjectCoolDown()
		end
	end
	return false
end
end

-- 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）
-- (string, number) X.GetSkillName(number dwSkillID[, number dwLevel])
do local SKILL_CACHE = {} -- 技能列表缓存 技能ID查技能名称图标
function X.GetSkillName(dwSkillID, dwLevel)
	local uLevelKey = dwLevel or '*'
	if not SKILL_CACHE[dwSkillID] then
		SKILL_CACHE[dwSkillID] = {}
	end
	if not SKILL_CACHE[dwSkillID][uLevelKey] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (X.StringFindW(tLine.szDesc, '_') == nil  or X.StringFindW(tLine.szDesc, '<') ~= nil)
		then
			SKILL_CACHE[dwSkillID][uLevelKey] = X.Pack(tLine.szName, tLine.dwIconID)
		else
			local szName = 'SKILL#' .. dwSkillID
			if dwLevel then
				szName = szName .. ':' .. dwLevel
			end
			SKILL_CACHE[dwSkillID][uLevelKey] = X.Pack(szName, 13)
		end
	end
	return X.Unpack(SKILL_CACHE[dwSkillID][uLevelKey])
end
end

function X.GetSkillIconID(dwSkillID, dwLevel)
	local nIconID = Table_GetSkillIconID(dwSkillID, dwLevel)
	if nIconID ~= -1 then
		return nIconID
	end
end

do
local KUNGFU_NAME_CACHE = {}
local KUNGFU_SHORT_NAME_CACHE = {}
function X.GetKungfuName(dwKungfuID, szType)
	if not KUNGFU_NAME_CACHE[dwKungfuID] then
		KUNGFU_NAME_CACHE[dwKungfuID] = Table_GetSkillName(dwKungfuID, 1) or ''
		KUNGFU_SHORT_NAME_CACHE[dwKungfuID] = X.StringSubW(KUNGFU_NAME_CACHE[dwKungfuID], 1, 2)
	end
	if szType == 'short' then
		return KUNGFU_SHORT_NAME_CACHE[dwKungfuID]
	else
		return KUNGFU_NAME_CACHE[dwKungfuID]
	end
end
end

do
local CACHE = {}
local REPLACE = {}
local function OnSkillReplace()
	CACHE = {}
	REPLACE[arg0] = arg1
	REPLACE[arg1] = nil
end
RegisterEvent('ON_SKILL_REPLACE', OnSkillReplace)
RegisterEvent('CHANGE_SKILL_ICON', OnSkillReplace)

-- 获取一个心法的技能列表
-- X.GetKungfuSkillList(dwKungfuID)
-- 获取一个套路的技能列表
-- X.GetKungfuSkillList(dwKungfuID, dwMountKungfu)
function X.GetKungfuSkillList(dwKungfuID, dwMountKungfu)
	if not dwMountKungfu then
		dwMountKungfu = 0
	end
	if not (CACHE[dwKungfuID] and CACHE[dwKungfuID][dwMountKungfu]) then
		local aSkillID
		if not X.IsEmpty(dwMountKungfu) then -- 获取一个套路的技能列表
			if X.IsFunction(_G.Table_GetNewKungfuSkill) then -- 兼容旧版
				aSkillID = _G.Table_GetNewKungfuSkill(dwKungfuID, dwMountKungfu)
					or _G.Table_GetKungfuSkillList(dwMountKungfu)
			else
				aSkillID = Table_GetKungfuSkillList(dwMountKungfu, dwKungfuID)
			end
		else -- 获取一个心法的技能列表 遍历该心法的所有套路
			if X.IsFunction(_G.Table_GetNewKungfuSkill) and X.IsFunction(_G.Table_GetKungfuSkillList) then -- 兼容旧版
				aSkillID = _G.Table_GetKungfuSkillList(dwKungfuID)
			else
				aSkillID = {}
				for _, dwMKungfuID in ipairs(X.GetMKungfuList(dwKungfuID)) do
					for _, dwSkillID in ipairs(X.GetKungfuSkillList(dwKungfuID, dwMKungfuID)) do
						table.insert(aSkillID, dwSkillID)
					end
				end
			end
		end
		for i, dwSkillID in ipairs(aSkillID) do
			if REPLACE[dwSkillID] then
				aSkillID[i] = REPLACE[dwSkillID]
			end
		end
		if not CACHE[dwKungfuID] then
			CACHE[dwKungfuID] = {}
		end
		CACHE[dwKungfuID][dwMountKungfu] = aSkillID or {}
	end
	return CACHE[dwKungfuID][dwMountKungfu]
end
end

-- 获取内功心法子套路列表（P面板左侧每列标题即为套路名）
do local CACHE = {}
function X.GetMKungfuList(dwKungfuID)
	if not CACHE[dwKungfuID] then
		CACHE[dwKungfuID] = Table_GetMKungfuList(dwKungfuID) or X.CONSTANT.EMPTY_TABLE
	end
	return CACHE[dwKungfuID]
end
end

do local CACHE = {}
-- 获取门派对应心法ID列表
---@param dwForceID number @要获取的门派ID
---@return number[] @门派对应的心法ID列表
function X.GetForceKungfuList(dwForceID)
	if not CACHE[dwForceID] then
		if X.IsFunction(ForceIDToKungfuIDs) then
			CACHE[dwForceID] = ForceIDToKungfuIDs(dwForceID)
		elseif X.IsFunction(_G.Table_GetSkillSchoolKungfu) then
			-- 这个API真是莫名其妙，明明是Force-Kungfu对应表，标题非写成School-Kungfu对应表
			CACHE[dwForceID] = _G.Table_GetSkillSchoolKungfu(dwForceID) or {}
		else
			local aKungfuList = {}
			local SkillSchoolKungfu = X.GetGameTable('SkillSchoolKungfu', true)
			if SkillSchoolKungfu then
				local tLine = SkillSchoolKungfu:Search(dwForceID)
				if tLine then
					local szKungfu = tLine.szKungfu
					for s in string.gmatch(szKungfu, '%d+') do
						local dwID = tonumber(s)
						if dwID then
							table.insert(aKungfuList, dwID)
						end
					end
				end
			else
				for _, v in ipairs(X.CONSTANT.KUNGFU_LIST) do
					if v.dwForceID == dwForceID then
						table.insert(aKungfuList, v.dwID)
					end
				end
			end
			CACHE[dwForceID] = aKungfuList
		end
	end
	return CACHE[dwForceID]
end
end

do local CACHE = {}
function X.GetSchoolForceID(dwSchoolID)
	if not CACHE[dwSchoolID] then
		if X.IsFunction(_G.Table_SchoolToForce) then
			CACHE[dwSchoolID] = _G.Table_SchoolToForce(dwSchoolID) or 0
		else
			local ForceToSchool = X.GetGameTable('ForceToSchool', true)
			if ForceToSchool then
				local nCount = ForceToSchool:GetRowCount()
				local dwForceID = 0
				for i = 1, nCount do
					local tLine = ForceToSchool:GetRow(i)
					if dwSchoolID == tLine.dwSchoolID then
						dwForceID = tLine.dwForceID
					end
				end
				CACHE[dwSchoolID] = dwForceID or 0
			end
		end
	end
	return CACHE[dwSchoolID]
end
end

function X.GetPlayerSkillList(tar)
	local aSchoolID, aSkillID = tar.GetSchoolList(), {}
	for _, dwSchoolID in ipairs(aSchoolID) do
		local dwForceID = X.GetSchoolForceID(dwSchoolID)
		local aKungfuID = X.GetForceKungfuList(dwForceID)
		for _, dwKungfuID in ipairs(aKungfuID) do
			for _, dwSkillID in ipairs(X.GetKungfuSkillList(dwKungfuID)) do
				table.insert(aSkillID, dwSkillID)
			end
		end
	end
	return aSkillID
end

do
local LIST, LIST_ALL
function X.GetSkillMountList(bIncludePassive)
	if not LIST then
		LIST, LIST_ALL = {}, {}
		local me = X.GetClientPlayer()
		local aList = X.GetPlayerSkillList(me)
		for _, dwID in ipairs(aList) do
			local nLevel = me.GetSkillLevel(dwID)
			if nLevel > 0 then
				local KSkill = GetSkill(dwID, nLevel)
				if not KSkill.bIsPassiveSkill then
					table.insert(LIST, dwID)
				end
				table.insert(LIST_ALL, dwID)
			end
		end
	end
	return bIncludePassive and LIST_ALL or LIST
end

local function onCacheExpired()
	LIST, LIST_ALL = nil, nil
end
X.RegisterEvent('ON_SKILL_REPLACE', onCacheExpired)
X.RegisterEvent('SKILL_MOUNT_KUNG_FU', onCacheExpired)
X.RegisterEvent('SKILL_UNMOUNT_KUNG_FU', onCacheExpired)
end

-- 判断两个心法ID是不是同一心法，藏剑视为单心法
function X.IsSameKungfu(dwID1, dwID2)
	if dwID1 == dwID2 then
		return true
	end
	if X.CONSTANT.KUNGFU_FORCE_TYPE[dwID1] == X.CONSTANT.FORCE_TYPE.CANG_JIAN
	and X.CONSTANT.KUNGFU_FORCE_TYPE[dwID2] == X.CONSTANT.FORCE_TYPE.CANG_JIAN then
		return true
	end
	return false
end

do
local SKILL_CACHE = setmetatable({}, { __mode = 'v' })
local SKILL_PROXY = setmetatable({}, { __mode = 'v' })
local function reject() assert(false, 'Modify skill info from X.GetSkill is forbidden!') end
function X.GetSkill(dwID, nLevel)
	if nLevel == 0 then
		return
	end
	local KSkill = GetSkill(dwID, nLevel)
	if not KSkill then
		return
	end
	local szKey = dwID .. '#' .. nLevel
	if not SKILL_CACHE[szKey] or not SKILL_PROXY[szKey] then
		SKILL_CACHE[szKey] = {
			szKey = szKey,
			szName = X.GetSkillName(dwID, nLevel),
			dwID = dwID,
			nLevel = nLevel,
			bLearned = nLevel > 0,
			nIcon = Table_GetSkillIconID(dwID, nLevel),
			dwExtID = X.Table.GetSkillExtCDID(dwID),
			bFormation = Table_IsSkillFormation(dwID, nLevel),
		}
		SKILL_PROXY[szKey] = setmetatable({}, { __index = SKILL_CACHE[szKey], __newindex = reject })
	end
	return KSkill, SKILL_PROXY[szKey]
end
end

do
local SKILL_SURFACE_NUM = {}
local function OnChangeSkillSurfaceNum()
	SKILL_SURFACE_NUM[arg0] = arg1
end
RegisterEvent('CHANGE_SKILL_SURFACE_NUM', OnChangeSkillSurfaceNum)
local function GetSkillCDProgress(dwID, nLevel, dwCDID, KObject)
	if dwCDID then
		return KObject.GetSkillCDProgress(dwID, nLevel, dwCDID)
	else
		return KObject.GetSkillCDProgress(dwID, nLevel)
	end
end
function X.GetSkillCDProgress(KObject, dwID, nLevel, bIgnorePublic)
	if not X.IsUserdata(KObject) then
		KObject, dwID, nLevel = X.GetClientPlayer(), KObject, dwID
	end
	if not nLevel then
		nLevel = KObject.GetSkillLevel(dwID)
	end
	if not nLevel then
		return
	end
	local KSkill, info = X.GetSkill(dwID, nLevel)
	if not KSkill or not info then
		return
	end
	-- # 更新CD相关的所有东西
	-- -- 附加技能CD
	-- if info.dwExtID then
	-- 	info.skillExt = X.GetTargetSkill(KObject, info.dwExtID)
	-- end
	-- 充能和透支技能CD刷新
	local nCDMaxCount, dwCDID = KObject.GetCDMaxCount(dwID)
	local nODMaxCount, dwODID = KObject.GetCDMaxOverDraftCount(dwID)
	local _, bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum, bPublic
	if nCDMaxCount > 1 then -- 充能技能CD刷新
		szType = 'CHARGE'
		nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, dwCDID, KObject))
		nInterval = KObject.GetCDInterval(dwCDID)
		nTotal = nInterval
		nLeft, nCount = KObject.GetCDLeft(dwCDID)
		bCool = nLeft > 0
		nCount = nCDMaxCount - nCount
		nMaxCount = nCDMaxCount
	elseif nODMaxCount > 1 then -- 透支技能CD刷新
		szType = 'OVERDRAFT'
		bCool, nLeft, nTotal, nCount, bPublic = GetSkillCDProgress(dwID, nLevel, dwODID, KObject)
		nInterval = KObject.GetCDInterval(dwODID)
		nMaxCount, nCount = KObject.GetOverDraftCoolDown(dwODID)
		if nCount == nMaxCount then -- 透支用完了显示CD
			bCool, nLeft, nTotal, _, bPublic = GetSkillCDProgress(dwID, nLevel, nil, KObject)
		else
			bCool, nLeft, nTotal = false, select(2, GetSkillCDProgress(dwID, nLevel, nil, KObject))
		end
	else -- 普通技能CD刷新
		szType = 'NORMAL'
		if bIgnorePublic then
			local dwGCDID = KSkill.GetPublicCoolDown()
			nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, dwGCDID, KObject))
		else
			nLeft, nTotal, nCount, bPublic = select(2, GetSkillCDProgress(dwID, nLevel, nil, KObject))
		end
		bCool = nLeft > 0
		nInterval = nTotal
		nCount, nMaxCount = bCool and 1 or 0, 1
	end
	if bPublic then
		szType = 'PUBLIC'
	end
	nSurfaceNum = SKILL_SURFACE_NUM[dwID]

	-- -- 指定BUFF存在时技能显示特定特效的需求
	-- local tLine = Table_GetSkillEffectBySkill(dwID)
	-- if tLine then
	-- 	local bShow = not not KObject.GetBuff(tLine.dwBuffID, 0)
	-- 	if bShow then
	-- 		if tLine.bAnimate then
	-- 			hBox:SetExtentAnimate(tLine.szUITex, tLine.nFrame)
	-- 		else
	-- 			hBox:SetExtentImage(tLine.szUITex, tLine.nFrame)
	-- 		end
	-- 	else
	-- 		hBox:ClearExtentAnimate()
	-- 	end
	-- end
	return bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum
end
end

-- 秘笈是否激活 全名/短名
do
local RECIPE_CACHE = {}
local function onRecipeUpdate()
	RECIPE_CACHE = {}
end
X.RegisterEvent({'SYNC_ROLE_DATA_END', 'SKILL_UPDATE', 'SKILL_RECIPE_LIST_UPDATE'}, onRecipeUpdate)

local function GetShortName(sz) -- 获取秘笈短名
	local nStart, nEnd = string.find(sz, '·')
	return nStart and X.StringReplaceW(string.sub(sz, nEnd + 1), _L['>'], '')
end

function X.IsRecipeActive(szRecipeName)
	local me = X.GetClientPlayer()
	if not RECIPE_CACHE[szRecipeName] then
		if not me then
			return
		end

		for id, lv in pairs(me.GetAllSkillList())do
			for _, info in pairs(me.GetSkillRecipeList(id, lv) or {}) do
				local t = Table_GetSkillRecipe(info.recipe_id , info.recipe_level)
				if t and (szRecipeName == t.szName or szRecipeName == GetShortName(t.szName)) then
					RECIPE_CACHE[szRecipeName] = info.active and 1 or 0
					break
				end
			end

			if RECIPE_CACHE[szRecipeName] then
				break
			end
		end

		if not RECIPE_CACHE[szRecipeName] then
			RECIPE_CACHE[szRecipeName] = 0
		end
	end

	return RECIPE_CACHE[szRecipeName] == 1
end
end

-- 根据技能 ID 获取引导帧数，非引导技能返回 nil
-- (number) X.GetChannelSkillFrame(number dwSkillID, number nLevel)
function X.GetChannelSkillFrame(dwSkillID, nLevel)
	local skill = GetSkill(dwSkillID, nLevel)
	if skill then
		return skill.nChannelFrame
	end
end

---获取当前心法是否为移动端心法
---@return boolean @是否是移动端心法
function X.IsClientPlayerMountMobileKungfu()
	return IsMobileKungfu and IsMobileKungfu() or false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
