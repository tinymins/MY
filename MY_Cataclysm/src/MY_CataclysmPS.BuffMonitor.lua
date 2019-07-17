--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板BUFF设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local ipairs_r = LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_Cataclysm/lang/')
if not LIB.AssertVersion('MY_Cataclysm', _L['MY_Cataclysm'], 0x2012800) then
	return
end
local CFG, PS = MY_Cataclysm.CFG, {}

-- 解析
local function GetListText(aBuffList)
	local aName = {}
	for _, v in ipairs(aBuffList) do
		local a = {}
		insert(a, v.szName or v.dwID)
		if v.nLevel then
			insert(a, 'lv' .. v.nLevel)
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
		insert(aName, (concat(a, ',')))
	end
	return concat(aName, '\n')
end

local function GetTextList(szText)
	local t = {}
	for _, line in ipairs(LIB.SplitString(szText, '\n')) do
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
				insert(t, tab)
			end
		end
	end
	return t
end

local l_list
function OpenBuffEditPanel(rec)
	local w, h = 320, 320
	local ui = UI.CreateFrame('MY_Cataclysm_BuffConfig', {
		w = w, h = h,
		text = _L['Edit buff'],
		close = true, anchor = 'CENTER',
	}):remove(function()
		if not rec.dwID and (not rec.szName or rec.szName == '') then
			for i, p in ipairs(CFG.aBuffList) do
				if p == rec then
					if l_list then
						l_list:listbox('delete', 'id', rec)
					end
					remove(CFG.aBuffList, i)
					MY_Cataclysm.UpdateBuffListCache()
					break
				end
			end
		end
	end)
	local function update()
		MY_Cataclysm.UpdateBuffListCache()
		if not l_list then
			return
		end
		l_list:listbox('update', 'id', rec, {'text'}, {GetListText({rec})})
	end
	local X, Y = 25, 60
	local x, y = X, Y
	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Name or id'],
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndEditBox', {
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
			update()
		end,
	}, true):width() + 15

	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Level'],
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndEditBox', {
		x = x, y = y, w = 60, h = 25,
		placeholder = _L['No limit'],
		edittype = 0, text = rec.nLevel,
		onchange = function(text)
			rec.nLevel = tonumber(text)
			update()
		end,
	}, true):width() + 5
	y = y + 30
	y = y + 10

	x = X
	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Stacknum'],
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndComboBox', {
		name = 'WndComboBox_StackOp',
		x = x, y = y, w = 90, h = 25,
		text = rec.szStackOp or (rec.nStackNum and '>=' or _L['No limit']),
		menu = function()
			local this = this
			local menu = {{
				szOption = _L['No limit'],
				fnAction = function()
					rec.szStackOp = nil
					ui:children('#WndEditBox_StackNum'):text('')
					update()
					UI(this):text(_L['No limit'])
				end,
			}}
			for _, op in ipairs({ '>=', '=', '!=', '<', '<=', '>', '>=' }) do
				insert(menu, {
					szOption = op,
					fnAction = function()
						rec.szStackOp = op
						update()
						UI(this):text(op)
					end,
				})
			end
			return menu
		end,
	}, true):width() + 5
	x = x + ui:append('WndEditBox', {
		name = 'WndEditBox_StackNum',
		x = x, y = y, w = 30, h = 25,
		edittype = 0,
		text = rec.nStackNum,
		onchange = function(text)
			rec.nStackNum = tonumber(text)
			if rec.nStackNum then
				if not rec.szStackOp then
					rec.szStackOp = '>='
					ui:children('#WndComboBox_StackOp'):text('>=')
				end
			end
			update()
		end,
	}, true):width() + 10

	ui:append('WndCheckBox', {
		x = x, y = y - 10,
		text = _L['Only mine'],
		checked = rec.bOnlyMine,
		oncheck = function(bChecked)
			rec.bOnlyMine = bChecked
			update()
		end,
	}, true):autoWidth()
	ui:append('WndCheckBox', {
		x = x, y = y + 10,
		text = _L['Only me'],
		checked = rec.bOnlyMe,
		oncheck = function(bChecked)
			rec.bOnlyMe = bChecked
			update()
		end,
	}, true):autoWidth()
	y = y + 30
	y = y + 10

	x = X
	y = y + 10
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Hide (Can Modify Default Data)'],
		checked = rec.bDelete,
		oncheck = function(bChecked)
			rec.bDelete = bChecked
			update()
		end,
	}, true):autoWidth():width() + 5

	x = X
	y = y + 30
	y = y + 10
	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Reminder'],
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndEditBox', {
		x = x, y = y, w = 30, h = 25,
		text = rec.szReminder,
		onchange = function(text)
			rec.szReminder = text
			update()
		end,
		autoenable = function() return not rec.bDelete end,
	}, true):width() + 5
	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Priority'],
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndEditBox', {
		x = x, y = y, w = 40, h = 25,
		edittype = 0,
		text = rec.nPriority,
		onchange = function(text)
			rec.nPriority = tonumber(text)
			update()
		end,
		autoenable = function() return not rec.bDelete end,
	}, true):width() + 5
	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Color'],
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.col and {LIB.HumanColor2RGB(rec.col)} or {255, 255, 0},
		onlclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				local a = rec.col and select(4, LIB.Hex2RGB(rec.col)) or 255
				rec.nColAlpha = a
				rec.col = LIB.RGB2Hex(r, g, b, a)
				UI(this):color(r, g, b)
				update()
			end)
		end,
		onrclick = function()
			UI(this):color(255, 255, 0)
			rec.col = nil
			update()
		end,
		tip = _L['Left click to change color, right click to clear color'],
		tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
		autoenable = function() return not rec.bDelete end,
	}, true):width() + 5
	x = x + ui:append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.colScreenHead and {LIB.HumanColor2RGB(rec.colScreenHead)} or {255, 255, 0},
		onlclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				rec.colScreenHead = LIB.RGB2Hex(r, g, b)
				UI(this):color(r, g, b)
				update()
			end)
		end,
		onrclick = function()
			UI(this):color(255, 255, 0)
			rec.colScreenHead = nil
			update()
		end,
		tip = _L['Left click to change screen head color, right click to clear color'],
		tippostype = ALW.TOP_BOTTOM,
		autoenable = function() return not rec.bDelete end,
	}, true):width() + 5
	y = y + 30

	x = X
	x = x + ui:append('Text', {
		x = x, y = y, h = 25,
		text = _L['Border alpha'],
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndSliderBox', {
		x = x, y = y, text = '',
		range = {0, 255},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		value = rec.col and select(4, LIB.HumanColor2RGB(rec.col)) or rec.nColAlpha or 255,
		onchange = function(nVal)
			if rec.col then
				local r, g, b = LIB.Hex2RGB(rec.col)
				if r and g and b then
					rec.col = LIB.RGB2Hex(r, g, b, nVal)
				end
			end
			rec.nColAlpha = nVal
			update()
		end,
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	y = y + 30

	x = X
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Attention'],
		checked = rec.bAttention,
		oncheck = function(bChecked)
			rec.bAttention = bChecked
			update()
		end,
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Caution'],
		checked = rec.bCaution,
		oncheck = function(bChecked)
			rec.bCaution = bChecked
			update()
		end,
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Screen Head'],
		checked = rec.bScreenHead,
		oncheck = function(bChecked)
			rec.bScreenHead = bChecked
			update()
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
		autoenable = function() return not rec.bDelete end,
	}, true):autoWidth():width() + 5

	y = y + 50
	ui:append('WndButton2', {
		x = (w - 120) / 2, y = y, w = 120,
		text = _L['Delete'], color = {223, 63, 95},
		onclick = function()
			local function fnAction()
				for i, p in ipairs(CFG.aBuffList) do
					if p == rec then
						if l_list then
							l_list:listbox('delete', 'id', rec)
						end
						remove(CFG.aBuffList, i)
						MY_Cataclysm.UpdateBuffListCache()
						break
					end
				end
				ui:remove()
			end
			if rec.dwID or (rec.szName and rec.szName ~= '') then
				LIB.Confirm(_L('Delete [%s]?', rec.szName or rec.dwID), fnAction)
			else
				fnAction()
			end
		end,
	}, true)
	y = y + 30

	h = y + 15
	ui:height(h)
