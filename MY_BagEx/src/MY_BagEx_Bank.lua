--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 仓库基础逻辑
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_Bank'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_Bank'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Bank'],
			_L['Bank package sort and stack'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bConfirm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Bank'],
			_L['Sort need confirm'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	tLock = {
		ePathType = X.PATH_TYPE.ROLE,
		eDefaultLocationOverride = X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Bank'],
			_L['Lock cells data'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})
local D = {}

function D.PreventItemUIEvent(el)
	el.OnItemMouseEnter = function() end
	el.OnItemMouseLeave = function() end
	el.OnItemLButtonDown = function() end
	el.OnItemLButtonUp = function() end
	el.OnItemRefreshTip = function() end
end

function D.ShowItemShadow(frame, dwBox, dwX, bEditLock)
	for _, v in ipairs({
		{ szPath = '', szSubPath = 'Handle_Box/' .. dwBox .. '_' .. dwX, bNew = false },
		{ szPath = 'WndScroll_Bag', szSubPath = 'Handle_Normal_Mod' .. dwBox .. '/Handle_Bag_Content/Handle_Mode' .. dwBox .. '_' .. dwX .. '/Box', bNew = true },
		{ szPath = 'WndScroll_Bag', szSubPath = 'Handle_Compact_Mod' .. dwBox .. '_' .. dwX .. '/Box_Impact', bNew = true },
	}) do
		local box = frame:Lookup(v.szPath, v.szSubPath)
		if box then
			local szKey = dwBox .. '_' .. dwX
			local sha
			if v.bNew then
				sha = box:GetParent():Lookup('Shadow_MY_BagEx')
				if not sha then
					sha = X.UI(box:GetParent()):Append('Shadow', { name = 'Shadow_MY_BagEx', w = 0, h = 0 }):Raw()
					sha:SetSize(box:GetSize())
					sha:SetRelPos(box:GetRelPos())
					sha:SetAbsPos(box:GetAbsPos())
					D.PreventItemUIEvent(sha)
				end
				sha:Show()
			else
				local h = box:GetParent():GetParent():Lookup('Handle_MY_BagEx_Shadow')
				if not h then
					h = X.UI(box:GetParent():GetParent()):Append('Handle', { name = 'Handle_MY_BagEx_Shadow' }):Raw()
					D.PreventItemUIEvent(h)
				end
				h:SetSize(box:GetParent():GetSize())
				sha = h:Lookup(dwBox .. '_' .. dwX)
				if not sha then
					sha = X.UI(h):Append('Shadow', { name = dwBox .. '_' .. dwX, w = 0, h = 0 }):Raw()
					sha:SetSize(box:GetSize())
					D.PreventItemUIEvent(sha)
				end
				sha:SetRelPos(box:GetRelPos())
				sha:SetAbsPos(box:GetAbsPos())
				sha:Show()
			end
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
	local frame = Station.Lookup('Normal/BigBankPanel')
	if not frame then
		return
	end
	-- 遮罩紧凑模式切换按钮
	local chk = frame:Lookup('CheckBox_Compact')
	if chk then
		local wnd = frame:Lookup('Wnd_MY_BagEx_CheckBox_Compact')
		if not wnd then
			wnd = X.UI(frame):Append('WndWindow', { name = 'Wnd_MY_BagEx_CheckBox_Compact' }):Raw()
			wnd:SetSize(chk:GetSize())
			wnd:SetRelPos(chk:GetRelPos())
		end
		wnd:Show()
	end
	-- 遮罩背包列表
	local h = frame:Lookup('', '')
	local box = h:Lookup('Box_Bag1')
	if box then
		local nRelX, nRelY = box:GetRelPos()
		local nAbsX, nAbsY = box:GetAbsPos()
		local nW, nH = box:GetSize()
		local i = 1
		while box do
			i = i + 1
			box = frame:Lookup('', 'Box_Bag' .. i)
			if box then
				nW = box:GetRelX() - nRelX + box:GetW()
				nH = box:GetRelY() - nRelY + box:GetH()
			end
		end
		local sha = h:Lookup('Shadow_MY_BagEx')
		if not sha then
			sha = X.UI(h):Append('Shadow', { name = 'Shadow_MY_BagEx', w = 0, h = 0 }):Raw()
			sha:SetColorRGB(255, 255, 255)
			sha:SetAlpha(0)
			sha:SetSize(nW, nH)
			sha:SetRelPos(nRelX, nRelY)
			sha:SetAbsPos(nAbsX, nAbsY)
			D.PreventItemUIEvent(sha)
		end
		sha:Show()
	end
	-- 遮罩背包物品
	for _, dwBox in ipairs(X.CONSTANT.INVENTORY_BANK_LIST) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			D.ShowItemShadow(frame, dwBox, dwX, bEditLock)
		end
	end
end

function D.HideItemShadow(frame, dwBox, dwX)
	for _, v in ipairs({
		{ szPath = '', szSubPath = 'Handle_Box/' .. dwBox .. '_' .. dwX, bNew = false },
		{ szPath = 'WndScroll_Bag', szSubPath = 'Handle_Normal_Mod' .. dwBox .. '/Handle_Bag_Content/Handle_Mode' .. dwBox .. '_' .. dwX .. '/Box', bNew = true },
		{ szPath = 'WndScroll_Bag', szSubPath = 'Handle_Compact_Mod' .. dwBox .. '_' .. dwX .. '/Box_Impact', bNew = true },
	}) do
		local box = frame:Lookup(v.szPath, v.szSubPath)
		if box then
			if v.bNew then
				local sha = box:GetParent():Lookup('Shadow_MY_BagEx')
				if sha then
					sha:Hide()
				end
			else
				local sha = box:GetParent():GetParent():Lookup('Handle_MY_BagEx_Shadow/' .. dwBox .. '_' .. dwX)
				if sha then
					sha:Hide()
				end
			end
		end
	end
end

function D.HideAllItemShadow()
	local frame = Station.Lookup('Normal/BigBankPanel')
	if not frame then
		return
	end
	-- 遮罩紧凑模式切换按钮
	local chk = frame:Lookup('CheckBox_Compact')
	if chk then
		local wnd = frame:Lookup('Wnd_MY_BagEx_CheckBox_Compact')
		if wnd then
			wnd:Hide()
		end
	end
	-- 遮罩背包列表
	local h = frame:Lookup('', '')
	if h then
		local sha = h:Lookup('Shadow_MY_BagEx')
		if sha then
			sha:Hide()
		end
	end
	-- 遮罩背包物品
	for _, dwBox in ipairs(X.CONSTANT.INVENTORY_BANK_LIST) do
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
function D.CheckConflict(bRemoveInjection)
	if not bRemoveInjection and O.bEnable then
		-- 隐藏冲突的系统按钮
		for _, szPath in ipairs({
			'Normal/BigBankPanel/Btn_CU',
			'Normal/BigBankPanel/Btn_Stack',
			'Normal/BigBankPanel/Btn_Lock',
		}) do
			local el = Station.Lookup(szPath)
			if el then
				el:Hide()
			end
		end
	else
		-- 恢复冲突的系统按钮
		for _, szPath in ipairs({
			'Normal/BigBankPanel/Btn_CU',
			'Normal/BigBankPanel/Btn_Stack',
			'Normal/BigBankPanel/Btn_Lock',
		}) do
			local el = Station.Lookup(szPath)
			if el then
				el:Show()
			end
		end
	end
end

function D.CheckEnable(bRemoveInjection)
	D.CheckConflict(bRemoveInjection)
	MY_BagEx_BankSort.CheckInjection(bRemoveInjection)
	MY_BagEx_BankStack.CheckInjection(bRemoveInjection)
	MY_BagEx_BankLock.CheckInjection(bRemoveInjection)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Bank package sort and stack'],
		checked = O.bEnable,
		onCheck = function(bChecked)
			O.bEnable = bChecked
			D.CheckEnable()
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
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_Bank',
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
MY_BagEx_Bank = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('ON_SET_BANK_COMPACT_MODE', 'MY_BagEx_Bank', function() X.DelayCall(D.CheckEnable) end)
X.RegisterUserSettingsInit('MY_BagEx_Bank', function() X.DelayCall(D.CheckEnable) end)
X.RegisterFrameCreate('BigBankPanel', 'MY_BagEx_Bank', function() X.DelayCall(D.CheckEnable) end)
X.RegisterReload('MY_BagEx_Bank', function() D.CheckEnable(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
