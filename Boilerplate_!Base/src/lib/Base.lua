--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 基础函数枚举
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-------------------------------------------------------------------------------------------------------
-- wstring 修正
-------------------------------------------------------------------------------------------------------
local wsub = _G.wstring.sub
local wstring = setmetatable({}, {
	__index = function(t, k)
		local v = _G.wstring[k]
		t[k] = v
		return v
	end,
})
wstring.find = StringFindW
wstring.sub = function(str, s, e)
	local nLen = wstring.len(str)
	if s < 0 then
		s = nLen + s + 1
	end
	if not e then
		e = nLen
	elseif e < 0 then
		e = nLen + e + 1
	end
	return wsub(str, s, e)
end
wstring.gsub = StringReplaceW
wstring.lower = StringLowerW
-------------------------------------------------------------------------------------------------------
-- 测试等级
-------------------------------------------------------------------------------------------------------
local DEBUG_LEVEL = SetmetaReadonly({
	PMLOG   = 0,
	LOG     = 1,
	WARNING = 2,
	ERROR   = 3,
	DEBUG   = 3,
	NONE    = 4,
})
-------------------------------------------------------------------------------------------------------
-- 游戏语言、游戏运营分支编码、游戏发行版编码、游戏版本号
-------------------------------------------------------------------------------------------------------
local _GAME_LANG_, _GAME_BRANCH_, _GAME_EDITION_, _GAME_VERSION_
local _GAME_PROVIDER_ = 'local'
do
	local szVersionLineFullName, szVersion, szVersionLineName, szVersionEx, szVersionName = GetVersion()
	_GAME_LANG_ = string.lower(szVersionLineName)
	if _GAME_LANG_ == 'classic' then
		_GAME_LANG_ = 'zhcn'
	end
	_GAME_BRANCH_ = string.lower(szVersionLineName)
	if _GAME_BRANCH_ == 'zhcn' then
		_GAME_BRANCH_ = 'remake'
	elseif _GAME_BRANCH_ == 'zhtw' then
		_GAME_BRANCH_ = 'intl'
	end
	_GAME_EDITION_ = string.lower(szVersionLineName .. '_' .. szVersionEx)
	_GAME_VERSION_ = string.lower(szVersion)

	if SM_IsEnable then
		local status, res = pcall(SM_IsEnable)
		if status and res then
			_GAME_PROVIDER_ = 'remote'
		end
	end
end
-------------------------------------------------------------------------------------------------------
-- 本地函数变量
-------------------------------------------------------------------------------------------------------
local _BUILD_                 = '19700101'
local _VERSION_               = '0.0.0'
local _MENU_COLOR_            = {255, 255, 255}
local _INTERFACE_ROOT_        = 'Interface/'
local _NAME_SPACE_            = 'Boilerplate'
local _ADDON_ROOT_            = _INTERFACE_ROOT_ .. _NAME_SPACE_ .. '/'
local _DATA_ROOT_             = (_GAME_PROVIDER_ == 'remote' and (GetUserDataFolder() .. '/' .. GetUserAccount() .. '/interface/') or _INTERFACE_ROOT_) .. _NAME_SPACE_ .. '#DATA/'
local _FRAMEWORK_ROOT_        = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_!Base/'
local _UICOMPONENT_ROOT_      = _FRAMEWORK_ROOT_ .. 'ui/components/'
local _LOGO_UITEX_            = _FRAMEWORK_ROOT_ .. 'img/Logo.UITex'
local _LOGO_MAIN_FRAME_       = 0
local _LOGO_MENU_FRAME_       = 1
local _LOGO_MENU_HOVER_FRAME_ = 2
local _POSTER_UITEX_          = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_Resource/img/Poster.UITex'
local _POSTER_FRAME_COUNT_    = 1
local _DEBUG_LEVEL_           = tonumber(LoadLUAData(_DATA_ROOT_ .. 'debug.level.jx3dat') or nil) or DEBUG_LEVEL.NONE
local _DELOG_LEVEL_           = tonumber(LoadLUAData(_DATA_ROOT_ .. 'delog.level.jx3dat') or nil) or DEBUG_LEVEL.NONE
-------------------------------------------------------------------------------------------------------
-- 其它环境变量
-------------------------------------------------------------------------------------------------------
local _SERVER_ADDRESS_ = select(7, GetUserServer())
local _RUNTIME_OPTIMIZE_ = (
	debug.traceback ~= nil
	and _DEBUG_LEVEL_ == DEBUG_LEVEL.NONE
	and _DELOG_LEVEL_ == DEBUG_LEVEL.NONE
	and not IsLocalFileExist(_ADDON_ROOT_ .. 'secret.jx3dat')
) and not IsLocalFileExist(_DATA_ROOT_ .. 'no.runtime.optimize.jx3dat')
-------------------------------------------------------------------------------------------------------
-- 初始化调试工具
-------------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 数据设为只读
-----------------------------------------------
local SetmetaReadonly = SetmetaReadonly
if not SetmetaReadonly then
	SetmetaReadonly = function(t)
		for k, v in pairs(t) do
			if type(v) == 'table' then
				t[k] = SetmetaReadonly(v)
			end
		end
		return setmetatable({}, {
			__index     = t,
			__newindex  = function() assert(false, 'table is readonly\n') end,
			__metatable = {
				const_table = t,
			},
		})
	end
