--
-- 快速登出
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140411
--
-- 主要功能:
-- 1.指定条件退队/下线
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Logoff/lang/')

MY_Logoff = {}
MY_Logoff.bIdleOff = false
MY_Logoff.nIdleOffTime = 30
RegisterCustomData('MY_Logoff.bIdleOff')
RegisterCustomData('MY_Logoff.nIdleOffTime')

local function Logoff(bCompletely, bUnfight, bNotDead)
	if MY.BreatheCall('MY_LOGOFF') then
		MY.BreatheCall('MY_LOGOFF', false)
		MY.Sysmsg({_L['Logoff has been cancelled.']})
		return
	end
	local function onBreatheCall()
		local me = GetClientPlayer()
		if not me then
			return
		end
		if bUnfight and me.bFightState then
			return
		end
		if bNotDead and me.nMoveState == MOVE_STATE.ON_DEATH then
			return
		end
		MY.Logout(bCompletely)
	end
	onBreatheCall()
	if bUnfight then
		MY.Sysmsg({_L['Logoff is ready for your casting unfight skill.']})
	end
	MY.BreatheCall('MY_LOGOFF', onBreatheCall)
end

local function IdleOff()
	if not MY_Logoff.bIdleOff then
		if MY.BreatheCall('MY_LOGOFF_IDLE') then
			MY.Sysmsg({_L['Idle off has been cancelled.']})
			MY.BreatheCall('MY_LOGOFF_IDLE', false)
		end
		return
	end
	if MY.BreatheCall('MY_LOGOFF_IDLE') then
		return
	end
	local function onBreatheCall()
		local remainTime = MY_Logoff.nIdleOffTime * 60 - Station.GetIdleTime()
		if remainTime <= 0 then
			return MY.Logout(bCompletely)
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
			MY.Sysmsg({szMessage})
		else
			MY.Sysmsg({_L('Idle off notice: you\'ll auto logoff if you keep idle for %dm %ds.', remainTime / 60, remainTime % 60)})
		end
	end
	MY.BreatheCall('MY_LOGOFF_IDLE', 1000, StartIdleOff)
	MY.Sysmsg({_L('Idle off has been started, you\'ll auto logoff if you keep idle for %ds.', MY_Logoff.nIdleOffTime)})
end

local function onInit()
	IdleOff()
end
MY.RegisterInit('MY_LOGOFF', onInit)

-- MY_Logoff = {
-- 	bLogOffCompletely = false,
-- 	bTargetBloodLessLogOff = true,
-- 	nTargetBloodLessLogOff = 12,
-- 	dwTargetBloodLessLogOff = nil,
-- 	szTargetBloodLessLogOff = nil,
-- 	bPlayerLeaveLogOff = false,
-- 	aPlayerLeaveLogOff = {},
-- 	bClientLevelOverLogOff = false,
-- 	nClientLevelOverLogOff = 90,
-- 	bTimeOutLogOff = false,
-- 	nTimeOut = 3600,
-- }
-- for k, _ in pairs(MY_Logoff) do
-- 	RegisterCustomData('MY_Logoff.' .. k)
-- end
-- MY_Logoff.Const = {
-- 	QUIT_TEAM = 0,
-- 	RETURN_LOGIN = 1,
-- 	RETURN_LIST = 2,
-- }
-- local _MY_Logoff = {
-- 	bStart = false,
-- 	nTimeOutUnixTime = nil,
-- }
-- local Count = function(t)
-- 	local i = 0
-- 	for _,_ in pairs(t) do
-- 		i = i+1
-- 	end
-- 	return i
-- end

