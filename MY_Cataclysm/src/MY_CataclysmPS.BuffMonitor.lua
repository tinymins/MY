--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板BUFF设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
X.RegisterRestriction('MY_Cataclysm_BuffMonitor', { ['*'] = false, classic = true })
--------------------------------------------------------------------------

local D = {
	ReloadCataclysmPanel = MY_CataclysmMain.ReloadCataclysmPanel,
}
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 5 }

-- 解析
local function EncodeBuffRuleList(aBuffList)
	local aName = {}
	for _, v in ipairs(aBuffList) do
		table.insert(aName, MY_Cataclysm.EncodeBuffRule(v))
	end
	return table.concat(aName, '\n')
end

local function DecodeBuffRuleList(szText)
	local aBuffList = {}
	for _, v in ipairs(X.SplitString(szText, '\n')) do
		v = MY_Cataclysm.DecodeBuffRule(v)
		if v then
			table.insert(aBuffList, v)
		end
	end
	return aBuffList
end

local l_list
local function OpenBuffRuleEditor(rec)
	MY_Cataclysm.OpenBuffRuleEditor(rec, function(p)
		if p then
			if l_list then
				l_list:ListBox('update', 'id', rec, {'text'}, {MY_Cataclysm.EncodeBuffRule(rec)})
			end
			MY_CataclysmMain.UpdateBuffListCache()
		else
			for i, p in ipairs(CFG.aBuffList) do
				if p == rec then
					if l_list then
						l_list:ListBox('delete', 'id', rec)
					end
					table.remove(CFG.aBuffList, i)
					MY_CataclysmMain.UpdateBuffListCache()
					break
				end
			end
		end
	end, function()
		CFG.aBuffList = CFG.aBuffList
		X.SwitchTab('MY_Cataclysm_BuffMonitor', true)
	end)
end

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 10, 10
	local x, y = nPaddingX, nPaddingY
	local w, h = ui:Size()
	local bRestricted = X.IsRestricted('MY_Cataclysm_BuffMonitor')

	if not bRestricted then
		x = nPaddingX
		x = x + ui:Append('WndButton', {
			x = x, y = y, w = 100,
			buttonStyle = 'FLAT',
			text = _L['Add'],
			onClick = function()
				local rec = {}
				table.insert(CFG.aBuffList, rec)
				l_list:ListBox('insert', { id = rec, text = MY_Cataclysm.EncodeBuffRule(rec), data = rec })
				OpenBuffRuleEditor(rec)
			end,
		}):AutoHeight():Width() + 5
		x = x + ui:Append('WndButton', {
			x = x, y = y, w = 100,
			buttonStyle = 'FLAT',
			text = _L['Edit'],
			onClick = function()
				local ui = X.UI.CreateFrame('MY_Cataclysm_BuffConfig', {
					w = 350, h = 550,
					text = _L['Edit buff'],
					close = true, anchor = 'CENTER',
				})
				local x, y = 20, 60
				local edit = ui:Append('WndEditBox',{
					x = x, y = y, w = 310, h = 440,
					limit = -1, multiline = true,
					text = EncodeBuffRuleList(CFG.aBuffList),
				})
				y = y + edit:Height() + 5

				ui:Append('WndButton', {
					x = x, y = y, w = 310,
					text = _L['Sure'],
					buttonStyle = 'FLAT',
					onClick = function()
						CFG.aBuffList = DecodeBuffRuleList(edit:Text())
						MY_CataclysmMain.UpdateBuffListCache()
						ui:Remove()
						X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
						X.SwitchTab('MY_Cataclysm_BuffMonitor', true)
					end,
				})
			end,
		}):AutoHeight():Width() + 5
		x = nPaddingX
		y = y + 30

		l_list = ui:Append('WndListBox', {
			x = x, y = y,
			w = w - 240 - 20, h = h - y - 5,
			listBox = {{
				'onlclick',
				function(id, szText, data, bSelected)
					OpenBuffRuleEditor(data)
					return false
				end,
			}},
		})
		for _, rec in ipairs(CFG.aBuffList) do
			l_list:ListBox('insert', { id = rec, text = MY_Cataclysm.EncodeBuffRule(rec), data = rec })
		end
		y = h
	end

	nPaddingX = X.IIf(bRestricted, 30, w - 240)
	x = nPaddingX
	y = nPaddingY + 25
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Auto scale'],
		checked = CFG.bAutoBuffSize,
		onCheck = function(bCheck)
			CFG.bAutoBuffSize = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y, h = 25, rw = 80,
		enable = not CFG.bAutoBuffSize,
		autoEnable = function() return not CFG.bAutoBuffSize end,
		range = {50, 200},
		value = CFG.fBuffScale * 100,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			CFG.fBuffScale = nVal / 100
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
		textFormatter = function(val) return _L('%d%%', val) end,
	}):AutoWidth():Width() + 10

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('Text', { x = x, y = y, h = 25, text = _L['Max count']}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y, h = 25, rw = 80, text = '',
		range = {0, 10},
		value = CFG.nMaxShowBuff,
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			CFG.nMaxShowBuff = nVal
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 8

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Push buff to official'],
		checked = CFG.bBuffPushToOfficial,
		onCheck = function(bCheck)
			CFG.bBuffPushToOfficial = bCheck
			MY_CataclysmMain.UpdateBuffListCache()
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Buff Staring'],
		checked = CFG.bStaring,
		onCheck = function(bCheck)
			CFG.bStaring = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Time'],
		checked = CFG.bShowBuffTime,
		onCheck = function(bCheck)
			CFG.bShowBuffTime = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Over mana bar'],
		checked = not CFG.bBuffAboveMana,
		onCheck = function(bCheck)
			CFG.bBuffAboveMana = not bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Num'],
		checked = CFG.bShowBuffNum,
		onCheck = function(bCheck)
			CFG.bShowBuffNum = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Buff Reminder'],
		checked = CFG.bShowBuffReminder,
		onCheck = function(bCheck)
			CFG.bShowBuffReminder = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	x = nPaddingX
	y = y + 30
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Alt Click Publish'],
		checked = CFG.bBuffAltPublish,
		onCheck = function(bCheck)
			CFG.bBuffAltPublish = bCheck
		end,
	}):AutoWidth():Width() + 5
	y = y + 30

	x = nPaddingX
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Enable official data'],
		checked = CFG.bBuffDataOfficial,
		onCheck = function(bCheck)
			CFG.bBuffDataOfficial = bCheck
			MY_CataclysmMain.UpdateBuffListCache()
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
		autoEnable = function() return MY_Resource and true end,
	}):AutoWidth():Width() + 5
	y = y + 30

	if not bRestricted then
		x = nPaddingX
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Enable MY_TeamMon data'],
			checked = CFG.bBuffDataTeamMon,
			onCheck = function(bCheck)
				CFG.bBuffDataTeamMon = bCheck
				MY_CataclysmMain.UpdateBuffListCache()
				X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
			end,
			autoEnable = function() return MY_Resource and true end,
		}):AutoWidth():Width() + 5
		y = y + 30
	end
end
function PS.OnPanelDeactive()
	l_list = nil
end
X.RegisterPanel(_L['Raid'], 'MY_Cataclysm_BuffMonitor', _L['Buff settings'], 'ui/Image/UICommon/RaidTotal.uitex|65', PS)
