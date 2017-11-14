---------------------------------------------------------------------
-- BUFF监控
---------------------------------------------------------------------

------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local insert, remove, concat = table.insert, table.remove, table.concat
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_TargetMon/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_TargetMon/ui/MY_TargetMon.ini"
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.ROLE}
local DEFAULT_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "MY_TargetMon/data/$lang.jx3dat"
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.GLOBAL}
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
local TARGET_TYPE_LIST = {
	'CLIENT_PLAYER'  ,
	'CONTROL_PLAYER' ,
	'TARGET'         ,
	'TTARGET'        ,
	"TEAM_MARK_CLOUD",
	"TEAM_MARK_SWORD",
	"TEAM_MARK_AX"   ,
	"TEAM_MARK_HOOK" ,
	"TEAM_MARK_DRUM" ,
	"TEAM_MARK_SHEAR",
	"TEAM_MARK_STICK",
	"TEAM_MARK_JADE" ,
	"TEAM_MARK_DART" ,
	"TEAM_MARK_FAN"  ,
}
local Config, ConfigTemplate = {}
local BOX_SPARKING_FRAME = GLOBAL.GAME_FPS * 2 / 3

----------------------------------------------------------------------------------------------
-- 通用逻辑
----------------------------------------------------------------------------------------------
local FE = {}
local l_frames = {}
local l_frameIndex = -1
local function ClosePanel(config)
	if config == 'all' then
		for config, frame in pairs(l_frames) do
			Wnd.CloseWindow(frame)
		end
		l_frames = {}
	elseif l_frames[config] then
		Wnd.CloseWindow(l_frames[config])
		l_frames[config] = nil
	end
end

local function UpdateHotkey(frame)
	local i
	for ii = 1, #Config do
		if Config[ii] == frame.config then
			i = ii
		end
	end
	if not i then
		return
	end
	local hList = frame:Lookup("", "Handle_List")
	for j = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(j)
		local nKey, bShift, bCtrl, bAlt = Hotkey.Get("MY_TargetMon_" .. i .. "_" .. (j + 1))
		hItem.box:SetOverText(2, GetKeyShow(nKey, bShift, bCtrl, bAlt, true))
	end
end

local function CorrectPos(frame)
	local x, y = frame:GetAbsPos()
	local w, h = frame:GetSize()
	local cw, ch = Station.GetClientSize()
	if (x >= cw and y >= ch) or (x + w <= 0 and y + h <= 0) then
		frame:CorrectPos()
	end
end

local function SaveAnchor(frame)
	CorrectPos(frame)
	if frame.config.hideVoid then
		frame.config.anchor = GetFrameAnchor(frame, "LEFTTOP")
	else
		frame.config.anchor = GetFrameAnchor(frame)
	end
end

local function UpdateAnchor(frame)
	local anchor = frame.config.anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	CorrectPos(frame)
end

