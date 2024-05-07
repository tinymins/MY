--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ±³°ü¶Ñµþ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BankStack'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BankStack'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- ±³°ü¶Ñµþ
function D.StackBag()
	local frame = Station.Lookup('Normal/BigBankPanel')
	if not frame then
		return
	end
	local bTrigger
	local fnFinish = function()
		X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE'}, 'MY_BagEx_BankStack__Stack', false)
		MY_BagEx_Bank.HideAllItemShadow()
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	local function fnNext()
		bTrigger = true
		if not frame then
			X.Systopmsg(_L['Bank panel closed, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		local me, tList = X.GetClientPlayer(), {}
		for _, dwBox in ipairs(X.CONSTANT.INVENTORY_BANK_LIST) do
			for dwX = 0, me.GetBoxSize(dwBox) - 1 do
				if not MY_BagEx_Bank.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bank.HideItemShadow(frame, dwBox, dwX)
				end
				local item = not MY_BagEx_Bank.IsItemBoxLocked(dwBox, dwX) and GetPlayerItem(me, dwBox, dwX)
				if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
					local szKey = X.GetItemKey(item)
					local tPos = tList[szKey]
					if tPos then
						local dwBox1, dwX1 = tPos.dwBox, tPos.dwX
						--[[#DEBUG BEGIN]]
						X.Debug('MY_BagEx_BankStack', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						OnExchangeItem(dwBox, dwX, dwBox1, dwX1)
						return
					else
						tList[szKey] = { dwBox = dwBox, dwX = dwX }
					end
				end
			end
		end
		fnFinish()
	end
	X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE'}, 'MY_BagEx_BankStack__Stack', function(event)
		local dwBox, dwX, bNewAdd = arg0, arg1, arg2
		if (event == 'BAG_ITEM_UPDATE' and dwBox >= INVENTORY_INDEX.BANK_PACKAGE1 and dwBox <= INVENTORY_INDEX.BANK_PACKAGE5)
		or event == 'BANK_ITEM_UPDATE' then
			if bNewAdd then
				X.Systopmsg(_L['Put new item in bank detected, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
				fnFinish()
			else
				X.DelayCall('MY_BagEx_BankStack__Stack', fnNext)
			end
		end
	end)
	X.DelayCall(1000, function()
		if not bTrigger then
			fnFinish()
		end
	end)
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
	bTrigger = false
end

-- ¼ì²â¶Ñµþ°´Å¦
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bank.bEnable then
		-- Ö²Èë¶Ñµþ°´Å¦
		local frame = Station.Lookup('Normal/BigBankPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_MY_Sort')
		local btnNew = frame:Lookup('Btn_MY_Stack')
		if not btnRef then
			return
		end
		local nX = btnRef:GetRelX() + btnRef:GetW() + 5
		local nY = btnRef:GetRelY()
		local nW, nH = btnRef:GetSize()
		if not btnNew then
			btnNew = X.UI('Normal/BigBankPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Stack',
					w = nW, h = nH - 3,
					text = _L['Stack'],
					onClick = function()
						if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
							X.Systopmsg(_L['Please unlock mibao first.'])
							return
						end
						MY_BagEx_Bank.ShowAllItemShadow()
						if MY_BagEx_Bank.bConfirm then
							X.Confirm('MY_BagEx_BankStack', _L['Sure to start bank stack?'], {
								x = frame:GetAbsX() + frame:GetW() / 2,
								y = frame:GetAbsY() + frame:GetH() / 2,
								fnResolve = D.StackBag,
								fnReject = MY_BagEx_Bank.HideAllItemShadow,
								fnCancel = MY_BagEx_Bank.HideAllItemShadow,
							})
						else
							D.StackBag()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankStack__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- ÒÆ³ý¶Ñµþ°´Å¦
		X.UI('Normal/BigBankPanel/Btn_MY_Stack'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankStack__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BankStack',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BankStack = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- ÊÂ¼þ×¢²á
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
