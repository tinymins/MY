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
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TargetMon.MapRestriction', { ['*'] = true })
--------------------------------------------------------------------------
local C, D = {}, {
	GetTargetTypeList = MY_TargetMonConfig.GetTargetTypeList,
	GetConfigCaption = MY_TargetMonConfig.GetConfigCaption,
	ModifyMonitor = MY_TargetMonConfig.ModifyMonitor,
	CreateMonitorId = MY_TargetMonConfig.CreateMonitorId,
	ModifyMonitorId = MY_TargetMonConfig.ModifyMonitorId,
	CreateMonitorLevel = MY_TargetMonConfig.CreateMonitorLevel,
	ModifyMonitorLevel = MY_TargetMonConfig.ModifyMonitorLevel,
}
local BUFF_CACHE = {} -- 下标为目标ID的目标BUFF缓存数组 反正ID不可能是doodad不会冲突
local BUFF_INFO = {} -- BUFF反向索引
local BUFF_TIME = {} -- BUFF最长持续时间
local SKILL_EXTRA = {} -- 缓存自己放过的技能用于扫描
local SKILL_CACHE = {} -- 下标为目标ID的目标技能缓存数组 反正ID不可能是doodad不会冲突
local SKILL_INFO = {} -- 技能反向索引
local VIEW_LIST = {}
local BOX_SPARKING_FRAME = X.ENVIRONMENT.GAME_FPS * 2 / 3

do
local function FilterMonitors(monitors, dwMapID, dwKungfuID)
	local ret = {}
	for i, mon in ipairs(monitors) do
		if mon.enable
		and (not next(mon.maps) or mon.maps.all or mon.maps[dwMapID])
		and (not next(mon.kungfus) or mon.kungfus.all or mon.kungfus[dwKungfuID]) then
			table.insert(ret, mon)
		end
	end
	return ret
end
local CACHE_CONFIG
function D.GetConfigList()
	if not CACHE_CONFIG then
		local me = GetClientPlayer()
		if not me then
			return MY_TargetMonConfig.GetConfigList()
		end
		local aConfig = {}
		local dwMapID = me.GetMapID() or 0
		local dwKungfuID = me.GetKungfuMountID() or 0
		for i, config in ipairs(MY_TargetMonConfig.GetConfigList()) do
			aConfig[i] = setmetatable({
				monitors = FilterMonitors(config.monitors, dwMapID, dwKungfuID),
			}, { __index = config })
		end
		CACHE_CONFIG = aConfig
	end
	return CACHE_CONFIG
end

local function onFilterChange()
	CACHE_CONFIG = nil
end
X.RegisterEvent('LOADING_END', 'MY_TargetMonData', onFilterChange)
X.RegisterEvent('SKILL_MOUNT_KUNG_FU', 'MY_TargetMonData', onFilterChange)
X.RegisterEvent('SKILL_UNMOUNT_KUNG_FU', 'MY_TargetMonData', onFilterChange)
X.RegisterEvent('MY_TARGET_MON_MONITOR_CHANGE', 'MY_TargetMonData', onFilterChange)

local function onTargetMonReload()
	onFilterChange()
	D.OnTargetMonReload()
end
X.RegisterEvent('MY_TARGET_MON_CONFIG_INIT', 'MY_TargetMonData', onTargetMonReload)
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
		return TARGET.PLAYER, GetControlPlayerID()
	elseif eTarType == 'CLIENT_PLAYER' then
		return TARGET.PLAYER, UI_GetClientPlayerID()
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
					return TARGET[IsPlayer(dwID) and 'PLAYER' or 'NPC'], dwID
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
		if arg1 ~= UI_GetClientPlayerID() then
			return
		end
		OnSkill(arg2, arg3)
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		if arg1 ~= UI_GetClientPlayerID() then
			return
		end
		OnSkill(arg4, arg5)
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		if arg4 ~= SKILL_EFFECT_TYPE.SKILL or arg1 ~= UI_GetClientPlayerID() then
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
local function Base_ShowMon(mon, dwTarKungfuID)
	if next(mon.tarkungfus) and not mon.tarkungfus.all and not mon.tarkungfus[dwTarKungfuID] then
		return
	end
	return true
