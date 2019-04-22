--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 仓库背包增强（搜索/对比）
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
--------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local MY, UI, DEBUG_LEVEL, PATH_TYPE = MY, MY.UI, MY.DEBUG_LEVEL, MY.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_BagEx/lang/')

MY_BagEx = {}
MY_BagEx.bEnable = true
RegisterCustomData('MY_BagEx.bEnable')

local l_tItemText = {}

local l_szBagFilter = ''

local l_szBankFilter = ''
local l_bCompareBank = false
local l_bBankTimeLtd = false

local l_szGuildBankFilter = ''
local l_bCompareGuild = false

local function GetItemText(item)
	if item then
		if GetItemTip then
			local szKey = item.dwTabType .. ',' .. item.dwIndex
			if not l_tItemText[szKey] then
				l_tItemText[szKey] = ''
				l_tItemText[szKey] = MY.Xml.GetPureText(GetItemTip(item))
			end
			return l_tItemText[szKey]
		else
			return item.szName
		end
	else
		return ''
	end
end

local SimpleMatch = MY.StringSimpleMatch
local function FilterBags(szTreePath, szFilter, bTimeLtd)
	if szFilter then
		szFilter = szFilter:gsub('[%[%]]', '')
		if szFilter == '' then
			szFilter = nil
		end
	end
	local me = GetClientPlayer()
	if not szFilter and not bTimeLtd then
		UI(szTreePath):find('.Box'):alpha(255)
	else
		UI(szTreePath):find('.Box'):each(function(ui)
			if this.bBag then
				return
			end
			local bMatch = true
			local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
			if szBoxType == UI_OBJECT_ITEM then
				local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
				if item then
					if bTimeLtd and item.GetLeftExistTime() == 0 then
						bMatch = false
					end
					if szFilter and not SimpleMatch(GetItemText(item), szFilter) then
						bMatch = false
					end
				end
			end
			if bMatch then
				this:SetAlpha(255)
			else
				this:SetAlpha(50)
			end
		end)
	end
end

local function DoFilterBag(bForce)
	if IsBagInSort and IsBagInSort() then
		return
	end
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szBagFilter or l_bBagTimeLtd then
		FilterBags('Normal/BigBagPanel', l_szBagFilter, l_bBagTimeLtd)
		if l_szBagFilter == '' then
			l_szBagFilter = nil
		end
	end
end

local function DoFilterBank(bForce)
	if IsBankInSort and IsBankInSort() then
		return
	end
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szBankFilter or l_bBankTimeLtd then
		FilterBags('Normal/BigBankPanel', l_szBankFilter, l_bBankTimeLtd)
		if l_szBankFilter == '' then
			l_szBankFilter = nil
		end
	end
end

local function DoFilterGuildBank(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szGuildBankFilter then
		FilterBags('Normal/GuildBankPanel', l_szGuildBankFilter)
		if l_szGuildBankFilter == '' then
			l_szGuildBankFilter = nil
		end
	end
end

local function DoCompare(ui1, ui2)
	local itemlist1 = {}
	local itemlist2 = {}

	ui1:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist1[dwTabType .. ',' .. dwIndex] = true
		end
	end)
	ui2:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist2[dwTabType .. ',' .. dwIndex] = true

			if itemlist1[dwTabType .. ',' .. dwIndex] then
				e:alpha(255)
			else
				e:alpha(50)
			end
		end
	end)
	ui1:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			if itemlist2[dwTabType .. ',' .. dwIndex] then
				e:alpha(255)
			else
				e:alpha(50)
			end
		end
	end)
end

local function DoCompareBank(bForce)
	if l_bCompareBank then
		local frmBag = Station.Lookup('Normal/BigBagPanel')
		local frmBank = Station.Lookup('Normal/BigBankPanel')

		if frmBag and frmBank and frmBank:IsVisible() then
			UI('Normal/BigBagPanel/CheckBox_Totle'):check(true):check(false)
			DoCompare(UI(frmBag), UI(frmBank))
		end
	else
		DoFilterBag(bForce)
		DoFilterBank(bForce)
	end
end

local function DoCompareGuildBank(bForce)
	if l_bCompareGuild then
		local frmBag = Station.Lookup('Normal/BigBagPanel')
		local frmGuildBank = Station.Lookup('Normal/GuildBankPanel')

		if frmBag and frmGuildBank and frmGuildBank:IsVisible() then
			UI('Normal/BigBagPanel/CheckBox_Totle'):check(true):check(false)
			DoCompare(UI(frmBag), UI(frmGuildBank))
		end
	else
		DoFilterBag(bForce)
		DoFilterGuildBank(bForce)
	end
end

local function OnFrameKeyDown()
	local szKey = GetKeyName(Station.GetMessageKey())
	if IsCtrlKeyDown() and szKey == 'F' then
		Station.SetFocusWindow('Normal/BigBagPanel/WndEditBox_KeyWord/WndEdit_Default')
		return 1
	end
	return 0
