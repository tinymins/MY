--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 用户配置
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Storage.UserSettings')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------
--- 思维导图
--- https://www.processon.com/view/link/67495e06ef5dd571a450dddb?cid=61ffb4506376890390cf80e2 访问密码：ot1K
--------------------------------------------------------------------------------

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
	[X.PATH_TYPE.ROLE] = 'role/settings.db',
	[X.PATH_TYPE.SERVER] = 'server/{$server_origin}.db',
	[X.PATH_TYPE.GLOBAL] = 'global/settings.db',
}
local DATABASE_TYPE_PRESET_FILE_MIGRATE = {
	['role.db'] = X.PATH_TYPE.ROLE,
	['server.db'] = X.PATH_TYPE.SERVER,
	['global.db'] = X.PATH_TYPE.GLOBAL,
}
local DATABASE_INSTANCE = {}
local USER_SETTINGS_INFO = {}
local USER_SETTINGS_LIST = {}
local USER_SETTINGS_LOCATION_OVERRIDE = {}
local DATA_CACHE = {}
local FLUSH_TIME = 0
local DATABASE_CONNECTION_ESTABLISHED = false

local function GetDB(inst, info)
	if info.bUserData then
		return inst.pUserDataDB
	end
	if info.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.ROLE then
		return inst.pRoleSettingsDB
	end
	if info.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.SERVER then
		return inst.pServerSettingsDB
	end
	if info.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.GLOBAL then
		return inst.pGlobalSettingsDB
	end
	return inst.pSettingsDB
end

