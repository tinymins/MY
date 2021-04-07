--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : IE
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

-- ÅÐ¶Ïä¯ÀÀÆ÷ÊÇ·ñÒÑ¿ªÆô
local function IsInternetExplorerOpened(nIndex)
	local frame = Station.Lookup('Topmost/IE' .. nIndex)
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

-- »ñÈ¡ä¯ÀÀÆ÷¾ø¶ÔÎ»ÖÃ
local function IE_GetNewIEFramePos()
	local nLastTime = 0
	local nLastIndex = nil
	for i = 1, 10, 1 do
		local frame = Station.Lookup('Topmost/IE' .. i)
		if frame and frame:IsVisible() then
			if frame.nOpenTime > nLastTime then
				nLastTime = frame.nOpenTime
				nLastIndex = i
			end
		end
	end
	if nLastIndex then
		local frame = Station.Lookup('Topmost/IE' .. nLastIndex)
		local x, y = frame:GetAbsPos()
		local wC, hC = Station.GetClientSize()
		if x + 890 <= wC and y + 630 <= hC then
			return x + 30, y + 30
		end
	end
	return 40, 40
end

-- ´ò¿ªä¯ÀÀÆ÷
function UI.OpenIE(szAddr, bDisableSound, w, h)
	local nIndex, nLast = nil, nil
	for i = 1, 10, 1 do
		if not IsInternetExplorerOpened(i) then
			nIndex = i
			break
		elseif not nLast then
			nLast = i
		end
	end
	if not nIndex then
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.MSG_OPEN_TOO_MANY)
		return nil
	end
	local x, y = IE_GetNewIEFramePos()
	local frame = Wnd.OpenWindow('InternetExplorer', 'IE' .. nIndex)
	frame.bIE = true
	frame.nIndex = nIndex

	if w and h then
		UI.ResizeIE(frame, w, h)
	end
	frame:BringToTop()
	if nLast then
		frame:SetAbsPos(x, y)
		frame:CorrectPos()
		frame.x = x
		frame.y = y
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
		frame.x, frame.y = frame:GetAbsPos()
	end
	local webPage = frame:Lookup('WebPage_Page')
	if szAddr then
		webPage:Navigate(szAddr)
	end
	Station.SetFocusWindow(webPage)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	return webPage
end

function UI.ResizeIE(frame, w, h)
	if w < 400 then w = 400 end
	if h < 200 then h = 200 end
	local handle = frame:Lookup('', '')
	handle:SetSize(w, h)
	handle:Lookup('Image_Bg'):SetSize(w, h)
	handle:Lookup('Image_BgT'):SetSize(w - 6, 64)
	if not frame.bQuestionnaire then
		handle:Lookup('Image_Edit'):SetSize(w - 300, 25)
	end
	handle:Lookup('Text_Title'):SetSize(w - 168, 30)
	handle:FormatAllItemPos()

	local webPage = frame:Lookup('WebPage_Page')
	if frame.bQuestionnaire then
		webPage:SetSize(w - 20, h - 140)
	else
		webPage:SetSize(w - 12, h - 76)
		frame:Lookup('Edit_Input'):SetSize(w - 306, 20)
		frame:Lookup('Btn_GoTo'):SetRelPos(w - 110, 38)
	end

	frame:Lookup('Btn_Close'):SetRelPos(w - 40, 10)
	frame:Lookup('CheckBox_MaxSize'):SetRelPos(w - 70, 10)

	frame:Lookup('Btn_DL'):SetSize(10, h - 20)
	frame:Lookup('Btn_DT'):SetSize(w - 20, 10)
	frame:Lookup('Btn_DTR'):SetRelPos(w - 10, 0)
	frame:Lookup('Btn_DR'):SetRelPos(w - 10, 10)
	frame:Lookup('Btn_DR'):SetSize(10, h - 20)
	frame:Lookup('Btn_DRB'):SetRelPos(w - 10, h - 10)
	frame:Lookup('Btn_DB'):SetRelPos(10, h - 10)
	frame:Lookup('Btn_DB'):SetSize(w - 20, 10)
	frame:Lookup('Btn_DLB'):SetRelPos(0, h - 10)

	frame:SetSize(w, h)
	frame:SetDragArea(0, 0, w, 30)
end
