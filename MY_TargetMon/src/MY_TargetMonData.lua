--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控数值计算相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMonData'

local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TargetMon.MapRestriction', { ['*'] = true })
--------------------------------------------------------------------------
local D = {}
local BUFF_CACHE = {} -- 下标为目标ID的目标BUFF缓存数组 反正ID不可能是doodad不会冲突
local BUFF_INFO = {} -- BUFF反向索引
local BUFF_TIME = {} -- BUFF最长持续时间
local SKILL_EXTRA = {} -- 缓存自己放过的技能用于扫描
local SKILL_CACHE = {} -- 下标为目标ID的目标技能缓存数组 反正ID不可能是doodad不会冲突
local SKILL_INFO = {} -- 技能反向索引
local VIEW_LIST = {}
local DEFAULT_CONTENT_COLOR = {255, 255, 255}

do
local function FilterMonitors(aMonitor, dwMapID, dwKungfuID)
	local ret = {}
	for i, mon in ipairs(aMonitor) do
		if mon.bEnable
		and (X.IsEmpty(mon.tMap) or mon.tMap.bAll or mon.tMap[dwMapID])
		and (X.IsEmpty(mon.tKungfu) or mon.tKungfu.bAll or mon.tKungfu[dwKungfuID]
			or ( -- 藏剑不区分心法
				(dwKungfuID == X.CONSTANT.KUNGFU_TYPE.WEN_SHUI or dwKungfuID == X.CONSTANT.KUNGFU_TYPE.SHAN_JU)
				and (mon.tKungfu[X.CONSTANT.KUNGFU_TYPE.WEN_SHUI] or mon.tKungfu[X.CONSTANT.KUNGFU_TYPE.SHAN_JU])
			)
		) then
			table.insert(ret, mon)
		end
	end
	return ret
end
local CACHE_CONFIG
function D.GetConfigList()
	if not CACHE_CONFIG then
		local me = X.GetClientPlayer()
		if not me then
			return MY_TargetMonConfig.GetConfigList()
		end
		local aConfig = {}
		local dwMapID = me.GetMapID() or 0
		local dwKungfuID = me.GetKungfuMountID() or 0
		for i, config in ipairs(MY_TargetMonConfig.GetConfigList()) do
			aConfig[i] = setmetatable(
				{
					aMonitor = FilterMonitors(config.aMonitor, dwMapID, dwKungfuID),
				},
				{ __index = config }
			)
		end
		CACHE_CONFIG = aConfig
	end
	return CACHE_CONFIG
end

local function onFilterChange()
	CACHE_CONFIG = nil
end
X.RegisterInit('MY_TargetMonData', onFilterChange)
X.RegisterKungfuMount('MY_TargetMonData', onFilterChange)
X.RegisterEvent('LOADING_ENDING', 'MY_TargetMonData', onFilterChange)

local function onTargetMonReload()
	VIEW_LIST = {}
	onFilterChange()
	D.OnTargetMonReload()
end
X.RegisterEvent('MY_TARGET_MON_CONFIG_RELOAD', 'MY_TargetMonData', onTargetMonReload)
X.RegisterEvent('MY_TARGET_MON_CONFIG_MODIFY', 'MY_TargetMonData', onTargetMonReload)
X.RegisterEvent('MY_TARGET_MON_CONFIG_MONITOR_MODIFY', 'MY_TargetMonData', onTargetMonReload)
end

