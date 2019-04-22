--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天过滤
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_ChatFilter/lang/')
if not LIB.AssertVersion('MY_ChatFilter', _L['MY_ChatFilter'], 0x2011800) then
	return
end
MY_ChatFilter = {}
local _C = {}
local MY_ChatFilter = MY_ChatFilter
local MAX_CHAT_RECORD = 10
local MAX_UUID_RECORD = 10
MY_ChatFilter.bFilterDuplicate           = true   -- 屏蔽重复聊天
MY_ChatFilter.bFilterDuplicateIgnoreID   = false  -- 不同玩家重复聊天也屏蔽
MY_ChatFilter.bFilterDuplicateContinuous = true   -- 仅屏蔽连续的重复聊天
MY_ChatFilter.bFilterDuplicateAddonTalk  = true   -- 屏蔽UUID相同的插件消息
RegisterCustomData('MY_ChatFilter.bFilterDuplicate')
RegisterCustomData('MY_ChatFilter.bFilterDuplicateIgnoreID')
RegisterCustomData('MY_ChatFilter.bFilterDuplicateContinuous')
RegisterCustomData('MY_ChatFilter.bFilterDuplicateAddonTalk')

MY_ChatFilter.tApplyDuplicateChannels = {
	['MSG_SYS'           ] = false,
	['MSG_NORMAL'        ] = true,
	['MSG_PARTY'         ] = false,
	['MSG_MAP'           ] = true,
	['MSG_BATTLE_FILED'  ] = true,
	['MSG_GUILD'         ] = true,
	['MSG_GUILD_ALLIANCE'] = true,
	['MSG_SCHOOL'        ] = true,
	['MSG_WORLD'         ] = true,
	['MSG_TEAM'          ] = false,
	['MSG_CAMP'          ] = true,
	['MSG_GROUP'         ] = true,
	['MSG_WHISPER'       ] = false,
	['MSG_SEEK_MENTOR'   ] = true,
	['MSG_FRIEND'        ] = false,
}
for k, _ in pairs(MY_ChatFilter.tApplyDuplicateChannels) do
	RegisterCustomData('MY_ChatFilter.tApplyDuplicateChannels.' .. k)
end

local l_tChannelHeader = {
	['MSG_WHISPER'] = g_tStrings.STR_TALK_HEAD_SAY,
	['MSG_NORMAL'] = g_tStrings.STR_TALK_HEAD_SAY,
	['MSG_NPC_NEARBY'] = g_tStrings.STR_TALK_HEAD_SAY,
	['MSG_PARTY'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_GUILD'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_GUILD_ALLIANCE'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_WORLD'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_SCHOOL'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_CAMP'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_FRIEND'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_TEAM'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_MAP'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_BATTLE_FILED'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_NPC_PARTY'] = g_tStrings.STR_TALK_HEAD_SAY1,
}

LIB.HookChatPanel('FILTER.MY_ChatFilter', function(h, szMsg, szChannel, dwTime)
	-- 插件消息UUID过滤
	if MY_ChatFilter.bFilterDuplicateAddonTalk then
		local me = GetClientPlayer()
		local tSay = LIB.FormatChatContent(szMsg)
		if not h.MY_tDuplicateUUID then
			h.MY_tDuplicateUUID = {}
		end
		for _, element in ipairs(tSay) do
			if element.type == 'eventlink' and element.name == '' then
				local data = LIB.JsonDecode(element.linkinfo)
				if data and data.uuid then
					local szUUID = data.uuid
					if szUUID then
						for k, uuid in pairs(h.MY_tDuplicateUUID) do
							if uuid == szUUID then
								return false
							end
						end
						table.insert(h.MY_tDuplicateUUID, 1, szUUID)
						local nCount = #h.MY_tDuplicateUUID - MAX_UUID_RECORD
						if nCount > 0 then
							for i = nCount, 1, -1 do
								table.remove(h.MY_tDuplicateUUID)
							end
						end
					end
				end
			end
		end
	end
	-- 重复内容刷屏屏蔽（系统频道除外）
	if MY_ChatFilter.bFilterDuplicate
	and MY_ChatFilter.tApplyDuplicateChannels[szChannel] then
		-- 计算过滤记录
		local szText, szName = GetPureText(szMsg), ''
		if l_tChannelHeader[szChannel] then
			local nS, nE = wstring.find(szText, l_tChannelHeader[szChannel])
			if nS and nE then
				szName = ''
				szText:sub(1, nE):gsub('(%[[^%[%]]-%])', function(s)
					szName = szName .. s
				end)
				szText = szText:sub(nE + 1)
			end
		end
		szText = szText:gsub('[ \n]', '')
		if szText == '' then -- 纯表情纯链接就不屏蔽了
			return true
		end
		if not MY_ChatFilter.bFilterDuplicateIgnoreID then
			szText = szName .. ':' .. szText
		end
		-- 判断是否需要过滤
		if not h.MY_tDuplicateLog then
			h.MY_tDuplicateLog = {}
		elseif MY_ChatFilter.bFilterDuplicateContinuous then
			if h.MY_tDuplicateLog[1] == szText then
				return false
			end
			h.MY_tDuplicateLog[1] = szText
		else
			for i, szRecord in ipairs(h.MY_tDuplicateLog) do
				if szRecord == szText then
					return false
				end
			end
			table.insert(h.MY_tDuplicateLog, 1, szText)
			local nCount = #h.MY_tDuplicateLog - MAX_CHAT_RECORD
			if nCount > 0 then
				for i = nCount, 1, -1 do
					table.remove(h.MY_tDuplicateLog)
				end
			end
		end
	end
	return true
end)

LIB.RegisterPanel('MY_DuplicateChatFilter', _L['duplicate chat filter'], _L['Chat'],
'ui/Image/UICommon/yirong3.UITex|104', {OnPanelActive = function(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30

	ui:append('WndCheckBox', {
		text = _L['filter duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicate,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicate = bCheck
		end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		text = _L['filter duplicate chat ignore id'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateIgnoreID,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateIgnoreID = bCheck
		end,
	})
	y = y + 30

	ui:append('WndCheckBox', {
		text = _L['only filter continuous duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateContinuous,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateContinuous = bCheck
		end,
	})
	y = y + 30

	ui:append('WndComboBox', {
		x = x, y = y, w = 330, h = 25,
		menu = function()
			local t = {}
			for szChannelID, bFilter in pairs(MY_ChatFilter.tApplyDuplicateChannels) do
				table.insert(t, {
					szOption = g_tStrings.tChannelName[szChannelID],
					bCheck = true, bChecked = bFilter,
					rgb = GetMsgFontColor(szChannelID, true),
					fnAction = function()
						MY_ChatFilter.tApplyDuplicateChannels[szChannelID] = not MY_ChatFilter.tApplyDuplicateChannels[szChannelID]
					end,
				})
			end
			return t
		end,
		text = _L['select duplicate channels'],
	})
	y = y + 50

	ui:append('WndCheckBox', {
		text = _L['filter duplicate addon message'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateAddonTalk,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateAddonTalk = bCheck
		end,
	})
	y = y + 30
end})
