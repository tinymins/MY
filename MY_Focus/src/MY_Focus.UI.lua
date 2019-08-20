--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 焦点列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Focus'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Focus'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2012800) then
	return
end
local INI_PATH = PACKET_INFO.ROOT .. 'MY_Focus/ui/MY_Focus.ini'
local D = {
	GetDisplayList     = MY_Focus.GetDisplayList    ,
	IsShielded         = MY_Focus.IsShielded        ,
	SortFocus          = MY_Focus.SortFocus         ,
	RescanNearby       = MY_Focus.RescanNearby      ,
	RemoveFocusID      = MY_Focus.RemoveFocusID     ,
	OnObjectEnterScene = MY_Focus.OnObjectEnterScene,
	OnObjectLeaveScene = MY_Focus.OnObjectLeaveScene,
}
local TEMP_TARGET_TYPE, TEMP_TARGET_ID
local l_dwLockType, l_dwLockID, l_lockInDisplay

function D.AdjustScaleRatio(frame, hList)
	local hTotal = frame:Lookup('', '')
	local hList = hTotal:Lookup('Handle_List')
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		-- 导航保持比例
		local hL = hItem:Lookup('Handle_L')
		local nDeltaX = hL:GetH() / 70 * 50 - hL:GetW()
		local fScaleL = 1 + nDeltaX / hL:GetW()
		hL:Scale(fScaleL, 1)
		local hR = hItem:Lookup('Handle_R')
		local fScaleR = (hItem:GetW() - hL:GetW()) / hR:GetW()
		hR:Scale(fScaleR, 1)
		hR:SetRelX(hL:GetW())
		hItem:FormatAllItemPos()
		-- 图标保持比例
		local hInfoList = hItem:Lookup('Handle_R/Handle_InfoList')
		for i = 0, hInfoList:GetItemCount() - 1 do
			local hInfo = hInfoList:Lookup(i)
			hInfo:Scale(hInfo:GetH() / hInfo:GetW(), 1)
		end
		hInfoList:FormatAllItemPos()
		-- 字体大小
		UI(hItem):find('.Text'):fontScale(frame.fScaleY)
	end
	local nW, nH = hTotal:Lookup('Image_Title'):GetSize()
	hTotal:Lookup('Text_Title'):SetRelX(nH * 1.1)
	local btnSetting = frame:Lookup('Btn_Setting')
	btnSetting:SetRelX(nH * 0.2)
	btnSetting:Scale(btnSetting:GetH() / btnSetting:GetW(), 1)
	local btnClose = frame:Lookup('Btn_Close')
	btnClose:SetRelX(nW - nH)
	btnClose:Scale(btnClose:GetH() / btnClose:GetW(), 1)
	local chkMinimize = frame:Lookup('CheckBox_Minimize')
	chkMinimize:Scale(chkMinimize:GetH() / chkMinimize:GetW(), 1)
	chkMinimize:SetRelX(btnClose:GetRelX() - chkMinimize:GetW() - nH * 0.1)
	hTotal:FormatAllItemPos()
end

function D.Scale(frame)
	if frame.fScaleX and frame.fScaleY then
		frame:Scale(1 / frame.fScaleX, 1 / frame.fScaleY)
	end
	frame.fScaleX = MY_Focus.fScaleX
	frame.fScaleY = MY_Focus.fScaleY
	frame:Scale(frame.fScaleX, frame.fScaleY)
	UI(frame):find('.Text'):fontScale(frame.fScaleY)
	D.AdjustScaleRatio(frame)
end

function D.CreateList(frame)
	local hList = frame:Lookup('', 'Handle_List')
	hList:Clear()
	for i = 1, MY_Focus.nMaxDisplay do
		local hItem = hList:AppendItemFromIni(INI_PATH, 'Handle_Info')
		if frame.fScaleX and frame.fScaleY then
			hItem:Scale(frame.fScaleX, frame.fScaleY)
		end
		hItem:Hide()
	end
	hList:FormatAllItemPos()
	D.AdjustScaleRatio(frame)
end

function D.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_FocusUI')
end

function D.Close()
	local hFrame = D.GetFrame()
	if hFrame then
		Wnd.CloseWindow(hFrame)
	end
end

