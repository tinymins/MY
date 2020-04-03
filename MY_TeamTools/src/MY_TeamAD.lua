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
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamAD'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
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

function D.SetEdit(edit, tab)
	edit:ClearText()
	for k, v in ipairs(tab) do
		if v.text then
			if v.type == 'text' then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
	end
end

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
	nX = ui:Append('WndButton2', { x = nX, y = nY + 10, text = _L['Save Advertising'] }):Click(function(bChecked)
		local edit = LIB.GetChatInputEdit()
		local txt, data = edit:GetText(), edit:GetTextStruct()
		if LIB.TrimString(txt) == '' then
			LIB.Alert(_L['Chat box is empty'])
		else
			GetUserInput(_L['Save Advertising Name'],function(text)
				table.insert(O.tADList, { key = text, text = txt, ad = data })
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
		nX = ui:Append('WndButton2', {
			x = nX, y = nY, w = 80, text = v.key,
			onlclick = function()
				local edit = LIB.GetChatInputEdit()
				D.SetEdit(edit, v.ad)
				Station.SetFocusWindow(edit)
			end,
			rmenu = function()
				local menu = {{
					szOption = _L['Delete'],
					fnAction = function()
						table.remove(O.tADList, k)
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
LIB.RegisterPanel('MY_TeamAD', _L['MY_TeamAD'], _L['Raid'], 5958, PS)
