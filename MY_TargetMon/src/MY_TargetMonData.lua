--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控数值计算相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMonData'

local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}
local BUFF_CACHE = {} -- 下标为目标ID的目标BUFF缓存数组 反正ID不可能是doodad不会冲突
local BUFF_INFO = {} -- BUFF反向索引
local BUFF_TIME = {} -- BUFF最长持续时间
local SKILL_EXTRA = {} -- 缓存自己放过的技能用于扫描
local SKILL_CACHE = {} -- 下标为目标ID的目标技能缓存数组 反正ID不可能是doodad不会冲突
local SKILL_INFO = {} -- 技能反向索引
local SHIELDED
local CONFIG_CACHE
local NEARBY_TARGET_FORCE_CACHE = {} -- 附近目标门派缓存
local NEARBY_FORCE_STAT_CACHE = {} -- 附件目标门派统计缓存
local VIEW_LIST_CACHE = {}
local DEFAULT_CONTENT_COLOR = {255, 255, 0}
local MY_TARGET_MON_MAP_TYPE = MY_TargetMonConfig.MY_TARGET_MON_MAP_TYPE
local MY_TARGET_MON_DATA_MAX_LIMIT = 2000

do
local function FilterDatasets(aDataset, dwMapID, dwKungfuID)
	local ret = {}
	for i, dataset in ipairs(aDataset) do
		if dataset.bEnable
		and (X.IsEmpty(dataset.tMap) or (
			dataset.tMap.bAll or dataset.tMap[dwMapID]
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.CITY           ] and X.IsCityMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.DUNGEON        ] and X.IsDungeonMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.TEAM_DUNGEON   ] and X.IsDungeonMap(dwMapID, false))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.RAID_DUNGEON   ] and X.IsDungeonMap(dwMapID, true))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.STARVE         ] and X.IsStarveMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.VILLAGE        ] and X.IsVillageMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.ARENA          ] and X.IsArenaMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.BATTLEFIELD    ] and X.IsBattlefieldMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.PUBG           ] and X.IsPubgMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.ZOMBIE         ] and X.IsZombieMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.MONSTER        ] and X.IsMonsterMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.MOBA           ] and X.IsMobaMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.HOMELAND       ] and X.IsHomelandMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.GUILD_TERRITORY] and X.IsGuildTerritoryMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.ROGUELIKE      ] and X.IsRoguelikeMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.COMPETITION    ] and X.IsCompetitionMap(dwMapID))
			or (dataset.tMap[MY_TARGET_MON_MAP_TYPE.CAMP           ] and X.IsCampMap(dwMapID))
		)) then
			table.insert(ret, dataset)
		end
	end
	return ret
end
local function HasNearbyKungfu(tKungfu)
	if tKungfu.bAll or tKungfu.bNpc then
		return true
	end
	for dwKungfuID, bEnable in pairs(tKungfu) do
		if bEnable then
			local dwForceID = X.CONSTANT.KUNGFU_FORCE_TYPE[dwKungfuID]
			if dwForceID and NEARBY_FORCE_STAT_CACHE[dwForceID] then
				return true
			end
		end
	end
end
local function FilterMonitors(aMonitor, dwMapID, dwKungfuID)
	local ret = {}
	for i, mon in ipairs(aMonitor) do
		if mon.bEnable
		and (X.IsEmpty(mon.tMap) or (
			mon.tMap.bAll or mon.tMap[dwMapID]
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.CITY           ] and X.IsCityMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.DUNGEON        ] and X.IsDungeonMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.TEAM_DUNGEON   ] and X.IsDungeonMap(dwMapID, false))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.RAID_DUNGEON   ] and X.IsDungeonMap(dwMapID, true))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.STARVE         ] and X.IsStarveMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.VILLAGE        ] and X.IsVillageMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.ARENA          ] and X.IsArenaMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.BATTLEFIELD    ] and X.IsBattlefieldMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.PUBG           ] and X.IsPubgMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.ZOMBIE         ] and X.IsZombieMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.MONSTER        ] and X.IsMonsterMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.MOBA           ] and X.IsMobaMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.HOMELAND       ] and X.IsHomelandMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.GUILD_TERRITORY] and X.IsGuildTerritoryMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.ROGUELIKE      ] and X.IsRoguelikeMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.COMPETITION    ] and X.IsCompetitionMap(dwMapID))
			or (mon.tMap[MY_TARGET_MON_MAP_TYPE.CAMP           ] and X.IsCampMap(dwMapID))
		))
		and (X.IsEmpty(mon.tKungfu) or mon.tKungfu.bAll or mon.tKungfu[dwKungfuID]
			or ( -- 藏剑不区分心法
				(dwKungfuID == X.CONSTANT.KUNGFU_TYPE.WEN_SHUI or dwKungfuID == X.CONSTANT.KUNGFU_TYPE.SHAN_JU)
				and (mon.tKungfu[X.CONSTANT.KUNGFU_TYPE.WEN_SHUI] or mon.tKungfu[X.CONSTANT.KUNGFU_TYPE.SHAN_JU])
			)
		)
		and (X.IsEmpty(mon.tTargetKungfu) or mon.tTargetKungfu.bAll or HasNearbyKungfu(mon.tTargetKungfu)) then
			table.insert(ret, mon)
		end
	end
	return ret
