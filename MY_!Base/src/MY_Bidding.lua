--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 简易的多人拍卖
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

local _L = LIB.LoadLangPack()
local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT .. 'ui/MY_Bidding.ini'
local D = {}
local O = {}
local BIDDING_CACHE = {}

function D.CheckTalkLock()
	if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		LIB.Systopmsg(_L['Please unlock safety talk lock first!'])
		return false
	end
	return true
end

function D.Open(tConfig)
	if not tConfig then
		tConfig = {}
	end
	if not tConfig.szKey then
		tConfig.szKey = LIB.GetUUID()
	end
	if not LIB.IsDistributer() then
		return LIB.Systopmsg(_L['You are not distributer!'])
	end
	if not D.CheckTalkLock() then
		return
	end
	if not tConfig.szItem and not tConfig.dwTabType then
		BIDDING_CACHE[tConfig.szKey] = {
			tConfig = tConfig,
			aRecord = {},
		}
		local frame = Wnd.OpenWindow(INI_PATH, 'MY_Bidding#' .. tConfig.szKey)
		if not frame then
			return
		end
		frame.bWaitInit = true
		frame.tUnsavedConfig = Clone(tConfig)
		D.UpdateConfig(frame)
		D.SwitchConfig(frame, true)
		D.UpdateAuthourize(frame)
	else
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_START', tConfig)
		D.PublishConfig(tConfig, true)
	end
end

function D.Close(szKey)
	Wnd.CloseWindow('MY_Bidding#' .. szKey)
end

function D.GetFrame(szKey)
	return Station.Lookup('Normal/MY_Bidding#' .. szKey)
end