do
local TEAM_MARK = {
	['TEAM_MARK_CLOUD'] = 1,
	['TEAM_MARK_SWORD'] = 2,
	['TEAM_MARK_AX'   ] = 3,
	['TEAM_MARK_HOOK' ] = 4,
	['TEAM_MARK_DRUM' ] = 5,
	['TEAM_MARK_SHEAR'] = 6,
	['TEAM_MARK_STICK'] = 7,
	['TEAM_MARK_JADE' ] = 8,
	['TEAM_MARK_DART' ] = 9,
	['TEAM_MARK_FAN'  ] = 10,
}
function D.GetTarget(eTarType, eMonType)
	if eMonType == 'SKILL' or eTarType == 'CONTROL_PLAYER' then
		return TARGET.PLAYER, X.GetControlPlayerID()
	elseif eTarType == 'CLIENT_PLAYER' then
		return TARGET.PLAYER, X.GetClientPlayerID()
	elseif eTarType == 'TARGET' then
		return X.GetTarget()
	elseif eTarType == 'TTARGET' then
		local KTarget = X.GetObject(X.GetTarget())
		if KTarget then
			return X.GetTarget(KTarget)
		end
	elseif TEAM_MARK[eTarType] then
		local mark = GetClientTeam().GetTeamMark()
		if mark then
			for dwID, nMark in pairs(mark) do
				if TEAM_MARK[eTarType] == nMark then
					return TARGET[X.IsPlayer(dwID) and 'PLAYER' or 'NPC'], dwID
				end
			end
		end
	end
	return TARGET.NO_TARGET, 0
end
end

do
local EVENT_UPDATE = {}
function D.RegisterDataUpdateEvent(frame, fnAction)
	if fnAction then
		EVENT_UPDATE[frame] = fnAction
	else
		EVENT_UPDATE[frame] = nil
	end
end

function D.FireDataUpdateEvent()
	for frame, fnAction in pairs(EVENT_UPDATE) do
		fnAction(frame)
	end
end
end

do
local SHIELDED
function D.IsShielded()
	if SHIELDED == nil then
		SHIELDED = X.IsRestricted('MY_TargetMon.MapRestriction') and X.IsInArena()
	end
	return SHIELDED
end

local function onShieldedReset()
	SHIELDED = nil
end
X.RegisterEvent('MY_RESTRICTION', 'MY_TargetMonData_Shield', function()
	if arg0 and arg0 ~= 'MY_TargetMon.MapRestriction' then
		return
	end
	onShieldedReset()
end)
X.RegisterEvent('LOADING_END', 'MY_TargetMonData_Shield', onShieldedReset)
end

do
local SHIELDED_BUFF = {}
function D.IsShieldedBuff(dwID, nLevel)
	if D.IsShielded() then
		local szKey = dwID .. ',' .. nLevel
		if SHIELDED_BUFF[szKey] == nil then
			local info = Table_GetBuff(dwID, nLevel)
			SHIELDED_BUFF[szKey] = not info or info.bShow == 0
		end
		return SHIELDED_BUFF[szKey]
	end
	return false
end
end

do
local function OnSkill(dwID, nLevel)
	SKILL_EXTRA[dwID] = dwID
end
local function OnSysMsg(event)
	if arg0 == 'UI_OME_SKILL_CAST_LOG' then
		if arg1 ~= X.GetClientPlayerID() then
			return
		end
		OnSkill(arg2, arg3)
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		if arg1 ~= X.GetClientPlayerID() then
			return
		end
		OnSkill(arg4, arg5)
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		if arg4 ~= SKILL_EFFECT_TYPE.SKILL or arg1 ~= X.GetClientPlayerID() then
			return
		end
		OnSkill(arg5, arg6)
	end
end
X.RegisterEvent('SYS_MSG', 'MY_TargetMon_SKILL', OnSysMsg)
end

-- 更新BUFF数据 更新监控条
do
local EXTENT_ANIMATE = {
	['[0.7,0.9)'] = 'ui\\Image\\Common\\Box.UITex|17',
	['[0.9,1]'] = 'ui\\Image\\Common\\Box.UITex|20',
	NONE = '',
}
local MON_EXIST_CACHE = {}
-- 通用：判断监控项是否显示
local function Base_ShowMon(mon, dwTarKungfuID)
	if not X.IsEmpty(mon.tTargetKungfu) and not mon.tTargetKungfu.bAll and not mon.tTargetKungfu[dwTarKungfuID] then
		return
	end
	return true
