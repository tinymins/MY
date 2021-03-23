--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 仇恨统计
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_ThreatRank'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ThreatRank'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

MY_ThreatRank = {
	bEnable       = true,  -- 开启
	bInDungeon    = true, -- 只有秘境内才开启
	nBGAlpha      = 30,    -- 背景透明度
	nMaxBarCount  = 7,     -- 最大列表
	bForceColor   = false, -- 根据门派着色
	bForceIcon    = true,  -- 显示门派图标 团队时显示心法
	nOTAlertLevel = 1,     -- OT提醒
	bOTAlertSound = true,  -- OT 播放声音
	bSpecialSelf  = true,  -- 特殊颜色显示自己
	bTopTarget    = true,  -- 置顶当前目标
	bShowPercent  = true,  -- 是否为显示百分比模式
	tAnchor       = {},
	nStyle        = 2,
}
LIB.RegisterCustomData('MY_ThreatRank')

local TS = MY_ThreatRank
local ipairs, pairs = ipairs, pairs
local GetPlayer, GetNpc, IsPlayer, ApplyCharacterThreatRankList = GetPlayer, GetNpc, IsPlayer, ApplyCharacterThreatRankList
local GetClientPlayer, GetClientTeam = GetClientPlayer, GetClientTeam
local UI_GetClientPlayerID, GetTime = UI_GetClientPlayerID, GetTime
local HATRED_COLLECT = g_tStrings.HATRED_COLLECT
local MY_GetObjName, MY_GetForceColor = LIB.GetObjectName, LIB.GetForceColor
local MY_GetBuff, MY_GetBuffName, MY_GetEndTime = LIB.GetBuff, LIB.GetBuffName, LIB.GetEndTime
local GetNpcIntensity = GetNpcIntensity
local GetTime = GetTime

local TS_INIFILE = PACKET_INFO.ROOT .. 'MY_ThreatRank/ui/MY_ThreatRank.ini'

local _TS = {
	tStyle = LoadLUAData(PACKET_INFO.ROOT .. 'MY_ThreatRank/data/style.jx3dat'),
}
local function IsEnabled() return TS.bEnable end

function TS.OnFrameCreate()
	this:RegisterEvent('CHARACTER_THREAT_RANKLIST')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('TARGET_CHANGE')
	this:RegisterEvent('FIGHT_HINT')
	this:RegisterEvent('LOADING_END')
	this.hItemData      = this:CreateItemData(PACKET_INFO.ROOT .. 'MY_ThreatRank/ui/Handle_ThreatBar.ini', 'Handle_ThreatBar')
	this.dwTargetID     = 0
	this.nTime          = 0
	this.bSelfTreatRank = 0
	this.bg         = this:Lookup('', 'Image_Background')
	this.bg:SetAlpha(255 * TS.nBGAlpha / 100)
	this.handle     = this:Lookup('', 'Handle_List')
	this.txt        = this:Lookup('', 'Handle_TargetInfo'):Lookup('Text_Name')
	this.CastBar    = this:Lookup('', 'Handle_TargetInfo'):Lookup('Image_Cast_Bar')
	this.Life       = this:Lookup('', 'Handle_TargetInfo'):Lookup('Image_Life')
	this:Lookup('', 'Text_Title'):SetText(g_tStrings.HATRED_COLLECT)
	_TS.UpdateAnchor(this)
	TS.OnEvent('TARGET_CHANGE')
end

function TS.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		_TS.UpdateAnchor(this)
	elseif szEvent == 'TARGET_CHANGE' then
		local dwType, dwID = Target_GetTargetData()
		local dwTargetID
		-- check tar
		if dwType == TARGET.NPC or GetNpc(this.dwLockTargetID) then
			if GetNpc(this.dwLockTargetID) then
				dwTargetID = this.dwLockTargetID
			else
				dwTargetID = dwID
			end
		elseif dwType == TARGET.PLAYER and GetPlayer(dwID) then
			local tdwTpye, tdwID = GetPlayer(dwID).GetTarget()
			if tdwTpye == TARGET.NPC then
				dwTargetID = tdwID
			end
		end
		-- so ...
		if dwTargetID then
			this.dwTargetID = dwTargetID
			this:Show()
		else
			_TS.UnBreathe()
		end
	elseif szEvent == 'CHARACTER_THREAT_RANKLIST' then
		if arg0 == this.dwTargetID then
			_TS.UpdateThreatBars(arg1, arg2, arg0)
		end
	elseif szEvent == 'FIGHT_HINT' then
		if not arg0 then
			this.nTime = GetTime()
		end
	elseif szEvent == 'LOADING_END' then
		this.dwTargetID     = 0
		this.nTime          = 0
		this.bSelfTreatRank = 0
	end
