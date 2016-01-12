---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_BuffMon/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_BuffMon/ui/MY_BuffMon.ini"
local DEFAULT_S_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "MY_BuffMon/data/self/$lang.jx3dat"
local DEFAULT_T_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "MY_BuffMon/data/target/$lang.jx3dat"
local CUSTOM_STYLES = {
	MY.GetAddonInfo().szUITexST .. "|" .. 0,
	MY.GetAddonInfo().szUITexST .. "|" .. 1,
	MY.GetAddonInfo().szUITexST .. "|" .. 2,
	MY.GetAddonInfo().szUITexST .. "|" .. 3,
	MY.GetAddonInfo().szUITexST .. "|" .. 4,
	MY.GetAddonInfo().szUITexST .. "|" .. 5,
	MY.GetAddonInfo().szUITexST .. "|" .. 6,
	MY.GetAddonInfo().szUITexST .. "|" .. 7,
	MY.GetAddonInfo().szUITexST .. "|" .. 8,
	"/ui/Image/Common/Money.UITex|168",
	"/ui/Image/Common/Money.UITex|203",
	"/ui/Image/Common/Money.UITex|204",
	"/ui/Image/Common/Money.UITex|205",
	"/ui/Image/Common/Money.UITex|206",
	"/ui/Image/Common/Money.UITex|207",
	"/ui/Image/Common/Money.UITex|208",
	"/ui/Image/Common/Money.UITex|209",
	"/ui/Image/Common/Money.UITex|210",
	"/ui/Image/Common/Money.UITex|211",
	"/ui/Image/Common/Money.UITex|212",
	"/ui/Image/Common/Money.UITex|213",
	"/ui/Image/Common/Money.UITex|214",
	"/ui/Image/Common/Money.UITex|215",
	"/ui/Image/Common/Money.UITex|216",
	"/ui/Image/Common/Money.UITex|217",
	"/ui/Image/Common/Money.UITex|218",
	"/ui/Image/Common/Money.UITex|219",
	"/ui/Image/Common/Money.UITex|220",
	"/ui/Image/Common/Money.UITex|228",
	"/ui/Image/Common/Money.UITex|232",
	"/ui/Image/Common/Money.UITex|233",
	"/ui/Image/Common/Money.UITex|234",
}
local BOX_SPARKING_FRAME = GLOBAL.GAME_FPS

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local function RedrawBuffList(hFrame, aBuffMon, OBJ)
	local nBgFrame = OBJ.nBgFrame
	hFrame.tItem = {}
	local nWidth = 0
	local hList = hFrame:Lookup("", "Handle_BuffList")
	hList:Clear()
	local nCount = 0
	for _, mon in ipairs(aBuffMon) do
		if mon[1] then
			nCount = nCount + 1
			local hItem = hList:AppendItemFromIni(INI_PATH, "Handle_Item")
			local hdlBox = hItem:Lookup("Handle_Box")
			local hdlBar = hItem:Lookup("Handle_Bar")
			local hBox = hdlBox:Lookup("Box_Default")
			local hBoxBg = hdlBox:Lookup("Image_BoxBg")
			local hSkillName = hdlBar:Lookup("Text_Name")
			local hProcessTxt = hdlBar:Lookup("Text_Process")
			local hProcessImg = hdlBar:Lookup("Image_Process")
			
			-- Box部分
			hItem.hBox = hBox
			hItem.mon = mon
			hItem.dwIcon = mon[2]
			hFrame.tItem[mon[3]] = hItem
			hBox:SetObject(UI_OBJECT.BUFF, mon[2], 1, 1)
			hBox:SetObjectIcon(hItem.dwIcon or -1)
			hBox:SetObjectCoolDown(true)
			hBox:SetCoolDownPercentage(0)
			hBoxBg:SetFrame(nBgFrame)
			-- BUFF时间
			hBox:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
			hBox:SetOverTextFontScheme(1, 15)
			-- BUFF层数
			hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
			hBox:SetOverTextFontScheme(0, 15)
			
			-- 倒计时条
			if OBJ.bCDBar then
				hProcessTxt:SetW(OBJ.nCDWidth - 10)
				hProcessTxt:SetText("")
				hItem.hProcessTxt = hProcessTxt
				
				hSkillName:SetVisible(OBJ.bSkillName)
				hSkillName:SetW(OBJ.nCDWidth - 10)
				hSkillName:SetText(mon[3])
				hItem.hSkillName = hSkillName
				
				XGUI(hProcessImg):image(OBJ.szCDUITex)
				hProcessImg:SetW(OBJ.nCDWidth)
				hProcessImg:SetPercentage(0)
				hItem.hProcessImg = hProcessImg
				
				hdlBar:Show()
				hdlBar:SetW(OBJ.nCDWidth)
				hItem.hdlBar = hdlBar
				hItem:SetW(hdlBox:GetW() + OBJ.nCDWidth)
			else
				hdlBar:Hide()
				hItem:SetW(hdlBox:GetW())
			end
			
			if nCount <= OBJ.nMaxLineCount then
				nWidth = nWidth + hItem:GetW() * hFrame.fScale
			end
			hItem:Scale(hFrame.fScale, hFrame.fScale)
			hItem:SetVisible(not OBJ.bHideVoidBuff)
		end
	end
	hList:SetW(nWidth)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	hList:SetIgnoreInvisibleChild(true)
	hList:FormatAllItemPos()
	local nW, nH = hList:GetSize()
	nW = math.max(nW, 50 * hFrame.fScale)
	nH = math.max(nH, 50 * hFrame.fScale)
	hFrame:SetSize(nW, nH)
	hFrame:SetDragArea(0, 0, nW, nH)
