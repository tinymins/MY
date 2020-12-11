--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板样式设置
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
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 4 }
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:Append('Text', { x = x, y = y, text = _L['Interface settings'], font = 27 }):Height()

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
	}):AutoWidth():Width() + 5

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
	}):AutoWidth():Height()

	x = X + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Interface Width']}):AutoWidth():Width() + 5
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
	}):Height()

	x = X + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Interface Height']}):AutoWidth():Width() + 5
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
	}):Height()

	x = X
	y = y + 10
	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.OTHER, font = 27 }):Height()

	x = x + 10
	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Group Number'],
		checked = CFG.bShowGroupNumber,
		oncheck = function(bCheck)
			CFG.bShowGroupNumber = bCheck
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}):Height()

	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_ALPHA }):AutoWidth():Width() + 5
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
		}):Height()
	end

	x = X
	y = y + 10
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Arrangement'], font = 27 }):Height()

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
	}):AutoWidth():Height() + 3

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
	}):AutoWidth():Height() + 3

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
	}):AutoWidth():Height() + 3

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
	}):AutoWidth():Height() + 3

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
	}):AutoWidth():Height() + 3
end
LIB.RegisterPanel(_L['Raid'], 'MY_Cataclysm_Interface', _L['Interface settings'], 'ui/Image/UICommon/RaidTotal.uitex|74', PS)
