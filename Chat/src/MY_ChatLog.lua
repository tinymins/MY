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

function _C.OnMsg(szMsg, szChannel, nFont, bRich, r, g, b)
	if not bRich then
		szMsg = GetFormatText(szMsg, nil, r, g, b)
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
	Log = MY.Json.Decode(MY.LoadUserData('cache/CHAT_LOG/log')) or {
		nMax       = 50,
		MSG_GUILD  = {},
		MSG_WHISPER= {},
		MSG_TEAM   = {},
		MSG_FRIEND = {},
		Active     = 'MSG_WHISPER',
	}
	RegisterMsgMonitor(_C.OnTongMsg  , { 'MSG_GUILD', 'MSG_GUILD_ALLIANCE' })
	RegisterMsgMonitor(_C.OnWisperMsg, { 'MSG_WHISPER' })
	RegisterMsgMonitor(_C.OnRaidMsg  , { 'MSG_TEAM', 'MSG_GROUP' })
	RegisterMsgMonitor(_C.OnFriendMsg, { 'MSG_FRIEND' })
end)

MY.RegisterExit(function()
	MY.SaveUserData('cache/CHAT_LOG/log', MY.Json.Encode(Log))
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
	  :pos(x + 400, y - 3):width(120)
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
end

MY.RegisterPanel( "ChatLog", _L["chat log"], _L['General'], "ui/Image/button/SystemButton.UITex|43", {255,127,0,200}, {
	OnPanelActive = _C.OnPanelActive,
	OnPanelDeactive = function()
		_C.uiLog = nil
	end
})
