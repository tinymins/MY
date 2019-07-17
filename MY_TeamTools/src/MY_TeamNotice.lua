--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队告示
-- @author   : 茗伊 @双梦镇 @追风蹑影
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
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')
local TI = {}

MY_TeamNotice = {
	bEnable = true,
	anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
}
LIB.RegisterCustomData('MY_TeamNotice')

function TI.SaveList()
	LIB.SaveLUAData({'config/yy.jx3dat', PATH_TYPE.GLOBAL}, TI.tList, '\t', false)
end

function TI.GetList()
	if not TI.tList then
		TI.tList = LIB.LoadLUAData({'config/yy.jx3dat', PATH_TYPE.GLOBAL}) or {}
	end
	return TI.tList
end

function TI.GetFrame()
	return Station.Lookup('Normal/MY_TeamNotice')
end

function TI.CreateFrame(a, b)
	if LIB.IsInZombieMap() then
		return
	end
	local ui = TI.GetFrame()
	if ui then
		ui = UI(ui)
		ui:children('#YY'):text(a, WNDEVENT_FIRETYPE.PREVENT)
		ui:children('#Message'):text(b, WNDEVENT_FIRETYPE.PREVENT)
	else
		ui = UI.CreateFrame('MY_TeamNotice', {
			w = 320, h = 195,
			text = _L['Team Message'],
			anchor = MY_TeamNotice.anchor,
			simple = true, close = true, close = true,
			setting = function()
				LIB.ShowPanel()
				LIB.FocusPanel()
				LIB.SwitchTab('MY_TeamTools')
			end,
		})
		local x, y = 10, 5
		x = x + ui:append('Text', { x = x, y = y - 3, text = _L['YY:'], font = 48 }, true):autoWidth():width() + 5
		x = x + ui:append('WndAutocomplete', {
			name = 'YY',
			w = 160, h = 26, x = x, y = y,
			text = a, font = 48, color = { 128, 255, 0 },
			onclick = function()
				if IsPopupMenuOpened() then
					UI(this):autocomplete('close')
				elseif LIB.IsLeader() then
					UI(this):autocomplete('search', '')
				end
			end,
			onchange = function(szText)
				if TI.szYY == szText then
					return
				end
				if LIB.IsLeader() then
					TI.szYY = szText
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', 'Edit', szText, ui:children('#Message'):text())
				else
					ui:children('#YY'):text(TI.szYY, WNDEVENT_FIRETYPE.PREVENT)
				end
			end,
			autocomplete = {
				{
					'option', 'beforeSearch', function(raw, option, text)
						if LIB.IsLeader() then
							TI.tList = TI.GetList()
							option.source = {}
							for k, v in pairs(TI.tList) do
								table.insert(option.source, k)
							end
							if #option.source == 1 and tostring(option.source[1]) == text then
								option.source = {}
							end
						else
							option.source = {}
						end
					end,
				},
				{
					'option', 'beforeDelete', function(szOption, fnDoDelete, option)
						TI.tList[tonumber(szOption)] = nil
						TI.SaveList()
					end,
				},
			},
		}, true):width() + 5
		y = y + ui:append('WndButton2', {
			x = x, y = y, text = _L['Paste YY'],
			onclick = function()
				local yy = ui:children('#YY'):text()
				if tonumber(yy) then
					TI.tList = TI.GetList()
					if not TI.tList[tonumber(yy)] then
						TI.tList[tonumber(yy)] = true
						TI.SaveList()
					end
				end
				if yy ~= '' then
					for i = 0, 2 do -- 发三次
						LIB.Talk(PLAYER_TALK_CHANNEL.RAID, yy)
					end
				end
				local message = ui:children('#Message'):text():gsub('\n', ' ')
				if message ~= '' then
					LIB.Talk(PLAYER_TALK_CHANNEL.RAID, message)
				end
			end,
		}, true):height() + 5
		ui:append('WndEditBox', {
			name = 'Message',
			w = 300, h = 80, x = 10, y = y,
			multiline = true, limit = 512,
			text = b,
			onchange = function(szText)
				if TI.szNote == szText then
					return
				end
				if LIB.IsLeader() then
					TI.szNote = szText
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', 'Edit', ui:children('#YY'):text(), szText)
				else
					ui:children('#Message'):text(TI.szNote, WNDEVENT_FIRETYPE.PREVENT)
				end
			end,
		})
		x, y = 5, 130
		x = x + ui:append('WndButton2', { x = x, y = y, text = _L['Raid Tools'], onclick = MY_RaidTools.TogglePanel }, true):autoWidth():width() + 5
		x = x + ui:append('WndButton2', {
			x = x, y = y,
			text = _L['GKP Golden Team Record'],
			onclick = function()
				if MY_GKP then
					MY_GKP.TogglePanel()
				else
					LIB.Alert(_L['You haven\'t had MY_GKP installed and loaded yet.'])
				end
			end,
		}, true):autoWidth():width() + 5
		if DBM_RemoteRequest then
			x = x + ui:append('WndButton2', { x = x, y = y, text = _L['Import Data'], onclick = DBM_RemoteRequest.TogglePanel }, true):autoWidth():width() + 5
		end
		-- 注册事件
		local frame = TI.GetFrame()
		frame.OnFrameKeyDown = nil -- esc close --> nil
		frame:RegisterEvent('PARTY_DISBAND')
		frame:RegisterEvent('PARTY_DELETE_MEMBER')
		frame:RegisterEvent('PARTY_ADD_MEMBER')
		frame:RegisterEvent('UI_SCALED')
		frame.OnEvent = function(szEvent)
			if szEvent == 'PARTY_DISBAND' then
				ui:remove()
			elseif szEvent == 'PARTY_DELETE_MEMBER' then
				if arg1 == UI_GetClientPlayerID() then
					ui:remove()
				end
			elseif szEvent == 'PARTY_ADD_MEMBER' then
				if LIB.IsLeader() then
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', 'reply', arg1, TI.szYY, TI.szNote)
				end
			elseif szEvent == 'UI_SCALED' then
				ui:anchor(MY_TeamNotice.anchor)
			end
		end
		frame.OnFrameDragSetPosEnd = function()
			this:CorrectPos()
			MY_TeamNotice.anchor = GetFrameAnchor(this)
		end
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	TI.szYY   = a or TI.szYY
	TI.szNote = b or TI.szNote
