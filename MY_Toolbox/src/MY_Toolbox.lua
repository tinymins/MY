-----------------------------------------------
-- @Desc  : 茗伊插件 - 常用工具
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-05-10 08:40:30
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-05-08 17:30:11
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Toolbox/lang/")
local _C = {}
MY_ToolBox = {}

MY_ToolBox.bFriendHeadTip = false
RegisterCustomData("MY_ToolBox.bFriendHeadTip")
MY_ToolBox.bFriendHeadTipNav = false
RegisterCustomData("MY_ToolBox.bFriendHeadTipNav")
MY_ToolBox.bTongMemberHeadTip = false
RegisterCustomData("MY_ToolBox.bTongMemberHeadTip")
MY_ToolBox.bTongMemberHeadTipNav = false
RegisterCustomData("MY_ToolBox.bTongMemberHeadTipNav")
MY_ToolBox.bAvoidBlackShenxingCD = true
RegisterCustomData("MY_ToolBox.bAvoidBlackShenxingCD")
MY_ToolBox.bJJCAutoSwitchTalkChannel = true
RegisterCustomData("MY_ToolBox.bJJCAutoSwitchTalkChannel")
MY_ToolBox.bChangGeShadow = false
RegisterCustomData("MY_ToolBox.bChangGeShadow")
MY_ToolBox.bChangGeShadowDis = false
RegisterCustomData("MY_ToolBox.bChangGeShadowDis")
MY_ToolBox.bChangGeShadowCD = false
RegisterCustomData("MY_ToolBox.bChangGeShadowCD")
MY_ToolBox.fChangeGeShadowScale = 1.5
RegisterCustomData("MY_ToolBox.fChangeGeShadowScale")
MY_ToolBox.bRestoreAuthorityInfo = true
RegisterCustomData("MY_ToolBox.bRestoreAuthorityInfo")
MY_ToolBox.bAutoShowInArena = true
RegisterCustomData("MY_ToolBox.bAutoShowInArena")
MY_ToolBox.ApplyConfig = function()
	-- 好友高亮
	if Navigator_Remove then
		Navigator_Remove("MY_FRIEND_TIP")
	end
	if MY_ToolBox.bFriendHeadTip then
		local hShaList = XGUI.GetShadowHandle("MY_FriendHeadTip")
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID)
			local tar = GetPlayer(dwID)
			if not tar then
				return
			end
			local p = MY.Player.GetFriend(dwID)
			if p then
				if MY_ToolBox.bFriendHeadTipNav and Navigator_SetID then
					Navigator_SetID("MY_FRIEND_TIP." .. dwID, TARGET.PLAYER, dwID, p.name)
				else
					local sha = hShaList:Lookup(tostring(dwID))
					if not sha then
						hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
						sha = hShaList:Lookup(tostring(dwID))
					end
					local r, g, b, a = 255,255,255,255
					local szTip = ">> " .. p.name .. " <<"
					sha:ClearTriangleFanPoint()
					sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
					sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
					sha:Show()
				end
			end
		end
		local function OnPlayerLeave(dwID)
			if MY_ToolBox.bFriendHeadTipNav and Navigator_Remove then
				Navigator_Remove("MY_FRIEND_TIP." .. dwID)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if sha then
					sha:Hide()
					table.insert(hShaList.freeShadows, sha)
				end
			end
		end
		local function RescanNearby()
			for _, p in pairs(MY.Player.GetNearPlayer()) do
				OnPlayerEnter(p.dwID)
			end
		end
		RescanNearby()
		MY.RegisterEvent("PLAYER_ENTER_SCENE.MY_FRIEND_TIP", function(event) OnPlayerEnter(arg0) end)
		MY.RegisterEvent("PLAYER_LEAVE_SCENE.MY_FRIEND_TIP", function(event) OnPlayerLeave(arg0) end)
		MY.RegisterEvent("DELETE_FELLOWSHIP.MY_FRIEND_TIP", function(event) RescanNearby() end)
		MY.RegisterEvent("PLAYER_FELLOWSHIP_UPDATE.MY_FRIEND_TIP", function(event) RescanNearby() end)
		MY.RegisterEvent("PLAYER_FELLOWSHIP_CHANGE.MY_FRIEND_TIP", function(event) RescanNearby() end)
	else
		MY.RegisterEvent("PLAYER_ENTER_SCENE.MY_FRIEND_TIP")
		MY.RegisterEvent("PLAYER_LEAVE_SCENE.MY_FRIEND_TIP")
		MY.RegisterEvent("DELETE_FELLOWSHIP.MY_FRIEND_TIP")
		MY.RegisterEvent("PLAYER_FELLOWSHIP_UPDATE.MY_FRIEND_TIP")
		MY.RegisterEvent("PLAYER_FELLOWSHIP_CHANGE.MY_FRIEND_TIP")
		XGUI.GetShadowHandle("MY_FriendHeadTip"):Hide()
	end

	-- 帮会成员高亮
	if Navigator_Remove then
		Navigator_Remove("MY_GUILDMEMBER_TIP")
	end
	if MY_ToolBox.bTongMemberHeadTip then
		local hShaList = XGUI.GetShadowHandle("MY_TongMemberHeadTip")
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID, nRetryCount)
			nRetryCount = nRetryCount or 0
			if nRetryCount > 5 then
				return
			end
			local tar = GetPlayer(dwID)
			local me = GetClientPlayer()
			if not tar or not me or me.dwTongID == 0
			or me.dwID == tar.dwID or tar.dwTongID ~= me.dwTongID then
				return
			end
			if tar.szName == "" then
				MY.DelayCall(500, function() OnPlayerEnter(dwID, nRetryCount + 1) end)
				return
			end
			if MY_ToolBox.bTongMemberHeadTipNav and Navigator_SetID then
				Navigator_SetID("MY_GUILDMEMBER_TIP." .. dwID, TARGET.PLAYER, dwID, tar.szName)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if not sha then
					hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
					sha = hShaList:Lookup(tostring(dwID))
				end
				local r, g, b, a = 255,255,255,255
				local szTip = "> " .. tar.szName .. " <"
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
				sha:Show()
			end
		end
		local function OnPlayerLeave(dwID)
			if MY_ToolBox.bTongMemberHeadTipNav and Navigator_Remove then
				Navigator_Remove("MY_GUILDMEMBER_TIP." .. dwID)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if sha then
					sha:Hide()
					table.insert(hShaList.freeShadows, sha)
				end
			end
		end
		for _, p in pairs(MY.Player.GetNearPlayer()) do
			OnPlayerEnter(p.dwID)
		end
		MY.RegisterEvent("PLAYER_ENTER_SCENE.MY_GUILDMEMBER_TIP", function(event) OnPlayerEnter(arg0) end)
		MY.RegisterEvent("PLAYER_LEAVE_SCENE.MY_GUILDMEMBER_TIP", function(event) OnPlayerLeave(arg0) end)
	else
		MY.RegisterEvent("PLAYER_ENTER_SCENE.MY_GUILDMEMBER_TIP")
		MY.RegisterEvent("PLAYER_LEAVE_SCENE.MY_GUILDMEMBER_TIP")
		XGUI.GetShadowHandle("MY_TongMemberHeadTip"):Hide()
	end

	-- 玩家名字变成link方便组队
	MY.RegisterEvent('OPEN_WINDOW.NAMELINKER', function(event)
		local h = Station.Lookup("Normal/DialoguePanel", "Handle_Message")
		for i = 0, h:GetItemCount() - 1 do
			local hItem = h:Lookup(i)
			if hItem:GetType() == "Text" then
				local szText = hItem:GetText()
				for _, szPattern in ipairs(_L.NAME_PATTERN_LIST) do
					local _, _, szName = szText:find(szPattern)
					if szName then
						local nPos1, nPos2 = szText:find(szName)
						h:InsertItemFromString(i, true, GetFormatText(szText:sub(nPos2 + 1), hItem:GetFontScheme()))
						h:InsertItemFromString(i, true, GetFormatText("[" .. szText:sub(nPos1, nPos2) .. "]", nil, nil, nil, nil, nil, nil, "namelink"))
						MY.Chat.RenderLink(h:Lookup(i + 1))
						if MY_Farbnamen and MY_Farbnamen.Render then
							MY_Farbnamen.Render(h:Lookup(i + 1))
						end
						hItem:SetText(szText:sub(1, nPos1 - 1))
						hItem:SetFontColor(0, 0, 0)
						hItem:AutoSize()
						break
					end
				end
			end
		end
		h:FormatAllItemPos()
	end)

	-- 试炼之地九宫助手
	MY.RegisterEvent('OPEN_WINDOW.JIUGONG_HELPER', function(event)
		if MY.IsShieldedVersion() then
			return
		end
		-- 确定当前对话对象是醉逍遥（18707）
		local target = GetTargetHandle(GetClientPlayer().GetTarget())
		if target and target.dwTemplateID ~= 18707 then
			return
		end
		local szText = arg1
		-- 匹配字符串
		string.gsub(szText, "<T1916><(T%d+)><T1926><(T%d+)><T1928><(T%d+)><T1924>.+<T1918><(T%d+)><T1931><(T%d+)><T1933><(T%d+)><T1935>.+<T1920><(T%d+)><T1937><(T%d+)><T1938><(T%d+)><T1939>", function(n1,n2,n3,n4,n5,n6,n7,n8,n9)
			local tNumList = {
				T1925 = 1, T1927 = 2, T1929 = 3,
				T1930 = 4, T1932 = 5, T1934 = 6,
				T1936 = 7, T1922 = 8, T1923 = 9,
				T1940 = false,
			}
			local tDefaultSolution = {
				{8,1,6,3,5,7,4,9,2},
				{6,1,8,7,5,3,2,9,4},
				{4,9,2,3,5,7,8,1,6},
				{2,9,4,7,5,3,6,1,8},
				{6,7,2,1,5,9,8,3,4},
				{8,3,4,1,5,9,6,7,2},
				{2,7,6,9,5,1,4,3,8},
				{4,3,8,9,5,1,2,7,6},
			}

			n1,n2,n3,n4,n5,n6,n7,n8,n9 = tNumList[n1],tNumList[n2],tNumList[n3],tNumList[n4],tNumList[n5],tNumList[n6],tNumList[n7],tNumList[n8],tNumList[n9]
			local tQuestion = {n1,n2,n3,n4,n5,n6,n7,n8,n9}
			local tSolution
			for _, solution in ipairs(tDefaultSolution) do
				local bNotMatch = false
				for i, v in ipairs(solution) do
					if tQuestion[i] and tQuestion[i] ~= v then
						bNotMatch = true
						break
					end
				end
				if not bNotMatch then
					tSolution = solution
					break
				end
			end
			local szText = _L['The kill sequence is: ']
			if tSolution then
				for i, v in ipairs(tQuestion) do
					if not tQuestion[i] then
						szText = szText .. NumberToChinese(tSolution[i]) .. ' '
					end
				end
			else
				szText = szText .. _L['failed to calc.']
			end
			MY.Sysmsg({szText})
			OutputWarningMessage("MSG_WARNING_RED", szText, 10)
		end)
	end)

	-- 防止神行CD被吃
	if MY_ToolBox.bAvoidBlackShenxingCD then
		MY.RegisterEvent('DO_SKILL_CAST.MY_TOOLBOX_AVOIDBLACKSHENXINGCD', function()
			local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
			if not(UI_GetClientPlayerID() == dwID and
			Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)) then
				return
			end
			local player = GetClientPlayer()
			if not player then
				return
			end

			local nType, dwSkillID, dwSkillLevel, fProgress = player.GetSkillOTActionState()
			if not ((
				nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
			) and dwSkillID == 3691) then
				return
			end
			MY.Sysmsg({_L['Shenxing has been cancelled, cause you got the zhenyan.']})
			player.StopCurrentAction()
		end)
	else
		MY.RegisterEvent('DO_SKILL_CAST.MY_TOOLBOX_AVOIDBLACKSHENXINGCD')
	end

	if MY_ToolBox.bJJCAutoSwitchTalkChannel then
		MY.RegisterEvent('LOADING_ENDING.MY_TOOLBOX_JJCAUTOSWITCHTALKCHANNEL', function()
			local bIsBattleField = (GetClientPlayer().GetScene().nType == MAP_TYPE.BATTLE_FIELD)
			local nChannel, szName = EditBox_GetChannel()
			if bIsBattleField and (nChannel == PLAYER_TALK_CHANNEL.RAID or nChannel == PLAYER_TALK_CHANNEL.TEAM) then
				_C.JJCAutoSwitchTalkChannel_OrgChannel = nChannel
				MY.Chat.SwitchChat(PLAYER_TALK_CHANNEL.BATTLE_FIELD)
			elseif not bIsBattleField and nChannel == PLAYER_TALK_CHANNEL.BATTLE_FIELD then
				MY.Chat.SwitchChat(_C.JJCAutoSwitchTalkChannel_OrgChannel or PLAYER_TALK_CHANNEL.RAID)
			end
		end)
	else
		MY.RegisterEvent('LOADING_ENDING.MY_TOOLBOX_JJCAUTOSWITCHTALKCHANNEL')
	end

	-- 长歌影子头顶次序
	if MY_ToolBox.bChangGeShadow then
		local MAX_LIMIT_TIME = 25
		local hList, hItem, nCount, sha, r, g, b, nDis, szText, fPer
		local hShaList = XGUI.GetShadowHandle("MY_ChangGeShadow")
		local MAX_SHADOW_COUNT = 10
		local nInterval = (MY_ToolBox.bChangGeShadowDis or MY_ToolBox.bChangGeShadowCD) and 50 or 400
		MY.BreatheCall("CHANGGE_SHADOW", nInterval, function()
			local frame = Station.Lookup("Lowest1/ChangGeShadow")
			if not frame then
				if nCount and nCount > 0 then
					for i = 0, nCount - 1 do
						sha = hShaList:Lookup(i)
						if sha then
							sha:Hide()
						end
					end
					nCount = 0
				end
				return
			end
			hList = frame:Lookup("Wnd_Bar", "Handle_Skill")
			nCount = hList:GetItemCount()
			for i = 0, nCount - 1 do
				hItem = hList:Lookup(i)
				sha = hShaList:Lookup(i)
				if not sha then
					hShaList:AppendItemFromString("<shadow></shadow>")
					sha = hShaList:Lookup(i)
				end
				nDis = GetCharacterDistance(UI_GetClientPlayerID(), hItem.nNpcID) / 64
				if hItem.szState == "disable" then
					r, g, b = 191, 31, 31
				else
					if nDis > 25 then
						r, g, b = 255, 255, 31
					else
						r, g, b = 63, 255, 31
					end
				end
				fPer = hItem:Lookup("Image_CD"):GetPercentage()
				szText = tostring(i + 1)
				if MY_ToolBox.bChangGeShadowDis and nDis >= 0 then
					szText = szText .. g_tStrings.STR_CONNECT .. KeepOneByteFloat(nDis) .. g_tStrings.STR_METER
				end
				if MY_ToolBox.bChangGeShadowCD then
					szText = szText .. g_tStrings.STR_CONNECT .. math.floor(fPer * MAX_LIMIT_TIME) .. "'"
				end
				sha:Show()
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(hItem.nNpcID, true, r, g, b, 200, 0, 40, szText, 0, MY_ToolBox.fChangeGeShadowScale)
			end
			for i = nCount, MAX_SHADOW_COUNT do
				sha = hShaList:Lookup(i)
				if sha then
					sha:Hide()
				end
			end
		end)
		hShaList:Show()
	else
		MY.BreatheCall("CHANGGE_SHADOW", false)
		XGUI.GetShadowHandle("MY_ChangGeShadow"):Hide()
	end
