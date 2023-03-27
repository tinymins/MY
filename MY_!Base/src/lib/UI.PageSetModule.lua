--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : IconPicker
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.PageSetModule')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/PageSetModule.ini'

-- 创建一个 PageSet 模块
---@param NS table | userdata @需要挂载 PageSet 的命名空间或窗体对象
---@param szPageSetPath string @从窗体根节点到 WndPageSet 对象的路径
---@return table @返回一个模块导出对象
function X.UI.CreatePageSetModule(NS, szPageSetPath)
	local Exports = {
		tModuleAPI = {},
	}
	local Modules = {}
	local PageSetEvent = {}

	local function GetPageSet(frame)
		return frame:Lookup(szPageSetPath)
	end

	-- 注册子模块
	function Exports.RegisterModule(szKey, szName, tModule)
		for i, v in X.ipairs_r(Modules) do
			if v.szKey == szKey then
				table.remove(Modules, i)
			end
		end
		if szName and tModule then
			table.insert(Modules, {
				szKey = szKey,
				szName = szName,
				tModule = tModule,
			})
			if tModule.tAPI then
				for k, v in pairs(tModule.tAPI) do
					Exports.tModuleAPI[k] = v
				end
			end
		end
	end

	-- 初始化主界面
	function Exports.DrawUI(frame)
		local ps = GetPageSet(frame)
		if not ps then
			return
		end
		ps.bInitPageSet = true
		for i, m in ipairs(Modules) do
			local frameTemp, checkbox, page
			if m.szIni and m.szCheckboxPath and m.szPagePath then
				frameTemp = Wnd.OpenWindow(m.szIni, X.NSFormatString('{$NS}#PageSetModuleTemp'))
				checkbox = frameTemp and frameTemp:Lookup(m.szCheckboxPath)
				page = frameTemp and frameTemp:Lookup(m.szPagePath)
			else
				frameTemp = Wnd.OpenWindow(INI_PATH, X.NSFormatString('{$NS}#PageSetModuleTemp'))
				checkbox = frameTemp and frameTemp:Lookup('PageSet_Total/WndCheck_Default')
				page = frameTemp and frameTemp:Lookup('PageSet_Total/Page_Default')
			end
			if checkbox and page then
				checkbox:ChangeRelation(ps, true, true)
				page:ChangeRelation(ps, true, true)
				Wnd.CloseWindow(frameTemp)
				checkbox:SetName('WndCheck_Default')
				page:SetName('Page_Default')
				ps:AddPage(page, checkbox)
				checkbox:Show()
				if m.GetCheckboxPos then
					local x, y = m.GetCheckboxPos(checkbox, m, i)
					checkbox:SetRelPos(x, y)
				else
					checkbox:SetRelX(checkbox:GetRelX() + checkbox:GetW() * (i - 1))
				end
				if m.GetPagePos then
					local x, y = m.GetPagePos(page, m, i)
					page:SetRelPos(x, y)
				else
					page:SetRelPos(0, checkbox:GetH() + 4)
				end
				if m.GetPageSize then
					local w, h = m.GetPageSize(page, m, i)
					page:SetSize(w, h)
				else
					page:SetSize(ps:GetW(), ps:GetH() - checkbox:GetH() - 4)
				end
				local text = checkbox:Lookup(m.szCheckboxTextPath or '', m.szCheckboxTextSubPath or 'Text_CheckDefault')
				if text then
					text:SetText(m.szName)
				end
				checkbox.nIndex = i
				page.nIndex = i
			else
				Wnd.CloseWindow(frameTemp)
			end
		end
		ps.bInitPageSet = nil
	end

	function Exports.ActivePage(frame, szModule, bFirst)
		local ps = GetPageSet(frame)
		if not ps then
			return
		end
		local pageActive = ps:GetActivePage()
		local nActiveIndex, nToIndex = pageActive.nIndex, nil
		for i, m in ipairs(Modules) do
			if m.szKey == szModule or i == szModule then
				nToIndex = i
			end
		end
		if bFirst and not nToIndex then
			nToIndex = 1
		end
		if nToIndex then
			if nToIndex == nActiveIndex then
				X.SafeCallWithThis(ps, PageSetEvent.OnActivePage)
			else
				ps:ActivePage(nToIndex - 1)
			end
		end
	end

	function PageSetEvent.OnFrameCreate()
		Exports.DrawUI(this)
	end

	-- 广播给子模块
	function Exports.BroadcastPageEvent(frame, szEvent, ...)
		local ps = frame:Lookup(szPageSetPath)
		if ps then
			local page = ps:GetFirstChild()
			while page do
				if page:GetName() == 'Page_Default' and page.bInit then
					local m = Modules[page.nIndex]
					if m and m.tModule[szEvent] then
						X.SafeCallWithThis(page, m.tModule[szEvent], ...)
					end
				end
				page = page:GetNext()
			end
		end
	end

	-- 全局广播模块事件
	for _, szEvent in ipairs({
		'OnFrameCreate',
		'OnFrameDestroy',
		'OnFrameBreathe',
		'OnFrameRender',
		'OnFrameDragEnd',
		'OnFrameDragSetPosEnd',
		'OnEvent',
	}) do
		local fnOriginAction = NS[szEvent]
		NS[szEvent] = function(...)
			-- 广播给子模块
			local ps = this:Lookup(szPageSetPath)
			if ps then
				local page = ps:GetFirstChild()
				while page do
					if page:GetName() == 'Page_Default' and page.bInit then
						local m = Modules[page.nIndex]
						if m and m.tModule[szEvent] then
							X.SafeCallWithThis(page, m.tModule[szEvent], ...)
						end
					end
					page = page:GetNext()
				end
			end
			-- 广播给 PageSet 主体
			if PageSetEvent[szEvent] then
				PageSetEvent[szEvent](...)
			end
			-- 广播给原始事件
			if fnOriginAction then
				fnOriginAction(...)
			end
		end
	end

	function PageSetEvent.OnActivePage()
		if this:GetRoot():Lookup(szPageSetPath) == this then
			local ps = this
			if ps.bInitPageSet then
				return
			end
			local page = ps:GetActivePage()
			if page.nIndex then
				local m = Modules[page.nIndex]
				if not page.bInit then
					if m and m.tModule.OnInitPage then
						X.SafeCallWithThis(page, m.tModule.OnInitPage)
					end
					page.bInit = true
				end
				if m and m.tModule.OnActivePage then
					X.SafeCallWithThis(page, m.tModule.OnActivePage)
				end
			end
		end
	end

	-- 根据元素位置转发对应模块事件
	for _, szEvent in ipairs({
		'OnSetFocus',
		'OnKillFocus',
		'OnItemLButtonDown',
		'OnItemMButtonDown',
		'OnItemRButtonDown',
		'OnItemLButtonUp',
		'OnItemMButtonUp',
		'OnItemRButtonUp',
		'OnItemLButtonClick',
		'OnItemMButtonClick',
		'OnItemRButtonClick',
		'OnItemMouseEnter',
		'OnItemMouseLeave',
		'OnItemRefreshTip',
		'OnItemMouseWheel',
		'OnItemLButtonDrag',
		'OnItemLButtonDragEnd',
		'OnLButtonDown',
		'OnLButtonUp',
		'OnLButtonClick',
		'OnLButtonHold',
		'OnMButtonDown',
		'OnMButtonUp',
		'OnMButtonClick',
		'OnMButtonHold',
		'OnRButtonDown',
		'OnRButtonUp',
		'OnRButtonClick',
		'OnRButtonHold',
		'OnMouseEnter',
		'OnMouseLeave',
		'OnScrollBarPosChanged',
		'OnEditChanged',
		'OnEditSpecialKeyDown',
		'OnCheckBoxCheck',
		'OnCheckBoxUncheck',
		'OnActivePage',
	}) do
		local fnOriginAction = NS[szEvent]
		NS[szEvent] = function(...)
			-- 转发给子模块
			local ps = this:Lookup(szPageSetPath)
			if ps then
				local page, nLimit = this, 50
				while page and page:GetParent() ~= ps do
					if nLimit > 0 then
						page = page:GetParent()
						nLimit = nLimit - 1
					else
						page = nil
					end
				end
				if page and page ~= this then
					local m = Modules[page.nIndex]
					if m and m.tModule[szEvent] then
						return m.tModule[szEvent](...)
					end
					return
				end
			end
			-- 转发给 PageSet 主体
			if PageSetEvent[szEvent] and this:GetRoot():Lookup(szPageSetPath) == this then
				return PageSetEvent[szEvent](...)
			end
			-- 转发给原始事件
			if fnOriginAction then
				return fnOriginAction(...)
			end
		end
	end

	return Exports
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
