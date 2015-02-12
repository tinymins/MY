-- 
-- 聊天记录
-- 记录团队/好友/帮会/密聊 供日后查询
-- 作者：翟一鸣 @ tinymins
-- 网站：ZhaiYiMing.CoM
-- 
local _L  = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Chat/lang/")
local _C  = {}
local Log = {}
local tinsert = table.insert
local tremove = table.remove
MY_ChatLog = MY_ChatLog or {}
MY_ChatLog.bIgnoreTongOnlineMsg    = true -- 帮会上线通知
MY_ChatLog.bIgnoreTongMemberLogMsg = true -- 帮会成员上线下线提示
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')

_C.TongOnlineMsg       = '^' .. MY.String.PatternEscape(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG) .. '$'
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
	szMsg = MY.Chat.GetTimeLinkText({r=r, g=g, b=b, f=nFont, s='[MM/dd|hh:mm:ss]'}) .. szMsg
	szMsg = MY.Chat.RenderLink(szMsg)
	if MY_Farbnamen and MY_Farbnamen.Render then
		szMsg = MY_Farbnamen.Render(szMsg)
	end
	-- save rec
	tinsert(Log[szChannel], szMsg)
	while #Log[szChannel] > Log.nMax do
		tremove(Log[szChannel], 1)
	end
	_C.AppendLog(szChannel, szMsg)
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

MY.RegisterInit(function()
	Log = MY.Json.Decode(MY.LoadUserData('cache/CHAT_LOG/')) or {}
	for k, v in pairs({
		nMax       = 50,
		MSG_GUILD  = {},
		MSG_WHISPER= {},
		MSG_TEAM   = {},
		MSG_FRIEND = {},
		Active     = 'MSG_WHISPER',
	}) do
		if type(Log[k]) ~= type(v) then
			Log[k] = v
		end
	end
	RegisterMsgMonitor(_C.OnTongMsg  , { 'MSG_GUILD', 'MSG_GUILD_ALLIANCE' })
	RegisterMsgMonitor(_C.OnWisperMsg, { 'MSG_WHISPER' })
	RegisterMsgMonitor(_C.OnRaidMsg  , { 'MSG_TEAM', 'MSG_GROUP' })
	RegisterMsgMonitor(_C.OnFriendMsg, { 'MSG_FRIEND' })
end)

MY.RegisterExit(function()
	MY.SaveUserData('cache/CHAT_LOG/', MY.Json.Encode(Log))
end)

function _C.DrawLog()
	if not _C.uiLog then
		return
	end
	
	_C.uiLog:clear()
	for _, szMsg in ipairs(Log[Log.Active]) do
		_C.uiLog:append(szMsg)
	end
end

function _C.AppendLog(szChannel, szMsg)
	if not (_C.uiLog and szChannel == Log.Active) then
		return
	end
	_C.uiLog:append(szMsg)
end

function _C.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 10
	
	_C.uiLog = ui
	  :append('WndScrollBox_Log','WndScrollBox'):children('#WndScrollBox_Log')
	  :pos(20, 35):size(w - 21, h - 40):handleStyle(3)
	
	for i, szChannel in ipairs({
		'MSG_GUILD'  ,
		'MSG_WHISPER',
		'MSG_TEAM'   ,
		'MSG_FRIEND' ,
	}) do
		ui:append('RadioBox_' .. szChannel, 'WndRadioBox'):children('#RadioBox_' .. szChannel)
		  :pos(x + (i - 1) * 100, y):width(90)
		  :text(g_tStrings.tChannelName[szChannel] or '')
		  :check(function(bChecked)
			if bChecked then
				Log.Active = szChannel
			end
			_C.DrawLog()
		  end)
		  :check(Log.Active == szChannel)
	end
	
	ui:append('WndButton_MaxLog', 'WndButton'):children('#WndButton_MaxLog')
	  :pos(w - 26 - 120, y - 3):width(120)
	  :text(_L('Max log: %d', Log.nMax))
	  :click(function()
	  	local me = this
	  	GetUserInputNumber(
	  		Log.nMax,
	  		1000, nil,
	  		function(num)
	  			Log.nMax = num
	  			MY.UI(me):text(_L('Max log: %d', Log.nMax))
	  		end,
	  		function() end,
	  		function() end
	  	)
	  end)
	
	ui:append('Image_Setting','Image'):item('#Image_Setting')
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
