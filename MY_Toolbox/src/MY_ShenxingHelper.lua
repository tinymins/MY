--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 神行千里助手
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
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2011800) then
	return
end

local D = {}
local O = {
	bAncientMap = true,
	bOpenAllMap = true,
	bAvoidBlackCD = true,
}
RegisterCustomData('MY_ShenxingHelper.bAncientMap')
RegisterCustomData('MY_ShenxingHelper.bOpenAllMap')
RegisterCustomData('MY_ShenxingHelper.bAvoidBlackCD')

-- 【台服用】老地图神行
do
local tNonwarData = {
	{ id =  8, x =   70, y =   5 }, -- 洛阳
	{ id = 11, x =   15, y = -90 }, -- 天策
	{ id = 12, x = -150, y = 110 }, -- 枫华
	{ id = 15, x = -450, y =  65 }, -- 长安
	{ id = 26, x =  -20, y =  90 }, -- 荻花宫
	{ id = 32, x =   50, y =  45 }, -- 小战宝
}
local function drawNonwarMap()
	if LIB.IsShieldedVersion() then
		return
	end
	local h = Station.Lookup('Topmost1/WorldMap/Wnd_All', 'Handle_CopyBtn')
	if not h or h.__MY_NonwarData or not h:IsVisible() then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		local m = h:Lookup(i)
		if m and m.mapid == 160 then
			local _w, _ = m:GetSize()
			local fS = m.w / _w
			for _, v in ipairs(tNonwarData) do
				local bOpen = me.GetMapVisitFlag(v.id)
				local szFile, nFrame = 'ui/Image/MiddleMap/MapWindow.UITex', 41
				if bOpen then
					nFrame = 98
				end
				h:AppendItemFromString('<image>name="mynw_' .. v.id .. '" path='..EncodeComponentsString(szFile)..' frame='..nFrame..' eventid=341</image>')
				local img = h:Lookup(h:GetItemCount() - 1)
				img.bEnable = bOpen
				img.bSelect = bOpen and v.id ~= 26 and v.id ~= 32
				img.x = m.x + v.x
				img.y = m.y + v.y
				img.w, img.h = m.w, m.h
				img.id, img.mapid = v.id, v.id
				img.middlemapindex = 0
				img.name = Table_GetMapName(img.mapid)
				img.city = img.name
				img.button = m.button
				img.copy = true
				img:SetSize(img.w / fS, img.h / fS)
				img:SetRelPos(img.x / fS - (img.w / fS / 2), img.y / fS - (img.h / fS / 2))
			end
			h:FormatAllItemPos()
			break
		end
	end
	h.__MY_NonwarData = true
end
LIB.BreatheCall('MY_Toolbox#NonwarData', 130, drawNonwarMap)
end

-- 【台服用】强开所有地图
do
local h, hList, hItem
local function openAllMap()
	if LIB.IsShieldedVersion() then
		return
	end
	h = Station.Lookup('Topmost1/WorldMap/Wnd_All', '')
	if not h or not h:IsVisible() then
		return
	end
	local me = GetClientPlayer()
	local dwCurrMapID = me and me.GetScene().dwMapID
	for _, szHandleName in ipairs({
		'Handle_CityBtn',
		'Handle_CopyBtn',
	}) do
		hList = h:Lookup(szHandleName)
		if hList then
			for i = 0, hList:GetItemCount() - 1 do
				hItem = hList:Lookup(i)
				if hItem.mapid == 1 or dwCurrMapID == hItem.mapid then
					hItem.mapid = tostring(hItem.mapid)
				else
					hItem.mapid = tonumber(hItem.mapid) or hItem.mapid
				end
				hItem.bEnable = true
			end
		end
	end
	h, hList, hItem = nil
end
LIB.BreatheCall('MY_Toolbox#OpenAllMap', 130, openAllMap)
end

function D.Apply()
	if O.bEnable then
		LIB.RegisterEvent('DO_SKILL_CAST.MY_AvoidBlackShenxingCD', function()
			local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
			if not(UI_GetClientPlayerID() == dwID and
			Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)) then
				return
			end
			local player = GetClientPlayer()
			if not player then
				return
			end

			local nType, dwSkillID, dwSkillLevel, fProgress = player.GetSkillOTActionState()
			if not ((
				nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
			) and dwSkillID == 3691) then
				return
			end
			LIB.Sysmsg({_L['Shenxing has been cancelled, cause you got the zhenyan.']})
			player.StopCurrentAction()
		end)
	else
		LIB.RegisterEvent('DO_SKILL_CAST.MY_AvoidBlackShenxingCD')
	end
end
LIB.RegisterInit('MY_ShenxingHelper', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['avoid blacking shenxing cd'],
		checked = MY_ShenxingHelper.bAvoidBlackCD,
		oncheck = function(bChecked)
			MY_ShenxingHelper.bAvoidBlackCD = bChecked
		end,
	})
	y = y + 30
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
				bAncientMap = true,
				bOpenAllMap = true,
				bAvoidBlackCD = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bAncientMap = true,
				bOpenAllMap = true,
				bAvoidBlackCD = true,
			},
			triggers = {
				bAncientMap = D.Apply,
				bOpenAllMap = D.Apply,
				bAvoidBlackCD = D.Apply,
			},
			root = O,
		},
	},
}
MY_ShenxingHelper = LIB.GeneGlobalNS(settings)
end
