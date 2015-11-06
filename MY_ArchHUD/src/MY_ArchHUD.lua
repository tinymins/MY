-------------------------
-- 弧形血条
-- By 茗伊@双梦镇@荻花宫
-- ZhaiYiMing.CoM
-- 2015年11月4日10:54:06
-------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ArchHUD/lang/")
MY_ArchHUD = {}
MY_ArchHUD.DefaultAnchor = {s = "CENTER", r = "CENTER",  x = 0, y = 0}
MY_ArchHUD.bOn = true
MY_ArchHUD.bFightShow = false
MY_ArchHUD.bShowCastingBar = true
MY_ArchHUD.nAlpha = 60

local IMG_DIR = MY.GetAddonInfo().szRoot .. "MY_ArchHUD/img/"
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_ArchHUD/ui/MY_ArchHUD.ini"

RegisterCustomData("MY_ArchHUD.bOn")
RegisterCustomData("MY_ArchHUD.bFightShow")
RegisterCustomData("MY_ArchHUD.bShowCastingBar")
RegisterCustomData("MY_ArchHUD.nAlpha")

function MY_ArchHUD.OnFrameCreate()
	this:RegisterEvent("CUSTOM_DATA_LOADED")
	this:RegisterEvent("RENDER_FRAME_UPDATE")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_STATE_UPDATE")
	this:RegisterEvent("NPC_STATE_UPDATE")
	local frame = Station.Lookup("Lowest/MY_ArchHUD")
	local handle = frame:Lookup("", "")
	MY_ArchHUD.TargetHeath = handle:Lookup("Image_Lfore_T")
	MY_ArchHUD.TargetHeath_bg = handle:Lookup("Image_Lbg_T")
	MY_ArchHUD.MyHeath = handle:Lookup("Image_Lfore")
	MY_ArchHUD.MyHeath_bg = handle:Lookup("Image_Lbg")
	MY_ArchHUD.MyMana = handle:Lookup("Image_Rfore")
	MY_ArchHUD.MyMana_bg = handle:Lookup("Image_Rbg")
	MY_ArchHUD.Myextra = handle:Lookup("Image_extrafore")
	MY_ArchHUD.Myextra_bg = handle:Lookup("Image_extrabg")
	MY_ArchHUD.TargetCasting = handle:Lookup("Image_Rfore_T")
	MY_ArchHUD.TargetCasting:Hide()
	MY_ArchHUD.TargetCasting_bg = handle:Lookup("Image_Rbg_T")
	MY_ArchHUD.TargetCasting_bg:Hide()
	MY_ArchHUD.Text_My_Health = handle:Lookup("Text_My_Health")
	MY_ArchHUD.Text_My_Health:SetFontColor(0, 255, 0)
	MY_ArchHUD.Text_My_Mana = handle:Lookup("Text_My_Mana")
	MY_ArchHUD.Text_My_Mana:SetFontColor(0, 200, 255)
	MY_ArchHUD.Text_T_Heath = handle:Lookup("Text_T_Heath")
	MY_ArchHUD.Text_T_Heath:SetFontColor(255, 255, 0)
	MY_ArchHUD.Text_T_Cast = handle:Lookup("Text_T_Cast")
	MY_ArchHUD.Text_T_Cast:SetFontColor(255, 255, 0)
	MY_ArchHUD.Text_T_Cast:Hide()
	MY_ArchHUD.Text_My_Acc = handle:Lookup("Text_My_Acc")
	MY_ArchHUD.Text_My_Acc:SetFontColor(255, 255, 0)
	MY_ArchHUD.HideTargetFrame()
	MY_ArchHUD.UpdateAnchor(this)
end
function MY_ArchHUD.HideTargetFrame()
	MY_ArchHUD.TargetHeath:Hide()
	MY_ArchHUD.TargetHeath_bg:Hide()
	--MY_ArchHUD.TargetCasting:Hide()
	--MY_ArchHUD.TargetCasting_bg:Hide()
	MY_ArchHUD.Text_T_Heath:Hide()
	--MY_ArchHUD.Text_T_Cast:Hide()
end
function MY_ArchHUD.ShowTargetFrame()
	MY_ArchHUD.TargetHeath:Show()
	MY_ArchHUD.TargetHeath_bg:Show()
	--MY_ArchHUD.TargetCasting:Show()
	--MY_ArchHUD.TargetCasting_bg:Show()
	MY_ArchHUD.Text_T_Heath:Show()
	--MY_ArchHUD.Text_T_Cast:Show()