end
MY.RegisterInit('MY_TOOLBOX', MY_ToolBox.ApplyConfig)
-- 密码锁解锁提醒
MY.RegisterInit('MY_LOCK_TIP', function()
	-- 刚进游戏好像获取不到锁状态 20秒之后再说吧
	MY.DelayCall("MY_LOCK_TIP_DELAY", 20000, function()
		if not IsPhoneLock() then -- 手机密保还提示个鸡
			local state, nResetTime = Lock_State()
			if state == "PASSWORD_LOCK" then
				MY.DelayCall("MY_LOCK_TIP", 100000, function()
					local state, nResetTime = Lock_State()
					if state == "PASSWORD_LOCK" then
						local me = GetClientPlayer()
						local szText = me and me.GetGlobalID and _L.LOCK_TIP[me.GetGlobalID()] or _L['You have been loged in for 2min, you can unlock bag locker now.']
						MY.Sysmsg({szText})
						OutputWarningMessage("MSG_REWARD_GREEN", szText, 10)
					end
				end)
			end
		end
	end)
end)

-- 【台服用】老地图神行
_C.tNonwarData = {
	{ id =  8, x =   70, y =   5 }, -- 洛阳
	{ id = 11, x =   15, y = -90 }, -- 天策
	{ id = 12, x = -150, y = 110 }, -- 枫华
	{ id = 15, x = -450, y =  65 }, -- 长安
	{ id = 26, x =  -20, y =  90 }, -- 荻花宫
	{ id = 32, x =   50, y =  45 }, -- 小战宝
}
MY.BreatheCall(130, function()
	if MY.IsShieldedVersion() then
		return
	end
	local h = Station.Lookup("Topmost1/WorldMap/Wnd_All", "Handle_CopyBtn")
	if not h or h.tNonwarData then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		local m = h:Lookup(i)
		if m and m.mapid == 160 then
			local _w, _ = m:GetSize()
			local fS = m.w / _w
			for _, v in ipairs(_C.tNonwarData) do
				local bOpen = me.GetMapVisitFlag(v.id)
				local szFile, nFrame = "ui/Image/MiddleMap/MapWindow.UITex", 41
				if bOpen then
					nFrame = 98
				end
				h:AppendItemFromString("<image>name=\"mynw_" .. v.id .. "\" path="..EncodeComponentsString(szFile).." frame="..nFrame.." eventid=341</image>")
				local img = h:Lookup(h:GetItemCount() - 1)
				img.bEnable = bOpen
				img.bSelect = bOpen and v.id ~= 26 and v.id ~= 32
				img.x = m.x + v.x
				img.y = m.y + v.y
				img.w, img.h = m.w, m.h
				img.id, img.mapid = v.id, v.id
				img.middlemapindex = 0
				img.name = Table_GetMapName(v.mapid)
				img.city = img.name
				img.button = m.button
				img.copy = true
				img:SetSize(img.w / fS, img.h / fS)
				img:SetRelPos(img.x / fS - (img.w / fS / 2), img.y / fS - (img.h / fS / 2))
			end
			h:FormatAllItemPos()
			break
		end
	end
	h.tNonwarData = true
end)