end
function D.GetDatasetList()
	if not CONFIG_CACHE then
		local me = X.GetClientPlayer()
		if not me then
			return {}
		end
		local aConfig = {}
		if not (X.IsInCompetitionMap() and X.IsClientPlayerMountMobileKungfu()) then
			local dwMapID = me.GetMapID() or 0
			local dwKungfuID = me.GetKungfuMountID() or 0
			for i, dataset in ipairs(FilterDatasets(MY_TargetMonConfig.GetDatasetList(), dwMapID, dwKungfuID)) do
				aConfig[i] = setmetatable(
					{
						aMonitor = FilterMonitors(dataset.aMonitor, dwMapID, dwKungfuID),
					},
					{ __index = dataset }
				)
			end
		end
		CONFIG_CACHE = aConfig
	end
	return CONFIG_CACHE
end
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
		local me = X.GetClientPlayer()
		return X.GetCharacterTarget(me)
	elseif eTarType == 'TTARGET' then
		local me = X.GetClientPlayer()
		local KTarget = X.GetTargetHandle(X.GetCharacterTarget(me))
		if KTarget then
			return X.GetCharacterTarget(KTarget)
		end
	elseif TEAM_MARK[eTarType] then
		local mark = X.GetTeamMark()
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

function D.IsShielded()
	if SHIELDED == nil then
		SHIELDED = X.IsRestricted('MY_TargetMon.MapRestriction') and X.IsInArenaMap()
	end
	return SHIELDED
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

function D.AnnounceShielded()
	local bBlock = X.IsInCompetitionMap() and X.IsClientPlayerMountMobileKungfu()
	if bBlock and not D.bBlockMessageAnnounced then
		X.OutputSystemMessage(_L['MY_TargetMon is blocked in current kungfu, temporary disabled.'])
	end
	D.bBlockMessageAnnounced = bBlock
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
X.RegisterEvent('SYS_MSG', 'MY_TargetMonData__SKILL', OnSysMsg)
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
local function Base_MonVisible(mon, dwTarKungfuID)
	if X.IsEmpty(mon.tTargetKungfu) or mon.tTargetKungfu.bAll
	or mon.tTargetKungfu[dwTarKungfuID]
	or ( -- 藏剑不区分心法
		(dwTarKungfuID == X.CONSTANT.KUNGFU_TYPE.WEN_SHUI or dwTarKungfuID == X.CONSTANT.KUNGFU_TYPE.SHAN_JU)
		and (mon.tTargetKungfu[X.CONSTANT.KUNGFU_TYPE.WEN_SHUI] or mon.tTargetKungfu[X.CONSTANT.KUNGFU_TYPE.SHAN_JU])
	) then
		return true
	end
	return false
