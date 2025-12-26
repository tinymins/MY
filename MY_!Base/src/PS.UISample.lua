--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面组件库示例
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/PS.UISample')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 注册请求
--------------------------------------------------------------------------------
X.UI.RegisterRequest('SampleRequest', {
	szIconUITex = 'ui\\Image\\button\\SystemButton.UITex',
	nIconFrame = 55,
	Drawer = function(container, info)
		local ui = X.UI(container):Append('WndWindow', { w = 450, h = 50 })

		ui:Append('WndButton', {
			name = 'Btn_Accept',
			x = 326, y = 9, w = 60, h = 34,
			buttonStyle = 'FLAT',
			text = g_tStrings.STR_ACCEPT,
			onClick = function()
				X.UI.RemoveRequest('SampleRequest', info.szKey)
			end,
		})
		ui:Append('WndButton', {
			name = 'Btn_Refuse',
			x = 393, y = 9, w = 60, h = 34,
			buttonStyle = 'FLAT',
			text = g_tStrings.STR_REFUSE,
			onClick = function()
				X.UI.RemoveRequest('SampleRequest', info.szKey)
			end,
		})
		container.info = info

		return ui:Raw()
	end,
	GetTip = function(info)
		return GetFormatText(info.szDesc)
	end,
	GetIcon = function(info, szImage, nFrame)
		return 'FromIconID', 591
	end,
	-- GetMenu = function()
	-- 	return {}
	-- end,
	OnClear = function()
		-- Output('Clear!')
	end,
})


