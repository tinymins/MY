--------------------------------------------
-- @File  : MY_TalkEx.lua
-- @Desc  : ��������
-- @Author: ��һ�� (tinymins) @ derzh.com
-- @Date  : 2015-05-18 10:30:29
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-05-21 20:27:30
-- @Version: 1.0
-- @ChangeLog:
--  + v1.0 File founded. -- via��һ��
--------------------------------------------
MY_TalkEx = MY_TalkEx or {}
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "TalkEx/lang/")
MY_TalkEx.tTalkChannels     = {}
MY_TalkEx.szTalk            = ''
MY_TalkEx.szTrickFilter     = 'RAID'
MY_TalkEx.nTrickForce       = 4
MY_TalkEx.nTrickChannel     = PLAYER_TALK_CHANNEL.RAID
MY_TalkEx.szTrickTextBegin  = _L['$zj look around and have a little thought.']
MY_TalkEx.szTrickText       = _L['$zj epilate $mb\'s feather clearly.']
MY_TalkEx.szTrickTextEnd    = _L['$zj collected the feather epilated just now and wanted it sold well.']
RegisterCustomData('MY_TalkEx.tTalkChannels')
RegisterCustomData('MY_TalkEx.szTalk')
RegisterCustomData('MY_TalkEx.nTrickChannel')
RegisterCustomData('MY_TalkEx.szTrickFilter')
RegisterCustomData('MY_TalkEx.nTrickForce')
RegisterCustomData('MY_TalkEx.szTrickTextBegin')
RegisterCustomData('MY_TalkEx.szTrickText')
RegisterCustomData('MY_TalkEx.szTrickTextEnd')

_C.tTalkChannels = {
	{ nChannel = PLAYER_TALK_CHANNEL.NEARBY       , szID = "MSG_NORMAL"         },
	{ nChannel = PLAYER_TALK_CHANNEL.TEAM         , szID = "MSG_PARTY"          },
	{ nChannel = PLAYER_TALK_CHANNEL.RAID         , szID = "MSG_TEAM"           },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG         , szID = "MSG_GUILD"          },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG_ALLIANCE, szID = "MSG_GUILD_ALLIANCE" },
}
_C.tForceTitle = { [-1] = _L['all force'] }
for i, v in pairs(g_tStrings.tForceTitle) do
	_C.tForceTitle[i] = v -- GetForceTitle(i)
end
_C.tTrickFilter = { ['NEARBY'] = _L['nearby players where'], ['RAID'] = _L['teammates where'], }
_C.tTrickChannels = { 
	[PLAYER_TALK_CHANNEL.TEAM         ] = { szName = _L['team channel'         ], tCol = GetMsgFontColor("MSG_TEAM"          , true) },
	[PLAYER_TALK_CHANNEL.RAID         ] = { szName = _L['raid channel'         ], tCol = GetMsgFontColor("MSG_TEAM"          , true) },
	[PLAYER_TALK_CHANNEL.TONG         ] = { szName = _L['tong channel'         ], tCol = GetMsgFontColor("MSG_GUILD"         , true) },
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
}

_C.Talk = function()
	if #MY_TalkEx.szTalk == 0 then
		return MY.Sysmsg({_L["please input something."], r=255, g=0, b=0})
	end
	
	if not MY.IsShieldedVersion() and MY.ProcessCommand
	and MY_TalkEx.szTalk:sub(1, 8) == '/script ' then
		MY.ProcessCommand(MY_TalkEx.szTalk:sub(9))
	else
		-- ���Ĳ����ڵ�һ���ᵼ�·�����ȥ
		if MY_TalkEx.tTalkChannels[PLAYER_TALK_CHANNEL.NEARBY] then
			MY.Talk(PLAYER_TALK_CHANNEL.NEARBY, MY_TalkEx.szTalk)
		end
		-- �������Ͷ���
		for nChannel, _ in pairs(MY_TalkEx.tTalkChannels) do
			if nChannel ~= PLAYER_TALK_CHANNEL.NEARBY then
				MY.Talk(nChannel, MY_TalkEx.szTalk)
			end
		end
	end
end
MY.Game.AddHotKey("MY_TalkEx_Talk", _L["TalkEx Talk"], _C.Talk, nil)

