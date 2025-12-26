--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 简易的多人拍卖
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/MY_Bidding')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/my_bidding/')
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/MY_Bidding.ini'
local D = {}
local O = {}
local BIDDING_CACHE = {}

function D.CheckChatLock()
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		X.OutputSystemAnnounceMessage(_L['Please unlock safety talk lock first!'])
		return false
	end
	return true
end

function D.CreateFrame(szKey)
	local szFrameName = 'MY_Bidding#' .. szKey
	if Station.SearchFrame(szFrameName) then
		return
	end
	local ui, frame
	ui = X.UI.CreateFrame('MY_Bidding', {
		w = 565, h = 480,
		text = _L['Bidding'],
		onRemove = function()
			if X.IsClientPlayerTeamDistributor() then
				X.OutputSystemAnnounceMessage(_L['You are distributor, Please finish this bidding!'])
			else
				X.Confirm(_L['Sure cancel this bidding? You will not able to bidding this item.'], function()
					X.UI.CloseFrame(frame)
				end)
			end
			return true
		end,
	})
	frame = ui:Raw()
	if not frame then
		return
	end
	frame:SetName('MY_Bidding#' .. szKey)
	X.UI.AppendFromIni(frame, INI_PATH, 'Wnd_Total', true)
	frame:Lookup('Wnd_Config', 'Handle_ConfigName/Text_ConfigName_Title'):SetText(_L['Bidding item:'])
	frame:Lookup('Wnd_Config', 'Handle_ConfigPriceMin/Text_ConfigPriceMin_Title'):SetText(_L['Min price:'])
	frame:Lookup('Wnd_Config', 'Handle_ConfigPriceStep/Text_ConfigPriceStep_Title'):SetText(_L['Min price step:'])
	frame:Lookup('Wnd_Config', 'Handle_ConfigNumber/Text_ConfigNumber_Title'):SetText(_L['Target bidding number:'])
	frame:Lookup('Wnd_Config/WndButton_ConfigSubmit', 'Text_ConfigSubmit'):SetText(_L['Sure'])
	frame:Lookup('Wnd_Config/WndButton_ConfigCancel', 'Text_ConfigCancel'):SetText(_L['Cancel'])
	frame:Lookup('Wnd_Bidding/WndButton_Bidding', 'Text_ButtonBidding'):SetText(_L['Show price'])
	frame:Lookup('Wnd_Bidding/WndButton_BiddingP', 'Text_ButtonBiddingP'):SetText(_L['P'])
	frame:Lookup('Wnd_Bidding/WndButton_Publish', 'Text_Publish'):SetText(_L['Publish'])
	frame:Lookup('Wnd_Bidding/WndButton_Finish', 'Text_Finish'):SetText(_L['Finish'])
	frame:Lookup('WndScroll_Bidding', 'Handle_BiddingColumns/Handle_BiddingColumnName/Text_BiddingColumnName_Title'):SetText(_L['Name'])
	frame:Lookup('WndScroll_Bidding', 'Handle_BiddingColumns/Handle_BiddingColumnPrice/Text_BiddingColumnPrice_Title'):SetText(_L['Price'])
	frame:Lookup('WndScroll_Bidding', 'Handle_BiddingColumns/Handle_BiddingColumnTime/Text_BiddingColumnTime_Title'):SetText(_L['Time'])
	X.UI.AdaptComponentAppearance(frame:Lookup('Wnd_Config/WndButton_ConfigSubmit'))
	X.UI.AdaptComponentAppearance(frame:Lookup('Wnd_Config/WndButton_ConfigCancel'))
	X.UI.AdaptComponentAppearance(frame:Lookup('Wnd_Bidding/WndButton_Bidding'))
	X.UI.AdaptComponentAppearance(frame:Lookup('Wnd_Bidding/WndButton_BiddingP'))
	X.UI.AdaptComponentAppearance(frame:Lookup('Wnd_Bidding/WndButton_Publish'))
	X.UI.AdaptComponentAppearance(frame:Lookup('Wnd_Bidding/WndButton_Finish'))
	frame:RegisterEvent('PARTY_DISBAND')
	frame:RegisterEvent('PARTY_DELETE_MEMBER')
	frame:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, -100)
	D.SwitchConfig(frame, false)
	D.SwitchCustomBidding(frame, false)
	D.UpdateAuthourize(frame)
	D.UpdateList(frame)
	return frame
