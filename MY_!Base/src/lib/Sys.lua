--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Sys')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local bExiting = false
X.RegisterEvent('PLAYER_EXIT_GAME', function()
	bExiting = true
end)
---游戏是否处于退出状态
---@return boolean 是否正在退出
function X.IsGameExiting()
	return bExiting
end
end

-- #######################################################################################################
--       #       #               #         #           #           #
--       #       #               #     # # # # # #     # #       # # # #
--       #   # # # # # #         #         #         #     # #     #   #
--   #   # #     #     #     # # # #   # # # # #             # # # # # # #
--   #   #       #     #         #         #   #     # # #   #     #   #
--   #   #       #     #         #     # # # # # #     #   #     # # # #
--   #   # # # # # # # # #       # #       #   #       #   # #     #
--       #       #           # # #     # # # # #     # # #   # # # # # #
--       #     #   #             #         #           #     #     #
--       #     #   #             #     #   # # # #     #   # # # # # # # #
--       #   #       #           #     #   #           # #   #     #
--       # #           # #     # #   #   # # # # #     #   #   # # # # # #
-- #######################################################################################################
do local HOTKEY_CACHE = {}
-- 增加系统快捷键
-- (void) X.RegisterHotKey(string szName, string szTitle, func fnDown, func fnUp)   -- 增加系统快捷键
function X.RegisterHotKey(szName, szTitle, fnDown, fnUp)
	table.insert(HOTKEY_CACHE, { szName = szName, szTitle = szTitle, fnDown = fnDown, fnUp = fnUp })
end

