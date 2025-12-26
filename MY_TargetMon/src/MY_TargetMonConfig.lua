--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMonConfig'
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_TargetMon', { ['*'] = false, exp = false })
X.RegisterRestriction('MY_TargetMon.MapRestriction', { ['*'] = true })
--------------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_TargetMon', _L['Target'], {
	bCommon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetMon'],
		szDescription = X.MakeCaption({
			_L['Use common data'],
		}),
		szRestriction = 'MY_TargetMon',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nInterval = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetMon'],
		szDescription = X.MakeCaption({
			_L['View render interval'],
		}),
		szRestriction = 'MY_TargetMon',
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
})
local D = {
	CONFIG = {},
	DATASET_LIST = {},
}
local REMOTE_DATA_ROOT = X.FormatPath({'userdata/target_mon/remote/', X.PATH_TYPE.GLOBAL})
local DEFAULT_CONTENT_COLOR = {255, 255, 0}
local DEFAULT_MONITOR_ICON_ID = 572
local MY_TARGET_MON_MAP_TYPE = {
	COMMON          =  -1, -- 通用
	CITY            =  -2, -- 主城
	DUNGEON         =  -3, -- 秘境
	TEAM_DUNGEON    =  -4, -- 小队秘境
	RAID_DUNGEON    =  -5, -- 团队秘境
	STARVE          =  -6, -- 浪客行
	VILLAGE         =  -7, -- 野外
	ARENA           =  -8, -- 名剑大会
	BATTLEFIELD     = -10, -- 战场
	PUBG            = -11, -- 绝境战场
	ZOMBIE          = -12, -- 李渡鬼域
	MONSTER         = -13, -- 百战
	MOBA            = -14, -- 列星虚境
	HOMELAND        = -15, -- 家园
	ROGUELIKE       = -16, -- 八荒衡鉴
	COMPETITION     = -17, -- 竞技
	GUILD_TERRITORY = -18, -- 帮会领地
	CAMP            = -19, -- 阵营地图
	RECYCLE_BIN     =  -9, -- 回收站
}
local MY_TARGET_MON_MAP_TYPE_NAME = {
	[MY_TARGET_MON_MAP_TYPE.COMMON         ] = _L['Common map'],
	[MY_TARGET_MON_MAP_TYPE.CITY           ] = _L['City map'],
	[MY_TARGET_MON_MAP_TYPE.DUNGEON        ] = _L['Dungeon map'],
	[MY_TARGET_MON_MAP_TYPE.TEAM_DUNGEON   ] = _L['Team dungeon map'],
	[MY_TARGET_MON_MAP_TYPE.RAID_DUNGEON   ] = _L['Raid dungeon map'],
	[MY_TARGET_MON_MAP_TYPE.STARVE         ] = _L['Starve map'],
	[MY_TARGET_MON_MAP_TYPE.VILLAGE        ] = _L['Village map'],
	[MY_TARGET_MON_MAP_TYPE.ARENA          ] = _L['Arena map'],
	[MY_TARGET_MON_MAP_TYPE.BATTLEFIELD    ] = _L['Battlefield map'],
	[MY_TARGET_MON_MAP_TYPE.PUBG           ] = _L['Pubg map'],
	[MY_TARGET_MON_MAP_TYPE.ZOMBIE         ] = _L['Zombie map'],
	[MY_TARGET_MON_MAP_TYPE.MONSTER        ] = _L['Monster map'],
	[MY_TARGET_MON_MAP_TYPE.MOBA           ] = _L['Moba map'],
	[MY_TARGET_MON_MAP_TYPE.HOMELAND       ] = _L['Homeland map'],
	[MY_TARGET_MON_MAP_TYPE.GUILD_TERRITORY] = _L['Guild territory map'],
	[MY_TARGET_MON_MAP_TYPE.ROGUELIKE      ] = _L['Roguelike map'],
	[MY_TARGET_MON_MAP_TYPE.COMPETITION    ] = _L['Competition map'],
	[MY_TARGET_MON_MAP_TYPE.CAMP           ] = _L['Camp map'],
	[MY_TARGET_MON_MAP_TYPE.RECYCLE_BIN    ] = _L['Recycle bin map'],
}

