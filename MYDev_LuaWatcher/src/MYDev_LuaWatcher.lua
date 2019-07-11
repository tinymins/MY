--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ×ÊÔ´¼à¿Ø
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MYDev_LuaWatcher/lang/')
if not LIB.AssertVersion('MYDev_LuaWatcher', _L['MYDev_LuaWatcher'], 0x2011800) then
	return
end
local D = {}
local MAX_COUNT = 50
local RUNNING = false
local SORT_KEY = 'TIME'
local BTN, TXT
local SUM_CALL, SUM_TIME, CALL_TIME

function D.Reset()
	SUM_CALL = setmetatable({}, { __index = function() return 0 end })
	SUM_TIME = setmetatable({}, { __index = function() return 0 end })
	CALL_TIME = {}
end
D.Reset()

function D.SetHook()
	local bRecursive = false
	local function onHook(event, ...)
		local info = debug.getinfo(2)
		if info.func == debug.sethook or info.func == onHook or bRecursive then
			return
		end
		bRecursive = true
		-- source      --- Where the function was defined. If the function was defined in a string (through loadstring), source is that string. If the function was defined in a file, source is the file name prefixed with a `@?.
		-- short_src   --- A short version of source (up to 60 characters), useful for error messages.
		-- linedefined --- The line of the source where the function was defined.
		-- what        --- What this function is. Options are "Lua" if foo is a regular Lua function, "C" if it is a C function, or "main" if it is the main part of a Lua chunk.
		-- name        --- A reasonable name for the function.
		-- namewhat    --- What the previous field means. This field may be "global", "local", "method", "field", or "" (the empty string). The empty string means that Lua did not find a name for the function.
		-- nups        --- Number of upvalues of that function.
		-- func        --- The function itself; see later.
		local id = info.source .. ':' .. info.linedefined .. ' ' .. (info.name or '[anonymous]') .. ' (' .. info.what .. ':' .. info.namewhat .. ', upvalues:' .. info.nups .. ')'
		if event == 'call' then
			CALL_TIME[id] = GetTime()
		elseif CALL_TIME[id] then
			if not SUM_CALL[id] then
				SUM_CALL[id] = 0
			end
			if not SUM_TIME[id] then
				SUM_TIME[id] = 0
			end
			SUM_CALL[id] = SUM_CALL[id] + 1
			SUM_TIME[id] = SUM_TIME[id] + GetTime() - CALL_TIME[id]
			CALL_TIME[id] = nil
		end
		bRecursive = false
	end
	debug.sethook(onHook, 'rc')
	RUNNING = true
end

function D.RemoveHook()
	debug.sethook(nil, 'rc')
	RUNNING = false
	CALL_TIME = {}
end
LIB.RegisterReload('MYDev_LuaWatcher', D.RemoveHook)

local UNIT = {
	TIME = 'ms',
	CALL = '',
}
function D.GetRankString(key)
	assert(key == 'TIME' or key == 'CALL')
	local res = {}
	local count = 0
	local found = false
	local SUM_SORT = key == 'TIME' and SUM_TIME or SUM_CALL
	for id, time in pairs(SUM_SORT) do
		if not wfind(id, 'MYDev_LuaWatcher.lua:')
		and not wfind(id, 'Hack.lua:') then
			found = false
			for i, rid in ipairs_r(res) do
				if time <= SUM_SORT[rid] then
					insert(res, i + 1, id)
					found = true
					count = count + 1
					break
				end
			end
			if not found then
				insert(res, 1, id)
				count = count + 1
			end
			if count > MAX_COUNT then
				remove(res)
				count = count - 1
			end
		end
	end
	for i, id in ipairs(res) do
		res[i] = i .. '. ' .. '[TIME]' .. SUM_TIME[id] .. UNIT.TIME .. ' [CALL]' .. SUM_CALL[id] .. UNIT.CALL .. ' [INFO]' .. res[i]
	end
	return concat(res, '\n')
end

function D.SetBreathe()
	MY.BreatheCall('MYDev_LuaWatcher', 1000, function() TXT:text(D.GetRankString(SORT_KEY)) end)
end

function D.RemoveBreathe()
	MY.BreatheCall('MYDev_LuaWatcher', false)
end

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local x, y = 10, 10
	local w, h = ui:size()

	BTN = ui:append('WndButton', {
		x = x, y = y,
		text = RUNNING and _L['Stop'] or _L['Start'],
		onclick = function()
			if RUNNING then
				D.RemoveHook()
				D.RemoveBreathe()
			else
				D.SetHook()
				D.SetBreathe()
			end
			BTN:text(RUNNING and _L['Stop'] or _L['Start'])
		end,
	}, true)
	ui:append('WndButton', {
		x = x + 100, y = y,
		text = _L['Reset'],
		onclick = function()
			D.Reset()
		end,
	})
	y = y + 30

	TXT = ui:append('Text', {
		x = x, y = y, w = w, h = h - y,
		halign = 0, valign = 0,
		multiline = true,
		onclick = function()
			MY.Topmsg(_L['Copied to clipboard'], _L['MYDev_LuaWatcher'])
			UI.OpenTextEditor(D.GetRankString(SORT_KEY))
		end,
	}, true)

	if RUNNING then
		D.SetBreathe()
	end
	D.SetBreathe()
end

function PS.OnPanelDeactive()
	D.RemoveBreathe()
end

LIB.RegisterPanel('MYDev_LuaWatcher', _L['MYDev_LuaWatcher'], _L['Development'], 'ui/Image/UICommon/BattleFiled.UITex|7', PS)
