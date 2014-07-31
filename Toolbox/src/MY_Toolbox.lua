--
-- 其他功能
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140510
--
-- 主要功能: 共站检查 好友头顶
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")
local _MY_ToolBox = {
    bFighting = false,
    nLastFightStartTimestarp = -1,
    nLastFightEndTimestarp = -1,
}
MY_ToolBox = {}
MY_ToolBox.bFriendHeadTip = false
RegisterCustomData("MY_ToolBox.bFriendHeadTip")
MY_ToolBox.InfoTip = {
    -- FPS
    FPS       = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-190, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['fps monitor'],
                  breathe = function() MY.UI(this):find("#Text_Default"):text(_L("FPS: %d", GetFPS())) end },
    -- 目标距离
    Distance  = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-160, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['target distance'],
                  breathe = function()
                    local p, s = (MY.Player.GetTarget()), _L["No Target"]
                    if p then
                        s = _L('Distance: %d Foot', GetCharacterDistance(GetClientPlayer().dwID, p.dwID)/64)
                    end
                    MY.UI(this):find("#Text_Default"):text(s)
                  end },
    -- 系统时间
    SysTime   = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-130, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['system time'],
                  breathe = function()
                    local tDateTime = TimeToDate(GetCurrentTime())
                    MY.UI(this):find("#Text_Default"):text(_L("Time: %02d:%02d:%02d", tDateTime.hour, tDateTime.minute, tDateTime.second))
                  end },
    -- 战斗计时
    FightTime = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-100, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['fight clock'],
                  breathe = function()
                    local s, nTotal = _L["Never Fight"], 0
                    -- 判定战斗边界
                    if GetClientPlayer().bFightState then
                        -- 进入战斗判断
                        if not _MY_ToolBox.bFighting then
                            _MY_ToolBox.bFighting = true
                            -- 5秒脱战判定缓冲 防止明教隐身错误判定
                            if GetLogicFrameCount() - _MY_ToolBox.nLastFightEndTimestarp > 16*5 then
                                _MY_ToolBox.nLastFightStartTimestarp = GetLogicFrameCount()
                            end
                        end
                        nTotal = GetLogicFrameCount() - _MY_ToolBox.nLastFightStartTimestarp
                    else
                        -- 退出战斗判定
                        if _MY_ToolBox.bFighting then
                            _MY_ToolBox.bFighting = false
                            _MY_ToolBox.nLastFightEndTimestarp = GetLogicFrameCount()
                        end
                        if _MY_ToolBox.nLastFightStartTimestarp > 0 then 
                            nTotal = _MY_ToolBox.nLastFightEndTimestarp - _MY_ToolBox.nLastFightStartTimestarp
                        end
                    end
                    
                    if nTotal > 0 then
                        nTotal = nTotal/16
                        s = _L("Fight Clock: %d:%02d:%02d", math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60))
                    end
                    MY.UI(this):find("#Text_Default"):text(s)
                  end },
    -- 莲花和藕倒计时
    LotusTime = { bEnable = false, bShowBg = true, anchor =  { x=-10, y=-70, s="BOTTOMRIGHT", r="BOTTOMRIGHT" }, title = _L['lotus clock'],
                  breathe = function()
                    local nTotal = 6*60*60 - GetLogicFrameCount()/16%(6*60*60)
                    MY.UI(this):find("#Text_Default"):text(_L("Lotus Clock: %d:%d:%d", math.floor(nTotal/(60*60)), math.floor(nTotal/60%60), math.floor(nTotal%60)))
                  end },
}
for k, v in pairs(MY_ToolBox.InfoTip) do
    RegisterCustomData("MY_ToolBox.InfoTip."..k..".bEnable")
    RegisterCustomData("MY_ToolBox.InfoTip."..k..".bShowBg")
    RegisterCustomData("MY_ToolBox.InfoTip."..k..".anchor")
