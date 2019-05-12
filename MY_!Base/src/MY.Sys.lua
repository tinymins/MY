--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 系统函数库
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
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
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
local GetPatch, ApplyPatch, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.FullClone
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
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
-- (void) LIB.RegisterHotKey(string szName, string szTitle, func fnAction)   -- 增加系统快捷键
function LIB.RegisterHotKey(szName, szTitle, fnAction)
	insert(HOTKEY_CACHE, { szName = szName, szTitle = szTitle, fnAction = fnAction })
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
		local szGroup = szCommand or LIB.GetAddonInfo().szName

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

LIB.RegisterInit(LIB.GetAddonInfo().szNameSpace .. '#BIND_HOTKEY', function()
	-- hotkey
	Hotkey.AddBinding(LIB.GetAddonInfo().szNameSpace .. '_Total', _L['Open/Close main panel'], LIB.GetAddonInfo().szName, LIB.TogglePanel, nil)
	for _, v in ipairs(HOTKEY_CACHE) do
		Hotkey.AddBinding(v.szName, v.szTitle, '', v.fnAction, nil)
	end
	for i = 1, 5 do
		Hotkey.AddBinding(LIB.GetAddonInfo().szNameSpace .. '_HotKey_Null_'..i, _L['none-function hotkey'], '', function() end, nil)
	end
end)
LIB.RegisterHotKey(LIB.GetAddonInfo().szNameSpace .. '_STOP_CASTING', _L['Stop cast skill'], function() GetClientPlayer().StopCurrentAction() end)
end

-- Save & Load Lua Data
-- ##################################################################################################
--         #       #             #                           #
--     #   #   #   #             #     # # # # # #           #               # # # # # #
--         #       #             #     #         #   # # # # # # # # # # #     #     #   # # # #
--   # # # # # #   # # # #   # # # #   # # # # # #         #                   #     #     #   #
--       # #     #     #         #     #     #           #     # # # # #       # # # #     #   #
--     #   # #     #   #         #     # # # # # #       #           #         #     #     #   #
--   #     #   #   #   #         # #   #     #         # #         #           # # # #     #   #
--       #         #   #     # # #     # # # # # #   #   #   # # # # # # #     #     #     #   #
--   # # # # #     #   #         #     # #       #       #         #           #     # #     #
--     #     #       #           #   #   #       #       #         #         # # # # #       #
--       # #       #   #         #   #   # # # # #       #         #                 #     #   #
--   # #     #   #       #     # # #     #       #       #       # #                 #   #       #
-- ##################################################################################################
if IsLocalFileExist(LIB.GetAddonInfo().szRoot .. '@DATA/') then
	CPath.Move(LIB.GetAddonInfo().szRoot .. '@DATA/', LIB.GetAddonInfo().szInterfaceRoot .. LIB.GetAddonInfo().szNameSpace .. '#DATA/')
end

