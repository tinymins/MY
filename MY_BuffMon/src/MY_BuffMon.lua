---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_BuffMon/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_BuffMon/ui/MY_BuffMon.ini"
local ROLE_CONFIG_FILE = {'config/my_buffmon.jx3dat', MY_DATA_PATH.ROLE}
local DEFAULT_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "MY_BuffMon/data/$lang.jx3dat"
local CUSTOM_BOXBG_STYLES = {
	"UI/Image/Common/Box.UITex|0",
	"UI/Image/Common/Box.UITex|1",
	"UI/Image/Common/Box.UITex|2",
	"UI/Image/Common/Box.UITex|3",
	"UI/Image/Common/Box.UITex|4",
	"UI/Image/Common/Box.UITex|5",
	"UI/Image/Common/Box.UITex|6",
	"UI/Image/Common/Box.UITex|7",
	"UI/Image/Common/Box.UITex|8",
	"UI/Image/Common/Box.UITex|9",
	"UI/Image/Common/Box.UITex|10",
	"UI/Image/Common/Box.UITex|11",
	"UI/Image/Common/Box.UITex|12",
	"UI/Image/Common/Box.UITex|13",
	"UI/Image/Common/Box.UITex|14",
	"UI/Image/Common/Box.UITex|34",
	"UI/Image/Common/Box.UITex|35",
	"UI/Image/Common/Box.UITex|42",
	"UI/Image/Common/Box.UITex|43",
	"UI/Image/Common/Box.UITex|44",
	"UI/Image/Common/Box.UITex|45",
	"UI/Image/Common/Box.UITex|77",
	"UI/Image/Common/Box.UITex|78",
}
local CUSTOM_CDBAR_STYLES = {
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
local Config = {}
local BOX_SPARKING_FRAME = GLOBAL.GAME_FPS

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local FE = {}

local function ClosePanel(config)
	Wnd.CloseWindow("MY_BuffMon" .. config.uid)
end

local function OpenPanel(config, reload)
	if reload then
		ClosePanel(config)
	end
	if not config.enable then
		return
	end
	local frame = Wnd.OpenWindow(INI_PATH, "MY_BuffMon" .. config.uid)
	local hList = frame:Lookup("", "Handle_BuffList")
	
	hList:Clear()
	frame.tItem = {}
	frame.hList = hList
	frame.config = config
	local nWidth = 0
	local nCount = 0
	local function CreateItem(mon)
		if not mon.enable then
			return
		end
		nCount = nCount + 1
		local hItem        = hList:AppendItemFromIni(INI_PATH, "Handle_Item")
		local hBox         = hItem:Lookup("Handle_Box")
		local hCDBar       = hItem:Lookup("Handle_Bar")
		local box          = hBox:Lookup("Box_Default")
		local imgBoxBg     = hBox:Lookup("Image_BoxBg")
		local txtProcess   = hCDBar:Lookup("Text_Process")
		local imgProcess   = hCDBar:Lookup("Image_Process")
		local txtBuffName  = hCDBar:Lookup("Text_Name")
		
		-- 建立高速索引
		hItem.box = box
		hItem.mon = mon
		hItem.txtProcess = txtProcess
		hItem.imgProcess = imgProcess
		hItem.txtBuffName = txtBuffName
		if mon.buffid and mon.buffid ~= -1 then
			if not frame.tItem[mon.buffid] then
				frame.tItem[mon.buffid] = {}
			end
			frame.tItem[mon.buffid][hItem] = true
		elseif mon.buffname then
			if not frame.tItem[mon.buffname] then
				frame.tItem[mon.buffname] = {}
			end
			frame.tItem[mon.buffname][hItem] = true
		end
		
		-- Box部分
		box:SetObject(UI_OBJECT.BUFF, mon.buffid, 1, 1)
		box:SetObjectIcon(mon.iconid or 13)
		box:SetObjectCoolDown(true)
		box:SetCoolDownPercentage(0)
		-- BUFF时间
		box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
		box:SetOverTextFontScheme(1, 15)
		-- BUFF层数
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		-- Box背景图
		XGUI(imgBoxBg):image(config.boxBgUITex)
		
		-- 倒计时条
		if config.cdBar then
			txtProcess:SetW(config.cdBarWidth - 10)
			txtProcess:SetText("")
			
			txtBuffName:SetVisible(config.showBuffName)
			txtBuffName:SetW(config.cdBarWidth - 10)
			txtBuffName:SetText(mon.buffname or '')
			
			XGUI(imgProcess):image(config.cdBarUITex)
			imgProcess:SetW(config.cdBarWidth)
			imgProcess:SetPercentage(0)
			
			hCDBar:Show()
			hCDBar:SetW(config.cdBarWidth)
			hItem.hCDBar = hCDBar
			hItem:SetW(hBox:GetW() + config.cdBarWidth)
		else
			hCDBar:Hide()
			hItem:SetW(hBox:GetW())
		end
		
		if nCount <= config.maxLineCount then
			nWidth = nWidth + hItem:GetW() * config.scale
		end
		-- hItem:Scale(config.scale, config.scale)
		hItem:SetVisible(not config.hideVoidBuff)
	end
	for _, mon in ipairs(config.monitors.common or EMPTY_TABLE) do
		CreateItem(mon)
	end
	for _, mon in ipairs(config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID] or EMPTY_TABLE) do
		CreateItem(mon)
	end
	hList:SetW(nWidth)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	hList:SetIgnoreInvisibleChild(true)
	hList:FormatAllItemPos()
	
	local nW, nH = hList:GetSize()
	nW = math.max(nW, 50 * config.scale)
	nH = math.max(nH, 50 * config.scale)
	frame:SetSize(nW, nH)
	frame:SetDragArea(0, 0, nW, nH)
	frame:EnableDrag(config.dragable)
	frame:SetMousePenetrable(not config.dragable)
	frame:Scale(config.scale, config.scale)
	frame:SetPoint(config.anchor.s, 0, 0, config.anchor.r, config.anchor.x, config.anchor.y)
	frame:CorrectPos()
	
	for k, v in pairs(FE) do
		frame[k] = v
	end
	frame:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	frame:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	frame:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
