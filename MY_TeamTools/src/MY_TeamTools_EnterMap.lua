--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队工具 - 过图记录
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamTools_EnterMap'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_EnterMap'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_EnterMap.ini'

local PLAYER_ID  = 0
local ENTER_MAP_LOG = { RAID = {}, ROOM = {} }
local INFO_CACHE = { RAID = {}, ROOM = {} }
local RT_SELECT_MAP

function D.ClearEnterMapLog()
	ENTER_MAP_LOG = { RAID = {}, ROOM = {} }
	INFO_CACHE = { RAID = {}, ROOM = {} }
	FireUIEvent('MY_TEAMTOOLS_ENTERMAP')
end

X.RegisterEvent('LOADING_END', function()
	PLAYER_ID = X.GetClientPlayerID()
end)

X.RegisterBgMsg('MY_ENTER_MAP', function(_, aData, nChannel, dwTalkerID, szTalkerName, bSelf)
	local dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime, nCopyIndex = aData[1], aData[2], aData[3], aData[4], aData[5], aData[6]
	local tInfoCache, aEnterMapLog = {}, {}
	if nChannel == PLAYER_TALK_CHANNEL.RAID then
		aEnterMapLog = ENTER_MAP_LOG.RAID
		tInfoCache = INFO_CACHE.RAID
	elseif nChannel == PLAYER_TALK_CHANNEL.ROOM then
		aEnterMapLog = ENTER_MAP_LOG.ROOM
		tInfoCache = INFO_CACHE.ROOM
	end
	local key = dwTalkerID == PLAYER_ID
		and 'self'
		or dwTalkerID
	if not tInfoCache[dwTalkerID] then
		if key == 'self' then
			local me = X.GetClientPlayer()
			tInfoCache[dwTalkerID] = {
				szName = me.szName,
				dwForceID = me.dwForceID,
				dwMountKungfuID = UI_GetPlayerMountKungfuID(),
			}
		else
			local team = GetClientTeam()
			local info = X.GetTeamMemberInfo(dwTalkerID)
			if info then
				tInfoCache[dwTalkerID] = {
					szName = info.szName,
					dwForceID = info.dwForceID,
					dwMountKungfuID = info.dwActualMountKungfuID,
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
	for i, v in X.ipairs_r(aEnterMapLog) do -- 删除重复发送的过图
		if v.dwID == key and v.dwMapID == dwMapID and v.dwSubID == dwSubID and v.dwTime == dwTime then
			table.remove(aEnterMapLog, i)
		end
	end
	table.insert(aEnterMapLog, {
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
	local tInfoCache, aEnterMapLog = {}, {}
	if MY_TeamTools.szStatRange == 'RAID' then
		tInfoCache = INFO_CACHE.RAID
		aEnterMapLog = ENTER_MAP_LOG.RAID
	elseif MY_TeamTools.szStatRange == 'ROOM' then
		tInfoCache = INFO_CACHE.ROOM
		aEnterMapLog = ENTER_MAP_LOG.ROOM
	end
	local hDeathList = page:Lookup('Wnd_EnterMap/Scroll_Player_List', '')
	local aList, tList = {}, {}
	for _, v in ipairs(aEnterMapLog) do
		if tList[v.dwMapID] then
			tList[v.dwMapID].nCount = tList[v.dwMapID].nCount + 1
		else
			table.insert(aList, {
				dwMapID = v.dwMapID,
				nCount = 1,
			})
			tList[v.dwMapID] = aList[#aList]
		end
	end
	table.sort(aList, function(a, b) return a.nCount > b.nCount end)
	hDeathList:Clear()
	for _, v in ipairs(aList) do
		local map = X.GetMapInfo(v.dwMapID)
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
	local edit = X.GetChatInput()
	edit:ClearText()
	for i = this:GetIndex(), handle:GetItemCount() do
		local h = handle:Lookup(i)
		local szText = h:GetText()
		if szText == '\n' then
			break
		end
		if h:GetName() == 'namelink' then
			edit:InsertObj(szText, { type = 'name', text = szText, name = string.sub(szText, 2, -2) })
		else
			edit:InsertObj(szText, { type = 'text', text = szText })
		end
	end
	Station.SetFocusWindow(edit)
end

function D.UpdateList(page, dwMapID)
	local tInfoCache, aEnterMapLog = {}, {}
	if MY_TeamTools.szStatRange == 'RAID' then
		tInfoCache = INFO_CACHE.RAID
		aEnterMapLog = ENTER_MAP_LOG.RAID
	elseif MY_TeamTools.szStatRange == 'ROOM' then
		tInfoCache = INFO_CACHE.ROOM
		aEnterMapLog = ENTER_MAP_LOG.ROOM
	end
	local hDeathMsg = page:Lookup('Wnd_EnterMap/Scroll_Death_Info', '')
	local me = X.GetClientPlayer()
	local team = GetClientTeam()
	local aRec = {}
	local aEnterMapLog = X.Clone(aEnterMapLog)
	for _, v in ipairs(aEnterMapLog) do
		if not dwMapID or v.dwMapID == dwMapID then
			if v.dwID == 'self' then
				v.dwID = me.dwID
			end
			table.insert(aRec, v)
		end
	end
	table.sort(aRec, function(a, b) return a.dwSwitchTime < b.dwSwitchTime end)
	hDeathMsg:Clear()
	for _, data in ipairs(aRec) do
		local info = tInfoCache[data.dwID]
		local map = X.GetMapInfo(data.dwMapID)
		if map then
			local aXml = {}
			local t = TimeToDate(data.dwSwitchTime or data.dwTime)
			table.insert(aXml, GetFormatText(_L[' * '] .. string.format('[%02d:%02d:%02d]', t.hour, t.minute, t.second), 10, 255, 255, 255, 16, 'this.OnItemLButtonClick = MY_TeamTools_EnterMap.OnAppendEdit'))
			local r, g, b = X.GetForceColor(info.dwForceID)
			table.insert(aXml, GetFormatText('[' .. data.szName ..']', 10, r, g, b, 16, 'this.OnItemLButtonClick = function() OnItemLinkDown(this) end', 'namelink'))
			table.insert(aXml, GetFormatText(_L(' enter map %s', map.szName)))
			if X.IsDungeonMap(data.dwMapID) then
				if not X.IsEmpty(data.nCopyIndex) then
					table.insert(aXml, GetFormatText(_L(', copy id is %s', data.nCopyIndex)))
				end
				if not X.IsEmpty(data.aMapCopy) then
					table.insert(aXml, GetFormatText(_L(', copy cd is %s', table.concat(data.aMapCopy, ','))))
				end
			end
			table.insert(aXml, GetFormatText(_L['.']))
			table.insert(aXml, GetFormatText('\n'))
			hDeathMsg:AppendItemFromString(table.concat(aXml))
		end
	end
	hDeathMsg:FormatAllItemPos()
end

function D.OnInitPage()
	local frameTemp = X.UI.OpenFrame(SZ_INI, 'MY_TeamTools_EnterMap')
	local wnd = frameTemp:Lookup('Wnd_EnterMap')
	wnd:Lookup('Btn_All', 'Text_BtnAll'):SetText(_L['Show all'])
	wnd:Lookup('Btn_Clear', 'Text_BtnClear'):SetText(_L['Clear record'])
	wnd:ChangeRelation(this, true, true)
	X.UI.CloseFrame(frameTemp)
	X.UI.AdaptComponentAppearance(wnd:Lookup('Btn_All'))
	X.UI.AdaptComponentAppearance(wnd:Lookup('Btn_Clear'))
	X.UI.AdaptComponentAppearance(wnd:Lookup('Scroll_Player_List/ScrolBarl_Player_All_0'))
	X.UI.AdaptComponentAppearance(wnd:Lookup('Scroll_Death_Info/ScrolBarl_Player_All_0_0'))

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAMTOOLS_ENTERMAP')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_TEAM_TOOLS__STAT_RANGE_CHANGE')
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
	elseif event == 'MY_TEAM_TOOLS__STAT_RANGE_CHANGE' then
		D.UpdatePage(this)
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_All' then
		if IsCtrlKeyDown() or IsShiftKeyDown() then
			X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_ENTER_MAP_REQ', nil, true)
			X.SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, 'MY_ENTER_MAP_REQ', nil, true)
		else
			RT_SELECT_MAP = nil
			D.UpdatePage(this:GetParent():GetParent())
		end
	elseif szName == 'Btn_Clear' then
		X.Confirm(_L['Clear record'], D.ClearEnterMapLog)
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
	name = 'MY_TeamTools_EnterMap_Module',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnDeactivePage',
				bStatRange = true,
			},
			root = D,
		},
	},
}
MY_TeamTools.RegisterModule('EnterMap', _L['MY_TeamTools_EnterMap'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamTools_EnterMap',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				OnAppendEdit = D.OnAppendEdit,
			},
			root = D,
		},
	},
}
MY_TeamTools_EnterMap = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