end

function TS.OnFrameBreathe()
	local p = GetNpc(this.dwTargetID)
	if p then
		ApplyCharacterThreatRankList(this.dwTargetID)
		local nType, dwSkillID, dwSkillLevel, fCastPercent = p.GetSkillOTActionState()
		local fCurrentLife, fMaxLife = LIB.GetObjectLife(p)
		if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
		or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
			this.CastBar:Show()
			this.CastBar:SetPercentage(fCastPercent)
			local szName = LIB.GetSkillName(dwSkillID, dwSkillLevel)
			this.txt:SetText(szName)
		else
			local lifeper = fCurrentLife / fMaxLife
			this.CastBar:Hide()
			this.txt:SetText(MY_GetObjName(p) .. format(' (%0.1f%%)', lifeper * 100))
			this.Life:SetPercentage(lifeper)
		end

		-- 无威胁提醒
		local buff = MY_GetBuff(GetClientPlayer(), {
			[917]  = 0,
			[4487] = 0,
			[926]  = 0,
			[775]  = 0,
			[4101] = 0,
			[8422] = 0
		})
		local hText = this:Lookup('', 'Text_Title')
		local szText = hText.szText or ''
		if buff then
			local szName = MY_GetBuffName(buff.dwID, buff.nLevel)
			hText:SetText(format('%s (%ds)', szName, floor(MY_GetEndTime(buff.nEndFrame))) .. szText)
			hText:SetFontColor(0, 255, 0)
		else
			hText:SetText(HATRED_COLLECT .. szText)
			hText:SetFontColor(255, 255, 255)
			hText.bBuff = nil
		end

		-- 开怪提醒
		if this.nTime >= 0 and GetTime() - this.nTime > 1000 * 7 and GetNpcIntensity(p) > 2 then
			local me = GetClientPlayer()
			if not me.bFightState then return end
			this.nTime = -1
			LIB.DelayCall(1000, function()
				if not me.IsInParty() then return end
				if p and p.dwDropTargetPlayerID and p.dwDropTargetPlayerID ~= 0 then
					if IsParty(me.dwID, p.dwDropTargetPlayerID) or me.dwID == p.dwDropTargetPlayerID then
						local team = GetClientTeam()
						local szMember = team.GetClientTeamMemberName(p.dwDropTargetPlayerID)
						local nGroup = team.GetMemberGroupIndex(p.dwDropTargetPlayerID) + 1
						local name = MY_GetObjName(p)
						local oContent = {_L('Well done! %s in %d group first to attack %s!!', nGroup, szMember, name), r = 150, g = 250, b = 230}
						local oTitile = {g_tStrings.HATRED_COLLECT, r = 150, g = 250, b = 230}
						LIB.Sysmsg(oTitile, oContent)
					end
				end
			end)
		end
	else
		this:Hide()
	end
end

function TS.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Setting' then
		LIB.ShowPanel()
		LIB.FocusPanel()
		LIB.SwitchTab('MY_ThreatRank')
	end
end

function TS.OnCheckBoxCheck()
	local szName = this:GetName()
	if szName == 'CheckBox_ScrutinyLock' then
		local dwType, dwID = Target_GetTargetData()
		local frame = this:GetRoot()
		frame.dwLockTargetID = frame.dwTargetID
	end
end

function TS.OnCheckBoxUncheck()
	local szName = this:GetName()
	if szName == 'CheckBox_ScrutinyLock' then
		local dwType, dwID = Target_GetTargetData()
		local frame = this:GetRoot()
		frame.dwLockTargetID = 0
		if dwID then
			frame.dwTargetID = dwID
		else
			_TS.UnBreathe()
		end
	end
end

function TS.OnFrameDragEnd()
	this:CorrectPos()
	TS.tAnchor = GetFrameAnchor(this)
end

function _TS.GetFrame()
	return Station.Lookup('Normal/MY_ThreatRank')
