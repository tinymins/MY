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
local MODULE_PATH = 'MY_Toolbox/MY_PlayerRemark'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_PlayerRemark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^24.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_PlayerRemark.Export', { ['*'] = true, intl = false })
--------------------------------------------------------------------------
local D = {}
local DB_ERR_COUNT, DB_MAX_ERR_COUNT = 0, 5
local DB, DBP_W, DBP_DN, DBP_DG, DBP_R, DBP_RI, DBP_RN, DBP_RGI

local function IsGlobalID(szGlobalID)
	return szGlobalID and szGlobalID ~= '' and szGlobalID ~= '0'
end

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
	CPath.MakeDir(X.FormatPath({'userdata/player_remark/', X.PATH_TYPE.GLOBAL}))
	DB = X.SQLiteConnect(_L['MY_PlayerRemark'], {'userdata/player_remark/player_remark.v3.db', X.PATH_TYPE.GLOBAL})
	if not DB then
		local szMsg = _L['Cannot connect to database!!!']
		if DB_ERR_COUNT > 0 then
			szMsg = szMsg .. _L(' Retry time: %d', DB_ERR_COUNT)
		end
		DB_ERR_COUNT = DB_ERR_COUNT + 1
		X.OutputSystemMessage(_L['MY_PlayerRemark'], szMsg, X.CONSTANT.MSG_THEME.ERROR)
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
		CREATE TABLE IF NOT EXISTS PlayerRemark (
			server NVARCHAR(10) NOT NULL,
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			guid NVARCHAR(20) NOT NULL,
			remark NVARCHAR(255) NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY (server, id)
		)
	]])
	DB:Execute('CREATE UNIQUE INDEX IF NOT EXISTS player_info_server_name_u_idx ON PlayerRemark(server, name)')
	DB:Execute('CREATE INDEX IF NOT EXISTS player_info_guid_idx ON PlayerRemark(guid)')
	DBP_W = DB:Prepare('REPLACE INTO PlayerRemark (server, id, name, guid, remark, extra) VALUES (?, ?, ?, ?, ?, ?)')
	DBP_DN = DB:Prepare('DELETE FROM PlayerRemark WHERE server = ? AND name = ?')
	DBP_DG = DB:Prepare('DELETE FROM PlayerRemark WHERE guid = ?')
	DBP_R = DB:Prepare('SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark')
	DBP_RI = DB:Prepare('SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark WHERE server = ? AND id = ?')
	DBP_RN = DB:Prepare('SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark WHERE server = ? AND name = ?')
	DBP_RGI = DB:Prepare('SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark WHERE guid = ?')

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
		X.OutputDebugMessage('MY_PlayerRemark.Migrate', 'Client player not exist! Cannot migrate!', X.DEBUG_LEVEL.ERROR)
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
			for _, v in pairs(data.data or {}) do
				DBP_W:ClearBindings()
				DBP_W:BindAll(
					AnsiToUTF8(szServerName),
					v.dwID,
					AnsiToUTF8(v.szName),
					'',
					AnsiToUTF8(v.szContent),
					X.EncodeLUAData({
						bTipWhenGroup = v.bTipWhenGroup,
						bAlertWhenGroup = v.bAlertWhenGroup,
					})
				)
				DBP_W:Execute()
			end
		end
		-- CPath.Move(szFilePath, szFilePath .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
	end
	FireUIEvent('MY_PLAYER_REMARK_UPDATE')
end

function D.GetAll()
	if not InitDB() then
		return
	end
	DBP_R:ClearBindings()
	local aInfo = X.ConvertToAnsi((DBP_R:GetAll()))
	DBP_R:Reset()
	return aInfo
end

---通过角色、ID或角色唯一ID获取信息，获取角色的记录
---@param xKey string | number @角色名、角色ID或角色唯一ID，其中通过ID只能获取当前服务器角色记录或跨服玩家角色记录，通过角色名或角色唯一ID可以获取其他服务器角色记录
---@return table | nil @获取成功返回记录，否则返回空
function D.Get(xKey)
	if not InitDB() then
		return
	end
	local tInfo
	if X.IsNumber(xKey) then
		local szServer = X.GetServerOriginName()
		DBP_RI:ClearBindings()
		DBP_RI:BindAll(AnsiToUTF8(szServer), xKey)
		tInfo = X.ConvertToAnsi((DBP_RI:GetNext()))
		DBP_RI:Reset()
	elseif X.IsString(xKey) and string.find(xKey, '^[0-9]+$') then
		DBP_RGI:ClearBindings()
		DBP_RGI:BindAll(AnsiToUTF8(xKey))
		tInfo = X.ConvertToAnsi((DBP_RGI:GetNext()))
		DBP_RGI:Reset()
	elseif X.IsString(xKey) then
		local szName, szServer = ExtractNameServer(xKey, true)
		xKey = CombineNameServer(szName, szServer)
		DBP_RN:ClearBindings()
		DBP_RN:BindAll(AnsiToUTF8(szServer), AnsiToUTF8(szName))
		tInfo = X.ConvertToAnsi((DBP_RN:GetNext()))
		DBP_RN:Reset()
	end
	if tInfo then
		local tExtra = X.DecodeLUAData(tInfo.szExtra) or {}
		tInfo.szExtra = nil
		tInfo.bTipWhenGroup = tExtra.bTipWhenGroup
		tInfo.bAlertWhenGroup = tExtra.bAlertWhenGroup
	end
	return tInfo
end

-- 设置一个玩家的记录
function D.Set(szServerName, dwID, szName, szGlobalID, szRemark, bTipWhenGroup, bAlertWhenGroup)
	DBP_W:ClearBindings()
	DBP_W:BindAll(
		AnsiToUTF8(szServerName),
		dwID,
		AnsiToUTF8(szName),
		AnsiToUTF8(szGlobalID),
		AnsiToUTF8(szRemark),
		X.EncodeLUAData({
			bTipWhenGroup = bTipWhenGroup,
			bAlertWhenGroup = bAlertWhenGroup,
		})
	)
	DBP_W:Execute()
	FireUIEvent('MY_PLAYER_REMARK_UPDATE')
end

---删除一个玩家的记录
function D.Delete(szServerName, szName, szGlobalID)
	if szServerName and szName then
		DBP_DN:ClearBindings()
		DBP_DN:BindAll(
			AnsiToUTF8(szServerName),
			AnsiToUTF8(szName)
		)
		DBP_DN:Execute()
	end
	if szGlobalID then
		DBP_DG:ClearBindings()
		DBP_DG:BindAll(
			AnsiToUTF8(szGlobalID)
		)
		DBP_DG:Execute()
	end
	FireUIEvent('MY_PLAYER_REMARK_UPDATE')
end

-- 当有玩家进队时
function D.CheckPartyPlayer(dwID)
	local bLeader = X.IsLeader(dwID)
	local tMember = X.GetTeamMemberInfo(dwID)
	local tPlayer = D.Get(tMember.szGlobalID or tMember.szName)
	if tPlayer then
		if tPlayer.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_PlayerRemark_' .. tPlayer.dwID,
				szMessage = bLeader
					and _L('Tip: [%s](Leader) is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark)
					or _L('Tip: [%s] is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if tPlayer.bTipWhenGroup then
			X.OutputSystemMessage(_L('Tip: [%s] is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark))
		end
	end
end

-- 当有玩家进房间时
function D.CheckRoomPlayer(szGlobalID)
	local tMember = X.GetRoomMemberInfo(szGlobalID)
	local szServerName = tMember and X.GetServerNameByID(tMember.dwServerID)
	local tPlayer = (tMember and D.Get(tMember.szGlobalID))
		or (szServerName and D.Get(CombineNameServer(tMember.szName, szServerName)))
	if tPlayer then
		if tPlayer.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_PlayerRemark_' .. tPlayer.dwID,
				szMessage = _L('Tip: [%s] is in your room.\nRemark: %s', tPlayer.szName, tPlayer.szRemark),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if tPlayer.bTipWhenGroup then
			X.OutputSystemMessage(_L('Tip: [%s] is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark))
		end
	end
end

-- 打开一个玩家的记录编辑器
function D.OpenPlayerRemarkEditPanel(szServerName, dwID, szName, szGlobalID)
	if not MY_Farbnamen then
		return X.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local szRemark, bTipWhenGroup, bAlertWhenGroup = '', false, false
	do
		local tInfo
		if not tInfo and IsGlobalID(szGlobalID) then
			tInfo = D.Get(szGlobalID)
		end
		if not tInfo then
			tInfo = D.Get(CombineNameServer(szName, szServerName))
		end
		if not tInfo and not IsRemotePlayer(dwID) then
			tInfo = D.Get(dwID)
		end
		if tInfo then
			-- szServerName = tInfo.szServerName
			dwID = X.IIf(IsRemotePlayer(dwID), tInfo.dwID, dwID)
			szRemark = tInfo.szRemark
			bTipWhenGroup = tInfo.bTipWhenGroup
			bAlertWhenGroup = tInfo.bAlertWhenGroup
		end
	end
	if IsRemotePlayer(dwID) then
		dwID = 0
	end

	local nW, nH = 400, 360
	local nPaddingX, nPaddingY = 35, 50
	local nX, nY = nPaddingX, nPaddingY
	local nRightW = 250

	local ui = X.UI.CreateFrame('MY_PlayerRemark_Edit_' .. GetStringCRC(szServerName) ..  '_' .. dwID, {
		w = nW, h = nH, anchor = 'CENTER',
		text = _L['MY_PlayerRemark Edit'],
	})

	ui:Remove(function()
		X.RegisterEsc('MY_PlayerRemark_Edit_' .. GetStringCRC(szServerName) ..  '_' .. dwID)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end)

	ui:Append('Text', { x = nX, y = nY, text = _L['Server:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		multiline = false, enable = false, color = {200,200,200},
		text = szServerName,
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Name:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		multiline = false, enable = false, color = {200,200,200},
		text = szName,
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['ID:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		text = dwID,
		multiline = false, enable = false, color = {200,200,200},
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['GUID:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		text = szGlobalID,
		multiline = false, enable = false, color = {200,200,200},
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Remark:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 80,
		multiline = true, text = szRemark,
		onChange = function (szText)
			szRemark = szText
		end,
	})
	nY = nY + 90

	nX = nPaddingX
	nX = nX + 80 - 2
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = nRightW,
		text = _L['Alert when group'],
		checked = bAlertWhenGroup,
		onCheck = function(bChecked)
			bAlertWhenGroup = bChecked
		end,
	})
	nY = nY + 20

	nX = nPaddingX
	nX = nX + 80 - 2
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = nRightW,
		text = _L['Tip when group'],
		checked = bTipWhenGroup,
		onCheck = function(bChecked)
			bTipWhenGroup = bChecked
		end,
	})
	nY = nY + 30

	nX = nPaddingX
	nX = nX + 80 - 2
	nX = nX + ui:Append('WndButton', {
		name = 'WndButton_Submit',
		x = nX, y = nY, h = 30, minWidth = nRightW / 3,
		text = _L['sure'],
		onClick = function()
			D.Set(
				szServerName,
				dwID,
				szName,
				szGlobalID,
				szRemark,
				bTipWhenGroup,
				bAlertWhenGroup
			)
			ui:Remove()
		end,
	}):Width() + 3
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, h = 30, minWidth = nRightW / 3,
		text = _L['cancel'],
		onClick = function() ui:Remove() end,
	}):Width() + 3
	nX = nX + ui:Append('Text', {
		x = nX, y = nY - 3, h = 30 + 3, minWidth = nRightW / 3, alpha = 200,
		alignHorizontal = 1, alignVertical = 1,
		text = _L['Delete'], color = {255,0,0},
		onHover = function(bIn) X.UI(this):Alpha((bIn and 255) or 200) end,
		onClick = function()
			D.Delete(
				szServerName,
				szName,
				szGlobalID
			)
			ui:Remove()
		end,
	}):Width() + 3

	-- init
	X.RegisterEsc(
		'MY_PlayerRemark_Edit_' .. GetStringCRC(szServerName) ..  '_' .. (dwID or 0),
		function()
			return ui and ui:Count() > 0
		end,
		function()
			ui:Remove()
			return true
		end
	)
	Station.SetFocusWindow(ui[1])
	ui:Children('#WndEditBox_Name'):Change()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_PlayerRemark',
	exports = {
		{
			fields = {
				'Get',
			},
			root = D,
		},
	},
}
MY_PlayerRemark = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterTargetAddonMenu('MY_PlayerRemark', function()
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.PLAYER then
		local kPlayer = X.GetObject(dwType, dwID)
		return {
			szOption = _L['Edit player remark'],
			fnAction = function()
				local szName, szServerName = ExtractNameServer(kPlayer.szName, true)
				local szGlobalID = X.GetPlayerGlobalID(dwID)
				D.OpenPlayerRemarkEditPanel(szServerName, dwID, szName, szGlobalID)
			end
		}
	end
end)

X.RegisterAddonMenu('MY_PlayerRemark', {
	szOption = _L['View player remark'],
	fnAction = function()
		X.ShowPanel()
		X.FocusPanel()
		X.SwitchTab('MY_PlayerRemark')
	end,
})

X.RegisterEvent('PARTY_ADD_MEMBER', function()
	D.CheckPartyPlayer(arg1)
end)
-- X.RegisterEvent('PARTY_SYNC_MEMBER_DATA', OnPartyAddMember)

-- 当进队时
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', 'MY_PlayerRemark', function()
	local team = GetClientTeam()
	if not team then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		D.CheckPartyPlayer(dwID)
	end
end)

X.RegisterEvent('JOIN_GLOBAL_ROOM', 'MY_PlayerRemark', function()
	X.DelayCall(2000, function()
		for _, szGlobalID in ipairs(X.GetRoomMemberList()) do
			D.CheckRoomPlayer(szGlobalID)
		end
	end)
end)

X.RegisterEvent('GLOBAL_ROOM_MEMBER_CHANGE', 'MY_PlayerRemark', function()
	local szGlobalID = arg1
	local bJoin = arg2
	local szName = arg3
	local dwSeverID = arg4
	if not bJoin then
		return
	end
	local szServerName = X.GetServerNameByID(dwSeverID)
	if not szServerName then
		return
	end
	D.CheckRoomPlayer(szGlobalID)
end)

X.RegisterEvent('MY_PLAYER_REMARK_UPDATE', 'MY_PlayerRemark', function()
	if X.GetCurrentTabID() == 'MY_PlayerRemark' then
		X.SwitchTab('MY_PlayerRemark', true)
	end
end)

X.RegisterInit('MY_PlayerRemark', function()
	D.Migrate()
end)

X.RegisterExit('MY_PlayerRemark', ReleaseDB)

--------------------------------------------------------------------------------
-- 界面注册
--------------------------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nX, nY = 0, 0

	local list = ui:Append('WndListBox', {
		x = nX, y = nY,
		w = nW, h = nH,
		listBox = {{
			'onlclick',
			function(szID, szText, data, bSelected)
				D.OpenPlayerRemarkEditPanel(data.szServerName, data.dwID, data.szName, data.szGlobalID)
				return false
			end,
		}},
	})
	for _, tInfo in ipairs(D.GetAll()) do
		list:ListBox('insert', {
			id = CombineNameServer(tInfo.szName, tInfo.szServerName),
			text = _L('[%s] %s', CombineNameServer(tInfo.szName, tInfo.szServerName), tInfo.szRemark),
			data = tInfo,
		})
	end
end
X.RegisterPanel(_L['Target'], 'MY_PlayerRemark', _L['Player remark'], 'ui/Image/button/ShopButton.UITex|12', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
