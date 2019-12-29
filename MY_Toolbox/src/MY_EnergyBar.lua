--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : BUFF�б�
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_EnergyBar'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local ANCHOR = {x = 65, y = 250, s = 'CENTER', r = 'CENTER'}
local O = {
	bEnable = false,
	tAnchor = {},
}
RegisterCustomData('MY_EnergyBar.bEnable')
RegisterCustomData('MY_EnergyBar.tAnchor')

---------------------------------------------------------------------
-- ���غ����ͱ���
---------------------------------------------------------------------
local D = {
	nBombCount = 0,
	aAccumulateShow =
	{
		{},
		{'10'},
		{'11'},
		{'11', '20'},
		{'11', '21'},
		{'11', '21', '30'},
		{'11', '21', '31'},
		{'11', '21', '31', '40'},
		{'11', '21', '31', '41'},
		{'11', '21', '31', '41', '50'},
		{'11', '21', '31', '41', '51'},
	},
	aAccumulateHide =
	{
		{'10', '11', '20', '21', '30', '31', '40', '41', '50', '51'},
		{'11', '20', '21', '30', '31', '40', '41', '50', '51'},
		{'10', '20', '21', '30', '31', '40', '41', '50', '51'},
		{'10', '21', '30', '31', '40', '41', '50', '51'},
		{'10', '20', '30', '31', '40', '41', '50', '51'},
		{'10', '20', '31', '40', '41', '50', '51'},
		{'10', '20', '30', '40', '41', '50', '51'},
		{'10', '20', '30', '41', '50', '51'},
		{'10', '20', '30', '40', '50', '51'},
		{'10', '20', '30', '40', '51'},
		{'10', '20', '30', '40', '50'},
	},
}

function D.UpdateAnchor(frame)
	local an = O.tAnchor
	if IsEmpty(an) then
		an = ANCHOR
	end
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	frame:CorrectPos()
end

function D.UpdateAccumulateValue(frame)
	if not D.szShow or D.szShow == '' then
		return
	end
	local handle = frame:Lookup('', D.szShow)
	if handle then
		local nValue = GetClientPlayer().nAccumulateValue
		if nValue < 0 then
			nValue = 0
		end
		if D.szShowSub == 'SL' then
			if nValue > 3 then
				nValue = 3
			end
			local szSub = D.szShowSub .. '_'
			for i = 1, nValue, 1 do
				handle:Lookup(szSub .. i):Show()
			end
			for i = nValue + 1, 3, 1 do
				handle:Lookup(szSub .. i):Hide()
			end
		elseif D.szShowSub == 'QX' then
			local hText = handle:Lookup('Text_Layer')
			local hImage = handle:Lookup('Image_QX_Btn')
			if nValue > 10 then
				nValue = 10
			end
			if nValue > 0 then
				hText:SetText(nValue)
				hText:Show()
				hImage.bChecked = true
			else
				hText:Hide()
				hImage.bChecked = false
			end
			if hImage.bClickDown then
				hImage:SetFrame(89)
			elseif hImage.bInside then
				hImage:SetFrame(86)
			elseif hImage.bChecked then
				hImage:SetFrame(88)
			else
				hImage:SetFrame(85)
			end
			local szSub =D.szShowSub .. '_'
			for i = 1, nValue, 1 do
				handle:Lookup(szSub .. i):Show()
			end
			for i = nValue + 1, 10, 1 do
				handle:Lookup(szSub .. i):Hide()
			end
		else
			if nValue > 10 then
				nValue = 10
			end
			nValue = nValue + 1
			local szSub =D.szShowSub .. '_'
			local aShow = D.aAccumulateShow[nValue]
			local aHide = D.aAccumulateHide[nValue]
			for k, v in pairs(aShow) do
				handle:Lookup(szSub .. v):Show()
			end
			for k, v in pairs(aHide) do
				handle:Lookup(szSub .. v):Hide()
			end
		end
	end
end

