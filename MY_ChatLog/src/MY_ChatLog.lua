--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 记录团队/好友/帮会/密聊 供日后查询
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
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
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bIgnoreTongOnlineMsg    = true , -- 帮会上线通知
	bIgnoreTongMemberLogMsg = true , -- 帮会成员上线下线提示
	bRealtimeCommit         = false, -- 实时写入数据库
	bAutoConnectDB          = false, -- 登录时自动连接数据库
	tUncheckedChannel       = {}   ,
}
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')
RegisterCustomData('MY_ChatLog.bRealtimeCommit')
RegisterCustomData('MY_ChatLog.bAutoConnectDB')
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
local LOG_TYPE = {
	{ szKey = 'whisper', szTitle = g_tStrings.tChannelName['MSG_WHISPER'       ], aChannel = {'MSG_WHISPER'       }},
	{ szKey = 'party'  , szTitle = g_tStrings.tChannelName['MSG_PARTY'         ], aChannel = {'MSG_PARTY'         }},
	{ szKey = 'team'   , szTitle = g_tStrings.tChannelName['MSG_TEAM'          ], aChannel = {'MSG_TEAM'          }},
	{ szKey = 'friend' , szTitle = g_tStrings.tChannelName['MSG_FRIEND'        ], aChannel = {'MSG_FRIEND'        }},
	{ szKey = 'guild'  , szTitle = g_tStrings.tChannelName['MSG_GUILD'         ], aChannel = {'MSG_GUILD'         }},
	{ szKey = 'guild_a', szTitle = g_tStrings.tChannelName['MSG_GUILD_ALLIANCE'], aChannel = {'MSG_GUILD_ALLIANCE'}},
	{ szKey = 'death'  , szTitle = _L['Death Log'], aChannel = {'MSG_SELF_DEATH', 'MSG_SELF_KILL', 'MSG_PARTY_DEATH', 'MSG_PARTY_KILL'}},
	{ szKey = 'journal', szTitle = _L['Journal Log'], aChannel = {
		'MSG_MONEY', 'MSG_ITEM', --'MSG_EXP', 'MSG_REPUTATION', 'MSG_CONTRIBUTE', 'MSG_ATTRACTION', 'MSG_PRESTIGE',
		-- 'MSG_TRAIN', 'MSG_MENTOR_VALUE', 'MSG_THEW_STAMINA', 'MSG_TONG_FUND'
	}},
	{ szKey = 'monitor', szTitle = _L['MY Monitor'], aChannel = {'MSG_MY_MONITOR'}},
}
local LOG_LIMIT = (LIB.IsStreaming() and not LIB.IsDebugClient())
	and {
		{ aKey = {'whisper'}, nLimit = 5000 },
		{ aKey = {'party', 'team'}, nLimit = 5000 },
		{ aKey = {'friend'}, nLimit = 5000 },
		{ aKey = {'guild', 'guild_a'}, nLimit = 1000 },
		{ aKey = {'death', 'journal'}, nLimit = 1000 },
		{ aKey = {'monitor'}, nLimit = 1000 },
	}
	or {}
local MSGTYPE_COLOR = setmetatable({
	['MSG_MY_MONITOR'] = {255, 255, 0},
}, {__index = function(t, k) return GetMsgFontColor(k, true) end})
local UNSAVED_MSG_LIST, MAIN_DS = {}

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

function D.InitDB(szMode)
	if MAIN_DS then
		return true
	end
	if not szMode then
		szMode = 'ask'
	end
	if szMode == 'silent' and not LIB.IsShieldedVersion('DEVELOP') then
		szMode = 'sure'
	end
	if not D.UpgradeDB(szMode) then
		return
	end
	local ds, bSuccess = MY_ChatLog_DS(D.GetRoot()), true
	if not ds:InitDB() then
		bSuccess = false
		if szMode == 'ask' then
			LIB.Confirm(_L['Problem(s) detected on your chatlog database and must be fixed before use, would you like to do this now?'], function()
				LIB.Alert(_L['Your client may get no responding, please wait until it finished, otherwise your chatlog data may got lost, press yes to start.'], function()
					D.InitDB('sure')
				end)
			end)
		elseif szMode == 'sure' then
			ds:InitDB(true):OptimizeDB()
			MY.Alert(_L['Fix succeed!'])
			bSuccess = true
		end
	end
	if bSuccess then
		for _, a in ipairs(UNSAVED_MSG_LIST) do
			ds:InsertMsg(unpack(a))
		end
		MAIN_DS, UNSAVED_MSG_LIST = ds, {}
	end
	return bSuccess
