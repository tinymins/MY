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
local D = {}

function D.Operate(bRandom, bExportBlueprint, aBlueprint)
	local hFrame = Station.Lookup('Normal/BigBagPanel')
	if not hFrame then
		return
	end
	local szState = 'Idle'
	-- 加载格子列表
	local me, aItemDesc, nItemCount = X.GetClientPlayer(), {}, 0
	local aBagPos = {}
	local nBagPackageIndex = X.GetBagPackageIndex()
	for dwBox = nBagPackageIndex, nBagPackageIndex + X.GetBagPackageCount() - 1 do
		local dwGenre = me.GetContainType(dwBox)
		if dwGenre == ITEM_GENRE.BOOK then
			X.Systopmsg(_L['Bag contains book only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		if dwGenre == ITEM_GENRE.MATERIAL then
			X.Systopmsg(_L['Bag contains material only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local kItem = GetPlayerItem(me, dwBox, dwX)
			local tDesc = MY_BagEx.GetItemDesc(kItem)
			if not X.IsEmpty(tDesc) then
				nItemCount = nItemCount + 1
			end
			table.insert(aItemDesc, tDesc)
			table.insert(aBagPos, { dwBox = dwBox, dwX = dwX })
		end
	end
	-- 导出蓝图
	if bExportBlueprint then
		X.UI.OpenTextEditor(MY_BagEx.EncodeItemDescList(aItemDesc))
		return
	end
	-- 没物品不需要操作
	if nItemCount == 0 then
		return
	end
	-- 导入蓝图
	if aBlueprint then
		for nIndex, tDesc in ipairs(aItemDesc) do
			aItemDesc[nIndex] = aBlueprint[nIndex] or MY_BagEx.GetItemDesc()
		end
	else
		-- 避开锁定格子
		local aMovableItemDesc = {}
		for nIndex, tDesc in ipairs(aItemDesc) do
			local tPos = aBagPos[nIndex]
			if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
				table.insert(aMovableItemDesc, tDesc)
			end
		end
		-- 排序格子列表
		if bRandom then
			for nIndex = 1, #aMovableItemDesc do
				local nExcIndex = X.Random(1, #aMovableItemDesc)
				if nIndex ~= nExcIndex then
					aMovableItemDesc[nIndex], aMovableItemDesc[nExcIndex] = aMovableItemDesc[nExcIndex], aMovableItemDesc[nIndex]
				end
			end
		else
			table.sort(aMovableItemDesc, MY_BagEx.ItemDescSorter)
		end
		-- 合成避开锁定格子后的排序结果
		for nIndex, _ in X.ipairs_r(aItemDesc) do
			local tPos = aBagPos[nIndex]
			if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
				aItemDesc[nIndex] = table.remove(aMovableItemDesc)
			end
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
		if not hFrame then
			X.Systopmsg(_L['Bag panel closed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' then
			return
		end
		for nIndex, tDesc in ipairs(aItemDesc) do
			local tBagPos = aBagPos[nIndex]
			local dwBox, dwX = tBagPos.dwBox, tBagPos.dwX
			local kCurItem = GetPlayerItem(me, dwBox, dwX)
			local tCurDesc = MY_BagEx.GetItemDesc(kCurItem)
			if MY_BagEx.IsSameItemDesc(tDesc, tCurDesc) then
				if not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bag.HideItemShadow(hFrame, dwBox, dwX)
				end
			else -- 当前格子和预期不符 需要交换
				-- 当前格子和预期物品可堆叠 先拿个别的东西替换过来否则会导致物品合并
				if MY_BagEx.CanItemDescStack(tCurDesc, tDesc) then
					for nExcIndex = #aBagPos, nIndex + 1, -1 do
						local tExcBagPos = aBagPos[nExcIndex]
						local dwExcBox, dwExcX = tExcBagPos.dwBox, tExcBagPos.dwX
						local kExcItem = GetPlayerItem(me, dwExcBox, dwExcX)
						local tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- 匹配到用于交换的格子
						if not MY_BagEx_Bag.IsItemBoxLocked(dwExcBox, dwExcX) and not MY_BagEx.CanItemDescStack(tCurDesc, tExcDesc) then
							szState = 'Exchanging'
							if kCurItem then
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwExcBox .. ',' .. dwExcX .. ' <T1>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwBox, dwX, dwExcBox, dwExcX)
							else
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwExcBox .. ',' .. dwExcX .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwExcBox, dwExcX, dwBox, dwX)
							end
							return
						end
					end
					X.Systopmsg(_L['Cannot find item temp position, bag is full, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
					return fnFinish()
				end
				-- 寻找预期物品所在位置
				for nExcIndex = #aBagPos, nIndex + 1, -1 do
					local tExcBagPos = aBagPos[nExcIndex]
					local dwExcBox, dwExcX = tExcBagPos.dwBox, tExcBagPos.dwX
					local kExcItem = GetPlayerItem(me, dwExcBox, dwExcX)
					local tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
					-- 匹配到预期物品所在位置
					if not MY_BagEx_Bag.IsItemBoxLocked(dwExcBox, dwExcX) and MY_BagEx.IsSameItemDesc(tDesc, tExcDesc) then
						szState = 'Exchanging'
						if kCurItem then
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwExcBox .. ',' .. dwExcX .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwBox, dwX, dwExcBox, dwExcX)
						else
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwExcBox .. ',' .. dwExcX .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <N2>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwExcBox, dwExcX, dwBox, dwX)
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
		local hFrame = Station.Lookup('Normal/BigBagPanel')
		if not hFrame then
			return
		end
		local hBtnRef = hFrame:Lookup('Btn_CU')
		local hBtnNew = hFrame:Lookup('Btn_MY_Sort')
		if not hBtnRef then
			return
		end
		local nX, nY = hBtnRef:GetRelPos()
		local nW, nH = hBtnRef:GetSize()
		if not hBtnNew then
			hBtnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Sort',
					w = nW, h = nH - 3,
					text = _L['Sort'],
					tip = {
						render = _L['Press shift for random'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					onLClick = function()
						local bRandom = IsShiftKeyDown()
						MY_BagEx_Bag.ShowAllItemShadow()
						if MY_BagEx_Bag.bConfirm then
							X.Confirm('MY_BagEx_BagSort', _L['Sure to start bag sort?'], {
								x = hFrame:GetAbsX() + hFrame:GetW() / 2,
								y = hFrame:GetAbsY() + hFrame:GetH() / 2,
								fnResolve = function() D.Operate(bRandom) end,
								fnReject = MY_BagEx_Bag.HideAllItemShadow,
								fnCancel = MY_BagEx_Bag.HideAllItemShadow,
							})
						else
							D.Operate(bRandom)
						end
					end,
					menuRClick = function()
						return {
							{
								szOption = _L['Export blueprint'],
								fnAction = function()
									D.Operate(false, true)
								end,
							},
							{
								szOption = _L['Import blueprint'],
								fnAction = function()
									GetUserInput(_L['Please input blueprint'], function(szBlueprint)
										local aBlueprint = MY_BagEx.DecodeItemDescList(szBlueprint)
										if aBlueprint then
											D.Operate(false, false, aBlueprint)
										else
											X.Systopmsg(_L['Invalid blueprint data'])
										end
									end, nil, nil, nil, '')
								end,
							},
						}
					end,
				})
				:Raw()
		end
		if not hBtnNew then
			return
		end
		hBtnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
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
