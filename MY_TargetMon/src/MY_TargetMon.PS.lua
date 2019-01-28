--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
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
local MY, UI = MY, MY.UI
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local Get, GetPatch, ApplyPatch, RandomChild = MY.Get, MY.GetPatch, MY.ApplyPatch, MY.RandomChild
---------------------------------------------------------------------------------------------------

local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_TargetMon/lang/')
if not MY.AssertVersion('MY_TargetMon', _L['MY_TargetMon'], 0x2011800) then
	return
end
local C, D = {}, {
	GetTargetTypeList  = MY_TargetMonConfig.GetTargetTypeList ,
	LoadConfig         = MY_TargetMonConfig.LoadConfig        ,
	SaveConfig         = MY_TargetMonConfig.SaveConfig        ,
	ImportPatches      = MY_TargetMonConfig.ImportPatches     ,
	ExportPatches      = MY_TargetMonConfig.ExportPatches     ,
	GetConfig          = MY_TargetMonConfig.GetConfig         ,
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
	MY.GetAddonInfo().szUITexST .. '|' .. 0,
	MY.GetAddonInfo().szUITexST .. '|' .. 1,
	MY.GetAddonInfo().szUITexST .. '|' .. 2,
	MY.GetAddonInfo().szUITexST .. '|' .. 3,
	MY.GetAddonInfo().szUITexST .. '|' .. 4,
	MY.GetAddonInfo().szUITexST .. '|' .. 5,
	MY.GetAddonInfo().szUITexST .. '|' .. 6,
	MY.GetAddonInfo().szUITexST .. '|' .. 7,
	MY.GetAddonInfo().szUITexST .. '|' .. 8,
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
local PS = {}

-- 绘制详细监控项设置界面
local function DrawDetail(ui)
	local w, h = ui:size()
	local l_config, l_search, uiSearch
	local uiWrapper = ui:append('WndWindow', { name = 'WndWindow_Wrapper', x = 0, y = 0, w = w, h = h }, true)
	uiWrapper:append('Shadow', { x = 0, y = 0, w = w, h = h, r = 0, g = 0, b = 0, alpha = 150 })
	uiWrapper:append('Shadow', { x = 10, y = 10, w = w - 20, h = h - 20, r = 255, g = 255, b = 255, alpha = 40 })

	local x0, y0 = 20, 20
	local w0, h0 = w - 40, h - 30
	local w1, x1 = w0 - 5, x0
	local list = uiWrapper:append('WndListBox', { x = x1, y = y0 + 30, w = w1, h = h0 - 35 - 30 }, true)

	local function Search()
		list:listbox('clear')
		for i, mon in ipairs(l_config.monitors) do
			if not l_search or l_search == ''
			or (mon.name and wfind(mon.name, l_search))
			or (mon.longAlias and wfind(mon.longAlias, l_search))
			or (mon.shortAlias and wfind(mon.shortAlias, l_search)) then
				list:listbox(
					'insert',
					mon.name or mon.id,
					mon,
					{ mon = mon }
				)
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
					D.MoveMonitor(l_config, mon, #l_config.monitors - index)
				end
				list:listbox(
					'insert',
					mon.name or mon.id,
					mon,
					{ mon = mon },
					index
				)
				uiSearch:text('')
			end
		end, function() end, function() end, nil, l_search or '')
	end

	uiSearch = uiWrapper:append('WndEditBox', {
		x = x0, y = y0,
		w = 200, h = 30, placeholder = _L['Search'],
		onchange = function(text)
			l_search = text
			Search()
		end,
	}, true)
	uiWrapper:append('WndButton2', {
		x = x1 + w1 - 60, y = y0 - 1, w = 60, h = 28,
		text = _L['Add'], onclick = function() InsertMonitor() end,
	})

	-- 初始化list控件
	local function onMenu(hItem, szText, szID, data)
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
					list:listbox('delete', 'id', mon)
					Wnd.CloseWindow('PopupMenuPanel')
				end,
			},
			{
				szOption = _L['Insert'],
				fnAction = function()
					local index = #l_config.monitors
					for i, m in ipairs_r(l_config.monitors) do
						if m == mon then
							index = i
						end
					end
					InsertMonitor(index)
				end,
				bDisable = search,
			},
			{
				szOption = _L['Move up'],
				fnAction = function()
					local index = #l_config.monitors
					for i, m in ipairs_r(l_config.monitors) do
						if m == mon then
							index = i
						end
					end
					if index < 2 then
						return
					end
					D.MoveMonitor(l_config, mon, -1)
					list:listbox('exchange', 'index', index - 1, index)
				end,
				bDisable = search,
			},
			{
				szOption = _L['Move down'],
				fnAction = function()
					local index = #l_config.monitors
					for i, m in ipairs_r(l_config.monitors) do
						if m == mon then
							index = i
						end
					end
					if index == #l_config.monitors then
						return
					end
					D.MoveMonitor(l_config, mon, 1)
					list:listbox('exchange', 'index', index + 1, index)
				end,
				bDisable = search,
			},
			{
				szOption = _L['Rename'],
				fnAction = function()
					GetUserInput(_L['Please input name/id:'], function(szVal)
						szVal = (string.gsub(szVal, '^%s*(.-)%s*$', '%1'))
						if szVal ~= '' then
							list:listbox(
								'update',
								'id', mon,
								{ 'text' }, { szVal }
							)
							D.ModifyMonitor(mon, 'name', szVal)
						end
					end, function() end, function() end, nil, mon.name)
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
				bChecked = mon.kungfus.all or IsEmpty(mon.kungfus),
				fnAction = function(_, bChecked)
					D.ModifyMonitor(mon, 'kungfus.all', bChecked)
				end,
			},
		}
		for _, dwForceID in ipairs(MY.GetForceList()) do
			for i, dwKungfuID in ipairs(MY.GetForceKungfuList(dwForceID) or {}) do
				insert(t2, {
					szOption = MY.GetSkillName(dwKungfuID, 1),
					rgb = {MY.GetForceColor(dwForceID, 'foreground')},
					bCheck = true,
					bChecked = mon.kungfus[dwKungfuID],
					fnAction = function()
						D.ModifyMonitor(mon, {'kungfus', dwKungfuID}, not mon.kungfus[dwKungfuID])
					end,
					fnDisable = function() return mon.kungfus.all or IsEmpty(mon.kungfus) end,
				})
			end
		end
		insert(t1, t2)
		-- 目标心法
		local t2 = {
			szOption = _L['Target kungfu'],
			{
				szOption = _L['All kungfus'],
				rgb = {255, 255, 0},
				bCheck = true,
				bChecked = mon.tarkungfus.all or IsEmpty(mon.tarkungfus),
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
				fnDisable = function() return mon.tarkungfus.all or IsEmpty(mon.tarkungfus) end,
			},
		}
		for _, dwForceID in ipairs(MY.GetForceList()) do
			for i, dwKungfuID in ipairs(MY.GetForceKungfuList(dwForceID) or {}) do
				insert(t2, {
					szOption = MY.GetSkillName(dwKungfuID, 1),
					rgb = {MY.GetForceColor(dwForceID, 'foreground')},
					bCheck = true,
					bChecked = mon.tarkungfus[dwKungfuID],
					fnAction = function()
						D.ModifyMonitor(mon, {'tarkungfus', dwKungfuID}, not mon.tarkungfus[dwKungfuID])
					end,
					fnDisable = function() return mon.tarkungfus.all or IsEmpty(mon.tarkungfus) end,
				})
			end
		end
		insert(t1, t2)
		-- 地图要求
		local t2 = MY.GetDungeonMenu(function(p)
			D.ModifyMonitor(mon, {'maps', p.dwID}, not mon.maps[p.dwID])
		end, false, mon.maps)
		for i, p in ipairs(t2) do
			p.fnDisable = function() return mon.maps.all or IsEmpty(mon.maps) end
		end
		t2.szOption = _L['Map filter']
		insert(t2, 1, {
			szOption = _L['All maps'],
			bCheck = true,
			bChecked = mon.maps.all or IsEmpty(mon.maps),
			fnAction = function(_, bChecked)
				D.ModifyMonitor(mon, 'maps.all', bChecked)
			end,
		})
		insert(t1, t2)
		-- 隐藏消失的
		insert(t1, {
			szOption = l_config.hideVoid and _L['Show even void'] or _L['Hide if void'],
			bCheck = true,
			bChecked = not mon.hideVoid,
			fnAction = function()
				D.ModifyMonitor(mon, 'hideVoid', not mon.hideVoid)
			end,
		})
		-- 出现声音
		local t2 = MY.GetSoundMenu(function(dwID, bCheck)
			if not bCheck then
				for i, v in ipairs_r(mon.soundAppear) do
					if v == dwID then
						remove(mon.soundAppear, i)
					end
				end
			else
				insert(mon.soundAppear, dwID)
			end
			D.ModifyMonitor(mon, 'soundAppear', mon.soundAppear)
		end, MY.ArrayToObject(mon.soundAppear), true)
		t2.szOption = _L['Play sound when appear']
		insert(t1, t2)
		-- 消失声音
		local t2 = MY.GetSoundMenu(function(dwID, bCheck)
			if not bCheck then
				for i, v in ipairs_r(mon.soundDisappear) do
					if v == dwID then
						remove(mon.soundDisappear, i)
					end
				end
			else
				insert(mon.soundDisappear, dwID)
			end
			D.ModifyMonitor(mon, 'soundDisappear', mon.soundDisappear)
		end, MY.ArrayToObject(mon.soundDisappear), true)
		t2.szOption = _L['Play sound when disappear']
		insert(t1, t2)
		-- 显示特效框
		local t2 = { szOption = _L['Active extent animate'] }
		for _, p in ipairs(CUSTOM_BOX_EXTENT_ANIMATE) do
			local t3 = {
				szOption = p[2] or p[1],
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
			if p[1] == mon.extentAnimate then
				t3.rgb = {255, 255, 0}
			end
			insert(t2, t3)
		end
		insert(t1, t2)
		-- ID设置
		if not empty(mon.ids) then
			insert(t1, { bDevide = true })
			insert(t1, { szOption = _L['Ids'], bDisable = true })
			insert(t1, {
				szOption = _L['All ids'],
				bCheck = true,
				bChecked = mon.ignoreId,
				fnAction = function()
					D.ModifyMonitor(mon, 'ignoreId', not mon.ignoreId)
				end,
				szIcon = 'fromiconid',
				nFrame = mon.iconid,
				nIconWidth = 22,
				nIconHeight = 22,
				szLayer = 'ICON_RIGHTMOST',
				fnClickIcon = function()
					UI.OpenIconPanel(function(dwIcon)
						mon.iconid = dwIcon
					end)
					Wnd.CloseWindow('PopupMenuPanel')
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
					nFrame = info.iconid,
					nIconWidth = 22,
					nIconHeight = 22,
					szLayer = 'ICON_RIGHTMOST',
					fnClickIcon = function()
						if mon.ignoreId then
							return
						end
						UI.OpenIconPanel(function(dwIcon)
							D.ModifyMonitorId(info, 'iconid', dwIcon)
						end)
						Wnd.CloseWindow('PopupMenuPanel')
					end,
				}
				if not empty(info.levels) then
					insert(t2, { szOption = _L['Levels'], bDisable = true })
					insert(t2, MENU_DIVIDER)
					insert(t2, {
						szOption = _L['All levels'],
						bCheck = true,
						bChecked = info.ignoreLevel,
						fnAction = function()
							D.ModifyMonitorId(info, 'ignoreLevel', not info.ignoreLevel)
						end,
						szIcon = 'fromiconid',
						nFrame = info.iconid,
						nIconWidth = 22,
						nIconHeight = 22,
						szLayer = 'ICON_RIGHTMOST',
						fnClickIcon = function()
							if mon.ignoreId or info.ignoreLevel then
								return
							end
							UI.OpenIconPanel(function(dwIcon)
								info.iconid = dwIcon
							end)
							Wnd.CloseWindow('PopupMenuPanel')
						end,
					})
					local tLevels = {}
					for nLevel, infoLevel in pairs(info.levels) do
						insert(tLevels, {
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
								nFrame = infoLevel.iconid,
								nIconWidth = 22,
								nIconHeight = 22,
								szLayer = 'ICON_RIGHTMOST',
								fnClickIcon = function()
									UI.OpenIconPanel(function(dwIcon)
										D.ModifyMonitorLevel(infoLevel, 'iconid', dwIcon)
									end)
									Wnd.CloseWindow('PopupMenuPanel')
								end,
							}
						})
					end
					sort(tLevels, function(a, b) return a[1] < b[1] end)
					for _, p in ipairs(tLevels) do
						insert(t2, p[2])
					end
					insert(t2, MENU_DIVIDER)
				end
				insert(t2, {
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
				insert(t2, {
					szOption = _L['Delete'],
					fnAction = function()
						D.DeleteMonitorId(mon, dwID)
					end,
				})
				insert(t1, t2)
			end
		end
		insert(t1, { bDevide = true })
		insert(t1, {
			szOption = _L['Auto capture by name'],
			bCheck = true, bChecked = mon.capture,
			fnAction = function()
				D.ModifyMonitor(mon, 'capture', not mon.capture)
			end,
		})
		insert(t1, {
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
							local dwLevel = GetClientPlayer().GetSkillLevel(dwID) or 1
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
	list:listbox('onmenu', onMenu)

	local function OpenDetail(config)
		l_config = config
		Search()
		uiWrapper:show()
		uiWrapper:bringToTop()
	end

	uiWrapper:append('WndButton2', {
		x = x0 + w0 / 2 - 50, y = y0 + h0 - 30,
		w = 100, h = 30, text = _L['Close'],
		onclick = function()
			l_config = nil
			uiWrapper:hide()
		end,
	})
	uiWrapper:hide()

	return OpenDetail
end

-- 绘制总览界面
local function DrawPreview(ui, config, OpenDetail)
	local X, Y = 10, 10
	local x, y = X, Y
	local w, h = ui:size()
	ui = ui:append('WndWindow', { w = w, h = 190 }, true)
	ui:append('Text', {
		x = x, y = y - 3, w = 20,
		r = 255, g = 255, b = 0,
		text = _L['*'],
	})
	ui:append('WndEditBox', {
		x = x + 20, y = y, w = w - 290, h = 22,
		r = 255, g = 255, b = 0, text = config.caption,
		onchange = function(val) D.ModifyConfig(config, 'caption', val) end,
	})
	ui:append('WndButton2', {
		x = w - 180, y = y,
		w = 50, h = 25,
		text = _L['Move Up'],
		onclick = function()
			D.MoveConfig(config, -1)
			MY.SwitchTab('MY_TargetMon', true)
		end,
	})
	ui:append('WndButton2', {
		x = w - 125, y = y,
		w = 50, h = 25,
		text = _L['Move Down'],
		onclick = function()
			D.MoveConfig(config, 1)
			MY.SwitchTab('MY_TargetMon', true)
		end,
	})
	ui:append('WndButton2', {
		x = w - 70, y = y,
		w = 60, h = 25,
		text = _L['Delete'],
		onclick = function()
			D.DeleteConfig(config)
			MY.SwitchTab('MY_TargetMon', true)
		end,
	})
	y = y + 30

	x = X + 20
	ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Enable'],
		checked = config.enable,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'enable', bChecked)
		end,
	})

	ui:append('WndCheckBox', {
		x = x + 90, y = y, w = 200,
		text = _L['Hide others buff'],
		tip = _L['Hide others buff TIP'],
		tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
		checked = config.hideOthers,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'hideOthers', bChecked)
		end,
		autoenable = function()
			return config.enable and config.type == 'BUFF'
		end,
	})

	ui:append('WndCheckBox', {
		x = x + 180, y = y, w = 180,
		text = _L['Hide void'],
		checked = config.hideVoid,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'hideVoid', bChecked)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	x = X + 20
	ui:append('WndCheckBox', {
		x = x, y = y, w = 90,
		text = _L['Penetrable'],
		checked = config.penetrable,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'penetrable', bChecked)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 90, y = y, w = 100,
		text = _L['Undragable'],
		checked = not config.dragable,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'dragable', not bChecked)
		end,
		autoenable = function() return config.enable and not config.penetrable end,
	})

	ui:append('WndCheckBox', {
		x = x + 180, y = y, w = 120,
		text = _L['Ignore system ui scale'],
		checked = config.ignoreSystemUIScale,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'ignoreSystemUIScale', bChecked)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	x = X + 20
	ui:append('WndCheckBox', {
		x = x, y = y, w = 200,
		text = _L['Show cd circle'],
		checked = config.cdCircle,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'cdCircle', bChecked)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 90, y = y, w = 200,
		text = _L['Show cd flash'],
		checked = config.cdFlash,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'cdFlash', bChecked)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 180, y = y, w = 200,
		text = _L['Show cd ready spark'],
		checked = config.cdReadySpark,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'cdReadySpark', bChecked)
		end,
		autoenable = function() return config.enable and not config.hideVoid end,
	})
	y = y + 30

	x = X + 20
	ui:append('WndCheckBox', {
		x = x, y = y, w = 120,
		text = _L['Show cd bar'],
		checked = config.cdBar,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'cdBar', bChecked)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 90, y = y, w = 120,
		text = _L['Show name'],
		checked = config.showName,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'showName', bChecked)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndCheckBox', {
		x = x + 180, y = y, w = 120,
		text = _L['Show time'],
		checked = config.showTime,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'showTime', bChecked)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	x = X + 20
	ui:append('WndCheckBox', {
		x = x, y = y, w = 90,
		text = _L['Play sound'],
		checked = config.playSound,
		oncheck = function(bChecked)
			D.ModifyConfig(config, 'playSound', bChecked)
		end,
		autoenable = function() return config.enable end,
	})

	ui:append('WndComboBox', {
		x = x + 90, y = y, w = (w - 250 - 30 - 30 - 80) / 2,
		text = _L['Icon style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, p in ipairs(CUSTOM_BOXBG_STYLES) do
				szIcon, nFrame = unpack(p[1]:split('|'))
				subt = {
					szOption = p[2] or p[1],
					fnAction = function()
						D.ModifyConfig(config, 'boxBgUITex', p[1])
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = 'ICON_RIGHTMOST',
				}
				if p[1] == config.boxBgUITex then
					subt.rgb = {255, 255, 0}
				end
				insert(t, subt)
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})
	ui:append('WndComboBox', {
		x = x + 90 + (w - 250 - 30 - 30 - 80) / 2, y = y, w = (w - 250 - 30 - 30 - 80) / 2,
		text = _L['Countdown style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CDBAR_STYLES) do
				szIcon, nFrame = unpack(text:split('|'))
				subt = {
					szOption = text,
					fnAction = function()
						D.ModifyConfig(config, 'cdBarUITex', text)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = 'ICON_FILL',
				}
				if text == config.cdBarUITex then
					subt.rgb = {255, 255, 0}
				end
				insert(t, subt)
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})
	y = y + 30

	y = Y + 30
	local deltaY = 24
	ui:append('WndComboBox', {
		x = w - 250, y = y, w = 135,
		text = _L['Set target'],
		menu = function()
			local t = {}
			for _, eType in ipairs(D.GetTargetTypeList()) do
				insert(t, {
					szOption = _L.TARGET[eType],
					bCheck = true, bMCheck = true,
					bChecked = eType == (config.type == 'SKILL' and 'CONTROL_PLAYER' or config.target),
					fnDisable = function()
						return config.type == 'SKILL' and eType ~= 'CONTROL_PLAYER'
					end,
					fnAction = function()
						config.target = eType
					end,
				})
			end
			insert(t, { bDevide = true })
			for _, eType in ipairs({'BUFF', 'SKILL'}) do
				insert(t, {
					szOption = _L.TYPE[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.type,
					fnAction = function()
						config.type = eType
					end,
				})
			end
			insert(t, { bDevide = true })
			for _, eType in ipairs({'LEFT', 'RIGHT', 'CENTER'}) do
				insert(t, {
					szOption = _L.ALIGNMENT[eType],
					bCheck = true, bMCheck = true, bChecked = eType == config.alignment,
					fnAction = function()
						config.alignment = eType
					end,
				})
			end
			return t
		end,
		autoenable = function() return config.enable end,
	})
	ui:append('WndButton2', {
		x = w - 110, y = y, w = 102,
		text = _L['Set monitor'],
		onclick = function() OpenDetail(config) end,
		autoenable = function() return config.enable end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textfmt = function(val) return _L('Display %d eachline.', val) end,
		onchange = function(val)
			D.ModifyConfig(config, 'maxLineCount', val)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textfmt = function(val) return _L('UI scale %d%%.', val) end,
		onchange = function(val)
			D.ModifyConfig(config, 'scale', val / 100)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {1, 300},
		value = config.fontScale * 100,
		textfmt = function(val) return _L('Font scale %d%%.', val) end,
		onchange = function(val)
			D.ModifyConfig(config, 'fontScale', val / 100)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {50, 1000},
		value = config.cdBarWidth,
		textfmt = function(val) return _L('CD width %dpx.', val) end,
		onchange = function(val)
			D.ModifyConfig(config, 'cdBarWidth', val)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = w - 250, y = y,
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		range = {-1, 30},
		value = config.decimalTime,
		textfmt = function(val)
			if val == -1 then
				return _L['Always show decimal time.']
			elseif val == 0 then
				return _L['Never show decimal time.']
			else
				return _L('Show decimal time left in %ds.', val)
			end
		end,
		onchange = function(val)
			D.ModifyConfig(config, 'decimalTime', val)
		end,
		autoenable = function() return config.enable end,
	})
	y = y + deltaY

	return x, y
end

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()
	local X, Y = 20, 20
	local x, y = X, Y
	ui:containerType(WND_CONTAINER_STYLE.WND_CONTAINER_STYLE_LEFT_TOP)

	local OpenDetail = DrawDetail(ui)
	for _, config in ipairs(D.GetConfig()) do
		DrawPreview(ui, config, OpenDetail)
	end

	local uiWnd = ui:append('WndWindow', { w = w, h = 80 }, true)
	x, y = (w - 380) / 2, 10
	uiWnd:append('WndButton2', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Create'],
		onclick = function()
			local config = D.CreateConfig()
			DrawPreview(ui, config, OpenDetail)
			MY.SwitchTab('MY_TargetMon', true)
		end,
	})
	x = x + 70
	uiWnd:append('WndButton2', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Import'],
		onclick = function()
			local file = GetOpenFileName(
				_L['Please select import target monitor data file.'],
				'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
				MY.FormatPath({ 'export/TargetMon', MY_DATA_PATH.GLOBAL })
			)
			if file == '' then
				return
			end
			local aPatch = MY.LoadLUAData(file)
			if not aPatch then
				return
			end
			local importCount, replaceCount = D.ImportPatches(aPatch)
			if importCount > 0 then
				MY.SwitchTab('MY_TargetMon', true)
			end
			MY.Sysmsg({ _L('Import successed, %d imported and %d replaced.', importCount, replaceCount) })
			OutputMessage('MSG_ANNOUNCE_YELLOW', _L('Import successed, %d imported and %d replaced.', importCount, replaceCount))
		end,
	})
	x = x + 70
	uiWnd:append('WndButton2', {
		x = x, y = y,
		w = 60, h = 30,
		text = _L['Export'],
		menu = function()
			local aUUID = {}
			local menu = {}
			local indent = IsCtrlKeyDown() and '\t' or nil
			for _, config in ipairs(D.GetConfig()) do
				insert(menu, {
					bCheck = true,
					szOption = config.caption,
					fnAction = function()
						for i, uuid in ipairs_r(aUUID) do
							if uuid == config.uuid then
								remove(aUUID, i)
								return
							end
						end
						insert(aUUID, config.uuid)
					end,
				})
			end
			if #menu > 0 then
				insert(menu, MENU_DIVIDER)
			end
			insert(menu, {
				szOption = _L['Ensure export'],
				fnAction = function()
					local file = MY.FormatPath({
						'export/TargetMon/$name@$server@'
							.. MY.FormatTime('yyyyMMddhhmmss')
							.. '.jx3dat',
						MY_DATA_PATH.GLOBAL,
					})
					local aPatch = D.ExportPatches(aUUID)
					MY.SaveLUAData(file, aPatch, indent)
					MY.Sysmsg({ _L('Data exported, file saved at %s.', file) })
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
	uiWnd:append('WndButton2', {
		x = x, y = y,
		w = 80, h = 30,
		text = _L['Save As Default'],
		onclick = function()
			MY.Confirm(_L['Sure to save as default?'], function()
				D.SaveConfig(true)
			end)
		end,
	})
	x = x + 90
	uiWnd:append('WndButton2', {
		x = x, y = y,
		w = 80, h = 30,
		text = _L['Reset Default'],
		onclick = function()
			MY.Dialog(_L['Sure to reset default?'], {
				{
					szOption = _L['Origin config'],
					fnAction = function()
						D.LoadConfig(true, true)
						MY.SwitchTab('MY_TargetMon', true)
					end,
				},
				{
					szOption = _L['Default config'],
					fnAction = function()
						D.LoadConfig(true, false)
						MY.SwitchTab('MY_TargetMon', true)
					end,
				},
				{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
			})
		end,
	})
	x = x + 90
end

function PS.OnPanelScroll(wnd, scrollX, scrollY)
	wnd:Lookup('WndWindow_Wrapper'):SetRelPos(scrollX, scrollY)
end
MY.RegisterPanel('MY_TargetMon', _L['Target monitor'], _L['Target'], 'ui/Image/ChannelsPanel/NewChannels.UITex|141', PS)
