--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录记账页面
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
	GetMoneyCol = MY_GKP.GetMoneyCol,
	GetMoneyTipText = MY_GKP.GetMoneyTipText,
	GetFormatLink = MY_GKP.GetFormatLink,
}

function D.Open(ds, tab, szMode)
	-- CreateFrame
	local szKey = IsTable(tab) and tab.key or LIB.GetUUID()
	local ui = UI.CreateFrame('MY_GKP_Record#' .. GetStringCRC(szKey), { h = 380, w = 400, text = _L['GKP Golden Team Record'], close = true, focus = true })
	local x, y = 10, 55
	local nAuto = 0
	local dwForceID, item
	local bProcessed = false -- 是否已处理 没处理自动设为0价发布

	if IsTable(tab) then
		if not IsEmpty(tab.dwID) then
			item = GetItem(tab.dwID)
		end
		if not item and tab.dwTabType and tab.dwIndex then
			item = GetItemInfo(tab.dwTabType, tab.dwIndex)
		end
	end

	local hBox = ui:Append('Box', { name = 'Box', x = x + 175, y = y + 40, h = 48, w = 48 })
	local hCheckBox = ui:Append('WndCheckBox', { name = 'WndCheckBox', x = x + 50, y = y + 260, font = 65, text = _L['Equiptment Boss'] })
	local hButton = ui:Append('WndButton', { name = 'Success', x = x + 175, y = y + 260, text = g_tStrings.STR_HOTKEY_SURE, buttonstyle = 'FLAT_LACE_BORDER' })
	ui:Remove(function()
		if bProcessed then
			return
		end
		if ui[1].userdata then
			ui:Children('#Money'):Text(0)
			hButton:Click()
		end
	end)

	ui:Append('Text', { x = x + 65, y = y + 10, font = 65, text = _L['Keep Account to:'] })
	ui:Append('Text', { x = x + 65, y = y + 90, font = 65, text = _L['Name of the Item:'] })
	ui:Append('Text', { x = x + 65, y = y + 120, font = 65, text = _L['Route of Acquiring:'] })
	ui:Append('Text', { x = x + 65, y = y + 150, font = 65, text = _L['Auction Price:'] })

	local hPlayer = ui:Append('WndComboBox', {
		name = 'PlayerList',
		x = x + 140, y = y + 13, text = g_tStrings.PLAYER_NOT_EMPTY,
		menu = function()
			return MY_GKP.GetTeamMemberMenu(function(v)
				local hTeamList = ui:Children('#PlayerList')
				hTeamList:Text(v.szName):Color(LIB.GetForceColor(v.dwForce))
				dwForceID = v.dwForce
			end, false, true)
		end,
	})
	local hSource = ui:Append('WndEditBox', { name = 'Source', x = x + 140, y = y + 121, w = 185, h = 25 })
    local hName = ui:Append('WndAutocomplete', {
		name = 'Name', x = x + 140, y = y + 91, w = 185, h = 25,
		autocomplete = {
			{
				'option', 'beforeSearch', function(text)
					local source = {}
					for k, v in ipairs(MY_GKP.aSubsidies) do
						if v[3] then
							insert(source, v[1])
						end
					end
					UI(this):Autocomplete('option', 'source', source)
				end,
			},
			{
				'option', 'afterComplete', function(raw, option, search, text)
					if text then
						for k, v in ipairs(MY_GKP.aSubsidies) do
							if v[1] == text then
								ui:Children('#Money'):Text(v[2])
							end
						end
						ui:Children('#Money'):Focus()
					end
				end,
			},
		},
		onclick = function()
			if IsPopupMenuOpened() then
				UI(this):Autocomplete('close')
			else
				UI(this):Autocomplete('search', '')
			end
		end,
	})
	local hMoney = ui:Append('WndAutocomplete', {
		name = 'Money', x = x + 140, y = y + 151, w = 185, h = 25, limit = 8, edittype = UI.EDIT_TYPE.ASCII,
		autocomplete = {
			{
				'option', 'beforeSearch', function(text)
					local source = {}
					if tonumber(text) then
						if tonumber(text) < 100 and tonumber(text) > -100 and tonumber(text) ~= 0 then
							for k, v in ipairs({2, 3, 4}) do
								local szMoney = format('%0.'.. v ..'f', text):gsub('%.', '')
								insert(source, {
									text     = szMoney,
									keyword  = text,
									display  = D.GetMoneyTipText(tonumber(szMoney)),
									richtext = true,
								})
							end
							insert(source, { divide = true, keyword = text })
						end
						insert(source, {
							text     = text,
							keyword  = text,
							display  = D.GetMoneyTipText(tonumber(text)),
							richtext = true,
						})
					end
					UI(this):Autocomplete('option', 'source', source)
				end,
			},
		},
		onchange = function(szText)
			local ui = UI(this)
			if tonumber(szText) or szText == '' or szText == '-' then
				this.szText = szText
				ui:Color(D.GetMoneyCol(szText))
			else
				LIB.Sysmsg(_L['Please enter numbers'])
				ui:Text(this.szText or '')
			end
		end,
	})
	-- set frame
	if tab and type(item) == 'userdata' then
		hPlayer:Text(tab.szPlayer):Color(LIB.GetForceColor(tab.dwForceID))
		hName:Text(tab.szName):Enable(false)
		hSource:Text(tab.szNpcName):Enable(false)
		ui[1].userdata = true
	else
		hPlayer:Text(g_tStrings.PLAYER_NOT_EMPTY):Color(255, 255, 255)
		hSource:Text(_L['Add Manually']):Enable(false)
	end
	if tab and tab.key then -- 编辑
		hPlayer:Text(tab.szPlayer):Color(LIB.GetForceColor(tab.dwForceID))
		dwForceID = tab.dwForceID
		hName:Text(tab.szName or LIB.GetItemNameByUIID(tab.nUiId))
		hMoney:Text(tab.nMoney)
		hSource:Text(tab.szNpcName)
	end

	if tab and tab.nVersion and tab.nUiId and tab.dwTabType and tab.dwIndex and tab.nUiId ~= 0 then
		hBox:ItemInfo(tab.nVersion, tab.dwTabType, tab.dwIndex, tab.nBookID or tab.nStackNum)
	else
		hBox:ItemInfo()
		hBox:Icon(582)
	end
	if nAuto == 0 and tab and not tab.key then -- edit/add killfocus
		hMoney:Focus()
	elseif nAuto > 0 and tab then
		hMoney:Text(nAuto) -- OnEditChanged kill
		ui:Focus()
	elseif not tab then
		hName:Focus()
	end
	hButton:Click(function()
		bProcessed = true
		if IsCtrlKeyDown() and IsShiftKeyDown() and IsAltKeyDown() then
			return ui:Remove()
		end
		local tab = tab or {
			nUiId      = 0,
			dwTabType  = 0,
			dwDoodadID = 0,
			nQuality   = 1,
			nVersion   = 0,
			dwIndex    = 0,
			nTime      = GetCurrentTime(),
			dwForceID  = dwForceID,
			szName     = hName:Text(),
		}
		local nMoney = tonumber(hMoney:Text()) or 0
		local szPlayer = hPlayer:Text()
		if hName:Text() == '' then
			return LIB.Alert(_L['Please entry the name of the item'])
		end
		if szPlayer == g_tStrings.PLAYER_NOT_EMPTY then
			return LIB.Alert(_L['Select a member who is in charge of account and put money in his account.'])
		end
		tab.key       = szKey
		tab.szNpcName = hSource:Text()
		tab.nMoney    = nMoney
		tab.szPlayer  = szPlayer
		tab.dwForceID = dwForceID or tab.dwForceID or 0
		if tab and type(item) == 'userdata' and szMode ~= 'EDIT' then
			if LIB.IsDistributer() then
				if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
					LIB.Systopmsg(_L['Please unlock talk lock, otherwise gkp will not able to sync to teammate.'])
				else
					LIB.SendChat(PLAYER_TALK_CHANNEL.RAID, {
						D.GetFormatLink(tab),
						D.GetFormatLink(' '.. nMoney .. g_tStrings.STR_GOLD),
						D.GetFormatLink(_L[' Distribute to ']),
						D.GetFormatLink(tab.szPlayer, true)
					})
				end
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {'add', tab}, true)
			end
		elseif tab and szMode == 'EDIT' then
			tab.szName = hName:Text()
			tab.dwForceID = dwForceID or tab.dwForceID or 0
			tab.bEdit = true
			if LIB.IsDistributer() then
				if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
					LIB.Systopmsg(_L['Please unlock talk lock, otherwise gkp will not able to sync to teammate.'])
				else
					LIB.SendChat(PLAYER_TALK_CHANNEL.RAID, {
						D.GetFormatLink(tab.szPlayer, true),
						D.GetFormatLink(' '.. tab.szName),
						D.GetFormatLink(' '.. nMoney ..g_tStrings.STR_GOLD),
						D.GetFormatLink(_L['Make changes to the record.']),
					})
				end
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {'edit', tab}, true)
			end
		else
			if LIB.IsDistributer() then
				if LIB.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
					LIB.Systopmsg(_L['Please unlock talk lock, otherwise gkp will not able to sync to teammate.'])
				else
					LIB.SendChat(PLAYER_TALK_CHANNEL.RAID, {
						D.GetFormatLink(tab.szName),
						D.GetFormatLink(' '.. nMoney ..g_tStrings.STR_GOLD),
						D.GetFormatLink(_L['Manually make record to']),
						D.GetFormatLink(tab.szPlayer, true)
					})
				end
				LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GKP', {'add', tab}, true)
			end
		end
		if ui:Children('#WndCheckBox'):Check() then
			FireUIEvent('MY_GKP_LOOT_BOSS', tab.szPlayer)
		end
		ds:SetAuctionRec(tab)
		ui:Remove()
	end)
	if szMode == 'SKIP' then
		hButton:Click()
	end
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Open = D.Open,
			},
		},
	},
}
MY_GKP_AuctionUI = LIB.GeneGlobalNS(settings)
end
