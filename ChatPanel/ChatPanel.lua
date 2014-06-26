ChatPanel = ChatPanel or {}

ChatPanel = {
	Anchor = {
		s = "LEFT",
		r = "LEFT",
		x = 0,
		y = 600,
	},

	bEnable = true,
	bLock = false,
	bGatherData = true,
	bShowSecond = false,
	bTalkFilter = true,
	bTalkBalloon = true,
	bChatLog = false,
	bSaveMsgCache = false,
	bColor = true,
	szMsg = nil,

	tBlackList = {"击杀", "斩杀", "银联"},

	tForceInfo = {},

	szFile = "\\Interface\\MY\\ChatPanel\\data\\force.dat",
	szTemp = "\\Interface\\MY\\ChatPanel\\data\\schoolinfo.dat",
	szLog = "\\Interface\\MY\\ChatPanel\\data\\msg.dat",

	nSayChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS,

	tForceColor = {
		[0] = {255, 255, 255},		--新人
		[1] = {255, 178, 95},		--少林
		[2] = {196, 152, 255},		--万花
		[3] = {217, 156, 110},		--天策
		[4] = {89, 224, 232},		--纯阳
		[5] = {255, 129, 176},		--七秀
		[6] = {55, 147, 255},		--五毒
		[7] = {121, 183, 54},		--唐门
		[8] = {214, 249, 93},		--藏剑
		[10] = {230, 165, 25},		--明教
	},

	tTimeChannel = {
		["综合频道"] = {bOn = true, nPage = 1},
		["常用频道"] = {bOn = false, nPage = 3},
		["其他频道"] = {bOn = false, nPage = 4},
		["密聊频道"] = {bOn = false, nPage = 6},
	},

	tCustomTimeChannel = {},

	tLogChannel = {
		["密聊频道"] = {bOn = false, szName = "MSG_WHISPER"},
		["好友频道"] = {bOn = false, szName = "MSG_FRIEND"},
		["队伍频道"] = {bOn = false, szName = "MSG_PARTY"},
		["团队频道"] = {bOn = false, szName = "MSG_TEAM"},
		["帮会频道"] = {bOn = false, szName = "MSG_GUILD"},
	},

	tMonitorChannel = {},

	tMsgCache = {},
}

local tFaceIcon = {}
local tSortFaceIcon = {}
local tFIconMap = {}
local tCustomFilter = {}
local FACE_ONCE_SEND_MAX_COUNT = 10
local UITEX_FILE_PATH = "ui/Image/UICommon/Talk_face.UITex"

local tWhiteList = {
	"55", "33", "2200", "冲分", "进组", "随便来", "T", "DPS", "治疗",
	"HS", "BX", "奶毒", "奶秀", "驱散", "DH", "ZLD", "猪笼", "LYZ", "五小","MS",
}

local tMsgType = {
	PLAYER_TALK_CHANNEL.NEARBY,	--近聊
	PLAYER_TALK_CHANNEL.WORLD,	--世界
	PLAYER_TALK_CHANNEL.CAMP,	--阵营
	PLAYER_TALK_CHANNEL.SENCE,	--地图
}

local tChatItems = {
	{"Radio_Say", "Text_Say", "说", {g_tStrings.HEADER_SHOW_SAY, "/s "}, {255, 255, 255}},						--说
	{"Radio_Yell", "Text_Yell", "喊", {g_tStrings.HEADER_SHOW_MAP,"/y "}, {255, 126, 126}},						--地
	{"Radio_World", "Text_World", "世", {g_tStrings.HEADER_SHOW_WORLD, "/h "}, {252, 204, 204}},				--世
	{"Radio_Party", "Text_Party", "队", {g_tStrings.HEADER_SHOW_CHAT_PARTY, "/p "}, {140, 178, 253}},			--队
	{"Radio_Team", "Text_Team", "团", {g_tStrings.HEADER_SHOW_TEAM,"/t "}, {73, 168, 241}},						--团
	{"Radio_Battle", "Text_Battle", "战", {g_tStrings.HEADER_SHOW_BATTLE_FIELD,"/b "}, {255, 126, 126}},		--战
	{"Radio_Tong", "Text_Tong", "帮", {g_tStrings.HEADER_SHOW_CHAT_FACTION, "/g "}, {0, 200, 72}},				--帮
	{"Radio_School", "Text_School", "派", {g_tStrings.HEADER_SHOW_SCHOOL, "/f "}, {0, 255, 255}},				--派
	{"Radio_Camp", "Text_Camp", "阵", {g_tStrings.HEADER_SHOW_CAMP,"/c "}, {155, 230, 58}},						--阵
	{"Radio_Friends", "Text_Friends", "友", {g_tStrings.HEADER_SHOW_FRIEND,"/o "}, {241, 114, 183}},			--友
	{"Radio_Alliance", "Text_Alliance", "盟", {g_tStrings.HEADER_SHOW_CHAT_ALLIANCE, "/a "}, {178, 240, 164}},	--盟
}

---------------------------------------------------------------
-- 配置保存
---------------------------------------------------------------
RegisterCustomData("ChatPanel.bLock")
RegisterCustomData("ChatPanel.bEnable")
RegisterCustomData("ChatPanel.Anchor")
RegisterCustomData("ChatPanel.bTalkFilter")
RegisterCustomData("ChatPanel.bGatherData")
RegisterCustomData("ChatPanel.bShowSecond")
RegisterCustomData("ChatPanel.tForceColor")
RegisterCustomData("ChatPanel.bColor")
RegisterCustomData("ChatPanel.bTalkBalloon")
RegisterCustomData("ChatPanel.tBlackList")
RegisterCustomData("ChatPanel.tTimeChannel")
RegisterCustomData("ChatPanel.tCustomTimeChannel")
RegisterCustomData("ChatPanel.bChatLog")
RegisterCustomData("ChatPanel.tLogChannel")
RegisterCustomData("ChatPanel.nSayChannel")
RegisterCustomData("ChatPanel.bSaveMsgCache")
---------------------------------------------------------------
-- 系统调用
---------------------------------------------------------------
function ChatPanel.OnFrameCreate()
	this:RegisterEvent("CUSTOM_DATA_LOADED")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_TALK")
	this:RegisterEvent("PLAYER_SAY")

	this:RegisterEvent("PLAYER_DISPLAY_DATA_UPDATE")
	this:RegisterEvent("GAME_EXIT")
	this:RegisterEvent("PLAYER_EXIT_GAME")
	this:RegisterEvent("LOGIN_GAME")

	for k, v in pairs(tChatItems) do
		this:Lookup(v[1], v[2]):SetText(v[3])
		this:Lookup(v[1], v[2]):SetFontColor(unpack(v[5]))
	end

	this:Lookup("", "Handle_TotalBalloon"):Clear()
