--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ËæÉí±ã¼ã
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
	return
end
--------------------------------------------------------------------------
local ROLE_MEMO = {
	bEnable = false,
	nWidth = 200,
	nHeight = 200,
	szContent = '',
	nFont = 0,
	anchor = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -310, y = 135 },
}
local GLOBAL_MEMO = {
	bEnable = false,
	nWidth = 200,
	nHeight = 200,
	szContent = '',
	nFont = 0,
	anchor = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -310, y = 335 },
}
local D = {}

function D.Reload(bGlobal)
	local CFG_O = bGlobal and GLOBAL_MEMO or ROLE_MEMO
	local CFG = setmetatable({}, {
		__index = CFG_O,
		__newindex = function(t, k, v)
			CFG_O[k] = v
			X.DelayCall('MY_Memo_SaveConfig', D.SaveConfig)
		end,
	})
	local NAME = bGlobal and 'MY_MemoGlobal' or 'MY_MemoRole'
	local TITLE = bGlobal and _L['MY Memo (Global)'] or _L['MY Memo (Role)']
	UI('Normal/' .. NAME):Remove()
	if CFG.bEnable then
		UI.CreateFrame(NAME, {
			simple = true, alpha = 140,
			maximize = true, minimize = true, dragresize = true,
			minwidth = 180, minheight = 100,
			onmaximize = function(wnd)
				local ui = UI(wnd)
				ui:Children('#WndEditBox_Memo'):Size(ui:Size())
			end,
			onrestore = function(wnd)
				local ui = UI(wnd)
				ui:Children('#WndEditBox_Memo'):Size(ui:Size())
			end,
			ondragresize = function(wnd)
				local ui = UI(wnd:GetRoot())
				CFG.nWidth  = ui:Width()
				CFG.anchor  = ui:Anchor()
				CFG.nHeight = ui:Height()
				local ui = UI(wnd)
				ui:Children('#WndEditBox_Memo'):Size(ui:Size())
			end,
			w = CFG.nWidth, h = CFG.nHeight, text = TITLE,
			draggable = true, dragArea = {0, 0, CFG.nWidth, 30},
			anchor = CFG.anchor,
			events = {{ 'UI_SCALED', function() UI(this):Anchor(CFG.anchor) end }},
			uiEvents = {{ 'OnFrameDragEnd', function() CFG.anchor = UI('Normal/' .. NAME):Anchor() end }},
		}):Append('WndEditBox', {
			name = 'WndEditBox_Memo',
			x = 0, y = 0, w = CFG.nWidth, h = CFG.nHeight - 30,
			text = CFG.szContent, multiline = true,
			font = CFG.nFont,
			onChange = function(text) CFG.szContent = text end,
		})
	end
end

function D.LoadConfig()
	local CFG = X.LoadLUAData({'config/memo.jx3dat', X.PATH_TYPE.GLOBAL})
	if CFG then
		for k, v in pairs(CFG) do
			GLOBAL_MEMO[k] = v
		end
	end

	local CFG = X.LoadLUAData({'config/memo.jx3dat', X.PATH_TYPE.ROLE})
	if CFG then
		for k, v in pairs(CFG) do
			ROLE_MEMO[k] = v
		end
		ROLE_MEMO.bEnableGlobal = nil
		GLOBAL_MEMO.bEnable = CFG.bEnableGlobal
	end
end

function D.SaveConfig()
	local CFG = {}
	for k, v in pairs(ROLE_MEMO) do
		CFG[k] = v
	end
	CFG.bEnableGlobal = GLOBAL_MEMO.bEnable
	X.SaveLUAData({'config/memo.jx3dat', X.PATH_TYPE.ROLE}, CFG)

	local CFG = {}
	for k, v in pairs(GLOBAL_MEMO) do
		CFG[k] = v
	end
	CFG.bEnable = nil
	X.SaveLUAData({'config/memo.jx3dat', X.PATH_TYPE.GLOBAL}, CFG)
end

function D.IsEnable(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.bEnable
	end
	return ROLE_MEMO.bEnable
end

function D.Toggle(bGlobal, bEnable)
	(bGlobal and GLOBAL_MEMO or ROLE_MEMO).bEnable = bEnable
	D.SaveConfig()
	D.Reload(bGlobal)
end

function D.GetFont(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.nFont
	end
	return ROLE_MEMO.nFont
end

function D.SetFont(bGlobal, nFont)
	(bGlobal and GLOBAL_MEMO or ROLE_MEMO).nFont = nFont
	D.SaveConfig()
	D.Reload(bGlobal)
end

do
local function onInit()
	D.LoadConfig()
	D.Reload(true)
	D.Reload(false)
end
X.RegisterInit('MY_ANMERKUNGEN_PLAYERNOTE', onInit)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Memo (Role)'],
		checked = D.IsEnable(false),
		onCheck = function(bChecked)
			D.Toggle(false, bChecked)
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Font'],
		onClick = function()
			UI.OpenFontPicker(function(nFont)
				D.SetFont(false, nFont)
			end)
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Memo (Global)'],
		checked = D.IsEnable(true),
		onCheck = function(bChecked)
			D.Toggle(true, bChecked)
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Font'],
		onClick = function()
			UI.OpenFontPicker(function(nFont)
				D.SetFont(true, nFont)
			end)
		end,
	}):AutoWidth():Width() + 5
	nY = nY + nLH
	nX = nPaddingX
	return nX, nY
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_Memo',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_Memo = X.CreateModule(settings)
end
