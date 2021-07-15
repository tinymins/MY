--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动售出物品
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
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^7.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_AutoSell', _L['General'], {
	bEnable = { -- 打开商店后自动售出总开关,
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bSellGray = { -- 自动出售灰色物品,
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bSellWhiteBook = { -- 自动出售已读白书,
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bSellGreenBook = { -- 自动出售已读绿书,
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bSellBlueBook = { -- 自动出售已读蓝书,
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tSellItem = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Map(Schema.String, Schema.Boolean),
		xDefaultValue = {
			[LIB.GetObjectName('ITEM_INFO', 5, 2863)] = true, -- 银叶子
			[LIB.GetObjectName('ITEM_INFO', 5, 2864)] = true, -- 真银叶子
			[LIB.GetObjectName('ITEM_INFO', 5, 2865)] = true, -- 大片真银叶子
			[LIB.GetObjectName('ITEM_INFO', 5, 2866)] = true, -- 金粉末
			[LIB.GetObjectName('ITEM_INFO', 5, 2867)] = true, -- 金叶子
			[LIB.GetObjectName('ITEM_INFO', 5, 2868)] = true, -- 大片金叶子
			[LIB.GetObjectName('ITEM_INFO', 5, 11682)] = true, -- 金条
			[LIB.GetObjectName('ITEM_INFO', 5, 11683)] = true, -- 金块
			[LIB.GetObjectName('ITEM_INFO', 5, 11640)] = true, -- 金砖
			[LIB.GetObjectName('ITEM_INFO', 5, 17130)] = true, -- 银叶子·试炼之地
			[LIB.GetObjectName('ITEM_INFO', 5, 22974)] = true, -- 破碎的金玄玉
		},
	},
	tProtectItem = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Map(Schema.String, Schema.Boolean),
		xDefaultValue = {
			[LIB.GetObjectName('ITEM_INFO', 5, 789)] = true, -- 真丝肚兜
			[LIB.GetObjectName('ITEM_INFO', 5, 797)] = true, -- 春宫图册
		},
	},
})
local D = {}

RegisterCustomData('MY_AutoSell.tSellItem')
RegisterCustomData('MY_AutoSell.tProtectItem')

function D.SellItem(nNpcID, nShopID, dwBox, dwX, nCount, szReason, szName, nUiId)
	local me = GetClientPlayer()
	local item = me.GetItem(dwBox, dwX)
	if not item or item.nUiId ~= nUiId then
		return
	end
	SellItem(nNpcID, nShopID, dwBox, dwX, nCount)
	LIB.Sysmsg(_L('Auto sell %s item: %s.', szReason, szName))
end

-- 自动售出物品
function D.AutoSellItem(nNpcID, nShopID, bIgnoreGray)
	if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
		return
	end
	local me = GetClientPlayer()
	local nIndex = LIB.GetBagPackageIndex()
	local aSell = {}
	for dwBox = nIndex, nIndex + LIB.GetBagPackageCount() do
		local dwSize = me.GetBoxSize(dwBox) - 1
		for dwX = 0, dwSize do
			local item = me.GetItem(dwBox, dwX)
			if item and item.bCanTrade then
				local bSell, szReason = false, ''
				local szName = LIB.GetObjectName(item)
				if not O.tProtectItem[szName] then
					if item.nQuality == 0 and O.bSellGray and not bIgnoreGray then
						bSell = true
						szReason = _L['Gray item']
					end
					if not bSell and O.tSellItem[szName] then
						bSell = true
						szReason = _L['Specified']
					end
					if not bSell and item.nGenre == ITEM_GENRE.BOOK and me.IsBookMemorized(GlobelRecipeID2BookID(item.nBookID)) then
						if O.bSellWhiteBook and item.nQuality == 1 then
							bSell = true
							szReason = _L['Read white book']
						elseif O.bSellGreenBook and item.nQuality == 2 then
							bSell = true
							szReason = _L['Read green book']
						elseif O.bSellBlueBook and item.nQuality == 3 then
							bSell = true
							szReason = _L['Read blue book']
						end
					end
				end
				if bSell then
					local nCount = 1
					if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.ARROW then --远程武器
						nCount = item.nCurrentDurability
					elseif item.bCanStack then
						nCount = item.nStackNum
					end
					local r, g, b = GetItemFontColorByQuality(item.nQuality)
					local sell = {
						nNpcID = nNpcID, nShopID = nShopID, dwBox = dwBox, dwX = dwX, nCount = nCount,
						szReason = szReason, szName = szName, nUiId = item.nUiId, r = r, g = g, b = b,
					}
					insert(aSell, sell)
				end
			end
		end
	end
	sort(aSell, function(a, b)
		if a.szReason == b.szReason then
			return a.nUiId > b.nUiId
		end
		return a.szReason > b.szReason
	end)
	if #aSell > 0 then
		local aXML, szReason = {}
		insert(aXML, GetFormatText(_L['Confirm auto sell?']))
		insert(aXML, CONSTANT.XML_LINE_BREAKER)
		for _, v in ipairs(aSell) do
			if v.szReason ~= szReason then
				insert(aXML, CONSTANT.XML_LINE_BREAKER)
				insert(aXML, GetFormatText(v.szReason .. g_tStrings.STR_CHINESE_MAOHAO))
				szReason = v.szReason
			end
			insert(aXML, CONSTANT.XML_LINE_BREAKER)
			insert(aXML, GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE .. '['.. v.szName ..']', 166, v.r, v.g, v.b))
			insert(aXML, GetFormatText(' x' .. v.nCount))
		end
		insert(aXML, CONSTANT.XML_LINE_BREAKER)
		insert(aXML, CONSTANT.XML_LINE_BREAKER)
		insert(aXML, GetFormatText(_L['Some items may not be able to buy back once you sell it, and there is also a limit number rule by official, change auto sell rules in plugin if you want.']))
		local nW, nH = Station.GetClientSize()
		local tMsg = {
			x = nW / 2, y = nH / 3,
			szName = 'MY_AutoSell__Confirm',
			szMessage = concat(aXML),
			bRichText = true,
			szAlignment = 'CENTER',
			{
				szOption = g_tStrings.STR_HOTKEY_SURE,
				fnAction = function()
					for _, v in ipairs(aSell) do
						D.SellItem(v.nNpcID, v.nShopID, v.dwBox, v.dwX, v.nCount, v.szReason, v.szName, v.nUiId)
					end
				end,
			}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
		}
		MessageBox(tMsg)
	end
