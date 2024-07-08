--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色备注
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_PlayerMemo'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_PlayerMemo'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^24.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_PlayerMemo.Export', { ['*'] = true, intl = false })
--------------------------------------------------------------------------
local D = {
	bLoad = false,
	aMemo = {}, -- 备注列表
	tMemoCache = {}, -- 高速缓存
}
local PUBLIC_PLAYER_IDS = {}
local PUBLIC_PLAYER_NOTES = {}
local DB_ERR_COUNT, DB_MAX_ERR_COUNT = 0, 5
local DB, DBP_W, DBP_RI, DBP_RN, DBP_RGI, DBT_W, DBT_RI
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }

local function ExtractNameServer(szName, bFallbackServer)
	local a = X.SplitString(szName, g_tStrings.STR_CONNECT)
	if bFallbackServer and not a[2] then
		a[2] = X.GetServerOriginName()
	end
	return a[1], a[2]
end

local function CombineNameServer(szName, szServerName)
	return szName .. g_tStrings.STR_CONNECT .. szServerName
end

local function InitDB()
	if DB then
		return true
	end
	if DB_ERR_COUNT > DB_MAX_ERR_COUNT then
		return false
	end
	CPath.MakeDir(X.FormatPath({'userdata/player_memo/', X.PATH_TYPE.GLOBAL}))
	DB = X.SQLiteConnect(_L['MY_PlayerMemo'], {'userdata/player_memo/player_memo.v3.db', X.PATH_TYPE.GLOBAL})
	if not DB then
		local szMsg = _L['Cannot connect to database!!!']
		if DB_ERR_COUNT > 0 then
			szMsg = szMsg .. _L(' Retry time: %d', DB_ERR_COUNT)
		end
		DB_ERR_COUNT = DB_ERR_COUNT + 1
		X.OutputSystemMessage(_L['MY_PlayerMemo'], szMsg, X.CONSTANT.MSG_THEME.ERROR)
		return false
	end
	DB:Execute([[
		CREATE TABLE IF NOT EXISTS Info (
			key NVARCHAR(128) NOT NULL,
			value NVARCHAR(4096) NOT NULL,
			PRIMARY KEY (key)
		)
	]])
	DB:Execute([[INSERT INTO Info (key, value) VALUES ('version', '3')]])
	DB:Execute([[
		CREATE TABLE IF NOT EXISTS PlayerInfo (
			server NVARCHAR(10) NOT NULL,
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			guid NVARCHAR(20) NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY (server, id)
		)
	]])
	DB:Execute('CREATE UNIQUE INDEX IF NOT EXISTS player_info_server_name_u_idx ON PlayerInfo(server, name)')
	DB:Execute('CREATE INDEX IF NOT EXISTS player_info_guid_idx ON PlayerInfo(guid)')
	DBP_W  = DB:Prepare('REPLACE INTO PlayerInfo (server, id, name, guid, extra) VALUES (?, ?, ?, ?, ?)')
	DBP_RI = DB:Prepare('SELECT id as dwID, name as szName, guid as szGlobalID, extra as szExtra FROM PlayerInfo WHERE server = ? AND id = ?')
	DBP_RN = DB:Prepare('SELECT id as dwID, name as szName, guid as szGlobalID, extra as szExtra FROM PlayerInfo WHERE server = ? AND name = ?')
	DBP_RGI = DB:Prepare('SELECT id as dwID, name as szName, guid as szGlobalID, extra as szExtra FROM PlayerInfo WHERE guid = ? ORDER BY time DESC')

	return true
end
InitDB()

local function ReleaseDB()
	if not DB then
		return
	end
	DB:Release()
end

