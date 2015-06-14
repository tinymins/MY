local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Chat/lang/")
local CHAT_TIME = {
	HOUR_MIN = 1,
	HOUR_MIN_SEC = 2,
}
-- init vars
MY_Chat = MY_Chat or {}
local _Cache = {
	['tChannels'] = {
		{name="Radio_Say",      title=_L["SAY"],      head={string=g_tStrings.HEADER_SHOW_SAY,          code="/s "}, channel=PLAYER_TALK_CHANNEL.NEARBY       , color={255, 255, 255}},--说
		{name="Radio_Map",      title=_L["MAP"],      head={string=g_tStrings.HEADER_SHOW_MAP,          code="/y "}, channel=PLAYER_TALK_CHANNEL.SENCE        , color={255, 126, 126}},--地
		{name="Radio_World",    title=_L["WORLD"],    head={string=g_tStrings.HEADER_SHOW_WORLD,        code="/h "}, channel=PLAYER_TALK_CHANNEL.WORLD        , color={252, 204, 204}},--世
		{name="Radio_Party",    title=_L["PARTY"],    head={string=g_tStrings.HEADER_SHOW_CHAT_PARTY,   code="/p "}, channel=PLAYER_TALK_CHANNEL.TEAM         , color={140, 178, 253}},--队
		{name="Radio_Team",     title=_L["TEAM"],     head={string=g_tStrings.HEADER_SHOW_TEAM,         code="/t "}, channel=PLAYER_TALK_CHANNEL.RAID         , color={ 73, 168, 241}},--团
		{name="Radio_Battle",   title=_L["BATTLE"],   head={string=g_tStrings.HEADER_SHOW_BATTLE_FIELD, code="/b "}, channel=PLAYER_TALK_CHANNEL.BATTLE_FIELD , color={255, 126, 126}},--战
		{name="Radio_Tong",     title=_L["FACTION"],  head={string=g_tStrings.HEADER_SHOW_CHAT_FACTION, code="/g "}, channel=PLAYER_TALK_CHANNEL.TONG         , color={  0, 200,  72}},--帮
		{name="Radio_School",   title=_L["SCHOOL"],   head={string=g_tStrings.HEADER_SHOW_SCHOOL,       code="/f "}, channel=PLAYER_TALK_CHANNEL.FORCE        , color={  0, 255, 255}},--派
		{name="Radio_Camp",     title=_L["CAMP"],     head={string=g_tStrings.HEADER_SHOW_CAMP,         code="/c "}, channel=PLAYER_TALK_CHANNEL.CAMP         , color={155, 230,  58}},--阵
		{name="Radio_Friend",   title=_L["FRIEND"],   head={string=g_tStrings.HEADER_SHOW_FRIEND,       code="/o "}, channel=PLAYER_TALK_CHANNEL.FRIENDS      , color={241, 114, 183}},--友
		{name="Radio_Alliance", title=_L["ALLIANCE"], head={string=g_tStrings.HEADER_SHOW_CHAT_ALLIANCE,code="/a "}, channel=PLAYER_TALK_CHANNEL.TONG_ALLIANCE, color={178, 240, 164}},--盟
	},
}
MY_Chat.bLockPostion = false
MY_Chat.anchor = { x=10, y=-60, s="BOTTOMLEFT", r="BOTTOMLEFT" }
MY_Chat.bEnableBalloon = true
MY_Chat.bChatCopy = true
MY_Chat.bBlockWords = true
MY_Chat.tBlockWords = {}
MY_Chat.bChatTime = true
MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
MY_Chat.bChatCopyAlwaysShowMask = false
MY_Chat.bChatCopyAlwaysWhite = false
MY_Chat.bChatCopyNoCopySysmsg = false
MY_Chat.bDisplayPanel = true    -- 是否显示面板
_Cache.LoadBlockWords = function() MY_Chat.tBlockWords = MY.LoadLUAData('config/MY_CHAT/blockwords.$lang.jx3dat') or MY_Chat.tBlockWords end
_Cache.SaveBlockWords = function() MY.SaveLUAData('config/MY_CHAT/blockwords.$lang.jx3dat', MY_Chat.tBlockWords) end
MY.RegisterInit('MY_CHAT_BW', _Cache.LoadBlockWords)

