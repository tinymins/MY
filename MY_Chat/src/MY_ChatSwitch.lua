--------------------------------------------
-- @Desc  : 聊天频道切换
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-02-08 20:25:53
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Chat/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_Chat/ui/MY_ChatSwitch.ini"
local CD_REFRESH_OFFSET = 7 * 60 * 60 -- 7点更新CD
MY_ChatSwitch = {}
MY_ChatSwitch.aWhisper = {}
MY_ChatSwitch.szAway = nil
MY_ChatSwitch.szBusy = nil
RegisterCustomData("MY_ChatSwitch.szAway")
RegisterCustomData("MY_ChatSwitch.szBusy")

local function UpdateChannelDailyLimit(hRadio, bPlus)
	local me = GetClientPlayer()
	local shaCount = hRadio and hRadio.shaCount
	if not (me and shaCount) then
		return
	end

	local dwPercent = 1
	local info = hRadio.info
	local nChannel = info.channel
	if nChannel then
		local szDate = MY.FormatTime("yyyyMMdd", GetCurrentTime() - CD_REFRESH_OFFSET)
		if MY_ChatSwitch.tChannelCount.szDate ~= szDate then
			MY_ChatSwitch.tChannelCount = {szDate = szDate}
		end
		MY_ChatSwitch.tChannelCount[nChannel] = (MY_ChatSwitch.tChannelCount[nChannel] or 0) + (bPlus and 1 or 0)

		local nDailyCount = MY_ChatSwitch.tChannelCount[nChannel]
		local nDailyLimit = MY.GetChannelDailyLimit(me.nLevel, nChannel)
		if nDailyLimit then
			if nDailyLimit > 0 then
				dwPercent = (nDailyLimit - nDailyCount) / nDailyLimit
				hRadio.szTip = GetFormatText(_L("Today: %d\nDaily limit: %d", nDailyCount, nDailyLimit), nil, 255, 255, 0)
			else
				hRadio.szTip = GetFormatText(_L("Today: %d\nDaily limit: no limitation", nDailyCount), nil, 255, 255, 0)
			end
		end
	end
	XGUI(shaCount):drawCircle(nil, nil, nil, info.color[1], info.color[2], info.color[3], 100, math.pi / 2, math.pi * 2 * dwPercent)
end

local function OnClsCheck()
	local function Cls(bAll)
		for i = 1, 10 do
			local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
			local hCheck = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title")
			if h and (bAll or (hCheck and hCheck:IsCheckBoxChecked())) then
				h:Clear()
				h:FormatAllItemPos()
			end
		end
	end
	if IsCtrlKeyDown() then
		Cls()
	elseif IsAltKeyDown() then
		MessageBox({
			szName = "CLS_CHATPANEL_ALL",
			szMessage = _L["Are you sure you want to clear all message panel?"], {
				szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
					Cls(true)
				end
			}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
		})
	else
		MessageBox({
			szName = "CLS_CHATPANEL",
			szMessage = _L["Are you sure you want to clear current message panel?\nPress CTRL when click can clear without alert.\nPress ALT when click can clear all window."], {
				szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
					Cls()
				end
			}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
		})
	end
	MY.UI(this):check(false)
end

local function OnAwayCheck()
	MY.SwitchChat("/afk")
	Station.Lookup("Lowest2/EditBox"):Show()
	if Station.Lookup("Lowest2/EditBox/Edit_Input"):GetText() == "" then
		Station.Lookup("Lowest2/EditBox/Edit_Input"):InsertText(MY_ChatSwitch.szAway or g_tStrings.STR_AUTO_REPLAY_LEAVE)
		Station.Lookup("Lowest2/EditBox/Edit_Input"):SelectAll()
	end
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
end

local function OnAwayUncheck()
	MY.SwitchChat("/cafk")
end

local function OnAwayTip() return MY_ChatSwitch.szAway or g_tStrings.STR_AUTO_REPLAY_LEAVE end