function D.GetFrame(szWnd, szItem)
	if szWnd then
		if szItem then
			return Station.Lookup('Normal/MY_FocusUI/' .. szWnd, szItem)
		else
			return Station.Lookup('Normal/MY_FocusUI/' .. szWnd)
		end
	else
		return Station.Lookup('Normal/MY_FocusUI')
	end
end

-- 自适应调整界面大小
function D.AutosizeUI(frame)
	local nHeight = 0
	local hList = frame:Lookup('', 'Handle_List')
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		if hItem:IsVisible() then
			nHeight = nHeight + hItem:GetH()
		end
	end
	hList:SetH(nHeight)
	hList:SetVisible(not MY_Focus.bMinimize)
	frame:SetVisible(nHeight > 0 or not MY_Focus.bAutoHide)
	frame:SetH((MY_Focus.bMinimize and 0 or nHeight) + frame:Lookup('', 'Image_Title'):GetH())
end

-- 绘制指定的焦点Handle
function D.UpdateItem(hItem, p)
	local dwType, dwID = p.dwType, p.dwID
	local szVia, tRule = p.szVia, p.tRule
	local bDeletable = p.bDeletable
	local KObject, info, bInfo = LIB.GetObject(dwType, dwID)
	local szName = tRule and LIB.ReplaceSensitiveWord(tRule.szDisplay)
	if not szName or szName == '' then
		szName = LIB.GetObjectName(KObject)
	end
	local player = GetClientPlayer()
	if not KObject then
		return
	end
	hItem.dwType = dwType
	hItem.dwID = dwID
	hItem.szVia = szVia
	hItem.bDeletable = bDeletable

	---------- 左侧 ----------
	-- 小图标列表
	local hInfoList = hItem:Lookup('Handle_R/Handle_InfoList')
	-- 锁定
	hInfoList:Lookup('Handle_Lock'):Hide()
	if dwType == l_dwLockType and dwID == l_dwLockID then
		l_lockInDisplay = true
		hInfoList:Lookup('Handle_Lock'):Show()
	end
	-- 心法
	hInfoList:Lookup('Handle_Kungfu'):Hide()
	if dwType == TARGET.PLAYER then
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_L/Handle_KungfuName/Text_Kungfu'):SetText(LIB.GetKungfuName(info.dwMountKungfuID))
			hInfoList:Lookup('Handle_Kungfu'):Show()
			hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = KObject.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_L/Handle_KungfuName/Text_Kungfu'):SetText(LIB.GetKungfuName(kungfu.dwSkillID))
				hInfoList:Lookup('Handle_Kungfu'):Show()
				hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				hItem:Lookup('Handle_L/Handle_KungfuName/Text_Kungfu'):SetText(g_tStrings.tForceTitle[KObject.dwForceID])
				hInfoList:Lookup('Handle_Kungfu'):Show()
				hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromUITex(GetForceImage(KObject.dwForceID))
			end
		end
	else
		hItem:Lookup('Handle_L/Handle_KungfuName/Text_Kungfu'):SetText('')
	end
	-- 阵营
	hInfoList:Lookup('Handle_Camp'):Hide()
	if dwType == TARGET.PLAYER
	and (KObject.nCamp == CAMP.GOOD or KObject.nCamp == CAMP.EVIL) then
		hInfoList:Lookup('Handle_Camp'):Show()
		hInfoList:Lookup('Handle_Camp/Image_Camp'):FromUITex(LIB.GetCampImage(KObject.nCamp, KObject.bCampFlag))
	end
	-- 标记
	hInfoList:Lookup('Handle_Mark'):Hide()
	local KTeam = GetClientTeam()
	if KTeam and LIB.IsInParty() then
		local tMark = KTeam.GetTeamMark()
		if tMark then
			local nMarkID = tMark[dwID]
			if nMarkID then
				hInfoList:Lookup('Handle_Mark'):Show()
				hInfoList:Lookup('Handle_Mark/Image_Mark'):FromUITex(PARTY_MARK_ICON_PATH, PARTY_MARK_ICON_FRAME_LIST[nMarkID])
			end
		end
	end
	-- 小本本
	hInfoList:Lookup('Handle_Anmerkungen'):SetVisible(szVia == _L['Anmerkungen'])
	hInfoList:FormatAllItemPos()

	-- 目标距离
	local nDistance = 0
	if player then
		nDistance = floor(LIB.GetDistance(player, KObject, MY_Focus.szDistanceType) * 10) / 10
	end
	hItem:Lookup('Handle_L/Handle_Compass/Compass_Distance'):SetText(nDistance)
	hItem:Lookup('Handle_L/Handle_School/School_Distance'):SetText(nDistance)
	-- 自身面向
	if player then
		hItem:Lookup('Handle_L/Handle_Compass/Image_Player'):Show()
		hItem:Lookup('Handle_L/Handle_Compass/Image_Player'):SetRotate( - player.nFaceDirection / 128 * math.pi)
	end
	-- 左侧主要部分
	if MY_Focus.bDisplayKungfuIcon and dwType == TARGET.PLAYER then
		hItem:Lookup('Handle_L/Handle_Compass'):Hide()
		hItem:Lookup('Handle_L/Handle_School'):Show()
		-- 心法图标
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_L/Handle_School/Image_School'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = KObject.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_L/Handle_School/Image_School'):FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				hItem:Lookup('Handle_L/Handle_School/Image_School'):FromUITex(GetForceImage(KObject.dwForceID))
			end
		end
	else
		hItem:Lookup('Handle_L/Handle_School'):Hide()
		hItem:Lookup('Handle_L/Handle_Compass'):Show()
		-- 相对位置
		hItem:Lookup('Handle_L/Handle_Compass/Image_PointRed'):Hide()
		hItem:Lookup('Handle_L/Handle_Compass/Image_PointGreen'):Hide()
		if player and nDistance > 0 then
			local h
			if LIB.IsEnemy(UI_GetClientPlayerID(), dwID) then
				h = hItem:Lookup('Handle_L/Handle_Compass/Image_PointRed')
			else
				h = hItem:Lookup('Handle_L/Handle_Compass/Image_PointGreen')
			end
			h:Show()
			local nRotate = 0
			-- 特判角度
			if player.nX == KObject.nX then
				if player.nY > KObject.nY then
					nRotate = math.pi / 2
				else
					nRotate = - math.pi / 2
				end
			else
				nRotate = math.atan((player.nY - KObject.nY) / (player.nX - KObject.nX))
			end
			if nRotate < 0 then
				nRotate = nRotate + math.pi
			end
			if KObject.nY < player.nY then
				nRotate = math.pi + nRotate
			end
			local nRadius = 13.5
			h:SetRelPos((nRadius + nRadius * math.cos(nRotate) + 2) * MY_Focus.fScaleY, (nRadius - 3 - 13.5 * math.sin(nRotate)) * MY_Focus.fScaleY)
			h:GetParent():FormatAllItemPos()
		end
	end
	---------- 右侧 ----------
	-- 名字
	hItem:Lookup('Handle_R/Handle_LMN/Text_Name'):SetText(szName or KObject.dwID)
	-- 血量
	if dwType ~= TARGET.DOODAD then
		local nCurrentLife, nMaxLife = info.nCurrentLife, info.nMaxLife
		local nCurrentMana, nMaxMana = info.nCurrentMana, info.nMaxMana
		local szLife = LIB.FormatNumberDot(nCurrentLife, 1, false, true)
		if nMaxLife > 0 then
			local nPercent = floor(nCurrentLife / nMaxLife * 100)
			if nPercent > 100 then
				nPercent = 100
			end
			szLife = szLife .. '(' .. nPercent .. '%)'
			hItem:Lookup('Handle_R/Handle_LMN/Image_Health'):SetPercentage(nCurrentLife / nMaxLife)
			hItem:Lookup('Handle_R/Handle_LMN/Text_Health'):SetText(szLife)
		end
		if nMaxMana > 0 then
			hItem:Lookup('Handle_R/Handle_LMN/Image_Mana'):SetPercentage(nCurrentMana / nMaxMana)
			hItem:Lookup('Handle_R/Handle_LMN/Text_Mana'):SetText(LIB.FormatNumberDot(nCurrentMana, 1, false, true) .. '/' .. LIB.FormatNumberDot(nMaxMana, 1, false, true))
		end
	end
	-- 读条
	if dwType ~= TARGET.DOODAD then
		local nType, dwSkillID, dwSkillLevel, fProgress = KObject.GetSkillOTActionState()
		if MY_Focus.bTraversal and dwType == TARGET.PLAYER
		and (
			nType ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			and nType ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
			and KObject.GetOTActionState() == 1
		) then
			LIB.WithTarget(dwType, dwID, function()
				local nType, dwSkillID, dwSkillLevel, fProgress = KObject.GetSkillOTActionState()
				if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
					hItem:Lookup('Handle_R/Handle_Progress/Image_Progress'):SetPercentage(fProgress)
					hItem:Lookup('Handle_R/Handle_Progress/Text_Progress'):SetText((LIB.GetSkillName(dwSkillID, dwSkillLevel)))
				else
					hItem:Lookup('Handle_R/Handle_Progress/Image_Progress'):SetPercentage(0)
					hItem:Lookup('Handle_R/Handle_Progress/Text_Progress'):SetText('')
				end
			end)
		else
			if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
				hItem:Lookup('Handle_R/Handle_Progress/Image_Progress'):SetPercentage(fProgress)
				hItem:Lookup('Handle_R/Handle_Progress/Text_Progress'):SetText((LIB.GetSkillName(dwSkillID, dwSkillLevel)))
			else
				hItem:Lookup('Handle_R/Handle_Progress/Image_Progress'):SetPercentage(0)
				hItem:Lookup('Handle_R/Handle_Progress/Text_Progress'):SetText('')
			end
		end
	end
	-- 目标的目标
	if MY_Focus.bShowTarget and dwType ~= TARGET.DOODAD then
		local tp, id = KObject.GetTarget()
		local tar = LIB.GetObject(tp, id)
		if tar then
			hItem:Lookup('Handle_R/Handle_Progress/Text_Target'):SetText(LIB.GetObjectName(tar))
		else
			hItem:Lookup('Handle_R/Handle_Progress/Text_Target'):SetText('')
		end
	end
	-- 选中状态
	hItem:Lookup('Image_Select'):Hide()
	if player then
		local dwTargetType, dwTargetID = player.GetTarget()
		if dwTargetType == dwType and dwTargetID == dwID then
			hItem:Lookup('Image_Select'):Show()
		end
	end
	hItem:FormatAllItemPos()
