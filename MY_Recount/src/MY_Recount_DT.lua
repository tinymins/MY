--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 战斗统计 详情界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Recount/MY_Recount_DT'
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local DK = MY_Recount_DS.DK
local DK_REC_STAT_SKILL = MY_Recount_DS.DK_REC_STAT_SKILL
local DK_REC_STAT_SKILL_DETAIL = MY_Recount_DS.DK_REC_STAT_SKILL_DETAIL
local DK_REC_STAT_SKILL_TARGET = MY_Recount_DS.DK_REC_STAT_SKILL_TARGET
local DK_REC_STAT_TARGET = MY_Recount_DS.DK_REC_STAT_TARGET
local DK_REC_STAT_TARGET_DETAIL = MY_Recount_DS.DK_REC_STAT_TARGET_DETAIL
local DK_REC_STAT_TARGET_SKILL = MY_Recount_DS.DK_REC_STAT_TARGET_SKILL

local DK_REC_STAT = MY_Recount_DS.DK_REC_STAT
local D = {}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_Recount_DT.ini'
local STAT_TYPE = MY_Recount.STAT_TYPE
local STAT_TYPE_LIST = MY_Recount.STAT_TYPE_LIST
local STAT_TYPE_KEY = MY_Recount.STAT_TYPE_KEY
local STAT_TYPE_NAME = MY_Recount.STAT_TYPE_NAME
local SKILL_RESULT = MY_Recount.SKILL_RESULT
local SKILL_RESULT_NAME = MY_Recount.SKILL_RESULT_NAME

function D.InsertFromText(aTabTalk, h)
	local aText = {}
	for i = 0, h:GetItemCount() - 1 do
		local p = h:Lookup(i)
		if p:GetType() == 'Text' then
			table.insert(aText, p:GetText())
		end
	end
	table.insert(aTabTalk, aText)
end

function D.GetDetailMenu(frame)
	local t = {}
	local DataDisplay = MY_Recount.GetDisplayData()
	local eTimeChannel = MY_Recount_UI.bSysTimeMode and STAT_TYPE_KEY[MY_Recount_UI.nChannel]
	local function Publish(nChannel, nLimit)
		local bDetail = frame:Lookup('', 'Handle_Spliter'):IsVisible()
		X.SendChat(
			nChannel,
			'[' .. X.PACKET_INFO.SHORT_NAME .. ']'
			.. _L['Fight recount'] .. ' - '
			.. frame:Lookup('', 'Text_Default'):GetText()
			.. ' ' .. ((DataDisplay[DK.BOSSNAME] and ' - ' .. DataDisplay[DK.BOSSNAME]) or '')
			.. '(' .. X.FormatDuration(MY_Recount_DS.GeneFightTime(DataDisplay, eTimeChannel), 'SYMBOL', { mode = 'fixed-except-leading', maxUnit = 'minute', keepUnit = 'minute' }) .. ')',
			{ parsers = { name = false } }
		)
		X.SendChat(nChannel, '------------------------------')

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
			for i = 0, math.min(hList:GetItemCount(), nLimit) - 1 do
				D.InsertFromText(aTabTalk, hList:Lookup(i))
			end
		end
		X.SendTabChat(nChannel, aTabTalk, {'L', 'L', 'R', 'R', 'R'})
		X.SendChat(nChannel, '------------------------------')

		if bDetail then
			local aTabTalk = {}
			D.InsertFromText(aTabTalk, frame:Lookup('WndScroll_Detail', 'Handle_DetailTitle'))
			local hList = frame:Lookup('WndScroll_Detail', 'Handle_DetailList')
			for i = 0, hList:GetItemCount() - 1 do
				D.InsertFromText(aTabTalk, hList:Lookup(i))
			end
			X.SendTabChat(nChannel, aTabTalk, {'L', 'L', 'R', 'R', 'R', 'R', 'R'})
			X.SendChat(nChannel, '------------------------------')

			local aTabTalk = {}
			D.InsertFromText(aTabTalk, frame:Lookup('WndScroll_Target', 'Handle_TargetTitle'))
			local hList = frame:Lookup('WndScroll_Target', 'Handle_TargetList')
			for i = 0, math.min(hList:GetItemCount(), nLimit) - 1 do
				D.InsertFromText(aTabTalk, hList:Lookup(i))
			end
			X.SendTabChat(nChannel, aTabTalk, {'L', 'L', 'R', 'R', 'R', 'R', 'R', 'R'})
			X.SendChat(nChannel, '------------------------------')
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
				Publish(nChannel, math.huge)
				X.UI.ClosePopupMenu()
			end,
			rgb = GetMsgFontColor(szChannel, true),
		}
		for _, nLimit in ipairs({1, 2, 3, 4, 5, 8, 10, 15, 20, 30, 50, 100}) do
			table.insert(t1, {
				szOption = _L('Top %d', nLimit),
				fnAction = function() Publish(nChannel, nLimit) end,
			})
		end
		table.insert(t, t1)
	end

	return t
