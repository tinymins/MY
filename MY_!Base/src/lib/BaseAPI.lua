--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏通用函数
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------

-- Lua 数据序列化
---@overload fun(data: any, indent: string, level: number): string
---@param data any @要序列化的数据
---@param indent string @缩进字符串
---@param level number @当前层级
---@return string @序列化后的字符串
X.EncodeLUAData = _G.var2str

-- Lua 数据反序列化
---@overload fun(data: string): any
---@param data string @要反序列化的字符串
---@return any @反序列化后的数据
X.DecodeLUAData = _G.str2var or function(szText)
	local DECODE_ROOT = X.PACKET_INFO.DATA_ROOT .. '#cache/decode/'
	local DECODE_PATH = DECODE_ROOT .. GetCurrentTime() .. GetTime() .. math.random(0, 999999) .. '.jx3dat'
	CPath.MakeDir(DECODE_ROOT)
	SaveDataToFile(szText, DECODE_PATH)
	local data = LoadLUAData(DECODE_PATH)
	CPath.DelFile(DECODE_PATH)
	return data
end

-- 获取游戏接口
---@param szAddon string @接口导出名称
---@param szInside string @接口原始名称
---@return any @接口对象
function X.GetGameAPI(szAddon, szInside)
	local api = _G[szAddon]
	if not api and _DEBUG_LEVEL_ < X.DEBUG_LEVEL.NONE then
		local env = GetInsideEnv()
		if env then
			api = env[szInside or szAddon]
		end
	end
	return api
end

-- 获取游戏数据表
---@param szTable string @数据表名称
---@param bPrintError boolean @是否打印错误信息
---@return any @数据表对象
function X.GetGameTable(szTable, bPrintError)
	local b, t = (bPrintError and X.Call or pcall)(function() return g_tTable[szTable] end)
	if b then
		return t
	end
end

local LOG_MAX_FILE = 30
local LOG_MAX_LINE = 5000
local LOG_LINE_COUNT = 0
local LOG_CACHE
local LOG_PATH, LOG_DATE
local LOG_TAG = (GetCurrentTime() - 8 * 60 * 60) % (24 * 60 * 60)

