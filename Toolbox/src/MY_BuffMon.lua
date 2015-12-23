---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Toolbox/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "Toolbox/ui/MY_BuffMon.%d.ini"
local DEFAULT_S_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "Toolbox/data/buffmon/self/$lang.jx3dat"
local DEFAULT_T_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "Toolbox/data/buffmon/target/$lang.jx3dat"
local STYLE_COUNT = 2
MY_BuffMonS = {}
MY_BuffMonS.anchor = { y = 152, x = -343, s = "TOPLEFT", r = "CENTER" }
MY_BuffMonS.nStyle = 1
MY_BuffMonS.fScale = 0.8
MY_BuffMonS.bEnable = false
MY_BuffMonS.bDragable = false
MY_BuffMonS.nBoxBgFrame = 43
MY_BuffMonS.bHideOthers = true
MY_BuffMonS.nMaxLineCount = 16
RegisterCustomData("MY_BuffMonS.anchor")
RegisterCustomData("MY_BuffMonS.nStyle")
RegisterCustomData("MY_BuffMonS.fScale")
RegisterCustomData("MY_BuffMonS.bEnable")
RegisterCustomData("MY_BuffMonS.bDragable")
RegisterCustomData("MY_BuffMonS.bHideOthers")
RegisterCustomData("MY_BuffMonS.nMaxLineCount")
RegisterCustomData("MY_BuffMonS.tBuffList")
MY_BuffMonT = {}
MY_BuffMonT.anchor = { y = 102, x = -343, s = "TOPLEFT", r = "CENTER" }
MY_BuffMonT.nStyle = 1
MY_BuffMonT.fScale = 0.8
MY_BuffMonT.bEnable = false
MY_BuffMonT.bDragable = false
MY_BuffMonT.nBoxBgFrame = 44
MY_BuffMonT.bHideOthers = true
MY_BuffMonT.nMaxLineCount = 16
RegisterCustomData("MY_BuffMonT.anchor")
RegisterCustomData("MY_BuffMonT.nStyle")
RegisterCustomData("MY_BuffMonT.fScale")
RegisterCustomData("MY_BuffMonT.bEnable")
RegisterCustomData("MY_BuffMonT.bDragable")
RegisterCustomData("MY_BuffMonT.bHideOthers")
RegisterCustomData("MY_BuffMonT.nMaxLineCount")
RegisterCustomData("MY_BuffMonT.tBuffList")

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local function RedrawBuffList(hFrame, aBuffMon, nBgFrame, nStyle)
	hFrame.tItem = {}
	local nWidth = 0
	local hList = hFrame:Lookup("", "Handle_BuffList")
	hList:Clear()
	local nCount = 0
	for _, mon in ipairs(aBuffMon) do
		if mon[1] then
			nCount = nCount + 1
			local hItem = hList:AppendItemFromIni(INI_PATH:format(nStyle), "Handle_Item")
			hItem:Lookup("Image_BoxBg"):SetFrame(nBgFrame)
			local hBox  = hItem:Lookup("Box_Default")
			local hProcessTxt = hItem:Lookup("Text_Process")
			local hProcessImg = hItem:Lookup("Image_Process")
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
			if hProcessTxt then
				hProcessTxt:SetText("")
			end
			if hProcessImg then
				hProcessImg:SetPercentage(0)
			end
			if nCount <= MY_BuffMonT.nMaxLineCount then
				nWidth = nWidth + hItem:GetW() * hFrame.fScale
			end
			hItem:Scale(hFrame.fScale, hFrame.fScale)
		end
	end
	hList:SetW(nWidth)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	local nW, nH = hList:GetSize()
	nW = math.max(nW, 50 * hFrame.fScale)
	nH = math.max(nH, 50 * hFrame.fScale)
	hFrame:SetSize(nW, nH)
	hFrame:SetDragArea(0, 0, nW, nH)
end

