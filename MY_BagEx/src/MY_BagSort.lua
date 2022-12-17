--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 仓库堆叠整理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagSort'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagSort'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^14.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	bGuildBank = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
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

-- 帮会仓库堆叠
function D.StackGuildBank()
	local frame = Station.Lookup('Normal/GuildBankPanel')
	if not frame then
		return
	end
	local nPage = frame.nPage or 0
	local bTrigger
	local fnFinish = function()
		local btn = Station.Lookup('Normal/GuildBankPanel/Btn_MY_Stack')
		if btn then
			btn:Enable(1)
			Station.Lookup('Normal/GuildBankPanel/Btn_MY_Sort'):Enable(1)
		end
		X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagSort__Stack', false)
		X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagSort__Stack', false)
	end
	local function fnLoop()
		local me, tList = GetClientPlayer(), {}
		bTrigger = true
		for i = 1, X.GetGuildBankBagSize(nPage) do
			local dwPos, dwX = X.GetGuildBankBagPos(nPage, i)
			local item = GetPlayerItem(me, dwPos, dwX)
			if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
				local szKey = tostring(item.dwTabType) .. '_' .. tostring(item.dwIndex)
				local dwX2 = tList[szKey]
				if not dwX2 then
					tList[szKey] = dwX
				else
					OnExchangeItem(dwPos, dwX, INVENTORY_GUILD_BANK, dwX2)
					return
				end
			end
		end
		fnFinish()
	end
	frame:Lookup('Btn_MY_Stack'):Enable(0)
	frame:Lookup('Btn_MY_Sort'):Enable(0)
	X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagSort__Stack', fnLoop)
	X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagSort__Stack', function()
		-- TONG_EVENT_CODE.TAKE_REPERTORY_ITEM_PERMISSION_DENY_ERROR
		if arg0 == TONG_EVENT_CODE.PUT_ITEM_IN_REPERTORY_SUCCESS then
			fnFinish()
		end
	end)
	X.DelayCall(1000, function()
		if not bTrigger then
			fnFinish()
		end
	end)
	fnLoop()
	bTrigger = false
