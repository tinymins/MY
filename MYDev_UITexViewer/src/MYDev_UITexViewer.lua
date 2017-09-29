--
-- 开发者工具
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140730
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MYDev_UITexViewer/lang/")
local _Cache = {}
MYDev_UITexViewer = {}
MYDev_UITexViewer.szUITexPath = ''
RegisterCustomData('MYDev_UITexViewer.szUITexPath')

_Cache.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local w, h = ui:size()
    local x, y = 20, 20

    _Cache.tUITexList = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. 'MYDev_UITexViewer/data/data.jx3dat') or {}

    local uiBoard = ui:append("WndScrollBox", "WndScrollBox_ImageList")
      :children('#WndScrollBox_ImageList')
      :handleStyle(3):pos(x, y+25):size(w-21, h - 70)

    local uiEdit = ui:append("WndEditBox", "WndEdit_Copy"):children('#WndEdit_Copy')
      :pos(x, h-30):size(w-20, 25):multiLine(true)

    ui:append("WndAutocomplete", "WndAutocomplete_UITexPath"):children('#WndAutocomplete_UITexPath')
      :pos(x, y):size(w-20, 25):text(MYDev_UITexViewer.szUITexPath)
      :change(function(raw, szText)
        local tInfo = KG_Table.Load(szText .. '.txt', {
        -- 图片文件帧信息表的表头名字
            {f = "i", t = "nFrame" },             -- 图片帧 ID
            {f = "i", t = "nLeft"  },             -- 帧位置: 距离左侧像素(X位置)
            {f = "i", t = "nTop"   },             -- 帧位置: 距离顶端像素(Y位置)
            {f = "i", t = "nWidth" },             -- 帧宽度
            {f = "i", t = "nHeight"},             -- 帧高度
            {f = "s", t = "szFile" },             -- 帧来源文件(无作用)
        }, FILE_OPEN_MODE.NORMAL)
        if not tInfo then
            return
        end

        MYDev_UITexViewer.szUITexPath = szText
        uiBoard:clear()
        for i = 0, 256 do
            local tLine = tInfo:Search(i)
            if not tLine then
                break
            end

            if tLine.nWidth ~= 0 and tLine.nHeight ~= 0 then
                uiBoard:append("<image>eventid=277 name=\"Image_"..i.."\"</image>"):children('#Image_' .. i)
                  :image(szText .. '.UITex', tLine.nFrame)
                  :size(tLine.nWidth, tLine.nHeight)
                  :alpha(220)
                  :hover(function(bIn) MY.UI(this):alpha((bIn and 255) or 220) end)
                  :tip(szText .. '.UITex#' .. i .. '\n' .. tLine.nWidth .. 'x' .. tLine.nHeight .. '\n' .. _L['(left click to generate xml)'], MY.Const.UI.Tip.POS_TOP)
                  :click(function() uiEdit:text('<image>w='..tLine.nWidth..' h='..tLine.nHeight..' path="' .. szText .. '.UITex" frame=' .. i ..'</image>') end)
            end
        end
      end)
      :click(function(nButton, raw)
        if IsPopupMenuOpened() then
            MY.UI(raw):autocomplete('close')
        else
            MY.UI(raw):autocomplete('search', '')
        end
      end)
      :autocomplete('option', 'maxOption', 20)
      :autocomplete('option', 'source', _Cache.tUITexList)
      :change()
end

_Cache.OnPanelDeactive = function(wnd)
    _Cache.tUITexList = nil
    collectgarbage("collect")
end

MY.RegisterPanel( "Dev_UITexViewer", _L["UITexViewer"], _L['Development'], "ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
    OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = _Cache.OnPanelDeactive
})
