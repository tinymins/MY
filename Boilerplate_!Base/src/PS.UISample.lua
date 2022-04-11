--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面组件库示例
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local COMPONENT_H = 25
local COMPONENT_SAMPLE = {
	{'Shadow', 'Shadow', { w = COMPONENT_H, h = COMPONENT_H, color = { 255, 255, 255 } }},
	{'Text', 'Text', { w = 'auto', h = COMPONENT_H, font = 162, text = 'Text' }},
	{'CheckBox', 'CheckBox', { w = 'auto', h = COMPONENT_H, text = 'CheckBox' }},
	{'ColorBox', 'ColorBox', { w = 'auto', h = COMPONENT_H, text = 'ColorBox', color = {255, 255, 0} }},
	{'ColorBox Sized', 'ColorBox', { w = 'auto', h = COMPONENT_H, rw = 50, rh = 18, text = 'ColorBox', color = {255, 255, 0} }},
	{'Handle', 'Handle', { w = COMPONENT_H, h = COMPONENT_H }},
	{'Box', 'Box', { w = COMPONENT_H, h = COMPONENT_H, frame = 233 }},
	{'Image', 'Image', { w = COMPONENT_H, h = COMPONENT_H, image = X.PACKET_INFO.POSTER_UITEX, imageFrame = GetTime() % X.PACKET_INFO.POSTER_FRAME_COUNT }},
	{'WndAutocomplete', 'WndAutocomplete', { w = 200, h = COMPONENT_H, font = 162, text = 'WndAutocomplete' }},
	{'WndButtonBox', 'WndButtonBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndButtonBox' }},
	{'WndButtonBox Themed', 'WndButtonBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndButtonBox', buttonStyle = 'FLAT' }},
	{'WndButtonBox Option', 'WndButtonBox', { w = COMPONENT_H, h = COMPONENT_H, font = 162, buttonStyle = 'OPTION' }},
	{'WndButton', 'WndButton', { w = 100, h = COMPONENT_H, font = 162, text = 'WndButton' }},
	{'WndCheckBox', 'WndCheckBox', { w = 100, h = COMPONENT_H, font = 162, text = 'WndCheckBox' }},
	{'WndComboBox', 'WndComboBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndComboBox' }},
	{'WndEditBox', 'WndEditBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditBox' }},
	{'WndEditComboBox', 'WndEditComboBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditComboBox' }},
	-- WndListBox
	{'WndRadioBox', 'WndRadioBox', { w = 'auto', h = COMPONENT_H, font = 162, text = 'WndRadioBox' }},
	-- WndScrollHandleBox
	-- WndScrollWindowBox
	{'WndTrackbar', 'WndTrackbar', { w = 200, h = COMPONENT_H, font = 162, text = 'WndTrackbar' }},
	{'WndTrackbar Sized', 'WndTrackbar', { w = 600, h = COMPONENT_H, rw = 400, font = 162, text = 'WndTrackbar' }},
	-- WndWebCef
	-- WndWebPage
	-- WndWindow
}

local PS = {}

function PS.IsRestricted()
	return not X.IsDebugClient('Dev_UISample')
end

-- PS.OnPanelActive(wnd)
-- PS.OnPanelResize(wnd)
-- PS.OnPanelScroll(wnd, scrollX, scrollY)
-- PS.OnPanelBreathe(wnd)
-- PS.OnPanelDeactive(wnd)

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local W, H = ui:Size()
	local nPaddingX, nPaddingY, LH = 20, 20, 30
	local nX, nY = nPaddingX, nPaddingY

	for _, v in ipairs(COMPONENT_SAMPLE) do
		ui:Append('Shadow', { x = nX, y = nY + 22, w = W - nPaddingX * 2, h = 1, color = { 255, 255, 255 }, alpha = 100 })
		nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', h = COMPONENT_H, font = 162, text = v[1] .. ': ' }):Width() + 5
		nX = nX + ui:Append(v[2], v[3]):Pos(nX, nY):Width() + 5
		nX = nPaddingX
		nY = nY + LH
	end
end

X.RegisterPanel(_L['Development'], 'UISample', _L['UI SAMPLE'], '', PS)
