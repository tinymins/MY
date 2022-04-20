--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÊÔÒÂ¼ä
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
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
			local fCoefficient = math.min(nCW / nCurW, nCH / nCurH)
			local fAbsCoefficient = nCurW / nOriW * fCoefficient
			frame:EnableDrag(true)
			frame:SetDragArea(0, 0, frame:GetW(), 50 * fAbsCoefficient)
			frame:Scale(fCoefficient, fCoefficient)
			ui:Find('.Text'):FontScale(fAbsCoefficient)
			frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
		end
		ui:Append(PLUGIN_ROOT .. '/ui/Btn_MagnifierUp.ini:WndButton', {
			name = 'Btn_MY_MagnifierUp',
			x = config.x, y = config.y, w = config.w, h = config.h,
			onClick = function()
				nOriX, nOriY = ui:Pos()
				nOriW, nOriH = ui:Size()
				Fullscreen()
				ui:Children('#Btn_MY_MagnifierUp'):Hide()
				ui:Children('#Btn_MY_MagnifierDown'):Show()
			end,
			tip = _L['Click to enable MY player view magnifier'],
		})
		ui:Append(X.PACKET_INFO.ROOT .. 'MY_Toolbox/ui/Btn_MagnifierDown.ini:WndButton', {
			name = 'Btn_MY_MagnifierDown',
			x = config.x, y = config.y, w = config.w, h = config.h, visible = false,
			onClick = function()
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
		X.RegisterEvent('UI_SCALED', 'MY_PlayerViewMagnifier' .. arg0:GetName(), function()
			if not frame or not frame:IsValid() then
				return 0
			end
			if X.IsEmpty(nOriX) or X.IsEmpty(nOriY) or X.IsEmpty(nOriW) or X.IsEmpty(nOriH) then
				return
			end
			Fullscreen()
		end)
	end
end
X.RegisterFrameCreate('PlayerView', 'MY_PlayerViewMagnifier', onFrameCreate)
X.RegisterFrameCreate('ExteriorView', 'MY_PlayerViewMagnifier', onFrameCreate)
