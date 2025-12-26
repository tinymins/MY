--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 焦点列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Focus/MY_Focus'
local PLUGIN_NAME = 'MY_Focus'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Focus'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_Focus', { ['*'] = false })
X.RegisterRestriction('MY_Focus.MapRestriction', { ['*'] = true })
X.RegisterRestriction('MY_Focus.SHILDED_NPC', { ['*'] = true })
X.RegisterRestriction('MY_Focus.CHANGGE_SHADOW', { ['*'] = true })
--------------------------------------------------------------------------

local CHANGGE_REAL_SHADOW_TPLID = 46140 -- 清绝歌影 的主体影子
local FOCUS_LIST = {}
local TEAMMON_FOCUS = {}
local l_tTempFocusList = {
	[TARGET.PLAYER] = {},   -- dwID
	[TARGET.NPC]    = {},   -- dwTemplateID
	[TARGET.DOODAD] = {},   -- dwTemplateID
}
local O = X.CreateUserSettingsModule('MY_Focus', _L['Target'], {
	bEnable = { -- 是否启用
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bMinimize = { -- 是否最小化
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Minimize'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoHide = { -- 无焦点时隐藏
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Hide when empty'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nMaxDisplay = { -- 最大显示数量
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Max display count'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 5,
	},
	fScaleX = { -- 缩放比例
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Scale-x'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	fScaleY = { -- 缩放比例
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Scale-y'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	anchor = { -- 默认坐标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['UI Anchor'],
		}),
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x=-300, y=220, s='TOPRIGHT', r='TOPRIGHT' },
	},
	bFocusINpc = { -- 焦点重要NPC
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus very important npc'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bFocusFriend = { -- 焦点附近好友
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus friend'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusTong = { -- 焦点帮会成员
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus tong'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOnlyPublicMap = { -- 仅在公共地图焦点好友帮会成员
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus only in public map'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSortByDistance = { -- 优先焦点近距离目标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Sort by distance'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusEnemy = { -- 焦点敌对玩家
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus enemy'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusPlayerRemark = { -- 焦点角色备注记录在案的目标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['MY_PlayerRemark auto focus'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoFocus = { -- 启用默认焦点
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTeamMonFocus = { -- 启用团队监控焦点
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['TeamMon focus'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bHideDeath = { -- 隐藏死亡目标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Hide dead object'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bDisplayKungfuIcon = { -- 显示心法图标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Display kungfu icon instead of location'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusJJCParty = { -- 焦点名剑大会队友
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus party in arena'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFocusJJCEnemy = { -- 焦点名剑大会敌队
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus enemy in arena'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowTarget = { -- 显示目标目标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Show focus\'s target'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	szDistanceType = { -- 坐标距离计算方式
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Distance type'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'global',
	},
	bHealHelper = { -- 辅助治疗模式
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Heal healper'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowTipRB = { -- 在屏幕右下角显示信息
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Show tip at right bottom'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableSceneNavi = { -- 场景追踪点
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Enable scene navi'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	aPatternFocus = { -- 默认焦点
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Auto focus data'],
		}),
		xSchema = X.Schema.Collection(X.Schema.Record({
			szMethod = X.Schema.String,
			szPattern = X.Schema.String,
			szDisplay = X.Schema.String,
			dwMapID = X.Schema.Number,
			tType = X.Schema.MixedTable({
				bAll = X.Schema.Optional(X.Schema.Boolean),
				[TARGET.NPC] = X.Schema.Optional(X.Schema.Boolean),
				[TARGET.PLAYER] = X.Schema.Optional(X.Schema.Boolean),
				[TARGET.DOODAD] = X.Schema.Optional(X.Schema.Boolean),
			}),
			tRelation = X.Schema.Record({
				bAll = X.Schema.Optional(X.Schema.Boolean),
				bEnemy = X.Schema.Optional(X.Schema.Boolean),
				bAlly = X.Schema.Optional(X.Schema.Boolean),
			}),
			tLife = X.Schema.Record({
				bEnable = X.Schema.Boolean,
				szOperator = X.Schema.String,
				nValue = X.Schema.Number,
			}),
			nMaxDistance = X.Schema.Number,
		})),
		xDefaultValue = {},
	},
	tStaticFocus = { -- 永久焦点
		ePathType = X.PATH_TYPE.SERVER,
		szLabel = _L['MY_Focus'],
		szDescription = X.MakeCaption({
			_L['Static focus data'],
		}),
		xSchema = X.Schema.MixedTable({
			[TARGET.PLAYER] = X.Schema.Map(X.Schema.Number, X.Schema.Boolean), -- dwID
			[TARGET.NPC]    = X.Schema.Map(X.Schema.Number, X.Schema.Boolean), -- dwTemplateID
			[TARGET.DOODAD] = X.Schema.Map(X.Schema.Number, X.Schema.Boolean), -- dwTemplateID
		}),
		xDefaultValue = {
			[TARGET.PLAYER] = {}, -- dwID
			[TARGET.NPC]    = {}, -- dwTemplateID
			[TARGET.DOODAD] = {}, -- dwTemplateID
		},
	},
})
local D = {}

function D.IsShielded()
	if X.IsRestricted('MY_Focus') then
		return true
	end
	return X.IsRestricted('MY_Focus.MapRestriction') and X.IsInShieldedMap()
end

function D.IsEnabled()
	return O.bEnable and not D.IsShielded()
end

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
	return X.FormatDataStructure(data, ds)
end
local dsl = {
	'__META__',
	__VALUE__ = {},
	__CHILD_TEMPLATE__ = ds,
}
function D.FormatAutoFocusDataList(datalist)
	return X.FormatDataStructure(datalist, dsl)
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
	local szRolePath = X.FormatPath({'config/focus.jx3dat', X.PATH_TYPE.ROLE})
	local szGlobalPath = X.FormatPath({'config/focus/', X.PATH_TYPE.GLOBAL})
	local szServerPath = X.FormatPath({'config/focus/', X.PATH_TYPE.SERVER})
	local aPath = {}
	for _, szPath in ipairs(CPath.GetFileList(szGlobalPath)) do
		table.insert(aPath, szGlobalPath .. szPath)
	end
	for _, szPath in ipairs(CPath.GetFileList(szServerPath)) do
		table.insert(aPath, szServerPath .. szPath)
	end
	table.insert(aPath, szRolePath)
	for _, szPath in ipairs(aPath) do
		local config = X.LoadLUAData(szPath)
		CPath.DelFile(szPath)
		if config then
			for k, v in pairs(config) do
				-- 永久焦点与默认焦点数据需要合并处理
				if k == 'tStaticFocus' then
					for _, eType in ipairs({ TARGET.PLAYER, TARGET.NPC, TARGET.DOODAD }) do
						if not X.IsTable(v[eType]) then
							v[eType] = {}
						end
						for kk, vv in pairs(O.tStaticFocus[eType]) do
							pcall(X.Set, v, kk, vv)
						end
					end
				elseif k == 'aPatternFocus' then
					for _, vv in ipairs(O.aPatternFocus) do
						pcall(table.insert, v, vv)
					end
				end
				pcall(X.Set, O, k, v)
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
	return X.Clone(O.aPatternFocus)
end

-- 添加、修改默认焦点
function D.SetFocusPattern(szPattern, tData)
	local nIndex
	szPattern = X.TrimString(szPattern)
	for i, v in X.ipairs_r(O.aPatternFocus) do
		if v.szPattern == szPattern then
			nIndex = i
			table.remove(O.aPatternFocus, i)
			O.aPatternFocus = O.aPatternFocus
		end
	end
	-- 格式化数据
	if not X.IsTable(tData) then
		tData = { szPattern = szPattern }
	end
	tData = D.FormatAutoFocusData(tData)
	-- 更新焦点列表
	if nIndex then
		table.insert(O.aPatternFocus, nIndex, tData)
		O.aPatternFocus = O.aPatternFocus
	else
		table.insert(O.aPatternFocus, tData)
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
			table.remove(O.aPatternFocus, i)
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
			local KObject = X.GetTargetHandle(p.dwType, p.dwID)
			local dwTemplateID = p.dwType == TARGET.PLAYER and p.dwID or KObject.dwTemplateID
			if KObject and X.GetTargetName(p.dwType, p.dwID, { eShowID = 'never' }) == szPattern
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
		local KObject = X.GetTargetHandle(dwType, dwID)
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
	local KObject = X.GetTargetHandle(dwType, dwID)
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
	for _, dwID in ipairs(X.GetNearPlayerID()) do
		D.OnObjectEnterScene(TARGET.PLAYER, dwID)
	end
	for _, dwID in ipairs(X.GetNearNpcID()) do
		D.OnObjectEnterScene(TARGET.NPC, dwID)
	end
	for _, dwID in ipairs(X.GetNearDoodadID()) do
		D.OnObjectEnterScene(TARGET.DOODAD, dwID)
	end
end

-- 重新扫描附近焦点
function D.RescanNearby()
	D.ClearFocus()
	D.ScanNearby()
end
X.RegisterEvent('MY_PLAYER_REMARK_UPDATE', 'MY_Focus', D.RescanNearby)

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
			table.insert(aRule, v)
		end
	end
	return aRule
end

-- 对象进入视野
function D.OnObjectEnterScene(dwType, dwID, nRetryCount)
	if nRetryCount and nRetryCount > 5 then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return X.DelayCall(5000, function() D.OnObjectEnterScene(dwType, dwID) end)
	end
	local KObject = X.GetTargetHandle(dwType, dwID)
	if not KObject then
		return
	end

	local szName = X.GetTargetName(dwType, dwID, { eShowID = 'never' })
	-- 解决玩家刚进入视野时名字为空的问题
	if (dwType == TARGET.PLAYER and not szName) or not me then -- 解决自身刚进入场景的时候的问题
		X.DelayCall(300, function()
			D.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
		end)
	else-- if szName then -- 判断是否需要焦点
		if not szName then
			szName = X.GetTargetName(dwType, dwID, { eShowID = 'auto' })
		end
		local szGlobalID = dwType == TARGET.PLAYER and X.GetPlayerGlobalID(dwID) or nil
		local bFocus, aVia = false, {}
		local dwMapID = X.GetMapID(true)
		local dwTemplateID, szTong = -1, ''
		if dwType == TARGET.PLAYER then
			if KObject.dwTongID ~= 0 then
				szTong = X.GetTongName(KObject.dwTongID, 253)
				if not szTong or szTong == '' then -- 解决目标刚进入场景的时候帮会获取不到的问题
					X.DelayCall(300, function()
						D.OnObjectEnterScene(dwType, dwID, (nRetryCount or 0) + 1)
					end)
				end
			end
		else
			dwTemplateID = KObject.dwTemplateID
		end
		-- 判断临时焦点
		if l_tTempFocusList[dwType][dwID] then
			table.insert(aVia, {
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
				and IsEnemy(X.GetClientPlayerID(), dwID)
				and X.IsRestricted('MY_Focus.CHANGGE_SHADOW')
			) then
				table.insert(aVia, {
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
				table.insert(aVia, {
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
				table.insert(aVia, {
					tRule = tRule,
					bDeletable = false,
					szVia = _L['TeamMon focus'] .. ' ' .. tRule.szPattern,
				})
				bFocus = true
			end
		end

		-- 判断名剑大会
		if not bFocus then
			if X.IsInCompetitionMap() and not X.IsInBattlefieldMap() then
				if dwType == TARGET.PLAYER then
					if O.bFocusJJCEnemy and O.bFocusJJCParty then
						table.insert(aVia, {
							bDeletable = false,
							szVia = _L['Auto focus in arena'],
						})
						bFocus = true
					elseif O.bFocusJJCParty then
						if not IsEnemy(X.GetClientPlayerID(), dwID) then
							table.insert(aVia, {
								bDeletable = false,
								szVia = _L['Auto focus party in arena'],
							})
							bFocus = true
						end
					elseif O.bFocusJJCEnemy then
						if IsEnemy(X.GetClientPlayerID(), dwID) then
							table.insert(aVia, {
								bDeletable = false,
								szVia = _L['Auto focus enemy in arena'],
							})
							bFocus = true
						end
					end
				elseif dwType == TARGET.NPC then
					if O.bFocusJJCParty
					and KObject.dwTemplateID == CHANGGE_REAL_SHADOW_TPLID
					and not (IsEnemy(X.GetClientPlayerID(), dwID) and X.IsRestricted('MY_Focus.CHANGGE_SHADOW')) then
						D.OnRemoveFocus(TARGET.PLAYER, KObject.dwEmployer)
						table.insert(aVia, {
							bDeletable = false,
							szVia = _L['Auto focus party in arena'],
						})
						bFocus = true
					end
				end
			else
				if not O.bOnlyPublicMap or (not X.IsInCompetitionMap() and not X.IsInDungeonMap()) then
					-- 判断角色备注
					if dwType == TARGET.PLAYER
					and O.bFocusPlayerRemark
					and MY_PlayerRemark
					and MY_PlayerRemark.Get then
						local tRemark = szGlobalID
							and MY_PlayerRemark.Get(szGlobalID)
							or MY_PlayerRemark.Get(szName)
						if tRemark then
							table.insert(aVia, {
								bDeletable = false,
								szVia = _L['MY_PlayerRemark'] .. '\n' .. _L['PlayerRemark: '] .. tRemark.szRemark,
							})
							bFocus = true
						end
					end
					-- 判断好友
					if dwType == TARGET.PLAYER
					and O.bFocusFriend
					and (
						X.IsFellowship(dwID)
						or (szGlobalID and X.IsFellowship(szGlobalID))
					) then
						table.insert(aVia, {
							bDeletable = false,
							szVia = _L['Friend focus'],
						})
						bFocus = true
					end
					-- 判断同帮会
					if dwType == TARGET.PLAYER
					and O.bFocusTong
					and dwID ~= X.GetClientPlayerInfo().dwID
					and X.IsTongMember(dwID) then
						table.insert(aVia, {
							bDeletable = false,
							szVia = _L['Tong member focus'],
						})
						bFocus = true
					end
				end
				-- 判断敌对玩家
				if dwType == TARGET.PLAYER
				and O.bFocusEnemy
				and IsEnemy(X.GetClientPlayerID(), dwID) then
					table.insert(aVia, {
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
		and X.IsImportantNpc(dwMapID, KObject.dwTemplateID) then
			table.insert(aVia, {
				bDeletable = false,
				szVia = _L['Important npc focus'],
			})
			bFocus = true
		end

		-- 判断屏蔽的NPC
		if bFocus and dwType == TARGET.NPC and X.IsShieldedNpc(dwTemplateID, 'FOCUS') and X.IsRestricted('MY_Focus.SHILDED_NPC') then
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
	local KObject = X.GetTargetHandle(dwType, dwID)
	if KObject then
		if dwType == TARGET.NPC then
			if D.bReady and O.bFocusJJCParty
			and KObject.dwTemplateID == CHANGGE_REAL_SHADOW_TPLID
			and X.IsInCompetitionMap() and not (IsEnemy(X.GetClientPlayerID(), dwID) and X.IsRestricted('MY_Focus.SHILDED_NPC')) then
				D.OnSetFocus(TARGET.PLAYER, KObject.dwEmployer, X.GetTargetName(dwType, dwID, { eShowID = 'never' }), _L['Auto focus party in arena'])
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
		table.insert(FOCUS_LIST, {
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
			table.remove(FOCUS_LIST, i)
			break
		end
	end
	FireUIEvent('MY_FOCUS_UPDATE')
end

-- 排序
function D.SortFocus(fn)
	local p = X.GetClientPlayer()
	fn = fn or function(p1, p2)
		p1 = X.GetTargetHandle(p1.dwType, p1.dwID)
		p2 = X.GetTargetHandle(p2.dwType, p2.dwID)
		if p1 and p2 then
			return math.pow(p.nX - p1.nX, 2) + math.pow(p.nY - p1.nY, 2) < math.pow(p.nX - p2.nX, 2) + math.pow(p.nY - p2.nY, 2)
		end
		return true
	end
	table.sort(FOCUS_LIST, fn)
end

-- 获取焦点列表
function D.GetFocusList()
	local t = {}
	for _, v in ipairs(FOCUS_LIST) do
		table.insert(t, v)
	end
	return t
end

-- 获取当前显示的焦点列表
function D.GetDisplayList()
	local t = {}
	local me = X.GetClientPlayer()
	if not D.IsShielded() and me then
		for _, p in ipairs(FOCUS_LIST) do
			if #t >= O.nMaxDisplay then
				break
			end
			local KObject = X.GetTargetHandle(p.dwType, p.dwID)
			if KObject then
				local fCurrentLife, fMaxLife
				if p.dwType == TARGET.PLAYER or p.dwType == TARGET.NPC then
					fCurrentLife, fMaxLife = X.GetCharacterLife(KObject)
				end
				local bFocus, tRule, szVia, bDeletable = false
				for _, via in ipairs(p.aVia) do
					if via.tRule then
						local bRuleFocus = true
						if bRuleFocus and via.tRule.tLife.bEnable
						and fCurrentLife and fMaxLife
						and not X.JudgeOperator(via.tRule.tLife.szOperator, fCurrentLife / fMaxLife * 100, via.tRule.tLife.nValue) then
							bRuleFocus = false
						end
						if bRuleFocus and via.tRule.nMaxDistance ~= 0
						and X.GetCharacterDistance(me, KObject, O.szDistanceType) > via.tRule.nMaxDistance then
							bRuleFocus = false
						end
						if bRuleFocus and not via.tRule.tRelation.bAll then
							if X.IsCharacterRelationEnemy(me.dwID, KObject.dwID) then
								bRuleFocus = via.tRule.tRelation.bEnemy
							else
								bRuleFocus = via.tRule.tRelation.bAlly
							end
						end
						if bRuleFocus then
							--2025.8.16增加隐藏焦点方法，上述规则满足后，判断最大距离是否为-1，若为-1不显示焦点并跳出规则遍历
							bFocus = via.tRule.nMaxDistance ~= -1
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
				if bFocus and (p.dwType == TARGET.NPC or p.dwType == TARGET.PLAYER) and X.IsCharacterIsolated(me) ~= X.IsCharacterIsolated(KObject) then
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
					table.insert(t, setmetatable({
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
			table.insert(aText, _L['All type'])
		else
			local aSub = {}
			for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
				if v.tType[eType] then
					table.insert(aSub, _L.TARGET[eType])
				end
			end
			table.insert(aText, #aSub == 0 and _L['None type'] or table.concat(aSub, '|'))
		end
	end
	if not v.tRelation or v.tRelation.bAll then
		table.insert(aText, _L['All relation'])
	else
		local aSub = {}
		for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
			if v.tRelation['b' .. szRelation] then
				table.insert(aSub, _L.RELATION[szRelation])
			end
		end
		table.insert(aText, #aSub == 0 and _L['None relation'] or table.concat(aSub, '|'))
	end
	if not bNoBasic and v.szPattern then
		return v.szPattern .. ' (' .. table.concat(aText, ',') .. ')'
	end
	return table.concat(aText, ',')
end

function D.OpenRuleEditor(tData, onChangeNotify, bHideBase)
	local tData = D.FormatAutoFocusData(tData)
	local frame = X.UI.CreateFrame('MY_Focus_Editor', { close = true, text = _L['Focus rule editor'] })
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY, W = 30, 50, 350
	local nX, nY = nPaddingX, nPaddingY
	local dY = 27
	if not bHideBase then
		W = 450
		-- 匹配方式
		ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Judge method'] }):AutoWidth()
		nX, nY = nPaddingX + 10, nY + dY
		for i, eType in ipairs({ 'NAME', 'NAME_PATT', 'ID', 'TEMPLATE_ID', 'TONG_NAME', 'TONG_NAME_PATT' }) do
			if i == 5 then
				nX, nY = nPaddingX + 10, nY + dY
			end
			nX = ui:Append('WndRadioBox', {
				x = nX, y = nY,
				group = 'judge_method',
				text = _L.JUDGE_METHOD[eType],
				checked = tData.szMethod == eType,
				onCheck = function()
					tData.szMethod = eType
					onChangeNotify(tData)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		end
		nX, nY = nPaddingX, nY + dY
		-- 目标类型
		ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Target type'] }):AutoWidth()
		nX, nY = nPaddingX + 10, nY + dY
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['All'],
			checked = tData.tType.bAll,
			onCheck = function()
				tData.tType.bAll = not tData.tType.bAll
				onChangeNotify(tData)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
			nX = ui:Append('WndCheckBox', {
				x = nX, y = nY,
				text = _L.TARGET[eType],
				checked = tData.tType[eType],
				onCheck = function()
					tData.tType[eType] = not tData.tType[eType]
					onChangeNotify(tData)
				end,
				autoEnable = function() return not tData.tType.bAll end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		end
		nX, nY = nPaddingX, nY + dY
	end
	-- 目标关系
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Target relation'] }):AutoWidth()
	nX, nY = nPaddingX + 10, nY + dY
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['All'],
		checked = tData.tRelation.bAll,
		onCheck = function()
			tData.tRelation.bAll = not tData.tRelation.bAll
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L.RELATION[szRelation],
			checked = tData.tRelation['b' .. szRelation],
			onCheck = function()
				tData.tRelation['b' .. szRelation] = not tData.tRelation['b' .. szRelation]
				onChangeNotify(tData)
			end,
			autoEnable = function() return not tData.tRelation.bAll end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	end
	nX, nY = nPaddingX, nY + dY
	-- 目标血量百分比
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Target life percentage'] }):AutoWidth()
	nX, nY = nPaddingX + 10, nY + dY
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Enable'],
		checked = tData.tLife.bEnable,
		onCheck = function()
			tData.tLife.bEnable = not tData.tLife.bEnable
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200,
		text = X.GetOperatorName(tData.tLife.szOperator or '=='),
		menu = function()
			local this = this
			return X.InsertOperatorMenu(
				{},
				tData.tLife.szOperator,
				function(szOp)
					tData.tLife.szOperator = szOp
					onChangeNotify(tData)
					X.UI(this):Text(X.GetOperatorName(szOp))
					X.UI.ClosePopupMenu()
				end
			)
		end,
		autoEnable = function() return tData.tLife.bEnable end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndEditBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = tData.tLife.nValue,
		onChange = function(szText)
			local nValue = tonumber(szText) or 0
			tData.tLife.nValue = nValue
			onChangeNotify(tData)
		end,
		autoEnable = function() return tData.tLife.bEnable end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX, nY = nPaddingX, nY + dY
	-- 最远距离
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Max distance'] }):AutoWidth()
	nX, nY = nPaddingX + 10, nY + dY
	nX = ui:Append('WndEditBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = tData.nMaxDistance,
		onChange = function(szText)
			local nValue = tonumber(szText) or 0
			tData.nMaxDistance = nValue
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX, nY = nPaddingX, nY + dY
	-- 名称显示
	ui:Append('Text', { x = nX, y = nY, color = {255, 255, 0}, text = _L['Name display'] }):AutoWidth()
	nX, nY = nPaddingX + 10, nY + dY
	nX = ui:Append('WndEditBox', {
		x = nX, y = nY, w = 200, h = 25,
		text = tData.szDisplay,
		onChange = function(szText)
			tData.szDisplay = szText
			onChangeNotify(tData)
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX, nY = nPaddingX, nY + dY

	nY = nY + 20
	ui:Append('WndButton', {
		x = (W - 100) / 2, y = nY, w = 100,
		text = _L['Delete'], color = { 255, 0, 0 },
		buttonStyle = 'FLAT',
		onClick = function()
			X.Confirm(_L['Sure to delete?'], function()
				onChangeNotify()
				ui:Remove()
			end)
		end,
	})
	nX, nY = nPaddingX, nY + dY

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
						local rule = X.Clone(p)
						rule.szMethod = 'TEMPLATE_ID'
						rule.szPattern = tostring(data.dwID)
						rule.tType = {
							bAll = false,
							[TARGET.NPC] = false,
							[TARGET.PLAYER] = false,
							[TARGET.DOODAD] = false,
						}
						rule.tType[ds.dwType] = true
						table.insert(aFocus, D.FormatAutoFocusData(rule))
					end
				end
			end
		end
		TEAMMON_FOCUS = aFocus
		D.RescanNearby()
	end
end
local function onTeamMonUpdate()
	if arg0 and not arg0['NPC'] and not arg0['DOODAD'] then
		return
	end
	UpdateTeamMonData()
end
X.RegisterEvent('MY_TEAM_MON_DATA_RELOAD', 'MY_Focus', onTeamMonUpdate)
end

do
local function onMenu()
	local dwType, dwID = X.GetClientPlayer().GetTarget()
	return D.GetTargetMenu(dwType, dwID)
end
X.RegisterTargetAddonMenu('MY_Focus', onMenu)
end

do
local function onHotKey()
	local me = X.GetClientPlayer()
	local dwType, dwID = X.GetCharacterTarget(me)
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
	X.SetClientPlayerTarget(t.dwType, t.dwID)
end
X.RegisterHotKey('MY_Focus_LoopTarget', _L['Loop target in focus'], onHotKey)
end

X.RegisterTutorial({
	szKey = 'MY_Focus',
	szMessage = _L['Would you like to use MY focus?'],
	fnRequire = function() return not O.bEnable end,
	{
		szOption = _L['Use'],
		bDefault = true,
		fnAction = function()
			O.bEnable = true
			MY_FocusUI.Open()
			X.Panel.RedrawTab('MY_Focus')
		end,
	},
	{
		szOption = _L['Not use'],
		fnAction = function()
			O.bEnable = false
			MY_FocusUI.Close()
			X.Panel.RedrawTab('MY_Focus')
		end,
	},
})

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
				'bFocusPlayerRemark',
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
				'bFocusPlayerRemark',
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
				bFocusPlayerRemark = D.OnConfigChange,
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
MY_Focus = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

-- 初始化需要等待 MY_FocusUI 加载完成
X.RegisterUserSettingsInit('MY_Focus', function()
	D.bReady = true
	D.LoadConfig()
	D.RescanNearby()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
