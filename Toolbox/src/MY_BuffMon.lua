---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Toolbox/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "Toolbox/ui/MY_BuffMon.ini"
local DEFAULT_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "Toolbox/data/buffmon/$lang.jx3dat"
MY_BuffMonS = {}
MY_BuffMonS.anchor = { y = 152, x = -343, s = "TOPLEFT", r = "CENTER" }
MY_BuffMonS.bEnable = false
MY_BuffMonS.bDragable = false
MY_BuffMonS.nMaxLineCount = 16
RegisterCustomData("MY_BuffMonS.anchor")
RegisterCustomData("MY_BuffMonS.bEnable")
RegisterCustomData("MY_BuffMonS.bDragable")
RegisterCustomData("MY_BuffMonS.nMaxLineCount")
RegisterCustomData("MY_BuffMonS.tBuffList")
MY_BuffMonT = {}
MY_BuffMonT.anchor = { y = 102, x = -343, s = "TOPLEFT", r = "CENTER" }
MY_BuffMonT.bEnable = false
MY_BuffMonT.bDragable = false
MY_BuffMonT.nMaxLineCount = 16
RegisterCustomData("MY_BuffMonT.anchor")
RegisterCustomData("MY_BuffMonT.bEnable")
RegisterCustomData("MY_BuffMonT.bDragable")
RegisterCustomData("MY_BuffMonT.nMaxLineCount")
RegisterCustomData("MY_BuffMonT.tBuffList")

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local function RedrawBuffList(hFrame, aBuffMon, nBgFrame)
	hFrame.tItem = {}
	local nWidth = 0
	local hList = hFrame:Lookup("", "Handle_BuffList")
	hList:Clear()
	local nCount = 0
	for _, mon in ipairs(aBuffMon) do
		if mon[1] then
			nCount = nCount + 1
			local hItem = hList:AppendItemFromIni(INI_PATH, "Handle_Item")
			hItem:Lookup("Image_BoxBg"):SetFrame(nBgFrame)
			local hBox  = hItem:Lookup("Box_Default")
			hItem.mon = mon
			hItem.dwIcon = mon[2]
			hFrame.tItem[mon[3]] = hItem
			hBox:SetObject(UI_OBJECT.BUFF, mon[2], 1, 1)
			hBox:SetObjectIcon(hItem.dwIcon or -1)
			hBox:SetObjectCoolDown(true)
			hBox:SetCoolDownPercentage(0)
			-- BUFF时间
			hBox:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
			hBox:SetOverTextFontScheme(1, 15)
			-- BUFF层数
			hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
			hBox:SetOverTextFontScheme(0, 15)
			if nCount <= MY_BuffMonT.nMaxLineCount then
				nWidth = nWidth + hItem:GetW()
			end
		end
	end
	hList:SetW(nWidth)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	local nW, nH = hList:GetSize()
	nW, nH = math.max(nW, 50), math.max(nH, 50)
	hFrame:SetSize(nW, nH)
	hFrame:SetDragArea(0, 0, nW, nH)
end

