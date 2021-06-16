--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ColorPicker
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

-- 打开取色板
function UI.OpenColorPicker(callback, t)
	if t then
		return OpenColorTablePanel(callback,nil,nil,t)
	end
	local ui = UI.CreateFrame(NSFormatString('{$NS}_ColorTable'), { simple = true, close = true, esc = true })
	  :Size(900, 500):Text(_L['Color Picker']):Anchor({s='CENTER', r='CENTER', x=0, y=0})
	local fnHover = function(bHover, r, g, b)
		if bHover then
			this:SetAlpha(255)
			ui:Children('#Select'):Color(r, g, b)
			ui:Children('#Select_Text'):Text(format('r=%d, g=%d, b=%d', r, g, b))
		else
			this:SetAlpha(200)
			ui:Children('#Select'):Color(255, 255, 255)
			ui:Children('#Select_Text'):Text(g_tStrings.STR_NONE)
		end
	end
	local fnClick = function( ... )
		if callback then callback( ... ) end
		if not IsCtrlKeyDown() then
			ui:Remove()
		end
	end
	for nRed = 1, 8 do
		for nGreen = 1, 8 do
			for nBlue = 1, 8 do
				local x = 20 + ((nRed - 1) % 4) * 220 + (nGreen - 1) * 25
				local y = 10 + modf((nRed - 1) / 4) * 220 + (nBlue - 1) * 25
				local r, g, b  = nRed * 32 - 1, nGreen * 32 - 1, nBlue * 32 - 1
				ui:Append('Shadow', {
					w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200,
					onhover = function(bHover)
						fnHover(bHover, r, g, b)
					end,
					onclick = function()
						fnClick(r, g, b)
					end,
				})
			end
		end
	end

	for i = 1, 16 do
		local x = 480 + (i - 1) * 25
		local y = 435
		local r, g, b  = i * 16 - 1, i * 16 - 1, i * 16 - 1
		ui:Append('Shadow', {
			w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200,
			onhover = function(bHover)
				fnHover(bHover, r, g, b)
			end,
			onclick = function()
				fnClick(r, g, b)
			end,
		})
	end
	ui:Append('Shadow', { name = 'Select', w = 25, h = 25, x = 20, y = 435 })
	ui:Append('Text', { name = 'Select_Text', x = 65, y = 435 })
	local GetRGBValue = function()
		local r, g, b  = tonumber(ui:Children('#R'):Text()), tonumber(ui:Children('#G'):Text()), tonumber(ui:Children('#B'):Text())
		if r and g and b and r <= 255 and g <= 255 and b <= 255 then
			return r, g, b
		end
	end
	local onChange = function()
		if GetRGBValue() then
			local r, g, b = GetRGBValue()
			fnHover(true, r, g, b)
		end
	end
	local x, y = 220, 435
	ui:Append('Text', { text = 'R', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'R', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, edittype = UI.EDIT_TYPE.NUMBER, onchange = onChange })
	x = x + 14 + 34
	ui:Append('Text', { text = 'G', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'G', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, edittype = UI.EDIT_TYPE.NUMBER, onchange = onChange })
	x = x + 14 + 34
	ui:Append('Text', { text = 'B', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'B', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, edittype = UI.EDIT_TYPE.NUMBER, onchange = onChange })
	x = x + 14 + 34
	ui:Append('WndButton', { text = g_tStrings.STR_HOTKEY_SURE, x = x + 5, y = y + 3, w = 50, h = 30, onclick = function()
		if GetRGBValue() then
			fnClick(GetRGBValue())
		else
			LIB.Sysmsg(_L['RGB value error'])
		end
	end})
	x = x + 50
	ui:Append('WndButton', { text = _L['Color Picker Pro'], x = x + 5, y = y + 3, w = 50, h = 30, onclick = function()
		UI.OpenColorPickerEx(callback):Pos(ui:Pos())
		ui:Remove()
	end})
	Station.SetFocusWindow(ui[1])
	-- OpenColorTablePanel(callback,nil,nil,t)
	--  or {
	--     { r = 0,   g = 255, b = 0  },
	--     { r = 0,   g = 255, b = 255},
	--     { r = 255, g = 0  , b = 0  },
	--     { r = 40,  g = 140, b = 218},
	--     { r = 211, g = 229, b = 37 },
	--     { r = 65,  g = 50 , b = 160},
	--     { r = 170, g = 65 , b = 180},
	-- }
	return ui
