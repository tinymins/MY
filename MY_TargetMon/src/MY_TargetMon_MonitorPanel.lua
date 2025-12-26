--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控监控项配置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon_MonitorPanel'
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}
local CUSTOM_BOX_EXTENT_ANIMATE = {
	{nil, _L['None']},
	{'ui/Image/Common/Box.UITex|17'},
	{'ui/Image/Common/Box.UITex|20'},
}
local DEFAULT_CONTENT_COLOR = {255, 255, 0}
local MY_TARGET_MON_MAP_TYPE = MY_TargetMonConfig.MY_TARGET_MON_MAP_TYPE
local MY_TARGET_MON_MAP_TYPE_NAME = MY_TargetMonConfig.MY_TARGET_MON_MAP_TYPE_NAME

function D.Open(szConfigUUID, szMonitorUUID)
	local dataset = MY_TargetMonConfig.GetDataset(szConfigUUID)
	if not dataset then
		return
	end
	local mon
	for _, m in ipairs(dataset.aMonitor) do
		if m.szUUID == szMonitorUUID then
			mon = m
		end
	end
	if not mon then
		return
	end
	local ui = X.UI.CreateFrame('MY_TargetMon_MonitorPanel', {
		w = 800, h = 420, text = '',
	})
	local nPaddingX, nPaddingY = 30, 10
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()
	local uiWnd = ui:Append('WndWindow', { x = 0, y = 30, w = nW, h = 380 })

	local nDeltaY = 28

	-- 图标
	uiWnd:Append('Box', {
		x = (nW - 50) / 2, y = nY, w = 50, h = 50, icon = mon.nIconID or MY_TargetMonConfig.DEFAULT_MONITOR_ICON_ID,
		onHover = function(bHover) this:SetObjectMouseOver(bHover) end,
		onClick = function()
			local box = this
			local menu = {}
			local t1 = {
				szOption = _L['Monitor Change Icon'],
				fnAction = function()
					X.UI.OpenIconPicker(
						function(nIconID)
							mon.nIconID = nIconID
							FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
							box:SetObjectIcon(nIconID)
						end,
						mon.nIconID
					)
					X.UI.ClosePopupMenu()
				end,
			}
			if mon.nIconID then
				t1.szLayer = 'ICON_RIGHT'
				t1.szIcon = 'ui/Image/UICommon/Feedanimials.uitex'
				t1.nFrame = 86
				t1.nMouseOverFrame = 87
				t1.fnClickIcon = function()
					mon.nIconID = nil
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					box:SetObjectIcon(MY_TargetMonConfig.DEFAULT_MONITOR_ICON_ID)
					X.UI.ClosePopupMenu()
				end
			end
			table.insert(menu, t1)
			local nX, nY = Cursor.GetPos()
			local nW, nH = 0, 0
			menu.x = nX
			menu.y = nY + nH
			menu.nMiniWidth = nW
			X.UI.PopupMenu(menu)
		end,
	})
	nY = nY + 40

	-- 通用
	nX = nPaddingX
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		r = 255, g = 255, b = 0,
		text = _L['Monitor Common Config'],
	}):Width() + 5
	-- 启用
	nX = nX + uiWnd:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Monitor Enable'],
		checked = mon.bEnable,
		onCheck = function(bChecked)
			mon.bEnable = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
		end,
	}):Width() + 5
	nY = nY + nDeltaY

	-- ID
	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		text = _L['Monitor ID'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		x = nX, y = nY, w = 100, h = 22,
		text = mon.dwID,
		onChange = function(val)
			local nValue = tonumber(val)
			if nValue then
				mon.dwID = nValue
				FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
			end
		end,
	}):Width() + 5
	-- 等级
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		text = _L['Monitor Level'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		x = nX, y = nY, w = 50, h = 22,
		text = mon.nLevel,
		onChange = function(val)
			local nValue = tonumber(val)
			if nValue then
				mon.nLevel = nValue
				FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
			end
		end,
	}):Width() + 5
	-- 层数
	if dataset.szType == 'BUFF' then
		nX = nX + uiWnd:Append('Text', {
			x = nX, y = nY - 3, w = 'auto',
			text = _L['Monitor StackNum'],
		}):Width() + 5
		nX = nX + uiWnd:Append('WndComboBox', {
			x = nX, y = nY, w = 90, h = 25,
			text = X.GetOperatorName(mon.nStackNumOp or '=='),
			menu = function()
				local this = this
				return X.InsertOperatorMenu(
					{},
					mon.nStackNumOp,
					function(szOp)
						mon.nStackNumOp = szOp
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
						X.UI(this):Text(X.GetOperatorName(szOp))
						X.UI.ClosePopupMenu()
					end
				)
			end,
			tip = {
				render = _L['Monitor op value set to 0, means no limit, operator will be ignored.'],
				position = X.UI.TIP_POSITION.TOP_BOTTOM,
			},
		}):Width() + 5
		nX = nX + uiWnd:Append('WndEditBox', {
			x = nX, y = nY, w = 50, h = 22,
			text = mon.nStackNum,
			onChange = function(szValue)
				local nValue = tonumber(szValue)
				if nValue then
					mon.nStackNum = nValue
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
				end
			end,
			tip = {
				render = _L['Monitor op value set to 0, means no limit, operator will be ignored.'],
				position = X.UI.TIP_POSITION.TOP_BOTTOM,
			},
		}):Width() + 5
	end
	nY = nY + nDeltaY

	-- 备注名称
	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		text = _L['Monitor Note'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		x = nX, y = nY, w = 205, h = 22,
		text = mon.szNote,
		onChange = function(val)
			mon.szNote = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
		end,
	}):Width() + 5
	nY = nY + nDeltaY

	-- 提示内容
	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		text = _L['Monitor Content'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndAutocomplete', {
		text = mon.szContent,
		x = nX, y = nY, w = 180, h = 22,
		onChange = function(szText)
			mon.szContent = szText
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
		end,
		onClick = function()
			if IsPopupMenuOpened() then
				X.UI(this):Autocomplete('close')
			else
				X.UI(this):Autocomplete('search', '')
			end
		end,
		autocomplete = {{'option', 'source', _L.MONITOR_CONTENT_LIST}, {'option', 'maxOption', 40}},
	}):Width() + 5
	nX = nX + uiWnd:Append('ColorBox', {
		w = 18, h = 18, text = '',
		x = nX, y = nY + 1, color = mon.aContentColor or DEFAULT_CONTENT_COLOR,
		onColorPick = function(r, g, b)
			mon.aContentColor = {r, g, b}
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
		end,
	}):Width() + 5
	nY = nY + nDeltaY

	-- 提示内容
	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		text = _L['Monitor Group'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		text = mon.szGroup,
		x = nX, y = nY, w = 180, h = 22,
		onChange = function(szText)
			if szText == '' then
				szText = nil
			end
			mon.szGroup = szText
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
		end,
		tip = {
			render = _L['Monitor same group will only show one at the same time'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
	}):Width() + 5
	nY = nY + nDeltaY

	-- 条件
	nX = nPaddingX
	nY = nY + 10
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		r = 255, g = 255, b = 0,
		text = _L['Monitor Condition Config'],
	}):Width() + 5
	nY = nY + nDeltaY

	-- 自身心法
	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('WndComboBox', {
		w = 'auto', h = 25, text = _L['Monitor Self Kungfu Requirement'],
		x = nX, y = nY,
		menu = function()
			local menu = {
				{
					szOption = _L['Monitor All Kungfu'],
					rgb = {255, 255, 0},
					bCheck = true,
					bChecked = X.IsEmpty(mon.tKungfu) or mon.tKungfu.bAll,
					fnAction = function(_, bChecked)
						if not mon.tKungfu then
							mon.tKungfu = {}
						end
						mon.tKungfu.bAll = bChecked
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					end,
				},
			}
			for _, force in ipairs(X.CONSTANT.FORCE_LIST) do
				for i, dwKungfuID in ipairs(X.GetForceKungfuList(force.dwID) or {}) do
					table.insert(menu, {
						szOption = X.GetSkillName(dwKungfuID, 1),
						rgb = {X.GetForceColor(force.dwID, 'foreground')},
						bCheck = true,
						bChecked = not X.IsEmpty(mon.tKungfu) and mon.tKungfu[dwKungfuID],
						fnAction = function(_, bChecked)
							if not mon.tKungfu then
								mon.tKungfu = {}
							end
							mon.tKungfu[dwKungfuID] = bChecked
							FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
						end,
						fnDisable = function() return X.IsEmpty(mon.tKungfu) or mon.tKungfu.bAll end,
					})
				end
			end
			return menu
		end,
	}):Width() + 5

	-- 目标心法
	nX = nX + uiWnd:Append('WndComboBox', {
		w = 'auto', h = 25, text = _L['Monitor Target Kungfu Requirement'],
		x = nX, y = nY,
		menu = function()
			local menu = {
				{
					szOption = _L['All kungfus'],
					rgb = {255, 255, 0},
					bCheck = true,
					bChecked = X.IsEmpty(mon.tTargetKungfu) or mon.tTargetKungfu.bAll,
					fnAction = function(_, bChecked)
						if not mon.tTargetKungfu then
							mon.tTargetKungfu = {}
						end
						mon.tTargetKungfu.bAll = bChecked
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					end,
				},
				{
					szOption = _L['NPC'],
					rgb = {255, 255, 0},
					bCheck = true,
					bChecked = not X.IsEmpty(mon.tTargetKungfu) and mon.tTargetKungfu.bNpc,
					fnAction = function(_, bChecked)
						if not mon.tTargetKungfu then
							mon.tTargetKungfu = {}
						end
						mon.tTargetKungfu.bNpc = bChecked
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					end,
					fnDisable = function() return X.IsEmpty(mon.tTargetKungfu) or mon.tTargetKungfu.bAll end,
				},
			}
			for _, force in ipairs(X.CONSTANT.FORCE_LIST) do
				for i, dwKungfuID in ipairs(X.GetForceKungfuList(force.dwID) or {}) do
					table.insert(menu, {
						szOption = X.GetSkillName(dwKungfuID, 1),
						rgb = {X.GetForceColor(force.dwID, 'foreground')},
						bCheck = true,
						bChecked = not X.IsEmpty(mon.tTargetKungfu) and mon.tTargetKungfu[dwKungfuID],
						fnAction = function(_, bChecked)
							if not mon.tTargetKungfu then
								mon.tTargetKungfu = {}
							end
							mon.tTargetKungfu[dwKungfuID] = bChecked
							FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
						end,
						fnDisable = function() return X.IsEmpty(mon.tTargetKungfu) or mon.tTargetKungfu.bAll end,
					})
				end
			end
			return menu
		end,
	}):Width() + 5

	-- 地图要求
	nX = nX + uiWnd:Append('WndComboBox', {
		w = 'auto', h = 25, text = _L['Monitor Map Requirement'],
		x = nX, y = nY,
		menu = function()
			local menu = X.GetDungeonMenu({
				fnAction = function(p)
					if not mon.tMap then
						mon.tMap = {}
					end
					mon.tMap[p.dwID] = not mon.tMap[p.dwID]
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
				end,
				tChecked = mon.tMap,
			})
			for i, p in ipairs(menu) do
				p.fnDisable = function() return X.IsEmpty(mon.tMap) or mon.tMap.bAll end
			end
			local t1 = {
				szOption = _L['Monitor Map Requirement By Type'],
				fnDisable = function() return X.IsEmpty(mon.tMap) or mon.tMap.bAll end,
			}
			for _, eMapType in ipairs({
				MY_TARGET_MON_MAP_TYPE.CITY, -- 主城
				MY_TARGET_MON_MAP_TYPE.VILLAGE, -- 野外
				MY_TARGET_MON_MAP_TYPE.DUNGEON, -- 秘境
				MY_TARGET_MON_MAP_TYPE.TEAM_DUNGEON, -- 小队秘境
				MY_TARGET_MON_MAP_TYPE.RAID_DUNGEON, -- 团队秘境
				MY_TARGET_MON_MAP_TYPE.COMPETITION, -- 竞技
				MY_TARGET_MON_MAP_TYPE.STARVE, -- 浪客行
				MY_TARGET_MON_MAP_TYPE.ARENA, -- 名剑大会
				MY_TARGET_MON_MAP_TYPE.BATTLEFIELD, -- 战场
				MY_TARGET_MON_MAP_TYPE.PUBG, -- 绝境战场
				MY_TARGET_MON_MAP_TYPE.ZOMBIE, -- 李渡鬼域
				MY_TARGET_MON_MAP_TYPE.MONSTER, -- 百战
				MY_TARGET_MON_MAP_TYPE.MOBA, -- 列星虚境
				MY_TARGET_MON_MAP_TYPE.HOMELAND, -- 家园
				MY_TARGET_MON_MAP_TYPE.GUILD_TERRITORY, -- 帮会领地
				MY_TARGET_MON_MAP_TYPE.ROGUELIKE, -- 八荒衡鉴
				MY_TARGET_MON_MAP_TYPE.CAMP, -- 阵营地图
			}) do
				table.insert(t1, {
					szOption = MY_TARGET_MON_MAP_TYPE_NAME[eMapType],
					bCheck = true,
					bChecked = mon.tMap and mon.tMap[eMapType],
					fnAction = function(_, bChecked)
						if not mon.tMap then
							mon.tMap = {}
						end
						mon.tMap[eMapType] = bChecked
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					end,
					fnDisable = function() return X.IsEmpty(mon.tMap) or mon.tMap.bAll end,
				})
			end
			table.insert(menu, 1, t1)
			table.insert(menu, 1, {
				szOption = _L['Monitor All Maps'],
				bCheck = true,
				bChecked = X.IsEmpty(mon.tMap) or mon.tMap.bAll,
				fnAction = function(_, bChecked)
					if not mon.tMap then
						mon.tMap = {}
					end
					mon.tMap.bAll = bChecked
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
				end,
			})
			return menu
		end,
	}):Width() + 5

	-- 隐藏消失的
	nX = nX + uiWnd:Append('WndCheckBox', {
		w = 'auto', h = 25, text = dataset.bHideVoid and _L['Monitor Show Even Void'] or _L['Monitor Hide If Void'],
		x = nX, y = nY,
		checked = mon.bFlipHideVoid,
		onCheck = function(bChecked)
			mon.bFlipHideVoid = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
		end,
	}):Width() + 5

	-- 隐藏他人的
	if dataset.szType == 'BUFF' then
		nX = nX + uiWnd:Append('WndCheckBox', {
			w = 'auto', h = 25, text = dataset.bHideOthers and _L['Monitor Show Even Others'] or _L['Monitor Hide If Others'],
			x = nX, y = nY,
			checked = mon.bFlipHideOthers,
			onCheck = function(bChecked)
				mon.bFlipHideOthers = bChecked
				FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
			end,
		}):Width() + 5
	end

	nY = nY + nDeltaY

	-- 效果
	nX = nPaddingX
	nY = nY + 10
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		r = 255, g = 255, b = 0,
		text = _L['Monitor Effect Config'],
	}):Width() + 5
	nY = nY + nDeltaY

	-- 出现声音
	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('WndComboBox', {
		w = 'auto', h = 25, text = _L['Monitor Play Sound When Appear'],
		x = nX, y = nY,
		menu = function()
			local menu = X.GetSoundMenu(
				function(dwID, bCheck)
					if not mon.aSoundAppear then
						mon.aSoundAppear = {}
					end
					if not bCheck then
						for i, v in X.ipairs_r(mon.aSoundAppear) do
							if v == dwID then
								table.remove(mon.aSoundAppear, i)
							end
						end
					else
						table.insert(mon.aSoundAppear, dwID)
					end
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
				end,
				mon.aSoundAppear and X.ArrayToObject(mon.aSoundAppear) or {},
				true
			)
			return menu
		end,
	}):Width() + 5

	-- 消失声音
	nX = nX + uiWnd:Append('WndComboBox', {
		w = 'auto', h = 25, text = _L['Monitor Play Sound When Disappear'],
		x = nX, y = nY,
		menu = function()
			local menu = X.GetSoundMenu(
				function(dwID, bCheck)
					if not mon.aSoundDisappear then
						mon.aSoundDisappear = {}
					end
					if not bCheck then
						for i, v in X.ipairs_r(mon.aSoundDisappear) do
							if v == dwID then
								table.remove(mon.aSoundDisappear, i)
							end
						end
					else
						table.insert(mon.aSoundDisappear, dwID)
					end
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
				end,
				mon.aSoundDisappear and X.ArrayToObject(mon.aSoundDisappear) or {},
				true
			)
			return menu
		end,
	}):Width() + 5

	-- 显示特效框
	nX = nX + uiWnd:Append('WndComboBox', {
		w = 'auto', h = 25, text = _L['Monitor Active Extent Animate'],
		x = nX, y = nY,
		menu = function()
			local menu = {}
			for _, p in ipairs(CUSTOM_BOX_EXTENT_ANIMATE) do
				local t1 = {
					szOption = p[2] or p[1],
					bCheck = true, bMCheck = true,
					bChecked = p[1] == mon.szExtentAnimate,
					fnAction = function()
						mon.szExtentAnimate = p[1]
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
					end,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = 'ICON_RIGHTMOST',
				}
				if p[1] then
					t1.szIcon, t1.nFrame = unpack(p[1]:split('|'))
				end
				table.insert(menu, t1)
			end
			return menu
		end,
	}):Width() + 5

	nX = nPaddingX + 20
	nY = nY + nDeltaY + 20
	uiWnd:Append('WndButton', {
		x = (nW - 70) / 2, y = nY,
		w = 80, h = 35,
		text = _L['Delete'],
		color = { 255, 0, 0 },
		buttonStyle = 'FLAT',
		onClick = function()
			X.Confirm(_L['Sure to delete monitor? This operation can not be undone.'], function()
				for i, v in X.ipairs_r(dataset.aMonitor) do
					if v == mon then
						table.remove(dataset.aMonitor, i)
						MY_TargetMon_MonitorPanel.Close()
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_MONITOR_MODIFY', dataset.szUUID)
						return
					end
				end
			end)
		end,
	})

	local parent = Station.Lookup('Normal/MY_TargetMon_PS')
	ui:Pos(parent:GetRelX() + (parent:GetW() - ui:Width()) / 2, parent:GetRelY() + (parent:GetH() - ui:Height()) / 2)
end

function D.Close()
	X.UI.CloseFrame('MY_TargetMon_MonitorPanel')
end

function D.OnFrameBreathe()
	local parent = Station.Lookup('Normal/MY_TargetMon_PS')
	if not parent or Station.Lookup('Normal/MY_TargetMon_ConfigPanel') then
		X.UI.CloseFrame(this)
		return
	end
	local frame, bBehindParent = parent:GetNext(), true
	while frame do
		if frame:GetName() == this:GetName() then
			bBehindParent = false
			break
		end
		frame = frame:GetNext()
	end
	if bBehindParent then
		this:BringToTop()
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMon_MonitorPanel',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				Open = D.Open,
				Close = D.Close,
			},
		},
	},
}
MY_TargetMon_MonitorPanel = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
