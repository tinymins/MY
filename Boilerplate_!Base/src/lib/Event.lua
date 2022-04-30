--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 事件处理相关函数
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
---------------------------------------------------------------------------------------------
-- 事件注册
---------------------------------------------------------------------------------------------
do
local function CommonEventRegisterOperator(E, eAction, szEvent, szKey, fnAction)
	if eAction == 'REG' then
		if not E.tList then
			E.tList = {}
		end
		if not E.tList[szEvent] then
			E.tList[szEvent] = {
				tKey = {},
				aList = {},
			}
			if E.OnCreateEvent then
				E.OnCreateEvent(szEvent)
			end
		end
		local szID = szKey
		if not E.bSingleEvent then
			szID = szEvent .. '.' .. szID
		end
		for i, p in X.ipairs_r(E.tList[szEvent].aList) do
			if p.szKey == szKey then
				table.remove(E.tList[szEvent].aList, i)
				E.tList[szEvent].tKey[szKey] = nil
			end
		end
		table.insert(E.tList[szEvent].aList, { szKey = szKey, szID = szID, fnAction = fnAction })
		E.tList[szEvent].tKey[szKey] = true
	elseif eAction == 'UNREG' then
		if E.tList and E.tList[szEvent] then
			if szKey then
				for i, p in X.ipairs_r(E.tList[szEvent].aList) do
					if p.szKey == szKey then
						table.remove(E.tList[szEvent].aList, i)
						E.tList[szEvent].tKey[szKey] = nil
					end
				end
				if X.IsEmpty(E.tList[szEvent].aList) then
					E.tList[szEvent] = nil
				end
			else
				E.tList[szEvent] = nil
			end
			if not E.tList[szEvent] and E.OnRemoveEvent then
				E.OnRemoveEvent(szEvent)
			end
			if X.IsEmpty(E.tList) then
				E.tList = nil
			end
		end
	elseif eAction == 'FIND' then
		if szKey and E.tList then
			return E.tList[szEvent] and E.tList[szEvent].tKey[szKey] or false
		end
		if not szKey and E.tList and E.tList[szEvent] then
			return true
		end
		return false
	end
	return szKey
end
-- 通用注册函数
-- CommonEventRegister(E, szEvent, szKey, fnAction)
-- table    E              事件描述信息
-- boolean  E.bSingleEvent 该事件没有子事件，即参数仅接受 szKey 传入， szEvent 为定值
-- string   szEvent        事件名称，当 E.bSingleEvent 为真时省略该参数
-- string   szKey          事件唯一标示符，用于防止重复或取消绑定
-- function fnAction       事件响应函数
-- 外部使用文档：
--   E.bSingleEvent 为真：
--     RegisterXXX(string id, function fn) -- 注册
--     RegisterXXX(function fn)            -- 匿名注册
--     RegisterXXX(string id)              -- 查询
--     RegisterXXX(string id, false)       -- 注销
--   E.bSingleEvent 为假：
--     RegisterXXX(string event, string id, function fn) -- 注册
--     RegisterXXX(string event, function fn)            -- 匿名注册
--     RegisterXXX(string event, string id)              -- 查询
--     RegisterXXX(string event, string id, false)       -- 注销
-- 特别注意：当 fnAction 为 false 并且 szEvent、szKey 为 nil 时会取消所有通过本函数注册的事件处理器
local function CommonEventRegister(E, xArg1, xArg2, xArg3)
	local eAction, szEvent, szKey, fnAction
	if E.bSingleEvent then
		if X.IsFunction(xArg1) then
			eAction, fnAction = 'REG', xArg1
		elseif X.IsString(xArg1) and X.IsFunction(xArg2) then
			eAction, szKey, fnAction = 'REG', xArg1, xArg2
		elseif X.IsString(xArg1) and xArg2 == false then
			eAction, szKey = 'UNREG', xArg1
		elseif X.IsString(xArg1) and X.IsNil(xArg2) then
			eAction, szKey = 'FIND', xArg1
		end
		szEvent = 'SINGLE_EVENT'
	else
		if (X.IsString(xArg1) or X.IsArray(xArg1)) and X.IsFunction(xArg2) then
			eAction, szEvent, fnAction = 'REG', xArg1, xArg2
		elseif (X.IsString(xArg1) or X.IsArray(xArg1)) and X.IsString(xArg2) and X.IsFunction(xArg3) then
			eAction, szEvent, szKey, fnAction = 'REG', xArg1, xArg2, xArg3
		elseif (X.IsString(xArg1) or X.IsArray(xArg1)) and X.IsString(xArg2) and xArg3 == false then
			eAction, szEvent, szKey = 'UNREG', xArg1, xArg2
		elseif X.IsString(xArg1) and X.IsString(xArg2) and X.IsNil(xArg3) then
			eAction, szEvent, szKey = 'FIND', xArg1, xArg2
		elseif X.IsString(xArg1) and X.IsNil(xArg2) and X.IsNil(xArg3) then
			eAction, szEvent = 'FIND', xArg1
		end
	end
	assert(eAction, 'Parameters type not recognized, cannot infer action type.')
	-- 匿名注册分配随机标识符
	if eAction == 'REG' and not X.IsString(szKey) then
		szKey = GetTickCount() * 1000
		if X.IsString(szEvent) then
			if E.tList and E.tList[szEvent] then
				while E.tList[szEvent].tKey[tostring(szKey)] do
					szKey = szKey + 1
				end
			end
		elseif X.IsArray(szEvent) then
			if E.tList then
				while lodash.some(szEvent, function(szEvent) return E.tList[szEvent] and E.tList[szEvent].tKey[tostring(szKey)] end) do
					szKey = szKey + 1
				end
			end
		end
		szKey = tostring(szKey)
	end
	if X.IsTable(szEvent) then
		for _, szEvent in ipairs(szEvent) do
			CommonEventRegisterOperator(E, eAction, szEvent, szKey, fnAction)
		end
		return szKey
	end
	return CommonEventRegisterOperator(E, eAction, szEvent, szKey, fnAction)
