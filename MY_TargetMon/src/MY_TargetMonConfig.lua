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

local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^12.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TargetMon', { ['*'] = false, classic = true })
X.RegisterRestriction('MY_TargetMon.ShieldedUUID', { ['*'] = true })
--------------------------------------------------------------------------
local LANG = X.ENVIRONMENT.GAME_LANG
local INIT_STATE = 'NONE'
local D = X.SetmetaLazyload({
	PASSPHRASE = string.char(0xd5, 0xa6, 0xd, 0x0, 0x0, 0x0, 0x0, 0xf7, 0x48, 0x32, 0xa0, 0xee, 0x90, 0x64, 0x40, 0xe5, 0xd8, 0x96, 0xe0, 0xdc, 0x20, 0xc8, 0x80, 0xd3, 0x68, 0xfa, 0x20, 0xca, 0xb0, 0x2c, 0xc0, 0xc1, 0xf8, 0x5e, 0x60, 0xb8, 0x40, 0x90, 0x0, 0xaf, 0x88, 0xc2, 0xa0, 0xa6, 0xd0, 0xf4, 0x40, 0x9d, 0x18, 0x26, 0xe0, 0x94, 0x60, 0x58, 0x80, 0x8b, 0xa8, 0x8a, 0x20, 0x82, 0xf0, 0xbc, 0xc0, 0x79, 0x38, 0xee, 0x60, 0x70, 0x80, 0x20, 0x0, 0x67, 0xc8, 0x52, 0xa0, 0x5e, 0x10, 0x84, 0x40, 0x55, 0x58, 0xb6, 0xe0, 0x4c, 0xa0, 0xe8, 0x80, 0x43, 0xe8, 0x1a, 0x20, 0x3a, 0x30, 0x4c, 0xc0, 0x31, 0x78, 0x7e, 0x60, 0x28, 0xc0, 0xb0, 0x0, 0x1f, 0x8, 0xe2, 0xa0, 0x16, 0x50, 0x14, 0x40, 0xd, 0x98, 0x46, 0xe0, 0x4, 0xe0, 0x78, 0x80, 0xfb, 0x28, 0xaa, 0x20, 0xf2, 0x70, 0xdc, 0xc0, 0xe9, 0xb8, 0xe, 0x60, 0xe0, 0x0, 0x40, 0x0, 0xd7, 0x48, 0x72, 0xa0, 0xce, 0x90, 0xa4, 0x40, 0xc5, 0xd8, 0xd6, 0xe0, 0xbc, 0x20, 0x8, 0x80, 0xb3, 0x68, 0x3a, 0x20, 0xaa, 0xb0, 0x6c, 0xc0, 0xa1, 0xf8, 0x9e, 0x60, 0x98, 0x40, 0xd0, 0x0, 0x8f, 0x88, 0x2, 0xa0, 0x86, 0xd0, 0x34, 0x40, 0x7d, 0x18, 0x66, 0xe0, 0x74, 0x60, 0x98, 0x80, 0x6b, 0xa8, 0xca, 0x20, 0x62, 0xf0, 0xfc, 0xc0, 0x59, 0x38, 0x2e, 0x60, 0x50, 0x80, 0x60, 0x0, 0x47, 0xc8, 0x92, 0xa0, 0x3e, 0x10, 0xc4, 0x40),
	PASSPHRASE_EMBEDDED = string.char(0xd3, 0x62, 0x5, 0x0, 0x0, 0x0, 0x0, 0xd3, 0x68, 0xfa, 0x20, 0xa6, 0xd0, 0xf4, 0x40, 0x79, 0x38, 0xee, 0x60, 0x4c, 0xa0, 0xe8, 0x80, 0x1f, 0x8, 0xe2, 0xa0, 0xf2, 0x70, 0xdc, 0xc0, 0xc5, 0xd8, 0xd6, 0xe0, 0x98, 0x40, 0xd0, 0x0, 0x6b, 0xa8, 0xca, 0x20, 0x3e, 0x10, 0xc4, 0x40, 0x11, 0x78, 0xbe, 0x60, 0xe4, 0xe0, 0xb8, 0x80, 0xb7, 0x48, 0xb2, 0xa0, 0x8a, 0xb0, 0xac, 0xc0, 0x5d, 0x18, 0xa6, 0xe0, 0x30, 0x80, 0xa0, 0x0, 0x3, 0xe8, 0x9a, 0x20, 0xd6, 0x50, 0x94, 0x40, 0xa9, 0xb8, 0x8e, 0x60, 0x7c, 0x20, 0x88, 0x80, 0x4f, 0x88, 0x82, 0xa0, 0x22, 0xf0, 0x7c, 0xc0, 0xf5, 0x58, 0x76, 0xe0, 0xc8, 0xc0, 0x70, 0x0, 0x9b, 0x28, 0x6a, 0x20, 0x6e, 0x90, 0x64, 0x40, 0x41, 0xf8, 0x5e, 0x60, 0x14, 0x60, 0x58, 0x80, 0xe7, 0xc8, 0x52, 0xa0, 0xba, 0x30, 0x4c, 0xc0, 0x8d, 0x98, 0x46, 0xe0, 0x60, 0x0, 0x40, 0x0, 0x33, 0x68, 0x3a, 0x20, 0x6, 0xd0, 0x34, 0x40, 0xd9, 0x38, 0x2e, 0x60, 0xac, 0xa0, 0x28, 0x80, 0x7f, 0x8, 0x22, 0xa0, 0x52, 0x70, 0x1c, 0xc0, 0x25, 0xd8, 0x16, 0xe0, 0xf8, 0x40, 0x10, 0x0, 0xcb, 0xa8, 0xa, 0x20, 0x9e, 0x10, 0x4, 0x40, 0x71, 0x78, 0xfe, 0x60, 0x44, 0xe0, 0xf8, 0x80, 0x17, 0x48, 0xf2, 0xa0, 0xea, 0xb0, 0xec, 0xc0, 0xbd, 0x18, 0xe6, 0xe0, 0x90, 0x80, 0xe0, 0x0, 0x63, 0xe8, 0xda, 0x20, 0x36, 0x50, 0xd4, 0x40),
},
{
	PW = function() return X.SECRET['FILE::TARGET_MON_DATA_PW'] end,
	PW_E = function() return X.SECRET['FILE::TARGET_MON_DATA_PW_E'] end,
})
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', X.PATH_TYPE.ROLE}
local CUSTOM_EMBEDDED_CONFIG_ROOT = X.FormatPath({'userdata/TargetMon/', X.PATH_TYPE.GLOBAL})
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', X.PATH_TYPE.GLOBAL}
local TARGET_TYPE_LIST = {
	'CLIENT_PLAYER'  ,
	'CONTROL_PLAYER' ,
	'TARGET'         ,
	'TTARGET'        ,
	'TEAM_MARK_CLOUD',
	'TEAM_MARK_SWORD',
	'TEAM_MARK_AX'   ,
	'TEAM_MARK_HOOK' ,
	'TEAM_MARK_DRUM' ,
	'TEAM_MARK_SHEAR',
	'TEAM_MARK_STICK',
	'TEAM_MARK_JADE' ,
	'TEAM_MARK_DART' ,
	'TEAM_MARK_FAN'  ,
}
local CONFIG, CONFIG_CHANGED, CONFIG_BUFF_TARGET_LIST, CONFIG_SKILL_TARGET_LIST
local CONFIG_TEMPLATE = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MY_TargetMon/data/template/{$lang}.jx3dat')
local MON_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__
local MONID_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__
local MONLEVEL_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__.levels.__CHILD_TEMPLATE__
local EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = {}, {}, {}

