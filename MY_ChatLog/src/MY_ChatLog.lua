--
-- 聊天记录
-- 记录团队/好友/帮会/密聊 供日后查询
-- 作者：翟一鸣 @ tinymins
-- 网站：ZhaiYiMing.CoM
--

-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local XML_LINE_BREAKER = XML_LINE_BREAKER
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local ssub, slen, schar, srep, sbyte, sformat, sgsub =
	  string.sub, string.len, string.char, string.rep, string.byte, string.format, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID = GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID
local setmetatable = setmetatable

local _L  = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ChatLog/lang/")
MY_ChatLog = MY_ChatLog or {}
MY_ChatLog.bIgnoreTongOnlineMsg    = true -- 帮会上线通知
MY_ChatLog.bIgnoreTongMemberLogMsg = true -- 帮会成员上线下线提示
MY_ChatLog.bBlockWords             = true -- 不记录屏蔽关键字
RegisterCustomData('MY_ChatLog.bBlockWords')
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')

------------------------------------------------------------------------------------------------------
-- 数据采集
------------------------------------------------------------------------------------------------------
local TONG_ONLINE_MSG        = '^' .. MY.String.PatternEscape(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG)
local TONG_MEMBER_LOGIN_MSG  = '^' .. MY.String.PatternEscape(g_tStrings.STR_GUILD_MEMBER_LOGIN):gsub('<link 0>', '.-') .. '$'
local TONG_MEMBER_LOGOUT_MSG = '^' .. MY.String.PatternEscape(g_tStrings.STR_GUILD_MEMBER_LOGOUT):gsub('<link 0>', '.-') .. '$'