end

function TI.OpenFrame()
	if LIB.IsInZombieMap() then
		return LIB.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
	local me = GetClientPlayer()
	MY_TeamNotice.bEnable = true
	if me.IsInRaid() then
		if LIB.IsLeader() then
			TI.CreateFrame()
		else
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', 'ASK')
			LIB.Sysmsg({_L['Asking..., If no response in longtime, team leader not enable plug-in.']})
		end
	end
end

LIB.RegisterEvent('PARTY_LEVEL_UP_RAID.TEAM_NOTICE', function()
	if LIB.IsInZombieMap() then
		return
	end
	if LIB.IsLeader() then
		LIB.Confirm(_L['Edit team info?'], function()
			MY_TeamNotice.bEnable = true
			TI.CreateFrame()
		end)
	end
end)
LIB.RegisterEvent('FIRST_LOADING_END.TEAM_NOTICE', function()
	if not MY_TeamNotice.bEnable then
		return
	end
	-- 不存在队长不队长的问题了
	local me = GetClientPlayer()
	if me.IsInRaid() then
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', 'ASK')
	end
end)
LIB.RegisterEvent('LOADING_END.TEAM_NOTICE', function()
	local frame = TI.GetFrame()
	if frame and LIB.IsInZombieMap() then
		Wnd.CloseWindow(frame)
		LIB.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
end)

LIB.RegisterEvent('ON_BG_CHANNEL_MSG.LR_TeamNotice', function()
	if not MY_TeamNotice.bEnable then
		return
	end
	local szMsgID, nChannel, dwID, szName, aMsg, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == UI_GetClientPlayerID()
	if szMsgID ~= 'LR_TeamNotice' or bSelf then
		return
	end
	local szCmd, szText = aMsg[1], aMsg[2]
	if szCmd == 'SEND' then
		TI.CreateFrame('', szText)
	end
end)

LIB.RegisterBgMsg('TI', function(_, nChannel, dwID, szName, bIsSelf, ...)
	if not MY_TeamNotice.bEnable then
		return
	end
	local data = {...}
	if not bIsSelf then
		local me = GetClientPlayer()
		local team = GetClientTeam()
		if team then
			if data[1] == 'ASK' and LIB.IsLeader() then
				if TI.GetFrame() then
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', 'reply', szName, TI.szYY, TI.szNote)
				end
			elseif data[1] == 'Edit' then
				TI.CreateFrame(data[2], data[3])
			elseif data[1] == 'reply' and (tonumber(data[2]) == UI_GetClientPlayerID() or data[2] == me.szName) then
				if LIB.TrimString(data[3]) ~= '' or LIB.TrimString(data[4]) ~= '' then
					TI.CreateFrame(data[3], data[4])
				end
			end
		end
	end
end)

do
local function GetMenu()
	return {{
		szOption = _L['Team Message'],
		fnDisable = function()
			local me = GetClientPlayer()
			return not me.IsInRaid()
		end,
		fnAction = TI.OpenFrame,
	}}
end
LIB.RegisterAddonMenu(GetMenu)

local function GetMenuTB()
	local menu = GetMenu()
	menu[1].szOption = _L['Team Small Message']
	return menu
end
TraceButton_AppendAddonMenu({ GetMenuTB })
end

local ui = {
	OpenFrame = TI.OpenFrame
}
setmetatable(MY_TeamNotice, { __index = ui, __metatable = true })