MY_Chat.tChannel = {
	["Radio_Say"] = true,
	["Radio_Map"] = true,
	["Radio_World"] = true,
	["Radio_Party"] = true,
	["Radio_Team"] = true,
	["Radio_Battle"] = true,
	["Radio_Tong"] = true,
	["Radio_School"] = true,
	["Radio_Camp"] = true,
	["Radio_Friend"] = true,
	["Radio_Alliance"] = true,
	["Check_Away"] = true,
	["Check_Busy"] = true,
}
-- register settings
RegisterCustomData("MY_Chat.anchor")
RegisterCustomData("MY_Chat.bDisplayPanel")
RegisterCustomData("MY_Chat.bLockPostion")
RegisterCustomData("MY_Chat.bEnableBalloon")
RegisterCustomData("MY_Chat.bChatCopy")
RegisterCustomData("MY_Chat.bBlockWords")
RegisterCustomData("MY_Chat.bChatTime")
RegisterCustomData("MY_Chat.nChatTime")
RegisterCustomData("MY_Chat.bChatCopyAlwaysShowMask")
RegisterCustomData("MY_Chat.bChatCopyAlwaysWhite")
RegisterCustomData("MY_Chat.bChatCopyNoCopySysmsg")
for k, _ in pairs(MY_Chat.tChannel) do RegisterCustomData("MY_Chat.tChannel."..k) end

MY_Chat.OnFrameDragEnd = function() this:CorrectPos() MY_Chat.anchor = GetFrameAnchor(this) end

-- open window
MY_Chat.frame = Wnd.OpenWindow(MY.GetAddonInfo().szRoot .. "Chat\\ui\\Chat.ini", "MY_Chat")
-- load settings
MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
MY_Chat.UpdateAnchor = function() MY_Chat.frame:SetPoint(MY_Chat.anchor.s, 0, 0, MY_Chat.anchor.r, MY_Chat.anchor.x, MY_Chat.anchor.y) MY_Chat.frame:CorrectPos() end
MY_Chat.UpdateAnchor()
MY.RegisterEvent( "UI_SCALED", MY_Chat.UpdateAnchor )

--------------------------------------------------------------
-- chat balloon
--------------------------------------------------------------
function MY_Chat.AppendBalloon(dwID, szMsg)
	local handle = MY_Chat.frame:Lookup("", "Handle_TotalBalloon")
	local hBalloon = handle:Lookup("Balloon_" .. dwID)
	if not hBalloon then
		handle:AppendItemFromIni(MY.GetAddonInfo().szRoot .. "Chat\\ui\\Chat.ini", "Handle_Balloon", "Balloon_" .. dwID)
		hBalloon = handle:Lookup(handle:GetItemCount() - 1)
		hBalloon.dwID = dwID
	end
	hBalloon.nTime = GetTime()
	hBalloon.nAlpha = 255
	local hwnd = hBalloon:Lookup("Handle_Content")
	hwnd:Show()
	local r, g, b = GetMsgFontColor("MSG_PARTY")
	-- szMsg = MY_Chat.EmotionPanel_ParseBallonText(szMsg, r, g, b)
	hwnd:Clear()
	hwnd:SetSize(300, 131)
	hwnd:AppendItemFromString(szMsg)
	hwnd:FormatAllItemPos()
	hwnd:SetSizeByAllItemSize()
	MY_Chat.AdjustBalloonSize(hBalloon, hwnd)
	MY_Chat.ShowBalloon(dwID, hBalloon, hwnd)
end

