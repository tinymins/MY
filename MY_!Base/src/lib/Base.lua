--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 插件命名空间初始化
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------

-- 游戏语言、游戏运营分支编码、游戏发行版编码、游戏版本号、游戏运行方式
local szVersion, szVersionLineName, szVersionEx = select(2, GetVersion())
-- 游戏语言
local _GAME_LANG_ = string.lower(szVersionLineName)
if _GAME_LANG_ == 'classic' then
	_GAME_LANG_ = 'zhcn'
end
-- 游戏运营分支编码
local _GAME_BRANCH_ = string.lower(szVersionLineName)
if _GAME_BRANCH_ == 'zhcn' then
	_GAME_BRANCH_ = 'remake'
elseif _GAME_BRANCH_ == 'zhtw' then
	_GAME_BRANCH_ = 'intl'
end
-- 游戏发行版编码
local _GAME_EDITION_ = string.lower(szVersionLineName .. '_' .. szVersionEx)
-- 游戏版本号
local _GAME_VERSION_ = string.lower(szVersion)
-- 游戏运行方式，本地、云端
local _GAME_PROVIDER_ = 'local'
if SM_IsEnable then
	local status, res = pcall(SM_IsEnable)
	if status and res then
		_GAME_PROVIDER_ = 'remote'
	end
end

local DEBUG_LEVEL = {
	PM_LOG  = 0,
	LOG     = 1,
	WARNING = 2,
	ERROR   = 3,
	DEBUG   = 3,
	NONE    = 4,
}

local _NAME_SPACE_            = 'MY'
local _BUILD_                 = '20230821'
local _VERSION_               = '16.2.0'
local _MENU_COLOR_            = {255, 165, 79}
local _INTERFACE_ROOT_        = 'Interface/'
local _ADDON_ROOT_            = _INTERFACE_ROOT_ .. _NAME_SPACE_ .. '/'
local _DATA_ROOT_             = (_GAME_PROVIDER_ == 'remote' and (GetUserDataFolder() .. '/' .. GetUserAccount() .. '/interface/') or _INTERFACE_ROOT_) .. _NAME_SPACE_ .. '#DATA/'
local _FRAMEWORK_ROOT_        = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_!Base/'
local _UI_COMPONENT_ROOT_     = _FRAMEWORK_ROOT_ .. 'ui/components/'
local _LOGO_UITEX_            = _FRAMEWORK_ROOT_ .. 'img/Logo.UITex'
local _LOGO_MAIN_FRAME_       = 0
local _LOGO_MENU_FRAME_       = 1
local _LOGO_MENU_HOVER_FRAME_ = 2
local _POSTER_UITEX_          = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_Resource/img/Poster.UITex'
local _POSTER_FRAME_COUNT_    = 2
local _DEBUG_LEVEL_           = DEBUG_LEVEL[LoadLUAData(_DATA_ROOT_ .. 'debug.level.jx3dat') or 'NONE'] or DEBUG_LEVEL.NONE
local _LOG_LEVEL_             = math.min(DEBUG_LEVEL[LoadLUAData(_DATA_ROOT_ .. 'log.level.jx3dat') or 'ERROR'] or DEBUG_LEVEL.ERROR, _DEBUG_LEVEL_)