------------------------------------------------------------------------------------------------------
-- 数据库核心
------------------------------------------------------------------------------------------------------
local PAGE_AMOUNT = 150
local EXPORT_SLICE = 100
local PAGE_DISPLAY = 17
local SZ_INI = MY.GetAddonInfo().szRoot .. "MY_ChatLog/ui/MY_ChatLog.ini"
local CHANNELS = {[1] = "MSG_WHISPER", [2] = "MSG_PARTY", [3] = "MSG_TEAM", [4] = "MSG_FRIEND", [5] = "MSG_GUILD", [6] = "MSG_GUILD_ALLIANCE"}
local CHANNELS_R = (function() local t = {} for k, v in pairs(CHANNELS) do t[v] = k end return t end)()
local DB, DB_W, DB_D
local function InitDB()
	local DB_PATH = MY.FormatPath('$uid@$lang/userdata/chat_log.db')
	local SZ_OLD_PATH = MY.FormatPath('userdata/CHAT_LOG/$uid.db')
	if IsLocalFileExist(SZ_OLD_PATH) then
		CPath.Move(SZ_OLD_PATH, DB_PATH)
	end
	DB = SQLite3_Open(DB_PATH)
	if not DB then
		return MY.Debug({"Cannot connect to database!!!"}, "MY_ChatLog", MY_DEBUG.ERROR)
	end
	local me = GetClientPlayer()
	DB:Execute("CREATE TABLE IF NOT EXISTS ChatLogUser (userguid INTEGER, PRIMARY KEY (userguid))")
	DB:Execute("REPLACE INTO ChatLogUser (userguid) VALUES (" .. me.GetGlobalID() .. ")")
	
	DB:Execute("CREATE TABLE IF NOT EXISTS ChatLog (hash INTEGER, channel INTEGER, time INTEGER, talker NVARCHAR(20), text NVARCHAR(400) NOT NULL, msg NVARCHAR(4000) NOT NULL, PRIMARY KEY (hash, time))")
	DB:Execute("CREATE INDEX IF NOT EXISTS chatlog_channel_idx ON ChatLog(channel)")
	DB:Execute("CREATE INDEX IF NOT EXISTS chatlog_time_idx ON ChatLog(time)")
	DB:Execute("CREATE INDEX IF NOT EXISTS chatlog_text_idx ON ChatLog(text)")
	DB_W = DB:Prepare("REPLACE INTO ChatLog (hash, channel, time, talker, text, msg) VALUES (?, ?, ?, ?, ?, ?)")
	DB_D = DB:Prepare("DELETE FROM ChatLog WHERE hash = ? AND time = ?")
	
	local SZ_OLD_PATH = MY.FormatPath('userdata/CHAT_LOG/$uid/') -- %s/%s.$lang.jx3dat
	if IsLocalFileExist(SZ_OLD_PATH) then
		local nScanDays = 365 * 3
		local nDailySec = 24 * 3600
		local date = TimeToDate(GetCurrentTime())
		local dwEndedTime = GetCurrentTime() - date.hour * 3600 - date.minute * 60 - date.second
		local dwStartTime = dwEndedTime - nScanDays * nDailySec
		local nHour, nMin, nSec
		local function regexp(...)
			nHour, nMin, nSec = ...
			return ""
		end
		local szTalker
		local function regexpN(...)
			szTalker = ...
		end
		local hash, time, talker, text, msg
		DB:Execute("BEGIN TRANSACTION")
		for nChannel, szChannel in pairs(CHANNELS) do
			local SZ_CHANNEL_PATH = SZ_OLD_PATH .. szChannel .. "/"
			if IsLocalFileExist(SZ_CHANNEL_PATH) then
				for dwTime = dwStartTime, dwEndedTime, nDailySec do
					local szDate = MY.Sys.FormatTime("yyyyMMdd", dwTime)
					local data = MY.LoadLUAData(SZ_CHANNEL_PATH .. szDate .. '.$lang.jx3dat')
					if data then
						for _, szMsg in ipairs(data) do
							nHour, nMin, nSec, szTalker = nil
							szMsg = szMsg:gsub('<text>text="%[(%d+):(%d+):(%d+)%]".-</text>', regexp)
							szMsg:gsub('text="%[([^"<>]-)%]"[^<>]-name="namelink_', regexpN)
							if nHour and nMin and nSec and szTalker then
								msg    = AnsiToUTF8(szMsg)
								text   = AnsiToUTF8(GetPureText(szMsg))
								hash   = GetStringCRC(msg)
								talker = AnsiToUTF8(szTalker)
								time   = dwTime + nHour * 3600 + nMin * 60 + nSec
								DB_W:ClearBindings()
								DB_W:BindAll(hash, nChannel, time, talker, text, msg)
								DB_W:Execute()
							end
						end
					end
				end
			end
		end
		DB:Execute("END TRANSACTION")
		CPath.DelDir(SZ_OLD_PATH)
	end
	
	do
		local t = {}
		for nChannel, szChannel in pairs(CHANNELS) do
			tinsert(t, szChannel)
		end
		local function OnMsg(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szTalker)
			local szText = szMsg
			if bRich then
				szText = GetPureText(szMsg)
			else
				szMsg = GetFormatText(szMsg, nFont, r, g, b)
			end
			if MY_ChatLog.bBlockWords
			and MY_Chat and MY_Chat.MatchBlockWord
			and MY_Chat.MatchBlockWord(szText, szChannel, false) then
				return
			end
			-- filters
			if szChannel == "MSG_GUILD" then
				if MY_ChatLog.bIgnoreTongOnlineMsg and szText:find(TONG_ONLINE_MSG) then
					return
				end
				if MY_ChatLog.bIgnoreTongMemberLogMsg and (
					szText:find(TONG_MEMBER_LOGIN_MSG) or szText:find(TONG_MEMBER_LOGOUT_MSG)
				) then
					return
				end
			end
			-- generate rec
			local hash, time, talker, text, msg
			time   = GetCurrentTime()
			msg    = AnsiToUTF8(szMsg)
			text   = AnsiToUTF8(szText)
			hash   = GetStringCRC(msg)
			talker = AnsiToUTF8(szTalker)
			DB_W:ClearBindings()
			DB_W:BindAll(hash, CHANNELS_R[szChannel], time, talker, text, msg)
			DB_W:Execute()
		end
		MY.RegisterMsgMonitor('MY_ChatLog', OnMsg, t)
	end
