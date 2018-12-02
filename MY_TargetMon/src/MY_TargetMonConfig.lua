--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
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
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild = MY.Get, MY.Set, MY.RandomChild
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')
if not MY.AssertVersion('MY_TargetMon', _L['MY_TargetMon'], 0x2011800) then
	return
end
local C, D = {}, {}
local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/ui/MY_TargetMon.ini'
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', MY_DATA_PATH.ROLE}
local TEMPLATE_CONFIG_FILE = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat'
local EMBEDDED_CONFIG_ROOT = MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/embedded/'
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
local CONFIG, CONFIG_HASH, CONFIG_CHANGED
local CONFIG_TEMPLATE = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/data/template/$lang.jx3dat')
local EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = {}, {}, {}

-- 格式化监控项数据
function D.FormatConfig(config)
	return MY.FormatDataStructure(config, CONFIG_TEMPLATE)
end

function D.LoadEmbeddedConfig()
	local aEmbedded, tEmbedded, tEmbeddedMon = {}, {}, {}
	for _, szFile in ipairs(CPath.GetFileList(EMBEDDED_CONFIG_ROOT)) do
		if wfind(szFile, MY.GetLang() .. '.jx3dat') then
			for _, config in ipairs(MY.LoadLUAData(EMBEDDED_CONFIG_ROOT .. szFile) or {}) do
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

-- 通过内嵌数据将监控项转为Patch
function D.PatchToConfig(patch)
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
					elseif not mon.patch and mon.manually ~= false then -- 删除当前版本不存在的内嵌数据
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

function D.LoadConfig(bDefault, bOriginal, bReloadEmbedded)
	if bReloadEmbedded then
		D.LoadEmbeddedConfig()
	end
	local aPatch
	if not bDefault then
		aPatch = MY.LoadLUAData(ROLE_CONFIG_FILE)
	end
	if not aPatch and not bOriginal then
		aPatch = MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE)
	end
	if not aPatch then
		aPatch = MY.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE) or {}
	end
	local aConfig, tConfig = {}, {}
	for i, patch in ipairs(aPatch) do
		if not tConfig[patch.uuid] then
			local config = D.PatchToConfig(patch)
			if config then
				insert(aConfig, config)
				tConfig[config.uuid] = config
			end
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if not tConfig[embedded.uuid] then
			local config = D.FormatConfig(embedded)
			if config then
				insert(aConfig, config)
				tConfig[config.uuid] = config
			end
		end
	end
	CONFIG = aConfig
	CONFIG_HASH = tConfig
	CONFIG_CHANGED = bDefault and true or false
	FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
end

function D.SaveConfig(bDefault)
	local aPatch = {}
	for i, config in ipairs(CONFIG) do
		local patch = D.ConfigToPatch(config)
		if patch then
			insert(aPatch, patch)
		end
	end
	if bDefault then
		MY.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, aPatch)
	else
		MY.SaveLUAData(ROLE_CONFIG_FILE, aPatch)
		CONFIG_CHANGED = false
	end
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

function D.GetConfig(nIndex)
	if nIndex then
		return CONFIG[nIndex]
	end
	return CONFIG
end

function D.GetTargetTypeList()
	return TARGET_TYPE_LIST
end

function D.SetData(szUuid, aKey, oVal)
	local config = CONFIG_HASH[szUuid]
	if not config then
		return
	end
	if not Set(config, aKey, oVal) then
		return
	end
	if aKey[1] == 'enable' and oVal then
		FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	end
	D.MarkConfigChanged()
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				GetConfig         = D.GetConfig        ,
				LoadConfig        = D.LoadConfig       ,
				MarkConfigChanged = D.MarkConfigChanged,
				GetNewConfig      = D.GetNewConfig     ,
				GetNewMon         = D.GetNewMon        ,
				GetNewMonId       = D.GetNewMonId      ,
				GetNewMonLevel    = D.GetNewMonLevel   ,
				GetTargetTypeList = D.GetTargetTypeList,
				SetData           = D.SetData          ,
			},
		},
	},
}
MY_TargetMonConfig = MY.GeneGlobalNS(settings)
end