end
local function SetmetaLazyload(t, _keyLoader, fallbackLoader)
	local keyLoader = {}
	for k, v in pairs(_keyLoader) do
		keyLoader[k] = v
	end
	return setmetatable(t, {
		__index = function(t, k)
			local loader = keyLoader[k]
			if loader then
				keyLoader[k] = nil
				if not next(keyLoader) then
					setmetatable(t, nil)
				end
			else
				loader = fallbackLoader
			end
			if loader then
				local v = loader(k)
				t[k] = v
				return v
			end
		end,
	})
end
local SHARED_MEMORY = _G.PLUGIN_SHARED_MEMORY
if type(SHARED_MEMORY) ~= 'table' then
	SHARED_MEMORY = {}
	_G.PLUGIN_SHARED_MEMORY = SHARED_MEMORY
end
---------------------------------------------------
-- 调试工具
---------------------------------------------------
local function ErrorLog(...)
	local aLine, xLine = {}, nil
	for i = 1, select('#', ...) do
		xLine = select(i, ...)
		aLine[i] = tostring(xLine)
	end
	local szFull = table.concat(aLine, '\n') .. '\n'
	Log('MSG_SYS', szFull)
	FireUIEvent('CALL_LUA_ERROR', szFull)
end
if _DEBUG_LEVEL_ < DEBUG_LEVEL.NONE then
	if not SHARED_MEMORY.ECHO_LUA_ERROR then
		RegisterEvent('CALL_LUA_ERROR', function()
			OutputMessage('MSG_SYS', 'CALL_LUA_ERROR:\n' .. arg0 .. '\n')
		end)
		SHARED_MEMORY.ECHO_LUA_ERROR = _NAME_SPACE_
	end
	if not SHARED_MEMORY.RELOAD_UI_ADDON then
		TraceButton_AppendAddonMenu({{
			szOption = 'ReloadUIAddon',
			fnAction = function()
				ReloadUIAddon()
			end,
		}})
		SHARED_MEMORY.RELOAD_UI_ADDON = _NAME_SPACE_
	end
end
Log('[' .. _NAME_SPACE_ .. '] Debug level ' .. _DEBUG_LEVEL_ .. ' / delog level ' .. _DELOG_LEVEL_)
-------------------------------------------------------------------------------------------------------
-- 加载语言包
-------------------------------------------------------------------------------------------------------
local function LoadLangPack(szLangFolder)
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_..'lang/default') or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_..'lang/' .. _GAME_LANG_) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
	if type(szLangFolder)=='string' then
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
local _L = LoadLangPack(_FRAMEWORK_ROOT_ .. 'lang/lib/')
local _NAME_             = _L.PLUGIN_NAME
local _SHORT_NAME_       = _L.PLUGIN_SHORT_NAME
local _AUTHOR_           = _L.PLUGIN_AUTHOR
local _AUTHOR_WEIBO_     = _L.PLUGIN_AUTHOR_WEIBO
local _AUTHOR_WEIBO_URL_ = 'https://weibo.com/'
local _AUTHOR_SIGNATURE_ = _L.PLUGIN_AUTHOR_SIGNATURE
local _AUTHOR_ROLES_     = {
}
local _AUTHOR_HEADER_ = GetFormatText(_NAME_ .. ' ' .. _L['[Author]'], 8, 89, 224, 232)
local _AUTHOR_PROTECT_NAMES_ = {
}
local _AUTHOR_FAKE_HEADER_ = GetFormatText(_L['[Fake author]'], 8, 255, 95, 159)
-------------------------------------------------------------------------------------------------------
-- 通用函数
-------------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 三元运算
-----------------------------------------------
local IIf = function(expr, truepart, falsepart)
	if expr then
		return truepart
	end
	return falsepart