local function GetUserDataPath()
	local ePathType = O.bCommon and X.PATH_TYPE.GLOBAL or X.PATH_TYPE.ROLE
	local szPath = X.FormatPath({'userdata/target_mon/local.jx3dat', ePathType})
	X.OutputDebugMessage('[MY_TargetMon] Data path: ' .. szPath, X.DEBUG_LEVEL.LOG)
	return szPath
end

function D.GetDatasetTitle(dataset)
	local szTitle = dataset.szTitle
	if dataset.szAuthor and dataset.szAuthor ~= '' then
		szTitle = g_tStrings.STR_BRACKET_LEFT .. dataset.szAuthor .. g_tStrings.STR_BRACKET_RIGHT .. szTitle
	end
	if dataset.szVersion and dataset.szVersion ~= '' then
		szTitle = szTitle .. g_tStrings.STR_CONNECT .. dataset.szVersion
	end
	return szTitle
end

function D.AncientPatchToDataset(patch, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH)
	-- 处理用户删除的内建数据和不合法的数据
	if patch.delete or not patch.uuid then
		return
	end
	-- 合并未修改的内嵌数据
	local embedded, config = EMBEDDED_CONFIG_HASH[patch.uuid], {}
	if embedded then
		-- 设置内嵌数据默认属性
		for k, v in pairs(embedded) do
			if k ~= 'monitors' then
				if patch[k] == nil then
					config[k] = X.Clone(v)
				end
			end
		end
		-- 设置改变过的数据
		for k, v in pairs(patch) do
			if k ~= 'monitors' then
				config[k] = X.Clone(v)
			end
		end
		-- 设置监控项内嵌数据删除项和自定义项
		local monitors = {}
		local existMon = {}
		if patch.monitors then
			for i, mon in ipairs(patch.monitors) do
				if not mon.delete then
					local monEmbedded = EMBEDDED_MONITOR_HASH[patch.uuid][mon.uuid]
					if monEmbedded then -- 复制内嵌数据
						if mon.patch then
							table.insert(monitors, X.ApplyPatch(monEmbedded, mon.patch))
						else
							table.insert(monitors, X.Clone(monEmbedded))
						end
					elseif not mon.embedded and not mon.patch and mon.manually ~= false then -- 删除当前版本不存在的内嵌数据
						table.insert(monitors, X.Clone(mon))
					end
				end
				existMon[mon.uuid] = true
			end
		end
		-- 插入新的内嵌数据
		for i, monEmbedded in ipairs(embedded.monitors) do
			if not existMon[monEmbedded.uuid] then
				local prevUuid, nIndex = monitors[i - 1] and monitors[i - 1].uuid, nil
				if prevUuid then
					for j, mon in ipairs(monitors) do
						if mon.uuid == prevUuid then
							nIndex = j + 1
							break
						end
					end
				end
				if nIndex then
					table.insert(monitors, nIndex, X.Clone(monEmbedded))
				else
					table.insert(monitors, X.Clone(monEmbedded))
				end
				existMon[monEmbedded.uuid] = true
			end
		end
		config.monitors = monitors
		config.group = embedded.group
		config.caption = embedded.caption
		config.embedded = true
	else
		-- 不再存在的内嵌数据
		if patch.embedded then
			return
		end
		for k, v in pairs(patch) do
			config[k] = X.Clone(v)
		end
	end
	return config
end

