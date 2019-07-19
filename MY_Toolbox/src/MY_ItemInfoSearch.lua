-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------

local _L = LIB.LoadLangPack(PACKET_INFO.ROOT .. 'MY_Toolbox/lang/')
if not LIB.AssertVersion('MY_ItemInfoSearch', _L['MY_ItemInfoSearch'], 0x2012700) then
	return
end
local CACHE = {}
local ITEM_TYPE_MAX, UI_LIST
local SEARCH, RESULT, MAX_DISP = '', {}, 500

local function Init()
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
							LIB.Debug('ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (TOO SMALL)', DEBUG_LEVEL.ERROR)
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
								LIB.Debug('ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (NOT EXIST)', DEBUG_LEVEL.ERROR)
								break
							end
						end
						if nCount >= nMaxCount then
							LIB.Debug('ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (OVERFLOW)', DEBUG_LEVEL.ERROR)
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
	end
end

local function DrawList()
	UI_LIST:listbox('clear')
	for _, item in ipairs(RESULT) do
		local opt = {}
		opt.r, opt.g, opt.b = GetItemFontColorByQuality(item.itemInfo.nQuality, false)
		UI_LIST:listbox('insert', ' [' .. GetItemNameByItemInfo(item.itemInfo, item.dwRecipeID) .. '] - ' .. item.itemInfo.szName, item, item, opt)
	end
	if SEARCH ~= '' then
		UI_LIST:listbox('insert', _L('Max display count %d, current %d.', MAX_DISP, #RESULT), 'count', nil, { r = 100, g = 100, b = 100 })
	end
end

local function Search(szSearch)
	SEARCH = szSearch
	for _, v in ipairs(CACHE) do
		if v.szSearch == szSearch then
			RESULT = v.aResult
			return
		end
	end
	RESULT = {}
	local dwID = tonumber(szSearch)
	if szSearch == '' then
		return
	end
	for dwTabType, nMaxIndex in pairs(ITEM_TYPE_MAX) do
		for dwIndex = 1, nMaxIndex do
			local itemInfo = GetItemInfo(dwTabType, dwIndex)
			if itemInfo and (
				dwIndex == dwID
				or (itemInfo.nGenre ~= ITEM_GENRE.BOOK and wfind(GetItemNameByItemInfo(itemInfo), szSearch))
				or wfind(itemInfo.szName, szSearch)
			) then
				insert(RESULT, {
					dwTabType = dwTabType,
					dwIndex = dwIndex,
					itemInfo = itemInfo,
				})
				if #RESULT >= MAX_DISP then
					return
				end
			end
		end
	end
	for i = 1, g_tTable.BookSegment:GetRowCount() do
		local row = g_tTable.BookSegment:GetRow(i)
		if row then
			local dwRecipeID = BookID2GlobelRecipeID(row.dwBookID, row.dwSegmentID)
			local itemInfo = GetItemInfo(5, row.dwBookItemIndex)
			if itemInfo and (
				dwID == itemInfo.dwID or dwID == dwRecipeID
				or dwID == row.dwBookID or dwID == row.dwSegmentID
				or wfind(GetItemNameByItemInfo(itemInfo, dwRecipeID), szSearch)
			) then
				insert(RESULT, {
					dwTabType = 5,
					dwIndex = row.dwBookItemIndex,
					itemInfo = itemInfo,
					dwRecipeID = dwRecipeID,
				})
				if #RESULT >= MAX_DISP then
					return
				end
			end
		end
	end
	if #CACHE > 20 then
		remove(CACHE, 1)
	end
	insert(CACHE, { szSearch = szSearch, aResult = RESULT })
end

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local X, Y = 0, 0
	local x, y = X, Y
	local w, h = ui:size()

	y = y + ui:append('WndEditBox', {
		x = x, y = y, w = w - x, h = 25,
		text = SEARCH,
		placeholder = _L['Please input item name or item index number'],
		onchange = function(szSearch)
			LIB.DelayCall('MY_ItemInfoSearch', 200, function()
				Search(szSearch)
				DrawList()
			end)
		end,
	}, true):height()

	UI_LIST = ui:append('WndListBox', {
		x = x, y = y, w = w - x, h = h - y,
	}, true)
	UI_LIST:listbox('onhover', function(list, bIn, text, id, data)
		if id == 'count' then
			return false
		end
		if data and bIn and (data.itemInfo.nGenre ~= ITEM_GENRE.BOOK or data.dwRecipeID) then
			LIB.OutputItemInfoTip(data.dwTabType, data.dwIndex, data.dwRecipeID)
		else
			HideTip()
		end
	end)
	UI_LIST:listbox('onlclick', function(list, text, id, data)
		if data and IsCtrlKeyDown() then
			LIB.EditBoxInsertItemInfo(data.dwTabType, data.dwIndex, data.dwRecipeID)
		end
		return false
	end)
	UI_LIST:listbox('onrclick', function(list, text, id, data)
		return false
	end)
	Init()
	DrawList()
end

function PS.OnPanelDeactive()
	UI_LIST = nil
end

LIB.RegisterPanel('MY_ItemInfoSearch', _L['MY_ItemInfoSearch'], _L['System'], 'ui/Image/UICommon/ActivePopularize2.UITex|30', PS)