function MY_Chat.ShowBalloon(dwID, hBalloon, hwnd)
	local hWnd = Station.Lookup("Normal/Teammate")
	local x, y, w, h, _
	if hWnd and hWnd:IsVisible() then
		local handle = hWnd:Lookup("", "")
		local nCount = handle:GetItemCount()
		for i = 0, nCount - 1 do
			local hI = handle:Lookup(i)
			if hI.dwID == dwID then
				w, h = hwnd:GetSize()
				x, y = hI:GetAbsPos()
				x, y = x + 205, y - h - 2
			end
		end
	elseif CTM_GetMemberHandle then
		local handle = CTM_GetMemberHandle(dwID)
		if handle then
			_, h = hwnd:GetSize()
			w, _ = handle:GetSize()
			x, y = handle:GetAbsPos()
			x, y = x + w, y - h - 2
		end
	end
	if x and y then
		hBalloon:SetAbsPos(x, y)
		hBalloon:GetRoot():BringToTop()
		MY.UI(hBalloon):alpha(0):fadeIn(500)
	end
	MY.DelayCall("MY_Chat_Balloon_"..dwID, function()
		MY.UI(hBalloon):fadeOut(500)
	end, 5000)
end

function MY_Chat.AdjustBalloonSize(hBalloon, hwnd)
	local w, h = hwnd:GetSize()
	w, h = w + 20, h + 20
	local image1 = hBalloon:Lookup("Image_Bg1")
	image1:SetSize(w, h)

	local image2 = hBalloon:Lookup("Image_Bg2")
	image2:SetRelPos(math.min(w - 16 - 8, 32), h - 4)
	hBalloon:SetSize(10000, 10000)
	hBalloon:FormatAllItemPos()
	hBalloon:SetSizeByAllItemSize()
end

function MY_Chat.OnSay(szMsg, dwID, nChannel)
	local player = GetClientPlayer()
	if player and player.dwID ~= dwID and (
		nChannel == PLAYER_TALK_CHANNEL.TEAM or
		nChannel == PLAYER_TALK_CHANNEL.RAID
	) and player.IsInParty() then
		local hTeam = GetClientTeam()
		if not hTeam then return end
		if hTeam.nGroupNum > 1 then
			return
		end
		local hGroup = hTeam.GetGroupInfo(0)
		for k, v in pairs(hGroup.MemberList) do
			if v == dwID then
				MY_Chat.AppendBalloon(dwID, szMsg, false)
			end
		end
	end
end
MY.RegisterEvent("PLAYER_SAY",function()
	if MY_Chat.bEnableBalloon then
		MY_Chat.OnSay(arg0, arg1, arg2)
	end
end)