end
local function Base_MonToView(mon, info, item, KObject, nIcon, config, tMonExist, tMonLast)
	-- 格式化完善视图列表信息
	if config.showTime and item.bCd and item.nTimeLeft and item.nTimeLeft > 0 then
		if config.cdBar then
			item.szProcess = (
					item.nTimeLeft >= 60
						and X.FormatDuration(item.nTimeLeft - item.nTimeLeft % 60, 'ENGLISH_ABBR', { accuracyunit = 'minute' })
						or ''
				)
				.. (
					(config.decimalTime == -1 or item.nTimeLeft < config.decimalTime)
						and ('%.1fs'):format(item.nTimeLeft % 60)
						or ('%ds'):format(item.nTimeLeft % 60)
				)
			item.szTimeLeft = ''
		else
			local nTimeLeft, szTimeLeft = item.nTimeLeft, ''
			if nTimeLeft <= 3600 then
				if nTimeLeft > 60 then
					if config.decimalTime == -1 or nTimeLeft < config.decimalTime then
						szTimeLeft = '%d\'%.1f'
					else
						szTimeLeft = '%d\'%d'
					end
					szTimeLeft = szTimeLeft:format(math.floor(nTimeLeft / 60), nTimeLeft % 60)
				else
					if config.decimalTime == -1 or nTimeLeft < config.decimalTime then
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
	if not config.showName then
		item.szLongName = ''
		item.szShortName = ''
	end
	if not item.nIcon then
		item.nIcon = 13
	end
	if config.cdFlash and item.bCd then
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
	if item.szExtentAnimate == EXTENT_ANIMATE.NONE and item.bActive and mon.extentAnimate then
		item.szExtentAnimate = mon.extentAnimate
	end
	if not config.cdCircle then
		item.bCd = false
	end
	if info and info.bCool then
		if tMonLast and not tMonLast[mon.uuid] and config.playSound then
			local dwSoundID = X.RandomChild(mon.soundAppear)
			if dwSoundID then
				local szSoundPath = X.GetSoundPath(dwSoundID)
				if szSoundPath then
					X.PlaySound(SOUND.UI_SOUND, szSoundPath, '')
				end
			end
		end
		tMonExist[mon.uuid] = mon
	end
end
local function Buff_CaptureMon(mon)
	for _, buff in X.spairs(BUFF_INFO[mon.name]) do
		if not mon.iconid then
			D.ModifyMonitor(mon, 'iconid', buff.nIcon)
		end
		local tMonId = mon.ids[buff.dwID]
		if not tMonId then
			tMonId = D.CreateMonitorId(mon, buff.dwID)
		end
		if not tMonId.iconid then
			D.ModifyMonitorId(tMonId, 'iconid', buff.nIcon)
		end
		local tMonLevel = tMonId.levels[buff.nLevel]
		if not tMonLevel then
			tMonLevel = D.CreateMonitorLevel(tMonId, buff.nLevel)
		end
		if not tMonLevel.iconid then
			D.ModifyMonitorLevel(tMonLevel, 'iconid', buff.nIcon)
		end
	end
end
local function Buff_ShowMon(mon, dwTarKungfuID)
	return Base_ShowMon(mon, dwTarKungfuID)
end
local function Buff_MatchMon(tAllBuff, mon, config)
	local info, nIconID, dwClientID, dwControlID = nil, nil, UI_GetClientPlayerID(), GetControlPlayerID()
	-- ids={[13942]={enable=true,iconid=7237,ignoreLevel=false,levels={[2]={enable=true,iconid=7237}}}}
	for dwID, tMonId in pairs(mon.ids) do
		if tMonId.enable or mon.ignoreId then
			local tBuff = tAllBuff[dwID]
			if tBuff then
				for _, buff in pairs(tBuff) do
					if buff and buff.bCool then
						if (
							config.hideOthers == mon.rHideOthers
							or buff.dwSkillSrcID == dwClientID
							or buff.dwSkillSrcID == dwControlID
						) and (not D.IsShieldedBuff(dwID, buff.nLevel)) then
							local tMonLevel = tMonId.levels[buff.nLevel] or X.CONSTANT.EMPTY_TABLE
							if tMonLevel.enable or tMonId.ignoreLevel then
								info = buff
								if not mon.ignoreId then
									if not tMonId.ignoreLevel then
										nIconID = tMonLevel.iconid
									end
									if not nIconID then
										nIconID = tMonId.iconid
									end
								end
								if not nIconID then
									nIconID = mon.iconid or buff.nIcon or 13
								end
								break
							end
						end
					end
				end
			end
		end
		if info then
			break
		end
	end
	return info, nIconID or mon.iconid
