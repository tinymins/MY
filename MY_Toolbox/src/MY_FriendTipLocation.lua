--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 好友界面显示所有好友位置
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
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_FriendTipLocation'
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
RegisterCustomData('MY_FriendTipLocation.bEnable')

function D.Hook()
	local frame = Station.Lookup('Normal/FriendTip')
	if not frame then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local txtName = frame:Lookup('', 'Text_Name')
	local txtTitle = frame:Lookup('Wnd_Friend', 'Text_WhereT')
	local txtLocation = frame:Lookup('Wnd_Friend', 'Text_Where')
	if not (txtName and txtTitle and txtLocation) then
		return
	end
	if not txtLocation.__MY_SetText then
		txtLocation.__MY_SetText = txtLocation.SetText
		txtLocation.SetText = function(_, szText)
			local info = txtName and LIB.GetFriend(txtName:GetText())
			local card = info and info.isonline and GetFellowshipCardClient().GetFellowshipCardInfo(info.id)
			if card then
				szText = Table_GetMapName(card.dwMapID)
				if (me.nCamp == CAMP.EVIL and card.nCamp == CAMP.GOOD)
				or (me.nCamp == CAMP.GOOD and card.nCamp == CAMP.EVIL) then
					szText = szText .. _L['(Different camp)']
				end
			end
			txtLocation:__MY_SetText(szText)
		end
	end
end

function D.Unhook()
	Wnd.CloseWindow('FriendTip')
end

function D.CheckEnable()
	if LIB.IsShieldedVersion('MY_FriendTipLocation') or not O.bEnable then
		D.Unhook()
		LIB.RegisterFrameCreate('FriendTip.MY_FriendTipLocation', false)
	else
		D.Hook()
		LIB.RegisterFrameCreate('FriendTip.MY_FriendTipLocation', D.Hook)
	end
end

LIB.RegisterInit('MY_FriendTipLocation', D.CheckEnable)
LIB.RegisterReload('MY_FriendTipLocation', D.Unhook)
LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_FriendTipLocation', function()
	if arg0 and arg0 ~= 'MY_FriendTipLocation' then
		return
	end
	D.CheckEnable()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	if not LIB.IsShieldedVersion('MY_FriendTipLocation') then
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Show all friend tip location'],
			checked = MY_FriendTipLocation.bEnable,
			oncheck = function(bChecked)
				MY_FriendTipLocation.bEnable = bChecked
			end,
		}):AutoWidth():Width() + 5
	end
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
MY_FriendTipLocation = LIB.GeneGlobalNS(settings)
end
