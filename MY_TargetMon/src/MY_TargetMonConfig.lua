--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
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
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')
if not MY.AssertVersion('MY_TargetMon', _L['MY_TargetMon'], 0x2011800) then
	return
end
local C, D = {}, {}
local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/ui/MY_TargetMon.ini'
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.ROLE}
local TEMPLATE_CONFIG_FILE = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat'
local EMBEDDED_CONFIG_ROOT = MY.GetAddonInfo().szRoot .. 'MY_Resource/data/targetmon/'
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.GLOBAL}
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
local CONFIG_TEMPLATE = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat')
local MON_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__
local MONID_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__
local MONLEVEL_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__.levels.__CHILD_TEMPLATE__
local EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = {}, {}, {}

local PASSPHRASE, PASSPHRASE_EMBEDDED
do
local function GetPassphrase(a, b)
	for i = 0, 50 do
		for j, v in ipairs({ 253, 12, 34, 56 }) do
			insert(a, (i * j * ((b * v) % 256)) % 256)
		end
	end
	return char(unpack(a))
end
PASSPHRASE = GetPassphrase({213, 166, 13}, 3)
PASSPHRASE_EMBEDDED = GetPassphrase({211, 98, 5}, 15)
end

do -- auto generate embedded data
local DAT_ROOT = 'MY_Resource/data/targetmon/'
local SRC_ROOT = MY.GetAddonInfo().szRoot .. '!src-dist/dat/' .. DAT_ROOT
local DST_ROOT = EMBEDDED_CONFIG_ROOT
for _, szFile in ipairs(CPath.GetFileList(SRC_ROOT)) do
	MY.Sysmsg(_L['Encrypt and compressing: '] .. DAT_ROOT .. szFile)
	local data = LoadDataFromFile(SRC_ROOT .. szFile)
	if IsEncodedData(data) then
		data = DecodeData(data)
	end
	data = EncodeData(data, true, false)
	SaveDataToFile(data, DST_ROOT .. szFile, PASSPHRASE_EMBEDDED)
end
end

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
	return MY.GetUUID():gsub('-', '')
end

-- 格式化监控项数据
function D.FormatConfig(config)
	return MY.FormatDataStructure(config, CONFIG_TEMPLATE)
end

function D.LoadEmbeddedConfig()
	local aEmbedded, tEmbedded, tEmbeddedMon = {}, {}, {}
	for _, szFile in ipairs(CPath.GetFileList(EMBEDDED_CONFIG_ROOT)) do
		if wfind(szFile, MY.GetLang() .. '.jx3dat') then
			for _, config in ipairs(
				MY.LoadLUAData(EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = PASSPHRASE_EMBEDDED })
				or MY.LoadLUAData(EMBEDDED_CONFIG_ROOT .. szFile)
				or {}
			) do
				if config and config.uuid and config.monitors then
					local embedded = D.FormatConfig(config)
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
						insert(aEmbedded, embedded)
					end
				end
			end
		end
	end
	EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = aEmbedded, tEmbedded, tEmbeddedMon
end
D.LoadEmbeddedConfig()

