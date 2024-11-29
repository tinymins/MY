--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 用户设置导入导出界面
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.UserSettings')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local D = {}
local FRAME_NAME = X.NSFormatString('{$NS}_UserSettings')

function D.OpenImportExport(bImport)
	local tSettings = {}
	if bImport then
		local szRoot = X.FormatPath({'export/settings', X.PATH_TYPE.GLOBAL})
		local szPath = GetOpenFileName(_L['Please select import user settings file.'], 'User Settings File(*.us.jx3dat)\0*.us.jx3dat\0\0', szRoot)
		if X.IsEmpty(szPath) then
			return
		end
		tSettings = X.LoadLUAData(szPath, { passphrase = false }) or {}
	end
	X.UI.CloseFrame(FRAME_NAME)
	local W, H = 400, 600
	local uiFrame = X.UI.CreateFrame(FRAME_NAME, {
		w = W, h = H,
		text = bImport
			and _L['Import User Settings']
			or _L['Export User Settings'],
		esc = true,
	})
	local uiContainer = uiFrame:Append('WndScrollWindowBox', {
		x = 10, y = 50,
		w = W - 20, h = H - 60 - 40,
		containerType = X.UI.WND_CONTAINER_STYLE.LEFT_TOP,
	})
	local nW = uiContainer:ContainerWidth()
	local aGroup, tItemAll = {}, {}
	for _, us in ipairs(X.GetRegisterUserSettingsList()) do
		if us.szGroup and us.szLabel and not us.bUserData and (not bImport or tSettings[us.szKey]) then
			local tGroup
			for _, v in ipairs(aGroup) do
				if v.szGroup == us.szGroup then
					tGroup = v
					break
				end
			end
			if not tGroup then
				tGroup = {
					szGroup = us.szGroup,
					aItem = {},
				}
				table.insert(aGroup, tGroup)
			end
			local tItem
			for _, v in ipairs(tGroup.aItem) do
				if v.szLabel == us.szLabel then
					tItem = v
					break
				end
			end
			if not tItem then
				tItem = {
					szID = X.StringReplaceW(X.GetUUID(), '-', ''),
					szLabel = us.szLabel,
					aKey = {},
				}
				table.insert(tGroup.aItem, tItem)
				tItemAll[tItem.szID] = tItem
			end
			table.insert(tItem.aKey, us.szKey)
		end
	end
	-- 排序
	local tGroupRank = {}
	for i, category in ipairs(X.Panel.GetCategoryList()) do
		tGroupRank[category.szName] = i
	end
	table.sort(aGroup, function(g1, g2) return (tGroupRank[g1.szGroup] or math.huge) < (tGroupRank[g2.szGroup] or math.huge) end)
	-- 绘制
	local tItemChecked = {}
	for _, tGroup in ipairs(aGroup) do
		local uiGroupChk, tUiItemChk = nil, {}
		local function UpdateCheckboxState()
			local bCheckAll = true
			for _, tItem in ipairs(tGroup.aItem) do
				local bCheck = tItemChecked[tItem.szID]
				if not bCheck then
					bCheckAll = false
				end
				tUiItemChk[tItem.szID]:Check(bCheck, WNDEVENT_FIRETYPE.PREVENT)
			end
			uiGroupChk:Check(bCheckAll, WNDEVENT_FIRETYPE.PREVENT)
		end
		uiGroupChk = uiContainer:Append('WndWindow', { w = nW, h = 30 })
			:Append('WndCheckBox', {
				w = nW,
				text = tGroup.szGroup,
				color = {255, 255, 0},
				checked = true,
				onCheck = function (bCheck)
					for _, tItem in ipairs(tGroup.aItem) do
						tItemChecked[tItem.szID] = bCheck
					end
					UpdateCheckboxState()
				end,
			})
		for _, tItem in ipairs(tGroup.aItem) do
			tUiItemChk[tItem.szID] = uiContainer:Append('WndWindow', { w = nW / 3, h = 30 })
				:Append('WndCheckBox', {
					x = 0, w = nW / 3,
					text = tItem.szLabel,
					checked = true,
					onCheck = function(bCheck)
						tItemChecked[tItem.szID] = bCheck
						UpdateCheckboxState()
					end,
				})
			tItemChecked[tItem.szID] = true
		end
		uiContainer:Append('WndWindow', { w = nW, h = 10 })
	end
	uiFrame:Append('WndButtonBox', {
		x = (W - 200) / 2, y = H - 40,
		w = 200, h = 25,
		buttonStyle = 'FLAT',
		text = bImport and _L['Import'] or _L['Export'],
		onClick = function()
			local aKey, tKvp = {}, {}
			for szID, bCheck in pairs(tItemChecked) do
				if bCheck then
					local tItem = tItemAll[szID]
					for _, szKey in ipairs(tItem.aKey) do
						table.insert(aKey, szKey)
						tKvp[szKey] = tSettings[szKey]
					end
				end
			end
			if bImport then
				local nSuccess = X.ImportUserSettings(tKvp)
				X.OutputSystemAnnounceMessage(_L('%d settings imported.', nSuccess))
			else
				if #aKey == 0 then
					X.OutputSystemAnnounceMessage(_L['No custom setting selected, nothing to export.'], X.CONSTANT.MSG_THEME.ERROR)
					return
				end
				tKvp = X.ExportUserSettings(aKey)
				local nExport = 0
				for _ in pairs(tKvp) do
					nExport = nExport + 1
				end
				if nExport == 0 then
					X.OutputSystemAnnounceMessage(_L['No custom setting found, nothing to export.'], X.CONSTANT.MSG_THEME.ERROR)
					return
				end
				local szPath = X.FormatPath({
					'export/settings/'
						.. X.GetClientPlayerName()
						.. '_' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss')
						.. '.us.jx3dat',
					X.PATH_TYPE.GLOBAL
				})
				local szAbsolutePath = X.GetAbsolutePath(szPath)
				X.SaveLUAData(szPath, tKvp, { encoder = 'luatext', compress = false, crc = false, passphrase = false })
				X.OutputSystemMessage(_L('%d settings exported, file saved in %s.', nExport, szAbsolutePath))
				X.OpenFolder(szAbsolutePath)
			end
			uiFrame:Remove()
		end,
	})
	uiFrame:Anchor('CENTER')
