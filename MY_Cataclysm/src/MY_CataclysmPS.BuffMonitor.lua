--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板BUFF设置
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
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {
	ReloadCataclysmPanel = MY_CataclysmMain.ReloadCataclysmPanel,
}
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 5 }

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
				l_list:ListBox('update', 'id', rec, {'text'}, {MY_Cataclysm.EncodeBuffRule(rec)})
			end
			MY_CataclysmMain.UpdateBuffListCache()
		else
			for i, p in ipairs(CFG.aBuffList) do
				if p == rec then
					if l_list then
						l_list:ListBox('delete', 'id', rec)
					end
					remove(CFG.aBuffList, i)
					MY_CataclysmMain.UpdateBuffListCache()
					break
				end
			end
		end
	end, function()
		CFG.aBuffList = CFG.aBuffList
		LIB.SwitchTab('MY_Cataclysm_BuffMonitor', true)
	end)
end

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local nPaddingX, nPaddingY = 10, 10
	local x, y = nPaddingX, nPaddingY
	local w, h = ui:Size()

	x = nPaddingX
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 100,
		buttonstyle = 'FLAT',
		text = _L['Add'],
		onclick = function()
			local rec = {}
			insert(CFG.aBuffList, rec)
			l_list:ListBox('insert', { id = rec, text = MY_Cataclysm.EncodeBuffRule(rec), data = rec })
			OpenBuffRuleEditor(rec)
		end,
	}):AutoHeight():Width() + 5
	x = x + ui:Append('WndButton', {
		x = x, y = y, w = 100,
		buttonstyle = 'FLAT',
		text = _L['Edit'],
		onclick = function()
			local ui = UI.CreateFrame('MY_Cataclysm_BuffConfig', {
				w = 350, h = 550,
				text = _L['Edit buff'],
				close = true, anchor = 'CENTER',
			})
			local x, y = 20, 60
			local edit = ui:Append('WndEditBox',{
				x = x, y = y, w = 310, h = 440,
				limit = -1, multiline = true,
				text = EncodeBuffRuleList(CFG.aBuffList),
			})
			y = y + edit:Height() + 5

			ui:Append('WndButton', {
				x = x, y = y, w = 310,
				text = _L['Sure'],
				buttonstyle = 'FLAT',
				onclick = function()
					CFG.aBuffList = DecodeBuffRuleList(edit:Text())
					MY_CataclysmMain.UpdateBuffListCache()
					ui:Remove()
					LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
					LIB.SwitchTab('MY_Cataclysm_BuffSettings', true)
				end,
			})
		end,
	}):AutoHeight():Width() + 5
	x = nPaddingX
	y = y + 30

	l_list = ui:Append('WndListBox', {
		x = x, y = y,
		w = w - 240 - 20, h = h - y - 5,
		listbox = {{
			'onlclick',
			function(id, szText, data, bSelected)
				OpenBuffRuleEditor(data)
				return false
			end,
		}},
	})
	for _, rec in ipairs(CFG.aBuffList) do
		l_list:ListBox('insert', { id = rec, text = MY_Cataclysm.EncodeBuffRule(rec), data = rec })
	end
	y = h

	nPaddingX = w - 240
	x = nPaddingX
	y = nPaddingY + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Auto scale'],
		checked = CFG.bAutoBuffSize,
		oncheck = function(bCheck)
			CFG.bAutoBuffSize = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y, h = 25, rw = 80,
		enable = not CFG.bAutoBuffSize,
		autoenable = function() return not CFG.bAutoBuffSize end,
		range = {50, 200},
		value = CFG.fBuffScale * 100,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(nVal)
			CFG.fBuffScale = nVal / 100
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
		textfmt = function(val) return _L('%d%%', val) end,
	}):AutoWidth():Width() + 10

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Max count']}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y + 3, rw = 80, text = '',
		range = {0, 10},
		value = CFG.nMaxShowBuff,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(nVal)
			CFG.nMaxShowBuff = nVal
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 8

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Push buff to official'],
		checked = CFG.bBuffPushToOfficial,
		oncheck = function(bCheck)
			CFG.bBuffPushToOfficial = bCheck
			MY_CataclysmMain.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Buff Staring'],
		checked = CFG.bStaring,
		oncheck = function(bCheck)
			CFG.bStaring = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Time'],
		checked = CFG.bShowBuffTime,
		oncheck = function(bCheck)
			CFG.bShowBuffTime = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Over mana bar'],
		checked = not CFG.bBuffAboveMana,
		oncheck = function(bCheck)
			CFG.bBuffAboveMana = not bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Num'],
		checked = CFG.bShowBuffNum,
		oncheck = function(bCheck)
			CFG.bShowBuffNum = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Reminder'],
		checked = CFG.bShowBuffReminder,
		oncheck = function(bCheck)
			CFG.bShowBuffReminder = bCheck
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Alt Click Publish'],
		checked = CFG.bBuffAltPublish,
		oncheck = function(bCheck)
			CFG.bBuffAltPublish = bCheck
		end,
	}):AutoWidth():Width() + 5
	y = y + 30

	x = nPaddingX
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Enable MY_TeamMon data'],
		checked = CFG.bBuffDataTeamMon,
		oncheck = function(bCheck)
			CFG.bBuffDataTeamMon = bCheck
			MY_CataclysmMain.UpdateBuffListCache()
			LIB.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
		autoenable = function() return MY_Resource and true end,
	}):AutoWidth():Width() + 5
	y = y + 30
end
function PS.OnPanelDeactive()
	l_list = nil
end
LIB.RegisterPanel(_L['Raid'], 'MY_Cataclysm_BuffMonitor', _L['Buff settings'], 'ui/Image/UICommon/RaidTotal.uitex|65', PS)
