--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ����֮�ؾŹ�����
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
local MODULE_NAME = 'MY_LockFrame'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false,
	bTempDisable = false,
}
RegisterCustomData('MY_LockFrame.bEnable')

local HOOKED_UI = setmetatable({}, { __mode = 'k' })
local UI_DRAGABLE = setmetatable({}, { __mode = 'k' })
local function EnableDrag(frame, bEnable)
	UI_DRAGABLE[frame] = bEnable
end
local function IsDragable(frame)
	return UI_DRAGABLE[frame] or false
end
function D.LockFrame(frame)
	if not HOOKED_UI[frame] then
		HOOKED_UI[frame] = true
		UI_DRAGABLE[frame] = frame:IsDragable()
		frame:EnableDrag(false)
		HookTableFunc(frame, 'EnableDrag', EnableDrag, { bDisableOrigin = true })
		HookTableFunc(frame, 'IsDragable', IsDragable, { bDisableOrigin = true, bHookReturn = true })
	end
end
function D.UnlockFrame(frame)
	if HOOKED_UI[frame] then
		UnhookTableFunc(frame, 'EnableDrag', EnableDrag)
		UnhookTableFunc(frame, 'IsDragable', IsDragable)
		frame:EnableDrag(UI_DRAGABLE[frame])
		HOOKED_UI[frame] = nil
		UI_DRAGABLE[frame] = nil
	end
end

function D.IsLock()
	return O.bEnable and not O.bTempDisable
end

function D.CheckFrame(frame)
	local bLock = D.IsLock()
	if bLock then
		D.LockFrame(frame)
	else
		D.UnlockFrame(frame)
	end
end

function D.CheckAllFrame()
	local bLock = D.IsLock()
	for _, szLayer in ipairs({'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2'})do
		local frmIter = Station.Lookup(szLayer):GetFirstChild()
		while frmIter do
			if bLock then
				D.LockFrame(frmIter)
			else
				D.UnlockFrame(frmIter)
			end
			frmIter = frmIter:GetNext()
		end
	end
	if bLock then
		LIB.RegisterEvent('ON_FRAME_CREATE.MY_LockFrame', function()
			D.CheckFrame(arg0)
		end)
		LIB.BreatheCall('MY_LockFrame', function()
			if IsCtrlKeyDown() and (IsShiftKeyDown() or IsAltKeyDown()) then
				if not O.bTempDisable then
					O.bTempDisable = true
					D.CheckAllFrame()
				end
			else
				if O.bTempDisable then
					O.bTempDisable = false
					D.CheckAllFrame()
				end
			end
		end)
	else
		LIB.RegisterEvent('ON_FRAME_CREATE.MY_LockFrame', false)
	end
end

LIB.RegisterInit('MY_LockFrame', D.CheckAllFrame)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Lock all frame position (press ctrl+alt to temp unlock)'],
		checked = MY_LockFrame.bEnable,
		oncheck = function(bChecked)
			MY_LockFrame.bEnable = bChecked
		end,
	})
	y = y + 25
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			triggers = {
				bEnable = D.CheckAllFrame,
			},
			root = O,
		},
	},
}
MY_LockFrame = LIB.GeneGlobalNS(settings)
end