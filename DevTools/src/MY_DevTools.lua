--
-- 开发者工具
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."DevTools/lang/")
local _Cache = {}
MY_DevTools = {}
MY_DevTools.bShowTreePath = false
RegisterCustomData('MY_DevTools.bShowTreePath')

_Cache.OnFrameBreathe = function()
    local ui = MY.UI(_Cache.frame)
    if MY_DevTools.bShowTreePath then
        local wnd = Station.GetMouseOverWindow()
        if wnd then
            local W, H = Station.GetClientSize()
            local x, y = wnd:GetAbsPos()
            local w, h = wnd:GetSize()
            local uiHdlTip = ui:hdl():children('#Handle_Tip'):show()
            local uiTxtTip = uiHdlTip:item('#Text_HoverTip')
            ui:item("#Shadow_HoverWndLeft"):pos(x - 1, 0):show()
            ui:item("#Shadow_HoverWndRight"):pos(x + w, 0):show()
            ui:item("#Shadow_HoverWndTop"):pos(0, y - 1):show()
            ui:item("#Shadow_HoverWndBottom"):pos(0, y + h):show()
            
            local wT, hT = uiTxtTip:size()
            local xT, yT
            xT = x + 5
            if xT + wT > W then
                xT = W - wT
            elseif xT < 0 then
                xT = 0
            end
            
            if y >= hT then -- 顶部可以显示的下
                yT = y - hT
            elseif y + h + 1 + hT <= H then -- 底部显示的下
                yT = y + h + 1
            else
                yT = y + 20
            end
            
            uiTxtTip:text(string.format(
                'name: %s\ntype: %s\npath: %s\nx: %s\ny: %s\nw: %s\nh: %s',
                wnd:GetName(),
                wnd:GetType(),
                wnd:GetTreePath(),
                x, y,
                w, h
            ))
            uiHdlTip:pos(xT, yT)
        end
    else
        ui:item("#^Shadow_HoverWnd"):hide()
        ui:hdl():children('#Handle_Tip'):hide()
    end
    ui:bringToTop()
end

local SNAPLINES_RGB = {255, 255, 255}
local TIP_RGB = {255, 0, 0}
MY.RegisterInit(function()
    _Cache.frame = MY.UI.CreateFrame('MY_DevTools', MY.Const.UI.Frame.TOPMOST2_EMPTY):raw(1)
    local ui = MY.UI(_Cache.frame)
    local W, H = Station.GetClientSize()
    ui:size(W, H)
      :penetrable(true)
      :breathe(_Cache.OnFrameBreathe)
    
    ui:append("Shadow_HoverWndLeft", "Shadow"):item("#Shadow_HoverWndLeft")
      :size(2, H):pos(0, 0):color(SNAPLINES_RGB)
    ui:append("Shadow_HoverWndRight", "Shadow"):item("#Shadow_HoverWndRight")
      :size(2, H):pos(W, 0):color(SNAPLINES_RGB)
    ui:append("Shadow_HoverWndTop", "Shadow"):item("#Shadow_HoverWndTop")
      :size(W, 2):pos(0, 0):color(SNAPLINES_RGB)
    ui:append("Shadow_HoverWndBottom", "Shadow"):item("#Shadow_HoverWndBottom")
      :size(W, 2):pos(0, H):color(SNAPLINES_RGB)
    ui:hdl():append('<handle>name="Handle_Tip" handletype=3</handle>'):children('#Handle_Tip')
      :append("<text>name=\"Text_HoverTip\" font=99 </text>"):item("#Text_HoverTip")
      :pos(0, 0):color(TIP_RGB):multiLine(true)
end)

_Cache.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    
    ui:append("WndCheckBox_ShowTreePath", "WndCheckBox"):children("#WndCheckBox_ShowTreePath")
      :pos(20,20):width(200)
      :text(_L['enable tree path view']):check(MY_DevTools.bShowTreePath or false)
      :check(function(bCheck)
        MY_DevTools.bShowTreePath = bCheck
        _Cache.OnFrameBreathe()
    end)
    
    ui:append("Text_SetHotkey", "Text"):find("#Text_SetHotkey"):pos(w-140, 20):color(255,255,0)
      :text(_L['>> set hotkey <<'])
      :click(function() MY.Game.SetHotKey() end)
end

MY.RegisterPanel( "DevTools", _L["Dev Tools"], _L['General'], "ui/Image/UICommon/PlugIn.UITex|1", {255,127,0,200}, {
    OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = nil
})