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
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagStack'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagStack'
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
			X.OutputSystemAnnounceMessage(_L['Bag panel closed, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
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
					local szKey = X.GetItemKey(kItem) .. '_' .. (kItem.bBind and '1' or '0')
					local nLeftExistTime = bStackLeftExistTime and 0 or kItem.GetLeftExistTime()
					local tPos = tList[szKey] and tList[szKey][nLeftExistTime]
					if tPos then
						local dwBox1, dwX1 = tPos.dwBox, tPos.dwX
						--[[#DEBUG BEGIN]]
						X.OutputDebugMessage('MY_BagEx_BagStack', 'ExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
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
		X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagStack__Stack', function()
			local dwBox, dwX, bNewAdd = arg0, arg1, arg2
			if bNewAdd then
				X.OutputSystemAnnounceMessage(_L['Put new item in bag detected, stack exited!'], X.CONSTANT.MSG_THEME.ERROR)
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
	local hFrame = Station.Lookup('Normal/BigBagPanel')
	if not hFrame then
		return
	end
	local hInjectRoot = hFrame:Lookup('WndContainer_Btn') or hFrame
	if not bRemoveInjection and MY_BagEx_Bag.IsEnabled() then
		-- Ö²Èë¶Ñµþ°´Å¦
		local hWndRef = hInjectRoot:Lookup('Wnd_MY_Split')
		local hBtnNew = hInjectRoot:Lookup('Btn_MY_Stack')
		if not hWndRef then
			return
		end
		local nX = hWndRef:GetRelX() + hWndRef:GetW() + 3
		local nY = hWndRef:GetRelY()
		local nH = hWndRef:GetH()
		if not hBtnNew then
			hBtnNew = X.UI(hInjectRoot)
				:Append('WndButton', {
					name = 'Btn_MY_Stack',
					w = 'auto', h = nH,
					text = _L['Stack'],
					onClick = function()
						MY_BagEx_Bag.ShowAllItemShadow()
						if MY_BagEx_Bag.bConfirm then
							X.Confirm('MY_BagEx_BagStack', _L['Sure to start bag stack?'], {
								x = hFrame:GetAbsX() + hFrame:GetW() / 2,
								y = hFrame:GetAbsY() + hFrame:GetH() / 2,
								fnResolve = D.Operate,
								fnReject = MY_BagEx_Bag.HideAllItemShadow,
								fnCancel = MY_BagEx_Bag.HideAllItemShadow,
								fnAutoClose = function() return not hFrame or not hFrame:IsVisible() end,
							})
						else
							D.Operate()
						end
					end,
				})
				:Raw()
		end
		if not hBtnNew then
			return
		end
		hBtnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagStack__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
		end)
	else
		-- ÒÆ³ý¶Ñµþ°´Å¦
		X.UI(hInjectRoot:Lookup('Btn_MY_Stack')):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagStack__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- È«¾Öµ¼³ö
--------------------------------------------------------------------------------
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