end

function D.OpenExportPanel()
	D.OpenImportExport(false)
end

function D.OpenImportPanel()
	D.OpenImportExport(true)
end

function D.OpenLocationOverridePanel()
	local bDebug = IsCtrlKeyDown()
	local W, H = 800, 600
	local uiFrame = X.UI.CreateFrame(FRAME_NAME, {
		w = W, h = H,
		text = _L['User Settings Location Override'],
		esc = true,
	})

	local uiTable = nil
	local function GetDataSource()
		local aDataSource = {}
		for _, us in ipairs(X.GetRegisterUserSettingsList()) do
			if not us.bUserData then
				local szDescription = us.szKey
				if us.szDescription then
					if bDebug then
						szDescription = us.szDescription .. ' (' .. szDescription .. ')'
					else
						szDescription = us.szDescription
					end
				end
				table.insert(aDataSource, {
					szKey = us.szKey,
					szDescription = szDescription,
					eLocationOverride = us.eLocationOverride,
				})
			end
		end
		return aDataSource
	end

	uiTable = uiFrame:Append('WndTable', {
		x = 10, y = 50,
		w = W - 10 * 2, h = H - 50 - 10,
		columns = {
			{
				key = 'szDescription',
				title = ' ' .. _L['Settings description'],
				width = 580,
				alignHorizontal = 'left',
				alignVertical = 'middle',
				render = function(value, record, index)
					return GetFormatText(' ' .. value, 162, 255, 255, 255)
				end,
			},
			{
				key = 'preset',
				title = _L['Preset'],
				titleTip = {
					render = GetFormatText(_L['Preset mean follow preset location.'], 162, 255, 255, 0),
					rich = true,
				},
				width = 50,
				alignHorizontal = 'center',
				alignVertical = 'middle',
				render = function(value, record, index)
					if record.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.PRESET then
						return GetFormatText(_L['y'], 162, 255, 255, 255)
					end
					return ''
				end,
			},
			{
				key = 'role',
				title = _L['Role'],
				titleTip = {
					render = GetFormatText(_L['Role: always follow role.'], 162, 255, 255, 0),
					rich = true,
				},
				width = 50,
				alignHorizontal = 'center',
				alignVertical = 'middle',
				render = function(value, record, index)
					if record.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.ROLE then
						return GetFormatText(_L['y'], 162, 255, 255, 255)
					end
					return ''
				end,
			},
			{
				key = 'server',
				title = _L['Server'],
				titleTip = {
					render = GetFormatText(_L['Server: always follow server.'], 162, 255, 255, 0),
					rich = true,
				},
				width = 50,
				alignHorizontal = 'center',
				alignVertical = 'middle',
				render = function(value, record, index)
					if record.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.SERVER then
						return GetFormatText(_L['y'], 162, 255, 255, 255)
					end
					return ''
				end,
			},
			{
				key = 'global',
				title = _L['Global'],
				titleTip = {
					render = GetFormatText(_L['Global: always follow global.'], 162, 255, 255, 0),
					rich = true,
				},
				width = 50,
				alignHorizontal = 'center',
				alignVertical = 'middle',
				render = function(value, record, index)
					if record.eLocationOverride == X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.GLOBAL then
						return GetFormatText(_L['y'], 162, 255, 255, 255)
					end
					return ''
				end,
			},
		},
		dataSource = GetDataSource(),
		onCellLClick = function(xVal, tRow, nRowIndex, tCol, nColumnIndex)
			if tCol.key == 'preset' then
				X.SetUserSettingsLocationOverride(tRow.szKey, X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.PRESET)
			elseif tCol.key == 'role' then
				X.SetUserSettingsLocationOverride(tRow.szKey, X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.ROLE)
			elseif tCol.key == 'server' then
				X.SetUserSettingsLocationOverride(tRow.szKey, X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.SERVER)
			elseif tCol.key == 'global' then
				X.SetUserSettingsLocationOverride(tRow.szKey, X.CONSTANT.USER_SETTINGS_LOCATION_OVERRIDE.GLOBAL)
			end
			uiTable:DataSource(GetDataSource())
		end,
	})

	uiFrame:Anchor('CENTER')
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenExportPanel',
				'OpenImportPanel',
				'OpenLocationOverridePanel',
			},
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end

X.OpenUserSettingsExportPanel = D.OpenExportPanel
X.OpenUserSettingsImportPanel = D.OpenImportPanel
X.OpenUserSettingsLocationOverridePanel = D.OpenLocationOverridePanel

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
