--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队告示
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamNotice'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {
	szYY = '',
	szNote = '',
}

local O = X.CreateUserSettingsModule('MY_TeamNotice', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_TeamNotice'],
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nWidth = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_TeamNotice'],
			_L['UI Width'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 320,
	},
	nHeight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_TeamNotice'],
			_L['UI Height'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 195,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_TeamNotice'],
			_L['UI Anchor'],
		}),
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
	},
})

function D.SaveList()
	X.SaveLUAData({'config/yy.jx3dat', X.PATH_TYPE.GLOBAL}, D.tList, { encoder = 'luatext', indent = '\t', passphrase = false, crc = false })
end

function D.GetList()
	if not D.tList then
		D.tList = X.LoadLUAData({'config/yy.jx3dat', X.PATH_TYPE.GLOBAL}, { passphrase = false }) or {}
	end
	return D.tList
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_TeamNotice')
end

function D.CreateFrame(szInitYY, szInitNote)
	if X.IsInZombieMap() then
		return
	end
	if szInitNote then
		szInitNote = X.ReplaceSensitiveWord(szInitNote)
	end
	local ui = D.GetFrame()
	if ui then
		ui = X.UI(ui)
		ui:Children('#YY'):Text(szInitYY, WNDEVENT_FIRETYPE.PREVENT)
		ui:Children('#Message'):Text(szInitNote, WNDEVENT_FIRETYPE.PREVENT)
	else
		local function FormatAllContentPos()
			if not ui then
				return
			end
			X.DelayCall('MY_TeamNotice#DragResize', 500, function()
				O.nWidth  = ui:Width()
				O.nHeight = ui:Height()
				O.anchor  = ui:Anchor()
			end)
			local nW, nH = ui:ContainerSize()
			ui:Fetch('YY'):Width(ui:Width() - 160)
			local uiBtn = ui:Fetch('Btn_YY')
			uiBtn:Left(nW - uiBtn:Width() - 10)
			local uiBtns = ui:Fetch('WndBtn_RaidTools'):Add(ui:Fetch('WndBtn_GKP')):Add(ui:Fetch('WndBtn_TeamMon'))
			uiBtns:Top(nH - uiBtns:Height() - 10)
			local uiMessage = ui:Fetch('Message')
			uiMessage:Size(nW - 20, uiBtns:Top() - uiMessage:Top() - 10)
		end
		ui = X.UI.CreateFrame('MY_TeamNotice', {
			w = O.nWidth, h = O.nHeight,
			text = _L['Team Message'],
			anchor = O.anchor,
			theme = X.UI.FRAME_THEME.SIMPLE, close = true, resize = true,
			minWidth = 320, minHeight = 195,
			setting = function()
				X.Panel.Show()
				X.Panel.Focus()
				X.Panel.SwitchTab('MY_TeamTools')
			end,
			onSizeChange = FormatAllContentPos,
		})
		local x, y = 10, 5
		x = x + ui:Append('Text', { x = x, y = y - 3, text = X.ENVIRONMENT.GAME_LANG == 'zhcn' and _L['YY:'] or _L['DC:'], font = 48 }):AutoWidth():Width() + 5
		x = x + ui:Append('WndAutocomplete', {
			name = 'YY',
			w = 160, h = 26, x = x, y = y,
			text = szInitYY, font = 48, color = { 128, 255, 0 },
			editType = X.UI.EDIT_TYPE.NUMBER,
			onClick = function()
				if IsPopupMenuOpened() then
					X.UI(this):Autocomplete('close')
				elseif X.IsClientPlayerTeamLeader() then
					X.UI(this):Autocomplete('search', '')
				end
			end,
			onBlur = function()
				local szText = X.UI(this):Text()
				if D.szYY == szText then
					return
				end
				if X.IsClientPlayerTeamLeader() then
					if not X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						D.szYY = szText
						X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'Edit', szText, ui:Children('#Message'):Text()})
						return
					end
					X.OutputSystemAnnounceMessage(_L['Please unlock talk lock first.'])
				end
				ui:Fetch('YY'):Text(D.szYY, WNDEVENT_FIRETYPE.PREVENT)
			end,
			autocomplete = {
				{
					'option', 'beforeSearch', function(text)
						local source = {}
						if X.IsClientPlayerTeamLeader() then
							D.tList = D.GetList()
							for k, v in pairs(D.tList) do
								table.insert(source, k)
							end
							if #source == 1 and tostring(source[1]) == text then
								source = {}
							end
						end
						X.UI(this):Autocomplete('option', 'source', source)
					end,
				},
				{
					'option', 'beforeDelete', function(szOption)
						D.tList[tonumber(szOption)] = nil
						D.SaveList()
					end,
				},
			},
		}):Width() + 5
		y = y + ui:Append('WndButton', {
			name = 'Btn_YY',
			x = x, y = y, text = X.IsClientPlayerTeamLeader()
				and (X.ENVIRONMENT.GAME_LANG == 'zhcn' and _L['Paste YY'] or _L['Paste DC'])
				or (X.ENVIRONMENT.GAME_LANG == 'zhcn' and _L['Copy YY'] or _L['Copy DC']),
			buttonStyle = 'FLAT',
			onClick = function()
				local yy = ui:Children('#YY'):Text()
				if X.IsClientPlayerTeamLeader() then
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
					end
					if tonumber(yy) then
						D.tList = D.GetList()
						if not D.tList[tonumber(yy)] then
							D.tList[tonumber(yy)] = true
							D.SaveList()
						end
					end
					if yy ~= '' then
						for i = 0, 2 do -- 发三次
							X.SendChat(PLAYER_TALK_CHANNEL.RAID, yy)
						end
					end
					local message = ui:Children('#Message'):Text():gsub('\n', ' ')
					if message ~= '' then
						X.SendChat(PLAYER_TALK_CHANNEL.RAID, message)
					end
				else
					SetDataToClip(yy)
					X.OutputAnnounceMessage(_L['Channel number has been copied to clipboard'])
				end
			end,
		}):Height() + 5
		ui:Append('WndEditBox', {
			name = 'Message',
			w = 300, h = 80, x = 10, y = y,
			multiline = true, limit = 512,
			text = szInitNote,
			onBlur = function()
				local szText = X.ReplaceSensitiveWord(X.UI(this):Text())
				if D.szNote == szText then
					return
				end
				if X.IsClientPlayerTeamLeader() then
					if not X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						D.szNote = szText
						X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'Edit', ui:Children('#YY'):Text(), szText})
						return
					end
					X.OutputSystemAnnounceMessage(_L['Please unlock talk lock first.'])
				end
				ui:Fetch('Message'):Text(D.szNote, WNDEVENT_FIRETYPE.PREVENT)
			end,
		})
		x, y = 11, 130
		x = x + ui:Append('WndButton', {
			name = 'WndBtn_RaidTools',
			x = x, y = y, w = 96,
			text = _L['MY_TeamTools'],
			buttonStyle = 'FLAT',
			onClick = MY_TeamTools.Toggle,
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndButton', {
			name = 'WndBtn_GKP',
			x = x, y = y, w = 96,
			text = _L['GKP Golden Team Record'],
			buttonStyle = 'FLAT',
			onClick = function()
				if MY_GKP then
					MY_GKP_MI.TogglePanel()
				else
					X.Alert(_L['You haven\'t had MY_GKP installed and loaded yet.'])
				end
			end,
		}):AutoWidth():Width() + 5
		if MY_TeamMon_Subscribe then
			x = x + ui:Append('WndButton', {
				name = 'WndBtn_TeamMon',
				x = x, y = y, w = 96,
				text = _L['Import Data'],
				buttonStyle = 'FLAT',
				onClick = MY_TeamMon_Subscribe.OpenPanel,
			}):AutoWidth():Width() + 5
		end
		FormatAllContentPos()
		-- 注册事件
		local frame = D.GetFrame()
		frame.OnFrameKeyDown = nil -- esc close --> nil
		frame:RegisterEvent('PARTY_DISBAND')
		frame:RegisterEvent('PARTY_DELETE_MEMBER')
		frame:RegisterEvent('PARTY_ADD_MEMBER')
		frame:RegisterEvent('UI_SCALED')
		frame:RegisterEvent('TEAM_AUTHORITY_CHANGED')
		frame.OnEvent = function(szEvent)
			if szEvent == 'PARTY_DISBAND' then
				ui:Remove()
			elseif szEvent == 'PARTY_DELETE_MEMBER' then
				if arg1 == X.GetClientPlayerID() then
					ui:Remove()
				end
			elseif szEvent == 'PARTY_ADD_MEMBER' then
				if X.IsClientPlayerTeamLeader() then
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						return
					end
					X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'reply', arg1, D.szYY, D.szNote})
				end
			elseif szEvent == 'UI_SCALED' then
				ui:Anchor(O.anchor)
			elseif szEvent == 'TEAM_AUTHORITY_CHANGED' then
				ui:Fetch('Btn_YY'):Text(X.IsClientPlayerTeamLeader() and _L['Paste YY'] or _L['Copy YY'])
			end
		end
		frame.OnFrameDragSetPosEnd = function()
			this:CorrectPos()
		end
		frame.OnFrameDragEnd = function()
			this:CorrectPos()
			O.anchor = GetFrameAnchor(this)
		end
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	D.szYY   = szInitYY or D.szYY
	D.szNote = szInitNote or D.szNote
