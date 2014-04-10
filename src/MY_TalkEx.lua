MY_TalkEx = MY_TalkEx or {}
local _MY_TalkEx = {}
local _L = MY.LoadLangPack()
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
MY_TalkEx.szTrickTextBegin = '$zj斜眼看了身边的羊群，冥想了一会。'
MY_TalkEx.szTrickText = '$zj麻利的拔光了$mb的羊毛。'
MY_TalkEx.szTrickTextEnd = '$zj收拾了一下背包里的羊毛，希望今年能卖个好价钱。'
RegisterCustomData('MY_TalkEx.tTalkChannel')
RegisterCustomData('MY_TalkEx.szTalk')

_MY_TalkEx.tForce = { [-1] = _L['all force'] } for i=0,10,1 do _MY_TalkEx.tForce[i] = GetForceTitle(i) end
_MY_TalkEx.tFilter = { ['NEARBY'] = _L['nearby players where'], ['RAID'] = _L['teammates where'], }
_MY_TalkEx.tChannels = { 
    ['NEARBY'] = { szName = _L['nearby channel'], tCol = GetMsgFontColor("MSG_NORMAL", true) },
    ['FRIEND'] = { szName = _L['friend channel'], tCol = GetMsgFontColor("MSG_FRIEND", true) },
    ['TEAM'] = { szName = _L['team channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
    ['RAID'] = { szName = _L['raid channel'], tCol = GetMsgFontColor("MSG_TEAM", true) },
    ['TONG'] = { szName = _L['tong channel'], tCol = GetMsgFontColor("MSG_GUILD", true) },
    ['TONG_ALLIANCE'] = { szName = _L['tong alliance channel'], tCol = GetMsgFontColor("MSG_GUILD_ALLIANCE", true) },
    ['SENCE'] = { szName = _L['map channel'], tCol = GetMsgFontColor("MSG_MAP", true) },
    ['FORCE'] = { szName = _L['school channel'], tCol = GetMsgFontColor("MSG_SCHOOL", true) },
    ['CAMP'] = { szName = _L['camp channel'], tCol = GetMsgFontColor("MSG_CAMP", true) },
    ['WORLD'] = { szName = _L['world channel'], tCol = GetMsgFontColor("MSG_WORLD", true) },
}
_MY_TalkEx.Init = function()
    -------------------------------------
    -- 喊话部分
    -------------------------------------
    -- 喊话输入框
    MY.UI.AddEdit('TalkEx','WndEdit_TalkEx_Talk',25,25,510,210,MY_TalkEx.szTalk,true)
    MY.UI.RegisterEvent('WndEdit_TalkEx_Talk', {
        OnEditChanged = function() 
            MY_TalkEx.szTalk = this:GetText()
        end
    })
    -- 喊话频道
    local i = 22
    for szChannel, tChannel in pairs(_MY_TalkEx.tChannels) do
        MY.UI.AddCheckBox('TalkEx','WndCheckBox_TalkEx_'..szChannel,540,i,tChannel.szName,tChannel.tCol,MY_TalkEx.tTalkChannel[szChannel])
        MY.UI.RegisterEvent('WndCheckBox_TalkEx_'..szChannel, {
            OnCheckBoxCheck = function() 
                MY_TalkEx.tTalkChannel[szChannel] = true
            end,
            OnCheckBoxUncheck = function() 
                MY_TalkEx.tTalkChannel[szChannel] = false
            end
        })
        i = i + 18
    end
    -- 喊话按钮
    MY.UI.AddButton('TalkEx','WndButton_TalkEx_Talk',540,210,_L['send'],{255,255,255})
    MY.UI.RegisterEvent('WndButton_TalkEx_Talk', {
        OnLButtonClick = function() 
            for szChannel, bSend in pairs(MY_TalkEx.tTalkChannel) do
                if bSend then MY.Talk(PLAYER_TALK_CHANNEL[szChannel],MY_TalkEx.szTalk) end
            end
        end
    })
    -------------------------------------
    -- 调侃部分
    -------------------------------------
    -- 文本标题
    MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_With"):SetText(_L['have a trick with'])
    -- 调侃对象范围过滤器
    MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Filter"):SetText(_MY_TalkEx.tFilter[MY_TalkEx.tTrickFilter])
    MY.UI.RegisterEvent("Button_TalkEx_Trick_Filter", { 
        OnLButtonClick = function()
            local item = MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Filter")
            PopupMenu((function() 
                local t = {}
                for szFilterId,szTitle in pairs(_MY_TalkEx.tFilter) do
                    table.insert(t,{
                        szOption = szTitle,
                        fnAction = function()
                            item:SetText(szTitle)
                            MY_TalkEx.tTrickFilter = szFilterId
                        end,
                    })
                end
                return t
            end)())
        end
    })
    -- 调侃门派过滤器
    MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Force"):SetText(_MY_TalkEx.tForce[MY_TalkEx.tTrickFilterForce])
    MY.UI.RegisterEvent("Button_TalkEx_Trick_Force", { 
        OnLButtonClick = function()
            local item = MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Force")
            PopupMenu((function() 
                local t = {}
                for szFilterId,szTitle in pairs(_MY_TalkEx.tForce) do
                    table.insert(t,{
                        szOption = szTitle,
                        fnAction = function()
                            item:SetText(szTitle)
                            MY_TalkEx.tTrickFilterForce = szFilterId
                        end,
                    })
                end
                return t
            end)())
        end
    })
    -- 调侃内容输入框：第一句
    MY.UI.AddEdit('TalkEx','WndEdit_TalkEx_TrickBegin',25,285,510,25,MY_TalkEx.szTrickTextBegin,true)
    MY.UI.RegisterEvent('WndEdit_TalkEx_TrickBegin', {
        OnLButtonClick = function() 
            for szChannel, bSend in pairs(MY_TalkEx.tTalkChannel) do
                if bSend then MY.Talk(PLAYER_TALK_CHANNEL[szChannel],MY_TalkEx.szTrickTextBegin) end
            end
        end
    })
    -- 调侃内容输入框：调侃内容
    MY.UI.AddEdit('TalkEx','WndEdit_TalkEx_Trick',25,310,510,75,MY_TalkEx.szTrickText,true)
    MY.UI.RegisterEvent('WndEdit_TalkEx_Trick', {
        OnLButtonClick = function() 
            for szChannel, bSend in pairs(MY_TalkEx.tTalkChannel) do
                if bSend then MY.Talk(PLAYER_TALK_CHANNEL[szChannel],MY_TalkEx.szTrickText) end
            end
        end
    })
    -- 调侃内容输入框：最后一句
    MY.UI.AddEdit('TalkEx','WndEdit_TalkEx_TrickEnd',25,385,510,25,MY_TalkEx.szTrickTextEnd,true)
    MY.UI.RegisterEvent('WndEdit_TalkEx_TrickEnd', {
        OnLButtonClick = function() 
            for szChannel, bSend in pairs(MY_TalkEx.tTalkChannel) do
                if bSend then MY.Talk(PLAYER_TALK_CHANNEL[szChannel],MY_TalkEx.szTrickTextEnd) end
            end
        end
    })
    -- 调侃发送频道提示框
    MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Sendto"):SetText(_L['send to'])
    -- 调侃发送频道
    MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Sendto_Filter"):SetText(_MY_TalkEx.tChannels[MY_TalkEx.tTrickChannel].szName)
    MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Sendto_Filter"):SetFontColor(unpack(_MY_TalkEx.tChannels[MY_TalkEx.tTrickChannel].tCol))
    MY.UI.RegisterEvent("Button_TalkEx_Trick_Sendto_Filter", { 
        OnLButtonClick = function()
            local item = MY.UI.Lookup("TalkEx","","Text_TalkEx_Trick_Sendto_Filter")
            PopupMenu((function() 
                local t = {}
                for szChannel,tChannel in pairs(_MY_TalkEx.tChannels) do
                    table.insert(t,{
                        szOption = tChannel.szName,
                        fnAction = function()
                            item:SetText(tChannel.szName)
                            item:SetFontColor(unpack(tChannel.tCol))
                            MY_TalkEx.tTrickChannel = szChannel
                        end,
                        rgb = tChannel.tCol,
                    })
                end
                return t
            end)())
        end
    })
    -- 调侃按钮
    MY.UI.AddButton('TalkEx','WndButton_TalkEx_Trick',435,415,_L['have a trick with'],{255,255,255})
    MY.UI.RegisterEvent("WndButton_TalkEx_Trick", { 
        OnLButtonClick = function()
            MY.Talk(PLAYER_TALK_CHANNEL[MY_TalkEx.tTrickChannel], MY_TalkEx.szTrickTextBegin)
            local tPlayers = {}
            if MY_TalkEx.tTrickFilter == 'RAID' then
                for _, i in pairs(GetClientTeam().GetTeamMemberList()) do
                    if GetPlayer(i) then table.insert(tPlayers, GetPlayer(i)) end
                end
            elseif MY_TalkEx.tTrickFilter == 'NEARBY' then
                tPlayers = MY.GetNearPlayer()
            end
            
            for _, player in pairs(tPlayers) do
                if MY_TalkEx.tTrickFilterForce == -1 or MY_TalkEx.tTrickFilterForce == player.dwForceID then
                    local szText = string.gsub(MY_TalkEx.szTrickText, "%$mb", '['..player.szName..']')
                    MY.Talk(PLAYER_TALK_CHANNEL[MY_TalkEx.tTrickChannel], szText)
                end
            end
            MY.Talk(PLAYER_TALK_CHANNEL[MY_TalkEx.tTrickChannel], MY_TalkEx.szTrickTextEnd)
        end
    })
end
MY.RegisterPanel( "TalkEx", _L["talk ex"], "interface\\MY\\ui\\MY_TalkEx.ini", _MY_TalkEx.Init, "UI/Image/UICommon/ScienceTreeNode.UITex", 123, {255,255,0,200} )
MY.RegisterEvent("CUSTOM_DATA_LOADED", _MY_TalkEx.Init)
-- MY.RegisterEvent("LOADING_END", _MY_TalkEx.Init)