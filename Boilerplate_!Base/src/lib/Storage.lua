--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 用户配置
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
---------------------------------------------------------------------------------------------
-- 用户配置项
---------------------------------------------------------------------------------------------
local USER_SETTINGS_EVENT = { szName = 'UserSettings' }
local CommonEventFirer = LIB.CommonEventFirer
local CommonEventRegister = LIB.CommonEventRegister

function LIB.RegisterUserSettingsUpdate(...)
	return CommonEventRegister(USER_SETTINGS_EVENT, ...)
end

local DATABASE_TYPE_LIST = { PATH_TYPE.ROLE, PATH_TYPE.SERVER, PATH_TYPE.GLOBAL }
local DATABASE_INSTANCE = {}
local DATABASE_NEED_FLUSH = {}
local USER_SETTINGS_INFO = {}
local USER_SETTINGS_LIST = {}
local DATA_CACHE = {}
local DATA_CACHE_LEAF_FLAG = {}
local FLUSH_TIME = 0

function LIB.ConnectSettingsDatabase()
	local bFireEvent = false
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if not DATABASE_INSTANCE[ePathType] then
			local szPath = LIB.FormatPath({'userdata/settings.udb', ePathType})
			if ePathType == PATH_TYPE.ROLE then
				local szID = LIB.GetUserSettingsPresetID()
				if szID then
					szPath = LIB.FormatPath({'userdata/settings/' .. szID .. '/', PATH_TYPE.GLOBAL})
					CPath.MakeDir(szPath)
					szPath = szPath .. 'role.udb'
				end
			end
			DATABASE_INSTANCE[ePathType] = LIB.UnQLiteConnect(szPath)
			bFireEvent = true
		end
	end
	if bFireEvent then
		CommonEventFirer(USER_SETTINGS_EVENT, '@@INIT@@')
	end
end

function LIB.ReleaseSettingsDatabase()
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if DATABASE_INSTANCE[ePathType] then
			LIB.UnQLiteDisconnect(DATABASE_INSTANCE[ePathType])
			DATABASE_INSTANCE[ePathType] = nil
			DATABASE_NEED_FLUSH[ePathType] = nil
		end
	end
end

function LIB.FlushSettingsDatabase()
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if DATABASE_INSTANCE[ePathType] and DATABASE_NEED_FLUSH[ePathType] and DATABASE_INSTANCE[ePathType].Commit then
			DATABASE_INSTANCE[ePathType]:Commit()
			DATABASE_NEED_FLUSH[ePathType] = nil
		end
	end
end

function LIB.GetUserSettingsPresetID()
	local szID = LIB.LoadLUAData({'config/usersettings-preset.jx3dat', PATH_TYPE.ROLE})
	if IsString(szID) and not szID:find('[/?*:|\\<>]') then
		return szID
	end
end

function LIB.SetUserSettingsPresetID(szID)
	if szID then
		if szID:find('[/?*:|\\<>]') then
			return _L['User settings preset id cannot contains special character (/?*:|\\<>).']
		end
		szID = wgsub(szID, '^%s+', '')
		szID = wgsub(szID, '%s+$', '')
	end
	if IsEmpty(szID) then
		szID = nil
	end
	if szID == LIB.GetUserSettingsPresetID() then
		return
	end
	LIB.SaveLUAData({'config/usersettings-preset.jx3dat', PATH_TYPE.ROLE}, szID)
	local db = DATABASE_INSTANCE[PATH_TYPE.ROLE]
	if db then
		LIB.UnQLiteDisconnect(db)
		DATABASE_INSTANCE[PATH_TYPE.ROLE] = nil
		DATABASE_NEED_FLUSH[PATH_TYPE.ROLE] = nil
		LIB.ConnectSettingsDatabase()
	end
end

function LIB.GetUserSettingsPresetList()
	return CPath.GetFolderList(LIB.FormatPath({'userdata/settings/', PATH_TYPE.GLOBAL}))
end