end
MY.RegisterInit("MY_ChatLog_Init", InitDB)

local function ReleaseDB()
	if not DB then
		return
	end
	DB:Release()
end
MY.RegisterExit("MY_Chat_Release", ReleaseDB)

function MY_ChatLog.Open()
	if not DB then
		return MY.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L['MY_ChatLog'])
	end
	Wnd.OpenWindow(SZ_INI, "MY_ChatLog"):BringToTop()
end

function MY_ChatLog.Close()
	Wnd.CloseWindow("MY_ChatLog")
end

function MY_ChatLog.OnFrameCreate()
	local container = this:Lookup("Window_Main/WndScroll_ChatChanel/WndContainer_ChatChanel")
	container:Clear()
	for nChannel, szChannel in pairs(CHANNELS) do
		local wnd = container:AppendContentFromIni(SZ_INI, "Wnd_ChatChannel")
		wnd.nChannel = nChannel
		wnd:Lookup("CheckBox_ChatChannel"):Check(true, WNDEVENT_FIRETYPE.PREVENT)
		wnd:Lookup("CheckBox_ChatChannel", "Text_ChatChannel"):SetText(g_tStrings.tChannelName[szChannel])
		wnd:Lookup("CheckBox_ChatChannel", "Text_ChatChannel"):SetFontColor(GetMsgFontColor(szChannel))
	end
	container:FormatAllContentPos()
	
	local handle = this:Lookup("Window_Main/Wnd_Index", "Handle_IndexesOuter/Handle_Indexes")
	handle:Clear()
	for i = 1, PAGE_DISPLAY do
		handle:AppendItemFromIni(SZ_INI, "Handle_Index")
	end
	handle:FormatAllItemPos()
	
	local handle = this:Lookup("Window_Main/WndScroll_ChatLog", "Handle_ChatLogs")
	handle:Clear()
	for i = 1, PAGE_AMOUNT do
		handle:AppendItemFromIni(SZ_INI, "Handle_ChatLog")
	end
	handle:FormatAllItemPos()
	
	this:Lookup("", "Text_Title"):SetText(_L['MY - MY_ChatLog'])
	this:Lookup("Window_Main/Wnd_Search/Edit_Search"):SetPlaceholderText(_L['press enter to search ...'])
	
	this.nCurrentPage = 1
	MY_ChatLog.UpdatePage(this)
	this:RegisterEvent("ON_MY_MOSAICS_RESET")
end

function MY_ChatLog.OnEvent(event)
	if event == "ON_MY_MOSAICS_RESET" then
		MY_ChatLog.UpdatePage(this)
	end
end

function MY_ChatLog.OnLButtonClick()
	local name = this:GetName()
	if name == "Btn_Close" then
		MY_ChatLog.Close()
	end
end

function MY_ChatLog.OnCheckBoxCheck()
	MY_ChatLog.UpdatePage(this:GetRoot())
end

function MY_ChatLog.OnCheckBoxUncheck()
	MY_ChatLog.UpdatePage(this:GetRoot())
end

function MY_ChatLog.OnItemLButtonClick()
	local name = this:GetName()
	if name == "Handle_Index" then
		this:GetRoot().nCurrentPage = this.nPage
		MY_ChatLog.UpdatePage(this:GetRoot())
	end
end

function MY_ChatLog.OnEditSpecialKeyDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == "Enter" then
		if name == "WndEdit_Index" then
			frame.nCurrentPage = tonumber(this:GetText()) or frame.nCurrentPage
		end
		MY_ChatLog.UpdatePage(this:GetRoot())
		return 1
	end
end