end
-- 通用：监控项转视图数据
local function Base_MonToView(mon, info, item, KObject, nIconID, config, tMonExist, tMonLast)
	-- 格式化完善视图列表信息
	if config.bShowTime and item.bCd and item.nTimeLeft and item.nTimeLeft > 0 then
		if config.bCdBar then
			item.szProcess = (
					item.nTimeLeft >= 60
						and X.FormatDuration(item.nTimeLeft - item.nTimeLeft % 60, 'ENGLISH_ABBR', { accuracyUnit = 'minute' })
						or ''
				)
				.. (
					(config.nDecimalTime == -1 or item.nTimeLeft < config.nDecimalTime)
						and ('%.1fs'):format(item.nTimeLeft % 60)
						or ('%ds'):format(item.nTimeLeft % 60)
				)
			item.szTimeLeft = ''
		else
			local nTimeLeft, szTimeLeft = item.nTimeLeft, ''
			if nTimeLeft <= 3600 then
				if nTimeLeft > 60 then
					if config.nDecimalTime == -1 or nTimeLeft < config.nDecimalTime then
						szTimeLeft = '%d\'%.1f'
					else
						szTimeLeft = '%d\'%d'
					end
					szTimeLeft = szTimeLeft:format(math.floor(nTimeLeft / 60), nTimeLeft % 60)
				else
					if config.nDecimalTime == -1 or nTimeLeft < config.nDecimalTime then
						szTimeLeft = '%.1f'
					else
						szTimeLeft = '%d'
					end
					szTimeLeft = szTimeLeft:format(nTimeLeft)
				end
			end
			item.szTimeLeft = szTimeLeft
			item.szProcess = ''
		end
	else
		item.szTimeLeft = ''
		item.szProcess = ''
	end
	if not config.bShowName then
		item.szLongName = ''
		item.szShortName = ''
	end
	if not item.nIconID then
		item.nIconID = 13
	end
	if config.bCdFlash and item.bCd then
		if item.fProgress >= 0.9 then
			item.szExtentAnimate = EXTENT_ANIMATE['[0.9,1]']
		elseif item.fProgress >= 0.7 then
			item.szExtentAnimate = EXTENT_ANIMATE['[0.7,0.9)']
		else
			item.szExtentAnimate = EXTENT_ANIMATE.NONE
		end
		item.bStaring = item.fProgress > 0.5
	else
		item.bStaring = false
		item.szExtentAnimate = EXTENT_ANIMATE.NONE
	end
	if item.szExtentAnimate == EXTENT_ANIMATE.NONE and item.bActive and mon.szExtentAnimate then
		item.szExtentAnimate = mon.szExtentAnimate
	end
	if not config.bCdCircle then
		item.bCd = false
	end
	if info and info.bCool then
		if tMonLast and not tMonLast[mon.szUUID] and config.bPlaySound and mon.aSoundAppear then
			local dwSoundID = X.RandomChild(mon.aSoundAppear)
			if dwSoundID then
				local szSoundPath = X.GetSoundPath(dwSoundID)
				if szSoundPath then
					X.PlaySound(SOUND.UI_SOUND, szSoundPath, false)
				end
			end
		end
		tMonExist[mon.szUUID] = mon
	end
end
-- BUFF：判断监控项是否显示
local function Buff_ShowMon(mon, dwTarKungfuID)
	return Base_ShowMon(mon, dwTarKungfuID)
end
-- BUFF：监控项匹配 BUFF 对象
local function Buff_MatchMon(tAllBuff, mon, config)
	local dwClientID, dwControlID = X.GetClientPlayerID(), X.GetControlPlayerID()
	local tBuff = tAllBuff[mon.dwID]
	if tBuff then
		for _, buff in pairs(tBuff) do
			if buff and buff.bCool then
				if (
					config.bHideOthers == mon.bFlipHideOthers
					or buff.dwSkillSrcID == dwClientID
					or buff.dwSkillSrcID == dwControlID
				)
				and (not D.IsShieldedBuff(buff.dwID, buff.nLevel))
				and (mon.nLevel == 0 or mon.nLevel == buff.nLevel)
				and (not mon.nStackNum or mon.nStackNum == 0 or mon.nStackNum == buff.nStackNum) then
					return buff, mon.nIconID ~= 13 and mon.nIconID or buff.nIcon or 13
				end
			end
		end
	end
