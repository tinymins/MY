--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 扁平血条设置
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
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

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
	ui:Children('#WndTrackbar_GlobalUIScale'):Value(Config.fGlobalUIScale * 100 * LIB.GetUIScale())
	ui:Children('#WndTrackbar_LifeBarWidth'):Value(Config.nLifeWidth)
	ui:Children('#WndTrackbar_LifeBarHeight'):Value(Config.nLifeHeight)
	ui:Children('#WndTrackbar_LifeBarOffsetX'):Value(Config.nLifeOffsetX)
	ui:Children('#WndTrackbar_LifeBarOffsetY'):Value(Config.nLifeOffsetY)
	ui:Children('#WndTrackbar_LifeBarPadding'):Value(Config.nLifePadding)
	ui:Children('#WndTrackbar_LifeBarBorder'):Value(Config.nLifeBorder)
	ui:Children('#Shadow_LifeBarBorderRGB'):Color(Config.nLifeBorderR, Config.nLifeBorderG, Config.nLifeBorderB)
	ui:Children('#WndTrackbar_TextOffsetY'):Value(Config.nTextOffsetY)
	ui:Children('#WndTrackbar_TextLineHeight'):Value(Config.nTextLineHeight)
	ui:Children('#WndTrackbar_TextScale'):Value(Config.fTextScale * 40)
	ui:Children('#WndTrackbar_TextSpacing'):Value(Config.fTextSpacing * 10)
	ui:Children('#WndTrackbar_TitleEffectScale'):Value(Config.fTitleEffectScale * 100)
	ui:Children('#WndTrackbar_TitleEffectOffsetY'):Value(Config.nTitleEffectOffsetY)
	ui:Children('#WndTrackbar_LifePerOffsetX'):Value(Config.nLifePerOffsetX)
	ui:Children('#WndTrackbar_LifePerOffsetY'):Value(Config.nLifePerOffsetY)
	ui:Children('#WndTrackbar_Distance'):Value(sqrt(Config.nDistance) / 64)
	ui:Children('#WndTrackbar_VerticalDistance'):Value(Config.nVerticalDistance / 8 / 64)
	ui:Children('#WndTrackbar_Alpha'):Value(Config.nAlpha)
	ui:Children('#WndCheckBox_IgnoreUIScale'):Check(not Config.bSystemUIScale)
	ui:Children('#WndCheckBox_ShowWhenUIHide'):Check(Config.bShowWhenUIHide)
	ui:Children('#WndCheckBox_ShowObjectID'):Check(Config.bShowObjectID)
	ui:Children('#WndCheckBox_ShowObjectIDOnlyUnnamed'):Check(Config.bShowObjectIDOnlyUnnamed)
	ui:Children('#WndCheckBox_ShowSpecialNpc'):Check(Config.bShowSpecialNpc)
	ui:Children('#WndCheckBox_ShowSpecialNpcOnlyEnemy'):Check(Config.bShowSpecialNpcOnlyEnemy)
	ui:Children('#WndCheckBox_ShowKungfu'):Check(Config.bShowKungfu)
	ui:Children('#WndCheckBox_ShowDistance'):Check(Config.bShowDistance)
	ui:Children('#WndCheckBox_ScreenPosSort'):Check(Config.bScreenPosSort)
	ui:Children('#WndCheckBox_MineOnTop'):Check(Config.bMineOnTop)