function LIB.RemoveUserSettingsPreset(szID)
	CPath.DelDir(LIB.FormatPath({'userdata/settings/' .. szID .. '/', PATH_TYPE.GLOBAL}))
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
--   {table} tOption.tDataSetDefaultValue 数据默认值（仅当 bDataSet 为真时生效，用于设置配置项组不同默认值）
function LIB.RegisterUserSettings(szKey, tOption)
	local ePathType, szDataKey, szGroup, szLabel, szVersion, xDefaultValue, xSchema, bDataSet, tDataSetDefaultValue
	if IsTable(tOption) then
		ePathType = tOption.ePathType
		szDataKey = tOption.szDataKey
		szGroup = tOption.szGroup
		szLabel = tOption.szLabel
		szVersion = tOption.szVersion
		xDefaultValue = tOption.xDefaultValue
		xSchema = tOption.xSchema
		bDataSet = tOption.bDataSet
		tDataSetDefaultValue = tOption.tDataSetDefaultValue
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
		if bDataSet then
			tDataSetDefaultValue = IsTable(tDataSetDefaultValue)
				and Clone(tDataSetDefaultValue)
				or {}
			local errs = Schema.CheckSchema(tDataSetDefaultValue, Schema.Map(Schema.Any, xSchema))
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				assert(false, szErrHeader .. '`DataSetDefaultValue` cannot pass `Schema` check.' .. '\n' .. concat(aErrmsgs, '\n'))
			end
		end
	end
	local tInfo = {
		szKey = szKey,
		ePathType = ePathType,
		szDataKey = szDataKey,
		szGroup = szGroup,
		szLabel = szLabel,
		szVersion = szVersion,
		xDefaultValue = xDefaultValue,
		xSchema = xSchema,
		bDataSet = bDataSet,
		tDataSetDefaultValue = tDataSetDefaultValue,
	}
	USER_SETTINGS_INFO[szKey] = tInfo
	insert(USER_SETTINGS_LIST, tInfo)
end

function LIB.GetRegisterUserSettingsList()
	return Clone(USER_SETTINGS_LIST)
end

function LIB.ExportUserSettings(aKey)
	local tKvp = {}
	for _, szKey in ipairs(aKey) do
		local info = USER_SETTINGS_INFO[szKey]
		local db = info and DATABASE_INSTANCE[info.ePathType]
		if db then
			tKvp[szKey] = db:Get(info.szDataKey)
		end
	end
	return tKvp
end

function LIB.ImportUserSettings(tKvp)
	local nSuccess = 0
	for szKey, xValue in pairs(tKvp) do
		local info = USER_SETTINGS_INFO[szKey]
		local db = info and DATABASE_INSTANCE[info.ePathType]
		if db then
			nSuccess = nSuccess + 1
			db:Set(info.szDataKey, xValue)
			DATA_CACHE[szKey] = nil
		end
	end
	CommonEventFirer(USER_SETTINGS_EVENT, '@@INIT@@')
	return nSuccess
end

-- 获取用户配置项值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
-- @return 值
function LIB.GetUserSettings(szKey, ...)
	-- 缓存加速
	local cache = DATA_CACHE
	for _, k in ipairs({...}) do
		cache = IsTable(cache) and cache[k]
	end
	if IsTable(cache) and cache[1] == DATA_CACHE_LEAF_FLAG then
		return cache[2]
	end
	-- 参数检查
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
	-- 读数据库
	local res, bData = db:Get(info.szDataKey), false
	if IsTable(res) and res.v == info.szVersion then
		local data = res.d
		if info.bDataSet then
			if IsTable(data) then
				data = data[szDataSetKey]
			else
				data = nil
			end
		end
		if not info.xSchema or not Schema.CheckSchema(data, info.xSchema) then
			bData = true
			res = data
		end
	end
	-- 默认值
	if not bData then
		if info.bDataSet then
			res = info.tDataSetDefaultValue[szDataSetKey]
			if IsNil(res) then
				res = info.xDefaultValue
			end
		else
			res = info.xDefaultValue
		end
		res = Clone(res)
	end
	-- 缓存
	if info.bDataSet then
		if not DATA_CACHE[szKey] then
			DATA_CACHE[szKey] = {}
		end
		DATA_CACHE[szKey][szDataSetKey] = { DATA_CACHE_LEAF_FLAG, res }
	else
		DATA_CACHE[szKey] = { DATA_CACHE_LEAF_FLAG, res }
	end
	return res
end