end

-- 更新列表
local NAVIGATOR_CACHE = {}
function D.UpdateList(frame)
	l_lockInDisplay = false
	local nCount = 0
	local tKeep = {}
	local hList = frame:Lookup('', 'Handle_List')
	local aList = D.GetDisplayList()
	for i = 1, hList:GetItemCount() do
		local p = aList[i]
		local hItem = hList:Lookup(i - 1)
		if p then
			if not hItem:IsVisible() then
				hItem:Show()
			end
			D.UpdateItem(hItem, p)
			if MY_Focus.bEnableSceneNavi and Navigator_SetID then
				local szKey = 'MY_FOCUS.' .. p.dwType .. '_' .. p.dwID
				local szText = p.tRule and p.tRule.szDisplay ~= '' and LIB.ReplaceSensitiveWord(p.tRule.szDisplay) or p.szName
				if NAVIGATOR_CACHE[szKey] ~= szText then
					Navigator_SetID(szKey, p.dwType, p.dwID, szText)
				end
				tKeep[szKey] = szText
			end
			nCount = nCount + 1
		elseif hItem:IsVisible() then
			hItem:Hide()
		end
	end
	if frame.nCount ~= nCount then
		D.AutosizeUI(frame)
		frame.nCount = nCount
	end
	if Navigator_Remove then
		for szKey, _ in pairs(NAVIGATOR_CACHE) do
			if not tKeep[szKey] then
				Navigator_Remove(szKey)
			end
		end
	end
	NAVIGATOR_CACHE = tKeep
