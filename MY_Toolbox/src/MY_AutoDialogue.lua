--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动对话（for 台服）
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
	return
end
--------------------------------------------------------------------------
local DIALOGUE
local CURRENT_WINDOW
local CURRENT_CONTENTS

local O = LIB.CreateUserSettingsModule('MY_AutoDialogue', _L['General'], {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bEchoOn = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoClose = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bEnableShift = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoSelectSg = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoSelectSp = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bSkipQuestTalk = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

---------------------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------------------
function D.LoadData()
	DIALOGUE = LIB.LoadLUAData({'config/auto_dialogue.jx3dat', PATH_TYPE.GLOBAL})
		or LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_Toolbox/data/auto_dialogue/{$lang}.jx3dat')
		or {}
end

function D.SaveData()
	if not DIALOGUE then
		return
	end
	LIB.SaveLUAData({'config/auto_dialogue.jx3dat', PATH_TYPE.GLOBAL}, DIALOGUE)
end

function D.EnableDialogueData(szMap, szName, szContext, szKey)
	Set(DIALOGUE, {szMap, szName, szContext, szKey}, 1)
	D.SaveData()
	D.AutoDialogue()
end

function D.DisableDialogueData(szMap, szName, szContext, szKey)
	if Get(DIALOGUE, {szMap, szName, szContext, szKey}) then
		Set(DIALOGUE, {szMap, szName, szContext, szKey}, 0)
	end
	D.SaveData()
end

function D.RemoveDialogueData(szMap, szName, szContext, szKey)
	if Get(DIALOGUE, {szMap, szName, szContext, szKey}) then
		Set(DIALOGUE, {szMap, szName, szContext, szKey}, nil)
	end
	if IsEmpty(Get(DIALOGUE, {szMap, szName, szContext})) then
		Set(DIALOGUE, {szMap, szName, szContext}, nil)
	end
	if IsEmpty(Get(DIALOGUE, {szMap, szName})) then
		Set(DIALOGUE, {szMap, szName}, nil)
	end
	if IsEmpty(Get(DIALOGUE, {szMap})) then
		Set(DIALOGUE, {szMap}, nil)
	end
	D.SaveData()
end

---------------------------------------------------------------------------
-- 自动对话核心逻辑
---------------------------------------------------------------------------
do
-- 将服务器返回的对话Info解析为内容和交互选项
function D.DecodeDialogInfo(aInfo, dwTarType, dwTarID)
	local szName, szMap = _L['Common'], _L['Common']
	if dwTarID ~= UI_GetClientPlayerID() then
		szName = LIB.GetObjectName(LIB.GetObject(dwTarType, dwTarID), 'never') or _L['Common']
		if dwTarType ~= TARGET.ITEM then
			szMap = Table_GetMapName(GetClientPlayer().GetMapID())
		end
	end
	local dialog = { szMap = szMap, szName = szName, szContext = '', aOptions = {} }
	-- 分析交互选项和文字内容
	for _, v in ipairs(aInfo) do
		if v.name == '$'  -- 选项
		or v.name == 'W' then  -- 需要确认的选项
			local szImage, nImageFrame
			if v.name == 'T' then
				for iconid in gmatch(v.context, '%$ (%d+)') do
					szImage = 'fromiconid'
					nImageFrame = iconid
				end
			end
			insert(dialog.aOptions, { dwID = tonumber(v.attribute.id) or 0, szContext = v.context })
		elseif v.name == 'T' then -- 图片
			local szImage, nImageFrame
			for iconid in gmatch(v.context, '%$ (%d+)') do
				szImage = 'fromiconid'
				nImageFrame = iconid
			end
			insert(dialog.aOptions, { dwID = tonumber(v.attribute.id) or 0, szContext = v.context, szImage = szImage, nImageFrame = nImageFrame })
		elseif v.name == 'M' then -- 商店
			insert(dialog.aOptions, { szContext = v.context })
		elseif v.name == 'Q' then -- 任务对话
			local dwQuestId = tonumber(v.attribute.questid)
			local tQuestInfo = Table_GetQuestStringInfo(dwQuestId)
			if tQuestInfo then
				local eQuestState, nLevel = GetQuestState(dwQuestId, dwTarType, dwTarID)
				if eQuestState == QUEST_STATE_YELLOW_QUESTION
				or eQuestState == QUEST_STATE_BLUE_QUESTION
				or eQuestState == QUEST_STATE_HIDE
				or eQuestState == QUEST_STATE_YELLOW_EXCLAMATION
				or eQuestState == QUEST_STATE_BLUE_EXCLAMATION
				or eQuestState == QUEST_STATE_WHITE_QUESTION
				or eQuestState == QUEST_STATE_DUN_DIA then
					insert(dialog.aOptions, { szContext = tQuestInfo.szName })
				end
			end
		elseif v.name == 'F' then -- 字体
			dialog.szContext = dialog.szContext .. v.attribute.text
		elseif v.name == 'text' then -- 文本
			dialog.szContext = dialog.szContext .. v.context
		elseif v.name == 'MT' then -- 交通
			insert(dialog.aOptions, { szContext = v.context })
		elseif v.name == 'U' then -- 跨地图交通
			insert(dialog.aOptions, { szContext = v.context })
		end
	end
	return dialog
end

function D.ProcessDialogInfo(frame, aInfo, dwTarType, dwTarID, dwIndex)
	local dialog = D.DecodeDialogInfo(aInfo, dwTarType, dwTarID)
	if not (dialog.szMap and dialog.szName and dwIndex and aInfo) then
		return
	end
	local option, nRepeat
	local tChat = Get(DIALOGUE, {dialog.szMap, dialog.szName, dialog.szContext})
	if tChat then
		for i, p in ipairs(dialog.aOptions) do
			if p.dwID and tChat[p.szContext] and tChat[p.szContext] > 0 then
				option = p
				nRepeat = tChat[p.szContext]
				break
			end
		end
	end
	if not LIB.IsInDungeon() then
		if not option and O.bAutoSelectSp and #dialog.aOptions == 1 and dialog.aOptions[1].szContext == '' then
			option = dialog.aOptions[1]
			nRepeat = 1
		end
		if not option and O.bAutoSelectSg and #dialog.aOptions == 1 then
			option = dialog.aOptions[1]
			nRepeat = 1
		end
	end
	if option and option.dwID then
		if O.bAutoClose then
			frame:Hide()
			Station.Show()
			rlcmd('dialogue with npc 0')
		end
		for i = 1, nRepeat do
			GetClientPlayer().WindowSelect(dwIndex, option.dwID)
		end
		if O.bEchoOn then
			LIB.Sysmsg(_L('Conversation with [%s]: %s', dialog.szName, dialog.szContext:gsub('%s', '')))
			if option.szContext and option.szContext ~= '' then
				LIB.Sysmsg(_L('Conversation with [%s] auto chose: %s', dialog.szName, option.szContext))
			end
		end
		--[[#DEBUG BEGIN]]
		LIB.Debug('AUTO_CHAT', 'WindowSelect ' .. dwIndex .. ',' .. option.dwID .. 'x' .. nRepeat, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		return true
	end
end

function D.AutoDialogue()
	-- Output(CURRENT_CONTENTS, CURRENT_WINDOW)
	if not DIALOGUE then
		D.LoadData()
	end
	if O.bEnableShift and IsShiftKeyDown() then
		LIB.Sysmsg(_L['Auto interact disabled due to SHIFT key pressed.'])
		return
	end
	local frame = Station.Lookup('Normal/DialoguePanel')
	if frame and frame:IsVisible() then
		return D.ProcessDialogInfo(frame, frame.aInfo, frame.dwTargetType, frame.dwTargetId, frame.dwIndex)
	end
	local frame = Station.Lookup('Lowest2/PlotDialoguePanel')
	if frame and frame:IsVisible() then
		return D.ProcessDialogInfo(frame, frame.aInfo, frame.dwTargetType, frame.dwTargetId, frame.dwIndex)
	end
end

local function onOpenWindow()
	CURRENT_WINDOW = arg0
	CURRENT_CONTENTS = arg1
	if not O.bEnable or LIB.IsShieldedVersion('MY_AutoDialogue') then
		return
	end
	LIB.DelayCall('MY_AutoDialogue__AutoDialogue', D.AutoDialogue)
end
LIB.RegisterEvent('OPEN_WINDOW', 'MY_AutoDialogue', onOpenWindow)
end

---------------------------------------------------------------------------
-- 精简任务对话核心逻辑
---------------------------------------------------------------------------
do
local function UnhookSkipQuestTalk()
	local frame = Station.Lookup('Lowest2/QuestAcceptPanel')
	if not frame or not frame.__SkipQuestHackEl then
		return 0
	end
	frame.__SkipQuestEl = nil
	frame.__SkipQuestHackEl:Destroy()
	frame.__SkipQuestHackEl = nil
end
LIB.RegisterReload('MY_AutoDialogue#SkipQuestTalk', UnhookSkipQuestTalk)

local function HookSkipQuestTalk()
	local frame = Station.Lookup('Lowest2/QuestAcceptPanel')
	if not frame then
		return 0
	end
	if O.bSkipQuestTalk then
		if not frame.__SkipQuestHackEl then
			local w, h = Station.GetClientSize()
			frame.__SkipQuestEl = frame:Lookup('Btn_Skip')
			frame.__SkipQuestHackEl = UI(frame):Append('WndWindow', {
				name = 'Btn_Skip',
				x = 0, y = 0, w = w, h = h,
			}):Raw()
		end
		if frame.dwShowIndex == 1 and IsTable(frame.tQuestRpg) then
			local nCount = 2
			while frame.tQuestRpg['szText' .. nCount] and frame.tQuestRpg[nCount] ~= '' do
				nCount = nCount + 1
			end
			frame.dwShowIndex = nCount - 1
		end
		frame.__SkipQuestHackEl:SetVisible(frame.__SkipQuestEl:IsVisible() and frame.tQuestRpg and frame.tQuestRpg.szText2 and frame.tQuestRpg.szText2 ~= '')
	else
		UnhookSkipQuestTalk()
	end
end

local function onInit()
	LIB.BreatheCall('MY_AutoDialogue#SkipQuestTalk', HookSkipQuestTalk)
end
LIB.RegisterInit('MY_AutoDialogue#SkipQuestTalk', onInit)

local function onFrameCreate()
	LIB.BreatheCall('MY_AutoDialogue#SkipQuestTalk', HookSkipQuestTalk)
end
LIB.RegisterFrameCreate('QuestAcceptPanel', 'MY_AutoDialogue#SkipQuestTalk', onFrameCreate)
end

---------------------------------------------------------------------------
-- 设置按钮入口
---------------------------------------------------------------------------
function D.GetDialogueMenu(aInfo, dwTargetType, dwTargetID, dwIndex)
	if not aInfo then
		return
	end
	local dialog = D.DecodeDialogInfo(aInfo, dwTargetType, dwTargetID)
	if not dialog.szName or not dialog.szMap then
		return
	end
	-- 显示标题
	local szCaption = dialog.szName
	if dialog.szContext ~= '' then
		szCaption = szCaption .. '(' .. wsub(dialog.szContext:gsub('%s', ''), 1, 8)
		if wlen(dialog.szContext) > 8 then
			szCaption = szCaption .. '...'
		end
		szCaption = szCaption .. ')'
	end
	if IsCtrlKeyDown() then
		szCaption = '(' .. dwIndex .. ') ' .. szCaption
	end
	-- 计算选项列表
	local tOption, aOption = {}, {}
	for i, option in ipairs(dialog.aOptions) do -- 面板上的对话
		if option.dwID then
			insert(aOption, option)
			tOption[option.szContext] = true
		end
	end
	local aList = Get(DIALOGUE, {dialog.szMap, dialog.szName, dialog.szContext}) -- 保存的自动对话
	if aList then
		for szContext, nCount in pairs(aList) do
			if not tOption[szContext] then
				insert(aOption, { szContext = szContext })
				tOption[szContext] = true
			end
		end
	end
	-- 数据转菜单项
	local menu = {{ szOption = szCaption, bDisable = true }, { bDevide = true }}
	for _, option in ipairs(aOption) do
		local szCaption = option.szContext
		if IsCtrlKeyDown() and option.dwID then
			szCaption = '(' .. option.dwID .. ') ' .. szCaption
		end
		local menuSub = { szOption = szCaption, r = 255, g = 255, b = 255 }
		local nRepeat = Get(DIALOGUE, {dialog.szMap, dialog.szName, dialog.szContext, option.szContext})
		if nRepeat then
			menuSub.szIcon = 'ui/Image/UICommon/Feedanimials.UITex'
			menuSub.nFrame = 86
			menuSub.nMouseOverFrame = 87
			menuSub.szLayer = 'ICON_RIGHT'
			menuSub.fnClickIcon = function()
				D.RemoveDialogueData(dialog.szMap, dialog.szName, dialog.szContext, option.szContext)
				UI.ClosePopupMenu()
			end
		end
		if nRepeat and nRepeat > 0 then
			menuSub.r, menuSub.g, menuSub.b = 255, 0, 255
			menuSub.fnAction = function()
				D.DisableDialogueData(dialog.szMap, dialog.szName, dialog.szContext, option.szContext)
				UI.ClosePopupMenu()
			end
		else
			menuSub.r, menuSub.g, menuSub.b = 255, 255, 255
			menuSub.fnAction = function()
				D.EnableDialogueData(dialog.szMap, dialog.szName, dialog.szContext, option.szContext)
				UI.ClosePopupMenu()
			end
		end
		if option.szImage then
			menuSub.szIcon = option.szImage
			menuSub.nFrame = option.nImageFrame
			menuSub.szLayer = 'ICON_RIGHT'
		end
		insert(menu, menuSub)
	end
	return menu
end

do
local ENTRY_LIST = {
	{
		name = 'DialoguePanel', root = 'Normal/DialoguePanel', x = 53, y = 4,
		keys = { info = 'aInfo', tartype = 'dwTargetType', tarid = 'dwTargetId', winidx = 'dwIndex'},
	},
	{
		name = 'PlotDialoguePanel', root = 'Lowest2/PlotDialoguePanel',
		ref = 'WndScroll_Options', point = 'TOPRIGHT', x = -50, y = 10, plot = true,
		keys = { info = 'aInfo', tartype = 'dwTargetType', tarid = 'dwTargetId', winidx = 'dwIndex'},
	},
	{
		name = 'QuestAcceptPanel', root = 'Lowest2/QuestAcceptPanel',
		ref = 'Btn_Accept', point = 'TOPRIGHT', x = -30, y = 10, plot = true,
		keys = { info = 'aInfo', tartype = 'dwTargetType', tarid = 'dwTargetID', winidx = 'dwIndex'},
	},
}
function D.CreateEntry()
	if LIB.IsShieldedVersion('MY_AutoDialogue') then
		return
	end
	for _, p in ipairs(ENTRY_LIST) do
		local frame = Station.Lookup(p.root)
		if frame and (not p.el or not p.el:IsValid()) then
			local wnd = frame
			if p.path then
				wnd = frame:Lookup(p.path)
			end
			p.el = UI(wnd):Append('WndButton', {
				name = 'WndButton_AutoChat',
				text = _L['Autochat'],
				tip = _L['Left click to config autochat.\nRight click to edit global config.'],
				tippostype = UI.TIP_POSITION.TOP_BOTTOM,
				lmenu = function()
					return D.GetDialogueMenu(frame[p.keys.info], frame[p.keys.tartype], frame[p.keys.tarid], frame[p.keys.winidx])
				end,
				rmenu = D.GetConfigMenu,
			}):Raw()
		end
	end
	D.UpdateEntryPos()
end
for _, p in ipairs(ENTRY_LIST) do
	LIB.RegisterFrameCreate(p.name, 'MY_AutoDialogue#ENTRY', D.CreateEntry)
end
LIB.RegisterInit('MY_AutoDialogue', D.CreateEntry)

function D.UpdateEntryPos()
	if LIB.IsShieldedVersion('MY_AutoDialogue') then
		return
	end
	for _, p in ipairs(ENTRY_LIST) do
		local frame = Station.Lookup(p.root)
		if frame and p.el and p.el:IsValid() then
			local wnd = frame
			if p.path then
				wnd = frame:Lookup(p.path)
			end
			local ref = frame
			if p.ref then
				ref = frame:Lookup(p.ref)
			end
			local x = p.x + (ref:GetAbsX() - frame:GetAbsX())
			local y = p.y + (ref:GetAbsY() - frame:GetAbsY())
			local point = p.point or 'TOPLEFT'
			if point:find('RIGHT') then
				x = x + ref:GetW()
			end
			if point:find('BOTTOM') then
				y = y + ref:GetH()
			end
			p.el:SetRelPos(x, y)
		end
	end
end
LIB.RegisterEvent('UI_SCALED', 'MY_AutoDialogue#ENTRY', D.UpdateEntryPos)

function D.RemoveEntry()
	for i, p in ipairs(ENTRY_LIST) do
		if p.el and p.el:IsValid() then
			p.el:Destroy()
		end
		p.el = nil
	end
end
LIB.RegisterReload('MY_AutoDialogue#ENTRY', D.RemoveEntry)

local function onOpenWindow()
	if LIB.IsShieldedVersion('MY_AutoDialogue') then
		return
	end
	D.CreateEntry()
end
LIB.RegisterEvent('OPEN_WINDOW', 'MY_AutoDialogue#ENTRY', onOpenWindow)

LIB.RegisterEvent('MY_SHIELDED_VERSION', 'MY_AutoDialogue#ENTRY', function()
	if arg0 and arg0 ~= 'MY_AutoDialogue' then
		return
	end
	if LIB.IsShieldedVersion('MY_AutoDialogue') then
		D.RemoveEntry()
	else
		D.CreateEntry()
	end
end)
end

---------------------------------------------------------------------------
-- 头像设置菜单
---------------------------------------------------------------------------
function D.GetConfigMenu()
	return {
		szOption = _L['Autochat'], {
			szOption = _L['Enable'],
			bCheck = true, bChecked = O.bEnable,
			fnAction = function()
				O.bEnable = not O.bEnable
			end
		}, {
			szOption = _L['Echo when autochat'],
			bCheck = true, bChecked = O.bEchoOn,
			fnAction = function()
				O.bEchoOn = not O.bEchoOn
			end
		}, {
			szOption = _L['Auto chat when only one selection'],
			bCheck = true, bChecked = O.bAutoSelectSg,
			fnAction = function()
				O.bAutoSelectSg = not O.bAutoSelectSg
			end
		}, {
			szOption = _L['Auto chat when only one space selection'],
			bCheck = true, bChecked = O.bAutoSelectSp,
			fnAction = function()
				O.bAutoSelectSp = not O.bAutoSelectSp
			end
		}, {
			szOption = _L['Disable when shift key pressed'],
			bCheck = true, bChecked = O.bEnableShift,
			fnAction = function()
				O.bEnableShift = not O.bEnableShift
			end
		}, {
			szOption = _L['Close after auto chat'],
			bCheck = true, bChecked = O.bAutoClose,
			fnAction = function()
				O.bAutoClose = not O.bAutoClose
			end
		}, {
			szOption = _L['Skip quest talk'],
			bCheck = true, bChecked = O.bSkipQuestTalk,
			fnAction = function()
				O.bSkipQuestTalk = not O.bSkipQuestTalk
			end
		},
	}
end

LIB.RegisterAddonMenu('MY_AutoDialogue', function()
	if LIB.IsShieldedVersion('MY_AutoDialogue') then
		return
	end
	return D.GetConfigMenu()
end)
