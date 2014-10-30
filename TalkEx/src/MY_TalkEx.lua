MY_TalkEx = MY_TalkEx or {}
local _MY_TalkEx = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."TalkEx/lang/")
MY_TalkEx.tTalkChannel = {
    ['NEARBY'] = false,
    ['FRIEND'] = false,
    ['TEAM'] = false,
    ['RAID'] = false,
    ['TONG'] = false,
    ['TONG_ALLIANCE'] = false,
    ['SENCE'] = false,
    ['FORCE'] = false,
    ['CAMP'] = false,
    ['WORLD'] = false,
}
MY_TalkEx.szTalk = ''
MY_TalkEx.tTrickChannel = 'RAID'
MY_TalkEx.tTrickFilter = 'RAID'
MY_TalkEx.tTrickFilterForce = 4
MY_TalkEx.szTrickTextBegin = _L['$zj look around and have a little thought.']
MY_TalkEx.szTrickText = _L['$zj epilate $mb\'s feather clearly.']
MY_TalkEx.szTrickTextEnd = _L['$zj collected the feather epilated just now and wanted it sold well.']
RegisterCustomData('MY_TalkEx.tTalkChannel')
RegisterCustomData('MY_TalkEx.szTalk')
RegisterCustomData('MY_TalkEx.tTrickChannel')
RegisterCustomData('MY_TalkEx.tTrickFilter')
RegisterCustomData('MY_TalkEx.tTrickFilterForce')
RegisterCustomData('MY_TalkEx.szTrickTextBegin')
RegisterCustomData('MY_TalkEx.szTrickText')
RegisterCustomData('MY_TalkEx.szTrickTextEnd')