local COMPONENT_H = 25
local COMPONENT_SAMPLE = {
	{'Shadow', 'Shadow', { w = COMPONENT_H, h = COMPONENT_H, color = { 255, 255, 255 } }},
	{'Text', 'Text', { w = 'auto', h = COMPONENT_H, font = 162, text = 'Text' }},
	{'CheckBox', 'CheckBox', { w = 'auto', h = COMPONENT_H, text = 'CheckBox' }},
	{'ColorBox', 'ColorBox', { w = 'auto', h = COMPONENT_H, text = 'ColorBox', color = {255, 255, 0} }},
	{'ColorBox Sized', 'ColorBox', { w = 'auto', h = COMPONENT_H, text = 'ColorBox', color = {255, 255, 0} }},
	{'Handle', 'Handle', { w = COMPONENT_H, h = COMPONENT_H }},
	{'Box', 'Box', { w = COMPONENT_H, h = COMPONENT_H, frame = 233 }},
	{'Image', 'Image', { w = COMPONENT_H, h = COMPONENT_H, image = X.PACKET_INFO.POSTER_IMAGE_LIST[1], imageFrame = 0 }},
	{
		'WndFrame Intact (Default)',
		'WndButton',
		{
			w = 100, h = COMPONENT_H, name = 'WndButton_CreateFrame', text = 'Create',
			onClick = function()
				X.UI.CreateFrame('IntactFrame', {
					text = 'Intact Frame Sample',
					minimize = true,
					maximize = true,
					resize = true,
				})
			end,
		},
	},
	{
		'WndFrame Simple',
		'WndButton',
		{
			w = 'auto', h = COMPONENT_H, name = 'WndButton_CreateSimpleFrame', text = 'Create',
			onClick = function()
				X.UI.CreateFrame('SimpleFrame', {
					text = 'Simple Frame Sample',
					theme = X.UI.FRAME_THEME.SIMPLE,
					close = true,
					minimize = true,
					maximize = true,
					resize = true,
				})
			end,
		},
	},
	{
		'WndFrame Float',
		'WndButton',
		{
			w = 'auto', h = COMPONENT_H, name = 'WndButton_CreateSimpleFrame', text = 'Create',
			onClick = function()
				X.UI.CreateFrame('FloatFrame', {
					text = 'Float Frame Sample',
					theme = X.UI.FRAME_THEME.FLOAT,
					close = true,
					minimize = true,
					maximize = true,
					resize = true,
				})
			end,
		},
	},
	{
		'UI.Browser',
		'WndButton',
		{
			w = 'auto', h = COMPONENT_H, name = 'WndButton_CreateUIBrowser', text = 'Create',
			onClick = function()
				X.UI.OpenBrowser('https://jx3.xoyo.com')
			end,
		},
	},
	{
		'UI.CreateNotify',
		'WndButton',
		{
			w = 'auto', h = COMPONENT_H, name = 'WndButton_CreateNotify', text = 'Create',
			onClick = function()
				X.CreateNotify({
					szKey = 'DEMO',
					szMsg = GetFormatText('DEMO!!!'),
					fnAction = function() end,
					bPlaySound = true,
					bPopupPreview = true,
				})
			end,
		},
	},
	{
		'UI.CreateRequest',
		'WndButton',
		{
			w = 'auto', h = COMPONENT_H, name = 'WndButton_CreateRequest', text = 'Create',
			onClick = function()
				X.UI.ReplaceRequest('SampleRequest', 'DEMO_KEY', {
					szKey = 'DEMO_KEY',
					szDesc = 'Description for DEMO!!!'
				})
			end,
		},
	},
	{
		'UI.TextEditor',
		'WndButton',
		{
			w = 'auto', h = COMPONENT_H, name = 'WndButton_TextEditor', text = 'Create',
			onClick = function()
				X.UI.OpenTextEditor('Hello world!')
			end,
		},
	},
	{'WndAutocomplete', 'WndAutocomplete', { w = 200, h = COMPONENT_H, font = 162, text = 'WndAutocomplete' }},
	{'WndButtonBox', 'WndButtonBox', { w = 'auto', h = 'auto', font = 162, text = 'WndButtonBox' }},
	{'WndButtonBox Themed', 'WndButtonBox', { w = 'auto', h = 'auto', font = 162, text = 'WndButtonBox', buttonStyle = 'FLAT' }},
	{'WndButtonBox Option', 'WndButtonBox', { w = COMPONENT_H, h = COMPONENT_H, font = 162, buttonStyle = 'OPTION' }},
	{'WndButton', 'WndButton', { w = 'auto', h = 'auto', font = 162, text = 'WndButton' }},
	{'WndCheckBox', 'WndCheckBox', { w = 'auto', h = 'auto', font = 162, text = 'WndCheckBox' }},
	{'WndComboBox', 'WndComboBox', { w = 'auto', h = 'auto', font = 162, text = 'WndComboBox' }},
	{'WndEditBox', 'WndEditBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditBox' }},
	{'WndEditBox Left Search', 'WndEditBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditBox', appearance = 'SEARCH_LEFT' }},
	{'WndEditBox Right Search', 'WndEditBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditBox', appearance = 'SEARCH_RIGHT' }},
	{'WndEditComboBox', 'WndEditComboBox', { w = 200, h = COMPONENT_H, font = 162, text = 'WndEditComboBox' }},
	-- WndListBox
	{'WndRadioBox', 'WndRadioBox', { w = 'auto', h = 'auto', font = 162, text = 'WndRadioBox No Group' }},
	{'WndRadioBox', 'WndRadioBox', { w = 'auto', h = 'auto', font = 162, text = 'WndRadioBox No Group' }},
	{'WndRadioBox', 'WndRadioBox', { w = 'auto', h = 'auto', group = '1', font = 162, text = 'WndRadioBox Group1' }},
	{'WndRadioBox', 'WndRadioBox', { w = 'auto', h = 'auto', group = '1', font = 162, text = 'WndRadioBox Group1' }},
	-- WndScrollHandleBox
	-- WndScrollWindowBox
	{'WndSlider', 'WndSlider', { w = 200, h = COMPONENT_H, font = 162, text = 'WndSlider' }},
	{'WndSlider Sized', 'WndSlider', { w = 600, h = COMPONENT_H, sliderWidth = 400, font = 162, text = 'WndSlider' }},
	{
		'WndTabs/WndTab',
		'WndButton',
		{
			w = 100, h = COMPONENT_H, name = 'WndButton_CreateTabs', text = 'Create',
			onClick = function()
				local ui = X.UI.CreateFrame('SampleTabsFrame', {
					w = 800, h = 500,
					minimize = true,
					maximize = true,
					resize = false,
				})
				local uiTabs = ui:Append('WndTabs', {
					x = 0, y = 50,
					w = 800, h = 35,
				})
				for i = 1, 5 do
					uiTabs:Append('WndTab', {
						w = 100, h = 35,
						text = 'SAMPLE-' .. i,
					})
				end
			end,
		},
	},
	-- WndWebCef
	-- WndWebPage
	-- WndWindow
	{
		'WndTable',
		'WndTable',
		{
			w = 720, h = 400,
			columns = {
				{
					key = 'name',
					title = 'Fixed L',
					titleTip = 'NAME!!!',
					width = 80,
					alignHorizontal = 'left',
					alignVertical = 'top',
					sorter = true,
					fixed = true,
					draggable = true,
				},
				{
					key = 'desc',
					title = GetFormatText('Description', 162, 255, 255, 0),
					titleRich = true,
					titleTip = {
						render = GetFormatText('DESCRIPTION!!!', 162, 255, 255, 0),
						rich = true,
					},
					minWidth = 150,
					render = function(value, record, index)
						if value == 'desc 2' then
							return GetFormatText('--', 162, 255, 255, 255)
						end
						return GetFormatText(value .. '/' .. record.price, 162, 255, 255, 255)
					end,
					sorter = function(v1, v2, r1, r2)
						v1, v2 = tonumber((v1:sub(1, 4))), tonumber((v2:sub(1, 4)))
						if v1 == v2 then
							return 0
						end
						return v1 < v2 and -1 or 1
					end,
					draggable = true,
				},
				{
					key = 'price',
					title = function() return GetFormatText('Price', 162, 255, 255, 0), true end,
					titleTip = function() return GetFormatText('PRICE!!!', 162, 255, 255, 0), true end,
					minWidth = 150,
					alignHorizontal = 'center',
					alignVertical = 'middle',
					sorter = true,
					draggable = true,
				},
				{
					key = 'from',
					title = 'From',
					minWidth = 200,
					alignHorizontal = 'center',
					alignVertical = 'middle',
					sorter = true,
					tip = function(value, record, index)
						return GetFormatText(value, 162, 255, 255, 0), true
					end,
				},
				{
					key = 'extra',
					title = 'Extra',
					minWidth = 300,
					alignHorizontal = 'right',
					alignVertical = 'bottom',
					render = function()
						return GetFormatText('EXTRA EXTRA EXTRA', 162, 255, 255, 0)
					end,
				},
				{
					key = 'name',
					title = 'Fixed R',
					titleTip = 'NAME!!!',
					width = 80,
					alignHorizontal = 'left',
					alignVertical = 'middle',
					sorter = true,
					fixed = 'right',
				},
			},
			dataSource = {
				{ name = 'name 1', desc = 'desc 1', price = 1, from = 'China' },
				{ name = 'name 2', desc = 'desc 2', price = 2, from = 'England' },
				{ name = 'name 3', desc = 'desc 3', price = 3, from = 'China' },
				{ name = 'name 4', desc = 'desc 4', price = 4, from = 'England' },
				{ name = 'name 5', desc = 'desc 5', price = 5, from = 'China' },
				{ name = 'name 6', desc = 'desc 6', price = 6, from = 'United States' },
				{ name = 'name 7', desc = 'desc 7', price = 7, from = 'Cuba' },
				{ name = 'name 8', desc = 'desc 8', price = 8, from = 'Japan' },
				{ name = 'name 9', desc = 'desc 9', price = 9, from = 'China' },
				{ name = 'name 10', desc = 'desc 10', price = 10, from = 'China' },
				{ name = 'name 11', desc = 'desc 11', price = 11, from = 'China' },
				{ name = 'name 12', desc = 'desc 12', price = 12, from = 'Japan' },
				{ name = 'name 13', desc = 'desc 13', price = 13, from = 'United States' },
				{ name = 'name 14', desc = 'desc 14', price = 14, from = 'Japan' },
				{ name = 'name 15', desc = 'desc 15', price = 15, from = 'United States' },
				{ name = 'name 16', desc = 'desc 16', price = 16, from = 'Japan' },
				{ name = 'name 17', desc = 'desc 17', price = 17, from = 'Japan' },
				{ name = 'name 18', desc = 'desc 18', price = 18, from = 'United States' },
				{ name = 'name 19', desc = 'desc 19', price = 19, from = 'United States' },
				{ name = 'name 20', desc = 'desc 20', price = 20, from = 'Japan' },
				{ name = 'name 21', desc = 'desc 21', price = 21, from = 'United States' },
				{ name = 'name 22', desc = 'desc 22', price = 22, from = 'China' },
				{ name = 'name 23', desc = 'desc 23', price = 23, from = 'Cuba' },
				{ name = 'name 24', desc = 'desc 24', price = 24, from = 'China' },
				{ name = 'name 25', desc = 'desc 25', price = 25, from = 'England' },
				{ name = 'name 26', desc = 'desc 26', price = 26, from = 'China' },
				{ name = 'name 27', desc = 'desc 27', price = 27, from = 'Cuba' },
				{ name = 'name 28', desc = 'desc 28', price = 28, from = 'England' },
				{ name = 'name 29', desc = 'desc 29', price = 29, from = 'United States' },
				{ name = 'name 30', desc = 'desc 30', price = 30, from = 'England' },
				{ name = 'name 31', desc = 'desc 31', price = 31, from = 'England' },
				{ name = 'name 32', desc = 'desc 32', price = 32, from = 'Cuba' },
			},
			summary = { name = 'Summary', desc = '--', price = 528, from = 'Earth' },
			sort = 'price',
			sortOrder = 'asc',
			onSortChange = function(szSort, szSortOrder)
				X.OutputSystemAnnounceMessage('Sort: ' .. szSort .. ' (order) ' .. szSortOrder)
			end,
			rowTip = {
				render = function(rec)
					return X.EncodeJSON(rec, '    '), false
				end,
				position = X.UI.TIP_POSITION.LEFT_RIGHT,
			},
			rowMenuRClick = function(rec, index)
				local menu = {
					{
						szOption = _L['Delete'],
						fnAction = function()
							X.OutputSystemAnnounceMessage('Delete: ' .. rec.name .. ' (index) ' .. index)
						end,
						rgb = { 255, 128, 128 },
					},
				}
				X.UI.PopupMenu(menu)
			end,
			onColumnsChange = function(aColumns)
				local aKeys = {}
				for _, v in ipairs(aColumns) do
					table.insert(aKeys, v.key)
				end
				X.OutputSystemMessage('ColumnsChange: ' .. table.concat(aKeys, ','))
			end,
		},
	},
	{
		'DragDrop',
		'Image',
		{
			w = 100, h = 100, name = 'Image_DragDrop_1',
			image = 'ui\\Image\\UICommon\\CommonPanel4.UITex|3',
			onDrag = function()
				return 'data 1', this
			end,
			onDrop = function(dragID, data)
				X.OutputSystemMessage('Drop 1, ' .. tostring(dragID) .. ', ' .. X.EncodeLUAData(data))
			end,
		},
	},
	{
		'DragDrop',
		'Image',
		{
			w = 100, h = 100, name = 'Image_DragDrop_2',
			image = 'ui\\Image\\UICommon\\CommonPanel4.UITex|3',
			onDrag = function()
				local frame = this:GetRoot()
				local capture = {
					element = frame,
					x = this:GetAbsX() - frame:GetAbsX(),
					y = this:GetAbsY() - frame:GetAbsY() - 220,
					w = this:GetW(),
					h = this:GetH() * 2 + 50,
				}
				return 'data 2', capture
			end,
			onDragHover = function()
				local frame = this:GetRoot()
				local rect = {
					x = frame:GetAbsX(),
					y = frame:GetAbsY(),
					w = frame:GetW(),
					h = frame:GetH(),
				}
				return rect
			end,
			onDrop = function(dragID, data)
				X.OutputSystemMessage('Drop 2, ' .. tostring(dragID) .. ', ' .. X.EncodeLUAData(data))
			end,
		},
	},
}

