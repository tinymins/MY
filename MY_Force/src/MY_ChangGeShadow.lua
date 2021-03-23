--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 长歌影子头顶次序
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
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false,
	bShowDistance = false,
	bShowCD = false,
	fScale = 1.5,
}
RegisterCustomData('MY_ChangGeShadow.bEnable')
RegisterCustomData('MY_ChangGeShadow.bShowDistance')
RegisterCustomData('MY_ChangGeShadow.bShowCD')
RegisterCustomData('MY_ChangGeShadow.fScale')

function D.Apply()
	if O.bEnable then
		local MAX_LIMIT_TIME = 25
		local hList, hItem, nCount, sha, r, g, b, nDis, szText, fPer
		local hShaList = UI.GetShadowHandle('MY_ChangGeShadow')
		local MAX_SHADOW_COUNT = 10
		local nInterval = (O.bShowDistance or O.bShowCD) and 50 or 400
		LIB.BreatheCall('CHANGGE_SHADOW', nInterval, function()
			local frame = Station.Lookup('Lowest1/ChangGeShadow')
			if not frame then
				if nCount and nCount > 0 then
					for i = 0, nCount - 1 do
						sha = hShaList:Lookup(i)
						if sha then
							sha:Hide()
						end
					end
					nCount = 0
				end
				return
			end
			hList = frame:Lookup('Wnd_Bar', 'Handle_Skill')
			nCount = hList:GetItemCount()
			for i = 0, nCount - 1 do
				hItem = hList:Lookup(i)
				sha = hShaList:Lookup(i)
				if not sha then
					hShaList:AppendItemFromString('<shadow></shadow>')
					sha = hShaList:Lookup(i)
				end
				nDis = LIB.GetDistance(GetNpc(hItem.nNpcID))
				if hItem.szState == 'disable' then
					r, g, b = 191, 31, 31
				else
					if nDis > 25 then
						r, g, b = 255, 255, 31
					else
						r, g, b = 63, 255, 31
					end
				end
				fPer = hItem:Lookup('Image_CD'):GetPercentage()
				szText = tostring(i + 1)
				if O.bShowDistance and nDis >= 0 then
					szText = szText .. g_tStrings.STR_CONNECT .. KeepOneByteFloat(nDis) .. g_tStrings.STR_METER
				end
				if O.bShowCD then
					szText = szText .. g_tStrings.STR_CONNECT .. floor(fPer * MAX_LIMIT_TIME) .. '"'
				end
				sha:Show()
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(hItem.nNpcID, true, r, g, b, 200, 0, 40, szText, 0, O.fScale)
			end
			for i = nCount, MAX_SHADOW_COUNT do
				sha = hShaList:Lookup(i)
				if sha then
					sha:Hide()
				end
			end
		end)
		hShaList:Show()
	else
		LIB.BreatheCall('CHANGGE_SHADOW', false)
		UI.GetShadowHandle('MY_ChangGeShadow'):Hide()
	end
end
LIB.RegisterInit('MY_ChangGeShadow', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Show changge shadow index'],
		checked = MY_ChangGeShadow.bEnable,
		oncheck = function(bChecked)
			MY_ChangGeShadow.bEnable = bChecked
		end,
		tip = function(self)
			if not self:Enable() then
				return _L['Changge force only']
			end
		end,
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}):Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Show distance'],
		checked = MY_ChangGeShadow.bShowDistance,
		oncheck = function(bChecked)
			MY_ChangGeShadow.bShowDistance = bChecked
		end,
		tip = function(self)
			if not self:Enable() then
				return _L['Changge force only']
			end
		end,
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}):Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Show countdown'],
		checked = MY_ChangGeShadow.bShowCD,
		oncheck = function(bChecked)
			MY_ChangGeShadow.bShowCD = bChecked
		end,
		tip = function(self)
			if not self:Enable() then
				return _L['Changge force only']
			end
		end,
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}):Width() + 5
	ui:Append('WndTrackbar', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('Scale: %d%%.', val) end,
		range = {10, 800},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = MY_ChangGeShadow.fScale * 100,
		onchange = function(val)
			MY_ChangGeShadow.fScale = val / 100
		end,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	})
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
				bShowDistance = true,
				bShowCD = true,
				fScale = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				bShowDistance = true,
				bShowCD = true,
				fScale = true,
			},
			triggers = {
				bEnable = D.Apply,
				bShowDistance = D.Apply,
				bShowCD = D.Apply,
				fScale = D.Apply,
			},
			root = O,
		},
	},
}
MY_ChangGeShadow = LIB.GeneGlobalNS(settings)
end
