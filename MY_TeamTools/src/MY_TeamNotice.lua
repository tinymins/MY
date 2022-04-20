--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队告示
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
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
	return
end
--------------------------------------------------------------------------
local TI = {
	szYY = '',
	szNote = '',
}

local O = X.CreateUserSettingsModule('MY_TeamNotice', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nWidth = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Number,
		xDefaultValue = 320,
	},
	nHeight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Number,
		xDefaultValue = 195,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
	},
})

function TI.SaveList()
	X.SaveLUAData({'config/yy.jx3dat', X.PATH_TYPE.GLOBAL}, TI.tList, { indent = '\t', passphrase = false, crc = false })
end

function TI.GetList()
	if not TI.tList then
		TI.tList = X.LoadLUAData({'config/yy.jx3dat', X.PATH_TYPE.GLOBAL}, { passphrase = false }) or {}
	end
	return TI.tList
end

function TI.GetFrame()
	return Station.Lookup('Normal/MY_TeamNotice')
end

function TI.CreateFrame(szInitYY, szInitNote)
	if X.IsInZombieMap() then
		return
	end
	if szInitNote then
		szInitNote = X.ReplaceSensitiveWord(szInitNote)
	end
	local ui = TI.GetFrame()
	if ui then
		ui = UI(ui)
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
			local W, H = select(3, ui:Size())
			ui:Fetch('YY'):Width(ui:Width() - 160)
			local uiBtn = ui:Fetch('Btn_YY')
			uiBtn:Left(W - uiBtn:Width() - 10)
			local uiBtns = ui:Fetch('WndBtn_RaidTools'):Add(ui:Fetch('WndBtn_GKP')):Add(ui:Fetch('WndBtn_TeamMon'))
			uiBtns:Top(H - uiBtns:Height() - 10)
			local uiMessage = ui:Fetch('Message')
			uiMessage:Size(W - 20, uiBtns:Top() - uiMessage:Top() - 10)
		end
		ui = UI.CreateFrame('MY_TeamNotice', {
			w = O.nWidth, h = O.nHeight,
			text = _L['Team Message'],
			anchor = O.anchor,
			simple = true, close = true, dragresize = true,
			minwidth = 320, minheight = 195,
			setting = function()
				X.ShowPanel()
				X.FocusPanel()
				X.SwitchTab('MY_TeamTools')
			end,
			ondragresize = FormatAllContentPos,
		})
		local x, y = 10, 5
		x = x + ui:Append('Text', { x = x, y = y - 3, text = ENVIRONMENT.GAME_LANG == 'zhcn' and _L['YY:'] or _L['DC:'], font = 48 }):AutoWidth():Width() + 5
		x = x + ui:Append('WndAutocomplete', {
			name = 'YY',
			w = 160, h = 26, x = x, y = y,
			text = szInitYY, font = 48, color = { 128, 255, 0 },
			editType = UI.EDIT_TYPE.NUMBER,
			onClick = function()
				if IsPopupMenuOpened() then
					UI(this):Autocomplete('close')
				elseif X.IsLeader() then
					UI(this):Autocomplete('search', '')
				end
			end,
			onBlur = function()
				local szText = UI(this):Text()
				if TI.szYY == szText then
					return
				end
				if X.IsLeader() then
					if not X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						TI.szYY = szText
						X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'Edit', szText, ui:Children('#Message'):Text()})
						return
					end
					X.Systopmsg(_L['Please unlock talk lock first.'])
				end
				ui:Fetch('YY'):Text(TI.szYY, WNDEVENT_FIRETYPE.PREVENT)
			end,
			autocomplete = {
				{
					'option', 'beforeSearch', function(text)
						local source = {}
						if X.IsLeader() then
							TI.tList = TI.GetList()
							for k, v in pairs(TI.tList) do
								table.insert(source, k)
							end
							if #source == 1 and tostring(source[1]) == text then
								source = {}
							end
						end
						UI(this):Autocomplete('option', 'source', source)
					end,
				},
				{
					'option', 'beforeDelete', function(szOption)
						TI.tList[tonumber(szOption)] = nil
						TI.SaveList()
					end,
				},
			},
		}):Width() + 5
		y = y + ui:Append('WndButton', {
			name = 'Btn_YY',
			x = x, y = y, text = X.IsLeader()
				and (ENVIRONMENT.GAME_LANG == 'zhcn' and _L['Paste YY'] or _L['Paste DC'])
				or (ENVIRONMENT.GAME_LANG == 'zhcn' and _L['Copy YY'] or _L['Copy DC']),
			buttonStyle = 'FLAT',
			onClick = function()
				local yy = ui:Children('#YY'):Text()
				if X.IsLeader() then
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
					end
					if tonumber(yy) then
						TI.tList = TI.GetList()
						if not TI.tList[tonumber(yy)] then
							TI.tList[tonumber(yy)] = true
							TI.SaveList()
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
					X.Topmsg(_L['Channel number has been copied to clipboard'])
				end
			end,
		}):Height() + 5
		ui:Append('WndEditBox', {
			name = 'Message',
			w = 300, h = 80, x = 10, y = y,
			multiline = true, limit = 512,
			text = szInitNote,
			onBlur = function()
				local szText = X.ReplaceSensitiveWord(UI(this):Text())
				if TI.szNote == szText then
					return
				end
				if X.IsLeader() then
					if not X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						TI.szNote = szText
						X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'Edit', ui:Children('#YY'):Text(), szText})
						return
					end
					X.Systopmsg(_L['Please unlock talk lock first.'])
				end
				ui:Fetch('Message'):Text(TI.szNote, WNDEVENT_FIRETYPE.PREVENT)
			end,
		})
		x, y = 11, 130
		local bTeamMon = MY_TeamMon_RR and ENVIRONMENT.GAME_BRANCH ~= 'classic'
		local nBtnW = bTeamMon and 96 or 144
		x = x + ui:Append('WndButton', {
			name = 'WndBtn_RaidTools',
			x = x, y = y, w = nBtnW,
			text = _L['MY_TeamTools'],
			buttonStyle = 'FLAT',
			onClick = MY_TeamTools.Toggle,
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndButton', {
			name = 'WndBtn_GKP',
			x = x, y = y, w = nBtnW,
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
		if bTeamMon then
			x = x + ui:Append('WndButton', {
				name = 'WndBtn_TeamMon',
				x = x, y = y, w = nBtnW,
				text = _L['Import Data'],
				buttonStyle = 'FLAT',
				onClick = MY_TeamMon_RR.OpenPanel,
			}):AutoWidth():Width() + 5
		end
		FormatAllContentPos()
		-- 注册事件
		local frame = TI.GetFrame()
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
				if arg1 == UI_GetClientPlayerID() then
					ui:Remove()
				end
			elseif szEvent == 'PARTY_ADD_MEMBER' then
				if X.IsLeader() then
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						return
					end
					X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'reply', arg1, TI.szYY, TI.szNote})
				end
			elseif szEvent == 'UI_SCALED' then
				ui:Anchor(O.anchor)
			elseif szEvent == 'TEAM_AUTHORITY_CHANGED' then
				ui:Fetch('Btn_YY'):Text(X.IsLeader() and _L['Paste YY'] or _L['Copy YY'])
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
	TI.szYY   = szInitYY or TI.szYY
	TI.szNote = szInitNote or TI.szNote