end

local function GetTarget(eType)
	if eType == "CLIENT_PLAYER" then
		return TARGET.PLAYER, UI_GetClientPlayerID()
	elseif eType == "CONTROL_PLAYER" then
		return TARGET.PLAYER, GetControlPlayerID()
	elseif eType == "TARGET" then
		return MY.GetTarget()
	elseif eType == "TTARGET" then
		local KTarget = MY.GetObject(MY.GetTarget())
		if KTarget then
			return MY.GetTarget(KTarget)
		else
			return TARGET.NO_TARGET, 0
		end
	end
end

do
local needFormatItemPos
local l_tBuffTime = setmetatable({}, { __mode = "v" })
local function UpdateItem(hItem, KTarget, buff, szBuffName, tItem, config, nFrameCount, targetChanged)
	if buff then
		if not hItem.mon.buffid or hItem.mon.buffid == -1 or hItem.mon.buffid == buff.dwID then
			if hItem.nRenderFrame == nFrameCount then
				return
			end
			if config.hideVoidBuff and not hItem:IsVisible() then
				needFormatItemPos = true
				hItem:Show()
			end
			-- 计算BUFF时间
			local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - nFrameCount) / 16)
			local nBuffTime = math.max(GetBuffTime(buff.dwID, buff.nLevel) / 16, nTimeLeft)
			if l_tBuffTime[KTarget.dwID][buff.dwID] then
				nBuffTime = math.max(l_tBuffTime[KTarget.dwID][buff.dwID], nBuffTime)
			end
			l_tBuffTime[KTarget.dwID][buff.dwID] = nBuffTime
			-- 处理新出现的BUFF
			if not hItem.mon.iconid or hItem.mon.iconid == 13 then
				-- 计算图标 名字 BuffID等
				if hItem.mon.buffid ~= -1 then
					-- 加入精确缓存
					if not tItem[buff.dwID] then
						tItem[buff.dwID] = {}
					end
					tItem[buff.dwID][hItem] = true
					-- 移除模糊缓存
					if tItem[szBuffName] then
						tItem[szBuffName][hItem] = false
					end
					hItem.mon.buffid = buff.dwID
				end
				if not hItem.mon.buffname then
					hItem.mon.buffname = szBuffName
					hItem.txtBuffName:SetText(szBuffName)
				end
				hItem.mon.iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
				hItem.box:SetObjectIcon(hItem.mon.iconid)
			end
			-- 倒计时 与 BUFF层数堆叠
			hItem.txtProcess:SprintfText("%d'", nTimeLeft)
			hItem.box:SetOverText(1, nTimeLeft .. "'")
			hItem.box:SetOverText(0, buff.nStackNum == 1 and "" or buff.nStackNum)
			-- CD百分比
			local fPercent = nTimeLeft / nBuffTime
			hItem.imgProcess:SetPercentage(fPercent)
			hItem.box:SetCoolDownPercentage(fPercent)
			if fPercent < 0.5 and fPercent > 0.3 then
				if hItem.fPercent ~= 0.5 then
					hItem.fPercent = 0.5
					hItem.box:SetObjectStaring(true)
				end
			elseif fPercent < 0.3 and fPercent > 0.1 then
				if hItem.fPercent ~= 0.3 then
					hItem.fPercent = 0.3
					hItem.box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 17)
				end
			elseif fPercent < 0.1 then
				if hItem.fPercent ~= 0.1 then
					hItem.fPercent = 0.1
					hItem.box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 20)
				end
			else
				hItem.box:SetObjectStaring(false)
				hItem.box:ClearExtentAnimate()
			end
			hItem.nRenderFrame = nFrameCount
		end
		-- 加入同名BUFF列表
		if not hItem.mon.buffids then
			hItem.mon.buffids = {}
		end
		if not hItem.mon.buffids[buff.dwID] then
			hItem.mon.buffids[buff.dwID] = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
		end
	else
		hItem.box:SetCoolDownPercentage(0)
		hItem.box:SetObjectStaring(false)
		hItem.box:SetOverText(0, "")
		hItem.box:SetOverText(1, "")
		hItem.box:ClearExtentAnimate()
		hItem.txtProcess:SetText("")
		hItem.imgProcess:SetPercentage(0)
		-- 如果目标没有改变过 且 之前存在 则显示刷新动画
		if hItem.nRenderFrame and hItem.nRenderFrame >= 0 and hItem.nRenderFrame ~= nFrameCount and not targetChanged then
			hItem.box:SetObjectSparking(true)
			hItem.nSparkingFrame = nFrameCount
		-- 如果勾选隐藏不存在的BUFF 且 当前未隐藏 且 (目标改变过 或 刷新动画没有在播放) 则隐藏
		elseif config.hideVoidBuff and hItem:IsVisible()
		and (targetChanged or not hItem.nSparkingFrame or nFrameCount - hItem.nSparkingFrame <= BOX_SPARKING_FRAME) then
			hItem:Hide()
			hItem.nSparkingFrame = nil
			needFormatItemPos = true
		end
		hItem.fPercent = 0
		hItem.nRenderFrame = nil
	end
