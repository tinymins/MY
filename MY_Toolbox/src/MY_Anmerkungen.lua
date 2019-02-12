--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色小本本
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/lang/')
if not MY.AssertVersion('MY_Anmerkungen', _L['MY_Anmerkungen'], 0x2011800) then
	return
end
local _C = {}
local PUBLIC_PLAYER_IDS = {}
local PUBLIC_PLAYER_NOTES = {}
local PRIVATE_PLAYER_IDS = {}
local PRIVATE_PLAYER_NOTES = {}
MY_Anmerkungen = MY_Anmerkungen or {}
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }

-- 打开一个玩家的记录编辑器
function MY_Anmerkungen.OpenPlayerNoteEditPanel(dwID, szName)
	if not MY_Farbnamen then
		return MY.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}

	local w, h = 340, 300
	local ui = UI.CreateFrame('MY_Anmerkungen_PlayerNoteEdit_' .. (dwID or 0), {
		w = w, h = h, anchor = {},
		text = _L['my anmerkungen - player note edit'],
	})

	local function IsValid()
		return ui and ui:count() > 0
	end
	local function RemoveFrame()
		ui:remove()
		return true
	end
	MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', IsValid, RemoveFrame)

	local function onRemove()
		MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	ui:remove(onRemove)

	local x, y = 35 , 50
	ui:append('Text', { x = x, y = y, text = _L['Name:'] })
	ui:append('WndEditBox', {
		name = 'WndEditBox_Name',
		x = x + 60, y = y, w = 200, h = 25,
		multiline = false, text = szName or note.szName or '',
		onchange = function(szName)
			local rec = MY_Anmerkungen.GetPlayerNote(szName) or {}
			local info = MY_Farbnamen and MY_Farbnamen.GetAusName(szName)
			if info and rec.dwID ~= info.dwID then
				rec.dwID = info.dwID
				rec.szContent = ''
				rec.bTipWhenGroup = true
				rec.bAlertWhenGroup = false
			end
			if rec.dwID then
				ui:children('#WndButton_Submit'):enable(true)
				ui:children('#WndEditBox_ID'):text(rec.dwID)
				ui:children('#WndEditBox_Content'):text(rec.szContent)
				ui:children('#WndCheckBox_TipWhenGroup'):check(rec.bTipWhenGroup)
				ui:children('#WndCheckBox_AlertWhenGroup'):check(rec.bAlertWhenGroup)
			else
				ui:children('#WndButton_Submit'):enable(false)
				ui:children('#WndEditBox_ID'):text(_L['Not found in local store'])
			end
		end,
	})
	y = y + 30

	ui:append('Text', { x = x, y = y, text = _L['ID:'] })
	ui:append('WndEditBox', {
		name = 'WndEditBox_ID', x = x + 60, y = y, w = 200, h = 25,
		text = dwID or note.dwID or '',
		multiline = false, enable = false, color = {200,200,200},
	})
	y = y + 30

	ui:append('Text', { x = x, y = y, text = _L['Content:'] })
	ui:append('WndEditBox', {
		name = 'WndEditBox_Content',
		x = x + 60, y = y, w = 200, h = 80,
		multiline = true, text = note.szContent or '',
	})
	y = y + 90

	ui:append('WndCheckBox', {
		name = 'WndCheckBox_AlertWhenGroup',
		x = x + 58, y = y, w = 200,
		text = _L['alert when group'],
		checked = note.bAlertWhenGroup,
	})
	y = y + 20

	ui:append('WndCheckBox', {
		name = 'WndCheckBox_TipWhenGroup',
		x = x + 58, y = y, w = 200,
		text = _L['tip when group'],
		checked = note.bTipWhenGroup,
	})
	y = y + 30

	ui:append('WndButton', {
		name = 'WndButton_Submit',
		x = x + 58, y = y, w = 80,
		text = _L['sure'],
		onclick = function()
			MY_Anmerkungen.SetPlayerNote(
				ui:children('#WndEditBox_ID'):text(),
				ui:children('#WndEditBox_Name'):text(),
				ui:children('#WndEditBox_Content'):text(),
				ui:children('#WndCheckBox_TipWhenGroup'):check(),
				ui:children('#WndCheckBox_AlertWhenGroup'):check()
			)
			ui:remove()
		end,
	})
	ui:append('WndButton', {
		x = x + 143, y = y, w = 80,
		text = _L['cancel'],
		onclick = function() ui:remove() end,
	})
	ui:append('Text', {
		x = x + 230, y = y - 3, w = 80, alpha = 200,
		text = _L['delete'], color = {255,0,0},
		onhover = function(bIn) UI(this):alpha((bIn and 255) or 200) end,
		onclick = function()
			MY_Anmerkungen.SetPlayerNote(ui:children('#WndEditBox_ID'):text())
			ui:remove()
		end,
	})

	-- init
	Station.SetFocusWindow(ui[1])
	ui:children('#WndEditBox_Name'):change()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

