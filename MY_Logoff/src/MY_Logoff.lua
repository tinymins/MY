--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 快速登出 指定条件退队/下线
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Logoff/MY_Logoff'
local PLUGIN_NAME = 'MY_Logoff'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Logoff'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_Logoff', _L['System'], {
	bIdleOff = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Logoff'],
		szDescription = X.MakeCaption({
			_L['Enable'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nIdleOffTime = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Logoff'],
		szDescription = X.MakeCaption({
			_L['Auto logoff when keep idle for'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 30,
	},
})

local function Logoff(bCompletely, bUnfight, bNotDead)
	if X.BreatheCall('MY_LOGOFF') then
		X.BreatheCall('MY_LOGOFF', false)
		X.OutputSystemMessage(_L['Logoff has been cancelled.'])
		return
	end
	local function onBreatheCall()
		local me = X.GetClientPlayer()
		if not me then
			return
		end
		if bUnfight and me.bFightState then
			return
		end
		if bNotDead and me.nMoveState == MOVE_STATE.ON_DEATH then
			return
		end
		X.Logout(bCompletely)
	end
	onBreatheCall()
	if bUnfight then
		X.OutputSystemMessage(_L['Logoff is ready for your casting unfight skill.'])
	end
	X.BreatheCall('MY_LOGOFF', onBreatheCall)
end

local function IdleOff()
	if not O.bIdleOff then
		if X.BreatheCall('MY_LOGOFF_IDLE') then
			X.OutputSystemMessage(_L['Idle off has been cancelled.'])
			X.BreatheCall('MY_LOGOFF_IDLE', false)
		end
		return
	end
	if X.BreatheCall('MY_LOGOFF_IDLE') then
		return
	end
	local function onBreatheCall()
		local nIdleTime = (Station.GetIdleTime()) / 1000 - 300
		local remainTime = O.nIdleOffTime * 60 - nIdleTime
		if remainTime <= 0 then
			return X.Logout(true)
		end
		if remainTime > 1200 and remainTime % 600 ~= 0 then
			return
		end
		if remainTime > 300 and remainTime % 300 ~= 0 then
			return
		end
		if remainTime > 10 and remainTime % 10 ~= 0 then
			return
		end
		if remainTime <= 60 then
			local szMessage = _L('Idle off notice: you\'ll auto logoff if you keep idle for %ds.', remainTime)
			if remainTime <= 10 then
				OutputMessage('MSG_ANNOUNCE_YELLOW', szMessage)
			end
			X.OutputSystemMessage(szMessage)
		else
			X.OutputSystemMessage(_L('Idle off notice: you\'ll auto logoff if you keep idle for %dm %ds.', remainTime / 60, remainTime % 60))
		end
	end
	X.BreatheCall('MY_LOGOFF_IDLE', 1000, onBreatheCall)
	X.OutputSystemMessage(_L('Idle off has been started, you\'ll auto logoff if you keep idle for %dm.', O.nIdleOffTime))
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

do
local menu = {
	szOption = _L['Express logoff'],
	{
		szOption = _L['Return to role list'],
		fnAction = function()
			Logoff(false)
		end,
	}, {
		szOption = _L['Return to game login'],
		fnAction = function()
			Logoff(true)
		end,
	}, {
		szOption = _L['Return to role list while not fight'],
		fnAction = function()
			Logoff(false, true)
		end,
	}, {
		szOption = _L['Return to game login while not fight'],
		fnAction = function()
			Logoff(true, true)
		end,
	}, {
		bDevide  = true,
	}, {
		szOption = _L['Set hotkey'],
		fnAction = function()
			X.SetHotKey()
		end,
	},
}
X.RegisterAddonMenu('MY_LOGOFF_MENU', menu)
end

X.RegisterHotKey('MY_LogOff_RUI', _L['Return to role list'], function() Logoff(false) end, nil)
X.RegisterHotKey('MY_LogOff_RRL', _L['Return to game login'], function() Logoff(true) end, nil)
X.RegisterHotKey('MY_LogOff_RUI_UNFIGHT', _L['Return to role list while not fight'], function() Logoff(false, true) end, nil)
X.RegisterHotKey('MY_LogOff_RRL_UNFIGHT', _L['Return to game login while not fight'], function() Logoff(true, true) end, nil)
X.RegisterHotKey('MY_LogOff_RUI_UNFIGHT_ALIVE', _L['Return to role list while not fight and not dead'], function() Logoff(false, true, true) end, nil)
X.RegisterHotKey('MY_LogOff_RRL_UNFIGHT_ALIVE', _L['Return to game login while not fight and not dead'], function() Logoff(true, true, true) end, nil)

local function onInit()
	X.DelayCall(2000, IdleOff)
end
X.RegisterUserSettingsInit('MY_Logoff', onInit)

--------------------------------------------------------------------------------
-- 界面注册
--------------------------------------------------------------------------------

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()

	-- 暂离登出
	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Idle logoff'], font = 27 })
	nY = nY + 35

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, text = _L['Enable'],
		checked = O.bIdleOff,
		onCheck = function(bChecked)
			O.bIdleOff = bChecked
			IdleOff()
		end,
	}):AutoWidth():Width() + 5

	ui:Append('WndSlider', {
		x = nX, y = nY, w = 150,
		textFormatter = function(val) return _L('Auto logoff when keep idle for %dmin.', val) end,
		range = {1, 1440},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.nIdleOffTime,
		onChange = function(val)
			O.nIdleOffTime = val
			X.DelayCall('MY_LOGOFF_IDLE_TIME_CHANGE', 500, IdleOff)
		end,
		autoEnable = function() return O.bIdleOff end,
	})
	nY = nY + 40

	-- 快速登出
	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Express logoff'], font = 27 })
	nY = nY + 35

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Return to role list'], buttonStyle = 'FLAT',
		onClick = function() Logoff(false) end,
	}):Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Return to role list while not fight'], buttonStyle = 'FLAT',
		onClick = function() Logoff(false,true) end,
	}):Width() + 5

	ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Hotkey setting'], buttonStyle = 'FLAT',
		onClick = function() X.SetHotKey() end,
	})
	nY = nY + 30

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Return to game login'], buttonStyle = 'FLAT',
		onClick = function() Logoff(true) end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY,
		text = _L['Return to game login while not fight'], buttonStyle = 'FLAT',
		onClick = function() Logoff(true,true) end,
	}):Width() + 5
	nY = nY + 30

	nX = nPaddingX
	nY = nY + 20
	ui:Append('Text', { x = nX, y = nY, w = nW - nX * 2, text = _L['Tips'], font = 27, multiline = true, alignVertical = 0 })
	nY = nY + 30
	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, w = nW - nX * 2, text = _L['MY_Logoff TIPS'], font = 27, multiline = true, alignVertical = 0 })
end
X.Panel.Register(_L['System'], 'Logoff', _L['Express logoff'], 'UI/Image/UICommon/LoginSchool.UITex|24', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