end

function _TS.CheckOpen()
	if TS.bEnable then
		if TS.bInDungeon then
			if LIB.IsInDungeon() then
				_TS.OpenPanel()
			else
				_TS.ClosePanel()
			end
		else
			_TS.OpenPanel()
		end
	else
		_TS.ClosePanel()
	end
end

function _TS.OpenPanel()
	local frame = _TS.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(TS_INIFILE, 'MY_ThreatRank')
		local dwType = Target_GetTargetData()
		if dwType ~= TARGET.NPC then
			frame:Hide()
		end
	end
	return frame
end

function _TS.ClosePanel()
	if _TS.GetFrame() then
		Wnd.CloseWindow(_TS.GetFrame())
	end
end

function _TS.UnBreathe()
	local frame = _TS.GetFrame()
	frame:Hide()
	frame.dwTargetID = 0
	frame.handle:Clear()
	frame.bg:SetSize(240, 55)
	frame.txt:SetText(_L['Loading...'])
	frame.Life:SetPercentage(0)
	frame:Lookup('', 'Text_Title').szText = ''
end

function _TS.UpdateAnchor(frame)
	local a = TS.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('TOPRIGHT', -300, 300, 'TOPRIGHT', 0, 0)
	end
	this:CorrectPos()
end

-- 有几个问题
-- 1) 当前目标 结果反馈的是0仇恨 BUG了 fixed
-- 2) 反馈的目标是错误的 也BUG了 fixed
-- 3) 因为是异步 反馈时目标已经更新 也需要同时更新 fixed
-- 4) 反馈的列表中不存在当前目标 fixed
function _TS.UpdateThreatBars(tList, dwTargetID, dwApplyID)
	local team = GetClientTeam()
	local tThreat, tRank, tMyRank, nTopRank = {}, {}, {}, 1
	-- 修复arg2反馈不准 当前目标才修复 非当前目标也不准。。
	local dwType, dwID = Target_GetTargetData()
	if dwID == dwApplyID and dwType == TARGET.NPC then
		local p = GetNpc(dwApplyID)
		if p then
			local _, tdwID = p.GetTarget()
			if tdwID and tdwID ~= 0 and tdwID ~= dwTargetID and tList[tdwID] then -- 原来是0 搞半天。。
				dwTargetID = tdwID
			end
		end
	end
	-- 重构用于排序
	for k, v in pairs(tList) do
		insert(tThreat, { id = k, val = v })
	end
	sort(tThreat, function(a, b) return a.val > b.val end) -- 进行排序
	for k, v in ipairs(tThreat) do
		v.sort = k
		if v.id == UI_GetClientPlayerID() then
			tMyRank = v
		end
	end
	this.bg:SetH(55 + 24 * min(#tThreat, TS.nMaxBarCount))
	this.handle:Clear()
	local KGnpc = GetNpc(dwApplyID)
	if #tThreat > 0 and KGnpc then
		this:Show()
		if #tThreat >= 2 then
			if TS.bTopTarget and tList[dwTargetID] then
				for k, v in ipairs(tThreat) do
					if v.id == dwTargetID then
						insert(tThreat, 1, remove(tThreat, k))
						break
					end
				end
			end
		end

		if tThreat[1].val ~= 0 then
			nTopRank = tThreat[1].val
		else
			tThreat[1].val = nTopRank -- 修正一些无仇恨的技能，这样单人会显示0%，很不好看。
		end

		local dat = _TS.tStyle[TS.nStyle] or _TS.tStyle[1]
		local show = false
		for k, v in ipairs(tThreat) do
			if k > TS.nMaxBarCount then break end
			if UI_GetClientPlayerID() == v.id then
				if TS.nOTAlertLevel > 0 and GetNpcIntensity(KGnpc) > 2 then
					if this.bSelfTreatRank < TS.nOTAlertLevel and v.val / nTopRank >= TS.nOTAlertLevel then
						LIB.Topmsg(_L('** You Threat more than %d, 120% is Out of Taunt! **', TS.nOTAlertLevel * 100))
						if TS.bOTAlertSound then
							PlaySound(SOUND.UI_SOUND, _L['SOUND_nat_view2'])
						end
					end
				end
				this.bSelfTreatRank = v.val / nTopRank
				show = true
			elseif k == TS.nMaxBarCount and not show and tList[UI_GetClientPlayerID()] then -- 始终显示自己的
				v = tMyRank
			end

			local item = this.handle:AppendItemFromData(this.hItemData, k)
			local nThreatPercentage, fDiff = 0, 0
			if MY_ThreatRank.bShowPercent then
				if v.val ~= 0 then
					fDiff = v.val / nTopRank
					nThreatPercentage = fDiff * (100 / 120)
					item:Lookup('Text_ThreatValue'):SetText(floor(100 * fDiff) .. '%')
				else
					item:Lookup('Text_ThreatValue'):SetText('0%')
				end
			else
				item:Lookup('Text_ThreatValue'):SetText(v.val)
			end
			item:Lookup('Text_ThreatValue'):SetFontScheme(dat[6][2])

			if v.id == dwTargetID then
				if dwTargetID == UI_GetClientPlayerID() then
					item:Lookup('Image_Target'):SetFrame(10)
				end
				item:Lookup('Image_Target'):Show()
			end

			local r, g, b = 188, 188, 188
			local szName, dwForceID = _L['Loading...'], 0
			if IsPlayer(v.id) then
				local p = GetPlayer(v.id)
				if p then
					dwForceID = p.dwForceID
					szName    = p.szName
				else
					if MY_Farbnamen and MY_Farbnamen.Get then
						local data = MY_Farbnamen.Get(v.id)
						if data then
							szName    = data.szName
							dwForceID = data.dwForceID
						end
					end
				end
				if TS.bForceColor and p then
					r, g, b = MY_GetForceColor(p.dwForceID)
				else
					r, g, b = 255, 255, 255
				end
			else
				local p = GetNpc(v.id)
				if p then
					szName = LIB.GetObjectName(p)
				end
			end
			item:Lookup('Text_ThreatName'):SetText(v.sort .. '.' .. szName)
			item:Lookup('Text_ThreatName'):SetFontScheme(dat[6][1])
			item:Lookup('Text_ThreatName'):SetFontColor(r, g, b)
			if TS.bForceIcon then
				local info = LIB.IsParty(v.id) and IsPlayer(v.id) and team.GetMemberInfo(v.id)
				if info then
					item:Lookup('Image_Icon'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
				elseif IsPlayer(v.id) then
					item:Lookup('Image_Icon'):FromUITex(GetForceImage(dwForceID))
				else
					item:Lookup('Image_Icon'):FromUITex('ui/Image/TargetPanel/Target.uitex', 57)
				end
				item:Lookup('Text_ThreatName'):SetRelPos(21, 4)
				item:FormatAllItemPos()
			end
			if fDiff > 1 then
				item:Lookup('Image_Treat_Bar'):FromUITex(unpack(dat[4]))
				item:Lookup('Text_ThreatName'):SetFontColor(255, 255, 255) --红色的 无论如何都显示白了 否则看不清
			elseif fDiff >= 0.80 then
				item:Lookup('Image_Treat_Bar'):FromUITex(unpack(dat[3]))
			elseif fDiff >= 0.50 then
				item:Lookup('Image_Treat_Bar'):FromUITex(unpack(dat[2]))
			elseif fDiff >= 0.01 then
				item:Lookup('Image_Treat_Bar'):FromUITex(unpack(dat[1]))
			end
			if TS.bSpecialSelf and v.id == UI_GetClientPlayerID() then
				item:Lookup('Image_Treat_Bar'):FromUITex(unpack(dat[5]))
			end
			item:Lookup('Image_Treat_Bar'):SetPercentage(nThreatPercentage)
			item:Show()
		end
		this.handle:FormatAllItemPos()
		this.handle:SetSizeByAllItemSize()
	-- else
		-- this:Hide()
	end
end

local PS = {}
function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local X, Y = 20, 20
	local x, y = X, Y

	ui:Append('Text', { x = x, y = y, text = g_tStrings.HATRED_COLLECT, font = 27 })
	x = x + 10
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 130, checked = TS.bEnable, text = _L['Enable ThreatScrutiny'],
		oncheck = function(bChecked)
			TS.bEnable = bChecked
			_TS.CheckOpen()
		end,
	})
	x = x + 130

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 250, checked = TS.bInDungeon,
		enable = TS.bEnable,
		text = _L['Only in the map type is Dungeon Enable plug-in'],
		oncheck = function(bChecked)
			TS.bInDungeon = bChecked
			_TS.CheckOpen()
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	x = X
	ui:Append('Text', { x = x, y = y, text = _L['Alert Setting'], font = 27, autoenable = IsEnabled })
	x = x + 10
	y = y + 28
	ui:Append('WndCheckBox', {
		x = x, y = y, checked = TS.nOTAlertLevel == 1, text = _L['OT Alert'],
		oncheck = function(bChecked)
			if bChecked then -- 以后可以做% 暂时先不管
				TS.nOTAlertLevel = 1
			else
				TS.nOTAlertLevel = 0
			end
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x, y = y, checked = TS.bOTAlertSound, text = _L['OT Alert Sound'],
		oncheck = function(bChecked)
			TS.bOTAlertSound = bChecked
		end,
		autoenable = function() return IsEnabled() and TS.nOTAlertLevel == 1 end,
	})
	y = y + 28

	x = X
	ui:Append('Text', { x = x, y = y, text = _L['Style Setting'], font = 27, autoenable = IsEnabled })
	y = y + 28

	x = x + 10
	ui:Append('WndCheckBox', {
		x = x , y = y, checked = TS.bShowPercent, text = _L['Show percent'],
		oncheck = function(bChecked)
			TS.bShowPercent = bChecked
		end,
		autoenable = IsEnabled,
	})

	y = y + 28
	ui:Append('WndCheckBox', {
		x = x , y = y, checked = TS.bTopTarget, text = _L['Top Target'],
		oncheck = function(bChecked)
			TS.bTopTarget = bChecked
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x , y = y, checked = TS.bForceColor, text = g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		oncheck = function(bChecked)
			TS.bForceColor = bChecked
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x , y = y, checked = TS.bForceIcon, text = g_tStrings.STR_SHOW_KUNGFU,
		oncheck = function(bChecked)
			TS.bForceIcon = bChecked
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	ui:Append('WndCheckBox', {
		x = x , y = y, w = 200, checked = TS.bSpecialSelf, text = _L['Special Self'],
		oncheck = function(bChecked)
			TS.bSpecialSelf = bChecked
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Style Select'],
		menu = function()
			local t = {}
			for k, v in ipairs(_TS.tStyle) do
				insert(t, {
					szOption = _L('Style %d', k),
					bMCheck = true,
					bChecked = TS.nStyle == k,
					fnAction = function()
						TS.nStyle = k
					end,
				})
			end
			return t
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	ui:Append('WndComboBox', {
		x = x, y = y, text = g_tStrings.STR_SHOW_HATRE_COUNTS,
		menu = function()
			local t = {}
			for k, v in ipairs({2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 50}) do -- 其实服务器最大反馈不到50个
				insert(t, {
					szOption = v,
					bMCheck = true,
					bChecked = TS.nMaxBarCount == v,
					fnAction = function()
						TS.nMaxBarCount = v
					end,
				})
			end
			return t
		end,
		autoenable = IsEnabled,
	})
	y = y + 28

	x = X
	ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_RAID_MENU_BG_ALPHA, autoenable = IsEnabled })
	x = x + 5
	y = y + 28
	ui:Append('WndTrackbar', {
		x = x, y = y, text = '',
		range = {0, 100},
		value = TS.nBGAlpha,
		onchange = function(nVal)
			TS.nBGAlpha = nVal
			local frame = _TS.GetFrame()
			if frame then
				frame.bg:SetAlpha(255 * TS.nBGAlpha / 100)
			end
		end,
		autoenable = IsEnabled,
	})
end
LIB.RegisterPanel(_L['Target'], 'MY_ThreatRank', g_tStrings.HATRED_COLLECT, 632, PS)

do
local function GetMenu()
	return {
		szOption = g_tStrings.HATRED_COLLECT,
		bCheck = true, bChecked = not not _TS.GetFrame(),
		fnAction = function()
			TS.bInDungeon = false
			if not _TS.GetFrame() then -- 这样才对嘛  按按钮应该强制开启和关闭
				TS.bEnable = true
			else
				TS.bEnable = false
			end
			_TS.CheckOpen()
		end
	}
end
LIB.RegisterAddonMenu(GetMenu)
end
LIB.RegisterEvent('LOADING_END', _TS.CheckOpen)
