--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录主数据源实例化逻辑 (Main Instance)
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
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {
	Sysmsg = MY_GKP.Sysmsg,
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
local DS_ROOT = {'userdata/gkp/', PATH_TYPE.ROLE}
local DS_PATH = {'userdata/gkp/current.gkp', PATH_TYPE.ROLE}

function D.Init()
	if O.ds then
		return
	end
	O.ds = MY_GKP_DS(LIB.FormatPath(DS_PATH), true)
end

function D.GetDS()
	D.Init()
	return O.ds
end

function D.NewDS(bSilent)
	local ds = D.GetDS()
	if not ds:IsEmpty() then
		if not IsEmpty(ds:GetTime()) and not IsEmpty(ds:GetMap()) then
			local szRoot = LIB.FormatPath(DS_ROOT)
			local i, szNewPath = 0
			repeat
				szNewPath = szRoot
					.. LIB.FormatTime(ds:GetTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
					.. (i == 0 and '' or ('-' .. i))
					.. '_' .. ds:GetMap()
					.. '.gkp.jx3dat'
				i = i + 1
			until not IsLocalFileExist(LIB.FormatPath(szNewPath))
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
		LIB.Alert(_L['Records are wiped'])
	end
	FireUIEvent('MY_GKP_LOOT_BOSS')
end

function D.UpdateDSMeta()
	local ds = D.GetDS()
	local me = GetClientPlayer()
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
	if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		if not bSilent then
			LIB.Systopmsg(_L['Please unlock talk lock, otherwise gkp will not able to sync to teammate.'])
		end
		return
	end
	local ds = D.GetDS()
	local tab = {
		GKP_Record  = ds:GetAuctionList(),
		GKP_Account = ds:GetPaymentList(),
	}
	-- 密聊频道限制了字数 发起来太慢了
	local szKey = LIB.GetUUID():sub(1, 8)
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP_SYNC_START', {dwID, szKey})
	LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP_SYNC_CONTENT_' .. szKey, {dwID, tab})
end

LIB.RegisterInit('MY_GKP_MI', function()
	D.Init()
end)

LIB.RegisterBgMsg('MY_GKP_SYNC_START', function(_, aData, nChannel, dwID, szName, bIsSelf)
	local dwID, szKey = aData[1], aData[2]
	if dwID == UI_GetClientPlayerID() or dwID == 0 then
		LIB.RegisterBgMsg('MY_GKP_SYNC_CONTENT_' .. szKey, function(_, aData, nChannel, dwID, szName, bIsSelf)
			local dwID, tab = aData[1], aData[2]
			if dwID == UI_GetClientPlayerID() or dwID == 0 then
				LIB.Topmsg(_L['Sychoronization Complete'])
				if tab then
					LIB.Confirm(_L('Data Sharing Finished, you have one last chance to confirm wheather cover the current data with [%s]\'s data or not? \n data of team bidding: %s\n transation data: %s', szName, #tab.GKP_Record, #tab.GKP_Account), function()
						local ds = D.GetDS()
						ds:SetAuctionList(tab.GKP_Record)
						ds:SetPaymentList(tab.GKP_Account)
					end)
				else
					D.Sysmsg(_L['Abnormal with Data Sharing, Please contact and make feed back with the writer.'])
				end
			end
			LIB.RegisterBgMsg('MY_GKP_SYNC_CONTENT_' .. szKey, false)
		end, function(szMsgID, nSegCount, nSegRecv, nSegIndex, nChannel, dwID, szName, bIsSelf)
			local fPercent = nSegRecv / nSegCount
			LIB.Topmsg(_L('Sychoronizing data please wait %d%% loaded.', fPercent * 100))
		end)
	end
end)


LIB.RegisterBgMsg('MY_GKP', function(_, data, nChannel, dwID, szName, bIsSelf)
	local ds = D.GetDS()
	local me = GetClientPlayer()
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
				LIB.Debug('MY_GKP', '#MY_GKP# Sync Success', DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			end
		end
		if data[1] == 'GKP_INFO' then
			if data[2] == 'Start' then
				local szFrameName = data[3] == 'Information on Debt' and 'GKP_Debt' or 'GKP_info'
				if data[3] == 'Information on Debt' and szName ~= me.szName then -- 欠债记录只自己看
					return
				end
				local ui = UI.CreateFrame(szFrameName, { w = 800, h = 400, text = _L['GKP Golden Team Record'], close = true, anchor = 'CENTER' })
				local x, y = 20, 50
				ui:Append('Text', { x = x, y = y, w = 760, h = 30, text = _L[data[3]], halign = 1, font = 236, color = { 255, 255, 0 } })
				ui:Append('WndButton', { name = 'ScreenShot', x = x + 590, y = y, text = _L['Print Ticket'], buttonstyle = 'FLAT_LACE_BORDER' }):Toggle(false):Click(function()
					local scale         = Station.GetUIScale()
					local left, top     = ui:Pos()
					local width, height = ui:Size()
					local right, bottom = left + width, top + height
					local btn           = this
					local path          = GetRootPath() .. format('\\ScreenShot\\GKP_Ticket_%s.png', FormatTime('%Y-%m-%d_%H.%M.%S', GetCurrentTime()))
					btn:Hide()
					LIB.DelayCall(function()
						ScreenShot(path, 100, scale * left, scale * top, scale * right, scale * bottom)
						LIB.DelayCall(function()
							LIB.Alert(_L('Shot screen succeed, file saved as %s .', path))
							btn:Show()
						end)
					end, 50)
				end)
				ui:Append('Text', { w = 120, h = 30, x = x + 40, y = y + 35, text = _L('Operator:%s', szName), font = 41 })
				ui:Append('Text', { w = 720, h = 30, x = x, halign = 2, y = y + 35, text = _L('Print Time:%s', D.GetTimeString(GetCurrentTime())), font = 41 })
			end
			if data[2] == 'Info' then
				if data[3] == me.szName and tonumber(data[4]) and tonumber(data[4]) < 0 then
					LIB.OutputWhisper(data[3] .. g_tStrings.STR_COLON .. data[4] .. g_tStrings.STR_GOLD, _L['MY_GKP'])
				end
				local frm = Station.Lookup('Normal/GKP_info')
				if frm and frm.done then
					frm = Station.Lookup('Normal/GKP_Debt')
				end
				if not frm and Station.Lookup('Normal/GKP_Debt') then
					frm = Station.Lookup('Normal/GKP_Debt')
				end
				if frm then
					if not frm.n then frm.n = 0 end
					local n = frm.n
					local ui = UI(frm)
					local x, y = 20, 50
					if n % 2 == 0 then
						ui:Append('Image', { w = 760, h = 30, x = x, y = y + 70 + 30 * n, image = 'ui/Image/button/ShopButton.UITex', imageframe = 75 })
					end
					local dwForceID, tBox = -1, {}
					if me.IsInParty() then
						for k, v in ipairs(team.GetTeamMemberList()) do
							if team.GetClientTeamMemberName(v) == data[3] then
								dwForceID = team.GetMemberInfo(v).dwForceID
							end
						end
					end
					for k, v in ipairs(ds:GetAuctionList()) do -- 依赖于本地记录 反正也不可能差异到哪去
						if v.szPlayer == data[3] then
							if dwForceID == -1 then
								dwForceID = v.dwForceID
							end
							insert(tBox, v)
						end
					end
					if dwForceID ~= -1 then
						ui:Append('Image', { w = 28, h = 28, x = x + 30, y = y + 71 + 30 * n }):Image(GetForceImage(dwForceID))
					end
					ui:Append('Text', { w = 140, h = 30, x = x + 60, y = y + 70 + 30 * n, text = data[3], color = { LIB.GetForceColor(dwForceID) } })
					local handle = ui:Append('Handle', { w = 130, h = 20, x = x + 200, y = y + 70 + 30 * n, handlestyle = 3 })[1]
					handle:AppendItemFromString(D.GetMoneyTipText(tonumber(data[4])))
					handle:FormatAllItemPos()
					for k, v in ipairs(tBox) do
						if k > 12 then
							ui:Append('Text', { x = x + 290 + k * 32 + 5, y = y + 71 + 30 * n, w = 28, h = 28, text = '.....', font = 23 })
							break
						end
						local hBox = ui:Append('Box', { x = x + 290 + k * 32, y = y + 71 + 30 * n, w = 28, h = 28, alpha = v.bDelete and 60 })
						if v.nUiId ~= 0 then
							hBox:ItemInfo(v.nVersion, v.dwTabType, v.dwIndex, v.nStackNum or v.nBookID)
						else
							hBox:Icon(582):Hover(function(bHover)
								if bHover then
									local x, y = this:GetAbsPos()
									local w, h = this:GetSize()
									OutputTip(GetFormatText(v.szName .. g_tStrings.STR_TALK_HEAD_SAY1, 136) .. D.GetMoneyTipText(v.nMoney), 250, { x, y, w, h })
								else
									HideTip()
								end
							end)
						end
					end
					if frm.n > 5 then
						ui:Size(800, 30 * frm.n + 250):Anchor('CENTER')
					end
					frm.n = frm.n + 1
				end
			end
			if data[2] == 'End' then
				local szFrameName = data[4] and 'GKP_info' or 'GKP_Debt'
				local frm = Station.Lookup('Normal/' .. szFrameName)
				if frm then
					if data[4] then
						local ui = UI(frm)
						local x, y = 20, 50
						local n = frm.n or 0
						local nMoney = tonumber(data[4]) or 0
						local handle = ui:Append('Handle', { w = 230, h = 20, x = x + 30, y = y + 70 + 30 * n + 5, handlestyle = 3 })[1]
						handle:AppendItemFromString(GetFormatText(_L['Total Auction:'], 41) .. D.GetMoneyTipText(nMoney))
						handle:FormatAllItemPos()
						if LIB.IsDistributer() then
							ui:Append('WndButton', {
								w = 91, h = 26, x = x + 620, y = y + 70 + 30 * n + 5, text = _L['salary'],
								buttonstyle = 'SKEUOMORPHISM',
								onclick = function()
									LIB.Confirm(_L['Confirm?'], function()
										MY_GKP.Bidding(nMoney)
									end)
								end,
							})
						end
						if data[5] and tonumber(data[5]) then
							local nTime = tonumber(data[5])
							ui:Append('Text', { w = 725, h = 30, x = x + 0, y = y + 70 + 30 * n + 5, text = _L('Spend time approx %d:%d', nTime / 3600, nTime % 3600 / 60), halign = 1 })
						end
						UI(frm):Children('#ScreenShot'):Toggle(true)
						if n >= 4 then
							local t = {
								{ 50000,   1 }, -- 黑出翔
								{ 100000,  0 }, -- 背锅
								{ 250000,  2 }, -- 脸帅
								{ 500000,  6 }, -- 自称小红手
								{ 5000000, 3 }, -- 特别红
								{ 5000000, 5 }, -- 玄晶专用r
							}
							local nFrame = 4
							for k, v in ipairs(t) do
								if v[1] >= nMoney then
									nFrame = v[2]
									break
								end
							end
							local img = ui:Append('Image', {
								x = x + 590, y = y + n * 30 - 30, w = 150, h = 150, alpha = 180,
								image = PACKET_INFO.ROOT .. 'MY_GKP/img/GKPSeal.uitex', imageframe = nFrame,
								onhover = function(bHover)
									if bHover then
										this:SetAlpha(30)
									else
										this:SetAlpha(180)
									end
								end,
							})[1]
							-- JH.Animate(img, 200):Scale(4)
						end
						frm.done = true
					elseif szFrameName == 'GKP_Debt' and not frm:IsVisible() then
						Wnd.CloseWindow(frm)
					end
				end
				FireUIEvent('MY_GKP_SEND_FINISH')
			end
		end
	end
end)

LIB.RegisterEvent('ON_BG_CHANNEL_MSG.LR_GKP', function()
	local szMsgID, nChannel, dwID, szName, data, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == UI_GetClientPlayerID()
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
		LIB.Debug('MY_GKP', '#MY_GKP# Sync From LR Success', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
end)

LIB.RegisterEvent('LOADING_END',function()
	local ds = D.GetDS()
	if not ds:IsEmpty() then
		if LIB.IsInDungeon() and MY_GKP.bAlertMessage then
			LIB.Confirm(_L['Do you want to wipe the previous data when you enter the dungeon\'s map?'], D.NewDS)
		end
	else
		D.UpdateDSMeta()
	end
end)

---------------------------------------------------------------------->
-- 金钱记录
----------------------------------------------------------------------<
D.TradingTarget = {}

function D.MoneyUpdate(nGold, nSilver, nCopper)
	if nGold < 100 and not D.TradingTarget.szName then
		return
	end
	if not D.TradingTarget then
		return
	end
	if not D.TradingTarget.szName and not MY_GKP.bMoneySystem then
		return
	end
	local ds = D.GetDS()
	ds:SetPaymentRec({
		nGold     = nGold, -- API给的有问题 …… 只算金
		szPlayer  = D.TradingTarget.szName or 'System',
		dwForceID = D.TradingTarget.dwForceID,
		nTime     = GetCurrentTime(),
		dwMapID   = GetClientPlayer().GetMapID()
	})
	if D.TradingTarget.szName and MY_GKP.bMoneyTalk then
		if nGold > 0 then
			LIB.SendChat(PLAYER_TALK_CHANNEL.RAID, {
				D.GetFormatLink(_L['Received']),
				D.GetFormatLink(D.TradingTarget.szName, true),
				D.GetFormatLink(_L['The'] .. nGold ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		else
			LIB.SendChat(PLAYER_TALK_CHANNEL.RAID, {
				D.GetFormatLink(_L['Pay to']),
				D.GetFormatLink(D.TradingTarget.szName, true),
				D.GetFormatLink(' ' .. nGold * -1 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		end
	end
end

LIB.RegisterEvent('TRADING_OPEN_NOTIFY',function() -- 交易开始
	D.TradingTarget = GetPlayer(arg0)
end)
LIB.RegisterEvent('TRADING_CLOSE',function() -- 交易结束
	D.TradingTarget = {}
end)
LIB.RegisterEvent('MONEY_UPDATE',function() --金钱变动
	D.MoneyUpdate(arg0, arg1, arg2)
end)

---------------------------------------------------------------------->
-- 系统金团
----------------------------------------------------------------------<
function D.SyncSystemGKP()
	if not MY_GKP.bSyncSystem then
		return
	end
	local GetInfo = _G.GoldTeamBase_GetAllBiddingInfos
	if not GetInfo then
		local env = GetInsideEnv()
		GetInfo = env and env.GoldTeamBase_GetAllBiddingInfos
	end
	local aInfo = GetInfo and GetInfo()
	if not aInfo then
		return
	end
	local ds = D.GetDS()
	for _, v in ipairs(aInfo) do
		local szKey = concat({
			tostring(v.nBiddingInfoIndex),
			tostring(v.dwItemTabType),
			tostring(v.dwItemTabIndex),
			tostring(v.dwDoodadID),
			tostring(v.nType),
			tostring(v.nLootItemIndex),
			tostring(v.nStartTime),
		}, ',')
		-- 拍卖记录
		local item = not IsEmpty(v.dwItemID) and GetItem(v.dwItemID)
		local itemInfo = not IsEmpty(v.dwItemTabType) and not IsEmpty(v.dwItemTabIndex) and GetItemInfo(v.dwItemTabType, v.dwItemTabIndex)
		local player = GetPlayer(v.dwDestPlayerID)
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
			szNpcName  = IsEmpty(v.dwNpcTemplateID) and _L['Add Manually'] or LIB.GetTemplateName(TARGET.NPC, v.dwNpcTemplateID),
		}
		if item then
			local szName = LIB.GetObjectName('ITEM', v.dwItemID, 'never')
			if szName then
				tab.szName = szName
			end
			if item.nGenre == ITEM_GENRE.BOOK then
				tab.nBookID = item.nBookID
			end
			tab.nUiId = item.nUiId
			tab.nQuality = item.nQuality
		elseif itemInfo then
			local szName = LIB.GetObjectName('ITEM_INFO', v.dwItemTabType, v.dwItemTabIndex, 'never')
			if szName then
				tab.szName = szName
			end
			tab.nUiId = itemInfo.nUiId
			tab.nQuality = itemInfo.nQuality
		end
		if not tab.szName then
			tab.szName = v.szComment
		end
		if IsEmpty(tab.dwForceID) and not IsEmpty(dwForceID) then
			tab.dwForceID = dwForceID
		end
		tab.bDelete = v.nState == 0
		tab.bSystem = true
		ds:SetAuctionRec(tab)
		-- 付款记录
		if not IsEmpty(v.dwPayerID) and not IsEmpty(v.nPrice) then
			local player = GetPlayer(v.dwDestPlayerID) -- 记账到欠款人头上方便统计
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
			if IsEmpty(tab.dwForceID) and not IsEmpty(dwForceID) then
				tab.dwForceID = dwForceID
			end
			tab.bSystem = true
			ds:SetPaymentRec(tab)
		end
	end
end
LIB.RegisterEvent('BIDDING_OPERATION', function()
	if not MY_GKP.bSyncSystem then
		return
	end
	LIB.DelayCall('MY_GKP_MI__SyncSystemGKP', 150, D.SyncSystemGKP)
end)
LIB.RegisterInit('MY_GKP_MI__SyncSystemGKP', D.SyncSystemGKP)

---------------------------------------------------------------------->
-- 主界面
----------------------------------------------------------------------<
function D.OpenPanel()
	MY_GKP_Open(D.GetDS():GetFilePath())
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

LIB.RegisterHotKey('MY_GKP', _L['Open/Close Golden Team Record'], D.TogglePanel)
LIB.RegisterAddonMenu({ szOption = _L['Golden Team Record'], fnAction = D.OpenPanel })

-- Global exports
do
local settings = {
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
MY_GKP_MI = LIB.GeneGlobalNS(settings)
end
