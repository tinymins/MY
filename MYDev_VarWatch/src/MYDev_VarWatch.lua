--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 变量监控
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
			insert(t, string.format('%q', var))
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
			}):Children('#WndEditBox_K' .. i)

			tWndEditV[i] = ui:Append('WndEditBox', {
				name = 'WndEditBox_V' .. i,
				x = x + 150, y = y + (i - 1) * 25,
				w = w - 2 * x - 150, h = 25,
				color = {255, 255, 255},
			}):Children('#WndEditBox_V' .. i)
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
