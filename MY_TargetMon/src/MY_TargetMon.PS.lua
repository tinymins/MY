--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon.PS'

local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local C, D = {}, {
	GetTargetTypeList  = MY_TargetMonConfig.GetTargetTypeList ,
	LoadConfig         = MY_TargetMonConfig.LoadConfig        ,
	SaveConfig         = MY_TargetMonConfig.SaveConfig        ,
	GetConfigCaption   = MY_TargetMonConfig.GetConfigCaption  ,
	ImportPatchFile    = MY_TargetMonConfig.ImportPatchFile   ,
	ExportPatchFile    = MY_TargetMonConfig.ExportPatchFile   ,
	GetConfigList      = MY_TargetMonConfig.GetConfigList     ,
	CreateConfig       = MY_TargetMonConfig.CreateConfig      ,
	MoveConfig         = MY_TargetMonConfig.MoveConfig        ,
	ModifyConfig       = MY_TargetMonConfig.ModifyConfig      ,
	DeleteConfig       = MY_TargetMonConfig.DeleteConfig      ,
	CreateMonitor      = MY_TargetMonConfig.CreateMonitor     ,
	MoveMonitor        = MY_TargetMonConfig.MoveMonitor       ,
	ModifyMonitor      = MY_TargetMonConfig.ModifyMonitor     ,
	DeleteMonitor      = MY_TargetMonConfig.DeleteMonitor     ,
	CreateMonitorId    = MY_TargetMonConfig.CreateMonitorId   ,
	ModifyMonitorId    = MY_TargetMonConfig.ModifyMonitorId   ,
	DeleteMonitorId    = MY_TargetMonConfig.DeleteMonitorId   ,
	CreateMonitorLevel = MY_TargetMonConfig.CreateMonitorLevel,
	ModifyMonitorLevel = MY_TargetMonConfig.ModifyMonitorLevel,
	DeleteMonitorLevel = MY_TargetMonConfig.DeleteMonitorLevel,
}
local CUSTOM_BOXBG_STYLES = {
	{'', _L['None']},
	{'UI/Image/Common/Box.UITex|0'},
	{'UI/Image/Common/Box.UITex|1'},
	{'UI/Image/Common/Box.UITex|2'},
	{'UI/Image/Common/Box.UITex|3'},
	{'UI/Image/Common/Box.UITex|4'},
	{'UI/Image/Common/Box.UITex|5'},
	{'UI/Image/Common/Box.UITex|6'},
	{'UI/Image/Common/Box.UITex|7'},
	{'UI/Image/Common/Box.UITex|8'},
	{'UI/Image/Common/Box.UITex|9'},
	{'UI/Image/Common/Box.UITex|10'},
	{'UI/Image/Common/Box.UITex|11'},
	{'UI/Image/Common/Box.UITex|12'},
	{'UI/Image/Common/Box.UITex|13'},
	{'UI/Image/Common/Box.UITex|14'},
	{'UI/Image/Common/Box.UITex|34'},
	{'UI/Image/Common/Box.UITex|35'},
	{'UI/Image/Common/Box.UITex|42'},
	{'UI/Image/Common/Box.UITex|43'},
	{'UI/Image/Common/Box.UITex|44'},
	{'UI/Image/Common/Box.UITex|45'},
	{'UI/Image/Common/Box.UITex|77'},
	{'UI/Image/Common/Box.UITex|78'},
}
local CUSTOM_BOX_EXTENT_ANIMATE = {
	{nil, _L['None']},
	{'ui/Image/Common/Box.UITex|17'},
	{'ui/Image/Common/Box.UITex|20'},
}
local CUSTOM_CDBAR_STYLES = {
	PLUGIN_ROOT .. '/img/ST.UITex|0',
	PLUGIN_ROOT .. '/img/ST.UITex|1',
	PLUGIN_ROOT .. '/img/ST.UITex|2',
	PLUGIN_ROOT .. '/img/ST.UITex|3',
	PLUGIN_ROOT .. '/img/ST.UITex|4',
	PLUGIN_ROOT .. '/img/ST.UITex|5',
	PLUGIN_ROOT .. '/img/ST.UITex|6',
	PLUGIN_ROOT .. '/img/ST.UITex|7',
	PLUGIN_ROOT .. '/img/ST.UITex|8',
	'/ui/Image/Common/Money.UITex|168',
	'/ui/Image/Common/Money.UITex|203',
	'/ui/Image/Common/Money.UITex|204',
	'/ui/Image/Common/Money.UITex|205',
	'/ui/Image/Common/Money.UITex|206',
	'/ui/Image/Common/Money.UITex|207',
	'/ui/Image/Common/Money.UITex|208',
	'/ui/Image/Common/Money.UITex|209',
	'/ui/Image/Common/Money.UITex|210',
	'/ui/Image/Common/Money.UITex|211',
	'/ui/Image/Common/Money.UITex|212',
	'/ui/Image/Common/Money.UITex|213',
	'/ui/Image/Common/Money.UITex|214',
	'/ui/Image/Common/Money.UITex|215',
	'/ui/Image/Common/Money.UITex|216',
	'/ui/Image/Common/Money.UITex|217',
	'/ui/Image/Common/Money.UITex|218',
	'/ui/Image/Common/Money.UITex|219',
	'/ui/Image/Common/Money.UITex|220',
	'/ui/Image/Common/Money.UITex|228',
	'/ui/Image/Common/Money.UITex|232',
	'/ui/Image/Common/Money.UITex|233',
	'/ui/Image/Common/Money.UITex|234',
}

