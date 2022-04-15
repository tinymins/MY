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
	{
		'WndTable',
		'WndTable',
		{
			w = 600, h = 400,
			columns = {
				{
					key = 'price',
					title = 'Account Price',
					titleRich = true,
					titleTip = 'ACCOUNT PRICE!!!',
					minWidth = 150,
					alignHorizontal = 'left',
					alignVertical = 'top',
				},
				{
					key = 'text',
					title = GetFormatText('Account Stamina', 162, 255, 255, 0),
					titleRich = true,
					titleTip = GetFormatText('ACCOUNT STAMINA!!!', 162, 255, 255, 0),
					titleTipRich = true,
					minWidth = 150,
					render = function(value, record, index)
						if value == '2' then
							return GetFormatText('--', 162, 255, 255, 255)
						end
						return GetFormatText(record.text .. '/' .. record.text, 162, 255, 255, 255)
					end,
					sorter = function(v1, v2, r1, r2)
						v1, v2 = tonumber(v1), tonumber(v2)
						if v1 == v2 then
							return 0
						end
						return v1 < v2 and -1 or 1
					end,
				},
				{
					key = 'price',
					title = function() return GetFormatText('Account Price', 162, 255, 255, 0), true end,
					titleTip = function() return GetFormatText('ACCOUNT PRICE!!!', 162, 255, 255, 0), true end,
					minWidth = 150,
					alignHorizontal = 'center',
					alignVertical = 'middle',
				},
				{
					key = 'price',
					title = 'Account Price',
					minWidth = 300,
					alignHorizontal = 'right',
					alignVertical = 'bottom',
				},
			},
			dataSource = {
				{ text = '1', price = '$1' },
				{ text = '2', price = '$2' },
				{ text = '3', price = '$3' },
				{ text = '4', price = '$4' },
				{ text = '5', price = '$5' },
				{ text = '6', price = '$6' },
				{ text = '7', price = '$7' },
				{ text = '8', price = '$8' },
				{ text = '9', price = '$9' },
				{ text = '10', price = '$10' },
				{ text = '11', price = '$11' },
				{ text = '12', price = '$12' },
				{ text = '13', price = '$13' },
				{ text = '14', price = '$14' },
				{ text = '15', price = '$15' },
				{ text = '16', price = '$16' },
				{ text = '17', price = '$17' },
				{ text = '18', price = '$18' },
				{ text = '19', price = '$19' },
				{ text = '20', price = '$20' },
				{ text = '21', price = '$21' },
				{ text = '22', price = '$22' },
				{ text = '23', price = '$23' },
				{ text = '24', price = '$24' },
				{ text = '25', price = '$25' },
				{ text = '26', price = '$26' },
				{ text = '27', price = '$27' },
				{ text = '28', price = '$28' },
				{ text = '29', price = '$29' },
				{ text = '30', price = '$30' },
				{ text = '31', price = '$31' },
				{ text = '32', price = '$32' },
			},
			summary = { text = '32', price = '$32' },
		},
	},
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
		nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', h = COMPONENT_H, font = 162, text = v[1] .. ': ' }):Width() + 5
		if v[3].h > COMPONENT_H then
			nX = nPaddingX
			nY = nY + COMPONENT_H
			ui:Append('Shadow', { x = nPaddingX, y = nY + v[3].h, w = W - nPaddingX * 2, h = 1, color = { 255, 255, 255 }, alpha = 100 })
		else
			ui:Append('Shadow', { x = nPaddingX, y = nY + 22, w = W - nPaddingX * 2, h = 1, color = { 255, 255, 255 }, alpha = 100 })
		end
		nX = nX + ui:Append(v[2], v[3]):Pos(nX, nY):Width() + 5
		nX = nPaddingX
		nY = nY + LH
	end
end

X.RegisterPanel(_L['Development'], 'UISample', _L['UI SAMPLE'], '', PS)
