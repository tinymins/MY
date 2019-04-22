--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌìÅÝÅÝ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local INI_PATH = LIB.GetAddonInfo().szRoot .. 'MY_Chat/ui/MY_TeamBalloon.ini'
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
	image2:SetRelPos(math.min(w - 16 - 8, 32), h - 4)
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

LIB.RegisterEvent('CUSTOM_DATA_LOADED.MY_TeamBalloon', function()
	if arg0 == 'Role' then
		MY_TeamBalloon.Enable(MY_TeamBalloon.Enable())
		LIB.RegisterEvent('CUSTOM_DATA_LOADED.MY_TeamBalloon')
	end
end)
