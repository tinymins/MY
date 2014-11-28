--
-- 开发者工具
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
-- 
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Dev_Snaplines/lang/")
local _Cache = {}
MYDev_Snaplines = {}
MYDev_Snaplines.bShowTreePath = false
RegisterCustomData('MYDev_Snaplines.bShowTreePath')
MYDev_Snaplines.bDetectBox = true
RegisterCustomData('MYDev_Snaplines.bDetectBox')
MYDev_Snaplines.bShowWndSnaplines = true
RegisterCustomData('MYDev_Snaplines.bShowWndSnaplines')
MYDev_Snaplines.bShowItemSnaplines = true
RegisterCustomData('MYDev_Snaplines.bShowItemSnaplines')
MYDev_Snaplines.bShowTip = true
RegisterCustomData('MYDev_Snaplines.bShowTip')
MYDev_Snaplines.rgbWndSnaplines = {0, 0, 0}
RegisterCustomData('MYDev_Snaplines.rgbWndSnaplines')
MYDev_Snaplines.rgbItemSnaplines = {0, 255, 0}
RegisterCustomData('MYDev_Snaplines.rgbItemSnaplines')
MYDev_Snaplines.rgbTip = {255, 255, 0}
RegisterCustomData('MYDev_Snaplines.rgbTip')
MYDev_Snaplines.nTipFont = 40
RegisterCustomData('MYDev_Snaplines.nTipFont')

MYDev_Snaplines.GetElementTip = function(raw, tTip)
    if type(tTip) ~= 'table' then
        tTip = {}
    else
        tTip = clone(tTip)
    end
    
    local x, y = raw:GetAbsPos()
    local w, h = raw:GetSize()
    table.insert(tTip, _L('Name: %s', raw:GetName()))
    table.insert(tTip, _L('Type: %s', raw:GetType()))
    table.insert(tTip, _L('Path: %s', raw:GetTreePath()))
    table.insert(tTip, _L('X: %s', x))
    table.insert(tTip, _L('Y: %s', y))
    table.insert(tTip, _L('W: %s', w))
    table.insert(tTip, _L('H: %s', h))
    
    local szType = raw:GetType()
    if szType == 'Text' then
        table.insert(tTip, _L('FontScheme: %s', raw:GetFontScheme()))
        table.insert(tTip, _L('Text: %s', raw:GetText()))
        table.insert(tTip, _L('TextLen: %s', raw:GetTextLen()))
        table.insert(tTip, _L('VAlign: %s', raw:GetVAlign()))
        table.insert(tTip, _L('HAlign: %s', raw:GetHAlign()))
        table.insert(tTip, _L('RowSpacing: %s', raw:GetRowSpacing()))
        table.insert(tTip, _L('IsMultiLine: %s', tostring(raw:IsMultiLine())))
        table.insert(tTip, _L('IsCenterEachLine: %s', tostring(raw:IsCenterEachLine())))
        table.insert(tTip, _L('FontSpacing: %s', raw:GetFontSpacing()))
        table.insert(tTip, _L('IsRichText: %s', tostring(raw:IsRichText())))
        table.insert(tTip, _L('FontScale: %s', raw:GetFontScale()))
        table.insert(tTip, _L('FontID: %s', raw:GetFontID()))
        table.insert(tTip, _L('FontColor: %s', raw:GetFontColor()))
        table.insert(tTip, _L('FontBoder: %s', raw:GetFontBoder()))
        table.insert(tTip, _L('FontProjection: %s', raw:GetFontProjection()))
        table.insert(tTip, _L('TextExtent: %s', raw:GetTextExtent()))
        table.insert(tTip, _L('TextPosExtent: %s', raw:GetTextPosExtent()))
    elseif szType == 'Image' then
        table.insert(tTip, _L('Frame: %s', raw:GetFrame()))
        table.insert(tTip, _L('ImageType: %s', raw:GetImageType()))
        table.insert(tTip, _L('ImageID: %s', raw:GetImageID()))
    elseif szType == 'Shadow' then
        table.insert(tTip, _L('ShadowColor: %s', raw:GetShadowColor()))
        table.insert(tTip, _L('ColorRGB: %s, %s, %s', raw:GetColorRGB()))
        table.insert(tTip, _L('IsTriangleFan: %s', tostring(raw:IsTriangleFan())))
    elseif szType == 'Animate' then
        table.insert(tTip, _L('IsFinished: %s', tostring(raw:IsFinished())))
    elseif szType == 'Box' then
        table.insert(tTip, _L('BoxIndex: %s', raw:GetBoxIndex()))
        -- table.insert(tTip, _L('Object: %s', raw:GetObject()))
        table.insert(tTip, _L('ObjectType: %s', raw:GetObjectType()))
        table.insert(tTip, _L('ObjectData: %s', raw:GetObjectData()))
        table.insert(tTip, _L('IsEmpty: %s', tostring(raw:IsEmpty())))
        if not raw:IsEmpty() then
            table.insert(tTip, _L('IsObjectEnable: %s', tostring(raw:IsObjectEnable())))
            table.insert(tTip, _L('IsObjectCoolDown: %s', tostring(raw:IsObjectCoolDown())))
            table.insert(tTip, _L('IsObjectSelected: %s', tostring(raw:IsObjectSelected())))
            table.insert(tTip, _L('IsObjectMouseOver: %s', tostring(raw:IsObjectMouseOver())))
            table.insert(tTip, _L('IsObjectPressed: %s', tostring(raw:IsObjectPressed())))
            table.insert(tTip, _L('CoolDownPercentage: %s', raw:GetCoolDownPercentage()))
            table.insert(tTip, _L('ObjectIcon: %s', raw:GetObjectIcon()))
            table.insert(tTip, _L('OverText1: %s', raw:GetOverText(1)))
            table.insert(tTip, _L('OverTextFontScheme1: %s', raw:GetOverTextFontScheme(1)))
            table.insert(tTip, _L('OverTextPosition1: %s', raw:GetOverTextPosition(1)))
            table.insert(tTip, _L('OverText2: %s', raw:GetOverText(2)))
            table.insert(tTip, _L('OverTextFontScheme2: %s', raw:GetOverTextFontScheme(2)))
            table.insert(tTip, _L('OverTextPosition2: %s', raw:GetOverTextPosition(2)))
            table.insert(tTip, _L('OverText3: %s', raw:GetOverText(3)))
            table.insert(tTip, _L('OverTextFontScheme3: %s', raw:GetOverTextFontScheme(3)))
            table.insert(tTip, _L('OverTextPosition3: %s', raw:GetOverTextPosition(3)))
            table.insert(tTip, _L('OverText4: %s', raw:GetOverText(4)))
            table.insert(tTip, _L('OverTextFontScheme4: %s', raw:GetOverTextFontScheme(4)))
            table.insert(tTip, _L('OverTextPosition4: %s', raw:GetOverTextPosition(4)))
        end

    end
    
    return tTip