end
function MY_ArchHUD.HideMyFrame()
	MY_ArchHUD.MyHeath:Hide()
	MY_ArchHUD.MyHeath_bg:Hide()
	MY_ArchHUD.MyMana:Hide()
	MY_ArchHUD.MyMana_bg:Hide()
	MY_ArchHUD.Myextra:Hide()
	MY_ArchHUD.Myextra_bg:Hide()
	MY_ArchHUD.Text_My_Health:Hide()
	MY_ArchHUD.Text_My_Mana:Hide()
	MY_ArchHUD.Text_My_Acc:Hide()
end
function MY_ArchHUD.ShowMyFrame()
	MY_ArchHUD.MyHeath:Show()
	MY_ArchHUD.MyHeath_bg:Show()
	MY_ArchHUD.MyMana:Show()
	MY_ArchHUD.MyMana_bg:Show()
	MY_ArchHUD.Myextra:Show()
	MY_ArchHUD.Myextra_bg:Show()
	MY_ArchHUD.Text_My_Health:Show()
	MY_ArchHUD.Text_My_Mana:Show()
	MY_ArchHUD.Text_My_Acc:Show()
end
function MY_ArchHUD.OnFrameBreathe()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local dwType, dwID = hPlayer.GetTarget()
	if dwID == 0 or dwID == hPlayer.dwID then
		MY_ArchHUD.HideTargetFrame()
		MY_ArchHUD.dwID = dwID
		MY_ArchHUD.dwType = dwType
		return
	end
	if dwID ~= MY_ArchHUD.dwID or dwType ~= MY_ArchHUD.dwType then
		MY_ArchHUD.dwID = dwID
		MY_ArchHUD.dwType = dwType
		MY_ArchHUD.UpdateTargetData()
	end
	MY_ArchHUD.UpdateCasting()
end
function MY_ArchHUD.OnEvent(event)
	if event == "UI_SCALED" then
		MY_ArchHUD.UpdateAnchor(this)
	elseif event == "PLAYER_STATE_UPDATE" then
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end
		if arg0 == hPlayer.dwID then
				MY_ArchHUD.UpdatePlayerData()
		end
		local dwType, dwID = hPlayer.GetTarget()
		if arg0 == dwID and dwType == TARGET.PLAYER then
				MY_ArchHUD.UpdateTargetData()
		end
	elseif event == "NPC_STATE_UPDATE" then
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end
		local dwType, dwID = hPlayer.GetTarget()
		if arg0 == dwID and dwType == TARGET.NPC then
				MY_ArchHUD.UpdateTargetData()
		end
	elseif event == "CUSTOM_DATA_LOADED" then
		this:SetAlpha(MY_ArchHUD.nAlpha * 2.55)
	end