function D.UpdateCangJian(frame)
	local me, hCangjian = GetClientPlayer(), frame:Lookup('', D.szShow)
	if not me or not hCangjian or not me.bCanUseBigSword then
		return
	end
	local hImageShort = hCangjian:Lookup('Image_Short')
	local hTextShort = hCangjian:Lookup('Text_Short')
	local hAniShort = hCangjian:Lookup('Animate_Short')
	local hImageLong = hCangjian:Lookup('Image_Long')
	local hTextLong = hCangjian:Lookup('Text_Long')
	local hAniLong = hCangjian:Lookup('Animate_Long')
	local szShow = nil
	if me.nMaxRage > 100 then
		hImageShort:Hide()
		hTextShort:Hide()
		hAniShort:Hide()
		hImageLong:Show()
		hTextLong:Show()
		hAniLong:Show()
		szShow = 'Long'
	else
		hImageShort:Show()
		hTextShort:Show()
		hAniShort:Show()
		hImageLong:Hide()
		hTextLong:Hide()
		hAniLong:Hide()
		szShow = 'Short'
	end
	if me.nMaxRage > 0 then
		hCangjian:Lookup('Image_' .. szShow):SetPercentage(me.nCurrentRage / me.nMaxRage)
		hCangjian:Lookup('Text_' .. szShow):SetText(me.nCurrentRage .. '/' .. me.nMaxRage)
	else
		hCangjian:Lookup('Image_' .. szShow):SetPercentage(0)
		hCangjian:Lookup('Text_' .. szShow):SetText('')
	end
end

function D.UpdateMingJiao(frame)
	local hMingJiao = frame:Lookup('', D.szShow)
	if not hMingJiao then
		return
	end
	local me = GetClientPlayer()
	local imgS = hMingJiao:Lookup('Image_SunEnergy')
	local imgM = hMingJiao:Lookup('Image_MoonEnergy')
	imgS:SetPercentage(me.nCurrentSunEnergy / me.nMaxSunEnergy)
	imgM:SetPercentage(me.nCurrentMoonEnergy / me.nMaxMoonEnergy)
	imgS:Show(me.nSunPowerValue <= 0 and me.nMoonPowerValue <= 0)
	imgM:Show(me.nSunPowerValue <= 0 and me.nMoonPowerValue <= 0)
	hMingJiao:Lookup('Image_MingJiaoBG2'):Show(me.nMoonPowerValue <= 0 and me.nSunPowerValue <= 0 and me.nCurrentSunEnergy <= 0 and me.nCurrentMoonEnergy <= 0)
	hMingJiao:Lookup('Image_SunCao'):Show(me.nCurrentSunEnergy > 0 or me.nCurrentMoonEnergy > 0)
	hMingJiao:Lookup('Image_MoonCao'):Show(me.nCurrentSunEnergy > 0 or me.nCurrentMoonEnergy > 0)
	hMingJiao:Lookup('Image_SunBG'):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup('Image_MoonBG'):Show(me.nMoonPowerValue > 0)
	hMingJiao:Lookup('Image_SunValue'):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup('Image_MoonValue'):Show(me.nMoonPowerValue > 0)
	hMingJiao:Lookup('Animate_SunValue'):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup('Animate_MoonValue'):Show(me.nMoonPowerValue > 0)
	frame:Lookup('', 'Text_Sun'):SetText(FormatString(g_tStrings.MINGJIAO_POWER_SUN, string.format('%d/%d', me.nCurrentSunEnergy / 100, me.nMaxSunEnergy / 100)))
	frame:Lookup('', 'Text_Moon'):SetText(FormatString(g_tStrings.MINGJIAO_POWER_MOON, string.format('%d/%d', me.nCurrentMoonEnergy / 100, me.nMaxMoonEnergy / 100)))
end

-- cangyun pose type
function D.UpdateCangYun(frame)
	local me, hCangyun = GetClientPlayer(), frame:Lookup('', D.szShow)
	if not me or not hCangyun then
		return
	end
	local hImageRang = hCangyun:Lookup('Image_Rang')
	local hTextRang = hCangyun:Lookup('Text_Rang')
	if me.nMaxRage > 0 then
		hImageRang:SetPercentage(me.nCurrentRage / me.nMaxRage)
		hTextRang:SetText(me.nCurrentRage .. '/' .. me.nMaxRage)
	else
		hImageRang:SetPercentage(0)
		hTextRang:SetText('')
	end
	hCangyun:Lookup('Image_Sword'):SetVisible(me.nPoseState == POSE_TYPE.SWORD)
	hCangyun:Lookup('Image_Shield'):SetVisible(me.nPoseState == POSE_TYPE.SHIELD)
	local hShield = hCangyun:Lookup('Handle_Sheild')
	if not hShield then
		return
	end
	if me.nLevel >= 50 then
		hShield:Show()
		hShield:Lookup('Image_Sheild'):SetVisible(me.nCurrentEnergy > 0)
		hShield:Lookup('Image_SheildRed'):SetVisible(me.nCurrentEnergy == 0)
		hShield:Lookup('Text_Num'):SetText(me.nCurrentEnergy)
		if me.nMaxEnergy > 0 then
			hShield:Lookup('Image_SheildProgress'):SetPercentage(0.1 + (me.nCurrentEnergy / me.nMaxEnergy * 0.8))
		else
			hShield:Lookup('Image_SheildProgress'):SetPercentage(0)
		end
	else
		hShield:Hide()
	end
