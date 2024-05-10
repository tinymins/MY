--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 仓库整理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_GuildBankSort'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_GuildBankSort'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- 帮会仓库整理
function D.SortGuildBank()
	local hFrame = Station.Lookup('Normal/GuildBankPanel')
	if not hFrame then
		return
	end
	local nPage, szState = hFrame.nPage or 0, 'Idle'
	-- 加载格子列表
	local me, aItemDesc, nItemCount = X.GetClientPlayer(), {}, 0
	for i = 1, X.GetGuildBankBagSize(nPage) do
		local dwPos, dwX = X.GetGuildBankBagPos(nPage, i)
		local kItem = GetPlayerItem(me, dwPos, dwX)
		local tDesc = kItem
			and MY_BagEx.GetItemDesc(kItem)
			or X.CONSTANT.EMPTY_TABLE
		if tDesc ~= X.CONSTANT.EMPTY_TABLE then
			nItemCount = nItemCount + 1
		end
		table.insert(aItemDesc, tDesc)
	end
	if nItemCount == 0 then
		return
	end
	-- 排序格子列表
	if IsShiftKeyDown() then
		for nIndex = 1, #aItemDesc do
			local nExcIndex = X.Random(1, #aItemDesc)
			if nIndex ~= nExcIndex then
				aItemDesc[nIndex], aItemDesc[nExcIndex] = aItemDesc[nExcIndex], aItemDesc[nIndex]
			end
		end
	else
		table.sort(aItemDesc, MY_BagEx.ItemDescSorter)
	end
	-- 结束清理环境、恢复控件状态
	local function fnFinish()
		szState = 'Idle'
		X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankSort__Sort', false)
		X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankSort__Sort', false)
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	-- 根据排序结果与当前状态交换物品
	local function fnNext()
		if not hFrame or (hFrame.nPage or 0) ~= nPage then
			X.Systopmsg(_L['Guild box closed or page changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' or szState == 'Refreshing' then
			return
		end
		for nIndex, tDesc in ipairs(aItemDesc) do
			local dwPos, dwX = X.GetGuildBankBagPos(nPage, nIndex)
			local kCurItem = GetPlayerItem(me, dwPos, dwX)
			local tCurDesc = MY_BagEx.GetItemDesc(kCurItem)
			-- 当前格子和预期不符 需要交换
			if not MY_BagEx.IsSameItemDesc(tDesc, tCurDesc) then
				-- 当前格子和预期物品可堆叠 先拿个别的东西替换过来否则会导致物品合并
				if MY_BagEx.CanItemDescStack(tCurDesc, tDesc) then
					for nExcIndex = X.GetGuildBankBagSize(nPage), nIndex + 1, -1 do
						local dwExcPos, dwExcX = X.GetGuildBankBagPos(nPage, nExcIndex)
						local kExcItem = GetPlayerItem(me, INVENTORY_GUILD_BANK, dwExcX)
						local tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- 匹配到用于交换的格子
						if not MY_BagEx.CanItemDescStack(tCurDesc, tExcDesc) then
							szState = 'Exchanging'
							if kCurItem then
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwExcX .. ' <T1>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos, dwX, dwExcPos, dwExcX)
							else
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwExcX .. ' <-> ' .. 'GUILD,' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwExcPos, dwExcX, dwPos, dwX)
							end
							return
						end
					end
					X.Systopmsg(_L['Cannot find item temp position, guild bag is full, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
					return fnFinish()
				end
				-- 寻找预期物品所在位置
				for nExcIndex = X.GetGuildBankBagSize(nPage), nIndex + 1, -1 do
					local dwExcPos, dwExcX = X.GetGuildBankBagPos(nPage, nExcIndex)
					local kExcItem = GetPlayerItem(me, dwExcPos, dwExcX)
					local tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
					-- 匹配到预期物品所在位置
					if MY_BagEx.IsSameItemDesc(tDesc, tExcDesc) then
						szState = 'Exchanging'
						if kCurItem then
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwExcX .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos, dwX, dwExcPos, dwExcX)
						else
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwExcX .. ' <-> ' .. 'GUILD,' .. dwX .. ' <N2>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwExcPos, dwExcX, dwPos, dwX)
						end
						return
					end
				end
				X.Systopmsg(_L['Exchange item match failed, guild bag may changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
				return fnFinish()
			end
		end
		fnFinish()
	end
	X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankSort__Sort', function()
		if szState == 'Refreshing' then
			szState = 'Idle'
			fnNext()
		end
	end)
	X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankSort__Sort', function()
		-- TONG_EVENT_CODE.TAKE_REPERTORY_ITEM_PERMISSION_DENY_ERROR
		if arg0 == TONG_EVENT_CODE.EXCHANGE_REPERTORY_ITEM_SUCCESS then
			szState = 'Refreshing'
		elseif arg0 == TONG_EVENT_CODE.PUT_ITEM_IN_REPERTORY_SUCCESS then
			X.Systopmsg(_L['Put item in guild detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		else
			X.Systopmsg(_L['Unknown exception occurred, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
			--[[#DEBUG BEGIN]]
			X.Debug('MY_BagEx_GuildBankSort', 'TONG_EVENT_NOTIFY: ' .. arg0, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
	end)
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
end

-- 检测增加按纽
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_GuildBank.bEnable then
		-- 植入整理按纽
		local hFrame = Station.Lookup('Normal/GuildBankPanel')
		if not hFrame then
			return
		end
		local hBtnRef = hFrame:Lookup('Btn_Refresh')
		local hBtnNew = hFrame:Lookup('Btn_MY_Sort')
		if hBtnRef then
			if not hBtnNew then
				local nX, nY = hBtnRef:GetRelPos()
				local nW, nH = hBtnRef:GetSize()
				hBtnNew = X.UI('Normal/GuildBankPanel')
					:Append('WndButton', {
						name = 'Btn_MY_Sort',
						x = nX - nW, y = nY, w = nW, h = nH - 2,
						text = _L['Sort'],
						tip = {
							render = _L['Press shift for random'],
							position = X.UI.TIP_POSITION.BOTTOM_TOP,
						},
						onClick = function()
							if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY) then
								X.Systopmsg(_L['Please unlock mibao first.'])
								return
							end
							if MY_BagEx_Bag.bConfirm then
								X.Confirm('MY_BagEx_GuildBankSort', _L['Sure to start guild bank sort?'], {
									x = hFrame:GetAbsX() + hFrame:GetW() / 2,
									y = hFrame:GetAbsY() + hFrame:GetH() / 2,
									fnResolve = D.SortGuildBank,
								})
							else
								D.SortGuildBank()
							end
						end,
					})
					:Raw()
			end
		end
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankSort__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
		end)
	else
		-- 移除整理按纽
		X.UI('Normal/GuildBankPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankSort__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_GuildBankSort',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_GuildBankSort = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_BagEx_GuildBankSort', function() D.CheckInjection() end)
X.RegisterFrameCreate('GuildBankPanel', 'MY_BagEx_GuildBankSort', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_GuildBankSort', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
