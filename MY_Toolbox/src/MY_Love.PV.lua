--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������Ե���ý���
-- @author   : ���� @˫���� @׷����Ӱ
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
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Love'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {
	FormatLoverString = MY_Love.FormatLoverString,
	GetPlayerInfo = MY_Love.GetPlayerInfo,
	RequestOtherLover = MY_Love.RequestOtherLover,
	GetOtherLover = MY_Love.GetOtherLover,
}
local O = {
	tActiveLove = {},
	tID2Name = {},
}

-- ���������Ե����
function D.PvRequestOtherLover(frame)
	local nX, nY = frame:GetAbsPos()
	local nW, nH = frame:GetSize()
	local pageset = frame:Lookup('Page_Main')
	return D.RequestOtherLover(pageset.dwPlayer, nX + nW / 2, nY + nH / 3, function() return not Station.Lookup('Normal/PlayerView/Page_Main') end)
end

-- ������Ե�����Ϣ
function D.UpdatePage()
	local p = Station.Lookup('Normal/PlayerView/Page_Main/Page_Love')
	if not p then
		return
	end
	local tar = D.GetPlayerInfo(p:GetParent().dwPlayer)
	if not tar then
		return p:GetRoot():Hide()
	end
	local h, t = p:Lookup('', ''), D.GetOtherLover(tar.dwID)
	local bNoData, dwID, szName, dwAvatar, szSign, dwForceID, nRoleType, nLoverType, nLoverTime, szLoverTitle = not t
	if t then
		dwID = t.dwID
		szName = t.szName
		dwAvatar = t.dwAvatar
		szSign = t.szSign
		dwForceID = t.dwForceID
		nRoleType = t.nRoleType
		nLoverType = t.nLoverType
		nLoverTime = t.nLoverTime
		szLoverTitle = t.szLoverTitle
	end
	h:Lookup('Text_LTitle'):SetText(_L('%s\'s lover', tar.szName))
	-- lover
	local txt = h:Lookup('Text_Lover')
	if bNoData then
		txt:SetText(_L['...Unknown...'])
	else
		txt:SetText(szName or _L['...Loading...'])
	end
	txt.szPlayer = szName
	-- lover title
	local ttl = h:Lookup('Text_LoverTitle')
	if bNoData or IsEmpty(szLoverTitle) then
		ttl:SetText('')
	else
		ttl:SetFontColor(255, 128, 255)
		ttl:SetText('<' .. szLoverTitle .. '>')
	end
	-- lover info
	local inf = h:Lookup('Text_LoverInfo')
	if nLoverType and nLoverTime and nLoverTime > 0 then
		inf:SetText(D.FormatLoverString('{$type}   {$time}', { nLoverType = nLoverType, nLoverTime = nLoverTime }))
	else
		inf:SetText('')
	end
	-- avatar
	local szFile, nFrame, bAnimate = LIB.GetPlayerAvatar(dwForceID, nRoleType, dwAvatar)
	local img, ani = h:Lookup('Image_Lover'), h:Lookup('Animate_Lover')
	if IsEmpty(dwID) or IsEmpty(szFile) then
		img:Hide()
		ani:Hide()
		txt:SetRelPos(42, 92)
		txt:SetSize(300, 25)
		txt:SetHAlign(1)
	else
		if bAnimate then
			ani:SetAnimate(szFile, nFrame)
			--ani:SetAnimateType(ANIMATE.FLIP_HORIZONTAL)
			ani:Show()
			img:Hide()
		else
			if nFrame < 0 then
				img:FromTextureFile(szFile)
			else
				img:FromUITex(szFile, nFrame)
			end
			if nFrame == -2 then
				img:SetImageType(IMAGE.NORMAL)
			else
				img:SetImageType(IMAGE.FLIP_HORIZONTAL)
			end
			ani:Hide()
			img:Show()
		end
		if bNoData or IsEmpty(szLoverTitle) then
			txt:SetRelPos(130, 92)
			inf:SetRelPos(130, 115)
		else
			txt:SetRelPos(130, 82)
			ttl:SetRelPos(130, 105)
			inf:SetRelPos(130, 128)
		end
		txt:SetSize(200, 25)
		txt:SetHAlign(0)
	end
	ani.szPlayer = szName
	img.szPlayer = szName
	-- sign title
	h:Lookup('Text_SignTTL'):SetText(bNoData and '' or _L('%s\'s Love signature:', tar.szName))
	-- sign
	if bNoData then
		szSign = _L['No peer lover data yet, you must request first.']
	elseif not szSign then
		szSign = _L['If it is always loading, the target may not install plugin or turn on quiet mode, strongly recommend to query after team up.']
	elseif szSign == '' then
		szSign = _L['This guy is very lazy, nothing left!']
	end
	h:Lookup('Text_Sign'):SetText(szSign)
	-- btn
	local txt = p:Lookup('Btn_LoveYou'):Lookup('', 'Text_LoveYou')
	if bNoData then
		txt:SetText(_L['Request lover data'])
	elseif tar.nGender == 2 then
		txt:SetText(_L['Strike up her'])
	else
		txt:SetText(_L['Strike up him'])
	end
	h:FormatAllItemPos()
end
LIB.RegisterEvent('MY_LOVE_OTHER_UPDATE', D.UpdatePage)

