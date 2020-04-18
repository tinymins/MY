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
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
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

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	if not LIB.IsShieldedVersion('MY_FriendTipLocation') then
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Show all friend tip location'],
			checked = MY_FriendTipLocation.bEnable,
			oncheck = function(bChecked)
				MY_FriendTipLocation.bEnable = bChecked
			end,
		}):AutoWidth():Width() + 5
		x, y = X, y + 25
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
