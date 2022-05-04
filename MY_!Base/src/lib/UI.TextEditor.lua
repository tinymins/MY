--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : TextEditor
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_NAME = X.NSFormatString('{$NS}.UI.TextEditor')
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------
X.ReportModuleLoading(MODULE_NAME, 'START')
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
		local nW, nH = select(3, ui:Size())
		ui:Fetch('WndEditBox'):Size(nW, nH)
	end
	ui = X.UI.CreateFrame(szFrameName, {
		w = w, h = h, alpha = opt.alpha or 180,
		text = opt.title or _L['Text Editor'],
		anchor = opt.anchor or { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
		simple = true, close = true, esc = true,
		dragresize = true, minimize = true, ondragresize = OnResize,
	})
	ui:Append('WndEditBox', { x = 0, y = 0, multiline = true, text = szText })
	ui:Focus()
	OnResize()
	return ui
end

X.ReportModuleLoading(MODULE_NAME, 'FINISH')
