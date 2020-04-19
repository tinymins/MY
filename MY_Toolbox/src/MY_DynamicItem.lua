--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 大战没交
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
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
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_DynamicItem'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local SZ_INI = PLUGIN_ROOT .. '/ui/MY_DynamicItem.ini'

local D = {}
local O = {
	bEnable = false,
	bShowBg = true,
	nNum = 16,
	nCol = 16,
	anchor = { s = 'BOTTOMCENTER', r = 'BOTTOMCENTER', x = 26, y = -226 },
	aList = {},
}
RegisterCustomData('MY_DynamicItem.bEnable')
RegisterCustomData('MY_DynamicItem.bShowBg')
RegisterCustomData('MY_DynamicItem.nNum')
RegisterCustomData('MY_DynamicItem.nCol')
RegisterCustomData('MY_DynamicItem.anchor')

local MAP_NAME_FIX = setmetatable({
	[296] = 297, -- 龙门绝境
	[410] = 297, -- 沧溟绝境
	[421] = 421, -- 浪客行·悬棺裂谷
	[422] = 421, -- 浪客行·桑珠草原
	[423] = 421, -- 浪客行·东水寨
	[424] = 421, -- 浪客行·湘竹溪
	[425] = 421, -- 浪客行·荒魂镇
	[433] = 421, -- 浪客行·有间客栈
	[434] = 421, -- 浪客行·绥梦山
	[435] = 421, -- 浪客行·华清宫
	[436] = 421, -- 浪客行·枫阳村
	[437] = 421, -- 浪客行·荒雪路
	[438] = 421, -- 浪客行·古祭坛
	[439] = 421, -- 浪客行·雾荧洞
	[440] = 421, -- 浪客行·阴风峡
	[441] = 421, -- 浪客行·翡翠瑶池
	[442] = 421, -- 浪客行·胡杨林道
	[443] = 421, -- 浪客行·浮景峰
	[461] = 421, -- 浪客行·落樱林
}, {__index = CONSTANT.MAP_NAME_FIX})

function D.GetMapID()
	local dwMapID = GetClientPlayer().GetMapID()
	return MAP_NAME_FIX[dwMapID] or dwMapID
end

function D.SaveMapConfig()
	LIB.SaveLUAData(
		{'userdata/dynamic_item/' .. D.GetMapID() .. '.jx3dat', PATH_TYPE.GLOBAL},
		O.aList,
		{ passphrase = false, crc = false })
end

function D.LoadMapConfig()
	O.aList = LIB.LoadLUAData(
		{'userdata/dynamic_item/' .. D.GetMapID() .. '.jx3dat', PATH_TYPE.GLOBAL},
		{ passphrase = false })
		or LIB.LoadLUAData(PLUGIN_ROOT .. '/data/dynamic_item/' .. D.GetMapID() .. '.jx3dat')
		or {}
end

function D.GetFrame()
	return Station.Lookup('Lowest/' .. MODULE_NAME)
end

function D.CheckEnable()
	if not GetClientPlayer() then
		return
	end
	if O.bEnable then
		Wnd.OpenWindow(SZ_INI, MODULE_NAME)
	else
		Wnd.CloseWindow(MODULE_NAME)
	end
end

function D.Reinit()
	Wnd.CloseWindow(MODULE_NAME)
	D.CheckEnable()
end

function D.UpdateAnchor(frame)
	local an = O.anchor
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function D.InitList(frame)
	local nItemW = 0
	local hTotal = frame:Lookup('', '')
	-- 列表
	local hList = hTotal:Lookup('Handle_List')
	hList:Clear()
	for i = 1, O.nNum do
		local hItem = hList:AppendItemFromIni(SZ_INI, 'Handle_Item')
		local box = hItem:Lookup('Box_Item')
		box.nIndex = i
		box.__bDrag = true
		box.__tType = { [UI_OBJECT.ITEM] = true, [UI_OBJECT.ITEM_INFO] = true }
		box.__szTypeErrorMsg = _L['Only item can be draged in']
		-- bind events
		UpdateBoxObject(box, UI_OBJECT.MONEY, 0)
		box.__OnItemLButtonDragEnd = box.OnItemLButtonDragEnd
		nItemW = hItem:GetW()
	end
	hList:SetW(nItemW * O.nCol)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	local nListW, nListH = hList:GetSize()
	-- 左右分隔符
	local hSplits = hTotal:Lookup('Handle_Splits')
	hSplits:Clear()
	for _ = 1, ceil(O.nNum / O.nCol) do
		local hSplit = hSplits:AppendItemFromIni(SZ_INI, 'Handle_Split')
		hSplit:SetW(nListW + hList:GetRelX() * 2)
		hSplit:Lookup('Image_SplitR'):SetRelX(nListW + hList:GetRelX())
		hSplit:FormatAllItemPos()
	end
	hSplits:FormatAllItemPos()
	hSplits:SetSizeByAllItemSize()
	local nSplitsW, nSplitsH = hSplits:GetSize()
	-- 界面大小
	hTotal:SetSize(nSplitsW, nSplitsH)
	frame:SetSize(nSplitsW, nSplitsH)