end

_Cache.OnFrameBreathe = function()
    local ui = MY.UI(_Cache.frame)
    if MYDev_Snaplines.bShowTreePath then
        local wnd, item = Station.GetMouseOverWindow()
        if wnd then
            local W, H = Station.GetClientSize()
            local xC, yC = Cursor.GetPos()
            local xW, yW = wnd:GetAbsPos()
            local wW, hW = wnd:GetSize()
            local uiHdlTip = ui:hdl():children('#Handle_Tip'):show()
            local uiTxtTip = uiHdlTip:item('#Text_HoverTip')
            local tTip = {}
            table.insert(tTip, _L('CursorX: %s', xC))
            table.insert(tTip, _L('CursorY: %s', yC))
            tTip = MYDev_Snaplines.GetElementTip(wnd, tTip)
            ui:item("#Shadow_HoverWndLeft"):pos(xW - 2, 0):show()
            ui:item("#Shadow_HoverWndRight"):pos(xW + wW, 0):show()
            ui:item("#Shadow_HoverWndTop"):pos(0, yW - 2):show()
            ui:item("#Shadow_HoverWndBottom"):pos(0, yW + hW):show()
            if MYDev_Snaplines.bDetectBox and not (item and item:GetType() == 'Box') then
                MY.UI(wnd):find('.Box'):each(function()
                    local x, y = this:GetAbsPos()
                    local w, h = this:GetSize()
                    if xC >= x and xC <= x + w and yC >= y and yC <= y + h then
                        table.insert(tTip, '---------------------')
                        tTip = MYDev_Snaplines.GetElementTip(this, tTip)
                    end
                end)
            end
            if item then
                local xI, yI = item:GetAbsPos()
                local wI, hI = item:GetSize()
                table.insert(tTip, _L['-------------------'])
                tTip = MYDev_Snaplines.GetElementTip(item, tTip)
                ui:item("#Shadow_HoverItemLeft"):pos(xI - 2, 0):show()
                ui:item("#Shadow_HoverItemRight"):pos(xI + wI, 0):show()
                ui:item("#Shadow_HoverItemTop"):pos(0, yI - 2):show()
                ui:item("#Shadow_HoverItemBottom"):pos(0, yI + hI):show()
            else
                ui:item("#^Shadow_HoverItem"):hide()
            end
            uiTxtTip:text(table.concat(tTip, '\n'))
            
            local wT, hT = uiTxtTip:size()
            local xT, yT
            xT = xW + 5
            if xT + wT > W then
                xT = W - wT
            elseif xT < 0 then
                xT = 0
            end
            
            local bReAdjustX
            if yW >= hT then -- 顶部可以显示的下
                yT = yW - hT
            elseif yW + hW + 1 + hT <= H then -- 底部显示的下
                yT = yW + hW + 1
            elseif yW + hT <= H then -- 中间开始显示的下
                yT = yW + 20
                bReAdjustX = true
            else
                yT = 5
                bReAdjustX = true
            end
            if bReAdjustX then
                if xW >= wT + 5 then -- 左侧显示的下
                    xT = xW - wT - 5
                elseif xW + wW + wT + 5 <= W then -- 右侧显示的下
                    xT = xW + wW + 5
                end
            end
            
            uiHdlTip:pos(xT, yT)
        end
    else
        ui:item("#^Shadow_HoverWnd"):hide()
        ui:item("#^Shadow_HoverItem"):hide()
        ui:hdl():children('#Handle_Tip'):hide()
    end
    ui:bringToTop()