local function UpdateBuffList(hFrame, KTarget, bTargetNotChanged, bHideOthers)
	local hList = hFrame:Lookup("", "Handle_BuffList")
	if not KTarget then
		for i = 0, hList:GetItemCount() - 1 do
			local hItem = hList:Lookup(i)
			local hBox = hItem:Lookup("Box_Default")
			hBox:SetCoolDownPercentage(0)
			hBox:SetObjectStaring(false)
			hBox:SetOverText(0, "")
			hBox:SetOverText(1, "")
			hBox:ClearExtentAnimate()
			local hProcessTxt = hItem:Lookup("Text_Process")
			if hProcessTxt then
				hProcessTxt:SetText("")
			end
			local hProcessImg = hItem:Lookup("Image_Process")
			if hProcessImg then
				hProcessImg:SetPercentage(0)
			end
		end
	else
		local nCurrentFrame = GetLogicFrameCount()
		for _, buff in ipairs(MY.Player.GetBuffList(KTarget)) do
			if not bHideOthers or buff.dwSkillSrcID == UI_GetClientPlayerID() then
				local szName = Table_GetBuffName(buff.dwID, buff.nLevel)
				local hItem = hFrame.tItem[szName]
				if hItem then
					local hBox = hItem:Lookup("Box_Default")
					local hProcessTxt = hItem:Lookup("Text_Process")
					local hProcessImg = hItem:Lookup("Image_Process")
					local nBuffTime, _ = GetBuffTime(buff.dwID, buff.nLevel)
					local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - GetLogicFrameCount()) / 16)
					if not hItem.dwIcon or hItem.dwIcon == 13 then
						hItem.dwIcon = Table_GetBuffIconID(buff.dwID, buff.nLevel)
						hBox:SetObjectIcon(hItem.dwIcon)
						hItem.mon[2] = hItem.dwIcon
					end
					if hProcessTxt then
						hProcessTxt:SetText(nTimeLeft .. "'")
					end
					hBox:SetOverText(1, nTimeLeft .. "'")

					if buff.nStackNum == 1 then
						hBox:SetOverText(0, "")
					else
						hBox:SetOverText(0, buff.nStackNum)
					end

					local dwPercent = nTimeLeft / (nBuffTime / 16)
					if hProcessImg then
						hProcessImg:SetPercentage(dwPercent)
					end
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
		end
		-- update disappeared buff info
		if bTargetNotChanged then
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
					local hProcessTxt = hItem:Lookup("Text_Process")
					if hProcessTxt then
						hProcessTxt:SetText("")
					end
					local hProcessImg = hItem:Lookup("Image_Process")
					if hProcessImg then
						hProcessImg:SetPercentage(0)
					end
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
					local hProcessTxt = hItem:Lookup("Text_Process")
					if hProcessTxt then
						hProcessTxt:SetText("")
					end
					local hProcessImg = hItem:Lookup("Image_Process")
					if hProcessImg then
						hProcessImg:SetPercentage(0)
					end
					hItem.nRenderFrame = nil
				end
			end
		end
	end
end

local function GeneNameSpace(OBJ, NAMESPACE, DEFAULT_CONFIG_FILE, GetTarget, LANG)
	function OBJ.AddBuff(dwKungFuID, szBuffName)
		OBJ.GetBuffList(dwKungFuID)
		if not OBJ.tBuffList[dwKungFuID] then
			OBJ.tBuffList[dwKungFuID] = {}
		end
		for _, mon in ipairs(OBJ.tBuffList[dwKungFuID]) do
			if mon[3] == szBuffName then
				return
			end
		end
		table.insert(OBJ.tBuffList[dwKungFuID], {true, 13, szBuffName})
		OBJ.Reload()
	end

	function OBJ.DelBuff(dwKungFuID, szBuffName)
		if OBJ.GetBuffList(dwKungFuID) then
			for i, mon in ipairs(OBJ.tBuffList[dwKungFuID]) do
				if mon[3] == szBuffName then
					table.remove(OBJ.tBuffList[dwKungFuID], i)
					return OBJ.Reload()
				end
			end
		end
	end

	function OBJ.EnableBuff(dwKungFuID, szBuffName, bEnable)
		if OBJ.GetBuffList(dwKungFuID) then
			for i, mon in ipairs(OBJ.tBuffList[dwKungFuID]) do
				if mon[3] == szBuffName then
					mon[1] = bEnable
					return OBJ.Reload()
				end
			end
		end
	end

	function OBJ.GetBuffList(dwKungFuID)
		if not OBJ.tBuffList then
			OBJ.tBuffList = MY.LoadLUAData(DEFAULT_CONFIG_FILE)
		end
		return OBJ.tBuffList[dwKungFuID]
	end

	function OBJ.RedrawBuffList(hFrame)
		local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
		RedrawBuffList(hFrame, OBJ.GetBuffList(dwKungFuID) or EMPTY_TABLE, OBJ.nBoxBgFrame, OBJ.nStyle)
		this:SetPoint(OBJ.anchor.s, 0, 0, OBJ.anchor.r, OBJ.anchor.x, OBJ.anchor.y)
		this:CorrectPos()
	end

	function OBJ.OnFrameCreate()
		this.fScale = OBJ.fScale
		this:Scale(OBJ.fScale, OBJ.fScale)
		this:RegisterEvent("SKILL_MOUNT_KUNG_FU")
		this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
		this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
		this:EnableDrag(OBJ.bDragable)
		this:SetMousePenetrable(not OBJ.bDragable)
		OBJ.RedrawBuffList(this)
	end

	function OBJ.OnFrameBreathe()
		local dwType, dwID = GetTarget()
		if dwType ~= this.dwType or dwID ~= this.dwID
		or dwType == TARGET.PLAYER or dwType == TARGET.NPC then
			UpdateBuffList(this, MY.GetObject(dwType, dwID), dwType == this.dwType and dwID == this.dwID, OBJ.bHideOthers)
			this.dwType, this.dwID = dwType, dwID
		end
	end

	function OBJ.OnFrameDragEnd()
		OBJ.anchor = GetFrameAnchor(this, "TOPLEFT")
	end

	function OBJ.OnEvent(event)
		if event == "SKILL_MOUNT_KUNG_FU" then
			OBJ.RedrawBuffList(this)
		elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
			UpdateCustomModeWindow(this, LANG.CMTEXT, not OBJ.bDragable)
		elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
			UpdateCustomModeWindow(this, LANG.CMTEXT, not OBJ.bDragable)
			if OBJ.bDragable then
				this:EnableDrag(true)
			end
			OBJ.anchor = GetFrameAnchor(this, "TOPLEFT")
		end
	end

	function OBJ.Open()
		Wnd.OpenWindow(INI_PATH:format(OBJ.nStyle), NAMESPACE)
	end

	function OBJ.Close()
		Wnd.CloseWindow(NAMESPACE)
	end

	function OBJ.Reload()
		OBJ.Close()
		if OBJ.bEnable then
			OBJ.Open()
		end
	end