local function OnBusyCheck()
	MY.SwitchChat("/atr")
	Station.Lookup("Lowest2/EditBox"):Show()
	if Station.Lookup("Lowest2/EditBox/Edit_Input"):GetText() == "" then
		Station.Lookup("Lowest2/EditBox/Edit_Input"):InsertText(MY_ChatSwitch.szBusy or g_tStrings.STR_AUTO_REPLAY_LEAVE)
		Station.Lookup("Lowest2/EditBox/Edit_Input"):SelectAll()
	end
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
end

local function OnBusyUncheck()
	MY.SwitchChat("/catr")
end

local function OnBusyTip() return MY_ChatSwitch.szBusy end

local function OnMosaicsCheck()
	MY_ChatMosaics.bEnabled = true
	MY_ChatMosaics.ResetMosaics()
end

local function OnMosaicsUncheck()
	MY_ChatMosaics.bEnabled = false
	MY_ChatMosaics.ResetMosaics()
end

local function OnWhisperCheck()
	local t = {}
	for i, whisper in ipairs(MY_ChatSwitch.aWhisper) do
		local info = MY_Farbnamen.Get(whisper[1])
		table.insert(t, {
			szOption = whisper[1],
			rgb = info and info.rgb or {202, 126, 255},
			fnAction = function()
				MY.SwitchChat(whisper[1])
				MY.DelayCall(MY.FocusChatBox)
			end,
			szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = "ICON_RIGHTMOST",
			fnClickIcon = function()
				for i = #MY_ChatSwitch.aWhisper, 1, -1 do
					if MY_ChatSwitch.aWhisper[i][1] == whisper[1] then
						table.remove(MY_ChatSwitch.aWhisper, i)
						Wnd.CloseWindow("PopupMenuPanel")
					end
				end
			end,
			fnMouseEnter = function()
				local t = {}
				local today = MY.FormatTime("yyyyMMdd")
				local r, g, b = GetMsgFontColor("MSG_WHISPER")
				for _, v in ipairs(whisper[2]) do
					if type(v) == "string" then
						table.insert(t, v)
					elseif type(v) == "table" then
						if today == MY.FormatTime("yyyyMMdd", v[2]) then
							table.insert(t, MY.GetTimeLinkText({r = r, g = g, b = b, s = "[hh:mm:ss]"}, v[2]) .. v[1])
						else
							table.insert(t, MY.GetTimeLinkText({r = r, g = g, b = b, s = "[M.dd.hh:mm:ss]"}, v[2]) .. v[1])
						end
					end
				end
				local szMsg = table.concat(t, "")
				if MY_Farbnamen then
					szMsg = MY_Farbnamen.Render(szMsg)
				end
				OutputTip(szMsg, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
		})
	end
	local x, y = this:GetAbsPos()
	t.x = x
	t.y = y - #MY_ChatSwitch.aWhisper * 24 - 24 - 20 - 8
	if #t > 0 then
		table.insert(t, 1, MENU_DIVIDER)
		table.insert(t, 1, {
			szOption = g_tStrings.CHANNEL_WHISPER_SIGN,
			rgb = {202, 126, 255},
			fnAction = function()
				MY.SwitchChat(PLAYER_TALK_CHANNEL.WHISPER)
				MY.DelayCall(MY.FocusChatBox)
			end,
		})
		PopupMenu(t)
	else
		MY.SwitchChat(PLAYER_TALK_CHANNEL.WHISPER)
	end
	this:Check(false)
end

local CHANNEL_LIST = {
	{id = "NEAR", title = _L["SAY"     ], head = "/s ", channel = PLAYER_TALK_CHANNEL.NEARBY       , cd = 0 , color = {255, 255, 255}}, --说
	{id = "SENC", title = _L["MAP"     ], head = "/y ", channel = PLAYER_TALK_CHANNEL.SENCE        , cd = 10, color = {255, 126, 126}}, --地
	{id = "WORL", title = _L["WORLD"   ], head = "/h ", channel = PLAYER_TALK_CHANNEL.WORLD        , cd = 60, color = {252, 204, 204}}, --世
	{id = "TEAM", title = _L["PARTY"   ], head = "/p ", channel = PLAYER_TALK_CHANNEL.TEAM         , cd = 0 , color = {140, 178, 253}}, --队
	{id = "RAID", title = _L["TEAM"    ], head = "/t ", channel = PLAYER_TALK_CHANNEL.RAID         , cd = 0 , color = { 73, 168, 241}}, --团
	{id = "BATT", title = _L["BATTLE"  ], head = "/b ", channel = PLAYER_TALK_CHANNEL.BATTLE_FIELD , cd = 0 , color = {255, 126, 126}}, --战
	{id = "TONG", title = _L["FACTION" ], head = "/g ", channel = PLAYER_TALK_CHANNEL.TONG         , cd = 0 , color = {  0, 200,  72}}, --帮
	{id = "FORC", title = _L["SCHOOL"  ], head = "/f ", channel = PLAYER_TALK_CHANNEL.FORCE        , cd = 20, color = {  0, 255, 255}}, --派
	{id = "CAMP", title = _L["CAMP"    ], head = "/c ", channel = PLAYER_TALK_CHANNEL.CAMP         , cd = 30, color = {155, 230,  58}}, --阵
	{id = "FRIE", title = _L["FRIEND"  ], head = "/o ", channel = PLAYER_TALK_CHANNEL.FRIENDS      , cd = 10, color = {241, 114, 183}}, --友
	{id = "TONG", title = _L["ALLIANCE"], head = "/a ", channel = PLAYER_TALK_CHANNEL.TONG_ALLIANCE, cd = 0 , color = {178, 240, 164}}, --盟
	{id = "WHIS", title = _L['WHISPER' ], channel = PLAYER_TALK_CHANNEL.WHISPER, cd = 0, onclick = OnWhisperCheck, color = {202, 126, 255}}, --密
	{id = "CLSC", title = _L['CLS'     ], onclick = OnClsCheck, color = {255, 0, 0}}, --清
	{id = "AWAY", title = _L["AWAY"    ], oncheck = OnAwayCheck, onuncheck = OnAwayUncheck, tip = OnAwayTip, color = {255, 255, 255}}, --离
	{id = "BUSY", title = _L["BUSY"    ], oncheck = OnBusyCheck, onuncheck = OnBusyUncheck, tip = OnBusyTip, color = {255, 255, 255}}, --扰
	{id = "MOSA", title = _L["MOSAICS" ], oncheck = OnMosaicsCheck, onuncheck = OnMosaicsUncheck, color = {255, 255, 255}}, --马
}
local CHANNEL_DICT = {}
local CHANNEL_TITLE = {}
local CHANNEL_CD_TIME = {}
for i, v in ipairs(CHANNEL_LIST) do
	if v.channel then
		CHANNEL_TITLE[v.channel] = v.title
		CHANNEL_CD_TIME[v.channel] = v.cd
	end
	CHANNEL_DICT[v.id] = v
end
local m_tChannelTime = {}

MY_ChatSwitch.tChannelCount = {}
MY_ChatSwitch.bAlertBeforeClear = true
RegisterCustomData("MY_ChatSwitch.aWhisper", 1)
RegisterCustomData("MY_ChatSwitch.tChannelCount")
RegisterCustomData("MY_ChatSwitch.bAlertBeforeClear")

local function OnChannelCheck()
	MY.SwitchChat(this.info.channel)
	Station.Lookup("Lowest2/EditBox"):Show()
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
	this:Check(false)
end

function MY_ChatSwitch.OnFrameCreate()
	this.tRadios = {}
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_SAY")
	this:RegisterEvent("CUSTOM_DATA_LOADED")
	this:EnableDrag(not MY.GetStorage('BoolValues.MY_ChatSwitch_LockPostion'))

	local hContainer = this:Lookup("WndContainer_Radios")
	hContainer:SetW(0xFFFF)
	hContainer:Clear()
	for i, v in ipairs(CHANNEL_LIST) do
		if not MY.GetStorage('BoolValues.MY_ChatSwitch_CH' .. i) then
			local chk, txtTitle, txtCooldown, shaCount
			if v.head then
				chk = hContainer:AppendContentFromIni(INI_PATH, "Wnd_Channel"):Lookup("WndRadioChannel")
				txtTitle = chk:Lookup("", "Text_Channel")
				txtCooldown = chk:Lookup("", "Text_CD")
				shaCount = chk:Lookup("", "Shadow_Count")
				chk.OnCheckBoxCheck = OnChannelCheck
			elseif v.onclick then
				chk = hContainer:AppendContentFromIni(INI_PATH, "Wnd_Channel"):Lookup("WndRadioChannel")
				txtTitle = chk:Lookup("", "Text_Channel")
				txtCooldown = chk:Lookup("", "Text_CD")
				shaCount = chk:Lookup("", "Shadow_Count")
				chk.OnCheckBoxCheck = v.onclick
			else
				chk = hContainer:AppendContentFromIni(INI_PATH, "Wnd_CheckBox"):Lookup("WndCheckBox")
				txtTitle = chk:Lookup("", "Text_CheckBox")
				chk.OnCheckBoxCheck = v.oncheck
				chk.OnCheckBoxUncheck = v.onuncheck
			end
			chk.txtTitle = txtTitle
			chk.txtCooldown = txtCooldown
			chk.shaCount = shaCount
			if v.channel then
				this.tRadios[v.channel] = chk
			end
			if v.tip then
				XGUI(chk):tip(v.tip, MY.Const.UI.Tip.CENTER)
			end
			if txtTitle then
				txtTitle:SetText(v.title)
				txtTitle:SetFontScheme(197)
				txtTitle:SetFontColor(unpack(v.color or {255, 255, 255}))
			end
			if txtCooldown then
				txtCooldown:SetText("")
				txtCooldown:SetFontScheme(197)
				txtCooldown:SetFontColor(unpack(v.color or {255, 255, 255}))
			end
			if shaCount then
				XGUI(shaCount):drawCircle(0, 0, 0)
			end
			chk.info = v
			UpdateChannelDailyLimit(chk)
		end
	end
	hContainer:FormatAllContentPos()
	hContainer:SetSize(hContainer:GetAllContentSize())

	this:Lookup("", "Image_Bar"):SetW(hContainer:GetW() + 35)
	this:SetW(hContainer:GetW() + 60)
	MY_ChatSwitch.UpdateAnchor(this)
end

function MY_ChatSwitch.OnEvent(event)
	if event == "PLAYER_SAY" then
		local szContent, dwTalkerID, nChannel, szName, szMsg = arg0, arg1, arg2, arg3, arg11
		if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
			local t
			for i = #MY_ChatSwitch.aWhisper, 1, -1 do
				if MY_ChatSwitch.aWhisper[i][1] == szName then
					t = table.remove(MY_ChatSwitch.aWhisper, i)
				end
			end
			while #MY_ChatSwitch.aWhisper > 20 do
				table.remove(MY_ChatSwitch.aWhisper, 1)
			end
			if not t then
				t = {szName, {}}
			end
			while #t[2] > 20 do
				table.remove(t[2], 1)
			end
			table.insert(t[2], {szMsg, GetCurrentTime()})
			table.insert(MY_ChatSwitch.aWhisper, t)
		end
		if dwTalkerID ~= UI_GetClientPlayerID() then
			return
		end
		local hRadio = this.tRadios[nChannel]
		if hRadio then
			UpdateChannelDailyLimit(hRadio, true)
			m_tChannelTime[nChannel] = GetCurrentTime()
		end
	elseif event == "UI_SCALED" then
		MY_ChatSwitch.UpdateAnchor(this)
	elseif event == "CUSTOM_DATA_LOADED" then
		if arg0 == "Role" then
			for nChannel, hRadio in pairs(this.tRadios) do
				UpdateChannelDailyLimit(hRadio)
			end
		end
	end
end

function MY_ChatSwitch.OnFrameBreathe()
	for nChannel, nTime in pairs(m_tChannelTime) do
		local nCooldown = (CHANNEL_CD_TIME[nChannel] or 0) - (GetCurrentTime() - nTime)
		if nCooldown <= 0 then
			m_tChannelTime[nChannel] = nil
		end

		local hCheck = this.tRadios[nChannel]
		local txtCooldown = hCheck and hCheck.txtCooldown
		if txtCooldown then
			txtCooldown:SetText(nCooldown > 0 and nCooldown or "")
		end
	end
end

function MY_ChatSwitch.OnMouseEnter()
	if this.szTip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.szTip, 450, {x, y, w, h}, ALW.RIGHT_LEFT_AND_BOTTOM_TOP)
	end