function D.Migrate()
	if not X.GetClientPlayer() then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_PlayerMemo.Migrate', 'Client player not exist! Cannot migrate!', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	local szFilePath = X.FormatPath({'config/anmerkungen.jx3dat', X.PATH_TYPE.SERVER})
	if not IsLocalFileExist(szFilePath) then
		return
	end
	local szServerName = X.GetServerOriginName()
	if IsLocalFileExist(szFilePath) then
		local data = X.LoadLUAData(szFilePath)
		if data then
			for _, v in ipairs(data.data or {}) do
				DBP_W:ClearBindings()
				DBP_W:BindAll(
					AnsiToUTF8(szServerName),
					v.dwID,
					AnsiToUTF8(v.szName),
					'',
					X.EncodeLUAData({
						szContent = v.szContent,
						bTipWhenGroup = v.bTipWhenGroup,
						bAlertWhenGroup = v.bAlertWhenGroup,
					})
				)
				DBP_W:Execute()
			end
		end
		CPath.Move(szFilePath, szFilePath .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
	end
	FireUIEvent('MY_PLAYER_MEMO_UPDATE')
end

-- 读取公共数据
function D.LoadConfig()
	local data = X.LoadLUAData({'config/player_memo.jx3dat', X.PATH_TYPE.GLOBAL})
	if data then
		D.aMemo = data.aMemo or {}
		D.UpdateMemoCache()
	end
	D.bLoad = true
end

-- 保存公共数据
function D.SaveConfig()
	local data = {
		aMemo = D.aMemo,
	}
	X.SaveLUAData({'config/player_memo.jx3dat', X.PATH_TYPE.SERVER}, data)
end

function D.UpdateMemoCache()
	local tMemoCache = {}
	for _, v in ipairs(D.aMemo) do
		if v.szServerName and v.dwID then
			tMemoCache[v.szServerName .. g_tStrings.STR_CONNECT .. v.dwID] = v
		end
		if v.szServerName and v.szName then
			tMemoCache[v.szServerName .. g_tStrings.STR_CONNECT .. v.szName] = v
		end
		if v.szGlobalID then
			tMemoCache[v.szGlobalID] = v
		end
	end
	D.tMemoCache = tMemoCache
end

---通过角色、ID或角色唯一ID获取信息，获取角色的记录
---@param xKey string | number @角色名、角色ID或角色唯一ID，其中通过ID只能获取当前服务器角色记录或跨服玩家角色记录，通过角色名或角色唯一ID可以获取其他服务器角色记录
---@return table | nil @获取成功返回记录，否则返回空
function D.Get(xKey)
	if not InitDB() then
		return
	end
	local tMemo
	if X.IsNumber(xKey) then
		local szServer = X.GetServerOriginName()
		DBP_RI:ClearBindings()
		DBP_RI:BindAll(AnsiToUTF8(szServer), xKey)
		tMemo = X.ConvertToANSI((DBP_RI:GetNext()))
		DBP_RI:Reset()
	elseif X.IsGlobalID(xKey) then
		DBP_RGI:ClearBindings()
		DBP_RGI:BindAll(AnsiToUTF8(xKey))
		tMemo = X.ConvertToANSI((DBP_RGI:GetNext()))
		DBP_RGI:Reset()
	elseif X.IsString(xKey) then
		local szName, szServer = ExtractNameServer(xKey, true)
		xKey = CombineNameServer(szName, szServer)
		DBP_RN:ClearBindings()
		DBP_RN:BindAll(AnsiToUTF8(szServer), AnsiToUTF8(szName))
		tMemo = X.ConvertToANSI((DBP_RN:GetNext()))
		DBP_RN:Reset()
	end
	if tMemo then
		local tExtra = X.DecodeLUAData(tMemo.szExtra) or {}
		tMemo.szExtra = nil
		tMemo.szContent = tExtra.szContent
		tMemo.bTipWhenGroup = tExtra.bTipWhenGroup
		tMemo.bAlertWhenGroup = tExtra.bAlertWhenGroup
	end
	return tMemo
end

-- 设置一个玩家的记录
function D.Set(szServerName, dwID, szName, szGlobalID, szContent, bTipWhenGroup, bAlertWhenGroup)
	D.LoadConfig()
	-- remove
	local rec = PUBLIC_PLAYER_NOTES[dwID]
	if rec then
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
		PUBLIC_PLAYER_NOTES[dwID] = t
		PUBLIC_PLAYER_IDS[szName] = dwID
		if D.uiList then
			D.uiList:ListBox('update', 'id', dwID, {'text', 'data'}, { _L('[%s] %s', t.szName, t.szContent), t })
		end
	elseif D.uiList then
		D.uiList:ListBox('delete', 'id', dwID)
	end
	FireUIEvent('MY_PLAYER_MEMO_UPDATE')
	if X.GetCurrentTabID() == 'MY_PlayerMemo' then
		X.SwitchTab('MY_PlayerMemo', true)
	end
	D.SaveConfig()
end

---删除一个玩家的记录
function D.Delete(szServerName, dwID, szName, szGlobalID)
	for i, v in X.ipairs_r(D.aMemo) do
		if (v.szServerName == szServerName and v.dwID == dwID)
		or (v.szSenderName == szServerName and v.szName == szName)
		or (v.szGlobalID == szGlobalID) then
			table.remove(D.aMemo, i)
		end
	end
	D.SaveConfig()
	D.UpdateMemoCache()
end

-- 当有玩家进队时
function D.CheckPartyPlayer(dwID)
	local kTeam = GetClientTeam()
	local dwLeaderID = kTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
	local t = D.Get(dwID)
	if t then
		if t.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_PlayerMemo_' .. t.dwID,
				szMessage = dwID == dwLeaderID
					and _L('Tip: [%s](Leader) is in your team.\nNote: %s', t.szName, t.szContent)
					or _L('Tip: [%s] is in your team.\nNote: %s', t.szName, t.szContent),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if t.bTipWhenGroup then
			X.OutputSystemMessage(_L('Tip: [%s] is in your team.\nNote: %s', t.szName, t.szContent))
		end
	end
end

-- 打开一个玩家的记录编辑器
function D.OpenPlayerNoteEditPanel(szServerName, dwID, szName, szGlobalID)
	if not MY_Farbnamen then
		return X.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local note = D.GetPlayerNote(dwID) or {}

	local w, h = 340, 300
	local ui = X.UI.CreateFrame('MY_PlayerMemo_Edit_' .. GetStringCRC(szServerName) ..  '_' .. (dwID or 0), {
		w = w, h = h, anchor = 'CENTER',
		text = _L['MY_PlayerMemo Edit'],
	})

	local function IsValid()
		return ui and ui:Count() > 0
	end
	local function RemoveFrame()
		ui:Remove()
		return true
	end
	X.RegisterEsc('MY_PlayerMemo_Edit_' .. GetStringCRC(szServerName) ..  '_' .. (dwID or 0), IsValid, RemoveFrame)

	local function onRemove()
		X.RegisterEsc('MY_PlayerMemo_Edit_' .. GetStringCRC(szServerName) ..  '_' .. (dwID or 0))
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
			local rec = D.GetPlayerNote(szName) or {}
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
			D.Set(
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
		onHover = function(bIn) X.UI(this):Alpha((bIn and 255) or 200) end,
		onClick = function()
			D.Set(ui:Children('#WndEditBox_ID'):Text())
			ui:Remove()
		end,
	})

	-- init
	Station.SetFocusWindow(ui[1])
	ui:Children('#WndEditBox_Name'):Change()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_PlayerMemo',
	exports = {
		{
			fields = {
				'GetPlayerNote',
			},
			root = D,
		},
	},
}
MY_PlayerMemo = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterTargetAddonMenu('MY_PlayerMemo', function()
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.PLAYER then
		local p = X.GetObject(dwType, dwID)
		return {
			szOption = _L['Edit player note'],
			fnAction = function()
				X.DelayCall(1, function()
					D.OpenPlayerNoteEditPanel(p.dwID, p.szName)
				end)
			end
		}
	end
end)

