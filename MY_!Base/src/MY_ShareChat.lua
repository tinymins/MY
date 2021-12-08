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
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_!Base'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_!Base'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '*') then
	return
end
--------------------------------------------------------------------------
local SHARE_NPC_CHAT_FILE = {'temporary/share-npc-chat.jx3dat', X.PATH_TYPE.GLOBAL}
local SHARE_NPC_CHAT = X.LoadLUAData(SHARE_NPC_CHAT_FILE) -- NPC上报对话模板表（远程）

X.RegisterInit('MY_ShareChat__Npc', function()
	if not SHARE_NPC_CHAT then
		X.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = 'https://pull.j3cx.com/config/npc-chat'
				.. '?l=' .. AnsiToUTF8(GLOBAL.GAME_LANG)
				.. '&L=' .. AnsiToUTF8(GLOBAL.GAME_EDITION)
				.. '&_=' .. GetCurrentTime(),
			success = function(html, status)
				local data = X.JsonDecode(html)
				if X.IsTable(data) then
					SHARE_NPC_CHAT = {}
					for _, dwTemplateID in ipairs(data) do
						SHARE_NPC_CHAT[dwTemplateID] = true
					end
					X.SaveLUAData(SHARE_NPC_CHAT_FILE, SHARE_NPC_CHAT)
				end
			end,
		})
	end
end)

X.RegisterEvent('OPEN_WINDOW', 'MY_ShareChat__Npc', function()
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
	local map = X.GetMapInfo(me.GetMapID())
	local szDelayID
	local function fnAction(line)
		X.EnsureAjax({
			url = 'https://push.j3cx.com/api/npc-chat?'
				.. X.EncodePostData(X.UrlEncode(X.SignPostData({
					l = AnsiToUTF8(GLOBAL.GAME_LANG),
					L = AnsiToUTF8(GLOBAL.GAME_EDITION),
					r = AnsiToUTF8(X.GetRealServer(1)), -- Region
					s = AnsiToUTF8(X.GetRealServer(2)), -- Server
					c = AnsiToUTF8(szContent), -- Content
					t = GetCurrentTime(), -- Time
					cn = line and AnsiToUTF8(line.szCenterName) or '', -- Center Name
					ci = line and line.dwCenterID or -1, -- Center ID
					li = line and line.nLineIndex or -1, -- Line Index
					mi = map and map.dwID, -- Map ID
					mn = map and AnsiToUTF8(map.szName), -- Map Name
					nt = npc.dwTemplateID, -- NPC Template ID
					nn = X.GetObjectName(npc), -- NPC Name
				}, CONSTANT.SECRET.NPC_CHAT)))
			})
		X.DelayCall(szDelayID, false)
	end
	szDelayID = X.DelayCall(5000, fnAction)
	X.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex }, fnAction)
end)

--------------------------------------------------------------------------
local SHARE_SYSMSG_FILE = {'temporary/share-sysmsg.jx3dat', X.PATH_TYPE.GLOBAL} -- 系统信息上报模板表（远程）
local SHARE_SYSMSG = X.LoadLUAData(SHARE_SYSMSG_FILE) -- 系统信息上报模板表（远程）

X.RegisterInit('MY_ShareChat__Sysmsg', function()
	if not SHARE_SYSMSG then
		X.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = 'https://pull.j3cx.com/config/share-sysmsg'
				.. '?l=' .. AnsiToUTF8(GLOBAL.GAME_LANG)
				.. '&L=' .. AnsiToUTF8(GLOBAL.GAME_EDITION)
				.. '&_=' .. GetCurrentTime(),
			success = function(html, status)
				local data = X.JsonDecode(html)
				if X.IsTable(data) then
					SHARE_SYSMSG = {}
					for _, szPattern in ipairs(data) do
						if X.IsString(szPattern) then
							table.insert(SHARE_SYSMSG, szPattern)
						end
					end
					X.SaveLUAData(SHARE_SYSMSG_FILE, SHARE_SYSMSG)
				end
			end,
		})
	end
end)

X.RegisterMsgMonitor('MSG_SYS', 'MY_ShareChat__Sysmsg', function(szChannel, szMsg, nFont, bRich, r, g, b)
	if not MY_Serendipity.bEnable then
		return
	end
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
	if X.ContainsEchoMsgHeader(szMsg) then
		return
	end
	-- OutputMessage('MSG_SYS', "<image>path=\"UI/Image/Minimap/Minimap.UITex\" frame=184</image><text>text=\"“一只蠢盾盾”侠士正在为人传功，不经意间触发奇遇【雪山恩仇】！正是：侠心义行，偏遭奇症缠身；雪峰疗伤，却逢绝世奇缘。\" font=10 r=255 g=255 b=0 </text><text>text=\"\\\n\"</text>", true)
	-- “醉戈止战”侠士福缘非浅，触发奇遇【阴阳两界】，此千古奇缘将开启怎样的奇妙际遇，令人神往！
	-- 恭喜侠士江阙阙在25人英雄会战唐门中获得稀有掉落[夜话·白鹭]！
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	for _, szPattern in ipairs(SHARE_SYSMSG) do
		if string.find(szMsg, szPattern) then
			X.EnsureAjax({
				url = 'https://push.j3cx.com/api/share-sysmsg?'
					.. X.EncodePostData(X.UrlEncode(X.SignPostData({
						l = AnsiToUTF8(GLOBAL.GAME_LANG),
						L = AnsiToUTF8(GLOBAL.GAME_EDITION),
						region = AnsiToUTF8(X.GetRealServer(1)), -- Region
						server = AnsiToUTF8(X.GetRealServer(2)), -- Server
						content = AnsiToUTF8(szMsg), -- Content
						time = GetCurrentTime(), -- Time
					}, CONSTANT.SECRET.SHARE_SYSMSG)))
				})
			return
		end
	end
end)