end

MYDev_Snaplines.ReloadUI = function()
    _Cache.frame = MY.UI.CreateFrame('MYDev_Snaplines', MY.Const.UI.Frame.TOPMOST2_EMPTY):raw(1)
    local ui = MY.UI(_Cache.frame)
    local W, H = Station.GetClientSize()
    ui:size(W, H)
      :penetrable(true)
      :breathe(_Cache.OnFrameBreathe)
    
    if MYDev_Snaplines.bShowWndSnaplines then
        ui:append("Shadow_HoverWndLeft", "Shadow"):item("#Shadow_HoverWndLeft")
          :size(2, H):pos(0, 0):color(MYDev_Snaplines.rgbWndSnaplines)
        ui:append("Shadow_HoverWndRight", "Shadow"):item("#Shadow_HoverWndRight")
          :size(2, H):pos(W, 0):color(MYDev_Snaplines.rgbWndSnaplines)
        ui:append("Shadow_HoverWndTop", "Shadow"):item("#Shadow_HoverWndTop")
          :size(W, 2):pos(0, 0):color(MYDev_Snaplines.rgbWndSnaplines)
        ui:append("Shadow_HoverWndBottom", "Shadow"):item("#Shadow_HoverWndBottom")
          :size(W, 2):pos(0, H):color(MYDev_Snaplines.rgbWndSnaplines)
    end
    
    if MYDev_Snaplines.bShowItemSnaplines then
        ui:append("Shadow_HoverItemLeft", "Shadow"):item("#Shadow_HoverItemLeft")
          :size(2, H):pos(0, 0):color(MYDev_Snaplines.rgbItemSnaplines)
        ui:append("Shadow_HoverItemRight", "Shadow"):item("#Shadow_HoverItemRight")
          :size(2, H):pos(W, 0):color(MYDev_Snaplines.rgbItemSnaplines)
        ui:append("Shadow_HoverItemTop", "Shadow"):item("#Shadow_HoverItemTop")
          :size(W, 2):pos(0, 0):color(MYDev_Snaplines.rgbItemSnaplines)
        ui:append("Shadow_HoverItemBottom", "Shadow"):item("#Shadow_HoverItemBottom")
          :size(W, 2):pos(0, H):color(MYDev_Snaplines.rgbItemSnaplines)
    end
    
    if MYDev_Snaplines.bShowTip then
        ui:hdl():append('<handle>name="Handle_Tip" handletype=3</handle>'):children('#Handle_Tip')
          :append("<text>name=\"Text_HoverTip\" </text>"):item("#Text_HoverTip")
          :pos(0, 0):font(MYDev_Snaplines.nTipFont):color(MYDev_Snaplines.rgbTip):multiLine(true)
    end

    MY.RegisterEvent('UI_SCALED', 'MYDev_Snaplines', function()
        local W, H = Station.GetClientSize()
        ui:size(W, H)
        ui:item("#Shadow_HoverWndLeft"):size(2, H)
        ui:item("#Shadow_HoverWndRight"):size(2, H)
        ui:item("#Shadow_HoverWndTop"):size(W, 2)
        ui:item("#Shadow_HoverWndBottom"):size(W, 2)
        ui:item("#Shadow_HoverItemLeft"):size(2, H)
        ui:item("#Shadow_HoverItemRight"):size(2, H)
        ui:item("#Shadow_HoverItemTop"):size(W, 2)
        ui:item("#Shadow_HoverItemBottom"):size(W, 2)
    end)
end
MY.RegisterInit(MYDev_Snaplines.ReloadUI)

