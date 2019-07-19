--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 网络请求支持库
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
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
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local EMPTY_TABLE, MENU_DIVIDER, XML_LINE_BREAKER = LIB.EMPTY_TABLE, LIB.MENU_DIVIDER, LIB.XML_LINE_BREAKER
-----------------------------------------------------------------------------------------------------------
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
		type = 'get',
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
		szRequestID = ('%X%X'):format(GetTickCount(), math.floor(math.random() * 0xEFFF) + 0x1000)
	until not Station.Lookup('Lowest/MYRRWP_' .. szRequestID)
	hFrame = Wnd.OpenWindow(PACKET_INFO.FRAMEWORK_ROOT .. 'ui/WndWebPage.ini', 'MYRRWP_' .. szRequestID)
	hFrame:Hide()
	return szRequestID, hFrame
end

-- 先开几个常驻防止创建时抢焦点
for i = 1, 5 do
	local szRequestID = CreateWebPageFrame()
	insert(MY_RRWP_FREE, szRequestID)
end

local CURL_HttpPost = CURL_HttpPostEx or CURL_HttpPost
function LIB.Ajax(settings)
	assert(settings and settings.url)
	setmetatable(settings, l_ajaxsettingsmeta)

	local url, data = settings.url, settings.data
	if settings.charset == 'utf8' then
		url  = LIB.ConvertToUTF8(url)
		data = LIB.ConvertToUTF8(data)
	end

	local ssl = url:sub(1, 6) == 'https:'
	local method, payload = unpack(LIB.SplitString(settings.type, '/'))
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
			LIB.Debug({settings.url .. ' - SUCCESS'}, 'AJAX', DEBUG_LEVEL.LOG)
		end
	end
	if not settings.error then
		settings.error = function(html, status, success)
			LIB.Debug({settings.url .. ' - STATUS ' .. (success and status or 'failed')}, 'AJAX', DEBUG_LEVEL.WARNING)
		end
	end

	if driver == 'curl' then
		if not Curl_Create then
			return settings.error()
		end
		local curl = Curl_Create(url)
		if method == 'post' then
			curl:SetMethod('POST')
			if payload == 'json' then
				data = LIB.JsonEncode(data)
				curl:AddHeader('Content-Type: application/json')
			else -- if payload == 'form' then
				data = LIB.EncodePostData(data)
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
	elseif driver == 'webcef' then
		assert(method == 'get', '[MY_AJAX] Webcef only support get method, got ' .. method)
		local RequestID, hFrame
		local nFreeWebPages = #MY_RRWC_FREE
		if nFreeWebPages > 0 then
			RequestID = MY_RRWC_FREE[nFreeWebPages]
			hFrame = Station.Lookup('Lowest/MYRRWC_' .. RequestID)
			table.remove(MY_RRWC_FREE)
		end
		-- create page
		if not hFrame then
			RequestID = ('%X_%X'):format(GetTickCount(), math.floor(math.random() * 65536))
			hFrame = Wnd.OpenWindow(PACKET_INFO.FRAMEWORK_ROOT .. 'ui/WndWebCef.ini', 'MYRRWC_' .. RequestID)
			hFrame:Hide()
		end
		local wWebCef = hFrame:Lookup('WndWebCef')

		-- bind callback function
		wWebCef.OnWebLoadEnd = function()
			-- local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			-- LIB.Debug({string.format('%s - %s', szTitle, szUrl)}, 'MYRRWC::OnDocumentComplete', DEBUG_LEVEL.LOG)
			-- 注销超时处理时钟
			LIB.DelayCall('MYRRWC_TO_' .. RequestID, false)
			-- 成功回调函数
			-- if settings.success then
			-- 	local status, err = pcall_this(settings.context, settings.success, szContent, 200, settings)
			-- 	if not status then
			-- 		LIB.Debug({err}, 'MYRRWC::OnDocumentComplete::Callback', DEBUG_LEVEL.ERROR)
			-- 	end
			-- end
			table.insert(MY_RRWC_FREE, RequestID)
		end

		-- do with this remote request
		LIB.Debug({settings.url}, 'MYRRWC', DEBUG_LEVEL.LOG)
		-- register request timeout clock
		if settings.timeout > 0 then
			LIB.DelayCall('MYRRWC_TO_' .. RequestID, settings.timeout, function()
				LIB.Debug({settings.url}, 'MYRRWC::Timeout', DEBUG_LEVEL.WARNING) -- log
				-- request timeout, call timeout function.
				if settings.error then
					local status, err = pcall_this(settings.context, settings.error, 'timeout', settings)
					if not status then
						LIB.Debug({err}, 'MYRRWC::TIMEOUT', DEBUG_LEVEL.ERROR)
					end
				end
				table.insert(MY_RRWC_FREE, RequestID)
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
			table.remove(MY_RRWP_FREE)
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
				LIB.Debug({string.format('%s - %s', szTitle, szUrl)}, 'MYRRWP::OnDocumentComplete', DEBUG_LEVEL.LOG)
				-- 注销超时处理时钟
				LIB.DelayCall('MYRRWP_TO_' .. RequestID, false)
				-- 成功回调函数
				if settings.success then
					local status, err = pcall_this(settings.context, settings.success, szContent, 200, settings)
					if not status then
						LIB.Debug({err}, 'MYRRWP::OnDocumentComplete::Callback', DEBUG_LEVEL.ERROR)
					end
				end
				if settings.complete then
					local status, err = pcall_this(settings.context, settings.complete, szContent, 200, true)
					if not status then
						LIB.Debug({err}, 'MYRRWP::OnDocumentComplete::Callback::Complete', DEBUG_LEVEL.ERROR)
					end
				end
				table.insert(MY_RRWP_FREE, RequestID)
			end
		end

		-- do with this remote request
		LIB.Debug({settings.url}, 'MYRRWP', DEBUG_LEVEL.LOG)
		-- register request timeout clock
		if settings.timeout > 0 then
			LIB.DelayCall('MYRRWP_TO_' .. RequestID, settings.timeout, function()
				LIB.Debug({settings.url}, 'MYRRWP::Timeout', DEBUG_LEVEL.WARNING) -- log
				-- request timeout, call timeout function.
				if settings.error then
					local status, err = pcall_this(settings.context, settings.error, 'timeout', settings)
					if not status then
						LIB.Debug({err}, 'MYRRWP::TIMEOUT', DEBUG_LEVEL.ERROR)
					end
				end
				if settings.complete then
					local status, err = pcall_this(settings.context, settings.complete, '', 500, false)
					if not status then
						LIB.Debug({err}, 'MYRRWP::TIMEOUT::Callback::Complete', DEBUG_LEVEL.ERROR)
					end
				end
				table.insert(MY_RRWP_FREE, RequestID)
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
		local method, payload = unpack(LIB.SplitString(settings.type, '/'))
		local status = bSuccess and 200 or 500
		if settings.complete then
			local status, err = pcall(settings.complete, html, status, bSuccess or dwBufferSize > 0)
			if not status then
				LIB.Debug({GetTraceback('CURL # ' .. settings.url .. ' - complete - PCALL ERROR - ' .. err)}, DEBUG_LEVEL.ERROR)
			end
		end
		if bSuccess then
			if settings.charset == 'utf8' and html ~= nil and CLIENT_LANG == 'zhcn' then
				html = UTF8ToAnsi(html)
			end
			-- if payload == 'json' then
			-- 	html = LIB.JsonDecode(html)
			-- end
			local status, err = pcall(settings.success, html, status)
			if not status then
				LIB.Debug({GetTraceback('CURL # ' .. settings.url .. ' - success - PCALL ERROR - ' .. err)}, DEBUG_LEVEL.ERROR)
			end
		else
			local status, err = pcall(settings.error, html, status, dwBufferSize ~= 0)
			if not status then
				LIB.Debug({GetTraceback('CURL # ' .. settings.url .. ' - error - PCALL ERROR - ' .. err)}, DEBUG_LEVEL.ERROR)
			end
		end
		MY_CALL_AJAX[szKey] = nil
	end
end
LIB.RegisterEvent('CURL_REQUEST_RESULT.AJAX', OnCurlRequestResult)
end