end
-- BUFF：监控项转视图数据
local function Buff_MonToView(mon, buff, item, KObject, nIconID, config, tMonExist, tMonLast)
	if nIconID then
		item.nIconID = nIconID
	end
	if buff and buff.bCool then
		if not item.nIconID then
			item.nIconID = buff.nIcon
		end
		local nTimeLeft = buff.nLeft * 0.0625
		if not BUFF_TIME[KObject.dwID] then
			BUFF_TIME[KObject.dwID] = {}
		end
		if not BUFF_TIME[KObject.dwID][buff.szKey] or BUFF_TIME[KObject.dwID][buff.szKey] < nTimeLeft then
			BUFF_TIME[KObject.dwID][buff.szKey] = nTimeLeft
		end
		local nTimeTotal = BUFF_TIME[KObject.dwID][buff.szKey]
		item.bActive = true
		item.bCd = true
		item.fCd = nTimeLeft / nTimeTotal
		item.fCdBar = item.fCd
		item.bCdBarFlash = true
		item.fProgress = 1 - item.fCd
		item.bSparking = false
		item.dwID = buff.dwID
		item.nLevel = buff.nLevel
		item.nTimeLeft = nTimeLeft
		item.szStackNum = buff.nStackNum > 1 and buff.nStackNum or ''
		item.nTimeTotal = nTimeTotal
		item.szContent = X.IsEmpty(mon.szContent) and X.GetBuffName(buff.dwID, buff.nLevel) or mon.szContent
	else
		item.bActive = false
		item.bCd = true
		item.fCd = 0
		item.fCdBar = 0
		item.bCdBarFlash = false
		item.fProgress = 0
		item.nTimeLeft = -1
		item.bSparking = true
		item.dwID = mon.dwID
		item.nLevel = mon.nLevel
		item.nIconID = mon.nIconID
		item.szStackNum = ''
		item.szContent = X.IsEmpty(mon.szContent) and X.GetBuffName(mon.dwID, mon.nLevel) or mon.szContent
	end
	item.aContentColor = mon.aContentColor or DEFAULT_CONTENT_COLOR
	Base_MonToView(mon, buff, item, KObject, nIconID, config, tMonExist, tMonLast)
end
-- 技能：判断监控项是否显示
local function Skill_ShowMon(mon, dwTarKungfuID)
	return Base_ShowMon(mon, dwTarKungfuID)
end
-- 技能：监控项匹配 BUFF 对象
local function Skill_MatchMon(tSkill, mon, config)
	local skill = tSkill[mon.dwID]
	if skill and (mon.nLevel == 0 or mon.nLevel == skill.nLevel) then
		return skill, mon.nIconID ~= 13 and mon.nIconID or skill.nIcon or 13
	end
end
-- 技能：监控项转视图数据
local function Skill_MonToView(mon, skill, item, KObject, nIconID, config, tMonExist, tMonLast)
	if nIconID then
		item.nIconID = nIconID
	end
	if skill and skill.bCool then
		if not item.nIconID then
			item.nIconID = skill.nIcon
		end
		local nTimeLeft = skill.nCdLeft * 0.0625
		local nTimeTotal = skill.nCdTotal * 0.0625
		item.bActive = false
		item.bCd = true
		item.fCd = 1 - nTimeLeft / nTimeTotal
		item.fCdBar = item.fCd
		item.bCdBarFlash = true
		item.fProgress = item.fCd
		item.bSparking = false
		item.dwID = skill.dwID
		item.nLevel = skill.nLevel
		item.nTimeLeft = nTimeLeft
		item.nTimeTotal = nTimeTotal
		item.szContent = X.IsEmpty(mon.szContent) and skill.szName or mon.szContent
	else
		item.bActive = true
		item.bCd = false
		item.fCd = 1
		item.fCdBar = 1
		item.bCdBarFlash = false
		item.fProgress = 0
		item.bSparking = true
		item.dwID = mon.dwID
		item.nLevel = mon.nLevel
		item.szContent = X.IsEmpty(mon.szContent) and X.GetSkillName(mon.dwID, mon.nLevel) or mon.szContent
	end
	local nStackNum = (skill and skill.nCdMaxCount > 1)
		and (skill.nCdMaxCount - skill.nCdCount)
		or 0
	item.szStackNum = nStackNum > 0 and nStackNum or ''
	item.aContentColor = mon.aContentColor or DEFAULT_CONTENT_COLOR
	Base_MonToView(mon, skill, item, KObject, nIconID, config, tMonExist, tMonLast)
