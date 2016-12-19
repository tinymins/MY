-------------------------
-- 弧形血条 -- 重构
-- By 茗伊@双梦镇@荻花宫
-- ZhaiYiMing.CoM
-- 2015-12-11 09:54:01
-------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ArchHUD/lang/")
local DefaultAnchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0}
MY_ArchHUD = {}
MY_ArchHUD.bOn = false
MY_ArchHUD.Anchor = clone(DefaultAnchor)
MY_ArchHUD.bFightShow = true
MY_ArchHUD.bShowCastingBar = true
MY_ArchHUD.nAlpha = 60
local IMG_DIR = MY.GetAddonInfo().szRoot .. "MY_ArchHUD/img/"
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_ArchHUD/ui/MY_ArchHUD.ini"

RegisterCustomData("MY_ArchHUD.bOn")
RegisterCustomData("MY_ArchHUD.bFightShow")
RegisterCustomData("MY_ArchHUD.bShowCastingBar")
RegisterCustomData("MY_ArchHUD.nAlpha")

function MY_ArchHUD.Reload()
	Wnd.CloseWindow("MY_ArchHUD")
	if MY_ArchHUD.bOn then
		Wnd.OpenWindow(INI_PATH, "MY_ArchHUD")
	end
end
MY.RegisterInit("MY_ArchHUD", MY_ArchHUD.Reload)

function MY_ArchHUD.UpdateAnchor(hFrame)
	hFrame:SetPoint(MY_ArchHUD.Anchor.s, 0, 0, MY_ArchHUD.Anchor.r, MY_ArchHUD.Anchor.x, MY_ArchHUD.Anchor.y)
	hFrame:CorrectPos()
end