function D.GetKey(frame)
	return frame:GetName():sub(#'MY_Bidding#' + 1)
end

function D.EditToConfig(edit, tConfig)
	local aStruct = edit:GetTextStruct()
	local tStruct = aStruct and aStruct[1]
	if tStruct then
		if tStruct.type == 'item' then
			local item = GetItem(tStruct.item)
			if item then
				tConfig.szItem = nil
				tConfig.dwTabType = item.dwTabType
				tConfig.dwTabIndex = item.dwIndex
				tConfig.nCount = item.bCanStack and item.nStackNum or 1
				tConfig.nBookID = item.nGenre == ITEM_GENRE.BOOK and item.nBookID or nil
			end
		elseif tStruct.type == 'iteminfo' then
			tConfig.szItem = nil
			tConfig.dwTabType = tStruct.tabtype
			tConfig.dwTabIndex = tStruct.index
			tConfig.nCount = 1
			tConfig.nBookID = nil
		elseif tStruct.type == 'book' then
			tConfig.szItem = nil
			tConfig.dwTabType = tStruct.tabtype
			tConfig.dwTabIndex = tStruct.index
			tConfig.nCount = 1
			tConfig.nBookID = tStruct.bookinfo
		elseif tStruct.type == 'text' then
			tConfig.szItem = tStruct.text
			tConfig.dwTabType = nil
			tConfig.dwTabIndex = nil
			tConfig.nCount = 1
			tConfig.nBookID = nil
		end
	end
	local tCount = aStruct and aStruct[2]
	if tCount and tCount.type == 'text' then
		local nCount = tonumber(tCount.text:gsub('.*x', ''), 10)
		if nCount then
			tConfig.nCount = max(floor(nCount), 1)
		end
	end
end

function D.ConfigToEditStruct(tConfig)
	local aStruct = {}
	if tConfig.nBookID then
		insert(aStruct, {
			type = 'book',
			version = 0,
			text = '[' .. LIB.GetObjectName('ITEM_INFO', tConfig.dwTabType, tConfig.dwTabIndex, tConfig.nBookID) .. ']',
			tabtype = tConfig.dwTabType,
			index = tConfig.dwTabIndex,
			bookinfo = tConfig.nBookID,
		})
		if tConfig.nCount and tConfig.nCount > 1 then
			insert(aStruct, {
				type = 'text',
				text = ' x' .. tConfig.nCount,
			})
		end
	elseif tConfig.dwTabType then
		insert(aStruct, {
			type = 'iteminfo',
			version = 0,
			text = '[' .. LIB.GetObjectName('ITEM_INFO', tConfig.dwTabType, tConfig.dwTabIndex) .. ']',
			tabtype = tConfig.dwTabType,
			index = tConfig.dwTabIndex,
		})
		if tConfig.nCount and tConfig.nCount > 1 then
			insert(aStruct, {
				type = 'text',
				text = ' x' .. tConfig.nCount,
			})
		end
	elseif tConfig.szItem then
		insert(aStruct, {
			type = 'text',
			text = tConfig.szItem,
		})
	end
	return aStruct
end

function D.SetTextStruct(edit, aStruct)
	edit:ClearText()
	for _, p in ipairs(aStruct) do
		if p.type == 'book' or p.type == 'iteminfo' then
			edit:InsertObj(p.text, p)
		elseif p.type == 'text' then
			edit:InsertText(p.text)
		end
	end
end

function D.ConfigToEdit(edit, tConfig)
	D.SetTextStruct(edit, D.ConfigToEditStruct(tConfig))
end

function D.GetQuickBiddingPrice(szKey)
	local cache = BIDDING_CACHE[szKey]
	local tConfig = cache.tConfig
	local aRecord = D.GetRankRecord(cache.aRecord)
	-- 计算最低加价金额
	local nPriceNext = tConfig.nPriceMin
	if #aRecord >= tConfig.nNumber then
		nPriceNext = aRecord[tConfig.nNumber].nPrice + tConfig.nPriceStep
	end
	-- 计算自己的当前有效出价
	local nPriceSelf
	for i, p in ipairs(aRecord) do
		if i > tConfig.nNumber then
			break
		end
		if p.dwTalkerID == UI_GetClientPlayerID() then
			nPriceSelf = p.nPrice
		end
	end
	return nPriceNext, nPriceSelf
end

function D.DrawPrice(h, nGold)
	h:Clear()
	h:AppendItemFromString(GetMoneyText({ nGold = nGold }, 'font=162', 'all2'))
	h:FormatAllItemPos()
end

function D.UpdateConfig(frame)
	local szKey = D.GetKey(frame)
	local tConfig = BIDDING_CACHE[szKey].tConfig
	local wnd = frame:Lookup('Wnd_Config')
	local h = wnd:Lookup('', '')
	if tConfig.dwTabType and tConfig.dwTabIndex then
		-- dwTabType, dwTabIndex, nBookID
		local szItem = LIB.GetObjectName('ITEM_INFO', tConfig.dwTabType, tConfig.dwTabIndex, tConfig.nBookID)
		if tConfig.nCount and tConfig.nCount > 1 then
			szItem = szItem .. ' x' .. (tConfig.nCount or 1)
		end
		UpdateBoxObject(
			h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Handle_ConfigBiddingItem/Box_ConfigBiddingItem'),
			UI_OBJECT.ITEM_INFO, nil, tConfig.dwTabType, tConfig.dwTabIndex, tConfig.nBookID or tConfig.nCount)
		h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Handle_ConfigBiddingItem'):Show()
		h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Text_ConfigBiddingName'):Hide()
		h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Handle_ConfigBiddingItem/Text_ConfigBiddingItem'):SetText(szItem)
		D.ConfigToEdit(wnd:Lookup('WndEditBox_Name/WndEdit_Name'), tConfig)
	else -- if tConfig.szItem then
		-- szItem
		h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Handle_ConfigBiddingItem'):Hide()
		h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Text_ConfigBiddingName'):Show()
		h:Lookup('Handle_ConfigName/Handle_ConfigName_Value/Text_ConfigBiddingName'):SetText(tConfig.szItem or '')
		wnd:Lookup('WndEditBox_Name/WndEdit_Name'):SetText(tConfig.szItem or '')
	end
	wnd:Lookup('WndEditBox_PriceMin/WndEdit_PriceMin'):SetText(tConfig.nPriceMin or '')
	D.DrawPrice(h:Lookup('Handle_ConfigPriceMin/Handle_ConfigPriceMin_Value'), tConfig.nPriceMin or 0)
	wnd:Lookup('WndEditBox_PriceStep/WndEdit_PriceStep'):SetText(tConfig.nPriceStep or '')
	D.DrawPrice(h:Lookup('Handle_ConfigPriceStep/Handle_ConfigPriceStep_Value'), tConfig.nPriceStep or 0)
	wnd:Lookup('WndCombo_Number', 'Text_Number'):SetText(tConfig.nNumber or 1)
	h:Lookup('Handle_ConfigNumber/Text_ConfigNumber_Value'):SetText(tConfig.nNumber or 1)
	frame:Lookup('Wnd_Bidding/WndButton_Bidding'):SetVisible(not frame.bWaitInit)
end

function D.SwitchConfig(frame, bConfig)
	frame:Lookup('Wnd_Config/WndEditBox_Name'):SetVisible(bConfig)
	frame:Lookup('Wnd_Config', 'Handle_ConfigName/Handle_ConfigName_Value'):SetVisible(not bConfig)
	frame:Lookup('Wnd_Config/WndEditBox_PriceMin'):SetVisible(bConfig)
	frame:Lookup('Wnd_Config', 'Handle_ConfigPriceMin/Handle_ConfigPriceMin_Value'):SetVisible(not bConfig)
	frame:Lookup('Wnd_Config/WndEditBox_PriceStep'):SetVisible(bConfig)
	frame:Lookup('Wnd_Config', 'Handle_ConfigPriceStep/Handle_ConfigPriceStep_Value'):SetVisible(not bConfig)
	frame:Lookup('Wnd_Config/WndCombo_Number'):SetVisible(bConfig)
	frame:Lookup('Wnd_Config', 'Handle_ConfigNumber/Text_ConfigNumber_Value'):SetVisible(not bConfig)
	frame:Lookup('Wnd_Config/WndButton_ConfigSubmit'):SetVisible(bConfig)
	frame:Lookup('Wnd_Config/WndButton_ConfigCancel'):SetVisible(not frame.bWaitInit and bConfig)
	frame:Lookup('Wnd_Config/Btn_Option'):SetVisible(not bConfig)
end

function D.SwitchCustomBidding(frame, bCustom)
	frame:Lookup('Wnd_CustomBidding'):SetVisible(bCustom)
end

function D.UpdateAuthourize(frame)
	local bDistributer = LIB.IsDistributer()
	if not bDistributer then
		D.SwitchConfig(frame, false)
	end
	frame:Lookup('Wnd_Config/Btn_Option'):SetVisible(not frame.bWaitInit and bDistributer)
	frame:Lookup('Wnd_Bidding/WndButton_Publish'):SetVisible(not frame.bWaitInit and bDistributer)
	frame:Lookup('Wnd_Bidding/WndButton_Finish'):SetVisible(not frame.bWaitInit and bDistributer)
end

function D.RecordSorter(r1, r2)
	if r1.nPrice == r2.nPrice then
		return r1.dwTick < r2.dwTick
	end
	return r1.nPrice > r2.nPrice
end

function D.GetRankRecord(aRecord)
	local tRes = {}
	for _, rec in ipairs(aRecord) do
		if not tRes[rec.dwTalkerID] or tRes[rec.dwTalkerID].dwTick < rec.dwTick then
			tRes[rec.dwTalkerID] = rec
		end
	end
	local aRes = {}
	for _, v in pairs(tRes) do
		insert(aRes, v)
	end
	if #aRes > 0 then
		sort(aRes, D.RecordSorter)
	end
	return aRes
end

function D.UpdateList(frame)
	local szKey = D.GetKey(frame)
	local aRecord = D.GetRankRecord(BIDDING_CACHE[szKey].aRecord)
	local h = frame:Lookup('WndScroll_Bidding', 'Handle_List')
	h:Clear()
	for _, rec in ipairs(aRecord) do
		local hItem = h:AppendItemFromIni(INI_PATH, 'Handle_Row')
		hItem.rec = rec
		hItem:Lookup('Handle_RowItem/Image_RowItemKungfu'):FromIconID(Table_GetSkillIconID(rec.dwKungfu, 1))
		hItem:Lookup('Handle_RowItem/Text_RowItemName'):SetText(rec.szTalkerName)
		D.DrawPrice(hItem:Lookup('Handle_RowItem/Handle_RowItemPrice'), rec.nPrice)
		hItem:Lookup('Handle_RowItem/Text_RowItemTime'):SetText(LIB.FormatTime(rec.dwTime, '%hh:%mm:%ss'))
	end
	h:FormatAllItemPos()
end

function D.PublishConfig(tConfig, bInit)
	local aSay = D.ConfigToEditStruct(tConfig)
	if bInit then
		insert(aSay, 1, { type = 'text', text = _L['Raise bidding for '] })
	else
		insert(aSay, 1, { type = 'text', text = _L['Modify bidding for '] })
	end
	insert(aSay, {
		type = 'text',
		text = _L(', min price is %s, bidding step is %s.',
			D.GetMoneyTalkText(tConfig.nPriceMin),
			D.GetMoneyTalkText(tConfig.nPriceStep)),
		})
	LIB.Talk(PLAYER_TALK_CHANNEL.RAID, aSay, nil, true)
end

function D.GetMoneyTalkText(nGold)
	if nGold >= 10000 then
		local nBrick = floor(nGold / 10000)
		local nGold = nGold % 10000
		if nGold == 0 then
			return _L('%d brick', nBrick)
		end
		return _L('%d brick %d gold', nBrick, nGold)
	end
	return _L('%d gold', nGold)
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
				Close = D.Close,
			},
		},
	},
}
MY_Bidding = LIB.GeneGlobalNS(settings)
end

