-----------------------------------------------
-- @Desc  : 茗伊插件 - 常用工具
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-05-10 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-06-23 22:30:28
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _C = {}
MY_ToolBox = {}

MY_ToolBox.bFriendHeadTip = false
RegisterCustomData("MY_ToolBox.bFriendHeadTip")
MY_ToolBox.bAvoidBlackShenxingCD = true
RegisterCustomData("MY_ToolBox.bAvoidBlackShenxingCD")
MY_ToolBox.bJJCAutoSwitchTalkChannel = true
RegisterCustomData("MY_ToolBox.bJJCAutoSwitchTalkChannel")
MY_ToolBox.bChangGeShadow = false
RegisterCustomData("MY_ToolBox.bChangGeShadow")
MY_ToolBox.ApplyConfig = function()
	-- 好友高亮
	if MY_ToolBox.bFriendHeadTip then
		local hShaList = XGUI.GetShadowHandle("MY_FriendHeadTip")
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID)
			local p = MY.Player.GetFriend(dwID)
			if p then
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
		local function OnPlayerLeave(dwID)
			local sha = hShaList:Lookup(tostring(dwID))
			if sha then
				table.insert(hShaList.freeShadows, sha)
			end
		end
		for _, p in pairs(MY.Player.GetNearPlayer()) do
			OnPlayerEnter(p.dwID)
		end
		MY.RegisterEvent("PLAYER_ENTER_SCENE.MY_FRIEND_TIP", function(event) OnPlayerEnter(arg0) end)
		MY.RegisterEvent("PLAYER_LEAVE_SCENE.MY_FRIEND_TIP", function(event) OnPlayerLeave(arg0) end)
	else
		MY.RegisterEvent("PLAYER_ENTER_SCENE.MY_FRIEND_TIP")
		MY.RegisterEvent("PLAYER_LEAVE_SCENE.MY_FRIEND_TIP")
		XGUI.GetShadowHandle("MY_FriendHeadTip"):Hide()
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
			
			local bIsPrepare, dwSkillID, dwSkillLevel, fProgress = player.GetSkillPrepareState()
			if not (bIsPrepare and dwSkillID == 3691) then
				return
			end
			MY.Sysmsg({_L['Shenxing has been cancelled, cause you got the zhenyan.']})
			player.StopCurrentAction()
		end)
	else
		MY.RegisterEvent('DO_SKILL_CAST.MY_TOOLBOX_AVOIDBLACKSHENXINGCD')
	end
	
	if MY_ToolBox.bJJCAutoSwitchTalkChannel then
		MY.RegisterEvent('LOADING_END.MY_TOOLBOX_JJCAUTOSWITCHTALKCHANNEL', function()
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
		MY.RegisterEvent('LOADING_END.MY_TOOLBOX_JJCAUTOSWITCHTALKCHANNEL')
	end
	
	-- 长歌影子头顶次序
	if MY_ToolBox.bChangGeShadow then
		local hList, hItem, nCount, sha, r, g, b
		local hShaList = XGUI.GetShadowHandle("MY_ChangGeShadow")
		local MAX_SHADOW_COUNT = 10
		MY.BreatheCall("CHANGGE_SHADOW", 500, function()
			local frame = Station.Lookup("Lowest1/ChangGeShadow")
			if not frame then
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
				if hItem.szState == "disable" then
					r, g, b = 191, 31, 31
				else
					r, g, b = 63, 255, 31
				end
				sha:Show()
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(hItem.nNpcID, true, r, g, b, 200, 0, 40, tostring(i + 1), 0, 1.5)
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
					if ui:item("#Text_MY_Tip"):count() == 0 then
						ui:append("Text", "Text_MY_Tip", {y = ui:height(), w = ui:width(), color = {255, 255, 0}, font = 199, halign = 1})
					end
					ui = ui:item("#Text_MY_Tip"):text(_L['Warning: Bigwar has been finished but not handed yet!']):shake(10, 10, 10, 1000)
					break
				end
			end
		end
	end
end)

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
	  		for _, buff in pairs(MY.Player.GetBuffList(p)) do
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
	ui:append("WndCheckBox", "WndCheckBox_FriendHeadTip"):children("#WndCheckBox_FriendHeadTip")
	  :pos(x, y):width(180)
	  :text(_L['friend headtop tips'])
	  :check(MY_ToolBox.bFriendHeadTip)
	  :check(function(bCheck)
	  	MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
		MY_ToolBox.ApplyConfig()
	  end)
	y = y + 30
	
	-- 背包搜索
	ui:append("WndCheckBox", "WndCheckBox_BagEx"):children("#WndCheckBox_BagEx")
	  :pos(x, y)
	  :text(_L['package searcher'])
	  :check(MY_BagEx.bEnable or false)
	  :check(function(bChecked)
	  	MY_BagEx.Enable(bChecked)
	  end)
	y = y + 30
	
	-- 显示历史技能列表
	ui:append("WndCheckBox", "WndCheckBox_VisualSkill"):children("#WndCheckBox_VisualSkill")
	  :pos(x, y):width(160)
	  :text(_L['visual skill'])
	  :check(MY_VisualSkill.bEnable or false)
	  :check(function(bChecked)
	  	MY_VisualSkill.bEnable = bChecked
	  	MY_VisualSkill.Reload()
	  end)
	
	ui:append("WndSliderBox", "WndSliderBox_VisualSkillCast"):children("#WndSliderBox_VisualSkillCast")
	  :pos(x + 160, y)
	  :sliderStyle(false):range(1, 32)
	  :value(MY_VisualSkill.nVisualSkillBoxCount)
	  :text(_L("display %d skills.", MY_VisualSkill.nVisualSkillBoxCount))
	  :text(function(val) return _L("display %d skills.", val) end)
	  :change(function(raw, val)
	  	MY_VisualSkill.nVisualSkillBoxCount = val
	  	MY_VisualSkill.Reload()
	  end)
	y = y + 30
	
	-- 防止神行CD被黑
	ui:append("WndCheckBox", "WndCheckBox_AvoidBlackShenxingCD"):children("#WndCheckBox_AvoidBlackShenxingCD")
	  :pos(x, y):width(150)
	  :text(_L['avoid blacking shenxing cd']):check(MY_ToolBox.bAvoidBlackShenxingCD or false)
	  :check(function(bChecked)
	  	MY_ToolBox.bAvoidBlackShenxingCD = bChecked
	  	MY_ToolBox.ApplyConfig()
	  end)
	y = y + 30
	
	-- 自动隐藏聊天栏
	ui:append("WndCheckBox", "WndCheckBox_AutoHideChatPanel"):children("#WndCheckBox_AutoHideChatPanel")
	  :pos(x, y):width(150)
	  :text(_L['auto hide chat panel']):check(MY_AutoHideChat.bAutoHideChatPanel)
	  :check(function(bChecked)
	  	MY_AutoHideChat.bAutoHideChatPanel = bChecked
	  	MY_AutoHideChat.ApplyConfig()
	  end)
	y = y + 30
	
	-- 自动隐藏聊天栏
	ui:append("WndCheckBox", "WndCheckBox_AutoSwitchChannel"):children("#WndCheckBox_AutoSwitchChannel")
	  :pos(x, y):width(300)
	  :text(_L['auto switch talk channel when into battle field']):check(MY_ToolBox.bJJCAutoSwitchTalkChannel)
	  :check(function(bChecked)
	  	MY_ToolBox.bJJCAutoSwitchTalkChannel = bChecked
	  	MY_ToolBox.ApplyConfig()
	  end)
	y = y + 30
	
	-- 长歌影子顺序
	ui:append("WndCheckBox", {
		x = x, y = y, w = 300,
		text = _L['show changge shadow headtop index'],
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
	y = y + 30
	
	-- 随身便笺
	ui:append("Text", "Text_Anmerkungen"):item("#Text_Anmerkungen")
	  :pos(x, y)
	  :color(255,255,0)
	  :text(_L['* anmerkungen'])
	y = y + 30
	
	ui:append("WndCheckBox", "WndCheckBox_Anmerkungen_NotePanel"):children("#WndCheckBox_Anmerkungen_NotePanel")
	  :pos(x, y)
	  :text(_L['my anmerkungen'])
	  :check(MY_Anmerkungen.bNotePanelEnable or false)
	  :check(function(bChecked)
	  	MY_Anmerkungen.bNotePanelEnable = bChecked
	  	MY_Anmerkungen.ReloadNotePanel()
	  end)
	y = y + 30
end
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], _L['General'], "UI/Image/Common/Money.UITex|243", { 255, 255, 0, 200 }, PS)
