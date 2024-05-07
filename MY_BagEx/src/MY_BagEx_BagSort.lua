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
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagSort'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagSort'
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
		[ITEM_GENRE.MATERIAL] = 5
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
	if not a.dwID then
		return false
	end
	if not b.dwID then
		return true
	end
	local gA, gB = D.aGenre[a.nGenre] or (100 + a.nGenre), D.aGenre[b.nGenre] or (100 + b.nGenre)
	if gA == gB then
		if b.nUiId == a.nUiId and b.bCanStack then
			return a.nStackNum > b.nStackNum
		elseif a.nGenre == ITEM_GENRE.EQUIPMENT then
			local sA, sB = D.aSub[a.nSub] or (100 + a.nSub), D.aSub[b.nSub] or (100 + b.nSub)
			if sA == sB then
				if b.nSub == EQUIPMENT_SUB.MELEE_WEAPON or b.nSub == EQUIPMENT_SUB.RANGE_WEAPON then
					if a.nDetail < b.nDetail then
						return true
					end
				elseif b.nSub == EQUIPMENT_SUB.PACKAGE then
					if a.nCurrentDurability > b.nCurrentDurability then
						return true
					elseif a.nCurrentDurability < b.nCurrentDurability then
						return false
					end
				end
			end
		end
		return a.nQuality > b.nQuality or (a.nQuality == b.nQuality and (a.dwTabType < b.dwTabType or (a.dwTabType == b.dwTabType and a.dwIndex < b.dwIndex)))
	else
		return gA < gB
	end
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

