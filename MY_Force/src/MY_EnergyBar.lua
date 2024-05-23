--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : BUFF列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Force/MY_EnergyBar'
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_EnergyBar'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.3') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local INI_PATH = PLUGIN_ROOT .. '/ui/PlayerBar.ini'

local O = X.CreateUserSettingsModule('MY_EnergyBar', _L['Target'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = 65, y = 250, s = 'CENTER', r = 'CENTER' },
	},
})
local D = {
	nBombCount = 0,
	tBombMsg = {},
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
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	frame:CorrectPos()
end

function D.UpdateAccumulateValue(frame)
	if not D.szShow or D.szShow == '' then
		return
	end
	local handle = frame:Lookup('', D.szShow)
	if handle then
		local nValue = X.GetClientPlayer().nAccumulateValue
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
	local me, hCangjian = X.GetClientPlayer(), frame:Lookup('', D.szShow)
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
	local me = X.GetClientPlayer()

	local hImageSunEnergy = hMingJiao:Lookup('Image_SunEnergy')
	local hImageMoonEnergy = hMingJiao:Lookup('Image_MoonEnergy')
	local bShowSunEnergy = (me.nCurrentSunEnergy > 0 or me.nCurrentMoonEnergy > 0)
						and me.nCurrentSunEnergy < 10000
	local bShowMoonEnergy = (me.nCurrentSunEnergy > 0 or me.nCurrentMoonEnergy > 0)
						and me.nCurrentMoonEnergy < 10000
	local sunPer, moonPer = 0, 0
	if me.nMaxSunEnergy ~= 0 then
		sunPer = me.nCurrentSunEnergy / me.nMaxSunEnergy
	end

	if me.nMaxMoonEnergy ~= 0 then
		moonPer = me.nCurrentMoonEnergy / me.nMaxMoonEnergy
	end

	hImageSunEnergy:SetPercentage(sunPer)
	hImageMoonEnergy:SetPercentage(moonPer)

	hMingJiao:Lookup('Text_Sun'):Show(me.nSunPowerValue == 0 and me.nCurrentSunEnergy ~= me.nMaxSunEnergy and me.nCurrentSunEnergy ~= 0)
	local nInteger = math.modf(sunPer * 100)
	if nInteger > 100 then nInteger = 100 end
	hMingJiao:Lookup('Text_Sun'):SetText(tostring(nInteger))
	hMingJiao:Lookup('Text_Moon'):Show(me.nMoonPowerValue == 0 and me.nCurrentMoonEnergy ~= me.nMaxMoonEnergy and me.nCurrentMoonEnergy ~= 0)
	nInteger = math.modf(moonPer * 100)
	if nInteger > 100 then nInteger = 100 end
	hMingJiao:Lookup('Text_Moon'):SetText(tostring(nInteger))

	hImageSunEnergy:Show(me.nSunPowerValue <= 0)
	hImageMoonEnergy:Show(me.nMoonPowerValue <= 0)
	hMingJiao:Lookup('Image_MingJiaoBG2'):Show(
		me.nMoonPowerValue <= 0 and
		me.nSunPowerValue <= 0 and
		me.nCurrentSunEnergy <= 0 and
		me.nCurrentMoonEnergy <= 0
	)
	hMingJiao:Lookup('Image_SunCao'):Show(bShowSunEnergy)
	hMingJiao:Lookup('Image_SunBG'):Show(me.nSunPowerValue > 0)
	hMingJiao:Lookup('SFX_Sun'):Show(me.nSunPowerValue > 0)

	hMingJiao:Lookup('Image_MoonCao'):Show(bShowMoonEnergy)
	hMingJiao:Lookup('Image_MoonBG'):Show(me.nMoonPowerValue > 0)
	hMingJiao:Lookup('SFX_Moon'):Show(me.nMoonPowerValue > 0)
end

-- cangyun pose type
function D.UpdateCangYun(frame)
	local me, hCangyun = X.GetClientPlayer(), frame:Lookup('', D.szShow)
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
	local me, hBaDao = X.GetClientPlayer(), frame:Lookup('', D.szShow)
	if not me or not hBaDao then
		return
	end
	frame.nUpdateStatus = PlayerEnergyUI_Update(D.szShowSub, hBaDao, me)
end

-- 唐门机关暗藏杀机 抄的官方代码
function D.UpdateBomb(frame)
	local h = frame:Lookup('', D.szShow)
	local me = X.GetClientPlayer()
	if not h or not me then
		return
	end
	local hBombList = h:Lookup('Handle_ACSJ')
	local ACSJ_SKILL_BUFF_LIST_ID = 2 --唐门暗藏杀机BUFF列表
	if hBombList then
		local tBuffList, nBombID = Table_GetCustomBuffList(ACSJ_SKILL_BUFF_LIST_ID), nil
		for i, nBuffID in ipairs(tBuffList) do
			local bExist = me.IsHaveBuff(nBuffID, 1)
			if bExist then
				local buff = X.GetBuff(me, nBuffID)
				if buff then
					local nLeftTime = math.floor((buff.nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS)
					if D.tBombMsg[i] and D.tBombMsg[i].nTime >= nLeftTime then
						D.tBombMsg[i].nTime = nLeftTime
					else
						D.tBombMsg[i] = {nID = nBuffID, nTime = nLeftTime}
					end
				else
					D.tBombMsg[i] = nil
				end
			else
				D.tBombMsg[i] = nil
			end
		end

		for i, nBuffID in ipairs(tBuffList) do
			local pBomb, bFound = me.GetBomb(i - 1), false
			if pBomb then
				for _, tBomb in pairs(D.tBombMsg) do
					if tBomb.nBombNpcID == pBomb.dwID then
						bFound = true
						break
					end
				end
				if not bFound then
					nBombID = pBomb.dwID
				end
			end
		end
		if nBombID then
			for _, tBomb in pairs(D.tBombMsg) do
				if not tBomb.nBombNpcID then
					tBomb.nBombNpcID = nBombID
					break
				end
			end
		end

		for i, nBuffID in ipairs(tBuffList) do
			local hBomb = hBombList:Lookup(i - 1)
			hBomb:Hide()
			if D.tBombMsg[i] then
				hBomb:Show()
				hBomb:Lookup(2):SetText(tostring(D.tBombMsg[i].nTime))
				if D.tBombMsg[i].nBombNpcID then
					local npc = X.GetNpc(D.tBombMsg[i].nBombNpcID)
					local nDistance = npc and X.GetDistance(npc, 'plane')
					if nDistance and nDistance <= 30 then
						hBomb:SetAlpha(255)
					else
						hBomb:SetAlpha(100)
					end
				end
			end
		end
	end
end

function D.UpdateTangMen(frame)
	local me, h = X.GetClientPlayer(), frame:Lookup('', D.szShow)
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
	local mnt = X.GetClientPlayer().GetKungfuMount()
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
	local me = X.GetClientPlayer()
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
		hTotal:AppendItemFromIni(INI_PATH, D.szShow)
		local h = hTotal:Lookup(D.szShow)
		if D.szShowSub == 'MJ' then
			h:AppendItemFromString('<image>x=-4 y=-1 w=44 h=40 path="ui\\Image\\UICommon\\skills2.UITex" frame=11</image>')
			h:FormatAllItemPos()
		end
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
-- 能量条相关事件函数
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
		if X.CONSTANT.KUNGFU_FORCE_TYPE[arg0] == X.CONSTANT.FORCE_TYPE.CANG_JIAN then
			return
		end
		D.CopyHandle(this)
		D.Update(this)
	elseif event == 'DO_SKILL_CAST' then
		local me = X.GetClientPlayer()
		if me.dwID == arg0 then
			local nBomb = D.nBombCount
			if arg1 == 3357 then
				D.nBombCount = 0
			elseif arg1 == 3111 then
				D.nBombCount = D.nBombCount + 1
			end
			if nBomb ~= D.nBombCount then
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
	elseif event == 'PLAYER_STATE_UPDATE' and arg0 == X.GetClientPlayer().dwID then
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
	if D.szShowSub == 'TM' then
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
	if not X.GetClientPlayer() then
		return X.DelayCall('MY_EnergyBar#Apply', 300, D.Apply)
	end
	if not O.bEnable then
		X.UI.CloseFrame('MY_EnergyBar')
	else
		local frame = Station.Lookup('Normal/MY_EnergyBar')
		if not frame then
			X.UI.CreateFrame('MY_EnergyBar', { empty = true, w = 400, h = 60, penetrable = true, anchor = O.tAnchor })
		end
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	if X.ENVIRONMENT.GAME_BRANCH ~= 'classic' then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Enable MY_EnergyBar'],
			checked = O.bEnable,
			onCheck = function(bChecked)
				O.bEnable = bChecked
				D.Apply()
			end,
		}):AutoWidth():Width() + 5
		-- crlf
		nX = nPaddingX + 10
		nY = nY + 28
	end
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_EnergyBar',
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
	},
}
MY_EnergyBar = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_EnergyBar', D.Apply)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
