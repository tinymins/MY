--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标方位显示
-- @author   : Webster
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
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
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Target/lang/')
if not MY.AssertVersion('MY_TargetDirection', _L['MY_TargetDirection'], 0x2011800) then
	return
end

local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_Target/ui/MY_TargetDirection.ini'
local IMG_PATH = MY.GetAddonInfo().szRoot .. 'MY_Target/img/MY_TargetDirection.uitex'

local C = {
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
	local a = C.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 250, 100)
	end
	frame:CorrectPos()
end

function D.CheckEnable()
	if C.bEnable then
		D.OpenPanel()
	else
		D.ClosePanel()
	end
end

function D.OnFrameCreate()
	-- this:Lookup('', 'Handle_Main/Image_Arrow'):FromUITex(IMG_PATH, 0)
	-- this:Lookup('', 'Handle_Main/Image_Player'):FromUITex(IMG_PATH, 1)
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
	local dwType, dwID = MY.GetTarget()
	local tar, info, bInfo = MY.GetObject(dwType, dwID)
	if tar and tar.dwID ~= me.dwID then
		-- 头像
		SetObjectAvatar(this:Lookup('', 'Handle_Main/Image_Force'), tar, info)
		-- 方位
		local dwRad1 = math.atan2(tar.nY - me.nY, tar.nX - me.nX)
		local dwRad2 = me.nFaceDirection / 128 * math.pi
		this:Lookup('', 'Handle_Main/Image_Arrow'):SetRotate(1.5 * math.pi + dwRad2 - dwRad1)
		-- 颜色
		local nFrame = 4
		if me.IsInParty() and MY.IsParty(tar.dwID) then
			nFrame = 3
		elseif IsEnemy(me.dwID, tar.dwID) then
			nFrame = 1
		elseif IsAlly(me.dwID, tar.dwID) then
			nFrame = 2
		end
		this:Lookup('', 'Handle_Main/Image_Arrow'):SetFrame(nFrame)
		-- 距离
		this:Lookup('', 'Handle_Main/Text_Distance'):SetText(_L('%.1f feet', MY.GetDistance(me, tar, C.eDistanceType)))
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
	C.tAnchor = GetFrameAnchor(this)
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
			root = C,
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
			root = C,
		},
	},
}
MY_TargetDirection = MY.GeneGlobalNS(settings)
end
