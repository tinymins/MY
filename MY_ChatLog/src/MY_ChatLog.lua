--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 记录团队/好友/帮会/密聊 供日后查询
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
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
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local XML_LINE_BREAKER = XML_LINE_BREAKER

local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_ChatLog/lang/')
if not LIB.AssertVersion('MY_ChatLog', _L['MY_ChatLog'], 0x2013500) then
	return
end

local D = {}
local O = {
	bIgnoreTongOnlineMsg    = true , -- 帮会上线通知
	bIgnoreTongMemberLogMsg = true , -- 帮会成员上线下线提示
	bRealtimeCommit         = false, -- 实时写入数据库
	tUncheckedChannel       = {}   ,
}
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')
RegisterCustomData('MY_ChatLog.bRealtimeCommit')
RegisterCustomData('MY_ChatLog.tUncheckedChannel')

------------------------------------------------------------------------------------------------------
-- 数据采集
------------------------------------------------------------------------------------------------------
local TONG_ONLINE_MSG        = '^' .. LIB.EscapeString(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG)
local TONG_MEMBER_LOGIN_MSG  = '^' .. LIB.EscapeString(g_tStrings.STR_GUILD_MEMBER_LOGIN):gsub('<link 0>', '.-') .. '$'
local TONG_MEMBER_LOGOUT_MSG = '^' .. LIB.EscapeString(g_tStrings.STR_GUILD_MEMBER_LOGOUT):gsub('<link 0>', '.-') .. '$'

------------------------------------------------------------------------------------------------------
-- 数据库控制器
------------------------------------------------------------------------------------------------------
local EXPORT_SLICE = 100
local LOG_TYPE = {
	{id = 'whisper', title = g_tStrings.tChannelName['MSG_WHISPER'       ], channels = {'MSG_WHISPER'       }},
	{id = 'party'  , title = g_tStrings.tChannelName['MSG_PARTY'         ], channels = {'MSG_PARTY'         }},
	{id = 'team'   , title = g_tStrings.tChannelName['MSG_TEAM'          ], channels = {'MSG_TEAM'          }},
	{id = 'friend' , title = g_tStrings.tChannelName['MSG_FRIEND'        ], channels = {'MSG_FRIEND'        }},
	{id = 'guild'  , title = g_tStrings.tChannelName['MSG_GUILD'         ], channels = {'MSG_GUILD'         }},
	{id = 'guild_a', title = g_tStrings.tChannelName['MSG_GUILD_ALLIANCE'], channels = {'MSG_GUILD_ALLIANCE'}},
	{id = 'death'  , title = _L['Death Log'], channels = {'MSG_SELF_DEATH', 'MSG_SELF_KILL', 'MSG_PARTY_DEATH', 'MSG_PARTY_KILL'}},
	{id = 'journal', title = _L['Journal Log'], channels = {
		'MSG_MONEY', 'MSG_ITEM', --'MSG_EXP', 'MSG_REPUTATION', 'MSG_CONTRIBUTE', 'MSG_ATTRACTION', 'MSG_PRESTIGE',
		-- 'MSG_TRAIN', 'MSG_MENTOR_VALUE', 'MSG_THEW_STAMINA', 'MSG_TONG_FUND'
	}},
	{id = 'monitor', title = _L['MY Monitor'], channels = {'MSG_MY_MONITOR'}},
}
local MSGTYPE_COLOR = setmetatable({
	['MSG_MY_MONITOR'] = {255, 255, 0},
}, {__index = function(t, k) return GetMsgFontColor(k, true) end})

function D.GetRoot()
	local szRoot = LIB.FormatPath({'userdata/chat_log/', PATH_TYPE.ROLE})
	if not IsLocalFileExist(szRoot) then
		CPath.MakeDir(szRoot)
	end
	return szRoot
end

function D.Open()
	MY_ChatLog_Open(D.GetRoot())
end

