--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 好友、帮会成员脚下姓名显示
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_FooterTip', _L['MY_Toolbox'], {
	bFriend = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_FooterTip'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bFriendNav = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_FooterTip'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTongMember = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_FooterTip'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTongMemberNav = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_FooterTip'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

function D.Apply()
	-- 好友高亮
	if Navigator_Remove then
		Navigator_Remove('MY_FRIEND_TIP')
	end
	if O.bFriend and not LIB.IsInShieldedMap() then
		local hShaList = UI.GetShadowHandle('MY_FriendHeadTip')
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID)
			if LIB.IsInShieldedMap() then
				return
			end
			local tar = GetPlayer(dwID)
			local me = GetClientPlayer()
			if not tar or not me
			or LIB.IsIsolated(tar) ~= LIB.IsIsolated(me) then
				return
			end
			local p = LIB.GetFriend(dwID)
			if p then
				if O.bFriendNav and Navigator_SetID then
					Navigator_SetID('MY_FRIEND_TIP.' .. dwID, TARGET.PLAYER, dwID, p.name)
				else
					local sha = hShaList:Lookup(tostring(dwID))
					if not sha then
						hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
						sha = hShaList:Lookup(tostring(dwID))
					end
					local r, g, b, a = 255,255,255,255
					local szTip = '>> ' .. p.name .. ' <<'
					sha:ClearTriangleFanPoint()
					sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
					sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
					sha:Show()
				end
			end
		end
		local function OnPlayerLeave(dwID)
			if LIB.IsInShieldedMap() then
				return
			end
			if O.bFriendNav and Navigator_Remove then
				Navigator_Remove('MY_FRIEND_TIP.' .. dwID)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if sha then
					sha:Hide()
					insert(hShaList.freeShadows, sha)
				end
			end
		end
		local function RescanNearby()
			if LIB.IsInShieldedMap() then
				return
			end
			for _, p in ipairs(LIB.GetNearPlayer()) do
				OnPlayerEnter(p.dwID)
			end
		end
		RescanNearby()
		LIB.RegisterEvent('ON_ISOLATED.MY_FRIEND_TIP', function(event)
			-- dwCharacterID, nIsolated
			local me = GetClientPlayer()
			if arg0 == UI_GetClientPlayerID() then
				for _, p in ipairs(LIB.GetNearPlayer()) do
					if LIB.IsIsolated(p) == LIB.IsIsolated(me) then
						OnPlayerEnter(p.dwID)
					else
						OnPlayerLeave(p.dwID)
					end
				end
			else
				local tar = GetPlayer(arg0)
				if tar then
					if LIB.IsIsolated(tar) == LIB.IsIsolated(me) then
						OnPlayerEnter(arg0)
					else
						OnPlayerLeave(arg0)
					end
				end
			end
		end)
		LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_FRIEND_TIP', function(event) OnPlayerEnter(arg0) end)
		LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_FRIEND_TIP', function(event) OnPlayerLeave(arg0) end)
		LIB.RegisterEvent('DELETE_FELLOWSHIP.MY_FRIEND_TIP', function(event) RescanNearby() end)
		LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE.MY_FRIEND_TIP', function(event) RescanNearby() end)
		LIB.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE.MY_FRIEND_TIP', function(event) RescanNearby() end)
	else
		LIB.RegisterEvent('ON_ISOLATED.MY_FRIEND_TIP', false)
		LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_FRIEND_TIP', false)
		LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_FRIEND_TIP', false)
		LIB.RegisterEvent('DELETE_FELLOWSHIP.MY_FRIEND_TIP', false)
		LIB.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE.MY_FRIEND_TIP', false)
		LIB.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE.MY_FRIEND_TIP', false)
		UI.GetShadowHandle('MY_FriendHeadTip'):Hide()
	end
	-- 帮会成员高亮
	if Navigator_Remove then
		Navigator_Remove('MY_GUILDMEMBER_TIP')
	end
	if O.bTongMember and not LIB.IsInShieldedMap() then
		local hShaList = UI.GetShadowHandle('MY_TongMemberHeadTip')
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID, nRetryCount)
			if LIB.IsInShieldedMap() then
				return
			end
			nRetryCount = nRetryCount or 0
			if nRetryCount > 5 then
				return
			end
			local tar = GetPlayer(dwID)
			local me = GetClientPlayer()
			if not tar or not me
			or me.dwTongID == 0
			or me.dwID == tar.dwID
			or tar.dwTongID ~= me.dwTongID
			or LIB.IsIsolated(tar) ~= LIB.IsIsolated(me) then
				return
			end
			if tar.szName == '' then
				LIB.DelayCall(500, function() OnPlayerEnter(dwID, nRetryCount + 1) end)
				return
			end
			if O.bTongMemberNav and Navigator_SetID then
				Navigator_SetID('MY_GUILDMEMBER_TIP.' .. dwID, TARGET.PLAYER, dwID, tar.szName)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if not sha then
					hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
					sha = hShaList:Lookup(tostring(dwID))
				end
				local r, g, b, a = 255,255,255,255
				local szTip = '> ' .. tar.szName .. ' <'
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
				sha:Show()
			end
		end
		local function OnPlayerLeave(dwID)
			if LIB.IsInShieldedMap() then
				return
			end
			if O.bTongMemberNav and Navigator_Remove then
				Navigator_Remove('MY_GUILDMEMBER_TIP.' .. dwID)
			else
				local sha = hShaList:IsValid() and hShaList:Lookup(tostring(dwID))
				if sha then
					sha:Hide()
					insert(hShaList.freeShadows, sha)
				end
			end
		end
		for _, p in ipairs(LIB.GetNearPlayer()) do
			if LIB.IsInShieldedMap() then
				return
			end
			OnPlayerEnter(p.dwID)
		end
		LIB.RegisterEvent('ON_ISOLATED.MY_GUILDMEMBER_TIP', function(event)
			-- dwCharacterID, nIsolated
			local me = GetClientPlayer()
			if arg0 == UI_GetClientPlayerID() then
				for _, p in ipairs(LIB.GetNearPlayer()) do
					if LIB.IsIsolated(p) == LIB.IsIsolated(me) then
						OnPlayerEnter(p.dwID)
					else
						OnPlayerLeave(p.dwID)
					end
				end
			else
				local tar = GetPlayer(arg0)
				if tar then
					if LIB.IsIsolated(tar) == LIB.IsIsolated(me) then
						OnPlayerEnter(arg0)
					else
						OnPlayerLeave(arg0)
					end
				end
			end
		end)
		LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_GUILDMEMBER_TIP', function(event) OnPlayerEnter(arg0) end)
		LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_GUILDMEMBER_TIP', function(event) OnPlayerLeave(arg0) end)
	else
		LIB.RegisterEvent('ON_ISOLATED.MY_GUILDMEMBER_TIP', false)
		LIB.RegisterEvent('PLAYER_ENTER_SCENE.MY_GUILDMEMBER_TIP', false)
		LIB.RegisterEvent('PLAYER_LEAVE_SCENE.MY_GUILDMEMBER_TIP', false)
		UI.GetShadowHandle('MY_TongMemberHeadTip'):Hide()
	end
