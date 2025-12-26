--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ColorPicker
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.ColorPicker')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 打开取色板
function X.UI.OpenColorPicker(callback, t)
	if t then
		return OpenColorTablePanel(callback,nil,nil,t)
	end
	local ui = X.UI.CreateFrame(X.NSFormatString('{$NS}_ColorTable'), {
		theme = X.UI.FRAME_THEME.SIMPLE,
		anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
		w = 900, h = 500,
		close = true, esc = true,
		text = _L['Color Picker'],
	})
	local fnHover = function(bHover, r, g, b)
		if bHover then
			this:SetAlpha(255)
			ui:Children('#Select'):Color(r, g, b)
			ui:Children('#Select_Text'):Text(string.format('r=%d, g=%d, b=%d', r, g, b))
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
				local y = 10 + math.modf((nRed - 1) / 4) * 220 + (nBlue - 1) * 25
				local r, g, b  = nRed * 32 - 1, nGreen * 32 - 1, nBlue * 32 - 1
				ui:Append('Shadow', {
					w = 23, h = 23, x = x, y = y,
					color = { r, g, b },
					alpha = 200,
					onHover = function(bHover)
						fnHover(bHover, r, g, b)
					end,
					onClick = function()
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
			w = 23, h = 23, x = x, y = y,
			color = { r, g, b },
			alpha = 200,
			onHover = function(bHover)
				fnHover(bHover, r, g, b)
			end,
			onClick = function()
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
	ui:Append('WndEditBox', { name = 'R', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, editType = X.UI.EDIT_TYPE.NUMBER, onChange = onChange })
	x = x + 14 + 34
	ui:Append('Text', { text = 'G', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'G', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, editType = X.UI.EDIT_TYPE.NUMBER, onChange = onChange })
	x = x + 14 + 34
	ui:Append('Text', { text = 'B', x = x, y = y, w = 10 })
	ui:Append('WndEditBox', { name = 'B', x = x + 14, y = y + 4, w = 34, h = 25, limit = 3, editType = X.UI.EDIT_TYPE.NUMBER, onChange = onChange })
	x = x + 14 + 34
	ui:Append('WndButton', { text = g_tStrings.STR_HOTKEY_SURE, x = x + 5, y = y + 3, w = 50, h = 30, onClick = function()
		if GetRGBValue() then
			fnClick(GetRGBValue())
		else
			X.OutputSystemMessage(_L['RGB value error'])
		end
	end})
	x = x + 50
	ui:Append('WndButton', { text = _L['Color Picker Pro'], x = x + 5, y = y + 3, w = 50, h = 30, onClick = function()
		X.UI.OpenColorPickerEx(callback):Pos(ui:Pos())
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
function X.UI.OpenColorPickerEx(fnAction)
	local fX, fY = Cursor.GetPos(true)
	local tUI = {}
	local function hsv2rgb(h, s, v)
		s = s / 100
		v = v / 100
		local r, g, b = 0, 0, 0
		local h = h / 60
		local i = math.floor(h)
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
		return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
	end

	local wnd = X.UI.CreateFrame(X.NSFormatString('{$NS}_ColorPickerEx'), {
		theme = X.UI.FRAME_THEME.SIMPLE,
		x = fX + 15, y = fY + 15,
		w = 346, h = 430,
		text = _L['Color Picker Pro'],
		close = true, esc = true,
	})
	local fnHover = function(bHover, r, g, b)
		if bHover then
			wnd:Children('#Select'):Color(r, g, b)
			wnd:Children('#Select_Text'):Text(string.format('r=%d, g=%d, b=%d', r, g, b))
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
						w = 9, h = 9, x = x, y = y,
						color = { r, g, b },
						onHover = function(bHover)
							wnd:Children('#Select_Image'):Pos(this:GetRelPos()):Toggle(bHover)
							local r, g, b = this:GetColorRGB()
							fnHover(bHover, r, g, b)
						end,
						onClick = function()
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
	wnd:Append('WndSlider', {
		x = 20, y = 35, h = 25, w = 306, sliderWidth = 272,
		textFormatter = function(val) return ('%d H'):format(val) end,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = COLOR_HUE, range = {0, 360},
		onChange = function(nVal)
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