end
-----------------------------------------------
-- 克隆数据
-----------------------------------------------
local function Clone(var)
	if type(var) == 'table' then
		local ret = {}
		for k, v in pairs(var) do
			ret[Clone(k)] = Clone(v)
		end
		return ret
	else
		return var
	end
end
-----------------------------------------------
-- Lua数据序列化
-----------------------------------------------
local EncodeLUAData = _G.var2str
-----------------------------------------------
-- Lua数据反序列化
-----------------------------------------------
local DecodeLUAData = _G.str2var or function(szText)
	local DECODE_ROOT = _DATA_ROOT_ .. '#cache/decode/'
	local DECODE_PATH = DECODE_ROOT .. GetCurrentTime() .. GetTime() .. math.random(0, 999999) .. '.jx3dat'
	CPath.MakeDir(DECODE_ROOT)
	SaveDataToFile(szText, DECODE_PATH)
	local data = LoadLUAData(DECODE_PATH)
	CPath.DelFile(DECODE_PATH)
	return data
end
-----------------------------------------------
-- 读取数据
-----------------------------------------------
local function Get(var, keys, dft)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		for _, k in ipairs(keys) do
			if type(var) == 'table' then
				var, res = var[k], true
			else
				var, res = dft, false
				break
			end
		end
	end
	if var == nil then
		var, res = dft, false
	end
	return var, res
end
-----------------------------------------------
-- 设置数据
-----------------------------------------------
local function Set(var, keys, val)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		local n = #keys
		for i = 1, n do
			local k = keys[i]
			if type(var) == 'table' then
				if i == n then
					var[k], res = val, true
				else
					if var[k] == nil then
						var[k] = {}
					end
					var = var[k]
				end
			else
				break
			end
		end
	end
	return res
end
-----------------------------------------------
-- 打包拆包数据
-----------------------------------------------
local Pack = type(table.pack) == 'function'
	and table.pack
	or function(...)
		return { n = select("#", ...), ... }
	end
local Unpack = type(table.unpack) == 'function'
	and table.unpack
	or unpack
-----------------------------------------------
-- 合并数据
-----------------------------------------------
local function Assign(t, ...)
	for index = 1, select('#', ...) do
		local t1 = select(index, ...)
		if type(t1) == 'table' then
			for k, v in pairs(t1) do
				t[k] = v
			end
		end
	end
	return t
end
-----------------------------------------------
-- 判断是否为空
-----------------------------------------------
local function IsEmpty(var)
	local szType = type(var)
	if szType == 'nil' then
		return true
	elseif szType == 'boolean' then
		return var
	elseif szType == 'number' then
		return var == 0
	elseif szType == 'string' then
		return var == ''
	elseif szType == 'function' then
		return false
	elseif szType == 'table' then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end
-----------------------------------------------
-- 深度判断相等
-----------------------------------------------
local function IsEquals(o1, o2)
	if o1 == o2 then
		return true
	elseif type(o1) ~= type(o2) then
		return false
	elseif type(o1) == 'table' then
		local t = {}
		for k, v in pairs(o1) do
			if IsEquals(o1[k], o2[k]) then
				t[k] = true
			else
				return false
			end
		end
		for k, v in pairs(o2) do
			if not t[k] then
				return false
			end
		end
		return true
	end
	return false
