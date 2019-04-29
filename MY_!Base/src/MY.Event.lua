--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 事件处理相关函数
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
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
---------------------------------------------------------------------------------------------
-- 事件注册
---------------------------------------------------------------------------------------------
-- 通用注册函数
-- CommonEventRegister(E, szID, fnAction)
-- table    E              事件描述信息
-- boolean  E.bSingleEvent 该事件没有子事件，即 szID 全部赋值给 szKey、 szEvent 为定值
-- string   szID           事件ID
-- function fnAction       事件响应函数
-- 外部使用文档：
--   RegisterXXX(string id, function fn) -- 注册
--   RegisterXXX(function fn)            -- 注册
--   RegisterXXX(string id)              -- 查询
--   RegisterXXX(string id, false)       -- 注销
-- 注：
--   当 E.bSingleEvent 为 true 时，可在id后面加一个点并紧跟
--   一个标识字符串用于防止重复或取消绑定，如 LOADING_END.xxx
local function CommonEventRegister(E, szID, fnAction)
	if IsTable(szID) then
		for _, szID in ipairs(szID) do
			CommonEventRegister(E, szID, fnAction)
		end
		return
	end
	local szKey, szEvent
	if E.bSingleEvent then
		szKey = szID
		szEvent = 'SINGLE_EVENT'
	else
		local nPos = StringFindW(szID, '.')
		if nPos then
			szKey = sub(szID, nPos + 1)
			szEvent = sub(szID, 1, nPos - 1)
		else
			szEvent = szID
		end
	end
	if IsFunction(fnAction) then
		if not E.tList then
			E.tList = {}
		end
		if not E.tList[szEvent] then
			E.tList[szEvent] = {}
			if E.OnCreateEvent then
				E.OnCreateEvent(szEvent)
			end
		end
		if not IsString(szKey) then
			szKey = GetTickCount() * 1000
			while E.tList[szEvent][tostring(szKey)] do
				szKey = szKey + 1
			end
			szKey = tostring(szKey)
		end
		if szEvent == 'SINGLE_EVENT' then
			szID = szKey
		else
			szID = szID .. '.' .. szKey
		end
		E.tList[szEvent][szKey] = { szID = szID, fnAction = fnAction }
	elseif fnAction == false then
		if E.tList and E.tList[szEvent] then
			if szKey then
				E.tList[szEvent][szKey] = nil
				if IsEmpty(E.tList[szEvent]) then
					E.tList[szEvent] = nil
				end
			else
				E.tList[szEvent] = nil
			end
			if not E.tList[szEvent] and E.OnRemoveEvent then
				E.OnRemoveEvent(szEvent)
			end
			if IsEmpty(E.tList) then
				E.tList = nil
			end
		end
	elseif szKey and E.tList and E.tList[szEvent] and E.tList[szEvent][szKey] then
		return true
	end
	return szKey
end

local function CommonEventFirer(E, arg0, ...)
	local szEvent = E.bSingleEvent and 'SINGLE_EVENT' or arg0
	local tEvent = E.tList and szEvent and E.tList[szEvent]
	if tEvent then
		for szKey, p in pairs(tEvent) do
			local nStartTick = GetTickCount()
			local status, err = pcall(p.fnAction, arg0, ...)
			if not status then
				LIB.Debug({GetTraceback(err)}, 'On' .. E.szName .. '#' .. p.szID, DEBUG_LEVEL.ERROR)
			end
			LIB.Debug({_L('%s function <%s> executed in %dms.', E.szName, szKey, GetTickCount() - nStartTick)}, _L['PMTool'], DEBUG_LEVEL.LOG)
		end
	end
end

-- 注册游戏事件监听
-- LIB.RegisterEvent(szEvent, fnAction) -- 注册
-- LIB.RegisterEvent(szEvent, false) -- 注销
-- (string)   szEvent  事件，可在后面加一个点并紧跟一个标识字符串用于防止重复或取消绑定，如 LOADING_END.xxx
-- (function) fnAction 事件处理函数，传入 false 相当于取消该事件
--特别注意：当 fnAction 为 false 并且 szKey 为 nil 时会取消所有通过本函数注册的事件处理器
do
local GLBAL_EVENT = { szName = 'Event' }
local function EventHandler(szEvent, ...)
	CommonEventFirer(GLBAL_EVENT, szEvent, ...)
end
function GLBAL_EVENT.OnCreateEvent(szEvent)
	RegisterEvent(szEvent, EventHandler)
end
function GLBAL_EVENT.OnRemoveEvent(szEvent)
	if not szEvent then
		return
	end
	UnRegisterEvent(szEvent, EventHandler)
end
function LIB.RegisterEvent(szEvent, fnAction)
	return CommonEventRegister(GLBAL_EVENT, szEvent, fnAction)
end
end

