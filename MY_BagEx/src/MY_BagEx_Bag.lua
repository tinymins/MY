--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 背包堆叠
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_Bag'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_Bag'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bConfirm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tLock = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})
local D = {}

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
				sha = X.UI(box:GetParent()):Append('Shadow', { name = 'Shadow_MY_BagEx' }):Raw()
				sha:SetSize(box:GetSize())
				sha:SetRelPos(box:GetRelPos())
				sha:SetAbsPos(box:GetAbsPos())
			end
			sha:Show()
			if O.tLock[szKey] then
				sha:SetAlpha(192)
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
						sha:SetAlpha(192)
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
			sha = X.UI(h):Append('Shadow', { name = 'Shadow_MY_BagEx' }):Raw()
			sha:SetColorRGB(255, 255, 255)
			sha:SetAlpha(0)
			sha:SetSize(h:GetSize())
			sha:SetRelPos(0, 0)
			sha:SetAbsPos(h:GetAbsPos())
		end
		sha:Show()
	end
	-- 遮罩背包物品
	local me = X.GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() - 1 do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
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
	local me = X.GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() - 1 do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
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
	if not bRestore and O.bEnable then
		-- 隐藏冲突的系统按钮
		for _, szPath in ipairs({
			'Normal/BigBagPanel/Btn_CU',
			'Normal/BigBagPanel/Btn_Stack',
			'Normal/BigBagPanel/Btn_LockSort',
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
			'Normal/BigBagPanel/Btn_Stack',
			'Normal/BigBagPanel/Btn_LockSort',
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
	MY_BagEx_BagStack.CheckInjection()
	MY_BagEx_BagLock.CheckInjection()
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
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
	}):AutoWidth():Width() + 5
	return nX, nY
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
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
			},
		},
		{
			fields = {
				'bEnable',
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
