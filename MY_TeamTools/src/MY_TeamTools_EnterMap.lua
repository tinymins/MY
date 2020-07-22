--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具 - 过图记录
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
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_EnterMap'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local D = {}
local SZ_INI = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_EnterMap.ini'

local PLAYER_ID  = 0
local ENTER_MAP_LOG = {}
local INFO_CACHE = {}
local RT_SELECT_MAP

function D.ClearEnterMapLog()
	ENTER_MAP_LOG = {}
	INFO_CACHE = {}
	FireUIEvent('MY_TEAMTOOLS_ENTERMAP')
end

LIB.RegisterEvent('LOADING_END', function()
	PLAYER_ID = UI_GetClientPlayerID()
end)

LIB.RegisterBgMsg('MY_ENTER_MAP', function(_, aData, nChannel, dwTalkerID, szTalkerName, bSelf)
	local dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime, nCopyIndex = aData[1], aData[2], aData[3], aData[4], aData[5], aData[6]
	local key = dwTalkerID == PLAYER_ID
		and 'self'
		or dwTalkerID
	if not INFO_CACHE[dwTalkerID] then
		if key == 'self' then
			local me = GetClientPlayer()
			INFO_CACHE[dwTalkerID] = {
				szName = me.szName,
				dwForceID = me.dwForceID,
				dwMountKungfuID = UI_GetPlayerMountKungfuID(),
			}
		else
			local team = GetClientTeam()
			local info = team.GetMemberInfo(dwTalkerID)
			if info then
				INFO_CACHE[dwTalkerID] = {
					szName = info.szName,
					dwForceID = info.dwForceID,
					dwMountKungfuID = info.dwMountKungfuID,
				}
			end
		end
	end
	if not dwTime then
		dwTime = GetCurrentTime()
	end
	if not dwSwitchTime then
		dwSwitchTime = dwTime
	end
	if not nCopyIndex then
		nCopyIndex = 0
	end
	for i, v in ipairs_r(ENTER_MAP_LOG) do -- 删除重复发送的过图
		if v.dwID == key and v.dwMapID == dwMapID and v.dwSubID == dwSubID and v.dwTime == dwTime then
			remove(ENTER_MAP_LOG, i)
		end
	end
	insert(ENTER_MAP_LOG, {
		dwID = key,
		szName = szTalkerName,
		dwMapID = dwMapID,
		dwSubID = dwSubID,
		aMapCopy = aMapCopy,
		dwTime = dwTime,
		dwSwitchTime = dwSwitchTime,
		nCopyIndex = nCopyIndex,
	})
	FireUIEvent('MY_TEAMTOOLS_ENTERMAP', key)
end)