do
local function onMenu()
	local dwType, dwID = MY.GetTarget()
	if dwType == TARGET.PLAYER then
		local p = MY.GetObject(dwType, dwID)
		return {
			szOption = _L['edit player note'],
			fnAction = function()
				MY.DelayCall(1, function()
					MY_Anmerkungen.OpenPlayerNoteEditPanel(p.dwID, p.szName)
				end)
			end
		}
	end
end
MY.RegisterTargetAddonMenu('MY_Anmerkungen_PlayerNotes', onMenu)
end

do
local menu = {
	szOption = _L['View anmerkungen'],
	fnAction = function()
		MY.ShowPanel()
		MY.FocusPanel()
		MY.SwitchTab('MY_Anmerkungen')
	end,
}
MY.RegisterAddonMenu('MY_Anmerkungen_PlayerNotes', menu)
end

-- 获取一个玩家的记录
-- MY_Anmerkungen.GetPlayerNote(dwID)
-- MY_Anmerkungen.GetPlayerNote(szName)
function MY_Anmerkungen.GetPlayerNote(dwID)
	local t
	local rec = PRIVATE_PLAYER_NOTES[PRIVATE_PLAYER_IDS[dwID] or dwID]
	if rec then
		t = clone(rec)
		t.bPrivate = true
	else
		rec = PUBLIC_PLAYER_NOTES[PUBLIC_PLAYER_IDS[dwID] or dwID]
		if rec then
			t = clone(rec)
			t.bPrivate = false
		end
	end
	return t
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
			_C.list:listbox('update', 'id', dwID, {'text', 'data'}, { _L('[%s] %s', t.szName, t.szContent), t })
		end
	elseif _C.list then
		_C.list:listbox('delete', 'id', dwID)
	end
	MY_Anmerkungen.SaveConfig()
end

-- 当有玩家进队时
do
local function OnPartyAddMember()
	local dwID = arg1
	local team = GetClientTeam()
	local szName = team.GetClientTeamMemberName(dwID)
	-- local dwLeaderID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
	-- local szLeaderName = team.GetClientTeamMemberName(dwLeader)
	local t = MY_Anmerkungen.GetPlayerNote(dwID)
	if t then
		if t.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_Anmerkungen_PlayerNotes_'..t.dwID,
				szMessage = _L('Tip: [%s] is in your team.\nNote: %s\n', t.szName, t.szContent),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if t.bTipWhenGroup then
			MY.Sysmsg({_L('Tip: [%s] is in your team.\nNote: %s', t.szName, t.szContent)})
		end
	end
end
MY.RegisterEvent('PARTY_ADD_MEMBER', OnPartyAddMember)
-- MY.RegisterEvent('PARTY_SYNC_MEMBER_DATA', OnPartyAddMember)
end