do
local INIT_EVENT = { szName = 'Initial', bSingleEvent = true }
local function OnInit()
	if not INIT_EVENT then
		return
	end
	LIB.CreateDataRoot(PATH_TYPE.ROLE)
	LIB.CreateDataRoot(PATH_TYPE.GLOBAL)
	LIB.CreateDataRoot(PATH_TYPE.SERVER)

	CommonEventFirer(INIT_EVENT)
	INIT_EVENT = nil
	-- 显示欢迎信息
	LIB.Sysmsg({_L('%s, welcome to use mingyi plugins!', GetClientPlayer().szName) .. ' v' .. LIB.GetVersion() .. ' Build ' .. LIB.GetAddonInfo().szBuild})
end
LIB.RegisterEvent('LOADING_ENDING', OnInit) -- 不能用FIRST_LOADING_END 不然注册快捷键就全跪了

-- 注册初始化函数
-- RegisterInit(string id, function fn) -- 注册
-- RegisterInit(function fn)            -- 注册
-- RegisterInit(string id, false)       -- 注销
function LIB.RegisterInit(...)
	return CommonEventRegister(INIT_EVENT, ...)
end

function LIB.IsInitialized()
	return not INIT_EVENT
end
end

do
local EXIT_EVENT = { szName = 'Exit', bSingleEvent = true }
local function OnExit()
	CommonEventFirer(EXIT_EVENT)
end
LIB.RegisterEvent('GAME_EXIT', OnExit)
LIB.RegisterEvent('PLAYER_EXIT_GAME', OnExit)
LIB.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnExit)

-- 注册游戏结束函数
-- RegisterExit(string id, function fn) -- 注册
-- RegisterExit(function fn)            -- 注册
-- RegisterExit(string id, false)       -- 注销
function LIB.RegisterExit(...)
	return CommonEventRegister(EXIT_EVENT, ...)
end
end

do
local RELOAD_EVENT = { szName = 'Reload', bSingleEvent = true }
local function OnReload()
	CommonEventFirer(RELOAD_EVENT)
end
LIB.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnReload)

-- 注册插件重载函数
-- RegisterReload(string id, function fn) -- 注册
-- RegisterReload(function fn)            -- 注册
-- RegisterReload(string id, false)       -- 注销
function LIB.RegisterReload(...)
	return CommonEventRegister(RELOAD_EVENT, ...)
end
end

do
local IDLE_EVENT, TIME = { szName = 'Idle', bSingleEvent = true }, 0
local function OnIdle()
	local nTime = GetTime()
	if nTime - TIME < 20000 then
		return
	end
	TIME = nTime
	CommonEventFirer(IDLE_EVENT)
end
LIB.RegisterEvent('ON_FRAME_CREATE', function()
	if arg0:GetName() == 'OptionPanel' then
		OnIdle()
	end
end)
LIB.RegisterEvent('BUFF_UPDATE', function()
	if arg1 then
		return
	end
	if arg0 == UI_GetClientPlayerID() and arg4 == 103 then
		DelayCall(LIB.GetAddonInfo().szNameSpace .. '#ON_IDLE', math.random(0, 10000), function()
			local me = GetClientPlayer()
			if me and me.GetBuff(103, 0) then
				OnIdle()
			end
		end)
	end
end)
LIB.BreatheCall(LIB.GetAddonInfo().szNameSpace .. '#ON_IDLE', function()
	if Station.GetIdleTime() > 300000 then
		OnIdle()
	end
end)

-- 注册游戏空闲函数 -- 用户存储数据等操作
-- RegisterIdle(string id, function fn) -- 注册
-- RegisterIdle(function fn)            -- 注册
-- RegisterIdle(string id, false)       -- 注销
function LIB.RegisterIdle(...)
	return CommonEventRegister(IDLE_EVENT, ...)
end
end

do
local MODULE_LIST = {}
function LIB.RegisterModuleEvent(arg0, arg1)
	local szModule = arg0
	if arg1 == false then
		local tEvent, nCount = MODULE_LIST[szModule], 0
		if tEvent then
			for szKey, info in pairs(tEvent) do
				if info.szEvent == "#BREATHE" then
					LIB.BreatheCall(szKey, false)
				else
					LIB.RegisterEvent(szKey, false)
				end
				nCount = nCount + 1
			end
			MODULE_LIST[szModule] = nil
			LIB.Debug({"Uninit # "  .. szModule .. " # Events Removed # " .. nCount}, 'MY#EVENT', DEBUG_LEVEL.LOG)
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
				LIB.BreatheCall(szKey, unpack(aParams))
			else
				LIB.RegisterEvent(szKey, unpack(aParams))
			end
			nCount = nCount + 1
			tEvent[szKey] = { szEvent = szEvent }
		end
		LIB.Debug({"Init # "  .. szModule .. " # Events Added # " .. nCount}, 'MY#EVENT', DEBUG_LEVEL.LOG)
	end
end
end

do
local TUTORIAL_LIST = {}
function LIB.RegisterTutorial(tOptions)
	if type(tOptions) ~= 'table' or not tOptions.szKey or not tOptions.szMessage then
		return
	end
	insert(TUTORIAL_LIST, LIB.FullClone(tOptions))
end