end

function MY_ChatSwitch.OnMouseLeave()
	HideTip()
end

function MY_ChatSwitch.OnLButtonClick()
	local name = this:GetName()
	if name == "Btn_Option" then
		MY.OpenPanel()
		MY.SwitchTab("MY_ChatSwitch")
	end
end

function MY_ChatSwitch.OnFrameDragEnd()
	this:CorrectPos()
	MY.SetStorage('FrameAnchor.MY_ChatSwitch', GetFrameAnchor(this))
end

function MY_ChatSwitch.UpdateAnchor(this)
	local anchor = MY.GetStorage('FrameAnchor.MY_ChatSwitch')
		or { x = 10, y = -60, s = "BOTTOMLEFT", r = "BOTTOMLEFT" }
	this:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	this:CorrectPos()
end

local function OnChatSetAFK()
	if type(arg0) == "table" then
		MY_ChatSwitch.szAway = MY.Chat.StringfyContent(arg0)
	else
		MY_ChatSwitch.szAway = arg0 and tostring(arg0)
	end
end
MY.RegisterEvent("ON_CHAT_SET_AFK", OnChatSetAFK)

local function OnChatSetATR()
	if type(arg0) == "table" then
		MY_ChatSwitch.szBusy = MY.Chat.StringfyContent(arg0):sub(4)
	else
		MY_ChatSwitch.szBusy = arg0 and tostring(arg0)
	end
