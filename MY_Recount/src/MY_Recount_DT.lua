--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗统计 详情界面
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
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_Recount_DT.ini'
local STAT_TYPE = MY_Recount.STAT_TYPE
local STAT_TYPE_KEY = MY_Recount.STAT_TYPE_KEY
local STAT_TYPE_NAME = MY_Recount.STAT_TYPE_NAME
local SKILL_RESULT = MY_Recount.SKILL_RESULT
local SKILL_RESULT_NAME = MY_Recount.SKILL_RESULT_NAME

MY_Recount_DT = class()

function D.InsertFromText(aTabTalk, h)
	local aText = {}
	for i = 0, h:GetItemCount() - 1 do
		local p = h:Lookup(i)
		if p:GetType() == 'Text' then
			insert(aText, p:GetText())
		end
	end
	insert(aTabTalk, aText)
end

function D.GetDetailMenu(frame)
	local t = {}
	local DataDisplay = MY_Recount.GetDisplayData()
	local function Publish(nChannel, nLimit)
		local bDetail = frame:Lookup('', 'Handle_Spliter'):IsVisible()
		LIB.Talk(
			nChannel,
			'[' .. PACKET_INFO.SHORT_NAME .. ']'
			.. _L['fight recount'] .. ' - '
			.. frame:Lookup('', 'Text_Default'):GetText()
			.. ' ' .. ((DataDisplay.szBossName and ' - ' .. DataDisplay.szBossName) or '')
			.. '(' .. LIB.FormatTimeCounter(DataDisplay.nTimeDuring, '%M:%ss') .. ')',
			nil,
			true
		)
		LIB.Talk(nChannel, '------------------------------')

		local aTabTalk = {}
		D.InsertFromText(aTabTalk, frame:Lookup('WndScroll_Skill', 'Handle_SkillTitle'))
		local hList = frame:Lookup('WndScroll_Skill', 'Handle_SkillList')
		if bDetail then
			for i = 0, hList:GetItemCount() - 1 do
				local hItem = hList:Lookup(i)
				if hItem:Lookup('Shadow_SkillEntry'):IsVisible() then
					D.InsertFromText(aTabTalk, hItem)
					break
				end
			end
		else
			for i = 0, min(hList:GetItemCount(), nLimit) - 1 do
				D.InsertFromText(aTabTalk, hList:Lookup(i))
			end
		end
		LIB.TabTalk(nChannel, aTabTalk, {'L', 'L', 'R', 'R', 'R'})
		LIB.Talk(nChannel, '------------------------------')

		if bDetail then
			local aTabTalk = {}
			D.InsertFromText(aTabTalk, frame:Lookup('WndScroll_Detail', 'Handle_DetailTitle'))
			local hList = frame:Lookup('WndScroll_Detail', 'Handle_DetailList')
			for i = 0, hList:GetItemCount() - 1 do
				D.InsertFromText(aTabTalk, hList:Lookup(i))
			end
			LIB.TabTalk(nChannel, aTabTalk, {'L', 'L', 'R', 'R', 'R', 'R', 'R'})
			LIB.Talk(nChannel, '------------------------------')

			local aTabTalk = {}
			D.InsertFromText(aTabTalk, frame:Lookup('WndScroll_Target', 'Handle_TargetTitle'))
			local hList = frame:Lookup('WndScroll_Target', 'Handle_TargetList')
			for i = 0, min(hList:GetItemCount(), nLimit) - 1 do
				D.InsertFromText(aTabTalk, hList:Lookup(i))
			end
			LIB.TabTalk(nChannel, aTabTalk, {'L', 'L', 'R', 'R', 'R', 'R', 'R', 'R'})
			LIB.Talk(nChannel, '------------------------------')
		end
	end
	for nChannel, szChannel in pairs({
		[PLAYER_TALK_CHANNEL.RAID] = 'MSG_TEAM',
		[PLAYER_TALK_CHANNEL.TEAM] = 'MSG_PARTY',
		[PLAYER_TALK_CHANNEL.TONG] = 'MSG_GUILD',
	}) do
		local t1 = {
			szOption = g_tStrings.tChannelName[szChannel],
			bCheck = true, -- 不设置成可选框不能点╭∩╮(︶︿︶）╭∩╮垃圾
			fnAction = function()
				Publish(nChannel, HUGE)
				Wnd.CloseWindow('PopupMenuPanel')
			end,
			rgb = GetMsgFontColor(szChannel, true),
		}
		for _, nLimit in ipairs({1, 2, 3, 4, 5, 8, 10, 15, 20, 30, 50, 100}) do
			insert(t1, {
				szOption = _L('top %d', nLimit),
				fnAction = function() Publish(nChannel, nLimit) end,
			})
		end
		insert(t, t1)
	end

	return t
end

function MY_Recount_DT.OnFrameCreate()
	local frame = this
	local id, nChannel = this:GetName():match('^MY_Recount_DT#([^_]+)_(%d+)$')
	frame.id = tonumber(id) or id
	frame.nChannel = tonumber(nChannel)
	frame.bFirstRendering = true
	frame.szPrimarySort = ((frame.nChannel == STAT_TYPE.DPS or frame.nChannel == STAT_TYPE.HPS) and 'Skill') or 'Target'
	frame.szSecondarySort = ((frame.nChannel == STAT_TYPE.DPS or frame.nChannel == STAT_TYPE.HPS) and 'Target') or 'Skill'
	frame:Lookup('WndScroll_Target', 'Handle_TargetTitle/Text_TargetTitle_5'):SetText(g_tStrings.STR_HIT_NAME)
	frame:Lookup('WndScroll_Target', 'Handle_TargetTitle/Text_TargetTitle_6'):SetText(g_tStrings.STR_CS_NAME)
	frame:Lookup('WndScroll_Target', 'Handle_TargetTitle/Text_TargetTitle_7'):SetText(g_tStrings.STR_MSG_MISS)
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)

	local function canEsc()
		if frame and frame:IsValid() then
			return true
		else
			LIB.RegisterEsc(frame:GetName())
		end
	end
	local function onEsc()
		if frame.szSelectedSkill or frame.szSelectedTarget then
			frame.szSelectedSkill  = nil
			frame.szSelectedTarget = nil
		else
			LIB.RegisterEsc(frame:GetName())
			Wnd.CloseWindow(frame)
		end
	end
	LIB.RegisterEsc(frame:GetName(), canEsc, onEsc)