-- 大战没交
local m_aBigWars = {14765, 14766, 14767, 14768, 14769}
MY.RegisterEvent("ON_FRAME_CREATE.BIG_WAR_CHECK", function()
	local me = GetClientPlayer()
	if me and arg0:GetName() == "ExitPanel" then
		for _, dwQuestID in ipairs(m_aBigWars) do
			local info = me.GetQuestTraceInfo(dwQuestID)
			if info then
				local finished = false
				if info.finish then
					finished = true
				elseif info.quest_state then
					finished = true
					for _, state in ipairs(info.quest_state) do
						if state.need ~= state.have then
							finished = false
						end
					end
				end
				if finished then
					local ui = XGUI(arg0)
					if ui:children("#Text_MY_Tip"):count() == 0 then
						ui:append('Text', { name = 'Text_MY_Tip',y = ui:height(), w = ui:width(), color = {255, 255, 0}, font = 199, halign = 1})
					end
					ui = ui:children("#Text_MY_Tip"):text(_L['Warning: Bigwar has been finished but not handed yet!']):shake(10, 10, 10, 1000)
					break
				end
			end
		end
	end
end)

-- auto restore team authourity info in arena
do local l_tTeamInfo, l_bConfigEnd
MY.RegisterEvent("LOADING_ENDING", function() l_bConfigEnd = false end)
MY.RegisterEvent("ARENA_START", function() l_bConfigEnd = true  end)
local function RestoreTeam()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not l_tTeamInfo
	or not MY_ToolBox.bRestoreAuthorityInfo
	or not me.IsInParty() or not MY.IsInArena() then
		return
	end
	MY.SetTeamInfo(l_tTeamInfo)