end

function D.OpenFrame()
	if MY_TeamNoticeOfficial.bEnable then
		return MY_TeamNoticeOfficial.OpenFrame()
	end
	if X.IsInZombieMap() then
		return X.OutputAnnounceMessage(_L['TeamNotice is disabled in this map.'])
	end
	O.bEnable = true
	if X.IsClientPlayerInParty() then
		if X.IsClientPlayerTeamLeader() then
			D.CreateFrame()
		else
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'ASK'})
			X.OutputSystemMessage(_L['Asking..., If no response in longtime, team leader not enable plug-in.'])
		end
	end
end

X.RegisterEvent('PARTY_LEVEL_UP_RAID', 'TEAM_NOTICE', function()
	if X.IsInZombieMap() then
		return
	end
	if X.IsClientPlayerTeamLeader() then
		X.Confirm(_L['Edit team info?'], function()
			O.bEnable = true
			D.OpenFrame()
		end)
	end
end)
X.RegisterEvent('FIRST_LOADING_END', 'TEAM_NOTICE', function()
	if not O.bEnable then
		return
	end
	-- 不存在队长不队长的问题了
	if X.IsClientPlayerInParty() then
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'ASK'}, true)
	end
end)
X.RegisterEvent('LOADING_END', 'TEAM_NOTICE', function()
	local frame = D.GetFrame()
	if frame and X.IsInZombieMap() then
		X.UI.CloseFrame(frame)
		X.OutputAnnounceMessage(_L['TeamNotice is disabled in this map.'])
	end
end)

