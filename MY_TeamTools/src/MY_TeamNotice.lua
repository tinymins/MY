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
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2016100) then
	return
end
--------------------------------------------------------------------------
local TI = {
	szYY = '',
	szNote = '',
}

MY_TeamNotice = {
	bEnable = true,
	nWidth = 320,
	nHeight = 195,
	anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
}
LIB.RegisterCustomData('MY_TeamNotice')

function TI.SaveList()
	LIB.SaveLUAData({'config/yy.jx3dat', PATH_TYPE.GLOBAL}, TI.tList, { indent = '\t', passphrase = false, crc = false })
end

function TI.GetList()
	if not TI.tList then
		TI.tList = LIB.LoadLUAData({'config/yy.jx3dat', PATH_TYPE.GLOBAL}, { passphrase = false }) or {}
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
		ui:Children('#YY'):Text(a, WNDEVENT_FIRETYPE.PREVENT)
		ui:Children('#Message'):Text(b, WNDEVENT_FIRETYPE.PREVENT)
	else
		local function FormatAllContentPos()
			if not ui then
				return
			end
			MY_TeamNotice.nWidth  = ui:Width()
			MY_TeamNotice.nHeight = ui:Height()
			MY_TeamNotice.anchor  = ui:Anchor()
			local W, H = ui:Size(true)
			ui:Fetch('YY'):Width(ui:Width() - 160)
			local uiBtn = ui:Fetch('Btn_YY')
			uiBtn:Left(W - uiBtn:Width() - 10)
			local uiBtns = ui:Fetch('WndBtn_RaidTools'):Add(ui:Fetch('WndBtn_GKP')):Add(ui:Fetch('WndBtn_TeamMon'))
			uiBtns:Top(H - uiBtns:Height() - 10)
			local uiMessage = ui:Fetch('Message')
			uiMessage:Size(W - 20, uiBtns:Top() - uiMessage:Top() - 10)
		end
		ui = UI.CreateFrame('MY_TeamNotice', {
			w = MY_TeamNotice.nWidth, h = MY_TeamNotice.nHeight,
			text = _L['Team Message'],
			anchor = MY_TeamNotice.anchor,
			simple = true, close = true, dragresize = true,
			minwidth = 320, minheight = 195,
			setting = function()
				LIB.ShowPanel()
				LIB.FocusPanel()
				LIB.SwitchTab('MY_TeamTools')
			end,
			ondragresize = FormatAllContentPos,
		})
		local x, y = 10, 5
		x = x + ui:Append('Text', { x = x, y = y - 3, text = LIB.GetLang() == 'zhcn' and _L['YY:'] or _L['DC:'], font = 48 }):AutoWidth():Width() + 5
		x = x + ui:Append('WndAutocomplete', {
			name = 'YY',
			w = 160, h = 26, x = x, y = y,
			text = a, font = 48, color = { 128, 255, 0 },
			edittype = UI.EDIT_TYPE.NUMBER,
			onclick = function()
				if IsPopupMenuOpened() then
					UI(this):Autocomplete('close')
				elseif LIB.IsLeader() then
					UI(this):Autocomplete('search', '')
				end
			end,
			onchange = function(szText)
				if TI.szYY == szText then
					return
				end
				if LIB.IsLeader() then
					if not LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						TI.szYY = szText
						LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'Edit', szText, ui:Children('#Message'):Text()})
						return
					end
					LIB.Systopmsg(_L['Please unlock talk lock first.'])
				end
				ui:Fetch('YY'):Text(TI.szYY, WNDEVENT_FIRETYPE.PREVENT)
			end,
			autocomplete = {
				{
					'option', 'beforeSearch', function(text)
						local source = {}
						if LIB.IsLeader() then
							TI.tList = TI.GetList()
							for k, v in pairs(TI.tList) do
								insert(source, k)
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
			x = x, y = y, text = LIB.IsLeader()
				and (LIB.GetLang() == 'zhcn' and _L['Paste YY'] or _L['Paste DC'])
				or (LIB.GetLang() == 'zhcn' and _L['Copy YY'] or _L['Copy DC']),
			buttonstyle = 2,
			onclick = function()
				local yy = ui:Children('#YY'):Text()
				if LIB.IsLeader() then
					if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						return LIB.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
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
							LIB.Talk(PLAYER_TALK_CHANNEL.RAID, yy)
						end
					end
					local message = ui:Children('#Message'):Text():gsub('\n', ' ')
					if message ~= '' then
						LIB.Talk(PLAYER_TALK_CHANNEL.RAID, message)
					end
				else
					SetDataToClip(yy)
					LIB.Topmsg(_L['Channel number has been copied to clipboard'])
				end
			end,
		}):Height() + 5
		ui:Append('WndEditBox', {
			name = 'Message',
			w = 300, h = 80, x = 10, y = y,
			multiline = true, limit = 512,
			text = b,
			onchange = function(szText)
				if TI.szNote == szText then
					return
				end
				if LIB.IsLeader() then
					if not LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						TI.szNote = szText
						LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'Edit', ui:Children('#YY'):Text(), szText})
						return
					end
					LIB.Systopmsg(_L['Please unlock talk lock first.'])
				end
				ui:Fetch('Message'):Text(TI.szNote, WNDEVENT_FIRETYPE.PREVENT)
			end,
		})
		x, y = 11, 130
		x = x + ui:Append('WndButton', {
			name = 'WndBtn_RaidTools',
			x = x, y = y, w = 96,
			text = _L['MY_TeamTools'],
			buttonstyle = 2,
			onclick = MY_TeamTools.Toggle,
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndButton', {
			name = 'WndBtn_GKP',
			x = x, y = y, w = 96,
			text = _L['GKP Golden Team Record'],
			buttonstyle = 2,
			onclick = function()
				if MY_GKP then
					MY_GKP_MI.TogglePanel()
				else
					LIB.Alert(_L['You haven\'t had MY_GKP installed and loaded yet.'])
				end
			end,
		}):AutoWidth():Width() + 5
		if MY_TeamMon_RR then
			x = x + ui:Append('WndButton', {
				name = 'WndBtn_TeamMon',
				x = x, y = y, w = 96,
				text = _L['Import Data'],
				buttonstyle = 2,
				onclick = MY_TeamMon_RR.OpenPanel,
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
				if LIB.IsLeader() then
					if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						return
					end
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'reply', arg1, TI.szYY, TI.szNote})
				end
			elseif szEvent == 'UI_SCALED' then
				ui:Anchor(MY_TeamNotice.anchor)
			elseif szEvent == 'TEAM_AUTHORITY_CHANGED' then
				ui:Fetch('Btn_YY'):Text(LIB.IsLeader() and _L['Paste YY'] or _L['Copy YY'])
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
	MY_TeamNotice.bEnable = true
	if LIB.IsInParty() then
		if LIB.IsLeader() then
			TI.CreateFrame()
		else
			if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return LIB.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'ASK'})
			LIB.Sysmsg(_L['Asking..., If no response in longtime, team leader not enable plug-in.'])
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
	if LIB.IsInParty() then
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'ASK'}, true)
	end
