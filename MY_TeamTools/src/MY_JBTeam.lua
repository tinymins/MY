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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local D = {}
local O = {}

function D.ApplyAPI(szAction, szTeam, resolve, reject)
	local dwID = UI_GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		LIB.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	local me = GetClientPlayer()
	local szURL = 'https://push.j3cx.com/team/'
		.. (szAction == 'join' and 'join' or 'quit')
		.. '?'
		.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			team = AnsiToUTF8(szTeam),
			cguid = LIB.GetClientGUID(),
			jx3id = AnsiToUTF8(LIB.GetClientUUID()),
			server = AnsiToUTF8(LIB.GetRealServer(2)),
			id = AnsiToUTF8(dwID),
			name = AnsiToUTF8(LIB.GetUserRoleName()),
			mount = me.GetKungfuMount().dwMountType,
			body_type = me.nRoleType,
		}, szAction == 'join' and '3a0e8712-db2e-4dd5-a089-169fe2b4093b' or '26f76228-1f64-479a-a6d3-2cff034fcf08')))
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = szURL,
		charset = 'utf8',
		success = function(szHTML)
			local res = LIB.JsonDecode(szHTML)
			if Get(res, {'code'}) == 0 then
				SafeCall(resolve)
			else
				SafeCall(reject, LIB.ReplaceSensitiveWord(Get(res, {'msg'}, _L['Request failed.'])))
			end
		end,
	})
end

function D.OnPanelActivePartial(ui, X, Y, W, H, LH, nX, nY, nLFY)
	-- 快捷入团
	nX = X
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Quick team'], font = 27 }):Height() + 2

	nX = X + 10
	local bLoading
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Team name/id:'] }):Width()
	local uiInput = ui:Append('WndEditBox', { x = nX, y = nY + 2, w = 150, h = 25 })
	nX = nX + uiInput:Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonstyle = 'FLAT', text = _L['Apply join team'],
		onclick = function()
			if bLoading then
				return LIB.Systopmsg(_L['Processing, please wait.'])
			end
			local szTeam = uiInput:Text()
			if IsEmpty(szTeam) then
				return LIB.Alert(_L['Please input team name/id.'])
			end
			if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				return LIB.Topmsg(_L['Please unlock equip lock first!'], CONSTANT.MSG_THEME.ERROR)
			end
			LIB.Confirm(_L('Sure to apply join team %s?', szTeam), function()
				bLoading = true
				D.ApplyAPI(
					'join',
					szTeam,
					function()
						bLoading = false
						LIB.Alert(_L['Apply succeed!'])
						uiInput:Text('')
					end,
					function(szMsg)
						bLoading = false
						LIB.Alert(_L['Apply failed!'] .. szMsg)
					end)
			end)
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonstyle = 'FLAT', text = _L['Apply quit team'],
		onclick = function()
			if bLoading then
				return LIB.Systopmsg('Processing, please wait.')
			end
			local szTeam = uiInput:Text()
			if IsEmpty(szTeam) then
				return LIB.Alert(_L['Please input team name/id.'])
			end
			if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				return LIB.Topmsg(_L['Please unlock equip lock first!'], CONSTANT.MSG_THEME.ERROR)
			end
			LIB.Confirm(_L('Sure to apply quit team %s?', szTeam), function()
				bLoading = true
				D.ApplyAPI(
					'quit',
					szTeam,
					function()
						bLoading = false
						LIB.Alert(_L['Quit succeed!'])
						uiInput:Text('')
					end,
					function(szMsg)
						bLoading = false
						LIB.Alert(_L['Quit failed!'] .. szMsg)
					end)
			end)
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 5, w = 20, h = 20,
		buttonstyle = 'QUESTION',
		onclick = function()
			UI.OpenBrowser('https://page.j3cx.com/jx3box/team/about')
		end,
	}):Width()

	nLFY = nY + LH
	return nX, nY, nLFY
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
	},
}
MY_JBTeam = LIB.GeneGlobalNS(settings)
end
