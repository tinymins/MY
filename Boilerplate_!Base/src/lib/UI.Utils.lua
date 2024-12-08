--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面工具库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.Utils')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.UI.GetFrameAnchor(...)
	return GetFrameAnchor(...)
end

function X.UI.SetFrameAnchor(frame, anchor)
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
end

function X.UI.GetTreePath(raw)
	local tTreePath = {}
	if X.IsTable(raw) and raw.GetTreePath then
		table.insert(tTreePath, (raw:GetTreePath()):sub(1, -2))
		while(raw and raw:GetType():sub(1, 3) ~= 'Wnd') do
			local szName = raw:GetName()
			if not szName or szName == '' then
				table.insert(tTreePath, 2, raw:GetIndex())
			else
				table.insert(tTreePath, 2, szName)
			end
			raw = raw:GetParent()
		end
	else
		table.insert(tTreePath, tostring(raw))
	end
	return table.concat(tTreePath, '/')
end

do
local ui, cache
function X.UI.GetTempElement(szType, szKey)
	if not X.IsString(szType) then
		return
	end
	if not X.IsString(szKey) then
		szKey = 'Default'
	end
	if not cache or not ui or ui:Count() == 0 then
		cache = {}
		ui = X.UI.CreateFrame(X.NSFormatString('{$NS}#TempElement'), { empty = true }):Hide()
	end
	local szName = szType .. '_' .. szKey
	local raw = cache[szName]
	if not raw then
		raw = ui:Append(szType, {
			name = szName,
		})[1]
		cache[szName] = raw
	end
	return raw
end
end

function X.UI.ScrollIntoView(el, scrollY, nOffsetY, scrollX, nOffsetX)
	local elParent, nParentW, nParentH = el:GetParent()
	local nX, nY = el:GetAbsX() - elParent:GetAbsX(), el:GetAbsY() - elParent:GetAbsY()
	if elParent:GetType() == 'WndContainer' then
		nParentW, nParentH = elParent:GetAllContentSize()
	else
		nParentW, nParentH = elParent:GetAllItemSize()
	end
	if nOffsetY then
		nY = nY + nOffsetY
	end
	if scrollY then
		scrollY:SetScrollPos(nY / nParentH * scrollY:GetStepCount())
	end
	if nOffsetX then
		nX = nX + nOffsetX
	end
	if scrollX then
		scrollX:SetScrollPos(nX / nParentW * scrollX:GetStepCount())
	end
end

function X.UI.LookupFrame(szName)
	for _, v in ipairs(X.UI.LAYER_LIST) do
		local frame = Station.Lookup(v .. '/' .. szName)
		if frame then
			return frame
		end
	end
end

do
local ITEM_COUNT = {}
local HOOK_BEFORE = setmetatable({}, { __mode = 'v' })
local HOOK_AFTER = setmetatable({}, { __mode = 'v' })

