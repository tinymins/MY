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

local function renderTemplateString(szTplString, tVar)
    return (szTplString:gsub("{{%$(%w+)}}", function(varName)
        return tVar[varName] or ""
    end))
end

local function getHeader()
	local szTplString = [[
<!DOCTYPE html>
<html>
<head><meta http-equiv='Content-Type' content='text/html; charset={{$charset}}' />
<style>
* {
	font-size: 12px;
}
a {
	line-height: 16px;
}
input,
button,
select,
textarea {
	outline: none;
}
body {
	background-color: #000;
	margin: 8px 8px 45px 8px;
}
#browserWarning {
	background-color: #f00;
	font-weight: 800;
	color: #fff;
	padding: 8px;
	position: fixed;
	opacity: 0.92;
	top: 0;
	left: 0;
	right: 0;
}
.channel {
	color: #fff;
	font-weight: 800;
	font-size: 32px;
	padding: 0;
	margin: 30px 0 0 0;
}
.date {
	color: #fff;
	font-weight: 800;
	font-size: 24px;
	padding: 0;
	margin: 0;
}
a.content {
	font-family: cursive;
}
span.emotion_44 {
	width: 21px;
	height: 21px;
	display: inline-block;
	background-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAO/SURBVDhPnZT7U4xRGMfff4GftEVKYsLutkVETKmsdrtY9QMNuTRDpVZS2Fw2utjcL1NSYaaUa5gRFSK5mzFukzHGYAbjOmTC7tv79vWcs2+bS7k9M985u+c953PO85zneYS+zBQThYChKvj7ejg1zDnqfN1hipkKZdnfmXFKKLRD3aHXecMyPQh1q+PRVr4Qj2qycKZkAfLmRyJitA80tCaa1irb+rZR3m4I9huIgsQQvKxKxZemXEgNuZAvrIPcWoSuqzbYH5bhcZMV6fHjETjcA6OGuPUNHuk9AJM1g3E4IxId9TnwcuvHJV0phHQuD9L5fODFPtf8mwcV2JIVg4kab6h9VL+Co/VhGOOrQlnSBHQcWeyE3SqG1JKHzoaVkC4WQr68HniyGUAb6QFf86FtC0qzTRhL3kVPCfsRrKGTUsNH4lX5PDiOLoZ0yQrpzCoOlW9uoLGAu4/2cgK2kC6QGiG9rsCr5gKkm8ZBTTFWcIIQH2dAyHAV7q+d5nLNJVV/Psq3NkO+RNC3lb+s8VHWBNFtE4jFJGgolsmhfnheZKTTfzS2WL6/3XlTcr/r3iYC71S+Oo2teXfdhjlTAzDCawCXwNJnx8xgvC9Jgrg7EfZ98yAeSoGjLt3p+lkrZHp1+cp6GosJbkPXnXwuudWKLjpUvJiPvctMPM2YBH9K5pZsPeyls2HfkwzHQTPE49nobFrNX12+pgC/1zUGL+r5T6G5uyfNVSgcejs3CvYSgu4laFUKxBM5Lih3/Xtgb2otxNOaJdBR1TFxaIM5nG6ahK9lc+HYnwbxSCbE+hWQmtf+GcpCQ/FuLp7dc9MAHzdYo3X4vG0m7LuSYK+cD8eBDIinLehsZGn1E5QgbI6L8pd707gS62ZNhD+xmARTrAF69SA8sSX0hKA6tee2lJ+uh6L4MggrCHYgP5QOf1ebAUPgEGo0UVw8V1kGbEoYg090WwcVAH+wbvApBawAxZPLac7CH1Oi2H+py8LGWZN4E+KwbouibhOh8UR9Wjjat82Ao8IJ7jyYDrF6AaRTOUplkavHsyAezaRvZnRUL8KxpQZM8POAobeOFUClatB5oSY5BB+2Unx3z4FtSZyrcrply4ylmC/CRwoVaz562qP+XafS0MfgYSqsMGjxzGbiEPshCkMtpVkNSzUzn3tJYcqbFohJIzzA+oayvW8zUsdiVRHq5w6LUYvalDDcsBhxb00c6s2RyE8Igl7ryWPYq8u/s+nUGNTUF/xpM8tlLvqtJW9MscoL/6v9P1QQvgHonm5Hx/sAiwAAAABJRU5ErkJggg==");
}
#controls {
	background-color: #fff;
	position: fixed;
	opacity: 0.92;
	bottom: 0;
	left: 0;
	right: 0;
	display: flex;
}
#mosaics {
	width: 80px;
	height: 20px;
}
#pagination {
	display: flex;
	align-items: center;
}
.pagination-page,
.pagination-go {
	height: 20px;
	margin: 3px 2px;
}
.pagination-page.active {
	background-color: #ffffff;
}
.pagination-input {
	width: 35px;
}
.search-input {
	width: 80px;
	margin: 3px 2px;
}
.search-button {
	height: 20px;
	margin: 3px 2px;
}
{{$forceStyles}}
</style>
</head>
<body>
<div id='browserWarning'>Please allow running JavaScript on this page!</div>
<div id='controls' style='display:none'>
	<input type="text" id="searchInput" class="search-input">
	<button class="search-button" onclick="search()">Search</button>
	<div id="pagination"></div>
	<input type='range' id='mosaics' min='0' max='200' value='0'>
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

		if (!Sys.chrome && !Sys.firefox) {
			document.getElementById('browserWarning').innerHTML = '<a>WARNING: Please use </a><a href=\'https://www.google.cn/chrome/browser/desktop/index.html\' style=\'color: yellow;\'>Chrome</a></a> to browse this page!!!</a>';
		} else {
			document.getElementById('controls').style['display'] = null;
			document.getElementById('browserWarning').style['display'] = 'none';
		}
	})();

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
			var radius = this.value == 0 ? 0 : (this.value / 100 + 0.5);
			setMosaic(radius + 'px');
		}
	})();

	window.MESSAGES = [];
	window.messages = [];

	var DISP_PAGE_NUMBER = 9;

	var currentPage = 0;
	var pageSize = 100;

	function renderPage() {
		var messages = window.messages;
		var container = document.getElementById('messageContainer');
		container.innerHTML = '';
		var start = currentPage * pageSize;
		var end = start + pageSize;
		for (var i = start; i < end && i < messages.length; i++) {
			var msg = messages[i];
			var contentHtml = '';
			for (var j = 0; j < msg.parts.length; j++) {
				var part = msg.parts[j];
				if (part.type === 'namelink') {
					contentHtml += '<a class="namelink force-' + part.force_id + '">' + part.name + '</a>';
				} else if (part.type === 'text') {
					contentHtml += '<span style="color:' + part.color + '">' + part.text + '</span>';
				} else if (part.type === 'emotion') {
					contentHtml += '<span class="emotion_' + part.id + '"></span>';
				}
			}
			var date = new Date(msg.time * 1000);
			var formattedTime = `[${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}/${String(date.getDate()).padStart(2, '0')}]` +
				`[${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:${String(date.getSeconds()).padStart(2, '0')}]`;
			container.innerHTML += `<div class="message-item" style="color:${msg.color}">${formattedTime}${contentHtml}</div>`;
		}
	}

	function onPageClick() {
		currentPage = parseInt(this.getAttribute('data-index'), 10);
		currentPage = Math.max(currentPage, 0);
		currentPage = Math.min(currentPage, Math.ceil(messages.length / pageSize) - 1);
		renderPage();
		renderPagination();
	}

	function renderPagination() {
		var messages = window.messages;
		var pagination = document.getElementById('pagination');
		pagination.innerHTML = '';

		var maxPageNumber = Math.ceil(messages.length / pageSize) - 1;

		var createButton = function(text, index) {
			var button = document.createElement('button');
			button.innerText = text;
			button.setAttribute('data-index', index);
			button.onclick = onPageClick;
			button.className = 'pagination-page';
			return button;
		};

		pagination.appendChild(createButton('<', currentPage - 1));

		var startPage = Math.max(0, Math.min(currentPage - Math.floor(DISP_PAGE_NUMBER / 2), maxPageNumber - DISP_PAGE_NUMBER));
		var endPage = Math.min(maxPageNumber, startPage + DISP_PAGE_NUMBER);

		if (startPage === 0 && endPage !== maxPageNumber) {
			endPage += 1;
		} else if (startPage !== 0 && endPage === maxPageNumber) {
			startPage -= 1;
		}

		for (var i = 0; i <= maxPageNumber; i++) {
			if (i === 0 || i === maxPageNumber || (i >= startPage && i <= endPage)) {
				var pageButton = createButton(i + 1, i);
				if (i === currentPage) {
					pageButton.className += ' active';
				}
				pagination.appendChild(pageButton);
			}
		}

		pagination.appendChild(createButton('>', currentPage + 1));

		var input = document.createElement('input');
		input.type = 'number';
		input.min = 1;
		input.max = maxPageNumber + 1;
		input.value = currentPage + 1;
		input.className = 'pagination-input';
		pagination.appendChild(input);

		var goButton = document.createElement('button');
		goButton.innerText = 'GO';
		goButton.onclick = function() {
			var pageIndex = parseInt(input.value, 10) - 1;
			if (!isNaN(pageIndex) && pageIndex >= 0 && pageIndex <= maxPageNumber) {
				currentPage = pageIndex;
				renderPage();
				renderPagination();
			}
		};
		goButton.className = 'pagination-go';
		pagination.appendChild(goButton);
	}

	function search() {
		var s = document.getElementById('searchInput').value;
		if (s) {
			window.messages = [];
			for (var i = 0; i < window.MESSAGES.length; i++) {
				if (window.MESSAGES[i].text.indexOf(s) !== -1) {
					window.messages.push(window.MESSAGES[i]);
				}
			}
		} else {
			window.messages = window.MESSAGES;
		}
		currentPage = 0;
		renderPage();
		renderPagination();
	}
