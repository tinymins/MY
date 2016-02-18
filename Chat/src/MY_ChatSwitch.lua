--------------------------------------------
-- @Desc  : 聊天频道切换
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-08-19 10:33:04
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Chat/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "Chat/ui/MY_ChatSwitch.ini"
MY_ChatSwitch = {}
MY_ChatSwitch.tChannel = {}

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
		Station.Lookup("Lowest2/EditBox/Edit_Input"):InsertText(g_tStrings.STR_AUTO_REPLAY_LEAVE)
		Station.Lookup("Lowest2/EditBox/Edit_Input"):SelectAll()
	end
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
end

local function OnAwayUncheck()
	MY.SwitchChat("/cafk")
end

local m_szAfk
local function OnAwayTip() return m_szAfk or g_tStrings.STR_AUTO_REPLAY_LEAVE end

local function OnBusyCheck()
	MY.SwitchChat("/atr")
	Station.Lookup("Lowest2/EditBox"):Show()
	if Station.Lookup("Lowest2/EditBox/Edit_Input"):GetText() == "" then
		Station.Lookup("Lowest2/EditBox/Edit_Input"):InsertText(g_tStrings.STR_AUTO_REPLAY_LEAVE)
		Station.Lookup("Lowest2/EditBox/Edit_Input"):SelectAll()
	end
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
end

local function OnBusyUncheck()
	MY.SwitchChat("/catr")
end

local m_szAtr
local function OnBusyTip() return m_szAtr end

local function OnMosaicsCheck()
	MY_ChatMosaics.bEnabled = true
	MY_ChatMosaics.ResetMosaics()
end

local function OnMosaicsUncheck()
	MY_ChatMosaics.bEnabled = false
	MY_ChatMosaics.ResetMosaics()
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
	MY_ChatSwitch.tChannel[v.id] = true
end
local m_tChannelTime = {}

MY_ChatSwitch.anchor = { x=10, y=-60, s="BOTTOMLEFT", r="BOTTOMLEFT" }
MY_ChatSwitch.bDisplayPanel = true
MY_ChatSwitch.bLockPostion = false
MY_ChatSwitch.bAlertBeforeClear = true
RegisterCustomData("MY_ChatSwitch.anchor")
RegisterCustomData("MY_ChatSwitch.bDisplayPanel")
RegisterCustomData("MY_ChatSwitch.bLockPostion")
RegisterCustomData("MY_ChatSwitch.bAlertBeforeClear")
for k, _ in pairs(MY_ChatSwitch.tChannel) do RegisterCustomData("MY_ChatSwitch.tChannel."..k) end

local function OnChannelCheck()
	MY.SwitchChat(this.info.channel)
	Station.Lookup("Lowest2/EditBox"):Show()
	Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
	this:Check(false)
end

function MY_ChatSwitch.OnFrameCreate()
	this.tRadios = {}
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_TALK")
	this:EnableDrag(not MY_ChatSwitch.bLockPostion)
	
	local hContainer = this:Lookup("WndContainer_Radios")
	hContainer:SetW(0xFFFF)
	hContainer:Clear()
	local i = 0
	for _, v in ipairs(CHANNEL_LIST) do
		if MY_ChatSwitch.tChannel[v.id] then
			i = i + 1
			local hCheck, hTitle, hCooldown
			if v.head then
				hCheck = hContainer:AppendContentFromIni(INI_PATH, "Wnd_Channel"):Lookup("WndRadioChannel")
				hTitle = hCheck:Lookup("", "Text_Channel")
				hCooldown = hCheck:Lookup("", "Text_CD")
				hCheck.OnCheckBoxCheck = OnChannelCheck
			elseif v.onclick then
				hCheck = hContainer:AppendContentFromIni(INI_PATH, "Wnd_Channel"):Lookup("WndRadioChannel")
				hTitle = hCheck:Lookup("", "Text_Channel")
				hCooldown = hCheck:Lookup("", "Text_CD")
				hCheck.OnCheckBoxCheck = v.onclick
			else
				hCheck = hContainer:AppendContentFromIni(INI_PATH, "Wnd_CheckBox"):Lookup("WndCheckBox")
				hTitle = hCheck:Lookup("", "Text_CheckBox")
				hCheck.OnCheckBoxCheck = v.oncheck
				hCheck.OnCheckBoxUncheck = v.onuncheck
			end
			hCheck.hTitle = hTitle
			hCheck.hCooldown = hCooldown
			if v.channel then
				this.tRadios[v.channel] = hCheck
			end
			if v.tip then
				XGUI(hCheck):tip(v.tip)
			end
			if hTitle then
				hTitle:SetText(v.title)
				hTitle:SetFontScheme(197)
				hTitle:SetFontColor(unpack(v.color or {255, 255, 255}))
			end
			if hCooldown then
				hCooldown:SetText("")
				hCooldown:SetFontScheme(197)
				hCooldown:SetFontColor(unpack(v.color or {255, 255, 255}))
			end
			hCheck.info = v
		end
	end
	hContainer:FormatAllContentPos()
	hContainer:SetSize(hContainer:GetAllContentSize())
	
	this:Lookup("", "Image_Bar"):SetW(hContainer:GetW() + 35)
	this:SetW(hContainer:GetW() + 60)
	MY_ChatSwitch.UpdateAnchor(this)
end