-- �鿴����װ������Ե
function D.HookPlayerViewPanel()
	local mPage = Station.Lookup('Normal/PlayerView/Page_Main')
	if not mPage then
		return
	end
	local txtName = mPage:Lookup('Page_Battle', 'Text_PlayerName')
	if not txtName then
		return
	end
	local szName = txtName:GetText()
	local dwID = O.tID2Name[szName]
	local bHook = MY_Love.bHookPlayerView and dwID and not IsRemotePlayer(dwID) and not MY_Love.IsShielded()
	-- attach page
	if bHook then
		if not mPage.bMYLoved then
			local frame = Wnd.OpenWindow(PLUGIN_ROOT .. '\\ui\\MY_Love.ini', 'MY_Love')
			local pageset = frame:Lookup('Page_Main')
			local checkbox = pageset:Lookup('CheckBox_Love')
			local page = pageset:Lookup('Page_Love')
			checkbox:ChangeRelation(mPage, true, true)
			page:ChangeRelation(mPage, true, true)
			Wnd.CloseWindow(frame)
			checkbox:SetRelPos(270, 510)
			page:SetRelPos(0, 0)
			mPage:AddPage(page, checkbox)
			checkbox:Show()
			mPage.bMYLoved = true
			-- events
			mPage.OnActivePage = function()
				if this:GetActivePage():GetName() == 'Page_Love' then
					D.UpdatePage()
					D.PvRequestOtherLover(this:GetRoot())
				end
				PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
			end
			page:Lookup('Btn_LoveYou').OnLButtonClick = function()
				local mp = this:GetParent():GetParent()
				if D.GetOtherLover(mp.dwPlayer) then
					local tar = D.GetPlayerInfo(mp.dwPlayer)
					if tar then
						LIB.Talk(tar.szName, MY_Love.szJabber)
					end
				else
					D.PvRequestOtherLover(this:GetRoot())
				end
			end
			page:Lookup('Btn_LoveYou').OnRButtonClick = function()
				local mp = this:GetParent():GetParent()
				local tar = D.GetPlayerInfo(mp.dwPlayer)
				if tar then
					local m0, me = {}, GetClientPlayer()
					InsertInviteTeamMenu(m0, tar.szName)
					if me.IsInParty() and me.dwID == GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) then
						InsertMarkMenu(m0, tar.dwID)
					end
					if me.IsInParty() and me.IsPlayerInMyParty(tar.dwID) then
						InsertTeammateLeaderMenu(m0, tar.dwID)
					end
					if #m0 > 0 then
						insert(m0, { bDevide = true })
					end
					InsertPlayerCommonMenu(m0, tar.dwID, tar.szName)
					PopupMenu(m0)
				end
			end
			page:Lookup('', 'Image_Lover').OnItemRButtonDown = function()
				if this.szPlayer then
					local m0 = {}
					InsertPlayerCommonMenu(m0, 0, this.szPlayer)
					PopupMenu(m0)
				end
			end
			page:Lookup('', 'Text_Lover').OnItemRButtonDown = page:Lookup('', 'Image_Lover').OnItemRButtonDown
			page:Lookup('', 'Animate_Lover').OnItemRButtonDown = page:Lookup('', 'Image_Lover').OnItemRButtonDown
			page:Lookup('', 'Text_LTitle'):SetText(_L['Lover'])
			page:Lookup('', 'Text_SignTTL'):SetText(_L['Love signature:'])
			page:Lookup('', 'Text_Lover'):SetFontColor(255, 128, 255)
			checkbox:Lookup('', 'Text_LoveCaptical'):SetText(_L['Lover'])
		end
		-- update page
		mPage.dwPlayer = dwID
		-- active page
		if O.tActiveLove[dwID] then
			O.tActiveLove[dwID] = nil
			mPage:ActivePage('Page_Love')
		end
	elseif not bHook and mPage.bMYLoved then
		local frame = Wnd.OpenWindow(PLUGIN_ROOT .. '\\ui\\MY_Love.ini', 'MY_Love')
		local pageset = frame:Lookup('Page_Main')
		local checkbox = mPage:Lookup('CheckBox_Love')
		local page = mPage:Lookup('Page_Love')
		pageset:AddPage(page, checkbox)
		checkbox:ChangeRelation(pageset, true, true)
		page:ChangeRelation(pageset, true, true)
		Wnd.CloseWindow(frame)
		mPage.dwPlayer = nil
		mPage.bMYLoved = nil
	end
end

function D.OnPeekOtherPlayer()
	if arg0 ~= 1 or IsRemotePlayer(arg1) then
		return
	end
	local tar = GetPlayer(arg1)
	if not tar then
		return
	end
	O.tID2Name[tar.szName] = arg1
	D.HookPlayerViewPanel()
end
LIB.RegisterEvent('PEEK_OTHER_PLAYER.MY_Love__PV', D.OnPeekOtherPlayer)

function D.OnActiveLoveChange()
	O.tActiveLove[arg0] = arg1 and true or nil
end
LIB.RegisterEvent('MY_LOVE_PV_ACTIVE_CHANGE', D.OnActiveLoveChange)

function D.OnPVHookChange()
	D.HookPlayerViewPanel()
end
LIB.RegisterEvent('MY_LOVE_PV_HOOK', D.OnPVHookChange)

-- view other lover by dwID
function D.PeekOther(dwID)
	MY_Love.bHookPlayerView = true
	O.tActiveLove[dwID] = true
	ViewInviteToPlayer(dwID)
end

-- add target menu
do
local function onMenu(dwTarType, dwTarID)
	if MY_Love.IsShielded() then
		return
	end
	if dwTarType ~= TARGET.PLAYER or dwTarID == UI_GetClientPlayerID() or IsRemotePlayer(dwTarID) then
		return
	end
	return {{
		szOption = _L['View love info'],
		fnAction = function() D.PeekOther(dwTarID) end
	}}
end
LIB.RegisterTargetAddonMenu('MY_Love', onMenu)
end

-- close player view when reload
LIB.RegisterReload('MY_Love', function() Wnd.CloseWindow('PlayerView') end)