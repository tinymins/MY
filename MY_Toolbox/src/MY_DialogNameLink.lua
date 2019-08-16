--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 玩家名字变成link方便组队
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
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT..'MY_Toolbox/lang/')
if not LIB.AssertVersion('MY_Toolbox', _L['MY_Toolbox'], 0x2011800) then
	return
end

local D = {}
local O = {
	bEnable = true,
}
RegisterCustomData('MY_DialogNameLink.bAncientMap')

function D.Apply()
	LIB.RegisterEvent('OPEN_WINDOW.NAMELINKER', function(event)
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
						LIB.RenderChatLink(h:Lookup(i + 1))
						if MY_Farbnamen and MY_Farbnamen.Render then
							MY_Farbnamen.Render(h:Lookup(i + 1))
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
end
LIB.RegisterInit('MY_DialogNameLink', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
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
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_DialogNameLink = LIB.GeneGlobalNS(settings)
end