-- 创建命名空间
local X = {
	UI = {},
	DEBUG_LEVEL = DEBUG_LEVEL,
	PATH_TYPE = {
		NORMAL = 0,
		DATA   = 1,
		ROLE   = 2,
		GLOBAL = 3,
		SERVER = 4,
	},
	PACKET_INFO = {
		NAME_SPACE            = _NAME_SPACE_           ,
		VERSION               = _VERSION_              ,
		BUILD                 = _BUILD_                ,
		MENU_COLOR            = _MENU_COLOR_           ,
		INTERFACE_ROOT        = _INTERFACE_ROOT_       ,
		ROOT                  = _ADDON_ROOT_           ,
		DATA_ROOT             = _DATA_ROOT_            ,
		FRAMEWORK_ROOT        = _FRAMEWORK_ROOT_       ,
		UI_COMPONENT_ROOT     = _UI_COMPONENT_ROOT_    ,
		LOGO_UITEX            = _LOGO_UITEX_           ,
		LOGO_MAIN_FRAME       = _LOGO_MAIN_FRAME_      ,
		LOGO_MENU_FRAME       = _LOGO_MENU_FRAME_      ,
		LOGO_MENU_HOVER_FRAME = _LOGO_MENU_HOVER_FRAME_,
		POSTER_UITEX          = _POSTER_UITEX_         ,
		POSTER_FRAME_COUNT    = _POSTER_FRAME_COUNT_   ,
		DEBUG_LEVEL           = _DEBUG_LEVEL_          ,
		LOG_LEVEL             = _LOG_LEVEL_            ,
	},
	ENVIRONMENT = setmetatable({}, {
		__index = setmetatable({
			GAME_LANG = _GAME_LANG_,
			GAME_BRANCH = _GAME_BRANCH_,
			GAME_EDITION = _GAME_EDITION_,
			GAME_VERSION = _GAME_VERSION_,
			GAME_PROVIDER = _GAME_PROVIDER_,
			SERVER_ADDRESS = select(7, GetUserServer()),
			RUNTIME_OPTIMIZE = --[[#DEBUG BEGIN]](
				(IsDebugClient() or debug.traceback ~= nil)
					and _DEBUG_LEVEL_ == DEBUG_LEVEL.NONE
					and _LOG_LEVEL_ == DEBUG_LEVEL.NONE
					and not IsLocalFileExist(_ADDON_ROOT_ .. 'secret.jx3dat')
				) and not IsLocalFileExist(_DATA_ROOT_ .. 'no.runtime.optimize.jx3dat')
					and true
					or --[[#DEBUG END]]false,
		}, { __index = GLOBAL }),
		__newindex = function() end,
	}),
	SECRET = setmetatable(LoadLUAData(_ADDON_ROOT_ .. 'secret.jx3dat') or {}, {
		__index = function(_, k) return k end,
	}),
	SHARED_MEMORY = PLUGIN_SHARED_MEMORY,
}

-- 共享内存
if type(X.SHARED_MEMORY) ~= 'table' then
	X.SHARED_MEMORY = {}
	PLUGIN_SHARED_MEMORY = X.SHARED_MEMORY
end

local NS_FORMAT_STRING_CACHE = {}

-- 格式化命名空间模板字符串
---@param s string @需要格式化的字符串
---@return string @格式化后的字符串
function X.NSFormatString(s)
	if not NS_FORMAT_STRING_CACHE[s] then
		NS_FORMAT_STRING_CACHE[s] = StringReplaceW(s, '{$NS}', _NAME_SPACE_)
	end
	return NS_FORMAT_STRING_CACHE[s]
end

-- 加载语言包
---@param szLangFolder string @语言包文件夹
---@return table<string, any> @语言包
function X.LoadLangPack(szLangFolder)
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_ .. 'lang/default') or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_ .. 'lang/' .. _GAME_LANG_) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
	if type(szLangFolder) == 'string' then
		szLangFolder = string.gsub(szLangFolder,'[/\\]+$','')
		local t2 = LoadLUAData(szLangFolder..'/default') or {}
		for k, v in pairs(t2) do
			t0[k] = v
		end
		local t3 = LoadLUAData(szLangFolder..'/' .. _GAME_LANG_) or {}
		for k, v in pairs(t3) do
			t0[k] = v
		end
	end
	setmetatable(t0, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return t0
end

local _L = X.LoadLangPack(_FRAMEWORK_ROOT_ .. 'lang/lib/')

X.PACKET_INFO.NAME                  = _L.PLUGIN_NAME
X.PACKET_INFO.SHORT_NAME            = _L.PLUGIN_SHORT_NAME
X.PACKET_INFO.AUTHOR                = _L.PLUGIN_AUTHOR
X.PACKET_INFO.AUTHOR_FEEDBACK       = _L.PLUGIN_AUTHOR_FEEDBACK
X.PACKET_INFO.AUTHOR_FEEDBACK_URL   = _L.PLUGIN_AUTHOR_FEEDBACK_URL
X.PACKET_INFO.AUTHOR_SIGNATURE      = _L.PLUGIN_AUTHOR_SIGNATURE
X.PACKET_INFO.AUTHOR_HEADER         = GetFormatText(_L.PLUGIN_NAME .. ' ' .. _L['[Author]'], 8, 89, 224, 232)
X.PACKET_INFO.AUTHOR_FAKE_HEADER    = GetFormatText(_L['[Fake author]'], 8, 255, 95, 159)
X.PACKET_INFO.AUTHOR_ROLES          = {
	[ 3007396] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 梦江南
	[28564812] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- 茗伊伊 梦江南
	[ 1600498] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 追风蹑影
	[ 4664780] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 日月明尊
	[17796954] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0x40, 0xB0, 0xD7, 0xB5, 0xDB, 0xB3, 0xC7), -- 茗伊@白帝城 梦江南
	[  385183] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A), -- 茗伊 傲血戰意
	[ 1452025] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A), -- 茗伊伊 巔峰再起
	[    1028] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 缘起稻香@缘起一区
	[     660] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 梦回长安@缘起一区
	[     280] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 烟雨扬州@缘起一区
	[     143] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 神都洛阳@缘起一区
	[    1259] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 天宝盛世@缘起一区
}
X.PACKET_INFO.AUTHOR_PROTECT_NAMES  = {
	[string.char(0xDC, 0xF8, 0xD2, 0xC1)] = true, -- 简体
	[string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1)] = true, -- 简体
	[string.char(0XE8, 0X8C, 0X97, 0XE4, 0XBC, 0X8A)] = true, -- 繁体
	[string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A)] = true, -- 繁体
}

-- 导出命名空间
MY = X
