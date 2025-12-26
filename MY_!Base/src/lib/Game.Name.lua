--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Name')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local CACHE = {}

---@class GetNameOption @获取名称通用参数
---@field eShowID '"auto"' | '"always"' | '"never"' @是否显示ID
---@field eShowEmployer '"none"' | '"auto"' | '"prefix"' | '"suffix"' @是否显示所有者
---@field bShowSuffix boolean @是否显示转服后缀
---@field bShowServerName boolean @是否显示跨服后缀

-- 标准化查询参数
---@param tOption GetNameOption | nil @传入的参数
---@return GetNameOption @标准化之后的参数
local function StandardizeOption(tOption)
	if not tOption then
		tOption = {}
	end
	if not tOption.eShowID then
		tOption.eShowID = 'auto'
	end
	if not tOption.eShowEmployer then
		tOption.eShowEmployer = 'auto'
	end
	if tOption.bShowSuffix == nil then
		tOption.bShowSuffix = true
	end
	if tOption.bShowServerName == nil then
		tOption.bShowServerName = true
	end
	return tOption
end

local function FormatShowName(szName, szID, eShowID)
	if szName == '' then
		szName = nil
	end
	if eShowID == 'never' then
		return szName
	end
	if not szName then
		return szID
	end
	if eShowID == 'auto' then
		return szName
	end
	if eShowID == 'always' then
		return szName .. '(' .. szID .. ')'
	end
end

local function CacheSet(szCacheID, xKey, szName)
	if not CACHE[szCacheID] then
		CACHE[szCacheID] = X.CreateCache('LIB#NameCache#' .. szCacheID, 'v')
	end
	CACHE[szCacheID][xKey] = {szName}
end

local function CacheGet(szCacheID, xKey)
	return CACHE[szCacheID]
		and CACHE[szCacheID][xKey]
		and CACHE[szCacheID][xKey][1]
		or nil
end

