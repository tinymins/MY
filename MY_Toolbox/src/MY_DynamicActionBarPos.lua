--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 记住动态技能栏上次位置
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_DynamicActionBarPos'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	-- 设置项
	bEnable = true,
	tAnchor = nil,
}
RegisterCustomData('MY_DynamicActionBarPos.bEnable')

function D.GetFrame()
	return Station.Lookup('Lowest1/DynamicActionBar')
end

function D.UpdateAnchor()
	local an = O.bEnable and O.tAnchor
	if not an then
		return
	end
	local frame = D.GetFrame()
	if not frame then
		return
	end
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	frame:CorrectPos()
end

function D.SaveAnchor()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	O.tAnchor = GetFrameAnchor(frame, 'TOP_LEFT')
end

LIB.RegisterFrameCreate('DynamicActionBar.MY_DynamicActionBarPos', D.UpdateAnchor)
LIB.RegisterFrameCreate('UI_SCALED.MY_DynamicActionBarPos', D.UpdateAnchor)
LIB.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE.MY_DynamicActionBarPos', D.SaveAnchor)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 130,
		text = _L['Restore dynamic action bar pos'],
		checked = MY_DynamicActionBarPos.bEnable,
		oncheck = function()
			MY_DynamicActionBarPos.bEnable = not MY_DynamicActionBarPos.bEnable
		end,
	}):AutoWidth()
	y = y + 25
	return x, y
end

-- Global exports
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
				bEnable = true,
				tAnchor = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				tAnchor = true,
			},
			triggers = {
				bEnable = D.UpdateAnchor,
			},
			root = O,
		},
	},
}
MY_DynamicActionBarPos = LIB.GeneGlobalNS(settings)
end
