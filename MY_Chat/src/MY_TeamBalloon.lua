--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌìÅÝÅÝ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall = LIB.Call, LIB.XpCall, LIB.SafeCall
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamBalloon'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local INI_PATH = PACKET_INFO.ROOT .. 'MY_Chat/ui/MY_TeamBalloon.ini'
local DISPLAY_TIME = 5000
local ANIMATE_SHOW_TIME = 500
local ANIMATE_HIDE_TIME = 500
MY_TeamBalloon = { bEnable = true }
RegisterCustomData('MY_TeamBalloon.bEnable')

local function AppendBalloon(hFrame, dwID, szMsg)
	local hTotal = hFrame:Lookup('', '')
	local hBalloon = hTotal:Lookup('Balloon_' .. dwID)
	if not hBalloon then
		hBalloon = hTotal:AppendItemFromIni(INI_PATH, 'Handle_Balloon', 'Balloon_' .. dwID)
		hBalloon.dwID = dwID
	end
	hBalloon.nTime = GetTime()
	local hContent = hBalloon:Lookup('Handle_Content')
	hContent:Show()
	hContent:Clear()
	hContent:SetSize(300, 131)
	hContent:AppendItemFromString(szMsg)
	hContent:FormatAllItemPos()
	hContent:SetSizeByAllItemSize()

	-- Adjust balloon size
	local w, h = hContent:GetSize()
	w, h = w + 20, h + 20
	local image1 = hBalloon:Lookup('Image_Bg1')
	image1:SetSize(w, h)
	local image2 = hBalloon:Lookup('Image_Bg2')
	image2:SetRelPos(min(w - 16 - 8, 32), h - 4)
	hBalloon:SetSize(10000, 10000)
	hBalloon:FormatAllItemPos()
	hBalloon:SetSizeByAllItemSize()

	-- Show balloon
	local hWnd = Station.Lookup('Normal/Teammate')
	local hContent = hBalloon:Lookup('Handle_Content')
	local x, y, w, h, _
	if hWnd and hWnd:IsVisible() then
		local hTotal = hWnd:Lookup('', '')
		local nCount = hTotal:GetItemCount()
		for i = 0, nCount - 1 do
			local hI = hTotal:Lookup(i)
			if hI.dwID == dwID then
				w, h = hContent:GetSize()
				x, y = hI:GetAbsPos()
				x, y = x + 205, y - h - 2
			end
		end
	elseif MY_CataclysmParty and MY_CataclysmParty.GetMemberHandle then
		local hTotal = MY_CataclysmParty.GetMemberHandle(dwID)
		if hTotal then
			_, h = hContent:GetSize()
			w, _ = hTotal:GetSize()
			x, y = hTotal:GetAbsPos()
			x, y = x + w, y - h - 2
		end
	end
	if x and y then
		hBalloon:SetRelPos(x, y)
		hBalloon:SetAbsPos(x, y)
	end
	hBalloon:SetAlpha(0)
	hFrame:BringToTop()
end


local function OnSay(hFrame, szMsg, dwID, nChannel)
	local player = GetClientPlayer()
	if player and player.dwID ~= dwID and (
		nChannel == PLAYER_TALK_CHANNEL.TEAM or
		nChannel == PLAYER_TALK_CHANNEL.RAID
	) and player.IsInParty() then
		local hTeam = GetClientTeam()
		if not hTeam then return end
		if hTeam.nGroupNum > 1 then
			return
		end
		local hGroup = hTeam.GetGroupInfo(0)
		for k, v in pairs(hGroup.MemberList) do
			if v == dwID then
				AppendBalloon(hFrame, dwID, szMsg, false)
			end
		end
	end
end

function MY_TeamBalloon.OnFrameCreate()
	this:RegisterEvent('PLAYER_SAY')
end

function MY_TeamBalloon.OnEvent(event)
	if event == 'PLAYER_SAY' then
		OnSay(this, arg0, arg1, arg2)
	end
end

function MY_TeamBalloon.OnFrameBreathe()
	local hTotal = this:Lookup('', '')
	for i = 0, hTotal:GetItemCount() - 1 do
		local hBalloon = hTotal:Lookup(i)
		if hBalloon and hBalloon.nTime then
			local nTick = GetTime() - hBalloon.nTime
			if nTick <= ANIMATE_SHOW_TIME then
				hBalloon:SetAlpha(nTick / ANIMATE_SHOW_TIME * 255)
			elseif nTick >= ANIMATE_SHOW_TIME + DISPLAY_TIME + ANIMATE_HIDE_TIME then
				hTotal:RemoveItem(hBalloon)
			elseif nTick >= ANIMATE_SHOW_TIME + DISPLAY_TIME then
				hBalloon:SetAlpha((1 - (nTick - ANIMATE_SHOW_TIME - DISPLAY_TIME) / ANIMATE_HIDE_TIME) * 255)
			end
		end
	end
end

function MY_TeamBalloon.Enable(...)
	if select('#', ...) == 1 then
		MY_TeamBalloon.bEnable = not not ...
		if MY_TeamBalloon.bEnable then
			Wnd.OpenWindow(INI_PATH, 'MY_TeamBalloon')
		else
			Wnd.CloseWindow('MY_TeamBalloon')
		end
	else
		return MY_TeamBalloon.bEnable
	end
end

do
local function Init()
	MY_TeamBalloon.Enable(MY_TeamBalloon.bEnable)
end
LIB.RegisterInit('MY_TeamBalloon', Init)
end
