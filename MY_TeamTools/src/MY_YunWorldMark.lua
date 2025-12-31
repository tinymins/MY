--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 快捷入团
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_YunWorldMark'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_YunWorldMark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}

local USE_DISABLE_MS = 1000
local USE_COLOR_ACTIVE = { 255, 255, 0 }
local USE_COLOR_DISABLED = { 128, 128, 128 }

local FRAME_NAME = 'MY_YunWorldMark'

function D.ShowSceneWorldMark()
	local tTemplateToIndex = {}
	for _, info in ipairs((X.CONSTANT and X.CONSTANT.WORLD_MARK) or {}) do
		if info and info.dwNpcTemplateID and info.nIndex then
			tTemplateToIndex[info.dwNpcTemplateID] = info.nIndex
		end
	end

	local data = {}
	for i = 1, 10 do
		data[i] = { x = 0, y = 0, z = 0, mark = i }
	end

	for _, npc in ipairs(X.GetNearNpc()) do
		local nIndex = npc and tTemplateToIndex[npc.dwTemplateID]
		if nIndex and nIndex >= 1 and nIndex <= 10 then
			local nX = tonumber(npc.nX) or 0
			local nY = tonumber(npc.nY) or 0
			local nZ = tonumber(npc.nZ) or 0
			if not (nX == 0 and nY == 0 and nZ == 0) then
				data[nIndex] = { x = nX, y = nY, z = nZ, mark = nIndex }
			end
		end
	end

	-- 手动拼接可读的 JSON（同时保证能被 X.DecodeJSON 解析）
	-- 约束：第一层列表项使用 \t + 换行；对象内部不再使用 \t。
	local aText = { '[', }
	for i = 1, 10 do
		local pt = data[i] or {}
		local nX = tostring(tonumber(pt.x) or 0)
		local nY = tostring(tonumber(pt.y) or 0)
		local nZ = tostring(tonumber(pt.z) or 0)
		local nMark = tostring(tonumber(pt.mark) or i)
		local szLine = string.format('\t{ "x": %s, "y": %s, "z": %s, "mark": %s }', nX, nY, nZ, nMark)
		if i < 10 then
			szLine = szLine .. ','
		end
		table.insert(aText, szLine)
	end
	table.insert(aText, ']')
	local szText = table.concat(aText, '\n')
	X.UI.OpenTextEditor(szText, {
		w = 450,
		h = 300,
		title = _L['World mark'],
	})
end