local function UpdatePlayerData(hFrame, KSelf)
	if not KSelf then
		return
	end
	
	local nCurrentMana, nMaxMana
	local nManaR, nManaG, nManaB
	local szMana, szManaImage, nManaFrame
	local nCurrentExtra, nMaxExtra
	local nExtraR, nExtraG, nExtraB
	local szExtra, szExtraImage, nExtraFrame
	if KSelf.dwForceID == FORCE_TYPE.SHAO_LIN then
		local nAccumulate = math.min(KSelf.nAccumulateValue, 3)
		szExtra = _L["ChanNa:"] .. tostring(nAccumulate)
		nCurrentExtra, nMaxExtra = nAccumulate, 3
		szExtraImage, nExtraFrame = "rRing_T.UITex", 0
		nCurrentMana, nMaxMana = KSelf.nCurrentMana, KSelf.nMaxMana
	elseif KSelf.dwForceID == FORCE_TYPE.CHUN_YANG then
		local nAccumulate = math.min(KSelf.nAccumulateValue, 10) / 2
		szExtra = _L["Qi:"] .. tostring(nAccumulate)
		nCurrentExtra, nMaxExtra = nAccumulate, 5
		szExtraImage, nExtraFrame = "rRing.UITex", 0
		nCurrentMana, nMaxMana = KSelf.nCurrentMana, KSelf.nMaxMana
	elseif KSelf.dwForceID == FORCE_TYPE.QI_XIU then
		local nAccumulate = math.min(KSelf.nAccumulateValue, 10)
		szExtra = _L["JianWu:"] .. tostring(nAccumulate)
		nCurrentExtra, nMaxExtra = nAccumulate, 10
		szExtraImage, nExtraFrame = "rRing.UITex", 2
		nCurrentMana, nMaxMana = KSelf.nCurrentMana, KSelf.nMaxMana
	elseif KSelf.dwForceID == FORCE_TYPE.TANG_MEN then
		nManaR, nManaG, nManaB = 255, 255, 0
		szManaImage, nManaFrame = "rRing.UITex", 2
		nCurrentMana, nMaxMana = KSelf.nCurrentEnergy, KSelf.nMaxEnergy
	elseif KSelf.dwForceID == FORCE_TYPE.CANG_JIAN then
		nManaR, nManaG, nManaB = 255, 150, 0
		szManaImage, nManaFrame = "rRing.UITex", 1
		nCurrentMana, nMaxMana = KSelf.nCurrentRage, KSelf.nMaxRage
	elseif KSelf.dwForceID == FORCE_TYPE.MING_JIAO then
		nManaR, nManaG, nManaB = 255, 255, 0
		if KSelf.nSunPowerValue == 1 then
			szMana = _L["ManRi!"]
			szManaImage, nManaFrame = "rRing.UITex", 1
			szExtraImage, nExtraFrame = "rRing.UITex", 1
			nCurrentMana, nMaxMana = KSelf.nMaxSunEnergy, KSelf.nMaxSunEnergy
		elseif KSelf.nMoonPowerValue == 1 then
			szMana = _L["ManYue!"]
			szManaImage, nManaFrame = "rRing.UITex", 3
			szExtraImage, nExtraFrame = "rRing.UITex", 3
			nCurrentMana, nMaxMana = KSelf.nMaxMoonEnergy, KSelf.nMaxMoonEnergy
		else
			szManaImage, nManaFrame = "rRing.UITex", 3
			szExtraImage, nExtraFrame = "rRing.UITex", 1
			nCurrentMana, nMaxMana = KSelf.nCurrentMoonEnergy, KSelf.nMaxMoonEnergy
			nCurrentExtra, nMaxExtra = KSelf.nCurrentSunEnergy, KSelf.nMaxSunEnergy
			szMana = _L["Ri:"] .. tostring(KSelf.nCurrentSunEnergy / 100) .. " " .. _L["Yue:"] .. tostring(KSelf.nCurrentMoonEnergy / 100)
		end
		szExtra = ""
	elseif KSelf.dwForceID == FORCE_TYPE.CANG_YUN then
		nManaR, nManaG, nManaB = 191, 63, 31
		szManaImage, nManaFrame = "rRing.UITex", 1
		nCurrentMana, nMaxMana = KSelf.nCurrentRage, KSelf.nMaxRage
	elseif KSelf.dwForceID == FORCE_TYPE.CHANG_GE then
		local nAccumulate = math.min(KSelf.nAccumulateValue, 5)
		szExtra = _L["Qu:"] .. tostring(nAccumulate)
		nCurrentExtra, nMaxExtra = nAccumulate, 5
		szExtraImage, nExtraFrame = "rRing.UITex", 2
		nCurrentMana, nMaxMana = KSelf.nCurrentMana, KSelf.nMaxMana
	elseif KSelf.dwForceID == FORCE_TYPE.BA_DAO then
		if KSelf.nPoseState == POSE_TYPE.BROADSWORD then
			nCurrentMana, nMaxMana = KSelf.nCurrentRage, KSelf.nMaxRage
		elseif KSelf.nPoseState == POSE_TYPE.DOUBLE_BLADE then
			nCurrentMana, nMaxMana = KSelf.nCurrentEnergy, KSelf.nMaxEnergy
		elseif KSelf.nPoseState == POSE_TYPE.SHEATH_KNIFE then
			nCurrentMana, nMaxMana = KSelf.nCurrentSunEnergy, KSelf.nMaxSunEnergy
		end
	else
		nCurrentMana, nMaxMana = KSelf.nCurrentMana, KSelf.nMaxMana
	end
	
	hFrame.hSelfHealth:Show()
	hFrame.hTextSelfHealth:SetText(tostring(KSelf.nCurrentLife) .. "(" .. KeepTwoByteFloat(KSelf.nCurrentLife / KSelf.nMaxLife * 100) .. "%)")
	hFrame.hImageSelfHealth:SetPercentage(KSelf.nCurrentLife / KSelf.nMaxLife)
	
	hFrame.hSelfMana:Show()
	if nManaR and nManaG and nManaB then
		hFrame.hTextSelfMana:SetFontColor(nManaR, nManaG, nManaB)
	end
	if szManaImage and nManaFrame then
		hFrame.hImageSelfMana:FromUITex(IMG_DIR .. szManaImage, nManaFrame)
	end
	if not szMana then
		szMana = "(" .. KeepTwoByteFloat(nCurrentMana / nMaxMana * 100) .. "%)" .. nCurrentMana
	end
	hFrame.hTextSelfMana:SetText(szMana)
	hFrame.hImageSelfMana:SetPercentage(nCurrentMana / nMaxMana)
	
	if nCurrentExtra then
		hFrame.hSelfExtra:Show()
		if szExtraImage and nExtraFrame then
			hFrame.hImageSelfExtra:FromUITex(IMG_DIR .. szExtraImage, nExtraFrame)
		end
		if not szExtra and nCurrentExtra then
			szExtra = "(" .. KeepTwoByteFloat(nCurrentExtra / nMaxExtra * 100) .. "%)" .. nCurrentExtra
		end
		hFrame.hTextSelfExtra:SetText(szExtra or "")
		hFrame.hImageSelfExtra:SetPercentage(nCurrentExtra / nMaxExtra)
	else
		hFrame.hSelfExtra:Hide()
	end
