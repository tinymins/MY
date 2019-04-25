--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动对话（for 台服）
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
local LIB, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot..'MY_Toolbox/lang/')
local D = {}
local CHAT
local CURRENT_WINDOW
local CURRENT_CONTENTS

MY_AutoChat = {}
MY_AutoChat.bEnable = false
MY_AutoChat.bEchoOn = true
MY_AutoChat.bAutoClose = true
MY_AutoChat.bEnableShift = true
MY_AutoChat.bAutoSelectSg = false
MY_AutoChat.bSkipQuestTalk = false
RegisterCustomData('MY_AutoChat.bEnable')
RegisterCustomData('MY_AutoChat.bEchoOn', 1)
RegisterCustomData('MY_AutoChat.bAutoClose', 1)
RegisterCustomData('MY_AutoChat.bEnableShift')
RegisterCustomData('MY_AutoChat.bAutoSelectSg')
RegisterCustomData('MY_AutoChat.bSkipQuestTalk')

function D.LoadData()
	local szOrgPath = LIB.GetLUADataPath('config/AUTO_CHAT/data.$lang.jx3dat')
	local szFilePath = LIB.GetLUADataPath({'config/autochat.jx3dat', PATH_TYPE.GLOBAL})
	if IsLocalFileExist(szOrgPath) then
		CPath.Move(szOrgPath, szFilePath)
	end
	CHAT = LIB.LoadLUAData(szFilePath) or LIB.LoadLUAData(LIB.GetAddonInfo().szRoot .. 'MY_ToolBox/data/interact/$lang.jx3dat')
end

function D.SaveData()
	if not CHAT then
		return
	end
	LIB.SaveLUAData({'config/autochat.jx3dat', PATH_TYPE.GLOBAL}, CHAT)
end

function D.GetName(dwType, dwID)
	if dwID == UI_GetClientPlayerID() then
		return _L['Common'], _L['Common']
	else
		local szMap  = _L['Common']
		local szName = LIB.GetObjectName(LIB.GetObject(dwType, dwID), 'never') or _L['Common']
		if dwType ~= TARGET.ITEM then
			szMap = Table_GetMapName(GetClientPlayer().GetMapID())
		end
		return szName, szMap
	end
end

function D.AddData(szMap, szName, szKey)
	if not CHAT[szMap] then
		CHAT[szMap] = { [szName] = { [szKey] = 1 } }
	elseif not CHAT[szMap][szName] then
		CHAT[szMap][szName] = { [szKey] = 1 }
	elseif not CHAT[szMap][szName][szKey] then
		CHAT[szMap][szName][szKey] = 1
	else
		CHAT[szMap][szName][szKey] = CHAT[szMap][szName][szKey] + 1
	end
	D.SaveData()
	D.DoSomething()
end

function D.DisableData(szMap, szName, szKey)
	if CHAT[szMap]
	and CHAT[szMap][szName]
	and CHAT[szMap][szName][szKey] then
		CHAT[szMap][szName][szKey] = 0
	end
	D.SaveData()
end

function D.DelData(szMap, szName, szKey)
	if not CHAT[szMap] or not CHAT[szMap][szName] or not CHAT[szMap][szName][szKey] then
		return
	else
		CHAT[szMap][szName][szKey] = nil
		if empty(CHAT[szMap][szName]) then
			CHAT[szMap][szName] = nil
			if empty(CHAT[szMap]) then
				CHAT[szMap] = nil
			end
		end
	end
	D.SaveData()
end

local function WindowSelect(dwIndex, dwID)
	LIB.Debug({'WindowSelect ' .. dwIndex .. ',' .. dwID}, 'AUTO_CHAT', DEBUG_LEVEL.LOG)
	return GetClientPlayer().WindowSelect(dwIndex, dwID)
end