end

function D.OnFrameBreathe()
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
	local szName = X.IsString(id) and id or MY_Recount_DS.GetNameAusID(DataDisplay, id)
	this:Lookup('Wnd_Bg', 'Text_Default'):SetText(szName .. ' ' .. STAT_TYPE_NAME[this.nChannel])

	-- 获取数据
	local tData = MY_Recount_DS.GetMergeTargetData(DataDisplay, szChannel, id, MY_Recount_UI.bGroupSameNpc, MY_Recount_UI.bGroupSameEffect)
	if not tData then
		this:Lookup('WndScroll_Detail', 'Handle_DetailList'):Clear()
		this:Lookup('WndScroll_Skill' , 'Handle_SkillList' ):Clear()
		this:Lookup('WndScroll_Target', 'Handle_TargetList'):Clear()
		return
	end

	local szPrimarySort   = this.szPrimarySort or DK_REC_STAT.SKILL
	local szSecondarySort = (szPrimarySort == DK_REC_STAT.SKILL and DK_REC_STAT_SKILL.TARGET) or DK_REC_STAT_TARGET.SKILL

	--------------- 一、技能列表更新 -----------------
	-- 数据收集
	local aResult, nTotal = {}, MY_Recount_UI.bShowEffect and tData[DK_REC_STAT.TOTAL_EFFECT] or tData[DK_REC_STAT.TOTAL]
	if szPrimarySort == DK_REC_STAT.SKILL then
		for szEffectID, p in pairs(tData[DK_REC_STAT.SKILL]) do
			local bShowZeroVal = MY_Recount_UI.bShowZeroVal
				or MY_Recount.StatSkillContainsImportantEffect(szEffectID, p)
			local rec = {
				szKey  = szEffectID,
				szName = MY_Recount_DS.GetEffectNameAusID(DataDisplay, szChannel, szEffectID) or szEffectID,
				nCount = not bShowZeroVal and p[DK_REC_STAT_SKILL.NZ_COUNT] or p[DK_REC_STAT_SKILL.COUNT],
				nTotal = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_SKILL.TOTAL_EFFECT] or p[DK_REC_STAT_SKILL.TOTAL],
			}
			if (bShowZeroVal or rec.nTotal > 0)
			and (not MY_Recount_UI.bHideAnonymous or rec.szName:sub(1, 1) ~= '#') then
				table.insert(aResult, rec)
			end
		end
	else
		for id, p in pairs(tData[DK_REC_STAT.TARGET]) do
			local bShowZeroVal = MY_Recount_UI.bShowZeroVal
				or MY_Recount.StatTargetContainsImportantEffect(p)
			local rec = {
				szKey  = id                              ,
				szName = X.IsString(id) and id or MY_Recount_DS.GetNameAusID(DataDisplay, id),
				nCount = not bShowZeroVal and p[DK_REC_STAT_TARGET.NZ_COUNT] or p[DK_REC_STAT_TARGET.COUNT],
				nTotal = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_TARGET.TOTAL_EFFECT] or p[DK_REC_STAT_TARGET.TOTAL],
			}
			if bShowZeroVal or rec.nTotal > 0 then
				table.insert(aResult, rec)
			end
		end
	end
	table.sort(aResult, function(p1, p2) return p1.nTotal > p2.nTotal end)
	-- 默认选中第一个
	if this.bFirstRendering then
		if aResult[1] then
			if szPrimarySort == DK_REC_STAT.SKILL then
				this.szSelectedSkill = aResult[1].szKey
			else
				this.szSelectedTarget = aResult[1].szKey
			end
		end
		this.bFirstRendering = nil
	end
	local szSelected
	local szSelectedSkill  = this.szSelectedSkill
	local szSelectedTarget = this.szSelectedTarget
	if szPrimarySort == DK_REC_STAT.SKILL then
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
		hItem:Lookup('Text_SkillName'):SetText(MY_Recount.GetTargetShowName(p.szName, szPrimarySort == DK_REC_STAT.TARGET and p.dwForceID ~= -1))
		hItem:Lookup('Text_SkillCount'):SetText(p.nCount)
		hItem:Lookup('Text_SkillTotal'):SetText(p.nTotal)
		hItem:Lookup('Text_SkillPercentage'):SetText(nTotal > 0 and _L('%.1f%%', (i == 1 and math.ceil or math.floor)(p.nTotal / nTotal * 1000) / 10) or ' - ')

		if szPrimarySort == DK_REC_STAT.SKILL and szSelectedSkill == p.szKey
		or szPrimarySort == DK_REC_STAT.TARGET and szSelectedTarget == p.szKey then
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
		this:Lookup('Wnd_Bg', 'Handle_Spliter'):Show()
		--------------- 二、技能释放结果列表更新 -----------------
		-- 数据收集
		local aResult, nCountSum, bShowZeroVal = {}, 0
		if szPrimarySort == DK_REC_STAT.SKILL then
			bShowZeroVal = MY_Recount_UI.bShowZeroVal
				or MY_Recount.StatSkillContainsImportantEffect(szSelected, tData[DK_REC_STAT.SKILL][szSelected])
			nCountSum = not bShowZeroVal
				and tData[DK_REC_STAT.SKILL][szSelected][DK_REC_STAT_SKILL.NZ_COUNT]
				or tData[DK_REC_STAT.SKILL][szSelected][DK_REC_STAT_SKILL.COUNT]
			for nSkillResult, p in pairs(tData[DK_REC_STAT.SKILL][szSelected][DK_REC_STAT_SKILL.DETAIL]) do
				local res = {
					nCount = not bShowZeroVal and p[DK_REC_STAT_SKILL_DETAIL.NZ_COUNT] or p[DK_REC_STAT_SKILL_DETAIL.COUNT],
					nMin   = not MY_Recount_UI.bShowEffect
						and (not bShowZeroVal and p[DK_REC_STAT_SKILL_DETAIL.NZ_MIN] or p[DK_REC_STAT_SKILL_DETAIL.MIN])
						or (not bShowZeroVal and p[DK_REC_STAT_SKILL_DETAIL.NZ_MIN_EFFECT] or p[DK_REC_STAT_SKILL_DETAIL.MIN_EFFECT]),
					nAvg   = not MY_Recount_UI.bShowEffect
						and (not bShowZeroVal and p[DK_REC_STAT_SKILL_DETAIL.NZ_AVG] or p[DK_REC_STAT_SKILL_DETAIL.AVG])
						or (not bShowZeroVal and p[DK_REC_STAT_SKILL_DETAIL.NZ_AVG_EFFECT] or p[DK_REC_STAT_SKILL_DETAIL.AVG_EFFECT]),
					nMax   = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_SKILL_DETAIL.MAX_EFFECT] or p[DK_REC_STAT_SKILL_DETAIL.MAX],
					nTotal = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_SKILL_DETAIL.TOTAL_EFFECT] or p[DK_REC_STAT_SKILL_DETAIL.TOTAL],
					szSkillResult = SKILL_RESULT_NAME[nSkillResult],
				}
				if res.nCount > 0 then
					table.insert(aResult, res)
				end
			end
		else
			bShowZeroVal = MY_Recount_UI.bShowZeroVal
				or MY_Recount.StatTargetContainsImportantEffect(tData[DK_REC_STAT.TARGET][szSelected])
			nCountSum = not bShowZeroVal
				and tData[DK_REC_STAT.TARGET][szSelected][DK_REC_STAT_TARGET.NZ_COUNT]
				or tData[DK_REC_STAT.TARGET][szSelected][DK_REC_STAT_TARGET.COUNT]
			for nSkillResult, p in pairs(tData[DK_REC_STAT.TARGET][szSelected][DK_REC_STAT_TARGET.DETAIL]) do
				local res = {
					nCount = not bShowZeroVal and p[DK_REC_STAT_TARGET_DETAIL.NZ_COUNT] or p[DK_REC_STAT_TARGET_DETAIL.COUNT],
					nMin   = not MY_Recount_UI.bShowEffect
						and (not bShowZeroVal and p[DK_REC_STAT_TARGET_DETAIL.NZ_MIN] or p[DK_REC_STAT_TARGET_DETAIL.MIN])
						or (not bShowZeroVal and p[DK_REC_STAT_TARGET_DETAIL.NZ_MIN_EFFECT] or p[DK_REC_STAT_TARGET_DETAIL.MIN_EFFECT]),
					nAvg   = not MY_Recount_UI.bShowEffect
						and (not bShowZeroVal and p[DK_REC_STAT_TARGET_DETAIL.NZ_AVG] or p[DK_REC_STAT_TARGET_DETAIL.AVG])
						or (not bShowZeroVal and p[DK_REC_STAT_TARGET_DETAIL.NZ_AVG_EFFECT] or p[DK_REC_STAT_TARGET_DETAIL.AVG_EFFECT]),
					nMax   = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_TARGET_DETAIL.MAX_EFFECT] or p[DK_REC_STAT_TARGET_DETAIL.MAX],
					nTotal = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_TARGET_DETAIL.TOTAL_EFFECT] or p[DK_REC_STAT_TARGET_DETAIL.TOTAL],
					szSkillResult = SKILL_RESULT_NAME[nSkillResult],
				}
				if res.nCount > 0 then
					table.insert(aResult, res)
				end
			end
		end
		table.sort(aResult, function(p1, p2) return p1.nAvg > p2.nAvg end)
		-- 界面重绘
		this:Lookup('WndScroll_Detail'):Show()
		local hList = this:Lookup('WndScroll_Detail', 'Handle_DetailList')
		for i, p in ipairs(aResult) do
			local hItem = hList:Lookup(i - 1) or hList:AppendItemFromIni(SZ_INI, 'Handle_DetailItem')
			hItem:Lookup('Text_DetailNo'):SetText(i)
			hItem:Lookup('Text_DetailType'):SetText(p.szSkillResult)
			hItem:Lookup('Text_DetailMin'):SetText(p.nMin)
			hItem:Lookup('Text_DetailAverage'):SetText(p.nAvg)
			hItem:Lookup('Text_DetailMax'):SetText(p.nMax)
			hItem:Lookup('Text_DetailCount'):SetText(p.nCount)
			hItem:Lookup('Text_DetailPercent'):SetText(nCountSum > 0
				and _L('%.1f%%', (i == 1 and math.ceil or math.floor)(p.nCount / nCountSum * 1000) / 10)
				or ' - ')
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
		local aResult, nTotal = {}, 0
		if szPrimarySort == DK_REC_STAT.SKILL then
			local bShowZeroVal = MY_Recount_UI.bShowZeroVal
				or MY_Recount.StatSkillContainsImportantEffect(szSelectedSkill, tData[DK_REC_STAT.SKILL][szSelectedSkill])
			for id, p in pairs(tData[DK_REC_STAT.SKILL][szSelectedSkill][DK_REC_STAT_SKILL.TARGET]) do
				local rec = {
					szKey          = id,
					nHitCount      = bShowZeroVal
						and (
							(p[DK_REC_STAT_SKILL_TARGET.COUNT][SKILL_RESULT.HIT] or 0)
							+ (p[DK_REC_STAT_SKILL_TARGET.COUNT][SKILL_RESULT.ABSORB] or 0)
						)
						or (
							(p[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][SKILL_RESULT.HIT] or 0)
							+ (p[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][SKILL_RESULT.ABSORB] or 0)
						),
					nMissCount     = bShowZeroVal
						and (p[DK_REC_STAT_SKILL_TARGET.COUNT][SKILL_RESULT.MISS] or 0)
						or p[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][SKILL_RESULT.MISS] or 0,
					nCriticalCount = bShowZeroVal
						and (p[DK_REC_STAT_SKILL_TARGET.COUNT][SKILL_RESULT.CRITICAL] or 0)
						or p[DK_REC_STAT_SKILL_TARGET.NZ_COUNT][SKILL_RESULT.CRITICAL] or 0,
					nMax           = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_SKILL_TARGET.MAX_EFFECT] or p[DK_REC_STAT_SKILL_TARGET.MAX],
					nTotal         = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_SKILL_TARGET.TOTAL_EFFECT] or p[DK_REC_STAT_SKILL_TARGET.TOTAL],
					szName         = X.IsString(id) and id or MY_Recount_DS.GetNameAusID(DataDisplay, id),
				}
				if bShowZeroVal or rec.nTotal > 0 or rec.nMissCount > 0 then
					table.insert(aResult, rec)
				end
			end
			nTotal = tData[DK_REC_STAT.SKILL][szSelected][MY_Recount_UI.bShowEffect and DK_REC_STAT_SKILL.TOTAL_EFFECT or DK_REC_STAT_SKILL.TOTAL]
		else
			local bShowZeroVal = MY_Recount_UI.bShowZeroVal
				or MY_Recount.StatTargetContainsImportantEffect(tData[DK_REC_STAT.TARGET][szSelectedTarget])
			for szEffectID, p in pairs(tData[DK_REC_STAT.TARGET][szSelectedTarget][DK_REC_STAT_TARGET.SKILL]) do
				local rec = {
					nHitCount      = bShowZeroVal
						and (p[DK_REC_STAT_TARGET_SKILL.COUNT][SKILL_RESULT.HIT] or 0)
						or p[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][SKILL_RESULT.HIT] or 0,
					nMissCount     = bShowZeroVal
						and (p[DK_REC_STAT_TARGET_SKILL.COUNT][SKILL_RESULT.MISS] or 0)
						or p[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][SKILL_RESULT.MISS] or 0,
					nCriticalCount = bShowZeroVal
						and (p[DK_REC_STAT_TARGET_SKILL.COUNT][SKILL_RESULT.CRITICAL] or 0)
						or p[DK_REC_STAT_TARGET_SKILL.NZ_COUNT][SKILL_RESULT.CRITICAL] or 0,
					nMax           = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_TARGET_SKILL.MAX_EFFECT] or p[DK_REC_STAT_TARGET_SKILL.MAX],
					nTotal         = MY_Recount_UI.bShowEffect and p[DK_REC_STAT_TARGET_SKILL.TOTAL_EFFECT] or p[DK_REC_STAT_TARGET_SKILL.TOTAL],
					szName         = MY_Recount_DS.GetEffectNameAusID(DataDisplay, szChannel, szEffectID) or szEffectID,
				}
				if (bShowZeroVal or rec.nTotal > 0 or rec.nMissCount > 0)
				and (not MY_Recount_UI.bHideAnonymous or rec.szName:sub(1, 1) ~= '#') then
					table.insert(aResult, rec)
				end
			end
			nTotal = tData[DK_REC_STAT.TARGET][szSelected][MY_Recount_UI.bShowEffect and DK_REC_STAT_TARGET.TOTAL_EFFECT or DK_REC_STAT_TARGET.TOTAL]
		end
		table.sort(aResult, function(p1, p2) return p1.nTotal > p2.nTotal end)
		-- 界面重绘
		this:Lookup('WndScroll_Target'):Show()
		local hList = this:Lookup('WndScroll_Target', 'Handle_TargetList')
		for i, p in ipairs(aResult) do
			local hItem = hList:Lookup(i - 1) or hList:AppendItemFromIni(SZ_INI, 'Handle_TargetItem')
			hItem:Lookup('Text_TargetNo'):SetText(i)
			hItem:Lookup('Text_TargetName'):SetText(MY_Recount.GetTargetShowName(p.szName, szPrimarySort == DK_REC_STAT.SKILL and p.dwForceID ~= -1))
			hItem:Lookup('Text_TargetTotal'):SetText(p.nTotal)
			hItem:Lookup('Text_TargetMax'):SetText(p.nMax)
			hItem:Lookup('Text_TargetHit'):SetText(p.nHitCount)
			hItem:Lookup('Text_TargetCritical'):SetText(p.nCriticalCount)
			hItem:Lookup('Text_TargetMiss'):SetText(p.nMissCount)
			hItem:Lookup('Text_TargetPercent'):SetText((nTotal > 0 and _L('%.1f%%', (i == 1 and math.ceil or math.floor)(p.nTotal / nTotal * 1000) / 10) or ' - '))
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

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		this.nLastRedrawFrame = nil
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		X.RegisterEsc(this:GetRoot():GetTreePath(), false)
		X.UI.CloseFrame(this:GetRoot())
	elseif name == 'Btn_Switch' then
		if this:GetRoot().szPrimarySort == DK_REC_STAT.SKILL then
			this:GetRoot().szPrimarySort = DK_REC_STAT.TARGET
		else
			this:GetRoot().szPrimarySort = DK_REC_STAT.SKILL
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

