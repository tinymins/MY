--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 分享NPC对话框
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_!Base'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_!Base'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '*') then
	return
end
--------------------------------------------------------------------------
local SHARE_NPC_CHAT_FILE = {'temporary/share-npc-chat.jx3dat', PATH_TYPE.GLOBAL}
local SHARE_NPC_CHAT = LIB.LoadLUAData(SHARE_NPC_CHAT_FILE) -- NPC上报对话模板表（远程）

LIB.RegisterInit('MY_ShareChat__Npc', function()
	if not SHARE_NPC_CHAT then
		LIB.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = 'https://pull.j3cx.com/config/npc-chat'
				.. '?l=' .. AnsiToUTF8(GLOBAL.GAME_LANG)
				.. '&L=' .. AnsiToUTF8(GLOBAL.GAME_EDITION)
				.. '&_=' .. GetCurrentTime(),
			success = function(html, status)
				local data = LIB.JsonDecode(html)
				if IsTable(data) then
					SHARE_NPC_CHAT = {}
					for _, dwTemplateID in ipairs(data) do
						SHARE_NPC_CHAT[dwTemplateID] = true
					end
					LIB.SaveLUAData(SHARE_NPC_CHAT_FILE, SHARE_NPC_CHAT)
				end
			end,
		})
	end
end)

LIB.RegisterEvent('OPEN_WINDOW.MY_ShareChat__Npc', function()
	if not MY_Serendipity.bEnable then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwTargetID = arg3
	local npc = GetNpc(dwTargetID)
	local bShare = npc and SHARE_NPC_CHAT and SHARE_NPC_CHAT[npc.dwTemplateID]
	if not bShare then
		return
	end
	local szContent = arg1
	local map = LIB.GetMapInfo(me.GetMapID())
	local szDelayID
	local function fnAction(line)
		LIB.EnsureAjax({
			url = 'https://push.j3cx.com/api/npc-chat?'
				.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
					l = AnsiToUTF8(GLOBAL.GAME_LANG),
					L = AnsiToUTF8(GLOBAL.GAME_EDITION),
					r = AnsiToUTF8(LIB.GetRealServer(1)), -- Region
					s = AnsiToUTF8(LIB.GetRealServer(2)), -- Server
					c = AnsiToUTF8(szContent), -- Content
					t = GetCurrentTime(), -- Time
					cn = line and AnsiToUTF8(line.szCenterName) or '', -- Center Name
					ci = line and line.dwCenterID or -1, -- Center ID
					li = line and line.nLineIndex or -1, -- Line Index
					mi = map and map.dwID, -- Map ID
					mn = map and AnsiToUTF8(map.szName), -- Map Name
					nt = npc.dwTemplateID, -- NPC Template ID
					nn = LIB.GetObjectName(npc), -- NPC Name
				}, 'MY_huadfiuadfioadfios178291hsy')))
			})
		LIB.DelayCall(szDelayID, false)
	end
	szDelayID = LIB.DelayCall(5000, fnAction)
	LIB.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex }, fnAction)
end)

--------------------------------------------------------------------------
local SHARE_SYSMSG_FILE = {'temporary/share-sysmsg.jx3dat', PATH_TYPE.GLOBAL} -- 系统信息上报模板表（远程）
local SHARE_SYSMSG = LIB.LoadLUAData(SHARE_SYSMSG_FILE) -- 系统信息上报模板表（远程）

LIB.RegisterInit('MY_ShareChat__Sysmsg', function()
	if not SHARE_SYSMSG then
		LIB.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = 'https://pull.j3cx.com/config/share-sysmsg'
				.. '?l=' .. AnsiToUTF8(GLOBAL.GAME_LANG)
				.. '&L=' .. AnsiToUTF8(GLOBAL.GAME_EDITION)
				.. '&_=' .. GetCurrentTime(),
			success = function(html, status)
				local data = LIB.JsonDecode(html)
				if IsTable(data) then
					SHARE_SYSMSG = {}
					for _, szPattern in ipairs(data) do
						if IsString(szPattern) then
							insert(SHARE_SYSMSG, szPattern)
						end
					end
					LIB.SaveLUAData(SHARE_SYSMSG_FILE, SHARE_SYSMSG)
				end
			end,
		})
	end
end)

LIB.RegisterMsgMonitor('MSG_SYS.MY_ShareChat__Sysmsg', function(szChannel, szMsg, nFont, bRich, r, g, b)
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not SHARE_SYSMSG then
		return
	end
	-- 跨服中免打扰
	if IsRemotePlayer(me.dwID) then
		return
	end
	-- 确认是真实系统消息
	if LIB.ContainsEchoMsgHeader(szMsg) then
		return
	end
	-- OutputMessage('MSG_SYS', "<image>path=\"UI/Image/Minimap/Minimap.UITex\" frame=184</image><text>text=\"“一只蠢盾盾”侠士正在为人传功，不经意间触发奇遇【雪山恩仇】！正是：侠心义行，偏遭奇症缠身；雪峰疗伤，却逢绝世奇缘。\" font=10 r=255 g=255 b=0 </text><text>text=\"\\\n\"</text>", true)
	-- “醉戈止战”侠士福缘非浅，触发奇遇【阴阳两界】，此千古奇缘将开启怎样的奇妙际遇，令人神往！
	-- 恭喜侠士江阙阙在25人英雄会战唐门中获得稀有掉落[夜话·白鹭]！
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	for _, szPattern in ipairs(SHARE_SYSMSG) do
		if find(szMsg, szPattern) then
			LIB.EnsureAjax({
				url = 'https://push.j3cx.com/api/share-sysmsg?'
					.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
						l = AnsiToUTF8(GLOBAL.GAME_LANG),
						L = AnsiToUTF8(GLOBAL.GAME_EDITION),
						regin = AnsiToUTF8(LIB.GetRealServer(1)), -- Region
						server = AnsiToUTF8(LIB.GetRealServer(2)), -- Server
						content = AnsiToUTF8(szMsg), -- Content
						time = GetCurrentTime(), -- Time
					}, '89eb9924-e683-4302-a007-8d53b25fd9d1')))
				})
			return
		end
	end
end)