end

local _tBuffTime = setmetatable({}, { __mode = "v" })
local _needFormatItemPos
local function UpdateBuffList(hFrame, KTarget, bTargetNotChanged, bHideOthers, bHideVoidBuff)
	local hList = hFrame:Lookup("", "Handle_BuffList")
	if not KTarget then
		for i = 0, hList:GetItemCount() - 1 do
			local hItem = hList:Lookup(i)
			local hBox = hItem:Lookup("Handle_Box/Box_Default")
			hBox:SetCoolDownPercentage(0)
			hBox:SetObjectStaring(false)
			hBox:SetOverText(0, "")
			hBox:SetOverText(1, "")
			hBox:ClearExtentAnimate()
			hItem:Lookup("Handle_Bar/Text_Process"):SetText("")
			hItem:Lookup("Handle_Bar/Image_Process"):SetPercentage(0)
			if bHideVoidBuff and hItem:IsVisible() then
				_needFormatItemPos = true
				hItem:Hide()
			end
		end
	else
		local nCurrentFrame = GetLogicFrameCount()
		for _, buff in ipairs(MY.Player.GetBuffList(KTarget)) do
			if not bHideOthers or buff.dwSkillSrcID == UI_GetClientPlayerID() then
				local szName = Table_GetBuffName(buff.dwID, buff.nLevel)
				local hItem = hFrame.tItem[szName]
				if hItem then
					if bHideVoidBuff and not hItem:IsVisible() then
						_needFormatItemPos = true
						hItem:Show()
					end
					local hBox = hItem.hBox
					-- 计算BUFF时间
					local nBuffTime = GetBuffTime(buff.dwID, buff.nLevel) / 16
					local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - GetLogicFrameCount()) / 16)
					if not _tBuffTime[KTarget.dwID] then
						_tBuffTime[KTarget.dwID] = {}
					end
					nBuffTime = math.max(nBuffTime, nTimeLeft)
					if _tBuffTime[KTarget.dwID][buff.dwID] then
						nBuffTime = math.max(_tBuffTime[KTarget.dwID][buff.dwID], nBuffTime)
					end
					_tBuffTime[KTarget.dwID][buff.dwID] = nBuffTime
					
					if not hItem.dwIcon or hItem.dwIcon == 13 then
						hItem.dwIcon = Table_GetBuffIconID(buff.dwID, buff.nLevel)
						hBox:SetObjectIcon(hItem.dwIcon)
						hItem.mon[2] = hItem.dwIcon
					end
					
					if hItem.hProcessTxt then
						hItem.hProcessTxt:SetText(nTimeLeft .. "'")
					end
					hBox:SetOverText(1, nTimeLeft .. "'")
					
					if buff.nStackNum == 1 then
						hBox:SetOverText(0, "")
					else
						hBox:SetOverText(0, buff.nStackNum)
					end

					local dwPercent = nTimeLeft / nBuffTime
					if hItem.hProcessImg then
						hItem.hProcessImg:SetPercentage(dwPercent)
					end
					hBox:SetCoolDownPercentage(dwPercent)

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
					local hBox = hItem.hBox
					hBox.dwPercent = 0
					hBox:SetCoolDownPercentage(0)
					hBox:SetOverText(0, "")
					hBox:SetOverText(1, "")
					hBox:SetObjectStaring(false)
					hBox:ClearExtentAnimate()
					hBox:SetObjectSparking(true)
					if hItem.hProcessTxt then
						hItem.hProcessTxt:SetText("")
					end
					if hItem.hProcessImg then
						hItem.hProcessImg:SetPercentage(0)
					end
					hItem.nRenderFrame = nil
					hItem.nSparkingFrame = nCurrentFrame
				elseif bHideVoidBuff and hItem:IsVisible()
				and hItem.nSparkingFrame
				and nCurrentFrame - hItem.nSparkingFrame > BOX_SPARKING_FRAME then
					hItem.nSparkingFrame = nil
					_needFormatItemPos = true
					hItem:Hide()
				end
			end
		else
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				if hItem.nRenderFrame and hItem.nRenderFrame >= 0
				and hItem.nRenderFrame ~= nCurrentFrame then
					local hBox = hItem.hBox
					hBox.dwPercent = 0
					hBox:SetCoolDownPercentage(0)
					hBox:SetOverText(0, "")
					hBox:SetOverText(1, "")
					hBox:SetObjectStaring(false)
					hBox:ClearExtentAnimate()
					if hItem.hProcessTxt then
						hItem.hProcessTxt:SetText("")
					end
					if hItem.hProcessImg then
						hItem.hProcessImg:SetPercentage(0)
					end
					if bHideVoidBuff and hItem:IsVisible() then
						_needFormatItemPos = true
						hItem:Hide()
					end
					hItem.nRenderFrame = nil
				end
			end
		end
		if _needFormatItemPos then
			hList:FormatAllItemPos()
		end
	end