-- 保存用户配置项值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
-- @param {unknown} xValue 值
function LIB.SetUserSettings(szKey, ...)
	-- 参数检查
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
	-- 数据校验
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
	-- 写数据库
	if info.bDataSet then
		local res = db:Get(info.szDataKey)
		if IsTable(res) and res.v == info.szVersion and IsTable(res.d) then
			res.d[szDataSetKey] = xValue
			xValue = res.d
		else
			xValue = { [szDataSetKey] = xValue }
		end
		if not DATA_CACHE[szKey] then
			DATA_CACHE[szKey] = {}
		end
		DATA_CACHE[szKey][szDataSetKey] = { DATA_CACHE_LEAF_FLAG, xValue[szDataSetKey] }
	else
		DATA_CACHE[szKey] = { DATA_CACHE_LEAF_FLAG, xValue }
	end
	db:Set(info.szDataKey, { d = xValue, v = info.szVersion })
	DATABASE_NEED_FLUSH[info.ePathType] = true
	CommonEventFirer(USER_SETTINGS_EVENT, szKey)
	return true
end

-- 删除用户配置项值（恢复默认值）
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
function LIB.ResetUserSettings(szKey, ...)
	-- 参数检查
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
	-- 写数据库
	if info.bDataSet then
		local res = db:Get(info.szDataKey)
		if IsTable(res) and res.v == info.szVersion and IsTable(res.d) and szDataSetKey then
			res.d[szDataSetKey] = nil
			if IsEmpty(res.d) then
				db:Delete(info.szDataKey)
			else
				db:Set(info.szDataKey, res)
			end
			if DATA_CACHE[szKey] then
				DATA_CACHE[szKey][szDataSetKey] = nil
			end
		else
			db:Delete(info.szDataKey)
			DATA_CACHE[szKey] = nil
		end
	else
		db:Delete(info.szDataKey)
		DATA_CACHE[szKey] = nil
	end
	DATABASE_NEED_FLUSH[info.ePathType] = true
	CommonEventFirer(USER_SETTINGS_EVENT, szKey)
end

-- 创建用户设置代理对象
-- @param {string | table} xProxy 配置项代理表（ alias => globalKey ），或模块命名空间
-- @return 配置项读写代理对象
function LIB.CreateUserSettingsProxy(xProxy)
	local tDataSetProxy = {}
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
			local szGlobalKey = GetGlobalKey(k)
			if not tLoaded[k] then
				local info = USER_SETTINGS_INFO[szGlobalKey]
				if info and info.bDataSet then
					-- 配置项组，初始化读写模块
					tDataSetProxy[k] = setmetatable({}, {
						__index = function(_, kds)
							return LIB.GetUserSettings(szGlobalKey, kds)
						end,
						__newindex = function(_, kds, vds)
							LIB.SetUserSettings(szGlobalKey, kds, vds)
						end,
					})
				end
				tLoaded[k] = true
			end
			return tDataSetProxy[k] or LIB.GetUserSettings(szGlobalKey)
		end,
		__newindex = function(_, k, v)
			LIB.SetUserSettings(GetGlobalKey(k), v)
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

------------------------------------------------------------------------------
-- 格式化数据
------------------------------------------------------------------------------

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

------------------------------------------------------------------------------
-- 官方角色设置自定义二进制位
------------------------------------------------------------------------------

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

------------------------------------------------------------------------------
-- UnQLite 数据库
------------------------------------------------------------------------------
do
local UNQLITE_POOL = {} -- 连接池，有BUG，不能断开连接，不然会挂。
function LIB.UnQLiteConnect(oPath)
	local szPath = LIB.FormatPath(oPath)
	if not UNQLITE_POOL[szPath] then
		UNQLITE_POOL[szPath] = UnQLite_Open(szPath)
	end
	return UNQLITE_POOL[szPath]
end

function LIB.UnQLiteDisconnect(db)
	-- 有BUG，不能断开连接，不然会挂。
	-- 已修复，等待 KGUI 更新即可。
	for k, v in pairs(UNQLITE_POOL) do
		if v == db then
			UNQLITE_POOL[k] = nil
			break
		end
	end
	db:Release()
end
end

------------------------------------------------------------------------------
-- SQLite 数据库
------------------------------------------------------------------------------

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

function LIB.SQLiteConnect(szCaption, oPath, fnAction)
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
