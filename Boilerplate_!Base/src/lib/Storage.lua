--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 用户配置
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Storage')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local EncodeByteData = X.GetGameAPI('EncodeByteData')
local DecodeByteData = X.GetGameAPI('DecodeByteData')

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
if IsLocalFileExist(X.PACKET_INFO.ROOT .. '@DATA/') then
	CPath.Move(X.PACKET_INFO.ROOT .. '@DATA/', X.PACKET_INFO.DATA_ROOT)
end

-- 格式化数据文件路径（替换{$uid}、{$lang}、{$server}以及补全相对路径）
-- (string) X.GetLUADataPath(oFilePath)
--   当路径为绝对路径时(以斜杠开头)不作处理
--   当路径为相对路径时 相对于插件`{NS}#DATA`目录
--   可以传入表{szPath, ePathType}
local PATH_TYPE_MOVE_STATE = {
	[X.PATH_TYPE.GLOBAL] = 'PENDING',
	[X.PATH_TYPE.ROLE] = 'PENDING',
	[X.PATH_TYPE.SERVER] = 'PENDING',
}
function X.FormatPath(oFilePath, tParams)
	if not tParams then
		tParams = {}
	end
	local szFilePath, ePathType
	if type(oFilePath) == 'table' then
		szFilePath, ePathType = X.Unpack(oFilePath)
	else
		szFilePath, ePathType = oFilePath, X.PATH_TYPE.NORMAL
	end
	-- 兼容旧版数据位置
	if PATH_TYPE_MOVE_STATE[ePathType] == 'PENDING' then
		PATH_TYPE_MOVE_STATE[ePathType] = nil
		local szPath = X.FormatPath({'', ePathType})
		if not IsLocalFileExist(szPath) then
			local szOriginPath
			if ePathType == X.PATH_TYPE.GLOBAL then
				szOriginPath = X.FormatPath({'!all-users@{$lang}/', X.PATH_TYPE.DATA})
			elseif ePathType == X.PATH_TYPE.ROLE then
				szOriginPath = X.FormatPath({'{$uid}@{$lang}/', X.PATH_TYPE.DATA})
			elseif ePathType == X.PATH_TYPE.SERVER then
				szOriginPath = X.FormatPath({'#{$relserver}@{$lang}/', X.PATH_TYPE.DATA})
			end
			if IsLocalFileExist(szOriginPath) then
				CPath.Move(szOriginPath, szPath)
			end
		end
	end
	-- Unified the directory separator
	szFilePath = string.gsub(szFilePath, '\\', '/')
	-- if it's relative path then complete path with '/{NS}#DATA/'
	if szFilePath:sub(2, 3) ~= ':/' then
		if ePathType == X.PATH_TYPE.DATA then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. szFilePath
		elseif ePathType == X.PATH_TYPE.GLOBAL then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. '!all-users@{$edition}/' .. szFilePath
		elseif ePathType == X.PATH_TYPE.ROLE then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. '{$uid}@{$edition}/' .. szFilePath
		elseif ePathType == X.PATH_TYPE.SERVER then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. '#{$relserver}@{$edition}/' .. szFilePath
		end
	end
	-- if exist {$uid} then add user role identity
	if string.find(szFilePath, '{$uid}', nil, true) then
		szFilePath = szFilePath:gsub('{%$uid}', tParams['uid'] or X.GetPlayerGUID())
	end
	-- if exist {$name} then add user role identity
	if string.find(szFilePath, '{$name}', nil, true) then
		szFilePath = szFilePath:gsub('{%$name}', tParams['name'] or X.GetClientInfo().szName)
	end
	-- if exist {$lang} then add language identity
	if string.find(szFilePath, '{$lang}', nil, true) then
		szFilePath = szFilePath:gsub('{%$lang}', tParams['lang'] or X.ENVIRONMENT.GAME_LANG)
	end
	-- if exist {$edition} then add edition identity
	if string.find(szFilePath, '{$edition}', nil, true) then
		szFilePath = szFilePath:gsub('{%$edition}', tParams['edition'] or X.ENVIRONMENT.GAME_EDITION)
	end
	-- if exist {$branch} then add branch identity
	if string.find(szFilePath, '{$branch}', nil, true) then
		szFilePath = szFilePath:gsub('{%$branch}', tParams['branch'] or X.ENVIRONMENT.GAME_BRANCH)
	end
	-- if exist {$version} then add version identity
	if string.find(szFilePath, '{$version}', nil, true) then
		szFilePath = szFilePath:gsub('{%$version}', tParams['version'] or X.ENVIRONMENT.GAME_VERSION)
	end
	-- if exist {$date} then add date identity
	if string.find(szFilePath, '{$date}', nil, true) then
		szFilePath = szFilePath:gsub('{%$date}', tParams['date'] or X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd'))
	end
	-- if exist {$server} then add server identity
	if string.find(szFilePath, '{$server}', nil, true) then
		szFilePath = szFilePath:gsub('{%$server}', tParams['server'] or ((X.GetServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- if exist {$relserver} then add relserver identity
	if string.find(szFilePath, '{$relserver}', nil, true) then
		szFilePath = szFilePath:gsub('{%$relserver}', tParams['relserver'] or ((X.GetRealServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	local rootPath = GetRootPath():gsub('\\', '/')
	if szFilePath:find(rootPath) == 1 then
		szFilePath = szFilePath:gsub(rootPath, '.')
	end
	return szFilePath
end

function X.GetRelativePath(oPath, oRoot)
	local szPath = X.FormatPath(oPath):gsub('^%./', '')
	local szRoot = X.FormatPath(oRoot):gsub('^%./', '')
	local szRootPath = GetRootPath():gsub('\\', '/')
	if szPath:sub(2, 2) ~= ':' then
		szPath = X.ConcatPath(szRootPath, szPath)
	end
	if szRoot:sub(2, 2) ~= ':' then
		szRoot = X.ConcatPath(szRootPath, szRoot)
	end
	szRoot = szRoot:gsub('/$', '') .. '/'
	if X.StringFindW(szPath:lower(), szRoot:lower()) ~= 1 then
		return
	end
	return szPath:sub(#szRoot + 1)
end

function X.GetAbsolutePath(oPath)
	local szPath = X.FormatPath(oPath)
	if szPath:sub(2, 2) == ':' then
		return szPath
	end
	return X.NormalizePath(GetRootPath():gsub('\\', '/') .. '/' .. X.GetRelativePath(szPath, {'', X.PATH_TYPE.NORMAL}):gsub('^[./\\]*', ''))
end

function X.GetLUADataPath(oFilePath)
	local szFilePath = X.FormatPath(oFilePath)
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

function X.ConcatPath(...)
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
function X.NormalizePath(szPath)
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
function X.GetParentPath(szPath)
	return X.NormalizePath(szPath):gsub('/[^/]*$', '')
end

function X.OpenFolder(szPath)
	local OpenFolder = X.GetGameAPI('OpenFolder')
	if X.IsFunction(OpenFolder) then
		OpenFolder(szPath)
	else
		X.SafeCall(SetDataToClip, szPath)
		X.UI.OpenTextEditor(szPath)
	end
end

function X.IsURL(szURL)
	return szURL:sub(1, 8):lower() == 'https://' or szURL:gsub(1, 7):lower() == 'http://'
end

-- 插件数据存储默认密钥
local GetLUADataPathPassphrase
do
local function GetPassphrase(nSeed, nLen)
	local a = {}
	local b, c = 0x20, 0x7e - 0x20 + 1
	for i = 1, nLen do
		table.insert(a, ((i + nSeed) % 256 * (2 * i + nSeed) % 32) % c + b)
	end
	return string.char(X.Unpack(a))
end
local szDataRoot = StringLowerW(X.FormatPath({'', X.PATH_TYPE.DATA}))
local szPassphrase = GetPassphrase(666, 233)
local szPassphraseSalted = X.SECRET['@@LUA_DATA_MANIFEST_SALT@@']
	and (X.KGUIEncrypt(X.SECRET['@@LUA_DATA_MANIFEST_SALT@@']) .. szPassphrase)
	or szPassphrase
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
	local nPos = X.StringFindW(szPath, '/')
	if not nPos or nPos == 1 then
		return
	end
	local szDomain = szPath:sub(1, nPos)
	szPath = szPath:sub(nPos + 1)
	-- 过滤不需要加密的地址
	local nPos = X.StringFindW(szPath, '/')
	if nPos then
		if szPath:sub(1, nPos - 1) == 'export' then
			return
		end
	end
	-- 获取或创建密钥
	local bNew = false
	if not CACHE[szDomain] or not CACHE[szDomain][szPath] then
		local szFilePath = szDataRoot .. szDomain .. '/manifest.jx3dat'
		CACHE[szDomain] = LoadLUAData(szFilePath, { passphrase = szPassphraseSalted })
			or LoadLUAData(szFilePath, { passphrase = szPassphrase })
			or {}
		if not CACHE[szDomain][szPath] then
			bNew = true
			CACHE[szDomain][szPath] = X.GetUUID():gsub('-', '')
			SaveLUAData(szFilePath, CACHE[szDomain], { passphrase = szPassphraseSalted })
		end
	end
	return CACHE[szDomain][szPath], bNew
end
end

-- 获取插件软唯一标示符
do
local GUID
function X.GetClientGUID()
	if not GUID then
		local szRandom = GetLUADataPathPassphrase(X.GetLUADataPath({'GUIDv2', X.PATH_TYPE.GLOBAL}))
		local szPrefix = MD5(szRandom):sub(1, 4)
		local nCSW, nCSH = GetSystemCScreen()
		local szCS = MD5(nCSW .. ',' .. nCSH):sub(1, 4)
		GUID = ('%s%X%s'):format(szPrefix, GetStringCRC(szRandom), szCS)
	end
	return GUID
end
end

-- 保存数据文件
function X.SaveLUAData(oFilePath, oData, tConfig)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTickCount()
	--[[#DEBUG END]]
	local config, szPassphrase, bNew = X.Clone(tConfig) or {}, nil, nil
	local szFilePath = X.GetLUADataPath(oFilePath)
	if X.IsNil(config.passphrase) then
		config.passphrase = GetLUADataPathPassphrase(szFilePath)
	end
	local data = SaveLUAData(szFilePath, oData, config)
	--[[#DEBUG BEGIN]]
	nStartTick = GetTickCount() - nStartTick
	if nStartTick > 5 then
		X.Debug('PMTool', _L('%s saved during %dms.', szFilePath, nStartTick), X.DEBUG_LEVEL.PM_LOG)
	end
	--[[#DEBUG END]]
	return data
end

-- 加载数据文件
function X.LoadLUAData(oFilePath, tConfig)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTickCount()
	--[[#DEBUG END]]
	local config, szPassphrase, bNew = X.Clone(tConfig) or {}, nil, nil
	local szFilePath = X.GetLUADataPath(oFilePath)
	if X.IsNil(config.passphrase) then
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
	nStartTick = GetTickCount() - nStartTick
	if nStartTick > 5 then
		X.Debug('PMTool', _L('%s loaded during %dms.', szFilePath, nStartTick), X.DEBUG_LEVEL.PM_LOG)
	end
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
			table.insert(aChild, { k = GetLUADataHashSYNC(k), v = GetLUADataHashSYNC(v) })
		end
		table.sort(aChild, TableSorterK)
		for i, v in ipairs(aChild) do
			aChild[i] = v.k .. ':' .. v.v
		end
		return GetLUADataHashSYNC('{}::' .. table.concat(aChild, ';'))
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
		table.insert(__stack__, current)
		return current
	end

	local function __exit_context__()
		table.remove(__stack__)
	end

	local function __call__(...)
		table.insert(__stack__, {
			continuation = '0',
			arguments = X.Pack(...),
			state = {},
			context = {},
		})
	end

	local function __return__(...)
		__exit_context__()
		__retvals__ = X.Pack(...)
	end

	__call__(data)

	local current, continuation, arguments, state, context, timer

	timer = X.BreatheCall(function()
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
					table.sort(context.aChild, TableSorterK)
					for i, v in ipairs(context.aChild) do
						context.aChild[i] = v.k .. ':' .. v.v
					end
					__call__('{}::' .. table.concat(context.aChild, ';'))
					current.continuation = '1.2'
				end
			elseif continuation == '1.2' then
				__return__(X.Unpack(__retvals__))
				__return__(X.Unpack(__retvals__))
			elseif continuation == '2' then
				__call__(context.k)
				current.continuation = '2.1'
			elseif continuation == '2.1' then
				context.ks = __retvals__[1]
				__call__(context.v)
				current.continuation = '2.2'
			elseif continuation == '2.2' then
				context.vs = __retvals__[1]
				table.insert(context.aChild, { k = context.ks, v = context.vs })
				__exit_context__()
			end

			if GetTime() - nTime > 100 then
				return
			end
		end

		X.BreatheCall(timer, false)
		X.SafeCall(fnAction, X.Unpack(__retvals__))
	end)
end
X.GetLUADataHash = GetLUADataHash
end

do
---------------------------------------------------------------------------------------------
-- 用户配置项
---------------------------------------------------------------------------------------------
local USER_SETTINGS_UPDATE_EVENT = {
	szName = 'UserSettingsUpdate',
}

function X.RegisterUserSettingsUpdate(...)
	return X.CommonEventRegister(USER_SETTINGS_UPDATE_EVENT, ...)
end

--[[#DEBUG BEGIN]]
local USER_SETTINGS_INIT_TIME_RANK = {}
--[[#DEBUG END]]
local USER_SETTINGS_INIT_EVENT = {
	szName = 'UserSettingsInit',
	bSingleEvent = true,
	--[[#DEBUG BEGIN]]
	OnStat = function(szID, nTime)
		X.CollectUsageRank(USER_SETTINGS_INIT_TIME_RANK, szID, nTime)
		X.Log('USER_SETTINGS_INIT_REPORT', 'Event function "' .. szID .. '" execution takes ' .. nTime .. 'ms.')
	end,
	--[[#DEBUG END]]
}

function X.RegisterUserSettingsInit(...)
	if X.IsUserSettingsAvailable() then
		local fnAction = ...
		if not X.IsFunction(fnAction) then
			fnAction = select(2, ...)
		end
		X.SafeCall(fnAction)
	end
	return X.CommonEventRegister(USER_SETTINGS_INIT_EVENT, ...)
end

--[[#DEBUG BEGIN]]
local USER_SETTINGS_RELEASE_TIME_RANK = {}
--[[#DEBUG END]]
local USER_SETTINGS_RELEASE_EVENT = {
	szName = 'UserSettingsRelease',
	bSingleEvent = true,
	--[[#DEBUG BEGIN]]
	OnStat = function(szID, nTime)
		X.CollectUsageRank(USER_SETTINGS_RELEASE_TIME_RANK, szID, nTime)
		X.Log('USER_SETTINGS_RELEASE_REPORT', 'Event function "' .. szID .. '" execution takes ' .. nTime .. 'ms.')
	end,
	--[[#DEBUG END]]
}

function X.RegisterUserSettingsRelease(...)
	return X.CommonEventRegister(USER_SETTINGS_RELEASE_EVENT, ...)
end

local DATABASE_TYPE_LIST = { X.PATH_TYPE.ROLE, X.PATH_TYPE.SERVER, X.PATH_TYPE.GLOBAL }
local DATABASE_TYPE_HASH = X.ArrayToObject(DATABASE_TYPE_LIST)
local DATABASE_TYPE_PRESET_FILE = {
	[X.PATH_TYPE.ROLE] = 'role',
	[X.PATH_TYPE.SERVER] = 'server',
	[X.PATH_TYPE.GLOBAL] = 'global',
}
local DATABASE_INSTANCE = {}
local USER_SETTINGS_INFO = {}
local USER_SETTINGS_LIST = {}
local DATA_CACHE = {}
local DATA_CACHE_LEAF_FLAG = {}
local FLUSH_TIME = 0
local DATABASE_CONNECTION_ESTABLISHED = false

local function SetInstanceInfoData(inst, info, data, version)
	local db = info.bUserData
		and inst.pUserDataDB
		or inst.pSettingsDB
	if db then
		--[[#DEBUG BEGIN]]
		local nStartTick = GetTime()
		--[[#DEBUG END]]
		db:Set(info.szDataKey, { d = data, v = version })
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, _L('User settings %s saved during %dms.', info.szDataKey, GetTickCount() - nStartTick), X.DEBUG_LEVEL.PM_LOG)
		--[[#DEBUG END]]
	end
end

local function GetInstanceInfoData(inst, info)
	local db = info.bUserData
		and inst.pUserDataDB
		or inst.pSettingsDB
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTime()
	--[[#DEBUG END]]
	local res = db and db:Get(info.szDataKey)
	--[[#DEBUG BEGIN]]
	X.Debug(X.PACKET_INFO.NAME_SPACE, _L('User settings %s loaded during %dms.', info.szDataKey, GetTickCount() - nStartTick), X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
	if res then
		return res
	end
	return nil
end

local function DeleteInstanceInfoData(inst, info)
	local db = info.bUserData
		and inst.pUserDataDB
		or inst.pSettingsDB
	if db then
		db:Delete(info.szDataKey)
	end
end

function X.IsUserSettingsAvailable()
	return DATABASE_CONNECTION_ESTABLISHED
end

function X.ConnectUserSettingsDB()
	if DATABASE_CONNECTION_ESTABLISHED then
		return
	end
	local szID, szDBPresetRoot = X.GetUserSettingsPresetID(), nil
	if not X.IsEmpty(szID) then
		szDBPresetRoot = X.FormatPath({'config/settings/' .. szID .. '/', X.PATH_TYPE.GLOBAL})
		CPath.MakeDir(szDBPresetRoot)
	end
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if not DATABASE_INSTANCE[ePathType] then
			local pSettingsDB = X.NoSQLiteConnect(
				szDBPresetRoot
					and (szDBPresetRoot .. DATABASE_TYPE_PRESET_FILE[ePathType] .. '.db')
					or X.FormatPath({'config/settings.db', ePathType})
			)
			local pUserDataDB = X.NoSQLiteConnect(X.FormatPath({'userdata/userdata.db', ePathType}))
			if not pSettingsDB then
				X.Debug(X.PACKET_INFO.NAME_SPACE, 'Connect user settings database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			if not pUserDataDB then
				X.Debug(X.PACKET_INFO.NAME_SPACE, 'Connect userdata database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			DATABASE_INSTANCE[ePathType] = {
				pSettingsDB = pSettingsDB,
				-- bSettingsDBCommit = false,
				pUserDataDB = pUserDataDB,
				-- bUserDataDBCommit = false,
			}
		end
	end
	DATABASE_CONNECTION_ESTABLISHED = true
	X.CommonEventFirer(USER_SETTINGS_INIT_EVENT)
	--[[#DEBUG BEGIN]]
	X.ReportUsageRank('USER_SETTINGS_INIT_REPORT', USER_SETTINGS_INIT_TIME_RANK)
	--[[#DEBUG END]]
end

function X.ReleaseUserSettingsDB()
	X.CommonEventFirer(USER_SETTINGS_RELEASE_EVENT)
	--[[#DEBUG BEGIN]]
	X.ReportUsageRank('USER_SETTINGS_RELEASE_REPORT', USER_SETTINGS_INIT_TIME_RANK)
	--[[#DEBUG END]]
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		local inst = DATABASE_INSTANCE[ePathType]
		if inst then
			if inst.pSettingsDB then
				X.NoSQLiteDisconnect(inst.pSettingsDB)
			end
			if inst.pUserDataDB then
				X.NoSQLiteDisconnect(inst.pUserDataDB)
			end
			DATABASE_INSTANCE[ePathType] = nil
		end
	end
	DATA_CACHE = {}
	DATABASE_CONNECTION_ESTABLISHED = false
end

function X.FlushUserSettingsDB()
	-- for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
	-- 	local inst = DATABASE_INSTANCE[ePathType]
	-- 	if inst then
	-- 		if inst.bSettingsDBCommit and inst.pSettingsDB and inst.pSettingsDB.Commit then
	-- 			inst.pSettingsDB:Commit()
	-- 			inst.bSettingsDBCommit = false
	-- 		end
	-- 		if inst.bUserDataDBCommit and inst.pUserDataDB and inst.pUserDataDB.Commit then
	-- 			inst.pUserDataDB:Commit()
	-- 			inst.bUserDataDBCommit = false
	-- 		end
	-- 	end
	-- end
end

function X.GetUserSettingsPresetID(bDefault)
	local szPath = X.FormatPath({'config/usersettings-preset.jx3dat', bDefault and X.PATH_TYPE.GLOBAL or X.PATH_TYPE.ROLE})
	if not bDefault and not IsLocalFileExist(szPath) then
		return X.GetUserSettingsPresetID(true)
	end
	local szID = X.LoadLUAData(szPath)
	if X.IsString(szID) and not szID:find('[/?*:|\\<>]') then
		return szID
	end
	return ''
end

function X.SetUserSettingsPresetID(szID, bDefault)
	if szID then
		if szID:find('[/?*:|\\<>]') then
			return _L['User settings preset id cannot contains special character (/?*:|\\<>).']
		end
		szID = X.StringReplaceW(szID, '^%s+', '')
		szID = X.StringReplaceW(szID, '%s+$', '')
	end
	if X.IsEmpty(szID) then
		szID = ''
	end
	if szID == X.GetUserSettingsPresetID(bDefault) then
		return
	end
	local szCurrentID = X.GetUserSettingsPresetID()
	X.SaveLUAData({'config/usersettings-preset.jx3dat', bDefault and X.PATH_TYPE.GLOBAL or X.PATH_TYPE.ROLE}, szID)
	if szCurrentID == X.GetUserSettingsPresetID() then
		return
	end
	if DATABASE_CONNECTION_ESTABLISHED then
		X.ReleaseUserSettingsDB()
		X.ConnectUserSettingsDB()
	end
	DATA_CACHE = {}
end

function X.GetUserSettingsPresetList()
	return CPath.GetFolderList(X.FormatPath({'userdata/settings/', X.PATH_TYPE.GLOBAL}))
end

function X.RemoveUserSettingsPreset(szID)
	CPath.DelDir(X.FormatPath({'userdata/settings/' .. szID .. '/', X.PATH_TYPE.GLOBAL}))
end

-- 注册单个用户配置项
-- @param {string} szKey 配置项全局唯一键
-- @param {table} tOption 自定义配置项
--   {PATH_TYPE} tOption.ePathType 配置项保存位置（当前角色、当前服务器、全局）
--   {string} tOption.szDataKey 配置项入库时的键值，一般不需要手动指定，默认与配置项全局键值一致
--   {string} tOption.bUserData 配置项是否为角色数据项，为真将忽略预设方案重定向，禁止共用
--   {string} tOption.szGroup 配置项分组组标题，用于导入导出显示，禁止导入导出请留空
--   {string} tOption.szLabel 配置标题，用于导入导出显示，禁止导入导出请留空
--   {string} tOption.szVersion 数据版本号，加载数据时会丢弃版本不一致的数据
--   {any} tOption.xDefaultValue 数据默认值
--   {schema} tOption.xSchema 数据类型约束对象，通过 Schema 库生成
--   {boolean} tOption.bDataSet 是否为配置项组（如用户多套自定义偏好），配置项组在读写时需要额外传入一个组下配置项唯一键值（即多套自定义偏好中某一项的名字）
--   {table} tOption.tDataSetDefaultValue 数据默认值（仅当 bDataSet 为真时生效，用于设置配置项组不同默认值）
function X.RegisterUserSettings(szKey, tOption)
	local ePathType, szDataKey, bUserData, szGroup, szLabel, szVersion, xDefaultValue, xSchema, bDataSet, tDataSetDefaultValue
	if X.IsTable(tOption) then
		ePathType = tOption.ePathType
		szDataKey = tOption.szDataKey
		bUserData = tOption.bUserData
		szGroup = tOption.szGroup
		szLabel = tOption.szLabel
		szVersion = tOption.szVersion
		xDefaultValue = tOption.xDefaultValue
		xSchema = tOption.xSchema
		bDataSet = tOption.bDataSet
		tDataSetDefaultValue = tOption.tDataSetDefaultValue
	end
	if not ePathType then
		ePathType = X.PATH_TYPE.ROLE
	end
	if not szDataKey then
		szDataKey = szKey
	end
	if not szVersion then
		szVersion = ''
	end
	if not X.IsString(szKey) or szKey == '' then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` should be a non-empty string value.')
	end
	if USER_SETTINGS_INFO[szKey] then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): duplicated `Key` found.')
	end
	if not X.IsString(szDataKey) or szDataKey == '' then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `DataKey` should be a non-empty string value.')
	end
	for k, p in pairs(USER_SETTINGS_INFO) do
		if p.szDataKey == szDataKey and p.ePathType == ePathType then
			assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): duplicated `DataKey` + `PathType` found.')
		end
	end
	if not DATABASE_TYPE_HASH[ePathType] then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `PathType` value is not valid.')
	end
	if not X.IsNil(szGroup) and (not X.IsString(szGroup) or szGroup == '') then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Group` should be nil or a non-empty string value.')
	end
	if not X.IsNil(szLabel) and (not X.IsString(szLabel) or szLabel == '') then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Label` should be nil or a non-empty string value.')
	end
	if not X.IsString(szVersion) then
		assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Version` should be a string value.')
	end
	if xSchema then
		local errs = X.Schema.CheckSchema(xDefaultValue, xSchema)
		if errs then
			local aErrmsgs = {}
			for i, err in ipairs(errs) do
				table.insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
			end
			assert(false, szErrHeader .. '`DefaultValue` cannot pass `Schema` check.' .. '\n' .. table.concat(aErrmsgs, '\n'))
		end
		if bDataSet then
			tDataSetDefaultValue = X.IsTable(tDataSetDefaultValue)
				and X.Clone(tDataSetDefaultValue)
				or {}
			local errs = X.Schema.CheckSchema(tDataSetDefaultValue, X.Schema.Map(X.Schema.Any, xSchema))
			if errs then
				local aErrmsgs = {}
				for i, err in ipairs(errs) do
					table.insert(aErrmsgs, '  ' .. i .. '. ' .. err.message)
				end
				assert(false, szErrHeader .. '`DataSetDefaultValue` cannot pass `Schema` check.' .. '\n' .. table.concat(aErrmsgs, '\n'))
			end
		end
	end
	local tInfo = {
		szKey = szKey,
		ePathType = ePathType,
		bUserData = bUserData,
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
	table.insert(USER_SETTINGS_LIST, tInfo)
end

function X.GetRegisterUserSettingsList()
	return X.Clone(USER_SETTINGS_LIST)
end

function X.ExportUserSettings(aKey)
	local tKvp = {}
	for _, szKey in ipairs(aKey) do
		local info = USER_SETTINGS_INFO[szKey]
		local inst = info and DATABASE_INSTANCE[info.ePathType]
		if inst then
			tKvp[szKey] = GetInstanceInfoData(inst, info)
		end
	end
	return tKvp
end

function X.ImportUserSettings(tKvp)
	local nSuccess = 0
	for szKey, xValue in pairs(tKvp) do
		local info = X.IsTable(xValue) and USER_SETTINGS_INFO[szKey]
		local inst = info and DATABASE_INSTANCE[info.ePathType]
		if inst then
			SetInstanceInfoData(inst, info, xValue.d, xValue.v)
			nSuccess = nSuccess + 1
			DATA_CACHE[szKey] = nil
		end
	end
	X.CommonEventFirer(USER_SETTINGS_INIT_EVENT)
	--[[#DEBUG BEGIN]]
	X.ReportUsageRank('USER_SETTINGS_INIT_REPORT', USER_SETTINGS_INIT_TIME_RANK)
	--[[#DEBUG END]]
	return nSuccess
end

-- 获取用户配置项值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
-- @return 值
function X.GetUserSettings(szKey, ...)
	-- 缓存加速
	local cache = DATA_CACHE
	for _, k in ipairs({szKey, ...}) do
		if X.IsTable(cache) then
			cache = cache[k]
		end
		if not X.IsTable(cache) then
			cache = nil
			break
		end
		if cache[1] == DATA_CACHE_LEAF_FLAG then
			return cache[2]
		end
	end
	-- 参数检查
	local nParameter = select('#', ...) + 1
	local info = USER_SETTINGS_INFO[szKey]
	if not info then
		assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` has not been registered.')
	end
	local inst = DATABASE_INSTANCE[info.ePathType]
	if not inst then
		assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): Database not connected.')
	end
	local szDataSetKey
	if info.bDataSet then
		if nParameter ~= 2 then
			assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 2 parameters expected, got ' .. nParameter)
		end
		szDataSetKey = ...
		if not X.IsString(szDataSetKey) and not X.IsNumber(szDataSetKey) then
			assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `DataSetKey` should be a string or number value.')
		end
	else
		if nParameter ~= 1 then
			assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 1 parameter expected, got ' .. nParameter)
		end
	end
	-- 读数据库
	local res, bData = GetInstanceInfoData(inst, info), false
	if X.IsTable(res) and res.v == info.szVersion then
		local data = res.d
		if info.bDataSet then
			if X.IsTable(data) then
				data = data[szDataSetKey]
			else
				data = nil
			end
		end
		if not info.xSchema or not X.Schema.CheckSchema(data, info.xSchema) then
			bData = true
			res = data
		end
	end
	-- 默认值
	if not bData then
		if info.bDataSet then
			res = info.tDataSetDefaultValue[szDataSetKey]
			if X.IsNil(res) then
				res = info.xDefaultValue
			end
		else
			res = info.xDefaultValue
		end
		res = X.Clone(res)
	end
	-- 缓存
	if info.bDataSet then
		if not DATA_CACHE[szKey] then
			DATA_CACHE[szKey] = {}
		end
		DATA_CACHE[szKey][szDataSetKey] = { DATA_CACHE_LEAF_FLAG, res, X.Clone(res) }
	else
		DATA_CACHE[szKey] = { DATA_CACHE_LEAF_FLAG, res, X.Clone(res) }
	end
	return res
end

-- 保存用户配置项值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
-- @param {unknown} xValue 值
function X.SetUserSettings(szKey, ...)
	-- 参数检查
	local nParameter = select('#', ...) + 1
	local info = USER_SETTINGS_INFO[szKey]
	if not info then
		assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` has not been registered.')
	end
	local inst = DATABASE_INSTANCE[info.ePathType]
	if not inst and X.IsDebugClient() then
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): Database not connected!!!', X.DEBUG_LEVEL.WARNING)
		return false
	end
	if not inst then
		assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): Database not connected.')
	end
	local cache = DATA_CACHE[szKey]
	local szDataSetKey, xValue
	if info.bDataSet then
		if nParameter ~= 3 then
			assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 3 parameters expected, got ' .. nParameter)
		end
		szDataSetKey, xValue = ...
		if not X.IsString(szDataSetKey) and not X.IsNumber(szDataSetKey) then
			assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `DataSetKey` should be a string or number value.')
		end
		cache = cache and cache[szDataSetKey]
	else
		if nParameter ~= 2 then
			assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 2 parameters expected, got ' .. nParameter)
		end
		xValue = ...
	end
	if cache and cache[1] == DATA_CACHE_LEAF_FLAG and X.IsEquals(cache[3], xValue) then
		return
	end
	-- 数据校验
	if info.xSchema then
		local errs = X.Schema.CheckSchema(xValue, info.xSchema)
		if errs then
			local aErrmsgs = {}
			for i, err in ipairs(errs) do
				table.insert(aErrmsgs, i .. '. ' .. err.message)
			end
			assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): ' .. szKey .. ', schema check failed.\n' .. table.concat(aErrmsgs, '\n'))
		end
	end
	-- 写数据库
	if info.bDataSet then
		local res = GetInstanceInfoData(inst, info)
		if X.IsTable(res) and res.v == info.szVersion and X.IsTable(res.d) then
			res.d[szDataSetKey] = xValue
			xValue = res.d
		else
			xValue = { [szDataSetKey] = xValue }
		end
		if X.IsTable(DATA_CACHE[szKey]) then
			DATA_CACHE[szKey][szDataSetKey] = nil
		end
	else
		DATA_CACHE[szKey] = nil
	end
	SetInstanceInfoData(inst, info, xValue, info.szVersion)
	-- if info.bUserData then
	-- 	inst.bUserDataDBCommit = true
	-- else
	-- 	inst.bSettingsDBCommit = true
	-- end
	X.CommonEventFirer(USER_SETTINGS_UPDATE_EVENT, szKey)
	return true
end

-- 重载刷新用户配置项缓存值
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
function X.ReloadUserSettings(szKey, ...)
	local root = DATA_CACHE
	local key = szKey
	if ... then
		root = root[szKey]
		key = ...
	end
	if X.IsTable(root) then
		root[key] = nil
	end
	X.GetUserSettings(szKey, ...)
end

-- 删除用户配置项值（恢复默认值）
-- @param {string} szKey 配置项全局唯一键
-- @param {string} szDataSetKey 配置项组（如用户多套自定义偏好）唯一键，当且仅当 szKey 对应注册项携带 bDataSet 标记位时有效
function X.ResetUserSettings(szKey, ...)
	-- 参数检查
	local nParameter = select('#', ...) + 1
	local info = USER_SETTINGS_INFO[szKey]
	if not info then
		assert(false, 'ResetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` has not been registered.')
	end
	local inst = DATABASE_INSTANCE[info.ePathType]
	if not inst then
		assert(false, 'ResetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): Database not connected.')
	end
	local szDataSetKey
	if info.bDataSet then
		if nParameter ~= 1 and nParameter ~= 2 then
			assert(false, 'ResetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 1 or 2 parameter(s) expected, got ' .. nParameter)
		end
		szDataSetKey = ...
		if not X.IsString(szDataSetKey) and not X.IsNumber(szDataSetKey) and not X.IsNil(szDataSetKey) then
			assert(false, 'ResetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `DataSetKey` should be a string or number or nil value.')
		end
	else
		if nParameter ~= 1 then
			assert(false, 'ResetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 1 parameter expected, got ' .. nParameter)
		end
	end
	-- 写数据库
	if info.bDataSet then
		local res = GetInstanceInfoData(inst, info)
		if X.IsTable(res) and res.v == info.szVersion and X.IsTable(res.d) and szDataSetKey then
			res.d[szDataSetKey] = nil
			if X.IsEmpty(res.d) then
				DeleteInstanceInfoData(inst, info)
			else
				SetInstanceInfoData(inst, info, res.d, info.szVersion)
			end
			if DATA_CACHE[szKey] then
				DATA_CACHE[szKey][szDataSetKey] = nil
			end
		else
			DeleteInstanceInfoData(inst, info)
			DATA_CACHE[szKey] = nil
		end
	else
		DeleteInstanceInfoData(inst, info)
		DATA_CACHE[szKey] = nil
	end
	-- if info.bUserData then
	-- 	inst.bUserDataDBCommit = true
	-- else
	-- 	inst.bSettingsDBCommit = true
	-- end
	X.CommonEventFirer(USER_SETTINGS_UPDATE_EVENT, szKey)
end

-- 创建用户设置代理对象
-- @param {string | table} xProxy 配置项代理表（ alias => globalKey ），或模块命名空间
-- @return 配置项读写代理对象
function X.CreateUserSettingsProxy(xProxy)
	local tDataSetProxy = {}
	local tLoaded = {}
	local tProxy = X.IsTable(xProxy) and xProxy or {}
	for k, v in pairs(tProxy) do
		if not X.IsString(k) then
			assert(false, '`Key` ' .. X.EncodeLUAData(k) .. ' of proxy should be a string value.')
		end
		if not X.IsString(v) then
			assert(false, '`Val` ' .. X.EncodeLUAData(v) .. ' of proxy should be a string value.')
		end
	end
	local function GetGlobalKey(k)
		if not tProxy[k] then
			if X.IsString(xProxy) then
				tProxy[k] = xProxy .. '.' .. k
			end
			if not tProxy[k] then
				assert(false, '`Key` ' .. X.EncodeLUAData(k) .. ' not found in proxy table.')
			end
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
							return X.GetUserSettings(szGlobalKey, kds)
						end,
						__newindex = function(_, kds, vds)
							X.SetUserSettings(szGlobalKey, kds, vds)
						end,
					})
				end
				tLoaded[k] = true
			end
			return tDataSetProxy[k] or X.GetUserSettings(szGlobalKey)
		end,
		__newindex = function(_, k, v)
			X.SetUserSettings(GetGlobalKey(k), v)
		end,
		__call = function(_, cmd, arg0)
			if cmd == 'load' then
				if not X.IsTable(arg0) then
					arg0 = {}
					for k, _ in pairs(tProxy) do
						table.insert(arg0, k)
					end
				end
				for _, k in ipairs(arg0) do
					X.GetUserSettings(GetGlobalKey(k))
				end
			elseif cmd == 'reset' then
				if not X.IsTable(arg0) then
					arg0 = {}
					for k, _ in pairs(tProxy) do
						table.insert(arg0, k)
					end
				end
				for _, k in ipairs(arg0) do
					X.ResetUserSettings(GetGlobalKey(k))
				end
			elseif cmd == 'reload' then
				if not X.IsTable(arg0) then
					arg0 = {}
					for k, _ in pairs(tProxy) do
						table.insert(arg0, k)
					end
				end
				for _, k in ipairs(arg0) do
					X.ReloadUserSettings(GetGlobalKey(k))
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
function X.CreateUserSettingsModule(szModule, szGroupLabel, tSettings)
	if X.IsTable(szGroupLabel) then
		szGroupLabel, tSettings = nil, szGroupLabel
	end
	local tProxy = {}
	for k, v in pairs(tSettings) do
		local szKey = szModule .. '.' .. k
		local tOption = X.Clone(v)
		if tOption.szDataKey then
			tOption.szDataKey = szModule .. '.' .. tOption.szDataKey
		end
		if szGroupLabel then
			tOption.szGroup = szGroupLabel
		end
		X.RegisterUserSettings(szKey, tOption)
		tProxy[k] = szKey
	end
	return X.CreateUserSettingsProxy(tProxy)
end

X.RegisterIdle(X.NSFormatString('{$NS}#FlushUserSettingsDB'), function()
	if GetCurrentTime() - FLUSH_TIME > 60 then
		X.FlushUserSettingsDB()
		FLUSH_TIME = GetCurrentTime()
	end
end)
end

------------------------------------------------------------------------------
-- 格式化数据
------------------------------------------------------------------------------

do local CREATED = {}
function X.CreateDataRoot(ePathType)
	if CREATED[ePathType] then
		return
	end
	CREATED[ePathType] = true
	-- 创建目录
	if ePathType == X.PATH_TYPE.ROLE then
		X.SaveLUAData(
			{'info.jx3dat', X.PATH_TYPE.ROLE},
			{
				id = X.GetClientInfo('dwID'),
				uid = X.GetPlayerGUID(),
				name = X.GetClientInfo('szName'),
				lang = X.ENVIRONMENT.GAME_LANG,
				edition = X.ENVIRONMENT.GAME_EDITION,
				branch = X.ENVIRONMENT.GAME_BRANCH,
				version = X.ENVIRONMENT.GAME_VERSION,
				region = X.GetServer(1),
				server = X.GetServer(2),
				relregion = X.GetRealServer(1),
				relserver = X.GetRealServer(2),
				time = GetCurrentTime(),
				timestr = X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'),
			},
			{ crc = false, passphrase = false })
		CPath.MakeDir(X.FormatPath({'{$name}/', X.PATH_TYPE.ROLE}))
	end
	-- 版本更新时删除旧的临时目录
	if IsLocalFileExist(X.FormatPath({'temporary/', ePathType}))
	and not IsLocalFileExist(X.FormatPath({'temporary/{$version}', ePathType})) then
		CPath.DelDir(X.FormatPath({'temporary/', ePathType}))
	end
	CPath.MakeDir(X.FormatPath({'temporary/{$version}/', ePathType}))
	CPath.MakeDir(X.FormatPath({'audio/', ePathType}))
	CPath.MakeDir(X.FormatPath({'cache/', ePathType}))
	CPath.MakeDir(X.FormatPath({'config/', ePathType}))
	CPath.MakeDir(X.FormatPath({'export/', ePathType}))
	CPath.MakeDir(X.FormatPath({'logs/', ePathType}))
	CPath.MakeDir(X.FormatPath({'font/', ePathType}))
	CPath.MakeDir(X.FormatPath({'userdata/', ePathType}))
end
end

------------------------------------------------------------------------------
-- 官方角色设置自定义二进制位
------------------------------------------------------------------------------

do
local REMOTE_STORAGE_REGISTER = {}
local REMOTE_STORAGE_WATCHER = {}
local BIT_NUMBER = 8
local BIT_COUNT = 32 * BIT_NUMBER -- total bytes: 32
local GetOnlineAddonCustomData = _G.GetOnlineAddonCustomData or GetAddonCustomData
local SetOnlineAddonCustomData = _G.SetOnlineAddonCustomData or SetAddonCustomData

local function Byte2Bit(nByte)
	local aBit = { 0, 0, 0, 0, 0, 0, 0, 0 }
	for i = 8, 1, -1 do
		aBit[i] = nByte % 2
		nByte = math.floor(nByte / 2)
	end
	return aBit
end

local function Bit2Byte(aBit)
	local nByte = 0
	for i = 1, 8 do
		nByte = nByte * 2 + (aBit[i] or 0)
	end
	return nByte
end

local function OnRemoteStorageChange(szKey)
	if not REMOTE_STORAGE_WATCHER[szKey] then
		return
	end
	local oVal = X.GetRemoteStorage(szKey)
	for _, fnAction in ipairs(REMOTE_STORAGE_WATCHER[szKey]) do
		fnAction(oVal)
	end
end

function X.RegisterRemoteStorage(szKey, nBitPos, nBitNum, fnGetter, fnSetter, bForceOnline)
	if nBitPos < 0 or nBitNum <= 0 or nBitPos + nBitNum > BIT_COUNT then
		assert(false, 'storage position out of range: ' .. szKey)
	end
	for _, p in pairs(REMOTE_STORAGE_REGISTER) do
		if nBitPos < p.nBitPos + p.nBitNum and nBitPos + nBitNum > p.nBitPos then
			assert(false, 'storage position conflicted: ' .. szKey .. ', ' .. p.szKey)
		end
	end
	if not X.IsFunction(fnGetter) or not X.IsFunction(fnSetter) then
		assert(false, 'storage setter and getter must be function')
	end
	REMOTE_STORAGE_REGISTER[szKey] = {
		szKey = szKey,
		nBitPos = nBitPos,
		nBitNum = nBitNum,
		fnGetter = fnGetter,
		fnSetter = fnSetter,
		bForceOnline = bForceOnline,
	}
end

function X.SetRemoteStorage(szKey, ...)
	local st = REMOTE_STORAGE_REGISTER[szKey]
	if not st then
		assert(false, 'unknown storage key: ' .. szKey)
	end

	local aBit = st.fnSetter(...)
	if #aBit ~= st.nBitNum then
		assert(false, 'storage setter bit number mismatch: ' .. szKey)
	end

	local GetData = st.bForceOnline and GetOnlineAddonCustomData or GetAddonCustomData
	local SetData = st.bForceOnline and SetOnlineAddonCustomData or SetAddonCustomData
	local nPos = math.floor(st.nBitPos / BIT_NUMBER)
	local nLen = math.floor((st.nBitPos + st.nBitNum - 1) / BIT_NUMBER) - nPos + 1
	local aByte = {GetData(X.PACKET_INFO.NAME_SPACE, nPos, nLen)}
	for i, v in ipairs(aByte) do
		aByte[i] = Byte2Bit(v)
	end
	for nBitPos = st.nBitPos, st.nBitPos + st.nBitNum - 1 do
		local nIndex = math.floor(nBitPos / BIT_NUMBER) - nPos + 1
		local nOffset = nBitPos % BIT_NUMBER + 1
		aByte[nIndex][nOffset] = aBit[nBitPos - st.nBitPos + 1]
	end
	for i, v in ipairs(aByte) do
		aByte[i] = Bit2Byte(v)
	end
	SetData(X.PACKET_INFO.NAME_SPACE, nPos, nLen, X.Unpack(aByte))

	OnRemoteStorageChange(szKey)
end

function X.GetRemoteStorage(szKey)
	local st = REMOTE_STORAGE_REGISTER[szKey]
	if not st then
		assert(false, 'unknown storage key: ' .. szKey)
	end

	local GetData = st.bForceOnline and GetOnlineAddonCustomData or GetAddonCustomData
	local nPos = math.floor(st.nBitPos / BIT_NUMBER)
	local nLen = math.floor((st.nBitPos + st.nBitNum - 1) / BIT_NUMBER) - nPos + 1
	local aByte = {GetData(X.PACKET_INFO.NAME_SPACE, nPos, nLen)}
	for i, v in ipairs(aByte) do
		aByte[i] = Byte2Bit(v)
	end
	local aBit = {}
	for nBitPos = st.nBitPos, st.nBitPos + st.nBitNum - 1 do
		local nIndex = math.floor(nBitPos / BIT_NUMBER) - nPos + 1
		local nOffset = nBitPos % BIT_NUMBER + 1
		table.insert(aBit, aByte[nIndex][nOffset])
	end
	return st.fnGetter(aBit)
end

-- 判断是否可以访问同步设置项（ESC-游戏设置-综合-服务器同步设置-界面常规设置）
function X.CanUseOnlineRemoteStorage()
	if _G.SetOnlineAddonCustomData then
		return true
	end
	local n = (GetUserPreferences(4347, 'c') + 1) % 256
	SetOnlineAddonCustomData(X.PACKET_INFO.NAME_SPACE, 31, 1, n)
	return GetUserPreferences(4347, 'c') == n
end

function X.WatchRemoteStorage(szKey, fnAction)
	if not REMOTE_STORAGE_WATCHER[szKey] then
		REMOTE_STORAGE_WATCHER[szKey] = {}
	end
	table.insert(REMOTE_STORAGE_WATCHER[szKey], fnAction)
end

local INIT_FUNC_LIST = {}
function X.RegisterRemoteStorageInit(szKey, fnAction)
	INIT_FUNC_LIST[szKey] = fnAction
end

local function OnInit()
	for szKey, _ in pairs(REMOTE_STORAGE_WATCHER) do
		OnRemoteStorageChange(szKey)
	end
	for szKey, fnAction in pairs(INIT_FUNC_LIST) do
		local res, err, trace = X.XpCall(fnAction)
		if not res then
			X.ErrorLog(err, 'INIT_FUNC_LIST: ' .. szKey, trace)
		end
	end
	INIT_FUNC_LIST = {}
end
X.RegisterInit('LIB#RemoteStorage', OnInit)
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
	X.Debug(szCaption, 'Duplicate database start.', X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	-- 运行 DDL 语句 创建表和索引等
	for _, rec in ipairs(DB_SRC:Execute('SELECT sql FROM sqlite_master')) do
		DB_DST:Execute(rec.sql)
		--[[#DEBUG BEGIN]]
		X.Debug(szCaption, 'Duplicating database: ' .. rec.sql, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	-- 读取表名 依次复制
	for _, rec in ipairs(DB_SRC:Execute('SELECT name FROM sqlite_master WHERE type=\'table\'')) do
		-- 读取列名
		local szTableName, aColumns, aPlaceholders = rec.name, {}, {}
		for _, rec in ipairs(DB_SRC:Execute('PRAGMA table_info(' .. szTableName .. ')')) do
			table.insert(aColumns, rec.name)
			table.insert(aPlaceholders, '?')
		end
		local szColumns, szPlaceholders = table.concat(aColumns, ', '), table.concat(aPlaceholders, ', ')
		local nCount, nPageSize = X.Get(DB_SRC:Execute('SELECT COUNT(*) AS count FROM ' .. szTableName), {1, 'count'}, 0), 10000
		local DB_W = DB_DST:Prepare('REPLACE INTO ' .. szTableName .. ' (' .. szColumns .. ') VALUES (' .. szPlaceholders .. ')')
		--[[#DEBUG BEGIN]]
		X.Debug(szCaption, 'Duplicating table: ' .. szTableName .. ' (cols)' .. szColumns .. ' (count)' .. nCount, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- 开始读取和写入数据
		DB_DST:Execute('BEGIN TRANSACTION')
		for i = 0, nCount / nPageSize do
			for _, rec in ipairs(DB_SRC:Execute('SELECT ' .. szColumns .. ' FROM ' .. szTableName .. ' LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
				local aValues = { n = #aColumns }
				for i, szKey in ipairs(aColumns) do
					aValues[i] = rec[szKey]
				end
				DB_W:ClearBindings()
				DB_W:BindAll(X.Unpack(aValues))
				DB_W:Execute()
			end
		end
		DB_W:Reset()
		DB_DST:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		X.Debug(szCaption, 'Duplicating table finished: ' .. szTableName, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end

local function ConnectMalformedDatabase(szCaption, szPath, bAlert)
	--[[#DEBUG BEGIN]]
	X.Debug(szCaption, 'Fixing malformed database...', X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local szMalformedPath = RenameDatabase(szCaption, szPath)
	if not szMalformedPath then
		--[[#DEBUG BEGIN]]
		X.Debug(szCaption, 'Fixing malformed database failed... Move file failed...', X.DEBUG_LEVEL.LOG)
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
			X.Debug(szCaption, 'Fixing malformed database finished...', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return 'SUCCESS', DB_DST
		elseif not DB_SRC then
			--[[#DEBUG BEGIN]]
			X.Debug(szCaption, 'Connect malformed database failed...', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return 'TRANSFER_FAILED', DB_DST
		end
	end
end

function X.SQLiteConnect(szCaption, oPath, fnAction)
	-- 尝试连接数据库
	local szPath = X.FormatPath(oPath)
	--[[#DEBUG BEGIN]]
	X.Debug(szCaption, 'Connect database: ' .. szPath, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local DB = SQLite3_Open(szPath)
	if not DB then
		-- 连不上直接重命名原始文件并重新连接
		if IsLocalFileExist(szPath) and RenameDatabase(szCaption, szPath) then
			DB = SQLite3_Open(szPath)
		end
		if not DB then
			X.Debug(szCaption, 'Cannot connect to database!!!', X.DEBUG_LEVEL.ERROR)
			if fnAction then
				fnAction()
			end
			return
		end
	end

	-- 测试数据库完整性
	local aRes = DB:Execute('PRAGMA QUICK_CHECK')
	if X.Get(aRes, {1, 'integrity_check'}) == 'ok' then
		if fnAction then
			fnAction(DB)
		end
		return DB
	else
		-- 记录错误日志
		X.Debug(szCaption, 'Malformed database detected...', X.DEBUG_LEVEL.ERROR)
		for _, rec in ipairs(aRes or {}) do
			X.Debug(szCaption, X.EncodeLUAData(rec), X.DEBUG_LEVEL.ERROR)
		end
		DB:Release()
		-- 准备尝试修复
		if fnAction then
			X.Confirm(_L('%s Database is malformed, do you want to repair database now? Repair database may take a long time and cause a disconnection.', szCaption), function()
				X.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					local szStatus, DB = ConnectMalformedDatabase(szCaption, szPath)
					if szStatus == 'FILE_LOCKED' then
						X.Alert(_L('Database file locked, repair database failed! : %s', szPath))
					else
						X.Alert(_L('%s Database repair finished!', szCaption))
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

function X.SQLiteDisconnect(db)
	db:Release()
end

------------------------------------------------------------------------------
-- 基于 SQLite 的 NoSQLite 封装
------------------------------------------------------------------------------

function X.NoSQLiteConnect(oPath)
	local db = X.SQLiteConnect('NoSQL', oPath)
	if not db then
		return
	end
	db:Execute('CREATE TABLE IF NOT EXISTS data (key NVARCHAR(256) NOT NULL, value BLOB, PRIMARY KEY (key))')
	local stmtSetter = db:Prepare('REPLACE INTO data (key, value) VALUES (?, ?)')
	local stmtGetter = db:Prepare('SELECT * FROM data WHERE key = ? LIMIT 1')
	local stmtDeleter = db:Prepare('DELETE FROM data WHERE key = ?')
	local stmtAllGetter = db:Prepare('SELECT * FROM data')
	if not stmtSetter or not stmtGetter or not stmtDeleter or not stmtAllGetter then
		X.NoSQLiteDisconnect(db)
		return
	end
	return setmetatable({}, {
		__index = {
			Set = function(_, k, v)
				if not stmtSetter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtSetter:ClearBindings()
				stmtSetter:BindAll(k, EncodeByteData(v))
				stmtSetter:Execute()
				stmtSetter:Reset()
			end,
			Get = function(_, k)
				if not stmtGetter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtGetter:ClearBindings()
				stmtGetter:BindAll(k)
				local res = stmtGetter:GetNext()
				stmtGetter:Reset()
				if res then
					-- res.value: KByteData
					res = DecodeByteData(res.value)
				end
				return res
			end,
			Delete = function(_, k)
				if not stmtDeleter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtDeleter:ClearBindings()
				stmtDeleter:BindAll(k)
				stmtDeleter:Execute()
				stmtDeleter:Reset()
			end,
			GetAll = function(_)
				if not stmtAllGetter then
					assert(false, 'NoSQL connection closed.')
				end
				stmtAllGetter:ClearBindings()
				local res = stmtAllGetter:GetAll()
				stmtAllGetter:Reset()
				local tKvp = {}
				if res then
					for _, v in ipairs(res) do
						tKvp[v.key] = DecodeByteData(v.value)
					end
				end
				return tKvp
			end,
			Release = function(_)
				if stmtSetter then
					stmtSetter:Release()
					stmtSetter = nil
				end
				if stmtGetter then
					stmtGetter:Release()
					stmtGetter = nil
				end
				if stmtDeleter then
					stmtDeleter:Release()
					stmtDeleter = nil
				end
				if stmtAllGetter then
					stmtAllGetter:Release()
					stmtAllGetter = nil
				end
				if db then
					db:Release()
					db = nil
				end
			end,
		},
		__newindex = function() end,
	})
end

function X.NoSQLiteDisconnect(db)
	db:Release()
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