local function FormatAllItemPosExt(hList)
	local hItem = hList:Lookup(0)
	if not hItem then
		return
	end
	local W = hList:GetW()
	local w, h = hItem:GetSize()
	local columms = max(floor(W / w), 1)
	local ignoreInvisible = hList:IsIgnoreInvisibleChild()
	local aItem = {}
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		if not ignoreInvisible or hItem:IsVisible() then
			insert(aItem, hItem)
		end
	end
	local align, y = hList:GetHAlign(), 0
	while #aItem > 0 do
		local x, deltaX = 0, 0
		if align == ALIGNMENT.LEFT then
			x, deltaX = 0, w
		elseif align == ALIGNMENT.RIGHT then
			x, deltaX = W, - w
		elseif align == ALIGNMENT.CENTER then
			x, deltaX = (W - w * min(#aItem, columms)) / 2, w
		end
		for i = 1, min(#aItem, columms) do
			remove(aItem, 1):SetRelPos(x, y)
			x = x + deltaX
		end
		y = y + h
	end
	hList:SetSize(W, y)
	hList:FormatAllItemPos()
end

local function RecreatePanel(config)
	if not config.enable then
		return ClosePanel(config)
	end
	local frame = l_frames[config]
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, "MY_TargetMon#" .. l_frameIndex)
		l_frameIndex = l_frameIndex + 1
		l_frames[config] = frame
		frame.hList = frame:Lookup("", "Handle_List")
		frame.hList.FormatAllItemPosExt = FormatAllItemPosExt

		for k, v in pairs(FE) do
			frame[k] = v
		end
		frame:RegisterEvent("HOT_KEY_RELOADED")
		frame:RegisterEvent("SYS_MSG")
		frame:RegisterEvent("SKILL_MOUNT_KUNG_FU")
		frame:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
		frame:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	elseif frame.scale then
		frame:Scale(1 / frame.scale, 1 / frame.scale)
	end
	local hList = frame.hList

	hList:Clear()
	frame.tItem = {}
	frame.config = config
	local nItemW, nItemH, nWidth, nHeight, nCount = 0, 0, 0, 0, 0
	local function CreateItem(mon)
		if not mon.enable then
			return
		end
		nCount = nCount + 1
		local hItem        = hList:AppendItemFromIni(INI_PATH, "Handle_Item")
		local hBox         = hItem:Lookup("Handle_Box")
		local box          = hBox:Lookup("Box_Default")
		local imgBoxBg     = hBox:Lookup("Image_BoxBg")
		local txtShortName = hBox:Lookup("Text_ShortName")
		local hCDBar       = hItem:Lookup("Handle_Bar")
		local txtProcess   = hCDBar:Lookup("Text_Process")
		local imgProcess   = hCDBar:Lookup("Image_Process")
		local txtName      = hCDBar:Lookup("Text_Name")

		-- 建立高速索引
		hItem.box = box
		hItem.mon = mon
		hItem.txtProcess   = txtProcess
		hItem.imgProcess   = imgProcess
		hItem.txtName      = txtName
		hItem.txtShortName = txtShortName
		if mon.id and mon.id ~= 'common' then
			if not frame.tItem[mon.id] then
				frame.tItem[mon.id] = {}
			end
			frame.tItem[mon.id][hItem] = true
		elseif mon.name then
			if not frame.tItem[mon.name] then
				frame.tItem[mon.name] = {}
			end
			frame.tItem[mon.name][hItem] = true
		end

		-- Box部分
		box:SetObject(UI_OBJECT.BUFF, mon.id, 1, 1)
		box:SetObjectIcon(mon.iconid or 13)
		box:SetObjectCoolDown(true)
		box:SetCoolDownPercentage(0)
		-- BUFF时间
		box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
		box:SetOverTextFontScheme(1, 15)
		-- BUFF层数
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		-- 快捷键
		box:SetOverTextPosition(2, ITEM_POSITION.LEFT_BOTTOM)
		box:SetOverTextFontScheme(2, 7)
		-- Box背景图
		XGUI(imgBoxBg):image(config.boxBgUITex)

		if config.type == 'SKILL' then
			box.__SetCoolDownPercentage = box.SetCoolDownPercentage
			box.SetCoolDownPercentage = function(box, fPercent, ...)
				imgProcess:SetPercentage(1 - fPercent)
				box:__SetCoolDownPercentage(fPercent, ...)
			end
			box.__SetObjectCoolDown = box.SetObjectCoolDown
			box.SetObjectCoolDown = function(box, bCool, ...)
				imgProcess:SetVisible(bCool)
				box:__SetObjectCoolDown(bCool, ...)
			end
			box.__SetOverText = box.SetOverText
			box.SetOverText = function(box, nIndex, szText, ...)
				if nIndex == 3 then
					if szText == '' then
						txtProcess:SetText('')
					else
						txtProcess:SetText(szText .. "'")
					end
				end
				box:__SetOverText(nIndex, szText, ...)
			end
		end

		-- 倒计时条
		if config.cdBar then
			txtProcess:SetW(config.cdBarWidth - 10)
			txtProcess:SetText("")

			txtName:SetVisible(config.showName)
			txtName:SetW(config.cdBarWidth - 10)
			txtName:SetText(mon.longAlias or mon.name or '')

			XGUI(imgProcess):image(config.cdBarUITex)
			imgProcess:SetW(config.cdBarWidth)
			imgProcess:SetPercentage(0)

			hCDBar:Show()
			hCDBar:SetW(config.cdBarWidth)
			hItem.hCDBar = hCDBar
			hItem:SetW(hBox:GetW() + config.cdBarWidth)
			txtShortName:Hide()
		else
			hCDBar:Hide()
			hItem:SetW(hBox:GetW())
			txtShortName:SetText(mon.shortAlias or mon.name or '')
			txtShortName:SetVisible(config.showName)
			hBox:SetSizeByAllItemSize()
			hItem:SetSizeByAllItemSize()
		end
		if nCount == 1 then
			nItemW, nItemH = hItem:GetSize()
		end
		if nCount <= config.maxLineCount then
			nWidth = nWidth + hItem:GetW()
		end
		if nCount % config.maxLineCount == 1 then
			nHeight = nHeight + hItem:GetH()
		end
		hItem:SetVisible(not config.hideVoid)
	end
	for _, mon in ipairs(config.monitors.common or EMPTY_TABLE) do
		CreateItem(mon)
	end
	for _, mon in ipairs(config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID] or EMPTY_TABLE) do
		CreateItem(mon)
	end

	nWidth = nWidth == 0 and 200 or nWidth
	nHeight = nHeight == 0 and 50 or nHeight

	hList:SetSize(nWidth, nHeight)
	hList:SetHAlign(ALIGNMENT[config.alignment] or ALIGNMENT.LEFT)
	hList:SetIgnoreInvisibleChild(true)
	hList:FormatAllItemPosExt()
	UpdateHotkey(frame)

	frame:SetSize(nWidth, nHeight)
	frame:SetDragArea(0, 0, nWidth, nHeight)
	frame:EnableDrag(config.dragable)
	frame:SetMousePenetrable(not config.dragable)
	frame:Scale(config.scale, config.scale)

	frame.scale = config.scale
	frame.w, frame.h = frame:GetSize()
	frame.dragW = (nWidth) == 0 and 200 or (nWidth * config.scale)
	frame.dragH = (nItemH) == 0 and 200 or (nItemH * config.scale)
	UpdateAnchor(frame)
end

local function RecreateAllPanel(reload)
	for i, config in ipairs(Config) do
		RecreatePanel(config)
	end
end

local TEAM_MARK = {
	["TEAM_MARK_CLOUD"] = 1,
	["TEAM_MARK_SWORD"] = 2,
	["TEAM_MARK_AX"   ] = 3,
	["TEAM_MARK_HOOK" ] = 4,
	["TEAM_MARK_DRUM" ] = 5,
	["TEAM_MARK_SHEAR"] = 6,
	["TEAM_MARK_STICK"] = 7,
	["TEAM_MARK_JADE" ] = 8,
	["TEAM_MARK_DART" ] = 9,
	["TEAM_MARK_FAN"  ] = 10,
}
local function GetTarget(eTarType, eMonType)
	if eMonType == "SKILL" or eTarType == "CONTROL_PLAYER" then
		return TARGET.PLAYER, GetControlPlayerID()
	elseif eTarType == "CLIENT_PLAYER" then
		return TARGET.PLAYER, UI_GetClientPlayerID()
	elseif eTarType == "TARGET" then
		return MY.GetTarget()
	elseif eTarType == "TTARGET" then
		local KTarget = MY.GetObject(MY.GetTarget())
		if KTarget then
			return MY.GetTarget(KTarget)
		end
	elseif TEAM_MARK[eTarType] then
		local mark = GetClientTeam().GetTeamMark()
		if mark then
			for dwID, nMark in pairs(mark) do
				if TEAM_MARK[eTarType] == nMark then
					return TARGET[IsPlayer(dwID) and "PLAYER" or "NPC"], dwID
				end
			end
		end
	end
	return TARGET.NO_TARGET, 0
end

do
local needFormatItemPos
local l_tBuffTime = setmetatable({}, { __mode = "v" })
local function UpdateItem(hItem, KTarget, buff, szName, tItem, config, nFrameCount, targetChanged, dwOwnerID)
	if config.type == 'BUFF' and buff then
		if not hItem.mon.id or hItem.mon.id == 'common' or hItem.mon.id == buff.dwID then
			if hItem.nRenderFrame == nFrameCount then
				return
			end
			if config.hideVoid and not hItem:IsVisible() then
				needFormatItemPos = true
				hItem:Show()
			end
			-- 计算BUFF时间
			local nTimeLeft = math.max(0, buff.nEndFrame - nFrameCount) / 16
			local szTimeLeft = nTimeLeft > 3600 and '1h+' or ((config.decimalTime == -1 or nTimeLeft < config.decimalTime) and "%.1f'" or "%d'"):format(nTimeLeft)
			local nBuffTime = math.max(GetBuffTime(buff.dwID, buff.nLevel) / 16, nTimeLeft)
			if not l_tBuffTime[KTarget.dwID][buff.dwID] then
				l_tBuffTime[KTarget.dwID][buff.dwID] = {}
			end
			if not l_tBuffTime[KTarget.dwID][buff.dwID][buff.nLevel] then
				l_tBuffTime[KTarget.dwID][buff.dwID][buff.nLevel] = {}
			end
			if l_tBuffTime[KTarget.dwID][buff.dwID][buff.nLevel][buff.nStackNum] then
				nBuffTime = math.max(l_tBuffTime[KTarget.dwID][buff.dwID][buff.nLevel][buff.nStackNum])
			end
			l_tBuffTime[KTarget.dwID][buff.dwID][buff.nLevel][buff.nStackNum] = nBuffTime
			-- 处理新出现的BUFF
			if not hItem.mon.iconid or hItem.mon.iconid == 13 then
				-- 计算图标 名字 ID等
				if hItem.mon.id ~= "common" then
					-- 加入精确缓存
					if not tItem[buff.dwID] then
						tItem[buff.dwID] = {}
					end
					tItem[buff.dwID][hItem] = true
					-- 移除模糊缓存
					if tItem[szName] then
						tItem[szName][hItem] = false
					end
					hItem.mon.id = buff.dwID
				end
				if not hItem.mon.name then
					hItem.mon.name = szName
					hItem.txtName:SetText(hItem.mon.longAlias or szName)
					hItem.txtShortName:SetText(hItem.mon.shortAlias or szName)
				end
				hItem.mon.iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
				hItem.box:SetObjectIcon(hItem.mon.iconid)
			end
			-- 倒计时 与 BUFF层数堆叠
			hItem.txtProcess:SetText(szTimeLeft)
			hItem.box:SetOverText(1, szTimeLeft)
			hItem.box:SetOverText(0, buff.nStackNum == 1 and "" or buff.nStackNum)
			-- CD百分比
			local fPercent = nTimeLeft / nBuffTime
			hItem.imgProcess:SetPercentage(fPercent)
			hItem.box:SetCoolDownPercentage(fPercent)
			if config.cdFlash then
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
			else
				if hItem.box.__SetObjectCoolDown then
					hItem.box:__SetObjectCoolDown(false)
					hItem.box:__SetCoolDownPercentage(1)
				else
					hItem.box:SetObjectCoolDown(false)
					hItem.box:SetCoolDownPercentage(1)
				end
			end
			hItem.nRenderFrame = nFrameCount
		end
		-- 加入同名BUFF列表
		if not hItem.mon.ids[buff.dwID] then
			hItem.mon.ids[buff.dwID] = { framecount = 0, iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13 }
		end
	elseif config.type == 'SKILL' and buff and szName then
		if config.hideVoid and not hItem:IsVisible() then
			needFormatItemPos = true
			hItem:Show()
		end
		local dwID, dwLevel = buff, szName
		UpdateBoxObject(hItem.box, UI_OBJECT.SKILL, dwID, dwLevel, dwOwnerID)
		hItem.nRenderFrame = nFrameCount
	else
		if config.type == 'BUFF' then
			hItem.box:SetCoolDownPercentage(0)
			hItem.box:SetObjectStaring(false)
			hItem.box:SetOverText(0, "")
			hItem.box:SetOverText(1, "")
			hItem.box:ClearExtentAnimate()
		elseif config.type == 'SKILL' then
			hItem.box:SetOverText(3, "")
			hItem.box:SetObjectCoolDown(false)
		end
		hItem.txtProcess:SetText("")
		hItem.imgProcess:SetPercentage(0)
		-- 如果目标没有改变过 且 之前存在 则显示刷新动画
		if config.cdFlash and hItem.nRenderFrame and hItem.nRenderFrame >= 0 and hItem.nRenderFrame ~= nFrameCount and not targetChanged then
			hItem.box:SetObjectSparking(true)
			hItem.nSparkingFrame = nFrameCount
		-- 如果勾选隐藏不存在的BUFF 且 当前未隐藏 且 (目标改变过 或 刷新动画没有在播放) 则隐藏
		elseif config.hideVoid and hItem:IsVisible()
		and (targetChanged or not hItem.nSparkingFrame or nFrameCount - hItem.nSparkingFrame > BOX_SPARKING_FRAME) then
			hItem:Hide()
			hItem.nSparkingFrame = nil
			needFormatItemPos = true
		end
		hItem.fPercent = 0
		hItem.nRenderFrame = nil
	end
end
function FE.OnFrameBreathe()
	local dwType, dwID = GetTarget(this.config.target, this.config.type)
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
		if config.type == 'BUFF' then
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
		elseif config.type == 'SKILL' then
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				local bFind = false
				for dwSkillID, info in pairs(hItem.mon.ids) do
					local dwLevel = KTarget.GetSkillLevel(dwSkillID)
					local bCool, nLeft, nTotal, nCDCount, bPublicCD = KTarget.GetSkillCDProgress(dwSkillID, dwLevel, 444)
					if bCool and nLeft ~= 0 and nTotal ~= 0 and not bPublicCD then
						bFind = true
						UpdateItem(hItem, KTarget, dwSkillID, dwLevel, this.tItem, config, nFrameCount, targetChanged, dwID)
						break
					end
				end
				if not bFind then
					UpdateItem(hItem, KTarget, nil, nil, this.tItem, config, nFrameCount, targetChanged, dwID)
				end
			end
		end
		-- 检查是否需要重绘界面坐标
		if needFormatItemPos then
			hList:FormatAllItemPosExt()
		end
	end
	this.dwType, this.dwID = dwType, dwID
end
end

function FE.OnFrameDragEnd()
	SaveAnchor(this)
end

do
local function OnSkill(this, dwID, dwLevel)
	local tItems = this.tItem[dwID]
	if tItems then
		for hItem, _ in pairs(tItems) do
			if not hItem.mon.ids[dwID] then
				if not hItem.mon.iconid or hItem.mon.iconid == 13 then
					hItem.mon.iconid = Table_GetSkillIconID(dwID, dwLevel)
				end
				hItem.mon.ids[dwID] = { framecount = 0, iconid = Table_GetSkillIconID(dwID, dwLevel) }
			end
		end
	end
	local szName = Table_GetSkillName(dwID, dwLevel)
	local tItems = this.tItem[szName]
	if tItems then
		for hItem, _ in pairs(tItems) do
			if not hItem.mon.ids[dwID] then
				if not hItem.mon.iconid or hItem.mon.iconid == 13 then
					hItem.mon.iconid = Table_GetSkillIconID(dwID, dwLevel)
				end
				hItem.mon.ids[dwID] = { framecount = 0, iconid = Table_GetSkillIconID(dwID, dwLevel) }
			end
		end
	end
end
function FE.OnEvent(event)
	if event == "HOT_KEY_RELOADED" then
		UpdateHotkey(this)
	elseif event == "SYS_MSG" then
		if this.config.type ~= 'SKILL' then
			return
		end
		if arg0 == "UI_OME_SKILL_CAST_LOG" then
			-- 技能施放日志；
			-- (arg1)dwCaster：技能施放者 (arg2)dwSkillID：技能ID (arg3)dwLevel：技能等级
			-- MY_Recount.OnSkillCast(arg1, arg2, arg3)
			if arg1 == this.dwID then
				OnSkill(this, arg2, arg3)
			end
		elseif arg0 == "UI_OME_SKILL_HIT_LOG" then
			if arg1 == this.dwID then
				OnSkill(this, arg4, arg5)
			end
		end
	elseif event == "SKILL_MOUNT_KUNG_FU" then
		RecreatePanel(this.config)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		this:SetH(this.dragH)
		this:Lookup('', 'Handle_List'):SetAlpha(90)
		UpdateCustomModeWindow(this, this.config.caption, not this.config.dragable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		this:SetH(this.h)
		this:Lookup('', 'Handle_List'):SetAlpha(255)
		UpdateCustomModeWindow(this, this.config.caption, not this.config.dragable)
		if this.config.dragable then
			this:EnableDrag(true)
		end
		FE.OnFrameDragEnd()
	end
end
end

----------------------------------------------------------------------------------------------
-- 数据存储
----------------------------------------------------------------------------------------------
local function UpdateConfigCalcProps(config)
	for _, monitors in pairs(config.monitors) do
		for _, mon in ipairs(monitors) do
			if not mon.ids then
				mon.ids = {}
			end
			for k, _ in pairs(mon.ids) do
				if not tonumber(k) then
					mon.ids[k] = nil
				end
			end
		end
	end
	for k, v in pairs(ConfigTemplate) do
		if type(v) ~= type(config[k]) then
			config[k] = clone(v)
		end
	end
end

local function UpdateConfigDataVersion(config)
	for kungfuid, monitors in pairs(config.monitors) do
		for _, mon in ipairs(monitors) do
			mon.name, mon.buffname = mon.name or mon.buffname, nil
			mon.id  , mon.buffid   = mon.id   or mon.buffid  , nil
			mon.ids , mon.buffids  = mon.ids  or mon.buffids , nil
			for dwID, dwIconID in pairs(mon.ids) do
				mon.ids[dwID] = { framecount = 0, iconid = dwIconID }
			end
		end
	end
	config.type = config.type or 'BUFF'
	config.showName, config.showBuffName = config.showName or config.showBuffName, nil
	UpdateConfigCalcProps(config)
end

do
MY_BuffMonS = {}
RegisterCustomData("MY_BuffMonS.fScale")
RegisterCustomData("MY_BuffMonS.bEnable")
RegisterCustomData("MY_BuffMonS.bDragable")
RegisterCustomData("MY_BuffMonS.bHideOthers")
RegisterCustomData("MY_BuffMonS.nMaxLineCount")
RegisterCustomData("MY_BuffMonS.bHideVoidBuff")
RegisterCustomData("MY_BuffMonS.bCDBar")
RegisterCustomData("MY_BuffMonS.nCDWidth")
RegisterCustomData("MY_BuffMonS.szCDUITex")
RegisterCustomData("MY_BuffMonS.bSkillName")
RegisterCustomData("MY_BuffMonS.anchor")
RegisterCustomData("MY_BuffMonS.tBuffList")
MY_BuffMonT = {}
RegisterCustomData("MY_BuffMonT.fScale")
RegisterCustomData("MY_BuffMonT.bEnable")
RegisterCustomData("MY_BuffMonT.bDragable")
RegisterCustomData("MY_BuffMonT.bHideOthers")
RegisterCustomData("MY_BuffMonT.nMaxLineCount")
RegisterCustomData("MY_BuffMonT.bHideVoidBuff")
RegisterCustomData("MY_BuffMonT.bCDBar")
RegisterCustomData("MY_BuffMonT.nCDWidth")
RegisterCustomData("MY_BuffMonT.szCDUITex")
RegisterCustomData("MY_BuffMonT.bSkillName")
RegisterCustomData("MY_BuffMonT.anchor")
RegisterCustomData("MY_BuffMonT.tBuffList")
local function OnInit()
	local data = MY.LoadLUAData(DEFAULT_CONFIG_FILE)
	ConfigTemplate = data.template
	data.default = MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE) or data.default

	local OLD_PATH = {'config/my_buffmon.jx3dat', MY_DATA_PATH.ROLE}
	local SZ_OLD_PATH = MY.FormatPath(OLD_PATH)
	if IsLocalFileExist(SZ_OLD_PATH) then
		Config = MY.LoadLUAData(OLD_PATH)
		CPath.DelFile(SZ_OLD_PATH)
		if Config then
			for _, config in ipairs(Config) do
				UpdateConfigDataVersion(config)
			end
		else
			Config = MY.LoadLUAData(ROLE_CONFIG_FILE) or data.default
		end
	else
		Config = MY.LoadLUAData(ROLE_CONFIG_FILE) or data.default
	end
	for _, p in ipairs({
		{ OBJ = MY_BuffMonS, index = 1, title = _L['mingyi self buff monitor'], target = 'CLIENT_PLAYER' },
		{ OBJ = MY_BuffMonT, index = 2, title = _L['mingyi target buff monitor'], target = 'TARGET' },
	}) do
		local OBJ, index = p.OBJ, p.index
		if OBJ and OBJ.tBuffList then
			if not Config[index] then
				Config[index] = clone(data.template)
			end
			Config[index].caption      = p.title
			Config[index].type         = 'BUFF'
			Config[index].target       = p.target
			Config[index].scale        = OBJ.fScale
			Config[index].enable       = OBJ.bEnable
			Config[index].dragable     = OBJ.bDragable
			Config[index].hideOthers   = OBJ.bHideOthers
			Config[index].maxLineCount = OBJ.nMaxLineCount
			Config[index].hideVoid     = OBJ.bHideVoidBuff
			Config[index].cdBar        = OBJ.bCDBar
			Config[index].cdBarWidth   = OBJ.nCDWidth
			Config[index].cdBarUITex   = OBJ.szCDUITex
			Config[index].showName     = OBJ.bSkillName
			Config[index].boxBgUITex   = "UI/Image/Common/Box.UITex|44"
			Config[index].anchor       = OBJ.anchor
			Config[index].monitors     = {}
			for kungfuid, mons in pairs(OBJ.tBuffList) do
				Config[index].monitors[kungfuid] = {}
				for _, mon in ipairs(mons) do
					if mon[4] == -1 then
						mon[4] = 'common'
					end
					if mon[5] and mon[5][-1] then
						mon[5]['common'], mon[5][-1] = mon[5][-1]
					end
					table.insert(Config[index].monitors[kungfuid], {
						enable = mon[1], iconid = mon[2],
						name = mon[3], id = mon[4], ids = (function()
							local ids = {}
							if mon[5] then
								for dwID, dwIconID in pairs(mon[5]) do
									ids[dwID] = { framecount = 0, iconid = dwIconID}
								end
							end
							return ids
						end)(),
					})
				end
			end
			OBJ.fScale        = nil
			OBJ.bEnable       = nil
			OBJ.bDragable     = nil
			OBJ.bHideOthers   = nil
			OBJ.nMaxLineCount = nil
			OBJ.bHideVoidBuff = nil
			OBJ.bCDBar        = nil
			OBJ.nCDWidth      = nil
			OBJ.szCDUITex     = nil
			OBJ.bSkillName    = nil
			OBJ.anchor        = nil
			OBJ.tBuffList     = nil
		end
	end
	for _, config in pairs(Config) do
		UpdateConfigCalcProps(config)
	end
	-- 加载界面
	RecreateAllPanel()
end
MY.RegisterInit("MY_TargetMon", OnInit)

local function OnExit()
	MY.SaveLUAData(ROLE_CONFIG_FILE, Config)
end
MY.RegisterExit("MY_TargetMon", OnExit)
end

----------------------------------------------------------------------------------------------
-- 快捷键
----------------------------------------------------------------------------------------------
do
local title = _L["MY Buff Monitor"]
for i = 1, 5 do
	for j = 1, 10 do
		Hotkey.AddBinding("MY_TargetMon_" .. i .. "_" .. j, _L("Cancel buff %d - %d", i, j), title, function()
			if MY.IsShieldedVersion() and not MY.IsInDungeon(true) then
				if not IsDebugClient() then
					OutputMessage("MSG_ANNOUNCE_YELLOW", _L['Cancel buff is disabled outside dungeon.'])
				end
				return
			end
			local config = Config[i]
			if not config or config.type ~= 'BUFF' then
				return
			end
			local frame = l_frames[config]
			if not frame then
				return
			end
			local hItem = frame:Lookup("", "Handle_List"):Lookup(j - 1)
			if not hItem then
				return
			end
			local KTarget = MY.GetObject(GetTarget(frame.config.target, frame.config.type))
			if not KTarget then
				return
			end
			MY.CancelBuff(KTarget, hItem.mon.id == 'common' and hItem.mon.name or hItem.mon.id)
		end, nil)
		title = ""
	end
end
end

----------------------------------------------------------------------------------------------
-- 设置界面
----------------------------------------------------------------------------------------------
local PS = {}
local function GenePS(ui, config, x, y, w, h, OpenConfig)
	ui:append("Text", {text = (function()
		for i = 1, #Config do
			if Config[i] == config then
				return i
			end
		end
		return "X"
	end)() .. ".", x = x, y = y - 3, w = 20, r = 255, g = 255, b = 0})
	ui:append("WndEditBox", {
		x = x + 20, y = y, w = w - 290, h = 22,
		r = 255, g = 255, b = 0, text = config.caption,
		onchange = function(raw, val) config.caption = val end,
	})
	ui:append("WndButton2", {
		x = w - 180, y = y,
		w = 50, h = 30,
		text = _L["Move Up"],
		onclick = function()
			for i = 1, #Config do
				if Config[i] == config then
					if Config[i - 1] then
						Config[i], Config[i - 1] = Config[i - 1], Config[i]
						RecreateAllPanel()
						return MY.SwitchTab("MY_TargetMon", true)
					end
				end
			end
		end,
	})
	ui:append("WndButton2", {
		x = w - 125, y = y,
		w = 50, h = 30,
		text = _L["Move Down"],
		onclick = function()
			for i = 1, #Config do
				if Config[i] == config then
					if Config[i + 1] then
						Config[i], Config[i + 1] = Config[i + 1], Config[i]
						RecreateAllPanel()
						return MY.SwitchTab("MY_TargetMon", true)
					end
				end
			end
		end,
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
			MY.SwitchTab("MY_TargetMon", true)
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['Enable'],
		checked = config.enable,
		oncheck = function(bChecked)
			config.enable = bChecked
			RecreatePanel(config)
		end,
	})

	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['Hide others buff'],
		checked = config.hideOthers,
		oncheck = function(bChecked)
			config.hideOthers = bChecked
			RecreatePanel(config)
		end,
		autoenable = function()
			return config.type == 'BUFF'
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y, w = 135,
		text = _L['Set target'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {}
			for _, eType in ipairs(TARGET_TYPE_LIST) do
				table.insert(t, {
					szOption = _L.TARGET[eType],
					bCheck = true, bMCheck = true,
					bChecked = eType == (config.type == "SKILL" and "CONTROL_PLAYER" or config.target),
					fnDisable = function()
						return config.type == "SKILL" and eType ~= "CONTROL_PLAYER"
					end,
					fnAction = function()
						config.target = eType
						RecreatePanel(config)
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'BUFF', 'SKILL'}) do
				table.insert(t, {
					szOption = _L.TYPE[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.type,
					fnAction = function()
						config.type = eType
						RecreatePanel(config)
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'LEFT', 'RIGHT', 'CENTER'}) do
				table.insert(t, {
					szOption = _L.ALIGNMENT[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.alignment,
					fnAction = function()
						config.alignment = eType
						RecreatePanel(config)
					end,
				})
			end
			return t
		end,
	})
	ui:append("WndButton2", {
		x = w - 110, y = y, w = 102,
		text = _L['Set monitor'],
		onclick = function() OpenConfig(config) end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 100,
		text = _L['Undragable'],
		checked = not config.dragable,
		oncheck = function(bChecked)
			config.dragable = not bChecked
			RecreatePanel(config)
		end,
	})

	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['Hide void'],
		checked = config.hideVoid,
		oncheck = function(bChecked)
			config.hideVoid = bChecked
			RecreatePanel(config)
		end,
	})

	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textfmt = function(val) return _L("Display %d eachline.", val) end,
		onchange = function(raw, val)
			config.maxLineCount = val
			RecreatePanel(config)
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 120,
		text = _L['Show cd bar'],
		checked = config.cdBar,
		oncheck = function(bCheck)
			config.cdBar = bCheck
			RecreatePanel(config)
		end,
	})

	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 120,
		text = _L['Show name'],
		checked = config.showName,
		oncheck = function(bCheck)
			config.showName = bCheck
			RecreatePanel(config)
		end,
	})

	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textfmt = function(val) return _L("Scale %d%%.", val) end,
		onchange = function(raw, val)
			config.scale = val / 100
			RecreatePanel(config)
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 200,
		text = _L['Show cd flash'],
		checked = config.cdFlash,
		oncheck = function(bCheck)
			config.cdFlash = bCheck
			RecreatePanel(config)
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
			RecreatePanel(config)
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
						RecreatePanel(config)
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
						RecreatePanel(config)
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
		range = {-1, 30},
		value = config.decimalTime,
		textfmt = function(val)
			if val == -1 then
				return _L['Always show decimal time.']
			elseif val == 0 then
				return _L['Never show decimal time.']
			else
				return _L("Show decimal time left in %ds.", val)
			end
		end,
		onchange = function(raw, val)
			config.decimalTime = val
			RecreatePanel(config)
		end,
	})
	y = y + 30

	return x, y
