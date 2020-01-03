--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������Ե���ý���
-- @author   : ���� @˫���� @׷����Ӱ
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Love'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {
	GetLover = MY_Love.GetLover,
	SetLover = MY_Love.SetLover,
	FixLover = MY_Love.FixLover,
	RemoveLover = MY_Love.RemoveLover,
	GetLoverType = MY_Love.GetLoverType,
	GetLoverTime = MY_Love.GetLoverTime,
}
local O = {
	bPanelActive = false,
}

-- refresh ps
function D.RefreshPS()
	if O.bPanelActive and MY.IsPanelOpened() then
		MY.SwitchTab('MY_Love', true)
	end
end
LIB.RegisterEvent('MY_LOVE_UPDATE.MY_Love__PS', D.RefreshPS)

-------------------------------------
-- ���ý���
-------------------------------------
local PS = { IsShielded = MY_Love.IsShielded }

-- ��ȡ����Ե�����б�
function D.GetLoverMenu(nType)
	local me, m0 = GetClientPlayer(), {}
	local aGroup = me.GetFellowshipGroupInfo() or {}
	table.insert(aGroup, 1, {id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND})
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for _, vv in ipairs(aFriend) do
			if vv.attraction >= MY_Love.nLoveAttraction and (nType ~= 1 or vv.attraction >= MY_Love.nDoubleLoveAttraction) then
				table.insert(m0, {
					szOption = vv.name,
					fnDisable = function() return not vv.isonline end,
					fnAction = function()
						D.SetLover(vv.id, nType)
					end
				})
			end
		end
	end
	if #m0 == 0 then
		table.insert(m0, { szOption = _L['<Non-avaiable>'] })
	end
	return m0
end

-- init
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 20, 20
	local nX, nY = X, Y
	local lover = D.GetLover()

	ui:Append('Text', { text = _L['Heart lover'], x = X, y = nY, font = 27 })
	-- lover info
	nY = nY + 36
	if not lover or not lover.dwID or lover.dwID == 0 then
		nX = X + 10
		nX = ui:Append('Text', { text = _L['No lover :-('], font = 19, x = nX, y = nY }):Pos('BOTTOMRIGHT')
		-- create lover
		nX = X + 10
		nY = nY + 36
		nX = ui:Append('Text', { text = _L['Mutual love friend Lv.6: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = nX + 5, y = nY, w = 200, h = 25,
			text = _L['- Select plz -'],
			menu = function() return D.GetLoverMenu(1) end,
		}):Pos('BOTTOMRIGHT')
		ui:Append('Text', { text = _L['(4-feets, with specific fireworks)'], x = nX + 5, y = nY })
		nX = X + 10
		nY = nY + 28
		nX = ui:Append('Text', { text = _L['Blind love friend Lv.2: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = nX + 5, y = nY, w = 200, h = 25,
			text = _L['- Select plz -'],
			menu = function() return D.GetLoverMenu(0) end,
		}):Pos('BOTTOMRIGHT')
		ui:Append('Text', { text = _L['(Online required, notify anonymous)'], x = nX + 5, y = nY })
	else
		-- sync social data
		Wnd.OpenWindow('SocialPanel')
		Wnd.CloseWindow('SocialPanel')
		-- show lover
		nX = X + 10
		nX = ui:Append('Text', { text = lover.szName, font = 19, x = nX, y = nY, r = 255, g = 128, b = 255 }):AutoWidth():Pos('BOTTOMRIGHT')
		local map = lover.bOnline and LIB.GetMapInfo(lover.dwMapID)
		if not IsEmpty(lover.szLoverTitle) then
			nX = ui:Append('Text', { text = '<' .. lover.szLoverTitle .. '>', x = nX, y = nY, font = 80, r = 255, g = 128, b = 255 }):AutoWidth():Pos('BOTTOMRIGHT')
		end
		if map and map.szName then
			ui:Append('Text', { text = '(' .. g_tStrings.STR_GUILD_ONLINE .. ': ' .. map.szName .. ')', font = 80, x = nX + 10, y = nY })
		else
			ui:Append('Text', { text = '(' .. g_tStrings.STR_GUILD_OFFLINE .. ')', font = 62, x = nX + 10, y = nY })
		end
		nX = X + 10
		nY = nY + 36
		nX = ui:Append('Text', { text = D.GetLoverType(), font = 2, x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { text = D.GetLoverTime(), font = 2, x = nX + 10, y = nY }):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { text = _L['[Break love]'], x = nX + 10, y = nY, onclick = D.RemoveLover }):AutoWidth():Pos('BOTTOMRIGHT')
		if lover.nLoverType == 1 then
			nX = ui:Append('Text', { text = _L['[Recovery]'], x = nX + 10, y = nY, onclick = D.FixLover }):AutoWidth():Pos('BOTTOMRIGHT')
		end
		ui:Append('WndCheckBox', {
			x = nX + 10, y = nY + 2,
			text = _L['Auto focus lover'],
			checked = MY_Love.bAutoFocus,
			oncheck = function(bChecked)
				MY_Love.bAutoFocus = bChecked
			end,
		})
		nY = nY + 10
	end
	-- local setting
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Non-love display: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
	nX = ui:Append('WndEditBox', {
		x = nX + 5, y = nY, w = 198, h = 25,
		limit = 20, text = MY_Love.szNone,
		onchange = function(szText) MY_Love.szNone = szText end,
	}):Pos('BOTTOMRIGHT')
	ui:Append('WndCheckBox', {
		x = nX + 5, y = nY,
		text = _L['Enable quiet mode'],
		checked = MY_Love.bQuiet,
		oncheck = function(bChecked) MY_Love.bQuiet = bChecked end,
	})
	-- jabber
	nX = X + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Quick to accost text: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
	ui:Append('WndEditBox', {
		x = nX + 5, y = nY, w = 340, h = 25,
		limit = 128, text = MY_Love.szJabber,
		onchange = function(szText) MY_Love.szJabber = szText end,
	})
	-- signature
	nX = X + 10
	nY = nY + 36
	nX = ui:Append('Text', { text = _L['Love signature: '], x = nX, y = nY, font = 27 }):Pos('BOTTOMRIGHT')
	ui:Append('WndEditBox', {
		x = nX + 5, y = nY, w = 340, h = 48,
		limit = 42,  multi = true,
		text = MY_Love.szSign,
		onchange = function(szText)
			MY_Love.szSign = LIB.ReplaceSensitiveWord(szText)
		end,
	})
	nY = nY + 54
	ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, w = 200,
		text = _L['Enable player view panel hook'],
		checked = MY_Love.bHookPlayerView,
		oncheck = function(bChecked) MY_Love.bHookPlayerView = bChecked end,
	}):AutoWidth()
	-- tips
	nY = nY + 28
	ui:Append('Text', { text = _L['Tips'], x = X, y = nY, font = 27 })
	nX = X + 10
	nY = nY + 25
	ui:Append('Text', { text = _L['1. You can break love one-sided'], x = nX, y = nY })
	O.bPanelActive = true
end

-- deinit
function PS.OnPanelDeactive()
	O.bPanelActive = false
end

LIB.RegisterPanel('MY_Love', _L['MY_Love'], _L['Target'], 329, PS)