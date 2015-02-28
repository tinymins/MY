--------------------------------------------
-- @Desc  : UI事件ID计算
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-02-28 18:34:18
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Dev_UIEventID/lang/")
local tEventIndex = {
	{ _L["OnKeyDown"        ], 13 },
	{ _L["OnKeyUp"          ], 14 },

	{ _L["OnLButtonDown"    ], 1 },
	{ _L["OnLButtonUp"      ], 3 },
	{ _L["OnLButtonClick"   ], 5 },
	{ _L["OnLButtonDbClick" ], 7 },
	{ _L["OnLButtonDrag"    ], 20 },

	{ _L["OnRButtonDown"    ], 2 },
	{ _L["OnRButtonUp"      ], 4 },
	{ _L["OnRButtonClick"   ], 6 },
	{ _L["OnRButtonDbClick" ], 8 },
	{ _L["OnRButtonDrag"    ], 19 },

	{ _L["OnMButtonDown"    ], 15 },
	{ _L["OnMButtonUp"      ], 16 },
	{ _L["OnMButtonClick"   ], 17 },
	{ _L["OnMButtonDbClick" ], 18 },
	{ _L["OnMButtonDrag"    ], 21 },

	{ _L["OnMouseEnterLeave"], 9 },
	{ _L["OnMouseArea"      ], 10 },
	{ _L["OnMouseMove"      ], 11 },
	{ _L["OnMouseHover"     ], 22 },
	{ _L["OnScroll"         ], 12 },
}

MY.RegisterPanel( "Dev_UIEventID", _L["UIEventID"], _L['Development'], "ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 30
	
	local function BitTable2UInt()
		local tBitTab = {}
		for k, v in ipairs(tEventIndex) do
			if ui:children('#' .. v[1]) then
				if ui:children('#' .. v[1]):check() then
					tBitTab[v[2]] = 1
				else
					tBitTab[v[2]] = 0
				end
			end
		end
		local nUInt = 0
		for i = 1, 24 do
			nUInt = nUInt + (tBitTab[i] or 0) * (2 ^ (i - 1))
		end
		ui:children("#WndEdit"):text(nUInt)
	end
	ui:append("WndEditBox", "WndEdit", { text = '0', x = x, y = y, w = 150, h = 25, font = 201, color = { 255, 255, 255 }})
	
	x, y = 5, y + 35
	for k, v in ipairs(tEventIndex) do
		ui:append("WndCheckBox", v[1], { text = v[1], x = x, y = y, w = 120 }):children('#' .. v[1])
		  :check(function(bCheck)
		  	if bCheck then
		  		ui:children('#' .. v[1]):color(255, 128, 0)
		  	else
		  		ui:children('#' .. v[1]):color(255, 255, 255)
		  	end
		  	BitTable2UInt()
		  end)
		x = x + 90
		
		if(k - 1) % 5 == 1 or k == 2 then
			x, y = 5, y + 25
		end
	end
end })
