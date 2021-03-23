--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 仓库堆叠整理
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
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
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagSort'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bGuildBank = true,
	-- 物品排序顺序
	aGenre = {
		[ITEM_GENRE.TASK_ITEM] = 1,
		[ITEM_GENRE.EQUIPMENT] = 2,
		[ITEM_GENRE.BOOK] = 3,
		[ITEM_GENRE.POTION] = 4,
		[ITEM_GENRE.MATERIAL] = 5
	},
	aSub = {
		[EQUIPMENT_SUB.HORSE] = 1,
		[EQUIPMENT_SUB.PACKAGE] = 2,
		[EQUIPMENT_SUB.MELEE_WEAPON] = 3,
		[EQUIPMENT_SUB.RANGE_WEAPON] = 4,
	},
}

-- 帮会仓库堆叠
function D.StackGuildBank()
	local frame = Station.Lookup('Normal/GuildBankPanel')
	if not frame then
		return
	end
	local nPage = frame.nPage or 0
	local bTrigger
	local fnFinish = function()
		local btn = Station.Lookup('Normal/GuildBankPanel/Btn_MY_Stack')
		if btn then
			btn:Enable(1)
			Station.Lookup('Normal/GuildBankPanel/Btn_MY_Sort'):Enable(1)
		end
		LIB.RegisterEvent('TONG_EVENT_NOTIFY.MY_BagSort__Stack', false)
		LIB.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE.MY_BagSort__Stack', false)
	end
	local function fnLoop()
		local me, tList = GetClientPlayer(), {}
		bTrigger = true
		for i = 1, LIB.GetGuildBankBagSize(nPage) do
			local dwPos, dwX = LIB.GetGuildBankBagPos(nPage, i)
			local item = GetPlayerItem(me, dwPos, dwX)
			if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
				local szKey = tostring(item.dwTabType) .. '_' .. tostring(item.dwIndex)
				local dwX2 = tList[szKey]
				if not dwX2 then
					tList[szKey] = dwX
				else
					OnExchangeItem(dwPos, dwX, INVENTORY_GUILD_BANK, dwX2)
					return
				end
			end
		end
		fnFinish()
	end
	frame:Lookup('Btn_MY_Stack'):Enable(0)
	frame:Lookup('Btn_MY_Sort'):Enable(0)
	LIB.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE.MY_BagSort__Stack', fnLoop)
	LIB.RegisterEvent('TONG_EVENT_NOTIFY.MY_BagSort__Stack', function()
		-- TONG_EVENT_CODE.TAKE_REPERTORY_ITEM_PERMISSION_DENY_ERROR
		if arg0 == TONG_EVENT_CODE.PUT_ITEM_IN_REPERTORY_SUCCESS then
			fnFinish()
		end
	end)
	LIB.DelayCall(1000, function()
		if not bTrigger then
			fnFinish()
		end
	end)
	fnLoop()
	bTrigger = false
end

-- 背包整理格子排序函数
function D.ItemSorter(a, b)
	if not a.dwID then
		return false
	end
	if not b.dwID then
		return true
	end
	local gA, gB = O.aGenre[a.nGenre] or (100 + a.nGenre), O.aGenre[b.nGenre] or (100 + b.nGenre)
	if gA == gB then
		if b.nUiId == a.nUiId and b.bCanStack then
			return a.nStackNum > b.nStackNum
		elseif a.nGenre == ITEM_GENRE.EQUIPMENT then
			local sA, sB = O.aSub[a.nSub] or (100 + a.nSub), O.aSub[b.nSub] or (100 + b.nSub)
			if sA == sB then
				if b.nSub == EQUIPMENT_SUB.MELEE_WEAPON or b.nSub == EQUIPMENT_SUB.RANGE_WEAPON then
					if a.nDetail < b.nDetail then
						return true
					end
				elseif b.nSub == EQUIPMENT_SUB.PACKAGE then
					if a.nCurrentDurability > b.nCurrentDurability then
						return true
					elseif a.nCurrentDurability < b.nCurrentDurability then
						return false
					end
				end
			end
		end
		return a.nQuality > b.nQuality or (a.nQuality == b.nQuality and (a.dwTabType < b.dwTabType or (a.dwTabType == b.dwTabType and a.dwIndex < b.dwIndex)))
	else
		return gA < gB
	end
end

