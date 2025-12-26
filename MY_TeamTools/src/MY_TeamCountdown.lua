--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队倒计时
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamCountdown'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamCountdown'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_TeamCountdown', _L['Raid'], {
	nCountdown = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_TeamCountdown'],
			_L['Team countdown seconds'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 5,
	},
})
local D = {}

function D.Open()
	if not X.IsClientPlayerTeamLeader() then
		X.OutputAnnounceMessage(_L['You are not leader!'])
		return
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		X.OutputAnnounceMessage(_L['Please unlock safety talk lock first!'])
		return
	end
	GetUserInput(_L['Team countdown seconds'], function(text)
		local nCountdown = tonumber(text)
		if not nCountdown then
			X.OutputAnnounceMessage(_L['Invalid countdown time input.'])
			return
		end
		if nCountdown > 10 then
			X.OutputAnnounceMessage(_L('Countdown time cannot be more than %ds.', 10))
			return
		end
		if nCountdown < 1 then
			X.OutputAnnounceMessage(_L('Countdown time cannot be less than %ds.', 1))
			return
		end
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamCountdown', {nCountdown}, true)
		O.nCountdown = nCountdown
	end, nil, nil, nil, tostring(O.nCountdown), 50)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nPaddingX
	nX, nY = ui:Append('Text', { x = nX, y = nY + 15, text = _L['MY_TeamCountdown'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = nPaddingX + 10
	nY = nY + 5
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY, w = 200,
		text = _L['Send team countdown'],
		buttonStyle = 'FLAT',
		onClick = D.Open,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 28

	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamCountdown',
	exports = {
		{
			fields = {
				Open = D.Open,
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_TeamCountdown = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------
X.RegisterBgMsg('MY_TeamCountdown', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not X.IsPlayerTeamLeader(dwTalkerID) then
		return
	end
	local nCountdown = data[1]
	if X.IsNumber(nCountdown) and nCountdown >= 1 and nCountdown <= 10 then
				if X.IsClientPlayerTeamLeader() then
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['[TeamCountdown] Fight Countdown Begin!'])
		end
		X.BreatheCall('MY_TeamCountdown', 1000, function()
			local szText = nCountdown == 0 and _L['Fight Begin'] or tostring(nCountdown)
			X.UI.CreateFloatText(szText, 1000, {
				nFont = 230,
				fScale = 10,
				nR = 255,
				nG = 255,
				nB = 0,
				szAnimation = 'ZOOM_IN_FADE_IN_OUT',
			})
			if X.IsClientPlayerTeamLeader() then
				X.SendChat(
					PLAYER_TALK_CHANNEL.RAID,
					nCountdown == 0
						and _L['[TeamCountdown] Fight Begin!']
						or _L('[TeamCountdown] %ds!', nCountdown)
				)
			end
			-- 喊话
			if nCountdown <= 0 then
				return 0
			end
			nCountdown = nCountdown - 1
		end)
	end
end)

X.RegisterHotKey('MY_TeamCountdown', _L['Open MY_TeamCountdown'], D.Open, nil)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