end

function D.CheckEnable()
	if O.bEnable then
		LIB.RegisterEvent('SHOP_OPENSHOP', 'MY_AutoSell', function()
			local chk = Station.Lookup('Normal/ShopPanel/CheckBox_AutoSell')
			local bIgnoreGray = chk and chk:IsCheckBoxChecked() or false
			D.AutoSellItem(arg4, arg0, bIgnoreGray)
		end)
	else
		LIB.RegisterEvent('SHOP_OPENSHOP', 'MY_AutoSell', false)
	end
end
LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_AutoSell', function()
	for _, k in ipairs({'tSellItem', 'tProtectItem'}) do
		if D[k] then
			SafeCall(Set, O, k, D[k])
			D[k] = nil
		end
	end
	D.CheckEnable()
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndComboBox', {
		x = W - 140, y = 65, w = 130,
		text = _L['Auto sell items'],
		menu = function()
			local m0 = {
				{ szOption = _L['Auto sell when open shop'], bDisable = true },
				{
					szOption = _L['Enable'],
					bCheck = true, bChecked = O.bEnable,
					fnAction = function(d, b)
						O.bEnable = b
						D.CheckEnable()
					end,
				},
				{
					szOption = _L['Sell grey items'],
					bCheck = true, bChecked = O.bSellGray,
					fnAction = function(d, b) O.bSellGray = b end,
					fnDisable = function() return not O.bEnable end,
				},
				{
					szOption = _L['Sell read white books'],
					bCheck = true, bChecked = O.bSellWhiteBook,
					fnAction = function(d, b) O.bSellWhiteBook = b end,
					fnDisable = function() return not O.bEnable end,
				},
				{
					szOption = _L['Sell read green books'], bCheck = true, bChecked = O.bSellGreenBook,
					fnAction = function(d, b) O.bSellGreenBook = b end,
					fnDisable = function() return not O.bEnable end
				},
				{
					szOption = _L['Sell read blue books'], bCheck = true, bChecked = O.bSellBlueBook,
					fnAction = function(d, b) O.bSellBlueBook = b end,
					fnDisable = function() return not O.bEnable end,
				},
				{ bDevide = true },
			}
			-- 自定义售卖物品
			local m1 = {
				szOption = _L['Sell specified items'],
				fnDisable = function() return not O.bEnable end,
				{
					szOption = _L['* New *'],
					fnAction = function()
						GetUserInput(_L['Name of item'], function(szText)
							local szText = gsub(szText, '^%s*%[?(.-)%]?%s*$', '%1')
							if szText ~= '' then
								O.tSellItem[szText] = true
								O.tSellItem = O.tSellItem
							end
						end)
					end
				},
				{ bDevide = true },
			}
			local m2 = { bInline = true, nMaxHeight = 550 }
			for k, v in pairs(O.tSellItem) do
				insert(m2, {
					szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) O.tSellItem[k] = b end,
					{
						szOption = _L['Remove'],
						fnAction = function()
							O.tSellItem[k] = nil
							O.tSellItem = O.tSellItem
							for i, v in ipairs(m2) do
								if v.szOption == k then
									remove(m2, i)
									break
								end
							end
							return 0
						end,
					},
				})
			end
			insert(m1, m2)
			insert(m0, m1)
			-- 自定义不卖物品
			local m1 = {
				szOption = _L['Protect specified items'],
				fnDisable = function() return not O.bEnable end,
				{
					szOption = _L['* New *'],
					fnAction = function()
						GetUserInput(_L['Name of item'], function(szText)
							local szText = gsub(szText, '^%s*%[?(.-)%]?%s*$', '%1')
							if szText ~= '' then
								O.tProtectItem[szText] = true
								O.tProtectItem = O.tProtectItem
							end
						end)
					end
				},
				{ bDevide = true },
			}
			local m2 = { bInline = true, nMaxHeight = 550 }
			for k, v in pairs(O.tProtectItem) do
				insert(m2, {
					szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) O.tProtectItem[k] = b end,
					{
						szOption = _L['Remove'],
						fnAction = function()
							O.tProtectItem[k] = nil
							O.tProtectItem = O.tProtectItem
							for i, v in ipairs(m2) do
								if v.szOption == k then
									remove(m2, i)
									break
								end
							end
							return 0
						end,
					},
				})
			end
			insert(m1, m2)
			insert(m0, m1)
			return m0
		end,
	})
	return x, y
end

-- Global exports
do
local settings = {
	name = 'MY_AutoSell',
	exports = {
		{
			fields = {
				'tSellItem',
				'tProtectItem',
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'tSellItem',
				'tProtectItem',
			},
			root = D,
		},
	},
}
MY_AutoSell = LIB.CreateModule(settings)
end
