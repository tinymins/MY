--
-- 其他功能
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140510
--
-- 主要功能: 共站检查 好友头顶
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _MY_ToolBox = {}
MY_ToolBox = {}
MY_ToolBox.bFriendHeadTip = false
RegisterCustomData("MY_ToolBox.bFriendHeadTip")

_MY_ToolBox.FriendHeadTip = function(bEnable)
    if bEnable then
        local frm = MY.UI.CreateFrame("MY_Shadow",true,true):show()
        local fnPlayerEnter = function(dwID)
            local p = MY.Player.GetFriend(dwID)
            if p then
                local shadow = frm:append("MY_FRIEND_TIP"..dwID,"Shadow"):find("#MY_FRIEND_TIP"..dwID):raw(1)
                if shadow then
                    local r,g,b,a = 255,255,255,255
                    local szTip = ">> "..p.name.." <<"
                    shadow:ClearTriangleFanPoint()
                    shadow:SetTriangleFan(GEOMETRY_TYPE.TEXT)
                    shadow:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
                    --shadow:AppendCharacterID(dwCharacterID, bCharacterTop, r, g, b, a [[,fTopDelta, dwFontSchemeID, szText, fSpace, fScale]])
                    shadow:Show()
                end
            end
        end
        MY.RegisterEvent("PLAYER_ENTER_SCENE","MY_FRIEND_TIP",fnPlayerEnter)
        MY.RegisterEvent("PLAYER_LEAVE_SCENE","MY_FRIEND_TIP",function(arg0)
            frm:find("#MY_FRIEND_TIP"..arg0):remove()
        end)
        for _, p in pairs(MY.Player.GetNearPlayer()) do
            fnPlayerEnter(p.dwID)
        end
    else
        MY.RegisterEvent("PLAYER_ENTER_SCENE","MY_FRIEND_TIP")
        MY.RegisterEvent("PLAYER_LEAVE_SCENE","MY_FRIEND_TIP")
        MY.UI("Lowest/MY_Shadow"):remove()
    end
end

-- 注册INIT事件
MY.RegisterInit(function()
    if MY_ToolBox.bFriendHeadTip then _MY_ToolBox.FriendHeadTip(true) end
end)
-- 标签栏激活
_MY_ToolBox.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    ui:append('WndButton_GongzhanCheck', 'WndButton'):children('#WndButton_GongzhanCheck'):text(_L['check nearby gongzhan']):width(120):pos(20,50):click(function()
        -- (number) TMS.FrameToSecondLeft(nEndFrame)     -- 获取nEndFrame剩余秒数
        local FrameToSecondLeft = function(nEndFrame)
            local nLeftFrame = nEndFrame - GetLogicFrameCount()
            return nLeftFrame / 16
        end
        local IsGongZhan = function(obj)
            for k, v in pairs(MY.Player.GetBuffList(obj)) do
                if string.find(Table_GetBuffName(v.dwID, v.nLevel), "共战") ~= nil then
                    MY.Talk( PLAYER_TALK_CHANNEL.RAID, _L("检测到[%s]共战BUFF剩余%d秒。", obj.szName, FrameToSecondLeft(v.nEndFrame) ) )
                    return true
                end
            end
            return false
        end
        local i = 0
        for k, v in pairs(MY.GetNearPlayer()) do
            if IsGongZhan(v) then
                i = i + 1
            end
        end
        MY.Talk(PLAYER_TALK_CHANNEL.RAID, "附近共战数量："..i.."。")
    end)
    ui:append("WndCheckBox_FriendHeadTip", "WndCheckBox"):children("#WndCheckBox_FriendHeadTip"):pos(20,20):text(_L['friend headtop tips']):check(MY_ToolBox.bFriendHeadTip):check(function(bCheck)
        MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
        _MY_ToolBox.FriendHeadTip(MY_ToolBox.bFriendHeadTip)
    end)
end
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], "UI/Image/Helper/Help.UITex|26", {255,255,0,200}, { OnPanelActive = _MY_ToolBox.OnPanelActive } )