X.RegisterAddonMenu('MY_PlayerMemo', {
	szOption = _L['View player memo'],
	fnAction = function()
		X.ShowPanel()
		X.FocusPanel()
		X.SwitchTab('MY_PlayerMemo')
	end,
})

X.RegisterEvent('PARTY_ADD_MEMBER', function()
	D.CheckPartyPlayer(arg1)
end)
-- X.RegisterEvent('PARTY_SYNC_MEMBER_DATA', OnPartyAddMember)

-- 当进队时
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', 'MY_PlayerMemo', function()
	local team = GetClientTeam()
	if not team then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		D.CheckPartyPlayer(dwID)
	end
end)

X.RegisterInit('MY_PlayerMemo', function()
	D.LoadConfig()
	D.Migrate()
end)

X.RegisterExit('MY_PlayerMemo', ReleaseDB)

--------------------------------------------------------------------------------
-- 界面注册
--------------------------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nX, nY = 0, 0

	ui:Append('WndButton', {
		x = nX, y = nY, w = 110,
		text = _L['Create'],
		buttonStyle = 'FLAT',
		onClick = function()
			D.OpenPlayerNoteEditPanel()
		end,
	})

	if not MY.IsRestricted('MY_PlayerMemo.Export') then
		local szOriginServer = X.GetRegionOriginName() .. '_' .. X.GetServerOriginName()
		ui:Append('WndButton', {
			x = nW - 230, y = nY, w = 110,
			text = _L['Import'],
			buttonStyle = 'FLAT',
			onClick = function()
				GetUserInput(_L['Please input import data:'], function(szVal)
					local config = X.DecodeLUAData(szVal)
					if config and config.server and config.public then
						if config.server ~= szOriginServer then
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
							D.SaveConfig()
							X.SwitchTab('MY_PlayerMemo', true)
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
			x = nW - 110, y = nY, w = 110,
			text = _L['Export'],
			buttonStyle = 'FLAT',
			onClick = function()
				X.UI.OpenTextEditor(X.EncodeLUAData({
					server   = szOriginServer,
					publici  = PUBLIC_PLAYER_IDS,
					publicd  = PUBLIC_PLAYER_NOTES,
				}))
			end,
		})
	end

	nY = nY + 30
	local list = ui:Append('WndListBox', {
		x = nX, y = nY,
		w = nW, h = nH - 30,
		listBox = {{
			'onlclick',
			function(szID, szText, data, bSelected)
				D.OpenPlayerNoteEditPanel(data.dwID, data.szName)
				return false
			end,
		}},
	})
	for dwID, t in pairs(PUBLIC_PLAYER_NOTES) do
		if tonumber(dwID) then
			list:ListBox('insert', { id = t.dwID, text = _L('[%s] %s', t.szName, t.szContent), data = t })
		end
	end
	D.uiList = list
end
function PS.OnPanelDeactive()
	D.uiList = nil
end
X.RegisterPanel(_L['Target'], 'MY_PlayerMemo', _L['Player note'], 'ui/Image/button/ShopButton.UITex|12', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