end
function FE.OnFrameBreathe()
	local dwType, dwID = GetTarget(this.config.target)
	if dwType == this.dwType and dwID == this.dwID
	and dwType ~= TARGET.PLAYER and dwType ~= TARGET.NPC then
		return
	end
	needFormatItemPos = false
	local hList = this.hList
	local config = this.config
	local KTarget = MY.GetObject(dwType, dwID)
	local targetChanged = dwType ~= this.dwType or dwID ~= this.dwID
	local nFrameCount = GetLogicFrameCount()
	
	if not KTarget then
		for i = 0, hList:GetItemCount() - 1 do
			UpdateItem(hList:Lookup(i), KTarget, nil, nil, this.tItem, config, nFrameCount, targetChanged)
		end
	else
		-- BUFF最大时间缓存
		if not l_tBuffTime[KTarget.dwID] then
			l_tBuffTime[KTarget.dwID] = {}
		end
		-- 更新当前存在的BUFF列表
		local dwClientPlayerID  = UI_GetClientPlayerID()
		local dwControlPlayerID = GetControlPlayerID()
		for _, buff in ipairs(MY.GetBuffList(KTarget)) do
			if not config.hideOthers or buff.dwSkillSrcID == dwClientPlayerID or buff.dwSkillSrcID == dwControlPlayerID then
				local szName = Table_GetBuffName(buff.dwID, buff.nLevel) or ""
				local tItems = this.tItem[buff.dwID]
				if tItems then
					for hItem, _ in pairs(tItems) do
						UpdateItem(hItem, KTarget, buff, szName, this.tItem, config, nFrameCount, targetChanged)
					end
				end
				local tItems = this.tItem[szName]
				if tItems then
					for hItem, _ in pairs(tItems) do
						UpdateItem(hItem, KTarget, buff, szName, this.tItem, config, nFrameCount, targetChanged)
					end
				end
			end
		end
		-- 更新消失的BUFF列表
		for i = 0, hList:GetItemCount() - 1 do
			if hList:Lookup(i).nRenderFrame ~= nFrameCount then
				UpdateItem(hList:Lookup(i), KTarget, nil, nil, this.tItem, config, nFrameCount, targetChanged)
			end
		end
		-- 防止CD过程中table被GC回收
		if targetChanged then
			this.tBuffTime = l_tBuffTime[KTarget.dwID]
		end
		-- 检查是否需要重绘界面坐标
		if needFormatItemPos then
			hList:FormatAllItemPos()
		end
	end
	this.dwType, this.dwID = dwType, dwID
