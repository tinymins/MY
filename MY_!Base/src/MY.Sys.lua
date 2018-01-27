--------------------------------------------
-- @Desc  : ������� - ϵͳ������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2014-12-17 17:24:48
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2017-02-08 17:56:29
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
local srep, tostring, string2byte = string.rep, tostring, string.byte
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local type, next, print, pairs, ipairs = type, next, print, pairs, ipairs
MY = MY or {}
MY.Sys = MY.Sys or {}
MY.Sys.bShieldedVersion = false -- ���α���з�Ĺ��ܣ��������ã�
local _L, _C = MY.LoadLangPack(), {}

-- ��ȡ��Ϸ����
function MY.GetLang()
	local _, _, lang = GetVersion()
	return lang
end

-- ��ȡ��������״̬
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
	CPath.Move(MY.GetAddonInfo().szRoot .. '@DATA/', MY.GetAddonInfo().szInterfaceRoot .. "MY#DATA/")
end
-- ��ʽ�������ļ�·�����滻$uid��$lang��$server�Լ���ȫ���·����
-- (string) MY.GetLUADataPath(oFilePath)
function MY.FormatPath(oFilePath, tParams)
	if not tParams then
		tParams = {}
	end
	local szFilePath, ePathType
	if type(oFilePath) == "table" then
		szFilePath, ePathType = unpack(oFilePath)
	else
		szFilePath, ePathType = oFilePath, MY_DATA_PATH.NORMAL
	end
	-- Unified the directory separator
	szFilePath = string.gsub(szFilePath, '\\', '/')
	-- if it's relative path then complete path with "/MY@DATA/"
	if szFilePath:sub(1, 2) ~= './' and szFilePath:sub(2, 3) ~= ':/' then
		if ePathType == MY_DATA_PATH.GLOBAL then
			szFilePath = "!all-users@$lang/" .. szFilePath
		elseif ePathType == MY_DATA_PATH.ROLE then
			szFilePath = "$uid@$lang/" .. szFilePath
		elseif ePathType == MY_DATA_PATH.SERVER then
			szFilePath = "#$relserver@$lang/" .. szFilePath
		end
		szFilePath = MY.GetAddonInfo().szInterfaceRoot .. "MY#DATA/" .. szFilePath
	end
	-- if exist $uid then add user role identity
	if string.find(szFilePath, "%$uid") then
		szFilePath = szFilePath:gsub("%$uid", tParams["uid"] or MY.GetClientUUID())
	end
	-- if exist $name then add user role identity
	if string.find(szFilePath, "%$name") then
		szFilePath = szFilePath:gsub("%$name", tParams["name"] or MY.GetClientInfo().szName or MY.GetClientUUID())
	end
	-- if exist $lang then add language identity
	if string.find(szFilePath, "%$lang") then
		szFilePath = szFilePath:gsub("%$lang", tParams["lang"] or string.lower(MY.GetLang()))
	end
	-- if exist $date then add date identity
	if string.find(szFilePath, "%$date") then
		szFilePath = szFilePath:gsub("%$date", tParams["date"] or MY.FormatTime("yyyyMMdd", GetCurrentTime()))
	end
	-- if exist $server then add server identity
	if string.find(szFilePath, "%$server") then
		szFilePath = szFilePath:gsub("%$server", tParams["server"] or ((MY.Game.GetServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- if exist $relserver then add relserver identity
	if string.find(szFilePath, "%$relserver") then
		szFilePath = szFilePath:gsub("%$relserver", tParams["relserver"] or ((MY.Game.GetRealServer()):gsub('[/\\|:%*%?"<>]', '')))
	end
	local rootPath = GetRootPath():gsub('\\', '/')
	if szFilePath:find(rootPath) == 1 then
		szFilePath = szFilePath:gsub(rootPath, '')
	end
	return szFilePath
end

function MY.GetLUADataPath(oFilePath)
	local szFilePath = MY.FormatPath(oFilePath)
	-- ensure has file name
	if string.sub(szFilePath, -1) == '/' then
		szFilePath = szFilePath .. "data"
	end
	return szFilePath
end

-- ���������ļ�
-- MY.SaveLUAData(oFilePath, tData, ePathType, indent, crc)
-- oFilePath           �����ļ�·��(1)
-- tData               Ҫ���������
-- indent              �����ļ�����
-- crc                 �Ƿ����CRCУ��ͷ��Ĭ��true��
-- nohashlevels        ��LIST�����ڲ㣨�Ż�����дЧ�ʣ�
-- (1)�� ��·��Ϊ����·��ʱ(��б�ܿ�ͷ)��������
--       ��·��Ϊ���·��ʱ ����ڲ��`MY@DATA`Ŀ¼
--       ���Դ����{szPath, ePathType}
function MY.SaveLUAData(oFilePath, tData, indent, crc, nohashlevels)
	local nStartTick = GetTickCount()
	-- format uri
	local szFilePath = MY.GetLUADataPath(oFilePath)
	-- save data
	local data = SaveLUAData(szFilePath, tData, indent, crc or false, nohashlevels)
	-- performance monitor
	MY.Debug({_L('%s saved during %dms.', szFilePath, GetTickCount() - nStartTick)}, 'PMTool', MY_DEBUG.PMLOG)
	return data
end

-- ���������ļ���
-- MY.LoadLUAData(oFilePath)
-- oFilePath           �����ļ�·��(1)
-- (1)�� ��·��Ϊ./��ͷʱ��������
--       ��·��Ϊ����ʱ ����ڲ��`MY@DATA`Ŀ¼
--       ���Դ����{szPath, ePathType}
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


-- ע���û��������ݣ�֧��ȫ�ֱ����������
-- (void) MY.RegisterCustomData(string szVarPath[, number nVersion])
function MY.RegisterCustomData(szVarPath, nVersion, szDomain)
	szDomain = szDomain or "Role"
	if _G and type(_G[szVarPath]) == "table" then
		for k, _ in pairs(_G[szVarPath]) do
			RegisterCustomData(szDomain .. "/" .. szVarPath .. "." .. k, nVersion)
		end
	else
		RegisterCustomData(szDomain .. "/" .. szVarPath, nVersion)
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
	-- ��׼������
	local params = setmetatable({}, defaultParams)
	local structTypes, defaultData, defaultDataType
	local keyTemplate, childTemplate, arrayTemplate, dictTemplate
	if type(struct) == 'table' and struct[1] == metaFlag then
		-- ������META��ǵ�������
		-- �������ͺ�Ĭ��ֵ
		structTypes = struct[2] or { type(struct.__VALUE__) }
		defaultData = struct[3] or struct.__VALUE__
		defaultDataType = type(defaultData)
		-- ��ģ����ز���
		if defaultDataType == 'table' then
			keyTemplate = struct.__KEY_TEMPLATE__
			childTemplate = struct.__CHILD_TEMPLATE__
			arrayTemplate = struct.__ARRAY_TEMPLATE__
			dictionaryTemplate = struct.__DICTIONARY_TEMPLATE__
		end
		-- ���Ӳ���
		if struct.__PARAMS__ then
			for k, v in pairs(struct.__PARAMS__) do
				params[k] = v
			end
		end
	else
		-- ������ͨ������
		structTypes = { type(struct) }
		defaultData = struct
		defaultDataType = type(defaultData)
	end
	-- ����ṹ�����ݵ�����
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
	-- �ֱ�������ƥ���벻ƥ������
	if dataTypeExists then
		if not assign then
			data = clone(data)
		end
		local keys = {}
		-- ���������Ǳ���META��Ϣ�ж�������Ԫ��KEYģ�� ��ݹ�����Ԫ��KEY����Ԫ��KEYģ��
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
		-- ���������Ǳ���META��Ϣ�ж�������Ԫ��ģ�� ��ݹ�����Ԫ������Ԫ��ģ��
		if dataType == 'table' and childTemplate then
			for i, v in pairs(data) do
				keys[i] = true
				data[i] = FormatDataStructure(data[i], childTemplate)
			end
		end
		-- ���������Ǳ���META��Ϣ�ж������б���Ԫ��ģ�� ��ݹ�����Ԫ�����б���Ԫ��ģ��
		if dataType == 'table' and arrayTemplate then
			for i, v in pairs(data) do
				if type(i) == 'number' then
					keys[i] = true
					data[i] = FormatDataStructure(data[i], arrayTemplate)
				end
			end
		end
		-- ���������Ǳ���META��Ϣ�ж����˹�ϣ��Ԫ��ģ�� ��ݹ�����Ԫ�����ϣ��Ԫ��ģ��
		if dataType == 'table' and dictionaryTemplate then
			for i, v in pairs(data) do
				if type(i) ~= 'number' then
					keys[i] = true
					data[i] = FormatDataStructure(data[i], dictionaryTemplate)
				end
			end
		end
		-- ���������Ǳ���Ĭ������Ҳ�Ǳ� ��ݹ�����Ԫ����Ĭ����Ԫ��
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
	else -- ���Ͳ�ƥ������
		if type(defaultData) == 'table' then
			-- Ĭ��ֵΪ�� ��Ҫ�ݹ�����Ԫ��
			data = {}
			for k, v in pairs(defaultData) do
				data[k] = FormatDataStructure(nil, v)
			end
		else -- Ĭ��ֵ���Ǳ� ֱ�ӿ�¡����
			data = clone(defaultData)
		end
	end
	return data
end
MY.FormatDataStructure = FormatDataStructure
end

function MY.SetGlobalValue(szVarPath, Val)
	local t = MY.String.Split(szVarPath, ".")
	local tab = _G
	for k, v in ipairs(t) do
		if type(tab[v]) == "nil" then
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
	for szIndex in string.gmatch(szVarPath, "[^%.]+") do
		if tVariable and type(tVariable) == "table" then
			tVariable = tVariable[szIndex]
		else
			tVariable = nil
			break
		end
	end
	return tVariable
end

function MY.CreateDataRoot(ePathType)
	-- ����Ŀ¼
	if ePathType == MY_DATA_PATH.ROLE then
		CPath.MakeDir(MY.FormatPath({'$name/', MY_DATA_PATH.ROLE}))
	end
	CPath.MakeDir(MY.FormatPath({'cache/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'config/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'export/', ePathType}))
	CPath.MakeDir(MY.FormatPath({'userdata/', ePathType}))
end

-- ��������
-- MY.PlaySound(szFilePath[, szCustomPath])
-- szFilePath   ��Ƶ�ļ���ַ
-- szCustomPath ���Ի���Ƶ�ļ���ַ
-- ע�����Ȳ���szCustomPath, szCustomPath�����ڲŻᲥ��szFilePath
function MY.PlaySound(szFilePath, szCustomPath)
	szCustomPath = szCustomPath or szFilePath
	-- ͳһ��Ŀ¼�ָ���
	szCustomPath = string.gsub(szCustomPath, '\\', '/')
	-- ��������·�����/@Custom/��ȫ
	if string.sub(szCustomPath, 1, 2) ~= './' then
		szCustomPath = MY.GetAddonInfo().szRoot .. "@Custom/" .. szCustomPath
	end
	if IsFileExist(szCustomPath) then
		PlaySound(SOUND.UI_SOUND, szCustomPath)
	else
		-- ͳһ��Ŀ¼�ָ���
		szFilePath = string.gsub(szFilePath, '\\', '/')
		-- ��������·�����/@Custom/��ȫ
		if string.sub(szFilePath, 1, 2) ~= './' then
			szFilePath = MY.GetAddonInfo().szFrameworkRoot .. "audio/" .. szFilePath
		end
		PlaySound(SOUND.UI_SOUND, szFilePath)
	end
end
-- ����ע������
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
-- (void) MY.RemoteRequest(string szUrl, func fnAction)       -- ����Զ�� HTTP ����
-- szUrl        -- ��������� URL������ http:// �� https://��
-- fnAction     -- ������ɺ�Ļص��������ص�ԭ�ͣ�function(szTitle, szContent)]]
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
local MY_AJAX_TAG = "MY_AJAX#"
local l_ajaxsettingsmeta = {
	__index = {
		type = 'get',
		driver = "curl",
		timeout = 60000,
		charset = "utf8",
	}
}

local function EncodePostData(data, t, prefix)
	if type(data) == "table" then
		local first = true
		for k, v in pairs(data) do
			if first then
				first = false
			else
				tinsert(t, "&")
			end
			if prefix == "" then
				EncodePostData(v, t, k)
			else
				EncodePostData(v, t, prefix .. "[" .. k .. "]")
			end
		end
	else
		if prefix ~= "" then
			tinsert(t, prefix)
			tinsert(t, "=")
		end
		tinsert(t, data)
	end
end

local function serialize(data)
	local t = {}
	EncodePostData(data, t, "")
	local text = tconcat(t)
	return text
end

function MY.Ajax(settings)
	assert(settings and settings.url)
	setmetatable(settings, l_ajaxsettingsmeta)

	local url, data = settings.url, settings.data
	if settings.charset == "utf8" then
		url  = MY.ConvertToUTF8(url)
		data = MY.ConvertToUTF8(data)
	end

	local ssl = url:sub(1, 6) == "https:"
	local method, payload = unpack(MY.Split(settings.type, '/'))
	if (method == "get" or method == "delete") and data then
		if not url:find("?") then
			url = url .. "?"
		elseif url:sub(-1) ~= "&" then
			url = url .. "&"
		end
		url, data = url .. serialize(data), nil
	end
	assert(method == "post" or method == "get" or method == "put" or method == "delete", "[MY_AJAX] Unknown http request type: " .. method)

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

	if settings.driver == "curl" then
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
	elseif settings.driver == "webbrowser" then
		assert(method == "get", "[MY_AJAX] Webbrowser only support get method, got " .. method)
		local RequestID, hFrame
		local nFreeWebPages = #_C.tFreeWebPages
		if nFreeWebPages > 0 then
			RequestID = _C.tFreeWebPages[nFreeWebPages]
			hFrame = Station.Lookup('Lowest/MYRR_' .. RequestID)
			table.remove(_C.tFreeWebPages)
		end
		-- create page
		if not hFrame then
			RequestID = ("%X_%X"):format(GetTickCount(), math.floor(math.random() * 65536))
			hFrame = Wnd.OpenWindow(MY.GetAddonInfo().szFrameworkRoot .. 'ui/WndWebPage.ini', "MYRR_" .. RequestID)
			hFrame:Hide()
		end
		local wWebPage = hFrame:Lookup('WndWebPage')

		-- bind callback function
		wWebPage.OnDocumentComplete = function()
			local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			if szUrl ~= szTitle or szContent ~= "" then
				MY.Debug({string.format("%s - %s", szTitle, szUrl)}, 'MYRR::OnDocumentComplete', MY_DEBUG.LOG)
				-- ע����ʱ����ʱ��
				MY.DelayCall("MYRR_TO_" .. RequestID, false)
				-- �ɹ��ص�����
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
			MY.DelayCall("MYRR_TO_" .. RequestID, settings.timeout, function()
				MY.Debug({settings.url}, 'MYRR::Timeout', MY_DEBUG.WARNING) -- log
				-- request timeout, call timeout function.
				if settings.error then
					local status, err = pcall_this(settings.context, settings.error, settings, "timeout")
					if not status then
						MY.Debug({err}, 'MYRR::TIMEOUT', MY_DEBUG.ERROR)
					end
				end
				table.insert(_C.tFreeWebPages, RequestID)
			end)
		end

		-- start ie navigate
		wWebPage:Navigate(url)
	else -- if settings.driver == "origin" then
		local szKey = GetTickCount() * 100
		while MY_CALL_AJAX[MY_AJAX_TAG .. szKey] do
			szKey = szKey + 1
		end
		szKey = MY_AJAX_TAG .. szKey
		if method == "post" then
			CURL_HttpPost(szKey, url, data, ssl, settings.timeout)
		else
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
				MY.Debug({"CURL # " .. settings.url .. ' - complete - PCALL ERROR - ' .. err}, MY_DEBUG.ERROR)
			end
		end
		if bSuccess then
			if settings.charset == "utf8" and html ~= nil and CLIENT_LANG == "zhcn" then
				html = UTF8ToAnsi(html)
			end
			-- if payload == "json" then
			-- 	html = MY.JsonDecode(html)
			-- end
			local status, err = pcall(settings.success, html, status)
			if not status then
				MY.Debug({"CURL # " .. settings.url .. ' - success - PCALL ERROR - ' .. err}, MY_DEBUG.ERROR)
			end
		else
			local status, err = pcall(settings.error, html, status, dwBufferSize ~= 0)
			if not status then
				MY.Debug({"CURL # " .. settings.url .. ' - error - PCALL ERROR - ' .. err}, MY_DEBUG.ERROR)
			end
		end
		MY_CALL_AJAX[szKey] = nil
	end
end
MY.RegisterEvent("CURL_REQUEST_RESULT.AJAX", OnCurlRequestResult)
end

do
-------------------------------
-- remote data storage online
-- bosslist (done)
-- focus list (working on)
-- chat blocklist (working on)
-------------------------------
-- �������ݰ汾��
local m_nStorageVer = {}
MY.BreatheCall("MYLIB#STORAGE_DATA", 200, function()
	if not MY.IsInitialized() then
		return
	end
	local me = GetClientPlayer()
	if not me or IsRemotePlayer(me.dwID) or not MY.GetTongName() then
		return
	end
	m_nStorageVer = MY.LoadLUAData({'config/storageversion.jx3dat', MY_DATA_PATH.ROLE}) or {}
	MY.Ajax({
		type = "post/json",
		url = 'http://data.jx3.derzh.com/api/storage',
		data = {
			data = MY.SimpleEcrypt(MY.ConvertToUTF8(MY.JsonEncode({
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
						FireUIEvent("MY_PUBLIC_STORAGE_UPDATE", k, oData)
					end
				end
				for k, v in pairs(data.private or EMPTY_TABLE) do
					if not m_nStorageVer[k] or m_nStorageVer[k] < v.v then
						local oData = str2var(v.o)
						if oData ~= nil then
							FireUIEvent("MY_PRIVATE_STORAGE_UPDATE", k, oData)
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
MY.RegisterExit("MYLIB#STORAGE_DATA", function()
	MY.SaveLUAData({'config/storageversion.jx3dat', MY_DATA_PATH.ROLE}, m_nStorageVer)
end)
-- ����������� �������ɵ��͹�˾���������л�
function MY.StorageData(szKey, oData)
	MY.DelayCall("STORAGE_" .. szKey, 120000, function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		MY.Ajax({
			type = 'post/json',
			url = 'http://data.jx3.derzh.com/api/storage',
			data = {
				data =  MY.String.SimpleEcrypt(MY.Json.Encode({
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
					FireUIEvent("MY_PRIVATE_STORAGE_SYNC", szKey)
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
	local nPos = StringFindW(szKey, ".")
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
	local nPos = StringFindW(szKey, ".")
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
			MY.Debug({err}, "STORAGE_INIT_FUNC_LIST#" .. szKey)
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
_C.tPlayerMenu = {}   -- ���ͷ��˵�
_C.tTargetMenu = {}   -- Ŀ��ͷ��˵�
_C.tTraceMenu  = {}   -- �������˵�

-- get plugin folder menu
function _C.GetMainMenu()
	return {
		szOption = _L["mingyi plugins"],
		fnAction = MY.TogglePanel,
		bCheck = true,
		bChecked = MY.IsPanelVisible(),

		szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
		nFrame = 105, nMouseOverFrame = 106,
		szLayer = "ICON_RIGHT",
		fnClickIcon = MY.TogglePanel
	}
end
-- get target addon menu
function _C.GetTargetAddonMenu()
	local menu = {}
	for i = 1, #_C.tTargetMenu, 1 do
		local m = _C.tTargetMenu[i].Menu
		if type(m) == "function" then m = m() end
		if not m or m.szOption then m = {m} end
		for _, v in ipairs(m) do
			table.insert(menu, v)
		end
	end
	table.sort(menu, function(m1, m2)
		return #m1 < #m2
	end)
	return menu
end
-- get player addon menu
function _C.GetPlayerAddonMenu()
	-- �����˵�
	local menu = _C.GetMainMenu()
	for i = 1, #_C.tPlayerMenu, 1 do
		local m = _C.tPlayerMenu[i].Menu
		if type(m) == "function" then m = m() end
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
		if type(m) == "function" then m = m() end
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

-- ע��Ŀ��ͷ��˵�
-- ע��
-- (void) MY.RegisterTargetAddonMenu(szName,Menu)
-- (void) MY.RegisterTargetAddonMenu(Menu)
-- ע��
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

-- ע�����ͷ��˵�
-- ע��
-- (void) MY.RegisterPlayerAddonMenu(szName,Menu)
-- (void) MY.RegisterPlayerAddonMenu(Menu)
-- ע��
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

-- ע�Ṥ�����˵�
-- ע��
-- (void) MY.RegisterTraceButtonAddonMenu(szName,Menu)
-- (void) MY.RegisterTraceButtonAddonMenu(Menu)
-- ע��
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

-- ע�����ͷ��͹������˵�
-- ע��
-- (void) MY.RegisterAddonMenu(szName,Menu)
-- (void) MY.RegisterAddonMenu(Menu)
-- ע��
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
-- ��ʾ������Ϣ
-- MY.Sysmsg(oContent, oTitle)
-- szContent    Ҫ��ʾ��������Ϣ
-- szTitle      ��Ϣͷ��
-- tContentRgbF ������Ϣ������ɫrgbf[��ѡ��Ϊ��ʹ��Ĭ����ɫ���塣]
-- tTitleRgbF   ��Ϣͷ��������ɫrgbf[��ѡ��Ϊ�պ�������Ϣ������ɫ��ͬ��]
function MY.Sysmsg(oContent, oTitle, szType)
	oTitle = oTitle or MY.GetAddonInfo().szShortName
	if type(oTitle)~='table' then oTitle = { oTitle, bNoWrap = true } end
	if type(oContent)~='table' then oContent = { oContent, bNoWrap = true } end
	oContent.r, oContent.g, oContent.b, oContent.f = oContent.r or 255, oContent.g or 255, oContent.b or 0, oContent.f or 10

	for i = #oContent, 1, -1 do
		if type(oContent[i])=="number"  then oContent[i] = '' .. oContent[i] end
		if type(oContent[i])=="boolean" then oContent[i] = (oContent[i] and 'true') or 'false' end
		-- auto wrap each line
		if (not oContent.bNoWrap) and type(oContent[i])=="string" and string.sub(oContent[i], -1)~='\n' then
			oContent[i] = oContent[i] .. '\n'
		end
	end

	-- calc szMsg
	local szMsg = ''
	for i = 1, #oTitle, 1 do
		if oTitle[i]~='' then
			szMsg = szMsg .. '['..oTitle[i]..']'
		end
	end
	if #szMsg > 0 then
		szMsg = GetFormatText( szMsg..' ', oTitle.f or oContent.f, oTitle.r or oContent.r, oTitle.g or oContent.g, oTitle.b or oContent.b )
	end
	for i = 1, #oContent, 1 do
		szMsg = szMsg .. GetFormatText(oContent[i], oContent.f, oContent.r, oContent.g, oContent.b)
	end
	-- Output
	OutputMessage(szType or "MSG_SYS", szMsg, true)
end

-- û��ͷ��������Ϣ Ҳ��������ϵͳ��Ϣ
function MY.Topmsg(szText, szType)
	MY.Sysmsg(szText, {}, szType or "MSG_ANNOUNCE_YELLOW")
end

-- ���һ��������Ϣ
function MY.OutputWhisper(szMsg, szHead)
	szHead = szHead or MY.GetAddonInfo().szShortName
	OutputMessage("MSG_WHISPER", "[" .. szHead .. "]" .. g_tStrings.STR_TALK_HEAD_WHISPER .. szMsg .. "\n")
	PlaySound(SOUND.UI_SOUND, g_sound.Whisper)
end

-- Debug���
-- (void)MY.Debug(oContent, szTitle, nLevel)
-- oContent Debug��Ϣ
-- szTitle  Debugͷ
-- nLevel   Debug����[���ڵ�ǰ����ֵ���������]
function MY.Debug(oContent, szTitle, nLevel)
	if type(nLevel)~="number"  then nLevel = MY_DEBUG.WARNING end
	if type(szTitle)~="string" then szTitle = 'MY DEBUG' end
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
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szTitle .. ']' .. table.concat(oContent, "\n"))
		MY.Sysmsg(oContent, szTitle)
	elseif nLevel >= MY.GetAddonInfo().nLogLevel then
		Log('[MY_DEBUG][LEVEL_' .. nLevel .. ']' .. '[' .. szTitle .. ']' .. table.concat(oContent, "\n"))
	end
end

function MY.StartDebugMode()
	if JH then
		JH.bDebugClient = true
	end
	MY.Sys.IsShieldedVersion(false)
end

-- ��ʽ����ʱʱ��
-- (string) MY.FormatTimeCount(szFormat, nTime)
-- szFormat  ��ʽ���ַ��� ��ѡ��H,M,S,hh,mm,ss,h,m,s
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

-- ��ʽ��ʱ��
-- (string) MY.FormatTimeCount(szFormat[, nTimestamp])
-- szFormat   ��ʽ���ַ��� ��ѡ��yyyy,yy,MM,dd,y,m,d,hh,mm,ss,h,m,s
-- nTimestamp UNIXʱ���
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

-- ������
if loadstring then
function MY.ProcessCommand(cmd)
	local ls = loadstring("return " .. cmd)
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
RegisterEvent("ON_ENTER_CUSTOM_UI_MODE", function() bCustomMode = true  end)
RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE", function() bCustomMode = false end)
end

function MY.DoMessageBox(szName, i)
	local frame = Station.Lookup("Topmost2/MB_" .. szName) or Station.Lookup("Topmost/MB_" .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup("Wnd_All/Btn_Option" .. i)
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

	tinsert(t, GetFormatText(Table_GetBuffName(dwID, nLevel) .. "\t", 65))
	local buffInfo = GetBuffInfo(dwID, nLevel, {})
	if buffInfo and buffInfo.nDetachType and g_tStrings.tBuffDetachType[buffInfo.nDetachType] then
		tinsert(t, GetFormatText(g_tStrings.tBuffDetachType[buffInfo.nDetachType] .. '\n', 106))
	else
		tinsert(t, XML_LINE_BREAKER)
	end

	local szDesc = GetBuffDesc(dwID, nLevel, "desc")
	if szDesc then
		tinsert(t, GetFormatText(szDesc .. g_tStrings.STR_FULL_STOP, 106))
	end

	if nTime then
		if nTime == 0 then
			tinsert(t, XML_LINE_BREAKER)
			tinsert(t, GetFormatText(g_tStrings.STR_BUFF_H_TIME_ZERO, 102))
		else
			local H, M, S = "", "", ""
			local h = math.floor(nTime / 3600)
			local m = math.floor(nTime / 60) % 60
			local s = math.floor(nTime % 60)
			if h > 0 then
				H = h .. g_tStrings.STR_BUFF_H_TIME_H .. " "
			end
			if h > 0 or m > 0 then
				M = m .. g_tStrings.STR_BUFF_H_TIME_M_SHORT .. " "
			end
			S = s..g_tStrings.STR_BUFF_H_TIME_S
			if h < 720 then
				tinsert(t, XML_LINE_BREAKER)
				tinsert(t, GetFormatText(FormatString(g_tStrings.STR_BUFF_H_LEFT_TIME_MSG, H, M, S), 102))
			end
		end
	end

	-- For test
	if IsCtrlKeyDown() then
		tinsert(t, XML_LINE_BREAKER)
		tinsert(t, GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP, 102))
		tinsert(t, XML_LINE_BREAKER)
		tinsert(t, GetFormatText("ID:     " .. dwID, 102))
		tinsert(t, XML_LINE_BREAKER)
		tinsert(t, GetFormatText("Level:  " .. nLevel, 102))
		tinsert(t, XML_LINE_BREAKER)
		tinsert(t, GetFormatText("IconID: " .. tostring(Table_GetBuffIconID(dwID, nLevel)), 102))
	end
	OutputTip(tconcat(t), 300, Rect)
end


function MY.Alert(szMsg, fnAction, szSure)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = "MY_Alert", szAlignment = "CENTER",
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
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = "MY_Confirm", szAlignment = "CENTER",
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
	local s, r, g, b, a = (hex:gsub("#", ""))
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
		a = tonumber("0x" .. a)
	end
	r, g, b = tonumber("0x" .. r), tonumber("0x" .. g), tonumber("0x" .. b)

	if not r or not g or not b then
		return
	end
	return r, g, b, a
end

function MY.RGB2Hex(r, g, b, a)
	if a then
		return (("#%02X%02X%02X%02X"):format(r, g, b, a))
	end
	return (("#%02X%02X%02X"):format(r, g, b))
end

local COLOR_NAME_RGB = {}
do
	local tColor = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. "data/colors.jx3dat")
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

local HUMAN_COLOR_CACHE = setmetatable({}, {__mode = "v", __index = COLOR_NAME_RGB})
function MY.HumanColor2RGB(name)
	if not HUMAN_COLOR_CACHE[name] then
		local r, g, b, a = MY.Hex2RGB(name)
		HUMAN_COLOR_CACHE[name] = {r, g, b, a}
	end
	return unpack(HUMAN_COLOR_CACHE[name])
end
end

function MY.ExecuteWithThis(element, fnAction, ...)
	if not (element and element:IsValid()) then
		-- Log("[UI ERROR]Invalid element on executing ui event!")
		return false
	end
	if type(fnAction) == "string" then
		if element[fnAction] then
			fnAction = element[fnAction]
		else
			local szFrame = element:GetRoot():GetName()
			if type(_G[szFrame]) == "table" then
				fnAction = _G[szFrame][fnAction]
			end
		end
	end
	if type(fnAction) ~= "function" then
		-- Log("[UI ERROR]Invalid function on executing ui event! # " .. element:GetTreePath())
		return false
	end
	local _this = this
	this = element
	local rets = {fnAction(...)}
	this = _this
	return true, unpack(rets)
end