end

function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 30
	local x, y = X, Y

	local OpenConfig
	do -- single config details
		local l_config
		local uiWrapper = ui:append('WndWindow', { name = 'WndWindow_Wrapper', x = 0, y = 0, w = w, h = h }, true)
		uiWrapper:append('Shadow', { x = 0, y = 0, w = w, h = h, r = 0, g = 0, b = 0, alpha = 150 })
		uiWrapper:append('Shadow', { x = 10, y = 10, w = w - 20, h = h - 20, r = 255, g = 255, b = 255, alpha = 40 })

		local x0, y0 = 20, 20
		local w0, h0 = w - 40, h - 30
		local w1, w2 = w0 / 2 - 5, w0 / 2 - 5
		local x1, x2 = x0, x0 + w1 + 10

		local listCommon = uiWrapper:append("WndListBox", { x = x1, y = y0 + 25, w = w1, h = h0 - 30 - 30 }, true)
		local listKungfu = uiWrapper:append("WndListBox", { x = x2, y = y0 + 25, w = w2, h = h0 - 30 - 30 }, true)

		local function Add(kungfuid)
			if kungfuid == 'current' then
				kungfuid = GetClientPlayer().GetKungfuMount().dwSkillID
			end
			GetUserInput(_L['Please input name:'], function(szVal)
				szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
				if szVal ~= "" then
					if not l_config.monitors[kungfuid] then
						l_config.monitors[kungfuid] = {}
					end
					local aMonList = l_config.monitors[kungfuid]
					local mon = {
						enable = true,
						iconid = 13,
						id = tonumber(szVal) or 'common',
						ids = {},
						name = not tonumber(szVal) and szVal or nil,
					}
					table.insert(aMonList, mon)
					local list = kungfuid == 'common' and listCommon or listKungfu
					list:listbox(
						'insert',
						mon.name or mon.id,
						mon.name or mon.id,
						{ mon = mon, monlist = aMonList }
					)
					RecreatePanel(l_config)
				end
			end, function() end, function() end, nil, "" )
		end
		uiWrapper:append("Text", { x = x1 + 5, y = y0, w = w1 - 60 - 5,  h = 25, text = _L['Common monitor'] })
		uiWrapper:append("WndButton2", { x = x1 + w1 - 60, y = y0 - 1, w = 60, h = 28, text = _L['Add'], onclick = function() Add('common') end })
		uiWrapper:append("Text", { x = x2 + 5, y = y0, w = w2 - 60 - 5,  h = 25, text = _L['Current kungfu monitor'] })
		uiWrapper:append("WndButton2", { x = x2 + w2 - 60, y = y0 - 1, w = 60, h = 28, text = _L['Add'], onclick = function() Add('current') end })

		-- 初始化list控件
		local function onMenu(hItem, szText, szID, data)
			local mon = data.mon
			local monlist = data.monlist
			local t1 = {
				{
					szOption = _L['enable'],
					bCheck = true, bChecked = mon.enable,
					fnAction = function()
						mon.enable = not mon.enable
						RecreatePanel(l_config)
					end,
				},
				{ bDevide = true },
				{
					szOption = _L['Delete'],
					fnAction = function()
						local list = monlist == l_config.monitors.common and listCommon or listKungfu
						list:listbox('delete', szText, szID)
						for i, m in ipairs_r(monlist) do
							if m == mon then
								table.remove(monlist, i)
							end
						end
						Wnd.CloseWindow("PopupMenuPanel")
						RecreatePanel(l_config)
					end,
				},
				{
					szOption = _L['Rename'],
					fnAction = function()
						GetUserInput(_L['Please input name:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							if szVal ~= "" then
								mon.name = szVal
								RecreatePanel(l_config)
							end
						end, function() end, function() end, nil, mon.name)
					end,
				},
				{
					szOption = _L['Manual add id'],
					fnAction = function()
						GetUserInput(_L['Please input id:'], function(szVal)
							local nVal = tonumber(string.gsub(szVal, "^%s*(.-)%s*$", "%1"), 10)
							if nVal then
								for id, _ in pairs(mon.ids) do
									if id == nVal then
										return
									end
								end
								local dwIconID = 13
								if l_config.type == "SKILL" then
									local dwLevel = GetClientPlayer().GetSkillLevel(nVal) or 1
									dwIconID = Table_GetSkillIconID(nVal, dwLevel) or dwIconID
								else
									dwIconID = Table_GetBuffIconID(nVal, 1) or 13
								end
								mon.ids[nVal] = dwIconID
								RecreatePanel(l_config)
							end
						end, function() end, function() end, nil, nil)
					end,
				},
				{ bDevide = true },
				{
					szOption = _L('Long alias: %s', mon.longAlias or _L['Not set']),
					fnAction = function()
						GetUserInput(_L['Please input long alias:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							mon.longAlias = szVal
							RecreatePanel(l_config)
						end, function() end, function() end, nil, mon.longAlias or mon.name)
					end,
				},
				{
					szOption = _L('Short alias: %s', mon.shortAlias or _L['Not set']),
					fnAction = function()
						GetUserInput(_L['Please input short alias:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							mon.shortAlias = szVal
							RecreatePanel(l_config)
						end, function() end, function() end, nil, mon.shortAlias or mon.name)
					end,
				},
			}
			if not empty(mon.ids) then
				table.insert(t1, { bDevide = true })
				local function InsertMenuID(dwID, dwIcon)
					table.insert(t1, {
						szOption = dwID == "common" and _L['All ids'] or dwID,
						bCheck = true, bMCheck = true,
						bChecked = dwID == mon.id or (dwID == "common" and mon.id == nil),
						fnAction = function()
							mon.iconid = dwIcon
							mon.id = dwID
							RecreatePanel(l_config)
						end,
						szIcon = "fromiconid",
						nFrame = dwIcon or 13,
						nIconWidth = 22,
						nIconHeight = 22,
						szLayer = "ICON_RIGHTMOST",
						fnClickIcon = function()
							XGUI.OpenIconPanel(function(dwIcon)
								mon.ids[dwID] = dwIcon
								if mon.id == dwID then
									mon.iconid = dwIcon
									RecreatePanel(l_config)
								end
							end)
							Wnd.CloseWindow("PopupMenuPanel")
						end,
						{
							szOption = _L['Delete'],
							fnAction = function()
								mon.ids[dwID] = nil
								RecreatePanel(l_config)
							end,
						}
					})
				end
				InsertMenuID('common', mon.ids.common or mon.iconid or 13)
				for dwID, dwIcon in pairs(mon.ids) do
					if dwID ~= "common" then
						InsertMenuID(dwID, dwIcon)
					end
				end
			end
			return t1
		end
		listCommon:listbox('onmenu', onMenu)
		listKungfu:listbox('onmenu', onMenu)

		function OpenConfig(config)
			l_config = config
			listCommon:listbox('clear')
			do local aMonList = config.monitors.common
				if aMonList and #aMonList > 0 then
					for i, mon in ipairs(aMonList) do
						listCommon:listbox(
							'insert',
							mon.name or mon.id,
							mon.name or mon.id,
							{ mon = mon, monlist = aMonList }
						)
					end
				end
			end
			listKungfu:listbox('clear')
			do local aMonList = config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID]
				if aMonList and #aMonList > 0 then
					for i, mon in ipairs(aMonList) do
						listKungfu:listbox(
							'insert',
							mon.name or mon.id,
							mon.name or mon.id,
							{ mon = mon, monlist = aMonList }
						)
					end
				end
			end
			uiWrapper:show()
			uiWrapper:bringToTop()
		end

		uiWrapper:append('WndButton2', {
			x = x0 + w0 / 2 - 50, y = y0 + h0 - 30,
			w = 100, h = 30, text = _L['Close'],
			onclick = function()
				l_config = nil
				uiWrapper:hide()
			end,
		})
		uiWrapper:hide()
	end

	for _, config in ipairs(Config) do
		x, y = GenePS(ui, config, x, y, w, h, OpenConfig)
		y = y + 20
	end
	y = y + 10

	x = (w - 380) / 2
	ui:append("WndButton2", {
		x = x, y = y,
		w = 60, h = 30,
		text = _L["Create"],
		onclick = function()
			local config = clone(ConfigTemplate)
			table.insert(Config, config)
			RecreatePanel(config)
			MY.SwitchTab("MY_TargetMon", true)
		end,
	})
	x = x + 70
	ui:append("WndButton2", {
		x = x, y = y,
		w = 60, h = 30,
		text = _L["Import"],
		onclick = function()
			local file = GetOpenFileName(
				_L['Please select import target monitor data file.'],
				'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
				MY.FormatPath({ 'export/TargetMon', MY_DATA_PATH.GLOBAL })
			)
			if file == '' then
				return
			end
			local configs = MY.LoadLUAData(file)
			if not configs then
				return
			end
			local importCount = 0
			local replaceCount = 0
			for _, config in ipairs(configs) do
				UpdateConfigDataVersion(config)
				for i, cfg in ipairs_r(Config) do
					if cfg.caption == config.caption then
						table.remove(Config, i)
						replaceCount = replaceCount + 1
					end
				end
				table.insert(Config, config)
				importCount = importCount + 1
			end
			RecreateAllPanel(true)
			MY.SwitchTab("MY_TargetMon", true)
			MY.Sysmsg({ _L('Import successed, %d imported and %d replaced.', importCount, replaceCount) })
			OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Import successed, %d imported and %d replaced.', importCount, replaceCount))
		end,
	})
	x = x + 70
	ui:append("WndButton2", {
		x = x, y = y,
		w = 60, h = 30,
		text = _L["Export"],
		menu = function()
			local configs = {}
			local menu = {}
			for _, config in ipairs(Config) do
				table.insert(menu, {
					bCheck = true,
					szOption = config.caption,
					fnAction = function()
						for i, cfg in ipairs_r(configs) do
							if cfg == config then
								table.remove(configs, i)
								return
							end
						end
						table.insert(configs, config)
					end,
				})
			end
			if #menu > 0 then
				table.insert(menu, MENU_DIVIDER)
			end
			table.insert(menu, {
				szOption = _L['Ensure export'],
				fnAction = function()
					local file = MY.FormatPath({
						"export/TargetMon/$name@$server@"
							.. MY.FormatTime("yyyyMMddhhmmss")
							.. ".jx3dat",
						MY_DATA_PATH.GLOBAL,
					})
					MY.SaveLUAData(file, configs)
					MY.Sysmsg({ _L('Data exported, file saved at %s.', file) })
					OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Data exported, file saved at %s.', file))
				end,
				fnDisable = function()
					return not next(configs)
				end,
			})
			return menu
		end,
	})
	x = x + 70
	ui:append("WndButton2", {
		x = x, y = y,
		w = 80, h = 30,
		text = _L["Save As Default"],
		onclick = function()
			MY.Confirm(_L['Sure to save as default?'], function()
				MY.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, Config)
			end)
		end,
	})
	x = x + 90
	ui:append("WndButton2", {
		x = x, y = y,
		w = 80, h = 30,
		text = _L["Reset Default"],
		tip = _L['Hold ctrl to reset original default.'],
		tippostype = MY.Const.UI.Tip.POS_TOP,
		onclick = function()
			local ctrl = IsCtrlKeyDown()
			MY.Confirm(_L[ctrl and 'Sure to reset original default?' or 'Sure to reset default?'], function()
				ClosePanel('all')
				Config = MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE)
				if not Config or ctrl then
					Config = MY.LoadLUAData(DEFAULT_CONFIG_FILE).default
				end
				for _, config in pairs(Config) do
					UpdateConfigDataVersion(config)
				end
				RecreateAllPanel()
				MY.SwitchTab("MY_TargetMon", true)
			end)
		end,
	})
	x = x + 90

	x = X
	y = y + 30
end

function PS.OnPanelScroll(wnd, scrollX, scrollY)
	wnd:Lookup('WndWindow_Wrapper'):SetRelPos(scrollX, scrollY)
end
MY.RegisterPanel("MY_TargetMon", _L["Target monitor"], _L['Target'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)
