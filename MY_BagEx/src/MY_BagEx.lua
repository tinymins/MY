--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背包整理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {
	-- 物品排序顺序
	aGenre = {
		[ITEM_GENRE.TASK_ITEM] = 1,
		[ITEM_GENRE.EQUIPMENT] = 2,
		[ITEM_GENRE.BOOK] = 3,
		[ITEM_GENRE.POTION] = 4,
		[ITEM_GENRE.MATERIAL] = 5,
	},
	aSub = {
		[EQUIPMENT_SUB.HORSE] = 1,
		[EQUIPMENT_SUB.PACKAGE] = 2,
		[EQUIPMENT_SUB.MELEE_WEAPON] = 3,
		[EQUIPMENT_SUB.RANGE_WEAPON] = 4,
	},
}

-- 背包整理格子排序函数
function D.ItemSorter(a, b)
	-- 空白格子靠后
	if not a.dwID then
		return false
	end
	if not b.dwID then
		return true
	end
	-- 类型不同按类型排序
	local nGenreA = D.aGenre[a.nGenre] or (100 + a.nGenre)
	local nGenreB = D.aGenre[b.nGenre] or (100 + b.nGenre)
	if nGenreA ~= nGenreB then
		return nGenreA < nGenreB
	end
	-- 相同物品按堆叠数量排序
	if a.nUiId == b.nUiId and b.bCanStack then
		return a.nStackNum > b.nStackNum
	end
	-- 装备类比较
	if a.nGenre == ITEM_GENRE.EQUIPMENT then
		local nSubA = D.aSub[a.nSub] or (100 + a.nSub)
		local nSubB = D.aSub[b.nSub] or (100 + b.nSub)
		if nSubA == nSubB then
			-- 武器按照类型排列
			if b.nSub == EQUIPMENT_SUB.MELEE_WEAPON or b.nSub == EQUIPMENT_SUB.RANGE_WEAPON then
				if a.nDetail ~= b.nDetail then
					return a.nDetail < b.nDetail
				end
			end
			-- 包裹容量大的排在后面
			if b.nSub == EQUIPMENT_SUB.PACKAGE then
				if a.nCurrentDurability ~= b.nCurrentDurability then
					return a.nCurrentDurability > b.nCurrentDurability
				end
			end
		end
	end
	-- 处理品质比较
	if a.nQuality ~= b.nQuality then
		return a.nQuality > b.nQuality
	end
	-- 按照表下标排序
	if a.dwTabType ~= b.dwTabType then
		return a.dwTabType < b.dwTabType
	end
	return a.dwIndex < b.dwIndex
end

function D.IsSameItem(item1, item2)
	if (not item1 or not item1.dwID) and (not item2 or not item2.dwID) then
		return true
	end
	if item1 and item2 and item1.dwID and item2.dwID then
		if item1.dwID == item2.dwID then
			return true
		end
		if item1.nUiId == item2.nUiId and (not item1.bCanStack or item1.nStackNum == item2.nStackNum) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx',
	exports = {
		{
			fields = {
				ItemSorter = D.ItemSorter,
				IsSameItem = D.IsSameItem,
			},
		},
	},
}
MY_BagEx = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