local PS = {}

function PS.IsRestricted()
	return not X.IsDebugging('Dev_UISample')
end

-- PS.OnPanelActive(wnd)
-- PS.OnPanelResize(wnd)
-- PS.OnPanelScroll(wnd, scrollX, scrollY)
-- PS.OnPanelBreathe(wnd)
-- PS.OnPanelDeactive(wnd)

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local W, H = ui:Size()
	local nPaddingX, nPaddingY, LH = 20, 20, 30
	local nX, nY = nPaddingX, nPaddingY

	for _, v in ipairs(COMPONENT_SAMPLE) do
		nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', h = COMPONENT_H, font = 162, text = v[1] .. ': ' }):Width() + 5
		if X.IsNumber(v[3].h) and v[3].h > COMPONENT_H then
			nX = nPaddingX
			nY = nY + COMPONENT_H
		end
		nY = nY + math.max(LH, ui:Append(v[2], v[3]):Pos(nX, nY):Height() + 5)
		nX = nPaddingX
		ui:Append('Shadow', { x = nPaddingX, y = nY, w = W - nPaddingX * 2, h = 1, color = { 255, 255, 255 }, alpha = 50 })
		nY = nY + 3
	end

	ui:Append('WndWindow', { x = 0, y = nY + COMPONENT_H, w = W, h = H / 3 })
end

X.Panel.Register(_L['Development'], 'UISample', _L['UI SAMPLE'], '', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