end

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 10, 10
	local x, y = X, Y
	local w, h = ui:size()

	x = X
	x = x + ui:append('WndButton2', {
		x = x, y = y, w = 100,
		text = _L['Add'],
		onclick = function()
			local rec = {}
			insert(CFG.aBuffList, rec)
			l_list:listbox('insert', GetListText({rec}), rec, rec)
			OpenBuffEditPanel(rec, l_list)
		end,
	}, true):autoHeight():width() + 5
	x = x + ui:append('WndButton2', {
		x = x, y = y, w = 100,
		text = _L['Edit'],
		onclick = function()
			local ui = UI.CreateFrame('MY_Cataclysm_BuffConfig', {
				w = 350, h = 550,
				text = _L['Edit buff'],
				close = true, anchor = 'CENTER',
			})
			local X, Y = 20, 60
			local x, y = X, Y
			local edit = ui:append('WndEditBox',{
				x = x, y = y, w = 310, h = 440, limit = 4096, multiline = true,
				text = GetListText(CFG.aBuffList),
			}, true)
			y = y + edit:height() + 5

			ui:append('WndButton2', {
				x = x, y = y, w = 310,
				text = _L['Sure'],
				onclick = function()
					CFG.aBuffList = GetTextList(edit:text())
					MY_Cataclysm.UpdateBuffListCache()
					ui:remove()
					LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
					LIB.SwitchTab('MY_Cataclysm_BuffSettings', true)
				end,
			})
		end,
	}, true):autoHeight():width() + 5
	x = X
	y = y + 30

	l_list = ui:append('WndListBox', {
		x = x, y = y,
		w = w - 240 - 20, h = h - y - 5,
		listbox = {{
			'onlclick',
			function(hItem, szText, id, data, bSelected)
				OpenBuffEditPanel(data, l_list)
				return false
			end,
		}},
	}, true)
	for _, rec in ipairs(CFG.aBuffList) do
		l_list:listbox('insert', GetListText({rec}), rec, rec)
	end
	y = h

	X = w - 240
	x = X
	y = Y + 25
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Auto scale'],
		checked = CFG.bAutoBuffSize,
		oncheck = function(bCheck)
			CFG.bAutoBuffSize = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndSliderBox', {
		x = x, y = y, h = 25, rw = 80,
		enable = not CFG.bAutoBuffSize,
		autoenable = function() return not CFG.bAutoBuffSize end,
		range = {50, 200},
		value = CFG.fBuffScale * 100,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		onchange = function(nVal)
			CFG.fBuffScale = nVal / 100
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
		textfmt = function(val) return _L('%d%%', val) end,
	}, true):autoWidth():width() + 10

	x = X
	y = y + 30
	x = x + ui:append('Text', { x = x, y = y, text = _L['Max count']}, true):autoWidth():width() + 5
	x = x + ui:append('WndSliderBox', {
		x = x, y = y + 3, rw = 80, text = '',
		range = {0, 10},
		value = CFG.nMaxShowBuff,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		onchange = function(nVal)
			CFG.nMaxShowBuff = nVal
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 8

	x = X
	y = y + 30
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Push buff to official'],
		checked = CFG.bBuffPushToOfficial,
		oncheck = function(bCheck)
			CFG.bBuffPushToOfficial = bCheck
			MY_Cataclysm.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Buff Staring'],
		checked = CFG.bStaring,
		oncheck = function(bCheck)
			CFG.bStaring = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5

	x = X
	y = y + 30
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Time'],
		checked = CFG.bShowBuffTime,
		oncheck = function(bCheck)
			CFG.bShowBuffTime = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Over mana bar'],
		checked = not CFG.bBuffAboveMana,
		oncheck = function(bCheck)
			CFG.bBuffAboveMana = not bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5

	x = X
	y = y + 30
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Num'],
		checked = CFG.bShowBuffNum,
		oncheck = function(bCheck)
			CFG.bShowBuffNum = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Reminder'],
		checked = CFG.bShowBuffReminder,
		oncheck = function(bCheck)
			CFG.bShowBuffReminder = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
	}, true):autoWidth():width() + 5

	x = X
	y = y + 30
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Alt Click Publish'],
		checked = CFG.bBuffAltPublish,
		oncheck = function(bCheck)
			CFG.bBuffAltPublish = bCheck
		end,
	}, true):autoWidth():width() + 5
	y = y + 30

	x = X
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Enable default data'], tip = _L['Default data TIP'],
		tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		checked = CFG.bBuffDataNangongbo,
		oncheck = function(bCheck)
			CFG.bBuffDataNangongbo = bCheck
			MY_Cataclysm.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
		autoenable = function() return MY_Resource and true end,
	}, true):autoWidth():width() + 5
	y = y + 30

	x = X
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Cmd data'], tip = _L['Cmd data TIP'],
		tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		checked = CFG.bBuffDataNangongboCmd,
		oncheck = function(bCheck)
			CFG.bBuffDataNangongboCmd = bCheck
			MY_Cataclysm.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
		autoenable = function() return MY_Resource and CFG.bBuffDataNangongbo end,
	}, true):autoWidth():width() + 5
	x = x + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Heal data'], tip = _L['Heal data TIP'],
		tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		checked = CFG.bBuffDataNangongboHeal,
		oncheck = function(bCheck)
			CFG.bBuffDataNangongboHeal = bCheck
			MY_Cataclysm.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
		autoenable = function() return MY_Resource and CFG.bBuffDataNangongbo end,
	}, true):autoWidth():width() + 5

	x = X
	y = y + 30
	x = x + ui:append('WndButton2', {
		x = x, y = y, w = 220,
		text = _L['Feedback @nangongbo'],
		onclick = function()
			LIB.OpenBrowser('https://weibo.com/nangongbo')
		end,
	}, true):autoHeight():width()
	y = y + 28
end
function PS.OnPanelDeactive()
	l_list = nil
end
LIB.RegisterPanel('MY_Cataclysm_BuffMonitor', _L['Buff settings'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|65', PS)
