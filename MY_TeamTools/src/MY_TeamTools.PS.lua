--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具界面
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
LIB.RegisterRestriction('MY_WorldMark', { ['*'] = true, intl = false })
--------------------------------------------------------------------------
local PS = { nPriority = 0 }
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local nPaddingX, nPaddingY = 20, 30
	local nX, nY, nLFY = nPaddingX, nPaddingY, nPaddingY
	local nW, nH = ui:Size()
	local nLH = 25

	ui:Append('WndButton', {
		x = nW - 165, y = nY, w = 150, h = 38,
		text = _L['Open Panel'],
		buttonstyle = 'SKEUOMORPHISM_LACE_BORDER',
		onclick = MY_TeamTools.Open,
	})

	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['MY_TeamTools'], font = 27 }):Height() + 5
	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		checked = MY_TeamNotice.bEnable,
		text = _L['Team Message'],
		oncheck = function(bChecked)
			MY_TeamNotice.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		checked = MY_CharInfo.bEnable,
		text = _L['Allow view charinfo'],
		oncheck = function(bChecked)
			MY_CharInfo.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5

	if not LIB.IsRestricted('MY_WorldMark') then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			checked = MY_WorldMark.bEnable,
			text = _L['World mark enhance'],
			oncheck = function(bChecked)
				MY_WorldMark.bEnable = bChecked
				MY_WorldMark.CheckEnable()
			end,
		}):AutoWidth():Width() + 5
	end

	nLFY = nY + nLH
	nX, nY, nLFY = MY_CombatLogs.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)

	nX = nPaddingX
	nY = nY + 30
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Party Request'], font = 27 }):Height() + 5
	nX = nPaddingX + 10
	nX, nY = MY_PartyRequest.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX, nY = MY_RideRequest.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX, nY = MY_EvokeRequest.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX, nY = MY_SocialRequest.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX, nY = MY_TeamRestore.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
end
LIB.RegisterPanel(_L['Raid'], 'MY_TeamTools', _L['MY_TeamTools'], 5962, PS)
