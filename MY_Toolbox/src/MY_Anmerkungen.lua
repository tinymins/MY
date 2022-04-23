--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色备注
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Anmerkungen'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
X.RegisterRestriction('MY_Anmerkungen.Export', { ['*'] = true, intl = false })
--------------------------------------------------------------------------
local _C = {}
local LOADED = false
local PUBLIC_PLAYER_IDS = {}
local PUBLIC_PLAYER_NOTES = {}
local PRIVATE_PLAYER_IDS = {}
local PRIVATE_PLAYER_NOTES = {}
MY_Anmerkungen = MY_Anmerkungen or {}
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }

-- 打开一个玩家的记录编辑器
function MY_Anmerkungen.OpenPlayerNoteEditPanel(dwID, szName)
	if not MY_Farbnamen then
		return X.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}

	local w, h = 340, 300
	local ui = UI.CreateFrame('MY_Anmerkungen_PlayerNoteEdit_' .. (dwID or 0), {
		w = w, h = h, anchor = 'CENTER',
		text = _L['MY Anmerkungen - Player Note Edit'],
	})

	local function IsValid()
		return ui and ui:Count() > 0
	end
	local function RemoveFrame()
		ui:Remove()
		return true
	end
	X.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', IsValid, RemoveFrame)

	local function onRemove()
		X.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	ui:Remove(onRemove)

	local x, y = 35 , 50
	ui:Append('Text', { x = x, y = y, text = _L['Name:'] })
	ui:Append('WndEditBox', {
		name = 'WndEditBox_Name',
		x = x + 60, y = y, w = 200, h = 25,
		multiline = false, text = szName or note.szName or '',
		onChange = function(szName)
			local rec = MY_Anmerkungen.GetPlayerNote(szName) or {}
			local info = MY_Farbnamen and MY_Farbnamen.GetAusName(szName)
			if info and rec.dwID ~= info.dwID then
				rec.dwID = info.dwID
				rec.szContent = ''
				rec.bTipWhenGroup = true
				rec.bAlertWhenGroup = false
			end
			if rec.dwID then
				ui:Children('#WndButton_Submit'):Enable(true)
				ui:Children('#WndEditBox_ID'):Text(rec.dwID)
				ui:Children('#WndEditBox_Content'):Text(rec.szContent)
				ui:Children('#WndCheckBox_TipWhenGroup'):Check(rec.bTipWhenGroup)
				ui:Children('#WndCheckBox_AlertWhenGroup'):Check(rec.bAlertWhenGroup)
			else
				ui:Children('#WndButton_Submit'):Enable(false)
				ui:Children('#WndEditBox_ID'):Text(_L['Not found in local store'])
			end
		end,
	})
	y = y + 30

	ui:Append('Text', { x = x, y = y, text = _L['ID:'] })
	ui:Append('WndEditBox', {
		name = 'WndEditBox_ID', x = x + 60, y = y, w = 200, h = 25,
		text = dwID or note.dwID or '',
		multiline = false, enable = false, color = {200,200,200},
	})
	y = y + 30

	ui:Append('Text', { x = x, y = y, text = _L['Content:'] })
	ui:Append('WndEditBox', {
		name = 'WndEditBox_Content',
		x = x + 60, y = y, w = 200, h = 80,
		multiline = true, text = note.szContent or '',
	})
	y = y + 90

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_AlertWhenGroup',
		x = x + 58, y = y, w = 200,
		text = _L['Alert when group'],
		checked = note.bAlertWhenGroup,
	})
	y = y + 20

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_TipWhenGroup',
		x = x + 58, y = y, w = 200,
		text = _L['Tip when group'],
		checked = note.bTipWhenGroup,
	})
	y = y + 30

	ui:Append('WndButton', {
		name = 'WndButton_Submit',
		x = x + 58, y = y, w = 80,
		text = _L['sure'],
		onClick = function()
			MY_Anmerkungen.SetPlayerNote(
				ui:Children('#WndEditBox_ID'):Text(),
				ui:Children('#WndEditBox_Name'):Text(),
				ui:Children('#WndEditBox_Content'):Text(),
				ui:Children('#WndCheckBox_TipWhenGroup'):Check(),
				ui:Children('#WndCheckBox_AlertWhenGroup'):Check()
			)
			ui:Remove()
		end,
	})
	ui:Append('WndButton', {
		x = x + 143, y = y, w = 80,
		text = _L['cancel'],
		onClick = function() ui:Remove() end,
	})
	ui:Append('Text', {
		x = x + 230, y = y - 3, w = 80, alpha = 200,
		text = _L['Delete'], color = {255,0,0},
		onHover = function(bIn) UI(this):Alpha((bIn and 255) or 200) end,
		onClick = function()
			MY_Anmerkungen.SetPlayerNote(ui:Children('#WndEditBox_ID'):Text())
			ui:Remove()
		end,
	})

	-- init
	Station.SetFocusWindow(ui[1])
	ui:Children('#WndEditBox_Name'):Change()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

