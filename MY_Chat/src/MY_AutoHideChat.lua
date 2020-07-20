--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动隐藏聊天栏
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Chat'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local STATE = {
	SHOW    = 1, -- 已显示
	HIDE    = 2, -- 已隐藏
	SHOWING = 3, -- 渐变显示中
	HIDDING = 4, -- 渐变隐藏中
}
local m_nState = STATE.SHOW
local D = {}
local O = {
	bEnable = false,
}
RegisterCustomData('MY_AutoHideChat.bEnable')

-- get sys chat bg alpha
function D.GetBgAlpha()
	return Station.Lookup('Lowest2/ChatPanel1'):Lookup('Wnd_Message', 'Shadow_Back'):GetAlpha() / 255
end

-- show panel
function D.ShowChatPanel(nShowFrame, nDelayFrame, callback)
	-- 渐变出现帧数
	if not nShowFrame then
		nShowFrame = GLOBAL.GAME_FPS / 4
	end
	-- 隐藏延迟帧数
	if not nDelayFrame then
		nDelayFrame = 0
	end
	-- switch case
	if m_nState == STATE.SHOW then
		-- return when chat panel is visible
		if callback then
			Call(callback)
		end
		return
	elseif m_nState == STATE.SHOWING then
		return
	elseif m_nState == STATE.HIDE then
		-- show each
		for i = 1, 10 do
			local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
			if hFrame then
				hFrame:SetMousePenetrable(false)
			end
		end
	elseif m_nState == STATE.HIDDING then
		-- unregister hide animate
		LIB.BreatheCall('MY_AutoHideChat_Hide', false)
	end
	m_nState = STATE.SHOWING

	-- get start alpha
	local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
	local nStartFrame = GetLogicFrameCount()
	-- register animate breathe call
	LIB.BreatheCall('MY_AutoHideChat_Show', function()
		local nFrame = GetLogicFrameCount()
		if nFrame - nDelayFrame < nStartFrame then
			O.fAhBgAlpha = D.GetBgAlpha()
			return
		end
		-- calc new alpha
		local nAlpha = min(ceil((nFrame - nDelayFrame - nStartFrame) / nShowFrame * (255 - nStartAlpha) + nStartAlpha), 255)
		-- alpha each panel
		for i = 1, 10 do
			local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
			if hFrame then
				hFrame:SetAlpha(nAlpha)
				hFrame:Lookup('Wnd_Message', 'Shadow_Back'):SetAlpha(nAlpha * O.fAhBgAlpha)
			end
		end
		Station.Lookup('Lowest1/ChatTitleBG'):SetAlpha(nAlpha)
		Station.Lookup('Lowest1/ChatTitleBG', 'Image_BG'):SetAlpha(nAlpha * O.fAhBgAlpha)
		if nAlpha == 255 then
			m_nState = STATE.SHOW
			if callback then
				Call(callback)
			end
			return 0
		end
	end)
end

-- hide panel
function D.HideChatPanel(nHideFrame, nDelayFrame, callback)
	-- 渐变消失帧数
	if not nHideFrame then
		nHideFrame = GLOBAL.GAME_FPS / 2
	end
	-- 隐藏延迟帧数
	if not nDelayFrame then
		nDelayFrame = GLOBAL.GAME_FPS * 5
	end
	-- switch case
	if m_nState == STATE.SHOW then
		-- get bg alpha
		O.fAhBgAlpha = D.GetBgAlpha()
	elseif m_nState == STATE.SHOWING then
		return
	elseif m_nState == STATE.HIDE then
		-- return when chat panel is not visible
		if callback then
			Call(callback)
		end
		return
	elseif m_nState == STATE.HIDDING then
		-- unregister hide animate
		LIB.BreatheCall('MY_AutoHideChat_Hide', false)
	end
	m_nState = STATE.HIDDING

	-- get start alpha
	local nStartAlpha = Station.Lookup('Lowest1/ChatTitleBG'):GetAlpha()
	local nStartFrame = GetLogicFrameCount()
	-- register animate breathe call
	LIB.BreatheCall('MY_AutoHideChat_Hide', function()
		local nFrame = GetLogicFrameCount()
		if nFrame - nDelayFrame < nStartFrame then
			O.fAhBgAlpha = D.GetBgAlpha()
			return
		end
		-- calc new alpha
		local nAlpha = max(ceil((1 - (nFrame - nDelayFrame - nStartFrame) / nHideFrame) * nStartAlpha), 0)
		-- if panel setting panel is opened then delay again
		local hPanelSettingFrame = Station.Lookup('Normal/ChatSettingPanel')
		if hPanelSettingFrame and hPanelSettingFrame:IsVisible() then
			nStartFrame = GetLogicFrameCount()
			return
		end
		-- if mouse over chat panel then delay again
		local hMouseOverWnd = Station.GetMouseOverWindow()
		if hMouseOverWnd and hMouseOverWnd:GetRoot():GetName():sub(1, 9) == 'ChatPanel' then
			nStartFrame = GetLogicFrameCount()
			nAlpha = 255
		end
		-- alpha each panel
		for i = 1, 10 do
			local hFrame = Station.Lookup('Lowest2/ChatPanel' .. i)
			if hFrame then
				hFrame:SetAlpha(nAlpha)
				hFrame:Lookup('Wnd_Message', 'Shadow_Back'):SetAlpha(nAlpha * O.fAhBgAlpha)
				-- hide if alpha turns to zero
				if nAlpha == 0 then
					hFrame:SetMousePenetrable(true)
				end
			end
		end
		Station.Lookup('Lowest1/ChatTitleBG'):SetAlpha(nAlpha)
		Station.Lookup('Lowest1/ChatTitleBG', 'Image_BG'):SetAlpha(nAlpha * O.fAhBgAlpha)
		if nAlpha == 0 then
			m_nState = STATE.HIDE
			if callback then
				Call(callback)
			end
			return 0
		end
	end)