end

-- 检查升级数据库版本
function D.UpgradeDB(szMode)
	local szPath, bSuccess = LIB.FormatPath({'userdata/chat_log.db', PATH_TYPE.ROLE}), true
	if IsLocalFileExist(szPath) then
		bSuccess = false
		if szMode == 'ask' then
			LIB.Confirm(_L['You need to upgrade chatlog database before using, that may take a while and cannot be break, do you want to do it now?'], function()
				LIB.Alert(_L['Your client may get no responding, please wait until it finished, otherwise your chatlog data may got lost, press yes to start.'], function()
					D.InitDB('sure')
				end)
			end)
		elseif szMode == 'sure' then
			D.ImportDB(szPath)
			CPath.Move(szPath, szPath .. '.bak' .. GetCurrentTime())
			MY.Alert(_L['Upgrade succeed!'])
			bSuccess = true
		end
	end
	return bSuccess
end
LIB.RegisterInit('MY_ChatLog_UpgradeDB', D.UpgradeDB)

-- 导入数据
function D.ImportDB(szPath)
	local odb, nImportCount = LIB.ConnectDatabase(_L['MY_ChatLog'], szPath), 0
	if odb then
		-- 老版分表机制
		local dwGlobalID = Get(odb:Execute('SELECT * FROM ChatLogInfo WHERE key = "userguid"'), {1, 'value'})
		if dwGlobalID == GetClientPlayer().GetGlobalID() then
			for _, info in ipairs(odb:Execute('SELECT * FROM ChatLogIndex ORDER BY stime ASC') or CONSTANT.EMPTY_TABLE) do
				if info.etime == -1 then
					info.etime = 0
				end
				local db = MY_ChatLog_DB(D.GetRoot() .. info.name .. '.db')
				db:SetMinTime(info.stime)
				db:SetMaxTime(info.etime)
				db:SetInfo('user_global_id', dwGlobalID)
				for _, p in ipairs(odb:Execute('SELECT * FROM ' .. info.name .. ' ORDER BY time ASC') or CONSTANT.EMPTY_TABLE) do
					nImportCount = nImportCount + 1
					db:InsertMsg(p.channel, p.text, p.msg, p.talker, p.time, p.hash)
				end
				db:Flush()
				db:Disconnect()
			end
		end
		-- 新版导出数据
		local dwGlobalID = Get(odb:Execute('SELECT value FROM ChatInfo WHERE key = "user_global_id"'), {1, 'value'}, ''):gsub('"', '')
		if dwGlobalID == GetClientPlayer().GetGlobalID() then
			local nCount = Get(odb:Execute('SELECT COUNT(*) AS nCount FROM ChatLog'), {1, 'nCount'}, 0)
			if nCount > 0 then
				local szRoot, nOffset, nLimit, szNewPath, dbNew = D.GetRoot(), 0, 20000
				local stmt, aRes = odb:Prepare('SELECT * FROM ChatLog ORDER BY time ASC LIMIT ' .. nLimit .. ' OFFSET ?')
				while nOffset < nCount do
					stmt:ClearBindings()
					stmt:BindAll(nOffset)
					aRes = stmt:GetAll()
					if #aRes > 0 then
						repeat
							szNewPath = szRoot .. ('chatlog_%x'):format(random(0x100000, 0xFFFFFF)) .. '.db'
						until not IsLocalFileExist(szNewPath)
						dbNew = MY_ChatLog_DB(szNewPath)
						dbNew:SetMinTime(aRes[1].time)
						dbNew:SetMaxTime(aRes[#aRes].time)
						dbNew:SetInfo('user_global_id', dwGlobalID)
						for _, p in ipairs(aRes) do
							nImportCount = nImportCount + 1
							dbNew:InsertMsg(p.channel, p.text, p.msg, p.talker, p.time, p.hash)
						end
						dbNew:Flush()
						dbNew:Disconnect()
					end
					nOffset = nOffset + nLimit
				end
			end
		end
		odb:Release()
	end
	MY_ChatLog_DS(D.GetRoot()):InitDB(true):OptimizeDB()
	return nImportCount
end

function D.OptimizeDB()
	if not D.InitDB('sure') then
		return
	end
	MAIN_DS:OptimizeDB()
end

LIB.RegisterMsgMonitor('MY_ChatLog', function(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szTalker)
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
	if MAIN_DS then
		MAIN_DS:InsertMsg(szChannel, szText, szMsg, szTalker, GetCurrentTime())
		if O.bRealtimeCommit and not LIB.IsShieldedVersion('MY_ChatLog') then
			MAIN_DS:FlushDB()
		end
	else
		insert(UNSAVED_MSG_LIST, {szChannel, szText, szMsg, szTalker, GetCurrentTime()})
	end
end, (function()
	local tChannels, aChannels = {}, {}
	for _, info in ipairs(LOG_TYPE) do
		for _, szChannel in ipairs(info.aChannel) do
			tChannels[szChannel] = true
		end
	end
	for szChannel, _ in pairs(tChannels) do
		insert(aChannels, szChannel)
	end
	return aChannels
end)())

LIB.RegisterEvent('LOADING_ENDING.MY_ChatLog_Save', function()
	if MAIN_DS then
		MAIN_DS:FlushDB()
	end
end)

LIB.RegisterIdle('MY_ChatLog_Save', function()
	if MAIN_DS and not LIB.IsShieldedVersion('DEVELOP') then
		MAIN_DS:FlushDB()
	end
end)

function D.OnInit()
	if not GetClientPlayer() then
		return LIB.DelayCall(500, D.OnInit)
	end
	if O.bAutoConnectDB then
		D.InitDB('ask')
	end
end
LIB.RegisterInit('MY_ChatLog_InitDB', D.OnInit)

function D.FlushDB(bCheckExceed)
	if not D.InitDB('silent') then
		return
	end
	MAIN_DS:FlushDB()
	-- 数据超限检查处理
	if not bCheckExceed then
		return
	end
	local bExceed = false
	for _, p in ipairs(LOG_LIMIT) do
		local aChannel = {}
		for _, szKey in ipairs(p.aKey) do
			for _, info in ipairs(LOG_TYPE) do
				if info.szKey == szKey then
					for _, szChannel in ipairs(info.aChannel) do
						insert(aChannel, szChannel)
					end
				end
			end
		end
		local nCount = MAIN_DS:CountMsg(aChannel)
		if nCount > p.nLimit then
			local aMsg = MAIN_DS:SelectMsg(aChannel, nil, nil, nil, nCount - p.nLimit, 1)
			if aMsg and aMsg[1] then
				bExceed = true
				MAIN_DS:DeleteMsgInterval(aChannel, '', 0, aMsg[1].nTime)
			end
		end
	end
	if bExceed then
		D.OptimizeDB()
	end
end

function D.ReleaseDB()
	D.FlushDB(true)
	if not MAIN_DS then
		return
	end
	MAIN_DS:ReleaseDB()
end
LIB.RegisterExit('MY_Chat_Release', D.ReleaseDB)

LIB.RegisterEvent('DISCONNECT.MY_Chat_Release', function()
	if LIB.IsShieldedVersion('DEVELOP') then
		return
	end
	D.ReleaseDB()
end)

LIB.RegisterAddonMenu('MY_CHATLOG_MENU', {
	szOption = _L['MY_ChatLog'],
	fnAction = D.Open,
})
LIB.RegisterHotKey('MY_ChatLog', _L['MY_ChatLog'], D.Open, nil)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
				GetRoot = D.GetRoot,
				InitDB = D.InitDB,
				OptimizeDB = D.OptimizeDB,
				ImportDB = D.ImportDB,
				LOG_TYPE = LOG_TYPE,
				MSGTYPE_COLOR = MSGTYPE_COLOR,
			},
		},
		{
			fields = {
				bIgnoreTongOnlineMsg    = true,
				bIgnoreTongMemberLogMsg = true,
				bRealtimeCommit         = true,
				bAutoConnectDB          = true,
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
				bAutoConnectDB          = true,
				tUncheckedChannel       = true,
			},
			triggers = {
				bAutoConnectDB = D.OnInit,
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
-- 	ds:FlushDB()
-- end)