do
local function onMenu()
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.PLAYER then
		local p = X.GetObject(dwType, dwID)
		return {
			szOption = _L['Edit player note'],
			fnAction = function()
				X.DelayCall(1, function()
					MY_Anmerkungen.OpenPlayerNoteEditPanel(p.dwID, p.szName)
				end)
			end
		}
	end
end
X.RegisterTargetAddonMenu('MY_Anmerkungen_PlayerNotes', onMenu)
end

do
local menu = {
	szOption = _L['View anmerkungen'],
	fnAction = function()
		X.ShowPanel()
		X.FocusPanel()
		X.SwitchTab('MY_Anmerkungen_Player_Note')
	end,
}
X.RegisterAddonMenu('MY_Anmerkungen_PlayerNotes', menu)
end

-- 获取一个玩家的记录
-- MY_Anmerkungen.GetPlayerNote(dwID)
-- MY_Anmerkungen.GetPlayerNote(szName)
function MY_Anmerkungen.GetPlayerNote(dwID)
	if not LOADED then
		MY_Anmerkungen.LoadConfig()
	end
	local t, rec
	rec = PRIVATE_PLAYER_NOTES[PRIVATE_PLAYER_IDS[dwID] or dwID]
	if rec then
		t = X.Clone(rec)
		t.bPrivate = true
		return t
	end
	rec = PUBLIC_PLAYER_NOTES[PUBLIC_PLAYER_IDS[dwID] or dwID]
	if rec then
		t = X.Clone(rec)
		t.bPrivate = false
		return t
	end
end

-- 设置一个玩家的记录
function MY_Anmerkungen.SetPlayerNote(dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate)
	dwID = dwID and tonumber(dwID)
	if not dwID then
		return nil
	end
	MY_Anmerkungen.LoadConfig()
	-- remove
	local rec = PRIVATE_PLAYER_NOTES[dwID]
	if rec then
		PRIVATE_PLAYER_IDS[rec.szName] = nil
		PRIVATE_PLAYER_NOTES[dwID] = nil
	end
	local rec = PUBLIC_PLAYER_NOTES[dwID]
	if rec then
		PUBLIC_PLAYER_IDS[rec.szName] = nil
		PUBLIC_PLAYER_NOTES[dwID] = nil
	end
	-- add
	if szName then
		local t = {
			dwID = dwID,
			szName = szName,
			szContent = szContent,
			bTipWhenGroup = bTipWhenGroup,
			bAlertWhenGroup = bAlertWhenGroup,
		}
		if bPrivate then
			PRIVATE_PLAYER_NOTES[dwID] = t
			PRIVATE_PLAYER_IDS[szName] = dwID
		else
			PUBLIC_PLAYER_NOTES[dwID] = t
			PUBLIC_PLAYER_IDS[szName] = dwID
		end
		if _C.list then
			_C.list:ListBox('update', 'id', dwID, {'text', 'data'}, { _L('[%s] %s', t.szName, t.szContent), t })
		end
	elseif _C.list then
		_C.list:ListBox('delete', 'id', dwID)
	end
	FireUIEvent('MY_ANMERKUNGEN_UPDATE')
	if X.GetCurrentTabID() == 'MY_Anmerkungen_Player_Note' then
		X.SwitchTab('MY_Anmerkungen_Player_Note', true)
	end
	MY_Anmerkungen.SaveConfig()
end