-- 获取快捷键名称
-- (string) X.GetHotKeyDisplay(string szName, boolean bBracket, boolean bShort)      -- 取得快捷键名称
function X.GetHotKeyDisplay(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szDisplay = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szDisplay ~= '' and bBracket then
		szDisplay = '(' .. szDisplay .. ')'
	end
	return szDisplay
end

-- 获取快捷键
-- (table) X.GetHotKey(string szName, true , true )       -- 取得快捷键
-- (number nKey, boolean bShift, boolean bCtrl, boolean bAlt) X.GetHotKey(string szName, true , fasle)        -- 取得快捷键
function X.GetHotKey(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	if nKey==0 then return nil end
	if bBracket then
		return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
	else
		return nKey, bShift, bCtrl, bAlt
	end
end

-- 设置快捷键/打开快捷键设置面板    -- HM里面抠出来的
-- (void) X.SetHotKey()                               -- 打开快捷键设置面板
-- (void) X.SetHotKey(string szGroup)     -- 打开快捷键设置面板并定位到 szGroup 分组（不可用）
-- (void) X.SetHotKey(string szCommand, number nKey )     -- 设置快捷键
-- (void) X.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- 设置快捷键
function X.SetHotKey(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
	if nIndex then
		if not nKey then
			nIndex, nKey = 1, nIndex
		end
		Hotkey.Set(szCommand, nIndex, nKey, bShift == true, bCtrl == true, bAlt == true)
	else
		local szGroup = szCommand or X.PACKET_INFO.NAME

		local frame = Station.Lookup('Topmost/HotkeyPanel')
		if not frame then
			frame = X.UI.OpenFrame('HotkeyPanel')
		elseif not frame:IsVisible() then
			frame:Show()
		end
		if not szGroup then return end
		-- load aKey
		local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
		for k, v in pairs(bindings) do
			if v.szHeader ~= '' then
				if aKey then
					break
				elseif v.szHeader == szGroup then
					aKey = {}
				else
					nI = nI + 1
				end
			end
			if aKey then
				if not v.Hotkey1 then
					v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				if not v.Hotkey2 then
					v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				table.insert(aKey, v)
			end
		end
		if not aKey then return end
		local hP = frame:Lookup('', 'Handle_List')
		local hI = hP:Lookup(nI)
		if hI.bSel then return end
		-- update list effect
		for i = 0, hP:GetItemCount() - 1 do
			local hB = hP:Lookup(i)
			if hB.bSel then
				hB.bSel = false
				if hB.IsOver then
					hB:Lookup('Image_Sel'):SetAlpha(128)
					hB:Lookup('Image_Sel'):Show()
				else
					hB:Lookup('Image_Sel'):Hide()
				end
			end
		end
		hI.bSel = true
		hI:Lookup('Image_Sel'):SetAlpha(255)
		hI:Lookup('Image_Sel'):Show()
		-- update content keys [hI.nGroupIndex]
		local hK = frame:Lookup('', 'Handle_Hotkey')
		local szIniFile = 'UI/Config/default/HotkeyPanel.ini'
		Hotkey.SetCapture(false)
		hK:Clear()
		hK.nGroupIndex = hI.nGroupIndex
		hK:AppendItemFromIni(szIniFile, 'Text_GroupName')
		hK:Lookup(0):SetText(szGroup)
		hK:Lookup(0).bGroup = true
		for k, v in ipairs(aKey) do
			hK:AppendItemFromIni(szIniFile, 'Handle_Binding')
			local hI = hK:Lookup(k)
			hI.bBinding = true
			hI.nIndex = k
			hI.szTip = v.szTip
			hI:Lookup('Text_Name'):SetText(v.szDesc)
			for i = 1, 2, 1 do
				local hK = hI:Lookup('Handle_Key'..i)
				hK.bKey = true
				hK.nIndex = i
				local hotkey = v['Hotkey'..i]
				hotkey.bUnchangeable = v.bUnchangeable
				hK.bUnchangeable = v.bUnchangeable
				local text = hK:Lookup('Text_Key'..i)
				text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
				-- update btn
				if hK.bUnchangeable then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(56)
				elseif hK.bDown then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bRDown then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bSel then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bOver then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(54)
				elseif hotkey.bChange then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(56)
				elseif hotkey.bConflict then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(54)
				else
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(53)
				end
			end
		end
		-- update content scroll
		hK:FormatAllItemPos()
		local wAll, hAll = hK:GetAllItemSize()
		local w, h = hK:GetSize()
		local scroll = frame:Lookup('Scroll_Key')
		local nCountStep = math.ceil((hAll - h) / 10)
		scroll:SetStepCount(nCountStep)
		scroll:SetScrollPos(0)
		if nCountStep > 0 then
			scroll:Show()
			scroll:GetParent():Lookup('Btn_Up'):Show()
			scroll:GetParent():Lookup('Btn_Down'):Show()
		else
			scroll:Hide()
			scroll:GetParent():Lookup('Btn_Up'):Hide()
			scroll:GetParent():Lookup('Btn_Down'):Hide()
		end
		-- update list scroll
		local scroll = frame:Lookup('Scroll_List')
		if scroll:GetStepCount() > 0 then
			local _, nH = hI:GetSize()
			local nStep = math.ceil((nI * nH) / 10)
			if nStep > scroll:GetStepCount() then
				nStep = scroll:GetStepCount()
			end
			scroll:SetScrollPos(nStep)
		end
	end
end

X.RegisterInit(X.NSFormatString('{$NS}#BIND_HOTKEY'), function()
	-- hotkey
	Hotkey.AddBinding(X.NSFormatString('{$NS}_Total'), _L['Toggle main panel'], X.PACKET_INFO.NAME, X.TogglePanel, nil)
	for _, v in ipairs(HOTKEY_CACHE) do
		Hotkey.AddBinding(v.szName, v.szTitle, '', v.fnDown, v.fnUp)
	end
	for i = 1, 5 do
		Hotkey.AddBinding(X.NSFormatString('{$NS}_HotKey_Null_')..i, _L['None-function hotkey'], '', function() end, nil)
	end
end)
if X.PACKET_INFO.DEBUG_LEVEL <= X.DEBUG_LEVEL.DEBUG then
	local aFrame = {
		'Lowest2/ChatPanel1',
		'Lowest2/ChatPanel2',
		'Lowest2/ChatPanel3',
		'Lowest2/ChatPanel4',
		'Lowest2/ChatPanel5',
		'Lowest2/ChatPanel6',
		'Lowest2/ChatPanel7',
		'Lowest2/ChatPanel8',
		'Lowest2/ChatPanel9',
		'Lowest2/EditBox',
		'Normal1/ChatPanel1',
		'Normal1/ChatPanel2',
		'Normal1/ChatPanel3',
		'Normal1/ChatPanel4',
		'Normal1/ChatPanel5',
		'Normal1/ChatPanel6',
		'Normal1/ChatPanel7',
		'Normal1/ChatPanel8',
		'Normal1/ChatPanel9',
		'Normal1/EditBox',
		'Normal/' .. X.PACKET_INFO.NAME_SPACE,
	}
	X.RegisterHotKey(X.NSFormatString('{$NS}_STAGE_CHAT'), _L['Display only chat panel'], function()
		if Station.IsVisible() then
			for _, v in ipairs(aFrame) do
				local frame = Station.Lookup(v)
				if frame then
					frame:ShowWhenUIHide()
				end
			end
			Station.Hide()
		else
			for _, v in ipairs(aFrame) do
				local frame = Station.Lookup(v)
				if frame then
					frame:HideWhenUIHide()
				end
			end
			Station.Show()
		end
	end)
end
X.RegisterHotKey(X.NSFormatString('{$NS}_STOP_CASTING'), _L['Stop cast skill'], function() X.GetClientPlayer().StopCurrentAction() end)
end

-- Format data's structure as struct descripted.
do
local defaultParams = { keepNewChild = false }
local function FormatDataStructure(data, struct, assign, metaSymbol)
	if metaSymbol == nil then
		metaSymbol = '__META__'
	end
	-- 标准化参数
	local params = setmetatable({}, defaultParams)
	local structTypes, defaultData, defaultDataType
	local keyTemplate, childTemplate, arrayTemplate, dictionaryTemplate
	if type(struct) == 'table' and struct[1] == metaSymbol then
		-- 处理有META标记的数据项
		-- 允许类型和默认值
		structTypes = struct[2] or { type(struct.__VALUE__) }
		defaultData = struct[3] or struct.__VALUE__
		defaultDataType = type(defaultData)
		-- 表模板相关参数
		if defaultDataType == 'table' then
			keyTemplate = struct.__KEY_TEMPLATE__
			childTemplate = struct.__CHILD_TEMPLATE__
			arrayTemplate = struct.__ARRAY_TEMPLATE__
			dictionaryTemplate = struct.__DICTIONARY_TEMPLATE__
		end
		-- 附加参数
		if struct.__PARAMS__ then
			for k, v in pairs(struct.__PARAMS__) do
				params[k] = v
			end
		end
	else
		-- 处理普通数据项
		structTypes = { type(struct) }
		defaultData = struct
		defaultDataType = type(defaultData)
	end
	-- 计算结构和数据的类型
	local dataType = type(data)
	local dataTypeExists = false
	if not dataTypeExists then
		for _, v in ipairs(structTypes) do
			if dataType == v then
				dataTypeExists = true
				break
			end
		end
	end
	-- 分别处理类型匹配与不匹配的情况
	if dataTypeExists then
		if not assign then
			data = X.Clone(data, true)
		end
		local keys, skipKeys = {}, {}
		-- 数据类型是表且默认数据也是表 则递归检查子元素与默认子元素
		if dataType == 'table' and defaultDataType == 'table' then
			for k, v in pairs(defaultData) do
				keys[k], skipKeys[k] = true, true
				data[k] = FormatDataStructure(data[k], defaultData[k], true, metaSymbol)
			end
		end
		-- 数据类型是表且META信息中定义了子元素KEY模板 则递归检查子元素KEY与子元素KEY模板
		if dataType == 'table' and keyTemplate then
			for k, v in pairs(data) do
				if not skipKeys[k] then
					local k1 = FormatDataStructure(k, keyTemplate, true, metaSymbol)
					if k1 ~= k then
						if k1 ~= nil then
							data[k1] = data[k]
						end
						data[k] = nil
					end
				end
			end
		end
		-- 数据类型是表且META信息中定义了子元素模板 则递归检查子元素与子元素模板
		if dataType == 'table' and childTemplate then
			for k, v in pairs(data) do
				if not skipKeys[k] then
					keys[k] = true
					data[k] = FormatDataStructure(data[k], childTemplate, true, metaSymbol)
				end
			end
		end
		-- 数据类型是表且META信息中定义了列表子元素模板 则递归检查子元素与列表子元素模板
		if dataType == 'table' and arrayTemplate then
			for i, v in pairs(data) do
				if type(i) == 'number' then
					if not skipKeys[i] then
						keys[i] = true
						data[i] = FormatDataStructure(data[i], arrayTemplate, true, metaSymbol)
					end
				end
			end
		end
		-- 数据类型是表且META信息中定义了哈希子元素模板 则递归检查子元素与哈希子元素模板
		if dataType == 'table' and dictionaryTemplate then
			for k, v in pairs(data) do
				if type(k) ~= 'number' then
					if not skipKeys[k] then
						keys[k] = true
						data[k] = FormatDataStructure(data[k], dictionaryTemplate, true, metaSymbol)
					end
				end
			end
		end
		-- 数据类型是表且默认数据也是表 则递归检查子元素是否需要保留
		if dataType == 'table' and defaultDataType == 'table' then
			if not params.keepNewChild then
				for k, v in pairs(data) do
					if defaultData[k] == nil and not keys[k] then -- 默认中没有且没有通过过滤器函数的则删除
						data[k] = nil
					end
				end
			end
		end
	else -- 类型不匹配的情况
		if type(defaultData) == 'table' then
			-- 默认值为表 需要递归检查子元素
			data = {}
			for k, v in pairs(defaultData) do
				data[k] = FormatDataStructure(nil, v, true, metaSymbol)
			end
		else -- 默认值不是表 直接克隆数据
			data = X.Clone(defaultData, true)
		end
	end
	return data
end
X.FormatDataStructure = FormatDataStructure
end

function X.SetGlobalValue(szVarPath, Val)
	local t = X.SplitString(szVarPath, '.')
	local tab = _G
	for k, v in ipairs(t) do
		if not X.IsTable(tab) then
			return false
		end
		if type(tab[v]) == 'nil' then
			tab[v] = {}
		end
		if k == #t then
			tab[v] = Val
		end
		tab = tab[v]
	end
	return true
end

function X.GetGlobalValue(szVarPath)
	local tVariable = _G
	for szIndex in string.gmatch(szVarPath, '[^%.]+') do
		if tVariable and type(tVariable) == 'table' then
			tVariable = tVariable[szIndex]
		else
			tVariable = nil
			break
		end
	end
	return tVariable
end

do
local SOUND_VOLUME_CACHE
local function CaptureSoundVolumes()
	local frame = Station.SearchFrame('SoundSettingPanel')
	local bClose = not frame
	if not frame then
		frame = X.UI.OpenFrame('SoundSettingPanel')
	end
	local chkMainMute = frame and frame:Lookup('CheckBox_Silence')
	local scrollMainVolume = frame and frame:Lookup('Scroll_MainVolume')
	local nMainVolume = chkMainMute and not chkMainMute:IsCheckBoxChecked() and scrollMainVolume
		and (scrollMainVolume:GetScrollPos() / scrollMainVolume:GetStepCount())
		or 0
	local chkBgMute = frame and frame:Lookup('CheckBox_BgSound')
	local scrollBgVolume = frame and frame:Lookup('Scroll_BgVolume')
	local nBgVolume = chkBgMute and chkBgMute:IsCheckBoxChecked() and scrollBgVolume
		and (scrollBgVolume:GetScrollPos() / scrollBgVolume:GetStepCount())
		or 0
	local chkRoleMute = frame and frame:Lookup('CheckBox_RoleSound')
	local scrollRoleVolume = frame and frame:Lookup('Scroll_ChVolume')
	local nRoleVolume = chkRoleMute and chkRoleMute:IsCheckBoxChecked() and scrollRoleVolume
		and (scrollRoleVolume:GetScrollPos() / scrollRoleVolume:GetStepCount())
		or 0
	local chkSceneMute = frame and frame:Lookup('CheckBox_SceneSound')
	local scrollSceneVolume = frame and frame:Lookup('Scroll_SceneVolume')
	local nSceneVolume = chkSceneMute and chkSceneMute:IsCheckBoxChecked() and scrollSceneVolume
		and (scrollSceneVolume:GetScrollPos() / scrollSceneVolume:GetStepCount())
		or 0
	local chkUIMute = frame and frame:Lookup('CheckBox_UISound')
	local scrollUIVolume = frame and frame:Lookup('Scroll_UIVolume')
	local nUIVolume = chkUIMute and chkUIMute:IsCheckBoxChecked() and scrollUIVolume
		and (scrollUIVolume:GetScrollPos() / scrollUIVolume:GetStepCount())
		or 0
	local chkTipMute = frame and frame:Lookup('CheckBox_Tip')
	local scrollTipVolume = frame and frame:Lookup('Scroll_TipVolume')
	local nTipVolume = chkTipMute and chkTipMute:IsCheckBoxChecked() and scrollTipVolume
		and (scrollTipVolume:GetScrollPos() / scrollTipVolume:GetStepCount())
		or 0
	local chkSpeakMute = frame and frame:Lookup('CheckBox_Speak')
	local scrollSpeakVolume = frame and frame:Lookup('Scroll_SpeakVolume')
	local nSpeakVolume = chkSpeakMute and chkSpeakMute:IsCheckBoxChecked() and scrollSpeakVolume
		and (scrollSpeakVolume:GetScrollPos() / scrollSpeakVolume:GetStepCount())
		or 0
	local chkErrorMute = frame and frame:Lookup('CheckBox_ErrorSound')
	local scrollErrorVolume = frame and frame:Lookup('Scroll_ErrorVolume')
	local nErrorVolume = chkErrorMute and chkErrorMute:IsCheckBoxChecked() and scrollErrorVolume
		and (scrollErrorVolume:GetScrollPos() / scrollErrorVolume:GetStepCount())
		or 0
	local chkHelpMute = frame and frame:Lookup('CheckBox_Help')
	local scrollHelpVolume = frame and frame:Lookup('Scroll_HelpVolume')
	local nHelpVolume = chkHelpMute and chkHelpMute:IsCheckBoxChecked() and scrollHelpVolume
		and (scrollHelpVolume:GetScrollPos() / scrollHelpVolume:GetStepCount())
		or 0
	if bClose then
		X.UI.CloseFrame('SoundSettingPanel')
	end
	SOUND_VOLUME_CACHE = {
		[SOUND.BG_MUSIC       ] = nBgVolume    * nMainVolume,
		[SOUND.UI_SOUND       ] = nUIVolume    * nMainVolume,
		[SOUND.UI_ERROR_SOUND ] = nErrorVolume * nMainVolume,
		[SOUND.SCENE_SOUND    ] = nSceneVolume * nMainVolume,
		[SOUND.CHARACTER_SOUND] = nRoleVolume  * nMainVolume,
		[SOUND.CHARACTER_SPEAK] = nSpeakVolume * nMainVolume,
		[SOUND.FRESHER_TIP    ] = nHelpVolume  * nMainVolume,
		[SOUND.SYSTEM_TIP     ] = nTipVolume   * nMainVolume,
	}
end

local SOUND_PANEL_OPEN_TIME
X.RegisterEvent('ON_FRAME_CREATE', 'LIB#SOUND_VOLUME', function()
	if arg0 and arg0:GetName() == 'SoundSettingPanel' then
		SOUND_PANEL_OPEN_TIME = GetTickCount()
	end
end)
X.RegisterEvent('ON_FRAME_DESTROY', 'LIB#SOUND_VOLUME', function()
	if arg0 and arg0:GetName() == 'SoundSettingPanel' then
		if GetTickCount() - SOUND_PANEL_OPEN_TIME >= 500 then
			SOUND_VOLUME_CACHE = nil
		end
	end
end)

function X.GetSoundVolume(eChannel)
	if not SOUND_VOLUME_CACHE then
		CaptureSoundVolumes()
	end
	return SOUND_VOLUME_CACHE[eChannel] or 0
end
end

do
local SOUND_ROOT = X.PACKET_INFO.FRAMEWORK_ROOT .. 'audio/'
local SOUNDS = {
	{
		szType = _L['Default'],
		{ dwID = 1, szName = _L['Bing.ogg'], szPath = SOUND_ROOT .. 'Bing.ogg', szWwise = 'UserPluginAudio_MY_Base_Bing' },
		{ dwID = 88001, szName = _L['Notify.ogg'], szPath = SOUND_ROOT .. 'Notify.ogg', szWwise = 'UserPluginAudio_MY_Base_Notify' },
	},
}
local CACHE, WWISE_EVENT = nil, {}
local function GetSoundList()
	local a = { szOption = _L['Sound'] }
	for _, v in ipairs(SOUNDS) do
		table.insert(a, v)
	end
	local RE = _G[X.NSFormatString('{$NS}_Resource')]
	if X.IsTable(RE) and X.IsFunction(RE.GetSoundList) then
		for _, v in ipairs(RE.GetSoundList()) do
			table.insert(a, v)
		end
	end
	return a
end
local function GetSoundMenu(tSound, fnAction, tCheck, bMultiple)
	local t = {}
	if tSound.szType then
		t.szOption = tSound.szType
	elseif tSound.dwID then
		t.szOption = tSound.szName
		t.bCheck = true
		t.bChecked = tCheck[tSound.dwID]
		t.bMCheck = not bMultiple
		t.UserData = tSound
		t.fnAction = fnAction
		t.fnMouseEnter = function()
			if IsCtrlKeyDown() then
				X.PlaySound(SOUND.UI_SOUND, tSound.szPath, false)
			else
				local szXml = GetFormatText(_L['Hold ctrl when move in to preview.'], nil, 255, 255, 0)
				OutputTip(szXml, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end
		end
		t.fnMouseLeave = function()
			HideTip()
		end
	end
	for _, v in ipairs(tSound) do
		local t1 = GetSoundMenu(v, fnAction, tCheck, bMultiple)
		if t1 then
			table.insert(t, t1)
		end
	end
	if t.dwID and not IsLocalFileExist(t.szPath) then
		return
	end
	return t
end

function X.GetSoundMenu(fnAction, tCheck, bMultiple)
	local function fnMenuAction(tSound, bCheck)
		fnAction(tSound.dwID, bCheck)
	end
	return GetSoundMenu(GetSoundList(), fnMenuAction, tCheck, bMultiple)
end

local function Cache(tSound)
	if not X.IsTable(tSound) then
		return
	end
	if tSound.dwID then
		CACHE[tSound.dwID] = {
			dwID = tSound.dwID,
			szName = tSound.szName,
			szPath = tSound.szPath,
		}
		if tSound.szWwise then
			WWISE_EVENT[string.lower(tSound.szPath)] = tSound.szWwise
		end
	end
	for _, t in ipairs(tSound) do
		Cache(t)
	end
end

local function GeneCache()
	if not CACHE then
		CACHE = {}
		local RE = _G[X.NSFormatString('{$NS}_Resource')]
		if X.IsTable(RE) and X.IsFunction(RE.GetSoundList) then
			local tSound = RE.GetSoundList()
			if tSound then
				Cache(tSound)
			end
		end
		Cache(SOUNDS)
	end
	return true
end

function X.GetSoundName(dwID)
	if not GeneCache() then
		return
	end
	local tSound = CACHE[dwID]
	if not tSound then
		return
	end
	return tSound.szName
end

function X.GetSoundPath(dwID)
	if not GeneCache() then
		return
	end
	local tSound = CACHE[dwID]
	if not tSound then
		return
	end
	return tSound.szPath
end

function X.RegisterWwiseSound(szPath, szEvent)
	WWISE_EVENT[string.lower(szPath)] = szEvent
end

local SOUND_PLAYER
local SOUND_BRIDGE_ROOT = X.PACKET_INFO.DATA_ROOT .. '#cache/sound/'
-- 播放声音
-- X.PlaySound(eChannel, szSoundPath, bAllowCustomize)
---@param eChannel SOUND @音频播放通道
---@param szSoundPath string @音频文件地址
---@param bAllowCustomize boolean @是否允许用户使用个性化音频覆盖，默认允许
function X.PlaySound(eChannel, szSoundPath, bAllowCustomize)
	if not GeneCache() then
		return
	end
	-- 允许简写基础库提供的音频资源地址
	szSoundPath = X.StringReplaceW(szSoundPath, '\\', '/')
	if not X.StringFindW(szSoundPath, '/') then
		szSoundPath = X.ConcatPath(X.PACKET_INFO.FRAMEWORK_ROOT, 'audio', szSoundPath)
	end
	local szFinalPath
	-- 自定义声音覆盖：仅可覆盖本插件的音频资源，覆盖文件位于插件数据文件夹角色配置、全局配置目录下的同名子路径文件
	if not szFinalPath and bAllowCustomize ~= false then
		local szPath = X.GetRelativePath(szSoundPath, '')
		if szPath then
			local szPrefix = X.PACKET_INFO.ROOT:lower()
			if szPath:lower():sub(1, #szPrefix) == szPrefix then
				szPath = szPath:sub(#szPrefix + 1)
				szPath = X.ConcatPath('audio', szPath)
			else
				szPath = nil
			end
		end
		if szPath then
			for _, ePathType in ipairs({
				X.PATH_TYPE.ROLE,
				X.PATH_TYPE.GLOBAL,
			}) do
				local szPath = X.FormatPath({ szPath, ePathType })
				if IsFileExist(szPath) then
					szFinalPath = szPath
					break
				end
			end
		end
	end
	-- 插件内置声音：位于基础库 audio 子文件夹
	if not szFinalPath then
		if IsFileExist(szSoundPath) then
			szFinalPath = szSoundPath
		end
	end
	-- 播放声音
	if szFinalPath then
		if X.ENVIRONMENT.SOUND_DRIVER == 'FMOD' then -- FMOD
			szFinalPath = X.NormalizePath(szFinalPath)
			PlaySound(eChannel, szFinalPath)
		elseif WWISE_EVENT[string.lower(szFinalPath)] then -- WWISE
			PlaySound(eChannel, WWISE_EVENT[string.lower(szFinalPath)])
		else -- fallback
			if not SOUND_PLAYER then
				SOUND_PLAYER = X.UI.GetTempElement('WndWebCef', X.NSFormatString('{$NS}Lib__SoundPlayer'))
			end
			szFinalPath = X.GetAbsolutePath(szFinalPath)
			szFinalPath = X.StringReplaceW(szFinalPath, '\\', '/')
			local SOUND_BRIDGE_PATH = SOUND_BRIDGE_ROOT .. eChannel .. '.html'
			CPath.MakeDir(SOUND_BRIDGE_ROOT)
			SaveDataToFile('<!DOCTYPE html><html><body><audio id="audio" autoplay><source src="' .. X.EncodeFileURI(szFinalPath) .. '"></audio><script>var audio = document.getElementById("audio"); audio.volume = ' .. X.GetSoundVolume(eChannel) .. ';</script></body></html>', SOUND_BRIDGE_PATH)
			SOUND_PLAYER:Navigate('about:blank')
			SOUND_PLAYER:Navigate(X.EncodeFileURI(X.StringReplaceW(X.GetAbsolutePath(SOUND_BRIDGE_PATH), '\\', '/')))
		end
	end
end
end

function X.GetFontList()
	local aList, tExist = {}, {}
	-- 插件字体包
	local FR = _G[X.NSFormatString('{$NS}_FontResource')]
	if X.IsTable(FR) and X.IsFunction(FR.GetList) then
		for _, p in ipairs(FR.GetList()) do
			local szFile = p.szFile:gsub('/', '\\')
			local szKey = szFile:lower()
			if not tExist[szKey] then
				table.insert(aList, {
					szName = p.szName,
					szFile = p.szFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 系统字体
	for _, p in X.ipairs_r(Font.GetFontPathList() or {}) do
		local szFile = p.szFile:gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			table.insert(aList, 1, {
				szName = p.szName,
				szFile = szFile,
			})
			tExist[szKey] = true
		end
	end
	-- 按照描述文件添加字体
	local CUSTOM_FONT_DIR = X.FormatPath({'font/', X.PATH_TYPE.GLOBAL})
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_FONT_DIR)) do
		local info = szFile:lower():find('%.jx3dat$') and X.LoadLUAData(CUSTOM_FONT_DIR .. szFile, { passphrase = false })
		if info and info.szName and info.szFile then
			local szFontFile = info.szFile:gsub('^%./', CUSTOM_FONT_DIR):gsub('/', '\\')
			local szKey = szFontFile:lower()
			if not tExist[szKey] then
				table.insert(aList, {
					szName = info.szName,
					szFile = szFontFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 纯字体文件
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_FONT_DIR)) do
		if szFile:lower():find('%.[to]tf$') then
			local szFontFile = (CUSTOM_FONT_DIR .. szFile):gsub('/', '\\')
			local szKey = szFontFile:lower()
			if not tExist[szKey] then
				table.insert(aList, {
					szName = szFile,
					szFile = szFontFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 删除不存在的字体
	for i, p in X.ipairs_r(aList) do
		if not IsFileExist(p.szFile) then
			table.remove(aList, i)
		end
	end
	return aList
end

-- 加载注册数据
X.RegisterInit(X.NSFormatString('{$NS}#INITDATA'), function()
	local t = LoadLUAData(X.GetLUADataPath({'config/initial.jx3dat', X.PATH_TYPE.GLOBAL}))
	if t then
		for v_name, v_data in pairs(t) do
			X.SetGlobalValue(v_name, v_data)
		end
	end
end)

-- ##################################################################################################
--               # # # #         #         #               #       #             #           #
--     # # # # #                 #           #       # # # # # # # # # # #         #       #
--           #                 #       # # # # # #         #       #           # # # # # # # # #
--         #         #       #     #       #                       # # #       #       #       #
--       # # # # # #         # # #       #     #     # # # # # # #             # # # # # # # # #
--             # #               #     #         #     #     #       #         #       #       #
--         # #         #       #       # # # # # #       #     #   #           # # # # # # # # #
--     # # # # # # # # # #   # # # #     #   #   #             #                       #
--             #         #               #   #       # # # # # # # # # # #   # # # # # # # # # # #
--       #     #     #           # #     #   #             #   #   #                   #
--     #       #       #     # #       #     #   #       #     #     #                 #
--   #       # #         #           #         # #   # #       #       # #             #
-- ##################################################################################################
do

local function menuSorter(m1, m2)
	return #m1 < #m2
end

local function RegisterMenu(aList, tKey, arg0, arg1)
	local szKey, oMenu
	if X.IsString(arg0) then
		szKey = arg0
		if X.IsTable(arg1) or X.IsFunction(arg1) then
			oMenu = arg1
		end
	elseif X.IsTable(arg0) or X.IsFunction(arg0) then
		oMenu = arg0
	end
	if szKey then
		for i, v in X.ipairs_r(aList) do
			if v.szKey == szKey then
				table.remove(aList, i)
			end
		end
		tKey[szKey] = nil
	end
	if oMenu then
		if not szKey then
			szKey = GetTickCount()
			while tKey[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		tKey[szKey] = true
		table.insert(aList, { szKey = szKey, oMenu = oMenu })
	end
	return szKey
end

local function GenerateMenu(aList, bMainMenu, dwTarType, dwTarID)
	if not X.AssertVersion('', '', '*') then
		return
	end
	local menu = {}
	if bMainMenu then
		menu = {
			szOption = X.PACKET_INFO.NAME,
			fnAction = X.TogglePanel,
			rgb = X.PACKET_INFO.MENU_COLOR,
			bCheck = true,
			bChecked = X.IsPanelVisible(),

			szIcon = X.PACKET_INFO.LOGO_UITEX,
			nFrame = X.PACKET_INFO.LOGO_MENU_FRAME,
			nMouseOverFrame = X.PACKET_INFO.LOGO_MENU_HOVER_FRAME,
			szLayer = 'ICON_RIGHT',
			fnClickIcon = X.TogglePanel,
		}
	end
	for _, p in ipairs(aList) do
		local m = p.oMenu
		if X.IsFunction(m) then
			m = m(dwTarType, dwTarID)
		end
		if not m or m.szOption then
			m = {m}
		end
		for _, v in ipairs(m) do
			if not v.rgb and not bMainMenu then
				v.rgb = X.PACKET_INFO.MENU_COLOR
			end
			table.insert(menu, v)
		end
	end
	table.sort(menu, menuSorter)
	return bMainMenu and {menu} or menu
end

do
local PLAYER_MENU, PLAYER_MENU_HASH = {}, {} -- 玩家头像菜单
-- 注册玩家头像菜单
-- 注册
-- (void) X.RegisterPlayerAddonMenu(Menu)
-- (void) X.RegisterPlayerAddonMenu(szName, tMenu)
-- (void) X.RegisterPlayerAddonMenu(szName, fnMenu)
-- 注销
-- (void) X.RegisterPlayerAddonMenu(szName, false)
function X.RegisterPlayerAddonMenu(arg0, arg1)
	return RegisterMenu(PLAYER_MENU, PLAYER_MENU_HASH, arg0, arg1)
end
local function GetPlayerAddonMenu(dwTarID, dwTarType)
	return GenerateMenu(PLAYER_MENU, true, dwTarType, dwTarID)
end
Player_AppendAddonMenu({GetPlayerAddonMenu})
end

do
local TRACE_MENU, TRACE_MENU_HASH = {}, {} -- 工具栏菜单
-- 注册工具栏菜单
-- 注册
-- (void) X.RegisterTraceButtonAddonMenu(Menu)
-- (void) X.RegisterTraceButtonAddonMenu(szName, tMenu)
-- (void) X.RegisterTraceButtonAddonMenu(szName, fnMenu)
-- 注销
-- (void) X.RegisterTraceButtonAddonMenu(szName, false)
function X.RegisterTraceButtonAddonMenu(arg0, arg1)
	return RegisterMenu(TRACE_MENU, TRACE_MENU_HASH, arg0, arg1)
end
function X.GetTraceButtonAddonMenu(dwTarID, dwTarType)
	return GenerateMenu(TRACE_MENU, true, dwTarType, dwTarID)
end
TraceButton_AppendAddonMenu({X.GetTraceButtonAddonMenu})
end

do
local TARGET_MENU, TARGET_MENU_HASH = {}, {} -- 目标头像菜单
-- 注册目标头像菜单
-- 注册
-- (void) X.RegisterTargetAddonMenu(Menu)
-- (void) X.RegisterTargetAddonMenu(szName, tMenu)
-- (void) X.RegisterTargetAddonMenu(szName, fnMenu)
-- 注销
-- (void) X.RegisterTargetAddonMenu(szName, false)
function X.RegisterTargetAddonMenu(arg0, arg1)
	return RegisterMenu(TARGET_MENU, TARGET_MENU_HASH, arg0, arg1)
end
local function GetTargetAddonMenu(dwTarID, dwTarType)
	return GenerateMenu(TARGET_MENU, false, dwTarType, dwTarID)
end
Target_AppendAddonMenu({GetTargetAddonMenu})
end
end

-- 注册玩家头像和工具栏菜单
-- 注册
-- (void) X.RegisterAddonMenu(Menu)
-- (void) X.RegisterAddonMenu(szName, tMenu)
-- (void) X.RegisterAddonMenu(szName, fnMenu)
-- 注销
-- (void) X.RegisterAddonMenu(szName, false)
function X.RegisterAddonMenu(...)
	X.RegisterPlayerAddonMenu(...)
	X.RegisterTraceButtonAddonMenu(...)
end

-- Format `prime`:
--   It's not particularly common for expressions of time.
--   It's similar to degrees-minutes-seconds: instead of decimal degrees (38.897212°,-77.036519°) you write (38° 53′ 49.9632″, -77° 2′ 11.4678″).
--   Both are derived from a sexagesimal counting system such as that devised in Ancient Babylon:
--   the single prime represents the first sexagesimal division and the second the next, and so on.
--   17th-century astronomers used a third division of 1/60th of a second.
--   The advantage of using minute and second symbols for time is that it obviously expresses a duration rather than a time.
--   From the time 01:00:00 to the time 02:34:56 is a duration of 1 hour, 34 minutes and 56 seconds (1h 34′ 56″)
--   Prime markers start single and are multiplied for subsequent appearances, so minutes use a single prime ′ and seconds use a double-prime ″.
--   They are pronounced minutes and seconds respectively in the case of durations like this.
--   Note that a prime ′ is not a straight-apostrophe ' or a printer's apostrophe ’, although straight-apostrophes are a reasonable approximation and printer's apostrophes do occur as well.

---@class FormatDurationUnitItem @格式化时间配置项参数
---@field normal string @正常显示格式
---@field fixed string @固定宽度显示格式
---@field skipNull boolean @为空是否跳过
---@field delimiter string @分隔符

---@class FormatDurationUnit @格式化时间配置参数
---@field year FormatDurationUnitItem | string @年数
---@field day FormatDurationUnitItem | string @天数
---@field hour FormatDurationUnitItem | string @小时数
---@field minute FormatDurationUnitItem | string @分钟数
---@field second FormatDurationUnitItem | string @秒钟数

---@type table<string, FormatDurationUnit>
local FORMAT_TIME_COUNT_PRESET = {
	['CHINESE'] = {
		year = { normal = '%d' .. g_tStrings.STR_YEAR, fixed = '%04d' .. g_tStrings.STR_YEAR, skipNull = true },
		day = { normal = '%d' .. g_tStrings.STR_BUFF_H_TIME_D_SHORT, fixed = '%02d' .. g_tStrings.STR_BUFF_H_TIME_D_SHORT, skipNull = true },
		hour = { normal = '%d' .. g_tStrings.STR_TIME_HOUR, fixed = '%02d' .. g_tStrings.STR_TIME_HOUR, skipNull = true },
		minute = { normal = '%d' .. g_tStrings.STR_TIME_MINUTE, fixed = '%02d' .. g_tStrings.STR_TIME_MINUTE, skipNull = true },
		second = { normal = '%d' .. g_tStrings.STR_TIME_SECOND, fixed = '%02d' .. g_tStrings.STR_TIME_SECOND, skipNull = true },
	},
	['ENGLISH_ABBR'] = {
		year = { normal = '%dy', fixed = '%04dy' },
		day = { normal = '%dd', fixed = '%02dd' },
		hour = { normal = '%dh', fixed = '%02dh' },
		minute = { normal = '%dm', fixed = '%02dm' },
		second = { normal = '%ds', fixed = '%02ds' },
	},
	['PRIME'] = {
		minute = { normal = '%d\'', fixed = '%02d\'' },
		second = { normal = '%d"', fixed = '%02d"' },
	},
	['SYMBOL'] = {
		hour = { normal = '%d', fixed = '%02d', delimiter = ':' },
		minute = { normal = '%d', fixed = '%02d', delimiter = ':' },
		second = { normal = '%d', fixed = '%02d' },
	},
}
local FORMAT_TIME_UNIT_LIST = {
	{ key = 'year' },
	{ key = 'day', radix = 365 },
	{ key = 'hour', radix = 24 },
	{ key = 'minute', radix = 60 },
	{ key = 'second', radix = 60 },
}

---@class FormatDurationControl @格式化时间控制参数
---@field mode "'normal'" | "'fixed'" | "'fixed-except-leading'" @格式化模式
---@field maxUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @开始单位，最大只显示到该单位，默认值：'year'。
---@field keepUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @零值也保留的单位位置，默认值：'second'。
---@field accuracyUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @精度结束单位，精度低于该单位的数据将被省去，默认值：'second'。

-- 格式化计时时间
---@param nTime number @时间
---@param tUnitFmt FormatDurationUnit | string @格式化参数 或 预设方案名（见 `FORMAT_TIME_COUNT_PRESET`）
---@param tControl FormatDurationControl @控制参数
function X.FormatDuration(nTime, tUnitFmt, tControl)
	if X.IsString(tUnitFmt) then
		tUnitFmt = FORMAT_TIME_COUNT_PRESET[tUnitFmt]
	end
	if not X.IsTable(tUnitFmt) then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: invalid UnitFormat.'))
	end
	-- 格式化模式
	local mode = tControl and tControl.mode or 'normal'
	-- 开始单位，最大只显示到该单位
	local maxUnit = tControl and tControl.maxUnit or 'year'
	local maxUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == maxUnit then
			maxUnitIndex = i
			break
		end
	end
	if maxUnitIndex == -1 then
		maxUnitIndex = 1
		maxUnit = FORMAT_TIME_UNIT_LIST[maxUnitIndex].key
	end
	-- 零值也保留的单位位置
	local keepUnit = tControl and tControl.keepUnit or 'second'
	local keepUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == keepUnit then
			keepUnitIndex = i
			break
		end
	end
	if keepUnitIndex == -1 then
		keepUnitIndex = #FORMAT_TIME_UNIT_LIST
		keepUnit = FORMAT_TIME_UNIT_LIST[keepUnitIndex].key
	end
	-- 精度结束单位，精度低于该单位的数据将被省去
	local accuracy = tControl and tControl.accuracyUnit or 'second'
	local accuracyUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == accuracy then
			accuracyUnitIndex = i
			break
		end
	end
	if accuracyUnitIndex == -1 then
		accuracyUnitIndex = #FORMAT_TIME_UNIT_LIST
		accuracy = FORMAT_TIME_UNIT_LIST[accuracyUnitIndex].key
	end
	if maxUnitIndex > keepUnitIndex then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: maxUnit must be less than keepUnit.'))
	end
	if maxUnitIndex > accuracyUnitIndex then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: maxUnit must be less than accuracyUnit.'))
	end
	-- 计算完整各个单位数据
	local aValue = {}
	for i, unit in X.ipairs_r(FORMAT_TIME_UNIT_LIST) do
		if i > 1 then
			aValue[i] = nTime % unit.radix
			nTime = math.floor(nTime / unit.radix)
		else
			aValue[i] = nTime
		end
	end
	-- 合并超出开始单位或不存在的单位数据到下级单位中
	for i, unit in ipairs(FORMAT_TIME_UNIT_LIST) do
		if i < maxUnitIndex or not tUnitFmt[unit.key] then
			local nextUnit = FORMAT_TIME_UNIT_LIST[i + 1]
			if nextUnit then
				aValue[i + 1] = aValue[i + 1] + aValue[i] * nextUnit.radix
				aValue[i] = 0
			end
		end
	end
	-- 合并超出精度单位的数据到上级单位中
	for i, unit in X.ipairs_r(FORMAT_TIME_UNIT_LIST) do
		if i > accuracyUnitIndex then
			local prevUnit = FORMAT_TIME_UNIT_LIST[i - 1]
			if prevUnit then
				aValue[i - 1] = aValue[i - 1] + aValue[i] / unit.radix
				aValue[i] = 0
			end
		end
	end
	-- 单位依次拼接
	local szText, szSplitter = '', ''
	for i, unit in ipairs(FORMAT_TIME_UNIT_LIST) do
		local fmt = tUnitFmt[unit.key]
		if X.IsString(fmt) then
			fmt = { normal = fmt }
		end
		if i >= maxUnitIndex and i <= accuracyUnitIndex -- 单位在最大最小允许显示之间
		and fmt -- 并且单位自定义格式化数据存在
		and (
			aValue[i] > 0 --数据不为空
			or (szText ~= '' and not fmt.skipNull) -- 或者数据为空但高位有值且该单位格式化数据要求不可省略
			or i >= keepUnitIndex -- 单位位于零值保留单位之后
		) then
			local formatString = (mode == 'normal' or (mode == 'fixed-except-leading' and szText == ''))
				and (fmt.normal)
				or (fmt.fixed or fmt.normal)
			szText = szText .. szSplitter .. formatString:format(math.ceil(aValue[i]))
			szSplitter = fmt.delimiter or ''
		end
	end
	return szText
end

-- 格式化时间
-- (string) X.FormatTime(nTimestamp, szFormat)
-- nTimestamp UNIX时间戳
-- szFormat   格式化字符串
--   %yyyy 年份四位对齐
--   %yy   年份两位对齐
--   %MM   月份两位对齐
--   %dd   日期两位对齐
--   %y    年份
--   %m    月份
--   %d    日期
--   %hh   小时两位对齐
--   %mm   分钟两位对齐
--   %ss   秒钟两位对齐
--   %h    小时
--   %m    分钟
--   %s    秒钟
function X.FormatTime(nTimestamp, szFormat)
	local t = TimeToDate(nTimestamp)
	szFormat = X.StringReplaceW(szFormat, '%yyyy', string.format('%04d', t.year  ))
	szFormat = X.StringReplaceW(szFormat, '%yy'  , string.format('%02d', t.year % 100))
	szFormat = X.StringReplaceW(szFormat, '%MM'  , string.format('%02d', t.month ))
	szFormat = X.StringReplaceW(szFormat, '%dd'  , string.format('%02d', t.day   ))
	szFormat = X.StringReplaceW(szFormat, '%hh'  , string.format('%02d', t.hour  ))
	szFormat = X.StringReplaceW(szFormat, '%mm'  , string.format('%02d', t.minute))
	szFormat = X.StringReplaceW(szFormat, '%ss'  , string.format('%02d', t.second))
	szFormat = X.StringReplaceW(szFormat, '%y', t.year  )
	szFormat = X.StringReplaceW(szFormat, '%M', t.month )
	szFormat = X.StringReplaceW(szFormat, '%d', t.day   )
	szFormat = X.StringReplaceW(szFormat, '%h', t.hour  )
	szFormat = X.StringReplaceW(szFormat, '%m', t.minute)
	szFormat = X.StringReplaceW(szFormat, '%s', t.second)
	return szFormat
end

function X.DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
	return DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
end

function X.TimeToDate(nTimestamp)
	local date = TimeToDate(nTimestamp)
	return date.year, date.month, date.day, date.hour, date.minute, date.second
end

-- 格式化数字小数点
-- (string) X.FormatNumberDot(nValue, nDot, bDot, bSimple)
-- nValue  要格式化的数字
-- nDot    小数点位数
-- bDot    小数点不足补位0
-- bSimple 是否显示精简数值
function X.FormatNumberDot(nValue, nDot, bDot, bSimple)
	if not nDot then
		nDot = 0
	end
	local szUnit = ''
	if bSimple then
		if nValue >= 100000000 then
			nValue = nValue / 100000000
			szUnit = g_tStrings.DIGTABLE.tCharDiH[3]
		elseif nValue > 100000 then
			nValue = nValue / 10000
			szUnit = g_tStrings.DIGTABLE.tCharDiH[2]
		end
	end
	return math.floor(nValue * math.pow(2, nDot)) / math.pow(2, nDot) .. szUnit
end

-- register global esc key down action
-- (void) X.RegisterEsc(szID, fnCondition, fnAction, bTopmost) -- register global esc event handle
-- (void) X.RegisterEsc(szID, nil, nil, bTopmost)              -- unregister global esc event handle
-- (string)szID        -- an UUID (if this UUID has been register before, the old will be recovered)
-- (function)fnCondition -- a function returns if fnAction will be execute
-- (function)fnAction    -- inf fnCondition() is true then fnAction will be called
-- (boolean)bTopmost    -- this param equals true will be called in high priority
function X.RegisterEsc(szID, fnCondition, fnAction, bTopmost)
	if fnCondition and fnAction then
		if RegisterGlobalEsc then
			RegisterGlobalEsc(X.PACKET_INFO.NAME_SPACE .. '#' .. szID, fnCondition, fnAction, bTopmost)
		end
	else
		if UnRegisterGlobalEsc then
			UnRegisterGlobalEsc(X.PACKET_INFO.NAME_SPACE .. '#' .. szID, bTopmost)
		end
	end
end

-- 测试用
if loadstring then
function X.ProcessCommand(cmd)
	local ls = loadstring('return ' .. cmd)
	if ls then
		return ls()
	end
end
end

do
local bCustomMode = false
function X.IsInCustomUIMode()
	return bCustomMode
end
X.RegisterEvent('ON_ENTER_CUSTOM_UI_MODE', function() bCustomMode = true  end)
X.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE', function() bCustomMode = false end)
end

function X.DoMessageBox(szName, i)
	local frame = Station.Lookup('Topmost2/MB_' .. szName) or Station.Lookup('Topmost/MB_' .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup('Wnd_All/Btn_Option' .. i)
		if btn and btn:IsEnabled() then
			if btn.fnAction then
				if frame.args then
					btn.fnAction(X.Unpack(frame.args))
				else
					btn.fnAction()
				end
			elseif frame.fnAction then
				if frame.args then
					frame.fnAction(i, X.Unpack(frame.args))
				else
					frame.fnAction(i)
				end
			end
			frame.OnFrameDestroy = nil
			CloseMessageBox(szName)
		end
	end
end

do -- 二次封装 MessageBox 相关事件
local function OnMessageBoxOpen()
	local szName, frame, aMsg = arg0, arg1, {}
	if not frame then
		return
	end
	local wndAll = frame:Lookup('Wnd_All')
	if not wndAll then
		return
	end
	for i = 1, 5 do
		local btn = wndAll:Lookup('Btn_Option' .. i)
		if btn and btn.IsVisible and btn:IsVisible() then
			local nIndex, szOption = btn.nIndex, btn.szOption
			if btn.fnAction then
				HookTableFunc(btn, 'fnAction', function()
					FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			if btn.fnCountDownEnd then
				HookTableFunc(btn, 'fnCountDownEnd', function()
					FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'TIME_OUT', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			aMsg[i] = { nIndex = nIndex, szOption = szOption }
		end
	end

	HookTableFunc(frame, 'fnAction', function(i)
		local msg = aMsg[i]
		if not msg then
			return
		end
		FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', msg.szOption, msg.nIndex)
	end, { bAfterOrigin = true })

	HookTableFunc(frame, 'fnCancelAction', function()
		FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'CANCEL')
	end, { bAfterOrigin = true })

	if frame.fnAutoClose then
		HookTableFunc(frame, 'fnAutoClose', function()
			FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'AUTO_CLOSE')
		end, { bAfterOrigin = true })
	end

	FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_OPEN'), arg0, arg1)
end
X.RegisterEvent('ON_MESSAGE_BOX_OPEN', OnMessageBoxOpen)
end

-- 弹出对话框
-- X.MessageBox([szKey, ]tMsg)
-- X.MessageBox([szKey, ]tMsg)
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param tMsg {object} 更多参见官方 MessageBox 文档
-- 	@param tMsg.fnCancelAction {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.MessageBox(szKey, tMsg)
	if X.IsTable(szKey) then
		szKey, tMsg = nil, szKey
	end
	if not szKey then
		szKey = X.GetUUID():gsub('-', '')
	end
	tMsg.szName = X.NSFormatString('{$NS}_MessageBox#') .. GetStringCRC(szKey)
	if not tMsg.x or not tMsg.y then
		local nW, nH = Station.GetClientSize()
		tMsg.x = nW / 2
		tMsg.y = nH / 3
	end
	if not tMsg.szAlignment then
		tMsg.szAlignment = 'CENTER'
	end
	if tMsg.fnCancelAction == 'FORBIDDEN' then
		tMsg.fnCancelAction = function()
			X.DelayCall(function()
				X.MessageBox(szKey, tMsg)
			end)
		end
	end
	MessageBox(tMsg)
	return szKey
end

-- 弹出对话框 - 单按钮确认
-- X.Alert([szKey, ]szMsg[, fnResolve])
-- X.Alert([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.szResolve {string} 按钮文案
-- 	@param tOpt.fnResolve {function} 按钮回调
-- 	@param tOpt.nResolveCountDown {number} 确定按钮倒计时
-- 	@param tOpt.fnCancel {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.Alert(szKey, szMsg, fnResolve)
	if not X.IsString(szMsg) then
		szKey, szMsg, fnResolve = nil, szKey, szMsg
	end
	local tOpt = fnResolve
	if not X.IsTable(tOpt) then
		tOpt = { fnResolve = fnResolve }
	end
	return X.MessageBox(szKey, {
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		{
			szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE,
			fnAction = tOpt.fnResolve,
			bDelayCountDown = tOpt.nResolveCountDown and true or false,
			nCountDownTime = tOpt.nResolveCountDown,
		},
	})
end

-- 弹出对话框 - 双按钮二次确认
-- X.Confirm([szKey, ]szMsg[, fnResolve[, fnReject[, fnCancel]]])
-- X.Confirm([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.szResolve {string} 确定按钮文案
-- 	@param tOpt.fnResolve {function} 确定回调
-- 	@param tOpt.szReject {string} 取消按钮文案
-- 	@param tOpt.fnReject {function} 取消回调
-- 	@param tOpt.fnCancel {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.Confirm(szKey, szMsg, fnResolve, fnReject, fnCancel)
	if not X.IsString(szMsg) then
		szKey, szMsg, fnResolve, fnReject = nil, szKey, szMsg, fnResolve
	end
	local tOpt = fnResolve
	if not X.IsTable(tOpt) then
		tOpt = {
			fnResolve = fnResolve,
			fnReject = fnReject,
			fnCancel = fnCancel,
		}
	end
	return X.MessageBox(szKey, {
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		{ szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE, fnAction = tOpt.fnResolve },
		{ szOption = tOpt.szReject or g_tStrings.STR_HOTKEY_CANCEL, fnAction = tOpt.fnReject },
	})
end

-- 弹出对话框 - 自定义按钮
-- X.Dialog([szKey, ]szMsg[, aOptions[, fnCancelAction]])
-- X.Dialog([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.aOptions {array} 按钮列表，参见 MessageBox 用法
-- 	@param tOpt.fnCancelAction {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.Dialog(szKey, szMsg, aOptions, fnCancelAction)
	if not X.IsString(szMsg) then
		szKey, szMsg, aOptions, fnCancelAction = nil, szKey, szMsg, aOptions
	end
	local tMsg = {
		szMessage = szMsg,
		fnCancelAction = fnCancelAction,
	}
	for i, p in ipairs(aOptions) do
		local tOption = {
			szOption = p.szOption,
			fnAction = p.fnAction,
		}
		if not tOption.szOption then
			if i == 1 then
				tOption.szOption = g_tStrings.STR_HOTKEY_SURE
			elseif i == #aOptions then
				tOption.szOption = g_tStrings.STR_HOTKEY_CANCEL
			end
		end
		table.insert(tMsg, tOption)
	end
	return X.MessageBox(szKey, tMsg)
end

do
function X.Hex2RGB(hex)
	local s, r, g, b, a = hex:gsub('#', ''), nil, nil, nil, nil
	if #s == 3 then
		r, g, b = s:sub(1, 1):rep(2), s:sub(2, 2):rep(2), s:sub(3, 3):rep(2)
	elseif #s == 4 then
		r, g, b, a = s:sub(1, 1):rep(2), s:sub(2, 2):rep(2), s:sub(3, 3):rep(2), s:sub(4, 4):rep(2)
	elseif #s == 6 then
		r, g, b = s:sub(1, 2), s:sub(3, 4), s:sub(5, 6)
	elseif #s == 8 then
		r, g, b, a = s:sub(1, 2), s:sub(3, 4), s:sub(5, 6), s:sub(7, 8)
	end

	if not r or not g or not b then
		return
	end
	if a then
		a = tonumber('0x' .. a)
	end
	r, g, b = tonumber('0x' .. r), tonumber('0x' .. g), tonumber('0x' .. b)

	if not r or not g or not b then
		return
	end
	return r, g, b, a
end

function X.RGB2Hex(r, g, b, a)
	if a then
		return (('#%02X%02X%02X%02X'):format(r, g, b, a))
	end
	return (('#%02X%02X%02X'):format(r, g, b))
end

local COLOR_NAME_RGB = {}
do
	local aColor = X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/colors/{$lang}.jx3dat')
	for szColor, aKey in ipairs(aColor) do
		local nR, nG, nB = X.Hex2RGB(szColor)
		if nR then
			for _, szKey in ipairs(aKey) do
				COLOR_NAME_RGB[szKey] = {nR, nG, nB}
			end
		end
	end
end

function X.ColorName2RGB(name)
	if not COLOR_NAME_RGB[name] then
		return
	end
	return X.Unpack(COLOR_NAME_RGB[name])
end

local HUMAN_COLOR_CACHE = setmetatable({}, {__mode = 'v', __index = COLOR_NAME_RGB})
function X.HumanColor2RGB(name)
	if X.IsTable(name) then
		if name.r then
			return name.r, name.g, name.b
		end
		return X.Unpack(name)
	end
	if not HUMAN_COLOR_CACHE[name] then
		local r, g, b, a = X.Hex2RGB(name)
		HUMAN_COLOR_CACHE[name] = {r, g, b, a}
	end
	return X.Unpack(HUMAN_COLOR_CACHE[name])
end
end

-- 获取某个字体的颜色
-- (bool) X.GetFontColor(number nFont)
do
local CACHE, el = {}, nil
function X.GetFontColor(nFont)
	if not CACHE[nFont] then
		if not el or not X.IsElement(el) then
			el = X.UI.GetTempElement('Text', X.NSFormatString('{$NS}Lib__GetFontColor'))
		end
		el:SetFontScheme(nFont)
		CACHE[nFont] = X.Pack(el:GetFontColor())
	end
	return X.Unpack(CACHE[nFont])
end
end

function X.ExecuteWithThis(context, fnAction, ...)
	-- 界面组件支持字符串调用方法
	if X.IsString(fnAction) then
		if not X.IsElement(context) then
			return false
		end
		if context[fnAction] then
			fnAction = context[fnAction]
		else
			local szFrame = context:GetRoot():GetName()
			if type(_G[szFrame]) == 'table' then
				fnAction = _G[szFrame][fnAction]
			end
		end
	end
	if not X.IsFunction(fnAction) then
		return false
	end
	local _this = this
	this = context
	local rets = X.Pack(fnAction(...))
	this = _this
	return true, X.Unpack(rets)
end

do
local HOOK = setmetatable({}, { __mode = 'k' })
-- X.SetMemberFunctionHook(tTable, szName, fnHook, tOption) -- hook
-- X.SetMemberFunctionHook(tTable, szName, szKey, fnHook, tOption) -- hook
-- X.SetMemberFunctionHook(tTable, szName, szKey, false) -- unhook
function X.SetMemberFunctionHook(t, xArg1, xArg2, xArg3, xArg4)
	local eAction, szName, szKey, fnHook, tOption
	if X.IsTable(t) and X.IsFunction(xArg2) then
		eAction, szName, fnHook, tOption = 'REG', xArg1, xArg2, xArg3
	elseif X.IsTable(t) and X.IsString(xArg2) and X.IsFunction(xArg3) then
		eAction, szName, szKey, fnHook, tOption = 'REG', xArg1, xArg2, xArg3, xArg4
	elseif X.IsTable(t) and X.IsString(xArg2) and xArg3 == false then
		eAction, szName, szKey = 'UNREG', xArg1, xArg2
	end
	if not eAction then
		assert(false, 'Parameters type not recognized, cannot infer action type.')
	end
	-- 匿名注册分配随机标识符
	if eAction == 'REG' and not X.IsString(szKey) then
		szKey = GetTickCount() * 1000
		while X.Get(HOOK, {t, szName, (tostring(szKey))}) do
			szKey = szKey + 1
		end
		szKey = tostring(szKey)
	end
	if eAction == 'REG' or eAction == 'UNREG' then
		local fnCurrentHook = X.Get(HOOK, {t, szName, szKey})
		if fnCurrentHook then
			X.Set(HOOK, {t, szName, szKey}, nil)
			UnhookTableFunc(t, szName, fnCurrentHook)
		end
	end
	if eAction == 'REG' then
		X.Set(HOOK, {t, szName, szKey}, fnHook)
		HookTableFunc(t, szName, fnHook, tOption)
	end
	return szKey
end
end

function X.GetOperatorName(szOperator, L)
	return L and L[szOperator] or _L.OPERATOR[szOperator]
end

function X.InsertOperatorMenu(t, szOperator, fnAction, aOperator, L)
	for _, szOp in ipairs(aOperator or { '==', '!=', '<', '>=', '>', '<=' }) do
		table.insert(t, {
			szOption = L and L[szOp] or _L.OPERATOR[szOp],
			bCheck = true, bMCheck = true,
			bChecked = szOperator == szOp,
			fnAction = function() fnAction(szOp) end,
		})
	end
	return t
end

function X.JudgeOperator(szOperator, dwLeftValue, dwRightValue)
	if szOperator == '>' then
		return dwLeftValue > dwRightValue
	elseif szOperator == '>=' then
		return dwLeftValue >= dwRightValue
	elseif szOperator == '<' then
		return dwLeftValue < dwRightValue
	elseif szOperator == '<=' then
		return dwLeftValue <= dwRightValue
	elseif szOperator == '=' or szOperator == '==' or szOperator == '===' then
		return dwLeftValue == dwRightValue
	elseif szOperator == '<>' or szOperator == '~=' or szOperator == '!=' or szOperator == '!==' then
		return dwLeftValue ~= dwRightValue
	end
end

-- 跨线程实时获取目标界面位置
-- 注册：X.CThreadCoor(dwType, dwID, szKey, true)
-- 注销：X.CThreadCoor(dwType, dwID, szKey, false)
-- 获取：X.CThreadCoor(dwType, dwID) -- 必须已注册才能获取
-- 注册：X.CThreadCoor(dwType, nX, nY, nZ, szKey, true)
-- 注销：X.CThreadCoor(dwType, nX, nY, nZ, szKey, false)
-- 获取：X.CThreadCoor(dwType, nX, nY, nZ) -- 必须已注册才能获取
do
local CACHE = {}
function X.CThreadCoor(arg0, arg1, arg2, arg3, arg4, arg5)
	local dwType, dwID, nX, nY, nZ, szCtcKey, szKey, bReg = arg0, nil, nil, nil, nil, nil, nil, nil
	if dwType == CTCT.CHARACTER_TOP_2_SCREEN_POS or dwType == CTCT.CHARACTER_POS_2_SCREEN_POS or dwType == CTCT.DOODAD_POS_2_SCREEN_POS then
		dwID, szKey, bReg = arg1, arg2, arg3
		szCtcKey = dwType .. '_' .. dwID
	elseif dwType == CTCT.SCENE_2_SCREEN_POS or dwType == CTCT.GAME_WORLD_2_SCREEN_POS then
		nX, nY, nZ, szKey, bReg = arg1, arg2, arg3, arg4, arg5
		szCtcKey = dwType .. '_' .. nX .. '_' .. nY .. '_' .. nZ
	end
	if szKey then
		if bReg then
			if not CACHE[szCtcKey] then
				local cache = { keys = {} }
				if dwID then
					cache.ctcid = CThreadCoor_Register(dwType, dwID)
				else
					cache.ctcid = CThreadCoor_Register(dwType, nX, nY, nZ)
				end
				CACHE[szCtcKey] = cache
			end
			CACHE[szCtcKey].keys[szKey] = true
		else
			local cache = CACHE[szCtcKey]
			if cache then
				cache.keys[szKey] = nil
				if not next(cache.keys) then
					CThreadCoor_Unregister(cache.ctcid)
					CACHE[szCtcKey] = nil
				end
			end
		end
	else
		local cache = CACHE[szCtcKey]
		--[[#DEBUG BEGIN]]
		if not cache then
			X.Debug(X.NSFormatString('{$NS}#SYS'), _L('Error: `%s` has not be registed!', szCtcKey), X.DEBUG_LEVEL.ERROR)
		end
		--[[#DEBUG END]]
		return CThreadCoor_Get(cache.ctcid) -- nX, nY, bFront
	end
end
end

function X.GetUIScale()
	return Station.GetUIScale()
end

function X.GetOriginUIScale()
	-- 线性拟合出来的公式 -- 不知道不同机器会不会不一样
	-- 源数据
	-- 0.63, 0.7
	-- 0.666, 0.75
	-- 0.711, 0.8
	-- 0.756, 0.85
	-- 0.846, 0.95
	-- 0.89, 1
	-- return math.floor((1.13726 * Station.GetUIScale() / Station.GetMaxUIScale() - 0.011) * 100 + 0.5) / 100 -- +0.5为了四舍五入
	-- 不同显示器GetMaxUIScale都不一样 太麻烦了 放弃 直接读配置项
	return GetUserPreferences(3775, 'c') / 100 -- TODO: 不同步设置就GG了 要通过实时数值反向计算 缺少API
end

function X.GetFontScale(nOffset)
	return 1 + (nOffset or Font.GetOffset()) * 0.07
end

do
local CURRENT_ACCOUNT
function X.GetAccount()
	if X.IsNil(CURRENT_ACCOUNT) then
		if not CURRENT_ACCOUNT and Login_GetAccount then
			local bSuccess, szAccount = X.XpCall(Login_GetAccount)
			if bSuccess and not X.IsEmpty(szAccount) then
				CURRENT_ACCOUNT = szAccount
			end
		end
		if not CURRENT_ACCOUNT and GetUserAccount then
			local bSuccess, szAccount = X.XpCall(GetUserAccount)
			if bSuccess and not X.IsEmpty(szAccount) then
				CURRENT_ACCOUNT = szAccount
			end
		end
		if not CURRENT_ACCOUNT then
			local bSuccess, hFrame = X.XpCall(function() return X.UI.OpenFrame('LoginPassword') end)
			if bSuccess and hFrame then
				local hEdit = hFrame:Lookup('WndPassword/Edit_Account')
				if hEdit then
					CURRENT_ACCOUNT = hEdit:GetText()
				end
				X.UI.CloseFrame(hFrame)
			end
		end
		if not CURRENT_ACCOUNT then
			CURRENT_ACCOUNT = false
		end
	end
	return CURRENT_ACCOUNT or nil
end
end

-- X.OpenBrowser(szAddr, 'auto')
-- X.OpenBrowser(szAddr, 'outer')
-- X.OpenBrowser(szAddr, 'inner')
function X.OpenBrowser(szAddr, szMode)
	if not szMode then
		szMode = 'auto'
	end
	if szMode == 'auto' or szMode == 'outer' then
		local OpenBrowser = X.GetGameAPI('OpenBrowser')
		if OpenBrowser then
			OpenBrowser(szAddr)
			return
		end
		if szMode == 'outer' then
			X.UI.OpenTextEditor(szAddr)
			return
		end
	end
	X.UI.OpenBrowser(szAddr)
end

-- Global exports
do
local PRESETS = {
	UIEvent = {
		'OnActivePage',
		'OnBeforeNavigate',
		'OnCheckBoxCheck',
		'OnCheckBoxDrag',
		'OnCheckBoxDragBegin',
		'OnCheckBoxDragEnd',
		'OnCheckBoxUncheck',
		'OnDocumentComplete',
		'OnDragButton',
		'OnDragButtonBegin',
		'OnDragButtonEnd',
		'OnEditChanged',
		'OnEditSpecialKeyDown',
		'OnEvent',
		'OnFrameBreathe',
		'OnFrameCreate',
		'OnFrameDestroy',
		'OnFrameDrag',
		'OnFrameDragEnd',
		'OnFrameDragSetPosEnd',
		'OnFrameFadeIn',
		'OnFrameFadeOut',
		'OnFrameHide',
		'OnFrameKeyDown',
		'OnFrameKeyUp',
		'OnFrameKillFocus',
		'OnFrameRender',
		'OnFrameSetFocus',
		'OnFrameShow',
		'OnHistoryChanged',
		'OnIgnoreKeyDown',
		'OnItemDrag',
		'OnItemDragEnd',
		'OnItemKeyDown',
		'OnItemKeyUp',
		'OnItemLButtonClick',
		'OnItemLButtonDBClick',
		'OnItemLButtonDown',
		'OnItemLButtonDrag',
		'OnItemLButtonDragEnd',
		'OnItemLButtonUp',
		'OnItemLongPressGesture',
		'OnItemMButtonClick',
		'OnItemMButtonDBClick',
		'OnItemMButtonDown',
		'OnItemMButtonDrag',
		'OnItemMButtonDragEnd',
		'OnItemMButtonUp',
		'OnItemMouseEnter',
		'OnItemMouseHover',
		'OnItemMouseIn',
		'OnItemMouseIn',
		'OnItemMouseLeave',
		'OnItemMouseMove',
		'OnItemMouseOut',
		'OnItemMouseOut',
		'OnItemMouseWheel',
		'OnItemPanGesture',
		'OnItemRButtonClick',
		'OnItemRButtonDBClick',
		'OnItemRButtonDown',
		'OnItemRButtonDrag',
		'OnItemRButtonDragEnd',
		'OnItemRButtonUp',
		'OnItemRefreshTip',
		'OnItemResize',
		'OnItemResizeEnd',
		'OnItemUpdateSize',
		'OnKillFocus',
		'OnLButtonClick',
		'OnLButtonDBClick',
		'OnLButtonDown',
		'OnLButtonHold',
		'OnLButtonRBClick',
		'OnLButtonUp',
		'OnLongPressRecognizer',
		'OnMButtonClick',
		'OnMButtonDBClick',
		'OnMButtonDown',
		'OnMButtonHold',
		'OnMButtonUp',
		'OnMinimapMouseEnterObj',
		'OnMinimapMouseEnterSelf',
		'OnMinimapMouseLeaveObj',
		'OnMinimapMouseLeaveSelf',
		'OnMinimapSendInfo',
		'OnMouseEnter',
		'OnMouseHover',
		'OnMouseIn',
		'OnMouseLeave',
		'OnMouseOut',
		'OnMouseWheel',
		'OnPanRecognizer',
		'OnPinchRecognizer',
		'OnRButtonClick',
		'OnRButtonDown',
		'OnRButtonHold',
		'OnRButtonUp',
		'OnRefreshTip',
		'OnSceneLButtonDown',
		'OnSceneLButtonUp',
		'OnSceneRButtonDown',
		'OnSceneRButtonUp',
		'OnScrollBarPosChanged',
		'OnSetFocus',
		'OnTapRecognizer',
		'OnTitleChanged',
		'OnWebLoadEnd',
		'OnWebPageClose',
		'OnWndDrag',
		'OnWndDragEnd',
		'OnWndDragSetPosEnd',
		'OnWndKeyDown',
		'OnWndResize',
		'OnWndResizeEnd',
	},
}
local function FormatModuleProxy(options, name)
	local entries = {} -- entries
	local interceptors = {} -- before trigger, return anything if want to intercept
	local triggers = {} -- aftet trigger, will not be called while intercepted by interceptors
	if options then
		local statics = {} -- static root
		for _, option in ipairs(options) do
			if option.root then
				local presets = option.presets or {} -- presets = {"XXX"},
				if option.preset then -- preset = "XXX",
					table.insert(presets, option.preset)
				end
				for i, s in ipairs(presets) do
					if PRESETS[s] then
						for _, k in ipairs(PRESETS[s]) do
							entries[k] = option.root
						end
					end
				end
			end
			if X.IsTable(option.fields) then
				for k, v in pairs(option.fields) do
					if X.IsNumber(k) and X.IsString(v) then -- "XXX",
						if not X.IsTable(option.root) then
							assert(false, 'Module `' .. name .. '`: static field `' .. v .. '` must be declared with a table root.')
						end
						entries[v] = option.root
					elseif X.IsString(k) then -- XXX = D.XXX,
						statics[k] = v
						entries[k] = statics
					end
				end
			end
			if X.IsTable(option.interceptors) then
				for k, v in pairs(option.interceptors) do
					if X.IsString(k) and X.IsFunction(v) then -- XXX = function(k) end,
						interceptors[k] = v
					end
				end
			end
			if X.IsTable(option.triggers) then
				for k, v in pairs(option.triggers) do
					if X.IsString(k) and X.IsFunction(v) then -- XXX = function(k, v) end,
						triggers[k] = v
					end
				end
			end
		end
	end
	return entries, interceptors, triggers
end
local function ParameterCounter(...)
	return select('#', ...), ...
end
function X.CreateModule(options)
	local name = options.name or 'Unnamed'
	local exportEntries, exportInterceptors, exportTriggers = FormatModuleProxy(options.exports, name)
	local importEntries, importInterceptors, importTriggers = FormatModuleProxy(options.imports, name)
	local function getter(_, k)
		local v = nil
		local interceptor, hasInterceptor = exportInterceptors[k] or exportInterceptors['*'], false
		if interceptor then
			local pc, value = ParameterCounter(interceptor(k))
			if pc >= 1 then
				v = value
				hasInterceptor = true
			end
		end
		if not hasInterceptor then
			local root = exportEntries[k]
			if not root then
				--[[#DEBUG BEGIN]]
				X.Debug(X.PACKET_INFO.NAME_SPACE, 'Module `' .. name .. '`: get value failed, unregistered property `' .. k .. '`.', X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				return
			end
			if root then
				v = root[k]
			end
		end
		local trigger = exportTriggers[k]
		if trigger then
			trigger(k, v)
		end
		return v
	end
	local function setter(_, k, v)
		local interceptor, hasInterceptor = importInterceptors[k] or importInterceptors['*'], false
		if interceptor then
			local pc, res, value = ParameterCounter(pcall(interceptor, k, v))
			if not res then
				return
			end
			if pc >= 2 then
				v = value
				hasInterceptor = true
			end
		end
		local root = importEntries[k]
		if not root and not hasInterceptor then
			--[[#DEBUG BEGIN]]
			assert(false, 'Module `' .. name .. '`: set value failed, unregistered property `' .. k .. '`.')
			--[[#DEBUG END]]
			return
		end
		if root then
			root[k] = v
		end
		local trigger = importTriggers[k]
		if trigger then
			trigger(k, v)
		end
	end
	return setmetatable({}, { __index = getter, __newindex = setter, __metatable = true })
end
end

function X.EditBox_AppendLinkPlayer(szName)
	local edit = X.GetChatInput()
	edit:InsertObj('['.. szName ..']', { type = 'name', text = '['.. szName ..']', name = szName })
	Station.SetFocusWindow(edit)
	return true
end

function X.EditBox_AppendLinkItem(dwID)
	local item = GetItem(dwID)
	if not item then
		return false
	end
	local szName = '[' .. X.GetItemNameByItem(item) ..']'
	local edit = X.GetChatInput()
	edit:InsertObj(szName, { type = 'item', text = szName, item = item.dwID })
	Station.SetFocusWindow(edit)
	return true
end

-------------------------------------------
-- 语音相关 API
-------------------------------------------

function X.GVoiceBase_IsOpen(...)
	if X.IsFunction(_G.GVoiceBase_IsOpen) then
		return _G.GVoiceBase_IsOpen(...)
	end
	return false
end

function X.GVoiceBase_GetMicState(...)
	if X.IsFunction(_G.GVoiceBase_GetMicState) then
		return _G.GVoiceBase_GetMicState(...)
	end
	return X.CONSTANT.MIC_STATE.CLOSE_NOT_IN_ROOM
end

function X.GVoiceBase_SwitchMicState(...)
	if X.IsFunction(_G.GVoiceBase_SwitchMicState) then
		return _G.GVoiceBase_SwitchMicState(...)
	end
end

function X.GVoiceBase_CheckMicState(...)
	if X.IsFunction(_G.GVoiceBase_CheckMicState) then
		return _G.GVoiceBase_CheckMicState(...)
	end
end

function X.GVoiceBase_GetSpeakerState(...)
	if X.IsFunction(_G.GVoiceBase_GetSpeakerState) then
		return _G.GVoiceBase_GetSpeakerState(...)
	end
	return X.CONSTANT.SPEAKER_STATE.CLOSE
end

function X.GVoiceBase_SwitchSpeakerState(...)
	if X.IsFunction(_G.GVoiceBase_SwitchSpeakerState) then
		return _G.GVoiceBase_SwitchSpeakerState(...)
	end
end

function X.GVoiceBase_GetSaying(...)
	if X.IsFunction(_G.GVoiceBase_GetSaying) then
		return _G.GVoiceBase_GetSaying(...)
	end
	return {}
end

function X.GVoiceBase_IsMemberSaying(...)
	if X.IsFunction(_G.GVoiceBase_IsMemberSaying) then
		return _G.GVoiceBase_IsMemberSaying(...)
	end
	return false
end

function X.GVoiceBase_IsMemberForbid(...)
	if X.IsFunction(_G.GVoiceBase_IsMemberForbid) then
		return _G.GVoiceBase_IsMemberForbid(...)
	end
	return false
end

function X.GVoiceBase_ForbidMember(...)
	if X.IsFunction(_G.GVoiceBase_ForbidMember) then
		return _G.GVoiceBase_ForbidMember(...)
	end
end

if _G.Login_GetTimeOfFee then
	function X.GetTimeOfFee()
		-- [仅客户端使用]返回帐号月卡截止时间，计点剩余秒数，计天剩余秒数和总截止时间
		local dwMonthEndTime, nPointLeftTime, nDayLeftTime, dwEndTime = _G.Login_GetTimeOfFee()
		if dwMonthEndTime <= 1229904000 then
			dwMonthEndTime = 0
		end
		return dwEndTime, dwMonthEndTime, nPointLeftTime, nDayLeftTime
	end
else
	local bInit, dwMonthEndTime, dwPointEndTime, dwDayEndTime = false, 0, 0, 0
	local frame = Station.Lookup('Lowest/Scene')
	local data = frame and frame[X.NSFormatString('{$NS}_TimeOfFee')]
	if data then
		bInit, dwMonthEndTime, dwPointEndTime, dwDayEndTime = true, X.Unpack(data)
	else
		X.RegisterMsgMonitor('MSG_SYS', 'LIB#GetTimeOfFee', function(szChannel, szMsg)
			-- 点卡剩余时间为：558小时41分33秒
			local szHour, szMinute, szSecond = szMsg:match(_L['Point left time: (%d+)h(%d+)m(%d+)s'])
			if szHour and szMinute and szSecond then
				local dwTime = GetCurrentTime()
				bInit = true
				dwPointEndTime = dwTime + tonumber(szHour) * 3600 + tonumber(szMinute) * 60 + tonumber(szSecond)
			end
			-- 您的月卡剩余总时间：49天19小时
			local szDay, szHour = szMsg:match(_L['Month time left days: (%d+)d(%d+)h'])
			if szDay and szHour then
				local dwTime = GetCurrentTime()
				bInit = true
				dwPointEndTime = dwTime + tonumber(szDay) * 3600 * 24 + tonumber(szHour) * 3600
			end
			-- 包月时间截止至：xxxx/xx/xx xx:xx
			local szYear, szMonth, szDay, szHour, szMinute = szMsg:match(_L['Month time to: (%d+)y(%d+)m(%d+)d (%d+)h(%d+)m'])
			if szYear and szMonth and szDay and szHour and szMinute then
				bInit = true
				dwMonthEndTime = X.DateToTime(szYear, szMonth, szDay, szHour, szMinute, 0)
			end
			if bInit then
				local dwTime = GetCurrentTime()
				if dwMonthEndTime > dwTime then -- 优先消耗月卡 即点卡结束时间需要加上月卡时间
					dwPointEndTime = dwPointEndTime + dwMonthEndTime - dwTime
				end
				local frame = Station.Lookup('Lowest/Scene')
				if frame then
					frame[X.NSFormatString('{$NS}_TimeOfFee')] = X.Pack(dwMonthEndTime, dwPointEndTime, dwDayEndTime)
				end
				X.RegisterMsgMonitor('MSG_SYS', 'LIB#GetTimeOfFee', false)
			end
		end)
	end
	function X.GetTimeOfFee()
		local dwTime = GetCurrentTime()
		local dwEndTime = math.max(dwMonthEndTime, dwPointEndTime, dwDayEndTime)
		return dwEndTime, dwMonthEndTime, math.max(dwPointEndTime - dwTime, 0), math.max(dwDayEndTime - dwTime, 0)
	end
end

do
local FILE_PATH = {'temporary/lua_error.jx3dat', X.PATH_TYPE.GLOBAL}
local LAST_ERROR_MSG = X.LoadLUAData(FILE_PATH, { passphrase = false }) or {}
local ERROR_MSG = {}

if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
	local KEY = '/' .. X.StringReplaceW(X.PACKET_INFO.ROOT, '\\', '/'):gsub('/+$', ''):gsub('^.*/', ''):lower() .. '/'
	local function SaveErrorMessage()
		X.SaveLUAData(FILE_PATH, ERROR_MSG, { passphrase = false, crc = false, indent = '\t' })
	end
	local BROKEN_KGUI = IsDebugClient() and not X.IsDebugServer() and not X.IsDebugClient(true)
	local BROKEN_KGUI_ECHO = false
	RegisterEvent('CALL_LUA_ERROR', function()
		if BROKEN_KGUI_ECHO then
			return
		end
		local szMsg = arg0
		local szMsgL = X.StringReplaceW(arg0:lower(), '\\', '/')
		if X.StringFindW(szMsgL, KEY) then
			if BROKEN_KGUI then
				local szMessage = 'Your KGUI is not official, please fix client and try again.'
				BROKEN_KGUI_ECHO = true
				X.SafeCall(X.ErrorLog, '[' .. X.PACKET_INFO.NAME_SPACE .. ']' .. szMessage .. '\n' .. _L[szMessage])
				BROKEN_KGUI_ECHO = false
			end
			X.Log('CALL_LUA_ERROR', szMsg)
			table.insert(ERROR_MSG, szMsg)
		end
		SaveErrorMessage()
	end)
	X.RegisterInit('LIB#AddonErrorMessage', SaveErrorMessage)
end

function X.GetAddonErrorMessage()
	local szMsg = table.concat(LAST_ERROR_MSG, '\n\n')
	if not X.IsEmpty(szMsg) then
		szMsg = szMsg .. '\n\n'
	end
	return szMsg .. table.concat(ERROR_MSG, '\n\n')
end

function X.GetAddonErrorMessageFilePath()
	return X.FormatPath(FILE_PATH)
end
end

-----------------------------------------------
-- 事件驱动自动回收的缓存机制
-----------------------------------------------
function X.CreateCache(szNameMode, aEvent)
	-- 处理参数
	local szName, szMode
	if X.IsString(szNameMode) then
		local nPos = X.StringFindW(szNameMode, '.')
		if nPos then
			szName = string.sub(szNameMode, 1, nPos - 1)
			szMode = string.sub(szNameMode, nPos + 1)
		else
			szName = szNameMode
		end
	end
	if X.IsString(aEvent) then
		aEvent = {aEvent}
	elseif X.IsArray(aEvent) then
		aEvent = X.Clone(aEvent)
	else
		aEvent = {'LOADING_ENDING'}
	end
	local szKey = 'LIB#CACHE#' .. tostring(aEvent):sub(8)
	if szName then
		szKey = szKey .. '#' .. szName
	end
	-- 创建弱表以及事件驱动
	local t = {}
	local mt = { __mode = szMode }
	local function Flush()
		for k, _ in pairs(t) do
			t[k] = nil
		end
	end
	local function Register()
		for _, szEvent in ipairs(aEvent) do
			X.RegisterEvent(szEvent, szKey, Flush)
		end
	end
	local function Unregister()
		for _, szEvent in ipairs(aEvent) do
			X.RegisterEvent(szEvent, szKey, false)
		end
	end
	function mt.__call(_, k)
		if k == 'flush' then
			Flush()
		elseif k == 'register' then
			Register()
		elseif k == 'unregister' then
			Unregister()
		end
	end
	Register()
	return setmetatable(t, mt)
end

-----------------------------------------------
-- 汉字转拼音
-----------------------------------------------
do local PINYIN, PINYIN_CONSONANT
function X.Han2Pinyin(szText)
	if not X.IsString(szText) then
		return
	end
	if not PINYIN then
		PINYIN = X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/pinyin/{$lang}.jx3dat', { passphrase = false })
		local tPinyinConsonant = {}
		for c, v in pairs(PINYIN) do
			local a, t = {}, {}
			for _, s in ipairs(v) do
				s = s:sub(1, 1)
				if not t[s] then
					t[s] = true
					table.insert(a, s)
				end
			end
			tPinyinConsonant[c] = a
		end
		PINYIN_CONSONANT = tPinyinConsonant
	end
	local aText = X.SplitString(szText, '')
	local aFull, nFullCount = {''}, 1
	local aConsonant, nConsonantCount = {''}, 1
	for _, szChar in ipairs(aText) do
		local aCharPinyin = PINYIN[szChar]
		if aCharPinyin and #aCharPinyin > 0 then
			for i = 2, #aCharPinyin do
				for j = 1, nFullCount do
					table.insert(aFull, aFull[j] .. aCharPinyin[i])
				end
			end
			for j = 1, nFullCount do
				aFull[j] = aFull[j] .. aCharPinyin[1]
			end
			nFullCount = nFullCount * #aCharPinyin
		else
			for j = 1, nFullCount do
				aFull[j] = aFull[j] .. szChar
			end
		end
		local aCharPinyinConsonant = PINYIN_CONSONANT[szChar]
		if aCharPinyinConsonant and #aCharPinyinConsonant > 0 then
			for i = 2, #aCharPinyinConsonant do
				for j = 1, nConsonantCount do
					table.insert(aConsonant, aConsonant[j] .. aCharPinyinConsonant[i])
				end
			end
			for j = 1, nConsonantCount do
				aConsonant[j] = aConsonant[j] .. aCharPinyinConsonant[1]
			end
			nConsonantCount = nConsonantCount * #aCharPinyinConsonant
		else
			for j = 1, nConsonantCount do
				aConsonant[j] = aConsonant[j] .. szChar
			end
		end
	end
	return aFull, aConsonant
end
end

function X.IsMobileClient(nClientVersionType)
	return nClientVersionType == X.CONSTANT.CLIENT_VERSION_TYPE.MOBILE_ANDROID
		or nClientVersionType == X.CONSTANT.CLIENT_VERSION_TYPE.MOBILE_IOS
		or nClientVersionType == X.CONSTANT.CLIENT_VERSION_TYPE.MOBILE_PC
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
