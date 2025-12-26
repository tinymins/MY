--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ×ÊÔ´¼à¿Ø
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
if LoadLUAData('interface/DEBUG.jx3dat') and IsLocalFileExist('ui/DEBUG.ini') then
	Wnd.OpenWindow('ui/DEBUG.ini')
end
--------------------------------------------------------------------------------
local NS = 'MY'
local D = {}
local NO_RES_TIME = 6000
local MAX_COUNT = 50
local RUNNING = false
local SORT_KEY = 'TIME'
local BTN, TXT
local SUM_CALL, SUM_TIME, CALL_TIME
local STATUS_FILE = 'interface/' .. NS .. '#DATA/.luawatcher.jx3dat'

local wfind_c
do
local c = {}
function wfind_c(s, i)
	if not c[s] then
		c[s] = {}
	end
	if c[s][i] == nil then
		c[s][i] = wstring.find(s, i) or false
	end
	return c[s][i]
end
end

local ipairs_r
do
local function fnBpairs(tab, nIndex)
	nIndex = nIndex - 1
	if nIndex > 0 then
		return nIndex, tab[nIndex]
	end
end
function ipairs_r(tab)
	return fnBpairs, tab, #tab + 1
end
end

function D.SetWatchLoop()
	local nTime = GetTime()

	local function OnBreathe()
		nTime = GetTime()
	end
	BreatheCall(NS .. '_LuaWatcher__NO_RES_TIME', OnBreathe)

	local function trace_line(event, nLine)
		local nDelay = GetTime() - nTime
		if nDelay < NO_RES_TIME then
			return
		end
		Log('Response over ' .. nDelay .. ', ' .. debug.getinfo(2).short_src .. ':' .. nLine)
	end
	debug.sethook(trace_line, 'l')
	RegisterEvent('RELOAD_UI_ADDON_BEGIN', D.RemoveWatchLoop)
end

function D.RemoveWatchLoop()
	debug.sethook(nil, 'l')
	BreatheCall(NS .. '_LuaWatcher__NO_RES_TIME', false)
	UnRegisterEvent('RELOAD_UI_ADDON_BEGIN', D.RemoveWatchLoop)
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
RegisterEvent(NS .. '_BASE_LOADING_END', function() _G[NS].RegisterReload(NS .. '_LuaWatcher', D.RemoveHook) end)

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
	if key ~= 'TIME' and key ~= 'CALL' then
		assert(false, 'invalid key')
	end
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
					table.insert(res, i + 1, id)
					found = true
					count = count + 1
					break
				end
			end
			if not found then
				table.insert(res, 1, id)
				count = count + 1
			end
			if count > MAX_COUNT then
				table.remove(res)
				count = count - 1
			end
		end
	end
	for i, id in ipairs(res) do
		res[i] = i .. '. ' .. '[TIME]' .. SUM_TIME[id] .. UNIT.TIME .. ' [CALL]' .. SUM_CALL[id] .. UNIT.CALL .. ' [INFO]' .. res[i]
	end
	return table.concat(res, '\n')
end

function D.SetBreathe()
	if not _G[NS] then
		return
	end
	return _G[NS].BreatheCall(NS .. '_LuaWatcher', 60000, function() TXT:Text(D.GetRankString(SORT_KEY)) end)
end

function D.RemoveBreathe()
	if not _G[NS] then
		return
	end
	_G[NS].BreatheCall(NS .. '_LuaWatcher', false)
end

RegisterEvent(NS .. '_BASE_LOADING_END', function()
	local _L = _G[NS].LoadLangPack(_G[NS].PACKET_INFO.FRAMEWORK_ROOT .. 'lang/Dev/')
	local PS = {}
	local bInitRunning = RUNNING

	function PS.IsRestricted()
		if bInitRunning then
			return false
		end
		return not _G[NS].IsDebugging('Dev_LuaWatcher')
	end

	function PS.OnPanelActive(wnd)
		local ui = _G[NS].UI(wnd)
		local nX, nY = 10, 10
		local nW, nH = ui:Size()

		BTN = ui:Append('WndButton', {
			x = nX, y = nY,
			text = RUNNING and _L['Stop'] or _L['Start'],
			onClick = function()
				if RUNNING then
					D.RemoveHook()
					D.SaveStatus()
					D.RemoveBreathe()
				else
					D.SetHook()
					D.SaveStatus()
					D.SetBreathe()
				end
				BTN:Text(RUNNING and _L['Stop'] or _L['Start'])
			end,
		})
		ui:Append('WndButton', {
			x = nX + 100, y = nY,
			text = _L['Refresh'],
			onClick = function()
				TXT:Text(D.GetRankString(SORT_KEY))
			end,
		})
		ui:Append('WndButton', {
			x = nX + 200, y = nY,
			text = SORT_KEY,
			onClick = function()
				if SORT_KEY == 'TIME' then
					SORT_KEY = 'CALL'
				else
					SORT_KEY = 'TIME'
				end
				_G[NS].UI(this):Text(SORT_KEY)
				TXT:Text(D.GetRankString(SORT_KEY))
			end,
		})
		ui:Append('WndButton', {
			x = nX + 300, y = nY,
			text = _L['Reset'],
			onClick = function()
				D.Reset()
			end,
		})
		nY = nY + 30

		TXT = ui:Append('Text', {
			x = nX, y = nY, w = nW, h = nH - nY,
			alignHorizontal = 0, alignVertical = 0,
			multiline = true,
			onClick = function()
				_G[NS].OutputAnnounceMessage(_L['LuaWatcher'], _L['Copied to clipboard'])
				_G[NS].UI.OpenTextEditor(D.GetRankString(SORT_KEY))
			end,
		})

		if RUNNING then
			D.SetBreathe()
		end
		D.SetBreathe()
	end

	function PS.OnPanelDeactive()
		D.RemoveBreathe()
	end

	_G[NS].Panel.Register(_L['Development'], 'LuaWatcher', _L['LuaWatcher'], 'ui/Image/UICommon/BattleFiled.UITex|7', PS)
end)