MY_Chat.GetMenu = function()
	local t = {
		szOption = _L["chat helper"],
		{
			szOption = _L["about..."],
			fnAction = function()
				local t = {
					szName = "MY_Chat_About",
					szMessage = _L["Mingyi Plugins - Chatpanel\nThis plugin is developed by Zhai YiMing @ derzh.com."],
					{szOption = g_tStrings.STR_HOTKEY_SURE,fnAction = function() end},
				}
				MessageBox(t)
			end,
		}, {
			bDevide = true
		}, {
			szOption = _L["display panel"],
			bCheck = true,
			bChecked = MY_Chat.bDisplayPanel,
			fnAction = function()
				MY_Chat.bDisplayPanel = not MY_Chat.bDisplayPanel
				MY.UI(MY_Chat.frame):toggle(MY_Chat.bDisplayPanel)
			end,
		}, {
			szOption = _L["lock postion"],
			bCheck = true,
			bChecked = MY_Chat.bLockPostion,
			fnAction = function()
				MY_Chat.bLockPostion = not MY_Chat.bLockPostion
				MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
			end,
			fnDisable = function()
				return not MY_Chat.bDisplayPanel
			end,
		}, {
			szOption = _L["team balloon"],
			bCheck = true,
			bChecked = MY_Chat.bEnableBalloon,
			fnAction = function()
				MY_Chat.bEnableBalloon = not MY_Chat.bEnableBalloon
			end
		}, {
			szOption = _L["chat copy"],
			bCheck = true,
			bChecked = MY_Chat.bChatCopy,
			fnAction = function()
				MY_Chat.bChatCopy = not MY_Chat.bChatCopy
			end,
			{
				szOption = _L['always show *'],
				bCheck = true,
				bChecked = MY_Chat.bChatCopyAlwaysShowMask,
				fnAction = function()
					MY_Chat.bChatCopyAlwaysShowMask = not MY_Chat.bChatCopyAlwaysShowMask
				end,
				fnDisable = function()
					return not MY_Chat.bChatCopy
				end,
			}, {
				szOption = _L['always be white'],
				bCheck = true,
				bChecked = MY_Chat.bChatCopyAlwaysWhite,
				fnAction = function()
					MY_Chat.bChatCopyAlwaysWhite = not MY_Chat.bChatCopyAlwaysWhite
				end,
				fnDisable = function()
					return not MY_Chat.bChatCopy
				end,
			}, {
				szOption = _L['hide system msg copy'],
				bCheck = true,
				bChecked = MY_Chat.bChatCopyNoCopySysmsg,
				fnAction = function()
					MY_Chat.bChatCopyNoCopySysmsg = not MY_Chat.bChatCopyNoCopySysmsg
				end,
				fnDisable = function()
					return not MY_Chat.bChatCopy
				end,
			},
		}, {
			szOption = _L["chat filter"],
			bCheck = true,
			bChecked = MY_Chat.bBlockWords,
			fnAction = function()
				MY_Chat.bBlockWords = not MY_Chat.bBlockWords
			end, {
				szOption = _L['keyword manager'],
				fnAction = function()
					MY.OpenPanel()
					MY.SwitchTab('MY_Chat_Filter')
				end,
				fnDisable = function()
					return not MY_Chat.bBlockWords
				end
			},
		},
	}
	if (MY_Farbnamen and MY_Farbnamen.GetMenu) then
		table.insert(t, MY_Farbnamen.GetMenu())
	end
	table.insert(t, {
		szOption = _L["chat time"],
		bCheck = true,
		bChecked = MY_Chat.bChatTime,
		fnAction = function()
			MY_Chat.bChatTime = not MY_Chat.bChatTime
			if MY_Chat.bChatTime and HM_ToolBox then
				HM_ToolBox.bChatTime = false
			end
		end, {
			szOption = _L['hh:mm'],
			bMCheck = true,
			bChecked = MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN,
			fnAction = function()
				MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN
			end,
			fnDisable = function()
				return not MY_Chat.bChatTime
			end,
		},{
			szOption = _L['hh:mm:ss'],
			bMCheck = true,
			bChecked = MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN_SEC,
			fnAction = function()
				MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
			end,
			fnDisable = function()
				return not MY_Chat.bChatTime
			end,
		}
	})
	table.insert(t, { bDevide = true })
	local tChannel = {
		szOption = _L['channel setting'],
		fnDisable = function()
			return not MY_Chat.bDisplayPanel
		end,
	}
	for _, v in ipairs(_Cache.tChannels) do
		table.insert(tChannel, {
			szOption = v.title, bCheck = true, bChecked = MY_Chat.tChannel[v.name], rgb = v.color,
			fnAction = function() MY_Chat.tChannel[v.name] = not MY_Chat.tChannel[v.name] MY_Chat.ReInitUI() end,
		})
	end
	table.insert(tChannel, {
		szOption = _L['AWAY'], bCheck = true, bChecked = MY_Chat.tChannel['Check_Away'],
		fnAction = function() MY_Chat.tChannel['Check_Away'] = not MY_Chat.tChannel['Check_Away'] MY_Chat.ReInitUI() end,
	})
	table.insert(tChannel, {
		szOption = _L['BUSY'], bCheck = true, bChecked = MY_Chat.tChannel['Check_Busy'],
		fnAction = function() MY_Chat.tChannel['Check_Busy'] = not MY_Chat.tChannel['Check_Busy'] MY_Chat.ReInitUI() end,
	})
	table.insert(t, tChannel)
	return t
