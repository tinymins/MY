--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色小本本
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Anmerkungen'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
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
		return LIB.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}

	local w, h = 340, 300
	local ui = UI.CreateFrame('MY_Anmerkungen_PlayerNoteEdit_' .. (dwID or 0), {
		w = w, h = h, anchor = 'CENTER',
		text = _L['my anmerkungen - player note edit'],
	})

	local function IsValid()
		return ui and ui:Count() > 0
	end
	local function RemoveFrame()
		ui:Remove()
		return true
	end
	LIB.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', IsValid, RemoveFrame)

	local function onRemove()
		LIB.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	ui:Remove(onRemove)

	local x, y = 35 , 50
	ui:Append('Text', { x = x, y = y, text = _L['Name:'] })
	ui:Append('WndEditBox', {
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
		text = _L['alert when group'],
		checked = note.bAlertWhenGroup,
	})
	y = y + 20

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_TipWhenGroup',
		x = x + 58, y = y, w = 200,
		text = _L['tip when group'],
		checked = note.bTipWhenGroup,
	})
	y = y + 30

	ui:Append('WndButton', {
		name = 'WndButton_Submit',
		x = x + 58, y = y, w = 80,
		text = _L['sure'],
		onclick = function()
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
		onclick = function() ui:Remove() end,
	})
	ui:Append('Text', {
		x = x + 230, y = y - 3, w = 80, alpha = 200,
		text = _L['delete'], color = {255,0,0},
		onhover = function(bIn) UI(this):Alpha((bIn and 255) or 200) end,
		onclick = function()
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
	local dwType, dwID = LIB.GetTarget()
	if dwType == TARGET.PLAYER then
		local p = LIB.GetObject(dwType, dwID)
		return {
			szOption = _L['edit player note'],
			fnAction = function()
				LIB.DelayCall(1, function()
					MY_Anmerkungen.OpenPlayerNoteEditPanel(p.dwID, p.szName)
				end)
			end
		}
	end
end
LIB.RegisterTargetAddonMenu('MY_Anmerkungen_PlayerNotes', onMenu)
end

do
local menu = {
	szOption = _L['View anmerkungen'],
	fnAction = function()
		LIB.ShowPanel()
		LIB.FocusPanel()
		LIB.SwitchTab('MY_Anmerkungen')
	end,
}
LIB.RegisterAddonMenu('MY_Anmerkungen_PlayerNotes', menu)
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
		t = Clone(rec)
		t.bPrivate = true
		return t
	end
	rec = PUBLIC_PLAYER_NOTES[PUBLIC_PLAYER_IDS[dwID] or dwID]
	if rec then
		t = Clone(rec)
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
			LIB.Sysmsg({_L('Tip: [%s] is in your team.\nNote: %s', t.szName, t.szContent)})
		end
	end
end

do
local function OnPartyAddMember()
	CheckPartyPlayer(arg1)
end
LIB.RegisterEvent('PARTY_ADD_MEMBER', OnPartyAddMember)
-- LIB.RegisterEvent('PARTY_SYNC_MEMBER_DATA', OnPartyAddMember)
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
LIB.RegisterEvent('PARTY_UPDATE_BASE_INFO.MY_Anmerkungen', OnEnterParty)
end
end

-- 读取公共数据
function MY_Anmerkungen.LoadConfig()
	if not GetClientPlayer() then
		--[[#DEBUG BEGIN]]
		LIB.Debug('Client player not exist! Cannot load config!', 'MY_Anmerkungen.LoadConfig', DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end

	local data = LIB.LoadLUAData({'config/anmerkungen.jx3dat', PATH_TYPE.SERVER})
	if data then
		PUBLIC_PLAYER_IDS = data.ids or {}
		PUBLIC_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = LIB.GetLUADataPath({'config/PLAYER_NOTES/${relserver}.${lang}.jx3dat', PATH_TYPE.DATA})
	local szFilePath = LIB.GetLUADataPath({'config/playernotes.jx3dat', PATH_TYPE.SERVER})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = LIB.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = LIB.JsonDecode(data)
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

	local data = LIB.LoadLUAData({'config/anmerkungen.jx3dat', PATH_TYPE.ROLE})
	if data then
		PRIVATE_PLAYER_IDS = data.ids or {}
		PRIVATE_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = LIB.GetLUADataPath({'config/PLAYER_NOTES/${uid}.${lang}.jx3dat', PATH_TYPE.DATA})
	local szFilePath = LIB.GetLUADataPath({'config/playernotes.jx3dat', PATH_TYPE.ROLE})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = LIB.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = LIB.JsonDecode(data)
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
	LIB.SaveLUAData({'config/anmerkungen.jx3dat', PATH_TYPE.SERVER}, data)

	local data = {
		ids = PRIVATE_PLAYER_IDS,
		data = PRIVATE_PLAYER_NOTES,
	}
	LIB.SaveLUAData({'config/anmerkungen.jx3dat', PATH_TYPE.ROLE}, data)
end
LIB.RegisterInit('MY_ANMERKUNGEN', MY_Anmerkungen.LoadConfig)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 0, 0

	ui:Append('WndButton2', {
		x = x, y = y, w = 110,
		text = _L['Create'],
		onclick = function()
			MY_Anmerkungen.OpenPlayerNoteEditPanel()
		end,
	})

	if not MY.IsShieldedVersion() then
		ui:Append('WndButton2', {
			x = w - 230, y = y, w = 110,
			text = _L['Import'],
			onclick = function()
				GetUserInput(_L['please input import data:'], function(szVal)
					local config = DecodeLUAData(szVal)
					if config and config.server and config.public and config.private then
						if config.server ~= LIB.GetRealServer() then
							return LIB.Alert(_L['Server not match!'])
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
							LIB.SwitchTab('MY_Anmerkungen_Player_Note', true)
						end
						LIB.Confirm(_L['Prefer old data or new data?'], function() Next(false) end,
							function() Next(true) end, _L['Old data'], _L['New data'])
					else
						LIB.Alert(_L['Decode data failed!'])
					end
				end, function() end, function() end, nil, '' )
			end,
		})

		ui:Append('WndButton2', {
			x = w - 110, y = y, w = 110,
			text = _L['Export'],
			onclick = function()
				UI.OpenTextEditor(EncodeLUAData({
					server   = LIB.GetRealServer(),
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
		listbox = {{
			'onlclick',
			function(hItem, szText, szID, data, bSelected)
				MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
				return false
			end,
		}},
	})
	for dwID, t in pairs(PUBLIC_PLAYER_NOTES) do
		if tonumber(dwID) then
			list:ListBox('insert', _L('[%s] %s', t.szName, t.szContent), t.dwID, t)
		end
	end
	_C.list = list
end
function PS.OnPanelDeactive()
	_C.list = nil
end
LIB.RegisterPanel( 'MY_Anmerkungen_Player_Note', _L['player note'], _L['Target'], 'ui/Image/button/ShopButton.UITex|12', PS)
