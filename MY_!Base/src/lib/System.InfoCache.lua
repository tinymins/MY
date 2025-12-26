--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 键值对文件分隔快速存储模块
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.InfoCache')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

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
	local IC = X.InfoCache('cache/PLAYER_INFO/{$server_origin}/TONG/<SEG>.{$lang}.jx3dat', 2, 3000)
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
function X.InfoCache(SZ_DATA_PATH, SEG_LEN, L1_SIZE, ValueComparer)
	if not ValueComparer then
		ValueComparer = DefaultValueComparer
	end
	local aCache, tCache = {}, setmetatable({}, { __mode = 'v' }) -- high speed L1 CACHE
	local tInfos, tInfoVisit, tInfoModified = {}, {}, {}
	return setmetatable({}, {
		__index = function(t, k)
			-- if hit in L1 CACHE
			if tCache[k] then
				-- X.Log('INFO CACHE L1 HIT ' .. k)
				return tCache[k]
			end
			-- read info from saved data
			local szSegID = table.concat({string.byte(k, 1, SEG_LEN)}, '-')
			if not tInfos[szSegID] then
				tInfos[szSegID] = X.LoadLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID))) or {}
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
			local szSegID = table.concat({string.byte(k, 1, SEG_LEN)}, '-')
			-- read from DataBase if L1 CACHE not hit
			if not tInfo then
				if not tInfos[szSegID] then
					tInfos[szSegID] = X.LoadLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID))) or {}
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
					table.remove(aCache, 1)
				end
				table.insert(aCache, v)
				tCache[k] = v
			end
			------------------
			-- update DataBase
			if bModified then
				-- save info to DataBase
				if not tInfos[szSegID] then
					tInfos[szSegID] = X.LoadLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID))) or {}
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
				local aSeg = {}
				for i = 1, SEG_LEN do
					table.insert(aSeg, 0)
				end
				while aSeg[SEG_LEN + 1] ~= 1 do
					local szSegID = table.concat(aSeg, '-')
					local szPath = SZ_DATA_PATH:gsub('<SEG>', szSegID)
					if IsFileExist(X.GetLUADataPath(szPath)) then
						X.SaveLUAData(szPath, nil)
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
							X.SaveLUAData((SZ_DATA_PATH:gsub('<SEG>', szSegID)), tInfos[szSegID])
						--[[#DEBUG BEGIN]]
						else
							X.OutputDebugMessage('InfoCache', 'INFO Unloaded: ' .. szSegID, X.DEBUG_LEVEL.LOG)
						--[[#DEBUG END]]
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