end
MY.RegisterEvent("PARTY_ADD_MEMBER", RestoreTeam)

local function SaveTeam()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me.IsInParty() or not MY.IsInArena() or l_bConfigEnd then
		return
	end
	l_tTeamInfo = MY.GetTeamInfo()
end
MY.RegisterEvent({"TEAM_AUTHORITY_CHANGED", "PARTY_SET_FORMATION_LEADER", "TEAM_CHANGE_MEMBER_GROUP"}, SaveTeam)
end

-- 进入JJC自动显示所有人物
do local l_bHideNpc, l_bHidePlayer, l_lock
MY.RegisterEvent("ON_REPRESENT_CMD", function()
	if l_lock then
		return
	end
	if arg0 == "show npc" or arg0 == "hide npc" then
		l_bHideNpc = arg0 == "hide npc"
	elseif arg0 == "show player" or arg0 == "hide player" then
		l_bHidePlayer = arg0 == "hide player"
	end
end)
MY.RegisterEvent("LOADING_END", function()
	if not MY_ToolBox.bAutoShowInArena then
		return
	end
	if MY.IsInArena() or MY.IsInBattleField() then
		l_lock = true
		rlcmd("show npc")
		rlcmd("show player")
	else
		l_lock = true
		if l_bHideNpc then
			rlcmd("hide npc")
		else
			rlcmd("show npc")
		end
		if l_bHidePlayer then
			rlcmd("hide player")
		else
			rlcmd("show player")
		end
		l_lock = false
	end
end)
end

