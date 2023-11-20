--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMonConfig'
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_TargetMon', _L['Target'], {
	bCommon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TargetMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {
	CONFIG_LIST = {},
}

local function GetUserDataPath()
	local ePathType = O.bCommon and X.PATH_TYPE.GLOBAL or X.PATH_TYPE.ROLE
	local szPath = X.FormatPath({'userdata/target_mon/local.jx3dat', ePathType})
	X.Debug('[MY_TargetMon] Data path: ' .. szPath, X.DEBUG_LEVEL.LOG)
	return szPath
end

function D.GetConfigTitle(config)
	local szTitle = config.szTitle
	if config.szAuthor and config.szAuthor ~= '' then
		szTitle = g_tStrings.STR_BRACKET_LEFT .. config.szAuthor .. g_tStrings.STR_BRACKET_RIGHT .. szTitle
	end
	if config.szVersion and config.szVersion ~= '' then
		szTitle = szTitle .. g_tStrings.STR_CONNECT .. config.szVersion
	end
	return szTitle
end

function D.AncientPatchToConfig(patch, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH)
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

function D.ConvertAncientConfig(config)
	local tRecord = {
		szUUID = config.uuid,
		szTitle = config.caption,
		szAuthor = config.group,
		szVersion = '',
		szType = config.type,
		szTarget = config.target,
		szAlignment = config.alignment,

		bEnable = config.enable,
		bHideOthers = config.hideOthers,
		bHideVoid = config.hideVoid,
		bPenetrable = config.penetrable,
		bDraggable = config.draggable,
		bIgnoreSystemUIScale = config.ignoreSystemUIScale,
		bCdCircle = config.cdCircle,
		bCdFlash = config.cdFlash,
		bCdReadySpark = config.cdReadySpark,
		bCdBar = config.cdBar,
		bShowName = config.showName,
		bShowTime = config.showTime,
		bPlaySound = config.playSound,
		szBoxBgUITex = config.boxBgUITex,
		szCdBarUITex = config.cdBarUITex,

		nMaxLineCount = config.maxLineCount,
		fScale = config.scale,
		fIconFontScale = config.iconFontScale,
		fOtherFontScale = config.otherFontScale,
		nCdBarWidth = config.cdBarWidth,
		nDecimalTime = config.decimalTime,

		tAnchor = config.anchor,
		aMonitor = {},
	}
	local DEFAULT_IDS = {[0] = { ignoreLevel = true }}
	local DEFAULT_LEVELS = {[0] = {}}
	for _, mon in ipairs(config.monitors) do
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
				table.insert(tRecord.aMonitor, X.Clone({
					szUUID = mon.uuid .. '-' .. id .. '-' .. level,
					szGroupID = mon.uuid,
					bEnable = mon.enable and (idConfig.ignoreLevel or levelConfig.enable),
					dwID = id,
					nLevel = level,
					nStackNum = 0,
					szNote = mon.name,
					szContent = not X.IsEmpty(mon.longAlias) and mon.longAlias or mon.shortAlias,
					aContentColor = not X.IsEmpty(mon.rgbLongAlias) and mon.rgbLongAlias or mon.rgbShortAlias,
					nIconID = levelConfig.iconid or idConfig.iconid or mon.iconid,
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

function D.LoadAncientData()
	-- 加载内置数据
	local CUSTOM_EMBEDDED_CONFIG_ROOT = X.FormatPath({'userdata/TargetMon/', X.PATH_TYPE.GLOBAL})
	local EMBEDDED_CONFIG_LIST = {}
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_EMBEDDED_CONFIG_ROOT) or {}) do
		local config = X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW_E'] .. 'MY') })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = string.char(0xd3, 0x62, 0x5, 0x0, 0x0, 0x0, 0x0, 0xd3, 0x68, 0xfa, 0x20, 0xa6, 0xd0, 0xf4, 0x40, 0x79, 0x38, 0xee, 0x60, 0x4c, 0xa0, 0xe8, 0x80, 0x1f, 0x8, 0xe2, 0xa0, 0xf2, 0x70, 0xdc, 0xc0, 0xc5, 0xd8, 0xd6, 0xe0, 0x98, 0x40, 0xd0, 0x0, 0x6b, 0xa8, 0xca, 0x20, 0x3e, 0x10, 0xc4, 0x40, 0x11, 0x78, 0xbe, 0x60, 0xe4, 0xe0, 0xb8, 0x80, 0xb7, 0x48, 0xb2, 0xa0, 0x8a, 0xb0, 0xac, 0xc0, 0x5d, 0x18, 0xa6, 0xe0, 0x30, 0x80, 0xa0, 0x0, 0x3, 0xe8, 0x9a, 0x20, 0xd6, 0x50, 0x94, 0x40, 0xa9, 0xb8, 0x8e, 0x60, 0x7c, 0x20, 0x88, 0x80, 0x4f, 0x88, 0x82, 0xa0, 0x22, 0xf0, 0x7c, 0xc0, 0xf5, 0x58, 0x76, 0xe0, 0xc8, 0xc0, 0x70, 0x0, 0x9b, 0x28, 0x6a, 0x20, 0x6e, 0x90, 0x64, 0x40, 0x41, 0xf8, 0x5e, 0x60, 0x14, 0x60, 0x58, 0x80, 0xe7, 0xc8, 0x52, 0xa0, 0xba, 0x30, 0x4c, 0xc0, 0x8d, 0x98, 0x46, 0xe0, 0x60, 0x0, 0x40, 0x0, 0x33, 0x68, 0x3a, 0x20, 0x6, 0xd0, 0x34, 0x40, 0xd9, 0x38, 0x2e, 0x60, 0xac, 0xa0, 0x28, 0x80, 0x7f, 0x8, 0x22, 0xa0, 0x52, 0x70, 0x1c, 0xc0, 0x25, 0xd8, 0x16, 0xe0, 0xf8, 0x40, 0x10, 0x0, 0xcb, 0xa8, 0xa, 0x20, 0x9e, 0x10, 0x4, 0x40, 0x71, 0x78, 0xfe, 0x60, 0x44, 0xe0, 0xf8, 0x80, 0x17, 0x48, 0xf2, 0xa0, 0xea, 0xb0, 0xec, 0xc0, 0xbd, 0x18, 0xe6, 0xe0, 0x90, 0x80, 0xe0, 0x0, 0x63, 0xe8, 0xda, 0x20, 0x36, 0x50, 0xd4, 0x40) })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile)
		if X.IsTable(config) and config.uuid and szFile:sub(1, -#'.jx3dat' - 1) == config.uuid and config.group and config.sort and config.monitors then
			table.insert(EMBEDDED_CONFIG_LIST, config)
		end
	end
	table.sort(EMBEDDED_CONFIG_LIST, function(a, b)
		if a.group == b.group then
			return b.sort > a.sort
		end
		return b.group > a.group
	end)
	local EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = {}, {}
	for _, config in ipairs(EMBEDDED_CONFIG_LIST) do
		local embedded = config
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
	local aConfig, tLoaded = {}, {}
	for i, patch in ipairs(aPatch) do
		if patch.uuid and not tLoaded[patch.uuid] then
			local config = D.AncientPatchToConfig(patch, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH)
			if config then
				table.insert(aConfig, config)
			end
			tLoaded[patch.uuid] = true
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if embedded.uuid and not tLoaded[embedded.uuid] then
			local config = X.Clone(embedded)
			if config then
				config.embedded = true
				table.insert(aConfig, config)
			end
			tLoaded[config.uuid] = true
		end
	end
	-- 转换数据
	local aResult = {}
	for i, config in ipairs(aConfig) do
		table.insert(aResult, D.ConvertAncientConfig(config))
	end
	D.CONFIG_LIST = aResult
end

-- 保存用户监控数据、配置
function D.SaveUserData()
	X.SaveLUAData(
		GetUserDataPath(),
		{
			data = D.CONFIG_LIST,
		})
end

-- 加载用户监控数据、配置
function D.LoadUserData()
	local data = X.LoadLUAData(GetUserDataPath())
	if X.IsTable(data) then
		D.CONFIG_LIST = data.data or {}
	else
		D.CONFIG_LIST = {}
		D.LoadAncientData()
	end
	FireUIEvent('MY_TARGET_MON_CONFIG_RELOAD')
end

function D.ImportConfigFile(szFile)
	local aConfig = X.LoadLUAData(szFile, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW'] .. 'MY') })
		or X.LoadLUAData(szFile, { passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW_E'] .. 'MY') })
		or X.LoadLUAData(szFile, { passphrase = false })
	if not X.IsArray(aConfig) then
		X.Sysmsg(_L['MY_TargetMon'], _L('Load config failed: %s', tostring(szFile)), X.CONSTANT.MSG_THEME.ERROR)
		return
	end
	SaveLUAData('interface/a.jx3dat', aConfig, {crc = false,indent = '\t'})
	for i, config in ipairs(aConfig) do
		if config.uuid then
			aConfig[i] = D.ConvertAncientConfig(config)
		end
	end
	if #aConfig == 0 then
		return
	end
	local aTitle = {}
	for _, config in ipairs(aConfig) do
		table.insert(aTitle, D.GetConfigTitle(config))
	end
	X.Confirm(_L['Are you sure to import configs below?'] .. '\n\n' .. table.concat(aTitle, '\n'), function()
		for _, config in ipairs(aConfig) do
			local bExist = false
			for i, v in ipairs(D.CONFIG_LIST) do
				if v.szUUID == config.szUUID then
					v.aMonitor = config.aMonitor
					v.szTitle = config.szTitle
					v.szAuthor = config.szAuthor
					v.szVersion = config.szVersion
					bExist = true
				end
			end
			if not bExist then
				table.insert(D.CONFIG_LIST, config)
			end
		end
		FireUIEvent('MY_TARGET_MON_CONFIG_MODIFY')
		X.Sysmsg(_L['MY_TargetMon'], _L('Load config success: %s', tostring(szFile)), X.CONSTANT.MSG_THEME.SUCCESS)
	end)
end

function D.ExportConfigFile(aUUID, bIndent)
	local tConfig = {}
	for _, config in ipairs(D.CONFIG_LIST) do
		tConfig[config.szUUID] = config
	end
	local aExport = {}
	for _, szUUID in ipairs(aUUID) do
		table.insert(aExport, tConfig[szUUID])
	end
	if #aExport == 0 then
		X.Topmsg(_L['Please select at least one config to export'])
		return
	end
	local szFile = X.FormatPath({
		'userdata/target_mon/remote/'
			.. '{$name}@{$server}@'
			.. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd_%hh%mm%ss')
			.. '.{$lang}.jx3dat',
		X.PATH_TYPE.GLOBAL,
	})
	if bIndent then
		X.SaveLUAData(szFile, aExport, {
			indent = '\t',
			passphrase = false,
			crc = false,
		})
	else
		X.SaveLUAData(szFile, aExport, {
			passphrase = X.KE(X.SECRET['FILE::TARGET_MON_DATA_PW'] .. 'MY'),
		})
	end
	X.Alert(_L('Export config success: %s', tostring(szFile)))
	X.Sysmsg(_L['MY_TargetMon'], _L('Export config success: %s', tostring(szFile)), X.CONSTANT.MSG_THEME.SUCCESS)
	return true
end

function D.SetConfigList(aList)
	D.CONFIG_LIST = aList
end

function D.GetConfigList()
	return D.CONFIG_LIST
end

function D.GetConfig(szUUID)
	for i, v in ipairs(D.CONFIG_LIST) do
		if v.szUUID == szUUID then
			return v
		end
	end
end

function D.CreateConfig()
	table.insert(D.CONFIG_LIST, {
		szUUID = X.GetUUID(),
		szTitle = _L['New target mon config'] .. '#' .. (#D.CONFIG_LIST + 1),
		szAuthor = X.GetUserRoleName(),
		szVersion = X.FormatTime(GetCurrentTime(), '%yyyy/%MM/%dd'),
		szType = 'BUFF',
		szTarget = 'CLIENT_PLAYER',
		szAlignment = 'LEFT',

		bEnable = true,
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
	FireUIEvent('MY_TARGET_MON_CONFIG_MODIFY')
end

function D.DeleteConfig(szUUID)
	for i, v in ipairs(D.CONFIG_LIST) do
		if v.szUUID == szUUID then
			table.remove(D.CONFIG_LIST, i)
			FireUIEvent('MY_TARGET_MON_CONFIG_MODIFY')
			return
		end
	end
end

function D.CreateMonitor(szUUID, dwID, nLevel)
	local config = D.GetConfig(szUUID)
	if not config then
		return
	end
	table.insert(config.aMonitor, {
		szUUID = X.GetUUID(),
		szGroupID = nil,
		bEnable = true,
		dwID = dwID,
		nLevel = nLevel,
		nStackNum = 0,
		szNote = config.szType == 'BUFF' and (X.GetBuffName(dwID, nLevel == 0 and 1 or nLevel) or '') or (X.GetSkillName(dwID, nLevel) or ''),
		szContent = '',
		aContentColor = nil,
		nIconID = config.szType == 'BUFF' and (X.GetBuffIconID(dwID, nLevel == 0 and 1 or nLevel) or 13) or (X.GetSkillIconID(dwID, nLevel) or 13),
		tMap = nil,
		tKungfu = nil,
		tTargetKungfu = nil,
		bFlipHideVoid = nil,
		bFlipHideOthers = nil,
		aSoundAppear = nil,
		aSoundDisappear = nil,
		szExtentAnimate = nil,
	})
	FireUIEvent('MY_TARGET_MON_CONFIG_MONITOR_MODIFY')
end

-- Global exports
do
local settings = {
	name = 'MY_TargetMonConfig',
	exports = {
		{
			fields = {
				'bCommon',
			},
			root = O,
		},
		{
			fields = {
				ImportConfigFile = D.ImportConfigFile,
				ExportConfigFile = D.ExportConfigFile,
				GetConfigTitle = D.GetConfigTitle,
				GetConfigList = D.GetConfigList,
				GetConfig = D.GetConfig,
				CreateConfig = D.CreateConfig,
				DeleteConfig = D.DeleteConfig,
				CreateMonitor = D.CreateMonitor,
			},
		},
	},
	imports = {
		{
			fields = {
				'bCommon',
			},
			triggers = {
				bCommon = D.LoadUserData,
			},
			root = O,
		},
	},
}
MY_TargetMonConfig = X.CreateModule(settings)
end

do
local function DelaySaveConfig()
	X.DelayCall('MY_TargetMon#SaveConfig', 500, D.SaveUserData)
end
X.RegisterEvent('MY_TARGET_MON_CONFIG_MODIFY', 'MY_TargetMonConfig', DelaySaveConfig)
X.RegisterEvent('MY_TARGET_MON_CONFIG_MONITOR_MODIFY', 'MY_TargetMonConfig', DelaySaveConfig)
end

X.RegisterInit('MY_TargetMonConfig', D.LoadUserData)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