_C.Trick = function()
	if #MY_TalkEx.szTrickText == 0 then
		return MY.Sysmsg({_L["please input something."], r=255, g=0, b=0})
	end
	local t = {}
	if MY_TalkEx.szTrickFilter == 'RAID' then
		local team = GetClientTeam()
		local me = GetClientPlayer()
		if team and me and (me.IsInParty() or me.IsInRaid()) then
			for i = 0, team.nGroupNum - 1 do
				local tGroup = team.GetGroupInfo(i)
				if tGroup and tGroup.MemberList then
					for _, dwID in ipairs(tGroup.MemberList) do
						local info = team.GetMemberInfo(dwID)
						if info and (MY_TalkEx.nTrickForce == -1 or MY_TalkEx.nTrickForce == info.dwForceID) then
							table.insert(t, info.szName)
						end
					end
				end
			end
		end
	elseif MY_TalkEx.szTrickFilter == 'NEARBY' then
		for dwID, p in pairs(MY.GetNearPlayer()) do
			if MY_TalkEx.nTrickForce == -1 or MY_TalkEx.nTrickForce == p.dwForceID then
				table.insert(t, p.szName)
			end
		end
	end
	-- ȥ���Լ� _(:�١���)_��٩�Լ���������
	for i = #t, 1, -1 do
		if t[i] == GetClientPlayer().szName then
			table.remove(t, i)
		end
	end
	-- none target
	if #t == 0 then
		return MY.Sysmsg({_L["no trick target found."], r=255, g=0, b=0},nil)
	end
	-- start tricking
	if #MY_TalkEx.szTrickTextBegin > 0 then
		MY.Talk(MY_TalkEx.nTrickChannel, MY_TalkEx.szTrickTextBegin)
	end
	for _, szName in ipairs(t) do
		MY.Talk(MY_TalkEx.nTrickChannel, MY_TalkEx.szTrickText:gsub("%$mb", '[' .. szName .. ']'))
	end
	if #MY_TalkEx.szTrickTextEnd > 0 then
		MY.Talk(MY_TalkEx.nTrickChannel, MY_TalkEx.szTrickTextEnd)
	end
end