function D.ConvertAncientDataset(dataset)
	local tRecord = {
		szUUID = dataset.uuid,
		szTitle = dataset.caption,
		szAuthor = dataset.group,
		szVersion = '',
		szType = dataset.type,
		szTarget = dataset.target,
		szAlignment = dataset.alignment,

		bEnable = dataset.enable,
		bHideOthers = dataset.hideOthers,
		bHideVoid = dataset.hideVoid,
		bPenetrable = dataset.penetrable,
		bDraggable = dataset.draggable,
		bIgnoreSystemUIScale = dataset.ignoreSystemUIScale,
		bCdCircle = dataset.cdCircle,
		bCdFlash = dataset.cdFlash,
		bCdReadySpark = dataset.cdReadySpark,
		bCdBar = dataset.cdBar,
		bShowName = dataset.showName,
		bShowTime = dataset.showTime,
		bPlaySound = dataset.playSound,
		szBoxBgUITex = dataset.boxBgUITex,
		szCdBarUITex = dataset.cdBarUITex,

		nMaxLineCount = dataset.maxLineCount,
		fScale = dataset.scale,
		fIconFontScale = dataset.iconFontScale,
		fOtherFontScale = dataset.otherFontScale,
		nCdBarWidth = dataset.cdBarWidth,
		nDecimalTime = dataset.decimalTime,

		tAnchor = dataset.anchor,
		aMonitor = {},
	}
	local DEFAULT_IDS = {[0] = { ignoreLevel = true }}
	local DEFAULT_LEVELS = {[0] = {}}
	for _, mon in ipairs(dataset.monitors) do
		for id, idConfig in pairs(X.IsEmpty(mon.ids) and DEFAULT_IDS or mon.ids) do
			local tMap = X.Clone(mon.maps) or {}
			tMap.bAll = tMap.all or X.IsEmpty(tMap)
			tMap.all = nil
			local tKungfu = X.Clone(mon.kungfus) or {}
			tKungfu.bAll = tKungfu.all or X.IsEmpty(tKungfu)
			tKungfu.all = nil
			local tTargetKungfu = X.Clone(mon.tarkungfus) or {}
			tTargetKungfu.bAll = tTargetKungfu.all or X.IsEmpty(tTargetKungfu)
			tTargetKungfu.all = nil
			tTargetKungfu.bNpc = tTargetKungfu.npc
			tTargetKungfu.npc = nil
			for level, levelConfig in pairs(X.IsEmpty(idConfig.levels) and DEFAULT_LEVELS or idConfig.levels) do
				local szContent, aContentColor = '', nil
				if dataset.cdBar then
					if X.IsEmpty(mon.longAlias) then
						szContent = mon.shortAlias
					else
						szContent = mon.longAlias
					end
					if X.IsEmpty(mon.rgbLongAlias) or X.IsEquals(mon.rgbLongAlias, DEFAULT_CONTENT_COLOR) then
						aContentColor = mon.rgbShortAlias
					else
						aContentColor = mon.rgbLongAlias
					end
				else
					if X.IsEmpty(mon.shortAlias) then
						szContent = mon.longAlias
					else
						szContent = mon.shortAlias
					end
					if X.IsEmpty(mon.rgbShortAlias) or X.IsEquals(mon.rgbShortAlias, DEFAULT_CONTENT_COLOR) then
						aContentColor = mon.rgbLongAlias
					else
						aContentColor = mon.rgbShortAlias
					end
				end
				local nIconID
				if levelConfig.iconid and levelConfig.iconid > 0 then
					nIconID = levelConfig.iconid
				elseif idConfig.iconid and idConfig.iconid > 0 then
					nIconID = idConfig.iconid
				elseif mon.iconid and mon.iconid > 0 then
					nIconID = mon.iconid
				end
				table.insert(tRecord.aMonitor, X.Clone({
					szUUID = mon.uuid .. '-' .. id .. '-' .. level,
					szGroupID = mon.uuid,
					bEnable = mon.enable and (idConfig.ignoreLevel or levelConfig.enable),
					dwID = id,
					nLevel = level,
					nStackNum = 0,
					szNote = mon.name,
					szContent = szContent,
					aContentColor = aContentColor,
					nIconID = nIconID,
					tMap = tMap,
					tKungfu = tKungfu,
					tTargetKungfu = tTargetKungfu,
					bFlipHideVoid = mon.rHideVoid,
					bFlipHideOthers = mon.rHideOthers,
					aSoundAppear = idConfig.soundAppear or mon.soundAppear,
					aSoundDisappear = idConfig.soundDisappear or mon.soundDisappear,
					szExtentAnimate = mon.extentAnimate,
				}))
			end
		end
	end
	return tRecord
