--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local ipairs_r = LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------

local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')
if not LIB.AssertVersion('MY_TargetMon', _L['MY_TargetMon'], 0x2011800) then
	return
end
local LANG = LIB.GetLang()
local INIT_STATE = 'NONE'
local C, D = { PASSPHRASE = {213, 166, 13}, PASSPHRASE_EMBEDDED = {211, 98, 5} }, {}
local INI_PATH = LIB.GetAddonInfo().szRoot .. 'MY_TargetMon/ui/MY_TargetMon.ini'
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', PATH_TYPE.ROLE}
local TEMPLATE_CONFIG_FILE = LIB.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat'
local EMBEDDED_ENCRYPTED = false
local EMBEDDED_CONFIG_ROOT = LIB.GetAddonInfo().szRoot .. 'MY_Resource/data/targetmon/'
local CUSTOM_EMBEDDED_CONFIG_ROOT = LIB.FormatPath({'userdata/TargetMon/', PATH_TYPE.GLOBAL})
local EMBEDDED_CONFIG_SUFFIX = '.' .. LANG .. '.jx3dat'
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', PATH_TYPE.GLOBAL}
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
local CONFIG_TEMPLATE = LIB.LoadLUAData(LIB.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat')
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
	return LIB.GetUUID():gsub('-', '')
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
	return LIB.FormatDataStructure(config, CONFIG_TEMPLATE, nil, nil, bCoroutine)
end

function D.LoadEmbeddedConfig(bCoroutine)
	if not IsString(C.PASSPHRASE) or not IsString(C.PASSPHRASE_EMBEDDED) then
		return LIB.Debug({'Passphrase cannot be empty!'}, 'MY_TargetMonConfig', DEBUG_LEVEL.ERROR)
	end
	if not EMBEDDED_ENCRYPTED then
		-- 自动生成内置加密数据
		local DAT_ROOT = 'MY_Resource/data/targetmon/'
		local SRC_ROOT = LIB.GetAddonInfo().szRoot .. '!src-dist/dat/' .. DAT_ROOT
		local DST_ROOT = EMBEDDED_CONFIG_ROOT
		for _, szFile in ipairs(CPath.GetFileList(SRC_ROOT)) do
			LIB.Sysmsg(_L['Encrypt and compressing: '] .. DAT_ROOT .. szFile)
			local lang = szFile:sub(-11, -8)
			local data = LoadDataFromFile(SRC_ROOT .. szFile)
			if IsEncodedData(data) then
				data = DecodeData(data)
			end
			if lang == 'zhcn' then
				data = DecodeLUAData(data)
				if IsArray(data) then
					for k, p in ipairs(data) do
						data[k] = D.FormatConfig(p, bCoroutine)
					end
				else
					data = D.FormatConfig(data, bCoroutine)
				end
				data = 'return ' .. EncodeLUAData(data)
			end
			data = EncodeData(data, true, true)
			SaveDataToFile(data, DST_ROOT .. szFile, C.PASSPHRASE_EMBEDDED)
		end
		-- 兼容旧版内置数据
		local szV2Path = EMBEDDED_CONFIG_ROOT .. LANG .. '.jx3dat'
		if IsLocalFileExist(szV2Path) then
			local aConfig = LIB.LoadLUAData(szV2Path, { passphrase = C.PASSPHRASE_EMBEDDED }) or LIB.LoadLUAData(szV2Path)
			if IsTable(aConfig) then
				for i, config in ipairs(aConfig) do
					if IsTable(config) and config.uuid then
						config.group = ''
						config.sort = i
						LIB.SaveLUAData(EMBEDDED_CONFIG_ROOT .. config.uuid .. '.' .. LANG .. '.jx3dat', D.FormatConfig(config, bCoroutine), { passphrase = C.PASSPHRASE_EMBEDDED })
					end
				end
			end
			CPath.DelFile(szV2Path)
		end
		EMBEDDED_ENCRYPTED = true
	end
	-- 加载内置数据
	local aConfig = {}
	for _, szFile in ipairs(CPath.GetFileList(EMBEDDED_CONFIG_ROOT) or {}) do
		if wfind(szFile, EMBEDDED_CONFIG_SUFFIX) then
			local config = LIB.LoadLUAData(EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = C.PASSPHRASE_EMBEDDED })
				or LIB.LoadLUAData(EMBEDDED_CONFIG_ROOT .. szFile)
			if IsTable(config) and config.uuid and szFile:sub(1, -#EMBEDDED_CONFIG_SUFFIX - 1) == config.uuid and config.monitors then
				insert(aConfig, config)
			end
		end
	end
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_EMBEDDED_CONFIG_ROOT) or {}) do
		local config = LIB.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = C.PASSPHRASE_EMBEDDED })
			or LIB.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile)
		if IsTable(config) and config.uuid and szFile:sub(1, -#'.jx3dat' - 1) == config.uuid and config.group and config.sort and config.monitors then
			insert(aConfig, config)
		end
	end
	sort(aConfig, function(a, b)
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
				insert(aEmbedded, embedded)
			end
		end
	end
	EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = aEmbedded, tEmbedded, tEmbeddedMon
end

local SHIELDED_UUID = LIB.ArrayToObject({
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
	if patch.delete or not patch.uuid or (LIB.IsShieldedVersion() and not IsDebugClient() and SHIELDED_UUID[patch.uuid]) then
		return
	end
	-- 合并未修改的内嵌数据
	local embedded, config = EMBEDDED_CONFIG_HASH[patch.uuid], {}
	if embedded then
		-- 设置内嵌数据默认属性
		for k, v in pairs(embedded) do
			if k ~= 'monitors' then
				if patch[k] == nil then
					config[k] = Clone(v)
				end
			end
		end
		-- 设置改变过的数据
		for k, v in pairs(patch) do
			if k ~= 'monitors' then
				config[k] = Clone(v)
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
							insert(monitors, Clone(monEmbedded))
						end
					elseif not mon.embedded and not mon.patch and mon.manually ~= false then -- 删除当前版本不存在的内嵌数据
						insert(monitors, Clone(mon))
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
					insert(monitors, nIndex, Clone(monEmbedded))
				else
					insert(monitors, Clone(monEmbedded))
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
			config[k] = Clone(v)
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
			if k ~= 'monitors' and not IsEquals(v, embedded[k]) then
				patch[k] = Clone(v)
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
				insert(monitors, Clone(mon))
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
			patch[k] = Clone(v)
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

function D.LoadConfig(bDefault, bOriginal, bCoroutine)
	local aPatch
	if not bDefault then
		aPatch = LIB.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = C.PASSPHRASE }) or LIB.LoadLUAData(ROLE_CONFIG_FILE)
	end
	if not aPatch and not bOriginal then
		aPatch = LIB.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE, { passphrase = C.PASSPHRASE }) or LIB.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE)
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
			local config = embedded
			if LANG ~= 'zhcn' then
				config = D.FormatConfig(config, bCoroutine)
			end
			if config then
				config.embedded = true
				insert(aConfig, config)
			end
			tLoaded[config.uuid] = true
		end
	end
	if #EMBEDDED_CONFIG_LIST == 0 then
		OutputMessage('MSG_ANNOUNCE_RED', _L['Empty embedded config detected, did you forgot to load MY_Resource plugin?'])
		LIB.Sysmsg(_L['Empty embedded config detected, please logout and check if MY_Resource has been downloaded and loaded.'])
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
		LIB.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, aPatch, { passphrase = C.PASSPHRASE })
	else
		LIB.SaveLUAData(ROLE_CONFIG_FILE, aPatch, { passphrase = C.PASSPHRASE })
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
				LIB.SaveLUAData(szFile, embedded, { passphrase = C.PASSPHRASE_EMBEDDED })
			end
		end
		if nImportCount > 0 then
			D.LoadEmbeddedConfig()
			D.SaveConfig()
			D.LoadConfig()
		end
	else
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
				insert(aPatch, patch)
			end
		end
	end
	return aPatch
