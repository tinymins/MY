--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 集中渲染阴影
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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

local D = {}
local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Shadows.ini'
local FRAME_NAME = NSFormatString('{$NS}_Shadows')

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('COINSHOP_ON_OPEN')
	this:RegisterEvent('COINSHOP_ON_CLOSE')
	this:RegisterEvent('ENTER_STORY_MODE')
	this:RegisterEvent('LEAVE_STORY_MODE')
	this:RegisterEvent('ON_FRAME_CREATE')
	UI(this):BringToBottom()
end

do
local VISIBLE = true
function D.OnFrameBreathe()
	if Station.IsVisible() then
		if not VISIBLE then
			local h = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				h:Lookup(i):SetVisible(true)
			end
			VISIBLE = true
		end
	else
		if VISIBLE then
			local h, hh = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				hh = h:Lookup(i)
				hh:SetVisible(hh.bShowWhenUIHide or false)
			end
			VISIBLE = false
		end
	end
end
end

function D.OnEvent(event)
	if event == 'LOADING_END' then
		this:Show()
	elseif event == 'COINSHOP_ON_OPEN' or event == 'ENTER_STORY_MODE' then
		this:HideWhenUIHide()
	elseif event == 'COINSHOP_ON_CLOSE' or event == 'LEAVE_STORY_MODE' then
		this:ShowWhenUIHide()
	elseif event == 'ON_FRAME_CREATE' then
		UI(this):BringToBottom()
	end
end

function UI.GetShadowHandle(szName)
	local frame = Station.SearchFrame(FRAME_NAME)
	if frame and not IsElement(frame) then -- 关闭无效的 frame 句柄
		Wnd.CloseWindow(FRAME_NAME)
		frame = nil
	end
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, FRAME_NAME)
	end
	local sh = frame:Lookup('', szName)
	if sh and not IsElement(sh) then -- 关闭无效的 sh 句柄
		frame:Lookup('', ''):Remove(sh)
		sh = nil
	end
	if not sh then
		frame:Lookup('', ''):AppendItemFromString(format('<handle> name="%s" </handle>', szName))
		--[[#DEBUG BEGIN]]
		LIB.Debug('UI', 'Create sh # ' .. szName, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		sh = frame:Lookup('', szName)
	end
	return sh
end

function UI.SetShadowHandleParam(szName, tParam)
	local sh = UI.GetShadowHandle(szName)
	for k, v in pairs(tParam) do
		sh[k] = v
	end
end

do local VISIBLES = {}
function UI.TempSetShadowHandleVisible(bVisible)
	local frame = Station.SearchFrame(FRAME_NAME)
	if not frame then
		return insert(VISIBLES, true)
	end
	insert(VISIBLES, frame:IsVisible() or false)
	frame:SetVisible(bVisible)
end

function UI.RevertShadowHandleVisible()
	if #VISIBLES == 0 then
		return
	end
	local bVisible = remove(VISIBLES)
	local frame = Station.SearchFrame(FRAME_NAME)
	if frame then
		frame:SetVisible(bVisible)
	end
end
end

-- Global exports
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
_G[FRAME_NAME] = LIB.CreateModule(settings)
end