-- 帮会仓库整理
function D.SortBag()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if not frame then
		return
	end
	local szState = 'Idle'
	-- 加载格子列表
	local me, aInfo, nItemCount = X.GetClientPlayer(), {}, 0
	local aBagPos = {}
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() - 1 do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local item = GetPlayerItem(me, dwBox, dwX)
			if item then
				table.insert(aInfo, {
					dwID = item.dwID,
					nUiId = item.nUiId,
					dwTabType = item.dwTabType,
					dwIndex = item.dwIndex,
					nGenre = item.nGenre,
					nSub = item.nSub,
					nDetail = item.nDetail,
					nQuality = item.nQuality,
					bCanStack = item.bCanStack,
					nStackNum = item.nStackNum,
					nCurrentDurability = item.nCurrentDurability,
					szName = X.GetObjectName('ITEM', item),
				})
				nItemCount = nItemCount + 1
			else
				table.insert(aInfo, X.CONSTANT.EMPTY_TABLE)
			end
			table.insert(aBagPos, { dwBox = dwBox, dwX = dwX })
		end
	end
	if nItemCount == 0 then
		return
	end
	-- 避开锁定格子
	local aMovableInfo = {}
	for i, info in ipairs(aInfo) do
		local tPos = aBagPos[i]
		if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
			table.insert(aMovableInfo, info)
		end
	end
	-- 排序格子列表
	if IsShiftKeyDown() then
		for i = 1, #aMovableInfo do
			local j = X.Random(1, #aMovableInfo)
			if i ~= j then
				aMovableInfo[i], aMovableInfo[j] = aMovableInfo[j], aMovableInfo[i]
			end
		end
	else
		table.sort(aMovableInfo, D.ItemSorter)
	end
	-- 合成避开锁定格子后的排序结果
	for i, _ in X.ipairs_r(aInfo) do
		local tPos = aBagPos[i]
		if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
			aInfo[i] = table.remove(aMovableInfo)
		end
	end
	-- 结束清理环境、恢复控件状态
	local function fnFinish()
		szState = 'Idle'
		X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagSort__Sort', false)
		MY_BagEx_Bag.HideAllItemShadow()
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	-- 根据排序结果与当前状态交换物品
	local function fnNext()
		if not frame then
			X.Systopmsg(_L['Bag panel closed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' then
			return
		end
		for i, info in ipairs(aInfo) do
			local tBagPos = aBagPos[i]
			local dwBox, dwX = tBagPos.dwBox, tBagPos.dwX
			local item = GetPlayerItem(me, dwBox, dwX)
			if D.IsSameItem(item, info) then
				if not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bag.HideItemShadow(frame, dwBox, dwX)
				end
			else -- 当前格子和预期不符 需要交换
				-- 当前格子和预期物品可堆叠 先拿个别的东西替换过来否则会导致物品合并
				if item and info.dwID and item.nUiId == info.nUiId and item.bCanStack and item.nStackNum ~= info.nStackNum then
					for j = #aBagPos, i + 1, -1 do
						local tBagPos1 = aBagPos[j]
						local dwBox1, dwX1 = tBagPos1.dwBox, tBagPos1.dwX
						local item1 = GetPlayerItem(me, dwBox1, dwX1)
						-- 匹配到用于交换的格子
						if not MY_BagEx_Bag.IsItemBoxLocked(dwBox1, dwX1) and (not item1 or item1.nUiId ~= item.nUiId) then
							szState = 'Exchanging'
							if item then
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwBox, dwX, dwBox1, dwX1)
							else
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox1 .. ',' .. dwX1 .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwBox1, dwX1, dwBox, dwX)
							end
							return
						end
					end
					X.Systopmsg(_L['Cannot find item temp position, bag is full, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
					return fnFinish()
				end
				-- 寻找预期物品所在位置
				for j = #aBagPos, i + 1, -1 do
					local tBagPos1 = aBagPos[j]
					local dwBox1, dwX1 = tBagPos1.dwBox, tBagPos1.dwX
					local item1 = GetPlayerItem(me, dwBox1, dwX1)
					-- 匹配到预期物品所在位置
					if not MY_BagEx_Bag.IsItemBoxLocked(dwBox1, dwX1) and D.IsSameItem(item1, info) then
						szState = 'Exchanging'
						if item then
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwBox, dwX, dwBox1, dwX1)
						else
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox1 .. ',' .. dwX1 .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <N2>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwBox1, dwX1, dwBox, dwX)
						end
						return
					end
				end
				X.Systopmsg(_L['Exchange item match failed, bag may changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
				return fnFinish()
			end
		end
		fnFinish()
	end
	X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagSort__Sort', function()
		local dwBox, dwX, bNewAdd = arg0, arg1, arg2
		if bNewAdd then
			X.Systopmsg(_L['Put new item in bag detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		elseif szState == 'Exchanging' then
			szState = 'Idle'
			X.DelayCall('MY_BagEx_BagSort__Sort', fnNext)
		end
	end)
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
end

-- 检测增加按纽
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bag.bEnable then
		-- 植入整理按纽
		local frame = Station.Lookup('Normal/BigBagPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_CU')
		local btnNew = frame:Lookup('Btn_MY_Sort')
		if not btnRef then
			return
		end
		local nX, nY = btnRef:GetRelPos()
		local nW, nH = btnRef:GetSize()
		if not btnNew then
			btnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Sort',
					w = nW, h = nH - 3,
					text = _L['Sort'],
					tip = {
						render = _L['Press shift for random'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					onClick = function()
						MY_BagEx_Bag.ShowAllItemShadow()
						if MY_BagEx_Bag.bConfirm then
							X.Confirm(_L['Sure to start bag sort?'], {
								x = frame:GetAbsX() + frame:GetW() / 2,
								y = frame:GetAbsY() + frame:GetH() / 2,
								fnResolve = D.SortBag,
								fnReject = MY_BagEx_Bag.HideAllItemShadow,
								fnCancel = MY_BagEx_Bag.HideAllItemShadow,
							})
						else
							D.SortBag()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- 移除整理按纽
		X.UI('Normal/BigBagPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BagSort',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BagSort = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('SCROLL_UPDATE_LIST', 'MY_BagEx_BagSort', function()
	if (arg0 == 'Handle_Bag_Compact' or arg0 == 'Handle_Bag_Normal')
	and arg1 == 'BigBagPanel' then
		D.CheckInjection()
	end
end)
X.RegisterUserSettingsInit('MY_BagEx_BagSort', function() D.CheckInjection() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_BagSort', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_BagSort', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
