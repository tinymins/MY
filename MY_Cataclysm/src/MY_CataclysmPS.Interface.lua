--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板样式设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, {}
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:Append('Text', { x = x, y = y, text = _L['Interface settings'], font = 27 }, true):Height()

	x = X + 10
	y = y + 3
	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Official team frame style'],
		group = 'CSS', checked = CFG.eFrameStyle == 'OFFICIAL',
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.eFrameStyle = 'OFFICIAL'
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}, true):AutoWidth():Width() + 5

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Cataclysm team frame style'],
		group = 'CSS', checked = CFG.eFrameStyle == 'CATACLYSM',
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.eFrameStyle = 'CATACLYSM'
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}, true):AutoWidth():Height()

	x = X + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Interface Width']}, true):AutoWidth():Width() + 5
	y = y + ui:Append('WndTrackbar', {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = CFG.fScaleX * 100,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = nVal / CFG.fScaleX, CFG.fScaleY / CFG.fScaleY
			CFG.fScaleX = nVal
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:Scale(nNewX, nNewY)
			end
		end,
		textfmt = function(val) return _L('%d%%', val) end,
	}, true):Height()

	x = X + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Interface Height']}, true):AutoWidth():Width() + 5
	y = y + ui:Append('WndTrackbar', {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = CFG.fScaleY * 100,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = CFG.fScaleX / CFG.fScaleX, nVal / CFG.fScaleY
			CFG.fScaleY = nVal
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:Scale(nNewX, nNewY)
			end
		end,
		textfmt = function(val) return _L('%d%%', val) end,
	}, true):Height()

	x = X
	y = y + 10
	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.OTHER, font = 27 }, true):Height()

	x = x + 10
	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Group Number'],
		checked = CFG.bShowGroupNumber,
		oncheck = function(bCheck)
			CFG.bShowGroupNumber = bCheck
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}, true):Height()

	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_ALPHA }, true):AutoWidth():Width() + 5
		y = y + ui:Append('WndTrackbar', {
			x = x, y = y + 3,
			range = {0, 255},
			value = CFG.nAlpha,
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(nVal)
				CFG.nAlpha = nVal
				if MY_Cataclysm.GetFrame() then
					FireUIEvent('CTM_SET_ALPHA')
				end
			end,
			textfmt = function(val) return _L('%d%%', val / 255 * 100) end,
		}, true):Height()
	end

	x = X
	y = y + 10
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Arrangement'], font = 27 }, true):Height()

	x = x + 10
	y = y + 3
	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['One lines: 5/0'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 5,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 5
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 1/4'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 1,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 1
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 2/3'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 2,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 2
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 3/2'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 3,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 3
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 4/1'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 4,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 4
			if MY_Cataclysm.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):AutoWidth():Height() + 3
end
LIB.RegisterPanel('MY_Cataclysm_Interface', _L['Interface settings'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|74', PS)
