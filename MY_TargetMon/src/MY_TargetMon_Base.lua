------------------------------------------------
--@Author: tinymins (root@derzh.com)
--@Date:   2018-01-08 21:18:02
--@Last Modified by:   tinymins (root@derzh.com)
--@Last Modified time: 2018-01-08 21:19:32
------------------------------------------------
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

local D = {}
local BOX_SPARKING_FRAME = GLOBAL.GAME_FPS * 2 / 3
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_TargetMon/ui/MY_TargetMon.ini"

function D.UpdateHotkey(frame)
	local i = this.index
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

function D.SaveAnchor(frame)
	frame.config.anchor = frame.config.hideVoid
		and GetFrameAnchor(frame, "LEFTTOP")
		or GetFrameAnchor(frame)
end

function D.UpdateAnchor(frame)
	local anchor = frame.config.anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	local x, y = frame:GetAbsPos()
	local w, h = frame:GetSize()
	local cw, ch = Station.GetClientSize()
	if (x < cw or y < ch) and (x + w > 0 and y + h > 0) then
		return
	end
	frame:CorrectPos()
end

local function ReloadFrame(frame)
	local config, index = MY_TargetMon.GetFrameData(frame:GetName():sub(#"MY_TargetMon#" + 1))
	if not config then
		return Wnd.CloseWindow(frame)
	end
	this.index = index
	this.config = config

	if frame.scale then
		frame:Scale(1 / frame.scale, 1 / frame.scale)
	end
	local hTotal, hList = frame.hTotal, frame.hList

	frame.tItem = {}
	hList:Clear()
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
		for dwID, info in pairs(mon.ids) do
			if info.enable or mon.ignoreId then
				if not frame.tItem[dwID] then
					frame.tItem[dwID] = {}
				end
				if not mon.ignoreId and not info.ignoreLevel then
					for nLevel, levelInfo in pairs(info.levels) do
						if levelInfo.enable then
							if not frame.tItem[dwID][nLevel] then
								frame.tItem[dwID][nLevel] = {}
							end
							frame.tItem[dwID][nLevel][hItem] = true
						end
					end
				else
					if not frame.tItem[dwID]['all'] then
						frame.tItem[dwID]['all'] = {}
					end
					frame.tItem[dwID]['all'][hItem] = true
				end
			end
		end
		if mon.name then
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
			txtName:SetFontColor(unpack(mon.rgbAlias))

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
			txtShortName:SetFontColor(unpack(mon.rgbShortAlias))
			hBox:SetSizeByAllItemSize()
			hItem:SetSizeByAllItemSize()
		end
		if nCount == 1 then
			nItemW, nItemH = hItem:GetSize()
		end
		if nCount <= config.maxLineCount then
			nWidth = ceil(nWidth + ceil(hItem:GetW()))
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
	hTotal:SetSizeByAllItemSize()
	D.UpdateHotkey(frame)

	frame:SetSize(nWidth, nHeight)
	frame:SetDragArea(0, 0, nWidth, nHeight)
	frame:EnableDrag(config.dragable)
	frame:SetMousePenetrable(config.penetrable)
	frame:Scale(config.scale, config.scale)

	frame.scale = config.scale
	frame.w, frame.h = frame:GetSize()
	frame.dragW = (nWidth) == 0 and 200 or (nWidth * config.scale)
	frame.dragH = (nItemH) == 0 and 200 or (nItemH * config.scale)
	D.UpdateAnchor(frame)
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
			x, deltaX = W - w, - w
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

MY_TargetMon_Base = class()

function MY_TargetMon_Base.OnFrameCreate()
	this.hTotal = this:Lookup("", "")
	this.hList = this:Lookup("", "Handle_List")
	this.hList.FormatAllItemPosExt = FormatAllItemPosExt
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("HOT_KEY_RELOADED")
	this:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("MY_TARGET_MON_RELOAD")
	ReloadFrame(this)
end

function D.GeneMonItemData(level, iconid, enable)
	return MY_TargetMon.FormatMonItemStructure({
		enable = enable,
		iconid = iconid,
		levels = { [level] = { iconid = iconid } },
		ignoreLevel = true,
	})
end

do
local needFormatItemPos
local l_tBuffTime = setmetatable({}, { __mode = "v" })
local function UpdateItem(hItem, KTarget, buff, szName, tItem, config, nFrameCount, targetChanged, dwOwnerID)
	if config.type == 'BUFF' and buff then
		-- 加入同名BUFF列表
		if not hItem.mon.ids[buff.dwID] or not hItem.mon.ids[buff.dwID].levels[buff.nLevel] then
			if not hItem.mon.ids[buff.dwID] then
				hItem.mon.ids[buff.dwID] = D.GeneMonItemData(buff.nLevel, Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13, hItem.mon.ignoreId)
			elseif not hItem.mon.ids[buff.dwID].levels[buff.nLevel] then
				hItem.mon.ids[buff.dwID].levels[buff.nLevel] = MY_TargetMon.FormatMonItemLevelStructure({
					enable = hItem.mon.ids[buff.dwID].ignoreLevel,
					iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13,
				})
			end
			local id = buff.dwID
			local level = (hItem.mon.ignoreId or hItem.mon.ids[id].ignoreLevel) and "all" or buff.nLevel
			if not tItem[id] then
				tItem[id] = {}
			end
			if not tItem[id][level] then
				tItem[id][level] = {}
			end
			tItem[id][level][hItem] = true
		end
		if not hItem.mon.ignoreId and not hItem.mon.ids[buff.dwID].enable then
			return
		end
		if not hItem.mon.ignoreId and not hItem.mon.ids[buff.dwID].ignoreLevel
		and not hItem.mon.ids[buff.dwID].levels[buff.nLevel].enable then
			return
		end
		if hItem.nRenderFrame == nFrameCount then
			return
		end
		-- 处理新出现的BUFF
		if hItem.mon.iconid == 13 then
			hItem.mon.iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
		end
		if hItem.mon.ids[buff.dwID].iconid == 13 then
			-- 计算图标 名字 ID等
			if tonumber(hItem.mon.name) == buff.dwID then
				hItem.mon.name = szName
				hItem.txtName:SetText(hItem.mon.longAlias or szName)
				hItem.txtShortName:SetText(hItem.mon.shortAlias or szName)
			end
			hItem.mon.ids[buff.dwID].iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
		end
		if hItem.mon.ids[buff.dwID].levels[buff.nLevel].iconid == 13 then
			hItem.mon.ids[buff.dwID].levels[buff.nLevel].iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
		end
		-- 刷新BUFF图标
		local iconid
		if not hItem.mon.ignoreId then
			if not hItem.mon.ids[buff.dwID].ignoreLevel then
				iconid = hItem.mon.ids[buff.dwID].levels[buff.nLevel].iconid
			end
			if not iconid or iconid == 13 then
				iconid = hItem.mon.ids[buff.dwID].iconid
			end
		end
		if not iconid or iconid == 13 then
			iconid = hItem.mon.iconid or 13
		end
		hItem.box:SetObjectIcon(iconid)
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
		-- 倒计时 与 BUFF层数堆叠
		hItem.txtProcess:SetText(szTimeLeft)
		hItem.box:SetOverText(1, szTimeLeft)
		hItem.box:SetOverText(0, buff.nStackNum == 1 and "" or buff.nStackNum)
		-- CD百分比
		local fPercent = nTimeLeft / nBuffTime
		hItem.imgProcess:SetPercentage(fPercent)
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
		end
		if config.cdCircle then
			hItem.box:SetCoolDownPercentage(fPercent)
		else
			if hItem.box.__SetObjectCoolDown then
				hItem.box:__SetObjectCoolDown(false)
				hItem.box:__SetCoolDownPercentage(1)
			else
				hItem.box:SetObjectCoolDown(false)
				hItem.box:SetCoolDownPercentage(1)
			end
		end
		if config.hideVoid and not hItem:IsVisible() then
			needFormatItemPos = true
			hItem:Show()
		end
		-- 缓存数据更新
		hItem.dwID = buff.dwID
		hItem.nLevel = buff.nLevel
		hItem.nTimeLeft = nTimeLeft
		hItem.nRenderFrame = nFrameCount
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
			hItem.box:SetObjectCoolDown(true)
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
		if config.cdReadySpark and hItem.nRenderFrame and hItem.nRenderFrame >= 0 and hItem.nRenderFrame ~= nFrameCount and not targetChanged then
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

local function CancelBuff(hItem)
	if not hItem or not hItem.mon then
		return
	end
	local config = hItem:GetRoot().config
	if not config or config.type ~= 'BUFF' then
		return
	end
	local KTarget = MY.GetObject(GetTarget(config.target, config.type))
	if not KTarget then
		return
	end
	MY.CancelBuff(KTarget, hItem.mon.id == 'common' and hItem.mon.name or hItem.mon.id)
end

function MY_TargetMon_Base.OnFrameBreathe()
	local dwType, dwID = GetTarget(this.config.target, this.config.type)
	if dwType == this.dwType and dwID == this.dwID
	and dwType ~= TARGET.PLAYER and dwType ~= TARGET.NPC then
		return
	end
	needFormatItemPos = false
	local hTotal, hList = this.hTotal, this.hList
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
					-- 先按ID和等级严格匹配（顺序不可颠倒）
					local tItems = this.tItem[buff.dwID] and this.tItem[buff.dwID][buff.nLevel]
					if tItems then
						for hItem, _ in pairs(tItems) do
							UpdateItem(hItem, KTarget, buff, szName, this.tItem, config, nFrameCount, targetChanged)
						end
					end
					-- 再按照ID匹配
					local tItems = this.tItem[buff.dwID] and this.tItem[buff.dwID]["all"]
					if tItems then
						for hItem, _ in pairs(tItems) do
							UpdateItem(hItem, KTarget, buff, szName, this.tItem, config, nFrameCount, targetChanged)
						end
					end
					-- 再按照名字匹配
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
			hList:SetW(this.w)
			hList:FormatAllItemPosExt()
			hList:SetSizeByAllItemSize()
			hTotal:SetSizeByAllItemSize()
		end
	end
	this.dwType, this.dwID = dwType, dwID
end
end

function MY_TargetMon_Base.OnFrameDragEnd()
	D.SaveAnchor(this)
end

function MY_TargetMon_Base.OnItemRButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Box_Default' and frame.config.type == 'BUFF' then
		CancelBuff(this:GetParent():GetParent())
	end
end

function MY_TargetMon_Base.OnItemMouseEnter()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.config.type
	if name == 'Box_Default' then
		if eMonType == 'BUFF' then
			local hItem = this:GetParent():GetParent()
			local w, h = hItem:GetW(), hItem:GetH()
			local x, y = hItem:GetAbsX(), hItem:GetAbsY()
			MY.OutputBuffTip(hItem.dwID, hItem.nLevel, {x, y, w, h}, hItem.nTimeLeft)
		end
		this:SetObjectMouseOver(1)
	end
end

function MY_TargetMon_Base.OnItemMouseLeave()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.config.type
	if name == 'Box_Default' then
		if eMonType == 'BUFF' then
			HideTip()
		end
		this:SetObjectMouseOver(0)
	end
end

function MY_TargetMon_Base.OnItemLButtonDown()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.config.type
	if name == 'Box_Default' then
		this:SetObjectPressed(1)
	end
end
MY_TargetMon_Base.OnItemRButtonDown = MY_TargetMon_Base.OnItemLButtonDown

function MY_TargetMon_Base.OnItemLButtonUp()
	local name = this:GetName()
	local frame = this:GetRoot()
	local eMonType = frame.config.type
	if name == 'Box_Default' then
		this:SetObjectPressed(0)
	end
end
MY_TargetMon_Base.OnItemRButtonUp = MY_TargetMon_Base.OnItemLButtonUp

do
local function OnSkillItem(tItems, dwID, dwLevel)
	for hItem, _ in pairs(tItems) do
		if not hItem.mon.ids[dwID] then
			if not hItem.mon.iconid or hItem.mon.iconid == 13 then
				hItem.mon.iconid = Table_GetSkillIconID(dwID, dwLevel)
			end
			hItem.mon.ids[dwID] = D.GeneMonItemData(dwLevel, Table_GetSkillIconID(dwID, dwLevel), hItem.mon.ignoreId)
		end
	end
end
local function OnSkill(this, dwID, dwLevel)
	local szName = Table_GetSkillName(dwID, dwLevel)
	local tItems = this.tItem[szName]
	if tItems then
		OnSkillItem(tItems, dwID, dwLevel)
	end
	local tItems = this.tItem[dwID] and this.tItem[dwID]["all"]
	if tItems then
		OnSkillItem(tItems, dwID, dwLevel)
	end
	local tItems = this.tItem[dwID] and this.tItem[dwID][dwLevel]
	if tItems then
		OnSkillItem(tItems, dwID, dwLevel)
	end
end

function MY_TargetMon_Base.OnEvent(event)
	if event == "HOT_KEY_RELOADED" then
		D.UpdateHotkey(this)
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
		D.OpenFrame(this.config)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		this:SetH(this.dragH)
		this:Lookup('', 'Handle_List'):SetAlpha(90)
		UpdateCustomModeWindow(this, this.config.caption, this.config.penetrable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		this:SetH(this.h)
		this:Lookup('', 'Handle_List'):SetAlpha(255)
		UpdateCustomModeWindow(this, this.config.caption, this.config.penetrable)
		if this.config.dragable then
			this:EnableDrag(true)
		end
		MY_TargetMon_Base.OnFrameDragEnd()
	elseif event == "MY_TARGET_MON_RELOAD" then
		if this.config ~= arg0 then
			return
		end
		ReloadFrame(this)
	elseif event == "UI_SCALED" then
		D.UpdateAnchor(this)
	end
end
end
