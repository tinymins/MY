-- 
-- 中地图标记
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20141204
--
-- 主要功能: 记录所有NPC和Doodad位置 提供搜索和显示
-- 

MY_MiddleMapMark = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_MiddleMapMark/lang/")
local _Cache = { tMapDataChanged = {} }
local Data = {}
local SZ_CACHE_PATH = "cache/NPC_DOODAD_REC/"
local MAX_DISTINCT_DISTANCE = 4 -- 最大独立距离4尺（低于该距离的两个实体视为同一个）
MAX_DISTINCT_DISTANCE = MAX_DISTINCT_DISTANCE * MAX_DISTINCT_DISTANCE * 64 * 64

-- HOOK MAP SWITCH
if MiddleMap._MY_MMM_ShowMap == nil then
    MiddleMap._MY_MMM_ShowMap = MiddleMap.ShowMap or false
end
MiddleMap.ShowMap = function(...)
    if MiddleMap._MY_MMM_ShowMap then
        MiddleMap._MY_MMM_ShowMap(...)
    end
    MY_MiddleMapMark.Search(_Cache.szKeyword)
    -- for mapid changing
    local dwMapID = MiddleMap.dwMapID
    MY.DelayCall(function()
        if dwMapID ~= MiddleMap.dwMapID then
            MY_MiddleMapMark.Search(_Cache.szKeyword)
        end
    end, 200)
end

-- HOOK OnEditChanged
if MiddleMap._MY_MMM_OnEditChanged == nil then
    MiddleMap._MY_MMM_OnEditChanged = MiddleMap.OnEditChanged or false
end
MiddleMap.OnEditChanged = function()
    if this:GetName() == 'Edit_Search' then
        MY_MiddleMapMark.Search(this:GetText())
    end
    if MiddleMap._MY_MMM_OnEditChanged then
        MiddleMap._MY_MMM_OnEditChanged()
    end
end

-- HOOK OnMouseEnter
if MiddleMap._MY_MMM_OnMouseEnter == nil then
    MiddleMap._MY_MMM_OnMouseEnter = MiddleMap.OnMouseEnter or false
end
MiddleMap.OnMouseEnter = function()
    if this:GetName() == 'Edit_Search' then
        local x, y = this:GetAbsPos()
        local w, h = this:GetSize()
        OutputTip(
            GetFormatText(_L['Type to search, use comma to split.'], nil, 255, 255, 0),
            w,
            {x - 10, y, w, h},
            MY.Const.UI.Tip.POS_TOP
        )
    end
    if MiddleMap._MY_MMM_OnMouseEnter then
        MiddleMap._MY_MMM_OnMouseEnter()
    end
end

-- HOOK OnMouseLeave
if MiddleMap._MY_MMM_OnMouseLeave == nil then
    MiddleMap._MY_MMM_OnMouseLeave = MiddleMap.OnMouseLeave or false
end
MiddleMap.OnMouseLeave = function()
    if this:GetName() == 'Edit_Search' then
        HideTip()
    end
    if MiddleMap._MY_MMM_OnMouseLeave then
        MiddleMap._MY_MMM_OnMouseLeave()
    end
end

-- start search
MY_MiddleMapMark.Search = function(szKeyword)
    local ui = MY.UI("Topmost1/MiddleMap")
    local player = GetClientPlayer()
    if ui:count() == 0 or not ui:visible() or not player then
        return
    end
    
    local uiHandle = ui:item("#Handle_MY_MMM")
    if uiHandle:count() == 0 then
        uiHandle = ui:append('Handle_MY_MMM', 'Handle'):item('#Handle_MY_MMM')
          :pos(ui:item('#Handle_Map'):pos())
    end
    uiHandle:clear()
    
    _Cache.szKeyword = szKeyword
    if not szKeyword or szKeyword == '' then
        return
    end

    local dwMapID = MiddleMap.dwMapID or player.GetMapID()
    local tKeyword = MY.String.Split(szKeyword, ',')
    -- check if data exist
    local data = MY_MiddleMapMark.GetMapData(dwMapID)
    if not data then
        return
    end
    
    -- render npc mark
    for _, npc in ipairs(data.Npc) do
        local bMatch = false
        for _, kw in ipairs(tKeyword) do
            if string.find(npc.szName, kw) or
            string.find(npc.szTitle, kw) then
                bMatch = true
                break
            end
        end
        if bMatch then
            uiHandle:append('Image_Npc_' .. npc.dwID, 'Image'):item('#Image_Npc_' .. npc.dwID)
              :image('ui/Image/Minimap/MapMark.UITex|95')
              :size(13, 13)
              :pos(MiddleMap.LPosToHPos(npc.nX, npc.nY, 13, 13))
              :tip(npc.szName ..
                ((npc.nLevel and npc.nLevel > 0 and ' lv.' .. npc.nLevel) or '') ..
                ((npc.szTitle ~= '' and '\n<' .. npc.szTitle .. '>') or ''),
              MY.Const.UI.Tip.POS_TOP)
        end
    end
    
    -- render doodad mark
    for _, doodad in ipairs(data.Doodad) do
        local bMatch = false
        for _, kw in ipairs(tKeyword) do
        if string.find(doodad.szName, kw) then
                bMatch = true
                break
            end
        end
        if bMatch then
            uiHandle:append('Image_Doodad_' .. doodad.dwID, 'Image'):item('#Image_Doodad_' .. doodad.dwID)
              :image('ui/Image/Minimap/MapMark.UITex|95')
              :size(13, 13)
              :pos(MiddleMap.LPosToHPos(doodad.nX, doodad.nY, 13, 13))
              :tip(doodad.szName, MY.Const.UI.Tip.POS_TOP)
        end
    end
