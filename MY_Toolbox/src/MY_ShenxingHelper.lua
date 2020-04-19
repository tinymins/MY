--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 神行千里助手
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
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
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
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
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
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bAncientMap = true,
	bOpenAllMap = true,
	bAvoidBlackCD = true,
}
RegisterCustomData('MY_ShenxingHelper.bAncientMap')
RegisterCustomData('MY_ShenxingHelper.bOpenAllMap')
RegisterCustomData('MY_ShenxingHelper.bAvoidBlackCD')

local NONWAR_DATA = {
	{ id =  8, x =   70, y =    5 }, -- 洛阳
	{ id = 11, x =  170, y = -160 }, -- 天策
	{ id = 12, x = -150, y =  110 }, -- 枫华
	{ id = 15, x = -450, y =   65 }, -- 长安
	{ id = 26, x =  -20, y =   90 }, -- 荻花宫
	{ id = 32, x =   50, y =   45 }, -- 小战宝
}

--------------------------------------------------------------------------
-- 【台服用】老地图神行
--------------------------------------------------------------------------
function D.HookNonwarMap()
	local h = Station.Lookup('Topmost1/WorldMap/Wnd_All', 'Handle_CopyBtn')
	if not h or h.__MY_NonwarData then
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
			for _, v in ipairs(NONWAR_DATA) do
				local bOpen = me.GetMapVisitFlag(v.id)
				local szFile, nFrame = 'ui/Image/MiddleMap/MapWindow.UITex', 41
				if bOpen then
					nFrame = 98
				end
				h:AppendItemFromString('<image>name="mynw_' .. v.id .. '" path='..EncodeComponentsString(szFile)..' frame='..nFrame..' eventid=341</image>')
				local img = h:Lookup(h:GetItemCount() - 1)
				img.bMYNonwar = true
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
				img.OnItemMouseEnter = function()
					img:SetAlpha(255)
					return LIB.FORMAT_WMSG_RET(true, true)
				end
				img.OnItemMouseLeave = function()
					img:SetAlpha(200)
					return LIB.FORMAT_WMSG_RET(true, true)
				end
				img:SetAlpha(200)
				img:SetSize(img.w / fS, img.h / fS)
				img:SetRelPos(img.x / fS - (img.w / fS / 2), img.y / fS - (img.h / fS / 2))
			end
			h:FormatAllItemPos()
			break
		end
	end
	h.__MY_NonwarData = true
end

function D.UnhookNonwarMap()
	local h = Station.Lookup('Topmost1/WorldMap/Wnd_All', 'Handle_CopyBtn')
	if not h or not h.__MY_NonwarData then
		return
	end
	for i = h:GetItemCount() - 1, 0, -1 do
		local m = h:Lookup(i)
		if m.bMYNonwar then
			h:RemoveItem(m)
		end
	end
	h.__MY_NonwarData = nil
end

function D.CheckNonwarMapEnable()
	if O.bAncientMap and not LIB.IsShieldedVersion('MY_ShenxingHelper') then
		D.HookNonwarMap()
	else
		D.UnhookNonwarMap()
	end
end
LIB.RegisterFrameCreate('WorldMap.MY_ShenxingHelper__NonwarMap', D.CheckNonwarMapEnable)

--------------------------------------------------------------------------
-- 【台服用】强开所有地图
--------------------------------------------------------------------------
function D.HookOpenAllMap()
	local h = Station.Lookup('Topmost1/WorldMap/Wnd_All', '')
	if not h then
		return
	end
	local me = GetClientPlayer()
	local dwCurrMapID = me and me.GetScene().dwMapID
	for _, szHandleName in ipairs({ 'Handle_CityBtn', 'Handle_CopyBtn' }) do
		local hList = h:Lookup(szHandleName)
		if hList then
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				if hItem.dwMYMapID == nil then
					hItem.dwMYMapID = hItem.mapid
				end
				if hItem.bMYEnable == nil then
					hItem.bMYEnable = hItem.bEnable
				end
				if hItem.mapid == 1 or dwCurrMapID == hItem.mapid then
					hItem.mapid = tostring(hItem.mapid)
				else
					hItem.mapid = tonumber(hItem.mapid) or hItem.mapid
				end
				hItem.bEnable = true
			end
		end
	end
