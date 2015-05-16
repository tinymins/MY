--
-- ���ٵǳ�
-- by ���� @ ˫���� @ ݶ����
-- Build 20140411
--
-- ��Ҫ����:
-- 1.ָ�������˶�/����
-- 
MY_Logoff = {
	bLogOffCompletely = false,
	bTargetBloodLessLogOff = true,
	nTargetBloodLessLogOff = 12,
	dwTargetBloodLessLogOff = nil,
	szTargetBloodLessLogOff = nil,
	bPlayerLeaveLogOff = false,
	aPlayerLeaveLogOff = {},
	bClientLevelOverLogOff = false,
	nClientLevelOverLogOff = 90,
	bTimeOutLogOff = false,
	nTimeOut = 3600,
}
for k, _ in pairs(MY_Logoff) do
	RegisterCustomData("MY_Logoff." .. k)
end
MY_Logoff.Const = {
	QUIT_TEAM = 0,
	RETURN_LOGIN = 1,
	RETURN_LIST = 2,
}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot..'Logoff/lang/')
local _MY_Logoff = {
	bStart = false,
	nTimeOutUnixTime = nil,
}
local Count = function(t)
	local i = 0
	for _,_ in pairs(t) do
		i = i+1
	end
	return i
end
-- (void)MY_Logoff.LogOff(bCompletely, bUnfight)
MY_Logoff.LogOffEx = function(bCompletely, bUnfight)
	if not bUnfight then MY.Player.LogOff(bCompletely) return nil end
	MY.Sysmsg({_L["Logoff is ready for your casting unfight skill."]})
	-- ��Ӻ��������ȴ���ս��
	MY.BreatheCall("LOG_OFF",function()
		if not GetClientPlayer().bFightState then
			MY.Player.LogOff(bCompletely)    -- ����ս�����ߡ�
		end
	end)
end
-- 
MY_Logoff.PrintCurrentCondition = function(nChanel) 
	nChanel = nChanel or PLAYER_TALK_CHANNEL.LOCAL_SYS
	MY.Talk(nChanel, "--------------------------------------------------\n")
	MY.Talk(nChanel, "[".._L['mingyi plugin'] .. "]" ..
		_L["Any condition matches, game will return to "] ..
		((MY_Logoff.bLogOffCompletely and _L["login page"]) or _L["character page"]) ..
		g_tStrings.STR_COLON .. "\n"
	)
	if MY_Logoff.bTimeOutLogOff then
		local nTimeOutUnixTime = _MY_Logoff.nTimeOutUnixTime or MY_Logoff.nTimeOut+GetCurrentTime()
		local tDate = TimeToDate(nTimeOutUnixTime)
		MY.Talk(nChanel,  _L('* while time up to %04d-%02d-%02d %02d:%02d:%02d (%d seconds later)',
			tDate.year, tDate.month, tDate.day, tDate.hour, tDate.minute, tDate.second, nTimeOutUnixTime-GetCurrentTime()
		) .. '\n')
	end
	if MY_Logoff.bPlayerLeaveLogOff then
		local t = {}
		for dwID, szName in pairs(MY_Logoff.aPlayerLeaveLogOff) do
			table.insert(t, szName..'('..dwID..')')
		end
		MY.Talk(nChanel, _L["* while players below all disappeared:"] .. table.concat(t, ',') .. '\n' )
	end
	if MY_Logoff.bClientLevelOverLogOff then
		MY.Talk(nChanel, _L('* while self level up to %d.', MY_Logoff.nClientLevelOverLogOff) .. "\n")
	end
	if MY_Logoff.bTargetBloodLessLogOff and MY_Logoff.szTargetBloodLessLogOff then
		MY.Talk(nChanel, _L('* while [%s(%d)]\'s life below %d%%.',
			MY_Logoff.szTargetBloodLessLogOff, MY_Logoff.dwTargetBloodLessLogOff, MY_Logoff.nTargetBloodLessLogOff
		)..'\n')
	end
	MY.Talk(nChanel, "--------------------------------------------------\n")
