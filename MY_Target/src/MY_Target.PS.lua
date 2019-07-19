--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标面向显示等功能设置面板
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_Target/lang/')
if not LIB.AssertVersion('MY_Target', _L['MY_Target'], 0x2011800) then
	return
end

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local x, y = X, Y
	local deltaY = 26
	ui:append('Text', { x = x, y = y, text = _L['Options'], font = 27 })

	-- target direction
	x, y = X + 10, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Show target direction'],
		checked = MY_TargetDirection.bEnable,
		oncheck = function(bChecked)
			MY_TargetDirection.bEnable = bChecked
		end,
	}, true):autoWidth():width()

	ui:append('WndComboBox', {
		x = x, y = y, w = 200, text = _L['Distance type'],
		menu = function()
			return LIB.GetDistanceTypeMenu(true, MY_TargetDirection.eDistanceType, function(p)
				MY_TargetDirection.eDistanceType = p.szType
			end)
		end,
	}, true):autoWidth()

	if LIB.IsShieldedVersion() then
		return
	end

	-- target line
	x, y = X + 10, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Display the line from self to target'],
		checked = MY_TargetLine.bTarget,
		oncheck = function(bChecked)
			MY_TargetLine.bTarget = bChecked
		end,
	}, true):autoWidth():width()

	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['New style'],
		checked = MY_TargetLine.bTargetRL,
		oncheck = function(bChecked)
			MY_TargetLine.bTargetRL = bChecked
		end,
	}, true):autoWidth():width() + 10

	x = x + ui:append('Shadow', {
		x = x + 2, y = y + 4, w = 18, h = 18,
		color = MY_TargetLine.tTargetColor,
		onclick = function()
			local ui = UI(this)
			UI.OpenColorPicker(function(r, g, b)
				ui:color(r, g, b)
				MY_TargetLine.tTargetColor = { r, g, b }
			end)
		end,
		autoenable = function() return not MY_TargetLine.bTargetRL end,
	}, true):width() + 5

	x = x + ui:append('Text', {
		x = x, y = y - 2,
		text = _L['Change color'],
		autoenable = function() return not MY_TargetLine.bTargetRL end,
	}, true):autoWidth():width()

	x, y = X + 10, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Display the line target self to target target'],
		checked = MY_TargetLine.bTTarget,
		oncheck = function(bChecked)
			MY_TargetLine.bTTarget = bChecked
		end,
	}, true):autoWidth():width()

	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['New style'],
		checked = MY_TargetLine.bTTargetRL,
		oncheck = function(bChecked)
			MY_TargetLine.bTTargetRL = bChecked
		end,
	}, true):autoWidth():width() + 10

	x = x + ui:append('Shadow', {
		x = x + 2, y = y + 4, w = 18, h = 18,
		color = MY_TargetLine.tTTargetColor,
		onclick = function()
			local ui = UI(this)
			UI.OpenColorPicker(function(r, g, b)
				ui:color(r, g, b)
				MY_TargetLine.tTTargetColor = { r, g, b }
			end)
		end,
		autoenable = function() return not MY_TargetLine.bTTargetRL end,
	}, true):width() + 5

	x = x + ui:append('Text', {
		x = x, y = y - 2,
		text = _L['Change color'],
		autoenable = function() return not MY_TargetLine.bTTargetRL end,
	}, true):autoWidth():width()

	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', {
		text = _L['Line width'], x = x, y = y,
		autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
	}, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = MY_TargetLine.nLineWidth,
		range = {1, 5},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		textfmt = function(val) return _L('%d px', val) end,
		onchange = function(val) MY_TargetLine.nLineWidth = val end,
		autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
	})
	x = x + 180
	x = x + ui:append('WndRadioBox', {
		x = x, y = y, w = 100, h = 25, group = 'line postype',
		text = _L['From head to head'],
		checked = MY_TargetLine.bAtHead,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			MY_TargetLine.bAtHead = true
		end,
	}, true):autoWidth():width() + 10


	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', {
		text = _L['Line alpha'], x = x, y = y,
		autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
	}, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = MY_TargetLine.nLineAlpha,
		range = {1, 255},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		onchange = function(val) MY_TargetLine.nLineAlpha = val end,
		autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
	})
	x = x + 180
	x = x + ui:append('WndRadioBox', {
		x = x, y = y, w = 100, h = 25, group = 'line postype',
		text = _L['From foot to foot'],
		checked = not MY_TargetLine.bAtHead,
		oncheck = function(bChecked)
			if not bChecked then
				return
			end
			MY_TargetLine.bAtHead = false
		end,
	}, true):autoWidth():width() + 10

	-- target face
	x, y = X + 10, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Display the sector of target facing, change color'],
		checked = MY_TargetFace.bTargetFace,
		oncheck = function(bChecked)
			MY_TargetFace.bTargetFace = bChecked
		end,
	}, true):autoWidth():width()

	ui:append('Shadow', {
		x = x + 2, y = y + 2, w = 18, h = 18,
		color = MY_TargetFace.tTargetFaceColor,
		onclick = function()
			local ui = UI(this)
			UI.OpenColorPicker(function(r, g, b)
				ui:color(r, g, b)
				MY_TargetFace.tTargetFaceColor = { r, g, b }
			end)
		end,
	})

	-- target target face
	x, y = X + 10, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Display the sector of target target facing, change color'],
		checked = MY_TargetFace.bTTargetFace,
		oncheck = function(bChecked)
			MY_TargetFace.bTTargetFace = bChecked
		end,
	}, true):autoWidth():width()

	ui:append('Shadow', {
		x = x + 2, y = y + 2, w = 18, h = 18,
		color = MY_TargetFace.tTTargetFaceColor,
		onclick = function()
			local ui = UI(this)
			UI.OpenColorPicker(function(r, g, b)
				ui:color(r, g, b)
				MY_TargetFace.tTTargetFaceColor = { r, g, b }
			end)
		end,
	})

	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', { text = _L['The sector angle'], x = x, y = y }, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = MY_TargetFace.nSectorDegree,
		range = {30, 180},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		textfmt = function(val) return _L('%d degree', val) end,
		onchange = function(val) MY_TargetFace.nSectorDegree = val end,
	})

	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', { text = _L['The sector radius'], x = x, y = y }, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = MY_TargetFace.nSectorRadius,
		range = {1, 26},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		textfmt = function(val) return _L('%d feet', val) end,
		onchange = function(val) MY_TargetFace.nSectorRadius = val end,
	})

	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', { text = _L['The sector transparency'], x = x, y = y }, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = ceil((200 - MY_TargetFace.nSectorAlpha) / 2),
		range = {0, 100},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		textfmt = function(val) return _L('%d %%', val) end,
		onchange = function(val) MY_TargetFace.nSectorAlpha = (100 - val) * 2 end,
	})

	-- foot shape
	x, y = X, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Display the foot shape of target, change color'],
		checked = MY_TargetFace.bTargetShape,
		oncheck = function(bChecked) MY_TargetFace.bTargetShape = bChecked end,
	}, true):autoWidth():width()

	ui:append('Shadow', {
		x = x + 2, y = y + 2, w = 18, h = 18,
		color = MY_TargetFace.tTargetShapeColor,
		onclick = function()
			local ui = UI(this)
			UI.OpenColorPicker(function(r, g, b)
				ui:color(r, g, b)
				MY_TargetFace.tTargetShapeColor = { r, g, b }
			end)
		end,
	})

	x, y = X, y + deltaY
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Display the foot shape of target target, change color'],
		checked = MY_TargetFace.bTTargetShape,
		oncheck = function(bChecked) MY_TargetFace.bTTargetShape = bChecked end,
	}, true):autoWidth():width()

	ui:append('Shadow', {
		x = x + 2, y = y + 2, w = 18, h = 18,
		color = MY_TargetFace.tTTargetShapeColor,
		onclick = function()
			local ui = UI(this)
			UI.OpenColorPicker(function(r, g, b)
				ui:color(r, g, b)
				MY_TargetFace.tTTargetShapeColor = { r, g, b }
			end)
		end,
	})

	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', { text = _L['The foot shape radius'], x = x, y = y }, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = MY_TargetFace.nShapeRadius,
		range = {1, 26},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		textfmt = function(val) return _L('%.1f feet', val / 2) end,
		onchange = function(val) MY_TargetFace.nShapeRadius = val end,
	})

	x, y = X + 37, y + deltaY
	x = x + ui:append('Text', { text = _L['The foot shape transparency'], x = x, y = y }, true):autoWidth():width()

	ui:append('WndSliderBox', {
		x = x + 2, y = y + 2,
		value = ceil((200 - MY_TargetFace.nShapeAlpha) / 2),
		range = {0, 100},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		textfmt = function(val) return _L('%d %%', val) end,
		onchange = function(val) MY_TargetFace.nShapeAlpha = (100 - val) * 2 end,
	})
end
LIB.RegisterPanel('MY_Target', _L['MY_Target'], _L['Target'], 2136, PS)