-- MY_Logoff.PrintCurrentCondition = function(nChanel)
-- 	nChanel = nChanel or PLAYER_TALK_CHANNEL.LOCAL_SYS
-- 	MY.Talk(nChanel, '--------------------------------------------------\n')
-- 	MY.Talk(nChanel, '['.._L['mingyi plugin'] .. ']' ..
-- 		_L['Any condition matches, game will return to '] ..
-- 		((MY_Logoff.bLogOffCompletely and _L['login page']) or _L['character page']) ..
-- 		g_tStrings.STR_COLON .. '\n'
-- 	)
-- 	if MY_Logoff.bTimeOutLogOff then
-- 		local nTimeOutUnixTime = _MY_Logoff.nTimeOutUnixTime or MY_Logoff.nTimeOut+GetCurrentTime()
-- 		local tDate = TimeToDate(nTimeOutUnixTime)
-- 		MY.Talk(nChanel,  _L('* while time up to %04d-%02d-%02d %02d:%02d:%02d (%d seconds later)',
-- 			tDate.year, tDate.month, tDate.day, tDate.hour, tDate.minute, tDate.second, nTimeOutUnixTime-GetCurrentTime()
-- 		) .. '\n')
-- 	end
-- 	if MY_Logoff.bPlayerLeaveLogOff then
-- 		local t = {}
-- 		for dwID, szName in pairs(MY_Logoff.aPlayerLeaveLogOff) do
-- 			table.insert(t, szName..'('..dwID..')')
-- 		end
-- 		MY.Talk(nChanel, _L['* while players below all disappeared:'] .. table.concat(t, ',') .. '\n' )
-- 	end
-- 	if MY_Logoff.bClientLevelOverLogOff then
-- 		MY.Talk(nChanel, _L('* while self level up to %d.', MY_Logoff.nClientLevelOverLogOff) .. '\n')
-- 	end
-- 	if MY_Logoff.bTargetBloodLessLogOff and MY_Logoff.szTargetBloodLessLogOff then
-- 		MY.Talk(nChanel, _L('* while [%s(%d)]\'s life below %d%%.',
-- 			MY_Logoff.szTargetBloodLessLogOff, MY_Logoff.dwTargetBloodLessLogOff, MY_Logoff.nTargetBloodLessLogOff
-- 		)..'\n')
-- 	end
-- 	MY.Talk(nChanel, '--------------------------------------------------\n')
-- end
-- --
-- MY_Logoff.ConditionLogOff = function()
-- 	local bLogOff = false
-- 	if MY_Logoff.bTimeOutLogOff and GetCurrentTime()>_MY_Logoff.nTimeOutUnixTime then bLogOff = true end
-- 	-- 指定玩家消失
-- 	local bAllPlayerLeave = true
-- 	if MY_Logoff.bPlayerLeaveLogOff and Count(MY_Logoff.aPlayerLeaveLogOff)>0 then
-- 		local tNearPlayer = MY.GetNearPlayer()
-- 		for dwID, szName in pairs(MY_Logoff.aPlayerLeaveLogOff) do
-- 			for _,v in pairs(tNearPlayer) do
-- 				if v.dwID == dwID then bAllPlayerLeave = false end
-- 			end
-- 		end
-- 	else bAllPlayerLeave = false
-- 	end
-- 	bLogOff = bLogOff or bAllPlayerLeave
-- 	-- 当前角色等级超过
-- 	if MY_Logoff.bClientLevelOverLogOff and GetClientPlayer().nLevel>=MY_Logoff.nClientLevelOverLogOff then bLogOff=true end
-- 	--指定目标血量不足
-- 	local p = GetNpc(MY_Logoff.dwTargetBloodLessLogOff) or GetPlayer(MY_Logoff.dwTargetBloodLessLogOff)
-- 	if MY_Logoff.bTargetBloodLessLogOff and p and (p.nCurrentLife / p.nMaxLife)*100<MY_Logoff.nTargetBloodLessLogOff then
-- 		bLogOff = true
-- 	end
-- 	-- 下线判定
-- 	if bLogOff then
-- 		MY.Player.LogOff(MY_Logoff.bLogOffCompletely)
-- 	end
-- end
-- --

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local x, y = 20, 20
	local w, h = ui:size()

	-- ui:append('Text', 'Label_ConditionLogoff'):find('#Label_ConditionLogoff')
	--   :pos(30, 20):text(_L['# condition logoff'])
	-- -- <hr />
	-- ui:append('Image', 'Image_ConditionLogoff_Spliter'):find('#Image_ConditionLogoff_Spliter')
	--   :pos(5, 43):size(636, 2):image('UI/Image/UICommon/ScienceTreeNode.UITex', 62)

	-- --指定目标血量低于指定百分比下线
	-- ui:append('WndCheckBox', 'WndCheckBox_TargetBloodLessLogOff'):children('#WndCheckBox_TargetBloodLessLogOff')
	--   :pos(offset.x+10, offset.y+120):text(_L['while'])
	--   :check(MY_Logoff.bTargetBloodLessLogOff or false)
	--   :check(function(b) MY_Logoff.bTargetBloodLessLogOff = b end)

	-- ui:append('WndComboBox', 'WndComboBox_Target'):children('#WndComboBox_Target')
	--   :pos(offset.x+60, offset.y+120):width(290)
	--   :text((MY_Logoff.dwTargetBloodLessLogOff and MY_Logoff.szTargetBloodLessLogOff..'('..MY_Logoff.dwTargetBloodLessLogOff..')') or _L['[ select a target ]'])
	--   :menu(function()
	--   	local t = {}
	--   	local dwType, dwID = GetClientPlayer().GetTarget()
	--   	if dwType == TARGET.NPC and dwID then
	--   		local p = GetNpc(dwID)
	--   		local szName, szTitle = p.szName, p.szName..'('..p.dwID..')'
	--   		table.insert(t, {
	--   			szOption = szName.._L['( current target )'],
	--   			fnAction = function()
	--   				MY_Logoff.szTargetBloodLessLogOff, MY_Logoff.dwTargetBloodLessLogOff = szName, dwID
	--   				ui:children('#WndComboBox_Target'):text(szTitle)
	--   			end,
	--   		})
	--   	end
	--   	for _, p in pairs(MY.GetNearNpc()) do
	--   		local szName, dwID, szTitle = p.szName, p.dwID, p.szName..'('..p.dwID..')'
	--   		if szName and szName~='' then
	--   			table.insert(t, {
	--   				szOption = szTitle,
	--   				fnAction = function()
	--   					MY_Logoff.szTargetBloodLessLogOff, MY_Logoff.dwTargetBloodLessLogOff = szName, dwID
	--   					ui:children('#WndComboBox_Target'):text(szTitle)
	--   				end,
	--   			})
	--   		end
	--   	end
	--   	return t
	--   end)

	-- ui:append('Text', 'Label_LessThan'):find('#Label_LessThan')
	--   :text(_L['life below       %']):pos(offset.x+360,offset.y+120)
	-- ui:append('WndEditBox', 'WndEditBox_TargetBloodLess'):children('#WndEditBox_TargetBloodLess')
	--   :pos(offset.x+420,offset.y+123):size(30,22)
	--   :text(MY_Logoff.nTargetBloodLessLogOff)
	--   :change(function(raw, txt) MY_Logoff.nTargetBloodLessLogOff = tonumber(txt) or MY_Logoff.nTargetBloodLessLogOff end)

	-- -- 指定玩家消失后下线
	-- ui:append('WndCheckBox', 'WndCheckBox_PlayerLeaveLogOff'):children('#WndCheckBox_PlayerLeaveLogOff')
	--   :pos(offset.x+10,offset.y+80):text(_L['while'])
	--   :check(MY_Logoff.bPlayerLeaveLogOff or false)
	--   :check(function(b)MY_Logoff.bPlayerLeaveLogOff=b end)

	-- ui:append('WndComboBox', 'WndComboBox_PlayerLeave'):children('#WndComboBox_PlayerLeave')
	--   :pos(offset.x+60,offset.y+80):width(290)
	--   :text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	--   :menu(function()
	--   	local t = {}
	--   	for dwID, szName in pairs(MY_Logoff.aPlayerLeaveLogOff) do
	--   		if szName and szName~='' then
	--   			table.insert(t, {
	--   				szOption = szName..'('..dwID..')',
	--   				bCheck = true,
	--   				bChecked = (MY_Logoff.aPlayerLeaveLogOff[dwID] and true) or false,
	--   				fnAction = function()
	--   					MY_Logoff.aPlayerLeaveLogOff[dwID] = (not MY_Logoff.aPlayerLeaveLogOff[dwID] and szName) or nil
	--   					ui:children('#WndComboBox_PlayerLeave'):text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	--   				end,
	--   			})
	--   		end
	--   	end
	--   	local dwType, dwID = GetClientPlayer().GetTarget()
	--   	if dwType == TARGET.PLAYER and dwID and not MY_Logoff.aPlayerLeaveLogOff[dwID] then
	--   		local p = GetPlayer(dwID)
	--   		local szName, szTitle = p.szName, p.szName..'('..p.dwID..')'
	--   		table.insert(t, {
	--   			szOption = szName.._L['( current target )'],
	--   			bCheck = true,
	--   			bChecked = (MY_Logoff.aPlayerLeaveLogOff[dwID] and true) or false,
	--   			fnAction = function()
	--   				MY_Logoff.aPlayerLeaveLogOff[dwID] = (not MY_Logoff.aPlayerLeaveLogOff[dwID] and szName) or nil
	--   				ui:children('#WndComboBox_PlayerLeave'):text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	--   			end,
	--   		})
	--   	end
	--   	for _, p in pairs(MY.GetNearPlayer()) do
	--   		local szName, dwID, szTitle = p.szName, p.dwID, p.szName..'('..p.dwID..')'
	--   		if szName and szName~='' and not MY_Logoff.aPlayerLeaveLogOff[dwID] then
	--   			table.insert(t, {
	--   				szOption = szTitle,
	--   				bCheck = true,
	--   				bChecked = (MY_Logoff.aPlayerLeaveLogOff[dwID] and true) or false,
	--   				fnAction = function()
	--   					MY_Logoff.aPlayerLeaveLogOff[dwID] = (not MY_Logoff.aPlayerLeaveLogOff[dwID] and szName) or nil
	--   					ui:children('#WndComboBox_PlayerLeave'):text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	--   				end,
	--   			})
	--   		end
	--   	end
	--   	return t
	-- end)

	-- ui:append('Text', 'Label_PlayerLeaveWhen'):find('#Label_PlayerLeaveWhen')
	--   :pos(offset.x+360,offset.y+80):text(_L['all disappeared'])

	-- -- 自身等级到达指定值下线
	-- ui:append('WndCheckBox', 'WndCheckBox_ClientLevelOverLogOff'):children('#WndCheckBox_ClientLevelOverLogOff')
	--   :pos(offset.x+10,offset.y+40)
	--   :text(_L['while client level exceeds'])
	--   :check(MY_Logoff.bClientLevelOverLogOff or false)
	--   :check(function(b)MY_Logoff.bClientLevelOverLogOff=b end)

	-- ui:append('WndEditBox', 'WndEditBox_ClientLevelOverLogOff'):children('#WndEditBox_ClientLevelOverLogOff')
	--   :pos(offset.x+140,offset.y+40):size(30,22)
	--   :text(MY_Logoff.nClientLevelOverLogOff)
	--   :change(function(raw, txt) MY_Logoff.nClientLevelOverLogOff = tonumber(txt) or MY_Logoff.nClientLevelOverLogOff end)

	-- -- 指定时间后下线
	-- ui:append('WndCheckBox', 'WndCheckBox_TimeOutLogOff'):children('#WndCheckBox_TimeOutLogOff')
	--   :pos(offset.x+10,offset.y):text('')
	--   :check(MY_Logoff.bTimeOutLogOff or false)
	--   :check(function(b)MY_Logoff.bTimeOutLogOff=b end)

	-- ui:append('WndEditBox', 'WndEditBox_TimeOutLogOff'):children('#WndEditBox_TimeOutLogOff')
	--   :pos(offset.x+35,offset.y):size(60,22)
	--   :text(MY_Logoff.nTimeOut)
	--   :change(function(raw, txt) MY_Logoff.nTimeOut = tonumber(txt) or MY_Logoff.nTimeOut end)

	-- ui:append('Text', 'Label_TimeOutWhen'):find('#Label_TimeOutWhen')
	--   :pos(offset.x+100,offset.y-3):text(_L['second(s) later'])

	-- -- 符合条件时
	-- ui:append('Text', 'Label_ReturnTo'):find('#Label_ReturnTo')
	--   :pos(offset.x,offset.y+155):text(_L['While it meets any condition below'])

	-- ui:append('WndComboBox', 'WndComboBox_ReturnTo'):children('#WndComboBox_ReturnTo')
	--   :pos(offset.x+140,offset.y+160):width(130)
	--   :text(_L['return to role list'])
	--   :menu({{
	--   	szOption = _L['return to role list'],
	--   	fnAction = function()
	--   		MY_Logoff.bLogOffCompletely = false
	--   		ui:children('#WndComboBox_ReturnTo'):text(_L['return to role list'])
	-- 	end,
	--   },{
	--   	szOption = _L['return to game login'],
	--   	fnAction = function()
	--   		MY_Logoff.bLogOffCompletely = true
	--   		ui:children('#WndComboBox_ReturnTo'):text(_L['return to game login'])
	--   	end,
	--   }})

	-- ui:append('WndButton', 'WndButton_Print'):children('#WndButton_Print')
	--   :pos(offset.x+390,offset.y)
	--   :text(_L['send to ...'])
	--   :menu({
	--   	--SYS
	--   	{szOption = _L['system channel'], rgb = GetMsgFontColor('MSG_SYS', true), fnAction = function() MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.LOCAL_SYS) end, fnAutoClose = function() return true end},
	--   	--近聊频道
	--   	{szOption = g_tStrings.tChannelName.MSG_NORMAL, rgb = GetMsgFontColor('MSG_NORMAL', true), fnAction = function() MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.NEARBY) end, fnAutoClose = function() return true end},
	--   	--团队频道
	--   	{szOption = g_tStrings.tChannelName.MSG_TEAM  , rgb = GetMsgFontColor('MSG_TEAM', true), fnAction = function() MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.RAID) end, fnAutoClose = function() return true end},
	--   })

	-- ui:append('WndButton', 'WndButton_Switcher'):children('#WndButton_Switcher'):text((_MY_Logoff.bStart and _L['cancel']) or _L['start']):pos(offset.x+390,offset.y+165):click(function()
	--   	_MY_Logoff.bStart = not _MY_Logoff.bStart
	--   	if _MY_Logoff.bStart then
	--   		_MY_Logoff.nTimeOutUnixTime = MY_Logoff.nTimeOut + GetCurrentTime()
	--   		MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.LOCAL_SYS)
	--   		MY.BreatheCall('MY_ConditionLogOff', 300, MY_Logoff.ConditionLogOff)
	--   	else
	--   		MY.BreatheCall('MY_ConditionLogOff', false)
	--   	end
	--   	MY.UI(this):text((_MY_Logoff.bStart and _L['cancel']) or _L['start'])
	-- end)

	-- 暂离登出
	ui:append('Text', { x = x + 10, y = y, text = _L['# idle logoff'] })
	y = y + 23

	ui:append('Image', {
		x = x - 15, y = y, w = w - (x - 15) * 2, h = 1,
		image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageframe = 62,
	})
	y = y + 17

	ui:append('WndCheckBox', {
		x = x, y = y, text = _L['enable'],
		checked = MY_Logoff.bIdleOff,
		oncheck = function(bChecked)
			MY_Logoff.bIdleOff = bChecked
			IdleOff()
		end,
	})

	ui:append('WndSliderBox', {
		x = x + 70, y = y, w = 150,
		textfmt = function(val) return _L('Auto logoff when keep idle for %dmin.', val) end,
		range = {1, 1440},
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		value = MY_Logoff.nIdleOffTime,
		onchange = function(raw, val)
			MY_Logoff.nIdleOffTime = val
			MY.DelayCall('MY_LOGOFF_IDLE_TIME_CHANGE', 500, IdleOff)
		end,
	})
	y = y + 40

	-- 快速登出
	ui:append('Text', { x = x + 10, y = y, text = _L['# express logoff'] })
	y = y + 23

	ui:append('Image', {
		x = x - 15, y = y, w = w - (x - 15) * 2, h = 1,
		image = 'UI/Image/UICommon/ScienceTreeNode.UITex', imageframe = 62,
	})
	y = y + 17

	ui:append('WndButton', {
		x = x, y = y, w = 120, text = _L['return to role list'],
		onclick = function() Logoff(false) end,
	})

	ui:append('WndButton', {
		x = 145, y = y, w = 170, text = _L['return to role list while not fight'],
		onclick = function() Logoff(false,true) end,
	})

	ui:append('Text', {
		x = 330, y = y, r = 255, g = 255, b = 0, text = _L['* hotkey setting'],
		onclick = function() MY.Game.SetHotKey() end,
	})
	y = y + 30

	ui:append('WndButton', {
		x = 20, y = y, w = 120, text = _L['return to game login'],
		onclick = function() Logoff(true) end,
	})
	ui:append('WndButton', {
		x = 145, y = y, w = 170, text = _L['return to game login while not fight'],
		onclick = function() Logoff(true,true) end,
	})
	y = y + 30