end
local UpdateView
do
local fUIScale, fFontScaleBase
function UpdateView()
	local nViewIndex, nViewCount = 1, #VIEW_LIST
	for _, config in ipairs(D.GetConfigList()) do
		if config.bEnable then
			local dwTarType, dwTarID = D.GetTarget(config.szTarget, config.szType)
			local KObject = X.GetObject(dwTarType, dwTarID)
			local dwTarKungfuID = KObject
				and (dwTarType == TARGET.PLAYER
					and (KObject.GetKungfuMountID() or 0)
					or 'npc'
				)
				or 0
			local view = VIEW_LIST[nViewIndex]
			if not view then
				view = {}
				VIEW_LIST[nViewIndex] = view
			end
			fUIScale = (config.bIgnoreSystemUIScale and 1 or Station.GetUIScale()) * config.fScale
			fFontScaleBase = fUIScale * X.GetFontScale() * config.fScale
			view.szUUID               = config.szUUID
			view.szType               = config.szType
			view.szTarget             = config.szTarget
			view.szCaption            = MY_TargetMonConfig.GetConfigTitle(config)
			view.tAnchor              = config.tAnchor
			view.bIgnoreSystemUIScale = config.bIgnoreSystemUIScale
			view.fUIScale             = fUIScale
			view.fIconFontScale       = fFontScaleBase * config.fIconFontScale
			view.fOtherFontScale      = fFontScaleBase * config.fOtherFontScale
			view.bPenetrable          = config.bPenetrable
			view.bDraggable           = config.bDraggable
			view.szAlignment          = config.szAlignment
			view.nMaxLineCount        = config.nMaxLineCount
			view.bCdCircle            = config.bCdCircle
			view.bCdFlash             = config.bCdFlash
			view.bCdReadySpark        = config.bCdReadySpark
			view.bCdBar               = config.bCdBar
			view.nCdBarWidth          = config.nCdBarWidth
			-- view.playSound         = config.bPlaySound
			view.szCdBarUITex         = config.szCdBarUITex
			view.szBoxBgUITex         = config.szBoxBgUITex
			local aItem = view.aItem
			if not aItem then
				aItem = {}
				view.aItem = aItem
			end
			local nItemIndex, nItemCount = 1, #aItem
			local tMonExist, tMonLast = {}, MON_EXIST_CACHE[config.szUUID]
			if config.szType == 'BUFF' then
				local tBuff = KObject and BUFF_CACHE[KObject.dwID] or X.CONSTANT.EMPTY_TABLE
				for _, mon in ipairs(config.aMonitor) do
					if Buff_ShowMon(mon, dwTarKungfuID) then
						-- 通过监控项生成视图列表
						local buff, nIconID = Buff_MatchMon(tBuff, mon, config)
						if (buff and buff.bCool) or not config.bHideVoid == not mon.bFlipHideVoid then
							local item = aItem[nItemIndex]
							if not item then
								item = {}
								aItem[nItemIndex] = item
							end
							Buff_MonToView(mon, buff, item, KObject, nIconID, config, tMonExist, tMonLast)
							nItemIndex = nItemIndex + 1
						end
					end
				end
			elseif config.szType == 'SKILL' then
				local tSkill = KObject and SKILL_CACHE[KObject.dwID] or X.CONSTANT.EMPTY_TABLE
				for _, mon in ipairs(config.aMonitor) do
					if Skill_ShowMon(mon, dwTarKungfuID) then
						-- 通过监控项生成视图列表
						local skill, nIconID = Skill_MatchMon(tSkill, mon, config)
						if (skill and skill.bCool) or not config.bHideVoid == not mon.bFlipHideVoid then
							local item = aItem[nItemIndex]
							if not item then
								item = {}
								aItem[nItemIndex] = item
							end
							Skill_MonToView(mon, skill, item, KObject, nIconID, config, tMonExist, tMonLast)
							nItemIndex = nItemIndex + 1
						end
					end
				end
			end
			for i = nItemIndex, nItemCount do
				aItem[i] = nil
			end
			if tMonLast then
				for uuid, mon in pairs(tMonLast) do
					if not tMonExist[uuid] and config.bPlaySound and mon.aSoundDisappear then
						local dwSoundID = X.RandomChild(mon.aSoundDisappear)
						if dwSoundID then
							local szSoundPath = X.GetSoundPath(dwSoundID)
							if szSoundPath then
								X.PlaySound(SOUND.UI_SOUND, szSoundPath, false)
							end
						end
					end
				end
			end
			MON_EXIST_CACHE[config.szUUID] = tMonExist
			nViewIndex = nViewIndex + 1
		end
	end
	for i = nViewIndex, nViewCount do
		VIEW_LIST[i] = nil
	end
	D.FireDataUpdateEvent()
