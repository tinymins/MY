--
-- 聊天记录
-- 记录团队/好友/帮会/密聊 供日后查询
-- 作者：翟一鸣 @ tinymins
-- 网站：ZhaiYiMing.CoM
--

-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local ssub, slen, schar, srep, sbyte, sformat, sgsub =
	  string.sub, string.len, string.char, string.rep, string.byte, string.format, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID = GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID
local setmetatable = setmetatable

local _L  = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Chat/lang/")
local _C  = {}
local Log = {}
local XML_LINE_BREAKER = XML_LINE_BREAKER
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
MY_ChatLog = MY_ChatLog or {}
MY_ChatLog.szActiveChannel		 = "MSG_WHISPER" -- 当前激活的标签页
MY_ChatLog.bIgnoreTongOnlineMsg	= true -- 帮会上线通知
MY_ChatLog.bIgnoreTongMemberLogMsg = true -- 帮会成员上线下线提示
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')

------------------------------------------------------------------------------------------------------
-- 数据采集
------------------------------------------------------------------------------------------------------
_C.TongOnlineMsg	   = '^' .. MY.String.PatternEscape(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG)
_C.TongMemberLoginMsg  = '^' .. MY.String.PatternEscape(g_tStrings.STR_GUILD_MEMBER_LOGIN):gsub('<link 0>', '.-') .. '$'
_C.TongMemberLogoutMsg = '^' .. MY.String.PatternEscape(g_tStrings.STR_GUILD_MEMBER_LOGOUT):gsub('<link 0>', '.-') .. '$'

function _C.OnMsg(szMsg, szChannel, nFont, bRich, r, g, b)
	local szText = szMsg
	if bRich then
		szText = GetPureText(szMsg)
	else
		szMsg = GetFormatText(szMsg, nil, r, g, b)
	end
	-- filters
	if szChannel == "MSG_GUILD" then
		if MY_ChatLog.bIgnoreTongOnlineMsg and szText:find(_C.TongOnlineMsg) then
			return
		end
		if MY_ChatLog.bIgnoreTongMemberLogMsg and (
			szText:find(_C.TongMemberLoginMsg) or szText:find(_C.TongMemberLogoutMsg)
		) then
			return
		end
	end
	-- generate rec
	szMsg = MY.Chat.GetTimeLinkText({r=r, g=g, b=b, f=nFont, s='[hh:mm:ss]'}) .. szMsg
	-- save and draw rec
	_C.AppendLog(szChannel, _C.GetCurrentDate(), szMsg)
	_C.UiAppendLog(szChannel, szMsg)
end

function _C.OnTongMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_GUILD', nFont, bRich, r, g, b)
end
function _C.OnWisperMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_WHISPER', nFont, bRich, r, g, b)
end
function _C.OnRaidMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_TEAM', nFont, bRich, r, g, b)
end
function _C.OnFriendMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_FRIEND', nFont, bRich, r, g, b)
end

MY.RegisterInit("MY_CHATLOG_REGMSG", function()
	MY.RegisterMsgMonitor('MY_ChatLog_Tong'  , _C.OnTongMsg  , { 'MSG_GUILD', 'MSG_GUILD_ALLIANCE' })
	MY.RegisterMsgMonitor('MY_ChatLog_Wisper', _C.OnWisperMsg, { 'MSG_WHISPER' })
	MY.RegisterMsgMonitor('MY_ChatLog_Raid'  , _C.OnRaidMsg  , { 'MSG_TEAM', 'MSG_PARTY', 'MSG_GROUP' })
	MY.RegisterMsgMonitor('MY_ChatLog_Friend', _C.OnFriendMsg, { 'MSG_FRIEND' })
end)

------------------------------------------------------------------------------------------------------
-- 数据存取
------------------------------------------------------------------------------------------------------
--[[
	Log = {
		MSG_WHISPER = {
			DateList = { 20150214, 20150215 }
			DateIndex = { [20150214] = 1, [20150215] = 2 }
			[20150214] = { <szMsg>, <szMsg>, ... },
			[20150215] = { <szMsg>, <szMsg>, ... },
			...
		},
		...
	}
]]
local DATA_PATH = 'userdata/CHAT_LOG/$uid/%s/%s.$lang.jx3dat'

_C.tModifiedLog = {}
function _C.GetCurrentDate()
	return tonumber(MY.Sys.FormatTime("yyyyMMdd", GetCurrentTime()))
