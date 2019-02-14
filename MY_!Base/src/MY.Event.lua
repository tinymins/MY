--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 事件处理相关函数
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack()
---------------------------------------------------------------------------------------------
-- 事件注册
---------------------------------------------------------------------------------------------
-- 注册游戏事件监听
-- MY.RegisterEvent(szEvent, fnAction) -- 注册
-- MY.RegisterEvent(szEvent) -- 注销
-- (string)  szEvent  事件，可在后面加一个点并紧跟一个标识字符串用于防止重复或取消绑定，如 LOADING_END.xxx
-- (function)fnAction 事件处理函数，arg0 ~ arg9，传入 nil 相当于取消该事件
--特别注意：当 fnAction 为 nil 并且 szKey 也为 nil 时会取消所有通过本函数注册的事件处理器
do local EVENT_LIST = {}
local function EventHandler(szEvent, ...)
	local tEvent = EVENT_LIST[szEvent]
	if tEvent then
		for k, v in pairs(tEvent) do
			local res, err = pcall(v, szEvent, ...)
			if not res then
				MY.Debug({GetTraceback(err)}, 'OnEvent#' .. szEvent .. '.' .. k, MY_DEBUG.ERROR)
			end
		end
	end
end

function MY.RegisterEvent(szEvent, fnAction)
	if type(szEvent) == 'table' then
		for _, szEvent in ipairs(szEvent) do
			MY.RegisterEvent(szEvent, fnAction)
		end
	elseif type(szEvent) == 'string' then
		local szKey = nil
		local nPos = StringFindW(szEvent, '.')
		if nPos then
			szKey = string.sub(szEvent, nPos + 1)
			szEvent = string.sub(szEvent, 1, nPos - 1)
		end
		if fnAction then
			if not EVENT_LIST[szEvent] then
				EVENT_LIST[szEvent] = {}
				RegisterEvent(szEvent, EventHandler)
			end
			if szKey then
				EVENT_LIST[szEvent][szKey] = fnAction
			else
				table.insert(EVENT_LIST[szEvent], fnAction)
			end
		else
			if szKey then
				if EVENT_LIST[szEvent] then
					EVENT_LIST[szEvent][szKey] = nil
				end
			else
				EVENT_LIST[szEvent] = {}
			end
		end
	end
end
end