function D.IsSameItem(item1, item2)
	if (not item1 or not item1.dwID) and (not item2 or not item2.dwID) then
		return true
	end
	if item1 and item2 and item1.dwID and item2.dwID then
		if item1.dwID == item2.dwID then
			return true
		end
		if item1.nUiId == item2.nUiId and (not item1.bCanStack or item1.nStackNum == item2.nStackNum) then
			return true
		end
	end
	return false
end

-- 帮会仓库整理
function D.SortGuildBank()
	local frame = Station.Lookup('Normal/GuildBankPanel')
	if not frame then
		return
	end
	local nPage, szState = frame.nPage or 0, 'Idle'
	-- 加载格子列表
	local me, aInfo, nItemCount = GetClientPlayer(), {}, 0
	for i = 1, LIB.GetGuildBankBagSize(nPage) do
		local dwPos, dwX = LIB.GetGuildBankBagPos(nPage, i)
		local item = GetPlayerItem(me, dwPos, dwX)
		if item then
			insert(aInfo, {
				dwID = item.dwID,
				nUiId = item.nUiId,
				dwTabType = item.dwTabType,
				dwIndex = item.dwIndex,
				nGenre = item.nGenre,
				nSub = item.nSub,
				nDetail = item.nDetail,
				nQuality = item.nQuality,
				bCanStack = item.bCanStack,
				nStackNum = item.nStackNum,
				nCurrentDurability = item.nCurrentDurability,
				szName = LIB.GetObjectName('ITEM', item),
			})
			nItemCount = nItemCount + 1
		else
			insert(aInfo, CONSTANT.EMPTY_TABLE)
		end
	end
	if nItemCount == 0 then
		return
	end
	-- 排序格子列表
	if IsShiftKeyDown() then
		for i = 1, #aInfo do
			local j = random(1, #aInfo)
			if i ~= j then
				aInfo[i], aInfo[j] = aInfo[j], aInfo[i]
			end
		end
	else
		sort(aInfo, D.ItemSorter)
	end
	-- 结束清理环境、恢复控件状态
	local function fnFinish()
		szState = 'Idle'
		local btn = Station.Lookup('Normal/GuildBankPanel/Btn_MY_Sort')
		if btn then
			btn:Enable(1)
			Station.Lookup('Normal/GuildBankPanel/Btn_MY_Stack'):Enable(1)
		end
		LIB.RegisterEvent('TONG_EVENT_NOTIFY.MY_BagSort__Sort', false)
		LIB.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE.MY_BagSort__Sort', false)
	end
	-- 根据排序结果与当前状态交换物品
	local function fnNext()
		if not frame or (frame.nPage or 0) ~= nPage then
			LIB.Systopmsg(_L['Guild box closed or page changed, sort exited!'], CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' or szState == 'Refreshing' then
			return
		end
		for i, info in ipairs(aInfo) do
			local dwPos, dwX = LIB.GetGuildBankBagPos(nPage, i)
			local item = GetPlayerItem(me, dwPos, dwX)
			-- 当前格子和预期不符 需要交换
			if not D.IsSameItem(item, info) then
				-- 当前格子和预期物品可堆叠 先拿个别的东西替换过来否则会导致物品合并
				if item and info.dwID and item.nUiId == info.nUiId and item.bCanStack and item.nStackNum ~= info.nStackNum then
					for j = LIB.GetGuildBankBagSize(nPage), i + 1, -1 do
						local dwPos1, dwX1 = LIB.GetGuildBankBagPos(nPage, j)
						local item1 = GetPlayerItem(me, INVENTORY_GUILD_BANK, dwX1)
						-- 匹配到用于交换的格子
						if not item1 or item1.nUiId ~= item.nUiId then
							szState = 'Exchanging'
							if item then
								--[[#DEBUG BEGIN]]
								LIB.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwX1 .. ' <T1>', DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos, dwX, dwPos1, dwX1)
							else
								--[[#DEBUG BEGIN]]
								LIB.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX1 .. ' <-> ' .. 'GUILD,' .. dwX .. ' <T2>', DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos1, dwX1, dwPos, dwX)
							end
							return
						end
					end
					LIB.Systopmsg(_L['Cannot find item temp position, guild bag is full, sort exited!'], CONSTANT.MSG_THEME.ERROR)
					return
				end
				-- 寻找预期物品所在位置
				for j = LIB.GetGuildBankBagSize(nPage), i + 1, -1 do
					local dwPos1, dwX1 = LIB.GetGuildBankBagPos(nPage, j)
					local item1 = GetPlayerItem(me, dwPos1, dwX1)
					-- 匹配到预期物品所在位置
					if D.IsSameItem(item1, info) then
						szState = 'Exchanging'
						if item then
							--[[#DEBUG BEGIN]]
							LIB.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwX1 .. ' <N1>', DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos, dwX, dwPos1, dwX1)
						else
							--[[#DEBUG BEGIN]]
							LIB.Debug('MY_BagSort', 'OnExchangeItem: GUILD,' .. dwX1 .. ' <-> ' .. 'GUILD,' .. dwX .. ' <N1>', DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos1, dwX1, dwPos, dwX)
						end
						return
					end
				end
				LIB.Systopmsg(_L['Exchange item match failed, guild bag may changed, sort exited!'], CONSTANT.MSG_THEME.ERROR)
				return
			end
		end
		fnFinish()
	end
	frame:Lookup('Btn_MY_Sort'):Enable(0)
	frame:Lookup('Btn_MY_Stack'):Enable(0)
	LIB.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE.MY_BagSort__Sort', function()
		if szState == 'Refreshing' then
			szState = 'Idle'
			fnNext()
		end
	end)
	LIB.RegisterEvent('TONG_EVENT_NOTIFY.MY_BagSort__Sort', function()
		-- TONG_EVENT_CODE.TAKE_REPERTORY_ITEM_PERMISSION_DENY_ERROR
		if arg0 == TONG_EVENT_CODE.EXCHANGE_REPERTORY_ITEM_SUCCESS then
			szState = 'Refreshing'
		elseif arg0 == TONG_EVENT_CODE.PUT_ITEM_IN_REPERTORY_SUCCESS then
			LIB.Systopmsg(_L['Put item in guild detected, sort exited!'], CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		else
			LIB.Systopmsg(_L['Unknown exception occured, sort exited!'], CONSTANT.MSG_THEME.ERROR)
			fnFinish()
			--[[#DEBUG BEGIN]]
			LIB.Debug('MY_BagSort', 'TONG_EVENT_NOTIFY: ' .. arg0, DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
	end)
	fnNext()
end

-- 植入堆叠整理按纽
function D.CreateInjection()
	-- guild bank sort/stack
	local btn1 = UI('Normal/GuildBankPanel/Btn_Refresh')
	local btn2 = UI('Normal/GuildBankPanel/Btn_MY_Sort')
	local btn3 = UI('Normal/GuildBankPanel/Btn_MY_Stack')
	if btn1:Count() == 0 then
		return
	end
	if btn2:Count() == 0 then
		local x, y = btn1:Pos()
		local w, h = btn1:Size()
		btn2 = UI('Normal/GuildBankPanel'):Append('WndButton', {
			name = 'Btn_MY_Sort',
			x = x - w, y = y, w = w, h = h,
			text = _L['Sort'],
			tip = _L['Press shift for random'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
			onclick = D.SortGuildBank,
		})
	end
	if btn3:Count() == 0 then
		local x, y = btn2:Pos()
		local w, h = btn2:Size()
		btn3 = UI('Normal/GuildBankPanel'):Append('WndButton', {
			name = 'Btn_MY_Stack',
			x = x - w, y = y, w = w, h = h,
			text = _L['Stack'],
			onclick = D.StackGuildBank,
		})
	end
end

-- 移除堆叠整理按纽
function D.RemoveInjection()
	UI('Normal/GuildBankPanel/Btn_MY_Sort'):Remove()
	UI('Normal/GuildBankPanel/Btn_MY_Stack'):Remove()
end

-- 检测增加堆叠按纽
function D.CheckInjection()
	if O.bGuildBank then
		D.CreateInjection()
	else
		D.RemoveInjection()
	end
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Guild package sort and stack'],
		checked = MY_BagSort.bGuildBank,
		oncheck = function(bChecked)
			MY_BagSort.bGuildBank = bChecked
		end,
	}):AutoWidth():Width() + 5
	x = X
	y = y + deltaY
	return x, y
end

LIB.RegisterInit('MY_BagSort', D.CheckInjection)
LIB.RegisterReload('MY_BagSort', D.RemoveInjection)
LIB.RegisterFrameCreate('GuildBankPanel.MY_BagSort', D.CheckInjection)

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bGuildBank = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bGuildBank = true,
			},
			triggers = {
				bGuildBank = D.CheckInjection,
			},
			root = O,
		},
	},
}
MY_BagSort = LIB.GeneGlobalNS(settings)
end
