--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌì¸¨Öú
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, XpCall = LIB.GetTraceback, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_ChatCopy/lang/')
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
				szTime = szTime .. LIB.GetTimeLinkText({r = nR, g = nG, b = nB, f = 10, s = '[hh:mm:ss]'}, dwTime)
			else
				szTime = szTime .. LIB.GetTimeLinkText({r = nR, g = nG, b = nB, f = 10, s = '[hh:mm]'}, dwTime)
			end
		end
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end
LIB.HookChatPanel('AFTER.MY_ChatCopy', onNewChatLine)
