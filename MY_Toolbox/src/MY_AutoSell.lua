--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Զ��۳���Ʒ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = false, -- ���̵���Զ��۳��ܿ���
	bSellGray = true, -- �Զ����ۻ�ɫ��Ʒ
	bSellWhiteBook = false, -- �Զ������Ѷ�����
	bSellGreenBook = false, -- �Զ������Ѷ�����
	bSellBlueBook = false, -- �Զ������Ѷ�����
	tSellItem = {
		[LIB.GetObjectName('ITEM_INFO', 5, 2863)] = true, -- ��Ҷ��
		[LIB.GetObjectName('ITEM_INFO', 5, 2864)] = true, -- ����Ҷ��
		[LIB.GetObjectName('ITEM_INFO', 5, 2865)] = true, -- ��Ƭ����Ҷ��
		[LIB.GetObjectName('ITEM_INFO', 5, 2866)] = true, -- ���ĩ
		[LIB.GetObjectName('ITEM_INFO', 5, 2867)] = true, -- ��Ҷ��
		[LIB.GetObjectName('ITEM_INFO', 5, 2868)] = true, -- ��Ƭ��Ҷ��
		[LIB.GetObjectName('ITEM_INFO', 5, 11682)] = true, -- ����
		[LIB.GetObjectName('ITEM_INFO', 5, 11683)] = true, -- ���
		[LIB.GetObjectName('ITEM_INFO', 5, 11640)] = true, -- ��ש
		[LIB.GetObjectName('ITEM_INFO', 5, 17130)] = true, -- ��Ҷ�ӡ�����֮��
		[LIB.GetObjectName('ITEM_INFO', 5, 22974)] = true, -- ����Ľ�����
	},
	tProtectItem = {
		[LIB.GetObjectName('ITEM_INFO', 5, 789)] = true, -- ��˿�Ƕ�
		[LIB.GetObjectName('ITEM_INFO', 5, 797)] = true, -- ����ͼ��
	},
}
RegisterCustomData('MY_AutoSell.bEnable', 2)
RegisterCustomData('MY_AutoSell.bSellGray')
RegisterCustomData('MY_AutoSell.bSellWhiteBook')
RegisterCustomData('MY_AutoSell.bSellGreenBook')
RegisterCustomData('MY_AutoSell.bSellBlueBook')
RegisterCustomData('MY_AutoSell.tSellItem')
RegisterCustomData('MY_AutoSell.tProtectItem')

-- �Զ��۳���Ʒ
function D.AutoSellItem(nNpcID, nShopID)
	local me = GetClientPlayer()
	for dwBox = 1, LIB.GetBagPackageCount() do
		local dwSize = me.GetBoxSize(dwBox) - 1
		for dwX = 0, dwSize do
			local item = me.GetItem(dwBox, dwX)
			if item and item.bCanTrade then
				local bSell, szReason = item.nQuality == 0, ''
				local szName = LIB.GetObjectName(item)
				if not O.tProtectItem[szName] then
					if not bSell and O.tSellItem[szName] then
						bSell = true
						szReason = _L['specified']
					end
					if not bSell and item.nGenre == ITEM_GENRE.BOOK and me.IsBookMemorized(GlobelRecipeID2BookID(item.nBookID)) then
						if O.bSellWhiteBook and item.nQuality == 1 then
							bSell = true
							szReason = _L['read white book']
						elseif O.bSellGreenBook and item.nQuality == 2 then
							bSell = true
							szReason = _L['read green book']
						elseif O.bSellBlueBook and item.nQuality == 3 then
							bSell = true
							szReason = _L['read blue book']
						end
					end
				end
				if bSell then
					local nCount = 1
					if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.ARROW then --Զ������
						nCount = item.nCurrentDurability
					elseif item.bCanStack then
						nCount = item.nStackNum
					end
					SellItem(nNpcID, nShopID, dwBox, dwX, nCount)
					LIB.Sysmsg(_L('Auto sell %s item: %s.', szReason, szName))
				end
			end
		end
	end
end