end
-----------------------------------------------
-- 数组随机
-----------------------------------------------
local function RandomChild(var)
	if type(var) == 'table' and #var > 0 then
		return var[math.random(1, #var)]
	end
end
-----------------------------------------------
-- 基础类型判断
-----------------------------------------------
local function IsArray(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return false
		end
		i = i + 1
	end
	return true
end
local function IsDictionary(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return true
		end
		i = i + 1
	end
	return false
end
local function IsNil     (var) return type(var) == 'nil'      end
local function IsTable   (var) return type(var) == 'table'    end
local function IsNumber  (var) return type(var) == 'number'   end
local function IsString  (var) return type(var) == 'string'   end
local function IsBoolean (var) return type(var) == 'boolean'  end
local function IsFunction(var) return type(var) == 'function' end
local function IsUserdata(var) return type(var) == 'userdata' end
local function IsHugeNumber(var) return IsNumber(var) and not (var < math.huge and var > -math.huge) end
local function IsElement(element) return type(element) == 'table' and element.IsValid and element:IsValid() or false end
-----------------------------------------------
-- 创建数据补丁
-----------------------------------------------
local function GetPatch(oBase, oData)
	-- dictionary patch
	if IsDictionary(oData) or (IsDictionary(oBase) and IsTable(oData) and IsEmpty(oData)) then
		-- dictionary raw value patch
		if not IsTable(oBase) then
			return { v = oData }
		end
		-- dictionary children patch
		local tKeys, bDiff = {}, false
		local oPatch = {}
		for k, v in pairs(oData) do
			local patch = GetPatch(oBase[k], v)
			if not IsNil(patch) then
				bDiff = true
				table.insert(oPatch, { k = k, v = patch })
			end
			tKeys[k] = true
		end
		for k, v in pairs(oBase) do
			if not tKeys[k] then
				bDiff = true
				table.insert(oPatch, { k = k, v = nil })
			end
		end
		if not bDiff then
			return nil
		end
		return oPatch
	end
	if not IsEquals(oBase, oData) then
		-- nil value patch
		if IsNil(oData) then
			return { t = 'nil' }
		end
		-- table value patch
		if IsTable(oData) then
			return { v = oData }
		end
		-- other patch value
		return oData
	end
	-- empty patch
	return nil
end
-----------------------------------------------
-- 数据应用补丁
-----------------------------------------------
local function ApplyPatch(oBase, oPatch, bNew)
	if bNew ~= false then
		oBase = Clone(oBase)
		oPatch = Clone(oPatch)
	end
	-- patch in dictionary type can only be a special value patch
	if IsDictionary(oPatch) then
		-- nil value patch
		if oPatch.t == 'nil' then
			return nil
		end
		-- raw value patch
		if not IsNil(oPatch.v) then
			return oPatch.v
		end
	end
	-- dictionary patch
	if IsTable(oPatch) and IsDictionary(oPatch[1]) then
		if not IsTable(oBase) then
			oBase = {}
		end
		for _, patch in ipairs(oPatch) do
			if IsNil(patch.v) then
				oBase[patch.k] = nil
			else
				oBase[patch.k] = ApplyPatch(oBase[patch.k], patch.v, false)
			end
		end
		return oBase
	end
	-- empty patch
	if IsNil(oPatch) then
		return oBase
	end
	-- other patch value
	return oPatch
end
-----------------------------------------------
-- 选代器 倒序
-----------------------------------------------
local ipairs_r
do
local function fnBpairs(tab, nIndex)
	nIndex = nIndex - 1
	if nIndex > 0 then
		return nIndex, tab[nIndex]
	end
end
function ipairs_r(tab)
	return fnBpairs, tab, #tab + 1
end
end
-----------------------------------------------
-- 只读表选代器
-----------------------------------------------
-- -- 只读表字典枚举
-- local pairs_c = pairs_c or function(t, ...)
-- 	if type(t) == 'table' then
-- 		local metatable = getmetatable(t)
-- 		if type(metatable) == 'table' and metatable.const_table then
-- 			return pairs(metatable.const_table, ...)
-- 		end
-- 	end
-- 	return pairs(t, ...)
-- end
-- -- 只读表数组枚举
-- local ipairs_c = ipairs_c or function(t, ...)
-- 	if type(t) == 'table' then
-- 		local metatable = getmetatable(t)
-- 		if type(metatable) == 'table' and metatable.const_table then
-- 			return ipairs(metatable.const_table, ...)
-- 		end
-- 	end
-- 	return ipairs(t, ...)
-- end
-----------------------------------------------
-- 类型安全选代器
-----------------------------------------------
local spairs, sipairs, spairs_r, sipairs_r
do
local function SafeIter(a, i)
	i = i + 1
	if a[i] then
		return i, a[i][1], a[i][2], a[i][3]
	end
end
function sipairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIter, iters, 0
end
function spairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIter, iters, 0
end
local function SafeIterR(a, i)
	i = i - 1
	if i > 0 then
		return i, a[i][1], a[i][2], a[i][3]
	end
end
function sipairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIterR, iters, #iters + 1
end
function spairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIterR, iters, #iters + 1
end
end
-----------------------------------------------
-- 类
-----------------------------------------------
local Class
do
local function createInstance(c, ins, ...)
	if not ins then
		ins = c
	end
	if c.ctor then
		c.ctor(ins, ...)
	end
	return c
end
function Class(className, super)
	local classPrototype
	if type(super) == 'string' then
		className, super = super, nil
	end
	if not className then
		className = 'Unnamed Class'
	end
	classPrototype = (function ()
		local proxys = {}
		if super then
			proxys.super = super
			setmetatable(proxys, { __index = super })
		end
		return setmetatable({}, {
			__index = proxys,
			__tostring = function(t) return className .. ' (class prototype)' end,
			__call = function (...)
				return createInstance(setmetatable({}, {
					__index = classPrototype,
					__tostring = function(t) return className .. ' (class instance)' end,
				}), nil, ...)
			end,
		})
	end)()
	return classPrototype
end
end
-----------------------------------------------
-- 获取调用栈
-----------------------------------------------
local function GetTraceback(str)
	local traceback = debug and debug.traceback and debug.traceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	if traceback then
		if str then
			str = str .. '\n' .. traceback
		else
			str = traceback
		end
	end
	return str or ''
end
-----------------------------------------------
-- 安全调用
-----------------------------------------------
local Call, XpCall
do
local xpAction, xpArgs, xpErrMsg, xpTraceback, xpErrLog
local function CallHandler()
	return xpAction(Unpack(xpArgs))
end
local function CallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	xpErrLog = (errMsg or '') .. '\n' .. xpTraceback
	Log(xpErrLog)
	FireUIEvent('CALL_LUA_ERROR', xpErrLog .. '\n')
end
local function XpCallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
end
function Call(arg0, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = arg0, Pack(...), nil, nil
	local res = Pack(xpcall(CallHandler, CallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return Unpack(res)
end
function XpCall(arg0, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = arg0, Pack(...), nil, nil
	local res = Pack(xpcall(CallHandler, XpCallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return Unpack(res)
end
end
local function SafeCall(f, ...)
	if not IsFunction(f) then
		return false, 'NOT CALLABLE'
	end
	return Call(f, ...)
end
local function CallWithThis(context, f, ...)
	local _this = this
	this = context
	local rtc = Pack(Call(f, ...))
	this = _this
	return Unpack(rtc)
end
local function SafeCallWithThis(context, f, ...)
	local _this = this
	this = context
	local rtc = Pack(SafeCall(f, ...))
	this = _this
	return Unpack(rtc)
end

local NSFormatString
do local CACHE = {}
function NSFormatString(s)
	if not CACHE[s] then
		CACHE[s] = wstring.gsub(s, '{$NS}', _NAME_SPACE_)
	end
	return CACHE[s]
end
end

local function GetGameAPI(szAddon, szInside)
	local api = _G[szAddon]
	if not api and _DEBUG_LEVEL_ < DEBUG_LEVEL.NONE then
		local env = GetInsideEnv()
		if env then
			api = env[szInside or szAddon]
		end
	end
	return api
end

local function GetGameTable(szTable, bPringError)
	local b, t = (bPringError and Call or pcall)(function() return g_tTable[szTable] end)
	if b then
		return t
	end
end
-----------------------------------------------
-- 插件集信息
-----------------------------------------------
local PACKET_INFO
do
local tInfo = {
	NAME                  = _NAME_                 ,
	SHORT_NAME            = _SHORT_NAME_           ,
	VERSION               = _VERSION_              ,
	BUILD                 = _BUILD_                ,
	NAME_SPACE            = _NAME_SPACE_           ,
	DEBUG_LEVEL           = _DEBUG_LEVEL_          ,
	DELOG_LEVEL           = _DELOG_LEVEL_          ,
	INTERFACE_ROOT        = _INTERFACE_ROOT_       ,
	ROOT                  = _ADDON_ROOT_           ,
	DATA_ROOT             = _DATA_ROOT_            ,
	FRAMEWORK_ROOT        = _FRAMEWORK_ROOT_       ,
	UICOMPONENT_ROOT      = _UICOMPONENT_ROOT_     ,
	LOGO_UITEX            = _LOGO_UITEX_           ,
	LOGO_MAIN_FRAME       = _LOGO_MAIN_FRAME_      ,
	LOGO_MENU_FRAME       = _LOGO_MENU_FRAME_      ,
	LOGO_MENU_HOVER_FRAME = _LOGO_MENU_HOVER_FRAME_,
	POSTER_UITEX          = _POSTER_UITEX_         ,
	POSTER_FRAME_COUNT    = _POSTER_FRAME_COUNT_   ,
	AUTHOR                = _AUTHOR_               ,
	AUTHOR_WEIBO          = _AUTHOR_WEIBO_         ,
	AUTHOR_WEIBO_URL      = _AUTHOR_WEIBO_URL_     ,
	AUTHOR_SIGNATURE      = _AUTHOR_SIGNATURE_     ,
	AUTHOR_ROLES          = _AUTHOR_ROLES_         ,
	AUTHOR_HEADER         = _AUTHOR_HEADER_        ,
	AUTHOR_PROTECT_NAMES  = _AUTHOR_PROTECT_NAMES_ ,
	AUTHOR_FAKE_HEADER    = _AUTHOR_FAKE_HEADER_   ,
	MENU_COLOR            = _MENU_COLOR_           ,
}
PACKET_INFO = SetmetaReadonly(tInfo)
end
-----------------------------------------------
-- 枚举
-----------------------------------------------
local function KvpToObject(kvp)
	local t = {}
	for _, v in ipairs(kvp) do
		if not IsNil(v[1]) then
			t[v[1]] = v[2]
		end
	end
	return t
end

local ENVIRONMENT = setmetatable({}, {
	__index = setmetatable({
		GAME_LANG        = _GAME_LANG_       ,
		GAME_BRANCH      = _GAME_BRANCH_     ,
		GAME_EDITION     = _GAME_EDITION_    ,
		GAME_VERSION     = _GAME_VERSION_    ,
		GAME_PROVIDER    = _GAME_PROVIDER_   ,
		SERVER_ADDRESS   = _SERVER_ADDRESS_  ,
		RUNTIME_OPTIMIZE = _RUNTIME_OPTIMIZE_,
	}, { __index = _G.GLOBAL }),
	__newindex = function() end,
})

local SECRET = setmetatable(LoadLUAData(_ADDON_ROOT_ .. 'secret.jx3dat') or {}, {
	__index = function(_, k) return k end,
})

local PATH_TYPE = SetmetaReadonly({
	NORMAL = 0,
	DATA   = 1,
	ROLE   = 2,
	GLOBAL = 3,
	SERVER = 4,
})

---------------------------------------------------------------------------------------------
local X = {
	UI               = {}              ,
	wstring          = wstring         ,
	count_c          = count_c         ,
	pairs_c          = pairs_c         ,
	ipairs_c         = ipairs_c        ,
	ipairs_r         = ipairs_r        ,
	spairs           = spairs          ,
	spairs_r         = spairs_r        ,
	sipairs          = sipairs         ,
	sipairs_r        = sipairs_r       ,
	IsArray          = IsArray         ,
	IsDictionary     = IsDictionary    ,
	IsEquals         = IsEquals        ,
	IsNil            = IsNil           ,
	IsBoolean        = IsBoolean       ,
	IsNumber         = IsNumber        ,
	IsUserdata       = IsUserdata      ,
	IsHugeNumber     = IsHugeNumber    ,
	IsElement        = IsElement       ,
	IsEmpty          = IsEmpty         ,
	IsString         = IsString        ,
	IsTable          = IsTable         ,
	IsFunction       = IsFunction      ,
	IIf              = IIf             ,
	Clone            = Clone           ,
	Call             = Call            ,
	XpCall           = XpCall          ,
	SafeCall         = SafeCall        ,
	CallWithThis     = CallWithThis    ,
	SafeCallWithThis = SafeCallWithThis,
	SetmetaReadonly  = SetmetaReadonly ,
	SetmetaLazyload  = SetmetaLazyload ,
	ErrorLog         = ErrorLog        ,
	Set              = Set             ,
	Get              = Get             ,
	Pack             = Pack            ,
	Unpack           = Unpack          ,
	Assign           = Assign          ,
	Class            = Class           ,
	GetPatch         = GetPatch        ,
	ApplyPatch       = ApplyPatch      ,
	EncodeLUAData    = EncodeLUAData   ,
	DecodeLUAData    = DecodeLUAData   ,
	RandomChild      = RandomChild     ,
	KvpToObject      = KvpToObject     ,
	GetTraceback     = GetTraceback    ,
	NSFormatString   = NSFormatString  ,
	GetGameAPI       = GetGameAPI      ,
	GetGameTable     = GetGameTable    ,
	LoadLangPack     = LoadLangPack    ,
	ENVIRONMENT      = ENVIRONMENT     ,
	SECRET           = SECRET          ,
	PATH_TYPE        = PATH_TYPE       ,
	DEBUG_LEVEL      = DEBUG_LEVEL     ,
	PACKET_INFO      = PACKET_INFO     ,
	SHARED_MEMORY    = SHARED_MEMORY   ,
}
_G[_NAME_SPACE_] = X
---------------------------------------------------------------------------------------------