end
-- 通用：监控项转视图数据
local function Base_MonToView(mon, info, item, KObject, dataset, tMonExist, tMonLast)
	-- 格式化完善视图列表信息
	if dataset.bShowTime and item.bCd and item.nTimeLeft and item.nTimeLeft > 0 then
		if dataset.bCdBar then
			item.szProcess = (
					item.nTimeLeft >= 60
						and X.FormatDuration(item.nTimeLeft - item.nTimeLeft % 60, 'ENGLISH_ABBR', { accuracyUnit = 'minute' })
						or ''
				)
				.. (
					(dataset.nDecimalTime == -1 or item.nTimeLeft < dataset.nDecimalTime)
						and ('%.1fs'):format(item.nTimeLeft % 60)
						or ('%ds'):format(item.nTimeLeft % 60)
				)
			item.szTimeLeft = ''
		else
			local nTimeLeft, szTimeLeft = item.nTimeLeft, ''
			if nTimeLeft <= 3600 then
				if nTimeLeft > 60 then
					if dataset.nDecimalTime == -1 or nTimeLeft < dataset.nDecimalTime then
						szTimeLeft = '%d\'%.1f'
					else
						szTimeLeft = '%d\'%d'
					end
					szTimeLeft = szTimeLeft:format(math.floor(nTimeLeft / 60), nTimeLeft % 60)
				else
					if dataset.nDecimalTime == -1 or nTimeLeft < dataset.nDecimalTime then
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
	if not dataset.bShowName then
		item.szContent = ''
	end
	if not item.nIconID then
		item.nIconID = MY_TargetMonConfig.DEFAULT_MONITOR_ICON_ID
	end
	if dataset.bCdFlash and item.bCd then
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
	if not dataset.bCdCircle then
		item.bCd = false
	end
	if info and info.bCool then
		if tMonLast and not tMonLast[mon.szUUID] and dataset.bPlaySound and mon.aSoundAppear then
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
local function Buff_MonVisible(mon, dwTarKungfuID)
	return Base_MonVisible(mon, dwTarKungfuID)
end
-- BUFF：监控项匹配 BUFF 对象
local function Buff_MonMatch(tAllBuff, mon, dataset)
	local dwClientID, dwControlID = X.GetClientPlayerID(), X.GetControlPlayerID()
	local tBuff = tAllBuff[mon.dwID]
	if tBuff then
		for _, buff in pairs(tBuff) do
			if buff and buff.bCool then
				if (
					not dataset.bHideOthers == not mon.bFlipHideOthers
					or buff.dwSkillSrcID == dwClientID
					or buff.dwSkillSrcID == dwControlID
				)
				and (not D.IsShieldedBuff(buff.dwID, buff.nLevel))
				and (mon.nLevel == 0 or mon.nLevel == buff.nLevel)
				and (not mon.nStackNum or mon.nStackNum == 0 or X.JudgeOperator(mon.nStackNumOp or '=', buff.nStackNum, mon.nStackNum)) then
					return buff
				end
			end
		end
	end
end
-- BUFF：监控项转视图数据
local function Buff_MonToView(mon, buff, item, KObject, dataset, tMonExist, tMonLast)
	if buff and buff.bCool then
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
		item.nIconID = mon.nIconID or buff.nIcon
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
		item.nIconID = mon.nIconID or X.GetBuffIconID(item.dwID, item.nLevel == 0 and 1 or item.nLevel)
		item.szStackNum = ''
		item.szContent = X.IsEmpty(mon.szContent) and X.GetBuffName(mon.dwID, mon.nLevel) or mon.szContent
	end
	item.aContentColor = mon.aContentColor or DEFAULT_CONTENT_COLOR
	Base_MonToView(mon, buff, item, KObject, dataset, tMonExist, tMonLast)
end
-- 技能：判断监控项是否显示
local function Skill_MonVisible(mon, dwTarKungfuID)
	return Base_MonVisible(mon, dwTarKungfuID)
end
-- 技能：监控项匹配 BUFF 对象
local function Skill_MonMatch(tSkill, mon, dataset)
	local skill = tSkill[mon.dwID]
	if skill and (mon.nLevel == 0 or mon.nLevel == skill.nLevel) then
		return skill
	end
end
-- 技能：监控项转视图数据
local function Skill_MonToView(mon, skill, item, KObject, dataset, tMonExist, tMonLast)
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
		item.nIconID = mon.nIconID or skill.nIcon
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
		item.nIconID = mon.nIconID or X.GetSkillIconID(item.dwID, item.nLevel)
		item.szContent = X.IsEmpty(mon.szContent) and X.GetSkillName(mon.dwID, mon.nLevel) or mon.szContent
	end
	local nStackNum = (skill and skill.nCdMaxCount > 1)
		and (skill.nCdMaxCount - skill.nCdCount)
		or 0
	item.szStackNum = nStackNum > 0 and nStackNum or ''
	item.aContentColor = mon.aContentColor or DEFAULT_CONTENT_COLOR
	Base_MonToView(mon, skill, item, KObject, dataset, tMonExist, tMonLast)