do local INIT_FUNC_LIST = {}
local function OnInit()
	if not INIT_FUNC_LIST then
		return
	end
	MY.CreateDataRoot(MY_DATA_PATH.ROLE)
	MY.CreateDataRoot(MY_DATA_PATH.GLOBAL)
	MY.CreateDataRoot(MY_DATA_PATH.SERVER)

	for szKey, fnAction in pairs(INIT_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({GetTraceback(err)}, 'INIT_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Initial function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	INIT_FUNC_LIST = nil
	-- 显示欢迎信息
	MY.Sysmsg({_L('%s, welcome to use mingyi plugins!', GetClientPlayer().szName) .. ' v' .. MY.GetVersion() .. ' Build ' .. MY.GetAddonInfo().szBuild})
end
MY.RegisterEvent('LOADING_ENDING', OnInit) -- 不能用FIRST_LOADING_END 不然注册快捷键就全跪了

-- 注册初始化函数
-- RegisterInit(string id, function fn) -- 注册
-- RegisterInit(function fn)            -- 注册
-- RegisterInit(string id)              -- 注销
function MY.RegisterInit(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			INIT_FUNC_LIST[szKey] = fnAction
		else
			table.insert(INIT_FUNC_LIST, fnAction)
		end
	elseif szKey then
		INIT_FUNC_LIST[szKey] = nil
	end
end

function MY.IsInitialized()
	return not INIT_FUNC_LIST
end
end

do local EXIT_FUNC_LIST = {}
local function OnExit()
	for szKey, fnAction in pairs(EXIT_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({GetTraceback(err)}, 'EXIT_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Exit function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	EXIT_FUNC_LIST = nil
end
MY.RegisterEvent('GAME_EXIT', OnExit)
MY.RegisterEvent('PLAYER_EXIT_GAME', OnExit)
MY.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnExit)

-- 注册游戏结束函数
-- RegisterExit(string id, function fn) -- 注册
-- RegisterExit(function fn)            -- 注册
-- RegisterExit(string id)              -- 注销
function MY.RegisterExit(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			EXIT_FUNC_LIST[szKey] = fnAction
		else
			table.insert(EXIT_FUNC_LIST, fnAction)
		end
	elseif szKey then
		EXIT_FUNC_LIST[szKey] = nil
	end
end
end

do local RELOAD_FUNC_LIST = {}
local function OnReload()
	for szKey, fnAction in pairs(RELOAD_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({GetTraceback(err)}, 'RELOAD_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Reload function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	RELOAD_FUNC_LIST = nil
end
MY.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnReload)

-- 注册插件重载函数
-- RegisterReload(string id, function fn) -- 注册
-- RegisterReload(function fn)            -- 注册
-- RegisterReload(string id)              -- 注销
function MY.RegisterReload(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			RELOAD_FUNC_LIST[szKey] = fnAction
		else
			table.insert(RELOAD_FUNC_LIST, fnAction)
		end
	elseif szKey then
		RELOAD_FUNC_LIST[szKey] = nil
	end
end
end

do local IDLE_FUNC_LIST, TIME = {}, 0
local function OnIdle()
	local nTime = GetTime()
	if nTime - TIME < 20000 then
		return
	end
	for szKey, fnAction in pairs(IDLE_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({GetTraceback(err)}, 'IDLE_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Idle function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	TIME = nTime
end
MY.RegisterEvent('ON_FRAME_CREATE', function()
	if arg0:GetName() == 'OptionPanel' then
		OnIdle()
	end
end)
MY.RegisterEvent('BUFF_UPDATE', function()
	if arg1 then
		return
	end
	if arg0 == UI_GetClientPlayerID() and arg4 == 103 then
		DelayCall('MY_ON_IDLE', math.random(0, 10000), function()
			local me = GetClientPlayer()
			if me and me.GetBuff(103, 0) then
				OnIdle()
			end
		end)
	end
end)
MY.BreatheCall('MY_ON_IDLE', function()
	if Station.GetIdleTime() > 300000 then
		OnIdle()
	end
end)

-- 注册游戏空闲函数 -- 用户存储数据等操作
-- RegisterIdle(string id, function fn) -- 注册
-- RegisterIdle(function fn)            -- 注册
-- RegisterIdle(string id)              -- 注销
function MY.RegisterIdle(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			IDLE_FUNC_LIST[szKey] = fnAction
		else
			table.insert(IDLE_FUNC_LIST, fnAction)
		end
	elseif szKey then
		IDLE_FUNC_LIST[szKey] = nil
	end
end
end

do
local MODULE_LIST = {}
function MY.RegisterModuleEvent(arg0, arg1)
	local szModule = arg0
	if arg1 == false then
		local tEvent, nCount = MODULE_LIST[szModule], 0
		if tEvent then
			for szKey, info in pairs(tEvent) do
				if info.szEvent == "#BREATHE" then
					MY.BreatheCall(szKey, false)
				else
					MY.RegisterEvent(szKey, false)
				end
				nCount = nCount + 1
			end
			MODULE_LIST[szModule] = nil
			MY.Debug({"Uninit # "  .. szModule .. " # Events Removed # " .. nCount}, 'MY#EVENT', MY_DEBUG.LOG)
		end
	elseif IsTable(arg1) then
		local nCount = 0
		local tEvent = MODULE_LIST[szModule]
		if not tEvent then
			tEvent = {}
			MODULE_LIST[szModule] = tEvent
		end
		for _, aParams in ipairs(arg1) do
			local szEvent = remove(aParams, 1)
			local nPos, szSubKey = StringFindW(szEvent, '.')
			if nPos then
				szSubKey = sub(szEvent, nPos + 1)
				szEvent = sub(szEvent, 1, nPos - 1)
			end
			local szKey = szEvent .. '.' .. szModule
			if szSubKey then
				szKey = szKey .. '#' .. szSubKey
			end
			if szEvent == "#BREATHE" then
				MY.BreatheCall(szKey, unpack(aParams))
			else
				MY.RegisterEvent(szKey, unpack(aParams))
			end
			nCount = nCount + 1
			tEvent[szKey] = { szEvent = szEvent }
		end
		MY.Debug({"Init # "  .. szModule .. " # Events Added # " .. nCount}, 'MY#EVENT', MY_DEBUG.LOG)
	end
end
end

do
local TUTORIAL_LIST = {}
function MY.RegisterTutorial(tOptions)
	if type(tOptions) ~= 'table' or not tOptions.szKey or not tOptions.szMessage then
		return
	end
	insert(TUTORIAL_LIST, MY.FullClone(tOptions))
end

local CHECKED = {}
local function GetNextTutorial()
	for _, p in ipairs(TUTORIAL_LIST) do
		if not CHECKED[p.szKey] and (not p.fnRequire or p.fnRequire()) then
			return p
		end
	end
end
MY.RegisterInit(function()
	CHECKED = MY.LoadLUAData({'config/tutorialed.jx3dat', MY_DATA_PATH.ROLE})
	if not IsTable(CHECKED) then
		CHECKED = {}
	end
end)
MY.RegisterExit(function() MY.SaveLUAData({'config/tutorialed.jx3dat', MY_DATA_PATH.ROLE}, CHECKED) end)

local function StepNext(bQuick)
	local tutorial = GetNextTutorial()
	if not tutorial then
		return
	end
	if bQuick then
		local menu = tutorial[1]
		for i, p in ipairs(tutorial) do
			if p.bDefault then
				menu = p
			end
		end
		if menu and menu.fnAction then
			menu.fnAction()
		end
		CHECKED[tutorial.szKey] = true
		return StepNext(bQuick)
	end
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = 'MY_Tutorial',
		szMessage = tutorial.szMessage,
		szAlignment = 'CENTER',
	}
	for _, p in ipairs(tutorial) do
		local menu = MY.FullClone(p)
		menu.fnAction = function()
			if p.fnAction then
				p.fnAction()
			end
			CHECKED[tutorial.szKey] = true
			StepNext()
		end
		insert(tMsg, menu)
	end
	MessageBox(tMsg)
end

function MY.CheckTutorial()
	if not GetNextTutorial() then
		return
	end
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = 'MY_Tutorial',
		szMessage = _L['Welcome to use MY plugin, would you like to start quick tutorial now?'],
		szAlignment = 'CENTER',
		{
			szOption = _L['Quickset'],
			fnAction = function() StepNext(true) end,
		},
		{
			szOption = _L['Manually'],
			fnAction = function() StepNext() end,
		},
		{
			szOption = _L['Later'],
		},
	}
	MessageBox(tMsg)
end
end

do
local BG_MSG_ID_PREFIX = 'MY:'
local BG_MSG_ID_SUFFIX = ':V1'
do
local BG_MSG_LIST = {}
------------------------------------
--            背景通讯             --
------------------------------------
-- ON_BG_CHANNEL_MSG
-- arg0: 消息szKey
-- arg1: 消息来源频道
-- arg2: 消息发布者ID
-- arg3: 消息发布者名字
-- arg4: 不定长参数数组数据
------------------------------------
do
local BG_MSG_PART = {}
local function OnBgMsg()
	local szMsgSID, nChannel, dwID, szName, aMsg, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == UI_GetClientPlayerID()
	if not szMsgSID or szMsgSID:sub(1, #BG_MSG_ID_PREFIX) ~= BG_MSG_ID_PREFIX or szMsgSID:sub(-#BG_MSG_ID_SUFFIX) ~= BG_MSG_ID_SUFFIX then
		return
	end
	local szMsgID = szMsgSID:sub(#BG_MSG_ID_PREFIX + 1, -#BG_MSG_ID_SUFFIX - 1)
	if not BG_MSG_LIST[szMsgID] then
		return
	end
	-- pagination
	local szMsgUUID, nSegCount, nSegIndex, szPart = aMsg[1].u, aMsg[1].c, aMsg[1].i, aMsg[2]
	if not BG_MSG_PART[szMsgUUID] then
		BG_MSG_PART[szMsgUUID] = {}
	end
	BG_MSG_PART[szMsgUUID][nSegIndex] = szPart
	-- fire progress event
	for szKey, p in pairs(BG_MSG_LIST[szMsgID]) do
		if p.fnProgress then
			local status, err = pcall(p.fnProgress, szMsgID, nChannel, dwID, szName, bSelf, nSegCount, #BG_MSG_PART[szMsgUUID], nSegIndex)
			if not status then
				MY.Debug({GetTraceback(err)}, 'BG_EVENT_PROGRESS#' .. szMsgID .. '.' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
	-- concat and decode data
	if #BG_MSG_PART[szMsgUUID] == nSegCount then
		local szParam = concat(BG_MSG_PART[szMsgUUID])
		local szPlain = szParam and MY.SimpleDecryptString(szParam)
		local aParam = szPlain and str2var(szPlain)
		if aParam then
			for szKey, p in pairs(BG_MSG_LIST[szMsgID]) do
				local status, err = pcall(p.fnAction, szMsgID, nChannel, dwID, szName, bSelf, unpack(aParam))
				if not status then
					MY.Debug({GetTraceback(err)}, 'BG_EVENT#' .. szMsgID .. '.' .. szKey, MY_DEBUG.ERROR)
				end
			end
		else
			MY.Debug({GetTraceback('Cannot decode bgmsg')}, 'BG_EVENT#' .. szMsgID, MY_DEBUG.ERROR)
		end
		BG_MSG_PART[szMsgUUID] = nil
	end
end
MY.RegisterEvent('ON_BG_CHANNEL_MSG', OnBgMsg)
end

-- MY.RegisterBgMsg('MY_CHECK_INSTALL', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oDatas...) MY.SendBgMsg(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- MY.RegisterBgMsg('MY_CHECK_INSTALL') -- 注销
-- MY.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oDatas...) MY.SendBgMsg(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- MY.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01') -- 注销
function MY.RegisterBgMsg(szMsgID, fnAction, fnProgress)
	if type(szMsgID) == 'table' then
		for _, szMsgID in ipairs(szMsgID) do
			MY.RegisterBgMsg(szMsgID, fnAction)
		end
		return
	end
	local szKey = nil
	local nPos = StringFindW(szMsgID, '.')
	if nPos then
		szKey = string.sub(szMsgID, nPos + 1)
		szMsgID = string.sub(szMsgID, 1, nPos - 1)
	end
	if fnAction then
		if not BG_MSG_LIST[szMsgID] then
			BG_MSG_LIST[szMsgID] = {}
		end
		if not szKey then
			szKey = GetTickCount()
			while BG_MSG_LIST[szMsgID][tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		BG_MSG_LIST[szMsgID][szKey] = { fnAction = fnAction, fnProgress = fnProgress }
	elseif BG_MSG_LIST[szMsgID] then
		if szKey then
			BG_MSG_LIST[szMsgID][szKey] = nil
		else
			BG_MSG_LIST[szMsgID] = nil
		end
	end
	return szKey
end
end

do
local MAX_CHANNEL_LEN = setmetatable({
	[PLAYER_TALK_CHANNEL.RAID] = 500,
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = 500,
}, { __index = function() return 300 end })
-- MY.SendBgMsg(szName, szMsgID, ...)
-- MY.SendBgMsg(nChannel, szMsgID, ...)
function MY.SendBgMsg(nChannel, szMsgID, ...)
	local szTarget, me = '', GetClientPlayer()
	if not (me and nChannel) then
		return
	end
	-- channel
	if type(nChannel) == 'string' then
		szTarget = nChannel
		nChannel = PLAYER_TALK_CHANNEL.WHISPER
	end
	-- auto switch battle field
	if nChannel == PLAYER_TALK_CHANNEL.RAID
	and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	end
	-- encode and pagination
	local szMsgSID = BG_MSG_ID_PREFIX .. szMsgID .. BG_MSG_ID_SUFFIX
	local szMsgUUID = MY.GetUUID():gsub('-', '')
	local szArg = MY.SimpleEncryptString(var2str({...}))
	local nMsgLen = wlen(szArg)
	local nSegLen = MAX_CHANNEL_LEN[nChannel]
	local nSegCount = ceil(nMsgLen / nSegLen)
	-- send msg
	for nSegIndex = 1, nSegCount do
		local aSay = {
			{ type = 'eventlink', name = 'BG_CHANNEL_MSG', linkinfo = szMsgSID },
			{ type = 'eventlink', name = '', linkinfo = var2str({ u = szMsgUUID, c = nSegCount, i = nSegIndex }) },
			{ type = 'eventlink', name = '', linkinfo = var2str(wsub(szArg, (nSegIndex - 1) * nSegLen + 1, nSegIndex * nSegLen)) },
		}
		me.Talk(nChannel, szTarget, aSay)
	end
end
end
end
