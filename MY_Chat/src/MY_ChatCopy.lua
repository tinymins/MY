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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatCopy'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------
MY_ChatCopy = {}
MY_ChatCopy.bChatCopy = true
MY_ChatCopy.bChatTime = true
MY_ChatCopy.eChatTime = 'HOUR_MIN_SEC'
MY_ChatCopy.bChatCopyAlwaysShowMask = false
MY_ChatCopy.bChatCopyAlwaysWhite = false
MY_ChatCopy.bChatCopyNoCopySysmsg = false
RegisterCustomData('MY_ChatCopy.bChatCopy')
RegisterCustomData('MY_ChatCopy.bChatTime')
RegisterCustomData('MY_ChatCopy.eChatTime')
RegisterCustomData('MY_ChatCopy.bChatCopyAlwaysShowMask')
RegisterCustomData('MY_ChatCopy.bChatCopyAlwaysWhite')
RegisterCustomData('MY_ChatCopy.bChatCopyNoCopySysmsg')

local function onNewChatLine(h, i, szMsg, szChannel, dwTime, nR, nG, nB)
	if szMsg and i and h:GetItemCount() > i and (MY_ChatCopy.bChatTime or MY_ChatCopy.bChatCopy) then
		-- chat time
		-- check if timestrap can insert
		if MY_ChatCopy.bChatCopyNoCopySysmsg and szChannel == 'SYS_MSG' then
			return
		end
		-- create timestrap text
		local szTime = ''
		for ii = i, h:GetItemCount() - 1 do
			local el = h:Lookup(i)
			if el:GetType() == 'Text' and not el:GetName():find('^namelink_%d+$') and el:GetText() ~= '' then
				nR, nG, nB = el:GetFontColor()
				break
			end
		end
		if MY_ChatCopy.bChatCopy and (MY_ChatCopy.bChatCopyAlwaysShowMask or not MY_ChatCopy.bChatTime) then
			local _r, _g, _b = nR, nG, nB
			if MY_ChatCopy.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = LIB.GetChatCopyXML(_L[' * '], { r = _r, g = _g, b = _b, richtext = szMsg })
		elseif MY_ChatCopy.bChatCopyAlwaysWhite then
			nR, nG, nB = 255, 255, 255
		end
		if MY_ChatCopy.bChatTime then
			if MY_ChatCopy.eChatTime == 'HOUR_MIN_SEC' then
				szTime = szTime .. LIB.GetChatTimeXML(dwTime, {
					r = nR, g = nG, b = nB, f = 10,
					s = '[%hh:%mm:%ss]', richtext = szMsg,
				})
			else
				szTime = szTime .. LIB.GetChatTimeXML(dwTime, {
					r = nR, g = nG, b = nB, f = 10,
					s = '[%hh:%mm]', richtext = szMsg,
				})
			end
		end
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end
LIB.HookChatPanel('AFTER.MY_ChatCopy', onNewChatLine)

function MY_ChatCopy.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = X
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['chat copy'],
		checked = MY_ChatCopy.bChatCopy,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopy = bChecked
		end,
	})
	y = y + deltaY

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['chat time'],
		checked = MY_ChatCopy.bChatTime,
		oncheck = function(bChecked)
			if bChecked and _G.HM_ToolBox then
				_G.HM_ToolBox.bChatTime = false
			end
			MY_ChatCopy.bChatTime = bChecked
		end,
	}):AutoWidth():Width()

	ui:Append('WndComboBox', {
		x = x, y = y, w = 150,
		text = _L['chat time format'],
		menu = function()
			return {{
				szOption = _L['hh:mm'],
				bMCheck = true,
				bChecked = MY_ChatCopy.eChatTime == 'HOUR_MIN',
				fnAction = function()
					MY_ChatCopy.eChatTime = 'HOUR_MIN'
				end,
				fnDisable = function()
					return not MY_ChatCopy.bChatTime
				end,
			},{
				szOption = _L['hh:mm:ss'],
				bMCheck = true,
				bChecked = MY_ChatCopy.eChatTime == 'HOUR_MIN_SEC',
				fnAction = function()
					MY_ChatCopy.eChatTime = 'HOUR_MIN_SEC'
				end,
				fnDisable = function()
					return not MY_ChatCopy.bChatTime
				end,
			}}
		end,
	})
	y = y + deltaY

	x = X + 25
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['always show *'],
		checked = MY_ChatCopy.bChatCopyAlwaysShowMask,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopyAlwaysShowMask = bChecked
		end,
		isdisable = function()
			return not MY_ChatCopy.bChatCopy
		end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['always be white'],
		checked = MY_ChatCopy.bChatCopyAlwaysWhite,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopyAlwaysWhite = bChecked
		end,
		isdisable = function()
			return not MY_ChatCopy.bChatCopy
		end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250,
		text = _L['hide system msg copy'],
		checked = MY_ChatCopy.bChatCopyNoCopySysmsg,
		oncheck = function(bChecked)
			MY_ChatCopy.bChatCopyNoCopySysmsg = bChecked
		end,
		isdisable = function()
			return not MY_ChatCopy.bChatCopy
		end,
	})
	y = y + deltaY

	return x, y
end
