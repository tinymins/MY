--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 背包整理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BankSort'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BankSort'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

function D.Operate(bRandom, bExportBlueprint, aBlueprint)
	local hFrame = Station.Lookup('Normal/BigBankPanel')
	if not hFrame then
		return
	end
	local szState = 'Idle'
	-- 加载格子列表
	local me, aItemDesc, nItemCount, aBoxPos = X.GetClientPlayer(), {}, 0, {}
	for _, dwBox in ipairs(X.CONSTANT.INVENTORY_BANK_LIST) do
		local dwGenre = me.GetContainType(dwBox)
		if dwGenre == ITEM_GENRE.BOOK then
			X.OutputSystemAnnounceMessage(_L['Bank contains book only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		if dwGenre == ITEM_GENRE.MATERIAL then
			X.OutputSystemAnnounceMessage(_L['Bank contains material only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			local kItem = X.GetInventoryItem(me, dwBox, dwX)
			local tDesc = MY_BagEx.GetItemDesc(kItem)
			if not X.IsEmpty(tDesc) then
				nItemCount = nItemCount + 1
			end
			table.insert(aItemDesc, tDesc)
			table.insert(aBoxPos, { dwBox = dwBox, dwX = dwX })
		end
	end
	-- 导出布局
	if bExportBlueprint then
		X.UI.OpenTextEditor(MY_BagEx.EncodeItemDescList(aItemDesc))
		return
	end
	-- 没物品不需要操作
	if nItemCount == 0 then
		return
	end
	-- 导入布局
	if aBlueprint then
		for nIndex, tDesc in ipairs(aItemDesc) do
			aItemDesc[nIndex] = aBlueprint[nIndex] or MY_BagEx.GetItemDesc()
		end
	else
		-- 避开锁定格子
		local aMovableItemDesc = {}
		for nIndex, tDesc in ipairs(aItemDesc) do
			local tPos = aBoxPos[nIndex]
			if not MY_BagEx_Bank.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
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
		for i, _ in X.ipairs_r(aItemDesc) do
			local tPos = aBoxPos[i]
			if not MY_BagEx_Bank.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
				aItemDesc[i] = table.remove(aMovableItemDesc)
			end
		end
	end
	-- 结束清理环境、恢复控件状态
	local function fnFinish()
		szState = 'Idle'
		X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE'}, 'MY_BagEx_BankSort__Sort', false)
		MY_BagEx_Bank.HideAllItemShadow()
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	-- 根据排序结果与当前状态交换物品
	local nIndex, bChanged = 1, false
	local function fnNext()
		if not hFrame then
			X.OutputSystemAnnounceMessage(_L['Bank panel closed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' then
			return
		end
		while nIndex <= #aItemDesc do
			local tDesc = aItemDesc[nIndex]
			local tBoxPos = aBoxPos[nIndex]
			local dwBox, dwX = tBoxPos.dwBox, tBoxPos.dwX
			local kCurItem = X.GetInventoryItem(me, dwBox, dwX)
			local tCurDesc = MY_BagEx.GetItemDesc(kCurItem)
			if MY_BagEx.IsSameItemDesc(tDesc, tCurDesc) then
				if not MY_BagEx_Bank.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bank.HideItemShadow(hFrame, dwBox, dwX)
				end
				nIndex = nIndex + 1
			else -- 当前格子和预期不符 需要交换
				local tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc
				-- 寻找预期物品所在位置
				if not dwExcBox then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- 匹配到预期物品所在位置
						if not MY_BagEx_Bank.IsItemBoxLocked(dwExcBox, dwExcX) and MY_BagEx.IsSameItemDesc(tDesc, tExcDesc) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						bChanged = true
					end
				end
				-- 寻找堆叠数不同的预期物品所在位置
				if not dwExcBox then
					for nExcIndex = nIndex, #aBoxPos do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- 匹配到预期物品所在位置
						if not MY_BagEx_Bank.IsItemBoxLocked(dwExcBox, dwExcX) and MY_BagEx.IsSameItemDesc(tDesc, tExcDesc, true) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
				end
				-- 符合要求不用交換
				if dwBox == dwExcBox and dwX == dwExcX then
					nIndex = nIndex + 1
					X.DelayCall(fnNext)
					return
				end
				-- 当前格子和预期物品可堆叠 先拿个别的东西替换过来否则会导致物品合并
				if dwExcBox and MY_BagEx.CanItemDescStack(tCurDesc, tDesc) then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- 匹配到用于交换的格子
						if not MY_BagEx_Bank.IsItemBoxLocked(dwExcBox, dwExcX) and not MY_BagEx.CanItemDescStack(tCurDesc, tExcDesc) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						local szMsg = bChanged
							and _L['Bank item changed, sort finished, result may not be perfect!']
							or _L['Cannot find item temp position, bank is full, sort exited!']
						X.OutputSystemAnnounceMessage(szMsg, X.CONSTANT.MSG_THEME.ERROR)
						return fnFinish()
					end
				end
				-- 还是没有匹配到 将当前物品找个空格子移走
				if not dwExcBox then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						-- 匹配到用于交换的格子
						if not MY_BagEx_Bank.IsItemBoxLocked(dwExcBox, dwExcX) and not kExcItem then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						local szMsg = bChanged
							and _L['Bank item changed, sort finished, result may not be perfect!']
							or _L['Cannot find item temp position, bank is full, sort exited!']
						X.OutputSystemAnnounceMessage(szMsg, X.CONSTANT.MSG_THEME.ERROR)
						return fnFinish()
					end
				end
				-- 执行物品互换
				szState = 'Exchanging'
				if kCurItem then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage('MY_BagEx_BankSort', 'ExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwExcBox .. ',' .. dwExcX .. ' <T1>', X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.ExchangeInventoryItem(dwBox, dwX, dwExcBox, dwExcX)
				else
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage('MY_BagEx_BankSort', 'ExchangeItem: ' ..dwExcBox .. ',' .. dwExcX .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.ExchangeInventoryItem(dwExcBox, dwExcX, dwBox, dwX)
				end
				return
			end
		end
		fnFinish()
	end
	X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE'}, 'MY_BagEx_BankSort__Sort', function(event)
		local dwBox, dwX, bNewAdd = arg0, arg1, arg2
		if (event == 'BAG_ITEM_UPDATE' and dwBox >= INVENTORY_INDEX.BANK_PACKAGE1 and dwBox <= INVENTORY_INDEX.BANK_PACKAGE5)
		or event == 'BANK_ITEM_UPDATE' then
			if bNewAdd then
				X.OutputSystemAnnounceMessage(_L['Put new item in bank detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
				fnFinish()
			elseif szState == 'Exchanging' then
				szState = 'Idle'
				X.DelayCall('MY_BagEx_BankSort__Sort', fnNext)
			end
		end
	end)
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
end

-- 检测增加按纽
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bank.bEnable and not X.IsInInventoryPackageLimitedMap() then
		-- 植入整理按纽
		local hFrame = Station.Lookup('Normal/BigBankPanel')
		if not hFrame then
			return
		end
		local hBtnRef = hFrame:Lookup('Btn_CU')
		local hBtnNew = hFrame:Lookup('Btn_MY_Sort')
		if not hBtnRef then
			return
		end
		local nX, nY = hBtnRef:GetRelPos()
		if not hBtnNew then
			hBtnNew = X.UI('Normal/BigBankPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Sort',
					w = 'auto', h = 'auto',
					text = _L['Sort'],
					tip = {
						render = _L['Press shift for random, right click to import and export'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					onLClick = function()
						if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
							X.OutputSystemAnnounceMessage(_L['Please unlock mibao first.'])
							return
						end
						local bRandom = IsShiftKeyDown()
						MY_BagEx_Bank.ShowAllItemShadow()
						if MY_BagEx_Bank.bConfirm then
							X.Confirm('MY_BagEx_BankSort', _L['Sure to start bank sort?'], {
								x = hFrame:GetAbsX() + hFrame:GetW() / 2,
								y = hFrame:GetAbsY() + hFrame:GetH() / 2,
								fnResolve = function() D.Operate(bRandom) end,
								fnReject = MY_BagEx_Bank.HideAllItemShadow,
								fnCancel = MY_BagEx_Bank.HideAllItemShadow,
								fnAutoClose = function() return not hFrame or not hFrame:IsVisible() end,
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
									X.UI.ClosePopupMenu()
								end,
							},
							{
								szOption = _L['Import blueprint'],
								fnAction = function()
									GetUserInput(_L['Please input blueprint'], function(szBlueprint)
										local aBlueprint = MY_BagEx.DecodeItemDescList(szBlueprint)
										if aBlueprint then
											MY_BagEx_Bank.ShowAllItemShadow()
											D.Operate(false, false, aBlueprint)
										else
											X.OutputSystemAnnounceMessage(_L['Invalid blueprint data'])
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
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankSort__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
		end)
	else
		-- 移除整理按纽
		X.UI('Normal/BigBankPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankSort__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BankSort',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BankSort = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
