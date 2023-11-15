--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 目标监控配置相关
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon.PS'

local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local C, D = {}, {
	GetTargetTypeList  = MY_TargetMonConfig.GetTargetTypeList ,
	LoadConfig         = MY_TargetMonConfig.LoadConfig        ,
	SaveConfig         = MY_TargetMonConfig.SaveConfig        ,
	GetConfigCaption   = MY_TargetMonConfig.GetConfigCaption  ,
	ImportPatchFile    = MY_TargetMonConfig.ImportPatchFile   ,
	ExportPatchFile    = MY_TargetMonConfig.ExportPatchFile   ,
	GetConfigList      = MY_TargetMonConfig.GetConfigList     ,
	CreateConfig       = MY_TargetMonConfig.CreateConfig      ,
	MoveConfig         = MY_TargetMonConfig.MoveConfig        ,
	ModifyConfig       = MY_TargetMonConfig.ModifyConfig      ,
	DeleteConfig       = MY_TargetMonConfig.DeleteConfig      ,
	CreateMonitor      = MY_TargetMonConfig.CreateMonitor     ,
	MoveMonitor        = MY_TargetMonConfig.MoveMonitor       ,
	ModifyMonitor      = MY_TargetMonConfig.ModifyMonitor     ,
	DeleteMonitor      = MY_TargetMonConfig.DeleteMonitor     ,
	CreateMonitorId    = MY_TargetMonConfig.CreateMonitorId   ,
	ModifyMonitorId    = MY_TargetMonConfig.ModifyMonitorId   ,
	DeleteMonitorId    = MY_TargetMonConfig.DeleteMonitorId   ,
	CreateMonitorLevel = MY_TargetMonConfig.CreateMonitorLevel,
	ModifyMonitorLevel = MY_TargetMonConfig.ModifyMonitorLevel,
	DeleteMonitorLevel = MY_TargetMonConfig.DeleteMonitorLevel,
}
local CUSTOM_BOXBG_STYLES = {
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
local CUSTOM_BOX_EXTENT_ANIMATE = {
	{nil, _L['None']},
	{'ui/Image/Common/Box.UITex|17'},
	{'ui/Image/Common/Box.UITex|20'},
}
local CUSTOM_CDBAR_STYLES = {
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
		x = nPaddingX, y = nY, text = _L['Use common data'],
		checked = MY_TargetMonConfig.bCommon,
		onCheck = function(bCheck)
			MY_TargetMonConfig.bCommon = bCheck
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
			MY_TargetMon_PS.Open()
		end,
	})
end

function PS.OnPanelScroll(wnd, scrollX, scrollY)
	wnd:Lookup('WndWindow_Wrapper'):SetRelPos(scrollX, scrollY)
end
X.RegisterPanel(_L['Target'], 'MY_TargetMon', _L['Target monitor'], 'ui/Image/ChannelsPanel/NewChannels.UITex|141', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