end

function _C.RebuildDateList(tChannels, nScanDays)
	_C.UnloadLog()
	for _, szChannel in ipairs(tChannels) do
		Log[szChannel] = { DateList = {} }
		local nEndedDate = tonumber(MY.Sys.FormatTime("yyyyMMdd", GetCurrentTime()))
		local nStartDate = nEndedDate - nScanDays
		local tDateList  = Log[szChannel].DateList
		for dwDate = nStartDate, nEndedDate do
			if IsFileExist(MY.GetLUADataPath(DATA_PATH:format(szChannel, dwDate))) then
				tinsert(tDateList, dwDate)
				_C.tModifiedLog[szChannel] = { DateList = true }
			end
		end
	end
	_C.UnloadLog()
end

function _C.GetDateList(szChannel)
	if not Log[szChannel] then
		Log[szChannel] = {}
		Log[szChannel].DateList = MY.LoadLUAData(DATA_PATH:format(szChannel, 'DateList')) or {}
		Log[szChannel].DateIndex = {}
		for i, dwDate in ipairs(Log[szChannel].DateList) do
			Log[szChannel].DateIndex[dwDate] = i
		end
	end
	return Log[szChannel].DateList, Log[szChannel].DateIndex
end

function _C.GetLog(szChannel, dwDate)
	_C.GetDateList(szChannel)
	if not Log[szChannel][dwDate] then
		Log[szChannel][dwDate] = MY.LoadLUAData(DATA_PATH:format(szChannel, dwDate)) or {}
	end
	return Log[szChannel][dwDate]
end

function _C.AppendLog(szChannel, dwDate, szMsg)
	local log = _C.GetLog(szChannel, dwDate)
	tinsert(log, szMsg)
	-- mark as modified
	if not _C.tModifiedLog[szChannel] then
		_C.tModifiedLog[szChannel] = {}
	end
	_C.tModifiedLog[szChannel][dwDate] = true
	-- append datelist
	local DateList, DateIndex = _C.GetDateList(szChannel)
	if not DateIndex[dwDate] then
		tinsert(DateList, dwDate)
		DateIndex[dwDate] = #DateList
		_C.tModifiedLog[szChannel]['DateList'] = true
	end
	MY.DelayCall("MY_ChatLog",  _C.SaveLog, 30000)
end

function _C.SaveLog()
	for szChannel, tDate in pairs(_C.tModifiedLog) do
		for dwDate, _ in pairs(tDate) do
			if not empty(Log[szChannel][dwDate]) then
				MY.SaveLUAData(DATA_PATH:format(szChannel, dwDate), Log[szChannel][dwDate])
			end
		end
	end
	_C.tModifiedLog = {}
end

function _C.UnloadLog()
	_C.SaveLog()
	Log = {}
end
MY.RegisterExit(_C.UnloadLog)