function D.CheckEnable()
	if O.bEnable then
		LIB.RegisterEvent('SHOP_OPENSHOP', function()
			D.AutoSellItem(arg4, arg0)
		end)
	else
		LIB.RegisterEvent('SHOP_OPENSHOP', false)
	end
end
LIB.RegisterInit('MY_AutoSell', D.CheckEnable)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndComboBox', {
		x = W - 150, y = 50, w = 130,
		text = _L['Auto sell items'],
		menu = function()
			local m0 = {
				{ szOption = _L['Auto sell when open shop'], bDisable = true },
				{
					szOption = _L['Enable'],
					bCheck = true, bChecked = MY_AutoSell.bEnable,
					fnAction = function(d, b) MY_AutoSell.bEnable = b end,
				},
				{
					szOption = _L['Sell grey items'],
					bCheck = true, bChecked = MY_AutoSell.bSellGray,
					fnAction = function(d, b) MY_AutoSell.bSellGray = b end,
					fnDisable = function() return not MY_AutoSell.bEnable end,
				},
				{
					szOption = _L['Sell read white books'],
					bCheck = true, bChecked = MY_AutoSell.bSellWhiteBook,
					fnAction = function(d, b) MY_AutoSell.bSellWhiteBook = b end,
					fnDisable = function() return not MY_AutoSell.bEnable end,
				},
				{
					szOption = _L['Sell read green books'], bCheck = true, bChecked = MY_AutoSell.bSellGreenBook,
					fnAction = function(d, b) MY_AutoSell.bSellGreenBook = b end,
					fnDisable = function() return not MY_AutoSell.bEnable end
				},
				{
					szOption = _L['Sell read blue books'], bCheck = true, bChecked = MY_AutoSell.bSellBlueBook,
					fnAction = function(d, b) MY_AutoSell.bSellBlueBook = b end,
					fnDisable = function() return not MY_AutoSell.bEnable end,
				},
				{ bDevide = true },
			}
			-- �Զ���������Ʒ
			local m1 = {
				szOption = _L['Sell specified items'],
				fnDisable = function() return not MY_AutoSell.bEnable end,
				{
					szOption = _L['* New *'],
					fnAction = function()
						GetUserInput(_L['Name of item'], function(szText)
							local szText = gsub(szText, '^%s*%[?(.-)%]?%s*$', '%1')
							if szText ~= '' then
								MY_AutoSell.tSellItem[szText] = true
							end
						end)
					end
				},
				{ bDevide = true },
			}
			for k, v in pairs(MY_AutoSell.tSellItem) do
				insert(m1, {
					szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) MY_AutoSell.tSellItem[k] = b end,
					{ szOption = _L['Remove'], fnAction = function() MY_AutoSell.tSellItem[k] = nil end }
				})
			end
			insert(m0, m1)
			-- �Զ��岻����Ʒ
			local m1 = {
				szOption = _L['Protect specified items'],
				fnDisable = function() return not MY_AutoSell.bEnable end,
				{
					szOption = _L['* New *'],
					fnAction = function()
						GetUserInput(_L['Name of item'], function(szText)
							local szText = gsub(szText, '^%s*%[?(.-)%]?%s*$', '%1')
							if szText ~= '' then
								MY_AutoSell.tProtectItem[szText] = true
							end
						end)
					end
				},
				{ bDevide = true },
			}
			for k, v in pairs(MY_AutoSell.tProtectItem) do
				insert(m1, {
					szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) MY_AutoSell.tProtectItem[k] = b end,
					{ szOption = _L['Remove'], fnAction = function() MY_AutoSell.tProtectItem[k] = nil end }
				})
			end
			insert(m0, m1)
			return m0
		end,
	})
	return x, y
end

-- Global exports
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
				bEnable = true,
				bSellGray = true,
				bSellWhiteBook = true,
				bSellGreenBook = true,
				bSellBlueBook = true,
				tSellItem = true,
				tProtectItem = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				bSellGray = true,
				bSellWhiteBook = true,
				bSellGreenBook = true,
				bSellBlueBook = true,
				tSellItem = true,
				tProtectItem = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_AutoSell = LIB.GeneGlobalNS(settings)
end