-- 重伤记录
function D.UpdatePage(page)
	local hDeathList = page:Lookup('Wnd_EnterMap/Scroll_Player_List', '')
	local aList, tList = {}, {}
	for _, v in ipairs(ENTER_MAP_LOG) do
		if tList[v.dwMapID] then
			tList[v.dwMapID].nCount = tList[v.dwMapID].nCount + 1
		else
			insert(aList, {
				dwMapID = v.dwMapID,
				nCount = 1,
			})
			tList[v.dwMapID] = aList[#aList]
		end
	end
	sort(aList, function(a, b) return a.nCount > b.nCount end)
	hDeathList:Clear()
	for _, v in ipairs(aList) do
		local map = LIB.GetMapInfo(v.dwMapID)
		if map then
			local h = hDeathList:AppendItemFromData(page.hEnterMap, 'Handle_EnterMap')
			h.dwID = v.dwMapID
			h:Lookup('Text_DeathName'):SetText(map.szName)
			h:Lookup('Text_DeathCount'):SetText(v.nCount)
			h:Lookup('Image_Select'):SetVisible(v.dwMapID == RT_SELECT_MAP)
		end
	end
	hDeathList:FormatAllItemPos()
	D.UpdateList(page, RT_SELECT_MAP)
end

function D.OnAppendEdit()
	local handle = this:GetParent()
	local edit = LIB.GetChatInput()
	edit:ClearText()
	for i = this:GetIndex(), handle:GetItemCount() do
		local h = handle:Lookup(i)
		local szText = h:GetText()
		if szText == '\n' then
			break
		end
		if h:GetName() == 'namelink' then
			edit:InsertObj(szText, { type = 'name', text = szText, name = sub(szText, 2, -2) })
		else
			edit:InsertObj(szText, { type = 'text', text = szText })
		end
	end
	Station.SetFocusWindow(edit)
end

function D.UpdateList(page, dwMapID)
	local hDeathMsg = page:Lookup('Wnd_EnterMap/Scroll_Death_Info', '')
	local me = GetClientPlayer()
	local team = GetClientTeam()
	local aRec = {}
	local aEnterMapLog = Clone(ENTER_MAP_LOG)
	for _, v in ipairs(aEnterMapLog) do
		if not dwMapID or v.dwMapID == dwMapID then
			if v.dwID == 'self' then
				v.dwID = me.dwID
			end
			insert(aRec, v)
		end
	end
	sort(aRec, function(a, b) return a.dwSwitchTime < b.dwSwitchTime end)
	hDeathMsg:Clear()
	for _, data in ipairs(aRec) do
		local info = INFO_CACHE[data.dwID]
		local map = LIB.GetMapInfo(data.dwMapID)
		if map then
			local aXml = {}
			local t = TimeToDate(data.dwSwitchTime or data.dwTime)
			insert(aXml, GetFormatText(_L[' * '] .. format('[%02d:%02d:%02d]', t.hour, t.minute, t.second), 10, 255, 255, 255, 16, 'this.OnItemLButtonClick = MY_TeamTools_EnterMap.OnAppendEdit'))
			local r, g, b = LIB.GetForceColor(info.dwForceID)
			insert(aXml, GetFormatText('[' .. data.szName ..']', 10, r, g, b, 16, 'this.OnItemLButtonClick = function() OnItemLinkDown(this) end', 'namelink'))
			insert(aXml, GetFormatText(_L(' enter map %s', map.szName)))
			if LIB.IsDungeonMap(data.dwMapID) then
				if not IsEmpty(data.nCopyIndex) then
					insert(aXml, GetFormatText(_L(', copy id is %s', data.nCopyIndex)))
				end
				if not IsEmpty(data.aMapCopy) then
					insert(aXml, GetFormatText(_L(', copy cd is %s', concat(data.aMapCopy, ','))))
				end
			end
			insert(aXml, GetFormatText(_L['.']))
			insert(aXml, GetFormatText('\n'))
			hDeathMsg:AppendItemFromString(concat(aXml))
		end
	end
	hDeathMsg:FormatAllItemPos()
end

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_TeamTools_EnterMap')
	local wnd = frameTemp:Lookup('Wnd_EnterMap')
	wnd:Lookup('Btn_All', 'Text_BtnAll'):SetText(_L['Show all'])
	wnd:Lookup('Btn_Clear', 'Text_BtnClear'):SetText(_L['Clear record'])
	wnd:ChangeRelation(this, true, true)
	Wnd.CloseWindow(frameTemp)

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAMTOOLS_ENTERMAP')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	this.hEnterMap = frame:CreateItemData(SZ_INI, 'Handle_Item_EnterMap')
end

function D.OnActivePage()
	D.UpdatePage(this)
end

function D.OnEvent(event)
	if event == 'MY_TEAMTOOLS_ENTERMAP' then
		D.UpdatePage(this)
	elseif event == 'ON_MY_MOSAICS_RESET' then
		D.UpdatePage(this)
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_All' then
		RT_SELECT_MAP = nil
		D.UpdatePage(this:GetParent():GetParent())
	elseif szName == 'Btn_Clear' then
		LIB.Confirm(_L['Clear record'], D.ClearEnterMapLog)
	end
end

function D.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_EnterMap' then
		RT_SELECT_MAP = this.dwID
		D.UpdatePage(this:GetParent():GetParent():GetParent():GetParent())
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'Handle_EnterMap' then
		if this and this:Lookup('Image_Cover') and this:Lookup('Image_Cover'):IsValid() then
			this:Lookup('Image_Cover'):Hide()
		end
	end
	HideTip()
end

-- Module exports
do
local settings = {
	exports = {
		{
			fields = {
				OnInitPage = D.OnInitPage,
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_TeamTools.RegisterModule('EnterMap', _L['MY_TeamTools_EnterMap'], LIB.GeneGlobalNS(settings))
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnAppendEdit = D.OnAppendEdit,
			},
		},
	},
}
MY_TeamTools_EnterMap = LIB.GeneGlobalNS(settings)
end