end
function MY_ArchHUD.UpdatePlayerData()
	local me = GetClientPlayer()
	if not me then
		return
	end
	if MY_ArchHUD.bOn == false
	or (MY_ArchHUD.bFightShow == true and me.bFightState == false) then
		return MY_ArchHUD.HideMyFrame()
	end
	MY_ArchHUD.ShowMyFrame()
	MY_ArchHUD.Text_My_Acc:Hide()
	MY_ArchHUD.Myextra:Hide()
	MY_ArchHUD.Myextra_bg:Hide()
	MY_ArchHUD.Text_My_Health:SetText(""..tostring(me.nCurrentLife).."("..KeepTwoByteFloat(me.nCurrentLife / me.nMaxLife * 100).."%)")
	MY_ArchHUD.MyHeath:SetPercentage(me.nCurrentLife/me.nMaxLife)
	if me.dwForceID == FORCE_TYPE.SHAO_LIN then
		local nAccumulate = me.nAccumulateValue
		if nAccumulate > 3 then
			nAccumulate = 3
		end
		MY_ArchHUD.Text_My_Acc:Show()
		MY_ArchHUD.Text_My_Acc:SetText(_L["ChanNa:"]..tostring(nAccumulate))
		MY_ArchHUD.Text_My_Mana:SetText("".."("..KeepTwoByteFloat(me.nCurrentMana / me.nMaxMana * 100).."%)"..tostring(me.nCurrentMana))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMana/me.nMaxMana)
	elseif me.dwForceID == FORCE_TYPE.CHUN_YANG then
		local nAccumulate = me.nAccumulateValue
		if nAccumulate > 10 then
			nAccumulate = 10
		end
		MY_ArchHUD.Text_My_Acc:Show()
		MY_ArchHUD.Text_My_Acc:SetText(_L["Qi:"]..tostring(nAccumulate/2))
		MY_ArchHUD.Text_My_Mana:SetText("".."("..KeepTwoByteFloat(me.nCurrentMana / me.nMaxMana * 100).."%)"..tostring(me.nCurrentMana))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMana/me.nMaxMana)
	elseif me.dwForceID == FORCE_TYPE.QI_XIU then
		local nAccumulate = me.nAccumulateValue
		if nAccumulate > 10 then
			nAccumulate = 10
		end
		MY_ArchHUD.Text_My_Acc:Show()
		MY_ArchHUD.Text_My_Acc:SetText(_L["JianWu:"]..tostring(nAccumulate))
		MY_ArchHUD.Text_My_Mana:SetText("".."("..KeepTwoByteFloat(me.nCurrentMana / me.nMaxMana * 100).."%)"..tostring(me.nCurrentMana))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMana/me.nMaxMana)
	elseif me.dwForceID == FORCE_TYPE.TANG_MEN then
		MY_ArchHUD.MyMana:FromUITex(IMG_DIR .. "rRing.UITex", 2)
		MY_ArchHUD.Text_My_Acc:Hide()
		MY_ArchHUD.Text_My_Mana:SetFontColor(255, 255, 0)
		MY_ArchHUD.Text_My_Mana:SetText("      "..tostring(me.nCurrentEnergy).."/"..tostring(me.nMaxEnergy))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentEnergy/me.nMaxEnergy)
	elseif me.dwForceID == FORCE_TYPE.CANG_JIAN then
		MY_ArchHUD.MyMana:FromUITex(IMG_DIR .. "rRing.UITex", 1)
		MY_ArchHUD.Text_My_Acc:Hide()
		MY_ArchHUD.Text_My_Mana:SetFontColor(255, 150, 0)
		MY_ArchHUD.Text_My_Mana:SetText("      "..tostring(me.nCurrentRage).."/"..tostring(me.nMaxRage))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentRage/me.nMaxRage)
	elseif me.dwForceID == FORCE_TYPE.GAI_BANG then
		MY_ArchHUD.Text_My_Acc:Hide()
		MY_ArchHUD.Text_My_Mana:SetText("       "..FixFloat(me.nCurrentMana / me.nMaxMana * 100, 0).."%")
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMana/me.nMaxMana)
	elseif me.dwForceID == FORCE_TYPE.MING_JIAO then
		MY_ArchHUD.Myextra:Show()
		MY_ArchHUD.Myextra_bg:Show()
		MY_ArchHUD.Text_My_Acc:Hide()
		MY_ArchHUD.Text_My_Mana:SetFontColor(255, 255, 0)
		if me.nSunPowerValue == 1 then
			MY_ArchHUD.Text_My_Mana:SetText(_L["ManRi!"])
			MY_ArchHUD.MyMana:FromUITex(IMG_DIR .. "rRing.UITex", 1)
			MY_ArchHUD.Myextra:FromUITex(IMG_DIR .. "rRing.UITex", 1)
			MY_ArchHUD.MyMana:SetPercentage(100)
			MY_ArchHUD.Myextra:SetPercentage(100)
		elseif me.nMoonPowerValue == 1 then
			MY_ArchHUD.MyMana:FromUITex(IMG_DIR .. "rRing.UITex", 3)
			MY_ArchHUD.Myextra:FromUITex(IMG_DIR .. "rRing.UITex", 3)
			MY_ArchHUD.Text_My_Mana:SetText(_L["ManYue!"])
			MY_ArchHUD.MyMana:SetPercentage(100)
			MY_ArchHUD.Myextra:SetPercentage(100)
		else
			MY_ArchHUD.MyMana:FromUITex(IMG_DIR .. "rRing.UITex", 3)
			MY_ArchHUD.Myextra:FromUITex(IMG_DIR .. "rRing.UITex", 1)
			MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMoonEnergy/me.nMaxMoonEnergy)
			MY_ArchHUD.Myextra:SetPercentage(me.nCurrentSunEnergy/me.nMaxSunEnergy)
			MY_ArchHUD.Text_My_Mana:SetText(_L["Ri:"]..tostring(me.nCurrentSunEnergy/100).." ".._L["Yue:"]..tostring(me.nCurrentMoonEnergy/100))
		end
	elseif me.dwForceID == FORCE_TYPE.CANG_YUN then
		MY_ArchHUD.MyMana:FromUITex(IMG_DIR .. "rRing.UITex", 1)
		MY_ArchHUD.Text_My_Acc:Hide()
		MY_ArchHUD.Text_My_Mana:SetFontColor(191, 63, 31)
		MY_ArchHUD.Text_My_Mana:SetText("      "..tostring(me.nCurrentRage).."/"..tostring(me.nMaxRage))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentRage/me.nMaxRage)
	elseif me.dwForceID == FORCE_TYPE.CHANG_GE then
		local nAccumulate = me.nAccumulateValue
		if nAccumulate > 5 then
			nAccumulate = 5
		end
		MY_ArchHUD.Text_My_Acc:Show()
		MY_ArchHUD.Text_My_Acc:SetText(_L["Qu:"]..tostring(nAccumulate))
		MY_ArchHUD.Text_My_Mana:SetText("".."("..KeepTwoByteFloat(me.nCurrentMana / me.nMaxMana * 100).."%)"..tostring(me.nCurrentMana))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMana/me.nMaxMana)
	else
		MY_ArchHUD.Text_My_Mana:SetText("".."("..KeepTwoByteFloat(me.nCurrentMana / me.nMaxMana * 100).."%)"..tostring(me.nCurrentMana))
		MY_ArchHUD.MyMana:SetPercentage(me.nCurrentMana/me.nMaxMana)
	end
