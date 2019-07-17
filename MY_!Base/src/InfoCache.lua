--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 键值对文件分隔快速存储模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local ipairs_r = LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNumber, IsHugeNumber = LIB.IsNumber, LIB.IsHugeNumber
local IsNil, IsBoolean, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------

local function DefaultValueComparer(v1, v2)
	if v1 == v2 then
		return 0
	else
		return 1
	end
end

--[[
Sample:
	------------------
	-- Get an instance
	local IC = LIB.InfoCache('cache/PLAYER_INFO/$relserver/TONG/<SEG>.$lang.jx3dat', 2, 3000)
	--------------------
	-- Setter and Getter
	-- Set value
	IC['Test'] = 'this is a demo'
	-- Get value
	print(IC['Test'])
	-------------
	-- Management
	IC('save')                 -- Save to DB
	IC('save', 6000)           -- Save to DB with a max unvisited time
	IC('save', nil, 5)         -- Save to DB with a max saving len
	IC('save', nil, nil, true) -- Save to DB and release memory
	IC('save', 6000, 5, true)  -- Save to DB with a max unvisited time and a max saving len and release memory
	IC('clear')                -- Delete all data
]]
function LIB.InfoCache(SZ_DATA_PATH, SEG_LEN, L1_SIZE, ValueComparer)
	if not ValueComparer then
		ValueComparer = DefaultValueComparer
	end
	local aCache, tCache = {}, setmetatable({}, { __mode = 'v' }) -- high speed L1 CACHE
	local tInfos, tInfoVisit, tInfoModified = {}, {}, {}
	return setmetatable({}, {
		__index = function(t, k)
			-- if hit in L1 CACHE
			if tCache[k] then
				-- Log('INFO CACHE L1 HIT ' .. k)
				return tCache[k]
			end
			-- read info from saved data
			local szSegID = concat({byte(k, 1, SEG_LEN)}, '-')
			if not tInfos[szSegID] then
				tInfos[szSegID] = LIB.LoadLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID))) or {}
			end
			tInfoVisit[szSegID] = GetTime()
			return tInfos[szSegID][k]
		end,
		__newindex = function(t, k, v)
			local bModified
			------------------------------------------------------
			-- judge if info has been updated and need to be saved
			-- read from L1 CACHE
			local tInfo = tCache[k]
			local szSegID = concat({byte(k, 1, SEG_LEN)}, '-')
			 -- read from DataBase if L1 CACHE not hit
			if not tInfo then
				if not tInfos[szSegID] then
					tInfos[szSegID] = LIB.LoadLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID))) or {}
				end
				tInfo = tInfos[szSegID][k]
				tInfoVisit[szSegID] = GetTime()
			end
			-- judge data
			if tInfo then
				bModified = ValueComparer(v, tInfo) ~= 0
			else
				bModified = true
			end
			------------
			-- save info
			-- update L1 CACHE
			if bModified or not tCache[k] then
				if #aCache > L1_SIZE then
					remove(aCache, 1)
				end
				insert(aCache, v)
				tCache[k] = v
			end
			------------------
			-- update DataBase
			if bModified then
				-- save info to DataBase
				if not tInfos[szSegID] then
					tInfos[szSegID] = LIB.LoadLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID))) or {}
				end
				tInfos[szSegID][k] = v
				tInfoVisit[szSegID] = GetTime()
				tInfoModified[szSegID] = GetTime()
			end
		end,
		__call = function(t, cmd, arg0, arg1, ...)
			if cmd == 'clear' then
				-- clear all data file
				tInfos, tInfoVisit, tInfoModified = {}, {}, {}
				tName2ID, tName2IDModified = {}, {}
				local aSeg = {}
				for i = 1, SEG_LEN do
					insert(aSeg, 0)
				end
				while aSeg[SEG_LEN + 1] ~= 1 do
					local szSegID = concat(aSeg, '-')
					local szPath = SZ_DATA_PATH:gsub('<SEG>', szSegID)
					if IsFileExist(LIB.GetLUADataPath(szPath)) then
						LIB.SaveLUAData(szPath, nil)
						-- Log('INFO CACHE CLEAR @' .. szSegID)
					end
					-- bit add one
					local i = 1
					aSeg[i] = (aSeg[i] or 0) + 1
					while aSeg[i] == 256 do
						aSeg[i] = 0
						i = i + 1
						aSeg[i] = (aSeg[i] or 0) + 1
					end
				end
			elseif cmd == 'save' then -- save data to db, if nCount has been set and data saving reach the max, fn will return true
				local dwTime = arg0
				local nCount = arg1
				local bCollect = arg2
				-- save info data
				for szSegID, dwLastVisitTime in pairs(tInfoVisit) do
					if not dwTime or dwTime > dwLastVisitTime then
						if nCount then
							if nCount == 0 then
								return true
							end
							nCount = nCount - 1
						end
						if tInfoModified[szSegID] then
							LIB.SaveLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID)), tInfos[szSegID])
						else
							LIB.Debug({'INFO Unloaded: ' .. szSegID}, 'InfoCache', DEBUG_LEVEL.LOG)
						end
						if bCollect then
							tInfos[szSegID] = nil
						end
						tInfoVisit[szSegID] = nil
						tInfoModified[szSegID] = nil
					end
				end
			end
		end
	})
end