function MY_ChatLog.OnItemRButtonClick()
	local this = this
	local name = this:GetName()
	if name == "Handle_ChatLog" then
		local menu = {
			{
				szOption = _L["delete record"],
				fnAction = function()
					DB_D:ClearBindings()
					DB_D:BindAll(this.hash, this.time)
					DB_D:Execute()
					MY_ChatLog.UpdatePage(this:GetRoot())
				end,
			}, {
				szOption = _L["copy this record"],
				fnAction = function()
					XGUI.OpenTextEditor(UTF8ToAnsi(this.text))
				end,
			}
		}
		PopupMenu(menu)
	end
end

function MY_ChatLog.UpdatePage(frame)
	local container = frame:Lookup("Window_Main/WndScroll_ChatChanel/WndContainer_ChatChanel")
	local wheres = {}
	local values = {}
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:Lookup("CheckBox_ChatChannel"):IsCheckBoxChecked() then
			tinsert(wheres, "channel = ?")
			tinsert(values, wnd.nChannel)
		end
	end
	local sql  = "SELECT * FROM ChatLog"
	local where = ""
	local sqlc = "SELECT count(*) AS count FROM ChatLog"
	if #wheres > 0 then
		where = where .. " (" .. tconcat(wheres, " OR ") .. ")"
	else
		where = " 1 = 0"
	end
	local search = frame:Lookup("Window_Main/Wnd_Search/Edit_Search"):GetText()
	if search ~= "" then
		if #where > 0 then
			where = where .. " AND"
		end
		where = where .. " (talker LIKE ? OR text LIKE ?)"
		tinsert(values, AnsiToUTF8("%" .. search .. "%"))
		tinsert(values, AnsiToUTF8("%" .. search .. "%"))
	end
	if #where > 0 then
		sql  = sql  .. " WHERE" .. where
		sqlc = sqlc .. " WHERE" .. where
	end
	sql  = sql  .. " ORDER BY time ASC"
	sqlc = sqlc .. " ORDER BY time ASC"
	
	local DB_RC = DB:Prepare(sqlc)
	DB_RC:BindAll(unpack(values))
	local data = DB_RC:GetNext()
	local nPageCount = mceil(data.count / PAGE_AMOUNT)
	frame.nCurrentPage = mmin(frame.nCurrentPage, nPageCount)
	frame:Lookup("Window_Main/Wnd_Index/Wnd_IndexEdit/WndEdit_Index"):SetText(frame.nCurrentPage)
	frame:Lookup("Window_Main/Wnd_Index", "Handle_IndexCount/Text_IndexCount"):SprintfText(_L["total %d pages"], nPageCount)
	
	local hOuter = frame:Lookup("Window_Main/Wnd_Index", "Handle_IndexesOuter")
	local handle = hOuter:Lookup("Handle_Indexes")
	if nPageCount <= PAGE_DISPLAY then
		for i = 0, PAGE_DISPLAY - 1 do
			local hItem = handle:Lookup(i)
			hItem.nPage = i + 1
			hItem:Lookup("Text_Index"):SetText(i + 1)
			hItem:Lookup("Text_IndexUnderline"):SetVisible(i + 1 == frame.nCurrentPage)
			hItem:SetVisible(i < nPageCount)
		end
	else
		local hItem = handle:Lookup(0)
		hItem.nPage = 1
		hItem:Lookup("Text_Index"):SetText(1)
		hItem:Lookup("Text_IndexUnderline"):SetVisible(1 == frame.nCurrentPage)
		hItem:Show()
		
		local hItem = handle:Lookup(PAGE_DISPLAY - 1)
		hItem.nPage = nPageCount
		hItem:Lookup("Text_Index"):SetText(nPageCount)
		hItem:Lookup("Text_IndexUnderline"):SetVisible(nPageCount == frame.nCurrentPage)
		hItem:Show()
		
		local nStartPage
		if frame.nCurrentPage + mceil((PAGE_DISPLAY - 2) / 2) > nPageCount then
			nStartPage = nPageCount - (PAGE_DISPLAY - 2)
		elseif frame.nCurrentPage - mceil((PAGE_DISPLAY - 2) / 2) < 2 then
			nStartPage = 2
		else
			nStartPage = frame.nCurrentPage - mceil((PAGE_DISPLAY - 2) / 2)
		end
		for i = 1, PAGE_DISPLAY - 2 do
			local hItem = handle:Lookup(i)
			hItem.nPage = nStartPage + i - 1
			hItem:Lookup("Text_Index"):SetText(nStartPage + i - 1)
			hItem:Lookup("Text_IndexUnderline"):SetVisible(nStartPage + i - 1 == frame.nCurrentPage)
			hItem:SetVisible(true)
		end
	end
	handle:SetSize(hOuter:GetSize())
	handle:FormatAllItemPos()
	handle:SetSizeByAllItemSize()
	hOuter:FormatAllItemPos()
	
	sql = sql .. " LIMIT " .. PAGE_AMOUNT .. " OFFSET " .. ((frame.nCurrentPage - 1) * PAGE_AMOUNT)
	local DB_R = DB:Prepare(sql)
	DB_R:BindAll(unpack(values))
	local data = DB_R:GetAll()
	local handle = frame:Lookup("Window_Main/WndScroll_ChatLog", "Handle_ChatLogs")
	for i = 1, PAGE_AMOUNT do
		local rec = data[i]
		local hItem = handle:Lookup(i - 1)
		if rec then
			local f = GetMsgFont(CHANNELS[rec.channel])
			local r, g, b = GetMsgFontColor(CHANNELS[rec.channel])
			local h = hItem:Lookup("Handle_ChatLog_Msg")
			h:Clear()
			h:AppendItemFromString(MY.GetTimeLinkText({r=r, g=g, b=b, f=f, s='[yyyy/MM/dd][hh:mm:ss]'}, rec.time))
			local nCount = h:GetItemCount()
			h:AppendItemFromString(UTF8ToAnsi(rec.msg))
			if MY_Farbnamen.Render then
				for i = nCount, h:GetItemCount() - 1 do
					MY_Farbnamen.Render(h:Lookup(i))
				end
			end
			if MY_ChatMosaics and MY_ChatMosaics.Mosaics then
				MY_ChatMosaics.Mosaics(h)
			end
			h:FormatAllItemPos()
			local nW, nH = h:GetAllItemSize()
			h:SetH(nH)
			hItem:Lookup("Shadow_ChatLogBg"):SetH(nH + 3)
			hItem:SetH(nH + 3)
			hItem.hash = rec.hash
			hItem.time = rec.time
			hItem.text = rec.text
			hItem:Show()
		else
			hItem:Hide()
		end
	end
	handle:FormatAllItemPos()
