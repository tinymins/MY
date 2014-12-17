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
if not MiddleMap._MY_MMM_ShowMap then
    MiddleMap._MY_MMM_ShowMap = MiddleMap.ShowMap
end
local lockerOnShowMap
MiddleMap.ShowMap = function(...)
    if lockerOnShowMap then
        return
    end
    lockerOnShowMap = true

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
    lockerOnShowMap = false
end

-- HOOK OnEditChanged
if not MiddleMap._MY_MMM_OnEditChanged then
    MiddleMap._MY_MMM_OnEditChanged = MiddleMap.OnEditChanged
end
local lockerOnEditChanged
MiddleMap.OnEditChanged = function()
    if lockerOnEditChanged then
        return
    end
    lockerOnEditChanged = true

    if this:GetName() == 'Edit_Search' then
        MY_MiddleMapMark.Search(this:GetText())
    end
    if MiddleMap._MY_MMM_OnEditChanged then
        MiddleMap._MY_MMM_OnEditChanged()
    end
    lockerOnEditChanged = false
end

-- HOOK OnMouseEnter
if not MiddleMap._MY_MMM_OnMouseEnter then
    MiddleMap._MY_MMM_OnMouseEnter = MiddleMap.OnMouseEnter
end
local lockerOnMouseEnter
MiddleMap.OnMouseEnter = function()
    if lockerOnMouseEnter then
        return
    end
    lockerOnMouseEnter = true

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
    lockerOnMouseEnter = false
end

-- HOOK OnMouseLeave
if not MiddleMap._MY_MMM_OnMouseLeave then
    MiddleMap._MY_MMM_OnMouseLeave = MiddleMap.OnMouseLeave
end
local lockerOnMouseLeave
MiddleMap.OnMouseLeave = function()
    if lockerOnMouseLeave then
        return
    end
    lockerOnMouseLeave = true

    if this:GetName() == 'Edit_Search' then
        HideTip()
    end
    if MiddleMap._MY_MMM_OnMouseLeave then
        MiddleMap._MY_MMM_OnMouseLeave()
    end
    lockerOnMouseLeave = false
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
    
    local muList = ui:append("WndScrollBox_ResultList", "WndScrollBox"):find("#WndScrollBox_ResultList")
      :pos(20, 35)
      :size(w - 32, h - 50)
      :handleStyle(3)
    
    local muProgress = ui:append('Image_Progress', 'Image'):item('#Image_Progress')
      :pos(20, 31)
      :size(w - 30, 4)
      :image('ui/Image/UICommon/RaidTotal.UITex|45')
    
    local AddListItem = function(szText, data)
        local muItem = muList:append('<handle><image>w=300 h=25 eventid=371 name="Image_Bg" </image><text>name="Text_Default" </text></handle>'):hdl(1):children():last()
        
        local hText = muItem:children("#Text_Default")
          :pos(10, 2)
          :autosize(true)
          :text(szText or "")
          :raw(1)
        
        muItem:children("#Image_Bg"):image("UI/Image/Common/TextShadow.UITex",5):alpha(0)
          :hover(function(bIn)
            if bIn then
                MY.UI(this):fadeIn(100)
            else
                MY.UI(this):fadeTo(500,0)
            end
          end)
          :click(function(nButton)
            if nButton == MY.Const.Event.Mouse.LBUTTON then
                OpenMiddleMap(data.dwMapID, 0)
                MY.UI('Topmost1/MiddleMap/Wnd_Tool/Edit_Search'):text(MY.String.PatternEscape(data.szName))
                Station.SetFocusWindow('Topmost1/MiddleMap')
            end
          end)
    end
    
    ui:append('WndEdit_Search', 'WndEditBox'):children('#WndEdit_Search')
      :pos(18, 10)
      :size(w - 26, 25)
      :change(function(v)
        if not (v and #v > 0) then
            return
        end
        muList:clear()
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
                    and (string.find(p.szName, v) or
                    string.find(p.szTitle, v)) then
                        AddListItem('[' .. Table_GetMapName(dwMapID) .. '] ' .. p.szName ..
                        ((p.szTitle and #p.szTitle > 0 and '<' .. p.szTitle .. '>') or ''), {
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
                    if not tNames[p.szName] and string.find(p.szName, v) then
                        AddListItem('[' .. Table_GetMapName(dwMapID) .. '] ' .. p.szName, {
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
    if tonumber(szName) then
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
        szName  = MY.GetObjectName(npc),
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
    -- avoid player's doodad
    if doodad.dwEmployer and doodad.dwEmployer ~= 0 then
        return
    end
    -- avoid full number named doodad
    local szName = MY.GetObjectName(doodad)
    if tonumber(szName) then
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
        szName  = MY.GetObjectName(doodad),
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