-------------------------------------------------------------------------------------------------------
-- 背景通信
-------------------------------------------------------------------------------------------------------
LIB.RegisterBgMsg('MY_BIDDING_START', function(_, tConfig, nChannel, dwTalkerID, szTalkerName, bSelf)
	BIDDING_CACHE[tConfig.szKey] = {
		tConfig = tConfig,
		aRecord = {},
	}
	local frame = Wnd.OpenWindow(INI_PATH, 'MY_Bidding#' .. tConfig.szKey)
	if not frame then
		return
	end
	D.UpdateConfig(frame)
end)

LIB.RegisterBgMsg('MY_BIDDING_CONFIG', function(_, tConfig, nChannel, dwTalkerID, szTalkerName, bSelf)
	if BIDDING_CACHE[tConfig.szKey] then
		BIDDING_CACHE[tConfig.szKey].tConfig = tConfig
	end
	local frame = D.GetFrame(tConfig.szKey)
	if not frame then
		return
	end
	D.UpdateConfig(frame)
end)

LIB.RegisterBgMsg('MY_BIDDING_ACTION', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	insert(BIDDING_CACHE[data.szKey].aRecord, {
		dwTalkerID = dwTalkerID,
		szTalkerName = szTalkerName,
		nPrice = data.nPrice,
		dwTime = GetCurrentTime(),
		dwTick = GetTickCount(),
		dwKungfu = GetClientTeam().GetMemberInfo(dwTalkerID).dwMountKungfuID,
	})
	local frame = D.GetFrame(data.szKey)
	if not frame then
		return
	end
	D.UpdateList(frame)
end)

