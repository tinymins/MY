--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 扁平血条设置
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
local MY, UI = MY, MY.UI
local var2str, str2var, clone, empty, ipairs_r = MY.var2str, MY.str2var, MY.clone, MY.empty, MY.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = MY.spairs, MY.spairs_r, MY.sipairs, MY.sipairs_r
local GetPatch, ApplyPatch = MY.GetPatch, MY.ApplyPatch
local Get, Set, RandomChild, GetTraceback = MY.Get, MY.Set, MY.RandomChild, MY.GetTraceback
local IsArray, IsDictionary, IsEquals = MY.IsArray, MY.IsDictionary, MY.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = MY.MENU_DIVIDER, MY.EMPTY_TABLE, MY.XML_LINE_BREAKER
--------------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_LifeBar/lang/')
if not MY.AssertVersion('MY_LifeBar', _L['MY_LifeBar'], 0x2011800) then
	return
end

local Config = MY_LifeBar_Config
if not Config then
    return
end

local D = {
	Reset = MY_LifeBar.Reset,
	Repaint = MY_LifeBar.Repaint,
	IsEnabled = MY_LifeBar.IsEnabled,
	IsShielded = MY_LifeBar.IsShielded,
	UpdateShadowHandleParam = MY_LifeBar.UpdateShadowHandleParam,
}

local PS = {}
local function LoadUI(ui)
	ui:children('#WndSliderBox_GlobalUIScale'):value(Config.fGlobalUIScale * 100)
	ui:children('#WndSliderBox_LifeBarWidth'):value(Config.nLifeWidth)
	ui:children('#WndSliderBox_LifeBarHeight'):value(Config.nLifeHeight)
	ui:children('#WndSliderBox_LifeBarOffsetX'):value(Config.nLifeOffsetX)
	ui:children('#WndSliderBox_LifeBarOffsetY'):value(Config.nLifeOffsetY)
	ui:children('#WndSliderBox_LifeBarPadding'):value(Config.nLifePadding)
	ui:children('#WndSliderBox_LifeBarBorder'):value(Config.nLifeBorder)
	ui:children('#Shadow_LifeBarBorderRGB'):color(Config.nLifeBorderR, Config.nLifeBorderG, Config.nLifeBorderB)
	ui:children('#WndSliderBox_TextOffsetY'):value(Config.nTextOffsetY)
	ui:children('#WndSliderBox_TextLineHeight'):value(Config.nTextLineHeight)
	ui:children('#WndSliderBox_TextScale'):value(Config.fTextScale * 40)
	ui:children('#WndSliderBox_TextSpacing'):value(Config.fTextSpacing * 10)
	ui:children('#WndSliderBox_TitleEffectScale'):value(Config.fTitleEffectScale * 100)
	ui:children('#WndSliderBox_TitleEffectOffsetY'):value(Config.nTitleEffectOffsetY)
	ui:children('#WndSliderBox_LifePerOffsetX'):value(Config.nLifePerOffsetX)
	ui:children('#WndSliderBox_LifePerOffsetY'):value(Config.nLifePerOffsetY)
	ui:children('#WndSliderBox_Distance'):value(math.sqrt(Config.nDistance) / 64)
	ui:children('#WndSliderBox_VerticalDistance'):value(Config.nVerticalDistance / 8 / 64)
	ui:children('#WndSliderBox_Alpha'):value(Config.nAlpha)
	ui:children('#WndCheckBox_IgnoreUIScale'):check(not Config.bSystemUIScale)
	ui:children('#WndCheckBox_ShowWhenUIHide'):check(Config.bShowWhenUIHide)
	ui:children('#WndCheckBox_ShowObjectID'):check(Config.bShowObjectID)
	ui:children('#WndCheckBox_ShowObjectIDOnlyUnnamed'):check(Config.bShowObjectIDOnlyUnnamed)
	ui:children('#WndCheckBox_ShowSpecialNpc'):check(Config.bShowSpecialNpc)
	ui:children('#WndCheckBox_ShowSpecialNpcOnlyEnemy'):check(Config.bShowSpecialNpcOnlyEnemy)
	ui:children('#WndCheckBox_ShowKungfu'):check(Config.bShowKungfu)
	ui:children('#WndCheckBox_ShowDistance'):check(Config.bShowDistance)
	ui:children('#WndCheckBox_ScreenPosSort'):check(Config.bScreenPosSort)
	ui:children('#WndCheckBox_MineOnTop'):check(Config.bMineOnTop)