end

function TI.OpenFrame()
	if X.IsInZombieMap() then
		return X.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
	O.bEnable = true
	if X.IsInParty() then
		if X.IsLeader() then
			TI.CreateFrame()
		else
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'ASK'})
			X.Sysmsg(_L['Asking..., If no response in longtime, team leader not enable plug-in.'])
		end
	end
end

X.RegisterEvent('PARTY_LEVEL_UP_RAID', 'TEAM_NOTICE', function()
	if X.IsInZombieMap() then
		return
	end
	if X.IsLeader() then
		X.Confirm(_L['Edit team info?'], function()
			O.bEnable = true
			TI.CreateFrame()
		end)
	end
end)
X.RegisterEvent('FIRST_LOADING_END', 'TEAM_NOTICE', function()
	if not O.bEnable then
		return
	end
	-- 不存在队长不队长的问题了
	if X.IsInParty() then
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'ASK'}, true)
	end
end)
X.RegisterEvent('LOADING_END', 'TEAM_NOTICE', function()
	local frame = TI.GetFrame()
	if frame and X.IsInZombieMap() then
		Wnd.CloseWindow(frame)
		X.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
end)

-- 退队时清空团队告示
X.RegisterEvent({'PARTY_DISBAND', 'PARTY_DELETE_MEMBER'}, 'TEAM_NOTICE', function(e)
	if e == 'PARTY_DISBAND' or (e == 'PARTY_DELETE_MEMBER' and arg1 == UI_GetClientPlayerID()) then
		local frame = TI.GetFrame()
		if frame then
			Wnd.CloseWindow(frame)
		end
		TI.szYY = nil
		TI.szNote = nil
	end
end)

X.RegisterEvent('ON_BG_CHANNEL_MSG', 'LR_TeamNotice', function()
	if not O.bEnable then
		return
	end
	local szMsgID, nChannel, dwID, szName, aMsg, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == UI_GetClientPlayerID()
	if szMsgID ~= 'LR_TeamNotice' or bSelf then
		return
	end
	if not X.IsLeader(dwID) then
		return
	end
	local szCmd, szText = aMsg[1], aMsg[2]
	if szCmd == 'SEND' then
		TI.CreateFrame('', szText)
	end
end)

X.RegisterBgMsg('TI', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not O.bEnable then
		return
	end
	if not bIsSelf then
		local me = GetClientPlayer()
		local team = GetClientTeam()
		if team then
			if data[1] == 'ASK' and X.IsLeader() then
				if TI.GetFrame() then
					X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'reply', szName, TI.szYY, TI.szNote}, true)
				end
			else
				if not X.IsLeader(dwID) then
					return
				end
				if data[1] == 'Edit' then
					TI.CreateFrame(data[2], data[3])
				elseif data[1] == 'reply' and (tonumber(data[2]) == UI_GetClientPlayerID() or data[2] == me.szName) then
					TI.CreateFrame(data[3], data[4])
				end
			end
		end
	end
end)

X.RegisterAddonMenu(function()
	return {{
		szOption = _L['Team Message'],
		fnDisable = function()
			return not X.IsInParty()
		end,
		fnAction = TI.OpenFrame,
	}}
end)

-- Global exports
do
local settings = {
	name = 'MY_TeamNotice',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenFrame',
			},
			root = TI,
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
