--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : ±³°ü¶Ñµþ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BankStack'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BankStack'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

function D.Operate()
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
	local bStackLeftExistTime = false
	local function fnNext()
		bTrigger = true
		if not frame then
			X.OutputSystemAnnounceMessage(_L['Bank panel closed, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		local me, tList = X.GetClientPlayer(), {}
		for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.BANK)) do
			for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
				if not MY_BagEx_Bank.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bank.HideItemShadow(frame, dwBox, dwX)
				end
				local kItem = not MY_BagEx_Bank.IsItemBoxLocked(dwBox, dwX) and X.GetInventoryItem(me, dwBox, dwX)
				if kItem and kItem.bCanStack and kItem.nStackNum < kItem.nMaxStackNum and me.GetTradeItemLeftTime(kItem.dwID) == 0 then
					local szKey = X.GetItemKey(kItem) .. '_' .. (kItem.bBind and '1' or '0')
					local nLeftExistTime = bStackLeftExistTime and 0 or kItem.GetLeftExistTime()
					local tPos = tList[szKey] and tList[szKey][nLeftExistTime]
					if tPos then
						local dwBox1, dwX1 = tPos.dwBox, tPos.dwX
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage('MY_BagEx_BankStack', 'ExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						X.ExchangeInventoryItem(dwBox, dwX, dwBox1, dwX1)
						return
					else
						if not tList[szKey] then
							tList[szKey] = {}
						end
						tList[szKey][nLeftExistTime] = { dwBox = dwBox, dwX = dwX }
					end
				end
			end
		end
		fnFinish()
	end
	local function fnStart()
		X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE'}, 'MY_BagEx_BankStack__Stack', function(event)
			local dwBox, dwX, bNewAdd = arg0, arg1, arg2
			if (event == 'BAG_ITEM_UPDATE' and dwBox >= INVENTORY_INDEX.BANK_PACKAGE1 and dwBox <= INVENTORY_INDEX.BANK_PACKAGE5)
			or event == 'BANK_ITEM_UPDATE' then
				if bNewAdd then
					X.OutputSystemAnnounceMessage(_L['Put new item in bank detected, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
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
		fnNext()
	end
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	bTrigger = false

	local me, tCache = X.GetClientPlayer(), {}
	local bLeftExistTime = false
	for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.BANK)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			if not MY_BagEx_Bank.IsItemBoxLocked(dwBox, dwX) then
				local kItem = X.GetInventoryItem(me, dwBox, dwX)
				if kItem then
					local szKey = X.GetItemKey(kItem)
					local nTimeLimited = kItem.GetLeftExistTime()
					if tCache[szKey] then
						if tCache[szKey] ~= nTimeLimited then
							bLeftExistTime = true
						end
					else
						tCache[szKey] = nTimeLimited
					end
				end
			end
		end
	end
	if bLeftExistTime then
		MessageBox({
			szMessage = g_tStrings.STR_STACK_BANK_JUDGE,
			szName = 'BigBankPanel_StackBox',
			x = frame:GetAbsX() + frame:GetW() / 2,
			y = frame:GetAbsY() + frame:GetH() / 2,
			fnAutoClose = function() return not frame or not frame:IsVisible() end,
			fnCancelAction = fnFinish,
			{
				szOption = g_tStrings.STR_HOTKEY_SURE,
				fnAction = function()
					bStackLeftExistTime = true
					fnStart()
				end,
			}, {
				szOption = g_tStrings.STR_HOTKEY_CANCEL,
				fnAction = function()
					bStackLeftExistTime = false
					fnStart()
				end,
			},
		})
	else
		fnStart()
	end
end

-- ¼ì²â¶Ñµþ°´Å¦
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bank.bEnable and not X.IsInInventoryPackageLimitedMap() then
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
		if not btnNew then
			btnNew = X.UI('Normal/BigBankPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Stack',
					w = 'auto', h = 'auto',
					text = _L['Stack'],
					onClick = function()
						if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
							X.OutputSystemAnnounceMessage(_L['Please unlock mibao first.'])
							return
						end
						MY_BagEx_Bank.ShowAllItemShadow()
						if MY_BagEx_Bank.bConfirm then
							X.Confirm('MY_BagEx_BankStack', _L['Sure to start bank stack?'], {
								x = frame:GetAbsX() + frame:GetW() / 2,
								y = frame:GetAbsY() + frame:GetH() / 2,
								fnResolve = D.Operate,
								fnReject = MY_BagEx_Bank.HideAllItemShadow,
								fnCancel = MY_BagEx_Bank.HideAllItemShadow,
								fnAutoClose = function() return not frame or not frame:IsVisible() end,
							})
						else
							D.Operate()
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

--------------------------------------------------------------------------------
-- È«¾Öµ¼³ö
--------------------------------------------------------------------------------
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