end
function MY_ArchHUD.UpdateTargetData()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local dwType, dwID = hPlayer.GetTarget()
	if dwID == hPlayer.dwID then
		return
	end
	local target = nil
	local szLife = ""
	if MY_ArchHUD.bOn == false
	or (MY_ArchHUD.bFightShow == true and hPlayer.bFightState == false) then
		MY_ArchHUD.HideTargetFrame()
	else
		MY_ArchHUD.ShowTargetFrame()
		if dwType == TARGET.PLAYER then
			target = GetPlayer(dwID)
		elseif dwType == TARGET.NPC then
			target = GetNpc(dwID)
		else
			return
		end
		if target.nCurrentLife >= 100000000 then
			szLife = string.format("%.2f", target.nCurrentLife / 100000000) .. _L['One hundred million']
		elseif target.nCurrentLife >= 100000 then
			szLife = string.format("%.2f", target.nCurrentLife / 10000) .. _L['Ten thousand']
		else
			szLife = target.nCurrentLife
		end
		MY_ArchHUD.Text_T_Heath:SetText(""..tostring(szLife).."("..KeepTwoByteFloat(target.nCurrentLife / target.nMaxLife * 100).."%)")
		MY_ArchHUD.TargetHeath:SetPercentage(target.nCurrentLife/target.nMaxLife)
		return szLife
	end
end
function MY_ArchHUD.UpdateCasting()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local dwType, dwID = hPlayer.GetTarget()
	local target = nil
	if dwType == TARGET.PLAYER then
		target = GetPlayer(dwID)
	elseif dwType == TARGET.NPC then
		target = GetNpc(dwID)
	end
	if target then
		local bPrePare, dwSkillID, dwSkillLevel, fCastPercent = target.GetSkillPrepareState()
		if bPrePare then
			local szSkillName = Table_GetSkillName(dwSkillID, dwSkillLevel)
			MY_ArchHUD.TargetCasting:SetPercentage(fCastPercent)
			MY_ArchHUD.Text_T_Cast:SetText(szSkillName)
			if MY_ArchHUD.bShowCastingBar and not MY_ArchHUD.TargetCasting:IsVisible() then
				MY_ArchHUD.TargetCasting:Show()
				MY_ArchHUD.TargetCasting_bg:Show()
				MY_ArchHUD.Text_T_Cast:Show()
			end
			return
		end
	end
	if MY_ArchHUD.TargetCasting:IsVisible() then
		MY_ArchHUD.TargetCasting:Hide()
		MY_ArchHUD.TargetCasting_bg:Hide()
		MY_ArchHUD.Text_T_Cast:Hide()
	end
end
function MY_ArchHUD.UpdateAnchor(frame)
	frame:SetPoint(MY_ArchHUD.DefaultAnchor.s, 0, 0, MY_ArchHUD.DefaultAnchor.r, MY_ArchHUD.DefaultAnchor.x, MY_ArchHUD.DefaultAnchor.y)
	frame:CorrectPos()
end

Wnd.OpenWindow(INI_PATH, "MY_ArchHUD")

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
			MY_ArchHUD.UpdatePlayerData()
			MY_ArchHUD.UpdateTargetData()
		end,
	})
	y = y + 45
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = 200,
		text = _L['hide when unfight'],
		checked = MY_ArchHUD.bFightShow,
		oncheck = function(bCheck)
			MY_ArchHUD.bFightShow = bCheck
			MY_ArchHUD.UpdatePlayerData()
			MY_ArchHUD.UpdateTargetData()
		end,
	})
	y = y + 45
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = 200,
		text = _L['display target casting'],
		checked = MY_ArchHUD.bShowCastingBar,
		oncheck = function(bCheck)
			MY_ArchHUD.bShowCastingBar = bCheck
		end,
	})
	y = y + 45
	
	ui:append("WndSliderBox", {
		x = x, y = y, w = 200,
		text = _L('current alpha is %d%%.', MY_ArchHUD.nAlpha),
		textfmt = function(val) return _L("current alpha is %d%%.", val) end,
		range = {0, 100},
		value = MY_ArchHUD.nAlpha,
		onchange = function(val)
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