end

function ChatPanel.OnEvent(event)
	if event == "CUSTOM_DATA_LOADED" and arg0 == "Role" then
		if ChatPanel.bLock then
			this:EnableDrag(false)
		else
			this:EnableDrag(true)
		end
		ChatPanel.RegisterMonitor(ChatPanel.bEnable)
	elseif event == "PLAYER_DISPLAY_DATA_UPDATE" then
		if ChatPanel.bGatherData then
			ChatPanel.GetForceInfo(arg0)
		end
	elseif event == "PLAYER_EXIT_GAME" or event == "GAME_EXIT" then
		ChatPanel.SaveForceInfo()
		if ChatPanel.bSaveMsgCache then
			ChatLog.SaveMsgCache()
		end
	elseif event == "LOGIN_GAME" then
		ChatPanel.LoadForceInfo()
	elseif event == "UI_SCALED" then
		ChatPanel.UpdateAnchor(this)
	elseif event == "PLAYER_TALK" then
		if ChatPanel.bEnable then
			ChatPanel.OnTalk()
		end
		if ChatPanel.bChatLog then
			ChatLog.OnTalk()
		end
	elseif event == "PLAYER_SAY" then
		if ChatPanel.bTalkBalloon then
			ChatPanel.OnSay()
		end
	end
end

function ChatPanel.OnFrameDragEnd()
	this:CorrectPos()
	ChatPanel.Anchor = GetFrameAnchor(this)
end

function ChatPanel.UpdateAnchor(frame)
	local anchor = ChatPanel.Anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	frame:CorrectPos()
end

function ChatPanel.OnFrameBreathe()
	if not ChatPanel.bTalkBalloon then
		return
	end
	local player = GetClientPlayer()
	if not player then
		return
	end
	local handle = this:Lookup("","Handle_TotalBalloon")
	if not player.IsInParty() then
		handle:Clear()	--出现泡泡时退队需要清空泡泡
		return
	end
	local nCount = handle:GetItemCount()
	for i = 0, nCount - 1 do
		local hBalloon = handle:Lookup(i)
		if not hBalloon.dwID then
			handle:RemoveItem(i)
			nCount = nCount - 1
			return
		end
		if GetTime() - hBalloon.nTime > 5000 then
			if hBalloon.nAlpha > 0 then
				handle:SetAlpha(hBalloon.nAlpha)
				hBalloon.nAlpha = hBalloon.nAlpha - 8
			else
				handle:RemoveItem(i)
				nCount = nCount - 1
			end
		else
			handle:SetAlpha(hBalloon.nAlpha)
		end
	end
end

function ChatPanel.init()
	for k, v in pairs(tChatItems)do
		if Station.Lookup("Lowest2/EditBox"):Lookup("", "Text_Channel"):GetText() == v[3][1] then
			Station.Lookup("Normal/ChatPanel"):Lookup(k):Check(true)
			Station.SetFocusWindow(nil)
			return
		end
	end
end

function ChatPanel.OnCheckBoxCheck()
	local szName = this:GetName()
	for k, v in pairs(tChatItems) do
		if v[1] == szName then
			SwitchChatChannel(v[4][2])
			Station.SetFocusWindow(Station.Lookup("Lowest2/EditBox/Edit_Input"))
		end
		Station.Lookup("Normal/ChatPanel"):Lookup(v[1]):Check(false)
	end
end

function ChatPanel.OnTalk()
	local t = ChatPanel.MergeChannelTable()
	for k, v in pairs(t) do
		local frame = Station.Lookup("Lowest2/ChatPanel"..v.nPage)
		if frame and v.bOn then
			local handle = frame:Lookup("Wnd_Message","Handle_Message")
			if not handle then
				return
			end
			local item, index = ChatPanel.GetFirstItem(handle)
			local bFinished = false
			if item and not item.bShowTime then
				bFinished = true
				item.bShowTime = true
				if item.GetFontScheme then
					local szFont = item:GetFontScheme()
					local r, g, b = item:GetFontColor()
					--插入时间
					handle:InsertItemFromString(index, false, "<text>text="..EncodeComponentsString(""..ChatPanel.GetTime().."").."name=\"copylink\" eventid=513 font="..szFont.." r="..r.." g="..g.." b="..b.."</text>")
					local timer = handle:Lookup(index)
					timer.szMsg = ChatPanel.szMsg
					timer.dwID = arg0

					if ChatPanel.bTalkFilter then
						for kk, vv in pairs(tMsgType) do
							if arg1 == vv and ChatPanel.CanMsgFilter(timer) and arg0 ~= UI_GetClientPlayerID() then
								local nFirstPos = timer:GetIndex()
								local nEndPos = handle:GetItemCount() - 1
								for i = 1, nEndPos - nFirstPos + 1 do
									handle:RemoveItem(nEndPos - i + 1)
								end
								--防止空行或者遮挡
								if not frame:Lookup("Wnd_Message/Btn_End"):IsEnabled() then
									frame:Lookup("Wnd_Message/Scroll_Msg"):ScrollEnd()
								end
							end
						end
					end

					--聊天复制
					timer.OnItemLButtonDown =  function()
						ChatPanel.CopyLink(this)
					end

					--职业着色
					if ChatPanel.bColor then
						local pos = ChatPanel.GetNamePos(handle, index)
						if pos then
							local name = handle:Lookup(index + pos)
							local color = ChatPanel.GetForceColor(arg0, ChatPanel.bGatherData)
							if color then
								name:SetFontColor(unpack(color))
							else
								name:SetFontColor(item:GetFontColor())
							end
						end
					end
				end
			end
			if bFinished then
				if not frame:Lookup("Wnd_Message/Btn_End"):IsEnabled() then
					frame:Lookup("Wnd_Message/Scroll_Msg"):ScrollEnd()
				end
			end
		end
	end
