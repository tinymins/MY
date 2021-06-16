--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 焦点列表
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Focus'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Focus'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local CHANGGE_REAL_SHADOW_TPLID = 46140 -- 清绝歌影 的主体影子
local FOCUS_LIST = {}
local TEAMMON_FOCUS = {}
local l_tTempFocusList = {
	[TARGET.PLAYER] = {},   -- dwID
	[TARGET.NPC]    = {},   -- dwTemplateID
	[TARGET.DOODAD] = {},   -- dwTemplateID
}
local O = LIB.CreateUserSettingsModule('MY_Focus', _L['MY_Focus'], {
	bEnable = { -- 是否启用
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bMinimize = { -- 是否最小化
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoHide = { -- 无焦点时隐藏
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	nMaxDisplay = { -- 最大显示数量
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Number,
		xDefaultValue = 5,
	},
	fScaleX = { -- 缩放比例
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	fScaleY = { -- 缩放比例
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	anchor = { -- 默认坐标
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['Basic settings'],
		xSchema = Schema.FrameAnchor,
		xDefaultValue = { x=-300, y=220, s='TOPRIGHT', r='TOPRIGHT' },
	},

	bFocusINpc = { -- 焦点重要NPC
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bFocusFriend = { -- 焦点附近好友
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusTong = { -- 焦点帮会成员
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bOnlyPublicMap = { -- 仅在公共地图焦点好友帮会成员
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bSortByDistance = { -- 优先焦点近距离目标
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusEnemy = { -- 焦点敌对玩家
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusAnmerkungen = { -- 焦点记在小本本里的玩家
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoFocus = { -- 启用默认焦点
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bTeamMonFocus = { -- 启用团队监控焦点
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bHideDeath = { -- 隐藏死亡目标
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bDisplayKungfuIcon = { -- 显示心法图标
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusJJCParty = { -- 焦竞技场队友
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusJJCEnemy = { -- 焦竞技场敌队
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowTarget = { -- 显示目标目标
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	szDistanceType = { -- 坐标距离计算方式
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.String,
		xDefaultValue = 'global',
	},
	bHealHelper = { -- 辅助治疗模式
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowTipRB = { -- 在屏幕右下角显示信息
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableSceneNavi = { -- 场景追踪点
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Basic settings'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	aPatternFocus = { -- 默认焦点
		ePathType = PATH_TYPE.GLOBAL,
		szLabel = _L['Auto focus'],
		xSchema = Schema.Collection(Schema.Record({
			szMethod = Schema.String,
			szPattern = Schema.String,
			szDisplay = Schema.String,
			dwMapID = Schema.Number,
			tType = Schema.MixedTable({
				bAll = Schema.Optional(Schema.Boolean),
				[TARGET.NPC] = Schema.Optional(Schema.Boolean),
				[TARGET.PLAYER] = Schema.Optional(Schema.Boolean),
				[TARGET.DOODAD] = Schema.Optional(Schema.Boolean),
			}),
			tRelation = Schema.Record({
				bAll = Schema.Optional(Schema.Boolean),
				bEnemy = Schema.Optional(Schema.Boolean),
				bAlly = Schema.Optional(Schema.Boolean),
			}),
			tLife = Schema.Record({
				bEnable = Schema.Boolean,
				szOperator = Schema.String,
				nValue = Schema.Number,
			}),
			nMaxDistance = Schema.Number,
		})),
		xDefaultValue = {},
	},

	tStaticFocus = { -- 永久焦点
		ePathType = PATH_TYPE.SERVER,
		szLabel = _L['Static focus'],
		xSchema = Schema.MixedTable({
			[TARGET.PLAYER] = Schema.Map(Schema.Number, Schema.Boolean), -- dwID
			[TARGET.NPC]    = Schema.Map(Schema.Number, Schema.Boolean), -- dwTemplateID
			[TARGET.DOODAD] = Schema.Map(Schema.Number, Schema.Boolean), -- dwTemplateID
		}),
		xDefaultValue = {
			[TARGET.PLAYER] = {}, -- dwID
			[TARGET.NPC]    = {}, -- dwTemplateID
			[TARGET.DOODAD] = {}, -- dwTemplateID
		},
	},
})
local D = {}

function D.IsShielded() return LIB.IsShieldedVersion('MY_Focus') and LIB.IsInShieldedMap() end
function D.IsEnabled() return O.bEnable and not D.IsShielded() end

do
local ds = {
	szMethod = 'NAME',
	szPattern = '',
	szDisplay = '',
	dwMapID = -1,
	tType = {
		bAll = true,
		[TARGET.NPC] = false,
		[TARGET.PLAYER] = false,
		[TARGET.DOODAD] = false,
	},
	tRelation = {
		bAll = true,
		bEnemy = false,
		bAlly = false,
	},
	tLife = {
		bEnable = false,
		szOperator = '>',
		nValue = 0,
	},
	nMaxDistance = 0,
}
function D.FormatAutoFocusData(data)
	return LIB.FormatDataStructure(data, ds)
end
local dsl = {
	'__META__',
	__VALUE__ = {},
	__CHILD_TEMPLATE__ = ds,
}
function D.FormatAutoFocusDataList(datalist)
	return LIB.FormatDataStructure(datalist, dsl)
end
end

function D.CheckFrameOpen(bForceReload)
	if D.IsEnabled() then
		if bForceReload then
			MY_FocusUI.Close()
		end
		MY_FocusUI.Open()
	else
		MY_FocusUI.Close()
	end
end

function D.LoadConfig()
	local szRolePath = LIB.FormatPath({'config/focus.jx3dat', PATH_TYPE.ROLE})
	local szGlobalPath = LIB.FormatPath({'config/focus/', PATH_TYPE.GLOBAL})
	local szServerPath = LIB.FormatPath({'config/focus/', PATH_TYPE.SERVER})
	local aPath = {}
	for _, szPath in ipairs(CPath.GetFileList(szGlobalPath)) do
		insert(aPath, szGlobalPath .. szPath)
	end
	for _, szPath in ipairs(CPath.GetFileList(szServerPath)) do
		insert(aPath, szServerPath .. szPath)
	end
	insert(aPath, szRolePath)
	for _, szPath in ipairs(aPath) do
		local config = LIB.LoadLUAData(szPath)
		CPath.DelFile(szPath)
		if config then
			for k, v in pairs(config) do
				-- 永久焦点与默认焦点数据需要合并处理
				if k == 'tStaticFocus' then
					for _, eType in ipairs({ TARGET.PLAYER, TARGET.NPC, TARGET.DOODAD }) do
						if not IsTable(v[eType]) then
							v[eType] = {}
						end
						for kk, vv in pairs(O.tStaticFocus[eType]) do
							pcall(Set, v, kk, vv)
						end
					end
				elseif k == 'aPatternFocus' then
					for _, vv in ipairs(O.aPatternFocus) do
						pcall(insert, v, vv)
					end
				end
				pcall(Set, O, k, v)
			end
		end
	end
	-- 扫描附近玩家
	D.RescanNearby()
end

function D.OnConfigChange(k, v)
	if k == 'bEnable' then
		D.CheckFrameOpen()
	elseif k == 'fScaleX' or k == 'fScaleY' then
		FireUIEvent('MY_FOCUS_SCALE_UPDATE')
	elseif k == 'nMaxDisplay' then
		FireUIEvent('MY_FOCUS_MAX_DISPLAY_UPDATE')
	elseif k == 'bAutoHide' then
		FireUIEvent('MY_FOCUS_AUTO_HIDE_UPDATE')
	end
end

function D.GetAllFocusPattern()
	return Clone(O.aPatternFocus)
end

-- 添加、修改默认焦点
function D.SetFocusPattern(szPattern, tData)
	local nIndex
	szPattern = LIB.TrimString(szPattern)
	for i, v in ipairs_r(O.aPatternFocus) do
		if v.szPattern == szPattern then
			nIndex = i
			remove(O.aPatternFocus, i)
			O.aPatternFocus = O.aPatternFocus
		end
	end
	-- 格式化数据
	if not IsTable(tData) then
		tData = { szPattern = szPattern }
	end
	tData = D.FormatAutoFocusData(tData)
	-- 更新焦点列表
	if nIndex then
		insert(O.aPatternFocus, nIndex, tData)
		O.aPatternFocus = O.aPatternFocus
	else
		insert(O.aPatternFocus, tData)
		O.aPatternFocus = O.aPatternFocus
	end
	D.RescanNearby()
	return tData
end

-- 删除默认焦点
function D.RemoveFocusPattern(szPattern)
	local p
	for i = #O.aPatternFocus, 1, -1 do
		if O.aPatternFocus[i].szPattern == szPattern then
			p = O.aPatternFocus[i]
			remove(O.aPatternFocus, i)
			O.aPatternFocus = O.aPatternFocus
		end
	end
	if not p then
		return
	end
	-- 刷新UI
	if p.szMethod == 'NAME' then
		-- 全字符匹配模式：检查是否在永久焦点中 没有则删除Handle （节约性能）
		for i = #FOCUS_LIST, 1, -1 do
			local p = FOCUS_LIST[i]
			local KObject = LIB.GetObject(p.dwType, p.dwID)
			local dwTemplateID = p.dwType == TARGET.PLAYER and p.dwID or KObject.dwTemplateID
			if KObject and LIB.GetObjectName(KObject, 'never') == szPattern
			and not l_tTempFocusList[p.dwType][p.dwID]
			and not O.tStaticFocus[p.dwType][dwTemplateID] then
				D.OnObjectLeaveScene(p.dwType, p.dwID)
			end
		end
	else
		-- 其他模式：重绘焦点列表
		D.RescanNearby()
	end
end

-- 添加ID焦点
function D.SetFocusID(dwType, dwID, bSave)
	dwType, dwID = tonumber(dwType), tonumber(dwID)
	if bSave then
		local KObject = LIB.GetObject(dwType, dwID)
		local dwTemplateID = dwType == TARGET.PLAYER and dwID or KObject.dwTemplateID
		if O.tStaticFocus[dwType][dwTemplateID] then
			return
		end
		O.tStaticFocus[dwType][dwTemplateID] = true
		O.tStaticFocus = O.tStaticFocus
		D.RescanNearby()
	else
		if l_tTempFocusList[dwType][dwID] then
			return
		end
		l_tTempFocusList[dwType][dwID] = true
		D.OnObjectEnterScene(dwType, dwID)
	end
end

-- 删除ID焦点
function D.RemoveFocusID(dwType, dwID)
	dwType, dwID = tonumber(dwType), tonumber(dwID)
	if l_tTempFocusList[dwType][dwID] then
		l_tTempFocusList[dwType][dwID] = nil
		D.OnObjectLeaveScene(dwType, dwID)
	end
	local KObject = LIB.GetObject(dwType, dwID)
	local dwTemplateID = dwType == TARGET.PLAYER and dwID or KObject.dwTemplateID
	if O.tStaticFocus[dwType][dwTemplateID] then
		O.tStaticFocus[dwType][dwTemplateID] = nil
		O.tStaticFocus = O.tStaticFocus
		D.RescanNearby()
	end
end

-- 清空焦点列表
function D.ClearFocus()
	FOCUS_LIST = {}
	FireUIEvent('MY_FOCUS_UPDATE')
end

-- 重新扫描附近对象更新焦点列表（只增不减）
function D.ScanNearby()
	for _, dwID in ipairs(LIB.GetNearPlayerID()) do
		D.OnObjectEnterScene(TARGET.PLAYER, dwID)
	end
	for _, dwID in ipairs(LIB.GetNearNpcID()) do
		D.OnObjectEnterScene(TARGET.NPC, dwID)
	end
	for _, dwID in ipairs(LIB.GetNearDoodadID()) do
		D.OnObjectEnterScene(TARGET.DOODAD, dwID)
	end
end

-- 重新扫描附近焦点
function D.RescanNearby()
	D.ClearFocus()
	D.ScanNearby()
end
LIB.RegisterEvent('MY_ANMERKUNGEN_UPDATE.MY_Focus', D.RescanNearby)

function D.GetEligibleRules(tRules, dwMapID, dwType, dwID, dwTemplateID, szName, szTong)
	local aRule = {}
	for _, v in ipairs(tRules) do
		if (v.tType.bAll or v.tType[dwType])
		and (v.dwMapID == -1 or v.dwMapID == dwMapID)
		and (
			(v.szMethod == 'NAME' and v.szPattern == szName)
			or (v.szMethod == 'NAME_PATT' and szName:find(v.szPattern))
			or (v.szMethod == 'ID' and tonumber(v.szPattern) == dwID)
			or (v.szMethod == 'TEMPLATE_ID' and tonumber(v.szPattern) == dwTemplateID)
			or (v.szMethod == 'TONG_NAME' and v.szPattern == szTong)
			or (v.szMethod == 'TONG_NAME_PATT' and szTong:find(v.szPattern))
		) then
			insert(aRule, v)
		end
	end
	return aRule
end

-- 对象进入视野
function D.OnObjectEnterScene(dwType, dwID, nRetryCount)
	if nRetryCount and nRetryCount > 5 then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return LIB.DelayCall(5000, function() D.OnObjectEnterScene(dwType, dwID) end)
	end
	local KObject = LIB.GetObject(dwType, dwID)
	if not KObject then
		return
	end

	local szName = LIB.GetObjectName(KObject, 'never')
	-- 解决玩家刚进入视野时名字为空的问题
	if (dwType == TARGET.PLAYER and not szName) or not me then -- 解决自身刚进入场景的时候的问题
		LIB.DelayCall(300, function()
			D.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
		end)
	else-- if szName then -- 判断是否需要焦点
		if not szName then
			szName = LIB.GetObjectName(KObject, 'auto')
		end
		local bFocus, aVia = false, {}
		local dwMapID = LIB.GetMapID(true)
		local dwTemplateID, szTong = -1, ''
		if dwType == TARGET.PLAYER then
			if KObject.dwTongID ~= 0 then
				szTong = GetTongClient().ApplyGetTongName(KObject.dwTongID, 253)
				if not szTong or szTong == '' then -- 解决目标刚进入场景的时候帮会获取不到的问题
					LIB.DelayCall(300, function()
						D.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
					end)
				end
			end
		else
			dwTemplateID = KObject.dwTemplateID
		end
		-- 判断临时焦点
		if l_tTempFocusList[dwType][dwID] then
			insert(aVia, {
				bDeletable = true,
				szVia = _L['Temp focus'],
			})
			bFocus = true
		end
		-- 判断永久焦点
		if not bFocus then
			local dwTemplateID = dwType == TARGET.PLAYER and dwID or KObject.dwTemplateID
			if O.tStaticFocus[dwType][dwTemplateID]
			and not (
				dwType == TARGET.NPC
				and dwTemplateID == CHANGGE_REAL_SHADOW_TPLID
				and IsEnemy(UI_GetClientPlayerID(), dwID)
				and LIB.IsShieldedVersion('CHANGGE_SHADOW')
			) then
				insert(aVia, {
					bDeletable = true,
					szVia = _L['Static focus'],
				})
				bFocus = true
			end
		end
		-- 判断默认焦点
		if not bFocus and O.bAutoFocus then
			local aRule = D.GetEligibleRules(O.aPatternFocus, dwMapID, dwType, dwID, dwTemplateID, szName, szTong)
			for _, tRule in ipairs(aRule) do
				insert(aVia, {
					tRule = tRule,
					bDeletable = false,
					szVia = _L['Auto focus'] .. ' ' .. tRule.szPattern,
				})
				bFocus = true
			end
		end
		-- 判断团队监控焦点
		if not bFocus and O.bTeamMonFocus then
			local aRule = D.GetEligibleRules(TEAMMON_FOCUS, dwMapID, dwType, dwID, dwTemplateID, szName, szTong)
			for _, tRule in ipairs(aRule) do
				insert(aVia, {
					tRule = tRule,
					bDeletable = false,
					szVia = _L['TeamMon focus'] .. ' ' .. tRule.szPattern,
				})
				bFocus = true
			end
		end

		-- 判断竞技场
		if not bFocus then
			if LIB.IsInArena() or LIB.IsInPubg() or LIB.IsInZombieMap() then
				if dwType == TARGET.PLAYER then
					if O.bFocusJJCEnemy and O.bFocusJJCParty then
						insert(aVia, {
							bDeletable = false,
							szVia = _L['Auto focus in arena'],
						})
						bFocus = true
					elseif O.bFocusJJCParty then
						if not IsEnemy(UI_GetClientPlayerID(), dwID) then
							insert(aVia, {
								bDeletable = false,
								szVia = _L['Auto focus party in arena'],
							})
							bFocus = true
						end
					elseif O.bFocusJJCEnemy then
						if IsEnemy(UI_GetClientPlayerID(), dwID) then
							insert(aVia, {
								bDeletable = false,
								szVia = _L['Auto focus enemy in arena'],
							})
							bFocus = true
						end
					end
				elseif dwType == TARGET.NPC then
					if O.bFocusJJCParty
					and KObject.dwTemplateID == CHANGGE_REAL_SHADOW_TPLID
					and not (IsEnemy(UI_GetClientPlayerID(), dwID) and LIB.IsShieldedVersion('CHANGGE_SHADOW')) then
						D.OnRemoveFocus(TARGET.PLAYER, KObject.dwEmployer)
						insert(aVia, {
							bDeletable = false,
							szVia = _L['Auto focus party in arena'],
						})
						bFocus = true
					end
				end
			else
				if not O.bOnlyPublicMap or (not LIB.IsInBattleField() and not LIB.IsInDungeon() and not LIB.IsInArena()) then
					-- 判断好友
					if dwType == TARGET.PLAYER
					and O.bFocusFriend
					and LIB.GetFriend(dwID) then
						insert(aVia, {
							bDeletable = false,
							szVia = _L['Friend focus'],
						})
						bFocus = true
					end
					-- 判断同帮会
					if dwType == TARGET.PLAYER
					and O.bFocusTong
					and dwID ~= LIB.GetClientInfo().dwID
					and LIB.GetTongMember(dwID) then
						insert(aVia, {
							bDeletable = false,
							szVia = _L['Tong member focus'],
						})
						bFocus = true
					end
				end
				-- 判断敌对玩家
				if dwType == TARGET.PLAYER
				and O.bFocusEnemy
				and IsEnemy(UI_GetClientPlayerID(), dwID) then
					insert(aVia, {
						bDeletable = false,
						szVia = _L['Enemy focus'],
					})
					bFocus = true
				end
			end
		end

		-- 判断重要NPC
		if not bFocus and O.bFocusINpc
		and dwType == TARGET.NPC
		and LIB.IsImportantNpc(dwMapID, KObject.dwTemplateID) then
			insert(aVia, {
				bDeletable = false,
				szVia = _L['Important npc focus'],
			})
			bFocus = true
		end

		-- 判断小本本
		if not bFocus and O.bFocusAnmerkungen
		and dwType == TARGET.PLAYER
		and MY_Anmerkungen.GetPlayerNote(dwID) then
			insert(aVia, {
				bDeletable = false,
				szVia = _L['Anmerkungen'],
			})
			bFocus = true
		end

		-- 判断屏蔽的NPC
		if bFocus and dwType == TARGET.NPC and LIB.IsShieldedNpc(dwTemplateID, 'FOCUS') and LIB.IsShieldedVersion('TARGET') then
			bFocus = false
		end

		-- 加入焦点
		if bFocus then
			D.OnSetFocus(dwType, dwID, szName, aVia)
		end
	end
end

-- 对象离开视野
function D.OnObjectLeaveScene(dwType, dwID)
	local KObject = LIB.GetObject(dwType, dwID)
	if KObject then
		if dwType == TARGET.NPC then
			if O.bFocusJJCParty
			and KObject.dwTemplateID == CHANGGE_REAL_SHADOW_TPLID
			and LIB.IsInArena() and not (IsEnemy(UI_GetClientPlayerID(), dwID) and LIB.IsShieldedVersion('TARGET')) then
				D.OnSetFocus(TARGET.PLAYER, KObject.dwEmployer, LIB.GetObjectName(KObject, 'never'), _L['Auto focus party in arena'])
			end
		end
	end
	D.OnRemoveFocus(dwType, dwID)
end

-- 目标加入焦点列表
function D.OnSetFocus(dwType, dwID, szName, aVia)
	local nIndex
	for i, p in ipairs(FOCUS_LIST) do
		if p.dwType == dwType and p.dwID == dwID then
			nIndex = i
			break
		end
	end
	if not nIndex then
		insert(FOCUS_LIST, {
			dwType = dwType,
			dwID = dwID,
			szName = szName,
			aVia = aVia,
		})
		nIndex = #FOCUS_LIST
	end
	FireUIEvent('MY_FOCUS_UPDATE')
end

-- 目标移除焦点列表
function D.OnRemoveFocus(dwType, dwID)
	-- 从列表数据中删除
	for i = #FOCUS_LIST, 1, -1 do
		local p = FOCUS_LIST[i]
		if p.dwType == dwType and p.dwID == dwID then
			remove(FOCUS_LIST, i)
			break
		end
	end
	FireUIEvent('MY_FOCUS_UPDATE')
end

-- 排序
function D.SortFocus(fn)
	local p = GetClientPlayer()
	fn = fn or function(p1, p2)
		p1 = LIB.GetObject(p1.dwType, p1.dwID)
		p2 = LIB.GetObject(p2.dwType, p2.dwID)
		if p1 and p2 then
			return pow(p.nX - p1.nX, 2) + pow(p.nY - p1.nY, 2) < pow(p.nX - p2.nX, 2) + pow(p.nY - p2.nY, 2)
		end
		return true
	end
	sort(FOCUS_LIST, fn)
end

-- 获取焦点列表
function D.GetFocusList()
	local t = {}
	for _, v in ipairs(FOCUS_LIST) do
		insert(t, v)
	end
	return t
end

-- 获取当前显示的焦点列表
function D.GetDisplayList()
	local t = {}
	local me = GetClientPlayer()
	if not D.IsShielded() and me then
		for _, p in ipairs(FOCUS_LIST) do
			if #t >= O.nMaxDisplay then
				break
			end
			local KObject = LIB.GetObject(p.dwType, p.dwID)
			if KObject then
				local fCurrentLife, fMaxLife
				if p.dwType == TARGET.PLAYER or p.dwType == TARGET.NPC then
					fCurrentLife, fMaxLife = LIB.GetObjectLife(KObject)
				end
				local bFocus, tRule, szVia, bDeletable = false
				for _, via in ipairs(p.aVia) do
					if via.tRule then
						local bRuleFocus = true
						if bRuleFocus and via.tRule.tLife.bEnable
						and fCurrentLife and fMaxLife
						and not LIB.JudgeOperator(via.tRule.tLife.szOperator, fCurrentLife / fMaxLife * 100, via.tRule.tLife.nValue) then
							bRuleFocus = false
						end
						if bRuleFocus and via.tRule.nMaxDistance ~= 0
						and LIB.GetDistance(me, KObject, O.szDistanceType) > via.tRule.nMaxDistance then
							bRuleFocus = false
						end
						if bRuleFocus and not via.tRule.tRelation.bAll then
							if LIB.IsEnemy(me.dwID, KObject.dwID) then
								bRuleFocus = via.tRule.tRelation.bEnemy
							else
								bRuleFocus = via.tRule.tRelation.bAlly
							end
						end
						if bRuleFocus then
							bFocus = true
							tRule = via.tRule
							szVia = via.szVia
							bDeletable = via.bDeletable
							break
						end
					else
						bFocus = true
						szVia = via.szVia
						bDeletable = via.bDeletable
					end
				end
				if bFocus and (p.dwType == TARGET.NPC or p.dwType == TARGET.PLAYER) and LIB.IsIsolated(me) ~= LIB.IsIsolated(KObject) then
					bFocus = false
				end
				if bFocus and O.bHideDeath then
					if p.dwType == TARGET.NPC or p.dwType == TARGET.PLAYER then
						bFocus = KObject.nMoveState ~= MOVE_STATE.ON_DEATH
					else--if p.dwType == TARGET.DOODAD then
						bFocus = KObject.nKind ~= DOODAD_KIND.CORPSE
					end
				end
				if bFocus then
					insert(t, setmetatable({
						tRule = tRule,
						szVia = szVia,
						bDeletable = bDeletable,
					}, { __index = p }))
				end
			end
		end
	end
	return t
end

function D.GetTargetMenu(dwType, dwID)
	return {{
		szOption = _L['Add to temp focus list'],
		fnAction = function()
			if not O.bEnable then
				O.bEnable = true
				MY_FocusUI.Open()
			end
			D.SetFocusID(dwType, dwID)
		end,
	}, {
		szOption = _L['Add to static focus list'],
		fnAction = function()
			if not O.bEnable then
				O.bEnable = true
				MY_FocusUI.Open()
			end
			D.SetFocusID(dwType, dwID, true)
		end,
	}}
end

function D.FormatRuleText(v, bNoBasic)
	local aText = {}
	if not bNoBasic then
		if not v.tType or v.tType.bAll then
			insert(aText, _L['All type'])
		else
			local aSub = {}
			for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
				if v.tType[eType] then
					insert(aSub, _L.TARGET[eType])
				end
			end
			insert(aText, #aSub == 0 and _L['None type'] or concat(aSub, '|'))
		end
	end
	if not v.tRelation or v.tRelation.bAll then
		insert(aText, _L['All relation'])
	else
		local aSub = {}
		for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
			if v.tRelation['b' .. szRelation] then
				insert(aSub, _L.RELATION[szRelation])
			end
		end
		insert(aText, #aSub == 0 and _L['None relation'] or concat(aSub, '|'))
	end
	if not bNoBasic and v.szPattern then
		return v.szPattern .. ' (' .. concat(aText, ',') .. ')'
	end
	return concat(aText, ',')
end

function D.OpenRuleEditor(tData, onChangeNotify, bHideBase)
	local tData = D.FormatAutoFocusData(tData)
	local frame = UI.CreateFrame('MY_Focus_Editor', { close = true, text = _L['Focus rule editor'] })
	local ui = UI(frame)
	local X, Y, W = 30, 50, 350
	local nX, nY = X, Y
	local dY = 27
	if not bHideBase then
		W = 450
		-- 匹配方式
		ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Judge method'] }):AutoWidth()
		nX, nY = X + 10, nY + dY
		for i, eType in ipairs({ 'NAME', 'NAME_PATT', 'ID', 'TEMPLATE_ID', 'TONG_NAME', 'TONG_NAME_PATT' }) do
			if i == 5 then
				nX, nY = X + 10, nY + dY
			end
			nX = ui:Append('WndRadioBox', {
				x = nX, y = nY,
				group = 'judge_method',
				text = _L.JUDGE_METHOD[eType],
				checked = tData.szMethod == eType,
				oncheck = function()
					tData.szMethod = eType
					onChangeNotify(tData)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		end
		nX, nY = X, nY + dY
		-- 目标类型
		ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Target type'] }):AutoWidth()
		nX, nY = X + 10, nY + dY
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['All'],
			checked = tData.tType.bAll,
			oncheck = function()
				tData.tType.bAll = not tData.tType.bAll
				onChangeNotify(tData)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
			nX = ui:Append('WndCheckBox', {
				x = nX, y = nY,
				text = _L.TARGET[eType],
				checked = tData.tType[eType],
				oncheck = function()
					tData.tType[eType] = not tData.tType[eType]
					onChangeNotify(tData)
				end,
				autoenable = function() return not tData.tType.bAll end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		end
		nX, nY = X, nY + dY
	end
	-- 目标关系
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Target relation'] }):AutoWidth()
	nX, nY = X + 10, nY + dY
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['All'],
		checked = tData.tRelation.bAll,
		oncheck = function()
			tData.tRelation.bAll = not tData.tRelation.bAll
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L.RELATION[szRelation],
			checked = tData.tRelation['b' .. szRelation],
			oncheck = function()
				tData.tRelation['b' .. szRelation] = not tData.tRelation['b' .. szRelation]
				onChangeNotify(tData)
			end,
			autoenable = function() return not tData.tRelation.bAll end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	end
	nX, nY = X, nY + dY
	-- 目标血量百分比
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Target life percentage'] }):AutoWidth()
	nX, nY = X + 10, nY + dY
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Enable'],
		checked = tData.tLife.bEnable,
		oncheck = function()
			tData.tLife.bEnable = not tData.tLife.bEnable
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = _L['Operator'],
		menu = function()
			return LIB.InsertOperatorMenu({}, tData.tLife.szOperator, function(op)
				tData.tLife.szOperator = op
				onChangeNotify(tData)
			end)
		end,
		autoenable = function() return tData.tLife.bEnable end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndEditBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = tData.tLife.nValue,
		onchange = function(szText)
			local nValue = tonumber(szText) or 0
			tData.tLife.nValue = nValue
			onChangeNotify(tData)
		end,
		autoenable = function() return tData.tLife.bEnable end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX, nY = X, nY + dY
	-- 最远距离
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Max distance'] }):AutoWidth()
	nX, nY = X + 10, nY + dY
	nX = ui:Append('WndEditBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = tData.nMaxDistance,
		onchange = function(szText)
			local nValue = tonumber(szText) or 0
			tData.nMaxDistance = nValue
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX, nY = X, nY + dY
	-- 名称显示
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Name display'] }):AutoWidth()
	nX, nY = X + 10, nY + dY
	nX = ui:Append('WndEditBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = tData.szDisplay,
		onchange = function(szText)
			tData.szDisplay = szText
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX, nY = X, nY + dY

	nY = nY + 20
	ui:Append('WndButton', {
		x = (W - 100) / 2, y = nY, w = 100,
		text = g_tStrings.STR_FRIEND_DEL, color = { 255, 0, 0 },
		buttonstyle = 'FLAT',
		onclick = function()
			LIB.Confirm(_L['Sure to delete?'], function()
				onChangeNotify()
				ui:Remove()
			end)
		end,
	})
	nX, nY = X, nY + dY

	ui:Size(W, nY + 40):Anchor('CENTER')
end

do
local function UpdateTeamMonData()
	if MY_TeamMon and MY_TeamMon.IterTable and MY_TeamMon.GetTable then
		local aFocus = {}
		for _, ds in ipairs({
			{ szType = 'NPC', dwType = TARGET.NPC},
			{ szType = 'DOODAD', dwType = TARGET.DOODAD},
		}) do
			for _, data in MY_TeamMon.IterTable(MY_TeamMon.GetTable(ds.szType), 0, true) do
				if data.aFocus then
					for _, p in ipairs(data.aFocus) do
						local rule = Clone(p)
						rule.szMethod = 'TEMPLATE_ID'
						rule.szPattern = tostring(data.dwID)
						rule.tType = {
							bAll = false,
							[TARGET.NPC] = false,
							[TARGET.PLAYER] = false,
							[TARGET.DOODAD] = false,
						}
						rule.tType[ds.dwType] = true
						insert(aFocus, D.FormatAutoFocusData(rule))
					end
				end
			end
		end
		TEAMMON_FOCUS = aFocus
		D.RescanNearby()
	end
end
LIB.RegisterEvent('LOADING_ENDING.MY_Focus', UpdateTeamMonData)
local function onTeamMonUpdate()
	if arg0 and not arg0['NPC'] and not arg0['DOODAD'] then
		return
	end
	UpdateTeamMonData()
end
LIB.RegisterEvent('MY_TM_DATA_RELOAD.MY_Focus', onTeamMonUpdate)
end

do
local function onInit()
	-- 加载设置项数据
	D.LoadConfig()
	-- 密码生成
	local k = char(80, 65, 83, 83, 80, 72, 82, 65, 83, 69)
	if IsTable(D[k]) then
		for i = 0, 50 do
			for j, v in ipairs({ 23, 112, 234, 156 }) do
				insert(D[k], (i * j * ((31 * v) % 256)) % 256)
			end
		end
		D[k] = char(unpack(D[k]))
	end
	-- 用户自定义默认焦点
	if not O.aPatternFocus then
		O.aPatternFocus = {}
	end
	for i, v in ipairs(O.aPatternFocus) do
		if IsString(v) then
			v = { szPattern = v }
		end
		O.aPatternFocus[i] = D.FormatAutoFocusData(v)
	end
	-- 永久焦点
	if not O.tStaticFocus then
		O.tStaticFocus = {}
	end
	for _, dwType in ipairs({TARGET.PLAYER, TARGET.NPC, TARGET.DOODAD}) do
		if not O.tStaticFocus[dwType] then
			O.tStaticFocus[dwType] = {}
		end
	end
	D.CheckFrameOpen()
	D.RescanNearby()
end
LIB.RegisterInit('MY_Focus', onInit)
end

do
local function onMenu()
	local dwType, dwID = GetClientPlayer().GetTarget()
	return D.GetTargetMenu(dwType, dwID)
end
LIB.RegisterTargetAddonMenu('MY_Focus', onMenu)
end

do
local function onHotKey()
	local dwType, dwID = LIB.GetTarget()
	local aList = D.GetDisplayList()
	local t = aList[1]
	if not t then
		return
	end
	for i, p in ipairs(aList) do
		if p.dwType == dwType and p.dwID == dwID then
			t = aList[i + 1] or t
		end
	end
	LIB.SetTarget(t.dwType, t.dwID)
end
LIB.RegisterHotKey('MY_Focus_LoopTarget', _L['Loop target in focus'], onHotKey)
end

LIB.RegisterTutorial({
	szKey = 'MY_Focus',
	szMessage = _L['Would you like to use MY focus?'],
	fnRequire = function() return not O.bEnable end,
	{
		szOption = _L['Use'],
		bDefault = true,
		fnAction = function()
			O.bEnable = true
			MY_FocusUI.Open()
			LIB.RedrawTab('MY_Focus')
		end,
	},
	{
		szOption = _L['Not use'],
		fnAction = function()
			O.bEnable = false
			MY_FocusUI.Close()
			LIB.RedrawTab('MY_Focus')
		end,
	},
})

-- Global exports
do
local settings = {
	name = 'MY_Focus',
	exports = {
		{
			fields = {
				'GetTargetMenu',
				'IsShielded',
				'RescanNearby',
				'IsEnabled',
				'GetAllFocusPattern',
				'SetFocusPattern',
				'RemoveFocusPattern',
				'GetDisplayList',
				'OnObjectEnterScene',
				'OnObjectLeaveScene',
				'SetFocusID',
				'RemoveFocusID',
				'SortFocus',
				'OpenRuleEditor',
				'FormatRuleText',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'bMinimize',
				'bFocusINpc',
				'bFocusFriend',
				'bFocusTong',
				'bOnlyPublicMap',
				'bSortByDistance',
				'bFocusEnemy',
				'bFocusAnmerkungen',
				'bAutoHide',
				'nMaxDisplay',
				'bAutoFocus',
				'bTeamMonFocus',
				'bHideDeath',
				'bDisplayKungfuIcon',
				'bFocusJJCParty',
				'bFocusJJCEnemy',
				'bShowTarget',
				'szDistanceType',
				'bHealHelper',
				'bShowTipRB',
				'bEnableSceneNavi',
				'anchor',
				'fScaleX',
				'fScaleY',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'bMinimize',
				'bFocusINpc',
				'bFocusFriend',
				'bFocusTong',
				'bOnlyPublicMap',
				'bSortByDistance',
				'bFocusEnemy',
				'bFocusAnmerkungen',
				'bAutoHide',
				'nMaxDisplay',
				'bAutoFocus',
				'bTeamMonFocus',
				'bHideDeath',
				'bDisplayKungfuIcon',
				'bFocusJJCParty',
				'bFocusJJCEnemy',
				'bShowTarget',
				'szDistanceType',
				'bHealHelper',
				'bShowTipRB',
				'bEnableSceneNavi',
				'anchor',
				'fScaleX',
				'fScaleY',
			},
			triggers = {
				bEnable = D.OnConfigChange,
				bMinimize = D.OnConfigChange,
				anchor = D.OnConfigChange,
				bFocusINpc = D.OnConfigChange,
				bFocusFriend = D.OnConfigChange,
				bFocusTong = D.OnConfigChange,
				bOnlyPublicMap = D.OnConfigChange,
				bSortByDistance = D.OnConfigChange,
				bFocusEnemy = D.OnConfigChange,
				bFocusAnmerkungen = D.OnConfigChange,
				bAutoHide = D.OnConfigChange,
				nMaxDisplay = D.OnConfigChange,
				bAutoFocus = D.OnConfigChange,
				bTeamMonFocus = D.OnConfigChange,
				bHideDeath = D.OnConfigChange,
				bDisplayKungfuIcon = D.OnConfigChange,
				bFocusJJCParty = D.OnConfigChange,
				bFocusJJCEnemy = D.OnConfigChange,
				bShowTarget = D.OnConfigChange,
				szDistanceType = D.OnConfigChange,
				bHealHelper = D.OnConfigChange,
				bShowTipRB = D.OnConfigChange,
				bEnableSceneNavi = D.OnConfigChange,
				fScaleX = D.OnConfigChange,
				fScaleY = D.OnConfigChange,
			},
			root = O,
		},
	},
}
MY_Focus = LIB.CreateModule(settings)
end
