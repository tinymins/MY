--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : UI´°¿ÚÃ¶¾ÙÆ÷
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/UIManager')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. '/lang/Dev/')
--------------------------------------------------------------------------------

local UI_DESC = _L.UI_DESC or {}

local function GetMenu(ui)
	local menu, frames = { szOption = ui }, {}
	local frmLayer = Station.Lookup(ui)
	local frame = frmLayer and frmLayer:GetFirstChild()
	while frame do
		table.insert(frames, { szName = frame:GetName() })
		frame = frame:GetNext()
	end
	table.sort(frames, function(a, b) return a.szName < b.szName end)
	for k, v in ipairs(frames) do
		local szPath = ui .. '/' .. v.szName
		local frame = Station.Lookup(szPath)
		local szOption = v.szName
		if UI_DESC[szPath] then
			szOption = szOption .. ' (' .. UI_DESC[szPath]  .. ')'
		end
		table.insert(menu, {
			szOption = szOption,
			bCheck = true,
			bChecked = frame:IsVisible(),
			rgb = frame:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
			fnAction = function()
				if frame:IsVisible() then
					frame:Hide()
				else
					frame:Show()
				end
				if IsCtrlKeyDown() then
					X.UI.CloseFrame(frame)
				end
			end
		})
	end
	return menu
end

local SHARED_MEMORY = X.SHARED_MEMORY
if not SHARED_MEMORY.UI_MANAGER then
	TraceButton_AppendAddonMenu({function()
		for _, f in ipairs(SHARED_MEMORY.UI_MANAGER) do
			local v = f()
			if v then
				return v
			end
		end
	end})
	SHARED_MEMORY.UI_MANAGER = {}
end
table.insert(SHARED_MEMORY.UI_MANAGER, function()
	if not X.IsDebugging('Dev_UIManager') then
		return
	end
	local menu = { szOption = _L['Dev_UIManager'] }
	for k, v in ipairs({ 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' }) do
		table.insert(menu, GetMenu(v))
	end
	return {menu}
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
