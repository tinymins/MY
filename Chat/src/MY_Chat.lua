--------------------------------------------
-- @Desc  : 聊天辅助
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-09-22 12:55:45
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Chat/lang/")
MY_Chat = {}
MY_Chat.bChatCopy = true
MY_Chat.bBlockWords = true
MY_Chat.tBlockWords = {}
MY_Chat.bChatTime = true
MY_Chat.eChatTime = "HOUR_MIN_SEC"
MY_Chat.bChatCopyAlwaysShowMask = false
MY_Chat.bChatCopyAlwaysWhite = false
MY_Chat.bChatCopyNoCopySysmsg = false
MY_Chat.bAlertBeforeClear = true
RegisterCustomData("MY_Chat.bChatCopy")
RegisterCustomData("MY_Chat.bBlockWords")
RegisterCustomData("MY_Chat.bChatTime")
RegisterCustomData("MY_Chat.eChatTime")
RegisterCustomData("MY_Chat.bChatCopyAlwaysShowMask")
RegisterCustomData("MY_Chat.bChatCopyAlwaysWhite")
RegisterCustomData("MY_Chat.bChatCopyNoCopySysmsg")
RegisterCustomData("MY_Chat.nVersion")

local function LoadBlockWords()
	local nVersion = MY.LoadLUAData('config/MY_CHAT/blockwords.$lang.ver.jx3dat') or 0
	MY_Chat.tBlockWords = MY.LoadLUAData('config/MY_CHAT/blockwords.$lang.jx3dat') or MY_Chat.tBlockWords
	for i, bw in ipairs(MY_Chat.tBlockWords) do
		if type(bw) == "string" then
			MY_Chat.tBlockWords[i] = {bw, {ALL = true}, true, true}
		end
	end
	if nVersion == 0 then
		table.insert(MY_Chat.tBlockWords, {"166121867", {ALL = true}, false, false})
	end
end

local function SaveBlockWords()
	MY.SaveLUAData('config/MY_CHAT/blockwords.$lang.ver.jx3dat', 1)
	MY.SaveLUAData('config/MY_CHAT/blockwords.$lang.jx3dat', MY_Chat.tBlockWords)
	MY.StorageData("MY_CHAT_BLOCKWORD", MY_Chat.tBlockWords)
end

MY.RegisterEvent("MY_PRIVATE_STORAGE_UPDATE", function()
	if arg0 == "MY_CHAT_BLOCKWORD" then
		MY_Chat.tBlockWords = arg1
	end
end)
MY.RegisterInit('MY_CHAT_BW', LoadBlockWords)

local tNoneSpaceBlockWords = {}
function MY_Chat.MatchBlockWord(szMsg, szChannel, bRichText)
	if bRichText then
		szMsg = GetPureText(szMsg)
	end
	if szChannel then
		szMsg = "[" .. g_tStrings.tChannelName[szChannel] .. "]" .. szMsg
	end
	for _, bw in ipairs(MY_Chat.tBlockWords) do
		if bw[2].ALL ~= bw[2][szChannel]
		and MY.String.SimpleMatch(szMsg, bw[1], false, not bw[4], bw[3]) then
			return true
		end
	end
end

-- hook chat panel
MY.HookChatPanel("MY_Chat", function(h, szChannel, szMsg, dwTime, nR, nG, nB)
	-- chat filter
	if MY_Chat.bBlockWords and MY_Chat.MatchBlockWord(szMsg, szChannel, true) then
		return ""
	end
	return szMsg, h:GetItemCount()
end, function(h, i, szChannel, szMsg, dwTime, nR, nG, nB)
	if szMsg and i and h:GetItemCount() > i and (MY_Chat.bChatTime or MY_Chat.bChatCopy) then
		-- chat time
		-- check if timestrap can insert
		if MY_Chat.bChatCopyNoCopySysmsg and szChannel == "SYS_MSG" then
			return
		end
		-- create timestrap text
		local szTime = ""
		if MY_Chat.bChatCopy and (MY_Chat.bChatCopyAlwaysShowMask or not MY_Chat.bChatTime) then
			local _r, _g, _b = nR, nG, nB
			if MY_Chat.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = MY.Chat.GetCopyLinkText(_L[" * "], { r = _r, g = _g, b = _b })
		elseif MY_Chat.bChatCopyAlwaysWhite then
			nR, nG, nB = 255, 255, 255
		end
		if MY_Chat.bChatTime then
			if MY_Chat.eChatTime == "HOUR_MIN_SEC" then
				szTime = szTime .. MY.Chat.GetTimeLinkText({ r = nR, g = nG, b = nB, f = 10, s = "[hh:mm:ss]"}, dwTime)
			else
				szTime = szTime .. MY.Chat.GetTimeLinkText({ r = nR, g = nG, b = nB, f = 10, s = "[hh:mm]"}, dwTime)
			end
		end
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end)

