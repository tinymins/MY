
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random = math.huge, math.pi, math.random
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local IsNil, IsBoolean, IsEmpty, RandomChild = MY.IsNil, MY.IsBoolean, MY.IsEmpty, MY.RandomChild
local IsNumber, IsString, IsTable, IsFunction = MY.IsNumber, MY.IsString, MY.IsTable, MY.IsFunction
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Cataclysm/lang/')
local CFG, PS = Cataclysm_Main, {}
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = XGUI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	y = y + ui:append('Text', { x = x, y = y, text = _L['Interface settings'], font = 27 }, true):height()

	x = X + 10
	y = y + 3
	x = x + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['Official team frame style'],
		group = 'CSS', checked = CFG.eFrameStyle == 'OFFICIAL',
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.eFrameStyle = 'OFFICIAL'
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['Cataclysm team frame style'],
		group = 'CSS', checked = CFG.eFrameStyle == 'CATACLYSM',
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.eFrameStyle = 'CATACLYSM'
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}, true):autoWidth():height()

	x = X + 10
	x = x + ui:append('Text', { x = x, y = y, text = _L['Interface Width']}, true):autoWidth():width() + 5
	y = y + ui:append('WndSliderBox', {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = CFG.fScaleX * 100,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		onchange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = nVal / CFG.fScaleX, CFG.fScaleY / CFG.fScaleY
			CFG.fScaleX = nVal
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:Scale(nNewX, nNewY)
			end
		end,
		textfmt = function(val) return _L('%d%%', val) end,
	}, true):height()

	x = X + 10
	x = x + ui:append('Text', { x = x, y = y, text = _L['Interface Height']}, true):autoWidth():width() + 5
	y = y + ui:append('WndSliderBox', {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = CFG.fScaleY * 100,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		onchange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = CFG.fScaleX / CFG.fScaleX, nVal / CFG.fScaleY
			CFG.fScaleY = nVal
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:Scale(nNewX, nNewY)
			end
		end,
		textfmt = function(val) return _L('%d%%', val) end,
	}, true):height()

	x = X
	y = y + 10
	y = y + ui:append('Text', { x = x, y = y, text = g_tStrings.OTHER, font = 27 }, true):height()

	x = x + 10
	y = y + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show Group Number'],
		checked = CFG.bShowGroupNumber,
		oncheck = function(bCheck)
			CFG.bShowGroupNumber = bCheck
			MY_Cataclysm.ReloadCataclysmPanel()
		end,
	}, true):height()

	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:append('Text', { x = x, y = y, text = g_tStrings.STR_ALPHA }, true):autoWidth():width() + 5
		y = y + ui:append('WndSliderBox', {
			x = x, y = y + 3,
			range = {0, 255},
			value = CFG.nAlpha,
			sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
			onchange = function(nVal)
				CFG.nAlpha = nVal
				if MY_Cataclysm.GetFrame() then
					FireUIEvent('CTM_SET_ALPHA')
				end
			end,
			textfmt = function(val) return _L('%d%%', val / 255 * 100) end,
		}, true):height()
	end

	x = X
	y = y + 10
	y = y + ui:append('Text', { x = x, y = y, text = _L['Arrangement'], font = 27 }, true):height()

	x = x + 10
	y = y + 3
	y = y + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['One lines: 5/0'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 5,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 5
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 1/4'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 1,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 1
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 2/3'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 2,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 2
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 3/2'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 3,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 3
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3

	y = y + ui:append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 4/1'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 4,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 4
			if MY_Cataclysm.GetFrame() then
				Grid_CTM:AutoLinkAllPanel()
				MY_Cataclysm.SetFrameSize()
			end
		end,
	}, true):autoWidth():height() + 3
end
MY.RegisterPanel('MY_Cataclysm_Interface', _L['Interface settings'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|74', {255, 255, 0}, PS)
