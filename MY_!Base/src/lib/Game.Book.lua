--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Book')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 映射： 套书ID/名称 => 子书籍ID列表；书籍名称 => 书籍ID
local BOOK_SEGMENT_RECIPE = setmetatable({}, {
	__call = function(t, m, k)
		local tBookID2RecipeID = t.tBookID2RecipeID
		local tBookName2RecipeID = t.tBookName2RecipeID
		local tSegmentName2RecipeID = t.tSegmentName2RecipeID
		local tSegmentNameFix = t.tSegmentNameFix
		if not tSegmentNameFix then
			local data = X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/bookfix/{$lang}.jx3dat') or {}
			tSegmentNameFix = data.segment or {}
			t.tSegmentNameFix = tSegmentNameFix
		end
		if not tBookID2RecipeID or not tBookName2RecipeID or not tSegmentName2RecipeID then
			local cache = X.LoadLUAData({'temporary/book-segment.jx3dat', X.PATH_TYPE.GLOBAL})
			if X.IsTable(cache) then
				tBookID2RecipeID = cache.book_id
				tBookName2RecipeID = cache.book_name
				tSegmentName2RecipeID = cache.segment_name
			end
			if not tBookName2RecipeID or not tSegmentName2RecipeID then
				tBookID2RecipeID = {}
				tBookName2RecipeID = {}
				tSegmentName2RecipeID = {}
				local BookSegment = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('BookSegment', true)
				if BookSegment then
					local nCount = BookSegment:GetRowCount()
					for i = 2, nCount do
						local row = BookSegment:GetRow(i)
						-- {
						-- 	dwBookID = 2, dwSegmentID = 1, szBookName = "沉香劈山", szDesc = "沉香救母之传说。", szSegmentName = "沉香劈山上篇",
						-- 	dwBookItemIndex = 7936, dwBookNumber = 2, dwPageCount = 6, nSort = 2, nSubSort = 1, nType = 1,
						-- 	dwPageID_0 = 6, dwPageID_1 = 7, dwPageID_2 = 8, dwPageID_3 = 9, dwPageID_4 = 10, dwPageID_5 = 11, dwPageID_6 = 0, dwPageID_7 = 0, dwPageID_8 = 0, dwPageID_9 = 0
						-- }
						local dwRecipeID = X.SegmentToRecipeID(row.dwBookID, row.dwSegmentID)
						-- 套书
						local szBookName = X.TrimString(row.szBookName)
						if not tBookName2RecipeID[szBookName] then
							tBookName2RecipeID[szBookName] = {}
						end
						table.insert(tBookName2RecipeID[szBookName], dwRecipeID)
						if not tBookID2RecipeID[row.dwBookID] then
							tBookID2RecipeID[row.dwBookID] = {}
						end
						table.insert(tBookID2RecipeID[row.dwBookID], dwRecipeID)
						-- 书籍
						local szSegmentName = X.TrimString(row.szSegmentName)
						tSegmentName2RecipeID[szSegmentName] = dwRecipeID
					end
				end
			end
			if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
				X.SaveLUAData({'temporary/book-segment.jx3dat', X.PATH_TYPE.GLOBAL}, {
					book_id = tBookID2RecipeID,
					book_name = tBookName2RecipeID,
					segment_name = tSegmentName2RecipeID,
				})
			end
			t.tBookID2RecipeID = tBookID2RecipeID
			t.tBookName2RecipeID = tBookName2RecipeID
			t.tSegmentName2RecipeID = tSegmentName2RecipeID
		end
		if m == 'book_id' then
			return tBookName2RecipeID[k]
		end
		if m == 'book_name' then
			return tBookName2RecipeID[k]
		end
		if m == 'segment_name' then
			local k1 = tSegmentNameFix[k]
			if k1 then
				return tSegmentName2RecipeID[k1] or tSegmentName2RecipeID[k]
			end
			return tSegmentName2RecipeID[k]
		end
	end,
})

-- 获取书籍信息
-- X.GetBookSegmentInfo(szSegmentName)
-- X.GetBookSegmentInfo(dwRecipeID)
-- X.GetBookSegmentInfo(dwBookID, dwSegmentID)
function X.GetBookSegmentInfo(...)
	local dwBookID, dwSegmentID
	if select('#', ...) == 1 then
		local dwRecipeID = ...
		if X.IsString(dwRecipeID) then
			dwRecipeID = BOOK_SEGMENT_RECIPE('segment_name', X.TrimString(dwRecipeID))
		end
		if X.IsNumber(dwRecipeID) then
			dwBookID, dwSegmentID = X.RecipeToSegmentID(dwRecipeID)
		end
	else
		dwBookID, dwSegmentID = ...
	end
	if X.IsNumber(dwBookID) and X.IsNumber(dwSegmentID) then
		local BookSegment = X.GetGameTable('BookSegment', true)
		if BookSegment then
			return BookSegment:Search(dwBookID, dwSegmentID)
		end
	end