end
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()

	local X, Y = 10, 15
	local x, y = X, Y
	local offsety = 45
	-- 开启
	ui:Append('WndCheckBox', {
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
	ui:Append('WndEditBox', {
		x = x, y = y, w = 200, h = 25,
		placeholder = _L['Configure name'],
		text = MY_LifeBar.szConfig,
		onblur = function()
			local szConfig = UI(this):Text():gsub('%s', '')
			if szConfig == '' then
				return
			end
			Config('load', szConfig)
			LoadUI(ui)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 235
	ui:Append('Text', {
		x = x + 3, y = y - 16,
		text = _L['Only enable in those maps below'],
		autoenable = function() return D.IsEnabled() end,
	})
	ui:Append('WndCheckBox', {
		x = x, y = y + 9, w = 80, text = _L['Arena'],
		checked = Config.bOnlyInArena,
		oncheck = function(bChecked)
			Config.bOnlyInArena = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 80
	ui:Append('WndCheckBox', {
		x = x, y = y + 9, w = 70, text = _L['Battlefield'],
		checked = Config.bOnlyInBattleField,
		oncheck = function(bChecked)
			Config.bOnlyInBattleField = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 70
	ui:Append('WndCheckBox', {
		x = x, y = y + 9, w = 70, text = _L['Dungeon'],
		checked = Config.bOnlyInDungeon,
		oncheck = function(bChecked)
			Config.bOnlyInDungeon = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety
	-- <hr />
	ui:Append('Image', 'Image_Spliter'):Pos(10, y-7):Size(w - 20, 1):Image('UI/Image/UICommon/ScienceTreeNode.UITex',62)

	X, Y = 15, 60
	x, y = X, Y
	offsety = 20

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifeBarWidth',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 5, 150 },
		text = function(value) return _L('Lifebar width: %s px.', value) end, -- 血条宽度
		value = Config.nLifeWidth,
		onchange = function(value)
			Config.nLifeWidth = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifeBarHeight',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 1, 150 },
		text = function(value) return _L('Lifebar height: %s px.', value) end, -- 血条高度
		value = Config.nLifeHeight,
		onchange = function(value)
			Config.nLifeHeight = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifeBarOffsetX',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L('Lifebar offset-x: %d px.', value) end, -- 血条水平偏移
		value = Config.nLifeOffsetX,
		onchange = function(value)
			Config.nLifeOffsetX = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifeBarOffsetY',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('Lifebar offset-y: %d px.', value) end, -- 血条竖直偏移
		value = Config.nLifeOffsetY,
		onchange = function(value)
			Config.nLifeOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifeBarPadding',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 10 },
		text = function(value) return _L('Lifebar padding: %d px.', value) end, -- 血条边框宽度
		value = Config.nLifePadding,
		onchange = function(value)
			Config.nLifePadding = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifeBarBorder',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 10 },
		text = function(value) return _L('Lifebar border: %d px.', value) end, -- 血条边框宽度
		value = Config.nLifeBorder,
		onchange = function(value)
			Config.nLifeBorder = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifePerOffsetX',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L('Life percentage offset-x: %d px.', value) end, -- 血量百分比水平偏移
		value = Config.nLifePerOffsetX,
		onchange = function(value)
			Config.nLifePerOffsetX = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_LifePerOffsetY',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('Life percentage offset-y: %d px.', value) end, -- 血量百分比竖直偏移
		value = Config.nLifePerOffsetY,
		onchange = function(value)
			Config.nLifePerOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_TextOffsetY',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('Text offset-y: %d px.', value) end, -- 第一行字高度
		value = Config.nTextOffsetY,
		onchange = function(value)
			Config.nTextOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_TextLineHeight',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L('Text line height: %d px.', value) end, -- 字行高度
		value = Config.nTextLineHeight,
		onchange = function(value)
			Config.nTextLineHeight = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_TextScale',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 200 },
		text = function(value) return _L('Text scale: %.1f%%.', value / 40 * 100) end, -- 字缩放
		value = Config.fTextScale * 40,
		onchange = function(value)
			Config.fTextScale = value / 40
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_TextSpacing',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return _L('Text spacing: %.1f.', value / 10) end, -- 字间距
		value = Config.fTextSpacing * 10,
		onchange = function(value)
			Config.fTextSpacing = value / 10
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_TitleEffectScale',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 200 },
		text = function(value) return _L('Title effect scale: %.2f%%.', value / 100) end, -- 头顶特效缩放
		value = Config.fTitleEffectScale * 100,
		onchange = function(value)
			Config.fTitleEffectScale = value / 100
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_TitleEffectOffsetY',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L('Title effect offset y: %d px.', value) end, -- 头顶特效间距
		value = Config.nTitleEffectOffsetY,
		onchange = function(value)
			Config.nTitleEffectOffsetY = value
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_Distance',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return value == 0 and _L['Max Distance: Unlimited.'] or _L('Max Distance: %s foot.', value) end,
		value = sqrt(Config.nDistance) / 64,
		onchange = function(value)
			Config.nDistance = value * value * 64 * 64
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_VerticalDistance',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return value == 0 and _L['Max Vertical Distance: Unlimited.'] or _L('Max Vertical Distance: %s foot.', value) end,
		value = Config.nVerticalDistance / 8 / 64,
		onchange = function(value)
			Config.nVerticalDistance = value * 8 * 64
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_Alpha',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_PERCENT, range = { 0, 255 },
		text = function(value) return _L('Alpha: %.0f%%.', value) end, -- 透明度
		value = Config.nAlpha,
		onchange = function(value)
			Config.nAlpha = value * 255 / 100
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:Append('WndTrackbar', {
		name = 'WndTrackbar_GlobalUIScale',
		x = x, y = y, trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = { 1, 200 },
		text = function(value) return _L('Global UI scale: %.2f.', value / 100) end, -- 字缩放
		value = Config.fGlobalUIScale * 100 * LIB.GetUIScale(),
		onchange = function(value)
			Config.fGlobalUIScale = value / 100 / LIB.GetUIScale()
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
			insert(opt, {
				szOption = _L['Unified force color'],
				bCheck = true, bMCheck = true,
				bChecked = not cfg.DifferentiateForce,
				fnAction = function(_, r, g, b)
					cfg.DifferentiateForce = false
				end,
				rgb = cfg[tartype],
				fnChangeColor = function(_, r, g, b)
					cfg[tartype] = {r, g, b}
					opt.rgb = cfg[tartype]
				end,
			})
			insert(opt, {
				szOption = _L['Differentiate force color'],
				bCheck = true, bMCheck = true,
				bChecked = cfg.DifferentiateForce,
				fnAction = function(_, r, g, b)
					cfg.DifferentiateForce = true
				end,
			})
			insert(opt,{ bDevide = true } )
			for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
				insert(opt, {
					szOption = szForceTitle,
					rgb = cfg[dwForceID],
					fnChangeColor = function(_, r, g, b)
						cfg[dwForceID] = { r, g, b }
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
			insert(t, { szOption = szPlayerTip, bDisable = true } )
			for relation, cfg in pairs(cfgs) do
				if cfg.Player then
					insert(t, FillColorTable({
						szOption = _L[relation],
						bCheck = true,
						bChecked = cfg.Player.bEnable,
						fnAction = function()
							cfg.Player.bEnable = not cfg.Player.bEnable
							D.Reset()
						end,
						{
							szOption = _L['Hide when unfight'],
							bCheck = true,
							bChecked = cfg.Player.bOnlyFighting,
							fnAction = function()
								cfg.Player.bOnlyFighting = not cfg.Player.bOnlyFighting
							end,
						},
					}, relation, 'Player'))
				end
			end
		end
		if szPlayerTip and szNpcTip then
			insert(t,{ bDevide = true } )
		end
		if szNpcTip then
			insert(t,{ szOption = szNpcTip, bDisable = true } )
			for relation, cfg in pairs(cfgs) do
				if cfg.Npc then
					insert(t, FillColorTable({
						szOption = _L[relation],
						bCheck = true,
						bChecked = cfg.Npc.bEnable,
						fnAction = function()
							cfg.Npc.bEnable = not cfg.Npc.bEnable
							D.Reset()
						end,
						{
							szOption = _L['Hide when unfight'],
							bCheck = true,
							bChecked = cfg.Npc.bOnlyFighting,
							fnAction = function()
								cfg.Npc.bOnlyFighting = not cfg.Npc.bOnlyFighting
							end,
						},
						{
							szOption = _L['Hide pets'],
							bCheck = true,
							bChecked = cfg.Npc.bHidePets,
							fnAction = function()
								cfg.Npc.bHidePets = not cfg.Npc.bHidePets
							end,
						},
					}, relation, 'Npc'))
				end
			end
		end
		return t
	end
	-- 显示名字
	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Name display config'],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowName, _L['Player name display'], _L['Npc name display'])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 称号
	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Title display config'],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowTitle, _L['Player title display'], _L['Npc title display'])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 帮会
	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Tong display config'],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowTong, _L['Player tong display'])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 血条设置
	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Lifebar display config'],
		menu = function()
			local t = GeneBooleanPopupMenu(Config.ShowLife, _L['Player lifebar display'], _L['Npc lifebar display'])
			insert(t, { bDevide = true })
			local t1 = {
				szOption = _L['Draw direction'],
			}
			for _, szDirection in ipairs({ 'LEFT_RIGHT', 'RIGHT_LEFT', 'TOP_BOTTOM', 'BOTTOM_TOP' }) do
				insert(t1, {
					szOption = _L.DIRECTION[szDirection],
					bCheck = true, bMCheck = true,
					bChecked = Config.szLifeDirection == szDirection,
					fnAction = function()
						Config.szLifeDirection = szDirection
					end,
				})
			end
			insert(t, t1)
			return t
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- 显示血量%
	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Lifepercentage display config'],
		menu = function()
			local t = GeneBooleanPopupMenu(Config.ShowLifePer, _L['Player lifepercentage display'], _L['Npc lifepercentage display'])
			insert(t, { bDevide = true })
			insert(t, {
				szOption = _L['Hide decimal'],
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
	ui:Append('WndComboBox', {
		x = x, y = y, text = _L['Set current camp'],
		menu = function()
			return {{
				szOption = _L['Auto detect'],
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

	ui:Append('Shadow', {
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
				UI(this):Color(r, g, b)
			end)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	ui:Append('Text', { text = _L['Lifebar border color'], x = x + 27, y = y - 2 })

	x = X
	y = y + offsety - 10
	x = x + ui:Append('WndCheckBox', {
		name = 'WndCheckBox_IgnoreUIScale',
		x = x, y = y, text = _L['Ignore ui scale'],
		checked = not Config.bSystemUIScale,
		oncheck = function(bChecked)
			Config.bSystemUIScale = not bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	}):AutoWidth():Width()

	x = X
	y = y + offsety - 10
	x = x + ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowWhenUIHide',
		x = x, y = y, text = _L['Show when ui hide'],
		checked = Config.bShowWhenUIHide,
		oncheck = function(bChecked)
			Config.bShowWhenUIHide = bChecked
			D.UpdateShadowHandleParam()
		end,
		autoenable = function() return D.IsEnabled() end,
	}):AutoWidth():Width()

	x = X
	y = y + offsety - 10
	x = x + ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowObjectID',
		x = x, y = y, text = _L['Show object id'],
		checked = Config.bShowObjectID,
		oncheck = function(bChecked)
			Config.bShowObjectID = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	}):AutoWidth():Width()

	x = x + ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowObjectIDOnlyUnnamed',
		x = x, y = y, text = _L['Only unnamed'],
		checked = Config.bShowObjectIDOnlyUnnamed,
		oncheck = function(bChecked)
			Config.bShowObjectIDOnlyUnnamed = bChecked
		end,
		autoenable = function() return D.IsEnabled() and Config.bShowObjectID end,
	}):AutoWidth():Width()

	x = X
	y = y + offsety - 10
	x = x + ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowSpecialNpc',
		x = x, y = y, text = _L['Show special npc'],
		checked = Config.bShowSpecialNpc,
		oncheck = function(bChecked)
			Config.bShowSpecialNpc = bChecked
			D.Reset()
		end,
		tip = _L['This function has been shielded by official except in dungeon'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function() return D.IsEnabled() end,
	}):AutoWidth():Width() + 5
	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowSpecialNpcOnlyEnemy',
		x = x, y = y, w = 'auto',
		text = _L['Only enemy'],
		checked = Config.bShowSpecialNpcOnlyEnemy,
		oncheck = function(bChecked)
			Config.bShowSpecialNpcOnlyEnemy = bChecked
			D.Reset()
		end,
		tip = _L['This function has been shielded by official except in dungeon'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function() return D.IsEnabled() and Config.bShowSpecialNpc end,
	})

	x = X
	y = y + offsety - 10
	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowKungfu',
		x = x, y = y, w = 'auto',
		text = _L['Show kungfu'],
		checked = Config.bShowKungfu,
		oncheck = function(bChecked)
			Config.bShowKungfu = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_ShowDistance',
		x = x + 90, y = y, w = 'auto',
		text = _L['Show distance'],
		checked = Config.bShowDistance,
		oncheck = function(bChecked)
			Config.bShowDistance = bChecked
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	y = y + offsety - 10
	ui:Append('WndCheckBox', {
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
	ui:Append('WndCheckBox', {
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
	ui:Append('WndButton', {
		x = x, y = y, w = 65,
		text = _L['Font'],
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				Config.nFont = nFont
			end)
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	ui:Append('WndButton', {
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
	LIB.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED.MY_LifeBarPS', onReset)
	LIB.RegisterEvent('MY_LIFEBAR_CONFIG_UPDATE.MY_LifeBarPS', onReset)
end

function PS.OnPanelDeactive()
	LIB.RegisterEvent('MY_LIFEBAR_CONFIG_LOADED.MY_LifeBarPS')
	LIB.RegisterEvent('MY_LIFEBAR_CONFIG_UPDATE.MY_LifeBarPS')
end
LIB.RegisterPanel('MY_LifeBar', _L['MY_LifeBar'], _L['General'], 'UI/Image/LootPanel/LootPanel.UITex|74', PS)
