---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-02-08 16:49:55
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-02-08 17:05:32
---------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = XGUI(wnd)
	local X, Y = 20, 30
	local x, y = X, Y

	y = y + ui:append('Text', { x = x, y = y, text = _L['MY_TeamTools'], font = 27 }, true):height() + 5
	x = X + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_TeamNotice.bEnable,
		text = _L['Team Message'],
		oncheck = function(bChecked)
			MY_TeamNotice.bEnable = bChecked
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_CharInfo.bEnable,
		text = _L['Allow view charinfo'],
		oncheck = function(bChecked)
			MY_CharInfo.bEnable = bChecked
		end,
	}, true):autoWidth():height()

	x = X
	y = y + 20
	y = y + ui:append('Text', { x = x, y = y, text = _L['Party Request'], font = 27 }, true):height() + 5
	x = X + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bEnable,
		text = _L['Party Request'],
		oncheck = function(bChecked)
			MY_PartyRequest.bEnable = bChecked
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		checked = MY_PartyRequest.bAutoCancel,
		text = _L['Auto Refuse No full level Player'],
		oncheck = function(bChecked)
			MY_PartyRequest.bAutoCancel = bChecked
		end,
	}, true):autoWidth():width()
end
MY.RegisterPanel('MY_TeamTools', _L['MY_TeamTools'], _L['Raid'], 5962, {255, 255, 0}, PS)
