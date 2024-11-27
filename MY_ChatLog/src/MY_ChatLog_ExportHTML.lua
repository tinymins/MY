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
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_ExportHTML'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^27.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_ChatLog.RealtimeCommit', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local D = {
	bExporting = false,
}
local EXPORT_SLICE = 100
local MSG_TYPE_COLOR = MY_ChatLog.MSG_TYPE_COLOR

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

function D.Start(szExportFile, aMsgType, nPerSec, onProgress)
	if D.bExporting then
		return X.OutputSystemMessage(_L['Already exporting, please wait.'])
	end
	local ds = MY_ChatLog_DS(MY_ChatLog.GetRoot())
	if not ds then
		return
	end
	local status = Log(szExportFile, getHeader(), 'clear')
	if status ~= 'SUCCEED' then
		return X.OutputSystemMessage(_L('Error: open file error %s [%s]', szExportFile, status))
	end
	D.bExporting = true

	if onProgress then
		onProgress(_L['Preparing'], 0)
	end

	local nPage, nPageCount = 0, math.ceil(ds:CountMsg(aMsgType, '') / EXPORT_SLICE)
	local function Export()
		if nPage > nPageCount then
			D.bExporting = false
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
			Log(szExportFile, '<div class="message-item">')
			Log(szExportFile, convertXml2Html(X.GetChatTimeXML(rec.nTime, {r=r, g=g, b=b, f=f, s='[%yyyy/%MM/%dd][%hh:%mm:%ss]'})))
			Log(szExportFile, convertXml2Html(rec.szMsg))
			Log(szExportFile, '</div>')
		end
		if onProgress then
			onProgress(_L['exporting'], nPage / nPageCount)
		end
		nPage = nPage + 1
	end
	X.BreatheCall('MY_ChatLog_ExportHTML', Export)
end

function D.IsRunning()
	return D.bExporting
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatLog_ExportHTML',
	exports = {
		{
			fields = {
				'Start',
				'IsRunning',
			},
			root = D,
		},
	},
}
MY_ChatLog_ExportHTML = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