end
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:size()

	local X, Y = 10, 15
	local x, y = X, Y
	local offsety = 45
	-- 开启
	ui:append('WndCheckBox', {
		x = x, y = y, text = _L['Enable'],
		checked = MY_LifeBar.bEnabled,
		oncheck = function(bChecked)
			MY_LifeBar.bEnabled = bChecked
			D.Reset(true)
		end,
		tip = function()
			if D.IsShielded() then
				return _L['Can not use in shielded map!']
			end
		end,
		autoenable = function() return not D.IsShielded() end,
	})
	x = x + 80
	-- 配置文件名称
	ui:append('WndEditBox', {
		x = x, y = y, w = 200, h = 25,
		placeholder = _L['Configure name'],
		text = MY_LifeBar.szConfig,
		onblur = function()
			local szConfig = UI(this):text():gsub('%s', '')
			if szConfig == '' then
				return
			end
			Config('load', szConfig)
			LoadUI(ui)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 235
	ui:append('Text', {
		x = x + 3, y = y - 16,
		text = _L['only enable in those maps below'],
		autoenable = function() return D.IsEnabled() end,
	})
	ui:append('WndCheckBox', {
		x = x, y = y + 9, w = 80, text = _L['arena'],
		checked = Config.bOnlyInArena,
		oncheck = function(bChecked)
			Config.bOnlyInArena = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 80
	ui:append('WndCheckBox', {
		x = x, y = y + 9, w = 70, text = _L['battlefield'],
		checked = Config.bOnlyInBattleField,
		oncheck = function(bChecked)
			Config.bOnlyInBattleField = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 70
	ui:append('WndCheckBox', {
		x = x, y = y + 9, w = 70, text = _L['dungeon'],
		checked = Config.bOnlyInDungeon,
		oncheck = function(bChecked)
			Config.bOnlyInDungeon = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety
	-- <hr />
	ui:append('Image', 'Image_Spliter'):find('#Image_Spliter'):pos(10, y-7):size(w - 20, 1):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)

	X, Y = 15, 60
	x, y = X, Y
	offsety = 20

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifeBarWidth',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 5, 150 },
		text = function(value) return _L('lifebar width: %s px.', value) end, -- 血条宽度
		value = Config.nLifeWidth,
		onchange = function(value)
			Config.nLifeWidth = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifeBarHeight',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 1, 150 },
		text = function(value) return _L('lifebar height: %s px.', value) end, -- 血条高度
		value = Config.nLifeHeight,
		onchange = function(value)
			Config.nLifeHeight = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifeBarOffsetX',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L('lifebar offset-x: %d px.', value) end, -- 血条水平偏移
		value = Config.nLifeOffsetX,
		onchange = function(value)
			Config.nLifeOffsetX = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifeBarOffsetY',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('lifebar offset-y: %d px.', value) end, -- 血条竖直偏移
		value = Config.nLifeOffsetY,
		onchange = function(value)
			Config.nLifeOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifeBarPadding',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 10 },
		text = function(value) return _L('lifebar padding: %d px.', value) end, -- 血条边框宽度
		value = Config.nLifePadding,
		onchange = function(value)
			Config.nLifePadding = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifeBarBorder',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 10 },
		text = function(value) return _L('lifebar border: %d px.', value) end, -- 血条边框宽度
		value = Config.nLifeBorder,
		onchange = function(value)
			Config.nLifeBorder = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifePerOffsetX',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L('life percentage offset-x: %d px.', value) end, -- 血量百分比水平偏移
		value = Config.nLifePerOffsetX,
		onchange = function(value)
			Config.nLifePerOffsetX = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_LifePerOffsetY',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('life percentage offset-y: %d px.', value) end, -- 血量百分比竖直偏移
		value = Config.nLifePerOffsetY,
		onchange = function(value)
			Config.nLifePerOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_TextOffsetY',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('text offset-y: %d px.', value) end, -- 第一行字高度
		value = Config.nTextOffsetY,
		onchange = function(value)
			Config.nTextOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_TextLineHeight',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('text line height: %d px.', value) end, -- 字行高度
		value = Config.nTextLineHeight,
		onchange = function(value)
			Config.nTextLineHeight = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_TextScale',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 200 },
		text = function(value) return _L('text scale: %.1f%%.', value / 40 * 100) end, -- 字缩放
		value = Config.fTextScale * 40,
		onchange = function(value)
			Config.fTextScale = value / 40
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_TextSpacing',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return _L('text spacing: %.1f.', value / 10) end, -- 字间距
		value = Config.fTextSpacing * 10,
		onchange = function(value)
			Config.fTextSpacing = value / 10
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_TitleEffectScale',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 200 },
		text = function(value) return _L('Title effect scale: %.2f%%.', value / 100) end, -- 头顶特效缩放
		value = Config.fTitleEffectScale * 100,
		onchange = function(value)
			Config.fTitleEffectScale = value / 100
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_TitleEffectOffsetY',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L('Title effect offset y: %d px.', value) end, -- 头顶特效间距
		value = Config.nTitleEffectOffsetY,
		onchange = function(value)
			Config.nTitleEffectOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_Distance',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return value == 0 and _L['Max Distance: Unlimited.'] or _L('Max Distance: %s foot.', value) end,
		value = math.sqrt(Config.nDistance) / 64,
		onchange = function(value)
			Config.nDistance = value * value * 64 * 64
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_VerticalDistance',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return value == 0 and _L['Max Vertical Distance: Unlimited.'] or _L('Max Vertical Distance: %s foot.', value) end,
		value = Config.nVerticalDistance / 8 / 64,
		onchange = function(value)
			Config.nVerticalDistance = value * 8 * 64
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_Alpha',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_PERCENT, range = { 0, 255 },
		text = function(value) return _L('alpha: %.0f%%.', value) end, -- 透明度
		value = Config.nAlpha,
		onchange = function(value)
			Config.nAlpha = value * 255 / 100
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append('WndSliderBox', {
		name = 'WndSliderBox_GlobalUIScale',
		x = x, y = y, sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE, range = { 1, 200 },
		text = function(value) return _L('Global UI scale: %.2f.', value / 100) end, -- 字缩放
		value = Config.fGlobalUIScale * 100,
		onchange = function(value)
			Config.fGlobalUIScale = value / 100
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 右半边
	X, Y = 350, 65
	x, y = X, Y
	offsety = 27
	local function FillColorTable(opt, relation, tartype)
		local cfg = Config.Color[relation]
		opt.rgb = cfg[tartype]
		opt.szIcon = 'ui/Image/button/CommonButton_1.UITex'
		opt.nFrame = 69
		opt.nMouseOverFrame = 70
		opt.szLayer = 'ICON_RIGHT'
		opt.fnClickIcon = function()
			UI.OpenColorPicker(function(r, g, b)
				cfg[tartype] = { r, g, b }
			end)
		end
		if tartype == 'Player' then
			table.insert(opt, {
				szOption = _L['Unified force color'],
				bCheck = true, bMCheck = true,
				bChecked = not cfg.DifferentiateForce,
				fnAction = function(_, r, g, b)
					cfg.DifferentiateForce = false
				end,
				rgb = cfg[tartype],
				szIcon = 'ui/Image/button/CommonButton_1.UITex',
				nFrame = 69, nMouseOverFrame = 70,
				szLayer = 'ICON_RIGHT',
				fnClickIcon = function()
					UI.OpenColorPicker(function(r, g, b)
						cfg[tartype] = { r, g, b }
					end)
				end,
			})
			table.insert(opt, {
				szOption = _L['Differentiate force color'],
				bCheck = true, bMCheck = true,
				bChecked = cfg.DifferentiateForce,
				fnAction = function(_, r, g, b)
					cfg.DifferentiateForce = true
				end,
			})
			table.insert(opt,{ bDevide = true } )
			for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
				table.insert(opt, {
					szOption = szForceTitle,
					rgb = cfg[dwForceID],
					szIcon = 'ui/Image/button/CommonButton_1.UITex',
					nFrame = 69, nMouseOverFrame = 70,
					szLayer = 'ICON_RIGHT',
					fnClickIcon = function()
						UI.OpenColorPicker(function(r, g, b)
							cfg[dwForceID] = { r, g, b }
						end)
					end,
					fnDisable = function()
						return not cfg.DifferentiateForce
					end,
				})
			end
		end
		return opt
	end
	local function GeneBooleanPopupMenu(cfgs, szPlayerTip, szNpcTip)
		local t = {}
		if szPlayerTip then
			table.insert(t, { szOption = szPlayerTip, bDisable = true } )
			for relation, cfg in pairs(cfgs) do
				if cfg.Player ~= nil then
					table.insert(t, FillColorTable({
						szOption = _L[relation],
						bCheck = true,
						bChecked = cfg.Player,
						fnAction = function()
							cfg.Player = not cfg.Player
							D.Reset()
						end,
					}, relation, 'Player'))
				end
			end
		end
		if szPlayerTip and szNpcTip then
			table.insert(t,{ bDevide = true } )
		end
		if szNpcTip then
			table.insert(t,{ szOption = szNpcTip, bDisable = true } )
			for relation, cfg in pairs(cfgs) do
				if cfg.Npc ~= nil then
					table.insert(t, FillColorTable({
						szOption = _L[relation],
						bCheck = true,
						bChecked = cfg.Npc,
						fnAction = function()
							cfg.Npc = not cfg.Npc
							D.Reset()
						end,
					}, relation, 'Npc'))
				end
			end
		end
		return t
	end
	-- 显示名字
	ui:append('WndComboBox', {
		x = x, y = y, text = _L['name display config'],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowName, _L['player name display'], _L['npc name display'])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 称号
	ui:append('WndComboBox', {
		x = x, y = y, text = _L['title display config'],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowTitle, _L['player title display'], _L['npc title display'])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 帮会
	ui:append('WndComboBox', {
		x = x, y = y, text = _L['tong display config'],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowTong, _L['player tong display'])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 血条设置
	ui:append('WndComboBox', {
		x = x, y = y, text = _L['lifebar display config'],
		menu = function()
			local t = GeneBooleanPopupMenu(Config.ShowLife, _L['player lifebar display'], _L['npc lifebar display'])
			table.insert(t, { bDevide = true })
			local t1 = {
				szOption = _L['Draw direction'],
			}
			for _, szDirection in ipairs({ 'LEFT_RIGHT', 'RIGHT_LEFT', 'TOP_BOTTOM', 'BOTTOM_TOP' }) do
				table.insert(t1, {
					szOption = _L.DIRECTION[szDirection],
					bCheck = true, bMCheck = true,
					bChecked = Config.szLifeDirection == szDirection,
					fnAction = function()
						Config.szLifeDirection = szDirection
					end,
				})
			end
			table.insert(t, t1)
			return t
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 显示血量%
	ui:append('WndComboBox', {
		x = x, y = y, text = _L['lifepercentage display config'],
		menu = function()
			local t = GeneBooleanPopupMenu(Config.ShowLifePer, _L['player lifepercentage display'], _L['npc lifepercentage display'])
			table.insert(t, { bDevide = true })
			table.insert(t, {
				szOption = _L['hide when unfight'],
				bCheck = true,
				bChecked = Config.bHideLifePercentageWhenFight,
				fnAction = function()
					Config.bHideLifePercentageWhenFight = not Config.bHideLifePercentageWhenFight
				end,
			})
			table.insert(t, {
				szOption = _L['hide decimal'],
				bCheck = true,
				bChecked = Config.bHideLifePercentageDecimal,
				fnAction = function()
					Config.bHideLifePercentageDecimal = not Config.bHideLifePercentageDecimal
				end,
			})
			return t
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 当前阵营
	ui:append('WndComboBox', {
		x = x, y = y, text = _L['set current camp'],
		menu = function()
			return {{
				szOption = _L['auto detect'],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == -1,
				fnAction = function()
					Config.nCamp = -1
				end,
			}, {
				szOption = g_tStrings.STR_CAMP_TITLE[CAMP.GOOD],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == CAMP.GOOD,
				fnAction = function()
					Config.nCamp = CAMP.GOOD
				end,
			}, {
				szOption = g_tStrings.STR_CAMP_TITLE[CAMP.EVIL],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == CAMP.EVIL,
				fnAction = function()
					Config.nCamp = CAMP.EVIL
				end,
			}, {
				szOption = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == CAMP.NEUTRAL,
				fnAction = function()
					Config.nCamp = CAMP.NEUTRAL
				end,
			}}
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety
	offsety = 31

	ui:append('Shadow', {
		name = 'Shadow_LifeBarBorderRGB', -- 血条边框颜色
		x = x + 4, y = y + 6,
		r = Config.nLifeBorderR,
		g = Config.nLifeBorderG,
		b = Config.nLifeBorderB,
		onclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				Config.nLifeBorderR = r
				Config.nLifeBorderG = g
				Config.nLifeBorderB = b
				UI(this):color(r, g, b)
			end)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	ui:append('Text', { text = _L['lifebar border color'], x = x + 27, y = y - 2 })

	x = X
	y = y + offsety - 10
	x = x + ui:append('WndCheckBox', {
		name = 'WndCheckBox_IgnoreUIScale',
		x = x, y = y, text = _L['Ignore ui scale'],
		checked = not Config.bSystemUIScale,
		oncheck = function(bChecked)
			Config.bSystemUIScale = not bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	}, true):autoWidth():width()

	x = X
	y = y + offsety - 10
	x = x + ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowWhenUIHide',
		x = x, y = y, text = _L['Show when ui hide'],
		checked = Config.bShowWhenUIHide,
		oncheck = function(bChecked)
			Config.bShowWhenUIHide = bChecked
			D.UpdateShadowHandleParam()
		end,
		autoenable = function() return D.IsEnabled() end,
	}, true):autoWidth():width()

	x = X
	y = y + offsety - 10
	x = x + ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowObjectID',
		x = x, y = y, text = _L['Show object id'],
		checked = Config.bShowObjectID,
		oncheck = function(bChecked)
			Config.bShowObjectID = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	}, true):autoWidth():width()

	x = x + ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowObjectIDOnlyUnnamed',
		x = x, y = y, text = _L['Only unnamed'],
		checked = Config.bShowObjectIDOnlyUnnamed,
		oncheck = function(bChecked)
			Config.bShowObjectIDOnlyUnnamed = bChecked
		end,
		autoenable = function() return D.IsEnabled() and Config.bShowObjectID end,
	}, true):autoWidth():width()

	x = X
	y = y + offsety - 10
	x = x + ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowSpecialNpc',
		x = x, y = y, text = _L['show special npc'],
		checked = Config.bShowSpecialNpc,
		oncheck = function(bChecked)
			Config.bShowSpecialNpc = bChecked
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	}, true):autoWidth():width() + 5
	ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowSpecialNpcOnlyEnemy',
		x = x, y = y, w = 'auto',
		text = _L['only enemy'],
		checked = Config.bShowSpecialNpcOnlyEnemy,
		oncheck = function(bChecked)
			Config.bShowSpecialNpcOnlyEnemy = bChecked
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() and Config.bShowSpecialNpc end,
	})

	x = X
	y = y + offsety - 10
	ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowKungfu',
		x = x, y = y, w = 'auto',
		text = _L['show kungfu'],
		checked = Config.bShowKungfu,
		oncheck = function(bChecked)
			Config.bShowKungfu = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	ui:append('WndCheckBox', {
		name = 'WndCheckBox_ShowDistance',
		x = x + 90, y = y, w = 'auto',
		text = _L['show distance'],
		checked = Config.bShowDistance,
		oncheck = function(bChecked)
			Config.bShowDistance = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	y = y + offsety - 10
	ui:append('WndCheckBox', {
		name = 'WndCheckBox_ScreenPosSort',
		x = x, y = y, w = 'auto',
		text = _L['Sort by screen pos'],
		checked = Config.bScreenPosSort,
		oncheck = function(bChecked)
			Config.bScreenPosSort = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	y = y + offsety - 10
	ui:append('WndCheckBox', {
		name = 'WndCheckBox_MineOnTop',
		x = x, y = y, w = 'auto',
		text = _L['Self always on top'],
		checked = Config.bMineOnTop,
		oncheck = function(bChecked)
			Config.bMineOnTop = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	y = y + offsety
	ui:append('WndButton', {
		x = x, y = y, w = 65,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				Config.nFont = nFont
			end)
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	ui:append('WndButton', {
		x = x + 65, y = y, w = 120, text = _L['reset config'],
		onclick = function()
			Config('reset')
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	local function onReset()
		LoadUI(ui)
	end
	MY.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED.MY_LifeBarPS', onReset)
	MY.RegisterEvent('MY_LIFEBAR_CONFIG_UPDATE.MY_LifeBarPS', onReset)
end

function PS.OnPanelDeactive()
	MY.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED.MY_LifeBarPS')
	MY.RegisterEvent('MY_LIFEBAR_CONFIG_UPDATE.MY_LifeBarPS')
end
MY.RegisterPanel('MY_LifeBar', _L['MY_LifeBar'], _L['General'], 'UI/Image/LootPanel/LootPanel.UITex|74', PS)