end

function D.Open(tConfig)
	if not tConfig then
		tConfig = {}
	end
	if not tConfig.szKey then
		tConfig.szKey = X.GetUUID()
	end
	if not X.IsClientPlayerTeamDistributor() then
		return X.OutputSystemAnnounceMessage(_L['You are not distributor!'])
	end
	if not D.CheckChatLock() then
		return
	end
	if not tConfig.szItem and not tConfig.dwTabType then
		BIDDING_CACHE[tConfig.szKey] = {
			tConfig = tConfig,
			aRecord = {},
		}
		local frame = D.CreateFrame(tConfig.szKey)
		if not frame then
			return
		end
		frame.bWaitInit = true
		frame.tUnsavedConfig = X.Clone(tConfig)
		D.UpdateConfig(frame)
		D.SwitchConfig(frame, true)
		D.UpdateAuthourize(frame)
	else
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_START', tConfig)
		D.PublishConfig(tConfig, true)
	end
end

function D.Close(szKey)
	X.UI.CloseFrame('MY_Bidding#' .. szKey)
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
			tConfig.nCount = math.max(math.floor(nCount), 1)
		end
	end
end

function D.ConfigToEditStruct(tConfig)
	local aStruct = {}
	if tConfig.nBookID then
		table.insert(aStruct, {
			type = 'book',
			version = 0,
			text = '[' .. X.GetItemInfoName(tConfig.dwTabType, tConfig.dwTabIndex, tConfig.nBookID) .. ']',
			tabtype = tConfig.dwTabType,
			index = tConfig.dwTabIndex,
			bookinfo = tConfig.nBookID,
		})
		if tConfig.nCount and tConfig.nCount > 1 then
			table.insert(aStruct, {
				type = 'text',
				text = ' x' .. tConfig.nCount,
			})
		end
	elseif tConfig.dwTabType then
		table.insert(aStruct, {
			type = 'iteminfo',
			version = 0,
			text = '[' .. X.GetItemInfoName(tConfig.dwTabType, tConfig.dwTabIndex) .. ']',
			tabtype = tConfig.dwTabType,
			index = tConfig.dwTabIndex,
		})
		if tConfig.nCount and tConfig.nCount > 1 then
			table.insert(aStruct, {
				type = 'text',
				text = ' x' .. tConfig.nCount,
			})
		end
	elseif tConfig.szItem then
		table.insert(aStruct, {
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
	-- 计算最低最高有效金额、最低加价金额
	local nCurrentLowestPrice = nil
	local nCurrentHighestPrice = nil
	local nNextPrice = tConfig.nPriceMin
	if #aRecord >= tConfig.nNumber then
		nCurrentLowestPrice = aRecord[tConfig.nNumber].nPrice
		nCurrentHighestPrice = aRecord[1].nPrice
		nNextPrice = nCurrentLowestPrice + tConfig.nPriceStep
	end
	-- 计算自己的当前有效出价
	local nMyPrice, bPassed
	for i, p in ipairs(aRecord) do
		if p.dwTalkerID == X.GetClientPlayerID() then
			if i <= tConfig.nNumber then
				nMyPrice = p.nPrice
			end
			if p.bP then
				bPassed = true
			end
		end
	end
	return nNextPrice, nMyPrice, bPassed, nCurrentLowestPrice, nCurrentHighestPrice
end

function D.RaiseBidding(szKey, nPrice)
	local cache = BIDDING_CACHE[szKey]
	local tConfig = cache.tConfig
	if not D.CheckChatLock() then
		return false
	end
	local nNextPrice, nMyPrice, bPassed = D.GetQuickBiddingPrice(szKey)
	if nMyPrice then
		X.OutputSystemAnnounceMessage(_L('You already have a valid price at %s.', D.GetMoneyChatText(nMyPrice)))
		return false
	end
	if bPassed then
		X.OutputSystemAnnounceMessage(_L['You have already p.'])
		return false
	end
	local nPriceNear = math.max(nNextPrice, math.floor(((nPrice - tConfig.nPriceMin) / tConfig.nPriceStep)) * tConfig.nPriceStep + tConfig.nPriceMin)
	if nPrice ~= nPriceNear then
		X.OutputSystemAnnounceMessage(_L['Not a valid price'])
		X.OutputSystemAnnounceMessage(_L('Nearest price is %d and %d', nPriceNear, nPriceNear + tConfig.nPriceStep))
		return false
	end
	local aSay = D.ConfigToEditStruct(BIDDING_CACHE[szKey].tConfig)
	table.insert(aSay, 1, { type = 'text', text = _L['Want to buy '] })
	table.insert(aSay, { type = 'text', text = _L(', bidding for %s.', D.GetMoneyChatText(nPrice)) })
	X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_ACTION', { szKey = szKey, nPrice = nPrice })
	X.SendChat(PLAYER_TALK_CHANNEL.RAID, aSay, { parsers = { name = false } })
	return true
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
		local szItem = X.GetItemInfoName(tConfig.dwTabType, tConfig.dwTabIndex, tConfig.nBookID)
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
	local bDistributor = X.IsClientPlayerTeamDistributor()
	if not bDistributor then
		D.SwitchConfig(frame, false)
	end
	frame:Lookup('Wnd_Config/Btn_Option'):SetVisible(not frame.bWaitInit and bDistributor)
	frame:Lookup('Wnd_Bidding/WndButton_Publish'):SetVisible(not frame.bWaitInit and bDistributor)
	frame:Lookup('Wnd_Bidding/WndButton_Finish'):SetVisible(not frame.bWaitInit and bDistributor)
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
		table.insert(aRes, v)
	end
	if #aRes > 0 then
		table.sort(aRes, D.RecordSorter)
	end
	return aRes
end

function D.UpdateList(frame)
	local szKey = D.GetKey(frame)
	local cache = BIDDING_CACHE[szKey]
	local tConfig = cache.tConfig
	local aRecord = D.GetRankRecord(BIDDING_CACHE[szKey].aRecord)
	local h = frame:Lookup('WndScroll_Bidding', 'Handle_List')
	h:Clear()
	for i, rec in ipairs(aRecord) do
		local hItem = h:AppendItemFromIni(INI_PATH, 'Handle_Row')
		hItem.rec = rec
		hItem:Lookup('Handle_RowItem/Image_RowItemKungfu'):FromIconID(Table_GetSkillIconID(rec.dwKungfu, 1))
		hItem:Lookup('Handle_RowItem/Text_RowItemName'):SetText(rec.szTalkerName)
		D.DrawPrice(hItem:Lookup('Handle_RowItem/Handle_RowItemPrice'), rec.nPrice)
		hItem:Lookup('Handle_RowItem/Text_RowItemTime'):SetText(X.FormatTime(rec.dwTime, '%hh:%mm:%ss'))
		hItem:Lookup('Handle_RowItem/Text_RowItemP'):SetVisible(rec.bP)
		hItem:SetAlpha(tConfig.nNumber < i and 100 or 255)
	end
	h:FormatAllItemPos()
end

function D.PublishConfig(tConfig, bInit)
	local aSay = D.ConfigToEditStruct(tConfig)
	if bInit then
		table.insert(aSay, 1, { type = 'text', text = _L['Raise bidding for '] })
	else
		table.insert(aSay, 1, { type = 'text', text = _L['Modify bidding for '] })
	end
	table.insert(aSay, {
		type = 'text',
		text = _L(', min price is %s, bidding step is %s.',
			D.GetMoneyChatText(tConfig.nPriceMin),
			D.GetMoneyChatText(tConfig.nPriceStep)),
		})
	X.SendChat(PLAYER_TALK_CHANNEL.RAID, aSay, { parsers = { name = false } })
end

function D.GetMoneyChatText(nGold)
	if nGold >= 10000 then
		local nBrick = math.floor(nGold / 10000)
		local nGold = nGold % 10000
		if nGold == 0 then
			return _L('%d brick', nBrick)
		end
		return _L('%d brick %d gold', nBrick, nGold)
	end
	return _L('%d gold', nGold)
end

-------------------------------------------------------------------------------------------------------
-- 界面事件
-------------------------------------------------------------------------------------------------------

function D.OnEvent(event)
	if event == 'PARTY_DISBAND' then
		X.UI.CloseFrame(this)
	elseif event == 'PARTY_DELETE_MEMBER' then
		if X.GetClientPlayerID() == arg1 then
			X.UI.CloseFrame(this)
		end
	elseif event == 'TEAM_AUTHORITY_CHANGED' then
		D.UpdateAuthourize(this)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_Option' then
		if not X.IsClientPlayerTeamDistributor() then
			return X.OutputSystemAnnounceMessage(_L['You are not distributor!'])
		end
		local szKey = D.GetKey(frame)
		frame.tUnsavedConfig = X.Clone(BIDDING_CACHE[szKey].tConfig)
		D.UpdateConfig(frame)
		D.SwitchConfig(frame, true)
	elseif name == 'Btn_Number' then
		local frame = frame
		local txt = this:GetParent():Lookup('', 'Text_Number')
		local menu = {}
		for i = 1, 24 do
			table.insert(menu, {
				szOption = i,
				fnAction = function()
					frame.tUnsavedConfig.nNumber = i
					txt:SetText(i)
					X.UI.ClosePopupMenu()
				end,
			})
		end
		local wnd = this:GetParent()
		menu.x = wnd:GetAbsX()
		menu.y = wnd:GetAbsY() + wnd:GetH()
		menu.nMinWidth = wnd:GetW()
		X.UI.PopupMenu(menu)
	elseif name == 'WndButton_ConfigSubmit' then
		if not X.IsClientPlayerTeamDistributor() then
			return X.OutputSystemAnnounceMessage(_L['You are not distributor!'])
		end
		if not D.CheckChatLock() then
			return
		end
		local tConfig = frame.tUnsavedConfig
		local wnd = this:GetParent()
		D.EditToConfig(wnd:Lookup('WndEditBox_Name/WndEdit_Name'), tConfig)
		tConfig.nPriceMin = tonumber(wnd:Lookup('WndEditBox_PriceMin/WndEdit_PriceMin'):GetText()) or 2000
		tConfig.nPriceStep = tonumber(wnd:Lookup('WndEditBox_PriceStep/WndEdit_PriceStep'):GetText()) or 1000
		tConfig.nNumber = tConfig.nNumber or 1
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, frame.bWaitInit and 'MY_BIDDING_START' or 'MY_BIDDING_CONFIG', tConfig)
		D.PublishConfig(tConfig, frame.bWaitInit)
		frame.bWaitInit = nil
		D.SwitchConfig(frame, false)
		D.UpdateAuthourize(frame)
	elseif name == 'WndButton_ConfigCancel' then
		D.SwitchConfig(frame, false)
	elseif name == 'WndButton_BiddingP' then
		if not D.CheckChatLock() then
			return
		end
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local aRecord = D.GetRankRecord(cache.aRecord)
		local bExist, bP, bValid = false, false, false
		for i, p in ipairs(aRecord) do
			if p.dwTalkerID == X.GetClientPlayerID() then
				bExist = true
				if p.bP then
					bP = true
				elseif i <= cache.tConfig.nNumber then
					bValid = true
				end
				break
			end
		end
		if not bExist then
			return X.OutputSystemAnnounceMessage(_L['You have not bidding a price yet.'])
		end
		if bP then
			return X.OutputSystemAnnounceMessage(_L['You have already p.'])
		end
		if bValid then
			return X.OutputSystemAnnounceMessage(_L['You cannot p cause you have a valid price.'])
		end
		local aSay = D.ConfigToEditStruct(BIDDING_CACHE[szKey].tConfig)
		table.insert(aSay, 1, { type = 'text', text = _L['Exit from bidding '] })
		table.insert(aSay, { type = 'text', text = _L[', P.'] })
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_P', { szKey = szKey })
		X.SendChat(PLAYER_TALK_CHANNEL.RAID, aSay, { parsers = { name = false } })
	elseif name == 'WndButton_Bidding' then
		local szKey = D.GetKey(frame)
		local nNextPrice, nMyPrice, bPassed = D.GetQuickBiddingPrice(szKey)
		if bPassed then
			return X.OutputSystemAnnounceMessage(_L['You have already p.'])
		end
		if IsShiftKeyDown() then
			D.RaiseBidding(szKey, nNextPrice)
		else
			this:GetParent():GetParent()
				:Lookup('Wnd_CustomBidding/WndEditBox_CustomBidding/WndEdit_CustomBidding')
				:SetText(nNextPrice)
			D.SwitchCustomBidding(frame, true)
		end
	elseif name == 'WndButton_CustomBiddingDown' then
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local edit = this:GetParent():Lookup('WndEditBox_CustomBidding/WndEdit_CustomBidding')
		local nNextPrice = D.GetQuickBiddingPrice(szKey)
		local nPrice = tonumber(edit:GetText()) or 0
		nPrice = math.max(nNextPrice, math.floor(((nPrice - tConfig.nPriceMin) / tConfig.nPriceStep) - 1) * tConfig.nPriceStep + tConfig.nPriceMin)
		edit:SetText(nPrice)
	elseif name == 'WndButton_CustomBiddingUp' then
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local edit = this:GetParent():Lookup('WndEditBox_CustomBidding/WndEdit_CustomBidding')
		local nNextPrice = D.GetQuickBiddingPrice(szKey)
		local nPrice = tonumber(edit:GetText()) or 0
		nPrice = math.max(nNextPrice, math.floor(((nPrice - tConfig.nPriceMin) / tConfig.nPriceStep) + 1) * tConfig.nPriceStep + tConfig.nPriceMin)
		edit:SetText(nPrice)
	elseif name == 'WndButton_CustomBiddingSure' then
		local szKey = D.GetKey(frame)
		local edit = this:GetParent():Lookup('WndEditBox_CustomBidding/WndEdit_CustomBidding')
		local nPrice = tonumber(edit:GetText()) or 0
		D.RaiseBidding(szKey, nPrice)
		D.SwitchCustomBidding(frame, false)
	elseif name == 'WndButton_CustomBiddingCancel' then
		D.SwitchCustomBidding(frame, false)
	elseif name == 'WndButton_Publish' then
		if not D.CheckChatLock() then
			return
		end
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local aRecord = D.GetRankRecord(cache.aRecord)
		local aSay = D.ConfigToEditStruct(tConfig)
		table.insert(aSay, 1, { type = 'text', text = _L['Bidding'] })
		if #aRecord == 0 then
			table.insert(aSay, { type = 'text', text = _L[', no valid price'] })
		else
			table.insert(aSay, { type = 'text', text = _L[', current valid prices: '] })
			for i = 1, math.min(#aRecord, tConfig.nNumber) do
				if i > 1 then
					table.insert(aSay, { type = 'text', text = _L[','] })
				end
				table.insert(aSay, { type = 'name', name = aRecord[i].szTalkerName })
				table.insert(aSay, { type = 'text', text = aRecord[i].nPrice .. _L[' gold'] })
			end
		end
		table.insert(aSay, { type = 'text', text = _L['.'] })
		X.SendChat(PLAYER_TALK_CHANNEL.RAID, aSay, { parsers = { name = false } })
	elseif name == 'WndButton_Finish' then
		if not D.CheckChatLock() then
			return
		end
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local aRecord = D.GetRankRecord(cache.aRecord)
		local aSay = D.ConfigToEditStruct(tConfig)
		table.insert(aSay, 1, { type = 'text', text = _L['Bidding'] })
		if #aRecord == 0 then
			table.insert(aSay, { type = 'text', text = _L[', nobody would buy it'] })
		else
			table.insert(aSay, { type = 'text', text = _L[', finally bidding valid prices: '] })
			for i = 1, math.min(#aRecord, tConfig.nNumber) do
				if i > 1 then
					table.insert(aSay, { type = 'text', text = _L[','] })
				end
				table.insert(aSay, { type = 'name', name = aRecord[i].szTalkerName })
				table.insert(aSay, { type = 'text', text = aRecord[i].nPrice .. _L[' gold'] })
			end
		end
		table.insert(aSay, { type = 'text', text = _L[', bidding finished.'] })
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_FINISH', { szKey = szKey })
		X.SendChat(PLAYER_TALK_CHANNEL.RAID, aSay, { parsers = { name = false } })
	end
end

function D.OnRButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'WndButton_Bidding' then
		local szKey = D.GetKey(frame)
		local nNextPrice, nMyPrice, bPassed, nCurrentLowestPrice, nCurrentHighestPrice = D.GetQuickBiddingPrice(szKey)
		local menu = {
			{ szOption = _L['Raise quick bidding'], bDisable = true },
		}
		for _, nPriceAdd in ipairs({ 100, 1000, 5000, 10000, 20000, 50000, 100000 }) do
			table.insert(menu, {
				bRichText = true,
				szOption = GetFormatText('+', 162) .. GetMoneyText({ nGold = nPriceAdd }, 'font=162', 'all2'),
				fnMouseEnter = function()
					local nX, nY = this:GetAbsX(), this:GetAbsY()
					local nW, nH = this:GetW(), this:GetH()
					local szXml = bPassed
						and GetFormatText(_L['You have already p.'])
						or (GetFormatText(_L['Click to raise quick bidding.'])
							.. (nMyPrice
								and GetFormatText('\n' .. _L['Your valid price is '])
									.. GetMoneyText({ nGold = nMyPrice }, 'font=162', 'all2')
								or GetFormatText('\n' .. _L['Click to quick bidding at price '])
									.. GetMoneyText({ nGold = nCurrentLowestPrice + nPriceAdd }, 'font=162', 'all2'))
							.. GetFormatText(_L['.']))
					OutputTip(szXml, 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
				end,
				fnMouseLeave = function()
					HideTip()
				end,
				fnAction = function()
					if bPassed then
						return X.OutputSystemAnnounceMessage(_L['You have already p.'])
					end
					local msg = {
						szName = 'MY_Bidding_Confirm',
						szMessage = GetFormatText(_L['Sure to raise bidding to '])
							.. GetMoneyText({ nGold = nCurrentLowestPrice + nPriceAdd }, 'font=162', 'all2')
							.. GetFormatText(_L['?']),
						bRichText = true,
						szAlignment = 'CENTER',
						{
							szOption = g_tStrings.STR_HOTKEY_SURE,
							fnAction = function()
								D.RaiseBidding(szKey, nCurrentLowestPrice + nPriceAdd)
							end
						},
						{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
					}
					MessageBox(msg)
				end,
			})
		end
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		menu.nMiniWidth = this:GetW()
		menu.x = nX
		menu.y = nY + nH
		X.UI.PopupMenu(menu)
	end
end

function D.OnItemRefreshTip()
	local name = this:GetName()
	if name == 'Handle_ButtonBidding' then
		local frame = this:GetRoot()
		local szKey = D.GetKey(frame)
		local nNextPrice, nMyPrice, bPassed = D.GetQuickBiddingPrice(szKey)
		local szXml = bPassed
			and GetFormatText(_L['You have already p.'])
			or (GetFormatText(_L['Click to input price.'])
				.. (nMyPrice
					and GetFormatText('\n' .. _L['Your valid price is '])
						.. GetMoneyText({ nGold = nMyPrice }, 'font=162', 'all2')
					or GetFormatText('\n' .. _L['Hold SHIFT when click to quick bidding at price '])
						.. GetMoneyText({ nGold = nNextPrice }, 'font=162', 'all2')
						.. GetFormatText('\n' .. _L['Right click to select quick bidding price.']))
				.. GetFormatText(_L['.']))
		X.OutputTip(this, szXml, true, ALW.TOP_BOTTOM)
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_ButtonBidding' then
		HideTip()
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_RowItemDelete' then
		if not X.IsClientPlayerTeamDistributor() then
			return X.OutputSystemAnnounceMessage(_L['You are not distributor!'])
		end
		if not D.CheckChatLock() then
			return
		end
		local frame = this:GetRoot()
		local szKey = D.GetKey(frame)
		local cache = BIDDING_CACHE[szKey]
		local tConfig = cache.tConfig
		local aSay = D.ConfigToEditStruct(tConfig)
		local rec = this:GetParent().rec
		table.insert(aSay, 1, { type = 'text', text = _L['Modify bidding for '] })
		table.insert(aSay, { type = 'text', text = _L['\'s record, delete '] })
		table.insert(aSay, { type = 'name', name = rec.szTalkerName })
		table.insert(aSay, { type = 'text', text = _L[' \'s invalid price .'] })
		X.Confirm(_L('Sure to delete %s\'s bidding record?', rec.szTalkerName), function()
			if not X.IsClientPlayerTeamDistributor() then
				return X.OutputSystemAnnounceMessage(_L['You are not distributor!'])
			end
			X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_BIDDING_DELETE', { szKey = szKey, dwTalkerID = rec.dwTalkerID })
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, aSay, { parsers = { name = false } })
		end)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_Bidding',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				Open = D.Open,
				Close = D.Close,
			},
			root = D,
		},
	},
}
MY_Bidding = X.CreateModule(settings)
end