end

-- ########################################################################## --
--                                     #                 #         #          --
--                           # # # # # # # # # # #       #   #     #          --
--   # #     # # # # # # #       #     #     #         #     #     #          --
--     #     #       #           # # # # # # #         #     # # # # # # #    --
--     #     #       #                 #             # #   #       #          --
--     #     #       #         # # # # # # # # #       #           #          --
--     #     #       #                 #       #       #           #          --
--     #     #       #       # # # # # # # # # # #     #   # # # # # # # #    --
--     #     #       #                 #       #       #           #          --
--       # #     # # # # #     # # # # # # # # #       #           #          --
--                                     #               #           #          --
--                                   # #               #           #          --
-- ########################################################################## --
-- 周期重绘
function D.OnFrameBreathe()
	if not D.IsShielded() then
		if l_dwLockType and l_dwLockID and l_lockInDisplay then
			local dwType, dwID = LIB.GetTarget()
			if dwType ~= l_dwLockType or dwID ~= l_dwLockID then
				LIB.SetTarget(l_dwLockType, l_dwLockID)
			end
		end
		if MY_Focus.bSortByDistance then
			D.SortFocus()
		end
	end
	D.UpdateList(this)
end

function D.OnFrameCreate()
	this:RegisterEvent('PARTY_SET_MARK')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('PLAYER_ENTER_SCENE')
	this:RegisterEvent('NPC_ENTER_SCENE')
	this:RegisterEvent('DOODAD_ENTER_SCENE')
	this:RegisterEvent('PLAYER_LEAVE_SCENE')
	this:RegisterEvent('NPC_LEAVE_SCENE')
	this:RegisterEvent('DOODAD_LEAVE_SCENE')
	this:RegisterEvent('MY_SET_IMPORTANT_NPC')
	this:RegisterEvent('MY_FOCUS_LOCK_UPDATE')
	this:RegisterEvent('MY_FOCUS_SCALE_UPDATE')
	this:RegisterEvent('MY_FOCUS_MAX_DISPLAY_UPDATE')
	this:RegisterEvent('MY_FOCUS_AUTO_HIDE_UPDATE')
	this:RegisterEvent('MY_FOCUS_MINIMIZE_UPDATE')
	this:Lookup('', 'Text_Title'):SetText(_L['Focus list'])

	D.Scale(this)
	D.CreateList(this)
	D.OnEvent('UI_SCALED')
	D.RescanNearby()