-- 将服务器返回的对话Info解析为内容和交互选项
function D.InfoToDialog(aInfo, dwTargetType, dwTargetId)
	local aDialog = { szContext = '' }
	-- 分析交互选项和文字内容
	for _, v in ipairs(aInfo) do
		if v.name == '$'  -- 选项
		or v.name == 'W' then  -- 需要确认的选项
			if v.name == 'T' then
				for iconid in string.gmatch(v.context, '%$ (%d+)') do
					szImage = 'fromiconid'
					nImageFrame = iconid
				end
			end
			insert(aDialog, { dwID = v.attribute.id, szContext = v.context })
		elseif v.name == 'T' then -- 图片
			local szImage, nImageFrame
			for iconid in string.gmatch(v.context, '%$ (%d+)') do
				szImage = 'fromiconid'
				nImageFrame = iconid
			end
			insert(aDialog, { dwID = v.attribute.id, szContext = v.context, szImage = szImage, nImageFrame = nImageFrame })
		elseif v.name == 'M' then -- 商店
			insert(aDialog, { szContext = v.context })
		elseif v.name == 'Q' then -- 任务对话
			local dwQuestId = tonumber(v.attribute.questid)
			local tQuestInfo = Table_GetQuestStringInfo(dwQuestId)
			if tQuestInfo then
				local eQuestState, nLevel = GetQuestState(dwQuestId, dwTargetType, dwTargetId)
				if eQuestState == QUEST_STATE_YELLOW_QUESTION
				or eQuestState == QUEST_STATE_BLUE_QUESTION
				or eQuestState == QUEST_STATE_HIDE
				or eQuestState == QUEST_STATE_YELLOW_EXCLAMATION
				or eQuestState == QUEST_STATE_BLUE_EXCLAMATION
				or eQuestState == QUEST_STATE_WHITE_QUESTION
				or eQuestState == QUEST_STATE_DUN_DIA then
					insert(aDialog, { szContext = tQuestInfo.szName })
				end
			end
		elseif v.name == 'F' then -- 字体
			aDialog.szContext = aDialog.szContext .. v.attribute.text
		elseif v.name == 'text' then -- 文本
			aDialog.szContext = aDialog.szContext .. v.context
		elseif v.name == 'MT' then -- 交通
			insert(aDialog, { szContext = v.context })
		end
	end
	return aDialog
end

function D.EchoDialog(szName, aDialog, tOption)
	if MY_AutoChat.bEchoOn then
		LIB.Sysmsg({_L('Conversation with [%s]: %s', szName, aDialog.szContext:gsub('%s', ''))})
		if tOption.szContext and tOption.szContext ~= '' then
			LIB.Sysmsg({_L('Conversation with [%s] auto chose: %s', szName, tOption.szContext)})
		end
	end
end

function D.Choose(szType, dwTarType, dwTarID, dwIndex, aInfo)
	local szName, szMap = D.GetName(dwTarType, dwTarID)
	if not (szMap and szName and dwIndex and aInfo) then
		return
	end
	local tChat = (CHAT[szMap] or EMPTY_TABLE)[szName] or EMPTY_TABLE

	local nCount, tDefaultOption = 0
	local aDialog = D.InfoToDialog(aInfo, dwTarType, dwTarID)
	for i, tOption in ipairs(aDialog) do
		if tOption.dwID and tChat[tOption.szContext] and tChat[tOption.szContext] > 0 then
			if tOption.dwID > 0 then
				for i = 1, tChat[tOption.szContext] do
					WindowSelect(dwIndex, tOption.dwID)
				end
			end
			D.EchoDialog(szName, aDialog, tOption)
			return true
		else
			if tOption.dwID then
				tDefaultOption = tOption
			end
			nCount = nCount + 1
		end
	end

	if MY_AutoChat.bAutoSelectSg and tDefaultOption and nCount == 1 and not LIB.IsInDungeon() then
		WindowSelect(dwIndex, tDefaultOption.dwID)
		D.EchoDialog(szName, aDialog, tDefaultOption)
		return true
	end
end

function D.DoSomething()
	-- Output(CURRENT_CONTENTS, CURRENT_WINDOW)
	if not CHAT then
		D.LoadData()
	end
	if MY_AutoChat.bEnableShift and IsShiftKeyDown() then
		LIB.Sysmsg({_L['Auto interact disabled due to SHIFT key pressed.']})
		return
	end
	local frame = Station.Lookup('Normal/DialoguePanel')
	if frame and frame:IsVisible() then
		if D.Choose('Dialog', frame.dwTargetType, frame.dwTargetId, frame.dwIndex, frame.aInfo)
		and MY_AutoChat.bAutoClose then
			frame:Hide()
		end
		return
	end
	local frame = Station.Lookup('Lowest2/PlotDialoguePanel')
	if frame and frame:IsVisible() then
		if D.Choose('PlotDialog', frame.dwTargetType, frame.dwTargetId, frame.dwIndex, frame.aInfo)
		and MY_AutoChat.bAutoClose then
			frame:Hide()
			Station.Show()
		end
		return
	end
end

do
local function UnhookSkipQuestTalk()
	if frame.__SkipQuestHackEl then
		frame.__SkipQuestEl = nil
		frame.__SkipQuestHackEl:Destroy()
		frame.__SkipQuestHackEl = nil
	end
end
LIB.RegisterReload('MY_AutoChat#SkipQuestTalk', UnhookSkipQuestTalk)