LIB.RegisterBgMsg('MY_BIDDING_DELETE', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	local aRecord = BIDDING_CACHE[data.szKey].aRecord
	for i, p in ipairs_r(aRecord) do
		if p.dwTalkerID == data.dwTalkerID then
			remove(aRecord, i)
		end
	end
	local frame = D.GetFrame(data.szKey)
	if not frame then
		return
	end
	D.UpdateList(frame)
end)

LIB.RegisterBgMsg('MY_BIDDING_FINISH', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	BIDDING_CACHE[data.szKey] = nil
	D.Close(data.szKey)
end)

-------------------------------------------------------------------------------------------------------
-- 界面事件
-------------------------------------------------------------------------------------------------------
MY_BiddingBase = class()

function MY_BiddingBase.OnFrameCreate()
	this:Lookup('', 'Text_Title'):SetText(_L['Bidding'])
	this:Lookup('Wnd_Config', 'Handle_ConfigName/Text_ConfigName_Title'):SetText(_L['Bidding item:'])
	this:Lookup('Wnd_Config', 'Handle_ConfigPriceMin/Text_ConfigPriceMin_Title'):SetText(_L['Min price:'])
	this:Lookup('Wnd_Config', 'Handle_ConfigPriceStep/Text_ConfigPriceStep_Title'):SetText(_L['Min price step:'])
	this:Lookup('Wnd_Config', 'Handle_ConfigNumber/Text_ConfigNumber_Title'):SetText(_L['Target bidding number:'])
	this:Lookup('Wnd_Config/WndButton_ConfigSubmit', 'Text_ConfigSubmit'):SetText(_L['Sure'])
	this:Lookup('Wnd_Config/WndButton_ConfigCancel', 'Text_ConfigCancel'):SetText(_L['Cancel'])
	this:Lookup('Wnd_Bidding/WndButton_Bidding', 'Text_ButtonBidding'):SetText(_L['Show price'])
	this:Lookup('Wnd_Bidding/WndButton_Publish', 'Text_Publish'):SetText(_L['Publish'])
	this:Lookup('Wnd_Bidding/WndButton_Finish', 'Text_Finish'):SetText(_L['Finish'])
	this:Lookup('WndScroll_Bidding', 'Handle_BiddingColumns/Handle_BiddingColumnName/Text_BiddingColumnName_Title'):SetText(_L['Name'])
	this:Lookup('WndScroll_Bidding', 'Handle_BiddingColumns/Handle_BiddingColumnPrice/Text_BiddingColumnPrice_Title'):SetText(_L['Price'])
	this:Lookup('WndScroll_Bidding', 'Handle_BiddingColumns/Handle_BiddingColumnTime/Text_BiddingColumnTime_Title'):SetText(_L['Time'])
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, -100)
	D.SwitchConfig(this, false)
	D.SwitchCustomBidding(this, false)
	D.UpdateAuthourize(this)
	D.UpdateList(this)