end

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
function D.SortGuildBank()
	local frame = Station.Lookup('Normal/GuildBankPanel')
	if not frame then
		return
	end
	local nPage, szState = frame.nPage or 0, 'Idle'
	-- 加载格子列表
	local me, aInfo, nItemCount = GetClientPlayer(), {}, 0
	for i = 1, X.GetGuildBankBagSize(nPage) do
		local dwPos, dwX = X.GetGuildBankBagPos(nPage, i)
		local item = GetPlayerItem(me, dwPos, dwX)
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
	end
	if nItemCount == 0 then
		return
	end
	-- 排序格子列表
	if IsShiftKeyDown() then
		for i = 1, #aInfo do
			local j = X.Random(1, #aInfo)
			if i ~= j then
				aInfo[i], aInfo[j] = aInfo[j], aInfo[i]
			end
		end
	else
		table.sort(aInfo, D.ItemSorter)
	end
	-- 结束清理环境、恢复控件状态
	local function fnFinish()
		szState = 'Idle'
		local btn = Station.Lookup('Normal/GuildBankPanel/Btn_MY_Sort')
		if btn then
			btn:Enable(1)
			Station.Lookup('Normal/GuildBankPanel/Btn_MY_Stack'):Enable(1)
		end
		X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagSort__Sort', false)
		X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagSort__Sort', false)
	end
	-- 根据排序结果与当前状态交换物品
	local function fnNext()
		if not frame or (frame.nPage or 0) ~= nPage then
			X.Systopmsg(_L['Guild box closed or page changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' or szState == 'Refreshing' then
			return
		end
		for i, info in ipairs(aInfo) do
			local dwPos, dwX = X.GetGuildBankBagPos(nPage, i)
			local item = GetPlayerItem(me, dwPos, dwX)
			-- 当前格子和预期不符 需要交换
			if not D.IsSameItem(item, info) then
				-- 当前格子和预期物品可堆叠 先拿个别的东西替换过来否则会导致物品合并
				if item and info.dwID and item.nUiId == info.nUiId and item.bCanStack and item.nStackNum ~= info.nStackNum then
					for j = X.GetGuildBankBagSize(nPage), i + 1, -1 do
						local dwPos1, dwX1 = X.GetGuildBankBagPos(nPage, j)
						local item1 = GetPlayerItem(me, INVENTORY_GUILD_BANK, dwX1)
						-- 匹配到用于交换的格子
						if not item1 or item1.nUiId ~= item.nUiId then
							szState = 'Exchanging'
							if item then
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos, dwX, dwPos1, dwX1)
							else
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX1 .. ' <-> ' .. 'GUILD,' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos1, dwX1, dwPos, dwX)
							end
							return
						end
					end
					X.Systopmsg(_L['Cannot find item temp position, guild bag is full, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
					return
				end
				-- 寻找预期物品所在位置
				for j = X.GetGuildBankBagSize(nPage), i + 1, -1 do
					local dwPos1, dwX1 = X.GetGuildBankBagPos(nPage, j)
					local item1 = GetPlayerItem(me, dwPos1, dwX1)
					-- 匹配到预期物品所在位置
					if D.IsSameItem(item1, info) then
						szState = 'Exchanging'
						if item then
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwX1 .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos, dwX, dwPos1, dwX1)
						else
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX1 .. ' <-> ' .. 'GUILD,' .. dwX .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos1, dwX1, dwPos, dwX)
						end
						return
					end
				end
				X.Systopmsg(_L['Exchange item match failed, guild bag may changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
				return
			end
		end
		fnFinish()
	end
	frame:Lookup('Btn_MY_Sort'):Enable(0)
	frame:Lookup('Btn_MY_Stack'):Enable(0)
	X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagSort__Sort', function()
		if szState == 'Refreshing' then
			szState = 'Idle'
			fnNext()
		end
	end)
	X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagSort__Sort', function()
		-- TONG_EVENT_CODE.TAKE_REPERTORY_ITEM_PERMISSION_DENY_ERROR
		if arg0 == TONG_EVENT_CODE.EXCHANGE_REPERTORY_ITEM_SUCCESS then
			szState = 'Refreshing'
		elseif arg0 == TONG_EVENT_CODE.PUT_ITEM_IN_REPERTORY_SUCCESS then
			X.Systopmsg(_L['Put item in guild detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		else
			X.Systopmsg(_L['Unknown exception occured, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
			--[[#DEBUG BEGIN]]
			X.Debug('MY_BagSort', 'TONG_EVENT_NOTIFY: ' .. arg0, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
	end)
	fnNext()
end

-- 检测增加堆叠按纽
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and O.bGuildBank then
		-- 植入堆叠整理按纽
		-- guild bank sort/stack
		local btn1 = X.UI('Normal/GuildBankPanel/Btn_Refresh')
		local btn2 = X.UI('Normal/GuildBankPanel/Btn_MY_Sort')
		local btn3 = X.UI('Normal/GuildBankPanel/Btn_MY_Stack')
		if btn1:Count() > 0 then
			if btn2:Count() == 0 then
				local x, y = btn1:Pos()
				local w, h = btn1:Size()
				btn2 = X.UI('Normal/GuildBankPanel'):Append('WndButton', {
					name = 'Btn_MY_Sort',
					x = x - w, y = y, w = w, h = h,
					text = _L['Sort'],
					tip = {
						render = _L['Press shift for random'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					onClick = D.SortGuildBank,
				})
			end
			if btn3:Count() == 0 then
				local x, y = btn2:Pos()
				local w, h = btn2:Size()
				btn3 = X.UI('Normal/GuildBankPanel'):Append('WndButton', {
					name = 'Btn_MY_Stack',
					x = x - w, y = y, w = w, h = h,
					text = _L['Stack'],
					onClick = D.StackGuildBank,
				})
			end
		end
	else
		-- 移除堆叠整理按纽
		X.UI('Normal/GuildBankPanel/Btn_MY_Sort'):Remove()
		X.UI('Normal/GuildBankPanel/Btn_MY_Stack'):Remove()
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Guild package sort and stack'],
		checked = O.bGuildBank,
		onCheck = function(bChecked)
			O.bGuildBank = bChecked
			D.CheckInjection()
		end,
	}):AutoWidth():Width() + 5
	nX = nPaddingX
	nY = nY + nLH
	return nX, nY
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagSort',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_BagSort = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_BagSort', function() D.CheckInjection() end)
X.RegisterFrameCreate('GuildBankPanel', 'MY_BagSort', function() D.CheckInjection() end)
X.RegisterReload('MY_BagSort', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
