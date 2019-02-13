--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色属性
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
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TeamTools/lang/')

MY_CharInfo = {
	bEnable = true,
}
MY.RegisterCustomData('MY_CharInfo')

local CharInfo = {}

-- 获取的是一个表 data[1] 一定是装备分
function CharInfo.GetInfo()
	local data = { GetClientPlayer().GetTotalEquipScore() }
	local frame = Station.Lookup('Normal/CharInfo')
	if not frame or not frame:IsVisible() then
		if frame then
			Wnd.CloseWindow('CharInfo') -- 强制kill
		end
		Wnd.OpenWindow('CharInfo'):Hide()
	end
	local hCharInfo = Station.Lookup('Normal/CharInfo')
	local handle = hCharInfo:Lookup('WndScroll_Property', '')
	for i = 0, handle:GetVisibleItemCount() -1 do
		local h = handle:Lookup(i)
		table.insert(data, {
			szTip = h.szTip,
			label = h:Lookup(0):GetText(),
			value = h:Lookup(1):GetText(),
		})
	end
	return data
end

function CharInfo.CreateFrame(dwID, szName, info)
	local ui = UI.CreateFrame('MY_CharInfo' .. dwID, { w = 240, h = 400, text = g_tStrings.STR_EQUIP_ATTR, close = true })
	local frame = Station.Lookup('Normal/MY_CharInfo' .. dwID)
	local x, y = 20, 40
	x = x + ui:append('Image', {
		x = x, y = y, w = 30, h = 30,
		icon = select(2, MY.GetSkillName(info.dwMountKungfuID, 1)),
	}, true):width() + 5
	ui:append('Text', {
		x = x, y = y + 2, w = 240 - 2 * x,
		text = wstring.sub(szName, 1, 6),
		halign = 1,
		color = { MY.GetForceColor(info.dwForceID) },
	}) -- UI超了
	ui:append('WndButton2', {
		name = 'LOOKUP', x = 70, y = 360,
		text = g_tStrings.STR_LOOKUP,
		onclick = function()
			ViewInviteToPlayer(dwID)
		end,
	})
	local info  = ui:append('Text', { name = 'info', x = 20, y = 72, text = _L['Asking...'], w = 200, h = 70, font = 27, multiline = true }, true)
	frame.ui    = ui
	frame.data  = {}
	frame.info  = info
end

function CharInfo.ClearFrame(dwID)
	local frame = Station.Lookup('Normal/MY_CharInfo' .. dwID)
	if frame then
		frame.data = {}
		frame.info:toggle(true)
	end
end

function CharInfo.RefuseFrame(dwID)
	local frame = Station.Lookup('Normal/MY_CharInfo' .. dwID)
	if frame then
		frame.data = {}
		frame.info:toggle(true):text(_L['Refuse request'])
	end
end

function CharInfo.CreateContent(dwID, szContent)
	local frame = Station.Lookup('Normal/MY_CharInfo' .. dwID)
	if frame and frame.data then
		table.insert(frame.data, szContent)
		frame.info:text(_L['Syncing...'])
	end
end

function CharInfo.CreateComplete(dwID)
	local frame = Station.Lookup('Normal/MY_CharInfo' .. dwID)
	if frame then
		local data = MY.JsonDecode(table.concat(frame.data))
		if data and type(data) == 'table' then
			frame.info:toggle(false)
			local ui = frame.ui
			local self_data = CharInfo.GetInfo()
			local function GetSelfValue(label, value)
				for i = 2, #self_data do
					local v = self_data[i]
					if v.label == label then
						local sc = tonumber(clone(v.value:gsub('%%', '')))
						local tc = tonumber(clone(value:gsub('%%', '')))
						if sc and tc then
							return tc > sc and { 200, 255, 200 } or tc < sc and { 255, 200, 200 } or { 255, 255, 255 }
						end
					end
				end
				return { 255, 255, 255 }
			end
			-- 避免大小不够
			ui:size(240, 60 + 65 + (#data - 1) * 25)
			ui:children('#LOOKUP'):pos(70, 60 + #data * 25)
			for i = 2, #data do
				local v = data[i]
				ui:append('Text', { x = 20, y = (i - 1) * 25 + 50, w = 200, h = 25, halign = 0, text = v.label })
				ui:append('Text', {
					x = 20, y = (i - 1) * 25 + 50, w = 200, h = 25,
					halign = 2, text = v.value,
					color = GetSelfValue(v.label, v.value),
					onhover = function(bHover)
						if bHover then
							local x, y = this:GetAbsPos()
							local w, h = this:GetSize()
							OutputTip(v.szTip, 550, { x, y, w, h })
						else
							HideTip()
						end
					end,
				})
			end
			frame.data = nil
		else
			frame.info:text('Json Decode Error')
		end
	end
end

MY.RegisterBgMsg('CHAR_INFO', function(_, nChannel, dwID, szName, bIsSelf, ...)
	local data = {...}
	if not bIsSelf and data[2] == UI_GetClientPlayerID() then
		if data[1] == 'ASK'  then
			if not MY_CharInfo or MY_CharInfo.bEnable or data[3] == 'DEBUG' then
				local szJson = MY.JsonEncode(CharInfo.GetInfo())
				local nMax = 500
				local nTotal = math.ceil(#szJson / nMax)
				MY.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', 'START', dwID)
				for i = 1, nTotal do
					MY.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', 'CONTENT', dwID, string.sub(szJson, (i-1) * nMax + 1, i * nMax))
				end
				MY.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', 'STOP', dwID)
			else
				MY.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', 'REFUSE', dwID)
			end
		elseif data[1] == 'REFUSE' then
			CharInfo.RefuseFrame(dwID)
		elseif data[1] == 'START' then
			CharInfo.ClearFrame(dwID)
		elseif data[1] == 'CONTENT' then
			CharInfo.CreateContent(dwID, data[3])
		elseif data[1] == 'STOP' then
			CharInfo.CreateComplete(dwID)
		end
	end
end)

-- public API
function MY_CharInfo.ViewCharInfoToPlayer(dwID)
	if MY.IsParty(dwID) then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(dwID)
		if info then
			MY.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'CHAR_INFO', 'ASK', dwID, MY_CharInfo.bDebug and 'DEBUG')
			CharInfo.CreateFrame(dwID, info.szName, info)
		end
	else
		MY.Alert(_L['Party limit'])
	end
end

do
local function GetInfoPanelMenu(dwID, dwType)
	infopanel = dwType == TARGET.PLAYER and dwID ~= UI_GetClientPlayerID()
	if infopanel then
		return {{
			szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR,
			fnAction = function()
				MY_CharInfo.ViewCharInfoToPlayer(dwID)
			end
		}}
	else
		return {}
	end
end
Target_AppendAddonMenu({ GetInfoPanelMenu })
end
