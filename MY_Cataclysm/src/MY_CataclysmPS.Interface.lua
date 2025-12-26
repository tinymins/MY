--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队面板样式设置
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Cataclysm/MY_CataclysmPS.Interface'
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
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 4 }
local CTM_BG_COLOR_MODE = MY_Cataclysm.BG_COLOR_MODE

function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local x, y = nPaddingX, nPaddingY

	y = y + ui:Append('Text', { x = x, y = y, text = _L['Interface settings'], font = 27 }):Height()

	x = nPaddingX + 10
	y = y + 3
	x = x + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Official team frame style'],
		group = 'CSS', checked = CFG.eFrameStyle == 'OFFICIAL',
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.eFrameStyle = 'OFFICIAL'
			MY_CataclysmMain.ReloadCataclysmPanel()
		end,
	}):AutoWidth():Width() + 5

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Cataclysm team frame style'],
		group = 'CSS', checked = CFG.eFrameStyle == 'CATACLYSM',
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.eFrameStyle = 'CATACLYSM'
			MY_CataclysmMain.ReloadCataclysmPanel()
		end,
	}):AutoWidth():Height()

	x = nPaddingX + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Interface Width']}):AutoWidth():Width() + 5
	y = y + ui:Append('WndSlider', {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = CFG.fScaleX * 100,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = nVal / CFG.fScaleX, CFG.fScaleY / CFG.fScaleY
			CFG.fScaleX = nVal
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:Scale(nNewX, nNewY)
			end
		end,
		textFormatter = function(val) return _L('%d%%', val) end,
	}):Height()

	x = nPaddingX + 10
	x = x + ui:Append('Text', { x = x, y = y, text = _L['Interface Height']}):AutoWidth():Width() + 5
	y = y + ui:Append('WndSlider', {
		x = x, y = y + 3, h = 25, w = 250,
		range = {50, 250},
		value = CFG.fScaleY * 100,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			nVal = nVal / 100
			local nNewX, nNewY = CFG.fScaleX / CFG.fScaleX, nVal / CFG.fScaleY
			CFG.fScaleY = nVal
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:Scale(nNewX, nNewY)
			end
		end,
		textFormatter = function(val) return _L('%d%%', val) end,
	}):Height()

	x = nPaddingX
	y = y + 10
	y = y + ui:Append('Text', { x = x, y = y, text = g_tStrings.OTHER, font = 27 }):Height()

	x = x + 10
	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Group Number'],
		checked = CFG.bShowGroupNumber,
		onCheck = function(bCheck)
			CFG.bShowGroupNumber = bCheck
			MY_CataclysmMain.ReloadCataclysmPanel()
		end,
	}):Height()

	if CFG.nBGColorMode ~= CTM_BG_COLOR_MODE.OFFICIAL then
		x = x + ui:Append('Text', { x = x, y = y, text = g_tStrings.STR_ALPHA }):AutoWidth():Width() + 5
		y = y + ui:Append('WndSlider', {
			x = x, y = y + 3,
			range = {0, 255},
			value = CFG.nAlpha,
			sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
			onChange = function(nVal)
				CFG.nAlpha = nVal
				if MY_CataclysmMain.GetFrame() then
					FireUIEvent('MY_CATACLYSM_SET_ALPHA')
				end
			end,
			textFormatter = function(val) return _L('%d%%', val / 255 * 100) end,
		}):Height()
	end

	x = nPaddingX
	y = y + 10
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Arrangement'], font = 27 }):Height()

	x = x + 10
	y = y + 3
	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['One lines: 5/0'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 5,
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 5
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_CataclysmMain.SetFrameSize()
			end
		end,
	}):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 1/4'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 1,
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 1
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_CataclysmMain.SetFrameSize()
			end
		end,
	}):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 2/3'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 2,
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 2
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_CataclysmMain.SetFrameSize()
			end
		end,
	}):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 3/2'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 3,
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 3
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_CataclysmMain.SetFrameSize()
			end
		end,
	}):AutoWidth():Height() + 3

	y = y + ui:Append('WndRadioBox', {
		x = x, y = y, text = _L['Two lines: 4/1'],
		group = 'Arrangement', checked = CFG.nAutoLinkMode == 4,
		onCheck = function(bChecked)
			if not bChecked then
				return
			end
			CFG.nAutoLinkMode = 4
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:AutoLinkAllPanel()
				MY_CataclysmMain.SetFrameSize()
			end
		end,
	}):AutoWidth():Height() + 3
end
X.Panel.Register(_L['Raid'], 'MY_Cataclysm_Interface', _L['Interface settings'], 'ui/Image/UICommon/RaidTotal.uitex|74', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
