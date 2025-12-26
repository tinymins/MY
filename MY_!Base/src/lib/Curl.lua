--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 网络请求支持库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Curl')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

-- (void) X.RemoteRequest(string szUrl, func fnAction)       -- 发起远程 HTTP 请求
-- szUrl        -- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction     -- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
function X.RemoteRequest(szUrl, fnSuccess, fnError, nTimeout)
	local settings = {
		url     = szUrl,
		success = fnSuccess,
		error   = fnError,
		timeout = nTimeout,
	}
	return X.Ajax(settings)
end

do
local RRWP_FREE = {}
local RRWC_FREE = {}
local CALL_AJAX = {}
local AJAX_TAG = X.NSFormatString('{$NS}_AJAX#')
local AJAX_BRIDGE_WAIT = 10000
local AJAX_BRIDGE_PATH = X.PACKET_INFO.DATA_ROOT .. '#cache/curl/'

local function CreateWebPageFrame()
	local szRequestID, hFrame
	repeat
		szRequestID = ('%X%X'):format(GetTickCount(), X.Random(0x1000, 0xEFFF))
	until not Station.Lookup(X.NSFormatString('Lowest/{$NS}RRWP_') .. szRequestID)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage('CreateWebPageFrame: ' .. szRequestID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	hFrame = X.UI.OpenFrame(X.PACKET_INFO.UI_COMPONENT_ROOT .. 'WndWebPage.ini', X.NSFormatString('{$NS}RRWP_') .. szRequestID)
	hFrame:Hide()
	return szRequestID, hFrame
end

local Curl_Create = pcall(_G.Curl_Create, 'http://127.0.0.1/') and _G.Curl_Create or nil
local CURL_HttpRqst = pcall(_G.CURL_HttpRqst, 'http://127.0.0.1/') and _G.CURL_HttpRqst or nil
local CURL_HttpPost = (pcall(_G.CURL_HttpPostEx, 'TEST', 'http://127.0.0.1/') and _G.CURL_HttpPostEx)
	or (pcall(_G.CURL_HttpPost, 'TEST', 'http://127.0.0.1/') and _G.CURL_HttpPost)
	or nil

function X.CanAjax(driver, method)
	if driver == 'curl' then
		if not Curl_Create then
			return false, 'Curl_Create does not exist.'
		end
	elseif driver == 'webcef' then
		if method ~= 'get' then
			return false, 'Webcef only support get method, got ' .. method .. '.'
		end
	elseif driver == 'webbrowser' then
		if method ~= 'get' then
			return false, 'Webbrowser only support get method, got ' .. method .. '.'
		end
	else -- if driver == 'origin' then
		if method == 'post' then
			if not CURL_HttpPost then
				return false, 'CURL_HttpPost does not exist.'
			end
		else
			if not CURL_HttpRqst then
				return false, 'CURL_HttpRqst does not exist.'
			end
		end
	end
	return true
end

-- (void) X.Ajax(settings)       -- 发起远程 HTTP 请求
-- settings           -- 请求配置项
-- settings.url       -- 请求地址
-- settings.data      -- 请求数据
-- settings.method    -- 请求方式
-- settings.payload   -- 请求实体类型
-- settings.driver    -- 请求驱动方式
-- settings.timeout   -- 请求超时时间
-- settings.charset   -- 请求编码方式
-- settings.complete  -- 请求完成回调事件，无论成功失败，回调链： complete -> fulfilled -> success
-- settings.fulfilled -- 请求成功回调事件，不关心数据，回调链： complete -> fulfilled -> success
-- settings.success   -- 请求成功回调事件，携带数据，回调链： complete -> fulfilled -> success
-- settings.error     -- 请求失败回调事件，可能携带数据，回调链： complete -> error
function X.Ajax(settings)
	if not X.IsTable(settings) or not X.IsString(settings.url) then
		assert(false, X.NSFormatString('{$NS}.Ajax: Invalid settings.'))
	end
	-- standardize settings
	local id = string.lower(X.GetUUID())
	local oncomplete, onerror = settings.complete, settings.error
	local onfulfilled, onsuccess = settings.fulfilled, settings.success
	local config = {
		id        = id,
		url       = settings.url,
		data      = X.IIf(X.IsEmpty(settings.data), nil, settings.data),
		driver    = settings.driver  or 'auto',
		method    = settings.method  or 'auto',
		payload   = settings.payload or 'form',
		signature = X.KGUIEncrypt(settings.signature),
		timeout   = settings.timeout or 60000 ,
		charset   = settings.charset or 'utf8',
	}
	local settings = {
		config = setmetatable({}, {
			__index = function(_, k)
				return config[k]
			end,
			__newindex = function(_, k, v) end,
			__metatable = true,
		}),
	}

	-------------------------------
	-- convert encoding
	-------------------------------
	local xurl, xdata = config.url, config.data
	if config.charset == 'utf8' then
		xurl  = X.ConvertToUTF8(xurl)
		xdata = X.ConvertToUTF8(xdata)
	end

	-------------------------------
	-- auto settings
	-------------------------------
	-- select auto method
	local method = config.method
	if method == 'auto' then
		if Curl_Create then
			method = 'get'
		elseif CURL_HttpRqst then
			method = 'get'
		elseif CURL_HttpPost then
			method = 'post'
		else
			method = 'get'
		end
	end
	-- select auto driver
	local driver = config.driver
	if driver == 'auto' then
		if Curl_Create then
			driver = 'curl'
		elseif CURL_HttpRqst and method == 'get' then
			driver = 'origin'
		elseif CURL_HttpPost and method == 'post' then
			driver = 'origin'
		elseif onsuccess then
			driver = 'webbrowser'
		else
			driver = 'webcef'
		end
	end
	if (method == 'get' or method == 'delete') and xdata then
		local data = X.EncodeQuerystring(xdata)
		if data ~= '' then
			if not X.StringFindW(xurl, '?') then
				xurl = xurl .. '?'
			elseif X.StringSubW(xurl, -1) ~= '&' then
				xurl = xurl .. '&'
			end
			xurl = xurl .. data
		end
		xdata = nil
	end
	if method ~= 'post' and method ~= 'get' and method ~= 'put' and method ~= 'delete' then
		assert(false, X.NSFormatString('[{$NS}_AJAX] Unknown http request type: ') .. method)
	end

	-------------------------------
	-- data signature
	-------------------------------
	if config.signature then
		local pos = X.StringFindW(xurl, '?')
		if pos then
			xurl = string.sub(xurl, 1, pos)
				.. X.EncodeQuerystring(
					X.SignPostData(
						X.DecodeQuerystring(string.sub(xurl, pos + 1)),
						config.signature
					)
				)
		end
		if not X.IsEmpty(xdata) then
			if X.IsString(xdata) then
				xdata = X.DecodeQuerystring(xdata)
			end
			xdata = X.SignPostData(xdata, config.signature)
		end
	end

	-------------------------------
	-- correct ansi url and data
	-------------------------------
	if config.charset == 'utf8' then
		config.url  = X.ConvertToANSI(xurl)
		config.data = X.ConvertToANSI(xdata)
	end

	-------------------------------
	-- finalize settings
	-------------------------------
	-- log
	X.Log(
		'AJAX',
		xurl .. ' - ' .. config.driver .. '/' .. config.method
			.. ' (' .. driver .. '/' .. method .. ')'
			.. (xdata and (' [BODY]' .. X.EncodeQuerystring(xdata) .. '[/BODY]') or '')
	)
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage(
		'AJAX',
		xurl .. ' - ' .. config.driver .. '/' .. config.method
			.. ' (' .. driver .. '/' .. method .. ')'
			.. ': PREPARE READY'
			.. (xdata and ('\n[BODY]' .. X.EncodeQuerystring(xdata) .. '[/BODY]') or ''),
		X.DEBUG_LEVEL.LOG
	)
	--[[#DEBUG END]]
	local bridgewait = GetTime() + AJAX_BRIDGE_WAIT
	local bridgewaitkey = X.NSFormatString('{$NS}_AJAX_') .. id
	local fulfilled = false
	settings.callback = function(html, status)
		if fulfilled then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(
				'AJAX_DUP_CB',
				config.url .. ' - ' .. config.driver .. '/' .. config.method
					.. ' (' .. driver .. '/' .. method .. ')'
					.. ': ' .. (status or '')
					.. '\n' .. debug.traceback(),
				X.DEBUG_LEVEL.WARNING
			)
			--[[#DEBUG END]]
			return
		end
		local connected = html and status
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(
			'AJAX',
			config.url .. ' - ' .. config.driver .. '/' .. config.method
				.. ' (' .. driver .. '/' .. method .. ')'
				.. ': ' .. (status or 'FAILED'),
			X.IIf(connected, X.DEBUG_LEVEL.LOG, X.DEBUG_LEVEL.WARNING)
		)
		--[[#DEBUG END]]
		local function resolve()
			fulfilled = true
			X.SafeCallWithThis(settings.config, oncomplete, html, status, not X.IsEmpty(status))
			if X.IsNumber(status) and status >= 200 and status < 400 then
				X.SafeCallWithThis(settings.config, onfulfilled)
				X.SafeCallWithThis(settings.config, onsuccess, html, status)
			else
				X.SafeCallWithThis(settings.config, onerror, html, status)
			end
			X.XpCall(settings.closebridge)
		end
		if connected then
			resolve()
		else
			X.DelayCall(bridgewaitkey, bridgewait - GetTime(), resolve)
		end
	end

	-------------------------------
	-- each driver handlers
	-------------------------------
	-- bridge
	local bridgekey = X.NSFormatString('{$NS}RRDF_TO_') .. id
	local bridgein = AJAX_BRIDGE_PATH .. id .. '.' .. X.ENVIRONMENT.GAME_LANG .. '.jx3dat'
	local bridgeout = AJAX_BRIDGE_PATH .. id .. '.result.' .. X.ENVIRONMENT.GAME_LANG .. '.jx3dat'
	local bridgetimeout = GetTime() + config.timeout
	settings.closebridge = function()
		CPath.DelFile(bridgein)
		CPath.DelFile(bridgeout)
		X.DelayCall(bridgewaitkey, false)
		X.BreatheCall(bridgekey, false)
		X.DelayCall(bridgekey, false)
		X.RegisterExit(bridgekey, false)
	end
	X.SaveLUAData(bridgein, config, { encoder = 'luatext', passphrase = false })
	X.BreatheCall(bridgekey, 200, function()
		local data = X.LoadLUAData(bridgeout, { passphrase = false })
		if X.IsTable(data) then
			settings.callback(data.content, data.status)
		elseif GetTime() > bridgetimeout then
			settings.callback()
		end
	end)
	X.DelayCall(bridgekey, config.timeout, settings.closebridge)
	X.RegisterExit(bridgekey, settings.closebridge)

	local canajax, errmsg = X.CanAjax(driver, method)
	if not canajax then
		X.OutputDebugMessage(X.NSFormatString('{$NS}_AJAX'), errmsg, X.DEBUG_LEVEL.WARNING)
		settings.callback()
		return
	end

	if driver == 'curl' then
		local curl = Curl_Create(xurl)
		if method == 'post' then
			curl:SetMethod('POST')
			local data = xdata
			if config.payload == 'json' then
				data = X.EncodeJSON(data)
				curl:AddHeader('Content-Type: application/json')
			else -- if config.payload == 'form' then
				data = X.EncodeQuerystring(data)
				curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
			end
			curl:AddPostRawData(data)
		elseif method == 'get' then
			curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
		end
		-- curl:OnComplete(function(html, code, success)
		-- 	if config.charset == 'utf8' then
		-- 		html = UTF8ToAnsi(html)
		-- 	end
		-- 	settings.callback(html, code)
		-- end)
		curl:OnSuccess(function(html, code)
			if config.charset == 'utf8' then
				html = UTF8ToAnsi(html)
			end
			settings.callback(html, code)
		end)
		curl:OnError(function(html, code, connected)
			if connected then
				if config.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
			else
				html, code = nil, nil
			end
			settings.callback(html, code)
		end)
		curl:SetConnTimeout(config.timeout)
		curl:Perform()
	elseif driver == 'webcef' then
		local RequestID, hFrame
		local nFreeWebPages = #RRWC_FREE
		if nFreeWebPages > 0 then
			RequestID = RRWC_FREE[nFreeWebPages]
			hFrame = Station.Lookup(X.NSFormatString('Lowest/{$NS}RRWC_') .. RequestID)
			table.remove(RRWC_FREE)
		end
		-- create page
		if not hFrame then
			RequestID = ('%X_%X'):format(GetTickCount(), X.Random(0x1000, 0xEFFF))
			hFrame = X.UI.OpenFrame(X.PACKET_INFO.UI_COMPONENT_ROOT .. 'WndWebCef.ini', X.NSFormatString('{$NS}RRWC_') .. RequestID)
			hFrame:Hide()
		end
		local wWebCef = hFrame:Lookup('WndWebCef')

		-- bind callback function
		wWebCef.OnWebLoadEnd = function()
			-- local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			local szContent = ''
			--[[#DEBUG BEGIN]]
			-- X.OutputDebugMessage(X.NSFormatString('{$NS}RRWC::OnDocumentComplete'), string.format('%s - %s', szTitle, szUrl), X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- 注销超时处理时钟
			X.DelayCall(X.NSFormatString('{$NS}RRWC_TO_') .. RequestID, false)
			-- 回调函数
			settings.callback(szContent, 200)
			-- 有宕机问题，禁用 FREE 池，直接销毁句柄
			-- table.insert(RRWC_FREE, RequestID)
			X.UI.CloseFrame(this:GetRoot())
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.NSFormatString('{$NS}RRWC'), config.url, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if config.timeout > 0 then
			X.DelayCall(X.NSFormatString('{$NS}RRWC_TO_') .. RequestID, config.timeout, function()
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage(X.NSFormatString('{$NS}RRWC::Timeout'), config.url, X.DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				settings.callback()
				-- 有宕机问题，禁用 FREE 池，直接销毁句柄
				-- table.insert(RRWC_FREE, RequestID)
				X.UI.CloseFrame(hFrame)
			end)
		end

		-- start chrome navigate
		wWebCef:Navigate(xurl)
	elseif driver == 'webbrowser' then
		local RequestID, hFrame
		local function OnWebPageFrameCreate()
			local wWebPage = hFrame:Lookup('WndWebPage')
			-- bind callback function
			wWebPage.OnDocumentComplete = function()
				local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
				if szUrl ~= szTitle or szContent ~= '' then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(X.NSFormatString('{$NS}RRWP::OnDocumentComplete'), string.format('%s - %s', szTitle, szUrl), X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					-- 注销超时处理时钟
					X.DelayCall(X.NSFormatString('{$NS}RRWP_TO_') .. RequestID, false)
					-- 回调函数
					settings.callback(szContent, 200)
					-- 有宕机问题，禁用 FREE 池，直接销毁句柄
					table.insert(RRWP_FREE, RequestID)
					-- X.UI.CloseFrame(this:GetRoot())
				end
			end
			-- do with this remote request
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(X.NSFormatString('{$NS}RRWP'), config.url, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- register request timeout clock
			if config.timeout > 0 then
				X.DelayCall(X.NSFormatString('{$NS}RRWP_TO_') .. RequestID, config.timeout, function()
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage(X.NSFormatString('{$NS}RRWP::Timeout'), config.url, X.DEBUG_LEVEL.WARNING) -- log
					--[[#DEBUG END]]
					settings.callback()
					-- 有宕机问题，禁用 FREE 池，直接销毁句柄
					table.insert(RRWP_FREE, RequestID)
					-- X.UI.CloseFrame(hFrame)
				end)
			end
			-- start ie navigate
			wWebPage:Navigate(xurl)
		end
		local nFreeWebPages = #RRWP_FREE
		if nFreeWebPages > 0 then
			RequestID = RRWP_FREE[nFreeWebPages]
			hFrame = Station.Lookup(X.NSFormatString('Lowest/{$NS}RRWP_') .. RequestID)
			table.remove(RRWP_FREE)
		end
		-- create page
		if hFrame then
			OnWebPageFrameCreate()
		else
			local szKey = X.NSFormatString('{$NS}_AJAX#RRWP#') .. config.id
			X.BreatheCall(szKey, function()
				if X.IsFighting() or not Cursor.IsVisible() then
					return
				end
				X.BreatheCall(szKey, false)
				RequestID, hFrame = CreateWebPageFrame()
				OnWebPageFrameCreate()
			end)
		end
	else -- if driver == 'origin' then
		local szKey = GetTickCount() * 100
		while CALL_AJAX[AJAX_TAG .. szKey] do
			szKey = szKey + 1
		end
		szKey = AJAX_TAG .. szKey
		local ssl = xurl:sub(1, 6) == 'https:'
		if method == 'post' then
			local data = xdata
			if X.IsTable(xdata) then
				data = {}
				for _, kvp in ipairs(X.SplitString(X.EncodeQuerystring(xdata), '&', true)) do
					kvp = X.SplitString(kvp, '=')
					local k, v = kvp[1], kvp[2]
					data[X.DecodeURIComponent(k)] = X.DecodeURIComponent(v)
				end
			end
			CURL_HttpPost(szKey, xurl, data or '', ssl, config.timeout)
		else
			CURL_HttpRqst(szKey, xurl, ssl, config.timeout)
		end
		local info = {
			settings = settings,
			keys = { szKey, '__addon_' .. szKey },
		}
		for _, k in ipairs(info.keys) do
			CALL_AJAX[k] = info
		end
	end
end

local function OnCurlRequestResult()
	local szKey        = arg0
	local bSuccess     = arg1
	local html         = arg2
	local dwBufferSize = arg3
	local info = CALL_AJAX[szKey]
	if not info then
		return
	end
	local settings = info.settings
	if dwBufferSize == 0 then
		settings.callback()
	else
		local status = bSuccess and 200 or 500
		if settings.config.charset == 'utf8' then
			html = UTF8ToAnsi(html)
		end
		settings.callback(html, status)
	end
	for _, k in ipairs(info.keys) do
		CALL_AJAX[k] = nil
	end
end
X.RegisterEvent('CURL_REQUEST_RESULT', 'AJAX', OnCurlRequestResult)
end

do
local PENDING = {}
local Downloader = X.Class(X.NSFormatString('{$NS}Curl_FileDownloader'), {
	constructor = function(self, promiseFunction, info)
		self.info = info
		self:super(promiseFunction)
	end,
	Progress = function(self, handler)
		if X.IsFunction(handler) then
			table.insert(self.info.progressHandlers, handler)
		end
		return self
	end,
}, X.Promise)
function X.DownloadFile(szURL, szPath)
	local szKey = X.NSFormatString('{$NS}#DownloadFile.') .. GetStringCRC(szURL) .. GetStringCRC(szPath)
	local info = PENDING[szKey]
	if not info then
		info = {
			keys = { szKey, '__addon_' .. szKey },
			progressHandlers = {},
		}
		for _, k in ipairs(info.keys) do
			PENDING[k] = info
		end
		info.promise = X.Promise:new(function(resolve, reject)
			if CURL_DownloadFile then
				info.resolve = resolve
				info.reject = reject
				CURL_DownloadFile(szKey, szURL, szPath, szURL:lower():find('^https://') and true or false, 5)
			else
				for _, k in ipairs(info.keys) do
					PENDING[k] = nil
				end
				reject(X.Error:new('Global function CURL_DownloadFile not exists!'))
			end
		end)
	end
	return Downloader:new(function(resolve, reject)
		info.promise
			:Then(function(res)
				X.Call(resolve, res)
				return X.Promise.Resolve(res)
			end)
			:Catch(function(error)
				X.Call(reject, error)
				return X.Promise.Reject(error)
			end)
	end, info)
end

RegisterEvent('CURL_PROGRESS_UPDATE', function()
	local szKey, nTotal, nAlready = arg0, arg1, arg2
	local info = PENDING[szKey]
	if not info then
		return
	end
	for _, f in ipairs(info.progressHandlers) do
		X.Call(f, nTotal, nAlready)
	end
end)

RegisterEvent('CURL_DOWNLOAD_RESULT', function()
	local szKey, bSuccess = arg0, arg1
	local info = PENDING[szKey]
	if not info then
		return
	end
	for _, k in ipairs(info.keys) do
		PENDING[k] = nil
	end
	if bSuccess then
		info.resolve()
	else
		info.reject(X.Error:new('CURL_DOWNLOAD_RESULT failed!'))
	end
end)
end

function X.FetchLUAFile(szURL)
	if CURL_DownloadFile then
		return X.Promise:new(function(resolve, reject)
			local szRoot = X.FormatPath({'temporary/downloader/', X.PATH_TYPE.GLOBAL})
			local szPath = szRoot .. 'fetch_lua_file_' .. GetStringCRC(szURL) .. '_' .. GetTime() .. '.jx3dat'
			CPath.MakeDir(szRoot)
			X.DownloadFile(szURL, szPath)
				:Then(function()
					resolve(szPath)
				end)
				:Catch(reject)
		end)
	end
	return X.Promise:new(function(resolve, reject)
		local downloader = X.UI.GetTempElement('Image', X.NSFormatString('{$NS}Lib__FetchLUAFile-') .. GetStringCRC(szURL) .. '#' .. GetTime())
		downloader.FromTextureFile = function(_, szPath)
			resolve(szPath)
		end
		downloader:FromRemoteFile(szURL, false, function(image, szImageURL, szAbsPath, bSuccess)
			if not bSuccess then
				reject(X.Error:new('FetchLUAFile failed.'))
			end
			downloader:GetParent():RemoveItem(downloader)
		end)
	end)
end

function X.FetchLUAData(szURL, tOptions)
	return X.Promise:new(function(resolve, reject)
		X.FetchLUAFile(szURL)
			:Then(function(szPath)
				local data = X.LoadLUAData(szPath, tOptions)
				resolve(data)
			end)
			:Catch(reject)
	end)
end

-- 发起数据接口安全稳定的多次重试 Ajax 调用
-- 注意该接口暂只可用于上传 因为不支持返回结果内容
function X.EnsureAjax(options)
	local key = GetStringCRC(X.EncodeLUAData({options.url, options.data}))
	local configs, i, dc = {{'curl', 'post'}, {'origin', 'post'}, {'origin', 'get'}, {'webcef', 'get'}}, 1, nil
	-- 移除无法访问的调用方式，但至少保留一个用于尝试桥接通信
	for i, config in X.ipairs_r(configs) do
		if i >= 1 and not X.CanAjax(config[1], config[2]) then
			table.remove(configs, i)
		end
	end
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage('Ensure ajax ' .. key .. ' preparing: ' .. options.url, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local function TryUploadWithNextDriver()
		local config = configs[i]
		if not config then
			X.SafeCall(options.error)
			return 0
		end
		local driver, method = X.Unpack(config)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('Ensure ajax ' .. key .. ' try mode ' .. driver .. '/' .. method, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		dc, i = X.DelayCall(30000, TryUploadWithNextDriver), i + 1 -- 必须先发起保护再请求，因为请求可能会立刻失败触发gc
		local opt = {
			driver = driver,
			method = method,
			url = options.url,
			data = options.data,
			signature = options.signature,
			fulfilled = function(...)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('Ensure ajax ' .. key .. ' succeed with mode ' .. driver .. '/' .. method, X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				X.DelayCall(dc, false)
				X.SafeCall(options.fulfilled, ...)
			end,
			error = function()
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('Ensure ajax ' .. key .. ' failed with mode ' .. driver .. '/' .. method, X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				X.DelayCall(dc, false)
				TryUploadWithNextDriver()
			end,
		}
		X.Ajax(opt)
	end
	TryUploadWithNextDriver()
end

do local function StringSorter(p1, p2)
	local k1, k2, c1, c2 = tostring(p1.k), tostring(p2.k)
	for i = 1, math.max(#k1, #k2) do
		c1, c2 = string.byte(k1, i, i), string.byte(k2, i, i)
		if not c1 then
			if not c2 then
				return false
			end
			return true
		end
		if not c2 then
			return false
		end
		if c1 ~= c2 then
			return c1 < c2
		end
	end
end
function X.GetPostDataCRC(tData, szPassphrase)
	local a, r = {}, {}
	for k, v in pairs(tData) do
		table.insert(a, { k = k, v = v })
	end
	table.sort(a, StringSorter)
	if szPassphrase then
		table.insert(r, szPassphrase)
	end
	for _, v in ipairs(a) do
		if v.k ~= '_' and v.k ~= '_c' then
			table.insert(r, tostring(v.k) .. ':' .. tostring(v.v))
		end
	end
	return GetStringCRC(table.concat(r, ';'))
end
end

function X.SignPostData(tData, szPassphrase)
	tData._t = GetCurrentTime()
	tData._c = X.GetPostDataCRC(tData, szPassphrase)
	return tData
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
