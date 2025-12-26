--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·模块
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Module')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 全局导出
do
local PRESETS = {
	UIEvent = {
		'___submodule',
		'OnActivePage',
		'OnBeforeNavigate',
		'OnCheckBoxCheck',
		'OnCheckBoxDrag',
		'OnCheckBoxDragBegin',
		'OnCheckBoxDragEnd',
		'OnCheckBoxUncheck',
		'OnDocumentComplete',
		'OnDragButton',
		'OnDragButtonBegin',
		'OnDragButtonEnd',
		'OnEditChanged',
		'OnEditSpecialKeyDown',
		'OnEvent',
		'OnFrameBreathe',
		'OnFrameCreate',
		'OnFrameDestroy',
		'OnFrameDrag',
		'OnFrameDragEnd',
		'OnFrameDragSetPosEnd',
		'OnFrameFadeIn',
		'OnFrameFadeOut',
		'OnFrameHide',
		'OnFrameKeyDown',
		'OnFrameKeyUp',
		'OnFrameKillFocus',
		'OnFrameRender',
		'OnFrameSetFocus',
		'OnFrameShow',
		'OnHistoryChanged',
		'OnIgnoreKeyDown',
		'OnItemDrag',
		'OnItemDragEnd',
		'OnItemKeyDown',
		'OnItemKeyUp',
		'OnItemLButtonClick',
		'OnItemLButtonDBClick',
		'OnItemLButtonDown',
		'OnItemLButtonDrag',
		'OnItemLButtonDragEnd',
		'OnItemLButtonUp',
		'OnItemLongPressGesture',
		'OnItemMButtonClick',
		'OnItemMButtonDBClick',
		'OnItemMButtonDown',
		'OnItemMButtonDrag',
		'OnItemMButtonDragEnd',
		'OnItemMButtonUp',
		'OnItemMouseEnter',
		'OnItemMouseHover',
		'OnItemMouseIn',
		'OnItemMouseIn',
		'OnItemMouseLeave',
		'OnItemMouseMove',
		'OnItemMouseOut',
		'OnItemMouseOut',
		'OnItemMouseWheel',
		'OnItemPanGesture',
		'OnItemRButtonClick',
		'OnItemRButtonDBClick',
		'OnItemRButtonDown',
		'OnItemRButtonDrag',
		'OnItemRButtonDragEnd',
		'OnItemRButtonUp',
		'OnItemRefreshTip',
		'OnItemResize',
		'OnItemResizeEnd',
		'OnItemUpdateSize',
		'OnKillFocus',
		'OnLButtonClick',
		'OnLButtonDBClick',
		'OnLButtonDown',
		'OnLButtonHold',
		'OnLButtonRBClick',
		'OnLButtonUp',
		'OnLongPressRecognizer',
		'OnMButtonClick',
		'OnMButtonDBClick',
		'OnMButtonDown',
		'OnMButtonHold',
		'OnMButtonUp',
		'OnMinimapMouseEnterObj',
		'OnMinimapMouseEnterSelf',
		'OnMinimapMouseLeaveObj',
		'OnMinimapMouseLeaveSelf',
		'OnMinimapSendInfo',
		'OnMouseEnter',
		'OnMouseHover',
		'OnMouseIn',
		'OnMouseLeave',
		'OnMouseOut',
		'OnMouseWheel',
		'OnPanRecognizer',
		'OnPinchRecognizer',
		'OnRButtonClick',
		'OnRButtonDown',
		'OnRButtonHold',
		'OnRButtonUp',
		'OnRefreshTip',
		'OnSceneLButtonDown',
		'OnSceneLButtonUp',
		'OnSceneRButtonDown',
		'OnSceneRButtonUp',
		'OnScrollBarPosChanged',
		'OnSetFocus',
		'OnTapRecognizer',
		'OnTitleChanged',
		'OnWebLoadEnd',
		'OnWebPageClose',
		'OnWndDrag',
		'OnWndDragEnd',
		'OnWndDragSetPosEnd',
		'OnWndKeyDown',
		'OnWndResize',
		'OnWndResizeEnd',
		'OnBindEvent',
		'OnListNodeSelected',
	},
}
local function FormatModuleProxy(options, name)
	local entries = {} -- entries
	local interceptors = {} -- before trigger, return anything if want to intercept
	local triggers = {} -- after trigger, will not be called while intercepted by interceptors
	if options then
		local statics = {} -- static root
		for _, option in ipairs(options) do
			if option.root then
				local presets = option.presets or {} -- presets = {"XXX"},
				if option.preset then -- preset = "XXX",
					table.insert(presets, option.preset)
				end
				for i, s in ipairs(presets) do
					if PRESETS[s] then
						for _, k in ipairs(PRESETS[s]) do
							entries[k] = option.root
						end
					end
				end
			end
			if X.IsTable(option.fields) then
				for k, v in pairs(option.fields) do
					if X.IsNumber(k) and X.IsString(v) then -- "XXX",
						if not X.IsTable(option.root) then
							assert(false, 'Module `' .. name .. '`: static field `' .. v .. '` must be declared with a table root.')
						end
						entries[v] = option.root
					elseif X.IsString(k) then -- XXX = D.XXX,
						statics[k] = v
						entries[k] = statics
					end
				end
			end
			if X.IsTable(option.interceptors) then
				for k, v in pairs(option.interceptors) do
					if X.IsString(k) and X.IsFunction(v) then -- XXX = function(k) end,
						interceptors[k] = v
					end
				end
			end
			if X.IsTable(option.triggers) then
				for k, v in pairs(option.triggers) do
					if X.IsString(k) and X.IsFunction(v) then -- XXX = function(k, v) end,
						triggers[k] = v
					end
				end
			end
		end
	end
	return entries, interceptors, triggers
end
local function ParameterCounter(...)
	return select('#', ...), ...
end
function X.CreateModule(options)
	local name = options.name or 'Unnamed'
	local exportEntries, exportInterceptors, exportTriggers = FormatModuleProxy(options.exports, name)
	local importEntries, importInterceptors, importTriggers = FormatModuleProxy(options.imports, name)
	local function getter(_, k)
		local v = nil
		local interceptor, hasInterceptor = exportInterceptors[k] or exportInterceptors['*'], false
		if interceptor then
			local pc, value = ParameterCounter(interceptor(k))
			if pc >= 1 then
				v = value
				hasInterceptor = true
			end
		end
		if not hasInterceptor then
			local root = exportEntries[k]
			if not root then
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Module `' .. name .. '`: get value failed, unregistered property `' .. k .. '`.', X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				return
			end
			if root then
				v = root[k]
			end
		end
		local trigger = exportTriggers[k]
		if trigger then
			trigger(k, v)
		end
		return v
	end
	local function setter(_, k, v)
		local interceptor, hasInterceptor = importInterceptors[k] or importInterceptors['*'], false
		if interceptor then
			local pc, res, value = ParameterCounter(pcall(interceptor, k, v))
			if not res then
				return
			end
			if pc >= 2 then
				v = value
				hasInterceptor = true
			end
		end
		local root = importEntries[k]
		if not root and not hasInterceptor then
			--[[#DEBUG BEGIN]]
			assert(false, 'Module `' .. name .. '`: set value failed, unregistered property `' .. k .. '`.')
			--[[#DEBUG END]]
			return
		end
		if root then
			root[k] = v
		end
		local trigger = importTriggers[k]
		if trigger then
			trigger(k, v)
		end
	end
	return setmetatable({}, { __index = getter, __newindex = setter, __metatable = true })
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