local function HookSkipQuestTalk()
	local frame = Station.Lookup('Lowest2/QuestAcceptPanel')
	if not frame then
		return 0
	end
	if MY_AutoChat.bSkipQuestTalk then
		if not frame.__SkipQuestHackEl then
			local w, h = Station.GetClientSize()
			frame.__SkipQuestEl = frame:Lookup('Btn_Skip')
			frame.__SkipQuestHackEl = UI(frame):append('WndWindow', {
				name = 'Btn_Skip',
				x = 0, y = 0, w = w, h = h,
			}, true):raw()
		end
		if frame.dwShowIndex == 1 and IsTable(frame.tQuestRpg) then
			local nCount = 2
			while frame.tQuestRpg['szText' .. nCount] and frame.tQuestRpg[nCount] ~= '' do
				nCount = nCount + 1
			end
			frame.dwShowIndex = nCount - 1
		end
		frame.__SkipQuestHackEl:SetVisible(frame.__SkipQuestEl:IsVisible())
	else
		UnhookSkipQuestTalk()
	end
end

local function onInit()
	LIB.BreatheCall('MY_AutoChat#SkipQuestTalk', HookSkipQuestTalk)
end
LIB.RegisterInit('MY_AutoChat#SkipQuestTalk', onInit)

local function onFrameCreate()
	local name = arg0:GetName()
	if name == 'QuestAcceptPanel' then
		LIB.BreatheCall('MY_AutoChat#SkipQuestTalk', HookSkipQuestTalk)
	end
end
LIB.RegisterEvent('ON_FRAME_CREATE.MY_AutoChat#SkipQuestTalk', onFrameCreate)
end

---------------------------------------------------------------------------
-- 头像设置菜单
---------------------------------------------------------------------------
local function GetSettingMenu()
	return {
		szOption = _L['autochat'], {
			szOption = _L['enable'],
			bCheck = true, bChecked = MY_AutoChat.bEnable,
			fnAction = function()
				MY_AutoChat.bEnable = not MY_AutoChat.bEnable
			end
		}, {
			szOption = _L['echo when autochat'],
			bCheck = true, bChecked = MY_AutoChat.bEchoOn,
			fnAction = function()
				MY_AutoChat.bEchoOn = not MY_AutoChat.bEchoOn
			end
		}, {
			szOption = _L['auto chat when only one selection'],
			bCheck = true, bChecked = MY_AutoChat.bAutoSelectSg,
			fnAction = function()
				MY_AutoChat.bAutoSelectSg = not MY_AutoChat.bAutoSelectSg
			end
		}, {
			szOption = _L['disable when shift key pressed'],
			bCheck = true, bChecked = MY_AutoChat.bEnableShift,
			fnAction = function()
				MY_AutoChat.bEnableShift = not MY_AutoChat.bEnableShift
			end
		}, {
			szOption = _L['close after auto chat'],
			bCheck = true, bChecked = MY_AutoChat.bAutoClose,
			fnAction = function()
				MY_AutoChat.bAutoClose = not MY_AutoChat.bAutoClose
			end
		}, {
			szOption = _L['Skip quest talk'],
			bCheck = true, bChecked = MY_AutoChat.bSkipQuestTalk,
			fnAction = function()
				MY_AutoChat.bSkipQuestTalk = not MY_AutoChat.bSkipQuestTalk
			end
		},
	}
end

LIB.RegisterAddonMenu('MY_AutoChat', function()
	if LIB.IsShieldedVersion() then
		return
	end
	return GetSettingMenu()
end)

---------------------------------------------------------------------------
-- 对话面板HOOK 添加自动对话设置按钮
---------------------------------------------------------------------------
do
local function GetDialoguePanelMenuItem(szMap, szName, dialogueInfo)
	local r, g, b = 255, 255, 255
	local szIcon, nFrame, nMouseOverFrame, szLayer, fnClickIcon, fnAction
	if CHAT[szMap] and CHAT[szMap][szName] and CHAT[szMap][szName][dialogueInfo.szContext] then
		szIcon = 'ui/Image/UICommon/Feedanimials.UITex'
		nFrame = 86
		nMouseOverFrame = 87
		szLayer = 'ICON_RIGHT'
		fnClickIcon = function()
			D.DelData(szMap, szName, dialogueInfo.szContext)
			Wnd.CloseWindow('PopupMenuPanel')
		end
		if CHAT[szMap][szName][dialogueInfo.szContext] > 0 then
			r, g, b = 255, 0, 255
			fnAction = function() D.DisableData(szMap, szName, dialogueInfo.szContext) end
		else
			r, g, b = 255, 255, 255
			fnAction = function() D.AddData(szMap, szName, dialogueInfo.szContext) end
		end
	else
		fnAction = function() D.AddData(szMap, szName, dialogueInfo.szContext) end
	end
	if dialogueInfo.szImage then
		szIcon = dialogueInfo.szImage
		nFrame = dialogueInfo.nImageFrame
		szLayer = 'ICON_RIGHT'
	end
	return {
		r = r, g = g, b = b,
		szOption =  (IsCtrlKeyDown() and dialogueInfo.dwID and ('(' .. dialogueInfo.dwID .. ') ') or '') .. dialogueInfo.szContext,
		fnAction = fnAction,
		szIcon = szIcon, nFrame = nFrame, nMouseOverFrame = nMouseOverFrame,
		szLayer = szLayer, fnClickIcon = fnClickIcon,
	}
