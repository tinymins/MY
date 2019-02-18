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

function CharInfo.GetFrame(dwID)
	return Station.Lookup('Normal/MY_CharInfo' .. dwID)
end

function CharInfo.CreateFrame(dwID, szName)
	local ui = UI.CreateFrame('MY_CharInfo' .. dwID, { w = 240, h = 400, text = g_tStrings.STR_EQUIP_ATTR, close = true })
	local frame = CharInfo.GetFrame(dwID)
	local x, y = 20, 40
	x = x + ui:append('Image', {
		name = 'Image_Kungfu',
		x = x, y = y, w = 30, h = 30,
	}, true):width() + 5
	ui:append('Text', {
		name = 'Text_Name',
		x = x, y = y + 2, w = 240 - 2 * x,
		text = wstring.sub(szName, 1, 6), halign = 1,
	}) -- UI超了
	ui:append('WndButton2', {
		name = 'LOOKUP', x = 70, y = 360,
		text = g_tStrings.STR_LOOKUP,
		onclick = function()
			ViewInviteToPlayer(dwID)
		end,
	})
	ui:append('Text', { name = 'Text_Info', x = 20, y = 72, text = _L['Asking...'], w = 200, h = 70, font = 27, multiline = true })
end

function CharInfo.UpdateFrame(frame, status, data)
	if not frame then
		return
	end
	local ui = UI(frame)
	if status == 'REFUSE' then
		ui:children('#Text_Info'):text(_L['Refuse request']):show()
	elseif status == 'PROGRESS' then
		ui:children('#Text_Info'):text(_L('Syncing: %.2f%%.', data)):show()
	elseif status == 'ACCEPT' and data and type(data) == 'table' then
		local self_data = MY.GetCharInfo()
		local function GetSelfValue(label, value)
			for i = 1, #self_data do
				local v = self_data[i]
				if v.label == label then
					local sc = tonumber((tostring(v.value):gsub('%%', '')))
					local tc = tonumber((tostring(value):gsub('%%', '')))
					if sc and tc then
						return tc > sc and { 200, 255, 200 } or tc < sc and { 255, 200, 200 } or { 255, 255, 255 }
					end
				end
			end
			return { 255, 255, 255 }
		end
		-- 设置基础属性
		ui:children('#Image_Kungfu'):icon((select(2, MY.GetSkillName(data.dwMountKungfuID, 1))))
		ui:children('#Text_Name'):color({ MY.GetForceColor(data.dwForceID) })
		-- 避免大小不够
		ui:size(240, 60 + 65 + #data * 25)
		ui:children('#LOOKUP'):pos(70, 85 + #data * 25)
		for i = 1, #data do
			local v = data[i]
			if v.category then
				ui:append('Text', { x = 20, y = i * 25 + 50, w = 200, h = 25, halign = 1, text = v.label })
			else
				ui:append('Text', { x = 20, y = i * 25 + 50, w = 200, h = 25, halign = 0, text = v.label })
				ui:append('Text', {
					x = 20, y = i * 25 + 50, w = 200, h = 25,
					halign = 2, text = v.value,
					color = GetSelfValue(v.label, v.value),
					onhover = function(bHover)
						if not v.tip or v.szTip then
							return
						end
						if bHover then
							local x, y = this:GetAbsPos()
							local w, h = this:GetSize()
							OutputTip(v.tip or v.szTip, 550, { x, y, w, h })
						else
							HideTip()
						end
					end,
				})
			end
		end
		ui:anchor('CENTER')
		ui:children('#Text_Info'):hide()
	else
		ui:children('#Text_Info'):text('Json Decode Error'):show()
	end
end

MY.RegisterBgMsg('CHAR_INFO', function(szMsgID, nChannel, dwID, szName, bIsSelf, szAction, dwTarID, oData)
	if not bIsSelf and dwTarID == UI_GetClientPlayerID() then
		local frame = CharInfo.GetFrame(dwID)
		if not frame then
			return
		end
		CharInfo.UpdateFrame(frame, szAction, oData)
	end
end, function(szMsgID, nChannel, dwID, szName, bIsSelf, nSegCount, nSegIndex)
	local frame = CharInfo.GetFrame(dwID)
	if not frame then
		return
	end
	CharInfo.UpdateFrame(frame, 'PROGRESS', nSegIndex / nSegCount * 100)
end)

-- public API
function MY_CharInfo.ViewCharInfoToPlayer(dwID)
	local nChannel, szName
	if MY.IsParty(dwID) then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(dwID)
		if info then
			nChannel = PLAYER_TALK_CHANNEL.RAID
			szName = info.szName
		end
	end
	if not nChannel then
		local tar = GetPlayer(dwID)
		if tar then
			nChannel = tar.szName
			szName = tar.szName
		end
	end
	if not nChannel and MY_Farbnamen and MY_Farbnamen.Get then
		local info = MY_Farbnamen.Get(dwID)
		if info then
			nChannel = info.szName
			szName = info.szName
		end
	end
	if not nChannel or not szName then
		MY.Alert(_L['Party limit'])
	else
		CharInfo.CreateFrame(dwID, szName)
		MY.SendBgMsg(nChannel, 'CHAR_INFO', 'ASK', dwID, MY_CharInfo.bDebug and 'DEBUG')
	end
end

do
local function GetInfoPanelMenu()
	local dwType, dwID = MY.GetTarget()
	infopanel = dwType == TARGET.PLAYER and dwID ~= UI_GetClientPlayerID()
	if infopanel then
		return {
			szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR,
			fnAction = function()
				MY_CharInfo.ViewCharInfoToPlayer(dwID)
			end
		}
	end
end
MY.RegisterTargetAddonMenu('MY_CharInfo', GetInfoPanelMenu)
end