local function UpdateBuffList(hFrame, KTarget, bTargetNotChanged)
	local hList = hFrame:Lookup("", "Handle_BuffList")
	if not KTarget then
		for i = 0, hList:GetItemCount() - 1 do
			local hBox = hList:Lookup(i):Lookup("Box_Default")
			hBox:SetCoolDownPercentage(0)
			hBox:SetObjectStaring(false)
			hBox:ClearExtentAnimate()
		end
	else
		local nCurrentFrame = GetLogicFrameCount()
		for _, buff in ipairs(MY.Player.GetBuffList(KTarget)) do
			local szName = Table_GetBuffName(buff.dwID, buff.nLevel)
			local hItem = hFrame.tItem[szName]
			if hItem then
				local hBox = hItem:Lookup("Box_Default")
				local nBuffTime, _ = GetBuffTime(buff.dwID, buff.nLevel)
				local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - GetLogicFrameCount()) / 16)
				if not hItem.dwIcon or hItem.dwIcon == 13 then
					hItem.dwIcon = Table_GetBuffIconID(buff.dwID, buff.nLevel)
					hBox:SetObjectIcon(hItem.dwIcon)
					hItem.mon[2] = hItem.dwIcon
				end
				hBox:SetOverText(1, " " .. nTimeLeft .. "'")

				if buff.nStackNum == 1 then
					hBox:SetOverText(0, "")
				else
					hBox:SetOverText(0, buff.nStackNum)
				end

				local dwPercent = nTimeLeft / (nBuffTime / 16)
				hBox:SetCoolDownPercentage(1 - dwPercent)

				if dwPercent < 0.5 and dwPercent > 0.3 then
					if hBox.dwPercent ~= 0.5 then
						hBox.dwPercent = 0.5
						hBox:SetObjectStaring(true)
					end
				elseif dwPercent < 0.3 and dwPercent > 0.1 then
					if hBox.dwPercent ~= 0.3 then
						hBox.dwPercent = 0.3
						hBox:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 17)
					end
				elseif dwPercent < 0.1 then
					if hBox.dwPercent ~= 0.1 then
						hBox.dwPercent = 0.1
						hBox:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 20)
					end
				else
					hBox:SetObjectStaring(false)
					hBox:ClearExtentAnimate()
				end
				hItem.nRenderFrame = nCurrentFrame
			end
		end
		-- update disappeared buff info
		if KTarget and bTargetNotChanged then
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				if hItem.nRenderFrame and hItem.nRenderFrame >= 0
				and hItem.nRenderFrame ~= nCurrentFrame then
					local hBox = hItem:Lookup("Box_Default")
					hBox.dwPercent = 0
					hBox:SetCoolDownPercentage(0)
					hBox:SetOverText(0, "")
					hBox:SetOverText(1, "")
					hBox:SetObjectStaring(false)
					hBox:ClearExtentAnimate()
					hBox:SetObjectSparking(true)
					hItem.nRenderFrame = nil
				end
			end
		else
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				if hItem.nRenderFrame and hItem.nRenderFrame >= 0
				and hItem.nRenderFrame ~= nCurrentFrame then
					local hBox = hItem:Lookup("Box_Default")
					hBox.dwPercent = 0
					hBox:SetCoolDownPercentage(0)
					hBox:SetOverText(0, "")
					hBox:SetOverText(1, "")
					hBox:SetObjectStaring(false)
					hBox:ClearExtentAnimate()
					hItem.nRenderFrame = nil
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------
-- 目标监控
----------------------------------------------------------------------------------------------
function MY_BuffMonT.AddBuff(dwKungFuID, szBuffName)
	MY_BuffMonT.GetBuffList(dwKungFuID)
	if not MY_BuffMonT.tBuffList[dwKungFuID] then
		MY_BuffMonT.tBuffList[dwKungFuID] = {}
	end
	for _, mon in ipairs(MY_BuffMonT.tBuffList[dwKungFuID]) do
		if mon[3] == szBuffName then
			return
		end
	end
	table.insert(MY_BuffMonT.tBuffList[dwKungFuID], {true, 13, szBuffName})
	MY_BuffMonT.Reload()
end

function MY_BuffMonT.DelBuff(dwKungFuID, szBuffName)
	if MY_BuffMonT.GetBuffList(dwKungFuID) then
		for i, mon in ipairs(MY_BuffMonT.tBuffList[dwKungFuID]) do
			if mon[3] == szBuffName then
				table.remove(MY_BuffMonT.tBuffList[dwKungFuID], i)
				return MY_BuffMonT.Reload()
			end
		end
	end
end

function MY_BuffMonT.EnableBuff(dwKungFuID, szBuffName, bEnable)
	if MY_BuffMonT.GetBuffList(dwKungFuID) then
		for i, mon in ipairs(MY_BuffMonT.tBuffList[dwKungFuID]) do
			if mon[3] == szBuffName then
				mon[1] = bEnable
				return MY_BuffMonT.Reload()
			end
		end
	end
end

function MY_BuffMonT.GetBuffList(dwKungFuID)
	if not MY_BuffMonT.tBuffList then
		MY_BuffMonT.tBuffList = MY.LoadLUAData(DEFAULT_CONFIG_FILE)[2]
	end
	return MY_BuffMonT.tBuffList[dwKungFuID]
end

function MY_BuffMonT.RedrawBuffList(hFrame)
	local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
	RedrawBuffList(hFrame, MY_BuffMonT.GetBuffList(dwKungFuID) or EMPTY_TABLE, 44)
	this:SetPoint(MY_BuffMonT.anchor.s, 0, 0, MY_BuffMonT.anchor.r, MY_BuffMonT.anchor.x, MY_BuffMonT.anchor.y)
	this:CorrectPos()
end

function MY_BuffMonT.OnFrameCreate()
	this:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:EnableDrag(MY_BuffMonT.bDragable)
	this:SetMousePenetrable(not MY_BuffMonT.bDragable)
	MY_BuffMonT.RedrawBuffList(this)
end

function MY_BuffMonT.OnFrameBreathe()
	local dwType, dwID = MY.GetTarget()
	if dwType ~= this.dwType or dwID ~= this.dwID
	or dwType == TARGET.PLAYER or dwType == TARGET.NPC then
		UpdateBuffList(this, MY.GetObject(dwType, dwID), dwType == this.dwType and dwID == this.dwID)
		this.dwType, this.dwID = dwType, dwID
	end
end

function MY_BuffMonT.OnFrameDragEnd()
	MY_BuffMonT.anchor = GetFrameAnchor(this, "TOPLEFT")
end