function D.GetTargetTypeList(szType)
	if szType == 'BUFF' then
		return CONFIG_BUFF_TARGET_LIST
	end
	if szType == 'SKILL' then
		return CONFIG_SKILL_TARGET_LIST
	end
	return TARGET_TYPE_LIST
end

function D.GeneUUID()
	return X.GetUUID():gsub('-', '')
end

function D.GetConfigCaption(config)
	local szCaption = config.caption
	if config.group ~= '' then
		szCaption = g_tStrings.STR_BRACKET_LEFT .. config.group .. g_tStrings.STR_BRACKET_RIGHT .. szCaption
	end
	return szCaption
end

-- 格式化监控项数据
function D.FormatConfig(config, bCoroutine)
	return X.FormatDataStructure(config, CONFIG_TEMPLATE, nil, nil, bCoroutine)
end

function D.LoadEmbeddedConfig(bCoroutine)
	if not X.IsString(D.PW) or not X.IsString(D.PW_E) then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_TargetMonConfig', 'Passphrase cannot be empty!', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	-- 加载内置数据
	local aConfig = {}
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_EMBEDDED_CONFIG_ROOT) or {}) do
		local config = X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = D.PW_E })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = D.PASSPHRASE_EMBEDDED })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile)
		if X.IsTable(config) and config.uuid and szFile:sub(1, -#'.jx3dat' - 1) == config.uuid and config.group and config.sort and config.monitors then
			table.insert(aConfig, config)
		end
	end
	table.sort(aConfig, function(a, b)
		if a.group == b.group then
			return b.sort > a.sort
		end
		return b.group > a.group
	end)
	-- 格式化内置数据
	local aEmbedded, tEmbedded, tEmbeddedMon = {}, {}, {}
	for _, config in ipairs(aConfig) do
		if config and config.uuid and config.monitors then
			local embedded = config
			if LANG ~= 'zhcn' then
				embedded = D.FormatConfig(config, bCoroutine)
			end
			if embedded then
				-- 默认禁用
				embedded.enable = false
				-- 配置项和监控项高速缓存
				local tMon = {}
				for _, mon in ipairs(embedded.monitors) do
					mon.manually = nil
					tMon[mon.uuid] = mon
				end
				-- 插入结果集
				tEmbedded[embedded.uuid] = embedded
				tEmbeddedMon[embedded.uuid] = tMon
				table.insert(aEmbedded, embedded)
			end
		end
	end
	EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = aEmbedded, tEmbedded, tEmbeddedMon
end

local SHIELDED_UUID = X.ArrayToObject({
	'00000223B5B291D0',
	'00000223B5FD2010',
	'00mu02rong04youMB',
	'00mu02rong04youZS',
	'00mu02rong04youMBC',
	'00mu02rong04youZSC',
	'00mu02rong04youMBMZB',
	'00mu02rong04youZSMZB',
	'00000000D7D31AB0',
	'000000009AB91DB0',
	'000001B68EE82B00',
	'000001B68EE79EB0',
	'000001B5FA8F1880',
	'000001B6A2BCF6F0',
})
-- 通过内嵌数据将监控项转为Patch
function D.PatchToConfig(patch, bCoroutine)
	-- 处理用户删除的内建数据和不合法的数据
	if patch.delete or not patch.uuid or (X.IsRestricted('MY_TargetMon.ShieldedUUID') and not IsDebugClient() and SHIELDED_UUID[patch.uuid]) then
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
	return D.FormatConfig(config, bCoroutine)
end

-- 通过内嵌数据将Patch转为监控项
function D.ConfigToPatch(config)
	-- 处理不合法的数据
	if not config.uuid then
		return
	end
	-- 计算修改的内嵌数据
	local embedded, patch = EMBEDDED_CONFIG_HASH[config.uuid], {}
	if embedded then
		-- 保存修改的全局属性
		for k, v in pairs(config) do
			if k ~= 'monitors' and not X.IsEquals(v, embedded[k]) then
				patch[k] = X.Clone(v)
			end
		end
		-- 保存监控项添加以及排序修改的部分
		local monitors = {}
		local existMon = {}
		for i, mon in ipairs(config.monitors) do
			local monEmbedded = EMBEDDED_MONITOR_HASH[embedded.uuid][mon.uuid]
			if monEmbedded then
				-- 内嵌的监控计算Patch
				table.insert(monitors, {
					embedded = true,
					uuid = monEmbedded.uuid,
					patch = X.GetPatch(monEmbedded, mon),
				})
			else
				-- 自己添加的监控
				table.insert(monitors, X.Clone(mon))
			end
			existMon[mon.uuid] = true
		end
		-- 保存删减的部分
		for _, monEmbedded in ipairs(embedded.monitors) do
			if not existMon[monEmbedded.uuid] then
				table.insert(monitors, { uuid = monEmbedded.uuid, delete = true })
			end
			existMon[monEmbedded.uuid] = true
		end
		patch.uuid = config.uuid
		patch.embedded = true
		patch.monitors = monitors
	else
		for k, v in pairs(config) do
			patch[k] = X.Clone(v)
		end
	end
	return patch
end

function D.MarkConfigChanged()
	CONFIG_CHANGED = true
end

function D.HasConfigChanged()
	return CONFIG_CHANGED
end

function D.UpdateTargetList()
	local tBuffTargetExist, tSkillTargetExist = {}, {}
	for _, config in ipairs(CONFIG) do
		if config.enable then
			if config.type == 'BUFF' then
				tBuffTargetExist[config.target] = true
			elseif config.type == 'SKILL' then
				tSkillTargetExist[config.target] = true
			end
		end
	end
	local aBuffTarget, aSkillTarget = {}, {}
	for _, szType in ipairs(TARGET_TYPE_LIST) do
		if tBuffTargetExist[szType] then
			table.insert(aBuffTarget, szType)
		end
		if tSkillTargetExist[szType] then
			table.insert(aSkillTarget, szType)
		end
	end
	CONFIG_BUFF_TARGET_LIST, CONFIG_SKILL_TARGET_LIST = aBuffTarget, aSkillTarget
end

function D.LoadConfig(bDefault, bOriginal, bCoroutine)
	local aPatch
	if not bDefault then
		aPatch = X.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = D.PW })
			or X.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = D.PASSPHRASE })
			or X.LoadLUAData(ROLE_CONFIG_FILE)
	end
	if not aPatch and not bOriginal then
		aPatch = X.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE, { passphrase = D.PW })
			or X.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE, { passphrase = D.PASSPHRASE })
			or X.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE)
	end
	if not aPatch then
		aPatch = {}
	end
	local aConfig, tLoaded = {}, {}
	for i, patch in ipairs(aPatch) do
		if patch.uuid and not tLoaded[patch.uuid] then
			local config = D.PatchToConfig(patch)
			if config then
				table.insert(aConfig, config)
			end
			tLoaded[patch.uuid] = true
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if embedded.uuid and not tLoaded[embedded.uuid] then
			local config = X.Clone(embedded)
			if LANG ~= 'zhcn' then
				config = D.FormatConfig(config, bCoroutine)
			end
			if config then
				config.embedded = true
				table.insert(aConfig, config)
			end
			tLoaded[config.uuid] = true
		end
	end
	CONFIG = aConfig
	CONFIG_CHANGED = bDefault and true or false
	D.UpdateTargetList()
	if INIT_STATE == 'DONE' then
		FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	end