-- 获取指定玩家名称
---@param dwID number @要获取的玩家角色ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetPlayerName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'PLAYER.' .. tOption.eShowID .. '.' .. (tOption.bShowSuffix and '1' or '0') .. (tOption.bShowServerName and '1' or '0')
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kPlayer = X.GetPlayer(dwID)
		if kPlayer then
			szName = kPlayer and kPlayer.szName
			if szName == '' then
				szName = nil
			else
				bCache = true
			end
		end
		if szName then
			if not tOption.bShowSuffix or not tOption.bShowServerName then
				local szBaseName, szSuffixName, szServerName = X.DisassemblePlayerName(szName)
				if not tOption.bShowSuffix then
					szSuffixName = ''
				end
				if not tOption.bShowServerName then
					szServerName = nil
				end
				szName = X.AssemblePlayerName(szBaseName, szSuffixName, szServerName)
			end
		end
		szName = FormatShowName(szName, 'P' .. dwID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- 获取指定系统角色名称
---@param dwID number @要获取的系统角色ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetNpcName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'NPC.' .. tOption.eShowID .. '.' .. tOption.eShowEmployer
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey, szCacheID)
	if not szName then
		local bCache = false
		local kNpc = X.GetNpc(dwID)
		if kNpc then
			szName = kNpc.szName
			if X.IsEmpty(szName) then
				szName = X.GetNpcTemplateName(kNpc.dwTemplateID, { eShowID = 'never' })
			end
			if kNpc.dwEmployer and kNpc.dwEmployer ~= 0 then
				if X.Table.IsSimplePlayer(kNpc.dwTemplateID) then -- 长歌影子
					szName = X.GetPlayerName(kNpc.dwEmployer, tOption)
				elseif not X.IsEmpty(szName) then
					local szEmpName
					if tOption.eShowEmployer == 'auto' or tOption.eShowEmployer == 'prefix' or tOption.eShowEmployer == 'suffix' then
						local tEmpOption = X.Clone(tOption)
						tEmpOption.eShowID = 'never'
						if X.IsPlayer(kNpc.dwEmployer) then
							szEmpName = X.GetPlayerName(kNpc.dwEmployer, tEmpOption)
						else
							szEmpName = X.GetNpcName(kNpc.dwEmployer, tEmpOption)
						end
						if szEmpName then
							bCache = true
						else
							szEmpName = g_tStrings.STR_SOME_BODY
						end
					end
					if szEmpName then
						if tOption.eShowEmployer == 'prefix' or (tOption.eShowEmployer == 'auto' and not X.IsPartnerNpc(kNpc.dwTemplateID)) then
							local szBaseName, szSuffixName, szServerName = X.DisassemblePlayerName(szEmpName)
							szName = X.AssemblePlayerName(szBaseName .. g_tStrings.STR_PET_SKILL_LOG .. szName, szSuffixName, szServerName)
						else
							szName = szName .. g_tStrings.STR_CONNECT .. szEmpName
						end
					end
				end
			else
				bCache = true
			end
		end
		local szID = 'N' .. X.ConvertNpcID(dwID)
		if kNpc then
			szID = szID .. '@' .. kNpc.dwTemplateID
		end
		szName = FormatShowName(szName, szID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- 根据模板ID获取系统角色名称
---@param dwTemplateID number @要获取的系统角色模板ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetNpcTemplateName(dwTemplateID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'NPC_TEMPLATE.' .. tOption.eShowID
	local xKey = dwTemplateID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		szName = X.CONSTANT.NPC_NAME[dwTemplateID]
			and X.RenderTemplateString(X.CONSTANT.NPC_NAME[dwTemplateID])
			or Table_GetNpcTemplateName(dwTemplateID)
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		bCache = true
		szName = FormatShowName(szName, 'NT' .. dwTemplateID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- 根据模板ID获取交互物件名称
---@param dwTemplateID number @要获取的交互物件模板ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetDoodadTemplateName(dwTemplateID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'DOODAD_TEMPLATE.' .. tOption.eShowID
	local xKey = dwTemplateID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		szName = X.CONSTANT.DOODAD_NAME[dwTemplateID]
			and X.RenderTemplateString(X.CONSTANT.DOODAD_NAME[dwTemplateID])
			or Table_GetDoodadTemplateName(dwTemplateID)
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		bCache = true
		szName = FormatShowName(szName, 'DT' .. dwTemplateID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- 获取指定交互物件名称
---@param dwID number @要获取的交互物件ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetDoodadName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'DOODAD.' .. tOption.eShowID
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kDoodad = X.GetDoodad(dwID)
		if kDoodad then
			szName = X.Table.GetDoodadTemplateName(kDoodad.dwTemplateID)
			if szName then
				szName = szName:gsub('^%s*(.-)%s*$', '%1')
			end
			bCache = true
		end
		szName = FormatShowName(szName, 'D' .. dwID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- 获取指定目标名称
---@param dwType number @目标类型
---@param dwID number @目标ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetTargetName(dwType, dwID, tOption)
	if dwType == TARGET.NPC then
		return X.GetNpcName(dwID, tOption)
	end
	if dwType == TARGET.PLAYER then
		return X.GetPlayerName(dwID, tOption)
	end
	if dwType == TARGET.DOODAD then
		return X.GetDoodadName(dwID, tOption)
	end
end

-- 获取指定物品名称
---@param dwID number @要获取的物品ID
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetItemName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'ITEM.' .. tOption.eShowID
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kItem = X.GetItem(dwID)
		if kItem then
			szName = X.GetItemNameByItem(kItem)
			bCache = true
		end
		szName = FormatShowName(szName, 'I' .. dwID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- 获取指定物品信息名称
---@param dwTabType number @要获取的物品信息表类型
---@param dwTabIndex number @要获取的物品信息表下标
---@param nBookInfo? number @要获取的物品信息书籍信息
---@param tOption? GetNameOption @获取参数
---@return string | nil @获取成功返回名称，失败返回空
function X.GetItemInfoName(dwTabType, dwTabIndex, nBookInfo, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'ITEM_INFO.' .. tOption.eShowID
	local xKey = dwTabType .. ':' .. dwTabIndex .. ':' .. (nBookInfo or 0)
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kItemInfo = X.GetItemInfo(dwTabType, dwTabIndex)
		if kItemInfo then
			szName = X.GetItemNameByItemInfo(kItemInfo)
			bCache = true
		end
		local szID = dwTabType .. ':' .. dwTabIndex
		if nBookInfo then
			szID = szID .. ':' .. nBookInfo
		end
		szName = FormatShowName(szName, 'II' .. szID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