end

function D.ImportPatchFile(oFilePath)
	local aPatch, bAsEmbedded = LIB.LoadLUAData(oFilePath, { passphrase = C.PASSPHRASE }) or LIB.LoadLUAData(oFilePath), false
	if not aPatch then
		aPatch, bAsEmbedded = LIB.LoadLUAData(oFilePath, { passphrase = C.PASSPHRASE_EMBEDDED }), true
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
		szPassphrase = C.PASSPHRASE_EMBEDDED
	elseif not szIndent then
		szPassphrase = C.PASSPHRASE
	end
	local aPatch = D.ExportPatches(aUUID, bAsEmbedded)
	LIB.SaveLUAData(oFilePath, aPatch, { indent = szIndent, crc = not szIndent, passphrase = szPassphrase })
end

function D.Init(bNoCoroutine)
	if INIT_STATE == 'NONE' then
		local k = char(80, 65, 83, 83, 80, 72, 82, 65, 83, 69)
		if IsTable(C[k]) then
			for i = 0, 50 do
				for j, v in ipairs({ 253, 12, 34, 56 }) do
					insert(C[k], (i * j * ((3 * v) % 256)) % 256)
				end
			end
			C[k] = char(unpack(C[k]))
		end
		local k = char(80, 65, 83, 83, 80, 72, 82, 65, 83, 69, 95, 69, 77, 66, 69, 68, 68, 69, 68)
		if IsTable(C[k]) then
			for i = 0, 50 do
				for j, v in ipairs({ 253, 12, 34, 56 }) do
					insert(C[k], (i * j * ((15 * v) % 256)) % 256)
				end
			end
			C[k] = char(unpack(C[k]))
		end
		INIT_STATE = 'WAIT_CONFIG'
	end
	if INIT_STATE == 'WAIT_CONFIG' then
		LIB.RegisterCoroutine('MY_TargetMonConfig', function()
			D.LoadEmbeddedConfig(true)
			D.LoadConfig(nil, nil, true)
			INIT_STATE = 'DONE'
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
		end)
		INIT_STATE = 'LOADING_CONFIG'
	end
	if INIT_STATE == 'LOADING_CONFIG' and bNoCoroutine then
		LIB.FinishCoroutine('MY_TargetMonConfig')
	end
	return INIT_STATE == 'DONE'