end
end

local function OnFrameCall()
	local tExistBuffMonitorTargetType = {}
	local tExistSkillMonitorTargetType = {}
	for _, config in ipairs(MY_TargetMonConfig.GetConfigList()) do
		if config.bEnable then
			if config.szType == 'BUFF' then
				tExistBuffMonitorTargetType[config.szTarget] = true
			elseif config.szType == 'SKILL' then
				tExistSkillMonitorTargetType[config.szTarget] = true
			end
		end
	end
	-- 更新各目标BUFF数据
	local nLogicFrame, info = GetLogicFrameCount()
	for eType, _ in pairs(tExistBuffMonitorTargetType) do
		local KObject = X.GetObject(D.GetTarget(eType, 'BUFF'))
		if KObject then
			local tCache = BUFF_CACHE[KObject.dwID]
			if not tCache then
				tCache = {}
				BUFF_CACHE[KObject.dwID] = tCache
			end
			-- 当前身上的buff
			for _, buff in X.ipairs_c(X.GetBuffList(KObject)) do -- 缓存时必须复制buff表 否则buff过期后表会被回收导致显示错误的BUFF
				-- 正向索引用于监控
				if not tCache[buff.dwID] then
					tCache[buff.dwID] = {}
				end
				info = tCache[buff.dwID][buff.szKey]
				if not info then
					info = {}
					tCache[buff.dwID][buff.szKey] = info
				end
				X.CloneBuff(buff, info)
				info.nLeft = math.max(buff.nEndFrame - nLogicFrame, 0)
				info.bCool = true
				info.nRenderFrame = nLogicFrame
				-- 反向索引用于捕获
				if not BUFF_INFO[buff.szName] then
					BUFF_INFO[buff.szName] = {}
				end
				if not BUFF_INFO[buff.szName][buff.szKey] then
					BUFF_INFO[buff.szName][buff.szKey] = {
						szName = buff.szName,
						dwID = buff.dwID,
						nLevel = buff.nLevel,
						szKey = buff.szKey,
						nIcon = buff.nIcon,
					}
				end
			end
			-- 处理消失的buff
			for _, tBuff in pairs(tCache) do
				for k, info in pairs(tBuff) do
					if info.nRenderFrame ~= nLogicFrame then
						if info.bCool then
							info.nLeft = 0
							info.bCool = false
						end
						info.nRenderFrame = nLogicFrame
					end
				end
			end
		end
	end
	for eType, _ in pairs(tExistSkillMonitorTargetType) do
		local KObject = X.GetObject(D.GetTarget(eType, 'SKILL'))
		if KObject then
			local tSkill = {}
			local aSkill = X.GetSkillMountList()
			-- 遍历所有技能 生成反向索引
			for _, dwID in X.spairs(aSkill, SKILL_EXTRA) do
				if not tSkill[dwID] then
					local nLevel = KObject.GetSkillLevel(dwID)
					local KSkill, info = X.GetSkill(dwID, nLevel)
					if KSkill and info then
						local szKey, szName = dwID, X.GetSkillName(dwID)
						if not SKILL_INFO[szName] then
							SKILL_INFO[szName] = {}
						end
						if not SKILL_INFO[szName][szKey] then
							SKILL_INFO[szName][szKey] = {}
						end
						local skill = SKILL_INFO[szName][szKey]
						local bCool, szType, nLeft, nInterval, nTotal, nCount, nMaxCount, nSurfaceNum = X.GetSkillCDProgress(KObject, dwID, nLevel, true)
						skill.szKey = szKey
						skill.dwID = dwID
						skill.nLevel = info.nLevel
						skill.bCool = bCool or nCount > 0
						skill.szCdType = szType
						skill.nCdLeft = nLeft
						skill.nCdInterval = nInterval
						skill.nCdTotal = nTotal
						skill.nCdCount = nCount
						skill.nCdMaxCount = nMaxCount
						skill.nSurfaceNum = nSurfaceNum
						skill.nIcon = info.nIcon
						skill.szName = X.GetSkillName(dwID)
						tSkill[szKey] = skill
						tSkill[dwID] = skill
						tSkill[szName] = skill
					end
				end
			end
			-- 处理消失的buff
			local tLastSkill = SKILL_CACHE[KObject.dwID]
			if tLastSkill then
				for k, skill in pairs(tLastSkill) do
					if not tSkill[k] then
						if skill.bCool then
							skill.bCool = false
							skill.nLeft = 0
							skill.nCount = 0
						end
						tSkill[k] = skill
					end
				end
			end
			SKILL_CACHE[KObject.dwID] = tSkill
		end
	end
	UpdateView()