end

-- badao
function D.UpdateBaDao(frame)
	local me, hBaDao = GetClientPlayer(), frame:Lookup('', D.szShow)
	if not me or not hBaDao then
		return
	end
	frame.nUpdateStatus = PlayerEnergyUI_Update(D.szShowSub, hBaDao, me)
end

-- tangmen
function D.GetBombCount()
	if D.nBombTime and (GetTime() - D.nBombTime) < 1000 then
		return D.nBombCount
	end
	local me, nCount = GetClientPlayer(), 0
	for _, v in ipairs(LIB.GetNearNpc()) do
		if v.dwTemplateID == 16000 and v.dwEmployer == me.dwID then
			nCount = nCount + 1
		end
	end
	D.nBombCount = nCount
	D.nBombTime = GetTime()
	return nCount
end

function D.UpdateBomb(frame)
	local h = frame:Lookup('', D.szShow)
	if not h then
		return
	end
	local nCount = D.GetBombCount()
	for i = 0, 2, 1 do
		local img = frame:Lookup('', 'Image_Bomb' .. i)
		if i < nCount then
			img:Show()
		else
			img:Hide()
		end
	end
end

function D.UpdateTangMen(frame)
	local me, h = GetClientPlayer(), frame:Lookup('', D.szShow)
	if D.szShowSub ~= 'TM' or not me or not h then
		return
	end
	if me.nMaxEnergy > 0 then
		h:Lookup('Image_Strip'):SetPercentage(me.nCurrentEnergy / me.nMaxEnergy)
		h:Lookup('Text_Energy'):SetText(me.nCurrentEnergy .. '/' .. me.nMaxEnergy)
	else
		h:Lookup('Image_Strip'):SetPercentage(0)
		h:Lookup('Text_Energy'):SetText('')
	end
end

function D.Update(frame)
	if D.szShowSub == 'CY' or D.szShowSub == 'SL' or D.szShowSub == 'QX' then
		D.UpdateAccumulateValue(frame)
	elseif D.szShowSub == 'TM' then
		D.UpdateTangMen(frame)
		D.UpdateBomb(frame)
	elseif D.szShowSub == 'CJ' then
		D.UpdateCangJian(frame)
	elseif D.szShowSub == 'MJ' then
		D.UpdateMingJiao(frame)
	elseif D.szShow == 'Handle_CangYun' then
		D.UpdateCangYun(frame)
	elseif D.szShow == 'Handle_BaDao' then
		D.UpdateBaDao(frame)
	end
end

function D.UpdateHandleName()
	local mnt = GetClientPlayer().GetKungfuMount()
	local szShow, szShowSub = '', ''
	if mnt then
		if mnt.dwMountType == 3 then
			szShow, szShowSub = 'Handle_ChunYang', 'CY'
		elseif mnt.dwMountType == 5 then
			szShow, szShowSub = 'Handle_ShaoLin', 'SL'
		elseif mnt.dwMountType == 10 then
			szShow, szShowSub = 'Handle_TangMen', 'TM'
		elseif mnt.dwMountType == 4 then
			szShow, szShowSub = 'Handle_QiXiu', 'QX'
		elseif mnt.dwMountType == 8 then
			szShow, szShowSub = 'Handle_MingJiao', 'MJ'
		elseif mnt.dwMountType == 18 then
			szShow, szShowSub = 'Handle_CangYun', 'CYUN'
		elseif mnt.dwMountType == 20 then
			szShow, szShowSub = 'Handle_BaDao', 'BaDao'
		end
	end
	D.szShow = szShow
	D.szShowSub = szShowSub
end

function D.CopyHandle(frame)
	local hTotal = frame:Lookup('', '')
	local me = GetClientPlayer()
	D.UpdateHandleName()
	if me and me.bCanUseBigSword then
		D.szShow = 'Handle_CangJian'
		D.szShowSub = 'CJ'
	end
	hTotal:Clear()
	if D.szShow ~= '' then
		if not Station.Lookup('Normal/PlayerBar', D.szShow) then
			D.szShow = 'Handle_' .. D.szShowSub
		end
		hTotal:AppendItemFromIni('ui\\config\\default\\PlayerBar.ini', D.szShow)
		if D.szShowSub == 'TM' then
			local x = 125
			for i = 0, 2, 1 do
				hTotal:AppendItemFromString('<image>path="' .. PLUGIN_ROOT .. '/img/Ball.UiTex" frame=0 name="Image_Bomb' .. i .. '" x=' .. x .. ' y=0 w=25 h=25 lockshowhide=1 </image>')
				x = x + 25
			end
		elseif D.szShowSub == 'MJ' then
			hTotal:AppendItemFromString('<text>text="" name="Text_Sun" x=87 y=10 w=144 h=20 font=163 </text>')
			hTotal:AppendItemFromString('<text>text="" name="Text_Moon" x=87 y=52 w=144 h=20 font=202 </text>')
		end
		local h = hTotal:Lookup(D.szShow)
		if D.szShowSub == 'CYUN' then
			h:Lookup('SFX_Rang'):Hide()
		end
		h:ClearEvent()
		h:SetRelPos(75, 25)
		h:Show()
	end
	hTotal:FormatAllItemPos()