end

function D.SaveConfig(bDefault)
	local aPatch, tLoaded = {}, {}
	for i, config in ipairs(CONFIG) do
		local patch = D.ConfigToPatch(config)
		if patch then
			table.insert(aPatch, patch)
		end
		tLoaded[config.uuid] = true
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if not tLoaded[embedded.uuid] then
			table.insert(aPatch, {
				uuid = embedded.uuid,
				delete = true,
			})
			tLoaded[embedded.uuid] = true
		end
	end
	if bDefault then
		X.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, aPatch, { passphrase = D.PW })
	else
		X.SaveLUAData(ROLE_CONFIG_FILE, aPatch, { passphrase = D.PW })
		CONFIG_CHANGED = false
	end
end

function D.ImportPatches(aPatch, bAsEmbedded)
	local nImportCount = 0
	local nReplaceCount = 0
	if bAsEmbedded then
		for _, embedded in ipairs(aPatch) do
			if embedded and embedded.uuid then
				local szFile = CUSTOM_EMBEDDED_CONFIG_ROOT .. embedded.uuid .. '.jx3dat'
				if IsLocalFileExist(szFile) then
					nReplaceCount = nReplaceCount + 1
				end
				nImportCount = nImportCount + 1
				X.SaveLUAData(szFile, embedded, { passphrase = D.PW_E })
			end
		end
		if nImportCount > 0 then
			D.SaveConfig()
			D.LoadEmbeddedConfig()
			D.LoadConfig()
		end
	else
		for _, patch in ipairs(aPatch) do
			local config = D.PatchToConfig(patch)
			if config then
				for i, cfg in X.ipairs_r(CONFIG) do
					if config.uuid and config.uuid == cfg.uuid then
						table.remove(CONFIG, i)
						nReplaceCount = nReplaceCount + 1
					end
				end
				nImportCount = nImportCount + 1
				table.insert(CONFIG, config)
			end
		end
		if nImportCount > 0 then
			CONFIG_CHANGED = true
			D.UpdateTargetList()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
		end
	end
	return nImportCount, nReplaceCount