-- 当有玩家进队时
do
local function CheckPartyPlayer(dwID)
	local team = GetClientTeam()
	local szName = team.GetClientTeamMemberName(dwID)
	local dwLeaderID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
	-- local szLeaderName = team.GetClientTeamMemberName(dwLeader)
	local t = MY_Anmerkungen.GetPlayerNote(dwID)
	if t then
		if t.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_Anmerkungen_PlayerNotes_' .. t.dwID,
				szMessage = dwID == dwLeaderID
					and _L('Tip: [%s](Leader) is in your team.\nNote: %s', t.szName, t.szContent)
					or _L('Tip: [%s] is in your team.\nNote: %s', t.szName, t.szContent),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if t.bTipWhenGroup then
			X.Sysmsg(_L('Tip: [%s] is in your team.\nNote: %s', t.szName, t.szContent))
		end
	end
end

do
local function OnPartyAddMember()
	CheckPartyPlayer(arg1)
end
X.RegisterEvent('PARTY_ADD_MEMBER', OnPartyAddMember)
-- X.RegisterEvent('PARTY_SYNC_MEMBER_DATA', OnPartyAddMember)
end

-- 当进队时
do
local function OnEnterParty()
	local team = GetClientTeam()
	if not team then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		CheckPartyPlayer(dwID)
	end
end
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', 'MY_Anmerkungen', OnEnterParty)
end
end

-- 读取公共数据
function MY_Anmerkungen.LoadConfig()
	if not GetClientPlayer() then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_Anmerkungen.LoadConfig', 'Client player not exist! Cannot load config!', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end

	local data = X.LoadLUAData({'config/anmerkungen.jx3dat', X.PATH_TYPE.SERVER})
	if data then
		PUBLIC_PLAYER_IDS = data.ids or {}
		PUBLIC_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = X.GetLUADataPath({'config/PLAYER_NOTES/{$relserver}.{$lang}.jx3dat', X.PATH_TYPE.DATA})
	local szFilePath = X.GetLUADataPath({'config/playernotes.jx3dat', X.PATH_TYPE.SERVER})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = X.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = X.DecodeJSON(data)
		end
		for k, v in pairs(data) do
			if type(v) == 'table' then
				k = tonumber(k)
				if k then
					v.dwID = tonumber(v.dwID)
					PUBLIC_PLAYER_NOTES[k] = v
				end
			else
				PUBLIC_PLAYER_IDS[k] = tonumber(v)
			end
		end
		CPath.DelFile(szFilePath)
		MY_Anmerkungen.SaveConfig()
	end

	local data = X.LoadLUAData({'config/anmerkungen.jx3dat', X.PATH_TYPE.ROLE})
	if data then
		PRIVATE_PLAYER_IDS = data.ids or {}
		PRIVATE_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = X.GetLUADataPath({'config/PLAYER_NOTES/{$uid}.{$lang}.jx3dat', X.PATH_TYPE.DATA})
	local szFilePath = X.GetLUADataPath({'config/playernotes.jx3dat', X.PATH_TYPE.ROLE})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = X.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = X.DecodeJSON(data)
		end
		for k, v in pairs(data) do
			if type(v) == 'table' then
				k = tonumber(k)
				if k then
					v.dwID = tonumber(v.dwID)
					PRIVATE_PLAYER_NOTES[k] = v
				end
			else
				PRIVATE_PLAYER_IDS[k] = tonumber(v)
			end
		end
		CPath.DelFile(szFilePath)
		MY_Anmerkungen.SaveConfig()
	end
	LOADED = true
end
-- 保存公共数据
function MY_Anmerkungen.SaveConfig()
	local data = {
		ids = PUBLIC_PLAYER_IDS,
		data = PUBLIC_PLAYER_NOTES,
	}
	X.SaveLUAData({'config/anmerkungen.jx3dat', X.PATH_TYPE.SERVER}, data)

	local data = {
		ids = PRIVATE_PLAYER_IDS,
		data = PRIVATE_PLAYER_NOTES,
	}
	X.SaveLUAData({'config/anmerkungen.jx3dat', X.PATH_TYPE.ROLE}, data)