end

local function UpdateTargetData(hFrame, KTarget)
	if KTarget and KTarget.dwID ~= UI_GetClientPlayerID() then
		hFrame.hTargetHealth:Show()
		hFrame.hImageTargetHealth:SetPercentage(KTarget.nCurrentLife / KTarget.nMaxLife)
		local szLife = ""
		if KTarget.nCurrentLife >= 100000000 then
			szLife = ("%.2f"):format(KTarget.nCurrentLife / 100000000) .. _L['One hundred million']
		elseif KTarget.nCurrentLife >= 100000 then
			szLife = ("%.2f"):format(KTarget.nCurrentLife / 10000) .. _L['Ten thousand']
		else
			szLife = tonumber(KTarget.nCurrentLife)
		end
		hFrame.hTextTargetHealth:SetText(szLife .. "(" .. KeepTwoByteFloat(KTarget.nCurrentLife / KTarget.nMaxLife * 100) .. "%)")
	else
		hFrame.hTargetHealth:Hide()
	end
end

local function UpdateTargetCasting(hFrame, KTarget)
	if KTarget then
		hFrame.hTargetHealth:Show()
		hFrame.hImageTargetHealth:SetPercentage(KTarget.nCurrentLife / KTarget.nMaxLife)
		local bPrePare, dwSkillID, dwSkillLevel, fCastPercent = KTarget.GetSkillPrepareState()
		if bPrePare then
			hFrame.hImageTargetCasting:SetPercentage(fCastPercent)
			hFrame.hTargetCasting:Show()
			if hFrame.dwTargetCasting ~= dwSkillID then
				hFrame.dwTargetCasting = dwSkillID
				hFrame.hTextTargetCasting:SetText(Table_GetSkillName(dwSkillID, dwSkillLevel))
			end
		else
			hFrame.hTargetCasting:Hide()
		end
	else
		hFrame.hTargetHealth:Hide()
		hFrame.hTargetCasting:Hide()
	end
end

function MY_ArchHUD.OnFrameCreate()
	if MY_ArchHUD.bShowCastingBar then
		this:RegisterEvent("RENDER_FRAME_UPDATE")
	end
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_STATE_UPDATE")
	this:RegisterEvent("NPC_STATE_UPDATE")
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT")
	-- Handle
	this.hSelfHealth    = this:Lookup("", "Handle_SelfHealth")
	this.hSelfMana      = this:Lookup("", "Handle_SelfMana")
	this.hSelfExtra     = this:Lookup("", "Handle_SelfExtra")
	this.hTargetHealth  = this:Lookup("", "Handle_TargetHealth")
	this.hTargetCasting = this:Lookup("", "Handle_TargetCasting")
	-- Text
	this.hTextSelfHealth    = this.hSelfHealth:Lookup(2)
	this.hTextSelfMana      = this.hSelfMana:Lookup(2)
	this.hTextSelfExtra     = this.hSelfExtra:Lookup(2)
	this.hTextTargetHealth  = this.hTargetHealth:Lookup(2)
	this.hTextTargetCasting = this.hTargetCasting:Lookup(2)
	-- Process Bar
	this.hImageSelfHealth    = this.hSelfHealth:Lookup(1)
	this.hImageSelfMana      = this.hSelfMana:Lookup(1)
	this.hImageSelfExtra     = this.hSelfExtra:Lookup(1)
	this.hImageTargetHealth  = this.hTargetHealth:Lookup(1)
	this.hImageTargetCasting = this.hTargetCasting:Lookup(1)
	-- Init
	MY_ArchHUD.UpdateAnchor(this)
	this.hSelfHealth:Hide()
	this.hSelfMana:Hide()
	this.hSelfExtra:Hide()
	this.hTargetHealth:Hide()
	this.hTargetCasting:Hide()
	this.hTextSelfHealth:SetFontColor(0, 255, 0)
	this.hTextSelfMana:SetFontColor(0, 200, 255)
	this.hTextSelfExtra:SetFontColor(255, 255, 0)
	this.hTextTargetHealth:SetFontColor(255, 255, 0)
	this.hTextTargetCasting:SetFontColor(255, 255, 0)
	this:SetAlpha(MY_ArchHUD.nAlpha * 2.55)
	local KSelf = GetClientPlayer()
	if KSelf then
		UpdatePlayerData(this, KSelf)
		UpdateTargetCasting(this, GetTargetHandle(KSelf.GetTarget()))
	end
	MY_ArchHUD.OnFrameBreathe()