end

-- 调色板
local COLOR_HUE = 0
function UI.OpenColorPickerEx(fnAction)
	local fX, fY = Cursor.GetPos(true)
	local tUI = {}
	local function hsv2rgb(h, s, v)
		s = s / 100
		v = v / 100
		local r, g, b = 0, 0, 0
		local h = h / 60
		local i = floor(h)
		local f = h - i
		local p = v * (1 - s)
		local q = v * (1 - s * f)
		local t = v * (1 - s * (1 - f))
		if i == 0 or i == 6 then
			r, g, b = v, t, p
		elseif i == 1 then
			r, g, b = q, v, p
		elseif i == 2 then
			r, g, b = p, v, t
		elseif i == 3 then
			r, g, b = p, q, v
		elseif i == 4 then
			r, g, b = t, p, v
		elseif i == 5 then
			r, g, b = v, p, q
		end
		return floor(r * 255), floor(g * 255), floor(b * 255)
	end

	local wnd = UI.CreateFrame(NSFormatString('{$NS}_ColorPickerEx'), { w = 346, h = 430, text = _L['Color Picker Pro'], simple = true, close = true, esc = true, x = fX + 15, y = fY + 15 })
	local fnHover = function(bHover, r, g, b)
		if bHover then
			wnd:Children('#Select'):Color(r, g, b)
			wnd:Children('#Select_Text'):Text(format('r=%d, g=%d, b=%d', r, g, b))
		else
			wnd:Children('#Select'):Color(255, 255, 255)
			wnd:Children('#Select_Text'):Text(g_tStrings.STR_NONE)
		end
	end
	local fnClick = function( ... )
		if fnAction then fnAction( ... ) end
		if not IsCtrlKeyDown() then wnd:Remove() end
	end
	local function SetColor()
		for v = 100, 0, -3 do
			tUI[v] = tUI[v] or {}
			for s = 0, 100, 3 do
				local x = 20 + s * 3
				local y = 80 + (100 - v) * 3
				local r, g, b = hsv2rgb(COLOR_HUE, s, v)
				if tUI[v][s] then
					tUI[v][s]:Color(r, g, b)
				else
					tUI[v][s] = wnd:Append('Shadow', {
						w = 9, h = 9, x = x, y = y, color = { r, g, b },
						onhover = function(bHover)
							wnd:Children('#Select_Image'):Pos(this:GetRelPos()):Toggle(bHover)
							local r, g, b = this:GetColorRGB()
							fnHover(bHover, r, g, b)
						end,
						onclick = function()
							fnClick(this:GetColorRGB())
						end,
					})
				end
			end
		end
	end
	SetColor()
	wnd:Append('Image', { name = 'Select_Image', w = 9, h = 9, x = 0, y = 0 }):Image('ui/Image/Common/Box.Uitex', 9):Toggle(false)
	wnd:Append('Shadow', { name = 'Select', w = 25, h = 25, x = 20, y = 10, color = { 255, 255, 255 } })
	wnd:Append('Text', { name = 'Select_Text', x = 50, y = 10, text = g_tStrings.STR_NONE })
	wnd:Append('WndTrackbar', {
		x = 20, y = 35, h = 25, w = 306, rw = 272,
		textfmt = function(val) return ('%d H'):format(val) end,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = COLOR_HUE, range = {0, 360},
		onchange = function(nVal)
			COLOR_HUE = nVal
			SetColor()
		end,
	})
	for i = 0, 360, 8 do
		wnd:Append('Shadow', { x = 20 + (0.74 * i), y = 60, h = 10, w = 6, color = { hsv2rgb(i, 100, 100) } })
	end
	Station.SetFocusWindow(wnd[1])
	return wnd
end
