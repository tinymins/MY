--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 长歌影子头顶次序
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
					szText = szText .. g_tStrings.STR_CONNECT .. math.floor(fPer * MAX_LIMIT_TIME) .. '"'
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
		text = _L['show changge shadow index'],
		checked = MY_ChangGeShadow.bEnable,
		oncheck = function(bChecked)
			MY_ChangGeShadow.bEnable = bChecked
		end,
		tip = function(self)
			if not self:Enable() then
				return _L['changge force only']
			end
		end,
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}, true):Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['show distance'],
		checked = MY_ChangGeShadow.bShowDistance,
		oncheck = function(bChecked)
			MY_ChangGeShadow.bShowDistance = bChecked
		end,
		tip = function(self)
			if not self:Enable() then
				return _L['changge force only']
			end
		end,
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}, true):Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['show countdown'],
		checked = MY_ChangGeShadow.bShowCD,
		oncheck = function(bChecked)
			MY_ChangGeShadow.bShowCD = bChecked
		end,
		tip = function(self)
			if not self:Enable() then
				return _L['changge force only']
			end
		end,
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function()
			local me = GetClientPlayer()
			return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
		end,
	}, true):Width() + 5
	ui:Append('WndTrackbar', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('scale: %d%%.', val) end,
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
	x = X
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