end

function MY_BiddingBase.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Close' then
		if LIB.IsDistributer() then
			return LIB.Systopmsg(_L['You are distributer, Please finish this bidding!'])
		end
		LIB.Confirm(_L['Sure cancel this bidding? You will not able to bidding this item.'], function()
			Wnd.CloseWindow(frame)
		end)
	elseif name == 'Btn_Option' then
		if not LIB.IsDistributer() then
			return LIB.Systopmsg(_L['You are not distributer!'])
		end
		local szKey = D.GetKey(frame)
		frame.tUnsavedConfig = Clone(BIDDING_CACHE[szKey].tConfig)
		D.UpdateConfig(frame)
		D.SwitchConfig(frame, true)
	elseif name == 'Btn_Number' then
		local frame = frame
		local txt = this:GetParent():Lookup('', 'Text_Number')
		local menu = {}
		for i = 1, 24 do
			insert(menu, {
				szOption = i,
				fnAction = function()
					frame.tUnsavedConfig.nNumber = i
					txt:SetText(i)
					UI.ClosePopupMenu()
				end,
			})
		end
		local wnd = this:GetParent()
		menu.x = wnd:GetAbsX()
		menu.y = wnd:GetAbsY() + wnd:GetH()
		menu.nMinWidth = wnd:GetW()
		UI.PopupMenu(menu)
	elseif name == 'WndButton_ConfigSubmit' then
		if not LIB.IsDistributer() then
			return LIB.Systopmsg(_L['You are not distributer!'])
		end
		if not D.CheckTalkLock() then
			return
		end
		local tConfig = frame.tUnsavedConfig
		local wnd = this:GetParent()
		D.EditToConfig(wnd:Lookup('WndEditBox_Name/WndEdit_Name'), tConfig)
		tConfig.nPriceMin = tonumber(wnd:Lookup('WndEditBox_PriceMin/WndEdit_PriceMin'):GetText()) or 2000
		tConfig.nPriceStep = tonumber(wnd:Lookup('WndEditBox_PriceStep/WndEdit_PriceStep'):GetText()) or 1000
		tConfig.nNumber = tConfig.nNumber or 1
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, frame.bWaitInit and 'MY_BIDDING_START' or 'MY_BIDDING_CONFIG', tConfig)
		D.PublishConfig(tConfig, frame.bWaitInit)
		frame.bWaitInit = nil
		D.SwitchConfig(frame, false)
		D.UpdateAuthourize(frame)
	elseif name == 'WndButton_ConfigCancel' then
		D.SwitchConfig(frame, false)
	elseif name == 'WndButton_Bidding' then
		local szKey = D.GetKey(frame)
		local nPrice, nPriceSelf = D.GetQuickBiddingPrice(szKey)
		if IsShiftKeyDown() then
			if not D.CheckTalkLock() then
				return
			end
			if nPriceSelf then
				return LIB.Systopmsg(_L('You already have a vaild price at %s.', D.GetMoneyTalkText(nPriceSelf)))
			end
			local aSay = D.ConfigToEditStruct(BIDDING_CACHE[szKey].tConfig)
			insert(aSay, 1, { type = 'text', text = _L['Want to buy '] })
			insert(aSay, { type = 'text', text = _L(', bidding for %s.', D.GetMoneyTalkText(nPrice)) })
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_ACTION', { szKey = szKey, nPrice = nPrice })
			LIB.Talk(PLAYER_TALK_CHANNEL.RAID, aSay, nil, true)
		else
			this:GetParent():GetParent()
				:Lookup('Wnd_CustomBidding/WndEditBox_CustomBidding/WndEdit_CustomBidding')
				:SetText(nPrice)
			D.SwitchCustomBidding(frame, true)
		end
	elseif name == 'WndButton_CustomBiddingDown' then
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local edit = this:GetParent():Lookup('WndEditBox_CustomBidding/WndEdit_CustomBidding')
		local nPriceMin = D.GetQuickBiddingPrice(szKey)
		local nPrice = tonumber(edit:GetText()) or 0
		nPrice = max(nPriceMin, floor(((nPrice - tConfig.nPriceMin) / tConfig.nPriceStep) - 1) * tConfig.nPriceStep + tConfig.nPriceMin)
		edit:SetText(nPrice)
	elseif name == 'WndButton_CustomBiddingUp' then
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local edit = this:GetParent():Lookup('WndEditBox_CustomBidding/WndEdit_CustomBidding')
		local nPriceMin = D.GetQuickBiddingPrice(szKey)
		local nPrice = tonumber(edit:GetText()) or 0
		nPrice = max(nPriceMin, floor(((nPrice - tConfig.nPriceMin) / tConfig.nPriceStep) + 1) * tConfig.nPriceStep + tConfig.nPriceMin)
		edit:SetText(nPrice)
	elseif name == 'WndButton_CustomBiddingSure' then
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local edit = this:GetParent():Lookup('WndEditBox_CustomBidding/WndEdit_CustomBidding')
		local nPriceMin = D.GetQuickBiddingPrice(szKey)
		local nPrice = tonumber(edit:GetText()) or 0
		local nPriceNear = max(nPriceMin, floor(((nPrice - tConfig.nPriceMin) / tConfig.nPriceStep)) * tConfig.nPriceStep + tConfig.nPriceMin)
		if nPrice ~= nPriceNear then
			LIB.Systopmsg(_L['Not a valid price'])
			LIB.Systopmsg(_L('Nearest price is %d and %d', nPriceNear, nPriceNear + tConfig.nPriceMin))
			return
		end
		if not D.CheckTalkLock() then
			return
		end
		local aSay = D.ConfigToEditStruct(BIDDING_CACHE[szKey].tConfig)
		insert(aSay, 1, { type = 'text', text = _L['Want to buy '] })
		insert(aSay, { type = 'text', text = _L(', bidding for %s.', D.GetMoneyTalkText(nPrice)) })
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_ACTION', { szKey = szKey, nPrice = nPrice })
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, aSay, nil, true)
		D.SwitchCustomBidding(frame, false)
	elseif name == 'WndButton_CustomBiddingCancel' then
		D.SwitchCustomBidding(frame, false)
	elseif name == 'WndButton_Publish' then
		if not D.CheckTalkLock() then
			return
		end
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local aRecord = D.GetRankRecord(cache.aRecord)
		local aSay = D.ConfigToEditStruct(tConfig)
		if #aRecord == 0 then
			insert(aSay, { type = 'text', text = _L[' do not has vaild bidding price'] })
		else
			insert(aSay, { type = 'text', text = _L[' bidding valid prices: '] })
			for i = 1, min(#aRecord, tConfig.nNumber) do
				if i > 1 then
					insert(aSay, { type = 'text', text = _L[','] })
				end
				insert(aSay, { type = 'name', name = aRecord[i].szTalkerName })
				insert(aSay, { type = 'text', text = aRecord[i].nPrice .. _L[' gold'] })
			end
		end
		insert(aSay, { type = 'text', text = _L['.'] })
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, aSay, nil, true)
	elseif name == 'WndButton_Finish' then
		if not D.CheckTalkLock() then
			return
		end
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local aRecord = D.GetRankRecord(cache.aRecord)
		local aSay = D.ConfigToEditStruct(tConfig)
		insert(aSay, 1, { type = 'text', text = _L['Bidding'] })
		if #aRecord == 0 then
			insert(aSay, { type = 'text', text = _L[', nobody would buy it'] })
		else
			insert(aSay, { type = 'text', text = _L[', finally bidding valid prices: '] })
			for i = 1, min(#aRecord, tConfig.nNumber) do
				if i > 1 then
					insert(aSay, { type = 'text', text = _L[','] })
				end
				insert(aSay, { type = 'name', name = aRecord[i].szTalkerName })
				insert(aSay, { type = 'text', text = aRecord[i].nPrice .. _L[' gold'] })
			end
		end
		insert(aSay, { type = 'text', text = _L[', bidding finished.'] })
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_FINISH', { szKey = szKey })
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, aSay, nil, true)
	end