function D.OnItemLButtonDown()
	local name = this:GetName()
	if name == 'Handle_SkillItem' then
		if this:GetRoot().szPrimarySort == DK_REC_STAT.SKILL then
			this:GetRoot().szSelectedSkill = this.szKey
		else
			this:GetRoot().szSelectedTarget = this.szKey
		end
		this:GetRoot().nLastRedrawFrame = 0
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if (name == 'Handle_SkillItem' and this:GetRoot().szPrimarySort == DK_REC_STAT.TARGET)
	or (name == 'Handle_TargetItem' and this:GetRoot().szPrimarySort == DK_REC_STAT.SKILL) then
		local szKey = this.szKey
		local menu = {}
		menu.x, menu.y = Cursor.GetPos(true)
		for _, k in ipairs(STAT_TYPE_LIST) do
			table.insert(menu, {
				szOption = STAT_TYPE_NAME[STAT_TYPE[k]],
				fnAction = function()
					D.Open(szKey, STAT_TYPE[k])
				end,
			})
		end
		PopupMenu(menu)
	end
end

function D.OnItemLButtonDBClick()
	local name = this:GetName()
	if (name == 'Handle_SkillItem' and this:GetRoot().szPrimarySort == DK_REC_STAT.TARGET)
	or (name == 'Handle_TargetItem' and this:GetRoot().szPrimarySort == DK_REC_STAT.SKILL) then
		D.Open(this.szKey, this:GetRoot().nChannel)
	end
