--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控数值计算相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local Get, GetPatch, ApplyPatch, RandomChild = MY.Get, MY.GetPatch, MY.ApplyPatch, MY.RandomChild
---------------------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')
if not MY.AssertVersion('MY_TargetMon', _L['MY_TargetMon'], 0x2011800) then
	return
end
local C, D = {}, {
	GetConfig = MY_TargetMonConfig.GetConfig,
	GetNewMonId = MY_TargetMonConfig.GetNewMonId,
	GetNewMonLevel = MY_TargetMonConfig.GetNewMonLevel,
	MarkConfigChanged = MY_TargetMonConfig.MarkConfigChanged,
	GetTargetTypeList = MY_TargetMonConfig.GetTargetTypeList,
}
local BUFF_CACHE = {} -- 下标为目标ID的目标BUFF缓存数组 反正ID不可能是doodad不会冲突
local BUFF_INFO = {}
local BUFF_TIME = {}
local SKILL_INFO = {}
local VIEW_LIST = {}
local BOX_SPARKING_FRAME = GLOBAL.GAME_FPS * 2 / 3

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
		return MY.GetTarget()
	elseif eTarType == 'TTARGET' then
		local KTarget = MY.GetObject(MY.GetTarget())
		if KTarget then
			return MY.GetTarget(KTarget)
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

-- 更新技能反向索引
do
local function OnSkill(dwID, dwLevel)
	local szName = Table_GetSkillName(dwID, dwLevel)
	if not szName then
		return
	end
	SKILL_INFO[szName] = dwID
end
local function OnSysMsg(event)
	if arg0 == 'UI_OME_SKILL_CAST_LOG' then
		OnSkill(arg2, arg3)
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		OnSkill(arg4, arg5)
	end
end
MY.RegisterEvent('SYS_MSG.MY_TargetMon_SKILL', OnSysMsg)
end

-- 更新BUFF数据 更新监控条
do
local function BuffMonitorToView()
end

-- 更新监控条
local EXTENT_ANIMATE = {
	['[0.7,0.9)'] = {'ui\\Image\\Common\\Box.UITex', 17},
	['[0.9,1]'] = {'ui\\Image\\Common\\Box.UITex', 20},
	NONE = {},
}
local function UpdateView()
	local dwClientPlayerID = UI_GetClientPlayerID()
	local dwControlPlayerID = GetControlPlayerID()
	local nViewIndex, nViewCount = 1, #VIEW_LIST
	local bChange, nLogicFrame = false, GetLogicFrameCount()
	for _, config in ipairs(D.GetConfig()) do
		if config.enable then
			local KObject = MY.GetObject(D.GetTarget(config.target, config.type))
			local view = VIEW_LIST[nViewIndex]
			if not view then
				view = {}
				VIEW_LIST[nViewIndex] = view
			end
			view.szUuid               = config.uuid
			view.szType               = config.type
			view.szTarget             = config.target
			view.szCaption            = config.caption
			view.tAnchor              = config.anchor
			view.szAnchorBase         = config.hideVoid and 'TOPLEFT' or nil
			view.fUIScale             = config.ignoreSystemUIScale and (config.scale / Station.GetUIScale()) or config.scale
			view.fFontScale           = MY.GetFontScale() * config.scale
			view.bPenetrable          = config.penetrable
			view.bDragable            = config.dragable
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
			if config.type == 'BUFF' then
				local tBuff = KObject and BUFF_CACHE[KObject.dwID] or EMPTY_TABLE
				for _, mon in ipairs(config.monitors) do
					if mon.enable then
						-- 如果开启了捕获 从BUFF索引中捕获新的BUFF
						if mon.capture then
							for _, buff in spairs(BUFF_INFO[mon.name]) do
								if not mon.iconid then
									mon.iconid, bChange = buff.nIcon, true
								end
								local tMonId = mon.ids[buff.dwID]
								if not tMonId then
									tMonId = D.GetNewMonId(buff.dwID)
									mon.ids[buff.dwID], bChange = tMonId, true
								end
								if not tMonId.iconid then
									tMonId.iconid, bChange = buff.nIcon, true
								end
								local tMonLevel = tMonId.levels[buff.nLevel]
								if not tMonLevel then
									tMonLevel = D.GetNewMonLevel(buff.nLevel)
									tMonId.levels[buff.nLevel], bChange = tMonLevel, true
								end
								if not tMonLevel.iconid then
									tMonLevel.iconid, bChange = buff.nIcon, true
								end
							end
						end
						-- 通过监控项生成视图列表
						local buff, nIcon = nil, mon.iconid
						for dwID, tMonId in pairs(mon.ids) do
							buff = tBuff[dwID]
							if buff then
								if not config.hideOthers or buff.dwSkillSrcID == dwClientPlayerID or buff.dwSkillSrcID == dwControlPlayerID then
									if mon.iconid then
										nIcon = mon.iconid
										break
									end
									if tMonId.enable and mon.iconid then
										nIcon = tMonId.iconid or mon.iconid
										break
									end
									if tMonId.levels[buff.nLevel] and tMonId.levels[buff.nLevel].enable then
										nIcon = tMonId.levels[buff.nLevel].iconid
										break
									end
								end
								buff = nil
							end
						end
						if buff or config.hideVoid ~= mon.hideVoid then
							local item = aItem[nItemIndex]
							if not item then
								item = { nIcon = nIcon }
								aItem[nItemIndex] = item
							end
							if buff then
								if not item.nIcon then
									item.nIcon = buff.nIcon
								end
								local nTimeLeft = max((buff.nEndFrame - nLogicFrame) * 0.0625, 0)
								if not BUFF_TIME[KObject.dwID] then
									BUFF_TIME[KObject.dwID] = {}
								end
								if not BUFF_TIME[KObject.dwID][buff.szKey] or BUFF_TIME[KObject.dwID][buff.szKey] < nTimeLeft then
									BUFF_TIME[KObject.dwID][buff.szKey] = nTimeLeft
								end
								local nTimeTotal = BUFF_TIME[KObject.dwID][buff.szKey]
								item.bCd = true
								item.fCd = 1 - nTimeLeft / nTimeTotal
								item.bSparking = false
								item.dwID = buff.dwID
								item.nLevel = buff.nLevel
								item.nTimeLeft = nTimeLeft
								item.szStackNum = buff.nStackNum > 1 and buff.nStackNum or ''
								item.nTimeTotal = nTimeTotal
								item.szLongName = mon.longAlias or buff.szName
								item.szShortName = mon.shortAlias or buff.szName
							else
								item.bCd = false
								item.fCd = 1
								item.bSparking = true
								item.dwID = next(mon.ids) or -1
								item.nLevel = item.dwID and next(mon.ids[item.dwID].levels) or -1
								item.szStackNum = ''
								item.szLongName = mon.longAlias or mon.name
								item.szShortName = mon.shortAlias or mon.name
							end
							item.aLongAliasRGB = mon.rgbLongAlias
							item.aShortAliasRGB = mon.rgbShortAlias
							nItemIndex = nItemIndex + 1
						end
					end
				end
			end
			for i = nItemIndex, nItemCount do
				aItem[i] = nil
			end
			-- 格式化完善视图列表信息
			for _, item in ipairs(aItem) do
				if config.showTime and item.nTimeLeft then
					local nTimeLeft, szTimeLeft = item.nTimeLeft, ''
					if nTimeLeft <= 3600 then
						if nTimeLeft > 60 then
							if config.decimalTime == -1 or nTimeLeft < config.decimalTime then
								szTimeLeft = '%d\'%.1f'
							else
								szTimeLeft = '%d\'%d'
							end
							szTimeLeft = szTimeLeft:format(floor(nTimeLeft / 60), nTimeLeft % 60)
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
				else
					item.szTimeLeft = ''
				end
				if not config.showName then
					item.szLongName = ''
					item.szShortName = ''
				end
				if not item.nIcon then
					item.nIcon = 13
				end
				if config.cdFlash and item.bCd then
					if item.fCd >= 0.9 then
						item.aExtentAnimate = EXTENT_ANIMATE['[0.9,1]']
					elseif item.fCd >= 0.7 then
						item.aExtentAnimate = EXTENT_ANIMATE['[0.7,0.9)']
					else
						item.aExtentAnimate = EXTENT_ANIMATE.NONE
					end
					item.bStaring = item.fCd > 0.5
				else
					item.bStaring = false
					item.aExtentAnimate = EXTENT_ANIMATE.NONE
				end
				if not config.cdCircle then
					item.bCd = false
				end
			end
			nViewIndex = nViewIndex + 1
		end
	end
	for i = nViewIndex, nViewCount do
		VIEW_LIST[i] = nil
	end
	if bChange then
		D.MarkConfigChanged()
	end