end

function D.ExportPatches(aUUID, bAsEmbedded)
	local aPatch = {}
	for i, uuid in ipairs(aUUID) do
		for i, config in ipairs(CONFIG) do
			local patch = config.uuid == uuid and D.ConfigToPatch(config)
			if patch and (bAsEmbedded or not patch.embedded) then
				if bAsEmbedded then
					patch.uuid = 'DT' .. patch.uuid
				end
				table.insert(aPatch, patch)
			end
		end
	end
	return aPatch
end

function D.ImportPatchFile(oFilePath)
	local aPatch = X.LoadLUAData(oFilePath, { passphrase = D.PW })
		or X.LoadLUAData(oFilePath, { passphrase = D.PASSPHRASE })
		or X.LoadLUAData(oFilePath)
	local bAsEmbedded = false
	if not aPatch then
		aPatch = X.LoadLUAData(oFilePath, { passphrase = D.PW_E })
			or X.LoadLUAData(oFilePath, { passphrase = D.PASSPHRASE_EMBEDDED })
		bAsEmbedded = true
	end
	if not aPatch then
		return
	end
	return D.ImportPatches(aPatch, bAsEmbedded)
end

function D.ExportPatchFile(oFilePath, aUUID, szIndent, bAsEmbedded)
	if bAsEmbedded then
		szIndent = nil
	end
	local szPassphrase
	if bAsEmbedded then
		szPassphrase = D.PW_E
	elseif not szIndent then
		szPassphrase = D.PW
	end
	local aPatch = D.ExportPatches(aUUID, bAsEmbedded)
	X.SaveLUAData(oFilePath, aPatch, { indent = szIndent, crc = not szIndent, passphrase = szPassphrase })