end

----------------------------------------------------------------------------------------------
-- 目标监控
----------------------------------------------------------------------------------------------
GeneNameSpace(MY_BuffMonT, "MY_BuffMonT", DEFAULT_T_CONFIG_FILE,
function() return MY.GetTarget() end, {CMTEXT = _L["mingyi self buff monitor"]})

----------------------------------------------------------------------------------------------
-- 自身监控
----------------------------------------------------------------------------------------------
GeneNameSpace(MY_BuffMonS, "MY_BuffMonS", DEFAULT_S_CONFIG_FILE,
function() return TARGET.PLAYER, UI_GetClientPlayerID() end, {CMTEXT = _L["mingyi target buff monitor"]})

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


local function GenePS(ui, OBJ, x, y, w, h)
	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['enable'],
		checked = OBJ.bEnable,
		oncheck = function(bChecked)
			OBJ.bEnable = bChecked
			OBJ.Reload()
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 150, y = y, w = 100,
		text = _L['undragable'],
		checked = not OBJ.bDragable,
		oncheck = function(bChecked)
			OBJ.bDragable = not bChecked
			OBJ.Reload()
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y, w = 160,
		text = _L['set buff monitor'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {{
				szOption = _L['add'],
				fnAction = function()
					GetUserInput(_L['please input buff name:'], function(szVal)
						szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
						if szVal ~= "" then
							OBJ.AddBuff(dwKungFuID, szVal)
						end
					end, function() end, function() end, nil, "" )
				end,
			}}
			local tBuffMonList = OBJ.GetBuffList(dwKungFuID)
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					table.insert(t, {
						szOption = mon[3],
						bCheck = true, bChecked = mon[1],
						fnAction = function(bChecked)
							OBJ.EnableBuff(dwKungFuID, mon[3], not mon[1])
						end,
						szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
						nFrame = 49,
						nMouseOverFrame = 51,
						nIconWidth = 17,
						nIconHeight = 17,
						szLayer = "ICON_RIGHTMOST",
						fnClickIcon = function()
							OBJ.DelBuff(dwKungFuID, mon[3])
							Wnd.CloseWindow("PopupMenuPanel")
						end,
					})
				end
			end
			return t
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 200,
		text = _L['hide others buff'],
		checked = OBJ.bHideOthers,
		oncheck = function(bChecked)
			OBJ.bHideOthers = bChecked
			OBJ.Reload()
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = OBJ.nMaxLineCount,
		textfmt = function(val) return _L("display %d eachline.", val) end,
		onchange = function(raw, val)
			OBJ.nMaxLineCount = val
			OBJ.Reload()
		end,
	})
	y = y + 30
	
	ui:append("WndComboBox", {
		x = x + 20, y = y, w = 120,
		text = _L['select style'],
		menu = function()
			local t = {}
			for i = 1, STYLE_COUNT do
				table.insert(t, {
					szOption = i,
					fnAction = function()
						OBJ.nStyle = i
						OBJ.Reload()
					end,
					rgb = OBJ.nStyle == i and {0, 255, 0},
				})
			end
			return t
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = OBJ.fScale * 100,
		textfmt = function(val) return _L("scale %d%%.", val) end,
		onchange = function(raw, val)
			OBJ.fScale = val / 100
			OBJ.Reload()
		end,
	})
	y = y + 30
	
	return x, y
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30
	
	ui:append("Text", { x = x, y = y, r = 255, g = 255, b = 0, text = _L['* self buff monitor'] })
	y = y + 30

	x, y = GenePS(ui, MY_BuffMonS, x, y, w, h)
	y = y + 30
	
	ui:append("Text", { x = x, y = y, r = 255, g = 255, b = 0, text = _L['* target buff monitor'] })
	y = y + 30
	
	x, y = GenePS(ui, MY_BuffMonT, x, y, w, h)
end
MY.RegisterPanel("MY_BuffMon", _L["buff monitor"], _L['General'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)
