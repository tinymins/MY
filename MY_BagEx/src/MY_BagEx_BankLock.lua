--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : ²Ö¿âËø¶¨
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BankLock'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BankLock'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^29.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- ¼ì²â¶Ñµþ°´Å¦
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bank.bEnable and not X.IsInInventoryPackageLimitedMap() then
		-- Ö²Èë¶Ñµþ°´Å¦
		local frame = Station.Lookup('Normal/BigBankPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_MY_Stack')
		local btnNew = frame:Lookup('Btn_MY_Lock')
		if not btnRef then
			return
		end
		local nX = btnRef:GetRelX() + btnRef:GetW() + 5
		local nY = btnRef:GetRelY()
		if not btnNew then
			local bEdit = false
			btnNew = X.UI('Normal/BigBankPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Lock',
					w = 'auto', h = 'auto',
					text = _L['Lock'],
					onClick = function()
						bEdit = not bEdit
						if bEdit then
							MY_BagEx_Bank.ShowAllItemShadow(true)
						else
							MY_BagEx_Bank.HideAllItemShadow()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankLock__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- ÒÆ³ý¶Ñµþ°´Å¦
		X.UI('Normal/BigBankPanel/Btn_MY_Lock'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankLock__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- È«¾Öµ¼³ö
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BankLock',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BankLock = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- ÊÂ¼þ×¢²á
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
