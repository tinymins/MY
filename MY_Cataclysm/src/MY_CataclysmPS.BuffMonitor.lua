--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队面板BUFF设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Cataclysm/MY_CataclysmPS.BuffMonitor'
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_Cataclysm_BuffMonitor', { ['*'] = false, exp = false })
--------------------------------------------------------------------------------

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
		X.Panel.SwitchTab('MY_Cataclysm_BuffMonitor', true)
	end)
end

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 10, 10
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()
	local bRestricted = X.IsRestricted('MY_Cataclysm_BuffMonitor')

	if not bRestricted then
		nX = nPaddingX
		nX = nX + ui:Append('WndButton', {
			x = nX, y = nY, w = 100,
			buttonStyle = 'FLAT',
			text = _L['Add'],
			onClick = function()
				local rec = {}
				table.insert(CFG.aBuffList, rec)
				l_list:ListBox('insert', { id = rec, text = MY_Cataclysm.EncodeBuffRule(rec), data = rec })
				OpenBuffRuleEditor(rec)
			end,
		}):AutoHeight():Width() + 5
		nX = nX + ui:Append('WndButton', {
			x = nX, y = nY, w = 100,
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
						X.Panel.SwitchTab('MY_Cataclysm_BuffMonitor', true)
					end,
				})
			end,
		}):AutoHeight():Width() + 5
		nX = nPaddingX
		nY = nY + 30

		l_list = ui:Append('WndListBox', {
			x = nX, y = nY,
			w = nW - 240 - 20, h = nH - nY - 5,
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
		nY = nH
	end

	nPaddingX = X.IIf(bRestricted, 30, nW - 240)
	nX = nPaddingX
	nY = nPaddingY + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Auto scale'],
		checked = CFG.bAutoBuffSize,
		onCheck = function(bCheck)
			CFG.bAutoBuffSize = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndSlider', {
		x = nX, y = nY, h = 25, rw = 80,
		enable = not CFG.bAutoBuffSize,
		autoEnable = function() return not CFG.bAutoBuffSize end,
		range = {50, 200},
		value = CFG.fBuffScale * 100,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			CFG.fBuffScale = nVal / 100
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
		textFormatter = function(val) return _L('%d%%', val) end,
	}):AutoWidth():Width() + 10

	nX = nPaddingX
	nY = nY + 30
	nX = nX + ui:Append('Text', { x = nX, y = nY, h = 25, text = _L['Max count']}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndSlider', {
		x = nX, y = nY, h = 25, rw = 80, text = '',
		range = {0, 10},
		value = CFG.nMaxShowBuff,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			CFG.nMaxShowBuff = nVal
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 8

	nX = nPaddingX
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Push buff to official'],
		checked = CFG.bBuffPushToOfficial,
		onCheck = function(bCheck)
			CFG.bBuffPushToOfficial = bCheck
			MY_CataclysmMain.UpdateBuffListCache()
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Buff Staring'],
		checked = CFG.bStaring,
		onCheck = function(bCheck)
			CFG.bStaring = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Buff Time'],
		checked = CFG.bShowBuffTime,
		onCheck = function(bCheck)
			CFG.bShowBuffTime = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Over mana bar'],
		checked = not CFG.bBuffAboveMana,
		onCheck = function(bCheck)
			CFG.bBuffAboveMana = not bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Buff Num'],
		checked = CFG.bShowBuffNum,
		onCheck = function(bCheck)
			CFG.bShowBuffNum = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Show Buff Reminder'],
		checked = CFG.bShowBuffReminder,
		onCheck = function(bCheck)
			CFG.bShowBuffReminder = bCheck
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Alt Click Publish'],
		checked = CFG.bBuffAltPublish,
		onCheck = function(bCheck)
			CFG.bBuffAltPublish = bCheck
		end,
	}):AutoWidth():Width() + 5
	nY = nY + 30

	nX = nPaddingX
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable official data'],
		checked = CFG.bBuffDataOfficial,
		onCheck = function(bCheck)
			CFG.bBuffDataOfficial = bCheck
			MY_CataclysmMain.UpdateBuffListCache()
			X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
		end,
		autoEnable = function() return _G.MY_Resource and true end,
	}):AutoWidth():Width() + 5
	nY = nY + 30

	if not bRestricted then
		nX = nPaddingX
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Enable MY_TeamMon data'],
			checked = CFG.bBuffDataTeamMon,
			onCheck = function(bCheck)
				CFG.bBuffDataTeamMon = bCheck
				MY_CataclysmMain.UpdateBuffListCache()
				X.DelayCall('MY_Cataclysm_Reload', 300, D.ReloadCataclysmPanel)
			end,
			autoEnable = function() return _G.MY_Resource and true end,
		}):AutoWidth():Width() + 5
		nY = nY + 30
	end
end
function PS.OnPanelDeactive()
	l_list = nil
end
X.Panel.Register(_L['Raid'], 'MY_Cataclysm_BuffMonitor', _L['Buff settings'], 'ui/Image/UICommon/RaidTotal.uitex|65', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
