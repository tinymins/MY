--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 仇恨统计
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_ThreatRank/MY_ThreatRank'
local PLUGIN_NAME = 'MY_ThreatRank'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ThreatRank'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ThreatRank', _L['Target'], {
	bEnable = { -- 开启
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['Enable ThreatScrutiny'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bInDungeon = { -- 只有秘境内才开启
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['Only in the map type is Dungeon Enable plug-in'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nBGAlpha = { -- 背景透明度
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			g_tStrings.STR_RAID_MENU_BG_ALPHA,
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 30,
	},
	nMaxBarCount = { -- 最大列表
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			g_tStrings.STR_SHOW_HATRE_COUNTS,
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 7,
	},
	bForceColor = { -- 根据门派着色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bForceIcon = { -- 显示门派图标 团队时显示心法
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			g_tStrings.STR_SHOW_KUNGFU,
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nOTAlertLevel = { -- OT提醒
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['OT Alert'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	bOTAlertSound = { -- OT 播放声音
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['OT Alert Sound'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSpecialSelf = { -- 特殊颜色显示自己
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['Special Self'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTopTarget = { -- 置顶当前目标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['Top Target'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowPercent = { -- 是否为显示百分比模式
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['Show percent'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['UI Anchor'],
		}),
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -300, y = 300 },
	},
	nStyle = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ThreatRank'],
		szDescription = X.MakeCaption({
			_L['Style Select'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
})

local TS = {}
local ipairs, pairs = ipairs, pairs
local MY_GetPlayer, MY_GetNpc, MY_IsPlayer, ApplyCharacterThreatRankList = X.GetPlayer, X.GetNpc, X.IsPlayer, ApplyCharacterThreatRankList
local MY_GetClientPlayer, GetClientTeam = X.GetClientPlayer, GetClientTeam
local MY_GetClientPlayerID, GetTime = UI_GetClientPlayerID, GetTime
local HATRED_COLLECT = g_tStrings.HATRED_COLLECT
local MY_GetForceColor = X.GetForceColor
local MY_GetBuff, MY_GetBuffName, MY_GetEndTime = X.GetBuff, X.GetBuffName, X.GetEndTime
local GetNpcIntensity = GetNpcIntensity
local GetTime = GetTime

local TS_INIFILE = X.PACKET_INFO.ROOT .. 'MY_ThreatRank/ui/MY_ThreatRank.ini'

local _TS = {
	tStyle = LoadLUAData(X.PACKET_INFO.ROOT .. 'MY_ThreatRank/data/style.jx3dat'),
}
local function IsEnabled() return O.bEnable end

function TS.OnFrameCreate()
	this:RegisterEvent('CHARACTER_THREAT_RANKLIST')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('TARGET_CHANGE')
	this:RegisterEvent('FIGHT_HINT')
	this:RegisterEvent('LOADING_END')
	this.hItemData      = this:CreateItemData(X.PACKET_INFO.ROOT .. 'MY_ThreatRank/ui/Handle_ThreatBar.ini', 'Handle_ThreatBar')
	this.dwTargetID     = 0
	this.nTime          = 0
	this.bSelfTreatRank = 0
	this.bg         = this:Lookup('', 'Image_Background')
	this.bg:SetAlpha(255 * O.nBGAlpha / 100)
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
		if dwType == TARGET.NPC or MY_GetNpc(this.dwLockTargetID) then
			if MY_GetNpc(this.dwLockTargetID) then
				dwTargetID = this.dwLockTargetID
			else
				dwTargetID = dwID
			end
		elseif dwType == TARGET.PLAYER and MY_GetPlayer(dwID) then
			local tdwType, tdwID = MY_GetPlayer(dwID).GetTarget()
			if tdwType == TARGET.NPC then
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
	local p = MY_GetNpc(this.dwTargetID)
	if p then
		ApplyCharacterThreatRankList(this.dwTargetID)
		local nType, dwSkillID, dwSkillLevel, fCastPercent = X.GetCharacterOTActionState(p)
		local fCurrentLife, fMaxLife = X.GetCharacterLife(p)
		if nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
		or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
		or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE then
			this.CastBar:Show()
			this.CastBar:SetPercentage(fCastPercent)
			local szName = X.GetSkillName(dwSkillID, dwSkillLevel)
			this.txt:SetText(szName)
		else
			local lifeper = fCurrentLife / fMaxLife
			this.CastBar:Hide()
			this.txt:SetText(X.GetNpcName(p.dwID) .. string.format(' (%0.1f%%)', lifeper * 100))
			this.Life:SetPercentage(lifeper)
		end

		-- 无威胁提醒
		local buff = MY_GetBuff(MY_GetClientPlayer(), {
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
			hText:SetText(string.format('%s (%ds)', szName, math.floor(MY_GetEndTime(buff.nEndFrame))) .. szText)
			hText:SetFontColor(0, 255, 0)
		else
			hText:SetText(HATRED_COLLECT .. szText)
			hText:SetFontColor(255, 255, 255)
			hText.bBuff = nil
		end

		-- 开怪提醒
		if this.nTime >= 0 and GetTime() - this.nTime > 1000 * 7 and GetNpcIntensity(p) > 2 then
			local me = MY_GetClientPlayer()
			if not me.bFightState then return end
			this.nTime = -1
			X.DelayCall(1000, function()
				if not me.IsInParty() then return end
				if p and p.dwDropTargetPlayerID and p.dwDropTargetPlayerID ~= 0 then
					if IsParty(me.dwID, p.dwDropTargetPlayerID) or me.dwID == p.dwDropTargetPlayerID then
						local team = GetClientTeam()
						local szMember = team.GetClientTeamMemberName(p.dwDropTargetPlayerID)
						local nGroup = team.GetMemberGroupIndex(p.dwDropTargetPlayerID) + 1
						local name = X.GetNpcName(p.dwID)
						local oContent = {_L('Well done! %s in %d group first to attack %s!!', nGroup, szMember, name), r = 150, g = 250, b = 230}
						local oTitle = {g_tStrings.HATRED_COLLECT, r = 150, g = 250, b = 230}
						X.OutputSystemMessage(oTitle, oContent)
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
		X.Panel.Show()
		X.Panel.Focus()
		X.Panel.SwitchTab('MY_ThreatRank')
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
	O.tAnchor = GetFrameAnchor(this)
end

function _TS.GetFrame()
	return Station.Lookup('Normal/MY_ThreatRank')
end

function _TS.CheckOpen()
	if O.bEnable then
		if O.bInDungeon then
			if X.IsInDungeonMap() then
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
		frame = X.UI.OpenFrame(TS_INIFILE, 'MY_ThreatRank')
		local dwType = Target_GetTargetData()
		if dwType ~= TARGET.NPC then
			frame:Hide()
		end
	end
	return frame
end

function _TS.ClosePanel()
	if _TS.GetFrame() then
		X.UI.CloseFrame(_TS.GetFrame())
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
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
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
		local p = MY_GetNpc(dwApplyID)
		if p then
			local _, tdwID = p.GetTarget()
			if tdwID and tdwID ~= 0 and tdwID ~= dwTargetID and tList[tdwID] then -- 原来是0 搞半天。。
				dwTargetID = tdwID
			end
		end
	end
	-- 重构用于排序
	for k, v in pairs(tList) do
		table.insert(tThreat, { id = k, val = v })
	end
	table.sort(tThreat, function(a, b) return a.val > b.val end) -- 进行排序
	for k, v in ipairs(tThreat) do
		v.sort = k
		if v.id == MY_GetClientPlayerID() then
			tMyRank = v
		end
	end
	this.bg:SetH(55 + 24 * math.min(#tThreat, O.nMaxBarCount))
	this.handle:Clear()
	local KGnpc = MY_GetNpc(dwApplyID)
	if #tThreat > 0 and KGnpc then
		this:Show()
		if #tThreat >= 2 then
			if O.bTopTarget and tList[dwTargetID] then
				for k, v in ipairs(tThreat) do
					if v.id == dwTargetID then
						table.insert(tThreat, 1, table.remove(tThreat, k))
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

		local dat = _TS.tStyle[O.nStyle] or _TS.tStyle[1]
		local show = false
		for k, v in ipairs(tThreat) do
			if k > O.nMaxBarCount then break end
			local dwMeID = MY_GetClientPlayerID()
			if dwMeID == v.id then
				if O.nOTAlertLevel > 0 and GetNpcIntensity(KGnpc) > 2 then
					if this.bSelfTreatRank < O.nOTAlertLevel and v.val / nTopRank >= O.nOTAlertLevel then
						X.OutputAnnounceMessage(_L('** You Threat more than %d, 120% is Out of Taunt! **', O.nOTAlertLevel * 100))
						if O.bOTAlertSound then
							PlaySound(SOUND.UI_SOUND, _L['SOUND_nat_view2'])
						end
					end
				end
				this.bSelfTreatRank = v.val / nTopRank
				show = true
			elseif k == O.nMaxBarCount and not show and tList[MY_GetClientPlayerID()] then -- 始终显示自己的
				v = tMyRank
			end

			local item = this.handle:AppendItemFromData(this.hItemData, k)
			local nThreatPercentage, fDiff = 0, 0
			if O.bShowPercent then
				if v.val ~= 0 then
					fDiff = v.val / nTopRank
					nThreatPercentage = fDiff * (100 / 120)
					item:Lookup('Text_ThreatValue'):SetText(math.floor(100 * fDiff) .. '%')
				else
					item:Lookup('Text_ThreatValue'):SetText('0%')
				end
			else
				item:Lookup('Text_ThreatValue'):SetText(v.val)
			end
			item:Lookup('Text_ThreatValue'):SetFontScheme(dat[6][2])

			if v.id == dwTargetID then
				if dwTargetID == MY_GetClientPlayerID() then
					item:Lookup('Image_Target'):SetFrame(10)
				end
				item:Lookup('Image_Target'):Show()
			end

			local r, g, b = 188, 188, 188
			local szName, dwForceID = _L['Loading...'], 0
			if MY_IsPlayer(v.id) then
				local p = MY_GetPlayer(v.id)
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
				if O.bForceColor and p then
					r, g, b = MY_GetForceColor(p.dwForceID)
				else
					r, g, b = 255, 255, 255
				end
			else
				local p = MY_GetNpc(v.id)
				if p then
					szName = X.GetNpcName(p.dwID, { eShowEmployer = 'suffix' })
					if p.dwEmployer == dwMeID then
						r, g, b = 230, 230, 230
					end
				end
			end
			item:Lookup('Text_ThreatName'):SetText(v.sort .. '.' .. szName)
			item:Lookup('Text_ThreatName'):SetFontScheme(dat[6][1])
			item:Lookup('Text_ThreatName'):SetFontColor(r, g, b)
			if O.bForceIcon then
				local info = X.IsTeammate(v.id) and MY_IsPlayer(v.id) and X.GetTeamMemberInfo(v.id)
				if info then
					item:Lookup('Image_Icon'):FromIconID(Table_GetSkillIconID(info.dwActualMountKungfuID, 1))
				elseif MY_IsPlayer(v.id) then
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
			if O.bSpecialSelf and v.id == MY_GetClientPlayerID() then
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

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ThreatRank',
	exports = {
		{
			preset = 'UIEvent',
			root = TS,
		},
	},
}
MY_ThreatRank = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------
do
local function GetMenu()
	return {
		szOption = g_tStrings.HATRED_COLLECT,
		bCheck = true, bChecked = not not _TS.GetFrame(),
		fnAction = function()
			O.bInDungeon = false
			if not _TS.GetFrame() then -- 这样才对嘛  按按钮应该强制开启和关闭
				O.bEnable = true
			else
				O.bEnable = false
			end
			_TS.CheckOpen()
		end
	}
end
X.RegisterAddonMenu(GetMenu)
end
X.RegisterEvent('LOADING_END', _TS.CheckOpen)
X.RegisterUserSettingsInit('MY_ThreatRank', _TS.CheckOpen)

--------------------------------------------------------------------------------
-- 界面注册
--------------------------------------------------------------------------------

local PS = {}
function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	ui:Append('Text', { x = nX, y = nY, text = g_tStrings.HATRED_COLLECT, font = 27 })
	nX = nX + 10
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 130, checked = O.bEnable, text = _L['Enable ThreatScrutiny'],
		onCheck = function(bChecked)
			O.bEnable = bChecked
			_TS.CheckOpen()
		end,
	})
	nX = nX + 130

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250, checked = O.bInDungeon,
		enable = O.bEnable,
		text = _L['Only in the map type is Dungeon Enable plug-in'],
		onCheck = function(bChecked)
			O.bInDungeon = bChecked
			_TS.CheckOpen()
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Alert Setting'], font = 27, autoEnable = IsEnabled })
	nX = nX + 10
	nY = nY + 28
	ui:Append('WndCheckBox', {
		x = nX, y = nY, checked = O.nOTAlertLevel == 1, text = _L['OT Alert'],
		onCheck = function(bChecked)
			if bChecked then -- 以后可以做% 暂时先不管
				O.nOTAlertLevel = 1
			else
				O.nOTAlertLevel = 0
			end
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX, y = nY, checked = O.bOTAlertSound, text = _L['OT Alert Sound'],
		onCheck = function(bChecked)
			O.bOTAlertSound = bChecked
		end,
		autoEnable = function() return IsEnabled() and O.nOTAlertLevel == 1 end,
	})
	nY = nY + 28

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Style Setting'], font = 27, autoEnable = IsEnabled })
	nY = nY + 28

	nX = nX + 10
	ui:Append('WndCheckBox', {
		x = nX , y = nY, checked = O.bShowPercent, text = _L['Show percent'],
		onCheck = function(bChecked)
			O.bShowPercent = bChecked
		end,
		autoEnable = IsEnabled,
	})

	nY = nY + 28
	ui:Append('WndCheckBox', {
		x = nX , y = nY, checked = O.bTopTarget, text = _L['Top Target'],
		onCheck = function(bChecked)
			O.bTopTarget = bChecked
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX , y = nY, checked = O.bForceColor, text = g_tStrings.STR_RAID_COLOR_NAME_SCHOOL,
		onCheck = function(bChecked)
			O.bForceColor = bChecked
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX , y = nY, checked = O.bForceIcon, text = g_tStrings.STR_SHOW_KUNGFU,
		onCheck = function(bChecked)
			O.bForceIcon = bChecked
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	ui:Append('WndCheckBox', {
		x = nX , y = nY, w = 200, checked = O.bSpecialSelf, text = _L['Special Self'],
		onCheck = function(bChecked)
			O.bSpecialSelf = bChecked
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	ui:Append('WndComboBox', {
		x = nX, y = nY, text = _L['Style Select'],
		menu = function()
			local t = {}
			for k, v in ipairs(_TS.tStyle) do
				table.insert(t, {
					szOption = _L('Style %d', k),
					bMCheck = true,
					bChecked = O.nStyle == k,
					fnAction = function()
						O.nStyle = k
					end,
				})
			end
			return t
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	ui:Append('WndComboBox', {
		x = nX, y = nY, text = g_tStrings.STR_SHOW_HATRE_COUNTS,
		menu = function()
			local t = {}
			for k, v in ipairs({2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 50}) do -- 其实服务器最大反馈不到50个
				table.insert(t, {
					szOption = v,
					bMCheck = true,
					bChecked = O.nMaxBarCount == v,
					fnAction = function()
						O.nMaxBarCount = v
					end,
				})
			end
			return t
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + 28

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = g_tStrings.STR_RAID_MENU_BG_ALPHA, autoEnable = IsEnabled })
	nX = nX + 5
	nY = nY + 28
	ui:Append('WndSlider', {
		x = nX, y = nY, text = '',
		range = {0, 100},
		value = O.nBGAlpha,
		onChange = function(nVal)
			O.nBGAlpha = nVal
			local frame = _TS.GetFrame()
			if frame then
				frame.bg:SetAlpha(255 * O.nBGAlpha / 100)
			end
		end,
		autoEnable = IsEnabled,
	})
end
X.Panel.Register(_L['Target'], 'MY_ThreatRank', g_tStrings.HATRED_COLLECT, 632, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
