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
if IsLocalFileExist(PACKET_INFO.ROOT .. '@DATA/') then
	CPath.Move(PACKET_INFO.ROOT .. '@DATA/', PACKET_INFO.DATA_ROOT)
end

-- 格式化数据文件路径（替换{$uid}、{$lang}、{$server}以及补全相对路径）
-- (string) LIB.GetLUADataPath(oFilePath)
--   当路径为绝对路径时(以斜杠开头)不作处理
--   当路径为相对路径时 相对于插件`{NS}#DATA`目录
--   可以传入表{szPath, ePathType}
local PATH_TYPE_MOVE_STATE = {
	[PATH_TYPE.GLOBAL] = 'PENDING',
	[PATH_TYPE.ROLE] = 'PENDING',
	[PATH_TYPE.SERVER] = 'PENDING',
}
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
	-- 兼容旧版数据位置
	if PATH_TYPE_MOVE_STATE[ePathType] == 'PENDING' then
		PATH_TYPE_MOVE_STATE[ePathType] = nil
		local szPath = LIB.FormatPath({'', ePathType})
		if not IsLocalFileExist(szPath) then
			local szOriginPath
			if ePathType == PATH_TYPE.GLOBAL then
				szOriginPath = LIB.FormatPath({'!all-users@{$lang}/', PATH_TYPE.DATA})
			elseif ePathType == PATH_TYPE.ROLE then
				szOriginPath = LIB.FormatPath({'{$uid}@{$lang}/', PATH_TYPE.DATA})
			elseif ePathType == PATH_TYPE.SERVER then
				szOriginPath = LIB.FormatPath({'#{$relserver}@{$lang}/', PATH_TYPE.DATA})
			end
			if IsLocalFileExist(szOriginPath) then
				CPath.Move(szOriginPath, szPath)
			end
		end
	end
	-- Unified the directory separator
	szFilePath = gsub(szFilePath, '\\', '/')
	-- if it's relative path then complete path with '/{NS}#DATA/'
	if szFilePath:sub(2, 3) ~= ':/' then
		if ePathType == PATH_TYPE.DATA then
			szFilePath = PACKET_INFO.DATA_ROOT .. szFilePath
		elseif ePathType == PATH_TYPE.GLOBAL then
			szFilePath = PACKET_INFO.DATA_ROOT .. '!all-users@{$edition}/' .. szFilePath
		elseif ePathType == PATH_TYPE.ROLE then
			szFilePath = PACKET_INFO.DATA_ROOT .. '{$uid}@{$edition}/' .. szFilePath
		elseif ePathType == PATH_TYPE.SERVER then
			szFilePath = PACKET_INFO.DATA_ROOT .. '#{$relserver}@{$edition}/' .. szFilePath
		end
	end
	-- if exist {$uid} then add user role identity
	if find(szFilePath, '{$uid}', nil, true) then
		szFilePath = szFilePath:gsub('{%$uid}', tParams['uid'] or LIB.GetClientUUID())
	end
	-- if exist {$name} then add user role identity
	if find(szFilePath, '{$name}', nil, true) then
		szFilePath = szFilePath:gsub('{%$name}', tParams['name'] or LIB.GetClientInfo().szName or LIB.GetClientUUID())
	end
	-- if exist {$lang} then add language identity
	if find(szFilePath, '{$lang}', nil, true) then
		szFilePath = szFilePath:gsub('{%$lang}', tParams['lang'] or GLOBAL.GAME_LANG)
	end
	-- if exist {$edition} then add edition identity
	if find(szFilePath, '{$edition}', nil, true) then
		szFilePath = szFilePath:gsub('{%$edition}', tParams['edition'] or GLOBAL.GAME_EDITION)
	end
	-- if exist {$branch} then add branch identity
	if find(szFilePath, '{$branch}', nil, true) then
		szFilePath = szFilePath:gsub('{%$branch}', tParams['branch'] or GLOBAL.GAME_BRANCH)
	end
	-- if exist {$version} then add version identity
	if find(szFilePath, '{$version}', nil, true) then
		szFilePath = szFilePath:gsub('{%$version}', tParams['version'] or GLOBAL.GAME_VERSION)
	end
	-- if exist {$date} then add date identity
	if find(szFilePath, '{$date}', nil, true) then
		szFilePath = szFilePath:gsub('{%$date}', tParams['date'] or LIB.FormatTime(GetCurrentTime(), '%yyyy%MM%dd'))
	end
	-- if exist {$server} then add server identity
	if find(szFilePath, '{$server}', nil, true) then
		szFilePath = szFilePath:gsub('{%$server}', tParams['server'] or ((LIB.GetServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- if exist {$relserver} then add relserver identity
	if find(szFilePath, '{$relserver}', nil, true) then
		szFilePath = szFilePath:gsub('{%$relserver}', tParams['relserver'] or ((LIB.GetRealServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	local rootPath = GetRootPath():gsub('\\', '/')
	if szFilePath:find(rootPath) == 1 then
		szFilePath = szFilePath:gsub(rootPath, '.')
	end
	return szFilePath
end

function LIB.GetRelativePath(oPath, oRoot)
	local szPath = LIB.FormatPath(oPath):gsub('^%./', '')
	local szRoot = LIB.FormatPath(oRoot):gsub('^%./', '')
	local szRootPath = GetRootPath():gsub('\\', '/')
	if szPath:sub(2, 2) ~= ':' then
		szPath = LIB.ConcatPath(szRootPath, szPath)
	end
	if szRoot:sub(2, 2) ~= ':' then
		szRoot = LIB.ConcatPath(szRootPath, szRoot)
	end
	szRoot = szRoot:gsub('/$', '') .. '/'
	if wfind(szPath:lower(), szRoot:lower()) ~= 1 then
		return
	end
	return szPath:sub(#szRoot + 1)
end

function LIB.GetAbsolutePath(oPath)
	local szPath = LIB.FormatPath(oPath)
	if szPath:sub(2, 2) == ':' then
		return szPath
	end
	return LIB.NormalizePath(GetRootPath():gsub('\\', '/') .. '/' .. LIB.GetRelativePath(szPath, {'', PATH_TYPE.NORMAL}):gsub('^[./\\]*', ''))
end

function LIB.GetLUADataPath(oFilePath)
	local szFilePath = LIB.FormatPath(oFilePath)
	-- ensure has file name
	if sub(szFilePath, -1) == '/' then
		szFilePath = szFilePath .. 'data'
	end
	-- ensure file ext name
	if sub(szFilePath, -7):lower() ~= '.jx3dat' then
		szFilePath = szFilePath .. '.jx3dat'
	end
	return szFilePath
end

function LIB.ConcatPath(...)
	local aPath = {...}
	local szPath = ''
	for _, s in ipairs(aPath) do
		s = tostring(s):gsub('^[\\/]+', '')
		if s ~= '' then
			szPath = szPath:gsub('[\\/]+$', '')
			if szPath ~= '' then
				szPath = szPath .. '/'
			end
			szPath = szPath .. s
		end
	end
	return szPath
end

-- 替换目录分隔符为反斜杠，并且删除目录中的.\与..\
function LIB.NormalizePath(szPath)
	szPath = szPath:gsub('/', '\\')
	szPath = szPath:gsub('\\%.\\', '\\')
	local nPos1, nPos2
	while true do
		nPos1, nPos2 = szPath:find('[^\\]*\\%.%.\\')
		if not nPos1 then
			break
		end
		szPath = szPath:sub(1, nPos1 - 1) .. szPath:sub(nPos2 + 1)
	end
	return szPath
end

-- 获取父层目录 注意文件和文件夹获取父层的区别
function LIB.GetParentPath(szPath)
	return LIB.NormalizePath(szPath):gsub('/[^/]*$', '')
end

function LIB.OpenFolder(szPath)
	if _G.OpenFolder then
		_G.OpenFolder(szPath)
	end
end

function LIB.IsURL(szURL)
	return szURL:sub(1, 8):lower() == 'https://' or szURL:gsub(1, 7):lower() == 'http://'
end

-- 插件数据存储默认密钥
local GetLUADataPathPassphrase
do
local function GetPassphrase(nSeed, nLen)
	local a = {}
	local b, c = 0x20, 0x7e - 0x20 + 1
	for i = 1, nLen do
		insert(a, ((i + nSeed) % 256 * (2 * i + nSeed) % 32) % c + b)
	end
	return char(unpack(a))
end
local szDataRoot = StringLowerW(LIB.FormatPath({'', PATH_TYPE.DATA}))
local szPassphrase = GetPassphrase(666, 233)
local CACHE = {}
function GetLUADataPathPassphrase(szPath)
	-- 忽略大小写
	szPath = StringLowerW(szPath)
	-- 去除目录前缀
	if szPath:sub(1, szDataRoot:len()) ~= szDataRoot then
		return
	end
	szPath = szPath:sub(#szDataRoot + 1)
	-- 拆分数据分类地址
	local nPos = wfind(szPath, '/')
	if not nPos or nPos == 1 then
		return
	end
	local szDomain = szPath:sub(1, nPos)
	szPath = szPath:sub(nPos + 1)
	-- 过滤不需要加密的地址
	local nPos = wfind(szPath, '/')
	if nPos then
		if szPath:sub(1, nPos - 1) == 'export' then
			return
		end
	end
	-- 获取或创建密钥
	local bNew = false
	if not CACHE[szDomain] or not CACHE[szDomain][szPath] then
		local szFilePath = szDataRoot .. szDomain .. '/manifest.jx3dat'
		local tManifest = LoadLUAData(szFilePath, { passphrase = szPassphrase }) or {}
		-- 临时大小写兼容逻辑
		CACHE[szDomain] = {}
		for szPath, v in pairs(tManifest) do
			CACHE[szDomain][StringLowerW(szPath)] = v
		end
		if not CACHE[szDomain][szPath] then
			bNew = true
			CACHE[szDomain][szPath] = LIB.GetUUID():gsub('-', '')
			SaveLUAData(szFilePath, CACHE[szDomain], { passphrase = szPassphrase })
		end
	end
	return CACHE[szDomain][szPath], bNew
end
end

-- 获取插件软唯一标示符
do
local GUID
function LIB.GetClientGUID()
	if not GUID then
		local szRandom = GetLUADataPathPassphrase(LIB.GetLUADataPath({'GUIDv2', PATH_TYPE.GLOBAL}))
		local szPrefix = MD5(szRandom):sub(1, 4)
		local nCSW, nCSH = GetSystemCScreen()
		local szCS = MD5(nCSW .. ',' .. nCSH):sub(1, 4)
		GUID = ('%s%X%s'):format(szPrefix, GetStringCRC(szRandom), szCS)
	end
	return GUID
end
end

-- 保存数据文件
function LIB.SaveLUAData(oFilePath, oData, tConfig)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTickCount()
	--[[#DEBUG END]]
	local config, szPassphrase, bNew = Clone(tConfig) or {}, nil, nil
	local szFilePath = LIB.GetLUADataPath(oFilePath)
	if IsNil(config.passphrase) then
		config.passphrase = GetLUADataPathPassphrase(szFilePath)
	end
	local data = SaveLUAData(szFilePath, oData, config)
	--[[#DEBUG BEGIN]]
	LIB.Debug('PMTool', _L('%s saved during %dms.', szFilePath, GetTickCount() - nStartTick), DEBUG_LEVEL.PMLOG)
	--[[#DEBUG END]]
	return data
end

-- 加载数据文件
function LIB.LoadLUAData(oFilePath, tConfig)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTickCount()
	--[[#DEBUG END]]
	local config, szPassphrase, bNew = Clone(tConfig) or {}, nil, nil
	local szFilePath = LIB.GetLUADataPath(oFilePath)
	if IsNil(config.passphrase) then
		szPassphrase, bNew = GetLUADataPathPassphrase(szFilePath)
		if not bNew then
			config.passphrase = szPassphrase
		end
	end
	local data = LoadLUAData(szFilePath, config)
	if bNew and data then
		config.passphrase = szPassphrase
		SaveLUAData(szFilePath, data, config)
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug('PMTool', _L('%s loaded during %dms.', szFilePath, GetTickCount() - nStartTick), DEBUG_LEVEL.PMLOG)
	--[[#DEBUG END]]
	return data
end

-----------------------------------------------
-- 计算数据散列值
-----------------------------------------------
do
local function TableSorterK(a, b) return a.k > b.k end
local function GetLUADataHashSYNC(data)
	local szType = type(data)
	if szType == 'table' then
		local aChild = {}
		for k, v in pairs(data) do
			insert(aChild, { k = GetLUADataHashSYNC(k), v = GetLUADataHashSYNC(v) })
		end
		sort(aChild, TableSorterK)
		for i, v in ipairs(aChild) do
			aChild[i] = v.k .. ':' .. v.v
		end
		return GetLUADataHashSYNC('{}::' .. concat(aChild, ';'))
	end
	return tostring(GetStringCRC(szType .. ':' .. tostring(data)))
end

local function GetLUADataHash(data, fnAction)
	if not fnAction then
		return GetLUADataHashSYNC(data)
	end

	local __stack__ = {}
	local __retvals__ = {}

	local function __new_context__(continuation)
		local prev = __stack__[#__stack__]
		local current = {
			continuation = continuation,
			arguments = prev and prev.arguments,
			state = {},
			context = setmetatable({}, { __index = prev and prev.context }),
		}
		insert(__stack__, current)
		return current
	end

	local function __exit_context__()
		remove(__stack__)
	end

	local function __call__(...)
		insert(__stack__, {
			continuation = '0',
			arguments = {...},
			state = {},
			context = {},
		})
	end

	local function __return__(...)
		__exit_context__()
		__retvals__ = {...}
	end

	__call__(data)

	local current, continuation, arguments, state, context, timer

	timer = LIB.BreatheCall(function()
		local nTime = GetTime()

		while #__stack__ > 0 do
			current = __stack__[#__stack__]
			continuation = current.continuation
			arguments = current.arguments
			state = current.state
			context = current.context

			if continuation == '0' then
				if type(arguments[1]) == 'table' then
					__new_context__('1')
				else
					__return__(tostring(GetStringCRC(type(arguments[1]) .. ':' .. tostring(arguments[1]))))
				end
			elseif continuation == '1' then
				context.aChild = {}
				current.continuation = '1.1'
			elseif continuation == '1.1' then
				state.k = next(arguments[1], state.k)
				if state.k ~= nil then
					local nxt = __new_context__('2')
					nxt.context.k = state.k
					nxt.context.v = arguments[1][state.k]
				else
					sort(context.aChild, TableSorterK)
					for i, v in ipairs(context.aChild) do
						context.aChild[i] = v.k .. ':' .. v.v
					end
					__call__('{}::' .. concat(context.aChild, ';'))
					current.continuation = '1.2'
				end
			elseif continuation == '1.2' then
				__return__(unpack(__retvals__))
				__return__(unpack(__retvals__))
			elseif continuation == '2' then
				__call__(context.k)
				current.continuation = '2.1'
			elseif continuation == '2.1' then
				context.ks = __retvals__[1]
				__call__(context.v)
				current.continuation = '2.2'
			elseif continuation == '2.2' then
				context.vs = __retvals__[1]
				insert(context.aChild, { k = context.ks, v = context.vs })
				__exit_context__()
			end

			if GetTime() - nTime > 100 then
				return
			end
		end

		LIB.BreatheCall(timer, false)
		SafeCall(fnAction, unpack(__retvals__))
	end)
end
LIB.GetLUADataHash = GetLUADataHash
end

do
local DATABASE_TYPE_LIST = { PATH_TYPE.ROLE, PATH_TYPE.SERVER, PATH_TYPE.GLOBAL }
local DATABASE_INSTANCE = {}
local USER_SETTINGS_INFO = {}
local FLUSH_TIME = 0
local NEED_FLUSH = false

function LIB.ConnectSettingsDatabase()
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if not DATABASE_INSTANCE[ePathType] then
			DATABASE_INSTANCE[ePathType] = UnQLite_Open(LIB.FormatPath({'userdata/settings.udb', ePathType}))
		end
	end
end

function LIB.ReleaseSettingsDatabase()
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if DATABASE_INSTANCE[ePathType] then
			DATABASE_INSTANCE[ePathType]:Release()
			DATABASE_INSTANCE[ePathType] = nil
		end
	end
	NEED_FLUSH = false
end

function LIB.FlushSettingsDatabase()
	if not NEED_FLUSH then
		return
	end
	LIB.ReleaseSettingsDatabase()
	LIB.ConnectSettingsDatabase()
end

-- 注册单个用户配置项
-- @param {string} szKey 配置项全局唯一键
-- @param {table} tOption 自定义配置项
--   {PATH_TYPE} tOption.ePathType 配置项保存位置（当前角色、当前服务器、全局）
--   {string} tOption.szDataKey 配置项入库时的键值，一般不需要手动指定，默认与配置项全局键值一致
--   {string} tOption.szGroup 配置项分组组标题，用于导入导出显示，禁止导入导出请留空
--   {string} tOption.szLabel 配置标题，用于导入导出显示，禁止导入导出请留空
--   {string} tOption.szVersion 数据版本号，加载数据时会丢弃版本不一致的数据
--   {any} tOption.xDefaultValue 数据默认值
--   {schema} tOption.xSchema 数据类型约束对象，通过 Schema 库生成
--   {boolean} tOption.bDataSet 是否为配置项组（如用户多套自定义偏好），配置项组在读写时需要额外传入一个组下配置项唯一键值（即多套自定义偏好中某一项的名字）
function LIB.RegisterUserSettings(szKey, tOption)
	local ePathType, szDataKey, szGroup, szLabel, szVersion, xDefaultValue, xSchema, bDataSet
	if IsTable(tOption) then
		ePathType = tOption.ePathType
		szDataKey = tOption.szDataKey
		szGroup = tOption.szGroup
		szLabel = tOption.szLabel
		szVersion = tOption.szVersion
		xDefaultValue = tOption.xDefaultValue
		xSchema = tOption.xSchema
		bDataSet = tOption.bDataSet
	end
	if not ePathType then
		ePathType = PATH_TYPE.ROLE
	end
	if not szDataKey then
		szDataKey = szKey
	end
	local szErrHeader = 'RegisterUserSettings KEY(' .. EncodeLUAData(szKey) .. '): '
	assert(IsString(szKey) and #szKey > 0, szErrHeader .. '`Key` should be a non-empty string value.')
	assert(not USER_SETTINGS_INFO[szKey], szErrHeader .. 'duplicated `Key` found.')
	assert(IsString(szDataKey) and #szDataKey > 0, szErrHeader .. '`DataKey` should be a non-empty string value.')
	assert(not lodash.some(USER_SETTINGS_INFO, function(p) return p.szDataKey == szDataKey and p.ePathType == ePathType end), szErrHeader .. 'duplicated `DataKey` + `PathType` found.')
	assert(lodash.includes(DATABASE_TYPE_LIST, ePathType), szErrHeader .. '`PathType` value is not valid.')
	assert(IsNil(szGroup) or (IsString(szGroup) and #szGroup > 0), szErrHeader .. '`Group` should be nil or a non-empty string value.')
	assert(IsNil(szLabel) or (IsString(szLabel) and #szLabel > 0), szErrHeader .. '`Label` should be nil or a non-empty string value.')
	assert(IsNil(szVersion) or IsString(szVersion) or IsNumber(szVersion), szErrHeader .. '`Version` should be a nil, string or number value.')
	if xSchema then
		local errs = Schema.CheckSchema(xDefaultValue, xSchema)
		if errs then
			local aErrmsgs = {}
			for i, err in ipairs(errs) do
				insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
			end
			assert(false, szErrHeader .. '`DefaultValue` cannot pass `Schema` check.' .. '\n' .. concat(aErrmsgs, '\n'))
		end
	end
	USER_SETTINGS_INFO[szKey] = {
		szKey = szKey,
		ePathType = ePathType,
		szDataKey = szDataKey,
		szGroup = szGroup,
		szLabel = szLabel,
		szVersion = szVersion,
		xDefaultValue = xDefaultValue,
		xSchema = xSchema,
		bDataSet = bDataSet,
	}
end

function LIB.GetRegisterUserSettingsList()
	local aRes = {}
	for _, v in pairs(USER_SETTINGS_INFO) do
		insert(aRes, Clone(v))
	end
	return aRes
end

-- 获取用户配置项值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
-- @return 值
function LIB.GetUserSettings(szKey, ...)
	local nParameter = select('#', ...) + 1
	local szErrHeader = 'GetUserSettings KEY(' .. EncodeLUAData(szKey) .. '): '
	local info = USER_SETTINGS_INFO[szKey]
	assert(info, szErrHeader ..'`Key` has not been registered.')
	local db = DATABASE_INSTANCE[info.ePathType]
	assert(db, szErrHeader ..'Database not connected.')
	local szDataSetKey
	if info.bDataSet then
		assert(nParameter == 2, szErrHeader .. '2 parameters expected, got ' .. nParameter)
		szDataSetKey = ...
		assert(IsString(szDataSetKey) or IsNumber(szDataSetKey), szErrHeader ..'`DataSetKey` should be a string or number value.')
	else
		assert(nParameter == 1, szErrHeader .. '1 parameters expected, got ' .. nParameter)
	end
	local res = db:Get(info.szDataKey)
	if IsTable(res) and res.v == info.szVersion then
		local data = res.d
		if info.bDataSet then
			if IsTable(data) then
				data = data[szDataSetKey]
			else
				data = nil
			end
		end
		if info.xSchema then
			return LIB.SchemaGet(data, info.xSchema, info.xDefaultValue)
		end
		return data
	end
	return Clone(info.xDefaultValue)
end

-- 保存用户配置项值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
-- @param {unknown} xValue 值
function LIB.SetUserSettings(szKey, ...)
	local nParameter = select('#', ...) + 1
	local szErrHeader = 'SetUserSettings KEY(' .. EncodeLUAData(szKey) .. '): '
	local info = USER_SETTINGS_INFO[szKey]
	assert(info, szErrHeader .. '`Key` has not been registered.')
	local db = DATABASE_INSTANCE[info.ePathType]
	if not db and LIB.IsDebugClient() then
		LIB.Debug(PACKET_INFO.NAME_SPACE, szErrHeader .. 'Database not connected!!!', DEBUG_LEVEL.WARNING)
		return false
	end
	assert(db, szErrHeader .. 'Database not connected.')
	local szDataSetKey, xValue
	if info.bDataSet then
		assert(nParameter == 3, szErrHeader .. '3 parameters expected, got ' .. nParameter)
		szDataSetKey, xValue = ...
		assert(IsString(szDataSetKey) or IsNumber(szDataSetKey), szErrHeader ..'`DataSetKey` should be a string or number value.')
	else
		assert(nParameter == 2, szErrHeader .. '2 parameters expected, got ' .. nParameter)
		xValue = ...
	end
	if info.xSchema then
		local errs = Schema.CheckSchema(xValue, info.xSchema)
		if errs then
			local aErrmsgs = {}
			for i, err in ipairs(errs) do
				insert(aErrmsgs, i .. '. ' .. err.message)
			end
			assert(false, szErrHeader .. '' .. szKey .. ', schema check failed.\n' .. concat(aErrmsgs, '\n'))
		end
	end
	if info.bDataSet then
		local res = db:Get(info.szDataKey)
		if IsTable(res) and res.v == info.szVersion and IsTable(res.d) then
			res.d[szDataSetKey] = xValue
			xValue = res.d
		else
			xValue = { [szDataSetKey] = xValue }
		end
	end
	db:Set(info.szDataKey, { d = xValue, v = info.szVersion })
	NEED_FLUSH = true
	return true
end

-- 删除用户配置项值（恢复默认值）
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
function LIB.ResetUserSettings(szKey, ...)
	local nParameter = select('#', ...) + 1
	local szErrHeader = 'ResetUserSettings KEY(' .. EncodeLUAData(szKey) .. '): '
	local info = USER_SETTINGS_INFO[szKey]
	assert(info, szErrHeader .. '`Key` has not been registered.')
	local db = DATABASE_INSTANCE[info.ePathType]
	assert(db, szErrHeader .. 'Database not connected.')
	local szDataSetKey
	if info.bDataSet then
		assert(nParameter == 1 or nParameter == 2, szErrHeader .. '1 or 2 parameter(s) expected, got ' .. nParameter)
		szDataSetKey = ...
		assert(IsString(szDataSetKey) or IsNumber(szDataSetKey) or IsNil(szDataSetKey), szErrHeader ..'`DataSetKey` should be a string or number or nil value.')
	else
		assert(nParameter == 1, szErrHeader .. '1 parameters expected, got ' .. nParameter)
	end
	if info.bDataSet then
		local res = db:Get(info.szDataKey)
		if IsTable(res) and res.v == info.szVersion and IsTable(res.d) and szDataSetKey then
			res.d[szDataSetKey] = nil
			if IsEmpty(res.d) then
				db:Delete(info.szDataKey)
			else
				db:Set(info.szDataKey, res)
			end
		else
			db:Delete(info.szDataKey)
		end
	else
		db:Delete(info.szDataKey)
	end
	NEED_FLUSH = true
end

-- 创建用户设置代理对象
-- @param {string | table} xProxy 配置项代理表（ alias => globalKey ），或模块命名空间
-- @return 配置项读写代理对象
function LIB.CreateUserSettingsProxy(xProxy)
	local tSettings = {}
	local tDataSet = {}
	local tLoaded = {}
	local tProxy = IsTable(xProxy) and xProxy or {}
	for k, v in pairs(tProxy) do
		assert(IsString(k), '`Key` ' .. EncodeLUAData(k) .. ' of proxy should be a string value.')
		assert(IsString(v), '`Val` ' .. EncodeLUAData(v) .. ' of proxy should be a string value.')
	end
	local function GetGlobalKey(k)
		if not tProxy[k] then
			if IsString(xProxy) then
				tProxy[k] = xProxy .. '.' .. k
			end
			assert(tProxy[k], '`Key` ' .. EncodeLUAData(k) .. ' not found in proxy table.')
		end
		return tProxy[k]
	end
	return setmetatable({}, {
		__index = function(_, k)
			if not tLoaded[k] then
				local info = USER_SETTINGS_INFO[k]
				if info and info.bDataSet then
					-- 配置项组，初始化读写模块
					local tDSSettings = {}
					local tDSLoaded = {}
					tDataSet[k] = setmetatable({}, {
						__index = function(_, kds)
							if not tDSLoaded[kds] then
								tDSSettings[kds] = LIB.GetUserSettings(GetGlobalKey(k), kds)
								tDSLoaded[kds] = true
							end
							return tDSSettings[kds]
						end,
						__newindex = function(_, kds, vds)
							if not LIB.SetUserSettings(GetGlobalKey(k), kds, vds) then
								return
							end
							tDSSettings[kds] = vds
							tDSLoaded[kds] = true
						end,
					})
				else
					-- 普通数据，加载数据内容
					tSettings[k] = LIB.GetUserSettings(GetGlobalKey(k))
				end
				tLoaded[k] = true
			end
			return tDataSet[k] or tSettings[k]
		end,
		__newindex = function(_, k, v)
			if not LIB.SetUserSettings(GetGlobalKey(k), v) then
				return
			end
			tSettings[k] = v
			tLoaded[k] = true
		end,
		__call = function(_, cmd, arg0)
			if cmd == 'reset' then
				if not IsTable(arg0) then
					arg0 = {}
					for k, _ in pairs(tProxy) do
						insert(arg0, k)
					end
				end
				for _, k in ipairs(arg0) do
					LIB.ResetUserSettings(GetGlobalKey(k))
				end
			end
		end,
	})
end

-- 创建模块用户配置项表，并获得代理对象
-- @param {string} szModule 模块命名空间
-- @param {string} *szGroupLabel 模块标题
-- @param {table} tSettings 模块用户配置表
-- @return 配置项读写代理对象
function LIB.CreateUserSettingsModule(szModule, szGroupLabel, tSettings)
	if IsTable(szGroupLabel) then
		szGroupLabel, tSettings = nil, szGroupLabel
	end
	local tProxy = {}
	for k, v in pairs(tSettings) do
		local szKey = szModule .. '.' .. k
		local tOption = Clone(v)
		if tOption.szDataKey then
			tOption.szDataKey = szModule .. '.' .. tOption.szDataKey
		end
		if szGroupLabel then
			tOption.szGroup = szGroupLabel
		end
		LIB.RegisterUserSettings(szKey, tOption)
		tProxy[k] = szKey
	end
	return LIB.CreateUserSettingsProxy(tProxy)
end

LIB.RegisterIdle(NSFormatString('{$NS}#FlushSettingsDatabase'), function()
	if GetCurrentTime() - FLUSH_TIME > 60 then
		LIB.FlushSettingsDatabase()
		FLUSH_TIME = GetCurrentTime()
	end
end)
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

do local CREATED = {}
function LIB.CreateDataRoot(ePathType)
	if CREATED[ePathType] then
		return
	end
	CREATED[ePathType] = true
	-- 创建目录
	if ePathType == PATH_TYPE.ROLE then
		CPath.MakeDir(LIB.FormatPath({'{$name}/', PATH_TYPE.ROLE}))
	end
	-- 版本更新时删除旧的临时目录
	if IsLocalFileExist(LIB.FormatPath({'temporary/', ePathType}))
	and not IsLocalFileExist(LIB.FormatPath({'temporary/{$version}', ePathType})) then
		CPath.DelDir(LIB.FormatPath({'temporary/', ePathType}))
	end
	CPath.MakeDir(LIB.FormatPath({'temporary/{$version}/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'audio/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'cache/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'config/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'export/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'font/', ePathType}))
	CPath.MakeDir(LIB.FormatPath({'userdata/', ePathType}))
end
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

do
-- total bytes: 32
local l_tBoolValues = {
	-- KEY = OFFSET
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

local SetOnlineAddonCustomData = _G.SetOnlineAddonCustomData or SetAddonCustomData
function LIB.SetStorage(szKey, ...)
	if GLOBAL.GAME_EDITION == 'classic' then
		local oFilePath = {'userdata/localstorage.jx3dat', PATH_TYPE.ROLE}
		local data = LIB.LoadLUAData(oFilePath) or {}
		data[szKey] = {...}
		LIB.SaveLUAData(oFilePath, data)
		return
	end
	local szPriKey, szSubKey = szKey, nil
	local nPos = StringFindW(szKey, '.')
	if nPos then
		szSubKey = sub(szKey, nPos + 1)
		szPriKey = sub(szKey, 1, nPos - 1)
	end
	if szPriKey == 'BoolValues' then
		local nBitPos = l_tBoolValues[szSubKey]
		if not nBitPos then
			return
		end
		local oVal = ...
		local nPos = floor(nBitPos / BIT_NUMBER)
		local nOffset = BIT_NUMBER - nBitPos % BIT_NUMBER - 1
		local nByte = GetAddonCustomData(PACKET_INFO.NAME_SPACE, nPos, 1)
		local nBit = floor(nByte / pow(2, nOffset)) % 2
		if (nBit == 1) == (not not oVal) then
			return
		end
		nByte = nByte + (nBit == 1 and -1 or 1) * pow(2, nOffset)
		SetAddonCustomData(PACKET_INFO.NAME_SPACE, nPos, 1, nByte)
	elseif szPriKey == 'FrameAnchor' then
		local anchor = ...
		return SetOnlineFrameAnchor(szSubKey, anchor)
	end
	OnStorageChange(szKey)
end

local GetOnlineAddonCustomData = _G.GetOnlineAddonCustomData or GetAddonCustomData
function LIB.GetStorage(szKey)
	if GLOBAL.GAME_EDITION == 'classic' then
		local oFilePath = {'userdata/localstorage.jx3dat', PATH_TYPE.ROLE}
		local data = LIB.LoadLUAData(oFilePath) or {}
		return unpack(data[szKey] or {})
	end
	local szPriKey, szSubKey = szKey, nil
	local nPos = StringFindW(szKey, '.')
	if nPos then
		szSubKey = sub(szKey, nPos + 1)
		szPriKey = sub(szKey, 1, nPos - 1)
	end
	if szPriKey == 'BoolValues' then
		local nBitPos = l_tBoolValues[szSubKey]
		if not nBitPos then
			return
		end
		local nPos = floor(nBitPos / BIT_NUMBER)
		local nOffset = BIT_NUMBER - nBitPos % BIT_NUMBER - 1
		local nByte = GetAddonCustomData(PACKET_INFO.NAME_SPACE, nPos, 1)
		local nBit = floor(nByte / pow(2, nOffset)) % 2
		return nBit == 1
	elseif szPriKey == 'FrameAnchor' then
		return GetOnlineFrameAnchor(szSubKey)
	end
end

-- 判断用户是否同步了设置项（ESC-游戏设置-综合-服务器同步设置-界面常规设置）
function LIB.IsRemoteStorage()
	local n = (GetUserPreferences(4347, 'c') + 1) % 256
	SetOnlineAddonCustomData(PACKET_INFO.NAME_SPACE, 31, 1, n)
	return GetUserPreferences(4347, 'c') == n
end

function LIB.WatchStorage(szKey, fnAction)
	if not l_watches[szKey] then
		l_watches[szKey] = {}
	end
	insert(l_watches[szKey], fnAction)
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
		local res, err, trace = XpCall(fnAction)
		if not res then
			FireUIEvent('CALL_LUA_ERROR', err .. '\nINIT_FUNC_LIST: ' .. szKey .. '\n' .. trace .. '\n')
		end
	end
	INIT_FUNC_LIST = {}
end
LIB.RegisterInit('LIB#Storage', OnInit)
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

do
local nIndex = 0
function LIB.Alert(szName, szMsg, fnAction, szSure, fnCancelAction, nCountDownTime)
	if IsFunction(szMsg) or IsNil(szMsg) then
		szMsg, fnAction, szSure, fnCancelAction, nCountDownTime = szName, szMsg, fnAction, szSure, fnCancelAction
		szName = NSFormatString('{$NS}_Alert') .. nIndex
		nIndex = nIndex + 1
	else
		szName = NSFormatString('{$NS}_AlertCRC') .. GetStringCRC(szName)
	end
	local nW, nH = Station.GetClientSize()
	if fnCancelAction == 'FORBIDDEN' then
		fnCancelAction = function()
			LIB.DelayCall(function()
				LIB.Alert(szName, szMsg, fnAction, szSure, fnCancelAction, nCountDownTime)
			end)
		end
	end
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = szName,
		szMessage = szMsg,
		szAlignment = 'CENTER',
		fnCancelAction = fnCancelAction,
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
			bDelayCountDown = nCountDownTime and true or false,
			nCountDownTime = nCountDownTime,
		},
	}
	MessageBox(tMsg)
	return szName
end
end

function LIB.Confirm(szMsg, fnAction, fnCancel, szSure, szCancel, fnCancelAction)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = NSFormatString('{$NS}_Confirm'),
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
		szName = NSFormatString('{$NS}_Dialog'),
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

local function DuplicateDatabase(DB_SRC, DB_DST, szCaption)
	--[[#DEBUG BEGIN]]
	LIB.Debug(szCaption, 'Duplicate database start.', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	-- 运行 DDL 语句 创建表和索引等
	for _, rec in ipairs(DB_SRC:Execute('SELECT sql FROM sqlite_master')) do
		DB_DST:Execute(rec.sql)
		--[[#DEBUG BEGIN]]
		LIB.Debug(szCaption, 'Duplicating database: ' .. rec.sql, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
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
		--[[#DEBUG BEGIN]]
		LIB.Debug(szCaption, 'Duplicating table: ' .. szTableName .. ' (cols)' .. szColumns .. ' (count)' .. nCount, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
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
		--[[#DEBUG BEGIN]]
		LIB.Debug(szCaption, 'Duplicating table finished: ' .. szTableName, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end

local function ConnectMalformedDatabase(szCaption, szPath, bAlert)
	--[[#DEBUG BEGIN]]
	LIB.Debug(szCaption, 'Fixing malformed database...', DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local szMalformedPath = RenameDatabase(szCaption, szPath)
	if not szMalformedPath then
		--[[#DEBUG BEGIN]]
		LIB.Debug(szCaption, 'Fixing malformed database failed... Move file failed...', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		return 'FILE_LOCKED'
	else
		local DB_DST = SQLite3_Open(szPath)
		local DB_SRC = SQLite3_Open(szMalformedPath)
		if DB_DST and DB_SRC then
			DuplicateDatabase(DB_SRC, DB_DST, szCaption)
			DB_SRC:Release()
			CPath.DelFile(szMalformedPath)
			--[[#DEBUG BEGIN]]
			LIB.Debug(szCaption, 'Fixing malformed database finished...', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return 'SUCCESS', DB_DST
		elseif not DB_SRC then
			--[[#DEBUG BEGIN]]
			LIB.Debug(szCaption, 'Connect malformed database failed...', DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return 'TRANSFER_FAILED', DB_DST
		end
	end
end

function LIB.ConnectDatabase(szCaption, oPath, fnAction)
	-- 尝试连接数据库
	local szPath = LIB.FormatPath(oPath)
	--[[#DEBUG BEGIN]]
	LIB.Debug(szCaption, 'Connect database: ' .. szPath, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local DB = SQLite3_Open(szPath)
	if not DB then
		-- 连不上直接重命名原始文件并重新连接
		if IsLocalFileExist(szPath) and RenameDatabase(szCaption, szPath) then
			DB = SQLite3_Open(szPath)
		end
		if not DB then
			LIB.Debug(szCaption, 'Cannot connect to database!!!', DEBUG_LEVEL.ERROR)
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
		-- 记录错误日志
		LIB.Debug(szCaption, 'Malformed database detected...', DEBUG_LEVEL.ERROR)
		for _, rec in ipairs(aRes or {}) do
			LIB.Debug(szCaption, EncodeLUAData(rec), DEBUG_LEVEL.ERROR)
		end
		DB:Release()
		-- 准备尝试修复
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
local function FormatModuleProxy(options)
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
	local exportEntries, exportInterceptors, exportTriggers = FormatModuleProxy(options.exports)
	local importEntries, importInterceptors, importTriggers = FormatModuleProxy(options.imports)
	local function getter(_, k)
		if not exportEntries[k] then
			local errmsg = 'Module `' .. name .. '`: get value failed, unregistered properity `' .. k .. '`.'
			if LIB.IsDebugClient() then
				LIB.Debug(PACKET_INFO.NAME_SPACE, errmsg, DEBUG_LEVEL.WARNING)
				return
			end
			assert(false, errmsg)
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
			local errmsg = 'Module `' .. name .. '` set value failed, unregistered properity `' .. k .. '`.'
			if LIB.IsDebugClient() then
				LIB.Debug(PACKET_INFO.NAME_SPACE, errmsg, DEBUG_LEVEL.WARNING)
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
	return setmetatable({}, { __index = getter, __newindex = setter })
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
		LIB.RegisterMsgMonitor('MSG_SYS.LIB#GetTimeOfFee', function(szChannel, szMsg)
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
				LIB.RegisterMsgMonitor('MSG_SYS.LIB#GetTimeOfFee', false)
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
RegisterEvent('CALL_LUA_ERROR', function()
	local szMsg = arg0
	local szMsgL = wgsub(arg0:lower(), '\\', '/')
	if wfind(szMsgL, KEY) then
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
			LIB.RegisterEvent(szEvent .. '.' .. szKey, Flush)
		end
	end
	local function Unregister()
		for _, szEvent in ipairs(aEvent) do
			LIB.RegisterEvent(szEvent .. '.' .. szKey, false)
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
