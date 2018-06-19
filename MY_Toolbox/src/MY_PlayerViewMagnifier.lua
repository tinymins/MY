---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-06-19 23:58:06
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-06-20 01:50:25
---------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/lang/')

local function onFrameCreate()
	local config
	if arg0:GetName() == 'PlayerView' then
		config = { x = 35, y = 8, w = 30, h = 30, coefficient = 2.3 }
	elseif arg0:GetName() == 'ExteriorView' then
		config = { x = 20, y = 15, w = 40, h = 40, coefficient = 2.25 }
	end
	if config then
		local frame, ui = arg0, XGUI(arg0)
		ui:append(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/ui/Btn_MagnifierUp.ini:WndButton', {
			name = 'Btn_MY_MagnifierUp',
			x = config.x, y = config.y, w = config.w, h = config.h,
			onclick = function()
				frame:EnableDrag(true)
				frame:SetDragArea(0, 0, frame:GetW(), 50)
				frame:Scale(config.coefficient, config.coefficient)
				frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
				ui:find('.Text'):fontScale(config.coefficient)
				ui:children('#Btn_MY_MagnifierUp'):hide()
				ui:children('#Btn_MY_MagnifierDown'):show()
			end,
			tip = _L['Click to enable MY player view magnifier'],
		})
		ui:append(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/ui/Btn_MagnifierDown.ini:WndButton', {
			name = 'Btn_MY_MagnifierDown',
			x = config.x, y = config.y, w = config.w, h = config.h, visible = false,
			onclick = function()
				frame:Scale(1 / config.coefficient, 1 / config.coefficient)
				ui:find('.Text'):fontScale(1)
				ui:children('#Btn_MY_MagnifierUp'):show()
				ui:children('#Btn_MY_MagnifierDown'):hide()
			end,
			tip = _L['Click to disable MY player view magnifier'],
		})
	end
end
MY.RegisterEvent('ON_FRAME_CREATE.MY_PlayerViewMagnifier', onFrameCreate)
