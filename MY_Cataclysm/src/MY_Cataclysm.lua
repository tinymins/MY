--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板模块
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

MY_Cataclysm = {}
MY_Cataclysm.CFG = {}
MY_Cataclysm.bEnable = false
MY_Cataclysm.szConfigName = 'common'
MY_Cataclysm.bFold = false
MY_Cataclysm.BG_COLOR_MODE = {
	SAME_COLOR = 0,
	BY_DISTANCE = 1,
	BY_FORCE = 2,
	OFFICIAL = 3,
}
RegisterCustomData('MY_Cataclysm.bEnable')
RegisterCustomData('MY_Cataclysm.szConfigName')


-- 解析
function MY_Cataclysm.EncodeBuffRule(v, bNoBasic)
	local a = {}
	if not bNoBasic then
		insert(a, v.szName or v.dwID)
		if v.nLevel then
			insert(a, 'lv' .. v.nLevel)
		end
	end
	if v.nStackNum then
		insert(a, 'sn' .. (v.szStackOp or '>=') .. v.nStackNum)
	end
	if v.bOnlyMe then
		insert(a, 'me')
	end
	if v.bOnlyMine or v.bOnlySelf or v.bSelf then
		insert(a, 'mine')
	end
	a = { concat(a, '|') }

	if v.col then
		local cols = { v.col }
		if v.nColAlpha and v.col:sub(1, 1) ~= '#' then
			insert(cols, v.nColAlpha)
		end
		insert(a, '[' .. concat(cols, '|') .. ']')
	end
	if not IsEmpty(v.szReminder) then
		insert(a, '(' .. v.szReminder .. ')')
	end
	if v.nPriority then
		insert(a, '#' .. v.nPriority)
	end
	if v.bAttention then
		insert(a, '!!')
	end
	if v.bCaution then
		insert(a, '!!!')
	end
	if v.bScreenHead then
		if v.colScreenHead then
			insert(a, '!!!!|[' .. v.colScreenHead .. ']')
		else
			insert(a, '!!!!')
		end
	end
	if v.bDelete then
		insert(a, '-')
	end
	return concat(a, ',')
end

function MY_Cataclysm.DecodeBuffRule(line)
	line = LIB.TrimString(line)
	if line ~= '' then
		local tab = {}
		local vals = LIB.SplitString(line, ',')
		for i, val in ipairs(vals) do
			if i == 1 then
				local vs = LIB.SplitString(val, '|')
				for j, v in ipairs(vs) do
					v = LIB.TrimString(v)
					if v ~= '' then
						if j == 1 then
							tab.dwID = tonumber(v)
							if not tab.dwID then
								tab.szName = v
							end
						elseif v == 'self' or v == 'mine' then
							tab.bOnlyMine = true
						elseif v:sub(1, 2) == 'lv' then
							tab.nLevel = tonumber((v:sub(3)))
						elseif v:sub(1, 2) == 'sn' then
							if tonumber(v:sub(4, 4)) then
								tab.szStackOp = v:sub(3, 3)
								tab.nStackNum = tonumber((v:sub(4)))
							else
								tab.szStackOp = v:sub(3, 4)
								tab.nStackNum = tonumber((v:sub(5)))
							end
						end
					end
				end
			elseif val == '!!' then
				tab.bAttention = true
			elseif val == '!!!' then
				tab.bCaution = true
			elseif val == '!!!!' or val:sub(1, 5) == '!!!!|' then
				tab.bScreenHead = true
				local vs = LIB.SplitString(val, '|')
				for _, v in ipairs(vs) do
					if v:sub(1, 1) == '[' and v:sub(-1, -1) == ']' then
						tab.colScreenHead = v:sub(2, -2)
					end
				end
			elseif val == '-' then
				tab.bDelete = true
			elseif val:sub(1, 1) == '#' then
				tab.nPriority = tonumber((val:sub(2)))
			elseif val:sub(1, 1) == '[' and val:sub(-1, -1) == ']' then
				val = val:sub(2, -2)
				if val:sub(1, 1) == '#' then
					tab.col = val
				else
					local vs = LIB.SplitString(val, '|')
					tab.col = vs[1]
					tab.nColAlpha = vs[2] and tonumber(vs[2])
				end
			elseif val:sub(1, 1) == '(' and val:sub(-1, -1) == ')' then
				tab.szReminder = val:sub(2, -2)
			end
		end
		if tab.dwID or tab.szName then
			return tab
		end
	end
end