end
X.RegisterInit('MY_ANMERKUNGEN', MY_Anmerkungen.LoadConfig)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 0, 0

	ui:Append('WndButton', {
		x = x, y = y, w = 110,
		text = _L['Create'],
		buttonStyle = 'FLAT',
		onClick = function()
			MY_Anmerkungen.OpenPlayerNoteEditPanel()
		end,
	})

	if not MY.IsRestricted('MY_Anmerkungen.Export') then
		ui:Append('WndButton', {
			x = w - 230, y = y, w = 110,
			text = _L['Import'],
			buttonStyle = 'FLAT',
			onClick = function()
				GetUserInput(_L['Please input import data:'], function(szVal)
					local config = X.DecodeLUAData(szVal)
					if config and config.server and config.public and config.private then
						if config.server ~= X.GetRealServer() then
							return X.Alert(_L['Server not match!'])
						end
						local function Next(usenew)
							for k, v in pairs(config.public) do
								if type(v) == 'table' then
									k = tonumber(k)
									if not PUBLIC_PLAYER_NOTES[k] or usenew then
										v.dwID = tonumber(v.dwID)
										PUBLIC_PLAYER_NOTES[k] = v
									end
								else
									v = tonumber(v)
									PUBLIC_PLAYER_IDS[k] = v
								end
							end
							for k, v in pairs(config.publici) do
								if not PUBLIC_PLAYER_IDS[k] or usenew then
									PUBLIC_PLAYER_IDS[k] = v
								end
							end
							for k, v in pairs(config.publicd) do
								if not PUBLIC_PLAYER_NOTES[k] or usenew then
									PUBLIC_PLAYER_NOTES[k] = v
								end
							end
							for k, v in pairs(config.private) do
								if type(v) == 'table' then
									k = tonumber(k)
									if not PRIVATE_PLAYER_NOTES[k] or usenew then
										v.dwID = tonumber(v.dwID)
										PRIVATE_PLAYER_NOTES[k] = v
									end
								else
									v = tonumber(v)
									PRIVATE_PLAYER_IDS[k] = v
								end
							end
							for k, v in pairs(config.privatei) do
								if not PRIVATE_PLAYER_IDS[k] or usenew then
									PRIVATE_PLAYER_IDS[k] = v
								end
							end
							for k, v in pairs(config.privated) do
								if not PRIVATE_PLAYER_NOTES[k] or usenew then
									PRIVATE_PLAYER_NOTES[k] = v
								end
							end
							MY_Anmerkungen.SaveConfig()
							X.SwitchTab('MY_Anmerkungen_Player_Note', true)
						end
						X.Dialog(_L['Prefer old data or new data?'], {
							{ szOption = _L['Old data'], fnAction = function() Next(false) end },
							{ szOption = _L['New data'], fnAction = function() Next(true) end },
						})
					else
						X.Alert(_L['Decode data failed!'])
					end
				end, function() end, function() end, nil, '' )
			end,
		})

		ui:Append('WndButton', {
			x = w - 110, y = y, w = 110,
			text = _L['Export'],
			buttonStyle = 'FLAT',
			onClick = function()
				UI.OpenTextEditor(X.EncodeLUAData({
					server   = X.GetRealServer(),
					publici  = PUBLIC_PLAYER_IDS,
					publicd  = PUBLIC_PLAYER_NOTES,
					privatei = PRIVATE_PLAYER_IDS,
					privated = PRIVATE_PLAYER_NOTES,
				}))
			end,
		})
	end

	y = y + 30
	local list = ui:Append('WndListBox', {
		x = x, y = y,
		w = w, h = h - 30,
		listBox = {{
			'onlclick',
			function(szID, szText, data, bSelected)
				MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
				return false
			end,
		}},
	})
	for dwID, t in pairs(PUBLIC_PLAYER_NOTES) do
		if tonumber(dwID) then
			list:ListBox('insert', { id = t.dwID, text = _L('[%s] %s', t.szName, t.szContent), data = t })
		end
	end
	_C.list = list
end
function PS.OnPanelDeactive()
	_C.list = nil
end
X.RegisterPanel(_L['Target'], 'MY_Anmerkungen_Player_Note', _L['Player note'], 'ui/Image/button/ShopButton.UITex|12', PS)
