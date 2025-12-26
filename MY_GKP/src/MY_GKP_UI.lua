--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKP_UI'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_GKP.ini'
local D = {
	GetMoneyTipText = MY_GKP.GetMoneyTipText,
	GetTimeString = MY_GKP.GetTimeString,
	GetMoneyCol = MY_GKP.GetMoneyCol,
	GetFormatLink = MY_GKP.GetFormatLink,
}

function D.SetDS(frame, szFilePath)
	frame.ds = MY_GKP_DS(szFilePath)
	if frame.ds then
		D.UpdateMode(frame)
		D.DrawTitle(frame)
		D.DrawStat(frame)
		D.DrawAuctionPage(frame)
		D.DrawPaymentPage(frame)
	else
		X.UI.CloseFrame(frame)
		X.Alert('MY_GKP_UI', _L['Load data source failed!'])
	end
end

---------------------------------------------------------------------->
-- 绘制界面
----------------------------------------------------------------------<

function D.UpdateMode(frame)
	local bMainInstance = frame.ds == MY_GKP_MI.GetDS()
	local ui = X.UI(frame)
	ui:Fetch('Btn_AddManually'):Visible(bMainInstance)
	ui:Fetch('Btn_Calculate'):Visible(bMainInstance)
	ui:Fetch('GOLD_TEAM_BID_LIST'):Visible(bMainInstance)
	ui:Fetch('Debt'):Visible(bMainInstance)
	ui:Fetch('Btn_ClearRecord'):Visible(bMainInstance)
	ui:Fetch('Btn_HistoryRecord'):Visible(bMainInstance)
	ui:Fetch('Btn_SyncRecord'):Visible(bMainInstance)
	ui:Fetch('Btn_SetCaption'):Visible(bMainInstance)
	ui:Fetch('Btn_SetHistory'):Visible(not bMainInstance)
end

function D.DrawTitle(frame)
	local txtTitle = frame:Lookup('', 'Text_Title')
	local szMap = frame.ds:GetMap()
	local nTime = frame.ds:GetTime()
	local szText = _L['GKP Golden Team Record']
		.. (szMap ~= '' and (' - ' .. szMap) or '')
		.. (nTime ~= 0 and (' - ' .. X.FormatTime(nTime, '%yyyy-%MM-%dd-%hh-%mm-%ss')) or '')
	txtTitle:SetText(szText)
end

function D.DrawStat(frame)
	local a, b = frame.ds:GetAuctionSum()
	local c, d = frame.ds:GetPaymentSum()
	local hStat = frame:Lookup('Wnd_Bg', 'Handle_Record_Stat')
	local szXml = GetFormatText(_L['Reall Salary:'], 41) .. D.GetMoneyTipText(a + b)
	if X.IsClientPlayerTeamDistributor() or not X.IsClientPlayerInParty() then
		if c + d < 0 then
			szXml = szXml .. GetFormatText(' || ' .. _L['Spending:'], 41) .. D.GetMoneyTipText(d)
		elseif c ~= 0 then
			szXml = szXml .. GetFormatText(' || ' .. _L['Reall income:'], 41) .. D.GetMoneyTipText(c + d)
		end
		local e = (a + b) - (c + d)
		if a > 0 then
			szXml = szXml .. GetFormatText(' || ' .. _L['Money on Debt:'], 41) .. D.GetMoneyTipText(e)
		end
	end
	hStat:Clear()
	hStat:AppendItemFromString(szXml)
	hStat:FormatAllItemPos()
	hStat:SetSizeByAllItemSize()
	hStat.OnItemMouseEnter = function()
		local br = GetFormatText('\n', 41)
		local szXml = ''
		if a > 0 then
			szXml = szXml .. GetFormatText(_L['Total Auction:'], 41) .. D.GetMoneyTipText(a) .. br
			if b ~= 0 then
				szXml = szXml .. GetFormatText(_L['Salary Allowance:'], 41) .. D.GetMoneyTipText(b) .. br
				szXml = szXml .. GetFormatText(_L['Reall Salary:'], 41) .. D.GetMoneyTipText(a + b) .. br
			end
		end
		if (X.IsClientPlayerTeamDistributor() or not X.IsClientPlayerInParty()) and c > 0 then
			szXml = szXml .. GetFormatText(_L['Total income:'], 41) .. D.GetMoneyTipText(c) .. br
			if d ~= 0 then
				szXml = szXml .. GetFormatText(_L['Spending:'], 41) .. D.GetMoneyTipText(d) .. br
				szXml = szXml .. GetFormatText(_L['Reall income:'], 41) .. D.GetMoneyTipText(c + d) .. br
			end
		end
		if szXml ~= '' then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputTip(szXml, 400, { x - w, y, w, h })
		end
	end
	FireUIEvent('GKP_RECORD_TOTAL', a, b)
