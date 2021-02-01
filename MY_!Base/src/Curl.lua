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
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/libs/')
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

local function CallWithThis(context, fn, ...)
	local _this = this
	this = context
	local rtc = {Call(fn, ...)}
	this = _this
	return unpack(rtc)
end

do
local RRWP_FREE = {}
local RRWC_FREE = {}
local CALL_AJAX = {}
local AJAX_TAG = NSFormatString('{$NS}_AJAX#')
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
	until not Station.Lookup(NSFormatString('Lowest/{$NS}RRWP_') .. szRequestID)
	--[[#DEBUG BEGIN]]
	LIB.Debug('CreateWebPageFrame: ' .. szRequestID, DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	hFrame = Wnd.OpenWindow(PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebPage.ini', NSFormatString('{$NS}RRWP_') .. szRequestID)
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
	assert(method == 'post' or method == 'get' or method == 'put' or method == 'delete', NSFormatString('[{$NS}_AJAX] Unknown http request type: ') .. method)

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

	if not settings.success and not settings.fulfilled then
		settings.fulfilled = function()
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
		settings.error = function(html, status, connected)
			--[[#DEBUG BEGIN]]
			LIB.Debug(
				'AJAX',
				settings.url .. ' - ' .. settings.driver .. '/' .. settings.method
					.. ' (' .. driver .. '/' .. method .. ')'
					.. ': ' .. (connected and status or 'FAILED'),
				DEBUG_LEVEL.WARNING
			)
			--[[#DEBUG END]]
		end
	end

	--[[#DEBUG BEGIN]]
	LIB.Debug(
		'AJAX',
		settings.url .. ' - ' .. settings.driver .. '/' .. settings.method
			.. ' (' .. driver .. '/' .. method .. ')'
			.. ': PREPARE READY',
		DEBUG_LEVEL.LOG
	)
	--[[#DEBUG END]]
	if driver == 'curl' then
		if not Curl_Create then
			return CallWithThis(settings, settings.error, '', 0, false)
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
				CallWithThis(settings, settings.complete, html, code, success)
			end
		end)
		curl:OnSuccess(function(html, code)
			if settings.fulfilled then
				CallWithThis(settings, settings.fulfilled)
			end
			if settings.success then
				if settings.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
				CallWithThis(settings, settings.success, html, code)
			end
		end)
		curl:OnError(function(html, code, connected)
			if settings.error then
				if settings.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
				CallWithThis(settings, settings.error, html, code, connected)
			end
		end)
		curl:SetConnTimeout(settings.timeout)
		curl:Perform()
	elseif driver == 'webcef' then
		assert(method == 'get', NSFormatString('[{$NS}_AJAX] Webcef only support get method, got ') .. method)
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
			-- 成功回调函数
			if settings.fulfilled then
				CallWithThis(settings, settings.fulfilled)
			end
			if settings.success then
				CallWithThis(settings, settings.success, szContent, 200)
			end
			-- 有宕机问题，禁用 FREE 池，直接销毁句柄
			-- insert(RRWC_FREE, RequestID)
			Wnd.CloseWindow(this:GetRoot())
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		LIB.Debug(NSFormatString('{$NS}RRWC'), settings.url, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if settings.timeout > 0 then
			LIB.DelayCall(NSFormatString('{$NS}RRWC_TO_') .. RequestID, settings.timeout, function()
				--[[#DEBUG BEGIN]]
				LIB.Debug(NSFormatString('{$NS}RRWC::Timeout'), settings.url, DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				if settings.error then
					CallWithThis(settings, settings.error, '', 0, false)
				end
				-- insert(RRWC_FREE, RequestID)
			end)
		end

		-- start chrome navigate
		wWebCef:Navigate(url)
	elseif driver == 'webbrowser' then
		assert(method == 'get', NSFormatString('[{$NS}_AJAX] Webbrowser only support get method, got ') .. method)
		local RequestID, hFrame
		local nFreeWebPages = #RRWP_FREE
		if nFreeWebPages > 0 then
			RequestID = RRWP_FREE[nFreeWebPages]
			hFrame = Station.Lookup(NSFormatString('Lowest/{$NS}RRWP_') .. RequestID)
			remove(RRWP_FREE)
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
				LIB.Debug(NSFormatString('{$NS}RRWP::OnDocumentComplete'), format('%s - %s', szTitle, szUrl), DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				-- 注销超时处理时钟
				LIB.DelayCall(NSFormatString('{$NS}RRWP_TO_') .. RequestID, false)
				-- 成功回调函数
				if settings.fulfilled then
					CallWithThis(settings, settings.fulfilled)
				end
				if settings.success then
					CallWithThis(settings, settings.success, szContent, 200)
				end
				if settings.complete then
					CallWithThis(settings, settings.complete, szContent, 200, true)
				end
				insert(RRWP_FREE, RequestID)
			end
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		LIB.Debug(NSFormatString('{$NS}RRWP'), settings.url, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if settings.timeout > 0 then
			LIB.DelayCall(NSFormatString('{$NS}RRWP_TO_') .. RequestID, settings.timeout, function()
				--[[#DEBUG BEGIN]]
				LIB.Debug(NSFormatString('{$NS}RRWP::Timeout'), settings.url, DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				if settings.error then
					CallWithThis(settings, settings.error, '', 0, false)
				end
				if settings.complete then
					CallWithThis(settings, settings.complete, '', 500, false)
				end
				-- insert(RRWP_FREE, RequestID)
			end)
		end

		-- start ie navigate
		wWebPage:Navigate(url)
	else -- if driver == 'origin' then
		local szKey = GetTickCount() * 100
		while CALL_AJAX['__addon_' .. AJAX_TAG .. szKey] do
			szKey = szKey + 1
		end
		szKey = AJAX_TAG .. szKey
		if method == 'post' then
			if not CURL_HttpPost then
				return CallWithThis(settings, settings.error, '', 0, false)
			end
			CURL_HttpPost(szKey, url, data, ssl, settings.timeout)
		else
			if not CURL_HttpRqst then
				return CallWithThis(settings, settings.error, '', 0, false)
			end
			CURL_HttpRqst(szKey, url, ssl, settings.timeout)
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
		local status = bSuccess and 200 or 500
		if settings.charset == 'utf8' and IsString(html) then
			html = UTF8ToAnsi(html)
		end
		if settings.complete then
			CallWithThis(settings, settings.complete, html, status, bSuccess or dwBufferSize > 0)
		end
		if bSuccess then
			-- if settings.payload == 'json' then
			-- 	html = LIB.JsonDecode(html)
			-- end
			if settings.fulfilled then
				CallWithThis(settings, settings.fulfilled)
			end
			if settings.success then
				CallWithThis(settings, settings.success, html, status)
			end
		else
			CallWithThis(settings, settings.error, html, status, dwBufferSize ~= 0)
		end
		CALL_AJAX[szKey] = nil
	end
end
LIB.RegisterEvent('CURL_REQUEST_RESULT.AJAX', OnCurlRequestResult)
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
	local configs, i, dc = {{'curl', 'post'}, {'origin', 'post'}, {'origin', 'get'}, {'webcef', 'get'}}, 1
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
