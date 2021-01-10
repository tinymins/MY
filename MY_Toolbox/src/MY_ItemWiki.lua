--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��Ʒ�ٿƲ�ѯ
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false,
	nW = 850,
	nH = 610,
}
RegisterCustomData('MY_ItemWiki.bEnable')
RegisterCustomData('MY_ItemWiki.nW')
RegisterCustomData('MY_ItemWiki.nH')

function D.OnWebSizeChange()
	O.nW, O.nH = this:GetSize()
end

function D.Open(dwTabType, dwTabIndex, nBookID)
	if nBookID < 0 then
		nBookID = nil
	end
	local szName = LIB.GetObjectName('ITEM_INFO', dwTabType, dwTabIndex, nBookID)
	if not szName then
		return
	end
	local szURL = 'https://page.j3cx.com/item/' .. concat({dwTabType, dwTabIndex, nBookID}, '/') .. '?'
		.. LIB.EncodePostData(LIB.UrlEncode({
			lang = AnsiToUTF8(LIB.GetLang()),
			player = AnsiToUTF8(GetUserRoleName()),
		}))
	local szKey = 'ItemWiki_' .. concat({dwTabType, dwTabIndex, nBookID}, '_')
	local szTitle = szName
	szKey = MY_Web.Open(szURL, {
		key = szKey,
		title = szTitle,
		w = O.nW, h = O.nH,
	})
	UI(MY_Web.GetFrame(szKey)):Size(D.OnWebSizeChange)
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Hold SHIFT and r-click bag box to show item wiki'],
		checked = MY_ItemWiki.bEnable,
		oncheck = function(bChecked)
			MY_ItemWiki.bEnable = bChecked
		end,
	}):Width() + 5
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
				nW = true,
				nH = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				nW = true,
				nH = true,
			},
			root = O,
		},
	},
}
MY_ItemWiki = LIB.GeneGlobalNS(settings)
end

Box_AppendAddonMenu({function(box)
	if not IsElement(box) or box:GetType() ~= 'Box' or not O.bEnable then
		return
	end
	local _, dwBox, dwX = box:GetObjectData()
	if not dwBox or not dwX then
		return
	end
	local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
	if not item then
		return
	end
	local dwTabType = item.dwTabType
	local dwTabIndex = item.dwIndex
	local nBookID = item.nGenre == ITEM_GENRE.BOOK and item.nBookID or -1
	local menu = {{ szOption = _L['Item wiki'], fnAction = function() D.Open(dwTabType, dwTabIndex, nBookID) end }}
	if CONSTANT.FLOWERS_UIID[item.nUiId] then
		insert(menu, {
			szOption = _L['Lookup price'],
			fnAction = function()
				local me = GetClientPlayer()
				local line = LIB.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex })
				local szURL = 'https://page.j3cx.com/flowers/' .. concat({dwTabType, dwTabIndex}, '/') .. '?'
					.. LIB.EncodePostData(LIB.UrlEncode({
						lang = AnsiToUTF8(LIB.GetLang()),
						server = AnsiToUTF8(line and line.szCenterName or LIB.GetRealServer(2)),
						item = AnsiToUTF8(item.szName),
						tabtype = dwTabType, tabindex = dwTabIndex, uiid = item.nUiId, player = AnsiToUTF8(GetUserRoleName()),
					}))
				MY_Web.Open(szURL, {
					key = 'FlowerPrice_' .. concat({dwTabType, dwTabIndex}, '_'),
					title = item.szName,
					controls = false, w = 480, h = 640,
				})
			end,
		})
	end
	return menu
end})