end

MY_MiddleMapMark.GetMapData = function(dwMapID)
    -- if data not loaded, load it now
    if not Data[dwMapID] then
        MY_MiddleMapMark.StartDelayUnloadMapData(dwMapID)
        Data[dwMapID] = MY.Json.Decode(MY.LoadLUAData(SZ_CACHE_PATH .. dwMapID)) or {
            Npc = {},
            Doodad = {},
        }
        MY.Debug(Table_GetMapName(dwMapID) .. '(' .. dwMapID .. ') map data loaded.', 'MY_MiddleMapMark', 0)
    end
    return Data[dwMapID]
end

-- 开始指定地图的延时数据卸载时钟
MY_MiddleMapMark.StartDelayUnloadMapData = function(dwMapID)
    -- breathe until unload data
    MY.BreatheCall('MY_MiddleMapMark_DataUnload_' .. dwMapID, function()
        local player = GetClientPlayer()
        if player and player.GetMapID() ~= dwMapID and MiddleMap.dwMapID ~= dwMapID then
            MY_MiddleMapMark.UnloadMapData(dwMapID)
            return 0
        end
    end, 60000)
end

MY_MiddleMapMark.UnloadMapData = function(dwMapID)
    MY.Debug(Table_GetMapName(dwMapID) .. '(' .. dwMapID .. ') map data unloaded.', 'MY_MiddleMapMark', 0)
    Data[dwMapID] = nil
end

MY_MiddleMapMark.SaveMapData = function()
    for dwMapID, data in pairs(Data) do
        MY_MiddleMapMark.StartDelayUnloadMapData(dwMapID)
        if _Cache.tMapDataChanged[dwMapID] then
            MY.SaveLUAData(SZ_CACHE_PATH .. dwMapID, MY.Json.Encode(data))
        end
    end
end

