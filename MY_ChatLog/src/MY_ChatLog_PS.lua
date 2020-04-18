--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------

local D = {}
local EXPORT_SLICE = 100
local LOG_TYPE = MY_ChatLog.LOG_TYPE
local MSGTYPE_COLOR = MY_ChatLog.MSGTYPE_COLOR

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
	.. ((LIB.GetLang() == 'zhcn' and 'GBK') or 'UTF-8') .. [[' />
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
		szHeader = szHeader .. ('.force-%s{color:#%02X%02X%02X}'):format(k, LIB.GetForceColor(k, 'foreground'))
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
			document.getElementById('browserWarning').innerHTML = '<a>WARNING: Please use </a><a href=\'http://www.google.cn/chrome/browser/desktop/index.html\' style=\'color: yellow;\'>Chrome</a></a> to browse this page!!!</a>';
		} else {
			document.getElementById('controls').style['display'] = null;
			document.getElementById('browserWarning').style['display'] = 'none';
		}
	})();
</script>
<div>
<a style='color: #fff;margin: 0 10px'>]] .. GetClientPlayer().szName .. ' @ ' .. LIB.GetServer() ..
' Exported at ' .. LIB.FormatTime(GetCurrentTime(), '%yyyy%MM%dd %hh:%mm:%ss') .. '</a><hr />'

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
	local aXml = LIB.Xml.Decode(szXml)
	local t = {}
	if aXml then
		local text, name
		for _, xml in ipairs(aXml) do
			text = xml[''].text
			name = xml[''].name
			if text then
				local force
				text = htmlEncode(text)
				insert(t, '<a')
				if name and name:sub(1, 9) == 'namelink_' then
					insert(t, ' class="namelink')
					if MY_Farbnamen and MY_Farbnamen.Get then
						local info = MY_Farbnamen.Get((text:gsub('[%[%]]', '')))
						if info then
							force = info.dwForceID
							insert(t, ' force-')
							insert(t, info.dwForceID)
						end
					end
					insert(t, '"')
				end
				if not force and xml[''].r and xml[''].g and xml[''].b then
					insert(t, (' style="color:#%02X%02X%02X"'):format(xml[''].r, xml[''].g, xml[''].b))
				end
				insert(t, '>')
				insert(t, text)
				insert(t, '</a>')
			elseif name and name:sub(1, 8) == 'emotion_' then
				insert(t, '<span class="')
				insert(t, name)
				insert(t, '"></span>')
			end
		end
	end
	return concat(t)
end