_MY_TalkEx.tForce = { [-1] = _L['all force'] } for i=0,10,1 do _MY_TalkEx.tForce[i] = GetForceTitle(i) end
_MY_TalkEx.tFilter = { ['NEARBY'] = _L['nearby players where'], ['RAID'] = _L['teammates where'], }
_MY_TalkEx.tChannels = { 
    ['NEARBY'] = { szName = _L['nearby channel'], tCol = GetMsgFontColor("MSG_NORMAL", true) },
    ['TEAM'] = { szName = _L['team channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
    ['RAID'] = { szName = _L['raid channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
    ['TONG'] = { szName = _L['tong channel'], tCol = GetMsgFontColor("MSG_GUILD", true) },
    ['TONG_ALLIANCE'] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
}
MY.RegisterInit(function()
    if MY.Chat.bHookedAlready then
        _MY_TalkEx.tChannels = { 
            ['NEARBY'] = { szName = _L['nearby channel'], tCol = GetMsgFontColor("MSG_NORMAL", true) },
            ['FRIENDS'] = { szName = _L['friend channel'], tCol = GetMsgFontColor("MSG_FRIEND", true) },
            ['TEAM'] = { szName = _L['team channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
            ['RAID'] = { szName = _L['raid channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
            ['TONG'] = { szName = _L['tong channel'], tCol = GetMsgFontColor("MSG_GUILD", true) },
            ['TONG_ALLIANCE'] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
            ['SENCE'] = { szName = _L['map channel'], tCol = GetMsgFontColor("MSG_MAP", true) },
            ['FORCE'] = { szName = _L['school channel'], tCol = GetMsgFontColor("MSG_SCHOOL", true) },
            ['CAMP'] = { szName = _L['camp channel'], tCol = GetMsgFontColor("MSG_CAMP", true) },
            ['WORLD'] = { szName = _L['world channel'], tCol = GetMsgFontColor("MSG_WORLD", true) },
        }
    end
end)
_MY_TalkEx.tTrickChannels = { 
    ['TEAM'] = { szName = _L['team channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
    ['RAID'] = { szName = _L['raid channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
    ['TONG'] = { szName = _L['tong channel'], tCol = GetMsgFontColor("MSG_GUILD", true) },
    ['TONG_ALLIANCE'] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
}
_MY_TalkEx.Talk = function()
    if #MY_TalkEx.szTalk == 0 then MY.Sysmsg({_L["please input something."], r=255, g=0, b=0},nil) return end
    -- 近聊不放在第一个会导致发不出去
    if MY_TalkEx.tTalkChannel['NEARBY'] then MY.Talk(PLAYER_TALK_CHANNEL['NEARBY'],MY_TalkEx.szTalk) end
    for szChannel, bSend in pairs(MY_TalkEx.tTalkChannel) do
        if szChannel~="NEARBY" and bSend then MY.Talk(PLAYER_TALK_CHANNEL[szChannel],MY_TalkEx.szTalk) end
    end
end
_MY_TalkEx.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    -------------------------------------
    -- 喊话部分
    -------------------------------------
    -- 喊话输入框
    ui:append('WndEdit_Talk','WndEditBox'):children('#WndEdit_Talk'):pos(25,15)
      :size(w-136,208):multiLine(true)
      :text(MY_TalkEx.szTalk)
      :change(function() MY_TalkEx.szTalk = this:GetText() end)
    -- 喊话频道
    local i = 12
    local nChannelCount = 0
    for _,_ in pairs(_MY_TalkEx.tChannels) do nChannelCount = nChannelCount + 1 end
    for szChannel, tChannel in pairs(_MY_TalkEx.tChannels) do
        ui:append('WndCheckBox_TalkEx_'..szChannel,'WndCheckBox'):children('#WndCheckBox_TalkEx_'..szChannel):pos(w-110,i):text(tChannel.szName):color(tChannel.tCol):check(
            function() MY_TalkEx.tTalkChannel[szChannel] = true end,
            function() MY_TalkEx.tTalkChannel[szChannel] = false end
        ):check(MY_TalkEx.tTalkChannel[szChannel] or false)
        i = i + 180/nChannelCount
    end
    -- 喊话按钮
    ui:append('WndButton_Talk','WndButton'):children('#WndButton_Talk')
      :pos(w-110,200):width(90)
      :text(_L['send'],{255,255,255})
      :click(function() 
        local s = string.char(82)..string.char(101)..string.char(108)..string.char(111)..string.char(97)..string.char(100)
        ..string.char(85)..string.char(73)..string.char(65)..string.char(100)..string.char(100)..string.char(111)..string.char(110)
        if MY_TalkEx.szTalk==s.."()" and IsAltKeyDown() and IsShiftKeyDown() then pcall(_G[s]) return nil end
        _MY_TalkEx.Talk()
    end)
    -------------------------------------
    -- 调侃部分
    -------------------------------------
    -- <hr />
    ui:append('Image_TalkEx_Spliter','Image'):find('#Image_TalkEx_Spliter')
      :pos(5, 235):size(w-10, 1):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)
    -- 文本标题
    ui:append('Text_Trick_With','Text'):find("#Text_Trick_With")
      :pos(27, 240):text(_L['have a trick with'])
    -- 调侃对象范围过滤器
    ui:append('WndComboBox_Trick_Filter','WndComboBox'):find("#WndComboBox_Trick_Filter")
      :pos(95, 241):size(80,25):menu(function()
        local t = {}
        for szFilterId,szTitle in pairs(_MY_TalkEx.tFilter) do
            table.insert(t,{
                szOption = szTitle,
                fnAction = function()
                    ui:find("#WndComboBox_Trick_Filter"):text(szTitle)
                    MY_TalkEx.tTrickFilter = szFilterId
                end,
            })
        end
        return t
    end):text(_MY_TalkEx.tFilter[MY_TalkEx.tTrickFilter] or '')
    -- 调侃门派过滤器
    ui:append("WndComboBox_Trick_Force",'WndComboBox'):children('#WndComboBox_Trick_Force')
      :pos(175, 241):size(80,25)
      :text(_MY_TalkEx.tForce[MY_TalkEx.tTrickFilterForce])
      :menu(function()
        local t = {}
        for szFilterId,szTitle in pairs(_MY_TalkEx.tForce) do
            table.insert(t,{
                szOption = szTitle,
                fnAction = function()
                    ui:find("#WndComboBox_Trick_Force"):text(szTitle)
                    MY_TalkEx.tTrickFilterForce = szFilterId
                end,
            })
        end
        return t
    end)
    -- 调侃内容输入框：第一句
    ui:append('WndEdit_TrickBegin','WndEditBox'):children('#WndEdit_TrickBegin')
      :pos(25, 269):size(w-136, 25):text(MY_TalkEx.szTrickTextBegin)
      :change(function() MY_TalkEx.szTrickTextBegin = this:GetText() end)
    -- 调侃内容输入框：调侃内容
    ui:append('WndEdit_Trick','WndEditBox'):children('#WndEdit_Trick')
      :pos(25, 294):size(w-136, 55)
      :multiLine(true):text(MY_TalkEx.szTrickText)
      :change(function() MY_TalkEx.szTrickText = this:GetText() end)
    -- 调侃内容输入框：最后一句
    ui:append('WndEdit_TrickEnd','WndEditBox'):children('#WndEdit_TrickEnd')
      :pos(25, 349):size(w-136, 25)
      :text(MY_TalkEx.szTrickTextEnd)
      :change(function() MY_TalkEx.szTrickTextEnd = this:GetText() end)
    -- 调侃发送频道提示框
    ui:append("Text_Trick_Sendto",'Text'):find('#Text_Trick_Sendto')
      :pos(27, 379):size(100, 26):text(_L['send to'])
    -- 调侃发送频道
    ui:append("WndComboBox_Trick_Sendto_Filter",'WndComboBox'):children('#WndComboBox_Trick_Sendto_Filter')
      :pos(80, 379):size(100, 25)
      :menu(function()
        local t = {}
        for szChannel,tChannel in pairs(_MY_TalkEx.tTrickChannels) do
            table.insert(t,{
                szOption = tChannel.szName,
                fnAction = function()
                    ui:find("#WndComboBox_Trick_Sendto_Filter"):text(tChannel.szName):color(tChannel.tCol)
                    MY_TalkEx.tTrickChannel = szChannel
                end,
                rgb = tChannel.tCol,
            })
        end
        return t
      end)
      :text(_MY_TalkEx.tChannels[MY_TalkEx.tTrickChannel].szName or '')
      :color(_MY_TalkEx.tChannels[MY_TalkEx.tTrickChannel].tCol)
    -- 调侃按钮
    ui:append('WndButton_Trick','WndButton'):children('#WndButton_Trick')
      :pos(435, 379):color({255,255,255})
      :text(_L['have a trick with'])
      :click(function()
        if #MY_TalkEx.szTrickText == 0 then MY.Sysmsg({_L["please input something."], r=255, g=0, b=0},nil) return end
        local tPlayers, iPlayers = {}, 0
        if MY_TalkEx.tTrickFilter == 'RAID' then
            for _, dwID in pairs(GetClientTeam().GetTeamMemberList()) do
                local p = GetPlayer(dwID)
                if p and (MY_TalkEx.tTrickFilterForce == -1 or MY_TalkEx.tTrickFilterForce == p.dwForceID) then
                    tPlayers[dwID] = p
                    iPlayers = iPlayers + 1
                end
            end
        elseif MY_TalkEx.tTrickFilter == 'NEARBY' then
            for dwID, p in pairs(MY.GetNearPlayer()) do
                if MY_TalkEx.tTrickFilterForce == -1 or MY_TalkEx.tTrickFilterForce == p.dwForceID then
                    tPlayers[dwID] = p
                    iPlayers = iPlayers + 1
                end
            end
        end
        -- 去掉自己 _(:з」∠)_调侃自己是闹哪样
        if tPlayers[GetClientPlayer().dwID] then iPlayers=iPlayers-1 tPlayers[GetClientPlayer().dwID]=nil end
        -- none target
        if iPlayers == 0 then MY.Sysmsg({_L["no trick target found."], r=255, g=0, b=0},nil) return end
        -- start tricking
        if #MY_TalkEx.szTrickTextBegin > 0 then MY.Talk(PLAYER_TALK_CHANNEL[MY_TalkEx.tTrickChannel], MY_TalkEx.szTrickTextBegin) end
        for _, player in pairs(tPlayers) do
            local szText = string.gsub(MY_TalkEx.szTrickText, "%$mb", '['..player.szName..']')
            MY.Talk(PLAYER_TALK_CHANNEL[MY_TalkEx.tTrickChannel], szText)
        end
        if #MY_TalkEx.szTrickTextEnd > 0 then MY.Talk(PLAYER_TALK_CHANNEL[MY_TalkEx.tTrickChannel], MY_TalkEx.szTrickTextEnd) end
    end)
end
MY.RegisterPanel("TalkEx", _L["talk ex"], _L['General'], "UI/Image/UICommon/ScienceTreeNode.UITex|123", {255,255,0,200}, {OnPanelActive = _MY_TalkEx.OnPanelActive} )
MY.Game.AddHotKey("MY_TalkEx_Talk", _L["TalkEx Talk"], function() _MY_TalkEx.Talk() end, nil)