end
end

function FE.OnFrameDragEnd()
	this:CorrectPos()
	this.config.anchor = GetFrameAnchor(this)
end

function FE.OnEvent(event)
	if event == "SKILL_MOUNT_KUNG_FU" then
		OpenPanel(this.config, true)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, this.config.caption, not this.config.dragable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, this.config.caption, not this.config.dragable)
		if this.config.dragable then
			this:EnableDrag(true)
		end
		FE.OnFrameDragEnd()
	end
end

----------------------------------------------------------------------------------------------
-- 数据存储
----------------------------------------------------------------------------------------------
do
local function OnInit()
	local data = MY.LoadLUAData(DEFAULT_CONFIG_FILE)
	Config = MY.LoadLUAData(ROLE_CONFIG_FILE) or data.default
	if MY_BuffMonS then
		if not Config[1] then
			Config[1] = clone(data.template)
		end
		Config[1].uid          = 1
		Config[1].caption      = _L['mingyi self buff monitor']
		Config[1].target       = "CLIENT_PLAYER"
		Config[1].scale        = MY_BuffMonS.bScale
		Config[1].enable       = MY_BuffMonS.bEnable
		Config[1].dragable     = MY_BuffMonS.bDragable
		Config[1].hideOthers   = MY_BuffMonS.bHideOthers
		Config[1].maxLineCount = MY_BuffMonS.nMaxLineCount
		Config[1].hideVoidBuff = MY_BuffMonS.bHideVoidBuff
		Config[1].cdBar        = MY_BuffMonS.bCDBar
		Config[1].cdBarWidth   = MY_BuffMonS.nCDWidth
		Config[1].cdBarUITex   = MY_BuffMonS.szCDUITex
		Config[1].showBuffName = MY_BuffMonS.bSkillName
		Config[1].boxBgUITex   = "UI/Image/Common/Box.UITex|44"
		Config[1].anchor       = MY_BuffMonS.anchor
		Config[1].monitors     = {}
		for kungfuid, mons in pairs(MY_BuffMonS.tBuffList) do
			Config[1].monitors[kungfuid] = {}
			for _, mon in ipairs(mons) do
				table.insert(Config[1].monitors[kungfuid], {
					enable = mon[1], iconid = mon[2],
					buffname = mon[3], buffid = mon[4], buffids = mon[5]
				})
			end
		end
	end
	if MY_BuffMonT then
		if not Config[2] then
			Config[2] = clone(data.template)
		end
		Config[2].uid          = 1
		Config[2].caption      = _L['mingyi target buff monitor']
		Config[2].target       = "TARGET"
		Config[2].scale        = MY_BuffMonT.bScale
		Config[2].enable       = MY_BuffMonT.bEnable
		Config[2].dragable     = MY_BuffMonT.bDragable
		Config[2].hideOthers   = MY_BuffMonT.bHideOthers
		Config[2].maxLineCount = MY_BuffMonT.nMaxLineCount
		Config[2].hideVoidBuff = MY_BuffMonT.bHideVoidBuff
		Config[2].cdBar        = MY_BuffMonT.bCDBar
		Config[2].cdBarWidth   = MY_BuffMonT.nCDWidth
		Config[2].cdBarUITex   = MY_BuffMonT.szCDUITex
		Config[2].showBuffName = MY_BuffMonT.bSkillName
		Config[2].boxBgUITex   = "UI/Image/Common/Box.UITex|44"
		Config[2].anchor       = MY_BuffMonT.anchor
		Config[2].monitors     = {}
		for kungfuid, mons in pairs(MY_BuffMonT.tBuffList) do
			Config[2].monitors[kungfuid] = {}
			for _, mon in ipairs(mons) do
				table.insert(Config[2].monitors[kungfuid], {
					enable = mon[1], iconid = mon[2],
					buffname = mon[3], buffid = mon[4], buffids = mon[5]
				})
			end
		end
	end
	for i, config in ipairs(Config) do
		OpenPanel(config, true)
	end
	ConfigTemplate = data.template