local l_bExporting
function D.ExportConfirm()
	if l_bExporting then
		return LIB.Sysmsg(_L['Already exporting, please wait.'])
	end
	local ui = UI.CreateFrame('MY_ChatLog_Export', {
		simple = true, esc = true, close = true, w = 140,
		level = 'Normal1', text = _L['Export chatlog'], alpha = 233,
	})
	local btnSure
	local tChannels = {}
	local X, Y = 10, 10
	local x, y = X, Y
	local nMaxWidth = 0
	for nGroup, info in ipairs(LOG_TYPE) do
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, w = 100,
			text = info.szTitle,
			checked = true,
			oncheck = function(bChecked)
				tChannels[nGroup] = bChecked
				local bEnable = bChecked
				if not bChecked then
					for nGroup, _ in ipairs(LOG_TYPE) do
						if tChannels[nGroup] then
							bEnable = true
							break
						end
					end
				end
				btnSure:Enable(bEnable)
			end,
		}):AutoWidth():Width()
		nMaxWidth = max(nMaxWidth, x + X)
		if nGroup % 2 == 0 or nGroup == #LOG_TYPE then
			x = X
			y = y + 30
		else
			x = x + 5
		end
		tChannels[nGroup] = true
	end
	y = y + 10

	x = X + 20
	btnSure = ui:Append('WndButton', {
		x = x, y = y, w = nMaxWidth - x * 2, h = 35,
		text = _L['Export chatlog'],
		onclick = function()
			if LIB.IsStreaming() then
				return LIB.Alert(_L['Streaming client does not support export!'])
			end
			local function doExport(szSuffix)
				local aChannels = {}
				for nGroup, info in ipairs(LOG_TYPE) do
					if tChannels[nGroup] then
						for _, szChannel in ipairs(info.aChannel) do
							table.insert(aChannels, szChannel)
						end
					end
				end
				D.Export(
					LIB.FormatPath({'export/ChatLog/{$name}@{$server}@' .. LIB.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss') .. szSuffix, PATH_TYPE.ROLE}),
					aChannels, 10,
					function(title, progress)
						OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Exporting chatlog: %s, %.2f%%.', title, progress * 100))
					end
				)
				ui:Remove()
			end
			LIB.Confirm(
				_L['Please choose export mode.\nHTML mode will export chatlog to human-readable file.\nDB mode will export chatlog to re-importable backup file.'],
				function() doExport('.html') end,
				function() doExport('.db') end,
				_L['HTML mode'], _L['DB mode'])
		end,
	})
	y = y + 30
	ui:Size(nMaxWidth, y + 50)
	ui:Anchor({s = 'CENTER', r = 'CENTER', x = 0, y = 0})
end

function D.Export(szExportFile, aChannels, nPerSec, onProgress)
	if l_bExporting then
		return LIB.Sysmsg(_L['Already exporting, please wait.'])
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
		db:SetMaxTime(HUGE)
		db:SetInfo('user_global_id', GetClientPlayer().GetGlobalID())
		l_bExporting = true

		local nPage, nPageCount = 0, ceil(ds:CountMsg(aChannels, '') / EXPORT_SLICE)
		local function Export()
			if nPage > nPageCount then
				l_bExporting = false
				db:Disconnect()
				local szFile = GetRootPath() .. szExportFile:gsub('/', '\\')
				LIB.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
				LIB.Sysmsg(_L('Chatlog export succeed, file saved as %s', szFile))
				return 0
			end
			local data = ds:SelectMsg(aChannels, '', nil, nil, nPage * EXPORT_SLICE, EXPORT_SLICE, true)
			for i, rec in ipairs(data) do
				db:InsertMsg(rec.nChannel, rec.szText, rec.szMsg, rec.szTalker, rec.nTime, rec.szHash)
			end
			if onProgress then
				onProgress(_L['exporting'], nPage / nPageCount)
			end
			db:Flush()
			nPage = nPage + 1
		end
		LIB.BreatheCall('MY_ChatLog_Export', Export)
	elseif szExportFile:sub(-5) == '.html' then
		local status = Log(szExportFile, getHeader(), 'clear')
		if status ~= 'SUCCEED' then
			return LIB.Sysmsg(_L('Error: open file error %s [%s]', szExportFile, status))
		end
		l_bExporting = true

		local nPage, nPageCount = 0, ceil(ds:CountMsg(aChannels, '') / EXPORT_SLICE)
		local function Export()
			if nPage > nPageCount then
				l_bExporting = false
				Log(szExportFile, getFooter(), 'close')
				if onProgress then
					onProgress(_L['Export succeed'], 1)
				end
				local szFile = GetRootPath() .. szExportFile:gsub('/', '\\')
				LIB.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
				LIB.Sysmsg(_L('Chatlog export succeed, file saved as %s', szFile))
				return 0
			end
			local data = ds:SelectMsg(aChannels, '', nil, nil, nPage * EXPORT_SLICE, EXPORT_SLICE)
			for i, rec in ipairs(data) do
				local f = GetMsgFont(rec.szChannel)
				local r, g, b = unpack(MSGTYPE_COLOR[rec.szChannel])
				Log(szExportFile, convertXml2Html(LIB.GetTimeLinkText(rec.nTime, {r=r, g=g, b=b, f=f, s='[%yyyy/%MM/%dd][%hh:%mm:%ss]'})))
				Log(szExportFile, convertXml2Html(rec.szMsg))
			end
			if onProgress then
				onProgress(_L['exporting'], nPage / nPageCount)
			end
			nPage = nPage + 1
		end
		LIB.BreatheCall('MY_ChatLog_Export', Export)
	else
		onProgress(_L['Export failed, unknown suffix.'], 1)
	end
end

------------------------------------------------------------------------------------------------------
-- 设置界面绘制
------------------------------------------------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 50, 50
	local dy = 40
	local wr = 200

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr,
		text = _L['Filter tong member log message'],
		checked = MY_ChatLog.bIgnoreTongMemberLogMsg,
		oncheck = function(bChecked)
			MY_ChatLog.bIgnoreTongMemberLogMsg = bChecked
		end
	})
	y = y + dy

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr,
		text = _L['Filter tong online message'],
		checked = MY_ChatLog.bIgnoreTongOnlineMsg,
		oncheck = function(bChecked)
			MY_ChatLog.bIgnoreTongOnlineMsg = bChecked
		end
	})
	y = y + dy

	if not LIB.IsShieldedVersion('MY_ChatLog') then
		ui:Append('WndCheckBox', {
			x = x, y = y, w = wr,
			text = _L['Realtime database commit'],
			checked = MY_ChatLog.bRealtimeCommit,
			oncheck = function(bChecked)
				MY_ChatLog.bRealtimeCommit = bChecked
			end
		})
		y = y + dy
	end

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr,
		text = _L['Auto connect database'],
		checked = MY_ChatLog.bAutoConnectDB,
		oncheck = function(bChecked)
			MY_ChatLog.bAutoConnectDB = bChecked
		end
	})
	y = y + dy

	ui:Append('WndButton', {
		x = x, y = y, w = 125, h = 35,
		text = _L['Open chatlog'],
		onclick = function()
			MY_ChatLog.Open()
		end,
	})
	y = y + dy

	ui:Append('WndButton', {
		x = x, y = y, w = 125, h = 35,
		text = _L['Export chatlog'],
		onclick = function()
			D.ExportConfirm()
		end,
	})
	y = y + dy

	ui:Append('WndButton', {
		x = x, y = y, w = 125, h = 35,
		text = _L['Optimize datebase'],
		onclick = function()
			LIB.Confirm(_L['Optimize datebase will take a long time and may cause a disconnection, are you sure to continue?'], function()
				LIB.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					MY_ChatLog.OptimizeDB()
					LIB.Alert(_L['Optimize finished!'])
				end)
			end)
		end,
	})
	y = y + dy

	ui:Append('WndButton', {
		x = x, y = y, w = 125, h = 35,
		text = _L['Import chatlog'],
		onclick = function()
			local szRoot = LIB.FormatPath({'export/ChatLog', PATH_TYPE.ROLE})
			if not IsLocalFileExist(szRoot) then
				szRoot = LIB.FormatPath({'export/', PATH_TYPE.ROLE})
			end
			if not IsLocalFileExist(szRoot) then
				szRoot = LIB.FormatPath({'userdata/', PATH_TYPE.ROLE})
			end
			local file = GetOpenFileName(_L['Please select your chatlog database file.'], 'Database File(*.db)\0*.db\0\0', szRoot)
			if not IsEmpty(file) then
				LIB.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
						LIB.Alert(_L('%d chatlogs imported!', MY_ChatLog.ImportDB(file)))
				end)
			end
		end,
	})
	y = y + dy
end
LIB.RegisterPanel( 'ChatLog', _L['MY_ChatLog'], _L['Chat'], 'ui/Image/button/SystemButton.UITex|43', PS)