end

local function GeneNameSpace(OBJ, NAMESPACE, DEFAULT_CONFIG_FILE, GetTarget, LANG)
	OBJ.fScale        = 0.8    -- 缩放比
	OBJ.bEnable       = false  -- 启用标记
	OBJ.bDragable     = false  -- 是否可拖拽
	OBJ.nBoxBgFrame   = 43     -- Box背景帧
	OBJ.bHideOthers   = true   -- 只显示自己的BUFF
	OBJ.nMaxLineCount = 16     -- 单行最大数量
	OBJ.bHideVoidBuff = false  -- 隐藏消失的BUFF
	OBJ.bCDBar        = false  -- 显示倒计时条
	OBJ.nCDWidth      = 240    -- 倒计时条宽度
	OBJ.szCDUITex     = MY.GetAddonInfo().szUITexST .. "|7"
	OBJ.bSkillName    = true   -- 显示技能名字
	RegisterCustomData(NAMESPACE .. ".fScale")
	RegisterCustomData(NAMESPACE .. ".bEnable")
	RegisterCustomData(NAMESPACE .. ".bDragable")
	RegisterCustomData(NAMESPACE .. ".bHideOthers")
	RegisterCustomData(NAMESPACE .. ".nMaxLineCount")
	RegisterCustomData(NAMESPACE .. ".tBuffList")
	RegisterCustomData(NAMESPACE .. ".bHideVoidBuff")
	RegisterCustomData(NAMESPACE .. ".bCDBar")
	RegisterCustomData(NAMESPACE .. ".nCDWidth")
	RegisterCustomData(NAMESPACE .. ".szCDUITex")
	RegisterCustomData(NAMESPACE .. ".bSkillName")

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
		RedrawBuffList(hFrame, OBJ.GetBuffList(dwKungFuID) or EMPTY_TABLE, OBJ)
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
			UpdateBuffList(this, MY.GetObject(dwType, dwID), dwType == this.dwType and dwID == this.dwID, OBJ.bHideOthers, OBJ.bHideVoidBuff)
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
		Wnd.OpenWindow(INI_PATH, NAMESPACE)
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
MY_BuffMonT = {}
MY_BuffMonT.anchor = { y = 102, x = -343, s = "TOPLEFT", r = "CENTER" }
RegisterCustomData("MY_BuffMonT.anchor")
GeneNameSpace(MY_BuffMonT, "MY_BuffMonT", DEFAULT_T_CONFIG_FILE,
function() return MY.GetTarget() end, {CMTEXT = _L["mingyi target buff monitor"]})

