--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : TextEditor
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.TextEditor')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 打开文本编辑器
function X.UI.OpenTextEditor(szText, opt)
	local szFrameName
	if X.IsString(opt) then
		szFrameName = opt.name
	end
	if not X.IsTable(opt) then
		opt = {}
	end
	if not szFrameName then
		szFrameName = opt.name or X.NSFormatString('{$NS}_DefaultTextEditor')
	end
	local w, h, ui = opt.w or 400, opt.h or 300, nil
	local function OnResize()
		local nW, nH = ui:ContainerSize()
		ui:Fetch('WndEditBox'):Size(nW, nH)
	end
	ui = X.UI.CreateFrame(szFrameName, {
		w = w, h = h, alpha = opt.alpha or 180,
		text = opt.title or _L['Text Editor'],
		anchor = opt.anchor or { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
		theme = X.UI.FRAME_THEME.SIMPLE, close = true, esc = true,
		resize = true, minimize = true, onSizeChange = OnResize,
	})
	ui:Append('WndEditBox', { x = 0, y = 0, multiline = true, text = szText })
	ui:Focus()
	OnResize()
	return ui
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
