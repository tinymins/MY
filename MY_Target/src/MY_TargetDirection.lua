--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标方位显示
-- @author   : Webster
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
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetDirection'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local INI_PATH = PACKET_INFO.ROOT .. 'MY_Target/ui/MY_TargetDirection.ini'
local IMG_PATH = PACKET_INFO.ROOT .. 'MY_Target/img/MY_TargetDirection.uitex'

local O = {
	bEnable = false,
	tAnchor = {},
	eDistanceType = 'global',
}
local D = {}

RegisterCustomData('MY_TargetDirection.bEnable')
RegisterCustomData('MY_TargetDirection.tAnchor')
RegisterCustomData('MY_TargetDirection.eDistanceType')

function D.GetFrame()
	return Station.Lookup('Normal/MY_TargetDirection')
end

function D.OpenPanel()
	local frame = D.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, 'MY_TargetDirection')
	end
	return frame
end

function D.ClosePanel()
	Wnd.CloseWindow('MY_TargetDirection')
end

function D.UpdateAnchor()
	local frame = D.GetFrame()
	if not frame then
		return
	end
	local a = O.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 250, 100)
	end
	frame:CorrectPos()
end

function D.CheckEnable()
	if O.bEnable then
		D.OpenPanel()
	else
		D.ClosePanel()
	end
end

function D.GetState(tar)
	if tar.nMoveState == MOVE_STATE.ON_SIT then
		return 533, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_DEATH then
		return 2215, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_KNOCKED_DOWN then
		return 2027, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_DASH then
		return 2030, g_tStrings.tPlayerMoveState[tar.nMoveState]
	elseif tar.nMoveState == MOVE_STATE.ON_SKILL_MOVE_DST then
		return 1487, _L["Move"]
	else
		-- check other movestate
		if tar.nMoveState == MOVE_STATE.ON_HALT then
			return 2019, g_tStrings.tPlayerMoveState[tar.nMoveState]
		elseif tar.nMoveState == MOVE_STATE.ON_FREEZE then
			return 2038, g_tStrings.tPlayerMoveState[tar.nMoveState]
		elseif tar.nMoveState == MOVE_STATE.ON_ENTRAP then
			return 2020, _L["Entrap"]
		end
		-- check speed
		if IsPlayer(tar.dwID) and tar.nRunSpeed and tar.nRunSpeed < 20 then
			return 348, _L["Slower"]
		end
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	D.UpdateAnchor()
end

do
local function SetObjectAvatar(img, tar, info, bInfo)
	if IsPlayer(tar.dwID) then
		if bInfo and info.dwMountKungfuID then
			img:FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = tar.GetKungfuMount and tar.GetKungfuMount()
			if kungfu and kungfu.dwSkillID ~= 0 then
				img:FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				img:FromUITex(GetForceImage(tar.dwForceID))
			end
		end
	else
		local szPath = NPC_GetProtrait(tar.dwModelID)
		if not szPath or not IsFileExist(szPath) then
			szPath = NPC_GetHeadImageFile(tar.dwModelID)
		end
		if not szPath or not IsFileExist(szPath) then
			img:FromUITex(GetNpcHeadImage(tar.dwID))
		else
			img:FromTextureFile(szPath)
		end
	end
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	local dwType, dwID = LIB.GetTarget()
	local tar, info, bInfo = LIB.GetObject(dwType, dwID)
	if tar and tar.dwID ~= me.dwID then
		-- 头像
		SetObjectAvatar(this:Lookup('', 'Handle_Main/Image_Force'), tar, info, bInfo)
		-- 方位
		local dwRad1 = atan2(tar.nY - me.nY, tar.nX - me.nX)
		local dwRad2 = me.nFaceDirection / 128 * PI
		this:Lookup('', 'Handle_Main/Image_Arrow'):SetRotate(1.5 * PI + dwRad2 - dwRad1)
		-- 颜色
		local nFrame = 4
		if me.IsInParty() and LIB.IsParty(tar.dwID) then
			nFrame = 3
		elseif LIB.IsEnemy(me.dwID, tar.dwID) then
			nFrame = 1
		elseif IsAlly(me.dwID, tar.dwID) then
			nFrame = 2
		end
		-- 状态
		local dwIcon, szState = D.GetState(tar)
		local boxState = this:Lookup('', 'Handle_Main/Box_State')
		local txtState = this:Lookup('', 'Handle_Main/Text_State')
		if dwIcon then
			boxState:Show()
			boxState:SetObjectIcon(dwIcon)
		else
			boxState:Hide()
		end
		txtState:SetText(szState or '')
		-- 距离
		this:Lookup('', 'Handle_Main/Text_Distance'):SetText(_L('%.1f feet', LIB.GetDistance(me, tar, O.eDistanceType)))
		this:Show()
	else
		this:Hide()
	end
end
end

function D.OnEvent(event)
	if event == 'ON_ENTER_CUSTOM_UI_MODE' or event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['MY_TargetDirection'])
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor()
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this)
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				bEnable = true,
				tAnchor = true,
				eDistanceType = true,
			},
			root = O,
		},
		{
			fields = {
				OnFrameCreate  = D.OnFrameCreate ,
				OnFrameBreathe = D.OnFrameBreathe,
				OnFrameDragEnd = D.OnFrameDragEnd,
				OnEvent        = D.OnEvent       ,
			},
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				tAnchor = true,
				eDistanceType = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
				tAnchor = D.UpdateAnchor,
			},
			root = O,
		},
	},
}
MY_TargetDirection = LIB.GeneGlobalNS(settings)
end