local function getHeader()
	local szHeader = [[<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=GBK" />
<style>
*{font-size: 12px}
a{line-height: 16px}
input, button, select, textarea {outline: none}
body{background-color: #000; margin: 8px 8px 45px 8px}
#browserWarning{background-color: #f00; font-weight: 800; color:#fff; width: 100%; padding: 8px; position: fixed; opacity: 0.92; top: 0;}
.channel{color: #fff; font-weight: 800; font-size: 32px; padding: 0; margin: 30px 0 0 0}
.date{color: #fff; font-weight: 800; font-size: 24px; padding: 0; margin: 0}
#controls{background-color: #fff; width: 100%; height: 25px; position: fixed; opacity: 0.92; bottom: 0;}
]]
	
	if MY_Farbnamen and MY_Farbnamen.GetForceRgb then
		for k, v in pairs(g_tStrings.tForceTitle) do
			szHeader = szHeader .. (".force-%s{color:#%02X%02X%02X}"):format(k, unpack(MY_Farbnamen.GetForceRgb(k)))
		end
	end

	szHeader = szHeader .. [[
</style></head>
<body>
<div id="browserWarning">Please allow running JavaScript on this page!</div>
<script type="text/javascript">
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
        
        if (!Sys.chrome)
            document.getElementById("browserWarning").innerText = "WARNING: Please use Chrome to browse this page!!!";
        else
            document.getElementById("browserWarning").style["display"] = "none";
    })();
</script>
<div>
<a style="color: #fff;margin: 0 10px">]] .. GetClientPlayer().szName .. " @ " .. MY.GetServer() ..
" Exported at " .. MY.FormatTime("yyyyMMdd hh:mm:ss", GetCurrentTime()) .. "</a><hr />"

	return szHeader
end

local function getFooter()
	return [[
</div>
<div id="controls">
  <input type="range" style="width: 200px;height: 20px;" min="5" max="25" value="5" oninput='var a=document.getElementsByClassName("namelink"); for(i = a.length - 1; i >= 0; i--){a[i].style["-webkit-filter"]="blur(" + (this.value / 10) + "px)";}'>
</div>
</body>
</html>]]
end

local function getChannelTitle(szChannel)
	return [[<p class="channel">]] .. (g_tStrings.tChannelName[szChannel] or "") .. [[</p><hr />]]
end

local function getDateTitle(szDate)
	return [[<p class="date">]] .. (szDate or "") .. [[</p>]]
end

local function convertXml2Html(szXml)
	local aXml = MY.Xml.Decode(szXml)
	local t = {}
	if aXml then
		local text, name
		for _, xml in ipairs(aXml) do
			text = xml[''].text
			name = xml[''].name
			if text then
				local force
				text = text:gsub("\n", "<br>")
				tinsert(t, '<a')
				if name and name:sub(1, 9) == "namelink_" then
					tinsert(t, ' class="namelink')
					if MY_Farbnamen and MY_Farbnamen.Get then
						local info = MY_Farbnamen.Get((text:gsub("[%[%]]", "")))
						if info then
							force = info.dwForceID
							tinsert(t, ' force-')
							tinsert(t, info.dwForceID)
						end
					end
					tinsert(t, '"')
				end
				if not force and xml[''].r and xml[''].g and xml[''].b then
					tinsert(t, (' style="color:#%02X%02X%02X"'):format(xml[''].r, xml[''].g, xml[''].b))
				end
				tinsert(t, '>')
				tinsert(t, text)
				tinsert(t, '</a>')
			elseif name and name:sub(1, 8) == "emotion_" then
				tinsert(t, '<a class="')
				tinsert(t, name)
				tinsert(t, '"></a>')
			end
		end
	end
	return tconcat(t)
end

local m_bExporting
function MY_ChatLog.Export(szExportFile, aChannels, nPerSec, onProgress)
	local Log = _G.Log
	if m_bExporting then
		return MY.Sysmsg({_L['Already exporting, please wait.']})
	end
	if onProgress then
		onProgress(_L["preparing"], 0)
	end
	local status =  Log(szExportFile, getHeader(), "clear")
	if status ~= "SUCCEED" then
		return MY.Sysmsg({_L("Error: open file error %s [%s]", szExportFile, status)})
	end
	m_bExporting = true
	local szLastChannel, szLastDate
	local nChnIndex, nDateIndex, nOffset = 1, 1, 1
	local function Export()
		local szChannel = aChannels[nChnIndex]
		if not szChannel then
			m_bExporting = false
			Log(szExportFile, getFooter(), "close")
			if onProgress then
				onProgress(_L['Export succeed'], 1)
			end
			MY.Sysmsg({_L('Chatlog export succeed, file saved as %s', szExportFile)})
			return 0
		end
		if szChannel ~= szLastChannel then
			szLastChannel = szChannel
			Log(szExportFile, getChannelTitle(szChannel))
		end
		local DateList, DateIndex = _C.GetDateList(szChannel)
		local szDate = DateList[nDateIndex]
		if not szDate then
			nDateIndex = 1
			nChnIndex = nChnIndex + 1
			return
		end
		if szDate ~= szLastDate then
			szLastDate = szDate
			Log(szExportFile, getDateTitle(szDate))
		end
		local aLog = _C.GetLog(szChannel, DateList[nDateIndex])
		local nUIndex = nOffset + nPerSec
		if nUIndex >= #aLog then
			nUIndex = #aLog
		end
		for i = nOffset, nUIndex do
			if onProgress then
				onProgress(g_tStrings.tChannelName[szChannel] .. " - " .. DateList[nDateIndex],
				(((i - 1) / #aLog + (nDateIndex - 1)) / #DateList + (nChnIndex - 1)) / #aChannels)
			end
			Log(szExportFile, convertXml2Html(aLog[i]))
		end
		if nUIndex >= #aLog then
			nOffset = 1
			nDateIndex = nDateIndex + 1
		else
			nOffset = nUIndex + 1
		end
	end
	MY.BreatheCall("MY_ChatLog_Export", Export)
end

------------------------------------------------------------------------------------------------------
-- 界面绘制
------------------------------------------------------------------------------------------------------
function _C.UiRedrawLog()
	if not _C.uiLog then
		return
	end
	_C.uiLog:clear()
	_C.nDrawDate  = nil
	_C.nDrawIndex = nil
	_C.UiDrawPrev(20)
	_C.uiLog:scroll(100)
	if MY_ChatMosaics and MY_ChatMosaics.Mosaics then
		MY_ChatMosaics.Mosaics(_C.uiLog:hdl(1):raw(1))
	end
end

-- 加载更多
function _C.UiDrawPrev(nCount)
	if not _C.uiLog or _C.bUiDrawing == GetLogicFrameCount() then
		return
	end
	local h = _C.uiLog:hdl(1):raw(1)
	local szChannel = MY_ChatLog.szActiveChannel
	local DateList, DateIndex = _C.GetDateList(szChannel)
	if #DateList == 0 or -- 没有记录可以加载
	(_C.nDrawDate == DateList[1] and _C.nDrawIndex == 0) then -- 没有更多的记录可以加载
		return
	elseif not _C.nDrawDate then -- 还没有加载进度
		_C.nDrawDate = DateList[#DateList]
	end
	local nPos = 0
	local nLen = h:GetItemCount()
	-- 防止UI递归死循环 资源锁
	_C.bUiDrawing = GetLogicFrameCount()
	-- 保存当前滚动条位置
	local _, nH = h:GetSize()
	local _, nOrginScrollH = h:GetAllItemSize()
	local nOrginScrollY = (nOrginScrollH - nH) * _C.uiLog:scroll() / 100
	-- 绘制聊天记录
	while nCount > 0 do
		-- 加载指定日期的记录
		local log = _C.GetLog(szChannel, _C.nDrawDate)
		-- nDrawIndex为空则从最后一条开始加载
		if not _C.nDrawIndex then
			_C.nDrawIndex = #log
		end
		-- 计算该日期的记录是否足够加载剩余待加载条数
		if _C.nDrawIndex > nCount then -- 足够 则直接加载
			h:InsertItemFromString(0, false, tconcat(log, "", _C.nDrawIndex - nCount + 1, _C.nDrawIndex))
			_C.nDrawIndex = _C.nDrawIndex - nCount
			nCount = 0
		else -- 不足 则加载完后将加载进度指向上一个日期
			h:InsertItemFromString(0, false, tconcat(log, "", 1, _C.nDrawIndex))
			h:InsertItemFromString(0, false, GetFormatText("========== " .. _C.nDrawDate .. " ==========\n")) -- 跨日期输出日期戳
			-- 判断还有没有记录可以加载
			local nIndex = DateIndex[_C.nDrawDate]
			if nIndex == 1 then -- 没有记录可以加载了
				nCount = 0
				_C.nDrawIndex = 0
			else -- 还有记录
				nCount = nCount - _C.nDrawIndex
				_C.nDrawDate = DateList[nIndex - 1]
				_C.nDrawIndex = nil
			end
		end
	end
	h:FormatAllItemPos()
	nLen = h:GetItemCount() - nLen
	MY_ChatMosaics.Mosaics(h, nPos, nLen)
	for i = 0, nLen do
		local hItem = h:Lookup(i)
		MY.Chat.RenderLink(hItem)
		if MY_Farbnamen and MY_Farbnamen.Render then
			MY_Farbnamen.Render(hItem)
		end
	end
	-- 恢复之前滚动条位置
	if nOrginScrollY < 0 then -- 之前没有滚动条
		if _C.uiLog:scroll() >= 0 then -- 现在有滚动条
			_C.uiLog:scroll(100)
		end
	else
		local _, nScrollH = h:GetAllItemSize()
		local nDeltaScrollH = nScrollH - nOrginScrollH
		_C.uiLog:scroll((nDeltaScrollH + nOrginScrollY) / (nScrollH - nH) * 100)
	end
	-- 防止UI递归死循环 资源锁解除
	_C.bUiDrawing = nil
end

function _C.UiAppendLog(szChannel, szMsg)
	if not (_C.uiLog and szChannel == MY_ChatLog.szActiveChannel) then
		return
	end
	local bBottom = _C.uiLog:scroll() == 100
	if MY_ChatMosaics then
		local h = _C.uiLog:hdl(1):raw(1)
		local nCount
		if h then
			nCount = h:GetItemCount()
		end
		_C.uiLog:append(szMsg)
		if nCount then
			MY_ChatMosaics.Mosaics(h, nCount)
			for i = nCount, h:GetItemCount() - 1 do
				local hItem = h:Lookup(i)
				MY.Chat.RenderLink(hItem)
				if MY_Farbnamen and MY_Farbnamen.Render then
					MY_Farbnamen.Render(hItem)
				end
			end
		end
	else
		_C.uiLog:append(szMsg)
	end
	if bBottom then
		_C.uiLog:scroll(100)
	end
end

function _C.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 10
	
	_C.uiLog = ui:append("WndScrollBox", "WndScrollBox_Log", {
		x = 20, y = 35, w = w - 21, h = h - 40, handlestyle = 3,
		onscroll = function(nScrollPercent, nScrollDistance)
			if nScrollPercent == 0 -- 当前滚动条位置为0
			or (nScrollPercent == -1 and nScrollDistance == -1) then -- 还没有滚动条但是鼠标往上滚了
				_C.UiDrawPrev(20)
			end
		end,
	}):children('#WndScrollBox_Log')
	
	for i, szChannel in ipairs({
		'MSG_GUILD'  ,
		'MSG_WHISPER',
		'MSG_TEAM'   ,
		'MSG_FRIEND' ,
	}) do
		ui:append('WndRadioBox', 'RadioBox_' .. szChannel):children('#RadioBox_' .. szChannel)
		  :pos(x + (i - 1) * 100, y):width(90)
		  :text(g_tStrings.tChannelName[szChannel] or '')
		  :check(function(bChecked)
		  	if bChecked then
		  		MY_ChatLog.szActiveChannel = szChannel
		  	end
		  	_C.UiRedrawLog()
		  end)
		  :check(MY_ChatLog.szActiveChannel == szChannel)
	end
	
	ui:append("Image", "Image_Setting"):item('#Image_Setting')
	  :pos(w - 26, y - 6):size(30, 30):alpha(200)
	  :image('UI/Image/UICommon/Commonpanel.UITex',18)
	  :hover(function(bIn) this:SetAlpha((bIn and 255) or 200) end)
	  :click(function()
	  	PopupMenu((function()
	  		local t = {}
	  		table.insert(t, {
	  			szOption = _L['filter tong member log message'],
	  			bCheck = true, bChecked = MY_ChatLog.bIgnoreTongMemberLogMsg,
	  			fnAction = function()
	  				MY_ChatLog.bIgnoreTongMemberLogMsg = not MY_ChatLog.bIgnoreTongMemberLogMsg
	  			end,
	  		})
	  		table.insert(t, {
	  			szOption = _L['filter tong online message'],
	  			bCheck = true, bChecked = MY_ChatLog.bIgnoreTongOnlineMsg,
	  			fnAction = function()
	  				MY_ChatLog.bIgnoreTongOnlineMsg = not MY_ChatLog.bIgnoreTongOnlineMsg
	  			end,
	  		})
	  		table.insert(t, {
	  			szOption = _L['rebuild date list'],
	  			fnAction = function()
	  				_C.RebuildDateList({
	  					"MSG_GUILD", "MSG_WHISPER", "MSG_TEAM", "MSG_FRIEND"
	  				}, 300)
	  				_C.UiRedrawLog()
	  			end,
	  		})
	  		table.insert(t, {
	  			szOption = _L['export chatlog'],
	  			fnAction = function()
	  				MY_ChatLog.Export(MY.GetLUADataPath("export/ChatLog/$name@$server.html"), {
						"MSG_GUILD", "MSG_WHISPER", "MSG_TEAM", "MSG_FRIEND"
					}, 10, function(szTitle, fProgress)
						OutputMessage("MSG_ANNOUNCE_YELLOW", _L("Exporting chatlog: %s, %.2f%%.", szTitle, fProgress * 100))
					end)
	  			end,
	  		})
	  		return t
	  	end)())
	end)

end

MY.RegisterPanel( "ChatLog", _L["chat log"], _L['Chat'], "ui/Image/button/SystemButton.UITex|43", {255,127,0,200}, {
	OnPanelActive = _C.OnPanelActive,
	OnPanelDeactive = function()
		_C.uiLog = nil
	end
})