end
LIB.RegisterEvent('LOADING_ENDING.MY_FooterTip', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	-- 好友高亮
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 180,
		text = _L['Friend headtop tips'],
		checked = MY_FooterTip.bFriend,
		oncheck = function(bCheck)
			MY_FooterTip.bFriend = not MY_FooterTip.bFriend
		end,
	})
	ui:Append('WndCheckBox', {
		x = x + 180, y = y, w = 180,
		text = _L['Friend headtop tips nav'],
		checked = MY_FooterTip.bFriendNav,
		oncheck = function(bCheck)
			MY_FooterTip.bFriendNav = not MY_FooterTip.bFriendNav
		end,
		autoenable = function() return MY_FooterTip.bFriend end,
	})
	y = y + deltaY

	-- 帮会高亮
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 180,
		text = _L['Tong member headtop tips'],
		checked = MY_FooterTip.bTongMember,
		oncheck = function(bCheck)
			MY_FooterTip.bTongMember = not MY_FooterTip.bTongMember
		end,
	})
	ui:Append('WndCheckBox', {
		x = x + 180, y = y, w = 180,
		text = _L['Tong member headtop tips nav'],
		checked = MY_FooterTip.bTongMemberNav,
		oncheck = function(bCheck)
			MY_FooterTip.bTongMemberNav = not MY_FooterTip.bTongMemberNav
		end,
		autoenable = function() return MY_FooterTip.bTongMember end,
	})
	y = y + deltaY
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bFriend = true,
				bFriendNav = true,
				bTongMember = true,
				bTongMemberNav = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bFriend = true,
				bFriendNav = true,
				bTongMember = true,
				bTongMemberNav = true,
			},
			triggers = {
				bFriend = D.Apply,
				bFriendNav = D.Apply,
				bTongMember = D.Apply,
				bTongMemberNav = D.Apply,
			},
			root = O,
		},
	},
}
MY_FooterTip = LIB.CreateModule(settings)
end
