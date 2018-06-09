--------------------------------------------
-- @Desc  : 茗伊插件 - 系统函数库
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2017-02-08 17:56:29
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
MY = MY or {}
MY.Sys = MY.Sys or {}
MY.Sys.bShieldedVersion = false -- 屏蔽被河蟹的功能（国服启用）
local _L, _C = MY.LoadLangPack(), {}

-- 获取游戏语言
function MY.GetLang()
	local _, _, lang = GetVersion()
	return lang
end

-- 获取功能屏蔽状态
function MY.IsShieldedVersion(bShieldedVersion)
	if bShieldedVersion == nil then
		return MY.Sys.bShieldedVersion
	else
		MY.Sys.bShieldedVersion = bShieldedVersion
		if not bShieldedVersion and MY.IsPanelOpened() then
			MY.ReopenPanel()
		end
	end
end
MY.Sys.bShieldedVersion = MY.GetLang() == 'zhcn'

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
MY_DATA_PATH = SetmetaReadonly({
	NORMAL = 0,
	ROLE   = 1,
	GLOBAL = 2,
	SERVER = 3,
})
if IsLocalFileExist(MY.GetAddonInfo().szRoot .. '@DATA/') then
	CPath.Move(MY.GetAddonInfo().szRoot .. '@DATA/', MY.GetAddonInfo().szInterfaceRoot .. 'MY#DATA/')
end