local SHIELDED_UUID = MY.ArrayToObject({
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
function D.PatchToConfig(patch)
	-- 处理用户删除的内建数据和不合法的数据
	if patch.delete or not patch.uuid or (MY.IsShieldedVersion() and not IsDebugClient() and SHIELDED_UUID[patch.uuid]) then
		return
	end
	-- 合并未修改的内嵌数据
	local embedded, config = EMBEDDED_CONFIG_HASH[patch.uuid], {}
	if embedded then
		-- 设置内嵌数据默认属性
		for k, v in pairs(embedded) do
			if k ~= 'monitors' then
				if patch[k] == nil then
					config[k] = clone(v)
				end
			end
		end
		-- 设置改变过的数据
		for k, v in pairs(patch) do
			if k ~= 'monitors' then
				config[k] = clone(v)
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
							insert(monitors, ApplyPatch(monEmbedded, mon.patch))
						else
							insert(monitors, clone(monEmbedded))
						end
					elseif not mon.embedded and not mon.patch and mon.manually ~= false then -- 删除当前版本不存在的内嵌数据
						insert(monitors, clone(mon))
					end
				end
				existMon[mon.uuid] = true
			end
		end
		-- 插入新的内嵌数据
		for _, monEmbedded in ipairs(embedded.monitors) do
			if not existMon[monEmbedded.uuid] then
				insert(monitors, clone(monEmbedded))
			end
			existMon[monEmbedded.uuid] = true
		end
		config.monitors = monitors
	else
		-- 不再存在的内嵌数据
		if patch.embedded then
			return
		end
		for k, v in pairs(patch) do
			config[k] = clone(v)
		end
	end
	return D.FormatConfig(config)
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
			if k ~= 'monitors' and not IsEquals(v, embedded[k]) then
				patch[k] = clone(v)
			end
		end
		-- 保存监控项添加以及排序修改的部分
		local monitors = {}
		local existMon = {}
		for i, mon in ipairs(config.monitors) do
			local monEmbedded = EMBEDDED_MONITOR_HASH[embedded.uuid][mon.uuid]
			if monEmbedded then
				-- 内嵌的监控计算Patch
				insert(monitors, {
					embedded = true,
					uuid = monEmbedded.uuid,
					patch = GetPatch(monEmbedded, mon),
				})
			else
				-- 自己添加的监控
				insert(monitors, clone(mon))
			end
			existMon[mon.uuid] = true
		end
		-- 保存删减的部分
		for _, monEmbedded in ipairs(embedded.monitors) do
			if not existMon[monEmbedded.uuid] then
				insert(monitors, { uuid = monEmbedded.uuid, delete = true })
			end
			existMon[monEmbedded.uuid] = true
		end
		patch.uuid = config.uuid
		patch.embedded = true
		patch.monitors = monitors
	else
		for k, v in pairs(config) do
			patch[k] = clone(v)
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
			insert(aBuffTarget, szType)
		end
		if tSkillTargetExist[szType] then
			insert(aSkillTarget, szType)
		end
	end
	CONFIG_BUFF_TARGET_LIST, CONFIG_SKILL_TARGET_LIST = aBuffTarget, aSkillTarget
end

function D.LoadConfig(bDefault, bOriginal, bReloadEmbedded)
	if bReloadEmbedded then
		D.LoadEmbeddedConfig()
	end
	local aPatch
	if not bDefault then
		aPatch = MY.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = PASSPHRASE }) or MY.LoadLUAData(ROLE_CONFIG_FILE)
	end
	if not aPatch and not bOriginal then
		aPatch = MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE, { passphrase = PASSPHRASE }) or MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE)
	end
	if not aPatch then
		aPatch = {}
	end
	local aConfig, tLoaded = {}, {}
	for i, patch in ipairs(aPatch) do
		if patch.uuid and not tLoaded[patch.uuid] then
			local config = D.PatchToConfig(patch)
			if config then
				insert(aConfig, config)
			end
			tLoaded[patch.uuid] = true
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if embedded.uuid and not tLoaded[embedded.uuid] then
			local config = D.FormatConfig(embedded)
			if config then
				insert(aConfig, config)
			end
			tLoaded[config.uuid] = true
		end
	end
	if #EMBEDDED_CONFIG_LIST == 0 then
		OutputMessage('MSG_ANNOUNCE_RED', _L['Empty embedded config detected, did you forgot to load MY_Resource plugin?'])
		MY.Sysmsg(_L['Empty embedded config detected, please logout and check if MY_Resource has been downloaded and loaded.'])
	end
	CONFIG = aConfig
	CONFIG_CHANGED = bDefault and true or false
	D.UpdateTargetList()
	FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
end

function D.SaveConfig(bDefault)
	local aPatch, tLoaded = {}, {}
	for i, config in ipairs(CONFIG) do
		local patch = D.ConfigToPatch(config)
		if patch then
			insert(aPatch, patch)
		end
		tLoaded[config.uuid] = true
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if not tLoaded[embedded.uuid] then
			insert(aPatch, {
				uuid = embedded.uuid,
				delete = true,
			})
			tLoaded[embedded.uuid] = true
		end
	end
	if bDefault then
		MY.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, aPatch, { passphrase = PASSPHRASE })
	else
		MY.SaveLUAData(ROLE_CONFIG_FILE, aPatch, { passphrase = PASSPHRASE })
		CONFIG_CHANGED = false
	end
end

function D.ImportPatches(aPatch)
	local nImportCount = 0
	local nReplaceCount = 0
	for _, patch in ipairs(aPatch) do
		local config = D.PatchToConfig(patch)
		if config then
			for i, cfg in ipairs_r(CONFIG) do
				if config.uuid and config.uuid == cfg.uuid then
					remove(CONFIG, i)
					nReplaceCount = nReplaceCount + 1
				end
			end
			nImportCount = nImportCount + 1
			insert(CONFIG, config)
		end
	end
	if nImportCount > 0 then
		CONFIG_CHANGED = true
		D.UpdateTargetList()
		FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	end
	return nImportCount, nReplaceCount
end

