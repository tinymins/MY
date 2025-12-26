--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Inventory')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 物品、物品存储格：身上、背包、仓库、帮会仓库
--------------------------------------------------------------------------------

-- 插件物品存储位置转换为官方物品存储位置
---@param dwBox number @物品存储格
---@param dwX number @存储格中指定物品下标
---@return number,number @官方存储格位置(dwBox),官方存储格中指定物品的下标(dwX)
local function GetOfficialInventoryBoxPos(dwBox, dwX)
	-- 帮会仓库格为虚拟位置，特殊处理
	if dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE1
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE2
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE3
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE4
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE5
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE6
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE7
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE8
	then
		local nPage = dwBox - X.CONSTANT.INVENTORY_INDEX.GUILD_BANK
		local nPageSize = INVENTORY_GUILD_PAGE_SIZE or 100
		return INVENTORY_GUILD_BANK or INVENTORY_INDEX.TOTAL + 1, nPage * nPageSize + dwX
	end
	return dwBox, dwX
end

-- 获取指定类型物品存储格位置列表
---@param eType number @物品存储格指定类型
---@return number[] @存储格位置列表
function X.GetInventoryBoxList(eType)
	-- 身上装备格
	if eType == X.CONSTANT.INVENTORY_TYPE.EQUIP then
		return X.Clone(X.CONSTANT.INVENTORY_EQUIP_LIST)
	end
	-- 背包格
	if eType == X.CONSTANT.INVENTORY_TYPE.PACKAGE then
		if X.IsInInventoryPackageLimitedMap() then
			return X.Clone(X.CONSTANT.INVENTORY_LIMITED_PACKAGE_LIST)
		end
		return X.Clone(X.CONSTANT.INVENTORY_PACKAGE_LIST)
	end
	-- 仓库格
	if eType == X.CONSTANT.INVENTORY_TYPE.BANK then
		local me, aList = X.GetClientPlayer(), {}
		for i = 1, me.GetBankPackageCount() + 1 do
			aList[i] = X.CONSTANT.INVENTORY_BANK_LIST[i]
		end
		return aList
	end
	-- 帮会仓库格（虚拟位置不可用于离线存储）
	if eType == X.CONSTANT.INVENTORY_TYPE.GUILD_BANK then
		return X.Clone(X.CONSTANT.INVENTORY_GUILD_BANK_LIST)
	end
	-- 原始背包格
	if eType == X.CONSTANT.INVENTORY_TYPE.ORIGIN_PACKAGE then
		return X.Clone(X.CONSTANT.INVENTORY_PACKAGE_LIST)
	end
	-- 额外背包格
	if eType == X.CONSTANT.INVENTORY_TYPE.LIMITED_PACKAGE then
		return X.Clone(X.CONSTANT.INVENTORY_LIMITED_PACKAGE_LIST)
	end
end

-- 获取指定物品存储格可存放物品数量（指定位置装备包的大小）
---@param dwBox number @物品存储格位置
---@return number @存储格可存放物品数量
function X.GetInventoryBoxSize(dwBox)
	-- 帮会仓库格为虚拟位置，特殊处理
	if dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE1
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE2
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE3
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE4
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE5
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE6
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE7
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE8
	then
		return 98
	end
	-- 其它格走接口获取
	local me = X.GetClientPlayer()
	return me.GetBoxSize(dwBox)
end

-- 获取指定物品存储格位置的物品对象
---@param me userdata @玩家对象
---@param dwBox number @物品存储格
---@param dwX number @存储格中指定物品下标
---@return userdata|nil @指定位置的物品，不存在则返回空
function X.GetInventoryItem(me, dwBox, dwX)
	dwBox, dwX = GetOfficialInventoryBoxPos(dwBox, dwX)
	return GetPlayerItem(me, dwBox, dwX)
end

-- 交換两个物品存储格位置的物品对象
---@param dwBox1 number @物品存储格1
---@param dwX1 number @存储格中指定物品1下标
---@param dwBox2 number @物品存储格2
---@param dwX2 number @存储格中指定物品2下标
function X.ExchangeInventoryItem(dwBox1, dwX1, dwBox2, dwX2)
	dwBox1, dwX1 = GetOfficialInventoryBoxPos(dwBox1, dwX1)
	dwBox2, dwX2 = GetOfficialInventoryBoxPos(dwBox2, dwX2)
	if (
		dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE1
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE2
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE3
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE4
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE_MIBAO
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.LIMITED_PACKAGE
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE1
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE2
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE3
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE4
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE5
	) and (
		dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE1
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE2
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE3
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE4
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE_MIBAO
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.LIMITED_PACKAGE
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE1
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE2
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE3
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE4
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE5
	) then
		local me = X.GetClientPlayer()
		if me then
			me.ExchangeItem(dwBox1, dwX1, dwBox2, dwX2)
			return
		end
	end
	OnExchangeItem(dwBox1, dwX1, dwBox2, dwX2)
end

