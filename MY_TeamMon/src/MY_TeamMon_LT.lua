--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ´ó×ÖÌáÐÑ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_LT'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TeamMon_LT', { ['*'] = true })
--------------------------------------------------------------------------

local INIFILE = X.PACKET_INFO.ROOT ..  'MY_TeamMon/ui/MY_TeamMon_LT.ini'

local O = X.CreateUserSettingsModule('MY_TeamMon_LT', _L['Raid'], {
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1.5,
	},
	fPause = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	fFadeOut = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 0.3,
	},
	dwFontScheme = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 23,
	},
})
local D = {}

function D.OnFrameCreate()
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('MY_TM_LARGE_TEXT')
	D.UpdateAnchor(this)
	D.frame = this
	D.txt = this:Lookup('', 'Text_Total')
end

function D.OnEvent(szEvent)
	if szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		if X.IsRestricted('MY_TeamMon_LT') then
			return
		end
		if szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
			D.frame:Hide()
		else
			D.frame:FadeIn(0)
			D.frame:SetAlpha(255)
			D.frame:Show()
		end
		UpdateCustomModeWindow(this, _L['MY_TeamMon_LT'], true)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'MY_TM_LARGE_TEXT' then
		D.UpdateText(arg0, arg1)
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this)
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	if not X.IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	end
end

function D.Init()
	Wnd.CloseWindow('MY_TeamMon_LT')
	Wnd.OpenWindow(INIFILE, 'MY_TeamMon_LT')
end

function D.UpdateText(txt, col)
	if X.IsRestricted('MY_TeamMon_LT') then
		return
	end
	if not col then
		col = { 255, 128, 0 }
	end
	D.txt:SetText(txt)
	D.txt:SetFontScheme(O.dwFontScheme)
	D.txt:SetFontScale(O.fScale)
	D.txt:SetFontColor(unpack(col))
	D.frame:FadeIn(0)
	D.frame:SetAlpha(255)
	D.frame:Show()
	D.nTime = GetTime()
	X.BreatheCall('MY_TeamMon_LT', D.OnBreathe)
end

function D.OnBreathe()
	local nTime = GetTime()
	if D.nTime and (nTime - D.nTime) / 1000 > O.fPause then
		D.nTime = nil
		D.frame:FadeOut(O.fFadeOut * 10)
		X.BreatheCall('MY_TeamMon_LT', false)
	end
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_TeamMon_LT', D.Init)

local PS = { szRestriction = 'MY_TeamMon_LT' }
function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['MY_TeamMon_LT'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = ui:Append('Text', { text = _L['Font scale'], x = nPaddingX + 10, y = nY + 10 }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nX + 10, y = nY + 13, text = '',
		range = {1, 2, 10}, value = O.fScale,
		onChange = function(nVal)
			O.fScale = nVal
			ui:Children('#Text_Preview'):Font(O.dwFontScheme):scale(O.fScale)
		end,
	}):Pos('BOTTOMRIGHT')

	nX = ui:Append('Text', { text = _L['Pause time'], x = nPaddingX + 10, y = nY }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nX + 10, y = nY + 3, text = _L['s'],
		range = {0.5, 3, 25}, value = O.fPause,
		onChange = function(nVal)
			O.fPause = nVal
		end,
	}):Pos('BOTTOMRIGHT')

	nX = ui:Append('Text', { text = _L['FadeOut time'], x = nPaddingX + 10, y = nY }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndTrackbar', {
		x = nX + 10, y = nY + 3, text = _L['s'],
		range = {0, 3, 30}, value = O.fFadeOut,
		onChange = function(nVal)
			O.fFadeOut = nVal
		end,
	}):Pos('BOTTOMRIGHT')

	nY = nY + 10
	nX = ui:Append('WndButton', {
		x = nPaddingX + 10, y = nY + 5,
		text = g_tStrings.FONT,
		buttonStyle = 'FLAT',
		onClick = function()
			X.UI.OpenFontPicker(function(nFont)
				O.dwFontScheme = nFont
				ui:Children('#Text_Preview'):Font(O.dwFontScheme):scale(O.fScale)
			end)
		end,
	}):Pos('BOTTOMRIGHT')
	ui:Append('WndButton', {
		x = nX + 10, y = nY + 5,
		text = _L['Preview'],
		buttonStyle = 'FLAT',
		onClick = function()
			D.UpdateText(_L['PVE everyday, Xuanjing everyday!'])
		end,
	})
	ui:Append('Text', { name = 'Text_Preview', x = 20, y = nY + 50, txt = _L['JX3'], font = O.dwFontScheme, scale = O.fScale})
end
X.RegisterPanel(_L['Raid'], 'MY_TeamMon_LT', _L['MY_TeamMon_LT'], 'ui/Image/TargetPanel/Target.uitex|59', PS)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_LT',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'tAnchor',
				'fScale',
				'fPause',
				'fFadeOut',
				'dwFontScheme',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'tAnchor',
				'fScale',
				'fPause',
				'fFadeOut',
				'dwFontScheme',
			},
			root = O,
		},
	},
}
MY_TeamMon_LT = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