end
LIB.RegisterInit('MY_TargetMonConfig', D.Init)

do
local function onExit()
	if not D.HasConfigChanged() then
		return
	end
	D.SaveConfig()
end
LIB.RegisterExit('MY_TargetMonConfig', onExit)
end

function D.GetConfig()
	return CONFIG[nIndex]
end

function D.GetConfigList(bNoEmbedded)
	D.Init(true)
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
	local config = LIB.FormatDataStructure({
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

function D.DeleteConfig(config, bAsEmbedded)
	for i, v in ipairs_r(CONFIG) do
		if v == config then
			remove(CONFIG, i)
			D.UpdateTargetList()
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
			break
		end
	end
	if bAsEmbedded then
		CPath.DelFile(CUSTOM_EMBEDDED_CONFIG_ROOT .. config.uuid .. '.jx3dat')
		CPath.DelFile(EMBEDDED_CONFIG_ROOT .. config.uuid .. EMBEDDED_CONFIG_SUFFIX)
		D.LoadEmbeddedConfig()
		D.SaveConfig()
		D.LoadConfig()
	end
end

------------------------------------------------------------------------------------------------------
-- 监控内容数据项操作
------------------------------------------------------------------------------------------------------
function D.CreateMonitor(config, name)
	local mon = LIB.FormatDataStructure({
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
	local monid = LIB.FormatDataStructure(nil, MONID_TEMPLATE)
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
	local monlevel = LIB.FormatDataStructure(nil, MONLEVEL_TEMPLATE)
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
MY_TargetMonConfig = LIB.GeneGlobalNS(settings)
end