_Cache.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local x, y = ui:pos()
    local w, h = ui:size()
    
    local list = ui:append('WndListBox_1', 'WndListBox'):children('#WndListBox_1')
      :pos(20, 35)
      :size(w - 32, h - 50)
      :listbox('onlclick', function(text, id, data, selected)
        OpenMiddleMap(data.dwMapID, 0)
        MY.UI('Topmost1/MiddleMap/Wnd_Tool/Edit_Search'):text(MY.String.PatternEscape(data.szName))
        Station.SetFocusWindow('Topmost1/MiddleMap')
        if not selected then -- avoid unselect
            return false
        end
      end)
    
    local muProgress = ui:append('Image_Progress', 'Image'):item('#Image_Progress')
      :pos(20, 31)
      :size(w - 30, 4)
      :image('ui/Image/UICommon/RaidTotal.UITex|45')
    
    ui:append('WndEdit_Search', 'WndEditBox'):children('#WndEdit_Search')
      :pos(18, 10)
      :size(w - 26, 25)
      :change(function(v)
        if not (v and #v > 0) then
            return
        end
        list:listbox('clear')
        local aMap = GetMapList()
        local i, N = 1, #aMap
        local n, M = 0, 200
        
        MY.BreatheCall('MY_MiddleMapMark_Searching_Threading', function()
            for _ = 1, 10 do
                local dwMapID = aMap[i]
                local data = MY_MiddleMapMark.GetMapData(dwMapID)
                local tNames = {}
                for _, p in ipairs(data.Npc) do
                    if not tNames[p.szName]
                    and (wstring.find(p.szName, v) or
                    wstring.find(p.szTitle, v)) then
                        list:listbox('insert', '[' .. Table_GetMapName(dwMapID) .. '] ' .. p.szName ..
                        ((p.szTitle and #p.szTitle > 0 and '<' .. p.szTitle .. '>') or ''), nil, {
                            dwMapID = dwMapID ,
                            szName  = p.szName,
                        })
                        n = n + 1
                        tNames[p.szName] = true
                    end
                    if n > M then
                        return 0
                    end
                end
                local tNames = {}
                for _, p in ipairs(data.Doodad) do
                    if not tNames[p.szName] and wstring.find(p.szName, v) then
                        list:listbox('insert', '[' .. Table_GetMapName(dwMapID) .. '] ' .. p.szName, nil, {
                            dwMapID = dwMapID ,
                            szName  = p.szName,
                        })
                        n = n + 1
                        tNames[p.szName] = true
                    end
                    if n > M then
                        return 0
                    end
                end
                muProgress:width((w - 32) * i / N)

                i = i + 1
                if i > N then
                    return 0
                end
            end
        end)
        
      end)
    
end

local m_nLastRedrawFrame = GetLogicFrameCount()
local MARK_RENDER_INTERVAL = GLOBAL.GAME_FPS * 5
MY.RegisterEvent("NPC_ENTER_SCENE",    "MY_MiddleMapMark", function()
    local npc = GetNpc(arg0)
    local player = GetClientPlayer()
    if not (npc and player) then
        return
    end
    -- avoid player's pets
    if npc.dwEmployer and npc.dwEmployer ~= 0 then
        return
    end
    -- avoid full number named npc
    local szName = MY.GetObjectName(npc)
    if not szName then
        return
    end
    -- switch map
    local dwMapID = player.GetMapID()
    local data = MY_MiddleMapMark.GetMapData(dwMapID)
    
    -- keep data distinct
    for i = #data.Npc, 1, -1 do
        local p = data.Npc[i]
        if p.dwID == npc.dwID or
        p.dwTemplateID == npc.dwTemplateID and
        math.pow(npc.nX - p.nX, 2) + math.pow(npc.nY - p.nY, 2) <= MAX_DISTINCT_DISTANCE then
            table.remove(data.Npc, i)
        end
    end
    -- add rec
    table.insert(data.Npc, {
        nX = npc.nX,
        nY = npc.nY,
        dwID = npc.dwID,
        nLevel  = npc.nLevel,
        szName  = szName,
        szTitle = npc.szTitle,
        dwTemplateID = npc.dwTemplateID,
    })
    -- redraw ui
    if GetLogicFrameCount() - m_nLastRedrawFrame > MARK_RENDER_INTERVAL then
        m_nLastRedrawFrame = GetLogicFrameCount()
        MY_MiddleMapMark.Search(_Cache.szKeyword)
    end
    _Cache.tMapDataChanged[dwMapID] = true
end)
MY.RegisterEvent("DOODAD_ENTER_SCENE", "MY_MiddleMapMark", function()
    local doodad = GetDoodad(arg0)
    local player = GetClientPlayer()
    if not (doodad and player) then
        return
    end
    -- avoid special doodad
    if doodad.dwTemplateID == 82 then -- 切磋用旗帜
        return
    end
    -- avoid full number named doodad
    local szName = MY.GetObjectName(doodad)
    if not szName then
        return
    end
    -- switch map
    local dwMapID = player.GetMapID()
    local data = MY_MiddleMapMark.GetMapData(dwMapID)
    
    -- keep data distinct
    for i = #data.Doodad, 1, -1 do
        local p = data.Doodad[i]
        if p.dwID == doodad.dwID or
        p.dwTemplateID == doodad.dwTemplateID and
        math.pow(doodad.nX - p.nX, 2) + math.pow(doodad.nY - p.nY, 2) <= MAX_DISTINCT_DISTANCE then
            table.remove(data.Doodad, i)
        end
    end
    -- add rec
    table.insert(data.Doodad, {
        nX = doodad.nX,
        nY = doodad.nY,
        dwID = doodad.dwID,
        szName  = szName,
        dwTemplateID = doodad.dwTemplateID,
    })
    -- redraw ui
    if GetLogicFrameCount() - m_nLastRedrawFrame > MARK_RENDER_INTERVAL then
        m_nLastRedrawFrame = GetLogicFrameCount()
        MY_MiddleMapMark.Search(_Cache.szKeyword)
    end
    _Cache.tMapDataChanged[dwMapID] = true
end)
MY.RegisterEvent('LOADING_END', MY_MiddleMapMark.SaveMapData)
MY.RegisterEvent('PLAYER_EXIT_GAME', MY_MiddleMapMark.SaveMapData)
MY.RegisterPanel( "MY_MiddleMapMark", _L["middle map mark"], _L['General'],
    "ui/Image/MiddleMap/MapWindow2.UITex|4", {255,255,0,200}, {
        OnPanelActive = _Cache.OnPanelActive
    }
)
