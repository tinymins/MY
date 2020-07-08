--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 角色属性
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
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
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
	x = x + ui:Append('Image', {
		name = 'Image_Kungfu',
		x = x, y = y, w = 30, h = 30,
	}):Width() + 5
	ui:Append('Text', {
		name = 'Text_Name',
		x = x, y = y + 2, w = 240 - 2 * x,
		text = wsub(szName, 1, 6), halign = 1,
	}) -- UI超了
	ui:Append('WndButton', {
		name = 'LOOKUP', x = 70, y = 360,
		text = g_tStrings.STR_LOOKUP,
		buttonstyle = 2,
		onclick = function()
			ViewInviteToPlayer(dwID)
		end,
	})
	ui:Append('Text', { name = 'Text_Info', x = 20, y = 72, text = _L['Asking...'], w = 200, h = 70, font = 27, multiline = true })
	frame.pending = true
end

function CharInfo.UpdateFrame(frame, status, data)
	if not frame or not frame.pending then
		return
	end
	local ui = UI(frame)
	if status == 'REFUSE' then
		ui:Children('#Text_Info'):Text(_L['Refuse request']):Show()
		frame.pending = false
	elseif status == 'PROGRESS' then
		ui:Children('#Text_Info'):Text(_L('Syncing: %.2f%%.', data)):Show()
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
		ui:Children('#Image_Kungfu'):Icon((select(2, LIB.GetSkillName(data.dwMountKungfuID, 1))))
		ui:Children('#Text_Name'):Color({ LIB.GetForceColor(data.dwForceID) })
		-- 绘制属性条
		local y0 = 20
		for i = 1, #data do
			local v = data[i]
			if v.category then
				ui:Append('Text', { x = 20, y = y0 + i * 25, w = 200, h = 25, halign = 1, text = v.label })
			else
				ui:Append('Text', { x = 20, y = y0 + i * 25, w = 200, h = 25, halign = 0, text = v.label })
				ui:Append('Text', {
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
		ui:Size(240, y0 + 75 + #data * 25)
		ui:Children('#LOOKUP'):Pos(70, y0 + 35 + #data * 25)
		ui:Anchor('CENTER')
		ui:Children('#Text_Info'):Hide()
		frame.pending = false
	end
end

LIB.RegisterBgMsg('CHAR_INFO', function(szMsgID, aData, nChannel, dwID, szName, bIsSelf)
	local szAction, dwTarID, oData = aData[1], aData[2], aData[3]
	if not bIsSelf and dwTarID == UI_GetClientPlayerID() then
		local frame = CharInfo.GetFrame(dwID)
		if not frame then
			return
		end
		CharInfo.UpdateFrame(frame, szAction, oData)
	end
end, function(szMsgID, nSegCount, nSegRecv, nSegIndex, nChannel, dwID, szName, bIsSelf)
	if bIsSelf then
		return
	end
	local frame = CharInfo.GetFrame(dwID)
	if not frame then
		return
	end
	CharInfo.UpdateFrame(frame, 'PROGRESS', nSegRecv / nSegCount * 100)
end)

-- public API
function MY_CharInfo.ViewCharInfoToPlayer(dwID)
	if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return LIB.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
	end
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
		LIB.SendBgMsg(nChannel, 'CHAR_INFO', {'ASK', dwID, LIB.IsShieldedVersion('MY_CharInfoDaddy', 2) and 'DEBUG'})
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
