--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 全局染色设置
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
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps/')

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local nPaddingX, nPaddingY = 20, 20
	local x, y = nPaddingX, nPaddingY

	ui:Append('Text', {
		x = nPaddingX - 10, y = y,
		text = _L['Force color'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	x, y = nPaddingX, y + 30
	for _, dwForceID in X.pairs_c(CONSTANT.FORCE_TYPE) do
		local x0 = x
		local sha = ui:Append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = CONSTANT.FORCE_TYPE_LABEL[dwForceID],
			color = { X.GetForceColor(dwForceID, 'background') },
		})
		local txt = ui:Append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = CONSTANT.FORCE_TYPE_LABEL[dwForceID],
			color = { X.GetForceColor(dwForceID, 'foreground') },
		})
		x = x + 105
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { X.GetForceColor(dwForceID, 'foreground') },
			oncolorpick = function(r, g, b)
				txt:Color(r, g, b)
				X.SetForceColor(dwForceID, 'foreground', { r, g, b })
			end,
		})
		x = x + 30
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { X.GetForceColor(dwForceID, 'background') },
			oncolorpick = function(r, g, b)
				sha:Color(r, g, b)
				X.SetForceColor(dwForceID, 'background', { r, g, b })
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = nPaddingX
			y = y + 35
		end
	end
	ui:Append('WndButton', {
		x = x, y = y, w = 160, h = 25,
		buttonstyle = 'FLAT',
		text = _L['Restore default'],
		onclick = function()
			X.SetForceColor('reset')
			X.SwitchTab('GlobalColor', true)
		end,
	})

	y = y + 45
	ui:Append('Text', {
		x = nPaddingX - 10, y = y,
		text = _L['Camp color'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	x, y = nPaddingX, y + 30
	for _, nCamp in ipairs({ CAMP.NEUTRAL, CAMP.GOOD, CAMP.EVIL }) do
		local x0 = x
		local sha = ui:Append('Shadow', {
			x = x, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { X.GetCampColor(nCamp, 'background') },
		})
		local txt = ui:Append('Text', {
			x = x + 5, y = y, w = 100, h = 25,
			text = g_tStrings.STR_CAMP_TITLE[nCamp],
			color = { X.GetCampColor(nCamp, 'foreground') },
		})
		x = x + 105
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { X.GetCampColor(nCamp, 'foreground') },
			oncolorpick = function(r, g, b)
				txt:Color(r, g, b)
				X.SetCampColor(nCamp, 'foreground', { r, g, b })
			end,
		})
		x = x + 30
		ui:Append('Shadow', {
			x = x, y = y, w = 25, h = 25,
			color = { X.GetCampColor(nCamp, 'background') },
			oncolorpick = function(r, g, b)
				sha:Color(r, g, b)
				X.SetCampColor(nCamp, 'background', { r, g, b })
			end,
		})
		x = x + 40

		if 2 * x - x0 > w then
			x = nPaddingX
			y = y + 35
		end
	end
	ui:Append('WndButton', {
		x = x, y = y, w = 160, h = 25,
		text = _L['Restore default'],
		buttonstyle = 'FLAT',
		onclick = function()
			X.SetCampColor('reset')
			X.SwitchTab('GlobalColor', true)
		end,
	})
end

X.RegisterPanel(_L['System'], 'GlobalColor', _L['Global color'], 'ui\\Image\\button\\CommonButton_1.UITex|70', PS)
