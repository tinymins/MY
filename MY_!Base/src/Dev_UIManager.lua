--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : UI窗口枚举器
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
local LIB = MY
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

local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. '/lang/devs/')
---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local UI_DESC = _L.UI_DESC or {}

local function GetMeun(ui)
	local menu, frames = { szOption = ui }, {}
	local frame = Station.Lookup(ui):GetFirstChild()
	while frame do
		insert(frames, { szName = frame:GetName() })
		frame = frame:GetNext()
	end
	sort(frames, function(a, b) return a.szName < b.szName end)
	for k, v in ipairs(frames) do
		local szPath = ui .. '/' .. v.szName
		local frame = Station.Lookup(szPath)
		local szOption = v.szName
		if UI_DESC[szPath] then
			szOption = szOption .. ' (' .. UI_DESC[szPath]  .. ')'
		end
		insert(menu, {
			szOption = szOption,
			bCheck = true,
			bChecked = frame:IsVisible(),
			rgb = frame:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
			fnAction = function()
				if frame:IsVisible() then
					frame:Hide()
				else
					frame:Show()
				end
				if IsCtrlKeyDown() then
					Wnd.CloseWindow(frame)
				end
			end
		})
	end
	return menu
end

TraceButton_AppendAddonMenu({function()
	if not LIB.IsDebugClient('Dev_UIManager') then
		return
	end
	local menu = { szOption = _L['Dev_UIManager'] }
	for k, v in ipairs({ 'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2' })do
		insert(menu, GetMeun(v))
	end
	return {menu}
end})
