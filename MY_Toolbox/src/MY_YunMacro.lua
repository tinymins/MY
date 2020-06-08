--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ƶ˺�
-- @author   : ���� @˫���� @׷����Ӱ
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
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false,
}
RegisterCustomData('MY_YunMacro.bEnable')

function D.Hook()
	local frame = Station.SearchFrame('MacroSettingPanel')
	if not frame then
		return
	end
	local edtName = frame:Lookup('Edit_Name')
	local edtDesc = frame:Lookup('Edit_Desc')
	local edtMacro = frame:Lookup('Edit_Content')
	local btnSure = frame:Lookup('Btn_Sure')
	local hIconList = frame:Lookup('', 'Handle_Icon')
	UI(frame):Append('WndButton', {
		name = 'Btn_YunMacro_Update',
		x = edtName:GetRelX() + edtName:GetW() + 10, y = edtName:GetRelY() - 4,
		w = 'auto', h = edtName:GetH(),
		text = _L['Sync yun macro'],
		onclick = function()
			LIB.Alert('MY_YunMacro', _L['Macro update started, please keep panel opened and wait.'], nil, _L['Got it'])
			LIB.Ajax({
				driver = 'auto', mode = 'auto',
				url = 'https://pull.j3cx.com/api/plugins/macro/query?name='
					.. LIB.UrlEncode(AnsiToUTF8(edtName:GetText())),
				success = function(szHTML)
					local res, err = LIB.JsonDecode(szHTML)
					if not res then
						return LIB.Alert('MY_YunMacro', _L['ERR: Info content is illegal!'] .. '\n\n' .. err, nil, _L['Got it'])
					end
					if res.icon then
						for i = 0, hIconList:GetItemCount() - 1 do
							hIconList:Lookup(i):SetObjectInUse(false)
						end
						local box = hIconList:Lookup(0)
						box:SetObjectInUse(true)
						box:SetObjectIcon(res.icon)
						box.nIconID = res.icon
						hIconList.nIconID = res.icon
					end
					edtDesc:SetText(res.desc)
					edtDesc:SetCaretPos(0)
					edtMacro:SetText(res.data)
					edtMacro:SetCaretPos(0)
					LIB.Alert('MY_YunMacro', _L['Macro update succeed, please click save button.'], nil, _L['Got it'])
				end,
				error = function()
					LIB.Alert('MY_YunMacro', _L['Macro update failed...'], nil, _L['Got it'])
				end,
			})
		end,
	})
	UI(frame):Append('WndButton', {
		name = 'Btn_YunMacro_Tops',
		x = edtMacro:GetRelX(), y = btnSure:GetRelY(),
		w = btnSure:GetW(), h = btnSure:GetH(),
		text = _L['Top yun macro'],
		onclick = function()
			LIB.OpenBrowser('https://page.j3cx.com/macro/tops?kungfu=' .. UI_GetPlayerMountKungfuID())
		end,
	})
end

function D.Unhook()
	local frame = Station.SearchFrame('MacroSettingPanel')
	if not frame then
		return
	end
	for _, s in ipairs({
		'Btn_YunMacro_Update',
		'Btn_YunMacro_Tops',
	}) do
		local el = frame:Lookup(s)
		if el then
			el:Destroy()
		end
	end
end

function D.Apply()
	if O.bEnable then
		D.Hook()
		LIB.RegisterFrameCreate('MacroSettingPanel.MY_YunMacro', D.Hook)
		LIB.RegisterReload('MY_YunMacro', D.Unhook)
	else
		D.Unhook()
		LIB.RegisterFrameCreate('MacroSettingPanel.MY_YunMacro', false)
		LIB.RegisterReload('MY_YunMacro', false)
	end
end
LIB.RegisterInit('MY_YunMacro', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Show yun macro buttons on macro panel.'],
		checked = MY_YunMacro.bEnable,
		oncheck = function(bChecked)
			MY_YunMacro.bEnable = bChecked
		end,
	}):Width() + 5
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
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_YunMacro = LIB.GeneGlobalNS(settings)
end