local m_aBlockWordsChannels = {
	"MSG_SYS", "MSG_NORMAL", "MSG_PARTY", "MSG_TEAM", "MSG_BATTLE_FILED",
	"MSG_FRIEND", "MSG_WHISPER", "MSG_GROUP", "MSG_GUILD", "MSG_GUILD_ALLIANCE",
	"MSG_MAP", "MSG_SCHOOL", "MSG_WORLD", "MSG_CAMP", "MSG_SEEK_MENTOR",
}
local function Chn2Str(ch)
	local szAllChannel
	if ch.ALL then
		szAllChannel = _L["All channels"]
	end
	local aText = {}
	for _, szChannel in ipairs(m_aBlockWordsChannels) do
		if ch[szChannel] then
			table.insert(aText, g_tStrings.tChannelName[szChannel])
		end
	end
	local szText = table.concat(aText, ",")
	if szAllChannel then
		if #szText > 0 then
			szAllChannel = szAllChannel .. _L[', except:']
		end
		szText = szAllChannel .. szText
	elseif #aText == 0 then
		szText = _L['disabled']
	end
	return szText
end

local function ChatBlock2Text(szText, tChannel)
	return szText .. " (" .. Chn2Str(tChannel) .. ")"
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 0, 0
	LoadBlockWords()
	
	ui:append("WndCheckBox", "WndCheckBox_Enable"):children("#WndCheckBox_Enable")
	  :pos(x, y):width(70)
	  :text(_L['enable'])
	  :check(MY_Chat.bBlockWords or false)
	  :check(function(bCheck)
	  	MY_Chat.bBlockWords = bCheck
	  end)
	x = x + 70
	
	local edit = ui:append("WndEditBox", "WndEditBox_Keyword"):children("#WndEditBox_Keyword"):pos(x, y):size(w - 160 - x, 25)
	x, y = 0, y + 30
	
	local list = ui:append("WndListBox", "WndListBox_1"):children('#WndListBox_1'):pos(x, y):size(w, h - 30)
	-- 初始化list控件
	for _, v in ipairs(MY_Chat.tBlockWords) do
		list:listbox('insert', ChatBlock2Text(v[1], v[2]), v[1], v)
	end
	list:listbox('onmenu', function(hItem, text, id, data)
		local chns = data[2]
		local menu = {
			szOption = _L['Channels'], {
				szOption = _L['All channels'],
				bCheck = true, bChecked = chns.ALL,
				fnAction = function()
					chns.ALL = not chns.ALL
					XGUI(hItem):text(ChatBlock2Text(id, chns))
					SaveBlockWords()
				end,
			}, MENU_DIVIDER,
		}
		for _, szChannel in ipairs(m_aBlockWordsChannels) do
			table.insert(menu, {
				szOption = g_tStrings.tChannelName[szChannel],
				rgb = GetMsgFontColor(szChannel, true),
				bCheck = true, bChecked = chns[szChannel],
				fnAction = function()
					chns[szChannel] = not chns[szChannel]
					XGUI(hItem):text(ChatBlock2Text(id, chns))
					SaveBlockWords()
				end,
			})
		end
		table.insert(menu, MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['ignore spaces'],
			bCheck = true, bChecked = not data[3],
			fnAction = function()
				data[3] = not data[3]
				SaveBlockWords()
			end,
		})
		table.insert(menu, {
			szOption = _L['ignore enem'],
			bCheck = true, bChecked = not data[4],
			fnAction = function()
				data[4] = not data[4]
				SaveBlockWords()
			end,
		})
		table.insert(menu, MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['delete'],
			fnAction = function()
				list:listbox('delete', text, id)
				LoadBlockWords()
				for i = #MY_Chat.tBlockWords, 1, -1 do
					if MY_Chat.tBlockWords[i][1] == id then
						table.remove(MY_Chat.tBlockWords, i)
					end
				end
				SaveBlockWords()
			end,
		})
		return menu
	end):listbox('onlclick', function(hItem, text, id, data, selected)
		edit:text(id)
	end)
	-- add
	ui:append("WndButton", "WndButton_Add"):children("#WndButton_Add")
	  :pos(w - 160, 0):width(80)
	  :text(_L["add"])
	  :click(function()
	  	local szText = edit:text()
	  	-- 去掉前后空格
	  	szText = (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
	  	-- 验证是否为空
	  	if szText=="" then
	  		return
	  	end
	  	LoadBlockWords()
	  	-- 验证是否重复
	  	for i, v in ipairs(MY_Chat.tBlockWords) do
	  		if v[1] == szText then
	  			return
	  		end
	  	end
	  	-- 加入表
		local bw = {szText, {ALL = true, MSG_WHISPER = true, MSG_TEAM = true, MSG_PARTY = true, MSG_GUILD = true, MSG_GUILD_ALLIANCE = true}, false, false}
	  	table.insert(MY_Chat.tBlockWords, 1, bw)
	  	SaveBlockWords()
	  	-- 更新UI
	  	list:listbox('insert', ChatBlock2Text(bw[1], bw[2]), bw[1], bw, 1)
	  end)
	-- del
	ui:append("WndButton", "WndButton_Del"):children("#WndButton_Del")
	  :pos(w - 80, 0):width(80)
	  :text(_L["delete"])
	  :click(function()
	  	for _, v in ipairs(list:listbox('select', 'selected')) do
	  		list:listbox('delete', v.text, v.id)
	  		LoadBlockWords()
	  		for i = #MY_Chat.tBlockWords, 1, -1 do
	  			if MY_Chat.tBlockWords[i][1] == v.id then
	  				table.remove(MY_Chat.tBlockWords, i)
	  			end
	  		end
	  		SaveBlockWords()
	  	end
	  end)
end
MY.RegisterPanel( "MY_Chat_Filter", _L["chat filter"], _L['Chat'], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, PS)
