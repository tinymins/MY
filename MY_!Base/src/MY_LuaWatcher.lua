--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��Դ���
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
if LoadLUAData('interface/DEBUG.jx3dat') and IsLocalFileExist('ui/DEBUG.ini') then
	Wnd.OpenWindow('ui/DEBUG.ini')
end
if not IsDebugClient() then
	return
end
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
-------------------------------------------------------------------------------------------------------------
local D = {}
local MAX_COUNT = 50
local RUNNING = false
local SORT_KEY = 'TIME'
local BTN, TXT
local SUM_CALL, SUM_TIME, CALL_TIME
local STATUS_FILE = 'interface/MY#DATA/.luawatcher.jx3dat'

local wfind_c
do
local c = {}
function wfind_c(s, i)
	if not c[s] then
		c[s] = {}
	end
	if c[s][i] == nil then
		c[s][i] = wfind(s, i) or false
	end
	return c[s][i]
end
end

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
if LoadLUAData(STATUS_FILE) then D.SetHook() end

function D.RemoveHook()
	debug.sethook(nil, 'rc')
	RUNNING = false
	CALL_TIME = {}
end
RegisterEvent('MY_BASE_LOADING_END', function() MY.RegisterReload('MY_LuaWatcher', D.RemoveHook) end)

function D.SaveStatus()
	if RUNNING then
		SaveLUAData(STATUS_FILE, true)
	else
		CPath.DelFile(STATUS_FILE)
	end
end

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
		if not wfind_c(id, 'LuaWatcher.lua:')
		and not wfind_c(id, 'Hack.lua:') then
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
	if not MY then
		return
	end
	return MY.BreatheCall('MY_LuaWatcher', 60000, function() TXT:text(D.GetRankString(SORT_KEY)) end)
end

function D.RemoveBreathe()
	if not MY then
		return
	end
	MY.BreatheCall('MY_LuaWatcher', false)
end

RegisterEvent('MY_BASE_LOADING_END', function()
	local _L = MY.LoadLangPack()
	local PS = {}

	function PS.OnPanelActive(wnd)
		local ui = MY.UI(wnd)
		local x, y = 10, 10
		local w, h = ui:size()

		BTN = ui:append('WndButton', {
			x = x, y = y,
			text = RUNNING and _L['Stop'] or _L['Start'],
			onclick = function()
				if RUNNING then
					D.RemoveHook()
					D.SaveStatus()
					D.RemoveBreathe()
				else
					D.SetHook()
					D.SaveStatus()
					D.SetBreathe()
				end
				BTN:text(RUNNING and _L['Stop'] or _L['Start'])
			end,
		}, true)
		ui:append('WndButton', {
			x = x + 100, y = y,
			text = _L['Refresh'],
			onclick = function()
				TXT:text(D.GetRankString(SORT_KEY))
			end,
		})
		ui:append('WndButton', {
			x = x + 200, y = y,
			text = SORT_KEY,
			onclick = function()
				if SORT_KEY == 'TIME' then
					SORT_KEY = 'CALL'
				else
					SORT_KEY = 'TIME'
				end
				MY.UI(this):text(SORT_KEY)
				TXT:text(D.GetRankString(SORT_KEY))
			end,
		})
		ui:append('WndButton', {
			x = x + 300, y = y,
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
				MY.Topmsg(_L['Copied to clipboard'], _L['LuaWatcher'])
				MY.UI.OpenTextEditor(D.GetRankString(SORT_KEY))
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

	MY.RegisterPanel('MY_LuaWatcher', _L['MY_LuaWatcher'], _L['Development'], 'ui/Image/UICommon/BattleFiled.UITex|7', PS)
end)