end

------------------------------------------------------------------------------------------------------
-- 数据导出
------------------------------------------------------------------------------------------------------
local function htmlEncode(html)
	return html
	:gsub("&", "&amp;")
	:gsub(" ", "&ensp;")
	:gsub("<", "&lt;")
	:gsub(">", "&gt;")
	:gsub('"', "&quot;")
	:gsub("\n", "<br>")
end

local function getHeader()
	local szHeader = [[<!DOCTYPE html>
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=]]
	.. ((MY.GetLang() == "zhcn" and "GBK") or "UTF-8") .. [[" />
<style>
*{font-size: 12px}
a{line-height: 16px}
input, button, select, textarea {outline: none}
body{background-color: #000; margin: 8px 8px 45px 8px}
#browserWarning{background-color: #f00; font-weight: 800; color:#fff; padding: 8px; position: fixed; opacity: 0.92; top: 0; left: 0; right: 0}
.channel{color: #fff; font-weight: 800; font-size: 32px; padding: 0; margin: 30px 0 0 0}
.date{color: #fff; font-weight: 800; font-size: 24px; padding: 0; margin: 0}
a.content{font-family: cursive}
span.emotion_44{width:21px; height: 21px; display: inline-block; background-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAO/SURBVDhPnZT7U4xRGMfff4GftEVKYsLutkVETKmsdrtY9QMNuTRDpVZS2Fw2utjcL1NSYaaUa5gRFSK5mzFukzHGYAbjOmTC7tv79vWcs2+bS7k9M985u+c953PO85zneYS+zBQThYChKvj7ejg1zDnqfN1hipkKZdnfmXFKKLRD3aHXecMyPQh1q+PRVr4Qj2qycKZkAfLmRyJitA80tCaa1irb+rZR3m4I9huIgsQQvKxKxZemXEgNuZAvrIPcWoSuqzbYH5bhcZMV6fHjETjcA6OGuPUNHuk9AJM1g3E4IxId9TnwcuvHJV0phHQuD9L5fODFPtf8mwcV2JIVg4kab6h9VL+Co/VhGOOrQlnSBHQcWeyE3SqG1JKHzoaVkC4WQr68HniyGUAb6QFf86FtC0qzTRhL3kVPCfsRrKGTUsNH4lX5PDiOLoZ0yQrpzCoOlW9uoLGAu4/2cgK2kC6QGiG9rsCr5gKkm8ZBTTFWcIIQH2dAyHAV7q+d5nLNJVV/Psq3NkO+RNC3lb+s8VHWBNFtE4jFJGgolsmhfnheZKTTfzS2WL6/3XlTcr/r3iYC71S+Oo2teXfdhjlTAzDCawCXwNJnx8xgvC9Jgrg7EfZ98yAeSoGjLt3p+lkrZHp1+cp6GosJbkPXnXwuudWKLjpUvJiPvctMPM2YBH9K5pZsPeyls2HfkwzHQTPE49nobFrNX12+pgC/1zUGL+r5T6G5uyfNVSgcejs3CvYSgu4laFUKxBM5Lih3/Xtgb2otxNOaJdBR1TFxaIM5nG6ahK9lc+HYnwbxSCbE+hWQmtf+GcpCQ/FuLp7dc9MAHzdYo3X4vG0m7LuSYK+cD8eBDIinLehsZGn1E5QgbI6L8pd707gS62ZNhD+xmARTrAF69SA8sSX0hKA6tee2lJ+uh6L4MggrCHYgP5QOf1ebAUPgEGo0UVw8V1kGbEoYg090WwcVAH+wbvApBawAxZPLac7CH1Oi2H+py8LGWZN4E+KwbouibhOh8UR9Wjjat82Ao8IJ7jyYDrF6AaRTOUplkavHsyAezaRvZnRUL8KxpQZM8POAobeOFUClatB5oSY5BB+2Unx3z4FtSZyrcrply4ylmC/CRwoVaz562qP+XafS0MfgYSqsMGjxzGbiEPshCkMtpVkNSzUzn3tJYcqbFohJIzzA+oayvW8zUsdiVRHq5w6LUYvalDDcsBhxb00c6s2RyE8Igl7ryWPYq8u/s+nUGNTUF/xpM8tlLvqtJW9MscoL/6v9P1QQvgHonm5Hx/sAiwAAAABJRU5ErkJggg==")}
#controls{background-color: #fff; height: 25px; position: fixed; opacity: 0.92; bottom: 0; left: 0; right: 0}
#mosaics{width: 200px;height: 20px}
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
<div id="controls" style="display:none">
	<input type="range" id="mosaics" min="0" max="200" value="0">
	<script type="text/javascript">
	(function() {
		var timerid, blurRadius;
		var setMosaicHandler = function() {
			var filter = "blur(" + blurRadius + ")";console.log(filter);
			var eles = document.getElementsByClassName("namelink");
			for(i = eles.length - 1; i >= 0; i--) {
				eles[i].style["filter"] = filter;
				eles[i].style["-o-filter"] = filter;
				eles[i].style["-ms-filter"] = filter;
				eles[i].style["-moz-filter"] = filter;
				eles[i].style["-webkit-filter"] = filter;
			}
			timerid = null;
		}
		var setMosaic = function(radius) {
			if (timerid)
				clearTimeout(timerid);
			blurRadius = radius;
			timerid = setTimeout(setMosaicHandler, 50);
		}
		document.getElementById("mosaics").oninput = function() {
			setMosaic((this.value / 100 + 0.5) + "px");
		}
	})();
	</script>
</div>
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
		
		if (!Sys.chrome && !Sys.firefox) {
			document.getElementById("browserWarning").innerHTML = "<a>WARNING: Please use </a><a href='http://www.google.cn/chrome/browser/desktop/index.html' style='color: yellow;'>Chrome</a></a> to browse this page!!!</a>";
		} else {
			document.getElementById("controls").style["display"] = null;
			document.getElementById("browserWarning").style["display"] = "none";
		}
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
				text = htmlEncode(text)
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
				tinsert(t, '<span class="')
				tinsert(t, name)
				tinsert(t, '"></span>')
			end
		end
	end
	return tconcat(t)
end

local l_bExporting
function MY_ChatLog.ExportConfirm()
	if l_bExporting then
		return MY.Sysmsg({_L['Already exporting, please wait.']})
	end
	local ui = XGUI.CreateFrame("MY_ChatLog_Export", {
		simple = true, esc = true, close = true, w = 140,
		level = "Normal1", text = _L['export chatlog'], alpha = 233,
	})
	local btnSure
	local tChannels = {}
	local x, y = 10, 10
	for nChannel, szChannel in pairs(CHANNELS) do
		ui:append("WndCheckBox", {
			x = x, y = y, w = 100,
			text = g_tStrings.tChannelName[szChannel],
			checked = true,
			oncheck = function(checked)
				tChannels[nChannel] = checked
				if checked then
					btnSure:enable(true)
				else
					btnSure:enable(false)
					for nChannel, szChannel in pairs(CHANNELS) do
						if tChannels[nChannel] then
							btnSure:enable(true)
							break
						end
					end
				end
			end,
		})
		y = y + 30
		tChannels[nChannel] = true
	end
	y = y + 10
	
	btnSure = ui:append("WndButton", {
		x = x, y = y, w = 120,
		text = _L['export chatlog'],
		onclick = function()
			local aChannels = {}
			for nChannel, szChannel in pairs(CHANNELS) do
				if tChannels[nChannel] then
					table.insert(aChannels, nChannel)
				end
			end
			MY_ChatLog.Export(
				MY.GetLUADataPath("export/ChatLog/$name@$server@" .. MY.FormatTime("yyyyMMddhhmmss") .. ".html"),
				aChannels, 10,
				function(title, progress)
					OutputMessage("MSG_ANNOUNCE_YELLOW", _L("Exporting chatlog: %s, %.2f%%.", title, progress * 100))
				end
			)
			ui:remove()
		end,
	}, true)
	y = y + 30
	ui:height(y + 50)
	ui:anchor({s = "CENTER", r = "CENTER", x = 0, y = 0})
end

function MY_ChatLog.Export(szExportFile, aChannels, nPerSec, onProgress)
	if l_bExporting then
		return MY.Sysmsg({_L['Already exporting, please wait.']})
	end
	if not DB then
		return MY.Sysmsg({_L['Cannot connect to database!!!']})
	end
	if onProgress then
		onProgress(_L["preparing"], 0)
	end
	local status =  Log(szExportFile, getHeader(), "clear")
	if status ~= "SUCCEED" then
		return MY.Sysmsg({_L("Error: open file error %s [%s]", szExportFile, status)})
	end
	l_bExporting = true
	
	local sql  = "SELECT * FROM ChatLog"
	local sqlc = "SELECT count(*) AS count FROM ChatLog"
	local wheres = {}
	local values = {}
	for _, nChannel in ipairs(aChannels) do
		tinsert(wheres, "channel = ?")
		tinsert(values, nChannel)
	end
	if #wheres > 0 then
		sql  = sql  .. " WHERE (" .. tconcat(wheres, " OR ") .. ")"
		sqlc = sqlc .. " WHERE (" .. tconcat(wheres, " OR ") .. ")"
	end
	sql  = sql  .. " ORDER BY time ASC"
	sqlc = sqlc .. " ORDER BY time ASC"
	local DB_RC = DB:Prepare(sqlc)
	DB_RC:BindAll(unpack(values))
	local data = DB_RC:GetNext()
	local nPageCount = mceil(data.count / EXPORT_SLICE)
	
	sql = sql .. " LIMIT " .. EXPORT_SLICE .. " OFFSET ?"
	local nIndex = #values + 1
	local DB_R = DB:Prepare(sql)
	local i = 0
	local function Export()
		if i > nPageCount then
			l_bExporting = false
			Log(szExportFile, getFooter(), "close")
			if onProgress then
				onProgress(_L['Export succeed'], 1)
			end
			local szFile = GetRootPath() .. szExportFile:gsub("/", "\\")
			MY.Alert(_L('Chatlog export succeed, file saved as %s', szFile))
			MY.Sysmsg({_L('Chatlog export succeed, file saved as %s', szFile)})
			return 0
		end
		values[nIndex] = i * EXPORT_SLICE
		DB_R:ClearBindings()
		DB_R:BindAll(unpack(values))
		local data = DB_R:GetAll()
		for i, rec in ipairs(data) do
			local f = GetMsgFont(CHANNELS[rec.channel])
			local r, g, b = GetMsgFontColor(CHANNELS[rec.channel])
			Log(szExportFile, convertXml2Html(MY.GetTimeLinkText({r=r, g=g, b=b, f=f, s='[yyyy/MM/dd][hh:mm:ss]'}, rec.time)))
			Log(szExportFile, convertXml2Html(UTF8ToAnsi(rec.msg)))
		end
		if onProgress then
			onProgress(_L['exporting'], i / nPageCount)
		end
		i = i + 1
	end
	MY.BreatheCall("MY_ChatLog_Export", Export)
end

------------------------------------------------------------------------------------------------------
-- 设置界面绘制
------------------------------------------------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 50, 50
	local dy = 40
	local wr = 200
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr,
		text = _L['filter tong member log message'],
		checked = MY_ChatLog.bIgnoreTongMemberLogMsg,
		oncheck = function(bChecked)
			MY_ChatLog.bIgnoreTongMemberLogMsg = bChecked
		end
	})
	y = y + dy
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = wr,
		text = _L['filter tong online message'],
		checked = MY_ChatLog.bIgnoreTongOnlineMsg,
		oncheck = function(bChecked)
			MY_ChatLog.bIgnoreTongOnlineMsg = bChecked
		end
	})
	y = y + dy
	
	if MY_Chat then
		ui:append("WndCheckBox", {
			x = x, y = y, w = wr,
			text = _L['hide blockwords'],
			checked = MY_ChatLog.bBlockWords,
			oncheck = function(bChecked)
				MY_ChatLog.bBlockWords = bChecked
			end
		})
		ui:append("WndButton", {
			x = x + 200, y = y, w = 80,
			text = _L["edit"],
			onclick = function()
				MY.SwitchTab("MY_Chat_Filter")
			end,
		})
		y = y + dy
	end
	
	ui:append("WndButton", {
		x = x, y = y, w = 150,
		text = _L["export chatlog"],
		onclick = function()
			MY_ChatLog.ExportConfirm()
		end,
	})
	y = y + dy
	
	ui:append("WndButton", {
		x = x, y = y, w = 150,
		text = _L["open chatlog"],
		onclick = function()
			MY_ChatLog.Open()
		end,
	})
	y = y + dy
end
MY.RegisterPanel( "ChatLog", _L["chat log"], _L['Chat'], "ui/Image/button/SystemButton.UITex|43", {255,127,0,200}, PS)