end
local function Buff_MonToView(mon, buff, item, KObject, nIcon, config, tMonExist, tMonLast)
	if nIcon then
		item.nIcon = nIcon
	end
	if buff and buff.bCool then
		if not item.nIcon then
			item.nIcon = buff.nIcon
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
		if mon.longAlias then
			item.szLongName = mon.longAlias
		elseif mon.nameAlias then
			item.szLongName = mon.name
		else
			item.szLongName = buff.szName
		end
		if mon.shortAlias then
			item.szShortName = mon.shortAlias
		elseif mon.nameAlias then
			item.szShortName = mon.name
		else
			item.szShortName = buff.szName
		end
	else
		item.bActive = false
		item.bCd = true
		item.fCd = 0
		item.fCdBar = 0
		item.bCdBarFlash = false
		item.fProgress = 0
		item.nTimeLeft = -1
		item.bSparking = true
		item.dwID = next(mon.ids) or -1
		item.nLevel = item.dwID and mon.ids[item.dwID] and next(mon.ids[item.dwID].levels) or -1
		item.szStackNum = ''
		item.szLongName = mon.longAlias or mon.name
		item.szShortName = mon.shortAlias or mon.name
	end
	item.aLongAliasRGB = mon.rgbLongAlias
	item.aShortAliasRGB = mon.rgbShortAlias
	Base_MonToView(mon, buff, item, KObject, nIcon, config, tMonExist, tMonLast)
end
local function Skill_CaptureMon(mon)
	for _, skill in X.spairs(SKILL_INFO[mon.name]) do
		if not mon.iconid then
			D.ModifyMonitor(mon, 'iconid', skill.nIcon)
		end
		local tMonId = mon.ids[skill.dwID]
		if not tMonId then
			tMonId = D.CreateMonitorId(mon, skill.dwID)
		end
		if not tMonId.iconid then
			D.ModifyMonitorId(tMonId, 'iconid', skill.nIcon)
		end
		local tMonLevel = tMonId.levels[skill.nLevel]
		if not tMonLevel then
			tMonLevel = D.CreateMonitorLevel(tMonId, skill.nLevel)
		end
		if not tMonLevel.iconid then
			D.ModifyMonitorLevel(tMonLevel, 'iconid', skill.nIcon)
		end
	end
end
local function Skill_ShowMon(mon, dwTarKungfuID)
	return Base_ShowMon(mon, dwTarKungfuID)
end
local function Skill_MatchMon(tSkill, mon, config)
	local info, nIconID = nil, nil
	local infoCool, nIconIDCool = nil, nil
	for dwID, tMonId in pairs(mon.ids) do
		if tMonId.enable or mon.ignoreId then
			local skill = tSkill[dwID]
			if skill then
				-- if Base_MatchMon(mon) then
					local tMonLevel = tMonId.levels[skill.nLevel] or X.CONSTANT.EMPTY_TABLE
					if tMonLevel.enable or tMonId.ignoreLevel then
						if skill.bCool then
							info = skill
							if not mon.ignoreId then
								if not tMonId.ignoreLevel then
									nIconID = tMonLevel.iconid
								end
								if not nIconID then
									nIconID = tMonId.iconid
								end
							end
							if not nIconID then
								nIconID = mon.iconid or skill.nIcon or 13
							end
							break
						else
							infoCool = skill
							nIconIDCool = mon.iconid or skill.nIcon or 13
						end
					end
				-- end
			end
		end
		if info then
			break
		end
	end
	if not info then
		info, nIconID = infoCool, nIconIDCool
	end
	return info, nIconID or mon.iconid
end
local function Skill_MonToView(mon, skill, item, KObject, nIcon, config, tMonExist, tMonLast)
	if nIcon then
		item.nIcon = nIcon
	end
	if skill and skill.bCool then
		if not item.nIcon then
			item.nIcon = skill.nIcon
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
		item.szLongName = mon.longAlias or skill.szName
		item.szShortName = mon.shortAlias or skill.szName
	else
		item.bActive = true
		item.bCd = false
		item.fCd = 1
		item.fCdBar = 1
		item.bCdBarFlash = false
		item.fProgress = 0
		item.bSparking = true
		item.dwID = next(mon.ids) or -1
		item.nLevel = item.dwID and mon.ids[item.dwID] and next(mon.ids[item.dwID].levels) or -1
		item.szLongName = mon.longAlias or mon.name
		item.szShortName = mon.shortAlias or mon.name
	end
	local nStackNum = (skill and skill.nCdMaxCount > 1)
		and (skill.nCdMaxCount - skill.nCdCount)
		or 0
	item.szStackNum = nStackNum > 0 and nStackNum or ''
	item.aLongAliasRGB = mon.rgbLongAlias
	item.aShortAliasRGB = mon.rgbShortAlias
	Base_MonToView(mon, skill, item, KObject, nIcon, config, tMonExist, tMonLast)