function X.UI.HookHandleAppend(hList, fnOnAppendItem)
	-- 注销旧的 HOOK 函数
	if HOOK_BEFORE[hList] then
		UnhookTableFunc(hList, 'AppendItemFromIni'   , HOOK_BEFORE[hList])
		UnhookTableFunc(hList, 'AppendItemFromData'  , HOOK_BEFORE[hList])
		UnhookTableFunc(hList, 'AppendItemFromString', HOOK_BEFORE[hList])
	end
	if HOOK_AFTER[hList] then
		UnhookTableFunc(hList, 'AppendItemFromIni'   , HOOK_AFTER[hList])
		UnhookTableFunc(hList, 'AppendItemFromData'  , HOOK_AFTER[hList])
		UnhookTableFunc(hList, 'AppendItemFromString', HOOK_AFTER[hList])
	end

	-- 生成新的 HOOK 函数
	local function BeforeAppendItem(hList)
		ITEM_COUNT[hList] = hList:GetItemCount()
	end
	HOOK_BEFORE[hList] = BeforeAppendItem

	local function AfterAppendItem(hList)
		local nCount = ITEM_COUNT[hList]
		if not nCount then
			return
		end
		ITEM_COUNT[hList] = nil
		for i = nCount, hList:GetItemCount() - 1 do
			local hItem = hList:Lookup(i)
			fnOnAppendItem(hList, hItem)
		end
	end
	HOOK_AFTER[hList] = AfterAppendItem

	-- 应用 HOOK 函数
	ITEM_COUNT[hList] = 0
	AfterAppendItem(hList)
	HookTableFunc(hList, 'AppendItemFromIni'   , BeforeAppendItem, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendItemFromIni'   , AfterAppendItem , { bAfterOrigin = true  })
	HookTableFunc(hList, 'AppendItemFromData'  , BeforeAppendItem, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendItemFromData'  , AfterAppendItem , { bAfterOrigin = true  })
	HookTableFunc(hList, 'AppendItemFromString', BeforeAppendItem, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendItemFromString', AfterAppendItem , { bAfterOrigin = true  })
end
end

do
local ITEM_COUNT = {}
local HOOK_BEFORE = setmetatable({}, { __mode = 'v' })
local HOOK_AFTER = setmetatable({}, { __mode = 'v' })

function X.UI.HookContainerAppend(hList, fnOnAppendContent)
	-- 注销旧的 HOOK 函数
	if HOOK_BEFORE[hList] then
		UnhookTableFunc(hList, 'AppendContentFromIni'   , HOOK_BEFORE[hList])
	end
	if HOOK_AFTER[hList] then
		UnhookTableFunc(hList, 'AppendContentFromIni'   , HOOK_AFTER[hList])
	end

	-- 生成新的 HOOK 函数
	local function BeforeAppendContent(hList)
		ITEM_COUNT[hList] = hList:GetAllContentCount()
	end
	HOOK_BEFORE[hList] = BeforeAppendContent

	local function AfterAppendContent(hList)
		local nCount = ITEM_COUNT[hList]
		if not nCount then
			return
		end
		ITEM_COUNT[hList] = nil
		for i = nCount, hList:GetAllContentCount() - 1 do
			local hContent = hList:LookupContent(i)
			fnOnAppendContent(hList, hContent)
		end
	end
	HOOK_AFTER[hList] = AfterAppendContent

	-- 应用 HOOK 函数
	ITEM_COUNT[hList] = 0
	AfterAppendContent(hList)
	HookTableFunc(hList, 'AppendContentFromIni'   , BeforeAppendContent, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendContentFromIni'   , AfterAppendContent , { bAfterOrigin = true  })
end
end

-- 格式化界面事件回调函数行为掩码返回值，同官方 FORMAT_WMSG_RET 函数（未导出）
---@param stopPropagation boolean @事件已处理，停止冒泡寻找父层元素
---@param callFrameBinding boolean @继续调用窗体绑定的脚本上的同名回调函数
---@return number 界面事件回调函数行为掩码值
function X.UI.FormatUIEventMask(stopPropagation, callFrameBinding)
	local ret = 0
	if stopPropagation then
		ret = ret + 1 --01
	end
	if callFrameBinding then
		ret = ret + 2 --10
	end
	return ret
end

-- 设置按钮控件图素
---@param hWndCheckBox userdata @按钮框控件句柄
---@param szImagePath string @图素地址
---@param nNormal number @正常状态下图素
---@param nMouseOver number @鼠标划过时图素
---@param nMouseDown number @鼠标按下时图素
---@param nDisable number @禁用时图素
function X.UI.SetButtonUITex(
	hButton,
	szImagePath,
	nNormal,
	nMouseOver,
	nMouseDown,
	nDisable
)
	hButton:SetAnimatePath(szImagePath)
	hButton:SetAnimateGroupNormal(nNormal)
	hButton:SetAnimateGroupMouseOver(nMouseOver)
	hButton:SetAnimateGroupMouseDown(nMouseDown)
	hButton:SetAnimateGroupDisable(nDisable)
end

-- 设置复选框控件图素
-- 分为两个维度：(未勾选, 勾选) x (正常, 划过, 按下, 禁用)
---@param hWndCheckBox userdata @复选框控件句柄
---@param szImagePath string @图素地址
---@param nUnCheckAndEnable number @未选中、启用状态时图素（未勾选+正常）
---@param nUncheckedAndEnableWhenMouseOver number @未选中、启用状态时鼠标移入时图素（未勾选+划过）
---@param nChecking number @未选中、按下时图素（未勾选+按下）
---@param nUnCheckAndDisable number @未选中、禁用状态时图素（未勾选+禁用）
---@param nCheckAndEnable number @选中、启用状态时图素（勾选+正常）
---@param nCheckedAndEnableWhenMouseOver number @选中、启用状态时鼠标移入时图素（勾选+划过）
---@param nUnChecking number @选中、按下时图素（勾选+按下）
---@param nCheckAndDisable number @选中、禁用状态时图素（勾选+禁用）
---@param nUncheckedAndDisableWhenMouseOver? number @未选中、禁用状态时鼠标移入时图素，默认取未选中、禁用状态时图素
---@param nCheckedAndDisableWhenMouseOver? number @选中、禁用状态时鼠标移入时图素，默认取选中、禁用状态时图素
function X.UI.SetCheckBoxUITex(
	hWndCheckBox,
	szImagePath,
	nUnCheckAndEnable,
	nUncheckedAndEnableWhenMouseOver,
	nChecking,
	nUnCheckAndDisable,
	nCheckAndEnable,
	nCheckedAndEnableWhenMouseOver,
	nUnChecking,
	nCheckAndDisable,
	nUncheckedAndDisableWhenMouseOver,
	nCheckedAndDisableWhenMouseOver
)
	if not nUncheckedAndDisableWhenMouseOver then
		nUncheckedAndDisableWhenMouseOver = nUnCheckAndDisable
	end
	if not nCheckedAndDisableWhenMouseOver then
		nCheckedAndDisableWhenMouseOver = nCheckAndDisable
	end
	return hWndCheckBox:SetAnimation(
		szImagePath,
		nUnCheckAndEnable,
		nCheckAndEnable,
		nUnCheckAndDisable,
		nCheckAndDisable,
		nChecking,
		nUnChecking,
		nCheckedAndEnableWhenMouseOver,
		nUncheckedAndEnableWhenMouseOver,
		nCheckedAndDisableWhenMouseOver,
		nUncheckedAndDisableWhenMouseOver
	)
end

X.UI.UpdateItemInfoBoxObject = _G.UpdateItemInfoBoxObject or UpdataItemInfoBoxObject

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
