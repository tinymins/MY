--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队告示
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')
local TI = {}

MY_TeamNotice = {
	bEnable = true,
	anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
}
MY.RegisterCustomData('MY_TeamNotice')

function TI.SaveList()
	MY.SaveLUAData({'config/yy.jx3dat', MY_DATA_PATH.GLOBAL}, TI.tList, '\t', false)
end

function TI.GetList()
	if not TI.tList then
		TI.tList = MY.LoadLUAData({'config/yy.jx3dat', MY_DATA_PATH.GLOBAL}) or {}
	end
	return TI.tList
end

function TI.GetFrame()
	return Station.Lookup('Normal/MY_TeamNotice')
end

function TI.CreateFrame(a, b)
	if MY.IsInZombieMap() then
		return
	end
	local ui = TI.GetFrame()
	if ui then
		ui = XGUI(ui)
		ui:children('#YY'):text(a)
		ui:children('#Message'):text(b)
	else
		ui = XGUI.CreateFrame('MY_TeamNotice', {
			w = 320, h = 195,
			text = _L['Team Message'],
			anchor = MY_TeamNotice.anchor,
			simple = true, close = true, close = true,
			setting = function()
				MY.ShowPanel()
				MY.FocusPanel()
				MY.SwitchTab('MY_TeamTools')
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
					XGUI(this):autocomplete('close')
				elseif MY.IsLeader() then
					XGUI(this):autocomplete('search', '')
				end
			end,
			onchange = function(szText)
				if TI.szYY == szText then
					return
				end
				if MY.IsLeader() then
					TI.szYY = szText
					MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'TI', 'Edit', szText, ui:children('#Message'):text())
				else
					ui:children('#YY'):text(TI.szYY, true)
				end
			end,
			autocomplete = {
				{
					'option', 'beforeSearch', function(raw, option, text)
						if MY.IsLeader() then
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
						MY.Talk(PLAYER_TALK_CHANNEL.RAID, yy)
					end
				end
				local message = ui:children('#Message'):text():gsub('\n', ' ')
				if message ~= '' then
					MY.Talk(PLAYER_TALK_CHANNEL.RAID, message)
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
				if MY.IsLeader() then
					TI.szNote = szText
					MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'TI', 'Edit', ui:children('#YY'):text(), szText)
				else
					ui:children('#Message'):text(TI.szNote)
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
					MY.Alert(_L['You haven\'t had MY_GKP installed and loaded yet.'])
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
				if MY.IsLeader() then
					MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'TI', 'reply', arg1, TI.szYY, TI.szNote)
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
	TI.szYY   = a
	TI.szNote = b
end

function TI.OpenFrame()
	if MY.IsInZombieMap() then
		return MY.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
	local me = GetClientPlayer()
	MY_TeamNotice.bEnable = true
	if me.IsInRaid() then
		if MY.IsLeader() then
			TI.CreateFrame()
		else
			MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'TI', 'ASK')
			MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'LR_TeamNotice', 'ASK')
			MY.Sysmsg({_L['Asking..., If no response in longtime, team leader not enable plug-in.']})
		end
	end
end

MY.RegisterEvent('PARTY_LEVEL_UP_RAID.TEAM_NOTICE', function()
	if MY.IsInZombieMap() then
		return
	end
	if MY.IsLeader() then
		MY.Confirm(_L['Edit team info?'], function()
			MY_TeamNotice.bEnable = true
			TI.CreateFrame()
		end)
	end
end)
MY.RegisterEvent('FIRST_LOADING_END.TEAM_NOTICE', function()
	if not MY_TeamNotice.bEnable then
		return
	end
	-- 不存在队长不队长的问题了
	local me = GetClientPlayer()
	if me.IsInRaid() then
		MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'TI', 'ASK')
	end
end)
MY.RegisterEvent('LOADING_END.TEAM_NOTICE', function()
	local frame = TI.GetFrame()
	if frame and MY.IsInZombieMap() then
		Wnd.CloseWindow(frame)
		MY.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
end)

MY.RegisterBgMsg('LR_TeamNotice', function(_, nChannel, dwID, szName, bIsSelf, szCmd, szText)
	if not MY_TeamNotice.bEnable then
		return
	end
	if szCmd == 'SEND' then
		TI.CreateFrame('', szText)
	end
end)

MY.RegisterBgMsg('TI', function(_, nChannel, dwID, szName, bIsSelf, ...)
	if not MY_TeamNotice.bEnable then
		return
	end
	local data = {...}
	if not bIsSelf then
		local me = GetClientPlayer()
		local team = GetClientTeam()
		if team then
			if data[1] == 'ASK' and MY.IsLeader() then
				if TI.GetFrame() then
					MY.BgTalk(PLAYER_TALK_CHANNEL.RAID, 'TI', 'reply', szName, TI.szYY, TI.szNote)
				end
			elseif data[1] == 'Edit' then
				TI.CreateFrame(data[2], data[3])
			elseif data[1] == 'reply' and (tonumber(data[2]) == UI_GetClientPlayerID() or data[2] == me.szName) then
				if MY.TrimString(data[3]) ~= '' or MY.TrimString(data[4]) ~= '' then
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
MY.RegisterAddonMenu(GetMenu)

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
