--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_PS'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^26.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_ChatLog.RealtimeCommit', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local D = {}
local EXPORT_SLICE = 100
local MSG_TYPE_COLOR = MY_ChatLog.MSG_TYPE_COLOR

------------------------------------------------------------------------------------------------------
-- 数据导出
------------------------------------------------------------------------------------------------------
local function htmlEncode(html)
	return html
	:gsub('&', '&amp;')
	:gsub(' ', '&ensp;')
	:gsub('<', '&lt;')
	:gsub('>', '&gt;')
	:gsub('"', '&quot;')
	:gsub('\n', '<br>')
end

local function getHeader()
	local szHeader = [[<!DOCTYPE html>
<html>
<head><meta http-equiv='Content-Type' content='text/html; charset=]]
	.. ((X.ENVIRONMENT.GAME_LANG == 'zhcn' and 'GBK') or 'UTF-8') .. [[' />
<style>
*{font-size: 12px}
a{line-height: 16px}
input, button, select, textarea {outline: none}
body{background-color: #000; margin: 8px 8px 45px 8px}
#browserWarning{background-color: #f00; font-weight: 800; color:#fff; padding: 8px; position: fixed; opacity: 0.92; top: 0; left: 0; right: 0}
.channel{color: #fff; font-weight: 800; font-size: 32px; padding: 0; margin: 30px 0 0 0}
.date{color: #fff; font-weight: 800; font-size: 24px; padding: 0; margin: 0}
a.content{font-family: cursive}
span.emotion_44{width:21px; height: 21px; display: inline-block; background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAO/SURBVDhPnZT7U4xRGMfff4GftEVKYsLutkVETKmsdrtY9QMNuTRDpVZS2Fw2utjcL1NSYaaUa5gRFSK5mzFukzHGYAbjOmTC7tv79vWcs2+bS7k9M985u+c953PO85zneYS+zBQThYChKvj7ejg1zDnqfN1hipkKZdnfmXFKKLRD3aHXecMyPQh1q+PRVr4Qj2qycKZkAfLmRyJitA80tCaa1irb+rZR3m4I9huIgsQQvKxKxZemXEgNuZAvrIPcWoSuqzbYH5bhcZMV6fHjETjcA6OGuPUNHuk9AJM1g3E4IxId9TnwcuvHJV0phHQuD9L5fODFPtf8mwcV2JIVg4kab6h9VL+Co/VhGOOrQlnSBHQcWeyE3SqG1JKHzoaVkC4WQr68HniyGUAb6QFf86FtC0qzTRhL3kVPCfsRrKGTUsNH4lX5PDiOLoZ0yQrpzCoOlW9uoLGAu4/2cgK2kC6QGiG9rsCr5gKkm8ZBTTFWcIIQH2dAyHAV7q+d5nLNJVV/Psq3NkO+RNC3lb+s8VHWBNFtE4jFJGgolsmhfnheZKTTfzS2WL6/3XlTcr/r3iYC71S+Oo2teXfdhjlTAzDCawCXwNJnx8xgvC9Jgrg7EfZ98yAeSoGjLt3p+lkrZHp1+cp6GosJbkPXnXwuudWKLjpUvJiPvctMPM2YBH9K5pZsPeyls2HfkwzHQTPE49nobFrNX12+pgC/1zUGL+r5T6G5uyfNVSgcejs3CvYSgu4laFUKxBM5Lih3/Xtgb2otxNOaJdBR1TFxaIM5nG6ahK9lc+HYnwbxSCbE+hWQmtf+GcpCQ/FuLp7dc9MAHzdYo3X4vG0m7LuSYK+cD8eBDIinLehsZGn1E5QgbI6L8pd707gS62ZNhD+xmARTrAF69SA8sSX0hKA6tee2lJ+uh6L4MggrCHYgP5QOf1ebAUPgEGo0UVw8V1kGbEoYg090WwcVAH+wbvApBawAxZPLac7CH1Oi2H+py8LGWZN4E+KwbouibhOh8UR9Wjjat82Ao8IJ7jyYDrF6AaRTOUplkavHsyAezaRvZnRUL8KxpQZM8POAobeOFUClatB5oSY5BB+2Unx3z4FtSZyrcrply4ylmC/CRwoVaz562qP+XafS0MfgYSqsMGjxzGbiEPshCkMtpVkNSzUzn3tJYcqbFohJIzzA+oayvW8zUsdiVRHq5w6LUYvalDDcsBhxb00c6s2RyE8Igl7ryWPYq8u/s+nUGNTUF/xpM8tlLvqtJW9MscoL/6v9P1QQvgHonm5Hx/sAiwAAAABJRU5ErkJggg==')}
#controls{background-color: #fff; height: 25px; position: fixed; opacity: 0.92; bottom: 0; left: 0; right: 0}
#mosaics{width: 200px;height: 20px}
]]

	for k, v in pairs(g_tStrings.tForceTitle) do
		szHeader = szHeader .. ('.force-%s{color:#%02X%02X%02X}'):format(k, X.GetForceColor(k, 'foreground'))
	end

	szHeader = szHeader .. [[
</style></head>
<body>
<div id='browserWarning'>Please allow running JavaScript on this page!</div>
<div id='controls' style='display:none'>
	<input type='range' id='mosaics' min='0' max='200' value='0'>
	<script type='text/javascript'>
	(function() {
		var timerid, blurRadius;
		var setMosaicHandler = function() {
			var filter = 'blur(' + blurRadius + ')';console.log(filter);
			var eles = document.getElementsByClassName('namelink');
			for(i = eles.length - 1; i >= 0; i--) {
				eles[i].style['filter'] = filter;
				eles[i].style['-o-filter'] = filter;
				eles[i].style['-ms-filter'] = filter;
				eles[i].style['-moz-filter'] = filter;
				eles[i].style['-webkit-filter'] = filter;
			}
			timerid = null;
		}
		var setMosaic = function(radius) {
			if (timerid)
				clearTimeout(timerid);
			blurRadius = radius;
			timerid = setTimeout(setMosaicHandler, 50);
		}
		document.getElementById('mosaics').oninput = function() {
			setMosaic((this.value / 100 + 0.5) + 'px');
		}
	})();
	</script>
</div>
<script type='text/javascript'>
	(function () {
		var Sys = {};
		var ua = navigator.userAgent.toLowerCase();
		var s;
		(s = ua.match(/rv:([\d.]+)\) like gecko/)) ? Sys.ie = s[1] :
		(s = ua.match(/msie ([\d.]+)/)) ? Sys.ie = s[1] :
		(s = ua.match(/firefox\/([\d.]+)/)) ? Sys.firefox = s[1] :
		(s = ua.match(/chrome\/([\d.]+)/)) ? Sys.chrome = s[1] :
		(s = ua.match(/opera.([\d.]+)/)) ? Sys.opera = s[1] :
		(s = ua.match(/version\/([\d.]+).*safari/)) ? Sys.safari = s[1] : 0;

		// if (Sys.ie) document.write('IE: ' + Sys.ie);
		// if (Sys.firefox) document.write('Firefox: ' + Sys.firefox);
		// if (Sys.chrome) document.write('Chrome: ' + Sys.chrome);
		// if (Sys.opera) document.write('Opera: ' + Sys.opera);
		// if (Sys.safari) document.write('Safari: ' + Sys.safari);

		if (!Sys.chrome && !Sys.firefox) {
			document.getElementById('browserWarning').innerHTML = '<a>WARNING: Please use </a><a href=\'https://www.google.cn/chrome/browser/desktop/index.html\' style=\'color: yellow;\'>Chrome</a></a> to browse this page!!!</a>';
		} else {
			document.getElementById('controls').style['display'] = null;
			document.getElementById('browserWarning').style['display'] = 'none';
		}
	})();
</script>
<div>
<a style='color: #fff;margin: 0 10px'>]] .. X.GetClientPlayer().szName .. ' @ ' .. X.GetServerName() ..
' Exported at ' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd %hh:%mm:%ss') .. '</a><hr />'

	return szHeader
end

local function getFooter()
	return [[
</div>
</body>
</html>]]
end

local function getChannelTitle(szChannel)
	return [[<p class='channel'>]] .. (g_tStrings.tChannelName[szChannel] or '') .. [[</p><hr />]]
end

local function getDateTitle(szDate)
	return [[<p class='date'>]] .. (szDate or '') .. [[</p>]]
end

local function convertXml2Html(szXml)
	local aXMLNode = X.XMLDecode(szXml)
	local t = {}
	if aXMLNode then
		local text, name, force, r, g, b
		for _, node in ipairs(aXMLNode) do
			text = X.XMLGetNodeData(node, 'text')
			name = X.XMLGetNodeData(node, 'name')
			if text then
				text = htmlEncode(text)
				force = nil
				table.insert(t, '<a')
				if name and name:sub(1, 9) == 'namelink_' then
					table.insert(t, ' class="namelink')
					if MY_Farbnamen and MY_Farbnamen.Get then
						local info = MY_Farbnamen.Get((text:gsub('[%[%]]', '')))
						if info then
							force = info.dwForceID
							table.insert(t, ' force-')
							table.insert(t, info.dwForceID)
						end
					end
					table.insert(t, '"')
				end
				r = X.XMLGetNodeData(node, 'r')
				g = X.XMLGetNodeData(node, 'g')
				b = X.XMLGetNodeData(node, 'b')
				if not force and r and g and b then
					table.insert(t, (' style="color:#%02X%02X%02X"'):format(r, g, b))
				end
				table.insert(t, '>')
				table.insert(t, text)
				table.insert(t, '</a>')
			elseif name and name:sub(1, 8) == 'emotion_' then
				table.insert(t, '<span class="')
				table.insert(t, name)
				table.insert(t, '"></span>')
			end
		end
	end
	return table.concat(t)
end

local l_bExporting
function D.ExportConfirm()
	if l_bExporting then
		return X.OutputSystemMessage(_L['Already exporting, please wait.'])
	end
	local ui = X.UI.CreateFrame('MY_ChatLog_Export', {
		simple = true, esc = true, close = true, w = 140,
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
	if l_bExporting then
		return X.OutputSystemMessage(_L['Already exporting, please wait.'])
	end
	local ds = MY_ChatLog_DS(MY_ChatLog.GetRoot())
	if not ds then
		return
	end
	if onProgress then
		onProgress(_L['Preparing'], 0)
	end
	if szExportFile:sub(-3) == '.db' then
		local db = MY_ChatLog_DB(szExportFile)
		if not db:Connect() then
			return
		end
		db:SetMinTime(0)
		db:SetMaxTime(math.huge)
		db:SetInfo('version', '2')
		db:SetInfo('user_global_id', X.GetClientPlayerGlobalID())
		l_bExporting = true

		local nPage, nPageCount = 0, math.ceil(ds:CountMsg(aMsgType, '') / EXPORT_SLICE)
		local function Export()
			if nPage > nPageCount then
				l_bExporting = false
				db:Disconnect()
				local szFile = GetRootPath() .. szExportFile:gsub('/', '\\')
				X.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
				X.OutputSystemMessage(_L('Chatlog export succeed, file saved as %s', szFile))
				return 0
			end
			local data = ds:SelectMsg(aMsgType, '', nil, nil, nPage * EXPORT_SLICE, EXPORT_SLICE, true)
			for i, rec in ipairs(data) do
				db:InsertMsg(rec.szMsgType, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
			end
			if onProgress then
				onProgress(_L['exporting'], nPage / nPageCount)
			end
			db:Flush()
			nPage = nPage + 1
		end
		X.BreatheCall('MY_ChatLog_Export', Export)
	elseif szExportFile:sub(-5) == '.html' then
		local status = Log(szExportFile, getHeader(), 'clear')
		if status ~= 'SUCCEED' then
			return X.OutputSystemMessage(_L('Error: open file error %s [%s]', szExportFile, status))
		end
		l_bExporting = true

		local nPage, nPageCount = 0, math.ceil(ds:CountMsg(aMsgType, '') / EXPORT_SLICE)
		local function Export()
			if nPage > nPageCount then
				l_bExporting = false
				Log(szExportFile, getFooter(), 'close')
				if onProgress then
					onProgress(_L['Export succeed'], 1)
				end
				local szFile = X.GetAbsolutePath(szExportFile)
				X.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
				X.OutputSystemMessage(_L('Chatlog export succeed, file saved as %s', szFile))
				return 0
			end
			local data = ds:SelectMsg(aMsgType, '', nil, nil, nPage * EXPORT_SLICE, EXPORT_SLICE)
			for i, rec in ipairs(data) do
				local f = GetMsgFont(rec.szMsgType)
				local r, g, b = unpack(MSG_TYPE_COLOR[rec.szMsgType])
				Log(szExportFile, convertXml2Html(X.GetChatTimeXML(rec.nTime, {r=r, g=g, b=b, f=f, s='[%yyyy/%MM/%dd][%hh:%mm:%ss]'})))
				Log(szExportFile, convertXml2Html(rec.szMsg))
			end
			if onProgress then
				onProgress(_L['exporting'], nPage / nPageCount)
			end
			nPage = nPage + 1
		end
		X.BreatheCall('MY_ChatLog_Export', Export)
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
							ds:DeleteMsgInterval({szMsgType}, '', 0, math.huge)
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
