--------------------------------------------
-- @Desc  : 自动对话（for 台服）
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-03-09 21:26:52
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-13 14:46:58
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Toolbox/lang/")
local _C = { Data = {} }
MY_AutoChat = {}
MY_AutoChat.bEnable = false
MY_AutoChat.bEchoOn = true
MY_AutoChat.bAutoClose = true
MY_AutoChat.bEnableShift = true
MY_AutoChat.bAutoSelect1 = false
MY_AutoChat.Conents = nil
MY_AutoChat.CurrentWindow = 0
RegisterCustomData("MY_AutoChat.bEnable")
RegisterCustomData("MY_AutoChat.bEchoOn", 1)
RegisterCustomData("MY_AutoChat.bAutoClose", 1)
RegisterCustomData("MY_AutoChat.bEnableShift")
RegisterCustomData("MY_AutoChat.bAutoSelect1")

function MY_AutoChat.LoadData()
	local szOrgPath = MY.GetLUADataPath("config/AUTO_CHAT/data.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/autochat.jx3dat", MY_DATA_PATH.GLOBAL})
	if IsLocalFileExist(szOrgPath) then
		CPath.Move(szOrgPath, szFilePath)
	end
	_C.Data = MY.LoadLUAData(szFilePath) or MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "MY_ToolBox/data/interact/$lang.jx3dat") or _C.Data
end
function MY_AutoChat.SaveData() MY.SaveLUAData({"config/autochat.jx3dat", MY_DATA_PATH.GLOBAL}, _C.Data) end
function MY_AutoChat.GetName(dwType, dwID)
	if dwID == UI_GetClientPlayerID() then
		return _L['Common'], _L['Common']
	else
		local szMap  = _L['Common']
		local szName = MY.GetObjectName(MY.GetObject(dwType, dwID)) or _L['Common']
		if dwType ~= TARGET.ITEM then
			szMap = Table_GetMapName(GetClientPlayer().GetMapID())
		end
		return szName, szMap
	end
end

function MY_AutoChat.AddData(szMap, szName, szKey)
	if not _C.Data[szMap] then
		_C.Data[szMap] = { [szName] = { [szKey] = 1 } }
	elseif not _C.Data[szMap][szName] then
		_C.Data[szMap][szName] = { [szKey] = 1 }
	elseif not _C.Data[szMap][szName][szKey] then
		_C.Data[szMap][szName][szKey] = 1
	else
		_C.Data[szMap][szName][szKey] = _C.Data[szMap][szName][szKey] + 1
	end
	MY_AutoChat.SaveData()
	MY_AutoChat.DoSomething()
end

function MY_AutoChat.DisableData(szMap, szName, szKey)
	if _C.Data[szMap]
	and _C.Data[szMap][szName]
	and _C.Data[szMap][szName][szKey] then
		_C.Data[szMap][szName][szKey] = 0
	end
	MY_AutoChat.SaveData()
end

function MY_AutoChat.DelData(szMap, szName, szKey)
	if not _C.Data[szMap] or not _C.Data[szMap][szName] or not _C.Data[szMap][szName][szKey] then
		return
	else
		_C.Data[szMap][szName][szKey] = nil
		if empty(_C.Data[szMap][szName]) then
			_C.Data[szMap][szName] = nil
			if empty(_C.Data[szMap]) then
				_C.Data[szMap] = nil
			end
		end
	end
	MY_AutoChat.SaveData()
end

local function WindowSelect(dwIndex, dwID)
	MY.Debug({"WindowSelect " .. dwIndex .. "," .. dwID}, "AUTO_CHAT", MY_DEBUG.LOG)
	return GetClientPlayer().WindowSelect(dwIndex, dwID)
end

local function GetDialogueInfo(v, dwTargetType, dwTargetId)
	local id, context, image, imageframe
	if v.name == "$" or v.name == "W" or v.name == "T" then
		if v.name == "T" then
			for iconid in string.gmatch(v.context, "%$ (%d+)") do
				image = "fromiconid"
				imageframe = iconid
			end
		end
		id = v.attribute.id
		context = v.context
	elseif v.name == "M" then -- 商店
		context = v.context
	elseif v.name == "Q" then -- 任务对话
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
				context = tQuestInfo.szName
			end
		end
	end
	return context and { id = id, context = context } or nil
end

function MY_AutoChat.Choose(dwType, dwID, dwIndex, aInfo)
	local szName, szMap = MY_AutoChat.GetName(dwType, dwID)
	if not (szMap and szName and dwIndex and aInfo) then
		return
	end
	local tChat = (_C.Data[szMap] or EMPTY_TABLE)[szName] or EMPTY_TABLE

	local nCount, szContext, dwID = 0
	for i, v in ipairs(aInfo) do
		local info = GetDialogueInfo(v, dwType, dwID)
		if info then
			if info.id and tChat[info.context] and tChat[info.context] > 0 then
				for i = 1, tChat[info.context] do
					WindowSelect(dwIndex, info.id)
				end
				if MY_AutoChat.bEchoOn then
					MY.Sysmsg({_L("Conversation with [%s] auto chose: %s", szName, info.context)})
				end
				return true
			else
				if info.id then
					dwID = info.id
					szContext = v.context
				end
				nCount = nCount + 1
			end
		end
	end

	if MY_AutoChat.bAutoSelect1 and nCount == 1 and not MY.IsInDungeon(true) then
		WindowSelect(dwIndex, dwID)
		if MY_AutoChat.bEchoOn then
			MY.Sysmsg({_L("Conversation with [%s] auto chose: %s", szName, szContext)})
		end
		return true
	end
end

