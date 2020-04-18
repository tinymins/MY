--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Base64 处理模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-- Base64-encoding
-- Sourced from http://en.wikipedia.org/wiki/Base64
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------

local __author__ = 'Daniel Lindsley'
local __version__ = 'scm-1'
local __license__ = 'BSD'

local index_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function to_binary(integer)
	local remaining = tonumber(integer)
	local bin_bits = ''

	for i = 7, 0, -1 do
		local current_power = math.pow(2, i)

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

	for i = 1, string.len(to_encode) do
		bit_pattern = bit_pattern .. to_binary(string.byte(string.sub(to_encode, i, i)))
	end

	-- Check the number of bytes. If it's not evenly divisible by three,
	-- zero-pad the ending & append on the correct number of ``=``s.
	if math.mod(string.len(bit_pattern), 3) == 2 then
		trailing = '=='
		bit_pattern = bit_pattern .. '0000000000000000'
	elseif math.mod(string.len(bit_pattern), 3) == 1 then
		trailing = '='
		bit_pattern = bit_pattern .. '00000000'
	end

	for i = 1, string.len(bit_pattern), 6 do
		local byte = string.sub(bit_pattern, i, i+5)
		local offset = tonumber(from_binary(byte))
		encoded = encoded .. string.sub(index_table, offset+1, offset+1)
	end

	return string.sub(encoded, 1, -1 - string.len(trailing)) .. trailing
end


local function from_base64(to_decode)
	local padded = to_decode:gsub('%s', '')
	local unpadded = padded:gsub('=', '')
	local bit_pattern = ''
	local decoded = ''

	for i = 1, string.len(unpadded) do
		local char = string.sub(to_decode, i, i)
		local offset, _ = string.find(index_table, char)
		if offset == nil then
			error('Invalid character \'' .. char .. '\' found.')
		end

		bit_pattern = bit_pattern .. string.sub(to_binary(offset-1), 3)
	end

	for i = 1, string.len(bit_pattern), 8 do
		local byte = string.sub(bit_pattern, i, i+7)
		decoded = decoded .. string.char(from_binary(byte))
	end

	local padding_length = padded:len()-unpadded:len()

	if (padding_length == 1 or padding_length == 2) then
		decoded = decoded:sub(1,-2)
	end
	return decoded
end

LIB.Base64Encode = to_base64
LIB.Base64Decode = from_base64
