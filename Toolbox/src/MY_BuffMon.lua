---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Toolbox/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "Toolbox/ui/MY_BuffMon.%d.ini"
local DEFAULT_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "Toolbox/data/buffmon/$lang.jx3dat"
local STYLE_COUNT = 2
MY_BuffMonS = {}
MY_BuffMonS.anchor = { y = 152, x = -343, s = "TOPLEFT", r = "CENTER" }
MY_BuffMonS.nStyle = 1
MY_BuffMonS.fScale = 0.8
MY_BuffMonS.bEnable = false
MY_BuffMonS.bDragable = false
MY_BuffMonS.nMaxLineCount = 16
RegisterCustomData("MY_BuffMonS.anchor")
RegisterCustomData("MY_BuffMonS.nStyle")
RegisterCustomData("MY_BuffMonS.fScale")
RegisterCustomData("MY_BuffMonS.bEnable")
RegisterCustomData("MY_BuffMonS.bDragable")
RegisterCustomData("MY_BuffMonS.nMaxLineCount")
RegisterCustomData("MY_BuffMonS.tBuffList")
MY_BuffMonT = {}
MY_BuffMonT.anchor = { y = 102, x = -343, s = "TOPLEFT", r = "CENTER" }
MY_BuffMonT.nStyle = 1
MY_BuffMonT.fScale = 0.8
MY_BuffMonT.bEnable = false
MY_BuffMonT.bDragable = false
MY_BuffMonT.nMaxLineCount = 16
RegisterCustomData("MY_BuffMonT.anchor")
RegisterCustomData("MY_BuffMonT.nStyle")
RegisterCustomData("MY_BuffMonT.fScale")
RegisterCustomData("MY_BuffMonT.bEnable")
RegisterCustomData("MY_BuffMonT.bDragable")
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

local function UpdateBuffList(hFrame, KTarget, bTargetNotChanged)
	local hList = hFrame:Lookup("", "Handle_BuffList")
	if not KTarget then
		for i = 0, hList:GetItemCount() - 1 do
			local hItem = hList:Lookup(i)
			local hBox = hItem:Lookup("Box_Default")
			hBox:SetCoolDownPercentage(0)
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
		end
	else
		local nCurrentFrame = GetLogicFrameCount()
		for _, buff in ipairs(MY.Player.GetBuffList(KTarget)) do
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
	RedrawBuffList(hFrame, MY_BuffMonT.GetBuffList(dwKungFuID) or EMPTY_TABLE, 44, MY_BuffMonT.nStyle)
	this:SetPoint(MY_BuffMonT.anchor.s, 0, 0, MY_BuffMonT.anchor.r, MY_BuffMonT.anchor.x, MY_BuffMonT.anchor.y)
	this:CorrectPos()
end

function MY_BuffMonT.OnFrameCreate()
	this.fScale = MY_BuffMonT.fScale
	this:Scale(MY_BuffMonT.fScale, MY_BuffMonT.fScale)
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
	Wnd.OpenWindow(INI_PATH:format(MY_BuffMonT.nStyle), "MY_BuffMonT")
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
	RedrawBuffList(hFrame, MY_BuffMonS.GetBuffList(dwKungFuID) or EMPTY_TABLE, 43, MY_BuffMonS.nStyle)
	this:SetPoint(MY_BuffMonS.anchor.s, 0, 0, MY_BuffMonS.anchor.r, MY_BuffMonS.anchor.x, MY_BuffMonS.anchor.y)
	this:CorrectPos()
end

function MY_BuffMonS.OnFrameCreate()
	this.fScale = MY_BuffMonS.fScale
	this:Scale(MY_BuffMonS.fScale, MY_BuffMonS.fScale)
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
	Wnd.OpenWindow(INI_PATH:format(MY_BuffMonS.nStyle), "MY_BuffMonS")
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


