--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : Base64 ´¦ÀíÄ£¿é
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-- Base64-encoding
-- Sourced from http://en.wikipedia.org/wiki/Base64
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
local LIB = Boilerplate
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
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------

local __author__ = 'Daniel Lindsley'
local __version__ = 'scm-1'
local __license__ = 'BSD'

local index_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function to_binary(integer)
	local remaining = tonumber(integer)
	local bin_bits = ''

	for i = 7, 0, -1 do
		local current_power = pow(2, i)

		if remaining >= current_power then
			bin_bits = bin_bits .. '1'
			remaining = remaining - current_power
		else
			bin_bits = bin_bits .. '0'
		end
	end

	return bin_bits
end

local function from_binary(bin_bits)
	return tonumber(bin_bits, 2)
end


local function to_base64(to_encode)
	local bit_pattern = ''
	local encoded = ''
	local trailing = ''

	for i = 1, len(to_encode) do
		bit_pattern = bit_pattern .. to_binary(byte(sub(to_encode, i, i)))
	end

	-- Check the number of bytes. If it's not evenly divisible by three,
	-- zero-pad the ending & append on the correct number of ``=``s.
	if mod(len(bit_pattern), 3) == 2 then
		trailing = '=='
		bit_pattern = bit_pattern .. '0000000000000000'
	elseif mod(len(bit_pattern), 3) == 1 then
		trailing = '='
		bit_pattern = bit_pattern .. '00000000'
	end

	for i = 1, len(bit_pattern), 6 do
		local byte = sub(bit_pattern, i, i+5)
		local offset = tonumber(from_binary(byte))
		encoded = encoded .. sub(index_table, offset+1, offset+1)
	end

	return sub(encoded, 1, -1 - len(trailing)) .. trailing
end


local function from_base64(to_decode)
	local padded = to_decode:gsub('%s', '')
	local unpadded = padded:gsub('=', '')
	local bit_pattern = ''
	local decoded = ''

	for i = 1, len(unpadded) do
		local char = sub(to_decode, i, i)
		local offset, _ = find(index_table, char)
		if offset == nil then
			error('Invalid character \'' .. char .. '\' found.')
		end

		bit_pattern = bit_pattern .. sub(to_binary(offset-1), 3)
	end

	for i = 1, len(bit_pattern), 8 do
		local byte = sub(bit_pattern, i, i+7)
		decoded = decoded .. char(from_binary(byte))
	end

	local padding_length = padded:len()-unpadded:len()

	if (padding_length == 1 or padding_length == 2) then
		decoded = decoded:sub(1,-2)
	end
	return decoded
end

LIB.Base64Encode = to_base64
LIB.Base64Decode = from_base64