end

function D.Init(bNoCoroutine)
	if INIT_STATE == 'NONE' then
		local K = string.char(75, 69)
		local k = string.char(80, 87)
		if X.IsString(D[k]) then
			D[k] = X[K](D[k] .. string.char(77, 89))
		end
		local k = string.char(80, 87, 95, 69)
		if X.IsString(D[k]) then
			D[k] = X[K](D[k] .. string.char(77, 89))
		end
		INIT_STATE = 'WAIT_CONFIG'
	end
	if INIT_STATE == 'WAIT_CONFIG' then
		X.RegisterCoroutine('MY_TargetMonConfig', function()
			D.LoadEmbeddedConfig(true)
			D.LoadConfig(nil, nil, true)
			INIT_STATE = 'DONE'
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
		end)
		INIT_STATE = 'LOADING_CONFIG'
	end
	if INIT_STATE == 'LOADING_CONFIG' and bNoCoroutine then
		X.FlushCoroutine('MY_TargetMonConfig')
	end
	return INIT_STATE == 'DONE'
end
X.RegisterInit('MY_TargetMonConfig', D.Init)

do
local function Flush()
	if not D.HasConfigChanged() then
		return
	end
	D.SaveConfig()
end
X.RegisterFlush('MY_TargetMonConfig', Flush)
end

function D.GetConfig(nIndex)
	return CONFIG[nIndex]
end

function D.GetConfigList(bNoEmbedded)
	D.Init(true)
	if bNoEmbedded then
		local a = {}
		for _, config in ipairs(CONFIG) do
			if not EMBEDDED_CONFIG_HASH[config.uuid] then
				table.insert(a, config)
			end
		end
		return a
	end
	return CONFIG
end

------------------------------------------------------------------------------------------------------
-- 监控设置条操作
------------------------------------------------------------------------------------------------------
function D.CreateConfig()
	local config = X.FormatDataStructure({
		uuid = D.GeneUUID(),
	}, CONFIG_TEMPLATE)
	table.insert(CONFIG, config)
	D.UpdateTargetList()
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	return config
end

