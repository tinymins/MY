--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 常用工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT..'MY_Toolbox/lang/')
if not LIB.AssertVersion('MY_Toolbox', _L['MY_Toolbox'], 0x2011800) then
	return
end
local _C = {}
MY_ToolBox = {}

MY_ToolBox.bFriendHeadTip = false
RegisterCustomData('MY_ToolBox.bFriendHeadTip')
MY_ToolBox.bFriendHeadTipNav = false
RegisterCustomData('MY_ToolBox.bFriendHeadTipNav')
MY_ToolBox.bTongMemberHeadTip = false
RegisterCustomData('MY_ToolBox.bTongMemberHeadTip')
MY_ToolBox.bTongMemberHeadTipNav = false
RegisterCustomData('MY_ToolBox.bTongMemberHeadTipNav')
MY_ToolBox.bAvoidBlackShenxingCD = true
RegisterCustomData('MY_ToolBox.bAvoidBlackShenxingCD')
MY_ToolBox.bJJCAutoSwitchTalkChannel = true
RegisterCustomData('MY_ToolBox.bJJCAutoSwitchTalkChannel')
MY_ToolBox.bChangGeShadow = false
RegisterCustomData('MY_ToolBox.bChangGeShadow')
MY_ToolBox.bChangGeShadowDis = false
RegisterCustomData('MY_ToolBox.bChangGeShadowDis')
MY_ToolBox.bChangGeShadowCD = false
RegisterCustomData('MY_ToolBox.bChangGeShadowCD')
MY_ToolBox.fChangeGeShadowScale = 1.5
RegisterCustomData('MY_ToolBox.fChangeGeShadowScale')
MY_ToolBox.bRestoreAuthorityInfo = true
RegisterCustomData('MY_ToolBox.bRestoreAuthorityInfo')
MY_ToolBox.bAutoShowInArena = true
RegisterCustomData('MY_ToolBox.bAutoShowInArena')
MY_ToolBox.bWhisperMetion = true
RegisterCustomData('MY_ToolBox.bWhisperMetion')
MY_ToolBox.ApplyConfig = function()
	-- 好友高亮
	do
		if Navigator_Remove then
			Navigator_Remove('MY_FRIEND_TIP')
		end
		if MY_ToolBox.bFriendHeadTip then
			local hShaList = UI.GetShadowHandle('MY_FriendHeadTip')
			if not hShaList.freeShadows then
				hShaList.freeShadows = {}
			end
			hShaList:Show()
			local function OnPlayerEnter(dwID)
				local tar = GetPlayer(dwID)
				if not tar then
					return
				end
				local p = LIB.GetFriend(dwID)
				if p then
					if MY_ToolBox.bFriendHeadTipNav and Navigator_SetID then
						Navigator_SetID('MY_FRIEND_TIP.' .. dwID, TARGET.PLAYER, dwID, p.name)
					else
						local sha = hShaList:Lookup(tostring(dwID))
						if not sha then
							hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
							sha = hShaList:Lookup(tostring(dwID))
						end
						local r, g, b, a = 255,255,255,255
						local szTip = '>> ' .. p.name .. ' <<'
						sha:ClearTriangleFanPoint()
						sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
						sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
						sha:Show()
					end
				end
			end
			local function OnPlayerLeave(dwID)
				if MY_ToolBox.bFriendHeadTipNav and Navigator_Remove then
					Navigator_Remove('MY_FRIEND_TIP.' .. dwID)
				else
					local sha = hShaList:Lookup(tostring(dwID))
					if sha then
						sha:Hide()
						table.insert(hShaList.freeShadows, sha)
					end
				end
			end
			local function RescanNearby()
				for _, p in ipairs(LIB.GetNearPlayer()) do
					OnPlayerEnter(p.dwID)
				end
			end
			RescanNearby()
			LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_FRIEND_TIP', function(event) OnPlayerEnter(arg0) end)
			LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_FRIEND_TIP', function(event) OnPlayerLeave(arg0) end)
			LIB.RegisterEvent('DELETE_FELLOWSHIP.MY_FRIEND_TIP', function(event) RescanNearby() end)
			LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE.MY_FRIEND_TIP', function(event) RescanNearby() end)
			LIB.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE.MY_FRIEND_TIP', function(event) RescanNearby() end)
		else
			LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_FRIEND_TIP')
			LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_FRIEND_TIP')
			LIB.RegisterEvent('DELETE_FELLOWSHIP.MY_FRIEND_TIP')
			LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE.MY_FRIEND_TIP')
			LIB.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE.MY_FRIEND_TIP')
			UI.GetShadowHandle('MY_FriendHeadTip'):Hide()
		end
	end
	-- 帮会成员高亮
	do
		if Navigator_Remove then
			Navigator_Remove('MY_GUILDMEMBER_TIP')
		end
		if MY_ToolBox.bTongMemberHeadTip then
			local hShaList = UI.GetShadowHandle('MY_TongMemberHeadTip')
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
				if tar.szName == '' then
					LIB.DelayCall(500, function() OnPlayerEnter(dwID, nRetryCount + 1) end)
					return
				end
				if MY_ToolBox.bTongMemberHeadTipNav and Navigator_SetID then
					Navigator_SetID('MY_GUILDMEMBER_TIP.' .. dwID, TARGET.PLAYER, dwID, tar.szName)
				else
					local sha = hShaList:Lookup(tostring(dwID))
					if not sha then
						hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
						sha = hShaList:Lookup(tostring(dwID))
					end
					local r, g, b, a = 255,255,255,255
					local szTip = '> ' .. tar.szName .. ' <'
					sha:ClearTriangleFanPoint()
					sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
					sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
					sha:Show()
				end
			end
			local function OnPlayerLeave(dwID)
				if MY_ToolBox.bTongMemberHeadTipNav and Navigator_Remove then
					Navigator_Remove('MY_GUILDMEMBER_TIP.' .. dwID)
				else
					local sha = hShaList:Lookup(tostring(dwID))
					if sha then
						sha:Hide()
						table.insert(hShaList.freeShadows, sha)
					end
				end
			end
			for _, p in ipairs(LIB.GetNearPlayer()) do
				OnPlayerEnter(p.dwID)
			end
			LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_GUILDMEMBER_TIP', function(event) OnPlayerEnter(arg0) end)
			LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_GUILDMEMBER_TIP', function(event) OnPlayerLeave(arg0) end)
		else
			LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_GUILDMEMBER_TIP')
			LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_GUILDMEMBER_TIP')
			UI.GetShadowHandle('MY_TongMemberHeadTip'):Hide()
		end
	end

	-- 玩家名字变成link方便组队
	do
		LIB.RegisterEvent('OPEN_WINDOW.NAMELINKER', function(event)
			local h
			for _, p in ipairs({
				{'Normal/DialoguePanel', '', 'Handle_Message'},
				{'Lowest2/PlotDialoguePanel', 'Wnd_Dialogue', 'Handle_Dialogue'},
			}) do
				local frame = Station.Lookup(p[1])
				if frame and frame:IsVisible() then
					h = frame:Lookup(p[2], p[3])
					if h then
						break
					end
				end
			end
			if not h then
				return
			end
			for i = 0, h:GetItemCount() - 1 do
				local hItem = h:Lookup(i)
				if hItem:GetType() == 'Text' then
					local szText = hItem:GetText()
					for _, szPattern in ipairs(_L.NAME_PATTERN_LIST) do
						local _, _, szName = szText:find(szPattern)
						if szName then
							local nPos1, nPos2 = szText:find(szName)
							h:InsertItemFromString(i, true, GetFormatText(szText:sub(nPos2 + 1), hItem:GetFontScheme()))
							h:InsertItemFromString(i, true, GetFormatText('[' .. szText:sub(nPos1, nPos2) .. ']', nil, nil, nil, nil, nil, nil, 'namelink'))
							LIB.RenderChatLink(h:Lookup(i + 1))
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
	end

	-- 试炼之地九宫助手
	do
		LIB.RegisterEvent('OPEN_WINDOW.JIUGONG_HELPER', function(event)
			if LIB.IsShieldedVersion() then
				return
			end
			-- 确定当前对话对象是醉逍遥（18707）
			local target = GetTargetHandle(GetClientPlayer().GetTarget())
			if target and target.dwTemplateID ~= 18707 then
				return
			end
			local szText = arg1
			-- 匹配字符串
			string.gsub(szText, '<T1916><(T%d+)><T1926><(T%d+)><T1928><(T%d+)><T1924>.+<T1918><(T%d+)><T1931><(T%d+)><T1933><(T%d+)><T1935>.+<T1920><(T%d+)><T1937><(T%d+)><T1938><(T%d+)><T1939>', function(n1,n2,n3,n4,n5,n6,n7,n8,n9)
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
				LIB.Sysmsg({szText})
				OutputWarningMessage('MSG_WARNING_RED', szText, 10)
			end)
		end)
	end

	-- 防止神行CD被吃
	do
		if MY_ToolBox.bAvoidBlackShenxingCD then
			LIB.RegisterEvent('DO_SKILL_CAST.MY_TOOLBOX_AVOIDBLACKSHENXINGCD', function()
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
				LIB.Sysmsg({_L['Shenxing has been cancelled, cause you got the zhenyan.']})
				player.StopCurrentAction()
			end)
		else
			LIB.RegisterEvent('DO_SKILL_CAST.MY_TOOLBOX_AVOIDBLACKSHENXINGCD')
		end
	end

	-- 竞技场自动切换团队频道
	do
		if MY_ToolBox.bJJCAutoSwitchTalkChannel then
			LIB.RegisterEvent('LOADING_ENDING.MY_TOOLBOX_JJCAUTOSWITCHTALKCHANNEL', function()
				local bIsBattleField = (GetClientPlayer().GetScene().nType == MAP_TYPE.BATTLE_FIELD)
				local nChannel, szName = EditBox_GetChannel()
				if bIsBattleField and (nChannel == PLAYER_TALK_CHANNEL.RAID or nChannel == PLAYER_TALK_CHANNEL.TEAM) then
					_C.JJCAutoSwitchTalkChannel_OrgChannel = nChannel
					LIB.SwitchChat(PLAYER_TALK_CHANNEL.BATTLE_FIELD)
				elseif not bIsBattleField and nChannel == PLAYER_TALK_CHANNEL.BATTLE_FIELD then
					LIB.SwitchChat(_C.JJCAutoSwitchTalkChannel_OrgChannel or PLAYER_TALK_CHANNEL.RAID)
				end
			end)
		else
			LIB.RegisterEvent('LOADING_ENDING.MY_TOOLBOX_JJCAUTOSWITCHTALKCHANNEL')
		end
	end

	-- 长歌影子头顶次序
	do
		if MY_ToolBox.bChangGeShadow then
			local MAX_LIMIT_TIME = 25
			local hList, hItem, nCount, sha, r, g, b, nDis, szText, fPer
			local hShaList = UI.GetShadowHandle('MY_ChangGeShadow')
			local MAX_SHADOW_COUNT = 10
			local nInterval = (MY_ToolBox.bChangGeShadowDis or MY_ToolBox.bChangGeShadowCD) and 50 or 400
			LIB.BreatheCall('CHANGGE_SHADOW', nInterval, function()
				local frame = Station.Lookup('Lowest1/ChangGeShadow')
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
				hList = frame:Lookup('Wnd_Bar', 'Handle_Skill')
				nCount = hList:GetItemCount()
				for i = 0, nCount - 1 do
					hItem = hList:Lookup(i)
					sha = hShaList:Lookup(i)
					if not sha then
						hShaList:AppendItemFromString('<shadow></shadow>')
						sha = hShaList:Lookup(i)
					end
					nDis = LIB.GetDistance(GetNpc(hItem.nNpcID))
					if hItem.szState == 'disable' then
						r, g, b = 191, 31, 31
					else
						if nDis > 25 then
							r, g, b = 255, 255, 31
						else
							r, g, b = 63, 255, 31
						end
					end
					fPer = hItem:Lookup('Image_CD'):GetPercentage()
					szText = tostring(i + 1)
					if MY_ToolBox.bChangGeShadowDis and nDis >= 0 then
						szText = szText .. g_tStrings.STR_CONNECT .. KeepOneByteFloat(nDis) .. g_tStrings.STR_METER
					end
					if MY_ToolBox.bChangGeShadowCD then
						szText = szText .. g_tStrings.STR_CONNECT .. math.floor(fPer * MAX_LIMIT_TIME) .. '"'
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
			LIB.BreatheCall('CHANGGE_SHADOW', false)
			UI.GetShadowHandle('MY_ChangGeShadow'):Hide()
		end
	end

	-- 记录点名到密聊频道
	do
		if MY_ToolBox.bWhisperMetion then
			LIB.RegisterMsgMonitor('MY_RedirectMetionToWhisper', function(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
				local me = GetClientPlayer()
				if not me or me.dwID == dwTalkerID then
					return
				end
				local szText = "text=" .. EncodeComponentsString("[" .. me.szName .. "]")
				local nPos = StringFindW(szMsg, g_tStrings.STR_TALK_HEAD_SAY1)
				if nPos and StringFindW(szMsg, szText, nPos) then
					OutputMessage('MSG_WHISPER', szMsg, bRich, nFont, {r, g, b}, dwTalkerID, szName)
				end
			end, {
				'MSG_NORMAL', 'MSG_PARTY', 'MSG_MAP', 'MSG_BATTLE_FILED', 'MSG_GUILD', 'MSG_GUILD_ALLIANCE', 'MSG_SCHOOL', 'MSG_WORLD',
				'MSG_TEAM', 'MSG_CAMP', 'MSG_GROUP', 'MSG_SEEK_MENTOR', 'MSG_FRIEND', 'MSG_IDENTITY', 'MSG_SYS',
				'MSG_NPC_NEARBY', 'MSG_NPC_YELL', 'MSG_NPC_PARTY', 'MSG_NPC_WHISPER',
			})
			LIB.HookChatPanel('FILTER.MY_RedirectMetionToWhisper', function(h, szMsg, szChannel, dwTime)
				if h.__MY_LastMsg == szMsg and h.__MY_LastMsgChannel ~= szChannel and szChannel == 'MSG_WHISPER' then
					return false
				end
				h.__MY_LastMsg = szMsg
				h.__MY_LastMsgChannel = szChannel
				return true
			end)
		else
			LIB.HookChatPanel('FILTER.MY_RedirectMetionToWhisper', false)
			LIB.RegisterMsgMonitor('MY_RedirectMetionToWhisper')
		end
	end
end
LIB.RegisterInit('MY_TOOLBOX', MY_ToolBox.ApplyConfig)
-- 密码锁解锁提醒
LIB.RegisterInit('MY_LOCK_TIP', function()
	-- 刚进游戏好像获取不到锁状态 20秒之后再说吧
	LIB.DelayCall('MY_LOCK_TIP_DELAY', 20000, function()
		if not LIB.IsPhoneLock() then -- 手机密保还提示个鸡
			local state, nResetTime = Lock_State()
			if state == 'PASSWORD_LOCK' then
				LIB.DelayCall('MY_LOCK_TIP', 100000, function()
					local state, nResetTime = Lock_State()
					if state == 'PASSWORD_LOCK' then
						local me = GetClientPlayer()
						local szText = me and me.GetGlobalID and _L.LOCK_TIP[me.GetGlobalID()] or _L['You have been loged in for 2min, you can unlock bag locker now.']
						LIB.Sysmsg({szText})
						OutputWarningMessage('MSG_REWARD_GREEN', szText, 10)
					end
				end)
			end
		end
	end)
end)

-- 【台服用】老地图神行
do
local tNonwarData = {
	{ id =  8, x =   70, y =   5 }, -- 洛阳
	{ id = 11, x =   15, y = -90 }, -- 天策
	{ id = 12, x = -150, y = 110 }, -- 枫华
	{ id = 15, x = -450, y =  65 }, -- 长安
	{ id = 26, x =  -20, y =  90 }, -- 荻花宫
	{ id = 32, x =   50, y =  45 }, -- 小战宝
}
local function drawNonwarMap()
	if LIB.IsShieldedVersion() then
		return
	end
	local h = Station.Lookup('Topmost1/WorldMap/Wnd_All', 'Handle_CopyBtn')
	if not h or h.__MY_NonwarData or not h:IsVisible() then
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
			for _, v in ipairs(tNonwarData) do
				local bOpen = me.GetMapVisitFlag(v.id)
				local szFile, nFrame = 'ui/Image/MiddleMap/MapWindow.UITex', 41
				if bOpen then
					nFrame = 98
				end
				h:AppendItemFromString('<image>name="mynw_' .. v.id .. '" path='..EncodeComponentsString(szFile)..' frame='..nFrame..' eventid=341</image>')
				local img = h:Lookup(h:GetItemCount() - 1)
				img.bEnable = bOpen
				img.bSelect = bOpen and v.id ~= 26 and v.id ~= 32
				img.x = m.x + v.x
				img.y = m.y + v.y
				img.w, img.h = m.w, m.h
				img.id, img.mapid = v.id, v.id
				img.middlemapindex = 0
				img.name = Table_GetMapName(img.mapid)
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
	h.__MY_NonwarData = true
end
LIB.BreatheCall('MY_Toolbox#NonwarData', 130, drawNonwarMap)
end

-- 【台服用】强开所有地图
do
local h, hList, hItem
local function openAllMap()
	if LIB.IsShieldedVersion() then
		return
	end
	h = Station.Lookup('Topmost1/WorldMap/Wnd_All', '')
	if not h or not h:IsVisible() then
		return
	end
	local me = GetClientPlayer()
	local dwCurrMapID = me and me.GetScene().dwMapID
	for _, szHandleName in ipairs({
		'Handle_CityBtn',
		'Handle_CopyBtn',
	}) do
		hList = h:Lookup(szHandleName)
		if hList then
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if hItem.mapid == 1 or dwCurrMapID == hItem.mapid then
					hItem.mapid = tostring(hItem.mapid)
				else
					hItem.mapid = tonumber(hItem.mapid) or hItem.mapid
				end
				hItem.bEnable = true
			end
		end
	end
	h, hList, hItem = nil
end
LIB.BreatheCall('MY_Toolbox#OpenAllMap', 130, openAllMap)
end

-- 大战没交
local m_aBigWars = { 19191, 19192, 19195, 19196, 19197 }
LIB.RegisterFrameCreate('ExitPanel.BIG_WAR_CHECK', function(name, frame)
	local me = GetClientPlayer()
	if me then
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
					local ui = UI(frame)
					if ui:children('#Text_MY_Tip'):count() == 0 then
						ui:append('Text', { name = 'Text_MY_Tip',y = ui:height(), w = ui:width(), color = {255, 255, 0}, font = 199, halign = 1})
					end
					ui = ui:children('#Text_MY_Tip'):text(_L['Warning: Bigwar has been finished but not handed yet!']):shake(10, 10, 10, 1000)
					break
				end
			end
		end
	end
end)

-- auto restore team authourity info in arena
do local l_tTeamInfo, l_bConfigEnd
LIB.RegisterEvent('ARENA_START', function() l_bConfigEnd = true end)
LIB.RegisterEvent('LOADING_ENDING', function() l_bConfigEnd = false end)
LIB.RegisterEvent('PARTY_DELETE_MEMBER', function() l_bConfigEnd = false end)
local function RestoreTeam()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not l_tTeamInfo
	or not MY_ToolBox.bRestoreAuthorityInfo
	or not LIB.IsLeader()
	or not me.IsInParty() or not LIB.IsInArena() then
		return
	end
	LIB.SetTeamInfo(l_tTeamInfo)
end
LIB.RegisterEvent('PARTY_ADD_MEMBER', RestoreTeam)

local function SaveTeam()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me.IsInParty() or not LIB.IsInArena() or l_bConfigEnd then
		return
	end
	l_tTeamInfo = LIB.GetTeamInfo()
end
LIB.RegisterEvent({'TEAM_AUTHORITY_CHANGED', 'PARTY_SET_FORMATION_LEADER', 'TEAM_CHANGE_MEMBER_GROUP'}, SaveTeam)
end

-- 进入JJC自动显示所有人物
do local l_bHideNpc, l_bHidePlayer, l_bShowParty, l_lock
LIB.RegisterEvent('ON_REPRESENT_CMD', function()
	if l_lock then
		return
	end
	if arg0 == 'show npc' or arg0 == 'hide npc' then
		l_bHideNpc = arg0 == 'hide npc'
	elseif arg0 == 'show player' or arg0 == 'hide player' then
		l_bHidePlayer = arg0 == 'hide player'
	elseif arg0 == 'show or hide party player 0' or 'show or hide party player 1' then
		l_bShowParty = arg0 == 'show or hide party player 1'
	end
end)
LIB.RegisterEvent('LOADING_END', function()
	if not MY_ToolBox.bAutoShowInArena then
		return
	end
	if LIB.IsInArena() or LIB.IsInBattleField() then
		l_lock = true
		rlcmd('show npc')
		rlcmd('show player')
		rlcmd('show or hide party player 0')
	else
		l_lock = true
		if l_bHideNpc then
			rlcmd('hide npc')
		else
			rlcmd('show npc')
		end
		if l_bHidePlayer then
			rlcmd('hide player')
		else
			rlcmd('show player')
		end
		if l_bShowParty then
			rlcmd('show or hide party player 1')
		else
			rlcmd('show or hide party player 0')
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
	{ nChannel = PLAYER_TALK_CHANNEL.LOCAL_SYS, szName = _L['system channel'], rgb = GetMsgFontColor('MSG_SYS'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TEAM     , szName = _L['team channel']  , rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.RAID     , szName = _L['raid channel']  , rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG     , szName = _L['tong channel']  , rgb = GetMsgFontColor('MSG_GUILD' , true) },
}
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 30
	local x, y = X, Y

	-- 检测附近共战
	ui:append('WndButton', 'WndButton_GongzhanCheck'):children('#WndButton_GongzhanCheck')
	  :pos(w - 140, y):width(120)
	  :text(_L['check nearby gongzhan'])
	  :lclick(function()
	  	local tGongZhans = {}
	  	for _, p in ipairs(LIB.GetNearPlayer()) do
	  		for _, buff in pairs(LIB.GetBuffList(p)) do
	  			if (not buff.bCanCancel) and string.find(Table_GetBuffName(buff.dwID, buff.nLevel), _L['GongZhan']) ~= nil then
	  				table.insert(tGongZhans, {p = p, time = (buff.nEndFrame - GetLogicFrameCount()) / 16})
	  			end
	  		end
	  	end
	  	local nChannel = MY_ToolBox.nGongzhanPublishChannel or PLAYER_TALK_CHANNEL.LOCAL_SYS
	  	LIB.Talk(nChannel, _L['------------------------------------'])
	  	for _, r in ipairs(tGongZhans) do
	  		LIB.Talk( nChannel, _L('Detected [%s] has GongZhan buff for %d sec(s).', r.p.szName, r.time) )
	  	end
	  	LIB.Talk(nChannel, _L('Nearby GongZhan Total Count: %d.', #tGongZhans))
	  	LIB.Talk(nChannel, _L['------------------------------------'])
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
	ui:append('WndCheckBox', {
		x = x, y = y, w = 180,
		text = _L['friend headtop tips'],
		checked = MY_ToolBox.bFriendHeadTip,
		oncheck = function(bCheck)
			MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
			MY_ToolBox.ApplyConfig()
		end,
	})
	ui:append('WndCheckBox', {
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
	ui:append('WndCheckBox', {
		x = x, y = y, w = 180,
		text = _L['tong member headtop tips'],
		checked = MY_ToolBox.bTongMemberHeadTip,
		oncheck = function(bCheck)
			MY_ToolBox.bTongMemberHeadTip = not MY_ToolBox.bTongMemberHeadTip
			MY_ToolBox.ApplyConfig()
		end,
	})
	ui:append('WndCheckBox', {
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
		ui:append('WndCheckBox', {
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
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['visual skill'],
		checked = MY_VisualSkill.bEnable,
		oncheck = function(bChecked)
			MY_VisualSkill.bEnable = bChecked
			MY_VisualSkill.Reload()
		end,
	}, true):width() + 5

	ui:append('WndTrackbar', {
		x = x, y = y,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = {1, 32},
		value = MY_VisualSkill.nVisualSkillBoxCount,
		text = _L('display %d skills.', MY_VisualSkill.nVisualSkillBoxCount),
		textfmt = function(val) return _L('display %d skills.', val) end,
		onchange = function(val)
			MY_VisualSkill.nVisualSkillBoxCount = val
			MY_VisualSkill.Reload()
		end,
	})
	x = X
	y = y + 30

	-- 防止神行CD被黑
	ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['avoid blacking shenxing cd'],
		checked = MY_ToolBox.bAvoidBlackShenxingCD,
		oncheck = function(bChecked)
			MY_ToolBox.bAvoidBlackShenxingCD = bChecked
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 自动隐藏聊天栏
	ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto hide chat panel'],
		checked = MY_AutoHideChat.bAutoHideChatPanel,
		oncheck = function(bChecked)
			MY_AutoHideChat.bAutoHideChatPanel = bChecked
			MY_AutoHideChat.ApplyConfig()
		end,
	})
	y = y + 30

	-- 记录点名到密聊频道
	ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Redirect metion to whisper'],
		checked = MY_ToolBox.bWhisperMetion,
		oncheck = function(bChecked)
			MY_ToolBox.bWhisperMetion = bChecked
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 竞技场频道切换
	ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto switch talk channel when into battle field'],
		checked = MY_ToolBox.bJJCAutoSwitchTalkChannel,
		oncheck = function(bChecked)
			MY_ToolBox.bJJCAutoSwitchTalkChannel = bChecked
			MY_ToolBox.ApplyConfig()
		end,
	})
	y = y + 30

	-- 竞技场自动恢复队伍信息
	ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto restore team info in arena'],
		checked = MY_ToolBox.bRestoreAuthorityInfo,
		oncheck = function(bChecked)
			MY_ToolBox.bRestoreAuthorityInfo = bChecked
		end,
	})
	y = y + 30

	-- 竞技场战场自动取消屏蔽
	ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['auto cancel hide player in arena and battlefield'],
		checked = MY_ToolBox.bAutoShowInArena,
		oncheck = function(bChecked)
			MY_ToolBox.bAutoShowInArena = bChecked
		end,
	})
	y = y + 30

	-- 长歌影子顺序
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
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
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}, true):width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
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
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}, true):width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, w = 'auto',
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
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}, true):width() + 5
	ui:append('WndTrackbar', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('scale: %d%%.', val) end,
		range = {10, 800},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = MY_ToolBox.fChangeGeShadowScale * 100,
		onchange = function(val)
			MY_ToolBox.fChangeGeShadowScale = val / 100
		end,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	})
	x = X
	y = y + 30

	-- 随身便笺
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Memo (Role)'],
		checked = MY_Memo.IsEnable(false),
		oncheck = function(bChecked)
			MY_Memo.Toggle(false, bChecked)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndButton', {
		x = x, y = y,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				MY_Memo.SetFont(false, nFont)
			end)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Memo (Global)'],
		checked = MY_Memo.IsEnable(true),
		oncheck = function(bChecked)
			MY_Memo.Toggle(true, bChecked)
		end,
	}, true):autoWidth():width() + 5

	x = x + ui:append('WndButton', {
		x = x, y = y,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				MY_Memo.SetFont(true, nFont)
			end)
		end,
	}, true):autoWidth():width() + 5
	y = y + 30

	x = X
end
LIB.RegisterPanel( 'MY_ToolBox', _L['toolbox'], _L['General'], 'UI/Image/Common/Money.UITex|243', PS)

do
local TARGET_TYPE, TARGET_ID
local function onHotKey()
	if TARGET_TYPE then
		LIB.SetTarget(TARGET_TYPE, TARGET_ID)
		TARGET_TYPE, TARGET_ID = nil
	else
		TARGET_TYPE, TARGET_ID = LIB.GetTarget()
		LIB.SetTarget(TARGET.PLAYER, UI_GetClientPlayerID())
	end
end
LIB.RegisterHotKey('MY_AutoLoopMeAndTarget', _L['Loop target between me and target'], onHotKey)
end
