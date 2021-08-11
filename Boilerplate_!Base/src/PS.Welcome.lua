--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : »¶Ó­Ò³
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps/')

local PS = { bWelcome = true, bHide = true }

local function GetMemoryText()
	return string.format('Memory:%.1fMB', collectgarbage('count') / 1024)
end

local function GetAdvText()
	local me = GetClientPlayer()
	if not me then
		return ''
	end
	return _L('%s, welcome to use %s!', me.szName, X.PACKET_INFO.NAME)
end

local function GetSvrText()
	local nFeeTime = X.GetTimeOfFee() - GetCurrentTime()
	return X.GetServer() .. ' (' .. X.GetRealServer() .. ')'
		.. g_tStrings.STR_CONNECT
		.. (nFeeTime > 0 and X.FormatTimeCounter(nFeeTime, _L['Fee left %H:%mm:%ss']) or _L['Fee left unknown'])
end

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	ui:Append('Shadow', { name = 'Shadow_Adv', x = 0, y = 0, color = { 140, 140, 140 } })
	ui:Append('Image', { name = 'Image_Adv', x = 0, y = 0, image = X.PACKET_INFO.POSTER_UITEX, imageframe = GetTime() % X.PACKET_INFO.POSTER_FRAME_COUNT })
	ui:Append('Text', { name = 'Text_Adv', x = 10, y = 300, w = 557, font = 200, text = GetAdvText() })
	ui:Append('Text', { name = 'Text_Memory', x = 10, y = 300, w = 150, alpha = 150, font = 162, text = GetMemoryText(), halign = 2 })
	ui:Append('Text', { name = 'Text_Svr', x = 10, y = 345, w = 557, font = 204, text = GetSvrText(), alpha = 220 })
	local x = 7
	-- Êý¾ÝÎ»ÖÃ
	x = x + ui:Append('WndButton', {
		x = x, y = 405,
		name = 'WndButton_UserPreference',
		text = _L['User preference storage'],
		menu = function()
			return {
				{
					szOption = _L['User preference'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['User preference'] .. _L['Storage location'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						local szRoot = X.GetAbsolutePath({'', X.PATH_TYPE.ROLE}):gsub('/', '\\')
						X.OpenFolder(szRoot)
						UI.OpenTextEditor(szRoot)
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Server preference'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['Server preference'] .. _L['Storage location'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						local szRoot = X.GetAbsolutePath({'', X.PATH_TYPE.SERVER}):gsub('/', '\\')
						X.OpenFolder(szRoot)
						UI.OpenTextEditor(szRoot)
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Global preference'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['Global preference'] .. _L['Storage location'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						local szRoot = X.GetAbsolutePath({'', X.PATH_TYPE.GLOBAL}):gsub('/', '\\')
						X.OpenFolder(szRoot)
						UI.OpenTextEditor(szRoot)
						UI.ClosePopupMenu()
					end,
				},
				CONSTANT.MENU_DIVIDER,
				{
					szOption = _L['Flush data'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['Config and data will be saved when exit game, click to save immediately'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						X.FireFlush()
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Export data'],
					fnAction = function()
						X.OpenUserSettingsExportPanel()
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Import data'],
					fnAction = function()
						X.OpenUserSettingsImportPanel()
						UI.ClosePopupMenu()
					end,
				},
			}
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndButton', {
		name = 'WndButton_AddonErrorMessage',
		x = x, y = 405,
		text = _L['Error message'],
		tip = _L['Show error message'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		onclick = function()
			if IsCtrlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
				X.IsDebugClient('Dev_LuaWatcher', true, true)
				X.IsDebugClient('Dev_UIEditor', true, true)
				X.IsDebugClient('Dev_UIManager', true, true)
				X.IsDebugClient('Dev_UIFindStation', true, true)
				X.Systopmsg(_L['Debug tools has been enabled...'])
				X.ReopenPanel()
				return
			end
			UI.OpenTextEditor(X.GetAddonErrorMessage())
		end,
	}):AutoWidth():Width() + 5
	PS.OnPanelResize(wnd)
end

function PS.OnPanelResize(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local scaleH = w / 557 * 278
	local bottomH = 90
	if scaleH > h - bottomH then
		ui:Fetch('Shadow_Adv'):Size((h - bottomH) / 278 * 557, (h - bottomH))
		ui:Fetch('Image_Adv'):Size((h - bottomH) / 278 * 557, (h - bottomH))
		ui:Fetch('Text_Memory'):Pos(w - 150, h - bottomH + 10)
		ui:Fetch('Text_Adv'):Pos(10, h - bottomH + 10)
		ui:Fetch('Text_Svr'):Pos(10, h - bottomH + 35)
	else
		ui:Fetch('Shadow_Adv'):Size(w, scaleH)
		ui:Fetch('Image_Adv'):Size(w, scaleH)
		ui:Fetch('Text_Memory'):Pos(w - 150, scaleH + 10)
		ui:Fetch('Text_Adv'):Pos(10, scaleH + 10)
		ui:Fetch('Text_Svr'):Pos(10, scaleH + 35)
	end
	ui:Fetch('WndButton_UserPreference'):Top(scaleH + 65)
	ui:Fetch('WndButton_AddonErrorMessage'):Top(scaleH + 65)
end

function PS.OnPanelBreathe(wnd)
	local ui = UI(wnd)
	ui:Fetch('Text_Adv'):Text(GetAdvText())
	ui:Fetch('Text_Svr'):Text(GetSvrText())
	ui:Fetch('Text_Memory'):Text(GetMemoryText())
end

X.RegisterPanel(nil, 'Welcome', _L['Welcome'], '', PS)