end
--
MY_Logoff.ConditionLogOff = function()
	local bLogOff = false
	if MY_Logoff.bTimeOutLogOff and GetCurrentTime()>_MY_Logoff.nTimeOutUnixTime then bLogOff = true end
	-- ָ�������ʧ
	local bAllPlayerLeave = true
	if MY_Logoff.bPlayerLeaveLogOff and Count(MY_Logoff.aPlayerLeaveLogOff)>0 then
		local tNearPlayer = MY.GetNearPlayer()
		for dwID, szName in pairs(MY_Logoff.aPlayerLeaveLogOff) do
			for _,v in pairs(tNearPlayer) do
				if v.dwID == dwID then bAllPlayerLeave = false end
			end
		end
	else bAllPlayerLeave = false
	end
	bLogOff = bLogOff or bAllPlayerLeave
	-- ��ǰ��ɫ�ȼ�����
	if MY_Logoff.bClientLevelOverLogOff and GetClientPlayer().nLevel>=MY_Logoff.nClientLevelOverLogOff then bLogOff=true end
	--ָ��Ŀ��Ѫ������
	local p = GetNpc(MY_Logoff.dwTargetBloodLessLogOff) or GetPlayer(MY_Logoff.dwTargetBloodLessLogOff)
	if MY_Logoff.bTargetBloodLessLogOff and p and (p.nCurrentLife / p.nMaxLife)*100<MY_Logoff.nTargetBloodLessLogOff then
		bLogOff = true
	end
	-- �����ж�
	if bLogOff then
		MY.Player.LogOff(MY_Logoff.bLogOffCompletely)
	end
