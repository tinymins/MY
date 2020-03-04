--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 事件处理相关函数
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
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
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
-- 特别注意：当 fnAction 为 false 并且 szKey 为 nil 时会取消所有通过本函数注册的事件处理器
local function CommonEventRegister(E, szID, fnAction)
	if IsTable(szID) then
		for _, szID in ipairs(szID) do
			CommonEventRegister(E, szID, fnAction)
		end
		return
	elseif IsFunction(szID) then
		szID, fnAction = nil, szID
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
			E.tList[szEvent] = {
				tKey = {},
				aList = {},
			}
			if E.OnCreateEvent then
				E.OnCreateEvent(szEvent)
			end
		end
		if not IsString(szKey) then
			szKey = GetTickCount() * 1000
			while E.tList[szEvent].tKey[tostring(szKey)] do
				szKey = szKey + 1
			end
			szKey = tostring(szKey)
		end
		if szEvent == 'SINGLE_EVENT' then
			szID = szKey
		else
			szID = szEvent .. '.' .. szKey
		end
		for i, p in ipairs_r(E.tList[szEvent].aList) do
			if p.szKey == szKey then
				remove(E.tList[szEvent].aList, i)
				E.tList[szEvent].tKey[szKey] = nil
			end
		end
		insert(E.tList[szEvent].aList, { szKey = szKey, szID = szID, fnAction = fnAction })
		E.tList[szEvent].tKey[szKey] = true
	elseif fnAction == false then
		if E.tList and E.tList[szEvent] then
			if szKey then
				for i, p in ipairs_r(E.tList[szEvent].aList) do
					if p.szKey == szKey then
						remove(E.tList[szEvent].aList, i)
						E.tList[szEvent].tKey[szKey] = nil
					end
				end
				if IsEmpty(E.tList[szEvent].aList) then
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
	elseif szKey and E.tList and E.tList[szEvent] then
		return E.tList[szEvent].tKey[szKey] or false
	elseif not szKey and E.tList and E.tList[szEvent] then
		return true
	end
	return szID
end

