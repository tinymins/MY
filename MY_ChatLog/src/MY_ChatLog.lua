--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天记录 记录团队/好友/帮会/密聊 供日后查询
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ChatLog/MY_ChatLog'
local PLUGIN_NAME = 'MY_ChatLog'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatLog'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^22.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_ChatLog.DEVELOP', { ['*'] = true })
--------------------------------------------------------------------------

local MSG_TYPE_CUSTOM = {
	'MSG_MY_MONITOR',
}

local MSG_TYPE_TITLE = setmetatable({
	['MSG_MY_MONITOR'] = _L['MY Monitor'],
}, {__index = g_tStrings.tChannelName})

local MSG_TYPE_COLOR = setmetatable({
	['MSG_MY_MONITOR'] = {255, 255, 0},
}, {__index = function(t, k) return GetMsgFontColor(k, true) end})

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['Chat'], {
	bIgnoreTongOnlineMsg = { -- 帮会上线通知
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bIgnoreTongMemberLogMsg = { -- 帮会成员上线下线提示
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bIgnoreOthersAchievementDesignation = { -- 其他玩家成就称号
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bRealtimeCommit = { -- 实时写入数据库
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = IsDebugClient() and X.Schema.Boolean or false,
		xDefaultValue = false,
	},
	bAutoConnectDB = { -- 登录时自动连接数据库
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	aChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = X.Schema.Collection(
			X.Schema.Record({
				szKey = X.Schema.String,
				szTitle = X.Schema.String,
				aMsgType = X.Schema.Collection(X.Schema.String),
			})
		),
		xDefaultValue = (function()
			local aChannel = {
				{ szKey = 'whisper', szTitle = MSG_TYPE_TITLE['MSG_WHISPER'], aMsgType = {'MSG_WHISPER', 'MSG_SSG_WHISPER'} },
				{ szKey = 'party'  , szTitle = MSG_TYPE_TITLE['MSG_PARTY'], aMsgType = {'MSG_PARTY'} },
				{ szKey = 'team'   , szTitle = MSG_TYPE_TITLE['MSG_TEAM'], aMsgType = {'MSG_TEAM'} },
				{ szKey = 'room'   , szTitle = MSG_TYPE_TITLE['MSG_ROOM'], aMsgType = {'MSG_ROOM'} },
				{ szKey = 'friend' , szTitle = MSG_TYPE_TITLE['MSG_FRIEND'], aMsgType = {'MSG_FRIEND'} },
				{ szKey = 'guild'  , szTitle = MSG_TYPE_TITLE['MSG_GUILD'], aMsgType = {'MSG_GUILD'} },
				{ szKey = 'guild_a', szTitle = MSG_TYPE_TITLE['MSG_GUILD_ALLIANCE'], aMsgType = {'MSG_GUILD_ALLIANCE'} },
				{ szKey = 'death'  , szTitle = _L['Death Log'], aMsgType = {'MSG_SELF_DEATH', 'MSG_SELF_KILL', 'MSG_PARTY_DEATH', 'MSG_PARTY_KILL'} },
				{
					szKey = 'journal', szTitle = _L['Journal Log'], aMsgType = (function()
						for _, v in ipairs(X.CONSTANT.MSG_TYPE_MENU) do
							if v.szOption == g_tStrings.EARN then
								local a = {}
								for _, vv in ipairs(v) do
									table.insert(a, vv)
								end
								return a
							end
						end
						return {
							'MSG_MONEY', 'MSG_ITEM', --'MSG_EXP', 'MSG_REPUTATION', 'MSG_CONTRIBUTE', 'MSG_ATTRACTION', 'MSG_PRESTIGE',
							-- 'MSG_TRAIN', 'MSG_MENTOR_VALUE', 'MSG_THEW_STAMINA', 'MSG_TONG_FUND'
						}
					end)(),
				},
				{ szKey = 'monitor', szTitle = MSG_TYPE_TITLE['MSG_MY_MONITOR'], aMsgType = {'MSG_MY_MONITOR'} },
			}
			for i, v in X.ipairs_r(aChannel) do
				if not v or not v.szTitle then
					table.remove(aChannel, i)
				end
			end
			return aChannel
		end)(),
	},
	tUncheckedChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatLog'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})
local D = {}

------------------------------------------------------------------------------------------------------
-- 数据采集
------------------------------------------------------------------------------------------------------
local TONG_ONLINE_MSG        = '^' .. X.EscapeString(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG)
local TONG_MEMBER_LOGIN_MSG  = '^' .. X.EscapeString(g_tStrings.STR_GUILD_MEMBER_LOGIN):gsub('<link 0>', '.-') .. '$'
local TONG_MEMBER_LOGOUT_MSG = '^' .. X.EscapeString(g_tStrings.STR_GUILD_MEMBER_LOGOUT):gsub('<link 0>', '.-') .. '$'

------------------------------------------------------------------------------------------------------
-- 数据库控制器
------------------------------------------------------------------------------------------------------
local LOG_LIMIT = (X.ENVIRONMENT.GAME_PROVIDER == 'remote' and not X.IsDebugClient())
	and {
		{ aKey = {'whisper'}, nLimit = 5000 },
		{ aKey = {'party', 'team', 'room'}, nLimit = 5000 },
		{ aKey = {'friend'}, nLimit = 5000 },
		{ aKey = {'guild', 'guild_a'}, nLimit = 1000 },
		{ aKey = {'death', 'journal'}, nLimit = 1000 },
		{ aKey = {'monitor'}, nLimit = 1000 },
	}
	or {}
local UNSAVED_MSG_LIST, MAIN_DS = {}

-- 旧版数据频道对应数据库中数值
local V1_MSG_TYPE_MAP = {
	[1] = 'MSG_WHISPER',
	[2] = 'MSG_PARTY',
	[3] = 'MSG_TEAM',
	[4] = 'MSG_FRIEND',
	[5] = 'MSG_GUILD',
	[6] = 'MSG_GUILD_ALLIANCE',
	[7] = 'MSG_SELF_DEATH',
	[8] = 'MSG_SELF_KILL',
	[9] = 'MSG_PARTY_DEATH',
	[10] = 'MSG_PARTY_KILL',
	[11] = 'MSG_MONEY',
	[12] = 'MSG_EXP',
	[13] = 'MSG_ITEM',
	[14] = 'MSG_REPUTATION',
	[15] = 'MSG_CONTRIBUTE',
	[16] = 'MSG_ATTRACTION',
	[17] = 'MSG_PRESTIGE',
	[18] = 'MSG_TRAIN',
	[19] = 'MSG_MENTOR_VALUE',
	[20] = 'MSG_THEW_STAMINA',
	[21] = 'MSG_TONG_FUND',
	[22] = 'MSG_MY_MONITOR',
	[23] = 'MSG_SSG_WHISPER',
}

function D.GetRoot()
	local szRoot = X.FormatPath({'userdata/chat_log/', X.PATH_TYPE.ROLE})
	if not IsLocalFileExist(szRoot) then
		CPath.MakeDir(szRoot)
	end
	return szRoot
end

function D.Open()
	MY_ChatLog_UI.Open(D.GetRoot())
end

function D.ResetChannel()
	O('reset', { 'aChannel' })
	D.RegisterMsgMonitor()
	FireUIEvent('ON_MY_CHAT_LOG_CHANNEL_CHANGE')
end

function D.InitDB(szMode)
	if MAIN_DS then
		return true
	end
	if not szMode then
		szMode = 'ask'
	end
	if szMode == 'silent' and not X.IsRestricted('MY_ChatLog.DEVELOP') then
		szMode = 'sure'
	end
	local ds, bSuccess = MY_ChatLog_DS(D.GetRoot()), true
	if not ds:InitDB() then
		bSuccess = false
		if szMode == 'ask' then
			X.Confirm(_L['Problem(s) detected on your chatlog database and must be fixed before use, would you like to do this now?'], function()
				X.Alert(_L['Your client may get no responding, please wait until it finished, otherwise your chatlog data may got lost, press yes to start.'], function()
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

-- 导入数据
function D.ImportDB(aPath)
	if X.IsString(aPath) then
		aPath = {aPath}
	end
	-- 先释放存储集群防止出现缓存同步问题
	D.ReleaseDB()
	-- 开始导入
	local nImportCount = 0
	for _, szPath in ipairs(aPath) do
		local odb = X.SQLiteConnect(_L['MY_ChatLog'], szPath)
		if odb then
			-- 老版分表机制
			local szGlobalID = X.Get(odb:Execute('SELECT * FROM ChatLogInfo WHERE key = "userguid"'), {1, 'value'})
			if szGlobalID == X.GetClientPlayer().GetGlobalID() then
				for _, info in ipairs(odb:Execute('SELECT * FROM ChatLogIndex WHERE name IS NOT NULL ORDER BY stime ASC') or X.CONSTANT.EMPTY_TABLE) do
					if info.etime == -1 then
						info.etime = 0
					end
					local db = MY_ChatLog_DB(D.GetRoot() .. info.name .. '.v2.db')
					db:SetMinTime(info.stime)
					db:SetMaxTime(info.etime)
					db:SetInfo('version', '2')
					db:SetInfo('user_global_id', szGlobalID)
					for _, p in ipairs(odb:Execute('SELECT * FROM ' .. info.name .. ' WHERE talker IS NOT NULL ORDER BY time ASC') or X.CONSTANT.EMPTY_TABLE) do
						local szMsgType = V1_MSG_TYPE_MAP[p.channel]
						if szMsgType then
							nImportCount = nImportCount + 1
							db:InsertMsg(szMsgType, p.text, p.msg, p.talker, p.time, p.hash)
						end
					end
					db:Flush()
					db:Disconnect()
				end
			end
			-- 新版导出数据
			local szGlobalID = X.Get(odb:Execute('SELECT value FROM ChatInfo WHERE key = "user_global_id"'), {1, 'value'}, ''):gsub('"', '')
			if szGlobalID == X.GetClientPlayer().GetGlobalID() then
				local szVersion = X.Get(odb:Execute('SELECT value FROM ChatInfo WHERE key = "version"'), {1, 'value'}, '')
				local nCount = X.Get(odb:Execute('SELECT COUNT(*) AS nCount FROM ChatLog'), {1, 'nCount'}, 0)
				if nCount > 0 then
					local szRoot, nOffset, nLimit, szNewPath, dbNew = D.GetRoot(), 0, 20000
					local stmt, aRes = odb:Prepare('SELECT * FROM ChatLog WHERE talker IS NOT NULL ORDER BY time ASC LIMIT ' .. nLimit .. ' OFFSET ?')
					while nOffset < nCount do
						stmt:ClearBindings()
						stmt:BindAll(nOffset)
						aRes = stmt:GetAll()
						if #aRes > 0 then
							repeat
								szNewPath = szRoot .. ('chatlog_%x'):format(X.Random(0x100000, 0xFFFFFF)) .. '.v2.db'
							until not IsLocalFileExist(szNewPath)
							dbNew = MY_ChatLog_DB(szNewPath)
							dbNew:SetMinTime(aRes[1].time)
							dbNew:SetMaxTime(aRes[#aRes].time)
							dbNew:SetInfo('version', '2')
							dbNew:SetInfo('user_global_id', szGlobalID)
							for _, p in ipairs(aRes) do
								if szVersion == '2' then
									nImportCount = nImportCount + 1
									dbNew:InsertMsg(p.channel, p.text, p.msg, p.talker, p.time, p.hash)
								else
									local szMsgType = V1_MSG_TYPE_MAP[p.channel]
									if szMsgType then
										nImportCount = nImportCount + 1
										dbNew:InsertMsg(szMsgType, p.text, p.msg, p.talker, p.time, p.hash)
									end
								end
							end
							dbNew:Flush()
							dbNew:Disconnect()
						end
						nOffset = nOffset + nLimit
					end
					stmt:Reset()
				end
			end
			odb:Release()
		end
	end
	-- 优化集群数据
	local ds = MY_ChatLog_DS(D.GetRoot())
	ds:InitDB(true)
	ds:OptimizeDB()
	ds:ReleaseDB()
	return nImportCount
end

function D.OptimizeDB()
	if not D.InitDB('sure') then
		return
	end
	MAIN_DS:OptimizeDB()
end

-- 检查升级数据库版本
function D.MigrateDB()
	local aImportPath = {}
	-- 旧版单文件
	local DB_V0_PATH = X.FormatPath({'userdata/chat_log.db', X.PATH_TYPE.ROLE})
	if IsLocalFileExist(DB_V0_PATH) then
		table.insert(aImportPath, DB_V0_PATH)
	end
	-- 旧版集群V1
	for _, szName in ipairs(CPath.GetFileList(D.GetRoot()) or {}) do
		if szName:find('^chatlog_[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]%.db$') then
			table.insert(aImportPath, D.GetRoot() .. szName)
		end
	end
	if X.IsEmpty(aImportPath) then
		return
	end
	X.Confirm(_L['Ancient chatlog detected, you can migrate chatlog database from them, that may take a while and cannot be break, do you want to do it now?'], function()
		X.Alert(_L['Your client may get no responding, please wait until it finished, otherwise your chatlog data may got lost, press yes to start.'], function()
			D.ImportDB(aImportPath)
			for _, szPath in ipairs(aImportPath) do
				CPath.Move(szPath, szPath .. '.bak' .. GetCurrentTime())
			end
			MY.Alert(_L['Upgrade succeed!'])
		end)
	end)
end

local REGISTER_MONITOR_MSG_TYPE = {}
function D.RegisterMsgMonitor()
	for szMsgType, _ in pairs(REGISTER_MONITOR_MSG_TYPE) do
		X.RegisterMsgMonitor(szMsgType, 'MY_ChatLog', false)
	end
	local tMsgType = {}
	for _, info in ipairs(MY_ChatLog.aChannel) do
		for _, szMsgType in ipairs(info.aMsgType) do
			tMsgType[szMsgType] = true
		end
	end
	for szMsgType, _ in pairs(tMsgType) do
		X.RegisterMsgMonitor(szMsgType, 'MY_ChatLog', function(szMsgType, szMsg, nFont, bRich, r, g, b, dwTalkerID, szTalker)
			local szText = szMsg
			if bRich then
				szText = GetPureText(szMsg)
			else
				szMsg = GetFormatText(szMsg, nFont, r, g, b)
			end
			-- filters
			if szMsgType == 'MSG_GUILD' then
				if D.bReady and O.bIgnoreTongOnlineMsg and szText:find(TONG_ONLINE_MSG) then
					return
				end
				if D.bReady and O.bIgnoreTongMemberLogMsg and (
					szText:find(TONG_MEMBER_LOGIN_MSG) or szText:find(TONG_MEMBER_LOGOUT_MSG)
				) then
					return
				end
			elseif szMsgType == 'MSG_ACHIEVEMENT' or szMsgType == 'MSG_DESGNATION' then
				if D.bReady and O.bIgnoreOthersAchievementDesignation
				and not szText:find(_L['You\'ve achieved'])
				and not szText:find('[' .. X.GetClientPlayerName() .. ']', nil, true) then
					return
				end
			end
			if MAIN_DS then
				MAIN_DS:InsertMsg(szMsgType, szText, szMsg, szTalker, GetCurrentTime())
				if D.bReady and O.bRealtimeCommit and not X.IsRestricted('MY_ChatLog.RealtimeCommit') then
					MAIN_DS:FlushDB()
				end
			else
				table.insert(UNSAVED_MSG_LIST, {szMsgType, szText, szMsg, szTalker, GetCurrentTime()})
			end
		end)
	end
	REGISTER_MONITOR_MSG_TYPE = tMsgType
end

function D.OnInit()
	if not X.GetClientPlayer() then
		return X.DelayCall(500, D.OnInit)
	end
	if O.bAutoConnectDB then
		D.InitDB('ask')
	end
	D.bReady = true
end

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
		local aMsgType = {}
		for _, szKey in ipairs(p.aKey) do
			for _, info in ipairs(MY_ChatLog.aChannel) do
				if info.szKey == szKey then
					for _, szMsgType in ipairs(info.aMsgType) do
						table.insert(aMsgType, szMsgType)
					end
				end
			end
		end
		local nCount = MAIN_DS:CountMsg(aMsgType)
		if nCount > p.nLimit then
			local aMsg = MAIN_DS:SelectMsg(aMsgType, nil, nil, nil, nCount - p.nLimit, 1)
			if aMsg and aMsg[1] then
				bExceed = true
				MAIN_DS:DeleteMsgInterval(aMsgType, '', 0, aMsg[1].nTime)
			end
		end
	end
	if bExceed then
		D.OptimizeDB()
	end
end

function D.ReleaseDB()
	FireUIEvent('ON_MY_CHAT_LOG_RELEASE_DB')
	D.FlushDB(true)
	if not MAIN_DS then
		return
	end
	MAIN_DS:ReleaseDB()
end
--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatLog',
	exports = {
		{
			fields = {
				MSG_TYPE_CUSTOM = MSG_TYPE_CUSTOM,
				MSG_TYPE_TITLE = MSG_TYPE_TITLE,
				MSG_TYPE_COLOR = MSG_TYPE_COLOR,
				'Open',
				'GetRoot',
				'InitDB',
				'MigrateDB',
				'OptimizeDB',
				'ImportDB',
				'ResetChannel',
			},
			root = D,
		},
		{
			fields = {
				'bIgnoreTongOnlineMsg',
				'bIgnoreTongMemberLogMsg',
				'bIgnoreOthersAchievementDesignation',
				'bRealtimeCommit',
				'bAutoConnectDB',
				'aChannel',
				'tUncheckedChannel',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bIgnoreTongOnlineMsg',
				'bIgnoreTongMemberLogMsg',
				'bIgnoreOthersAchievementDesignation',
				'bRealtimeCommit',
				'bAutoConnectDB',
				'aChannel',
				'tUncheckedChannel',
			},
			triggers = {
				aChannel = function()
					D.RegisterMsgMonitor()
					FireUIEvent('ON_MY_CHAT_LOG_CHANNEL_CHANGE')
				end,
			},
			root = O,
		},
	},
}
MY_ChatLog = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('LOADING_ENDING', 'MY_ChatLog_Save', function()
	if MAIN_DS then
		MAIN_DS:FlushDB()
	end
end)

X.RegisterIdle('MY_ChatLog_Save', function()
	if MAIN_DS and not X.IsRestricted('MY_ChatLog.DEVELOP') then
		MAIN_DS:FlushDB()
	end
end)

X.RegisterInit('MY_ChatLog_InitDB', D.OnInit)
X.RegisterExit('MY_ChatLog_Release', D.ReleaseDB)

X.RegisterInit('MY_ChatLog_InitMsgMonitor', D.RegisterMsgMonitor)
X.RegisterUserSettingsInit('MY_ChatLog_InitMsgMonitor', D.RegisterMsgMonitor)

X.RegisterEvent('DISCONNECT', 'MY_ChatLog_Release', function()
	if X.IsRestricted('MY_ChatLog.DEVELOP') then
		return
	end
	D.ReleaseDB()
end)

X.RegisterAddonMenu('MY_ChatLog_Menu', {
	szOption = _L['MY_ChatLog'],
	fnAction = D.Open,
})
X.RegisterHotKey('MY_ChatLog', _L['MY_ChatLog'], D.Open, nil)

-- ===== 性能测试 =====
-- X.RegisterInit(function()
-- 	local ds = MY_ChatLog_DS(D.GetRoot())
-- 	local szTalker = '名字@服务器'
-- 	local szMsg = g_tStrings.STR_TONG_BAO_DESC
-- 	local szText = GetPureText(szMsg)
-- 	for i = 0, 20001 do
-- 		ds:InsertMsg('MSG_WHISPER', szText, szMsg, szTalker, 110000 + i)
-- 	end
-- 	ds:FlushDB()
-- end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