end
MY.RegisterInit("MY_BuffMon", OnInit)

local function OnExit()
	MY.SaveLUAData(ROLE_CONFIG_FILE, Config)
end
MY.RegisterExit("MY_BuffMon", OnExit)
end

----------------------------------------------------------------------------------------------
-- 设置界面
----------------------------------------------------------------------------------------------
local PS = {}
local function GenePS(ui, config, x, y, w, h)
	ui:append("WndEditBox", {
		x = x, y = y, w = w * 2 / 3, h = 22,
		r = 255, g = 255, b = 0, text = config.caption,
		onchange = function(raw, val) config.caption = val end,
	})
	ui:append("WndButton2", {
		x = w - 70, y = y,
		w = 60, h = 30,
		text = _L["Delete"],
		onclick = function()
			for i, c in ipairs_r(Config) do
				if config == c then
					table.remove(Config, i)
				end
			end
			ClosePanel(config)
			MY.SwitchTab("MY_BuffMon", true)
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['enable'],
		checked = config.enable,
		oncheck = function(bChecked)
			config.enable = bChecked
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['hide others buff'],
		checked = config.hideOthers,
		oncheck = function(bChecked)
			config.hideOthers = bChecked
			OpenPanel(config, true)
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y, w = 135,
		text = _L['set buff monitor'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {{
				szOption = _L['add'],
				fnAction = function()
					local function Next(kungfuid)
						GetUserInput(_L['please input buff name:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							if szVal ~= "" then
								if not config.monitors[kungfuid] then
									config.monitors[kungfuid] = {}
								end
								table.insert(config.monitors[kungfuid], {
									enable = true,
									iconid = 13,
									buffid = tonumber(szVal) or nil,
									buffname = not tonumber(szVal) and szVal or nil,
								})
								OpenPanel(config, true)
							end
						end, function() end, function() end, nil, "" )
					end
					MY.Confirm(_L['Add as common or current kunfu?'], function() Next('common') end,
						function() Next(dwKungFuID) end, _L['as common'], _L['as current kunfu'])
				end,
			}}
			local function InsertMenu(mon)
				local t1 = {
					szOption = mon.buffname or mon.buffid,
					bCheck = true, bChecked = mon.enable,
					fnAction = function(bChecked)
						mon.enable = bChecked
						OpenPanel(config, true)
					end,
					szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
					nFrame = 49,
					nMouseOverFrame = 51,
					nIconWidth = 17,
					nIconHeight = 17,
					szLayer = "ICON_RIGHTMOST",
					fnClickIcon = function()
						for i, m in ipairs_r(config.monitors) do
							if m == mon then
								table.remove(config.monitors, i)
							end
						end
						Wnd.CloseWindow("PopupMenuPanel")
						OpenPanel(config, true)
					end,
					nMiniWidth = 120,
				}
				if mon.buffids then
					do
						local dwBuffID, dwIcon = -1, mon.iconid or 13
						table.insert(t1, {
							szOption = _L['all buffid'],
							bCheck = true, bMCheck = true,
							bChecked = mon.buffid == nil or dwBuffID == mon.buffid,
							fnAction = function()
								mon.iconid = dwIcon
								mon.buffid = dwBuffID
								OpenPanel(config, true)
							end,
							szIcon = "fromiconid",
							nFrame = dwIcon or 13,
							nIconWidth = 22,
							nIconHeight = 22,
							szLayer = "ICON_RIGHTMOST",
						})
					end
					for dwBuffID, dwIcon in pairs(mon.buffids) do
						table.insert(t1, {
							szOption = dwBuffID,
							bCheck = true, bMCheck = true,
							bChecked = dwBuffID == mon.buffid,
							fnAction = function()
								mon.iconid = dwIcon or 13
								mon.buffid = dwBuffID
								OpenPanel(config, true)
							end,
							szIcon = "fromiconid",
							nFrame = dwIcon or 13,
							nIconWidth = 22,
							nIconHeight = 22,
							szLayer = "ICON_RIGHTMOST",
						})
					end
				end
				table.insert(t, t1)
			end
			local tBuffMonList = config.monitors.common
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					InsertMenu(mon)
				end
			end
			local tBuffMonList = config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID]
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					InsertMenu(mon)
				end
			end
			return t
		end,
	})
	ui:append("WndComboBox", {
		x = w - 115, y = y, w = 105,
		text = _L['set target'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {}
			for eType, szText in pairs(_L.TARGET) do
				table.insert(t, {
					szOption = szText,
					rgb = eType == config.target and {255, 255, 0} or nil,
					fnAction = function()
						config.target = eType
						OpenPanel(config, true)
					end,
				})
			end
			return t
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 100,
		text = _L['undragable'],
		checked = not config.dragable,
		oncheck = function(bChecked)
			config.dragable = not bChecked
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['hide void buff'],
		checked = config.hideVoidBuff,
		oncheck = function(bChecked)
			config.hideVoidBuff = bChecked
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textfmt = function(val) return _L("display %d eachline.", val) end,
		onchange = function(raw, val)
			config.maxLineCount = val
			OpenPanel(config, true)
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 120,
		text = _L['show cd bar'],
		checked = config.cdBar,
		oncheck = function(bCheck)
			config.cdBar = bCheck
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 120,
		text = _L['show buff name'],
		checked = config.showBuffName,
		oncheck = function(bCheck)
			config.showBuffName = bCheck
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textfmt = function(val) return _L("scale %d%%.", val) end,
		onchange = function(raw, val)
			config.scale = val / 100
			OpenPanel(config, true)
		end,
	})
	y = y + 30
	
	ui:append("WndComboBox", {
		x = 40, y = y, w = (w - 250 - 30 - 30 - 10) / 2,
		text = _L['Select background style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_BOXBG_STYLES) do
				szIcon, nFrame = unpack(text:split("|"))
				subt = {
					szOption = text,
					fnAction = function()
						config.boxBgUITex = text
						OpenPanel(config, true)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = "ICON_RIGHTMOST",
				}
				if text == config.boxBgUITex then
					subt.rgb = {255, 255, 0}
				end
				table.insert(t, subt)
			end
			return t
		end,
	})
	ui:append("WndComboBox", {
		x = 40 + (w - 250 - 30 - 30 - 10) / 2 + 10, y = y, w = (w - 250 - 30 - 30 - 10) / 2,
		text = _L['Select countdown style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CDBAR_STYLES) do
				szIcon, nFrame = unpack(text:split("|"))
				subt = {
					szOption = text,
					fnAction = function()
						config.cdBarUITex = text
						OpenPanel(config, true)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = "ICON_FILL",
				}
				if text == config.cdBarUITex then
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
		value = config.cdBarWidth,
		textfmt = function(val) return _L("CD width %dpx.", val) end,
		onchange = function(raw, val)
			config.cdBarWidth = val
			OpenPanel(config, true)
		end,
	})
	y = y + 30
	
	return x, y
end

function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30
	
	for _, config in ipairs(Config) do
		x, y = GenePS(ui, config, x, y, w, h)
		y = y + 20
	end
	y = y + 10
	
	ui:append("WndButton2", {
		x = (w - 60) / 2, y = y,
		w = 60, h = 30,
		text = _L["Create"],
		onclick = function()
			local config = clone(ConfigTemplate)
			config.uid = #Config == 0 and 1 or (Config[#Config].uid + 1)
			table.insert(Config, config)
			OpenPanel(config)
			MY.SwitchTab("MY_BuffMon", true)
		end,
	})
	y = y + 30
end
MY.RegisterPanel("MY_BuffMon", _L["buff monitor"], _L['Target'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)
