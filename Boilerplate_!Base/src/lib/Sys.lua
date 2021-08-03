--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local LIB = Boilerplate
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
---------------------------------------------------------------------------------------------------

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
-- (void) LIB.RegisterHotKey(string szName, string szTitle, func fnDown, func fnUp)   -- 增加系统快捷键
function LIB.RegisterHotKey(szName, szTitle, fnDown, fnUp)
	insert(HOTKEY_CACHE, { szName = szName, szTitle = szTitle, fnDown = fnDown, fnUp = fnUp })
end

-- 获取快捷键名称
-- (string) LIB.GetHotKeyDisplay(string szName, boolean bBracket, boolean bShort)      -- 取得快捷键名称
function LIB.GetHotKeyDisplay(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szDisplay = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szDisplay ~= '' and bBracket then
		szDisplay = '(' .. szDisplay .. ')'
	end
	return szDisplay
end

-- 获取快捷键
-- (table) LIB.GetHotKey(string szName, true , true )       -- 取得快捷键
-- (number nKey, boolean bShift, boolean bCtrl, boolean bAlt) LIB.GetHotKey(string szName, true , fasle)        -- 取得快捷键
function LIB.GetHotKey(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	if nKey==0 then return nil end
	if bBracket then
		return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
	else
		return nKey, bShift, bCtrl, bAlt
	end
end

-- 设置快捷键/打开快捷键设置面板    -- HM里面抠出来的
-- (void) LIB.SetHotKey()                               -- 打开快捷键设置面板
-- (void) LIB.SetHotKey(string szGroup)     -- 打开快捷键设置面板并定位到 szGroup 分组（不可用）
-- (void) LIB.SetHotKey(string szCommand, number nKey )     -- 设置快捷键
-- (void) LIB.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- 设置快捷键
function LIB.SetHotKey(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
	if nIndex then
		if not nKey then
			nIndex, nKey = 1, nIndex
		end
		Hotkey.Set(szCommand, nIndex, nKey, bShift == true, bCtrl == true, bAlt == true)
	else
		local szGroup = szCommand or PACKET_INFO.NAME

		local frame = Station.Lookup('Topmost/HotkeyPanel')
		if not frame then
			frame = Wnd.OpenWindow('HotkeyPanel')
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
				insert(aKey, v)
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
		local nCountStep = ceil((hAll - h) / 10)
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
			local nStep = ceil((nI * nH) / 10)
			if nStep > scroll:GetStepCount() then
				nStep = scroll:GetStepCount()
			end
			scroll:SetScrollPos(nStep)
		end
	end
end

LIB.RegisterInit(NSFormatString('{$NS}#BIND_HOTKEY'), function()
	-- hotkey
	Hotkey.AddBinding(NSFormatString('{$NS}_Total'), _L['Toggle main panel'], PACKET_INFO.NAME, LIB.TogglePanel, nil)
	for _, v in ipairs(HOTKEY_CACHE) do
		Hotkey.AddBinding(v.szName, v.szTitle, '', v.fnDown, v.fnUp)
	end
	for i = 1, 5 do
		Hotkey.AddBinding(NSFormatString('{$NS}_HotKey_Null_')..i, _L['None-function hotkey'], '', function() end, nil)
	end
end)
if PACKET_INFO.DEBUG_LEVEL <= DEBUG_LEVEL.DEBUG then
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
		'Normal/' .. PACKET_INFO.NAME_SPACE,
	}
	LIB.RegisterHotKey(NSFormatString('{$NS}_STAGE_CHAT'), _L['Display only chat panel'], function()
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
LIB.RegisterHotKey(NSFormatString('{$NS}_STOP_CASTING'), _L['Stop cast skill'], function() GetClientPlayer().StopCurrentAction() end)
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
			data = Clone(data, true)
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
			data = Clone(defaultData, true)
		end
	end
	return data
end
LIB.FormatDataStructure = FormatDataStructure
end

function LIB.SetGlobalValue(szVarPath, Val)
	local t = LIB.SplitString(szVarPath, '.')
	local tab = _G
	for k, v in ipairs(t) do
		if not IsTable(tab) then
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

function LIB.GetGlobalValue(szVarPath)
	local tVariable = _G
	for szIndex in gmatch(szVarPath, '[^%.]+') do
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
local SOUND_ROOT = PACKET_INFO.FRAMEWORK_ROOT .. 'audio/'
local SOUNDS = {
	{
		szType = _L['Default'],
		{ dwID = 1, szName = _L['Bing.ogg'], szPath = SOUND_ROOT .. 'Bing.ogg' },
		{ dwID = 88001, szName = _L['Notify.ogg'], szPath = SOUND_ROOT .. 'Notify.ogg' },
	},
}
local CACHE = nil
local function GetSoundList()
	local a = { szOption = _L['Sound'] }
	for _, v in ipairs(SOUNDS) do
		insert(a, v)
	end
	local RE = _G[NSFormatString('{$NS}_Resource')]
	if IsTable(RE) and IsFunction(RE.GetSoundList) then
		for _, v in ipairs(RE.GetSoundList()) do
			insert(a, v)
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
				LIB.PlaySound(SOUND.UI_SOUND, tSound.szPath, '')
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
			insert(t, t1)
		end
	end
	if t.dwID and not IsLocalFileExist(t.szPath) then
		return
	end
	return t
end

function LIB.GetSoundMenu(fnAction, tCheck, bMultiple)
	local function fnMenuAction(tSound, bCheck)
		fnAction(tSound.dwID, bCheck)
	end
	return GetSoundMenu(GetSoundList(), fnMenuAction, tCheck, bMultiple)
end

local function Cache(tSound)
	if not IsTable(tSound) then
		return
	end
	if tSound.dwID then
		CACHE[tSound.dwID] = {
			dwID = tSound.dwID,
			szName = tSound.szName,
			szPath = tSound.szPath,
		}
	end
	for _, t in ipairs(tSound) do
		Cache(t)
	end
end

local function GeneCache()
	if not CACHE then
		CACHE = {}
		local RE = _G[NSFormatString('{$NS}_Resource')]
		if IsTable(RE) and IsFunction(RE.GetSoundList) then
			local tSound = RE.GetSoundList()
			if tSound then
				Cache(tSound)
			end
		end
		Cache(SOUNDS)
	end
	return true
end

function LIB.GetSoundName(dwID)
	if not GeneCache() then
		return
	end
	local tSound = CACHE[dwID]
	if not tSound then
		return
	end
	return tSound.szName
end

function LIB.GetSoundPath(dwID)
	if not GeneCache() then
		return
	end
	local tSound = CACHE[dwID]
	if not tSound then
		return
	end
	return tSound.szPath
end
end

-- 播放声音
-- LIB.PlaySound([nType, ]szFilePath[, szCustomPath])
--   nType        声音类型
--     SOUND.BG_MUSIC = 0,    // 背景音乐
--     SOUND.UI_SOUND,        // 界面音效    -- 默认值
--     SOUND.UI_ERROR_SOUND,  // 错误提示音
--     SOUND.SCENE_SOUND,     // 环境音效
--     SOUND.CHARACTER_SOUND, // 角色音效,包括打击，特效的音效
--     SOUND.CHARACTER_SPEAK, // 角色对话
--     SOUND.FRESHER_TIP,     // 新手提示音
--     SOUND.SYSTEM_TIP,      // 系统提示音
--     SOUND.TREATYANI_SOUND, // 协议动画声音
--   szFilePath   音频文件地址
--   szCustomPath 个性化音频文件地址
-- 注：优先播放szCustomPath, szCustomPath不存在才会播放szFilePath
function LIB.PlaySound(nType, szFilePath, szCustomPath)
	if not IsNumber(nType) then
		nType, szFilePath, szCustomPath = SOUND.UI_SOUND, nType, szFilePath
	end
	if not szCustomPath then
		szCustomPath = szFilePath
	end
	-- 播放自定义声音
	if szCustomPath ~= '' then
		for _, ePathType in ipairs({
			PATH_TYPE.ROLE,
			PATH_TYPE.GLOBAL,
		}) do
			local szPath = LIB.FormatPath({ 'audio/' .. szCustomPath, ePathType })
			if IsFileExist(szPath) then
				return PlaySound(nType, szPath)
			end
		end
	end
	-- 播放默认声音
	local szPath = wgsub(szFilePath, '\\', '/')
	if not wfind(szPath, '/') then
		szPath = PACKET_INFO.FRAMEWORK_ROOT .. 'audio/' .. szPath
	end
	if not IsFileExist(szPath) then
		return
	end
	PlaySound(nType, szPath)
end

function LIB.GetFontList()
	local aList, tExist = {}, {}
	-- 插件字体包
	local FR = _G[NSFormatString('{$NS}_FontResource')]
	if IsTable(FR) and IsFunction(FR.GetList) then
		for _, p in ipairs(FR.GetList()) do
			local szFile = p.szFile:gsub('/', '\\')
			local szKey = szFile:lower()
			if not tExist[szKey] then
				insert(aList, {
					szName = p.szName,
					szFile = p.szFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 系统字体
	for _, p in ipairs_r(Font.GetFontPathList() or {}) do
		local szFile = p.szFile:gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			insert(aList, 1, {
				szName = p.szName,
				szFile = szFile,
			})
			tExist[szKey] = true
		end
	end
	-- 按照描述文件添加字体
	local CUSTOM_FONT_DIR = LIB.FormatPath({'font/', PATH_TYPE.GLOBAL})
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_FONT_DIR)) do
		local info = szFile:lower():find('%.jx3dat$') and LIB.LoadLUAData(CUSTOM_FONT_DIR .. szFile, { passphrase = false })
		if info and info.szName and info.szFile then
			local szFontFile = info.szFile:gsub('^%./', CUSTOM_FONT_DIR):gsub('/', '\\')
			local szKey = szFontFile:lower()
			if not tExist[szKey] then
				insert(aList, {
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
				insert(aList, {
					szName = szFile,
					szFile = szFontFile,
				})
				tExist[szKey] = true
			end
		end
	end
	-- 删除不存在的字体
	for i, p in ipairs_r(aList) do
		if not IsFileExist(p.szFile) then
			remove(aList, i)
		end
	end
	return aList
end

-- 加载注册数据
LIB.RegisterInit(NSFormatString('{$NS}#INITDATA'), function()
	local t = LoadLUAData(LIB.GetLUADataPath({'config/initial.jx3dat', PATH_TYPE.GLOBAL}))
	if t then
		for v_name, v_data in pairs(t) do
			LIB.SetGlobalValue(v_name, v_data)
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
	if IsString(arg0) then
		szKey = arg0
		if IsTable(arg1) or IsFunction(arg1) then
			oMenu = arg1
		end
	elseif IsTable(arg0) or IsFunction(arg0) then
		oMenu = arg0
	end
	if szKey then
		for i, v in ipairs_r(aList) do
			if v.szKey == szKey then
				remove(aList, i)
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
		insert(aList, { szKey = szKey, oMenu = oMenu })
	end
	return szKey
end

local function GenerateMenu(aList, bMainMenu, dwTarType, dwTarID)
	if not LIB.AssertVersion('', '', '*') then
		return
	end
	local menu = {}
	if bMainMenu then
		menu = {
			szOption = PACKET_INFO.NAME,
			fnAction = LIB.TogglePanel,
			rgb = PACKET_INFO.MENU_COLOR,
			bCheck = true,
			bChecked = LIB.IsPanelVisible(),

			szIcon = PACKET_INFO.LOGO_UITEX,
			nFrame = PACKET_INFO.LOGO_MENU_FRAME,
			nMouseOverFrame = PACKET_INFO.LOGO_MENU_HOVER_FRAME,
			szLayer = 'ICON_RIGHT',
			fnClickIcon = LIB.TogglePanel,
		}
	end
	for _, p in ipairs(aList) do
		local m = p.oMenu
		if IsFunction(m) then
			m = m(dwTarType, dwTarID)
		end
		if not m or m.szOption then
			m = {m}
		end
		for _, v in ipairs(m) do
			if not v.rgb and not bMainMenu then
				v.rgb = PACKET_INFO.MENU_COLOR
			end
			insert(menu, v)
		end
	end
	sort(menu, menuSorter)
	return bMainMenu and {menu} or menu
end

do
local PLAYER_MENU, PLAYER_MENU_HASH = {}, {} -- 玩家头像菜单
-- 注册玩家头像菜单
-- 注册
-- (void) LIB.RegisterPlayerAddonMenu(Menu)
-- (void) LIB.RegisterPlayerAddonMenu(szName, tMenu)
-- (void) LIB.RegisterPlayerAddonMenu(szName, fnMenu)
-- 注销
-- (void) LIB.RegisterPlayerAddonMenu(szName, false)
function LIB.RegisterPlayerAddonMenu(arg0, arg1)
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
-- (void) LIB.RegisterTraceButtonAddonMenu(Menu)
-- (void) LIB.RegisterTraceButtonAddonMenu(szName, tMenu)
-- (void) LIB.RegisterTraceButtonAddonMenu(szName, fnMenu)
-- 注销
-- (void) LIB.RegisterTraceButtonAddonMenu(szName, false)
function LIB.RegisterTraceButtonAddonMenu(arg0, arg1)
	return RegisterMenu(TRACE_MENU, TRACE_MENU_HASH, arg0, arg1)
end
function LIB.GetTraceButtonAddonMenu(dwTarID, dwTarType)
	return GenerateMenu(TRACE_MENU, true, dwTarType, dwTarID)
end
TraceButton_AppendAddonMenu({LIB.GetTraceButtonAddonMenu})
end

do
local TARGET_MENU, TARGET_MENU_HASH = {}, {} -- 目标头像菜单
-- 注册目标头像菜单
-- 注册
-- (void) LIB.RegisterTargetAddonMenu(Menu)
-- (void) LIB.RegisterTargetAddonMenu(szName, tMenu)
-- (void) LIB.RegisterTargetAddonMenu(szName, fnMenu)
-- 注销
-- (void) LIB.RegisterTargetAddonMenu(szName, false)
function LIB.RegisterTargetAddonMenu(arg0, arg1)
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
-- (void) LIB.RegisterAddonMenu(Menu)
-- (void) LIB.RegisterAddonMenu(szName, tMenu)
-- (void) LIB.RegisterAddonMenu(szName, fnMenu)
-- 注销
-- (void) LIB.RegisterAddonMenu(szName, false)
function LIB.RegisterAddonMenu(...)
	LIB.RegisterPlayerAddonMenu(...)
	LIB.RegisterTraceButtonAddonMenu(...)
end

-- 格式化计时时间
-- (string) LIB.FormatTimeCounter(nTime, szFormat, nStyle)
-- szFormat  格式化字符串 可选项：
--   %Y 总年数
--   %D 总天数
--   %H 总小时
--   %M 总分钟
--   %S 总秒数
--   %d 天数
--   %h 小时数
--   %m 分钟数
--   %s 秒钟数
--   %dd 天数两位对齐
--   %hh 小时数两位对齐
--   %mm 分钟数两位对齐
--   %ss 秒钟数两位对齐
function LIB.FormatTimeCounter(nTime, szFormat, nStyle)
	local nSeconds = floor(nTime)
	local nMinutes = floor(nSeconds / 60)
	local nHours   = floor(nMinutes / 60)
	local nDays    = floor(nHours / 24)
	local nYears   = floor(nDays / 365)
	local nDay     = nDays % 365
	local nHour    = nHours % 24
	local nMinute  = nMinutes % 60
	local nSecond  = nSeconds % 60
	if IsString(szFormat) then
		szFormat = wgsub(szFormat, '%Y', nYears)
		szFormat = wgsub(szFormat, '%D', nDays)
		szFormat = wgsub(szFormat, '%H', nHours)
		szFormat = wgsub(szFormat, '%M', nMinutes)
		szFormat = wgsub(szFormat, '%S', nSeconds)
		szFormat = wgsub(szFormat, '%dd', format('%02d', nDay   ))
		szFormat = wgsub(szFormat, '%hh', format('%02d', nHour  ))
		szFormat = wgsub(szFormat, '%mm', format('%02d', nMinute))
		szFormat = wgsub(szFormat, '%ss', format('%02d', nSecond))
		szFormat = wgsub(szFormat, '%d', nDay)
		szFormat = wgsub(szFormat, '%h', nHour)
		szFormat = wgsub(szFormat, '%m', nMinute)
		szFormat = wgsub(szFormat, '%s', nSecond)
		return szFormat
	end
	if szFormat == 1 then -- M'ss" / s"
		if nMinutes > 0 then
			return nMinutes .. '\'' .. format('%02d', nSecond) .. '"'
		end
		return nSeconds .. '"'
	end
	if szFormat == 2 or not szFormat then -- H:mm:ss / M:ss / s
		local y, d, h, m, s = 'y', 'd', 'h', 'm', 's'
		if nStyle == 2 then
			y, d, h, m, s = g_tStrings.STR_YEAR, g_tStrings.STR_BUFF_H_TIME_D_SHORT, g_tStrings.STR_TIME_HOUR, g_tStrings.STR_TIME_MINUTE, g_tStrings.STR_TIME_SECOND
		end
		if nYears > 0 then
			return nYears .. y .. format('%02d', nDay) .. d .. format('%02d', nHour) .. h .. format('%02d', nMinute)  .. m .. format('%02d', nSecond) .. s
		end
		if nDays > 0 then
			return nDays .. d .. format('%02d', nHour) .. h .. format('%02d', nMinute)  .. m .. format('%02d', nSecond) .. s
		end
		if nHours > 0 then
			return nHours .. h .. format('%02d', nMinute)  .. m .. format('%02d', nSecond) .. s
		end
		if nMinutes > 0 then
			return nMinutes .. m .. format('%02d', nSecond) .. s
		end
		return nSeconds .. s
	end
end

-- 格式化时间
-- (string) LIB.FormatTime(nTimestamp, szFormat)
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
function LIB.FormatTime(nTimestamp, szFormat)
	local t = TimeToDate(nTimestamp)
	szFormat = wgsub(szFormat, '%yyyy', format('%04d', t.year  ))
	szFormat = wgsub(szFormat, '%yy'  , format('%02d', t.year % 100))
	szFormat = wgsub(szFormat, '%MM'  , format('%02d', t.month ))
	szFormat = wgsub(szFormat, '%dd'  , format('%02d', t.day   ))
	szFormat = wgsub(szFormat, '%hh'  , format('%02d', t.hour  ))
	szFormat = wgsub(szFormat, '%mm'  , format('%02d', t.minute))
	szFormat = wgsub(szFormat, '%ss'  , format('%02d', t.second))
	szFormat = wgsub(szFormat, '%y', t.year  )
	szFormat = wgsub(szFormat, '%M', t.month )
	szFormat = wgsub(szFormat, '%d', t.day   )
	szFormat = wgsub(szFormat, '%h', t.hour  )
	szFormat = wgsub(szFormat, '%m', t.minute)
	szFormat = wgsub(szFormat, '%s', t.second)
	return szFormat
end

function LIB.DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
	return DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
end

function LIB.TimeToDate(nTimestamp)
	local date = TimeToDate(nTimestamp)
	return date.year, date.month, date.day, date.hour, date.minute, date.second
end

-- 格式化数字小数点
-- (string) LIB.FormatNumberDot(nValue, nDot, bDot, bSimple)
-- nValue  要格式化的数字
-- nDot    小数点位数
-- bDot    小数点不足补位0
-- bSimple 是否显示精简数值
function LIB.FormatNumberDot(nValue, nDot, bDot, bSimple)
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
	return floor(nValue * pow(2, nDot)) / pow(2, nDot) .. szUnit
end

-- register global esc key down action
-- (void) LIB.RegisterEsc(szID, fnCondition, fnAction, bTopmost) -- register global esc event handle
-- (void) LIB.RegisterEsc(szID, nil, nil, bTopmost)              -- unregister global esc event handle
-- (string)szID        -- an UUID (if this UUID has been register before, the old will be recovered)
-- (function)fnCondition -- a function returns if fnAction will be execute
-- (function)fnAction    -- inf fnCondition() is true then fnAction will be called
-- (boolean)bTopmost    -- this param equals true will be called in high priority
function LIB.RegisterEsc(szID, fnCondition, fnAction, bTopmost)
	if fnCondition and fnAction then
		if RegisterGlobalEsc then
			RegisterGlobalEsc(PACKET_INFO.NAME_SPACE .. '#' .. szID, fnCondition, fnAction, bTopmost)
		end
	else
		if UnRegisterGlobalEsc then
			UnRegisterGlobalEsc(PACKET_INFO.NAME_SPACE .. '#' .. szID, bTopmost)
		end
	end
end

-- 测试用
if loadstring then
function LIB.ProcessCommand(cmd)
	local ls = loadstring('return ' .. cmd)
	if ls then
		return ls()
	end
end
end

do
local bCustomMode = false
function LIB.IsInCustomUIMode()
	return bCustomMode
end
LIB.RegisterEvent('ON_ENTER_CUSTOM_UI_MODE', function() bCustomMode = true  end)
LIB.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE', function() bCustomMode = false end)
end

function LIB.DoMessageBox(szName, i)
	local frame = Station.Lookup('Topmost2/MB_' .. szName) or Station.Lookup('Topmost/MB_' .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup('Wnd_All/Btn_Option' .. i)
		if btn and btn:IsEnabled() then
			if btn.fnAction then
				if frame.args then
					btn.fnAction(unpack(frame.args))
				else
					btn.fnAction()
				end
			elseif frame.fnAction then
				if frame.args then
					frame.fnAction(i, unpack(frame.args))
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
					FireUIEvent(NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			if btn.fnCountDownEnd then
				HookTableFunc(btn, 'fnCountDownEnd', function()
					FireUIEvent(NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'TIME_OUT', szOption, nIndex)
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
		FireUIEvent(NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', msg.szOption, msg.nIndex)
	end, { bAfterOrigin = true })

	HookTableFunc(frame, 'fnCancelAction', function()
		FireUIEvent(NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'CANCEL')
	end, { bAfterOrigin = true })

	if frame.fnAutoClose then
		HookTableFunc(frame, 'fnAutoClose', function()
			FireUIEvent(NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'AUTO_CLOSE')
		end, { bAfterOrigin = true })
	end

	FireUIEvent(NSFormatString('{$NS}_MESSAGE_BOX_OPEN'), arg0, arg1)
end
LIB.RegisterEvent('ON_MESSAGE_BOX_OPEN', OnMessageBoxOpen)
end

-- 弹出对话框
-- LIB.MessageBox([szKey, ]tMsg)
-- LIB.MessageBox([szKey, ]tMsg)
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param tMsg {object} 更多参见官方 MessageBox 文档
-- 	@param tMsg.fnCancelAction {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function LIB.MessageBox(szKey, tMsg)
	if IsTable(szKey) then
		szKey, tMsg = nil, szKey
	end
	if not szKey then
		szKey = LIB.GetUUID():gsub('-', '')
	end
	tMsg.szName = NSFormatString('{$NS}_MessageBox#') .. GetStringCRC(szKey)
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
			LIB.DelayCall(function()
				LIB.MessageBox(szKey, tMsg)
			end)
		end
	end
	MessageBox(tMsg)
	return szKey
end

-- 弹出对话框 - 单按钮确认
-- LIB.Alert([szKey, ]szMsg[, fnResolve])
-- LIB.Alert([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.szResolve {string} 按钮文案
-- 	@param tOpt.fnResolve {function} 按钮回调
-- 	@param tOpt.nResolveCountDown {number} 确定按钮倒计时
-- 	@param tOpt.fnCancel {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function LIB.Alert(szKey, szMsg, fnResolve)
	if not IsString(szMsg) then
		szKey, szMsg, fnResolve = nil, szKey, szMsg
	end
	local tOpt = fnResolve
	if not IsTable(tOpt) then
		tOpt = { fnResolve = fnResolve }
	end
	return LIB.MessageBox(szKey, {
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
-- LIB.Confirm([szKey, ]szMsg[, fnResolve[, fnReject[, fnCancel]]])
-- LIB.Confirm([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.szResolve {string} 确定按钮文案
-- 	@param tOpt.fnResolve {function} 确定回调
-- 	@param tOpt.szReject {string} 取消按钮文案
-- 	@param tOpt.fnReject {function} 取消回调
-- 	@param tOpt.fnCancel {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function LIB.Confirm(szKey, szMsg, fnResolve, fnReject, fnCancel)
	if not IsString(szMsg) then
		szKey, szMsg, fnResolve, fnReject = nil, szKey, szMsg, fnResolve
	end
	local tOpt = fnResolve
	if not IsTable(tOpt) then
		tOpt = {
			fnResolve = fnResolve,
			fnReject = fnReject,
			fnCancel = fnCancel,
		}
	end
	return LIB.MessageBox(szKey, {
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		{ szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE, fnAction = tOpt.fnResolve },
		{ szOption = tOpt.szReject or g_tStrings.STR_HOTKEY_CANCEL, fnAction = tOpt.fnReject },
	})
end

-- 弹出对话框 - 自定义按钮
-- LIB.Dialog([szKey, ]szMsg[, aOptions[, fnCancelAction]])
-- LIB.Dialog([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.aOptions {array} 按钮列表，参见 MessageBox 用法
-- 	@param tOpt.fnCancelAction {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function LIB.Dialog(szKey, szMsg, aOptions, fnCancelAction)
	if not IsString(szMsg) then
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
		insert(tMsg, tOption)
	end
	return LIB.MessageBox(szKey, tMsg)
end

do
function LIB.Hex2RGB(hex)
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

function LIB.RGB2Hex(r, g, b, a)
	if a then
		return (('#%02X%02X%02X%02X'):format(r, g, b, a))
	end
	return (('#%02X%02X%02X'):format(r, g, b))
end

local COLOR_NAME_RGB = {}
do
	local aColor = LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/colors/{$lang}.jx3dat')
	for szColor, aKey in ipairs(aColor) do
		local nR, nG, nB = LIB.Hex2RGB(szColor)
		if nR then
			for _, szKey in ipairs(aKey) do
				COLOR_NAME_RGB[szKey] = {nR, nG, nB}
			end
		end
	end
end

function LIB.ColorName2RGB(name)
	if not COLOR_NAME_RGB[name] then
		return
	end
	return unpack(COLOR_NAME_RGB[name])
end

local HUMAN_COLOR_CACHE = setmetatable({}, {__mode = 'v', __index = COLOR_NAME_RGB})
function LIB.HumanColor2RGB(name)
	if IsTable(name) then
		if name.r then
			return name.r, name.g, name.b
		end
		return unpack(name)
	end
	if not HUMAN_COLOR_CACHE[name] then
		local r, g, b, a = LIB.Hex2RGB(name)
		HUMAN_COLOR_CACHE[name] = {r, g, b, a}
	end
	return unpack(HUMAN_COLOR_CACHE[name])
end
end

-- 获取某个字体的颜色
-- (bool) LIB.GetFontColor(number nFont)
do
local CACHE, el = {}, nil
function LIB.GetFontColor(nFont)
	if not CACHE[nFont] then
		if not el or not IsElement(el) then
			el = UI.GetTempElement(NSFormatString('Text.{$NS}Lib_GetFontColor'))
		end
		el:SetFontScheme(nFont)
		CACHE[nFont] = {el:GetFontColor()}
	end
	return unpack(CACHE[nFont])
end
end

function LIB.ExecuteWithThis(context, fnAction, ...)
	-- 界面组件支持字符串调用方法
	if IsString(fnAction) then
		if not IsElement(context) then
			-- Log('[UI ERROR]Invalid element on executing ui event!')
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
	if not IsFunction(fnAction) then
		-- Log('[UI ERROR]Invalid function on executing ui event! # ' .. element:GetTreePath())
		return false
	end
	local _this = this
	this = context
	local rets = {fnAction(...)}
	this = _this
	return true, unpack(rets)
end

do
local HOOK = setmetatable({}, { __mode = 'k' })
-- LIB.SetMemberFunctionHook(tTable, szName, fnHook, tOption) -- hook
-- LIB.SetMemberFunctionHook(tTable, szName, szKey, fnHook, tOption) -- hook
-- LIB.SetMemberFunctionHook(tTable, szName, szKey, false) -- unhook
function LIB.SetMemberFunctionHook(t, xArg1, xArg2, xArg3, xArg4)
	local eAction, szName, szKey, fnHook, tOption
	if IsTable(t) and IsFunction(xArg2) then
		eAction, szName, fnHook, tOption = 'REG', xArg1, xArg2, xArg3
	elseif IsTable(t) and IsString(xArg2) and IsFunction(xArg3) then
		eAction, szName, szKey, fnHook, tOption = 'REG', xArg1, xArg2, xArg3, xArg4
	elseif IsTable(t) and IsString(xArg2) and xArg3 == false then
		eAction, szName, szKey = 'UNREG', xArg1, xArg2
	end
	assert(eAction, 'Parameters type not recognized, cannot infer action type.')
	-- 匿名注册分配随机标识符
	if eAction == 'REG' and not IsString(szKey) then
		szKey = GetTickCount() * 1000
		while Get(HOOK, {t, szName, (tostring(szKey))}) do
			szKey = szKey + 1
		end
		szKey = tostring(szKey)
	end
	if eAction == 'REG' or eAction == 'UNREG' then
		local fnCurrentHook = Get(HOOK, {t, szName, szKey})
		if fnCurrentHook then
			Set(HOOK, {t, szName, szKey}, nil)
			UnhookTableFunc(t, szName, fnCurrentHook)
		end
	end
	if eAction == 'REG' then
		Set(HOOK, {t, szName, szKey}, fnHook)
		HookTableFunc(t, szName, fnHook, tOption)
	end
	return szKey
end
end

function LIB.InsertOperatorMenu(t, opt, action, opts, L)
	for _, op in ipairs(opts or { '==', '!=', '<', '>=', '>', '<=' }) do
		insert(t, {
			szOption = L and L[op] or _L.OPERATOR[op],
			bCheck = true, bMCheck = true,
			bChecked = opt == op,
			fnAction = function() action(op) end,
		})
	end
	return t
end

function LIB.JudgeOperator(opt, lval, rval, ...)
	if opt == '>' then
		return lval > rval
	elseif opt == '>=' then
		return lval >= rval
	elseif opt == '<' then
		return lval < rval
	elseif opt == '<=' then
		return lval <= rval
	elseif opt == '==' or opt == '===' then
		return lval == rval
	elseif opt == '~=' or opt == '!=' or opt == '!==' then
		return lval ~= rval
	end
end

-- 跨线程实时获取目标界面位置
-- 注册：LIB.CThreadCoor(dwType, dwID, szKey, true)
-- 注销：LIB.CThreadCoor(dwType, dwID, szKey, false)
-- 获取：LIB.CThreadCoor(dwType, dwID) -- 必须已注册才能获取
-- 注册：LIB.CThreadCoor(dwType, nX, nY, nZ, szKey, true)
-- 注销：LIB.CThreadCoor(dwType, nX, nY, nZ, szKey, false)
-- 获取：LIB.CThreadCoor(dwType, nX, nY, nZ) -- 必须已注册才能获取
do
local CACHE = {}
function LIB.CThreadCoor(arg0, arg1, arg2, arg3, arg4, arg5)
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
			LIB.Debug(NSFormatString('{$NS}#SYS'), _L('Error: `%s` has not be registed!', szCtcKey), DEBUG_LEVEL.ERROR)
		end
		--[[#DEBUG END]]
		return CThreadCoor_Get(cache.ctcid) -- nX, nY, bFront
	end
end
end

function LIB.GetUIScale()
	return Station.GetUIScale()
end

function LIB.GetOriginUIScale()
	-- 线性拟合出来的公式 -- 不知道不同机器会不会不一样
	-- 源数据
	-- 0.63, 0.7
	-- 0.666, 0.75
	-- 0.711, 0.8
	-- 0.756, 0.85
	-- 0.846, 0.95
	-- 0.89, 1
	-- return floor((1.13726 * Station.GetUIScale() / Station.GetMaxUIScale() - 0.011) * 100 + 0.5) / 100 -- +0.5为了四舍五入
	-- 不同显示器GetMaxUIScale都不一样 太麻烦了 放弃 直接读配置项
	return GetUserPreferences(3775, 'c') / 100 -- TODO: 不同步设置就GG了 要通过实时数值反向计算 缺少API
end

function LIB.GetFontScale(nOffset)
	return 1 + (nOffset or Font.GetOffset()) * 0.07
end

do
local CURRENT_ACCOUNT
function LIB.GetAccount()
	if IsNil(CURRENT_ACCOUNT) then
		if not CURRENT_ACCOUNT and Login_GetAccount then
			local bSuccess, szAccount = XpCall(Login_GetAccount)
			if bSuccess and not IsEmpty(szAccount) then
				CURRENT_ACCOUNT = szAccount
			end
		end
		if not CURRENT_ACCOUNT and GetUserAccount then
			local bSuccess, szAccount = XpCall(GetUserAccount)
			if bSuccess and not IsEmpty(szAccount) then
				CURRENT_ACCOUNT = szAccount
			end
		end
		if not CURRENT_ACCOUNT then
			local bSuccess, hFrame = XpCall(function() return Wnd.OpenWindow('LoginPassword') end)
			if bSuccess and hFrame then
				local hEdit = hFrame:Lookup('WndPassword/Edit_Account')
				if hEdit then
					CURRENT_ACCOUNT = hEdit:GetText()
				end
				Wnd.CloseWindow(hFrame)
			end
		end
		if not CURRENT_ACCOUNT then
			CURRENT_ACCOUNT = false
		end
	end
	return CURRENT_ACCOUNT or nil
end
end

function LIB.OpenBrowser(szAddr)
	if _G.OpenBrowser then
		_G.OpenBrowser(szAddr)
	else
		UI.OpenBrowser(szAddr)
	end
end

function LIB.ArrayToObject(arr)
	if not arr then
		return
	end
	local t = {}
	for k, v in pairs(arr) do
		if IsTable(v) and v[1] then
			t[v[1]] = v[2]
		else
			t[v] = true
		end
	end
	return t
end

function LIB.FlipObjectKV(obj)
	local t = {}
	for k, v in pairs(obj) do
		t[v] = k
	end
	return t
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
					insert(presets, option.preset)
				end
				for i, s in ipairs(presets) do
					if PRESETS[s] then
						for _, k in ipairs(PRESETS[s]) do
							entries[k] = option.root
						end
					end
				end
			end
			if IsTable(option.fields) then
				for k, v in pairs(option.fields) do
					if IsNumber(k) and IsString(v) then -- "XXX",
						if not IsTable(option.root) then
							assert(false, 'Module `' .. name .. '`: static field `' .. v .. '` must be declared with a table root.')
						end
						entries[v] = option.root
					elseif IsString(k) then -- XXX = D.XXX,
						statics[k] = v
						entries[k] = statics
					end
				end
			end
			if IsTable(option.interceptors) then
				for k, v in pairs(option.interceptors) do
					if IsString(k) and IsFunction(v) then -- XXX = function(k) end,
						interceptors[k] = v
					end
				end
			end
			if IsTable(option.triggers) then
				for k, v in pairs(option.triggers) do
					if IsString(k) and IsFunction(v) then -- XXX = function(k, v) end,
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
function LIB.CreateModule(options)
	local name = options.name or 'Unnamed'
	local exportEntries, exportInterceptors, exportTriggers = FormatModuleProxy(options.exports, name)
	local importEntries, importInterceptors, importTriggers = FormatModuleProxy(options.imports, name)
	local function getter(_, k)
		if not exportEntries[k] then
			LIB.Debug(PACKET_INFO.NAME_SPACE, 'Module `' .. name .. '`: get value failed, unregistered properity `' .. k .. '`.', DEBUG_LEVEL.WARNING)
			return
		end
		local interceptor = exportInterceptors[k]
		if interceptor then
			local pc, value = ParameterCounter(interceptor(k))
			if pc >= 1 then
				return value
			end
		end
		local value = nil
		local root = exportEntries[k]
		if root then
			value = root[k]
		end
		local trigger = exportTriggers[k]
		if trigger then
			trigger(k, value)
		end
		return value
	end
	local function setter(_, k, v)
		if not importEntries[k] then
			local errmsg = 'Module `' .. name .. '`: set value failed, unregistered properity `' .. k .. '`.'
			if not LIB.IsDebugClient() then
				LIB.Debug(PACKET_INFO.NAME_SPACE, errmsg, DEBUG_LEVEL.ERROR)
				return
			end
			assert(false, errmsg)
		end
		local interceptor = importInterceptors[k]
		if interceptor then
			local pc, res, value = ParameterCounter(pcall(interceptor, k, v))
			if not res then
				return
			end
			if pc >= 2 then
				v = value
			end
		end
		local root = importEntries[k]
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

function LIB.EditBox_AppendLinkPlayer(szName)
	local edit = LIB.GetChatInput()
	edit:InsertObj('['.. szName ..']', { type = 'name', text = '['.. szName ..']', name = szName })
	Station.SetFocusWindow(edit)
	return true
end

function LIB.EditBox_AppendLinkItem(dwID)
	local item = GetItem(dwID)
	if not item then
		return false
	end
	local szName = '[' .. LIB.GetItemNameByItem(item) ..']'
	local edit = LIB.GetChatInput()
	edit:InsertObj(szName, { type = 'item', text = szName, item = item.dwID })
	Station.SetFocusWindow(edit)
	return true
end

-------------------------------------------
-- 语音相关 API
-------------------------------------------

function LIB.GVoiceBase_IsOpen(...)
	if IsFunction(_G.GVoiceBase_IsOpen) then
		return _G.GVoiceBase_IsOpen(...)
	end
	return false
end

function LIB.GVoiceBase_GetMicState(...)
	if IsFunction(_G.GVoiceBase_GetMicState) then
		return _G.GVoiceBase_GetMicState(...)
	end
	return CONSTANT.MIC_STATE.CLOSE_NOT_IN_ROOM
end

function LIB.GVoiceBase_SwitchMicState(...)
	if IsFunction(_G.GVoiceBase_SwitchMicState) then
		return _G.GVoiceBase_SwitchMicState(...)
	end
end

function LIB.GVoiceBase_CheckMicState(...)
	if IsFunction(_G.GVoiceBase_CheckMicState) then
		return _G.GVoiceBase_CheckMicState(...)
	end
end

function LIB.GVoiceBase_GetSpeakerState(...)
	if IsFunction(_G.GVoiceBase_GetSpeakerState) then
		return _G.GVoiceBase_GetSpeakerState(...)
	end
	return CONSTANT.SPEAKER_STATE.CLOSE
end

function LIB.GVoiceBase_SwitchSpeakerState(...)
	if IsFunction(_G.GVoiceBase_SwitchSpeakerState) then
		return _G.GVoiceBase_SwitchSpeakerState(...)
	end
end

function LIB.GVoiceBase_GetSaying(...)
	if IsFunction(_G.GVoiceBase_GetSaying) then
		return _G.GVoiceBase_GetSaying(...)
	end
	return {}
end

function LIB.GVoiceBase_IsMemberSaying(...)
	if IsFunction(_G.GVoiceBase_IsMemberSaying) then
		return _G.GVoiceBase_IsMemberSaying(...)
	end
	return false
end

function LIB.GVoiceBase_IsMemberForbid(...)
	if IsFunction(_G.GVoiceBase_IsMemberForbid) then
		return _G.GVoiceBase_IsMemberForbid(...)
	end
	return false
end

function LIB.GVoiceBase_ForbidMember(...)
	if IsFunction(_G.GVoiceBase_ForbidMember) then
		return _G.GVoiceBase_ForbidMember(...)
	end
end

if _G.Login_GetTimeOfFee then
	function LIB.GetTimeOfFee()
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
	local data = frame and frame[NSFormatString('{$NS}_TimeOfFee')]
	if data then
		bInit, dwMonthEndTime, dwPointEndTime, dwDayEndTime = true, unpack(data)
	else
		LIB.RegisterMsgMonitor('MSG_SYS', 'LIB#GetTimeOfFee', function(szChannel, szMsg)
			-- 点卡剩余时间为：558小时41分33秒
			local szHour, szMinute, szSecond = szMsg:match(_L['Point left time: (%d+)h(%d+)m(%d+)s'])
			if szHour and szMinute and szSecond then
				local dwTime = GetCurrentTime()
				bInit = true
				dwPointEndTime = dwTime + tonumber(szHour) * 3600 + tonumber(szMinute) * 60 + tonumber(szSecond)
			end
			-- 包月时间截止至：xxxx/xx/xx xx:xx
			local szYear, szMonth, szDay, szHour, szMinute = szMsg:match(_L['Month time to: (%d+)y(%d+)m(%d+)d (%d+)h(%d+)m'])
			if szYear and szMonth and szDay and szHour and szMinute then
				bInit = true
				dwMonthEndTime = LIB.DateToTime(szYear, szMonth, szDay, szHour, szMinute, 0)
			end
			if bInit then
				local dwTime = GetCurrentTime()
				if dwMonthEndTime > dwTime then -- 优先消耗月卡 即点卡结束时间需要加上月卡时间
					dwPointEndTime = dwPointEndTime + dwMonthEndTime - dwTime
				end
				local frame = Station.Lookup('Lowest/Scene')
				if frame then
					frame[NSFormatString('{$NS}_TimeOfFee')] = {dwMonthEndTime, dwPointEndTime, dwDayEndTime}
				end
				LIB.RegisterMsgMonitor('MSG_SYS', 'LIB#GetTimeOfFee', false)
			end
		end)
	end
	function LIB.GetTimeOfFee()
		local dwTime = GetCurrentTime()
		local dwEndTime = max(dwMonthEndTime, dwPointEndTime, dwDayEndTime)
		return dwEndTime, dwMonthEndTime, max(dwPointEndTime - dwTime, 0), max(dwDayEndTime - dwTime, 0)
	end
end

do
local KEY = wgsub(PACKET_INFO.ROOT, '\\', '/'):lower()
local FILE_PATH = {'temporary/lua_error.jx3dat', PATH_TYPE.GLOBAL}
local LAST_ERROR_MSG = LIB.LoadLUAData(FILE_PATH, { passphrase = false }) or {}
local ERROR_MSG = {}
local function SaveErrorMessage()
	LIB.SaveLUAData(FILE_PATH, ERROR_MSG, { passphrase = false, crc = false, indent = '\t' })
end
local BROKEN_KGUI = IsDebugClient() and not LIB.IsDebugServer() and not LIB.IsDebugClient(true)
RegisterEvent('CALL_LUA_ERROR', function()
	local szMsg = arg0
	local szMsgL = wgsub(arg0:lower(), '\\', '/')
	if wfind(szMsgL, KEY) then
		if BROKEN_KGUI then
			local szMessage = 'Your KGUI is not official, please fix client and try again.'
			LIB.ErrorLog('[' .. PACKET_INFO.NAME_SPACE .. ']' .. szMessage .. '\n' .. _L[szMessage])
		end
		insert(ERROR_MSG, szMsg)
	end
	SaveErrorMessage()
end)
function LIB.GetAddonErrorMessage()
	local szMsg = concat(LAST_ERROR_MSG, '\n\n')
	if not IsEmpty(szMsg) then
		szMsg = szMsg .. '\n\n'
	end
	return szMsg .. concat(ERROR_MSG, '\n\n')
end
LIB.RegisterInit('LIB#AddonErrorMessage', SaveErrorMessage)
end

-----------------------------------------------
-- 事件驱动自动回收的缓存机制
-----------------------------------------------
function LIB.CreateCache(szNameMode, aEvent)
	-- 处理参数
	local szName, szMode
	if IsString(szNameMode) then
		local nPos = StringFindW(szNameMode, '.')
		if nPos then
			szName = sub(szNameMode, 1, nPos - 1)
			szMode = sub(szNameMode, nPos + 1)
		else
			szName = szNameMode
		end
	end
	if IsString(aEvent) then
		aEvent = {aEvent}
	elseif IsArray(aEvent) then
		aEvent = Clone(aEvent)
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
			LIB.RegisterEvent(szEvent, szKey, Flush)
		end
	end
	local function Unregister()
		for _, szEvent in ipairs(aEvent) do
			LIB.RegisterEvent(szEvent, szKey, false)
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
function LIB.Han2Pinyin(szText)
	if not IsString(szText) then
		return
	end
	if not PINYIN then
		PINYIN = LIB.LoadLUAData(PACKET_INFO.FRAMEWORK_ROOT .. 'data/pinyin/{$lang}.jx3dat', { passphrase = false })
		local tPinyinConsonant = {}
		for c, v in pairs(PINYIN) do
			local a, t = {}, {}
			for _, s in ipairs(v) do
				s = s:sub(1, 1)
				if not t[s] then
					t[s] = true
					insert(a, s)
				end
			end
			tPinyinConsonant[c] = a
		end
		PINYIN_CONSONANT = tPinyinConsonant
	end
	local aText = LIB.SplitString(szText, '')
	local aFull, nFullCount = {''}, 1
	local aConsonant, nConsonantCount = {''}, 1
	for _, szChar in ipairs(aText) do
		local aCharPinyin = PINYIN[szChar]
		if aCharPinyin and #aCharPinyin > 0 then
			for i = 2, #aCharPinyin do
				for j = 1, nFullCount do
					insert(aFull, aFull[j] .. aCharPinyin[i])
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
					insert(aConsonant, aConsonant[j] .. aCharPinyinConsonant[i])
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