end

-- 获取套书所有书籍信息
-- X.GetBookAllSegmentInfo(dwBookID)
-- X.GetBookAllSegmentInfo(szBookName)
function X.GetBookAllSegmentInfo(arg0)
	local aRecipeID
	if X.IsString(arg0) then
		aRecipeID = BOOK_SEGMENT_RECIPE('book_name', X.TrimString(arg0))
	elseif X.IsNumber(arg0) then
		aRecipeID = BOOK_SEGMENT_RECIPE('book_id', arg0)
	end
	if aRecipeID then
		local aSegmentInfo = {}
		for _, dwRecipeID in ipairs(aRecipeID) do
			local dwBookID, dwSegmentID = X.RecipeToSegmentID(dwRecipeID)
			table.insert(aSegmentInfo, X.GetBookSegmentInfo(dwBookID, dwSegmentID))
		end
		return aSegmentInfo
	end
end

-- 书籍 <=> 交互物件 映射
local DOODAD_BOOK = setmetatable({}, {
	__call = function(t, m, k)
		local tDoodadID2BookRecipe = t.tDoodadID2BookRecipe
		local tBookRecipe2DoodadID = t.tBookRecipe2DoodadID
		if not tDoodadID2BookRecipe or not tBookRecipe2DoodadID then
			local cache = X.LoadLUAData({'temporary/doodad-book.jx3dat', X.PATH_TYPE.GLOBAL})
			if X.IsTable(cache) then
				tDoodadID2BookRecipe = cache.doodad_book
				tBookRecipe2DoodadID = cache.book_doodad
			end
			if not tDoodadID2BookRecipe or not tBookRecipe2DoodadID then
				tDoodadID2BookRecipe = {}
				tBookRecipe2DoodadID = {}
				local DoodadTemplate = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('DoodadTemplate', true)
				if DoodadTemplate then
					local nCount = DoodadTemplate:GetRowCount()
					for i = 2, nCount do
						local row = DoodadTemplate:GetRow(i)
						if row.szBarText == _L['Copy inscription'] then
							local szSegmentName = string.sub(row.szName, string.len(_L['Inscription * ']) + 1)
							local info = X.GetBookSegmentInfo(szSegmentName)
							if info then
								local dwRecipeID = X.SegmentToRecipeID(info.dwBookID, info.dwSegmentID)
								tDoodadID2BookRecipe[row.nID] = dwRecipeID
								tBookRecipe2DoodadID[dwRecipeID] = row.nID
							end
						end
					end
				end
			end
			X.SaveLUAData({'temporary/doodad-book.jx3dat', X.PATH_TYPE.GLOBAL}, {
				doodad_book = tDoodadID2BookRecipe,
				book_doodad = tBookRecipe2DoodadID,
			}, { passphrase = false })
			t.tDoodadID2BookRecipe = tDoodadID2BookRecipe
			t.tBookRecipe2DoodadID = tBookRecipe2DoodadID
		end
		if m == 'doodad-book' then
			return tDoodadID2BookRecipe[k]
		end
		if m == 'book-doodad' then
			return tBookRecipe2DoodadID[k]
		end
	end,
})

-- 获取碑铭交互物件对应书籍ID
-- X.GetDoodadBookRecipeID(dwDoodadTemplate)
function X.GetDoodadBookRecipeID(dwDoodadTemplate)
	return DOODAD_BOOK('doodad-book', dwDoodadTemplate)
end

-- 获取书籍碑铭交互物件模板ID
-- X.GetBookDoodadID(dwRecipeID)
-- X.GetBookDoodadID(dwBookID, dwSegmentID)
-- X.GetBookDoodadID(szSegmentName)
function X.GetBookDoodadID(...)
	local dwRecipeID
	if select('#', ...) == 1 then
		dwRecipeID = ...
		if X.IsString(dwRecipeID) then
			dwRecipeID = BOOK_SEGMENT_RECIPE('segment_name', X.TrimString(dwRecipeID))
		end
	else
		dwRecipeID = X.SegmentToRecipeID(...)
	end
	if X.IsNumber(dwRecipeID) then
		return DOODAD_BOOK('book-doodad', dwRecipeID)
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