local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30
	
	ui:append("Text", { x = x, y = y, r = 255, g = 255, b = 0, text = _L['* self buff monitor'] })
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['enable'],
		checked = MY_BuffMonS.bEnable,
		oncheck = function(bChecked)
			MY_BuffMonS.bEnable = bChecked
			MY_BuffMonS.Reload()
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y,
		text = _L['set self buff monitor'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {{
				szOption = _L['add'],
				fnAction = function()
					GetUserInput(_L['please input buff name:'], function(szVal)
						szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
						if szVal ~= "" then
							MY_BuffMonS.AddBuff(dwKungFuID, szVal)
						end
					end, function() end, function() end, nil, "" )
				end,
			}}
			local tBuffMonList = MY_BuffMonS.GetBuffList(dwKungFuID)
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					table.insert(t, {
						szOption = mon[3],
						bCheck = true, bChecked = mon[1],
						fnAction = function(bChecked)
							MY_BuffMonS.EnableBuff(dwKungFuID, mon[3], not mon[1])
						end,
						szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
						nFrame = 49,
						nMouseOverFrame = 51,
						nIconWidth = 17,
						nIconHeight = 17,
						szLayer = "ICON_RIGHTMOST",
						fnClickIcon = function()
							MY_BuffMonS.DelBuff(dwKungFuID, mon[3])
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
		x = x + 20, y = y, w = 100,
		text = _L['undragable'],
		checked = not MY_BuffMonS.bDragable,
		oncheck = function(bChecked)
			MY_BuffMonS.bDragable = not bChecked
			MY_BuffMonS.Reload()
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = MY_BuffMonS.nMaxLineCount,
		textfmt = function(val) return _L("display %d eachline.", val) end,
		onchange = function(raw, val)
			MY_BuffMonS.nMaxLineCount = val
			MY_BuffMonS.Reload()
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
						MY_BuffMonS.nStyle = i
						MY_BuffMonS.Reload()
					end,
					rgb = MY_BuffMonS.nStyle == i and {0, 255, 0},
				})
			end
			return t
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = MY_BuffMonS.fScale * 100,
		textfmt = function(val) return _L("scale %d%%.", val) end,
		onchange = function(raw, val)
			MY_BuffMonS.fScale = val / 100
			MY_BuffMonS.Reload()
		end,
	})
	y = y + 30

	y = y + 30
	
	ui:append("Text", { x = x, y = y, r = 255, g = 255, b = 0, text = _L['* target buff monitor'] })
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['enable'],
		checked = MY_BuffMonT.bEnable,
		oncheck = function(bChecked)
			MY_BuffMonT.bEnable = bChecked
			MY_BuffMonT.Reload()
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y,
		text = _L['set target buff monitor'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {{
				szOption = _L['add'],
				fnAction = function()
					GetUserInput(_L['please input buff name:'], function(szVal)
						szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
						if szVal ~= "" then
							MY_BuffMonT.AddBuff(dwKungFuID, szVal)
						end
					end, function() end, function() end, nil, "" )
				end,
			}}
			local tBuffMonList = MY_BuffMonT.GetBuffList(dwKungFuID)
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					table.insert(t, {
						szOption = mon[3],
						bCheck = true, bChecked = mon[1],
						fnAction = function(bChecked)
							MY_BuffMonT.EnableBuff(dwKungFuID, mon[3], not mon[1])
						end,
						szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
						nFrame = 49,
						nMouseOverFrame = 51,
						nIconWidth = 17,
						nIconHeight = 17,
						szLayer = "ICON_RIGHTMOST",
						fnClickIcon = function()
							MY_BuffMonT.DelBuff(dwKungFuID, mon[3])
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
		x = x + 20, y = y, w = 100,
		text = _L['undragable'],
		checked = not MY_BuffMonS.bDragable,
		oncheck = function(bChecked)
			MY_BuffMonT.bDragable = not bChecked
			MY_BuffMonT.Reload()
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = MY_BuffMonT.nMaxLineCount,
		textfmt = function(val) return _L("display %d eachline.", val) end,
		onchange = function(raw, val)
			MY_BuffMonT.nMaxLineCount = val
			MY_BuffMonT.Reload()
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
						MY_BuffMonT.nStyle = i
						MY_BuffMonT.Reload()
					end,
					rgb = MY_BuffMonT.nStyle == i and {0, 255, 0},
				})
			end
			return t
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = MY_BuffMonT.fScale * 100,
		textfmt = function(val) return _L("scale %d%%.", val) end,
		onchange = function(raw, val)
			MY_BuffMonT.fScale = val / 100
			MY_BuffMonT.Reload()
		end,
	})
	y = y + 30
end
MY.RegisterPanel("MY_BuffMon", _L["buff monitor"], _L['General'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)
