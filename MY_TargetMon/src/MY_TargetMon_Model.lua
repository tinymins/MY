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
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local Get, GetPatch, ApplyPatch, RandomChild = MY.Get, MY.GetPatch, MY.ApplyPatch, MY.RandomChild
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
local CUSTOM_BOXBG_STYLES = {
	'UI/Image/Common/Box.UITex|0',
	'UI/Image/Common/Box.UITex|1',
	'UI/Image/Common/Box.UITex|2',
	'UI/Image/Common/Box.UITex|3',
	'UI/Image/Common/Box.UITex|4',
	'UI/Image/Common/Box.UITex|5',
	'UI/Image/Common/Box.UITex|6',
	'UI/Image/Common/Box.UITex|7',
	'UI/Image/Common/Box.UITex|8',
	'UI/Image/Common/Box.UITex|9',
	'UI/Image/Common/Box.UITex|10',
	'UI/Image/Common/Box.UITex|11',
	'UI/Image/Common/Box.UITex|12',
	'UI/Image/Common/Box.UITex|13',
	'UI/Image/Common/Box.UITex|14',
	'UI/Image/Common/Box.UITex|34',
	'UI/Image/Common/Box.UITex|35',
	'UI/Image/Common/Box.UITex|42',
	'UI/Image/Common/Box.UITex|43',
	'UI/Image/Common/Box.UITex|44',
	'UI/Image/Common/Box.UITex|45',
	'UI/Image/Common/Box.UITex|77',
	'UI/Image/Common/Box.UITex|78',
}
local CUSTOM_CDBAR_STYLES = {
	MY.GetAddonInfo().szUITexST .. '|' .. 0,
	MY.GetAddonInfo().szUITexST .. '|' .. 1,
	MY.GetAddonInfo().szUITexST .. '|' .. 2,
	MY.GetAddonInfo().szUITexST .. '|' .. 3,
	MY.GetAddonInfo().szUITexST .. '|' .. 4,
	MY.GetAddonInfo().szUITexST .. '|' .. 5,
	MY.GetAddonInfo().szUITexST .. '|' .. 6,
	MY.GetAddonInfo().szUITexST .. '|' .. 7,
	MY.GetAddonInfo().szUITexST .. '|' .. 8,
	'/ui/Image/Common/Money.UITex|168',
	'/ui/Image/Common/Money.UITex|203',
	'/ui/Image/Common/Money.UITex|204',
	'/ui/Image/Common/Money.UITex|205',
	'/ui/Image/Common/Money.UITex|206',
	'/ui/Image/Common/Money.UITex|207',
	'/ui/Image/Common/Money.UITex|208',
	'/ui/Image/Common/Money.UITex|209',
	'/ui/Image/Common/Money.UITex|210',
	'/ui/Image/Common/Money.UITex|211',
	'/ui/Image/Common/Money.UITex|212',
	'/ui/Image/Common/Money.UITex|213',
	'/ui/Image/Common/Money.UITex|214',
	'/ui/Image/Common/Money.UITex|215',
	'/ui/Image/Common/Money.UITex|216',
	'/ui/Image/Common/Money.UITex|217',
	'/ui/Image/Common/Money.UITex|218',
	'/ui/Image/Common/Money.UITex|219',
	'/ui/Image/Common/Money.UITex|220',
	'/ui/Image/Common/Money.UITex|228',
	'/ui/Image/Common/Money.UITex|232',
	'/ui/Image/Common/Money.UITex|233',
	'/ui/Image/Common/Money.UITex|234',
}
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
local CONFIG, CONFIG_CHANGED
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
							mon.manually = false
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
		local monitors = {}
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
	else
		for k, v in pairs(config) do
			patch[k] = clone(v)
		end
	end
	return patch
end

function D.SetConfigChanged(bChange)
	CONFIG_CHANGED = bChange ~= false
end

function D.HasConfigChanged(bChange)
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
	local aConfig = {}
	local existConfig = {}
	for i, patch in ipairs(aPatch) do
		if not existConfig[patch.uuid] then
			local config = D.PatchToConfig(patch)
			if config then
				insert(aConfig, config)
				existConfig[config.uuid] = true
			end
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if not existConfig[embedded.uuid] then
			local config = D.FormatConfig(embedded)
			if config then
				insert(aConfig, D.FormatConfig(config))
				existConfig[config.uuid] = true
			end
		end
	end
	CONFIG = aConfig
	D.SetConfigChanged(true)
	FireUIEvent('MY_TARGET_MON_RELOAD')
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
		D.SetConfigChanged(false)
	end
end

do
local function onInit()
	if CONFIG then
		return
	end
	D.LoadConfig()
end
MY.RegisterInit('MY_TargetMon', onInit)

local function onExit()
	if not D.HasConfigChanged() then
		return
	end
	D.SaveConfig()
end
MY.RegisterExit('MY_TargetMon', onExit)
end

function D.GetConfig()
	return CONFIG
end

MY_TargetMon = {}
MY_TargetMon.GetConfig = D.GetConfig
MY_TargetMon.LoadConfig = D.LoadConfig
MY_TargetMon.GetNewConfig = D.GetNewConfig
MY_TargetMon.GetNewMonitor = D.GetNewMonitor