end

function ChatPanel.OnSay()
	local player = GetClientPlayer()
	if not player then return end
	if arg1 == player.dwID then return end
	if arg2 ~= PLAYER_TALK_CHANNEL.TEAM then return end
	if player.IsInParty() then
		local hTeam = GetClientTeam()
		if not hTeam then return end
		if hTeam.nGroupNum > 1 then
			return
		end
		local hGroup = hTeam.GetGroupInfo(0)
		for k, v in pairs(hGroup.MemberList) do
			if v == arg1 then
				ChatPanel.AppendBalloon(arg1, arg0, false)
			end
		end
	end
end

---------------------------------------------------------------
-- 聊天复制和时间显示相关
---------------------------------------------------------------
function ChatPanel.GetFirstItem(handle)
	local nCount = handle:GetItemCount()
	local hLastItem, hLastItem1
	while(nCount > 0) do
		nCount = nCount - 1
		hLastItem = handle:Lookup(nCount)
		if hLastItem:GetName() == "msglink" then
			return hLastItem, nCount
		else
			if hLastItem.GetText and hLastItem:GetText():find(g_tStrings.STR_TALK_HEAD_SAY) then
				hLastItem = handle:Lookup(nCount - 1)
				hLastItem1 = handle:Lookup(nCount - 2)
				if hLastItem1 and hLastItem1.GetText and hLastItem1:GetText():find(g_tStrings.STR_TALK_HEAD_WHISPER_REPLY) then
					return hLastItem1, nCount - 2
				end
				return hLastItem, nCount - 1
			end
		end
	end
end
--1,2,3
--[世界][XXX]：
--[XXX]说：
--[阵营][浩气盟][XXX]：
--你悄悄的对[XXX]说：
--[XXX]悄悄的说
function ChatPanel.GetNamePos(handle, index)
	local item = handle:Lookup(index + 1)
	if item then
		if item:GetName() == "msglink" then
			if item:GetText() == "[阵营]" then
				return 3
			else
				return 2
			end
		elseif item:GetName() == "namelink" then
			return 1
		--else	--防止密聊染色出错
		--	return 2
		end
	end
	return nil
end

--解析消息
function ChatPanel.FormatContent(szMsg)
	local t = {}
	for w in string.gfind(szMsg, "<text>text=(.-)</text>") do
		if w then
			table.insert(t, w)
		end
	end
	--Output(t)
	local t2 = {}
	for k, v in pairs(t) do
		if not string.find(v, "name=") then
			if string.find(v, "frame=") then
				local n = string.match(v, "frame=(%d+)")
				local szCmd, nFaceID = ChatPanel.GetFaceCommand("image", tonumber(n))
				table.insert(t2, {type = "faceicon", text = szCmd, nFaceID = nFaceID})
			elseif string.find(v, "group=") then
				local n = string.match(v, "group=(%d+)")
				local szCmd, nFaceID = ChatPanel.GetFaceCommand("animate", tonumber(n))
				table.insert(t2, {type = "faceicon", text = szCmd, nFaceID = nFaceID})
			else
				local s = string.match(v, "\"(.-)\"")
				if string.find(s, "：") then
					s = string.sub(s, string.find(s, "：") + 2, -1)
				end
				table.insert(t2, {type= "text", text = s})
			end
		else
			--物品链接
			if string.find(v, "name=\"itemlink\"") then
				local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "item", text = name, item = userdata}})
			--物品信息
			elseif string.find(v, "name=\"iteminfolink\"") then
				local name, version, tab, index = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\this.dwTabType=(%d+)\\this.dwIndex=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "iteminfo", text = name, version = version, tabtype = tab, index = index}})
			--姓名
			elseif string.find(v, "name=\"namelink\"") then
				local name = string.match(v,"%[(.-)%]")
				table.insert(t2, {"["..name.."]", {type = "name", text = "["..name.."]", name = name}})
			--任务
			elseif string.find(v, "name=\"questlink\"") then
				local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "quest", text = name, questid = userdata}})
			--生活技艺
			elseif string.find(v, "name=\"recipelink\"") then
				local name, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\this.dwRecipeID=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "recipe", text = name, craftid = craft, recipeid = recipe}})
			--技能
			elseif string.find(v, "name=\"skilllink\"") then
				local name, skillinfo = string.match(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
				local skillKey = {}
				for w in string.gfind(skillinfo, "(.-)%,") do
					local k, v  = string.match(w, "(.-)=(%w+)")
					skillKey[k] = v
				end
				table.insert(t2, {"["..name.."]", skillKey})
			--称号
			elseif string.find(v, "name=\"designationlink\"") then
				local name, id, fix = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\this.bPrefix=(.-)")
				table.insert(t2, {"["..name.."]", {type = "designation", text = name, id = id, prefix = fix}})
			--技能秘籍
			elseif string.find(v, "name=\"skillrecipelink\"") then
				local name, id, level = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\this.dwLevel=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "skillrecipe", text = name, id = id, level = level}})
			--书籍
			elseif string.find(v, "name=\"booklink\"") then
				local name, version, tab, index, id = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\this.dwTabType=(%d+)\\this.dwIndex=(%d+)\\this.nBookRecipeID=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "book", text = name, version = version, tabtype = tab, index = index, bookinfo = id}})
			--成就
			elseif string.find(v, "name=\"achievementlink\"") then
				local name, id = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "achievement", text = name, id = id}})
			--强化
			elseif string.find(v, "name=\"enchantlink\"") then
				local name, pro, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\this.dwCraftID=(%d+)\\this.dwRecipeID=(%d+)")
				table.insert(t2, {"["..name.."]", {type = "enchant", text = name, proid = pro, craftid = craft, recipeid = recipe}})
			--事件
			elseif string.find(v, "name=\"eventlink\"") then
				local name, na, info = string.match(v,"%[(.-)%].-script=\"this.szName=\"(.-)\"\\this.szLinkInfo=\"(.-)\"")
				table.insert(t2, {"["..name.."]", {type = "eventlink", text = name, name = na, linkinfo = info or ""}})
			end
		end
	end
	return t2
