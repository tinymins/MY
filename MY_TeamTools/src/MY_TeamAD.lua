--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ±£´æº°»°
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
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamAD'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	szDataFile = {'userdata/team_advertising.jx3dat', PATH_TYPE.GLOBAL},
	tItem = {
		{ dwTabType = 5, dwIndex = 24430, nUiId = 153192 },
		{ dwTabType = 5, dwIndex = 23988, nUiId = 152748 },
		{ dwTabType = 5, dwIndex = 23841, nUiId = 152596 },
		{ dwTabType = 5, dwIndex = 22939, nUiId = 151677 },
		{ dwTabType = 5, dwIndex = 23759, nUiId = 152512 },
		{ dwTabType = 5, dwIndex = 22084, nUiId = 150827 },
		{ dwTabType = 5, dwIndex = 22085, nUiId = 150828 },
		{ dwTabType = 5, dwIndex = 22086, nUiId = 150829 },
		{ dwTabType = 5, dwIndex = 22087, nUiId = 150830 },
		{ dwTabType = 5, dwIndex = 25831, nUiId = 153898 },
		{ dwTabType = 5, dwIndex = 33450, nUiId = 162223 },
	}
}

function D.LoadLUAData()
	O.tADList = LIB.LoadLUAData(O.szDataFile, { passphrase = false, crc = false }) or {}
end

function D.SaveLUAData()
	LIB.SaveLUAData(O.szDataFile, O.tADList, { indent = '\t', passphrase = false, crc = false })
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local W, H = ui:Size()
	local nX, nY = X, Y
	D.LoadLUAData()

	nX = X
	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['Save Talk'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = X + 10
	nX = ui:Append('WndButton', { x = nX, y = nY + 10, text = _L['Save Advertising'], buttonstyle = 2 }):Click(function(bChecked)
		local edit = LIB.GetChatInput()
		local txt, data = edit:GetText(), edit:GetTextStruct()
		if LIB.TrimString(txt) == '' then
			LIB.Alert(_L['Chat box is empty'])
		else
			GetUserInput(_L['Save Advertising Name'],function(text)
				insert(O.tADList, { key = text, text = txt, ad = data })
				D.SaveLUAData()
				LIB.SwitchTab('MY_TeamAD', true)
			end, nil, nil, nil, nil, 5)
		end
	end):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = nX + 5, y = nY + 10, text = _L['Advertising Tips'] }):Pos('BOTTOMRIGHT')

	nX = X
	nX, nY = ui:Append('Text', { x = nX, y = nY + 5, text = _L['Gadgets'], font = 27 }):Pos('BOTTOMRIGHT')
	for k, v in ipairs(O.tItem) do
		nX = ui:Append('Box', { x = (k - 1) * 48 + X + 10, y = nY + 10, w = 38, h = 38 }):ItemInfo(GLOBAL.CURRENT_ITEM_VERSION, v.dwTabType, v.dwIndex):Pos('BOTTOMRIGHT')
	end

	nX = X
	nY = nY + 58
	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['Advertising List'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = X + 10
	nY = nY + 10
	for k, v in ipairs(O.tADList) do
		if nX + 80 > W then
			nX = X + 10
			nY = nY + 28
		end
		nX = ui:Append('WndButton', {
			x = nX, y = nY, w = 80, text = v.key,
			buttonstyle = 2,
			onlclick = function()
				LIB.SetChatInput(v.ad)
				LIB.FocusChatInput()
			end,
			rmenu = function()
				local menu = {{
					szOption = _L['Delete'],
					fnAction = function()
						remove(O.tADList, k)
						D.SaveLUAData()
						LIB.SwitchTab('MY_TeamAD', true)
					end,
				}}
				return menu
			end,
			onhover = function(bIn)
				if bIn then
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputTip(GetFormatText(v.text), 550, { x, y, w, h })
				else
					HideTip()
				end
			end,
		}):Pos('BOTTOMRIGHT') + 10
	end
end
LIB.RegisterPanel(_L['Raid'], 'MY_TeamAD', _L['MY_TeamAD'], 5958, PS)