MY.RegisterPanel("TalkEx", _L["talk ex"], _L['Chat'], "UI/Image/UICommon/ScienceTreeNode.UITex|123", {255,255,0,200}, { OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	-------------------------------------
	-- ��������
	-------------------------------------
	-- ���������
	ui:append("WndEditBox", "WndEdit_Talk"):children('#WndEdit_Talk'):pos(25,15)
	  :size(w-136,208):multiLine(true)
	  :text(MY_TalkEx.szTalk)
	  :change(function() MY_TalkEx.szTalk = this:GetText() end)
	-- ����Ƶ��
	local y = 12
	local nChannelCount = #_C.tTalkChannels
	for i, p in ipairs(_C.tTalkChannels) do
		ui:append('WndCheckBox', 'WndCheckBox_TalkEx_' .. p.nChannel):children('#WndCheckBox_TalkEx_' .. p.nChannel)
		  :pos(w - 110, y + (i - 1) * 180 / nChannelCount)
		  :text(g_tStrings.tChannelName[p.szID])
		  :color(GetMsgFontColor(p.szID, true))
		  :check(
		  	function() MY_TalkEx.tTalkChannels[p.nChannel] = true end,
		  	function() MY_TalkEx.tTalkChannels[p.nChannel] = nil  end)
		  :check(MY_TalkEx.tTalkChannels[p.nChannel] or false)
	end
	-- ������ť
	ui:append("WndButton", "WndButton_Talk"):children('#WndButton_Talk')
	  :pos(w-110,200):width(90)
	  :text(_L['send'],{255,255,255})
	  :click(function()
	  	if IsAltKeyDown() and IsShiftKeyDown() and MY.ProcessCommand
	  	and MY_TalkEx.szTalk:sub(1, 8) == '/script ' then
	  		MY.ProcessCommand(MY_TalkEx.szTalk:sub(9))
	  	else
	  		_C.Talk()
	  	end
	  end, function()
	  	MY.Talk(nil, MY_TalkEx.szTalk, nil, nil, nil, true)
	  end)
	-------------------------------------
	-- ��٩����
	-------------------------------------
	-- <hr />
	ui:append("Image", "Image_TalkEx_Spliter"):find('#Image_TalkEx_Spliter')
	  :pos(5, 235):size(w-10, 1):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)
	-- �ı�����
	ui:append("Text", "Text_Trick_With"):find("#Text_Trick_With")
	  :pos(27, 240):text(_L['have a trick with'])
	-- ��٩����Χ������
	ui:append("WndComboBox", "WndComboBox_Trick_Filter"):find("#WndComboBox_Trick_Filter")
	  :pos(95, 241):size(80,25):menu(function()
	  	local t = {}
	  	for szFilterId,szTitle in pairs(_C.tTrickFilter) do
	  		table.insert(t,{
	  			szOption = szTitle,
	  			fnAction = function()
	  				ui:find("#WndComboBox_Trick_Filter"):text(szTitle)
	  				MY_TalkEx.szTrickFilter = szFilterId
	  			end,
	  		})
	  	end
	  	return t
	  end)
	  :text(_C.tTrickFilter[MY_TalkEx.szTrickFilter] or '')
	-- ��٩���ɹ�����
	ui:append("WndComboBox", "WndComboBox_Trick_Force"):children('#WndComboBox_Trick_Force')
	  :pos(175, 241):size(80,25)
	  :text(_C.tForceTitle[MY_TalkEx.nTrickForce])
	  :menu(function()
	  	local t = {}
	  	for szFilterId,szTitle in pairs(_C.tForceTitle) do
	  		table.insert(t,{
	  			szOption = szTitle,
	  			fnAction = function()
	  				ui:find("#WndComboBox_Trick_Force"):text(szTitle)
	  				MY_TalkEx.nTrickForce = szFilterId
	  			end,
	  		})
	  	end
	  	return t
	  end)
	-- ��٩��������򣺵�һ��
	ui:append("WndEditBox", "WndEdit_TrickBegin"):children('#WndEdit_TrickBegin')
	  :pos(25, 269):size(w-136, 25):text(MY_TalkEx.szTrickTextBegin)
	  :change(function() MY_TalkEx.szTrickTextBegin = this:GetText() end)
	-- ��٩��������򣺵�٩����
	ui:append("WndEditBox", "WndEdit_Trick"):children('#WndEdit_Trick')
	  :pos(25, 294):size(w-136, 55)
	  :multiLine(true):text(MY_TalkEx.szTrickText)
	  :change(function() MY_TalkEx.szTrickText = this:GetText() end)
	-- ��٩������������һ��
	ui:append("WndEditBox", "WndEdit_TrickEnd"):children('#WndEdit_TrickEnd')
	  :pos(25, 349):size(w-136, 25)
	  :text(MY_TalkEx.szTrickTextEnd)
	  :change(function() MY_TalkEx.szTrickTextEnd = this:GetText() end)
	-- ��٩����Ƶ����ʾ��
	ui:append("Text", "Text_Trick_Sendto"):find('#Text_Trick_Sendto')
	  :pos(27, 379):size(100, 26):text(_L['send to'])
	-- ��٩����Ƶ��
	ui:append("WndComboBox", "WndComboBox_Trick_Sendto_Filter"):children('#WndComboBox_Trick_Sendto_Filter')
	  :pos(80, 379):size(100, 25)
	  :menu(function()
	  	local t = {}
	  	for nTrickChannel, tChannel in pairs(_C.tTrickChannels) do
	  		table.insert(t,{
	  			rgb = tChannel.tCol,
	  			szOption = tChannel.szName,
	  			fnAction = function()
	  				MY_TalkEx.nTrickChannel = nTrickChannel
	  				ui:find("#WndComboBox_Trick_Sendto_Filter"):text(tChannel.szName):color(tChannel.tCol)
	  			end,
	  		})
	  	end
	  	return t
	  end)
	  :text(_C.tTrickChannels[MY_TalkEx.nTrickChannel].szName or '')
	  :color(_C.tTrickChannels[MY_TalkEx.nTrickChannel].tCol)
	-- ��٩��ť
	ui:append("WndButton", "WndButton_Trick"):children('#WndButton_Trick')
	  :pos(435, 379):color({255,255,255})
	  :text(_L['have a trick with'])
	  :click(_C.Trick)
end})
