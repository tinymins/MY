--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌì¸¨Öú
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
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
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatCopy'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
MY_ChatCopy = {}
MY_ChatCopy.bChatCopy = true
MY_ChatCopy.bChatTime = true
MY_ChatCopy.eChatTime = 'HOUR_MIN_SEC'
MY_ChatCopy.bChatCopyAlwaysShowMask = false
MY_ChatCopy.bChatCopyAlwaysWhite = false
MY_ChatCopy.bChatCopyNoCopySysmsg = false
RegisterCustomData('MY_ChatCopy.bChatCopy')
RegisterCustomData('MY_ChatCopy.bChatTime')
RegisterCustomData('MY_ChatCopy.eChatTime')
RegisterCustomData('MY_ChatCopy.bChatCopyAlwaysShowMask')
RegisterCustomData('MY_ChatCopy.bChatCopyAlwaysWhite')
RegisterCustomData('MY_ChatCopy.bChatCopyNoCopySysmsg')

local function onNewChatLine(h, i, szMsg, szChannel, dwTime, nR, nG, nB)
	if szMsg and i and h:GetItemCount() > i and (MY_ChatCopy.bChatTime or MY_ChatCopy.bChatCopy) then
		-- chat time
		-- check if timestrap can insert
		if MY_ChatCopy.bChatCopyNoCopySysmsg and szChannel == 'SYS_MSG' then
			return
		end
		-- create timestrap text
		local szTime = ''
		for ii = i, h:GetItemCount() - 1 do
			local el = h:Lookup(i)
			if el:GetType() == 'Text' and not el:GetName():find('^namelink_%d+$') then
				nR, nG, nB = el:GetFontColor()
				break
			end
		end
		if MY_ChatCopy.bChatCopy and (MY_ChatCopy.bChatCopyAlwaysShowMask or not MY_ChatCopy.bChatTime) then
			local _r, _g, _b = nR, nG, nB
			if MY_ChatCopy.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = LIB.GetCopyLinkText(_L[' * '], { r = _r, g = _g, b = _b })
		elseif MY_ChatCopy.bChatCopyAlwaysWhite then
			nR, nG, nB = 255, 255, 255
		end
		if MY_ChatCopy.bChatTime then
			if MY_ChatCopy.eChatTime == 'HOUR_MIN_SEC' then
				szTime = szTime .. LIB.GetTimeLinkText(dwTime, {r = nR, g = nG, b = nB, f = 10, s = '[%hh:%mm:%ss]'})
			else
				szTime = szTime .. LIB.GetTimeLinkText(dwTime, {r = nR, g = nG, b = nB, f = 10, s = '[%hh:%mm]'})
			end
		end
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end
LIB.HookChatPanel('AFTER.MY_ChatCopy', onNewChatLine)