end
X.CommonEventRegister = CommonEventRegister

local function FireEventRec(E, p, ...)
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]
	local res, err, trace = X.XpCall(p.fnAction, ...)
	if not res then
		X.ErrorLog(err, 'On' .. E.szName .. ': ' .. p.szID, trace)
	end
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	if nTickCount > 50 then
		X.Debug(
			_L['PMTool'],
			_L('%s function <%s> %s in %dms.', E.szName, p.szID, res and _L['succeed'] or _L['failed'], nTickCount),
			X.DEBUG_LEVEL.PMLOG)
	end
	--[[#DEBUG END]]
end

local function CommonEventFirer(E, arg0, ...)
	local szEvent = E.bSingleEvent and 'SINGLE_EVENT' or arg0
	if not E.tList or not szEvent then
		return
	end
	if szEvent == '*' then
		for szEvent, eve in pairs(E.tList) do
			if szEvent ~= '*' then
				for _, p in ipairs(eve.aList) do
					FireEventRec(E, p, arg0, ...)
				end
			end
		end
	else
		if E.tList[szEvent] then
			for _, p in ipairs(E.tList[szEvent].aList) do
				FireEventRec(E, p, arg0, ...)
			end
		end
	end
	if E.tList['*'] then
		for _, p in ipairs(E.tList['*'].aList) do
			FireEventRec(E, p, arg0, ...)
		end
	end
end
X.CommonEventFirer = CommonEventFirer
end

---------------------------------------------------------------------------------------------
-- 监听游戏事件
---------------------------------------------------------------------------------------------
do
local GLOBAL_EVENT = { szName = 'Event' }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function EventHandler(szEvent, ...)
	CommonEventFirer(GLOBAL_EVENT, szEvent, ...)
end
function GLOBAL_EVENT.OnCreateEvent(szEvent)
	RegisterEvent(szEvent, EventHandler)
end
function GLOBAL_EVENT.OnRemoveEvent(szEvent)
	if not szEvent then
		return
	end
	UnRegisterEvent(szEvent, EventHandler)
end
function X.RegisterEvent(...)
	return CommonEventRegister(GLOBAL_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听初始化完成事件
---------------------------------------------------------------------------------------------
do
local INIT_EVENT = { szName = 'Initial', bSingleEvent = true }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function OnInit()
	if not INIT_EVENT then
		return
	end
	if not X.AssertVersion('', '', '*') then
		return
	end
	X.CreateDataRoot(X.PATH_TYPE.ROLE)
	X.CreateDataRoot(X.PATH_TYPE.GLOBAL)
	X.CreateDataRoot(X.PATH_TYPE.SERVER)
	X.ConnectUserSettingsDB()
	CommonEventFirer(INIT_EVENT)
	INIT_EVENT = nil
	-- 显示欢迎信息
	X.Sysmsg(_L('%s, welcome to use %s!', X.GetUserRoleName(), X.PACKET_INFO.NAME)
		.. _L(' v%s Build %s', X.PACKET_INFO.VERSION, X.PACKET_INFO.BUILD))
end
X.RegisterEvent('LOADING_ENDING', OnInit) -- 不能用FIRST_LOADING_END 不然注册快捷键就全跪了

function X.RegisterInit(...)
	return CommonEventRegister(INIT_EVENT, ...)
end

function X.IsInitialized()
	return not INIT_EVENT
end
end

---------------------------------------------------------------------------------------------
-- 监听游戏结束事件
---------------------------------------------------------------------------------------------
do
local EXIT_EVENT = { szName = 'Exit', bSingleEvent = true }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function OnExit()
	X.FireFlush()
	CommonEventFirer(EXIT_EVENT)
	X.ReleaseUserSettingsDB()
	X.DeleteAncientLogs()
end
X.RegisterEvent('GAME_EXIT', OnExit)
X.RegisterEvent('PLAYER_EXIT_GAME', OnExit)
X.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnExit)

function X.RegisterExit(...)
	return CommonEventRegister(EXIT_EVENT, ...)
end
end

do
local FLUSH_EVENT = { szName = 'Flush', bSingleEvent = true }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
function X.FireFlush()
	X.FlushCoroutine()
	CommonEventFirer(FLUSH_EVENT)
	X.FlushUserSettingsDB()
end

function X.RegisterFlush(...)
	return CommonEventRegister(FLUSH_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听插件重载事件
---------------------------------------------------------------------------------------------
do
local RELOAD_EVENT = { szName = 'Reload', bSingleEvent = true }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function OnReload()
	X.FlushCoroutine()
	CommonEventFirer(RELOAD_EVENT)
	X.ReleaseUserSettingsDB()
end
X.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnReload)

function X.RegisterReload(...)
	return CommonEventRegister(RELOAD_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听面板打开事件
---------------------------------------------------------------------------------------------
do
local FRAME_CREATE_EVENT = { szName = 'FrameCreate' }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function OnFrameCreate()
	CommonEventFirer(FRAME_CREATE_EVENT, arg0:GetName(), arg0)
end
X.RegisterEvent('ON_FRAME_CREATE', OnFrameCreate)

function X.RegisterFrameCreate(...)
	return CommonEventRegister(FRAME_CREATE_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听面板关闭事件
---------------------------------------------------------------------------------------------
do
local FRAME_DESTROY_EVENT = { szName = 'FrameCreate' }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function OnFrameDestroy()
	CommonEventFirer(FRAME_DESTROY_EVENT, arg0:GetName(), arg0)
end
X.RegisterEvent('ON_FRAME_DESTROY', OnFrameDestroy)

function X.RegisterFrameDestroy(...)
	return CommonEventRegister(FRAME_DESTROY_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听游戏空闲事件
---------------------------------------------------------------------------------------------
do
local IDLE_EVENT, TIME = { szName = 'Idle', bSingleEvent = true }, 0
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function OnIdle()
	local nTime = GetTime()
	if nTime - TIME < 20000 then
		return
	end
	TIME = nTime
	CommonEventFirer(IDLE_EVENT)
end
X.RegisterEvent('BUFF_UPDATE', function()
	if arg1 then
		return
	end
	if arg0 == UI_GetClientPlayerID() and arg4 == 103 then
		DelayCall(X.NSFormatString('{$NS}#ON_IDLE'), math.random(0, 10000), function()
			local me = GetClientPlayer()
			if me and me.GetBuff(103, 0) then
				OnIdle()
			end
		end)
	end
end)
X.BreatheCall(X.NSFormatString('{$NS}#ON_IDLE'), function()
	if Station.GetIdleTime() > 300000 then
		OnIdle()
	end
end)
X.RegisterFrameCreate('OptionPanel', OnIdle)

function X.RegisterIdle(...)
	return CommonEventRegister(IDLE_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听 CTRL ALT SHIFT 按键
---------------------------------------------------------------------------------------------
do
local SPECIAL_KEY_EVENT = { szName = 'SpecialKey' }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local ALT, SHIFT, CTRL = false, false, false
X.BreatheCall(X.NSFormatString('{$NS}#ON_SPECIAL_KEY'), function()
	if IsShiftKeyDown() then
		if not SHIFT then
			SHIFT = true
			CommonEventFirer(SPECIAL_KEY_EVENT, 'SHIFT_KEY_DOWN')
		end
	else
		if SHIFT then
			SHIFT = false
			CommonEventFirer(SPECIAL_KEY_EVENT, 'SHIFT_KEY_UP')
		end
	end
	if IsCtrlKeyDown() then
		if not CTRL then
			CTRL = true
			CommonEventFirer(SPECIAL_KEY_EVENT, 'CTRL_KEY_DOWN')
		end
	else
		if CTRL then
			CTRL = false
			CommonEventFirer(SPECIAL_KEY_EVENT, 'CTRL_KEY_UP')
		end
	end
	if IsAltKeyDown() then
		if not ALT then
			ALT = true
			CommonEventFirer(SPECIAL_KEY_EVENT, 'ALT_KEY_DOWN')
		end
	else
		if ALT then
			ALT = false
			CommonEventFirer(SPECIAL_KEY_EVENT, 'ALT_KEY_UP')
		end
	end
end)
function X.RegisterSpecialKeyEvent(...)
	return CommonEventRegister(SPECIAL_KEY_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 注册模块
---------------------------------------------------------------------------------------------
do
local MODULE_LIST = {}
function X.RegisterModuleEvent(arg0, arg1)
	local szModule = arg0
	if arg1 == false then
		local tEvent, nCount = MODULE_LIST[szModule], 0
		if tEvent then
			for szEvent, info in pairs(tEvent) do
				if info.szEvent == '#BREATHE' then
					X.BreatheCall(szModule .. '#BREATHE', false)
				else
					X.RegisterEvent(szEvent, szModule, false)
				end
				nCount = nCount + 1
			end
			MODULE_LIST[szModule] = nil
			--[[#DEBUG BEGIN]]
			X.Debug(X.NSFormatString('{$NS}#EVENT'), 'Uninit # '  .. szModule .. ' # Events Removed # ' .. nCount, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
	elseif X.IsTable(arg1) then
		local nCount = 0
		local tEvent = MODULE_LIST[szModule]
		if not tEvent then
			tEvent = {}
			MODULE_LIST[szModule] = tEvent
		end
		for _, aParams in ipairs(arg1) do
			local szEvent = table.remove(aParams, 1)
			if szEvent == '#BREATHE' then
				X.BreatheCall(szModule .. '#BREATHE', X.Unpack(aParams))
			else
				X.RegisterEvent(szEvent, szModule, X.Unpack(aParams))
			end
			nCount = nCount + 1
			tEvent[szEvent] = { szEvent = szEvent }
		end
		--[[#DEBUG BEGIN]]
		X.Debug(X.NSFormatString('{$NS}#EVENT'), 'Init # '  .. szModule .. ' # Events Added # ' .. nCount, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end
end

---------------------------------------------------------------------------------------------
-- 注册新手引导
---------------------------------------------------------------------------------------------
do
local TUTORIAL_LIST = {}
function X.RegisterTutorial(tOptions)
	if type(tOptions) ~= 'table' or not tOptions.szKey or not tOptions.szMessage then
		return
	end
	table.insert(TUTORIAL_LIST, X.Clone(tOptions, true))
end

local CHECKED = {}
local function GetNextTutorial()
	for _, p in ipairs(TUTORIAL_LIST) do
		if not CHECKED[p.szKey] and (not p.fnRequire or p.fnRequire()) then
			return p
		end
	end
end
X.RegisterInit(function()
	CHECKED = X.LoadLUAData({'config/tutorialed.jx3dat', X.PATH_TYPE.ROLE})
	if not X.IsTable(CHECKED) then
		CHECKED = {}
	end
end)
X.RegisterFlush(function() X.SaveLUAData({'config/tutorialed.jx3dat', X.PATH_TYPE.ROLE}, CHECKED) end)

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
		szName = X.NSFormatString('{$NS}_Tutorial'),
		szMessage = tutorial.szMessage,
		szAlignment = 'CENTER',
	}
	for _, p in ipairs(tutorial) do
		local menu = X.Clone(p, true)
		menu.fnAction = function()
			if p.fnAction then
				p.fnAction()
			end
			CHECKED[tutorial.szKey] = true
			StepNext()
		end
		table.insert(tMsg, menu)
	end
	MessageBox(tMsg)
end

function X.CheckTutorial()
	if not GetNextTutorial() then
		return
	end
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = X.NSFormatString('{$NS}_Tutorial'),
		szMessage = _L('Welcome to use %s, would you like to start quick tutorial now?', X.PACKET_INFO.NAME),
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

---------------------------------------------------------------------------------------------
-- 背景通讯
---------------------------------------------------------------------------------------------
do
local BG_MSG_ID_PREFIX = X.NSFormatString('{$NS}:')
local BG_MSG_ID_SUFFIX = ':V2'
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
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
	BG_MSG_PART[szMsgUUID][nSegIndex] = X.SimpleDecryptString(X.IsString(szPart) and szPart or '')
	-- fire progress event
	local nSegRecv = 0
	for _, _ in pairs(BG_MSG_PART[szMsgUUID]) do
		nSegRecv = nSegRecv + 1
	end
	CommonEventFirer(BG_MSG_PROGRESS_EVENT, szMsgID, nSegCount, nSegRecv, nSegIndex, nChannel, dwID, szName, bSelf)
	-- concat and decode data
	if #BG_MSG_PART[szMsgUUID] == nSegCount then
		local szPlain = table.concat(BG_MSG_PART[szMsgUUID])
		local aData = szPlain and X.DecodeLUAData(szPlain)
		if aData then
			CommonEventFirer(BG_MSG_EVENT, szMsgID, aData[1], nChannel, dwID, szName, bSelf)
		--[[#DEBUG BEGIN]]
		else
			X.Debug('BG_EVENT#' .. szMsgID, X.GetTraceback('Cannot decode BgMsg: ' .. szPlain), X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		end
		BG_MSG_PART[szMsgUUID] = nil
	end
end
X.RegisterEvent('ON_BG_CHANNEL_MSG', OnBgMsg)
end

-- X.RegisterBgMsg('{$NS}_CHECK_INSTALL', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oData) X.SendBgMsg(szTalkerName, '{$NS}_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- X.RegisterBgMsg('{$NS}_CHECK_INSTALL') -- 注销
-- X.RegisterBgMsg('{$NS}_CHECK_INSTALL.RECEIVER_01', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oData) X.SendBgMsg(szTalkerName, '{$NS}_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- X.RegisterBgMsg('{$NS}_CHECK_INSTALL.RECEIVER_01') -- 注销
function X.RegisterBgMsg(szMsgID, szID, fnAction, fnProgress)
	if not X.IsString(szID) then
		szID, fnAction, fnProgress = nil, szID, fnAction
	end
	if fnAction == false then
		fnProgress = false
	end
	if szID then
		CommonEventRegister(BG_MSG_EVENT, szMsgID, szID, fnAction)
	else
		szID = CommonEventRegister(BG_MSG_EVENT, szMsgID, fnAction)
	end
	return CommonEventRegister(BG_MSG_PROGRESS_EVENT, szMsgID, szID, fnProgress)
end
end

do
local MAX_CHANNEL_LEN = setmetatable({
	[PLAYER_TALK_CHANNEL.RAID] = 300,
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = 300,
}, { __index = function() return 130 end })
-- 是否可以发送消息
local function GetSenderStatus(me)
	if not me then
		return 'NO_PLAYER'
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return 'TALK_LOCK'
	end
	return 'READY'
end
-- 无法发送时的缓存队列
local BG_MSG_QUEUE = {}
local function ProcessQueue()
	if GetSenderStatus(GetClientPlayer()) ~= 'READY' then
		return
	end
	local v = table.remove(BG_MSG_QUEUE, 1)
	if not v then
		return 0
	end
	X.SendBgMsg(X.Unpack(v))
end
-- X.SendBgMsg(szName, szMsgID, oData)
-- X.SendBgMsg(nChannel, szMsgID, oData)
function X.SendBgMsg(nChannel, szMsgID, oData, bSilent)
	local szTarget, me = '', GetClientPlayer()
	if not nChannel then
		return
	end
	local szStatus = GetSenderStatus(me)
	if szStatus ~= 'READY' then
		if szStatus == 'TALK_LOCK' and not bSilent then
			X.Systopmsg(_L['BgMsg cannot be send due to talk lock, data will be sent as soon as talk unlocked.'])
		end
		table.insert(BG_MSG_QUEUE, X.Pack(nChannel, szMsgID, oData))
		X.BreatheCall(X.NSFormatString('{$NS}#BG_MSG_QUEUE'), ProcessQueue)
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
	local szMsgUUID = X.GetUUID():gsub('-', '')
	local szArg = X.EncodeLUAData({oData}) -- 如果发送nil，不包一层会被解析器误认为解码失败，所以必须用{}包裹
	local nMsgLen = wstring.len(szArg)
	local nSegLen = math.floor(MAX_CHANNEL_LEN[nChannel] / 4 * 3) -- Base64编码会导致长度增加
	local nSegCount = math.ceil(nMsgLen / nSegLen)
	-- send msg
	for nSegIndex = 1, nSegCount do
		local szSeg = X.SimpleEncryptString((wstring.sub(szArg, (nSegIndex - 1) * nSegLen + 1, nSegIndex * nSegLen)))
		local aSay = {
			{ type = 'eventlink', name = 'BG_CHANNEL_MSG', linkinfo = szMsgSID },
			{ type = 'eventlink', name = '', linkinfo = X.EncodeLUAData({ u = szMsgUUID, c = nSegCount, i = nSegIndex }) },
			{ type = 'eventlink', name = '', linkinfo = X.EncodeLUAData(szSeg) },
		}
		me.Talk(nChannel, szTarget, aSay)
	end
end
end
end

---------------------------------------------------------------------------------------------
-- 注册聊天监听
---------------------------------------------------------------------------------------------
-- Register:   X.RegisterMsgMonitor(string szKey, function fnAction)
-- Unregister: X.RegisterMsgMonitor(string szKey, false)
do
local MSGMON_EVENT = { szName = 'MsgMonitor' }
local CommonEventFirer = X.CommonEventFirer
local CommonEventRegister = X.CommonEventRegister
local function FixMsgMonBug() end
local function MsgMonHandler(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
	if bRich then
		-- filter addon comm.
		if StringFindW(szMsg, 'eventlink') and StringFindW(szMsg, _L['Addon comm.']) then
			return
		end
		-- filter addon echo message.
		if X.ContainsEchoMsgHeader(szMsg) then
			return
		end
	end
	CommonEventFirer(MSGMON_EVENT, szChannel, szMsg, nFont, bRich, r, g, b, dwTalkerID, szName)
end
function MSGMON_EVENT.OnCreateEvent(szEvent)
	if not szEvent then
		return
	end
	-- BUG: 首个注册的消息监听是个聋子，收不到消息，不知道官方代码什么逻辑
	RegisterMsgMonitor(FixMsgMonBug, { szEvent })
	RegisterMsgMonitor(MsgMonHandler, { szEvent })
end
function MSGMON_EVENT.OnRemoveEvent(szEvent)
	if not szEvent then
		return
	end
	UnRegisterMsgMonitor(FixMsgMonBug, { szEvent })
	UnRegisterMsgMonitor(MsgMonHandler, { szEvent })
end
function X.RegisterMsgMonitor(...)
	return CommonEventRegister(MSGMON_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 注册协程
---------------------------------------------------------------------------------------------
do
local COROUTINE_TIME = 1000 * 0.5 / ENVIRONMENT.GAME_FPS -- 一次 Breathe 时最大允许执行协程时间
local COROUTINE_LIST = {}
local yield = coroutine and coroutine.yield or function() end
function X.RegisterCoroutine(szKey, fnAction, fnCallback)
	if X.IsTable(szKey) then
		for _, szKey in ipairs(szKey) do
			X.RegisterCoroutine(szKey, fnAction, fnCallback)
		end
		return
	elseif X.IsFunction(szKey) then
		szKey, fnAction = nil, szKey
	end
	if X.IsFunction(fnAction) then
		local function fnActionWrapper()
			fnAction(yield)
		end
		if not X.IsString(szKey) then
			szKey = GetTickCount() * 1000
			while COROUTINE_LIST[tostring(szKey)] do
				szKey = szKey + 1
			end
			szKey = tostring(szKey)
		end
		if not coroutine then
			X.Call(fnActionWrapper)
			if fnCallback then
				X.Call(fnCallback)
			end
		else
			COROUTINE_LIST[szKey] = { szID = szKey, coAction = coroutine.create(fnActionWrapper), fnCallback = fnCallback }
		end
	elseif fnAction == false then
		COROUTINE_LIST[szKey] = nil
	elseif szKey and COROUTINE_LIST[szKey] then
		return true
	end
	return szKey
end
local FPS_SLOW_TIME = 1000 / ENVIRONMENT.GAME_FPS * 1.2
local l_nLastBreatheTime = GetTime()
local function onBreathe()
	if not coroutine then
		return
	end
	local nBeginTime, pCallback = GetTime()
	if nBeginTime - l_nLastBreatheTime < FPS_SLOW_TIME then
		while GetTime() - nBeginTime < COROUTINE_TIME and next(COROUTINE_LIST) do
			for k, p in pairs(COROUTINE_LIST) do
				if GetTime() - nBeginTime > COROUTINE_TIME then
					break
				end
				if coroutine.status(p.coAction) == 'suspended' then
					local res = X.Pack(coroutine.resume(p.coAction))
					if res[1] == true then
						p.bSuccess = true
						p.aReturn = X.Pack(select(2, X.Unpack(res)))
					elseif not res[1] then
						X.ErrorLog('OnCoroutine: ' .. p.szID .. ', Error: ' .. res[2])
					end
				end
				if coroutine.status(p.coAction) == 'dead' then
					if p.fnCallback then
						X.Call(p.fnCallback, p.bSuccess or false, X.Unpack(p.aReturn or CONSTANT.EMPTY_TABLE))
					end
					COROUTINE_LIST[k] = nil
				end
			end
		end
	end
	--[[#DEBUG BEGIN]]
	if GetTime() - nBeginTime > COROUTINE_TIME then
		X.Debug(_L['PMTool'], _L('Coroutine time exceed limit: %dms.', GetTime() - nBeginTime), X.DEBUG_LEVEL.PMLOG)
	elseif nBeginTime - l_nLastBreatheTime > FPS_SLOW_TIME then
		X.Debug(_L['PMTool'], _L('System breathe too slow(%dms), coroutine suspended.', nBeginTime - l_nLastBreatheTime), X.DEBUG_LEVEL.PMLOG)
	end
	--[[#DEBUG END]]
	l_nLastBreatheTime = nBeginTime
end
X.BreatheCall(X.NSFormatString('{$NS}#COROUTINE'), onBreathe)

-- 执行协程直到它完成
-- 不传参表示执行所有协程并清空协程队列
-- 传参标志执行并清空指定ID的协程
function X.FlushCoroutine(...)
	if not coroutine then
		return
	end
	if select('#', ...) == 0 then
		local p = next(COROUTINE_LIST)
		while p do
			X.FlushCoroutine(p.szID)
			p = next(COROUTINE_LIST)
		end
	else
		local szKey = ...
		local p = szKey and COROUTINE_LIST[szKey]
		if p then
			while coroutine.status(p.coAction) == 'suspended' do
				local status, err = coroutine.resume(p.coAction)
				if not status then
					X.ErrorLog('OnCoroutine: ' .. p.szID .. ', Error: ' .. err)
				end
			end
			if p.fnCallback then
				X.Call(p.fnCallback)
			end
			COROUTINE_LIST[szKey] = nil
		end
	end
end
end