end

local function OnBreathe()
	-- 更新各目标BUFF数据
	for _, eType in ipairs(D.GetTargetTypeList()) do
		local KObject = MY.GetObject(D.GetTarget(eType, 'BUFF'))
		if KObject then
			local tBuff = {}
			local aBuff = MY.GetBuffList(KObject)
			-- 当前身上的buff
			for _, buff in ipairs(aBuff) do
				tBuff[buff.szName] = buff
				tBuff[buff.dwID] = buff
				tBuff[buff.szKey] = buff
				if not BUFF_INFO[buff.szName] then
					BUFF_INFO[buff.szName] = {}
				end
				BUFF_INFO[buff.szName][buff.szKey] = buff
			end
			-- 处理消失的buff
			local tLastBuff = BUFF_CACHE[eType]
			if tLastBuff then
				local nLogicFrame = GetLogicFrameCount()
				for k, buff in pairs(tLastBuff) do
					if not tBuff[k] then
						if v.nEndFrame > nLogicFrame then
							v.nEndFrame = nLogicFrame
						end
						tBuff[k] = buff
					end
				end
			end
			BUFF_CACHE[KObject.dwID] = tBuff
		end
	end
	UpdateView()
end

local function onTargetMonReload()
	OnBreathe()
	FireUIEvent('MY_TARGET_MON_DATA_INIT')
	MY.BreatheCall('MY_TargetMonData', OnBreathe)
end
MY.RegisterEvent('MY_TARGET_MON_CONFIG_INIT.MY_TargetMonData', onTargetMonReload)
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
				if MY.IsShieldedVersion() and not MY.IsInDungeon() then
					if not IsDebugClient() then
						OutputMessage('MSG_ANNOUNCE_YELLOW', _L['Cancel buff is disabled outside dungeon.'])
					end
					return
				end
				local config = D.GetConfig(i)
				local view = VIEW_LIST[i]
				if not config or not view or config.type ~= 'BUFF' then
					return
				end
				local item = view.aItem[j]
				if not item then
					return
				end
				local KObject = MY.GetObject(D.GetTarget(config.target, config.type))
				if not KTarget then
					return
				end
				MY.CancelBuff(KTarget, item.dwID, item.nLevel)
			end, nil)
	end
end
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				GetTarget = D.GetTarget,
				GetViewData = D.GetViewData,
			},
		},
	},
}
MY_TargetMonData = MY.GeneGlobalNS(settings)
end