end

function D.HasAncientData()
	local szPath = X.FormatPath({'config/my_targetmon.jx3dat', X.PATH_TYPE.ROLE})
	return IsLocalFileExist(szPath)
end

function D.ImportAncientData(fnCallback)
	-- 加载内置数据
	local CUSTOM_EMBEDDED_CONFIG_ROOT = X.FormatPath({'userdata/TargetMon/', X.PATH_TYPE.GLOBAL})
	local EMBEDDED_CONFIG_LIST = {}
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_EMBEDDED_CONFIG_ROOT) or {}) do
		local dataset = X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW_E'] .. 'MY') })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = string.char(0xd3, 0x62, 0x5, 0x0, 0x0, 0x0, 0x0, 0xd3, 0x68, 0xfa, 0x20, 0xa6, 0xd0, 0xf4, 0x40, 0x79, 0x38, 0xee, 0x60, 0x4c, 0xa0, 0xe8, 0x80, 0x1f, 0x8, 0xe2, 0xa0, 0xf2, 0x70, 0xdc, 0xc0, 0xc5, 0xd8, 0xd6, 0xe0, 0x98, 0x40, 0xd0, 0x0, 0x6b, 0xa8, 0xca, 0x20, 0x3e, 0x10, 0xc4, 0x40, 0x11, 0x78, 0xbe, 0x60, 0xe4, 0xe0, 0xb8, 0x80, 0xb7, 0x48, 0xb2, 0xa0, 0x8a, 0xb0, 0xac, 0xc0, 0x5d, 0x18, 0xa6, 0xe0, 0x30, 0x80, 0xa0, 0x0, 0x3, 0xe8, 0x9a, 0x20, 0xd6, 0x50, 0x94, 0x40, 0xa9, 0xb8, 0x8e, 0x60, 0x7c, 0x20, 0x88, 0x80, 0x4f, 0x88, 0x82, 0xa0, 0x22, 0xf0, 0x7c, 0xc0, 0xf5, 0x58, 0x76, 0xe0, 0xc8, 0xc0, 0x70, 0x0, 0x9b, 0x28, 0x6a, 0x20, 0x6e, 0x90, 0x64, 0x40, 0x41, 0xf8, 0x5e, 0x60, 0x14, 0x60, 0x58, 0x80, 0xe7, 0xc8, 0x52, 0xa0, 0xba, 0x30, 0x4c, 0xc0, 0x8d, 0x98, 0x46, 0xe0, 0x60, 0x0, 0x40, 0x0, 0x33, 0x68, 0x3a, 0x20, 0x6, 0xd0, 0x34, 0x40, 0xd9, 0x38, 0x2e, 0x60, 0xac, 0xa0, 0x28, 0x80, 0x7f, 0x8, 0x22, 0xa0, 0x52, 0x70, 0x1c, 0xc0, 0x25, 0xd8, 0x16, 0xe0, 0xf8, 0x40, 0x10, 0x0, 0xcb, 0xa8, 0xa, 0x20, 0x9e, 0x10, 0x4, 0x40, 0x71, 0x78, 0xfe, 0x60, 0x44, 0xe0, 0xf8, 0x80, 0x17, 0x48, 0xf2, 0xa0, 0xea, 0xb0, 0xec, 0xc0, 0xbd, 0x18, 0xe6, 0xe0, 0x90, 0x80, 0xe0, 0x0, 0x63, 0xe8, 0xda, 0x20, 0x36, 0x50, 0xd4, 0x40) })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile)
		if X.IsTable(dataset) and dataset.uuid and szFile:sub(1, -#'.jx3dat' - 1) == dataset.uuid and dataset.group and dataset.sort and dataset.monitors then
			table.insert(EMBEDDED_CONFIG_LIST, dataset)
		end
	end
	table.sort(EMBEDDED_CONFIG_LIST, function(a, b)
		if a.group == b.group then
			return b.sort > a.sort
		end
		return b.group > a.group
	end)
	local EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = {}, {}
	for _, dataset in ipairs(EMBEDDED_CONFIG_LIST) do
		local embedded = dataset
		if embedded then
			local tMon = {}
			for _, mon in ipairs(embedded.monitors) do
				tMon[mon.uuid] = mon
			end
			-- 插入结果集
			EMBEDDED_CONFIG_HASH[embedded.uuid] = embedded
			EMBEDDED_MONITOR_HASH[embedded.uuid] = tMon
		end
	end
	-- 加载角色数据
	local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', X.PATH_TYPE.ROLE}
	local aPatch = X.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW'] .. 'MY') })
		or X.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = string.char(0xd5, 0xa6, 0xd, 0x0, 0x0, 0x0, 0x0, 0xf7, 0x48, 0x32, 0xa0, 0xee, 0x90, 0x64, 0x40, 0xe5, 0xd8, 0x96, 0xe0, 0xdc, 0x20, 0xc8, 0x80, 0xd3, 0x68, 0xfa, 0x20, 0xca, 0xb0, 0x2c, 0xc0, 0xc1, 0xf8, 0x5e, 0x60, 0xb8, 0x40, 0x90, 0x0, 0xaf, 0x88, 0xc2, 0xa0, 0xa6, 0xd0, 0xf4, 0x40, 0x9d, 0x18, 0x26, 0xe0, 0x94, 0x60, 0x58, 0x80, 0x8b, 0xa8, 0x8a, 0x20, 0x82, 0xf0, 0xbc, 0xc0, 0x79, 0x38, 0xee, 0x60, 0x70, 0x80, 0x20, 0x0, 0x67, 0xc8, 0x52, 0xa0, 0x5e, 0x10, 0x84, 0x40, 0x55, 0x58, 0xb6, 0xe0, 0x4c, 0xa0, 0xe8, 0x80, 0x43, 0xe8, 0x1a, 0x20, 0x3a, 0x30, 0x4c, 0xc0, 0x31, 0x78, 0x7e, 0x60, 0x28, 0xc0, 0xb0, 0x0, 0x1f, 0x8, 0xe2, 0xa0, 0x16, 0x50, 0x14, 0x40, 0xd, 0x98, 0x46, 0xe0, 0x4, 0xe0, 0x78, 0x80, 0xfb, 0x28, 0xaa, 0x20, 0xf2, 0x70, 0xdc, 0xc0, 0xe9, 0xb8, 0xe, 0x60, 0xe0, 0x0, 0x40, 0x0, 0xd7, 0x48, 0x72, 0xa0, 0xce, 0x90, 0xa4, 0x40, 0xc5, 0xd8, 0xd6, 0xe0, 0xbc, 0x20, 0x8, 0x80, 0xb3, 0x68, 0x3a, 0x20, 0xaa, 0xb0, 0x6c, 0xc0, 0xa1, 0xf8, 0x9e, 0x60, 0x98, 0x40, 0xd0, 0x0, 0x8f, 0x88, 0x2, 0xa0, 0x86, 0xd0, 0x34, 0x40, 0x7d, 0x18, 0x66, 0xe0, 0x74, 0x60, 0x98, 0x80, 0x6b, 0xa8, 0xca, 0x20, 0x62, 0xf0, 0xfc, 0xc0, 0x59, 0x38, 0x2e, 0x60, 0x50, 0x80, 0x60, 0x0, 0x47, 0xc8, 0x92, 0xa0, 0x3e, 0x10, 0xc4, 0x40) })
		or X.LoadLUAData(ROLE_CONFIG_FILE)
		or {}
	local aDataset, tLoaded = {}, {}
	for i, patch in ipairs(aPatch) do
		if patch.uuid and not tLoaded[patch.uuid] then
			local dataset = D.AncientPatchToDataset(patch, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH)
			if dataset then
				table.insert(aDataset, dataset)
			end
			tLoaded[patch.uuid] = true
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if embedded.uuid and not tLoaded[embedded.uuid] then
			local dataset = X.Clone(embedded)
			if dataset then
				dataset.embedded = true
				table.insert(aDataset, dataset)
			end
			tLoaded[dataset.uuid] = true
		end
	end
	-- 转换数据
	local aResult = {}
	for i, dataset in ipairs(aDataset) do
		table.insert(aResult, D.ConvertAncientDataset(dataset))
	end
	-- 导入数据
	for _, dataset in ipairs(aResult) do
		local bExist = false
		for i, v in ipairs(D.DATASET_LIST) do
			if v.szUUID == dataset.szUUID then
				v.aMonitor = dataset.aMonitor
				v.szTitle = dataset.szTitle
				v.szAuthor = dataset.szAuthor
				v.szVersion = dataset.szVersion
				bExist = true
			end
		end
		if not bExist then
			table.insert(D.DATASET_LIST, dataset)
		end
	end
	FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_RELOAD')
	if fnCallback then
		fnCallback(aResult)
	end
