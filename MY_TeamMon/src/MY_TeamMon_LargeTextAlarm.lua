--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 大字提醒
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_LargeTextAlarm'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_TeamMon_LargeTextAlarm', { ['*'] = true, intl = false, exp = true })
--------------------------------------------------------------------------------

local INI_FILE = X.PACKET_INFO.ROOT ..  'MY_TeamMon/ui/MY_TeamMon_LargeTextAlarm.ini'

local O = X.CreateUserSettingsModule('MY_TeamMon_LargeTextAlarm', _L['Raid'], {
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_LargeTextAlarm'],
			_L['UI Anchor'],
		}),
		szRestriction = 'MY_TeamMon_LargeTextAlarm',
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 },
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_LargeTextAlarm'],
			_L['Font scale'],
		}),
		szRestriction = 'MY_TeamMon_LargeTextAlarm',
		xSchema = X.Schema.Number,
		xDefaultValue = 1.5,
	},
	fPause = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_LargeTextAlarm'],
			_L['Pause time'],
		}),
		szRestriction = 'MY_TeamMon_LargeTextAlarm',
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	fFadeOut = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_LargeTextAlarm'],
			_L['FadeOut time'],
		}),
		szRestriction = 'MY_TeamMon_LargeTextAlarm',
		xSchema = X.Schema.Number,
		xDefaultValue = 0.3,
	},
	dwFontScheme = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		szDescription = X.MakeCaption({
			_L['MY_TeamMon_LargeTextAlarm'],
			g_tStrings.FONT,
		}),
		szRestriction = 'MY_TeamMon_LargeTextAlarm',
		xSchema = X.Schema.Number,
		xDefaultValue = 23,
	},
})
local D = {}

function D.OnFrameCreate()
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('MY_TEAM_MON__LARGE_TEXT_ALARM')
	D.UpdateAnchor(this)
	D.frame = this
	D.txt = this:Lookup('', 'Text_Total')
end

function D.OnEvent(szEvent)
	if szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		if X.IsRestricted('MY_TeamMon_LargeTextAlarm') then
			return
		end
		if szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
			D.frame:Hide()
		else
			D.frame:FadeIn(0)
			D.frame:SetAlpha(255)
			D.frame:Show()
		end
		UpdateCustomModeWindow(this, _L['MY_TeamMon_LargeTextAlarm'], true)
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'MY_TEAM_MON__LARGE_TEXT_ALARM' then
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

function D.UpdateText(txt, col)
	if X.IsRestricted('MY_TeamMon_LargeTextAlarm') then
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
	X.BreatheCall('MY_TeamMon_LargeTextAlarm', D.OnBreathe)
end

function D.OnBreathe()
	local nTime = GetTime()
	if D.nTime and (nTime - D.nTime) / 1000 > O.fPause then
		D.nTime = nil
		D.frame:FadeOut(O.fFadeOut * 10)
		X.BreatheCall('MY_TeamMon_LargeTextAlarm', false)
	end
end

function D.CheckEnable()
	X.UI.CloseFrame('MY_TeamMon_LargeTextAlarm')
	if X.IsRestricted('MY_TeamMon_LargeTextAlarm') then
		return
	end
	X.UI.OpenFrame(INI_FILE, 'MY_TeamMon_LargeTextAlarm')
end

function D.Init()
	D.CheckEnable()
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_LargeTextAlarm',
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
MY_TeamMon_LargeTextAlarm = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_TeamMon_LargeTextAlarm', D.Init)

X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon_LargeTextAlarm', function()
	if arg0 and arg0 ~= 'MY_TeamMon_LargeTextAlarm' then
		return
	end
	D.CheckEnable()
end)

--------------------------------------------------------------------------------
-- 界面注册
--------------------------------------------------------------------------------

local PS = { nPriority = 12, szRestriction = 'MY_TeamMon_LargeTextAlarm' }
function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['MY_TeamMon_LargeTextAlarm'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = ui:Append('Text', { text = _L['Font scale'], x = nPaddingX + 10, y = nY + 10 }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndSlider', {
		x = nX + 10, y = nY + 13, text = '',
		range = {1, 2, 10}, value = O.fScale,
		onChange = function(nVal)
			O.fScale = nVal
			ui:Children('#Text_Preview'):Font(O.dwFontScheme):scale(O.fScale)
		end,
	}):Pos('BOTTOMRIGHT')

	nX = ui:Append('Text', { text = _L['Pause time'], x = nPaddingX + 10, y = nY }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndSlider', {
		x = nX + 10, y = nY + 3, text = _L['s'],
		range = {0.5, 3, 25}, value = O.fPause,
		onChange = function(nVal)
			O.fPause = nVal
		end,
	}):Pos('BOTTOMRIGHT')

	nX = ui:Append('Text', { text = _L['FadeOut time'], x = nPaddingX + 10, y = nY }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndSlider', {
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
X.Panel.Register(_L['Raid'], 'MY_TeamMon_LargeTextAlarm', _L['MY_TeamMon_LargeTextAlarm'], 'ui/Image/TargetPanel/Target.uitex|59', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