end
local UpdateView
do
local fUIScale, fFontScaleBase
function UpdateView()
	local nViewIndex, nViewCount, nMonitorCount = 1, #VIEW_LIST_CACHE, 0
	for _, dataset in ipairs(X.IsRestricted('MY_TargetMon') and X.CONSTANT.EMPTY_TABLE or D.GetDatasetList()) do
		local dwTarType, dwTarID = D.GetTarget(dataset.szTarget, dataset.szType)
		local KObject = X.GetTargetHandle(dwTarType, dwTarID)
		local dwTarKungfuID = KObject
			and (dwTarType == TARGET.PLAYER
				and (KObject.GetKungfuMountID() or 0)
				or 'bNpc'
			)
			or 0
		local view = VIEW_LIST_CACHE[nViewIndex]
		if not view then
			view = {}
			VIEW_LIST_CACHE[nViewIndex] = view
		end
		fUIScale = (dataset.bIgnoreSystemUIScale and 1 or Station.GetUIScale()) * dataset.fScale
		fFontScaleBase = fUIScale * X.GetFontScale() * dataset.fScale
		view.szUUID               = dataset.szUUID
		view.szType               = dataset.szType
		view.szTarget             = dataset.szTarget
		view.szCaption            = MY_TargetMonConfig.GetDatasetTitle(dataset)
		view.tAnchor              = dataset.tAnchor
		view.bIgnoreSystemUIScale = dataset.bIgnoreSystemUIScale
		view.fUIScale             = fUIScale
		view.fIconFontScale       = fFontScaleBase * dataset.fIconFontScale
		view.fOtherFontScale      = fFontScaleBase * dataset.fOtherFontScale
		view.bPenetrable          = dataset.bPenetrable
		view.bDraggable           = dataset.bDraggable
		view.szAlignment          = dataset.szAlignment
		view.nMaxLineCount        = dataset.nMaxLineCount
		view.bCdCircle            = dataset.bCdCircle
		view.bCdFlash             = dataset.bCdFlash
		view.bCdReadySpark        = dataset.bCdReadySpark
		view.bCdBar               = dataset.bCdBar
		view.nCdBarWidth          = dataset.nCdBarWidth
		-- view.playSound         = dataset.bPlaySound
		view.szCdBarUITex         = dataset.szCdBarUITex
		view.szBoxBgUITex         = dataset.szBoxBgUITex
		view.aMonitor             = dataset.aMonitor
		local tMonGroupFallbackUUID = view.tMonGroupFallbackUUID
		if not tMonGroupFallbackUUID then
			tMonGroupFallbackUUID = {}
			for _, mon in ipairs(dataset.aMonitor) do
				if mon.szGroup then
					tMonGroupFallbackUUID[mon.szGroup] = mon.szUUID
				end
			end
			view.tMonGroupFallbackUUID = tMonGroupFallbackUUID
		end
		local tMonGroupActiveUUID = view.tMonGroupActiveUUID
		if not tMonGroupActiveUUID then
			tMonGroupActiveUUID = {}
			view.tMonGroupActiveUUID = tMonGroupActiveUUID
		end
		local aItem = view.aItem
		if not aItem then
			aItem = {}
			view.aItem = aItem
		end
		local nItemIndex, nItemCount = 1, #aItem
		local tMonExist, tMonLast = {}, MON_EXIST_CACHE[dataset.szUUID]
		if dataset.szType == 'BUFF' then
			local tBuff = KObject and BUFF_CACHE[KObject.dwID] or X.CONSTANT.EMPTY_TABLE
			for _, mon in ipairs(dataset.aMonitor) do
				if nMonitorCount > MY_TARGET_MON_DATA_MAX_LIMIT then
					break
				end
				nMonitorCount = nMonitorCount + 1
				if Buff_MonVisible(mon, dwTarKungfuID) then
					-- 通过监控项生成视图列表
					local buff = Buff_MonMatch(tBuff, mon, dataset)
					if mon.szGroup and (
						tMonGroupActiveUUID[mon.szGroup] == mon.szUUID
						or tMonGroupActiveUUID[mon.szGroup] == tMonGroupFallbackUUID[mon.szGroup]
					) then
						tMonGroupActiveUUID[mon.szGroup] = nil
					end
					if (
						not mon.szGroup -- 无同组项设置
						or (
							not tMonGroupActiveUUID[mon.szGroup] -- 不存在激活的同组项
							and (
								(buff and buff.bCool) -- 并且当前 BUFF 激活
								or tMonGroupFallbackUUID[mon.szGroup] == mon.szUUID -- 或者当前是同组项最后一个显示项
							)
						)
					)
					and ((buff and buff.bCool) or not dataset.bHideVoid == not mon.bFlipHideVoid) then
						local item = aItem[nItemIndex]
						if not item then
							item = {}
							aItem[nItemIndex] = item
						end
						Buff_MonToView(mon, buff, item, KObject, dataset, tMonExist, tMonLast)
						if mon.szGroup then
							tMonGroupActiveUUID[mon.szGroup] = mon.szUUID
						end
						nItemIndex = nItemIndex + 1
					end
				end
			end
		elseif dataset.szType == 'SKILL' then
			local tSkill = KObject and SKILL_CACHE[KObject.dwID] or X.CONSTANT.EMPTY_TABLE
			for _, mon in ipairs(dataset.aMonitor) do
				if nMonitorCount > MY_TARGET_MON_DATA_MAX_LIMIT then
					break
				end
				nMonitorCount = nMonitorCount + 1
				if Skill_MonVisible(mon, dwTarKungfuID) then
					-- 通过监控项生成视图列表
					local skill = Skill_MonMatch(tSkill, mon, dataset)
					if mon.szGroup and (
						tMonGroupActiveUUID[mon.szGroup] == mon.szUUID
						or tMonGroupActiveUUID[mon.szGroup] == tMonGroupFallbackUUID[mon.szGroup]
					) then
						tMonGroupActiveUUID[mon.szGroup] = nil
					end
					if (
						not mon.szGroup -- 无同组项设置
						or (
							not tMonGroupActiveUUID[mon.szGroup] -- 不存在激活的同组项
							and (
								(skill and skill.bCool) -- 并且当前 技能CD 激活
								or tMonGroupFallbackUUID[mon.szGroup] == mon.szUUID -- 或者当前是同组项最后一个显示项
							)
						)
					)
					and (skill and skill.bCool) or not dataset.bHideVoid == not mon.bFlipHideVoid then
						local item = aItem[nItemIndex]
						if not item then
							item = {}
							aItem[nItemIndex] = item
						end
						if mon.szGroup then
							tMonGroupActiveUUID[mon.szGroup] = mon.szUUID
						end
						Skill_MonToView(mon, skill, item, KObject, dataset, tMonExist, tMonLast)
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
				if not tMonExist[uuid] and dataset.bPlaySound and mon.aSoundDisappear then
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
		MON_EXIST_CACHE[dataset.szUUID] = tMonExist
		nViewIndex = nViewIndex + 1
	end
	for i = nViewIndex, nViewCount do
		VIEW_LIST_CACHE[i] = nil
	end
	D.FireDataUpdateEvent()