end

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
_MY_ToolBox.ReloadInfoTip = function()
    for id, p in pairs(MY_ToolBox.InfoTip) do
        local frm = MY.UI('Normal/MY_InfoTip_'..id)
        if p.bEnable then
            if frm:count()==0 then
                frm = MY.UI.CreateFrame('MY_InfoTip_'..id,true):size(150,30):onevent("UI_SCALED", function()
                    MY.UI(this):anchor(p.anchor)
                end):customMode(p.title, function(anchor)
                    p.anchor = anchor
                end, function(anchor)
                    p.anchor = anchor
                end):breathe(p.breathe):drag(0,0,0,0):drag(false)
                frm:append("Image_Default","Image"):find("#Image_Default"):size(150,30):image("UI/Image/UICommon/Commonpanel.UITex",86):alpha(180)
                frm:append("Text_Default", "Text"):find("#Text_Default"):size(150,30):text(p.title):font(2):raw(1):SetHAlign(1)
                -- frm:find("#Text_Default"):raw(1):SetVAlign(1)
            end
            if p.bShowBg then
                frm:find("#Image_Default"):show()
            else
                frm:find("#Image_Default"):hide()
            end
            frm:anchor(p.anchor)
        else
            frm:remove()
        end
    end
end
-- 注册INIT事件
MY.RegisterInit(function()
    if MY_ToolBox.bFriendHeadTip then _MY_ToolBox.FriendHeadTip(true) end
    _MY_ToolBox.ReloadInfoTip()
end)
-- 标签栏激活
_MY_ToolBox.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    
    ui:append('WndButton_GongzhanCheck', 'WndButton'):children('#WndButton_GongzhanCheck'):pos(150,20):width(120)
      :text(_L['check nearby gongzhan'])
      :click(function()
        -- (number) TMS.FrameToSecondLeft(nEndFrame)     -- 获取nEndFrame剩余秒数
        local FrameToSecondLeft = function(nEndFrame)
            local nLeftFrame = nEndFrame - GetLogicFrameCount()
            return nLeftFrame / 16
        end
        local IsGongZhan = function(obj)
            for k, v in pairs(MY.Player.GetBuffList(obj)) do
                if (not v.bCanCancel) and string.find(Table_GetBuffName(v.dwID, v.nLevel), "共战") ~= nil then
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
    ui:append("WndCheckBox_FriendHeadTip", "WndCheckBox"):children("#WndCheckBox_FriendHeadTip"):pos(20,20)
      :text(_L['friend headtop tips']):check(MY_ToolBox.bFriendHeadTip)
      :check(function(bCheck)
        MY_ToolBox.bFriendHeadTip = not MY_ToolBox.bFriendHeadTip
        _MY_ToolBox.FriendHeadTip(MY_ToolBox.bFriendHeadTip)
    end)
    
    local x, y = 20, 50
    ui:append("Text_InfoTip", "Text"):find("#Text_InfoTip"):text(_L['* infomation tips']):color(255,255,0):pos(x, y)
    y = y + 30
    for id, p in pairs(MY_ToolBox.InfoTip) do
        ui:append("WndCheckBox_InfoTip_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTip_"..id):pos(x, y)
          :text(p.title):check(MY_ToolBox.InfoTip[id].bEnable)
          :check(function(bChecked)
            MY_ToolBox.InfoTip[id].bEnable = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 120
        ui:append("WndCheckBox_InfoTipBg_"..id, "WndCheckBox"):children("#WndCheckBox_InfoTipBg_"..id):pos(x, y)
          :text(_L['show background']):check(MY_ToolBox.InfoTip[id].bShowBg)
          :check(function(bChecked)
            MY_ToolBox.InfoTip[id].bShowBg = bChecked
            _MY_ToolBox.ReloadInfoTip()
          end)
        x = x + 150
        if x + 150 > w then
            x, y = 20, y + 30
        end
    end
end
MY.RegisterPanel( "MY_ToolBox", _L["toolbox"], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, { OnPanelActive = _MY_ToolBox.OnPanelActive } )