end

function ChatPanel.CopyLink(hItem)
	local szMsg = hItem.szMsg
	local t = ChatPanel.FormatContent(szMsg)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")

	edit:ClearText()
	for k, v in ipairs(t) do
		if v.text ~= "" then
			if v.type == "text" or v.type == "faceicon" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v[1], v[2])
			end
		end
	end

	Station.SetFocusWindow(edit)
end

function ChatPanel.GetTime()
	local nTime = GetCurrentTime()
	local t = TimeToDate(nTime)
	if ChatPanel.bShowSecond then
		return string.format("[%02d:%02d:%02d]", t.hour, t.minute, t.second)
	else
		return string.format("[%02d:%02d]", t.hour, t.minute)
	end
end

function ChatPanel.GetContent(szMsg, nFont, bRich, r, g, b)
	local i = string.find(szMsg, "name=\"namelink\"")
	if i then
		local szText = string.sub(szMsg, i + 34, -1)
		szText = string.gsub(szText, "%c", "")
		szText = string.gsub(szText, "\\\"", "\"")

		szText = string.gsub(szText, "<animate>path", "<text>text")
		szText = string.gsub(szText, "</animate>", "</text>")
		szText = string.gsub(szText, "<image>path", "<text>text")
		szText = string.gsub(szText, "</image>", "</text>")

		ChatPanel.szMsg = szText
	end
end

---------------------------------------------------------------
-- 职业着色相关
---------------------------------------------------------------
function ChatPanel.SetForceColor(dwForceID, r, g, b)
     if ChatPanel.tForceColor then
		ChatPanel.tForceColor[dwForceID] = {r, g, b}
	end
end

function ChatPanel.GetForceColor(dwID, bReadDat)
	local player = GetPlayer(dwID)
	local nForceID = 0
	if player then
		nForceID = player.dwForceID
	else
		if bReadDat then
			for k, v in pairs(ChatPanel.tForceInfo) do
				if k == dwID then
					nForceID = v
					break
				end
			end
		else
			return nil
		end
	end

	if nForceID > 0 then
		return ChatPanel.tForceColor[nForceID]
	else
		return nil
	end

end

---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
function ChatPanel.GetForceInfo(dwID)
	local player = GetPlayer(dwID)
	if not player then
		return
	end
	local dwForceID = player.dwForceID
	if dwForceID == 0 then 	----新人不记录
		return
	end

	if not ChatPanel.tForceInfo[dwID] then
		ChatPanel.tForceInfo[dwID] = dwForceID
	end
end

function ChatPanel.SaveForceInfo()
	SaveLUAData(ChatPanel.szFile, ChatPanel.tForceInfo)
end

function ChatPanel.LoadForceInfo()
	if IsFileExist(ChatPanel.szFile) then
		ChatPanel.tForceInfo = LoadLUAData(ChatPanel.szFile)
	end
end

--------------------------------------------------------------
-- 数据统计
--------------------------------------------------------------
function ChatPanel.AnalyseForceInfo()
	local szTitle = "已收集职业数据 <D0> 份"
	local szRow = "<D0>\t(<D1>)\t<D2>人"
	local t = {
		["nCount"] = 0,
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 0,
		[5] = 0,
        [6] = 0,
		[7] = 0,
		[8] = 0,
		[10] = 0,
	}
	for k, v in pairs(ChatPanel.tForceInfo) do
		if v > 0 and t[v] then
			t["nCount"] = t["nCount"] + 1
			t[v] = t[v] + 1
		end
	end
	if t["nCount"] == 0 then
		return
	end
	--对table值进行排序
	local t2 = {}
	for k, v in pairs(t) do
		table.insert(t2, {K = k, V = v})
	end
	table.sort (t2, function(a, b) return a.V > b.V end)

	local tResult = {}
	table.insert(tResult, FormatString(szTitle, t["nCount"]))
	for k, v in pairs(t2) do
		if type(v.K) == "number" then
			table.insert(tResult, FormatString(szRow, GetForceTitle(v.K), string.format("%d%%", 100 * (v.V / t["nCount"])), v.V))
		end
	end
	return tResult
end

--------------------------------------------------------------
-- 数据导入合并
--------------------------------------------------------------
function ChatPanel.MergeForceInfo(szFile)
	local temp = nil
	if IsFileExist(szFile) then
		temp = LoadLUAData(szFile)
	else
		OutputMessage("MSG_SYS", "所输入的数据不存在\n")
		return
	end
	local i = 0
	for k, v in pairs(temp) do
		if not ChatPanel.tForceInfo[k] then
			ChatPanel.tForceInfo[k] = v
			i = i + 1
		end
	end
	return i
end

function ChatPanel.LoadOldInfo()
	local temp = nil
	if IsFileExist(ChatPanel.szTemp) then
		temp = LoadLUAData(ChatPanel.szTemp)
	else
		return
	end
	local i = 0
	for k, v in pairs(temp) do
		if not ChatPanel.tForceInfo[v[1]] then
			ChatPanel.tForceInfo[v[1]] = v[2]
			i = i + 1
		end
	end
	return i
