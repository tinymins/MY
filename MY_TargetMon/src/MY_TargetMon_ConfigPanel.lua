--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控项全局配置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon_ConfigPanel'
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
local MY_TARGET_MON_MAP_TYPE = MY_TargetMonConfig.MY_TARGET_MON_MAP_TYPE
local MY_TARGET_MON_MAP_TYPE_NAME = MY_TargetMonConfig.MY_TARGET_MON_MAP_TYPE_NAME
local TARGET_TYPE_LIST = {
	'CLIENT_PLAYER'  ,
	'CONTROL_PLAYER' ,
	'TARGET'         ,
	'TTARGET'        ,
	'TEAM_MARK_CLOUD',
	'TEAM_MARK_SWORD',
	'TEAM_MARK_AX'   ,
	'TEAM_MARK_HOOK' ,
	'TEAM_MARK_DRUM' ,
	'TEAM_MARK_SHEAR',
	'TEAM_MARK_STICK',
	'TEAM_MARK_JADE' ,
	'TEAM_MARK_DART' ,
	'TEAM_MARK_FAN'  ,
}
local CUSTOM_BOX_BG_STYLES = {
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
local CUSTOM_CD_BAR_STYLES = {
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

function D.Open(szConfigUUID)
	local dataset = MY_TargetMonConfig.GetDataset(szConfigUUID)
	if not dataset then
		return
	end
	local ui = X.UI.CreateFrame('MY_TargetMon_ConfigPanel', {
		w = 800, h = 360, text = _L['MY_TargetMon_ConfigPanel'],
	})
	local nPaddingX, nPaddingY = 10, 10
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()
	local uiWnd = ui:Append('WndWindow', { x = 0, y = 50, w = nW, h = 310 })

	nX = nPaddingX + 20
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		r = 255, g = 255, b = 0,
		text = _L['Title:'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		x = nX, y = nY, w = 220, h = 22,
		r = 255, g = 255, b = 0, text = dataset.szTitle,
		onChange = function(val)
			dataset.szTitle = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
	}):Width() + 5
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		r = 255, g = 255, b = 0,
		text = _L['Author:'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		x = nX, y = nY, w = 180, h = 22,
		r = 255, g = 255, b = 0, text = dataset.szAuthor,
		onChange = function(val)
			dataset.szAuthor = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
	}):Width() + 5
	nX = nX + uiWnd:Append('Text', {
		x = nX, y = nY - 3, w = 'auto',
		r = 255, g = 255, b = 0,
		text = _L['Version:'],
	}):Width() + 5
	nX = nX + uiWnd:Append('WndEditBox', {
		x = nX, y = nY, w = 120, h = 22,
		r = 255, g = 255, b = 0, text = dataset.szVersion,
		onChange = function(val)
			dataset.szVersion = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
	}):Width() + 5
	nY = nY + 40

	local nDeltaY = 31
	nX = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable'],
		checked = dataset.bEnable,
		onCheck = function(bChecked)
			dataset.bEnable = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 90, y = nY, w = 200,
		text = _L['Hide others buff'],
		tip = {
			render = _L['Hide others buff TIP'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		checked = dataset.bHideOthers,
		onCheck = function(bChecked)
			dataset.bHideOthers = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function()
			return dataset.bEnable and dataset.szType == 'BUFF'
		end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 180, y = nY, w = 180,
		text = _L['Hide void'],
		checked = dataset.bHideVoid,
		onCheck = function(bChecked)
			dataset.bHideVoid = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = nX, y = nY, w = 90,
		text = _L['Penetrable'],
		checked = dataset.bPenetrable,
		onCheck = function(bChecked)
			dataset.bPenetrable = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 90, y = nY, w = 100,
		text = _L['Undragable'],
		checked = not dataset.bDraggable,
		onCheck = function(bChecked)
			dataset.bDraggable = not bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable and not dataset.bPenetrable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 180, y = nY, w = 120,
		text = _L['Ignore system ui scale'],
		checked = dataset.bIgnoreSystemUIScale,
		onCheck = function(bChecked)
			dataset.bIgnoreSystemUIScale = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Show cd circle'],
		checked = dataset.bCdCircle,
		onCheck = function(bChecked)
			dataset.bCdCircle = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 90, y = nY, w = 200,
		text = _L['Show cd flash'],
		checked = dataset.bCdFlash,
		onCheck = function(bChecked)
			dataset.bCdFlash = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 180, y = nY, w = 200,
		text = _L['Show cd ready spark'],
		checked = dataset.bCdReadySpark,
		onCheck = function(bChecked)
			dataset.bCdReadySpark = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable and not dataset.bHideVoid end,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = nX, y = nY, w = 120,
		text = _L['Show cd bar'],
		checked = dataset.bCdBar,
		onCheck = function(bChecked)
			dataset.bCdBar = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 90, y = nY, w = 120,
		text = _L['Show name'],
		checked = dataset.bShowName,
		onCheck = function(bChecked)
			dataset.bShowName = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})

	uiWnd:Append('WndCheckBox', {
		x = nX + 180, y = nY, w = 120,
		text = _L['Show time'],
		checked = dataset.bShowTime,
		onCheck = function(bChecked)
			dataset.bShowTime = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 20
	uiWnd:Append('WndCheckBox', {
		x = nX, y = nY, w = 90,
		text = _L['Play sound'],
		checked = dataset.bPlaySound,
		onCheck = function(bChecked)
			dataset.bPlaySound = bChecked
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})

	uiWnd:Append('WndComboBox', {
		x = nX + 90, y = nY, w = 100,
		text = _L['Icon style'],
		menu = function()
			local t, t1, szIcon, nFrame = {}
			for _, p in ipairs(CUSTOM_BOX_BG_STYLES) do
				szIcon, nFrame = unpack(p[1]:split('|'))
				t1 = {
					szOption = p[2] or p[1],
					fnAction = function()
						dataset.szBoxBgUITex = p[1]
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
						X.UI.ClosePopupMenu()
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = 'ICON_RIGHTMOST',
					bCheck = true, bMCheck = true,
				}
				if p[1] == dataset.bBoxBgUITex then
					t1.rgb = {255, 255, 0}
					t1.bChecked = true
				end
				table.insert(t, t1)
			end
			return t
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	uiWnd:Append('WndComboBox', {
		x = nX + 90 + 100, y = nY, w = 100,
		text = _L['Countdown style'],
		menu = function()
			local t, t1, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CD_BAR_STYLES) do
				szIcon, nFrame = unpack(text:split('|'))
				t1 = {
					szOption = text,
					fnAction = function()
						dataset.szCdBarUITex = text
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
						X.UI.ClosePopupMenu()
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = 'ICON_FILL',
					bCheck = true, bMCheck = true,
				}
				if string.lower(text) == string.lower(dataset.szCdBarUITex) then
					t1.rgb = {255, 255, 0}
					t1.bChecked = true
				end
				table.insert(t, t1)
			end
			return t
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + 30

	nY = nPaddingY + 40
	local nDeltaY = 21
	local xr = nW - 340
	uiWnd:Append('WndComboBox', {
		x = xr, y = nY, w = 100,
		text = _L['Set target'],
		menu = function()
			local t = {}
			for _, eType in ipairs(TARGET_TYPE_LIST) do
				table.insert(t, {
					szOption = _L.TARGET[eType],
					bCheck = true, bMCheck = true,
					bChecked = eType == (dataset.szType == 'SKILL' and 'CONTROL_PLAYER' or dataset.szTarget),
					fnDisable = function()
						return dataset.szType == 'SKILL' and eType ~= 'CONTROL_PLAYER'
					end,
					fnAction = function()
						dataset.szTarget = eType
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'BUFF', 'SKILL'}) do
				table.insert(t, {
					szOption = _L.TYPE[eType],
					bCheck = true, bMCheck = true, bChecked = eType == dataset.szType,
					fnAction = function()
						dataset.szType = eType
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
					end,
				})
			end
			table.insert(t, { bDevide = true })
			for _, eType in ipairs({'LEFT', 'RIGHT', 'CENTER'}) do
				table.insert(t, {
					szOption = _L.ALIGNMENT[eType],
					bCheck = true, bMCheck = true, bChecked = eType == dataset.szAlignment,
					fnAction = function()
						dataset.szAlignment = eType
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
					end,
				})
			end
			return t
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	uiWnd:Append('WndComboBox', {
		x = xr + 105, y = nY, w = 165,
		text = _L['Only enable in those maps'],
		menu = function()
			local menu = X.GetDungeonMenu({
				fnAction = function(p)
					if not dataset.tMap then
						dataset.tMap = {}
					end
					dataset.tMap[p.dwID] = not dataset.tMap[p.dwID]
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY', dataset.szUUID, 'tMap')
				end,
				tChecked = dataset.tMap or {},
			})
			for i, p in ipairs(menu) do
				p.fnDisable = function() return X.IsEmpty(dataset.tMap) or dataset.tMap.bAll end
			end
			local t1 = {
				szOption = _L['Monitor Map Requirement By Type'],
				fnDisable = function() return X.IsEmpty(dataset.tMap) or dataset.tMap.bAll end,
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
					bChecked = dataset.tMap and dataset.tMap[eMapType],
					fnAction = function(_, bChecked)
						if not dataset.tMap then
							dataset.tMap = {}
						end
						dataset.tMap[eMapType] = bChecked
						FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY', dataset.szUUID, 'tMap')
					end,
					fnDisable = function() return X.IsEmpty(dataset.tMap) or dataset.tMap.bAll end,
				})
			end
			table.insert(menu, 1, t1)
			table.insert(menu, 1, {
				szOption = _L['Monitor All Maps'],
				bCheck = true,
				bChecked = X.IsEmpty(dataset.tMap) or dataset.tMap.bAll,
				fnAction = function(_, bChecked)
					if not dataset.tMap then
						dataset.tMap = {}
					end
					dataset.tMap.bAll = bChecked
					FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY', dataset.szUUID, 'tMap')
				end,
			})
			return menu
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + 24

	uiWnd:Append('WndSlider', {
		x = xr, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {1, 32},
		value = dataset.nMaxLineCount,
		textFormatter = function(val) return _L('Display %d eachline.', val) end,
		onChange = function(val)
			dataset.nMaxLineCount = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	uiWnd:Append('WndSlider', {
		x = xr, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {1, 300},
		value = dataset.fScale * 100,
		textFormatter = function(val) return _L('UI scale %d%%.', val) end,
		onChange = function(val)
			dataset.fScale = val / 100
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	uiWnd:Append('WndSlider', {
		x = xr, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {1, 300},
		value = dataset.fIconFontScale * 100,
		textFormatter = function(val) return _L('Icon font scale %d%%.', val) end,
		onChange = function(val)
			dataset.fIconFontScale = val / 100
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	uiWnd:Append('WndSlider', {
		x = xr, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {1, 300},
		value = dataset.fOtherFontScale * 100,
		textFormatter = function(val) return _L('Other font scale %d%%.', val) end,
		onChange = function(val)
			dataset.fOtherFontScale = val / 100
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	uiWnd:Append('WndSlider', {
		x = xr, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {50, 1000},
		value = dataset.nCdBarWidth,
		textFormatter = function(val) return _L('CD width %dpx.', val) end,
		onChange = function(val)
			dataset.nCdBarWidth = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	uiWnd:Append('WndSlider', {
		x = xr, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {-1, 30},
		value = dataset.nDecimalTime,
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
			dataset.nDecimalTime = val
			FireUIEvent('MY_TARGET_MON_CONFIG__DATASET_CONFIG_MODIFY')
		end,
		autoEnable = function() return dataset.bEnable end,
	})
	nY = nY + nDeltaY

	nY = nY + 30

	uiWnd:Append('WndButton', {
		x = (nW - 70) / 2, y = nY,
		w = 80, h = 35,
		text = _L['Delete'],
		color = { 255, 0, 0 },
		buttonStyle = 'FLAT',
		onClick = function()
			X.Confirm(_L['Sure to delete monitor? This operation can not be undone.'], function()
				MY_TargetMonConfig.DeleteDataset(szConfigUUID)
				MY_TargetMon_ConfigPanel.Close()
			end)
		end,
	})

	local parent = Station.Lookup('Normal/MY_TargetMon_PS')
	ui:Pos(parent:GetRelX() + (parent:GetW() - ui:Width()) / 2, parent:GetRelY() + (parent:GetH() - ui:Height()) / 2)
end

function D.Close()
	X.UI.CloseFrame('MY_TargetMon_ConfigPanel')
end

function D.OnFrameBreathe()
	local parent = Station.Lookup('Normal/MY_TargetMon_PS')
	if not parent then
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
	name = 'MY_TargetMon_ConfigPanel',
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
MY_TargetMon_ConfigPanel = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