end
--
_MY_Logoff.OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	-- �����ǳ�
	local offset = { x = 10, y = 70 }
	
	ui:append("Text", "Label_ConditionLogoff"):find('#Label_ConditionLogoff')
	  :pos(30, 20):text(_L['# condition logoff'])
	-- <hr />
	ui:append("Image", "Image_ConditionLogoff_Spliter"):find('#Image_ConditionLogoff_Spliter')
	  :pos(5, 43):size(636, 2):image('UI/Image/UICommon/ScienceTreeNode.UITex', 62)
	
	--ָ��Ŀ��Ѫ������ָ���ٷֱ�����
	ui:append("WndCheckBox", "WndCheckBox_TargetBloodLessLogOff"):children('#WndCheckBox_TargetBloodLessLogOff')
	  :pos(offset.x+10, offset.y+120):text(_L['while'])
	  :check(MY_Logoff.bTargetBloodLessLogOff or false)
	  :check(function(b) MY_Logoff.bTargetBloodLessLogOff = b end)
	
	ui:append("WndComboBox", "WndComboBox_Target"):children('#WndComboBox_Target')
	  :pos(offset.x+60, offset.y+120):width(290)
	  :text((MY_Logoff.dwTargetBloodLessLogOff and MY_Logoff.szTargetBloodLessLogOff..'('..MY_Logoff.dwTargetBloodLessLogOff..')') or _L['[ select a target ]'])
	  :menu(function()
	  	local t = {}
	  	local dwType, dwID = GetClientPlayer().GetTarget()
	  	if dwType == TARGET.NPC and dwID then
	  		local p = GetNpc(dwID)
	  		local szName, szTitle = p.szName, p.szName..'('..p.dwID..')'
	  		table.insert(t, {
	  			szOption = szName.._L['( current target )'],
	  			fnAction = function()
	  				MY_Logoff.szTargetBloodLessLogOff, MY_Logoff.dwTargetBloodLessLogOff = szName, dwID
	  				ui:children('#WndComboBox_Target'):text(szTitle)
	  			end,
	  		})
	  	end
	  	for _, p in pairs(MY.GetNearNpc()) do
	  		local szName, dwID, szTitle = p.szName, p.dwID, p.szName..'('..p.dwID..')'
	  		if szName and szName~='' then
	  			table.insert(t, {
	  				szOption = szTitle,
	  				fnAction = function()
	  					MY_Logoff.szTargetBloodLessLogOff, MY_Logoff.dwTargetBloodLessLogOff = szName, dwID
	  					ui:children('#WndComboBox_Target'):text(szTitle)
	  				end,
	  			})
	  		end
	  	end
	  	return t
	  end)

	ui:append("Text", "Label_LessThan"):find('#Label_LessThan')
	  :text(_L['life below       %']):pos(offset.x+360,offset.y+120)
	ui:append("WndEditBox", "WndEditBox_TargetBloodLess"):children('#WndEditBox_TargetBloodLess')
	  :pos(offset.x+420,offset.y+123):size(30,22)
	  :text(MY_Logoff.nTargetBloodLessLogOff)
	  :change(function(txt) MY_Logoff.nTargetBloodLessLogOff = tonumber(txt) or MY_Logoff.nTargetBloodLessLogOff end)
	
	-- ָ�������ʧ������
	ui:append("WndCheckBox", "WndCheckBox_PlayerLeaveLogOff"):children('#WndCheckBox_PlayerLeaveLogOff')
	  :pos(offset.x+10,offset.y+80):text(_L['while'])
	  :check(MY_Logoff.bPlayerLeaveLogOff or false)
	  :check(function(b)MY_Logoff.bPlayerLeaveLogOff=b end)
	
	ui:append("WndComboBox", "WndComboBox_PlayerLeave"):children('#WndComboBox_PlayerLeave')
	  :pos(offset.x+60,offset.y+80):width(290)
	  :text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	  :menu(function() 
	  	local t = {}
	  	for dwID, szName in pairs(MY_Logoff.aPlayerLeaveLogOff) do
	  		if szName and szName~='' then
	  			table.insert(t, {
	  				szOption = szName..'('..dwID..')',
	  				bCheck = true,
	  				bChecked = (MY_Logoff.aPlayerLeaveLogOff[dwID] and true) or false,
	  				fnAction = function()
	  					MY_Logoff.aPlayerLeaveLogOff[dwID] = (not MY_Logoff.aPlayerLeaveLogOff[dwID] and szName) or nil
	  					ui:children('#WndComboBox_PlayerLeave'):text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	  				end,
	  			})
	  		end
	  	end
	  	local dwType, dwID = GetClientPlayer().GetTarget()
	  	if dwType == TARGET.PLAYER and dwID and not MY_Logoff.aPlayerLeaveLogOff[dwID] then
	  		local p = GetPlayer(dwID)
	  		local szName, szTitle = p.szName, p.szName..'('..p.dwID..')'
	  		table.insert(t, {
	  			szOption = szName.._L['( current target )'],
	  			bCheck = true,
	  			bChecked = (MY_Logoff.aPlayerLeaveLogOff[dwID] and true) or false,
	  			fnAction = function()
	  				MY_Logoff.aPlayerLeaveLogOff[dwID] = (not MY_Logoff.aPlayerLeaveLogOff[dwID] and szName) or nil
	  				ui:children('#WndComboBox_PlayerLeave'):text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	  			end,
	  		})
	  	end
	  	for _, p in pairs(MY.GetNearPlayer()) do
	  		local szName, dwID, szTitle = p.szName, p.dwID, p.szName..'('..p.dwID..')'
	  		if szName and szName~='' and not MY_Logoff.aPlayerLeaveLogOff[dwID] then
	  			table.insert(t, {
	  				szOption = szTitle,
	  				bCheck = true,
	  				bChecked = (MY_Logoff.aPlayerLeaveLogOff[dwID] and true) or false,
	  				fnAction = function()
	  					MY_Logoff.aPlayerLeaveLogOff[dwID] = (not MY_Logoff.aPlayerLeaveLogOff[dwID] and szName) or nil
	  					ui:children('#WndComboBox_PlayerLeave'):text(_L('%d player(s) selected',Count(MY_Logoff.aPlayerLeaveLogOff)))
	  				end,
	  			})
	  		end
	  	end
	  	return t
	end)

	ui:append("Text", "Label_PlayerLeaveWhen"):find('#Label_PlayerLeaveWhen')
	  :pos(offset.x+360,offset.y+80):text(_L['all disappeared'])

	-- ����ȼ�����ָ��ֵ����
	ui:append("WndCheckBox", "WndCheckBox_ClientLevelOverLogOff"):children('#WndCheckBox_ClientLevelOverLogOff')
	  :pos(offset.x+10,offset.y+40)
	  :text(_L['while client level exceeds'])
	  :check(MY_Logoff.bClientLevelOverLogOff or false)
	  :check(function(b)MY_Logoff.bClientLevelOverLogOff=b end)
	
	ui:append("WndEditBox", "WndEditBox_ClientLevelOverLogOff"):children('#WndEditBox_ClientLevelOverLogOff')
	  :pos(offset.x+140,offset.y+40):size(30,22)
	  :text(MY_Logoff.nClientLevelOverLogOff)
	  :change(function(txt) MY_Logoff.nClientLevelOverLogOff = tonumber(txt) or MY_Logoff.nClientLevelOverLogOff end)

	-- ָ��ʱ�������
	ui:append("WndCheckBox", "WndCheckBox_TimeOutLogOff"):children('#WndCheckBox_TimeOutLogOff')
	  :pos(offset.x+10,offset.y):text('')
	  :check(MY_Logoff.bTimeOutLogOff or false)
	  :check(function(b)MY_Logoff.bTimeOutLogOff=b end)
	
	ui:append("WndEditBox", "WndEditBox_TimeOutLogOff"):children('#WndEditBox_TimeOutLogOff')
	  :pos(offset.x+35,offset.y):size(60,22)
	  :text(MY_Logoff.nTimeOut)
	  :change(function(txt) MY_Logoff.nTimeOut = tonumber(txt) or MY_Logoff.nTimeOut end)
	
	ui:append("Text", "Label_TimeOutWhen"):find('#Label_TimeOutWhen')
	  :pos(offset.x+100,offset.y-3):text(_L['second(s) later'])

	-- ��������ʱ
	ui:append("Text", "Label_ReturnTo"):find('#Label_ReturnTo')
	  :pos(offset.x,offset.y+155):text(_L['While it meets any condition below'])
	
	ui:append("WndComboBox", "WndComboBox_ReturnTo"):children('#WndComboBox_ReturnTo')
	  :pos(offset.x+140,offset.y+160):width(130)
	  :text(_L['return to role list'])
	  :menu({{
	  	szOption = _L['return to role list'],
	  	fnAction = function()
	  		MY_Logoff.bLogOffCompletely = false
	  		ui:children('#WndComboBox_ReturnTo'):text(_L['return to role list'])
		end,
	  },{
	  	szOption = _L['return to game login'],
	  	fnAction = function()
	  		MY_Logoff.bLogOffCompletely = true
	  		ui:children('#WndComboBox_ReturnTo'):text(_L['return to game login'])
	  	end,
	  }})
	
	ui:append("WndButton", "WndButton_Print"):children('#WndButton_Print')
	  :pos(offset.x+390,offset.y)
	  :text(_L['send to ...'])
	  :menu({
	  	--SYS
	  	{szOption = _L['system channel'], rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.LOCAL_SYS) end, fnAutoClose = function() return true end},
	  	--����Ƶ��
	  	{szOption = g_tStrings.tChannelName.MSG_NORMAL, rgb = GetMsgFontColor("MSG_NORMAL", true), fnAction = function() MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.NEARBY) end, fnAutoClose = function() return true end},
	  	--�Ŷ�Ƶ��
	  	{szOption = g_tStrings.tChannelName.MSG_TEAM  , rgb = GetMsgFontColor("MSG_TEAM", true), fnAction = function() MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.RAID) end, fnAutoClose = function() return true end},
	  })
	
	ui:append("WndButton", "WndButton_Switcher"):children('#WndButton_Switcher'):text((_MY_Logoff.bStart and _L['cancel']) or _L['start']):pos(offset.x+390,offset.y+165):click(function()
	  	_MY_Logoff.bStart = not _MY_Logoff.bStart
	  	if _MY_Logoff.bStart then
	  		_MY_Logoff.nTimeOutUnixTime = MY_Logoff.nTimeOut + GetCurrentTime()
	  		MY_Logoff.PrintCurrentCondition(PLAYER_TALK_CHANNEL.LOCAL_SYS)
	  		MY.BreatheCall(MY_Logoff.ConditionLogOff, 300, "MY_ConditionLogOff")
	  	else
	  		MY.BreatheCall("MY_ConditionLogOff")
	  	end
	  	MY.UI(this):text((_MY_Logoff.bStart and _L['cancel']) or _L['start'])
	end)

	-- ���ٵǳ�
	ui:append("Text", "Label_ExpressLogoff"):find('#Label_ExpressLogoff')
	  :pos(30, 270):text(_L['# express logoff'])
	-- <hr />
	ui:append("Image", "Image_ExpressLogoff_Spliter"):find('#Image_ExpressLogoff_Spliter')
	  :pos(5, 293):size(636, 1):image('UI/Image/UICommon/ScienceTreeNode.UITex', 62)

	ui:append("WndButton", "WndButton_ReturnToCha"):children('#WndButton_ReturnToCha')
	  :pos(20,310):width(120):text(_L['return to role list'])
	  :click(function()MY_Logoff.LogOffEx(false)end)
	ui:append("WndButton", "WndButton_ReturnToChaEx"):children('#WndButton_ReturnToChaEx')
	  :pos(145,310):width(170):text(_L['return to role list while not fight'])
	  :click(function()MY_Logoff.LogOffEx(false,true)end)
	
	ui:append("WndButton", "WndButton_ReturnToLogin"):children('#WndButton_ReturnToLogin')
	  :pos(20,340):width(120):text(_L['return to game login'])
	  :click(function()MY_Logoff.LogOffEx(true)end)
	ui:append("WndButton", "WndButton_ReturnToLoginEx"):children('#WndButton_ReturnToLoginEx')
	  :pos(145,340):width(170):text(_L['return to game login while not fight'])
	  :click(function()MY_Logoff.LogOffEx(true,true)end)
	
	ui:append("Text", "Text_HotKeySet"):find('#Text_HotKeySet')
	  :pos(330,310):color({255,255,0}):text(_L['* hotkey setting'])
	  :click(function() MY.Game.SetHotKey() end)