-- 退队时清空团队告示
X.RegisterEvent({'PARTY_DISBAND', 'PARTY_DELETE_MEMBER'}, 'TEAM_NOTICE', function(e)
	if e == 'PARTY_DISBAND' or (e == 'PARTY_DELETE_MEMBER' and arg1 == X.GetClientPlayerID()) then
		local frame = D.GetFrame()
		if frame then
			X.UI.CloseFrame(frame)
		end
		D.szYY = nil
		D.szNote = nil
	end
end)

X.RegisterEvent('ON_BG_CHANNEL_MSG', 'LR_TeamNotice', function()
	if not O.bEnable then
		return
	end
	local szMsgID, nChannel, dwID, szName, aMsg, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == X.GetClientPlayerID()
	if szMsgID ~= 'LR_TeamNotice' or bSelf then
		return
	end
	if not X.IsClientPlayerTeamLeader(dwID) then
		return
	end
	local szCmd, szText = aMsg[1], aMsg[2]
	if szCmd == 'SEND' then
		D.CreateFrame('', szText)
	end
end)

X.RegisterBgMsg('TI', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not O.bEnable then
		return
	end
	if not bIsSelf then
		local me = X.GetClientPlayer()
		local team = GetClientTeam()
		if team then
			if data[1] == 'ASK' and X.IsClientPlayerTeamLeader() then
				if D.GetFrame() then
					X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'reply', szName, D.szYY, D.szNote}, true)
				end
			else
				if not X.IsPlayerTeamLeader(dwID) then
					return
				end
				if data[1] == 'Edit' then
					D.CreateFrame(data[2], data[3])
				elseif data[1] == 'reply' and (tonumber(data[2]) == X.GetClientPlayerID() or data[2] == me.szName) then
					D.CreateFrame(data[3], data[4])
				end
			end
		end
	end
end)

X.RegisterAddonMenu(function()
	return {{
		szOption = _L['Team Message'],
		fnDisable = function()
			return not X.IsClientPlayerInParty()
		end,
		fnAction = D.OpenFrame,
	}}
end)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamNotice',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenFrame',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_TeamNotice = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