function MY_BuffMonT.OnEvent(event)
	if event == "SKILL_MOUNT_KUNG_FU" then
		MY_BuffMonT.RedrawBuffList(this)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, _L["mingyi self buff monitor"], not MY_BuffMonT.bDragable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, _L["mingyi self buff monitor"], not MY_BuffMonT.bDragable)
		if MY_BuffMonT.bDragable then
			this:EnableDrag(true)
		end
		MY_BuffMonT.anchor = GetFrameAnchor(this, "TOPLEFT")
	end
end

function MY_BuffMonT.Open()
	Wnd.OpenWindow(INI_PATH, "MY_BuffMonT")
end

function MY_BuffMonT.Close()
	Wnd.CloseWindow("MY_BuffMonT")
end

function MY_BuffMonT.Reload()
	MY_BuffMonT.Close()
	if MY_BuffMonT.bEnable then
		MY_BuffMonT.Open()
	end
end

----------------------------------------------------------------------------------------------
-- 自身监控
----------------------------------------------------------------------------------------------
function MY_BuffMonS.AddBuff(dwKungFuID, szBuffName)
	MY_BuffMonS.GetBuffList(dwKungFuID)
	if not MY_BuffMonS.tBuffList[dwKungFuID] then
		MY_BuffMonS.tBuffList[dwKungFuID] = {}
	end
	for _, mon in ipairs(MY_BuffMonS.tBuffList[dwKungFuID]) do
		if mon[3] == szBuffName then
			return
		end
	end
	table.insert(MY_BuffMonS.tBuffList[dwKungFuID], {true, 13, szBuffName})
	MY_BuffMonS.Reload()
end

function MY_BuffMonS.DelBuff(dwKungFuID, szBuffName)
	if MY_BuffMonS.GetBuffList(dwKungFuID) then
		for i, mon in ipairs(MY_BuffMonS.tBuffList[dwKungFuID]) do
			if mon[3] == szBuffName then
				table.remove(MY_BuffMonS.tBuffList[dwKungFuID], i)
				return MY_BuffMonS.Reload()
			end
		end
	end
end

function MY_BuffMonS.EnableBuff(dwKungFuID, szBuffName, bEnable)
	if MY_BuffMonS.GetBuffList(dwKungFuID) then
		for i, mon in ipairs(MY_BuffMonS.tBuffList[dwKungFuID]) do
			if mon[3] == szBuffName then
				mon[1] = bEnable
				return MY_BuffMonS.Reload()
			end
		end
	end
end

function MY_BuffMonS.GetBuffList(dwKungFuID)
	if not MY_BuffMonS.tBuffList then
		MY_BuffMonS.tBuffList = MY.LoadLUAData(DEFAULT_CONFIG_FILE)[1]
	end
	return MY_BuffMonS.tBuffList[dwKungFuID]
end

function MY_BuffMonS.RedrawBuffList(hFrame)
	local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
	RedrawBuffList(hFrame, MY_BuffMonS.GetBuffList(dwKungFuID) or EMPTY_TABLE, 43)
	this:SetPoint(MY_BuffMonS.anchor.s, 0, 0, MY_BuffMonS.anchor.r, MY_BuffMonS.anchor.x, MY_BuffMonS.anchor.y)
	this:CorrectPos()
end

function MY_BuffMonS.OnFrameCreate()
	this:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:EnableDrag(MY_BuffMonS.bDragable)
	this:SetMousePenetrable(not MY_BuffMonS.bDragable)
	MY_BuffMonS.RedrawBuffList(this)
end

function MY_BuffMonS.OnFrameBreathe()
	UpdateBuffList(this, GetClientPlayer(), true)
end

function MY_BuffMonS.OnFrameDragEnd()
	MY_BuffMonS.anchor = GetFrameAnchor(this, "TOPLEFT")
end

function MY_BuffMonS.OnEvent(event)
	if event == "SKILL_MOUNT_KUNG_FU" then
		MY_BuffMonS.RedrawBuffList(this)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, _L["mingyi self buff monitor"], not MY_BuffMonS.bDragable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, _L["mingyi self buff monitor"], not MY_BuffMonS.bDragable)
		if MY_BuffMonS.bDragable then
			this:EnableDrag(true)
		end
		MY_BuffMonS.anchor = GetFrameAnchor(this, "TOPLEFT")
	end
end

function MY_BuffMonS.Open()
	Wnd.OpenWindow(INI_PATH, "MY_BuffMonS")
end

function MY_BuffMonS.Close()
	Wnd.CloseWindow("MY_BuffMonS")
end

function MY_BuffMonS.Reload()
	MY_BuffMonS.Close()
	if MY_BuffMonS.bEnable then
		MY_BuffMonS.Open()
	end
end

----------------------------------------------------------------------------------------------
-- 初始化
----------------------------------------------------------------------------------------------
MY.RegisterInit("MY_BuffMon", function()
	if MY_BuffMonT.bEnable then
		MY_BuffMonT.Open()
	end
	if MY_BuffMonS.bEnable then
		MY_BuffMonS.Open()
	end
end)