-- 获取指定类型物品存储格空位总数
---@param eType number @物品存储格指定类型
---@return number @存储格空位总数
function X.GetInventoryEmptyItemCount(eType)
	local me, nCount = X.GetClientPlayer(), 0
	for _, dwBox in ipairs(X.GetInventoryBoxList(eType)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			if not X.GetInventoryItem(me, dwBox, dwX) then
				nCount = nCount + 1
			end
		end
	end
	return nCount
end

-- 获取指定类型物品存储格第一个空位位置
---@param eType number @物品存储格指定类型
---@return number,number @存储格第一个空位位置，已满返回空
function X.GetInventoryEmptyItemPos(eType)
	local me = X.GetClientPlayer()
	for _, dwBox in ipairs(X.GetInventoryBoxList(eType)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			if not X.GetInventoryItem(me, dwBox, dwX) then
				return dwBox, dwX
			end
		end
	end
end

-- 遍历指定类型物品存储格所有物品
---@param eType number @物品存储格指定类型
---@param fnIter function @遍历迭代器，返回0停止遍历
function X.IterInventoryItem(eType, fnIter)
	local me = X.GetClientPlayer()
	for _, dwBox in ipairs(X.GetInventoryBoxList(eType)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			local kItem = X.GetInventoryItem(me, dwBox, dwX)
			if kItem and fnIter(kItem, dwBox, dwX) == 0 then
				return
			end
		end
	end
end

do local CACHE = {}
-- 获取指定物品在指定类型的物品存储格中的总数量
---@param eType number @物品存储格指定类型
---@param dwTabType number @指定物品的表类型
---@param dwIndex number @指定物品的表下标
---@param nBookID number @指定物品为书籍情况下的书籍ID
---@return number @指定物品的总数量
function X.GetInventoryItemAmount(eType, dwTabType, dwIndex, nBookID)
	if not CACHE[eType] then
		CACHE[eType] = {}
	end
	local szKey = X.GetItemKey(dwTabType, dwIndex, nBookID)
	if not CACHE[eType][szKey] then
		local nAmount = 0
		X.IterInventoryItem(eType, function(kItem)
			if szKey == X.GetItemKey(kItem) then
				nAmount = nAmount + (kItem.bCanStack and kItem.nStackNum or 1)
			end
		end)
		CACHE[eType][szKey] = nAmount
	end
	return CACHE[eType][szKey]
end
X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE', 'LOADING_ENDING'}, 'LIB#GetInventoryItemAmount', function() CACHE = {} end)
end

-- 寻找物品位置
-- X.GetInventoryItemPos(eType, szName)
-- X.GetInventoryItemPos(eType, dwTabType, dwIndex, nBookID)
---@param eType number @物品存储格指定类型
---@param szName string @要使用的物品名称
---@param dwTabType number @要使用的物品表类型
---@param dwIndex number @要使用的物品表下标
---@param nBookID number @要使用的物品为书籍时的书籍ID
---@return number,number @物品坐标，找不到返回空
function X.GetInventoryItemPos(eType, dwTabType, dwIndex, nBookID)
	local dwRetBox, dwRetX = nil, nil
	if X.IsString(dwTabType) then
		X.IterInventoryItem(eType, function(kItem, dwBox, dwX)
			if X.GetItemName(kItem.dwID) == dwTabType then
				dwRetBox, dwRetX = dwBox, dwX
				return 0
			end
		end)
	else
		X.IterInventoryItem(eType, function(kItem, dwBox, dwX)
			if kItem.dwTabType == dwTabType and kItem.dwIndex == dwIndex then
				if kItem.nGenre == ITEM_GENRE.BOOK and kItem.nBookID ~= nBookID then
					return
				end
				dwRetBox, dwRetX = dwBox, dwX
				return 0
			end
		end)
	end
	return dwRetBox, dwRetX
end

-- 装备指定存储格的装备
---@param dwBox number @物品存储格
---@param dwX number @存储格中指定物品下标
function X.EquipInventoryItem(dwBox, dwX)
	local me = X.GetClientPlayer()
	local kItem = X.GetInventoryItem(me, dwBox, dwX)
	local szName = X.GetItemNameByUIID(kItem.nUiId)
	if szName == g_tStrings.tBulletDetail[BULLET_DETAIL.SNARE]
	or szName == g_tStrings.tBulletDetail[BULLET_DETAIL.BOLT] then
		for dwBulletX = 0, 15 do
			if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, dwBulletX) == nil then
				X.ExchangeInventoryItem(dwBox, dwX, INVENTORY_INDEX.BULLET_PACKAGE, dwBulletX)
				break
			end
		end
	else
		local dwEquipX = select(2, me.GetEquipPos(GetOfficialInventoryBoxPos(dwBox, dwX)))
		X.ExchangeInventoryItem(dwBox, dwX, INVENTORY_INDEX.EQUIP, dwEquipX)
	end
end

-- 使用物品
---@param dwBox number @物品存储格
---@param dwX number @存储格中指定物品下标
function X.UseInventoryItem(dwBox, dwX)
	dwBox, dwX = GetOfficialInventoryBoxPos(dwBox, dwX)
	OnUseItem(dwBox, dwX)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