local function FireEventRec(E, p, ...)
	local nStartTick = GetTickCount()
	local res, err, trace = XpCall(p.fnAction, ...)
	if not res then
		FireUIEvent('CALL_LUA_ERROR', err .. '\nOn' .. E.szName .. ': ' .. p.szID .. '\n' .. trace .. '\n')
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug(
		_L['PMTool'],
		_L('%s function <%s> %s in %dms.', E.szName, p.szID, res and _L['succeed'] or _L['failed'], GetTickCount() - nStartTick),
		DEBUG_LEVEL.PMLOG)
	--[[#DEBUG END]]
end

local function CommonEventFirer(E, arg0, ...)
	local szEvent = E.bSingleEvent and 'SINGLE_EVENT' or arg0
	if not E.tList or not szEvent then
		return
	end
	if E.tList[szEvent] then
		for _, p in ipairs(E.tList[szEvent].aList) do
			FireEventRec(E, p, arg0, ...)
		end
	end
	if E.tList['*'] then
		for _, p in ipairs(E.tList['*'].aList) do
			FireEventRec(E, p, arg0, ...)
		end
	end
end

---------------------------------------------------------------------------------------------
-- 监听游戏事件
---------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------
-- 监听初始化完成事件
---------------------------------------------------------------------------------------------
do
local INIT_EVENT = { szName = 'Initial', bSingleEvent = true }
local function OnInit()
	if not INIT_EVENT then
		return
	end
	LIB.CreateDataRoot(PATH_TYPE.ROLE)
	LIB.CreateDataRoot(PATH_TYPE.GLOBAL)
	LIB.CreateDataRoot(PATH_TYPE.SERVER)
	LIB.LoadDataBase()
	CommonEventFirer(INIT_EVENT)
	INIT_EVENT = nil
	-- 显示欢迎信息
	local me = GetClientPlayer()
	LIB.Sysmsg(_L('%s, welcome to use %s!', me.szName, PACKET_INFO.NAME) .. ' v' .. LIB.GetVersion() .. ' Build ' .. PACKET_INFO.BUILD)
end
LIB.RegisterEvent('LOADING_ENDING', OnInit) -- 不能用FIRST_LOADING_END 不然注册快捷键就全跪了

function LIB.RegisterInit(...)
	return CommonEventRegister(INIT_EVENT, ...)
end

function LIB.IsInitialized()
	return not INIT_EVENT
end
end

---------------------------------------------------------------------------------------------
-- 监听游戏结束事件
---------------------------------------------------------------------------------------------
do
local EXIT_EVENT = { szName = 'Exit', bSingleEvent = true }
local function OnExit()
	LIB.FireFlush()
	CommonEventFirer(EXIT_EVENT)
	LIB.ReleaseDataBase()
end
LIB.RegisterEvent('GAME_EXIT', OnExit)
LIB.RegisterEvent('PLAYER_EXIT_GAME', OnExit)
LIB.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnExit)

function LIB.RegisterExit(...)
	return CommonEventRegister(EXIT_EVENT, ...)
end
end

do
local FLUSH_EVENT = { szName = 'Flush', bSingleEvent = true }
function LIB.FireFlush()
	LIB.FlushCoroutine()
	CommonEventFirer(FLUSH_EVENT)
end

function LIB.RegisterFlush(...)
	return CommonEventRegister(FLUSH_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听插件重载事件
---------------------------------------------------------------------------------------------
do
local RELOAD_EVENT = { szName = 'Reload', bSingleEvent = true }
local function OnReload()
	LIB.FlushCoroutine()
	CommonEventFirer(RELOAD_EVENT)
	LIB.ReleaseDataBase()
end
LIB.RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnReload)

function LIB.RegisterReload(...)
	return CommonEventRegister(RELOAD_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听面板打开事件
---------------------------------------------------------------------------------------------
do
local FRAME_CREATE_EVENT = { szName = 'FrameCreate' }
local function OnFrameCreate()
	CommonEventFirer(FRAME_CREATE_EVENT, arg0:GetName(), arg0)
end
LIB.RegisterEvent('ON_FRAME_CREATE', OnFrameCreate)

function LIB.RegisterFrameCreate(...)
	return CommonEventRegister(FRAME_CREATE_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听面板关闭事件
---------------------------------------------------------------------------------------------
do
local FRAME_DESTROY_EVENT = { szName = 'FrameCreate' }
local function OnFrameDestroy()
	CommonEventFirer(FRAME_DESTROY_EVENT, arg0:GetName(), arg0)
end
LIB.RegisterEvent('ON_FRAME_DESTROY', OnFrameDestroy)

function LIB.RegisterFrameDestroy(...)
	return CommonEventRegister(FRAME_DESTROY_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听游戏空闲事件
---------------------------------------------------------------------------------------------
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
LIB.RegisterEvent('BUFF_UPDATE', function()
	if arg1 then
		return
	end
	if arg0 == UI_GetClientPlayerID() and arg4 == 103 then
		DelayCall(PACKET_INFO.NAME_SPACE .. '#ON_IDLE', math.random(0, 10000), function()
			local me = GetClientPlayer()
			if me and me.GetBuff(103, 0) then
				OnIdle()
			end
		end)
	end
end)
LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#ON_IDLE', function()
	if Station.GetIdleTime() > 300000 then
		OnIdle()
	end
end)
LIB.RegisterFrameCreate('OptionPanel', OnIdle)

function LIB.RegisterIdle(...)
	return CommonEventRegister(IDLE_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 监听 CTRL ALT SHIFT 按键
---------------------------------------------------------------------------------------------
do
local SPECIAL_KEY_EVENT = { szName = 'SpecialKey' }
local ALT, SHIFT, CTRL = false, false, false
LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#ON_SPECIAL_KEY', function()
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
function LIB.RegisterSpecialKeyEvent(...)
	return CommonEventRegister(SPECIAL_KEY_EVENT, ...)
end
end

---------------------------------------------------------------------------------------------
-- 注册模块
---------------------------------------------------------------------------------------------
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
			--[[#DEBUG BEGIN]]
			LIB.Debug('MY#EVENT', "Uninit # "  .. szModule .. " # Events Removed # " .. nCount, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
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
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY#EVENT', "Init # "  .. szModule .. " # Events Added # " .. nCount, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end
end

---------------------------------------------------------------------------------------------
-- 注册新手引导
---------------------------------------------------------------------------------------------
do
local TUTORIAL_LIST = {}
function LIB.RegisterTutorial(tOptions)
	if type(tOptions) ~= 'table' or not tOptions.szKey or not tOptions.szMessage then
		return
	end
	insert(TUTORIAL_LIST, Clone(tOptions, true))
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
LIB.RegisterFlush(function() LIB.SaveLUAData({'config/tutorialed.jx3dat', PATH_TYPE.ROLE}, CHECKED) end)

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
		szName = PACKET_INFO.NAME_SPACE .. '_Tutorial',
		szMessage = tutorial.szMessage,
		szAlignment = 'CENTER',
	}
	for _, p in ipairs(tutorial) do
		local menu = Clone(p, true)
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
		szMessage = _L('Welcome to use %s, would you like to start quick tutorial now?', PACKET_INFO.NAME),
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
local BG_MSG_ID_PREFIX = PACKET_INFO.NAME_SPACE .. ':'
local BG_MSG_ID_SUFFIX = ':V2'
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
	BG_MSG_PART[szMsgUUID][nSegIndex] = LIB.SimpleDecryptString(IsString(szPart) and szPart or '')
	-- fire progress event
	local nSegRecv = 0
	for _, _ in pairs(BG_MSG_PART[szMsgUUID]) do
		nSegRecv = nSegRecv + 1
	end
	CommonEventFirer(BG_MSG_PROGRESS_EVENT, szMsgID, nSegCount, nSegRecv, nSegIndex, nChannel, dwID, szName, bSelf)
	-- concat and decode data
	if #BG_MSG_PART[szMsgUUID] == nSegCount then
		local szPlain = concat(BG_MSG_PART[szMsgUUID])
		local aData = szPlain and DecodeLUAData(szPlain)
		if aData then
			CommonEventFirer(BG_MSG_EVENT, szMsgID, aData[1], nChannel, dwID, szName, bSelf)
		--[[#DEBUG BEGIN]]
		else
			LIB.Debug('BG_EVENT#' .. szMsgID, GetTraceback('Cannot decode BgMsg: ' .. szPlain), DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		end
		BG_MSG_PART[szMsgUUID] = nil
	end
end
LIB.RegisterEvent('ON_BG_CHANNEL_MSG', OnBgMsg)
end

-- LIB.RegisterBgMsg('MY_CHECK_INSTALL', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oData) LIB.SendBgMsg(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- LIB.RegisterBgMsg('MY_CHECK_INSTALL') -- 注销
-- LIB.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01', function(szMsgID, nChannel, dwTalkerID, szTalkerName, bSelf, oData) LIB.SendBgMsg(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- LIB.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01') -- 注销
function LIB.RegisterBgMsg(szMsgID, fnAction, fnProgress)
	if fnAction == false then
		fnProgress = false
	end
	local szID = CommonEventRegister(BG_MSG_EVENT, szMsgID, fnAction)
	return CommonEventRegister(BG_MSG_PROGRESS_EVENT, szID, fnProgress)
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
	if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
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
	local v = remove(BG_MSG_QUEUE, 1)
	if not v then
		return 0
	end
	LIB.SendBgMsg(unpack(v))
end
-- LIB.SendBgMsg(szName, szMsgID, oData)
-- LIB.SendBgMsg(nChannel, szMsgID, oData)
function LIB.SendBgMsg(nChannel, szMsgID, oData)
	local szTarget, me = '', GetClientPlayer()
	if not nChannel then
		return
	end
	local szStatus = GetSenderStatus(me)
	if szStatus ~= 'READY' then
		if szStatus == 'TALK_LOCK' then
			LIB.Systopmsg(_L['BgMsg cannot be send due to talk lock, data will be sent as soon as talk unlocked.'])
		end
		insert(BG_MSG_QUEUE, { nChannel, szMsgID, oData })
		LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#BG_MSG_QUEUE', ProcessQueue)
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
	local szArg = EncodeLUAData({oData}) -- 如果发送nil，不包一层会被解析器误认为解码失败，所以必须用{}包裹
	local nMsgLen = wlen(szArg)
	local nSegLen = floor(MAX_CHANNEL_LEN[nChannel] / 4 * 3) -- Base64编码会导致长度增加
	local nSegCount = ceil(nMsgLen / nSegLen)
	-- send msg
	for nSegIndex = 1, nSegCount do
		local szSeg = LIB.SimpleEncryptString((wsub(szArg, (nSegIndex - 1) * nSegLen + 1, nSegIndex * nSegLen)))
		local aSay = {
			{ type = 'eventlink', name = 'BG_CHANNEL_MSG', linkinfo = szMsgSID },
			{ type = 'eventlink', name = '', linkinfo = EncodeLUAData({ u = szMsgUUID, c = nSegCount, i = nSegIndex }) },
			{ type = 'eventlink', name = '', linkinfo = EncodeLUAData(szSeg) },
		}
		me.Talk(nChannel, szTarget, aSay)
	end
end
end
end

---------------------------------------------------------------------------------------------
-- 注册聊天监听
---------------------------------------------------------------------------------------------
-- Register:   LIB.RegisterMsgMonitor(string szKey, function fnAction, table tChannels)
--             LIB.RegisterMsgMonitor(function fnAction, table tChannels)
-- Unregister: LIB.RegisterMsgMonitor(string szKey)
do
local MSG_MONITOR_FUNC = {}
function LIB.RegisterMsgMonitor(arg0, arg1, arg2)
	local szKey, fnAction, tChannels
	local tp0, tp1, tp2 = type(arg0), type(arg1), type(arg2)
	if tp0 == 'string' and tp1 == 'function' and tp2 == 'table' then
		szKey, fnAction, tChannels = arg0, arg1, arg2
	elseif tp0 == 'function' and tp1 == 'table' then
		fnAction, tChannels = arg0, arg1
	elseif tp0 == 'string' and not arg1 then
		szKey = arg0
	end

	if szKey and MSG_MONITOR_FUNC[szKey] then
		UnRegisterMsgMonitor(MSG_MONITOR_FUNC[szKey].fn)
		MSG_MONITOR_FUNC[szKey] = nil
	end
	if fnAction and tChannels then
		MSG_MONITOR_FUNC[szKey] = { fn = function(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
			-- filter addon comm.
			if StringFindW(szMsg, 'eventlink') and StringFindW(szMsg, _L['Addon comm.']) then
				return
			end
			fnAction(szMsg, nFont, bRich, r, g, b, szChannel, dwTalkerID, szName)
		end, ch = tChannels }
		RegisterMsgMonitor(MSG_MONITOR_FUNC[szKey].fn, MSG_MONITOR_FUNC[szKey].ch)
	end
end
end

---------------------------------------------------------------------------------------------
-- 注册协程
---------------------------------------------------------------------------------------------
do
local COROUTINE_TIME = 1000 * 0.5 / GLOBAL.GAME_FPS -- 一次 Breathe 时最大允许执行协程时间
local COROUTINE_LIST = {}
function LIB.RegisterCoroutine(szKey, fnAction, fnCallback)
	if IsTable(szKey) then
		for _, szKey in ipairs(szKey) do
			LIB.RegisterCoroutine(szKey, fnAction, fnCallback)
		end
		return
	elseif IsFunction(szKey) then
		szKey, fnAction = nil, szKey
	end
	if IsFunction(fnAction) then
		if not IsString(szKey) then
			szKey = GetTickCount() * 1000
			while COROUTINE_LIST[tostring(szKey)] do
				szKey = szKey + 1
			end
			szKey = tostring(szKey)
		end
		if not coroutine then
			Call(fnAction)
			if fnCallback then
				Call(fnCallback)
			end
		else
			COROUTINE_LIST[szKey] = { szID = szKey, coAction = coroutine.create(fnAction), fnCallback = fnCallback }
		end
	elseif fnAction == false then
		COROUTINE_LIST[szKey] = nil
	elseif szKey and COROUTINE_LIST[szKey] then
		return true
	end
	return szKey
end
local FPS_SLOW_TIME = 1000 / GLOBAL.GAME_FPS * 1.2
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
					local status, err = coroutine.resume(p.coAction)
					if not status then
						FireUIEvent('CALL_LUA_ERROR',  'OnCoroutine: ' .. p.szID .. ', Error: ' .. err .. '\n')
					end
				end
				if coroutine.status(p.coAction) == 'dead' then
					if p.fnCallback then
						Call(p.fnCallback)
					end
					COROUTINE_LIST[k] = nil
				end
			end
		end
	end
	--[[#DEBUG BEGIN]]
	if GetTime() - nBeginTime > COROUTINE_TIME then
		LIB.Debug(_L['PMTool'], _L('Coroutine time exceed limit: %dms.', GetTime() - nBeginTime), DEBUG_LEVEL.PMLOG)
	elseif nBeginTime - l_nLastBreatheTime > FPS_SLOW_TIME then
		LIB.Debug(_L['PMTool'], _L('System breathe too slow(%dms), coroutine suspended.', nBeginTime - l_nLastBreatheTime), DEBUG_LEVEL.PMLOG)
	end
	--[[#DEBUG END]]
	l_nLastBreatheTime = nBeginTime
end
LIB.BreatheCall(PACKET_INFO.NAME_SPACE .. '#COROUTINE', onBreathe)

-- 执行协程直到它完成
-- 不传参表示执行所有协程并清空协程队列
-- 传参标志执行并清空指定ID的协程
function LIB.FlushCoroutine(...)
	if not coroutine then
		return
	end
	if select('#', ...) == 0 then
		local p = next(COROUTINE_LIST)
		while p do
			LIB.FlushCoroutine(p.szID)
			p = next(COROUTINE_LIST)
		end
	else
		local szKey = ...
		local p = szKey and COROUTINE_LIST[szKey]
		if p then
			while coroutine.status(p.coAction) == 'suspended' do
				local status, err = coroutine.resume(p.coAction)
				if not status then
					FireUIEvent('CALL_LUA_ERROR',  'OnCoroutine: ' .. p.szID .. ', Error: ' .. err .. '\n')
				end
			end
			if p.fnCallback then
				Call(p.fnCallback)
			end
			COROUTINE_LIST[szKey] = nil
		end
	end
end
end