end

function D.UpdateCDText(txt, nTime)
	if txt.nTime == nTime then
		return
	end
	local nSec, szTime, nR, nG, nB = floor(nTime / GLOBAL.GAME_FPS)
	if nSec == 0 then
		szTime, nR, nG, nB = '', 255, 255, 255
	else
		local nH = floor(nSec / 3600)
		local nM = floor(nSec / 60) % 60
		local nS = nSec % 60
		if nH > 0 then
			if nM > 0 or nS > 0 then
				nH = nH + 1
			end
			szTime = nH ..'h'
			nR, nG, nB = 255, 255, 255
		elseif nM  > 0 then
			if nS > 0 then
				nM = nM + 1
			end
			szTime = nM ..'m'
			nR, nG, nB = 255, 255, 0
		elseif nS >= 0 then
			if nS < 5 then
				if not txt.nSpark or txt.nSpark >= 7 then
					txt.nSpark = 0
					txt.bSpark = not txt.bSpark
				end
				if txt.bSpark then
					nR, nG, nB = 255, 255, 255
				else
					nR, nG, nB = 255, 0, 0
				end
				txt.nSpark = txt.nSpark + 1
			else
				nR, nG, nB = 255, 255, 0
			end
			szTime = nS
		end
	end
	txt:SetText(szTime)
	txt:SetFontColor(nR, nG, nB)
	txt.nTime = nTime
end

function D.UpdateListCD(frame)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bShowCD = LIB.GetNumberBit(GetUserPreferences(4380, 'c'), 2) == 1
	local hList = frame:Lookup('', 'Handle_List')
	for i = 1, O.nNum do
		local hItem = hList:Lookup(i - 1)
		local box = hItem:Lookup('Box_Item')
		local data, nTime = O.aList[i], 0
		if data then
			if data[1] == UI_OBJECT.ITEM_INFO then
				nTime = UpdataItemCDProgress(me, box, 0, data[2], data[3]) or 0
			elseif data[1] == UI_OBJECT.ITEM then
				nTime = UpdataItemCDProgress(me, box, data[2], data[3]) or 0
			end
		end
		D.UpdateCDText(hItem:Lookup('Text_CD'), bShowCD and nTime or 0)
	end
end

function D.UpdateList(frame)
	local hList = frame:Lookup('', 'Handle_List')
	for i = 1, O.nNum do
		local hItem = hList:Lookup(i - 1)
		local box = hItem:Lookup('Box_Item')
		local data = O.aList[i]
		if data then
			if data[1] == UI_OBJECT.ITEM_INFO then
				local nAmount = LIB.GetItemAmount(data[2], data[3], data[4])
				UpdateBoxObject(box, UI_OBJECT.ITEM_INFO, nil, data[2], data[3], data[4] or nAmount)
				box:EnableObject(nAmount > 0)
			elseif data[1] == UI_OBJECT.ITEM then
				UpdateBoxObject(box, UI_OBJECT.ITEM, data[2], data[3])
			else
				UpdateBoxObject(box, UI_OBJECT.NONE)
			end
		else
			UpdateBoxObject(box, UI_OBJECT.NONE)
		end
		box.OnItemLButtonClick = nil
		box.OnItemRButtonClick = nil
		box.OnItemLButtonDrag = nil
		box.OnItemLButtonDragEnd = nil
	end
	D.UpdateListCD(frame)
	D.UpdateItemVisible(frame)
end