end

function D.DrawAuctionPage(frame, szKey, szSort)
	if not szKey then
		szKey = frame.hRecordContainer.key or 'nTime'
	end
	if not szSort then
		szSort = frame.hRecordContainer.sort or 'desc'
	end
	local tab = frame.ds:GetAuctionList(szKey, szSort)
	local bMainInstance = frame.ds == MY_GKP_MI.GetDS()
	frame.hRecordContainer.key = szKey
	frame.hRecordContainer.sort = szSort
	frame.hRecordContainer:Clear()
	for k, v in ipairs(tab) do
		if MY_GKP.bDisplayEmptyRecords or v.nMoney ~= 0 then
			local wnd = frame.hRecordContainer:AppendContentFromIni(PLUGIN_ROOT .. '/ui/MY_GKP_Record_Item.ini', 'WndWindow', k)
			local item = wnd:Lookup('', '')
			if k % 2 == 0 then
				item:Lookup('Image_Line'):Hide()
			end
			item:RegisterEvent(32)
			if bMainInstance then
				item.OnItemRButtonClick = function()
					if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
						return X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
					end
					MY_GKP_AuctionUI.Open(this:GetRoot().ds, v, 'EDIT')
				end
			end
			item:Lookup('Text_No'):SetText(k)
			item:Lookup('Image_NameIcon'):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup('Text_Name'):SetText(v.szPlayer)
			item:Lookup('Text_Name'):SetFontColor(X.GetForceColor(v.dwForceID))
			local szName = v.szName or X.GetItemNameByUIID(v.nUiId)
			item:Lookup('Text_ItemName'):SetText(szName)
			if v.nQuality then
				item:Lookup('Text_ItemName'):SetFontColor(GetItemFontColorByQuality(v.nQuality))
			else
				local KItem = v.dwTabType and v.dwIndex and GetItemInfo(v.dwTabType, v.dwIndex)
				if KItem then
					item:Lookup('Text_ItemName'):SetFontColor(GetItemFontColorByQuality(KItem.nQuality))
				else
					item:Lookup('Text_ItemName'):SetFontColor(255, 255, 0)
				end
			end
			item:Lookup('Handle_Money'):AppendItemFromString(D.GetMoneyTipText(v.nMoney))
			item:Lookup('Handle_Money'):FormatAllItemPos()
			item:Lookup('Text_Source'):SetText(v.szNpcName)
			if v.bSync then
				item:Lookup('Text_Source'):SetFontColor(0,255,0)
			end
			item:Lookup('Text_Time'):SetText(D.GetTimeString(v.nTime))
			if v.bEdit then
				item:Lookup('Text_Time'):SetFontColor(255,255,0)
			end
			local box = item:Lookup('Box_Item')
			if v.dwTabType == 0 and v.dwIndex == 0 then
				box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
				box:SetObjectIcon(582)
			else
				if v.nBookID then
					UpdataItemInfoBoxObject(box, v.nVersion, v.dwTabType, v.dwIndex, 99999, v.nBookID)
				else
					UpdataItemInfoBoxObject(box, v.nVersion, v.dwTabType, v.dwIndex, v.nStackNum)
				end
			end
			local hItemName = item:Lookup('Text_ItemName')
			for kk, vv in ipairs({'OnItemMouseEnter', 'OnItemMouseLeave', 'OnItemLButtonDown', 'OnItemLButtonUp'}) do
				hItemName[vv] = function()
					if box[vv] then
						this = box
						box[vv]()
					end
				end
			end
			if bMainInstance then
				wnd:Lookup('WndButton_Delete').OnLButtonClick = function()
					if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
						return X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
					end
					v.bDelete = not v.bDelete
					frame.ds:SetAuctionRec(v)
					if X.IsClientPlayerTeamDistributor() then
						if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
							X.OutputSystemAnnounceMessage(_L['Please unlock talk lock, otherwise gkp will not able to sync to teammate.'])
						end
						X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {'edit', v}, true)
					end
				end
			else
				wnd:Lookup('WndButton_Delete'):Hide()
			end
			-- tip
			item:Lookup('Text_Name').data = v
			if v.bDelete then
				wnd:SetAlpha(80)
			end
		end
	end
	frame.hRecordContainer:FormatAllContentPos()
