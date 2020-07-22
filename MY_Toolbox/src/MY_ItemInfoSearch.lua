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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------

local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ItemInfoSearch'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local CACHE = {}
local ITEM_TYPE_MAX, BOOK_SEGMENT_COUNT, SEARCH_STEP_COUNT
local SEARCH, RESULT, MAX_DISP = '', {}, 500
local D = {}

function D.Init()
	if not ITEM_TYPE_MAX then
		ITEM_TYPE_MAX = {}
		local dwTabType = 1
		while 1 do
			local nMaxL = 100      -- 折半查找左端数值
			local nMaxR = 3000     -- 折半查找右端数值
			local item = GetItemInfo(dwTabType, nMaxL)
			if item then
				if not ITEM_TYPE_MAX[dwTabType] then
					local bMaxL = GetItemInfo(dwTabType, nMaxL) -- 折半查找左端结果
					local bMaxR = GetItemInfo(dwTabType, nMaxR) -- 折半查找右端结果
					local nCount, nMaxCount = 0, 1000 -- 折半次数统计 1000次折半查找还没找到多半是BUG了 判断上限防止死循环
					while true do
						if nMaxL < 1 then
							--[[#DEBUG BEGIN]]
							LIB.Debug(_L['MY_ItemInfoSearch'], 'ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (TOO SMALL)', DEBUG_LEVEL.ERROR)
							--[[#DEBUG END]]
							break
						elseif bMaxL and bMaxR then
							nMaxR = nMaxR * 2
							bMaxR = GetItemInfo(dwTabType, nMaxR)
						elseif not bMaxL and not bMaxR then
							nMaxL = floor(nMaxL / 2)
							bMaxL = GetItemInfo(dwTabType, nMaxL)
						else
							if bMaxL and not bMaxR then
								if nMaxL + 1 == nMaxR then
									ITEM_TYPE_MAX[dwTabType] = nMaxL
									break
								else
									local nCur = floor(nMaxR - (nMaxR - nMaxL) / 2)
									local bCur = GetItemInfo(dwTabType, nCur)
									if bCur then
										nMaxL = nCur
									else
										nMaxR = nCur
									end
								end
							elseif not bMaxL and bMaxR then
								--[[#DEBUG BEGIN]]
								LIB.Debug(_L['MY_ItemInfoSearch'], 'ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (NOT EXIST)', DEBUG_LEVEL.ERROR)
								--[[#DEBUG END]]
								break
							end
						end
						if nCount >= nMaxCount then
							--[[#DEBUG BEGIN]]
							LIB.Debug(_L['MY_ItemInfoSearch'], 'ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (OVERFLOW)', DEBUG_LEVEL.ERROR)
							--[[#DEBUG END]]
							break
						end
						nCount = nCount + 1
					end
				end
			elseif dwTabType > 20 then
				break
			end
			dwTabType = dwTabType + 1
		end
		-- 总查找步数 用于进度条
		BOOK_SEGMENT_COUNT = g_tTable.BookSegment:GetRowCount()
		SEARCH_STEP_COUNT = 0
		for _, nMaxIndex in pairs(ITEM_TYPE_MAX) do
			SEARCH_STEP_COUNT = SEARCH_STEP_COUNT + nMaxIndex
		end
		SEARCH_STEP_COUNT = SEARCH_STEP_COUNT + BOOK_SEGMENT_COUNT
	end
end

function D.StopSearch()
	LIB.BreatheCall('MY_ItemInfoSearch', false)
end

function D.DoRawSearch(szSearch, fnProgress, fnCallback)
	local aResult = {}
	if szSearch == '' then
		fnCallback(aResult)
		return
	end
	local dwID = tonumber(szSearch)
	-- 构建分段搜索步骤
	local dwTabType, dwIndex, nRound = next(ITEM_TYPE_MAX), 1, 0
	local function SearchStep()
		nRound = nRound + 1
		if dwTabType then
			local itemInfo = GetItemInfo(dwTabType, dwIndex)
			if itemInfo and (
				dwIndex == dwID
				or (itemInfo.nGenre ~= ITEM_GENRE.BOOK and wfind(LIB.GetItemNameByItemInfo(itemInfo), szSearch))
				or wfind(itemInfo.szName, szSearch)
			) then
				insert(aResult, {
					dwTabType = dwTabType,
					dwIndex = dwIndex,
					itemInfo = itemInfo,
				})
				if #aResult >= MAX_DISP then
					return true
				end
			end
			if dwIndex < ITEM_TYPE_MAX[dwTabType] then
				dwIndex = dwIndex + 1
			else
				dwTabType = next(ITEM_TYPE_MAX, dwTabType)
				dwIndex = 1
			end
		else
			local row = g_tTable.BookSegment:GetRow(dwIndex)
			local dwRecipeID = row and BookID2GlobelRecipeID(row.dwBookID, row.dwSegmentID)
			if dwRecipeID and GlobelRecipeID2BookID(dwRecipeID) then
				local itemInfo = GetItemInfo(5, row.dwBookItemIndex)
				if itemInfo and (
					dwID == itemInfo.dwID or dwID == dwRecipeID
					or dwID == row.dwBookID or dwID == row.dwSegmentID
					or wfind(LIB.GetItemNameByItemInfo(itemInfo, dwRecipeID), szSearch)
				) then
					insert(aResult, {
						dwTabType = 5,
						dwIndex = row.dwBookItemIndex,
						itemInfo = itemInfo,
						dwRecipeID = dwRecipeID,
					})
					if #aResult >= MAX_DISP then
						return true
					end
				end
			end
			if dwIndex < BOOK_SEGMENT_COUNT then
				dwIndex = dwIndex + 1
			else
				return true
			end
		end
	end
	local function SearchBreathe()
		local nTime = GetTime()
		while GetTime() - nTime < 50 do
			for _ = 1, 100 do
				if SearchStep() then
					fnCallback(aResult)
					D.StopSearch()
					return
				end
			end
			fnProgress(nRound / SEARCH_STEP_COUNT)
		end
	end
	LIB.BreatheCall('MY_ItemInfoSearch', SearchBreathe)
end

function D.Search(szSearch, fnProgress, fnCallback)
	-- 搜索缓存
	for _, v in ipairs(CACHE) do
		if v.szSearch == szSearch then
			fnCallback(v.aResult)
			return
		end
	end
	-- 计算结果
	D.DoRawSearch(szSearch, fnProgress, function(aResult)
		if #CACHE > 20 then
			remove(CACHE, 1)
		end
		insert(CACHE, { szSearch = szSearch, aResult = aResult })
		fnCallback(aResult)
	end)
end

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 0, 0
	local x, y = X, Y
	local w, h = ui:Size()

	local list, muProgress
	local function UpdateList()
		list:ListBox('clear')
		if IsEmpty(SEARCH) then
			for i, s in ipairs(_L['MY_ItemInfoSearch TIPS']) do
				list:ListBox('insert', s, 'TIP' .. i, nil, { r = 255, g = 255, b = 0 })
			end
		else
			for _, item in ipairs(RESULT) do
				local opt = {}
				opt.r, opt.g, opt.b = GetItemFontColorByQuality(item.itemInfo.nQuality, false)
				list:ListBox('insert', ' [' .. LIB.GetItemNameByItemInfo(item.itemInfo, item.dwRecipeID) .. '] - ' .. item.itemInfo.szName, item, item, opt)
			end
			list:ListBox('insert', _L('Max display count %d, current %d.', MAX_DISP, #RESULT), 'count', nil, { r = 100, g = 100, b = 100 })
		end
	end

	y = y + ui:Append('WndEditBox', {
		x = x, y = y, w = w - x, h = 25,
		text = SEARCH,
		placeholder = _L['Please input item name or item index number'],
		onchange = function(szSearch)
			LIB.DelayCall('MY_ItemInfoSearch', 200, function()
				D.Search(szSearch,
					function(fPer)
						muProgress:Width(w * fPer)
					end,
					function(aResult)
						muProgress:Width(w)
						SEARCH = szSearch
						RESULT = aResult
						UpdateList()
					end)
			end)
		end,
	}):Height()

	muProgress = ui:Append('Image', {
		name = 'Image_Progress',
		x = x, y = y,
		w = w, h = 4,
		image = 'ui/Image/UICommon/RaidTotal.UITex|45',
	})
	y = y + 4

	list = ui:Append('WndListBox', {
		x = x, y = y, w = w - x, h = h - y,
		listbox = {
			{
				'onhover',
				function(id, text, data)
					if id == 'count' or (IsString(id) and id:sub(1, 3) == 'TIP') then
						return false
					end
					if IsCtrlKeyDown() and IsShiftKeyDown() then
						LIB.OutputTip(this, EncodeLUAData(data, '  '))
					elseif data and (data.itemInfo.nGenre ~= ITEM_GENRE.BOOK or data.dwRecipeID) then
						LIB.OutputItemInfoTip(data.dwTabType, data.dwIndex, data.dwRecipeID)
					else
						HideTip()
					end
				end,
				function(id, text, data)
					if id == 'count' then
						return false
					end
					HideTip()
				end
			},
			{
				'onlclick',
				function(id, text, data)
					if data and IsCtrlKeyDown() then
						LIB.InsertChatInput('iteminfo', data.dwTabType, data.dwIndex, data.dwRecipeID)
					end
					return false
				end
			},
			{
				'onrclick',
				function(id, text, data)
					return false
				end
			},
		},
	})

	D.Init()
	UpdateList()
end

function PS.OnPanelDeactive()
	D.StopSearch()
end

LIB.RegisterPanel('MY_ItemInfoSearch', _L['MY_ItemInfoSearch'], _L['General'], 'ui/Image/UICommon/ActivePopularize2.UITex|30', PS)