function D.ParseBoxItem(box)
	local me = GetClientPlayer()
	local data, tItem = {box:GetObject()}
	if data[1] == UI_OBJECT.ITEM then
		local KItem = GetPlayerItem(me, data[3], data[4])
		if KItem then
			if data[3] == 0 then -- 玩家身上的装备
				tItem = {UI_OBJECT.ITEM, data[3], data[4]}
			else
				if KItem.nGenre == ITEM_GENRE.BOOK then
					tItem = {UI_OBJECT.ITEM_INFO, KItem.dwTabType, KItem.dwIndex, KItem.nBookID}
				else
					tItem = {UI_OBJECT.ITEM_INFO, KItem.dwTabType, KItem.dwIndex}
				end
			end
		end
	elseif data[1] == UI_OBJECT.ITEM_INFO then
		local KItemInfo = GetItemInfo(data[4], data[5])
		if KItemInfo then
			if KItemInfo.nGenre == ITEM_GENRE.BOOK then
				tItem = {UI_OBJECT.ITEM_INFO, data[4], data[5], data[7]}
			else
				tItem = {UI_OBJECT.ITEM_INFO, data[4], data[5]}
			end
		end
	end
	O.aList[box.nIndex] = tItem or {}
end

function D.UpdateHotKey(frame)
	local hList = frame:Lookup('', 'Handle_List')
	for i = 1, O.nNum do
		local nKey, bShift, bCtrl, bAlt = Hotkey.Get(MODULE_NAME .. '_' .. i)
		hList:Lookup(i - 1):Lookup('Text_HotKey'):SetText(GetKeyShow(nKey, bShift, bCtrl, bAlt, true))
	end
end

function D.UpdateItemVisible(frame)
	local hList = frame:Lookup('', 'Handle_List')
	local bShowItem = O.bShowBg or not Hand_IsEmpty()
	for i = 1, O.nNum do
		local hItem = hList:Lookup(i - 1)
		hItem:SetVisible(bShowItem or not hItem:Lookup('Box_Item'):IsEmpty())
	end
end

function D.UpdateBgVisible(frame)
	local hList = frame:Lookup('', 'Handle_List')
	local bShowBg = O.bShowBg or not Hand_IsEmpty()
	for i = 1, O.nNum do
		hList:Lookup(i - 1):Lookup('Image_ItemBg'):SetVisible(bShowBg)
	end
	frame:Lookup('', 'Handle_Splits'):SetVisible(bShowBg)
	frame:SetDummyWnd(Hand_IsEmpty())
	D.UpdateItemVisible(frame)
end

function D.OnFrameCreate()
	D.LoadMapConfig()
	D.InitList(this)
	D.UpdateList(this)
	D.UpdateHotKey(this)
	D.UpdateAnchor(this)
	D.UpdateBgVisible(this)
	D.UpdateItemVisible(this)

	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('LOADING_ENDING')
	this:RegisterEvent('EQUIP_ITEM_UPDATE')
	this:RegisterEvent('BAG_ITEM_UPDATE')
	this:RegisterEvent('HAND_PICK_OBJECT')
	this:RegisterEvent('HAND_CLEAR_OBJECT')
	this:RegisterEvent('HOT_KEY_RELOADED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
end

function D.OnFrameBreathe()
	D.UpdateListCD(this)
end

function D.OnEvent(event)
	if event == 'LOADING_ENDING' then
		D.LoadMapConfig()
		D.UpdateList(this)
	elseif event == 'EQUIP_ITEM_UPDATE' or event == 'BAG_ITEM_UPDATE' then
		D.UpdateList(this)
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'HAND_PICK_OBJECT' then
		D.UpdateBgVisible(this)
		D.UpdateItemVisible(this)
	elseif event == 'HAND_CLEAR_OBJECT' then
		D.UpdateBgVisible(this)
		D.UpdateItemVisible(this)
	elseif event == 'HOT_KEY_RELOADED' then
		D.UpdateHotKey(this)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L[MODULE_NAME])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		O.anchor = GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L[MODULE_NAME])
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Box_Item' then
		if this.bIgnoreClick or this.bDisableClick then
			return
		end
		if Hand_IsEmpty() then
			local data = {this:GetObject()}
			if data[1] == UI_OBJECT.ITEM_INFO then
				local dwTabType, dwIndex, nBookID = data[4], data[5], data[7]
				LIB.WalkBagItem(function(item, dwBox, dwX)
					if item.dwTabType == dwTabType and item.dwIndex == dwIndex then
						if item.nGenre == ITEM_GENRE.BOOK and item.nBookID ~= nBookID then
							return
						end
						OnUseItem(dwBox, dwX)
						return 0
					end
				end)
			elseif data[1] == UI_OBJECT.ITEM then
				local dwBox, dwX = data[3], data[4]
				OnUseItem(dwBox, dwX)
			end
		else
			LIB.ExecuteWithThis(this, D.OnItemLButtonDragEnd)
		end
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Box_Item' then
		D.OnItemLButtonClick()
	end