end
MY.RegisterEvent("ON_CHAT_SET_ATR", OnChatSetATR)

function MY_ChatSwitch.ReInitUI()
	Wnd.CloseWindow("MY_ChatSwitch")
	if not MY.GetStorage('BoolValues.MY_ChatSwitch_DisplayPanel') then
		return
	end
	Wnd.OpenWindow(INI_PATH, "MY_ChatSwitch")
end
MY.RegisterStorageInit('MY_CHAT', MY_ChatSwitch.ReInitUI)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w , h  = ui:size()
	local x0, y0 = 30, 30
	local x , y  = x0, y0
	local deltaX = 25
	local deltaY = 33

	ui:append("WndButton", {
		x = w - x - 80, y = y,
		w = 80, h = 30,
		text = _L["about..."],
		onclick = function() MY.Alert(_L["Mingyi Plugins - Chatpanel\nThis plugin is developed by Zhai YiMing @ derzh.com."]) end,
	})

	ui:append("WndCheckBox", {
		x = x, y = y, w = 250,
		text = _L["display panel"],
		checked = MY.GetStorage('BoolValues.MY_ChatSwitch_DisplayPanel'),
		oncheck = function(bChecked)
			MY.SetStorage('BoolValues.MY_ChatSwitch_DisplayPanel', bChecked)
			MY_ChatSwitch.ReInitUI()
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["lock postion"],
		checked = MY.GetStorage('BoolValues.MY_ChatSwitch_LockPostion'),
		oncheck = function(bChecked)
			MY.SetStorage('BoolValues.MY_ChatSwitch_LockPostion', bChecked)
			MY_ChatSwitch.ReInitUI()
		end,
		isdisable = function()
			return not MY.GetStorage('BoolValues.MY_ChatSwitch_DisplayPanel')
		end,
	})
	y = y + deltaY

	ui:append("WndComboBox", {
		x = x + deltaX, y = y, w = 150, h = 25,
		text = _L['channel setting'],
		menu = function()
			local t = {
				szOption = _L['channel setting'],
				fnDisable = function()
					return not MY.GetStorage('BoolValues.MY_ChatSwitch_DisplayPanel')
				end,
			}
			for i, v in ipairs(CHANNEL_LIST) do
				table.insert(t, {
					szOption = v.title, rgb = v.color,
					bCheck = true, bChecked = not MY.GetStorage('BoolValues.MY_ChatSwitch_CH' .. i),
					fnAction = function()
						MY.SetStorage(
							'BoolValues.MY_ChatSwitch_CH' .. i,
							not MY.GetStorage('BoolValues.MY_ChatSwitch_CH' .. i)
						)
						MY_ChatSwitch.ReInitUI()
					end,
				})
			end
			return t
		end,
		isdisable = function()
			return not MY.GetStorage('BoolValues.MY_ChatSwitch_DisplayPanel')
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x, y = y, w = 250,
		text = _L["team balloon"],
		checked = MY_TeamBalloon.Enable(),
		oncheck = function(bChecked)
			MY_TeamBalloon.Enable(bChecked)
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x, y = y, w = 250,
		text = _L["chat time"],
		checked = MY_ChatCopy.bChatTime,
		oncheck = function(bChecked)
			if bChecked and HM_ToolBox then
				HM_ToolBox.bChatTime = false
			end
			MY_ChatCopy.bChatTime = bChecked
		end,
	})
	y = y + deltaY

	ui:append("WndComboBox", {
		x = x + deltaX, y = y, w = 150,
		text = _L['chat time format'],
		menu = function()
			return {{
				szOption = _L['hh:mm'],
				bMCheck = true,
				bChecked = MY_ChatCopy.eChatTime == "HOUR_MIN",
				fnAction = function()
					MY_ChatCopy.eChatTime = "HOUR_MIN"
				end,
				fnDisable = function()
					return not MY_ChatCopy.bChatTime
				end,
			},{
				szOption = _L['hh:mm:ss'],
				bMCheck = true,
				bChecked = MY_ChatCopy.eChatTime == "HOUR_MIN_SEC",
				fnAction = function()
					MY_ChatCopy.eChatTime = "HOUR_MIN_SEC"
				end,
				fnDisable = function()
					return not MY_ChatCopy.bChatTime
				end,
			}}
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x, y = y, w = 250,
		text = _L["chat copy"],
		checked = MY_ChatCopy.bChatCopy,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopy = bChecked
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["always show *"],
		checked = MY_ChatCopy.bChatCopyAlwaysShowMask,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopyAlwaysShowMask = bChecked
		end,
		isdisable = function()
			return not MY_ChatCopy.bChatCopy
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["always be white"],
		checked = MY_ChatCopy.bChatCopyAlwaysWhite,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopyAlwaysWhite = bChecked
		end,
		isdisable = function()
			return not MY_ChatCopy.bChatCopy
		end,
	})
	y = y + deltaY

	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["hide system msg copy"],
		checked = MY_ChatCopy.bChatCopyNoCopySysmsg,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopyNoCopySysmsg = bChecked
		end,
		isdisable = function()
			return not MY_ChatCopy.bChatCopy
		end,
	})
	y = y + deltaY

	if (MY_Farbnamen and MY_Farbnamen.GetMenu) then
		ui:append("WndComboBox", {
			x = x, y = y, w = 150,
			text = _L['farbnamen'],
			menu = MY_Farbnamen.GetMenu,
		})
		y = y + deltaY
	end
end
MY.RegisterPanel("MY_ChatSwitch", _L["chat helper"], _L['Chat'], "UI/Image/UICommon/ActivePopularize2.UITex|20", {255,255,0,200}, PS)