local function SetInstanceInfoData(inst, info, data, version)
	local db = GetDB(inst, info)
	if db then
		--[[#DEBUG BEGIN]]
		local nStartTick = GetTime()
		--[[#DEBUG END]]
		db:Set(info.szDataKey, { d = data, v = version })
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, _L('User settings %s saved during %dms.', info.szDataKey, GetTickCount() - nStartTick), X.DEBUG_LEVEL.PM_LOG)
		--[[#DEBUG END]]
	end
end

local function GetInstanceInfoData(inst, info)
	local db = GetDB(inst, info)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTime()
	--[[#DEBUG END]]
	local res = db and db:Get(info.szDataKey)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, _L('User settings %s loaded during %dms.', info.szDataKey, GetTickCount() - nStartTick), X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
	if res then
		return res
	end
	return nil
end

local function DeleteInstanceInfoData(inst, info)
	local db = GetDB(inst, info)
	if db then
		db:Delete(info.szDataKey)
	end
end

-- 统一处理配置项存盘逻辑
---@param inst table 数据库实例
---@param info table 配置项信息
---@param szDataSetKey string|number DataSet 键值（可选，仅当配置项为 DataSet 类型时使用）
---@param xValue any 要保存的值
---@param bDelete boolean 是否为删除操作
local function FlushSettingsData(inst, info, szDataSetKey, xValue, bDelete)
	if info.bDataSet then
		-- 处理 DataSet 类型的数据
		if bDelete then
			-- 删除 DataSet 中的某个键
			local res = GetInstanceInfoData(inst, info)
			if X.IsTable(res) and res.v == info.szVersion and X.IsTable(res.d) then
				res.d[szDataSetKey] = nil
				if X.IsEmpty(res.d) then
					DeleteInstanceInfoData(inst, info)
				else
					SetInstanceInfoData(inst, info, res.d, info.szVersion)
				end
			else
				DeleteInstanceInfoData(inst, info)
			end
		else
			-- 设置 DataSet 中的某个键
			local res = GetInstanceInfoData(inst, info)
			local dataToSave
			if X.IsTable(res) and res.v == info.szVersion and X.IsTable(res.d) then
				res.d[szDataSetKey] = xValue
				dataToSave = res.d
			else
				dataToSave = { [szDataSetKey] = xValue }
			end
			SetInstanceInfoData(inst, info, dataToSave, info.szVersion)
		end
	else
		-- 处理普通数据
		if bDelete then
			DeleteInstanceInfoData(inst, info)
		else
			SetInstanceInfoData(inst, info, xValue, info.szVersion)
		end
	end
end

function X.IsUserSettingsAvailable()
	return DATABASE_CONNECTION_ESTABLISHED
end

function X.ConnectUserSettingsDB()
	if DATABASE_CONNECTION_ESTABLISHED then
		return
	end
	-- 角色共享方案
	X.LoadUserSettingsLocationOverride()
	local szID, szDBPresetRoot = X.GetUserSettingsPresetID(), nil
	if not X.IsEmpty(szID) then
		szDBPresetRoot = X.FormatPath({'config/settings/' .. szID .. '/', X.PATH_TYPE.GLOBAL})
		CPath.MakeDir(szDBPresetRoot)
		-- 兼容老数据结构
		for k, v in pairs(DATABASE_TYPE_PRESET_FILE_MIGRATE) do
			local szSrcPath = X.FormatPath(szDBPresetRoot .. k)
			local szDstPath = X.FormatPath(szDBPresetRoot .. DATABASE_TYPE_PRESET_FILE[v])
			if IsLocalFileExist(szSrcPath) then
				CPath.MakeDir(X.GetParentPath(szDstPath))
				CPath.Move(szSrcPath, szDstPath)
			end
		end
	end
	for _, ePathType in ipairs(DATABASE_TYPE_LIST) do
		if not DATABASE_INSTANCE[ePathType] then
			-- 用户数据
			local pUserDataDB = X.NoSQLiteConnect({'userdata/userdata.db', ePathType})
			if not pUserDataDB then
				X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Connect userdata database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			-- 普通配置/方案共享
			local pSettingsDB = X.NoSQLiteConnect(szDBPresetRoot and (szDBPresetRoot .. DATABASE_TYPE_PRESET_FILE[ePathType]) or {'config/settings.db', ePathType})
			if not pSettingsDB then
				X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Connect user settings database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			-- 角色独有
			local pRoleSettingsDB = X.NoSQLiteConnect({'config/settings.db', X.PATH_TYPE.ROLE})
			if not pRoleSettingsDB then
				X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Connect user role settings database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			-- 服务器共享
			local pServerSettingsDB = X.NoSQLiteConnect({'config/settings.db', X.PATH_TYPE.SERVER})
			if not pServerSettingsDB then
				X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Connect user role settings database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			-- 全局共享
			local pGlobalSettingsDB = X.NoSQLiteConnect({'config/settings.db', X.PATH_TYPE.GLOBAL})
			if not pGlobalSettingsDB then
				X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Connect user role settings database failed!!! ' .. ePathType, X.DEBUG_LEVEL.ERROR)
			end
			DATABASE_INSTANCE[ePathType] = {
				pUserDataDB = pUserDataDB,
				-- bUserDataDBCommit = false,
				pSettingsDB = pSettingsDB,
				-- bSettingsDBCommit = false,
				pRoleSettingsDB = pRoleSettingsDB,
				pServerSettingsDB = pServerSettingsDB,
				pGlobalSettingsDB = pGlobalSettingsDB,
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
	-- 遍历 DATA_CACHE 查找需要 flush 的数据
	for szKey, cache in pairs(DATA_CACHE) do
		local info = USER_SETTINGS_INFO[szKey]
		if info then
			local inst = DATABASE_INSTANCE[info.ePathType]
			if inst then
				if cache.bDataSet then
					-- 处理 DataSet 类型的数据
					for szDataSetKey, dataSetCache in pairs(cache.tDataSet) do
						if dataSetCache.bFlushRequired then
							FlushSettingsData(inst, info, szDataSetKey, dataSetCache.xValue, dataSetCache.bDeleted)
							-- 清除 flush 标记
							dataSetCache.bFlushRequired = nil
						end
					end
				else
					-- 处理普通数据
					if cache.bFlushRequired then
						FlushSettingsData(inst, info, nil, cache.xValue, cache.bDeleted)
						-- 清除 flush 标记
						cache.bFlushRequired = nil
					end
				end
			end
		end
	end
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
		szID = X.TrimString(szID)
		szID = X.TrimString(szID)
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
	return CPath.GetFolderList(X.FormatPath({'config/settings/', X.PATH_TYPE.GLOBAL}))
end

function X.RemoveUserSettingsPreset(szID)
	CPath.DelDir(X.FormatPath({'config/settings/' .. szID .. '/', X.PATH_TYPE.GLOBAL}))
end

-- 加载配置项存储位置重定向设置
function X.LoadUserSettingsLocationOverride()
	for k, _ in pairs(USER_SETTINGS_LOCATION_OVERRIDE) do
		USER_SETTINGS_LOCATION_OVERRIDE[k] = nil
	end
	local tLocationOverride = X.LoadLUAData({'config/usersettings-location-override.jx3dat', X.PATH_TYPE.ROLE})
	if X.IsTable(tLocationOverride) then
		for k, v in pairs(tLocationOverride) do
			if X.IsString(k) and X.IsNumber(v) then
				USER_SETTINGS_LOCATION_OVERRIDE[k] = v
			end
		end
	end
end

-- 保存配置项存储位置重定向设置
function X.SaveUserSettingsLocationOverride()
	X.SaveLUAData({'config/usersettings-location-override.jx3dat', X.PATH_TYPE.ROLE}, USER_SETTINGS_LOCATION_OVERRIDE)
end

-- 获取指定配置项是否被设定为角色不同步设置
---@param szKey string @配置项唯一标识符
---@return number @是否被设定为角色不同步设置
function X.GetUserSettingsLocationOverride(szKey)
	local info = USER_SETTINGS_INFO[szKey]
	if not info then
		assert(false, 'GetUserSettingsLocationOverride KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` has not been registered.')
	end
	return info.eLocationOverride
end

-- 设置指定配置项存储位置重定向设置
---@param szKey string @配置项唯一标识符
---@param eLocation number @配置项存储位置重定向设置 X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE
function X.SetUserSettingsLocationOverride(szKey, eLocation)
	local info = USER_SETTINGS_INFO[szKey]
	if not info then
		assert(false, 'SetUserSettingsLocationOverride KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` has not been registered.')
	end
	USER_SETTINGS_LOCATION_OVERRIDE[szKey] = eLocation
	X.DelayCall('LIB.SetUserSettingsLocationOverride', X.SaveUserSettingsLocationOverride)
	X.ReloadUserSettings(szKey)
end

-- 注册单个用户配置项
-- @param {string} szKey 配置项全局唯一键
-- @param {table} tOption 自定义配置项
--   {PATH_TYPE} tOption.ePathType 配置项保存位置（当前角色、当前服务器、全局）
--   {string} tOption.szDataKey 配置项入库时的键值，一般不需要手动指定，默认与配置项全局键值一致
--   {boolean} tOption.bUserData 配置项是否为角色数据项，为真将忽略预设方案重定向，禁止共用，禁止导入导出
--   {string} tOption.szGroup 配置项分组组标题，用于导入导出显示，禁止导入导出请留空
--   {string} tOption.szLabel 配置标题，用于导入导出显示，禁止导入导出请留空
--   {string} tOption.szDescription 配置描述，用于设置存储位置重定向显示描述
--   {string} tOption.szVersion 数据版本号，加载数据时会丢弃版本不一致的数据
--   {any} tOption.xDefaultValue 数据默认值
--   {number} tOption.eDefaultLocationOverride 配置项默认存储位置重定向设置，用于默认不参与方案共享的配置项
--   {schema} tOption.xSchema 数据类型约束对象，通过 Schema 库生成
--   {boolean} tOption.bDataSet 是否为配置项组（如用户多套自定义偏好），配置项组在读写时需要额外传入一个组下配置项唯一键值（即多套自定义偏好中某一项的名字）
--   {table} tOption.tDataSetDefaultValue 数据默认值（仅当 bDataSet 为真时生效，用于设置配置项组不同默认值）
--   {boolean} tOption.bPersistImmediatelyOnChange 是否在变更时立即持久化到文件，默认为 true，为 false 时变更会缓存在内存中等待系统空闲时写入
function X.RegisterUserSettings(szKey, tOption)
	local ePathType, szDataKey, bUserData, bNoExport, szGroup, szLabel, szDescription, szVersion, szRestriction, xDefaultValue, xSchema, bDataSet, tDataSetDefaultValue, eDefaultLocationOverride, bPersistImmediatelyOnChange
	if X.IsTable(tOption) then
		ePathType = tOption.ePathType
		szDataKey = tOption.szDataKey
		bUserData = tOption.bUserData
		bNoExport = tOption.bNoExport or tOption.bUserData
		szGroup = tOption.szGroup
		szLabel = tOption.szLabel
		szDescription = tOption.szDescription
		szRestriction = tOption.szRestriction
		szVersion = tOption.szVersion
		xDefaultValue = tOption.xDefaultValue
		xSchema = tOption.xSchema
		bDataSet = tOption.bDataSet
		tDataSetDefaultValue = tOption.tDataSetDefaultValue
		eDefaultLocationOverride = tOption.eDefaultLocationOverride
		bPersistImmediatelyOnChange = tOption.bPersistImmediatelyOnChange
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
	if X.IsNil(bPersistImmediatelyOnChange) then
		bPersistImmediatelyOnChange = true
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
			assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `DefaultValue` cannot pass `Schema` check.' .. '\n' .. table.concat(aErrmsgs, '\n'))
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
				assert(false, 'RegisterUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `DataSetDefaultValue` cannot pass `Schema` check.' .. '\n' .. table.concat(aErrmsgs, '\n'))
			end
		end
	end
	local tInfo = {
		szKey = szKey,
		ePathType = ePathType,
		bUserData = bUserData,
		bNoExport = bNoExport,
		szDataKey = szDataKey,
		szGroup = szGroup,
		szLabel = szLabel,
		szDescription = szDescription,
		szRestriction = szRestriction,
		szVersion = szVersion,
		xDefaultValue = xDefaultValue,
		xSchema = xSchema,
		bDataSet = bDataSet,
		tDataSetDefaultValue = tDataSetDefaultValue,
		eDefaultLocationOverride = eDefaultLocationOverride,
		bPersistImmediatelyOnChange = bPersistImmediatelyOnChange,
	}
	setmetatable(tInfo, {
		__index = function(t, k)
			if k == 'eLocationOverride' then
				return USER_SETTINGS_LOCATION_OVERRIDE[szKey]
					or t.eDefaultLocationOverride
					or X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.PRESET
			end
		end,
	})
	USER_SETTINGS_INFO[szKey] = tInfo
	table.insert(USER_SETTINGS_LIST, tInfo)
end

function X.GetRegisterUserSettingsList()
	local aList = {}
	for _, v in ipairs(USER_SETTINGS_LIST) do
		table.insert(aList, setmetatable({}, { __index = v }))
	end
	return aList
end

function X.ExportUserSettings(aKey)
	local tKvp = {}
	for _, szKey in ipairs(aKey) do
		local info = USER_SETTINGS_INFO[szKey]
		if info and not info.bNoExport then
			local inst = DATABASE_INSTANCE[info.ePathType]
			if inst then
				tKvp[szKey] = GetInstanceInfoData(inst, info)
			end
		end
	end
	return tKvp
end

function X.ImportUserSettings(tKvp)
	local nSuccess = 0
	for szKey, xValue in pairs(tKvp) do
		if X.IsTable(xValue) then
			local info = USER_SETTINGS_INFO[szKey]
			if info and not info.bNoExport then
				local inst = DATABASE_INSTANCE[info.ePathType]
				if inst then
					SetInstanceInfoData(inst, info, xValue.d, xValue.v)
					nSuccess = nSuccess + 1
					DATA_CACHE[szKey] = nil
				end
			end
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
	-- 参数检查
	local res, bData, bCache = nil, false, false
	local info = USER_SETTINGS_INFO[szKey]
	if not info then
		assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): `Key` has not been registered.')
	end
	local nParameter = select('#', ...) + 1
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
	-- 缓存加速
	local cache = DATA_CACHE[szKey]
	if info.bDataSet and ... then
		cache = X.IsTable(cache) and cache.bDataSet
			and cache.tDataSet[...]
			or nil
	end
	if X.IsTable(cache) and cache.bValue then
		-- 从缓存获取数据，如果标记为删除则返回默认值
		if cache.bDeleted then
			-- 数据被删除但还没有 flush，直接返回默认值
			bData, bCache = false, true
		else
			res, bData, bCache = cache.xValue, true, true
		end
	end
	-- 未命中缓存，从数据库读取
	if not bCache then
		-- 参数检查
		local inst = DATABASE_INSTANCE[info.ePathType]
		if not inst then
			assert(false, 'GetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): Database not connected.')
		end
		-- 读数据库
		res, bData = GetInstanceInfoData(inst, info), false
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
	-- 写入缓存
	if not bCache then
		if info.bDataSet then
			if not DATA_CACHE[szKey] then
				DATA_CACHE[szKey] = { bDataSet = true, tDataSet = {} }
			end
			DATA_CACHE[szKey].tDataSet[szDataSetKey] = {
				bValue = true,
				xValue = res,
				xRawValue = X.Clone(res),
				bDeleted = false,
			}
		else
			DATA_CACHE[szKey] = {
				bValue = true,
				xValue = res,
				xRawValue = X.Clone(res),
				bDeleted = false,
			}
		end
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
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): Database not connected!!!', X.DEBUG_LEVEL.WARNING)
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
		cache = cache and cache.tDataSet[szDataSetKey]
	else
		if nParameter ~= 2 then
			assert(false, 'SetUserSettings KEY(' .. X.EncodeLUAData(szKey) .. '): 2 parameters expected, got ' .. nParameter)
		end
		xValue = ...
	end
	if cache and cache.bValue and X.IsEquals(cache.xRawValue, xValue) then
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
		-- 更新缓存
		if not DATA_CACHE[szKey] then
			DATA_CACHE[szKey] = { bDataSet = true, tDataSet = {} }
		end
		DATA_CACHE[szKey].tDataSet[szDataSetKey] = {
			bValue = true,
			xValue = X.Clone(xValue),
			xRawValue = X.Clone(xValue),
			bFlushRequired = not info.bPersistImmediatelyOnChange,
			bDeleted = false,
		}
		if info.bPersistImmediatelyOnChange then
			FlushSettingsData(inst, info, szDataSetKey, xValue, false)
		end
	else
		-- 更新缓存
		DATA_CACHE[szKey] = {
			bValue = true,
			xValue = X.Clone(xValue),
			xRawValue = X.Clone(xValue),
			bFlushRequired = not info.bPersistImmediatelyOnChange,
			bDeleted = false,
		}
		if info.bPersistImmediatelyOnChange then
			FlushSettingsData(inst, info, nil, xValue, false)
		end
	end
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
	X.CommonEventFirer(USER_SETTINGS_UPDATE_EVENT, szKey)
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
		-- 更新缓存
		if not DATA_CACHE[szKey] then
			DATA_CACHE[szKey] = { bDataSet = true, tDataSet = {} }
		end
		if szDataSetKey then
			DATA_CACHE[szKey].tDataSet[szDataSetKey] = {
				bValue = true,
				xValue = nil,
				xRawValue = nil,
				bFlushRequired = not info.bPersistImmediatelyOnChange,
				bDeleted = true,
			}
			if info.bPersistImmediatelyOnChange then
				FlushSettingsData(inst, info, szDataSetKey, nil, true)
			end
		else
			-- 重置整个 DataSet
			DATA_CACHE[szKey] = nil
			if info.bPersistImmediatelyOnChange then
				FlushSettingsData(inst, info, nil, nil, true)
			end
		end
	else
		-- 更新缓存
		DATA_CACHE[szKey] = {
			bValue = true,
			xValue = nil,
			xRawValue = nil,
			bFlushRequired = not info.bPersistImmediatelyOnChange,
			bDeleted = true,
		}
		if info.bPersistImmediatelyOnChange then
			FlushSettingsData(inst, info, nil, nil, true)
		end
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
		__call = function(t, cmd, arg0)
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
			elseif cmd == 'flush' then
				t[arg0] = t[arg0]
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
		if tSettings.szKey then
			k = tSettings.szKey
		end
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

------------------------------------------------------------------------------
-- 根据 2022年5月17日 导出的接口 GetClientPlayerGlobalID()，
-- 获取用户ID可提前至 SYNC_ROLE_DATA_BEGIN 事件，
-- 而此事件发生于插件加载之前，因此可以直接初始化用户数据。
------------------------------------------------------------------------------
X.SafeCall(function()
	if X.GetClientPlayerGlobalID() then
		X.ConnectUserSettingsDB()
	end
end)

-- Hack方式优化用户数据逻辑，创建一个窗口用于退出游戏断开数据库链接
X.SafeCall(function()
	local frame = Wnd.OpenWindow(X.PACKET_INFO.FRAMEWORK_ROOT .. '/ui/components/WndFrameEmpty.ini', X.NSFormatString('{$NS}#UserSettingsReleaseListener'))
	local nCount = 0
	frame.OnFrameBreathe = function()
		if nCount > 0 then
			nCount = nCount - 1
			return
		end
		nCount = 128
		this:BringToTop()
	end
	frame.OnFrameDestroy = function()
		X.ReleaseUserSettingsDB()
	end
	frame:ChangeRelation('Topmost2')
	frame:SetRelPos(-10000, -10000)
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