-- 输出一条日志到日志文件
---@vararg string 日志分类层级1, 日志分类层级2, 日志分类层级3, ..., 日志分类层级n, 日志内容
function X.Log(...)
	local nType = select('#', ...) - 1
	local szText = select(nType + 1, ...)
	local tTime = TimeToDate(GetCurrentTime())
	local szDate = string.format('%04d-%02d-%02d', tTime.year, tTime.month, tTime.day)
	local szType = ''
	for i = 1, nType do
		szType = szType .. '[' .. select(i, ...) .. ']'
	end
	if szType ~= '' then
		szType = szType .. ' '
	end
	local szLog = string.format('%04d/%02d/%02d_%02d:%02d:%02d %s%s\n', tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second, szType, szText)
	if LOG_DATE ~= szDate or LOG_LINE_COUNT >= LOG_MAX_LINE then
		-- 系统未初始化完成，加入缓存数组等待写入
		if not X.GetPlayerGUID or not X.GetPlayerGUID() then
			if not LOG_CACHE then
				LOG_CACHE = {}
			end
			table.insert(LOG_CACHE, szLog)
			return
		end
		if LOG_PATH then
			Log(LOG_PATH, '', 'close')
		end
		LOG_PATH = X.FormatPath({
			'logs/'
				.. szDate .. '/JX3_'
				.. X.PACKET_INFO.NAME_SPACE
				.. '_' .. X.ENVIRONMENT.GAME_PROVIDER
				.. '_' .. X.ENVIRONMENT.GAME_EDITION
				.. '_' .. X.ENVIRONMENT.GAME_VERSION
				.. '_' .. LOG_TAG
				.. '_' .. string.format('%04d-%02d-%02d_%02d-%02d-%02d', tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
				.. '.log',
			X.PATH_TYPE.ROLE
		})
		LOG_DATE = szDate
		LOG_LINE_COUNT = 0
	end
	-- 如果存在缓存数据，先处理
	if LOG_CACHE then
		for _, szLog in ipairs(LOG_CACHE) do
			Log(LOG_PATH, szLog)
			LOG_LINE_COUNT = LOG_LINE_COUNT + 1
		end
		LOG_CACHE = nil
	end
	LOG_LINE_COUNT = LOG_LINE_COUNT + 1
	Log(LOG_PATH, szLog, 'close')
end

-- 清理日志文件
function X.DeleteAncientLogs()
	local szRoot = X.FormatPath({'logs/', X.PATH_TYPE.ROLE})
	local aFiles = {}
	for _, filename in ipairs(CPath.GetFileList(szRoot)) do
		local year, month, day = filename:match('^(%d+)%-(%d+)%-(%d+)$')
		if year then
			year = tonumber(year)
			month = tonumber(month)
			day = tonumber(day)
			table.insert(aFiles, { time = DateToTime(year, month, day, 0, 0, 0), filepath = szRoot .. filename })
		end
	end
	if #aFiles <= LOG_MAX_FILE then
		return
	end
	table.sort(aFiles, function(a, b)
		return a.time > b.time
	end)
	for i = LOG_MAX_FILE + 1, #aFiles do
		CPath.DelDir(aFiles[i].filepath)
	end
end

-- 产生一个错误堆栈日志并发起事件
---@vararg string @错误信息行文本
---@return void
function X.ErrorLog(...)
	local aLine, xLine = {}, nil
	for i = 1, select('#', ...) do
		xLine = select(i, ...)
		aLine[i] = tostring(xLine)
	end
	local szFull = table.concat(aLine, '\n') .. '\n'
	FireUIEvent('CALL_LUA_ERROR', szFull)
end

--[[#DEBUG BEGIN]]
local MODULE_TIME = {}
RegisterEvent('LOADING_END', function()
	for szModule, _ in pairs(MODULE_TIME) do
		X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" missing log finish!!!')
	end
end)
--[[#DEBUG END]]
-- 脚本加载性能监控
---@param szModule string @模块名称
---@param szStatus "'START'" | "'FINISH'" @加载状态
---@return void
function X.ReportModuleLoading(szModule, szStatus)
	--[[#DEBUG BEGIN]]
	if szStatus == 'START' then
		if MODULE_TIME[szModule] then
			X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" is already loading!!!')
		else
			MODULE_TIME[szModule] = GetTime()
		end
	elseif szStatus == 'FINISH' then
		if MODULE_TIME[szModule] then
			X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" loaded during ' .. (GetTime() - MODULE_TIME[szModule]) .. 'ms.')
			MODULE_TIME[szModule] = nil
		else
			X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" not exist!!!')
		end
	end
	--[[#DEBUG END]]
end

-- 初始化调试工具
if X.PACKET_INFO.DEBUG_LEVEL < X.DEBUG_LEVEL.NONE then
	if not X.SHARED_MEMORY.ECHO_LUA_ERROR then
		RegisterEvent('CALL_LUA_ERROR', function()
			OutputMessage('MSG_SYS', 'CALL_LUA_ERROR:\n' .. arg0 .. '\n')
		end)
		X.SHARED_MEMORY.ECHO_LUA_ERROR = X.PACKET_INFO.NAME_SPACE
	end
	if not X.SHARED_MEMORY.RELOAD_UI_ADDON then
		TraceButton_AppendAddonMenu({{
			szOption = 'ReloadUIAddon',
			fnAction = function()
				ReloadUIAddon()
			end,
		}})
		X.SHARED_MEMORY.RELOAD_UI_ADDON = X.PACKET_INFO.NAME_SPACE
	end
end
X.Log('[' .. X.PACKET_INFO.NAME_SPACE .. '] Debug level ' .. X.PACKET_INFO.DEBUG_LEVEL .. ' / delog level ' .. X.PACKET_INFO.DELOG_LEVEL)