end

function MY_BiddingBase.OnItemRefreshTip()
	local name = this:GetName()
	if name == 'Handle_ButtonBidding' then
		local frame = this:GetRoot()
		local szKey = D.GetKey(frame)
		local nPrice, nPriceSelf = D.GetQuickBiddingPrice(szKey)
		local szXml = GetFormatText(_L['Click to input price.'])
			.. (nPriceSelf
				and GetFormatText('\n' .. _L['Your valid price is '])
					.. GetMoneyText({ nGold = nPriceSelf }, 'font=162', 'all2')
				or GetFormatText('\n' .. _L['Hold SHIFT when click to quick bidding at price '])
					.. GetMoneyText({ nGold = nPrice }, 'font=162', 'all2'))
			.. GetFormatText(_L['.'])
		LIB.OutputTip(this, szXml, true, ALW.TOP_BOTTOM)
	end
end

function MY_BiddingBase.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_ButtonBidding' then
		HideTip()
	end
end

function MY_BiddingBase.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_RowItemDelete' then
		if not LIB.IsDistributer() then
			return LIB.Systopmsg(_L['You are not distributer!'])
		end
		if not D.CheckTalkLock() then
			return
		end
		local frame = this:GetRoot()
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local aSay = D.ConfigToEditStruct(tConfig)
		local rec = this:GetParent().rec
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_DELETE', { szKey = szKey, dwTalkerID = rec.dwTalkerID })
		insert(aSay, { type = 'text', text = _L[' delete '] })
		insert(aSay, { type = 'name', name = rec.szTalkerName })
		insert(aSay, { type = 'text', text = _L[' \'s invalid price .'] })
		LIB.Talk(PLAYER_TALK_CHANNEL.RAID, aSay, nil, true)
	end
end

LIB.RegisterAddonMenu('MY_Bidding', { szOption = _L['Create bidding'], fnAction = D.Open })
