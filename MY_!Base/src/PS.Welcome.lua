--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 欢迎页
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/PS.Welcome')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps/')
--------------------------------------------------------------------------------

local PS = { bWelcome = true, bHide = true }

local function GetMemoryText()
	return string.format('Memory:%.1fMB', collectgarbage('count') / 1024)
end

local function GetAdvText()
	local me = X.GetClientPlayer()
	if not me then
		return ''
	end
	return _L('%s, welcome to use %s!', me.szName, X.PACKET_INFO.NAME)
end

local function GetSvrText()
	local nFeeTime = X.GetTimeOfFee() - GetCurrentTime()
	local szFeeTime = nFeeTime > 0
		and _L('Fee left %s', X.FormatDuration(nFeeTime, 'CHINESE', { accuracyUnit = X.ENVIRONMENT.GAME_BRANCH == 'classic' and 'hour' or nil }))
		or _L['Fee left unknown']
	return X.GetRegionName() .. '::' .. X.GetServerName()
		.. ' (' .. X.GetRegionOriginName() .. '::' .. X.GetServerOriginName() .. ')'
		.. g_tStrings.STR_CONNECT
		.. szFeeTime
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local w, h = ui:Size()
	ui:Append('Shadow', { name = 'Shadow_Adv', x = 0, y = 0, w = 0, h = 0, color = { 140, 140, 140 } })
	ui:Append('Image', { name = 'Image_Adv', x = 0, y = 0, w = 0, h = 0, image = X.PACKET_INFO.POSTER_UITEX, imageFrame = GetTime() % X.PACKET_INFO.POSTER_FRAME_COUNT })
	ui:Append('Text', { name = 'Text_Adv', x = 10, y = 300, w = 557, font = 200, text = GetAdvText() })
	ui:Append('Text', { name = 'Text_Memory', x = 10, y = 300, w = 150, alpha = 150, font = 162, text = GetMemoryText(), alignHorizontal = 2 })
	ui:Append('Text', { name = 'Text_Svr', x = 10, y = 345, w = 557, font = 204, text = GetSvrText(), alpha = 220 })
	local x = 7
	-- 奇遇分享
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityNotify',
		text = _L['Show share notify.'],
		checked = MY_Serendipity.bEnable,
		onCheck = function(bChecked)
			if bChecked then
				local ui = X.UI(this)
				X.Confirm(_L['Check this will monitor system message for serendipity and share it, are you sure?'], function()
					MY_Serendipity.bEnable = bChecked
					ui:Check(true, WNDEVENT_FIRETYPE.PREVENT)
				end)
				ui:Check(false, WNDEVENT_FIRETYPE.PREVENT)
			else
				MY_Serendipity.bEnable = bChecked
			end
		end,
		tip = {
			render = _L['Monitor serendipity and show share notify.'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
	}):AutoWidth():Width()
	local xS0 = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityAutoShare',
		text = _L['Auto share.'],
		checked = MY_Serendipity.bAutoShare,
		onCheck = function()
			MY_Serendipity.bAutoShare = not MY_Serendipity.bAutoShare
		end,
		autoEnable = function() return MY_Serendipity.bEnable end,
	}):AutoWidth():Width()
	-- 自动分享子项
	x = xS0
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipitySilentMode',
		text = _L['Silent mode.'],
		checked = MY_Serendipity.bSilentMode,
		onCheck = function()
			MY_Serendipity.bSilentMode = not MY_Serendipity.bSilentMode
		end,
		autoVisible = function() return MY_Serendipity.bAutoShare end,
		autoEnable = function() return MY_Serendipity.bEnable end,
	}):AutoWidth():Width()
	x = x + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = 375, w = 105, h = 25,
		name = 'WndEditBox_SerendipitySilentMode',
		placeholder = _L['Realname, leave blank for anonymous.'],
		tip = {
			render = _L['Realname, leave blank for anonymous.'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		limit = 6,
		text = X.LoadLUAData({'config/realname.jx3dat', X.PATH_TYPE.ROLE}) or X.GetClientPlayer().szName:gsub('@.-$', ''),
		onChange = function(szText)
			X.SaveLUAData({'config/realname.jx3dat', X.PATH_TYPE.ROLE}, szText)
		end,
		autoVisible = function() return MY_Serendipity.bAutoShare end,
		autoEnable = function() return MY_Serendipity.bEnable end,
	}):Width()
	-- 手动分享子项
	x = xS0
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityNotifyTip',
		text = _L['Show notify tip.'],
		checked = MY_Serendipity.bPreview,
		onCheck = function()
			MY_Serendipity.bPreview = not MY_Serendipity.bPreview
		end,
		autoVisible = function() return not MY_Serendipity.bAutoShare end,
		autoEnable = function() return MY_Serendipity.bEnable end,
	}):AutoWidth():Width()
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityNotifySound',
		text = _L['Play notify sound.'],
		checked = MY_Serendipity.bSound,
		onCheck = function()
			MY_Serendipity.bSound = not MY_Serendipity.bSound
		end,
		autoEnable = function() return MY_Serendipity.bEnable and not MY_Serendipity.bAutoShare end,
		autoVisible = function() return not MY_Serendipity.bAutoShare end,
	}):AutoWidth():Width()
	x = x + ui:Append('WndButton', {
		x = x, y = 375,
		name = 'WndButton_SerendipitySearch',
		text = _L['serendipity'],
		onClick = function()
			local szNameU = AnsiToUTF8(X.GetClientPlayerInfo().szName)
			local szNameCRC = ('%x%x%x'):format(szNameU:byte(), GetStringCRC(szNameU), szNameU:byte(-1))
			X.UI.OpenBrowser(
				'https://j3cx.com/serendipity/?'
					.. X.EncodeQuerystring(X.SignPostData(X.ConvertToUTF8(
						{
							l = X.ENVIRONMENT.GAME_LANG,
							L = X.ENVIRONMENT.GAME_EDITION,
							S = X.GetRegionOriginName(),
							s = X.GetServerOriginName(),
							n = X.GetClientPlayerInfo().szName,
							N = szNameCRC,
						}),
						X.KGUIEncrypt(X.SECRET['J3CX::SERENDIPITY'])
					)),
				{ openurl = 'https://j3cx.com/serendipity', controls = false })
		end,
	}):AutoWidth():Width() + 5
	-- 数据位置
	x = x + ui:Append('WndButton', {
		x = x, h = 30,
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
						X.OpenFolder(X.GetAbsolutePath({'', X.PATH_TYPE.ROLE}))
						X.UI.ClosePopupMenu()
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
						X.OpenFolder(X.GetAbsolutePath({'', X.PATH_TYPE.SERVER}))
						X.UI.ClosePopupMenu()
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
						X.OpenFolder(X.GetAbsolutePath({'', X.PATH_TYPE.GLOBAL}))
						X.UI.ClosePopupMenu()
					end,
				},
				X.CONSTANT.MENU_DIVIDER,
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
						X.UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Export data'],
					fnAction = function()
						X.OpenUserSettingsExportPanel()
						X.UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Import data'],
					fnAction = function()
						X.OpenUserSettingsImportPanel()
						X.UI.ClosePopupMenu()
					end,
				},
			}
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndButton', {
		name = 'WndButton_AddonErrorMessage',
		x = x, h = 30,
		text = _L['Error message'],
		menu = function()
			local menu = {
				{
					szOption = _L['Show error message'],
					tip = {
						render = _L['Show error message, please commit it while report bugs'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					fnAction = function()
						local szErrmsg = X.GetAddonErrorMessage()
						local nErrmsgLen, nMaxLen = #szErrmsg, 1024
						if nErrmsgLen == 0 then
							X.Alert(_L['No error message found.'])
							return
						end
						if nErrmsgLen > 300 then
							szErrmsg = szErrmsg:sub(0, nMaxLen)
								.. '\n========================================'
								.. '\n' .. '... ' .. (nErrmsgLen - nMaxLen) .. ' char(s) omitted.'
								.. '\n========================================'
								.. '\n# Full error logs:'
								.. '\n> ' .. X.GetAbsolutePath(X.GetAddonErrorMessageFilePath())
								.. '\n========================================'
						end
						X.UI.OpenTextEditor(szErrmsg, { w = 800, h = 600, title = _L['Error message'] })
						X.UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Open error message folder'],
					fnAction = function()
						X.OpenFolder(X.GetAbsolutePath(X.GetAddonErrorMessageFilePath()))
						X.UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Open logs folder'],
					fnAction = function()
						X.OpenFolder(X.GetAbsolutePath(X.FormatPath({'logs/', X.PATH_TYPE.ROLE})))
						X.UI.ClosePopupMenu()
					end,
				},
				X.CONSTANT.MENU_DIVIDER,
				{
					szOption = _L['Report bugs'],
					fnAction = function()
						X.OpenBrowser(X.PACKET_INFO.AUTHOR_FEEDBACK_URL)
						X.UI.ClosePopupMenu()
					end,
				},
			}
			if IsCtrlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
				table.insert(menu, 1, {
					szOption = _L['Enable debug tools'],
					rgb = { 255, 128, 0 },
					fnAction = function()
						X.IsDebugClient('Dev_LuaWatcher', true, true)
						X.IsDebugClient('Dev_UIEditor', true, true)
						X.IsDebugClient('Dev_UIManager', true, true)
						X.IsDebugClient('Dev_UIFindStation', true, true)
						X.IsDebugClient('Dev_DebugLogs', true, true)
						X.OutputSystemAnnounceMessage(_L['Debug tools has been enabled...'])
						X.ReopenPanel()
						X.UI.ClosePopupMenu()
					end,
				})
				table.insert(menu, 2, X.CONSTANT.MENU_DIVIDER)
			end
			return menu
		end,
	}):AutoWidth():Width() + 5
	PS.OnPanelResize(wnd)
end

function PS.OnPanelResize(wnd)
	local ui = X.UI(wnd)
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
	ui:Fetch('WndCheckBox_SerendipityNotify'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipityAutoShare'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipitySilentMode'):Top(scaleH + 65)
	ui:Fetch('WndEditBox_SerendipitySilentMode'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipityNotifyTip'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipityNotifySound'):Top(scaleH + 65)
	ui:Fetch('WndButton_SerendipitySearch'):Top(scaleH + 65)
	ui:Fetch('WndButton_UserPreference'):Top(scaleH + 65)
	ui:Fetch('WndButton_AddonErrorMessage'):Top(scaleH + 65)
end

function PS.OnPanelBreathe(wnd)
	local ui = X.UI(wnd)
	ui:Fetch('Text_Adv'):Text(GetAdvText())
	ui:Fetch('Text_Svr'):Text(GetSvrText())
	ui:Fetch('Text_Memory'):Text(GetMemoryText())
end

X.RegisterPanel(nil, 'Welcome', _L['Welcome'], '', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
