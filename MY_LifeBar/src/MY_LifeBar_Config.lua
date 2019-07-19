--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 扁平血条设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local EMPTY_TABLE, MENU_DIVIDER, XML_LINE_BREAKER = LIB.EMPTY_TABLE, LIB.MENU_DIVIDER, LIB.XML_LINE_BREAKER
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_LifeBar/lang/')
if not LIB.AssertVersion('MY_LifeBar', _L['MY_LifeBar'], 0x2012800) then
	return
end

local D = {}

do -- auto generate embedded data
for _, DAT_ROOT in ipairs({
	'MY_LifeBar/config/default/',
	'MY_LifeBar/config/official/',
	'MY_LifeBar/config/clear/',
	'MY_LifeBar/config/xlifebar/',
}) do
	local SRC_ROOT = LIB.FormatPath(PACKET_INFO.ROOT .. '!src-dist/dat/' .. DAT_ROOT)
	local DST_ROOT = LIB.FormatPath(PACKET_INFO.ROOT .. DAT_ROOT)
	for _, szFile in ipairs(CPath.GetFileList(SRC_ROOT)) do
		LIB.Sysmsg(_L['Compressing: '] .. DAT_ROOT .. szFile)
		local data = LoadDataFromFile(SRC_ROOT .. szFile)
		if IsEncodedData(data) then
			data = DecodeData(data)
		end
		data = EncodeData(data, true, true)
		SaveDataToFile(data, DST_ROOT .. szFile)
	end
end
end

local function LoadDefaultTemplate(szStyle)
	local template = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MY_LifeBar/config/' .. szStyle .. '/$lang.jx3dat')
	if not template then
		return
	end
	for _, dwForceID in pairs_c(FORCE_TYPE) do
		for _, szRelation in ipairs({ 'Self', 'Party', 'Enemy', 'Neutrality', 'Ally', 'Foe' }) do
			if not template[1].Color[szRelation].__VALUE__[dwForceID] then
				template[1].Color[szRelation].__VALUE__[dwForceID] = { LIB.GetForceColor(dwForceID, 'foreground') }
			end
		end
	end
	return template
end

local CONFIG_DEFAULTS = setmetatable({
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
	return LIB.Debug({_L['Default config cannot be loaded, please reinstall!!!']}, _L['MY_LifeBar'], DEBUG_LEVEL.ERROR)
end
local Config, ConfigLoaded = CONFIG_DEFAULTS('DEFAULT'), false
local CONFIG_PATH = 'config/xlifebar/%s.jx3dat'

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
LIB.RegisterEvent('UI_SCALED.MY_LifeBar_Config', onUIScaled)
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
LIB.RegisterInit('MY_LifeBar_Config', function() D.LoadConfig() end)

function D.SaveConfig()
	if not ConfigLoaded then
		return
	end
	LIB.SaveLUAData({ D.GetConfigPath(), PATH_TYPE.GLOBAL }, Config)
end
LIB.RegisterExit(D.SaveConfig)

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