----------------------------------------------------------------------------------------------
-- 设置界面
----------------------------------------------------------------------------------------------
local PS = { szRestriction = 'MY_TargetMon' }

-- 绘制详细监控项设置界面
local function DrawDetail(ui)
	local w, h = ui:Size()
	local l_config, l_search, uiSearch
	local uiWrapper = ui:Append('WndWindow', { name = 'WndWindow_Wrapper', x = 0, y = 0, w = w, h = h })
	uiWrapper:Append('Shadow', { x = 0, y = 0, w = w, h = h, r = 0, g = 0, b = 0, alpha = 150 })
	uiWrapper:Append('Shadow', { x = 10, y = 10, w = w - 20, h = h - 20, r = 255, g = 255, b = 255, alpha = 40 })

	local x0, y0 = 20, 20
	local w0, h0 = w - 40, h - 30
	local w1, x1 = w0 - 5, x0
	local list = uiWrapper:Append('WndListBox', { x = x1, y = y0 + 30, w = w1, h = h0 - 35 - 30 })

	local function Search()
		list:ListBox('clear')
		for i, mon in ipairs(l_config.monitors) do
			if not l_search or l_search == ''
			or (mon.name and X.StringFindW(mon.name, l_search))
			or (mon.longAlias and X.StringFindW(mon.longAlias, l_search))
			or (mon.shortAlias and X.StringFindW(mon.shortAlias, l_search)) then
				list:ListBox('insert', {
					text = mon.name or mon.id,
					id = mon,
					data = { mon = mon },
				})
			end
		end
	end

	local function InsertMonitor(index)
		GetUserInput(_L['Please input name/id:'], function(szVal)
			szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
			if szVal ~= '' then
				local mon = D.CreateMonitor(l_config, szVal)
				local id = tonumber(szVal)
				if id then -- 直接添加ID特殊处理
					D.ModifyMonitor(mon, 'ignoreId', false)
					D.ModifyMonitor(mon, 'nameAlias', false)
					local monid = D.CreateMonitorId(mon, tonumber(szVal))
					D.ModifyMonitorId(monid, 'enable', true)
				end
				if index then
					D.MoveMonitor(l_config, mon, index - #l_config.monitors)
				end
				list:ListBox('insert', {
					text = mon.name or mon.id,
					id = mon,
					data = { mon = mon },
					index = index,
				})
				uiSearch:Text('')
			end
		end, function() end, function() end, nil, l_search or '')
	end

	uiSearch = uiWrapper:Append('WndEditBox', {
		x = x0, y = y0,
		w = 200, h = 30, placeholder = _L['Search'],
		onChange = function(text)
			l_search = text
			Search()
		end,
	})
	uiWrapper:Append('WndButton', {
		x = x1 + w1 - 60, y = y0 - 1, w = 60, h = 28,
		text = _L['Add'],
		buttonStyle = 'FLAT',
		onClick = function() InsertMonitor() end,
	})

	-- 初始化list控件
	local function onMenu(szID, szText, data)
		local mon = data.mon
		local search = l_search and l_search ~= ''
		local t1 = {
			{
				szOption = _L['Enable'],
				bCheck = true, bChecked = mon.enable,
				fnAction = function()
					D.ModifyMonitor(mon, 'enable', not mon.enable)
				end,
			},
			{ bDevide = true },
			{
				szOption = _L['Delete'],
				fnAction = function()
					D.DeleteMonitor(l_config, mon)
					list:ListBox('delete', 'id', mon)
					X.UI.ClosePopupMenu()
				end,
			},
			{
				szOption = _L['Insert'],
				fnAction = function()
					local index = #l_config.monitors
					for i, m in X.ipairs_r(l_config.monitors) do
						if m == mon then
							index = i
						end
					end
					InsertMonitor(index)
					X.UI.ClosePopupMenu()
				end,
				bDisable = search,
			},
			{
				szOption = _L['Move up'],
				fnAction = function()
					local index = #l_config.monitors
					for i, m in X.ipairs_r(l_config.monitors) do
						if m == mon then
							index = i
						end
					end
					if index < 2 then
						return
					end
					D.MoveMonitor(l_config, mon, -1)
					list:ListBox('exchange', 'index', index - 1, index)
				end,
				bDisable = search,
			},
			{
				szOption = _L['Move down'],
				fnAction = function()
					local index = #l_config.monitors
					for i, m in X.ipairs_r(l_config.monitors) do
						if m == mon then
							index = i
						end
					end
					if index == #l_config.monitors then
						return
					end
					D.MoveMonitor(l_config, mon, 1)
					list:ListBox('exchange', 'index', index + 1, index)
				end,
				bDisable = search,
			},
			{
				szOption = _L['Rename'],
				fnAction = function()
					GetUserInput(_L['Please input name/id:'], function(szVal)
						szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
						if szVal ~= '' then
							list:ListBox(
								'update',
								'id', mon,
								{ 'text' }, { szVal }
							)
							D.ModifyMonitor(mon, 'name', szVal)
						end
					end, function() end, function() end, nil, mon.name)
					X.UI.ClosePopupMenu()
				end,
			},
			{ bDevide = true },
			{
				szOption = _L['Display origin name when no alias'],
				bCheck = true, bChecked = not mon.nameAlias,
				fnAction = function()
					D.ModifyMonitor(mon, 'nameAlias', not mon.nameAlias)
				end,
			},
			{
				szOption = _L('Long alias: %s', mon.longAlias or _L['Not set']),
				fnAction = function()
					GetUserInput(_L['Please input long alias:'], function(szVal)
						szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
						if szVal == '' then
							szVal = nil
						end
						D.ModifyMonitor(mon, 'longAlias', szVal)
					end, function() end, function() end, nil, mon.longAlias or mon.name)
				end,
				rgb = mon.rgbLongAlias,
				bColorTable = true,
				fnChangeColor = function(_, r, g, b)
					D.ModifyMonitor(mon, 'rgbLongAlias', { r, g, b })
				end,
			},
			{
				szOption = _L('Short alias: %s', mon.shortAlias or _L['Not set']),
				fnAction = function()
					GetUserInput(_L['Please input short alias:'], function(szVal)
						szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
						if szVal == '' then
							szVal = nil
						end
						D.ModifyMonitor(mon, 'shortAlias', szVal)
					end, function() end, function() end, nil, mon.shortAlias or mon.name)
				end,
				rgb = mon.rgbShortAlias,
				bColorTable = true,
				fnChangeColor = function(_, r, g, b)
					D.ModifyMonitor(mon, 'rgbShortAlias', { r, g, b })
				end,
			},
		}
		-- 自身心法
		local t2 = {
			szOption = _L['Self kungfu'],
			{
				szOption = _L['All kungfus'],
				rgb = {255, 255, 0},
				bCheck = true,
				bChecked = mon.kungfus.all or X.IsEmpty(mon.kungfus),
				fnAction = function(_, bChecked)
					D.ModifyMonitor(mon, 'kungfus.all', bChecked)
				end,
			},
		}
		for _, force in ipairs(X.CONSTANT.FORCE_LIST) do
			for i, dwKungfuID in ipairs(X.GetForceKungfuIDs(force.dwID) or {}) do
				table.insert(t2, {
					szOption = X.GetSkillName(dwKungfuID, 1),
					rgb = {X.GetForceColor(force.dwID, 'foreground')},
					bCheck = true,
					bChecked = mon.kungfus[dwKungfuID],
					fnAction = function()
						D.ModifyMonitor(mon, {'kungfus', dwKungfuID}, not mon.kungfus[dwKungfuID])
					end,
					fnDisable = function() return mon.kungfus.all or X.IsEmpty(mon.kungfus) end,
				})
			end
		end
		table.insert(t1, t2)
		-- 目标心法
		local t2 = {
			szOption = _L['Target kungfu'],
			{
				szOption = _L['All kungfus'],
				rgb = {255, 255, 0},
				bCheck = true,
				bChecked = mon.tarkungfus.all or X.IsEmpty(mon.tarkungfus),
				fnAction = function(_, bChecked)
					D.ModifyMonitor(mon, 'tarkungfus.all', bChecked)
				end,
			},
			{
				szOption = _L['NPC'],
				rgb = {255, 255, 0},
				bCheck = true,
				bChecked = mon.tarkungfus.npc,
				fnAction = function()
					D.ModifyMonitor(mon, 'tarkungfus.npc', not mon.tarkungfus.npc)
				end,
				fnDisable = function() return mon.tarkungfus.all or X.IsEmpty(mon.tarkungfus) end,
			},
		}
		for _, force in ipairs(X.CONSTANT.FORCE_LIST) do
			for i, dwKungfuID in ipairs(X.GetForceKungfuIDs(force.dwID) or {}) do
				table.insert(t2, {
					szOption = X.GetSkillName(dwKungfuID, 1),
					rgb = {X.GetForceColor(force.dwID, 'foreground')},
					bCheck = true,
					bChecked = mon.tarkungfus[dwKungfuID],
					fnAction = function()
						D.ModifyMonitor(mon, {'tarkungfus', dwKungfuID}, not mon.tarkungfus[dwKungfuID])
					end,
					fnDisable = function() return mon.tarkungfus.all or X.IsEmpty(mon.tarkungfus) end,
				})
			end
		end
		table.insert(t1, t2)
		-- 地图要求
		local t2 = X.GetDungeonMenu({
			fnAction = function(p)
				D.ModifyMonitor(mon, {'maps', p.dwID}, not mon.maps[p.dwID])
			end,
			tChecked = mon.maps,
		})
		for i, p in ipairs(t2) do
			p.fnDisable = function() return mon.maps.all or X.IsEmpty(mon.maps) end
		end
		t2.szOption = _L['Map filter']
		table.insert(t2, 1, {
			szOption = _L['All maps'],
			bCheck = true,
			bChecked = mon.maps.all or X.IsEmpty(mon.maps),
			fnAction = function(_, bChecked)
				D.ModifyMonitor(mon, 'maps.all', bChecked)
			end,
		})
		table.insert(t1, t2)
		-- 隐藏消失的
		table.insert(t1, {
			szOption = l_config.hideVoid and _L['Show even void'] or _L['Hide if void'],
			bCheck = true,
			bChecked = mon.rHideVoid,
			fnAction = function()
				D.ModifyMonitor(mon, 'rHideVoid', not mon.rHideVoid)
			end,
		})
		-- 隐藏他人的
		if l_config.type == 'BUFF' then
			table.insert(t1, {
				szOption = l_config.hideOthers and _L['Show even others'] or _L['Hide if others'],
				bCheck = true,
				bChecked = mon.rHideOthers,
				fnAction = function()
					D.ModifyMonitor(mon, 'rHideOthers', not mon.rHideOthers)
				end,
			})
		end
		-- 出现声音
		local t2 = X.GetSoundMenu(function(dwID, bCheck)
			if not bCheck then
				for i, v in X.ipairs_r(mon.soundAppear) do
					if v == dwID then
						table.remove(mon.soundAppear, i)
					end
				end
			else
				table.insert(mon.soundAppear, dwID)
			end
			D.ModifyMonitor(mon, 'soundAppear', mon.soundAppear)
		end, X.ArrayToObject(mon.soundAppear), true)
		t2.szOption = _L['Play sound when appear']
		table.insert(t1, t2)
		-- 消失声音
		local t2 = X.GetSoundMenu(function(dwID, bCheck)
			if not bCheck then
				for i, v in X.ipairs_r(mon.soundDisappear) do
					if v == dwID then
						table.remove(mon.soundDisappear, i)
					end
				end
			else
				table.insert(mon.soundDisappear, dwID)
			end
			D.ModifyMonitor(mon, 'soundDisappear', mon.soundDisappear)
		end, X.ArrayToObject(mon.soundDisappear), true)
		t2.szOption = _L['Play sound when disappear']
		table.insert(t1, t2)
		-- 显示特效框
		local t2 = { szOption = _L['Active extent animate'] }
		for _, p in ipairs(CUSTOM_BOX_EXTENT_ANIMATE) do
			local t3 = {
				szOption = p[2] or p[1],
				bCheck = true, bMCheck = true,
				bChecked = p[1] == mon.extentAnimate,
				fnAction = function()
					D.ModifyMonitor(mon, 'extentAnimate', p[1])
				end,
				nIconMarginLeft = -3,
				nIconMarginRight = -3,
				szLayer = 'ICON_RIGHTMOST',
			}
			if p[1] then
				t3.szIcon, t3.nFrame = unpack(p[1]:split('|'))
			end
			table.insert(t2, t3)
		end
		table.insert(t1, t2)
		-- ID设置
		if not X.IsEmpty(mon.ids) then
			table.insert(t1, { bDevide = true })
			table.insert(t1, { szOption = _L['Ids'], bDisable = true })
			table.insert(t1, {
				szOption = _L['All ids'],
				bCheck = true,
				bChecked = mon.ignoreId,
				fnAction = function()
					D.ModifyMonitor(mon, 'ignoreId', not mon.ignoreId)
				end,
				szIcon = 'fromiconid',
				nFrame = mon.iconid or 13,
				nIconWidth = 22,
				nIconHeight = 22,
				szLayer = 'ICON_RIGHTMOST',
				fnClickIcon = function()
					X.UI.OpenIconPicker(function(dwIcon)
						mon.iconid = dwIcon
					end)
					X.UI.ClosePopupMenu()
				end,
			})
			for dwID, info in pairs(mon.ids) do
				local t2 = {
					szOption = dwID,
					bCheck = true,
					bChecked = info.enable,
					fnAction = function()
						D.ModifyMonitorId(info, 'enable', not info.enable)
					end,
					fnDisable = function()
						return mon.ignoreId
					end,
					szIcon = 'fromiconid',
					nFrame = info.iconid or 13,
					nIconWidth = 22,
					nIconHeight = 22,
					szLayer = 'ICON_RIGHTMOST',
					fnClickIcon = function()
						if mon.ignoreId then
							return
						end
						X.UI.OpenIconPicker(function(dwIcon)
							D.ModifyMonitorId(info, 'iconid', dwIcon)
						end)
						X.UI.ClosePopupMenu()
					end,
				}
				if not X.IsEmpty(info.levels) then
					table.insert(t2, { szOption = _L['Levels'], bDisable = true })
					table.insert(t2, X.CONSTANT.MENU_DIVIDER)
					table.insert(t2, {
						szOption = _L['All levels'],
						bCheck = true,
						bChecked = info.ignoreLevel,
						fnAction = function()
							D.ModifyMonitorId(info, 'ignoreLevel', not info.ignoreLevel)
						end,
						szIcon = 'fromiconid',
						nFrame = info.iconid or 13,
						nIconWidth = 22,
						nIconHeight = 22,
						szLayer = 'ICON_RIGHTMOST',
						fnClickIcon = function()
							if mon.ignoreId or info.ignoreLevel then
								return
							end
							X.UI.OpenIconPicker(function(dwIcon)
								info.iconid = dwIcon
							end)
							X.UI.ClosePopupMenu()
						end,
					})
					local tLevels = {}
					for nLevel, infoLevel in pairs(info.levels) do
						table.insert(tLevels, {
							nLevel, {
								szOption = nLevel,
								bCheck = true,
								bChecked = infoLevel.enable,
								fnAction = function()
									D.ModifyMonitorLevel(infoLevel, 'enable', not infoLevel.enable)
								end,
								fnDisable = function()
									return mon.ignoreId or info.ignoreLevel
								end,
								szIcon = 'fromiconid',
								nFrame = infoLevel.iconid or 13,
								nIconWidth = 22,
								nIconHeight = 22,
								szLayer = 'ICON_RIGHTMOST',
								fnClickIcon = function()
									X.UI.OpenIconPicker(function(dwIcon)
										D.ModifyMonitorLevel(infoLevel, 'iconid', dwIcon)
									end)
									X.UI.ClosePopupMenu()
								end,
							}
						})
					end
					table.sort(tLevels, function(a, b) return a[1] < b[1] end)
					for _, p in ipairs(tLevels) do
						table.insert(t2, p[2])
					end
					table.insert(t2, X.CONSTANT.MENU_DIVIDER)
				end
				table.insert(t2, {
					szOption = _L['Manual add level'],
					fnAction = function()
						GetUserInput(_L['Please input level:'], function(szVal)
							local nLevel = tonumber(string.gsub(szVal, '^%s*(.-)%s*$', '%1'), 10)
							if nLevel then
								if info.levels[nLevel] then
									return
								end
								local dwIconID = 13
								if l_config.type == 'SKILL' then
									dwIconID = Table_GetSkillIconID(dwID, nLevel) or dwIconID
								else
									dwIconID = Table_GetBuffIconID(dwID, nLevel) or dwIconID
								end
								local infoLevel = D.CreateMonitorLevel(info, nLevel)
								D.ModifyMonitorLevel(infoLevel, 'iconid', dwIconID)
							end
						end, function() end, function() end, nil, nil)
					end,
				})
				table.insert(t2, {
					szOption = _L['Delete'],
					fnAction = function()
						D.DeleteMonitorId(mon, dwID)
						X.UI.ClosePopupMenu()
					end,
				})
				table.insert(t1, t2)
			end
		end
		table.insert(t1, { bDevide = true })
		table.insert(t1, {
			szOption = _L['Auto capture by name'],
			bCheck = true, bChecked = mon.capture,
			fnAction = function()
				D.ModifyMonitor(mon, 'capture', not mon.capture)
			end,
		})
		table.insert(t1, {
			szOption = _L['Manual add id'],
			fnAction = function()
				GetUserInput(_L['Please input id:'], function(szVal)
					local dwID = tonumber(string.gsub(szVal, '^%s*(.-)%s*$', '%1'), 10)
					if dwID then
						if mon.ids[dwID] then
							return
						end
						local dwIconID = 13
						if l_config.type == 'SKILL' then
							local dwLevel = X.GetClientPlayer().GetSkillLevel(dwID) or 1
							dwIconID = Table_GetSkillIconID(dwID, dwLevel) or dwIconID
						else
							dwIconID = Table_GetBuffIconID(dwID, 1) or 13
						end
						local info = D.CreateMonitorId(mon, dwID)
						D.ModifyMonitorId(info, 'iconid', dwIconID)
					end
				end, function() end, function() end, nil, nil)
			end,
		})
		return t1
	end
	list:ListBox('onmenu', onMenu)

	local function OpenDetail(config)
		l_config = config
		Search()
		uiWrapper:Show()
		uiWrapper:BringToTop()
	end

	uiWrapper:Append('WndButton', {
		x = x0 + w0 / 2 - 50, y = y0 + h0 - 30,
		w = 100, h = 30,
		text = _L['Close'],
		buttonStyle = 'FLAT',
		onClick = function()
			l_config = nil
			uiWrapper:Hide()
		end,
	})
	uiWrapper:Hide()

	return OpenDetail
end

-- 绘制总览界面
local function DrawPreview(ui, config, OpenDetail)
	local nPaddingX, nPaddingY = 10, 10
	local x, y = nPaddingX, nPaddingY
	local w, h = ui:Size()
	local uiWnd = ui:Append('WndWindow', { w = w, h = 190 })
	uiWnd:Append('Text', {
		x = x, y = y - 3, w = 20,
		r = 255, g = 255, b = 0,
		text = _L['*'],
	})
	if config.embedded then
		local szCaption = D.GetConfigCaption(config)
		uiWnd:Append('Text', {
			x = x + 20, y = y - 3, w = w - 290,
			r = 255, g = 255, b = 0, text = szCaption,
			tip = {
				render = szCaption .. '\n' .. _L['(Embedded caption cannot be changed)'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		}):AutoWidth()
	else
		uiWnd:Append('WndEditBox', {
			x = x + 20, y = y, w = w - 290, h = 22,
			r = 255, g = 255, b = 0, text = config.caption,
			onChange = function(val) D.ModifyConfig(config, 'caption', val) end,
		})
	end
	uiWnd:Append('WndButton', {
		x = w - 180, y = y,
		w = 50, h = 25,
		text = _L['Move Up'],
		buttonStyle = 'FLAT',
		onClick = function()
			D.MoveConfig(config, -1)
			X.SwitchTab('MY_TargetMon', true)
		end,
	})
	uiWnd:Append('WndButton', {
		x = w - 125, y = y,
		w = 50, h = 25,
		text = _L['Move Down'],
		buttonStyle = 'FLAT',
		onClick = function()
			D.MoveConfig(config, 1)
			X.SwitchTab('MY_TargetMon', true)
		end,
	})
	uiWnd:Append('WndButton', {
		x = w - 70, y = y,
		w = 60, h = 25,
		text = _L['Delete'],
		buttonStyle = 'FLAT',
		onClick = function()
			D.DeleteConfig(config, IsCtrlKeyDown())
			X.SwitchTab('MY_TargetMon', true)
		end,
		tip = {
			render = config.embedded and _L['Press ctrl to delete embedded data permanently.'] or nil,
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
	})
	y = y + 30

	local deltaY = 31
	x = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Enable'],
		checked = config.enable,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'enable', bChecked)
		end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 90, y = y, w = 200,
		text = _L['Hide others buff'],
		tip = {
			render = _L['Hide others buff TIP'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		checked = config.hideOthers,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'hideOthers', bChecked)
		end,
		autoEnable = function()
			return config.enable and config.type == 'BUFF'
		end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 180, y = y, w = 180,
		text = _L['Hide void'],
		checked = config.hideVoid,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'hideVoid', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	x = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = x, y = y, w = 90,
		text = _L['Penetrable'],
		checked = config.penetrable,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'penetrable', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 90, y = y, w = 100,
		text = _L['Undragable'],
		checked = not config.draggable,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'draggable', not bChecked)
		end,
		autoEnable = function() return config.enable and not config.penetrable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 180, y = y, w = 120,
		text = _L['Ignore system ui scale'],
		checked = config.ignoreSystemUIScale,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'ignoreSystemUIScale', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	x = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Show cd circle'],
		checked = config.cdCircle,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'cdCircle', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 90, y = y, w = 200,
		text = _L['Show cd flash'],
		checked = config.cdFlash,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'cdFlash', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 180, y = y, w = 200,
		text = _L['Show cd ready spark'],
		checked = config.cdReadySpark,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'cdReadySpark', bChecked)
		end,
		autoEnable = function() return config.enable and not config.hideVoid end,
	})
	y = y + deltaY

	x = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = x, y = y, w = 120,
		text = _L['Show cd bar'],
		checked = config.cdBar,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'cdBar', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 90, y = y, w = 120,
		text = _L['Show name'],
		checked = config.showName,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'showName', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = x + 180, y = y, w = 120,
		text = _L['Show time'],
		checked = config.showTime,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'showTime', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	x = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = x, y = y, w = 90,
		text = _L['Play sound'],
		checked = config.playSound,
		onCheck = function(bChecked)
			D.ModifyConfig(config, 'playSound', bChecked)
		end,
		autoEnable = function() return config.enable end,
	})

	uiWnd:Append('WndComboBox', {
		x = x + 90, y = y, w = 100,
		text = _L['Icon style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, p in ipairs(CUSTOM_BOXBG_STYLES) do
				szIcon, nFrame = unpack(p[1]:split('|'))
				subt = {
					szOption = p[2] or p[1],
					fnAction = function()
						D.ModifyConfig(config, 'boxBgUITex', p[1])
						X.UI.ClosePopupMenu()
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = 'ICON_RIGHTMOST',
					bCheck = true, bMCheck = true,
				}
				if p[1] == config.boxBgUITex then
					subt.rgb = {255, 255, 0}
					subt.bChecked = true
				end
				table.insert(t, subt)
			end
			return t
		end,
		autoEnable = function() return config.enable end,
	})
	uiWnd:Append('WndComboBox', {
		x = x + 90 + 100, y = y, w = 100,
		text = _L['Countdown style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CDBAR_STYLES) do
				szIcon, nFrame = unpack(text:split('|'))
				subt = {
					szOption = text,
					fnAction = function()
						D.ModifyConfig(config, 'cdBarUITex', text)
						X.UI.ClosePopupMenu()
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = 'ICON_FILL',
					bCheck = true, bMCheck = true,
				}
				if string.lower(text) == string.lower(config.cdBarUITex) then
					subt.rgb = {255, 255, 0}
					subt.bChecked = true
				end
				table.insert(t, subt)
			end
			return t
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + 30

	y = nPaddingY + 30
	local deltaY = 21
	local xr = w - 280
	uiWnd:Append('WndComboBox', {
		x = xr, y = y, w = 135,
		text = _L['Set target'],
		menu = function()
			local t = {}
			for _, eType in ipairs(D.GetTargetTypeList()) do
				table.insert(t, {
					szOption = _L.TARGET[eType],
					bCheck = true, bMCheck = true,
					bChecked = eType == (config.type == 'SKILL' and 'CONTROL_PLAYER' or config.target),
					fnDisable = function()
						return config.type == 'SKILL' and eType ~= 'CONTROL_PLAYER'
					end,
					fnAction = function()
						D.ModifyConfig(config, 'target', eType)
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'BUFF', 'SKILL'}) do
				table.insert(t, {
					szOption = _L.TYPE[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.type,
					fnAction = function()
						D.ModifyConfig(config, 'type', eType)
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'LEFT', 'RIGHT', 'CENTER'}) do
				table.insert(t, {
					szOption = _L.ALIGNMENT[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.alignment,
					fnAction = function()
						D.ModifyConfig(config, 'alignment', eType)
					end,
				})
			end
			return t
		end,
		autoEnable = function() return config.enable end,
	})
	uiWnd:Append('WndButton', {
		x = xr + 140, y = y, w = 102,
		text = _L['Set monitor'],
		buttonStyle = 'FLAT',
		onClick = function() OpenDetail(config) end,
		autoEnable = function() return config.enable end,
	})
	y = y + 24

	uiWnd:Append('WndTrackbar', {
		x = xr, y = y,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textFormatter = function(val) return _L('Display %d eachline.', val) end,
		onChange = function(val)
			D.ModifyConfig(config, 'maxLineCount', val)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	uiWnd:Append('WndTrackbar', {
		x = xr, y = y,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textFormatter = function(val) return _L('UI scale %d%%.', val) end,
		onChange = function(val)
			D.ModifyConfig(config, 'scale', val / 100)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	uiWnd:Append('WndTrackbar', {
		x = xr, y = y,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		range = {1, 300},
		value = config.iconFontScale * 100,
		textFormatter = function(val) return _L('Icon font scale %d%%.', val) end,
		onChange = function(val)
			D.ModifyConfig(config, 'iconFontScale', val / 100)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	uiWnd:Append('WndTrackbar', {
		x = xr, y = y,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		range = {1, 300},
		value = config.otherFontScale * 100,
		textFormatter = function(val) return _L('Other font scale %d%%.', val) end,
		onChange = function(val)
			D.ModifyConfig(config, 'otherFontScale', val / 100)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	uiWnd:Append('WndTrackbar', {
		x = xr, y = y,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		range = {50, 1000},
		value = config.cdBarWidth,
		textFormatter = function(val) return _L('CD width %dpx.', val) end,
		onChange = function(val)
			D.ModifyConfig(config, 'cdBarWidth', val)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	uiWnd:Append('WndTrackbar', {
		x = xr, y = y,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		range = {-1, 30},
		value = config.decimalTime,
		textFormatter = function(val)
			if val == -1 then
				return _L['Always show decimal time.']
			elseif val == 0 then
				return _L['Never show decimal time.']
			else
				return _L('Show decimal time left in %ds.', val)
			end
		end,
		onChange = function(val)
			D.ModifyConfig(config, 'decimalTime', val)
		end,
		autoEnable = function() return config.enable end,
	})
	y = y + deltaY

	return x, y
end

local function DrawControls(ui, OpenDetail)
	ui:Children('#Wnd_Controls'):Remove()
	local w, h = ui:Size()
	local uiWnd = ui:Append('WndWindow', { name = 'Wnd_Controls', w = w, h = 80 })
	local x, y = (w - 380) / 2, 10
	uiWnd:Append('WndButton', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Create'],
		buttonStyle = 'FLAT',
		onClick = function()
			local config = D.CreateConfig()
			DrawPreview(ui, config, OpenDetail)
			DrawControls(ui, OpenDetail)
			ui:FormatChildrenPos()
		end,
	})
	x = x + 70
	uiWnd:Append('WndButton', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Import'],
		buttonStyle = 'FLAT',
		onClick = function()
			local file = GetOpenFileName(
				_L['Please select import target monitor data file.'],
				'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
				X.FormatPath({ 'export/TargetMon', X.PATH_TYPE.GLOBAL })
			)
			if file == '' then
				return
			end
			local nImportCount, nReplaceCount = D.ImportPatchFile(file)
			local szTip
			if nImportCount then
				if nImportCount > 0 then
					X.SwitchTab('MY_TargetMon', true)
				end
				szTip = _L('Import successed, %d imported and %d replaced.', nImportCount, nReplaceCount)
			else
				szTip = _L['Import failed, cannot decode file.']
			end
			X.Sysmsg(szTip)
			OutputMessage('MSG_ANNOUNCE_YELLOW', szTip)
		end,
	})
	x = x + 70
	uiWnd:Append('WndButton', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Export'],
		buttonStyle = 'FLAT',
		tip = {
			render = _L['Press ALT to export as default data.\n Press CTRL to export as plain.'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		menu = function()
			local aUUID = {}
			local menu = {}
			local bAsEmbedded = IsAltKeyDown()
			local szIndent = not bAsEmbedded and IsCtrlKeyDown() and '\t' or nil
			for _, config in ipairs(D.GetConfigList(bAsEmbedded)) do
				table.insert(menu, {
					bCheck = true,
					szOption = D.GetConfigCaption(config),
					fnAction = function()
						for i, uuid in X.ipairs_r(aUUID) do
							if uuid == config.uuid then
								table.remove(aUUID, i)
								return
							end
						end
						table.insert(aUUID, config.uuid)
					end,
				})
			end
			if #menu > 0 then
				table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			end
			table.insert(menu, {
				szOption = bAsEmbedded
					and _L['Ensure export (as embedded)']
					or (szIndent and _L['Ensure export (with indent)'] or _L['Ensure export']),
				fnAction = function()
					if X.ENVIRONMENT.GAME_PROVIDER == 'remote' then
						return X.Alert(_L['Streaming client does not support export!'])
					end
					local file = X.FormatPath({
						'export/TargetMon/'
							.. (bAsEmbedded and 'embedded/' or '')
							.. '{$name}@{$server}@'
							.. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss')
							.. (bAsEmbedded and '.{$lang}' or '')
							.. '.jx3dat',
						X.PATH_TYPE.GLOBAL,
					})
					D.ExportPatchFile(file, aUUID, szIndent, bAsEmbedded)
					X.Sysmsg(_L('Data exported, file saved at %s.', file))
					OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Data exported, file saved at %s.', file))
				end,
				fnDisable = function()
					return not next(aUUID)
				end,
			})
			return menu
		end,
	})
	x = x + 70
	uiWnd:Append('WndButton', {
		x = x, y = y,
		w = 80, h = 30,
		text = _L['Save As Default'],
		buttonStyle = 'FLAT',
		onClick = function()
			X.Confirm(_L['Sure to save as default?'], function()
				D.SaveConfig(true)
			end)
		end,
	})
	x = x + 90
	uiWnd:Append('WndButton', {
		x = x, y = y,
		w = 80, h = 30,
		text = _L['Reset Default'],
		buttonStyle = 'FLAT',
		onClick = function()
			X.Dialog(_L['Sure to reset default?'], {
				{
					szOption = _L['Origin config'],
					fnAction = function()
						D.LoadConfig(true, true)
						X.SwitchTab('MY_TargetMon', true)
					end,
				},
				{
					szOption = _L['Default config'],
					fnAction = function()
						D.LoadConfig(true, false)
						X.SwitchTab('MY_TargetMon', true)
					end,
				},
				{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
			})
		end,
	})
	x = x + 90

	return uiWnd
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	ui:ContainerType(X.UI.WND_CONTAINER_STYLE.LEFT_TOP)

	local OpenDetail = DrawDetail(ui)
	for _, config in ipairs(D.GetConfigList()) do
		DrawPreview(ui, config, OpenDetail)
	end
	DrawControls(ui, OpenDetail)
	ui:FormatChildrenPos()
end

function PS.OnPanelScroll(wnd, scrollX, scrollY)
	wnd:Lookup('WndWindow_Wrapper'):SetRelPos(scrollX, scrollY)
end
X.RegisterPanel(_L['Target'], 'MY_TargetMon', _L['Target monitor'], 'ui/Image/ChannelsPanel/NewChannels.UITex|141', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