function D.OpenPanel()
	X.UI.CloseFrame(FRAME_NAME)

	local me = X.GetClientPlayer()
	if not me then
		return
	end
	D.dwMapID = me.GetMapID() or 0

	local tMapName, aMapName, tMapMenu = {}, {}, {}
	for _, group in ipairs(X.GetTypeGroupMap()) do
		local tSub = { szOption = group.szGroup }
		for _, info in ipairs(group.aMapInfo) do
			table.insert(tSub, {
				szOption = info.szName,
				fnAction = function()
					D.dwMapID = info.dwID
					X.UI.ClosePopupMenu()
				end,
			})
			tMapName[info.dwID] = info.szName
			table.insert(aMapName, info.szName)
		end
		table.insert(tMapMenu, tSub)
	end
	local szCurrentMapName = tMapName[D.dwMapID] or ''
	local dwTargetType, dwTargetID = X.GetCharacterTarget(me)

	local ui = X.UI.CreateFrame(FRAME_NAME, {
		w = 760,
		h = 520,
		anchor = 'CENTER',
		close = true,
		resize = true,
		minWidth = 620,
		minHeight = 380,
		text = _L[MODULE_NAME],
		onSettingsClick = function()
			local menu = {
				{
					szOption = _L['Get current mark data'],
					fnAction = function()
						X.UI.ClosePopupMenu()
						D.ShowSceneWorldMark()
					end,
				},
				{
					szOption = _L['Restore world mark position'],
					fnAction = function()
						X.UI.ClosePopupMenu()
						X.UI.GetUserInput({
							title = _L['Please input world mark json:'],
							initialValue = '',
							multiline = true,
							maxLength = 99999,
							fnAction = function(szText)
								if X.IsEmpty(szText) then
									return
								end
								local data = X.DecodeJSON(szText)
								if not X.IsTable(data) then
									X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
									return
								end
								D.ApplyWorldMark(data)
							end,
						})
					end,
				},
			}
			X.UI.PopupMenu(menu)
		end,
		onSizeChange = function()
			local ui = X.UI(this)
			local nW, nH = ui:ContainerSize()
			ui:Fetch('WndTable_List'):Size(nW - 40, nH - 110)
		end,
	})

	local nX, nY = 20, 20 + 30
	local COMPONENT_H = 25

	nX = nX + ui:Append('WndAutocomplete', {
		name = 'WndAutocomplete_Map',
		x = nX,
		y = nY,
		w = 250,
		h = COMPONENT_H,
		text = szCurrentMapName,
		placeholder = _L['Current map'],
		autocomplete = { { 'option', 'source', aMapName } },
		menu = function() return tMapMenu end,
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.Search(ui)
				return 1
			end
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndEditBox', {
		name = 'WndEditBox_Search',
		x = nX,
		y = nY,
		w = 340,
		h = COMPONENT_H,
		text = dwTargetType == TARGET.NPC and X.GetNpcName(dwTargetID) or '',
		placeholder = _L['Search'],
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.Search(ui)
				return 1
			end
		end,
	}):Width() + 5

	ui:Append('WndButton', {
		name = 'Btn_Search',
		x = nX,
		y = nY,
		w = 100,
		h = COMPONENT_H,
		text = _L['Search'],
		onClick = function()
			D.Search(ui)
		end,
	})

	ui:Append('WndTable', {
		name = 'WndTable_List',
		x = 20,
		y = 90,
		w = 720,
		h = 390,
		columns = {
			{
				key = 'szName',
				title = _L['Name'],
				alignHorizontal = 'left',
				width = 260,
				render = function(value)
					return GetFormatText(' ' .. X.ReplaceSensitiveWord(tostring(value or '')), 162, 255, 255, 255)
				end,
			},
			{
				key = 'szAuthor',
				title = _L['Author'],
				alignHorizontal = 'left',
				width = 160,
				render = function(value)
					return GetFormatText(' ' .. X.ReplaceSensitiveWord(tostring(value or '')), 162, 255, 255, 255)
				end,
			},
			{
				key = 'dwUpdateTime',
				title = _L('Update time'),
				alignHorizontal = 'left',
				width = 170,
				render = function(value)
					return GetFormatText(' ' .. X.ReplaceSensitiveWord(tostring(value or '')), 162, 255, 255, 255)
				end,
			},
			{
				key = 'use',
				title = '',
				alignHorizontal = 'center',
				width = 90,
				render = function(_, record)
					return GetFormatText(_L['Use'], 162, 255, 255, 0, 255, 'this.szURL = ' .. X.EncodeLUAData(record and record.szDataURL or ''), 'Text_Use')
				end,
			},
		},
		dataSource = {},
	})

	ui:Show()
	D.Search(ui, 1)
end

function D.Search(ui, nPage)
	if not ui then
		return
	end
	-- 兼容传 raw 或 wrapper
	ui = X.UI(ui)

	nPage = tonumber(nPage) or 1
	if nPage < 1 then
		nPage = 1
	end

	local szSearch = X.TrimString(ui:Fetch('WndEditBox_Search'):Text() or '')
	local dwMapID = D.dwMapID or 0

	X.Ajax({
		url = MY_RSS.PULL_BASE_URL .. '/api/addon/common-monitor/subscribe/all',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			T = 3,
			map = dwMapID,
			q = szSearch,
			page = nPage,
			pageSize = 100,
		},
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			if not X.IsTable(res) or not X.IsTable(res.data) then
				X.OutputAnnounceMessage(_L['Fetch repo meta list failed.'])
				ui:Fetch('WndTable_List'):DataSource({})
				return
			end
			local aDataSource = {}
			for _, info in ipairs(res.data) do
				table.insert(aDataSource, {
					id = info.id,
					key = info.key,
					szName = info.name,
					szAuthor = info.author,
					dwUpdateTime = info.update,
					szDataURL = info.data_url,
					szAboutURL = info.about,
					__raw = info,
				})
			end
			ui:Fetch('WndTable_List'):DataSource(aDataSource)
		end,
		error = function(html, status)
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L[MODULE_NAME], 'ERROR Fetch list: ' .. X.EncodeLUAData(status) .. '\n' .. (X.ConvertToANSI(html) or ''), X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			X.OutputAnnounceMessage(_L['Fetch repo meta list failed.'])
			ui:Fetch('WndTable_List'):DataSource({})
		end,
	})
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Text_Use' then
		if not X.IsClientPlayerTeamMarker() then
			X.OutputAnnounceMessage(_L['Only team marker can do this.'])
			return
		end
		local szURL = this.szURL
		if X.IsEmpty(szURL) then
			return
		end
		D.ApplyYunWorldMark(szURL)

		-- 防止重复点击：置灰并禁用 2 秒
		local nNow = GetTime and GetTime() or 0
		if this.__MY_UseDisabledUntil and this.__MY_UseDisabledUntil > nNow then
			return
		end
		this.__MY_UseDisabledUntil = nNow + USE_DISABLE_MS
		local el = this
		if type(el.SetFontColor) == 'function' then
			el:SetFontColor(unpack(USE_COLOR_DISABLED))
		end
		local function RestoreUseButton()
			if not el or (type(el.IsValid) == 'function' and not el:IsValid()) then
				return
			end
			local nNow2 = GetTime and GetTime() or 0
			local nRemaining = (tonumber(el.__MY_UseDisabledUntil) or 0) - nNow2
			if nRemaining > 0 then
				X.DelayCall(nRemaining, RestoreUseButton)
				return
			end
			if type(el.SetFontColor) == 'function' then
				el:SetFontColor(unpack(USE_COLOR_ACTIVE))
			end
		end
		X.DelayCall(USE_DISABLE_MS, RestoreUseButton)
	end
