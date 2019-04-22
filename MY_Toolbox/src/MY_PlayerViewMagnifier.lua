--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÊÔÒÂ¼ä
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/lang/')

local function onFrameCreate()
	local config
	if arg0:GetName() == 'PlayerView' then
		config = { x = 35, y = 8, w = 30, h = 30, coefficient = 2.45 }
	elseif arg0:GetName() == 'ExteriorView' then
		config = { x = 20, y = 15, w = 40, h = 40, coefficient = 2.5 }
	end
	if config then
		local frame, ui, coefficient, posx, posy = arg0, UI(arg0), config.coefficient / Station.GetUIScale()
		ui:append(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/ui/Btn_MagnifierUp.ini:WndButton', {
			name = 'Btn_MY_MagnifierUp',
			x = config.x, y = config.y, w = config.w, h = config.h,
			onclick = function()
				posx, posy = ui:pos()
				frame:EnableDrag(true)
				frame:SetDragArea(0, 0, frame:GetW(), 50)
				frame:Scale(coefficient, coefficient)
				frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
				ui:find('.Text'):fontScale(coefficient)
				ui:children('#Btn_MY_MagnifierUp'):hide()
				ui:children('#Btn_MY_MagnifierDown'):show()
			end,
			tip = _L['Click to enable MY player view magnifier'],
		})
		ui:append(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/ui/Btn_MagnifierDown.ini:WndButton', {
			name = 'Btn_MY_MagnifierDown',
			x = config.x, y = config.y, w = config.w, h = config.h, visible = false,
			onclick = function()
				frame:Scale(1 / coefficient, 1 / coefficient)
				ui:pos(posx, posy)
				ui:find('.Text'):fontScale(1)
				ui:children('#Btn_MY_MagnifierUp'):show()
				ui:children('#Btn_MY_MagnifierDown'):hide()
			end,
			tip = _L['Click to disable MY player view magnifier'],
		})
	end
end
MY.RegisterEvent('ON_FRAME_CREATE.MY_PlayerViewMagnifier', onFrameCreate)