end

function D.OnTargetMonReload()
	OnFrameCall()
	FireUIEvent('MY_TARGET_MON_DATA_INIT')
	X.FrameCall('MY_TargetMonData', 2, OnFrameCall)
end
end

function D.GetViewData(nIndex)
	if nIndex then
		return VIEW_LIST[nIndex]
	end
	return VIEW_LIST
end

----------------------------------------------------------------------------------------------
-- 快捷键
----------------------------------------------------------------------------------------------
do
for i = 1, 5 do
	for j = 1, 10 do
		Hotkey.AddBinding(
			'MY_TargetMon_' .. i .. '_' .. j, _L('Cancel buff %d - %d', i, j),
			i == 1 and j == 1 and _L['MY Buff Monitor'] or '',
			function()
				if X.IsRestricted('MY_TargetMon.MapRestriction') and (X.IsInArena() or X.IsInBattleField()) then
					OutputMessage('MSG_ANNOUNCE_RED', _L['Cancel buff is disabled in arena and battlefield.'])
					return
				end
				local tViewData = D.GetViewData(i)
				if not tViewData or tViewData.szType ~= 'BUFF' then
					OutputMessage('MSG_ANNOUNCE_RED', _L['Hotkey cancel is only allowed for buff.'])
					return
				end
				local KTarget = X.GetObject(D.GetTarget(tViewData.szTarget, tViewData.szType))
				if not KTarget then
					OutputMessage('MSG_ANNOUNCE_RED', _L['Cannot find target to cancel buff.'])
					return
				end
				local item = tViewData.aItem[j]
				if not item or not item.bActive then
					OutputMessage('MSG_ANNOUNCE_RED', _L['Cannot find buff to cancel.'])
					return
				end
				X.CancelBuff(KTarget, item.dwID, item.nLevel)
			end, nil)
	end
end
end

-- Global exports
do
local settings = {
	name = 'MY_TargetMonData',
	exports = {
		{
			fields = {
				GetTarget = D.GetTarget,
				GetViewData = D.GetViewData,
				RegisterDataUpdateEvent = D.RegisterDataUpdateEvent,
			},
		},
	},
}
MY_TargetMonData = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