end

function MY_Recount_DT.OnFrameBreathe()
	if this.nLastRedrawFrame
	and GetLogicFrameCount() - this.nLastRedrawFrame > 0
	and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount_UI.nDrawInterval then
		return
	end
	this.nLastRedrawFrame = GetLogicFrameCount()

	local id        = this.id
	local szChannel = STAT_TYPE_KEY[this.nChannel]
	local DataDisplay = MY_Recount.GetDisplayData()
	if tonumber(id) then
		id = tonumber(id)
	end

	-- 更新标题
	local szName = IsString(id) and id or MY_Recount_DS.GetNameAusID(DataDisplay, id)
	this:Lookup('', 'Text_Default'):SetText(szName .. ' ' .. STAT_TYPE_NAME[this.nChannel])

	-- 获取数据
	local tData = MY_Recount_DS.GetMergeTargetData(DataDisplay, szChannel, id, MY_Recount_UI.bGroupSameNpc, MY_Recount_UI.bGroupSameEffect)
	if not tData then
		this:Lookup('WndScroll_Detail', 'Handle_DetailList'):Clear()
		this:Lookup('WndScroll_Skill' , 'Handle_SkillList' ):Clear()
		this:Lookup('WndScroll_Target', 'Handle_TargetList'):Clear()
		return
	end

	local szPrimarySort   = this.szPrimarySort or 'Skill'
	local szSecondarySort = (szPrimarySort == 'Skill' and 'Target') or 'Skill'

	--------------- 一、技能列表更新 -----------------
	-- 数据收集
	local aResult, nTotal = {}, MY_Recount_UI.bShowEffect and tData.nTotalEffect or tData.nTotal
	if szPrimarySort == 'Skill' then
		for szEffectID, p in pairs(tData.Skill) do
			local rec = {
				szKey  = szEffectID,
				szName = MY_Recount_DS.GetEffectNameAusID(DataDisplay, szEffectID) or szEffectID,
				nCount = not MY_Recount_UI.bShowZeroVal and p.nNzCount or p.nCount,
				nTotal = MY_Recount_UI.bShowEffect and p.nTotalEffect or p.nTotal,
			}
			if MY_Recount_UI.bShowZeroVal or rec.nTotal > 0 then
				insert(aResult, rec)
			end
		end
	else
		for id, p in pairs(tData.Target) do
			local rec = {
				szKey  = id                              ,
				szName = IsString(id) and id or MY_Recount_DS.GetNameAusID(DataDisplay, id),
				nCount = not MY_Recount_UI.bShowZeroVal and p.nNzCount or p.nCount,
				nTotal = MY_Recount_UI.bShowEffect and p.nTotalEffect or p.nTotal,
			}
			if MY_Recount_UI.bShowZeroVal or rec.nTotal > 0 then
				insert(aResult, rec)
			end
		end
	end
	sort(aResult, function(p1, p2) return p1.nTotal > p2.nTotal end)
	-- 默认选中第一个
	if this.bFirstRendering then
		if aResult[1] then
			if szPrimarySort == 'Skill' then
				this.szSelectedSkill  = aResult[1].szKey
			else
				this.szSelectedTarget = aResult[1].szKey
			end
		end
		this.bFirstRendering = nil
	end
	local szSelected
	local szSelectedSkill  = this.szSelectedSkill
	local szSelectedTarget = this.szSelectedTarget
	if szPrimarySort == 'Skill' then
		szSelected = this.szSelectedSkill
	else
		szSelected = this.szSelectedTarget
	end
	-- 界面重绘
	local hSelectedItem
	this:Lookup('WndScroll_Skill'):SetSize(480, 96)
	this:Lookup('WndScroll_Skill', ''):SetSize(480, 96)
	this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
	local hList = this:Lookup('WndScroll_Skill', 'Handle_SkillList')
	hList:SetSize(480, 80)
	for i, p in ipairs(aResult) do
		local hItem = hList:Lookup(i - 1) or hList:AppendItemFromIni(SZ_INI, 'Handle_SkillItem')
		hItem:Lookup('Text_SkillNo'):SetText(i)
		hItem:Lookup('Text_SkillName'):SetText(MY_Recount.GetTargetShowName(p.szName, szPrimarySort == 'Target' and p.dwForceID ~= -1))
		hItem:Lookup('Text_SkillCount'):SetText(not MY_Recount_UI.bShowZeroVal and p.nNzCount or p.nCount)
		hItem:Lookup('Text_SkillTotal'):SetText(p.nTotal)
		hItem:Lookup('Text_SkillPercentage'):SetText(nTotal > 0 and _L('%.1f%%', (i == 1 and ceil or floor)(p.nTotal / nTotal * 1000) / 10) or ' - ')

		if szPrimarySort == 'Skill' and szSelectedSkill == p.szKey or
		szPrimarySort == 'Target' and szSelectedTarget == p.szKey then
			hSelectedItem = hItem
			hItem:Lookup('Shadow_SkillEntry'):Show()
		else
			hItem:Lookup('Shadow_SkillEntry'):Hide()
		end
		hItem.szKey = p.szKey
	end
	for i = hList:GetItemCount() - 1, #aResult, -1 do
		hList:RemoveItem(i)
	end
	hList:FormatAllItemPos()

	if szSelected and tData[szPrimarySort][szSelected] then
		this:Lookup('', 'Handle_Spliter'):Show()
		--------------- 二、技能释放结果列表更新 -----------------
		-- 数据收集
		local aResult, nCountSum = {}, not MY_Recount_UI.bShowZeroVal and tData[szPrimarySort][szSelected].nNzCount or tData[szPrimarySort][szSelected].nCount
		local nTotal = tData[szPrimarySort][szSelected][MY_Recount_UI.bShowEffect and 'nTotalEffect' or 'nTotal']
		for nSkillResult, p in pairs(tData[szPrimarySort][szSelected].Detail) do
			local res = {
				nCount = not MY_Recount_UI.bShowZeroVal and p.nNzCount or p.nCount,
				nMin   = not MY_Recount_UI.bShowEffect
					and (not MY_Recount_UI.bShowZeroVal and p.nNzMin or p.nMin)
					or (not MY_Recount_UI.bShowZeroVal and p.nNzMinEffect or p.nMinEffect),
				nAvg   = not MY_Recount_UI.bShowEffect
					and (not MY_Recount_UI.bShowZeroVal and p.nNzAvg or p.nAvg)
					or (not MY_Recount_UI.bShowZeroVal and p.nNzAvgEffect or p.nAvgEffect),
				nMax   = MY_Recount_UI.bShowEffect and p.nMaxEffect or p.nMax,
				nTotal = MY_Recount_UI.bShowEffect and p.nTotalEffect or p.nTotal,
				szSkillResult = SKILL_RESULT_NAME[nSkillResult],
			}
			if res.nCount > 0 then
				insert(aResult, res)
			end
		end
		sort(aResult, function(p1, p2) return p1.nAvg > p2.nAvg end)
		-- 界面重绘
		this:Lookup('WndScroll_Detail'):Show()
		local hList = this:Lookup('WndScroll_Detail', 'Handle_DetailList')
		for i, p in ipairs(aResult) do
			local hItem = hList:Lookup(i - 1) or hList:AppendItemFromIni(SZ_INI, 'Handle_DetailItem')
			local nCount = not MY_Recount_UI.bShowZeroVal and p.nNzCount or p.nCount
			hItem:Lookup('Text_DetailNo'):SetText(i)
			hItem:Lookup('Text_DetailType'):SetText(p.szSkillResult)
			hItem:Lookup('Text_DetailMin'):SetText(p.nMin)
			hItem:Lookup('Text_DetailAverage'):SetText(p.nAvg)
			hItem:Lookup('Text_DetailMax'):SetText(p.nMax)
			hItem:Lookup('Text_DetailCount'):SetText(nCount)
			hItem:Lookup('Text_DetailPercent'):SetText(nCountSum > 0 and _L('%.1f%%', (i == 1 and ceil or floor)(nCount / nCountSum * 1000) / 10) or ' - ')
		end
		for i = hList:GetItemCount() - 1, #aResult, -1 do
			hList:RemoveItem(i)
		end
		hList:FormatAllItemPos()

		-- 调整滚动条 增强用户体验
		if hSelectedItem and not this:Lookup('WndScroll_Target'):IsVisible() then
			-- 说明是刚从未选择状态切换过来 滚动条滚动到选中项
			local hScroll = this:Lookup('WndScroll_Skill/Scroll_Skill_List')
			hScroll:SetScrollPos(math.ceil(hScroll:GetStepCount() * hSelectedItem:GetIndex() / hSelectedItem:GetParent():GetItemCount()))
		end

		--------------- 三、技能释放结果列表更新 -----------------
		-- 数据收集
		local aResult, nTotal = {}, tData[szPrimarySort][szSelected][MY_Recount_UI.bShowEffect and 'nTotalEffect' or 'nTotal']
		if szPrimarySort == 'Skill' then
			for id, p in pairs(tData.Skill[szSelectedSkill].Target) do
				local rec = {
					szKey          = id,
					nHitCount      = MY_Recount_UI.bShowZeroVal and (p.Count[SKILL_RESULT.HIT] or 0) or p.NzCount[SKILL_RESULT.HIT] or 0,
					nMissCount     = MY_Recount_UI.bShowZeroVal and (p.Count[SKILL_RESULT.MISS] or 0) or p.NzCount[SKILL_RESULT.MISS] or 0,
					nCriticalCount = MY_Recount_UI.bShowZeroVal and (p.Count[SKILL_RESULT.CRITICAL] or 0) or p.NzCount[SKILL_RESULT.CRITICAL] or 0,
					nMax           = MY_Recount_UI.bShowEffect and p.nMaxEffect or p.nMax,
					nTotal         = MY_Recount_UI.bShowEffect and p.nTotalEffect or p.nTotal,
					szName         = IsString(id) and id or MY_Recount_DS.GetNameAusID(DataDisplay, id),
				}
				if MY_Recount_UI.bShowZeroVal or rec.nTotal > 0 or rec.nMissCount > 0 then
					insert(aResult, rec)
				end
			end
		else
			for szEffectID, p in pairs(tData.Target[szSelectedTarget].Skill) do
				local rec = {
					nHitCount      = MY_Recount_UI.bShowZeroVal and (p.Count[SKILL_RESULT.HIT] or 0) or p.NzCount[SKILL_RESULT.HIT] or 0,
					nMissCount     = MY_Recount_UI.bShowZeroVal and (p.Count[SKILL_RESULT.MISS] or 0) or p.NzCount[SKILL_RESULT.MISS] or 0,
					nCriticalCount = MY_Recount_UI.bShowZeroVal and (p.Count[SKILL_RESULT.CRITICAL] or 0) or p.NzCount[SKILL_RESULT.CRITICAL] or 0,
					nMax           = MY_Recount_UI.bShowEffect and p.nMaxEffect or p.nMax,
					nTotal         = MY_Recount_UI.bShowEffect and p.nTotalEffect or p.nTotal,
					szName         = MY_Recount_DS.GetEffectNameAusID(DataDisplay, szEffectID) or szEffectID,
				}
				if MY_Recount_UI.bShowZeroVal or rec.nTotal > 0 or rec.nMissCount > 0 then
					insert(aResult, rec)
				end
			end
		end
		sort(aResult, function(p1, p2) return p1.nTotal > p2.nTotal end)
		-- 界面重绘
		this:Lookup('WndScroll_Target'):Show()
		local hList = this:Lookup('WndScroll_Target', 'Handle_TargetList')
		for i, p in ipairs(aResult) do
			local hItem = hList:Lookup(i - 1) or hList:AppendItemFromIni(SZ_INI, 'Handle_TargetItem')
			hItem:Lookup('Text_TargetNo'):SetText(i)
			hItem:Lookup('Text_TargetName'):SetText(MY_Recount.GetTargetShowName(p.szName, szPrimarySort == 'Skill' and p.dwForceID ~= -1))
			hItem:Lookup('Text_TargetTotal'):SetText(p.nTotal)
			hItem:Lookup('Text_TargetMax'):SetText(p.nMax)
			hItem:Lookup('Text_TargetHit'):SetText(p.nHitCount)
			hItem:Lookup('Text_TargetCritical'):SetText(p.nCriticalCount)
			hItem:Lookup('Text_TargetMiss'):SetText(p.nMissCount)
			hItem:Lookup('Text_TargetPercent'):SetText((nTotal > 0 and _L('%.1f%%', (i == 1 and ceil or floor)(p.nTotal / nTotal * 1000) / 10) or ' - '))
			hItem.szKey = p.szKey
		end
		for i = hList:GetItemCount() - 1, #aResult, -1 do
			hList:RemoveItem(i)
		end
		hList:FormatAllItemPos()
	else
		this:Lookup('WndScroll_Skill'):SetSize(480, 348)
		this:Lookup('WndScroll_Skill', ''):SetSize(480, 348)
		this:Lookup('WndScroll_Skill', 'Handle_SkillList'):SetSize(480, 332)
		this:Lookup('WndScroll_Skill', 'Handle_SkillList'):FormatAllItemPos()
		this:Lookup('WndScroll_Skill', ''):FormatAllItemPos()
		this:Lookup('WndScroll_Detail'):Hide()
		this:Lookup('WndScroll_Target'):Hide()
		this:Lookup('', 'Handle_Spliter'):Hide()
	end

