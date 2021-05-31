--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÁÄÌì¸¨Öú
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatEmotion'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local D = {}
local O = {
	bFixSize = false,
	nSize = 25,
}
RegisterCustomData('MY_ChatEmotion.bFixSize')
RegisterCustomData('MY_ChatEmotion.nSize')

LIB.HookChatPanel('BEFORE.MY_ChatEmotion', function(h, szMsg, ...)
	if O.bFixSize then
		local aXMLNode = LIB.XMLDecode(szMsg)
		if aXMLNode then
			for _, node in ipairs(aXMLNode) do
				local szType = LIB.XMLGetNodeType(node)
				local szName = LIB.XMLGetNodeData(node, 'name')
				if (szType == 'animate' or szType == 'image')
				and szName and szName:sub(1, 8) == 'emotion_' then
					LIB.XMLSetNodeData(node, 'w', O.nSize)
					LIB.XMLSetNodeData(node, 'h', O.nSize)
				end
			end
			szMsg = LIB.XMLEncode(aXMLNode)
		end
	end
	return szMsg
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, lineHeight)
	x = X
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['Resize emotion'],
		checked = MY_ChatEmotion.bFixSize,
		oncheck = function(bChecked)
			MY_ChatEmotion.bFixSize = bChecked
		end,
	}):AutoWidth():Width() + 5
	ui:Append('WndTrackbar', {
		x = x, y = y, w = 100, h = 25,
		value = MY_ChatEmotion.nSize,
		range = {1, 300},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(v) return _L('Size: %d', v) end,
		onchange = function(val)
			MY_ChatEmotion.nSize = val
		end,
		autoenable = function() return MY_ChatEmotion.bFixSize end,
	})
	y = y + lineHeight

	return x, y
end

--------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------
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
				bFixSize = true,
				nSize = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bFixSize = true,
				nSize = true,
			},
			root = O,
		},
	},
}
MY_ChatEmotion = LIB.GeneGlobalNS(settings)
end