end

-- 初始化/生效 设置
function D.Apply()
	local shaBack = Station.Lookup('Lowest2/ChatPanel1/Wnd_Message', 'Shadow_Back')
	local editInput = LIB.GetChatInputEdit()
	if not shaBack or not editInput then
		return
	end
	if O.bEnable then
		-- get bg alpha
		if not O.fAhBgAlpha then
			O.fAhBgAlpha = shaBack:GetAlpha() / 255
			O.bAhAnimate = O.bAhAnimate or false
		end
		-- hook chat panel as event listener
		LIB.HookChatPanel('AFTER.MY_AutoHideChat', function(h)
			-- if input box get focus then return
			local focus = Station.GetFocusWindow()
			if focus and focus == LIB.GetChatInputEdit() then
				return
			end
			-- show when new msg
			D.ShowChatPanel(GLOBAL.GAME_FPS / 4, 0, function()
				-- hide after 5 sec
				D.HideChatPanel(GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS * 5)
			end)
		end)

		-- hook chat edit box
		-- save org
		if editInput._MY_T_AHCP_OnSetFocus == nil then
			editInput._MY_T_AHCP_OnSetFocus = editInput.OnSetFocus or false
		end
		-- show when chat panel get focus
		editInput.OnSetFocus = function()
			D.ShowChatPanel(GLOBAL.GAME_FPS / 4, 0)
			if this._MY_T_AHCP_OnSetFocus then
				this._MY_T_AHCP_OnSetFocus()
			end
		end
		-- save org
		if editInput._MY_T_AHCP_OnKillFocus == nil then
			editInput._MY_T_AHCP_OnKillFocus = editInput.OnKillFocus or false
		end
		-- hide after input box lost focus for 5 sec
		editInput.OnKillFocus = function()
			D.HideChatPanel(GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS * 5)
			if this._MY_T_AHCP_OnKillFocus then
				this._MY_T_AHCP_OnKillFocus()
			end
		end
	else
		if editInput._MY_T_AHCP_OnSetFocus then
			editInput.OnSetFocus = editInput._MY_T_AHCP_OnSetFocus
		else
			editInput.OnSetFocus = nil
		end
		editInput._MY_T_AHCP_OnSetFocus = nil

		if editInput._MY_T_AHCP_OnKillFocus then
			editInput.OnKillFocus = editInput._MY_T_AHCP_OnKillFocus
		else
			editInput.OnKillFocus = nil
		end
		editInput._MY_T_AHCP_OnKillFocus = nil
		LIB.HookChatPanel('AFTER.MY_AutoHideChat', false)

		D.ShowChatPanel()
	end
end
LIB.RegisterInit('MY_AutoHideChat', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Auto hide chat panel'],
		checked = MY_AutoHideChat.bEnable,
		oncheck = function(bChecked)
			MY_AutoHideChat.bEnable = bChecked
		end,
	}):Width()
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
MY_AutoHideChat = LIB.GeneGlobalNS(settings)
end