function D.MoveConfig(config, offset)
	for i, v in ipairs(CONFIG) do
		if v == config then
			local j = math.min(math.max(i + offset, 1), #CONFIG)
			if j ~= i then
				table.remove(CONFIG, i)
				table.insert(CONFIG, j, config)
			end
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
			break
		end
	end
end

function D.ModifyConfig(config, szKey, oVal)
	if X.IsString(config) then
		for _, v in ipairs(CONFIG) do
			if v.uuid == config then
				config = v
				break
			end
		end
	end
	if not X.Set(config, szKey, oVal) then
		return
	end
	if szKey == 'enable' or szKey == 'target' or szKey == 'type' then
		D.UpdateTargetList()
	end
	if szKey == 'enable' and oVal then
		FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	end
	D.MarkConfigChanged()
end

function D.DeleteConfig(config, bAsEmbedded)
	for i, v in X.ipairs_r(CONFIG) do
		if v == config then
			table.remove(CONFIG, i)
			D.UpdateTargetList()
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
			break
		end
	end
	if bAsEmbedded then
		CPath.DelFile(CUSTOM_EMBEDDED_CONFIG_ROOT .. config.uuid .. '.jx3dat')
		D.LoadEmbeddedConfig()
		D.SaveConfig()
		D.LoadConfig()
	end
end

------------------------------------------------------------------------------------------------------
-- 监控内容数据项操作
------------------------------------------------------------------------------------------------------
function D.CreateMonitor(config, name)
	local mon = X.FormatDataStructure({
		name = name,
		uuid = D.GeneUUID(),
	}, MON_TEMPLATE)
	table.insert(config.monitors, mon)
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
	return mon
end

function D.MoveMonitor(config, mon, offset)
	for i, v in ipairs(config.monitors) do
		if v == mon then
			local j = math.min(math.max(i + offset, 1), #config.monitors)
			if j ~= i then
				table.remove(config.monitors, i)
				table.insert(config.monitors, j, mon)
			end
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
			break
		end
	end
end

function D.ModifyMonitor(mon, szKey, oVal)
	if not X.Set(mon, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
end

function D.DeleteMonitor(config, mon)
	for i, v in ipairs(config.monitors) do
		if v == mon then
			table.remove(config.monitors, i)
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
			break
		end
	end
end

------------------------------------------------------------------------------------------------------
-- 监控内容数据项ID列表
------------------------------------------------------------------------------------------------------
function D.CreateMonitorId(mon, dwID)
	local monid = X.FormatDataStructure(nil, MONID_TEMPLATE)
	mon.ids[dwID] = monid
	D.MarkConfigChanged()
	return monid
end

function D.ModifyMonitorId(monid, szKey, oVal)
	if not X.Set(monid, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
end

function D.DeleteMonitorId(mon, dwID)
	mon.ids[dwID] = nil
	D.MarkConfigChanged()
end

------------------------------------------------------------------------------------------------------
-- 监控内容数据项ID等级列表
------------------------------------------------------------------------------------------------------
function D.CreateMonitorLevel(monid, nLevel)
	local monlevel = X.FormatDataStructure(nil, MONLEVEL_TEMPLATE)
	monid.levels[nLevel] = monlevel
	D.MarkConfigChanged()
	return monlevel
end

function D.ModifyMonitorLevel(monlevel, szKey, oVal)
	if not X.Set(monlevel, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
end

function D.DeleteMonitorLevel(monid, nLevel)
	monid.levels[nLevel] = nil
	D.MarkConfigChanged()
end

-- Global exports
do
local settings = {
	name = 'MY_TargetMonConfig',
	exports = {
		{
			fields = {
				GetTargetTypeList  = D.GetTargetTypeList ,
				GetConfig          = D.GetConfig         ,
				GetConfigList      = D.GetConfigList     ,
				GetConfigCaption   = D.GetConfigCaption  ,
				LoadConfig         = D.LoadConfig        ,
				SaveConfig         = D.SaveConfig        ,
				ImportPatches      = D.ImportPatches     ,
				ExportPatches      = D.ExportPatches     ,
				ImportPatchFile    = D.ImportPatchFile   ,
				ExportPatchFile    = D.ExportPatchFile   ,
				MarkConfigChanged  = D.MarkConfigChanged ,
				CreateConfig       = D.CreateConfig      ,
				MoveConfig         = D.MoveConfig        ,
				ModifyConfig       = D.ModifyConfig      ,
				DeleteConfig       = D.DeleteConfig      ,
				CreateMonitor      = D.CreateMonitor     ,
				MoveMonitor        = D.MoveMonitor       ,
				ModifyMonitor      = D.ModifyMonitor     ,
				DeleteMonitor      = D.DeleteMonitor     ,
				CreateMonitorId    = D.CreateMonitorId   ,
				ModifyMonitorId    = D.ModifyMonitorId   ,
				DeleteMonitorId    = D.DeleteMonitorId   ,
				CreateMonitorLevel = D.CreateMonitorLevel,
				ModifyMonitorLevel = D.ModifyMonitorLevel,
				DeleteMonitorLevel = D.DeleteMonitorLevel,
			},
		},
	},
}
MY_TargetMonConfig = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
