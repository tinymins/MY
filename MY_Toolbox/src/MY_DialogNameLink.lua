--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 玩家名字变成link方便组队
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^6.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_DialogNameLink', _L['General'], {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

function D.Apply()
	if D.bReady and O.bEnable then
		LIB.RegisterEvent('OPEN_WINDOW', 'NAMELINKER', function(event)
			local h
			for _, p in ipairs({
				{'Normal/DialoguePanel', '', 'Handle_Message'},
				{'Lowest2/PlotDialoguePanel', 'Wnd_Dialogue', 'Handle_Dialogue'},
			}) do
				local frame = Station.Lookup(p[1])
				if frame and frame:IsVisible() then
					h = frame:Lookup(p[2], p[3])
					if h then
						break
					end
				end
			end
			if not h then
				return
			end
			for i = 0, h:GetItemCount() - 1 do
				local hItem = h:Lookup(i)
				if hItem:GetType() == 'Text' then
					local szText = hItem:GetText()
					for _, szPattern in ipairs(_L.NAME_PATTERN_LIST) do
						local _, _, szName = szText:find(szPattern)
						if szName then
							local nPos1, nPos2 = szText:find(szName)
							h:InsertItemFromString(i, true, GetFormatText(szText:sub(nPos2 + 1), hItem:GetFontScheme()))
							h:InsertItemFromString(i, true, GetFormatText('[' .. szText:sub(nPos1, nPos2) .. ']', nil, nil, nil, nil, nil, nil, 'namelink'))
							local txtName = h:Lookup(i + 1)
							LIB.RenderChatLink(txtName)
							if MY_Farbnamen and MY_Farbnamen.Render then
								MY_Farbnamen.Render(txtName, { bColor = false })
							end
							hItem:SetText(szText:sub(1, nPos1 - 1))
							hItem:SetFontColor(0, 0, 0)
							hItem:AutoSize()
							break
						end
					end
				end
			end
			h:FormatAllItemPos()
		end)
	else
		LIB.RegisterEvent('OPEN_WINDOW', 'NAMELINKER', false)
	end
end
LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_DialogNameLink', function()
	D.bReady = true
	D.Apply()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	return x, y
end

-- Global exports
do
local settings = {
	name = 'MY_DialogNameLink',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			triggers = {
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_DialogNameLink = LIB.CreateModule(settings)
end
