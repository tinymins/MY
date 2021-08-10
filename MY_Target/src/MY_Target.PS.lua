--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标面向显示等功能设置面板
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Target'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
LIB.RegisterRestriction('MY_Target', { ['*'] = false, classic = true })
--------------------------------------------------------------------------

local PS = { szRestriction = 'MY_Target' }

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local x, y = X, Y
	local deltaY = 26
	ui:Append('Text', { x = x, y = y, text = _L['Options'], font = 27 })

	-- target direction
	x, y = X + 10, y + deltaY
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Show target direction'],
		checked = MY_TargetDirection.bEnable,
		oncheck = function(bChecked)
			MY_TargetDirection.bEnable = bChecked
		end,
	}):AutoWidth():Width()

	ui:Append('WndComboBox', {
		x = x, y = y, w = 200, text = _L['Distance type'],
		menu = function()
			return LIB.GetDistanceTypeMenu(true, MY_TargetDirection.eDistanceType, function(p)
				MY_TargetDirection.eDistanceType = p.szType
			end)
		end,
	}):AutoWidth()

	if not LIB.IsRestricted('MY_TargetLine') then
		-- target line
		x, y = X + 10, y + deltaY
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Display the line from self to target'],
			checked = MY_TargetLine.bTarget,
			oncheck = function(bChecked)
				MY_TargetLine.bTarget = bChecked
			end,
		}):AutoWidth():Width()

		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['New style'],
			checked = MY_TargetLine.bTargetRL,
			oncheck = function(bChecked)
				MY_TargetLine.bTargetRL = bChecked
			end,
		}):AutoWidth():Width() + 10

		x = x + ui:Append('Shadow', {
			x = x + 2, y = y + 4, w = 18, h = 18,
			color = MY_TargetLine.tTargetColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetLine.tTargetColor = { r, g, b }
				end)
			end,
			autoenable = function() return not MY_TargetLine.bTargetRL end,
		}):Width() + 5

		x = x + ui:Append('Text', {
			x = x, y = y - 2,
			text = _L['Change color'],
			autoenable = function() return not MY_TargetLine.bTargetRL end,
		}):AutoWidth():Width()

		x, y = X + 10, y + deltaY
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Display the line target self to target target'],
			checked = MY_TargetLine.bTTarget,
			oncheck = function(bChecked)
				MY_TargetLine.bTTarget = bChecked
			end,
		}):AutoWidth():Width()

		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['New style'],
			checked = MY_TargetLine.bTTargetRL,
			oncheck = function(bChecked)
				MY_TargetLine.bTTargetRL = bChecked
			end,
		}):AutoWidth():Width() + 10

		x = x + ui:Append('Shadow', {
			x = x + 2, y = y + 4, w = 18, h = 18,
			color = MY_TargetLine.tTTargetColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetLine.tTTargetColor = { r, g, b }
				end)
			end,
			autoenable = function() return not MY_TargetLine.bTTargetRL end,
		}):Width() + 5

		x = x + ui:Append('Text', {
			x = x, y = y - 2,
			text = _L['Change color'],
			autoenable = function() return not MY_TargetLine.bTTargetRL end,
		}):AutoWidth():Width()

		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', {
			text = _L['Line width'], x = x, y = y,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		}):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = MY_TargetLine.nLineWidth,
			range = {1, 5},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d px', val) end,
			onchange = function(val) MY_TargetLine.nLineWidth = val end,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		})
		x = x + 180
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, w = 100, h = 25, group = 'line postype',
			text = _L['From head to head'],
			checked = MY_TargetLine.bAtHead,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				MY_TargetLine.bAtHead = true
			end,
		}):AutoWidth():Width() + 10


		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', {
			text = _L['Line alpha'], x = x, y = y,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		}):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = MY_TargetLine.nLineAlpha,
			range = {1, 255},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(val) MY_TargetLine.nLineAlpha = val end,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		})
		x = x + 180
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, w = 100, h = 25, group = 'line postype',
			text = _L['From foot to foot'],
			checked = not MY_TargetLine.bAtHead,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				MY_TargetLine.bAtHead = false
			end,
		}):AutoWidth():Width() + 10
	end

	if not LIB.IsRestricted('MY_TargetFace') then
		-- target face
		x, y = X + 10, y + deltaY
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Display the sector of target facing, change color'],
			checked = MY_TargetFace.bTargetFace,
			oncheck = function(bChecked)
				MY_TargetFace.bTargetFace = bChecked
			end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = x + 2, y = y + 2, w = 18, h = 18,
			color = MY_TargetFace.tTargetFaceColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTargetFaceColor = { r, g, b }
				end)
			end,
		})

		-- target target face
		x, y = X + 10, y + deltaY
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Display the sector of target target facing, change color'],
			checked = MY_TargetFace.bTTargetFace,
			oncheck = function(bChecked)
				MY_TargetFace.bTTargetFace = bChecked
			end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = x + 2, y = y + 2, w = 18, h = 18,
			color = MY_TargetFace.tTTargetFaceColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTTargetFaceColor = { r, g, b }
				end)
			end,
		})

		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', { text = _L['The sector angle'], x = x, y = y }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = MY_TargetFace.nSectorDegree,
			range = {30, 180},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d degree', val) end,
			onchange = function(val) MY_TargetFace.nSectorDegree = val end,
		})

		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', { text = _L['The sector radius'], x = x, y = y }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = MY_TargetFace.nSectorRadius,
			range = {1, 26},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d feet', val) end,
			onchange = function(val) MY_TargetFace.nSectorRadius = val end,
		})

		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', { text = _L['The sector transparency'], x = x, y = y }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = ceil((200 - MY_TargetFace.nSectorAlpha) / 2),
			range = {0, 100},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d %%', val) end,
			onchange = function(val) MY_TargetFace.nSectorAlpha = (100 - val) * 2 end,
		})

		-- foot shape
		x, y = X, y + deltaY
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Display the foot shape of target, change color'],
			checked = MY_TargetFace.bTargetShape,
			oncheck = function(bChecked) MY_TargetFace.bTargetShape = bChecked end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = x + 2, y = y + 2, w = 18, h = 18,
			color = MY_TargetFace.tTargetShapeColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTargetShapeColor = { r, g, b }
				end)
			end,
		})

		x, y = X, y + deltaY
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Display the foot shape of target target, change color'],
			checked = MY_TargetFace.bTTargetShape,
			oncheck = function(bChecked) MY_TargetFace.bTTargetShape = bChecked end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = x + 2, y = y + 2, w = 18, h = 18,
			color = MY_TargetFace.tTTargetShapeColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTTargetShapeColor = { r, g, b }
				end)
			end,
		})

		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', { text = _L['The foot shape radius'], x = x, y = y }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = MY_TargetFace.nShapeRadius,
			range = {1, 26},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%.1f feet', val / 2) end,
			onchange = function(val) MY_TargetFace.nShapeRadius = val end,
		})

		x, y = X + 37, y + deltaY
		x = x + ui:Append('Text', { text = _L['The foot shape transparency'], x = x, y = y }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = x + 2, y = y + 2,
			value = ceil((200 - MY_TargetFace.nShapeAlpha) / 2),
			range = {0, 100},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d %%', val) end,
			onchange = function(val) MY_TargetFace.nShapeAlpha = (100 - val) * 2 end,
		})
	end
end
LIB.RegisterPanel(_L['Target'], 'MY_Target', _L['MY_Target'], 2136, PS)
