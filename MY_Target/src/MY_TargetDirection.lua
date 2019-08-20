--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标方位显示
-- @author   : Webster
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetDirection'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetDirection'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2011800) then
	return
end

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
		if IsPlayer(tar.dwID) and tar.nRunSpeed < 20 then
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
local function SetObjectAvatar(img, tar, info)
	if IsPlayer(tar.dwID) then
		if bInfo and info.dwMountKungfuID then
			img:FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = tar.GetKungfuMount()
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

local function GetObjectArrow(img, tar)
	return nFrame
end

function D.OnFrameBreathe()
	local me = GetClientPlayer()
	local dwType, dwID = LIB.GetTarget()
	local tar, info, bInfo = LIB.GetObject(dwType, dwID)
	if tar and tar.dwID ~= me.dwID then
		-- 头像
		SetObjectAvatar(this:Lookup('', 'Handle_Main/Image_Force'), tar, info)
		-- 方位
		local dwRad1 = math.atan2(tar.nY - me.nY, tar.nX - me.nX)
		local dwRad2 = me.nFaceDirection / 128 * math.pi
		this:Lookup('', 'Handle_Main/Image_Arrow'):SetRotate(1.5 * math.pi + dwRad2 - dwRad1)
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