end

function D.OnItemLButtonDrag()
	local name = this:GetName()
	if name == 'Box_Item' then
		this.bIgnoreClick = true
		this.bDisableClick = true
		this:SetObjectPressed(0)
		if Hand_IsEmpty() and not this:IsEmpty() then
			if IsCursorInExclusiveMode() then
				OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
			elseif LIB.GetNumberBit(GetUserPreferences(2145, 'c'), 8) == 1 and not IsShiftKeyDown() then
				OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.SRT_ERROR_LOCK_ACTIONBAR_WHEN_DRAG)
			else
				Hand_Pick(this)
				UpdateBoxObject(this, UI_OBJECT.NONE)
				D.ParseBoxItem(this)
				D.SaveMapConfig()
			end
		end
	end
end

function D.OnItemLButtonDragEnd()
	local name = this:GetName()
	if name == 'Box_Item' then
		local wnd = Station.GetMouseOverWindow()
		if not wnd or wnd:GetRoot() ~= this:GetRoot() then
			return
		end
		if not this:IsEmpty() and LIB.GetNumberBit(GetUserPreferences(2145, 'c'), 8) == 1 and not IsShiftKeyDown() then
			OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.SRT_ERROR_LOCK_ACTIONBAR_WHEN_DRAG)
		else
			this.__OnItemLButtonDragEnd()
			D.ParseBoxItem(this)
			D.SaveMapConfig()
			D.UpdateList(this:GetRoot())
		end
		this.bIgnoreClick = nil
		this.bDisableClick = nil
	end
end

for i = 1, 32 do
	Hotkey.AddBinding(
		MODULE_NAME .. '_' .. i,
		_L('Dynamic item %d', i),
		i == 1 and _L['MY Dynamic Item'] or '',
		function()
			local frame = D.GetFrame()
			local hItem = frame and frame:Lookup('', 'Handle_List'):Lookup(i - 1)
			if not hItem then
				return
			end
			hItem:Lookup('Box_Item'):SetObjectPressed(1)
		end,
		function()
			local frame = D.GetFrame()
			local hItem = frame and frame:Lookup('', 'Handle_List'):Lookup(i - 1)
			if not hItem then
				return
			end
			hItem:Lookup('Box_Item'):SetObjectPressed(0)
			LIB.ExecuteWithThis(hItem:Lookup('Box_Item'), D.OnItemLButtonClick)
		end)
end

LIB.RegisterInit(MODULE_NAME, D.CheckEnable)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndComboBox', {
		x = W - 150, y = 106, w = 130,
		text = _L[MODULE_NAME],
		menu = function()
			local t = {
				{
					szOption = _L['Enable'],
					bCheck = true, bChecked = MY_DynamicItem.bEnable,
					fnAction = function(_, b)
						MY_DynamicItem.bEnable = b
					end,
				},
				{
					szOption = _L['Show background'],
					bCheck = true, bChecked = MY_DynamicItem.bShowBg,
					fnAction = function(_, b)
						MY_DynamicItem.bShowBg = b
					end,
				},
			}
			local t1 = {
				szOption = _L['Box number'],
			}
			local t2 = {
				szOption = _L['Col number'],
			}
			for i = 1, 32 do
				insert(t1, {
					szOption = i,
					fnAction = function()
						MY_DynamicItem.nNum = i
					end,
					bMCheck = true, bChecked = i == MY_DynamicItem.nNum
				})
				insert(t2, {
					szOption = i,
					fnAction = function()
						MY_DynamicItem.nCol = i
					end,
					bMCheck = true, bChecked = i == MY_DynamicItem.nCol
				})
			end
			insert(t, t1)
			insert(t, t2)
			return t
		end,
		tip = _L['Dynamic item bar for different map'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	})
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
				bShowBg = true,
				nNum = true,
				nCol = true,
				anchor = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				bShowBg = true,
				nNum = true,
				nCol = true,
				anchor = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
				bShowBg = D.Reinit,
				nNum = D.Reinit,
				nCol = D.Reinit,
				anchor = D.Reinit,
			},
			root = O,
		},
	},
}
MY_DynamicItem = LIB.GeneGlobalNS(settings)
end
