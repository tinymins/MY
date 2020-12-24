--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : °ó¶¨ JX3BOX
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
local PLUGIN_NAME = 'MY_JBBind'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------
local D = {}
local O = {
	uid = nil,
	pending = false,
}

function D.FetchBindStatus(resolve, reject)
	if IsNil(O.uid) then
		local szURL = 'https://pull.j3cx.com/role/query?'
			.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
				jx3id = AnsiToUTF8(LIB.GetClientUUID()),
				lang = AnsiToUTF8(LIB.GetLang()),
			}, '7228b445-14cb-465f-8dd2-019cbbbb2ce7')))
		O.pending = true
		LIB.Ajax({
			driver = 'auto', mode = 'auto', method = 'auto',
			url = szURL,
			charset = 'utf8',
			success = function(szHTML)
				O.pending = false
				local res = LIB.JsonDecode(szHTML)
				if Get(res, {'code'}) == 0 then
					O.uid = Get(res, {'data', 'uid'})
					SafeCall(resolve, O.uid)
				else
					SafeCall(reject)
				end
			end,
			error = function()
				O.pending = false
				SafeCall(reject)
			end,
		})
	else
		SafeCall(resolve, O.uid)
	end
end

function D.Bind(szToken, resolve, reject)
	local dwID = UI_GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		LIB.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	local me = GetClientPlayer()
	local szURL = 'https://push.j3cx.com/role/bind?'
		.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
			token = AnsiToUTF8(szToken),
			cguid = LIB.GetClientGUID(),
			jx3id = AnsiToUTF8(LIB.GetClientUUID()),
			server = AnsiToUTF8(LIB.GetRealServer(2)),
			id = AnsiToUTF8(dwID),
			name = AnsiToUTF8(LIB.GetUserRoleName()),
			mount = me.GetKungfuMount().dwMountType,
			type = me.nRoleType,
			lang = AnsiToUTF8(LIB.GetLang()),
		}, '7228b445-14cb-465f-8dd2-019cbbbb2ce7')))
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = szURL,
		charset = 'utf8',
		success = function(szHTML)
			local res = LIB.JsonDecode(szHTML)
			if Get(res, {'code'}) == 0 then
				O.uid = nil
				SafeCall(resolve, O.uid)
			else
				LIB.Alert((Get(res, {'msg'}, _L['Request failed.'])))
				SafeCall(reject)
			end
		end,
	})
end

function D.Unbind(resolve, reject)
	local szURL = 'https://push.j3cx.com/role/unbind?'
		.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
			jx3id = AnsiToUTF8(LIB.GetClientUUID()),
			lang = AnsiToUTF8(LIB.GetLang()),
		}, '7228b445-14cb-465f-8dd2-019cbbbb2ce7')))
	LIB.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = szURL,
		charset = 'utf8',
		success = function(szHTML)
			local res = LIB.JsonDecode(szHTML)
			if Get(res, {'code'}) == 0 then
				O.uid = nil
				SafeCall(resolve)
			else
				LIB.Alert((Get(res, {'msg'}, _L['Request failed.'])))
				SafeCall(reject)
			end
		end,
	})
end

local PS = { nPriority = 0, bWelcome = true }
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 30
	local nX, nY = X, Y
	local W, H = ui:Size()

	local uiCCStatus, uiBtnCCStatus
	local function UpdateUI()
		if O.pending then
			uiCCStatus:Text(_L['Loading'])
			uiBtnCCStatus:Text(_L['Click fetch'])
		elseif IsNil(O.uid) then
			uiCCStatus:Text(_L['Unknown'])
			uiBtnCCStatus:Text(_L['Click fetch'])
		elseif IsEmpty(O.uid) then
			uiCCStatus:Text(_L['Not bind'])
			uiBtnCCStatus:Text(_L['Click bind'])
		else
			uiCCStatus:Text(_L('Binded (ID: %s)', O.uid))
			uiBtnCCStatus:Text(_L['Click unbind'])
		end
		uiCCStatus:AutoWidth()
		uiBtnCCStatus:Enable(not O.pending)
		uiBtnCCStatus:Left(uiCCStatus:Left() + uiCCStatus:Width() + 20)
	end

	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Character Certification'], font = 27 }):Height() + 5
	nX = X + 10
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L('Current character: %s', GetUserRoleName()) }):Width() + 20
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Status: '] }):Width()
	uiCCStatus = ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Loading'] })
	nX = nX + uiCCStatus:Width()
	uiBtnCCStatus = ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonstyle = 2, text = _L['Bind'], enable = false,
		onclick = function()
			if IsEmpty(O.uid) then
				GetUserInput(_L['Please input certification code:'], function(szText)
					uiBtnCCStatus:Enable(false)
					D.Bind(
						szText,
						function()
							LIB.Alert(_L['Bind succeed!'])
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end,
						function()
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end)
				end)
			elseif LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				LIB.Topmsg(_L['Please unlock equip lock first!'], CONSTANT.MSG_THEME.ERROR)
			else
				LIB.Confirm(_L['Sure to unbind character certification?'], function()
					uiBtnCCStatus:Enable(false)
					D.Unbind(
						function()
							LIB.Alert(_L['Unbind succeed!'])
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end,
						function()
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end)
				end)
			end
		end,
	})
	nX = nX + uiBtnCCStatus:Width()

	UpdateUI()
	D.FetchBindStatus(UpdateUI, UpdateUI)

	nX = X
	nY = nY + 20
	-- tips
	nY = nY + 28
	ui:Append('Text', { text = _L['Tips'], x = X, y = nY, font = 27 })
	nX = X + 10
	nY = nY + 35

	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		r = 255, g = 255, b = 0,
		text = _L['1. Character certification is the most important thing you should do before JX3BOX pve ranking.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		r = 255, g = 255, b = 0,
		text = _L['2. Only with the "share" checkbox above checked and character certificated, you can join the ranking.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		r = 255, g = 255, b = 0,
		text = _L['3. Character certification will bind role with JX3BOX account, and will upload some information.'],
		}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		r = 255, g = 255, b = 0,
		text = _L['4. Checked the "share" checkbox, will upload team member info while killing dungeon bosses.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		r = 255, g = 255, b = 0,
		text = _L['5. For further information, please visit JX3BOX.'],
	}):AutoHeight():Height() + 3

	nX = X
	nY = nY + 20
end
LIB.RegisterPanel(_L['JX3BOX'], 'MY_JBBind', _L['MY_JBBind'], 5962, PS)