-- 读取公共数据
function MY_Anmerkungen.LoadConfig()
	local data = MY.LoadLUAData({'config/anmerkungen.jx3dat', MY_DATA_PATH.SERVER})
	if data then
		PUBLIC_PLAYER_IDS = data.ids or {}
		PUBLIC_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = MY.GetLUADataPath('config/PLAYER_NOTES/$relserver.$lang.jx3dat')
	local szFilePath = MY.GetLUADataPath({'config/playernotes.jx3dat', MY_DATA_PATH.SERVER})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = MY.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = MY.JsonDecode(data)
		end
		for k, v in pairs(data) do
			if type(v) == 'table' then
				k = tonumber(k)
				v.dwID = tonumber(v.dwID)
				PUBLIC_PLAYER_NOTES[k] = v
			else
				PUBLIC_PLAYER_IDS[k] = tonumber(v)
			end
		end
		CPath.DelFile(szFilePath)
		MY_Anmerkungen.SaveConfig()
	end

	local data = MY.LoadLUAData({'config/anmerkungen.jx3dat', MY_DATA_PATH.ROLE})
	if data then
		PRIVATE_PLAYER_IDS = data.ids or {}
		PRIVATE_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = MY.GetLUADataPath('config/PLAYER_NOTES/$uid.$lang.jx3dat')
	local szFilePath = MY.GetLUADataPath({'config/playernotes.jx3dat', MY_DATA_PATH.ROLE})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = MY.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = MY.JsonDecode(data)
		end
		for k, v in pairs(data) do
			if type(v) == 'table' then
				k = tonumber(k)
				v.dwID = tonumber(v.dwID)
				PRIVATE_PLAYER_NOTES[k] = v
			else
				PRIVATE_PLAYER_IDS[k] = tonumber(v)
			end
		end
		CPath.DelFile(szFilePath)
		MY_Anmerkungen.SaveConfig()
	end
end
-- 保存公共数据
function MY_Anmerkungen.SaveConfig()
	local data = {
		ids = PUBLIC_PLAYER_IDS,
		data = PUBLIC_PLAYER_NOTES,
	}
	MY.SaveLUAData({'config/anmerkungen.jx3dat', MY_DATA_PATH.SERVER}, data)

	local data = {
		ids = PRIVATE_PLAYER_IDS,
		data = PRIVATE_PLAYER_NOTES,
	}
	MY.SaveLUAData({'config/anmerkungen.jx3dat', MY_DATA_PATH.ROLE}, data)
end
MY.RegisterInit('MY_ANMERKUNGEN', MY_Anmerkungen.LoadConfig)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local x, y = 0, 0

	ui:append('WndButton2', {
		x = x, y = y, w = 110,
		text = _L['Create'],
		onclick = function()
			MY_Anmerkungen.OpenPlayerNoteEditPanel()
		end,
	})

	ui:append('WndButton2', {
		x = w - 230, y = y, w = 110,
		text = _L['Import'],
		onclick = function()
			GetUserInput(_L['please input import data:'], function(szVal)
				local config = str2var(szVal)
				if config and config.server and config.public and config.private then
					if config.server ~= MY.GetRealServer() then
						return MY.Alert(_L['Server not match!'])
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
						MY.SwitchTab('MY_Anmerkungen_Player_Note', true)
					end
					MY.Confirm(_L['Prefer old data or new data?'], function() Next(false) end,
						function() Next(true) end, _L['Old data'], _L['New data'])
				else
					MY.Alert(_L['Decode data failed!'])
				end
			end, function() end, function() end, nil, '' )
		end,
	})

	ui:append('WndButton2', {
		x = w - 110, y = y, w = 110,
		text = _L['Export'],
		onclick = function()
			UI.OpenTextEditor(var2str({
				server   = MY.GetRealServer(),
				publici  = PUBLIC_PLAYER_IDS,
				publicd  = PUBLIC_PLAYER_NOTES,
				privatei = PRIVATE_PLAYER_IDS,
				privated = PRIVATE_PLAYER_NOTES,
			}))
		end,
	})

	y = y + 30
	local list = ui:append('WndListBox', {
		x = x, y = y,
		w = w, h = h - 30,
		listbox = {{
			'onlclick',
			function(hItem, szText, szID, data, bSelected)
				MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
				return false
			end,
		}},
	}, true)
	for dwID, t in pairs(PUBLIC_PLAYER_NOTES) do
		if tonumber(dwID) then
			list:listbox('insert', _L('[%s] %s', t.szName, t.szContent), t.dwID, t)
		end
	end
	_C.list = list
end
function PS.OnPanelDeactive()
	_C.list = nil
end
MY.RegisterPanel( 'MY_Anmerkungen_Player_Note', _L['player note'], _L['Target'], 'ui/Image/button/ShopButton.UITex|12', PS)