end

local function GetDialoguePanelMenu(frame)
	local dwTarType, dwTarID, dwIdx = frame.dwTargetType, frame.dwTargetId, frame.dwIndex
	local szName, szMap = D.GetName(dwTarType, dwTarID)
	if szName and szMap then
		if frame.aInfo then
			local t = { {szOption = szName .. (IsCtrlKeyDown() and (' (' .. dwIdx .. ')') or ''), bDisable = true}, { bDevide = true } }
			local tChat = {}
			-- 面板上的对话
			local aDialog = D.InfoToDialog(frame.aInfo, dwTarType, dwTarID)
			for i, info in ipairs(aDialog) do
				table.insert(t, GetDialoguePanelMenuItem(szMap, szName, info))
				tChat[info.szContext] = true
			end
			-- 保存的自动对话
			if CHAT[szMap] and CHAT[szMap][szName] then
				for szContext, nCount in pairs(CHAT[szMap][szName]) do
					if not tChat[szContext] then
						table.insert(t, GetDialoguePanelMenuItem(szMap, szName, { szContext = szContext }))
						tChat[szContext] = true
					end
				end
			end
			return t
		end
	end
end

do
local ENTRY_LIST = {
	{ root = 'Normal/DialoguePanel', x = 53, y = 4, dialog = true },
	{ root = 'Lowest2/PlotDialoguePanel', ref = 'WndScroll_Options', point = 'TOPRIGHT', x = -50, y = 10, dialog = true },
	{ root = 'Lowest2/QuestAcceptPanel', ref = 'Btn_Accept', point = 'TOPRIGHT', x = -30, y = 10, dialog = true, quest = true },
}
function D.CreateEntry()
	if LIB.IsShieldedVersion() then
		return
	end
	for _, p in ipairs(ENTRY_LIST) do
		local frame = Station.Lookup(p.root)
		if frame and (not p.el or not p.el:IsValid()) then
			local wnd = frame
			if p.path then
				wnd = frame:Lookup(p.path)
			end
			p.el = UI(wnd):append('WndButton', {
				name = 'WndButton_AutoChat',
				text = _L['autochat'],
				tip = _L['Left click to config autochat.\nRight click to edit global config.'],
				tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
				lmenu = function() return GetDialoguePanelMenu(frame) end,
				rmenu = GetSettingMenu,
			}, true):raw()
		end
	end
	D.UpdateEntryPos()
end
LIB.RegisterInit('MY_AutoChat', D.CreateEntry)

local function onFrameCreate()
	for _, p in ipairs(ENTRY_LIST) do
		if Station.Lookup(p.root) == arg0 then
			D.CreateEntry()
			return
		end
	end
end
LIB.RegisterEvent('ON_FRAME_CREATE.MY_AutoChat', onFrameCreate)

function D.UpdateEntryPos()
	if LIB.IsShieldedVersion() then
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
MY.RegisterEvent('UI_SCALED.MY_AutoChat', D.UpdateEntryPos)

function D.RemoveEntry()
	for i, p in ipairs(ENTRY_LIST) do
		if p.el and p.el:IsValid() then
			p.el:Destroy()
		end
		p.el = nil
	end
end
LIB.RegisterReload('MY_AutoChat', D.RemoveEntry)
end
end

local function onOpenWindow()
	if LIB.IsShieldedVersion() then
		return
	end
	D.CreateEntry()
	CURRENT_WINDOW = arg0
	CURRENT_CONTENTS = arg1
	if not MY_AutoChat.bEnable then
		return
	end
	D.DoSomething()
end
LIB.RegisterEvent('OPEN_WINDOW.MY_AutoChat', onOpenWindow)

local function OnShieldedVersion()
	if LIB.IsShieldedVersion() then
		D.RemoveEntry()
	else
		D.CreateEntry()
	end
end
LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_AutoChat', OnShieldedVersion)
