--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 成就查询
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
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false,
	nW = 850,
	nH = 610,
}
RegisterCustomData('MY_AchievementWiki.bEnable')
RegisterCustomData('MY_AchievementWiki.nW')
RegisterCustomData('MY_AchievementWiki.nH')

function D.OnWebSizeChange()
	O.nW, O.nH = this:GetSize()
end

function D.Open(dwAchievement)
	local achi = LIB.GetAchievement(dwAchievement)
	if not achi then
		return
	end
	local szURL = 'https://page.j3cx.com/wiki/' .. dwAchievement .. '?'
		.. LIB.EncodePostData(LIB.UrlEncode({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			player = AnsiToUTF8(GetUserRoleName()),
		}))
	local szKey = 'AchievementWiki_' .. dwAchievement
	local szTitle = achi.szName .. ' - ' .. achi.szDesc
	szKey = UI.OpenBrowser(szURL, {
		key = szKey,
		title = szTitle,
		w = O.nW, h = O.nH,
		readonly = true,
	})
	UI(UI.LookupBrowser(szKey)):Size(D.OnWebSizeChange)
end

function D.OnAchieveItemMouseEnter()
	if O.bEnable then
		this:SetObjectMouseOver(true)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local xml = {}
		insert(xml, GetFormatText(_L['Click for achievement wiki'], 41))
		if IsCtrlKeyDown() then
			local h = this:GetParent()
			local t = {}
			for k, v in pairs(h) do
				if k ~= '___id' and k ~= '___type' then
					insert(t, k .. ': ' .. EncodeLUAData(v, '  '))
				end
			end
			insert(xml, GetFormatText('\n\n' .. g_tStrings.DEBUG_INFO_ITEM_TIP .. '\n', 102))
			insert(xml, GetFormatText(concat(t, '\n'), 102))
		end
		OutputTip(concat(xml), 300, { x, y, w, h })
	end
end

function D.OnAchieveItemMouseLeave()
	if O.bEnable then
		this:SetObjectMouseOver(false)
		HideTip()
	end
end

function D.OnAchieveItemLButtonClick()
	local name = this:GetName()
	if name == 'Box_AchiBox' and O.bEnable then
		D.Open(this:GetParent().dwAchievement)
	end
end

function D.OnAchieveAppendItem(res, hList)
	local hItem = res[1]
	if not hItem then
		return
	end
	local boxAchi = hItem:Lookup('Box_AchiBox') or hItem:Lookup('Box_AchiBoxShort')
	local txtName = hItem:Lookup('Text_AchiName')
	local txtDescribe = hItem:Lookup('Text_AchiDescribe')
	if not boxAchi or not txtName or not txtDescribe then
		return
	end
	boxAchi:RegisterEvent(ITEM_EVENT.LBUTTONCLICK)
	boxAchi:RegisterEvent(ITEM_EVENT.MOUSEENTERLEAVE)
	UnhookTableFunc(boxAchi, 'OnItemMouseEnter', D.OnAchieveItemMouseEnter)
	UnhookTableFunc(boxAchi, 'OnItemMouseLeave', D.OnAchieveItemMouseLeave)
	UnhookTableFunc(boxAchi, 'OnItemLButtonClick', D.OnAchieveItemLButtonClick)
	HookTableFunc(boxAchi, 'OnItemMouseEnter', D.OnAchieveItemMouseEnter)
	HookTableFunc(boxAchi, 'OnItemMouseLeave', D.OnAchieveItemMouseLeave)
	HookTableFunc(boxAchi, 'OnItemLButtonClick', D.OnAchieveItemLButtonClick)
end

function D.HookAchieveHandle(h)
	if not h then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		D.OnAchieveAppendItem({h:Lookup(i)}, h)
	end
	HookTableFunc(h, 'AppendItemFromData', D.OnAchieveAppendItem, { bAfterOrigin = true, bPassReturn = true })
end

function D.HookAchieveFrame(frame)
	D.HookAchieveHandle(frame:Lookup('PageSet_Achievement/Page_Achievement/WndScroll_AShow', ''))
	D.HookAchieveHandle(frame:Lookup('PageSet_Achievement/Page_TopRecord/WndScroll_TRShow', ''))
	D.HookAchieveHandle(frame:Lookup('PageSet_Achievement/Page_Summary/WndContainer_AchiPanel/PageSet_Achi/Page_Chi/PageSet_RecentAchi/Page_Scene', ''))
	D.HookAchieveHandle(frame:Lookup('PageSet_Achievement/Page_Summary/WndContainer_AchiPanel/PageSet_Achi/Page_Chi/PageSet_RecentAchi/Page_AlmostFinish', ''))
end

LIB.RegisterInit('MY_AchievementWiki', function()
	local frame = Station.Lookup('Normal/AchievementPanel')
	if not frame then
		return
	end
	D.HookAchieveFrame(frame)
end)

LIB.RegisterFrameCreate('AchievementPanel.MY_AchievementWiki', function(name, frame)
	D.HookAchieveFrame(frame)
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Achievement wiki'],
		tip = _L['Click icon on achievemnt panel to view achievement wiki'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		checked = MY_AchievementWiki.bEnable,
		oncheck = function(bChecked)
			MY_AchievementWiki.bEnable = bChecked
		end,
	}):Width() + 5
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
				nW = true,
				nH = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				nW = true,
				nH = true,
			},
			root = O,
		},
	},
}
MY_AchievementWiki = LIB.GeneGlobalNS(settings)
end