end

function MY_Recount_DT.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		this.nLastRedrawFrame = nil
	end
end

function MY_Recount_DT.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		LIB.RegisterEsc(this:GetRoot():GetTreePath())
		Wnd.CloseWindow(this:GetRoot())
	elseif name == 'Btn_Switch' then
		if this:GetRoot().szPrimarySort == 'Skill' then
			this:GetRoot().szPrimarySort = 'Target'
		else
			this:GetRoot().szPrimarySort = 'Skill'
		end
		this:GetRoot().nLastRedrawFrame = 0
	elseif name == 'Btn_Unselect' then
		this:GetRoot().szSelectedSkill  = nil
		this:GetRoot().szSelectedTarget = nil
		this:GetRoot().nLastRedrawFrame = 0
	elseif name == 'Btn_Issuance' then
		PopupMenu(D.GetDetailMenu(this:GetRoot()))
	end
end

function MY_Recount_DT.OnItemLButtonDown()
	local name = this:GetName()
	if name == 'Handle_SkillItem' then
		if this:GetRoot().szPrimarySort == 'Skill' then
			this:GetRoot().szSelectedSkill = this.szKey
		else
			this:GetRoot().szSelectedTarget = this.szKey
		end
		this:GetRoot().nLastRedrawFrame = 0
	end