end
end

local function OnFrameCall()
	local tExistBuffMonitorTargetType = {}
	local tExistSkillMonitorTargetType = {}
	for _, dataset in ipairs(D.GetDatasetList()) do
		if dataset.szType == 'BUFF' then
			tExistBuffMonitorTargetType[dataset.szTarget] = true
		elseif dataset.szType == 'SKILL' then
			tExistSkillMonitorTargetType[dataset.szTarget] = true
		end
	end
	-- 更新各目标BUFF数据
	local nLogicFrame, info = GetLogicFrameCount()
	for eType, _ in pairs(tExistBuffMonitorTargetType) do
		local KObject = X.GetTargetHandle(D.GetTarget(eType, 'BUFF'))
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
		local KObject = X.GetTargetHandle(D.GetTarget(eType, 'SKILL'))
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
	FireUIEvent('MY_TARGET_MON_DATA__INIT')
	X.FrameCall('MY_TargetMonData', MY_TargetMonConfig.nInterval, OnFrameCall)
end
end

function D.GetViewData(nIndex)
	if nIndex then
		return VIEW_LIST_CACHE[nIndex]
	end
	return VIEW_LIST_CACHE
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
				if X.IsRestricted('MY_TargetMon.MapRestriction') and (X.IsInArenaMap() or X.IsInBattlefieldMap()) then
					OutputMessage('MSG_ANNOUNCE_RED', _L['Cancel buff is disabled in arena and battlefield.'])
					return
				end
				local tViewData = D.GetViewData(i)
				if not tViewData or tViewData.szType ~= 'BUFF' then
					OutputMessage('MSG_ANNOUNCE_RED', _L['Hotkey cancel is only allowed for buff.'])
					return
				end
				local KTarget = X.GetTargetHandle(D.GetTarget(tViewData.szTarget, tViewData.szType))
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

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMonData',
	exports = {
		{
			fields = {
				MY_TARGET_MON_DATA_MAX_LIMIT = MY_TARGET_MON_DATA_MAX_LIMIT,
				GetTarget = D.GetTarget,
				GetViewData = D.GetViewData,
				RegisterDataUpdateEvent = D.RegisterDataUpdateEvent,
			},
		},
	},
}
MY_TargetMonData = X.CreateModule(settings)
end

