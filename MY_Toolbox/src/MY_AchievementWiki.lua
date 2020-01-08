--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 成就查询
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
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
RegisterCustomData('MY_AchievementWiki.bEnable')

local function OnItemMouseEnter()
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

local function OnItemMouseLeave()
	if O.bEnable then
		this:SetObjectMouseOver(false)
		HideTip()
	end
end

local function OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Box_AchiBox' and O.bEnable then
		local hItem = this:GetParent()
		local txtName = hItem:Lookup('Text_AchiName')
		local txtDescribe = hItem:Lookup('Text_AchiDescribe')
		local szURL = 'https://j3cx.com/wiki/' .. hItem.dwAchievement
		local szKey = 'AchievementWiki_' .. hItem.dwAchievement
		local szTitle = txtName:GetText() .. ' - ' .. txtDescribe:GetText()
		MY_Web.Open(szURL, { key = szKey, title = szTitle, w = 850, h = 610 })
	end
end

local function OnAppendItem(res, hList)
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
	UnhookTableFunc(boxAchi, 'OnItemMouseEnter', OnItemMouseEnter)
	UnhookTableFunc(boxAchi, 'OnItemMouseLeave', OnItemMouseLeave)
	UnhookTableFunc(boxAchi, 'OnItemLButtonClick', OnItemLButtonClick)
	HookTableFunc(boxAchi, 'OnItemMouseEnter', OnItemMouseEnter)
	HookTableFunc(boxAchi, 'OnItemMouseLeave', OnItemMouseLeave)
	HookTableFunc(boxAchi, 'OnItemLButtonClick', OnItemLButtonClick)
end

local function HookHandle(h)
	if not h then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		OnAppendItem({h:Lookup(i)}, h)
	end
	HookTableFunc(h, 'AppendItemFromData', OnAppendItem, { bAfterOrigin = true, bPassReturn = true })
end

local function HookFrame(frame)
	HookHandle(frame:Lookup('PageSet_Achievement/Page_Achievement/WndScroll_AShow', ''))
	HookHandle(frame:Lookup('PageSet_Achievement/Page_TopRecord/WndScroll_TRShow', ''))
	HookHandle(frame:Lookup('PageSet_Achievement/Page_Summary/WndContainer_AchiPanel/PageSet_Achi/Page_Chi/PageSet_RecentAchi/Page_Scene', ''))
	HookHandle(frame:Lookup('PageSet_Achievement/Page_Summary/WndContainer_AchiPanel/PageSet_Achi/Page_Chi/PageSet_RecentAchi/Page_AlmostFinish', ''))
end

do
local function OnInit()
	local frame = Station.Lookup('Normal/AchievementPanel')
	if not frame then
		return
	end
	HookFrame(frame)
end
LIB.RegisterInit('MY_AchievementWiki', OnInit)
end

do
local function OnFrameCreate(name, frame)
	HookFrame(frame)
end
LIB.RegisterFrameCreate('AchievementPanel.MY_AchievementWiki', OnFrameCreate)
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Achievement wiki'],
		checked = MY_AchievementWiki.bEnable,
		oncheck = function(bChecked)
			MY_AchievementWiki.bEnable = bChecked
		end,
	})
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
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
}
MY_AchievementWiki = LIB.GeneGlobalNS(settings)
end