end

function D.OnFrameDestroy()
	if Navigator_Remove then
		for szKey, _ in pairs(NAVIGATOR_CACHE) do
			Navigator_Remove(szKey)
		end
		NAVIGATOR_CACHE = {}
	end
end

function D.OnEvent(event)
	if event == 'PARTY_SET_MARK' then
		D.UpdateList(this)
	elseif event == 'UI_SCALED' then
		UI(this):anchor(MY_Focus.anchor)
	elseif event == 'PLAYER_ENTER_SCENE' then
		D.OnObjectEnterScene(TARGET.PLAYER, arg0)
	elseif event == 'NPC_ENTER_SCENE' then
		D.OnObjectEnterScene(TARGET.NPC, arg0)
	elseif event == 'DOODAD_ENTER_SCENE' then
		D.OnObjectEnterScene(TARGET.DOODAD, arg0)
	elseif event == 'PLAYER_LEAVE_SCENE' then
		D.OnObjectLeaveScene(TARGET.PLAYER, arg0)
	elseif event == 'NPC_LEAVE_SCENE' then
		D.OnObjectLeaveScene(TARGET.NPC, arg0)
	elseif event == 'DOODAD_LEAVE_SCENE' then
		D.OnObjectLeaveScene(TARGET.DOODAD, arg0)
	elseif event == 'MY_SET_IMPORTANT_NPC' then
		D.RescanNearby()
	elseif event == 'MY_FOCUS_LOCK_UPDATE' then
		D.UpdateList(this)
	elseif event == 'MY_FOCUS_SCALE_UPDATE' then
		D.Scale(this)
	elseif event == 'MY_FOCUS_MAX_DISPLAY_UPDATE' then
		D.CreateList(this)
	elseif event == 'MY_FOCUS_AUTO_HIDE_UPDATE' then
		D.AutosizeUI(this)
	elseif event == 'MY_FOCUS_MINIMIZE_UPDATE' then
		D.AutosizeUI(this)
	end
end