end)
LIB.RegisterEvent('LOADING_END.TEAM_NOTICE', function()
	local frame = TI.GetFrame()
	if frame and LIB.IsInZombieMap() then
		Wnd.CloseWindow(frame)
		LIB.Topmsg(_L['TeamNotice is disabled in this map.'])
	end
end)

-- 退队时清空团队告示
LIB.RegisterEvent({'PARTY_DISBAND.TEAM_NOTICE', 'PARTY_DELETE_MEMBER.TEAM_NOTICE'}, function(e)
	if e == 'PARTY_DISBAND' or (e == 'PARTY_DELETE_MEMBER' and arg1 == UI_GetClientPlayerID()) then
		local frame = TI.GetFrame()
		if frame then
			Wnd.CloseWindow(frame)
		end
		TI.szYY = nil
		TI.szNote = nil
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
	if not LIB.IsLeader(dwID) then
		return
	end
	local szCmd, szText = aMsg[1], aMsg[2]
	if szCmd == 'SEND' then
		TI.CreateFrame('', szText)
	end
end)

LIB.RegisterBgMsg('TI', function(_, data, nChannel, dwID, szName, bIsSelf)
	if not MY_TeamNotice.bEnable then
		return
	end
	if not bIsSelf then
		local me = GetClientPlayer()
		local team = GetClientTeam()
		if team then
			if data[1] == 'ASK' and LIB.IsLeader() then
				if TI.GetFrame() then
					LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'TI', {'reply', szName, TI.szYY, TI.szNote}, true)
				end
			else
				if not LIB.IsLeader(dwID) then
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

do
local function GetMenu()
	return {{
		szOption = _L['Team Message'],
		fnDisable = function()
			return not LIB.IsInParty()
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