end
MY.RegisterPlayerAddonMenu( 'MY_Chat', MY_Chat.GetMenu )
MY.RegisterTraceButtonMenu( 'MY_Chat', MY_Chat.GetMenu )
--------------------------------------------------------------
-- reinit ui
--------------------------------------------------------------
MY_Chat.ReInitUI = function()
	MY.UI(MY_Chat.frame):toggle(MY_Chat.bDisplayPanel)
	-- clear
	MY.UI(MY_Chat.frame):find(".WndCheckBox"):remove()
	MY.UI(MY_Chat.frame):find(".WndRadioBox"):remove()
	-- reinit
	local i = 0
	-- init ui
	for _, v in ipairs(_Cache.tChannels) do
		if MY_Chat.tChannel[v.name] then
			i = i + 1
			MY.UI(MY_Chat.frame):append("WndRadioBox", v.name):children("#"..v.name)
			  :pos(i * 30 + 15, 25):width(22)
			  :font(197):color(v.color)
			  :text(v.title)
			  :check(function()
			  	-- Switch Chat Channel Here
			  	MY.SwitchChat(v.channel)
			  	Station.Lookup("Lowest2/EditBox"):Show()
			  	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
			  	MY.UI(this):check(false)
			  end)
			  :find(".Text"):pos(4, -44):size(22, 66)
		end
	end
	
	if MY_Chat.tChannel.Check_Away then
		i = i + 1
		MY.UI(MY_Chat.frame):append("WndCheckBox", "Check_Away"):children("#Check_Away"):width(25):text(_L["AWAY"]):pos(i*30+15,25):check(function()
			MY.SwitchChat("/afk")
			Station.Lookup("Lowest2/EditBox"):Show()
			Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
		end, function()
			MY.SwitchChat("/cafk")
		end):find(".Text"):pos(5,-16):width(25):font(197)
	end
	
	if MY_Chat.tChannel.Check_Busy then
		i = i + 1
		MY.UI(MY_Chat.frame):append("WndCheckBox", "Check_Busy"):children("#Check_Busy"):width(25):text(_L["BUSY"]):pos(i*30+15,25):check(function()
			MY.SwitchChat("/atr")
			Station.Lookup("Lowest2/EditBox"):Show()
			Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
		end, function()
			MY.SwitchChat("/catr")
		end):find(".Text"):pos(5,-16):width(25):font(197)
	end
	
	MY.UI(MY_Chat.frame):find('#Image_Bar'):width(i*30+35)
	MY.UI(MY_Chat.frame):width(60 + i * 30)
end

--------------------------------------------------------------
-- init
--------------------------------------------------------------
MY.RegisterInit('MY_CHAT', function()
	MY_Chat.ReInitUI()
	MY.UI(MY_Chat.frame):children("#Btn_Option"):menu(MY_Chat.GetMenu)
	-- load settings
	MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
end)

