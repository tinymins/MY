--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 仓库背包增强（搜索/对比）
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
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild = LIB.GetTraceback, LIB.RandomChild
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

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
				l_tItemText[szKey] = LIB.Xml.GetPureText(GetItemTip(item))
			end
			return l_tItemText[szKey]
		else
			return item.szName
		end
	else
		return ''
	end
end

local SimpleMatch = LIB.StringSimpleMatch
local function FilterBags(szTreePath, szFilter, bTimeLtd)
	if szFilter then
		szFilter = szFilter:gsub('[%[%]]', '')
		if szFilter == '' then
			szFilter = nil
		end
	end
	local me = GetClientPlayer()
	if not szFilter and not bTimeLtd then
		UI(szTreePath):Find('.Box'):Alpha(255)
	else
		UI(szTreePath):Find('.Box'):Each(function(ui)
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
	if bForce or l_szBagFilter then
		FilterBags('Normal/BigBagPanel', l_szBagFilter)
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

	ui1:Find('.Box'):Each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist1[dwTabType .. ',' .. dwIndex] = true
		end
	end)
	ui2:Find('.Box'):Each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist2[dwTabType .. ',' .. dwIndex] = true

			if itemlist1[dwTabType .. ',' .. dwIndex] then
				e:Alpha(255)
			else
				e:Alpha(50)
			end
		end
	end)
	ui1:Find('.Box'):Each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			if itemlist2[dwTabType .. ',' .. dwIndex] then
				e:Alpha(255)
			else
				e:Alpha(50)
			end
		end
	end)
end

local function DoCompareBank(bForce)
	if l_bCompareBank then
		local frmBag = Station.Lookup('Normal/BigBagPanel')
		local frmBank = Station.Lookup('Normal/BigBankPanel')

		if frmBag and frmBank and frmBank:IsVisible() then
			UI('Normal/BigBagPanel/CheckBox_Totle'):Check(true):Check(false)
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
			UI('Normal/BigBagPanel/CheckBox_Totle'):Check(true):Check(false)
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
		UI(frame):Append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 100, h = 21, x = 60, y = 30,
			text = l_szBagFilter,
			placeholder = _L['Search'],
			onchange = function(txt)
				local nLen = txt:len()
				nLen = max(nLen, 10)
				nLen = min(nLen, 20)
				UI(this):Width(nLen * 10)
				l_szBagFilter = txt
				DoFilterBag()
			end,
		})

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	local frame = Station.Lookup('Normal/BigBankPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		UI(frame):Append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 150, h = 21, x = 280, y = 80,
			text = l_szBankFilter,
			placeholder = _L['Search'],
			onchange = function(txt)
				local nLen = txt:len()
				nLen = max(nLen, 15)
				nLen = min(nLen, 25)
				UI(this):Width(nLen * 10)
				l_szBankFilter = txt
				DoFilterBank(true)
			end,
		})

		UI(frame):Append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 340, y = 56,
			text = _L['Compare with bag'],
			checked = l_bCompareBank,
			oncheck = function(bChecked)
				if bChecked then
					UI('Normal/BigBankPanel/CheckBox_TimeLtd'):Check(false)
				end
				l_bCompareBank = bChecked
				DoCompareBank(true)
			end
		})

		UI(frame):Append('WndCheckBox', {
			name = 'CheckBox_TimeLtd',
			w = 60, x = 277, y = 56, alpha = 200,
			text = _L['Time Limited'],
			checked = l_bBankTimeLtd,
			oncheck = function(bChecked)
				if bChecked then
					UI('Normal/BigBankPanel/WndCheckBox_Compare'):Check(false)
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
		UI('Normal/GuildBankPanel'):Append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 100, h = 21, x = 60, y = 25,
			text = l_szGuildBankFilter,
			placeholder = _L['Search'],
			onchange = function(txt)
				local nLen = txt:len()
				nLen = max(nLen, 10)
				nLen = min(nLen, 25)
				UI(this):Width(nLen * 10)
				l_szGuildBankFilter = txt
				DoFilterGuildBank(true)
			end,
		})

		UI('Normal/GuildBankPanel'):Append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 20, y = 475,
			text = _L['Compare with bag'],
			checked = l_bCompareGuild,
			oncheck = function(bChecked)
				l_bCompareGuild = bChecked
				DoCompareGuildBank(true)
			end
		})

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	LIB.RegisterEvent('EXECUTE_BINDING.MY_BAGEX', function(e)
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

	LIB.RegisterEvent('EXECUTE_BINDING.MY_BAGEX')
end

local function Apply(bEnable)
	if bEnable == nil then
		bEnable = MY_BagEx.bEnable
	end
	if bEnable then
		Hook()
		LIB.RegisterFrameCreate('BigBagPanel.MY_BAGEX', Hook)
		LIB.RegisterFrameCreate('BigBankPanel.MY_BAGEX', Hook)
		LIB.RegisterFrameCreate('GuildBankPanel.MY_BAGEX', Hook)
	else
		Unhook()
		LIB.RegisterFrameCreate('BigBagPanel.MY_BAGEX', false)
		LIB.RegisterFrameCreate('BigBankPanel.MY_BAGEX', false)
		LIB.RegisterFrameCreate('GuildBankPanel.MY_BAGEX', false)
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
LIB.RegisterEvent({'BAG_ITEM_UPDATE', 'GUILD_BANK_PANEL_UPDATE', 'LOADING_END'}, function()
	if not MY_BagEx.bEnable then
		return
	end
	LIB.DelayCall('MY_BagEx', 100, OnBagItemUpdate)
end)
end

LIB.RegisterInit('MY_BAGEX', function() Apply() end)
LIB.RegisterReload('MY_BAGEX', function() Apply(false) end)

function MY_BagEx.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Package searcher'],
		checked = MY_BagEx.bEnable,
		oncheck = function(bChecked)
			MY_BagEx.Enable(bChecked)
		end,
	}):AutoWidth():Width() + 5
	-- y = y + 25
	return x, y
end