----------------------------------------------------------------------------------------------
-- 事件注册
----------------------------------------------------------------------------------------------

local function onShieldedReset()
	SHIELDED = nil
end
X.RegisterEvent('MY_RESTRICTION', 'MY_TargetMonData__Shield', function()
	if arg0 and arg0 ~= 'MY_TargetMon.MapRestriction' then
		return
	end
	onShieldedReset()
end)
X.RegisterEvent('LOADING_END', 'MY_TargetMonData__Shield', onShieldedReset)

X.RegisterEvent('LOADING_END', 'MY_TargetMonData__AnnounceShielded', D.AnnounceShielded)
X.RegisterKungfuMount('MY_TargetMonData__AnnounceShielded', D.AnnounceShielded)

local function onTargetMonReload()
	VIEW_LIST_CACHE = {}
	CONFIG_CACHE = nil
	D.OnTargetMonReload()
end
X.RegisterEvent('LOADING_ENDING', 'MY_TargetMonData', onTargetMonReload)
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_RELOAD', 'MY_TargetMonData', onTargetMonReload)
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY', 'MY_TargetMonData', onTargetMonReload)
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', 'MY_TargetMonData', onTargetMonReload)
X.RegisterEvent('MY_RESTRICTION', function()
	if arg0 and arg0 ~= 'MY_TargetMon' then
		return
	end
	onTargetMonReload()
end)

X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_TargetMonData', function()
	local dwID = arg0
	X.DelayCall(function()
		local player = GetPlayer(dwID)
		if not player then
			return
		end
		NEARBY_TARGET_FORCE_CACHE[dwID] = player.dwForceID
		if NEARBY_FORCE_STAT_CACHE[player.dwForceID] then
			NEARBY_FORCE_STAT_CACHE[player.dwForceID] = NEARBY_FORCE_STAT_CACHE[player.dwForceID] + 1
		else
			NEARBY_FORCE_STAT_CACHE[player.dwForceID] = 1
			VIEW_LIST_CACHE = {}
			CONFIG_CACHE = nil
		end
	end)
end)

X.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_TargetMonData', function()
	local dwForceID = NEARBY_TARGET_FORCE_CACHE[arg0]
	if not dwForceID then
		return
	end
	NEARBY_FORCE_STAT_CACHE[dwForceID] = NEARBY_FORCE_STAT_CACHE[dwForceID] - 1
	NEARBY_TARGET_FORCE_CACHE[arg0] = nil
	if NEARBY_FORCE_STAT_CACHE[dwForceID] == 0 then
		NEARBY_FORCE_STAT_CACHE[dwForceID] = nil
		VIEW_LIST_CACHE = {}
		CONFIG_CACHE = nil
	end
end)

local function onTargetMonIntervalChange()
	X.FrameCall('MY_TargetMonData', MY_TargetMonConfig.nInterval)
end
X.RegisterEvent('MY_TARGET_MON_CONFIG__INTERVAL_CHANGE', onTargetMonIntervalChange)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
