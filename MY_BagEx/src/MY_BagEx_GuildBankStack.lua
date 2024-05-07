--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ²Ö¿â¶Ñµþ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_GuildBankStack'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_GuildBankStack'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- °ï»á²Ö¿â¶Ñµþ
function D.StackGuildBank()
	local frame = Station.Lookup('Normal/GuildBankPanel')
	if not frame then
		return
	end
	local nPage = frame.nPage or 0
	local bTrigger
	local fnFinish = function()
		X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankStack__Stack', false)
		X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankStack__Stack', false)
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	local function fnNext()
		bTrigger = true
		local me, tList = X.GetClientPlayer(), {}
		for i = 1, X.GetGuildBankBagSize(nPage) do
			local dwBox, dwX = X.GetGuildBankBagPos(nPage, i)
			local item = GetPlayerItem(me, dwBox, dwX)
			if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
				local szKey = X.GetItemKey(item)
				local dwX2 = tList[szKey]
				if not dwX2 then
					tList[szKey] = dwX
				else
					OnExchangeItem(dwBox, dwX, INVENTORY_GUILD_BANK, dwX2)
					return
				end
			end
		end
		fnFinish()
	end
	X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankStack__Stack', fnNext)
	X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankStack__Stack', function()
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
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
	bTrigger = false
end

-- ¼ì²â¶Ñµþ°´Å¦
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_GuildBank.bEnable then
		-- Ö²Èë¶Ñµþ°´Å¦
		local frame = Station.Lookup('Normal/GuildBankPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_MY_Sort') or frame:Lookup('Btn_Refresh')
		local btnNew = frame:Lookup('Btn_MY_Stack')
		if btnRef then
			if not btnNew then
				local nX, nY = btnRef:GetRelPos()
				local nW, nH = btnRef:GetSize()
				btnNew = X.UI('Normal/GuildBankPanel')
					:Append('WndButton', {
						name = 'Btn_MY_Stack',
						x = nX - nW, y = nY, w = nW, h = nH - 2,
						text = _L['Stack'],
						onClick = function()
							if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY) then
								X.Systopmsg(_L['Please unlock mibao first.'])
								return
							end
							if MY_BagEx_Bag.bConfirm then
								X.Confirm('MY_BagEx_GuildBankStack', _L['Sure to start guild bank stack?'], {
									x = frame:GetAbsX() + frame:GetW() / 2,
									y = frame:GetAbsY() + frame:GetH() / 2,
									fnResolve = D.StackGuildBank,
								})
							else
								D.StackGuildBank()
							end
						end,
					})
					:Raw()
			end
		end
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankStack__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- ÒÆ³ý¶ÑµþÕûÀí°´Å¦]
		X.UI('Normal/GuildBankPanel/Btn_MY_Stack'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankStack__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_GuildBankStack',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_GuildBankStack = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- ÊÂ¼þ×¢²á
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_BagEx_GuildBankStack', function() D.CheckInjection() end)
X.RegisterFrameCreate('GuildBankPanel', 'MY_BagEx_GuildBankStack', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_GuildBankStack', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
