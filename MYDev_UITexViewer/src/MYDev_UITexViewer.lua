--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 开发者工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local ipairs_r, spairs, spairs_r = LIB.ipairs_r, LIB.spairs, LIB.spairs_r
local sipairs, sipairs_r = LIB.sipairs, LIB.sipairs_r
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, Clone = LIB.GetPatch, LIB.ApplyPatch, LIB.Clone
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local EMPTY_TABLE, MENU_DIVIDER, XML_LINE_BREAKER = LIB.EMPTY_TABLE, LIB.MENU_DIVIDER, LIB.XML_LINE_BREAKER
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT..'MYDev_UITexViewer/lang/')
if not LIB.AssertVersion('MYDev_UITexViewer', _L['MYDev_UITexViewer'], 0x2011800) then
	return
end
local _Cache = {}
MYDev_UITexViewer = {}
MYDev_UITexViewer.szUITexPath = ''
RegisterCustomData('MYDev_UITexViewer.szUITexPath')

_Cache.OnPanelActive = function(wnd)
    local ui = UI(wnd)
    local w, h = ui:size()
    local x, y = 20, 20

    _Cache.tUITexList = LIB.LoadLUAData(PACKET_INFO.ROOT .. 'MYDev_UITexViewer/data/data.jx3dat') or {}

    local uiBoard = ui:append('WndScrollBox', 'WndScrollBox_ImageList')
      :children('#WndScrollBox_ImageList')
      :handleStyle(3):pos(x, y+25):size(w-21, h - 70)

    local uiEdit = ui:append('WndEditBox', 'WndEdit_Copy'):children('#WndEdit_Copy')
      :pos(x, h-30):size(w-20, 25):multiLine(true)

    ui:append('WndAutocomplete', 'WndAutocomplete_UITexPath'):children('#WndAutocomplete_UITexPath')
      :pos(x, y):size(w-20, 25):text(MYDev_UITexViewer.szUITexPath)
      :change(function(szText)
        local tInfo = KG_Table.Load(szText .. '.txt', {
        -- 图片文件帧信息表的表头名字
            {f = 'i', t = 'nFrame' },             -- 图片帧 ID
            {f = 'i', t = 'nLeft'  },             -- 帧位置: 距离左侧像素(X位置)
            {f = 'i', t = 'nTop'   },             -- 帧位置: 距离顶端像素(Y位置)
            {f = 'i', t = 'nWidth' },             -- 帧宽度
            {f = 'i', t = 'nHeight'},             -- 帧高度
            {f = 's', t = 'szFile' },             -- 帧来源文件(无作用)
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
                uiBoard:append('<image>eventid=277 name="Image_'..i..'"</image>'):children('#Image_' .. i)
                  :image(szText .. '.UITex', tLine.nFrame)
                  :size(tLine.nWidth, tLine.nHeight)
                  :alpha(220)
                  :hover(function(bIn) UI(this):alpha((bIn and 255) or 220) end)
                  :tip(szText .. '.UITex#' .. i .. '\n' .. tLine.nWidth .. 'x' .. tLine.nHeight .. '\n' .. _L['(left click to generate xml)'], MY_TIP_POSTYPE.TOP_BOTTOM)
                  :click(function() uiEdit:text('<image>w='..tLine.nWidth..' h='..tLine.nHeight..' path="' .. szText .. '.UITex" frame=' .. i ..'</image>') end)
            end
        end
      end)
      :click(function(nButton)
        if IsPopupMenuOpened() then
            UI(this):autocomplete('close')
        else
            UI(this):autocomplete('search', '')
        end
      end)
      :autocomplete('option', 'maxOption', 20)
      :autocomplete('option', 'source', _Cache.tUITexList)
      :change()
end

_Cache.OnPanelDeactive = function(wnd)
    _Cache.tUITexList = nil
    collectgarbage('collect')
end

LIB.RegisterPanel( 'Dev_UITexViewer', _L['UITexViewer'], _L['Development'], 'ui/Image/UICommon/BattleFiled.UITex|7', {
    OnPanelActive = _Cache.OnPanelActive, OnPanelDeactive = _Cache.OnPanelDeactive
})