function D.ExportPatches(aUUID, bNoEmbedded)
	local aPatch = {}
	for i, uuid in ipairs(aUUID) do
		for i, config in ipairs(CONFIG) do
			local patch = config.uuid == uuid and D.ConfigToPatch(config)
			if patch and (not bNoEmbedded or not patch.embedded) then
				if bNoEmbedded then
					patch.uuid = 'DT' .. patch.uuid
				end
				insert(aPatch, patch)
			end
		end
	end
	return aPatch
end

function D.ImportPatchFile(oFilePath)
	local aPatch = MY.LoadLUAData(oFilePath, { passphrase = PASSPHRASE }) or MY.LoadLUAData(oFilePath)
	if not aPatch then
		return
	end
	return D.ImportPatches(aPatch)
end

function D.ExportPatchFile(oFilePath, aUUID, szIndent, bAsEmbedded)
	if bAsEmbedded then
		szIndent = nil
	end
	local szPassphrase
	if bAsEmbedded then
		szPassphrase = PASSPHRASE_EMBEDDED
	elseif not szIndent then
		szPassphrase = PASSPHRASE
	end
	local aPatch = D.ExportPatches(aUUID, bAsEmbedded)
	MY.SaveLUAData(oFilePath, aPatch, { indent = szIndent, crc = not szIndent, passphrase = szPassphrase })
end

do
local function onInit()
	if CONFIG then
		return
	end
	D.LoadConfig()
end
MY.RegisterInit('MY_TargetMonConfig', onInit)

local function onExit()
	if not D.HasConfigChanged() then
		return
	end
	D.SaveConfig()
end
MY.RegisterExit('MY_TargetMonConfig', onExit)
end

function D.GetConfig()
	return CONFIG[nIndex]
end

function D.GetConfigList(bNoEmbedded)
	if bNoEmbedded then
		local a = {}
		for _, config in ipairs(CONFIG) do
			if not EMBEDDED_CONFIG_HASH[config.uuid] then
				insert(a, config)
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
	local config = MY.FormatDataStructure({
		uuid = D.GeneUUID(),
	}, CONFIG_TEMPLATE)
	insert(CONFIG, config)
	D.UpdateTargetList()
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	return config
end

function D.MoveConfig(config, offset)
	for i, v in ipairs(CONFIG) do
		if v == config then
			local j = min(max(i + offset, 1), #CONFIG)
			if j ~= i then
				remove(CONFIG, i)
				insert(CONFIG, j, config)
			end
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
			break
		end
	end
end

function D.ModifyConfig(config, szKey, oVal)
	if IsString(config) then
		for _, v in ipairs(CONFIG) do
			if v.uuid == config then
				config = v
				break
			end
		end
	end
	if not Set(config, szKey, oVal) then
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

function D.DeleteConfig(config)
	for i, v in ipairs_r(CONFIG) do
		if v == config then
			remove(CONFIG, i)
			D.UpdateTargetList()
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
		end
	end
end

------------------------------------------------------------------------------------------------------
-- 监控内容数据项操作
------------------------------------------------------------------------------------------------------
function D.CreateMonitor(config, name)
	local mon = MY.FormatDataStructure({
		name = name,
		uuid = D.GeneUUID(),
	}, MON_TEMPLATE)
	insert(config.monitors, mon)
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
	return mon
end

function D.MoveMonitor(config, mon, offset)
	for i, v in ipairs(config.monitors) do
		if v == mon then
			local j = min(max(i + offset, 1), #config.monitors)
			if j ~= i then
				remove(config.monitors, i)
				insert(config.monitors, j, mon)
			end
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
			break
		end
	end
end

function D.ModifyMonitor(mon, szKey, oVal)
	if not Set(mon, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
end

function D.DeleteMonitor(config, mon)
	for i, v in ipairs(config.monitors) do
		if v == mon then
			remove(config.monitors, i)
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
	local monid = MY.FormatDataStructure(nil, MONID_TEMPLATE)
	mon.ids[dwID] = monid
	D.MarkConfigChanged()
	return monid
end

function D.ModifyMonitorId(monid, szKey, oVal)
	if not Set(monid, szKey, oVal) then
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
	local monlevel = MY.FormatDataStructure(nil, MONLEVEL_TEMPLATE)
	monid.levels[nLevel] = monlevel
	D.MarkConfigChanged()
	return monlevel
end

function D.ModifyMonitorLevel(monlevel, szKey, oVal)
	if not Set(monlevel, szKey, oVal) then
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
	exports = {
		{
			fields = {
				GetTargetTypeList  = D.GetTargetTypeList ,
				GetConfig          = D.GetConfig         ,
				GetConfigList      = D.GetConfigList     ,
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
MY_TargetMonConfig = MY.GeneGlobalNS(settings)
end