end
local UpdateView
do local fUIScale, fFontScaleBase
function UpdateView()
	local me = GetClientPlayer()
	local nViewIndex, nViewCount = 1, #VIEW_LIST
	for _, config in ipairs(D.GetConfigList()) do
		if config.enable then
			local dwTarType, dwTarID = D.GetTarget(config.target, config.type)
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
			fUIScale = (config.ignoreSystemUIScale and 1 or Station.GetUIScale()) * config.scale
			fFontScaleBase = fUIScale * X.GetFontScale() * config.scale
			view.szUuid               = config.uuid
			view.szType               = config.type
			view.szTarget             = config.target
			view.szCaption            = D.GetConfigCaption(config)
			view.tAnchor              = config.anchor
			view.bIgnoreSystemUIScale = config.ignoreSystemUIScale
			view.fUIScale             = fUIScale
			view.fIconFontScale       = fFontScaleBase * config.iconFontScale
			view.fOtherFontScale      = fFontScaleBase * config.otherFontScale
			view.bPenetrable          = config.penetrable
			view.bDragable            = config.draggable
			view.szAlignment          = config.alignment
			view.nMaxLineCount        = config.maxLineCount
			view.bCdCircle            = config.cdCircle
			view.bCdFlash             = config.cdFlash
			view.bCdReadySpark        = config.cdReadySpark
			view.bCdBar               = config.cdBar
			view.nCdBarWidth          = config.cdBarWidth
			-- view.playSound         = config.playSound
			view.szCdBarUITex         = config.cdBarUITex
			view.szBoxBgUITex         = config.boxBgUITex
			local aItem = view.aItem
			if not aItem then
				aItem = {}
				view.aItem = aItem
			end
			local nItemIndex, nItemCount = 1, #aItem
			local tMonExist, tMonLast = {}, MON_EXIST_CACHE[config.uuid]
			if config.type == 'BUFF' then
				local tBuff = KObject and BUFF_CACHE[KObject.dwID] or X.CONSTANT.EMPTY_TABLE
				for _, mon in ipairs(config.monitors) do
					if Buff_ShowMon(mon, dwTarKungfuID) then
						-- 如果开启了捕获 从BUFF索引中捕获新的BUFF
						if mon.capture then
							Buff_CaptureMon(mon)
						end
						-- 通过监控项生成视图列表
						local buff, nIcon = Buff_MatchMon(tBuff, mon, config)
						if (buff and buff.bCool) or config.hideVoid == mon.rHideVoid then
							local item = aItem[nItemIndex]
							if not item then
								item = {}
								aItem[nItemIndex] = item
							end
							Buff_MonToView(mon, buff, item, KObject, nIcon, config, tMonExist, tMonLast)
							nItemIndex = nItemIndex + 1
						end
					end
				end
			elseif config.type == 'SKILL' then
				local tSkill = KObject and SKILL_CACHE[KObject.dwID] or X.CONSTANT.EMPTY_TABLE
				for _, mon in ipairs(config.monitors) do
					if Skill_ShowMon(mon, dwTarKungfuID) then
						-- 如果开启了捕获 从BUFF索引中捕获新的BUFF
						if mon.capture then
							Skill_CaptureMon(mon)
						end
						-- 通过监控项生成视图列表
						local skill, nIcon = Skill_MatchMon(tSkill, mon, config)
						if (skill and skill.bCool) or config.hideVoid == mon.rHideVoid then
							local item = aItem[nItemIndex]
							if not item then
								item = {}
								aItem[nItemIndex] = item
							end
							Skill_MonToView(mon, skill, item, KObject, nIcon, config, tMonExist, tMonLast)
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
					if not tMonExist[uuid] and config.playSound then
						local dwSoundID = X.RandomChild(mon.soundDisappear)
						if dwSoundID then
							local szSoundPath = X.GetSoundPath(dwSoundID)
							if szSoundPath then
								X.PlaySound(SOUND.UI_SOUND, szSoundPath, '')
							end
						end
					end
				end
			end
			MON_EXIST_CACHE[config.uuid] = tMonExist
			nViewIndex = nViewIndex + 1
		end
	end
	for i = nViewIndex, nViewCount do
		VIEW_LIST[i] = nil
	end
	D.FireDataUpdateEvent()
end
end

local function OnBreathe()
	-- 更新各目标BUFF数据
	local nLogicFrame, info = GetLogicFrameCount()
	for _, eType in ipairs(D.GetTargetTypeList('BUFF')) do
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
	for _, eType in ipairs(D.GetTargetTypeList('SKILL')) do
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
	OnBreathe()
	FireUIEvent('MY_TARGET_MON_DATA_INIT')
	X.BreatheCall('MY_TargetMonData', OnBreathe)
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