end

---------------------------------------------------------------
-- 频道相关
---------------------------------------------------------------
function ChatPanel.GetChatPanelIndex(szName)
	for i = 1, 10, 1 do
		local frame = Station.Lookup("Lowest2/ChatPanel"..i)
		if frame then
			local szTitle = frame:Lookup("CheckBox_Title", "Text_TitleName"):GetText()
			if szTitle == szName then
				return i
			end
		end
	end
	return nil
end

function ChatPanel.MergeChannelTable()
	local t = clone(ChatPanel.tTimeChannel)
	for k, v in pairs(t) do
		for kk, vv in pairs(ChatPanel.tCustomTimeChannel) do
			if not t[kk] then
				t[kk] = vv
			end
		end
	end
	return t
end

function ChatPanel.GetFrame()
	return Station.Lookup("Normal/ChatPanel")
end

---------------------------------------------------------------
-- 聊天表情
---------------------------------------------------------------
function ChatPanel.GetFaceIconList()
	local tFaceIcon = {}
	local nCount = g_tTable.FaceIcon:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.FaceIcon:GetRow(i)
		table.insert(tFaceIcon, tLine)
	end
	return tFaceIcon
end

function ChatPanel.GetFaceCommand(szType, nFrame)
	for k, v in pairs(tFaceIcon) do
		if szType == v.szType and nFrame == v.nFrame then
			return v.szCommand, k
		end
	end
	return nil
end

function ChatPanel.InitFaceIcon()
	tFaceIcon = ChatPanel.GetFaceIconList()

	for nFaceID, tFace in ipairs(tFaceIcon) do
		tFIconMap[tFace.szCommand] = nFaceID
		table.insert(tSortFaceIcon, {nFaceID = nFaceID, nLen = string.len(tFace.szCommand)})
	end
	table.sort(tSortFaceIcon, function(a, b) return  a.nLen > b.nLen end)
end

function ChatPanel.FaceIcon_GetParseText(szText)
	local tResult ={}
	local nPos, nCount, szTmp = 1, 0, ""
	local nLen = string.len(szText)
	local nMaxLen = tSortFaceIcon[1].nLen

	local InserText = function(szTmp)
		if not szTmp or szTmp == "" then
			return
		end

		if nCount ~= 0 and tResult[nCount].type == "text" then
			tResult[nCount].text = tResult[nCount].text..szTmp
		else
			table.insert(tResult, {text=szTmp, type="text"})
			nCount = nCount + 1
		end
	end

	while nPos <= nLen do
		local nStart, nEnd = StringFindW(szText, "#", nPos)
		if not nStart then
			szTmp = string.sub(szText, nPos)
			InserText(szTmp)
			break
		end

		if nStart > nPos then
			szTmp = string.sub(szText, nPos, nStart - 1)
			InserText(szTmp)
		end

		local bFind = false
		for i=nMaxLen - 1, 1, -1 do
			szTmp = string.sub(szText, nStart, nStart + i)
			if szTmp and tFIconMap[szTmp] then
				table.insert(tResult, {text=szTmp, type="faceicon"})
				nCount = nCount + 1
				nPos = nStart + i + 1
				bFind = true
				break
			end
		end

		if not bFind then
			nPos = nStart + 1
		end
	end
	return tResult
end

function ChatPanel.EmotionPanel_ParseBallonText(szText, r, g, b)
	local szResult = ""
	local szAni1 = "<animate>path="..EncodeComponentsString(UITEX_FILE_PATH).." disablescale=1 group="
	local szAni2 = " </animate>"
	local szImg1 = "<image>path="..EncodeComponentsString(UITEX_FILE_PATH).." disablescale=1 frame="
	local szImg2 = " </image>"

	local tText = ChatPanel.FaceIcon_GetParseText(szText)
	local nCount = 0;
	for k, v in ipairs(tText) do
		if v.type == "faceicon" then
			if nCount < FACE_ONCE_SEND_MAX_COUNT then
				local nFaceID = tFIconMap[v.text]
				local nFrame, szType = tFaceIcon[nFaceID].nFrame, tFaceIcon[nFaceID].szType
				if szType == "animate" then
					szResult = szResult..szAni1..nFrame..szAni2
				elseif szType == "image" then
					szResult = szResult..szImg1..nFrame..szImg2
				end
			else
				szResult = szResult..GetFormatText(v.text, nil ,r,g ,b)
			end
			nCount = nCount + 1
		elseif v.type == "text" then
			szResult = szResult..GetFormatText(v.text, nil ,r,g ,b)
		end
	end
	return szResult
end

function ChatPanel.Talk(nChannel, szText)
	if nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		OutputMessage("MSG_SYS", szText	.. "\n")
	else
		local szText = {{ type = "text", text = szText .. "\n"}}
		GetClientPlayer().Talk(nChannel, "", szText)
	end
end

---------------------------------------------------------------
-- 聊天过滤
---------------------------------------------------------------
function ChatPanel.CanMsgFilter(hItem)
	local dwID, szMsg = hItem.dwID, hItem.szMsg
	local t = ChatPanel.FormatContent(szMsg)
	local szText = ""
	for k, v in ipairs(t) do
		if v.text ~= "" then
			if v.type == "text" or v.type == "faceicon" then
				szText = szText .. v.text
			end
		end
	end

	if ChatPanel.NormalFilter(szText) then
		return true
	elseif ChatPanel.IntelligentFilter(dwID, szText) then
		return true
	end
	return false
end

--普通屏蔽
function ChatPanel.NormalFilter(szInfo)
	for _, v in pairs(ChatPanel.tBlackList) do
		if string.find(szInfo, v) then
			return true
		end
	end
	return false
end

