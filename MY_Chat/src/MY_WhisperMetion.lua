--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 记录点名到密聊频道
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Chat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = true,
}
RegisterCustomData('MY_WhisperMetion.bEnable')

function D.Apply()
	if O.bEnable then
		LIB.RegisterMsgMonitor({
			'MSG_NORMAL.MY_RedirectMetionToWhisper',
			'MSG_PARTY.MY_RedirectMetionToWhisper',
			'MSG_MAP.MY_RedirectMetionToWhisper',
			'MSG_BATTLE_FILED.MY_RedirectMetionToWhisper',
			'MSG_GUILD.MY_RedirectMetionToWhisper',
			'MSG_GUILD_ALLIANCE.MY_RedirectMetionToWhisper',
			'MSG_SCHOOL.MY_RedirectMetionToWhisper',
			'MSG_WORLD.MY_RedirectMetionToWhisper',
			'MSG_TEAM.MY_RedirectMetionToWhisper',
			'MSG_CAMP.MY_RedirectMetionToWhisper',
			'MSG_GROUP.MY_RedirectMetionToWhisper',
			'MSG_SEEK_MENTOR.MY_RedirectMetionToWhisper',
			'MSG_FRIEND.MY_RedirectMetionToWhisper',
			'MSG_IDENTITY.MY_RedirectMetionToWhisper',
			'MSG_SYS.MY_RedirectMetionToWhisper',
			'MSG_NPC_NEARBY.MY_RedirectMetionToWhisper',
			'MSG_NPC_YELL.MY_RedirectMetionToWhisper',
			'MSG_NPC_PARTY.MY_RedirectMetionToWhisper',
			'MSG_NPC_WHISPER.MY_RedirectMetionToWhisper',
		}, function(szChannel, szMsg, nFont, bRich, r, g, b, dwTalkerID, szName)
			local me = GetClientPlayer()
			if not me or me.dwID == dwTalkerID then
				return
			end
			local szText = "text=" .. EncodeComponentsString("[" .. me.szName .. "]")
			local nPos = StringFindW(szMsg, g_tStrings.STR_TALK_HEAD_SAY1)
			if nPos and StringFindW(szMsg, szText, nPos) then
				OutputMessage('MSG_WHISPER', szMsg, bRich, nFont, {r, g, b}, dwTalkerID, szName)
			end
		end)
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
		LIB.RegisterMsgMonitor('MSG_NORMAL.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_PARTY.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_MAP.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_BATTLE_FILED.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_GUILD.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_GUILD_ALLIANCE.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_SCHOOL.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_WORLD.MY_RedirectMetionToWhisper',false)
		LIB.RegisterMsgMonitor('MSG_TEAM.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_CAMP.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_GROUP.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_SEEK_MENTOR.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_FRIEND.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_IDENTITY.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_SYS.MY_RedirectMetionToWhisper',false)
		LIB.RegisterMsgMonitor('MSG_NPC_NEARBY.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_NPC_YELL.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_NPC_PARTY.MY_RedirectMetionToWhisper', false)
		LIB.RegisterMsgMonitor('MSG_NPC_WHISPER.MY_RedirectMetionToWhisper',false)
	end
end
LIB.RegisterInit('MY_WhisperMetion', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, lineHeight)
	x = X
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Redirect metion to whisper'],
		checked = MY_WhisperMetion.bEnable,
		oncheck = function(bChecked)
			MY_WhisperMetion.bEnable = bChecked
		end,
	})
	y = y + lineHeight
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			triggers = {
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_WhisperMetion = LIB.GeneGlobalNS(settings)
end
