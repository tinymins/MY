--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动阅读书籍
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local MODULE_NAME = 'MY_AutoMemorizeBook'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false,
}
RegisterCustomData('MY_AutoMemorizeBook.bEnable')

function D.Hook()
	local frame = Station.Lookup('Normal/CraftReaderPanel')
	if not frame or frame:Lookup('MY_AutoMemorizeBook') then
		return
	end
	UI(frame):Append('WndCheckBox', {
		name = 'MY_AutoMemorizeBook',
		x = 50, y = 482,
		text = _L['MY_AutoMemorizeBook'],
		checked = MY_AutoMemorizeBook.bEnable,
		oncheck = function() MY_AutoMemorizeBook.bEnable = not MY_AutoMemorizeBook.bEnable end,
	})
end

function D.Unhook()
	UI('Normal/CraftReaderPanel/MY_AutoMemorizeBook'):Remove()
end

function D.CheckEnable()
	if LIB.IsShieldedVersion('MY_AutoMemorizeBook') then
		D.Unhook()
		LIB.RegisterFrameCreate('CraftReaderPanel.MY_AutoMemorizeBook', false)
		LIB.RegisterEvent('OPEN_BOOK.MY_AutoMemorizeBook', false)
		LIB.RegisterEvent('OPEN_BOOK_NOTIFY.MY_AutoMemorizeBook', false)
	else
		D.Hook()
		LIB.RegisterFrameCreate('CraftReaderPanel.MY_AutoMemorizeBook', D.Hook)
		if O.bEnable then
			LIB.RegisterEvent({'OPEN_BOOK.MY_AutoMemorizeBook', 'OPEN_BOOK_NOTIFY.MY_AutoMemorizeBook'}, function(event)
				if IsShiftKeyDown() then
					return LIB.Systopmsg(_L['Auto memorize book has been disabled due to SHIFT key pressed.'])
				end
				local me = GetClientPlayer()
				if not me then
					return
				end
				local nBookID, nSegmentID, nItemID, nRecipeID = arg0, arg1, arg2, arg3
				local dwTargetType = event == 'OPEN_BOOK_NOTIFY' and arg4 or nil
				if me.IsBookMemorized(nBookID, nSegmentID) then
					return
				end
				me.CastProfessionSkill(8, nRecipeID, dwTargetType, nItemID)
			end)
		end
	end
end

LIB.RegisterInit('MY_AutoMemorizeBook', D.CheckEnable)
LIB.RegisterReload('MY_AutoMemorizeBook', D.Unhook)
LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_AutoMemorizeBook', function()
	if arg0 and arg0 ~= 'MY_AutoMemorizeBook' then
		return
	end
	D.CheckEnable()
end)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_AutoMemorizeBook = LIB.GeneGlobalNS(settings)
end
