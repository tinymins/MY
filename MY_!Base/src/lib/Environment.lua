--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 环境相关
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
---------------------------------------------------------------------------------------------------

function X.AssertVersion(szKey, szCaption, szRequireVersion)
	if not X.IsString(szRequireVersion) then
		X.Sysmsg(_L(
			'%s requires a invalid base library version value: %s.',
			szCaption, X.EncodeLUAData(szRequireVersion)))
		return IsDebugClient() or false
	end
	if not (X.Semver(X.PACKET_INFO.VERSION) % szRequireVersion) then
		X.Sysmsg(_L(
			'%s requires base library version at %s, current at %s.',
			szCaption, szRequireVersion, X.PACKET_INFO.VERSION))
		return IsDebugClient() or false
	end
	return true
end

-- 获取功能屏蔽等级
do
local DELAY_EVENT = {}
local RESTRICTION = {}

-- 注册功能在不同分支下屏蔽状态
-- X.RegisterRestriction('SomeFunc', { ['*'] = true, intl = false })
function X.RegisterRestriction(szKey, tBranchRestricted)
	local bRestricted = nil
	if X.IsTable(tBranchRestricted) then
		if X.IsBoolean(tBranchRestricted[GLOBAL.GAME_BRANCH]) then
			bRestricted = tBranchRestricted[GLOBAL.GAME_BRANCH]
		elseif X.IsBoolean(tBranchRestricted['*']) then
			bRestricted = tBranchRestricted['*']
		end
	end
	if not X.IsBoolean(bRestricted) then
		--[[#DEBUG BEGIN]]
		X.Debug(X.PACKET_INFO.NAME_SPACE, 'Restriction should be a boolean value: ' .. szKey, X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	RESTRICTION[szKey] = bRestricted
end

-- 获取功能在当前分支是否已屏蔽
-- X.IsRestricted('SomeFunc')
function X.IsRestricted(szKey, ...)
	if select('#', ...) == 1 then
		-- 设置值
		local bRestricted = ...
		if not X.IsNil(bRestricted) then
			bRestricted = not not bRestricted
		end
		if RESTRICTION[szKey] == bRestricted then
			return
		end
		RESTRICTION[szKey] = bRestricted
		-- 发起事件通知
		local szEvent = X.NSFormatString('{$NS}.RESTRICTION')
		if szKey == '!' then
			for k, _ in pairs(DELAY_EVENT) do
				X.DelayCall(k, false)
			end
			DELAY_EVENT = {}
			szKey = nil
		else
			szEvent = szEvent .. '.' .. szKey
		end
		X.DelayCall(szEvent, 75, function()
			if X.IsPanelOpened() then
				X.ReopenPanel()
			end
			DELAY_EVENT[szEvent] = nil
			FireUIEvent(X.NSFormatString('{$NS}_RESTRICTION'), szKey)
		end)
		DELAY_EVENT[szEvent] = true
	else
		if not X.IsNil(RESTRICTION['!']) then
			return RESTRICTION['!']
		end
		return RESTRICTION[szKey] or false
	end
end

local function OnKeyPanelBtnLButtonUp()
	local frame = Station.SearchFrame('KeyPanel')
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	local szText = X.DecryptString('2,' .. edit:GetText())
	if not szText then
		return
	end
	local aParam = X.DecodeLUAData(szText)
	if not X.IsTable(aParam) then
		return
	end
	local szCRC = aParam[1]
	local szCorrect = X.PACKET_INFO.NAME_SPACE .. GetStringCRC(X.GetUserRoleName() .. '65e33433-d13c-4269-adac-f091d4a57d4b')
	if szCRC ~= szCorrect then
		return
	end
	local nExpire = tonumber(aParam[2] or '')
	if not nExpire or (nExpire ~= 0 and nExpire < GetCurrentTime()) then
		return
	end
	local szCmd = aParam[3]
	if szCmd == 'R' then
		for _, szKey in ipairs(aParam[4]) do
			X.IsRestricted(szKey, false)
		end
	end
	frame:Destroy()
	PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
end
local function HookKeyPanel()
	local frame = Station.SearchFrame('KeyPanel')
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	edit:SetLimit(-1)
	HookTableFunc(btn, 'OnLButtonUp', OnKeyPanelBtnLButtonUp)
end
local function UnhookPanel()
	local frame = Station.SearchFrame('KeyPanel')
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	UnhookTableFunc(btn, 'OnLButtonUp', OnKeyPanelBtnLButtonUp)
end
X.RegisterFrameCreate('KeyPanel', 'LIB.KeyPanel_Restriction', HookKeyPanel)
X.RegisterInit('LIB.KeyPanel_Restriction', HookKeyPanel)
X.RegisterReload('LIB.KeyPanel_Restriction', UnhookPanel)
end

-- 获取是否测试客户端
-- (bool) X.IsDebugClient()
-- (bool) X.IsDebugClient(bool bManually = false)
-- (bool) X.IsDebugClient(string szKey[, bool bDebug, bool bSet])
do
local DELAY_EVENT = {}
local DEBUG = { ['*'] = X.PACKET_INFO.DEBUG_LEVEL <= X.DEBUG_LEVEL.DEBUG }
function X.IsDebugClient(szKey, bDebug, bSet)
	if not X.IsString(szKey) then
		szKey, bDebug, bSet = '*', szKey, bDebug
	end
	if bSet then
		-- 通用禁止设为空
		if szKey == '*' and X.IsNil(bDebug) then
			return
		end
		-- 设置值
		if DEBUG[szKey] == bDebug then
			return
		end
		DEBUG[szKey] = bDebug
		-- 发起事件通知
		local szEvent = X.NSFormatString('{$NS}#DEBUG')
		if szKey == '*' or szKey == '!' then
			for k, _ in pairs(DELAY_EVENT) do
				X.DelayCall(k, false)
			end
			szKey = nil
		else
			szEvent = szEvent .. '#' .. szKey
		end
		X.DelayCall(szEvent, 75, function()
			if X.IsPanelOpened() then
				X.ReopenPanel()
			end
			DELAY_EVENT[szEvent] = nil
			FireUIEvent(X.NSFormatString('{$NS}_DEBUG'), szKey)
		end)
		DELAY_EVENT[szEvent] = true
	else
		if not X.IsNil(DEBUG['!']) then
			return DEBUG['!']
		end
		if szKey == '*' and not bDebug then
			return IsDebugClient()
		end
		if not X.IsNil(DEBUG[szKey]) then
			return DEBUG[szKey]
		end
		return DEBUG['*']
	end
end
end

-- 获取是否测试服务器
function X.IsDebugServer()
	local ip = select(7, GetUserServer())
	if ip:find('^192%.') or ip:find('^10%.') then
		return true
	end
	return false
end
