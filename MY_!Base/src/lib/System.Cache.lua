--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·缓存
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Cache')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-----------------------------------------------
-- 事件驱动自动回收的缓存机制
-----------------------------------------------
function X.CreateCache(szName, szMode, aEvent)
	-- 处理参数
	if X.IsString(aEvent) then
		aEvent = {aEvent}
	elseif X.IsArray(aEvent) then
		aEvent = X.Clone(aEvent)
	else
		aEvent = {'LOADING_ENDING'}
	end
	local szKey = 'LIB#CACHE#' .. tostring(aEvent):sub(8)
	if szName then
		szKey = szKey .. '#' .. szName
	end
	-- 创建弱表以及事件驱动
	local t = {}
	local mt = { __mode = szMode }
	local function Flush()
		for k, _ in pairs(t) do
			t[k] = nil
		end
	end
	local function Register()
		for _, szEvent in ipairs(aEvent) do
			X.RegisterEvent(szEvent, szKey, Flush)
		end
	end
	local function Unregister()
		for _, szEvent in ipairs(aEvent) do
			X.RegisterEvent(szEvent, szKey, false)
		end
	end
	function mt.__call(_, k)
		if k == 'flush' then
			Flush()
		elseif k == 'register' then
			Register()
		elseif k == 'unregister' then
			Unregister()
		end
	end
	Register()
	return setmetatable(t, mt)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