function MY_Cataclysm.OpenBuffRuleEditor(rec, onChangeNotify, bHideBase)
	local w, h = 320, 320
	local ui = UI.CreateFrame('MY_Cataclysm_BuffConfig', {
		w = w, h = h,
		text = _L['Edit buff'],
		close = true, anchor = 'CENTER',
	}):Remove(function()
		if not bHideBase and not rec.dwID and (not rec.szName or rec.szName == '') then
			onChangeNotify()
		end
	end)
	local X, Y = 25, 60
	local x, y = X, Y
	if not bHideBase then
		x = x + ui:Append('Text', {
			x = x, y = y, h = 25,
			text = _L['Name or id'],
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndEditBox', {
			x = x, y = y, w = 105, h = 25,
			text = rec.dwID or rec.szName,
			onchange = function(text)
				if tonumber(text) then
					rec.dwID = tonumber(text)
					rec.szName = nil
				else
					rec.dwID = nil
					rec.szName = text
				end
				onChangeNotify(rec)
			end,
		}):Width() + 15

		x = x + ui:Append('Text', {
			x = x, y = y, h = 25,
			text = _L['Level'],
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndEditBox', {
			x = x, y = y, w = 60, h = 25,
			placeholder = _L['No limit'],
			edittype = UI.EDIT_TYPE.NUMBER, text = rec.nLevel,
			onchange = function(text)
				rec.nLevel = tonumber(text)
				onChangeNotify(rec)
			end,
		}):Width() + 5
		y = y + 30
		y = y + 10
	end

	x = X
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Stacknum'],
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndComboBox', {
		name = 'WndComboBox_StackOp',
		x = x, y = y, w = 90, h = 25,
		text = rec.szStackOp or (rec.nStackNum and '>=' or _L['No limit']),
		menu = function()
			local this = this
			local menu = {{
				szOption = _L['No limit'],
				fnAction = function()
					rec.szStackOp = nil
					ui:Children('#WndEditBox_StackNum'):Text('')
					onChangeNotify(rec)
					UI(this):Text(_L['No limit'])
				end,
			}}
			for _, op in ipairs({ '>=', '=', '!=', '<', '<=', '>', '>=' }) do
				insert(menu, {
					szOption = op,
					fnAction = function()
						rec.szStackOp = op
						onChangeNotify(rec)
						UI(this):Text(op)
					end,
				})
			end
			return menu
		end,
	}):Width() + 5
	x = x + ui:Append('WndEditBox', {
		name = 'WndEditBox_StackNum',
		x = x, y = y, w = 30, h = 25,
		edittype = UI.EDIT_TYPE.NUMBER,
		text = rec.nStackNum,
		onchange = function(text)
			rec.nStackNum = tonumber(text)
			if rec.nStackNum then
				if not rec.szStackOp then
					rec.szStackOp = '>='
					ui:Children('#WndComboBox_StackOp'):Text('>=')
				end
			end
			onChangeNotify(rec)
		end,
	}):Width() + 10

	ui:Append('WndCheckBox', {
		x = x, y = y - 10,
		text = _L['Only mine'],
		checked = rec.bOnlyMine,
		oncheck = function(bChecked)
			rec.bOnlyMine = bChecked
			onChangeNotify(rec)
		end,
	}):AutoWidth()
	ui:Append('WndCheckBox', {
		x = x, y = y + 10,
		text = _L['Only me'],
		checked = rec.bOnlyMe,
		oncheck = function(bChecked)
			rec.bOnlyMe = bChecked
			onChangeNotify(rec)
		end,
	}):AutoWidth()
	y = y + 30
	y = y + 10

	if not bHideBase then
		x = X
		y = y + 10
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Hide (Can Modify Default Data)'],
			checked = rec.bDelete,
			oncheck = function(bChecked)
				rec.bDelete = bChecked
				onChangeNotify(rec)
			end,
		}):AutoWidth():Width() + 5
		y = y + 30
		y = y + 10
	end

	x = X
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Reminder'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = y, w = 30, h = 25,
		text = rec.szReminder,
		onchange = function(text)
			rec.szReminder = text
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Priority'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = y, w = 40, h = 25,
		edittype = UI.EDIT_TYPE.NUMBER,
		text = rec.nPriority,
		onchange = function(text)
			rec.nPriority = tonumber(text)
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Color'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.col and {LIB.HumanColor2RGB(rec.col)} or {255, 255, 0},
		onlclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				local a = rec.col and select(4, LIB.Hex2RGB(rec.col)) or 255
				rec.nColAlpha = a
				rec.col = LIB.RGB2Hex(r, g, b, a)
				UI(this):Color(r, g, b)
				onChangeNotify(rec)
			end)
		end,
		onrclick = function()
			UI(this):Color(255, 255, 0)
			rec.col = nil
			onChangeNotify(rec)
		end,
		tip = _L['Left click to change color, right click to clear color'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.colScreenHead and {LIB.HumanColor2RGB(rec.colScreenHead)} or {255, 255, 0},
		onlclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				rec.colScreenHead = LIB.RGB2Hex(r, g, b)
				UI(this):Color(r, g, b)
				onChangeNotify(rec)
			end)
		end,
		onrclick = function()
			UI(this):Color(255, 255, 0)
			rec.colScreenHead = nil
			onChangeNotify(rec)
		end,
		tip = _L['Left click to change screen head color, right click to clear color'],
		tippostype = ALW.TOP_BOTTOM,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	y = y + 30

	x = X
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Border alpha'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y, text = '',
		range = {0, 255},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = rec.col and select(4, LIB.HumanColor2RGB(rec.col)) or rec.nColAlpha or 255,
		onchange = function(nVal)
			if rec.col then
				local r, g, b = LIB.Hex2RGB(rec.col)
				if r and g and b then
					rec.col = LIB.RGB2Hex(r, g, b, nVal)
				end
			end
			rec.nColAlpha = nVal
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	y = y + 30

	x = X
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Attention'],
		checked = rec.bAttention,
		oncheck = function(bChecked)
			rec.bAttention = bChecked
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Caution'],
		checked = rec.bCaution,
		oncheck = function(bChecked)
			rec.bCaution = bChecked
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Screen Head'],
		checked = rec.bScreenHead,
		oncheck = function(bChecked)
			rec.bScreenHead = bChecked
			onChangeNotify(rec)
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5

	y = y + 50
	ui:Append('WndButton', {
		x = (w - 120) / 2, y = y, w = 120,
		text = _L['Delete'], color = {223, 63, 95},
		buttonstyle = 'FLAT',
		onclick = function()
			local function fnAction()
				onChangeNotify()
				ui:Remove()
			end
			if rec.dwID or (rec.szName and rec.szName ~= '') then
				LIB.Confirm(_L('Delete [%s]?', rec.szName or rec.dwID), fnAction)
			else
				fnAction()
			end
		end,
	})
	y = y + 30

	h = y + 15
	ui:Height(h)
end