end

function D.UnhookOpenAllMap()
	local h = Station.Lookup('Topmost1/WorldMap/Wnd_All', '')
	if not h then
		return
	end
	for _, szHandleName in ipairs({ 'Handle_CityBtn', 'Handle_CopyBtn' }) do
		local hList = h:Lookup(szHandleName)
		if hList then
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				if hItem.dwMYMapID ~= nil then
					hItem.mapid = hItem.dwMYMapID
					hItem.dwMYMapID = nil
				end
				if hItem.bMYEnable ~= nil then
					hItem.bEnable = hItem.bMYEnable
					hItem.bMYEnable = nil
				end
			end
		end
	end
end

function D.CheckOpenAllMapEnable()
	if O.bOpenAllMap and not LIB.IsShieldedVersion('MY_ShenxingHelper') then
		D.HookOpenAllMap()
	else
		D.UnhookOpenAllMap()
	end
end
LIB.RegisterFrameCreate('WorldMap.MY_ShenxingHelper__OpenAllMap', D.CheckOpenAllMapEnable)

--------------------------------------------------------------------------
-- 防止神行CD被黑
--------------------------------------------------------------------------
function D.CheckAvoidBlackShenxingEnable()
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
			LIB.Sysmsg(_L['Shenxing has been cancelled, cause you got the zhenyan.'])
			player.StopCurrentAction()
		end)
	else
		LIB.RegisterEvent('DO_SKILL_CAST.MY_AvoidBlackShenxingCD')
	end
end

--------------------------------------------------------------------------
-- 模块事件监听
--------------------------------------------------------------------------
function D.CheckEnable()
	D.CheckNonwarMapEnable()
	D.CheckOpenAllMapEnable()
	D.CheckAvoidBlackShenxingEnable()
end

function D.RemoveHook()
	D.UnhookNonwarMap()
	D.UnhookOpenAllMap()
end

LIB.RegisterEvent('MY_SHIELDED_VERSION.MY_ShenxingHelper', function()
	if arg0 and arg0 ~= 'MY_ShenxingHelper' then
		return
	end
	D.CheckEnable()
end)
LIB.RegisterInit('MY_ShenxingHelper', D.CheckEnable)
LIB.RegisterReload('MY_ShenxingHelper', D.RemoveHook)

--------------------------------------------------------------------------
-- 设置界面
--------------------------------------------------------------------------
function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Avoid blacking shenxing cd'],
		tip = _L['Got zhenyan wen shenxing, your shengxing will be blacked.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		checked = MY_ShenxingHelper.bAvoidBlackCD,
		oncheck = function(bChecked)
			MY_ShenxingHelper.bAvoidBlackCD = bChecked
		end,
	}):Width() + 5

	if not LIB.IsShieldedVersion('MY_ShenxingHelper') then
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, w = 'auto',
			text = _L['Shenxing to ancient maps'],
			checked = MY_ShenxingHelper.bAncientMap,
			oncheck = function(bChecked)
				MY_ShenxingHelper.bAncientMap = bChecked
			end,
		}):Width() + 5

		x = x + ui:Append('WndCheckBox', {
			x = x, y = y, w = 'auto',
			text = _L['Force open all map shenxing'],
			tip = _L['Shenxing can fly to undiscovered maps'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
			checked = MY_ShenxingHelper.bOpenAllMap,
			oncheck = function(bChecked)
				MY_ShenxingHelper.bOpenAllMap = bChecked
			end,
		}):Width() + 5
	end

	x = X
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
				bAncientMap = D.CheckNonwarMapEnable,
				bOpenAllMap = D.CheckOpenAllMapEnable,
				bAvoidBlackCD = D.CheckAvoidBlackShenxingEnable,
			},
			root = O,
		},
	},
}
MY_ShenxingHelper = LIB.GeneGlobalNS(settings)
end