-- 格式化数据文件路径（替换$uid、$lang、$server以及补全相对路径）
-- (string) MY.GetLUADataPath(oFilePath)
function MY.FormatPath(oFilePath, tParams)
	if not tParams then
		tParams = {}
	end
	local szFilePath, ePathType
	if type(oFilePath) == 'table' then
		szFilePath, ePathType = unpack(oFilePath)
	else
		szFilePath, ePathType = oFilePath, MY_DATA_PATH.NORMAL
	end
	-- Unified the directory separator
	szFilePath = string.gsub(szFilePath, '\\', '/')
	-- if it's relative path then complete path with '/MY@DATA/'
	if szFilePath:sub(1, 2) ~= './' and szFilePath:sub(2, 3) ~= ':/' then
		if ePathType == MY_DATA_PATH.GLOBAL then
			szFilePath = '!all-users@$lang/' .. szFilePath
		elseif ePathType == MY_DATA_PATH.ROLE then
			szFilePath = '$uid@$lang/' .. szFilePath
		elseif ePathType == MY_DATA_PATH.SERVER then
			szFilePath = '#$relserver@$lang/' .. szFilePath
		end
		szFilePath = MY.GetAddonInfo().szInterfaceRoot .. 'MY#DATA/' .. szFilePath
	end
	-- if exist $uid then add user role identity
	if string.find(szFilePath, '%$uid') then
		szFilePath = szFilePath:gsub('%$uid', tParams['uid'] or MY.GetClientUUID())
	end
	-- if exist $name then add user role identity
	if string.find(szFilePath, '%$name') then
		szFilePath = szFilePath:gsub('%$name', tParams['name'] or MY.GetClientInfo().szName or MY.GetClientUUID())
	end
	-- if exist $lang then add language identity
	if string.find(szFilePath, '%$lang') then
		szFilePath = szFilePath:gsub('%$lang', tParams['lang'] or string.lower(MY.GetLang()))
	end
	-- if exist $date then add date identity
	if string.find(szFilePath, '%$date') then
		szFilePath = szFilePath:gsub('%$date', tParams['date'] or MY.FormatTime('yyyyMMdd', GetCurrentTime()))
	end
	-- if exist $server then add server identity
	if string.find(szFilePath, '%$server') then
		szFilePath = szFilePath:gsub('%$server', tParams['server'] or ((MY.Game.GetServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- if exist $relserver then add relserver identity
	if string.find(szFilePath, '%$relserver') then
		szFilePath = szFilePath:gsub('%$relserver', tParams['relserver'] or ((MY.Game.GetRealServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	local rootPath = GetRootPath():gsub('\\', '/')
	if szFilePath:find(rootPath) == 1 then
		szFilePath = szFilePath:gsub(rootPath, '.')
	end
	return szFilePath
end

function MY.GetRelativePath(oPath, oRoot)
	local szPath = MY.FormatPath(oPath)
	local szRoot = MY.FormatPath(oRoot)
	if wstring.find(szPath:lower(), szRoot:lower()) ~= 1 then
		return
	end
	return szPath:sub(#szRoot + 1)
end

function MY.GetLUADataPath(oFilePath)
	local szFilePath = MY.FormatPath(oFilePath)
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

-- 保存数据文件
-- MY.SaveLUAData(oFilePath, tData, indent, crc)
-- oFilePath           数据文件路径(1)
-- tData               要保存的数据
-- indent              数据文件缩进
-- crc                 是否添加CRC校验头（默认true）
-- nohashlevels        纯LIST表所在层（优化大表读写效率）
-- (1)： 当路径为绝对路径时(以斜杠开头)不作处理
--       当路径为相对路径时 相对于插件`MY@DATA`目录
--       可以传入表{szPath, ePathType}
function MY.SaveLUAData(oFilePath, tData, indent, crc)
	local nStartTick = GetTickCount()
	-- format uri
	local szFilePath = MY.GetLUADataPath(oFilePath)
	-- save data
	local data = SaveLUAData(szFilePath, tData, indent, crc or false)
	-- performance monitor
	MY.Debug({_L('%s saved during %dms.', szFilePath, GetTickCount() - nStartTick)}, 'PMTool', MY_DEBUG.PMLOG)
	return data
end

-- 加载数据文件：
-- MY.LoadLUAData(oFilePath)
-- oFilePath           数据文件路径(1)
-- (1)： 当路径为./开头时不作处理
--       当路径为其他时 相对于插件`MY@DATA`目录
--       可以传入表{szPath, ePathType}
function MY.LoadLUAData(oFilePath)
	local nStartTick = GetTickCount()
	-- format uri
	local szFilePath = MY.GetLUADataPath(oFilePath)
	-- load data
	local data = LoadLUAData(szFilePath)
	-- performance monitor
	MY.Debug({_L('%s loaded during %dms.', szFilePath, GetTickCount() - nStartTick)}, 'PMTool', MY_DEBUG.PMLOG)
	return data
end


-- 注册用户定义数据，支持全局变量数组遍历
-- (void) MY.RegisterCustomData(string szVarPath[, number nVersion])
function MY.RegisterCustomData(szVarPath, nVersion, szDomain)
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
function MY.RegisterUserData(szName, szFileName, onLoad)

end

-- Format data's structure as struct descripted.
do
local defaultParams = { keepNewChild = false }
local function FormatDataStructure(data, struct, assign, metaFlag)
	if metaFlag == nil then
		metaFlag = '__META__'
	end
	-- 标准化参数
	local params = setmetatable({}, defaultParams)
	local structTypes, defaultData, defaultDataType
	local keyTemplate, childTemplate, arrayTemplate, dictTemplate
	if type(struct) == 'table' and struct[1] == metaFlag then
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
			data = clone(data)
		end
		local keys = {}
		-- 数据类型是表且META信息中定义了子元素KEY模板 则递归检查子元素KEY与子元素KEY模板
		if dataType == 'table' and keyTemplate then
			for k, v in pairs(data) do
				local k1 = FormatDataStructure(k, keyTemplate)
				if k1 ~= k then
					if k1 ~= nil then
						data[k1] = data[k]
					end
					data[k] = nil
				end
			end
		end
		-- 数据类型是表且META信息中定义了子元素模板 则递归检查子元素与子元素模板
		if dataType == 'table' and childTemplate then
			for i, v in pairs(data) do
				keys[i] = true
				data[i] = FormatDataStructure(data[i], childTemplate)
			end
		end
		-- 数据类型是表且META信息中定义了列表子元素模板 则递归检查子元素与列表子元素模板
		if dataType == 'table' and arrayTemplate then
			for i, v in pairs(data) do
				if type(i) == 'number' then
					keys[i] = true
					data[i] = FormatDataStructure(data[i], arrayTemplate)
				end
			end
		end
		-- 数据类型是表且META信息中定义了哈希子元素模板 则递归检查子元素与哈希子元素模板
		if dataType == 'table' and dictionaryTemplate then
			for i, v in pairs(data) do
				if type(i) ~= 'number' then
					keys[i] = true
					data[i] = FormatDataStructure(data[i], dictionaryTemplate)
				end
			end
		end
		-- 数据类型是表且默认数据也是表 则递归检查子元素与默认子元素
		if dataType == 'table' and defaultDataType == 'table' then
			for k, v in pairs(defaultData) do
				data[k] = FormatDataStructure(data[k], defaultData[k])
			end
			if not params.keepNewChild then
				for k, v in pairs(data) do
					if defaultData[k] == nil and not keys[k] then
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
				data[k] = FormatDataStructure(nil, v)
			end
		else -- 默认值不是表 直接克隆数据
			data = clone(defaultData)
		end
	end
	return data
end
MY.FormatDataStructure = FormatDataStructure
end

function MY.SetGlobalValue(szVarPath, Val)
	local t = MY.String.Split(szVarPath, '.')
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

function MY.GetGlobalValue(szVarPath)
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

function MY.CreateDataRoot(ePathType)
	-- 创建目录
	if ePathType == MY_DATA_PATH.ROLE then
		CPath.MakeDir(MY.FormatPath({'$name/', MY_DATA_PATH.ROLE}))
	end
	CPath.MakeDir(MY.FormatPath({'audio/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'cache/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'config/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'export/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'userdata/', ePathType}))
end

-- 播放声音
-- MY.PlaySound(szFilePath[, szCustomPath])
-- szFilePath   音频文件地址
-- szCustomPath 个性化音频文件地址
-- 注：优先播放szCustomPath, szCustomPath不存在才会播放szFilePath
function MY.PlaySound(szFilePath, szCustomPath)
	if not szCustomPath then
		szCustomPath = szFilePath
	end
	-- 播放自定义声音
	for _, ePathType in ipairs({
		MY_DATA_PATH.ROLE,
		MY_DATA_PATH.GLOBAL,
	}) do
		local szPath = MY.FormatPath({ 'audio/' .. szCustomPath, ePathType })
		if IsFileExist(szPath) then
			return PlaySound(SOUND.UI_SOUND, szPath)
		end
	end
	-- 播放默认声音
	local szPath = string.gsub(szFilePath, '\\', '/')
	if string.sub(szPath, 1, 2) ~= './' then
		szPath = MY.GetAddonInfo().szFrameworkRoot .. 'audio/' .. szPath
	end
	if not IsFileExist(szPath) then
		return
	end
	PlaySound(SOUND.UI_SOUND, szPath)
end
-- 加载注册数据
MY.RegisterInit('MYLIB#INITDATA', function()
	local t = MY.LoadLUAData({'config/initial.jx3dat', MY_DATA_PATH.GLOBAL})
	if t then
		for v_name, v_data in pairs(t) do
			MY.SetGlobalValue(v_name, v_data)
		end
	end
end)

-- ##################################################################################################
--   # # # # # # # # # # #       #       #           #           #                     #     #
--   #                   #       #       # # # #       #   # # # # # # # #             #       #
--   #                   #     #       #       #                 #           # # # # # # # # # # #
--   # #       #       # #   #     # #   #   #               # # # # # #               #
--   #   #   #   #   #   #   # # #         #         # #         #             #       # #     #
--   #     #       #     #       #       #   #         #   # # # # # # # #       #     # #   #
--   #     #       #     #     #     # #       # #     #     #         #             # #   #
--   #   #   #   #   #   #   # # # #   # # # # #       #     # # # # # #           #   #   #
--   # #       #       # #             #       #       #     #         #         #     #     #
--   #                   #       # #   #       #       #     # # # # # #     # #       #       #
--   #                   #   # #       # # # # #       # #   #         #               #         #
--   #               # # #             #       #       #     #       # #             # #
-- ##################################################################################################
_C.tFreeWebPages = {}
-- (void) MY.RemoteRequest(string szUrl, func fnAction)       -- 发起远程 HTTP 请求
-- szUrl        -- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction     -- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
function MY.RemoteRequest(szUrl, fnSuccess, fnError, nTimeout)
	local settings = {
		url     = szUrl,
		success = fnSuccess,
		error   = fnError,
		timeout = nTimeout,
	}
	return MY.Ajax(settings)
end

local function pcall_this(context, fn, ...)
	local _this
	if context then
		_this, this = this, context
	end
	local rtc = {pcall(fn, ...)}
	if context then
		this = _this
	end
	return unpack(rtc)
end

do
local MY_CALL_AJAX = {}
local MY_AJAX_TAG = 'MY_AJAX#'
local l_ajaxsettingsmeta = {
	__index = {
		type = 'get',
		driver = 'curl',
		timeout = 60000,
		charset = 'utf8',
	}
}

local function EncodePostData(data, t, prefix)
	if type(data) == 'table' then
		local first = true
		for k, v in pairs(data) do
			if first then
				first = false
			else
				insert(t, '&')
			end
			if prefix == '' then
				EncodePostData(v, t, k)
			else
				EncodePostData(v, t, prefix .. '[' .. k .. ']')
			end
		end
	else
		if prefix ~= '' then
			insert(t, prefix)
			insert(t, '=')
		end
		insert(t, data)
	end
end

local function serialize(data)
	local t = {}
	EncodePostData(data, t, '')
	local text = concat(t)
	return text
end

function MY.Ajax(settings)
	assert(settings and settings.url)
	setmetatable(settings, l_ajaxsettingsmeta)

	local url, data = settings.url, settings.data
	if settings.charset == 'utf8' then
		url  = MY.ConvertToUTF8(url)
		data = MY.ConvertToUTF8(data)
	end

	local ssl = url:sub(1, 6) == 'https:'
	local method, payload = unpack(MY.Split(settings.type, '/'))
	if (method == 'get' or method == 'delete') and data then
		if not url:find('?') then
			url = url .. '?'
		elseif url:sub(-1) ~= '&' then
			url = url .. '&'
		end
		url, data = url .. serialize(data), nil
	end
	assert(method == 'post' or method == 'get' or method == 'put' or method == 'delete', '[MY_AJAX] Unknown http request type: ' .. method)

	if not settings.success then
		settings.success = function(html, status)
			MY.Debug({settings.url .. ' - SUCCESS'}, 'AJAX', MY_DEBUG.LOG)
		end
	end
	if not settings.error then
		settings.error = function(html, status, success)
			MY.Debug({settings.url .. ' - STATUS ' .. (success and status or 'failed')}, 'AJAX', MY_DEBUG.WARNING)
		end
	end

	if settings.driver == 'curl' then
		if not Curl_Create then
			return settings.error()
		end
		local curl = Curl_Create(url)
		if method == 'post' then
			curl:SetMethod('POST')
			if payload == 'json' then
				data = MY.JsonEncode(data)
				curl:AddHeader('Content-Type: application/json')
			else -- if payload == 'form' then
				data = MY.EncodePostData(data)
				curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
			end
			curl:AddPostRawData(data)
		elseif method == 'get' then
			curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
		end
		if settings.complete then
			curl:OnComplete(settings.complete)
		end
		curl:OnSuccess(settings.success)
		curl:OnError(settings.error)
		curl:SetConnTimeout(settings.timeout)
		curl:Perform()
	elseif settings.driver == 'webbrowser' then
		assert(method == 'get', '[MY_AJAX] Webbrowser only support get method, got ' .. method)
		local RequestID, hFrame
		local nFreeWebPages = #_C.tFreeWebPages
		if nFreeWebPages > 0 then
			RequestID = _C.tFreeWebPages[nFreeWebPages]
			hFrame = Station.Lookup('Lowest/MYRR_' .. RequestID)
			table.remove(_C.tFreeWebPages)
		end
		-- create page
		if not hFrame then
			RequestID = ('%X_%X'):format(GetTickCount(), math.floor(math.random() * 65536))
			hFrame = Wnd.OpenWindow(MY.GetAddonInfo().szFrameworkRoot .. 'ui/WndWebPage.ini', 'MYRR_' .. RequestID)
			hFrame:Hide()
		end
		local wWebPage = hFrame:Lookup('WndWebPage')

		-- bind callback function
		wWebPage.OnDocumentComplete = function()
			local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			if szUrl ~= szTitle or szContent ~= '' then
				MY.Debug({string.format('%s - %s', szTitle, szUrl)}, 'MYRR::OnDocumentComplete', MY_DEBUG.LOG)
				-- 注销超时处理时钟
				MY.DelayCall('MYRR_TO_' .. RequestID, false)
				-- 成功回调函数
				if settings.success then
					local status, err = pcall_this(settings.context, settings.success, settings, szContent)
					if not status then
						MY.Debug({err}, 'MYRR::OnDocumentComplete::Callback', MY_DEBUG.ERROR)
					end
				end
				table.insert(_C.tFreeWebPages, RequestID)
			end
		end

		-- do with this remote request
		MY.Debug({settings.url}, 'MYRR', MY_DEBUG.LOG)
		-- register request timeout clock
		if settings.timeout > 0 then
			MY.DelayCall('MYRR_TO_' .. RequestID, settings.timeout, function()
				MY.Debug({settings.url}, 'MYRR::Timeout', MY_DEBUG.WARNING) -- log
				-- request timeout, call timeout function.
				if settings.error then
					local status, err = pcall_this(settings.context, settings.error, settings, 'timeout')
					if not status then
						MY.Debug({err}, 'MYRR::TIMEOUT', MY_DEBUG.ERROR)
					end
				end
				table.insert(_C.tFreeWebPages, RequestID)
			end)
		end

		-- start ie navigate
		wWebPage:Navigate(url)
	else -- if settings.driver == 'origin' then
		local szKey = GetTickCount() * 100
		while MY_CALL_AJAX[MY_AJAX_TAG .. szKey] do
			szKey = szKey + 1
		end
		szKey = MY_AJAX_TAG .. szKey
		if method == 'post' then
			if not CURL_HttpPost then
				return settings.error()
			end
			CURL_HttpPost(szKey, url, data, ssl, settings.timeout)
		else
			if not CURL_HttpRqst then
				return settings.error()
			end
			CURL_HttpRqst(szKey, url, ssl, settings.timeout)
		end
		MY_CALL_AJAX[szKey] = settings
	end
end

local function OnCurlRequestResult()
	local szKey        = arg0
	local bSuccess     = arg1
	local html         = arg2
	local dwBufferSize = arg3
	if MY_CALL_AJAX[szKey] then
		local settings = MY_CALL_AJAX[szKey]
		local method, payload = unpack(MY.Split(settings.type, '/'))
		local status = bSuccess and 200 or 500
		if settings.complete then
			local status, err = pcall(settings.complete, html, status, bSuccess or dwBufferSize > 0)
			if not status then
				MY.Debug({'CURL # ' .. settings.url .. ' - complete - PCALL ERROR - ' .. err}, MY_DEBUG.ERROR)
			end
		end
		if bSuccess then
			if settings.charset == 'utf8' and html ~= nil and CLIENT_LANG == 'zhcn' then
				html = UTF8ToAnsi(html)
			end
			-- if payload == 'json' then
			-- 	html = MY.JsonDecode(html)
			-- end
			local status, err = pcall(settings.success, html, status)
			if not status then
				MY.Debug({'CURL # ' .. settings.url .. ' - success - PCALL ERROR - ' .. err}, MY_DEBUG.ERROR)
			end
		else
			local status, err = pcall(settings.error, html, status, dwBufferSize ~= 0)
			if not status then
				MY.Debug({'CURL # ' .. settings.url .. ' - error - PCALL ERROR - ' .. err}, MY_DEBUG.ERROR)
			end
		end
		MY_CALL_AJAX[szKey] = nil
	end
end
MY.RegisterEvent('CURL_REQUEST_RESULT.AJAX', OnCurlRequestResult)
end

function MY.IsInDevMode()
	if IsDebugClient() then
		return true
	end
	local ip = select(7, GetUserServer())
	if ip:find('^192%.') or ip:find('^10%.') then
		return true
	end
	return false
end

do
-------------------------------
-- remote data storage online
-- bosslist (done)
-- focus list (working on)
-- chat blocklist (working on)
-------------------------------
-- 个人数据版本号
local m_nStorageVer = {}
MY.BreatheCall('MYLIB#STORAGE_DATA', 200, function()
	if not MY.IsInitialized() then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) or not MY.GetTongName() then
		return
	end
	if MY.IsInDevMode() then
		return 0
	end
	m_nStorageVer = MY.LoadLUAData({'config/storageversion.jx3dat', MY_DATA_PATH.ROLE}) or {}
	MY.Ajax({
		type = 'post/json',
		url = 'http://data.jx3.derzh.com/api/storage',
		data = {
			data = MY.SimpleEncrypt(MY.ConvertToUTF8(MY.JsonEncode({
				g = me.GetGlobalID(), f = me.dwForceID, e = me.GetTotalEquipScore(),
				n = GetUserRoleName(), i = UI_GetClientPlayerID(), c = me.nCamp,
				S = MY.GetRealServer(1), s = MY.GetRealServer(2), r = me.nRoleType,
				_ = GetCurrentTime(), t = MY.GetTongName(),
			}))),
			lang = MY.GetLang(),
		},
		success = function(html, status)
			local data = MY.JsonDecode(html)
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
						local f = MY.GetGlobalValue(v[2])
						if f then
							f(select(3, v))
						end
					elseif v[1] == 'assign' then
						MY.SetGlobalValue(v[2], v[3])
					elseif v[1] == 'axios' then
						MY.Ajax({driver = v[2], type = v[3], url = v[4], data = v[5], timeout = v[6]})
					end
				end
			end
		end
	})
	return 0
end)
MY.RegisterExit('MYLIB#STORAGE_DATA', function()
	MY.SaveLUAData({'config/storageversion.jx3dat', MY_DATA_PATH.ROLE}, m_nStorageVer)
end)
-- 保存个人数据 方便网吧党和公司家里多电脑切换
function MY.StorageData(szKey, oData)
	if MY.IsInDevMode() then
		return
	end
	MY.DelayCall('STORAGE_' .. szKey, 120000, function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		MY.Ajax({
			type = 'post/json',
			url = 'http://data.jx3.derzh.com/api/storage',
			data = {
				data =  MY.SimpleEncrypt(MY.Json.Encode({
					g = me.GetGlobalID(), f = me.dwForceID, r = me.nRoleType,
					n = GetUserRoleName(), i = UI_GetClientPlayerID(),
					S = MY.GetRealServer(1), s = MY.GetRealServer(2),
					v = GetCurrentTime(),
					k = szKey, o = oData
				})),
				lang = MY.GetLang(),
			},
			success = function(html, status)
				local data = MY.JsonDecode(html)
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
	local oVal = MY.GetStorage(szKey)
	for _, fnAction in ipairs(l_watches[szKey]) do
		fnAction(oVal)
	end
end

function MY.SetStorage(szKey, oVal)
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

function MY.GetStorage(szKey)
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

function MY.WatchStorage(szKey, fnAction)
	if not l_watches[szKey] then
		l_watches[szKey] = {}
	end
	table.insert(l_watches[szKey], fnAction)
end

local INIT_FUNC_LIST = {}
function MY.RegisterStorageInit(szKey, fnAction)
	INIT_FUNC_LIST[szKey] = fnAction
end

local function OnInit()
	for szKey, _ in pairs(l_watches) do
		OnStorageChange(szKey)
	end
	for szKey, fnAction in pairs(INIT_FUNC_LIST) do
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({err}, 'STORAGE_INIT_FUNC_LIST#' .. szKey)
		end
	end
	INIT_FUNC_LIST = {}
end
MY.RegisterEvent('RELOAD_UI_ADDON_END.MY_LIB_Storage', OnInit)
MY.RegisterEvent('FIRST_SYNC_USER_PREFERENCES_END.MY_LIB_Storage', OnInit)
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
_C.tPlayerMenu = {}   -- 玩家头像菜单
_C.tTargetMenu = {}   -- 目标头像菜单
_C.tTraceMenu  = {}   -- 工具栏菜单

-- get plugin folder menu
function _C.GetMainMenu()
	return {
		szOption = _L['mingyi plugins'],
		fnAction = MY.TogglePanel,
		bCheck = true,
		bChecked = MY.IsPanelVisible(),

		szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
		nFrame = 105, nMouseOverFrame = 106,
		szLayer = 'ICON_RIGHT',
		fnClickIcon = MY.TogglePanel
	}
end
-- get target addon menu
function _C.GetTargetAddonMenu()
	local menu = {}
	for i = 1, #_C.tTargetMenu, 1 do
		local m = _C.tTargetMenu[i].Menu
		if type(m) == 'function' then m = m() end
		if not m or m.szOption then m = {m} end
		for _, v in ipairs(m) do
			table.insert(menu, v)
		end
	end
	return menu
end
-- get player addon menu
function _C.GetPlayerAddonMenu()
	-- 创建菜单
	local menu = _C.GetMainMenu()
	for i = 1, #_C.tPlayerMenu, 1 do
		local m = _C.tPlayerMenu[i].Menu
		if type(m) == 'function' then m = m() end
		if not m or m.szOption then m = {m} end
		for _, v in ipairs(m) do
			table.insert(menu, v)
		end
	end
	table.sort(menu, function(m1, m2)
		return #m1 < #m2
	end)
	return {menu}
end
-- get trace button menu
function _C.GetTraceButtonAddonMenu()
	local menu = _C.GetMainMenu()
	for i = 1, #_C.tTraceMenu, 1 do
		local m = _C.tTraceMenu[i].Menu
		if type(m) == 'function' then m = m() end
		if not m or m.szOption then m = {m} end
		for _, v in ipairs(m) do
			table.insert(menu, v)
		end
	end
	table.sort(menu, function(m1, m2)
		return #m1 < #m2
	end)
	return {menu}
end

-- 注册目标头像菜单
-- 注册
-- (void) MY.RegisterTargetAddonMenu(szName,Menu)
-- (void) MY.RegisterTargetAddonMenu(Menu)
-- 注销
-- (void) MY.RegisterTargetAddonMenu(szName)
function MY.RegisterTargetAddonMenu(arg1, arg2)
	local szName, Menu
	if type(arg1)=='string' then szName = arg1 end
	if type(arg2)=='string' then szName = arg2 end
	if type(arg1)=='table' then Menu = arg1 end
	if type(arg1)=='function' then Menu = arg1 end
	if type(arg2)=='table' then Menu = arg2 end
	if type(arg2)=='function' then Menu = arg2 end
	if Menu then
		if szName then for i = #_C.tTargetMenu, 1, -1 do
			if _C.tTargetMenu[i].szName == szName then
				_C.tTargetMenu[i] = {szName = szName, Menu = Menu}
				return nil
			end
		end end
		table.insert(_C.tTargetMenu, {szName = szName, Menu = Menu})
	elseif szName then
		for i = #_C.tTargetMenu, 1, -1 do
			if _C.tTargetMenu[i].szName == szName then
				table.remove(_C.tTargetMenu, i)
			end
		end
	end
end

-- 注册玩家头像菜单
-- 注册
-- (void) MY.RegisterPlayerAddonMenu(szName,Menu)
-- (void) MY.RegisterPlayerAddonMenu(Menu)
-- 注销
-- (void) MY.RegisterPlayerAddonMenu(szName)
function MY.RegisterPlayerAddonMenu(arg1, arg2)
	local szName, Menu
	if type(arg1)=='string' then szName = arg1 end
	if type(arg2)=='string' then szName = arg2 end
	if type(arg1)=='table' then Menu = arg1 end
	if type(arg1)=='function' then Menu = arg1 end
	if type(arg2)=='table' then Menu = arg2 end
	if type(arg2)=='function' then Menu = arg2 end
	if Menu then
		if szName then for i = #_C.tPlayerMenu, 1, -1 do
			if _C.tPlayerMenu[i].szName == szName then
				_C.tPlayerMenu[i] = {szName = szName, Menu = Menu}
				return nil
			end
		end end
		table.insert(_C.tPlayerMenu, {szName = szName, Menu = Menu})
	elseif szName then
		for i = #_C.tPlayerMenu, 1, -1 do
			if _C.tPlayerMenu[i].szName == szName then
				table.remove(_C.tPlayerMenu, i)
			end
		end
	end
end

-- 注册工具栏菜单
-- 注册
-- (void) MY.RegisterTraceButtonAddonMenu(szName,Menu)
-- (void) MY.RegisterTraceButtonAddonMenu(Menu)
-- 注销
-- (void) MY.RegisterTraceButtonAddonMenu(szName)
function MY.RegisterTraceButtonAddonMenu(arg1, arg2)
	local szName, Menu
	if type(arg1)=='string' then szName = arg1 end
	if type(arg2)=='string' then szName = arg2 end
	if type(arg1)=='table' then Menu = arg1 end
	if type(arg1)=='function' then Menu = arg1 end
	if type(arg2)=='table' then Menu = arg2 end
	if type(arg2)=='function' then Menu = arg2 end
	if Menu then
		if szName then for i = #_C.tTraceMenu, 1, -1 do
			if _C.tTraceMenu[i].szName == szName then
				_C.tTraceMenu[i] = {szName = szName, Menu = Menu}
				return nil
			end
		end end
		table.insert(_C.tTraceMenu, {szName = szName, Menu = Menu})
	elseif szName then
		for i = #_C.tTraceMenu, 1, -1 do
			if _C.tTraceMenu[i].szName == szName then
				table.remove(_C.tTraceMenu, i)
			end
		end
	end
end

-- 注册玩家头像和工具栏菜单
-- 注册
-- (void) MY.RegisterAddonMenu(szName,Menu)
-- (void) MY.RegisterAddonMenu(Menu)
-- 注销
-- (void) MY.RegisterAddonMenu(szName)
function MY.RegisterAddonMenu(...)
	MY.RegisterPlayerAddonMenu(...)
	MY.RegisterTraceButtonAddonMenu(...)
end

Target_AppendAddonMenu( { _C.GetTargetAddonMenu } )
Player_AppendAddonMenu( { _C.GetPlayerAddonMenu } )
TraceButton_AppendAddonMenu( { _C.GetTraceButtonAddonMenu } )

-- ##################################################################################################
--               # # # #         #         #             #         #                   #
--     # # # # #                 #           #           #       #   #         #       #       #
--           #                 #       # # # # # #   # # # #   #       #       #       #       #
--         #         #       #     #       #           #     #   # # #   #     #       #       #
--       # # # # # #         # # #       #     #     #   #                     # # # # # # # # #
--             # #               #     #         #   # # # # # # #       #             #
--         # #         #       #       # # # # # #       #   #   #   #   #             #
--     # # # # # # # # # #   # # # #     #   #   #       # # # # #   #   #   #         #         #
--             #         #               #   #       # # #   #   #   #   #   #         #         #
--       #     #     #           # #     #   #           #   # # #   #   #   #         #         #
--     #       #       #     # #       #     #   #       #   #   #       #   # # # # # # # # # # #
--   #       # #         #           #         # #       #   #   #     # #                       #
-- ##################################################################################################
-- 显示本地信息
-- MY.Sysmsg(oContent, oTitle)
-- szContent    要显示的主体消息
-- szTitle      消息头部
-- tContentRgbF 主体消息文字颜色rgbf[可选，为空使用默认颜色字体。]
-- tTitleRgbF   消息头部文字颜色rgbf[可选，为空和主体消息文字颜色相同。]
function MY.Sysmsg(arg0, arg1, arg2)
	local szType, szMsg = arg2 or 'MSG_SYS', ''
	local r, g, b = GetMsgFontColor(szType)
	local f = GetMsgFont(szType)
	local ac, at, sc, st = {}, {}

	if IsTable(arg0) then
		for _, v in ipairs(arg0) do
			insert(ac, tostring(v))
		end
		ac.r, ac.g, ac.b, ac.f = arg0.r, arg0.g, arg0.b, arg0.f
	else
		insert(ac, tostring(arg0))
		ac.bNoWrap = true
	end
	if IsTable(arg1) then
		for _, v in ipairs(arg1) do
			insert(at, tostring(v))
		end
		at.r, at.g, at.b, at.f = arg1.r, arg1.g, arg1.b, arg1.f
	else
		insert(at, tostring(arg1 or MY.GetAddonInfo().szShortName))
	end

	sc = concat(ac, ac.bNoWrap and '' or '\n')
	if not ac.bNoWrap then
		sc = sc .. '\n'
	end
	szMsg = szMsg .. GetFormatText(sc, ac.f or f, ac.r or r, ac.g or g, ac.b or b)

	st = concat(at, '][')
	if st ~= '' then
		st = '[' .. st .. '] '
	end
	szMsg = GetFormatText(st, at.f or ac.f or f, at.r or ac.r or r, at.g or ac.g or g, at.b or ac.b or b) .. szMsg

	OutputMessage(szType, szMsg, true)
end

-- 没有头的中央信息 也可以用于系统信息
function MY.Topmsg(szText, szType)
	MY.Sysmsg(szText, {}, szType or 'MSG_ANNOUNCE_YELLOW')
end

-- 输出一条密聊信息
function MY.OutputWhisper(szMsg, szHead)
	szHead = szHead or MY.GetAddonInfo().szShortName
	OutputMessage('MSG_WHISPER', '[' .. szHead .. ']' .. g_tStrings.STR_TALK_HEAD_WHISPER .. szMsg .. '\n')
	PlaySound(SOUND.UI_SOUND, g_sound.Whisper)
end

-- Debug输出
-- (void)MY.Debug(oContent, szTitle, nLevel)
-- oContent Debug信息
-- szTitle  Debug头
-- nLevel   Debug级别[低于当前设置值将不会输出]
function MY.Debug(oContent, szTitle, nLevel)
	if type(nLevel)~='number'  then nLevel = MY_DEBUG.WARNING end
	if type(szTitle)~='string' then szTitle = 'MY DEBUG' end
	if type(oContent)~='table' then oContent = { oContent, bNoWrap = true } end
	if not oContent.r then
		if nLevel == 0 then
			oContent.r, oContent.g, oContent.b =   0, 255, 127
		elseif nLevel == 1 then
			oContent.r, oContent.g, oContent.b = 255, 170, 170
		elseif nLevel == 2 then
			oContent.r, oContent.g, oContent.b = 255,  86,  86
		else
			oContent.r, oContent.g, oContent.b = 255, 255, 0
		end
	end
	if nLevel >= MY.GetAddonInfo().nDebugLevel then
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szTitle .. ']' .. table.concat(oContent, '\n'))
		MY.Sysmsg(oContent, szTitle)
	elseif nLevel >= MY.GetAddonInfo().nLogLevel then
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szTitle .. ']' .. table.concat(oContent, '\n'))
	end
end

function MY.StartDebugMode()
	if JH then
		JH.bDebugClient = true
	end
	MY.Sys.IsShieldedVersion(false)
end

-- 格式化计时时间
-- (string) MY.FormatTimeCount(szFormat, nTime)
-- szFormat  格式化字符串 可选项H,M,S,hh,mm,ss,h,m,s
function MY.FormatTimeCount(szFormat, nTime)
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
-- (string) MY.FormatTimeCount(szFormat[, nTimestamp])
-- szFormat   格式化字符串 可选项yyyy,yy,MM,dd,y,m,d,hh,mm,ss,h,m,s
-- nTimestamp UNIX时间戳
function MY.FormatTime(szFormat, nTimestamp)
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

-- register global esc key down action
-- (void) MY.RegisterEsc(szID, fnCondition, fnAction, bTopmost) -- register global esc event handle
-- (void) MY.RegisterEsc(szID, nil, nil, bTopmost)              -- unregister global esc event handle
-- (string)szID        -- an UUID (if this UUID has been register before, the old will be recovered)
-- (function)fnCondition -- a function returns if fnAction will be execute
-- (function)fnAction    -- inf fnCondition() is true then fnAction will be called
-- (boolean)bTopmost    -- this param equals true will be called in high priority
function MY.RegisterEsc(szID, fnCondition, fnAction, bTopmost)
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
function MY.ProcessCommand(cmd)
	local ls = loadstring('return ' .. cmd)
	if ls then
		return ls()
	end
end
end

do
local bCustomMode = false
function MY.IsInCustomUIMode()
	return bCustomMode
end
RegisterEvent('ON_ENTER_CUSTOM_UI_MODE', function() bCustomMode = true  end)
RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE', function() bCustomMode = false end)
end

function MY.DoMessageBox(szName, i)
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

function MY.OutputBuffTip(dwID, nLevel, Rect, nTime)
	local t = {}

	insert(t, GetFormatText(Table_GetBuffName(dwID, nLevel) .. '\t', 65))
	local buffInfo = GetBuffInfo(dwID, nLevel, {})
	if buffInfo and buffInfo.nDetachType and g_tStrings.tBuffDetachType[buffInfo.nDetachType] then
		insert(t, GetFormatText(g_tStrings.tBuffDetachType[buffInfo.nDetachType] .. '\n', 106))
	else
		insert(t, XML_LINE_BREAKER)
	end

	local szDesc = GetBuffDesc(dwID, nLevel, 'desc')
	if szDesc then
		insert(t, GetFormatText(szDesc .. g_tStrings.STR_FULL_STOP, 106))
	end

	if nTime then
		if nTime == 0 then
			insert(t, XML_LINE_BREAKER)
			insert(t, GetFormatText(g_tStrings.STR_BUFF_H_TIME_ZERO, 102))
		else
			local H, M, S = '', '', ''
			local h = math.floor(nTime / 3600)
			local m = math.floor(nTime / 60) % 60
			local s = math.floor(nTime % 60)
			if h > 0 then
				H = h .. g_tStrings.STR_BUFF_H_TIME_H .. ' '
			end
			if h > 0 or m > 0 then
				M = m .. g_tStrings.STR_BUFF_H_TIME_M_SHORT .. ' '
			end
			S = s..g_tStrings.STR_BUFF_H_TIME_S
			if h < 720 then
				insert(t, XML_LINE_BREAKER)
				insert(t, GetFormatText(FormatString(g_tStrings.STR_BUFF_H_LEFT_TIME_MSG, H, M, S), 102))
			end
		end
	end

	-- For test
	if IsCtrlKeyDown() then
		insert(t, XML_LINE_BREAKER)
		insert(t, GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP, 102))
		insert(t, XML_LINE_BREAKER)
		insert(t, GetFormatText('ID:     ' .. dwID, 102))
		insert(t, XML_LINE_BREAKER)
		insert(t, GetFormatText('Level:  ' .. nLevel, 102))
		insert(t, XML_LINE_BREAKER)
		insert(t, GetFormatText('IconID: ' .. tostring(Table_GetBuffIconID(dwID, nLevel)), 102))
	end
	OutputTip(concat(t), 300, Rect)
end


function MY.Alert(szMsg, fnAction, szSure)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = 'MY_Alert', szAlignment = 'CENTER',
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		},
	}
	MessageBox(tMsg)
end

function MY.Confirm(szMsg, fnAction, fnCancel, szSure, szCancel)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = 'MY_Confirm', szAlignment = 'CENTER',
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

do
function MY.Hex2RGB(hex)
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

function MY.RGB2Hex(r, g, b, a)
	if a then
		return (('#%02X%02X%02X%02X'):format(r, g, b, a))
	end
	return (('#%02X%02X%02X'):format(r, g, b))
end

local COLOR_NAME_RGB = {}
do
	local tColor = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/colors.jx3dat')
	for id, col in pairs(tColor) do
		local r, g, b = MY.Hex2RGB(col)
		if r then
			if _L.COLOR_NAME[id] then
				COLOR_NAME_RGB[_L.COLOR_NAME[id]] = {r, g, b}
			end
			COLOR_NAME_RGB[id] = {r, g, b}
		end
	end
end

function MY.ColorName2RGB(name)
	if not COLOR_NAME_RGB[name] then
		return
	end
	return unpack(COLOR_NAME_RGB[name])
end

local HUMAN_COLOR_CACHE = setmetatable({}, {__mode = 'v', __index = COLOR_NAME_RGB})
function MY.HumanColor2RGB(name)
	if IsTable(name) then
		if name.r then
			return name.r, name.g, name.b
		end
		return unpack(name)
	end
	if not HUMAN_COLOR_CACHE[name] then
		local r, g, b, a = MY.Hex2RGB(name)
		HUMAN_COLOR_CACHE[name] = {r, g, b, a}
	end
	return unpack(HUMAN_COLOR_CACHE[name])
end
end

function MY.ExecuteWithThis(element, fnAction, ...)
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

function MY.InsertOperatorMenu(t, opt, action, opts, L)
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

function MY.JudgeOperator(opt, lval, rval, ...)
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


function MY.IsEmpty(var)
	local szType = type(var)
	if szType == 'nil' then
		return true
	elseif szType == 'boolean' then
		return var
	elseif szType == 'number' then
		return var == 0
	elseif szType == 'string' then
		return var == ''
	elseif szType == 'function' then
		return false
	elseif szType == 'table' then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end
