--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon.PS'

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

----------------------------------------------------------------------------------------------
-- 设置界面
----------------------------------------------------------------------------------------------
local PS = { szRestriction = 'MY_TargetMon' }

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Data save mode'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = nPaddingX + 10
	nX, nY = ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Use common data'],
		checked = MY_TargetMonConfig.bCommon,
		onCheck = function(bCheck)
			MY_TargetMonConfig.bCommon = bCheck
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nY = nY + 10

	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['View render config'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = nPaddingX + 10
	nX, nY = ui:Append('WndSlider', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Use common data'],
		value = MY_TargetMonConfig.nInterval,
		range = {1, 16},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		textFormatter = function(v) return _L('View render interval: every %d frame', v) end,
		onChange = function(val)
			MY_TargetMonConfig.nInterval = val
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nY = nY + 10

	nX = nPaddingX
	nX, nY = ui:Append('Text', { x = nPaddingX, y = nY + 5, text = _L['Data settings'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
	nX = nPaddingX + 10
	ui:Append('WndButton', {
		x = nX, y = nY, w = 150, h = 28,
		text = _L['Open config panel'],
		buttonStyle = 'FLAT',
		onClick = function()
			MY_TargetMon_PS.OpenPanel()
		end,
	})
end

function PS.OnPanelScroll(wnd, scrollX, scrollY)
	wnd:Lookup('WndWindow_Wrapper'):SetRelPos(scrollX, scrollY)
end
X.Panel.Register(_L['Target'], 'MY_TargetMon', _L['Target monitor'], 'ui/Image/ChannelsPanel/NewChannels.UITex|141', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
