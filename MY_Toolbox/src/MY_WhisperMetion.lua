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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
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
LIB.RegisterInit('MY_WhisperMetion', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Redirect metion to whisper'],
		checked = MY_WhisperMetion.bEnable,
		oncheck = function(bChecked)
			MY_WhisperMetion.bEnable = bChecked
		end,
	})
	y = y + 25
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