-- 格式化数据文件路径（替换$uid、$lang、$server以及补全相对路径）
-- (string) LIB.GetLUADataPath(oFilePath)
--   当路径为绝对路径时(以斜杠开头)不作处理
--   当路径为相对路径时 相对于插件`MY@DATA`目录
--   可以传入表{szPath, ePathType}
function LIB.FormatPath(oFilePath, tParams)
	if not tParams then
		tParams = {}
	end
	local szFilePath, ePathType
	if type(oFilePath) == 'table' then
		szFilePath, ePathType = unpack(oFilePath)
	else
		szFilePath, ePathType = oFilePath, PATH_TYPE.NORMAL
	end
	-- Unified the directory separator
	szFilePath = string.gsub(szFilePath, '\\', '/')
	-- if it's relative path then complete path with '/{NS}@DATA/'
	if szFilePath:sub(2, 3) ~= ':/' then
		if ePathType == PATH_TYPE.DATA then
			szFilePath = LIB.GetAddonInfo().szInterfaceRoot .. LIB.GetAddonInfo().szNameSpace .. '#DATA/' .. szFilePath
		elseif ePathType == PATH_TYPE.GLOBAL then
			szFilePath = LIB.GetAddonInfo().szInterfaceRoot .. LIB.GetAddonInfo().szNameSpace .. '#DATA/!all-users@$lang/' .. szFilePath
		elseif ePathType == PATH_TYPE.ROLE then
			szFilePath = LIB.GetAddonInfo().szInterfaceRoot .. LIB.GetAddonInfo().szNameSpace .. '#DATA/$uid@$lang/' .. szFilePath
		elseif ePathType == PATH_TYPE.SERVER then
			szFilePath = LIB.GetAddonInfo().szInterfaceRoot .. LIB.GetAddonInfo().szNameSpace .. '#DATA/#$relserver@$lang/' .. szFilePath
		end
	end
	-- if exist $uid then add user role identity
	if string.find(szFilePath, '%$uid') then
		szFilePath = szFilePath:gsub('%$uid', tParams['uid'] or LIB.GetClientUUID())
	end
	-- if exist $name then add user role identity
	if string.find(szFilePath, '%$name') then
		szFilePath = szFilePath:gsub('%$name', tParams['name'] or LIB.GetClientInfo().szName or LIB.GetClientUUID())
	end
	-- if exist $lang then add language identity
	if string.find(szFilePath, '%$lang') then
		szFilePath = szFilePath:gsub('%$lang', tParams['lang'] or string.lower(LIB.GetLang()))
	end
	-- if exist $version then add version identity
	if string.find(szFilePath, '%$version') then
		szFilePath = szFilePath:gsub('%$version', tParams['version'] or select(2, GetVersion()))
	end
	-- if exist $date then add date identity
	if string.find(szFilePath, '%$date') then
		szFilePath = szFilePath:gsub('%$date', tParams['date'] or LIB.FormatTime('yyyyMMdd', GetCurrentTime()))
	end
	-- if exist $server then add server identity
	if string.find(szFilePath, '%$server') then
		szFilePath = szFilePath:gsub('%$server', tParams['server'] or ((LIB.GetServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- if exist $relserver then add relserver identity
	if string.find(szFilePath, '%$relserver') then
		szFilePath = szFilePath:gsub('%$relserver', tParams['relserver'] or ((LIB.GetRealServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	local rootPath = GetRootPath():gsub('\\', '/')
	if szFilePath:find(rootPath) == 1 then
		szFilePath = szFilePath:gsub(rootPath, '.')
	end
	return szFilePath
end

function LIB.GetRelativePath(oPath, oRoot)
	local szPath = LIB.FormatPath(oPath)
	local szRoot = LIB.FormatPath(oRoot)
	local szRootPath = GetRootPath():gsub('\\', '/')
	if wfind(szPath:lower(), szRootPath:lower()) == 1 then
		szPath = szPath:sub(szRootPath:len() + 1)
	end
	if wfind(szRoot:lower(), szRootPath:lower()) == 1 then
		szRoot = szRoot:sub(szRootPath:len() + 1)
	end
	if wfind(szPath:lower(), szRoot:lower()) ~= 1 then
		return
	end
	return szPath:sub(#szRoot + 1)
end

function LIB.GetAbsolutePath(oPath, oRoot)
	return GetRootPath():gsub('\\', '/') .. '/' .. LIB.GetRelativePath(oPath, oRoot):gsub('^[./\\]*', '')
end

function LIB.GetLUADataPath(oFilePath)
	local szFilePath = LIB.FormatPath(oFilePath)
	-- ensure has file name
	if string.sub(szFilePath, -1) == '/' then
		szFilePath = szFilePath .. 'data'
	end
	-- ensure file ext name
	if string.sub(szFilePath, -7):lower() ~= '.jx3dat' then
		szFilePath = szFilePath .. '.jx3dat'
	end
	return szFilePath
end

function LIB.ConcatPath(...)
	local aPath = {...}
	local szPath = ''
	for _, s in ipairs(aPath) do
		s = tostring(s):gsub('^[\/]+', '')
		if s ~= '' then
			szPath = szPath:gsub('[\/]+$', '')
			if szPath ~= '' then
				szPath = szPath .. '/'
			end
			szPath = szPath .. s
		end
	end
	return szPath
end

-- 保存数据文件
function LIB.SaveLUAData(oFilePath, ...)
	local nStartTick = GetTickCount()
	-- format uri
	local szFilePath = LIB.GetLUADataPath(oFilePath)
	-- save data
	local data = SaveLUAData(szFilePath, ...)
	-- performance monitor
	LIB.Debug({_L('%s saved during %dms.', szFilePath, GetTickCount() - nStartTick)}, 'PMTool', DEBUG_LEVEL.PMLOG)
	return data
end

-- 加载数据文件
function LIB.LoadLUAData(oFilePath, ...)
	local nStartTick = GetTickCount()
	-- format uri
	local szFilePath = LIB.GetLUADataPath(oFilePath)
	-- load data
	local data = LoadLUAData(szFilePath, ...)
	-- performance monitor
	LIB.Debug({_L('%s loaded during %dms.', szFilePath, GetTickCount() - nStartTick)}, 'PMTool', DEBUG_LEVEL.PMLOG)
	return data
end


-- 注册用户定义数据，支持全局变量数组遍历
-- (void) LIB.RegisterCustomData(string szVarPath[, number nVersion])
function LIB.RegisterCustomData(szVarPath, nVersion, szDomain)
	szDomain = szDomain or 'Role'
	if _G and type(_G[szVarPath]) == 'table' then
		for k, _ in pairs(_G[szVarPath]) do
			RegisterCustomData(szDomain .. '/' .. szVarPath .. '.' .. k, nVersion)
		end
	else
		RegisterCustomData(szDomain .. '/' .. szVarPath, nVersion)
	end
end

--szName [, szDataFile]
function LIB.RegisterUserData(szName, szFileName, onLoad)

end

do local USER_DB
function LIB.LoadDataBase()
	if USER_DB then
		return
	end
	USER_DB = UnQLite_Open(LIB.FormatPath({'userdata/base.udb', PATH_TYPE.ROLE}))
end

function LIB.ReleaseDataBase()
	if not USER_DB then
		return
	end
	USER_DB:Release()
	USER_DB = nil
end

function LIB.GetUserData(szKey)
	return USER_DB:Get(szKey)
end

function LIB.SetUserData(szKey, oValue)
	return USER_DB:Set(szKey, oValue)
end
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
			data = FullClone(data)
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
					if not skipKeys[k] then
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
			data = FullClone(defaultData)
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
		if type(tab[v]) == 'nil' then
			tab[v] = {}
		end
		if k == #t then
			tab[v] = Val
		end
		tab = tab[v]
	end
end

function LIB.GetGlobalValue(szVarPath)
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

do local CREATED = {}
function LIB.CreateDataRoot(ePathType)
	if CREATED[ePathType] then
		return
	end
	CREATED[ePathType] = true
	-- 创建目录
	if ePathType == PATH_TYPE.ROLE then
		CPath.MakeDir(LIB.FormatPath({'$name/', PATH_TYPE.ROLE}))
	end
	-- 版本更新时删除旧的临时目录
	if IsLocalFileExist(LIB.FormatPath({'temporary/', ePathType}))
	and not IsLocalFileExist(LIB.FormatPath({'temporary/$version', ePathType})) then
		CPath.DelDir(LIB.FormatPath({'temporary/', ePathType}))
	end
	CPath.MakeDir(LIB.FormatPath({'temporary/$version/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'audio/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'cache/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'config/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'export/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'userdata/', ePathType}))
end
end

do
local SOUND_ROOT = LIB.GetAddonInfo().szFrameworkRoot .. 'audio/'
local SOUNDS, CACHE = {
	{
		szType = _L['Default'],
		{ dwID = 1, szName = _L['Bing.ogg'], szPath = SOUND_ROOT .. 'Bing.ogg' },
		{ dwID = 88001, szName = _L['Notify.ogg'], szPath = SOUND_ROOT .. 'Notify.ogg' },
	},
}
local function GetSoundList()
	local a = { szOption = _L['Sound'] }
	for _, v in ipairs(SOUNDS) do
		insert(a, v)
	end
	if MY_Resource then
		for _, v in ipairs(MY_Resource.GetSoundList()) do
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
		if MY_Resource then
			local tSound = MY_Resource.GetSoundList()
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
	local szPath = string.gsub(szFilePath, '\\', '/')
	if string.sub(szPath, 1, 2) ~= './' then
		szPath = LIB.GetAddonInfo().szFrameworkRoot .. 'audio/' .. szPath
	end
	if not IsFileExist(szPath) then
		return
	end
	PlaySound(nType, szPath)
end

function LIB.GetFontList()
	local aList, tExist = {}, {}
	if MY_FontResource then
		aList = MY_FontResource.GetList()
	end
	for _, p in ipairs(aList) do
		local szFile = p.szFile:gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			tExist[szKey] = true
		end
	end
	for _, p in ipairs_r(Font.GetFontPathList() or {}) do
		local szFile = p.szFile:gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			insert(aList, 1, { szName = p.szName, szFile = szFile })
			tExist[szKey] = true
		end
	end
	local CUSTOM_FONT_DIR = LIB.FormatPath({'font/', PATH_TYPE.GLOBAL}):gsub('%./', '/')
	local CUSTOM_FONT_LIST = LIB.LoadLUAData(CUSTOM_FONT_DIR .. 'list.jx3dat') or {}
	for _, p in ipairs(CUSTOM_FONT_LIST) do
		local szFile = p.szFile:gsub('^%./', CUSTOM_FONT_DIR):gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			insert(aList, { szName = p.szName, szFile = szFile })
			tExist[szKey] = true
		end
	end
	return aList
end

-- 加载注册数据
LIB.RegisterInit(LIB.GetAddonInfo().szNameSpace .. '#INITDATA', function()
	local t = LIB.LoadLUAData({'config/initial.jx3dat', PATH_TYPE.GLOBAL})
	if t then
		for v_name, v_data in pairs(t) do
			LIB.SetGlobalValue(v_name, v_data)
		end
	end
end)

do
-------------------------------
-- remote data storage online
-- bosslist (done)
-- focus list (working on)
-- chat blocklist (working on)
-------------------------------
-- 个人数据版本号
local m_nStorageVer = {}
LIB.BreatheCall(LIB.GetAddonInfo().szNameSpace .. '#STORAGE_DATA', 200, function()
	if not LIB.IsInitialized() then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) or not LIB.GetTongName() then
		return
	end
	if LIB.IsDebugServer() then
		return 0
	end
	m_nStorageVer = LIB.LoadLUAData({'config/storageversion.jx3dat', PATH_TYPE.ROLE}) or {}
	LIB.Ajax({
		type = 'post/json',
		url = 'http://data.jx3.derzh.com/api/storage',
		data = {
			data = LIB.EncryptString(LIB.ConvertToUTF8(LIB.JsonEncode({
				g = me.GetGlobalID(), f = me.dwForceID, e = me.GetTotalEquipScore(),
				n = GetUserRoleName(), i = UI_GetClientPlayerID(), c = me.nCamp,
				S = LIB.GetRealServer(1), s = LIB.GetRealServer(2), r = me.nRoleType,
				_ = GetCurrentTime(), t = LIB.GetTongName(),
			}))),
			lang = LIB.GetLang(),
		},
		success = function(html, status)
			local data = LIB.JsonDecode(html)
			if data then
				for k, v in pairs(data.public or EMPTY_TABLE) do
					local oData = str2var(v)
					if oData then
						FireUIEvent('MY_PUBLIC_STORAGE_UPDATE', k, oData)
					end
				end
				for k, v in pairs(data.private or EMPTY_TABLE) do
					if not m_nStorageVer[k] or m_nStorageVer[k] < v.v then
						local oData = str2var(v.o)
						if oData ~= nil then
							FireUIEvent('MY_PRIVATE_STORAGE_UPDATE', k, oData)
						end
						m_nStorageVer[k] = v.v
					end
				end
				for _, v in ipairs(data.action or EMPTY_TABLE) do
					if v[1] == 'execute' then
						local f = LIB.GetGlobalValue(v[2])
						if f then
							f(select(3, v))
						end
					elseif v[1] == 'assign' then
						LIB.SetGlobalValue(v[2], v[3])
					elseif v[1] == 'axios' then
						LIB.Ajax({driver = v[2], type = v[3], url = v[4], data = v[5], timeout = v[6]})
					end
				end
			end
		end
	})
	return 0
end)
LIB.RegisterExit(LIB.GetAddonInfo().szNameSpace .. '#STORAGE_DATA', function()
	LIB.SaveLUAData({'config/storageversion.jx3dat', PATH_TYPE.ROLE}, m_nStorageVer)
end)
-- 保存个人数据 方便网吧党和公司家里多电脑切换
function LIB.StorageData(szKey, oData)
	if LIB.IsDebugServer() then
		return
	end
	LIB.DelayCall('STORAGE_' .. szKey, 120000, function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		LIB.Ajax({
			type = 'post/json',
			url = 'http://data.jx3.derzh.com/api/storage',
			data = {
				data =  LIB.EncryptString(LIB.JsonEncode({
					g = me.GetGlobalID(), f = me.dwForceID, r = me.nRoleType,
					n = GetUserRoleName(), i = UI_GetClientPlayerID(),
					S = LIB.GetRealServer(1), s = LIB.GetRealServer(2),
					v = GetCurrentTime(),
					k = szKey, o = oData
				})),
				lang = LIB.GetLang(),
			},
			success = function(html, status)
				local data = LIB.JsonDecode(html)
				if data and data.succeed then
					FireUIEvent('MY_PRIVATE_STORAGE_SYNC', szKey)
				end
			end,
		})
	end)
	m_nStorageVer[szKey] = GetCurrentTime()
end
end

do
local l_tBoolValues = {
	['MY_ChatSwitch_DisplayPanel'] = 0,
	['MY_ChatSwitch_LockPostion'] = 1,
	['MY_Recount_Enable'] = 2,
	['MY_ChatSwitch_CH1'] = 3,
	['MY_ChatSwitch_CH2'] = 4,
	['MY_ChatSwitch_CH3'] = 5,
	['MY_ChatSwitch_CH4'] = 6,
	['MY_ChatSwitch_CH5'] = 7,
	['MY_ChatSwitch_CH6'] = 8,
	['MY_ChatSwitch_CH7'] = 9,
	['MY_ChatSwitch_CH8'] = 10,
	['MY_ChatSwitch_CH9'] = 11,
	['MY_ChatSwitch_CH10'] = 12,
	['MY_ChatSwitch_CH11'] = 13,
	['MY_ChatSwitch_CH12'] = 14,
	['MY_ChatSwitch_CH13'] = 15,
	['MY_ChatSwitch_CH14'] = 16,
	['MY_ChatSwitch_CH15'] = 17,
	['MY_ChatSwitch_CH16'] = 18,
}
local l_watches = {}
local BIT_NUMBER = 8

local function OnStorageChange(szKey)
	if not l_watches[szKey] then
		return
	end
	local oVal = LIB.GetStorage(szKey)
	for _, fnAction in ipairs(l_watches[szKey]) do
		fnAction(oVal)
	end
end

function LIB.SetStorage(szKey, oVal)
	local szPriKey, szSubKey = szKey
	local nPos = StringFindW(szKey, '.')
	if nPos then
		szSubKey = string.sub(szKey, nPos + 1)
		szPriKey = string.sub(szKey, 1, nPos - 1)
	end
	if szPriKey == 'BoolValues' then
		local nBitPos = l_tBoolValues[szSubKey]
		if not nBitPos then
			return
		end
		local nPos = math.floor(nBitPos / BIT_NUMBER)
		local nOffset = BIT_NUMBER - nBitPos % BIT_NUMBER - 1
		local nByte = GetAddonCustomData('MY', nPos, 1)
		local nBit = math.floor(nByte / math.pow(2, nOffset)) % 2
		if (nBit == 1) == (not not oVal) then
			return
		end
		nByte = nByte + (nBit == 1 and -1 or 1) * math.pow(2, nOffset)
		SetAddonCustomData('MY', nPos, 1, nByte)
	elseif szPriKey == 'FrameAnchor' then
		return SetOnlineFrameAnchor(szSubKey, oVal)
	end
	OnStorageChange(szKey)
end

function LIB.GetStorage(szKey)
	local szPriKey, szSubKey = szKey
	local nPos = StringFindW(szKey, '.')
	if nPos then
		szSubKey = string.sub(szKey, nPos + 1)
		szPriKey = string.sub(szKey, 1, nPos - 1)
	end
	if szPriKey == 'BoolValues' then
		local nBitPos = l_tBoolValues[szSubKey]
		if not nBitPos then
			return
		end
		local nPos = math.floor(nBitPos / BIT_NUMBER)
		local nOffset = BIT_NUMBER - nBitPos % BIT_NUMBER - 1
		local nByte = GetAddonCustomData('MY', nPos, 1)
		local nBit = math.floor(nByte / math.pow(2, nOffset)) % 2
		return nBit == 1
	elseif szPriKey == 'FrameAnchor' then
		return GetOnlineFrameAnchor(szSubKey)
	end
end

function LIB.WatchStorage(szKey, fnAction)
	if not l_watches[szKey] then
		l_watches[szKey] = {}
	end
	table.insert(l_watches[szKey], fnAction)
end

local INIT_FUNC_LIST = {}
function LIB.RegisterStorageInit(szKey, fnAction)
	INIT_FUNC_LIST[szKey] = fnAction
end

local function OnInit()
	for szKey, _ in pairs(l_watches) do
		OnStorageChange(szKey)
	end
	for szKey, fnAction in pairs(INIT_FUNC_LIST) do
		local status, err = pcall(fnAction)
		if not status then
			LIB.Debug({GetTraceback(err)}, 'STORAGE_INIT_FUNC_LIST#' .. szKey)
		end
	end
	INIT_FUNC_LIST = {}
end
LIB.RegisterEvent('RELOAD_UI_ADDON_END.' .. LIB.GetAddonInfo().szNameSpace .. '#Storage', OnInit)
LIB.RegisterEvent('FIRST_SYNC_USER_PREFERENCES_END.' .. LIB.GetAddonInfo().szNameSpace .. '#Storage', OnInit)
end

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

local function GenerateMenu(aList, bMainMenu)
	local menu = {}
	if bMainMenu then
		menu = {
			szOption = LIB.GetAddonInfo().szName,
			fnAction = LIB.TogglePanel,
			rgb = LIB.GetAddonInfo().tMenuColor,
			bCheck = true,
			bChecked = LIB.IsPanelVisible(),

			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 105, nMouseOverFrame = 106,
			szLayer = 'ICON_RIGHT',
			fnClickIcon = LIB.TogglePanel,
		}
	end
	for _, p in ipairs(aList) do
		local m = p.oMenu
		if IsFunction(m) then
			m = m()
		end
		if not m or m.szOption then
			m = {m}
		end
		for _, v in ipairs(m) do
			if not v.rgb and not bMainMenu then
				v.rgb = LIB.GetAddonInfo().tMenuColor
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
local function GetPlayerAddonMenu()
	return GenerateMenu(PLAYER_MENU, true)
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
local function GetTraceButtonAddonMenu()
	return GenerateMenu(TRACE_MENU, true)
end
TraceButton_AppendAddonMenu({GetTraceButtonAddonMenu})
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
local function GetTargetAddonMenu()
	return GenerateMenu(TARGET_MENU, false)
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
-- (string) LIB.FormatTimeCount(szFormat, nTime)
-- szFormat  格式化字符串 可选项H,M,S,hh,mm,ss,h,m,s
function LIB.FormatTimeCount(szFormat, nTime)
	local nSeconds = math.floor(nTime)
	local nMinutes = math.floor(nSeconds / 60)
	local nHours   = math.floor(nMinutes / 60)
	local nMinute  = nMinutes % 60
	local nSecond  = nSeconds % 60
	szFormat = szFormat:gsub('H', nHours)
	szFormat = szFormat:gsub('M', nMinutes)
	szFormat = szFormat:gsub('S', nSeconds)
	szFormat = szFormat:gsub('hh', string.format('%02d', nHours ))
	szFormat = szFormat:gsub('mm', string.format('%02d', nMinute))
	szFormat = szFormat:gsub('ss', string.format('%02d', nSecond))
	szFormat = szFormat:gsub('h', nHours)
	szFormat = szFormat:gsub('m', nMinute)
	szFormat = szFormat:gsub('s', nSecond)
	return szFormat
end

-- 格式化时间
-- (string) LIB.FormatTimeCount(szFormat[, nTimestamp])
-- szFormat   格式化字符串 可选项yyyy,yy,MM,dd,y,m,d,hh,mm,ss,h,m,s
-- nTimestamp UNIX时间戳
function LIB.FormatTime(szFormat, nTimestamp)
	local t = TimeToDate(nTimestamp or GetCurrentTime())
	szFormat = szFormat:gsub('yyyy', string.format('%04d', t.year  ))
	szFormat = szFormat:gsub('yy'  , string.format('%02d', t.year % 100))
	szFormat = szFormat:gsub('MM'  , string.format('%02d', t.month ))
	szFormat = szFormat:gsub('dd'  , string.format('%02d', t.day   ))
	szFormat = szFormat:gsub('hh'  , string.format('%02d', t.hour  ))
	szFormat = szFormat:gsub('mm'  , string.format('%02d', t.minute))
	szFormat = szFormat:gsub('ss'  , string.format('%02d', t.second))
	szFormat = szFormat:gsub('y', t.year  )
	szFormat = szFormat:gsub('M', t.month )
	szFormat = szFormat:gsub('d', t.day   )
	szFormat = szFormat:gsub('h', t.hour  )
	szFormat = szFormat:gsub('m', t.minute)
	szFormat = szFormat:gsub('s', t.second)
	return szFormat
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
			RegisterGlobalEsc(szID, fnCondition, fnAction, bTopmost)
		end
	else
		if UnRegisterGlobalEsc then
			UnRegisterGlobalEsc(szID, bTopmost)
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
	local wndAll = frame:Lookup('Wnd_All')

	for i = 1, 5 do
		local btn = wndAll:Lookup('Btn_Option' .. i)
		if btn and btn.IsVisible and btn:IsVisible() then
			local nIndex, szOption = btn.nIndex, btn.szOption
			if btn.fnAction then
				HookTableFunc(btn, 'fnAction', function()
					FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_MESSAGE_BOX_ACTION', szName, 'ACTION', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			if btn.fnCountDownEnd then
				HookTableFunc(btn, 'fnCountDownEnd', function()
					FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_MESSAGE_BOX_ACTION', szName, 'TIME_OUT', szOption, nIndex)
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
		FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_MESSAGE_BOX_ACTION', szName, 'ACTION', msg.szOption, msg.nIndex)
	end, { bAfterOrigin = true })

	HookTableFunc(frame, 'fnCancelAction', function()
		FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_MESSAGE_BOX_ACTION', szName, 'CANCEL')
	end, { bAfterOrigin = true })

	if frame.fnAutoClose then
		HookTableFunc(frame, 'fnAutoClose', function()
			FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_MESSAGE_BOX_ACTION', szName, 'AUTO_CLOSE')
		end, { bAfterOrigin = true })
	end

	FireUIEvent(LIB.GetAddonInfo().szNameSpace .. '_MESSAGE_BOX_OPEN', arg0, arg1)
end
LIB.RegisterEvent('ON_MESSAGE_BOX_OPEN', OnMessageBoxOpen)
end

function LIB.Alert(szMsg, fnAction, szSure, fnCancelAction)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = LIB.GetAddonInfo().szNameSpace .. '_Alert',
		szMessage = szMsg,
		szAlignment = 'CENTER',
		fnCancelAction = fnCancelAction,
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		},
	}
	MessageBox(tMsg)
end

function LIB.Confirm(szMsg, fnAction, fnCancel, szSure, szCancel, fnCancelAction)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = LIB.GetAddonInfo().szNameSpace .. '_Confirm',
		szMessage = szMsg,
		szAlignment = 'CENTER',
		fnCancelAction = fnCancelAction,
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		}, {
			szOption = szCancel or g_tStrings.STR_HOTKEY_CANCEL,
			fnAction = fnCancel,
		},
	}
	MessageBox(tMsg)
end

function LIB.Dialog(szMsg, aOptions, fnCancelAction)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = LIB.GetAddonInfo().szNameSpace .. '_Dialog',
		szMessage = szMsg,
		szAlignment = 'CENTER',
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
	MessageBox(tMsg)
end

do
function LIB.Hex2RGB(hex)
	local s, r, g, b, a = (hex:gsub('#', ''))
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
	local tColor = LIB.LoadLUAData(LIB.GetAddonInfo().szFrameworkRoot .. 'data/colors.jx3dat')
	for id, col in pairs(tColor) do
		local r, g, b = LIB.Hex2RGB(col)
		if r then
			if _L.COLOR_NAME[id] then
				COLOR_NAME_RGB[_L.COLOR_NAME[id]] = {r, g, b}
			end
			COLOR_NAME_RGB[id] = {r, g, b}
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

function LIB.ExecuteWithThis(element, fnAction, ...)
	if not (element and element:IsValid()) then
		-- Log('[UI ERROR]Invalid element on executing ui event!')
		return false
	end
	if type(fnAction) == 'string' then
		if element[fnAction] then
			fnAction = element[fnAction]
		else
			local szFrame = element:GetRoot():GetName()
			if type(_G[szFrame]) == 'table' then
				fnAction = _G[szFrame][fnAction]
			end
		end
	end
	if type(fnAction) ~= 'function' then
		-- Log('[UI ERROR]Invalid function on executing ui event! # ' .. element:GetTreePath())
		return false
	end
	local _this = this
	this = element
	local rets = {fnAction(...)}
	this = _this
	return true, unpack(rets)
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
	local dwType, dwID, nX, nY, nZ, szCtcKey, szKey, bReg = arg0
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
		if not cache then
			LIB.Debug({_L('Error: `%s` has not be registed!', szCtcKey)}, 'MY#SYS', DEBUG_LEVEL.ERROR)
		end
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
local function RenameDatabase(szCaption, szPath)
	local i = 0
	local szMalformedPath
	repeat
		szMalformedPath = szPath .. '.' .. i ..  '.malformed'
		i = i + 1
	until not IsLocalFileExist(szMalformedPath)
	CPath.Move(szPath, szMalformedPath)
	if not IsLocalFileExist(szMalformedPath) then
		return
	end
	return szMalformedPath
end

local function DuplicateDatabase(DB_SRC, DB_DST)
	LIB.Debug({'Duplicate database start.'}, szCaption, DEBUG_LEVEL.LOG)
	-- 运行 DDL 语句 创建表和索引等
	for _, rec in ipairs(DB_SRC:Execute('SELECT sql FROM sqlite_master')) do
		DB_DST:Execute(rec.sql)
		LIB.Debug({'Duplicating database: ' .. rec.sql}, szCaption, DEBUG_LEVEL.LOG)
	end
	-- 读取表名 依次复制
	for _, rec in ipairs(DB_SRC:Execute('SELECT name FROM sqlite_master WHERE type=\'table\'')) do
		-- 读取列名
		local szTableName, aColumns, aPlaceholders = rec.name, {}, {}
		for _, rec in ipairs(DB_SRC:Execute('PRAGMA table_info(' .. szTableName .. ')')) do
			insert(aColumns, rec.name)
			insert(aPlaceholders, '?')
		end
		local szColumns, szPlaceholders = concat(aColumns, ', '), concat(aPlaceholders, ', ')
		local nCount, nPageSize = Get(DB_SRC:Execute('SELECT COUNT(*) AS count FROM ' .. szTableName), {1, 'count'}, 0), 10000
		local DB_W = DB_DST:Prepare('REPLACE INTO ' .. szTableName .. ' (' .. szColumns .. ') VALUES (' .. szPlaceholders .. ')')
		LIB.Debug({'Duplicating table: ' .. szTableName .. ' (cols)' .. szColumns .. ' (count)' .. nCount}, szCaption, DEBUG_LEVEL.LOG)
		-- 开始读取和写入数据
		DB_DST:Execute('BEGIN TRANSACTION')
		for i = 0, nCount / nPageSize do
			for _, rec in ipairs(DB_SRC:Execute('SELECT ' .. szColumns .. ' FROM ' .. szTableName .. ' LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
				local aVals = {}
				for i, szKey in ipairs(aColumns) do
					aVals[i] = rec[szKey]
				end
				DB_W:ClearBindings()
				DB_W:BindAll(unpack(aVals))
				DB_W:Execute()
			end
		end
		DB_DST:Execute('END TRANSACTION')
		LIB.Debug({'Duplicating table finished: ' .. szTableName}, szCaption, DEBUG_LEVEL.LOG)
	end
end

local function ConnectMalformedDatabase(szCaption, szPath, bAlert)
	LIB.Debug({'Fixing malformed database...'}, szCaption, DEBUG_LEVEL.LOG)
	local szMalformedPath = RenameDatabase(szCaption, szPath)
	if not szMalformedPath then
		LIB.Debug({'Fixing malformed database failed... Move file failed...'}, szCaption, DEBUG_LEVEL.LOG)
		return 'FILE_LOCKED'
	else
		local DB_DST = SQLite3_Open(szPath)
		local DB_SRC = SQLite3_Open(szMalformedPath)
		if DB_DST and DB_SRC then
			DuplicateDatabase(DB_SRC, DB_DST)
			DB_SRC:Release()
			CPath.DelFile(szMalformedPath)
			LIB.Debug({'Fixing malformed database finished...'}, szCaption, DEBUG_LEVEL.LOG)
			return 'SUCCESS', DB_DST
		elseif not DB_SRC then
			LIB.Debug({'Connect malformed database failed...'}, szCaption, DEBUG_LEVEL.LOG)
			return 'TRANSFER_FAILED', DB_DST
		end
	end
end

function LIB.ConnectDatabase(szCaption, oPath, fnAction)
	-- 尝试连接数据库
	local szPath = LIB.FormatPath(oPath)
	LIB.Debug({'Connect database: ' .. szPath}, szCaption, DEBUG_LEVEL.LOG)
	local DB = SQLite3_Open(szPath)
	if not DB then
		-- 连不上直接重命名原始文件并重新连接
		if IsLocalFileExist(szPath) and RenameDatabase(szCaption, szPath) then
			DB = SQLite3_Open(szPath)
		end
		if not DB then
			LIB.Debug({'Cannot connect to database!!!'}, szCaption, DEBUG_LEVEL.ERROR)
			if fnAction then
				fnAction()
			end
			return
		end
	end

	-- 测试数据库完整性
	local aRes = DB:Execute('PRAGMA QUICK_CHECK')
	if Get(aRes, {1, 'integrity_check'}) == 'ok' then
		if fnAction then
			fnAction(DB)
		end
		return DB
	else
		LIB.Debug({'Malformed database detected...'}, szCaption, DEBUG_LEVEL.ERROR)
		for _, rec in ipairs(aRes or {}) do
			LIB.Debug({var2str(rec)}, szCaption, DEBUG_LEVEL.ERROR)
		end
		DB:Release()
		if fnAction then
			LIB.Confirm(_L('%s Database is malformed, do you want to repair database now? Repair database may take a long time and cause a disconnection.', szCaption), function()
				LIB.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					local szStatus, DB = ConnectMalformedDatabase(szCaption, szPath)
					if szStatus == 'FILE_LOCKED' then
						LIB.Alert(_L('Database file locked, repair database failed! : %s', szPath))
					else
						LIB.Alert(_L('%s Database repair finished!', szCaption))
					end
					fnAction(DB)
				end)
			end)
		else
			return select(2, ConnectMalformedDatabase(szCaption, szPath))
		end
	end
end
end

function LIB.OpenBrowser(szAddr)
	OpenBrowser(szAddr)
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

-- Global exports
do
local PRESETS = {
	UIEvent = LIB.ArrayToObject({
		'OnFrameCreate',
		'OnFrameDestroy',
		'OnFrameBreathe',
		'OnEvent',
		'OnSetFocus',
		'OnKillFocus',
		'OnItemLButtonClick',
		'OnItemMButtonClick',
		'OnItemRButtonClick',
		'OnItemMouseEnter',
		'OnItemMouseLeave',
		'OnItemMouseWheel',
		'OnLButtonDown',
		'OnLButtonUp',
		'OnLButtonClick',
		'OnLButtonHold',
		'OnMButtonDown',
		'OnMButtonUp',
		'OnMButtonClick',
		'OnMButtonHold',
		'OnRButtonDown',
		'OnRButtonUp',
		'OnRButtonClick',
		'OnRButtonHold',
		'OnMouseEnter',
		'OnMouseLeave',
		'OnScrollBarPosChanged',
		'OnEditChanged',
		'OnEditSpecialKeyDown',
	}),
}
function LIB.GeneGlobalNS(options)
	local exports = Get(options, 'exports', {})
	for _, export in ipairs(exports) do
		if not export.presets then
			export.presets = {}
		end
		if export.preset then
			insert(export.presets, export.preset)
			export.preset = nil
		end
		for i, s in ipairs_r(export.presets) do
			if not PRESETS[s] then
				remove(export.presets, i)
			end
		end
	end
	local function getter(_, k)
		local found, v, trigger, getter = false
		for _, export in ipairs(exports) do
			trigger = Get(export, {'triggers', k})
			if trigger then
				trigger(k)
			end
			if not found then
				getter, found = Get(export, {'getters', k})
				if getter then
					v = getter(k)
				end
			end
			if not found then
				v, found = Get(export, {'fields', k})
				if found then
					if export.root and not IsNil(v) then
						v = export.root[k]
					end
				else -- if not found
					for _, presetName in ipairs(export.presets) do
						local presetKeys = PRESETS[presetName]
						if presetKeys and presetKeys[k] then
							if IsFunction(export.root[k]) then
								v = export.root[k]
								found = true
								break
							end
						end
					end
				end
			end
			if found then
				return v
			end
		end
	end

	local imports = Get(options, 'imports', {})
	local function setter(_, k, v)
		local found, trigger, setter, res = false
		for _, import in ipairs(imports) do
			trigger = Get(import, {'triggers', k})
			if IsTable(trigger) and IsFunction(trigger[1]) then
				trigger[1](k, v)
			end
			if not found then
				setter, found = Get(import, {'setters', k})
				if setter then
					setter(k, v)
					found = true
				end
			end
			if not found then
				res, found = Get(import, {'fields', k})
				if res and import.root then
					import.root[k] = v
				end
			end
			if IsTable(trigger) and IsFunction(trigger[2]) then
				trigger[2](k, v)
			elseif IsFunction(trigger) then
				trigger(k, v)
			end
			if found then
				return
			end
		end
	end
	return setmetatable({}, { __index = getter, __newindex = setter })
end
end
