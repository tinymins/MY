--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 网络请求支持库
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
-------------------------------------------------------------------------------------------------------------

-- (void) LIB.RemoteRequest(string szUrl, func fnAction)       -- 发起远程 HTTP 请求
-- szUrl        -- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction     -- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
function LIB.RemoteRequest(szUrl, fnSuccess, fnError, nTimeout)
	local settings = {
		url     = szUrl,
		success = fnSuccess,
		error   = fnError,
		timeout = nTimeout,
	}
	return LIB.Ajax(settings)
end

do
local RRWP_FREE = {}
local RRWC_FREE = {}
local CALL_AJAX = {}
local AJAX_TAG = NSFormatString('{$NS}_AJAX#')
local AJAX_BRIDGE_WAIT = 10000
local AJAX_BRIDGE_PATH = PACKET_INFO.DATA_ROOT .. '#cache/curl/'

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

local function CreateWebPageFrame()
	local szRequestID, hFrame
	repeat
		szRequestID = ('%X%X'):format(GetTickCount(), floor(random() * 0xEFFF) + 0x1000)
	until not Station.Lookup(NSFormatString('Lowest/{$NS}RRWP_') .. szRequestID)
	--[[#DEBUG BEGIN]]
	LIB.Debug('CreateWebPageFrame: ' .. szRequestID, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	hFrame = Wnd.OpenWindow(PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebPage.ini', NSFormatString('{$NS}RRWP_') .. szRequestID)
	hFrame:Hide()
	return szRequestID, hFrame
end

local Curl_Create = pcall(_G.Curl_Create, '') and _G.Curl_Create or nil
local CURL_HttpRqst = pcall(_G.CURL_HttpRqst, '') and _G.CURL_HttpRqst or nil
local CURL_HttpPost = (pcall(_G.CURL_HttpPostEx, 'TEST', '') and _G.CURL_HttpPostEx)
	or (pcall(_G.CURL_HttpPost, 'TEST', '') and _G.CURL_HttpPost)
	or nil

function LIB.CanAjax(driver, method)
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

-- (void) LIB.Ajax(settings)       -- 发起远程 HTTP 请求
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
function LIB.Ajax(settings)
	assert(IsTable(settings) and IsString(settings.url))
	-- standradize settings
	local id = lower(LIB.GetUUID())
	local oncomplete, onerror = settings.complete, settings.error
	local onfulfilled, onsuccess = settings.fulfilled, settings.success
	local config = {
		id      = id,
		url     = settings.url,
		data    = IIf(IsEmpty(settings.data), nil, settings.data),
		method  = settings.method  or 'get' ,
		payload = settings.payload or 'form',
		driver  = settings.driver  or 'auto',
		timeout = settings.timeout or 60000 ,
		charset = settings.charset or 'utf8',
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
	if (method == 'get' or method == 'delete') and config.data then
		if not config.url:find('?') then
			config.url = config.url .. '?'
		elseif config.url:sub(-1) ~= '&' then
			config.url = config.url .. '&'
		end
		config.url, config.data = config.url .. serialize(config.data), nil
	end
	assert(method == 'post' or method == 'get' or method == 'put' or method == 'delete', NSFormatString('[{$NS}_AJAX] Unknown http request type: ') .. method)

	-------------------------------
	-- finalize settings
	-------------------------------
	--[[#DEBUG BEGIN]]
	LIB.Debug(
		'AJAX',
		config.url .. ' - ' .. config.driver .. '/' .. config.method
			.. ' (' .. driver .. '/' .. method .. ')'
			.. ': PREPARE READY',
		DEBUG_LEVEL.LOG
	)
	--[[#DEBUG END]]
	local bridgewait = GetTime() + AJAX_BRIDGE_WAIT
	local bridgewaitkey = NSFormatString('{$NS}_AJAX_') .. id
	local fulfilled = false
	settings.callback = function(html, status)
		if fulfilled then
			--[[#DEBUG BEGIN]]
			LIB.Debug(
				'AJAX_DUP_CB',
				config.url .. ' - ' .. config.driver .. '/' .. config.method
					.. ' (' .. driver .. '/' .. method .. ')'
					.. ': ' .. (status or '')
					.. '\n' .. debug.traceback(),
				DEBUG_LEVEL.WARNING
			)
			--[[#DEBUG END]]
			return
		end
		local connected = html and status
		--[[#DEBUG BEGIN]]
		LIB.Debug(
			'AJAX',
			config.url .. ' - ' .. config.driver .. '/' .. config.method
				.. ' (' .. driver .. '/' .. method .. ')'
				.. ': ' .. (status or 'FAILED'),
			IIf(connected, DEBUG_LEVEL.LOG, DEBUG_LEVEL.WARNING)
		)
		--[[#DEBUG END]]
		local function resolve()
			fulfilled = true
			SafeCallWithThis(settings.config, oncomplete, html, status, not IsEmpty(status))
			if IsNumber(status) and status >= 200 and status < 400 then
				SafeCallWithThis(settings.config, onfulfilled)
				SafeCallWithThis(settings.config, onsuccess, html, status)
			else
				SafeCallWithThis(settings.config, onerror, html, status)
			end
			XpCall(settings.closebridge)
		end
		if connected then
			resolve()
		else
			LIB.DelayCall(bridgewaitkey, bridgewait - GetTime(), resolve)
		end
	end

	-------------------------------
	-- each driver handlers
	-------------------------------
	-- convert encoding
	local xurl, xdata = config.url, config.data or ''
	if config.charset == 'utf8' then
		xurl  = LIB.ConvertToUTF8(xurl)
		xdata = LIB.ConvertToUTF8(xdata) or ''
	end
	-- bridge
	local bridgekey = NSFormatString('{$NS}RRDF_TO_') .. id
	local bridgein = AJAX_BRIDGE_PATH .. id .. '.' .. GLOBAL.GAME_LANG .. '.jx3dat'
	local bridgeout = AJAX_BRIDGE_PATH .. id .. '.result.' .. GLOBAL.GAME_LANG .. '.jx3dat'
	local bridgetimeout = GetTime() + config.timeout
	settings.closebridge = function()
		CPath.DelFile(bridgein)
		CPath.DelFile(bridgeout)
		LIB.DelayCall(bridgewaitkey, false)
		LIB.BreatheCall(bridgekey, false)
		LIB.DelayCall(bridgekey, false)
		LIB.RegisterExit(bridgekey, false)
	end
	LIB.SaveLUAData(bridgein, config, { crc = false, passphrase = false })
	LIB.BreatheCall(bridgekey, 200, function()
		local data = LIB.LoadLUAData(bridgeout, { passphrase = false })
		if IsTable(data) then
			settings.callback(data.content, data.status)
		elseif GetTime() > bridgetimeout then
			settings.callback()
		end
	end)
	LIB.DelayCall(bridgekey, config.timeout, settings.closebridge)
	LIB.RegisterExit(bridgekey, settings.closebridge)

	local canajax, errmsg = LIB.CanAjax(driver, method)
	if not canajax then
		LIB.Debug(NSFormatString('{$NS}_AJAX'), errmsg, DEBUG_LEVEL.WARNING)
		settings.callback()
		return
	end

	if driver == 'curl' then
		local curl = Curl_Create(xurl)
		if method == 'post' then
			curl:SetMethod('POST')
			local data = config.data
			if config.payload == 'json' then
				data = LIB.JsonEncode(data)
				curl:AddHeader('Content-Type: application/json')
			else -- if config.payload == 'form' then
				data = LIB.EncodePostData(data)
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
			hFrame = Station.Lookup(NSFormatString('Lowest/{$NS}RRWC_') .. RequestID)
			remove(RRWC_FREE)
		end
		-- create page
		if not hFrame then
			RequestID = ('%X_%X'):format(GetTickCount(), floor(random() * 65536))
			hFrame = Wnd.OpenWindow(PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebCef.ini', NSFormatString('{$NS}RRWC_') .. RequestID)
			hFrame:Hide()
		end
		local wWebCef = hFrame:Lookup('WndWebCef')

		-- bind callback function
		wWebCef.OnWebLoadEnd = function()
			-- local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			local szContent = ''
			--[[#DEBUG BEGIN]]
			-- LIB.Debug(NSFormatString('{$NS}RRWC::OnDocumentComplete'), format('%s - %s', szTitle, szUrl), DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- 注销超时处理时钟
			LIB.DelayCall(NSFormatString('{$NS}RRWC_TO_') .. RequestID, false)
			-- 回调函数
			settings.callback(szContent, 200)
			-- 有宕机问题，禁用 FREE 池，直接销毁句柄
			-- insert(RRWC_FREE, RequestID)
			Wnd.CloseWindow(this:GetRoot())
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		LIB.Debug(NSFormatString('{$NS}RRWC'), config.url, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if config.timeout > 0 then
			LIB.DelayCall(NSFormatString('{$NS}RRWC_TO_') .. RequestID, config.timeout, function()
				--[[#DEBUG BEGIN]]
				LIB.Debug(NSFormatString('{$NS}RRWC::Timeout'), config.url, DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				settings.callback()
				-- 有宕机问题，禁用 FREE 池，直接销毁句柄
				-- insert(RRWC_FREE, RequestID)
				Wnd.CloseWindow(hFrame)
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
					LIB.Debug(NSFormatString('{$NS}RRWP::OnDocumentComplete'), format('%s - %s', szTitle, szUrl), DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					-- 注销超时处理时钟
					LIB.DelayCall(NSFormatString('{$NS}RRWP_TO_') .. RequestID, false)
					-- 回调函数
					settings.callback(szContent, 200)
					-- 有宕机问题，禁用 FREE 池，直接销毁句柄
					insert(RRWP_FREE, RequestID)
					-- Wnd.CloseWindow(this:GetRoot())
				end
			end
			-- do with this remote request
			--[[#DEBUG BEGIN]]
			LIB.Debug(NSFormatString('{$NS}RRWP'), config.url, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- register request timeout clock
			if config.timeout > 0 then
				LIB.DelayCall(NSFormatString('{$NS}RRWP_TO_') .. RequestID, config.timeout, function()
					--[[#DEBUG BEGIN]]
					LIB.Debug(NSFormatString('{$NS}RRWP::Timeout'), config.url, DEBUG_LEVEL.WARNING) -- log
					--[[#DEBUG END]]
					settings.callback()
					-- 有宕机问题，禁用 FREE 池，直接销毁句柄
					insert(RRWP_FREE, RequestID)
					-- Wnd.CloseWindow(hFrame)
				end)
			end
			-- start ie navigate
			wWebPage:Navigate(xurl)
		end
		local nFreeWebPages = #RRWP_FREE
		if nFreeWebPages > 0 then
			RequestID = RRWP_FREE[nFreeWebPages]
			hFrame = Station.Lookup(NSFormatString('Lowest/{$NS}RRWP_') .. RequestID)
			remove(RRWP_FREE)
		end
		-- create page
		if hFrame then
			OnWebPageFrameCreate()
		else
			local szKey = NSFormatString('{$NS}_AJAX#RRWP#') .. config.id
			LIB.BreatheCall(szKey, function()
				if LIB.IsFighting() or not Cursor.IsVisible() then
					return
				end
				LIB.BreatheCall(szKey, false)
				RequestID, hFrame = CreateWebPageFrame()
				OnWebPageFrameCreate()
			end)
		end
	else -- if driver == 'origin' then
		local szKey = GetTickCount() * 100
		while CALL_AJAX['__addon_' .. AJAX_TAG .. szKey] do
			szKey = szKey + 1
		end
		szKey = AJAX_TAG .. szKey
		local ssl = config.url:sub(1, 6) == 'https:'
		if method == 'post' then
			CURL_HttpPost(szKey, xurl, xdata, ssl, config.timeout)
		else
			CURL_HttpRqst(szKey, xurl, ssl, config.timeout)
		end
		CALL_AJAX['__addon_' .. szKey] = settings
	end
end

local function OnCurlRequestResult()
	local szKey        = arg0
	local bSuccess     = arg1
	local html         = arg2
	local dwBufferSize = arg3
	if CALL_AJAX[szKey] then
		local settings = CALL_AJAX[szKey]
		if dwBufferSize == 0 then
			settings.callback()
		else
			local status = bSuccess and 200 or 500
			if settings.config.charset == 'utf8' then
				html = UTF8ToAnsi(html)
			end
			settings.callback(html, status)
		end
		CALL_AJAX[szKey] = nil
	end
end
LIB.RegisterEvent('CURL_REQUEST_RESULT', 'AJAX', OnCurlRequestResult)
end

function LIB.DownloadFile(szPath, resolve, reject)
	local downloader = LIB.UI.GetTempElement(NSFormatString('Image.{$NS}#DownloadFile-') .. GetStringCRC(szPath) .. '#' .. GetTime())
	downloader.FromTextureFile = function(_, szPath)
		Call(resolve, szPath)
	end
	downloader:FromRemoteFile(szPath, false, function(image, szURL, szAbsPath, bSuccess)
		if not bSuccess then
			Call(reject)
		end
		downloader:GetParent():RemoveItem(downloader)
	end)
end

-- 发起数据接口安全稳定的多次重试 Ajax 调用
-- 注意该接口暂只可用于上传 因为不支持返回结果内容
function LIB.EnsureAjax(options)
	local key = GetStringCRC(options.url)
	local configs, i, dc = {{'curl', 'post'}, {'origin', 'post'}, {'origin', 'get'}, {'webcef', 'get'}}, 1, nil
	-- 移除无法访问的调用方式，但至少保留一个用于尝试桥接通信
	for i, config in ipairs_r(configs) do
		if i >= 1 and not LIB.CanAjax(config[1], config[2]) then
			remove(configs, i)
		end
	end
	--[[#DEBUG BEGIN]]
	LIB.Debug('Ensure ajax ' .. key .. ' preparing: ' .. options.url, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local function TryUploadWithNextDriver()
		local config = configs[i]
		if not config then
			SafeCall(options.error)
			return 0
		end
		--[[#DEBUG BEGIN]]
		LIB.Debug('Ensure ajax ' .. key .. ' try mode ' .. config[1] .. '/' .. config[2], DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		dc, i = LIB.DelayCall(30000, TryUploadWithNextDriver), i + 1 -- 必须先发起保护再请求，因为请求可能会立刻失败触发gc
		local opt = {
			driver = config[1],
			method = config[2],
			url = options.url,
			fulfilled = function(...)
				--[[#DEBUG BEGIN]]
				LIB.Debug('Ensure ajax ' .. key .. ' succeed with mode ' .. config[1] .. '/' .. config[2], DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				LIB.DelayCall(dc, false)
				SafeCall(options.fulfilled, ...)
			end,
			error = function()
				--[[#DEBUG BEGIN]]
				LIB.Debug('Ensure ajax ' .. key .. ' failed with mode ' .. config[1] .. '/' .. config[2], DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				LIB.DelayCall(dc, false)
				TryUploadWithNextDriver()
			end,
		}
		LIB.Ajax(opt)
	end
	TryUploadWithNextDriver()
end

do local function StringSorter(p1, p2)
	local k1, k2, c1, c2 = tostring(p1.k), tostring(p2.k)
	for i = 1, max(#k1, #k2) do
		c1, c2 = byte(k1, i, i), byte(k2, i, i)
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
function LIB.GetPostDataCRC(tData, szPassphrase)
	local a, r = {}, {}
	for k, v in pairs(tData) do
		insert(a, { k = k, v = v })
	end
	sort(a, StringSorter)
	if szPassphrase then
		insert(r, szPassphrase)
	end
	for _, v in ipairs(a) do
		if v.k ~= '_' and v.k ~= '_c' then
			insert(r, tostring(v.k) .. ':' .. tostring(v.v))
		end
	end
	return GetStringCRC(concat(r, ';'))
end
end

function LIB.SignPostData(tData, szPassphrase)
	tData._t = GetCurrentTime()
	tData._c = LIB.GetPostDataCRC(tData, szPassphrase)
	tData._ = GetCurrentTime()
	return tData
end