local CHECKED = {}
local function GetNextTutorial()
	for _, p in ipairs(TUTORIAL_LIST) do
		if not CHECKED[p.szKey] and (not p.fnRequire or p.fnRequire()) then
			return p
		end
	end
end
LIB.RegisterInit(function()
	CHECKED = LIB.LoadLUAData({'config/tutorialed.jx3dat', PATH_TYPE.ROLE})
	if not IsTable(CHECKED) then
		CHECKED = {}
	end
end)
LIB.RegisterExit(function() LIB.SaveLUAData({'config/tutorialed.jx3dat', PATH_TYPE.ROLE}, CHECKED) end)

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
		local menu = LIB.FullClone(p)
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

function LIB.CheckTutorial()
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
local BG_MSG_ID_PREFIX = LIB.GetAddonInfo().szNameSpace .. ':'
local BG_MSG_ID_SUFFIX = ':V1'
do
local BG_MSG_EVENT = { szName = 'BgMsg' }
local BG_MSG_PROGRESS_EVENT = { szName = 'BgMsgProgress' }
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
	if not CommonEventRegister(BG_MSG_EVENT, szMsgID) then
		return
	end
	-- pagination
	local szMsgUUID, nSegCount, nSegIndex, szPart = aMsg[1].u, aMsg[1].c, aMsg[1].i, aMsg[2]
	if not BG_MSG_PART[szMsgUUID] then
		BG_MSG_PART[szMsgUUID] = {}
	end
	BG_MSG_PART[szMsgUUID][nSegIndex] = szPart
	-- fire progress event
	CommonEventFirer(BG_MSG_PROGRESS_EVENT, szMsgID, nChannel, dwID, szName, bSelf, nSegCount, #BG_MSG_PART[szMsgUUID], nSegIndex)
	-- concat and decode data
	if #BG_MSG_PART[szMsgUUID] == nSegCount then
		local szParam = concat(BG_MSG_PART[szMsgUUID])
		local szPlain = szParam and LIB.SimpleDecryptString(szParam)
		local aParam = szPlain and str2var(szPlain)
		if aParam then
			CommonEventFirer(BG_MSG_EVENT, szMsgID, nChannel, dwID, szName, bSelf, unpack(aParam))
		else
			LIB.Debug({GetTraceback('Cannot decode bgmsg')}, 'BG_EVENT#' .. szMsgID, DEBUG_LEVEL.ERROR)
		end
		BG_MSG_PART[szMsgUUID] = nil
	end
end
LIB.RegisterEvent('ON_BG_CHANNEL_MSG', OnBgMsg)
end

-- LIB.RegisterBgMsg('MY_CHECK_INSTALL', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oDatas...) LIB.SendBgMsg(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- LIB.RegisterBgMsg('MY_CHECK_INSTALL') -- 注销
-- LIB.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oDatas...) LIB.SendBgMsg(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- LIB.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01') -- 注销
function LIB.RegisterBgMsg(szMsgID, fnAction, fnProgress)
	local szID = CommonEventRegister(BG_MSG_EVENT, szMsgID, fnAction)
	return CommonEventRegister(BG_MSG_PROGRESS_EVENT, szID, fnProgress)
end
end

do
local MAX_CHANNEL_LEN = setmetatable({
	[PLAYER_TALK_CHANNEL.RAID] = 500,
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = 500,
}, { __index = function() return 300 end })
-- LIB.SendBgMsg(szName, szMsgID, ...)
-- LIB.SendBgMsg(nChannel, szMsgID, ...)
function LIB.SendBgMsg(nChannel, szMsgID, ...)
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
	local szMsgUUID = LIB.GetUUID():gsub('-', '')
	local szArg = LIB.SimpleEncryptString(var2str({...}))
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

do
local FRAME_CREATE_EVENT = { szName = 'FrameCreate' }
local function OnFrameCreate()
	CommonEventFirer(FRAME_CREATE_EVENT, arg0:GetName(), arg0)
end
LIB.RegisterEvent('ON_FRAME_CREATE', OnFrameCreate)

-- 注册插件重载函数
-- RegisterFrameCreate(string id, function fn) -- 注册
-- RegisterFrameCreate(function fn)            -- 注册
-- RegisterFrameCreate(string id, false)       -- 注销
function LIB.RegisterFrameCreate(...)
	return CommonEventRegister(FRAME_CREATE_EVENT, ...)
end
end

do
local FRAME_DESTROY_EVENT = { szName = 'FrameCreate' }
local function OnFrameDestroy()
	CommonEventFirer(FRAME_DESTROY_EVENT, arg0:GetName(), arg0)
end
LIB.RegisterEvent('ON_FRAME_DESTROY', OnFrameDestroy)

-- 注册插件重载函数
-- RegisterFrameDestroy(string id, function fn) -- 注册
-- RegisterFrameDestroy(function fn)            -- 注册
-- RegisterFrameDestroy(string id, false)       -- 注销
function LIB.RegisterFrameDestroy(...)
	return CommonEventRegister(FRAME_DESTROY_EVENT, ...)
end
end