end

function D.DrawPaymentPage(frame, szKey, szSort)
	if not szKey then
		szKey = frame.hAccountContainer.key or 'szPlayer'
	end
	if not szSort then
		szSort = frame.hAccountContainer.sort or 'desc'
	end
	local tab = frame.ds:GetPaymentList(szKey, szSort)
	local bMainInstance = frame.ds == MY_GKP_MI.GetDS()
	frame.hAccountContainer.key = szKey
	frame.hAccountContainer.sort = szSort
	frame.hAccountContainer:Clear()
	local tMoney = X.GetClientPlayer().GetMoney()
	for k, v in ipairs(tab) do
		local c = frame.hAccountContainer:AppendContentFromIni(PLUGIN_ROOT .. '/ui/MY_GKP_Account_Item.ini', 'WndWindow', k)
		local item = c:Lookup('', '')
		if k % 2 == 0 then
			item:Lookup('Image_Line'):Hide()
		end
		c:Lookup('', 'Handle_Money'):AppendItemFromString(D.GetMoneyTipText(v.nGold))
		c:Lookup('', 'Handle_Money'):FormatAllItemPos()
		item:Lookup('Text_No'):SetText(k)
		if v.szPlayer and v.szPlayer ~= 'System' then
			item:Lookup('Image_NameIcon'):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup('Text_Name'):SetText(v.szPlayer)
			item:Lookup('Text_Change'):SetText(_L['Player\'s transation'])
			item:Lookup('Text_Name'):SetFontColor(X.GetForceColor(v.dwForceID))
		else
			item:Lookup('Image_NameIcon'):FromUITex('ui/Image/uicommon/commonpanel4.UITex',3)
			item:Lookup('Text_Name'):SetText(_L['System'])
			item:Lookup('Text_Change'):SetText(_L['Reward & other ways'])
		end
		item:Lookup('Text_Map'):SetText(X.IsEmpty(v.dwMapID) and '-' or Table_GetMapName(v.dwMapID))
		item:Lookup('Text_Time'):SetText(D.GetTimeString(v.nTime))
		if bMainInstance then
			c:Lookup('WndButton_Delete').OnLButtonClick = function()
				v.bDelete = not v.bDelete
				frame.ds:SetPaymentRec(v)
			end
		else
			c:Lookup('WndButton_Delete'):Hide()
		end
		-- tip
		item:Lookup('Text_Name').data = v
		if v.bDelete then
			c:SetAlpha(80)
		end
	end
	frame.hAccountContainer:FormatAllContentPos()
end

