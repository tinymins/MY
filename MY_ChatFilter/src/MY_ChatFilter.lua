--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天过滤
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ChatFilter'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatFilter'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
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
	local aXMLNode, aSay
	-- 插件消息UUID过滤
	if MY_ChatFilter.bFilterDuplicateAddonTalk then
		if not aXMLNode then
			aXMLNode = LIB.XMLDecode(szMsg)
			aSay = LIB.ParseChatData(aXMLNode)
		end
		if not h.MY_tDuplicateUUID then
			h.MY_tDuplicateUUID = {}
		end
		for _, element in ipairs(aSay) do
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
						insert(h.MY_tDuplicateUUID, 1, szUUID)
						local nCount = #h.MY_tDuplicateUUID - MAX_UUID_RECORD
						if nCount > 0 then
							for i = nCount, 1, -1 do
								remove(h.MY_tDuplicateUUID)
							end
						end
					end
				end
			end
		end
	end
	-- 重复内容刷屏屏蔽（系统频道除外）
	if szChannel == 'MSG_SYS' and LIB.ContainsEchoMsgHeader(szMsg) then
		if not aXMLNode then
			aXMLNode = LIB.XMLDecode(szMsg)
			aSay = LIB.ParseChatData(aXMLNode)
		end
		local bHasEcho, szEchoChannel = LIB.DecodeEchoMsgHeader(aXMLNode)
		if bHasEcho and szEchoChannel then
			szChannel = szEchoChannel
		end
	end
	if MY_ChatFilter.bFilterDuplicate
	and MY_ChatFilter.tApplyDuplicateChannels[szChannel] then
		if not aXMLNode then
			aXMLNode = LIB.XMLDecode(szMsg)
			aSay = LIB.ParseChatData(aXMLNode)
		end
		-- 解析聊天纯字符串
		local szText = LIB.StringifyChatText(aSay)
		-- 解析发言人名字
		local szName = ''
		if l_tChannelHeader[szChannel] then
			local nS, nE = wfind(szText, l_tChannelHeader[szChannel])
			if nS and nE then
				szName = ''
				szText:sub(1, nE):gsub('(%[[^%[%]]-%])', function(s)
					szName = szName .. s
				end)
				szText = szText:sub(nE + 1)
			end
		end
		szText = szText:gsub('[ \n]', '')
		-- 判断是否区分发言者
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
			insert(h.MY_tDuplicateLog, 1, szText)
			local nCount = #h.MY_tDuplicateLog - MAX_CHAT_RECORD
			if nCount > 0 then
				for i = nCount, 1, -1 do
					remove(h.MY_tDuplicateLog)
				end
			end
		end
	end
	return true
end)

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 20, 30

	ui:Append('WndCheckBox', {
		text = _L['filter duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicate,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicate = bCheck
		end,
	})
	y = y + 30

	ui:Append('WndCheckBox', {
		text = _L['filter duplicate chat ignore id'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateIgnoreID,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateIgnoreID = bCheck
		end,
	})
	y = y + 30

	ui:Append('WndCheckBox', {
		text = _L['only filter continuous duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateContinuous,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateContinuous = bCheck
		end,
	})
	y = y + 30

	ui:Append('WndComboBox', {
		x = x, y = y, w = 330, h = 25,
		menu = function()
			local t = {}
			for szChannelID, bFilter in pairs(MY_ChatFilter.tApplyDuplicateChannels) do
				insert(t, {
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

	ui:Append('WndCheckBox', {
		text = _L['filter duplicate addon message'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateAddonTalk,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateAddonTalk = bCheck
		end,
	})
	y = y + 30
end

LIB.RegisterPanel(_L['Chat'], 'MY_DuplicateChatFilter', _L['duplicate chat filter'], 'ui/Image/UICommon/yirong3.UITex|104', PS)