function D.OnFrameDragSetPosEnd()
	this:CorrectPos()
	MY_Focus.anchor = UI(this):anchor('TOPRIGHT')
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Info' then
		this:Lookup('Image_Hover'):Show()
		if MY_Focus.bHealHelper then
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = LIB.GetTarget()
			LIB.SetTarget(this.dwType, this.dwID)
		end
		D.OnItemRefreshTip()
	end
end

function D.OnItemRefreshTip()
	local name = this:GetName()
	if name == 'Handle_Info' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		LIB.OutputObjectTip({ x, y, w, h }, this.dwType, this.dwID, GetFormatText(_L['Via:'] .. this.szVia .. '\n', 82))
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_Info' then
		if this:Lookup('Image_Hover') then
			if MY_Focus.bHealHelper and TEMP_TARGET_TYPE and TEMP_TARGET_ID then
				LIB.SetTarget(TEMP_TARGET_TYPE, TEMP_TARGET_ID)
				TEMP_TARGET_TYPE, TEMP_TARGET_ID = nil
			end
			this:Lookup('Image_Hover'):Hide()
		end
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Info' then
		if MY_Focus.bHealHelper then
			TEMP_TARGET_TYPE, TEMP_TARGET_ID = nil
		end
		LIB.SetTarget(this.dwType, this.dwID)
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Info' then
		local dwType, dwID = this.dwType, this.dwID
		local t = LIB.GetTargetContextMenu(dwType, this:Lookup('Handle_R/Handle_LMN/Text_Name'):GetText(), dwID)
		if this.bDeletable then
			table.insert(t, 1, {
				szOption = _L['Delete focus'],
				fnAction = function()
					if l_dwLockType == dwType and l_dwLockID == dwID then
						l_dwLockType = nil
						l_dwLockID = nil
					end
					D.RemoveFocusID(dwType, dwID)
				end,
			})
		else
			table.insert(t, 1, {
				szOption = _L['Option'],
				fnAction = function()
					LIB.ShowPanel()
					LIB.FocusPanel()
					LIB.SwitchTab('MY_Focus')
				end,
			})
		end
		local bLock = dwType == l_dwLockType and dwID == l_dwLockID
		table.insert(t, {
			szOption = bLock and _L['Unlock focus'] or _L['Lock focus'],
			fnAction = function()
				if bLock then
					l_dwLockID = nil
					l_dwLockType = nil
				else
					l_dwLockID = dwID
					l_dwLockType = dwType
					LIB.SetTarget(dwType, dwID)
				end
				FireUIEvent('MY_FOCUS_LOCK_UPDATE')
			end,
		})
		PopupMenu(t)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		LIB.ShowPanel()
		LIB.FocusPanel()
		LIB.SwitchTab('MY_Focus')
	elseif name == 'Btn_Close' then
		D.Close()
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		MY_Focus.bMinimize = true
		FireUIEvent('MY_FOCUS_MINIMIZE_UPDATE')
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		MY_Focus.bMinimize = false
		FireUIEvent('MY_FOCUS_MINIMIZE_UPDATE')
	end
end

LIB.RegisterInit('MY_FOCUS', function()
	if MY_Focus.bEnable then
		D.Open()
	else
		D.Close()
	end
end)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open                 = D.Open                ,
				Close                = D.Close               ,
				OnFrameBreathe       = D.OnFrameBreathe      ,
				OnFrameCreate        = D.OnFrameCreate       ,
				OnFrameDestroy       = D.OnFrameDestroy      ,
				OnEvent              = D.OnEvent             ,
				OnFrameDragSetPosEnd = D.OnFrameDragSetPosEnd,
				OnItemMouseEnter     = D.OnItemMouseEnter    ,
				OnItemRefreshTip     = D.OnItemRefreshTip    ,
				OnItemMouseLeave     = D.OnItemMouseLeave    ,
				OnItemLButtonClick   = D.OnItemLButtonClick  ,
				OnItemRButtonClick   = D.OnItemRButtonClick  ,
				OnLButtonClick       = D.OnLButtonClick      ,
				OnCheckBoxCheck      = D.OnCheckBoxCheck     ,
				OnCheckBoxUncheck    = D.OnCheckBoxUncheck   ,
			},
		},
	},
}
MY_FocusUI = LIB.GeneGlobalNS(settings)
end