-------------------------------------------------------------------------------------------------------
-- 背景通信
-------------------------------------------------------------------------------------------------------
X.RegisterBgMsg('MY_BIDDING_START', function(_, tConfig, nChannel, dwTalkerID, szTalkerName, bSelf)
	BIDDING_CACHE[tConfig.szKey] = {
		tConfig = tConfig,
		aRecord = {},
	}
	local frame = D.CreateFrame(tConfig.szKey)
	if not frame then
		return
	end
	D.UpdateConfig(frame)
end)

X.RegisterBgMsg('MY_BIDDING_CONFIG', function(_, tConfig, nChannel, dwTalkerID, szTalkerName, bSelf)
	if BIDDING_CACHE[tConfig.szKey] then
		BIDDING_CACHE[tConfig.szKey].tConfig = tConfig
	end
	local frame = D.GetFrame(tConfig.szKey)
	if not frame then
		return
	end
	D.UpdateConfig(frame)
end)

X.RegisterBgMsg('MY_BIDDING_ACTION', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	table.insert(BIDDING_CACHE[data.szKey].aRecord, {
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

X.RegisterBgMsg('MY_BIDDING_P', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	for _, p in ipairs(BIDDING_CACHE[data.szKey].aRecord) do
		if p.dwTalkerID == dwTalkerID then
			p.bP = true
		end
	end
	local frame = D.GetFrame(data.szKey)
	if not frame then
		return
	end
	D.UpdateList(frame)
end)

X.RegisterBgMsg('MY_BIDDING_DELETE', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	local aRecord = BIDDING_CACHE[data.szKey].aRecord
	for i, p in X.ipairs_r(aRecord) do
		if p.dwTalkerID == data.dwTalkerID then
			table.remove(aRecord, i)
		end
	end
	local frame = D.GetFrame(data.szKey)
	if not frame then
		return
	end
	D.UpdateList(frame)
end)

X.RegisterBgMsg('MY_BIDDING_FINISH', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not BIDDING_CACHE[data.szKey] then
		return
	end
	BIDDING_CACHE[data.szKey] = nil
	D.Close(data.szKey)
end)

X.RegisterAddonMenu('MY_Bidding', { szOption = _L['Create bidding'], fnAction = D.Open })

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
