--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 焦点列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Focus/MY_Focus.PS'
local PLUGIN_NAME = 'MY_Focus'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Focus'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local PS = { szRestriction = 'MY_Focus' }
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local w  = ui:Width()
	local h  = math.max(ui:Height(), 440)
	local xr, yr, wr = w - 260, 5, 260
	local xl, yl, wl = 5,  5, w - wr -15

	-- 左侧
	local x, y = xl, yl
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 250, text = _L['Enable'],
		r = 255, g = 255, b = 0, checked = MY_Focus.bEnable,
		onCheck = function(bChecked)
			MY_Focus.bEnable = bChecked
		end,
		tip = function()
			if MY_Focus.IsShielded() then
				return _L['Can not use in shielded map!']
			end
		end,
		autoEnable = function() return not MY_Focus.IsShielded() end,
	}):AutoWidth():Width() + 10

	x, y = xl, y + 25

	-- <hr />
	ui:Append('Image', {x = x, y = y, w = wl, h = 1, image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageFrame = 62})
	y = y + 5

	ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Auto focus'], checked = MY_Focus.bAutoFocus,
		onCheck = function(bChecked)
			MY_Focus.bAutoFocus = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})

	local list = ui:Append('WndListBox', {
		x = x, y = y + 30, w = wl - x + xl, h = h - y - 40,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	-- 初始化list控件
	for _, v in ipairs(MY_Focus.GetAllFocusPattern()) do
		list:ListBox('insert', { id = v, text = MY_Focus.FormatRuleText(v), data = v })
	end
	list:ListBox('onmenu', function(oID, szText, tData)
		local t = {{
			szOption = _L['Delete'],
			fnAction = function()
				MY_Focus.RemoveFocusPattern(tData.szPattern)
				list:ListBox('delete', 'id', oID)
				X.UI.ClosePopupMenu()
			end,
		}}
		-- 匹配方式
		local t1 = { szOption = _L['Judge method'] }
		for _, eType in ipairs({ 'NAME', 'NAME_PATT', 'ID', 'TEMPLATE_ID', 'TONG_NAME', 'TONG_NAME_PATT' }) do
			table.insert(t1, {
				szOption = _L.JUDGE_METHOD[eType],
				bCheck = true, bMCheck = true,
				bChecked = tData.szMethod == eType,
				fnAction = function()
					tData.szMethod = eType
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
				end,
			})
		end
		table.insert(t, t1)
		-- 目标类型
		local t1 = {
			szOption = _L['Target type'], {
				szOption = _L['All'],
				bCheck = true, bChecked = tData.tType.bAll,
				fnAction = function()
					tData.tType.bAll = not tData.tType.bAll
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:ListBox('update', 'id', oID, {'text'}, {MY_Focus.FormatRuleText(tData)})
				end,
			}
		}
		for _, eType in ipairs({ TARGET.NPC, TARGET.PLAYER, TARGET.DOODAD }) do
			table.insert(t1, {
				szOption = _L.TARGET[eType],
				bCheck = true, bChecked = tData.tType[eType],
				fnAction = function()
					tData.tType[eType] = not tData.tType[eType]
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:ListBox('update', 'id', oID, {'text'}, {MY_Focus.FormatRuleText(tData)})
				end,
				fnDisable = function()
					return tData.tType.bAll
				end,
			})
		end
		table.insert(t, t1)
		-- 目标关系
		local t1 = {
			szOption = _L['Target relation'], {
				szOption = _L['All'],
				bCheck = true, bChecked = tData.tRelation.bAll,
				fnAction = function()
					tData.tRelation.bAll = not tData.tRelation.bAll
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:ListBox('update', 'id', oID, {'text'}, {MY_Focus.FormatRuleText(tData)})
				end,
			}
		}
		for _, szRelation in ipairs({ 'Enemy', 'Ally' }) do
			table.insert(t1, {
				szOption = _L.RELATION[szRelation],
				bCheck = true, bChecked = tData.tRelation['b' .. szRelation],
				fnAction = function()
					tData.tRelation['b' .. szRelation] = not tData.tRelation['b' .. szRelation]
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
					list:ListBox('update', 'id', oID, {'text'}, {MY_Focus.FormatRuleText(tData)})
				end,
				fnDisable = function()
					return tData.tRelation.bAll
				end,
			})
		end
		table.insert(t, t1)
		-- 目标血量百分比
		local t1 = {
			szOption = _L['Target life percentage'], {
				szOption = _L['Enable'],
				bCheck = true, bChecked = tData.tLife.bEnable,
				fnAction = function()
					tData.tLife.bEnable = not tData.tLife.bEnable
				end,
			},
			X.InsertOperatorMenu({
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
				fnMouseLeave = function()
					HideTip()
				end,
				fnAction = function()
					GetUserInputNumber(tData.tLife.nValue, 100, nil, function(val)
						tData.tLife.nValue = val
						MY_Focus.SetFocusPattern(tData.szPattern, tData)
					end, nil, function() return not X.Panel.IsVisible() end)
				end,
				fnDisable = function() return not tData.tLife.bEnable end,
			},
		}
		table.insert(t, t1)
		-- 最远距离
		local t1 = {
			szOption = _L['Max distance'],
			fnMouseEnter = function()
				if tData.nMaxDistance == 0 then
					return
				end
				OutputTip(GetFormatText(tData.nMaxDistance .. g_tStrings.STR_METER , nil, 255, 255, 0), 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
			fnMouseLeave = function()
				HideTip()
			end,
			fnAction = function()
				GetUserInput(_L['Please input max distance, leave blank to disable:'], function(val)
					tData.nMaxDistance = tonumber(val) or 0
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
				end, nil, function() return not X.Panel.IsVisible() end, nil, tData.nMaxDistance)
			end,
		}
		table.insert(t, t1)
		-- 名称显示
		local t1 = {
			szOption = _L['Name display'],
			fnMouseEnter = function()
				if tData.szDisplay == '' then
					return
				end
				OutputTip(GetFormatText(tData.szDisplay, nil, 255, 255, 0), 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
			end,
			fnMouseLeave = function()
				HideTip()
			end,
			fnAction = function()
				GetUserInput(_L['Please input display name, leave blank to use its own name:'], function(val)
					tData.szDisplay = val
					MY_Focus.SetFocusPattern(tData.szPattern, tData)
				end, nil, function() return not X.Panel.IsVisible() end, nil, tData.szDisplay)
			end,
		}
		table.insert(t, t1)
		return t
	end)
	-- add
	ui:Append('WndButton', {
		x = wl - 80, y = y, w = 80,
		text = _L['Add'],
		onClick = function()
			GetUserInput(_L['Add auto focus'], function(szText)
				local tData = MY_Focus.SetFocusPattern(szText)
				if not tData then
					return
				end
				list:ListBox('insert', { id = tData, text = MY_Focus.FormatRuleText(tData), data = tData })
			end, function() end, function() end, nil, '')
		end,
		tip = _L['Right click list to delete'],
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})

	-- 右侧
	local x, y = xr, yr
	local deltaY = (h - y * 2) / 20
	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Hide when empty'],
		checked = MY_Focus.bAutoHide,
		onCheck = function(bChecked)
			MY_Focus.bAutoHide = bChecked
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Auto focus very important npc'],
		tip = {
			render = _L['Boss list is always been collecting and updating'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		checked = MY_Focus.bFocusINpc,
		onCheck = function(bChecked)
			MY_Focus.bFocusINpc = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['TeamMon focus'],
		tip = {
			render = _L['TeamMon focus is related to MY_TeamMon data.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		checked = MY_Focus.bTeamMonFocus,
		onCheck = function(bChecked)
			MY_Focus.bTeamMonFocus = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Auto focus friend'],
		checked = MY_Focus.bFocusFriend,
		onCheck = function(bChecked)
			MY_Focus.bFocusFriend = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('Image', {
		x = x + 5, y = y - 3, w = 10, h = 8,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageFrame = 10,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Auto focus tong'],
		checked = MY_Focus.bFocusTong,
		onCheck = function(bChecked)
			MY_Focus.bFocusTong = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('Image', {
		x = x + 5, y = y - 3, w = 10, h = 8,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageFrame = 10,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['MY_PlayerRemark auto focus'],
		checked = MY_Focus.bFocusPlayerRemark,
		onCheck = function(bChecked)
			MY_Focus.bFocusPlayerRemark = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('Image', {
		x = x + 5, y = y, w = 10, h = 10,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageFrame = 10,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	ui:Append('Image', {
		x = x + 10, y = y + 5, w = 10, h = 10,
		image = 'ui/Image/UICommon/ScienceTree.UITex',
		imageFrame = 8,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	ui:Append('WndCheckBox', {
		x = x + 20, y = y, w = wr, text = _L['Auto focus only in public map'],
		checked = MY_Focus.bOnlyPublicMap,
		onCheck = function(bChecked)
			MY_Focus.bOnlyPublicMap = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Auto focus enemy'],
		checked = MY_Focus.bFocusEnemy,
		onCheck = function(bChecked)
			MY_Focus.bFocusEnemy = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Auto focus party in arena'],
		checked = MY_Focus.bFocusJJCParty,
		onCheck = function(bChecked)
			MY_Focus.bFocusJJCParty = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Auto focus enemy in arena'],
		checked = MY_Focus.bFocusJJCEnemy,
		onCheck = function(bChecked)
			MY_Focus.bFocusJJCEnemy = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Show focus\'s target'],
		checked = MY_Focus.bShowTarget,
		onCheck = function(bChecked)
			MY_Focus.bShowTarget = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Hide dead object'],
		checked = MY_Focus.bHideDeath,
		onCheck = function(bChecked)
			MY_Focus.bHideDeath = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Display kungfu icon instead of location'],
		checked = MY_Focus.bDisplayKungfuIcon,
		onCheck = function(bChecked)
			MY_Focus.bDisplayKungfuIcon = bChecked
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_SortByDistance',
		x = x, y = y, w = wr,
		text = _L['Sort by distance'],
		checked = MY_Focus.bSortByDistance,
		onCheck = function(bChecked)
			MY_Focus.bSortByDistance = bChecked
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		name = 'WndCheckBox_EnableSceneNavi',
		x = x, y = y, w = wr,
		text = _L['Enable scene navi'],
		checked = MY_Focus.bEnableSceneNavi,
		onCheck = function(bChecked)
			MY_Focus.bEnableSceneNavi = bChecked
			MY_Focus.RescanNearby()
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Show tip at right bottom'],
		checked = MY_Focus.bShowTipRB,
		onCheck = function(bChecked)
			MY_Focus.bShowTipRB = bChecked
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = wr, text = _L['Heal healper'],
		tip = {
			render = _L['Select target when mouse enter'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		checked = MY_Focus.bHealHelper,
		onCheck = function(bChecked)
			MY_Focus.bHealHelper = bChecked
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	}):AutoWidth():Width() + 5

	ui:Append('WndComboBox', {
		x = x, y = y, w = wr, text = _L['Distance type'],
		menu = function()
			return X.GetDistanceTypeMenu(true, MY_Focus.szDistanceType, function(p)
				MY_Focus.szDistanceType = p.szType
			end)
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	}):AutoWidth()

	x = xr
	y = y + deltaY

	ui:Append('WndSlider', {
		x = x, y = y, w = 150,
		textFormatter = function(val) return _L('Max display count %d.', val) end,
		range = {1, 20},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = MY_Focus.nMaxDisplay,
		onChange = function(val)
			MY_Focus.nMaxDisplay = val
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndSlider', {
		x = x, y = y, w = 150,
		textFormatter = function(val) return _L('Current scale-x is %d%%.', val) end,
		range = {10, 300},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = MY_Focus.fScaleX * 100,
		onChange = function(val)
			MY_Focus.fScaleX = val / 100
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY

	ui:Append('WndSlider', {
		x = x, y = y, w = 150,
		textFormatter = function(val) return _L('Current scale-y is %d%%.', val) end,
		range = {10, 300},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = MY_Focus.fScaleY * 100,
		onChange = function(val)
			MY_Focus.fScaleY = val / 100
		end,
		autoEnable = function() return MY_Focus.IsEnabled() end,
	})
	y = y + deltaY
end
X.Panel.Register(_L['Target'], 'MY_Focus', _L['Focus list'], 'ui/Image/button/SystemButton_1.UITex|9', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
