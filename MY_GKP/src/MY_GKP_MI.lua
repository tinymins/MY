--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录主数据源实例化逻辑 (Main Instance)
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKP_MI'
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

local D = {
	Sysmsg = MY_GKP.OutputSystemMessage,
	GetTimeString = MY_GKP.GetTimeString,
	GetMoneyTipText = MY_GKP.GetMoneyTipText,
	GetFormatLink = MY_GKP.GetFormatLink,
}
local O = {
	ds          = nil,
	tSyncQueue  = {},
	bSync       = {},
	nSyncLen    = 0,
}
local DS_ROOT = {'userdata/gkp/', X.PATH_TYPE.ROLE}
local DS_PATH = {'userdata/gkp/current.gkp', X.PATH_TYPE.ROLE}

function D.Init()
	if O.ds then
		return
	end
	O.ds = MY_GKP_DS(X.FormatPath(DS_PATH), true)
end

function D.GetDS()
	D.Init()
	return O.ds
end

function D.NewDS(bSilent)
	local ds = D.GetDS()
	if not ds:IsEmpty() then
		if not X.IsEmpty(ds:GetTime()) and not X.IsEmpty(ds:GetMap()) then
			local szRoot = X.FormatPath(DS_ROOT)
			local i, szNewPath = 0
			repeat
				szNewPath = szRoot
					.. X.FormatTime(ds:GetTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
					.. (i == 0 and '' or ('-' .. i))
					.. '_' .. ds:GetMap()
					.. '.gkp.jx3dat'
				i = i + 1
			until not IsLocalFileExist(X.FormatPath(szNewPath))
			local dsNew = MY_GKP_DS(szNewPath, true)
			dsNew:SetTime(ds:GetTime())
			dsNew:SetMap(ds:GetMap())
			dsNew:SetAuctionList(ds:GetAuctionList())
			dsNew:SetPaymentList(ds:GetPaymentList())
		end
		ds:ClearData()
	end
	D.UpdateDSMeta()
	if not bSilent then
		X.Alert(_L['Records are wiped'])
	end
	FireUIEvent('MY_GKP_LOOT_BOSS')
end

function D.UpdateDSMeta()
	local ds = D.GetDS()
	local me = X.GetClientPlayer()
	ds:SetTime(GetCurrentTime())
	ds:SetMap(me and Table_GetMapName(me.GetMapID()) or '')
end

function D.NewAuction(tab, bSkipPanel)
	local ds = D.GetDS()
	if MY_GKP.bOn then
		MY_GKP_AuctionUI.Open(ds, tab, bSkipPanel and 'SKIP' or '')
	else -- 关闭的情况所有东西全部绕过
		if not tab.nMoney then
			tab.nMoney = 0
		end
		ds:SetAuctionRec(tab)
	end
end

function D.SyncSend(dwID, bSilent)
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		if not bSilent then
			X.OutputSystemAnnounceMessage(_L['Please unlock talk lock, otherwise gkp will not able to sync to teammate.'])
		end
		return
	end
	local ds = D.GetDS()
	local tab = {
		GKP_Record  = ds:GetAuctionList(),
		GKP_Account = ds:GetPaymentList(),
	}
	-- 密聊频道限制了字数 发起来太慢了
	local szKey = X.GetUUID():sub(1, 8)
	X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP_SYNC_START', {dwID, szKey})
	X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP_SYNC_CONTENT_' .. szKey, {dwID, tab})
end

X.RegisterInit('MY_GKP_MI', function()
	D.Init()
end)

X.RegisterBgMsg('MY_GKP_SYNC_START', function(_, aData, nChannel, dwID, szName, bIsSelf)
	local dwID, szKey = aData[1], aData[2]
	if dwID == X.GetClientPlayerID() or dwID == 0 then
		X.RegisterBgMsg('MY_GKP_SYNC_CONTENT_' .. szKey, szKey, function(_, aData, nChannel, dwID, szName, bIsSelf)
			local dwID, tab = aData[1], aData[2]
			if dwID == X.GetClientPlayerID() or dwID == 0 then
				X.OutputAnnounceMessage(_L['Sychoronization Complete'])
				if tab then
					X.Confirm(_L('Data Sharing Finished, you have one last chance to confirm wheather cover the current data with [%s]\'s data or not? \n data of team bidding: %s\n transation data: %s', szName, #tab.GKP_Record, #tab.GKP_Account), function()
						local ds = D.GetDS()
						ds:SetAuctionList(tab.GKP_Record)
						ds:SetPaymentList(tab.GKP_Account)
					end)
				else
					D.OutputSystemMessage(_L['Abnormal with Data Sharing, Please contact and make feed back with the writer.'])
				end
			end
			X.RegisterBgMsg('MY_GKP_SYNC_CONTENT_' .. szKey, szKey, false)
		end, function(szMsgID, nSegCount, nSegRecv, nSegIndex, nChannel, dwID, szName, bIsSelf)
			local fPercent = nSegRecv / nSegCount
			X.OutputAnnounceMessage(_L('Sychoronizing data please wait %d%% loaded.', fPercent * 100))
		end)
	end
end)


X.RegisterBgMsg('MY_GKP', function(_, data, nChannel, dwID, szName, bIsSelf)
	local ds = D.GetDS()
	local me = X.GetClientPlayer()
	local team = GetClientTeam()
	if team then
		if not bIsSelf then
			if data[1] == 'GKP_Sync' and data[2] == me.szName then
				D.SyncSend(dwID, true)
			elseif (data[1] == 'del' or data[1] == 'edit' or data[1] == 'add') and MY_GKP.bAutoSync then
				local tab = data[2]
				tab.bSync = true
				ds:SetAuctionRec(tab)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('MY_GKP', '#MY_GKP# Sync Success', X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		end
		if data[1] == 'GKP_CONSUMPTION' or data[1] == 'GKP_DEBT' then
			local szFrameName = data[1] == 'GKP_CONSUMPTION' and 'MY_GKP_Consumption' or 'MY_GKP_Debt'
			if data[2] == 'BEGIN' then
				X.UI.CloseFrame(szFrameName)
				local ui = X.UI.CreateFrame(szFrameName, { w = 800, h = 400, text = _L['GKP Golden Team Record'], close = true, anchor = 'CENTER' })
				local x, y = 20, 50
				local szCaption = data[1] == 'GKP_CONSUMPTION' and _L['--- Consumption ---'] or _L['Information on Debt']
				ui:Append('Text', { x = x, y = y, w = 760, h = 30, text = szCaption, alignHorizontal = 1, font = 236, color = { 255, 255, 0 } })
				ui:Append('WndButton', { name = 'ScreenShot', x = x + 590, y = y, text = _L['Print Ticket'], buttonStyle = 'FLAT_LACE_BORDER' }):Toggle(false):Click(function()
					local scale         = Station.GetUIScale()
					local left, top     = ui:Pos()
					local width, height = ui:Size()
					local right, bottom = left + width, top + height
					local btn           = this
					local path          = GetRootPath() .. string.format('\\ScreenShot\\GKP_Ticket_%s.png', FormatTime('%Y-%m-%d_%H.%M.%S', GetCurrentTime()))
					btn:Hide()
					X.DelayCall(function()
						ScreenShot(path, 100, scale * left, scale * top, scale * right, scale * bottom)
						X.DelayCall(function()
							X.Alert(_L('Shot screen succeed, file saved as %s .', path))
							btn:Show()
						end)
					end, 50)
				end)
				ui:Append('Text', { w = 120, h = 30, x = x + 40, y = y + 35, text = _L('Operator:%s', szName), font = 41 })
				ui:Append('Text', { w = 720, h = 30, x = x, alignHorizontal = 2, y = y + 35, text = _L('Print Time:%s', D.GetTimeString(GetCurrentTime())), font = 41 })
				ui[1].key = data[3]
			end
			if data[2] == 'RECORD' then
				if data[4] == me.szName and tonumber(data[5]) and tonumber(data[5]) < 0 then
					X.OutputWhisperMessage(data[4] .. g_tStrings.STR_COLON .. data[5] .. g_tStrings.STR_GOLD, _L['MY_GKP'])
				end
				local frm = Station.SearchFrame(szFrameName)
				if frm and frm.key == data[3] then
					if not frm.n then
						frm.n = 0
					end
					if not frm.items then
						frm.items = {}
					end
					for k, v in ipairs(data[7]) do
						table.insert(frm.items, v)
					end
					local n = frm.n
					local ui = X.UI(frm)
					local x, y = 20, 50
					if n % 2 == 0 then
						ui:Append('Image', { w = 760, h = 30, x = x, y = y + 70 + 30 * n, image = 'ui/Image/button/ShopButton.UITex', imageFrame = 75 })
					end
					ui:Append('Image', { w = 28, h = 28, x = x + 30, y = y + 71 + 30 * n }):Image(GetForceImage(data[6]))
					ui:Append('Text', { w = 140, h = 30, x = x + 60, y = y + 70 + 30 * n, text = data[4], color = { X.GetForceColor(data[6]) } })
					local handle = ui:Append('Handle', { w = 130, h = 20, x = x + 200, y = y + 70 + 30 * n, handleStyle = 3 })[1]
					handle:AppendItemFromString(D.GetMoneyTipText(tonumber(data[5])))
					handle:FormatAllItemPos()
					for k, v in ipairs(data[7]) do
						if k > 12 then
							ui:Append('Text', { x = x + 290 + k * 32 + 5, y = y + 71 + 30 * n, w = 28, h = 28, text = '.....', font = 23 })
							break
						end
						local hBox = ui:Append('Box', { x = x + 290 + k * 32, y = y + 71 + 30 * n, w = 28, h = 28, alpha = v.bDelete and 60 })
						if v[1] == 'M' then
							hBox:Icon(582):Hover(function(bHover)
								if bHover then
									local x, y = this:GetAbsPos()
									local w, h = this:GetSize()
									OutputTip(GetFormatText(v[2] .. g_tStrings.STR_TALK_HEAD_SAY1, 136) .. D.GetMoneyTipText(v[3]), 250, { x, y, w, h })
								else
									HideTip()
								end
							end)
						else
							hBox:ItemInfo(X.ENVIRONMENT.GAME_VERSION, v[1], v[2], v[3])
						end
					end
					if frm.n > 5 then
						ui:Size(800, 30 * frm.n + 250):Anchor('CENTER')
					end
					frm.n = frm.n + 1
				end
			end
			if data[2] == 'FINISH' then
				local frm = Station.SearchFrame(szFrameName)
				if frm and frm.key == data[3] then
					if data[1] == 'GKP_CONSUMPTION' then
						local ui = X.UI(frm)
						local x, y = 20, 50
						local n = frm.n or 0
						local nMoney = tonumber(data[4]) or 0
						local handle = ui:Append('Handle', { w = 230, h = 20, x = x + 30, y = y + 70 + 30 * n + 5, handleStyle = 3 })[1]
						handle:AppendItemFromString(GetFormatText(_L['Total Auction:'], 41) .. D.GetMoneyTipText(nMoney))
						handle:FormatAllItemPos()
						if X.IsClientPlayerTeamDistributor() and X.IS_REMAKE then
							ui:Append('WndButton', {
								w = 91, h = 26, x = x + 620, y = y + 70 + 30 * n + 5, text = _L['salary'],
								buttonStyle = 'SKEUOMORPHISM',
								onClick = function()
									X.Confirm(_L['Confirm?'], function()
										MY_GKP.Bidding(nMoney)
									end)
								end,
							})
						end
						local nTime = tonumber(data[5]) or 0
						if nTime > 0 then
							ui:Append('Text', { w = 725, h = 30, x = x + 0, y = y + 70 + 30 * n + 5, text = _L('Spend time approx %d:%d', nTime / 3600, nTime % 3600 / 60), alignHorizontal = 1 })
						end
						X.UI(frm):Children('#ScreenShot'):Toggle(true)
						if n >= 4 and data[6] then
							local nGKPLevel = data[6]
							local aGKPLevelFrame = {
								1, -- 黑出翔
								0, -- 背锅
								2, -- 脸帅
								6, -- 自称小红手
								3, -- 特别红
								5, -- 玄晶专用
							}
							local nFrame = aGKPLevelFrame[math.min(#aGKPLevelFrame, math.max(1, nGKPLevel))]
							local nImgW, nImgH = 150, 150
							local nCenterX, nCenterY = x + 590 + nImgW / 2, y + n * 30 - 30 + nImgH / 2
							local nInitAlpha, nDistAlpha = 180, 60
							local img = ui:Append('Image', {
								x = 0, y = 0, w = 0, h = 0, alpha = nInitAlpha,
								image = X.PACKET_INFO.ROOT .. 'MY_GKP/img/GKPSeal.uitex', imageFrame = nFrame,
							})[1]
							local nStartTick = GetTime()
							local SCALE_ANIMATE_TIME = 200
							local IDLE_ANIMATE_TIME = 1000
							local ALPHA_ANIMATE_TIME = 500
							X.RenderCall(function()
								if not X.IsElement(img) then
									return 0
								end
								local nTime = GetTime() - nStartTick
								local fScale = math.max(1, (1 - nTime / SCALE_ANIMATE_TIME) * 3 + 1)
								img:SetSize(nImgW * fScale, nImgH * fScale)
								img:SetRelPos(nCenterX - nImgW * fScale / 2, nCenterY - nImgH * fScale / 2)
								img:SetAbsPos(img:GetParent():GetAbsX() + img:GetRelX(), img:GetParent():GetAbsY() + img:GetRelY())
								if nTime >= SCALE_ANIMATE_TIME + IDLE_ANIMATE_TIME then
									img:SetAlpha(nDistAlpha + math.max(0, (1 - (nTime - SCALE_ANIMATE_TIME - IDLE_ANIMATE_TIME) / ALPHA_ANIMATE_TIME)) * (nInitAlpha - nDistAlpha))
									if nTime >= SCALE_ANIMATE_TIME + IDLE_ANIMATE_TIME + ALPHA_ANIMATE_TIME then
										return 0
									end
								end
							end)
							-- JH.Animate(img, 200):Scale(4)
						end
						frm.done = true
					elseif data[1] == 'GKP_DEBT' and not frm:IsVisible() then
						X.UI.CloseFrame(frm)
					end
				end
				FireUIEvent('MY_GKP_SEND_FINISH')
			end
		end
	end
end)

X.RegisterEvent('ON_BG_CHANNEL_MSG', 'LR_GKP', function()
	local szMsgID, nChannel, dwID, szName, data, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == X.GetClientPlayerID()
	if szMsgID ~= 'LR_GKP' or bSelf then
		return
	end
	if (data[1] == 'SYNC' or data[1] == 'DEL') and MY_GKP.bAutoSync then
		local ds = D.GetDS()
		local rawData = data[2]
		local tab = {
			bSync = true,
			bEdit = true,
			bDelete = data[1] == 'DEL',
			szPlayer = rawData.szPurchaserName,
			dwIndex = rawData.dwIndex,
			dwTabType = rawData.dwTabType,
			nQuality = rawData.nQuality,
			nVersion = rawData.nVersion or 0,
			nGenre = rawData.nGenre,
			nTime = rawData.nCreateTime,
			nMoney = rawData.nGold,
			key = rawData.hash,
			dwForceID = rawData.dwPurchaserForceID,
			szName = rawData.szName,
			dwDoodadID = rawData.dwDoodadID or 0,
			nUiId = rawData.nUiId or 0,
			szNpcName = rawData.szSourceName,
			nBookID = rawData.nGenre == ITEM_GENRE.BOOK
				and rawData.nBookID and rawData.nBookID ~= 0
				and rawData.nBookID or nil,
			nStackNum = rawData.nStackNum,
		}
		ds:SetAuctionRec(tab)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_GKP', '#MY_GKP# Sync From LR Success', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end)

X.RegisterEvent('LOADING_END',function()
	local ds = D.GetDS()
	if not ds:IsEmpty() then
		if X.IsInDungeonMap() and MY_GKP.bAlertMessage then
			X.Confirm(_L['Do you want to wipe the previous data when you enter the dungeon\'s map?'], D.NewDS)
		end
	else
		D.UpdateDSMeta()
	end
end)

---------------------------------------------------------------------->
-- 金钱记录
----------------------------------------------------------------------<
D.tTradingInfo = {}

function D.MoneyUpdate(nGold, nSilver, nCopper)
	if math.abs(nGold) < 1 then -- 不足1金不记录
		return
	end
	local szPeerName = 'System'
	if D.tTradingInfo and D.tTradingInfo.dwPeerID
	and D.tTradingInfo.bSelfConfirm and D.tTradingInfo.bPeerConfirm then
		szPeerName = D.tTradingInfo.szPeerName
	end
	-- 不记录系统交易变动，则直接返回
	if szPeerName == 'System' and not MY_GKP.bMoneySystem then
		return
	end
	-- 不记录10金以下系统交易变动
	if nGold < 10 and szPeerName == 'System' then
		return
	end
	local ds = D.GetDS()
	ds:SetPaymentRec({
		nGold     = nGold, -- API给的有问题 …… 只算金
		szPlayer  = szPeerName,
		dwForceID = D.tTradingInfo.dwForceID,
		nTime     = GetCurrentTime(),
		dwMapID   = X.GetClientPlayer().GetMapID()
	})
	if MY_GKP.bMoneyTalk and szPeerName ~= 'System'
	and (not MY_GKP.bMoneyTalkOnlyDistributor or X.IsPlayerTeamDistributor(D.tTradingInfo.dwID) or X.IsClientPlayerTeamDistributor()) then
		if nGold > 0 then
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, {
				D.GetFormatLink(_L['Received']),
				D.GetFormatLink(szPeerName, true),
				D.GetFormatLink(_L['The'] .. nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		else
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, {
				D.GetFormatLink(_L['Pay to']),
				D.GetFormatLink(szPeerName, true),
				D.GetFormatLink(' ' .. nGold * -1 .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		end
	end
end

X.RegisterEvent('TRADING_OPEN_NOTIFY', function() -- 交易开始
	local tar = X.GetPlayer(arg0)
	if not tar then
		return
	end
	D.tTradingInfo = { dwPeerID = tar.dwID, dwForceID = tar.dwForceID, szPeerName = X.GetPlayerName(tar.dwID, { eShowID = 'never' }) or 'Unknown' }
end)
X.RegisterEvent('TRADING_UPDATE_CONFIRM', function() -- 交易确认
	local dwID, bConfirm = arg0, arg1
	if not D.tTradingInfo then
		return
	end
	if dwID == X.GetClientPlayerID() then
		D.tTradingInfo.bSelfConfirm = bConfirm
	elseif dwID == D.tTradingInfo.dwPeerID then
		D.tTradingInfo.bPeerConfirm = bConfirm
	end
end)
X.RegisterEvent('MONEY_UPDATE', function() --金钱变动
	D.MoneyUpdate(arg0, arg1, arg2)
end)
X.RegisterEvent('TRADING_CLOSE', function() -- 交易结束
	D.tTradingInfo = {}
end)

---------------------------------------------------------------------->
-- 系统金团
----------------------------------------------------------------------<
function D.SyncSystemGKP()
	if not MY_GKP.bSyncSystem then
		return
	end
	local GetInfo = X.GetGameAPI('GoldTeamBase_GetAllBiddingInfos')
	local aInfo = GetInfo and GetInfo()
	if not aInfo then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]
	local ds = D.GetDS()
	for _, v in ipairs(aInfo) do
		local szKey = table.concat({
			tostring(v.nBiddingInfoIndex),
			tostring(v.dwItemTabType),
			tostring(v.dwItemTabIndex),
			tostring(v.dwDoodadID),
			tostring(v.nType),
			tostring(v.nLootItemIndex),
			tostring(v.nStartTime),
		}, ',')
		-- 拍卖记录
		local item = not X.IsEmpty(v.dwItemID) and GetItem(v.dwItemID)
		local itemInfo = not X.IsEmpty(v.dwItemTabType) and not X.IsEmpty(v.dwItemTabIndex) and GetItemInfo(v.dwItemTabType, v.dwItemTabIndex)
		local player = X.GetPlayer(v.dwDestPlayerID)
		local dwForceID = player and player.dwForceID
		if not dwForceID then
			if MY_Farbnamen and MY_Farbnamen.Get then
				local data = MY_Farbnamen.Get(v.dwDestPlayerID)
				if data then
					dwForceID = data.dwForceID
				end
			end
		end
		local tab = ds:GetAuctionRec(szKey) or {
			key        = szKey,
			nUiId      = 0,
			dwTabType  = v.dwItemTabType or 0,
			dwDoodadID = v.dwDoodadID or 0,
			nQuality   = 1,
			nVersion   = 0,
			dwIndex    = v.dwItemTabIndex or 0,
			nTime      = v.nStartTime or 0,
			dwForceID  = dwForceID or 0,
			szPlayer   = v.szDestPlayerName or 0,
			nMoney     = v.nPrice or 0,
			szNpcName  = X.IsEmpty(v.dwNpcTemplateID) and _L['Add Manually'] or X.GetNpcTemplateName(v.dwNpcTemplateID),
		}
		if item then
			local szName = X.GetItemName(v.dwItemID, { eShowID = 'never' })
			if szName then
				tab.szName = szName
			end
			if item.nGenre == ITEM_GENRE.BOOK then
				tab.nBookID = item.nBookID
			end
			tab.nUiId = item.nUiId
			tab.nQuality = item.nQuality
		elseif itemInfo then
			local szName = X.GetItemInfoName(v.dwItemTabType, v.dwItemTabIndex, 0, { eShowID = 'never' })
			if szName then
				tab.szName = szName
			end
			tab.nUiId = itemInfo.nUiId
			tab.nQuality = itemInfo.nQuality
		end
		if not tab.szName then
			tab.szName = v.szComment
		end
		if X.IsEmpty(tab.dwForceID) and not X.IsEmpty(dwForceID) then
			tab.dwForceID = dwForceID
		end
		tab.bDelete = v.nState == 0
		tab.bSystem = true
		ds:SetAuctionRec(tab)
		-- 付款记录
		if not X.IsEmpty(v.dwPayerID) and not X.IsEmpty(v.nPrice) then
			local player = X.GetPlayer(v.dwDestPlayerID) -- 记账到欠款人头上方便统计
			local dwForceID = player and player.dwForceID
			if not dwForceID then
				if MY_Farbnamen and MY_Farbnamen.Get then
					local data = MY_Farbnamen.Get(v.dwDestPlayerID)
					if data then
						dwForceID = data.dwForceID
					end
				end
			end
			local tab = ds:GetPaymentRec(szKey) or {
				key = szKey,
				nGold = v.nPrice or 0,
				szPlayer = v.szDestPlayerName or '', -- v.szPayerName
				dwForceID = dwForceID or 0,
				dwMapID = 0,
				nTime = v.nStartTime or 0,
			}
			if X.IsEmpty(tab.dwForceID) and not X.IsEmpty(dwForceID) then
				tab.dwForceID = dwForceID
			end
			tab.bSystem = true
			ds:SetPaymentRec(tab)
		end
	end
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.OutputDebugMessage(
		_L['PMTool'],
		_L('MY_GKP_MI SyncSystemGKP in %dms.', nTickCount),
		X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
end
X.RegisterEvent('BIDDING_OPERATION', function()
	if not MY_GKP.bSyncSystem then
		return
	end
	X.DelayCall('MY_GKP_MI__SyncSystemGKP', 150, D.SyncSystemGKP)
end)
X.RegisterInit('MY_GKP_MI__SyncSystemGKP', D.SyncSystemGKP)

---------------------------------------------------------------------->
-- 主界面
----------------------------------------------------------------------<
function D.OpenPanel()
	MY_GKP_UI.Open(D.GetDS():GetFilePath())
end

function D.ClosePanel()
	local frame = Station.Lookup('Normal/MY_GKP#MI')
	if frame then
		frame:Hide()
	end
end

function D.IsOpened()
	local frame = Station.Lookup('Normal/MY_GKP#MI')
	return frame and frame:IsVisible()
end

function D.TogglePanel()
	if D.IsOpened() then
		D.ClosePanel()
	else
		D.OpenPanel()
	end
end

function D.LoadHistory(szFilePath)
	local dsHist = MY_GKP_DS(szFilePath)
	if dsHist then
		local ds = D.GetDS()
		D.NewDS(true)
		ds:SetTime(dsHist:GetTime())
		ds:SetMap(dsHist:GetMap())
		ds:SetAuctionList(dsHist:GetAuctionList())
		ds:SetPaymentList(dsHist:GetPaymentList())
		CPath.DelFile(szFilePath)
	end
end

X.RegisterHotKey('MY_GKP', _L['Open/Close Golden Team Record'], D.TogglePanel)
X.RegisterAddonMenu({ szOption = _L['Golden Team Record'], fnAction = D.OpenPanel })

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_GKP_MI',
	exports = {
		{
			fields = {
				GetDS = D.GetDS,
				NewDS = D.NewDS,
				NewAuction = D.NewAuction,
				SyncSend = D.SyncSend,
				OpenPanel = D.OpenPanel,
				ClosePanel = D.ClosePanel,
				IsOpened = D.IsOpened,
				TogglePanel = D.TogglePanel,
				LoadHistory = D.LoadHistory,
			},
		},
	},
}
MY_GKP_MI = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
