--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 背包基础逻辑
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_Bag'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_Bag'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_BagEx_Bag', { remake = true })
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Bag'],
			_L['Bag package sort and stack'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
		szRestriction = 'MY_BagEx_Bag',
	},
	bConfirm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Bag'],
			_L['Sort need confirm'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
		szRestriction = 'MY_BagEx_Bag',
	},
	tLock = {
		ePathType = X.PATH_TYPE.ROLE,
		eDefaultLocationOverride = X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Bag'],
			_L['Lock cells data'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
		szRestriction = 'MY_BagEx_Bag',
	},
})
local D = {}

function D.IsEnabled()
	return O.bEnable and not X.IsInInventoryPackageLimitedMap() and not X.IsRestricted('MY_BagEx_Bag')
end

function D.ShowItemShadow(frame, dwBox, dwX, bEditLock)
	for _, szPath in ipairs({
		'Handle_Bag_Compact/Mode_' .. dwBox .. '_' .. dwX .. '/' .. dwBox .. '_' .. dwX,
		'Handle_Bag_Normal/Handle_Bag' .. dwBox .. '/Handle_Bag_Content' .. dwBox .. '/Mode_' .. dwX .. '/' .. dwBox .. '_' .. dwX
	}) do
		local box = frame:Lookup('', szPath)
		if box then
			local szKey = dwBox .. '_' .. dwX
			local sha = box:GetParent():Lookup('Shadow_MY_BagEx')
			if not sha then
				sha = X.UI(box:GetParent()):Append('Shadow', { name = 'Shadow_MY_BagEx', w = 0, h = 0 }):Raw()
				sha:SetSize(box:GetSize())
				sha:SetRelPos(box:GetRelPos())
				sha:SetAbsPos(box:GetAbsPos())
			end
			sha:Show()
			if O.tLock[szKey] then
				sha:SetAlpha(128)
				sha:SetColorRGB(0, 0, 0)
			else
				sha:SetAlpha(50)
				sha:SetColorRGB(255, 255, 255)
			end
			if bEditLock then
				sha.OnItemLButtonClick = function()
					local tLock = O.tLock
					tLock[szKey] = not tLock[szKey] or nil
					if tLock[szKey] then
						sha:SetAlpha(128)
						sha:SetColorRGB(0, 0, 0)
					else
						sha:SetAlpha(50)
						sha:SetColorRGB(255, 255, 255)
					end
					O.tLock = tLock
				end
			else
				sha.OnItemLButtonClick = nil
			end
		end
	end
end

function D.ShowAllItemShadow(bEditLock)
	local frame = Station.Lookup('Normal/BigBagPanel')
	if not frame then
		return
	end
	-- 遮罩背包列表
	local h = frame:Lookup('', 'Handle_BagList')
	if h then
		local sha = h:Lookup('Shadow_MY_BagEx')
		if not sha then
			sha = X.UI(h):Append('Shadow', { name = 'Shadow_MY_BagEx', w = 0, h = 0 }):Raw()
			sha:SetColorRGB(255, 255, 255)
			sha:SetAlpha(0)
			sha:SetSize(h:GetSize())
			sha:SetRelPos(0, 0)
			sha:SetAbsPos(h:GetAbsPos())
		end
		sha:Show()
	end
	-- 遮罩背包物品
	for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.PACKAGE)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			D.ShowItemShadow(frame, dwBox, dwX, bEditLock)
		end
	end
end

function D.HideItemShadow(frame, dwBox, dwX)
	for _, szPath in ipairs({
		'Handle_Bag_Compact/Mode_' .. dwBox .. '_' .. dwX .. '/' .. dwBox .. '_' .. dwX,
		'Handle_Bag_Normal/Handle_Bag' .. dwBox .. '/Handle_Bag_Content' .. dwBox .. '/Mode_' .. dwX .. '/' .. dwBox .. '_' .. dwX
	}) do
		local box = frame:Lookup('', szPath)
		if box then
			local sha = box:GetParent():Lookup('Shadow_MY_BagEx')
			if sha then
				sha:Hide()
			end
		end
	end
end

function D.HideAllItemShadow()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if not frame then
		return
	end
	-- 遮罩背包列表
	local h = frame:Lookup('', 'Handle_BagList')
	if h then
		local sha = h:Lookup('Shadow_MY_BagEx')
		if sha then
			sha:Hide()
		end
	end
	-- 遮罩背包物品
	for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.PACKAGE)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			D.HideItemShadow(frame, dwBox, dwX)
		end
	end
end

function D.IsItemBoxLocked(dwBox, dwX)
	local szKey = dwBox .. '_' .. dwX
	return O.tLock[szKey] or false
end

-- 检测冲突
function D.CheckConflict(bRestore)
	if not bRestore and D.IsEnabled() then
		-- 隐藏冲突的系统按钮
		for _, szPath in ipairs({
			'Normal/BigBagPanel/Btn_CU',
			'Normal/BigBagPanel/Btn_Split',
			'Normal/BigBagPanel/Btn_Stack',
			'Normal/BigBagPanel/Btn_LockSort',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_CU',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_Split',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_Stack',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_LockSort',
		}) do
			local el = Station.Lookup(szPath)
			if el then
				el:Hide()
			end
		end
	else
		-- 恢复冲突的系统按钮
		for _, szPath in ipairs({
			'Normal/BigBagPanel/Btn_CU',
			'Normal/BigBagPanel/Btn_Split',
			'Normal/BigBagPanel/Btn_Stack',
			'Normal/BigBagPanel/Btn_LockSort',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_CU',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_Split',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_Stack',
			'Normal/BigBagPanel/WndContainer_Btn/Btn_LockSort',
		}) do
			local el = Station.Lookup(szPath)
			if el then
				el:Show()
			end
		end
	end
end

function D.OnEnableChange()
	D.CheckConflict()
	MY_BagEx_BagSort.CheckInjection()
	MY_BagEx_BagSplit.CheckInjection()
	MY_BagEx_BagStack.CheckInjection()
	MY_BagEx_BagLock.CheckInjection()
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	if not X.IsRestricted('MY_BagEx_Bag') then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 200,
			text = _L['Bag package sort and stack'],
			checked = O.bEnable,
			onCheck = function(bChecked)
				O.bEnable = bChecked
				D.OnEnableChange()
			end,
		}):AutoWidth():Width() + 5
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 200,
			text = _L['Need confirm'],
			checked = O.bConfirm,
			onCheck = function(bChecked)
				O.bConfirm = bChecked
			end,
			autoEnable = function() return O.bEnable end,
		}):AutoWidth():Width() + 5
		nX = nPaddingX
		nY = nY + nLH
	end
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_Bag',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
				ShowItemShadow = D.ShowItemShadow,
				ShowAllItemShadow = D.ShowAllItemShadow,
				HideItemShadow = D.HideItemShadow,
				HideAllItemShadow = D.HideAllItemShadow,
				IsItemBoxLocked = D.IsItemBoxLocked,
				IsEnabled = D.IsEnabled,
			},
		},
		{
			fields = {
				'bConfirm',
			},
			root = O,
		},
	},
}
MY_BagEx_Bag = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_BagEx_Bag', function() D.CheckConflict() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_Bag', function() D.CheckConflict() end)
X.RegisterReload('MY_BagEx_Bag', function() D.CheckConflict(true) end)
X.RegisterEvent('LOADING_ENDING', 'MY_BagEx_Bag', function() D.OnEnableChange() end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
