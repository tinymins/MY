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
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog_ExportHTML'
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

local D = {
	bExporting = false,
}
local EXPORT_SLICE = 100
local MSG_TYPE_COLOR = MY_ChatLog.MSG_TYPE_COLOR

--[[
https://www.jx3box.com/joke
JSON.stringify([...document.querySelectorAll('.c-jx3box-emotion-item')].map(n => n.firstChild).map(n => {
    const id = n.src.match(/\/\d+_(\d+)_/)[1];
    return {id: parseInt(id), src: n.src};
}))
]]

local EMOTION_LIST = '[{"id":1,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_1__%E5%BE%AE%E7%AC%91.gif"},{"id":2,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_2__%E5%8F%AF%E6%80%9C.gif"},{"id":3,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_3__%E5%90%90.gif"},{"id":4,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_4__%E5%AA%9A%E7%9C%BC.gif"},{"id":5,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_5__%E5%AE%B3%E7%BE%9E.gif"},{"id":6,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_6__%E5%B0%B4%E5%B0%AC.gif"},{"id":7,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_7__%E7%8B%82%E6%B1%97.gif"},{"id":8,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_8__%E6%81%90%E6%85%8C.gif"},{"id":9,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_9__%E7%94%9F%E6%B0%94.gif"},{"id":10,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_10__%E6%98%8F.gif"},{"id":11,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_11__%E6%B5%81%E6%B3%AA.gif"},{"id":12,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_12__%E4%BA%B2%E4%BA%B2.png"},{"id":13,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_13__%E6%B2%89%E9%BB%98.png"},{"id":14,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_14__%E6%97%A0%E5%A5%88.png"},{"id":15,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_15__%E5%82%B2%E6%85%A2.png"},{"id":16,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_16__%E5%86%B7%E6%B1%97.png"},{"id":17,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_17__%E5%A4%A7%E7%AC%91.png"},{"id":18,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_18__%E9%98%B4%E9%99%A9.png"},{"id":19,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_19__%E9%9A%BE%E8%BF%87.png"},{"id":20,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_20__%E8%AE%A8%E5%8E%8C.png"},{"id":21,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_21__%E5%B7%B4%E6%8E%8C.png"},{"id":22,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_22__%E6%B5%81%E6%B1%97.png"},{"id":23,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_23__%E5%8F%91%E6%80%92.png"},{"id":24,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_24__%E6%AC%A3%E5%96%9C.png"},{"id":25,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_25__%E5%8F%A3%E6%B0%B4.png"},{"id":26,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_26__%E5%90%93.png"},{"id":27,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_27__%E5%91%86.png"},{"id":28,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_28__%E5%99%A2.png"},{"id":29,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_29__%E5%91%B2%E7%89%99.png"},{"id":30,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_30__%E6%81%B6%E5%BF%83.png"},{"id":31,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_31__%E5%9B%B0.png"},{"id":32,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_32__%E5%87%B6%E6%81%B6.png"},{"id":33,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_33__%E7%8B%A1%E8%AF%88.png"},{"id":34,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_34__%E5%BE%97%E6%84%8F.png"},{"id":35,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_35__%E9%AC%BC%E8%84%B8.png"},{"id":36,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_36__%E6%89%81%E5%98%B4.png"},{"id":37,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_37__%E6%92%87%E5%98%B4.png"},{"id":38,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_38__%E6%99%95.png"},{"id":39,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_39__%E7%8B%A1%E7%8C%BE.png"},{"id":40,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_40__%E7%9D%A1.png"},{"id":41,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_41__%E8%88%8C%E5%A4%B4.png"},{"id":42,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_42__%E8%89%B2.png"},{"id":43,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_43__%E8%AE%B6%E5%BC%82.png"},{"id":44,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_44__%E9%84%99%E8%A7%86.png"},{"id":45,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_45__%E9%85%B7.png"},{"id":46,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_46__%E9%92%B1.gif"},{"id":47,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_47__%E9%94%A4%E5%AD%90.gif"},{"id":48,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_48__%E6%89%93%E9%9B%B7.gif"},{"id":49,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_49__%E9%97%AE%E5%8F%B7.gif"},{"id":50,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_50__%E7%BA%A2%E7%81%AF.gif"},{"id":51,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_51__%E7%BB%BF%E7%81%AF.gif"},{"id":52,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_52__%E9%BB%84%E7%81%AF.gif"},{"id":53,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_53__%E4%B8%8B%E9%9B%A8.gif"},{"id":54,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_54__%E5%88%80.gif"},{"id":55,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_55__%E5%92%96%E5%95%A1.gif"},{"id":56,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_56__%E5%96%9C%E6%AC%A2.gif"},{"id":57,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_57__%E5%98%B4.gif"},{"id":58,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_58__%E5%94%87.gif"},{"id":59,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_59__%E5%BF%83%E7%A2%8E.gif"},{"id":60,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_60__%E6%84%9F%E5%8F%B9%E5%8F%B7.gif"},{"id":61,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_61__%E6%8B%8D%E6%89%8B.gif"},{"id":62,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_62__%E6%8F%A1%E6%89%8B.gif"},{"id":63,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_63__%E7%8C%AA.gif"},{"id":64,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_64__%E7%8E%AB%E7%91%B0.gif"},{"id":65,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_65__%E7%94%B5%E8%AF%9D.gif"},{"id":66,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_66__%E7%81%AF%E6%B3%A1.gif"},{"id":67,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_67__%E7%AC%A8%E7%8C%AA.png"},{"id":68,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_68__%E6%9C%88%E4%BA%AE.png"},{"id":69,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_69__%E8%8F%A0%E8%90%9D.png"},{"id":70,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_70__%E9%AA%B7%E9%AB%85.png"},{"id":71,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_71__%E7%A4%BC%E7%89%A9.png"},{"id":72,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_72__%E4%B8%A5%E5%AF%92.png"},{"id":73,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_73__%E5%AF%92.png"},{"id":74,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_74__%E8%A1%B0.png"},{"id":75,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_75__%E8%8A%B1.png"},{"id":76,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_76__%E9%A6%99%E8%95%89.png"},{"id":77,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_77__%E9%9B%AA%E7%B3%95.png"},{"id":78,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_78__%E8%83%9C%E5%88%A9.png"},{"id":79,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_79__%E8%8B%B9%E6%9E%9C.png"},{"id":80,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_80__%E9%A5%AE%E6%96%99.png"},{"id":81,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_81__%E9%A6%92%E5%A4%B4.png"},{"id":82,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_82__%E8%A5%BF%E7%93%9C.png"},{"id":83,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_83__%E7%83%9F%E8%8A%B1.png"},{"id":84,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_84__%E6%A0%87%E8%AE%B0.png"},{"id":85,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_85__%E8%92%9C%E5%A4%B4.png"},{"id":86,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_86__%E5%A4%AA%E9%98%B3.png"},{"id":87,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_87__%E7%88%B1%E5%BF%83.png"},{"id":88,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_88__%E5%BC%BA.png"},{"id":89,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_89__%E5%B7%AE%E5%8A%B2.png"},{"id":90,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_90__%E6%A8%B1%E6%A1%83.png"},{"id":91,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_91__%E7%AC%AC%E4%B8%80%E5%90%8D.png"},{"id":92,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_92__%E7%AC%AC%E4%BA%8C%E5%90%8D.png"},{"id":93,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_93__%E7%AC%AC%E4%B8%89%E5%90%8D.png"},{"id":94,"src":"https://img.jx3box.com/emotion/output/%E9%BB%98%E8%AE%A4/0_94__%E8%9C%A1%E7%83%9B.gif"}]'

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
.message-item {
	display: flex;
	align-items: center;
}
{{$emotionStyles}}
.emotion {
	background-size: cover;
	background-repeat: no-repeat;
	width: 1.2em;
	height: 1.2em;
	display: inline-block;
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
					contentHtml += '<span';
					if (part.color) {
						contentHtml += ' style="color:' + part.color + '"';
					}
					contentHtml += '>' + part.text + '</span>';
				} else if (part.type === 'emotion') {
					contentHtml += '<span class="emotion emotion_' + part.id + '"></span>';
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
	local emotionStyles = ''
	for _, emo in ipairs(X.DecodeJSON(EMOTION_LIST)) do
		emotionStyles = emotionStyles .. '.emotion_' .. emo.id .. '{\n\tbackground-image: url(\''.. emo.src .. '\');\n}\n'
	end
	local forceStyles = ''
	for k, v in pairs(g_tStrings.tForceTitle) do
		forceStyles = forceStyles .. ('.force-%s{\n\tcolor:#%02X%02X%02X;\n}\n'):format(k, X.GetForceColor(k, 'foreground'))
	end
	local tVar = {
		charset = (X.ENVIRONMENT.GAME_LANG == 'zhcn' and 'GBK') or 'UTF-8',
		emotionStyles = emotionStyles,
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
		for i, node in ipairs(aXMLNode) do
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
						color = color,
					})
				end
			elseif name and name:sub(1, 8) == 'emotion_' then
				local emotion_id = tonumber(name:match('emotion_(%d+)'))
				table.insert(aMessage, {
					type = 'emotion',
					id = emotion_id,
				})
			else
				-- 金钱单位等图片解析
				local aSay = X.ParseChatData({ node })
				local item = aSay and aSay[1]
				if item and item.text then
					table.insert(aMessage, {
						type = 'text',
						text = item.text,
					})
				end
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
			local aXMLNode = X.XMLDecode(rec.szMsg)
			local aSay = X.ParseChatData(aXMLNode)
			local szText = X.StringifyChatText(aSay)
			local msg = {
				time = rec.nTime,
				talker = rec.szTalker or '',
				color = color,
				text = X.FormatTime(rec.nTime, '[%yyyy/%MM/%dd][%hh:%mm:%ss]') .. szText,
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
