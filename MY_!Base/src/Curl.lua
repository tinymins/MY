--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 网络请求支持库
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
-------------------------------------------------------------------------------------------------------------

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
local MY_RRWP_FREE = {}
local MY_RRWC_FREE = {}
local MY_CALL_AJAX = {}
local MY_AJAX_TAG = 'MY_AJAX#'
local l_ajaxsettingsmeta = {
	__index = {
		method = 'get',
		payload = 'form',
		driver = 'auto',
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

local function CreateWebPageFrame()
	local szRequestID, hFrame
	repeat
		szRequestID = ('%X%X'):format(GetTickCount(), floor(random() * 0xEFFF) + 0x1000)
	until not Station.Lookup('Lowest/MYRRWP_' .. szRequestID)
	--[[#DEBUG BEGIN]]
	LIB.Debug('CreateWebPageFrame: ' .. szRequestID, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	hFrame = Wnd.OpenWindow(PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebPage.ini', 'MYRRWP_' .. szRequestID)
	hFrame:Hide()
	return szRequestID, hFrame
end

local Curl_Create = _G.Curl_Create
local CURL_HttpRqst = _G.CURL_HttpRqst
local CURL_HttpPost = _G.CURL_HttpPostEx or _G.CURL_HttpPost
function LIB.Ajax(settings)
	assert(settings and settings.url)
	setmetatable(settings, l_ajaxsettingsmeta)

	local url, data = settings.url, settings.data
	if settings.charset == 'utf8' then
		url  = LIB.ConvertToUTF8(url)
		data = LIB.ConvertToUTF8(data)
	end

	local ssl = url:sub(1, 6) == 'https:'
	local method = settings.method
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
	if (method == 'get' or method == 'delete') and data then
		if not url:find('?') then
			url = url .. '?'
		elseif url:sub(-1) ~= '&' then
			url = url .. '&'
		end
		url, data = url .. serialize(data), nil
	end
	assert(method == 'post' or method == 'get' or method == 'put' or method == 'delete', '[MY_AJAX] Unknown http request type: ' .. method)

	local driver = settings.driver
	if driver == 'auto' then
		if Curl_Create then
			driver = 'curl'
		elseif CURL_HttpRqst and method == 'get' then
			driver = 'origin'
		elseif CURL_HttpPost and method == 'post' then
			driver = 'origin'
		elseif settings.success then
			driver = 'webbrowser'
		else
			driver = 'webcef'
		end
	end

	if not settings.success then
		settings.success = function(html, status)
			--[[#DEBUG BEGIN]]
			LIB.Debug(
				'AJAX',
				settings.url .. ' - ' .. settings.driver .. '/' .. settings.method
					.. ' (' .. driver .. '/' .. method .. ')'
					.. ': SUCCESS',
				DEBUG_LEVEL.LOG
			)
			--[[#DEBUG END]]
		end
	end
	if not settings.error then
		settings.error = function(html, status, success)
			--[[#DEBUG BEGIN]]
			LIB.Debug(
				'AJAX',
				settings.url .. ' - ' .. settings.driver .. '/' .. settings.method
					.. ' (' .. driver .. '/' .. method .. ')'
					.. ': ' .. (success and status or 'FAILED'),
				DEBUG_LEVEL.WARNING
			)
			--[[#DEBUG END]]
		end
	end

	if driver == 'curl' then
		if not Curl_Create then
			return settings.error()
		end
		local curl = Curl_Create(url)
		if method == 'post' then
			curl:SetMethod('POST')
			if settings.payload == 'json' then
				data = LIB.JsonEncode(data)
				curl:AddHeader('Content-Type: application/json')
			else -- if settings.payload == 'form' then
				data = LIB.EncodePostData(data)
				curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
			end
			curl:AddPostRawData(data)
		elseif method == 'get' then
			curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
		end
		curl:OnComplete(function(html, code, success)
			if settings.complete then
				if settings.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
				settings.complete(html, code, success)
			end
		end)
		curl:OnSuccess(function(html, code)
			if settings.success then
				if settings.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
				settings.success(html, code, settings)
			end
		end)
		curl:OnError(function(html, code, success)
			if settings.error then
				if settings.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
				settings.error(html, code, settings)
			end
		end)
		curl:SetConnTimeout(settings.timeout)
		curl:Perform()
	elseif driver == 'webcef' then
		assert(method == 'get', '[MY_AJAX] Webcef only support get method, got ' .. method)
		local RequestID, hFrame
		local nFreeWebPages = #MY_RRWC_FREE
		if nFreeWebPages > 0 then
			RequestID = MY_RRWC_FREE[nFreeWebPages]
			hFrame = Station.Lookup('Lowest/MYRRWC_' .. RequestID)
			remove(MY_RRWC_FREE)
		end
		-- create page
		if not hFrame then
			RequestID = ('%X_%X'):format(GetTickCount(), floor(random() * 65536))
			hFrame = Wnd.OpenWindow(PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebCef.ini', 'MYRRWC_' .. RequestID)
			hFrame:Hide()
		end
		local wWebCef = hFrame:Lookup('WndWebCef')

		-- bind callback function
		wWebCef.OnWebLoadEnd = function()
			-- local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			local szContent = ''
			--[[#DEBUG BEGIN]]
			-- LIB.Debug('MYRRWC::OnDocumentComplete', format('%s - %s', szTitle, szUrl), DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- 注销超时处理时钟
			LIB.DelayCall('MYRRWC_TO_' .. RequestID, false)
			-- 成功回调函数
			-- if settings.success then
			--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall_this(settings.context, settings.success, szContent, 200, settings)
			--[[#DEBUG BEGIN]]
			-- 	if not status then
			-- 		LIB.Debug('MYRRWC::OnDocumentComplete::Callback', err, DEBUG_LEVEL.ERROR)
			-- 	end
			--[[#DEBUG END]]
			-- end
			insert(MY_RRWC_FREE, RequestID)
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		LIB.Debug('MYRRWC', settings.url, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if settings.timeout > 0 then
			LIB.DelayCall('MYRRWC_TO_' .. RequestID, settings.timeout, function()
				--[[#DEBUG BEGIN]]
				LIB.Debug('MYRRWC::Timeout', settings.url, DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				if settings.error then
					--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall_this(settings.context, settings.error, 'timeout', settings)
					--[[#DEBUG BEGIN]]
					if not status then
						LIB.Debug('MYRRWC::TIMEOUT', err, DEBUG_LEVEL.ERROR)
					end
					--[[#DEBUG END]]
				end
				insert(MY_RRWC_FREE, RequestID)
			end)
		end

		-- start chrome navigate
		wWebCef:Navigate(url)
	elseif driver == 'webbrowser' then
		assert(method == 'get', '[MY_AJAX] Webbrowser only support get method, got ' .. method)
		local RequestID, hFrame
		local nFreeWebPages = #MY_RRWP_FREE
		if nFreeWebPages > 0 then
			RequestID = MY_RRWP_FREE[nFreeWebPages]
			hFrame = Station.Lookup('Lowest/MYRRWP_' .. RequestID)
			remove(MY_RRWP_FREE)
		end
		-- create page
		if not hFrame then
			if LIB.IsFighting() or not Cursor.IsVisible() then
				return LIB.DelayCall(1, LIB.Ajax, settings)
			end
			RequestID, hFrame = CreateWebPageFrame()
		end
		local wWebPage = hFrame:Lookup('WndWebPage')

		-- bind callback function
		wWebPage.OnDocumentComplete = function()
			local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			if szUrl ~= szTitle or szContent ~= '' then
				--[[#DEBUG BEGIN]]
				LIB.Debug('MYRRWP::OnDocumentComplete', format('%s - %s', szTitle, szUrl), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				-- 注销超时处理时钟
				LIB.DelayCall('MYRRWP_TO_' .. RequestID, false)
				-- 成功回调函数
				if settings.success then
					--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall_this(settings.context, settings.success, szContent, 200, settings)
					--[[#DEBUG BEGIN]]
					if not status then
						LIB.Debug('MYRRWP::OnDocumentComplete::Callback', err, DEBUG_LEVEL.ERROR)
					end
					--[[#DEBUG END]]
				end
				if settings.complete then
					--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall_this(settings.context, settings.complete, szContent, 200, true)
					--[[#DEBUG BEGIN]]
					if not status then
						LIB.Debug('MYRRWP::OnDocumentComplete::Callback::Complete', err, DEBUG_LEVEL.ERROR)
					end
					--[[#DEBUG END]]
				end
				insert(MY_RRWP_FREE, RequestID)
			end
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		LIB.Debug('MYRRWP', settings.url, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if settings.timeout > 0 then
			LIB.DelayCall('MYRRWP_TO_' .. RequestID, settings.timeout, function()
				--[[#DEBUG BEGIN]]
				LIB.Debug('MYRRWP::Timeout', settings.url, DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				if settings.error then
					--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall_this(settings.context, settings.error, 'timeout', settings)
					--[[#DEBUG BEGIN]]
					if not status then
						LIB.Debug('MYRRWP::TIMEOUT', err, DEBUG_LEVEL.ERROR)
					end
					--[[#DEBUG END]]
				end
				if settings.complete then
					--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall_this(settings.context, settings.complete, '', 500, false)
					--[[#DEBUG BEGIN]]
					if not status then
						LIB.Debug('MYRRWP::TIMEOUT::Callback::Complete', err, DEBUG_LEVEL.ERROR)
					end
					--[[#DEBUG END]]
				end
				insert(MY_RRWP_FREE, RequestID)
			end)
		end

		-- start ie navigate
		wWebPage:Navigate(url)
	else -- if driver == 'origin' then
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
		MY_CALL_AJAX['__addon_' .. szKey] = settings
	end
end

local function OnCurlRequestResult()
	local szKey        = arg0
	local bSuccess     = arg1
	local html         = arg2
	local dwBufferSize = arg3
	if MY_CALL_AJAX[szKey] then
		local settings = MY_CALL_AJAX[szKey]
		local status = bSuccess and 200 or 500
		if settings.charset == 'utf8' and IsString(html) then
			html = UTF8ToAnsi(html)
		end
		if settings.complete then
			--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall(settings.complete, html, status, bSuccess or dwBufferSize > 0)
			--[[#DEBUG BEGIN]]
			if not status then
				LIB.Debug(GetTraceback('CURL # ' .. settings.url .. ' - complete - PCALL ERROR - ' .. err), DEBUG_LEVEL.ERROR)
			end
			--[[#DEBUG END]]
		end
		if bSuccess then
			-- if settings.payload == 'json' then
			-- 	html = LIB.JsonDecode(html)
			-- end
			--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall(settings.success, html, status)
			--[[#DEBUG BEGIN]]
			if not status then
				LIB.Debug(GetTraceback('CURL # ' .. settings.url .. ' - success - PCALL ERROR - ' .. err), DEBUG_LEVEL.ERROR)
			end
			--[[#DEBUG END]]
		else
			--[[#DEBUG BEGIN]]local status, err = --[[#DEBUG END]]pcall(settings.error, html, status, dwBufferSize ~= 0)
			--[[#DEBUG BEGIN]]
			if not status then
				LIB.Debug(GetTraceback('CURL # ' .. settings.url .. ' - error - PCALL ERROR - ' .. err), DEBUG_LEVEL.ERROR)
			end
			--[[#DEBUG END]]
		end
		MY_CALL_AJAX[szKey] = nil
	end
end
LIB.RegisterEvent('CURL_REQUEST_RESULT.AJAX', OnCurlRequestResult)
end
