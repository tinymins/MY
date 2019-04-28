--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 焦点列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
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
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_Focus/lang/')
if not LIB.AssertVersion('MY_Focus', _L['MY_Focus'], 0x2011800) then
	return
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w  = ui:width()
	local h  = max(ui:height(), 440)
	local xr, yr, wr = w - 260, 5, 260
	local xl, yl, wl = 5,  5, w - wr -15

	-- 左侧
	local x, y = xl, yl
	x = x + ui:append('WndCheckBox', {
		x = x, y = y, w = 250, text = _L['enable'],
		r = 255, g = 255, b = 0, checked = MY_Focus.bEnable,
		oncheck = function(bChecked)
			MY_Focus.bEnable = bChecked
		end,
		tip = function()
			if MY_Focus.IsShielded() then
				return _L['Can not use in shielded map!']
			end
		end,
		autoenable = function() return not MY_Focus.IsShielded() end,
	}, true):autoWidth():width() + 10

	ui:append('WndEditBox', {
		x = x, y = y, w = wl - x, h = 25,
		placeholder = _L['Style'],
		text = MY_Focus.szStyle,
		onblur = function()
			local szStyle = UI(this):text():gsub('%s', '')
			if szStyle == '' then
				return
			end
			MY_Focus.szStyle = szStyle
			LIB.SwitchTab('MY_Focus', true)
		end,
	})
	x, y = xl, y + 25

	-- <hr />
	ui:append('Image', {x = x, y = y, w = wl, h = 1, image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageframe = 62})
	y = y + 5

	ui:append('WndCheckBox', {
		x = x, y = y, text = _L['auto focus'], checked = MY_Focus.bAutoFocus,
		oncheck = function(bChecked)
			MY_Focus.bAutoFocus = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})

	local function GeneItemText(v)
		local szType
		if v.tType.bAll then
			szType = _L['All']
		else
			local aText = {}
			for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
				if v.tType[eType] then
					insert(aText, _L.TARGET[eType])
				end
			end
			for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
				if v.tRelation['b' .. szRelation] then
					insert(aText, _L.RELATION[szRelation])
				end
			end
			szType = #aText == 0 and _L['None'] or concat(aText, ',')
		end
		return v.szPattern .. ' (' .. szType .. ')'
	end
	local list = ui:append('WndListBox', {
		x = x, y = y + 30, w = wl - x + xl, h = h - y - 40,
		autoenable = function() return MY_Focus.IsEnabled() end,
	}, true)
	-- 初始化list控件
	for _, v in ipairs(MY_Focus.GetAllFocusPattern()) do
		list:listbox('insert', GeneItemText(v), v, v)
	end
	list:listbox('onmenu', function(hItem, szText, oID, tData)
		local t = {{
			szOption = _L['delete'],
			fnAction = function()
				MY_Focus.RemoveFocusPattern(tData.szPattern)
				list:listbox('delete', 'id', oID)
			end,
		}}
		-- 匹配方式
		local t1 = { szOption = _L['Judge method'] }
		for _, eType in ipairs({ 'NAME', 'NAME_PATT', 'ID', 'TEMPLATE_ID', 'TONG_NAME', 'TONG_NAME_PATT' }) do
			insert(t1, {
				szOption = _L.JUDGE_METHOD[eType],
				bCheck = true, bMCheck = true,
				bChecked = tData.szMethod == eType,
				fnAction = function()
					tData.szMethod = eType
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
				end,
			})
		end
		insert(t, t1)
		-- 目标类型
		local t1 = {
			szOption = _L['Target type'], {
				szOption = _L['All'],
				bCheck = true, bChecked = tData.tType.bAll,
				fnAction = function()
					tData.tType.bAll = not tData.tType.bAll
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:listbox('update', 'id', oID, {'text'}, {GeneItemText(tData)})
				end,
			}
		}
		for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
			insert(t1, {
				szOption = _L.TARGET[eType],
				bCheck = true, bChecked = tData.tType[eType],
				fnAction = function()
					tData.tType[eType] = not tData.tType[eType]
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:listbox('update', 'id', oID, {'text'}, {GeneItemText(tData)})
				end,
				fnDisable = function()
					return tData.tType.bAll
				end,
			})
		end
		insert(t, t1)
		-- 目标关系
		local t1 = {
			szOption = _L['Target relation'], {
				szOption = _L['All'],
				bCheck = true, bChecked = tData.tRelation.bAll,
				fnAction = function()
					tData.tRelation.bAll = not tData.tRelation.bAll
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:listbox('update', 'id', oID, {'text'}, {GeneItemText(tData)})
				end,
			}
		}
		for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
			insert(t1, {
				szOption = _L.RELATION[szRelation],
				bCheck = true, bChecked = tData.tRelation['b' .. szRelation],
				fnAction = function()
					tData.tRelation['b' .. szRelation] = not tData.tRelation['b' .. szRelation]
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:listbox('update', 'id', oID, {'text'}, {GeneItemText(tData)})
				end,
				fnDisable = function()
					return tData.tRelation.bAll
				end,
			})
		end
		insert(t, t1)
		-- 目标血量百分比
		local t1 = {
			szOption = _L['Target life percentage'], {
				szOption = _L['Enable'],
				bCheck = true, bChecked = tData.tLife.bEnable,
				fnAction = function()
					tData.tLife.bEnable = not tData.tLife.bEnable
				end,
			},
			LIB.InsertOperatorMenu({
				szOption = _L['Operator'],
				fnDisable = function() return not tData.tLife.bEnable end,
			}, tData.tLife.szOperator, function(op)
				tData.tLife.szOperator = op
				MY_Focus.SetFocusPattern(tData.szPattern, tData)
			end), {
				szOption = _L['Value'],
				fnMouseEnter = function()
					OutputTip(GetFormatText(tData.tLife.nValue .. '%', nil, 255, 255, 0), 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
				end,
				fnAction = function()
					GetUserInputNumber(tData.tLife.nValue, 100, nil, function(val)
						tData.tLife.nValue = val
						MY_Focus.SetFocusPattern(tData.szPattern, tData)
					end, nil, function() return not LIB.IsPanelVisible() end)
				end,
				fnDisable = function() return not tData.tLife.bEnable end,
			},
		}
		insert(t, t1)
		-- 最远距离
		local t1 = {
			szOption = _L['Max distance'],
			fnMouseEnter = function()
				if tData.nMaxDistance == 0 then
					return
				end
				OutputTip(GetFormatText(tData.nMaxDistance .. g_tStrings.STR_METER , nil, 255, 255, 0), 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
			fnAction = function()
				GetUserInput(_L['Please input max distance, leave blank to disable:'], function(val)
					tData.nMaxDistance = tonumber(val) or 0
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
				end, nil, function() return not LIB.IsPanelVisible() end, nil, tData.nMaxDistance)
			end,
		}
		insert(t, t1)
		-- 名称显示
		local t1 = {
			szOption = _L['Name display'],
			fnMouseEnter = function()
				if tData.szDisplay == '' then
					return
				end
				OutputTip(GetFormatText(tData.szDisplay, nil, 255, 255, 0), 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
			fnAction = function()
				GetUserInput(_L['Please input display name, leave blank to use its own name:'], function(val)
					tData.szDisplay = val
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
				end, nil, function() return not LIB.IsPanelVisible() end, nil, tData.szDisplay)
			end,
		}
		insert(t, t1)
		return t
	end)
	-- add
	ui:append('WndButton', {
		x = wl - 80, y = y, w = 80,
		text = _L['add'],
		onclick = function()
			GetUserInput(_L['add auto focus'], function(szText)
				local tData = MY_Focus.SetFocusPattern(szText)
				if not tData then
					return
				end
				list:listbox('insert', GeneItemText(tData), tData, tData)
			end, function() end, function() end, nil, '')
		end,
		tip = _L['Right click list to delete'],
		autoenable = function() return MY_Focus.IsEnabled() end,
	})

	-- 右侧
	local x, y = xr, yr
	local deltaY = (h - y * 2) / 21
	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['hide when empty'],
		checked = MY_Focus.bAutoHide,
		oncheck = function(bChecked)
			MY_Focus.bAutoHide = bChecked
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['auto focus very important npc'],
		tip = _L['boss list is always been collecting and updating'],
		tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
		checked = MY_Focus.bFocusINpc,
		oncheck = function(bChecked)
			MY_Focus.bFocusINpc = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Embedded focus (powered by nangongbo)'],
		tip = _L['Embedded focus is always been collecting and updating'],
		tippostype = MY_TIP_POSTYPE.TOP_BOTTOM,
		checked = MY_Focus.bEmbeddedFocus,
		oncheck = function(bChecked)
			MY_Focus.bEmbeddedFocus = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['auto focus friend'],
		checked = MY_Focus.bFocusFriend,
		oncheck = function(bChecked)
			MY_Focus.bFocusFriend = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('Image', {
		x = x + 5, y = y - 3, w = 10, h = 8,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageframe = 10,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['auto focus tong'],
		checked = MY_Focus.bFocusTong,
		oncheck = function(bChecked)
			MY_Focus.bFocusTong = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('Image', {
		x = x + 5, y = y, w = 10, h = 10,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageframe = 10,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	ui:append('Image', {
		x = x + 10, y = y + 5, w = 10, h = 10,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageframe = 8,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	ui:append('WndCheckBox', {
		x = x + 20, y = y, w = wr, text = _L['auto focus only in public map'],
		checked = MY_Focus.bOnlyPublicMap,
		oncheck = function(bChecked)
			MY_Focus.bOnlyPublicMap = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['auto focus enemy'],
		checked = MY_Focus.bFocusEnemy,
		oncheck = function(bChecked)
			MY_Focus.bFocusEnemy = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['jjc auto focus party'],
		checked = MY_Focus.bFocusJJCParty,
		oncheck = function(bChecked)
			MY_Focus.bFocusJJCParty = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['jjc auto focus enemy'],
		checked = MY_Focus.bFocusJJCEnemy,
		oncheck = function(bChecked)
			MY_Focus.bFocusJJCEnemy = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Anmerkungen auto focus'],
		checked = MY_Focus.bFocusAnmerkungen,
		oncheck = function(bChecked)
			MY_Focus.bFocusAnmerkungen = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['show focus\'s target'],
		checked = MY_Focus.bShowTarget,
		oncheck = function(bChecked)
			MY_Focus.bShowTarget = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y,w = wr, text = _L['traversal object'],
		tip = _L['may cause some problem in dungeon map'],
		tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		checked = MY_Focus.bTraversal,
		oncheck = function(bChecked)
			MY_Focus.bTraversal = bChecked
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['hide dead object'],
		checked = MY_Focus.bHideDeath,
		oncheck = function(bChecked)
			MY_Focus.bHideDeath = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['display kungfu icon instead of location'],
		checked = MY_Focus.bDisplayKungfuIcon,
		oncheck = function(bChecked)
			MY_Focus.bDisplayKungfuIcon = bChecked
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		name = 'WndCheckBox_SortByDistance',
		x = x, y = y, w = wr,
		text = _L['sort by distance'],
		checked = MY_Focus.bSortByDistance,
		oncheck = function(bChecked)
			MY_Focus.bSortByDistance = bChecked
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		name = 'WndCheckBox_EnableSceneNavi',
		x = x, y = y, w = wr,
		text = _L['enable scene navi'],
		checked = MY_Focus.bEnableSceneNavi,
		oncheck = function(bChecked)
			MY_Focus.bEnableSceneNavi = bChecked
			MY_Focus.RescanNearby()
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['heal healper'],
		tip = _L['select target when mouse enter'],
		tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		checked = MY_Focus.bHealHelper,
		oncheck = function(bChecked)
			MY_Focus.bHealHelper = bChecked
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndComboBox', {
		x = x, y = y, w = wr, text = _L['Distance type'],
		menu = function()
			return LIB.GetDistanceTypeMenu(true, MY_Focus.szDistanceType, function(p)
				MY_Focus.szDistanceType = p.szType
			end)
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	}, true):autoWidth()
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('max display count %d.', val) end,
		range = {1, 20},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		value = MY_Focus.nMaxDisplay,
		onchange = function(val)
			MY_Focus.nMaxDisplay = val
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('current scale-x is %d%%.', val) end,
		range = {10, 300},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		value = MY_Focus.fScaleX * 100,
		onchange = function(val)
			MY_Focus.fScaleX = val / 100
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:append('WndSliderBox', {
		x = x, y = y, w = 150,
		textfmt = function(val) return _L('current scale-y is %d%%.', val) end,
		range = {10, 300},
		sliderstyle = MY_SLIDER_DISPTYPE.SHOW_VALUE,
		value = MY_Focus.fScaleY * 100,
		onchange = function(val)
			MY_Focus.fScaleY = val / 100
		end,
		autoenable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY
end
LIB.RegisterPanel('MY_Focus', _L['focus list'], _L['Target'], 'ui/Image/button/SystemButton_1.UITex|9', PS)
