--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色属性
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_TeamTools/lang/')

MY_CharInfo = {
	bEnable = true,
}
LIB.RegisterCustomData('MY_CharInfo')

local CharInfo = {}

function CharInfo.GetFrame(dwID)
	return Station.Lookup('Normal/MY_CharInfo' .. dwID)
end

function CharInfo.CreateFrame(dwID, szName)
	local ui = UI.CreateFrame('MY_CharInfo' .. dwID, { w = 240, h = 400, text = '', close = true })
	local frame = CharInfo.GetFrame(dwID)
	local x, y = 20, 10
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
	frame.pending = true
end

function CharInfo.UpdateFrame(frame, status, data)
	if not frame or not frame.pending then
		return
	end
	local ui = UI(frame)
	if status == 'REFUSE' then
		ui:children('#Text_Info'):text(_L['Refuse request']):show()
		frame.pending = false
	elseif status == 'PROGRESS' then
		ui:children('#Text_Info'):text(_L('Syncing: %.2f%%.', data)):show()
	elseif status == 'ACCEPT' and data and type(data) == 'table' then
		local self_data = LIB.GetCharInfo()
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
		ui:children('#Image_Kungfu'):icon((select(2, LIB.GetSkillName(data.dwMountKungfuID, 1))))
		ui:children('#Text_Name'):color({ LIB.GetForceColor(data.dwForceID) })
		-- 绘制属性条
		local y0 = 20
		for i = 1, #data do
			local v = data[i]
			if v.category then
				ui:append('Text', { x = 20, y = y0 + i * 25, w = 200, h = 25, halign = 1, text = v.label })
			else
				ui:append('Text', { x = 20, y = y0 + i * 25, w = 200, h = 25, halign = 0, text = v.label })
				ui:append('Text', {
					x = 20, y = y0 + i * 25, w = 200, h = 25,
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
		-- 避免大小不够
		ui:size(240, y0 + 75 + #data * 25)
		ui:children('#LOOKUP'):pos(70, y0 + 35 + #data * 25)
		ui:anchor('CENTER')
		ui:children('#Text_Info'):hide()
		frame.pending = false
	end
end

LIB.RegisterBgMsg('CHAR_INFO', function(szMsgID, nChannel, dwID, szName, bIsSelf, szAction, dwTarID, oData)
	if not bIsSelf and dwTarID == UI_GetClientPlayerID() then
		local frame = CharInfo.GetFrame(dwID)
		if not frame then
			return
		end
		CharInfo.UpdateFrame(frame, szAction, oData)
	end
end, function(szMsgID, nChannel, dwID, szName, bIsSelf, nSegCount, nSegIndex)
	if bIsSelf then
		return
	end
	local frame = CharInfo.GetFrame(dwID)
	if not frame then
		return
	end
	CharInfo.UpdateFrame(frame, 'PROGRESS', nSegIndex / nSegCount * 100)
end)

-- public API
function MY_CharInfo.ViewCharInfoToPlayer(dwID)
	local nChannel, szName
	if LIB.IsParty(dwID) then
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
		LIB.Alert(_L['Party limit'])
	else
		CharInfo.CreateFrame(dwID, szName)
		LIB.SendBgMsg(nChannel, 'CHAR_INFO', 'ASK', dwID, MY_CharInfo.bDebug and 'DEBUG')
	end
end

do
local function GetInfoPanelMenu()
	local dwType, dwID = LIB.GetTarget()
	if dwType == TARGET.PLAYER and dwID ~= UI_GetClientPlayerID() then
		return {
			szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR,
			fnAction = function()
				MY_CharInfo.ViewCharInfoToPlayer(dwID)
			end
		}
	end
end
LIB.RegisterTargetAddonMenu('MY_CharInfo', GetInfoPanelMenu)
end