do
local aMsg, ds = {}
local function InitDB(bFix)
	local szPath = LIB.FormatPath({'userdata/chat_log.db', PATH_TYPE.ROLE})
	if IsLocalFileExist(szPath) then
		if not bFix then
			LIB.Confirm(_L['You need to upgrade chatlog database before using, that may take a while and cannot be break, do you want to do it now?'], function()
				LIB.Alert(_L['Your client may get no responding, please wait until it finished, otherwise your chatlog data may got lost, press yes to start.'], function()
					InitDB(true)
				end)
			end)
			return
		end
		local odb = LIB.ConnectDatabase(_L['chat log'], szPath)
		if odb then
			for _, info in ipairs(odb:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC')) do
				if info.etime == -1 then
					info.etime = 0
				end
				local db = MY_ChatLog_DB(D.GetRoot() .. info.name .. '.db')
				db:SetMinTime(info.stime)
				db:SetMaxTime(info.etime)
				for _, p in ipairs(odb:Execute('SELECT * FROM ' .. info.name .. ' ORDER BY time ASC')) do
					db:InsertMsg(p.channel, p.text, p.msg, p.talker, p.time, p.hash)
				end
				db:PushDB()
			end
			odb:Release()
		end
		CPath.Move(szPath, szPath .. '.bak')
	end
	ds = MY_ChatLog_DS(D.GetRoot())
	if not ds:InitDB() then
		if not bFix then
			LIB.Confirm(_L['Problem(s) detected on your chatlog database and must be fixed before use, would you like to do this now?'], function()
				LIB.Alert(_L['Your client may get no responding, please wait until it finished, otherwise your chatlog data may got lost, press yes to start.'], function()
					InitDB(true)
				end)
			end)
			return
		end
		ds:InitDB(true)
	end
	for _, a in ipairs(aMsg) do
		ds:InsertMsg(unpack(a))
	end
	aMsg = {}
	return true
end
LIB.RegisterInit('MY_ChatLog_InitMon', function() InitDB() end)

local function OnMsg(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szTalker)
	local szText = szMsg
	if bRich then
		szText = GetPureText(szMsg)
	else
		szMsg = GetFormatText(szMsg, nFont, r, g, b)
	end
	-- filters
	if szChannel == 'MSG_GUILD' then
		if O.bIgnoreTongOnlineMsg and szText:find(TONG_ONLINE_MSG) then
			return
		end
		if O.bIgnoreTongMemberLogMsg and (
			szText:find(TONG_MEMBER_LOGIN_MSG) or szText:find(TONG_MEMBER_LOGOUT_MSG)
		) then
			return
		end
	end
	if ds then
		ds:InsertMsg(szChannel, szText, szMsg, szTalker, GetCurrentTime())
		if O.bRealtimeCommit and not LIB.IsShieldedVersion() then
			ds:PushDB()
		end
	else
		insert(aMsg, {szChannel, szText, szMsg, szTalker, GetCurrentTime()})
	end
end
local tChannels, aChannels = {}, {}
for _, info in ipairs(LOG_TYPE) do
	for _, szChannel in ipairs(info.channels) do
		tChannels[szChannel] = true
	end
end
for szChannel, _ in pairs(tChannels) do
	insert(aChannels, szChannel)
end
LIB.RegisterMsgMonitor('MY_ChatLog', OnMsg, aChannels)

local function onLoadingEnding()
	if ds then
		ds:PushDB()
	end
end
LIB.RegisterEvent('LOADING_ENDING.MY_ChatLog_Save', onLoadingEnding)

local function onIdle()
	if ds and not LIB.IsShieldedVersion() then
		ds:PushDB()
	end
end
LIB.RegisterIdle('MY_ChatLog_Save', onIdle)

local function onExit()
	if not ds then
		return
	end
	ds:PushDB()
	ds:ReleaseDB()
end
LIB.RegisterExit('MY_Chat_Release', onExit)
LIB.RegisterEvent('DISCONNECT.MY_Chat_Release', onExit)
end

do
local menu = {
	szOption = _L['chat log'],
	fnAction = D.Open,
}
LIB.RegisterAddonMenu('MY_CHATLOG_MENU', menu)
end
LIB.RegisterHotKey('MY_ChatLog', _L['chat log'], D.Open, nil)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
				GetRoot = D.GetRoot,
				LOG_TYPE = LOG_TYPE,
				MSGTYPE_COLOR = MSGTYPE_COLOR,
			},
		},
		{
			fields = {
				bIgnoreTongOnlineMsg    = true,
				bIgnoreTongMemberLogMsg = true,
				bRealtimeCommit         = true,
				tUncheckedChannel       = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bIgnoreTongOnlineMsg    = true,
				bIgnoreTongMemberLogMsg = true,
				bRealtimeCommit         = true,
				tUncheckedChannel       = true,
			},
			root = O,
		},
	},
}
MY_ChatLog = LIB.GeneGlobalNS(settings)
end

-- ===== 性能测试 =====
-- LIB.RegisterInit(function()
-- 	local ds = MY_ChatLog_DS(D.GetRoot())
-- 	local szTalker = '名字@服务器'
-- 	local szMsg = g_tStrings.STR_TONG_BAO_DESC
-- 	local szText = GetPureText(szMsg)
-- 	for i = 0, 20001 do
-- 		ds:InsertMsg('MSG_WHISPER', szText, szMsg, szTalker, 110000 + i)
-- 	end
-- 	ds:PushDB()
-- end)