end


function D.ApplyWorldMark(aList)
	if type(SetWorldMark) ~= 'function' then
		X.OutputAnnounceMessage(_L['Failed.'])
		return
	end
	if not X.IsTable(aList) then
		X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
		return
	end

	local nWillApply = 0
	for i, pt in ipairs(aList) do
		if X.IsTable(pt) then
			local nX = tonumber(pt.x) or 0
			local nY = tonumber(pt.y) or 0
			local nZ = tonumber(pt.z) or 0
			if not (nX == 0 and nY == 0 and nZ == 0) then
				local nIndex = tonumber(pt.mark) or i
				if nIndex > 0 then
					nWillApply = nWillApply + 1
				end
			end
		end
	end

	X.Confirm(_L('About to clear all current world marks and set %d new world marks, continue?', nWillApply), function()
		SetWorldMark(0)

		local nApplied = 0
		for i, pt in ipairs(aList) do
			if X.IsTable(pt) then
				local nX = tonumber(pt.x) or 0
				local nY = tonumber(pt.y) or 0
				local nZ = tonumber(pt.z) or 0
				if not (nX == 0 and nY == 0 and nZ == 0) then
					local nIndex = tonumber(pt.mark) or i
					if nIndex > 0 then
						SetWorldMark(nIndex, nX, nY, nZ)
						nApplied = nApplied + 1
					end
				end
			end
		end

		X.OutputAnnounceMessage(_L('Done, %s marks applied.', tostring(nApplied)))
	end)
end

function D.ApplyYunWorldMark(szURL)
	if X.IsEmpty(szURL) then
		return
	end
	if type(SetWorldMark) ~= 'function' then
		X.OutputAnnounceMessage(_L['Failed.'])
		return
	end

	local LUA_CONFIG = { passphrase = false, crc = false, compress = false }
	X.FetchLUAData(szURL, LUA_CONFIG)
		:Then(function(data)
			if not data then
				X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
				return
			end
			D.ApplyWorldMark(data)
		end)
		:Catch(function(error)
			X.OutputAnnounceMessage((error and error.message) or _L['Failed.'])
		end)
end

--------------------------------------------------------------------------------
-- 目标头像菜单：副本内 NPC 右键快捷搜索
--------------------------------------------------------------------------------
do
local function GetNpcTargetMenu()
	if not X.IsInDungeonMap() then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local dwType = X.GetCharacterTarget(me)
	if dwType ~= TARGET.NPC then
		return
	end
	return {
		szOption = _L['Search MY cloud world mark'],
		fnAction = function()
			D.OpenPanel()
		end,
	}
end
X.RegisterTargetAddonMenu('MY_YunWorldMark', GetNpcTargetMenu)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark',
	exports = {
		{
			root = D,
			fields = {
				'OpenPanel',
				'Search',
				'OnItemLButtonClick',
			},
			preset = 'UIEvent',
		},
	},
}
MY_YunWorldMark = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