end

-- 保存用户监控数据、配置
function D.SaveUserData()
	X.SaveLUAData(
		GetUserDataPath(),
		{
			config = D.CONFIG,
			data = D.DATASET_LIST,
		})
end

-- 加载用户监控数据、配置
function D.LoadUserData()
	local data = X.LoadLUAData(GetUserDataPath())
	if X.IsTable(data) then
		D.CONFIG = data.config or {}
		D.DATASET_LIST = data.data or {}
		FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_RELOAD')
	else
		D.ImportAncientData()
	end
end

function D.SetUserConfig(szKey, xVal)
	D.CONFIG[szKey] = xVal
	FireUIEvent('MY_TARGET_MON_CONFIG__USER_CONFIG_MODIFY')
end

function D.GetUserConfig(szKey)
	return D.CONFIG[szKey]
end

function D.ImportDatasetFile(szFile, tOption)
	local aDataset = X.LoadLUAData(szFile, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW'] .. 'MY') })
		or X.LoadLUAData(szFile, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW_E'] .. 'MY') })
		or X.LoadLUAData(szFile, { passphrase = false })
	if not X.IsArray(aDataset) then
		X.OutputSystemMessage(_L['MY_TargetMon'], _L('Load dataset failed: %s', tostring(szFile)), X.CONSTANT.MSG_THEME.ERROR)
		return
	end
	for i, dataset in ipairs(aDataset) do
		if dataset.uuid then
			aDataset[i] = D.ConvertAncientDataset(dataset)
		end
	end
	if #aDataset == 0 then
		return
	end
	local tUUID = {}
	if tOption and tOption.aUUID then
		for _, szUUID in ipairs(tOption.aUUID) do
			tUUID[szUUID] = true
		end
	else
		for _, dataset in ipairs(aDataset) do
			tUUID[dataset.szUUID] = true
		end
	end
	local function fnAction()
		for _, dataset in ipairs(aDataset) do
			if tUUID[dataset.szUUID] then
				local bExist = false
				for i, v in ipairs(D.DATASET_LIST) do
					if v.szUUID == dataset.szUUID then
						v.tMap = dataset.tMap
						v.aMonitor = dataset.aMonitor
						v.szTitle = dataset.szTitle
						v.szAuthor = dataset.szAuthor
						v.szVersion = dataset.szVersion
						bExist = true
					end
				end
				if not bExist then
					table.insert(D.DATASET_LIST, dataset)
				end
			end
		end
		FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		X.OutputSystemMessage(_L['MY_TargetMon'], _L('Load dataset success: %s', tostring(szFile)), X.CONSTANT.MSG_THEME.SUCCESS)
		if tOption and tOption.fnCallback then
			local aImported = {}
			for _, dataset in ipairs(aDataset) do
				if tUUID[dataset.szUUID] then
					table.insert(aImported, dataset)
				end
			end
			tOption.fnCallback(aImported)
		end
	end
	if tOption and tOption.bConfirmed then
		fnAction()
	else
		local nHeight = 50
		local ui = X.UI.CreateFrame('MY_TargetMon_ImportConfirm', {
			w = 460, close = true,
			text = _L['Are you sure to import datasets below?'],
		})
		for _, dataset in ipairs(aDataset) do
			ui:Append('WndCheckBox', {
				x = 30, y = nHeight, w = 400,
				text = MY_TargetMonConfig.GetDatasetTitle(dataset),
				checked = tUUID[dataset.szUUID],
				onCheck = function(bChecked)
					tUUID[dataset.szUUID] = bChecked
				end,
			})
			nHeight = nHeight + 30
		end
		nHeight = nHeight + 10
		ui:Append('WndButton', {
			x = 180, y = nHeight, w = 100, h = 40,
			text = _L['Confirm Import'],
			buttonStyle = 'FLAT',
			onClick = function()
				fnAction()
				ui:Remove()
			end,
		})
		nHeight = nHeight + 40
		ui:Height(nHeight + 30)
	end
end

function D.ExportDatasetFile(aUUID, bIndent)
	local tDataset = {}
	for _, dataset in ipairs(D.DATASET_LIST) do
		tDataset[dataset.szUUID] = dataset
	end
	local aExport = {}
	for _, szUUID in ipairs(aUUID) do
		table.insert(aExport, tDataset[szUUID])
	end
	if #aExport == 0 then
		X.OutputAnnounceMessage(_L['Please select at least one dataset to export'])
		return
	end
	local szFile = X.FormatPath(
		REMOTE_DATA_ROOT
			.. '{$name}@{$server}@'
			.. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd_%hh%mm%ss')
			.. '.{$lang}.jx3dat'
	)
	if bIndent then
		X.SaveLUAData(szFile, aExport, {
			encoder = 'luatext',
			indent = '\t',
			passphrase = false,
			crc = false,
		})
	else
		X.SaveLUAData(szFile, aExport, {
			passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW'] .. 'MY'),
		})
	end
	X.Alert(_L('Export dataset success: %s', tostring(szFile)))
	X.OutputSystemMessage(_L['MY_TargetMon'], _L('Export dataset success: %s', tostring(szFile)), X.CONSTANT.MSG_THEME.SUCCESS)
	return true
end

function D.SetDatasetList(aList)
	D.DATASET_LIST = aList
end

function D.GetDatasetList()
	return D.DATASET_LIST
end

function D.GetDataset(szUUID)
	for i, v in ipairs(D.DATASET_LIST) do
		if v.szUUID == szUUID then
			return v
		end
	end
end

function D.CreateDataset()
	table.insert(D.DATASET_LIST, {
		szUUID = X.GetUUID(),
		szTitle = _L['New target mon dataset'] .. '#' .. (#D.DATASET_LIST + 1),
		szAuthor = X.GetClientPlayerName(),
		szVersion = X.FormatTime(GetCurrentTime(), '%yyyy/%MM/%dd'),
		szType = 'BUFF',
		szTarget = 'CLIENT_PLAYER',
		szAlignment = 'LEFT',

		bEnable = true,
		tMap = nil,
		bHideOthers = false,
		bHideVoid = false,
		bPenetrable = false,
		bDraggable = false,
		bIgnoreSystemUIScale = false,
		bCdCircle = true,
		bCdFlash = true,
		bCdReadySpark = true,
		bCdBar = false,
		bShowName = true,
		bShowTime = true,
		bPlaySound = true,
		szBoxBgUITex = '',
		szCdBarUITex = '/ui/Image/Common/Money.UITex|208',

		nMaxLineCount = 16,
		fScale = 0.7,
		fIconFontScale = 1,
		fOtherFontScale = 1,
		nCdBarWidth = 240,
		nDecimalTime = 1,

		tAnchor = { y = 152, x = -343, s = 'TOPLEFT', r = 'CENTER' },
		aMonitor = {},
	})
	FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
end

function D.DeleteDataset(szUUID)
	for i, v in ipairs(D.DATASET_LIST) do
		if v.szUUID == szUUID then
			table.remove(D.DATASET_LIST, i)
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
			return
		end
	end
end

function D.DeleteAllDataset()
	for i, _ in X.ipairs_r(D.DATASET_LIST) do
		table.remove(D.DATASET_LIST, i)
	end
	FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
end

function D.CreateMonitor(szUUID, nIndex, dwID, nLevel)
	local dataset = D.GetDataset(szUUID)
	if not dataset then
		return
	end
	if not nIndex then
		nIndex = #dataset.aMonitor + 1
	end
	local szNote, nIconID = '', nil
	if dataset.szType == 'BUFF' then
		szNote = X.GetBuffName(dwID, nLevel == 0 and 1 or nLevel) or ''
		nIconID = X.GetBuffIconID(dwID, nLevel == 0 and 1 or nLevel)
	elseif dataset.szType == 'SKILL' then
		szNote = X.GetSkillName(dwID, nLevel) or ''
		nIconID = X.GetSkillIconID(dwID, nLevel)
	end
	table.insert(dataset.aMonitor, nIndex, {
		szUUID = X.GetUUID(),
		szGroupID = nil,
		bEnable = true,
		dwID = dwID,
		nLevel = nLevel,
		nStackNum = 0,
		nStackNumOp = nil,
		szNote = szNote,
		szContent = '',
		aContentColor = nil,
		nIconID = nIconID,
		tMap = nil,
		tKungfu = nil,
		tTargetKungfu = nil,
		bFlipHideVoid = nil,
		bFlipHideOthers = nil,
		aSoundAppear = nil,
		aSoundDisappear = nil,
		szExtentAnimate = nil,
	})
	FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', szUUID)
end

function D.SendBgMsg(...)
	return X.SendBgMsg(...)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMonConfig',
	exports = {
		{
			fields = {
				'bCommon',
				'nInterval',
			},
			root = O,
		},
		{
			fields = {
				REMOTE_DATA_ROOT = REMOTE_DATA_ROOT,
				DEFAULT_MONITOR_ICON_ID = DEFAULT_MONITOR_ICON_ID,
				MY_TARGET_MON_MAP_TYPE = MY_TARGET_MON_MAP_TYPE,
				MY_TARGET_MON_MAP_TYPE_NAME = MY_TARGET_MON_MAP_TYPE_NAME,
				HasAncientData = D.HasAncientData,
				ImportAncientData = D.ImportAncientData,
				ImportDatasetFile = D.ImportDatasetFile,
				ExportDatasetFile = D.ExportDatasetFile,
				SetUserConfig = D.SetUserConfig,
				GetUserConfig = D.GetUserConfig,
				GetDatasetTitle = D.GetDatasetTitle,
				GetDatasetList = D.GetDatasetList,
				GetDataset = D.GetDataset,
				CreateDataset = D.CreateDataset,
				DeleteDataset = D.DeleteDataset,
				DeleteAllDataset = D.DeleteAllDataset,
				CreateMonitor = D.CreateMonitor,
				SendBgMsg = D.SendBgMsg,
			},
		},
	},
	imports = {
		{
			fields = {
				'bCommon',
				'nInterval',
			},
			triggers = {
				bCommon = D.LoadUserData,
				nInterval = function() FireUIEvent('MY_TARGET_MON_CONFIG__INTERVAL_CHANGE') end,
			},
			root = O,
		},
	},
}
MY_TargetMonConfig = X.CreateModule(settings)
end

do
local function DelaySaveUserData()
	X.DelayCall('MY_TargetMon#SaveUserData', 500, D.SaveUserData)
end
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY', 'MY_TargetMonConfig', DelaySaveUserData)
X.RegisterEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', 'MY_TargetMonConfig', DelaySaveUserData)
X.RegisterEvent('MY_TARGET_MON_CONFIG__USER_CONFIG_MODIFY', 'MY_TargetMonConfig', DelaySaveUserData)
end

X.RegisterInit('MY_TargetMonConfig', D.LoadUserData)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
