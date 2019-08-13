--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板BUFF设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
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
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_Cataclysm/lang/')
if not LIB.AssertVersion('MY_Cataclysm', _L['MY_Cataclysm'], 0x2012800) then
	return
end
local CFG, PS = MY_Cataclysm.CFG, {}

-- 解析
local function EncodeBuffRuleList(aBuffList)
	local aName = {}
	for _, v in ipairs(aBuffList) do
		insert(aName, MY_Cataclysm.EncodeBuffRule(v))
	end
	return concat(aName, '\n')
end

local function DecodeBuffRuleList(szText)
	local aBuffList = {}
	for _, v in ipairs(LIB.SplitString(szText, '\n')) do
		v = MY_Cataclysm.DecodeBuffRule(v)
		if v then
			insert(aBuffList, v)
		end
	end
	return aBuffList
end

local l_list
local function OpenBuffRuleEditor(rec)
	MY_Cataclysm.OpenBuffRuleEditor(rec, function(p)
		if p then
			if l_list then
				l_list:listbox('update', 'id', rec, {'text'}, {MY_Cataclysm.EncodeBuffRule(rec)})
			end
			MY_Cataclysm.UpdateBuffListCache()
		else
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
			l_list:listbox('insert', MY_Cataclysm.EncodeBuffRule(rec), rec, rec)
			OpenBuffRuleEditor(rec)
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
				x = x, y = y, w = 310, h = 440,
				limit = -1, multiline = true,
				text = EncodeBuffRuleList(CFG.aBuffList),
			}, true)
			y = y + edit:height() + 5

			ui:append('WndButton2', {
				x = x, y = y, w = 310,
				text = _L['Sure'],
				onclick = function()
					CFG.aBuffList = DecodeBuffRuleList(edit:text())
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
				OpenBuffRuleEditor(data)
				return false
			end,
		}},
	}, true)
	for _, rec in ipairs(CFG.aBuffList) do
		l_list:listbox('insert', MY_Cataclysm.EncodeBuffRule(rec), rec, rec)
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
		sliderstyle = UI.SLIDER_DISPTYPE.SHOW_VALUE,
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
		sliderstyle = UI.SLIDER_DISPTYPE.SHOW_VALUE,
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
		text = _L['Enable MY_TeamMon data'],
		checked = CFG.bBuffDataTeamMon,
		oncheck = function(bCheck)
			CFG.bBuffDataTeamMon = bCheck
			MY_Cataclysm.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, ReloadCataclysmPanel)
		end,
		autoenable = function() return MY_Resource and true end,
	}, true):autoWidth():width() + 5
	y = y + 30
end
function PS.OnPanelDeactive()
	l_list = nil
end
LIB.RegisterPanel('MY_Cataclysm_BuffMonitor', _L['Buff settings'], _L['Raid'], 'ui/Image/UICommon/RaidTotal.uitex|65', PS)
