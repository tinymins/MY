--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 物品价格查询
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
X.RegisterRestriction('MY_ItemPrice', { ['*'] = false, classic = true })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ItemPrice', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nW = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 480,
	},
	nH = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 640,
	},
})
local D = {}

function D.OnWebSizeChange()
	O.nW, O.nH = this:GetSize()
end

function D.Open(dwTabType, dwTabIndex, nBookID)
	if nBookID < 0 then
		nBookID = nil
	end
	local szName = X.GetObjectName('ITEM_INFO', dwTabType, dwTabIndex, nBookID)
	if not szName then
		return
	end
	local me = GetClientPlayer()
	local line = X.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex })
	local aPath = {dwTabType, dwTabIndex}
	if nBookID then
		table.insert(aPath, nBookID)
	end
	local szURL = 'https://page.j3cx.com/item/' .. table.concat(aPath, '/') .. '/price?'
		.. X.EncodePostData(X.UrlEncode({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			server = AnsiToUTF8(line and line.szCenterName or X.GetRealServer(2)),
			player = AnsiToUTF8(GetUserRoleName()), item = AnsiToUTF8(szName),
		}))
	local szKey = 'ItemPrice_' .. table.concat(aPath, '_')
	local szTitle = szName
	szKey = UI.OpenBrowser(szURL, {
		key = szKey,
		title = szTitle,
		w = O.nW, h = O.nH,
		readonly = true,
	})
	UI(UI.LookupBrowser(szKey)):Size(D.OnWebSizeChange)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	if not X.IsRestricted('MY_ItemPrice') then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 'auto',
			text = _L['Item price'],
			checked = MY_ItemPrice.bEnable,
			oncheck = function(bChecked)
				if bChecked then
					local ui = UI(this)
					X.Confirm(_L['Check this will show price entry in bag item menu, and will share price when search auction, are you sure?'], function()
						MY_ItemPrice.bEnable = bChecked
						ui:Check(true, WNDEVENT_FIRETYPE.PREVENT)
					end)
					ui:Check(false, WNDEVENT_FIRETYPE.PREVENT)
				else
					MY_ItemPrice.bEnable = bChecked
				end
			end,
			tip = _L['Hold SHIFT and r-click bag box to show item price, share price when search auction.'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		}):Width() + 5
	end
	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_ItemPrice',
	exports = {
		{
			fields = {
				'Open',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'nW',
				'nH',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'nW',
				'nH',
			},
			root = O,
		},
	},
}
MY_ItemPrice = X.CreateModule(settings)
end

Box_AppendAddonMenu({function(box)
	if not X.IsElement(box) or box:GetType() ~= 'Box' or not O.bEnable then
		return
	end
	local _, dwBox, dwX = box:GetObjectData()
	if not dwBox or not dwX then
		return
	end
	local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
	if not item then
		return
	end
	local dwTabType = item.dwTabType
	local dwTabIndex = item.dwIndex
	local nBookID = item.nGenre == ITEM_GENRE.BOOK and item.nBookID or -1
	local menu = {}
	if not item.bBind then
		table.insert(menu, {
			szOption = _L['Lookup price'],
			fnAction = function() D.Open(dwTabType, dwTabIndex, nBookID) end,
		})
	elseif CONSTANT.FLOWERS_UIID[item.nUiId] then
		table.insert(menu, {
			szOption = _L['Lookup flower price'],
			fnAction = function() D.Open(dwTabType, dwTabIndex, nBookID) end,
		})
	end
	return menu
end})

local function GetItemKey(it)
	if it.nGenre == ITEM_GENRE.BOOK then
		return X.NumberBaseN(it.dwTabType, 32) .. '_'
			.. X.NumberBaseN(it.dwIndex, 32) .. '_'
			.. X.NumberBaseN(it.nBookID, 32)
	end
	return X.NumberBaseN(it.dwTabType, 32) .. '_' .. X.NumberBaseN(it.dwIndex, 32)
end
X.RegisterEvent('AUCTION_LOOKUP_RESPOND', function()
	if not O.bEnable then
		return
	end
	if arg0 == AUCTION_RESPOND_CODE.SUCCEED and arg1 == 0 then
		-- 获取数据
		local AuctionClient = GetAuctionClient()
		local nCount, aInfo = AuctionClient.GetLookupResult(arg1)
		local dwBaseID = math.huge
		local tItemGroup = {}
		for _, info in ipairs(aInfo) do
			local szKey = GetItemKey(info.Item)
			local nPrice = GoldSilverAndCopperToMoney(info.BuyItNowPrice.nGold, info.BuyItNowPrice.nSilver, info.BuyItNowPrice.nCopper)
			if not tItemGroup[szKey] then
				tItemGroup[szKey] = {}
			end
			table.insert(tItemGroup[szKey], {
				dwID = info.ID,
				nCount = info.Item.bCanStack
					and info.Item.nStackNum
					or 1,
				nPrice = nPrice,
			})
			dwBaseID = math.min(dwBaseID, info.ID)
		end
		if X.IsHugeNumber(dwBaseID) then
			return
		end
		local aData = {}
		-- 重组数据
		for szKey, aItemInfo in pairs(tItemGroup) do
			-- 价格升序
			table.sort(aItemInfo, function(a, b)
				return a.nPrice < b.nPrice
			end)
			-- 价格序列化
			local aPrice = {}
			for i, v in ipairs(aItemInfo) do
				-- 压缩数据长度，仅第一个为32进制价格，后面的为与前一个的价格差
				if i == 1 then
					aPrice[i] = X.NumberBaseN(v.nPrice, 32)
				else
					aPrice[i] = X.NumberBaseN(v.nPrice - aItemInfo[i - 1].nPrice, 32)
				end
				aPrice[i] = aPrice[i] .. '_' .. X.NumberBaseN(v.nCount, 32) .. '_' .. X.NumberBaseN(v.dwID - dwBaseID, 32)
			end
			table.insert(aData, szKey .. '-' .. table.concat(aPrice, '-'))
		end
		local szData = table.concat(aData, ' ')
		local szURL = 'https://push.j3cx.com/api/item/price?'
			.. X.EncodePostData(X.UrlEncode(X.SignPostData({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				r = AnsiToUTF8(X.GetRealServer(1)), -- Region
				s = AnsiToUTF8(X.GetRealServer(2)), -- Server
				t = GetCurrentTime(), -- Time
				d = AnsiToUTF8(szData), -- Price data
				ib = X.NumberBaseN(dwBaseID, 32),
			}, 'e87d2e0a-d3bd-4095-af48-e50dfe58f36b')))
		-- 延迟一帧 否则系统还没更新界面数据
		X.DelayCall(function()
			-- 保证第一页
			local txtPage = Station.Lookup('Normal/AuctionPanel/PageSet_Totle/Page_Business/Wnd_Result2', 'Text_Page')
			if not txtPage or txtPage:GetText():find('1-', nil, true) ~= 1 then
				return
			end
			-- 保证一口价升序
			local imgPriceUp = Station.Lookup('Normal/AuctionPanel/PageSet_Totle/Page_Business/Wnd_Result2/CheckBox_Price', 'Image_PriceNameUp')
			if not imgPriceUp or not imgPriceUp:IsVisible() then
				return
			end
			X.Ajax({ driver = 'auto', mode = 'auto', method = 'auto', url = szURL })
		end)
	end
end)
