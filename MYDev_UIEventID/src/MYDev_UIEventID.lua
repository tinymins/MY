--------------------------------------------
-- @Desc  : UI事件ID计算
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-01 10:10:13
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MYDev_UIEventID/lang/")
_C.tEventIndex = {
	{ text = _L["OnKeyDown"        ], bit = 13 },
	{ text = _L["OnKeyUp"          ], bit = 14 },

	{ text = _L["OnLButtonDown"    ], bit = 1  },
	{ text = _L["OnLButtonUp"      ], bit = 3  },
	{ text = _L["OnLButtonClick"   ], bit = 5  },
	{ text = _L["OnLButtonDbClick" ], bit = 7  },
	{ text = _L["OnLButtonDrag"    ], bit = 20 },

	{ text = _L["OnRButtonDown"    ], bit = 2  },
	{ text = _L["OnRButtonUp"      ], bit = 4  },
	{ text = _L["OnRButtonClick"   ], bit = 6  },
	{ text = _L["OnRButtonDbClick" ], bit = 8  },
	{ text = _L["OnRButtonDrag"    ], bit = 19 },

	{ text = _L["OnMButtonDown"    ], bit = 15 },
	{ text = _L["OnMButtonUp"      ], bit = 16 },
	{ text = _L["OnMButtonClick"   ], bit = 17 },
	{ text = _L["OnMButtonDbClick" ], bit = 18 },
	{ text = _L["OnMButtonDrag"    ], bit = 21 },

	{ text = _L["OnMouseEnterLeave"], bit = 9  },
	{ text = _L["OnMouseArea"      ], bit = 10 },
	{ text = _L["OnMouseMove"      ], bit = 11 },
	{ text = _L["OnMouseHover"     ], bit = 22 },
	{ text = _L["OnScroll"         ], bit = 12 },
}
_C.nEventID = 0

_C.GetEventID = function(ui)
	local t = {}
	for i, event in ipairs(_C.tEventIndex) do
		if ui:children('#Event_' .. event.bit):check() then
			t[event.bit] = 1
		else
			t[event.bit] = 0
		end
	end
	return MY.Math.Bitmap2Number(t)
end

_C.SetEventID = function(ui, nEventID)
	local t = MY.Math.Number2Bitmap(nEventID)
	for i, event in ipairs(_C.tEventIndex) do
		ui:children('#Event_' .. event.bit):check(t[event.bit] == 1)
	end
end

MY.RegisterPanel(
"Dev_UIEventID", _L["UIEventID"], _L['Development'],
"ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 30
	
	ui:append('WndEditBox', {
		name = 'WndEdit',
		text = _C.nEventID, x = x, y = y, w = 150, h = 25, font = 201, color = { 255, 255, 255 }
	}):children('#WndEdit'):change(function(raw, text)
	  	local nEventID = tonumber(text)
	  	if nEventID and nEventID ~= _C.nEventID then
	  		_C.SetEventID(ui, nEventID)
	  	end
	  end)
	
	x, y = 5, y + 35
	for k, event in ipairs(_C.tEventIndex) do
		ui:append("WndCheckBox", {
			name = 'Event_' .. event.bit,
			text = event.text, x = x, y = y, w = 120
		}):children('#Event_' .. event.bit)
		  :check(function(bCheck)
		  	if bCheck then
		  		ui:children('#Event_' .. event.bit):color(255, 128, 0  )
		  	else
		  		ui:children('#Event_' .. event.bit):color(255, 255, 255)
		  	end
		  	_C.nEventID = _C.GetEventID(ui)
		  	ui:children("#WndEdit"):text(_C.nEventID)
		  end)
		x = x + 90
		
		if(k - 1) % 5 == 1 or k == 2 then
			x, y = 5, y + 25
		end
	end
	
	_C.SetEventID(ui, _C.nEventID)
end})
