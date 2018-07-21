---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-03-19 11:00:29
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-07-22 06:05:24
---------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
local _L, D = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/lang/'), {}
local CONFIG_DEFAULTS = setmetatable({
	DEFAULT  = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/config/default/$lang.jx3dat'),
	OFFICIAL = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/config/official/$lang.jx3dat'),
	CLEAR    = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/config/clear/$lang.jx3dat'),
	XLIFEBAR = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/config/xlifebar/$lang.jx3dat'),
}, { __index = function(t, k) return t.DEFAULT end })

if not CONFIG_DEFAULTS.DEFAULT then
    return MY.Debug({_L['Default config cannot be loaded, please reinstall!!!']}, _L['x lifebar'], MY_DEBUG.ERROR)
end
local Config, ConfigLoaded = clone(CONFIG_DEFAULTS.DEFAULT), false
local CONFIG_PATH = 'config/xlifebar/%s.jx3dat'

function D.GetConfigPath()
	return (CONFIG_PATH:format(MY_LifeBar.szConfig))
end

-- 根据玩家自定义界面缩放设置反向缩放 实现默认设置不受用户缩放影响
function D.AutoAdjustScale()
	local fUIScale = MY.GetOriginUIScale()
	if Config.fDesignUIScale ~= fUIScale then
		local fScale = Config.fDesignUIScale / fUIScale
		Config.fGlobalUIScale = Config.fGlobalUIScale * fScale
		Config.nTextLineHeight = floor(Config.nTextLineHeight * fScale + 0.5)
		Config.fDesignUIScale = fUIScale
	end
	local nFontOffset = Font.GetOffset()
	if Config.nDesignFontOffset ~= nFontOffset then
		local fScale = MY.GetFontScale(Config.nDesignFontOffset) / MY.GetFontScale()
		Config.nTextLineHeight = floor(Config.nTextLineHeight * fScale + 0.5)
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
MY.RegisterEvent('UI_SCALED.MY_LifeBar_Config', onUIScaled)
end

function D.LoadConfig(szConfig)
	if IsString(szConfig) then
		if MY_LifeBar.szConfig ~= szConfig then
			D.SaveConfig()
			MY_LifeBar.szConfig = szConfig
		end
		Config = MY.LoadLUAData({ D.GetConfigPath(), MY_DATA_PATH.GLOBAL })
	elseif IsTable(szConfig) then
		Config = szConfig
	end
	if Config and not Config.fDesignUIScale then -- 兼容老数据
		Config.fDesignUIScale = MY.GetOriginUIScale()
		Config.fMatchedFontOffset = Font.GetOffset()
	end
	Config = MY.FormatDataStructure(Config, CONFIG_DEFAULTS[Config and Config.eCss or ''], true)
	ConfigLoaded = true
	D.AutoAdjustScale()
	FireUIEvent('MY_LIFEBAR_CONFIG_LOADED')
end
MY.RegisterInit(D.LoadConfig)

function D.SaveConfig()
	if not ConfigLoaded then
		return
	end
	MY.SaveLUAData({ D.GetConfigPath(), MY_DATA_PATH.GLOBAL }, Config)
end
MY.RegisterExit(D.SaveConfig)

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
							D.LoadConfig(clone(CONFIG_DEFAULTS.OFFICIAL))
						end,
					},
					{
						szOption = _L['Official clear style'],
						fnAction = function()
							D.LoadConfig(clone(CONFIG_DEFAULTS.CLEAR))
						end,
					},
					{
						szOption = _L['XLifeBar style'],
						fnAction = function()
							D.LoadConfig(clone(CONFIG_DEFAULTS.XLIFEBAR))
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
				D.LoadConfig(clone(CONFIG_DEFAULTS[argv[1]]))
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
