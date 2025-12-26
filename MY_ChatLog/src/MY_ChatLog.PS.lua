--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 聊天记录 设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog.PS'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_ChatLog.RealtimeCommit', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local D = {}

------------------------------------------------------------------------------------------------------
-- 数据导出
------------------------------------------------------------------------------------------------------

function D.ExportConfirm()
	if MY_ChatLog_ExportDB.IsRunning() or MY_ChatLog_ExportHTML.IsRunning() then
		return X.OutputSystemMessage(_L['Already exporting, please wait.'])
	end
	local ui = X.UI.CreateFrame('MY_ChatLog_Export', {
		theme = X.UI.FRAME_THEME.SIMPLE, esc = true, close = true, w = 140,
		level = 'Normal1', text = _L['Export chatlog'], alpha = 233,
	})
	local btnSure
	local tChannels = {}
	local nPaddingX, nPaddingY = 10, 10
	local x, y = nPaddingX, nPaddingY
	local nMaxWidth = 0
	for nGroup, info in ipairs(MY_ChatLog.aChannel) do
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, w = 100,
			text = info.szTitle,
			checked = true,
			onCheck = function(bChecked)
				tChannels[nGroup] = bChecked
				local bEnable = bChecked
				if not bChecked then
					for nGroup, _ in ipairs(MY_ChatLog.aChannel) do
						if tChannels[nGroup] then
							bEnable = true
							break
						end
					end
				end
				btnSure:Enable(bEnable)
			end,
		}):AutoWidth():Width()
		nMaxWidth = math.max(nMaxWidth, x + nPaddingX)
		if nGroup % 2 == 0 or nGroup == #MY_ChatLog.aChannel then
			x = nPaddingX
			y = y + 30
		else
			x = x + 5
		end
		tChannels[nGroup] = true
	end
	y = y + 10

	x = nPaddingX + 20
	btnSure = ui:Append('WndButton', {
		x = x, y = y, w = nMaxWidth - x * 2, h = 35,
		text = _L['Export chatlog'],
		onClick = function()
			if X.ENVIRONMENT.GAME_PROVIDER == 'remote' then
				return X.Alert(_L['Streaming client does not support export!'])
			end
			local function doExport(szSuffix)
				local aMsgType = {}
				for nGroup, info in ipairs(MY_ChatLog.aChannel) do
					if tChannels[nGroup] then
						for _, szMsgType in ipairs(info.aMsgType) do
							table.insert(aMsgType, szMsgType)
						end
					end
				end
				D.Export(
					X.FormatPath({'export/ChatLog/{$name}@{$server}@' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss') .. szSuffix, X.PATH_TYPE.ROLE}),
					aMsgType, 10,
					function(title, progress)
						OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Exporting chatlog: %s, %.2f%%.', title, progress * 100))
					end
				)
				ui:Remove()
			end
			X.Dialog(
				_L['Please choose export mode.\nHTML mode will export chatlog to human-readable file.\nDB mode will export chatlog to re-importable backup file.'], {
					{ szOption = _L['HTML mode'], fnAction = function() doExport('.html') end },
					{ szOption = _L['DB mode'], fnAction = function() doExport('.db') end },
				})
		end,
	})
	y = y + 30
	ui:Size(nMaxWidth, y + 50)
	ui:Anchor({s = 'CENTER', r = 'CENTER', x = 0, y = 0})
end

function D.Export(szExportFile, aMsgType, nPerSec, onProgress)
	if MY_ChatLog_ExportDB.IsRunning() or MY_ChatLog_ExportHTML.IsRunning() then
		return X.OutputSystemMessage(_L['Already exporting, please wait.'])
	end
	if szExportFile:sub(-3) == '.db' then
		MY_ChatLog_ExportDB.Start(szExportFile, aMsgType, nPerSec, onProgress)
	elseif szExportFile:sub(-5) == '.html' then
		MY_ChatLog_ExportHTML.Start(szExportFile, aMsgType, nPerSec, onProgress)
	else
		onProgress(_L['Export failed, unknown suffix.'], 1)
	end
end

------------------------------------------------------------------------------------------------------
-- 设置界面绘制
------------------------------------------------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nPaddingX, nPaddingY = 25, 25
	local nX, nY = nPaddingX, nPaddingY
	local nDeltaY = 35
	local nComponentW = 200

	-- 左侧
	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Settings'], font = 27 })
	nY = nY + nDeltaY
	nX = nPaddingX + 10

	local function InsertChatLogMsgTypeMenu(m, xInject)
		-- 通用
		X.InsertMsgTypeMenu(m, xInject)
		-- 自定义
		local m1 = { szOption = _L['Other channel'] }
		for _, szMsgType in ipairs(MY_ChatLog.MSG_TYPE_CUSTOM) do
			local tInject
			if X.IsFunction(xInject) then
				tInject = xInject(szMsgType)
			elseif X.IsTable(xInject) then
				tInject = xInject
			end
			local t1 = {
				szOption = MY_ChatLog.MSG_TYPE_TITLE[szMsgType],
				rgb = MY_ChatLog.MSG_TYPE_COLOR[szMsgType],
				bCheck = true,
			}
			if tInject then
				for k, v in pairs(tInject) do
					t1[k] = v
				end
			end
			table.insert(m1, t1)
		end
		table.insert(m, m1)
		return m
	end

	ui:Append('WndComboBox', {
		x = nX, y = nY, w = nComponentW, h = 25,
		text = _L['Channel settings'],
		menu = function()
			local menu = {}
			for _, tChannel in ipairs(MY_ChatLog.aChannel) do
				local tMsgTypeChecked = {}
				for _, szMsgType in ipairs(tChannel.aMsgType) do
					tMsgTypeChecked[szMsgType] = true
				end
				local m = {
					szOption = tChannel.szTitle,
					{
						szOption = _L['Rename channel'],
						fnAction = function()
							GetUserInput(_L['Please input new channel name:'], function(szTitle)
								tChannel.szTitle = szTitle
								MY_ChatLog.aChannel = MY_ChatLog.aChannel
							end, nil, nil, nil, tChannel.szTitle)
							X.UI.ClosePopupMenu()
						end,
					},
					X.CONSTANT.MENU_DIVIDER,
				}
				InsertChatLogMsgTypeMenu(m, function(szMsgType)
					return {
						fnAction = function(szMsgType)
							for i, v in ipairs(tChannel.aMsgType) do
								if v == szMsgType then
									table.remove(tChannel.aMsgType, i)
									MY_ChatLog.aChannel = MY_ChatLog.aChannel
									return
								end
							end
							table.insert(tChannel.aMsgType, szMsgType)
							MY_ChatLog.aChannel = MY_ChatLog.aChannel
						end,
						bChecked = tMsgTypeChecked[szMsgType],
					}
				end)
				table.insert(menu, m)
			end
			if #menu > 0 then
				table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			end
			table.insert(menu, {
				szOption = _L['New channel'],
				fnAction = function()
					GetUserInput(_L['Please input new channel name:'], function(szTitle)
						table.insert(MY_ChatLog.aChannel, {
							szKey = X.GetUUID(),
							szTitle = szTitle,
							aMsgType = {},
						})
						MY_ChatLog.aChannel = MY_ChatLog.aChannel
					end, nil, nil, nil, _L['New channel'])
					X.UI.ClosePopupMenu()
				end,
			})
			table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			table.insert(menu, {
				szOption = _L['Reset channel'],
				rgb = {255, 0, 0},
				fnAction = function()
					X.Confirm(_L['Are you sure to reset channel settings? Al custom channel settings will be lost.'], function()
						MY_ChatLog.ResetChannel()
					end)
					X.UI.ClosePopupMenu()
				end,
			})
			return menu
		end,
	})
	nY = nY + nDeltaY

	ui:Append('WndComboBox', {
		x = nX, y = nY, w = nComponentW, h = 25,
		text = _L['Chat log filter'],
		menu = function()
			return InsertChatLogMsgTypeMenu(
				{},
				function(szMsgType)
					local t1 = {}
					-- 消息必须不包含下列任何：
					local aExcludeFilter = MY_ChatLog.tExcludeFilter[szMsgType] or {}
					if #aExcludeFilter > 0 then
						table.insert(t1, {
							szOption = _L['Message must exclude:'],
							bDisable = true,
						})
					end
					for nIndex, tFilter in ipairs(aExcludeFilter) do
						table.insert(t1, {
							szOption = tFilter.szText,
							{
								szOption = _L['Pattern match'],
								bCheck = true, bChecked = tFilter.bPattern,
								fnAction = function()
									tFilter.bPattern = not tFilter.bPattern
									MY_ChatLog.tExcludeFilter[szMsgType] = aExcludeFilter
									MY_ChatLog.tExcludeFilter = MY_ChatLog.tExcludeFilter
								end,
							},
							{
								szOption = _L['Edit'],
								fnAction = function()
									GetUserInput('', function(szFilter)
										aExcludeFilter[nIndex].szText = szFilter
										MY_ChatLog.tExcludeFilter[szMsgType] = aExcludeFilter
										MY_ChatLog.tExcludeFilter = MY_ChatLog.tExcludeFilter
									end, nil, nil, nil, tFilter.szText)
									X.UI.ClosePopupMenu()
								end,
							},
							{
								szOption = _L['Delete'],
								rgb = {255, 0, 0},
								fnAction = function()
									X.Confirm(_L['Are you sure to delete this filter?'] .. '\n\n' .. tFilter.szText, function()
										table.remove(aExcludeFilter, nIndex)
										MY_ChatLog.tExcludeFilter[szMsgType] = aExcludeFilter
										MY_ChatLog.tExcludeFilter = MY_ChatLog.tExcludeFilter
									end)
									X.UI.ClosePopupMenu()
								end,
							},
						})
					end
					if #t1 > 0 then
						table.insert(t1, X.CONSTANT.MENU_DIVIDER)
					end
					-- 消息必须包含下列任何：
					local aIncludeFilter = MY_ChatLog.tIncludeFilter[szMsgType] or {}
					if #aIncludeFilter > 0 then
						table.insert(t1, {
							szOption = _L['Message must include:'],
							bDisable = true,
						})
					end
					for nIndex, tFilter in ipairs(aIncludeFilter) do
						table.insert(t1, {
							szOption = tFilter.szText,
							{
								szOption = _L['Pattern match'],
								bCheck = true, bChecked = tFilter.bPattern,
								fnAction = function()
									tFilter.bPattern = not tFilter.bPattern
									MY_ChatLog.tIncludeFilter[szMsgType] = aIncludeFilter
									MY_ChatLog.tIncludeFilter = MY_ChatLog.tIncludeFilter
								end,
							},
							{
								szOption = _L['Edit'],
								fnAction = function()
									GetUserInput('', function(szFilter)
										aIncludeFilter[nIndex].szText = szFilter
										MY_ChatLog.tIncludeFilter[szMsgType] = aIncludeFilter
										MY_ChatLog.tIncludeFilter = MY_ChatLog.tIncludeFilter
									end, nil, nil, nil, tFilter.szText)
									X.UI.ClosePopupMenu()
								end,
							},
							{
								szOption = _L['Delete'],
								rgb = {255, 0, 0},
								fnAction = function()
									X.Confirm(_L['Are you sure to delete this filter?'] .. '\n\n' .. tFilter.szText, function()
										table.remove(aIncludeFilter, nIndex)
										MY_ChatLog.tIncludeFilter[szMsgType] = aIncludeFilter
										MY_ChatLog.tIncludeFilter = MY_ChatLog.tIncludeFilter
									end)
									X.UI.ClosePopupMenu()
								end,
							},
						})
					end
					if #t1 > 0 then
						table.insert(t1, X.CONSTANT.MENU_DIVIDER)
					end
					-- 添加
					table.insert(t1, {
						szOption = _L['Add'],
						fnAction = function()
							X.Confirm('MY_ChatLog_PS_Filter_Add', _L['Which kind of filter do you want to add?'], {
								szResolve = _L['Message exclude'],
								fnResolve = function ()
									GetUserInput('', function(szFilter)
										table.insert(aExcludeFilter, {
											szText = szFilter,
											bPattern = false,
										})
										MY_ChatLog.tExcludeFilter[szMsgType] = aExcludeFilter
										MY_ChatLog.tExcludeFilter = MY_ChatLog.tExcludeFilter
									end, nil, nil, nil, '')
								end,
								szReject = _L['Message include'],
								fnReject = function ()
									GetUserInput('', function(szFilter)
										table.insert(aIncludeFilter, {
											szText = szFilter,
											bPattern = false,
										})
										MY_ChatLog.tIncludeFilter[szMsgType] = aIncludeFilter
										MY_ChatLog.tIncludeFilter = MY_ChatLog.tIncludeFilter
									end, nil, nil, nil, '')
								end,
							})
							X.UI.ClosePopupMenu()
						end,
					})
					return t1
				end
			)
		end,
	})
	nY = nY + nDeltaY

	ui:Append('WndComboBox', {
		x = nX, y = nY, w = nComponentW, h = 25,
		text = _L['Clear chat log'],
		r = 255, g = 0, b = 0,
		menu = function()
			local menu = InsertChatLogMsgTypeMenu(
				{},
				{
					fnAction = function(szMsgType)
						X.Confirm(_L('Are you sure to clear msg type chat log of %s? All chat logs in this msg type will be lost.', MY_ChatLog.MSG_TYPE_TITLE[szMsgType] or g_tStrings.tChannelName[szMsgType] or szMsgType), function()
							local ds = MY_ChatLog_DS(MY_ChatLog.GetRoot())
							ds:DeleteMsgByCondition({szMsgType}, '', 0, math.huge)
						end)
						X.UI.ClosePopupMenu()
					end,
				}
			)
			return menu
		end,
	})
	nY = nY + nDeltaY

	if not X.IsRestricted('MY_ChatLog.RealtimeCommit') then
		ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Realtime database commit'],
			checked = MY_ChatLog.bRealtimeCommit,
			onCheck = function(bChecked)
				MY_ChatLog.bRealtimeCommit = bChecked
			end,
		})
		nY = nY + nDeltaY
	end

	ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Auto connect database'],
		checked = MY_ChatLog.bAutoConnectDB,
		onCheck = function(bChecked)
			MY_ChatLog.bAutoConnectDB = bChecked
		end,
	})
	nY = nY + nDeltaY

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, w = nW, text = _L['Tips'], font = 27, multiline = true, alignVertical = 0 })
	nY = nY + 30
	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, w = nW, text = _L['MY_ChatLog TIPS'], font = 27, multiline = true, alignVertical = 0 })

	-- 右侧
	nX = nW - 150
	nY = nPaddingY
	nDeltaY = 40
	ui:Append('WndButton', {
		x = nX, y = nY, w = 125, h = 35,
		text = _L['Open chatlog'],
		onClick = function()
			MY_ChatLog.Open()
		end,
	})
	nY = nY + nDeltaY

	ui:Append('WndButton', {
		x = nX, y = nY, w = 125, h = 35,
		text = _L['Export chatlog'],
		onClick = function()
			D.ExportConfirm()
		end,
	})
	nY = nY + nDeltaY

	ui:Append('WndButton', {
		x = nX, y = nY, w = 125, h = 35,
		text = _L['Optimize datebase'],
		onClick = function()
			X.Confirm(_L['Optimize datebase will take a long time and may cause a disconnection, are you sure to continue?'], function()
				X.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					MY_ChatLog.OptimizeDB()
					X.Alert(_L['Optimize finished!'])
				end)
			end)
		end,
	})
	nY = nY + nDeltaY

	ui:Append('WndButton', {
		x = nX, y = nY, w = 125, h = 35,
		text = _L['Import chatlog'],
		onClick = function()
			local szRoot = X.FormatPath({'export/ChatLog', X.PATH_TYPE.ROLE})
			if not IsLocalFileExist(szRoot) then
				szRoot = X.FormatPath({'export/', X.PATH_TYPE.ROLE})
			end
			if not IsLocalFileExist(szRoot) then
				szRoot = X.FormatPath({'userdata/', X.PATH_TYPE.ROLE})
			end
			local file = GetOpenFileName(_L['Please select your chatlog database file.'], 'Database File(*.db)\0*.db\0\0', szRoot)
			if not X.IsEmpty(file) then
				X.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					local nImport, bOthersFound = MY_ChatLog.ImportDB(file)
					local szText = _L('%d chatlogs imported!', nImport)
					if bOthersFound then
						szText = szText .. _L['Others chat log found, please do not import other role chat log!']
					end
					X.Alert(szText)
				end)
			end
		end,
	})
	nY = nY + nDeltaY
end
X.Panel.Register(_L['Chat'], 'ChatLog', _L['MY_ChatLog'], 'ui/Image/button/SystemButton.UITex|43', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