end

function MY_Recount_DT.OnItemRButtonClick()
	local name = this:GetName()
	if (name == 'Handle_SkillItem' and this:GetRoot().szPrimarySort == 'Target')
	or (name == 'Handle_TargetItem' and this:GetRoot().szPrimarySort == 'Skill') then
		local szKey = this.szKey
		local menu = {}
		menu.x, menu.y = Cursor.GetPos(true)
		for _, nChannel in ipairs({ STAT_TYPE.DPS, STAT_TYPE.HPS, STAT_TYPE.BDPS, STAT_TYPE.BHPS }) do
			insert(menu, {
				szOption = STAT_TYPE_NAME[nChannel],
				fnAction = function()
					Wnd.OpenWindow(SZ_INI, 'MY_Recount_DT#' .. szKey .. '_' .. nChannel)
				end,
			})
		end
		PopupMenu(menu)
	end
end

function MY_Recount_DT.OnItemLButtonDBClick()
	local name = this:GetName()
	if (name == 'Handle_SkillItem' and this:GetRoot().szPrimarySort == 'Target')
	or (name == 'Handle_TargetItem' and this:GetRoot().szPrimarySort == 'Skill') then
		Wnd.OpenWindow(SZ_INI, 'MY_Recount_DT#' .. this.szKey .. '_' .. this:GetRoot().nChannel)
	end
end

function MY_Recount_DT_Open(id, nChannel)
	Wnd.OpenWindow(SZ_INI, 'MY_Recount_DT#' .. id .. '_' .. nChannel)
end