----------------------------------------------------------------------------------------------
-- 自身监控
----------------------------------------------------------------------------------------------
MY_BuffMonS = {}
MY_BuffMonS.anchor = { y = 152, x = -343, s = "TOPLEFT", r = "CENTER" }
RegisterCustomData("MY_BuffMonS.anchor")
GeneNameSpace(MY_BuffMonS, "MY_BuffMonS", DEFAULT_S_CONFIG_FILE,
function() return TARGET.PLAYER, UI_GetClientPlayerID() end, {CMTEXT = _L["mingyi self buff monitor"]})

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
		x = x + 120, y = y, w = 200,
		text = _L['hide others buff'],
		checked = OBJ.bHideOthers,
		oncheck = function(bChecked)
			OBJ.bHideOthers = bChecked
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
		x = x + 20, y = y, w = 100,
		text = _L['undragable'],
		checked = not OBJ.bDragable,
		oncheck = function(bChecked)
			OBJ.bDragable = not bChecked
			OBJ.Reload()
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['hide void buff'],
		checked = OBJ.bHideVoidBuff,
		oncheck = function(bChecked)
			OBJ.bHideVoidBuff = bChecked
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
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 120,
		text = _L['show cd bar'],
		checked = OBJ.bCDBar,
		oncheck = function(bCheck)
			OBJ.bCDBar = bCheck
			OBJ.Reload()
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 120,
		text = _L['show buff name'],
		checked = OBJ.bSkillName,
		oncheck = function(bCheck)
			OBJ.bSkillName = bCheck
			OBJ.Reload()
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
	
	ui:append("WndComboBox", {
		x = 40, y = y, w = w - 250 - 30 - 30,
		text = _L['Select countdown style'],
		menu = function()
			local t, subt = {}
			for _, text in ipairs(CUSTOM_STYLES) do
				subt = {
					szOption = text,
					fnAction = function()
						OBJ.szCDUITex = text
						OBJ.Reload()
					end,
				}
				if text == OBJ.szCDUITex then
					subt.rgb = {255, 255, 0}
				end
				table.insert(t, subt)
			end
			return t
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {50, 1000},
		value = OBJ.nCDWidth,
		textfmt = function(val) return _L("CD width %dpx.", val) end,
		onchange = function(raw, val)
			OBJ.nCDWidth = val
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
MY.RegisterPanel("MY_BuffMon", _L["buff monitor"], _L['Target'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)