function MY_AutoChat.DoSomething()
	-- Output(MY_AutoChat.Conents, MY_AutoChat.CurrentWindow)
	if MY_AutoChat.bEnableShift and IsShiftKeyDown() then
		MY.Sysmsg({_L["Auto interact disabled due to SHIFT key pressed."]})
		return
	end
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame:IsVisible() then
		if MY_AutoChat.Choose(frame.dwTargetType, frame.dwTargetId, frame.dwIndex, frame.aInfo)
		and MY_AutoChat.bAutoClose then
			frame:Hide()
		end
	end
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
			bCheck = true, bChecked = MY_AutoChat.bAutoSelect1,
			fnAction = function()
				MY_AutoChat.bAutoSelect1 = not MY_AutoChat.bAutoSelect1
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
		},
	}
end

MY.RegisterPlayerAddonMenu('MY_AutoChat', function()
	if MY.IsShieldedVersion() then
		return
	end
	return GetSettingMenu()
end)

---------------------------------------------------------------------------
-- 对话面板HOOK 添加自动对话设置按钮
---------------------------------------------------------------------------
local function GetDialoguePanelMenuItem(szMap, szName, dialogueInfo)
	local r, g, b = 255, 255, 255
	local szIcon, nFrame, nMouseOverFrame, szLayer, fnClickIcon, fnAction
	if _C.Data[szMap] and _C.Data[szMap][szName] and _C.Data[szMap][szName][dialogueInfo.context] then
		szIcon = 'ui/Image/UICommon/Feedanimials.UITex'
		nFrame = 86
		nMouseOverFrame = 87
		szLayer = "ICON_RIGHT"
		fnClickIcon = function()
			MY_AutoChat.DelData(szMap, szName, dialogueInfo.context)
			Wnd.CloseWindow('PopupMenuPanel')
		end
		if _C.Data[szMap][szName][dialogueInfo.context] > 0 then
			r, g, b = 255, 0, 255
			fnAction = function() MY_AutoChat.DisableData(szMap, szName, dialogueInfo.context) end
		else
			r, g, b = 255, 255, 255
			fnAction = function() MY_AutoChat.AddData(szMap, szName, dialogueInfo.context) end
		end
	else
		fnAction = function() MY_AutoChat.AddData(szMap, szName, dialogueInfo.context) end
	end
	if dialogueInfo.name == "T" then
		for szIconID in string.gmatch(dialogueInfo.context, "%$ (%d+)") do
			szIcon = "fromiconid"
			nFrame = szIconID
			szLayer = "ICON_RIGHT"
		end
	end
	return {
		r = r, g = g, b = b,
		szOption =  (IsCtrlKeyDown() and dialogueInfo.id and ("(" .. dialogueInfo.id .. ") ") or "") .. dialogueInfo.context,
		fnAction = fnAction,
		szIcon = szIcon, nFrame = nFrame, nMouseOverFrame = nMouseOverFrame,
		szLayer = szLayer, fnClickIcon = fnClickIcon,
	}
end

local function GetDialoguePanelMenu()
	local frame = Station.Lookup("Normal/DialoguePanel")
	if not frame then
		return
	end
	local dwType, dwID, dwIdx = frame.dwTargetType, frame.dwTargetId, frame.dwIndex
	local szName, szMap = MY_AutoChat.GetName(dwType, dwID)
	if szName and szMap then
		if frame.aInfo then
			local t = { {szOption = szName .. (IsCtrlKeyDown() and (" (" .. dwIdx .. ")") or ""), bDisable = true}, { bDevide = true } }
			local tChat = {}
			-- 面板上的对话
			for i, v in ipairs(frame.aInfo) do
				local info = GetDialogueInfo(v, dwType, dwID)
				if info and info.id then
					table.insert(t, GetDialoguePanelMenuItem(szMap, szName, info))
					tChat[info.context] = true
				end
			end
			-- 保存的自动对话
			if _C.Data[szMap] and _C.Data[szMap][szName] then
				for szContext, nCount in pairs(_C.Data[szMap][szName]) do
					if not tChat[szContext] then
						table.insert(t, GetDialoguePanelMenuItem(szMap, szName, { name = "$", context = szContext }))
						tChat[szContext] = true
					end
				end
			end
			return t
		end
	end
end

local function HookDialoguePanel()
	if MY.IsShieldedVersion() then
		return
	end
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame:IsVisible() and not frame.bMYHooked then
		MY.UI(frame):append('WndButton', {
			name = 'WndButton_AutoChat',
			x = 50, y = 10, w = 80, text = _L['autochat'],
			tip = _L['Left click to config autochat.\nRight click to edit global config.'],
			tippostype = MY.Const.UI.Tip.POS_TOP,
			lmenu = GetDialoguePanelMenu,
			rmenu = GetSettingMenu,
		})
		frame.bMYHooked = true
	end
end
MY.RegisterInit("MY_AutoChat", HookDialoguePanel)

local function onOpenWindow()
	if MY.IsShieldedVersion() then
		return
	end
	if empty(_C.Data) then
		MY_AutoChat.LoadData()
	end
	HookDialoguePanel()
	if not MY_AutoChat.bEnable then
		return
	end
	MY_AutoChat.CurrentWindow = arg0
	MY_AutoChat.Conents = arg1
	MY_AutoChat.DoSomething()
end
MY.RegisterEvent("OPEN_WINDOW.MY_AutoChat", onOpenWindow)

local function UnhookDialoguePanel()
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame.bMYHooked then
		MY.UI(frame):children('#WndButton_AutoChat'):remove()
		frame.bMYHooked = false
	end
end
MY.RegisterReload("MY_AutoChat", UnhookDialoguePanel)
