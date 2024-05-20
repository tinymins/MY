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
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagStack'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagStack'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- ±³°ü¶Ñµþ
function D.StackBag()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if not frame then
		return
	end
	local bTrigger
	local fnFinish = function()
		X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagStack__Stack', false)
		MY_BagEx_Bag.HideAllItemShadow()
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	local bStackLeftExistTime = false
	local function fnNext()
		bTrigger = true
		if not frame then
			X.Systopmsg(_L['Bag panel closed, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		local me, tList = X.GetClientPlayer(), {}
		for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.PACKAGE)) do
			for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
				if not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bag.HideItemShadow(frame, dwBox, dwX)
				end
				local kItem = not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) and X.GetInventoryItem(me, dwBox, dwX)
				if kItem and kItem.bCanStack and kItem.nStackNum < kItem.nMaxStackNum and me.GetTradeItemLeftTime(kItem.dwID) == 0 then
					local szKey = X.GetItemKey(kItem)
					local nLeftExistTime = bStackLeftExistTime and 0 or kItem.GetLeftExistTime()
					local tPos = tList[szKey] and tList[szKey][nLeftExistTime]
					if tPos then
						local dwBox1, dwX1 = tPos.dwBox, tPos.dwX
						--[[#DEBUG BEGIN]]
						X.Debug('MY_BagEx_BagStack', 'ExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
						me.ExchangeItem(dwBox, dwX, dwBox1, dwX1)
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
		X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagStack__Stack', function()
			local dwBox, dwX, bNewAdd = arg0, arg1, arg2
			if bNewAdd then
				X.Systopmsg(_L['Put new item in bag detected, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
				fnFinish()
			else
				X.DelayCall('MY_BagEx_BagStack__Stack', fnNext)
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
	for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.PACKAGE)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			if not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) then
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
			szMessage = g_tStrings.STR_STACK_BAG_JUDGE,
			szName = 'BigBagPanel_StackBox',
			fnAutoClose = function() return frame and frame:IsVisible() end,
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
	if not bRemoveInjection and MY_BagEx_Bag.bEnable then
		-- Ö²Èë¶Ñµþ°´Å¦
		local frame = Station.Lookup('Normal/BigBagPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_Stack')
		local btnNew = frame:Lookup('Btn_MY_Stack')
		if not btnRef then
			return
		end
		local nX, nY = btnRef:GetRelPos()
		local nW, nH = btnRef:GetSize()
		if not btnNew then
			btnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Stack',
					w = nW, h = nH - 3,
					text = _L['Stack'],
					onClick = function()
						MY_BagEx_Bag.ShowAllItemShadow()
						if MY_BagEx_Bag.bConfirm then
							X.Confirm('MY_BagEx_BagStack', _L['Sure to start bag stack?'], {
								x = frame:GetAbsX() + frame:GetW() / 2,
								y = frame:GetAbsY() + frame:GetH() / 2,
								fnResolve = D.StackBag,
								fnReject = MY_BagEx_Bag.HideAllItemShadow,
								fnCancel = MY_BagEx_Bag.HideAllItemShadow,
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
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagStack__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- ÒÆ³ý¶Ñµþ°´Å¦
		X.UI('Normal/BigBagPanel/Btn_MY_Stack'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagStack__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BagStack',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BagStack = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- ÊÂ¼þ×¢²á
--------------------------------------------------------------------------------

X.RegisterEvent('SCROLL_UPDATE_LIST', 'MY_BagEx_BagStack', function()
	if (arg0 == 'Handle_Bag_Compact' or arg0 == 'Handle_Bag_Normal')
	and arg1 == 'BigBagPanel' then
		D.CheckInjection()
	end
end)
X.RegisterUserSettingsInit('MY_BagEx_BagStack', function() D.CheckInjection() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_BagStack', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_BagStack', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