--智能屏蔽，计算同一玩家连续5次喊话的相似率，存在相似度高于阀值的喊话即屏蔽
function ChatPanel.IntelligentFilter(dwID, szInfo)
	if not tCustomFilter[dwID] then
		tCustomFilter[dwID] = {" "," "," "," "," ",}
	end
	if #tCustomFilter[dwID] == 5 then
		for _, v in pairs(tCustomFilter[dwID]) do
			if ChatPanel.CheckSimilarTalk(v, szInfo,  10) > 0.65 then	--相似度高于65%
				table.remove(tCustomFilter[dwID], 1)
				table.insert(tCustomFilter[dwID], szInfo)
				return true
			end
		end
		table.remove(tCustomFilter[dwID], 1)
		table.insert(tCustomFilter[dwID], szInfo)
	elseif #tCustomFilter[dwID] > 5 then
		for i = 1, #tCustomFilter[dwID] - 5, 1 do
			table.remove(tCustomFilter[dwID], 1)
		end
	elseif #tCustomFilter[dwID] < 5 then
		for i = 1, #tCustomFilter[dwID] - 5, 1 do
			table.insert(tCustomFilter[dwID], " ")
		end
	end
	return false
end

function ChatPanel.CheckSimilarTalk(tOrg, tTar, nLim)
	local nLenOrg, nLenTar = string.len(tOrg), string.len(tTar)
	if nLim and math.abs(nLenOrg - nLenTar) >= nLim then
		return 0
	end

	if nLenTar <= 20 then
		return 0
	end

	local nPos, _ = string.find(tTar, "=")
	if nPos then
		local szNext = string.sub(tTar, nPos + 1, nPos + 1)
		if szNext and szNext ~= " " then
			if tonumber(szNext) then
				return 0
			end
		elseif szNext and szNext == " " then
			szNext = string.sub(tTar, nPos + 2, nPos + 2)
			if tonumber(szNext) then
				return 0
			end
		end
	end

	for k, v in pairs(tWhiteList) do
		if string.find(tTar, v) then
			return 0
		end
	end

	if type(tOrg) == "string" then
		tOrg = {string.byte(tOrg, 1, nLenOrg)}
	end

	if type(tTar) == "string" then
		tTar = {string.byte(tTar, 1, nLenTar)}
	end

	local nColumns = nLenTar + 1
	local d = {}

	for i = 0, nLenOrg do
		d[i * nColumns] = i
	end

	for j = 0, nLenTar do
		d[j] = j
	end

	for i = 1, nLenOrg do
		local nPos = i * nColumns
		local nBest = nLim
		for j = 1, nLenTar do
			local nCost = (tOrg[i] ~= tTar[j] and 1 or 0)
			local nVal = math.min(
				d[nPos - nColumns + j] + 1,
				d[nPos + j - 1] + 1,
				d[nPos - nColumns + j - 1 ] + nCost
			)
			d[nPos + j] = nVal

			if i > 1 and j > 1 and tOrg[i] == tTar[j - 1] and tOrg[i - 1] == tTar[j] then
				d[nPos + j] = math.min(
					nVal,
					d[nPos - nColumns * 2 + j - 2 ] + nCost
				)
			end

			if nLim and nVal < nBest then
				nBest = nVal
			end
		end
	end
	return 1 - d[#d] / math.max(nLenOrg, nLenTar)
end

--------------------------------------------------------------
--聊天泡泡
--------------------------------------------------------------
function ChatPanel.AppendBalloon(dwID, szMsg)
	local handle = this:Lookup("", "Handle_TotalBalloon")
	local hBalloon = handle:Lookup("Balloon_" .. dwID)
	if not hBalloon then
		handle:AppendItemFromIni("Interface\\MY\\ChatPanel\\ChatPanel.ini", "Handle_Balloon", "Balloon_" .. dwID)
		hBalloon = handle:Lookup(handle:GetItemCount() - 1)
		hBalloon.dwID = dwID
	end
	hBalloon.nTime = GetTime()
	hBalloon.nAlpha = 255
	local hwnd = hBalloon:Lookup("Handle_Content")
	hwnd:Show()
	local r, g, b = GetMsgFontColor("MSG_PARTY")
	szMsg = ChatPanel.EmotionPanel_ParseBallonText(szMsg, r, g, b)
	hwnd:Clear()
	hwnd:SetSize(300, 131)
	hwnd:AppendItemFromString(szMsg)
	hwnd:FormatAllItemPos()
	hwnd:SetSizeByAllItemSize()
	ChatPanel.AdjustBalloonSize(hBalloon, hwnd)
	ChatPanel.ShowBalloon(dwID, hBalloon, hwnd)
end

function ChatPanel.ShowBalloon(dwID, hBalloon, hwnd)
	local handle = Station.Lookup("Normal/Teammate", "")
	local nCount = handle:GetItemCount()
	for i = 0, nCount - 1 do
		local hI = handle:Lookup(i)
		if hI.dwID == dwID then
			local x,y = hI:GetAbsPos()
			local w, h = hwnd:GetSize()
			hBalloon:SetAbsPos(x + 205, y - h - 2)
		end
	end
end

function ChatPanel.AdjustBalloonSize(hBalloon, hwnd)
	local w, h = hwnd:GetSize()
	w, h = w + 20, h + 20
	local image1 = hBalloon:Lookup("Image_Bg1")
	image1:SetSize(w, h)

	local image2 = hBalloon:Lookup("Image_Bg2")
	image2:SetRelPos(w * 0.8 - 16, h - 4)
	hBalloon:SetSize(10000, 10000)
	hBalloon:FormatAllItemPos()
	hBalloon:SetSizeByAllItemSize()
end


--------------------------------------------------------------
-- 生成菜单
--------------------------------------------------------------
function ChatPanel.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Handle_Menu" then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = "<text>text=\"左键拖动，右键设置\" font=162</text>"
		OutputTip(szTip, 400, {x, y, w, h})
	end
end

function ChatPanel.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Handle_Menu" then
		HideTip()
	end
end

function ChatPanel.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Handle_Menu" then
		local menu = ChatPanel.GetMenu()
		PopupMenu(menu)
	end
end

function ChatPanel.GetMenu()
	local menu = {}

	local m_0 = {
		szOption = "锁定面板",
		bCheck = true,
		bChecked = ChatPanel.bLock,
		fnAction = function()
			ChatPanel.bLock = not ChatPanel.bLock
			if ChatPanel.bLock then
				Station.Lookup("Normal/ChatPanel"):EnableDrag(false)
			else
				Station.Lookup("Normal/ChatPanel"):EnableDrag(true)
			end
		end,
	}
	table.insert(menu, m_0)
	table.insert(menu, {bDevide = true})

	local m_1 = {
		szOption = "显示时间",
		bCheck = true,
		bChecked = ChatPanel.bEnable,
		fnAction = function()
			ChatPanel.bEnable = not ChatPanel.bEnable
			ChatPanel.RegisterMonitor(ChatPanel.bEnable)
		end,
		{
			szOption = "精确显示",
			bCheck = true,
			bChecked = ChatPanel.bShowSecond,
			fnDisable = function()
				return not ChatPanel.bEnable
			end,
			fnAction = function()
				ChatPanel.bShowSecond = not ChatPanel.bShowSecond
			end,
		},
	}
	table.insert(menu, m_1)

	local m_2 = {
		szOption = "收集数据",
		bCheck = true,
		bChecked = ChatPanel.bGatherData,
		fnDisable = function()
			return not ChatPanel.bEnable
		end,
		fnAction = function()
			ChatPanel.bGatherData = not ChatPanel.bGatherData
		end,
		{
			szOption = "发布频道",
			{szOption = "近聊频道", bMCheck = true, bChecked = ChatPanel.nSayChannel == PLAYER_TALK_CHANNEL.NEARBY, rgb = GetMsgFontColor("MSG_NORMAL", true), fnAction = function() ChatPanel.nSayChannel = PLAYER_TALK_CHANNEL.NEARBY end},
			{szOption = "队伍频道", bMCheck = true, bChecked = ChatPanel.nSayChannel == PLAYER_TALK_CHANNEL.TEAM, rgb = GetMsgFontColor("MSG_PARTY", true), fnAction = function() ChatPanel.nSayChannel = PLAYER_TALK_CHANNEL.TEAM end},
			{szOption = "团队频道", bMCheck = true, bChecked = ChatPanel.nSayChannel == PLAYER_TALK_CHANNEL.RAID, rgb = GetMsgFontColor("MSG_TEAM", true), fnAction = function() ChatPanel.nSayChannel = PLAYER_TALK_CHANNEL.RAID end},
			{szOption = "帮会频道", bMCheck = true, bChecked = ChatPanel.nSayChannel == PLAYER_TALK_CHANNEL.TONG, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() ChatPanel.nSayChannel = PLAYER_TALK_CHANNEL.TONG end},
			{szOption = "系统频道", bMCheck = true, bChecked = ChatPanel.nSayChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS, fnAction = function() ChatPanel.nSayChannel = 9 end, rgb = GetMsgFontColor("MSG_SYS", true)},
		},
		{bDevide = true},
		{
			szOption = "数据合并",
			fnDisable = function()
				return not ChatPanel.bGatherData
			end,
			fnAction = function()
				GetUserInput("输入数据名（包含后缀名）：", function(szText)
					local szPath = "\\Interface\\ChatPanel\\"..szText
					local nCount = ChatPanel.MergeForceInfo(szPath)
					OutputMessage("MSG_SYS", "共合并 " .. nCount .. " 条数据\n")
				end, nil, nil, nil, nil)
			end,
		},
		{
			szOption = "数据分析",
			fnDisable = function()
				return not ChatPanel.bGatherData
			end,
			fnAction = function()
				local t = ChatPanel.AnalyseForceInfo()
				for k, v in pairs(t) do
					ChatPanel.Talk(ChatPanel.nSayChannel, v)
				end
			end,
		},
		{bDevide = true},
		{
			szOption = "数据转换",
			fnAction = function()
				local n = ChatPanel.LoadOldInfo()
				if n then
					OutputMessage("MSG_SYS", "共转换 " .. n .. " 条旧数据\n")
				end
			end,
		}
	}
	table.insert(menu, m_2)

	local m_3 = {
		szOption = "聊天泡泡",
		bCheck = true,
		bChecked = ChatPanel.bTalkBalloon,
		fnDisable = function()
			return not ChatPanel.bEnable
		end,
		fnAction = function()
			ChatPanel.bTalkBalloon = not ChatPanel.bTalkBalloon
		end,
	}
	table.insert(menu, m_3)

	local m_4 = {
		szOption = "聊天过滤",
		bCheck = true,
		bChecked = ChatPanel.bTalkFilter,
		fnDisable = function()
			return not ChatPanel.bEnable
		end,
		fnAction = function()
			ChatPanel.bTalkFilter = not ChatPanel.bTalkFilter
		end,
	}
	for k, v in pairs(ChatPanel.tBlackList) do
		local m = {
			szOption = v,
			bCheck = true,
			bChecked = true,
			fnDisable = function()
				return not ChatPanel.bTalkFilter
			end,
			fnAction = function()
				ChatPanel.tBlackList[k] = nil
				OutputMessage("MSG_SYS", "[聊天助手]" .. v .. "删除成功\n")
			end,
		}
		table.insert(m_4, m)
	end
	table.insert(m_4, {bDevide = true})
	table.insert(m_4, {
		szOption = "添加",
		fnDisable = function()
			return not ChatPanel.bTalkFilter
		end,
		fnAction = function()
			GetUserInput("输入过滤字：", function(szText)
				table.insert(ChatPanel.tBlackList, szText)
				OutputMessage("MSG_SYS", "[聊天助手]" .. szText .. "添加成功\n")
			end, nil, nil, nil, nil, nil)
		end,}
	)
	table.insert(menu, m_4)

	local m_5 = {
		szOption = "职业着色",
		bCheck = true,
		bChecked = ChatPanel.bColor,
		fnDisable = function()
			return not ChatPanel.bEnable
		end,
		fnAction = function()
			ChatPanel.bColor = not ChatPanel.bColor
		end,
	}
	for dwForceID, tColor in pairs(ChatPanel.tForceColor) do
		if dwForceID then
			local m = {
				szOption = GetForceTitle(dwForceID),
				bColorTable = true,
				bNotChangeSelfColor = false,
				rgb = tColor,
				fnChangeColor = function(UserData, r, g, b)
					ChatPanel.SetForceColor(dwForceID, r, g, b)
				end,
			}
			table.insert(m_5, m)
		end
	end
	table.insert(menu, m_5)

	local m_6 = {
		szOption = "频道设置",
		fnDisable = function()
			return not ChatPanel.bEnable
		end,
	}
	for k, v in pairs(ChatPanel.tTimeChannel) do
		local m = {
			szOption = k,
			bCheck = true,
			bChecked = v.bOn,
			fnAction = function()
				v.bOn = not v.bOn
			end,
		}
		table.insert(m_6, m)
	end
	table.insert(m_6, {bDevide = true})
	local m_7 = {szOption = "自定义"}
	if not IsTableEmpty(ChatPanel.tCustomTimeChannel) then
		for k, v in pairs(ChatPanel.tCustomTimeChannel) do
			local m = {
				szOption = k,
				bCheck = true,
				bChecked = v.bOn,
				fnAction = function()
					v.bOn = not v.bOn
				end,
				{
					szOption = "删除",
					fnAction = function()
						ChatPanel.tCustomTimeChannel[k] = nil
						OutputMessage("MSG_SYS", "[聊天助手]" .. k .. "频道删除成功\n")
					end,
				}
			}
			table.insert(m_7, m)
		end
	end
	table.insert(m_7, {bDevide = true})
	table.insert(m_7, {
		szOption = "添加",
		fnAction = function()
			GetUserInput("输入频道名：", function(szText)
				local index = ChatPanel.GetChatPanelIndex(szText)
				if index then
					if not ChatPanel.tCustomTimeChannel[szText] then
						ChatPanel.tCustomTimeChannel[szText] = {}
					end
					ChatPanel.tCustomTimeChannel[szText] = {bOn = true, nPage = index}
					OutputMessage("MSG_SYS", "[聊天助手]" .. szText .. "频道添加成功\n")
				else
					OutputMessage("MSG_SYS", "[聊天助手]找不到该频道\n")
				end
			end, nil, nil, nil, nil, nil)
		end,}
	)
	table.insert(m_6, m_7)
	table.insert(menu, m_6)

	local m_8 = {
		szOption = "聊天记录",
		bCheck = true,
		bChecked = ChatPanel.bChatLog,
		fnAction = function()
			ChatPanel.bChatLog = not ChatPanel.bChatLog
		end,
		{
			szOption = "查看记录",
			fnDisable = function()
				return not ChatPanel.bChatLog
			end,
			fnAction = function()
				ChatLog.OpenWindow(true)
			end,
		}
	}

	table.insert(m_8, {bDevide = true})

	local m_10 = {
		szOption = "外部保存",
		bCheck = true,
		bChecked = ChatPanel.bSaveMsgCache,
		fnDisable = function()
				return not ChatPanel.bChatLog
			end,
		fnAction = function()
			ChatPanel.bSaveMsgCache = not ChatPanel.bSaveMsgCache
		end,
	}
	table.insert(m_8, m_10)

	local m_9 = {
		szOption = "频道选择",
		fnDisable = function()
			return not ChatPanel.bChatLog
		end,
	}
	for k, v in pairs(ChatPanel.tLogChannel) do
		local m = {
			szOption = k,
			bCheck = true,
			bChecked = v.bOn,
			rgb = GetMsgFontColor(v.szName, true),
			fnAction = function()
				v.bOn = not v.bOn
				if v.bOn then
					ChatLog.AddMonitorMsg(v.szName)
				else
					ChatLog.RemoveMonitorMsg(v.szName)
				end
			end,
		}
		table.insert(m_9, m)
	end
	table.insert(m_8, m_9)
	table.insert(menu, m_8)

	table.insert(menu, {bDevide = true})
	local m_11 = {
		szOption = "重置插件",
		fnAction = function()
			ChatPanel = nil
			OutputMessage("MSG_SYS", "[聊天助手]插件已重置，请小退生效\n")
		end,
	}
	table.insert(menu, m_11)

	return menu
end

--------------------------------------------------------------
-- 注册聊天监控事件
--------------------------------------------------------------
function ChatPanel.RegisterMonitor(bEnable)
	if bEnable then
		RegisterMsgMonitor(ChatPanel.GetContent, {
			"MSG_NORMAL", "MSG_WHISPER",
			"MSG_PARTY", "MSG_MAP", "MSG_FRIEND",
			"MSG_GROUP", "MSG_GUILD",
			"MSG_SCHOOL", "MSG_WORLD",
			"MSG_TEAM", "MSG_CAMP",
			"MSG_BATTLE_FILED", "MSG_GUILD_ALLIANCE"
		})
	else
		UnRegisterMsgMonitor(ChatPanel.GetContent, {
			"MSG_NORMAL", "MSG_WHISPER",
			"MSG_PARTY", "MSG_MAP", "MSG_FRIEND",
			"MSG_GROUP", "MSG_GUILD",
			"MSG_SCHOOL", "MSG_WORLD",
			"MSG_TEAM", "MSG_CAMP",
			"MSG_BATTLE_FILED", "MSG_GUILD_ALLIANCE"
		})
	end
end


--------------------------------------------------------------
-- 初始化表情
--------------------------------------------------------------
tFaceIcon = ChatPanel.GetFaceIconList()
ChatPanel.InitFaceIcon()

Wnd.OpenWindow("Interface\\MY\\ChatPanel\\ChatPanel.ini", "ChatPanel")
