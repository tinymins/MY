--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/lang/')
if not MY.AssertVersion('MY_ItemInfoSearch', _L['MY_ItemInfoSearch'], 0x2012700) then
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
							MY.Debug('ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (TOO SMALL)', MY_DEBUG.ERROR)
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
								MY.Debug('ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (NOT EXIST)', MY_DEBUG.ERROR)
								break
							end
						end
						if nCount >= nMaxCount then
							MY.Debug('ERROR CALC ITEM_TYPE_MAX: ' .. dwTabType .. ' (OVERFLOW)', MY_DEBUG.ERROR)
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
		UI_LIST:listbox('insert', item.itemInfo.szName, item, item, opt)
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
			if itemInfo and (wfind(itemInfo.szName, szSearch) or dwIndex == dwID) then
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
			MY.DelayCall('MY_ItemInfoSearch', 200, function()
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
		if data and bIn then
			MY.OutputItemInfoTip(data.dwTabType, data.dwIndex)
		else
			HideTip()
		end
	end)
	UI_LIST:listbox('onlclick', function(list, text, id, data)
		if data and IsCtrlKeyDown() then
			MY.EditBoxInsertItemInfo(data.dwTabType, data.dwIndex)
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

MY.RegisterPanel('MY_ItemInfoSearch', _L['MY_ItemInfoSearch'], _L['System'], 'ui/Image/UICommon/ActivePopularize2.UITex|30', PS)