end

local function Hook()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		UI(frame):append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 100, h = 21, x = 60, y = 30,
			text = l_szBagFilter,
			placeholder = _L['Search'],
			onchange = function(txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 20)
				UI(this):width(nLen * 10)
				l_szBagFilter = txt
				DoFilterBag()
			end,
		})

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	local frame = Station.Lookup('Normal/BigBankPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		UI(frame):append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 150, h = 21, x = 280, y = 80,
			text = l_szBankFilter,
			placeholder = _L['Search'],
			onchange = function(txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 15)
				nLen = math.min(nLen, 25)
				UI(this):width(nLen * 10)
				l_szBankFilter = txt
				DoFilterBank(true)
			end,
		})

		UI(frame):append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 340, y = 56,
			text = _L['compare with bag'],
			checked = l_bCompareBank,
			oncheck = function(bChecked)
				if bChecked then
					UI('Normal/BigBankPanel/CheckBox_TimeLtd'):check(false)
				end
				l_bCompareBank = bChecked
				DoCompareBank(true)
			end
		})

		UI(frame):append('WndCheckBox', {
			name = 'CheckBox_TimeLtd',
			w = 60, x = 277, y = 56, alpha = 200,
			text = _L['Time Limited'],
			checked = l_bBankTimeLtd,
			oncheck = function(bChecked)
				if bChecked then
					UI('Normal/BigBankPanel/WndCheckBox_Compare'):check(false)
				end
				l_bBankTimeLtd = bChecked
				DoFilterBank(true)
			end
		})

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	local frame = Station.Lookup('Normal/GuildBankPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		UI('Normal/GuildBankPanel'):append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 100, h = 21, x = 60, y = 25,
			text = l_szGuildBankFilter,
			placeholder = _L['Search'],
			onchange = function(txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 25)
				UI(this):width(nLen * 10)
				l_szGuildBankFilter = txt
				DoFilterGuildBank(true)
			end,
		})

		UI('Normal/GuildBankPanel'):append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 20, y = 475,
			text = _L['compare with bag'],
			checked = l_bCompareGuild,
			oncheck = function(bChecked)
				l_bCompareGuild = bChecked
				DoCompareGuildBank(true)
			end
		})

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	MY.RegisterEvent('EXECUTE_BINDING.MY_BAGEX', function(e)
		local szName, bDown = arg0, arg1
		if Cursor.IsVisible()
		and szName == 'OPENORCLOSEALLBAGS' and not bDown then
			local hFrame = Station.Lookup('Normal/BigBagPanel')
			if hFrame and hFrame:IsVisible() then
				Station.SetFocusWindow(hFrame)
			end
		end
	end)

	DoFilterBank()
	DoCompareBank()
	DoFilterGuildBank()
	DoCompareGuildBank()
end

local function Unhook()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		frame:Lookup('WndEditBox_KeyWord'):Destroy()
		UnhookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown)
	end

	local frame = Station.Lookup('Normal/BigBankPanel')
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		frame:Lookup('CheckBox_TimeLtd'):Destroy()
		frame:Lookup('WndEditBox_KeyWord'):Destroy()
		frame:Lookup('WndCheckBox_Compare'):Destroy()
		UnhookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown)
	end

	local frame = Station.Lookup('Normal/GuildBankPanel')
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		frame:Lookup('WndEditBox_KeyWord'):Destroy()
		frame:Lookup('WndCheckBox_Compare'):Destroy()
		UnhookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown)
	end

	MY.RegisterEvent('EXECUTE_BINDING.MY_BAGEX')
end

local function Apply(bEnable)
	if bEnable == nil then
		bEnable = MY_BagEx.bEnable
	end
	if bEnable then
		Hook()
		MY.RegisterEvent('ON_FRAME_CREATE.MY_BAGEX', Hook)
	else
		Unhook()
		MY.RegisterEvent('ON_FRAME_CREATE.MY_BAGEX')
	end
end

function MY_BagEx.Enable(bEnable)
	MY_BagEx.bEnable = bEnable
	Apply()
end

do
local function OnBagItemUpdate()
	if l_bCompareBank then
		DoCompareBank()
	elseif l_bCompareGuild then
		DoCompareGuildBank()
	else
		DoFilterBag()
		DoFilterBank()
		DoFilterGuildBank()
	end
end
MY.RegisterEvent({'BAG_ITEM_UPDATE', 'GUILD_BANK_PANEL_UPDATE'}, function()
	if not MY_BagEx.bEnable then
		return
	end
	MY.DelayCall('MY_BagEx', 100, OnBagItemUpdate)
end)
end

MY.RegisterInit('MY_BAGEX', function() Apply() end)
MY.RegisterReload('MY_BAGEX', function() Apply(false) end)