---------------------------------------------------------------------->
-- 窗体创建时会被调用
----------------------------------------------------------------------<
function D.InitFrame(frame)
	X.UI.AppendFromIni(frame, SZ_INI, 'Wnd_Total', true)
	frame.hRecordContainer = frame:Lookup('Page_GKP_Record/WndScroll_GKP_Record/WndContainer_Record_List')
	frame.hAccountContainer = frame:Lookup('Page_GKP_Account/WndScroll_GKP_Account/WndContainer_Account_List')
	X.UI.AdaptComponentAppearance(frame:Lookup('Page_GKP_Record/WndScroll_GKP_Record/Scroll_GKP_Record_All'))
	X.UI.AdaptComponentAppearance(frame:Lookup('Page_GKP_Account/WndScroll_GKP_Account/Scroll_GKP_Account_All'))
	local ui = X.UI(frame)
	frame:Lookup('Page_GKP_Record'):Show()
	frame:Lookup('Page_GKP_Account'):Hide()
	ui:Text(_L['GKP Golden Team Record']):Anchor('CENTER')
	ui:Append('Image', {
		x = 10, y = -10,
		w = 36, h = 36,
		image = 'ui\\Image\\UICommon\\CommonPanel.UITex', imageFrame = 88,
	})
	local uiTabs = ui:Append('WndTabs', {
		x = 0, y = 40, w = frame:GetW(), h = 35,
	})
	uiTabs:Append('WndTab', {
		w = 150, h = 35,
		text = g_tStrings.GOLD_BID_RECORD_STATIC_TITLE,
		checked = true,
		onCheck = function(bChecked)
			frame:Lookup('Page_GKP_Record'):SetVisible(bChecked)
		end,
	})
	uiTabs:Append('WndTab', {
		w = 150, h = 35,
		text = g_tStrings.GOLD_BID_RPAY_STATIC_TITLE,
		onCheck = function(bChecked)
			frame:Lookup('Page_GKP_Account'):SetVisible(bChecked)
		end,
	})
	ui:Append('WndButton', {
		x = 955, y = 54, w = 20, h = 20,
		buttonStyle = 'OPTION',
		onClick = function()
			X.Panel.Show()
			X.Panel.Focus()
			X.Panel.SwitchTab('MY_GKP')
		end,
	})
	ui:Append('WndButton', {
		name = 'Btn_AddManually',
		x = 20, y = 660, w = 120, text = _L['Add Manually'],
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then -- debug
				return X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
			end
			MY_GKP_AuctionUI.Open(frame:GetRoot().ds)
		end,
	})
	local nW = 980
	-- 结算工资按钮
	local nX = nW - 120 - 5
	ui:Append('WndButton', {
		name = 'Btn_Calculate',
		x = nX, y = 620, w = 120, text = g_tStrings.GOLD_TEAM_SYLARY_LIST,
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			local ds = frame:GetRoot().ds
			local me = X.GetClientPlayer()
			if not me.IsInParty() and not X.IsDebugging('MY_GKP') then
				return X.Alert('MY_GKP_UI', _L['You are not in the team.'])
			end
			local team = GetClientTeam()
			if X.IsEmpty(ds:GetAuctionList()) then
				return X.Alert('MY_GKP_UI', _L['No Record'])
			end
			if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
				return X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
			end
			GetUserInput(_L['Total Amount of People with Output Settle Account'],function(num)
				if not tonumber(num) then return end
				local a, b = ds:GetAuctionSum()
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['Salary Settle Account'])
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Salary Statistic: income  %d Gold.', a))
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Salary Allowance: %d Gold.', b))
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Reall Salary: %d Gold.',a + b, a, b))
				if a + b >= 0 then
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Amount of People with Settle Account: %d',num))
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Actual per person: %d Gold.',math.floor((a + b) / num)))
				else
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['The Account is Negative, no money is coming out!'])
				end
			end, nil, nil, nil, team.GetTeamSize())
		end,
	})
	local function SendGKPInfoBgMsg(szMsgType, aBill, aAuction)
		FireUIEvent('MY_GKP_SEND_BEGIN')
		local szKey = X.GetUUID()
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {szMsgType, 'BEGIN', szKey})
		local nBeginTime, nEndTime = math.huge, 0
		local nMoney, nEquipNum, nEquipPrice, tEquipPrice = 0, 0, 0, {}
		for k, v in ipairs(aBill) do
			if v.szName ~= 'System' then
				local dwForceID, aItem = -1, {}
				for kk, vv in ipairs(aAuction) do
					if vv.szPlayer == v.szName then
						if vv.dwForceID and dwForceID == -1 then
							dwForceID = vv.dwForceID
						end
						if vv.nUiId == 0 then
							table.insert(aItem, { 'M', vv.szName, vv.nMoney })
						else
							local KItemInfo = GetItemInfo(vv.dwTabType, vv.dwIndex)
							if KItemInfo and KItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and KItemInfo.nQuality >= X.CONSTANT.ITEM_QUALITY.PURPLE then
								tEquipPrice[vv.nMoney] = true
								nEquipNum = nEquipNum + 1
								nEquipPrice = nEquipPrice + vv.nMoney
							end
							table.insert(aItem, { vv.dwTabType, vv.dwIndex, vv.nStackNum or vv.nBookID })
						end
						nMoney = nMoney + vv.nMoney
						nBeginTime = math.min(nBeginTime, vv.nTime)
						nEndTime = math.max(nEndTime, vv.nTime)
					end
				end
				X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {szMsgType, 'RECORD', szKey, v.szName, v.nGold, dwForceID, aItem})
			end
		end
		local nDuring = nEndTime >= nBeginTime and nEndTime - nBeginTime or 0
		local nGKPLevel = 0
		-- 根据总金额评分
		for k, v in ipairs({
			50000 , -- 黑出翔
			100000, -- 背锅
			250000, -- 脸帅
			500000, -- 自称小红手
			500000, -- 特别红
			500000, -- 玄晶专用
		}) do
			if v >= nMoney then
				nGKPLevel = k
				break
			end
		end
		if nEquipNum > 0 then
			-- 根据装备平均溢价百分比评分
			local aEquipPrice = {}
			for k, _ in pairs(tEquipPrice) do
				table.insert(aEquipPrice, k)
			end
			table.sort(aEquipPrice, function(a, b) return a < b end)
			local nEquipMinPrice = aEquipPrice[1] == 0 and aEquipPrice[2] or aEquipPrice[1]
			for i = 1, #aEquipPrice - 1 do
				nEquipMinPrice = math.min(nEquipMinPrice, aEquipPrice[i + 1] - aEquipPrice[i])
			end
			local fEquipPrice = nEquipPrice / nEquipNum / nEquipMinPrice
			for k, v in ipairs({
				1,   -- 黑出翔
				1.5, -- 背锅
				2,   -- 脸帅
				3,   -- 自称小红手
				5,   -- 特别红
			}) do
				if v >= fEquipPrice then
					if k >= nGKPLevel then
						nGKPLevel = k
					end
					break
				end
			end
		end
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {szMsgType, 'FINISH', szKey, nMoney, nDuring, nGKPLevel})
	end
	-- 发布拍卖记录
	nX = nW - 120 - 5
	ui:Append('WndButton', {
		name = 'GOLD_TEAM_BID_LIST',
		x = nX, y = 660, w = 120, text = g_tStrings.GOLD_TEAM_BID_LIST,
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			local ds = frame:GetRoot().ds
			local me = X.GetClientPlayer()
			if not me.IsInParty() and not X.IsDebugging('MY_GKP') then
				return X.Alert('MY_GKP_UI', _L['You are not in the team.'])
			end
			local tAuction = ds:GetAuctionPlayerSum()
			local aAuction = ds:GetAuctionList('nTime', 'desc')
			if X.IsEmpty(tAuction) then
				return X.Alert('MY_GKP_UI', _L['No Record'])
			end
			if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
				return X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
			end
			-- 处理数据
			local nTime = aAuction[1].nTime - aAuction[#aAuction].nTime -- 所花费的时间
			local nAuctionSum = ds:GetAuctionSum()
			local aBill = {}
			for k, v in pairs(tAuction) do
				table.insert(aBill, { szName = k, nGold = v })
			end
			table.sort(aBill, function(a, b) return a.nGold < b.nGold end)
			-- 聊天频道
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['--- Consumption ---'])
			for k, v in ipairs(aBill) do
				if v.nGold > 0 then
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, { D.GetFormatLink(v.szName, true), D.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
				end
			end
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Total Auction: %d Gold.', nAuctionSum))
			-- 弹出面板
			SendGKPInfoBgMsg('GKP_CONSUMPTION', aBill, aAuction)
		end,
	})
	-- 欠费情况
	nX = nX - 120 - 5
	ui:Append('WndButton', {
		name = 'Debt',
		x = nX, y = 660, w = 120, text = _L['Debt Issued'],
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			local ds = frame:GetRoot().ds
			local me = X.GetClientPlayer()
			if not me.IsInParty() and not X.IsDebugging('MY_GKP') then
				return X.Alert('MY_GKP_UI', _L['You are not in the team.'])
			end
			if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
				return X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
			end
			local tAuction = ds:GetAuctionPlayerSum()
			local tPayment = ds:GetPaymentPlayerSum()
			-- 处理数据
			local tBill = {}
			-- 欠账
			for k, v in pairs(tAuction) do
				tBill[k] = (tBill[k] or 0) - v
			end
			-- 正账
			for k, v in pairs(tPayment) do
				tBill[k] = (tBill[k] or 0) + v
			end
			-- 排序
			local aBill = {}
			for k, v in pairs(tBill) do
				if k ~= 'System' and v ~= 0 then
					table.insert(aBill, { szName = k, nGold = v })
				end
			end
			if X.IsEmpty(aBill) then
				return X.Alert('MY_GKP_UI', _L['No Record'])
			end
			table.sort(aBill, function(a, b) return a.nGold < b.nGold end)
			-- 聊天频道
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['Information on Debt'])
			for _, v in ipairs(aBill) do
				if v.nGold < 0 then
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, { D.GetFormatLink(v.szName, true), D.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
				else
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, { D.GetFormatLink(v.szName, true), D.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. '+' .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
				end
			end
			local nGold, nGold2 = 0, 0
			for szPlayer, nMoney in pairs(tPayment) do
				if szPlayer ~= 'System' then -- 必须要有交易对象
					if nMoney > 0 then
						nGold = nGold + nMoney
					else
						nGold2 = nGold2 + nMoney
					end
				end
			end
			if nGold ~= 0 then
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Received: %d Gold.', nGold))
			end
			if nGold2 ~= 0 then
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('Spending: %d Gold.', nGold2 * -1))
			end
			-- 弹出面板
			SendGKPInfoBgMsg('GKP_DEBT', aBill, ds:GetAuctionList())
		end,
	})
	-- 清空数据
	nX = nX - 120 - 5
	ui:Append('WndButton', {
		name = 'Btn_ClearRecord',
		x = nX, y = 660, w = 120, text = _L['Clear Record'],
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			local fnAction = function()
				MY_GKP_MI.NewDS()
			end
			X.Confirm(_L['Are you sure to wipe all of the records?'], fnAction)
		end,
	})
	-- 历史记录
	nX = nX - 120 - 5
	ui:Append('WndButton', {
		name = 'Btn_HistoryRecord',
		x = nX, y = 660, w = 120, text = _L['History record'],
		buttonStyle = 'FLAT_LACE_BORDER',
		menu = function()
			local menu = {}
			local aFiles = MY_GKP.GetHistoryFiles()
			for i = 1, math.min(#aFiles, 21) do
				local info = aFiles[i]
				table.insert(menu, {
					szOption = info.filename .. '.gkp',
					fnAction = function()
						D.Open(info.fullpath)
					end,
					szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
					nFrame = 49,
					nMouseOverFrame = 51,
					nIconWidth = 17,
					nIconHeight = 17,
					szLayer = 'ICON_RIGHTMOST',
					fnClickIcon = function()
						CPath.DelFile(info.fullpath)
						X.UI.ClosePopupMenu()
					end,
				})
			end
			if #menu > 0 then
				table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			end
			table.insert(menu, {
				szOption = _L['Manually load from file.'],
				rgb = { 255, 255, 0 },
				fnAction = function()
					local file = GetOpenFileName(
						_L['Please select gkp file.'],
						'GKP File(*.gkp,*.gkp.jx3dat)\0*.gkp;*.gkp.jx3dat\0All Files(*.*)\0*.*\0\0',
						X.FormatPath({'userdata/gkp', X.PATH_TYPE.ROLE})
					)
					if not X.IsEmpty(file) then
						D.Open(file)
					end
				end,
			})
			return menu
		end,
	})
	-- 同步数据
	nX = nX - 120 - 5
	ui:Append('WndButton', {
		name = 'Btn_SyncRecord',
		x = nX, y = 660, w = 120, text = _L['Manual SYNC'],
		buttonStyle = 'FLAT_LACE_BORDER',
		tip = {
			render = _L['Left click to sync from others, right click to sync to others'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		menuLClick = function()
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			local me = X.GetClientPlayer()
			if me.IsInParty() then
				local menu = MY_GKP.GetTeamMemberMenu(function(v)
					X.Confirm(_L('Wheater replace the current record with the synchronization [%s]\'s record?\n Please notice, this means you are going to lose the information of current record.', v.szName), function()
						X.Alert('MY_GKP_UI', _L('Asking for the sychoronization information...\n If no response in longtime, it may because [%s] is not using MY_GKP plugin or not responding.', v.szName))
						X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {'GKP_Sync', v.szName}) -- 请求同步信息
					end)
				end, true)
				table.insert(menu, 1, { bDevide = true })
				table.insert(menu, 1, { szOption = _L['Please select which will be the one you are going to ask record for.'], bDisable = true })
				return menu
			else
				X.Alert('MY_GKP_UI', _L['You are not in the team.'])
			end
		end,
		menuRClick = function()
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			local me = X.GetClientPlayer()
			if not me.IsInParty() then
				X.Alert('MY_GKP_UI', _L['You are not in the team.'])
			elseif not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
				X.Alert('MY_GKP_UI', _L['You are not the distrubutor.'])
			else
				local menu = MY_GKP.GetTeamMemberMenu(function(v)
					X.Confirm(_L('Wheater synchronize your record to [%s]?\n Please notice, this means the opposite sites are going to lose their information of current record.', v.szName), function()
						MY_GKP_MI.SyncSend(v.dwID)
					end)
				end, true)
				table.insert(menu, { bDevide = true })
				table.insert(menu, {
					szOption = _L['Full raid.'],
					fnAction = function()
						X.Confirm(_L['Wheater synchronize your record to full raid?\n Please notice, this means the opposite sites are going to lose their information of current record.'], function()
							MY_GKP_MI.SyncSend(0)
						end)
					end,
				})
				table.insert(menu, 1, { bDevide = true })
				table.insert(menu, 1, { szOption = _L['Please select which will be the one you are going to send record to.'], bDisable = true })
				return menu
			end
		end,
	})
	-- 重命名
	nX = nX - 120 - 5
	ui:Append('WndButton', {
		name = 'Btn_SetCaption',
		x = nX, y = 660, w = 120, text = _L['Set record caption'],
		buttonStyle = 'FLAT_LACE_BORDER',
		menu = function()
			local ds = frame:GetRoot().ds
			GetUserInput(_L['Please input new caption'],function(szText)
				if X.IsEmpty(szText) then
					return
				end
				local a, b = ds:SetMap(szText)
			end, nil, nil, nil, ds:GetMap())
		end,
	})
	-- 恢复历史记录
	nX = (nW - 20 - 120) / 2
	ui:Append('WndButton', {
		name = 'Btn_SetHistory',
		x = nX, y = 660, w = 120, text = _L['Set current record'],
		buttonStyle = 'FLAT_LACE_BORDER',
		menu = function()
			local frame = frame:GetRoot()
			X.Confirm(_L['Are you sure to cover the current information with the last record data?'], function()
				MY_GKP_MI.LoadHistory(frame.ds:GetFilePath())
				MY_GKP_MI.OpenPanel()
				X.UI.CloseFrame(frame)
				X.Alert('MY_GKP_UI', _L['Reocrd Recovered.'])
			end)
		end,
	})

	-- 排序
	local page = frame:Lookup('Page_GKP_Record')
	local t = {
		{'#',         false},
		{'szPlayer',  _L['Gainer']},
		{'szName',    _L['Name of the Items']},
		{'nMoney',    _L['Auction Price']},
		{'szNpcName', _L['Source of the Object']},
		{'nTime',     _L['Distribution Time']},
	}
	for k, v in ipairs(t) do
		if v[2] then
			local txt = page:Lookup('', 'Text_Record_Break' ..k)
			txt:RegisterEvent(786)
			txt:SetText(v[2])
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or 'asc'
				D.DrawAuctionPage(frame:GetRoot(), v[1], sort)
				if sort == 'asc' then
					txt.sort = 'desc'
				else
					txt.sort = 'asc'
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255, 255, 255)
			end
		end
	end

	-- 排序2
	local page = frame:Lookup('Page_GKP_Account')
	local t = {
		{'#',        false},
		{'szPlayer', _L['Transation Target']},
		{'nGold',    _L['Changes in Money']},
		{'szPlayer', _L['Ways of Money Change']},
		{'dwMapID',  _L['The Map of Current Location when Money Changes']},
		{'nTime',    _L['The Change of Time']},
	}

	for k, v in ipairs(t) do
		if v[2] then
			local txt = page:Lookup('', 'Text_Account_Break' .. k)
			txt:RegisterEvent(786)
			txt:SetText(v[2])
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or 'asc'
				D.DrawPaymentPage(frame:GetRoot(), v[1], sort)
				if sort == 'asc' then
					txt.sort = 'desc'
				else
					txt.sort = 'asc'
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255, 255, 255)
			end
		end
	end

	frame.SetDS = D.SetDS
	frame:RegisterEvent('MY_GKP_DATA_UPDATE')
	frame:RegisterEvent('MY_GKP_SEND_BEGIN')
	frame:RegisterEvent('MY_GKP_SEND_FINISH')
end

function D.OnFrameShow()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function D.OnFrameHide()
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function D.OnEvent(event)
	if event == 'MY_GKP_DATA_UPDATE' then
		if arg0 == '' or arg0 == this.ds:GetFilePath() then
			if arg1 == 'MAP' or arg1 == 'TIME' or arg1 == 'ALL' then
				D.DrawTitle(this)
			end
			if arg1 == 'AUCTION' or arg1 == 'PAYMENT' or arg1 == 'ALL' then
				if arg1 == 'AUCTION' or arg1 == 'ALL' then
					D.DrawAuctionPage(this)
				end
				if arg1 == 'PAYMENT' or arg1 == 'ALL' then
					D.DrawPaymentPage(this)
				end
				D.DrawStat(this)
			end
		end
	elseif event == 'MY_GKP_SEND_BEGIN' then
		this:Lookup('Debt'):Enable(false)
		this:Lookup('GOLD_TEAM_BID_LIST'):Enable(false)
	elseif event == 'MY_GKP_SEND_FINISH' then
		this:Lookup('Debt'):Enable(true)
		this:Lookup('GOLD_TEAM_BID_LIST'):Enable(true)
	end
end

function D.OnFrameKeyDown()
	if GetKeyName(Station.GetMessageKey()) == 'Esc' then
		X.UI.CloseFrame(this:GetRoot())
		return 1
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		X.UI.CloseFrame(this:GetRoot())
	end
end

function D.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == 'Text_Name' then
		if IsCtrlKeyDown() then
			return X.EditBox_AppendLinkPlayer(this:GetText())
		end
	end
end

function D.OnItemMouseEnter()
	local frame = this:GetRoot()
	if this:GetName() == 'Text_Name' then
		local data = this.data
		if not data.dwForceID then
			return
		end
		local szIcon, nFrame = GetForceImage(data.dwForceID)
		local r, g, b = X.GetForceColor(data.dwForceID)
		local aXml = {
			GetFormatImage(szIcon,nFrame,20,20),
			GetFormatText('  ' .. data.szPlayer .. g_tStrings.STR_COLON .. '\n', 136, r, g, b),
		}
		if IsCtrlKeyDown() then
			table.insert(aXml, GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. '\n', 136, 255, 0, 0))
			table.insert(aXml, GetFormatText(X.EncodeLUAData(data, ' '), 136, 255, 255, 255))
		else
			local tAuction, tSubsidy = frame.ds:GetAuctionPlayerSum()
			local tPayment = frame.ds:GetPaymentPlayerSum()
			local nAuction = tAuction[data.szPlayer] or 0
			local nSubsidy = tSubsidy[data.szPlayer] or 0
			local nPayment = tPayment[data.szPlayer] or 0
			local nSummary = math.max(nAuction + nSubsidy - nPayment, 0)
			table.insert(aXml, GetFormatText(_L['System Information as Shown Below\n\n'], 136, 255, 255, 255))
			local r, g, b = D.GetMoneyCol(nAuction)
			table.insert(aXml, GetFormatText(_L['Total Cosumption:'], 136, 255, 128, 0))
			table.insert(aXml, GetFormatText(nAuction ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n', 136, r, g, b))
			local r, g, b = D.GetMoneyCol(nSubsidy)
			table.insert(aXml, GetFormatText(_L['Total Allowance:'], 136, 255, 128, 0))
			table.insert(aXml, GetFormatText(nSubsidy .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n', 136, r, g, b))
			local r, g, b = D.GetMoneyCol(nPayment)
			table.insert(aXml, GetFormatText(_L['Total Payment:'], 136, 255, 128, 0))
			table.insert(aXml, GetFormatText(nPayment .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n', 136, r, g, b))
			local r, g, b = D.GetMoneyCol(nSummary)
			table.insert(aXml, GetFormatText(_L['Money on Debt:'], 136, 255, 128, 0))
			table.insert(aXml, GetFormatText(nSummary .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. '\n', 136, r, g, b))
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(table.concat(aXml), 400, { x, y, w, h })
	end
end

function D.OnItemMouseLeave()
	HideTip()
end

do
local nIndex = 0
function D.Open(szFilePath)
	local szName = 'MY_GKP'
	local ds = MY_GKP_DS(szFilePath)
	if ds == MY_GKP_MI.GetDS() then
		szName = szName .. '#MI'
		local frame = Station.Lookup('Normal/' .. szName)
		if frame then
			frame:Show()
			frame:BringToTop()
			return
		end
	else
		nIndex = nIndex + 1
		szName = szName .. '#' .. nIndex
	end
	local ui = X.UI.CreateFrame('MY_GKP_UI', { w = 1000, h = 700 })
	local frame = ui:Raw()
	D.InitFrame(frame)
	frame:SetName(szName)
	frame:SetDS(szFilePath)
	frame:BringToTop()
end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_GKP_UI',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'Open',
			},
			root = D,
		},
	},
}
MY_GKP_UI = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