end
MY.RegisterPanel('Logoff', _L['express logoff'], _L['General'], 'UI/Image/UICommon/LoginSchool.UITex|24', {255,0,0,200}, PS)

do
local menu = {
	szOption = _L['express logoff'],
	{
		szOption = _L['return to role list'],
		fnAction = function()
			Logoff(false)
		end,
	}, {
		szOption = _L['return to game login'],
		fnAction = function()
			Logoff(true)
		end,
	}, {
		szOption = _L['return to role list while not fight'],
		fnAction = function()
			Logoff(false, true)
		end,
	}, {
		szOption = _L['return to game login while not fight'],
		fnAction = function()
			Logoff(true, true)
		end,
	}, {
		bDevide  = true,
	}, {
		szOption = _L['set hotkey'],
		fnAction = function()
			MY.Game.SetHotKey()
		end,
	},
}
MY.RegisterPlayerAddonMenu('MY_LOGOFF_MENU', menu)
MY.RegisterTraceButtonMenu('MY_LOGOFF_MENU', menu)
end

MY.Game.AddHotKey('LogOff_RUI', _L['return to role list'], function() Logoff(false) end, nil)
MY.Game.AddHotKey('LogOff_RRL', _L['return to game login'], function() Logoff(true) end, nil)
MY.Game.AddHotKey('LogOff_RUI_UNFIGHT', _L['return to role list while not fight'], function() Logoff(false, true) end, nil)
MY.Game.AddHotKey('LogOff_RRL_UNFIGHT', _L['return to game login while not fight'], function() Logoff(true, true) end, nil)
MY.Game.AddHotKey('LogOff_RUI_UNFIGHT_ALIVE', _L['return to role list while not fight and not dead'], function() Logoff(false, true, true) end, nil)
MY.Game.AddHotKey('LogOff_RRL_UNFIGHT_ALIVE', _L['return to game login while not fight and not dead'], function() Logoff(true, true, true) end, nil)
