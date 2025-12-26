--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : UI事件ID计算
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MYDev_UIEventID/MYDev_UIEventID'
local PLUGIN_NAME = 'MYDev_UIEventID'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_UIEventID'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local _C = {}
_C.tEventIndex = {
	{ text = _L['OnKeyDown'        ], bit = 13 },
	{ text = _L['OnKeyUp'          ], bit = 14 },

	{ text = _L['OnLButtonDown'    ], bit = 1  },
	{ text = _L['OnLButtonUp'      ], bit = 3  },
	{ text = _L['OnLButtonClick'   ], bit = 5  },
	{ text = _L['OnLButtonDbClick' ], bit = 7  },
	{ text = _L['OnLButtonDrag'    ], bit = 20 },

	{ text = _L['OnRButtonDown'    ], bit = 2  },
	{ text = _L['OnRButtonUp'      ], bit = 4  },
	{ text = _L['OnRButtonClick'   ], bit = 6  },
	{ text = _L['OnRButtonDbClick' ], bit = 8  },
	{ text = _L['OnRButtonDrag'    ], bit = 19 },

	{ text = _L['OnMButtonDown'    ], bit = 15 },
	{ text = _L['OnMButtonUp'      ], bit = 16 },
	{ text = _L['OnMButtonClick'   ], bit = 17 },
	{ text = _L['OnMButtonDbClick' ], bit = 18 },
	{ text = _L['OnMButtonDrag'    ], bit = 21 },

	{ text = _L['OnMouseEnterLeave'], bit = 9  },
	{ text = _L['OnMouseArea'      ], bit = 10 },
	{ text = _L['OnMouseMove'      ], bit = 11 },
	{ text = _L['OnMouseHover'     ], bit = 22 },
	{ text = _L['OnScroll'         ], bit = 12 },
}
_C.nEventID = 0

_C.GetEventID = function(ui)
	local t = {}
	for i, event in ipairs(_C.tEventIndex) do
		if ui:Children('#Event_' .. event.bit):Check() then
			t[event.bit] = 1
		else
			t[event.bit] = 0
		end
	end
	return X.Bitmap2Number(t)
end

_C.SetEventID = function(ui, nEventID)
	local t = X.Number2Bitmap(nEventID)
	for i, event in ipairs(_C.tEventIndex) do
		ui:Children('#Event_' .. event.bit):Check(t[event.bit] == 1)
	end
end

X.Panel.Register(_L['Development'], 'Dev_UIEventID', _L['UIEventID'], 'ui/Image/UICommon/BattleFiled.UITex|7', {
IsRestricted = function()
	return not X.IsDebugging('Dev_UIEventID')
end,
OnPanelActive = function(wnd)
	local ui = X.UI(wnd)
	local x, y = 10, 30

	ui:Append('WndEditBox', {
		x = x, y = y, w = 150, h = 25,
		name = 'WndEdit',
		text = _C.nEventID,
		font = 201, color = { 255, 255, 255 },
		onChange = function(text)
			local nEventID = tonumber(text)
			if nEventID and nEventID ~= _C.nEventID then
				_C.SetEventID(ui, nEventID)
			end
		end,
	})

	x, y = 5, y + 35
	for k, event in ipairs(_C.tEventIndex) do
		ui:Append('WndCheckBox', {
			name = 'Event_' .. event.bit,
			text = event.text, x = x, y = y, w = 120,
			onCheck = function(bCheck)
				if bCheck then
					ui:Children('#Event_' .. event.bit):Color(255, 128, 0  )
				else
					ui:Children('#Event_' .. event.bit):Color(255, 255, 255)
				end
				_C.nEventID = _C.GetEventID(ui)
				ui:Children('#WndEdit'):Text(_C.nEventID)
			end,
		})
		x = x + 90

		if(k - 1) % 5 == 1 or k == 2 then
			x, y = 5, y + 25
		end
	end

	_C.SetEventID(ui, _C.nEventID)
end})

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