end

function D.Open(id, nChannel)
	local szFrameName = 'MY_Recount_DT#' .. id .. '_' .. nChannel
	if Station.SearchFrame(szFrameName) then
		return
	end
	local frame = X.UI.CreateFrame('MY_Recount_DT', { text = '', theme = X.UI.FRAME_THEME.SIMPLE, close = false, w = 480, h = 387 }):Raw()
	X.UI.AppendFromIni(frame, SZ_INI, 'Wnd_Total', true)
	frame:SetName(szFrameName)
	frame.id = tonumber(id) or id
	frame.nChannel = tonumber(nChannel)
	frame.bFirstRendering = true
	frame.szPrimarySort = ((frame.nChannel == STAT_TYPE.DPS or frame.nChannel == STAT_TYPE.HPS) and DK_REC_STAT.SKILL) or DK_REC_STAT.TARGET
	frame.szSecondarySort = ((frame.nChannel == STAT_TYPE.DPS or frame.nChannel == STAT_TYPE.HPS) and DK_REC_STAT.TARGET) or DK_REC_STAT.SKILL
	frame:Lookup('WndScroll_Target', 'Handle_TargetTitle/Text_TargetTitle_5'):SetText(g_tStrings.STR_HIT_NAME)
	frame:Lookup('WndScroll_Target', 'Handle_TargetTitle/Text_TargetTitle_6'):SetText(g_tStrings.STR_CS_NAME)
	frame:Lookup('WndScroll_Target', 'Handle_TargetTitle/Text_TargetTitle_7'):SetText(g_tStrings.STR_MSG_MISS)
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	X.UI.AdaptComponentAppearance(frame:Lookup('WndScroll_Skill/Scroll_Skill_List'))
	X.UI.AdaptComponentAppearance(frame:Lookup('WndScroll_Detail/Scroll_Detail_List'))
	X.UI.AdaptComponentAppearance(frame:Lookup('WndScroll_Target/Scroll_Target_List'))

	local function canEsc()
		if frame and frame:IsValid() then
			return true
		else
			X.RegisterEsc(szFrameName, false)
		end
	end
	local function onEsc()
		if frame.szSelectedSkill or frame.szSelectedTarget then
			frame.szSelectedSkill  = nil
			frame.szSelectedTarget = nil
		else
			X.RegisterEsc(szFrameName, false)
			X.UI.CloseFrame(frame)
		end
	end
	X.RegisterEsc(szFrameName, canEsc, onEsc)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_Recount_DT',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'Open',
			},
			root = D,
		},
	},
}
MY_Recount_DT = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