end

MY.RegisterInit('MY_LOGOFF', function()
	-- �����˵�
	local tMenu = function() return {
		szOption = _L["express logoff"],
		{  -- ���ؽ�ɫѡ��
			szOption = _L['return to role list'],
			-- szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				MY_Logoff.LogOffEx(false)
			end,
			fnAutoClose = function() return true end
		}, {  -- �����û���¼
			szOption = _L['return to game login'],
			-- szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				MY_Logoff.LogOffEx(true)
			end,
			fnAutoClose = function() return true end
		}, {  -- ��ս�󷵻ؽ�ɫѡ��
			szOption = _L['return to role list while not fight'],
			-- szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				MY_Logoff.LogOffEx(false, true)
			end,
			fnAutoClose = function() return true end
		},
		{  -- ��ս�󷵻��û���¼
			szOption = _L['return to game login while not fight'],
			-- szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
				MY_Logoff.LogOffEx(true, true)
			end,
			fnAutoClose = function() return true end
		}, {
			bDevide  = true,
		},  {  -- ���ÿ�ݼ�
			szOption = _L['set hotkey'],
			fnAction = function()
				MY.Game.SetHotKey()
			end,
			fnAutoClose = function() return true end
		},
	} end
	MY.RegisterPlayerAddonMenu( 'MY_LOGOFF_MENU', tMenu)
	MY.RegisterTraceButtonMenu( 'MY_LOGOFF_MENU', tMenu)
end)

MY.RegisterPanel(
	"Logoff", _L["express logoff"], _L['General'],
	"UI/Image/UICommon/LoginSchool.UITex|24", {255,0,0,200},
	{ OnPanelActive = _MY_Logoff.OnPanelActive, bShielded = true }
)
-----------------------------------------------
-- ��ݼ���
-----------------------------------------------
MY.Game.AddHotKey("LogOff_RUI", _L['return to role list'], function() MY_Logoff.LogOffEx(false) end, nil)
MY.Game.AddHotKey("LogOff_RRL", _L['return to game login'], function() MY_Logoff.LogOffEx(true) end, nil)
MY.Game.AddHotKey("LogOff_RUI_UNFIGHT", _L['return to role list while not fight'], function() MY_Logoff.LogOffEx(false, true) end, nil)
MY.Game.AddHotKey("LogOff_RRL_UNFIGHT", _L['return to game login while not fight'], function() MY_Logoff.LogOffEx(true, true) end, nil)