end

function MY_ArchHUD.OnFrameBreathe()
	if not (this.KSelf and this.KSelf.szName) then
		this.KSelf = GetClientPlayer()
	end
	local KSelf = this.KSelf
	if not KSelf or (MY_ArchHUD.bFightShow and not KSelf.bFightState) then
		this:Hide()
		return
	else
		this:Show()
	end
	local dwType, dwID = KSelf.GetTarget()
	if this.dwType ~= dwType or this.dwID ~= dwID then
		this.dwType = dwType
		this.dwID   = dwID
		UpdateTargetData(this, GetTargetHandle(KSelf.GetTarget()))
	end
end

function MY_ArchHUD.OnEvent(event)
	if event == "RENDER_FRAME_UPDATE" then
		local KSelf = GetClientPlayer()
		if not KSelf then
			return
		end
		UpdateTargetCasting(this, GetTargetHandle(KSelf.GetTarget()))
	elseif event == "PLAYER_STATE_UPDATE" then
		local KSelf = GetClientPlayer()
		if not KSelf then
			return
		end
		if arg0 == KSelf.dwID then
			UpdatePlayerData(this, KSelf)
		end
		local dwType, dwID = KSelf.GetTarget()
		if arg0 == dwID and dwType == TARGET.PLAYER then
			UpdateTargetData(this, GetTargetHandle(dwType, dwID))
		end
	elseif event == "NPC_STATE_UPDATE" then
		local KSelf = GetClientPlayer()
		if not KSelf then
			return
		end
		local dwType, dwID = KSelf.GetTarget()
		if arg0 == dwID and dwType == TARGET.NPC then
			UpdateTargetData(this, GetTargetHandle(dwType, dwID))
		end
	elseif event == "UI_SCALED" then
		MY_ArchHUD.UpdateAnchor(this)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, _L['MY_ArchHUD'], true)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		MY_ArchHUD.Anchor = GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L['MY_ArchHUD'], true)
	elseif event == "CUSTOM_UI_MODE_SET_DEFAULT" then
		MY_ArchHUD.Anchor = clone(DefaultAnchor)
		MY_ArchHUD.UpdateAnchor(this)
	end
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local x, y = 30, 30
	local w, h = ui:size()

	ui:append("WndCheckBox", {
		x = x, y = y, w = 120,
		text = _L['enable'],
		checked = MY_ArchHUD.bOn,
		oncheck = function(bCheck)
			MY_ArchHUD.bOn = bCheck
			MY_ArchHUD.Reload()
		end,
	})
	y = y + 45
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = 200,
		text = _L['hide when unfight'],
		checked = MY_ArchHUD.bFightShow,
		oncheck = function(bCheck)
			MY_ArchHUD.bFightShow = bCheck
			MY_ArchHUD.Reload()
		end,
	})
	y = y + 45
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = 200,
		text = _L['display target casting'],
		checked = MY_ArchHUD.bShowCastingBar,
		oncheck = function(bCheck)
			MY_ArchHUD.bShowCastingBar = bCheck
			MY_ArchHUD.Reload()
		end,
	})
	y = y + 45
	
	ui:append("WndSliderBox", {
		x = x, y = y, w = 200,
		text = _L('current alpha is %d%%.', MY_ArchHUD.nAlpha),
		textfmt = function(val) return _L("current alpha is %d%%.", val) end,
		range = {0, 100},
		value = MY_ArchHUD.nAlpha,
		onchange = function(raw, val)
			MY_ArchHUD.nAlpha = val
			local frame = Station.Lookup("Lowest/MY_ArchHUD")
			if frame then
				frame:SetAlpha(MY_ArchHUD.nAlpha * 2.55)
			end
		end,
	})
	y = y + 45
	
	ui:append("Text", {
		x = x, y = y, w = 120,
		text = _L['origin author: Sulian Yi'],
	})
end
MY.RegisterPanel("MY_ArchHUD", _L["MY_ArchHUD"], _L['General'], 6767, {255,255,0,200}, PS)