end

---------------------------------------------------------------------
-- ����������¼�����
---------------------------------------------------------------------
function D.OnFrameCreate()
	this:RegisterEvent('DO_SKILL_CAST')
	this:RegisterEvent('UI_UPDATE_ACCUMULATE')
	this:RegisterEvent('UI_UPDATE_SUN_MOON_POWER_VALUE')
	this:RegisterEvent('SKILL_MOUNT_KUNG_FU')
	this:RegisterEvent('SKILL_UNMOUNT_KUNG_FU')
	this:RegisterEvent('PLAYER_STATE_UPDATE')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('ON_CHARACTER_POSE_STATE_UPDATE')
	UpdateCustomModeWindow(this, _L['MY_EnergyBar'], true)
	D.CopyHandle(this)
	D.Update(this)
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this)
end

function D.OnEvent(event)
	if event == 'SKILL_MOUNT_KUNG_FU' or event == 'SKILL_UNMOUNT_KUNG_FU' then
		D.CopyHandle(this)
		D.Update(this)
	elseif event == 'DO_SKILL_CAST' then
		local me = GetClientPlayer()
		if me.dwID == arg0 then
			local nBomb = D.nBombCount
			if arg1 == 3357 then
				D.nBombCount = 0
			elseif arg1 == 3111 then
				D.nBombCount = D.nBombCount + 1
			end
			if nBomb ~= D.nBombCount then
				D.nBombTime = GetTime()
				D.UpdateBomb(this)
			end
		end
	elseif event == 'UI_UPDATE_ACCUMULATE' then
		D.UpdateAccumulateValue(this)
	elseif event == 'UI_UPDATE_SUN_MOON_POWER_VALUE' then
		D.UpdateMingJiao(this)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' or event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['MY_EnergyBar'], true)
		this:BringToTop()
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'PLAYER_STATE_UPDATE' and arg0 == GetClientPlayer().dwID then
		if D.szShowSub == 'CJ' then
			D.UpdateCangJian(this)
		elseif D.szShowSub == 'TM' then
			D.UpdateTangMen(this)
		elseif D.szShowSub == 'MJ' then
			D.UpdateMingJiao(this)
		elseif D.szShow == 'Handle_CangYun' then
			D.UpdateCangYun(this)
		elseif D.szShow == 'Handle_BaDao' then
			D.UpdateBaDao(this)
		end
	elseif event == 'ON_CHARACTER_POSE_STATE_UPDATE' then
		if D.szShow == 'Handle_CangYun' then
			D.UpdateCangYun(this)
		elseif D.szShow == 'Handle_BaDao' then
			D.UpdateBaDao(this)
		end
	elseif event == 'LOADING_END' then
		D.Update(this)
	end
end

function D.OnFrameBreathe()
	if D.szShowSub == 'TM' and D.nBombTime and D.nBombTime < (GetTime() - 1000) then
		D.UpdateBomb(this)
	end
	if this.nUpdateStatus == 1 then
		if D.szShow == 'Handle_BaDao' then
			D.UpdateBaDao(this)
		end
	end
end

-- macro command
function D.Apply()
	if not GetClientPlayer() then
		return LIB.DelayCall('MY_EnergyBar#Apply', 300, D.Apply)
	end
	if not O.bEnable then
		Wnd.CloseWindow('MY_EnergyBar')
	else
		local frame = Station.Lookup('Normal/MY_EnergyBar')
		if not frame then
			local an = O.tAnchor
			if IsEmpty(an) then
				an = ANCHOR
			end
			UI.CreateFrame('MY_EnergyBar', { empty = true, w = 400, h = 60, penetrable = true, anchor = an })
		end
	end
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Enable MY_EnergyBar'],
		checked = MY_EnergyBar.bEnable,
		oncheck = function(bChecked)
			MY_EnergyBar.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5
	x, y = X, y + 30
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
				tAnchor = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				tAnchor = true,
			},
			triggers = {
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_EnergyBar = LIB.GeneGlobalNS(settings)
end