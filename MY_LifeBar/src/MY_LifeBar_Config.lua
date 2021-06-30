--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 扁平血条设置
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
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {}

local function LoadDefaultTemplate(szStyle)
	local template = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_LifeBar/config/' .. szStyle .. '/{$lang}.jx3dat')
	if not template then
		return
	end
	for _, szRelation in ipairs({ 'Self', 'Party', 'Enemy', 'Neutrality', 'Ally', 'Foe' }) do
		local tVal = LIB.KvpToObject(template[1].Color[szRelation].__VALUE__)
		for _, dwForceID in pairs_c(CONSTANT.FORCE_TYPE) do
			if not tVal[dwForceID] then
				tVal[dwForceID] = { LIB.GetForceColor(dwForceID, 'foreground') }
			end
		end
		template[1].Color[szRelation].__VALUE__ = tVal
	end
	if LIB.IsStreaming() then -- 云端微调对立颜色防止压缩模糊
		for _, szType in ipairs({ 'Player', 'Npc' }) do
			template[1].Color.Enemy.__VALUE__[szType] = { 253, 86, 86 }
		end
		template[1].Color.Foe.__VALUE__.Player = { 202, 126, 255 }
	end
	return template
end

local CONFIG_DEFAULTS, Config
local ConfigLoaded = false
local CONFIG_PATH = 'config/xlifebar/%s.jx3dat'

function D.Init()
	CONFIG_DEFAULTS = setmetatable({
		DEFAULT  = LoadDefaultTemplate('default'),
		OFFICIAL = LoadDefaultTemplate('official'),
		CLEAR    = LoadDefaultTemplate('clear'),
		XLIFEBAR = LoadDefaultTemplate('xlifebar'),
	}, {
		__call = function(t, k, d)
			local template = t[k]
			return LIB.FormatDataStructure(d, template[1], true, template[2])
		end,
		__index = function(t, k) return t.DEFAULT end,
	})
	if not CONFIG_DEFAULTS.DEFAULT then
		return LIB.Debug(_L['MY_LifeBar'], _L['Default config cannot be loaded, please reinstall!!!'], DEBUG_LEVEL.ERROR)
	end
	Config = CONFIG_DEFAULTS('DEFAULT')
end

function D.GetConfigPath()
	return (CONFIG_PATH:format(MY_LifeBar.szConfig))
end

-- 根据玩家自定义界面缩放设置反向缩放 实现默认设置不受用户缩放影响
function D.AutoAdjustScale()
	local fUIScale = LIB.GetUIScale()
	if Config.fDesignUIScale ~= fUIScale then
		Config.fGlobalUIScale = Config.fGlobalUIScale * Config.fDesignUIScale / fUIScale
		Config.fDesignUIScale = fUIScale
	end
	local nFontOffset = Font.GetOffset()
	if Config.nDesignFontOffset ~= nFontOffset then
		Config.fTextScale = Config.fTextScale * LIB.GetFontScale(Config.nDesignFontOffset) / LIB.GetFontScale()
		Config.nDesignFontOffset = nFontOffset
	end
end

do
local function onUIScaled()
	if not ConfigLoaded then
		return
	end
	D.AutoAdjustScale()
	FireUIEvent('MY_LIFEBAR_CONFIG_UPDATE')
end
LIB.RegisterEvent('UI_SCALED', 'MY_LifeBar_Config', onUIScaled)
end

function D.LoadConfig(szConfig)
	if IsTable(szConfig) then
		Config = szConfig
		ConfigLoaded = true
	else
		if IsString(szConfig) then
			if MY_LifeBar.szConfig ~= szConfig then
				if ConfigLoaded then
					D.SaveConfig()
				end
				MY_LifeBar.szConfig = szConfig
			end
		end
		Config = LIB.LoadLUAData({ D.GetConfigPath(), PATH_TYPE.GLOBAL })
	end
	if Config and not Config.fDesignUIScale then -- 兼容老数据
		for _, key in ipairs({'ShowName', 'ShowTong', 'ShowTitle', 'ShowLife', 'ShowLifePer'}) do
			for _, relation in ipairs({'Self', 'Party', 'Enemy', 'Neutrality', 'Ally', 'Foe'}) do
				for _, tartype in ipairs({'Npc', 'Player'}) do
					if Config[key] and IsTable(Config[key][relation]) and IsBoolean(Config[key][relation][tartype]) then
						Config[key][relation][tartype] = { bEnable = Config[key][relation][tartype] }
					end
				end
			end
		end
		Config.fDesignUIScale = LIB.GetUIScale()
		Config.fMatchedFontOffset = Font.GetOffset()
	end
	Config = CONFIG_DEFAULTS('DEFAULT', Config)
	D.AutoAdjustScale()
	ConfigLoaded = true
	FireUIEvent('MY_LIFEBAR_CONFIG_LOADED')
end

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_LifeBar_Config', function()
	D.Init()
	D.LoadConfig()
end)

function D.SaveConfig()
	if not ConfigLoaded then
		return
	end
	LIB.SaveLUAData({ D.GetConfigPath(), PATH_TYPE.GLOBAL }, Config)
end
LIB.RegisterFlush(D.SaveConfig)

MY_LifeBar_Config = setmetatable({}, {
	__call = function(t, op, ...)
		local argc = select('#', ...)
		local argv = {...}
		if op == 'get' then
			local config = Config
			for i = 1, argc do
				if not IsTable(config) then
					return
				end
				config = config[argv[i]]
			end
			return config
		elseif op == 'set' then
			local config = Config
			for i = 1, argc - 2 do
				if not IsTable(config) then
					return
				end
				config = config[argv[i]]
			end
			if not IsTable(config) then
				return
			end
			config[argv[argc - 1]] = argv[argc]
		elseif op == 'reset' then
			if not argv[1] then
				MessageBox({
					szName = 'MY_LifeBar_Restore_Default',
					szAlignment = 'CENTER',
					szMessage = _L['Please choose your favorite lifebar style.\nYou can rechoose in setting panel.'],
					{
						szOption = _L['Official default style'],
						fnAction = function()
							D.LoadConfig(CONFIG_DEFAULTS('OFFICIAL'))
						end,
					},
					{
						szOption = _L['Official clear style'],
						fnAction = function()
							D.LoadConfig(CONFIG_DEFAULTS('CLEAR'))
						end,
					},
					{
						szOption = _L['XLifeBar style'],
						fnAction = function()
							D.LoadConfig(CONFIG_DEFAULTS('XLIFEBAR'))
						end,
					},
					{
						szOption = _L['Keep current'],
						fnAction = function()
							if Config.eCss == '' then
								Config.eCss = 'DEFAULT'
							end
						end,
					},
				})
			else
				D.LoadConfig(CONFIG_DEFAULTS(argv[1]))
			end
		elseif op == 'save' then
			return D.SaveConfig(...)
		elseif op == 'load' then
			return D.LoadConfig(...)
		elseif op == 'loaded' then
			return ConfigLoaded
		end
	end,
	__index = function(t, k) return Config[k] end,
	__newindex = function(t, k, v) Config[k] = v end,
})