_Cache.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    local x, y = 20, 20
    
    ui:append("WndCheckBox_ShowTreePath", "WndCheckBox"):children("#WndCheckBox_ShowTreePath")
      :pos(x, y):width(300)
      :text(_L['enable tree path view']):check(MYDev_Snaplines.bShowTreePath or false)
      :check(function(bCheck)
        MYDev_Snaplines.bShowTreePath = bCheck
    end)
    y = y + 40
    
    ui:append("WndCheckBox_ShowTip", "WndCheckBox"):children("#WndCheckBox_ShowTip")
      :pos(x, y):width(200)
      :text(_L['show tip']):check(MYDev_Snaplines.bShowTip or false)
      :check(function(bCheck)
        MYDev_Snaplines.bShowTip = bCheck
        MYDev_Snaplines.ReloadUI()
    end)
    x = x + 200
    ui:append("Shadow_TipColor", "Shadow"):item("#Shadow_TipColor"):pos(x, y)
      :size(20, 20):color(MYDev_Snaplines.rgbTip or {255,255,255})
      :click(function()
        local me = this
        MY.UI.OpenColorPicker(function(r, g, b)
            MY.UI(me):color(r, g, b)
            MYDev_Snaplines.rgbTip = { r, g, b }
            MYDev_Snaplines.ReloadUI()
        end)
      end)
    x = x + 40
    ui:append("WndButton_TipFont", "WndButton"):children("#WndButton_TipFont"):pos(x, y)
      :width(50):text(_L['font'])
      :click(function()
        MY.UI.OpenFontPicker(function(f)
            MYDev_Snaplines.nTipFont = f
            MYDev_Snaplines.ReloadUI()
        end)
      end)
    x = 20
    y = y + 40
    
    ui:append("WndCheckBox_ShowWndSnaplines", "WndCheckBox"):children("#WndCheckBox_ShowWndSnaplines")
      :pos(x, y):width(200)
      :text(_L['show wnd snaplines']):check(MYDev_Snaplines.bShowWndSnaplines or false)
      :check(function(bCheck)
        MYDev_Snaplines.bShowWndSnaplines = bCheck
        MYDev_Snaplines.ReloadUI()
    end)
    x = x + 200
    ui:append("Shadow_WndSnaplinesColor", "Shadow"):item("#Shadow_WndSnaplinesColor"):pos(x, y)
      :size(20, 20):color(MYDev_Snaplines.rgbWndSnaplines or {255,255,255})
      :click(function()
        local me = this
        MY.UI.OpenColorPicker(function(r, g, b)
            MY.UI(me):color(r, g, b)
            MYDev_Snaplines.rgbWndSnaplines = { r, g, b }
            MYDev_Snaplines.ReloadUI()
        end)
      end)
    x = 20
    y = y + 40
    
    ui:append("WndCheckBox_ShowItemSnaplines", "WndCheckBox"):children("#WndCheckBox_ShowItemSnaplines")
      :pos(x, y):width(200)
      :text(_L['show item snaplines']):check(MYDev_Snaplines.bShowItemSnaplines or false)
      :check(function(bCheck)
        MYDev_Snaplines.bShowItemSnaplines = bCheck
        MYDev_Snaplines.ReloadUI()
    end)
    x = x + 200
    ui:append("Shadow_ItemSnaplinesColor", "Shadow"):item("#Shadow_ItemSnaplinesColor"):pos(x, y)
      :size(20, 20):color(MYDev_Snaplines.rgbItemSnaplines or {255,255,255})
      :click(function()
        local me = this
        MY.UI.OpenColorPicker(function(r, g, b)
            MY.UI(me):color(r, g, b)
            MYDev_Snaplines.rgbItemSnaplines = { r, g, b }
            MYDev_Snaplines.ReloadUI()
        end)
      end)
    x = 20
    y = y + 40
    
    ui:append("WndCheckBox_AutoDetectBox", "WndCheckBox"):children("#WndCheckBox_AutoDetectBox")
      :pos(x, y):width(200)
      :text(_L['auto detect box']):check(MYDev_Snaplines.bDetectBox or false)
      :check(function(bCheck)
        MYDev_Snaplines.bDetectBox = bCheck
    end)
    y = y + 40
    
    ui:append("Text_SetHotkey", "Text"):find("#Text_SetHotkey"):pos(w-140, 20):color(255,255,0)
      :text(_L['>> set hotkey <<'])
      :click(function() MY.Game.SetHotKey() end)
end

MY.RegisterPanel( "Dev_Snaplines", _L["Snaplines"], _L['Development'], "ui/Image/UICommon/PlugIn.UITex|1", {255,127,0,200}, {
    OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = nil
})