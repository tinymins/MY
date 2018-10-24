--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÊÔÒÂ¼ä
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/lang/')

local function onFrameCreate()
	local config
	if arg0:GetName() == 'PlayerView' then
		config = { x = 35, y = 8, w = 30, h = 30, coefficient = 2.45 }
	elseif arg0:GetName() == 'ExteriorView' then
		config = { x = 20, y = 15, w = 40, h = 40, coefficient = 2.5 }
	end
	if config then
		local frame, ui, coefficient, posx, posy = arg0, XGUI(arg0), config.coefficient / Station.GetUIScale()
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
