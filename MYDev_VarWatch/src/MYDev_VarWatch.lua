--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 变量监控
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MYDev_VarWatch'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_VarWatch'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local _C = {}
local DATA_PATH = {'config/dev_varwatch.jx3dat', PATH_TYPE.GLOBAL}
_C.tVarList = LIB.LoadLUAData(DATA_PATH) or {}

local function var2str_x(var, indent, level) -- 只解析一层table且不解析方法
	local function table_r(var, level, indent)
		local t = {}
		local szType = type(var)
		if szType == 'nil' then
			insert(t, 'nil')
		elseif szType == 'number' then
			insert(t, tostring(var))
		elseif szType == 'string' then
			insert(t, format('%q', var))
		elseif szType == 'boolean' then
			insert(t, tostring(var))
		elseif szType == 'table' then
			insert(t, '{')
			local s_tab_equ = ']='
			if indent then
				s_tab_equ = '] = '
				if not IsEmpty(var) then
					insert(t, '\n')
				end
			end
			for key, val in pairs(var) do
				if indent then
					insert(t, rep(indent, level + 1))
				end
				insert(t, '[')
				insert(t, tostring(key))
				insert(t, s_tab_equ) --'] = '
				insert(t, tostring(val))
				insert(t, ',')
				if indent then
					insert(t, '\n')
				end
			end
			if indent and not IsEmpty(var) then
				insert(t, rep(indent, level))
			end
			insert(t, '}')
		else --if (szType == 'userdata') then
			insert(t, '"')
			insert(t, tostring(var))
			insert(t, '"')
		end
		return concat(t)
	end
	return table_r(var, level or 0, indent)
end

LIB.RegisterPanel(
'Dev_VarWatch', _L['VarWatch'], _L['Development'],
'ui/Image/UICommon/BattleFiled.UITex|7', {
	OnPanelActive = function(wnd)
		local ui = UI(wnd)
		local x, y = 10, 10
		local w, h = ui:Size()
		local nLimit = 20

		local tWndEditK = {}
		local tWndEditV = {}

		for i = 1, nLimit do
			tWndEditK[i] = ui:Append('WndEditBox', {
				name = 'WndEditBox_K' .. i,
				text = _C.tVarList[i],
				x = x, y = y + (i - 1) * 25,
				w = 150, h = 25,
				color = {255, 255, 255},
				onchange = function(text)
					_C.tVarList[i] = LIB.TrimString(text)
					LIB.SaveLUAData(DATA_PATH, _C.tVarList)
				end,
			})

			tWndEditV[i] = ui:Append('WndEditBox', {
				name = 'WndEditBox_V' .. i,
				x = x + 150, y = y + (i - 1) * 25,
				w = w - 2 * x - 150, h = 25,
				color = {255, 255, 255},
			})
		end

		LIB.BreatheCall('DEV_VARWATCH', function()
			for i = 1, nLimit do
				local szKey = _C.tVarList[i]
				local hFocus = Station.GetFocusWindow()
				if not IsEmpty(szKey) and -- 忽略空白的Key
				wnd:GetRoot():IsVisible() and ( -- 主界面隐藏了就不要解析了
					not hFocus or (
						not hFocus:GetTreePath():find(tWndEditK[i]:Name()) and  -- 忽略K编辑中的
						not hFocus:GetTreePath():find(tWndEditV[i]:Name()) -- 忽略V编辑中的
					)
				) then
					if loadstring then
						local t = {select(2, XpCall(loadstring('return ' .. szKey)))}
						for k, v in pairs(t) do
							t[k] = tostring(v)
						end
						tWndEditV[i]:Text(concat(t, ', '))
					else
						tWndEditV[i]:Text(var2str_x(LIB.GetGlobalValue(szKey)))
					end
				end
			end
		end)
	end,
	OnPanelDeactive = function()
		LIB.BreatheCall('DEV_VARWATCH', false)
	end,
})