-- ################################################################################################ --
--     #       # # # #         # # # # # # # # #                                 #             # #  --
--       #     #     #         #     #   #     #     # # # # # # # # # # #       #     # # # #      --
--             #     #         # # # # # # # # #               #                 #     #            --
--             #     #                 #                     #               # # # #   #            --
--   # # #   #         # #   # # # # # # # # # # #     # # # # # # # # # #       #     # # # # # #  --
--       #                             #               #     #     #     #     # # #   #   #     #  --
--       #   # # # # # #         # # # # # # #         #     # # # #     #     # #   # #   #     #  --
--       #     #       #         #           #         #     #     #     #   #   #     #   #   #    --
--       #       #   #           #           #         #     # # # #     #       #     #   #   #    --
--       # #       #             #     #     #         #     #     #     #       #     #     #      --
--       #       #   #           #     #     #         # # # # # # # # # #       #   #     #   #    --
--           # #       # #   # # # # # # # # # # #     #                 #       # #     #       #  --
-- ################################################################################################ --
_C.tChannels = {
	{ nChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS, szName = _L['system channel'], rgb = GetMsgFontColor("MSG_SYS"  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TEAM     , szName = _L['team channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.RAID     , szName = _L['raid channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG     , szName = _L['tong channel']  , rgb = GetMsgFontColor("MSG_GUILD" , true) },
}
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30

	-- 检测附近共战
	ui:append("WndButton", "WndButton_GongzhanCheck"):children('#WndButton_GongzhanCheck')
	  :pos(w - 140, y):width(120)
	  :text(_L['check nearby gongzhan'])
	  :lclick(function()
	  	local tGongZhans = {}
	  	for _, p in pairs(MY.GetNearPlayer()) do
	  		for _, buff in pairs(MY.GetBuffList(p)) do
	  			if (not buff.bCanCancel) and string.find(Table_GetBuffName(buff.dwID, buff.nLevel), _L["GongZhan"]) ~= nil then
	  				table.insert(tGongZhans, {p = p, time = (buff.nEndFrame - GetLogicFrameCount()) / 16})
	  			end
	  		end
	  	end
	  	local nChannel = MY_ToolBox.nGongzhanPublishChannel or PLAYER_TALK_CHANNEL.LOCAL_SYS
	  	MY.Talk(nChannel, _L["------------------------------------"])
	  	for _, r in ipairs(tGongZhans) do
	  		MY.Talk( nChannel, _L("Detected [%s] has GongZhan buff for %d sec(s).", r.p.szName, r.time) )
	  	end
	  	MY.Talk(nChannel, _L("Nearby GongZhan Total Count: %d.", #tGongZhans))
	  	MY.Talk(nChannel, _L["------------------------------------"])
	  end):rmenu(function()
	  	local t = { { szOption = _L['send to ...'], bDisable = true }, { bDevide = true } }
	  	for _, tChannel in ipairs(_C.tChannels) do
	  		table.insert( t, {
	  			szOption = tChannel.szName,
	  			rgb = tChannel.rgb,
	  			bCheck = true, bMCheck = true, bChecked = MY_ToolBox.nGongzhanPublishChannel == tChannel.nChannel,
	  			fnAction = function()
	  				MY_ToolBox.nGongzhanPublishChannel = tChannel.nChannel
	  			end
	  		} )
	  	end
	  	return t
	  end)

	-- 好友高亮
	ui:append("WndCheckBox", {
		x = x, y = y, w = 180,
		text = _L['friend headtop tips'],
		checked = MY_ToolBox.bFriendHeadTip,
		oncheck = function(bCheck)
			MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
			MY_ToolBox.ApplyConfig()
		end,
	})
	ui:append("WndCheckBox", {
		x = x + 180, y = y, w = 180,
		text = _L['friend headtop tips nav'],
		checked = MY_ToolBox.bFriendHeadTipNav,
		oncheck = function(bCheck)
			MY_ToolBox.bFriendHeadTipNav = not MY_ToolBox.bFriendHeadTipNav
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 帮会高亮
	ui:append("WndCheckBox", {
		x = x, y = y, w = 180,
		text = _L['tong member headtop tips'],
		checked = MY_ToolBox.bTongMemberHeadTip,
		oncheck = function(bCheck)
			MY_ToolBox.bTongMemberHeadTip = not MY_ToolBox.bTongMemberHeadTip
			MY_ToolBox.ApplyConfig()
		end,
	})
	ui:append("WndCheckBox", {
		x = x + 180, y = y, w = 180,
		text = _L['tong member headtop tips nav'],
		checked = MY_ToolBox.bTongMemberHeadTipNav,
		oncheck = function(bCheck)
			MY_ToolBox.bTongMemberHeadTipNav = not MY_ToolBox.bTongMemberHeadTipNav
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 背包搜索
	if MY_BagEx then
		ui:append("WndCheckBox", {
			x = x, y = y,
			text = _L['package searcher'],
			checked = MY_BagEx.bEnable,
			oncheck = function(bChecked)
				MY_BagEx.Enable(bChecked)
			end,
		})
		y = y + 30
	end

	-- 显示历史技能列表
	ui:append("WndCheckBox", {
		x = x, y = y, w = 160,
		text = _L['visual skill'],
		checked = MY_VisualSkill.bEnable,
		oncheck = function(bChecked)
			MY_VisualSkill.bEnable = bChecked
			MY_VisualSkill.Reload()
		end,
	})

	ui:append("WndSliderBox", {
		x = x + 160, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = {1, 32},
		value = MY_VisualSkill.nVisualSkillBoxCount,
		text = _L("display %d skills.", MY_VisualSkill.nVisualSkillBoxCount),
		textfmt = function(val) return _L("display %d skills.", val) end,
		onchange = function(raw, val)
			MY_VisualSkill.nVisualSkillBoxCount = val
			MY_VisualSkill.Reload()
		end,
	})
	y = y + 30

	-- 防止神行CD被黑
	ui:append("WndCheckBox", {
		x = x, y = y, w = 150,
		text = _L['avoid blacking shenxing cd'],
		checked = MY_ToolBox.bAvoidBlackShenxingCD,
		oncheck = function(bChecked)
			MY_ToolBox.bAvoidBlackShenxingCD = bChecked
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 自动隐藏聊天栏
	ui:append("WndCheckBox", {
		x = x, y = y, w = 150,
		text = _L['auto hide chat panel'],
		checked = MY_AutoHideChat.bAutoHideChatPanel,
		oncheck = function(bChecked)
			MY_AutoHideChat.bAutoHideChatPanel = bChecked
			MY_AutoHideChat.ApplyConfig()
		end,
	})
	y = y + 30

	-- 竞技场频道切换
	ui:append("WndCheckBox", {
		x = x, y = y, w = 300,
		text = _L['auto switch talk channel when into battle field'],
		checked = MY_ToolBox.bJJCAutoSwitchTalkChannel,
		oncheck = function(bChecked)
			MY_ToolBox.bJJCAutoSwitchTalkChannel = bChecked
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 竞技场自动恢复队伍信息
	ui:append("WndCheckBox", {
		x = x, y = y, w = 300,
		text = _L['auto restore team info in arena'],
		checked = MY_ToolBox.bRestoreAuthorityInfo,
		oncheck = function(bChecked)
			MY_ToolBox.bRestoreAuthorityInfo = bChecked
		end,
	})
	y = y + 30

	-- 竞技场自动恢复队伍信息
	ui:append("WndCheckBox", {
		x = x, y = y, w = 300,
		text = _L['auto cancel hide player in arena and battlefield'],
		checked = MY_ToolBox.bAutoShowInArena,
		oncheck = function(bChecked)
			MY_ToolBox.bAutoShowInArena = bChecked
		end,
	})
	y = y + 30

	-- 长歌影子顺序
	ui:append("WndCheckBox", {
		x = x, y = y, w = 150,
		text = _L['show changge shadow index'],
		checked = MY_ToolBox.bChangGeShadow,
		oncheck = function(bChecked)
			MY_ToolBox.bChangGeShadow = bChecked
			MY_ToolBox.ApplyConfig()
		end,
		tip = function(self)
			if not self:enable() then
				return _L['changge force only']
			end
		end,
		tippos = ALW.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == FORCE_TYPE.CHANG_GE
		end,
	})
	ui:append("WndCheckBox", {
		x = x + 150, y = y, w = 100,
		text = _L['show distance'],
		checked = MY_ToolBox.bChangGeShadowDis,
		oncheck = function(bChecked)
			MY_ToolBox.bChangGeShadowDis = bChecked
			MY_ToolBox.ApplyConfig()
		end,
		tip = function(self)
			if not self:enable() then
				return _L['changge force only']
			end
		end,
		tippos = ALW.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == FORCE_TYPE.CHANG_GE
		end,
	})
	ui:append("WndCheckBox", {
		x = x + 250, y = y, w = 100,
		text = _L['show countdown'],
		checked = MY_ToolBox.bChangGeShadowCD,
		oncheck = function(bChecked)
			MY_ToolBox.bChangGeShadowCD = bChecked
			MY_ToolBox.ApplyConfig()
		end,
		tip = function(self)
			if not self:enable() then
				return _L['changge force only']
			end
		end,
		tippos = ALW.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == FORCE_TYPE.CHANG_GE
		end,
	})
	ui:append("WndSliderBox", {
		x = x + 350, y = y, w = 150,
		textfmt = function(val) return _L("scale: %d%%.", val) end,
		range = {10, 800},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_ToolBox.fChangeGeShadowScale * 100,
		onchange = function(raw, val)
			MY_ToolBox.fChangeGeShadowScale = val / 100
		end,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == FORCE_TYPE.CHANG_GE
		end,
	})
	y = y + 30

	-- 随身便笺
	ui:append("Text", {
		x = x, y = y,
		r = 255, g = 255, b = 0,
		text = _L['* anmerkungen'],
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x, y = y,
		text = _L['my anmerkungen'],
		checked = MY_Anmerkungen.bNotePanelEnable,
		oncheck = function(bChecked)
			MY_Anmerkungen.bNotePanelEnable = bChecked
			MY_Anmerkungen.ReloadNotePanel()
		end,
	})
	y = y + 30
end
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], _L['General'], "UI/Image/Common/Money.UITex|243", { 255, 255, 0, 200 }, PS)
