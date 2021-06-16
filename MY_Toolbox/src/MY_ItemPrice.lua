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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_ItemPrice', _L['MY_Toolbox'], {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_ItemPrice'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nW = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_ItemPrice'],
		xSchema = Schema.Number,
		xDefaultValue = 480,
	},
	nH = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_ItemPrice'],
		xSchema = Schema.Number,
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
	local szName = LIB.GetObjectName('ITEM_INFO', dwTabType, dwTabIndex, nBookID)
	if not szName then
		return
	end
	local me = GetClientPlayer()
	local line = LIB.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex })
	local aPath = {dwTabType, dwTabIndex}
	if nBookID then
		insert(aPath, nBookID)
	end
	local szURL = 'https://page.j3cx.com/item/' .. concat(aPath, '/') .. '/price?'
		.. LIB.EncodePostData(LIB.UrlEncode({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			server = AnsiToUTF8(line and line.szCenterName or LIB.GetRealServer(2)),
			player = AnsiToUTF8(GetUserRoleName()), item = AnsiToUTF8(szName),
		}))
	local szKey = 'ItemPrice_' .. concat(aPath, '_')
	local szTitle = szName
	szKey = UI.OpenBrowser(szURL, {
		key = szKey,
		title = szTitle,
		w = O.nW, h = O.nH,
		readonly = true,
	})
	UI(UI.LookupBrowser(szKey)):Size(D.OnWebSizeChange)
end

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Item price'],
		checked = MY_ItemPrice.bEnable,
		oncheck = function(bChecked)
			MY_ItemPrice.bEnable = bChecked
		end,
		tip = _L['Hold SHIFT and r-click bag box to show item price'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
	}):Width() + 5
	return x, y
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
MY_ItemPrice = LIB.CreateModule(settings)
end

Box_AppendAddonMenu({function(box)
	if not IsElement(box) or box:GetType() ~= 'Box' or not O.bEnable then
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
		insert(menu, {
			szOption = _L['Lookup price'],
			fnAction = function() D.Open(dwTabType, dwTabIndex, nBookID) end,
		})
	elseif CONSTANT.FLOWERS_UIID[item.nUiId] then
		insert(menu, {
			szOption = _L['Lookup flower price'],
			fnAction = function() D.Open(dwTabType, dwTabIndex, nBookID) end,
		})
	end
	return menu
end})

local function GetItemKey(it)
	if it.nGenre == ITEM_GENRE.BOOK then
		return LIB.NumberBaseN(it.dwTabType, 32) .. '_'
			.. LIB.NumberBaseN(it.dwIndex, 32) .. '_'
			.. LIB.NumberBaseN(it.nBookID, 32)
	end
	return LIB.NumberBaseN(it.dwTabType, 32) .. '_' .. LIB.NumberBaseN(it.dwIndex, 32)
end
LIB.RegisterEvent('AUCTION_LOOKUP_RESPOND', function()
	if not O.bEnable then
		return
	end
	if arg0 == AUCTION_RESPOND_CODE.SUCCEED then
		-- 获取数据
		local AuctionClient = GetAuctionClient()
		local nCount, aInfo = AuctionClient.GetLookupResult(arg1)
		SaveLUAData('interface/a.jx3dat', {AuctionClient.GetLookupResult(arg1)}, {indent = '\t'})
		local tItemPrice = {}
		for _, info in ipairs(aInfo) do
			local szKey = GetItemKey(info.Item)
			local nPrice = GoldSilverAndCopperToMoney(info.BuyItNowPrice.nGold, info.BuyItNowPrice.nSilver, info.BuyItNowPrice.nCopper)
			if not tItemPrice[szKey] then
				tItemPrice[szKey] = {}
			end
			if not tItemPrice[szKey][nPrice] then
				tItemPrice[szKey][nPrice] = 0
			end
			tItemPrice[szKey][nPrice] = tItemPrice[szKey][nPrice] + (info.Item.bCanStack and info.Item.nStackNum or 1)
		end
		local aData = {}
		-- 重组数据
		for szKey, tPrice in pairs(tItemPrice) do
			local aPriceStat = {}
			for nPrice, nCount in pairs(tPrice) do
				insert(aPriceStat, {
					nPrice = nPrice,
					nCount = nCount,
				})
			end
			-- 价格升序
			sort(aPriceStat, function(a, b)
				return a.nPrice < b.nPrice
			end)
			-- 价格序列化
			local aPrice = {}
			for i, v in ipairs(aPriceStat) do
				-- 压缩数据长度，仅第一个为32进制价格，后面的为与前一个的价格差
				if i == 1 then
					aPrice[i] = LIB.NumberBaseN(v.nPrice, 32)
				else
					aPrice[i] = LIB.NumberBaseN(v.nPrice - aPriceStat[i - 1].nPrice, 32)
				end
				aPrice[i] = aPrice[i] .. '_' .. LIB.NumberBaseN(v.nCount, 32)
			end
			-- 压缩数据长度，因为很多人会一件售卖，所以差价实际是一样的，也就是等差数列，所以重复的等差使用简写（.nRepeat）
			local nIndex, nRepeat = 2, 0
			while nIndex < #aPrice do
				nRepeat = 0
				while aPrice[nIndex] == aPrice[nIndex + 1] do
					nRepeat = nRepeat + 1
					remove(aPrice, nIndex + 1)
				end
				if nRepeat > 0 then
					aPrice[nIndex] = aPrice[nIndex] .. '.' .. nRepeat
				end
				nIndex = nIndex + 1
			end
			insert(aData, szKey .. '-' .. concat(aPrice, '-'))
		end
		local szData = concat(aData, ' ')
		local szURL = 'https://push.j3cx.com/api/item/price?'
			.. LIB.EncodePostData(LIB.UrlEncode(LIB.SignPostData({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				r = AnsiToUTF8(LIB.GetRealServer(1)), -- Region
				s = AnsiToUTF8(LIB.GetRealServer(2)), -- Server
				t = GetCurrentTime(), -- Time
				d = AnsiToUTF8(szData), -- Price data
			}, 'e87d2e0a-d3bd-4095-af48-e50dfe58f36b')))
		-- 延迟一帧 否则系统还没更新界面数据
		LIB.DelayCall(function()
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
			LIB.Ajax({ driver = 'auto', mode = 'auto', method = 'auto', url = szURL })
		end)
	end
end)
