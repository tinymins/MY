--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背包锁定
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagLock'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagLock'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.3') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- 检测堆叠按纽
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bag.bEnable then
		-- 植入堆叠按纽
		local frame = Station.Lookup('Normal/BigBagPanel')
		if not frame then
			return
		end
		local btnRef1 = frame:Lookup('Btn_Split')
		local btnRef2 = frame:Lookup('Btn_Stack')
		local btnNew = frame:Lookup('Btn_MY_Lock')
		if not btnRef1 or not btnRef2 then
			return
		end
		local nX = btnRef2:GetRelX() * 2 - btnRef1:GetRelX()
		local nY = btnRef2:GetRelY()
		local nW, nH = btnRef2:GetSize()
		if not btnNew then
			local bEdit = false
			btnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Lock',
					w = nW, h = nH - 3,
					text = _L['Lock'],
					onClick = function()
						bEdit = not bEdit
						if bEdit then
							MY_BagEx_Bag.ShowAllItemShadow(true)
						else
							MY_BagEx_Bag.HideAllItemShadow()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagLock__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- 移除堆叠按纽
		X.UI('Normal/BigBagPanel/Btn_MY_Lock'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagLock__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BagLock',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BagLock = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('SCROLL_UPDATE_LIST', 'MY_BagEx_BagLock', function()
	if (arg0 == 'Handle_Bag_Compact' or arg0 == 'Handle_Bag_Normal')
	and arg1 == 'BigBagPanel' then
		D.CheckInjection()
	end
end)
X.RegisterUserSettingsInit('MY_BagEx_BagLock', function() D.CheckInjection() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_BagLock', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_BagLock', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
