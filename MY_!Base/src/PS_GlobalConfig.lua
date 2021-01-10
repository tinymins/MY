--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ȫ����������
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps_globalconfig/')

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local X, Y = 20, 20
	local x, y = X, Y

	ui:Append('Text', {
		x = X - 10, y = y,
		text = _L['Distance type'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	x, y = X, y + 30

	for _, p in ipairs(LIB.GetDistanceTypeList()) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, w = 100, h = 25, group = 'distance type',
			text = p.szText,
			checked = LIB.GetGlobalDistanceType() == p.szType,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				LIB.SetGlobalDistanceType(p.szType)
			end,
		}):AutoWidth():Width() + 10
	end
	x, y = X, y + 30

	ui:Append('Text', {
		x = X - 10, y = y,
		text = _L['Notify center'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 200, h = 25,
		text = _L['Show in minimap'],
		checked = MY_Notify.bEntry,
		oncheck = function(bChecked)
			MY_Notify.bEntry = bChecked
			MY_Notify.UpdateEntry()
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 100, h = 25,
		text = _L['Order desc'],
		checked = MY_Notify.bDesc,
		oncheck = function(bChecked)
			MY_Notify.bDesc = bChecked
			MY_Notify.DrawNotifies()
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 100, h = 25,
		text = _L['Disable dismiss'],
		checked = MY_Notify.bDisableDismiss,
		oncheck = function(bChecked)
			MY_Notify.bDisableDismiss = bChecked
		end,
	}):AutoWidth():Width() + 5
	x, y = X, y + 30

	ui:Append('Text', {
		x = X - 10, y = y,
		text = _L['Hover entry'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 100, h = 25,
		text = _L['Enable'],
		checked = MY_HoverEntry.bEnable,
		oncheck = function(bChecked)
			MY_HoverEntry.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 100, h = 25,
		text = _L['Hover popup'],
		checked = MY_HoverEntry.bHoverMenu,
		oncheck = function(bChecked)
			MY_HoverEntry.bHoverMenu = bChecked
		end,
		autoenable = function() return MY_HoverEntry.bEnable end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y, w = 100, h = 25,
		value = MY_HoverEntry.nSize,
		range = {1, 300},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(v) return _L('Size: %d', v) end,
		onchange = function(val)
			MY_HoverEntry.nSize = val
		end,
		autoenable = function() return MY_HoverEntry.bEnable end,
	}):AutoWidth():Width() + 5
	x, y = X, y + 30

	ui:Append('Text', {
		x = X - 10, y = y,
		text = _L['System Info'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	y = y + 30

	local uiMemory = ui:Append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	})
	y = y + 25

	local uiSize = ui:Append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	})
	y = y + 25

	local uiUIScale = ui:Append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	})
	y = y + 25

	local uiFontScale = ui:Append('Text', {
		x = x, y = y, w = 150,
		alpha = 150, font = 162,
	})
	y = y + 25

	local function onRefresh()
		uiMemory:Text(format('Memory: %.2fMB', collectgarbage('count') / 1024))
		uiSize:Text(format('UISize: %.2fx%.2f', Station.GetClientSize()))
		uiUIScale:Text(format('UIScale: %.2f (%.2f)', LIB.GetUIScale(), LIB.GetOriginUIScale()))
		uiFontScale:Text(format('FontScale: %.2f (%.2f)', LIB.GetFontScale(), Font.GetOffset()))
	end
	onRefresh()
	LIB.BreatheCall('GlobalConfig', onRefresh)
end

function PS.OnPanelDeactive()
	LIB.BreatheCall('GlobalConfig', false)
end

LIB.RegisterPanel(_L['System'], 'GlobalConfig', _L['GlobalConfig'], 'ui\\Image\\Minimap\\Minimap.UITex|181', PS)