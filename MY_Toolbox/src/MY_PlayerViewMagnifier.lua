--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���¼�
-- @author   : ���� @˫���� @׷����Ӱ
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

local function onFrameCreate()
	local config
	if arg0:GetName() == 'PlayerView' then
		config = { x = 35, y = 8, w = 30, h = 30 }
	elseif arg0:GetName() == 'ExteriorView' then
		config = { x = 20, y = 15, w = 40, h = 40 }
	end
	if config then
		local frame, ui, nOriX, nOriY, nOriW, nOriH = arg0, UI(arg0), 0, 0, 0, 0
		local function Fullscreen()
			local nCurW, nCurH = ui:Size()
			local nCW, nCH = Station.GetClientSize()
			local fCoefficient = min(nCW / nCurW, nCH / nCurH)
			local fAbsCoefficient = nCurW / nOriW * fCoefficient
			frame:EnableDrag(true)
			frame:SetDragArea(0, 0, frame:GetW(), 50 * fAbsCoefficient)
			frame:Scale(fCoefficient, fCoefficient)
			ui:Find('.Text'):FontScale(fAbsCoefficient)
			frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
		end
		ui:Append(PACKET_INFO.ROOT .. 'MY_Toolbox/ui/Btn_MagnifierUp.ini:WndButton', {
			name = 'Btn_MY_MagnifierUp',
			x = config.x, y = config.y, w = config.w, h = config.h,
			onclick = function()
				nOriX, nOriY = ui:Pos()
				nOriW, nOriH = ui:Size()
				Fullscreen()
				ui:Children('#Btn_MY_MagnifierUp'):Hide()
				ui:Children('#Btn_MY_MagnifierDown'):Show()
			end,
			tip = _L['Click to enable MY player view magnifier'],
		})
		ui:Append(PACKET_INFO.ROOT .. 'MY_Toolbox/ui/Btn_MagnifierDown.ini:WndButton', {
			name = 'Btn_MY_MagnifierDown',
			x = config.x, y = config.y, w = config.w, h = config.h, visible = false,
			onclick = function()
				local nCW, nCH = ui:Size()
				local fCoefficient = nOriW / nCW
				frame:Scale(fCoefficient, fCoefficient)
				ui:Pos(nOriX, nOriY)
				ui:Find('.Text'):FontScale(1)
				ui:Children('#Btn_MY_MagnifierUp'):Show()
				ui:Children('#Btn_MY_MagnifierDown'):Hide()
				nOriX, nOriY, nOriW, nOriH = nil
			end,
			tip = _L['Click to disable MY player view magnifier'],
		})
		LIB.RegisterEvent('UI_SCALED.MY_PlayerViewMagnifier' .. arg0:GetName(), function()
			if not frame or not frame:IsValid() then
				return 0
			end
			if IsEmpty(nOriX) or IsEmpty(nOriY) or IsEmpty(nOriW) or IsEmpty(nOriH) then
				return
			end
			Fullscreen()
		end)
	end
end
LIB.RegisterFrameCreate('PlayerView.MY_PlayerViewMagnifier', onFrameCreate)
LIB.RegisterFrameCreate('ExteriorView.MY_PlayerViewMagnifier', onFrameCreate)