--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·颜色
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Color')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
function X.Hex2RGB(hex)
	local s, r, g, b, a = hex:gsub('#', ''), nil, nil, nil, nil
	if #s == 3 then
		r, g, b = s:sub(1, 1):rep(2), s:sub(2, 2):rep(2), s:sub(3, 3):rep(2)
	elseif #s == 4 then
		r, g, b, a = s:sub(1, 1):rep(2), s:sub(2, 2):rep(2), s:sub(3, 3):rep(2), s:sub(4, 4):rep(2)
	elseif #s == 6 then
		r, g, b = s:sub(1, 2), s:sub(3, 4), s:sub(5, 6)
	elseif #s == 8 then
		r, g, b, a = s:sub(1, 2), s:sub(3, 4), s:sub(5, 6), s:sub(7, 8)
	end

	if not r or not g or not b then
		return
	end
	if a then
		a = tonumber('0x' .. a)
	end
	r, g, b = tonumber('0x' .. r), tonumber('0x' .. g), tonumber('0x' .. b)

	if not r or not g or not b then
		return
	end
	return r, g, b, a
end

function X.RGB2Hex(r, g, b, a)
	if a then
		return (('#%02X%02X%02X%02X'):format(r, g, b, a))
	end
	return (('#%02X%02X%02X'):format(r, g, b))
end

local COLOR_NAME_RGB = {}
do
	local aColor = X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/colors/{$lang}.jx3dat')
	for szColor, aKey in ipairs(aColor) do
		local nR, nG, nB = X.Hex2RGB(szColor)
		if nR then
			for _, szKey in ipairs(aKey) do
				COLOR_NAME_RGB[szKey] = {nR, nG, nB}
			end
		end
	end
end

function X.ColorName2RGB(name)
	if not COLOR_NAME_RGB[name] then
		return
	end
	return X.Unpack(COLOR_NAME_RGB[name])
end

local HUMAN_COLOR_CACHE = setmetatable({}, {__mode = 'v', __index = COLOR_NAME_RGB})
function X.HumanColor2RGB(name)
	if X.IsTable(name) then
		if name.r then
			return name.r, name.g, name.b
		end
		return X.Unpack(name)
	end
	if not HUMAN_COLOR_CACHE[name] then
		local r, g, b, a = X.Hex2RGB(name)
		HUMAN_COLOR_CACHE[name] = {r, g, b, a}
	end
	return X.Unpack(HUMAN_COLOR_CACHE[name])
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