</script>
<div>
<a style='color: #fff;margin: 0 10px'>{{$title}}</a><hr /><div id="messageContainer"></div>
]]
	local forceStyles = ''
	for k, v in pairs(g_tStrings.tForceTitle) do
		forceStyles = forceStyles .. ('.force-%s{\n\tcolor:#%02X%02X%02X;\n}\n'):format(k, X.GetForceColor(k, 'foreground'))
	end
	local tVar = {
		charset = (X.ENVIRONMENT.GAME_LANG == 'zhcn' and 'GBK') or 'UTF-8',
		forceStyles = forceStyles,
		title = X.GetClientPlayer().szName .. ' @ ' .. X.GetServerName() .. ' Exported at ' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd %hh:%mm:%ss'),
	}
	return renderTemplateString(szTplString, tVar)
end

local function getFooter()
	return [[
<script type='text/javascript'>
	renderPage();
	renderPagination();
</script>
</div>
</body>
</html>
]]
end

local function convertXml2MessageJSON(szXml)
	local aXMLNode = X.XMLDecode(szXml)
	local aMessage = {}
	if aXMLNode then
		local text, name, force, r, g, b, color
		for _, node in ipairs(aXMLNode) do
			text = X.XMLGetNodeData(node, 'text')
			name = X.XMLGetNodeData(node, 'name')
			if text then
				text = htmlEncode(text)
				force = nil
				color = nil
				if name and name:sub(1, 9) == 'namelink_' then
					if MY_Farbnamen and MY_Farbnamen.Get then
						local info = MY_Farbnamen.Get((text:gsub('[%[%]]', '')))
						if info then
							force = info.dwForceID
						end
					end
					table.insert(aMessage, {
						type = 'namelink',
						name = text,
						force = force or -1,
					})
				else
					r = X.XMLGetNodeData(node, 'r')
					g = X.XMLGetNodeData(node, 'g')
					b = X.XMLGetNodeData(node, 'b')
					if r and g and b then
						color = ('#%02X%02X%02X'):format(r, g, b)
					end
					table.insert(aMessage, {
						type = 'text',
						text = text,
						color = color or '#FFFFFF',
					})
				end
			elseif name and name:sub(1, 8) == 'emotion_' then
				local emotion_id = tonumber(name:match('emotion_(%d+)'))
				table.insert(aMessage, {
					type = 'emotion',
					id = emotion_id,
				})
			end
		end
	end
	return aMessage
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

	Log(szExportFile, '\n<script>\n\twindow.MESSAGES = [')

	local nPage, nPageCount = 0, math.ceil(ds:CountMsg(aMsgType, '') / EXPORT_SLICE)
	local function Export()
		if nPage > nPageCount then
			D.bExporting = false
			Log(szExportFile, '];\n\twindow.messages = window.MESSAGES;\n</script>\n')
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
			local color, r, g, b = nil, unpack(MSG_TYPE_COLOR[rec.szMsgType])
			if r and g and b then
				color = ('#%02X%02X%02X'):format(r, g, b)
			end
			local msg = {
				time = rec.nTime,
				talker = rec.szTalker or '',
				color = color,
				text = X.FormatTime(rec.nTime, '[%yyyy/%MM/%dd][%hh:%mm:%ss]') .. X.GetPureText(rec.szMsg),
				parts = convertXml2MessageJSON(rec.szMsg)
			}
			if nPage ~= 0 or i ~= 1 then
				Log(szExportFile, ',')
			end
			Log(szExportFile, X.EncodeJSON(msg))
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
