--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 快捷入团
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^6.0.0') then
	return
end
--------------------------------------------------------------------------
local O = LIB.CreateUserSettingsModule('MY_JBTeamSnapshot', _L['Raid'], {
	szTeam = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = Schema.String,
		xDefaultValue = '',
	},
})
local D = {}

function D.CreateSnapshot()
	local dwID = UI_GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		LIB.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	if IsEmpty(O.szTeam) then
		LIB.ShowPanel()
		LIB.SwitchTab('MY_JX3BOX')
		return LIB.Alert(_L['Please input team name/id.'])
	end
	local aTeammate = {}
	local team = LIB.IsInParty() and GetClientTeam()
	if team then
		for _, dwTarID in ipairs(team.GetTeamMemberList()) do
			local info = team.GetMemberInfo(dwTarID)
			local guid = LIB.GetPlayerGUID(dwTarID) or 0
			insert(aTeammate, info.szName .. ',' .. dwID .. ',' .. guid .. ',' .. info.dwMountKungfuID)
		end
	end
	local me = GetClientPlayer()
	local szURL = 'https://push.j3cx.com/team/snapshot?'
		.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			team = AnsiToUTF8(O.szTeam),
			cguid = LIB.GetClientGUID(),
			jx3id = AnsiToUTF8(LIB.GetClientUUID()),
			server = AnsiToUTF8(LIB.GetRealServer(2)),
			teammate = AnsiToUTF8(concat(aTeammate, ';')),
		}, '361aaabd-b494-4c28-ad8b-e9c297bb4739')))
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = szURL,
		charset = 'utf8',
		success = function(szHTML)
			local res = LIB.JsonDecode(szHTML)
			if Get(res, {'code'}) == 0 then
				LIB.Alert(_L['Upload snapshot succeed!'])
			else
				LIB.Alert(_L['Upload snapshot failed!'] .. LIB.ReplaceSensitiveWord(Get(res, {'msg'}, _L['Request failed.'])))
			end
		end,
		error = function()
			LIB.Alert(_L['Upload snapshot failed!'])
		end,
	})
end

function D.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	-- 快捷入团
	nX = X
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Team Snapshot'], font = 27 }):Height() + 2

	nX = X + 10
	local bLoading
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Team name/id:'] }):Width()
	ui:Append('Text', {
		x = nX, y = nY + LH, h = 25,
		text = _L['(Input: Team@Server:Passcode)'],
		color = { 172, 172, 172 },
	}):AutoWidth()
	nX = nX + ui:Append('WndEditBox', {
		x = nX, y = nY + 2, w = 300, h = 25,
		text = O.szTeam,
		onchange = function(szText)
			O.szTeam = szText
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonstyle = 'FLAT', text = _L['Upload Snapshot'],
		onclick = function()
			D.CreateSnapshot()
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButtonBox', {
		x = nX, y = nY + 5, w = 130, h = 20,
		color = { 234, 235, 185 },
		buttonstyle = 'LINK',
		text = _L['>> View Snapshots <<'],
		onclick = function()
			LIB.OpenBrowser('https://page.j3cx.com/jx3box/team/snapshot')
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + LH
	return nX, nY, nLFY
end

-- Global exports
do
local settings = {
	name = 'MY_JBTeamSnapshot',
	exports = {
		{
			fields = {
				'CreateSnapshot',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'szTeam',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'szTeam',
			},
			root = O,
		},
	},
}
MY_JBTeamSnapshot = LIB.CreateModule(settings)
end
