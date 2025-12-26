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
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagSplit'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagSplit'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- 检测增加按纽
function D.CheckInjection(bRemoveInjection)
	local hFrame = Station.Lookup('Normal/BigBagPanel')
	if not hFrame then
		return
	end
	local hInjectRoot = hFrame:Lookup('WndContainer_Btn') or hFrame
	if not bRemoveInjection and MY_BagEx_Bag.IsEnabled() then
		-- 植入拆分按纽
		local hBtnRef = hInjectRoot:Lookup('Btn_MY_Sort')
		local hWndNew = hInjectRoot:Lookup('Wnd_MY_Split')
		local hBtnNew = hInjectRoot:Lookup('Wnd_MY_Split/Btn_Split')
		if not hBtnRef then
			return
		end
		local nX = hBtnRef:GetRelX() + hBtnRef:GetW() + 3
		local nY = hBtnRef:GetRelY()
		local nH = hBtnRef:GetH()
		if not hWndNew then
			hWndNew = X.UI(hInjectRoot)
				:Append('WndWindow', {
					name = 'Wnd_MY_Split',
					w = 0, h = nH,
				})
				:Raw()
			hBtnNew = X.UI(hWndNew)
				:Append('WndButton', {
					name = 'Btn_Split',
					w = 'auto', h = nH,
					text = _L['Split'],
					tip = {
						render = _L['Split stacked items (hotkey SHIFT+LClick)'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
				})
				:Raw()
			hWndNew:SetW(hBtnNew:GetW())
		end
		if not hWndNew or not hBtnNew then
			return
		end
		hWndNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSplit__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
		end)
	else
		-- 移除整理按纽
		X.UI(hInjectRoot:Lookup('Wnd_MY_Split')):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSplit__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BagSplit',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BagSplit = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('SCROLL_UPDATE_LIST', 'MY_BagEx_BagSplit', function()
	if (arg0 == 'Handle_Bag_Compact' or arg0 == 'Handle_Bag_Normal')
	and arg1 == 'BigBagPanel' then
		D.CheckInjection()
	end
end)
X.RegisterUserSettingsInit('MY_BagEx_BagSplit', function() D.CheckInjection() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_BagSplit', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_BagSplit', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