function MY_ChatSwitch.OnEvent(event)
	if event == "PLAYER_TALK" then
		if arg0 ~= UI_GetClientPlayerID() then
			return
		end
		local hRadio = this.tRadios[arg1]
		if hRadio then
			m_tChannelTime[arg1] = GetCurrentTime()
		end
	elseif event == "UI_SCALED" then
		MY_ChatSwitch.UpdateAnchor(this)
	end
end

function MY_ChatSwitch.OnFrameBreathe()
	for nChannel, nTime in pairs(m_tChannelTime) do
		local nCooldown = (CHANNEL_CD_TIME[nChannel] or 0) - (GetCurrentTime() - nTime)
		if nCooldown <= 0 then
			m_tChannelTime[nChannel] = nil
		end
		
		local hCheck = this.tRadios[nChannel]
		local hCooldown = hCheck and hCheck.hCooldown
		if hCooldown then
			hCooldown:SetText(nCooldown > 0 and nCooldown or "")
		end
	end
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
	MY_ChatSwitch.anchor = GetFrameAnchor(this)
end

function MY_ChatSwitch.UpdateAnchor(this)
	this:SetPoint(MY_ChatSwitch.anchor.s, 0, 0, MY_ChatSwitch.anchor.r, MY_ChatSwitch.anchor.x, MY_ChatSwitch.anchor.y)
	this:CorrectPos()
end

MY.RegisterEvent("ON_CHAT_SET_AFK", function()
	if type(arg0) == "table" then
		m_szAfk = MY.Chat.StringfyContent(arg0)
	else
		m_szAfk = arg0 and tostring(arg0)
	end
end)

MY.RegisterEvent("ON_CHAT_SET_ATR", function()
	if type(arg0) == "table" then
		m_szAtr = MY.Chat.StringfyContent(arg0)
	else
		m_szAtr = arg0 and tostring(arg0)
	end
end)

function MY_ChatSwitch.ReInitUI()
	Wnd.CloseWindow("MY_ChatSwitch")
	if MY_ChatSwitch.bDisplayPanel then
		Wnd.OpenWindow(INI_PATH, "MY_ChatSwitch")
	end
end
MY.RegisterInit('MY_CHAT', MY_ChatSwitch.ReInitUI)

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
		checked = MY_ChatSwitch.bDisplayPanel,
		oncheck = function(bChecked)
			MY_ChatSwitch.bDisplayPanel = bChecked
			MY_ChatSwitch.ReInitUI()
		end,
	})
	y = y + deltaY
	
	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["lock postion"],
		checked = MY_ChatSwitch.bLockPostion,
		oncheck = function(bChecked)
			MY_ChatSwitch.bLockPostion = bChecked
			MY_ChatSwitch.ReInitUI()
		end,
		isdisable = function()
			return not MY_ChatSwitch.bDisplayPanel
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
					return not MY_ChatSwitch.bDisplayPanel
				end,
			}
			for _, v in ipairs(CHANNEL_LIST) do
				table.insert(t, {
					szOption = v.title, rgb = v.color,
					bCheck = true, bChecked = MY_ChatSwitch.tChannel[v.id],
					fnAction = function()
						MY_ChatSwitch.tChannel[v.id] = not MY_ChatSwitch.tChannel[v.id]
						MY_ChatSwitch.ReInitUI()
					end,
				})
			end
			return t
		end,
		isdisable = function()
			return not MY_ChatSwitch.bDisplayPanel
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
		checked = MY_Chat.bChatTime,
		oncheck = function(bChecked)
			if bChecked and HM_ToolBox then
				HM_ToolBox.bChatTime = false
			end
			MY_Chat.bChatTime = bChecked
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
				bChecked = MY_Chat.eChatTime == "HOUR_MIN",
				fnAction = function()
					MY_Chat.eChatTime = "HOUR_MIN"
				end,
				fnDisable = function()
					return not MY_Chat.bChatTime
				end,
			},{
				szOption = _L['hh:mm:ss'],
				bMCheck = true,
				bChecked = MY_Chat.eChatTime == "HOUR_MIN_SEC",
				fnAction = function()
					MY_Chat.eChatTime = "HOUR_MIN_SEC"
				end,
				fnDisable = function()
					return not MY_Chat.bChatTime
				end,
			}}
		end,
	})
	y = y + deltaY
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = 250,
		text = _L["chat copy"],
		checked = MY_Chat.bChatCopy,
		oncheck = function(bChecked)
			MY_Chat.bChatCopy = bChecked
		end,
	})
	y = y + deltaY
	
	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["always show *"],
		checked = MY_Chat.bChatCopyAlwaysShowMask,
		oncheck = function(bChecked)
			MY_Chat.bChatCopyAlwaysShowMask = bChecked
		end,
		isdisable = function()
			return not MY_Chat.bChatCopy
		end,
	})
	y = y + deltaY
	
	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["always be white"],
		checked = MY_Chat.bChatCopyAlwaysWhite,
		oncheck = function(bChecked)
			MY_Chat.bChatCopyAlwaysWhite = bChecked
		end,
		isdisable = function()
			return not MY_Chat.bChatCopy
		end,
	})
	y = y + deltaY
	
	ui:append("WndCheckBox", {
		x = x + deltaX, y = y, w = 250,
		text = _L["hide system msg copy"],
		checked = MY_Chat.bChatCopyNoCopySysmsg,
		oncheck = function(bChecked)
			MY_Chat.bChatCopyNoCopySysmsg = bChecked
		end,
		isdisable = function()
			return not MY_Chat.bChatCopy
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