-- hook chat panel
MY.HookChatPanel("MY_Chat", function(h, szChannel, szMsg)
	-- chat filter
	if MY_Chat.bBlockWords then
		-- local t = MY.Chat.FormatContent(szMsg)
		-- local szText = ""
		-- for k, v in ipairs(t) do
		-- 	if v.type == "text" then
		-- 		szText = szText .. v.text
		-- 	end
		-- end
		local szText = GetPureText(szMsg)
		for _,szWord in ipairs(MY_Chat.tBlockWords) do
			if MY.String.SimpleMatch(szText, szWord) then
				return ""
			end
		end
	end
	-- save animiate group into name
	if MY_Chat.bChatTime or MY_Chat.bChatCopy then
		szMsg = string.gsub(szMsg, "group=(%d+) </a", "group=%1 name=\"%1\" </a")
	end
	
	return szMsg, h:GetItemCount()
end, function(h, szChannel, szMsg, i)
	if szMsg and #(GetPureText(szMsg)) > 0 and (MY_Chat.bChatTime or MY_Chat.bChatCopy) and i then
		-- chat time
		-- get msg rgb
		local r, g, b = 255, 255, 0
		for j = i, h:GetItemCount() - 1 do
			local h2 = h:Lookup(j)
			if not h2 then
				return
			elseif h2:GetType() == "Text" and h2:GetName():sub(1, 8) ~= 'namelink' then
				r, g, b = h2:GetFontColor()
				break
			end
		end
		
		-- check if timestrap can insert
		if r == 255 and g == 255 and b == 0 and MY_Chat.bChatCopyNoCopySysmsg then
			return
		end
		
		-- create timestrap text
		local szTime = ""
		if MY_Chat.bChatCopy and (MY_Chat.bChatCopyAlwaysShowMask or not MY_Chat.bChatTime) then
			local _r, _g, _b = r, g, b
			if MY_Chat.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = MY.Chat.GetCopyLinkText(_L[" * "], { r = _r, g = _g, b = _b })
		elseif MY_Chat.bChatCopyAlwaysWhite then
			r, g, b = 255, 255, 255
		end
		if MY_Chat.bChatTime then
			if MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN_SEC then
				szTime = szTime .. MY.Chat.GetTimeLinkText({ r = r, g = g, b = b , f = 10, s = "[hh:mm:ss]"})
			else
				szTime = szTime .. MY.Chat.GetTimeLinkText({ r = r, g = g, b = b , f = 10, s = "[hh:mm]"})
			end
		end
		
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end)

MY.RegisterPanel( "MY_Chat_Filter", _L["chat filter"], _L['Chat'],
"UI/Image/Common/Money.UITex|243", {255,255,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 0, 0
	_Cache.LoadBlockWords()
	
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
		list:listbox('insert', v, v)
	end
	list:listbox('onmenu', function(szText, szID)
		return {{
			szOption = _L['delete'],
			fnAction = function()
				list:listbox('delete', szText, szID)
				_Cache.LoadBlockWords()
				for i = #MY_Chat.tBlockWords, 1, -1 do
					if MY_Chat.tBlockWords[i] == szText then
						table.remove(MY_Chat.tBlockWords, i)
					end
				end
				_Cache.SaveBlockWords()
			end,
		}}
	end):listbox('onlclick', function(text, id, data, selected)
		edit:text(text)
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
	  	_Cache.LoadBlockWords()
	  	-- 验证是否重复
	  	for i, v in ipairs(MY_Chat.tBlockWords) do
	  		if v == szText then
	  			return
	  		end
	  	end
	  	-- 加入表
	  	table.insert(MY_Chat.tBlockWords, 1, szText)
	  	_Cache.SaveBlockWords()
	  	-- 更新UI
	  	list:listbox('insert', szText, szText, nil, 1)
	  end)
	-- del
	ui:append("WndButton", "WndButton_Del"):children("#WndButton_Del")
	  :pos(w - 80, 0):width(80)
	  :text(_L["delete"])
	  :click(function()
	  	for _, v in ipairs(list:listbox('select', 'selected')) do
	  		list:listbox('delete', v.text, v.id)
	  		_Cache.LoadBlockWords()
	  		for i = #MY_Chat.tBlockWords, 1, -1 do
	  			if MY_Chat.tBlockWords[i] == v.text then
	  				table.remove(MY_Chat.tBlockWords, i)
	  			end
	  		end
	  		_Cache.SaveBlockWords()
	  	end
	  end)
end})
